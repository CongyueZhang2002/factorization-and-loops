#!/usr/bin/env python3
"""No-kernel static admission gate for the frozen CF300 exact-Q(eps) run."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
EXACT = HERE.parent / "exact_qeps_left_obstruction_xh"
ADMISSION = HERE / "run_cf300_sector12_exact_qeps_admitted_v2_xh.wls"
HELD_PARSE = HERE / "held_parse_cf300_exact_qeps_runtime_admission_v2_xh.wls"
FROZEN_DRIVER = EXACT / "run_cf300_sector12_exact_qeps_left_obstruction_v1.wls"

EXPECTED = {
    "frozen_driver": "446da75743811e2c3d1e2a438205a74786883fa7a4363304c37d911685bfa174",
    "helper": "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b",
    "modular": "0c50fe48adc4bd28181e0954a2191a8c49452779a134405e1c27b6cd27def1ce",
    "schema": "909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45",
    "manifest": "642fb0b403c1c68e04e9943945e32b3b66b923265e50777c3fef3da85e451757",
    "v6d": "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf",
    "kpsubmit": "138315a11149c14fc3491a008e6e7ad4d23623d29a2228fbdea31d4384707ddc",
    "transformed": "35c3c32e6db5c1b5bb0accd62b7516b43b264191b664f6377e4d8d0d87f31ac8",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def code_only(text: str) -> str:
    out: list[str] = []
    i = 0
    depth = 0
    in_string = False
    while i < len(text):
        if in_string:
            if text[i] == "\\":
                i += 2
                continue
            if text[i] == '"':
                in_string = False
            i += 1
            continue
        if depth:
            if text.startswith("(*", i):
                depth += 1
                i += 2
            elif text.startswith("*)", i):
                depth -= 1
                i += 2
            else:
                i += 1
            continue
        if text.startswith("(*", i):
            depth = 1
            i += 2
        elif text[i] == '"':
            in_string = True
            i += 1
        else:
            out.append(text[i])
            i += 1
    assert depth == 0 and not in_string
    return "".join(out)


def balanced_wl(text: str) -> bool:
    cleaned = code_only(text)
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[str] = []
    for char in cleaned:
        if char in "([{":
            stack.append(char)
        elif char in pairs:
            if not stack or stack.pop() != pairs[char]:
                return False
    return not stack


def has_split_context_marker(text: str) -> bool:
    return any(line.rstrip().endswith("`") for line in text.splitlines())


def pinned_ascii(path: Path) -> str:
    raw = path.read_bytes()
    assert raw.endswith(b"\n")
    assert all(byte < 128 for byte in raw)
    return raw.decode("ascii")


def strip_shebang_exact(source: str) -> str:
    if not source.startswith("#!"):
        return source
    newline = source.find("\n")
    return "" if newline < 0 else source[newline + 1:]


def transformed_driver_text() -> str:
    parse_text = strip_shebang_exact(pinned_ascii(FROZEN_DRIVER))
    replacements = {
        "Exit[64]": 'Throw[64, "CF300ExactQepsFrozenDriverExitV2"]',
        "Exit[98]": 'Throw[98, "CF300ExactQepsFrozenDriverExitV2"]',
        "Exit[code]": 'Throw[code, "CF300ExactQepsFrozenDriverExitV2"]',
        "Exit[65]": 'Throw[65, "CF300ExactQepsFrozenDriverExitV2"]',
        "If[FileExistsQ[outputFile], Return[$Failed]];": (
            "If[FileExistsQ[outputFile] || ByteCount[value] > 2^30,\n"
            "    Return[$Failed]];"
        ),
        "reread = Quiet[Check[Get[outputFile], $Failed]];": (
            "If[FileByteCount[outputFile] > 2^30,\n"
            "    deleteIfPresent[outputFile]; Return[$Failed]];\n"
            "  reread = Quiet[Check[Get[outputFile], $Failed]];"
        ),
    }
    assert parse_text.count("Exit[") == 4
    for old in replacements:
        assert parse_text.count(old) == 1
    for old, new in replacements.items():
        parse_text = parse_text.replace(old, new)
    return parse_text

def main() -> None:
    admission = ADMISSION.read_text()
    held_parse = HELD_PARSE.read_text()
    admission_code = code_only(admission)
    held_code = code_only(held_parse)
    checks: list[tuple[str, bool]] = []

    def check(name: str, condition: bool) -> None:
        checks.append((name, bool(condition)))

    check("admission_exists", ADMISSION.is_file())
    check("held_parse_exists", HELD_PARSE.is_file())
    check("admission_balanced", balanced_wl(admission))
    check("held_parse_balanced", balanced_wl(held_parse))
    check("no_split_context_admission", not has_split_context_marker(admission))
    check("no_split_context_gate", not has_split_context_marker(held_parse))
    check("no_unresolved_placeholders", "__" not in admission and "__" not in held_parse)

    for label, digest in EXPECTED.items():
        check(f"pin_{label}", digest in admission or digest in held_parse)
    check("frozen_driver_hash_exact", sha256(FROZEN_DRIVER) == EXPECTED["frozen_driver"])
    check("helper_hash_exact", sha256(EXACT / "CF300ExactQepsLeftObstruction.wl") == EXPECTED["helper"])
    check("modular_hash_exact", sha256(EXACT / "CF300ModularQepsWitnessReconstruction.wl") == EXPECTED["modular"])
    check("schema_hash_exact", sha256(EXACT / "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl") == EXPECTED["schema"])
    check("manifest_hash_exact", sha256(EXACT / "SHA256SUMS_EXACT_QEPS_LEFT_OBSTRUCTION_V1") == EXPECTED["manifest"])
    check("gate_pins_admission_hash", sha256(ADMISSION) in held_parse)

    for label, source in [("admission", admission), ("held", held_parse)]:
        check(f"{label}_k24", "expectedDispatchKernelID = 24" in source)
        check(f"{label}_helper_zero", "taskBrokerMaxHelpers === 0" in source)
        check(f"{label}_nested_empty", "nestedKernelsAtEntry =!= {}" in source)
        check(f"{label}_preflight_before_arguments",
              source.index("actualDispatchKernelID =") < source.index("arguments = Rest[$ScriptCommandLine]"))

    check("admission_poststate_k24", "AdmissionStateChangedDuringRun" in admission)
    check("admission_poststate_nested", "System`Kernels[] === {}" in admission)
    check("admission_poststate_helper", "KernelPoolMission`$TaskBrokerMaxHelpers === 0" in admission)
    check("runtime_requires_held_parse_artifact",
          "heldParseArtifactFile = ExpandFileName[arguments[[4]]]" in admission and
          "CF300ExactQepsRuntimeAdmissionHeldParsePassedV2XH" in admission)
    check("held_parse_artifact_binds_wrapper",
          '"AdmissionDriver" -> wrapperHashBefore' in admission)
    check("held_parse_artifact_exact_source_map",
          'Lookup[heldParseArtifact, "SourceHashesBefore", <||>] ===' in admission and
          "heldExpectedHashes" in admission)
    check("held_parse_artifact_five_records",
          'Length[Lookup[heldParseArtifact, "ParseRecords", <||>]] === 5' in admission)
    check("held_parse_gate_and_artifact_stability",
          "heldParseArtifactHashAfter === heldParseArtifactHashBefore" in admission and
          "heldParseGateHashAfter === heldParseGateHashBefore" in admission)
    check("outer_pool_only_telemetry", '"OuterPoolKernelCount"' in admission and
          "outerPoolKernelCount = System`$KernelCount" in admission)
    check("no_nested_launch_api_admission", not re.search(
        r"\b(LaunchKernels|ParallelSubmit|ParallelTable|ParallelMap)\s*\[",
        admission_code))
    check("no_nested_launch_api_gate", not re.search(
        r"\b(LaunchKernels|ParallelSubmit|ParallelTable|ParallelMap)\s*\[",
        held_code))
    check("no_process_control_admission", "KillProcess[" not in admission_code and
          "StartProcess[" not in admission_code and "RunProcess[" not in admission_code)
    check("no_system_exit_admission", "Exit[" not in admission_code)
    check("no_system_exit_gate", "Exit[" not in held_code)

    transformed = transformed_driver_text()
    check("transformed_sha", hashlib.sha256(transformed.encode()).hexdigest() == EXPECTED["transformed"])
    check("transformed_no_exit", "Exit[" not in transformed)
    check("transformed_four_typed_throw",
          transformed.count("CF300ExactQepsFrozenDriverExitV2") == 4 and
          transformed.count("Throw[") == 4)
    check("transformed_memory_ceiling", "ByteCount[value] > 2^30" in transformed)
    check("transformed_disk_ceiling", "FileByteCount[outputFile] > 2^30" in transformed)
    check("transform_occurrence_guards", 'exitCount =!= 4' in admission and
          "exitReplacementCounts =!=" in admission and
          "StringCount[parseText, ceilingPattern] =!= 1" in admission and
          "StringCount[parseText, rereadPattern] =!= 1" in admission)
    check("byte_exact_ascii_reader",
          'BinaryReadList[file, "Byte"]' in admission and
          "stripShebangExact" in admission and
          'StringPosition[text, "\\n", 1]' in admission and
          'Import[files["FrozenDriver"], "Text"]' not in admission)
    check("terminal_lf_runtime_gate",
          'StringEndsQ[sourceText, "\\n"]' in admission and
          "driver_binary_read_or_terminal_lf" in admission)
    check("typed_catch_throw_containment",
          "CF300ExactQepsFrozenDriverExitV2" in admission and
          "ToExpression[transformedText, InputForm]], driverExitTag]" in admission and
          '"Exit[" -> "Throw["' not in admission)
    check("transformed_held_parse", "ToExpression[transformedText, InputForm, HoldComplete]" in admission)
    check("transformed_syntax_length", "SyntaxLength[transformedText]" in admission)
    check("transformed_context_split_gate", '"SplitContextMarkerLines"' in admission)

    check("certificate_ceiling_1gib", "maximumCertificateBytes = 2^30" in admission)
    check("certificate_prewrite_memory_ceiling", "ByteCount[value] > 2^30" in admission)
    check("certificate_postwrite_disk_ceiling", "FileByteCount[outputFile] > 2^30" in admission)
    check("receipt_ceiling_16mib", "maximumReceiptBytes = 2^24" in admission)
    check("held_output_ceiling_16mib", "maximumOutputBytes = 2^24" in held_parse)
    check("fresh_output_policy", "FileExistsQ[outputFile]" in admission and
          "FileExistsQ[receiptFile]" in admission)
    check("atomic_nonoverwrite_receipt", "OverwriteTarget -> False" in admission and
          "RenameFile[temporary, receiptFile" in admission)
    check("receipt_failure_rolls_back_certificate",
          "CF300_EXACT_QEPS_ADMISSION FAIL receipt_atomic_write" in admission and
          "rollbackPerformed = deleteIfPresent[outputFile]" in admission)
    check("atomic_nonoverwrite_held", "OverwriteTarget -> False" in held_parse and
          "RenameFile[temporary, outputFile" in held_parse)
    check("certification_status_exact", "CF300Sector12ExactQepsLeftObstructionCertifiedV1" in admission)
    check("admission_success_status", "CF300ExactQepsRuntimeAdmissionPassedV2XH" in admission)
    check("held_success_status", "CF300ExactQepsRuntimeAdmissionHeldParsePassedV2XH" in held_parse)
    check("watcher_pass_marker", "CF300_EXACT_QEPS_ADMISSION PASS" in admission)
    check("watcher_fail_marker", "CF300_EXACT_QEPS_ADMISSION FAIL" in admission)
    check("held_pass_marker", "CF300_EXACT_QEPS_HELD_PARSE PASS" in held_parse)
    check("held_fail_marker", "CF300_EXACT_QEPS_HELD_PARSE FAIL" in held_parse)

    for label in ["AdmissionDriver", "FrozenDriver", "ExactHelper",
                  "ModularReconstruction", "PrerequisiteSchema"]:
        check(f"held_parses_{label}", f'"{label}" ->' in held_parse)
    check("held_holdcomplete", "HoldCompleteExact" in held_parse)
    check("held_syntax_exact", "SyntaxLengthExact" in held_parse)
    check("held_zero_messages", 'record["ParserMessages"] === {}' in held_parse)
    check("held_namespace_cleanup", "ParseNamespaceCleanupPassed" in held_parse)
    check("held_hash_before_after", "hashesAfter === hashesBefore === expectedHashes" in held_parse)
    check("admission_hash_before_after", "hashesAfter === hashesBefore === expectedHashes" in admission)
    check("prerequisite_stability", "prerequisiteHashAfter === prerequisiteHashBefore" in admission)
    check("receipt_records_central_held_parse",
          '"HeldParseArtifactSHA256"' in admission and
          '"HeldParseEvidenceValid"' in admission)
    check("wrapper_stability", "wrapperHashAfter === wrapperHashBefore" in admission)

    failures = [name for name, ok in checks if not ok]
    if failures:
        raise SystemExit(f"FAIL {len(failures)}/{len(checks)}: {', '.join(failures)}")
    print(f"PASS {len(checks)}/{len(checks)} runtime-admission static checks")


if __name__ == "__main__":
    main()
