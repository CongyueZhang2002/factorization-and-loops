#!/usr/bin/env bash
# Two-root completion campaign, THREE FAMILIES IN PARALLEL (user go
# 2026-08-21 23:00 "solve the remaining 2 roots families with our latest
# machinery", 23:10 "run 3 in parallel").  One main kernel of ours (the
# KernelPool) holding one subkernel per family; measured 2026-08-21 23:09:
# subkernels cannot launch helper kernels on this licence (0 of 2), so
# each family runs on exactly one kernel (FACET_KERNEL_COUNT=1; FLINT
# threads and Maple are external processes).  Per family: the standardized
# sector route (family_epsform_sector.wls), then the exact family
# certificate into FamilyEpsFormsCertified/.
# Usage: tworoot_parallel.sh <output-root> <pooldir> <family> [family ...]
# Progress: Scripts/tworoot_status.sh <output-root>
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$1"; pool="$2"; shift 2; families=("$@")
R="$root/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical"
export POOL="$pool"
export FACET_KERNEL_COUNT=1
export FACET_RATIONAL_MAPLE_BUDGET="${FACET_RATIONAL_MAPLE_BUDGET:-300}"
cpus="${FACET_CPU_LIST:-0,1,6,7,8,9}"
mkdir -p "$out" "$pool"
status="$out/campaign_status.tsv"
[[ -f "$status" ]] || printf 'family\tphase\tstarted\tfinished\tseconds\tresult\n' > "$status"

# 1. the pool: one main + one subkernel per family, FeynFacet preloaded
if ! { [[ -f "$pool/pool.pid" ]] && kill -0 "$(cat "$pool/pool.pid")" 2>/dev/null; }; then
  rm -f "$pool/control/stop" "$pool/control/stopnow"
  taskset -c "$cpus" nohup wolframscript -file "$root/Scripts/KernelPool.wls" "$pool" "${#families[@]}" True > "$pool/pool.log" 2>&1 &
  for i in $(seq 1 120); do grep -q "preload done" "$pool/pool.log" 2>/dev/null && break; sleep 5; done
  grep -q "preload done" "$pool/pool.log" || { echo "pool did not come up; see $pool/pool.log"; exit 2; }
fi
echo "pool: $(grep -o 'running [0-9]* (license' "$pool/pool.log" | tail -1)"

# 2. one solve mission per family
for family in "${families[@]}"; do
  if [[ -f "$R/FamilyEpsFormsCertified/family_epsform_$family.wl" ]]; then
    printf '%s\tcertified-existing\t-\t-\t0\tskip\n' "$family" >> "$status"; continue
  fi
  mkdir -p "$out/$family"
  ln -sfn "$pool/logs/sol_$family.log" "$out/$family/run.log"
  "$root/Scripts/kpsubmit.sh" "sol_$family" "$root/Scripts/family_epsform_sector.wls" \
    "$family" "$out/$family" 1800 standard 30 > /dev/null
  printf '%s\tsolving\t%s\t-\t-\tmission sol_%s\n' "$family" "$(date --iso-8601=seconds)" "$family" >> "$status"
done

# 3. per family: wait, then certify on the freed kernel
waiter() {
  local family="$1" t0; t0=$(date +%s)
  "$root/Scripts/kpwait.sh" "sol_$family" 172800 > "$out/${family}_solve.status" 2>&1
  local record="$out/$family/family_epsform_$family.wl"
  if ! grep -q '"Status" -> "OK"' "$out/${family}_solve.status" || [[ ! -f "$record" ]]; then
    printf '%s\tsolve-failed\t-\t%s\t%d\t%s\n' "$family" "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" \
      "$(grep -o '"Status" -> "[A-Z0-9]*"' "$out/${family}_solve.status" | head -1)" >> "$status"; return
  fi
  printf '%s\tcertifying\t-\t-\t%d\tmission cert_%s\n' "$family" "$(( $(date +%s) - t0 ))" "$family" >> "$status"
  "$root/Scripts/kpsubmit.sh" "cert_$family" "$root/Scripts/certify_family_epsform_record.wls" \
    "$record" "$R/DifferentialEquations/nnlo_de_$family.wl" "$R/FamilyEpsFormsCertified/family_epsform_$family.wl" > /dev/null
  "$root/Scripts/kpwait.sh" "cert_$family" 86400 > "$out/${family}_certify.status" 2>&1
  ln -sfn "$pool/logs/cert_$family.log" "$out/${family}_certify.log"
  local verdict; verdict="$(grep -o 'CERTIFY.*' "$pool/logs/cert_$family.log" | tail -1 | cut -c1-120)"
  printf '%s\t%s\t-\t%s\t%d\t%s\n' "$family" \
    "$(grep -q 'exact=True' <<<"$verdict" && echo certified || echo certify-failed)" \
    "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" "$verdict" >> "$status"
}
pids=()
for family in "${families[@]}"; do
  [[ -f "$R/FamilyEpsFormsCertified/family_epsform_$family.wl" ]] && continue
  waiter "$family" & pids+=($!)
done
wait "${pids[@]}"
printf 'ALL\tdone\t-\t%s\t-\t-\n' "$(date --iso-8601=seconds)" >> "$status"
touch "$pool/control/stop"
