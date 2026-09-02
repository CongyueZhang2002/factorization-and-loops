#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
runtime="$repo/Runtime/2026-09-01_observable_transport_triple_final/cf259_dlog_gpu"
threads=${THREADS:-8}
cpuset=${CPUSET:-2-9}
build=$(mktemp -d -t postfix-native-build.XXXXXX)
trap 'rm -f -- "$build/libpostfix_native.so"; rmdir -- "$build"' EXIT

g++ -std=c++17 -O3 -march=native -fopenmp -fPIC -shared \
  -Wall -Wextra -Werror "$here/postfix_native.cpp" -o "$build/libpostfix_native.so"

OMP_DYNAMIC=false OMP_PROC_BIND=close OMP_PLACES=cores \
  taskset -c "$cpuset" python3 "$here/family_dlog_native.py" \
  "$runtime/sidecar.wl" "$here/cf259_dlog_residues_native.wl" \
  --cache "$runtime/programs.pkl" \
  --reference "$runtime/dlog_residues_CF259.wl" \
  --native-library "$build/libpostfix_native.so" \
  --rref "$repo/FeynFacet/Backends/flint/bin/flint_affine_rref" \
  --solve "$repo/FeynFacet/Backends/flint/bin/flint_modular_solve" \
  --threads "$threads" --flint-threads 4 --crt-primes 13 --max-primes 14 \
  | tee "$here/cf259_native_dlog_run.jsonl"
