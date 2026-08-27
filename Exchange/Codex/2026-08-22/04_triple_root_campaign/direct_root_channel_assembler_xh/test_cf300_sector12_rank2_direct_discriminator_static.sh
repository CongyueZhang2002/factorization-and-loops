#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
driver="$script_dir/run_cf300_sector12_rank2_direct_ansatz_discriminator.wls"
delimiter="$script_dir/../flint_affine_rref_wl_xh/check_wl_delimiters.pl"
passes=0
failures=0

pass() { passes=$((passes + 1)); printf 'PASS %s\n' "$1"; }
fail() { failures=$((failures + 1)); printf 'FAIL %s\n' "$1" >&2; }
require_literal() {
  local label=$1 literal=$2
  if grep -Fq -- "$literal" "$driver"; then pass "$label"; else fail "$label"; fi
}
reject_literal() {
  local label=$1 literal=$2
  if grep -Fq -- "$literal" "$driver"; then fail "$label"; else pass "$label"; fi
}

if [[ -f "$driver" ]]; then pass driver_exists; else fail driver_exists; fi
if [[ -f "$delimiter" ]]; then pass delimiter_exists; else fail delimiter_exists; fi

require_literal pinned_preparation \
  'a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6'
require_literal pinned_input \
  '274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6'
require_literal pinned_assembler \
  '227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6'
require_literal pinned_adapter \
  'ec35738a2ee518ece02173fd0c1bdb7bbade2aa6455943cd418cbba1725c160c'
require_literal pinned_native_source \
  '11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd'
require_literal pinned_native_binary \
  'e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5'
require_literal direct_prepare 'CodexDirectRootChannelAssembler`DRCAPrepare['
require_literal direct_sample 'CodexDirectRootChannelAssembler`DRCAAssembleSample['
require_literal arbitrary_points '"CandidatePoints" -> Automatic'
require_literal direct_grade_basis '"MultiquadraticGradeBasis"'
require_literal nonsplit_policy 'DirectNondegeneratePointsIncludingNonsplitImages'
require_literal nonsplit_evidence '"NonsplitPointCount" -> nonsplitPointCount'
require_literal legendre_histogram '"ResidueCharacterHistogram" -> Counts[residueCharacters]'
require_literal rejection_histogram '"RejectedReasonHistogram" -> Counts['
reject_literal no_split_assembler 'TRSplitPointRows['

require_literal variants 'buildVariant["A0"'
require_literal support_variant 'buildVariant["AS"'
require_literal letter_variant 'buildVariant["AL"'
require_literal combined_variant 'buildVariant["ASL"'
require_literal widened_support 'Max /@ Transpose[widenedSupport] =!= {5, 6}'
require_literal asl_identity_projection 'variantColumnMaps["ASL"] =!='
require_literal projection_fingerprint '"ProjectionColumnMapFingerprint"'
require_literal same_point_formula '"PointCountFormula" -> "Max[4,Ceiling[(UnknownCount+32)/32]]"'
require_literal nested_prefixes '{prefixPointCount, {19, 20, 21}}'

require_literal verified_flint '"VerifiedFLINTAffineRREFRun"'
require_literal coefficient_rank 'tag <> "-coefficient"'
require_literal augmented_rank 'tag <> "-augmented"'
require_literal affine_certificate '"CertifiedAffineConsistencyByTwoRanksV1"'
require_literal rank_relation 'AugmentedRankRelationInvalid'
require_literal native_thread_cap '1 <= nativeThreads <= 8'

require_literal square_class_independent 'Lookup[squareClass, "Independent", False]'
require_literal square_class_rank 'Lookup[squareClass, "Rank", None] =!= 2'
require_literal source_closure_before 'sourceClosureBefore = sourceClosureSnapshot[]'
require_literal source_closure_completion 'sourceStateAtCompletion = currentSourceState[]'
require_literal driver_hash_completion '"Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]'
require_literal fresh_output 'FileExistsQ[outputFile]'
require_literal atomic_rename 'RenameFile[temporary, outputFile,'
require_literal post_commit_readback 'committed = Quiet[Check[Get[outputFile], $Failed]]'
require_literal direct_status 'CF300Sector12Rank2DirectAnsatzDiscriminatorV1'
require_literal milestone_load 'milestone=load_complete'
require_literal milestone_census 'milestone=census_complete'
require_literal milestone_compile_start 'milestone=asl_compile_start'
require_literal milestone_compile_complete 'milestone=asl_compile_complete'
require_literal milestone_image_assembly 'milestone=image_assembly_complete'
require_literal milestone_image_ranks 'milestone=image_ranks_complete'
require_literal separate_compile_timing '"DirectPreparationSeconds" -> directPreparationSeconds'
require_literal separate_sample_timing '"DirectSampleSeconds" -> directSeconds'

reject_literal no_toexpression 'ToExpression['
reject_literal no_runprocess 'RunProcess['
reject_literal no_parallel_kernels 'LaunchKernels['
reject_literal no_parallel_table 'ParallelTable['
reject_literal no_export 'Export['

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
if git -C "$script_dir" diff --check -- \
    "${driver#"$script_dir/"}" "${BASH_SOURCE[0]#"$script_dir/"}"; then
  pass diff_check
else
  fail diff_check
fi

printf 'CF300_RANK2_DIRECT_DISCRIMINATOR_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
