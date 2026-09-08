#!/bin/bash
# CF259 observable transport probe from the overhaul worktree (goal 11), standalone main on E-cores.
# Usage: run_cf259_transport.sh ALLOWANCE_SECONDS OUTPUT_TAG   (CARD=<card.wl> overrides the transport card)
# On a licence refusal (a third main kernel) the launch is retried after a jittered 60-180 s pause, up to 20 times.
ALLOWANCE=$1; TAG=$2
OUT=/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad/bench/cf259_$TAG
mkdir -p $OUT
cd /tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad/work
export FACET_CHECK_LEVEL=Production FACET_KERNEL_COUNT=1
CARD="${CARD:-/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF259/transport_inputs_2026-09-02/cf259_transport_card.wl}"
for attempt in $(seq 1 20); do
  echo "=== attempt $attempt $(date -Is) card $CARD" >> $OUT/transport.log
  CORES=2,3,4,5,10,11,12,13 /home/maxzhang/factorization-and-loops/Scripts/run_with_allowance.sh $ALLOWANCE $OUT/transport.log Scripts/family_observable_transport.wls /home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF259/transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl /home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquations/nnlo_de_CF259.wl /home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/MasterCoefficientValuations.wl $OUT/observable_transport_CF259.wl "$CARD"
  if tail -c 2000 $OUT/transport.log | grep -a -q "not activated or is experiencing a license"; then
    echo "licence refusal; retrying after pause" >> $OUT/transport.log; sleep $((60 + RANDOM % 120)); continue
  fi
  break
done
