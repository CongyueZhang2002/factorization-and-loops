#!/usr/bin/env python3
"""Adversarial no-kernel audit for the materialized V5 K146 recovery."""

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
LAUNCHER = HERE / "run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146.wls"
BODY = HERE / "run_cf300_sector12_recapture_from_v4_xh_v5_dirty_k146_body.wls"
PREFLIGHT = HERE / "preflight_cf300_sector12_recapture_v5_dirty_k146_global_state.wls"
PROBE = HERE / "probe_cf300_sector12_recapture_v5_dirty_k146_k146.wls"
INSPECTOR = HERE / "inspect_cf300_sector12_recapture_v5_dirty_k146_paths.py"
SEAL = HERE / "cf300_sector12_recapture_v5_dirty_k146_path_seal.json"
OUTDIR = Path("/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v5_dirty_k146")

V4_HASHES = {
    "run_cf300_sector12_recapture_from_v4_xh_v4.wls":
        "8c033f6cee92e0b01b2e5b31ff45cdde1a20afb3706b1fd092f3cb93ff54197c",
    "run_cf300_sector12_recapture_from_v4_xh_v4_body.wls":
        "51f489e78ec5ea5f277b7b1c8b0ef18f2853d9d62795ce6a5327a2384caf9cc7",
    "preflight_cf300_sector12_recapture_v4_global_state.wls":
        "91249cb30209f2a19ee5eb980889024b98694ed21744e9a81f1f49142a330ae5",
    "probe_cf300_sector12_recapture_v4_virgin_k146.wls":
        "b3edd4eed9e3dcfb81ca4188325c01585791f128f1996ba572d5616fcf9ab44a",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def no_context_mark_line_end(text: str) -> bool:
    # The pool held-parser can silently truncate a qualified symbol if a code
    # line ends after its context mark and the basename starts on the next line.
    for line in text.splitlines():
        code = line.split("(*", 1)[0]
        if re.search(r"[A-Za-z$][A-Za-z0-9$]*`\s*$", code):
            return False
    return True


def require(text: str, tokens: tuple[str, ...]) -> None:
    for token in tokens:
        assert token in text, token


def fingerprint_contract(launcher: str, body: str, preflight: str, probe: str) -> bool:
    return all((
        "Length[Rest[System`$ScriptCommandLine]] === 1" in launcher,
        "expectedPackageFingerprint" in launcher,
        '"PackageDefinitionFingerprintSHA256"' in launcher,
        'Lookup[preflightReport,\n                "PackageDefinitionFingerprintSHA256", None] ===' in launcher,
        "Length[Rest[System`$ScriptCommandLine]] === 2" in body,
        "packageFingerprintBefore === expectedPackageFingerprint" in body,
        "System`$KernelID === 146" in body,
        "Length[existingPackageNames] === 1685" in body,
        "packageFingerprintAfterDriver" in body,
        '"PackageDefinitionFingerprintSHA256"' in body,
        "packageFingerprintAfter === packageFingerprintBefore" in preflight,
        "unsafeDirtyDefinitionNames === {}" in preflight,
        "unsafePackageShadowNames === {}" in preflight,
        'feynCalcVersion === "10.2.1"' in preflight,
        'feynArtsVersion === "FeynArts 3.12 (27 Mar 2025)"' in preflight,
        "SameQ[globalStatesAfter, globalStatesBefore]" in probe,
        '"PackageDefinitionFingerprintSHA256"' in probe,
        "CF300_V5_DIRTY_K146_PACKAGE_FINGERPRINT_SHA256=" in probe,
    ))


def main() -> None:
    launcher, body, preflight, probe = (
        path.read_text() for path in (LAUNCHER, BODY, PREFLIGHT, PROBE)
    )
    checks = 0

    for name, digest in V4_HASHES.items():
        assert sha(HERE / name) == digest
        checks += 1
    assert not os.path.lexists(OUTDIR)
    checks += 1

    for text in (launcher, body, preflight, probe):
        assert no_context_mark_line_end(text)
        for forbidden in (
            "KillProcess", "StartProcess", "RunProcess", "LaunchKernels",
            "CloseKernels", "Quit[]", "Remove[\"FeynCalc`*\"]",
            "Remove[\"FeynArts`*\"]", "Remove[\"FeynFacet`*\"]",
        ):
            assert forbidden not in text
            checks += 1
        checks += 1

    assert fingerprint_contract(launcher, body, preflight, probe)
    checks += 1
    for source_name, text, token in (
        ("launcher", launcher, "Length[Rest[System`$ScriptCommandLine]] === 1"),
        ("launcher", launcher, "Lookup[preflightReport,\n                \"PackageDefinitionFingerprintSHA256\", None] ==="),
        ("body", body, "packageFingerprintBefore === expectedPackageFingerprint"),
        ("body", body, "System`$KernelID === 146"),
        ("body", body, "Length[existingPackageNames] === 1685"),
        ("preflight", preflight, "unsafeDirtyDefinitionNames === {}"),
        ("preflight", preflight, "unsafePackageShadowNames === {}"),
        ("preflight", preflight, "packageFingerprintAfter === packageFingerprintBefore"),
        ("probe", probe, "SameQ[globalStatesAfter, globalStatesBefore]"),
    ):
        mutant = text.replace(token, "")
        parts = {"launcher": launcher, "body": body,
                 "preflight": preflight, "probe": probe}
        parts[source_name] = mutant
        assert not fingerprint_contract(parts["launcher"], parts["body"],
                                        parts["preflight"], parts["probe"]), token
        checks += 1

    require(preflight, (
        "Sort[packageListHazards] === Sort[",
        '{"CANONICA`", "FeynFacet`", "FeynArts`", "FeynCalc`"}',
        "Length[existingPackageNames] === 1685",
        '"Global`root"', '"Global`ranges"', '"Global`t0"',
        '"Global`variables"', '"Global`dD"',
        "4238350af2ff91a6687ea937446b9e6077318914593afe963d4d10026dfc5165",
        "7c23eed024fa4666a024c84e956f832960026c46b38edd91d90f4016422b1476",
    ))
    checks += 10
    assert "existingPackageNames === {}" not in preflight
    assert "sourceCandidateNames === {}" not in preflight
    checks += 2

    for name in ("root", "ranges", "t0", "variables", "dD"):
        assert f'"Global`{name}"' in body
        assert f"Global`{name}" in body
        checks += 2
    assert body.count("SameQ[globalStatesAfter, globalStatesBefore]") >= 1
    assert "SameQ[globalBaselineStatesAfter, globalBaselineStatesBefore]" in body
    checks += 2

    require(body, (
        'driverMessagesRaw === {}', 'normalizedTranscript === ""',
        'driverExitPayload =!= {"EXIT", 75}',
        "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976",
        "expectedStripBytes = 15667",
        "WorkerReusableQ", "CooperativeQuarantineRequiredQ",
        "While[True,", "Pause[30]",
    ))
    checks += 9

    seal = json.loads(SEAL.read_text())
    spec = importlib.util.spec_from_file_location("v5_paths", INSPECTOR)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    assert module.build_result() == seal
    checks += 3
    with tempfile.TemporaryDirectory(prefix="cf300-v5-adversary-") as tmp:
        tmp_path = Path(tmp)
        regular = tmp_path / "regular"
        regular.write_text("x\n")
        symlink = tmp_path / "symlink"
        dangling = tmp_path / "dangling"
        os.symlink(regular, symlink)
        os.symlink(tmp_path / "missing", dangling)
        assert not module.inspect_path("symlink", symlink, "file")["GateQ"]
        assert not module.inspect_path("dangling", dangling, "absent")["GateQ"]
        assert not module.inspect_path("wrong-kind", regular, "directory")["GateQ"]
        checks += 3

    assert "cf300_sector12_recapture_from_v4_xh_v4" not in str(OUTDIR)
    assert "v5_dirty_k146" in str(OUTDIR)
    assert "CF300-S12-V5-DIRTY-K146-PASS-RELEASE" in body
    assert "CF300-S12-V5-DIRTY-K146-FAIL-RELEASE" in body
    assert "CF300-S12-V5-DIRTY-K146-ABORT-RELEASE" in launcher
    checks += 5

    print(f"PASS {checks}/{checks} including 9 contract mutants; no Wolfram/native solver launched")


if __name__ == "__main__":
    main()
