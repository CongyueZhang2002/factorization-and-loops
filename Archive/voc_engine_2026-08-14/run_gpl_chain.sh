#!/bin/bash
# Sequential GPL-layer chain.  Kernel discipline: before EVERY wolframscript
# invocation, wait until no foreign wolframscript is running; never more than
# one of our own at a time; never kill anything.
cd /tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine

wait_seat () {
  local n=0
  while true; do
    if [ -z "$(pgrep -x wolframscript)" ]; then return 0; fi
    n=$((n+1))
    if [ $((n % 10)) -eq 1 ]; then
      echo "[$(date -Is)] seat busy: $(pgrep -x wolframscript | tr '\n' ' ')" | tee -a chain_gpl.log
    fi
    sleep 20
  done
}

run_step () {   # $1 = script, $2 = log, $3.. = args
  local script="$1"; shift
  local log="$1"; shift
  wait_seat
  echo "[$(date -Is)] === START $script $* ===" | tee -a chain_gpl.log
  wolframscript -f "$script" "$@" 2>&1 | tee -a "$log"
  local rc=${PIPESTATUS[0]}
  echo "[$(date -Is)] === END $script rc=$rc ===" | tee -a chain_gpl.log
  return $rc
}

STEP="${1:-all}"

if [ "$STEP" = "all" ] || [ "$STEP" = "selftest" ]; then
  run_step gpl_selftest.wls gpl_selftest.log
  if ! grep -q "SELF-TEST SUMMARY" gpl_selftest.log; then
    echo "[$(date -Is)] self-test did not finish -- stopping chain" | tee -a chain_gpl.log
    exit 1
  fi
  if ! tail -20 gpl_selftest.log | grep -q "0 failed"; then
    echo "[$(date -Is)] self-test reported failures -- CONTINUING anyway:" | tee -a chain_gpl.log
    echo "[$(date -Is)] the symbolic gates (CF3, stragglers) do not use the" | tee -a chain_gpl.log
    echo "[$(date -Is)] numeric evaluator at all, and the NLO symbolic solve" | tee -a chain_gpl.log
    echo "[$(date -Is)] + exact DE check are meaningful regardless." | tee -a chain_gpl.log
    grep "FAILED:" gpl_selftest.log | tail -1 | tee -a chain_gpl.log
  else
    echo "[$(date -Is)] self-test clean" | tee -a chain_gpl.log
  fi
  [ "$STEP" = "selftest" ] && exit 0
fi

if [ "$STEP" = "all" ] || [ "$STEP" = "gates" ]; then
  run_step nlo_gate_gpl.wls nlo_gate_gpl.log
  run_step cf3_gate_gpl.wls cf3_gate_gpl.log
  [ "$STEP" = "gates" ] && exit 0
fi

if [ "$STEP" = "all" ] || [ "$STEP" = "stragglers" ]; then
  run_step stragglers_gpl.wls stragglers_gpl.log "CF360,CF123,CF269,CF263" 2 900
fi

echo "[$(date -Is)] chain finished" | tee -a chain_gpl.log
