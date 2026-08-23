#!/usr/bin/env python3
"""No-Wolfram adversarial source audit for the CF300 sector-12 recapture."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


REPO = Path("/home/maxzhang/factorization-and-loops")
HERE = Path(__file__).resolve().parent
WRAPPER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v1.wls"
SOURCE_MANIFEST = HERE / "CF300_RESUME_SOURCE_SHA256SUMS"
VALIDATOR = HERE / "validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls"
VALIDATOR_EVIDENCE = HERE / "cf300_s11_postwrite_validator_xh_v2_OK.log"
FORMAL_INSPECTOR = HERE / "inspect_cf300_sector11_postwrite_v4.py"
FORMAL_RESULT = HERE / "cf300_sector11_postwrite_formal_inspector_v4_result.json"
V4_STATE = REPO / (
    "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/"
    "FamilyEpsFormsSolving/triple_root_2026-08-23/"
    "CF300_direct_regulator_v4_candidate/sector_state_CF300_standard.wl"
)
V4_REPORT = V4_STATE.parent / "cf300_sector11_direct_regulator_report_v4.wl"
OUTDIR = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_sector12_recapture_from_v4_xh_v1"
)
EXPECTED = {
    WRAPPER: "e0456c5e0472cceeb982dac23ce78af632846a062dbe6ecdc8527929c96a21fe",
    SOURCE_MANIFEST: "880c4f7850b2c0daf5c207e96df23113c91d75d1056e23c6edc169aec66487b2",
    VALIDATOR: "304e7748e3971e9b0bf50fc84b10f50cda8231d49d6df235327134a297c45759",
    VALIDATOR_EVIDENCE: "185d009d9ed4a56037c3360a14862b97e8e39cfbe8e591c5d6bc38d936d45f3e",
    FORMAL_INSPECTOR: "554248efd8e62d293c8a4bfcef0e6774945b36b43965a8a65297d9609b764a8b",
    FORMAL_RESULT: "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128",
    V4_STATE: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V4_REPORT: "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


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


def parse_manifest(path: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for line in path.read_text().splitlines():
        digest, relative = line.split(None, 1)
        assert re.fullmatch(r"[0-9a-f]{64}", digest)
        assert not relative.startswith("/")
        assert ".." not in Path(relative).parts
        assert relative not in entries
        entries[relative] = digest
    return entries


def launch_contract_ok(source: str) -> bool:
    required = (
        '"FACET_KERNEL_COUNT" -> "1"',
        '"FACET_TASK_BROKER_MAX_HELPERS" -> "0"',
        '"FACET_CHECK_LEVEL" -> "Production"',
        '"FACET_STRIP_ROUTE" -> "FiniteFieldFirst"',
        '"FACET_RECORD_STRIP_ONLY" -> "True"',
        '"FACET_RESUME_HYDRATION" -> "True"',
        '{driver, "CF300", outdir, "7200", "standard",',
        '"30", "", familyDataDirectory, classFormDirectory}',
    )
    return all(item in source for item in required)


def classify_driver_exit(captured: bool, payload: object) -> str:
    if captured and payload == ("EXIT", 75):
        return "accept"
    if captured:
        return "rethrow"
    return "fail"


for path, expected_hash in EXPECTED.items():
    assert path.is_file(), path
    assert sha256(path) == expected_hash, path
assert not OUTDIR.exists(), OUTDIR

manifest = parse_manifest(SOURCE_MANIFEST)
assert len(manifest) == 69
for relative, expected_hash in manifest.items():
    artifact = REPO / relative
    assert artifact.is_file(), artifact
    assert sha256(artifact) == expected_hash, artifact

source = WRAPPER.read_text()
assert balanced_wolfram_delimiters(source)
assert not re.search(r"[ \t]+$", source, flags=re.MULTILINE)
assert launch_contract_ok(source)
assert 'expectedManifestHash =' in source and EXPECTED[SOURCE_MANIFEST] in source
assert 'Length[manifestParts] =!= 69' in source
assert 'expectedKernelPoolSourceHash =' in source
assert 'expectedPoolRunDefinitionHash =' in source
assert 'KernelPoolMission`$TaskBrokerMaxHelpers === 0' in source
assert 'Length[Kernels[]] =!= 0' in source
assert 'IntegerQ[$KernelID]' in source

# Certified V4 and successful validator evidence are pinned at both ends.
assert EXPECTED[VALIDATOR] in source
assert EXPECTED[VALIDATOR_EVIDENCE] in source
assert EXPECTED[FORMAL_INSPECTOR] in source
assert EXPECTED[FORMAL_RESULT] in source
assert EXPECTED[V4_STATE] in source
assert EXPECTED[V4_REPORT] in source
assert 'sourcePinsBefore = <|' in source
assert 'sourcePinsAfter = <|' in source
assert 'candidateHashesAfter === candidateHashesBefore' in source
assert 'badSourcesAfter === {}' in source

# Fresh isolated copy and preserved pre-sector-12 snapshot.
assert 'If[FileExistsQ[outdir] || DirectoryQ[outdir]' in source
assert 'CopyFile[v4State, snapshotFile, OverwriteTarget -> False]' in source
assert 'CopyFile[v4State, stateFile, OverwriteTarget -> False]' in source
assert 'hashHex[snapshotFile] =!= expectedV4StateHash' in source
assert 'hashHex[stateFile] =!= expectedV4StateHash' in source
assert 'DirectoryQ[scratch]' in source
assert 'pre_sector12_snapshot_CF300_standard.wl' in source
assert 'sector_state_CF300_standard.wl' in source

# Get must preserve its value even when messages occur.  Every exit is caught,
# dynamic state is restored first, only exact EXIT75 is accepted, and every
# other tagged payload is rethrown unchanged.
assert 'Quiet[Get[driver], General::shdw]' in source
assert 'Check[Get[driver]' not in source
assert 'driverMessages = ToString[InputForm[#1]] & /@ $MessageList' in source
assert 'driverExitCapturedQ = True;' in source
restore_index = source.index("restoreDriverDynamicState[];", source.index("driverResult ="))
classification_index = source.index("If[TrueQ[driverExitCapturedQ] &&")
assert restore_index < classification_index
assert 'driverExitPayload =!= {"EXIT", 75}' in source
assert 'Throw[driverExitPayload, "KernelPoolExit"]' in source
assert '! TrueQ[driverExitCapturedQ] ||' in source
assert 'environmentRestoredQ = TrueQ[' in source
assert 'AssociationThread[Keys[environmentOverrides]' in source
assert 'If[driverMessages =!= {}' in source
assert classify_driver_exit(True, ("EXIT", 75)) == "accept"
for payload in (("EXIT", 0), ("EXIT", 2), ("QUIT", 75), None, "$Failed"):
    assert classify_driver_exit(True, payload) == "rethrow"
assert classify_driver_exit(False, None) == "fail"

# Post-record proof: state is still the certified sector 11, no stale sector-12
# checkpoint exists, and the fresh strip equals the package's source-identical
# block-equation reconstruction.
assert 'SameQ[recaptureState, snapshotState]' in source
assert 'Lookup[recaptureState, "Sector", None] === 11' in source
assert '! KeyExistsQ[recaptureState, "Stop"]' in source
assert 'Lookup[#1, "Sector", None] === 12 &' in source
assert 'familyRowGaugeResumeBlockEquation[' in source
assert 'recaptureState["A"], 12, 11, <||>' in source
assert 'Dimensions[Lookup[stripRecord, "Strip", {}]] === {3, 2, 2, 2}' in source
assert 'SameQ[Lookup[stripRecord, "Strip", $Failed], expectedStrip]' in source
assert '! FileExistsQ[stripCheckpointFile]' in source
assert 'Sort[FileNames["*", scratch]] === {stripInputFile}' in source
assert '"NoStaleSector12CheckpointQ"' in source
assert '"FreshStripExactReconstructionQ"' in source

# No package/candidate mutation primitives beyond the two explicit isolated
# copies; no nested compute or process control.
assert source.count("CopyFile[") == 2
for forbidden in (
    "LaunchKernels",
    "ParallelSubmit",
    "StartProcess",
    "KillProcess",
    "SetProcessorAffinity",
    "DeleteFile",
    "DeleteDirectory",
    "OverwriteTarget -> True",
):
    assert forbidden not in source

# Static adversaries: each launch-seal mutation must be rejected, and adding
# Check[Get] must be detected by the explicit source rule above.
for old, new in (
    ('"FACET_RECORD_STRIP_ONLY" -> "True"', '"FACET_RECORD_STRIP_ONLY" -> "False"'),
    ('"FACET_KERNEL_COUNT" -> "1"', '"FACET_KERNEL_COUNT" -> "2"'),
    ('"FACET_CHECK_LEVEL" -> "Production"', '"FACET_CHECK_LEVEL" -> "Development"'),
    ('"7200"', '"7201"'),
    ('"standard"', '"wrong_tag"'),
):
    mutant = source.replace(old, new)
    assert not launch_contract_ok(mutant), (old, new)
check_get_mutant = source.replace(
    "Quiet[Get[driver], General::shdw]",
    "Quiet[Check[Get[driver], $Failed], General::shdw]",
    1,
)
assert "Check[Get[driver]" in check_get_mutant

print("CF300_SECTOR12_RECAPTURE_FROM_V4_V1_STATIC PASS 156/156")
