#!/usr/bin/env bash
set -euo pipefail

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exchange=$(CDPATH= cd -- "$here/.." && pwd)
driver="$here/run_cf300_sector12_denominator_census.wls"
checker="$exchange/flint_affine_rref_wl_xh/check_wl_delimiters.pl"

checks=0
pass() {
  checks=$((checks + 1))
}
require_literal() {
  local literal=$1
  grep -Fq -- "$literal" "$driver"
  pass
}
forbid_literal() {
  local literal=$1
  if grep -Fq -- "$literal" "$driver"; then
    echo "forbidden literal in $driver: $literal" >&2
    exit 1
  fi
  pass
}

test -s "$driver"; pass
test -x "$checker" || test -f "$checker"; pass
perl "$checker" "$driver"; pass

require_literal 'expectedCacheHash ='
require_literal 'DRCAReadCompiledArtifact['
require_literal 'DRCAAssemblyPreparationValidQ['
require_literal 'ChannelDenominatorFingerprintCollision'
require_literal 'ChannelFactorFingerprintCollision'
require_literal 'GaugeFactorFingerprintCollision'
require_literal '"SourceMaximumDenominatorExponents" -> sourceExponentMaxima'
require_literal 'forcingExponent = sourceExponentMaxima["BBar"]'
require_literal 'expectedGaugeExponent = Max[forcingExponent - 1, 0]'
require_literal '"GaugeExponentDeficit" -> gaugeExponentDeficit'
require_literal 'GaugeDenominatorMissingRequiredHigherPoleFactor'
require_literal '"OmittedByForcingSimplePoleRule" ->'
require_literal 'TrueQ[#1["OmittedByForcingSimplePoleRule"]]'
require_literal 'TrueQ[#1["EpsilonFree"]]'
require_literal 'TrueQ[#1["KinematicsDependent"]]'
require_literal 'ContextualDiagonalSimplePoleCandidates'
require_literal 'epsilon-free kinematic factor with BBar maximum pole order one and gauge exponent zero'
require_literal 'SourceOrCacheChangedDuringCensus'
require_literal 'RenameFile[temporary, outputFile,'

forbid_literal 'TrueQ[#1["SimplePoleOnly"]] && TrueQ[#1["EpsilonFree"]]'
forbid_literal 'RunProcess['
forbid_literal 'ParallelMap['
forbid_literal 'LaunchKernels['

echo "DENOMINATOR_CENSUS_STATIC PASS $checks/$checks"
