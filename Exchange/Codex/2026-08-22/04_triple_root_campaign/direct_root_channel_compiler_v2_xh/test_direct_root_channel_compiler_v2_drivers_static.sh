#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
files=(
  "$root/DirectRootChannelCompilerV2.wl"
  "$root/run_direct_root_channel_compiler_v2_adversarial.wls"
  "$root/run_cf300_sector12_compiler_v2_benchmark.wls"
)

python3 - "${files[@]}" <<'PY'
import pathlib
import sys

pairs = {")": "(", "]": "[", "}": "{"}
for raw_path in sys.argv[1:]:
    path = pathlib.Path(raw_path)
    text = path.read_text(encoding="utf-8")
    stack = []
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
                    f"FAIL {path.name}: mismatch {char} at line {line}; "
                    f"stack={stack[-3:]}"
                )
            stack.pop()
        index += 1
    if stack or in_string or comment_depth:
        raise SystemExit(
            f"FAIL {path.name}: unterminated stack={stack[-5:]}, "
            f"string={in_string}, comment={comment_depth}"
        )
    print(f"PASS {path.name}: balanced syntax")
PY

for driver in "${files[@]:1}"; do
  if grep -Fq 'LaunchKernels[' "$driver" || \
      grep -Fq 'CloseKernels[' "$driver" || \
      grep -Fq 'KillProcess[' "$driver"; then
    printf 'FAIL %s launches/stops kernels or processes\n' "$driver" >&2
    exit 1
  fi
  if ! grep -Fq 'sourceHashes[]' "$driver" || \
      ! grep -Fq 'FileExistsQ[outputFile]' "$driver" || \
      ! grep -Fq 'OverwriteTarget -> False' "$driver"; then
    printf 'FAIL %s lacks source/fresh-output guard\n' "$driver" >&2
    exit 1
  fi
  printf 'PASS %s: managed-run guards\n' "$(basename "$driver")"
done

adversarial="$root/run_direct_root_channel_compiler_v2_adversarial.wls"
benchmark="$root/run_cf300_sector12_compiler_v2_benchmark.wls"
grep -Fq 'rank, 0, 3' "$adversarial"
grep -Fq 'recursive-norm-zero-divisor-fails-closed' "$adversarial"
grep -Fq 'polynomial-pool-corruption-rejected' "$adversarial"
grep -Fq 'one-form-prefix-extension-compiles-only-suffix-and-is-exact' \
  "$adversarial"
grep -Fq 'ExactV1AssemblyEqual' "$benchmark"
grep -Fq 'LegacyOverV2Speedup' "$benchmark"
grep -Fq 'SupportRebindExact' "$benchmark"

if grep -Fn 'CodexDirectRootCompilerV2`' \
    "$root/DirectRootChannelCompilerV2.wl" \
    "$adversarial" "$benchmark"; then
  printf 'FAIL stale/misspelled compiler context\n' >&2
  exit 1
fi

printf 'PASS static managed-driver contract\n'
