#!/usr/bin/env bash
set -euo pipefail

if (( $# != 1 )); then
  echo "usage: launch_cf300_pair_chart_pool_2026-08-24.sh <pool-dir>" >&2
  exit 64
fi
pool="$1"
root=/home/maxzhang/factorization-and-loops
mkdir -p "$pool"
if [[ -f "$pool/pool.pid" ]] && kill -0 "$(<"$pool/pool.pid")" 2>/dev/null; then
  echo "pool already active: $pool" >&2
  exit 73
fi

export FACET_TASK_BROKER="$pool"
export FACET_KERNEL_COUNT=1
export FACET_CHECK_LEVEL=Development
export FACET_CPU_LIST=0,1,6,7,8,9,18,19
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export FLINT_NUM_THREADS=1

exec taskset -c 0,1,6,7,8,9,18,19 \
  wolframscript -file "$root/Scripts/KernelPool.wls" "$pool" 8 True \
  > "$pool/pool.log" 2>&1
