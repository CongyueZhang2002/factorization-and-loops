#!/usr/bin/env bash
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
driver="$here/run_cf300_sector12_rank2_ansatz_discriminator.wls"
expected_driver_sha256="8f0f35d953fae2c9f6c824f926db388c3ed88b6ed171f3950a5777721a66474d"
triple_root=$(cd -- "$here/../.." && pwd)
checker="$triple_root/flint_affine_rref_wl_xh/check_wl_delimiters.pl"

perl "$checker" "$driver"
python3 - "$driver" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
required = [
    '"A0", currentSupport, basePreparation["OneForms"]',
    '"AS", widenedSupport, basePreparation["OneForms"]',
    '"AL", currentSupport, unionForms',
    '"ASL", widenedSupport, unionForms',
    'widenedSupport = Join[currentSupport,',
    'Take[widenedSupport, Length[currentSupport]] =!= currentSupport',
    'Map[CodexTripleRootStrip`TRFieldDecompose',
    'FactorList[Expand[polynomial]]',
    'FreeQ[factor, epsilon]',
    'Scan[appendUniqueForm, basePreparation["OneForms"]]',
    'Max[4, Ceiling[(unknownCount + 32)/32]]',
    'assembleSharedSamples[localImage_Association, localSeed_Integer]',
    'variantColumnMap[localPreparation_Association]',
    'variantColumnMaps["ASL"] =!=',
    '"AssemblyVariant" -> "ASL"',
    'projectedRows = #1[[columnMap]] & /@ fullRows',
    'basePreparation["ABIFingerprint"], image["Prime"]',
    '{prefixPointCount, {19, 20, 21}}',
    'variantLabel === "A0" && image["ImageID"] === "I00"',
    'augmented = Join[localMatrix, rightColumn, 2]',
    '"CertifiedAffineConsistencyByTwoRanksV1"',
    'CFFRRun[nativeBinary, request,',
    'nativeThreads, False, 600',
    'TimeConstrained[\n      assembleSharedSamples[image, seed], 3600, $Failed]',
    'mainResult = MemoryConstrained[TimeConstrained[Catch[Module[',
    '], $discriminatorFailureTag], mainTimeBudgetSeconds,',
    '"GlobalMemoryLimitBytes" -> 8 2^30',
    'MemoryConstrained[artifactRead[preparationFile],',
    'CodexTripleRootReconstruction`TRPreparationABIValidQ[basePreparation]',
    'expectedSourceClosureRelative = <|',
    'sourceClosureDifference[sourceClosureBefore,',
    '"ExpectedSourceClosure" -> KeySort[sourceClosureExpected]',
    '"ObservedSourceClosure" -> KeySort[sourceClosureBefore]',
    'committed = Quiet[Check[Get[outputFile], $Failed]]',
    'finalCurrentSourceState[] ===\n        mainResult["ExpectedSourceState"]',
    'deleteIfPresent[outputFile]',
    '"ProductionLinearAlgebraBackend" ->',
    '"RankFourTRFieldInverseOnly"',
    '"SharedPointStreams" -> sharedPointStreams',
    '<I00|I01|I10|I11|ALL>',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit('missing contracts: ' + repr(missing))

for forbidden in ('RowReduce', 'MatrixRank', 'LinearSolve', 'NullSpace',
                  'LaunchKernels', 'ParallelSubmit', 'ParallelTable',
                  'ParallelMap'):
    if re.search(r'(?<![A-Za-z`])' + re.escape(forbidden) + r'(?![A-Za-z])', text):
        raise SystemExit('forbidden production operation: ' + forbidden)
for forbidden in ('InstallEpsFormStripSolution', 'FamilyArtifactWrite'):
    if forbidden in text:
        raise SystemExit('forbidden package mutation: ' + forbidden)
if 'InconsistentAffineImage' in text or 'ExitCode' in text:
    raise SystemExit('exit-code-only inconsistency path is forbidden')
if 'KeyDrop[run, {"Certificate", "Verification"}]' in text:
    raise SystemExit('native verifier diagnostics must survive failure artifacts')
if 'Get[coreDependencyFiles["LoadFACET"]]' in text or 'FeynFacet`FamilyArtifactRead' in text:
    raise SystemExit('full driver must not execute LoadFACET/FeynCalc/FeynFacet')

manifest_match = re.search(
    r'expectedSourceClosureRelative\s*=\s*<\|(.*?)\|>;', text, re.S)
if not manifest_match:
    raise SystemExit('literal executed-source manifest missing')
manifest_entries = re.findall(
    r'^\s*"([^"]+)"\s*->\s*"([0-9a-f]{64})"',
    manifest_match.group(1), re.M)
if len(manifest_entries) != 6 or len(dict(manifest_entries)) != 6:
    raise SystemExit(f'executed-source manifest must contain 6 unique files: {manifest_entries!r}')

images = re.findall(
    r'<\|"ImageID"\s*->\s*"(I(?:00|01|10|11))",\s*"Prime"\s*->\s*(\d+),\s*"EpsilonValue"\s*->\s*([^|]+)\|>',
    text)
expected_images = {
    ('I00', '10007', '1/21'), ('I01', '10007', '1/11'),
    ('I10', '10039', '1/21'), ('I11', '10039', '1/11'),
}
if set((a, b, c.strip()) for a, b, c in images) != expected_images or len(images) != 4:
    raise SystemExit(f'exact four-image schema mismatch: {images!r}')

if text.index('sourceClosureDiff = sourceClosureDifference[') > text.index('Get[coreDependencyFiles["TripleRootAlgebra"]]'):
    raise SystemExit('executed-source closure is not checked before first Get')
rename_pos = text.index('RenameFile[temporary, outputFile')
readback_pos = text.index('committed = Quiet[Check[Get[outputFile], $Failed]]')
postcheck_pos = text.index('(commitCheck === Automatic || TrueQ[commitCheck[]])')
delete_pos = text.index('deleteIfPresent[outputFile]', readback_pos)
if not rename_pos < readback_pos < postcheck_pos < delete_pos:
    raise SystemExit('post-rename readback/source/delete ordering invalid')
if '! FileExistsQ[file]' not in text or 'invalid committed target remains' not in text:
    raise SystemExit('exact-target cleanup absence is not verified')

print('DISCRIMINATOR STATIC semantic_checks=37 failures=0')
PY

actual_driver_sha256=$(sha256sum "$driver" | awk '{print $1}')
if [[ "$expected_driver_sha256" != "PENDING" && \
      "$actual_driver_sha256" != "$expected_driver_sha256" ]]; then
  printf 'DISCRIMINATOR STATIC frozen_driver_hash_mismatch expected=%s actual=%s\n' \
    "$expected_driver_sha256" "$actual_driver_sha256" >&2
  exit 1
fi
printf 'DISCRIMINATOR STATIC driver_sha256=%s\n' "$actual_driver_sha256"
