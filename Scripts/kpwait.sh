#!/usr/bin/env bash
# Wait for a mission to finish; print its status record. Usage: kpwait.sh <name> [timeout_s]
set -u
POOL="${POOL:-${FACET_SCRATCHPAD:+$FACET_SCRATCHPAD/kernelpool}}"; [[ -z "$POOL" ]] && { echo "kpwait: set POOL=<pooldir> (or FACET_SCRATCHPAD)" >&2; exit 64; }
name="$1"; to="${2:-86400}"; t0=$(date +%s)
while true; do
  for d in done failed; do [ -f "$POOL/$d/$name.status" ] && { echo "$d:"; cat "$POOL/$d/$name.status"; echo; exit $([ "$d" = done ] && echo 0 || echo 1); }; done
  [ $(( $(date +%s) - t0 )) -ge "$to" ] && { echo "kpwait: timeout waiting for $name" >&2; exit 3; }
  sleep 5
done
