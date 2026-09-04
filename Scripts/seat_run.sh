#!/bin/bash
# seat_run.sh TIMEOUT_SECONDS COMMAND...   -- runs COMMAND under one of the two licensed
# main-kernel seats (flock), pinned to that seat's CPUs, with a hard timeout.
# Waits (polling) until a seat is free. Exit code = the command's (124 on timeout).
T=$1; shift
# a wolframscript -file target that does not exist relative to the caller's cwd makes
# wolframscript print "Failed to open file" and exit 0 (a false green): refuse it here
for ((i=1;i<=$#;i++)); do
  if [ "${!i}" = "-file" ]; then j=$((i+1)); f="${!j}"
    if [ ! -f "$f" ]; then echo "seat_run.sh: script not found from $(pwd): $f" >&2; exit 66; fi; fi
done
S=/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad/seats
declare -A CPUS=( [A]="2-5,10-13" [B]="14-17,0,1,6,7" )
while true; do
  for seat in A B; do
    exec {fd}>"$S/seat_$seat.lock"
    if flock -n $fd; then
      echo "seat $seat acquired $(date +%T) :: timeout $T :: $*" >> "$S/seat_log.txt"
      # the release line is written on EVERY exit path, including the wrapper being
      # killed by signal (2026-09-02: a wrapper killed by PID left a seat without a
      # release line for 3.5 minutes; the flock itself is freed by the kernel on exit)
      released=0; cmdstr="$*"
      release() { if [ "$released" = 0 ]; then released=1; echo "seat $seat released $(date +%T) exit=${1:-signal} :: $cmdstr" >> "$S/seat_log.txt"; fi; }
      trap 'release killed; exit 143' TERM INT HUP
      # memory allowance (2026-09-03: a finisher probe reached 31 GB and was OOM-killed,
      # its twin 28 GB): the job's process tree is killed when its resident set passes
      # MEM_GB gigabytes (default 20), recorded as exit 138
      timeout --signal=KILL "$T" taskset -c "${CPUS[$seat]}" "$@" & jobpid=$!
      memlimit=$(( ${MEM_GB:-20} * 1048576 ))
      ( while kill -0 $jobpid 2>/dev/null; do
          tot=0; for c in $(pgrep -g $(ps -o pgid= -p $jobpid 2>/dev/null | tr -d ' ') 2>/dev/null); do r=$(awk '/VmRSS/ {print $2}' /proc/$c/status 2>/dev/null); tot=$((tot + ${r:-0})); done
          if [ "$tot" -gt "$memlimit" ]; then echo "seat $seat MEMORY ALLOWANCE $(date +%T): $((tot/1048576)) GB > ${MEM_GB:-20} GB, killing :: $cmdstr" >> "$S/seat_log.txt"; pkill -KILL -g $(ps -o pgid= -p $jobpid | tr -d ' ') 2>/dev/null; break; fi
          sleep 5; done ) & memwatch=$!
      wait $jobpid; code=$?; kill $memwatch 2>/dev/null; wait $memwatch 2>/dev/null
      grep -q "MEMORY ALLOWANCE $(date +%H)" "$S/seat_log.txt" 2>/dev/null && [ "$code" = 137 ] && code=138
      release $code
      flock -u $fd; exec {fd}>&-
      exit $code
    fi
    exec {fd}>&-
  done
  sleep 10
done
