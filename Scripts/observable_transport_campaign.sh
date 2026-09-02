#!/usr/bin/env bash
# STANDALONE observable-transport campaign driver: one family per
# wolframscript process (each its own main kernel, no KernelPool, no
# task broker), FACET_TRANSPORT_JOBS families at a time.
#
# NOT the canonical driver.  The canonical multi-family driver is
# observable_transport_kernelpool_campaign.sh (one pool main + N
# subkernels, round 4 decision 2026-09-02).  Use THIS script only when
# no KernelPool can run (another main kernel already holds the second
# licence seat, or a machine without the pool tooling) or for one family
# at a time; with FACET_TRANSPORT_JOBS > 1 it starts several main kernels
# and on the shared licence that collides with any running pool.
set -u

if (( $# != 2 )); then
  printf '%s\n' \
    'Usage: observable_transport_campaign.sh <manifest.tsv> <output-root>' \
    'Columns: family, epsilon-form file, differential-system file,' \
    'valuation file, optional transport-card file.'
  exit 64
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cpu_runner="$repository_root/FeynFacet/Tools/RunWithCPUList.sh"
manifest="$1"
output_root="$2"
cpu_list="${FACET_CPU_LIST:-0-15}"
kernel_count="${FACET_KERNEL_COUNT:-8}"
if (( kernel_count < 1 )); then kernel_count=1; fi
if (( kernel_count > 8 )); then kernel_count=8; fi
transport_jobs="${FACET_TRANSPORT_JOBS:-$kernel_count}"
if (( transport_jobs < 1 )); then transport_jobs=1; fi
if (( transport_jobs > kernel_count )); then transport_jobs="$kernel_count"; fi
export FACET_CPU_LIST="$cpu_list"

if [[ ! -f "$manifest" ]]; then
  printf 'Observable-transport manifest does not exist: %s\n' "$manifest"
  exit 66
fi

# Wolfram's TSV exporter quotes string fields. Decode only the outer TSV
# quotes here; never pass them through as part of a family name or path.
decode_tsv_field() {
  local value="${1:-}"
  if (( ${#value} >= 2 )) &&
      [[ "${value:0:1}" == '"' && "${value: -1}" == '"' ]]; then
    value="${value:1:${#value}-2}"
    value="${value//\"\"/\"}"
  fi
  printf '%s' "$value"
}

mkdir -p "$output_root"
campaign_log="$output_root/campaign.log"
campaign_table="$output_root/campaign.tsv"
status_directory="$output_root/.campaign-status"
mkdir -p "$status_directory"
rm -f "$status_directory"/*.tsv
printf 'family\tresult\texit_code\toutput\n' > "$campaign_table"
printf '[transport] CPU affinity %s\n' "$cpu_list" | tee -a "$campaign_log"
printf '[transport] dynamic family slots %d (one serial kernel per family)\n' \
  "$transport_jobs" | tee -a "$campaign_log"

run_family() {
  local family="$1" epsilon_form="$2" differential_system="$3"
  local valuations="$4" card="$5" output arguments code
  output="$output_root/observable_transport_${family}.wl"
  arguments=("$epsilon_form" "$differential_system" "$valuations" "$output")
  if [[ -n "${card:-}" ]]; then arguments+=("$card"); fi

  # BuildObservableTransport is serial.  Keep the subkernel allowance at one
  # inside each worker: campaign parallelism belongs between independent
  # families, and nested pools here only spend license seats and memory.
  if "$cpu_runner" "$cpu_list" env FACET_KERNEL_COUNT=1 \
      wolframscript -file \
        "$repository_root/Scripts/family_observable_transport.wls" \
        "${arguments[@]}" > "$output_root/${family}.log" 2>&1; then
    code=0
  else
    code=$?
  fi

  if (( code == 0 )); then
    printf '%s\texact\t0\t%s\n' "$family" "$output" > \
      "$status_directory/${family}.tsv"
  else
    printf '%s\tincomplete\t%d\t%s\n' \
      "$family" "$code" "$output" > "$status_directory/${family}.tsv"
  fi
  return "$code"
}

# Store complete manifest rows before dispatch.  A parent-side scheduler owns
# all shared status/log writes; workers only write their family log and one
# atomic-sized status row.  Slots are refilled as soon as any family exits.
rows=()
while IFS=$'\t' read -r raw_family raw_epsilon_form \
    raw_differential_system raw_valuations raw_card; do
  family="$(decode_tsv_field "$raw_family")"
  [[ -z "$family" || "$family" == \#* || "$family" == "family" ]] && continue
  epsilon_form="$(decode_tsv_field "$raw_epsilon_form")"
  differential_system="$(decode_tsv_field "$raw_differential_system")"
  valuations="$(decode_tsv_field "$raw_valuations")"
  card="$(decode_tsv_field "${raw_card:-}")"
  rows+=("$family"$'\t'"$epsilon_form"$'\t'"$differential_system"$'\t'"$valuations"$'\t'"$card")
done < "$manifest"

declare -A running_family=()
next=0
active=0
while (( next < ${#rows[@]} || active > 0 )); do
  while (( active < transport_jobs && next < ${#rows[@]} )); do
    IFS=$'\t' read -r family epsilon_form differential_system valuations card \
      <<< "${rows[$next]}"
    printf '[transport] %s started %s\n' \
      "$family" "$(date --iso-8601=seconds)" | tee -a "$campaign_log"
    run_family "$family" "$epsilon_form" "$differential_system" \
      "$valuations" "${card:-}" &
    pid=$!
    running_family[$pid]="$family"
    next=$((next + 1))
    active=$((active + 1))
  done

  if (( active > 0 )); then
    finished_pid=""
    if wait -n -p finished_pid "${!running_family[@]}"; then
      code=0
    else
      code=$?
    fi
    if [[ -z "$finished_pid" || -z "${running_family[$finished_pid]:-}" ]]; then
      printf '[transport] scheduler lost a worker completion\n' | tee -a "$campaign_log"
      exit 70
    fi
    family="${running_family[$finished_pid]}"
    unset 'running_family[$finished_pid]'
    active=$((active - 1))
    printf '[transport] %s finished %s code %d\n' \
      "$family" "$(date --iso-8601=seconds)" "$code" | tee -a "$campaign_log"
  fi
done

incomplete=0
for row in "${rows[@]}"; do
  family="${row%%$'\t'*}"
  status_file="$status_directory/${family}.tsv"
  if [[ -f "$status_file" ]]; then
    cat "$status_file" >> "$campaign_table"
    grep -q $'\texact\t0\t' "$status_file" || incomplete=$((incomplete + 1))
  else
    printf '%s\tincomplete\t70\tmissing worker status\n' "$family" >> "$campaign_table"
    incomplete=$((incomplete + 1))
  fi
done

printf '[transport] finished with %d incomplete families\n' "$incomplete" |
  tee -a "$campaign_log"
exit "$incomplete"
