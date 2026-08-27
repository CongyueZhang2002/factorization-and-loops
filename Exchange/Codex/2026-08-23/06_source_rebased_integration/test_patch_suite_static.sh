#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "$script_dir/../../.." && pwd)
p1="$script_dir/01_finite_field_backend_plan_artifact.apply_patch"
p2="$script_dir/02_solver_failure_resume_provenance.apply_patch"
p3="$script_dir/03_deferred_row_gauge_regulator_seal.apply_patch"
p4="$script_dir/04_adversarial_mutants.apply_patch"
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
hash_is() {
  local label=$1 file=$2 expected=$3 actual
  actual=$(sha256sum "$file" | awk '{print $1}')
  if [[ "$actual" == "$expected" ]]; then pass "$label"; else
    printf 'expected=%s actual=%s file=%s\n' \
      "$expected" "$actual" "$file" >&2
    fail "$label"
  fi
}

hash_is preimage_finite_field \
  "$repo/FeynFacet/Private/FiniteFieldStripSolve.wl" \
  c6230ae8b6b1d00780ca697cf9e6838a395682a7eabe626b17c8371357bb1671
hash_is preimage_resume \
  "$repo/FeynFacet/Private/FamilyRowGaugeResume.wl" \
  e9719e551fcd1930dfbce478a25880d7393a9b6ab3dcf1d2a9672cf0bf4c5dde
hash_is preimage_sector \
  "$repo/Scripts/family_epsform_sector.wls" \
  60cc272a0b28da47d670984f401286f4ec29854b6216b7f36580bcde43e4a660
hash_is preimage_regulator \
  "$repo/FeynFacet/Private/FamilyRegulatorFactor.wl" \
  6e26a8eec72780a6fea52f5c72f32a4ac314b1cd436d6fdb09808e4e84f83b60
hash_is preimage_row_materializer \
  "$repo/FeynFacet/Private/FamilyRowGauge.wl" \
  ebe728cf47d61b01552178a03001bf91297dcadd43a545b28ba83f9d00a71e1b
hash_is preimage_transport_charts \
  "$repo/FeynFacet/Private/TransportCharts.wl" \
  c30e2e54b63abe9eb6c3b82ec2d275b8f4bb247007f2a93fa7db879399de051a

for file in "$p1" "$p2" "$p3" "$p4"; do
  [[ -f "$file" ]] && pass "exists:${file##*/}" || fail "exists:${file##*/}"
  [[ $(head -n 1 "$file") == '*** Begin Patch' ]] &&
    pass "begin:${file##*/}" || fail "begin:${file##*/}"
  [[ $(tail -n 1 "$file") == '*** End Patch' ]] &&
    pass "end:${file##*/}" || fail "end:${file##*/}"
  [[ $(grep -c '^\*\*\* Begin Patch$' "$file") -eq 1 ]] &&
    pass "single_begin:${file##*/}" || fail "single_begin:${file##*/}"
  [[ $(grep -c '^\*\*\* End Patch$' "$file") -eq 1 ]] &&
    pass "single_end:${file##*/}" || fail "single_end:${file##*/}"
  if grep -q '^diff --git ' "$file"; then
    fail "no_git_diff_grammar:${file##*/}"
  else
    pass "no_git_diff_grammar:${file##*/}"
  fi
done

require exhaustive_fixed_core_backend "$p1" \
  'MemberQ[{Automatic, "Wolfram", "FLINT"}, requested]'
require explicit_flint_no_fallback "$p1" \
  '"FallbackAllowed" -> False'
require plan_discovery_distinct "$p1" \
  '"FLINTAffineRREF"'
require plan_discovery_current_used "$p1" \
  '"PlanDiscoveryBackendUsed" -> "Wolfram"'
require sealed_plan "$p1" \
  'finiteFieldStripSealEliminationPlan['
require strict_plan_keys "$p1" \
  'Sort[$finiteFieldStripEliminationPlanRequiredKeys]'
require canonical_native_residues "$p1" \
  'AllTrue[Flatten[solution], Between[#, {0, prime - 1}] &]'
require artifact_plan_binding "$p1" \
  '"EliminationPlanFingerprint"'
require artifact_backend_binding "$p1" \
  '"BackendConfiguration"'
require artifact_plan_discovery_binding "$p1" \
  '"PlanDiscoveryBackend"'

require solver_schema_two "$p2" \
  '$familyRowGaugeSolverConfigurationSchemaVersion = 2'
require complete_sector_provenance "$p2" \
  '"family_epsform_sector.wls"'
require complete_materializer_provenance "$p2" \
  '"FamilyRowGauge.wl"'
require backend_binary_provenance "$p2" \
  '"BackendImplementationProvenance"'
require resume_sameq_binding "$p2" \
  'SameQ[saved, expected]'
require bounded_failure "$p2" 'ByteCount[value] <= 4096'
require unsolved_failure_record "$p2" '"SolverFailure" ->'
reject no_failure_gauge_whitelist "$p2" 'keys = {"Gauge"'
reject no_failure_samples_whitelist "$p2" 'keys = {"Samples"'

require constant_guard "$p3" \
  '"RegulatorTransformationNotConstant"'
require inverse_guard "$p3" \
  '"RegulatorTransformationInverseInvalid"'
require factor_seal "$p3" \
  '"RegulatorPropagationSealMismatch"'
require factor_seal_created_twice "$p3" \
  '"PropagationSeal" -> familyRegulatorPropagationSeal['
require production_deferred_only "$p3" \
  'futureAMode = If[productionQ && installedRow =!= Automatic'
require intended_s_direction "$p3" \
  'state["S"], tFull, False]'
require intended_inverse_direction "$p3" \
  'tInv, state["SInverse"], True]'

require noncanonical_mutant "$p4" \
  'CongruentButNoncanonicalNativeResiduesRejected'
require stale_cache_mutant "$p4" \
  'WolframCacheRejectedForDifferentFixedCoreRequest'
require discovery_mutant "$p4" \
  'NativeAffineRREFNotSmuggledThroughFixedCore'
require variable_transform_mutant "$p4" \
  'regulator helper rejects a kinematic transformation'
require inverse_mutant "$p4" \
  'regulator helper rejects a false inverse'
require seal_mutant "$p4" \
  'regulator helper rejects a mismatched factor seal'
require s_direction_mutant "$p4" \
  'left-multiplying S is an adversarial direction mutant'
require inverse_direction_mutant "$p4" \
  'right-multiplying SInverse is an adversarial direction mutant'
require double_direction_mutant "$p4" \
  'mutually inverse double swap still implements the wrong gauge'

for file in "$p1" "$p2" "$p3" "$p4"; do
  reject "no_direct_assembler:${file##*/}" "$file" \
    'DirectRootChannelAssembler'
done

if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if grep -nE '[[:blank:]]+$' "$script_dir"/*.apply_patch "$0" |
    grep -vE '^[^:]+:[0-9]+: $'; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi
if git -C "$repo" diff --check -- "$script_dir"; then
  pass diff_check
else
  fail diff_check
fi
printf 'SOURCE_REBASED_INTEGRATION_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
