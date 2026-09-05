#!/usr/bin/env bash
# Run the general V2 family dlog epsilon-form campaign.  The worker performs
# the defining-equation validation before it writes a result, so this launcher
# neither recertifies records nor fingerprints construction checkpoints.
set -u

if (( $# < 3 )); then
  echo "Usage: complete_family_epsforms.sh <output-root> <v2-input-table.tsv> <family> [family ...]" >&2
  exit 64
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$repository_root/Scripts/family_epsform_campaign.sh" "$@"
