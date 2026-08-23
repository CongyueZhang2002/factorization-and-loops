#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
aggregate="$script_dir/run_cf300_sector12_rank2_extension_aggregate.wls"

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
  local literal=$2
  if grep -Fq -- "$literal" "$aggregate"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_literal coordinate_schema_gate '"ReconstructedCoordinateSchemaInvalid"'
require_literal coordinate_count_gate 'preparation["UnknownCount"]'
require_literal coordinate_value_gate 'scaledResult["ReconstructedVector"]'
require_literal coordinate_degree_gate 'scaledResult["DegreeProfile"]'
require_literal crt_modulus_recorded '"CRTModulus" -> crtModulus'
require_literal rr_bound_formula 'Floor[Sqrt[crtModulus/2]]'
require_literal numerator_height '"MaxAbsRecoveredNumerator"'
require_literal denominator_height '"MaxRecoveredDenominator"'
require_literal reconstruction_budget_gate '"RationalReconstructionBudgetViolation"'
require_literal raw_derivative 'D[gauge, variables[[mu]]]'
require_literal raw_left_product 'Dot[strip[[1, mu]], gauge]'
require_literal raw_right_product 'Dot[gauge, strip[[2, mu]]]'
require_literal raw_entrywise_together 'Map[Together,'
require_literal raw_failure_gate '"IndependentRawOriginalPDEResidualFailed"'
require_literal raw_success_status '"DirectRawOriginalPDEResidualZero"'
require_literal raw_timing '"RawOriginalExactSeconds"'
require_literal raw_output_evidence '"RawOriginalExactVerification" -> rawOriginalExact'

raw_body=$(sed -n '/^directRawExactResidual\[/,/^];$/p' "$aggregate")
if grep -Eq 'TRFieldDecompose|TRDerivative|TRMultiply|TRExactChannelResidual' \
    <<<"$raw_body"; then
  fail raw_check_is_independent_of_channel_algebra
else
  pass raw_check_is_independent_of_channel_algebra
fi

printf 'CF300_RANK2_AGGREGATE_RAW_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
