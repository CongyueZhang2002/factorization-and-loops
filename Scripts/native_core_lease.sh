#!/usr/bin/env bash
# Run one native adapter under a process-shared CPU-thread lease.
# Usage: native_core_lease.sh <pool> <requested> -- <command> ... <threads>
# The final command argument is replaced by the granted thread count.
set -euo pipefail

pool="${1:-}"
requested="${2:-}"
shift 2 || true
[[ "${1:-}" == "--" ]] || { echo "native_core_lease: missing --" >&2; exit 64; }
shift
[[ "$requested" =~ ^[0-9]+$ ]] && (( requested >= 1 )) || {
  echo "native_core_lease: requested threads must be positive" >&2
  exit 64
}
(( $# >= 1 )) || { echo "native_core_lease: missing command" >&2; exit 64; }

control="$pool/control/native_cores"
state="$pool/native_leases"
if [[ ! -d "$pool" ]] || ! command -v flock >/dev/null; then
  exec "$@"
fi
if [[ ! -r "$control" ]]; then
  echo "native_core_lease: live pool has no native-core control" >&2
  exit 75
fi
mkdir -p "$state"

nonce="$(date +%s%N)_$$_$RANDOM"
request_file="$state/request.$nonce"
lease_file="$state/lease.$nonce"
printf '%s %s\n' "$$" "$requested" > "$request_file.next"
mv -f "$request_file.next" "$request_file"

child_pid=""
cleanup() {
  rm -f -- "$request_file" "$lease_file"
}
terminate() {
  if [[ "$child_pid" =~ ^[0-9]+$ ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  exit 143
}
trap cleanup EXIT
trap terminate INT TERM

grant=0
while (( grant == 0 )); do
  exec {lock_fd}>"$state/lock"
  flock -x "$lock_fd"

  for record in "$state"/request.* "$state"/lease.*; do
    [[ -f "$record" ]] || continue
    read -r owner _ < "$record" || owner=0
    [[ "$owner" =~ ^[0-9]+$ ]] && kill -0 "$owner" 2>/dev/null ||
      rm -f -- "$record"
  done

  capacity="$(tr -d '[:space:]' < "$control" 2>/dev/null || true)"
  if [[ ! "$capacity" =~ ^[0-9]+$ ]] || (( capacity < 1 )); then
    capacity=1
  fi
  candidate=$(( requested < capacity ? requested : capacity ))
  used=0
  for record in "$state"/lease.*; do
    [[ -f "$record" ]] || continue
    read -r _ amount < "$record" || amount=0
    [[ "$amount" =~ ^[0-9]+$ ]] && used=$((used + amount))
  done
  first_request=""
  for record in "$state"/request.*; do
    [[ -f "$record" ]] || continue
    request_name="${record##*/}"
    if [[ -z "$first_request" || "$request_name" < "$first_request" ]]; then
      first_request="$request_name"
    fi
  done
  if [[ "$first_request" == "${request_file##*/}" ]] &&
      (( used + candidate <= capacity )); then
    printf '%s %s\n' "$$" "$candidate" > "$lease_file.next"
    mv -f "$lease_file.next" "$lease_file"
    rm -f -- "$request_file"
    grant="$candidate"
  fi
  flock -u "$lock_fd"
  eval "exec ${lock_fd}>&-"
  (( grant > 0 )) || sleep 0.05
done

command=("$@")
last_index=$((${#command[@]} - 1))
command[$last_index]="$grant"
"${command[@]}" &
child_pid=$!
set +e
wait "$child_pid"
status=$?
set -e
child_pid=""
exit "$status"
