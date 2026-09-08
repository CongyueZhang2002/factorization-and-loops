#!/bin/bash
# Queue CF123 at kmax=2 (8h guard, verbose) AFTER:
#   1. our own CF269/CF263 kmax=1 run finishes, and
#   2. a 30-minute COURTESY WINDOW in which we deliberately do not claim the
#      seat, so the hard-class toolkit agent's two short CANONICA runs
#      (class 97 and 77, minutes each) can take it, and
#   3. normal seat discipline: no wolframscript of ANY owner is running.
# Ownership is classified by /proc/<pid>/cwd -- never by timing or by name.
cd /tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine || exit 1
MINE="/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine"
LOG=queue_cf123_k2.log

say () { echo "[$(date -Is)] $*" | tee -a "$LOG"; }

mine_running () {
  for p in $(pgrep -x wolframscript 2>/dev/null); do
    [ "$(readlink /proc/$p/cwd 2>/dev/null)" = "$MINE" ] && return 0
  done
  return 1
}
any_running () { [ -n "$(pgrep -x wolframscript 2>/dev/null)" ]; }

say "queue armed: waiting for our CF269/CF263 kmax=1 run to finish"
while mine_running; do sleep 30; done
say "our runs are done"

say "COURTESY WINDOW: 30 min, seat deliberately left free for the toolkit agent"
sleep 1800
say "courtesy window over"

if any_running; then
  say "seat taken (expected: toolkit agent) -- waiting for it to clear"
fi
while any_running; do sleep 30; done
say "seat clear -- claiming it for CF123 kmax=2"

# preserve the kmax=1 record; the script treats an existing CF123.wl as cached
if [ -f stragglers_gpl/CF123.wl ]; then
  cp stragglers_gpl/CF123.wl stragglers_gpl/CF123_kmax1_result.wl
  rm -f stragglers_gpl/CF123.wl
  say "kmax=1 record preserved as stragglers_gpl/CF123_kmax1_result.wl"
fi

say "launching CF123 kmax=2, guard 28800s (8h), verbose"
wolframscript -f stragglers_gpl.wls CF123 2 28800 > cf123_k2.log 2>&1
rc=$?
say "CF123 kmax=2 finished rc=$rc"
tail -5 cf123_k2.log | tee -a "$LOG"
