#!/usr/bin/env python3
"""No-Wolfram adversarial audit for CF300 S12 recapture V3."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


REPO = Path("/home/maxzhang/factorization-and-loops")
HERE = Path(__file__).resolve().parent
LAUNCHER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v3.wls"
BODY = HERE / "run_cf300_sector12_recapture_from_v4_xh_v3_body.wls"
PROBE = HERE / "probe_cf300_sector12_recapture_v3_localized_packages.wls"
SOURCE_MANIFEST = HERE / "CF300_RESUME_SOURCE_SHA256SUMS"
V1_WRAPPER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v1.wls"
V1_FAILED_LOG = HERE / "cf300_s12_recapture_from_v4_xh_v1_FAILED.log"
V1_FAILED_STATUS = HERE / "cf300_s12_recapture_from_v4_xh_v1_FAILED.status"
V2_WRAPPER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v2.wls"
V2_MANIFEST = HERE / "MANIFEST_CF300_SECTOR12_RECAPTURE_V2.sha256"
V2_PROBE = HERE / "probe_cf300_sector12_recapture_v2_parse_context.wls"
V2_PROBE_LOG = HERE / "probe_cf300_s12_recapture_v2_parse_context_xh_v2_OK.log"
V2_PROBE_STATUS = HERE / "probe_cf300_s12_recapture_v2_parse_context_xh_v2_OK.status"
V2_FAILED_LOG = HERE / "cf300_s12_recapture_from_v4_xh_v2_FAILED.log"
V2_FAILED_STATUS = HERE / "cf300_s12_recapture_from_v4_xh_v2_FAILED.status"
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
V1_OUTDIR = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_sector12_recapture_from_v4_xh_v1"
)
V2_OUTDIR = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_sector12_recapture_from_v4_xh_v2"
)
V3_OUTDIR = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_sector12_recapture_from_v4_xh_v3"
)
V1_LAUNCH = V1_OUTDIR / "CF300_sector12_recapture_launch_seal_v1.wl"
V1_SNAPSHOT = V1_OUTDIR / "pre_sector12_snapshot_CF300_standard.wl"
V1_STATE = V1_OUTDIR / "sector_state_CF300_standard.wl"
V1_STRIP = V1_OUTDIR / "sector_CF300_standard/CF300_12_11_input.wl"
V2_LAUNCH = V2_OUTDIR / "CF300_sector12_recapture_launch_seal_v2.wl"
V2_SNAPSHOT = V2_OUTDIR / "pre_sector12_snapshot_CF300_standard.wl"
V2_STATE = V2_OUTDIR / "sector_state_CF300_standard.wl"
V2_STRIP = V2_OUTDIR / "sector_CF300_standard/CF300_12_11_input.wl"

EXPECTED = {
    LAUNCHER: "07029adc6eddbd0fefd6e8287123f35f7297c8bc6327b27c712477036d833c97",
    BODY: "138ddd8643bff53779a14503c7c3579cc6b5375aab486e6a2e8719e3745ddff3",
    PROBE: "7de4b1ba1f8fd4292d2e290ed245b7160dba8bc628af14b5e116e984959c0df0",
    SOURCE_MANIFEST: "880c4f7850b2c0daf5c207e96df23113c91d75d1056e23c6edc169aec66487b2",
    V1_WRAPPER: "e0456c5e0472cceeb982dac23ce78af632846a062dbe6ecdc8527929c96a21fe",
    V1_FAILED_LOG: "34a786e30fc00f13d6b630f42c544138f1b0c99a79c54fbb4f853d3cf257ecb6",
    V1_FAILED_STATUS: "cce9b175ef7ca2123fccaede7688eb47986820ddd84c68d2a9323e76b3f8d950",
    V2_WRAPPER: "8667a863f0fe60a8fc59080880c7736ee76114189bb1b49196c342a2f2a9ccbb",
    V2_MANIFEST: "6f006cc45ef60dbb029cf92d3c49fcf07c5c4aaa716dddab947a98d320b9791e",
    V2_PROBE: "bf85d8df492e8b4a95c2a692f74177377daedc4d96cfa6da3b1de125cc6cb531",
    V2_PROBE_LOG: "0284f86e66b12033ee55ba0cfc713e3564da8de6b157b4dab59d74de90f5439f",
    V2_PROBE_STATUS: "0c4fb1ffb4dae801a5c2412fddcb1ddda6bdd4a2a3496e2a9da253bd3f9ad6ae",
    V2_FAILED_LOG: "fb9d15dd1c3f00c48cb0fe673e57917ba15da7049e50329bcb764a7e5c0392c9",
    V2_FAILED_STATUS: "b8799711ced0ee6f0be9f50166d7632b4163c9e780012d32a5389dde2ea0d142",
    VALIDATOR: "304e7748e3971e9b0bf50fc84b10f50cda8231d49d6df235327134a297c45759",
    VALIDATOR_EVIDENCE: "185d009d9ed4a56037c3360a14862b97e8e39cfbe8e591c5d6bc38d936d45f3e",
    FORMAL_INSPECTOR: "554248efd8e62d293c8a4bfcef0e6774945b36b43965a8a65297d9609b764a8b",
    FORMAL_RESULT: "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128",
    V4_STATE: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V4_REPORT: "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e",
    V1_LAUNCH: "8de31fe88daabb96db1366cd402e505e7a5f505054ed0b78327464c323b6ba4d",
    V1_SNAPSHOT: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V1_STATE: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V1_STRIP: "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976",
    V2_LAUNCH: "8a5d807036fbd01c136ab68ae774c058b8b29de95da7d2a4f4891a6e26473f43",
    V2_SNAPSHOT: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V2_STATE: "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
    V2_STRIP: "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976",
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
    comments = 0
    i = 0
    while i < len(source):
        if comments:
            if source.startswith("(*", i):
                comments += 1
                i += 2
            elif source.startswith("*)", i):
                comments -= 1
                i += 2
            else:
                i += 1
            continue
        if in_string:
            if source[i] == "\\":
                i += 2
            else:
                if source[i] == '"':
                    in_string = False
                i += 1
            continue
        if source.startswith("(*", i):
            comments = 1
            i += 2
        elif source[i] == '"':
            in_string = True
            i += 1
        elif source[i] in pairs:
            stack.append(pairs[source[i]])
            i += 1
        elif source[i] in ")]}":
            if not stack or source[i] != stack.pop():
                return False
            i += 1
        else:
            i += 1
    return not stack and not in_string and comments == 0


def strip_wolfram_strings_and_comments(source: str) -> str:
    out: list[str] = []
    in_string = False
    comments = 0
    i = 0
    while i < len(source):
        if comments:
            if source.startswith("(*", i):
                comments += 1
                i += 2
            elif source.startswith("*)", i):
                comments -= 1
                i += 2
            else:
                i += 1
            out.append(" ")
        elif in_string:
            if source[i] == "\\":
                out.extend("  ")
                i += 2
            else:
                if source[i] == '"':
                    in_string = False
                out.append(" ")
                i += 1
        elif source.startswith("(*", i):
            comments = 1
            out.extend("  ")
            i += 2
        elif source[i] == '"':
            in_string = True
            out.append(" ")
            i += 1
        else:
            out.append(source[i])
            i += 1
    return "".join(out)


def parse_source_manifest(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text().splitlines():
        digest, relative = line.split(None, 1)
        check(bool(re.fullmatch(r"[0-9a-f]{64}", digest)), "manifest digest")
        check(not relative.startswith("/"), "manifest absolute path")
        check(".." not in Path(relative).parts, "manifest traversal")
        check(relative not in result, "manifest duplicate")
        result[relative] = digest
    return result


def message_allowed(signatures: list[str]) -> bool:
    return len(signatures) == 1 and signatures == ["HoldForm[BuildBasis::length]"]


def dirty_shadow_gate(global_names: set[str], package_bases: set[str]) -> set[str]:
    known = {"Global`$LoadFeynArts", "Global`$LoadAddOns", "Global`A0"}
    overlap = {name for name in global_names if name.rsplit("`", 1)[-1] in package_bases}
    return (global_names & known) | overlap


for path, digest in EXPECTED.items():
    check(path.is_file(), f"missing pin: {path}")
    check(sha256(path) == digest, f"hash drift: {path}")
check(V1_STRIP.stat().st_size == 15667, "V1 strip bytes")
check(V2_STRIP.stat().st_size == 15667, "V2 strip bytes")
check(not V3_OUTDIR.exists(), "V3 outdir must be fresh")

source_manifest = parse_source_manifest(SOURCE_MANIFEST)
check(len(source_manifest) == 69, "source count")
for relative, digest in source_manifest.items():
    path = REPO / relative
    check(path.is_file(), f"missing source: {path}")
    check(sha256(path) == digest, f"source drift: {path}")

launcher = LAUNCHER.read_text()
body = BODY.read_text()
probe = PROBE.read_text()
launcher_code = strip_wolfram_strings_and_comments(launcher)
body_code = strip_wolfram_strings_and_comments(body)
probe_code = strip_wolfram_strings_and_comments(probe)
for label, source in (("launcher", launcher), ("body", body), ("probe", probe)):
    check(balanced_wolfram_delimiters(source), f"{label} delimiters")
    check(not re.search(r"[ \t]+$", source, flags=re.MULTILINE),
          f"{label} trailing whitespace")

# Held parsing cannot intern an explicitly qualified V3 runtime symbol.
for label, code in (("launcher", launcher_code), ("body", body_code),
                    ("probe", probe_code)):
    check("CodexCF300Sector12RecaptureV3`" not in code,
          f"explicit V3 symbol token in {label}")
    check("Return[" not in code, f"Return escape in {label}")
    check(not re.search(r"(?<![A-Za-z0-9_`])Names\[", code),
          f"unqualified Names in {label}")
    check(not re.search(r"(?<![A-Za-z0-9_`])Remove\[", code),
          f"unqualified Remove in {label}")

# Launcher: dirty-worker gate occurs before body Get/outdir creation, body is
# pinned, and protected package/path state is localized and exact-audited.
for token in (
    EXPECTED[BODY],
    '"Global`$LoadFeynArts"',
    '"Global`$LoadAddOns"',
    '"Global`A0"',
    '"FeynCalc`"',
    '"FeynArts`"',
    '"FeynFacet`"',
    '"CANONICA`"',
    'System`Names["Global`*"]',
    "dirtyShadowNames === {}",
    "Internal`InheritedBlock[",
    "{System`$ContextPath, System`$Packages}",
    'Get[bodyPath]',
    '"ContextPathRestoredQ"',
    '"PackagesRestoredQ"',
    '"PackagesProtectionRestoredQ"',
    '"DedicatedNamesAfter"',
    '"CF300Sector12RecaptureV3BodyEnvelope"',
    'Throw[Lookup[bodyEnvelope, "ForwardPayload"]',
):
    check(token in launcher, f"missing launcher contract: {token}")
check("Module[" not in launcher_code, "launcher durable Module")
check("System`$Packages =" not in launcher, "launcher assigns protected Packages")
check("Check[Get[bodyPath]" not in launcher, "launcher Check Get")
check("Quiet[Get[bodyPath]" not in launcher, "launcher Quiet Get")
check(launcher.index("dirtyShadowNames === {}") < launcher.index("Get[bodyPath]"),
      "dirty gate after body Get")
check(launcher.index("! FileExistsQ[expectedOutdir]") < launcher.index("Get[bodyPath]"),
      "freshness gate after body Get")
check("FACET_TASK_BROKER_MAX_HELPERS" not in launcher or
      "KernelPoolMission`$TaskBrokerMaxHelpers === 0" in launcher,
      "launcher helper ceiling")

# Static dirty-worker discrimination reproduces K141 and clean cases.
package_bases = {"$LoadFeynArts", "$LoadAddOns", "A0", "FCI"}
check(dirty_shadow_gate(set(), package_bases) == set(), "clean shadow model")
for hazard in ("Global`$LoadFeynArts", "Global`$LoadAddOns", "Global`A0"):
    check(hazard in dirty_shadow_gate({hazard}, package_bases),
          f"known hazard not rejected: {hazard}")
check("Global`FCI" in dirty_shadow_gate({"Global`FCI"}, package_bases),
      "generic package overlap not rejected")

# Body private-package lifetime and no protected-variable assignment.
check('BeginPackage["CodexCF300Sector12RecaptureV3`"]' in body,
      "body BeginPackage")
check('Begin["`Private`"]' in body, "body Private begin")
check(body.index('Begin["`Private`"]') < body.index("Module["),
      "body Module outside Private")
check("System`$Packages =" not in body, "body assigns protected Packages")
check('Block[{$MessageList = {}, $Context = "Global`"}' in body,
      "driver Global block")
check("Get[driver]" in body, "direct driver Get")
check("Check[Get[driver]" not in body, "body Check Get")
check("Quiet[Get[driver]" not in body, "body Quiet Get")
check("driverMessagesRaw = $MessageList" in body, "raw driver messages")
check("Length[driverMessagesRaw] === 1" in body, "singleton message count")
check("driverMessageSignatures === allowedDriverMessageSignatures" in body,
      "exact message signature")
check('allowedDriverMessageSignatures = {"HoldForm[BuildBasis::length]"}' in body,
      "BuildBasis singleton allowlist")
check(message_allowed(["HoldForm[BuildBasis::length]"]), "message positive model")
for mutant in (
    [], ["HoldForm[A0::shdw]"],
    ["HoldForm[BuildBasis::length]", "HoldForm[A0::shdw]"],
    ["HoldForm[FeynCalc`BuildBasis::length]"],
):
    check(not message_allowed(mutant), f"message mutant accepted: {mutant}")

# Exact driver dynamic-state restoration still precedes message/exit gates.
restore_index = body.index("restoreDriverDynamicState[];", body.index("driverResult ="))
telemetry_index = body.index("RESTORATION TELEMETRY")
message_gate_index = body.index("If[! allowedDriverMessagesQ")
exit_gate_index = body.index("If[TrueQ[driverExitCapturedQ] &&")
check(restore_index < telemetry_index < message_gate_index < exit_gate_index,
      "body restore/gate order")
for token in (
    '"SavedEnvironment"', '"CurrentEnvironment"',
    '"EnvironmentComponentQ"', '"SavedCommandLine"',
    '"CurrentCommandLine"', '"CommandLineRestoredQ"',
    '"SavedDirectory"', '"CurrentDirectory"',
    '"DirectoryRestoredQ"', '"SavedScriptCommandLineProtectedQ"',
    '"CurrentScriptCommandLineProtectedQ"',
    '"ScriptCommandLineProtectionRestoredQ"',
    '"EnvironmentActiveFlagClearedQ"', '"AllRestoredQ"',
):
    check(token in body, f"missing restoration telemetry: {token}")

# V1/V2 evidence is pinned at both ends, including exact copied strips/states.
for path in (
    V1_WRAPPER, V1_FAILED_LOG, V1_FAILED_STATUS,
    V2_WRAPPER, V2_MANIFEST, V2_PROBE, V2_PROBE_LOG, V2_PROBE_STATUS,
    V2_FAILED_LOG, V2_FAILED_STATUS, VALIDATOR, VALIDATOR_EVIDENCE,
    FORMAL_INSPECTOR, FORMAL_RESULT, V4_STATE, V4_REPORT,
    V1_LAUNCH, V1_SNAPSHOT, V1_STATE, V1_STRIP,
    V2_LAUNCH, V2_SNAPSHOT, V2_STATE, V2_STRIP,
):
    check(EXPECTED[path] in body, f"body missing pin: {path.name}")
for token in (
    "v1PinsBefore = <|", "v1PinsAfter = <|",
    "v1PinsAfter === v1PinsBefore",
    "v2PinsBefore = <|", "v2PinsAfter = <|",
    "v2PinsAfter === v2PinsBefore",
    "sourcePinsAfter === sourcePinsBefore",
    "candidateHashesAfter === candidateHashesBefore",
    "badSourcesAfter === {}",
):
    check(token in body, f"missing immutable gate: {token}")

# Fresh exact recapture and body envelope.
for token in (
    '"cf300_sector12_recapture_from_v4_xh_v3"',
    "If[FileExistsQ[outdir] || DirectoryQ[outdir]",
    "CopyFile[v4State, snapshotFile, OverwriteTarget -> False]",
    "CopyFile[v4State, stateFile, OverwriteTarget -> False]",
    "SameQ[recaptureState, snapshotState]",
    'Lookup[recaptureState, "Sector", None] === 11',
    "familyRowGaugeResumeBlockEquation[",
    'recaptureState["A"], 12, 11, <||>',
    'SameQ[Lookup[stripRecord, "Strip", $Failed], expectedStrip]',
    "! FileExistsQ[stripCheckpointFile]",
    'Sort[FileNames["*", scratch]] === {stripInputFile}',
    '"CF300Sector12RecaptureV3BodyEnvelope"',
    '"DedicatedNameCleanupQ"',
    '"ContextPathWasLocalizedQ"',
    '"PackagesWasLocalizedQ"',
):
    check(token in body, f"missing body recapture gate: {token}")
check(body.count("CopyFile[") == 2, "unexpected body CopyFile count")
check('Throw[resolvedForwardPayload, "KernelPoolExit"]' not in body,
      "body rethrows before launcher lifecycle audit")

# No-write probe uses the same InheritedBlock and real package lifecycle.
for token in (
    "Internal`InheritedBlock[",
    "{System`$ContextPath, System`$Packages}",
    'System`BeginPackage[', 'System`Begin["`Private`"]',
    "System`End[]", "System`EndPackage[]",
    '"PublicContextOnLocalizedPathQ"',
    '"PublicContextInLocalizedPackagesQ"',
    '"PackagesStillProtectedInsideQ"',
    '"PackagesAttributesRestoredQ"',
    '"ProbeNamesCleanedQ"',
):
    check(token in probe, f"missing localized-packages probe gate: {token}")
for forbidden in ("Get[", "Put[", "Export[", "CreateFile[", "CreateDirectory["):
    check(forbidden not in probe_code, f"probe mutation/execution: {forbidden}")

# No nested compute, process control, destructive cleanup, or package edits.
for label, code_source in (("launcher", launcher), ("body", body), ("probe", probe)):
    for forbidden in (
        "LaunchKernels", "ParallelSubmit", "StartProcess", "KillProcess",
        "SetProcessorAffinity", "DeleteFile", "DeleteDirectory",
        "OverwriteTarget -> True",
    ):
        check(forbidden not in code_source, f"{label} forbidden: {forbidden}")

print(f"CF300_SECTOR12_RECAPTURE_FROM_V4_V3_STATIC PASS {checks}/{checks}")
