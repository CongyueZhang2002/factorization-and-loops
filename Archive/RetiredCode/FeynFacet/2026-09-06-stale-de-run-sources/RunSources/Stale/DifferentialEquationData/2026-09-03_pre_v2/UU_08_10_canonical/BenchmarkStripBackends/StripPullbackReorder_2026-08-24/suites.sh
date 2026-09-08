#!/bin/bash
# The suites that touch the strip-pullback path, one kernel at a time,
# taskset -c 10-17, with the jittered 60-180 s licence backoff of
# CLAUDE.md.  Per-suite wall time and exit code go to suites_result.tsv.
set -u
S=/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/strip_pullback_perf
R=/home/maxzhang/factorization-and-loops
OUT="$S/suites"
mkdir -p "$OUT"
RES="$S/suites_result.tsv"
: > "$RES"
SUITES="${SUITES:-t_transport_chart_extension t_multiquadratic_dispatch t_multiquadratic_strip_solve t_eps_form_strip t_kallen_q4_chart t_radical_denesting t_chart_transport}"
for name in $SUITES; do
  log="$OUT/$name.log"
  start=$(date +%s)
  code=99
  for attempt in $(seq 1 60); do
    ( cd "$R" && timeout 7200 taskset -c 10-17 wolframscript -file "Tests/$name.wls" ) > "$log" 2>&1
    code=$?
    if grep -qi "not activated\|license-related" "$log"; then
      back=$((60 + RANDOM % 120))
      echo "[suites $(date -Is)] $name licence refused (attempt $attempt), sleeping ${back}s" >> "$S/suites.log"
      sleep $back
      continue
    fi
    break
  done
  end=$(date +%s)
  printf '%s\t%s\t%s\n' "$name" "$code" "$((end-start))" >> "$RES"
  echo "[suites $(date -Is)] $name exit=$code wall=$((end-start))s" >> "$S/suites.log"
done
echo "[suites $(date -Is)] ALL SUITES DONE" >> "$S/suites.log"
