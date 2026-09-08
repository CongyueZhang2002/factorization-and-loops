#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "$script_dir/../../.." && pwd)
patch1="$script_dir/01_backend_and_plan_hardening.patch"
patch2="$script_dir/02_solver_failure_and_resume_binding.patch"
driver1="$script_dir/run_finite_field_backend_plan_adversarial.wls"
driver2="$script_dir/run_solver_configuration_resume_adversarial.wls"
delimiter="$script_dir/../triple_root_2026-08-22/flint_affine_rref_wl_xh/check_wl_delimiters.pl"
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
    printf 'expected=%s actual=%s file=%s\n' "$expected" "$actual" "$file" >&2
    fail "$label"
  fi
}

for file in "$patch1" "$patch2" "$driver1" "$driver2" "$delimiter"; do
  [[ -f "$file" ]] && pass "exists:${file##*/}" || fail "exists:${file##*/}"
done

hash_is pinned_finite_field_source \
  "$repo/FeynFacet/Private/FiniteFieldStripSolve.wl" \
  c6230ae8b6b1d00780ca697cf9e6838a395682a7eabe626b17c8371357bb1671
hash_is pinned_resume_source \
  "$repo/FeynFacet/Private/FamilyRowGaugeResume.wl" \
  e9719e551fcd1930dfbce478a25880d7393a9b6ab3dcf1d2a9672cf0bf4c5dde
hash_is pinned_sector_source \
  "$repo/Scripts/family_epsform_sector.wls" \
  60cc272a0b28da47d670984f401286f4ec29854b6216b7f36580bcde43e4a660

require exhaustive_backend "$patch1" \
  'MemberQ[{Automatic, "Wolfram", "FLINT"}, requested]'
require explicit_no_fallback "$patch1" \
  '"FallbackAllowed" -> False'
require automatic_audited_fallback "$patch1" \
  'backendFallbackReason = backendFailure'
require native_core_certificate "$patch1" \
  'finiteFieldStripCoreSolutionQ['
require backend_used_telemetry "$patch1" '"BackendUsed" -> backendUsed'
require exact_plan_keys "$patch1" \
  'Sort[$finiteFieldStripEliminationPlanRequiredKeys]'
require plan_version "$patch1" \
  '$finiteFieldStripEliminationPlanSchemaVersion = 1'
require plan_fingerprint "$patch1" \
  'finiteFieldStripEliminationPlanFingerprint[plan]'
require plan_preparation_binding "$patch1" \
  '"PlanPreparationFingerprintMismatch"'
require plan_provenance_binding "$patch1" \
  '"PlanSolverProvenanceMismatch"'
require row_range_validation "$patch1" '"PlanEquationRowsInvalid"'
require normalization_range_validation "$patch1" \
  '"PlanNormalizationColumnsInvalid"'
if grep -E '^\+.*Max\[eliminationPlan\["IndependentEquationRows"\]' \
    "$patch1" >/dev/null; then
  fail no_unsafe_plan_max
else
  pass no_unsafe_plan_max
fi

require solver_configuration_schema "$patch2" \
  'FeynFacetStripSolverConfiguration'
require exact_configuration_keys "$patch2" \
  '$familyRowGaugeSolverConfigurationRequiredKeys'
require configuration_fingerprint "$patch2" \
  '"Fingerprint" -> Hash[KeySort[payload]'
require route_binding "$patch2" '"RationalChartFiniteField"'
require backend_binding "$patch2" '"FiniteFieldBackend" -> backend'
require frame_binding "$patch2" '"FrameFingerprint" -> frameFingerprint'
require source_hash_binding "$patch2" '"SourceSHA256" -> hashes'
require narrow_legacy_chart "$patch2" '"LegacyRationalChart"'
require legacy_direct_fails_closed "$patch2" \
  '"ResumeSolverConfigurationMissing"'
require bounded_failure "$patch2" 'ByteCount[value] <= 4096'
require failure_whitelist "$patch2" \
  'keys = {"Method", "RootIndices", "RootSquares"'
require unsolved_solver_failure "$patch2" '"SolverFailure" ->'
require unsolved_solver_configuration "$patch2" \
  '"SolverConfiguration" -> requestedSolverConfiguration'
reject no_gauge_persistence "$patch2" 'keys = {"Gauge"'
reject no_samples_persistence "$patch2" 'keys = {"Samples"'

for driver in "$driver1" "$driver2"; do
  reject "serial_no_launch:${driver##*/}" "$driver" 'LaunchKernels['
  reject "serial_no_parallelmap:${driver##*/}" "$driver" 'ParallelMap['
  reject "no_runprocess:${driver##*/}" "$driver" 'RunProcess['
  reject "no_shell_escape:${driver##*/}" "$driver" 'Run['
done
require adversarial_native_failure "$driver1" \
  'finiteFieldStripFLINTSolve[___] := $Failed'
require adversarial_plan_mutants "$driver1" \
  'DuplicateNormalizationRejectedAfterValidReseal'
require adversarial_resume_gate "$driver2" \
  'HydrationRejectsWrongConfigurationBeforeReplay'
require adversarial_bounded_summary "$driver2" 'FailureSummaryBounded'

if perl "$delimiter" "$driver1" "$driver2"; then
  pass wolfram_delimiter_syntax
else
  fail wolfram_delimiter_syntax
fi
if bash -n "$0"; then pass shell_syntax; else fail shell_syntax; fi
if grep -nE '[[:blank:]]+$' "$driver1" "$driver2" "$0"; then
  fail trailing_whitespace
else
  pass trailing_whitespace
fi
if git -C "$repo" diff --check -- "$script_dir"; then
  pass diff_check
else
  fail diff_check
fi
printf 'FINITE_FIELD_HARDENING_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
