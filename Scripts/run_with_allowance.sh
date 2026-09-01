#!/bin/bash
# Generic kernel launcher with a hard allowance (house rule 2026-08-31,
# Design/Watchdog.md): the wolframscript runs in its own process group
# and a timer in THIS script SIGKILLs the whole group at the allowance.
# Usage: run_with_allowance.sh ALLOWANCE_SECONDS LOGFILE SCRIPT [args...]
ALLOWANCE=$1; LOG=$2; SCRIPT=$3; shift 3
CORES="${CORES:-0,1,6,7}"   # P-cores first (265K: LP 0,1,6,7,8,9,18,19)
setsid taskset -c "$CORES" wolframscript -file "$SCRIPT" "$@" >> "$LOG" 2>&1 &
RUNPID=$!
( trap 'kill "$SLEEPPID" 2>/dev/null; exit 0' TERM
  sleep "$ALLOWANCE" & SLEEPPID=$!
  wait "$SLEEPPID" || exit 0
  if kill -0 "$RUNPID" 2>/dev/null; then
    echo "ALLOWANCE EXPIRED after ${ALLOWANCE}s — killing group $RUNPID" >> "$LOG"
    kill -9 -- -"$RUNPID" 2>/dev/null
  fi ) &
TIMERPID=$!
wait "$RUNPID"; CODE=$?
kill "$TIMERPID" 2>/dev/null
echo "RUN exit=$CODE" >> "$LOG"
exit "$CODE"
