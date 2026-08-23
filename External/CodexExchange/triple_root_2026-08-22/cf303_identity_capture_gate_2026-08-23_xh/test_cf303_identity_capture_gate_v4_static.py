#!/usr/bin/env python3
"""No-kernel V4 control-flow, hash-contract, and probe-shape gate."""

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
WRAPPER = HERE / "run_cf303_identity_capture_fresh_xh_v4.wls"
PROBE = HERE / "probe_cf303_pool_exit_contract_noop_v1.wls"
V1 = HERE / "run_cf303_identity_capture_fresh_xh_v1.wls"
V2 = HERE / "run_cf303_identity_capture_fresh_xh_v2.wls"
V3 = HERE / "run_cf303_identity_capture_fresh_xh_v3.wls"
MANIFEST = HERE / "SOURCE_SHA256SUMS"
POOL_SOURCE = ROOT / "Scripts/KernelPool.wls"
POOL_DEFINITION = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/pool/poolrun_definition.m"
)
OUTPUT = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf303_identity_capture_xh_v4"
)
EXPECTED = {
    MANIFEST: "0123b6241eb8e396c98598d3de4625fc83b6df010d33d57b14b70a25a07c8a3d",
    POOL_SOURCE: "0758f0f95a24b5dee4c6162939388ca5641610ef5e73bb73775a2030e8ff069d",
    POOL_DEFINITION: "d49632694d4da9f47a7c3c0d9828e98d47f9a416c9cb72d8a10a74b9b011db51",
    V1: "586e46e7b157f063f1e0c2ce926a0c736f43c6e5745e38fb6e8f975b3537cc8d",
    V2: "5b75e81df5907a45882e7f82183b9e7bfd5a2960e4b0ce031bb3dd6fe6959a9d",
    V3: "4969fe24022305569c139e678ee59c6cf7c10364079fb516eb7514f44cc19f66",
}


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
        assert relative not in records, f"duplicate manifest path: {relative}"
        records[relative] = digest
    return records


def lexical_preflight_model(target: Path) -> list[str]:
    messages: list[str] = []
    if target.exists():
        messages.append(f"output is not fresh: {target}")
    else:
        parent = os.path.dirname(os.fspath(target))
        assert isinstance(parent, str) and parent
        if not Path(parent).is_dir():
            messages.append(f"output parent is absent: {parent}")
    return messages


class TaggedDriverExit(Exception):
    def __init__(self, payload: tuple[str, int]):
        self.payload = payload


def modeled_wrapper_preflight(ok: bool) -> str:
    return "driver-result" if ok else "$Failed"


def modeled_pool_run(target_result: str) -> dict[str, object]:
    return {
        "status": "FAILED" if target_result == "$Failed" else "OK",
        "mission_end": True,
        "kernel_done": True,
    }


def modeled_wrapper_driver_exit(code: int) -> None:
    environment_restored = True
    assert environment_restored
    raise TaggedDriverExit(("EXIT", code))


def modeled_pool_catch_driver_exit(code: int) -> dict[str, object]:
    try:
        modeled_wrapper_driver_exit(code)
    except TaggedDriverExit as caught:
        assert caught.payload == ("EXIT", code)
        return {
            "status": "OK" if code == 0 else f"EXIT{code}",
            "mission_end": True,
            "kernel_done": True,
        }
    raise AssertionError("driver exit was not rethrown to pool")


