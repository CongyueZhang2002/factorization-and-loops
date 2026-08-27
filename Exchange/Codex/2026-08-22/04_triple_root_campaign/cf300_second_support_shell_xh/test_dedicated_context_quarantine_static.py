#!/usr/bin/env python3
"""Static, no-kernel checks for dedicated hydration and pool quarantine."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
HYDRATION = HERE / "run_cf300_artifact_hydration_dedicated_context_probe_v1.wls"
HYDRATION_V2 = HERE / "run_cf300_artifact_hydration_dedicated_context_probe_v2.wls"
HYDRATION_V3 = HERE / "run_cf300_artifact_hydration_dedicated_context_probe_v3.wls"
QUARANTINE = HERE / "run_kernel_pool_quarantine_nomutation_v1.wls"
QUARANTINE_V2 = HERE / "run_kernel_pool_quarantine_nomutation_v2.wls"

EXPECTED = {
    HYDRATION.name: "7062e60b08b9c548a4a29b582202ef5e6d0b812eeab6cf3d84557ed306bdc81b",
    HYDRATION_V2.name: "10f3240038d950f357ffd30e62ab66f698ec0565782689420b36d41bd92e36fc",
    HYDRATION_V3.name: "50a972175f173f2a47eb4731bbfb66377429b4a57540bd0855ee2f785f19ce34",
    QUARANTINE.name: "3bb4bbd6593c97df10c5bb6697cfb2af2635f22fb20ac58e5c80fc6a590406bc",
    QUARANTINE_V2.name: "52c04ec384284fa288e5297c60c4113adbe1d2d4420d2351509761a52c2c13b7",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


hydration = HYDRATION.read_text()
hydration_v2 = HYDRATION_V2.read_text()
hydration_v3 = HYDRATION_V3.read_text()
quarantine = QUARANTINE.read_text()
quarantine_v2 = QUARANTINE_V2.read_text()
assert sha256(HYDRATION) == EXPECTED[HYDRATION.name]
assert sha256(HYDRATION_V2) == EXPECTED[HYDRATION_V2.name]
assert sha256(HYDRATION_V3) == EXPECTED[HYDRATION_V3.name]
assert sha256(QUARANTINE) == EXPECTED[QUARANTINE.name]
assert sha256(QUARANTINE_V2) == EXPECTED[QUARANTINE_V2.name]

assert 'artifactContext = "CodexCF300ArtifactSymbolsHydrationProbeV1`";' in hydration
assert '$Context = artifactContext' in hydration
assert '"System`", artifactContext' in hydration
assert "artifactReadActive[preparationFile]" in hydration
assert "artifactReadActive[cacheFile]" in hydration
assert "artifactReadValidatedActive[cacheFile]" in hydration
assert "DRCACompiledArtifactValidQ[" in hydration
assert "DRCAAssemblyPreparationValidQ[" in hydration
assert "TRPreparationABIValidQ[" in hydration
assert '"DedicatedExactFingerprintMatchesStoredQ"' in hydration
assert '"DedicatedContextRemovedQ"' in hydration
assert 'Remove[artifactContext <> "*"]' in hydration

# The package reader is unusable on a poisoned persistent kernel because it
# hardcodes Global`.  This gate must never call it, even diagnostically.
assert "DRCAReadCompiledArtifact" not in hydration
assert "Internal`InheritedBlock" not in hydration

# V2 is message-tolerant: benign messages are telemetry, while public
# validators and exact fingerprints remain the fail-closed value gates.
assert "artifactReadWithTelemetryActive" in hydration_v2
assert "Quiet[CheckAbort[Get[file], $Aborted]]" in hydration_v2
telemetry_reader = hydration_v2.split(
    "artifactReadWithTelemetryActive", 1
)[1].split("globalDefinitionSnapshot", 1)[0]
assert "Quiet[Check[Get[file], $Failed]]" not in telemetry_reader
assert '$MessageList = {}' in hydration_v2
assert '"PreparationReadTelemetry"' in hydration_v2
assert '"CacheReadTelemetry"' in hydration_v2
assert '"CensusReadTelemetry"' in hydration_v2
assert '{"eps", "v", "w", "x", "y"}' in hydration_v2
assert '"DedicatedNamespaceExactQ"' in hydration_v2
assert "DRCAReadCompiledArtifact" not in hydration_v2
assert "Internal`InheritedBlock" not in hydration_v2

# V3 fixes the HoldAll indirection bug in the V2 definition-free audit.
assert "SetAttributes[definitionFreeHeldQ, HoldAll]" in hydration_v3
assert "definitionFreeHeldQ[symbol_Symbol]" in hydration_v3
assert "Function[heldSymbol, definitionFreeHeldQ[heldSymbol], HoldAll]" in hydration_v3
assert "Module[{symbol = Symbol[name]}" not in hydration_v3
assert "DRCAReadCompiledArtifact" not in hydration_v3

# Every explicit reference to the poisoned symbols is a read-only definition
# table/attribute snapshot.  No mutator may target them.
global_refs = re.findall(r"(?m)^.*Global`(?:x|y|eps).*$", hydration)
assert len(global_refs) == 24
allowed_read = re.compile(
    r"(?:OwnValues|DownValues|UpValues|SubValues|NValues|"
    r"DefaultValues|FormatValues|Attributes)\[Global`(?:x|y|eps)\]"
)
assert all(allowed_read.search(line) for line in global_refs)
assert not re.search(
    r"(?:Clear|ClearAll|Remove|Unprotect|Protect|SetAttributes|"
    r"OwnValues|DownValues|UpValues|SubValues|NValues|DefaultValues|"
    r"FormatValues|Attributes)\[Global`(?:x|y|eps)\]\s*=",
    hydration,
)
assert not re.search(
    r"(?:Clear|ClearAll|Remove|Unprotect|Protect|SetAttributes)\s*\["
    r"[^\]]*Global`(?:x|y|eps)",
    hydration,
)

# The quarantine is bounded, parser-safe, helper-free, and read-only on the
# filesystem.  A separate controller creates the sentinel to release it.
assert "ToExpression" not in quarantine
assert "parseUnsignedInteger" in quarantine
assert 'RegularExpression["[A-Za-z0-9_.:-]{16,128}"]' in quarantine
assert "AbsoluteTime[] < deadline" in quarantine
assert "FileExistsQ[sentinelFile]" in quarantine
assert "Pause[" in quarantine
assert "FileHash[driverFile" in quarantine
assert "Global`" not in quarantine
for forbidden in (
    "LaunchKernels",
    "ParallelSubmit",
    "RunProcess",
    "StartProcess",
    "KillProcess",
    "SetProcessorAffinity",
    "Put[",
    "PutAppend[",
    "Export[",
    "DeleteFile[",
    "RenameFile[",
    "CreateFile[",
    "CreateDirectory[",
):
    assert forbidden not in quarantine

# V2 may reserve only the known poisoned pool kernel and must prove the exact
# poison fingerprints before the first Pause, then recheck them periodically.
assert "requiredKernelID = 144;" in quarantine_v2
assert '"ObservedKernelID" -> $KernelID' in quarantine_v2
assert 'SameQ[$KernelID, expectedKernelID]' in quarantine_v2
for digest in (
    "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
    "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968",
):
    assert quarantine_v2.count(digest) == 1
assert quarantine_v2.index('Print["KERNEL_POOL_QUARANTINE preflight="') < (
    quarantine_v2.index("Pause[")
)
assert quarantine_v2.index('preflight["PoisonFingerprintsMatchQ"]') < (
    quarantine_v2.index("Pause[")
)
assert "currentFingerprints = poisonFingerprints[currentStates]" in quarantine_v2
assert 'releaseReason = "PoisonFingerprintDrift"' in quarantine_v2
assert "ToExpression" not in quarantine_v2
quarantine_v2_global_refs = re.findall(
    r"(?m)^.*Global`(?:x|y|eps).*$", quarantine_v2
)
assert len(quarantine_v2_global_refs) == 24
assert all(allowed_read.search(line) for line in quarantine_v2_global_refs)
assert not re.search(
    r"(?:Clear|ClearAll|Remove|Unprotect|Protect|SetAttributes)\s*\["
    r"[^\]]*Global`(?:x|y|eps)",
    quarantine_v2,
)
for forbidden in (
    "LaunchKernels",
    "ParallelSubmit",
    "RunProcess",
    "StartProcess",
    "KillProcess",
    "SetProcessorAffinity",
    "Put[",
    "PutAppend[",
    "Export[",
    "DeleteFile[",
    "RenameFile[",
    "CreateFile[",
    "CreateDirectory[",
):
    assert forbidden not in quarantine_v2

for source in (hydration, quarantine):
    assert not re.search(r"`[ \t]+$", source, flags=re.MULTILINE)
    assert not re.search(r"[ \t]+$", source, flags=re.MULTILINE)

v2_global_refs = re.findall(r"(?m)^.*Global`(?:x|y|eps).*$", hydration_v2)
assert len(v2_global_refs) == 24
assert all(allowed_read.search(line) for line in v2_global_refs)
assert not re.search(
    r"(?:Clear|ClearAll|Remove|Unprotect|Protect|SetAttributes)\s*\["
    r"[^\]]*Global`(?:x|y|eps)",
    hydration_v2,
)
assert not re.search(r"`[ \t]+$", hydration_v2, flags=re.MULTILINE)
assert not re.search(r"[ \t]+$", hydration_v2, flags=re.MULTILINE)

v3_global_refs = re.findall(r"(?m)^.*Global`(?:x|y|eps).*$", hydration_v3)
assert len(v3_global_refs) == 24
assert all(allowed_read.search(line) for line in v3_global_refs)
assert not re.search(
    r"(?:Clear|ClearAll|Remove|Unprotect|Protect|SetAttributes)\s*\["
    r"[^\]]*Global`(?:x|y|eps)",
    hydration_v3,
)
assert not re.search(r"`[ \t]+$", hydration_v3, flags=re.MULTILINE)
assert not re.search(r"[ \t]+$", hydration_v3, flags=re.MULTILINE)
assert not re.search(r"`[ \t]+$", quarantine_v2, flags=re.MULTILINE)
assert not re.search(r"[ \t]+$", quarantine_v2, flags=re.MULTILINE)

print("CF300_DEDICATED_CONTEXT_QUARANTINE_STATIC PASS 93/93")
