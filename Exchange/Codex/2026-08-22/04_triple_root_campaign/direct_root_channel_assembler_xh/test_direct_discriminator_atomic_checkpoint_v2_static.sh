#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
v1="$script_dir/run_cf300_sector12_rank2_direct_ansatz_discriminator.wls"
v2="$script_dir/run_cf300_sector12_rank2_direct_ansatz_discriminator_v2.wls"
helper="$script_dir/DirectDiscriminatorAtomicCheckpointV2.wl"
integration="$script_dir/run_cf300_sector12_rank2_direct_ansatz_discriminator_v2.integration.patch"
delimiter="$script_dir/../flint_affine_rref_wl_xh/check_wl_delimiters.pl"
parse_guard="$script_dir/check_wl_no_kernel_parse_guard.pl"
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

for file in "$v1" "$v2" "$helper" "$integration" "$delimiter" "$parse_guard"; do
  if [[ -f "$file" ]]; then pass "exists_$(basename "$file")"; else fail "exists_$(basename "$file")"; fi
done

v1_sha=$(sha256sum "$v1" | awk '{print $1}')
helper_sha=$(sha256sum "$helper" | awk '{print $1}')
if [[ "$v1_sha" == 3a3093357f16094f311b98be305bac05f2b22b89f0fe5be586d1369cf6de29fa ]]; then
  pass immutable_v1_hash
else
  fail immutable_v1_hash
fi
if [[ "$helper_sha" == dbd36f7f078f08ed329490dd6b91bef950d977a1d70474ce2ccd6d8617fcad30 ]]; then
  pass helper_hash
else
  fail helper_hash
fi
require_count helper_hash_pinned_twice 2 "$v2" "$helper_sha"
require_count helper_hash_in_patch_twice 2 "$integration" "$helper_sha"
require_count postmerge_preparation_pin 1 "$v2" \
  '6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4'
require_count corrected_adapter_pins 2 "$v2" \
  'd5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605'
require_count integration_postmerge_preparation 1 "$integration" \
  '6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4'
require_count integration_corrected_adapter 2 "$integration" \
  'd5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605'
reject_literal no_stale_preparation_pin "$v2" \
  'a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6'
reject_literal no_stale_adapter_pin "$v2" \
  'ec35738a2ee518ece02173fd0c1bdb7bbade2aa6455943cd418cbba1725c160c'

require_literal held_message_capture "$helper" 'SetAttributes[ddacMessages, HoldFirst]'
require_literal empty_rejection_guard "$helper" 'If[rejected === {}, Return[<||>]]'
require_literal reserved_integrity_key "$helper" 'ReservedIntegrityKeyPresent'
require_literal payload_seal_stage "$helper" 'PayloadSealFailed'
require_literal temporary_put_stage "$helper" 'TemporaryPutFailed'
require_literal temporary_readback_stage "$helper" 'TemporaryReadbackInvalid'
require_literal precommit_stage "$helper" 'PreCommitCheckFailed'
require_literal rename_stage "$helper" 'AtomicRenameFailed'
require_literal committed_hash_stage "$helper" 'CommittedByteHashMismatch'
require_literal committed_readback_stage "$helper" 'CommittedReadbackInvalid'
require_literal postcommit_stage "$helper" 'PostCommitCheckFailed'
require_literal preserved_evidence "$helper" '"EvidencePreserved" -> True'
require_literal sealed_reader "$helper" 'DDACReadSealed[file_String]'
require_literal rank_summary_helper "$helper" 'DDACRankSummary[variantResults_Association'
require_literal rank_summary_relation "$helper" 'summary["CoefficientRank"] + 1'
reject_literal no_delete_helper "$helper" 'DeleteFile['

