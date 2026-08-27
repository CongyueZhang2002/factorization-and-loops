#!/usr/bin/env python3
"""Static/artifact classifier for the CF300 row-minor witness failure."""

import hashlib
import json
import re
import subprocess
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops")
EXCHANGE = ROOT / "External/CodexExchange/triple_root_2026-08-22"
ADAPTER = (EXCHANGE / "flint_affine_rref_wl_xh/FlintAffineRREFAdapter.wl").read_text()
NATIVE = (EXCHANGE / "flint_affine_rref_xh/flint_affine_rref.c").read_text()
WIRE = (EXCHANGE / "flint_affine_rref_xh/verify_wire_row_minor.py").read_text()
QDIAG = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_s12_denominator_witness_qdiag_xh_v3.wl"
).read_text()
QWIRE_RESULT = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf300_s12_denominator_witness_qwire_xh_v6.wl"
)
QWIRE_STATUS = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/pool/failed/"
    "cf300_s12_denominator_witness_qwire_xh_v6.status"
)
REQUEST = Path("/tmp/m00003537554061/request.bin")
RESPONSE = Path("/tmp/m00003537554061/response.bin")
VERIFY_WIRE = (EXCHANGE / "flint_affine_rref_xh/verify_wire_row_minor.py")

EXPECTED_HASHES = {
    QWIRE_RESULT: "72275635deee18fe8f1c8768cf6eb2349afb1c07abf39d9e19735c57b61cc673",
    QWIRE_STATUS: "844677a5bab64968719d936e2e47f9b3cc7db2cecc7fdebe7833ab28f781ae6a",
    REQUEST: "b7175b7644434111419f3b1e2d21763b696b2646cb24d26c8c0ca32bf1cccf2a",
    RESPONSE: "4b9611f8cd34150d9c7ca54e8e84827be5264c5fda5deeddf8525e4ab36343de",
}


def require(condition, label):
    if not condition:
        raise AssertionError(label)
    print(f"PASS {label}")


def wl_rule(text, key, value):
    return re.search(rf'"{re.escape(key)}"\s*->\s*{value}\b', text) is not None


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    require(wl_rule(QDIAG, "RowMinorInverseWitness", "False"),
            "qdiag isolates row-minor inverse witness")
    for check in (
        "AffineResidual", "NullspaceResidual", "CanonicalFreeIdentity",
        "DerivedCanonicalNullspace", "NormalizationMinorInverseWitness",
    ):
        require(wl_rule(QDIAG, check, "True"), f"qdiag {check} passed")
    require("verify_two_sided_inverse(row_minor" in NATIVE,
            "native verifies row inverse before output")
    require("write_nmod_matrix(stream, row_minor_inverse)" in NATIVE,
            "native serializes row inverse with matrix writer")
    require("for (i = 0; i < nmod_mat_nrows(matrix); ++i)" in NATIVE and
            "for (j = 0; j < nmod_mat_ncols(matrix); ++j)" in NATIVE,
            "native matrix writer is row-major")
    require("ArrayReshape[rowInverseFlat, {rank, rank}]" in ADAPTER,
            "Wolfram parser reshapes row-major flat witness")
    require("row_inverse_flat.reshape(rank, rank)" in WIRE,
            "Python verifier reshapes row-major flat witness")
    inverse_function = ADAPTER.split("cffrInverseWitnessQ", 1)[1].split(
        "cffrCanonicalPivotOrderQ", 1
    )[0]
    require("identity = Normal[IdentityMatrix[size]]" in inverse_function,
            "active adapter materializes exact dense identity")
    require("Normal[Mod[matrix . inverse, prime]] === identity" in inverse_function,
            "active adapter normalizes left inverse product")
    require("Normal[Mod[inverse . matrix, prime]] === identity" in inverse_function,
            "active adapter normalizes right inverse product")
    require("=== IdentityMatrix[size]" not in inverse_function,
            "active inverse verifier has no representation-sensitive identity SameQ")
    require("nullspace[[All, free]] === IdentityMatrix[nullity]" in ADAPTER,
            "audit records analogous nullity identity for later hardening")
    for path, expected in EXPECTED_HASHES.items():
        require(path.is_file(), f"retained artifact exists: {path.name}")
        require(sha256(path) == expected, f"retained artifact hash: {path.name}")

    qwire_text = QWIRE_RESULT.read_text()
    require(wl_rule(qwire_text, "RowMinorInverseWitness", "False"),
            "qwire v6 reproduces isolated Wolfram rejection")
    require('"DiagnosticArtifactDirectory" -> "/tmp/m00003537554061"' in qwire_text,
            "qwire v6 binds retained wire directory")

    completed = subprocess.run(
        ["python3", str(VERIFY_WIRE), str(REQUEST), str(RESPONSE), "--trials", "8"],
        check=True, text=True, capture_output=True,
    )
    result = json.loads(completed.stdout)
    require(result["status"] == "OK", "independent wire verifier passes")
    require(result["rank"] == 1028 and result["nullity"] == 12,
            "wire verifier sees expected rank/nullity")
    require(result["left_failures"] == [] and result["right_failures"] == [],
            "wire inverse passes both directions")
    require(result["leading_sample_identity"] is True,
            "wire inverse passes exact leading sample")


if __name__ == "__main__":
    main()
