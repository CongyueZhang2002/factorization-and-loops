#!/usr/bin/env bash

# Submit one structural boundary-mode build per family.  Families are read
# from the exact NullityPeriods inventory, rather than from the subset that
# happens to have Stage-3 value certificates.
set -euo pipefail

if (( $# != 2 )); then
  echo "Usage: submit_boundary_mode_campaign.sh <pool-directory> <output-directory>" >&2
  exit 64
fi

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/../../.." && pwd)"
pool_directory="$(readlink -f "$1")"
output_directory="$(readlink -m "$2")"
period_file="$repository_root/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BoundaryPeriods/Certificates/NullityPeriods.wl"
mission="$script_directory/build_boundary_mode_campaign.wls"

if [[ ! -f "$pool_directory/pool.pid" ]] ||
    ! kill -0 "$(<"$pool_directory/pool.pid")" 2>/dev/null; then
  echo "No running KernelPool at $pool_directory" >&2
  exit 2
fi

mapfile -t families < <(python3 - "$period_file" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
families = set()
for match in re.finditer(r'"Families"\s*->\s*\{([^}]*)\}', text):
    families.update(re.findall(r'CF\d+', match.group(1)))
for family in sorted(families, key=lambda value: int(value[2:])):
    print(family)
PY
)

mkdir -p "$output_directory"
for family in "${families[@]}"; do
  POOL="$pool_directory" \
  FACET_TASK_BROKER_MAX_HELPERS=0 \
  FACET_RESOURCE_GROUP="$family" \
  FACET_RESOURCE_ROLE=family \
    "$repository_root/Scripts/kpsubmit.sh" \
      "boundary_mode_$family" "$mission" "$output_directory" "$family"
done
