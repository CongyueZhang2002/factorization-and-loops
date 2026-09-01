#!/usr/bin/env python3
"""One-prime direct-u Hermite pilot for a CF303 exceptional forcing.

The saved deferred block equation is evaluated as a truncated path jet by the
existing native provider.  For fixed (p, epsilon) this recovers the exact
rational function of tau=u-1/2 with Berlekamp--Massey, then performs rational
Hermite reduction entirely over F_q[tau].  No multivariate symbolic numerator
is constructed.  The first fixture is (25,2), whose remaining direct-u root
content is rational; the same driver shape extends to paired residual sheets.
"""

from __future__ import annotations

import argparse
import math
import importlib.util
import json
import struct
import subprocess
import sys
import tempfile
import time
from fractions import Fraction
from pathlib import Path
from typing import Sequence


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
REPOSITORY = Path("/home/maxzhang/factorization-and-loops")
NATIVE_MODULE = ROOT / "Diagnostics/Scripts/native_path_residue_reconstruct.py"
BLOCK2_INPUT = ROOT / (
    "Runtime/CF303_exception14_continuation_2026-08-30/"
    "sector_CF303_standard/CF303_25_2_input.wl"
)
BINARY = REPOSITORY / "FeynFacet/Backends/flint/bin/flint_deferred_path_jet"
BLOCK2_ROOTS = (
    "1 + 2*x + x^2 - 2*y + 2*x*y + y^2",
    "1 - 4*x*y",
)


def load_native():
    spec = importlib.util.spec_from_file_location("native_path", NATIVE_MODULE)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load native path module")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def write_request(path: Path, data, epsilon: int) -> None:
    lines = [
        "DeferredPathJetRequestV1",
        f"prime {data.prime}",
        "variables x y eps",
        f"order {data.order}",
        "rank 2",
        *(f"root {root}" for root in BLOCK2_ROOTS),
        "epsilon_count 1",
        f"epsilon {epsilon % data.prime}",
        "x_jet " + " ".join(map(str, data.x)),
        "y_jet " + " ".join(map(str, data.y)),
    ]
    # BLOCK2_ROOTS are Delta2 and Delta3 in the three-root path provider.
    for index in (1, 2):
        lines.append("delta_jet " + " ".join(map(str, data.deltas[index])))
        lines.append("root_jet " + " ".join(map(str, data.roots[index])))
    path.write_text("\n".join(lines) + "\n")


def direct_u_path_data(native, prime: int, order: int, p_value: Fraction,
                       center: Fraction, residual_root: bool = False):
    """Return the direct-u jet at an arbitrary center with du/dtau=1."""
    size = order + 1
    constant = lambda value: native.jet_constant(
        native.fraction_mod(value, prime), size, prime
    )
    one = constant(Fraction(1))
    two = constant(Fraction(2))
    four = constant(Fraction(4))
    p_jet = constant(p_value)
    u_jet = [native.fraction_mod(center, prime), 1] + [0] * (size - 2)
    four_product = native.jet_mul(
        four,
        native.jet_mul(p_jet, native.jet_sub(one, p_jet, prime), prime),
        prime,
    )
    a = native.jet_mul(
        native.jet_sub(four_product, native.jet_mul(two, u_jet, prime), prime),
        native.jet_inv(
            native.jet_add(native.jet_mul(u_jet, u_jet, prime), four_product, prime),
            prime,
        ),
        prime,
    )
    x = native.jet_neg(native.jet_mul(a, p_jet, prime), prime)
    y = native.jet_mul(
        native.jet_sub(one, a, prime),
        native.jet_sub(one, p_jet, prime),
        prime,
    )
    x2 = native.jet_mul(x, x, prime)
    y2 = native.jet_mul(y, y, prime)
    xy = native.jet_mul(x, y, prime)
    two_x = [(2 * value) % prime for value in x]
    two_y = [(2 * value) % prime for value in y]
    two_xy = [(2 * value) % prime for value in xy]
    four_xy = [(4 * value) % prime for value in xy]
    delta1 = native.jet_add(
        native.jet_add(native.jet_add(native.jet_sub(one, two_x, prime), x2, prime),
                       two_y, prime),
        native.jet_add(two_xy, y2, prime), prime,
    )
    delta2 = native.jet_add(
        native.jet_add(native.jet_add(native.jet_add(one, two_x, prime), x2, prime),
                       native.jet_neg(two_y, prime), prime),
        native.jet_add(two_xy, y2, prime), prime,
    )
    delta3 = native.jet_sub(one, four_xy, prime)
    # Block 2 does not declare Delta1.  Algebraic fixtures request its actual
    # Taylor sheet and run the provider once for each sign.
    root1 = (
        native.jet_sqrt(delta1, prime) if residual_root else [0] * size
    )
    root2 = native.jet_sub(a, p_jet, prime)
    root3 = native.jet_add(one, native.jet_mul(u_jet, a, prime), prime)
    roots = [root1, root2, root3]
    deltas = [delta1, delta2, delta3]
    for root, delta in zip(roots[1:], deltas[1:], strict=True):
        if native.jet_mul(root, root, prime) != delta:
            raise AssertionError("direct-u root identity")
    return native.PathData(prime, order, x, y, roots, deltas)


