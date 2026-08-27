#!/usr/bin/env bash
# Run every categorized Tests/**/t_*.wls (and shell-only t_*.sh) in its
# own process; nonzero exit if any fails.
# The default per-test limit is a hang guard, not a performance gate:
# t_rationalized_coefficients reconstructs the NNLO ghost grid (2451
# targets) and compares 27 master coefficients exactly, which takes
# about an hour.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fail=0
while IFS= read -r -d '' t; do
  echo "== ${t}"
  case "$t" in
    *.wls) timeout "${FT_TEST_TIMEOUT:-7200}" wolframscript -file "$t" ;;
    *.sh)  timeout "${FT_TEST_TIMEOUT:-7200}" bash "$t" ;;
  esac
  code=$?
  if [ "${code}" -ne 0 ]; then
    echo "** FAILED (exit ${code}): ${t}"
    fail=1
  fi
done < <(find Tests -mindepth 2 -type f \
  \( -name 't_*.wls' -o -name 't_*.sh' \) -print0 | sort -z)
exit "${fail}"
