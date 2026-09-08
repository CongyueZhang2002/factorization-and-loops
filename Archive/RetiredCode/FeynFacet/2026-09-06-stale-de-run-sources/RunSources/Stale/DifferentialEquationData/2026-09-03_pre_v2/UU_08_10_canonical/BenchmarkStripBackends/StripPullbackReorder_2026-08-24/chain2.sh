#!/bin/bash
set -u
S=/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/strip_pullback_perf
until grep -q "ALL SUITES DONE" "$S/suites.log"; do sleep 20; done
echo "[chain2 $(date -Is)] suites done -> square-class probe" >> "$S/runner.log"
for attempt in $(seq 1 60); do
  ( cd /home/maxzhang/factorization-and-loops && timeout 3600 taskset -c 10-17 wolframscript -file "$S/scaleprobe.wls" ) > "$S/scaleprobe.log" 2>&1
  code=$?
  if grep -qi "not activated\|license-related" "$S/scaleprobe.log"; then
    back=$((60 + RANDOM % 120))
    echo "[chain2 $(date -Is)] licence refused (attempt $attempt), sleeping ${back}s" >> "$S/runner.log"
    sleep $back; continue
  fi
  echo "[chain2 $(date -Is)] scaleprobe finished exit=$code" >> "$S/runner.log"
  exit $code
done
