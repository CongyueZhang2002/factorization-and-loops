#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
assembler="$script_dir/DirectRootChannelAssembler.wl"
oracle="$script_dir/run_direct_root_channel_adversarial_oracle.wls"
diagnostic="$script_dir/run_direct_root_channel_point_diagnostic_v2.wls"
differential="$script_dir/run_direct_root_channel_rank1_differential_diagnostic_v3.wls"
negative_probe="$script_dir/run_direct_root_channel_negative_reason_probe_v4.wls"
physical="$script_dir/run_cf300_sector12_a0_direct_comparison.wls"
protocol="$script_dir/PROTOCOL.md"
delimiter_check="$script_dir/../flint_affine_rref_wl_xh/check_wl_delimiters.pl"
passes=0
failures=0

pass() { passes=$((passes + 1)); printf 'PASS %s\n' "$1"; }
fail() { failures=$((failures + 1)); printf 'FAIL %s\n' "$1" >&2; }
require_literal() {
  local label=$1 file=$2 literal=$3
  if grep -Fq -- "$literal" "$file"; then pass "$label"; else fail "$label"; fi
}
reject_literal() {
  local label=$1 file=$2 literal=$3
  if grep -Fq -- "$literal" "$file"; then fail "$label"; else pass "$label"; fi
}

for file in "$assembler" "$oracle" "$diagnostic" "$differential" \
    "$negative_probe" "$physical" "$protocol" \
    "$delimiter_check"; do
  if [[ -f "$file" ]]; then pass "exists:${file##*/}"; else fail "exists:${file##*/}"; fi
done

require_literal exact_decompose "$assembler" 'TRFieldDecompose[expression, roots]'
require_literal exact_round_trip "$assembler" 'TRFieldCompose[channels, roots]'
require_literal sparse_polynomial_abi "$assembler" '"DRCAPolynomialExactV1"'
require_literal rational_abi "$assembler" '"DRCARationalExactV1"'
require_literal horner_collapse "$assembler" 'Fold[Mod[#1 epsilonMod + #2, prime] &'
require_literal sparse_point_dot "$assembler" 'polynomial["Coefficients"] monomials'
require_literal xor_product_grade "$assembler" 'BitXor[targetGrade, sourceGrade]'
require_literal delta_overlap "$assembler" 'BitAnd[productGrade, sourceGrade]'
require_literal derivative_grade_kronecker "$assembler" \
  'If[targetGrade === sourceGrade && a === i && b === j,'
require_literal direct_dense_rows "$assembler" 'Developer`ToPackedArray[rows]'
require_literal stable_column_order "$assembler" '"{upperRow,lowerColumn,grade0Based,supportIndex}"'
require_literal stable_row_order "$assembler" '"{outputGrade0Based,direction,upperRow,lowerColumn}"'
require_literal prime_cache "$assembler" '$drcaPrimeCache'
require_literal epsilon_cache "$assembler" '$drcaEpsilonCache'
require_literal held_cache_mutation "$assembler" \
  'SetAttributes[drcaCacheInsert, HoldFirst]'
require_literal residue_width_invariant "$assembler" \
  'DirectResidueRowWidthMismatch'
require_literal failure_only_primitive_preflight "$assembler" \
  'primitiveEvaluated = Catch[drcaEvaluateForms['
require_literal primitive_delta_reclassification "$assembler" \
  '"Point" -> point, "DeltaValues" -> primitiveDeltaValues'
require_literal primitive_gauge_reclassification "$assembler" \
  'primitiveDenominatorValue === 0'
