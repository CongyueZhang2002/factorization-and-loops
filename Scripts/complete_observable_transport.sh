#!/usr/bin/env bash
set -u

if (( $# < 4 )); then
  printf '%s\n' \
    'Usage: complete_observable_transport.sh <output-root> <differential-system-directory> <valuations.wl> <epsilon-form-directory> [epsilon-form-directory ...] [--card=<transport-card.wl>]'
  exit 64
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cpu_runner="$repository_root/FeynFacet/Tools/RunWithCPUList.sh"
output_root="$1"
differential_directory="$2"
valuations="$3"
shift 3
arguments=("$@")
epsilon_directories=()
card_argument=()
for argument in "${arguments[@]}"; do
  if [[ "$argument" == --card=* ]]; then
    card_argument=("$argument")
  else
    epsilon_directories+=("$argument")
  fi
done
if (( ${#epsilon_directories[@]} == 0 )); then exit 64; fi

cpu_list="${FACET_CPU_LIST:-0-15}"
kernel_count="${FACET_KERNEL_COUNT:-8}"
if (( kernel_count < 1 )); then kernel_count=1; fi
if (( kernel_count > 8 )); then kernel_count=8; fi
export FACET_KERNEL_COUNT="$kernel_count"
export FACET_CPU_LIST="$cpu_list"

mkdir -p "$output_root"
manifest="$output_root/observable_transport_manifest.tsv"
inventory_report="$output_root/observable_transport_inventory.wl"
transport_directory="$output_root/families"
maximum_rounds="${FACET_TRANSPORT_ROUNDS:-2}"

"$cpu_runner" "$cpu_list" wolframscript -file \
  "$repository_root/Scripts/build_observable_transport_manifest.wls" \
  "$differential_directory" "$valuations" "$manifest" \
  "$inventory_report" "${epsilon_directories[@]}" "${card_argument[@]}" ||
  exit $?

transport_complete=false
for ((round = 1; round <= maximum_rounds; round++)); do
  printf '[transport] campaign round %d of %d\n' "$round" "$maximum_rounds"
  set +e
  "$repository_root/Scripts/observable_transport_campaign.sh" \
    "$manifest" "$transport_directory"
  code=$?
  set -e
  if (( code == 0 )); then
    transport_complete=true
    break
  fi
done

if [[ "$transport_complete" != true ]]; then
  printf '[transport] exact family transports remain incomplete after %d rounds\n' \
    "$maximum_rounds"
  exit 1
fi

printf '[transport] every exact family in %s was transported with exact certificates\n' \
  "$manifest"
