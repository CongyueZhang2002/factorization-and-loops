#!/usr/bin/env bash
# Summarize a sweep output directory: per-family one-line status + totals.
# Usage: sweep_status.sh <outdir>
OUT="$1"
tot=0; ok=0; fail=0
for s in "$OUT"/*.status; do [ -f "$s" ] || continue; tot=$((tot+1)); if grep -q " Transported " "$s"; then ok=$((ok+1)); else fail=$((fail+1)); fi; done
echo "families with status: $tot   transported: $ok   not: $fail"
[ "$fail" -gt 0 ] && { echo "--- not transported ---"; grep -L " Transported " "$OUT"/*.status 2>/dev/null | xargs -r cat; }
echo "--- transported (family status wall note) ---"; grep -l " Transported " "$OUT"/*.status 2>/dev/null | xargs -r cat | sort -V
