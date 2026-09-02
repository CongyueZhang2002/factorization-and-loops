#!/usr/bin/env bash
# Two-stage master pipeline: (1) complete_family_epsforms.sh, (2)
# complete_observable_transport.sh.  "master transport" here names the
# pipeline that delivers the transported masters, NOT the retired Libra
# path-ordered route (TransportFamily answers RouteRetired since round 2,
# 2026-09-02): stage (2) is the observable transport, so this wrapper
# stays live (checked round 4, 2026-09-02).
set -eu

usage() {
  printf '%s\n' \
    'Usage: complete_master_transport.sh <output-root> <differential-system-directory> <valuations.wl> <epsilon-form-directory> [epsilon-form-directory ...] [--card=<transport-card.wl>]' \
    '' \
    'The calculation has two exact stages:' \
    '  1. certify existing epsilon forms and solve every missing family;' \
    '  2. transport only the master rows and epsilon orders requested by the valuations and card.'
}

if (( $# < 4 )); then
  usage
  exit 64
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="$1"
differential_directory="$2"
valuations="$3"
shift 3

candidate_directories=()
card_argument=()
for argument in "$@"; do
  if [[ "$argument" == --card=* ]]; then
    if (( ${#card_argument[@]} != 0 )); then
      usage
      exit 64
    fi
    card_argument=("$argument")
  else
    candidate_directories+=("$argument")
  fi
done

if (( ${#candidate_directories[@]} == 0 )); then
  usage
  exit 64
fi
if [[ ! -d "$differential_directory" || ! -f "$valuations" ]]; then
  printf '[master-transport] differential systems or valuations are missing\n'
  exit 66
fi
for directory in "${candidate_directories[@]}"; do
  if [[ ! -d "$directory" ]]; then
    printf '[master-transport] epsilon-form directory is missing: %s\n' "$directory"
    exit 66
  fi
done

kernel_count="${FACET_KERNEL_COUNT:-8}"
if (( kernel_count < 1 )); then kernel_count=1; fi
if (( kernel_count > 8 )); then kernel_count=8; fi
export FACET_KERNEL_COUNT="$kernel_count"
export FACET_CPU_LIST="${FACET_CPU_LIST:-0-15}"

epsilon_root="$output_root/epsilon_forms"
transport_root="$output_root/observable_transport"
certified_directory="$epsilon_root/certified"
mkdir -p "$output_root"

printf '[master-transport] exact epsilon-form inventory\n'
"$repository_root/Scripts/complete_family_epsforms.sh" \
  "$epsilon_root" "$differential_directory" \
  "${candidate_directories[@]}"

printf '[master-transport] demand-driven observable transport\n'
"$repository_root/Scripts/complete_observable_transport.sh" \
  "$transport_root" "$differential_directory" "$valuations" \
  "$certified_directory" "${card_argument[@]}"

printf '[master-transport] exact epsilon forms and demanded transports are complete\n'
