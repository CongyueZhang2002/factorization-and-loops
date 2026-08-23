#!/usr/bin/env bash
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
export FACET_KERNEL_COUNT="$kernel_count"
export FACET_CPU_LIST="$cpu_list"

if [[ ! -f "$manifest" ]]; then
  printf 'Observable-transport manifest does not exist: %s\n' "$manifest"
  exit 66
fi

mkdir -p "$output_root"
campaign_log="$output_root/campaign.log"
campaign_table="$output_root/campaign.tsv"
printf 'family\tresult\texit_code\toutput\n' > "$campaign_table"
printf '[transport] CPU affinity %s\n' "$cpu_list" | tee -a "$campaign_log"

incomplete=0
while IFS=$'\t' read -r family epsilon_form differential_system valuations card; do
  [[ -z "$family" || "$family" == \#* || "$family" == "family" ]] && continue
  output="$output_root/observable_transport_${family}.wl"
  arguments=("$epsilon_form" "$differential_system" "$valuations" "$output")
  if [[ -n "${card:-}" ]]; then arguments+=("$card"); fi

  printf '[transport] %s started %s\n' \
    "$family" "$(date --iso-8601=seconds)" | tee -a "$campaign_log"
  set +e
  "$cpu_runner" "$cpu_list" \
    wolframscript -file \
      "$repository_root/Scripts/family_observable_transport.wls" \
      "${arguments[@]}" 2>&1 | tee "$output_root/${family}.log"
  code=${PIPESTATUS[0]}
  set -e

  if (( code == 0 )); then
    printf '%s\texact\t0\t%s\n' "$family" "$output" >> "$campaign_table"
  else
    incomplete=$((incomplete + 1))
    printf '%s\tincomplete\t%d\t%s\n' \
      "$family" "$code" "$output" >> "$campaign_table"
  fi
done < "$manifest"

printf '[transport] finished with %d incomplete families\n' "$incomplete" |
  tee -a "$campaign_log"
exit "$incomplete"
