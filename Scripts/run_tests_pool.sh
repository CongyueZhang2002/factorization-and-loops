#!/usr/bin/env bash
# Run the test suite through a KernelPool, one FRESH subkernel per test
# (fresh_* missions), N tests at a time; prints a table and exits nonzero
# if any test failed.  Usage: run_tests_pool.sh <pooldir> <N> [t_name ...]
# Limits (measured 2026-08-22, 47 tests in 13 min on 3 subkernels): a test
# that launches its own subkernels (t_canonica_scheduler passes kernelCount
# 2) cannot do so inside a pool subkernel (LaunchKernels::subnopar) and must
# run standalone; t_reconstruction_ghost asserts a FireFly wall-time
# baseline and fails under load; t_wolfram_traps pins a Libra symptom that
# no longer reproduces on 14.2 (pre-existing red).
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pool="$1"; nk="$2"; shift 2
tests=("$@"); (( ${#tests[@]} == 0 )) && mapfile -t tests < <(cd "$root/Tests" && ls t_*.wls | sed 's/\.wls$//')
export POOL="$pool"; unset FACET_TASK_BROKER FACET_CHECK_LEVEL; export FACET_KERNEL_COUNT=1
mkdir -p "$pool"
if ! { [[ -f "$pool/pool.pid" ]] && kill -0 "$(cat "$pool/pool.pid")" 2>/dev/null; }; then
  rm -f "$pool/control/stop" "$pool/control/stopnow"
  taskset -c "${FACET_CPU_LIST:-0,1,6,7}" nohup wolframscript -file "$root/Scripts/KernelPool.wls" "$pool" "$nk" True > "$pool/pool.log" 2>&1 &
  for i in $(seq 1 90); do grep -q "preload done" "$pool/pool.log" 2>/dev/null && break; sleep 5; done
fi
for t in "${tests[@]}"; do "$root/Scripts/kpsubmit.sh" "fresh_$t" "$root/Tests/$t.wls" > /dev/null; done
fail=0; printf '%-45s %-8s %s\n' test status wall
for t in "${tests[@]}"; do
  "$root/Scripts/kpwait.sh" "fresh_$t" 14400 > "$pool/fresh_$t.wait" 2>&1
  st=$(grep -o '"Status" -> "[A-Z0-9]*"' "$pool/fresh_$t.wait" | head -1 | cut -d'"' -f4)
  w=$(grep -o '"Wall" -> [0-9.]*' "$pool/fresh_$t.wait" | head -1 | grep -o '[0-9.]*$' | cut -c1-7)
  printf '%-45s %-8s %s\n' "$t" "${st:-?}" "${w:-?}"
  [[ "$st" == "OK" ]] || fail=$((fail+1))
done
touch "$pool/control/stop"
echo "failed: $fail"; exit $fail