def main() -> int:
    checks = 0
    assert WRAPPER.is_file() and PROBE.is_file()
    for path, expected in EXPECTED.items():
        assert path.is_file(), f"missing pinned file: {path}"
        assert sha256(path) == expected, f"contract/source drift: {path}"
        checks += 1

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
    forbidden_calls = re.findall(r"(?<![A-Za-z0-9`])(Return|Exit|Quit)\s*\[", code)
    assert forbidden_calls == [], f"wrapper escape calls: {forbidden_calls}"
    assert "ParentDirectory[" not in code
    assert "DownValues[" not in code, "V4 reintroduced context-sensitive introspection"
    checks += 3

    required = [
        '"cf303_identity_capture_xh_v4"',
        '"identity_capture_xh_v4"',
        "outdirParent = DirectoryName[outdir];",
        "preflightTag = Unique[",
        "wrapperResult = Catch[",
        "Throw[$Failed, preflightTag]",
        "preflightTag];",
        "expectedKernelPoolSourceHash",
        "expectedPoolRunDefinitionHash",
        '"PinnedKernelPoolSourceAndActivePoolRunDefinition"',
        "driverExitPayload = payload",
        "Throw[driverExitPayload, \"KernelPoolExit\"]",
        '"FACET_KERNEL_COUNT" -> "1"',
        '"FACET_TASK_BROKER_MAX_HELPERS" -> "0"',
        "KernelPoolMission`$TaskBrokerMaxHelpers === 0",
        '"Status" -> "CF303IdentityCaptureLaunchSealedV4"',
        '"Status" -> "CF303IdentityCaptureDriverExitCapturedV4"',
        "RenameFile[temporary, file, OverwriteTarget -> False]",
    ]
    for token in required:
        assert token in text, f"missing V4 token: {token}"
        checks += 1

    for token in [
        "LaunchKernels[", "CloseKernels[", "RunProcess[", "StartProcess[",
        "DeleteFile[", "CF300",
    ]:
        assert token not in code, f"forbidden V4 token: {token}"
        checks += 1

    capture_index = text.index("driverExitPayload = payload")
    rethrow_index = text.index('Throw[driverExitPayload, "KernelPoolExit"]')
    restore_index = text.rfind("restoreEnvironment[]", capture_index, rethrow_index)
    status_index = text.index("CF303IdentityCaptureDriverExitCapturedV4")
    assert capture_index < restore_index < status_index < rethrow_index
    checks += 1

    # Exact shape of the optional no-op runtime probe: evaluate DownValues
    # first, stringify the resulting lists, and never call escape functions.
    probe_text = PROBE.read_text()
    probe_code = strip_wolfram_comments_and_strings(probe_text)
    assert_balanced(probe_code)
    probe_forbidden = re.findall(
        r"(?<![A-Za-z0-9`])(Return|Exit|Quit)\s*\[", probe_code
    )
    assert probe_forbidden == [], f"probe escape calls: {probe_forbidden}"
    probe_required = [
        "poolRunValues = DownValues[Global`poolRun];",
        "exitValues = DownValues[System`Exit];",
        "quitValues = DownValues[System`Quit];",
        "poolRunText = ToString[poolRunValues, InputForm];",
        "exitText = ToString[exitValues, InputForm];",
        "quitText = ToString[quitValues, InputForm];",
        '"FormerHeldExpressionEvaluated"',
    ]
    for token in probe_required:
        assert token in probe_text, f"missing runtime-probe token: {token}"
        checks += 1
    checks += 2

    assert not OUTPUT.exists(), f"V4 output is no longer fresh: {OUTPUT}"
    assert OUTPUT.parent.is_dir()
    assert lexical_preflight_model(OUTPUT) == []
    checks += 3

    failed = modeled_pool_run(modeled_wrapper_preflight(False))
    assert failed == {
        "status": "FAILED", "mission_end": True, "kernel_done": True
    }
    assert modeled_pool_catch_driver_exit(0)["status"] == "OK"
    assert modeled_pool_catch_driver_exit(2) == {
        "status": "EXIT2", "mission_end": True, "kernel_done": True
    }
    checks += 3

    print(f"PASS: {checks} V4 hash/control-flow/probe assertions")
    print(f"wrapper_sha256={sha256(WRAPPER)}")
    print(f"probe_sha256={sha256(PROBE)}")
    print(f"manifest_sha256={sha256(MANIFEST)}")
    print(f"fresh_output={OUTPUT}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
