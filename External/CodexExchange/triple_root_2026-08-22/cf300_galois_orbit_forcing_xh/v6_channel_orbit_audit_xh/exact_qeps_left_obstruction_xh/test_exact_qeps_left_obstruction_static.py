#!/usr/bin/env python3
"""No-kernel source and frozen-artifact gate for the CF300 Q(eps) lift."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
HELPER = HERE / "CF300ExactQepsLeftObstruction.wl"
RECONSTRUCTION = HERE / "CF300ModularQepsWitnessReconstruction.wl"
DRIVER = HERE / "run_cf300_sector12_exact_qeps_left_obstruction_v1.wls"
SCHEMA = HERE / "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl"
V6D = Path("/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl")
EXPECTED_V6D_SHA = "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def code_only(text: str) -> str:
    """Strip nested WL comments and strings for lexical safety assertions."""
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


def main() -> None:
    helper = HELPER.read_text()
    reconstruction = RECONSTRUCTION.read_text()
    driver = DRIVER.read_text()
    schema = SCHEMA.read_text()
    helper_code = code_only(helper)
    reconstruction_code = code_only(reconstruction)
    driver_code = code_only(driver)
    checks: list[tuple[str, bool]] = []

    def check(name: str, condition: bool) -> None:
        checks.append((name, bool(condition)))

    check("helper_exists", HELPER.is_file())
    check("reconstruction_exists", RECONSTRUCTION.is_file())
    check("driver_exists", DRIVER.is_file())
    check("schema_exists", SCHEMA.is_file())
    check("helper_balanced", balanced_wl(helper))
    check("reconstruction_balanced", balanced_wl(reconstruction))
    check("driver_balanced", balanced_wl(driver))
    check("schema_balanced", balanced_wl(schema))
    check("no_split_context_marker_any_source",
          not any(has_split_context_marker(text) for text in
                  (helper, reconstruction, driver, schema)))
    check("helper_package", 'BeginPackage["CodexCF300ExactQepsLeftObstruction`"' in helper)
    check("requirements_api", "EQWRequirementsFromV6d" in helper)
    check("prerequisite_api", "EQWPrerequisiteValidQ" in helper)
    check("exact_sample_api", "EQWAssembleExactSample" in helper)
    check("construct_api", "EQWConstruct" in helper)
    check("canonical_qeps_api", "EQWCanonicalQeps" in helper and
          "CodexCF300ExactQepsLeftObstruction`EQWCanonicalQeps" in reconstruction)
    check("qeps_field", '"Q(eps)"' in helper)
    check("thirty_points", "Length[points] =!= 30" in helper)
    check("matrix_shape", "{960, 912}" in helper)
    check("rank_pair", '"CoefficientRank" -> 888' in helper and '"AugmentedRank" -> 889' in helper)
    check("modular_reconstruction_api", "EQMRReconstruct" in reconstruction)
    check("cffa4_request", 'ToCharacterCode["CFFA4V1\\000"]' in reconstruction)
    check("cffa4_response", 'ToCharacterCode["CFFA4X1\\000"]' in reconstruction)
    check("native_binary_pinned", "e2d7d3ee375f712a20c62b31c4510b9cdac2fa13f7cce5256bb05733bee9d46b" in reconstruction)
    check("ff_source_pinned", "8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70" in reconstruction)
    check("native_fixed_square", "eqmrNativeSolve[Transpose[selectedBlock]" in reconstruction)
    check("no_cf300_symbolic_linear_solve", "LinearSolve[" not in helper_code and "LinearSolve[" not in reconstruction_code)
    check("crt_recovery", "ChineseRemainder" in reconstruction and "eqmrRationalReconstruct" in reconstruction)
    check("prefix_stability", "PrefixReconstructionNotStable" in reconstruction)
    check("rational_reconstruction_bound", "RationalReconstructionBoundSatisfied" in reconstruction)
    check("no_apriori_height_overclaim", '"APrioriCoefficientHeightBoundCertified" -> False' in reconstruction)
    check("adaptive_prime_growth", '"MinimumTrainingPrimeCount" -> 4' in reconstruction and '"MaximumTrainingPrimeCount" -> 12' in reconstruction)
    check("heldout_primes", "HeldOutPrimeImagesExact" in reconstruction)
    check("unseen_heldout_epsilon_values",
          '"HeldOutEpsilonValues" -> {163, 167, 173, 179, 181, 191, 193}' in reconstruction and
          "Intersection[epsilonCandidates, heldOutEpsilonValues] =!= {}" in reconstruction)
    check("heldout_residue_validation", "HeldOutEpsilonResiduesInvalid" in reconstruction and
          "HeldOutExceptionalEpsilonResidue" in reconstruction and
          "HeldOutTrainingEpsilonResidueOverlap" in reconstruction)
    check("phase_telemetry", "PhaseTelemetrySeconds" in reconstruction)
    check("hard_degree_bound", '"MaximumTotalEpsilonDegree" -> 80' in reconstruction)
    check("staged_degree_ladder", '"DegreeLadder" -> {8, 16, 24, 32, 48, 64, 80}' in reconstruction)
    check("degree_bound_not_overclaimed", '"DegreeBoundDerivedFromMatrix" -> False' in reconstruction)
    check("degree_cap_fail_fast", "ExploratoryDegreeCapReachedAtFirstQualifiedPrime" in reconstruction and
          '"FurtherTrainingPrimesSkipped" -> True' in reconstruction)
    check("degree_cap_evidence", "AcceptedImageSummaries" in reconstruction and
          "DegreeEvidence" in reconstruction and '"ResumeReady" -> False' in reconstruction)
    check("one_kernel_per_nonzero_coordinate_stage",
          reconstruction_code.count("NullSpace[") == 1 and
          '"MaximumInterpolationKernelCallsPerPrime" -> 6223' in reconstruction)
    check("interpolation_kernel_hard_total",
          '"MaximumTrainingInterpolationKernelCalls" -> 99568' in reconstruction)
    check("interpolation_actual_telemetry",
          "ActualRationalInterpolationWork" in reconstruction and
          "InterpolationKernelCallCount" in reconstruction)
    check("lower_degree_cache_revalidation",
          "eqmrCachedInterpolationValidQ" in reconstruction and
          "AssociateTo[interpolationCache" in reconstruction)
    check("cache_work_telemetry",
          '"MaximumCacheRevalidationsPerPrime" -> 5334' in reconstruction and
          "CacheRevalidationHitCount" in reconstruction and
          "CacheRevalidationMissCount" in reconstruction)
    check("cache_hits_do_not_double_count_kernel_work",
          '"CacheRevalidatedAtDegree" -> degree' in reconstruction and
          '"KernelCallCount" -> 0' in reconstruction and
          '"BasisPairReductionCount" -> 0' in reconstruction)
    check("one_basis_reduction_per_nonzero_coordinate_stage",
          '"MaximumBasisPairReductionsPerPrime" -> 6223' in reconstruction and
          '"BasisPairReductionCount" -> 1' in reconstruction)
    check("kernel_nullity_formula_checked",
          "expectedNullity = Min[maximumTotalDegree - degrees[[1]]" in reconstruction and
          "RationalInterpolationNullityMismatch" in reconstruction)
    check("kernel_multiple_subspace_certified",
          '"KernelEqualsPolynomialMultipleSubspace" -> True' in reconstruction)
    check("kernel_nullity_one_not_assumed",
          "Length[nullspace] =!= 1" not in reconstruction_code)
    check("degree_profile_two_of_three_consensus",
          "TwoMatchingProfilesWithinThreeQualifiedPrimes" in reconstruction and
          "ProvisionalDegreeProfileConsensusFailed" in reconstruction and
          "ProvisionalDegreeProfileMinorityRejected" in reconstruction)
    check("first_prime_does_not_seed_profile",
          'expectedDegrees = artifact["DegreeProfile"]' not in reconstruction_code)
    check("hard_prime_bound", '"MaximumPrimeCandidates" -> 18' in reconstruction)
    check("hard_solve_bound", '"MaximumTotalNativeSolveAttempts" -> 3024' in reconstruction)
    check("actual_solve_telemetry", "ActualNativeSolveAttempts" in reconstruction)
    check("runprocess_nonassociation_fails", '! AssociationQ[process]' in reconstruction and "NativeProcessDidNotReturnAssociation" in reconstruction)
    check("runprocess_exit_diagnostics", "NativeProcessNonzeroExit" in reconstruction and '"StandardError"' in reconstruction)
    check("exceptional_epsilon_rejected", "RegulatorExceptionalEpsilonImage" in reconstruction)
    check("epsilon_candidates_typed", 'MatchQ[epsilonCandidates, {(_Integer | _Rational) ..}]' in reconstruction)
    check("prime_static_short_circuit", "PrimeStaticPointAssemblyFailed" in reconstruction)
    check("augmented_column_required", "{columns + 1}" in helper)
    check("canonical_zero_elsewhere", "Thread[independentRows -> supportSolution]" in helper)
    check("left_residual", "Transpose[SparseArray[matrix]].witness" in helper)
    check("right_residual", "right.witness - 1" in helper)
    check("cleared_identity", "eqwClearedIdentity" in helper)
    check("all_left_zero", '"LeftClearedNumeratorsAllZero" -> True' in helper)
    check("right_pairing", '"RightPairing" -> 1' in helper)
    check("pick_1_based", "Pick[Range[Length[values]]" in helper)
    check("no_position_helper_code", "Position[" not in helper_code)
    check("no_position_reconstruction_code", "Position[" not in reconstruction_code)
    check("no_position_driver_code", "Position[" not in driver_code)
    check("no_heads_true_helper_code", "Heads->True" not in re.sub(r"\s+", "", helper_code))
    check("no_heads_true_reconstruction_code", "Heads->True" not in re.sub(r"\s+", "", reconstruction_code))
    check("no_heads_true_driver_code", "Heads->True" not in re.sub(r"\s+", "", driver_code))
    check("score_bug_detected", '"V6dScorePositionHeadTraversalBugDetected"' in helper)
    check("score_metadata_excluded", '"V6dScoreMetadataExcludedFromPlan" -> True' in driver)
    check("capture_required_status", "CF300ExactQepsWitnessPrerequisiteCaptureRequiredV1" in driver)
    check("plan_discovery_forbidden", '"PlanDiscoveryForbiddenInThisDriver" -> True' in driver)
    check("actual_run_says_no_discovery", '"PlanDiscoveryPerformed" -> False' in driver)
    check("anchor_i00", '"AnchorImageID" -> "I00"' in driver)
    check("rational_lift_documented", "minimum-height balanced rational lifts" in driver)
    check("residue_and_lift_fields", "AnchorAcceptedPointResidues" in driver and "ExactRationalPointLifts" in driver)
    check("lift_reduction_certificate", "PointLiftCertificate" in driver)
    check("atomic_output", "RenameFile[temporary, outputFile" in driver)
    check("stale_output_rejected", "FileExistsQ[outputFile]" in driver)
    check("source_stability", "fileHashes[] =!= sourceHashesBefore" in driver)
    check("no_unresolved_source_hash_placeholders",
          "__EXACT_HELPER_SHA256__" not in driver and
          "__MODULAR_RECONSTRUCTION_SHA256__" not in driver)
    check("driver_pins_current_helper_hash",
          sha256(HELPER) in driver)
    check("driver_pins_current_reconstruction_hash",
          sha256(RECONSTRUCTION) in driver)
    check("v6d_hash_pinned_helper", EXPECTED_V6D_SHA in helper)
    check("v6d_hash_pinned_driver", EXPECTED_V6D_SHA in driver)
    check("v6d_hash_pinned_schema", EXPECTED_V6D_SHA in schema)
    check("orbit_core_pinned", "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed" in driver)
    check("assembly_fingerprint_pinned", "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7" in helper)
    check("point_fingerprint_pinned", "f4ac00e6c1636c2f20028a2de449ea66a816ea017a84de6874dd63e54e155b50" in helper)
    check("coefficient_pivot_pinned", "ccc7fa776fdcf55017e98e8d57ee2480690db3c27e0dc8f8625acebd79bfe377" in helper)
    check("augmented_pivot_pinned", "8a9731fd7c345e781d71102d9cb3f8f0d745de3b17264e11b62ef538af0cb761" in helper)
    check("schema_missing_values", schema.count('Missing["CaptureRequired"]') == 11)
    check("schema_balanced_lift", "CertifiedBalancedRationalPointLiftV1" in schema)
    check("schema_coordinate_records", "CoordinateRecords" in schema)
    check("schema_anchor_revalidation", "AnchorPlanRevalidation" in schema)
    check("schema_no_plan_discovery", '"AllowPlanRediscoveryInExactDriver" -> False' in schema)
    check("schema_no_score_indices", '"ConsumeV6dScoreColumnIndices" -> False' in schema)
    check("single_basis_derivative_assignment", helper.count("basisDerivatives = Table[") == 1)
    check("single_training_prime_terminal", reconstruction.count('"TrainingPrimeImagesExact" -> True|>') == 1)
    check("no_duplicate_terminal_lines", not re.search(r'(?m)^(\s*"[^"]+"\s*->\s*True\|>\s*)\n\1$', reconstruction))

    if V6D.is_file():
        check("frozen_v6d_hash", sha256(V6D) == EXPECTED_V6D_SHA)
        with V6D.open("rb") as stream:
            stream.seek(max(0, V6D.stat().st_size - 40000))
            tail = stream.read().decode(errors="replace")
        check("v6d_only_point_fingerprints", '"AcceptedPointsFingerprint"' in tail and '"AcceptedPoints" ->' not in tail)
        check("v6d_no_pivot_arrays", '"PivotColumns" ->' not in tail and '"FreeColumns" ->' not in tail)
        check("v6d_score_count_bug_evidence", '"NonzeroScoreCount" -> 289' in tail)
        check("v6d_score_zero_index_evidence", '"NonzeroScoreColumns" -> \n       {0, 1, 2' in tail)
    else:
        check("frozen_v6d_hash", False)
        check("v6d_only_point_fingerprints", False)
        check("v6d_no_pivot_arrays", False)
        check("v6d_score_count_bug_evidence", False)
        check("v6d_score_zero_index_evidence", False)

    failures = [name for name, ok in checks if not ok]
    if failures:
        raise SystemExit(f"FAIL {len(failures)}/{len(checks)}: {', '.join(failures)}")
    print(f"PASS {len(checks)}/{len(checks)} static no-kernel checks")


if __name__ == "__main__":
    main()
