#!/usr/bin/env python3
"""Exact generic-point test of pre-transport Laurent constraints.

The stored family is in an exact epsilon form dF = eps R F.  We retain the
finite set of Laurent coefficients of F that can enter forbidden coefficients
of I = TTotal F, build their lifted differential system, and compute the
smallest dual differential space containing those forbidden coefficients.

All arithmetic is rational.  Kinematics are specialized to several regular
rational points only to determine generic ranks; this script does not evaluate
the master integrals numerically.
"""

from __future__ import annotations

import argparse
import json
import math
import time
from itertools import product
from pathlib import Path

import numpy as np
from mathics.core.load_builtin import import_and_load_builtins
from mathics.session import MathicsSession
import sympy as sp
from sympy.polys.matrices import DomainMatrix
from sympy.printing.mathematica import mathematica_code


ROOT = Path("/home/maxzhang/factorization-and-loops")
DATA = ROOT / "ppHX_NNLO_DoubleReal" / "Results" / "UU_08_10_canonical"
OUTPUT = ROOT / "Codex" / "ppHX_NNLO_DoubleReal" / "TransportProjection_2026-08-17"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("family", nargs="?", default="CF26")
    parser.add_argument("--max-closure-steps", type=int, default=12)
    parser.add_argument("--target-first", type=sp.Rational, default=sp.Rational(2, 7))
    parser.add_argument("--target-second", type=sp.Rational, default=sp.Rational(3, 11))
    parser.add_argument("--word-count", action="store_true")
    parser.add_argument(
        "--exact-reachable",
        action="store_true",
        help="prove the demanded map on each exact-weight reachable space",
    )
    parser.add_argument(
        "--observable-words",
        action="store_true",
        help="write only the demanded physical dlog words after valuation",
    )
    parser.add_argument(
        "--spectator-system",
        action="store_true",
        help="derive the exact connection induced on the constrained boundary coordinates",
    )
    parser.add_argument(
        "--symbolic-second",
        action="store_true",
        help="retain the spectator variable in the Laurent constraints",
    )
    parser.add_argument("--max-weight", type=int, default=5)
    parser.add_argument("--physical-top", type=int, default=2)
    parser.add_argument(
        "--rows",
        default="",
        help="comma-separated one-based physical rows; empty means every row",
    )
    return parser.parse_args()


def matrix_from_mathics(value) -> sp.Matrix:
    return sp.Matrix([[entry.to_sympy() for entry in row.elements] for row in value.elements])


def clean_symbols(expr, old_variables, old_eps, variables, eps):
    rules = dict(zip(old_variables, variables))
    rules[old_eps] = eps
    if isinstance(expr, sp.MatrixBase):
        return expr.xreplace(rules)
    return expr.xreplace(rules)


def wolfram_display_symbol(symbol: sp.Symbol) -> sp.Symbol:
    name = str(symbol)
    for prefix in ("_uGlobal_", "Global`"):
        if name.startswith(prefix):
            name = name[len(prefix):]
    return sp.Symbol(name)


def epsilon_order(expr: sp.Expr, eps: sp.Symbol) -> int | float:
    if expr == 0:
        return math.inf
    num, den = sp.fraction(sp.cancel(expr))
    numerator = sp.Poly(num, eps)
    denominator = sp.Poly(den, eps)
    nmin = min(power[0] for power in numerator.monoms())
    dmin = min(power[0] for power in denominator.monoms())
    return nmin - dmin


def laurent_matrices(matrix: sp.Matrix, eps: sp.Symbol, rmin: int, rmax: int):
    output = {r: sp.zeros(*matrix.shape) for r in range(rmin, rmax + 1)}
    for i in range(matrix.rows):
        for j in range(matrix.cols):
            entry = matrix[i, j]
            if entry == 0:
                continue
            series = sp.series(entry, eps, 0, rmax + 1).removeO().expand()
            for r in range(rmin, rmax + 1):
                coefficient = series.coeff(eps, r)
                if coefficient != 0:
                    output[r][i, j] = sp.cancel(coefficient)
    return output


def independent_rows_at(matrix: sp.Matrix, rules):
    if matrix.rows == 0:
        return [], 0
    evaluated = matrix.subs(rules)
    if any(entry.has(sp.zoo, sp.nan, sp.oo, -sp.oo) for entry in evaluated):
        raise ValueError(f"singular rank sample {rules}")
    _, pivots = evaluated.T.rref(simplify=False)
    return list(pivots), len(pivots)


def cancel_nonzero(matrix: sp.Matrix) -> sp.Matrix:
    return matrix.applyfunc(lambda entry: 0 if entry == 0 else sp.cancel(entry))


def rational_function_nullspace(matrix: sp.Matrix) -> sp.Matrix:
    domain_matrix = DomainMatrix.from_Matrix(matrix).to_field()
    reduced, pivots = domain_matrix.rref(method="GJ")
    reduced = reduced.to_Matrix()
    free_columns = [
        column for column in range(matrix.cols) if column not in pivots
    ]
    kernel = sp.MutableSparseMatrix(matrix.cols, len(free_columns), {})
    for free_index, free_column in enumerate(free_columns):
        kernel[free_column, free_index] = 1
        for pivot_row, pivot_column in enumerate(pivots):
            value = reduced[pivot_row, free_column]
            if value != 0:
                kernel[pivot_column, free_index] = -value
    return sp.Matrix(kernel)


def rational_function_column_basis(matrix: sp.Matrix) -> sp.Matrix:
    if matrix.cols == 0 or not any(value != 0 for value in matrix):
        return sp.zeros(matrix.rows, 0)
    domain_matrix = DomainMatrix.from_Matrix(matrix).to_field()
    _, pivots = domain_matrix.rref(method="GJ")
    return matrix[:, list(pivots)]


def rational_function_row_basis(matrix: sp.Matrix) -> sp.Matrix:
    if matrix.rows == 0 or not any(value != 0 for value in matrix):
        return sp.zeros(0, matrix.cols)
    return rational_function_column_basis(matrix.T).T


def compressed_row_union(matrices, columns: int, chunk_size: int = 16) -> sp.Matrix:
    """Accumulate an exact row space while keeping intermediate row counts small."""
    basis = sp.zeros(0, columns)
    chunk = []
    for matrix in matrices:
        if matrix.rows:
            chunk.append(matrix)
        if len(chunk) >= chunk_size:
            basis = rational_function_row_basis(sp.Matrix.vstack(basis, *chunk))
            chunk = []
    if chunk:
        basis = rational_function_row_basis(sp.Matrix.vstack(basis, *chunk))
    return basis


def exact_zero_matrix(matrix: sp.Matrix) -> bool:
    return all(sp.cancel(value) == 0 for value in matrix)


def identity_pivot_rows(matrix: sp.Matrix) -> list[int]:
    """Find rows that form the identity on the columns of a kernel matrix."""
    rows = []
    for column in range(matrix.cols):
        expected = [sp.S.Zero] * matrix.cols
        expected[column] = sp.S.One
        row = next(
            (
                index
                for index in range(matrix.rows)
                if all(matrix[index, j] == expected[j] for j in range(matrix.cols))
            ),
            None,
        )
        if row is None:
            raise ValueError(f"kernel column {column + 1} has no identity pivot row")
        rows.append(row)
    if len(set(rows)) != matrix.cols:
        raise ValueError("kernel identity pivot rows are not distinct")
    return rows


