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
export FACET_KERNEL_COUNT=1
export FACET_CPU_LIST="$cpu_list"

if ! { [[ -f "$pool_root/pool.pid" ]] &&
    kill -0 "$(cat "$pool_root/pool.pid")" 2>/dev/null; }; then
  rm -f "$pool_root/control/stop" "$pool_root/control/stopnow"
  taskset -c "$cpu_list" nohup env FACET_KERNEL_COUNT=1 \
    wolframscript -file "$repository_root/Scripts/KernelPool.wls" \
    "$pool_root" "$kernel_count" False > "$pool_root/pool.log" 2>&1 &
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

printf '[transport-pool] %s: one main + %s subkernels on CPUs %s; families %s\n' \
  "$(date --iso-8601=seconds)" "$kernel_count" "$cpu_list" \
  "${#families[@]}" | tee -a "$campaign_log"

for index in "${!families[@]}"; do
  IFS=$'\t' read -r epsilon_form differential_system valuations card \
    <<< "${rows[$index]}"
  arguments=("$epsilon_form" "$differential_system" "$valuations" \
    "${outputs[$index]}")
  [[ -n "${card:-}" ]] && arguments+=("$card")
  "$repository_root/Scripts/kpsubmit.sh" "${missions[$index]}" \
    "$repository_root/Scripts/family_observable_transport_pool_mission.wls" \
    "${arguments[@]}" >/dev/null
  ln -sfn "$pool_root/logs/${missions[$index]}.log" \
    "$output_root/${families[$index]}.log"
done

printf 'family\tresult\texit_code\toutput\n' > "$campaign_table"
incomplete=0
for index in "${!families[@]}"; do
  family="${families[$index]}"
  mission="${missions[$index]}"
  output="${outputs[$index]}"
  wait_file="$output_root/${family}.pool-status"
  if "$repository_root/Scripts/kpwait.sh" "$mission" 86400 > \
      "$wait_file" 2>&1; then
    printf '%s\texact\t0\t%s\n' "$family" "$output" > \
      "$status_directory/${family}.tsv"
    printf '[transport-pool] %s exact %s\n' \
      "$family" "$(date --iso-8601=seconds)" | tee -a "$campaign_log"
  else
    code=$?
    incomplete=$((incomplete + 1))
    printf '%s\tincomplete\t%d\t%s\n' "$family" "$code" "$output" > \
      "$status_directory/${family}.tsv"
    printf '[transport-pool] %s incomplete code %d %s\n' \
      "$family" "$code" "$(date --iso-8601=seconds)" | tee -a "$campaign_log"
  fi
  cat "$status_directory/${family}.tsv" >> "$campaign_table"
done

touch "$pool_root/control/stop"
printf '[transport-pool] finished with %d incomplete families\n' \
  "$incomplete" | tee -a "$campaign_log"
exit "$incomplete"
