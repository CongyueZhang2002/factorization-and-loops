#!/usr/bin/env bash
set -u

# Exactly two single-kernel Wolfram processes, confined to two logical CPUs.
# No timeout, signal, pkill, or cancellation command appears in this runner.

if (( $# < 2 )); then
  printf '%s\n' \
    'Usage: RunProjectedTransportCampaign.sh OUTPUT_DIRECTORY FAMILY ...'
  exit 64
fi

bundle="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output_directory="$1"
shift
workers="${CODEX_TRANSPORT_WORKERS:-2}"
cpu_list="${CODEX_TRANSPORT_CPU_LIST:-0,1}"

if (( workers < 1 )); then workers=1; fi
if (( workers > 2 )); then workers=2; fi

mkdir -p "$output_directory/logs"
family_file="$output_directory/families.txt"
printf '%s\n' "$@" > "$family_file"

export FACET_KERNEL_COUNT=1
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

run_case() {
  family="$1"
  output="$output_directory/projected_transport_${family}.wl"
  log="$output_directory/logs/${family}.log"
  taskset -c "$cpu_list" \
    /usr/bin/time -f 'WALL=%e MAXRSS_KB=%M EXIT=%x' \
    wolframscript -file "$bundle/RunProjectedTransportCase.wls" \
      "$family" "$output" false > "$log" 2>&1
  code=$?
  printf '%s\t%d\t%s\n' "$family" "$code" "$output" \
    > "$output_directory/${family}.status"
  return "$code"
}
export -f run_case
export bundle output_directory cpu_list

printf 'Projected transport campaign: workers=%d CPUs=%s families=%d\n' \
  "$workers" "$cpu_list" "$#"

xargs -r -n 1 -P "$workers" bash -c 'run_case "$1"' _ < "$family_file"

incomplete=0
for family in "$@"; do
  status_file="$output_directory/${family}.status"
  if [[ ! -s "$status_file" ]] || [[ "$(cut -f2 "$status_file")" != "0" ]]; then
    incomplete=$((incomplete + 1))
  fi
done

printf 'Projected transport campaign complete: %d incomplete\n' "$incomplete"
exit "$incomplete"

