#!/usr/bin/env python3
"""Recover constant dlog residues from deferred finite-field path jets.

This is a scratch prototype.  It deliberately avoids loading the accepted
connection into a Wolfram kernel: the existing DAPJ1 FLINT provider evaluates
the preserved deferred connection, while this driver performs only modular
series arithmetic, epsilon-order isolation, dlog-basis selection, CRT,
rational reconstruction, and fresh-prime validation.

The CF303 command at the bottom is one concrete fixture.  The reconstruction
core itself consumes a preparation, selected rows, a path-data provider, and a
candidate source alphabet; it contains no family-specific matrix arithmetic.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import pickle
import re
import struct
import subprocess
import tempfile
import time
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Callable, Iterable, Sequence

import sympy as sp
from sympy.parsing.mathematica import parse_mathematica


ROOT_SQUARE_TEXT = (
    "1 - 2*x + x^2 + 2*y + 2*x*y + y^2",
    "1 + 2*x + x^2 - 2*y + 2*x*y + y^2",
    "1 - 4*x*y",
)


def inv_mod(value: int, prime: int) -> int:
    return pow(value % prime, -1, prime)


def fraction_mod(value: Fraction, prime: int) -> int:
    return value.numerator % prime * inv_mod(value.denominator, prime) % prime


def jet_constant(value: int, size: int, prime: int) -> list[int]:
    return [value % prime] + [0] * (size - 1)


def jet_add(left: Sequence[int], right: Sequence[int], prime: int) -> list[int]:
    return [(a + b) % prime for a, b in zip(left, right)]


def jet_neg(value: Sequence[int], prime: int) -> list[int]:
    return [(-entry) % prime for entry in value]


def jet_sub(left: Sequence[int], right: Sequence[int], prime: int) -> list[int]:
    return [(a - b) % prime for a, b in zip(left, right)]


def jet_mul(
    left: Sequence[int], right: Sequence[int], prime: int, size: int | None = None
) -> list[int]:
    if size is None:
        size = min(len(left), len(right))
    return [
        sum(left[k] * right[degree - k] for k in range(degree + 1)) % prime
        for degree in range(size)
    ]


def jet_inv(value: Sequence[int], prime: int, size: int | None = None) -> list[int]:
    if size is None:
        size = len(value)
    if not value or value[0] % prime == 0:
        raise ZeroDivisionError("singular jet")
    result = [0] * size
    result[0] = inv_mod(value[0], prime)
    for degree in range(1, size):
        result[degree] = (
            -result[0]
            * sum(
                (value[k] if k < len(value) else 0) * result[degree - k]
                for k in range(1, degree + 1)
            )
        ) % prime
    return result


def jet_pow(value: Sequence[int], exponent: int, prime: int) -> list[int]:
    size = len(value)
    if exponent < 0:
        return jet_pow(jet_inv(value, prime), -exponent, prime)
    result = jet_constant(1, size, prime)
    base = list(value)
    power = exponent
    while power:
        if power & 1:
            result = jet_mul(result, base, prime)
        power >>= 1
        if power:
            base = jet_mul(base, base, prime)
    return result


def legendre_symbol(value: int, prime: int) -> int:
    result = pow(value % prime, (prime - 1) // 2, prime)
    return -1 if result == prime - 1 else result


def tonelli_shanks(value: int, prime: int) -> int:
    value %= prime
    if value == 0:
        return 0
    if legendre_symbol(value, prime) != 1:
        raise ValueError("not a square modulo prime")
    if prime % 4 == 3:
        return pow(value, (prime + 1) // 4, prime)
    q = prime - 1
    s = 0
    while q % 2 == 0:
        s += 1
        q //= 2
    nonresidue = 2
    while legendre_symbol(nonresidue, prime) != -1:
        nonresidue += 1
    c = pow(nonresidue, q, prime)
    x = pow(value, (q + 1) // 2, prime)
    t = pow(value, q, prime)
    m = s
    while t != 1:
        i = 1
        probe = t * t % prime
        while probe != 1:
            probe = probe * probe % prime
            i += 1
            if i == m:
                raise ValueError("Tonelli-Shanks failed")
        b = pow(c, 1 << (m - i - 1), prime)
        x = x * b % prime
        t = t * b * b % prime
        c = b * b % prime
        m = i
    return x


def jet_sqrt(value: Sequence[int], prime: int, sign: int = 1) -> list[int]:
    if not value or value[0] % prime == 0:
        raise ZeroDivisionError("ramified square-root jet")
    root0 = tonelli_shanks(value[0], prime)
    if sign < 0:
        root0 = -root0 % prime
    result = [0] * len(value)
    result[0] = root0
    inverse_twice_root = inv_mod(2 * root0, prime)
    for degree in range(1, len(value)):
        known = sum(result[k] * result[degree - k] for k in range(1, degree))
        result[degree] = (value[degree] - known) * inverse_twice_root % prime
    if jet_mul(result, result, prime) != [entry % prime for entry in value]:
        raise AssertionError("square-root series check failed")
    return result


def jet_derivative(value: Sequence[int], prime: int) -> list[int]:
    return [(degree * value[degree]) % prime for degree in range(1, len(value))]


@dataclass(frozen=True)
class PathData:
    prime: int
    order: int
    x: list[int]
    y: list[int]
    roots: list[list[int]]
    deltas: list[list[int]]

    @property
    def dx(self) -> list[int]:
        return jet_derivative(self.x, self.prime)

    @property
    def dy(self) -> list[int]:
        return jet_derivative(self.y, self.prime)


def cf303_u3_path_data(
    prime: int, order: int, endpoints: tuple[Fraction, Fraction]
) -> PathData:
    """The exact Kallen2Bilinear115, u=3 path contract used by CF303."""
    size = order + 1
    z0, z1 = endpoints
    z = [fraction_mod(z0, prime), fraction_mod(z1 - z0, prime)] + [0] * (size - 2)
    one = jet_constant(1, size, prime)
    four = jet_constant(4, size, prime)
    six = jet_constant(6, size, prime)
    nine = jet_constant(9, size, prime)
    z_one_minus_z = jet_mul(z, jet_sub(one, z, prime), prime)
    four_product = jet_mul(four, z_one_minus_z, prime)
    a = jet_mul(
        jet_sub(four_product, six, prime),
        jet_inv(jet_add(nine, four_product, prime), prime),
        prime,
    )
    x = jet_neg(jet_mul(a, z, prime), prime)
    y = jet_mul(jet_sub(one, a, prime), jet_sub(one, z, prime), prime)
    x2 = jet_mul(x, x, prime)
    y2 = jet_mul(y, y, prime)
    xy = jet_mul(x, y, prime)
    two_x = [(2 * entry) % prime for entry in x]
    two_y = [(2 * entry) % prime for entry in y]
    two_xy = [(2 * entry) % prime for entry in xy]
    four_xy = [(4 * entry) % prime for entry in xy]
    delta1 = jet_add(
        jet_add(
            jet_add(jet_sub(one, two_x, prime), x2, prime),
            two_y,
            prime,
        ),
        jet_add(two_xy, y2, prime),
        prime,
    )
    delta2 = jet_add(
        jet_add(
            jet_add(jet_add(one, two_x, prime), x2, prime),
            jet_neg(two_y, prime),
            prime,
        ),
        jet_add(two_xy, y2, prime),
        prime,
    )
    delta3 = jet_sub(one, four_xy, prime)
    root1 = jet_sqrt(delta1, prime)
    root2 = jet_sub(a, z, prime)
    root3 = jet_add(one, [(3 * entry) % prime for entry in a], prime)
    roots = [root1, root2, root3]
    deltas = [delta1, delta2, delta3]
    for root, delta in zip(roots, deltas):
        if jet_mul(root, root, prime) != delta:
            raise AssertionError("declared path branch does not square to delta")
    return PathData(prime, order, x, y, roots, deltas)


def cf303_kallen2b115_second_axis_data(
    prime: int, order: int, target: tuple[Fraction, Fraction]
) -> PathData:
    """Kallen2Bilinear115's preferred GPL axis.

    The first chart coordinate p is frozen.  The second coordinate runs from
    the engine's base u=1/2 to the caller-supplied target u.  On this axis the
    source letters of the GPL-closed subsystem pull back to polynomials of
    degree at most two; only the unused residual Delta1 sheet remains
    quadratic, and it is continued here solely because DAPJ1 authenticates the
    complete deferred rectangle before returning the selected rows.
    """
    size = order + 1
    p_value, u_target = target
    p_jet = jet_constant(fraction_mod(p_value, prime), size, prime)
    u0 = Fraction(1, 2)
    u_jet = [
        fraction_mod(u0, prime),
        fraction_mod(u_target - u0, prime),
    ] + [0] * (size - 2)
    one = jet_constant(1, size, prime)
    two = jet_constant(2, size, prime)
    four = jet_constant(4, size, prime)
    p_one_minus_p = jet_mul(p_jet, jet_sub(one, p_jet, prime), prime)
    four_k = jet_mul(four, p_one_minus_p, prime)
    a = jet_mul(
        jet_sub(four_k, jet_mul(two, u_jet, prime), prime),
        jet_inv(jet_add(jet_mul(u_jet, u_jet, prime), four_k, prime), prime),
        prime,
    )
    x = jet_neg(jet_mul(a, p_jet, prime), prime)
    y = jet_mul(jet_sub(one, a, prime), jet_sub(one, p_jet, prime), prime)
    x2 = jet_mul(x, x, prime)
    y2 = jet_mul(y, y, prime)
    xy = jet_mul(x, y, prime)
    two_x = [(2 * entry) % prime for entry in x]
    two_y = [(2 * entry) % prime for entry in y]
    two_xy = [(2 * entry) % prime for entry in xy]
    four_xy = [(4 * entry) % prime for entry in xy]
    delta1 = jet_add(
        jet_add(
            jet_add(jet_sub(one, two_x, prime), x2, prime),
            two_y,
            prime,
        ),
        jet_add(two_xy, y2, prime),
        prime,
    )
    delta2 = jet_add(
        jet_add(
            jet_add(jet_add(one, two_x, prime), x2, prime),
            jet_neg(two_y, prime),
            prime,
        ),
        jet_add(two_xy, y2, prime),
        prime,
    )
    delta3 = jet_sub(one, four_xy, prime)
    root1 = jet_sqrt(delta1, prime)
    root2 = jet_sub(a, p_jet, prime)
    root3 = jet_add(one, jet_mul(u_jet, a, prime), prime)
    roots = [root1, root2, root3]
    deltas = [delta1, delta2, delta3]
    for root, delta in zip(roots, deltas):
        if jet_mul(root, root, prime) != delta:
            raise AssertionError("declared Kallen2Bilinear115 branch is invalid")
    return PathData(prime, order, x, y, roots, deltas)


def write_dapj_request(path: Path, data: PathData, epsilon_values: Sequence[int]) -> None:
    lines = [
        "DeferredPathJetRequestV1",
        f"prime {data.prime}",
        "variables x y eps",
        f"order {data.order}",
        "rank 3",
    ]
    lines.extend(f"root {expression}" for expression in ROOT_SQUARE_TEXT)
    lines.append(f"epsilon_count {len(epsilon_values)}")
    lines.extend(f"epsilon {value % data.prime}" for value in epsilon_values)
    lines.append("x_jet " + " ".join(map(str, data.x)))
    lines.append("y_jet " + " ".join(map(str, data.y)))
    for delta, root in zip(data.deltas, data.roots):
        lines.append("delta_jet " + " ".join(map(str, delta)))
        lines.append("root_jet " + " ".join(map(str, root)))
    path.write_text("\n".join(lines) + "\n")


@dataclass
class NativeBatch:
    records: dict[tuple[int, int, int], list[list[int]]]
    parse_seconds: float
    evaluation_seconds: float
    wall_seconds: float
    term_count: int
    unique_expression_count: int


def read_dapj_output(
    path: Path,
    prime: int,
    order: int,
    epsilon_count: int,
    selected_rows: set[int],
) -> NativeBatch:
    raw = path.read_bytes()
    if len(raw) < 112 or raw[:8] != b"DAPJ1V1\0":
        raise ValueError("invalid DAPJ1 header")
    status = struct.unpack_from("<Q", raw, 8)[0]
    header = struct.unpack_from("<12Q", raw, 16)
    if status:
        raise RuntimeError(f"DAPJ1 refused request: status={status}, detail={header[7:9]}")
    (
        observed_prime,
        observed_order,
        rank,
        observed_epsilon_count,
        record_count,
        term_count,
        unique_count,
        dimension0,
        dimension1,
        dimension2,
        parse_ns,
        evaluation_ns,
    ) = header
    if (
        observed_prime != prime
        or observed_order != order
        or rank != 3
        or observed_epsilon_count != epsilon_count
        or (dimension0, dimension1, dimension2) != (2, 45, 45)
        or record_count != 2 * 45 * 45
    ):
        raise ValueError(f"unexpected DAPJ1 shape: {header}")
    cursor = 112
    payload_words = epsilon_count * (order + 1)
    payload_bytes = payload_words * 8
    records: dict[tuple[int, int, int], list[list[int]]] = {}
    for _ in range(record_count):
        form, row, column = struct.unpack_from("<3Q", raw, cursor)
        cursor += 24
        if row in selected_rows and column in selected_rows:
            values = struct.unpack_from(f"<{payload_words}Q", raw, cursor)
            records[(form, row, column)] = [
                list(values[index * (order + 1) : (index + 1) * (order + 1)])
                for index in range(epsilon_count)
            ]
        cursor += payload_bytes
    if cursor != len(raw):
        raise ValueError(f"DAPJ1 trailing payload: {len(raw) - cursor} bytes")
    return NativeBatch(
        records,
        parse_ns / 1e9,
        evaluation_ns / 1e9,
        0.0,
        term_count,
        unique_count,
    )


def run_dapj(
    binary: Path,
    preparation: Path,
    data: PathData,
    epsilon_values: Sequence[int],
    selected_rows: set[int],
    threads: int,
) -> NativeBatch:
    if not 1 <= threads <= 6:
        raise ValueError("prototype thread allocation must be in [1,6]")
    with tempfile.TemporaryDirectory(prefix="native_residue_") as directory:
        directory_path = Path(directory)
        request = directory_path / "request.txt"
        output = directory_path / "response.bin"
        write_dapj_request(request, data, epsilon_values)
        environment = dict(os.environ)
        environment["OMP_NUM_THREADS"] = str(threads)
        started = time.perf_counter()
        process = subprocess.run(
            [
                str(binary),
                str(preparation),
                str(request),
                str(output),
                "--threads",
                str(threads),
            ],
            check=False,
            capture_output=True,
            text=True,
            env=environment,
        )
        wall = time.perf_counter() - started
        if process.returncode != 0 or not output.exists():
            raise RuntimeError(
                f"DAPJ1 failed ({process.returncode}): {process.stderr.strip()}"
            )
        batch = read_dapj_output(
            output, data.prime, data.order, len(epsilon_values), selected_rows
        )
        batch.wall_seconds = wall
        return batch


def matrix_inverse_mod(matrix: Sequence[Sequence[int]], prime: int) -> list[list[int]]:
    size = len(matrix)
    augmented = [
        [entry % prime for entry in row]
        + [1 if row_index == column else 0 for column in range(size)]
        for row_index, row in enumerate(matrix)
    ]
    for column in range(size):
        pivot = next(
            (row for row in range(column, size) if augmented[row][column]), None
        )
        if pivot is None:
            raise ValueError("singular modular matrix")
        augmented[column], augmented[pivot] = augmented[pivot], augmented[column]
        scale = inv_mod(augmented[column][column], prime)
        augmented[column] = [(value * scale) % prime for value in augmented[column]]
        for row in range(size):
            if row == column or not augmented[row][column]:
                continue
            factor = augmented[row][column]
            augmented[row] = [
                (left - factor * right) % prime
                for left, right in zip(augmented[row], augmented[column])
            ]
    return [row[size:] for row in augmented]


def matrix_vector_mod(
    matrix: Sequence[Sequence[int]], vector: Sequence[int], prime: int
) -> list[int]:
    return [sum(a * b for a, b in zip(row, vector)) % prime for row in matrix]


def isolate_epsilon_orders(
    batch: NativeBatch,
    epsilon_values: Sequence[int],
    epsilon_orders: Sequence[int],
    prime: int,
) -> tuple[dict[int, dict[tuple[int, int, int], list[int]]], int]:
    construction_count = len(epsilon_orders)
    if len(epsilon_values) <= construction_count:
        raise ValueError("at least one held-out epsilon image is required")
    evaluation_matrix = [
        [pow(epsilon_values[row] % prime, order, prime) for order in epsilon_orders]
        for row in range(construction_count)
    ]
    inverse = matrix_inverse_mod(evaluation_matrix, prime)
    isolated = {order: {} for order in epsilon_orders}
    failures = 0
    for target, images in batch.records.items():
        coefficient_jets = [[0] * len(images[0]) for _ in epsilon_orders]
        for degree in range(len(images[0])):
            values = [images[row][degree] for row in range(construction_count)]
            coefficients = matrix_vector_mod(inverse, values, prime)
            for index, coefficient in enumerate(coefficients):
                coefficient_jets[index][degree] = coefficient
        for index, order in enumerate(epsilon_orders):
            isolated[order][target] = coefficient_jets[index]
        for image_index in range(construction_count, len(epsilon_values)):
            predicted = [
                sum(
                    coefficient_jets[index][degree]
                    * pow(epsilon_values[image_index] % prime, order, prime)
                    for index, order in enumerate(epsilon_orders)
                )
                % prime
                for degree in range(len(images[0]))
            ]
            if predicted != images[image_index]:
                failures += 1
                break
    return isolated, failures


def pull_back_isolated_orders(
    isolated: dict[int, dict[tuple[int, int, int], list[int]]],
    path_data: PathData,
    selected_rows: Sequence[int],
) -> dict[int, dict[tuple[int, int], list[int]]]:
    prime = path_data.prime
    effective_size = path_data.order
    zero = [0] * (path_data.order + 1)
    result: dict[int, dict[tuple[int, int], list[int]]] = {}
    for epsilon_order, tensor in isolated.items():
        matrix: dict[tuple[int, int], list[int]] = {}
        for row in selected_rows:
            for column in selected_rows:
                av = tensor.get((1, row, column), zero)
                aw = tensor.get((2, row, column), zero)
                matrix[(row, column)] = jet_add(
                    jet_mul(path_data.dx, av, prime, effective_size),
                    jet_mul(path_data.dy, aw, prime, effective_size),
                    prime,
                )
        result[epsilon_order] = matrix
    return result


def extract_balanced_list(text: str, marker: str, start: int = 0) -> tuple[str, int] | None:
    found = text.find(marker, start)
    if found < 0:
        return None
    cursor = found + len(marker)
    depth = 1
    quote = False
    escaped = False
    end = cursor
    while end < len(text) and depth:
        char = text[end]
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quote = False
        elif char == '"':
            quote = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        end += 1
    if depth:
        return None
    return text[cursor : end - 1], end


def split_top_level(text: str) -> list[str]:
    pieces: list[str] = []
    start = 0
    round_depth = square_depth = curly_depth = 0
    quote = False
    escaped = False
    for index, char in enumerate(text):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quote = False
            continue
        if char == '"':
            quote = True
        elif char == "(":
            round_depth += 1
        elif char == ")":
            round_depth -= 1
        elif char == "[":
            square_depth += 1
        elif char == "]":
            square_depth -= 1
        elif char == "{":
            curly_depth += 1
        elif char == "}":
            curly_depth -= 1
        elif char == "," and round_depth == square_depth == curly_depth == 0:
            pieces.append(text[start:index].strip())
            start = index + 1
    final = text[start:].strip()
    if final:
        pieces.append(final)
    return pieces


def source_alphabet_texts(state_file: Path, tail_bytes: int = 2_000_000) -> list[str]:
    raw = state_file.read_bytes()
    text = raw[-tail_bytes:].decode(errors="ignore")
    bodies: list[str] = []
    start = 0
    marker = '"Alphabet" -> {'
    while True:
        found = extract_balanced_list(text, marker, start)
        if found is None:
            break
        body, start = found
        bodies.append(body)
    diagonal = extract_balanced_list(text, '"DiagonalAlphabets" -> {')
    if diagonal is not None:
        bodies.append(diagonal[0])
    expressions: list[str] = []
    seen: set[str] = set()
    for body in bodies:
        for expression in split_top_level(body):
            normalized = " ".join(expression.replace("\\\n", "").split())
            if normalized and normalized not in seen:
                seen.add(normalized)
                expressions.append(normalized)
    return expressions


@dataclass(frozen=True)
class CandidateLetter:
    label: str
    expression: sp.Expr


def parse_rationalized_candidates(raw_expressions: Sequence[str]) -> tuple[list[CandidateLetter], dict[str, int]]:
    x, y = sp.symbols("x y")
    rho1, rho2, rho3 = sp.symbols("rho1 rho2 rho3")
    delta1 = 1 - 2 * x + x**2 + 2 * y + 2 * x * y + y**2
    delta2 = 1 + 2 * x + x**2 - 2 * y + 2 * x * y + y**2
    delta3 = 1 - 4 * x * y
    replacements = {
        sp.sqrt(delta1): rho1,
        sp.sqrt(delta2): rho2,
        sp.sqrt(delta3): rho3,
    }
    candidates: list[CandidateLetter] = []
    seen: set[str] = set()
    statistics = {
        "raw": len(raw_expressions),
        "parse_failed": 0,
        "residual_root": 0,
        "residual_norm_added": 0,
        "residual_norm_failed": 0,
        "unsupported_root": 0,
        "duplicate": 0,
    }
    for raw in raw_expressions:
        try:
            expression = parse_mathematica(raw).xreplace(replacements)
        except Exception:
            statistics["parse_failed"] += 1
            continue
        if expression.has(rho1):
            statistics["residual_root"] += 1
            # The selected GPL subsystem is invariant under the remaining
            # quadratic deck transformation.  Individual metadata letters
            # may nevertheless be written on one sheet.  Their field norm is
            # the combined rational letter whose dlog can occur in that
            # invariant connection.  Reduce numerator and denominator modulo
            # rho1^2-delta1 instead of asking for a large symbolic chart
            # pullback.
            try:
                numerator, denominator = sp.fraction(sp.cancel(expression))
                modulus = sp.Poly(rho1**2 - delta1, rho1, domain="EX")
                numerator_norm = sp.Poly(
                    sp.expand(numerator * numerator.subs(rho1, -rho1)),
                    rho1,
                    domain="EX",
                ).rem(modulus).as_expr()
                denominator_norm = sp.Poly(
                    sp.expand(denominator * denominator.subs(rho1, -rho1)),
                    rho1,
                    domain="EX",
                ).rem(modulus).as_expr()
                expression = sp.cancel(numerator_norm / denominator_norm)
                if expression.has(rho1):
                    raise ValueError("quadratic norm retained the residual root")
                raw = f"NormDelta1[{raw}]"
                statistics["residual_norm_added"] += 1
            except Exception:
                statistics["residual_norm_failed"] += 1
                continue
        remaining_half_powers = [
            power
            for power in expression.atoms(sp.Pow)
            if power.exp.is_Rational and power.exp.q != 1
        ]
        if remaining_half_powers:
            statistics["unsupported_root"] += 1
            continue
        key = sp.srepr(expression)
        if key in seen:
            statistics["duplicate"] += 1
            continue
        seen.add(key)
        candidates.append(CandidateLetter(raw, expression))
    statistics["accepted"] = len(candidates)
    return candidates, statistics


def evaluate_expression_jet(
    expression: sp.Expr,
    values: dict[sp.Symbol, Sequence[int]],
    prime: int,
    size: int,
) -> list[int]:
    if expression.is_Integer:
        return jet_constant(int(expression), size, prime)
    if expression.is_Rational:
        return jet_constant(
            int(expression.p) * inv_mod(int(expression.q), prime), size, prime
        )
    if expression.is_Symbol:
        if expression not in values:
            raise ValueError(f"unbound symbol {expression}")
        return list(values[expression][:size])
    if expression.is_Add:
        result = jet_constant(0, size, prime)
        for argument in expression.args:
            result = jet_add(
                result, evaluate_expression_jet(argument, values, prime, size), prime
            )
        return result
    if expression.is_Mul:
        result = jet_constant(1, size, prime)
        for argument in expression.args:
            result = jet_mul(
                result, evaluate_expression_jet(argument, values, prime, size), prime
            )
        return result
    if expression.is_Pow and expression.exp.is_Integer:
        return jet_pow(
            evaluate_expression_jet(expression.base, values, prime, size),
            int(expression.exp),
            prime,
        )
    raise ValueError(f"unsupported expression head: {expression.func}")


def candidate_dlog_jets(
    candidates: Sequence[CandidateLetter], path_data: PathData
) -> tuple[list[tuple[CandidateLetter, list[int]]], dict[str, int]]:
    x, y, rho1, rho2, rho3 = sp.symbols("x y rho1 rho2 rho3")
    values = {
        x: path_data.x,
        y: path_data.y,
        rho1: path_data.roots[0],
        rho2: path_data.roots[1],
        rho3: path_data.roots[2],
    }
    result: list[tuple[CandidateLetter, list[int]]] = []
    statistics = {"singular": 0, "unsupported": 0, "constant": 0}
    for candidate in candidates:
        try:
            letter = evaluate_expression_jet(
                candidate.expression, values, path_data.prime, path_data.order + 1
            )
            if not letter[0]:
                statistics["singular"] += 1
                continue
            derivative = jet_derivative(letter, path_data.prime)
            dlog = jet_mul(
                derivative,
                jet_inv(letter[: path_data.order], path_data.prime),
                path_data.prime,
                path_data.order,
            )
        except (ValueError, ZeroDivisionError):
            statistics["unsupported"] += 1
            continue
        if not any(dlog):
            statistics["constant"] += 1
            continue
        result.append((candidate, dlog))
    statistics["usable"] = len(result)
    return result, statistics


def select_column_basis(
    vectors: Sequence[Sequence[int]], prime: int
) -> tuple[list[int], list[int]]:
    echelon: list[tuple[int, list[int]]] = []
    selected: list[int] = []
    pivot_rows: list[int] = []
    for vector_index, vector in enumerate(vectors):
        reduced = [entry % prime for entry in vector]
        for pivot, basis_vector in echelon:
            factor = reduced[pivot]
            if factor:
                reduced = [
                    (left - factor * right) % prime
                    for left, right in zip(reduced, basis_vector)
                ]
        pivot = next((index for index, value in enumerate(reduced) if value), None)
        if pivot is None:
            continue
        scale = inv_mod(reduced[pivot], prime)
        reduced = [(entry * scale) % prime for entry in reduced]
        echelon.append((pivot, reduced))
        selected.append(vector_index)
        pivot_rows.append(pivot)
    return selected, pivot_rows


def select_low_complexity_dlog_basis(
    candidates: Sequence[CandidateLetter],
    path_provider: Callable[[int, int, tuple[Fraction, Fraction]], PathData],
    prime: int,
    endpoints: Sequence[tuple[Fraction, Fraction]],
    jet_order: int = 12,
) -> list[str]:
    """Choose a full dlog basis while avoiding gratuitously large letters.

    Several path targets are stacked so an accidental specialization cannot
    make two source letters look dependent. Complexity changes only the basis
    of the same dlog span; the connection fit is still accepted independently.
    """
    stacked: dict[str, list[int]] = {candidate.label: [] for candidate in candidates}
    usable = set(stacked)
    for endpoint in endpoints:
        path_data = path_provider(prime, jet_order, endpoint)
        dlogs, _ = candidate_dlog_jets(candidates, path_data)
        by_label = {candidate.label: dlog for candidate, dlog in dlogs}
        usable.intersection_update(by_label)
        for label in stacked:
            if label in by_label:
                stacked[label].extend(by_label[label])
    ordered = sorted(
        (candidate for candidate in candidates if candidate.label in usable),
        key=lambda candidate: (
            sp.count_ops(candidate.expression),
            len(candidate.label),
            candidate.label,
        ),
    )
    selected_indices, _ = select_column_basis(
        [stacked[candidate.label] for candidate in ordered], prime
    )
    basis = [ordered[index] for index in selected_indices]
    combined_indices, _ = select_column_basis(
        [stacked[candidate.label] for candidate in basis]
        + [stacked[candidate.label] for candidate in candidates if candidate.label in usable],
        prime,
    )
    if any(index >= len(basis) for index in combined_indices):
        raise ValueError("low-complexity basis does not span the source alphabet")
    return [candidate.label for candidate in basis]


def polynomial_trim(polynomial: Sequence[int], prime: int) -> list[int]:
    result = [coefficient % prime for coefficient in polynomial]
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    return result or [0]


def polynomial_divmod(
    numerator: Sequence[int], denominator: Sequence[int], prime: int
) -> tuple[list[int], list[int]]:
    numerator_work = polynomial_trim(numerator, prime)
    denominator_work = polynomial_trim(denominator, prime)
    if denominator_work == [0]:
        raise ZeroDivisionError("zero polynomial")
    if len(numerator_work) < len(denominator_work):
        return [0], numerator_work
    quotient = [0] * (len(numerator_work) - len(denominator_work) + 1)
    inverse_lead = inv_mod(denominator_work[-1], prime)
    while numerator_work != [0] and len(numerator_work) >= len(denominator_work):
        shift = len(numerator_work) - len(denominator_work)
        coefficient = numerator_work[-1] * inverse_lead % prime
        quotient[shift] = coefficient
        for index, value in enumerate(denominator_work):
            numerator_work[index + shift] = (
                numerator_work[index + shift] - coefficient * value
            ) % prime
        numerator_work = polynomial_trim(numerator_work, prime)
    return polynomial_trim(quotient, prime), numerator_work


def polynomial_gcd(
    left: Sequence[int], right: Sequence[int], prime: int
) -> list[int]:
    left_work = polynomial_trim(left, prime)
    right_work = polynomial_trim(right, prime)
    while right_work != [0]:
        _, remainder = polynomial_divmod(left_work, right_work, prime)
        left_work, right_work = right_work, remainder
    if left_work == [0]:
        return [0]
    scale = inv_mod(left_work[-1], prime)
    return [(entry * scale) % prime for entry in left_work]


def polynomial_lcm(
    left: Sequence[int], right: Sequence[int], prime: int
) -> list[int]:
    if polynomial_trim(left, prime) == [0] or polynomial_trim(right, prime) == [0]:
        return [0]
    gcd = polynomial_gcd(left, right, prime)
    quotient, remainder = polynomial_divmod(left, gcd, prime)
    if remainder != [0]:
        raise AssertionError("polynomial gcd did not divide")
    product = [0] * (len(quotient) + len(right) - 1)
    for i, first in enumerate(quotient):
        for j, second in enumerate(right):
            product[i + j] = (product[i + j] + first * second) % prime
    product = polynomial_trim(product, prime)
    scale = inv_mod(product[0], prime)
    return [(entry * scale) % prime for entry in product]


def berlekamp_massey(sequence: Sequence[int], prime: int) -> list[int]:
    """Return Q with Q(0)=1 for the minimal rational-series recurrence."""
    connection = [1]
    previous = [1]
    linear_complexity = 0
    shift = 1
    previous_discrepancy = 1
    for index in range(len(sequence)):
        discrepancy = sequence[index] % prime
        for degree in range(1, linear_complexity + 1):
            if degree < len(connection):
                discrepancy = (
                    discrepancy + connection[degree] * sequence[index - degree]
                ) % prime
        if discrepancy == 0:
            shift += 1
            continue
        saved = connection[:]
        scale = discrepancy * inv_mod(previous_discrepancy, prime) % prime
        required = len(previous) + shift
        if len(connection) < required:
            connection.extend([0] * (required - len(connection)))
        for degree, value in enumerate(previous):
            connection[degree + shift] = (
                connection[degree + shift] - scale * value
            ) % prime
        if 2 * linear_complexity <= index:
            linear_complexity = index + 1 - linear_complexity
            previous = saved
            previous_discrepancy = discrepancy
            shift = 1
        else:
            shift += 1
    return polynomial_trim(connection[: linear_complexity + 1], prime)


def rational_series_profile(sequence: Sequence[int], prime: int) -> dict[str, object]:
    denominator = berlekamp_massey(sequence, prime)
    numerator = [
        sum(
            denominator[k] * sequence[degree - k]
            for k in range(min(degree, len(denominator) - 1) + 1)
        )
        % prime
        for degree in range(len(sequence))
    ]
    numerator = polynomial_trim(numerator[: max(1, len(denominator) - 1)], prime)
    derivative = [
        degree * denominator[degree] % prime
        for degree in range(1, len(denominator))
    ] or [0]
    repeated = polynomial_gcd(denominator, derivative, prime)
    valid = True
    degree = len(denominator) - 1
    for index in range(degree, len(sequence)):
        if sum(
            denominator[k] * sequence[index - k]
            for k in range(len(denominator))
        ) % prime:
            valid = False
            break
    return {
        "denominator": denominator,
        "denominator_degree": degree,
        "numerator_degree": -1 if numerator == [0] else len(numerator) - 1,
        "repeated_gcd_degree": len(repeated) - 1,
        "recurrence_valid": valid,
        "determined_by_jet_count": 2 * degree < len(sequence),
    }


def factor_polynomial_mod(polynomial: Sequence[int], prime: int) -> list[dict[str, object]]:
    tau = sp.symbols("tau")
    expression = sum(
        int(coefficient) * tau**degree
        for degree, coefficient in enumerate(polynomial)
    )
    _, factors = sp.factor_list(expression, tau, modulus=prime)
    result = []
    for factor, multiplicity in factors:
        poly = sp.Poly(factor, tau, modulus=prime)
        coefficients_high = [int(value) % prime for value in poly.all_coeffs()]
        result.append(
            {
                "degree": poly.degree(),
                "multiplicity": int(multiplicity),
                "coefficients": list(reversed(coefficients_high)),
            }
        )
    return result


@dataclass
class PrimeResidues:
    prime: int
    basis_labels: list[str]
    entries: list[tuple[int, int]]
    residues: dict[int, list[list[int]]]
    timings: dict[str, float]
    native: dict[str, float | int]
    alphabet_statistics: dict[str, int]
    epsilon_validation_failures: int
    span_validation_failures: int
    span_failures_by_order: dict[int, int]
    span_failure_examples: list[dict[str, object]]
    span_denominator_profiles: list[dict[str, object]]
    target_denominator_profiles: list[dict[str, object]]


def solve_path_residues_at_prime(
    *,
    binary: Path,
    preparation: Path,
    selected_rows: Sequence[int],
    path_provider: Callable[[int, int, tuple[Fraction, Fraction]], PathData],
    endpoints: tuple[Fraction, Fraction],
    candidates: Sequence[CandidateLetter],
    prime: int,
    jet_order: int,
    epsilon_orders: Sequence[int],
    epsilon_values: Sequence[int],
    threads: int,
    fixed_basis_labels: Sequence[str] | None = None,
) -> PrimeResidues:
    timings: dict[str, float] = {}
    started = time.perf_counter()
    path_data = path_provider(prime, jet_order, endpoints)
    timings["path_data"] = time.perf_counter() - started
    started = time.perf_counter()
    batch = run_dapj(
        binary,
        preparation,
        path_data,
        epsilon_values,
        set(selected_rows),
        threads,
    )
    timings["native_wall"] = time.perf_counter() - started
    started = time.perf_counter()
    isolated, epsilon_failures = isolate_epsilon_orders(
        batch, epsilon_values, epsilon_orders, prime
    )
    path_orders = pull_back_isolated_orders(isolated, path_data, selected_rows)
    timings["epsilon_isolation_and_pullback"] = time.perf_counter() - started
    started = time.perf_counter()
    dlogs, alphabet_statistics = candidate_dlog_jets(candidates, path_data)
    if fixed_basis_labels is None:
        selected_indices, pivot_rows = select_column_basis(
            [dlog for _, dlog in dlogs], prime
        )
        basis = [dlogs[index] for index in selected_indices]
    else:
        by_label = {candidate.label: (candidate, dlog) for candidate, dlog in dlogs}
        missing = [label for label in fixed_basis_labels if label not in by_label]
        if missing:
            raise ValueError(f"fixed dlog basis unavailable at prime: {missing[:3]}")
        basis = [by_label[label] for label in fixed_basis_labels]
        selected_indices, pivot_rows = select_column_basis(
            [dlog for _, dlog in basis], prime
        )
        if selected_indices != list(range(len(basis))):
            raise ValueError("fixed dlog basis lost rank modulo prime")
    basis_labels = [candidate.label for candidate, _ in basis]
    q_columns = [dlog for _, dlog in basis]
    q_submatrix = [
        [column[row] for column in q_columns] for row in pivot_rows
    ]
    q_inverse = matrix_inverse_mod(q_submatrix, prime)
    timings["alphabet_and_basis"] = time.perf_counter() - started
    started = time.perf_counter()
    entries = [(row, column) for row in selected_rows for column in selected_rows]
    residues: dict[int, list[list[int]]] = {}
    span_failures = 0
    span_failures_by_order = {order: 0 for order in epsilon_orders}
    span_failure_examples: list[dict[str, object]] = []
    span_denominator_classes: dict[tuple[int, ...], dict[str, object]] = {}
    target_denominator_classes: dict[tuple[int, ...], dict[str, object]] = {}
    dlog_denominator = [1]
    if jet_order >= 32:
        for column in q_columns:
            dlog_denominator = polynomial_lcm(
                dlog_denominator, berlekamp_massey(column, prime), prime
            )
    for epsilon_order, matrix in path_orders.items():
        order_residues = [[0] * len(entries) for _ in basis]
        for entry_index, entry in enumerate(entries):
            target = matrix[entry]
            right_hand_side = [target[row] for row in pivot_rows]
            solved = matrix_vector_mod(q_inverse, right_hand_side, prime)
            predicted = [
                sum(column[row] * coefficient for column, coefficient in zip(q_columns, solved))
                % prime
                for row in range(jet_order)
            ]
            if predicted != target:
                span_failures += 1
                span_failures_by_order[epsilon_order] += 1
                if len(span_failure_examples) < 12:
                    first_degree = next(
                        degree
                        for degree, (left, right) in enumerate(zip(predicted, target))
                        if left != right
                    )
                    span_failure_examples.append(
                        {
                            "order": epsilon_order,
                            "entry": entry,
                            "first_degree": first_degree,
                            "target": target[first_degree],
                            "predicted": predicted[first_degree],
                        }
                    )
                if jet_order >= 32:
                    target_profile = rational_series_profile(target, prime)
                    target_key = tuple(target_profile["denominator"])
                    target_class = target_denominator_classes.setdefault(
                        target_key,
                        {"count": 0, "examples": [], "profile": target_profile},
                    )
                    target_class["count"] += 1
                    if len(target_class["examples"]) < 6:
                        target_class["examples"].append(
                            {"order": epsilon_order, "entry": entry}
                        )
                    residual = jet_sub(target, predicted, prime)
                    profile = rational_series_profile(residual, prime)
                    # Subtracting a fitted combination can introduce the
                    # union of every basis denominator.  If 64 jets do not
                    # determine the resulting Padé problem, do not factor an
                    # overfitted degree-32 recurrence.  The direct target
                    # profile below is the reliable discriminator.
                    if profile["determined_by_jet_count"]:
                        denominator_key = tuple(profile["denominator"])
                        denominator_class = span_denominator_classes.setdefault(
                            denominator_key,
                            {
                                "count": 0,
                                "examples": [],
                                "profile": profile,
                            },
                        )
                        denominator_class["count"] += 1
                        if len(denominator_class["examples"]) < 6:
                            denominator_class["examples"].append(
                                {"order": epsilon_order, "entry": entry}
                            )
                continue
            for basis_index, value in enumerate(solved):
                order_residues[basis_index][entry_index] = value
        residues[epsilon_order] = order_residues
    timings["residue_solve"] = time.perf_counter() - started
    denominator_profiles: list[dict[str, object]] = []
    for denominator_key, denominator_class in span_denominator_classes.items():
        missing, remainder = polynomial_divmod(
            list(denominator_key),
            polynomial_gcd(list(denominator_key), dlog_denominator, prime),
            prime,
        )
        enriched = dict(denominator_class)
        enriched["factors"] = factor_polynomial_mod(list(denominator_key), prime)
        enriched["missing_from_dlog_degree"] = len(missing) - 1
        enriched["missing_from_dlog_factors"] = factor_polynomial_mod(missing, prime)
        enriched["dlog_lcm_degree"] = len(dlog_denominator) - 1
        denominator_profiles.append(enriched)
    denominator_profiles.sort(key=lambda item: (-int(item["count"]), str(item["profile"])))
    target_profiles: list[dict[str, object]] = []
    for denominator_key, denominator_class in target_denominator_classes.items():
        common = polynomial_gcd(list(denominator_key), dlog_denominator, prime)
        missing, remainder = polynomial_divmod(
            list(denominator_key), common, prime
        )
        enriched = dict(denominator_class)
        enriched["factors"] = factor_polynomial_mod(list(denominator_key), prime)
        enriched["common_with_dlog_degree"] = len(common) - 1
        enriched["missing_from_dlog_degree"] = len(missing) - 1
        enriched["missing_from_dlog_factors"] = factor_polynomial_mod(missing, prime)
        enriched["dlog_lcm_degree"] = len(dlog_denominator) - 1
        target_profiles.append(enriched)
    target_profiles.sort(key=lambda item: (-int(item["count"]), str(item["profile"])))
    return PrimeResidues(
        prime=prime,
        basis_labels=basis_labels,
        entries=entries,
        residues=residues,
        timings=timings,
        native={
            "wall_seconds": batch.wall_seconds,
            "parse_seconds": batch.parse_seconds,
            "evaluation_seconds": batch.evaluation_seconds,
            "term_count": batch.term_count,
            "unique_expression_count": batch.unique_expression_count,
            "threads": threads,
        },
        alphabet_statistics=alphabet_statistics,
        epsilon_validation_failures=epsilon_failures,
        span_validation_failures=span_failures,
        span_failures_by_order=span_failures_by_order,
        span_failure_examples=span_failure_examples,
        span_denominator_profiles=denominator_profiles,
        target_denominator_profiles=target_profiles,
    )


def crt_pair(left: int, left_modulus: int, right: int, right_modulus: int) -> int:
    multiplier = (right - left) % right_modulus
    multiplier = multiplier * inv_mod(left_modulus, right_modulus) % right_modulus
    return left + left_modulus * multiplier


def rational_reconstruct(value: int, modulus: int) -> Fraction | None:
    value %= modulus
    bound = math.isqrt(modulus // 2)
    old_remainder, remainder = modulus, value
    old_denominator, denominator = 0, 1
    while remainder > bound:
        quotient = old_remainder // remainder
        old_remainder, remainder = remainder, old_remainder - quotient * remainder
        old_denominator, denominator = (
            denominator,
            old_denominator - quotient * denominator,
        )
    numerator = remainder
    if denominator < 0:
        numerator = -numerator
        denominator = -denominator
    if (
        denominator == 0
        or abs(numerator) > bound
        or denominator > bound
        or math.gcd(numerator, denominator) != 1
        or (value * denominator - numerator) % modulus
    ):
        return None
    return Fraction(numerator, denominator)


def combine_prime_residues(
    runs: Sequence[PrimeResidues], epsilon_orders: Sequence[int]
) -> tuple[int, dict[int, list[list[Fraction | None]]]]:
    if not runs:
        raise ValueError("no prime runs")
    reference = runs[0]
    for run in runs[1:]:
        if run.basis_labels != reference.basis_labels or run.entries != reference.entries:
            raise ValueError("incompatible prime residue layouts")
    modulus = runs[0].prime
    combined = {
        order: [list(row) for row in runs[0].residues[order]]
        for order in epsilon_orders
    }
    for run in runs[1:]:
        for order in epsilon_orders:
            for basis_index in range(len(reference.basis_labels)):
                combined[order][basis_index] = [
                    crt_pair(left, modulus, right, run.prime)
                    for left, right in zip(
                        combined[order][basis_index],
                        run.residues[order][basis_index],
                    )
                ]
        modulus *= run.prime
    reconstructed = {
        order: [
            [rational_reconstruct(value, modulus) for value in row]
            for row in combined[order]
        ]
        for order in epsilon_orders
    }
    return modulus, reconstructed


def validate_reconstruction(
    reconstructed: dict[int, list[list[Fraction | None]]],
    validation: PrimeResidues,
    epsilon_orders: Sequence[int],
) -> tuple[int, list[dict[str, object]]]:
    failures: list[dict[str, object]] = []
    checked = 0
    for order in epsilon_orders:
        for basis_index, exact_row in enumerate(reconstructed[order]):
            for entry_index, exact in enumerate(exact_row):
                if exact is None:
                    failures.append(
                        {
                            "kind": "reconstruction",
                            "order": order,
                            "basis": basis_index,
                            "entry": validation.entries[entry_index],
                        }
                    )
                    continue
                checked += 1
                if fraction_mod(exact, validation.prime) != validation.residues[order][basis_index][entry_index]:
                    failures.append(
                        {
                            "kind": "fresh_prime",
                            "order": order,
                            "basis": basis_index,
                            "entry": validation.entries[entry_index],
                            "exact": [exact.numerator, exact.denominator],
                        }
                    )
    return checked, failures


def sparse_artifact(
    runs: Sequence[PrimeResidues],
    validation: PrimeResidues,
    reconstructed: dict[int, list[list[Fraction | None]]],
    modulus: int,
    epsilon_orders: Sequence[int],
    endpoints: tuple[Fraction, Fraction],
    validation_endpoints: tuple[Fraction, Fraction],
    jet_order: int,
    checked: int,
    failures: Sequence[dict[str, object]],
    parse_statistics: dict[str, int],
) -> dict[str, object]:
    reference = runs[0]
    residues: dict[str, list[dict[str, object]]] = {}
    for order in epsilon_orders:
        records: list[dict[str, object]] = []
        for basis_index, matrix in enumerate(reconstructed[order]):
            nonzero = []
            unresolved = 0
            for entry, value in zip(reference.entries, matrix):
                if value is None:
                    unresolved += 1
                elif value:
                    nonzero.append(
                        [entry[0], entry[1], value.numerator, value.denominator]
                    )
            records.append(
                {
                    "letter_index": basis_index,
                    "nonzero": nonzero,
                    "unresolved": unresolved,
                }
            )
        residues[str(order)] = records
    return {
        "status": "NativePathDLogResiduesAcceptedV1" if not failures else "NativePathDLogResiduesFailedV1",
        "claim": (
            "Constant residue matrices for the selected connection on the declared path, "
            "in a modularly independent subset of the caller-supplied source letters."
        ),
        "selected_rows": list(sorted(set(row for entry in reference.entries for row in entry))),
        "matrix_dimension": int(math.isqrt(len(reference.entries))),
        "epsilon_orders": list(epsilon_orders),
        "jet_order": jet_order,
        "path_endpoints": [[value.numerator, value.denominator] for value in endpoints],
        "validation_endpoints": [
            [value.numerator, value.denominator] for value in validation_endpoints
        ],
        "basis_letters": reference.basis_labels,
        "basis_rank": len(reference.basis_labels),
        "construction_primes": [run.prime for run in runs],
        "validation_prime": validation.prime,
        "crt_modulus_bits": modulus.bit_length(),
        "validated_coordinates": checked,
        "validation_failures": list(failures[:20]),
        "parse_statistics": parse_statistics,
        "prime_runs": [
            {
                "prime": run.prime,
                "timings": run.timings,
                "native": run.native,
                "alphabet_statistics": run.alphabet_statistics,
                "epsilon_validation_failures": run.epsilon_validation_failures,
                "span_validation_failures": run.span_validation_failures,
                "span_failures_by_order": run.span_failures_by_order,
                "span_failure_examples": run.span_failure_examples,
                "span_denominator_profiles": run.span_denominator_profiles,
                "target_denominator_profiles": run.target_denominator_profiles,
            }
            for run in runs
        ],
        "fresh_validation": {
            "prime": validation.prime,
            "timings": validation.timings,
            "native": validation.native,
            "alphabet_statistics": validation.alphabet_statistics,
            "epsilon_validation_failures": validation.epsilon_validation_failures,
            "span_validation_failures": validation.span_validation_failures,
            "span_failures_by_order": validation.span_failures_by_order,
            "span_failure_examples": validation.span_failure_examples,
            "span_denominator_profiles": validation.span_denominator_profiles,
            "target_denominator_profiles": validation.target_denominator_profiles,
        },
        "residues": residues,
    }


def run_cf303(args: argparse.Namespace) -> int:
    # Exact residual-sheet parity removes blocks 15, 17, 21 and 25.  The
    # remaining 21 blocks form the maximal downward-closed rational subsystem
    # (37 masters).  The earlier 23-block guess omitted only 21/25 and was
    # disproved by native deck conjugation on 2026-08-31.
    selected_rows = (
        list(range(1, 23))
        + [26, 27]
        + list(range(29, 37))
        + list(range(39, 44))
    )
    epsilon_orders = [0, 1]
    epsilon_values = [1, 2, 5]
    # Preferred GPL path: chart p is fixed and u runs from 1/2 to target.
    # The two tuples are independent rational chart targets, not source-path
    # endpoints.  Changing p as well as u makes the final check stronger than
    # a second expansion point on the construction curve.
    endpoints = (Fraction(4, 11), Fraction(5, 7))
    validation_endpoints = (Fraction(7, 11), Fraction(7, 13))
    construction_candidates = [
        2305843009213691819,
        2305843009213641971,
        2305843009213592059,
        2305843009213693921,
        2305843009213686869,
        2305843009213685831,
        2305843009213684819,
        2305843009213683769,
        2305843009213682761,
        2305843009213678507,
        2305843009213675439,
    ]
    validation_prime = 2305843009213693613
    started = time.perf_counter()
    raw_candidates = source_alphabet_texts(args.state)
    candidates, parse_statistics = parse_rationalized_candidates(raw_candidates)
    print(
        "ALPHABET",
        json.dumps(parse_statistics, sort_keys=True),
        flush=True,
    )
    preferred_basis_labels = None
    cache_tag = "v1"
    if args.basis_mode == "low-complexity":
        preferred_basis_labels = select_low_complexity_dlog_basis(
            candidates,
            cf303_kallen2b115_second_axis_data,
            construction_candidates[0],
            [
                endpoints,
                validation_endpoints,
                (Fraction(1, 6), Fraction(3, 7)),
            ],
        )
        cache_tag = "cheapbasis_v1"
        by_label = {candidate.label: candidate for candidate in candidates}
        print(
            "LOW_COMPLEXITY_BASIS",
            json.dumps(
                [
                    {
                        "label": label,
                        "operations": int(sp.count_ops(by_label[label].expression)),
                    }
                    for label in preferred_basis_labels
                ],
                sort_keys=True,
            ),
            flush=True,
        )
    runs: list[PrimeResidues] = []
    cache_directory = args.output.parent / "prime_cache"
    cache_directory.mkdir(parents=True, exist_ok=True)
    lift_history: list[dict[str, object]] = []
    previous_reconstruction = None
    modulus = 1
    reconstructed = None
    for index, prime in enumerate(construction_candidates):
        print(f"PRIME {index + 1}/{len(construction_candidates)} p={prime}", flush=True)
        cache_file = cache_directory / (
            f"selected21_p{prime}_j{args.jet_order}_p4d11_u5d7_{cache_tag}.pkl"
        )
        if cache_file.exists():
            with cache_file.open("rb") as stream:
                run = pickle.load(stream)
            print(f"PRIME_CACHE {cache_file}", flush=True)
        else:
            run = solve_path_residues_at_prime(
                binary=args.binary,
                preparation=args.preparation,
                selected_rows=selected_rows,
                path_provider=cf303_kallen2b115_second_axis_data,
                endpoints=endpoints,
                candidates=candidates,
                prime=prime,
                jet_order=args.jet_order,
                epsilon_orders=epsilon_orders,
                epsilon_values=epsilon_values,
                threads=args.threads,
                fixed_basis_labels=(
                    preferred_basis_labels if index == 0 else runs[0].basis_labels
                ),
            )
            with cache_file.open("wb") as stream:
                pickle.dump(run, stream, protocol=pickle.HIGHEST_PROTOCOL)
        print(
            "PRIME_RESULT",
            json.dumps(
                {
                    "prime": prime,
                    "rank": len(run.basis_labels),
                    "timings": run.timings,
                    "native": run.native,
                    "epsilon_failures": run.epsilon_validation_failures,
                    "span_failures": run.span_validation_failures,
                    "span_failures_by_order": run.span_failures_by_order,
                    "span_failure_examples": run.span_failure_examples,
                    "span_denominator_profiles": run.span_denominator_profiles,
                    "target_denominator_profiles": run.target_denominator_profiles,
                },
                sort_keys=True,
            ),
            flush=True,
        )
        if run.epsilon_validation_failures or run.span_validation_failures:
            raise RuntimeError("construction prime failed mathematical validation")
        runs.append(run)
        if len(runs) < 2:
            continue
        modulus, reconstructed = combine_prime_residues(runs, epsilon_orders)
        flattened = [
            value
            for order in epsilon_orders
            for matrix in reconstructed[order]
            for value in matrix
        ]
        unresolved = sum(value is None for value in flattened)
        resolved = [value for value in flattened if value is not None]
        maximum_numerator_bits = max(
            (abs(value.numerator).bit_length() for value in resolved), default=0
        )
        maximum_denominator_bits = max(
            (value.denominator.bit_length() for value in resolved), default=0
        )
        stable = (
            previous_reconstruction is not None
            and previous_reconstruction == reconstructed
        )
        lift_step = {
            "prime_count": len(runs),
            "modulus_bits": modulus.bit_length(),
            "unresolved": unresolved,
            "stable_from_previous": stable,
            "maximum_numerator_bits": maximum_numerator_bits,
            "maximum_denominator_bits": maximum_denominator_bits,
        }
        lift_history.append(lift_step)
        print("LIFT", json.dumps(lift_step, sort_keys=True), flush=True)
        if unresolved == 0 and stable:
            break
        previous_reconstruction = reconstructed
    if reconstructed is None:
        raise RuntimeError("not enough construction primes")
    final_flattened = [
        value
        for order in epsilon_orders
        for matrix in reconstructed[order]
        for value in matrix
    ]
    if any(value is None for value in final_flattened):
        raise RuntimeError("construction prime budget exhausted before reconstruction")
    print(f"VALIDATE p={validation_prime} segment={validation_endpoints}", flush=True)
    validation = solve_path_residues_at_prime(
        binary=args.binary,
        preparation=args.preparation,
        selected_rows=selected_rows,
        path_provider=cf303_kallen2b115_second_axis_data,
        endpoints=validation_endpoints,
        candidates=candidates,
        prime=validation_prime,
        jet_order=args.jet_order,
        epsilon_orders=epsilon_orders,
        epsilon_values=epsilon_values,
        threads=args.threads,
        fixed_basis_labels=runs[0].basis_labels,
    )
    checked, failures = validate_reconstruction(
        reconstructed, validation, epsilon_orders
    )
    artifact = sparse_artifact(
        runs,
        validation,
        reconstructed,
        modulus,
        epsilon_orders,
        endpoints,
        validation_endpoints,
        args.jet_order,
        checked,
        failures,
        parse_statistics,
    )
    artifact["lift_history"] = lift_history
    artifact["maximum_numerator_bits"] = max(
        abs(value.numerator).bit_length() for value in final_flattened
    )
    artifact["maximum_denominator_bits"] = max(
        value.denominator.bit_length() for value in final_flattened
    )
    artifact["wall_seconds"] = time.perf_counter() - started
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(artifact, indent=2, sort_keys=True) + "\n")
    summary = {
        key: artifact[key]
        for key in (
            "status",
            "basis_rank",
            "construction_primes",
            "validation_prime",
            "crt_modulus_bits",
            "validated_coordinates",
            "wall_seconds",
        )
    }
    summary["validation_failure_count"] = len(failures)
    summary["output"] = str(args.output)
    print("FINAL", json.dumps(summary, sort_keys=True), flush=True)
    return 0 if artifact["status"] == "NativePathDLogResiduesAcceptedV1" else 2


def parse_arguments() -> argparse.Namespace:
    bundle = Path(__file__).resolve().parent
    repository = bundle.parents[5]
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--binary",
        type=Path,
        default=repository / "FeynFacet/Backends/flint/bin/flint_deferred_path_jet",
    )
    parser.add_argument(
        "--preparation",
        type=Path,
        default=bundle / "SourceConnectionDeferredInputNotBundled.wl",
    )
    parser.add_argument(
        "--state",
        type=Path,
        default=bundle / "SectorStateInputNotBundled.wl",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=bundle / "cf303_selected21_residues.json",
    )
    parser.add_argument("--threads", type=int, default=6)
    parser.add_argument("--jet-order", type=int, default=64)
    parser.add_argument(
        "--basis-mode",
        choices=("metadata", "low-complexity"),
        default="metadata",
    )
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(run_cf303(parse_arguments()))
