#!/usr/bin/env python3
"""No-Wolfram adversarial audit for the context-safe CF300 S12 recapture V2."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


REPO = Path("/home/maxzhang/factorization-and-loops")
HERE = Path(__file__).resolve().parent
WRAPPER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v2.wls"
PROBE = HERE / "probe_cf300_sector12_recapture_v2_parse_context.wls"
SOURCE_MANIFEST = HERE / "CF300_RESUME_SOURCE_SHA256SUMS"
VALIDATOR = HERE / "validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls"
VALIDATOR_EVIDENCE = HERE / "cf300_s11_postwrite_validator_xh_v2_OK.log"
FORMAL_INSPECTOR = HERE / "inspect_cf300_sector11_postwrite_v4.py"
FORMAL_RESULT = HERE / "cf300_sector11_postwrite_formal_inspector_v4_result.json"
V1_WRAPPER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v1.wls"
V1_FAILED_LOG = HERE / "cf300_s12_recapture_from_v4_xh_v1_FAILED.log"
V1_FAILED_STATUS = HERE / "cf300_s12_recapture_from_v4_xh_v1_FAILED.status"
SUPERSEDED_PROBE_LOG = (
    HERE / "probe_cf300_s12_recapture_v2_parse_context_xh_v1_SUPERSEDED_HUNG.log"
)
V4_STATE = REPO / (
    "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/"
    "FamilyEpsFormsSolving/triple_root_2026-08-23/"
    "CF300_direct_regulator_v4_candidate/sector_state_CF300_standard.wl"
)
V4_REPORT = V4_STATE.parent / "cf300_sector11_direct_regulator_report_v4.wl"
V1_OUTDIR = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_sector12_recapture_from_v4_xh_v1"
)
V2_OUTDIR = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_sector12_recapture_from_v4_xh_v2"
)
V1_LAUNCH_SEAL = V1_OUTDIR / "CF300_sector12_recapture_launch_seal_v1.wl"
V1_SNAPSHOT = V1_OUTDIR / "pre_sector12_snapshot_CF300_standard.wl"
V1_STATE = V1_OUTDIR / "sector_state_CF300_standard.wl"
V1_STRIP = V1_OUTDIR / "sector_CF300_standard/CF300_12_11_input.wl"

EXPECTED = {
    WRAPPER: "8667a863f0fe60a8fc59080880c7736ee76114189bb1b49196c342a2f2a9ccbb",
    PROBE: "bf85d8df492e8b4a95c2a692f74177377daedc4d96cfa6da3b1de125cc6cb531",
    SOURCE_MANIFEST: "880c4f7850b2c0daf5c207e96df23113c91d75d1056e23c6edc169aec66487b2",
    VALIDATOR: "304e7748e3971e9b0bf50fc84b10f50cda8231d49d6df235327134a297c45759",
    VALIDATOR_EVIDENCE: "185d009d9ed4a56037c3360a14862b97e8e39cfbe8e591c5d6bc38d936d45f3e",
    FORMAL_INSPECTOR: "554248efd8e62d293c8a4bfcef0e6774945b36b43965a8a65297d9609b764a8b",
    FORMAL_RESULT: "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128",
    V4_STATE: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V4_REPORT: "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e",
    V1_WRAPPER: "e0456c5e0472cceeb982dac23ce78af632846a062dbe6ecdc8527929c96a21fe",
    V1_FAILED_LOG: "34a786e30fc00f13d6b630f42c544138f1b0c99a79c54fbb4f853d3cf257ecb6",
    V1_FAILED_STATUS: "cce9b175ef7ca2123fccaede7688eb47986820ddd84c68d2a9323e76b3f8d950",
    SUPERSEDED_PROBE_LOG: "cf2c09fbfeab9f079f253434edb812d5a18364b8260802fc36eb70f96f7f4331",
    V1_LAUNCH_SEAL: "8de31fe88daabb96db1366cd402e505e7a5f505054ed0b78327464c323b6ba4d",
    V1_SNAPSHOT: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V1_STATE: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V1_STRIP: "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976",
}

checks = 0


def check(condition: bool, label: str) -> None:
    global checks
    checks += 1
    if not condition:
        raise AssertionError(label)


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
        elif character in ")]}" and (not stack or character != stack.pop()):
            return False
        index += 1
    return not stack and not in_string and comment_depth == 0


def strip_wolfram_strings_and_comments(source: str) -> str:
    output: list[str] = []
    in_string = False
    comment_depth = 0
    index = 0
    while index < len(source):
        if comment_depth:
            if source.startswith("(*", index):
                comment_depth += 1
                index += 2
            elif source.startswith("*)", index):
                comment_depth -= 1
                index += 2
            else:
                index += 1
            output.append(" ")
            continue
        if in_string:
            if source[index] == "\\":
                output.extend("  ")
                index += 2
            else:
                if source[index] == '"':
                    in_string = False
                output.append(" ")
                index += 1
            continue
        if source.startswith("(*", index):
            comment_depth = 1
            output.extend("  ")
            index += 2
        elif source[index] == '"':
            in_string = True
            output.append(" ")
            index += 1
        else:
            output.append(source[index])
            index += 1
    return "".join(output)


def parse_manifest(path: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for line in path.read_text().splitlines():
        digest, relative = line.split(None, 1)
        check(bool(re.fullmatch(r"[0-9a-f]{64}", digest)), "manifest digest")
        check(not relative.startswith("/"), "manifest path absolute")
        check(".." not in Path(relative).parts, "manifest parent traversal")
        check(relative not in entries, "manifest duplicate")
        entries[relative] = digest
    return entries


def launch_contract_ok(source: str) -> bool:
    required = (
        '"FACET_KERNEL_COUNT" -> "1"',
        '"FACET_TASK_BROKER_MAX_HELPERS" -> "0"',
        '"FACET_CHECK_LEVEL" -> "Production"',
        '"FACET_STRIP_ROUTE" -> "FiniteFieldFirst"',
        '"FACET_ZERO_FORCING" -> "True"',
        '"FACET_RECORD_STRIP_ONLY" -> "True"',
        '"FACET_RESUME_HYDRATION" -> "True"',
        '{driver, "CF300", outdir, "7200", "standard",',
        '"30", "", familyDataDirectory, classFormDirectory}',
    )
    return all(item in source for item in required)


def message_allowed(signatures: list[str]) -> bool:
    return len(signatures) == 1 and signatures == ["HoldForm[BuildBasis::length]"]


def classify_driver_exit(captured: bool, payload: object) -> str:
    if captured and payload == ("EXIT", 75):
        return "accept"
    if captured:
        return "rethrow"
    return "fail"


for path, expected_hash in EXPECTED.items():
    check(path.is_file(), f"missing pinned artifact: {path}")
    check(sha256(path) == expected_hash, f"hash drift: {path}")
check(V1_STRIP.stat().st_size == 15667, "V1 strip byte count")
check(not V2_OUTDIR.exists(), "V2 output must be fresh")

manifest = parse_manifest(SOURCE_MANIFEST)
check(len(manifest) == 69, "manifest cardinality")
for relative, expected_hash in manifest.items():
    artifact = REPO / relative
    check(artifact.is_file(), f"missing source: {artifact}")
    check(sha256(artifact) == expected_hash, f"source drift: {artifact}")

source = WRAPPER.read_text()
code = strip_wolfram_strings_and_comments(source)
probe_source = PROBE.read_text()
check(balanced_wolfram_delimiters(source), "wrapper delimiters")
check(balanced_wolfram_delimiters(probe_source), "probe delimiters")
check(not re.search(r"[ \t]+$", source, flags=re.MULTILINE), "wrapper trailing ws")
check(not re.search(r"[ \t]+$", probe_source, flags=re.MULTILINE), "probe trailing ws")
check(launch_contract_ok(source), "launch contract")

# The frozen V1 log is the runtime evidence for the sole allowed message.
log_flat = re.sub(r"\s+", " ", V1_FAILED_LOG.read_text())
check("BuildBasis::length:" in log_flat, "V1 message name evidence")
check("Expected four basis vectors, but received {nb, 5, xhat, yhat}." in log_flat,
      "V1 exact rendered message evidence")
superseded_log = SUPERSEDED_PROBE_LOG.read_text()
check('Names["CodexCF300Sector12RecaptureV2`*",' in superseded_log,
      "superseded probe Names-shadow evidence")
check("MISSION end" not in superseded_log,
      "superseded probe Return-escape evidence")
check('"HoldForm[BuildBasis::length]"' in source, "raw message signature pin")
check("knownDriverMessageText" in source, "rendered message text pin")
check(EXPECTED[V1_FAILED_LOG] in source, "failed log hash pin")
check(EXPECTED[V1_FAILED_STATUS] in source, "failed status hash pin")

# No explicitly qualified token in the dedicated context may survive
# kpsubmit's held parse. Context names are allowed only inside strings.
check("CodexCF300Sector12RecaptureV2`" not in code,
      "explicit dedicated-context symbol token")
check(not re.search(r"(?<![A-Za-z0-9_`])Names\[", code),
      "unqualified executable Names in wrapper")
check(not re.search(r"(?<![A-Za-z0-9_`])Remove\[", code),
      "unqualified executable Remove in wrapper")
check('BeginPackage["CodexCF300Sector12RecaptureV2`"]' in source,
      "dedicated package begin")
check('Begin["`Private`"]' in source, "dedicated private begin")
check(source.index('Begin["`Private`"]') < source.index("Module["),
      "Module parsed in Private context")
check('Block[{$MessageList = {}, $Context = "Global`"}' in source,
      "driver runs in Global context")
check('System`Names["CodexCF300Sector12RecaptureV2`Private`*"]' in source,
      "private context preflight")
check('System`Remove["CodexCF300Sector12RecaptureV2`Private`*"]' in source,
      "literal private cleanup")
check('System`Remove["CodexCF300Sector12RecaptureV2`*"]' in source,
      "literal public cleanup")
check("Remove[Evaluate" not in source, "no held Evaluate cleanup")
check('Remove["CodexCF300Sector12RecaptureV2`" <>' not in source,
      "no held dynamic cleanup pattern")
check("DEDICATED CONTEXT TELEMETRY" in source, "dedicated cleanup telemetry")
check(source.rindex("EndPackage[];") < source.rindex("Remove["),
      "cleanup after EndPackage")
check("System`$ContextPath = System`DeleteCases" in source,
      "context path cleanup")
check("System`$Packages = System`DeleteCases" in source,
      "packages cleanup")
check("System`Join[System`Names[" in source,
      "qualified context-name join")
check("System`FreeQ[System`$ContextPath" in source,
      "context path pre/post gate")
check("System`FreeQ[System`$Packages" in source,
      "packages pre/post gate")

# finalResult/finalForwardPayload must be durable Private symbols, not Module
# locals, and With must substitute them before EndPackage/cleanup.
module_header = source[source.index("Module["):source.index("repositoryRoot =")]
check("finalResult" not in module_header, "finalResult accidentally Module-local")
check("finalForwardPayload" not in module_header,
      "finalForwardPayload accidentally Module-local")
check("{resolvedResult = finalResult," in source, "With result capture")
check("resolvedForwardPayload = finalForwardPayload" in source,
      "With forward capture")
check("Throw[resolvedForwardPayload, \"KernelPoolExit\"]" in source,
      "post-cleanup payload forwarding")
check("Throw[driverExitPayload, \"KernelPoolExit\"]" not in source,
      "no pre-cleanup direct rethrow")

# Driver Get keeps its value, captures the raw list, restores first, then
# applies an exact one-message allowlist and exact EXIT75 classification.
check("Get[driver]" in source, "direct driver Get")
check("Check[Get[driver]" not in source, "Check Get value-loss regression")
check("Quiet[Get[driver]" not in source, "broadly quieted driver Get")
check("driverMessagesRaw = $MessageList" in source, "raw MessageList capture")
check("Length[driverMessagesRaw] === 1" in source, "one-message cardinality")
check("driverMessageSignatures === allowedDriverMessageSignatures" in source,
      "exact message signature equality")
check("driverMessagesRaw === {}" not in source, "obsolete no-message gate")
restore_index = source.index("restoreDriverDynamicState[];", source.index("driverResult ="))
telemetry_index = source.index("RESTORATION TELEMETRY")
message_gate_index = source.index("If[! allowedDriverMessagesQ")
exit_gate_index = source.index("If[TrueQ[driverExitCapturedQ] &&")
check(restore_index < telemetry_index < message_gate_index < exit_gate_index,
      "restore/telemetry/message/exit order")
check('driverExitPayload =!= {"EXIT", 75}' in source, "exact non75 gate")
check('driverExitPayload =!= {"EXIT", 75}' in source, "exact 75 acceptance")
check("forwardExitPayload = driverExitPayload" in source, "payload preserved")

check(message_allowed(["HoldForm[BuildBasis::length]"]), "allowed message model")
for messages in (
    [],
    ["HoldForm[Other::length]"],
    ["HoldForm[BuildBasis::length]", "HoldForm[Other::tag]"],
    ["HoldForm[FeynCalc`BuildBasis::length]"],
):
    check(not message_allowed(messages), f"message mutant accepted: {messages}")
check(classify_driver_exit(True, ("EXIT", 75)) == "accept", "EXIT75 model")
for payload in (("EXIT", 0), ("EXIT", 2), ("QUIT", 75), None, "$Failed"):
    check(classify_driver_exit(True, payload) == "rethrow",
          f"non75 model: {payload}")
check(classify_driver_exit(False, None) == "fail", "missing-exit model")

# Componentwise restoration is printed before any acceptance or forwarding.
for token in (
    '"SavedEnvironment"',
    '"CurrentEnvironment"',
    '"EnvironmentComponentQ"',
    '"SavedCommandLine"',
    '"CurrentCommandLine"',
    '"CommandLineRestoredQ"',
    '"SavedDirectory"',
    '"CurrentDirectory"',
    '"DirectoryRestoredQ"',
    '"SavedScriptCommandLineProtectedQ"',
    '"CurrentScriptCommandLineProtectedQ"',
    '"ScriptCommandLineProtectionRestoredQ"',
    '"EnvironmentActiveFlagClearedQ"',
    '"AllRestoredQ"',
):
    check(token in source, f"missing restoration telemetry: {token}")
check("AssociationMap[" in source and "environmentComponentsQ" in source,
      "per-environment component map")
check("And @@ Values[environmentComponentsQ]" in source,
      "all environment components required")
check("protectionRestoredQ" in source, "protection restoration gate")
check("environmentRestoredQ" in source, "total restoration gate")

# Frozen provenance is checked before and after; V1 evidence/output and the V4
# candidate cannot be modified by the recapture.
for path in (
    VALIDATOR, VALIDATOR_EVIDENCE, FORMAL_INSPECTOR, FORMAL_RESULT,
    V4_STATE, V4_REPORT, V1_WRAPPER, V1_FAILED_LOG, V1_FAILED_STATUS,
    V1_LAUNCH_SEAL, V1_SNAPSHOT, V1_STATE, V1_STRIP,
):
    check(EXPECTED[path] in source, f"missing embedded pin: {path.name}")
check("v1PinsBefore = <|" in source, "V1 before pins")
check("v1PinsAfter = <|" in source, "V1 after pins")
check("v1PinsAfter === v1PinsBefore" in source, "V1 immutable gate")
check("sourcePinsAfter === sourcePinsBefore" in source, "source immutable gate")
check("candidateHashesAfter === candidateHashesBefore" in source,
      "candidate immutable gate")
check("badSourcesAfter === {}" in source, "source manifest recheck")

# Fresh isolated state copy and exact recapture proof.
for token in (
    "If[FileExistsQ[outdir] || DirectoryQ[outdir]",
    "CopyFile[v4State, snapshotFile, OverwriteTarget -> False]",
    "CopyFile[v4State, stateFile, OverwriteTarget -> False]",
    "hashHex[snapshotFile] =!= expectedV4StateHash",
    "hashHex[stateFile] =!= expectedV4StateHash",
    "SameQ[recaptureState, snapshotState]",
    'Lookup[recaptureState, "Sector", None] === 11',
    '! KeyExistsQ[recaptureState, "Stop"]',
    "familyRowGaugeResumeBlockEquation[",
    'recaptureState["A"], 12, 11, <||>',
    'Dimensions[Lookup[stripRecord, "Strip", {}]] === {3, 2, 2, 2}',
    'SameQ[Lookup[stripRecord, "Strip", $Failed], expectedStrip]',
    "! FileExistsQ[stripCheckpointFile]",
    'Sort[FileNames["*", scratch]] === {stripInputFile}',
):
    check(token in source, f"missing recapture proof: {token}")

# Parse-context probe exactly mirrors kpsubmit's held ToExpression model and
# is read-only. The full launch remains blocked until this runs on a clean
# pool worker and the centrally generated wrapper passes its actual parser.
for token in (
    'ToExpression[parseText, InputForm, HoldComplete]',
    '$Context = parseContext, $ContextPath = {"System`"}',
    'System`Names["CodexCF300Sector12RecaptureV2`Private`*"]',
    'System`Names["Global`*"]',
    "System`Remove[",
    '"CodexCF300Sector12RecaptureV2ParseProbe`*"',
    '"DedicatedContextUnchangedQ"',
    '"GlobalContextUnchangedQ"',
    '"DisposableParseContextCleanedQ"',
):
    check(token in probe_source, f"missing parse probe contract: {token}")
check(EXPECTED[WRAPPER] in probe_source, "probe wrapper hash pin")
probe_code = strip_wolfram_strings_and_comments(probe_source)
check("Return[" not in probe_code,
      "top-level Return escape regression")
check(not re.search(r"(?<![A-Za-z0-9_`])Names\[", probe_code),
      "unqualified executable Names in probe")
check(not re.search(r"(?<![A-Za-z0-9_`])Remove\[", probe_code),
      "unqualified executable Remove in probe")
check("probeResult = Catch[" in probe_source, "probe Catch boundary")
check("Throw[$Failed, preflightTag]" in probe_source,
      "probe fail-closed Throw")
for forbidden in ("Get[wrapper]", "Put[", "Export[", "CreateFile["):
    check(forbidden not in probe_source, f"probe mutates/executes: {forbidden}")

# No package/source edits, nested compute, or process control. Only the two
# explicit copies into the fresh V2 directory are allowed.
check(source.count("CopyFile[") == 2, "unexpected CopyFile count")
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
    check(forbidden not in source, f"forbidden wrapper primitive: {forbidden}")

# Static launch-contract adversaries.
for old, new in (
    ('"FACET_RECORD_STRIP_ONLY" -> "True"', '"FACET_RECORD_STRIP_ONLY" -> "False"'),
    ('"FACET_KERNEL_COUNT" -> "1"', '"FACET_KERNEL_COUNT" -> "2"'),
    ('"FACET_CHECK_LEVEL" -> "Production"', '"FACET_CHECK_LEVEL" -> "Development"'),
    ('"7200"', '"7201"'),
    ('"standard"', '"wrong_tag"'),
):
    check(not launch_contract_ok(source.replace(old, new)),
          f"launch mutant accepted: {old}")

print(f"CF300_SECTOR12_RECAPTURE_FROM_V4_V2_STATIC PASS {checks}/{checks}")
