#!/usr/bin/env bash
# Convenience wrapper for running a selected two-root-family campaign through
# the general V2 pool launcher.  The mathematical inputs are explicit rows in
# the supplied table; this wrapper owns no project directory or artifact
# naming convention.
set -u

if (( $# < 5 )); then
  echo "Usage: tworoot_parallel.sh <output-root> <pooldir> <nkernels> <v2-input-table.tsv> <family> [family ...]" >&2
  exit 64
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$root/Scripts/family_epsform_pool.sh" "$@"
