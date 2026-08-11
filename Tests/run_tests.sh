#!/usr/bin/env bash
# Run every Tests/t_*.wls in its own kernel; nonzero exit if any fails.
# The default per-test limit is a hang guard, not a performance gate:
# t_rationalized_coefficients reconstructs the NNLO ghost grid (2451
# targets) and compares 27 master coefficients exactly, which takes
# about an hour.
set -u
cd "$(dirname "$0")/.."
fail=0
for t in Tests/t_*.wls; do
  echo "== ${t}"
  timeout "${FT_TEST_TIMEOUT:-7200}" wolframscript -file "${t}"
  code=$?
  if [ "${code}" -ne 0 ]; then
    echo "** FAILED (exit ${code}): ${t}"
    fail=1
  fi
done
exit "${fail}"
