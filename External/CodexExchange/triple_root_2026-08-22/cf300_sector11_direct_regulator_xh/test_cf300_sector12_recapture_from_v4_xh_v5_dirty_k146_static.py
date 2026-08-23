#!/usr/bin/env python3
"""Package-free static/adversarial audit for the CF300 V5 dirty-K146 bundle."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import re
import tempfile
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = Path("/home/maxzhang/factorization-and-loops")
LAUNCHER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146.wls"
BODY = HERE / "run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146_body.wls"
PREFLIGHT = HERE / "preflight_cf300_sector12_recapture_v5_dirty_k146_global_state.wls"
PROBE = HERE / "probe_cf300_sector12_recapture_v5_dirty_k146_k146.wls"
CENSUS = HERE / "family_sector_driver_global_census_v1.json"
INSPECTOR = HERE / "inspect_family_sector_driver_global_census_v1.py"
DRIVER = ROOT / "Scripts" / "family_epsform_sector.wls"
PATH_INSPECTOR = HERE / "inspect_cf300_sector12_recapture_v5_dirty_k146_paths.py"
PATH_SEAL = HERE / "cf300_sector12_recapture_v5_dirty_k146_path_seal.json"
SOURCE_MANIFEST = HERE / "CF300_RESUME_SOURCE_SHA256SUMS"
KERNEL_POOL_SOURCE = ROOT / "Scripts" / "KernelPool.wls"
POOL_RUN_DEFINITION = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/pool/poolrun_definition.m"
)
VALIDATOR = HERE / "validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls"
VALIDATOR_EVIDENCE = HERE / "cf300_s11_postwrite_validator_xh_v2_OK.log"
FORMAL_RESULT = HERE / "cf300_sector11_postwrite_formal_inspector_v4_result.json"
V4_CANDIDATE = (
    ROOT
    / "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving"
    / "triple_root_2026-08-23/CF300_direct_regulator_v4_candidate"
)
V4_STATE = V4_CANDIDATE / "sector_state_CF300_standard.wl"
V4_REPORT = V4_CANDIDATE / "cf300_sector11_direct_regulator_report_v4.wl"

CRITICAL_CALL_HEADS = (
    "Names", "Remove", "Context", "Attributes", "OwnValues",
    "DownValues", "UpValues", "SubValues", "NValues", "DefaultValues",
    "FormatValues", "Messages", "Options", "FileNames", "FileHash", "FileExistsQ", "DirectoryQ",
    "Kernels", "Directory", "FileByteCount", "ToExpression", "Get",
)
CRITICAL_SYSTEM_VARIABLES = (
    "Context", "ContextPath", "Packages", "Path", "ScriptCommandLine",
    "MessageList", "Messages", "InputFileName", "HistoryLength", "KernelID",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def strip_wl_comments_and_strings(source: str) -> str:
    out: list[str] = []
    i = 0
    comment_depth = 0
    in_string = False
    while i < len(source):
        if comment_depth:
            if source.startswith("(*", i):
                comment_depth += 1
                out.extend("  ")
                i += 2
            elif source.startswith("*)", i):
                comment_depth -= 1
                out.extend("  ")
                i += 2
            else:
                out.append("\n" if source[i] == "\n" else " ")
                i += 1
        elif in_string:
            if source[i] == "\\" and i + 1 < len(source):
                out.extend("  ")
                i += 2
            elif source[i] == '"':
                in_string = False
                out.append(" ")
                i += 1
            else:
                out.append("\n" if source[i] == "\n" else " ")
                i += 1
        elif source.startswith("(*", i):
            comment_depth = 1
            out.extend("  ")
            i += 2
        elif source[i] == '"':
            in_string = True
            out.append(" ")
            i += 1
        else:
            out.append(source[i])
            i += 1
    if comment_depth or in_string:
        raise AssertionError("unterminated Wolfram comment/string")
    return "".join(out)


def assert_balanced(source: str, label: str) -> None:
    code = strip_wl_comments_and_strings(source)
    stack: list[tuple[str, int]] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    line = 1
    for char in code:
        if char == "\n":
            line += 1
        elif char in "([{":
            stack.append((char, line))
        elif char in ")]}":
            assert stack and stack[-1][0] == pairs[char], (
                f"{label}: mismatched {char!r} at line {line}; stack={stack[-4:]}"
            )
            stack.pop()
    assert not stack, f"{label}: unclosed delimiters {stack[-8:]}"


def embedded_hash(source: str, name: str) -> str:
    match = re.search(rf"{re.escape(name)}\s*=\s*\n?\s*\"([0-9a-f]{{64}})\"", source)
    assert match, f"missing literal 64-hex assignment for {name}"
    return match.group(1)


def mutation_rejected(base: str, old: str, new: str, predicate, label: str) -> None:
    assert old in base, f"mutation anchor absent: {label}"
    mutant = base.replace(old, new, 1)
    assert not predicate(mutant), f"mutation survived: {label}"


def critical_system_qualified(source: str) -> bool:
    """Reject call heads/special variables vulnerable to context-path shadows."""
    executable = strip_wl_comments_and_strings(source)
    for head in CRITICAL_CALL_HEADS:
        if re.search(
            rf"(?<![A-Za-z0-9$`]){re.escape(head)}\s*\[", executable
        ):
            return False
    for variable in CRITICAL_SYSTEM_VARIABLES:
        if re.search(
            rf"(?<!System`)\${re.escape(variable)}\b", executable
        ):
            return False
    return True


def main() -> None:
    paths = [
        LAUNCHER, BODY, PREFLIGHT, PROBE, CENSUS, INSPECTOR, DRIVER,
        PATH_INSPECTOR, PATH_SEAL, SOURCE_MANIFEST, KERNEL_POOL_SOURCE,
        POOL_RUN_DEFINITION, VALIDATOR, VALIDATOR_EVIDENCE, FORMAL_RESULT,
        V4_STATE, V4_REPORT,
    ]
    for path in paths:
        assert path.is_file(), f"missing {path}"

    launcher = LAUNCHER.read_text()
    body = BODY.read_text()
    preflight = PREFLIGHT.read_text()
    probe = PROBE.read_text()
    driver = DRIVER.read_text()
    census = json.loads(CENSUS.read_text())
    path_seal = json.loads(PATH_SEAL.read_text())
    checks = 0

    for label, source in [
        ("launcher", launcher), ("body", body),
        ("preflight", preflight), ("probe", probe),
    ]:
        assert_balanced(source, label)
        checks += 1
        executable = strip_wl_comments_and_strings(source)
        assert not re.search(r"\bReturn\s*\[", executable), label
        assert not re.search(
            r"\b(?:RunProcess|StartProcess|KillProcess|ProcessStatus|"
            r"Renice|Taskset|LaunchKernels|ParallelSubmit)\s*\[",
            executable,
        ), label
        assert critical_system_qualified(source), label
        checks += 3

    # The first state-changing package forms must execute before the large
    # mission expressions are parsed, so their locals cannot land in Global`.
    for label, source, main_symbol in [
        ("launcher", launcher, "launcherFinalResult"),
        ("body", body, "bodyFinalResult"),
        ("preflight", preflight, "preflightFinalReport"),
        ("probe", probe, "probeFinalResult"),
    ]:
        assert source.index("BeginPackage[") < source.index(main_symbol)
        assert source.index("Begin[") < source.index(main_symbol)
        checks += 2

    assert "__V4_" not in launcher + body + preflight + probe
    checks += 1
    assert embedded_hash(launcher, "expectedBodyHash") == sha256(BODY)
    assert embedded_hash(launcher, "expectedPreflightHash") == sha256(PREFLIGHT)
    assert embedded_hash(probe, "expectedPreflightHash") == sha256(PREFLIGHT)
    checks += 3

    assert path_seal["Schema"] == "CF300Sector12RecaptureV5DirtyK146PathSealV1"
    assert path_seal["GateQ"] is True
    assert path_seal["RecordCount"] == 21
    assert len(path_seal["Records"]) == 21
    assert all(record["GateQ"] is True for record in path_seal["Records"])
    output_record = next(
        record for record in path_seal["Records"]
        if record["Label"] == "OutputDirectory"
    )
    assert output_record["ExpectedKind"] == "absent"
    assert output_record["ActualKind"] == "absent"
    assert output_record["Lexists"] is False
    spec = importlib.util.spec_from_file_location("v4_path_inspector", PATH_INSPECTOR)
    assert spec and spec.loader
    path_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(path_module)
    assert path_module.build_result() == path_seal
    checks += 9

    # Adversarial path fixtures: a symlink to a regular file and a dangling
    # link must both fail closed, even if a conventional exists() check lies.
    with tempfile.TemporaryDirectory(prefix="cf300-v4-path-audit-") as temp:
        temp_path = Path(temp)
        regular = temp_path / "regular"
        regular.write_text("sealed\n")
        linked = temp_path / "linked"
        dangling = temp_path / "dangling"
        os.symlink(regular, linked)
        os.symlink(temp_path / "missing-target", dangling)
        assert path_module.inspect_path("Linked", linked, "file")["GateQ"] is False
        assert path_module.inspect_path(
            "Dangling", dangling, "absent"
        )["GateQ"] is False
        checks += 2

    assert census["Schema"] == "FACETFamilySectorDriverGlobalCensusV1"
    assert census["DriverSHA256"] == sha256(DRIVER)
    assert census["QualifiedGlobalNameCount"] == 637
    assert len(census["QualifiedGlobalNames"]) == 637
    assert census["Extraction"]["AssignmentLHSCoveredQ"] is True
    assert census["Extraction"]["ConservativeSupersetQ"] is True
    checks += 6
    assert embedded_hash(preflight, "expectedDriverHash") == sha256(DRIVER)
    assert embedded_hash(preflight, "expectedCensusHash") == sha256(CENSUS)
    assert embedded_hash(preflight, "expectedInspectorHash") == sha256(INSPECTOR)
    checks += 3

    exact_artifact_pins = {
        "expectedSourceManifestHash": SOURCE_MANIFEST,
        "expectedKernelPoolSourceHash": KERNEL_POOL_SOURCE,
        "expectedPoolRunDefinitionHash": POOL_RUN_DEFINITION,
        "expectedValidatorHash": VALIDATOR,
        "expectedValidatorEvidenceHash": VALIDATOR_EVIDENCE,
        "expectedFormalResultHash": FORMAL_RESULT,
        "expectedV4StateHash": V4_STATE,
        "expectedV4ReportHash": V4_REPORT,
        "expectedDriverHash": DRIVER,
        "expectedCensusHash": CENSUS,
        "expectedCensusInspectorHash": INSPECTOR,
        "expectedPathSealHash": PATH_SEAL,
        "expectedPathInspectorHash": PATH_INSPECTOR,
    }
    for name, path in exact_artifact_pins.items():
        assert embedded_hash(body, name) == sha256(path), (name, path)
        checks += 1
    for name in [
        "expectedSourceManifestHash", "expectedKernelPoolSourceHash",
        "expectedPoolRunDefinitionHash", "expectedValidatorHash",
        "expectedValidatorEvidenceHash", "expectedFormalResultHash",
        "expectedV4StateHash", "expectedV4ReportHash", "expectedDriverHash",
        "expectedCensusHash", "expectedCensusInspectorHash",
        "expectedPathSealHash", "expectedPathInspectorHash",
    ]:
        assert embedded_hash(launcher, name) == embedded_hash(body, name), name
        checks += 1
    assert embedded_hash(probe, "expectedPathSealHash") == sha256(PATH_SEAL)
    checks += 1

    required_globals = {
        "tau", "s", "u", "p", "x", "y", "eps", "v", "w", "t",
        "r", "mu", "xi", "xx", "Eps", "epsilon", "Epsilon", "ep",
        "sqrtLambda", "gli", "nb", "n", "xhat", "yhat", "GlobalBasis",
        "$LoadFeynArts", "$LoadAddOns", "A0", "$FACETKernelLimit",
        "$FACETRatracerExecutable", "$FeynCalcStartupMessages",
        "$PolyLogPath", "FeynFacetFermatCheckVariable",
        "root", "ranges", "t0", "variables", "dD",
    }
    explicit_block = re.search(
        r"explicitGlobalNames\s*=\s*\{(.*?)\};", body, re.S
    )
    assert explicit_block
    explicit_names = set(re.findall(r'"Global`([^"`]+)"', explicit_block.group(1)))
    assert explicit_names == required_globals, (required_globals - explicit_names,
                                                explicit_names - required_globals)
    inherited = re.search(
        r"scopedExecution\s*=\s*Internal`InheritedBlock\s*\[\s*\{(.*?)\},\s*\n\s*System`ClearAll",
        body,
        re.S,
    )
    assert inherited
    inherited_names = set(re.findall(r"Global`([A-Za-z$][A-Za-z0-9$]*)", inherited.group(1)))
    assert required_globals <= inherited_names
    clear_block = re.search(
        r"System`ClearAll\[(.*?)\];\s*\n\s*System`\$HistoryLength", body, re.S
    )
    assert clear_block
    cleared_names = set(re.findall(r"Global`([A-Za-z$][A-Za-z0-9$]*)", clear_block.group(1)))
    assert required_globals <= cleared_names
    checks += 6

    assert 'System`$ContextPath = {"System`"}' in body
    assert "ToExpression[driverParseText, InputForm, HoldComplete]" in body
    assert "ReleaseHold[driverHeld]" in body
    assert "Get[driver]" not in strip_wl_comments_and_strings(body)
    assert 'UnsetEnvironment["FACET_MEMTRACE"]' in body
    assert '"FACET_MEMTRACE"' in launcher and '"FACET_MEMTRACE"' in body
    assert "Length[Rest[System`$ScriptCommandLine]] === 1" in launcher
    assert "Length[Rest[System`$ScriptCommandLine]] === 2" in body
    assert "packageFingerprintBefore === expectedPackageFingerprint" in body
    assert '"PackageDefinitionFingerprintSHA256"' in body
    checks += 10

    assert "driverMessagesRaw === {}" in body
    assert 'normalizedTranscript === ""' in body
    assert "CF300_driver_messages_v5_dirty_k146.txt" in body
    assert 'driverExitPayload =!= {"EXIT", 75}' in body
    assert embedded_hash(body, "expectedV1StripHash") == (
        "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976"
    )
    assert re.search(r"expectedStripBytes\s*=\s*15667\s*;", body)
    checks += 6

    for required in [
        "expectedTopLevelBeforeResult", "expectedTopLevelFinal",
        'FileNames["*.tmp*", outdir, Infinity] === {}',
        "SameQ[globalStatesAfter, globalStatesBefore]",
        "SameQ[systemLifecycleAfter, systemLifecycleBefore]",
        "hashHex[bodyFile] === bodyHashBefore",
        "hashHex[launcherFile] === launcherHashBefore",
        "CF300 S12 RECAPTURE V5 DIRTY K146 PRE-QUARANTINE PASS",
        "CF300 S12 RECAPTURE V5 DIRTY K146 QUARANTINE HEARTBEAT",
        "Pause[30]", "WorkerReusableQ", "CooperativeQuarantineRequiredQ",
    ]:
        assert required in body, required
        checks += 1
    assert "CF300 S12 RECAPTURE V5 DIRTY K146 ABORT QUARANTINE" in launcher
    assert "Pause[30]" in launcher
    assert "Abort[]" in launcher
    checks += 3

    assert "CF300_package_load_attempted_v5_dirty_k146.wl" in body
    assert body.index("loadAttemptHash = hashHex[loadAttemptFile]") < body.index(
        "packageLoadAttemptedQ = True"
    )
    assert body.index("System`Get[loadAttemptFile]") < body.index(
        "packageLoadAttemptedQ = True"
    )
    assert 'Import[releaseSentinelFile, "Text"]' in body
    assert 'Import[abortReleaseFile, "Text"]' in launcher
    assert "Get[releaseSentinelFile" not in strip_wl_comments_and_strings(body)
    assert "Get[abortReleaseFile" not in strip_wl_comments_and_strings(launcher)
    checks += 7

    success_loop = body[body.index("heartbeatCount = 0;"):body.index("      0,", body.index("heartbeatCount = 0;"))]
    failure_loop = body[body.index("CF300 S12 RECAPTURE V5 DIRTY K146 POST-LOAD FAILURE QUARANTINE"):]
    abort_loop = launcher[launcher.index("CF300 S12 RECAPTURE V5 DIRTY K146 ABORT QUARANTINE"):]
    assert success_loop.index("integrityQ = TrueQ[") < success_loop.index(
        "StringTrim[releaseText] === releaseToken"
    )
    assert failure_loop.index("failureIntegrityQ = TrueQ[") < failure_loop.index(
        "StringTrim[releaseText] === failureReleaseToken"
    )
    assert abort_loop.index("abortIntegrityQ = TrueQ[") < abort_loop.index(
        "StringTrim[abortReleaseText] ==="
    )
    for segment in [success_loop, failure_loop, abort_loop]:
        for required in [
            "expectedSourceManifestHash", "expectedKernelPoolSourceHash",
            "expectedPoolRunDefinitionHash", "expectedPreflightHash",
            "expectedV4StateHash", "expectedV4ReportHash",
        ]:
            assert required in segment, (required, segment[:80])
            checks += 1
    checks += 3

    assert 'expectedKernelID = 146' in probe
    assert "CreateDirectory" not in strip_wl_comments_and_strings(probe)
    assert "SetEnvironment" not in strip_wl_comments_and_strings(probe)
    assert "System`Names[\"Global`*\"]" in probe
    assert "SameQ[globalNamesAfter, globalNamesBefore]" in probe
    assert "SameQ[globalStatesAfter, globalStatesBefore]" in probe
    assert '"PackageDefinitionFingerprintSHA256"' in probe
    assert '"FeynCalcVersion"' in probe and '"FeynArtsVersion"' in probe
    assert "CF300_V5_DIRTY_K146_PACKAGE_FINGERPRINT_SHA256=" in probe
    assert "System`WriteString[System`First[System`$Output]" in probe
    assert "System`Head[System`First[System`$Output]] === System`OutputStream" in probe
    checks += 11

    assert "Length[existingPackageNames] === 1685" in preflight
    assert "unsafeDirtyDefinitionNames === {}" in preflight
    assert "unsafePackageShadowNames === {}" in preflight
    assert "SameQ[globalNamesAfter, globalNamesBefore]" in preflight
    assert "SameQ[statesAfter, statesBefore]" in preflight
    assert "packageFingerprintAfter === packageFingerprintBefore" in preflight
    assert 'feynCalcVersion === "10.2.1"' in preflight
    assert 'feynArtsVersion === "FeynArts 3.12 (27 Mar 2025)"' in preflight
    assert "4238350af2ff91a6687ea937446b9e6077318914593afe963d4d10026dfc5165" in preflight
    assert "7c23eed024fa4666a024c84e956f832960026c46b38edd91d90f4016422b1476" in preflight
    assert "AssociationMap[" in preflight
    for context in [
        '"FeynCalc`"', '"FeynArts`"', '"FeynFacet`"',
        '"FeynHelpers`"', '"FeynCalcLegacy`"', '"CANONICA`"',
    ]:
        assert context in preflight
        checks += 1
    assert "sourceCandidateNames === {}" not in preflight
    assert "existingPackageNames === {}" not in preflight
    assert "packageListHazards === {}" not in preflight
    checks += 8

    assert 'globalNamesBefore = System`Names["Global`*"]' in launcher
    assert "globalStatesBefore = AssociationMap[globalStateByName" in launcher
    assert 'ExportString[globalNamesBefore, "RawJSON"' in launcher
    assert "SameQ[AssociationMap[globalStateByName," in launcher
    assert 'System`Names["Global`*"]' in body
    assert "SameQ[globalNamesAfterCleanup, globalNamesBaseline]" in body
    assert "SameQ[globalBaselineStatesAfter, globalBaselineStatesBefore]" in body
    checks += 7

    safe_driver_parse = lambda src: (
        'System`$ContextPath = {"System`"}' in src
        and "ToExpression[driverParseText, InputForm, HoldComplete]" in src
        and "Get[driver]" not in strip_wl_comments_and_strings(src)
    )
    mutation_rejected(
        body,
        'System`$ContextPath = {"System`"}',
        'System`$ContextPath = {"Global`", "System`"}',
        safe_driver_parse,
        "Global context-path injection",
    )
    mutation_rejected(
        body,
        "ToExpression[driverParseText, InputForm, HoldComplete]",
        "Get[driver]",
        safe_driver_parse,
        "direct driver Get",
    )
    zero_messages = lambda src: (
        "driverMessagesRaw === {}" in src and 'normalizedTranscript === ""' in src
    )
    mutation_rejected(
        body,
        "driverMessagesRaw === {}",
        "ListQ[driverMessagesRaw]",
        zero_messages,
        "broad message acceptance",
    )
    fingerprint_safe = lambda src: (
        "packageFingerprintBefore === expectedPackageFingerprint" in src
        and "System`$KernelID === 146" in src
        and "Length[existingPackageNames] === 1685" in src
    )
    mutation_rejected(
        body,
        "packageFingerprintBefore === expectedPackageFingerprint",
        "StringQ[packageFingerprintBefore]",
        fingerprint_safe,
        "package fingerprint continuity removed",
    )
    mutation_rejected(
        body,
        "System`$KernelID === 146",
        "System`$KernelID > 0",
        fingerprint_safe,
        "K146 dispatch pin removed",
    )
    memtrace_safe = lambda src: (
        'UnsetEnvironment["FACET_MEMTRACE"]' in src
        and 'Append[Keys[environmentOverrides], "FACET_MEMTRACE"]' in src
    )
    mutation_rejected(
        body,
        'UnsetEnvironment["FACET_MEMTRACE"]',
        'Environment["FACET_MEMTRACE"]',
        memtrace_safe,
        "MEMTRACE not unset",
    )
    def quarantine_safe(src: str) -> bool:
        if "heartbeatCount = 0;" not in src:
            return False
        tail = src[src.index("heartbeatCount = 0;"):]
        if "\n      0," not in tail:
            return False
        success_tail = tail[:tail.index("\n      0,")]
        return (
            "CF300 S12 RECAPTURE V5 DIRTY K146 PRE-QUARANTINE PASS" in src
            and "While[True," in success_tail
            and "Pause[30]" in success_tail
        )
    mutation_rejected(
        body,
        "While[True,",
        "If[True,",
        quarantine_safe,
        "PASS returns without quarantine",
    )
    held_cleanup_safe = lambda src: (
        src.count("With[{literalName = name}") == 2
        and src.count("System`Remove[literalName]") == 2
        and src.count("System`ClearAll[literalName]") == 2
    )
    mutation_rejected(
        body,
        "System`Remove[literalName]",
        'System`Remove[name <> ""]',
        held_cleanup_safe,
        "held Remove receives a computed expression",
    )
    mutation_rejected(
        body,
        "With[{literalName = name}",
        "With[{wrongName = name}",
        held_cleanup_safe,
        "literal held-name substitution removed",
    )
    mutation_rejected(
        launcher,
        "System`Names[\"Global`*\"]",
        "Names[\"Global`*\"]",
        critical_system_qualified,
        "FeynCalc`Names shadow exposure",
    )
    mutation_rejected(
        preflight,
        "System`Remove[",
        "Remove[",
        critical_system_qualified,
        "unqualified Remove shadow exposure",
    )
    checks += 11

    print(f"PASS {checks}/" + str(checks))
    print("launcher", sha256(LAUNCHER))
    print("body", sha256(BODY))
    print("preflight", sha256(PREFLIGHT))
    print("probe", sha256(PROBE))
    print("census", sha256(CENSUS))
    print("inspector", sha256(INSPECTOR))
    print("driver", sha256(DRIVER))


if __name__ == "__main__":
    main()