def rational_order_at(expr: sp.Expr, variable: sp.Symbol, point=sp.S.Zero) -> int:
    """Return the zero order (negative for a pole) of a rational function."""
    if expr == 0:
        return 10**9
    shifted = sp.cancel(expr.subs(variable, variable + point))
    numerator, denominator = sp.fraction(shifted)

    def polynomial_order(polynomial):
        poly = sp.Poly(polynomial, variable)
        return min(power[0] for power in poly.monoms())

    return polynomial_order(numerator) - polynomial_order(denominator)


def rational_kernel_decomposition(matrix: sp.Matrix, variable: sp.Symbol):
    """Write a one-variable Fuchsian matrix as constant matrices times kernels."""
    coefficients = {}
    shape = matrix.shape

    for row in range(matrix.rows):
        for column in range(matrix.cols):
            entry = matrix[row, column]
            if entry == 0:
                continue
            for term in sp.Add.make_args(sp.apart(entry, variable)):
                numerator, denominator = sp.fraction(term)
                denominator_poly = sp.Poly(denominator, variable)
                denominator_degree = denominator_poly.degree()
                if denominator_degree == 0:
                    if sp.cancel(term) != 0:
                        raise ValueError(
                            "spectator connection has a polynomial part"
                        )
                    continue
                denominator_lc = denominator_poly.LC()
                monic_denominator = sp.expand(denominator / denominator_lc)
                normalized_numerator = sp.expand(numerator / denominator_lc)
                numerator_poly = sp.Poly(normalized_numerator, variable)
                if numerator_poly.degree() >= denominator_degree:
                    raise ValueError(
                        "spectator partial fraction is not proper"
                    )
                for (power,), coefficient in numerator_poly.terms():
                    if coefficient == 0:
                        continue
                    if coefficient.has(variable):
                        raise ValueError(
                            "spectator kernel coefficient depends on its variable"
                        )
                    key = (sp.factor(monic_denominator), power)
                    coefficient_matrix = coefficients.setdefault(
                        key, sp.MutableSparseMatrix(*shape, {})
                    )
                    coefficient_matrix[row, column] += coefficient

    kernels = []
    matrices = []
    for (denominator, power), coefficient_matrix in sorted(
        coefficients.items(), key=lambda item: (str(item[0][0]), item[0][1])
    ):
        kernels.append(variable**power / denominator)
        matrices.append(sp.SparseMatrix(coefficient_matrix))

    reconstructed = sp.zeros(*shape)
    for kernel, coefficient_matrix in zip(kernels, matrices):
        reconstructed += kernel * coefficient_matrix
    if not exact_zero_matrix(cancel_nonzero(matrix - reconstructed)):
        raise ValueError("spectator kernel decomposition failed exactly")
    return kernels, matrices


def mathematica_matrix(matrix: sp.Matrix, substitutions=None) -> str:
    substitutions = substitutions or {}
    rows = []
    for row in range(matrix.rows):
        entries = [
            mathematica_code(matrix[row, column].xreplace(substitutions))
            for column in range(matrix.cols)
        ]
        rows.append("{" + ", ".join(entries) + "}")
    return "{" + ",\n  ".join(rows) + "}"


def mathematica_sparse_entries(matrix: sp.Matrix, substitutions=None) -> str:
    substitutions = substitutions or {}
    entries = []
    for row in range(matrix.rows):
        for column in range(matrix.cols):
            value = matrix[row, column]
            if value != 0:
                entries.append(
                    "{" + ", ".join(
                        (
                            str(row + 1),
                            str(column + 1),
                            mathematica_code(
                                sp.cancel(value).xreplace(substitutions)
                            ),
                        )
                    ) + "}"
                )
    return "{" + ",\n    ".join(entries) + "}"


def observable_word_maps(
    residues,
    boundary: sp.Matrix,
    demanded: sp.Matrix,
    max_weight: int,
):
    """Return sparse demanded maps without constructing undemanded solutions."""
    states = {(): boundary}
    maps = []
    state_counts = []
    map_counts = []
    scalar_counts = []

    for weight in range(max_weight + 1):
        state_counts.append(len(states))
        nonzero_maps = 0
        nonzero_scalars = 0
        for word, state in states.items():
            projected = cancel_nonzero(demanded * state)
            if any(value != 0 for value in projected):
                maps.append((word, projected))
                nonzero_maps += 1
                nonzero_scalars += sum(value != 0 for value in projected)
        map_counts.append(nonzero_maps)
        scalar_counts.append(nonzero_scalars)

        if weight == max_weight:
            break
        children = {}
        for word, state in states.items():
            for residue_index, residue in enumerate(residues):
                child = residue * state
                if any(value != 0 for value in child):
                    children[(residue_index,) + word] = child
        states = children

    return maps, state_counts, map_counts, scalar_counts


def two_segment_observable_maps(
    first_path_maps,
    spectator_matrices,
    max_total_weight: int,
):
    """Compose only physical first-path maps with the spectator evolution."""
    output = []
    counts = [0] * (max_total_weight + 1)
    scalar_counts = [0] * (max_total_weight + 1)

    for first_word, first_matrix in first_path_maps:
        first_weight = len(first_word)
        if first_weight > max_total_weight:
            continue
        states = {(): sp.SparseMatrix(first_matrix)}
        for second_weight in range(max_total_weight - first_weight + 1):
            total_weight = first_weight + second_weight
            for second_word, matrix in states.items():
                if any(value != 0 for value in matrix):
                    output.append((first_word, second_word, matrix))
                    counts[total_weight] += 1
                    scalar_counts[total_weight] += sum(
                        value != 0 for value in matrix
                    )
            if total_weight == max_total_weight:
                break
            children = {}
            for second_word, matrix in states.items():
                for kernel_index, kernel_matrix in enumerate(
                    spectator_matrices
                ):
                    child = cancel_nonzero(matrix * kernel_matrix)
                    if any(value != 0 for value in child):
                        children[second_word + (kernel_index,)] = (
                            sp.SparseMatrix(child)
                        )
            states = children
            if not states:
                break

    output.sort(
        key=lambda item: (
            len(item[0]) + len(item[1]),
            item[0],
            item[1],
        )
    )
    return output, counts, scalar_counts


def path_pole_expansion(
    letter: sp.Expr,
    z1: sp.Symbol,
    z2: sp.Symbol,
    tau: sp.Symbol,
    base: sp.Rational,
):
    path = base + tau * (z1 - base)
    path_letter = sp.cancel(letter.subs(z1, path))
    numerator, denominator = sp.fraction(path_letter)
    poles = {}
    for polynomial, sign in ((numerator, 1), (denominator, -1)):
        polynomial = sp.Poly(polynomial, tau)
        if polynomial.degree() <= 0:
            continue
        roots = sp.roots(polynomial.as_expr(), tau)
        if sum(roots.values()) != polynomial.degree():
            raise ValueError(
                f"could not split path letter into exact roots: {letter}"
            )
        for root, multiplicity in roots.items():
            root = sp.factor(root)
            poles[root] = poles.get(root, 0) + sign * int(multiplicity)
    poles = {
        root: multiplicity
        for root, multiplicity in poles.items()
        if multiplicity != 0
    }
    kernel = sp.cancel(sp.diff(path_letter, tau) / path_letter)
    reconstructed = sum(
        multiplicity / (tau - root)
        for root, multiplicity in poles.items()
    )
    if sp.cancel(kernel - reconstructed) != 0:
        raise ValueError(f"path-pole reconstruction failed for {letter}")
    return sorted(poles.items(), key=lambda item: sp.default_sort_key(item[0]))