def decode(path: Path, prime: int, order: int) -> tuple[dict, dict]:
    raw = path.read_bytes()
    if raw[:8] != b"DAPJ1V1\0":
        raise RuntimeError(f"bad DAPJ magic {raw[:8]!r}")
    status = struct.unpack_from("<Q", raw, 8)[0]
    values = struct.unpack_from("<12Q", raw, 16)
    names = (
        "prime", "order", "rank", "epsilon_count", "record_count",
        "term_count", "unique_expression_count", "dimension0",
        "dimension1", "dimension2", "parse_nanoseconds",
        "evaluation_nanoseconds",
    )
    header = dict(zip(names, values, strict=True))
    if status or header["prime"] != prime or header["order"] != order:
        raise RuntimeError(f"DAPJ refusal status={status} header={header}")
    if (
        header["rank"] != 2
        or header["epsilon_count"] != 1
        or (header["dimension0"], header["dimension1"], header["dimension2"])
        != (2, 2, 1)
    ):
        raise RuntimeError(f"unexpected block-2 DAPJ shape {header}")
    cursor = 112
    records = {}
    for _ in range(header["record_count"]):
        target = struct.unpack_from("<3Q", raw, cursor)
        cursor += 24
        records[target] = list(struct.unpack_from(f"<{order + 1}Q", raw, cursor))
        cursor += 8 * (order + 1)
    if cursor != len(raw):
        raise RuntimeError(f"trailing DAPJ bytes {len(raw) - cursor}")
    return header, records


def trim(poly: Sequence[int], prime: int) -> list[int]:
    result = [int(value) % prime for value in poly]
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    return result or [0]


def add(left: Sequence[int], right: Sequence[int], prime: int, sign: int = 1) -> list[int]:
    result = [0] * max(len(left), len(right))
    for index, value in enumerate(left):
        result[index] = value % prime
    for index, value in enumerate(right):
        result[index] = (result[index] + sign * value) % prime
    return trim(result, prime)


def scale(poly: Sequence[int], scalar: int, prime: int) -> list[int]:
    return trim([(scalar * value) % prime for value in poly], prime)


def multiply(left: Sequence[int], right: Sequence[int], prime: int) -> list[int]:
    result = [0] * (len(left) + len(right) - 1)
    for i, first in enumerate(left):
        if not first:
            continue
        for j, second in enumerate(right):
            result[i + j] = (result[i + j] + first * second) % prime
    return trim(result, prime)


def derivative(poly: Sequence[int], prime: int) -> list[int]:
    if len(poly) <= 1:
        return [0]
    return trim([degree * poly[degree] for degree in range(1, len(poly))], prime)


