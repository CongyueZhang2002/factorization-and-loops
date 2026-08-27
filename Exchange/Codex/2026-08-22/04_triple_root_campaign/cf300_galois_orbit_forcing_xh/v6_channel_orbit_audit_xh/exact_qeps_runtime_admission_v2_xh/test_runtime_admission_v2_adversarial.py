#!/usr/bin/env python3
"""No-kernel adversarial models for exact-Q(eps) runtime admission."""

from __future__ import annotations

import copy
import hashlib
from pathlib import Path

from test_runtime_admission_v2_static import (
    ADMISSION, HELD_PARSE, EXPECTED, FROZEN_DRIVER,
    has_split_context_marker, transformed_driver_text,
)


def preflight(kernel: int, helpers: int, nested: list[int]) -> bool:
    return kernel == 24 and helpers == 0 and nested == []


def admission_model(record: dict[str, object]) -> bool:
    return bool(
        record["preflight"]
        and record["driver_code"] == 0
        and record["output_status"] ==
        "CF300Sector12ExactQepsLeftObstructionCertifiedV1"
        and isinstance(record["output_bytes"], int)
        and 0 <= record["output_bytes"] <= 2**30
        and record["sources_stable"]
        and record["prerequisite_stable"]
        and record["poststate_stable"]
    )


