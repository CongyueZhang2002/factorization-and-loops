#!/usr/bin/env bash
# Family eps-form completion on ONE main kernel + N subkernels (N is the
# option), several families at once, each family parallelized through the
# pool's task broker (FeynFacet/Private/TaskBroker.wl):
#   - the KernelPool is our one main kernel; every family runs as a pool
#     mission on one subkernel (family_epsform_sector.wls);
#   - inside a strip, the finite-field sample batches and the CANONICA
#     degree ladder are submitted as tasks to the same pool and run on the
#     FREE subkernels (helpers); a kernel never launches sub-kernels
#     (LaunchKernels::subnopar) and no second main is used;
#   - at most N-2 families run concurrently (the rest queue), so at least
#     two helpers are always free;
#   - each solved family is certified (CertifyFamilyEpsilonForm) into
#     FamilyEpsFormsCertified/ by a pool mission.
# Missions are submitted with the fresh_ prefix (2026-08-23, user decision):
# the subkernel that ran a family's solve or certificate is closed and
# replaced afterwards, so no campaign state (Global symbols, package
# contexts, basis pollution -- BuildBasis::length on cert_CF385) survives
# into the next family.  Cost: one FACET preload per mission (~seconds)
# against multi-minute solves.
# Usage: family_epsform_pool.sh <output-root> <pooldir> <nkernels> <family> [family ...]
# Env:   FACET_CPU_LIST (default 0,1,6,7,8,9,18,19 = the P-cores),
#        FACET_RATIONAL_MAPLE_BUDGET (default 300), FACET_SECTOR_BUDGET (1800)
# Progress: Scripts/tworoot_status.sh <output-root>
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$1"; pool="$2"; nk="$3"; shift 3; families=("$@")
R="$root/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical"
certified="${FACET_CERTIFIED_DIR:-$R/FamilyEpsFormsCertified}"   # override for tests
export POOL="$pool"
export FACET_TASK_BROKER="$pool"
export FACET_KERNEL_COUNT=1
export FACET_RATIONAL_MAPLE_BUDGET="${FACET_RATIONAL_MAPLE_BUDGET:-300}"
# checks stay separate from the calculation (user decision 2026-08-22): blocks
# are accepted on the modular residual, the exact statement is the family
# certificate run below; set FACET_CHECK_LEVEL=Development to restore the
# exact intermediate checks
export FACET_CHECK_LEVEL="${FACET_CHECK_LEVEL:-Production}"
sector_budget="${FACET_SECTOR_BUDGET:-1800}"
cpus="${FACET_CPU_LIST:-0,1,6,7,8,9,18,19}"
(( nk < 1 )) && { echo "need at least 1 subkernel"; exit 64; }
# families in flight: leave two helpers for the task broker when there are
# enough subkernels; with 1-2 subkernels families run one at a time and the
# broker simply finds no free helper (it then computes locally)
maxfam=$(( nk > 2 ? nk - 2 : 1 ))
# FACET_MAX_FAMILIES overrides (user campaigns that want every family in
# flight at once accept broker helpers computing locally)
[[ -n "${FACET_MAX_FAMILIES:-}" ]] && maxfam="$FACET_MAX_FAMILIES"
mkdir -p "$out" "$pool"
status="$out/campaign_status.tsv"
[[ -f "$status" ]] || printf 'family\tphase\tstarted\tfinished\tseconds\tresult\n' > "$status"

if ! { [[ -f "$pool/pool.pid" ]] && kill -0 "$(cat "$pool/pool.pid")" 2>/dev/null; }; then
  rm -f "$pool/control/stop" "$pool/control/stopnow"
  taskset -c "$cpus" nohup wolframscript -file "$root/Scripts/KernelPool.wls" "$pool" "$nk" True > "$pool/pool.log" 2>&1 &
  for i in $(seq 1 180); do grep -q "preload done" "$pool/pool.log" 2>/dev/null && break; sleep 5; done
  grep -q "preload done" "$pool/pool.log" || { echo "pool did not come up; see $pool/pool.log"; exit 2; }
fi
echo "pool: $(grep -o 'running [0-9]* (license' "$pool/pool.log" | tail -1); families at once: $maxfam"

run_family() {   # submit, wait, certify -- one family, sequential
  local family="$1" t0; t0=$(date +%s)
  mkdir -p "$out/$family"
  ln -sfn "$pool/logs/fresh_sol_$family.log" "$out/$family/run.log"
  "$root/Scripts/kpsubmit.sh" "fresh_sol_$family" "$root/Scripts/family_epsform_sector.wls" \
    "$family" "$out/$family" "$sector_budget" standard 30 > /dev/null
  printf '%s\tsolving\t%s\t-\t-\tmission fresh_sol_%s\n' "$family" "$(date --iso-8601=seconds)" "$family" >> "$status"
  "$root/Scripts/kpwait.sh" "fresh_sol_$family" 259200 > "$out/${family}_solve.status" 2>&1
  local record="$out/$family/family_epsform_$family.wl"
  if ! grep -q '"Status" -> "OK"' "$out/${family}_solve.status" || [[ ! -f "$record" ]]; then
    printf '%s\tsolve-failed\t-\t%s\t%d\t%s\n' "$family" "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" \
      "$(grep -o '"Status" -> "[A-Z0-9]*"' "$out/${family}_solve.status" | head -1)" >> "$status"; return
  fi
  printf '%s\tcertifying\t-\t-\t%d\tmission fresh_cert_%s\n' "$family" "$(( $(date +%s) - t0 ))" "$family" >> "$status"
  "$root/Scripts/kpsubmit.sh" "fresh_cert_$family" "$root/Scripts/certify_family_epsform_record.wls" \
    "$record" "$R/DifferentialEquations/nnlo_de_$family.wl" "$certified/family_epsform_$family.wl" > /dev/null
  "$root/Scripts/kpwait.sh" "fresh_cert_$family" 86400 > "$out/${family}_certify.status" 2>&1
  ln -sfn "$pool/logs/fresh_cert_$family.log" "$out/${family}_certify.log"
  local verdict; verdict="$(grep -o 'CERTIFY.*' "$pool/logs/fresh_cert_$family.log" | tail -1 | cut -c1-120)"
  printf '%s\t%s\t-\t%s\t%d\t%s\n' "$family" \
    "$(grep -q 'exact=True' <<<"$verdict" && echo certified || echo certify-failed)" \
    "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" "$verdict" >> "$status"
}

# waves: at most maxfam families in flight; a slot frees when a family finishes
pids=(); queue=()
for family in "${families[@]}"; do
  if [[ -f "$certified/family_epsform_$family.wl" ]]; then
    printf '%s\tcertified-existing\t-\t-\t0\tskip\n' "$family" >> "$status"; continue
  fi
  queue+=("$family")
done
running=""   # space-separated PIDs of run_family subshells (no array: an
             # empty-array expansion under set -u left one "" element and
             # the loop never ended -- found 2026-08-22 on the CF34 test)
while true; do
  live=""; n=0
  for p in $running; do kill -0 "$p" 2>/dev/null && { live="$live $p"; n=$((n+1)); }; done
  running="$live"
  while (( n < maxfam && ${#queue[@]} > 0 )); do
    family="${queue[0]}"; queue=("${queue[@]:1}")
    run_family "$family" & running="$running $!"; n=$((n+1))
  done
  (( n == 0 && ${#queue[@]} == 0 )) && break
  sleep 10
done
printf 'ALL\tdone\t-\t%s\t-\t-\n' "$(date --iso-8601=seconds)" >> "$status"
touch "$pool/control/stop"
echo "campaign finished; pool asked to stop"