def divmod_poly(numerator: Sequence[int], denominator: Sequence[int], prime: int):
    numerator = trim(numerator, prime)
    denominator = trim(denominator, prime)
    if denominator == [0]:
        raise ZeroDivisionError
    if len(numerator) < len(denominator):
        return [0], numerator
    quotient = [0] * (len(numerator) - len(denominator) + 1)
    inverse_lead = pow(denominator[-1], -1, prime)
    remainder = numerator[:]
    while remainder != [0] and len(remainder) >= len(denominator):
        shift = len(remainder) - len(denominator)
        coefficient = remainder[-1] * inverse_lead % prime
        quotient[shift] = coefficient
        for index, value in enumerate(denominator):
            remainder[index + shift] = (
                remainder[index + shift] - coefficient * value
            ) % prime
        remainder = trim(remainder, prime)
    return trim(quotient, prime), remainder


def exact_div(numerator: Sequence[int], denominator: Sequence[int], prime: int) -> list[int]:
    quotient, remainder = divmod_poly(numerator, denominator, prime)
    if remainder != [0]:
        raise ArithmeticError("non-exact polynomial division")
    return quotient


def gcd_poly(left: Sequence[int], right: Sequence[int], prime: int) -> list[int]:
    left, right = trim(left, prime), trim(right, prime)
    while right != [0]:
        _, remainder = divmod_poly(left, right, prime)
        left, right = right, remainder
    if left == [0]:
        return [0]
    return scale(left, pow(left[-1], -1, prime), prime)


def lcm_poly(left: Sequence[int], right: Sequence[int], prime: int) -> list[int]:
    common = gcd_poly(left, right, prime)
    result = multiply(exact_div(left, common, prime), right, prime)
    return scale(result, pow(result[-1], -1, prime), prime)


def solve_linear(columns: Sequence[Sequence[int]], target: Sequence[int], prime: int) -> list[int]:
    width = len(columns)
    height = max([len(target), *(len(column) for column in columns)])
    matrix = [
        [
            (columns[column][row] if row < len(columns[column]) else 0) % prime
            for column in range(width)
        ]
        + [(target[row] if row < len(target) else 0) % prime]
        for row in range(height)
    ]
    pivot_row = 0
    pivots: list[tuple[int, int]] = []
    for column in range(width):
        pivot = next(
            (row for row in range(pivot_row, height) if matrix[row][column]),
            None,
        )
        if pivot is None:
            continue
        matrix[pivot_row], matrix[pivot] = matrix[pivot], matrix[pivot_row]
        inverse = pow(matrix[pivot_row][column], -1, prime)
        matrix[pivot_row] = [value * inverse % prime for value in matrix[pivot_row]]
        for row in range(height):
            if row == pivot_row or not matrix[row][column]:
                continue
            factor = matrix[row][column]
            matrix[row] = [
                (left - factor * right) % prime
                for left, right in zip(matrix[row], matrix[pivot_row], strict=True)
            ]
        pivots.append((pivot_row, column))
        pivot_row += 1
    for row in range(height):
        if not any(matrix[row][:-1]) and matrix[row][-1]:
            raise ArithmeticError("inconsistent modular Hermite system")
    if len(pivots) != width:
        raise ArithmeticError(f"non-unique modular Hermite system {len(pivots)}/{width}")
    result = [0] * width
    for row, column in pivots:
        result[column] = matrix[row][-1]
    return result


def nullspace_vector(rows: list[list[int]], prime: int) -> tuple[list[int], int]:
    if not rows:
        raise ValueError("empty homogeneous system")
    height, width = len(rows), len(rows[0])
    matrix = [[value % prime for value in row] for row in rows]
    pivot_row = 0
    pivot_columns: list[int] = []
    for column in range(width):
        pivot = next(
            (row for row in range(pivot_row, height) if matrix[row][column]),
            None,
        )
        if pivot is None:
            continue
        matrix[pivot_row], matrix[pivot] = matrix[pivot], matrix[pivot_row]
        inverse = pow(matrix[pivot_row][column], -1, prime)
        matrix[pivot_row] = [value * inverse % prime for value in matrix[pivot_row]]
        for row in range(height):
            if row == pivot_row or not matrix[row][column]:
                continue
            factor = matrix[row][column]
            matrix[row] = [
                (left - factor * right) % prime
                for left, right in zip(matrix[row], matrix[pivot_row], strict=True)
            ]
        pivot_columns.append(column)
        pivot_row += 1
        if pivot_row == height:
            break
    free_columns = [column for column in range(width) if column not in pivot_columns]
    if not free_columns:
        raise ArithmeticError("rational degree caps admit no homogeneous solution")
    chosen = free_columns[-1]
    result = [0] * width
    result[chosen] = 1
    for row, column in reversed(list(enumerate(pivot_columns))):
        result[column] = -sum(
            matrix[row][free] * result[free] for free in free_columns
        ) % prime
    return result, len(free_columns)


