#!/usr/bin/env bash
# Focused regression batch for the read-only resume hydration integration.
# It uses only the existing KernelPool and never starts/stops a main kernel.
set -euo pipefail

repo=/home/maxzhang/factorization-and-loops
pool=/tmp/codex-triple-root-20260823c.vx654S/pool
prefix=fresh_resume_regression_xh

cd "$repo"
git diff --check -- \
  FeynFacet/FeynFacet.m \
  FeynFacet/Private/FamilyRowGaugeResume.wl \
  FeynFacet/Private/FamilyRowGauge.wl \
  Scripts/family_epsform_sector.wls \
  Tests/t_family_row_gauge_resume.wls \
  Tests/t_family_row_gauge.wls \
  Tests/t_task_broker_limit.wls \
  Tests/t_multiquadratic_transport_frame.wls \
  Tests/t_family_row_gauge_finite_field.wls
bash -n Scripts/kpsubmit.sh Scripts/kpwait.sh Scripts/run_tests_pool.sh

tests=(
  t_family_row_gauge_resume
  t_family_row_gauge
  t_task_broker_limit
  t_multiquadratic_transport_frame
  t_family_row_gauge_finite_field
)

for test_name in "${tests[@]}"; do
  mission="${prefix}_${test_name#t_}"
  POOL="$pool" FACET_TASK_BROKER_MAX_HELPERS=0 \
    Scripts/kpsubmit.sh "$mission" "Tests/$test_name.wls"
done

failed=0
for test_name in "${tests[@]}"; do
  mission="${prefix}_${test_name#t_}"
  if ! POOL="$pool" Scripts/kpwait.sh "$mission" 3600; then
    failed=$((failed + 1))
  fi
done

echo "resume regression failures: $failed"
exit "$failed"
