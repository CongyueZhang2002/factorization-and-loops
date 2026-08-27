#!/usr/bin/env python3
"""No-kernel structural gate for the frozen CF300 V6e runtime harness."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
PROTOTYPE = HERE.parent
V6 = PROTOTYPE.parent
DRIVER = HERE / "run_cf300_sector12_v6e_correctness_same_input_benchmark_xh.wls"
PARSE_GATE = HERE / "held_parse_cf300_sector12_v6e_runtime_gate_xh.wls"
HELPER = PROTOTYPE / "DirectRootChannelExactOneFormRebindV6e.wl"
INTEGRATION = PROTOTYPE / "V6E_DRIVER_INTEGRATION_BLOCK.wl"
V6_CORE = V6 / "GaloisChannelOrbitCoreV6d.wl"
V6_HELPER = V6 / "DirectRootChannelExactOneFormRebindV6.wl"
V6_DRIVER = V6 / "run_cf300_sector12_galois_orbit_forcing_screen_v6d.wls"
EXCHANGE = V6.parent.parent
SCHEMA = V6 / "exact_qeps_left_obstruction_xh" / \
    "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl"
EXACT_LIFT_HELPER = V6 / "exact_qeps_left_obstruction_xh" / \
    "CF300ExactQepsLeftObstruction.wl"
NATIVE_ADAPTER = EXCHANGE / "flint_affine_rref_wl_xh" / \
    "FlintAffineRREFAdapter.wl"
NATIVE_BINARY = EXCHANGE / "flint_affine_rref_xh" / "bin" / \
    "flint_affine_rref"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def delimiters_balanced(text: str) -> bool:
    """Balance WL delimiters while ignoring strings and nested comments."""
    opening = "([{"
    closing = ")]}"
    pairs = dict(zip(closing, opening))
    stack: list[tuple[str, int]] = []
    index = 0
    comment_depth = 0
    in_string = False
    while index < len(text):
        if comment_depth:
            if text.startswith("(*", index):
                comment_depth += 1
                index += 2
            elif text.startswith("*)", index):
                comment_depth -= 1
                index += 2
            else:
                index += 1
            continue
        if in_string:
            if text[index] == "\\" and index + 1 < len(text):
                index += 2
            elif text[index] == '"':
                in_string = False
                index += 1
            else:
                index += 1
            continue
        if text.startswith("(*", index):
            comment_depth = 1
            index += 2
        elif text[index] == '"':
            in_string = True
            index += 1
        elif text[index] in opening:
            stack.append((text[index], index))
            index += 1
        elif text[index] in closing:
            opening_item = stack.pop() if stack else None
            if not opening_item or opening_item[0] != pairs[text[index]]:
                print("DELIMITER_MISMATCH",
                      {"line": text.count("\n", 0, index) + 1,
                       "character": text[index]})
                return False
            index += 1
        else:
            index += 1
    if stack or in_string or comment_depth:
        print("DELIMITER_UNCLOSED",
              {"stack_tail": [(item, text.count("\n", 0, position) + 1)
                               for item, position in stack[-8:]],
               "in_string": in_string,
               "comment_depth": comment_depth})
        return False
    return True


def main() -> None:
    checks: list[tuple[str, bool]] = []

    def check(label: str, condition: bool) -> None:
        checks.append((label, bool(condition)))

    files = [DRIVER, PARSE_GATE, HELPER, INTEGRATION, V6_CORE, V6_HELPER,
             V6_DRIVER, SCHEMA, EXACT_LIFT_HELPER, NATIVE_ADAPTER,
             NATIVE_BINARY]
    check("all_sources_exist", all(path.is_file() for path in files))
    driver = DRIVER.read_text() if DRIVER.is_file() else ""
    gate = PARSE_GATE.read_text() if PARSE_GATE.is_file() else ""
    helper = HELPER.read_text() if HELPER.is_file() else ""
    integration = INTEGRATION.read_text() if INTEGRATION.is_file() else ""
    check("runtime_delimiters_balance", delimiters_balanced(driver))
    check("parse_gate_delimiters_balance", delimiters_balanced(gate))
    check("runtime_has_no_line_ending_in_context_mark",
          not any(line.rstrip().endswith("`")
                  for line in driver.splitlines()))
    check("parse_gate_has_no_line_ending_in_context_mark",
          not any(line.rstrip().endswith("`")
                  for line in gate.splitlines()))

    expected = {
        HELPER: "2fea1e07c691ade811162f47db1d71d82a385dd01d07afd20beaa3aa0262f2e8",
        INTEGRATION: "7ea7a437cd25a440e4713040d0882947977a71f092510f0c02c940d8d02f0dbe",
        V6_CORE: "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed",
        V6_HELPER: "2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44",
        V6_DRIVER: "921422ec0f78c8a56a707fb487115d0b0a5debe6b84e5257e0d3df638e43988d",
        SCHEMA: "909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45",
        EXACT_LIFT_HELPER: "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b",
        NATIVE_ADAPTER: "d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605",
        NATIVE_BINARY: "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5",
    }
    for path, digest in expected.items():
        check(f"frozen_hash_{path.name}", sha(path) == digest)
    runtime_hash = sha(DRIVER)
    check("runtime_hash_is_pinned_by_parse_gate", runtime_hash in gate)
    check("no_unresolved_placeholder", "__RUNTIME_" not in driver and
          "__RUNTIME_DRIVER_SHA256__" not in gate)

    source_pins = [
        "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
        "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
        "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
        "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
        "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
        "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557",
        "8b0f8d7fdab72d9660836d1f2a92e7f03be5eb1adcbd7082b327ed4bb8b8e907",
        expected[V6_CORE], expected[V6_HELPER], expected[HELPER],
        expected[INTEGRATION], expected[SCHEMA], expected[NATIVE_ADAPTER],
        expected[NATIVE_BINARY], expected[EXACT_LIFT_HELPER],
    ]
    check("runtime_pins_every_loaded_or_referenced_source",
          all(pin in driver for pin in source_pins))
    check("parse_gate_pins_every_parse_target",
          all(pin in gate for pin in [runtime_hash, expected[HELPER],
                                      expected[INTEGRATION], expected[V6_CORE],
                                      expected[V6_HELPER], expected[SCHEMA],
                                      expected[EXACT_LIFT_HELPER]]))
    check("preparation_hash_pinned",
          "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4" in driver)
    check("cache_hash_pinned",
          "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be" in driver)
    check("maximal_fingerprint_pinned",
          "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7" in driver)
    check("frozen_v6d_time_pinned", "485.843061" in driver)
    check("frozen_v6d_artifact_pinned",
          "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf" in driver)
    check("core_only_and_capture_modes_are_unambiguous", all(token in driver for token in
          ["MemberQ[{4, 5, 6, 7}, Length[arguments]]",
           "capturePrerequisiteQ = MemberQ[{6, 7}",
           "KeyDrop[allFiles, prerequisiteSourceNames]",
           "If[capturePrerequisiteQ,"]))

    forbidden = ["LaunchKernels", "CloseKernels", "ParallelSubmit",
                 "ParallelTable", "ParallelMap", "ParallelEvaluate",
                 "StartProcess", "RunProcess"]
    check("runtime_has_no_nested_or_external_execution",
          all(token not in driver for token in forbidden))
    check("parse_gate_has_no_nested_or_external_execution",
          all(token not in gate for token in forbidden))
    broker_guard = "! TrueQ[taskBrokerMaxHelpers === 0] || nestedKernelsAtEntry =!= {}"
    check("helper_ceiling_exact_runtime",
          'taskBrokerMaxHelpers = KernelPoolMission`$TaskBrokerMaxHelpers' in driver and
          broker_guard in driver and
          'Environment["FACET_TASK_BROKER_MAX_HELPERS"]' not in driver and
          'System`$KernelCount =!= 0' not in driver)
    check("helper_ceiling_exact_parse_gate",
          'taskBrokerMaxHelpers = KernelPoolMission`$TaskBrokerMaxHelpers' in gate and
          broker_guard in gate and
          'Environment["FACET_TASK_BROKER_MAX_HELPERS"]' not in gate and
          'System`$KernelCount =!= 0' not in gate)
    runtime_dispatch = driver.find("actualDispatchKernelID = System`$KernelID")
    runtime_arguments = driver.find("arguments = Rest[$ScriptCommandLine]")
    runtime_broker_guard = driver.find(
        "taskBrokerMaxHelpers = KernelPoolMission`$TaskBrokerMaxHelpers")
    runtime_first_read = min(position for position in
                             [driver.find("FileHash["), driver.find("Get[")]
                             if position >= 0)
    check("runtime_requires_k24_before_arguments_or_source_reads",
          runtime_dispatch >= 0 and
          "actualDispatchKernelID =!= expectedDispatchKernelID" in driver and
          "expectedDispatchKernelID = 24" in driver and
          runtime_dispatch < runtime_broker_guard < runtime_arguments <
          runtime_first_read)
    gate_dispatch = gate.find("actualDispatchKernelID = System`$KernelID")
    gate_arguments = gate.find("arguments = Rest[$ScriptCommandLine]")
    gate_broker_guard = gate.find(
        "taskBrokerMaxHelpers = KernelPoolMission`$TaskBrokerMaxHelpers")
    gate_first_read = min(position for position in
                          [gate.find("FileHash["), gate.find("Import[")]
                          if position >= 0)
    check("parse_gate_requires_k24_before_arguments_or_source_reads",
          gate_dispatch >= 0 and
          "actualDispatchKernelID =!= expectedDispatchKernelID" in gate and
          "expectedDispatchKernelID = 24" in gate and
          gate_dispatch < gate_broker_guard < gate_arguments < gate_first_read)
    check("successful_artifacts_record_actual_dispatch_kernel",
          all(token in driver and token in gate for token in
              ['"ExpectedDispatchKernelID" -> expectedDispatchKernelID',
               '"DispatchKernelID" -> actualDispatchKernelID']))
    check("successful_artifacts_record_pool_and_nested_telemetry",
          all(token in driver and token in gate for token in
              ['"TaskBrokerMaxHelpers" -> taskBrokerMaxHelpers',
               '"OuterPoolKernelCount" -> outerPoolKernelCount',
               '"NestedKernelCount" -> Length[nestedKernelsAtEntry]',
               '"NestedKernelsAtEntry" -> nestedKernelsAtEntry']))

    oracle_marker = driver.find("Correctness oracle deliberately precedes")
    oracle_call = driver.find("DRCARebindExactOneFormChannels[",
                              max(oracle_marker, 0))
    trial1 = driver.find('trial1Full = runV6eTrial["same-input-1"]')
    trial2 = driver.find('trial2Full = runV6eTrial["same-input-2"]')
    check("oracle_precedes_both_benchmark_trials",
          min(oracle_marker, oracle_call, trial1, trial2) >= 0 and
          oracle_marker < oracle_call < trial1 < trial2)
    check("exactly_one_frozen_v6_oracle_call",
          driver.count("DRCARebindExactOneFormChannels[") == 1)
    check("exactly_two_same_input_trial_invocations",
          driver.count("= runV6eTrial[") == 2)
    check("v6e_call_uses_identical_named_inputs",
          "DRCARebindExactOneFormRecordsV6e[\n"
          "          baseAssembly, maxPreparation, additionalRecords]" in driver)
    check("input_identity_fingerprinted_before_and_after",
          driver.count("{baseAssembly, maxPreparation, additionalRecords}") >= 5)
    check("full_semantic_identity_to_v6_oracle",
          "SameQ[semanticResult,\n          oracleSemanticAssembly]" in driver)
    check("only_version_diagnostics_dropped_from_v6e",
          '"ExactOneFormChannelRebindV6e",\n'
          '        "ExactOneFormChannelRebindSealV6e"' in driver)
    check("only_v6_diagnostic_dropped_from_oracle",
          'oracleSemanticAssembly = KeyDrop[oracleAssembly,\n'
          '      "ExactOneFormChannelRebindV6"]' in driver)
    check("seal_fresh_then_replay_gate",
          "SameQ[{firstConsume, replayConsume}, {True, False}]" in driver)
    check("seal_validated_before_consumption",
          "SpecializedSealValidBeforeConsume" in driver)
    check("trial_exposes_nonsecret_seal_evidence",
          all(token in driver for token in
              ['"SealStatus" -> Lookup[seal, "Status", $Failed]',
               '"SealNonce" -> Lookup[seal, "Nonce", $Failed]',
               '"SealFingerprint" -> Lookup[seal, "SealFingerprint", $Failed]',
               '"FreshConsumePassed" -> TrueQ[firstConsume]',
               '"ReplayConsumeRejected" -> TrueQ[replayConsume === False]']))
    check("trial_seal_evidence_format_gated",
          all(token in driver for token in
              ["uuidStringQ[Lookup[seal, \"Nonce\", None]]",
               "sha256HexStringQ[Lookup[seal, \"SealFingerprint\", None]]",
               '"ExactOneFormRebindSpecializedSealV6e"']))
    check("cross_trial_seal_nonce_and_fingerprint_distinct",
          all(token in driver for token in
              ["trialSealEvidenceValid = TrueQ[",
               "trialSealNoncesDistinct = TrueQ[DuplicateFreeQ[",
               "trialSealFingerprintsDistinct = TrueQ[DuplicateFreeQ[",
               '"TrialSealNoncesDistinct" -> trialSealNoncesDistinct',
               '"TrialSealFingerprintsDistinct" ->']))
    check("legacy_oracle_count_one", "LegacyOracleCountExact" in driver and
          '"LegacyWholeResultOracleCount", -1] === 1' in driver)
    check("raw_unique_reuse_conservation", "RawUniqueReuseConservationExact" in driver)
    check("compile_count_exact", "CompileCountExact" in driver)
    check("collision_free", "CollisionFree" in driver)
    check("no_algebraic_fallback", "NoAlgebraicFallback" in driver)
    check("failures_and_missing_rejected", "NoFailureOrMissing" in driver and
          "$Failed | _Missing" in driver)
    check("repeat_fingerprints_compared", "repeatFingerprintsExact = SameQ[" in driver)
    check("performance_uses_two_trial_median", "Median[trialSeconds]" in driver)
    check("performance_compared_to_frozen_v6d",
          "medianV6eSeconds < frozenV6dRebindSeconds" in driver and
          "repeatFingerprintsExact && trialSealEvidenceValid &&" in driver and
          "trialSealNoncesDistinct && trialSealFingerprintsDistinct" in driver)
    check("nonpassing_performance_has_nonpass_status",
          "CF300Sector12V6eCorrectButPerformanceAcceptanceNotMetXH" in driver)
    check("oracle_and_trial_outer_memory", all(token in driver for token in
          ["oracleMemoryBefore", "oracleMemoryAfter", "memoryBefore",
           "memoryAfter", "OuterMemory"]))
    check("phase_timings_and_memory_preserved", all(token in driver for token in
          ['"PhaseSeconds"', '"PhaseMemory"', '"ExpressionByteCounts"',
           '"SerializedInputFormCharacterCounts"']))
    check("atomic_no_overwrite_output", all(token in driver for token in
          ["OverwriteTarget -> False", "FileExistsQ[outputFile]",
           "RenameFile", "reread"]))
    check("second_atomic_prerequisite_output", all(token in driver for token in
          ["liftPrerequisiteOutputFile", "writeAtomicTo[liftPrerequisite",
           "FileExistsQ[liftPrerequisiteOutputFile]"]))
    check("worst_case_output_ceiling_and_telemetry", all(token in driver for token in
          ["maximumAtomicOutputBytes = 2^30", "ByteCount[value]",
           "FileByteCount[temporary]", "AtomicOutputSizePolicy",
           "PreTelemetryByteCount"]))
    check("atomic_abort_temp_cleanup", driver.count(
          "deleteIfPresent[temporary]; Abort[]") == 2)
    check("postscope_failure_rolls_back_both_outputs", all(token in driver for token in
          ["outputRollbackPassed = deleteIfPresent[outputFile]",
           "prerequisiteRollbackPassed = If[StringQ[liftPrerequisiteOutputFile]",
           '" output_rollback="']))
    check("source_stability_before_final_acceptance", driver.count("stableInputsQ[]") >= 5)
    check("integration_is_reference_not_loaded",
          '"V6eIntegrationReference"' in driver and
          'loadSourceNames = {' in driver and
          '"ExactChannelRebindV6e"};' in driver)
    check("dedicated_artifact_context_no_global_path",
          'artifactContext = "CodexCF300V6eRuntimeArtifactXH`"' in driver and
          '"GlobalContextPresent"' in driver and
          'MemberQ[$ContextPath, "Global`"]' in driver)
    check("artifact_namespace_normalized_and_definition_free", all(
          token in driver for token in ["artifactQualifiedName",
          "artifactNamespaceAudit", "ExactOwnedNamespaceQ",
          "artifactDefinitionsBeforeCleanup", "definitionFreeStateQ",
          "removeQualifiedSymbolName"]))
    unqualified_namespace = re.compile(r"(?<!System`)\b(?:Names|Remove)\[")
    check("runtime_names_remove_explicit_system",
          not unqualified_namespace.search(driver))
    check("parse_gate_names_remove_explicit_system",
          not unqualified_namespace.search(gate))
    shadow_mutant = driver.replace("System`Names[artifactPattern]",
                                   "Names[artifactPattern]", 1)
    check("namespace_shadow_mutant_rejected",
          bool(unqualified_namespace.search(shadow_mutant)))

    check("four_frozen_images_are_rerun",
          driver.count('<|"ImageID" ->') == 4 and
          "DRCAAssembleSample" in driver and "rankImage" in driver)
    check("all_four_rank_contract_exact", all(token in driver for token in
          ['"CoefficientRank", -1] === 888',
           '"AugmentedRank", -1] === 889',
           '"CoefficientNullity", -1] === 24',
           '"AllFourFrozenImageCertificatesExact" -> True']))
    frozen_plan_fingerprints = [
        "f4ac00e6c1636c2f20028a2de449ea66a816ea017a84de6874dd63e54e155b50",
        "ccc7fa776fdcf55017e98e8d57ee2480690db3c27e0dc8f8625acebd79bfe377",
        "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534",
        "9924c7eef76fea745d5451876be6012810e205e7ca28e021dd99cb2c720d9914",
        "8a9731fd7c345e781d71102d9cb3f8f0d745de3b17264e11b62ef538af0cb761",
        "3f35c25a1819c8c11ee28d300e252c47beda7f8213bcd45ac54f417fba3023a7",
    ]
    check("frozen_point_and_plan_fingerprints_pinned",
          all(item in driver for item in frozen_plan_fingerprints))
    check("complete_plan_arrays_persisted", all(token in driver for token in
          ["CoefficientPivotColumns", "CoefficientFreeColumns",
           "CoefficientIndependentEquationRows", "AugmentedPivotColumns",
           "AugmentedFreeColumns", "AugmentedIndependentEquationRows"]))
    lift_fields = ["AnchorAcceptedPointResidues", "ExactRationalPointLifts",
                   "PointLiftCertificate",
                   "CertifiedBalancedRationalPointLiftV1",
                   "CoordinateRecords", "AllDenominatorsInvertible",
                   "AllReductionsExact", "ExactPointsDistinctOverQ",
                   "AnchorLiftedPointsNonsingularModuloPrimeAtEpsilon",
                   "CapturedPlanRevalidatedAtLiftedResidues",
                   "AnchorPlanRevalidation"]
    check("exact_lift_capture_fields_complete",
          all(field in driver for field in lift_fields))
    check("lift_search_rule_exact", all(token in driver for token in
          ["liftDenominatorBound = Floor[Sqrt[liftPrime]]",
           "balancedRepresentative", "CoprimeQ", "SearchKey",
           "PowerMod[denominator, -1, liftPrime]"]))
    check("no_false_qeps_nonsingularity_claim",
          '"ExactRationalPointsNonsingularOverQepsClaimed" -> False' in driver)
    check("prerequisite_status_exact",
          '"Status" -> "CF300V6dExactLiftPrerequisiteV1"' in driver)
    check("prerequisite_runs_consumer_validator", all(token in driver for token in
          ["EQWPrerequisiteValidQ", "liftPrerequisiteConsumerValid",
           '"PlanArraysRevalidated" -> True',
           '"FullResidualRevalidated" -> True']))

    parse_targets = ["RuntimeDriver", "V6eHelper", "V6eIntegrationReference",
                     "V6dOrbitCore", "V6CorrectnessOracleHelper",
                     "ExactLiftPrerequisiteSchema",
                     "ExactLiftConsumerHelper"]
    check("held_gate_has_all_targets", all(target in gate for target in parse_targets))
    check("held_gate_core_only_mode_drops_optional_consumer_sources", all(
          token in gate for token in ["parsePrerequisiteSourcesQ",
          'Last[arguments] =!= "core-only"',
          "KeyDrop[allFiles, optionalPrerequisiteSources]"]))
    check("held_parse_uses_hold_complete",
          "ToExpression[parseText, InputForm, HoldComplete]" in gate)
    check("held_parse_requires_hold_head", "Head[parsed] === HoldComplete" in gate)
    check("held_parse_requires_full_syntax_length",
          "syntaxLength === StringLength[parseText]" in gate)
    check("held_parse_requires_zero_messages", '"ZeroParserMessages"' in gate and
          "messages === {}" in gate)
    check("held_parse_strips_only_shebang", "stripShebang" in gate and
          'StringStartsQ[First[lines], "#!"]' in gate)
    check("held_parse_uses_unique_context", "CodexV6eHeldParseXH`c" in gate)
    check("held_parse_cleans_namespace", all(token in gate for token in
          ["globalBefore", "newGlobal", "parseNamesAfter",
           "removeByFullName", "cleanupPassed"]))
    check("held_parse_sources_stable", "observedAfter === observedBefore === expectedHashes" in gate)
    check("held_parse_output_atomic", all(token in gate for token in
          ["OverwriteTarget -> False", "RenameFile", "reread"]))

    failed = [label for label, passed in checks if not passed]
    print(f"CF300_V6E_RUNTIME_STATIC passed={len(checks) - len(failed)}/{len(checks)}")
    for label in failed:
        print(f"FAIL {label}")
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
