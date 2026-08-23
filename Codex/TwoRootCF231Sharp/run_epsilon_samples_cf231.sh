#!/usr/bin/env bash
set -euo pipefail

root="/home/maxzhang/factorization-and-loops"
work="$root/Codex/TwoRootCF231Sharp"
prime="${FACET_PRIME:-2147483647}"
parallel_jobs="${FACET_PARALLEL_JOBS:-1}"
master_lock="${FACET_CF231_MASTER_LOCK:-/tmp/facet_cf231_wolfram_master.lock}"
sample_limit="${FACET_SAMPLE_LIMIT:-0}"

epsilon_values=(
  1/2 1/3 1/5 1/6 1/7 2/7 3/8 4/9 5/9 6/11
  7/12 8/13 9/19 2/5 3/5 4/7 5/8 7/9 8/11 9/13
  1/11 1/13 3/13 5/13 7/13 9/17 11/19 13/23 15/29 17/31
  19/37 21/41 23/43 25/47 27/49 29/53 31/59 33/61 35/67 37/71
)

if (( sample_limit > 0 )); then
  epsilon_values=("${epsilon_values[@]:0:sample_limit}")
fi

run_one() {
  set -euo pipefail
  local epsilon="$1"
  local tag="${epsilon//\//_}"
  local output="$work/CF231_8_7_gauge_sample_${tag}_p${prime}.wl"
  local log="$work/epsilon_${tag}_p${prime}.log"

  if [[ -s "$output" ]] && grep -q 'ParticularSolution' "$output"; then
    printf 'already complete: epsilon=%s\n' "$epsilon"
    return 0
  fi

  printf 'starting: epsilon=%s\n' "$epsilon"
  cd "$root"
  flock "$master_lock" \
    timeout --signal=TERM --kill-after=30s 300s \
      env FACET_EPSILON="$epsilon" FACET_PRIME="$prime" \
        FACET_POINT_COUNT=45 FACET_SOLVE_AFFINE=True \
      wolframscript -file \
        Codex/TwoRootCF231Sharp/sample_gauge_cf231.wls >"$log" 2>&1
  if [[ ! -s "$output" ]] || ! grep -q 'ParticularSolution' "$output"; then
    printf 'failed: epsilon=%s (see %s)\n' "$epsilon" "$log" >&2
    return 1
  fi
  printf 'finished: epsilon=%s\n' "$epsilon"
}

export root work prime master_lock
export -f run_one
printf '%s\n' "${epsilon_values[@]}" |
  xargs -P "$parallel_jobs" -I '{}' bash -lc 'run_one "$1"' _ '{}'
