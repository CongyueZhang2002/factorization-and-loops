#!/usr/bin/env python3
"""Static fail-closed audit of the narrow kernel-144 poison cleanup gate."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
CLEANUP = HERE / "cleanup_kernel144_exact_v2_poison_signature_v1.wls"
SOURCE_MODEL = HERE / "run_hydration_context_poison_model_v2.wls"
text = CLEANUP.read_text()
source = SOURCE_MODEL.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


assertions = 0
assert 'BeginPackage["CodexCF300Kernel144ExactPoisonCleanupV1`"]' in text
assert text.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", text)
assert "Internal`InheritedBlock" not in text
assertions += 4

for component in (
    "OwnValues",
    "DownValues",
    "UpValues",
    "SubValues",
    "NValues",
    "DefaultValues",
    "FormatValues",
    "Attributes",
):
    assert f'"{component}" -> {component}[symbol]' in text
    assertions += 1

for literal in (
    "Global`x] :> 31337",
    "Global`y] :> -27183",
    "Global`eps] :> 65537",
    'HoldComplete["x-down"',
    'HoldComplete["y-down"',
    'HoldComplete["eps-down"',
    'HoldComplete["x-up"]',
    'HoldComplete["y-up"]',
    'HoldComplete["eps-up"]',
    'HoldComplete["x-sub"]',
    'HoldComplete["y-sub"]',
    'HoldComplete["eps-sub"]',
    "poisonHeadX",
    "poisonHeadY",
    "poisonHeadEpsilon",
    '"Attributes" -> {Locked, Protected}',
):
    assert literal in text, literal
    assertions += 1

for source_literal in (
    "Global`x = 31337;",
    "Global`y = -27183;",
    "Global`eps = 65537;",
    'Global`x[1][2] = HoldComplete["x-sub"]',
    'Global`y[1][2] = HoldComplete["y-sub"]',
    'Global`eps[1][2] = HoldComplete["eps-sub"]',
    'Global`x[argument_] := HoldComplete["x-down", argument]',
    'Global`y[argument_] := HoldComplete["y-down", argument]',
    'Global`eps[argument_] := HoldComplete["eps-down", argument]',
    "Global`x /: poisonHeadX[Global`x]",
    "Global`y /: poisonHeadY[Global`y]",
    "Global`eps /: poisonHeadEpsilon[Global`eps]",
):
    assert source_literal in source, source_literal
    assertions += 1

for digest in (
    "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
    "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968",
):
    assert text.count(digest) == 1, digest
    assertions += 1

assert 'signatureMatchQ = TrueQ[exactTablesAndAttributesMatchQ &&' in text
assert "observedFingerprintsMatchPinQ && literalFingerprintsMatchPinQ" in text
assert 'If[! TrueQ[signatureMatchQ],' in text
assert '"no mutation attempted"]' in text
assert text.index('If[! TrueQ[signatureMatchQ],') < text.index(
    'cleanupTag = "CF300Kernel144ExactPoisonCleanupV1-"'
)
assertions += 5

assert text.count("ClearAll[Global`x, Global`y, Global`eps]") == 1
assert 'SameQ[postAttemptStates, expectedCleanStates]' in text
assert "cleanupAborted = True;\n    cleanupCommitted = False;" in text
assert 'If[! TrueQ[cleanupCommitted],' in text
assert 'restoreDefinitionState[Global`x, preStates["x"]]' in text
assert 'restoreDefinitionState[Global`y, preStates["y"]]' in text
assert 'restoreDefinitionState[Global`eps, preStates["eps"]]' in text
assert 'SameQ[readAllStates[], preStates]' in text
assert 'SameQ[finalStates, expectedCleanStates]' in text
assertions += 9

for forbidden in (
    "Get[",
    "Put[",
    "Export[",
    "RunProcess[",
    "StartProcess[",
    "LaunchKernels",
    "ParallelSubmit",
    "KillProcess",
):
    assert forbidden not in text, forbidden
    assertions += 1

print(
    f"CF300_KERNEL144_EXACT_POISON_CLEANUP_STATIC PASS "
    f"{assertions}/{assertions} cleanup_sha256={sha256(CLEANUP)}"
)
