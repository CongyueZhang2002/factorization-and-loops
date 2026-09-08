#!/usr/bin/env bash

# Submit one independent physical-endpoint mission per family to an existing
# KernelPool.  The family is the resource group: this lets the pool distribute
# workers across families and rebalance naturally as missions finish.
set -euo pipefail

if (( $# < 1 || $# > 2 )); then
  echo "Usage: submit_physical_endpoint_transport_campaign.sh <pool-directory> [output-directory]" >&2
  exit 64
fi

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/../../.." && pwd)"
pool_directory="$(readlink -f "$1")"
output_directory="${2:-$repository_root/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/PhysicalEndpointTransport}"
mode_directory="$repository_root/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/PhysicalBoundaryModes"
mission="$script_directory/build_physical_endpoint_transport_family.wls"

if [[ ! -f "$pool_directory/pool.pid" ]] ||
    ! kill -0 "$(<"$pool_directory/pool.pid")" 2>/dev/null; then
  echo "No running KernelPool at $pool_directory" >&2
  exit 2
fi

for mode_file in "$mode_directory"/boundary_mode_CF*.wl; do
  family="${mode_file##*/boundary_mode_}"
  family="${family%.wl}"
  POOL="$pool_directory" \
  FACET_TASK_BROKER_MAX_HELPERS=0 \
  FACET_RESOURCE_GROUP="$family" \
  FACET_RESOURCE_ROLE=family \
    "$repository_root/Scripts/kpsubmit.sh" \
      "physical_endpoint_$family" "$mission" "$output_directory" "$family"
done
