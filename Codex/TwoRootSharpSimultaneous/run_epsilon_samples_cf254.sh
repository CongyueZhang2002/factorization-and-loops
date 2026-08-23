#!/usr/bin/env bash
set -euo pipefail

cd /home/maxzhang/factorization-and-loops

prime="${FACET_PRIME:-1000003}"
sample_start="${FACET_SAMPLE_START:-1}"
sample_end="${FACET_SAMPLE_END:-32}"
point_count="${FACET_POINT_COUNT:-64}"

for k in $(seq "${sample_start}" "${sample_end}"); do
  epsilon_value="${k}/$((k + 20))"
  log_path="Codex/TwoRootSharpSimultaneous/epsilon_sample_${k}_p${prime}.log"
  echo "BEGIN ${epsilon_value} modulo ${prime}"
  timeout --signal=TERM --kill-after=30s 300s \
    env FACET_EPSILON="${epsilon_value}" \
      FACET_PRIME="${prime}" \
      FACET_POINT_COUNT="${point_count}" \
      FACET_SOLVE_AFFINE=True \
    wolframscript -file \
      Codex/TwoRootSharpSimultaneous/sample_rank_by_points_cf254.wls \
      > "${log_path}" 2>&1
  tail -n 1 "${log_path}"
done
