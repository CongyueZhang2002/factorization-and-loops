#!/usr/bin/env python3
"""Pilot the transposed regularized-endpoint functional for CF303 block 1.

At one accepted finite-field point and one later epsilon order, the Hermite
system is solved in the adjoint direction for only the normalized rho^0
primitive value.  The result is compared with the existing full primitive
solely as a pilot oracle; the adjoint path itself never constructs the
primitive coefficient vector.
"""

from __future__ import annotations

import argparse
from fractions import Fraction
import importlib.util
import json
from pathlib import Path
import sys
import time
from typing import Any


HERE = Path(__file__).resolve().parent
BUNDLE = HERE / "data/normal_factor_exact_circuit"
PILOT = BUNDLE / "cf303_block1_modular_finite_gauge_pilot.py"
LOCALIZER = HERE / "cf303_deferred_soft_residue_point.py"
DEFAULT_PRIME = 2_305_843_009_213_641_971
DEFAULT_DECK = BUNDLE / (
    "block1_modular_laurent_decks/"
    f"cf303_block1_laurent_deck_q{DEFAULT_PRIME}.json.gz"
)


class AdjointEndpointRefusal(RuntimeError):
    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise AdjointEndpointRefusal(
            "CF303AdjointEndpointProviderUnavailable", Provider=path.name
        )
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def solve_free_zero(columns, target, prime: int) -> list[int]:
    width = len(columns)
    height = max([len(target), *(len(column) for column in columns)])
    matrix = [[
        (columns[column][row] if row < len(columns[column]) else 0) % prime
        for column in range(width)
    ] + [(target[row] if row < len(target) else 0) % prime]
              for row in range(height)]
    pivot_row = 0
    pivots = []
    for column in range(width):
        pivot = next((row for row in range(pivot_row, height)
                      if matrix[row][column]), None)
        if pivot is None:
            continue
        matrix[pivot_row], matrix[pivot] = matrix[pivot], matrix[pivot_row]
        inverse = pow(matrix[pivot_row][column], -1, prime)
        matrix[pivot_row] = [value*inverse % prime
                             for value in matrix[pivot_row]]
        for row in range(height):
            if row == pivot_row or not matrix[row][column]:
                continue
            factor = matrix[row][column]
            matrix[row] = [
                (left - factor*right) % prime
                for left, right in zip(
                    matrix[row], matrix[pivot_row], strict=True
                )
            ]
        pivots.append((pivot_row, column))
        pivot_row += 1
        if pivot_row == height:
            break
    if any(not any(row[:-1]) and row[-1] for row in matrix):
        raise AdjointEndpointRefusal(
            "CF303AdjointEndpointSystemInconsistent"
        )
    result = [0] * width
    for row, column in pivots:
        result[column] = matrix[row][-1]
    return result


def hermite_system(function, helper, prime: int):
    numerator, denominator = list(function.numerator), list(function.denominator)
    polynomial_part, proper_numerator = helper.divmod_poly(
        numerator, denominator, prime
    )
    repeated = helper.gcd_poly(
        denominator, helper.derivative(denominator, prime), prime
    )
    square_free = helper.exact_div(denominator, repeated, prime)
    polynomial_primitive = [0] + [
        coefficient*pow(degree + 1, -1, prime) % prime
        for degree, coefficient in enumerate(polynomial_part)
    ]
    common_denominator = helper.lcm_poly(
        helper.lcm_poly(denominator, helper.multiply(
            repeated, repeated, prime
        ), prime), square_free, prime
    )
    target = helper.multiply(
        proper_numerator,
        helper.exact_div(common_denominator, denominator, prime),
        prime,
    )
    columns = []
    repeated_prime = helper.derivative(repeated, prime)
    repeated_multiplier = helper.exact_div(
        common_denominator, helper.multiply(repeated, repeated, prime), prime
    )
    for degree in range(len(repeated) - 1):
        monomial = [0]*degree + [1]
        derivative_numerator = helper.add(
            helper.multiply(helper.derivative(monomial, prime), repeated, prime),
            helper.multiply(monomial, repeated_prime, prime), prime, -1,
        )
        columns.append(helper.multiply(
            derivative_numerator, repeated_multiplier, prime
        ))
    square_free_multiplier = helper.exact_div(
        common_denominator, square_free, prime
    )
    for degree in range(len(square_free) - 1):
        columns.append(helper.multiply(
            [0]*degree + [1], square_free_multiplier, prime
        ))
    return columns, target, repeated, square_free, polynomial_primitive


