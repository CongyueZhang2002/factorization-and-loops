#!/usr/bin/env python3
"""No-Wolfram source/adversarial audit for the pinned CF300 V4 validator."""

from __future__ import annotations

import ast
import hashlib
import re
import sys
from pathlib import Path


HERE = Path(__file__).resolve().parent
VALIDATOR = HERE / "validate_cf300_sector11_direct_regulator_v4_postwrite_v1.wls"
FORMAL_INSPECTOR = HERE / "inspect_cf300_sector11_postwrite_v4.py"
PRIOR_INSPECTOR = HERE / "inspect_cf300_sector11_regulator_structure_v2.py"
DRIVER = HERE / "run_cf300_sector11_direct_scalar_regulator_continuation_v4.wls"
INPUT = Path(
    "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/"
    "UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/"
    "CF300/sector_state_CF300_standard.wl"
)
OUTPUT = Path(
    "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/"
    "UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/"
    "CF300_direct_regulator_v4_candidate/sector_state_CF300_standard.wl"
)
REPORT = OUTPUT.parent / "cf300_sector11_direct_regulator_report_v4.wl"
EXPECTED = {
    VALIDATOR: "eb6482572086bf073e9cc2ef223c5663dfe76d39ac1f3eca46ce2fbf75def839",
    FORMAL_INSPECTOR: "554248efd8e62d293c8a4bfcef0e6774945b36b43965a8a65297d9609b764a8b",
    PRIOR_INSPECTOR: "036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3",
    DRIVER: "369a05cfcc761b265059839365939cb06acbeb6e0bd9e67cf3f651706f5c3b6c",
    INPUT: "898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12",
    OUTPUT: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    REPORT: "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def balanced_wolfram_delimiters(source: str) -> bool:
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack: list[str] = []
    in_string = False
    comment_depth = 0
    index = 0
    while index < len(source):
        if comment_depth:
            if source.startswith("(*", index):
                comment_depth += 1
                index += 2
                continue
            if source.startswith("*)", index):
                comment_depth -= 1
                index += 2
                continue
            index += 1
            continue
        if in_string:
            if source[index] == "\\":
                index += 2
                continue
            if source[index] == '"':
                in_string = False
            index += 1
            continue
        if source.startswith("(*", index):
            comment_depth = 1
            index += 2
            continue
        character = source[index]
        if character == '"':
            in_string = True
        elif character in pairs:
            stack.append(pairs[character])
        elif character in ")]}":
            if not stack or character != stack.pop():
                return False
        index += 1
    return not stack and not in_string and comment_depth == 0


def executable_name_occurrences(source: str, name: str) -> list[int]:
    tree = ast.parse(source)
    return [
        node.lineno
        for node in ast.walk(tree)
        if isinstance(node, ast.Name) and node.id == name
    ]


for path, expected_hash in EXPECTED.items():
    assert path.is_file(), path
    assert sha256(path) == expected_hash, path
assert INPUT.stat().st_size == 33_012_365
assert OUTPUT.stat().st_size == 33_009_263
assert REPORT.stat().st_size == 3_752
assert sorted(path.name for path in OUTPUT.parent.iterdir()) == sorted(
    [OUTPUT.name, REPORT.name]
)
for suffix in (".tmp", ".part", ".partial", ".new"):
    assert not Path(str(OUTPUT) + suffix).exists()
    assert not Path(str(REPORT) + suffix).exists()

source = VALIDATOR.read_text()
inspector = FORMAL_INSPECTOR.read_text()
assert balanced_wolfram_delimiters(source)
assert not re.search(r"[ \t]+$", source, flags=re.MULTILINE)
assert not re.search(r"[ \t]+$", inspector, flags=re.MULTILINE)
assert 'BeginPackage["CodexCF300Sector11PostwriteValidatorV1`"]' in source
assert 'artifactContext = "CodexCF300Sector11RegulatorStateSymbolsV4`";' in source
assert '$ContextPath = {"System`", artifactContext' in source
assert 'MemberQ[$ContextPath, "Global`"]' not in source
assert 'Quiet[CheckAbort[Get[file], $Aborted]]' in source
assert "Check[Get[file]" not in source
assert 'AllTrue[Values[artifactReadTelemetry]' in source
assert 'Lookup[#1, "Messages", $Failed] === {} &' in source
assert 'dedicatedSymbolsCleanQ[]' in source
assert 'SameQ[globalDefinitionSnapshot[], globalStateBefore]' in source
assert 'expectedOutputHash =' in source and EXPECTED[OUTPUT] in source
assert 'expectedReportHash =' in source and EXPECTED[REPORT] in source
assert 'expectedDriverHash =' in source and EXPECTED[DRIVER] in source
assert 'expectedFormalInspectorHash =' in source and EXPECTED[FORMAL_INSPECTOR] in source
assert 'expectedPriorInspectorHash =' in source and EXPECTED[PRIOR_INSPECTOR] in source
assert source.index("sourceAndArtifactPinsQ") < source.index(
    'inputState = artifactRead[inputFile, "InputState"]'
)
assert 'visibleCandidateFiles === Sort[{outputFile, reportFile}]' in source
assert 'NoneTrue[staleCandidates, FileExistsQ]' in source
assert 'FileByteCount(outputFile] === expectedOutputBytes' not in source
assert 'FileByteCount[outputFile] === expectedOutputBytes' in source

# Independent exact-text formal inspector, pinned and bounded.
assert 'RunProcess[' in source
assert '{"/usr/bin/python3", formalInspectorFile, "--json"' in source
assert '240, $Aborted' in source
assert 'ImportString[formalRun["StandardOutput"], "RawJSON"]' in source
assert '"FormalPrefixEntriesChecked", None] === 968' in source
assert '"FormalEpsilonNonzeroChannels", None] === 317' in source
assert '"FormalZeroChannels", None] === 651' in source
assert '"AlgebraicallyEliminatedInputChannels", None] ===' in source
assert '{{1, 22, 11}}' in source
assert executable_name_occurrences(inspector, "FreeQ") == []
freeq_mutant = inspector + "\nFreeQ[entry / eps]\n"
assert executable_name_occurrences(freeq_mutant, "FreeQ") != []
assert "expression_multidegrees(expression)" in inspector
assert 'expected_output_counts = {' in inspector
assert '("new_lower_left_2x20", ((1, 0),)): 25' in inspector
assert '"FormalPrefixEntriesChecked": 968' in inspector
assert '"OutputPrefixDegreeFingerprintSHA256"' in inspector
assert "subprocess" not in inspector

# Metadata/provenance and mandatory fresh sector-12 recapture marker.
for key in (
    '"Sector"',
    '"OriginalA"',
    '"Ranges"',
    '"Blocks"',
    '"ChartFingerprint"',
    '"StripSolvers"',
    '"SectorCertificates"',
    '"TDiagonal"',
    '"TDiagonalInverse"',
):
    assert key in source
assert 'sector12RecaptureRequiredQ = TrueQ[' in source
assert '! KeyExistsQ[outputState, "Stop"]' in source
assert 'Lookup[#1, "Sector", None] === 12 &' in source
assert 'Length[outputCertificates] === 10' in source
assert 'SameQ[Take[outputFactors, 9], inputFactors]' in source
assert 'Lookup[factorRecord, "Rows", None] === 11' in source
assert 'Lookup[factorRecord, "RootIndices", None] === {1, 2, 3}' in source
assert '"SchemaVersion", None] === 4' in source
assert 'Lookup[report, "OutputStateSHA256", None] === expectedOutputHash' in source

# Correct Laurent-field convention and its expansion-depth implication.
assert '(2*epsilon - 1)*(3*epsilon - 1)*(3*epsilon - 2)' in source
assert 'lowerLeftScalar = Together[regulatorPolynomial/epsilon^2];' in source
assert 'transformation = Together[regulatorPolynomial/epsilon^3];' in source
assert 'inverseScalar = Together[1/transformation];' in source
assert 'Together[inverseScalar*lowerLeftScalar - epsilon] === 0' in source
assert 'Together[epsilon*transformation - lowerLeftScalar] === 0' in source
assert 'Together[D[transformation, xVariable]] === 0' in source
assert 'Together[D[transformation, yVariable]] === 0' in source
assert 'poleOrderAtEpsilonZero === 3' in source
assert '"RequiredEpsilonExpansionDepthShift" -> 3' in source
assert '"CoefficientField" -> "Q(x,y,roots)(eps)"' in source
assert "transformation = Together[epsilon/lowerLeftScalar]" not in source

# Full sparse G identities, changed blocks, wrong-side mutants, inverse/seal.
assert 'inputState["A"][[mu, row, column]]*' in source
assert 'columnScales[[column]]' in source
assert 'inputState["S"][[row, column]]*' in source
assert 'inputState["SInverse"][[row, column]]' in source
assert '"AIdentityQ" -> aIdentityQ' in source
assert '"SIdentityQ" -> sIdentityQ' in source
assert '"SInverseIdentityQ" -> sInverseIdentityQ' in source
assert 'outputState["A"][[All, 1 ;; 22, 23 ;; 24]]' in source
assert '"PrefixToFutureZeroChannels" -> 88' in source
assert 'lowerCount = 0' in source and 'lowerCount++' in source
assert 'diagonalCount = 0' in source and 'diagonalCount++' in source
assert 'futureCount = 0' in source and 'futureCount++' in source
assert 'exactEntryEqualQ[new, epsilon*coefficient]' in source
assert 'exactEntryEqualQ[new, old*transformation]' in source
assert 'exactEntryEqualQ[new, transformation*old]' in source
assert 'exactEntryEqualQ[new, old*inverseScalar]' in source
assert '"WrongSideLowerLeftRejectedQ"' in source
assert '"WrongSideFutureRejectedQ"' in source
assert 'matrixProductIdentityAudit[' in source
assert 'outputState["S"], outputState["SInverse"]' in source
assert 'outputState["SInverse"], outputState["S"]' in source
assert '600, $Aborted' in source
assert 'makePropagationSeal[' in source
assert 'SameQ[Lookup[report, "PropagationSeal", $Failed]' in source
assert 'SameQ[Lookup[factorRecord, "PropagationSeal", $Failed]' in source
assert '"FullTransformedVsPriorConnectionReconstructionQ"' in source

# Fail-closed/read-only source behavior.
for forbidden in (
    "LoadFACET",
    "LaunchKernels",
    "ParallelSubmit",
    "StartProcess",
    "KillProcess",
    "SetProcessorAffinity",
    "Put[",
    "PutAppend[",
    "Export[",
    "CopyFile[",
    "RenameFile[",
    "DeleteFile[",
    "CreateFile[",
    "CreateDirectory[",
    "OpenWrite[",
    "OpenAppend[",
):
    assert forbidden not in source
assert 'Apply[Remove, names]' in source
assert 'Remove[artifactContext <> "*"]' not in source
post_package = source.rsplit("EndPackage[];", 1)[1]
assert post_package.strip() == (
    "System`Exit[CodexCF300Sector11PostwriteValidatorV1`Private`finalCode];"
)
assert not re.search(r"System`Exit\[\s*finalCode\b", post_package)
assert not re.search(r"\bLookup\(", source)
assert not re.search(r"(?<!#)#2\b", source)

# Small no-kernel formal-degree adversaries exercise distributed epsilon terms.
sys.path.insert(0, str(HERE))
from inspect_cf300_sector11_regulator_structure_v2 import (  # noqa: E402
    expression_multidegrees,
)

assert expression_multidegrees("eps*x+eps*y") == ((1, 0),)
assert expression_multidegrees("(eps*x+eps*y)/eps") == ((0, 0),)
assert expression_multidegrees("eps*(x+y)") == ((1, 0),)
assert expression_multidegrees("(-2+13*eps-27*eps^2+18*eps^3)/eps^2") == (
    (0, 1),
)
assert expression_multidegrees(
    "eps*((-2+13*eps-27*eps^2+18*eps^3)/eps^3)*x"
) == ((0, 1),)

print("CF300_SECTOR11_POSTWRITE_VALIDATOR_V1_STATIC PASS 190/190")
