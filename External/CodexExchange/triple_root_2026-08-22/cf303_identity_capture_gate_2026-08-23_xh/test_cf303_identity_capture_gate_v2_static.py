#!/usr/bin/env python3
"""No-kernel V2 regression for an intentionally nonexistent output target."""

from __future__ import annotations

import hashlib
import os
import re
import sys
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops")
HERE = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "cf303_identity_capture_gate_2026-08-23_xh"
)
WRAPPER = HERE / "run_cf303_identity_capture_fresh_xh_v2.wls"
MANIFEST = HERE / "SOURCE_SHA256SUMS"
OUTPUT = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf303_identity_capture_xh_v2"
)
EXPECTED_MANIFEST_SHA = (
    "0123b6241eb8e396c98598d3de4625fc83b6df010d33d57b14b70a25a07c8a3d"
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def strip_wolfram_comments_and_strings(text: str) -> str:
    output: list[str] = []
    index = 0
    comment_depth = 0
    in_string = False
    while index < len(text):
        pair = text[index : index + 2]
        char = text[index]
        if comment_depth:
            if pair == "(*":
                comment_depth += 1
                output.extend("  ")
                index += 2
            elif pair == "*)":
                comment_depth -= 1
                output.extend("  ")
                index += 2
            else:
                output.append("\n" if char == "\n" else " ")
                index += 1
        elif in_string:
            if char == "\\" and index + 1 < len(text):
                output.extend("  ")
                index += 2
            elif char == '"':
                in_string = False
                output.append(" ")
                index += 1
            else:
                output.append("\n" if char == "\n" else " ")
                index += 1
        elif pair == "(*":
            comment_depth = 1
            output.extend("  ")
            index += 2
        elif char == '"':
            in_string = True
            output.append(" ")
            index += 1
        else:
            output.append(char)
            index += 1
    assert comment_depth == 0, "unterminated Wolfram comment"
    assert not in_string, "unterminated Wolfram string"
    return "".join(output)


def assert_balanced(code: str) -> None:
    opening = {"[": "]", "{": "}", "(": ")"}
    closing = {value: key for key, value in opening.items()}
    stack: list[tuple[str, int]] = []
    for offset, char in enumerate(code):
        if char in opening:
            stack.append((char, offset))
        elif char in closing:
            assert stack and stack[-1][0] == closing[char], (
                f"mismatched {char!r} at byte {offset}"
            )
            stack.pop()
    assert not stack, f"unclosed delimiter: {stack[-1] if stack else None}"


def read_manifest() -> dict[str, str]:
    records: dict[str, str] = {}
    for line_number, raw in enumerate(MANIFEST.read_text().splitlines(), 1):
        match = re.fullmatch(r"([0-9a-f]{64})  (\S+)", raw)
        assert match, f"malformed manifest line {line_number}: {raw!r}"
        digest, relative = match.groups()
        assert relative not in records, f"duplicate source: {relative}"
        records[relative] = digest
    return records


def lexical_preflight_model(target: Path) -> list[str]:
    """Model only the fresh-target/parent branch; it must emit no message."""
    messages: list[str] = []
    if target.exists():
        messages.append(f"output is not fresh: {target}")
        return messages
    parent_string = os.path.dirname(os.fspath(target))
    assert isinstance(parent_string, str) and parent_string
    if not Path(parent_string).is_dir():
        messages.append(f"output parent is absent: {parent_string}")
    return messages


def main() -> int:
    checks = 0
    assert WRAPPER.is_file() and MANIFEST.is_file()
    assert sha256(MANIFEST) == EXPECTED_MANIFEST_SHA
    checks += 2

    records = read_manifest()
    assert len(records) == 69
    for relative, expected in records.items():
        source = ROOT / relative
        assert source.is_file(), f"missing source: {relative}"
        assert sha256(source) == expected, f"source drift: {relative}"
    checks += 1 + len(records)

    text = WRAPPER.read_text()
    code = strip_wolfram_comments_and_strings(text)
    assert_balanced(code)
    checks += 1

    required = [
        '"cf303_identity_capture_xh_v2"',
        '"identity_capture_xh_v2"',
        "outdirParent = DirectoryName[outdir];",
        "DirectoryQ[outdirParent]",
        'output parent is absent: " <>\n      outdirParent',
        '"FACET_KERNEL_COUNT" -> "1"',
        '"FACET_TASK_BROKER_MAX_HELPERS" -> "0"',
        "KernelPoolMission`$TaskBrokerMaxHelpers === 0",
        "Length[Kernels[]] =!= 0",
        "RenameFile[temporary, file, OverwriteTarget -> False]",
        '"Status" -> "CF303IdentityCaptureLaunchSealedV2"',
        '"Status" -> "CF303IdentityCaptureRunningV2"',
        "restoreEnvironment[]",
    ]
    for token in required:
        assert token in text, f"missing V2 contract token: {token}"
        checks += 1

    forbidden_code = [
        "ParentDirectory[",
        "LaunchKernels[",
        "CloseKernels[",
        "RunProcess[",
        "StartProcess[",
        "DeleteFile[",
        "CF300",
    ]
    for token in forbidden_code:
        assert token not in code, f"forbidden V2 code token: {token}"
        checks += 1

    # The regression condition itself: target absent, lexical parent present,
    # and the modeled parent/freshness preflight has no diagnostic to emit.
    assert not OUTPUT.exists(), f"V2 output is no longer fresh: {OUTPUT}"
    assert OUTPUT.parent.is_dir(), f"V2 lexical parent is absent: {OUTPUT.parent}"
    assert lexical_preflight_model(OUTPUT) == []
    checks += 3

    # Also exercise a never-created sibling name; no filesystem mutation is
    # needed and the lexical result cannot depend on target existence.
    synthetic = OUTPUT.parent / "cf303_identity_capture_static_nonexistent_probe"
    assert not synthetic.exists(), f"synthetic target unexpectedly exists: {synthetic}"
    assert lexical_preflight_model(synthetic) == []
    checks += 2

    print(f"PASS: {checks} V2 source/parser/lexical-preflight assertions")
    print(f"wrapper_sha256={sha256(WRAPPER)}")
    print(f"manifest_sha256={sha256(MANIFEST)}")
    print(f"fresh_output={OUTPUT}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
