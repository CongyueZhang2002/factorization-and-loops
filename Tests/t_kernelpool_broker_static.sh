#!/usr/bin/env bash
# Static broker invariants only: never launches or contacts a Wolfram kernel.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
server="$root/Scripts/KernelPool.wls"
failures=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

assert_contains() {
  local description="$1" needle="$2"
  if grep -Fq -- "$needle" "$server"; then pass "$description"; else fail "$description"; fi
}

assert_absent() {
  local description="$1" needle="$2"
  if grep -Fq -- "$needle" "$server"; then fail "$description"; else pass "$description"; fi
}

assert_contains "subkernel wrapper receives an attempt token" \
  'poolRun[file_String, logFile_String, kernelFile_String, attempt_String]'
assert_contains "WSTP completion is compact metadata" \
  'allowedEnvelopeKeys = {"Mission", "Attempt", "Status", "HadMessages", "Wall", "Kernel"}'
assert_contains "crash sidecar is installed atomically" \
  'RenameFile[tmp, kernelFile <> ".result", OverwriteTarget -> True]'
assert_contains "mission-provided exit data cannot inflate the envelope" \
  'IntegerQ[exitCode] && Abs[exitCode] <= 999999999'
assert_contains "claim ownership is an atomic directory creation" \
  'claimWon = Quiet[Check[CreateDirectory[claim]; True, False]]'
assert_contains "kernel-loss cleanup supports directory claims" \
  'DeleteDirectory[claim, DeleteContents -> True]'
assert_absent "mission result body is never put in a broker record" '"Result" ->'
assert_absent "mission result body is never shortened for WSTP" 'Short[r]'
assert_contains "mission result is released before envelope construction" \
  'r =.; exitCode =.;   (* release mission values before constructing the WSTP envelope *)'
assert_absent "broker never blocks on WaitAll" 'WaitAll['
assert_contains "all outstanding EvaluationObjects have a registry" 'poolEIDs = {}'
assert_contains "resubmission appends rather than replaces EIDs" \
  '"EIDs" -> Append[Lookup[j, "EIDs", {}], eid]'
assert_contains "completion dequeues the exact EID with WaitNext" 'WaitNext[eids]'
assert_contains "dequeue is gated on the public received state" \
  'rec["EID"]["State"] === "received"'
assert_contains "attempt metadata is bound into ParallelSubmit" \
  'ParallelSubmit[poolRun[missionFile, missionLog, kernelFile,'
assert_contains "kernel-loss requeues preserve logical generation" \
  'requeueGenerations[name] = poolJobs[name]["Generation"]'
assert_contains "duplicate attempts wait for another tracked attempt" \
  'MemberQ[{"DUPLICATE", "FILEGONE"}, status] && more'
assert_contains "graceful stop drains EvaluationObjects" \
  'Length[poolJobs] == 0 && Length[poolEIDs] == 0'

qualified_count="$(grep -Fc 'Parallel`Developer`QueueRun[]' "$server")"
if (( qualified_count >= 2 )); then
  pass "scheduler is pumped before collection and after refill"
else
  fail "scheduler is pumped before collection and after refill"
fi
if grep -Eq '^[[:space:]]*QueueRun\[\]' "$server"; then
  fail "QueueRun is always fully qualified"
else
  pass "QueueRun is always fully qualified"
fi

sidecar_line="$(grep -nF 'RenameFile[tmp, kernelFile <> ".result", OverwriteTarget -> True]' "$server" | head -1 | cut -d: -f1)"
marker_line="$(grep -nF 'Export[kernelFile <> ".done", "done", "Text"]' "$server" | head -1 | cut -d: -f1)"
if [[ -n "$sidecar_line" && -n "$marker_line" ]] && (( sidecar_line < marker_line )); then
  pass "compact crash sidecar precedes completion marker"
else
  fail "compact crash sidecar precedes completion marker"
fi

# Lightweight lexical balance check. It understands nested Wolfram comments
# and escaped string characters; it is intentionally not an evaluator/parser.
if python3 - "$server" <<'PY'
import pathlib
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
opening = {"(": ")", "[": "]", "{": "}"}
closing = {v: k for k, v in opening.items()}
stack = []
i = 0
comment_depth = 0
in_string = False
while i < len(text):
    pair = text[i:i + 2]
    ch = text[i]
    if comment_depth:
        if pair == "(*":
            comment_depth += 1
            i += 2
            continue
        if pair == "*)":
            comment_depth -= 1
            i += 2
            continue
        i += 1
        continue
    if in_string:
        if ch == "\\":
            i += 2
            continue
        if ch == '"':
            in_string = False
        i += 1
        continue
    if pair == "(*":
        comment_depth = 1
        i += 2
        continue
    if ch == '"':
        in_string = True
        i += 1
        continue
    if ch in opening:
        stack.append((ch, i))
    elif ch in closing:
        if not stack or stack[-1][0] != closing[ch]:
            raise SystemExit(f"unmatched {ch!r} at byte {i}")
        stack.pop()
    i += 1
if comment_depth or in_string or stack:
    raise SystemExit(
        f"unterminated lexical construct: comment={comment_depth}, "
        f"string={in_string}, stack={stack[-3:]}"
    )
PY
then
  pass "Wolfram delimiters/comments/strings are balanced"
else
  fail "Wolfram delimiters/comments/strings are balanced"
fi

if (( failures > 0 )); then
  printf '%s broker static assertions failed\n' "$failures"
  exit 1
fi
printf 'kernel-pool broker static assertions: 0 failed\n'
