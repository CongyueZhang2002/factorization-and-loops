#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
lease="$root/Scripts/native_core_lease.sh"
test_root="$(mktemp -d /tmp/feynfacet-native-lease.XXXXXX)"
pool="$test_root/pool"
mkdir -p "$pool/control"
pids=()

cleanup() {
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
  case "$test_root" in
    /tmp/feynfacet-native-lease.*) rm -rf -- "$test_root" ;;
  esac
}
trap cleanup EXIT

wait_for_file() {
  local file="$1"
  for _ in $(seq 1 100); do
    [[ -f "$file" ]] && return 0
    sleep 0.02
  done
  return 1
}

# A call holding the former eight-core capacity must drain before a call
# admitted after a live shrink to four cores can begin.
printf '8\n' > "$pool/control/native_cores"
first="$test_root/first"
second="$test_root/second"
"$lease" "$pool" 8 -- bash -c \
  'printf "%s\n" "$1" > "$0"; sleep 1' "$first" 8 &
pids+=("$!")
wait_for_file "$first"
printf '4\n' > "$pool/control/native_cores.next"
mv -f "$pool/control/native_cores.next" "$pool/control/native_cores"
"$lease" "$pool" 8 -- bash -c \
  'printf "%s\n" "$1" > "$0"' "$second" 8 &
pids+=("$!")
sleep 0.2
[[ ! -f "$second" ]]
printf 'PASS  a shrink waits for the old oversized lease to drain\n'
wait "${pids[0]}"
wait "${pids[1]}"
[[ "$(<"$second")" == 4 ]]
printf 'PASS  the adapter receives the smaller live grant\n'
pids=()

# A live expansion from eight to twelve allows a four-thread call to run
# beside the existing eight-thread call rather than waiting for it.
printf '8\n' > "$pool/control/native_cores"
third="$test_root/third"
fourth="$test_root/fourth"
"$lease" "$pool" 8 -- bash -c \
  'printf "%s\n" "$1" > "$0"; sleep 1' "$third" 8 &
pids+=("$!")
wait_for_file "$third"
printf '12\n' > "$pool/control/native_cores.next"
mv -f "$pool/control/native_cores.next" "$pool/control/native_cores"
"$lease" "$pool" 4 -- bash -c \
  'printf "%s\n" "$1" > "$0"' "$fourth" 4 &
pids+=("$!")
wait_for_file "$fourth"
kill -0 "${pids[0]}"
printf 'PASS  an expansion admits disjoint native work immediately\n'
[[ "$(<"$third")" == 8 && "$(<"$fourth")" == 4 ]]
printf 'PASS  concurrent calls keep their granted thread counts\n'
wait "${pids[0]}"
wait "${pids[1]}"
pids=()

printf '4 shell assertions, 0 failed\n'
