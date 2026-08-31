#!/usr/bin/env python3
"""Independent unseen-prime acceptance for the CF303 (25,2) path lift.

At fresh path/epsilon points this script compares the exact lift with the
saved deferred AST.  It also cross-checks all four radical-sign sheets from
the selected-sheet evaluator against an independent full-grade evaluator and
verifies the variation-of-constants differentiate-back identity.  No Wolfram
kernel and no package source are used.
"""

from __future__ import annotations

import argparse
import json
import struct
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any

import cf303_25_2_exact_path_campaign as campaign
import cf303_25_2_native_path_degree as degree


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
FULL_GRADE_BINARY = ROOT / "Diagnostics/Scripts/deferred_ast_native_eval_sanitize"
DEFAULT_PRIME = 2_305_843_009_213_692_199
POINT_COUNT = 16


def rational_mod(pair: list[int], prime: int) -> int:
    numerator, denominator = pair
    denominator %= prime
    if denominator == 0:
        raise ZeroDivisionError("exact coefficient denominator hit unseen prime")
    return numerator % prime * pow(denominator, prime - 2, prime) % prime


def poly_mod(coefficients: list[list[int]], value: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * value + rational_mod(coefficient, prime)) % prime
    return result


def exact_entry(
    coefficients: dict[str, Any], channel: str,
    z: int, epsilon: int, prime: int,
) -> int:
    numerator = 0
    for z_row in reversed(coefficients["numerators"][channel]):
        epsilon_value = 0
        for coefficient in reversed(z_row):
            epsilon_value = (
                epsilon_value * epsilon + rational_mod(coefficient, prime)
            ) % prime
        numerator = (numerator * z + epsilon_value) % prime
    denominator = (
        poly_mod(coefficients["qz"][channel], z, prime)
        * poly_mod(coefficients["qeps"][channel], epsilon, prime)
    ) % prime
    if denominator == 0:
        raise ZeroDivisionError("exact path denominator vanished")
    return numerator * pow(denominator, prime - 2, prime) % prime


def decode_full_grade(
    path: Path, expected_base_count: int,
) -> tuple[dict[str, int], dict[tuple[int, int, int], list[list[int]]]]:
    payload = path.read_bytes()
    if payload[:8] != b"DAGO1V1\0":
        raise RuntimeError(f"bad full-grade magic {payload[:8]!r}")
    fields = struct.unpack_from("<13Q", payload, 8)
    names = (
        "status", "prime", "rank", "base_count", "grade_count",
        "record_count", "term_count", "unique_expression_count",
        "dimension0", "dimension1", "dimension2",
        "parse_nanoseconds", "evaluation_nanoseconds",
    )
    header = dict(zip(names, fields, strict=True))
    if (
        header["status"] != 0 or header["rank"] != 2
        or header["base_count"] != expected_base_count
        or header["grade_count"] != 4
        or tuple(header[f"dimension{i}"] for i in range(3))
        != degree.EXPECTED_DIMENSIONS
    ):
        raise RuntimeError(f"full-grade header mismatch {header}")
    offset = 8 + 13 * 8
    records: dict[tuple[int, int, int], list[list[int]]] = {}
    for _ in range(header["record_count"]):
        target = struct.unpack_from("<3Q", payload, offset)
        offset += 24
        flat = struct.unpack_from(
            f"<{expected_base_count * 4}Q", payload, offset
        )
        offset += 8 * expected_base_count * 4
        records[target] = [
            list(flat[4 * index:4 * index + 4])
            for index in range(expected_base_count)
        ]
    if offset != len(payload):
        raise RuntimeError("full-grade output has trailing bytes")
    expected = {(mu, row, 1) for mu in (1, 2) for row in (1, 2)}
    if set(records) != expected:
        raise RuntimeError(f"full-grade targets {sorted(records)}")
    return header, records


