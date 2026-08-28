#!/usr/bin/env bash
# Shell-only regression for run_tests_pool.sh's REUSE contract.  A mock pool
# reports one reused mission red while carrying a Global`t poison marker.  The
# runner must drain the pool, avoid submitting the chart-sensitive suite, and
# launch both tests in distinct standalone OS processes after the pool exits.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scratch="$(mktemp -d /tmp/facet-runner-reuse.XXXXXX)"
pool="$scratch/pool"
state="$scratch/state"
mkdir -p "$pool/control" "$state"

pool_watcher_pid=""
cleanup() {
  if [[ -n "$pool_watcher_pid" ]]; then
    wait "$pool_watcher_pid" 2>/dev/null || true
  fi
  case "$scratch" in
    /tmp/facet-runner-reuse.*) rm -rf -- "$scratch" ;;
  esac
}
trap cleanup EXIT

cat > "$scratch/fake_kpsubmit.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$1" >> "$RUNNER_TEST_STATE/submitted"
SH

cat > "$scratch/fake_kpwait.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '<|"Status" -> "EXIT1", "Wall" -> 0.1|>\n'
SH

cat > "$scratch/fake_wolframscript.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
pool_pid="$(cat "$RUNNER_TEST_STATE/pool_process_pid")"
[[ ! -d "/proc/$pool_pid" ]] || {
  printf 'standalone launched before pool exit (pid %s)\n' "$pool_pid" >&2
  exit 91
}
[[ -f "$RUNNER_TEST_POOL/control/stop" ]] || {
  printf 'standalone launched before graceful stop request\n' >&2
  exit 92
}
printf '%s\n' "$$" >> "$RUNNER_TEST_STATE/standalone_pids"
last_argument="${!#}"
test_name="$(basename "$last_argument" .wls)"
printf '%s\n' "$test_name" >> "$RUNNER_TEST_STATE/standalone_tests"
if [[ "${RUNNER_TEST_FAIL_BASENAME:-}" == "$test_name" ]]; then
  exit 7
fi
SH
chmod +x "$scratch/fake_kpsubmit.sh" "$scratch/fake_kpwait.sh" \
  "$scratch/fake_wolframscript.sh"

# This watcher is the mock pool main.  Its private marker represents the
# Global`t value left by an earlier reused suite.  It exits only through the
# same graceful control file used by KernelPool.wls; the test sends no signal.
(
  printf 'poisoned Global`t\n' > "$state/pool_global_t_poison"
  printf '%s\n' "$BASHPID" > "$pool/pool.pid"
  printf 'preload done\n' > "$pool/pool.log"
  while [[ ! -f "$pool/control/stop" ]]; do sleep 0.05; done
  rm -f "$pool/pool.pid"
) &
pool_watcher_pid=$!

for _ in $(seq 1 100); do
  [[ -f "$pool/pool.pid" ]] && break
  sleep 0.02
done
[[ -f "$pool/pool.pid" ]]
cp "$pool/pool.pid" "$state/pool_process_pid"

set +e
runner_output=$(RUNNER_TEST_STATE="$state" RUNNER_TEST_POOL="$pool" \
  REUSE=1 FACET_KPSUBMIT="$scratch/fake_kpsubmit.sh" \
  FACET_KPWAIT="$scratch/fake_kpwait.sh" \
  FACET_WOLFRAMSCRIPT="$scratch/fake_wolframscript.sh" \
  FACET_STANDALONE_GRACE=0 FACET_POOL_STOP_WAIT=10 \
  bash "$root/Scripts/run_tests_pool.sh" "$pool" 1 \
    Infrastructure/t_kpsubmit_argv_roundtrip \
    Transport/t_chart_transport \
    Transport/t_transport_chart_extension \
    Multiquadratic/t_kallen_q4_chart \
    EpsilonForm/t_family_regulator_factor_in_frame \
    Multiquadratic/t_radical_denesting 2>&1)
runner_rc=$?
set -e

wait "$pool_watcher_pid"
pool_watcher_pid=""

[[ "$runner_rc" -eq 0 ]] || {
  printf '%s\n' "$runner_output" >&2
  printf 'runner exit: %s\n' "$runner_rc" >&2
  exit 1
}
[[ "$(cat "$state/submitted")" == "run_t_kpsubmit_argv_roundtrip" ]]
[[ "$(wc -l < "$state/standalone_tests")" -eq 6 ]]
grep -qx 't_kpsubmit_argv_roundtrip' "$state/standalone_tests"
grep -qx 't_chart_transport' "$state/standalone_tests"
grep -qx 't_transport_chart_extension' "$state/standalone_tests"
grep -qx 't_kallen_q4_chart' "$state/standalone_tests"
grep -qx 't_family_regulator_factor_in_frame' "$state/standalone_tests"
grep -qx 't_radical_denesting' "$state/standalone_tests"
[[ "$(sort -u "$state/standalone_pids" | wc -l)" -eq 6 ]]
grep -q 'SCREEN' <<< "$runner_output"
grep -q 'reuse confirmation' <<< "$runner_output"
grep -q 'standalone-only' <<< "$runner_output"
grep -q 'failed: 0' <<< "$runner_output"

# The complementary half of the verdict contract: when the genuinely fresh
# standalone process itself fails, that failure (and only that failure) is red.
set +e
failure_output=$(RUNNER_TEST_STATE="$state" RUNNER_TEST_POOL="$pool" \
  RUNNER_TEST_FAIL_BASENAME=t_transport_chart_extension \
  FACET_WOLFRAMSCRIPT="$scratch/fake_wolframscript.sh" \
  FACET_STANDALONE_GRACE=0 FACET_POOL_STOP_WAIT=10 \
  bash "$root/Scripts/run_tests_pool.sh" "$pool" 1 \
    Transport/t_transport_chart_extension 2>&1)
failure_rc=$?
set -e
[[ "$failure_rc" -eq 1 ]] || {
  printf '%s\n' "$failure_output" >&2
  printf 'standalone-failure runner exit: %s\n' "$failure_rc" >&2
  exit 1
}
grep -q 'EXIT7' <<< "$failure_output"
grep -q 'failed: 1' <<< "$failure_output"

printf 't_run_tests_pool_reuse_confirmation: PASS\n'
