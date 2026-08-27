#!/usr/bin/env python3
"""No-kernel audit of the dedicated-context CF300 Galois V4 driver."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
V1 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v1.wls"
V2 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v2.wls"
V3 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v3.wls"
V4 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v4.wls"
v4 = V4.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


assertions = 0
for path, expected in {
    V1: "ca6cae1937f7c9cf9f619010d779a1b6edd1cd4b153b5af182d9581c8a8e46c0",
    V2: "5b2238dde9ecdc77d9114f97955ce700aa4308ccbcbc73ddfa22f6e47ade91de",
    V3: "8952afbda47958104eb473a4c24705283f517ba6a58816eec9d194d0f294e265",
}.items():
    assert sha256(path) == expected, path
    assertions += 1

assert 'BeginPackage["CodexCF300GaloisOrbitForcingDriverV4`"]' in v4
assert 'Begin["`Private`"]' in v4
assert 'ClearAll["CodexCF300GaloisOrbitForcingDriverV4`Private`*"]' in v4
assert v4.index("BeginPackage[") < v4.index("arguments =")
assertions += 4

assert v4.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", v4)
assert 'Throw[<|"Status" -> "CF300GaloisOrbitDriverExitRequestedV4"' in v4
assert "scopeOutcome = Internal`WithLocalSettings[" in v4
assert "Catch[" in v4 and "driverExitTag" in v4
assert '"CF300GaloisOrbitDriverExitRequestedV4"' in v4
assert v4.rindex("cf300GaloisOrbitDriverV4SystemExit[") > v4.index(
    "scopeOutcome = Internal`WithLocalSettings["
)
assertions += 7

# Artifact variables are precreated in a unique non-Global context. That same
# context remains visible for raw Get, all public validators, rebind and every
# sampler call because the complete physics body is inside one dynamic Block.
assert 'artifactContext = "CodexCF300GaloisOrbitArtifactV4`"' in v4
assert 'artifactContextPattern = "CodexCF300GaloisOrbitArtifactV4`*"' in v4
assert 'artifactContext <> #1, InputForm, HoldComplete' in v4
assert '{"v", "w", "x", "y", "eps"}' in v4
assert 'artifactNamesBeforeCreation = Names[artifactContextPattern]' in v4
assert "dedicatedArtifactRuntimeContextPath = {\n  artifactContext," in v4
assert 'Block[{$Context = artifactContext,' in v4
assert '$ContextPath = dedicatedArtifactRuntimeContextPath}' in v4
assert v4.index('Block[{$Context = artifactContext,') < v4.index(
    "preparationArtifact = artifactRead[preparationFile]"
)
assert v4.index('Block[{$Context = artifactContext,') < v4.index(
    "CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz["
)
assert v4.index('Block[{$Context = artifactContext,') < v4.index(
    "CodexDirectRootChannelAssembler`DRCAAssembleSample["
)
assert v4.index("finish[\"CF300Sector12GaloisOrbitForcingScreenPassedV4\"") < v4.index(
    "artifactDefinitionsAfterScope = artifactDefinitionStates[]"
)
assertions += 11

for forbidden in (
    "Global`x",
    "Global`y",
    "Global`eps",
    "Internal`InheritedBlock",
    "Unlock[",
    "Unprotect[",
    "Protect[",
    "Lock[",
    "DRCAReadCompiledArtifact[",
):
    assert forbidden not in v4, forbidden
    assertions += 1

assert '"PublicReaderIntentionallyNotCalled" -> True' in v4
assert '"DRCAReadCompiledArtifact hardcodes Global context hydration"' in v4
assert 'MemberQ[$ContextPath, "Global`"]' in v4
assert '"DedicatedArtifactSymbolsExactlyVWXYEpsilon"' in v4
assert '"DedicatedArtifactSymbolsDefinitionFree"' in v4
assert 'artifactSymbolsDefinitionFreeAfterScope = TrueQ[' in v4
assert "callerContextRestoredAfterScope = TrueQ[" in v4
assert 'Context[Evaluate[hydratedRegulator]]' in v4
assert 'Remove["CodexCF300GaloisOrbitArtifactV4`*"]' in v4
assert 'Names["CodexCF300GaloisOrbitArtifactV4`*"] === {}' in v4
assert 'artifactContextRemovedAfterScope' in v4
assert 'Quiet[CheckAbort[Get[file], $Aborted]]' in v4
assert 'Quiet[Check[Get[file], $Failed]]' not in v4
assertions += 13

for needle in (
    '"PreparationValueValidatorDedicatedContext"',
    '"RawCacheValueValidatorDedicatedContext"',
    '"RawAssemblyValueValidatorDedicatedContext"',
    '"ExactFingerprintValueMatch"',
    '"CompiledFingerprintValueMatch"',
    "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d",
    "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7",
):
    assert needle in v4
    assertions += 1

# Physics, exact orbit identities, maximal pure-superset construction and
# finite-field screen remain intact.
for needle in (
    "signMasks = Range[0, 3]",
    '"KleinFourCompositionExact"',
    '"OrbitDLogExact"',
    "candidateGroups = GatherBy[conjugateCandidates",
    "maxOneForms = Join[baseOneForms",
    "Take[targetScreenMatrix, All, baseUnknownCount]",
    "AIWScoreColumns[",
    'rankImage[targetSample["Matrix"]',
    '"ExactColumnSubsetEmbeddingV4"',
    '"CF300Sector12GaloisOrbitForcingScreenPassedV4"',
):
    assert needle in v4
    assertions += 1
assert v4.count('"ImageID" -> "I') == 4
assertions += 1

# The certificate distinguishes the exact column-deletion implication from
# whether every tested image actually rejected the maximal system.
assert '"ColumnDeletionImplicationExact" -> True' in v4
assert '"SubsetRejectionCertifiedByImage" -> subsetRejectionByImage' in v4
assert '"EveryTestedImageRejectsEveryLetterSubset" ->' in v4
assert 'everyImageRejectsMaximalOrbitAnsatz = AllTrue[imageResults' in v4
assert '"MaximalRejectsEveryLetterSubsetAtAnInconsistentImage" -> True' not in v4
assertions += 5

for forbidden in ("LaunchKernels", "ParallelSubmit", "RunProcess"):
    assert forbidden not in v4
    assertions += 1

print(
    f"CF300_GALOIS_ORBIT_V4_STATIC PASS {assertions}/{assertions} "
    f"v4_sha256={sha256(V4)}"
)
