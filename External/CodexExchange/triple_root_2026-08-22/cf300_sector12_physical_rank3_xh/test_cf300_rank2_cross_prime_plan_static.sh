#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exchange_dir=$(cd -- "$script_dir/.." && pwd)
prototype="$exchange_dir/TripleRootReconstructionPrototype.wl"
prepare="$script_dir/run_cf300_sector12_rank2_extension_prepare.wls"
prime="$script_dir/run_cf300_sector12_rank2_extension_prime.wls"
aggregate="$script_dir/run_cf300_sector12_rank2_extension_aggregate.wls"
syntax_smoke="$script_dir/run_cf300_sector12_sidecar_syntax_load_smoke.wls"

passes=0
failures=0

pass() {
  passes=$((passes + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1" >&2
}

require_literal() {
  local label=$1
  local file=$2
  local literal=$3
  if grep -Fq -- "$literal" "$file"; then pass "$label"; else fail "$label"; fi
}

reject_literal() {
  local label=$1
  local file=$2
  local literal=$3
  if grep -Fq -- "$literal" "$file"; then fail "$label"; else pass "$label"; fi
}

for file in "$prototype" "$prepare" "$prime" "$aggregate" "$syntax_smoke"; do
  if [[ -f "$file" ]]; then pass "exists:${file##*/}"; else fail "exists:${file##*/}"; fi
done

require_literal plan_version "$prototype" '"Status" -> "CrossPrimeEliminationPlanV1"'
require_literal plan_fingerprint_recomputed "$prototype" 'trCrossPrimeEliminationPlanFingerprint[plan]'
require_literal public_plan_validator "$prototype" 'TRCrossPrimeEliminationPlanValidQ[preparation_Association,'
require_literal pilot_point_range_gate "$prototype" '2 <= #1 <= pilotPrime - 2 &'
require_literal fixed_matrix_dimensions "$prototype" 'Dimensions[matrix]]'
require_literal all_row_particular_residual "$prototype" 'matrix . particular - right'
require_literal all_row_nullspace_residual "$prototype" 'matrix . Transpose[nullspace]'
require_literal fixed_normalization_check "$prototype" 'nullspace[[All, normalizationColumns]] === IdentityMatrix[nullity]'
require_literal explicit_require_mode "$prototype" 'planMode === "Require"'
require_literal required_plan_typed_failure "$prototype" '"RequiredCrossPrimeEliminationPlanInvalid"'
require_literal degree_profile_typed_rejection "$prototype" '"RejectPrimeDegreeProfileChanged"'
require_literal same_core_backend_fallback "$prototype" '"WolframFixedCoreFallback"'
reject_literal no_cross_prime_pilot_equality_gate "$prototype" 'Lookup[plan, "PilotPrime", Missing["PilotPrime"]] =!= prime'

lift_body=$(sed -n '/^TRLiftRationalAffineBatch\[/,/^TRUnpackReconstructedVector\[/p' "$prototype")
if grep -Fq '"PivotColumns"' <<<"$lift_body" || grep -Fq '"FreeColumns"' <<<"$lift_body"; then
  fail lift_does_not_use_legacy_pivot_free
else
  pass lift_does_not_use_legacy_pivot_free
fi
if grep -Fq '"PilotPivotColumns"' <<<"$lift_body" &&
    grep -Fq '"EliminationPlanFingerprint"' <<<"$lift_body"; then
  pass lift_uses_common_plan
else
  fail lift_uses_common_plan
fi

require_literal explicit_prime_cli "$prime" '<discover|reuse> <plan-source-or-dash>'
require_literal reuse_requires_source "$prime" 'planMode === "reuse"'
require_literal plan_source_hash_before "$prime" 'planSourceHashBefore'
require_literal plan_source_hash_after_read "$prime" 'planSourceHashAfterRead'
require_literal plan_source_hash_completion "$prime" 'planSourceHashAtCompletion'
require_literal source_must_be_discover "$prime" '"PlanAcquisitionMode", None] =!='
require_literal source_plan_semantic_gate "$prime" 'TRCrossPrimeEliminationPlanValidQ['
require_literal physical_driver_passes_required_mode "$prime" '"Discover", "Require"'

for file in "$prepare" "$prime" "$aggregate"; do
  reject_literal "strict_integer_no_ToExpression:${file##*/}" "$file" 'ToExpression['
  require_literal "manifest_FiniteFieldEpsForm:${file##*/}" "$file" '"FiniteFieldEpsForm"'
  require_literal "manifest_FamilyEpsForm:${file##*/}" "$file" '"FamilyEpsForm"'
done

require_literal channel_strip_shape_gate "$prepare" '"ChannelStripShapeInvalid"'
require_literal preparation_root_order_artifact "$prepare" '"RootOrderingFingerprint" ->'
require_literal sidecar_schema_gate "$aggregate" '"SidecarCertificateSchemaInvalid"'
require_literal exactly_one_discover_gate "$aggregate" 'Length[discoverPositions] =!= 1'
require_literal follower_origin_hash_gate "$aggregate" '"PlanSourceSHA256", $Failed] ==='
require_literal aggregate_plan_validator "$aggregate" 'TRCrossPrimeEliminationPlanValidQ['
require_literal aggregate_root_order_gate "$aggregate" 'artifactOrderings'
require_literal syntax_manifest_FiniteFieldEpsForm "$syntax_smoke" '"FiniteFieldEpsForm"'
require_literal syntax_manifest_FamilyEpsForm "$syntax_smoke" '"FamilyEpsForm"'
require_literal syntax_validator_loaded "$syntax_smoke" '"CrossPrimeEliminationPlanValidatorLoaded"'

printf 'CF300_RANK2_CROSS_PRIME_STATIC passes=%d failures=%d\n' "$passes" "$failures"
((failures == 0))
