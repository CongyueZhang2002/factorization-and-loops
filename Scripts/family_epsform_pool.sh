#!/usr/bin/env bash
# Family eps-form completion on ONE main kernel + N subkernels (N is the
# option), several families at once, each family parallelized through the
# pool's task broker (FeynFacet/Private/Infrastructure/TaskBroker.wl):
#   - the KernelPool is our one main kernel; every family runs as a pool
#     mission on one subkernel (family_epsform_sector.wls);
#   - inside a strip, the finite-field sample batches and the CANONICA
#     degree ladder are submitted as tasks to the same pool and run on the
#     FREE subkernels (helpers); a kernel never launches sub-kernels
#     (LaunchKernels::subnopar) and no second main is used;
#   - at most N-2 families run concurrently (the rest queue), so at least
#     two helpers are always free;
#   - the family mission performs the whole-family validation and writes one
#     V2 FamilyDLogEpsilonForm; the accepted record is then installed in the
#     campaign's validated-record directory without a second validation run.
# Missions are submitted with the fresh_ prefix (2026-08-23, user decision):
# the subkernel that ran a family's solve and validation is closed and
# replaced afterwards, so no campaign state (Global symbols, package
# contexts, basis pollution -- BuildBasis::length on cert_CF385) survives
# into the next family.  Cost: one FACET preload per mission (~seconds)
# against multi-minute solves.
# Usage: family_epsform_pool.sh <output-root> <pooldir> <nkernels> <family> [family ...]
# Env:   FACET_CPU_LIST (default 0,1,6,7,8,9,18,19 = the P-cores),
#        FACET_RATIONAL_MAPLE_BUDGET (default 300), FACET_SECTOR_BUDGET (1800),
#        FACET_FAMILY_DATA_DIRECTORY and FACET_CLASS_FORM_DIRECTORY
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
# Production validates each constructed block and the final family equation
# at independent finite-field points. Development uses characteristic-zero
# identities instead.
export FACET_CHECK_LEVEL="${FACET_CHECK_LEVEL:-Production}"
sector_budget="${FACET_SECTOR_BUDGET:-1800}"
cpus="${FACET_CPU_LIST:-0,1,6,7,8,9,18,19}"
family_data_directory="${FACET_FAMILY_DATA_DIRECTORY:-$R}"
class_form_directory="${FACET_CLASS_FORM_DIRECTORY:-}"
export FACET_MQ_NATIVE_THREADS="${FACET_MQ_NATIVE_THREADS:-8}"
(( nk < 1 )) && { echo "need at least 1 subkernel"; exit 64; }
# families in flight: leave two helpers for the task broker when there are
# enough subkernels; with 1-2 subkernels families run one at a time and the
# broker simply finds no free helper (it then computes locally)
maxfam=$(( nk > 2 ? nk - 2 : 1 ))
# FACET_MAX_FAMILIES overrides (user campaigns that want every family in
# flight at once accept broker helpers computing locally)
[[ -n "${FACET_MAX_FAMILIES:-}" ]] && maxfam="$FACET_MAX_FAMILIES"
native_core_count="${FACET_NATIVE_CORE_COUNT:-$(taskset -c "$cpus" nproc 2>/dev/null || printf '%s' "$nk")}"
if [[ ! "$native_core_count" =~ ^[0-9]+$ ]] || (( native_core_count < 1 )); then
  echo "FACET_NATIVE_CORE_COUNT must be a positive integer" >&2
  exit 64
fi
export FACET_NATIVE_CORE_COUNT="$native_core_count"
mkdir -p "$out" "$pool" "$certified"
mkdir -p "$pool/control"
native_core_file="$pool/control/native_cores"
printf '%s\n' "$native_core_count" > "$native_core_file.$$"
mv -f "$native_core_file.$$" "$native_core_file"
status="$out/campaign_status.tsv"
[[ -f "$status" ]] || printf 'family\tphase\tstarted\tfinished\tseconds\tresult\n' > "$status"

