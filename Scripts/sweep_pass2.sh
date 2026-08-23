#!/usr/bin/env bash
# Stage-2 sweep, pass 2a: for every family whose first-pass status is Failed
# with TimedOut or PathDenominatorsNotLinear, submit the family eps-form driver
# (guarded M2, catalog chart) so that pass 2b (sweep_launch.sh on the same
# outdir; Transported families are skipped) can take route 2.
# Usage: sweep_pass2.sh <sweep outdir> [FamilyEpsForms dir]
set -u
cd "$(dirname "$0")/.."
OUT="$1"; FE="${2:-$(pwd)/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsForms}"
n=0
for s in "$OUT"/*.status; do
  [ -f "$s" ] || continue
  f=$(basename "$s" .status)
  if grep -qE " Failed .*(TimedOut|PathDenominatorsNotLinear)" "$s"; then
    Scripts/kpsubmit.sh "fe2_$f" "$(pwd)/Scripts/family_epsform.wls" "$f" auto "$FE" >/dev/null && n=$((n+1))
  fi
done
echo "pass 2a: submitted $n family_epsform missions (fe2_<CF>); when they finish run: Scripts/sweep_launch.sh $OUT 10 3600 ALL"
