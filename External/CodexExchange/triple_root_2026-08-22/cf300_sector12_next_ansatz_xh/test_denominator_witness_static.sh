#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="$dir/run_cf300_sector12_denominator_witness_screen.wls"
checker="$dir/../flint_affine_rref_wl_xh/check_wl_delimiters.pl"
passes=0
checks=0

require_text() {
  checks=$((checks + 1))
  grep -Fq -- "$1" "$target"
  passes=$((passes + 1))
}
forbid_text() {
  checks=$((checks + 1))
  if grep -Fq -- "$1" "$target"; then
    printf 'forbidden token: %s\n' "$1" >&2
    exit 1
  fi
  passes=$((passes + 1))
}

test -f "$target"
test -f "$checker"
perl "$checker" "$target"
require_text 'expectedCensusHash ='
require_text 'expectedCandidateFingerprints = Sort[{'
require_text 'candidateSelector ='
require_text 'artifactRead[file_String]'
require_text 'loadSource[file_String]'
require_text 'loadOutcomes = AssociationMap['
require_text 'CF300Sector12DenominatorWitnessTargetedScreenPassed'
require_text 'DRCAReadCompiledArtifact'
require_text 'DRCARebindAnsatz'
require_text 'RequiredOldGaugeNumeratorSupport'
require_text 'containmentProjection['
require_text 'PureSupersetMatrixContainmentFailed'
require_text 'AIWConstruct['
require_text 'AIWScoreColumns['
require_text '"WitnessFailure" -> KeyDrop[witness, "Witness"]'
require_text 'A^T y=0,b^T y=1'
require_text 'nativeRank['
require_text '"coefficient"'
require_text '"augmented"'
require_text 'canonicalVectorQ['
require_text 'canonicalMatrixQ['
require_text 'rows === 0'
require_text 'NativeRankCertificatePostconditionFailed'
require_text '"Verification" -> Lookup[run, "Verification"'
require_text '"DiagnosticArtifactDirectory" ->'
require_text 'RankImageCoefficientFailed'
require_text 'RankImageAugmentedFailed'
require_text '"RankFailure" -> fullRank'
require_text 'SourceOrArtifactChangedDuringScreen'
require_text 'writeAtomic['
forbid_text 'LaunchKernels'
forbid_text 'ParallelMap'
forbid_text 'RowReduce'
forbid_text 'MatrixRank'
forbid_text 'LinearSolve'
forbid_text 'canonicalArrayQ['
forbid_text 'Get[files["LoadFACET"]]'
forbid_text 'FeynFacet`FamilyArtifactRead[preparationFile]'

printf 'DENOMINATOR_WITNESS_STATIC PASS %d/%d\n' "$passes" "$checks"