if ! { [[ -f "$pool/pool.pid" ]] && kill -0 "$(cat "$pool/pool.pid")" 2>/dev/null; }; then
  rm -f "$pool/control/stop" "$pool/control/stopnow"
  taskset -c "$cpus" nohup wolframscript -file "$root/Scripts/KernelPool.wls" "$pool" "$nk" True > "$pool/pool.log" 2>&1 &
  for i in $(seq 1 180); do grep -q "preload done" "$pool/pool.log" 2>/dev/null && break; sleep 5; done
  grep -q "preload done" "$pool/pool.log" || { echo "pool did not come up; see $pool/pool.log"; exit 2; }
fi
echo "pool: $(grep -o 'running [0-9]* (license' "$pool/pool.log" | tail -1); families at once: $maxfam; native cores: $native_core_count"

validated_v2_record() {
  local record="$1"
  [[ -f "$record" ]] &&
    grep -q '"DataType" -> "FamilyDLogEpsilonForm"' "$record" &&
    grep -q '"SchemaVersion" -> 2' "$record" &&
    grep -q '"Status" -> "FamilyDLogEpsilonFormValidated"' "$record"
}

run_family() {   # submit and wait for one validated family result
  local family="$1" t0 mission; t0=$(date +%s)
  mission="fresh_sol_${family}_${BASHPID}"
  mkdir -p "$out/$family"
  ln -sfn "$pool/logs/$mission.log" "$out/$family/run.log"
  local worker_arguments=(
    "$family" "$out/$family" "$sector_budget" standard 30 ""
    "$family_data_directory" "$class_form_directory"
  )
  if ! FACET_RESOURCE_GROUP="$family" FACET_RESOURCE_ROLE=family \
      "$root/Scripts/kpsubmit.sh" "$mission" \
        "$root/Scripts/family_epsform_sector.wls" \
        "${worker_arguments[@]}" > /dev/null; then
    printf '%s\tsubmission-failed\t-\t%s\t%d\tkpsubmit failed\n' \
      "$family" "$(date --iso-8601=seconds)" \
      "$(( $(date +%s) - t0 ))" >> "$status"
    return 1
  fi
  printf '%s\tsolving\t%s\t-\t-\tmission %s\n' "$family" \
    "$(date --iso-8601=seconds)" "$mission" >> "$status"
  "$root/Scripts/kpwait.sh" "$mission" 259200 > "$out/${family}_solve.status" 2>&1
  local record="$out/$family/family_epsform_$family.wl"
  if ! grep -q '"Status" -> "OK"' "$out/${family}_solve.status" || [[ ! -f "$record" ]]; then
    printf '%s\tsolve-failed\t-\t%s\t%d\t%s\n' "$family" "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" \
      "$(grep -o '"Status" -> "[A-Z0-9]*"' "$out/${family}_solve.status" | head -1)" >> "$status"; return 1
  fi
  if ! validated_v2_record "$record"; then
    printf '%s\tvalidation-failed\t-\t%s\t%d\tinvalid V2 family result\n' \
      "$family" "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" >> "$status"
    return 1
  fi
  local destination="$certified/family_epsform_$family.wl"
  local partial="$destination.partial-$BASHPID"
  if ! cp "$record" "$partial" || ! mv -f "$partial" "$destination"; then
    printf '%s\tinstallation-failed\t-\t%s\t%d\t%s\n' "$family" \
      "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" \
      "$destination" >> "$status"
    return 1
  fi
  printf '%s\tvalidated\t-\t%s\t%d\t%s\n' "$family" \
    "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" "$destination" >> "$status"
  return 0
}

# waves: at most maxfam families in flight; a slot frees when a family finishes
failures=0
queue=()
# Every requested family re-enters the worker: only validation against the
# current differential system can accept a result, not a stored status alone.
for family in "${families[@]}"; do
  queue+=("$family")
done
running=""   # space-separated PIDs of run_family subshells (no array: an
             # empty-array expansion under set -u left one "" element and
             # the loop never ended -- found 2026-08-22 on the CF34 test)
while true; do
  live=""; n=0
  for p in $running; do
    if kill -0 "$p" 2>/dev/null; then
      live="$live $p"; n=$((n+1))
    elif ! wait "$p"; then
      failures=$((failures + 1))
    fi
  done
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
echo "campaign finished with $failures incomplete families; pool asked to stop"
exit "$failures"
