#!/usr/bin/env bash
# Exact observable transports through one Wolfram main plus N subkernels.
set -u

if (( $# != 3 )); then
  printf '%s\n' \
    'Usage: observable_transport_kernelpool_campaign.sh <manifest.tsv> <output-root> <pool-root>'
  exit 64
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$(realpath "$1")"
output_root="$(realpath -m "$2")"
pool_root="$(realpath -m "$3")"
cpu_list="${FACET_CPU_LIST:-0-15}"
kernel_count="${FACET_KERNEL_COUNT:-8}"
(( kernel_count < 1 )) && kernel_count=1
(( kernel_count > 8 )) && kernel_count=8

decode_tsv_field() {
  local value="${1:-}"
  if (( ${#value} >= 2 )) &&
      [[ "${value:0:1}" == '"' && "${value: -1}" == '"' ]]; then
    value="${value:1:${#value}-2}"
    value="${value//\"\"/\"}"
  fi
  printf '%s' "$value"
}

mkdir -p "$output_root" "$pool_root"
campaign_log="$output_root/campaign.log"
campaign_table="$output_root/campaign.tsv"
status_directory="$output_root/.campaign-status"
mkdir -p "$status_directory"
export POOL="$pool_root"
export FACET_TASK_BROKER="$pool_root"
export FACET_KERNEL_COUNT=1
export FACET_CPU_LIST="$cpu_list"

if ! { [[ -f "$pool_root/pool.pid" ]] &&
    kill -0 "$(cat "$pool_root/pool.pid")" 2>/dev/null; }; then
  rm -f "$pool_root/control/stop" "$pool_root/control/stopnow"
  taskset -c "$cpu_list" nohup env FACET_KERNEL_COUNT=1 \
    wolframscript -file "$repository_root/Scripts/KernelPool.wls" \
    "$pool_root" "$kernel_count" True > "$pool_root/pool.log" 2>&1 &
  ready=0
  for _ in $(seq 1 120); do
    if grep -q 'serving; queue=' "$pool_root/pool.log" 2>/dev/null; then
      ready=1
      break
    fi
    /bin/sleep 1
  done
  if (( ready == 0 )); then
    printf 'Observable-transport kernel pool did not start: %s\n' \
      "$pool_root/pool.log"
    exit 2
  fi
fi

run_tag="$(date +%Y%m%dT%H%M%S)-$$"
families=()
missions=()
outputs=()
rows=()
while IFS=$'\t' read -r raw_family raw_epsilon_form \
    raw_differential_system raw_valuations raw_card; do
  family="$(decode_tsv_field "$raw_family")"
  [[ -z "$family" || "$family" == \#* || "$family" == "family" ]] && continue
  epsilon_form="$(decode_tsv_field "$raw_epsilon_form")"
  differential_system="$(decode_tsv_field "$raw_differential_system")"
  valuations="$(decode_tsv_field "$raw_valuations")"
  card="$(decode_tsv_field "${raw_card:-}")"
  output="$output_root/observable_transport_${family}.wl"
  mission="obs_${run_tag}_${family}"
  families+=("$family")
  missions+=("$mission")
  outputs+=("$output")
  rows+=("$epsilon_form"$'\t'"$differential_system"$'\t'"$valuations"$'\t'"$card")
  printf '%s\tqueued\t-\t%s\n' "$family" "$output" > \
    "$status_directory/${family}.tsv"
done < "$manifest"

max_families=$(( kernel_count > 2 ? kernel_count - 2 : 1 ))
[[ -n "${FACET_MAX_FAMILIES:-}" ]] && max_families="$FACET_MAX_FAMILIES"
if ! [[ "$max_families" =~ ^[1-9][0-9]*$ ]] ||
    (( max_families > kernel_count )); then
  printf 'FACET_MAX_FAMILIES must be between 1 and %d\n' "$kernel_count"
  exit 64
fi

printf '[transport-pool] %s: one main + %s subkernels on CPUs %s; families %s; family slots %s; helper seats %s\n' \
  "$(date --iso-8601=seconds)" "$kernel_count" "$cpu_list" \
  "${#families[@]}" "$max_families" "$((kernel_count - max_families))" |
  tee -a "$campaign_log"

run_family() {
  local index="$1" family mission output epsilon_form differential_system
  local valuations card code arguments
  family="${families[$index]}"
  mission="${missions[$index]}"
  output="${outputs[$index]}"
  IFS=$'\t' read -r epsilon_form differential_system valuations card \
    <<< "${rows[$index]}"
  arguments=("$epsilon_form" "$differential_system" "$valuations" \
    "$output")
  [[ -n "${card:-}" ]] && arguments+=("$card")
  FACET_RESOURCE_GROUP="$family" FACET_RESOURCE_ROLE=family \
    FACET_RESOURCE_OWNER="${run_tag}_${family}" \
    "$repository_root/Scripts/kpsubmit.sh" "$mission" \
    "$repository_root/Scripts/family_observable_transport_pool_mission.wls" \
    "${arguments[@]}" >/dev/null
  ln -sfn "$pool_root/logs/${mission}.log" "$output_root/${family}.log"
  wait_file="$output_root/${family}.pool-status"
  if "$repository_root/Scripts/kpwait.sh" "$mission" 86400 > \
      "$wait_file" 2>&1; then
    printf '%s\texact\t0\t%s\n' "$family" "$output" > \
      "$status_directory/${family}.tsv"
    printf '[transport-pool] %s exact %s\n' \
      "$family" "$(date --iso-8601=seconds)" | tee -a "$campaign_log"
  else
    code=$?
    printf '%s\tincomplete\t%d\t%s\n' "$family" "$code" "$output" > \
      "$status_directory/${family}.tsv"
    printf '[transport-pool] %s incomplete code %d %s\n' \
      "$family" "$code" "$(date --iso-8601=seconds)" | tee -a "$campaign_log"
  fi
}

# Keep the easy-first manifest order, but reserve two pool seats for the
# established task broker.  As the queue drains, every unoccupied family slot
# automatically becomes another helper available to the remaining families.
next_index=0
running=""
family_count="${#families[@]}"
while true; do
  live=""
  active=0
  for pid in $running; do
    if kill -0 "$pid" 2>/dev/null; then
      live="$live $pid"
      active=$((active + 1))
    fi
  done
  running="$live"
  while (( active < max_families && next_index < family_count )); do
    run_family "$next_index" &
    running="$running $!"
    next_index=$((next_index + 1))
    active=$((active + 1))
  done
  (( active == 0 && next_index == family_count )) && break
  /bin/sleep 1
done

printf 'family\tresult\texit_code\toutput\n' > "$campaign_table"
incomplete=0
for index in "${!families[@]}"; do
  family="${families[$index]}"
  if [[ "$(cut -f2 "$status_directory/${family}.tsv")" != "exact" ]]; then
    incomplete=$((incomplete + 1))
  fi
  cat "$status_directory/${family}.tsv" >> "$campaign_table"
done

touch "$pool_root/control/stop"
printf '[transport-pool] finished with %d incomplete families\n' \
  "$incomplete" | tee -a "$campaign_log"
exit "$incomplete"
