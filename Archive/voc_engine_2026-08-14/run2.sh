#!/bin/bash
# Stage 2: waits for the first NLO gate run to end (it has its own 2400s
# deadline), then runs the remaining scripts strictly one at a time.
cd /tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine
while pgrep -f "nlo_gat[e].wls" >/dev/null; do sleep 15; done
cp -f nlo_gate.log nlo_gate_run1.log 2>/dev/null
echo "=== STAGE2 START $(date) ===" >> chain2.log
run() {
  echo "=== $1 START $(date) ===" >> chain2.log
  timeout "$2" wolframscript -f "$1" > "${1%.wls}.log" 2>&1
  echo "=== $1 EXIT $? $(date) ===" >> chain2.log
}
run nlo_gate2.wls 600
run nlo_gate.wls 1500
run cf3_gate.wls 1500
run stragglers.wls 1500
echo "=== STAGE2 DONE $(date) ===" >> chain2.log
run smoke.wls 900
run sweep.wls 1200
echo "=== STAGE2 ALLDONE $(date) ===" >> chain2.log
