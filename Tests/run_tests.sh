#!/usr/bin/env bash
# Run every Tests/t_*.wls in its own kernel; nonzero exit if any fails.
set -u
cd "$(dirname "$0")/.."
fail=0
for t in Tests/t_*.wls; do
  echo "== ${t}"
  timeout "${FT_TEST_TIMEOUT:-1200}" wolframscript -file "${t}"
  code=$?
  if [ "${code}" -ne 0 ]; then
    echo "** FAILED (exit ${code}): ${t}"
    fail=1
  fi
done
exit "${fail}"
