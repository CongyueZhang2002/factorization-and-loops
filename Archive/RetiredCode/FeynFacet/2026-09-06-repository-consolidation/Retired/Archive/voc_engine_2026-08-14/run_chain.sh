#!/bin/bash
# Waits for the hardclasses.wls seat holder to exit, then runs the VoC
# engine scripts strictly one at a time (never two wolframscripts of ours).
cd /tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine
while pgrep -f "hardclasses.wls" >/dev/null; do sleep 20; done
echo "SEAT FREE $(date)" > chain.log
run() {
  echo "=== $1 START $(date) ===" >> chain.log
  timeout "$2" wolframscript -f "$1" > "${1%.wls}.log" 2>&1
  echo "=== $1 EXIT $? $(date) ===" >> chain.log
}
run smoke.wls 900
run nlo_gate.wls 2400
run cf3_gate.wls 2400
echo "CHAIN DONE $(date)" >> chain.log
run stragglers.wls 2400
run sweep.wls 1800
echo "CHAIN2 DONE $(date)" >> chain.log
