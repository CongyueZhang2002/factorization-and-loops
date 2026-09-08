#!/usr/bin/env bash
# Launch the stage-2 transport sweep: one pool mission per family.
# Usage: sweep_launch.sh <outdir> [maxWeight] [timeConstraintSeconds] [CF1,CF2,... | ALL | FILE] [safety=1]
# Families default to ALL (every DifferentialEquations/nnlo_de_CF*.wl); a
# family whose <outdir>/<CF>.status already says Transported is skipped
# (resumable). Missions are named sw_<CF>; logs in the pool's logs/ dir.
set -u
cd "$(dirname "$0")/.."
OUT="$1"; MAXW="${2:-10}"; TC="${3:-2400}"; SEL="${4-ALL}"; SAFETY="${5:-1}"; [ -z "$SEL" ] && { echo "empty selection: nothing to submit"; exit 0; }
mkdir -p "$OUT"
if [ "$SEL" = ALL ]; then
  FAMS=$(ls ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquations/ | grep -oE "nnlo_de_CF[0-9]+" | sed 's/nnlo_de_//' | sort -V)
elif [ -f "$SEL" ]; then FAMS=$(cat "$SEL"); else FAMS=$(echo "$SEL" | tr ',' ' '); fi
n=0
for f in $FAMS; do
  if [ -f "$OUT/$f.status" ] && grep -q " Transported " "$OUT/$f.status"; then continue; fi
  if Scripts/kpsubmit.sh "sw_$f" "$(pwd)/Scripts/sweep_transport.wls" "$f" "$OUT" "$MAXW" "$TC" "$SAFETY" >/dev/null; then
    n=$((n+1))
    # PRIORITY=1: the pool dispatches by file date; give the sweep an older mtime so it runs first.
    # ONLY after a successful submit (a touch on a missing file would create an EMPTY mission,
    # which the pool runs in 0 s as "done" -- measured 2026-08-17 02:26).
    if [ "${PRIORITY:-0}" = 1 ]; then
      POOL="${POOL:-/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/kernelpool}"
      [ -s "$POOL/queue/sw_$f.wl" ] && touch -d "2026-08-17 00:00:00" "$POOL/queue/sw_$f.wl" 2>/dev/null
    fi
  else
    echo "submit failed: $f"
  fi
done
echo "submitted $n missions -> $OUT (maxWeight $MAXW, timeConstraint $TC s)"
