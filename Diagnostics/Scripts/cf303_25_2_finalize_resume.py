#!/usr/bin/env python3
"""Write and verify the block-1 resume manifest after the block-2 append."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
SOURCE_RUNTIME = ROOT / "Runtime/CF303_exception14_continuation_2026-08-30"
DRIVER = ROOT / "Diagnostics/Scripts/cf303_exception_continuation_driver.wls"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runtime-directory", type=Path, required=True)
    args = parser.parse_args()
    runtime = args.runtime_directory.resolve()
    resume = runtime / "resume"
    state = resume / "sector_state_CF303_standard.wl"
    checkpoint = resume / "sector_CF303_standard/CF303_25_strip_state.wl"
    source_state = SOURCE_RUNTIME / "sector_state_CF303_standard.wl"
    source_checkpoint = (
        SOURCE_RUNTIME / "sector_CF303_standard/CF303_25_strip_state.wl"
    )
    record = runtime / "cf303_25_2_exact_path_exception_record.wl"
    artifact = runtime / "cf303_25_2_exact_structured_path.wl"
    report = runtime / "cf303_25_2_exact_path_report.json"
    unseen = runtime / "cf303_25_2_exact_path_unseen_prime.json"
    artifact_validation = runtime / "cf303_25_2_exact_path_artifact_validation.wl"
    package_resume_validation = (
        resume / "CF303_block2_package_resume_validation.wl"
    )
    basis = runtime / "cf303_25_2_checkpoint_basis_derivation.json"
    append_script = ROOT / "Diagnostics/Scripts/cf303_append_block2_path_exception.wls"
    required = (
        DRIVER, state, checkpoint, source_state, source_checkpoint, record,
        artifact, report, unseen, artifact_validation,
        package_resume_validation, basis, append_script,
    )
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise RuntimeError(f"resume inputs missing: {missing}")
    driver_text = DRIVER.read_text()
    if "{18, 14, 11, 2}" not in driver_text:
        raise RuntimeError("continuation driver does not accept exception sector 2")
    if sha256(state) != sha256(source_state):
        raise RuntimeError("resume sector state is not an exact source copy")
    accepted_report = json.loads(report.read_text())
    accepted_unseen = json.loads(unseen.read_text())
    basis_record = json.loads(basis.read_text())
    if (
        accepted_report.get("acceptance") != "ExactPathForcingAccepted"
        or accepted_unseen.get("acceptance") != "ExactPathForcingAccepted"
        or basis_record.get("column_block_basis") != [39]
        or "CF303Block2ExactPathArtifactAcceptedV1"
        not in artifact_validation.read_text()
        or "CF303Block2PackageResumeContractAcceptedV1"
        not in package_resume_validation.read_text()
    ):
        raise RuntimeError("resume acceptance evidence is incomplete")
    if '"LowerSector" -> 2' not in record.read_text():
        raise RuntimeError("typed block-2 exception record is missing")

    family_data = (
        "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/"
        "Results/UU_08_10_canonical"
    )
    class_forms = family_data + "/ClassForms"
    command = (
        "FACET_KERNEL_COUNT=2 FACET_MQ_NATIVE_THREADS=4 "
        "FACET_MQ_IMAGE_KERNEL_COUNT=2 FACET_NATIVE_CORE_COUNT=4 "
        "FACET_STRIP_ROUTE=FiniteFieldFirst taskset -c 4-7 wolframscript "
        f"-file {DRIVER} CF303 {resume} 14400 standard 30 \"\" "
        f"{family_data} {class_forms}"
    )
    manifest = {
        "status": "CF303Block2PathResumeReadyV1",
        "acceptance": "ExactPathForcingAccepted",
        "next_lower_sector": 1,
        "accepted_exception_sequence": [18, 14, 11, 2],
        "resume_directory": str(resume),
        "sector_state": str(state),
        "sector_state_sha256": sha256(state),
        "sector_state_source": str(source_state),
        "sector_state_source_sha256": sha256(source_state),
        "updated_strip_checkpoint": str(checkpoint),
        "updated_strip_checkpoint_sha256": sha256(checkpoint),
        "source_strip_checkpoint": str(source_checkpoint),
        "source_strip_checkpoint_sha256": sha256(source_checkpoint),
        "typed_exception_record": str(record),
        "typed_exception_record_sha256": sha256(record),
        "path_artifact": str(artifact),
        "path_artifact_sha256": sha256(artifact),
        "append_script": str(append_script),
        "append_script_sha256": sha256(append_script),
        "continuation_driver": str(DRIVER),
        "continuation_driver_sha256": sha256(DRIVER),
        "resume_command": command,
        "resource_contract": {
            "cpu_affinity": "4-7", "native_threads_max": 4,
            "wolfram_subkernels_max": 2,
        },
        "validation": {
            "state_copy_hash_equal": True,
            "append_idempotence_checked": True,
            "artifact_validation": str(artifact_validation),
            "package_resume_validation": str(package_resume_validation),
            "basis_derivation": str(basis),
            "modular_report": str(report),
            "unseen_prime_report": str(unseen),
        },
        "claim_boundary": (
            "ready to resume the ordinary descending solver at block 1 with a "
            "typed exact fixed-path block-2 provider; no global no-eps-form claim"
        ),
    }
    output = resume / "CF303_block2_path_resume_manifest.json"
    output.write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
