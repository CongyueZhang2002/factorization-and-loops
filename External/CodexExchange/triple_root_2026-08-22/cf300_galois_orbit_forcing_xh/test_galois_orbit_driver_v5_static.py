#!/usr/bin/env python3
"""No-kernel audit of the dedicated-context CF300 Galois V5 driver."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
V1 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v1.wls"
V2 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v2.wls"
V3 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v3.wls"
V4 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v4.wls"
V5 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v5.wls"
v5 = V5.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


assertions = 0
for path, expected in {
    V1: "ca6cae1937f7c9cf9f619010d779a1b6edd1cd4b153b5af182d9581c8a8e46c0",
    V2: "5b2238dde9ecdc77d9114f97955ce700aa4308ccbcbc73ddfa22f6e47ade91de",
    V3: "8952afbda47958104eb473a4c24705283f517ba6a58816eec9d194d0f294e265",
    V4: "583475964908ad09ede6d24f2bed547817cde16146af4f6a21bbfb8954dc2976",
}.items():
    assert sha256(path) == expected, path
    assertions += 1

assert 'BeginPackage["CodexCF300GaloisOrbitForcingDriverV5`"]' in v5
assert 'Begin["`Private`"]' in v5
assert 'ClearAll["CodexCF300GaloisOrbitForcingDriverV5`Private`*"]' in v5
assert v5.index("BeginPackage[") < v5.index("arguments =")
assertions += 4

assert v5.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", v5)
assert 'Throw[<|"Status" -> "CF300GaloisOrbitDriverExitRequestedV5"' in v5
assert "scopeOutcome = Internal`WithLocalSettings[" in v5
assert "Catch[" in v5 and "driverExitTag" in v5
assert '"CF300GaloisOrbitDriverExitRequestedV5"' in v5
assert v5.rindex("cf300GaloisOrbitDriverV5SystemExit[") > v5.index(
    "scopeOutcome = Internal`WithLocalSettings["
)
assertions += 7

# Artifact variables are precreated in a unique non-Global context. That same
# context remains visible for raw Get, all public validators, rebind and every
# sampler call because the complete physics body is inside one dynamic Block.
assert 'artifactContext = "CodexCF300GaloisOrbitArtifactV5`"' in v5
assert 'artifactContextPattern = "CodexCF300GaloisOrbitArtifactV5`*"' in v5
assert 'artifactContext <> #1, InputForm, HoldComplete' in v5
assert '{"v", "w", "x", "y", "eps"}' in v5
assert 'artifactNamesBeforeCreation = Names[artifactContextPattern]' in v5
assert "dedicatedArtifactRuntimeContextPath = {\n  artifactContext," in v5
assert 'Block[{$Context = artifactContext,' in v5
assert '$ContextPath = dedicatedArtifactRuntimeContextPath}' in v5
assert v5.index('Block[{$Context = artifactContext,') < v5.index(
    "preparationArtifact = artifactRead[preparationFile]"
)
assert v5.index('Block[{$Context = artifactContext,') < v5.index(
    "CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz["
)
assert v5.index('Block[{$Context = artifactContext,') < v5.index(
    "CodexDirectRootChannelAssembler`DRCAAssembleSample["
)
assert v5.index("finish[\"CF300Sector12GaloisOrbitForcingScreenPassedV5\"") < v5.index(
    "artifactNamesAfterScope = Names[artifactContextPattern]"
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
    assert forbidden not in v5, forbidden
    assertions += 1

assert '"PublicReaderIntentionallyNotCalled" -> True' in v5
assert '"DRCAReadCompiledArtifact hardcodes Global context hydration"' in v5
assert 'MemberQ[$ContextPath, "Global`"]' in v5
assert '"DedicatedArtifactNamespaceBeforeHydrationExact"' in v5
assert '"DedicatedArtifactNamespaceAfterHydrationExact"' in v5
assert '"DedicatedArtifactSymbolsDefinitionFree"' in v5
assert 'artifactSymbolsDefinitionFreeAfterScope = TrueQ[' in v5
assert "callerContextRestoredAfterScope = TrueQ[" in v5
assert 'Context[Evaluate[hydratedRegulator]]' in v5
assert 'Remove["CodexCF300GaloisOrbitArtifactV5`*"]' in v5
assert 'Names["CodexCF300GaloisOrbitArtifactV5`*"] === {}' in v5
assert 'artifactContextRemovedAfterScope' in v5
assert 'Quiet[CheckAbort[Get[file], $Aborted]]' in v5
assert 'Quiet[Check[Get[file], $Failed]]' not in v5
assertions += 14

# Names may shorten qualified names while artifactContext is on ContextPath.
# V5 canonicalizes every returned string, resolves it under HoldAll, and proves
# exact Context/SymbolName/FullName identities rather than comparing strings.
assert 'artifactQualifiedName[name_String] := If[StringContainsQ[name, "`"],' in v5
assert 'SetAttributes[artifactSymbolIdentityHeld, HoldAll]' in v5
assert '"Context" -> Context[symbol]' in v5
assert '"SymbolName" -> SymbolName[symbol]' in v5
assert '"FullName" -> Context[symbol] <> SymbolName[symbol]' in v5
assert 'artifactSymbolIdentityByName[name_String] := ToExpression[' in v5
assert 'artifactNamespaceAudit[names_List] := Module[' in v5
assert '"ExactOwnedNamespaceQ" -> exactQ' in v5
assert 'AllTrue[Lookup[identityValues, "Context", $Failed],' in v5
assert 'Sort[Lookup[identityValues, "SymbolName", $Failed]] ===' in v5
assert 'artifactNamespaceAfterHydrationAudit = artifactNamespaceAudit[' in v5
assert 'artifactNamespaceAfterScopeAudit = artifactNamespaceAudit[' in v5
assert 'artifactDefinitionStatesFromNames[artifactNamesAfterHydration]' in v5
assert 'artifactDefinitionStatesFromNames[artifactNamesAfterScope]' in v5
assert 'Sort[artifactNamesAfterHydration]' not in v5
assert 'Sort[Keys[artifactDefinitionsAfterScope]]' not in v5
assertions += 16

for needle in (
    '"PreparationValueValidatorDedicatedContext"',
    '"RawCacheValueValidatorDedicatedContext"',
    '"RawAssemblyValueValidatorDedicatedContext"',
    '"ExactFingerprintValueMatch"',
    '"CompiledFingerprintValueMatch"',
    "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d",
    "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7",
):
    assert needle in v5
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
    '"ExactColumnSubsetEmbeddingV5"',
    '"CF300Sector12GaloisOrbitForcingScreenPassedV5"',
):
    assert needle in v5
    assertions += 1
assert v5.count('"ImageID" -> "I') == 4
assertions += 1

# The certificate distinguishes the exact column-deletion implication from
# whether every tested image actually rejected the maximal system.
assert '"ColumnDeletionImplicationExact" -> True' in v5
assert '"SubsetRejectionCertifiedByImage" -> subsetRejectionByImage' in v5
assert '"EveryTestedImageRejectsEveryLetterSubset" ->' in v5
assert 'everyImageRejectsMaximalOrbitAnsatz = AllTrue[imageResults' in v5
assert '"MaximalRejectsEveryLetterSubsetAtAnInconsistentImage" -> True' not in v5
assertions += 5

for forbidden in ("LaunchKernels", "ParallelSubmit", "RunProcess"):
    assert forbidden not in v5
    assertions += 1

print(
    f"CF300_GALOIS_ORBIT_V5_STATIC PASS {assertions}/{assertions} "
    f"v5_sha256={sha256(V5)}"
)
