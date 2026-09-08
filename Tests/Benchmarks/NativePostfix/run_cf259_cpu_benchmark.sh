#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
runtime=/home/maxzhang/factorization-and-loops-codex/Runtime/2026-09-01_observable_transport_triple_final/cf259_dlog_gpu
payload="$here/.cf259_cpu_payload.bin"
binary="$here/.cf259_cpu_postfix_benchmark"
results="$here/cf259_cpu_postfix_benchmark.jsonl"
g++ -std=c++17 -O3 -march=native -fopenmp "$here/cf259_cpu_postfix_benchmark.cpp" -o "$binary"
python3 "$here/export_cf259_cpu_benchmark.py" "$runtime/programs.pkl" "$runtime/sidecar.wl" "$payload" | tee "$results"
OMP_DYNAMIC=false OMP_PROC_BIND=close OMP_PLACES=cores \
  taskset -c 0-15 "$binary" "$payload" 1,2,4,8,16 5 "$here/.cf259_cpu_last_output.bin" | tee -a "$results"
