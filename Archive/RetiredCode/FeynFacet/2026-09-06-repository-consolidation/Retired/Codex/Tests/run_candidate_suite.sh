#!/usr/bin/env bash
set -u

tests=(
  CoreContracts
  LoadInfrastructure
  ReloadSafety
  StrictContracts
  ExpressionForm
  LinearIntegralSum
  CommonFactorMultiset
  CausalCutAndBranchSafety
  PartialFractionTwoLoop
  BuildTopologies
  DimensionalShift
  GramMomentRecurrence
  CollinearFactorizePreIBP
  CollinearFactorizeTT
  TopologyEquivalence
  TopologyEquivalenceStress
  ProcessIndependentSimplification
  ReductionCacheSafety
  MasterIntegralAmFlowContracts
)

status=0
log_directory="/home/maxzhang/FACET/Codex/TestResults/candidate_suite"
mkdir -p "${log_directory}"
for test in "${tests[@]}"; do
  log="${log_directory}/${test}.log"
  echo "=== ${test} ==="
  if timeout 1800 wolframscript -file "/home/maxzhang/FACET/Codex/Tests/${test}.wls" >"${log}" 2>&1; then
    echo "criterion satisfied: ${test}"
  else
    code=$?
    echo "criterion not satisfied: ${test} (${code})"
    tail -n 80 "${log}"
    status=1
  fi
done
exit "${status}"
