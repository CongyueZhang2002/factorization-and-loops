#!/usr/bin/env python3
"""Independent O(k n^2) verifier for a retained CFFR1 request/response pair."""

from __future__ import annotations

import argparse
import json
import pathlib
import struct

import numpy as np


def read_words(path: pathlib.Path, magic: bytes, header_words: int):
    data = path.read_bytes()
    if data[:8] != magic:
        raise ValueError(f"bad magic in {path}")
    header = struct.unpack_from(f"<{header_words}Q", data, 8)
    offset = 8 + 8 * header_words
    payload = np.frombuffer(data, dtype="<u8", offset=offset).astype(np.int64)
    return header, payload


def take(payload: np.ndarray, offset: int, count: int):
    return payload[offset : offset + count], offset + count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("request", type=pathlib.Path)
    parser.add_argument("response", type=pathlib.Path)
    parser.add_argument("--trials", type=int, default=8)
    args = parser.parse_args()

    req, req_payload = read_words(args.request, b"CFFR1V1\0", 9)
    rows, columns, rhs_columns, prime, preference_count, flags, nonce_hi, nonce_lo, req_words = req
    if rhs_columns != 1 or preference_count != columns or flags != 0:
        raise ValueError("unsupported request header")
    expected_request_words = rows * columns + rows + columns
    if req_words != expected_request_words or req_payload.size != req_words:
        raise ValueError("request payload length mismatch")
    matrix = req_payload[: rows * columns].reshape(rows, columns)

    res, res_payload = read_words(args.response, b"CFFR1X1\0", 11)
    (res_rows, res_columns, res_rhs, res_prime, rank, nullity,
     res_preference, res_flags, res_nonce_hi, res_nonce_lo, res_words) = res
    if (res_rows, res_columns, res_rhs, res_prime, res_preference, res_flags,
        res_nonce_hi, res_nonce_lo) != (rows, columns, 1, prime,
        columns, 0, nonce_hi, nonce_lo):
        raise ValueError("response header is not request-bound")
    if rank + nullity != columns or res_payload.size != res_words:
        raise ValueError("response rank/payload mismatch")

    offset = 0
    pivots, offset = take(res_payload, offset, rank)
    _, offset = take(res_payload, offset, nullity)
    independent_rows, offset = take(res_payload, offset, rank)
    _, offset = take(res_payload, offset, nullity)
    _, offset = take(res_payload, offset, columns)
    _, offset = take(res_payload, offset, nullity * columns)
    row_inverse_flat, offset = take(res_payload, offset, rank * rank)
    _, offset = take(res_payload, offset, nullity * nullity)
    if offset != res_payload.size:
        raise ValueError("response payload partition mismatch")

    row_minor = matrix[np.ix_(independent_rows, pivots)]
    row_inverse = row_inverse_flat.reshape(rank, rank)
    rng = np.random.default_rng(20260823)
    left_failures = []
    right_failures = []
    for trial in range(args.trials):
        vector = rng.integers(0, prime, size=rank, dtype=np.int64)
        left = row_minor @ (row_inverse @ vector % prime) % prime
        right = row_inverse @ (row_minor @ vector % prime) % prime
        if not np.array_equal(left, vector):
            left_failures.append(trial)
        if not np.array_equal(right, vector):
            right_failures.append(trial)

    sample = min(rank, 8)
    sample_product = row_minor[:sample, :] @ row_inverse[:, :sample] % prime
    sample_expected = np.eye(sample, dtype=np.int64)
    report = {
        "status": "OK" if not left_failures and not right_failures else "FAILED",
        "rows": int(rows),
        "columns": int(columns),
        "prime": int(prime),
        "rank": int(rank),
        "nullity": int(nullity),
        "trials": args.trials,
        "left_failures": left_failures,
        "right_failures": right_failures,
        "leading_sample_identity": bool(np.array_equal(sample_product, sample_expected)),
        "independent_rows_sorted": bool(np.all(independent_rows[:-1] < independent_rows[1:])),
        "pivots_sorted": bool(np.all(pivots[:-1] < pivots[1:])),
    }
    print(json.dumps(report, sort_keys=True))
    return 0 if report["status"] == "OK" else 1


if __name__ == "__main__":
    raise SystemExit(main())