require_literal bounded_prime_cache "$assembler" 'prime, "Forms" -> forms|>, 8]'
require_literal bounded_epsilon_cache "$assembler" '"FormsFingerprint" -> drcaStableFingerprint[forms]|>, 32]'
require_literal root_count_cap "$assembler" '$drcaMaximumRootCount = 3'
require_literal epsilon_degree_cap "$assembler" '$drcaMaximumEpsilonDegree = 256'
require_literal sparse_gapped_powers "$assembler" 'AssociationThread[requiredXExponents'
reject_literal no_dense_exponent_range "$assembler" 'Range[0, maximumX]'
require_literal source_semantic_binding "$assembler" '"SourceSemanticFingerprint"'
require_literal epsilon_image_exact_keys "$assembler" 'Sort[Keys[forms]] =!= Sort[expectedKeys]'
require_literal epsilon_image_fingerprint "$assembler" 'forms["FormsFingerprint"]'
require_literal root_square_guard "$assembler" 'Mod[rootValues^2 - deltaValues, prime]'
require_literal point_transform_shape_guard "$assembler" 'Dimensions[pointRows] =!= {gradeCount equationsPerGrade'
require_literal differential_unified_pass "$assembler" '"Passed" -> passed'
require_literal duplicate_root_rejection "$assembler" 'DuplicateRootSquares'
require_literal duplicate_point_rejection "$assembler" 'DuplicatePointModuloPrime'
require_literal duplicate_normalization_rejection "$assembler" 'DuplicateNormalizationColumns'
require_literal transform_source_completion "$assembler" 'PrototypeSourceChangedDuringSampleTransform'
require_literal transform_sample_shape "$assembler" 'InvalidSampleTransformShape'
require_literal source_hash_load "$assembler" '$drcaSourceSHA256 = FileHash'
require_literal source_hash_point_completion "$assembler" 'PrototypeSourceChangedDuringPointAssembly'
require_literal source_hash_sample_completion "$assembler" 'PrototypeSourceChangedDuringSampleAssembly'
require_literal sign_transform "$assembler" 'drcaCharacter[signMask, grade, rank]'
require_literal legacy_differential "$assembler" 'TRSplitPointRows['
require_literal accepted_point_cache "$assembler" '"CandidatePoints" -> Automatic'
require_literal telemetry "$assembler" '"DenseMaterializationSeconds"'
reject_literal no_runprocess_assembler "$assembler" 'RunProcess['
reject_literal no_toexpression_assembler "$assembler" 'ToExpression['
reject_literal no_toexpression_oracle "$oracle" 'ToExpression['
reject_literal no_toexpression_physical "$physical" 'ToExpression['

require_literal oracle_rank_range "$oracle" '{rank, 0, 3}'
require_literal oracle_select_first_point "$oracle" 'SelectFirst[candidates'
reject_literal oracle_no_return_in_do "$oracle" 'Return[point]'
require_literal oracle_typed_point_gate "$oracle" ':direct-point-assembly'
require_literal oracle_cache_runtime "$oracle" \
  'cache:held-symbol-insertion-and-reuse'
require_literal oracle_prime_one "$oracle" '"Prime" -> 10007'
require_literal oracle_prime_two "$oracle" '"Prime" -> 10039'
require_literal oracle_epsilon_one "$oracle" '"EpsilonValue" -> 1/21'
require_literal oracle_epsilon_two "$oracle" '"EpsilonValue" -> 1/11'
require_literal oracle_all_grades "$oracle" ':all-grades-active'
require_literal oracle_legacy "$oracle" ':legacy-differential'
require_literal oracle_sign_invertible "$oracle" ':sign-transform-invertible'
require_literal oracle_zero_q "$oracle" 'zero-gauge-denominator-rejected'
require_literal oracle_zero_delta "$oracle" 'zero-delta-rejected'
require_literal oracle_singular_epsilon "$oracle" 'singular-epsilon-rejected'
require_literal oracle_perturbation "$oracle" 'perturbed-channel-detected'
require_literal oracle_nonresidue_direct "$oracle" 'nonresidue-direct-point-accepted'
require_literal oracle_rank2_acceptance "$oracle" '"ExpectedRank2AttemptReduction" -> 4'
require_literal oracle_rank3_acceptance "$oracle" '"ExpectedRank3AttemptReduction" -> 8'
require_literal oracle_malformed_epsilon "$oracle" 'malformed-epsilon-image-rejected'
require_literal oracle_wrong_root "$oracle" 'wrong-root-image-rejected'
require_literal oracle_large_exponent "$oracle" 'sparse-large-support-exponent-bounded'
require_literal oracle_epsilon_cap "$oracle" 'epsilon-degree-resource-cap'
require_literal oracle_root_cap "$oracle" 'root-count-resource-cap'
require_literal oracle_a0 "$oracle" '"A0" -> Take[baseSupport, 2]'
require_literal oracle_as "$oracle" '"AS" -> baseSupport'
require_literal oracle_al "$oracle" '"AL" -> Take[baseSupport, 2]'
require_literal oracle_asl "$oracle" '"ASL" -> baseSupport'
require_literal oracle_projection "$oracle" 'projectionPassed = TrueQ['
require_literal oracle_native_a "$oracle" 'rankA = nativeRank[coefficientMatrix'
require_literal oracle_native_aug_consistent "$oracle" 'rankConsistent = nativeRank[augmentedConsistent'
require_literal oracle_native_aug_inconsistent "$oracle" 'rankInconsistent = nativeRank[augmentedInconsistent'
require_literal oracle_atomic "$oracle" 'RenameFile[temporary, outputFile'
require_literal oracle_hash_completion "$oracle" 'hashesAtCompletion = sourceHashes[]'
require_literal oracle_message_gate "$oracle" 'StringTrim[runtimeMessages] === ""'
require_literal oracle_telemetry_gate "$oracle" \
  'AssociationQ[Lookup[differential, "Telemetry", None]]'
