#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
second="$script_dir/run_cf300_sector12_second_support_shell_screen.wls"
context="$script_dir/run_cf300_sector12_contextual_denominator_closure_screen.wls"
second_v2="$script_dir/run_cf300_sector12_second_support_shell_screen_v2.wls"
context_v2="$script_dir/run_cf300_sector12_contextual_denominator_closure_screen_v2.wls"
second_v3="$script_dir/run_cf300_sector12_second_support_shell_screen_v3.wls"
context_v3="$script_dir/run_cf300_sector12_contextual_denominator_closure_screen_v3.wls"
hydration_probe="$script_dir/run_cf300_artifact_hydration_context_probe_v1.wls"
counts="$script_dir/verify_ansatz_counts.py"
namespace_test="$script_dir/test_reused_kernel_namespace_static.py"
poison_fixture="$script_dir/reused_kernel_global_poison_fixture.wl"
exchange=$(cd -- "$script_dir/.." && pwd)
delimiter="$exchange/flint_affine_rref_wl_xh/check_wl_delimiters.pl"
parse_guard="$exchange/direct_root_channel_assembler_xh/check_wl_no_kernel_parse_guard.pl"
passes=0
failures=0

pass() { passes=$((passes + 1)); printf 'PASS %s\n' "$1"; }
fail() { failures=$((failures + 1)); printf 'FAIL %s\n' "$1" >&2; }
require_literal() {
  local label=$1 file=$2 literal=$3
  if grep -Fq -- "$literal" "$file"; then pass "$label"; else fail "$label"; fi
}
reject_regex() {
  local label=$1 file=$2 regex=$3
  if grep -Eq -- "$regex" "$file"; then fail "$label"; else pass "$label"; fi
}
require_count() {
  local label=$1 expected=$2 file=$3 literal=$4 observed
  observed=$(grep -Fc -- "$literal" "$file" || true)
  if [[ "$observed" == "$expected" ]]; then
    pass "$label"
  else
    printf 'FAIL %s expected=%s observed=%s\n' \
      "$label" "$expected" "$observed" >&2
    failures=$((failures + 1))
  fi
}

for file in "$second" "$context" "$second_v2" "$context_v2" \
    "$second_v3" "$context_v3" "$hydration_probe" "$counts" \
    "$namespace_test" "$poison_fixture" "$delimiter" "$parse_guard"; do
  if [[ -f "$file" ]]; then pass "exists_$(basename "$file")"; else fail "exists_$(basename "$file")"; fi
done

require_count context_preparation_pin 1 "$context" \
  '6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4'
require_count context_cache_pin 1 "$context" \
  '0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be'
require_count context_census_pin 1 "$context" \
  'c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a'
require_count context_adapter_pin 1 "$context" \
  'd5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605'
require_count context_atomic_helper_pin 1 "$context" \
  'dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30'
require_literal context_target_filter_before_build "$context" \
  'selectedFingerprints = Switch[candidateSelector,'
require_literal context_single_target_build "$context" \
  '{targetBuildSeconds, target} = AbsoluteTiming[buildTarget[]]'
require_literal context_all_absent_catalog "$context" \
  'catalog = SortBy[censusArtifact["AllAbsentCandidates"]'
require_literal context_plus_x_selector "$context" '"CTX:PLUS_X"'
require_literal context_plus_xy_selector "$context" '"CTX:PLUS_XY"'
require_literal context_both_selector "$context" '"CTX:BOTH"'
require_literal context_max5_selector "$context" '"MAX5"'
require_literal max5_31_subsets "$context" '"SubsetCount" -> 31'
require_literal max5_embedding_identity "$context" \
  'P/D_S = P*(F_MAX/F_S)/D_MAX for every gauge grade and matrix entry'
require_literal max5_support_containment "$context" \
  '"RequiredSupportContainedInMAX5"'
require_literal max5_residue_identity "$context" \
  '"ResidueColumnsIdentical" -> True'
require_literal context_base_projection "$context" \
  'projectedBase = containmentProjection[targetScreenMatrix, prime]'
require_literal context_checkpoint_write "$context" \
  'milestone=image_checkpoint_committed'
require_literal context_checkpoint_resume "$context" \
  'milestone=image_checkpoint_resumed'
require_literal context_typed_final_write "$context" \
  'finalCommit = CodexDirectDiscriminatorAtomicCheckpointV2`DDACWriteAtomic['
require_literal context_four_images "$context" '"ImageID" -> "I11"'
require_literal context_max5_count "$context" \
  '"MAX5", {{10, 8}, 99, 1728, 55}'

