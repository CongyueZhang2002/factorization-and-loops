#!/usr/bin/env python3
"""Deterministic lstat/realpath seal for CF300 V5b recovered-K146 recapture paths.

The script is read-only and prints one compact JSON object.  Existing inputs
must be regular, non-symlink files/directories whose real path equals their
absolute path.  The V5b recovered-K146 output must not lexist, which also rejects a dangling
symlink.  Every existing path component is checked with lstat.
"""

from __future__ import annotations

import json
import os
import stat
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops")
BUNDLE = ROOT / "External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh"
POOL = Path("/tmp/codex-triple-root-20260823c.vx654S/pool")
OUTDIR = Path("/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146")
V4_CANDIDATE = (
    ROOT
    / "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving"
    / "triple_root_2026-08-23/CF300_direct_regulator_v4_candidate"
)


EXPECTED: dict[str, tuple[Path, str]] = {
    "RepositoryRoot": (ROOT, "directory"),
    "BundleDirectory": (BUNDLE, "directory"),
    "Launcher": (BUNDLE / "run_cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146.wls", "file"),
    "Body": (BUNDLE / "run_cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146_body.wls", "file"),
    "Preflight": (BUNDLE / "preflight_cf300_sector12_recapture_v5b_recovered_k146_global_state.wls", "file"),
    "VirginProbe": (BUNDLE / "probe_cf300_sector12_recapture_v5b_recovered_k146_k146.wls", "file"),
    "Census": (BUNDLE / "family_sector_driver_global_census_v1.json", "file"),
    "CensusInspector": (BUNDLE / "inspect_family_sector_driver_global_census_v1.py", "file"),
    "SourceManifest": (BUNDLE / "CF300_RESUME_SOURCE_SHA256SUMS", "file"),
    "Driver": (ROOT / "Scripts/family_epsform_sector.wls", "file"),
    "KernelPoolSource": (ROOT / "Scripts/KernelPool.wls", "file"),
    "PoolRunDefinition": (POOL / "poolrun_definition.m", "file"),
    "ValidatorV2": (BUNDLE / "validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls", "file"),
    "ValidatorV2Evidence": (BUNDLE / "cf300_s11_postwrite_validator_xh_v2_OK.log", "file"),
    "FormalResult": (BUNDLE / "cf300_sector11_postwrite_formal_inspector_v4_result.json", "file"),
    "V4State": (V4_CANDIDATE / "sector_state_CF300_standard.wl", "file"),
    "V4Report": (V4_CANDIDATE / "cf300_sector11_direct_regulator_report_v4.wl", "file"),
    "V1Strip": (
        Path("/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v1")
        / "sector_CF300_standard/CF300_12_11_input.wl",
        "file",
    ),
    "V2Strip": (
        Path("/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v2")
        / "sector_CF300_standard/CF300_12_11_input.wl",
        "file",
    ),
    "OutputParent": (OUTDIR.parent, "directory"),
    "OutputDirectory": (OUTDIR, "absent"),
}


def component_records(path: Path) -> list[dict[str, object]]:
    absolute = Path(os.path.abspath(path))
    records: list[dict[str, object]] = []
    parts = absolute.parts
    current = Path(parts[0])
    for part in parts[1:]:
        current /= part
        if not os.path.lexists(current):
            break
        mode = os.lstat(current).st_mode
        records.append(
            {
                "Path": str(current),
                "IsSymlink": stat.S_ISLNK(mode),
            }
        )
    return records


def inspect_path(label: str, path: Path, expected: str) -> dict[str, object]:
    absolute = Path(os.path.abspath(path))
    lexists = os.path.lexists(absolute)
    is_symlink = lexists and stat.S_ISLNK(os.lstat(absolute).st_mode)
    if not lexists:
        actual = "absent"
    elif stat.S_ISREG(os.lstat(absolute).st_mode):
        actual = "file"
    elif stat.S_ISDIR(os.lstat(absolute).st_mode):
        actual = "directory"
    else:
        actual = "other"
    components = component_records(absolute)
    component_symlinks = [r["Path"] for r in components if r["IsSymlink"]]
    real_equals_absolute = (
        os.path.realpath(absolute) == str(absolute) if lexists else None
    )
    gate = (
        actual == expected
        and not is_symlink
        and not component_symlinks
        and (expected == "absent" or real_equals_absolute is True)
    )
    return {
        "Label": label,
        "Path": str(absolute),
        "ExpectedKind": expected,
        "ActualKind": actual,
        "Lexists": lexists,
        "IsSymlink": bool(is_symlink),
        "RealPathEqualsAbsolutePath": real_equals_absolute,
        "SymlinkComponents": component_symlinks,
        "GateQ": gate,
    }


def build_result() -> dict[str, object]:
    records = [inspect_path(label, path, kind) for label, (path, kind) in EXPECTED.items()]
    return {
        "Schema": "CF300Sector12RecaptureV5bRecoveredK146PathSealV1",
        "GateQ": all(record["GateQ"] for record in records),
        "RecordCount": len(records),
        "Records": records,
    }


if __name__ == "__main__":
    print(json.dumps(build_result(), sort_keys=True, separators=(",", ":")))



