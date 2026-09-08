#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
v1="$script_dir/run_cf300_sector12_rank2_extension_prepare.wls"
v2="$script_dir/run_cf300_sector12_rank2_extension_prepare_reuse_safe_v2.wls"
delimiter="$script_dir/../flint_affine_rref_wl_xh/check_wl_delimiters.pl"
passes=0
failures=0

pass() { passes=$((passes + 1)); printf 'PASS %s\n' "$1"; }
fail() { failures=$((failures + 1)); printf 'FAIL %s\n' "$1" >&2; }
require_literal() {
  local label=$1 literal=$2
  if grep -Fq -- "$literal" "$v2"; then pass "$label"; else fail "$label"; fi
}
reject_literal() {
  local label=$1 literal=$2
  if grep -Fq -- "$literal" "$v2"; then fail "$label"; else pass "$label"; fi
}

if [[ -f "$v1" ]]; then pass v1_exists; else fail v1_exists; fi
if [[ -f "$v2" ]]; then pass v2_exists; else fail v2_exists; fi
if [[ -f "$delimiter" ]]; then pass delimiter_exists; else fail delimiter_exists; fi

v1_sha=$(sha256sum "$v1" | awk '{print $1}')
if [[ "$v1_sha" == 4389186e48d0d4c4eb1fdb10b3a849306ba9354e977dde00eb60b3a3d46e71dd ]]; then
  pass immutable_v1_hash
else
  fail immutable_v1_hash
fi

require_literal dependency_hash_before \
  'dependencyHashesBefore = Map['
require_literal dependency_hash_after_load \
  'dependencyHashesAfterLoad = Map['
require_literal dependency_hash_completion \
  'dependencyHashesAtCompletion = Map['
require_literal input_hash_before \
  'inputHashBefore = FileHash[inputFile, "SHA256", "HexString"]'
require_literal input_hash_after_read \
  'inputHashAfterRead = FileHash[inputFile, "SHA256", "HexString"]'
require_literal input_hash_completion \
  'inputHashAtCompletion = FileHash[inputFile, "SHA256", "HexString"]'
require_literal driver_hash_before \
  'driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"]'
require_literal driver_hash_after_load \
  'driverHashAfterLoad = FileHash[$InputFileName, "SHA256", "HexString"]'
require_literal driver_hash_completion \
  'driverHashAtCompletion = FileHash[$InputFileName,'

require_literal holdfirst_capture \
  'SetAttributes[captureMessageTolerantLoad, HoldFirst]'
require_literal message_tolerant_quiet \
  'result = CheckAbort[Quiet[expression], $Aborted]'
require_literal runtime_source_files \
  'FeynFacet`Private`$feynFacetSourceFiles'
require_literal runtime_source_hash \
  'FeynFacet`Private`$feynFacetSourceHash'
require_literal observed_source_hash \
  'Hash[FileHash[#1, "SHA256"] & /@ runtimeFiles,'
require_literal required_files_subset \
  'Complement[requiredFeynFacetFiles, runtimeFiles] === {}'
require_literal source_directory_seal \
  'StringStartsQ[ExpandFileName[#1], sourceDirectory] &'
require_literal context_guard_definition \
  'StringContainsQ[readerDefinitionText, "$ContextPath"]'
require_literal context_guard_system \
  'StringContainsQ[readerDefinitionText, "System`"]'
require_literal context_guard_global \
  'StringContainsQ[readerDefinitionText, "Global`"]'
require_literal chart_semantic_probe \
  'FeynFacet`TransportFamilyChart["CF300"]'
require_literal reuse_validated_runtime \
  'feynFacetLoadMode = "ReuseValidatedFeynFacetRuntime"'
require_literal direct_public_reload \
  'feynFacetLoadMode = "ReloadFeynFacetPublicWithExistingFeynCalc"'
require_literal localized_basis_reload \
  'Block[{Global`nb, Global`n, Global`xhat, Global`yhat},'
require_literal fallback_reload \
  'ReloadFeynFacetPublicThenLoadFACETWithLocalizedBasisSymbols'
require_literal feynfacet_postcondition \
  '"ValidatedFeynFacetRuntimeV2"'
require_literal triple_root_postcondition \
  '"ValidatedTripleRootRuntimeV2"'
require_literal load_fail_closed \
  'finish["RuntimeLoadValidationFailed", <||>, 66]'
require_literal load_certificate_success \
  '"LoadCertificate" -> loadCertificate'

require_literal context_safe_artifact_read \
  'record = FeynFacet`FamilyArtifactRead[inputFile]'
reject_literal no_raw_input_get 'Get[inputFile]'
reject_literal no_global_clear 'Clear[Global`n]'
reject_literal no_global_unset 'Global`n =.'
reject_literal no_unprotect 'Unprotect['
reject_literal no_kernel_launch 'LaunchKernels['
reject_literal no_runprocess 'RunProcess['
reject_literal no_quit 'Quit['

require_literal preserved_status \
  '"Status" -> "PreparedCF300Sector12Rank2Extension"'
require_literal preserved_sidecar_validation \
  'PrecomputedChannelSidecarCertificateFailed'
require_literal preserved_abi_validation \
  'TRPreparationABIValidQ[preparation]'
require_literal preserved_unknown_cap \
  'preparation["UnknownCount"] > unknownCap'

if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if perl "$delimiter" "$v2"; then
  pass wolfram_delimiter_syntax
else
  fail wolfram_delimiter_syntax
fi
if grep -nE '[[:blank:]]+$' "$v2" "$0"; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi

printf 'RANK2_PREPARATION_REUSE_SAFE_V2_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
