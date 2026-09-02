#!/bin/bash
# Sequential runner for standalone kernel jobs: one licence seat, one job at a time.
# Usage: seatqueue.sh QUEUEFILE LOG   -- QUEUEFILE lines: ALLOWANCE_SECONDS<TAB>LABEL<TAB>WORKDIR<TAB>COMMAND
# Each job runs under setsid with its own allowance kill; a licence refusal retries the job after 60-180 s (up to 30 times).
Q=$1; LOG=$2
while IFS=$'\t' read -r allowance label workdir cmd; do
  [ -z "$allowance" ] && continue
  case "$allowance" in \#*) continue;; esac
  for attempt in $(seq 1 30); do
    echo "=== JOB $label attempt $attempt start $(date -Is) allowance ${allowance}s :: $cmd" >> "$LOG"
    joblog="$(dirname "$LOG")/seatqueue_${label}.log"
    ( cd "$workdir" && setsid bash -c "$cmd" >> "$joblog" 2>&1 & pid=$!; echo $pid > "$joblog.pid"
      ( sleep "$allowance"; if kill -0 $pid 2>/dev/null; then echo "ALLOWANCE EXPIRED after ${allowance}s" >> "$joblog"; kill -9 -- -$pid; fi ) & timer=$!
      wait $pid; code=$?; kill $timer 2>/dev/null; echo "JOB exit=$code" >> "$joblog"; exit $code )
    code=$?
    if tail -c 3000 "$joblog" | grep -a -q "not activated or is experiencing a license"; then
      echo "=== JOB $label licence refusal; retry after pause" >> "$LOG"; sleep $((60 + RANDOM % 120)); continue
    fi
    tally="$(command grep -a -E '^[0-9]+ assertions|OK, [0-9]+ FAIL|agreement on the sample|jet route, full matrix|observable transport|\[benchmark\] done' "$joblog" | tail -2 | tr '\n' ' ')"
    [ -z "$tally" ] && tally="NO-TALLY (void: the job produced no result marker)"
    echo "=== JOB $label end $(date -Is) exit=$code tally: $tally" >> "$LOG"
    break
  done
done < "$Q"
echo "=== QUEUE DONE $(date -Is)" >> "$LOG"