require_literal context_v2_package_isolation "$context_v2" \
  'BeginPackage["CodexCF300ContextualDenominatorClosureDriverV2`"]'
require_literal context_v2_private_clear "$context_v2" \
  'ClearAll["CodexCF300ContextualDenominatorClosureDriverV2`Private`*"]'
require_literal context_v2_context_restore "$context_v2" \
  '(End[]; EndPackage[]; System`Exit[code])'
require_literal second_v2_package_isolation "$second_v2" \
  'BeginPackage["CodexCF300SecondSupportShellDriverV2`"]'
require_literal second_v2_private_clear "$second_v2" \
  'ClearAll["CodexCF300SecondSupportShellDriverV2`Private`*"]'
require_literal second_v2_context_restore "$second_v2" \
  '(End[]; EndPackage[]; System`Exit[code])'
require_literal context_v3_inherited_global_isolation "$context_v3" \
  'Internal`InheritedBlock[{Global`x, Global`y, Global`eps}'
require_literal context_v3_canonical_path "$context_v3" \
  'Join[{"System`", "Global`"}, $ContextPath]'
require_literal context_v3_raw_reader_agreement "$context_v3" \
  '"ReaderSameAsRawQ" -> SameQ[compiledArtifact, compiledArtifactRaw]'
require_literal context_v3_value_diagnostics "$context_v3" \
  'CF300_CONTEXT_DENOM artifact_diagnostics='
require_literal context_v3_fail_closed "$context_v3" \
  'If[! artifactContractQ,'
require_literal second_v3_inherited_global_isolation "$second_v3" \
  'Internal`InheritedBlock[{Global`x, Global`y, Global`eps}'
require_literal second_v3_canonical_path "$second_v3" \
  'Join[{"System`", "Global`"}, $ContextPath]'
require_literal second_v3_raw_reader_agreement "$second_v3" \
  '"ReaderSameAsRawQ" -> SameQ[compiledArtifact, compiledArtifactRaw]'
require_literal second_v3_value_diagnostics "$second_v3" \
  'CF300_SECOND_SHELL artifact_diagnostics='
require_literal second_v3_fail_closed "$second_v3" \
  'If[! artifactContractQ,'
require_literal probe_canonical_reader "$hydration_probe" \
  'cacheReadCanonical ='
require_literal probe_isolated_reader "$hydration_probe" \
  'cacheReadIsolated = Block['
require_literal probe_expected_context_sensitivity "$hydration_probe" \
  'expected_context_sensitivity='
require_literal poison_checkpoint_ownvalue "$poison_fixture" \
  'Global`checkpointFile ='
require_literal poison_locked_fingerprint "$poison_fixture" \
  'SetAttributes[Global`fingerprint, {Protected, Locked}]'

require_literal second_maximal_support "$second" \
  '"SecondShellSupportCount" -> 56'
require_literal second_maximal_unknowns "$second" \
  '"SecondShellUnknownCount" -> 1040'
require_literal second_maximal_points "$second" \
  '"SecondShellPointCount" -> 34'
require_literal second_checkpoint_write "$second" \
  'milestone=image_checkpoint_committed'
require_literal second_checkpoint_resume "$second" \
  'milestone=image_checkpoint_resumed'
require_literal second_projection "$second" \
  'projectedAS = targetScreenMatrix[[All, asColumnMap]]'

for file in "$context" "$second" "$context_v2" "$second_v2" \
    "$context_v3" "$second_v3" "$hydration_probe"; do
  reject_regex "no_split_context_$(basename "$file")" "$file" '`[[:blank:]]*$'
  reject_regex "no_process_control_$(basename "$file")" "$file" \
    'LaunchKernels|ParallelSubmit|RunProcess|StartProcess|KillProcess|ProcessObject|DeleteFile|SetProcessorAffinity'
  if perl "$delimiter" "$file"; then pass "delimiter_$(basename "$file")"; else fail "delimiter_$(basename "$file")"; fi
  if perl "$parse_guard" "$file"; then pass "parse_guard_$(basename "$file")"; else fail "parse_guard_$(basename "$file")"; fi
done

if python3 "$counts"; then pass count_model; else fail count_model; fi
if python3 "$namespace_test"; then pass reused_kernel_namespace; else fail reused_kernel_namespace; fi
if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if grep -nE '[[:blank:]]+$' "$context" "$second" "$context_v2" \
    "$second_v2" "$context_v3" "$second_v3" "$hydration_probe" \
    "$counts" "$namespace_test" "$poison_fixture" "$0"; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi

printf 'CF300_NEXT_ANSATZ_STATIC passes=%d failures=%d\n' "$passes" "$failures"
((failures == 0))