require_literal helper_in_source_closure "$v2" 'DirectDiscriminatorAtomicCheckpointV2.wl" ->'
require_literal checkpoint_symbols_local "$v2" 'checkpointFile, checkpointRead, checkpointPayload, checkpointCommit,'
require_literal typed_final_writer "$v2" 'finalCommit = CodexDirectDiscriminatorAtomicCheckpointV2`DDACWriteAtomic['
require_literal typed_failure_telemetry "$v2" 'FAIL typed_atomic_commit='
require_literal checkpoint_status "$v2" 'CF300Sector12Rank2DirectImageCheckpointV2'
require_literal checkpoint_commit "$v2" 'milestone=image_checkpoint_committed'
require_literal checkpoint_resume "$v2" 'milestone=image_checkpoint_resumed'
require_literal checkpoint_driver_pin "$v2" 'checkpointPayload["DriverSHA256"] =!= driverHashBefore'
require_literal checkpoint_runtime_pin "$v2" 'checkpointPayload["RuntimeHashes"] =!= namedRuntimeHashesBefore'
require_literal checkpoint_source_closure_pin "$v2" 'checkpointPayload["SourceClosure"] =!= sourceClosureBefore'
require_literal immediate_rank_summary "$v2" 'CF300S12R2DIRECTDISC rank_summary image='
require_literal empty_safe_histogram_call "$v2" 'DDACRejectedReasonHistogram[rejectedPoints]'
reject_regex no_split_context_token "$v2" '`[[:blank:]]*$'
require_literal v2_status "$v2" 'CF300Sector12Rank2DirectAnsatzDiscriminatorV2'
reject_literal no_old_histogram_bug "$v2" 'Counts[Lookup[directSample["RejectedPoints"]'
reject_literal no_old_atomic_race_label "$v2" 'FAIL atomic output race'
reject_literal no_delete_driver "$v2" 'DeleteFile['
reject_literal no_parallel_kernels "$v2" 'LaunchKernels['
reject_literal no_runprocess "$v2" 'RunProcess['

require_literal integration_begin "$integration" '*** Begin Patch'
require_literal integration_target "$integration" '*** Update File: run_cf300_sector12_rank2_direct_ansatz_discriminator_v2.wls'
require_literal integration_end "$integration" '*** End Patch'
require_literal integration_empty_fix "$integration" 'DDACRejectedReasonHistogram[rejectedPoints]'
reject_regex integration_no_split_context_token "$integration" '`[[:blank:]]*$'
require_literal integration_checkpoint "$integration" 'ImageCheckpointCommitFailed'
require_literal integration_typed_writer "$integration" 'AtomicWriteCommittedV2'

if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if perl -c "$parse_guard" >/dev/null; then pass parse_guard_perl_syntax; else fail parse_guard_perl_syntax; fi
if perl "$delimiter" "$helper"; then pass helper_wolfram_delimiters; else fail helper_wolfram_delimiters; fi
if perl "$delimiter" "$v2"; then pass v2_wolfram_delimiters; else fail v2_wolfram_delimiters; fi
if perl "$parse_guard" "$helper"; then pass helper_no_kernel_parse_guard; else fail helper_no_kernel_parse_guard; fi
if perl "$parse_guard" "$v2"; then pass v2_no_kernel_parse_guard; else fail v2_no_kernel_parse_guard; fi
if printf 'value = BrokenContext`\n  name[];\n' |
    perl "$parse_guard" - >/dev/null 2>&1; then
  fail parse_guard_rejects_split_context
else
  pass parse_guard_rejects_split_context
fi
if printf '"String context`\n text"; (* CommentContext`\n token *) Good`name[];\n' |
    perl "$parse_guard" - >/dev/null 2>&1; then
  pass parse_guard_ignores_strings_and_comments
else
  fail parse_guard_ignores_strings_and_comments
fi
if printf 'value = Function[1;\n' |
    perl "$parse_guard" - >/dev/null 2>&1; then
  fail parse_guard_rejects_unclosed_delimiter
else
  pass parse_guard_rejects_unclosed_delimiter
fi
if grep -nE '[[:blank:]]+$' "$helper" "$v2" "$integration" "$0"; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi

printf 'DIRECT_DISCRIMINATOR_ATOMIC_CHECKPOINT_V2_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
