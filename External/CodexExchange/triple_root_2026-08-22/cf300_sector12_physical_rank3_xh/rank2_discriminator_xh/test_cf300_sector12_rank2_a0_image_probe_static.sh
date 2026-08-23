#!/usr/bin/env bash
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
driver="$here/run_cf300_sector12_rank2_a0_image_probe.wls"
expected_driver_sha256="15b6b504b3204c16ec590de16269e7d992379a9816b460e951b92f3f97004d45"
triple_root=$(cd -- "$here/../.." && pwd)
checker="$triple_root/flint_affine_rref_wl_xh/check_wl_delimiters.pl"

perl "$checker" "$driver"
python3 - "$driver" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
required = [
    '"I00" -> <|"Prime" -> 10007, "EpsilonValue" -> 1/21|>',
    '"I01" -> <|"Prime" -> 10007, "EpsilonValue" -> 1/11|>',
    '"I10" -> <|"Prime" -> 10039, "EpsilonValue" -> 1/21|>',
    '"I11" -> <|"Prime" -> 10039, "EpsilonValue" -> 1/11|>',
    'sourceClosureSnapshot[]',
    'expectedSourceClosureRelative = <|',
    'executedSourceFiles = Join[',
    'sourceClosureDifference[sourceClosureBefore,',
    '"SourceClosureDifference" -> sourceClosureDiff',
    '"ExpectedSourceClosure" -> KeySort[sourceClosureExpected]',
    '"ObservedSourceClosure" -> KeySort[sourceClosureBefore]',
    'expectedNativeBinarySHA256',
    'CFFRRun[nativeBinary, request, 1,',
    'augmented = Join[localMatrix, rightColumn, 2]',
    '"ConsistencyMethod" -> "VerifiedRanksOfAAndAugmentedMatrix"',
    '{prefixPointCount, {19, 20, 21}}',
    'Function[Null, currentState[] === expectedState]',
    'committed = Quiet[Check[Get[outputFile], $Failed]]',
    'deleteIfPresent[outputFile]',
    '"SymbolicAssemblyTimeoutSeconds" -> 900',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit('missing contracts: ' + repr(missing))
for forbidden in ('RowReduce', 'MatrixRank', 'LinearSolve', 'NullSpace',
                  'LaunchKernels', 'ParallelSubmit'):
    if re.search(r'(?<![A-Za-z`])' + re.escape(forbidden) + r'(?![A-Za-z])', text):
        raise SystemExit('forbidden operation: ' + forbidden)
images = re.findall(r'"I(?:00|01|10|11)"\s*->\s*<\|"Prime"', text)
if len(images) != 4 or len(set(images)) != 4:
    raise SystemExit(f'image schema count mismatch: {images!r}')
if 'InconsistentAffineImage' in text or 'ExitCode' in text:
    raise SystemExit('exit-code-only inconsistency path is forbidden')
if 'KeyDrop[run, {"Certificate", "Verification"}]' in text:
    raise SystemExit('native verifier diagnostics must survive failure artifacts')
if '"RequestFingerprint" -> requestFingerprint[request]' not in text:
    raise SystemExit('native failure request fingerprint missing')
manifest_match = re.search(
    r'expectedSourceClosureRelative\s*=\s*<\|(.*?)\|>;', text, re.S)
if not manifest_match:
    raise SystemExit('literal source-closure manifest missing')
manifest_entries = re.findall(
    r'^\s*"([^"]+)"\s*->\s*"([0-9a-f]{64})"',
    manifest_match.group(1), re.M)
if len(manifest_entries) != 6 or len(dict(manifest_entries)) != 6:
    raise SystemExit(f'expected 6 unique executed-source entries, got {len(manifest_entries)}')
if any(not path.startswith('External/CodexExchange/triple_root_2026-08-22/')
       for path, _ in manifest_entries):
    raise SystemExit('urgent shard executed-source manifest escaped External-only scope')
if 'Get[coreDependencyFiles["LoadFACET"]]' in text or 'FeynFacet`FamilyArtifactRead' in text:
    raise SystemExit('urgent shard must not execute LoadFACET/FeynCalc/FeynFacet')
if text.index('sourceClosureDiff = sourceClosureDifference[') > text.index('Get[coreDependencyFiles["TripleRootAlgebra"]]'):
    raise SystemExit('immutable closure is not checked before first Get')
rename_pos = text.index('RenameFile[temporary, outputFile')
readback_pos = text.index('committed = Quiet[Check[Get[outputFile], $Failed]]')
postcheck_pos = text.index('(commitCheck === Automatic || TrueQ[commitCheck[]])')
delete_output_pos = text.index('deleteIfPresent[outputFile]', readback_pos)
if not rename_pos < readback_pos < postcheck_pos < delete_output_pos:
    raise SystemExit('post-rename readback/source/delete ordering invalid')
if '! FileExistsQ[file]' not in text or 'invalid committed target remains' not in text:
    raise SystemExit('committed-target cleanup absence is not verified')
assembly_pos = text.index('{assemblySeconds, sample} = AbsoluteTiming[TimeConstrained[')
if text.index('900, $Failed]];', assembly_pos) < assembly_pos:
    raise SystemExit('symbolic assembly lacks explicit TimeConstrained fallback')
print('A0 STATIC semantic_checks=25 failures=0')
PY
actual_driver_sha256=$(sha256sum "$driver" | awk '{print $1}')
if [[ "$actual_driver_sha256" != "$expected_driver_sha256" ]]; then
  printf 'A0 STATIC frozen_driver_hash_mismatch expected=%s actual=%s\n' \
    "$expected_driver_sha256" "$actual_driver_sha256" >&2
  exit 1
fi
printf 'A0 STATIC driver_sha256=%s\n' "$actual_driver_sha256"
