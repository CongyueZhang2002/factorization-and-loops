#!/usr/bin/env python3
"""No-kernel static/adversarial audit for CF300 V5b K146 recovery."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import re
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
POOL = Path("/tmp/codex-triple-root-20260823c.vx654S/pool")
LAUNCHER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146.wls"
BODY = HERE / "run_cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146_body.wls"
PREFLIGHT = HERE / "preflight_cf300_sector12_recapture_v5b_recovered_k146_global_state.wls"
PROBE = HERE / "probe_cf300_sector12_recapture_v5b_recovered_k146_k146.wls"
INSPECTOR = HERE / "inspect_cf300_sector12_recapture_v5b_recovered_k146_paths.py"
SEAL = HERE / "cf300_sector12_recapture_v5b_recovered_k146_path_seal.json"
OUTDIR = Path("/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146")

FROZEN_V5 = {
    "run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146.wls":
        "511b9b4c4d8a3675b214a90ec14d03d490a4954c9c772bd761a87d1b842ab05f",
    "run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146_body.wls":
        "183c8b460fba3fa4cea7693671f60f4377c55396abf80d0e8868a61c0abbc50b",
    "preflight_cf300_sector12_recapture_v5_dirty_k146_global_state.wls":
        "4065f4ad5c7315a71ae37e41732862bb9395bb17eb91ba9d0c2084053c1a5a23",
    "probe_cf300_sector12_recapture_v5_dirty_k146_k146.wls":
        "950000f94102ecfca4405eba5a789d53eacb3fed2a4b3751469ac65cfe4e790e",
    "inspect_cf300_sector12_recapture_v5_dirty_k146_paths.py":
        "dd3a6c3b37edeb9ce0f11f04e8453175f6816150a6106af4b5c76a649acfec11",
    "cf300_sector12_recapture_v5_dirty_k146_path_seal.json":
        "86aa2c45b42fa4e424016fb40ebb8e34f91c937b59c5bd564c5b00eaf5b8b693",
}

EVIDENCE = {
    POOL / "logs/probe_cf300_s12_recapture_v5_dirty_k146_no_write_xh_v1.log":
        "6ff4c1e8ab36ce8c54d6a50ee43ce86281792aa7c22c961d38a05503dcf7ea54",
    POOL / "failed/probe_cf300_s12_recapture_v5_dirty_k146_no_write_xh_v1.status":
        "ac3e8fd9c7df046eca0449092b9d335008e891e160c6c3d4508c55e881f8c650",
    POOL / "failed/probe_cf300_s12_recapture_v5_dirty_k146_no_write_xh_v1.wl":
        "c050689373138464a96579fec4e0f456f6cb7c9289dd0c05811705d0d5b59065",
    POOL / "logs/diagnose_definition_reader_hold_k146_xh_v2.log":
        "d46f89e2e9a56c19c4ecdf2dd1bf8866ae64df0514877cd3484fe19425d7c255",
    POOL / "done/diagnose_definition_reader_hold_k146_xh_v2.status":
        "b0f23ab9e8c92431e24b4940d97737bf25ea7ae6da11408cfc78384990694506",
    POOL / "logs/inspect_k146_context_lifecycle_xh_v1.log":
        "3d3e997de61b4e093d4605297c5e52f4d13b9e6d19c236a4b4a12d2330eda90c",
    POOL / "done/inspect_k146_context_lifecycle_xh_v1.status":
        "306412e295634c58003ead74981a5527cde9ebdb041c70c05704d5fcec823269",
}

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def strip_wl(source: str) -> str:
    out: list[str] = []
    i = 0
    depth = 0
    string = False
    while i < len(source):
        if depth:
            if source.startswith("(*", i):
                depth += 1; out.extend("  "); i += 2
            elif source.startswith("*)", i):
                depth -= 1; out.extend("  "); i += 2
            else:
                out.append("\n" if source[i] == "\n" else " "); i += 1
        elif string:
            if source[i] == "\\" and i + 1 < len(source):
                out.extend("  "); i += 2
            elif source[i] == '"':
                string = False; out.append(" "); i += 1
            else:
                out.append("\n" if source[i] == "\n" else " "); i += 1
        elif source.startswith("(*", i):
            depth = 1; out.extend("  "); i += 2
        elif source[i] == '"':
            string = True; out.append(" "); i += 1
        else:
            out.append(source[i]); i += 1
    assert not depth and not string
    return "".join(out)

def balanced(source: str) -> bool:
    stack: list[str] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for char in strip_wl(source):
        if char in "([{":
            stack.append(char)
        elif char in ")]}":
            if not stack or stack.pop() != pairs[char]:
                return False
    return not stack

def embedded_hash(source: str, name: str) -> str:
    match = re.search(rf"{re.escape(name)}\s*=\s*\n?\s*\"([0-9a-f]{{64}})\"", source)
    assert match, name
    return match.group(1)

def contract(parts: dict[str, str]) -> bool:
    launcher = parts["launcher"]
    body = parts["body"]
    preflight = parts["preflight"]
    probe = parts["probe"]
    required = (
        "System`$Context === \"Global`\"" in launcher,
        "System`Length[System`Rest[System`$ScriptCommandLine]] === 2" in launcher,
        "Length[Rest[System`$ScriptCommandLine]] === 2" in launcher,
        "expectedLifecycleFingerprint" in launcher,
        "$RecoveredLifecycleFingerprint" in launcher,
        "System`$Packages = resolvedBaselinePackages" in launcher,
        "packageEnvelopeQ" in launcher,
        "Length[Rest[System`$ScriptCommandLine]] === 3" in body,
        "Part[Rest[System`$ScriptCommandLine], 2]" in body,
        "System`Options[System`Unevaluated[symbol]]" in body,
        "preflightResult = CheckAbort[" in preflight,
        "System`Options[System`Unevaluated[symbol]]" in preflight,
        "System`$Context ===\n              \"CodexDefinitionReaderHoldDiagnosticK146XH`Private`\"" in probe,
        "System`Drop[\n            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages,\n            2]" in probe,
        "System`End[];" in probe,
        "System`EndPackage[];" in probe,
        "System`Options[System`Unevaluated[" in probe,
        "expectedV5PrivateNames" in probe,
        "expectedV1PrivateNames" in probe,
        "CF300_V5B_RECOVERED_K146_PACKAGE_FINGERPRINT_SHA256=" in probe,
        "CF300_V5B_RECOVERED_K146_LIFECYCLE_SHA256=" in probe,
        "packageEnvelopeQ" in probe,
    )
    return all(required)

def main() -> None:
    sources = {
        "launcher": LAUNCHER.read_text(),
        "body": BODY.read_text(),
        "preflight": PREFLIGHT.read_text(),
        "probe": PROBE.read_text(),
    }
    checks = 0

    for path in (LAUNCHER, BODY, PREFLIGHT, PROBE, INSPECTOR, SEAL):
        assert path.is_file(), path
        checks += 1
    assert not os.path.lexists(OUTDIR)
    checks += 1

    for name, digest in FROZEN_V5.items():
        assert sha(HERE / name) == digest, name
        checks += 1
    for path, digest in EVIDENCE.items():
        assert sha(path) == digest, path
        checks += 1

    feynarts = ROOT / "Addon/Mathematica_Addon/FeynArts/FeynArts/Initialize.m"
    assert sha(feynarts) == "db2bd29ac8215640bea3df31360431e7c94bd135c4d3e41fe255e9e1450a6142"
    text = feynarts.read_text()
    assert "M$ClassesDescription := (" in text
    assert "Message[M$ClassesDescription::undefinedmod];" in text
    assert "Abort[]; );" in text
    checks += 4

    for label, source in sources.items():
        assert balanced(source), label
        executable = strip_wl(source)
        assert not re.search(
            r"(?<![A-Za-z0-9$`])(?:KillProcess|StartProcess|RunProcess|"
            r"LaunchKernels|CloseKernels|Quit)\s*\[", executable
        ), label
        assert "Remove[\"FeynCalc`*\"]" not in source
        assert "Remove[\"FeynArts`*\"]" not in source
        assert "Remove[\"FeynFacet`*\"]" not in source
        for match in re.finditer(r"System`Options\[", executable):
            assert executable[match.end():match.end()+40].lstrip().startswith(
                "System`Unevaluated["
            ), (label, executable[match.start():match.start()+100])
        assert '"Messages" -> System`Messages[' in source
        checks += 7

    assert sources["launcher"].index(
        "System`If[! System`TrueQ["
    ) < sources["launcher"].index("BeginPackage[")
    assert sources["probe"].index(
        "CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`result"
    ) < sources["probe"].index("BeginPackage[")
    checks += 2

    assert contract(sources)
    checks += 1
    mutations = [
        ("launcher", 'System`$Context === "Global`"', "System`True"),
        ("launcher", " === 2 &&", " === 1 &&"),
        ("launcher", "expectedLifecycleFingerprint", "removedLifecycle"),
        ("launcher", "packageEnvelopeQ", "packageEnvelopeRemoved"),
        ("launcher", "System`$Packages = resolvedBaselinePackages", "Null"),
        ("body", "Length[Rest[System`$ScriptCommandLine]] === 3",
         "Length[Rest[System`$ScriptCommandLine]] === 2"),
        ("body", "Part[Rest[System`$ScriptCommandLine], 2]", "$Failed"),
        ("body", "System`Options[System`Unevaluated[symbol]]",
         "System`Options[symbol]"),
        ("preflight", "preflightResult = CheckAbort[",
         "preflightResult = Identity["),
        ("preflight", "System`Options[System`Unevaluated[symbol]]",
         "System`Options[symbol]"),
        ("probe", "expectedV5PrivateNames", "expectedV5NamesRemoved"),
        ("probe", "expectedV1PrivateNames", "expectedV1NamesRemoved"),
        ("probe", "System`End[];", "Null;",),
        ("probe", "System`EndPackage[];", "Null;",),
        ("probe", "System`Options[System`Unevaluated[",
         "System`Options["),
        ("probe", "CF300_V5B_RECOVERED_K146_LIFECYCLE_SHA256=",
         "LIFECYCLE_TOKEN_REMOVED="),
        ("probe", "packageEnvelopeQ", "packageEnvelopeRemoved"),
    ]
    for label, old, new in mutations:
        mutant = dict(sources)
        assert old in mutant[label], (label, old)
        mutant[label] = mutant[label].replace(old, new)
        assert not contract(mutant), (label, old)
        checks += 1

    p = sources["probe"]
    v5_block = p[p.index("expectedV5PrivateNames ="):
                 p.index("expectedV1PrivateNames =")]
    v1_block = p[p.index("expectedV1PrivateNames ="):
                 p.index("v5Names =")]
    v5_names = sorted(set(re.findall(
        r'"(CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`[^"]+)"',
        v5_block)))
    v1_names = sorted(set(re.findall(
        r'"(CodexDefinitionReaderHoldDiagnosticK146XH`Private`[^"]+)"',
        v1_block)))
    assert len(v5_names) == 52
    assert len(v1_names) == 28
    assert hashlib.sha256(("\n".join(v5_names)+"\n").encode()).hexdigest() == (
        "5bba1dead4c350d76234d248cd64b99b84db0e889a6f9032e2c0a3c456afb172"
    )
    assert hashlib.sha256(("\n".join(v1_names)+"\n").encode()).hexdigest() == (
        "ef362b5a634c07f9ea5c737b1e033f326bbb9d044c942997ddf23654211f3e37"
    )
    checks += 4

    order = [
        p.index('"diagnostic End unwind"'),
        p.index('"diagnostic EndPackage unwind"'),
        p.index('"V5 probe End unwind"'),
        p.index('"V5 probe EndPackage unwind"'),
        p.index("System`$Packages =\n          System`Drop["),
        p.index('System`Remove[\n          "CodexDefinitionReaderHoldDiagnostic'),
        p.index('System`Remove[\n          "CodexCF300Sector12RecaptureV5Dirty'),
    ]
    assert order == sorted(order)
    assert 'Take[\n              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages,\n              3]' in p
    assert '{"CodexDefinitionReaderHoldDiagnosticK146XH`",' in p
    assert '"CodexCF300Sector12RecaptureV5DirtyK146Probe`",' in p
    assert '"CodexCF300Sector12RecaptureV4Probe`"}' in p
    checks += 5

    assert embedded_hash(sources["launcher"], "expectedBodyHash") == sha(BODY)
    assert embedded_hash(sources["launcher"], "expectedPreflightHash") == sha(PREFLIGHT)
    assert embedded_hash(sources["launcher"], "expectedPathSealHash") == sha(SEAL)
    assert embedded_hash(sources["launcher"], "expectedPathInspectorHash") == sha(INSPECTOR)
    assert embedded_hash(sources["body"], "expectedPreflightHash") == sha(PREFLIGHT)
    assert embedded_hash(sources["body"], "expectedPathSealHash") == sha(SEAL)
    assert embedded_hash(sources["body"], "expectedPathInspectorHash") == sha(INSPECTOR)
    assert embedded_hash(sources["probe"], "expectedPreflightHash") == sha(PREFLIGHT)
    assert embedded_hash(sources["probe"], "expectedPathSealHash") == sha(SEAL)
    checks += 9

    seal = json.loads(SEAL.read_text())
    assert seal["Schema"] == "CF300Sector12RecaptureV5bRecoveredK146PathSealV1"
    assert seal["GateQ"] is True and seal["RecordCount"] == 21
    assert len(seal["Records"]) == 21
    assert all(record["GateQ"] is True for record in seal["Records"])
    spec = importlib.util.spec_from_file_location("v5b_paths", INSPECTOR)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    assert module.build_result() == seal
    checks += 6
    with tempfile.TemporaryDirectory(prefix="cf300-v5b-adversary-") as tmp:
        base = Path(tmp)
        regular = base / "regular"
        regular.write_text("sealed\n")
        linked = base / "linked"
        dangling = base / "dangling"
        os.symlink(regular, linked)
        os.symlink(base / "missing", dangling)
        assert not module.inspect_path("linked", linked, "file")["GateQ"]
        assert not module.inspect_path("dangling", dangling, "absent")["GateQ"]
        assert not module.inspect_path("kind", regular, "directory")["GateQ"]
        checks += 3

    assert "CF300-S12-V5B-RECOVERED-K146-PASS-RELEASE-41e1af21ab824c19a99fbb177579f04c" in sources["body"]
    assert "CF300-S12-V5B-RECOVERED-K146-FAIL-RELEASE-75d04ab49d6e4cb2ba464214acc8b307" in sources["body"]
    assert "CF300-S12-V5B-RECOVERED-K146-ABORT-RELEASE-844aa732c3b24e3693ff463beb74089e" in sources["launcher"]
    checks += 3

    print(f"PASS {checks}/{checks}; {len(mutations)} adversarial contract mutants; no Wolfram/native process launched")

if __name__ == "__main__":
    main()