require_literal oracle_specific_gauge_pole "$oracle" \
  '"ZeroGaugeDenominator"'
require_literal oracle_specific_delta_failure "$oracle" \
  '"DegenerateRootImage"'

require_literal diagnostic_protocol "$diagnostic" \
  'DirectRootChannelPointDiagnosticV2'
require_literal diagnostic_select_first "$diagnostic" 'SelectFirst[candidates'
require_literal diagnostic_rank_range "$diagnostic" '{rank, 0, 3}'
require_literal diagnostic_prime_cache_insert "$diagnostic" \
  'PrimeCacheSizeAfterInsert'
require_literal diagnostic_epsilon_cache_reuse "$diagnostic" \
  'EpsilonReuseExact'
require_literal diagnostic_exact_width "$diagnostic" \
  'Dimensions[pointResult["Rows"]] === expectedDimensions'
require_literal diagnostic_messages "$diagnostic" \
  'StringTrim[messages] === ""'
require_literal diagnostic_atomic "$diagnostic" \
  'RenameFile[temporary, outputFile'

require_literal differential_protocol "$differential" \
  'DirectRootChannelRank1DifferentialV3'
require_literal differential_first_mismatch "$differential" \
  'FirstOldFormulaMismatch'
require_literal differential_column_semantic "$differential" \
  '"ColumnSemantic" -> semantic'
require_literal differential_derivative_component "$differential" \
  '"DerivativeContribution" -> derivativeContribution'
require_literal differential_e_component "$differential" \
  '"EContribution" -> eContribution'
require_literal differential_c_component "$differential" \
  '"CContribution" -> cContribution'
require_literal differential_root_log "$differential" \
  '"RootLogDerivativeHalf" -> rootLogTerm'
require_literal differential_old_emulation "$differential" \
  '"OldDerivativeLeakage" -> oldLeakage'
require_literal differential_sign_order "$differential" \
  '"SignTransformOrderingEvidence"'
require_literal differential_hash_completion "$differential" \
  'completionHashes = sourceHashes[]'
require_literal differential_message_gate "$differential" \
  'StringTrim[messages] === ""'

require_literal physical_artifact_read "$physical" 'FamilyArtifactRead[preparationFile]'
require_literal physical_recursive_driver_hash "$physical" 'FileHash[preparationDriverFile, "SHA256", "HexString"]'
require_literal physical_recursive_input_hash "$physical" 'FileHash[inputFile, "SHA256", "HexString"]'
require_literal physical_672_624 "$physical" '{672, 624}'
require_literal physical_21_points "$physical" '"PointCount" -> 21'
require_literal physical_candidate_reuse "$physical" '"CandidatePoints" -> legacySample["AcceptedPoints"]'
require_literal physical_full_matrix "$physical" 'FullSampleMatrixEqual'
require_literal physical_full_rhs "$physical" 'FullSampleRightHandSideEqual'
require_literal physical_point_differential "$physical" 'DRCADifferentialCheckPoint['
require_literal physical_speedup "$physical" 'AssemblySpeedupExcludingCompilation'
require_literal physical_atomic "$physical" 'RenameFile[temporary, outputFile'
require_literal physical_hash_completion "$physical" 'completionHashes = sourceHashes[]'
require_literal physical_recursive_completion "$physical" 'recursiveSourceHashesAtCompletion'
require_literal physical_sidecar_independence "$physical" 'LocalSquareClassCertificate'
require_literal physical_sidecar_rank "$physical" 'Lookup[squareClass, "Rank", None] =!= 2'
require_literal physical_failure_message_cleanup "$physical" '"CapturedFailureMessages" -> failureMessages'

if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if perl "$delimiter_check" "$assembler" "$oracle" "$diagnostic" \
    "$differential" "$negative_probe" \
    "$physical"; then
  pass wolfram_delimiter_syntax
else
  fail wolfram_delimiter_syntax
fi
if grep -nE '[[:blank:]]+$' "$assembler" "$oracle" "$diagnostic" \
    "$differential" "$negative_probe" "$physical" \
    "$protocol" "$0"; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi
if git -C "$script_dir" diff --check -- .; then pass diff_check; else fail diff_check; fi

printf 'DIRECT_ROOT_CHANNEL_STATIC passes=%d failures=%d\n' "$passes" "$failures"
((failures == 0))
