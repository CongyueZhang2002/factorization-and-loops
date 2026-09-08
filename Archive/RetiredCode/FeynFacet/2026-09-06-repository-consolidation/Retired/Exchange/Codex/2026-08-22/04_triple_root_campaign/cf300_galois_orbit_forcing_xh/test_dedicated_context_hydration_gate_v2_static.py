#!/usr/bin/env python3
"""Static audit for adjacent dedicated-context hydration gate V2."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
V1 = HERE / "run_cf300_dedicated_context_hydration_gate_v1.wls"
V2 = HERE / "run_cf300_dedicated_context_hydration_gate_v2.wls"
v2 = V2.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


assertions = 0
assert sha256(V1) == "82436c2c95a63095454d2285ec998fd78165a58fe92229148bdca740ea64a016"
assert 'BeginPackage["CodexCF300DedicatedContextHydrationGateV2`"]' in v2
assert v2.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", v2)
assert "Internal`InheritedBlock" not in v2
assertions += 5

assert 'artifactContext <> #1,\n    InputForm, HoldComplete] & /@ {"v", "w", "x", "y", "eps"}' in v2
assert 'expectedArtifactNames = artifactContext <> #1 & /@\n  {"v", "w", "x", "y", "eps"}' in v2
assert 'Block[{$Context = artifactContext, $ContextPath = runtimePath}' in v2
assert 'MemberQ[$ContextPath, "Global`"]' in v2
assertions += 4

assert "rawReadWithDiagnostics[file_String]" in v2
assert 'Block[{$MessageList = {}}' in v2
assert 'value = Quiet[CheckAbort[Get[file], $Aborted]]' in v2
assert '"ValueHead" -> ToString[Head[value], InputForm]' in v2
assert '"ValueSameQFailed" -> SameQ[value, $Failed]' in v2
assert '"ValueSameQAborted" -> SameQ[value, $Aborted]' in v2
assert '"MessageCount" -> Length[messages]' in v2
assert '"Messages" -> messages' in v2
assert "Quiet[Check[Get[file], $Failed]]" not in v2
assertions += 9

assert '"LoadFACETPinnedButIntentionallyNotLoaded" -> True' in v2
assert '"InitializationMatchesPriorSuccessfulHydrationProbe" -> True' in v2
assert '"PublicReaderIntentionallyNotCalled" -> True' in v2
assert "CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[" not in v2
assert "CodexTripleRootReconstruction`TRPreparationABIValidQ[" in v2
assert "CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[" in v2
assert "CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[" in v2
assertions += 7

assert '"x" -> definitionState[Global`x]' in v2
assert '"y" -> definitionState[Global`y]' in v2
assert '"eps" -> definitionState[Global`eps]' in v2
assert 'SameQ[globalBefore, globalAfter]' in v2
assert 'globalFingerprintsBefore === expectedGlobalPoisonFingerprints' in v2
assertions += 5

for digest in (
    "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
    "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968",
    "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d",
    "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7",
):
    assert v2.count(digest) == 1, digest
    assertions += 1

for forbidden in (
    "Unlock[",
    "Unprotect[",
    "Protect[",
    "Lock[",
    "ClearAll[Global`",
    "Clear[Global`",
    "Put[",
    "Export[",
    "RunProcess[",
    "StartProcess[",
    "LaunchKernels",
    "ParallelSubmit",
    "KillProcess",
):
    assert forbidden not in v2, forbidden
    assertions += 1

print(
    f"CF300_DEDICATED_CONTEXT_HYDRATION_GATE_V2_STATIC PASS "
    f"{assertions}/{assertions} v2_sha256={sha256(V2)}"
)
