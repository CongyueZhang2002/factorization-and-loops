#!/usr/bin/env python3
"""Deterministic native 672x624, rank-620 CFFR1 benchmark."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import subprocess
import tempfile
from pathlib import Path


MAGIC_IN = b"CFFR1V1\0"
MAGIC_OUT = b"CFFR1X1\0"
HEADER_IN = struct.Struct("<8s9Q")
HEADER_OUT = struct.Struct("<8s11Q")
P = 2147483647
M = 672
N = 624
R = 620
K = N - R
NONCE_HI = 0xCFF1300167200624
NONCE_LO = 0x0000062000000004


def next_lcg(state: int) -> tuple[int, int]:
    state = (6364136223846793005 * state + 1442695040888963407) & ((1 << 64) - 1)
    return state, state % P


def fixture() -> tuple[list[list[int]], list[int], list[int]]:
    state = 0x9E3779B97F4A7C15
    solution: list[int] = []
    for _ in range(N):
        state, value = next_lcg(state)
        solution.append(value)

    core: list[list[int]] = []
    rhs: list[int] = []
    for i in range(R):
        row = [0] * N
        row[i] = 1
        total = solution[i]
        for j in range(K):
            state, value = next_lcg(state)
            row[R + j] = value
            total = (total + value * solution[R + j]) % P
        core.append(row)
        rhs.append(total)

    # Each operation is invertible, so the first 620 rows retain exact rank
    # 620 while becoming dense and nontrivial. The fixed offsets make the
    # fixture deterministic and independent of the FLINT implementation.
    offsets = [1, 3, 7, 15, 31, 63, 127, 255, 511, 137]
    for sweep, offset in enumerate(offsets):
        for i in range(R):
            source = (i + offset) % R
            coefficient = ((i + 1) * (sweep + 17) + 29) % P or 1
            source_row = core[source]
            target_row = core[i]
            core[i] = [
                (target_row[j] + coefficient * source_row[j]) % P
                for j in range(N)
            ]
            rhs[i] = (rhs[i] + coefficient * rhs[source]) % P

    matrix = [row[:] for row in core]
    full_rhs = rhs[:]
    for extra in range(M - R):
        row = [0] * N
        value = 0
        for t in range(11):
            source = (extra * 97 + t * 53 + 11) % R
            coefficient = (extra * 41 + t * 73 + 19) % P or 1
            source_row = core[source]
            row = [(row[j] + coefficient * source_row[j]) % P for j in range(N)]
            value = (value + coefficient * rhs[source]) % P
        matrix.append(row)
        full_rhs.append(value)

    preference = list(range(N))
    return matrix, full_rhs, preference


def encode(matrix: list[list[int]], rhs: list[int], preference: list[int]) -> bytes:
    payload = [value for row in matrix for value in row] + rhs + preference
    return HEADER_IN.pack(
        MAGIC_IN, M, N, 1, P, N, 0, NONCE_HI, NONCE_LO, len(payload)
    ) + struct.pack(f"<{len(payload)}Q", *payload)


def parse_rss(stderr: str) -> int:
    match = re.search(r"Maximum resident set size \(kbytes\):\s*(\d+)", stderr)
    if not match:
        raise AssertionError(f"missing RSS record: {stderr}")
    return int(match.group(1))


def validate_response(data: bytes) -> tuple[int, int, int]:
    fields = HEADER_OUT.unpack_from(data)
    (magic, rows, columns, rhs_columns, modulus, matrix_rank, nullity,
     preference_count, flags, nonce_hi, nonce_lo, payload_words) = fields
    assert magic == MAGIC_OUT
    assert (rows, columns, rhs_columns, modulus) == (M, N, 1, P)
    assert (matrix_rank, nullity) == (R, K)
    assert (preference_count, flags) == (N, 0)
    assert (nonce_hi, nonce_lo) == (NONCE_HI, NONCE_LO)
    assert payload_words == 3 * N + K * N + R * R + K * K
    assert len(data) == HEADER_OUT.size + 8 * payload_words
    return matrix_rank, nullity, payload_words


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", type=Path)
    parser.add_argument("--result", type=Path)
    args = parser.parse_args()
    binary = args.binary.resolve()
    assert binary.is_file()
    matrix, rhs, preference = fixture()
    nonzero_entries = sum(value != 0 for row in matrix for value in row)
    request = encode(matrix, rhs, preference)
    records: list[dict[str, object]] = []
    response_hashes: list[str] = []

    with tempfile.TemporaryDirectory(prefix="cffr1-cf300-bench-") as temp_name:
        directory = Path(temp_name)
        request_path = directory / "cf300_shape.request.bin"
        request_path.write_bytes(request)
        for threads in (1, 2, 4):
            response_path = directory / f"cf300_shape.t{threads}.response.bin"
            completed = subprocess.run(
                ["/usr/bin/time", "-v", str(binary), str(request_path),
                 str(response_path), str(threads)],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                check=False,
            )
            assert completed.returncode == 0, completed.stderr
            backend_record = json.loads(completed.stdout)
            response = response_path.read_bytes()
            matrix_rank, nullity, payload_words = validate_response(response)
            response_hash = hashlib.sha256(response).hexdigest()
            response_hashes.append(response_hash)
            records.append({
                "threads": threads,
                "rank": matrix_rank,
                "nullity": nullity,
                "payload_words": payload_words,
                "rss_kbytes": parse_rss(completed.stderr),
                "rref_seconds": backend_record["rref_seconds"],
                "witness_construction_seconds": backend_record[
                    "witness_construction_seconds"
                ],
                "verification_seconds": backend_record["verification_seconds"],
                "output_seconds": backend_record["output_seconds"],
                "total_seconds": backend_record["total_seconds"],
                "response_sha256": response_hash,
            })

    assert len(set(response_hashes)) == 1
    result = {
        "status": "PASS",
        "fixture": {"rows": M, "columns": N, "rank": R, "nullity": K,
                    "modulus": P, "nonzero_entries": nonzero_entries,
                    "density": nonzero_entries / (M * N)},
        "request_bytes": len(request),
        "request_sha256": hashlib.sha256(request).hexdigest(),
        "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
        "thread_outputs_identical": True,
        "records": records,
    }
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.result is not None:
        args.result.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
