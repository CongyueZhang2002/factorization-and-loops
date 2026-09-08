#!/usr/bin/env bash
set -euo pipefail

directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
census="$directory/run_cf300_sector12_rank3_census.wls"
reconstruction="$directory/run_cf300_physical_rank3_reconstruction.wls"
passed=0
failed=0

assert_true() {
  local name="$1"
  shift
  if "$@"; then
    printf 'CF300R3DRIVERSTATIC PASS %s\n' "$name"
    passed=$((passed + 1))
  else
    printf 'CF300R3DRIVERSTATIC FAIL %s\n' "$name"
    failed=$((failed + 1))
  fi
}

source_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file"
}

source_excludes() {
  local file="$1"
  local text="$2"
  ! grep -Fq -- "$text" "$file"
}

regular_pattern='^CF300_12_([0-9]+)_input\.wl$'
physical_pattern='^CF300_12_([0-9]+)_physical_rank3_input\.wl$'

assert_true regular_name_accepted bash -c \
  '[[ "CF300_12_17_input.wl" =~ $1 ]]' _ "$regular_pattern"
assert_true physical_name_rejected_by_regular bash -c \
  '! [[ "CF300_12_17_physical_rank3_input.wl" =~ $1 ]]' _ \
  "$regular_pattern"
assert_true malformed_lower_rejected bash -c \
  '! [[ "CF300_12_x_input.wl" =~ $1 ]]' _ "$regular_pattern"
assert_true physical_name_accepted bash -c \
  '[[ "CF300_12_17_physical_rank3_input.wl" =~ $1 ]]' _ \
  "$physical_pattern"

assert_true census_strict_regular_parser source_contains "$census" \
  '^CF300_12_([0-9]+)_input\\.wl$'
assert_true census_clean_sidecar_gate source_contains "$census" \
  'CleanCheckedSidecarEvidenceMissing'
assert_true census_association_equality_gate source_contains "$census" \
  'PhysicalRegularAssociationSameQ'
assert_true census_metadata_gate source_contains "$census" \
  'InputMetadataMismatch'
assert_true census_stale_output_gate source_contains "$census" \
  'stale output target'
assert_true reconstruction_stale_output_gate source_contains \
  "$reconstruction" 'stale output target'
assert_true reconstruction_input_hash_gate source_contains \
  "$reconstruction" 'PhysicalInputHashMismatch'
assert_true reconstruction_census_abi_gate source_contains \
  "$reconstruction" 'CensusPreparationABIMismatch'
assert_true reconstruction_dense_budget_gate source_contains \
  "$reconstruction" 'DenseSolveBudgetExceeded'
assert_true reconstruction_benchmark_default_false source_contains \
  "$reconstruction" 'Switch[arguments[[6]], "True", True, "False", False, _, $Failed], False]'
assert_true census_never_overwrites source_excludes "$census" \
  'OverwriteTarget -> True'
assert_true reconstruction_never_overwrites source_excludes \
  "$reconstruction" 'OverwriteTarget -> True'

printf 'CF300R3DRIVERSTATIC RESULT passed=%d failed=%d\n' "$passed" "$failed"
((failed == 0))
