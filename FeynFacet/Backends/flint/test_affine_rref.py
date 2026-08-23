#!/usr/bin/env python3
"""Deterministic native/adversarial tests for the isolated CFFR1 helper."""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import struct
import subprocess
import tempfile
import time
from pathlib import Path


INPUT_MAGIC = b"CFFR1V1\0"
OUTPUT_MAGIC = b"CFFR1X1\0"
INPUT_HEADER = struct.Struct("<8s9Q")
OUTPUT_HEADER = struct.Struct("<8s11Q")
NONCE_HI = 0x0123456789ABCDEF
NONCE_LO = 0xFEDCBA9876543210


def matmul(a: list[list[int]], b: list[list[int]], p: int) -> list[list[int]]:
    if not a:
        return []
    inner = len(a[0])
    columns = len(b[0]) if b else 0
    assert len(b) == inner
    return [
        [sum(a[i][t] * b[t][j] for t in range(inner)) % p
         for j in range(columns)]
        for i in range(len(a))
    ]


def transpose(a: list[list[int]]) -> list[list[int]]:
    if not a:
        return []
    return [list(column) for column in zip(*a)]


def identity(n: int) -> list[list[int]]:
    return [[int(i == j) for j in range(n)] for i in range(n)]


def rref(matrix: list[list[int]], p: int) -> tuple[list[list[int]], list[int]]:
    result = [row[:] for row in matrix]
    if not result:
        return result, []
    rows, columns = len(result), len(result[0])
    pivots: list[int] = []
    row = 0
    for column in range(columns):
        pivot = next((i for i in range(row, rows) if result[i][column] % p), None)
        if pivot is None:
            continue
        result[row], result[pivot] = result[pivot], result[row]
        inverse = pow(result[row][column] % p, -1, p)
        result[row] = [(x * inverse) % p for x in result[row]]
        for i in range(rows):
            if i == row:
                continue
            factor = result[i][column] % p
            if factor:
                result[i] = [
                    (result[i][j] - factor * result[row][j]) % p
                    for j in range(columns)
                ]
        pivots.append(column)
        row += 1
        if row == rows:
            break
    return result, pivots


def rank(matrix: list[list[int]], p: int) -> int:
    return len(rref(matrix, p)[1])


def flatten(matrix: list[list[int]]) -> list[int]:
    return [value for row in matrix for value in row]


def encode_request(a: list[list[int]], b: list[int], p: int,
                   preference: list[int], *, flags: int = 0,
                   rhs_columns: int = 1, nonce_hi: int = NONCE_HI,
                   nonce_lo: int = NONCE_LO) -> bytes:
    rows = len(a)
    columns = len(a[0]) if rows else len(preference)
    assert all(len(row) == columns for row in a)
    assert len(b) == rows
    payload = flatten(a) + b + preference
    return INPUT_HEADER.pack(
        INPUT_MAGIC, rows, columns, rhs_columns, p, len(preference), flags,
        nonce_hi, nonce_lo, len(payload)
    ) + struct.pack(f"<{len(payload)}Q", *payload)


def take(words: list[int], offset: int, count: int) -> tuple[list[int], int]:
    result = words[offset:offset + count]
    assert len(result) == count
    return result, offset + count


def reshape(words: list[int], rows: int, columns: int) -> list[list[int]]:
    return [words[i * columns:(i + 1) * columns] for i in range(rows)]


def decode_response(data: bytes) -> dict[str, object]:
    assert len(data) >= OUTPUT_HEADER.size
    fields = OUTPUT_HEADER.unpack_from(data)
    (magic, rows, columns, rhs_columns, modulus, matrix_rank, nullity,
     preference_count, flags, nonce_hi, nonce_lo, payload_words) = fields
    assert magic == OUTPUT_MAGIC
    assert len(data) == OUTPUT_HEADER.size + 8 * payload_words
    words = list(struct.unpack_from(f"<{payload_words}Q", data, OUTPUT_HEADER.size))
    offset = 0
    pivots, offset = take(words, offset, matrix_rank)
    free, offset = take(words, offset, nullity)
    independent_rows, offset = take(words, offset, matrix_rank)
    normalization_columns, offset = take(words, offset, nullity)
    particular, offset = take(words, offset, columns)
    nullspace_flat, offset = take(words, offset, nullity * columns)
    row_inverse_flat, offset = take(words, offset, matrix_rank * matrix_rank)
    normalization_inverse_flat, offset = take(words, offset, nullity * nullity)
    assert offset == len(words)
    return {
        "rows": rows,
        "columns": columns,
        "rhs_columns": rhs_columns,
        "modulus": modulus,
        "rank": matrix_rank,
        "nullity": nullity,
        "preference_count": preference_count,
        "flags": flags,
        "nonce_hi": nonce_hi,
        "nonce_lo": nonce_lo,
        "payload_words": payload_words,
        "pivots": pivots,
        "free": free,
        "independent_rows": independent_rows,
        "normalization_columns": normalization_columns,
        "particular": particular,
        "nullspace": reshape(nullspace_flat, nullity, columns),
        "row_inverse": reshape(row_inverse_flat, matrix_rank, matrix_rank),
        "normalization_inverse": reshape(
            normalization_inverse_flat, nullity, nullity
        ),
    }


