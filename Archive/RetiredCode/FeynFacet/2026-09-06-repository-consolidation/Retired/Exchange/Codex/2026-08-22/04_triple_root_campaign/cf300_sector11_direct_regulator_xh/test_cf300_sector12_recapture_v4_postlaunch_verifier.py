#!/usr/bin/env python3
"""Package-free static and synthetic tests for the read-only V4 verifier."""

from __future__ import annotations

import ast
import hashlib
import importlib.util
import os
import sys
import tempfile
from pathlib import Path


HERE = Path(__file__).resolve().parent
VERIFIER = HERE / "verify_cf300_sector12_recapture_v4_postlaunch.py"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_verifier():
    spec = importlib.util.spec_from_file_location("postlaunch_verifier", VERIFIER)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def expect_failure(module, callback, label: str) -> None:
    try:
        callback()
    except module.VerificationError:
        return
    raise AssertionError(f"adversarial mutation survived: {label}")


def write(path: Path, data: str | bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data.encode() if isinstance(data, str) else data)


def build_fixture(module, base: Path):
    pool = base / "pool"
    outdir = base / "out"
    bundle = base / "bundle"
    probe = "probe"
    production = "production"
    for directory in ["done", "failed", "running", "queue", "logs"]:
        (pool / directory).mkdir(parents=True)
    bundle.mkdir()

    manifest_lines: list[str] = []
    for index in range(10):
        name = f"manifest_{index}.txt"
        payload = f"manifest-{index}\n".encode()
        write(bundle / name, payload)
        manifest_lines.append(f"{sha(payload)}  {name}")
    manifest = bundle / "manifest.sha256"
    write(manifest, "\n".join(manifest_lines) + "\n")
    pin_path = bundle / "direct_pin.txt"
    pin_data = b"direct-pin\n"
    write(pin_path, pin_data)

    probe_source = bundle / "probe_cf300_sector12_recapture_v4_virgin_k146.wls"
    production_source = bundle / "run_cf300_sector12_recapture_from_v4_xh_v4.wls"
    write(probe_source, "probe-source\n")
    write(production_source, "production-source\n")

    probe_status = (
        f'<|"Mission" -> "{probe}.wl", "Status" -> "OK", '
        '"HadMessages" -> False, "Kernel" -> 146, "Result" -> 0|>'
    )
    probe_wrapper = (
        "KernelPoolMission`$TaskBrokerMaxHelpers = 0; " + str(probe_source)
    )
    probe_log = " ".join([
        f"MISSION {probe}.wl kernel 146 start",
        "CF300 S12 RECAPTURE V4 K146 VIRGIN PROBE",
        '"GateQ" -> True', '"ExpectedKernelID" -> 146',
        '"ActualKernelID" -> 146', '"NestedKernelCount" -> 0',
        '"HelperCeilingZeroQ" -> True', '"PathSealGateQ" -> True',
        '"GlobalNamespaceReadOnlyQ" -> True',
        '"PreflightDedicatedCleanupQ" -> True', '"OutputAbsentQ" -> True',
        '"ExistingRelevantPackageNameCount" -> 0',
        '"RelevantPackageListHazardCount" -> 0',
        '"DirtyDefinitionCount" -> 0', '"PackageShadowCount" -> 0',
        '"StateReadGateQ" -> True', '"ImportMessages" -> {}',
        "CF300 S12 RECAPTURE V4 PROBE CLEANUP", '"CleanupQ" -> True',
        "status OK",
    ])
    write(pool / "done" / f"{probe}.status", probe_status)
    write(pool / "done" / f"{probe}.wl", probe_wrapper)
    write(pool / "logs" / f"{probe}.log", probe_log)

    state_data = b"state\n"
    strip_data = b"strip\n"
    module.STATE_SHA256 = sha(state_data)
    module.STRIP_SHA256 = sha(strip_data)
    module.STRIP_BYTES = len(strip_data)
    outdir.mkdir()
    scratch = outdir / "sector_CF300_standard"
    scratch.mkdir()
    write(outdir / "CF300_driver_messages_v4.txt", b"")
    write(outdir / "CF300_package_load_attempted_v4.wl", "load\n")
    write(outdir / "CF300_sector12_recapture_launch_seal_v4.wl", "seal\n")
    write(outdir / "pre_sector12_snapshot_CF300_standard.wl", state_data)
    write(outdir / "sector_state_CF300_standard.wl", state_data)
    write(scratch / "CF300_12_11_input.wl", strip_data)

    result_fields = [
        '"Status" -> "CF300Sector12RecapturePreQuarantinePassedV4"',
        '"Family" -> "CF300"', '"SourceSector" -> 11',
        '"TargetSector" -> 12', '"LowerSector" -> 11',
        '"WorkerKernelID" -> 146', '"NestedKernelCount" -> 0',
        '"TaskBrokerMaxHelpers" -> 0',
        '"IntentionalDriverExit" -> {"EXIT", 75}',
        '"ZeroDriverMessagesQ" -> True', '"DriverMessageSignatures" -> {}',
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
        f'"FreshStripSHA256" -> "{module.STRIP_SHA256}"',
        f'"FreshStripBytes" -> {module.STRIP_BYTES}',
        '"NoStaleSector12CheckpointQ" -> True',
        '"ExactTopLevelInventoryBeforeResultQ" -> True',
        '"NoTemporaryFilesQ" -> True', '"V4CandidateImmutableQ" -> True',
        f'"StateSHA256" -> "{module.STATE_SHA256}"',
        f'"SnapshotSHA256" -> "{module.STATE_SHA256}"',
        '"WorkerReusableQ" -> False',
        '"CooperativeQuarantineRequiredQ" -> True',
        f'"SyntheticSourcePin" -> "{sha(pin_data)}"',
    ]
    result_path = outdir / "CF300_sector12_recapture_result_v4.wl"
    write(result_path, "<|" + ",".join(result_fields) + "|>\n")
    result_hash = sha(result_path.read_bytes())
    marker_fields = [
        '"Status" -> "CF300Sector12RecapturePreQuarantinePassedV4"',
        '"WorkerKernelID" -> 146', f'"ResultSHA256" -> "{result_hash}"',
        f'"StripSHA256" -> "{module.STRIP_SHA256}"',
        f'"StripBytes" -> {module.STRIP_BYTES}',
        '"PoolWorkerMustRemainOccupiedQ" -> True',
    ]
    marker_path = outdir / "CF300_prequarantine_pass_v4.wl"
    write(marker_path, "<|" + ",".join(marker_fields) + "|>\n")
    marker_hash = sha(marker_path.read_bytes())

    write(pool / "running" / f"{production}.kernel", "146")
    write(pool / "running" / f"{production}.wl",
          "KernelPoolMission`$TaskBrokerMaxHelpers = 0; " + str(production_source))
    heartbeat_fields = [
        '"IntegrityQ" -> True', '"HelperCeilingZeroQ" -> True',
        '"NestedKernelCount" -> 0', f'"ResultSHA256" -> "{result_hash}"',
        f'"QuarantineMarkerSHA256" -> "{marker_hash}"',
        f'"StateSHA256" -> "{module.STATE_SHA256}"',
        f'"SnapshotSHA256" -> "{module.STATE_SHA256}"',
        f'"FreshStripSHA256" -> "{module.STRIP_SHA256}"',
        f'"FreshStripBytes" -> {module.STRIP_BYTES}',
        '"GlobalNamespaceExactQ" -> True', '"EnvironmentExactQ" -> True',
        '"CommandLineExactQ" -> True', '"DirectoryExactQ" -> True',
        '"ReleaseSentinelPresentQ" -> False',
    ]
    production_log = " ".join([
        f"MISSION {production}.wl kernel 146 start",
        "CF300 S12 RECAPTURE V4 VIRGIN PREFLIGHT",
        '"PreflightGateQ" -> True', '"PathSealGateQ" -> True',
        '"PreflightDedicatedCleanupQ" -> True',
        "CF300 S12 RECAPTURE V4 PRE-QUARANTINE PASS",
        f'"ResultSHA256" -> "{result_hash}"',
        f'"QuarantineMarkerSHA256" -> "{marker_hash}"',
        f'"FreshStripSHA256" -> "{module.STRIP_SHA256}"',
        f'"FreshStripBytes" -> {module.STRIP_BYTES}',
        '"ZeroDriverMessagesQ" -> True', '"ExactGlobalRestoreQ" -> True',
        '"WorkerReusableQ" -> False',
        "CF300 S12 RECAPTURE V4 QUARANTINE HEARTBEAT",
        "<|" + ",".join(heartbeat_fields) + "|>",
    ])
    write(pool / "logs" / f"{production}.log", production_log)

    config = module.Config(
        pool=pool, outdir=outdir, bundle=bundle,
        probe_mission=probe, production_mission=production,
        expected_kernel=146, source_pins={pin_path: sha(pin_data)},
        manifest=manifest, manifest_sha256=sha(manifest.read_bytes()),
    )
    return config, {
        "probe_status": pool / "done" / f"{probe}.status",
        "production_log": pool / "logs" / f"{production}.log",
        "transcript": outdir / "CF300_driver_messages_v4.txt",
        "strip": scratch / "CF300_12_11_input.wl",
        "strip_data": strip_data,
        "result_hash": result_hash,
        "marker_hash": marker_hash,
    }


