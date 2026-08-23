#!/usr/bin/env python3
"""Static audit for the minimal no-Global artifact hydration gate."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
GATE = HERE / "run_cf300_dedicated_context_hydration_gate_v1.wls"
text = GATE.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


assertions = 0
assert 'BeginPackage["CodexCF300DedicatedContextHydrationGateV1`"]' in text
assert text.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", text)
assert "Internal`InheritedBlock" not in text
assertions += 4

assert 'artifactContext = "CodexCF300DedicatedArtifactGateV1" <>' in text
assert 'artifactContext <> #1, InputForm, HoldComplete' in text
assert 'Block[\n  {$Context = artifactContext, $ContextPath = runtimeContextPath}' in text
assert 'MemberQ[$ContextPath, "Global`"]' in text
assert '"PublicReaderIntentionallyNotCalled" -> True' in text
assert '"DRCAReadCompiledArtifact hardcodes Global context hydration"' in text
assert "CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[" not in text
assertions += 7

assert text.count("Quiet[Check[Get[preparationFile], $Failed]]") == 1
assert text.count("Quiet[Check[Get[cacheFile], $Failed]]") == 1
assert "CodexTripleRootReconstruction`TRPreparationABIValidQ[" in text
assert "CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[" in text
assert "CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[" in text
assert 'fingerprint[exactForms]' in text
assert 'fingerprint[compiledForms]' in text
assertions += 7

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

assert '"x" -> definitionState[Global`x]' in text
assert '"y" -> definitionState[Global`y]' in text
assert '"eps" -> definitionState[Global`eps]' in text
assert 'SameQ[globalStatesBefore, globalStatesAfter]' in text
assert 'globalFingerprintsBefore === expectedGlobalPoisonFingerprints' in text
assertions += 5

for digest in (
    "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
    "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968",
    "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d",
    "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7",
):
    assert text.count(digest) == 1, digest
    assertions += 1

for forbidden in (
    "Unlock[",
    "Unprotect[",
    "Protect[",
    "Lock[",
    "ClearAll[Global`",
    "Clear[Global`",
    "OwnValues[Global`x] =",
    "OwnValues[Global`y] =",
    "OwnValues[Global`eps] =",
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
    f"CF300_DEDICATED_CONTEXT_HYDRATION_GATE_STATIC PASS "
    f"{assertions}/{assertions} gate_sha256={sha256(GATE)}"
)