def polynomial_taylor(poly: Sequence[int], center: int, count: int,
                      prime: int) -> list[int]:
    return [
        sum(
            poly[degree] * math.comb(degree, order)
            * pow(center, degree - order, prime)
            for degree in range(order, len(poly))
        ) % prime
        for order in range(count)
    ]


def reconstruct_multicenter(
    samples: Sequence[tuple[Fraction, Sequence[int]]],
    numerator_cap: int,
    denominator_cap: int,
    prime: int,
) -> dict:
    width = numerator_cap + 1 + denominator_cap + 1
    rows: list[list[int]] = []
    for center_fraction, series in samples:
        center = center_fraction.numerator % prime * pow(
            center_fraction.denominator % prime, -1, prime
        ) % prime
        powers = [
            polynomial_taylor([0] * degree + [1], center, len(series), prime)
            for degree in range(max(numerator_cap, denominator_cap) + 1)
        ]
        for order in range(len(series)):
            row = [
                powers[degree][order] if order <= degree else 0
                for degree in range(numerator_cap + 1)
            ]
            for degree in range(denominator_cap + 1):
                coefficient = 0
                for local_order in range(min(order, degree) + 1):
                    coefficient += powers[degree][local_order] * series[order - local_order]
                row.append(-coefficient % prime)
            rows.append(row)
    vector, nullity = nullspace_vector(rows, prime)
    numerator = trim(vector[: numerator_cap + 1], prime)
    denominator = trim(vector[numerator_cap + 1 :], prime)
    if denominator == [0]:
        raise ArithmeticError("null vector has zero denominator")
    common = gcd_poly(numerator, denominator, prime)
    numerator = exact_div(numerator, common, prime)
    denominator = exact_div(denominator, common, prime)
    normalization = pow(denominator[-1], -1, prime)
    numerator = scale(numerator, normalization, prime)
    denominator = scale(denominator, normalization, prime)
    return {
        "numerator": numerator,
        "denominator": denominator,
        "numerator_degree": len(numerator) - 1,
        "denominator_degree": len(denominator) - 1,
        "raw_nullity": nullity,
        "equations": len(rows),
        "unknowns": width,
    }


def validates_at_center(numerator: Sequence[int], denominator: Sequence[int],
                        center: Fraction, series: Sequence[int], prime: int) -> bool:
    center_mod = center.numerator % prime * pow(center.denominator % prime, -1, prime) % prime
    p_series = polynomial_taylor(numerator, center_mod, len(series), prime)
    q_series = polynomial_taylor(denominator, center_mod, len(series), prime)
    return p_series == [
        sum(q_series[k] * series[degree - k] for k in range(degree + 1)) % prime
        for degree in range(len(series))
    ]


def rational_identity(
    numerator: Sequence[int], denominator: Sequence[int],
    primitive_numerator: Sequence[int], primitive_denominator: Sequence[int],
    remainder_numerator: Sequence[int], remainder_denominator: Sequence[int],
    prime: int,
) -> bool:
    # f = (P/Q)' + B/S, cleared over D Q^2 S.
    q_prime = derivative(primitive_denominator, prime)
    p_prime = derivative(primitive_numerator, prime)
    derivative_numerator = add(
        multiply(p_prime, primitive_denominator, prime),
        multiply(primitive_numerator, q_prime, prime),
        prime,
        -1,
    )
    left = multiply(
        multiply(numerator, multiply(primitive_denominator, primitive_denominator, prime), prime),
        remainder_denominator,
        prime,
    )
    right_derivative = multiply(
        multiply(derivative_numerator, denominator, prime),
        remainder_denominator,
        prime,
    )
    right_remainder = multiply(
        multiply(remainder_numerator, denominator, prime),
        multiply(primitive_denominator, primitive_denominator, prime),
        prime,
    )
    return add(left, add(right_derivative, right_remainder, prime), prime, -1) == [0]