def main() -> None:
    source = VERIFIER.read_text()
    tree = ast.parse(source)
    checks = 0
    forbidden_calls = {
        "write_text", "write_bytes", "touch", "mkdir", "makedirs",
        "unlink", "remove", "rmdir", "rename", "replace", "symlink",
        "kill", "killpg", "system", "popen", "run", "Popen",
    }
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            if isinstance(node.func, ast.Attribute):
                assert node.func.attr not in forbidden_calls, node.func.attr
            elif isinstance(node.func, ast.Name):
                assert node.func.id not in forbidden_calls, node.func.id
            if isinstance(node.func, ast.Attribute) and node.func.attr == "open":
                assert len(node.args) >= 1
                assert isinstance(node.args[0], ast.Constant)
                assert node.args[0].value == "rb"
            checks += 1
    assert "release_sentinel" not in source.lower()
    assert "SetEnvironment" not in source
    assert "signal." not in source
    assert "subprocess" not in source
    checks += 4

    module = load_verifier()
    assert module.verify_manifest(module.Config())["ManifestRecordCount"] == 10
    assert module.wl_compact('"abc\\\n  def"  ->  True') == '"abcdef" -> True'
    expect_failure(module,
                   lambda: module.no_wolfram_messages("Set::wrsym", "mutant"),
                   "Wolfram message accepted")
    checks += 3

    with tempfile.TemporaryDirectory(prefix="cf300-v4-postlaunch-test-") as temp:
        config, paths = build_fixture(module, Path(temp))
        # Probe live-absence is tested before the synthetic production outdir
        # is hidden and then restored without deleting any real artifact.
        production_outdir = config.outdir
        hidden_outdir = production_outdir.with_name("out.hidden")
        production_outdir.rename(hidden_outdir)
        probe_config = module.Config(
            pool=config.pool, outdir=production_outdir, bundle=config.bundle,
            probe_mission=config.probe_mission,
            production_mission=config.production_mission,
            expected_kernel=config.expected_kernel,
            source_pins=config.source_pins, manifest=config.manifest,
            manifest_sha256=config.manifest_sha256,
        )
        assert module.verify_probe(probe_config, True)["GateQ"] is True
        hidden_outdir.rename(production_outdir)
        assert module.verify_production(config)["GateQ"] is True
        checks += 2

        original_status = paths["probe_status"].read_bytes()
        write(paths["probe_status"], original_status.replace(
            b'"HadMessages" -> False', b'"HadMessages" -> True'))
        expect_failure(module, lambda: module.verify_probe(config, False),
                       "probe HadMessages=True")
        write(paths["probe_status"], original_status)

        write(paths["transcript"], b"unexpected message\n")
        expect_failure(module, lambda: module.verify_production(config),
                       "nonempty driver transcript")
        write(paths["transcript"], b"")

        write(paths["strip"], b"mutant\n")
        expect_failure(module, lambda: module.verify_production(config),
                       "strip hash mutation")
        write(paths["strip"], paths["strip_data"])

        original_log = paths["production_log"].read_bytes()
        write(paths["production_log"], original_log.replace(
            b'"IntegrityQ" -> True', b'"IntegrityQ" -> False'))
        expect_failure(module, lambda: module.verify_production(config),
                       "heartbeat IntegrityQ=False")
        write(paths["production_log"], original_log)

        write(config.outdir / "CF300_quarantine_release_v4.txt", "forbidden\n")
        expect_failure(module, lambda: module.verify_production(config),
                       "release sentinel/inventory expansion")
        (config.outdir / "CF300_quarantine_release_v4.txt").unlink()

        link = Path(temp) / "linked"
        os.symlink(paths["strip"], link)
        expect_failure(module, lambda: module.read_regular(link),
                       "symlink read")
        checks += 6

    print(f"PASS {checks}/{checks}")
    print("verifier", hashlib.sha256(VERIFIER.read_bytes()).hexdigest())


if __name__ == "__main__":
    main()