def adjoint_normalized_finite(
    function, helper, localizer, rational_type, endpoint: int, base: int,
    prime: int,
) -> tuple[int, dict[str, int]]:
    columns, target, repeated, square_free, polynomial_primitive = (
        hermite_system(function, helper, prime)
    )
    repeated_degree = len(repeated) - 1
    width = len(columns)
    height = max([len(target), *(len(column) for column in columns)])
    rows = [[columns[column][row] if row < len(columns[column]) else 0
             for column in range(width)] for row in range(height)]
    functional = []
    for degree in range(repeated_degree):
        basis = rational_type.make([0]*degree + [1], repeated, prime, helper)
        local = localizer.rational_function_local_data(
            basis, endpoint, prime, through_power=0
        )
        finite = 0 if local is None else local["finite"]
        functional.append((finite - basis.evaluate(base)) % prime)
    functional.extend([0] * (width - repeated_degree))
    adjoint = solve_free_zero(rows, functional, prime)
    if any(
        sum(rows[unknown][equation]*adjoint[unknown]
            for unknown in range(height)) % prime != functional[equation]
        for equation in range(width)
    ):
        raise AdjointEndpointRefusal(
            "CF303AdjointEndpointTransposeReplayFailure"
        )
    value = sum(
        adjoint[index]*(target[index] if index < len(target) else 0)
        for index in range(height)
    ) % prime
    polynomial = rational_type.make(
        polynomial_primitive, [1], prime, helper
    )
    value = (value + polynomial.evaluate(endpoint)
             - polynomial.evaluate(base)) % prime
    return value, {
        "HermiteEquationCount": height,
        "HermiteUnknownCount": width,
        "PrimitiveUnknownCount": repeated_degree,
        "RemainderUnknownCount": len(square_free) - 1,
        "AdjointUnknownCount": height,
    }


def run_pilot(prime: int, point: Fraction, deck: Path,
              order: int) -> dict[str, Any]:
    if order <= -3 or order > 4:
        raise AdjointEndpointRefusal(
            "CF303AdjointEndpointPilotOrderInvalid", Order=order
        )
    pilot = load_module(f"cf303_adjoint_pilot_{prime}", PILOT)
    localizer = load_module(f"cf303_adjoint_localizer_{prime}", LOCALIZER)
    context = pilot.load_context(prime, deck)
    preceding_orders = tuple(range(-3, order))
    prior = pilot.run_point(context, point, preceding_orders)["records"]
    previous = {
        record["row"]: pilot.RationalFunction.make(
            record["h_numerator"], record["h_denominator"], prime,
            context["helper"],
        ) for record in prior if record["order"] == order - 1
    }
    p_value = pilot.exact_fraction_mod(point, prime)
    inputs = context["inputs"]
    diagonal = [[context["input_function"](record, p_value)
                 for record in row] for row in inputs["d"]]
    source = context["input_function"](inputs["s11"], p_value)
    endpoint = 2*p_value % prime
    base = pilot.exact_fraction_mod(Fraction(*inputs["base_point"]), prime)
    records = []
    started = time.perf_counter()
    for row in (1, 2):
        cross = pilot.RationalFunction.zero(prime)
        for middle in (1, 2):
            cross = cross.add(
                diagonal[row - 1][middle - 1].multiply(
                    previous[middle], context["helper"]
                ), context["helper"],
            )
        cross = cross.add(
            previous[row].multiply(source, context["helper"]),
            context["helper"], -1,
        )
        adjoint_started = time.perf_counter()
        value, dimensions = adjoint_normalized_finite(
            cross, context["helper"], localizer, pilot.RationalFunction,
            endpoint, base, prime,
        )
        adjoint_seconds = time.perf_counter() - adjoint_started
        oracle_started = time.perf_counter()
        primitive, _remainder = pilot.hermite(cross, context["helper"])
        primitive = primitive.add(
            pilot.RationalFunction.constant(primitive.evaluate(base), prime),
            context["helper"], -1,
        )
        local = localizer.rational_function_local_data(
            primitive, endpoint, prime, through_power=0
        )
        oracle = 0 if local is None else local["finite"]
        oracle_seconds = time.perf_counter() - oracle_started
        if value != oracle:
            raise AdjointEndpointRefusal(
                "CF303AdjointEndpointOracleMismatch", Row=row, Order=order
            )
        records.append({
            "Order": order, "Row": row,
            "AdjointRegularizedFiniteValue": value,
            **dimensions,
            "AdjointSeconds": adjoint_seconds,
            "FullPrimitivePilotOracleSeconds": oracle_seconds,
            "FullPrimitiveConstructedByAdjointPath": False,
        })
    return {
        "DataType": "CF303RegularizedEndpointHermiteAdjointPilot",
        "SchemaVersion": 2,
        "Status": "CF303RegularizedEndpointHermiteAdjointPilotValidated",
        "Family": "CF303", "Prime": prime,
        "TangentialPoint": [point.numerator, point.denominator],
        "NormalCoordinate": "rho=2*p-u", "EpsilonOrder": order,
        "Records": records,
        "Validation": {
            "AdjointEquationReplayed": True,
            "ExactAgreementWithFullPrimitivePilotOracle": True,
            "EndpointFunctionalOnly": True,
        },
        "Seconds": time.perf_counter() - started,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=DEFAULT_PRIME)
    parser.add_argument("--p", type=Fraction, default=Fraction(10))
    parser.add_argument("--deck", type=Path, default=DEFAULT_DECK)
    parser.add_argument("--order", type=int, default=-2)
    parser.add_argument("--output", type=Path)
    arguments = parser.parse_args()
    try:
        result = run_pilot(
            arguments.prime, arguments.p, arguments.deck, arguments.order
        )
    except AdjointEndpointRefusal as error:
        print(json.dumps({"Status": error.status, **error.details}, sort_keys=True))
        return 2
    encoded = json.dumps(result, indent=2) + "\n"
    if arguments.output:
        arguments.output.write_text(encoded)
    print(encoded, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