def run_full_grade(
    base_images: list[dict[str, int]], prime: int,
) -> tuple[dict[str, int], dict[tuple[int, int, int], list[list[int]]], float, str]:
    with tempfile.TemporaryDirectory(prefix="cf303-25-2-unseen-grade-") as directory:
        request = Path(directory) / "request.txt"
        output = Path(directory) / "output.bin"
        degree.write_request(request, base_images, prime)
        started = time.perf_counter()
        process = subprocess.run(
            [
                "/usr/bin/time", "-f", "MAX_RSS_KB=%M",
                "taskset", "-c", "4", str(FULL_GRADE_BINARY),
                str(degree.SOURCE), str(request), str(output),
            ],
            text=True, capture_output=True, check=False,
        )
        seconds = time.perf_counter() - started
        if process.returncode:
            raise RuntimeError(
                f"full-grade evaluator exit {process.returncode}:\n{process.stderr}"
            )
        header, records = decode_full_grade(output, len(base_images))
    return header, records, seconds, process.stderr.strip()


def sign_images(base_images: list[dict[str, int]], prime: int):
    signs = ((1, 1), (-1, 1), (1, -1), (-1, -1))
    images: list[dict[str, int]] = []
    for base in base_images:
        for sign1, sign3 in signs:
            image = dict(base)
            image["root1"] = sign1 * base["root1"] % prime
            image["root3"] = sign3 * base["root3"] % prime
            images.append(image)
    return signs, images


def contracted_grade_coefficients(
    records: dict[tuple[int, int, int], list[list[int]]],
    images: list[dict[str, int]], prime: int,
) -> dict[int, list[list[int]]]:
    result: dict[int, list[list[int]]] = {}
    for row in (1, 2):
        result[row] = []
        for index, image in enumerate(images):
            result[row].append([
                (
                    records[(1, row, 1)][index][grade] * image["dx"]
                    + records[(2, row, 1)][index][grade] * image["dy"]
                ) % prime
                for grade in range(4)
            ])
    return result


def grade_physical(
    coefficients: list[int], image: dict[str, int],
    sign1: int, sign3: int, prime: int,
) -> int:
    root1 = sign1 * image["root1"] % prime
    root3 = sign3 * image["root3"] % prime
    return (
        coefficients[0] + coefficients[1] * root1
        + coefficients[2] * root3 + coefficients[3] * root1 * root3
    ) % prime


def matrix_vector(matrix: list[list[int]], vector: list[int], prime: int):
    return [
        sum(a * b for a, b in zip(row, vector, strict=True)) % prime
        for row in matrix
    ]


def matrix_multiply(left: list[list[int]], right: list[list[int]], prime: int):
    return [
        [
            sum(left[i][k] * right[k][j] for k in range(2)) % prime
            for j in range(2)
        ]
        for i in range(2)
    ]


