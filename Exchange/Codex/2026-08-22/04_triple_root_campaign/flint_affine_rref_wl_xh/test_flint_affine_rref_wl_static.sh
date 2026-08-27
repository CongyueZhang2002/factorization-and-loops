#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
adapter="$script_dir/FlintAffineRREFAdapter.wl"
smoke="$script_dir/run_flint_affine_rref_differential_smoke.wls"
protocol="$script_dir/PROTOCOL.md"
assessment="$script_dir/ASSESSMENT.md"
native_module="$script_dir/NativeAffinePilotPrime.wl"
native_prime="$script_dir/run_cf300_sector12_rank2_native_prime.wls"
physical_benchmark="$script_dir/run_cf300_sector12_rank2_native_pilot_benchmark.wls"
delimiter_check="$script_dir/check_wl_delimiters.pl"
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

for file in "$adapter" "$smoke" "$protocol" "$assessment" "$native_module" \
    "$native_prime" "$physical_benchmark" "$delimiter_check"; do
  if [[ -f "$file" ]]; then pass "exists:${file##*/}"; else fail "exists:${file##*/}"; fi
done

require_literal input_magic "$adapter" 'ToCharacterCode["CFFR1V1\000"]'
require_literal output_magic "$adapter" 'ToCharacterCode["CFFR1X1\000"]'
require_literal exact_output_header "$adapter" '$cffrOutputHeaderWords = 11'
require_literal nonce_binding "$adapter" '{nonceHi, nonceLo} =!= request["Nonce"]'
require_literal exact_size_gate "$adapter" 'FileByteCount[file] =!= expectedBytes'
require_literal exact_eof_gate "$adapter" 'eof =!= EndOfFile'
require_literal zero_based_wire "$adapter" 'request["Preference"] - 1'
require_literal affine_residual "$adapter" 'matrix . particular - right'
require_literal nullspace_residual "$adapter" 'matrix . Transpose[nullspace]'
require_literal canonical_free_identity "$adapter" 'nullspace[[All, free]] === IdentityMatrix[nullity]'
require_literal canonical_pivot_actual_columns "$adapter" 'nullspace[[index, pivot[[forbiddenPositions]]]]'
reject_literal canonical_pivot_position_bug "$adapter" 'nullspace[[index, forbidden]]'
require_literal derived_particular "$adapter" '"DerivedCanonicalParticular"'
require_literal derived_nullspace "$adapter" '"DerivedCanonicalNullspace"'
require_literal explicit_large_identity "$adapter" 'identity = Normal[IdentityMatrix[size]]'
require_literal row_inverse_both_sides "$adapter" 'Normal[Mod[matrix . inverse, prime]] === identity'
require_literal inverse_other_side "$adapter" 'Normal[Mod[inverse . matrix, prime]] === identity'
require_literal greedy_preference "$adapter" 'cffrGreedyNormalizationColumns'
require_literal v1_plan_status "$adapter" '"Status" -> "CrossPrimeEliminationPlanV1"'
require_literal v1_fingerprint "$adapter" '"PlanFingerprint" -> cffrStableFingerprint[payload]'
require_literal plan_matrix_binding "$adapter" 'request["Matrix"] =!= Mod[Normal[sample["Matrix"]], request["Prime"]]'
require_literal production_preference_binding "$adapter" 'request["Preference"] =!= Join['
require_literal no_shell_process "$adapter" 'RunProcess[{ExpandFileName[binary], input, output, ToString[threads]}]'
reject_literal no_shell_command "$adapter" 'RunProcess["'
reject_literal no_to_expression_adapter "$adapter" 'ToExpression['
reject_literal no_to_expression_smoke "$smoke" 'ToExpression['
require_literal differential_oracle "$smoke" 'TRCanonicalAffineSolve['
require_literal smoke_load_facet "$smoke" 'Get[dependencyFiles["LoadFACET"]]'
require_literal smoke_load_algebra "$smoke" 'Get[dependencyFiles["TripleRootAlgebra"]]'
require_literal smoke_load_strip "$smoke" 'Get[dependencyFiles["TripleRootStripAdapter"]]'
require_literal smoke_load_pilot "$smoke" 'Get[dependencyFiles["TripleRootAffinePilot"]]'
require_literal smoke_dependency_hashes "$smoke" 'dependencyHashesBefore = Map['
require_literal smoke_adapter_hash "$smoke" 'adapterHashBefore = FileHash[adapter'
require_literal smoke_binary_hash "$smoke" 'binaryHashBefore = FileHash[binary'
require_literal smoke_driver_hash "$smoke" 'driverHashBefore = FileHash[$InputFileName'
require_literal smoke_load_message_capture "$smoke" '$Messages = {loadMessageStream}'
require_literal smoke_runtime_message_capture "$smoke" '$Messages = {runtimeMessageStream}'
require_literal smoke_load_message_gate "$smoke" 'StringTrim[loadMessageText] === ""'
require_literal smoke_runtime_message_gate "$smoke" 'StringTrim[runtimeMessageText] === ""'
require_literal smoke_persistent_symbol_clear "$smoke" 'ClearAll[strictNonnegativeInteger, writeReportAtomic, record,'
require_literal smoke_assertion_floor "$smoke" 'minimumExpectedAssertions = caseCount + 20'
require_literal smoke_assertion_fail_closed "$smoke" '"assertion-cardinality-fail-closed"'
require_literal smoke_strip_definition_gate "$smoke" 'CodexTripleRootStrip`TRClassifyStripRecord'
require_literal smoke_pilot_definition_gate "$smoke" 'CodexTripleRootPilot`TRSplitPointRows'
require_literal smoke_hash_completion_gate "$smoke" 'sourceHashesStableAtCompletion = TrueQ['
require_literal smoke_load_failure_status "$smoke" 'FLINTAffineRREFDifferentialSmokeLoadFailed'
require_literal corrupt_magic "$smoke" '"magic" -> ReplacePart'
require_literal corrupt_nonce "$smoke" '"nonce" -> ReplacePart'
require_literal corrupt_modulus "$smoke" '"modulus" -> ReplacePart'
require_literal corrupt_dimensions "$smoke" '"dimensions" -> ReplacePart'
require_literal corrupt_rank_nullity "$smoke" '"rank-nullity" -> ReplacePart'
require_literal corrupt_flags "$smoke" '"flags" -> ReplacePart'
require_literal corrupt_wire_index "$smoke" '"out-of-range-pivot" -> setU64LE'
require_literal corrupt_duplicate_index "$smoke" '"duplicate-pivot" -> setU64LE'
require_literal corrupt_unsorted_indices "$smoke" '"unsorted-pivots" -> setU64LE'
require_literal corrupt_residue_word "$smoke" '"noncanonical-residue" -> setU64LE'
require_literal corrupt_truncation "$smoke" '"truncated" -> Most[responseBytes]'
require_literal corrupt_trailing "$smoke" '"trailing-byte" -> Append[responseBytes, 0]'
require_literal corrupt_row_witness "$smoke" 'corrupt-row-inverse-rejected'
require_literal corrupt_normalization_witness "$smoke" 'corrupt-normalization-inverse-rejected'
require_literal inconsistent_system "$smoke" 'inconsistent-system-fails-closed'
require_literal gapped_pivot_matrix "$smoke" 'gappedPivotMatrix = {{1, 7, 0, 5}, {0, 0, 1, 9}}'
require_literal gapped_pivot_expected_columns "$smoke" '"PivotColumns", None] === {1, 3}'
require_literal gapped_free_expected_columns "$smoke" '"FreeColumns", None] === {2, 4}'
require_literal gapped_pivot_regression "$smoke" 'gapped-pivot-canonical-order:actual-column-regression'
require_literal typed_inconsistent_exit "$adapter" '$cffrInconsistentExitCode = 5'
require_literal typed_inconsistent_status "$adapter" 'cffrFailure["InconsistentAffineImage"'
require_literal native_bounded_probe_option "$native_module" '"NativeProbeCount" -> 4'
require_literal native_consistent_probe_floor "$native_module" '"MinimumConsistentNativeProbes" -> 2'
require_literal native_generic_rank "$native_module" 'genericProbeRank = Max['
require_literal native_earliest_maximum "$native_module" 'EarliestMaximumRankAcrossBoundedNativeProbes'
require_literal native_inconsistent_exclusion "$native_module" 'MemberQ[inconsistentProbeIndices, epsilonIndex]'
require_literal native_request "$native_module" 'CFFRMakeRequest['
require_literal native_certificate_verify "$native_module" 'CFFRVerifyCertificate['
require_literal native_v1_plan "$native_module" 'CFFRConstructCrossPrimePlanV1['
require_literal fixed_plan_remaining "$native_module" 'trSolveReconstructionWithPlan['
require_literal dynamic_usable_floor "$native_module" 'minimumUsableSampleCount < constructionCount + 4'
require_literal retained_failures "$native_module" '"SampleFailures" -> failures'
require_literal discarded_images "$native_module" '"DiscardedEpsilonValues" -> discardedEpsilonValues'
require_literal fixed_plan_backend_contract "$native_module" 'Lookup[#1, "Backend", None] === "FLINT"'
require_literal epsilon_interpolation "$native_module" 'InterpolateEpsFormStripAffine['
require_literal all_row_particular "$native_module" '"ResidualZero", False'
require_literal all_row_nullspace "$native_module" '"NullspaceResidualZero", False'
require_literal discover_reuse_cli "$native_prime" '<discover|reuse>'
require_literal candidate_pool_default "$native_prime" 'parseStrictInteger[arguments[[7]]], 48'
require_literal configurable_native_probe_count "$native_prime" 'parseStrictInteger[arguments[[10]]], 4'
require_literal configurable_probe_floor "$native_prime" 'parseStrictInteger[arguments[[11]]], 2'
reject_literal no_exact_48_driver_gate "$native_prime" 'sampleCount =!= 48'
reject_literal no_zero_failure_driver_gate "$native_prime" 'Lookup[result, "SampleFailures", None] =!= {}'
require_literal same_native_driver_hash "$native_prime" 'Lookup[planSourceArtifact, "DriverSHA256", None] =!= driverHashBefore'
require_literal native_binary_hash "$native_prime" '"NativeBinarySHA256" -> nativeBinaryHashBefore'
require_literal fixed_binary_hash "$native_prime" '"FixedPlanFLINTBinarySHA256" -> fixedPlanFLINTBinaryHashBefore'
require_literal source_certificate_reverify "$native_prime" 'PlanSourceNativeCertificateReverificationFailed'
require_literal aggregate_status "$native_prime" '"RationalAffinePrimeInterpolated"'
require_literal physical_threads "$physical_benchmark" '{threads, {1, 2, 4}}'
require_literal physical_cross_prime_probes "$physical_benchmark" 'probePrimes = {10007, 10039, 10067}'
require_literal physical_epsilon_probes "$physical_benchmark" 'probeEpsilonValues = (#1/(#1 + 20) &) /@ Range[4]'
require_literal physical_typed_inconsistency "$physical_benchmark" '"Status" -> "InconsistentAffineImage"'
require_literal physical_cross_prime_floor "$physical_benchmark" 'minimumDistinctConsistentPrimes = 2'
require_literal physical_generic_maximum "$physical_benchmark" 'genericProbeRank = Max['
require_literal physical_exact_shape "$physical_benchmark" 'sample["MatrixDimensions"] =!= {672, 624}'
require_literal physical_cross_thread_plan "$physical_benchmark" '"CrossThreadPlansIdentical" -> True'
require_literal physical_full_certificate "$physical_benchmark" '"ReferenceCertificate" -> First[certificates]'
for file in "$adapter" "$smoke" "$native_module" "$native_prime" \
    "$physical_benchmark"; do
  reject_literal "no_ToExpression:${file##*/}" "$file" 'ToExpression['
done

if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if perl "$delimiter_check" "$adapter" "$smoke" "$native_module" \
    "$native_prime" "$physical_benchmark"; then
  pass wolfram_delimiter_syntax
else
  fail wolfram_delimiter_syntax
fi
if git -C "$script_dir" diff --check -- .; then pass diff_check; else fail diff_check; fi
if grep -nE '[[:blank:]]+$' "$adapter" "$smoke" "$protocol" "$assessment" \
    "$native_module" "$native_prime" "$physical_benchmark" "$0"; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi

printf 'FLINT_AFFINE_RREF_WL_STATIC passes=%d failures=%d\n' "$passes" "$failures"
((failures == 0))
