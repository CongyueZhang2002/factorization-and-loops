#!/usr/bin/env python3
"""No-kernel audit of V3 cleanup and the exact-state poison model."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
V1 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v1.wls"
V2 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v2.wls"
V3 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v3.wls"
MODEL1 = HERE / "run_hydration_context_poison_model_v1.wls"
MODEL2 = HERE / "run_hydration_context_poison_model_v2.wls"
FIXTURE = HERE / "hydration_context_fixture_v1.wl"
v3 = V3.read_text()
model2 = MODEL2.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


assertions = 0

preserved = {
    V1: "ca6cae1937f7c9cf9f619010d779a1b6edd1cd4b153b5af182d9581c8a8e46c0",
    V2: "5b2238dde9ecdc77d9114f97955ce700aa4308ccbcbc73ddfa22f6e47ade91de",
    MODEL1: "3d2b1bdfa89628a9098885bea6097c54d591666af723f5db6008e5cb6870a630",
    FIXTURE: "300f3a68e77469f6558431fcbe8e0e42e99ae9ecb468965f507a09967c3e09f4",
}
for path, expected in preserved.items():
    assert sha256(path) == expected, path
    assertions += 1

assert 'BeginPackage["CodexCF300GaloisOrbitForcingDriverV3`"]' in v3
assert 'Begin["`Private`"]' in v3
assert 'ClearAll["CodexCF300GaloisOrbitForcingDriverV3`Private`*"]' in v3
assert v3.index("BeginPackage[") < v3.index("arguments =")
assertions += 4

# System Exit occurs only in the final dispatcher. Inside the sanitized scope,
# finish requests are private tagged throws, caught before cleanup returns.
assert v3.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", v3)
assert "driverExitScopeActive = False" in v3
assert "Throw[code, driverExitTag]" in v3
assert "Catch[" in v3 and "driverExitTag" in v3
assert '"CF300GaloisOrbitDriverExitRequestedV3"' in v3
assert "scopeOutcome = withCanonicalGlobalArtifactSymbols[" in v3
assert v3.rindex("cf300GaloisOrbitDriverV3SystemExit[") > v3.index(
    "scopeOutcome = withCanonicalGlobalArtifactSymbols[")
assertions += 8

# V3 explicitly compensates for the demonstrated InheritedBlock limitation:
# values are inherited/localized, while original attributes are snapshotted
# and restored in WithLocalSettings cleanup, with Locked applied last.
assert "SetAttributes[withCanonicalGlobalArtifactSymbols, HoldAll]" in v3
assert "Internal`WithLocalSettings[" in v3
assert "Internal`InheritedBlock[{Global`x, Global`y, Global`eps}" in v3
assert "xState = symbolDefinitionState[Global`x]" in v3
assert "yState = symbolDefinitionState[Global`y]" in v3
assert "epsilonState = symbolDefinitionState[Global`eps]" in v3
assert 'xAttributes = xState["Attributes"]' in v3
assert 'yAttributes = yState["Attributes"]' in v3
assert 'epsilonAttributes = epsilonState["Attributes"]' in v3
assert "Attributes[Global`x] = DeleteCases[xAttributes, Locked]" in v3
assert "Attributes[Global`y] = DeleteCases[yAttributes, Locked]" in v3
assert "Attributes[Global`eps] = DeleteCases[epsilonAttributes, Locked]" in v3
assert "If[MemberQ[xAttributes, Locked], Lock[Global`x]]" in v3
assert "If[MemberQ[yAttributes, Locked], Lock[Global`y]]" in v3
assert "If[MemberQ[epsilonAttributes, Locked], Lock[Global`eps]]" in v3
assert "driverCleanupVerified = And[" in v3
assert "SameQ[symbolDefinitionState[Global`x], xState]" in v3
assert "SameQ[symbolDefinitionState[Global`y], yState]" in v3
assert "SameQ[symbolDefinitionState[Global`eps], epsilonState]" in v3
assert "If[! TrueQ[driverCleanupVerified]" in v3
assert v3.index("Internal`InheritedBlock[") < v3.index(
    "Attributes[Global`x] = DeleteCases[xAttributes, Locked]")
assertions += 21

# Canonical value-level hydration gates and both pinned fingerprints survive.
for needle in (
    '"PreparationValueValidatorCanonical"',
    '"RawCacheValueValidatorCanonical"',
    '"RawAssemblyValueValidatorCanonical"',
    '"RawAndReaderArtifactsValueIdentical"',
    '"ReaderArtifactValueValidatorCanonical"',
    '"ReaderAssemblyValueValidatorCanonical"',
    '"ExactFingerprintValueMatch"',
    '"CompiledFingerprintValueMatch"',
    "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d",
    "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7",
):
    assert needle in v3
    assertions += 1

# The physics and maximal-subset screen remains versioned and intact.
for needle in (
    "signMasks = Range[0, 3]",
    '"KleinFourCompositionExact"',
    '"OrbitDLogExact"',
    "candidateGroups = GatherBy[conjugateCandidates",
    "maxOneForms = Join[baseOneForms",
    "Take[targetScreenMatrix, All, baseUnknownCount]",
    "AIWScoreColumns[",
    "rankImage[targetSample[\"Matrix\"]",
    '"ExactColumnSubsetEmbeddingV3"',
    '"CF300Sector12GaloisOrbitForcingScreenPassedV3"',
):
    assert needle in v3
    assertions += 1
assert v3.count('"ImageID" -> "I') == 4
assertions += 1

for forbidden in ("LaunchKernels", "ParallelSubmit", "RunProcess"):
    assert forbidden not in v3
    assertions += 1

# V2 model compares exact state components rather than the context-sensitive
# aggregate hashes that made V1's restoration diagnosis ambiguous.
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
    assert f'"{key}"' in model2
    assertions += 1
assert "SetAttributes[Global`x, {Protected, Locked}]" in model2
assert "SetAttributes[Global`y, {Protected, Locked}]" in model2
assert "SetAttributes[Global`eps, {Protected, Locked}]" in model2
assert "SameQ[poisonXAfterFirst, poisonXBefore]" in model2
assert "SameQ[poisonYAfterFirst, poisonYBefore]" in model2
assert "SameQ[poisonEpsilonAfterFirst, poisonEpsilonBefore]" in model2
assert "SameQ[poisonXAfterSecond, poisonXBefore]" in model2
assert "SameQ[poisonXAfterCleanupThrow, poisonXBefore]" in model2
assert 'Throw["ExpectedCleanupProbeThrow", cleanupProbeTag]' in model2
assert '"CallerXStateRestoredAfterModelScope"' in model2
assert '"CallerYStateRestoredAfterModelScope"' in model2
assert '"CallerEpsilonStateRestoredAfterModelScope"' in model2
assert '"CanonicalVsIsolatedFingerprintDifferent"' in model2
assert '"LegacyRestorationByExactComponent"' in model2
assert '"LegacyAttributeOnlyFailureObserved"' in model2
assert "legacyRestorationByComponent = AssociationMap[" in model2
assertions += 16

print(
    f"CF300_GALOIS_ORBIT_V3_STATIC PASS {assertions}/{assertions} "
    f"v3_sha256={sha256(V3)} model_v2_sha256={sha256(MODEL2)}"
)