def expand_observable_gpl(observable_maps, pole_expansions):
    gpl_maps = {}
    for word, matrix in observable_maps:
        choices = [pole_expansions[index] for index in word]
        terms = [()] if not choices else product(*choices)
        for term in terms:
            roots = tuple(item[0] for item in term)
            multiplier = math.prod(item[1] for item in term)
            contribution = sp.Integer(multiplier) * matrix.copy()
            if roots in gpl_maps:
                gpl_maps[roots] = gpl_maps[roots] + contribution
            else:
                gpl_maps[roots] = contribution
    output = []
    for word, matrix in gpl_maps.items():
        matrix = cancel_nonzero(matrix)
        if any(value != 0 for value in matrix):
            output.append((word, matrix))
    output.sort(key=lambda item: (len(item[0]), tuple(map(sp.default_sort_key, item[0]))))
    return output


def reconstruct_residues(
    letters,
    connection_x: sp.Matrix,
    connection_y: sp.Matrix,
    z1: sp.Symbol,
    z2: sp.Symbol,
):
    sample_values = (
        (sp.Rational(1, 7), sp.Rational(1, 11)),
        (sp.Rational(2, 7), sp.Rational(2, 11)),
        (sp.Rational(3, 7), sp.Rational(3, 11)),
        (sp.Rational(4, 7), sp.Rational(5, 11)),
        (sp.Rational(5, 7), sp.Rational(7, 11)),
        (sp.Rational(1, 5), sp.Rational(2, 9)),
        (sp.Rational(2, 5), sp.Rational(4, 9)),
    )
    dlogs = [
        (sp.cancel(sp.diff(letter, z1) / letter), sp.cancel(sp.diff(letter, z2) / letter))
        for letter in letters
    ]
    coefficient_rows = []
    connection_rows = []
    for first, second in sample_values:
        rules = {z1: first, z2: second}
        for direction, connection in enumerate((connection_x, connection_y)):
            coefficient_rows.append([entry[direction].subs(rules) for entry in dlogs])
            connection_rows.append([entry.subs(rules) for entry in connection])

    coefficient_matrix = sp.Matrix(coefficient_rows)
    _, letter_pivots = coefficient_matrix.rref(simplify=False)
    coefficient_matrix = coefficient_matrix[:, list(letter_pivots)]
    selected_letters = [letters[index] for index in letter_pivots]
    selected_dlogs = [dlogs[index] for index in letter_pivots]

    _, row_pivots = coefficient_matrix.T.rref(simplify=False)
    row_pivots = list(row_pivots)[: len(selected_letters)]
    square = coefficient_matrix[row_pivots, :]
    sampled_connections = sp.Matrix([connection_rows[index] for index in row_pivots])
    residue_rows = square.inv() * sampled_connections
    residues = [
        sp.Matrix(connection_x.rows, connection_x.cols, list(residue_rows[row, :]))
        for row in range(residue_rows.rows)
    ]

    checks = []
    for first, second in sample_values[:3]:
        rules = {z1: first, z2: second}
        for direction, connection in enumerate((connection_x, connection_y)):
            reconstructed = sp.zeros(connection.rows, connection.cols)
            for dlog, residue in zip(selected_dlogs, residues):
                reconstructed += dlog[direction].subs(rules) * residue
            checks.append(connection.subs(rules) == reconstructed)
    if not all(checks):
        raise ValueError("residue reconstruction failed at an exact rational sample")
    reconstructed_x = sp.zeros(connection_x.rows, connection_x.cols)
    reconstructed_y = sp.zeros(connection_y.rows, connection_y.cols)
    for dlog, residue in zip(selected_dlogs, residues):
        reconstructed_x += dlog[0] * residue
        reconstructed_y += dlog[1] * residue
    if not exact_zero_matrix(connection_x - reconstructed_x):
        raise ValueError("exact x-connection residue reconstruction failed")
    if not exact_zero_matrix(connection_y - reconstructed_y):
        raise ValueError("exact y-connection residue reconstruction failed")
    return selected_letters, residues


def matrix_mod_prime(matrix: sp.Matrix, prime: int) -> np.ndarray:
    result = np.zeros(matrix.shape, dtype=np.int64)
    for i in range(matrix.rows):
        for j in range(matrix.cols):
            value = sp.cancel(matrix[i, j])
            if value == 0:
                continue
            numerator, denominator = value.as_numer_denom()
            if numerator.free_symbols or denominator.free_symbols:
                raise ValueError(f"non-rational modular entry: {value}")
            result[i, j] = (
                int(numerator) % prime
            ) * pow(int(denominator) % prime, -1, prime) % prime
    return result


def sparse_entries(matrix: np.ndarray):
    rows, columns = np.nonzero(matrix)
    return [(int(i), int(j), int(matrix[i, j])) for i, j in zip(rows, columns)]


def sparse_left_multiply(entries, output_rows: int, state: np.ndarray, prime: int):
    result = np.zeros((output_rows, state.shape[1]), dtype=np.int64)
    for i, j, value in entries:
        result[i, :] = (result[i, :] + value * state[j, :]) % prime
    return result


def modular_word_counts(residues, boundary, demanded, max_weight: int, prime: int):
    residue_entries = [sparse_entries(matrix_mod_prime(matrix, prime)) for matrix in residues]
    demanded_entries = sparse_entries(matrix_mod_prime(demanded, prime))
    boundary_mod = matrix_mod_prime(boundary, prime)
    counts = [0] * (max_weight + 1)
    scalar_counts = [0] * (max_weight + 1)
    nonzero_states = [0] * (max_weight + 1)

    def visit(state: np.ndarray, weight: int):
        if np.any(state):
            nonzero_states[weight] += 1
        projected = sparse_left_multiply(
            demanded_entries, demanded.rows, state, prime
        )
        if np.any(projected):
            counts[weight] += 1
            scalar_counts[weight] += int(np.count_nonzero(projected))
        if weight == max_weight:
            return
        for entries in residue_entries:
            child = sparse_left_multiply(entries, boundary.rows, state, prime)
            if np.any(child):
                visit(child, weight + 1)

    visit(boundary_mod, 0)
    return counts, scalar_counts, nonzero_states


