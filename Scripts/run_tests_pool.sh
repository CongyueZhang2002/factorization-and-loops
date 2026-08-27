#!/usr/bin/env bash
# Run the test suite through a KernelPool, one FRESH subkernel per test
# (fresh_* missions), N tests at a time; prints a table and exits nonzero
# if any test failed.  Usage: run_tests_pool.sh <pooldir> <N>
# [t_name|Category/t_name ...]. Basenames remain accepted after test
# categorization and must resolve uniquely.
# Limits (measured 2026-08-22, 47 tests in 13 min on 3 subkernels): a test
# that launches its own subkernels (t_canonica_scheduler passes kernelCount
# 2) cannot do so inside a pool subkernel (LaunchKernels::subnopar) and must
# run standalone; t_canonical_pipeline is the same (Kira parallel import
# workers), t_pair_queue_schedule (its own 2-worker dynamic queue; in a
# pool subkernel it LOOPS FOREVER writing ~590 MB/min of QUEUEWARNING,
# 2026-08-27) and t_kernelpool_return_marker (brings up its own pool); t_reconstruction_ghost asserts a FireFly wall-time
# baseline and fails under load; t_wolfram_traps pins a Libra symptom that
# no longer reproduces on 14.2 (pre-existing red).
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pool="$1"; nk="$2"; shift 2
test_files=()
if (( $# == 0 )); then
  mapfile -d '' -t test_files < <(
    find "$root/Tests" -mindepth 2 -type f -name 't_*.wls' -print0 |
      sort -z)
else
  for spec in "$@"; do
    relative="${spec%.wls}"
    relative="${relative#Tests/}"
    candidate="$root/Tests/$relative.wls"
    if [[ -f "$candidate" ]]; then
      test_files+=("$candidate")
      continue
    fi
    mapfile -d '' -t matches < <(
      find "$root/Tests" -mindepth 2 -type f \
        -name "$(basename "$relative").wls" -print0)
    if (( ${#matches[@]} != 1 )); then
      printf 'test name must resolve uniquely: %s (%d matches)\n' \
        "$spec" "${#matches[@]}" >&2
      exit 64
    fi
    test_files+=("${matches[0]}")
  done
fi
export POOL="$pool"; unset FACET_TASK_BROKER FACET_CHECK_LEVEL; export FACET_KERNEL_COUNT=1
mkdir -p "$pool"
if ! { [[ -f "$pool/pool.pid" ]] && kill -0 "$(cat "$pool/pool.pid")" 2>/dev/null; }; then
  rm -f "$pool/control/stop" "$pool/control/stopnow"
  taskset -c "${FACET_CPU_LIST:-0,1,6,7}" nohup wolframscript -file "$root/Scripts/KernelPool.wls" "$pool" "$nk" True > "$pool/pool.log" 2>&1 &
  for i in $(seq 1 90); do grep -q "preload done" "$pool/pool.log" 2>/dev/null && break; sleep 5; done
fi
for test_file in "${test_files[@]}"; do
  t="$(basename "$test_file" .wls)"
  # REUSE=1 (2026-08-27): run on the standing preloaded subkernels
  # instead of one fresh kernel per test.  The fresh-per-test policy
  # launches ~95 kernels per full batch and outruns the licence
  # server's seat release, killing the pool (three batches lost
  # 2026-08-27 01:09-02:15).  Reused kernels skip the ~40 s preload per
  # test as well.  A test that fails under reuse gets one fresh
  # STANDALONE confirmation before its failure counts (Global` state
  # contamination is the known reuse risk, 2026-08-22: 2 of 21).
  prefix="fresh_"; [ "${REUSE:-0}" = "1" ] && prefix="run_"
  "$root/Scripts/kpsubmit.sh" "${prefix}$t" "$test_file" > /dev/null
done
fail=0; printf '%-45s %-8s %s\n' test status wall
for test_file in "${test_files[@]}"; do
  t="$(basename "$test_file" .wls)"
  "$root/Scripts/kpwait.sh" "${prefix}$t" 14400 > "$pool/${prefix}$t.wait" 2>&1
  st=$(grep -o '"Status" -> "[A-Z0-9]*"' "$pool/${prefix}$t.wait" | head -1 | cut -d'"' -f4)
  w=$(grep -o '"Wall" -> [0-9.]*' "$pool/${prefix}$t.wait" | head -1 | grep -o '[0-9.]*$' | cut -c1-7)
  printf '%-45s %-8s %s\n' "$t" "${st:-?}" "${w:-?}"
  [[ "$st" == "OK" ]] || fail=$((fail+1))
done
touch "$pool/control/stop"
echo "failed: $fail"; exit $fail
