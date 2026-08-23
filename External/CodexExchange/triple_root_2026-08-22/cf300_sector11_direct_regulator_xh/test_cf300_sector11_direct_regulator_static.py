#!/usr/bin/env python3
"""No-kernel source audit for the CF300 direct regulator continuation."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
DRIVER = HERE / "run_cf300_sector11_direct_scalar_regulator_continuation_v1.wls"
INSPECTOR = HERE / "inspect_cf300_sector11_regulator_structure.py"
EXPECTED = {
    DRIVER.name: "c8ff233744d8875c3476f0fb44013a70dcc251f725059a89bcb19005d33ae960",
    INSPECTOR.name: "0c91648c61f8f9a938af5b64a90b9ce972b326abd3313c08dbf4b0e2b9fd652b",
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
source = DRIVER.read_text()
inspector = INSPECTOR.read_text()

assert balanced_wolfram_delimiters(source)
assert not re.search(r"[ \t]+$", source, flags=re.MULTILINE)
assert not re.search(r"[ \t]+$", inspector, flags=re.MULTILINE)
assert 'BeginPackage["CodexCF300Sector11DirectRegulatorContinuationV1`"]' in source
assert 'artifactContext = "CodexCF300Sector11RegulatorStateSymbolsV1`";' in source
assert '$ContextPath = {"System`", artifactContext' in source
assert 'MemberQ[$ContextPath, "Global`"]' not in source
assert 'Quiet[CheckAbort[Get[file], $Aborted]]' in source
assert "Check[Get[file]" not in source
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
assert '{mu, 2}, {row, 21, 22}, {column, 1, 20}' in source
assert 'lowerLeftCount =!= 26 || diagonalCount =!= 8' in source
assert 'futureCount =!= 8 || sCount =!= 2 ||' in source
assert 'sInverseCount =!= 14' in source
assert '"DenseTransformationUnknowns" -> 484' in source
assert '"ReducedScalarUnknowns" -> 1' in source
assert 'TimeConstrained[' in source and '900, $Aborted' in source
assert 'KeyDrop[state, {"Stop"}]' in source
assert '"DirectInvariantSubspace/ScalarSectorBlock"' in source
assert 'OverwriteTarget -> False' in source
assert 'OverwriteTarget -> True' not in source
assert 'FileHash[inputFile, "SHA256", "HexString"] =!=' in source
assert 'Apply[Remove, names]' in source
assert 'Remove[artifactContext <> "*"]' not in source

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
assert "subprocess" not in inspector

print("CF300_SECTOR11_DIRECT_REGULATOR_STATIC PASS 64/64")