def matrix_inverse(matrix: list[list[int]], prime: int):
    determinant = (
        matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]
    ) % prime
    inverse = pow(determinant, prime - 2, prime)
    return [
        [matrix[1][1] * inverse % prime, -matrix[0][1] * inverse % prime],
        [-matrix[1][0] * inverse % prime, matrix[0][0] * inverse % prime],
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=DEFAULT_PRIME)
    parser.add_argument("--coefficients", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    coefficients = json.loads(args.coefficients.read_text())
    if args.prime in {
        2_305_843_009_213_693_951,
        2_305_843_009_213_693_921,
        2_305_843_009_213_693_907,
        2_305_843_009_213_693_723,
        2_305_843_009_213_693_693,
        2_305_843_009_213_693_669,
        2_305_843_009_213_693_613,
        2_305_843_009_213_693_561,
        2_305_843_009_213_693_487,
    }:
        raise RuntimeError("unseen prime overlaps lift or CRT confirmation")

    pairs: list[tuple[int, int]] = []
    base_images: list[dict[str, int]] = []
    candidate = 0
    while len(base_images) < POINT_COUNT:
        z = 500 + 7 * candidate
        epsilon = 101 + 3 * candidate
        image = degree.chart_point(z, epsilon, args.prime)
        if image is not None:
            pairs.append((z, epsilon))
            base_images.append(image)
        candidate += 1

    started = time.perf_counter()
    signs, selected_images = sign_images(base_images, args.prime)
    selected_header, selected_records, selected_stderr, selected_seconds, selected_rss = (
        degree.run_native(selected_images, args.prime, "4-7", 4)
    )
    selected_contracted = degree.contract(
        selected_records, selected_images, args.prime
    )
    grade_header, grade_records, grade_seconds, grade_stderr = run_full_grade(
        base_images, args.prime
    )
    grade_contracted = contracted_grade_coefficients(
        grade_records, base_images, args.prime
    )

    sign_comparisons = 0
    exact_comparisons = 0
    selected_forcing: dict[tuple[int, int], list[int]] = {}
    for base_index, ((z, epsilon), image) in enumerate(
        zip(pairs, base_images, strict=True)
    ):
        forcing = []
        for row in (1, 2):
            for sign_index, (sign1, sign3) in enumerate(signs):
                expected = grade_physical(
                    grade_contracted[row][base_index], image,
                    sign1, sign3, args.prime,
                )
                observed = selected_contracted[(row, 1)][4 * base_index + sign_index]
                if observed != expected:
                    raise RuntimeError(
                        f"sign mismatch row={row} pair={z},{epsilon} "
                        f"sign={sign1},{sign3}"
                    )
                sign_comparisons += 1
            exact = exact_entry(
                coefficients, f"{row},1", z, epsilon, args.prime
            )
            declared = selected_contracted[(row, 1)][4 * base_index]
            if exact != declared:
                raise RuntimeError(
                    f"unseen exact mismatch row={row} pair={z},{epsilon}"
                )
            exact_comparisons += 1
            forcing.append(exact)
        selected_forcing[(z, epsilon)] = forcing

    differentiation_comparisons = 0
    for z, epsilon in pairs:
        phi = [
            [(1 + z) % args.prime, epsilon % args.prime],
            [0, (1 + epsilon) % args.prime],
        ]
        phi_prime = [[1, 0], [0, 0]]
        phi_inverse = matrix_inverse(phi, args.prime)
        hard_connection = matrix_multiply(phi_prime, phi_inverse, args.prime)
        lower_solution = (z * epsilon + 3) % args.prime
        bracket = [
            (z * z + epsilon + 5) % args.prime,
            (3 * z + 2 * epsilon + 7) % args.prime,
        ]
        forcing_vector = [
            value * lower_solution % args.prime
            for value in selected_forcing[(z, epsilon)]
        ]
        bracket_prime = matrix_vector(phi_inverse, forcing_vector, args.prime)
        transported = matrix_vector(phi, bracket, args.prime)
        left = [
            (a + b) % args.prime
            for a, b in zip(
                matrix_vector(phi_prime, bracket, args.prime),
                matrix_vector(phi, bracket_prime, args.prime), strict=True,
            )
        ]
        right = [
            (a + b) % args.prime
            for a, b in zip(
                matrix_vector(hard_connection, transported, args.prime),
                forcing_vector, strict=True,
            )
        ]
        if left != right:
            raise RuntimeError(f"differentiate-back mismatch at {z},{epsilon}")
        differentiation_comparisons += 2

    report = {
        "status": "CF303Block2ExactPathUnseenPrimeAcceptedV1",
        "acceptance": "ExactPathForcingAccepted",
        "prime": args.prime, "prime_bits": args.prime.bit_length(),
        "pairs": pairs, "point_count": len(pairs),
        "radical_signs": [list(sign) for sign in signs],
        "sign_comparisons": sign_comparisons,
        "exact_path_comparisons": exact_comparisons,
        "differentiate_back_comparisons": differentiation_comparisons,
        "selected_sheet_header": selected_header,
        "full_grade_header": grade_header,
        "selected_sheet_seconds": selected_seconds,
        "selected_sheet_max_rss_kb": selected_rss,
        "full_grade_seconds": grade_seconds,
        "selected_sheet_stderr": selected_stderr,
        "full_grade_stderr": grade_stderr,
        "source_sha256": degree.source_sha256(),
        "wall_seconds": time.perf_counter() - started,
        "claim_boundary": (
            "unseen-prime fixed-path forcing and differentiate-back acceptance; "
            "not global no-eps-form"
        ),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
