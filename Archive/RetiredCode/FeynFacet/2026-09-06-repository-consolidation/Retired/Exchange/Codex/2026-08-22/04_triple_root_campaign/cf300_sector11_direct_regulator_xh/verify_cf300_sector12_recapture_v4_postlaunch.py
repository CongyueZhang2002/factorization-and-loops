#!/usr/bin/env python3
"""Read-only verifier for the CF300 V4 probe and quarantined recapture.

The verifier never writes a release sentinel, never mutates a pool artifact,
and never signals or inspects a process through an API.  It only opens regular,
non-symlink files for reading and uses lstat/stat/hash comparisons.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Mapping


ROOT = Path("/home/maxzhang/factorization-and-loops")
BUNDLE = (
    ROOT
    / "External/CodexExchange/triple_root_2026-08-22"
    / "cf300_sector11_direct_regulator_xh"
)
POOL = Path("/tmp/codex-triple-root-20260823c.vx654S/pool")
OUTDIR = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_sector12_recapture_from_v4_xh_v4"
)

PROBE_MISSION = "probe_cf300_s12_recapture_v4_virgin_k146_xh_v1"
PRODUCTION_MISSION = "cf300_s12_recapture_from_v4_xh_v4"
EXPECTED_KERNEL = 146

STRIP_SHA256 = "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976"
STRIP_BYTES = 15667
STATE_SHA256 = "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009"
EMPTY_SHA256 = hashlib.sha256(b"").hexdigest()

V4_MANIFEST = BUNDLE / "CF300_SECTOR12_RECAPTURE_FROM_V4_V4_SHA256SUMS"
V4_MANIFEST_SHA256 = "1a878a0f3f73fd397b68fa80cada6e689ceeae58b1b1d79ed06d7aa0a16edf17"

# Direct pins supplement the frozen V4 manifest with runtime/provenance files
# that the body checks before and throughout its cooperative quarantine.
DEFAULT_SOURCE_PINS: dict[Path, str] = {
    BUNDLE / "run_cf300_sector12_recapture_from_v4_xh_v4.wls":
        "8c033f6cee92e0b01b2e5b31ff45cdde1a20afb3706b1fd092f3cb93ff54197c",
    BUNDLE / "run_cf300_sector12_recapture_from_v4_xh_v4_body.wls":
        "51f489e78ec5ea5f277b7b1c8b0ef18f2853d9d62795ce6a5327a2384caf9cc7",
    BUNDLE / "preflight_cf300_sector12_recapture_v4_global_state.wls":
        "91249cb30209f2a19ee5eb980889024b98694ed21744e9a81f1f49142a330ae5",
    BUNDLE / "probe_cf300_sector12_recapture_v4_virgin_k146.wls":
        "b3edd4eed9e3dcfb81ca4188325c01585791f128f1996ba572d5616fcf9ab44a",
    BUNDLE / "inspect_cf300_sector12_recapture_v4_paths.py":
        "c6bfcee4603e5d2b0248a5dc8c02320f7a1d3fac3f4075e6f869d634caa6a0cd",
    BUNDLE / "cf300_sector12_recapture_v4_path_seal.json":
        "6f326c92c6f9948f0fcb4c10f8e1052da446ac4ea9a5baf3cc71d177f690e44e",
    BUNDLE / "family_sector_driver_global_census_v1.json":
        "990e086691cd0651823df256e019e6d7e32042b64951ded39f4f31ad8e16c377",
    BUNDLE / "inspect_family_sector_driver_global_census_v1.py":
        "89d27f01e6ab92bcf64fff60085f8c87115edab02d86b8ebf9691886735da6ae",
    BUNDLE / "CF300_RESUME_SOURCE_SHA256SUMS":
        "880c4f7850b2c0daf5c207e96df23113c91d75d1056e23c6edc169aec66487b2",
    ROOT / "Scripts/family_epsform_sector.wls":
        "6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1",
    ROOT / "Scripts/KernelPool.wls":
        "0758f0f95a24b5dee4c6162939388ca5641610ef5e73bb73775a2030e8ff069d",
    POOL / "poolrun_definition.m":
        "d49632694d4da9f47a7c3c0d9828e98d47f9a416c9cb72d8a10a74b9b011db51",
    BUNDLE / "validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls":
        "304e7748e3971e9b0bf50fc84b10f50cda8231d49d6df235327134a297c45759",
    BUNDLE / "cf300_s11_postwrite_validator_xh_v2_OK.log":
        "185d009d9ed4a56037c3360a14862b97e8e39cfbe8e591c5d6bc38d936d45f3e",
    BUNDLE / "cf300_sector11_postwrite_formal_inspector_v4_result.json":
        "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128",
    ROOT / (
        "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/"
        "FamilyEpsFormsSolving/triple_root_2026-08-23/"
        "CF300_direct_regulator_v4_candidate/sector_state_CF300_standard.wl"
    ): STATE_SHA256,
    ROOT / (
        "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/"
        "FamilyEpsFormsSolving/triple_root_2026-08-23/"
        "CF300_direct_regulator_v4_candidate/"
        "cf300_sector11_direct_regulator_report_v4.wl"
    ): "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e",
}


class VerificationError(RuntimeError):
    pass


@dataclass(frozen=True)
class Config:
    pool: Path = POOL
    outdir: Path = OUTDIR
    bundle: Path = BUNDLE
    probe_mission: str = PROBE_MISSION
    production_mission: str = PRODUCTION_MISSION
    expected_kernel: int = EXPECTED_KERNEL
    source_pins: Mapping[Path, str] | None = None
    manifest: Path = V4_MANIFEST
    manifest_sha256: str = V4_MANIFEST_SHA256

    def pins(self) -> Mapping[Path, str]:
        return DEFAULT_SOURCE_PINS if self.source_pins is None else self.source_pins


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VerificationError(message)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def safe_components(path: Path) -> None:
    """Reject every symlink in the existing prefix of an absolute path."""
    absolute = Path(os.path.abspath(path))
    current = Path(absolute.anchor)
    for part in absolute.parts[1:]:
        current /= part
        if not os.path.lexists(current):
            break
        mode = os.lstat(current).st_mode
        require(not stat.S_ISLNK(mode), f"symlink path component: {current}")


def read_regular(path: Path) -> bytes:
    safe_components(path)
    require(os.path.lexists(path), f"missing file: {path}")
    mode = os.lstat(path).st_mode
    require(stat.S_ISREG(mode), f"not a regular file: {path}")
    before = os.stat(path, follow_symlinks=False)
    with path.open("rb") as stream:
        data = stream.read()
    after = os.stat(path, follow_symlinks=False)
    stable = (
        before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns
    ) == (
        after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns
    )
    require(stable, f"file changed while being read: {path}")
    require(len(data) == after.st_size, f"short read: {path}")
    return data


def read_text(path: Path) -> str:
    try:
        return read_regular(path).decode("utf-8")
    except UnicodeDecodeError as exc:
        raise VerificationError(f"non-UTF-8 text file: {path}") from exc


def hash_regular(path: Path) -> str:
    return sha256_bytes(read_regular(path))


def wl_compact(text: str) -> str:
    # Put/InputForm may split long strings as backslash-newline continuations.
    text = re.sub(r"\\\r?\n\s*", "", text)
    return re.sub(r"\s+", " ", text).strip()


def require_tokens(text: str, tokens: Iterable[str], label: str) -> None:
    for token in tokens:
        require(token in text, f"{label}: missing token {token!r}")


def no_wolfram_messages(text: str, label: str) -> None:
    message = re.search(r"[A-Za-z$][A-Za-z0-9$`]*::[A-Za-z0-9$]+", text)
    if message is not None:
        raise VerificationError(
            f"{label}: Wolfram message signature {message.group(0)!r}"
        )


def verify_manifest(config: Config) -> dict[str, object]:
    require(hash_regular(config.manifest) == config.manifest_sha256,
            "frozen V4 manifest hash mismatch")
    lines = [line.strip() for line in read_text(config.manifest).splitlines()
             if line.strip()]
    require(len(lines) == 10, "frozen V4 manifest must contain 10 records")
    seen: set[str] = set()
    for line in lines:
        match = re.fullmatch(r"([0-9a-f]{64})  ([^/][^\n]*)", line)
        require(match is not None, f"malformed manifest line: {line!r}")
        expected, relative = match.groups()
        require(".." not in Path(relative).parts, f"unsafe manifest path: {relative}")
        require(relative not in seen, f"duplicate manifest path: {relative}")
        seen.add(relative)
        require(hash_regular(config.bundle / relative) == expected,
                f"manifest member hash mismatch: {relative}")
    for path, expected in config.pins().items():
        require(hash_regular(path) == expected, f"source pin mismatch: {path}")
    return {"ManifestRecordCount": len(lines), "DirectPinCount": len(config.pins())}


def mission_paths(config: Config, mission: str) -> dict[str, Path]:
    return {
        "done_status": config.pool / "done" / f"{mission}.status",
        "done_wrapper": config.pool / "done" / f"{mission}.wl",
        "failed_status": config.pool / "failed" / f"{mission}.status",
        "failed_wrapper": config.pool / "failed" / f"{mission}.wl",
        "running_kernel": config.pool / "running" / f"{mission}.kernel",
        "running_wrapper": config.pool / "running" / f"{mission}.wl",
        "queued_wrapper": config.pool / "queue" / f"{mission}.wl",
        "log": config.pool / "logs" / f"{mission}.log",
    }


def verify_probe(config: Config, require_live_output_absent: bool) -> dict[str, object]:
    paths = mission_paths(config, config.probe_mission)
    require(not os.path.lexists(paths["failed_status"]), "probe is filed FAILED")
    require(not os.path.lexists(paths["failed_wrapper"]), "probe has failed wrapper")
    require(not os.path.lexists(paths["running_kernel"]), "probe is still running")
    require(not os.path.lexists(paths["running_wrapper"]), "probe wrapper still running")
    require(not os.path.lexists(paths["queued_wrapper"]), "probe is still queued")

    status = wl_compact(read_text(paths["done_status"]))
    wrapper = read_text(paths["done_wrapper"])
    log = wl_compact(read_text(paths["log"]))
    require_tokens(status, [
        f'"Mission" -> "{config.probe_mission}.wl"',
        '"Status" -> "OK"', '"HadMessages" -> False',
        f'"Kernel" -> {config.expected_kernel}', '"Result" -> 0',
    ], "probe status")
    require_tokens(wrapper, [
        "KernelPoolMission`$TaskBrokerMaxHelpers = 0",
        str(config.bundle / "probe_cf300_sector12_recapture_v4_virgin_k146.wls"),
    ], "probe wrapper")
    require_tokens(log, [
        f"MISSION {config.probe_mission}.wl kernel {config.expected_kernel} start",
        "CF300 S12 RECAPTURE V4 K146 VIRGIN PROBE",
        '"GateQ" -> True',
        f'"ExpectedKernelID" -> {config.expected_kernel}',
        f'"ActualKernelID" -> {config.expected_kernel}',
        '"NestedKernelCount" -> 0',
        '"HelperCeilingZeroQ" -> True',
        '"PathSealGateQ" -> True',
        '"GlobalNamespaceReadOnlyQ" -> True',
        '"PreflightDedicatedCleanupQ" -> True',
        '"OutputAbsentQ" -> True',
        '"ExistingRelevantPackageNameCount" -> 0',
        '"RelevantPackageListHazardCount" -> 0',
        '"DirtyDefinitionCount" -> 0',
        '"PackageShadowCount" -> 0',
        '"StateReadGateQ" -> True',
        '"GlobalNamespaceReadOnlyQ" -> True',
        '"ImportMessages" -> {}',
        "CF300 S12 RECAPTURE V4 PROBE CLEANUP",
        '"CleanupQ" -> True',
        "status OK",
    ], "probe log")
    no_wolfram_messages(log, "probe log")
    require("FAIL" not in log, "probe log contains FAIL")
    if require_live_output_absent:
        safe_components(config.outdir)
        require(not os.path.lexists(config.outdir),
                "V4 output appeared before production dispatch")
    return {
        "GateQ": True,
        "Kernel": config.expected_kernel,
        "HadMessages": False,
        "LiveOutputAbsentCheckedQ": require_live_output_absent,
        "StatusSHA256": sha256_bytes(status.encode()),
        "LogSHA256": hash_regular(paths["log"]),
    }


def exact_inventory(outdir: Path) -> dict[str, Path]:
    safe_components(outdir)
    require(os.path.lexists(outdir), f"production outdir absent: {outdir}")
    require(stat.S_ISDIR(os.lstat(outdir).st_mode), f"outdir is not a directory: {outdir}")
    expected = {
        "CF300_driver_messages_v4.txt": "file",
        "CF300_package_load_attempted_v4.wl": "file",
        "CF300_prequarantine_pass_v4.wl": "file",
        "CF300_sector12_recapture_launch_seal_v4.wl": "file",
        "CF300_sector12_recapture_result_v4.wl": "file",
        "pre_sector12_snapshot_CF300_standard.wl": "file",
        "sector_state_CF300_standard.wl": "file",
        "sector_CF300_standard": "directory",
    }
    actual = {entry.name: entry for entry in os.scandir(outdir)}
    require(set(actual) == set(expected),
            f"top-level inventory mismatch: {sorted(actual)}")
    resolved: dict[str, Path] = {}
    for name, kind in expected.items():
        entry = actual[name]
        mode = entry.stat(follow_symlinks=False).st_mode
        require(not entry.is_symlink(), f"symlink output entry: {entry.path}")
        require(stat.S_ISREG(mode) if kind == "file" else stat.S_ISDIR(mode),
                f"wrong output kind for {name}: {kind}")
        resolved[name] = Path(entry.path)
    scratch = resolved["sector_CF300_standard"]
    scratch_entries = {entry.name: entry for entry in os.scandir(scratch)}
    require(set(scratch_entries) == {"CF300_12_11_input.wl"},
            f"scratch inventory mismatch: {sorted(scratch_entries)}")
    strip_entry = scratch_entries["CF300_12_11_input.wl"]
    require(not strip_entry.is_symlink() and
            stat.S_ISREG(strip_entry.stat(follow_symlinks=False).st_mode),
            "strip is not a regular non-symlink file")
    resolved["strip"] = Path(strip_entry.path)
    for root, directories, files in os.walk(outdir, followlinks=False):
        for name in directories + files:
            require(".tmp" not in name, f"temporary artifact present: {root}/{name}")
    return resolved


def last_complete_heartbeat(compact_log: str) -> str:
    marker = "CF300 S12 RECAPTURE V4 QUARANTINE HEARTBEAT"
    starts = [match.start() for match in re.finditer(re.escape(marker), compact_log)]
    require(bool(starts), "no production quarantine heartbeat")
    complete: list[str] = []
    for index, start in enumerate(starts):
        end = starts[index + 1] if index + 1 < len(starts) else len(compact_log)
        segment = compact_log[start:end]
        if '"IntegrityQ" ->' in segment and '"ReleaseSentinelPresentQ" ->' in segment:
            complete.append(segment)
    require(bool(complete), "no complete production heartbeat")
    return complete[-1]


def verify_production(config: Config) -> dict[str, object]:
    source_report = verify_manifest(config)
    probe_report = verify_probe(config, require_live_output_absent=False)
    paths = mission_paths(config, config.production_mission)
    require(not os.path.lexists(paths["done_status"]),
            "production unexpectedly returned to pool/done")
    require(not os.path.lexists(paths["failed_status"]),
            "production is filed FAILED")
    require(not os.path.lexists(paths["queued_wrapper"]),
            "production is still queued")
    require(read_text(paths["running_kernel"]).strip() == str(config.expected_kernel),
            "production running marker is not K146")
    wrapper = read_text(paths["running_wrapper"])
    require_tokens(wrapper, [
        "KernelPoolMission`$TaskBrokerMaxHelpers = 0",
        str(config.bundle / "run_cf300_sector12_recapture_from_v4_xh_v4.wls"),
    ], "production wrapper")

    inventory = exact_inventory(config.outdir)
    require(hash_regular(inventory["sector_state_CF300_standard.wl"]) == STATE_SHA256,
            "recapture state hash mismatch")
    require(hash_regular(inventory["pre_sector12_snapshot_CF300_standard.wl"]) == STATE_SHA256,
            "pre-sector12 snapshot hash mismatch")
    strip = read_regular(inventory["strip"])
    require(len(strip) == STRIP_BYTES, "strip byte count mismatch")
    require(sha256_bytes(strip) == STRIP_SHA256, "strip hash mismatch")
    transcript = read_regular(inventory["CF300_driver_messages_v4.txt"])
    require(transcript == b"", "driver message transcript is nonempty")
    require(sha256_bytes(transcript) == EMPTY_SHA256,
            "empty transcript hash invariant failed")

    result_path = inventory["CF300_sector12_recapture_result_v4.wl"]
    marker_path = inventory["CF300_prequarantine_pass_v4.wl"]
    result_raw = read_regular(result_path)
    marker_raw = read_regular(marker_path)
    result_hash = sha256_bytes(result_raw)
    marker_hash = sha256_bytes(marker_raw)
    result = wl_compact(result_raw.decode("utf-8"))
    marker = wl_compact(marker_raw.decode("utf-8"))
    require_tokens(result, [
        '"Status" -> "CF300Sector12RecapturePreQuarantinePassedV4"',
        '"Family" -> "CF300"', '"SourceSector" -> 11',
        '"TargetSector" -> 12', '"LowerSector" -> 11',
        f'"WorkerKernelID" -> {config.expected_kernel}',
        '"NestedKernelCount" -> 0', '"TaskBrokerMaxHelpers" -> 0',
        '"IntentionalDriverExit" -> {"EXIT", 75}',
        '"ZeroDriverMessagesQ" -> True',
        '"DriverMessageSignatures" -> {}',
        '"DedicatedDriverContextRemovedQ" -> True',
        '"ExplicitGlobalDefinitionStateRestoredQ" -> True',
        '"ExactGlobalNamespaceRestoredQ" -> True',
        '"GlobalCleanupMessages" -> {}',
        '"SystemLifecycleRestoredQ" -> True',
        '"EnvironmentRestoredQ" -> True',
        '"ScriptCommandLineRestoredQ" -> True',
        '"DirectoryRestoredQ" -> True',
        '"RecaptureStateUnchangedQ" -> True',
        '"FreshStripExactReconstructionQ" -> True',
        f'"FreshStripSHA256" -> "{STRIP_SHA256}"',
        f'"FreshStripBytes" -> {STRIP_BYTES}',
        '"NoStaleSector12CheckpointQ" -> True',
        '"ExactTopLevelInventoryBeforeResultQ" -> True',
        '"NoTemporaryFilesQ" -> True',
        '"V4CandidateImmutableQ" -> True',
        f'"StateSHA256" -> "{STATE_SHA256}"',
        f'"SnapshotSHA256" -> "{STATE_SHA256}"',
        '"WorkerReusableQ" -> False',
        '"CooperativeQuarantineRequiredQ" -> True',
    ], "production result")
    result_provenance_hashes = [
        expected for path, expected in config.pins().items()
        if path.name != "probe_cf300_sector12_recapture_v4_virgin_k146.wls"
    ]
    for expected_hash in result_provenance_hashes:
        require(expected_hash in result,
                f"production result omits provenance hash {expected_hash}")
    require_tokens(marker, [
        '"Status" -> "CF300Sector12RecapturePreQuarantinePassedV4"',
        f'"WorkerKernelID" -> {config.expected_kernel}',
        f'"ResultSHA256" -> "{result_hash}"',
        f'"StripSHA256" -> "{STRIP_SHA256}"',
        f'"StripBytes" -> {STRIP_BYTES}',
        '"PoolWorkerMustRemainOccupiedQ" -> True',
    ], "pre-quarantine marker")

    log_path = paths["log"]
    log_raw = read_regular(log_path)
    log = wl_compact(log_raw.decode("utf-8"))
    require_tokens(log, [
        f"MISSION {config.production_mission}.wl kernel {config.expected_kernel} start",
        "CF300 S12 RECAPTURE V4 VIRGIN PREFLIGHT",
        '"PreflightGateQ" -> True',
        '"PathSealGateQ" -> True',
        '"PreflightDedicatedCleanupQ" -> True',
        "CF300 S12 RECAPTURE V4 PRE-QUARANTINE PASS",
        f'"ResultSHA256" -> "{result_hash}"',
        f'"QuarantineMarkerSHA256" -> "{marker_hash}"',
        f'"FreshStripSHA256" -> "{STRIP_SHA256}"',
        f'"FreshStripBytes" -> {STRIP_BYTES}',
        '"ZeroDriverMessagesQ" -> True',
        '"ExactGlobalRestoreQ" -> True',
        '"WorkerReusableQ" -> False',
    ], "production log")
    for forbidden in [
        "CF300 S12 RECAPTURE V4 FAIL:",
        "CF300 S12 RECAPTURE V4 POST-LOAD FAILURE QUARANTINE",
        "CF300 S12 RECAPTURE V4 ABORT QUARANTINE",
        "KPSUBMIT TARGET PARSE FAILURE",
        "KPSUBMIT TARGET IMPORT FAILURE",
        "MISSION end",
    ]:
        require(forbidden not in log, f"production log contains {forbidden!r}")
    no_wolfram_messages(log, "production log")
    heartbeat = last_complete_heartbeat(log)
    require_tokens(heartbeat, [
        '"IntegrityQ" -> True',
        '"HelperCeilingZeroQ" -> True',
        '"NestedKernelCount" -> 0',
        f'"ResultSHA256" -> "{result_hash}"',
        f'"QuarantineMarkerSHA256" -> "{marker_hash}"',
        f'"StateSHA256" -> "{STATE_SHA256}"',
        f'"SnapshotSHA256" -> "{STATE_SHA256}"',
        f'"FreshStripSHA256" -> "{STRIP_SHA256}"',
        f'"FreshStripBytes" -> {STRIP_BYTES}',
        '"GlobalNamespaceExactQ" -> True',
        '"EnvironmentExactQ" -> True',
        '"CommandLineExactQ" -> True',
        '"DirectoryExactQ" -> True',
        '"ReleaseSentinelPresentQ" -> False',
    ], "latest complete heartbeat")

    # Fail closed on a read race in any durable output.  The active log is
    # intentionally exempt because a new heartbeat may append concurrently.
    require(hash_regular(result_path) == result_hash, "result changed during verification")
    require(hash_regular(marker_path) == marker_hash, "marker changed during verification")
    require(hash_regular(inventory["strip"]) == STRIP_SHA256,
            "strip changed during verification")
    return {
        "GateQ": True,
        "Phase": "production",
        "Kernel": config.expected_kernel,
        "Probe": probe_report,
        "Sources": source_report,
        "ResultSHA256": result_hash,
        "PreQuarantineMarkerSHA256": marker_hash,
        "StripSHA256": STRIP_SHA256,
        "StripBytes": STRIP_BYTES,
        "DriverMessageTranscriptSHA256": EMPTY_SHA256,
        "TopLevelInventory": sorted(path.name for path in inventory.values()
                                    if path.parent == config.outdir),
        "HeartbeatIntegrityQ": True,
        "ProductionMissionStillRunningQ": True,
        "ReleaseSentinelWrittenQ": False,
        "LogSHA256AtRead": sha256_bytes(log_raw),
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("auto", "probe", "production"),
                        nargs="?", default="auto")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    config = Config()
    phase = args.phase
    if phase == "auto":
        phase = "production" if os.path.lexists(config.outdir) else "probe"
    try:
        if phase == "probe":
            source_report = verify_manifest(config)
            report = {
                "GateQ": True,
                "Phase": "probe",
                "Sources": source_report,
                "Probe": verify_probe(config, require_live_output_absent=True),
                "ReleaseSentinelWrittenQ": False,
            }
        else:
            report = verify_production(config)
    except (OSError, VerificationError, UnicodeError, ValueError) as exc:
        print(json.dumps({"GateQ": False, "Phase": phase,
                          "Failure": str(exc)}, sort_keys=True))
        return 1
    print(json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