def rational_hermite(numerator: Sequence[int], denominator: Sequence[int], prime: int) -> dict:
    numerator, denominator = trim(numerator, prime), trim(denominator, prime)
    common = gcd_poly(numerator, denominator, prime)
    numerator = exact_div(numerator, common, prime)
    denominator = exact_div(denominator, common, prime)
    scale_denominator = pow(denominator[-1], -1, prime)
    numerator = scale(numerator, scale_denominator, prime)
    denominator = scale(denominator, scale_denominator, prime)
    polynomial_part, proper_numerator = divmod_poly(numerator, denominator, prime)
    repeated = gcd_poly(denominator, derivative(denominator, prime), prime)
    squarefree = exact_div(denominator, repeated, prime)

    # Integrate the polynomial part with zero integration constant.
    polynomial_primitive = [0] + [
        coefficient * pow(degree + 1, -1, prime) % prime
        for degree, coefficient in enumerate(polynomial_part)
    ]

    repeated_degree = len(repeated) - 1
    squarefree_degree = len(squarefree) - 1
    repeated_square = multiply(repeated, repeated, prime)
    common_denominator = lcm_poly(
        lcm_poly(denominator, repeated_square, prime), squarefree, prime
    )
    target = multiply(
        proper_numerator,
        exact_div(common_denominator, denominator, prime),
        prime,
    )
    columns: list[list[int]] = []
    repeated_prime = derivative(repeated, prime)
    repeated_multiplier = exact_div(common_denominator, repeated_square, prime)
    for degree in range(repeated_degree):
        monomial = [0] * degree + [1]
        monomial_prime = derivative(monomial, prime)
        derivative_numerator = add(
            multiply(monomial_prime, repeated, prime),
            multiply(monomial, repeated_prime, prime),
            prime,
            -1,
        )
        columns.append(multiply(derivative_numerator, repeated_multiplier, prime))
    squarefree_multiplier = exact_div(common_denominator, squarefree, prime)
    for degree in range(squarefree_degree):
        columns.append(
            multiply([0] * degree + [1], squarefree_multiplier, prime)
        )
    solution = solve_linear(columns, target, prime)
    exact_numerator = trim(solution[:repeated_degree] or [0], prime)
    remainder_numerator = trim(solution[repeated_degree:] or [0], prime)
    primitive_numerator = add(
        exact_numerator,
        multiply(polynomial_primitive, repeated, prime),
        prime,
    )
    verified = rational_identity(
        numerator, denominator,
        primitive_numerator, repeated,
        remainder_numerator, squarefree,
        prime,
    )
    return {
        "primitive_numerator": primitive_numerator,
        "primitive_denominator": repeated,
        "remainder_numerator": remainder_numerator,
        "remainder_denominator": squarefree,
        "input_numerator_degree": len(numerator) - 1,
        "input_denominator_degree": len(denominator) - 1,
        "repeated_degree": repeated_degree,
        "squarefree_degree": squarefree_degree,
        "verified": verified,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=2_305_843_009_213_691_819)
    parser.add_argument("--p", type=Fraction, default=Fraction(4, 11))
    parser.add_argument("--epsilon", type=int, default=11)
    parser.add_argument("--order", type=int, default=64)
    parser.add_argument("--validation-order", type=int, default=12)
    parser.add_argument("--threads", type=int, default=2)
    parser.add_argument("--numerator-cap", type=int, default=60)
    parser.add_argument("--denominator-cap", type=int, default=60)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    native = load_native()
    construction_centers = (Fraction(1, 2), Fraction(3, 2))
    validation_center = Fraction(-1, 2)
    center_results = {}
    path_seconds = native_seconds = contraction_seconds = 0.0
    parse_seconds = evaluation_seconds = 0.0
    headers = []
    native_stderr = []
    for center in (*construction_centers, validation_center):
        local_order = (
            args.order if center in construction_centers else args.validation_order
        )
        started = time.perf_counter()
        data = direct_u_path_data(
            native, args.prime, local_order, args.p, center
        )
        path_seconds += time.perf_counter() - started
        with tempfile.TemporaryDirectory(prefix="cf303-modular-hermite-") as directory:
            request = Path(directory) / "request.txt"
            response = Path(directory) / "response.bin"
            write_request(request, data, args.epsilon)
            environment = dict(__import__("os").environ)
            environment["OMP_NUM_THREADS"] = str(args.threads)
            native_started = time.perf_counter()
            process = subprocess.run(
                [str(BINARY), str(BLOCK2_INPUT), str(request), str(response),
                 "--threads", str(args.threads)],
                capture_output=True,
                text=True,
                check=False,
                env=environment,
            )
            native_seconds += time.perf_counter() - native_started
            if process.returncode:
                raise RuntimeError(f"native evaluator failed: {process.stderr}")
            header, records = decode(response, args.prime, local_order)
        headers.append(header)
        native_stderr.append(process.stderr.strip())
        parse_seconds += header["parse_nanoseconds"] / 1e9
        evaluation_seconds += header["evaluation_nanoseconds"] / 1e9
        started = time.perf_counter()
        center_results[center] = {
            row: native.jet_add(
                native.jet_mul(data.dx, records[(1, row, 1)], args.prime, local_order),
                native.jet_mul(data.dy, records[(2, row, 1)], args.prime, local_order),
                args.prime,
            )
            for row in (1, 2)
        }
        contraction_seconds += time.perf_counter() - started

    results = {}
    reconstruction_seconds = 0.0
    hermite_seconds = 0.0
    validation = {}
    for row in (1, 2):
        started = time.perf_counter()
        profile = reconstruct_multicenter(
            [(center, center_results[center][row]) for center in construction_centers],
            args.numerator_cap,
            args.denominator_cap,
            args.prime,
        )
        reconstruction_seconds += time.perf_counter() - started
        validation[str(row)] = validates_at_center(
            profile["numerator"], profile["denominator"],
            validation_center, center_results[validation_center][row], args.prime
        )
        if not validation[str(row)]:
            raise RuntimeError(f"fresh-center rational reconstruction failed in row {row}")
        started = time.perf_counter()
        reduction = rational_hermite(
            profile["numerator"], profile["denominator"], args.prime
        )
        hermite_seconds += time.perf_counter() - started
        if not reduction["verified"]:
            raise RuntimeError(f"modular Hermite identity failed in row {row}")
        results[str(row)] = {
            "series_profile": {
                key: value for key, value in profile.items()
                if key not in {"numerator", "denominator"}
            },
            "reduction": reduction,
        }
    report = {
        "status": "CF303Block2ModularHermitePilotAcceptedV1",
        "claim": (
            "At the declared (p,epsilon) image, each direct-u forcing was "
            "reconstructed from held-overdetermined path jets and Hermite-"
            "reduced exactly in F_q[u-1/2]."
        ),
        "block": [25, 2],
        "prime": args.prime,
        "p": [args.p.numerator, args.p.denominator],
        "epsilon": args.epsilon,
        "jet_order": args.order,
        "validation_jet_order": args.validation_order,
        "construction_centers": [
            [center.numerator, center.denominator] for center in construction_centers
        ],
        "validation_center": [validation_center.numerator, validation_center.denominator],
        "fresh_center_validation": validation,
        "degree_caps": [args.numerator_cap, args.denominator_cap],
        "threads": args.threads,
        "native": headers,
        "timings": {
            "path_data": path_seconds,
            "native_wall": native_seconds,
            "native_parse": parse_seconds,
            "native_evaluation": evaluation_seconds,
            "contraction": contraction_seconds,
            "rational_reconstruction": reconstruction_seconds,
            "hermite": hermite_seconds,
        },
        "rows": results,
        "native_stderr": native_stderr,
    }
    encoded = json.dumps(report, indent=2)
    print(encoded)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
