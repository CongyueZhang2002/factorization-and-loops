#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
smoke="$script_dir/run_cf300_rank2_cross_prime_plan_adversarial_smoke.wls"
prime_driver="$script_dir/run_cf300_sector12_rank2_extension_prime.wls"

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
  if grep -Fq -- "$literal" "$smoke"; then pass "$label"; else fail "$label"; fi
}

reject_literal() {
  local label=$1
  local literal=$2
  if grep -Fq -- "$literal" "$smoke"; then fail "$label"; else pass "$label"; fi
}

if [[ -f "$smoke" ]]; then pass smoke_exists; else fail smoke_exists; fi
if [[ -x "$smoke" ]]; then pass smoke_executable; else fail smoke_executable; fi

require_literal unnormalized_nullity_path '"NormalizationEquations" -> {}'
require_literal valid_plan_gate 'TRCrossPrimeEliminationPlanValidQ['
require_literal accepted_point_domain_gate 'out_of_range_pilot_point_rejected_after_refingerprint'
require_literal canonical_rref_trap 'DenseCanonicalRREFTrapInvoked'
require_literal plan_discovery_trap 'DensePlanDiscoveryTrapInvoked'
require_literal require_mode '"EliminationPlanMode" -> "Require"'
require_literal one_byte_dense_cap '"DenseByteCap" -> 1'
require_literal degree_profile_rejection '"RejectPrimeDegreeProfileChanged"'
require_literal root_order_rejection 'altered_root_order_rejected_after_refingerprint'
require_literal source_hash_rejection 'altered_plan_source_sha256_is_rejected'
require_literal all_row_residual 'noncore_row_corruption_caught_by_full_residual'
require_literal normalization_check 'fixed_core_canonical_zero_identity_normalization'
require_literal atomic_output 'OverwriteTarget -> False'
require_literal dependency_hash_stability 'dependencies_and_driver_unchanged'

if grep -Fq -- 'planSourceHashAfterRead =!= planSourceHashBefore' \
    "$prime_driver" &&
    grep -Fq -- 'planSourceHashAtCompletion =!= planSourceHashBefore' \
      "$prime_driver"; then
  pass physical_driver_binds_source_sha256
else
  fail physical_driver_binds_source_sha256
fi

if grep -nE '[[:alnum:]$]`[[:space:]]*$' "$smoke" >/dev/null; then
  fail no_split_context_symbol
else
  pass no_split_context_symbol
fi

reject_literal no_pool_submit 'kpsubmit'
reject_literal no_parallel_kernels 'LaunchKernels'
reject_literal no_parallel_table 'ParallelTable'
reject_literal no_child_process 'RunProcess'
reject_literal no_start_process 'StartProcess'
reject_literal no_shell_escape 'Run['
reject_literal no_package_write 'FeynFacet/Private/'

if bash -n "$smoke" 2>/dev/null; then
  fail wolfram_not_bash
else
  pass wolfram_not_bash
fi

printf 'CF300_RANK2_CROSS_PRIME_RUNTIME_SMOKE_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
