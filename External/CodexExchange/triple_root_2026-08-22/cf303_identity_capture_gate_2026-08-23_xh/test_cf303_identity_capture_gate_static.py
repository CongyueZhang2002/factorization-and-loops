#!/usr/bin/env python3
"""No-kernel acceptance checks for the fresh CF303 capture wrapper."""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops")
HERE = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "cf303_identity_capture_gate_2026-08-23_xh"
)
WRAPPER = HERE / "run_cf303_identity_capture_fresh_xh_v1.wls"
MANIFEST = HERE / "SOURCE_SHA256SUMS"
OUTPUT = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf303_identity_capture_xh_v1"
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
    """Keep delimiters in code while blanking nested comments and strings."""
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
    if comment_depth or in_string:
        raise AssertionError(
            f"unterminated {'comment' if comment_depth else 'string'}"
        )
    return "".join(output)


def balanced_wolfram_delimiters(code: str) -> None:
    opening = {"[": "]", "{": "}", "(": ")"}
    closing = {value: key for key, value in opening.items()}
    stack: list[tuple[str, int]] = []
    for offset, char in enumerate(code):
        if char in opening:
            stack.append((char, offset))
        elif char in closing:
            if not stack or stack[-1][0] != closing[char]:
                raise AssertionError(f"mismatched {char!r} at byte {offset}")
            stack.pop()
    if stack:
        raise AssertionError(f"unclosed delimiter {stack[-1]}")


def read_manifest() -> dict[str, str]:
    records: dict[str, str] = {}
    for line_number, raw in enumerate(MANIFEST.read_text().splitlines(), 1):
        if not raw.strip():
            continue
        match = re.fullmatch(r"([0-9a-f]{64})  (\S+)", raw)
        assert match, f"malformed manifest line {line_number}: {raw!r}"
        digest, relative = match.groups()
        assert relative not in records, f"duplicate manifest path: {relative}"
        assert not Path(relative).is_absolute(), f"absolute manifest path: {relative}"
        assert ".." not in Path(relative).parts, f"escaping manifest path: {relative}"
        records[relative] = digest
    return records


def cf303_class_ids() -> set[int]:
    assignment = (
        ROOT
        / "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/"
        "BlockClasses/block_class_assign.wl"
    ).read_text()
    records = re.findall(r"<\|(.*?)\|>", assignment, flags=re.DOTALL)
    return {
        int(match.group(1))
        for record in records
        if '"Family" -> "CF303"' in record
        if (match := re.search(r'"ClassID" -> (\d+)', record))
    }


def main() -> int:
    checks = 0
    assert ROOT.is_dir() and WRAPPER.is_file() and MANIFEST.is_file()
    checks += 1

    assert sha256(MANIFEST) == EXPECTED_MANIFEST_SHA
    checks += 1
    records = read_manifest()
    assert len(records) == 69
    checks += 1
    for relative, expected in records.items():
        path = ROOT / relative
        assert path.is_file(), f"missing pinned source: {relative}"
        assert sha256(path) == expected, f"source drift: {relative}"
    checks += len(records)

    package_sources = {
        str(path.relative_to(ROOT))
        for path in (ROOT / "FeynFacet/Private").glob("*.wl")
    } | {"FeynFacet/FeynFacet.m", "FeynFacet/Distributions.wl"}
    assert package_sources <= records.keys(), sorted(package_sources - records.keys())
    checks += 1

    expected_classes = cf303_class_ids()
    pinned_classes = {
        int(match.group(1))
        for relative in records
        if (
            match := re.fullmatch(
                r"ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/"
                r"ClassForms/class(\d+)\.wl",
                relative,
            )
        )
    }
    assert expected_classes == pinned_classes, (expected_classes, pinned_classes)
    assert len(expected_classes) == 24
    checks += 2

    text = WRAPPER.read_text()
    code = strip_wolfram_comments_and_strings(text)
    balanced_wolfram_delimiters(code)
    checks += 1
    required = [
        EXPECTED_MANIFEST_SHA,
        '"CF303"',
        '"FACET_KERNEL_COUNT" -> "1"',
        '"FACET_TASK_BROKER_MAX_HELPERS" -> "0"',
        '"FACET_CHECK_LEVEL" -> "Production"',
        '"FACET_STRIP_ROUTE" -> "FiniteFieldFirst"',
        '"FACET_ZERO_FORCING" -> "True"',
        '"FACET_RECORD_STRIP_ONLY" -> "False"',
        "KernelPoolMission`$TaskBrokerMaxHelpers === 0",
        "Length[Kernels[]] =!= 0",
        '"30", "", familyDataDirectory',
        "Put[expression, temporary]",
        "RenameFile[temporary, file, OverwriteTarget -> False]",
        "CheckAbort[",
        "restoreEnvironment[]",
    ]
    for token in required:
        assert token in text, f"missing wrapper contract token: {token}"
        checks += 1
    forbidden_code = [
        "LaunchKernels[",
        "CloseKernels[",
        "RunProcess[",
        "StartProcess[",
        "DeleteFile[",
        "CF300",
    ]
    for token in forbidden_code:
        assert token not in code, f"unsafe/cross-family code token: {token}"
        checks += 1

    assert not OUTPUT.exists(), f"fresh output path already exists: {OUTPUT}"
    assert OUTPUT.parent.is_dir(), f"output parent does not exist: {OUTPUT.parent}"
    checks += 2

    print(f"PASS: {checks} static/source/isolation assertions")
    print(f"wrapper_sha256={sha256(WRAPPER)}")
    print(f"manifest_sha256={sha256(MANIFEST)}")
    print(f"output={OUTPUT}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
