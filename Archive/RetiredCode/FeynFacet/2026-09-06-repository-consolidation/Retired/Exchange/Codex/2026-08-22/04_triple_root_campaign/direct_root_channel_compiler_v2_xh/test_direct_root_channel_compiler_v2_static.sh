#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_file="$root/DirectRootChannelCompilerV2.wl"

python3 - "$source_file" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
stack = []
pairs = {")": "(", "]": "[", "}": "{"}
line = 1
index = 0
in_string = False
escaped = False
comment_depth = 0
while index < len(text):
    char = text[index]
    nxt = text[index + 1] if index + 1 < len(text) else ""
    if char == "\n":
        line += 1
    if comment_depth:
        if char == "(" and nxt == "*":
            comment_depth += 1
            index += 2
            continue
        if char == "*" and nxt == ")":
            comment_depth -= 1
            index += 2
            continue
        index += 1
        continue
    if in_string:
        if escaped:
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == '"':
            in_string = False
        index += 1
        continue
    if char == "(" and nxt == "*":
        comment_depth = 1
        index += 2
        continue
    if char == '"':
        in_string = True
        index += 1
        continue
    if char in "([{":
        stack.append((char, line))
    elif char in ")]}":
        if not stack or stack[-1][0] != pairs[char]:
            raise SystemExit(
                f"FAIL delimiter mismatch at line {line}: {char}, "
                f"stack={stack[-3:]}"
            )
        stack.pop()
    index += 1
if stack or in_string or comment_depth:
    raise SystemExit(
        f"FAIL unterminated syntax: stack={stack[-5:]}, "
        f"string={in_string}, comment_depth={comment_depth}"
    )
print("PASS balanced Wolfram delimiters and comments")
PY

require_literal() {
  local literal="$1"
  local label="$2"
  if grep -Fq -- "$literal" "$source_file"; then
    printf 'PASS %s\n' "$label"
  else
    printf 'FAIL %s\n' "$label" >&2
    exit 1
  fi
}

reject_literal() {
  local literal="$1"
  local label="$2"
  if grep -Fq -- "$literal" "$source_file"; then
    printf 'FAIL %s\n' "$label" >&2
    exit 1
  else
    printf 'PASS %s\n' "$label"
  fi
}

require_literal '"PreparedDirectRootChannelCoreV2"' 'versioned core status'
require_literal '"PreparedDirectRootChannelsV2"' 'versioned assembly status'
require_literal '"PreparedDirectRootChannelsV1"' 'explicit V1 adapter status'
require_literal '"RootFreeFastPathCount"' 'root-free telemetry'
require_literal '"RecursiveMultiquadraticNorm"' 'recursive norm path'
require_literal '"IndependentInverseChecks"' 'independent inverse checks'
require_literal '"IndependentRoundTripChecks"' 'independent round-trip checks'
require_literal '"ScalarPoolHits"' 'scalar pooling telemetry'
require_literal '"PolynomialPoolHitsThisBundle"' 'polynomial pooling telemetry'
require_literal '"SupportOrNormalizationOnly"' 'compile-free support rebind'
require_literal '"OneFormPrefixExtension"' 'append-only one-form compilation'
require_literal 'DRCAAssemblyPreparationValidQ' 'public V1 boundary validation'
require_literal '$drcav2V1SourceSHA256' 'V1 source binding'
require_literal '$drcav2SourceSHA256' 'V2 source binding'
reject_literal 'LinearSolve[' 'no dense symbolic LinearSolve'
reject_literal 'TRFieldDecompose[' 'no generic field decomposition call'
reject_literal 'LaunchKernels[' 'prototype never launches kernels'
reject_literal 'ParallelSubmit[' 'prototype has no hidden parallel launch'
reject_literal 'KillProcess[' 'prototype never signals processes'

begin_count="$(grep -Fc 'Begin[' "$source_file")"
end_count="$(grep -Fc 'End[];' "$source_file")"
if [[ "$begin_count" == "$end_count" ]]; then
  printf 'PASS Begin/End count (%s)\n' "$begin_count"
else
  printf 'FAIL Begin/End count: Begin=%s End=%s\n' \
    "$begin_count" "$end_count" >&2
  exit 1
fi

printf 'PASS static compiler V2 contract\n'
