#!/usr/bin/env bash
set -u

if (( $# < 2 )); then
  printf 'Usage: RunWithCPUList.sh <cpu-list> <command> [argument ...]\n' >&2
  exit 64
fi

requested_cpu_list="$1"
shift

# FACET calculations use at most sixteen physical processors. Normalize
# ranges such as 2-20 and retain the first sixteen distinct processors so
# every external program, including detached Maple workers, obeys the same
# resource contract as Mathematica's eight-subkernel ceiling.
cpus=()
IFS=',' read -ra cpu_parts <<< "$requested_cpu_list"
for part in "${cpu_parts[@]}"; do
  if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    first="${BASH_REMATCH[1]}"
    last="${BASH_REMATCH[2]}"
    if (( first > last )); then
      printf 'Invalid descending CPU range: %s\n' "$part" >&2
      exit 64
    fi
    for ((cpu = first; cpu <= last; cpu++)); do
      [[ " ${cpus[*]} " == *" $cpu "* ]] || cpus+=("$cpu")
      (( ${#cpus[@]} >= 16 )) && break 2
    done
  elif [[ "$part" =~ ^[0-9]+$ ]]; then
    [[ " ${cpus[*]} " == *" $part "* ]] || cpus+=("$part")
    (( ${#cpus[@]} >= 16 )) && break
  else
    printf 'Invalid CPU list: %s\n' "$requested_cpu_list" >&2
    exit 64
  fi
done
if (( ${#cpus[@]} == 0 )); then
  printf 'CPU list is empty\n' >&2
  exit 64
fi
cpu_list="$(IFS=,; printf '%s' "${cpus[*]}")"

pin_tree() {
  local parent="$1"
  local child
  taskset --all-tasks --pid --cpu-list "$cpu_list" "$parent" \
    >/dev/null 2>&1 || true
  while read -r child; do
    [[ -n "$child" ]] && pin_tree "$child"
  done < <(pgrep -P "$parent" 2>/dev/null || true)
}

terminate_tree() {
  local parent="$1"
  local child
  while read -r child; do
    [[ -n "$child" ]] && terminate_tree "$child"
  done < <(pgrep -P "$parent" 2>/dev/null || true)
  kill -TERM "$parent" 2>/dev/null || true
}

root_pid=""
watcher_pid=""
terminate_session() {
  local session="$1"
  [[ -z "$session" ]] && return
  pkill -TERM -s "$session" 2>/dev/null || true
  sleep 0.1
  pkill -KILL -s "$session" 2>/dev/null || true
}
terminate() {
  trap - TERM INT HUP
  [[ -n "$watcher_pid" ]] && kill "$watcher_pid" 2>/dev/null || true
  [[ -n "$root_pid" ]] && terminate_session "$root_pid"
  exit 143
}
trap terminate TERM INT HUP

# A dedicated session is required here.  Maple's mserver can survive its
# immediate cmaple parent and become reparented to WSL init; a recursive PID
# walk can then no longer find it.  The session identifier remains stable, so
# timeout cleanup can remove every descendant without touching another job.
setsid "$@" &
root_pid=$!
pin_tree "$root_pid"

(
  while kill -0 "$root_pid" 2>/dev/null; do
    pin_tree "$root_pid"
    sleep 0.05
  done
) &
watcher_pid=$!

wait "$root_pid"
status=$?
kill "$watcher_pid" 2>/dev/null || true
wait "$watcher_pid" 2>/dev/null || true
terminate_session "$root_pid"
exit "$status"
