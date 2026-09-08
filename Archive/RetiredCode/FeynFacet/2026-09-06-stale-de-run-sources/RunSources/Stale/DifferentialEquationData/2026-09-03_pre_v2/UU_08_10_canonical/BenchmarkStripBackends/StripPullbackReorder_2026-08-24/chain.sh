#!/bin/bash
# Hold the licence slot: the moment the equivalence run finishes GREEN,
# start the suites in the same serialized lane.  A red equivalence run
# stops the chain (no point testing code that failed its own gate).
set -u
S=/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/strip_pullback_perf
until grep -q "case=ALL finished\|GAVE UP" "$S/runner.log"; do sleep 20; done
if grep -q "all equal: True" "$S/case_ALL.log"; then
  echo "[chain $(date -Is)] equivalence green -> starting the suites" >> "$S/runner.log"
  bash "$S/suites.sh"
else
  echo "[chain $(date -Is)] equivalence NOT green -> suites NOT started" >> "$S/runner.log"
fi
