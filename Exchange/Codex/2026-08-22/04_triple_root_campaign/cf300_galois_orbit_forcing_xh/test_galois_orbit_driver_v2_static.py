#!/usr/bin/env python3
"""No-kernel hydration and physics-contract audit for adjacent V2."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
V1 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v1.wls"
V2 = HERE / "run_cf300_sector12_galois_orbit_forcing_screen_v2.wls"
MODEL = HERE / "run_hydration_context_poison_model_v1.wls"
FIXTURE = HERE / "hydration_context_fixture_v1.wl"
v1 = V1.read_text()
v2 = V2.read_text()
model = MODEL.read_text()
fixture = FIXTURE.read_text()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


assertions = 0

# V1 is evidence, not a moving target.
assert sha256(V1) == "ca6cae1937f7c9cf9f619010d779a1b6edd1cd4b153b5af182d9581c8a8e46c0"
assertions += 1

assert 'BeginPackage["CodexCF300GaloisOrbitForcingDriverV2`"]' in v2
assert 'Begin["`Private`"]' in v2
assert 'ClearAll["CodexCF300GaloisOrbitForcingDriverV2`Private`*"]' in v2
assert v2.index("BeginPackage[") < v2.index("arguments =")
assert v2.count("System`Exit[") == 1
assert not re.search(r"(?<!System`)\bExit\[", v2)
assertions += 6

# Only the canonical artifact symbols may be explicitly Global. Driver state
# stays in the V2 private context despite the dynamic hydration Block.
global_symbols = set(re.findall(r"Global`([A-Za-z$][A-Za-z0-9$]*)", v2))
assert global_symbols == {"x", "y", "eps"}
assert "Internal`InheritedBlock[{Global`x, Global`y, Global`eps}" in v2
assert 'Block[{$Context = "Global`",' in v2
assert "$ContextPath = canonicalRuntimeContextPath" in v2
assert v2.index("Internal`InheritedBlock[") < v2.index(
    "preparationArtifact = artifactRead[preparationFile]")
assert v2.index("Internal`InheritedBlock[") < v2.index(
    "DRCAReadCompiledArtifact[")
assertions += 6

# Same-kernel poison is cleared reversibly, including attributes, and exact
# canonical symbol identities are demanded at value level.
assert "Unlock[Global`x, Global`y, Global`eps]" in v2
assert "Unprotect[Global`x, Global`y, Global`eps]" in v2
assert "ClearAll[Global`x, Global`y, Global`eps]" in v2
assert '"PreparationVariableContexts"' in v2
assert '{"Global`", "Global`"}' in v2
assert '"PreparationRegulatorContext"' in v2
assertions += 6

# The public reader, raw artifact, preparation and assembly validators are all
# executed inside the canonical block and recorded as value diagnostics.
for key in (
    "PreparationValueValidatorCanonical",
    "RawCacheValueValidatorCanonical",
    "RawAssemblyValueValidatorCanonical",
    "RawAndReaderArtifactsValueIdentical",
    "ReaderArtifactValueValidatorCanonical",
    "ReaderAssemblyValueValidatorCanonical",
    "ReaderStatus",
    "CanonicalHydrationDiagnostics",
):
    assert f'"{key}"' in v2
    assertions += 1
assert "DRCACompiledArtifactValidQ[" in v2
assert "DRCAAssemblyPreparationValidQ[" in v2
assert "TRPreparationABIValidQ[" in v2
assertions += 3

# Both context-sensitive value fingerprints are pinned, recomputed and
# required to match before the expensive orbit census can start.
exact = "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d"
compiled = "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7"
assert exact in v2
assert compiled in v2
assert '"ExactFingerprintValueMatch"' in v2
assert '"CompiledFingerprintValueMatch"' in v2
assert "storedExactFingerprint === canonicalExactFingerprint ===" in v2
assert "storedCompiledFingerprint === canonicalCompiledFingerprint ===" in v2
assert 'finish["PinnedArtifactsOrCanonicalHydrationInvalid"' in v2
assertions += 7

# The physics/census/screen core remains present and is explicitly versioned.
for needle in (
    "signMasks = Range[0, 3]",
    '"KleinFourCompositionExact"',
    '"OrbitDLogExact"',
    "candidateGroups = GatherBy[conjugateCandidates",
    "maxOneForms = Join[baseOneForms",
    "Take[targetScreenMatrix, All, baseUnknownCount]",
    "AIWScoreColumns[",
    "rankImage[targetSample[\"Matrix\"]",
    '"ExactColumnSubsetEmbeddingV2"',
    '"CF300Sector12GaloisOrbitForcingScreenPassedV2"',
):
    assert needle in v2
    assertions += 1
assert v2.count('"ImageID" -> "I') == 4
assertions += 1

# No nested Wolfram parallelism or shell process is introduced.
for forbidden in ("LaunchKernels", "ParallelSubmit", "RunProcess"):
    assert forbidden not in v2
    assertions += 1

# The regression model uses one kernel for poisoned Global symbols, two
# canonical reads, an isolated hydration, context diagnostics and the expected
# canonical-vs-isolated fingerprint mismatch.
assert sha256(FIXTURE) == "300f3a68e77469f6558431fcbe8e0e42e99ae9ecb468965f507a09967c3e09f4"
assert "{x, y}" in fixture and "eps" in fixture
assert "Internal`InheritedBlock[{Global`x, Global`y, Global`eps}" in model
assert "Global`x = 31337" in model
assert "Protect[Global`x, Global`y, Global`eps]" in model
assert model.count("canonicalRead[]") >= 3
assert "isolatedRead[]" in model
assert '"PoisonRestoredAfterFirstCanonicalRead"' in model
assert '"PoisonRestoredAfterSecondCanonicalRead"' in model
assert '"CanonicalVariableContexts"' in model
assert '"IsolatedVariableContexts"' in model
assert '"CanonicalVsIsolatedFingerprintDifferent"' in model
assertions += 12

print(
    f"CF300_GALOIS_ORBIT_V2_STATIC PASS {assertions}/{assertions} "
    f"v2_sha256={sha256(V2)} model_sha256={sha256(MODEL)}"
)
