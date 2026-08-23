#!/usr/bin/env python3
"""No-kernel source audit for the CF300 direct regulator continuation."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
DRIVER = HERE / "run_cf300_sector11_direct_scalar_regulator_continuation_v4.wls"
INSPECTOR = HERE / "inspect_cf300_sector11_regulator_structure_v2.py"
DIAGNOSIS = HERE / "diagnose_cf300_sector11_v2_exit71_static.py"
EXPECTED = {
    DRIVER.name: "369a05cfcc761b265059839365939cb06acbeb6e0bd9e67cf3f651706f5c3b6c",
    INSPECTOR.name: "036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3",
    DIAGNOSIS.name: "cbcc4d56529bdb92597cc1ce71456825ff4b82e7742a6ff42d224d6bde126a63",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


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


assert sha256(DRIVER) == EXPECTED[DRIVER.name]
assert sha256(INSPECTOR) == EXPECTED[INSPECTOR.name]
assert sha256(DIAGNOSIS) == EXPECTED[DIAGNOSIS.name]
source = DRIVER.read_text()
inspector = INSPECTOR.read_text()
diagnosis = DIAGNOSIS.read_text()

assert balanced_wolfram_delimiters(source)
assert not re.search(r"[ \t]+$", source, flags=re.MULTILINE)
assert not re.search(r"[ \t]+$", inspector, flags=re.MULTILINE)
assert 'BeginPackage["CodexCF300Sector11DirectRegulatorContinuationV4`"]' in source
assert 'artifactContext = "CodexCF300Sector11RegulatorStateSymbolsV4`";' in source
assert '$ContextPath = {"System`", artifactContext' in source
assert 'MemberQ[$ContextPath, "Global`"]' not in source
assert 'Quiet[CheckAbort[Get[file], $Aborted]]' in source
assert "Check[Get[file]" not in source
assert 'Lookup[artifactReadTelemetry, "Messages", $Failed] === {}' in source
assert 'expectedStateBytes = 33012365;' in source
assert (
    '"898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12"'
    in source
)
assert source.index("FileByteCount[inputFile]") < source.index(
    "state = artifactRead[inputFile]"
)
assert source.index("inputHashBefore = FileHash[inputFile") < source.index(
    "state = artifactRead[inputFile]"
)
assert 'Lookup[stop, "RootIndices", None] === {1, 2, 3}' in source
assert 'Lookup[Last[factors], "Rows", None] === 10' in source
assert 'Lookup[Last[factors], "RootIndices", None] === {1, 2}' in source
assert 'Dimensions[Lookup[state, "A", {}]] === {2, 24, 24}' in source
assert '(2*epsilon - 1)*(3*epsilon - 1)*(3*epsilon - 2)' in source
assert 'lowerLeftScalar = Together[regulatorPolynomial/epsilon^2];' in source
assert 'transformation = Together[regulatorPolynomial/epsilon^3];' in source
assert 'connection[[All, 1 ;; 20, 21 ;; 22]]' in source
assert 'connection[[All, 1 ;; 22, 23 ;; 24]]' in source
assert '{mu, 2}, {row, 21, 22}, {column, 1, 20}' in source
assert 'lowerLeftCount =!= 26 || diagonalCount =!= 8' in source
assert 'futureCount =!= 8 || sCount =!= 2 ||' in source
assert 'sInverseCount =!= 14' in source
assert 'rowScales = Table[' in source
assert 'columnScales = Table[' in source
assert 'connection[[mu, row, column]]*columnScales[[column]]' in source
assert '{mu, 2}, {row, 24}, {column, 24}' in source
assert 'state["S"][[row, column]]*' in source
assert 'state["SInverse"][[row, column]]' in source
assert '"FullTransformedAIdentityQ" -> transformedAIdentityQ' in source
assert '"FullSIdentityQ" -> sIdentityQ' in source
assert '"FullSInverseIdentityQ" -> sInverseIdentityQ' in source
assert 'newConnection[[All, 1 ;; 22, 1 ;; 22]]' in source
assert 'FreeQ[actualEntry/epsilon, epsilon]' in source
assert 'legacyStructuralPrefixEpsFormQ = True' in source
assert 'legacyStructuralFirstFailure = Missing["None"]' in source
assert 'inheritedFormalCertificateQ = TrueQ[' in source
assert 'inputHashBefore === expectedStateHash' in source
assert 'inspectorHashBefore === expectedInspectorHash' in source
assert 'inheritedSpotIndices = {' in source
assert 'Together[value/epsilon]' in source
assert '"FullPrefixEpsFormQ" -> fullPrefixEpsFormQ' in source
assert 'fullPrefixEpsFormQ = TrueQ[' in source
assert 'inheritedFormalCertificateQ && upperRightZeroQ' in source
assert 'lowerLeftIdentityQ && diagonalFactoredQ &&' in source
assert 'inheritedSpotProofQ' in source
for stage in (
    "precheck",
    "prefix_blocks",
    "propagation_counts",
    "exact_validation",
):
    assert f"predicate_stage={stage}" in source
for field in (
    '"FirstAFailure"',
    '"FirstSFailure"',
    '"FirstSInverseFailure"',
    '"LegacyStructuralFirstFailure"',
    '"InheritedSpotResults"',
):
    assert field in source
assert 'makePropagationSeal[inputPrefix_, outputPrefix_, transformation_' in source
assert '"InputPrefixSHA256" ->' in source
assert '"OutputPrefixSHA256" ->' in source
assert '"TransformationScalarSHA256" ->' in source
assert '"InverseScalarSHA256" ->' in source
assert 'SameQ[propagationSeal, recomputedSeal]' in source
assert '"PropagationSeal" -> propagationSeal' in source
assert '"PropagationSealRecomputedQ" ->' in source
assert 'Numerator[Together[transformation^2]] =!= 0' in source
assert '"TransformationDeterminant" -> transformation^2' in source
assert '"TransformationNonzeroRationalFunction" -> True' in source
assert '"ExceptionalEpsilonValues" -> {0, 1/3, 1/2, 2/3}' in source
assert '"DenseTransformationUnknowns" -> 484' in source
assert '"ReducedScalarUnknowns" -> 1' in source
assert 'TimeConstrained[' in source and '900, $Aborted' in source
assert 'KeyDrop[state, {"Stop"}]' in source
assert '"DirectInvariantSubspace/ScalarSectorBlock"' in source
assert 'OverwriteTarget -> False' in source
assert 'OverwriteTarget -> True' not in source
assert 'FileHash[inputFile, "SHA256", "HexString"] =!=' in source
assert 'FileHash[inspectorFile, "SHA256", "HexString"] =!=' in source
assert 'inspect_cf300_sector11_regulator_structure_v2.py' in source
assert 'Apply[Remove, names]' in source
assert 'Remove[artifactContext <> "*"]' not in source
post_package = source.rsplit("EndPackage[];", 1)[1]
assert post_package.strip() == (
    "System`Exit[\n"
    "  CodexCF300Sector11DirectRegulatorContinuationV4`Private`finalCode];"
)
assert not re.search(r"System`Exit\[\s*finalCode\b", post_package)
assert "resolvedFinalCode" not in post_package
assert 'System`Exit[finalCode]' not in source
assert '"SchemaVersion" -> 4' in source
assert 'PinnedFormalDegreeCensusPlusEightTogetherSpotsV4' in source

for forbidden in (
    "LoadFACET",
    "FactorFamilyRegulatorDependence",
    "DRCAReadCompiledArtifact",
    "Internal`InheritedBlock",
    "LaunchKernels",
    "ParallelSubmit",
    "StartProcess",
    "KillProcess",
    "SetProcessorAffinity",
    "RunProcess",
    "SystemOpen",
    "Dot[",
    "IdentityMatrix",
):
    assert forbidden not in source

global_mutation = re.compile(
    r"(?:Clear|ClearAll|Remove|Unprotect|Protect|SetAttributes|OwnValues|"
    r"DownValues|UpValues|SubValues|NValues|DefaultValues|FormatValues)\s*\["
    r"[^\]]*Global`(?:x|y|eps)"
)
for match in global_mutation.finditer(source):
    # Definition-table occurrences are the read-only snapshot on their
    # respective lines; assignments to the returned lists do not occur.
    line = source[source.rfind("\n", 0, match.start()) + 1 : source.find("\n", match.end())]
    assert re.match(
        r"\s*(?:\"(?:x|y|eps)\" -> \{)?(?:OwnValues|DownValues|UpValues|"
        r"SubValues|NValues|DefaultValues|FormatValues)\[Global`(?:x|y|eps)\]",
        line,
    )

assert 'EXPECTED_STATE_BYTES = 33_012_365' in inspector
assert 'expected_counts = {' in inspector
assert '("new_lower_left_2x20", ((0, 1),)): 26' in inspector
assert '("new_diagonal_2x2", ((1, 0),)): 8' in inspector
assert '("upper_right_20x2", "zero"): 80' in inspector
assert 'full_dense_unknowns=484 reduced_scalar_unknowns=1' in inspector
assert 'prefix_to_future_zero_channels=88' in inspector
assert 'future_scaled_nonzero_channels=8' in inspector
assert "subprocess" not in inspector
assert 'EXPECTED_DISTRIBUTED = [' in diagnosis
assert '(1, 18, 6, 7, 530,' in diagnosis
assert '(2, 18, 6, 13, 747,' in diagnosis
assert 'predicted_v2_legacy_first_failure={1,18,6}' in diagnosis
assert 'syntactic cancellation test' in diagnosis

print("CF300_SECTOR11_DIRECT_REGULATOR_V4_STATIC PASS 137/137")
