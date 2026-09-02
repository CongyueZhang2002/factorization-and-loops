#!/usr/bin/env bash
# Run the test suite through a KernelPool, N tests at a time; prints a table
# and exits nonzero if any test failed.  With REUSE=1 the pool is a screening
# pass: after it drains, every non-OK result is confirmed by a genuinely fresh
# standalone wolframscript process, and only that confirmation can count red.
# Usage: run_tests_pool.sh <pooldir> <N>
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
wolframscript_cmd="${FACET_WOLFRAMSCRIPT:-wolframscript}"
kpsubmit_cmd="${FACET_KPSUBMIT:-$root/Scripts/kpsubmit.sh}"
kpwait_cmd="${FACET_KPWAIT:-$root/Scripts/kpwait.sh}"
cpu_list="${FACET_CPU_LIST:-0,1,6,7}"
standalone_grace="${FACET_STANDALONE_GRACE:-4}"
pool_stop_wait="${FACET_POOL_STOP_WAIT:-180}"

process_alive() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ && -d "/proc/$pid" ]]
}

current_pool_pid() {
  local pid
  [[ -f "$pool/pool.pid" ]] || return 1
  IFS= read -r pid < "$pool/pool.pid"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$pid"
}

# These suites deliberately exercise short Global` chart-variable names and
# project chart registration.  They are valid standalone tests, but arbitrary
# preceding Global`/package state changes their inputs before the assertions
# begin.  Keep them off reused subkernels until an isolation regression proves
# that the whole kernel state, not merely newly parsed symbols, is restored.
# Tests that launch their own subkernels, Kira workers or a nested
# KernelPool cannot run on a pool subkernel (LaunchKernels::subnopar) and,
# when they start a nested pool, exhaust the licence seats of the running
# pool (measured 2026-09-02 03:18: relaunch refusals, requeues, DUPLICATE
# verdicts).  They run standalone after the pool stops.
# The three multiquadratic tests listed last ran more than 105 minutes
# on REUSED subkernels without a line of output (2026-09-02 baseline batch,
# suspected loss of a trusted fast path through leftover kernel state)
# while their own comments measure the intended route in seconds; fresh
# standalone runs measure them honestly.
standalone_only() {
  case "$1" in
    t_transport_chart_extension|t_kallen_q4_chart|\
    t_family_regulator_factor_in_frame|t_radical_denesting|\
    t_canonical_pipeline|t_pair_queue_schedule|\
    t_kernelpool_return_marker|t_kernelpool_resource_policy|\
    t_multiquadratic_gauge_ladder|t_multiquadratic_gauge_screen|\
    t_multiquadratic_letters) return 0 ;;
    *) return 1 ;;
  esac
}

preserve_log() {
  local log_file="$1" stamp destination counter=0
  [[ -e "$log_file" ]] || return 0
  stamp="$(date +%Y%m%d-%H%M%S)"
  destination="$log_file.$stamp"
  while [[ -e "$destination" ]]; do
    counter=$((counter + 1))
    destination="$log_file.$stamp-$counter"
  done
  mv -- "$log_file" "$destination"
}

graceful_pool_stop() {
  local pid waited=0
  mkdir -p "$pool/control"
  touch "$pool/control/stop"
  while pid="$(current_pool_pid 2>/dev/null)" && process_alive "$pid"; do
    if (( waited >= pool_stop_wait )); then
      printf 'pool did not exit after graceful stop in %s s: %s (pid %s)\n' \
        "$pool_stop_wait" "$pool" "$pid" >&2
      return 1
    fi
    sleep 1
    waited=$((waited + 1))
  done
}

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

