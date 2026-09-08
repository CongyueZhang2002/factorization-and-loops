#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
driver="$script_dir/run_cf300_sector12_a0_direct_common_stream_benchmark.wls"
delimiter="$script_dir/../flint_affine_rref_wl_xh/check_wl_delimiters.pl"
passes=0
failures=0
pass() { passes=$((passes + 1)); printf 'PASS %s\n' "$1"; }
fail() { failures=$((failures + 1)); printf 'FAIL %s\n' "$1" >&2; }
require() {
  if grep -Fq -- "$2" "$driver"; then pass "$1"; else fail "$1"; fi
}
reject() {
  if grep -Fq -- "$2" "$driver"; then fail "$1"; else pass "$1"; fi
}

[[ -f "$driver" ]] && pass driver_exists || fail driver_exists
[[ -f "$delimiter" ]] && pass delimiter_exists || fail delimiter_exists
require pinned_preparation \
  'a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6'
require pinned_assembler \
  '227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6'
require pinned_cache_helper \
  '8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557'
require pinned_validator \
  '7565022c17c29c4b2c0f3e2661f6890db0ebb1ef1fc457623a8642f6e00d02d9'
require pinned_cache_builder \
  'd65a6bb912148d0add608fc347147e7f67e7c4ba67f92319afc309875e7a879f'
require cached_only_usage '<compiled-cache.wl> <passed-validation-report.wl>'
require cached_input_mode \
  '"PreviouslyAdversariallyValidatedCompiledCache"'
require validation_contract \
  'DirectRootChannelCompiledArtifactAdversarialValidationV1'
require passed_validation_status \
  'DirectRootChannelCompiledArtifactValidationPassed'
require full_cache_read 'DRCAReadCompiledArtifact['
require full_cache_validation 'DRCACompiledArtifactValidQ['
require validation_cache_hash \
  'validationReport["CacheFileSHA256"] =!= cacheHashBefore'
require validation_cache_key \
  'compiledArtifact["CacheKey"] === validationReport["CacheKey"]'
require validation_assembly_fingerprint \
  'validationReport["AssemblyFingerprint"]'
require preparation_abi_binding \
  'preparation["ABIFingerprint"]'
require root_order_binding \
  'preparation["RootOrderingFingerprint"]'
require raw_input_binding \
  'builderProvenance["PreparationInputSHA256"]'
require preparation_driver_binding \
  'builderProvenance["PreparationDriverSHA256"]'
require builder_source_binding \
  'builderProvenance["BuilderDriverSHA256"]'
require runtime_source_binding \
  'currentBuilderRuntimeHashes ==='
require recursive_source_binding \
  'currentBuilderRecursiveHashes ==='
require all_adversarial_booleans 'validationBooleanKeys = {'
require no_compilation_report '"DirectCompilationPerformed" -> False'
require common_stream '"CandidatePoints" -> candidateStream'
require candidate_budget 'candidateBudget = 2048'
require survey_size 'surveyPointCount = 256'
require direct_attempt_position \
  'directAttemptCount = rawPosition[candidateStream, Last[directPoints]]'
require split_attempt_position \
  'splitAttemptCount = rawPosition[candidateStream, Last[splitPoints]]'
require character_histogram '"ResidueCharacterHistogram" -> characterHistogram'
require rejection_histogram '"SurveyRejectedReasonHistogram"'
require nonsplit_evidence '"DirectTargetNonsplitPointCount"'
require expected_factor '"ExpectedRank2AttemptReduction" -> 4'
require seven_repetitions 'repetitions = 7'
require cache_clear 'DRCAClearCaches[]'
require cold_timing '"DirectCold"'
require warm_direct '"DirectArbitraryWarm"'
require warm_split '"DirectSplitWarm"'
require warm_transform '"SignTransformWarm"'
require same_split_points 'legacyRowsAt[splitPoints]'
require exact_matrix '"CommonPointMatrixEqual"'
require exact_rhs '"CommonPointRightHandSideEqual"'
require median_mad '"MAD" -> Median[Abs[values - median]]'
require rows_per_second '"RowsPerPointAssemblySecondMedian"'
require like_for_like '"LikeForLikeSignBasisMedianSpeedup"'
require grade_basis '"TransformFreeGradeBasisMedianSpeedup"'
require timing_scope '"TimingScope"'
require atomic_output 'RenameFile[temporary, outputFile,'
require completion_hashes 'completionHashes = sourceHashes[]'
require recursive_hashes 'recursiveSourceHashesAtCompletion'
require milestone_cache_read 'milestone=cache_read_complete'
require milestone_survey 'milestone=survey_complete'
require milestone_legacy 'milestone=legacy_hot_complete'
require milestone_complete 'milestone=complete'
reject no_parallel_kernels 'LaunchKernels['
reject no_runprocess 'RunProcess['
reject no_toexpression 'ToExpression['
reject no_direct_compile 'DRCAPrepare['
reject no_uncached_mode 'Uncached'

if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if perl "$delimiter" "$driver"; then
  pass wolfram_delimiter_syntax
else
  fail wolfram_delimiter_syntax
fi
if grep -nE '[[:blank:]]+$' "$driver" "$0"; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi
if git -C "$script_dir" diff --check -- .; then pass diff_check; else fail diff_check; fi
printf 'CF300_DIRECT_BENCHMARK_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
