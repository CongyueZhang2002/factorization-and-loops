#!/usr/bin/env bash
# Convenience wrapper for running selected two-root families through the
# general V2 single-process campaign launcher.  It deliberately carries no
# family-specific result-directory layout.
set -u

if (( $# < 3 )); then
  echo "Usage: tworoot_campaign.sh <output-root> <v2-input-table.tsv> <family> [family ...]" >&2
  exit 64
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$root/Scripts/family_epsform_campaign.sh" "$@"
