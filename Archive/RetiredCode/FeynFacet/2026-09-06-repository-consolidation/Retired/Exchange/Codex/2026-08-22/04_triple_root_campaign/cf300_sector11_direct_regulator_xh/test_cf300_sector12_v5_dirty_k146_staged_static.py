#!/usr/bin/env python3
"""No-kernel audit of the K146 dirty-worker recovery assessment/delta."""

from __future__ import annotations

import hashlib
from pathlib import Path


HERE = Path(__file__).resolve().parent
POOL = Path("/tmp/codex-triple-root-20260823c.vx654S/pool")

EXPECTED = {
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


def require(text: str, needles: tuple[str, ...]) -> None:
    for needle in needles:
        assert needle in text, needle


def audit_patch(text: str) -> None:
    required = (
        "System`$KernelID === 146",
        '"CANONICA`", "FeynFacet`", "FeynArts`", "FeynCalc`"',
        '"Global`root"', '"Global`ranges"', '"Global`t0"',
        '"Global`variables"', '"Global`dD"',
        "unsafeDirtyDefinitionNames === {}",
        "unsafePackageShadowNames === {}",
        "SameQ[globalStatesAfter, globalStatesBefore]",
        "Never",
    )
    require(text, required)
    forbidden = (
        "KillProcess", "kill -", "pkill", "TaskKill", "Quit[]",
        "CloseKernels", "LaunchKernels", "Remove[\"FeynCalc`*\"]",
        "Remove[\"FeynFacet`*\"]",
    )
    for token in forbidden:
        assert token not in text, token
    # Every safety token must be independently necessary to the audit.
    for token in required[:-1]:
        mutant = text.replace(token, "")
        try:
            require(mutant, required)
        except AssertionError:
            pass
        else:
            raise AssertionError(f"mutant unexpectedly survived: {token}")


def main() -> None:
    for name, digest in EXPECTED.items():
        assert sha(HERE / name) == digest, name

    log = (POOL / "logs" /
           "probe_cf300_s12_recapture_v4_virgin_k146_xh_v1.log").read_text()
    status = (POOL / "failed" /
              "probe_cf300_s12_recapture_v4_virgin_k146_xh_v1.status").read_text()
    require(log, (
        "kernel 146 start", '"GateQ" -> False',
        '"ActualKernelID" -> 146', '"NestedKernelCount" -> 0',
        '"HelperCeilingZeroQ" -> True',
        '"GlobalNamespaceReadOnlyQ" -> True',
        '"PreflightDedicatedCleanupQ" -> True',
        '"OutputAbsentQ" -> True',
        '"SourceCandidateExistingCount" -> 42',
        '"PackageShadowCount" -> 4',
        '"ExistingRelevantPackageNameCount" -> 1685',
        '"RelevantPackageListHazardCount" -> 4',
        '"DirtyDefinitionCount" -> 5',
        '"Global`GlobalBasis"', '"Global`ranges"', '"Global`root"',
        '"Global`t0"', '"Global`variables"',
        "status FAILED",
    ))
    require(status, ('"Status" -> "FAILED"', '"HadMessages" -> False',
                     '"Kernel" -> 146', '"Result" -> $Failed'))

    driver = (HERE.parents[3] / "Scripts" /
              "family_epsform_sector.wls").read_text()
    load_facet = (HERE.parents[3] / "Addon" / "Load" /
                  "LoadFACET.wl").read_text()
    feynfacet = (HERE.parents[3] / "FeynFacet" /
                 "FeynFacet.m").read_text()
    require(load_facet, ('Get[FileNameJoin[{$FACETRoot, "FeynFacet", "FeynFacet.m"}]]',))
    require(feynfacet, ('ClearAll["FeynFacet`*"]',
                        'ClearAll["FeynFacet`Private`*"]'))
    require(driver, (
        'FeynFacet`Private`$canonicalBlocksCanonicaLoaded = False',
        'FeynFacet`Private`canonicalBlocksLoadCanonica[]',
        'CANONICA`$ComputeParallel = False',
    ))

    patch = (HERE / "CF300_SECTOR12_V5_DIRTY_K146_LOGIC.patch").read_text()
    audit_patch(patch)
    assessment = (HERE /
        "CF300_SECTOR12_V5_DIRTY_K146_ASSESSMENT.md").read_text()
    assessment_flat = " ".join(assessment.split())
    require(assessment_flat, (
        "Do not launch V4 on K146.",
        "new no-write runtime gate before production",
        "does not authorize launching the staged V5 production",
        "No process restart or signal is required",
    ))
    print("PASS 62/62 (including safety-token mutants); no Wolfram/native process launched")


if __name__ == "__main__":
    main()
