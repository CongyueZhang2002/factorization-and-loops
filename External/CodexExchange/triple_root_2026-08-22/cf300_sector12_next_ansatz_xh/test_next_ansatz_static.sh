#!/usr/bin/env bash
set -euo pipefail

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exchange=$(CDPATH= cd -- "$here/.." && pwd)
rebind="$here/DirectRootChannelAnsatzRebind.wl"
witness="$here/AffineInconsistencyWitness.wl"
rebind_gate="$here/run_cf300_sector12_ansatz_rebind_gate.wls"
checker="$exchange/flint_affine_rref_wl_xh/check_wl_delimiters.pl"

checks=0
pass() {
  checks=$((checks + 1))
}
require_literal() {
  local file=$1
  local literal=$2
  grep -Fq -- "$literal" "$file"
  pass
}
forbid_literal() {
  local file=$1
  local literal=$2
  if grep -Fq -- "$literal" "$file"; then
    echo "forbidden literal in $file: $literal" >&2
    exit 1
  fi
  pass
}

test -s "$rebind"; pass
test -s "$witness"; pass
test -s "$rebind_gate"; pass
test -x "$checker" || test -f "$checker"; pass
perl "$checker" "$rebind" "$witness" "$rebind_gate"; pass

require_literal "$rebind" 'DRCAAssemblyPreparationValidQ['
require_literal "$rebind" 'TRPreparationABIValidQ[target]'
require_literal "$rebind" 'Take[targetOneForms, Length[baseOneForms]] === baseOneForms'
require_literal "$rebind" 'suffix, 2, roots, variables, epsilon'
require_literal "$rebind" 'GaugeDenominatorAndDLogOnly'
require_literal "$rebind" 'KeyTake[exactForms, $drarEquationCoreKeys] =!= baseCoreExact'
require_literal "$rebind" 'drarFingerprint[drarSemanticPayload[result]]'
require_literal "$rebind" 'ReboundAssemblyValidationFailed'
forbid_literal "$rebind" 'DRCACompileSystem['
forbid_literal "$rebind" 'DRCAPrepare['
forbid_literal "$rebind" 'RunProcess['

require_literal "$witness" 'Transpose[canonicalMatrix], {canonicalRight}'
require_literal "$witness" 'ConstantArray[0, columns], {1}'
require_literal "$witness" 'leftResidual =!= ConstantArray[0, columns]'
require_literal "$witness" 'rightPairing =!= 1'
require_literal "$witness" 'Mod[vector.canonicalCandidates, prime]'
require_literal "$witness" 'CertifiedCandidateBlockCannotRepairThisAffineImage'
require_literal "$witness" 'NecessaryScreenPassedButFullRankTestStillRequired'
require_literal "$witness" 'VerifiedFLINTAffineRREFRun'
forbid_literal "$witness" 'RowReduce['
forbid_literal "$witness" 'NullSpace['

require_literal "$rebind_gate" 'expectedCacheSHA256 ='
require_literal "$rebind_gate" 'DRCAReadCompiledArtifact['
require_literal "$rebind_gate" 'supportOffset22 = Flatten[Table['
require_literal "$rebind_gate" 'changedDenominator = Together['
require_literal "$rebind_gate" 'baseSample["Matrix"]'
require_literal "$rebind_gate" 'supportSample["Matrix"][[All, projection]]'
require_literal "$rebind_gate" 'FullFreshCompileDifferentialFailed'
require_literal "$rebind_gate" 'SourceOrArtifactChangedDuringGate'

echo "NEXT_ANSATZ_STATIC PASS $checks/$checks"
