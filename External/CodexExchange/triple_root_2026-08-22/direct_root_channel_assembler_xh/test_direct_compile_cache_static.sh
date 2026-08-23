#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
helper="$script_dir/DirectRootChannelCompiledArtifact.wl"
builder="$script_dir/run_cf300_sector12_a0_direct_compile_cache_build.wls"
validator="$script_dir/run_direct_compile_cache_validate_adversarial.wls"
delimiter="$script_dir/../flint_affine_rref_wl_xh/check_wl_delimiters.pl"
passes=0
failures=0
pass() { passes=$((passes + 1)); printf 'PASS %s\n' "$1"; }
fail() { failures=$((failures + 1)); printf 'FAIL %s\n' "$1" >&2; }
require() {
  if grep -Fq -- "$3" "$2"; then pass "$1"; else fail "$1"; fi
}
reject() {
  if grep -Fq -- "$3" "$2"; then fail "$1"; else pass "$1"; fi
}

for file in "$helper" "$builder" "$validator" "$delimiter"; do
  [[ -f "$file" ]] && pass "exists:${file##*/}" || fail "exists:${file##*/}"
done

require cache_status "$helper" 'DirectRootChannelCompiledArtifactV1'
require source_abi_key "$helper" '"SourcePreparationABIFingerprint"'
require preparation_hash_key "$helper" '"PreparationSHA256"'
require prototype_hash_key "$helper" '"PrototypeSourceSHA256"'
require runtime_hash_key "$helper" '"RuntimeSourceHashes"'
require cache_key "$helper" '"CacheKey" -> drcacFingerprint[cacheKeyPayload]'
require exact_fingerprint "$helper" '"ExactChannelFormsFingerprint"'
require compiled_fingerprint "$helper" '"CompiledFormsFingerprint"'
require shape_fingerprint "$helper" '"CompiledFormsShapeFingerprint"'
require full_assembly_validation "$helper" \
  'DRCAAssemblyPreparationValidQ['
require exact_schema "$helper" 'Sort[Keys[artifact]] =!= Sort[requiredKeys]'
require source_bound "$helper" 'drcacSourceStableQ[]'
require atomic_write "$helper" 'RenameFile[temporary, target,'
require exact_readback "$helper" 'If[! SameQ[reread, artifact]'
require safe_context "$helper" '$ContextPath = {"System`", "Global`"}'

require builder_compile "$builder" 'DRCAPrepare[preparation]'
require builder_create "$builder" 'DRCACreateCompiledArtifact['
require builder_write "$builder" 'DRCAWriteCompiledArtifact['
require builder_reread "$builder" 'DRCAReadCompiledArtifact['
require builder_fresh "$builder" 'FileExistsQ[outputFile]'
require builder_prep_pin "$builder" \
  'a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6'
require builder_assembler_pin "$builder" \
  '227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6'
require builder_helper_pin "$builder" \
  '8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557'
require builder_source_completion "$builder" 'completionHashes = sourceHashes[]'
require builder_compile_milestone "$builder" 'milestone=compile_complete'

require validator_full_read "$validator" 'DRCAReadCompiledArtifact['
require validator_contract "$validator" \
  'DirectRootChannelCompiledArtifactAdversarialValidationV1'
require validator_self_file "$validator" \
  '"ValidatorDriverFile" -> validatorDriverFile'
require validator_self_hash "$validator" \
  '"ValidatorDriverSHA256" -> driverHashBefore'
require validator_operational "$validator" 'DRCACollapseEpsilon['
require validator_roundtrip "$validator" 'ExactPutGetRoundTripPassed'
require validator_fingerprint_corruption "$validator" \
  'CompiledFingerprintCorruptionRejected'
require validator_payload_corruption "$validator" \
  'CompiledPayloadCorruptionRejected'
require validator_key_corruption "$validator" 'CacheKeyCorruptionRejected'
require validator_source_copy "$validator" 'RelocatedExactSourceCopyAccepted'
require validator_source_mutation "$validator" 'TemporarySourceMutationRejected'
require validator_truncation "$validator" 'TruncatedArtifactRejected'
require bounded_truncation "$validator" 'BinaryReadList[input, "Byte", 4096]'
require validator_cleanup "$validator" 'TemporaryFilesRemoved'
require validator_cleanup_is_gate "$validator" \
  'sourceMutationRejected, truncationRejected, temporaryFilesRemoved,'
require validator_source_completion "$validator" 'sourcesStable = TrueQ['
require validator_atomic_report "$validator" 'RenameFile[temporary, outputFile,'
reject no_actual_source_write "$validator" \
  'OpenAppend[assembly["PrototypeSourceFile"]'

for file in "$helper" "$builder" "$validator"; do
  reject "no_parallel:${file##*/}" "$file" 'LaunchKernels['
  reject "no_runprocess:${file##*/}" "$file" 'RunProcess['
  reject "no_toexpression:${file##*/}" "$file" 'ToExpression['
done

if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if perl "$delimiter" "$helper" "$builder" "$validator"; then
  pass wolfram_delimiter_syntax
else
  fail wolfram_delimiter_syntax
fi
if grep -nE '[[:blank:]]+$' "$helper" "$builder" "$validator" "$0"; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi
if git -C "$script_dir" diff --check -- .; then pass diff_check; else fail diff_check; fi
printf 'DIRECT_COMPILE_CACHE_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
