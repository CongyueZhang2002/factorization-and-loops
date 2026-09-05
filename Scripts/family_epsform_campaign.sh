#!/usr/bin/env bash
set -u

if (( $# < 3 )); then
  printf '%s\n' \
    'Usage: family_epsform_campaign.sh <output-root> <v2-input-table.tsv> <family> [family ...]' \
    'Each table row is: family<TAB>FamilyDifferentialSystem<TAB>BlockDecomposition<TAB>CoefficientPresentation<TAB>DiagonalBlockDLogEpsilonFormsDirectory' \
    'Paths may be absolute or repository-root-relative.'
  exit 64
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cpu_runner="$repository_root/FeynFacet/Tools/RunWithCPUList.sh"
output_root="$1"
input_table="$2"
shift 2
families=("$@")

sector_budget="${FACET_SECTOR_BUDGET:-1800}"
direct_sector_budget="${FACET_DIRECT_SECTOR_BUDGET:-30}"
kernel_count="${FACET_KERNEL_COUNT:-8}"
if (( kernel_count < 1 )); then kernel_count=1; fi
if (( kernel_count > 8 )); then kernel_count=8; fi
export FACET_KERNEL_COUNT="$kernel_count"
cpu_list="${FACET_CPU_LIST:-0-15}"
if [[ ! -f "$input_table" ]]; then
  printf '[campaign] V2 input table does not exist: %s\n' "$input_table"
  exit 66
fi

resolve_input_path() {
  case "$1" in
    /*) printf '%s' "$1" ;;
    *) printf '%s/%s' "$repository_root" "$1" ;;
  esac
}

declare -A differential_system_files=()
declare -A block_decomposition_files=()
declare -A coefficient_presentation_files=()
declare -A diagonal_form_directories=()
while IFS=$'\t' read -r input_family differential_system_file \
    block_decomposition_file coefficient_presentation_file \
    diagonal_form_directory extra; do
  [[ -z "$input_family" || "$input_family" == \#* ]] && continue
  if [[ -n "${extra:-}" || -z "$differential_system_file" ||
        -z "$block_decomposition_file" || -z "$coefficient_presentation_file" ||
        -z "$diagonal_form_directory" ]]; then
    printf '[campaign] malformed V2 input row for %s\n' "$input_family"
    exit 64
  fi
  differential_system_files["$input_family"]="$(resolve_input_path "$differential_system_file")"
  block_decomposition_files["$input_family"]="$(resolve_input_path "$block_decomposition_file")"
  coefficient_presentation_files["$input_family"]="$(resolve_input_path "$coefficient_presentation_file")"
  diagonal_form_directories["$input_family"]="$(resolve_input_path "$diagonal_form_directory")"
done < "$input_table"

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
  record="$family_directory/FamilyDLogEpsilonForm.wl"
  mkdir -p "$family_directory"

  if [[ -z "${differential_system_files[$family]:-}" ]]; then
    failures=$((failures + 1))
    printf '[campaign] %s has no row in %s\n' "$family" "$input_table" |
      tee -a "$campaign_log"
    printf '%s\tmissing-input-row\t66\t%s\n' "$family" "$record" >> "$campaign_table"
    continue
  fi

  printf '[campaign] %s started %s\n' "$family" "$(date --iso-8601=seconds)" |
    tee -a "$campaign_log"
  worker_arguments=(
    "$family" "$family_directory"
    "${differential_system_files[$family]}"
    "${block_decomposition_files[$family]}"
    "${coefficient_presentation_files[$family]}"
    "${diagonal_form_directories[$family]}"
    "$sector_budget" standard "$direct_sector_budget"
  )
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
