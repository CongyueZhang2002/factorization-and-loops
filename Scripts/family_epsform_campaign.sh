#!/usr/bin/env bash
set -u

if (( $# < 2 )); then
  printf '%s\n' \
    'Usage: family_epsform_campaign.sh <output-root> <family> [family ...]' \
    'Optional: FACET_CHART_MANIFEST=<tab-separated family/chart-file table>' \
    '          FACET_FAMILY_DATA_DIRECTORY=<differential-equation data root>' \
    '          FACET_CLASS_FORM_DIRECTORY=<class-form directory>'
  exit 64
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cpu_runner="$repository_root/FeynFacet/Tools/RunWithCPUList.sh"
output_root="$1"
shift
families=("$@")

sector_budget="${FACET_SECTOR_BUDGET:-1800}"
direct_sector_budget="${FACET_DIRECT_SECTOR_BUDGET:-30}"
kernel_count="${FACET_KERNEL_COUNT:-8}"
if (( kernel_count < 1 )); then kernel_count=1; fi
if (( kernel_count > 8 )); then kernel_count=8; fi
export FACET_KERNEL_COUNT="$kernel_count"
cpu_list="${FACET_CPU_LIST:-0-15}"
family_data_directory="${FACET_FAMILY_DATA_DIRECTORY:-}"
class_form_directory="${FACET_CLASS_FORM_DIRECTORY:-}"

declare -A chart_files=()
chart_manifest="${FACET_CHART_MANIFEST:-}"
if [[ -n "$chart_manifest" ]]; then
  if [[ ! -f "$chart_manifest" ]]; then
    printf '[campaign] chart manifest does not exist: %s\n' "$chart_manifest"
    exit 66
  fi
  while IFS=$'\t' read -r chart_family chart_file; do
    [[ -z "$chart_family" || "$chart_family" == \#* ]] && continue
    chart_files["$chart_family"]="$chart_file"
  done < "$chart_manifest"
fi

mkdir -p "$output_root"
campaign_log="$output_root/campaign.log"
campaign_table="$output_root/campaign.tsv"
printf 'family\tresult\texit_code\trecord\n' > "$campaign_table"

validated_v2_record() {
  local record="$1"
  [[ -f "$record" ]] &&
    grep -q '"DataType" -> "FamilyDLogEpsilonForm"' "$record" &&
    grep -q '"SchemaVersion" -> 2' "$record" &&
    grep -q '"Status" -> "FamilyDLogEpsilonFormValidated"' "$record"
}

printf '[campaign] CPU affinity %s; %d families\n' \
  "$cpu_list" "${#families[@]}" |
  tee -a "$campaign_log"

failures=0
# A stored status alone does not establish the defining equation against the
# current differential system. Re-enter the worker so its V2 validator makes
# that mathematical decision; completed sector checkpoints remain reusable.
for family in "${families[@]}"; do
  family_directory="$output_root/$family"
  record="$family_directory/family_epsform_$family.wl"
  mkdir -p "$family_directory"

  printf '[campaign] %s started %s\n' "$family" "$(date --iso-8601=seconds)" |
    tee -a "$campaign_log"
  worker_arguments=(
    "$family" "$family_directory" "$sector_budget" standard
    "$direct_sector_budget" "${chart_files[$family]:-}"
  )
  if [[ -n "$family_data_directory" || -n "$class_form_directory" ]]; then
    worker_arguments+=("$family_data_directory" "$class_form_directory")
  fi
  set +e
  "$cpu_runner" "$cpu_list" \
    wolframscript -file "$repository_root/Scripts/family_epsform_sector.wls" \
      "${worker_arguments[@]}" 2>&1 | tee "$family_directory/run.log"
  code=${PIPESTATUS[0]}
  set -e

  if (( code == 0 )) && validated_v2_record "$record"; then
    printf '[campaign] %s validated %s\n' "$family" "$(date --iso-8601=seconds)" |
      tee -a "$campaign_log"
    printf '%s\tvalidated-new\t0\t%s\n' "$family" "$record" >> "$campaign_table"
  else
    failures=$((failures + 1))
    printf '[campaign] %s incomplete (exit %d); retained checkpoints\n' \
      "$family" "$code" | tee -a "$campaign_log"
    printf '%s\tincomplete\t%d\t%s\n' "$family" "$code" "$record" >> "$campaign_table"
  fi
done

printf '[campaign] finished with %d incomplete families\n' "$failures" |
  tee -a "$campaign_log"
exit "$failures"