def main() -> None:
    args = parse_args()
    started = time.time()
    def progress(label: str) -> None:
        print(f"[{time.time() - started:8.3f} s] {label}", flush=True)

    family = args.family
    record_file = DATA / "FamilyEpsForms" / f"family_epsform_{family}.wl"
    if not record_file.exists():
        raise FileNotFoundError(record_file)

    import_and_load_builtins()
    session = MathicsSession()
    session.evaluate(f'record = Get["{record_file}"]')

    dimension = int(session.evaluate('record["Dim"]').value)
    frame = session.evaluate('record["Frame"]').get_string_value()
    ranges_python = session.evaluate('record["Ranges"]').to_python()
    ranges = [[int(index) - 1 for index in block] for block in ranges_python]

    old_variables_value = session.evaluate('record["Variables"]')
    old_variables = [entry.to_sympy() for entry in old_variables_value.elements]
    old_eps = session.evaluate('record["Regulator"]').to_sympy()
    z1, z2, eps, tau = sp.symbols("z1 z2 eps tau")
    variables = (z1, z2)

    t_total = clean_symbols(
        matrix_from_mathics(session.evaluate('record["TTotal"]')),
        old_variables,
        old_eps,
        variables,
        eps,
    )
    t_inverse = clean_symbols(
        matrix_from_mathics(session.evaluate('record["TTotalInverse"]')),
        old_variables,
        old_eps,
        variables,
        eps,
    )
    ax = clean_symbols(
        matrix_from_mathics(session.evaluate('record["EpsFormX"]')),
        old_variables,
        old_eps,
        variables,
        eps,
    )
    ay = clean_symbols(
        matrix_from_mathics(session.evaluate('record["EpsFormY"]')),
        old_variables,
        old_eps,
        variables,
        eps,
    )
    progress("loaded exact epsilon-form record")

    tmin = min([0] + [epsilon_order(entry, eps) for entry in t_total if entry != 0])
    block_lows = []
    row_lows = [None] * dimension
    for block in ranges:
        orders = [
            epsilon_order(t_inverse[i, j], eps)
            for i in block
            for j in range(dimension)
            if t_inverse[i, j] != 0
        ]
        low = int(min(orders)) if orders else 0
        block_lows.append(low)
        for row in block:
            row_lows[row] = low
    if any(value is None for value in row_lows):
        raise ValueError("record ranges do not cover every transformed master")

    block_of_row = {}
    for block_index, block in enumerate(ranges):
        for row in block:
            block_of_row[row] = block_index

    base_first = sp.Rational(1, 2) if frame == "Chart" else sp.Rational(1, 4)
    path_rules = {
        z1: base_first + tau * (args.target_first - base_first),
        z2: z2 if args.symbolic_second else args.target_second,
    }
    tangent_first = args.target_first - base_first
    connection = cancel_nonzero((ax / eps).subs(path_rules) * tangent_first)
    if any(entry.has(eps) for entry in connection):
        raise ValueError("stored connection is not an exact epsilon form")

    # Source terms can create coefficients below a block's own boundary
    # order.  They are states of the lifted ODE, but their initial values are
    # zero.  This is the same lower-order propagation used by the blockwise
    # recursion for an exact epsilon form.
    propagated_lows = list(block_lows)
    for target_block, target_rows in enumerate(ranges):
        for source_block in range(target_block):
            source_rows = ranges[source_block]
            nonzero = any(
                connection[i, j] != 0
                for i in target_rows
                for j in source_rows
            )
            if nonzero:
                propagated_lows[target_block] = min(
                    propagated_lows[target_block],
                    propagated_lows[source_block] + 1,
                )

    state_row_lows = [propagated_lows[block_of_row[row]] for row in range(dimension)]
    flow = min(propagated_lows)
    fhigh = -1 - int(tmin)
    low_i = flow + int(tmin)
    forbidden_orders = list(range(low_i, 0))

    slots = []
    slot_index = {}
    for order in range(flow, fhigh + 1):
        for component in range(dimension):
            if order >= state_row_lows[component]:
                slot_index[(order, component)] = len(slots)
                slots.append((order, component))
    lifted_dimension = len(slots)

    boundary_slots = []
    boundary_slot_index = {}
    for order, component in slots:
        if order >= row_lows[component]:
            boundary_slot_index[(order, component)] = len(boundary_slots)
            boundary_slots.append((order, component))
    boundary_dimension = len(boundary_slots)
    embedding = sp.MutableSparseMatrix(lifted_dimension, boundary_dimension, {})
    for state_slot, key in enumerate(slots):
        boundary_slot = boundary_slot_index.get(key)
        if boundary_slot is not None:
            embedding[state_slot, boundary_slot] = 1
    embedding = sp.SparseMatrix(embedding)

    lifted = sp.MutableSparseMatrix(lifted_dimension, lifted_dimension, {})
    for (order, component), row in slot_index.items():
        previous = order - 1
        for source in range(dimension):
            column = slot_index.get((previous, source))
            if column is not None and connection[component, source] != 0:
                lifted[row, column] = connection[component, source]
    lifted = sp.SparseMatrix(lifted)

    rmax = max(n - order for n in forbidden_orders for order, _ in slots)
    t_laurent = laurent_matrices(t_total, eps, int(tmin), int(rmax))
    t_laurent = {
        order: cancel_nonzero(matrix.subs(path_rules))
        for order, matrix in t_laurent.items()
    }

    output_rows = []
    output_labels = []
    for physical_order in forbidden_orders:
        for physical_component in range(dimension):
            row = [sp.S.Zero] * lifted_dimension
            for column, (forder, source) in enumerate(slots):
                torder = physical_order - forder
                coefficient_matrix = t_laurent.get(torder)
                if coefficient_matrix is not None:
                    row[column] = coefficient_matrix[physical_component, source]
            if any(entry != 0 for entry in row):
                output_rows.append(row)
                output_labels.append((physical_order, physical_component + 1))
    output = sp.Matrix(output_rows)
    progress("built forbidden-output map")

    rank_samples = (
        {tau: sp.Rational(2, 5), z2: sp.Rational(3, 11)},
        {tau: sp.Rational(3, 5), z2: sp.Rational(4, 13)},
        {tau: sp.Rational(4, 7), z2: sp.Rational(2, 9)},
    )
    pivots, initial_rank = independent_rows_at(output, rank_samples[0])
    basis = output[pivots, :]
    frontier = basis
    rank_history = [initial_rank]
    constraint_matrices = [
        cancel_nonzero(basis.subs(tau, 0) * embedding)
    ]
    boundary_rank_history = [constraint_matrices[0].rank()]
    progress(
        f"initialized dual closure: state rank {initial_rank}, "
        f"constraint rank {boundary_rank_history[0]}"
    )

    for step in range(args.max_closure_steps):
        covariant = frontier.diff(tau) + frontier * lifted
        candidate = sp.Matrix.vstack(basis, covariant)
        pivots, rank = independent_rows_at(candidate, rank_samples[0])
        new_pivots = [pivot for pivot in pivots if pivot >= basis.rows]
        frontier = (
            candidate[new_pivots, :]
            if new_pivots
            else sp.zeros(0, candidate.cols)
        )
        if frontier.rows:
            constraint_matrices.append(
                cancel_nonzero(frontier.subs(tau, 0) * embedding)
            )
        rank_history.append(rank)
        boundary_rank_history.append(sp.Matrix.vstack(*constraint_matrices).rank())
        progress(
            f"dual closure step {step + 1}: state rank {rank}, "
            f"constraint rank {boundary_rank_history[-1]}"
        )
        basis = candidate[pivots, :]
        if not new_pivots:
            break
        if rank == lifted_dimension:
            break

    generic_ranks = []
    for sample in rank_samples:
        _, rank = independent_rows_at(basis, sample)
        generic_ranks.append(rank)

    constraints_at_base = sp.Matrix.vstack(*constraint_matrices)
    progress("assembled boundary constraint matrix")
    constraint_rank_samples = []
    for sample in (sp.Rational(3, 11), sp.Rational(4, 13), sp.Rational(2, 9)):
        constraint_rank_samples.append(constraints_at_base.subs(z2, sample).rank())
    _, base_pivots = constraints_at_base.subs(
        z2, sp.Rational(3, 11)
    ).T.rref(simplify=False)
    progress("selected independent symbolic constraint rows")
    constraints_at_base = constraints_at_base[list(base_pivots), :]
    constraint_rank = len(base_pivots)
    nullity = boundary_dimension - constraint_rank
    if nullity:
        boundary_nullspace = rational_function_nullspace(constraints_at_base)
    else:
        boundary_nullspace = sp.zeros(boundary_dimension, 0)
    progress("computed symbolic boundary nullspace")
    if boundary_nullspace.shape != (boundary_dimension, nullity):
        raise ValueError(
            f"unexpected boundary-kernel shape {boundary_nullspace.shape}"
        )
    if any(
        sp.cancel(value) != 0
        for value in constraints_at_base * boundary_nullspace
    ):
        raise ValueError("exact boundary-kernel certificate is nonzero")

    result = {
        "Family": family,
        "Dimension": dimension,
        "Frame": frame,
        "TTotalMinOrder": int(tmin),
        "BlockLowerOrders": block_lows,
        "PropagatedBlockLowerOrders": propagated_lows,
        "FOrders": [flow, fhigh],
        "ForbiddenPhysicalOrders": forbidden_orders,
        "LiftedDimension": lifted_dimension,
        "BoundaryCoefficientDimension": boundary_dimension,
        "InitialOutputRows": len(output_rows),
        "InitialOutputRank": initial_rank,
        "ClosureStateRankHistory": rank_history,
        "BoundaryConstraintRankHistory": boundary_rank_history,
        "ClosureRanksAtSamples": generic_ranks,
        "ConstraintRanksAtSpectatorSamples": constraint_rank_samples,
        "ConstraintRankAtBase": constraint_rank,
        "AllowedBoundaryDimension": nullity,
        "SymbolicSpectatorVariable": args.symbolic_second,
        "BoundaryNullspaceShape": list(boundary_nullspace.shape),
        "BoundaryNullspaceLeafCount": sum(
            int(sp.count_ops(value)) + 1 for value in boundary_nullspace
        ),
        "TargetPoint": [str(args.target_first), str(args.target_second)],
        "RankSamplePoints": [
            {str(symbol): str(value) for symbol, value in sample.items()}
            for sample in rank_samples
        ],
        "Seconds": round(time.time() - started, 3),
    }

    kernel_file = None
    observable_file = None
    two_segment_file = None
    if args.symbolic_second:
        spectator = wolfram_display_symbol(old_variables[1])
        display_rules = {z2: spectator}
        kernel_file = OUTPUT / f"PreTransportValuationKernel_{family}.wl"
        kernel_record = (
            '<|"Format" -> "PreTransportValuationKernel", '
            '"FormatVersion" -> 1,\n'
            f' "Family" -> "{family}", '
            f'"SpectatorVariable" -> {mathematica_code(spectator)},\n'
            f' "BlockRanges" -> {str([[index + 1 for index in block] for block in ranges]).replace("[", "{").replace("]", "}")},\n'
            f' "BoundarySlots" -> {str([[order, component + 1] for order, component in boundary_slots]).replace("[", "{").replace("]", "}")},\n'
            f' "ConstraintMatrix" -> {mathematica_matrix(constraints_at_base, display_rules)},\n'
            f' "Kernel" -> {mathematica_matrix(boundary_nullspace, display_rules)},\n'
            f' "ConstraintRank" -> {constraint_rank}, '
            f'"Nullity" -> {nullity},\n'
            ' "Certificate" -> True|>\n'
        )
        OUTPUT.mkdir(parents=True, exist_ok=True)
        kernel_file.write_text(kernel_record)

    if args.word_count:
        selected_rows = (
            [int(value) - 1 for value in args.rows.split(",") if value.strip()]
            if args.rows
            else list(range(dimension))
        )
        if any(row < 0 or row >= dimension for row in selected_rows):
            raise ValueError(f"physical row outside 1..{dimension}: {args.rows}")

        word_fhigh = args.physical_top - int(tmin)
        if word_fhigh < fhigh:
            raise ValueError(
                "word-count coefficient range is smaller than the valuation range"
            )

        extended_slots = []
        extended_slot_index = {}
        for order in range(flow, word_fhigh + 1):
            for component in range(dimension):
                if order >= state_row_lows[component]:
                    extended_slot_index[(order, component)] = len(extended_slots)
                    extended_slots.append((order, component))
        extended_dimension = len(extended_slots)

        extended_boundary_slots = [
            key for key in extended_slots if key[0] >= row_lows[key[1]]
        ]
        new_boundary_slots = [
            key for key in extended_boundary_slots if key not in boundary_slot_index
        ]
        constrained_free_dimension = nullity + len(new_boundary_slots)
        constrained_boundary = sp.MutableSparseMatrix(
            extended_dimension, constrained_free_dimension, {}
        )
        for state_row, key in enumerate(extended_slots):
            old_boundary_row = boundary_slot_index.get(key)
            if old_boundary_row is not None:
                for column in range(nullity):
                    value = boundary_nullspace[old_boundary_row, column]
                    if value != 0:
                        constrained_boundary[state_row, column] = value
        for offset, key in enumerate(new_boundary_slots):
            constrained_boundary[
                extended_slot_index[key], nullity + offset
            ] = 1
        constrained_boundary_symbolic = sp.SparseMatrix(constrained_boundary)
        constrained_boundary = constrained_boundary_symbolic
        if args.symbolic_second:
            constrained_boundary = constrained_boundary.subs(
                z2, args.target_second
            )

        unconstrained_boundary = sp.MutableSparseMatrix(
            extended_dimension, len(extended_boundary_slots), {}
        )
        for column, key in enumerate(extended_boundary_slots):
            unconstrained_boundary[extended_slot_index[key], column] = 1
        unconstrained_boundary = sp.SparseMatrix(unconstrained_boundary)

        physical_orders = list(range(0, args.physical_top + 1))
        word_rmax = max(
            physical_order - forder
            for physical_order in physical_orders
            for forder, _ in extended_slots
        )
        word_t_laurent_symbolic = laurent_matrices(
            t_total, eps, int(tmin), int(word_rmax)
        )
        word_t_laurent = {
            order: cancel_nonzero(
                matrix.subs({z1: args.target_first, z2: args.target_second})
            )
            for order, matrix in word_t_laurent_symbolic.items()
        }

        def build_demanded(laurent_coefficients):
            demanded_rows = []
            for physical_order in physical_orders:
                for physical_component in selected_rows:
                    row = [sp.S.Zero] * extended_dimension
                    for column, (forder, source) in enumerate(extended_slots):
                        coefficient_matrix = laurent_coefficients.get(
                            physical_order - forder
                        )
                        if coefficient_matrix is not None:
                            row[column] = coefficient_matrix[
                                physical_component, source
                            ]
                    if any(value != 0 for value in row):
                        demanded_rows.append(row)
            return sp.Matrix(demanded_rows)

        demanded_symbolic = build_demanded(word_t_laurent_symbolic)
        demanded = build_demanded(word_t_laurent)

        letters_value = session.evaluate('record["Letters"]')
        letters = [
            clean_symbols(
                entry.to_sympy(), old_variables, old_eps, variables, eps
            )
            for entry in letters_value.elements
        ]
        selected_letters, residues = reconstruct_residues(
            letters,
            cancel_nonzero(ax / eps),
            cancel_nonzero(ay / eps),
            z1,
            z2,
        )
        lifted_residues = []
        for residue in residues:
            lifted_residue = sp.MutableSparseMatrix(
                extended_dimension, extended_dimension, {}
            )
            for (order, component), row in extended_slot_index.items():
                previous = order - 1
                for source in range(dimension):
                    column = extended_slot_index.get((previous, source))
                    value = residue[component, source]
                    if column is not None and value != 0:
                        lifted_residue[row, column] = value
            lifted_residues.append(sp.SparseMatrix(lifted_residue))

        spectator_system = None
        spectator_kernels = []
        spectator_kernel_matrices = []
        if args.spectator_system:
            if not args.symbolic_second:
                raise ValueError(
                    "--spectator-system requires --symbolic-second"
                )
            progress("starting induced spectator-system calculation")
            spectator_connection = cancel_nonzero(
                (ay / eps).subs(z1, base_first)
            )
            if any(entry.has(eps) for entry in spectator_connection):
                raise ValueError(
                    "spectator connection is not an exact epsilon form"
                )
            lifted_spectator = sp.MutableSparseMatrix(
                extended_dimension, extended_dimension, {}
            )
            for (order, component), row in extended_slot_index.items():
                previous = order - 1
                for source in range(dimension):
                    column = extended_slot_index.get((previous, source))
                    value = spectator_connection[component, source]
                    if column is not None and value != 0:
                        lifted_spectator[row, column] = value
            lifted_spectator = sp.SparseMatrix(lifted_spectator)

            boundary_derivative = constrained_boundary_symbolic.diff(z2)
            induced_rhs = cancel_nonzero(
                lifted_spectator * constrained_boundary_symbolic
                - boundary_derivative
            )
            pivot_rows = identity_pivot_rows(constrained_boundary_symbolic)
            induced_connection = cancel_nonzero(induced_rhs[pivot_rows, :])
            induced_residual = cancel_nonzero(
                constrained_boundary_symbolic * induced_connection
                - induced_rhs
            )
            if not exact_zero_matrix(induced_residual):
                raise ValueError(
                    "constrained boundary subspace is not invariant under "
                    "spectator evolution"
                )

            spectator_kernels, spectator_kernel_matrices = (
                rational_kernel_decomposition(induced_connection, z2)
            )

            nonzero_entries = [
                value for value in induced_connection if value != 0
            ]
            orders_at_zero = [
                rational_order_at(value, z2) for value in nonzero_entries
            ]
            maximum_pole_order = max(
                [0] + [-order for order in orders_at_zero if order < 0]
            )
            residue = None
            residue_rank = None
            if maximum_pole_order <= 1:
                residue = cancel_nonzero(
                    induced_connection.applyfunc(
                        lambda value: sp.limit(z2 * value, z2, 0)
                    )
                )
                residue_rank = residue.rank()

            spectator = wolfram_display_symbol(old_variables[1])
            display_rules = {z2: spectator}
            spectator_file = OUTPUT / f"SpectatorSystem_{family}.wl"
            residue_text = (
                mathematica_sparse_entries(residue, display_rules)
                if residue is not None
                else "Missing[\"NonFuchsianAtZero\"]"
            )
            residue_rank_text = (
                str(residue_rank)
                if residue_rank is not None
                else 'Missing["NonFuchsianAtZero"]'
            )
            spectator_record = (
                '<|"Format" -> "FeynFacetConstrainedSpectatorSystem", '
                '"FormatVersion" -> 1,\n'
                f' "Family" -> "{family}", '
                f'"Variable" -> {mathematica_code(spectator)}, '
                f'"BasePoint" -> 0,\n'
                f' "Shape" -> {{{induced_connection.rows}, '
                f'{induced_connection.cols}}},\n'
                f' "BoundaryCoordinates" -> {constrained_free_dimension}, '
                f'"IdentityPivotRows" -> '
                f'{str([row + 1 for row in pivot_rows]).replace("[", "{").replace("]", "}")},\n'
                ' "LiftedCoordinates" -> '
                + str(
                    [
                        [order, component + 1]
                        for order, component in extended_slots
                    ]
                ).replace("[", "{").replace("]", "}")
                + ',\n'
                f' "BoundaryEmbeddingShape" -> '
                f'{{{constrained_boundary_symbolic.rows}, '
                f'{constrained_boundary_symbolic.cols}}},\n'
                f' "BoundaryEmbeddingEntries" -> '
                f'{mathematica_sparse_entries(constrained_boundary_symbolic, display_rules)},\n'
                f' "ConnectionEntries" -> '
                f'{mathematica_sparse_entries(induced_connection, display_rules)},\n'
                ' "KernelFunctions" -> {'
                + ", ".join(
                    mathematica_code(kernel.xreplace(display_rules))
                    for kernel in spectator_kernels
                )
                + '},\n'
                ' "KernelMatrices" -> {\n  '
                + ",\n  ".join(
                    mathematica_sparse_entries(matrix, display_rules)
                    for matrix in spectator_kernel_matrices
                )
                + '},\n'
                f' "MaximumPoleOrderAtBase" -> {maximum_pole_order},\n'
                f' "ResidueEntries" -> {residue_text},\n'
                f' "ResidueRank" -> {residue_rank_text},\n'
                ' "InvariantSubspaceCertificate" -> True|>\n'
            )
            spectator_file.write_text(spectator_record)
            spectator_system = {
                "Dimension": constrained_free_dimension,
                "NonzeroEntries": len(nonzero_entries),
                "KernelCount": len(spectator_kernels),
                "KernelFunctions": [str(kernel) for kernel in spectator_kernels],
                "MaximumPoleOrderAtBase": maximum_pole_order,
                "ResidueRank": residue_rank,
                "InvariantSubspaceCertificate": True,
                "Record": str(spectator_file),
            }
            progress(
                "certified induced spectator system: "
                f"dimension {constrained_free_dimension}, "
                f"nonzero entries {len(nonzero_entries)}, "
                f"kernels {len(spectator_kernels)}, "
                f"pole order {maximum_pole_order}"
            )

        exact_reachable = None
        if args.exact_reachable:
            if not args.symbolic_second:
                raise ValueError(
                    "--exact-reachable requires --symbolic-second"
                )
            progress("starting exact reachable-subspace certificate")
            reachable = rational_function_column_basis(
                constrained_boundary_symbolic
            )
            reachable_ranks = []
            demanded_zero = []
            demanded_nonzero_entries = []
            for weight in range(args.max_weight + 1):
                reachable_ranks.append(reachable.cols)
                projected = demanded_symbolic * reachable
                zero = exact_zero_matrix(projected)
                demanded_zero.append(zero)
                demanded_nonzero_entries.append(
                    0
                    if zero
                    else sum(sp.cancel(value) != 0 for value in projected)
                )
                progress(
                    f"exact weight {weight}: reachable rank {reachable.cols}, "
                    f"demanded zero {zero}"
                )
                if weight < args.max_weight:
                    candidates = sp.Matrix.hstack(
                        *(residue * reachable for residue in lifted_residues)
                    )
                    reachable = rational_function_column_basis(candidates)
            next_candidates = sp.Matrix.hstack(
                *(residue * reachable for residue in lifted_residues)
            )
            next_zero = not any(value != 0 for value in next_candidates)
            exact_reachable = {
                "ReachableRankByExactWeight": reachable_ranks,
                "DemandedMapIsZero": demanded_zero,
                "DemandedNonzeroEntries": demanded_nonzero_entries,
                "NextWeightStateIsZero": next_zero,
                "Field": "Q(z1,z2)",
            }

        if spectator_system is not None:
            result["SpectatorSystem"] = spectator_system

        primes = (1000003, 1000033)
        word_results = {}
        for name, boundary in (
            ("Unconstrained", unconstrained_boundary),
            ("LaurentConstrained", constrained_boundary),
        ):
            prime_results = []
            for prime in primes:
                sequences, scalars, states = modular_word_counts(
                    lifted_residues,
                    boundary,
                    demanded,
                    args.max_weight,
                    prime,
                )
                prime_results.append(
                    {
                        "Prime": prime,
                        "NonzeroProjectedSequences": sequences,
                        "NonzeroProjectedScalars": scalars,
                        "NonzeroIntermediateSequences": states,
                    }
                )
            if prime_results[0]["NonzeroProjectedSequences"] != prime_results[1]["NonzeroProjectedSequences"] or prime_results[0]["NonzeroProjectedScalars"] != prime_results[1]["NonzeroProjectedScalars"]:
                raise ValueError(
                    f"finite-field word counts disagree for {name}: {prime_results}"
                )
            word_results[name] = prime_results[0]

        observable_summary = None
        if args.observable_words:
            if exact_reachable is None:
                raise ValueError(
                    "--observable-words requires --exact-reachable"
                )
            nonzero_weights = [
                weight
                for weight, zero in enumerate(
                    exact_reachable["DemandedMapIsZero"]
                )
                if not zero
            ]
            transport_weight = max(nonzero_weights, default=0)
            if any(
                not zero
                for zero in exact_reachable["DemandedMapIsZero"][
                    transport_weight + 1:
                ]
            ):
                raise ValueError("non-contiguous exact observable weights")
            progress(
                f"constructing observable-only word maps through weight "
                f"{transport_weight}"
            )
            active_letter_indices = [
                index
                for index, letter in enumerate(selected_letters)
                if sp.diff(letter, z1) != 0
            ]
            active_residues = [
                lifted_residues[index] for index in active_letter_indices
            ]
            observable_maps, state_counts, map_counts, scalar_counts = (
                observable_word_maps(
                    active_residues,
                    constrained_boundary_symbolic,
                    demanded_symbolic,
                    transport_weight,
                )
            )
            path_prime_results = []
            for prime in primes:
                sequences, scalars, states = modular_word_counts(
                    active_residues,
                    constrained_boundary.subs(z2, args.target_second)
                    if args.symbolic_second
                    else constrained_boundary,
                    demanded,
                    transport_weight,
                    prime,
                )
                path_prime_results.append((sequences, scalars, states))
            if path_prime_results[0] != path_prime_results[1]:
                raise ValueError(
                    "path word counts disagree between the two exact primes"
                )
            expected_maps, expected_scalars, _ = path_prime_results[0]
            if map_counts != expected_maps or scalar_counts != expected_scalars:
                raise ValueError(
                    "exact observable word counts disagree with two-prime "
                    f"counts: exact={map_counts, scalar_counts}, "
                    f"modular={expected_maps, expected_scalars}"
                )
            active_path_poles = [
                path_pole_expansion(
                    selected_letters[index], z1, z2, tau, base_first
                )
                for index in active_letter_indices
            ]
            gpl_maps = expand_observable_gpl(
                observable_maps, active_path_poles
            )
            gpl_counts = [
                sum(len(word) == weight for word, _ in gpl_maps)
                for weight in range(transport_weight + 1)
            ]

            two_segment_maps = None
            two_segment_counts = None
            two_segment_scalar_counts = None
            if spectator_kernel_matrices:
                progress("constructing exact two-segment observable maps")
                (
                    two_segment_maps,
                    two_segment_counts,
                    two_segment_scalar_counts,
                ) = two_segment_observable_maps(
                    observable_maps,
                    spectator_kernel_matrices,
                    transport_weight,
                )
                progress(
                    "two-segment maps by total weight: "
                    + str(two_segment_counts)
                )

            original_first, original_second = tuple(
                wolfram_display_symbol(symbol) for symbol in old_variables
            )
            original_eps = wolfram_display_symbol(old_eps)
            display_rules = {z1: original_first, z2: original_second}
            physical_labels = [
                (order, component + 1)
                for order in physical_orders
                for component in selected_rows
            ]
            coordinate_labels = [
                f'BoundaryCoordinate["Kernel", {column + 1}]'
                for column in range(nullity)
            ] + [
                "BoundaryCoordinate[\"Slot\", {"
                + f"{order}, {component + 1}"
                + "}]"
                for order, component in new_boundary_slots
            ]
            map_records = []
            for word, matrix in observable_maps:
                original_word = tuple(
                    active_letter_indices[index] for index in word
                )
                map_records.append(
                    '<|"Weight" -> '
                    + str(len(word))
                    + ', "Word" -> {'
                    + ", ".join(str(index + 1) for index in original_word)
                    + '}, "Entries" -> '
                    + mathematica_sparse_entries(matrix, display_rules)
                    + "|>"
                )
            pole_records = []
            for local_index, poles in enumerate(active_path_poles):
                pole_records.append(
                    '<|"Letter" -> '
                    + str(active_letter_indices[local_index] + 1)
                    + ', "Poles" -> {'
                    + ", ".join(
                        "{" + mathematica_code(root.xreplace(display_rules))
                        + ", " + str(multiplicity) + "}"
                        for root, multiplicity in poles
                    )
                    + "}|>"
                )
            gpl_records = []
            for word, matrix in gpl_maps:
                gpl_records.append(
                    '<|"Weight" -> '
                    + str(len(word))
                    + ', "Word" -> {'
                    + ", ".join(
                        mathematica_code(root.xreplace(display_rules))
                        for root in word
                    )
                    + '}, "Entries" -> '
                    + mathematica_sparse_entries(matrix, display_rules)
                    + "|>"
                )
            observable_file = OUTPUT / f"ObservableTransport_{family}.wl"
            observable_record = (
                '<|"Format" -> "FeynFacetObservableDLogTransport", '
                '"FormatVersion" -> 1,\n'
                f' "Family" -> "{family}", "Frame" -> "{frame}",\n'
                f' "Variables" -> {{{mathematica_code(original_first)}, '
                f'{mathematica_code(original_second)}}}, '
                f'"Regulator" -> {mathematica_code(original_eps)},\n'
                f' "Path" -> <|"Base" -> {{{mathematica_code(base_first)}, '
                f'{mathematica_code(original_second)}}}, '
                f'"Target" -> {{{mathematica_code(original_first)}, '
                f'{mathematica_code(original_second)}}}, '
                '"Parameter" -> tau|>,\n'
                ' "WordConvention" -> "For Word -> {a1,...,ar}, the '
                'iterated differential is dlog(phi_a1) ... dlog(phi_ar) '
                'ordered from outermost to innermost integration",\n'
                ' "DLogLetters" -> {'
                + ", ".join(
                    mathematica_code(letter.xreplace(display_rules))
                    for letter in selected_letters
                )
                + '},\n'
                ' "PathActiveLetters" -> {'
                + ", ".join(str(index + 1) for index in active_letter_indices)
                + '},\n'
                ' "PathPoleExpansion" -> {\n  '
                + ",\n  ".join(pole_records)
                + '},\n'
                ' "PhysicalRows" -> {'
                + ", ".join(
                    "{" + f"{order}, {component}" + "}"
                    for order, component in physical_labels
                )
                + '},\n'
                ' "BoundaryCoordinates" -> {'
                + ", ".join(coordinate_labels)
                + '},\n'
                f' "MaximumWeight" -> {transport_weight},\n'
                ' "ObservableWordMaps" -> {\n  '
                + ",\n  ".join(map_records)
                + '},\n'
                ' "GPLWordMaps" -> {\n  '
                + ",\n  ".join(gpl_records)
                + '},\n'
                ' "Certificate" -> <|'
                '"ExactConnectionReconstruction" -> True, '
                '"ExactPathPoleReconstruction" -> True, '
                '"BoundaryKernel" -> True, '
                '"InitialValue" -> True, '
                '"ExactReachableRanks" -> {'
                + ", ".join(
                    str(value)
                    for value in exact_reachable[
                        "ReachableRankByExactWeight"
                    ]
                )
                + '}, "DemandedMapIsZero" -> {'
                + ", ".join(
                    "True" if value else "False"
                    for value in exact_reachable["DemandedMapIsZero"]
                )
                + '}, "NextWeightStateIsZero" -> '
                + (
                    "True"
                    if exact_reachable["NextWeightStateIsZero"]
                    else "False"
                )
                + '|>|>\n'
            )
            observable_file.write_text(observable_record)

            if two_segment_maps is not None:
                two_segment_records = []
                for first_word, second_word, matrix in two_segment_maps:
                    original_first_word = tuple(
                        active_letter_indices[index] for index in first_word
                    )
                    two_segment_records.append(
                        '<|"TotalWeight" -> '
                        + str(len(first_word) + len(second_word))
                        + ', "FirstPathWord" -> {'
                        + ", ".join(
                            str(index + 1) for index in original_first_word
                        )
                        + '}, "SpectatorPathWord" -> {'
                        + ", ".join(
                            str(index + 1) for index in second_word
                        )
                        + '}, "Entries" -> '
                        + mathematica_sparse_entries(matrix, display_rules)
                        + "|>"
                    )

                two_segment_file = (
                    OUTPUT / f"TwoSegmentObservableTransport_{family}.wl"
                )
                two_segment_record = (
                    '<|"Format" -> "FeynFacetTwoSegmentObservableTransport", '
                    '"FormatVersion" -> 1,\n'
                    f' "Family" -> "{family}", "Frame" -> "{frame}",\n'
                    f' "Variables" -> {{{mathematica_code(original_first)}, '
                    f'{mathematica_code(original_second)}}}, '
                    f'"Regulator" -> {mathematica_code(original_eps)},\n'
                    ' "PathOrder" -> {"SpectatorPath", "FirstPath"},\n'
                    ' "FirstPath" -> <|"Base" -> {'
                    + mathematica_code(base_first)
                    + ', '
                    + mathematica_code(original_second)
                    + '}, "Target" -> {'
                    + mathematica_code(original_first)
                    + ', '
                    + mathematica_code(original_second)
                    + '}|>,\n'
                    ' "SpectatorPath" -> <|"Base" -> {'
                    + mathematica_code(base_first)
                    + ', 0}, "Target" -> {'
                    + mathematica_code(base_first)
                    + ', '
                    + mathematica_code(original_second)
                    + '}|>,\n'
                    ' "FirstPathDLogLetters" -> {'
                    + ", ".join(
                        mathematica_code(letter.xreplace(display_rules))
                        for letter in selected_letters
                    )
                    + '},\n'
                    ' "SpectatorPathKernels" -> {'
                    + ", ".join(
                        mathematica_code(kernel.xreplace(display_rules))
                        for kernel in spectator_kernels
                    )
                    + '},\n'
                    ' "PhysicalRows" -> {'
                    + ", ".join(
                        "{" + f"{order}, {component}" + "}"
                        for order, component in physical_labels
                    )
                    + '},\n'
                    ' "BoundaryCoordinates" -> {'
                    + ", ".join(coordinate_labels)
                    + '},\n'
                    f' "MaximumTotalWeight" -> {transport_weight},\n'
                    ' "ObservableMaps" -> {\n  '
                    + ",\n  ".join(two_segment_records)
                    + '},\n'
                    ' "Certificate" -> <|'
                    '"ExactInducedSpectatorConnection" -> True, '
                    '"ExactInvariantBoundarySubspace" -> True, '
                    '"ExactMatrixProducts" -> True, '
                    '"HigherRequestedWeightsVanish" -> True|>|>\n'
                )
                two_segment_file.write_text(two_segment_record)

            observable_summary = {
                "MaximumWeight": transport_weight,
                "PathActiveLetters": [index + 1 for index in active_letter_indices],
                "StateWordsByWeight": state_counts,
                "ObservableWordsByWeight": map_counts,
                "ObservableScalarsByWeight": scalar_counts,
                "GPLWordsByWeight": gpl_counts,
                "Record": str(observable_file),
            }
            if two_segment_maps is not None:
                observable_summary["TwoSegmentTransport"] = {
                    "KernelCount": len(spectator_kernel_matrices),
                    "ObservableMapsByTotalWeight": two_segment_counts,
                    "ObservableScalarsByTotalWeight": (
                        two_segment_scalar_counts
                    ),
                    "Record": str(two_segment_file),
                }
            progress(
                f"wrote {len(observable_maps)} observable word matrices"
            )

        result["WordCount"] = {
            "PhysicalRows": [row + 1 for row in selected_rows],
            "PhysicalOrders": physical_orders,
            "ExtendedLiftedDimension": extended_dimension,
            "ExtendedBoundaryDimension": len(extended_boundary_slots),
            "ConstrainedFreeDimension": constrained_free_dimension,
            "IndependentDLogLetters": [str(letter) for letter in selected_letters],
            "ResidueCount": len(lifted_residues),
            "MaxWeight": args.max_weight,
            **word_results,
        }
        if exact_reachable is not None:
            result["ExactReachableCertificate"] = exact_reachable
        if observable_summary is not None:
            result["ObservableTransport"] = observable_summary
        result["Seconds"] = round(time.time() - started, 3)

    OUTPUT.mkdir(parents=True, exist_ok=True)
    suffix = "_SymbolicSecond" if args.symbolic_second else ""
    if args.word_count:
        suffix += "_Words"
    output_file = OUTPUT / f"PreTransportValuation_{family}{suffix}.json"
    output_file.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    print(f"written {output_file}")
    if kernel_file is not None:
        print(f"written {kernel_file}")
    if observable_file is not None:
        print(f"written {observable_file}")
    if two_segment_file is not None:
        print(f"written {two_segment_file}")


if __name__ == "__main__":
    main()
