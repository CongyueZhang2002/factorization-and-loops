#!/usr/bin/env bash
# Register a background output for the standing watchdog (Design/Watchdog.md).
# Usage: watchdog_register.sh <output_file> <label> [stall_minutes=30]
# The watchlist lives in the session scratchpad: $WATCHDOG_DIR or
# <scratchpad>/watchdog (FACET_SCRATCHPAD must then be set).
set -u
f="$1"; label="$2"; stall="${3:-30}"
dir="${WATCHDOG_DIR:-${FACET_SCRATCHPAD:?set WATCHDOG_DIR or FACET_SCRATCHPAD}/watchdog}"
mkdir -p "$dir"
[[ -f "$dir/watchlist.tsv" ]] || printf 'output_file\tlabel\tstall_minutes\n' > "$dir/watchlist.tsv"
printf '%s\t%s\t%s\n' "$(readlink -f "$f" 2>/dev/null || echo "$f")" "$label" "$stall" >> "$dir/watchlist.tsv"
echo "registered $label -> $dir/watchlist.tsv"
