#!/usr/bin/env python3
"""No-kernel adversarial models for exact-Q(eps) runtime admission."""

from __future__ import annotations

import copy
import hashlib
from pathlib import Path

from test_runtime_admission_static import (
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
    check("transform_has_four_caught_exits",
          FROZEN_DRIVER.read_text().count("Exit[") == 4 and
          transformed.count("Throw[") == 4 and "Exit[" not in transformed)
    check("transform_has_both_output_ceilings",
          "ByteCount[value] > 2^30" in transformed and
          "FileByteCount[outputFile] > 2^30" in transformed)
    drifted_driver = FROZEN_DRIVER.read_text().replace("Exit[64]", "Exit[63]", 1)
    drifted_lines = drifted_driver.split("\n")
    drifted_parse = "\n".join(drifted_lines[1:])
    check("driver_drift_changes_source_pin",
          hashlib.sha256(drifted_driver.encode()).hexdigest() !=
          EXPECTED["frozen_driver"])
    check("driver_drift_changes_transform_pin",
          hashlib.sha256(drifted_parse.replace("Exit[", "Throw[").encode()).hexdigest()
          != EXPECTED["transformed"])

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

    check("watcher_runtime_pass_marker",
          "CF300_EXACT_QEPS_ADMISSION PASS output=" in admission)
    check("watcher_runtime_fail_marker",
          "CF300_EXACT_QEPS_ADMISSION FAIL reason=" in admission)
    check("watcher_held_pass_marker",
          "CF300_EXACT_QEPS_HELD_PARSE PASS output=" in held_parse)
    check("watcher_held_fail_marker",
          "CF300_EXACT_QEPS_HELD_PARSE FAIL" in held_parse)
    check("success_receipt_status_exact",
          "CF300ExactQepsRuntimeAdmissionPassedXH" in admission)
    check("failure_receipt_status_exact",
          "CF300ExactQepsRuntimeAdmissionFailedXH" in admission)
    check("held_receipt_status_exact",
          "CF300ExactQepsRuntimeAdmissionHeldParsePassedXH" in held_parse)

    failures = [name for name, ok in checks if not ok]
    if failures:
        raise SystemExit(f"FAIL {len(failures)}/{len(checks)}: {', '.join(failures)}")
    print(f"PASS {len(checks)}/{len(checks)} runtime-admission adversarial checks")


if __name__ == "__main__":
    main()