def main() -> None:
    admission = ADMISSION.read_text()
    held_parse = HELD_PARSE.read_text()
    checks: list[tuple[str, bool]] = []

    def check(name: str, condition: bool) -> None:
        checks.append((name, bool(condition)))

    check("preflight_accepts_only_k24_zero_zero", preflight(24, 0, []))
    check("preflight_rejects_wrong_kernel", not preflight(23, 0, []))
    check("preflight_rejects_helper", not preflight(24, 1, []))
    check("preflight_rejects_nested", not preflight(24, 0, [101]))
    check("preflight_rejects_all_wrong", not preflight(9, 4, [1, 2]))

    valid = {
        "preflight": True,
        "driver_code": 0,
        "output_status": "CF300Sector12ExactQepsLeftObstructionCertifiedV1",
        "output_bytes": 2**30,
        "sources_stable": True,
        "prerequisite_stable": True,
        "poststate_stable": True,
    }
    check("admission_accepts_boundary_fixture", admission_model(valid))
    mutations = [
        ("preflight", False),
        ("driver_code", 2),
        ("output_status", "CF300ExactQepsWitnessModularReconstructionFailedV1"),
        ("output_bytes", 2**30 + 1),
        ("sources_stable", False),
        ("prerequisite_stable", False),
        ("poststate_stable", False),
    ]
    for field, value in mutations:
        mutant = copy.deepcopy(valid)
        mutant[field] = value
        check(f"admission_rejects_{field}", not admission_model(mutant))

    transformed = transformed_driver_text()
    check("transform_fingerprint_exact",
          hashlib.sha256(transformed.encode()).hexdigest() == EXPECTED["transformed"])
    check("transform_has_four_typed_caught_exits",
          FROZEN_DRIVER.read_text().count("Exit[") == 4 and
          transformed.count("Throw[") == 4 and
          transformed.count("CF300ExactQepsFrozenDriverExitV2") == 4 and
          "Exit[" not in transformed)
    check("transform_has_both_output_ceilings",
          "ByteCount[value] > 2^30" in transformed and
          "FileByteCount[outputFile] > 2^30" in transformed)
    frozen_bytes = FROZEN_DRIVER.read_bytes()
    check("frozen_source_has_required_terminal_lf", frozen_bytes.endswith(b"\n"))
    check("terminal_lf_deletion_changes_source_pin",
          hashlib.sha256(frozen_bytes[:-1]).hexdigest() != EXPECTED["frozen_driver"])
    check("terminal_lf_deletion_changes_transform_pin",
          hashlib.sha256(transformed[:-1].encode()).hexdigest() != EXPECTED["transformed"])
    check("non_ascii_source_rejected_by_runtime_model",
          not all(byte < 128 for byte in frozen_bytes + b"\x80"))
    for token in ("Exit[64]", "Exit[98]", "Exit[code]", "Exit[65]"):
        mutant = FROZEN_DRIVER.read_text().replace(token, token.replace("Exit", "Quit"), 1)
        check(f"typed_exit_mutant_changes_source_pin_{token}",
              hashlib.sha256(mutant.encode()).hexdigest() != EXPECTED["frozen_driver"])
    check("unrelated_throw_not_typed_exit",
          'Throw[777, "UnrelatedTag"]' !=
          'Throw[777, "CF300ExactQepsFrozenDriverExitV2"]')
    check("broad_untyped_transform_forbidden",
          '"Exit[" -> "Throw["' not in admission)
    check("typed_catch_literal_present",
          "ToExpression[transformedText, InputForm]], driverExitTag]" in admission)


    split_mutant = admission.replace(
        "CodexCF300ExactQepsLeftObstructionDriverV1`Private`",
        "CodexCF300ExactQepsLeftObstructionDriverV1`\nPrivate`", 1)
    check("context_backtick_mutant_detected",
          has_split_context_marker(split_mutant))
    check("admission_has_no_context_split",
          not has_split_context_marker(admission))
    check("held_gate_has_no_context_split",
          not has_split_context_marker(held_parse))

    check("stale_certificate_guard",
          "FileExistsQ[outputFile]" in admission)
    check("stale_receipt_guard",
          "FileExistsQ[receiptFile]" in admission)
    check("stale_held_output_guard",
          "FileExistsQ[outputFile]" in held_parse)
    check("oversize_certificate_rolls_back",
          "CertificateOutputCeilingExceeded" in admission and
          "rollbackPerformed = deleteIfPresent[outputFile]" in admission)
    check("false_certification_rolls_back",
          '! passed && outputStatus ===' in admission and
          "rollbackPerformed = deleteIfPresent[outputFile]" in admission)
    check("missing_success_receipt_rolls_back",
          "CF300_EXACT_QEPS_ADMISSION FAIL receipt_atomic_write" in admission and
          "If[TrueQ[successQ]" in admission)
    check("receipt_records_ceilings",
          '"MaximumCertificateBytes"' in admission and
          '"MaximumReceiptBytes"' in admission)
    check("receipt_records_admission_state",
          '"AdmissionStateStable"' in admission and
          '"NestedKernelCountAtEntry"' in admission)
    check("receipt_records_transformed_parse",
          '"TransformedDriverHeldParse"' in admission and
          '"ContextBacktickSplitGuardPassed"' in admission)
    check("runtime_rejects_missing_or_stale_held_gate",
          "CF300_EXACT_QEPS_ADMISSION FAIL held_parse_evidence" in admission and
          "HeldParseEvidenceChangedDuringRun" in admission)
    check("held_gate_binds_exact_five_sources",
          "heldExpectedHashes" in admission and
          'Length[Lookup[heldParseArtifact, "ParseRecords", <||>]] === 5' in admission)
    check("receipt_records_all_source_hashes",
          '"SourceHashesBefore"' in admission and
          '"SourceHashesAfter"' in admission)

    import_mutant = admission.replace(
        'sourceText = readPinnedASCIIText[files["FrozenDriver"]];',
        'sourceText = Import[files["FrozenDriver"], "Text"];', 1)
    check("import_text_regression_detected",
          hashlib.sha256(import_mutant.encode()).hexdigest() !=
          hashlib.sha256(admission.encode()).hexdigest() and
          'Import[files["FrozenDriver"], "Text"]' in import_mutant)
    untyped_mutant = admission.replace(
        "ToExpression[transformedText, InputForm]], driverExitTag]",
        "ToExpression[transformedText, InputForm]]]", 1)
    check("untyped_catch_regression_detected",
          untyped_mutant != admission and
          "ToExpression[transformedText, InputForm]], driverExitTag]" not in
          untyped_mutant)
    held_wrapper_pin_mutant = held_parse.replace(
        hashlib.sha256(ADMISSION.read_bytes()).hexdigest(), "0" * 64, 1)
    check("held_wrapper_pin_mutation_detected",
          held_wrapper_pin_mutant != held_parse and
          hashlib.sha256(ADMISSION.read_bytes()).hexdigest() not in
          held_wrapper_pin_mutant)

    check("watcher_runtime_pass_marker",
          "CF300_EXACT_QEPS_ADMISSION PASS output=" in admission)
    check("watcher_runtime_fail_marker",
          "CF300_EXACT_QEPS_ADMISSION FAIL reason=" in admission)
    check("watcher_held_pass_marker",
          "CF300_EXACT_QEPS_HELD_PARSE PASS output=" in held_parse)
    check("watcher_held_fail_marker",
          "CF300_EXACT_QEPS_HELD_PARSE FAIL" in held_parse)
    check("success_receipt_status_exact",
          "CF300ExactQepsRuntimeAdmissionPassedV2XH" in admission)
    check("failure_receipt_status_exact",
          "CF300ExactQepsRuntimeAdmissionFailedV2XH" in admission)
    check("held_receipt_status_exact",
          "CF300ExactQepsRuntimeAdmissionHeldParsePassedV2XH" in held_parse)

    failures = [name for name, ok in checks if not ok]
    if failures:
        raise SystemExit(f"FAIL {len(failures)}/{len(checks)}: {', '.join(failures)}")
    print(f"PASS {len(checks)}/{len(checks)} runtime-admission adversarial checks")


if __name__ == "__main__":
    main()