# A driver copy run from outside the tree derives the wrong root and would
# report a vacuous "failed: 0" (watchdog finding 2026-09-02); an empty test
# set is an error, never a clean run.
if (( ${#test_files[@]} == 0 )); then
  echo "run_tests_pool.sh: no tests found under $root/Tests (root is derived from this script's location)" >&2
  exit 65
fi

pool_test_files=()
standalone_test_files=()
for test_file in "${test_files[@]}"; do
  t="$(basename "$test_file" .wls)"
  if standalone_only "$t"; then
    standalone_test_files+=("$test_file")
  else
    pool_test_files+=("$test_file")
  fi
done

pool_active=0
if pid="$(current_pool_pid 2>/dev/null)" && process_alive "$pid"; then
  pool_active=1
fi
if (( ${#pool_test_files[@]} > 0 && pool_active == 0 )); then
  mkdir -p "$pool/control"
  rm -f "$pool/control/stop" "$pool/control/stopnow"
  taskset -c "$cpu_list" nohup "$wolframscript_cmd" -file \
    "$root/Scripts/KernelPool.wls" "$pool" "$nk" True \
    > "$pool/pool.log" 2>&1 &
  pool_active=1
  pool_ready=0
  for _ in $(seq 1 90); do
    if grep -q "preload done" "$pool/pool.log" 2>/dev/null; then
      pool_ready=1
      break
    fi
    sleep 5
  done
  if (( pool_ready == 0 )); then
    printf 'pool did not report preload completion: %s\n' "$pool" >&2
    exit 2
  fi
fi

reuse_mode=0
prefix="fresh_"
if [[ "${REUSE:-0}" == "1" ]]; then
  reuse_mode=1
  prefix="run_"
fi

for test_file in "${pool_test_files[@]}"; do
  t="$(basename "$test_file" .wls)"
  "$kpsubmit_cmd" "${prefix}$t" "$test_file" > /dev/null
done

fail=0
reuse_confirmation_files=()
printf '%-45s %-8s %s\n' test status wall
for test_file in "${pool_test_files[@]}"; do
  t="$(basename "$test_file" .wls)"
  "$kpwait_cmd" "${prefix}$t" 14400 > "$pool/${prefix}$t.wait" 2>&1
  st=$(grep -o '"Status" -> "[A-Z0-9]*"' "$pool/${prefix}$t.wait" | head -1 | cut -d'"' -f4)
  w=$(grep -o '"Wall" -> [0-9.]*' "$pool/${prefix}$t.wait" | head -1 | grep -o '[0-9.]*$' | cut -c1-7)
  if (( reuse_mode == 1 )) && [[ "$st" != "OK" ]]; then
    reuse_confirmation_files+=("$test_file")
    printf '%-45s %-8s %s (pooled %s; standalone confirmation queued)\n' \
      "$t" SCREEN "${w:-?}" "${st:-?}"
  else
    printf '%-45s %-8s %s\n' "$t" "${st:-?}" "${w:-?}"
    [[ "$st" == "OK" ]] || fail=$((fail + 1))
  fi
done

# kpwait above has observed every pooled completion.  Release the pool's
# main-kernel licence seat and wait for the graceful file-control shutdown;
# a standalone confirmation is never launched alongside this pool master.
if (( pool_active == 1 )); then
  graceful_pool_stop || exit 70
fi

standalone_queue=("${standalone_test_files[@]}" "${reuse_confirmation_files[@]}")
for (( index=0; index<${#standalone_queue[@]}; index++ )); do
  test_file="${standalone_queue[index]}"
  t="$(basename "$test_file" .wls)"
  standalone_log="$pool/standalone_$t.log"
  preserve_log "$standalone_log"
  start_seconds=$SECONDS
  (
    cd "$root" || exit 72
    taskset -c "$cpu_list" "$wolframscript_cmd" -file "$test_file"
  ) > "$standalone_log" 2>&1
  standalone_rc=$?
  standalone_wall=$((SECONDS - start_seconds))
  if (( standalone_rc == 0 )); then
    standalone_status=OK
  else
    standalone_status="EXIT$standalone_rc"
    fail=$((fail + 1))
  fi
  if standalone_only "$t"; then
    standalone_reason="standalone-only"
  else
    standalone_reason="reuse confirmation"
  fi
  printf '%-45s %-8s %s (%s; log %s)\n' \
    "$t" "$standalone_status" "$standalone_wall" "$standalone_reason" \
    "$standalone_log"
  if (( index + 1 < ${#standalone_queue[@]} )) && \
      [[ "$standalone_grace" != "0" ]]; then
    sleep "$standalone_grace"
  fi
done

echo "failed: $fail"; exit "$fail"
