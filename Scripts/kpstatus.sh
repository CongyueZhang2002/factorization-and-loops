#!/usr/bin/env bash
POOL="${POOL:-${FACET_SCRATCHPAD:+$FACET_SCRATCHPAD/kernelpool}}"; [[ -z "$POOL" ]] && { echo "kpstatus: set POOL=<pooldir> (or FACET_SCRATCHPAD)" >&2; exit 64; }
cat "$POOL/status.txt" 2>/dev/null || echo "no status (pool not running?)"
