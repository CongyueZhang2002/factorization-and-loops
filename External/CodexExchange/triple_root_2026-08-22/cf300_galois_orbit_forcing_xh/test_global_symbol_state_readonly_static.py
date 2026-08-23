#!/usr/bin/env python3
"""Fail-closed no-kernel proof that the recovery probe is read-only."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
PROBE = HERE / "inspect_cf300_galois_global_symbol_state_readonly_v1.wls"
text = PROBE.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


assertions = 0
assert 'BeginPackage["CodexCF300GlobalSymbolStateReadOnlyProbeV1`"]' in text
assert 'Begin["`Private`"]' in text
assert text.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", text)
assertions += 4

for key in (
    "OwnValues",
    "DownValues",
    "UpValues",
    "SubValues",
    "NValues",
    "DefaultValues",
    "FormatValues",
    "Attributes",
):
    assert f'"{key}" -> {key}[symbol]' in text
    assertions += 1

assert text.count("definitionSnapshot[Global`x]") == 2
assert text.count("definitionSnapshot[Global`y]") == 2
assert text.count("definitionSnapshot[Global`eps]") == 2
assert '"ReadOnlySameQ" -> SameQ[statesBefore, statesAfter]' in text
assert '"ExactDefinitionStates" -> statesBefore' in text
assert '"StateFingerprints"' in text
assert '"ComponentFingerprints"' in text
assertions += 7

# These are forbidden anywhere in the probe, including helper definitions.
forbidden_items = (
    "Unlock[",
    "Unprotect[",
    "Protect[",
    "Lock[",
    "Clear[Global`",
    "ClearAll[Global`",
    "ClearAttributes[Global`",
    "SetAttributes[Global`",
    "OwnValues[Global`x] =",
    "OwnValues[Global`y] =",
    "OwnValues[Global`eps] =",
    "Remove[",
    "Put[",
    "Export[",
    "RunProcess[",
    "LaunchKernels",
    "ParallelSubmit",
)
for forbidden in forbidden_items:
    assert forbidden not in text, forbidden
    assertions += 1

assert "FileHash[$InputFileName" in text
assert 'InputForm[diagnostics]' in text
assertions += 2

print(
    f"CF300_GLOBAL_STATE_READONLY_STATIC PASS {assertions}/{assertions} "
    f"probe_sha256={sha256(PROBE)}"
)