def run_binary(binary: Path, request: bytes, directory: Path, name: str,
               *, threads: str = "1", sentinel: bytes | None = None
               ) -> tuple[subprocess.CompletedProcess[bytes], Path]:
    request_path = directory / f"{name}.request.bin"
    output_path = directory / f"{name}.response.bin"
    request_path.write_bytes(request)
    if sentinel is not None:
        output_path.write_bytes(sentinel)
    completed = subprocess.run(
        [str(binary), str(request_path), str(output_path), threads],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    return completed, output_path


def expected_affine(a: list[list[int]], b: list[int], p: int
                    ) -> tuple[list[int], list[int], list[int], list[list[int]]]:
    augmented, pivots_augmented = rref(
        [row + [rhs] for row, rhs in zip(a, b)], p
    )
    columns = len(a[0])
    assert columns not in pivots_augmented
    pivots = pivots_augmented[:]
    free = [j for j in range(columns) if j not in set(pivots)]
    particular = [0] * columns
    for i, pivot in enumerate(pivots):
        particular[pivot] = augmented[i][columns]
    nullspace = []
    for free_column in free:
        vector = [0] * columns
        vector[free_column] = 1
        for i, pivot in enumerate(pivots):
            vector[pivot] = (-augmented[i][free_column]) % p
        nullspace.append(vector)
    return pivots, free, particular, nullspace


def greedy_normalization_set(nullspace: list[list[int]], preference: list[int],
                             p: int) -> list[int]:
    nullity = len(nullspace)
    if nullity == 0:
        return []
    selected: list[int] = []
    current_rank = 0
    for column in preference:
        candidate = selected + [column]
        candidate_matrix = [[row[j] for j in candidate] for row in nullspace]
        candidate_rank = rank(candidate_matrix, p)
        if candidate_rank > current_rank:
            selected.append(column)
            current_rank = candidate_rank
            if current_rank == nullity:
                break
    assert len(selected) == nullity
    return sorted(selected)


def check_success(binary: Path, directory: Path, name: str,
                  a: list[list[int]], b: list[int], p: int,
                  preference: list[int]) -> float:
    request = encode_request(a, b, p, preference)
    start = time.perf_counter()
    completed, output_path = run_binary(binary, request, directory, name)
    elapsed = time.perf_counter() - start
    assert completed.returncode == 0, completed.stderr.decode()
    summary = json.loads(completed.stdout)
    assert summary["verified"] is True
    assert summary["backend"] == "FLINT-_nmod_mat_rref-3.0.1"
    result = decode_response(output_path.read_bytes())
    rows, columns = len(a), len(a[0])
    pivots, free, particular, nullspace = expected_affine(a, b, p)
    matrix_rank, nullity = len(pivots), len(free)

    assert result["rows"] == rows and result["columns"] == columns
    assert result["rhs_columns"] == 1 and result["modulus"] == p
    assert result["rank"] == matrix_rank and result["nullity"] == nullity
    assert result["preference_count"] == columns and result["flags"] == 0
    assert result["nonce_hi"] == NONCE_HI and result["nonce_lo"] == NONCE_LO
    assert result["payload_words"] == (
        3 * columns + nullity * columns + matrix_rank * matrix_rank
        + nullity * nullity
    )
    assert result["pivots"] == pivots
    assert result["free"] == free
    assert result["particular"] == particular
    assert result["nullspace"] == nullspace
    assert result["independent_rows"] == sorted(result["independent_rows"])
    assert len(set(result["independent_rows"])) == matrix_rank
    assert all(0 <= i < rows for i in result["independent_rows"])
    assert result["normalization_columns"] == sorted(
        result["normalization_columns"]
    )
    assert result["normalization_columns"] == greedy_normalization_set(
        nullspace, preference, p
    )

    particular_column = [[x] for x in particular]
    assert matmul(a, particular_column, p) == [[x] for x in b]
    if nullity:
        assert matmul(a, transpose(nullspace), p) == [
            [0] * nullity for _ in range(rows)
        ]
    assert [[row[j] for j in free] for row in nullspace] == identity(nullity)

    independent_rows = result["independent_rows"]
    row_minor = [[a[i][j] for j in pivots] for i in independent_rows]
    row_inverse = result["row_inverse"]
    if matrix_rank:
        assert matmul(row_minor, row_inverse, p) == identity(matrix_rank)
        assert matmul(row_inverse, row_minor, p) == identity(matrix_rank)
    normalization_columns = result["normalization_columns"]
    normalization_minor = [
        [row[j] for j in normalization_columns] for row in nullspace
    ]
    normalization_inverse = result["normalization_inverse"]
    if nullity:
        assert matmul(normalization_minor, normalization_inverse, p) == identity(nullity)
        assert matmul(normalization_inverse, normalization_minor, p) == identity(nullity)
    return elapsed


def mutate_header(request: bytes, word_index: int, value: int) -> bytes:
    result = bytearray(request)
    struct.pack_into("<Q", result, 8 + 8 * word_index, value)
    return bytes(result)


def expect_failure(binary: Path, directory: Path, name: str, request: bytes,
                   expected_codes: set[int]) -> None:
    sentinel = b"preexisting-output-must-survive"
    completed, output_path = run_binary(
        binary, request, directory, name, sentinel=sentinel
    )
    assert completed.returncode in expected_codes, (
        completed.returncode, completed.stdout, completed.stderr
    )
    assert output_path.read_bytes() == sentinel
    assert not list(directory.glob(f"{name}.response.bin.tmp.*"))


def structured_case(rows: int, columns: int, matrix_rank: int, p: int
                    ) -> tuple[list[list[int]], list[int], list[int]]:
    nullity = columns - matrix_rank
    core: list[list[int]] = []
    for i in range(matrix_rank):
        row = [0] * columns
        row[i] = 1
        if i < nullity:
            row[matrix_rank + i] = (i * 17 + 3) % p or 1
        if nullity:
            row[matrix_rank + ((7 * i + 5) % nullity)] = (
                row[matrix_rank + ((7 * i + 5) % nullity)] + i * 29 + 11
            ) % p
        core.append(row)
    a = [row[:] for row in core]
    for extra in range(rows - matrix_rank):
        source = (37 * extra + 9) % matrix_rank
        scale = (19 * extra + 7) % p or 1
        a.append([(scale * x) % p for x in core[source]])
    solution = [(23 * j + 41) % p for j in range(columns)]
    b = [sum(row[j] * solution[j] for j in range(columns)) % p for row in a]
    preference = list(range(min(nullity, matrix_rank)))
    preference += [j for j in range(columns) if j not in set(preference)]
    return a, b, preference


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", type=Path)
    parser.add_argument("--quick", action="store_true")
    parser.add_argument("--result", type=Path)
    args = parser.parse_args()
    binary = args.binary.resolve()
    assert binary.is_file()
    checks = 0
    timings: dict[str, float] = {}

    with tempfile.TemporaryDirectory(prefix="cffr1-native-") as temp_name:
        directory = Path(temp_name)

        fixed_cases = [
            ("rectangular_rank3", [[1, 0, 2, 1], [0, 1, 3, 4],
             [1, 1, 5, 5], [2, 3, 13, 14], [4, 2, 14, 12]],
             [4, 9, 13, 35, 34], 101, [0, 3, 1, 2]),
            ("wide_rank2", [[1, 2, 3, 4, 5, 6], [0, 1, 4, 2, 1, 3],
             [1, 3, 7, 6, 6, 9]], [7, 11, 18], 1009,
             [2, 0, 4, 1, 5, 3]),
            ("full_column_rank", [[1, 0, 2], [0, 1, 3], [1, 1, 5],
             [2, 3, 13], [4, 2, 14]], [5, 7, 12, 31, 34], 101,
             [2, 1, 0]),
            ("rank_zero", [[0, 0, 0], [0, 0, 0]], [0, 0], 2,
             [2, 0, 1]),
            ("mersenne_61bit", [[1, 2305843009213693949, 7],
             [3, 5, 2305843009213693948]], [19, 23],
             2305843009213693951, [2, 0, 1]),
            ("largest_64bit_prime", [[18446744073709551556, 2, 9],
             [5, 18446744073709551554, 1]], [11, 17],
             18446744073709551557, [1, 2, 0]),
        ]
        for name, a, b, p, preference in fixed_cases:
            timings[name] = check_success(binary, directory, name, a, b, p, preference)
            checks += 1

        rng = random.Random(0xCFF1A11E)
        primes = [2, 3, 101, 1009, 65537]
        random_count = 12 if args.quick else 48
        for case_index in range(random_count):
            p = primes[case_index % len(primes)]
            rows = rng.randint(1, 9)
            columns = rng.randint(1, 10)
            a = [[rng.randrange(p) for _ in range(columns)] for _ in range(rows)]
            solution = [rng.randrange(p) for _ in range(columns)]
            b = [sum(row[j] * solution[j] for j in range(columns)) % p for row in a]
            preference = list(range(columns))
            rng.shuffle(preference)
            check_success(binary, directory, f"random_{case_index:03d}",
                          a, b, p, preference)
            checks += 1

        base = encode_request([[1, 2], [3, 4]], [5, 6], 101, [1, 0])
        malformed: list[tuple[str, bytes, set[int]]] = []
        malformed.append(("bad_magic", b"BADMAGIC" + base[8:], {4}))
        malformed.append(("truncated", base[:-1], {4}))
        malformed.append(("trailing", base + b"x", {4}))
        malformed.append(("rhs_columns", mutate_header(base, 2, 2), {4}))
        malformed.append(("composite", mutate_header(base, 3, 91), {4}))
        malformed.append(("preference_count", mutate_header(base, 4, 1), {4}))
        malformed.append(("flags", mutate_header(base, 5, 1), {4}))
        zero_nonce = mutate_header(mutate_header(base, 6, 0), 7, 0)
        malformed.append(("zero_nonce", zero_nonce, {4}))
        malformed.append(("payload_words", mutate_header(base, 8, 2**64 - 1), {4}))
        malformed.append(("zero_rows", mutate_header(base, 0, 0), {4}))
        malformed.append(("huge_columns", mutate_header(base, 1, 2**63), {4}))
        noncanonical = bytearray(base)
        struct.pack_into("<Q", noncanonical, INPUT_HEADER.size, 101)
        malformed.append(("noncanonical_field", bytes(noncanonical), {4}))
        duplicate_preference = bytearray(base)
        preference_offset = INPUT_HEADER.size + 8 * (4 + 2)
        struct.pack_into("<2Q", duplicate_preference, preference_offset, 0, 0)
        malformed.append(("duplicate_preference", bytes(duplicate_preference), {4}))
        out_of_range_preference = bytearray(base)
        struct.pack_into("<Q", out_of_range_preference, preference_offset, 2)
        malformed.append(("out_of_range_preference", bytes(out_of_range_preference), {4}))
        inconsistent = encode_request([[1, 0], [0, 0]], [0, 1], 101, [0, 1])
        malformed.append(("inconsistent", inconsistent, {5}))
        for name, request, codes in malformed:
            expect_failure(binary, directory, name, request, codes)
            checks += 1

        request_path = directory / "same_path.bin"
        request_path.write_bytes(base)
        same_path = subprocess.run(
            [str(binary), str(request_path), str(request_path), "1"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )
        assert same_path.returncode == 2 and request_path.read_bytes() == base
        checks += 1
        hardlink_path = directory / "same_inode.bin"
        hardlink_path.hardlink_to(request_path)
        same_inode = subprocess.run(
            [str(binary), str(request_path), str(hardlink_path), "1"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )
        assert same_inode.returncode == 2 and request_path.read_bytes() == base
        checks += 1
        invalid_threads = subprocess.run(
            [str(binary), str(request_path), str(directory / "unused.bin"), "1x"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )
        assert invalid_threads.returncode == 2
        checks += 1

        if not args.quick:
            a, b, preference = structured_case(672, 625, 480, 2147483647)
            timings["structured_672x625_rank480"] = check_success(
                binary, directory, "structured_672x625_rank480",
                a, b, 2147483647, preference
            )
            checks += 1

    source_hash = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    result = {
        "status": "PASS",
        "checks": checks,
        "binary": str(binary),
        "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
        "test_sha256": source_hash,
        "timings_seconds": timings,
    }
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.result is not None:
        args.result.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
