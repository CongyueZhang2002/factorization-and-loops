#!/bin/bash
# One main kernel of ours at a time, P-cores of the production pool untouched
# (taskset -c 10-17).  Jittered 60-180 s backoff on a license refusal
# (CLAUDE.md, Compute budget).
# usage: runner.sh <case> <oldLimitSeconds> <logfile>
S=/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/strip_pullback_perf
CASE="$1"; LIMIT="$2"; LOG="$3"
echo "[runner $(date -Is)] case=$CASE limit=$LIMIT log=$LOG" >> "$S/runner.log"
for attempt in $(seq 1 60); do
  taskset -c 10-17 wolframscript -file "$S/equiv.wls" "$CASE" "$LIMIT" > "$LOG" 2>&1
  code=$?
  if grep -qi "not activated\|license-related\|license" "$LOG"; then
    back=$((60 + RANDOM % 120))
    echo "[runner $(date -Is)] license refused (attempt $attempt), sleeping ${back}s" >> "$S/runner.log"
    sleep $back
    continue
  fi
  echo "[runner $(date -Is)] case=$CASE finished exit=$code after $attempt attempt(s)" >> "$S/runner.log"
  exit $code
done
echo "[runner $(date -Is)] case=$CASE GAVE UP: no licence in 60 attempts" >> "$S/runner.log"
exit 3
