#!/usr/bin/env bash
set -u

if (( $# < 3 )); then
  printf '%s\n' \
    'Usage: complete_family_epsforms.sh <output-root> <differential-system-directory> <candidate-directory> [candidate-directory ...]'
  exit 64
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cpu_runner="$repository_root/FeynFacet/Tools/RunWithCPUList.sh"
output_root="$1"
differential_directory="$2"
shift 2
candidate_directories=("$@")
certified_directory="$output_root/certified"
solved_directory="$output_root/solved"
report="$certified_directory/certification_report.wl"
cpu_list="${FACET_CPU_LIST:-0-15}"
kernel_count="${FACET_KERNEL_COUNT:-8}"
if (( kernel_count < 1 )); then kernel_count=1; fi
if (( kernel_count > 8 )); then kernel_count=8; fi
export FACET_KERNEL_COUNT="$kernel_count"
export FACET_CPU_LIST="$cpu_list"

mkdir -p "$certified_directory" "$solved_directory"

maximum_rounds="${FACET_COMPLETION_ROUNDS:-64}"
maximum_stalled_rounds="${FACET_STALLED_ROUNDS:-2}"

certify() {
  "$cpu_runner" "$cpu_list" wolframscript -file \
    "$repository_root/Scripts/certify_family_epsform_campaign.wls" \
    "$certified_directory" "$differential_directory" \
    "${candidate_directories[@]}" "$solved_directory"
}

incomplete_names() {
  "$cpu_runner" "$cpu_list" wolframscript -file \
    "$repository_root/Scripts/incomplete_family_names.wls" "$report"
}

checkpoint_fingerprint() {
  find "$solved_directory" -type f \
    \( -name 'sector_state_*.wl' -o -name 'family_epsform_*.wl' \) \
    -printf '%P\t%s\t%T@\n' 2>/dev/null | sort | sha256sum | awk '{print $1}'
}

export FACET_FAMILY_DATA_DIRECTORY="${FACET_FAMILY_DATA_DIRECTORY:-$(dirname "$differential_directory")}" 
export FACET_CLASS_FORM_DIRECTORY="${FACET_CLASS_FORM_DIRECTORY:-$(dirname "$differential_directory")/ClassForms}"

round=0
stalled_rounds=0
previous_fingerprint="$(checkpoint_fingerprint)"
while true; do
  set +e
  certify
  set -e
  if [[ ! -f "$report" ]]; then
    printf '[epsilon-form] certification report was not created: %s\n' "$report"
    exit 1
  fi
  mapfile -t incomplete_families < <(incomplete_names)
  if (( ${#incomplete_families[@]} == 0 )); then
    printf '[epsilon-form] every differential family has an exact certificate\n'
    exit 0
  fi

  round=$((round + 1))
  if (( round > maximum_rounds )); then
    printf '[epsilon-form] stopped after %d solver rounds; %d families remain: %s\n' \
      "$maximum_rounds" "${#incomplete_families[@]}" "${incomplete_families[*]}"
    exit 1
  fi
  printf '[epsilon-form] solver round %d: %d incomplete families: %s\n' \
    "$round" "${#incomplete_families[@]}" "${incomplete_families[*]}"

  set +e
  "$repository_root/Scripts/family_epsform_campaign.sh" \
    "$solved_directory" "${incomplete_families[@]}"
  set -e

  current_fingerprint="$(checkpoint_fingerprint)"
  if [[ "$current_fingerprint" == "$previous_fingerprint" ]]; then
    stalled_rounds=$((stalled_rounds + 1))
  else
    stalled_rounds=0
  fi
  previous_fingerprint="$current_fingerprint"
  if (( stalled_rounds >= maximum_stalled_rounds )); then
    printf '[epsilon-form] no exact sector checkpoint changed in %d consecutive rounds\n' \
      "$stalled_rounds"
    exit 1
  fi
done
