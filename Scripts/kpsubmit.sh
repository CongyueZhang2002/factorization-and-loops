#!/usr/bin/env bash
# Submit a Wolfram script as a mission to the running KernelPool.
# Usage: kpsubmit.sh <name> <script.wls|.wl> [args...]     (args -> $ScriptCommandLine inside the mission)
#        POOL=<pooldir> to override the pool directory.
# The mission runs on a free subkernel via Get; its Print/Message output goes to <pool>/logs/<name>.log;
# on completion <pool>/done/<name>.status (or failed/) holds the result record.
set -u
POOL="${POOL:-/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/kernelpool}"
name="$1"; script="$(readlink -f "$2")"; shift 2
[ -f "$POOL/pool.pid" ] && kill -0 "$(cat "$POOL/pool.pid")" 2>/dev/null || { echo "kpsubmit: pool not running at $POOL" >&2; exit 2; }
argl="\"$script\""; for a in "$@"; do argl="$argl, \"$a\""; done
tmp="$POOL/queue/.$name.wl.tmp"
cat > "$tmp" <<WL
(* mission $name: $script $* *)
Module[{res},
  Unprotect[\$ScriptCommandLine]; \$ScriptCommandLine = {$argl};
  SetDirectory["$(dirname "$script")"];
  res = Get["$script"];
  res]
WL
mv "$tmp" "$POOL/queue/$name.wl"
echo "queued $name -> $POOL/queue/$name.wl ; log $POOL/logs/$name.log ; wait: kpwait.sh $name"
