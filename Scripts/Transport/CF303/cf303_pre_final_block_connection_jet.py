#!/usr/bin/env python3
"""Reconstruct the selected CF303 sector-24 connection as finite-field jets.

The saved sector-24 state uses the mixed basis (G_source,F25).  This adapter
evaluates only the two target rows and eight required columns.  It delegates
the large InputForm arithmetic to the existing packed finite-field path-jet
backend, removes a declared soft-factor clearing power, contracts the two
connection directions with d/dp at fixed rho, and reconstructs only the
demanded Laurent coefficients in the dimensional regulator.

No symbolic Series operation and no characteristic-zero identity are used.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import gzip
import json
import mmap
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import time
from typing import Iterable, Sequence


HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parents[2]
sys.path.insert(0, str(HERE))
from cf303_extract_pre_final_block_a_target_rows import (  # noqa: E402
    PreFinalBlockAExtractionError,
    association_list_field,
    invert_ranges_blocks,
    list_items,
    nested_integer_list,
)


PRIME = 2_305_843_009_213_641_971
P_NUMERATOR = 3
P_DENOMINATOR = 5
TARGET_PHYSICAL_MASTER_INTEGRAL_IDS = (5, 6)
SOURCE_PHYSICAL_MASTER_INTEGRAL_IDS = (2, 12, 21, 22, 29, 30)
SELECTED_PHYSICAL_MASTER_INTEGRAL_IDS = (
    SOURCE_PHYSICAL_MASTER_INTEGRAL_IDS
    + TARGET_PHYSICAL_MASTER_INTEGRAL_IDS
)
ROOT_EXPRESSIONS = (
    "1 + 2*x + x^2 - 2*y + 2*x*y + y^2",
    "1 - 2*x + x^2 + 2*y + 2*x*y + y^2",
    "1 - 4*x*y",
)
SOFT_FACTOR = "(-1+x+y)"
DEFAULT_CLEARING_POWER = 8
DEFAULT_EPSILON_SHIFT = 16
DEMANDED_EPSILON_WINDOWS = {
    "TargetFromSource": (-10, 3),
    "TargetFromTarget": (-8, 7),
}
NATIVE_SOURCE = HERE / "cf303_laurent_path_jet.c"
NATIVE = NATIVE_SOURCE


class ConnectionJetRefusal(RuntimeError):
    def __init__(self, status: str, **details) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def mod_inverse(value: int) -> int:
    value %= PRIME
    if value == 0:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetModularDivisionByZero"
        )
    return pow(value, PRIME - 2, PRIME)


@dataclass(frozen=True)
class Jet:
    """A Laurent series known at every exponent strictly below cutoff."""

    terms: tuple[tuple[int, int], ...]
    cutoff: int

    @staticmethod
    def make(terms: Iterable[tuple[int, int]], cutoff: int) -> "Jet":
        accumulated: dict[int, int] = {}
        for exponent, coefficient in terms:
            if exponent < cutoff:
                accumulated[exponent] = (
                    accumulated.get(exponent, 0) + coefficient
                ) % PRIME
        return Jet(
            tuple(sorted(
                (exponent, coefficient)
                for exponent, coefficient in accumulated.items()
                if coefficient
            )),
            cutoff,
        )

    @staticmethod
    def constant(value: int, cutoff: int) -> "Jet":
        value %= PRIME
        return Jet(((0, value),), cutoff) if value else Jet((), cutoff)

    @staticmethod
    def rho(cutoff: int) -> "Jet":
        return Jet(((1, 1),), cutoff)

    @property
    def lower_bound(self) -> int:
        return self.terms[0][0] if self.terms else self.cutoff

    def coefficient(self, exponent: int) -> int:
        if exponent >= self.cutoff:
            raise ConnectionJetRefusal(
                "CF303PreFinalBlockBasisConnectionJetPrecisionInsufficient",
                Exponent=exponent,
                Cutoff=self.cutoff,
            )
        return dict(self.terms).get(exponent, 0)

    def add(self, other: "Jet", sign: int = 1) -> "Jet":
        cutoff = min(self.cutoff, other.cutoff)
        values = dict(self.terms)
        for exponent, coefficient in other.terms:
            if exponent < cutoff:
                values[exponent] = (
                    values.get(exponent, 0) + sign * coefficient
                ) % PRIME
        return Jet.make(values.items(), cutoff)

    def negate(self) -> "Jet":
        return Jet.make(
            ((exponent, -coefficient)
             for exponent, coefficient in self.terms),
            self.cutoff,
        )

    def multiply(self, other: "Jet") -> "Jet":
        cutoff = min(
            self.cutoff + other.lower_bound,
            other.cutoff + self.lower_bound,
        )
        if not self.terms or not other.terms:
            return Jet((), cutoff)
        if len(self.terms) == 1:
            shift, scale = self.terms[0]
            return Jet.make(
                ((shift + exponent, scale * coefficient)
                 for exponent, coefficient in other.terms),
                cutoff,
            )
        if len(other.terms) == 1:
            return other.multiply(self)
        values: dict[int, int] = {}
        for left_power, left in self.terms:
            for right_power, right in other.terms:
                exponent = left_power + right_power
                if exponent >= cutoff:
                    break
                values[exponent] = (
                    values.get(exponent, 0) + left * right
                ) % PRIME
        return Jet.make(values.items(), cutoff)

    def inverse(self) -> "Jet":
        if not self.terms:
            raise ConnectionJetRefusal(
                "CF303PreFinalBlockBasisConnectionJetInverseNeedsPrecision",
                KnownZeroThrough=self.cutoff - 1,
            )
        valuation = self.terms[0][0]
        relative_count = self.cutoff - valuation
        if relative_count <= 0:
            raise ConnectionJetRefusal(
                "CF303PreFinalBlockBasisConnectionJetInverseNeedsPrecision"
            )
        source = dict(self.terms)
        leading_inverse = mod_inverse(source[valuation])
        coefficients = [leading_inverse]
        for degree in range(1, relative_count):
            convolution = sum(
                source.get(valuation + index, 0)
                * coefficients[degree - index]
                for index in range(1, degree + 1)
            ) % PRIME
            coefficients.append(-leading_inverse * convolution % PRIME)
        return Jet.make(
            ((-valuation + degree, coefficient)
             for degree, coefficient in enumerate(coefficients)),
            self.cutoff - 2 * valuation,
        )

    def power(self, exponent: int) -> "Jet":
        if exponent < 0:
            return self.inverse().power(-exponent)
        result = Jet.constant(1, self.cutoff)
        base = self
        while exponent:
            if exponent & 1:
                result = result.multiply(base)
            exponent >>= 1
            if exponent:
                base = base.multiply(base)
        return result


def square_root_jet(value: Jet, root_constant: int) -> Jet:
    if value.lower_bound != 0:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetRadicalNotAUnit",
            Valuation=value.lower_bound,
        )
    source = dict(value.terms)
    root_constant %= PRIME
    if root_constant * root_constant % PRIME != source.get(0, 0):
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetRootConstantMismatch"
        )
    inverse_twice_root = mod_inverse(2 * root_constant)
    coefficients = [root_constant]
    for degree in range(1, value.cutoff):
        convolution = sum(
            coefficients[index] * coefficients[degree - index]
            for index in range(1, degree)
        ) % PRIME
        coefficients.append(
            (source.get(degree, 0) - convolution)
            * inverse_twice_root % PRIME
        )
    result = Jet.make(enumerate(coefficients), value.cutoff)
    if result.multiply(result).add(value, -1).terms:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetRootSquareMismatch"
        )
    return result


def path_data(cutoff: int) -> tuple[
        Jet, Jet, Jet, Jet, tuple[Jet, ...], tuple[Jet, ...]]:
    p = P_NUMERATOR * mod_inverse(P_DENOMINATOR) % PRIME
    one = Jet.constant(1, cutoff)
    rho = Jet.rho(cutoff)
    numerator = rho.multiply(Jet.constant(2, cutoff)).add(
        Jet.constant(-4 * p * p, cutoff)
    )
    denominator = Jet.constant(4 * p, cutoff).multiply(
        one.add(rho, -1)
    ).add(rho.power(2))
    a = numerator.multiply(denominator.inverse())
    x = a.multiply(Jet.constant(-p, cutoff))
    y = one.add(a, -1).multiply(Jet.constant(1 - p, cutoff))
    numerator_p = Jet.constant(-8 * p, cutoff)
    denominator_p = one.add(rho, -1).multiply(Jet.constant(4, cutoff))
    a_p = numerator_p.multiply(denominator).add(
        numerator.multiply(denominator_p), -1
    ).multiply(denominator.power(-2))
    x_p = a.negate().add(a_p.multiply(Jet.constant(-p, cutoff)))
    y_p = one.add(a, -1).negate().add(
        a_p.multiply(Jet.constant(-(1 - p), cutoff))
    )
    root_squares = (
        one.add(x).add(y, -1).power(2).add(
            x.multiply(y).multiply(Jet.constant(4, cutoff))
        ),
        one.add(x, -1).add(y).power(2).add(
            x.multiply(y).multiply(Jet.constant(4, cutoff))
        ),
        one.add(x.multiply(y).multiply(Jet.constant(4, cutoff)), -1),
    )
    root_constants = (
        6 * mod_inverse(5),
        8 * mod_inverse(5),
        7 * mod_inverse(25),
    )
    roots = tuple(
        square_root_jet(square, root)
        for square, root in zip(root_squares, root_constants)
    )
    return x, y, x_p, y_p, root_squares, roots


def slice_data(path: Path) -> tuple[list[list[list[str]]], dict]:
    with path.open("rb") as stream, mmap.mmap(
            stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
        header = data[:1024]
        if (b'"DataType" -> '
                b'"CF303PreFinalBlockBasisConnectionTargetRowSlice"'
                not in header or b'"Sector" -> 24' not in header):
            raise ConnectionJetRefusal(
                "CF303PreFinalBlockBasisConnectionJetSliceTypeInvalid"
            )
        directions = list_items(
            association_list_field(data, "ConnectionMatrices")
        )
        requested_target_physical_ids = [
            int(value) for value in list_items(association_list_field(
                data, "RequestedRowPhysicalMasterIntegralIDs"
            ))
        ]
        requested_selected_physical_ids = [
            int(value) for value in list_items(association_list_field(
                data, "RequestedColumnPhysicalMasterIntegralIDs"
            ))
        ]
        target_state_rows = [
            int(value) for value in list_items(
                association_list_field(data, "DerivedStateRows")
            )
        ]
        selected_state_columns = [
            int(value) for value in list_items(
                association_list_field(data, "DerivedStateColumns")
            )
        ]
        ranges = nested_integer_list(
            association_list_field(data, "Ranges"), "Ranges"
        )
        blocks = nested_integer_list(
            association_list_field(data, "Blocks"), "Blocks"
        )
    try:
        physical_to_state, state_to_physical = invert_ranges_blocks(
            ranges, blocks
        )
    except PreFinalBlockAExtractionError as error:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetRangesBlocksMappingInvalid",
            Reason=str(error),
        ) from error
    if requested_target_physical_ids != list(
            TARGET_PHYSICAL_MASTER_INTEGRAL_IDS):
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetTargetPhysicalOrderInvalid",
            Expected=list(TARGET_PHYSICAL_MASTER_INTEGRAL_IDS),
            Observed=requested_target_physical_ids,
        )
    if requested_selected_physical_ids != list(
            SELECTED_PHYSICAL_MASTER_INTEGRAL_IDS):
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetSelectedPhysicalOrderInvalid",
            Expected=list(SELECTED_PHYSICAL_MASTER_INTEGRAL_IDS),
            Observed=requested_selected_physical_ids,
        )
    expected_target_state_rows = [
        physical_to_state[value] for value in requested_target_physical_ids
    ]
    expected_selected_state_columns = [
        physical_to_state[value] for value in requested_selected_physical_ids
    ]
    if (target_state_rows != expected_target_state_rows or
            selected_state_columns != expected_selected_state_columns or
            [state_to_physical[value] for value in target_state_rows] !=
            requested_target_physical_ids or
            [state_to_physical[value] for value in selected_state_columns] !=
            requested_selected_physical_ids):
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetPhysicalOrderNotPreserved",
            TargetStateRows=target_state_rows,
            ExpectedTargetStateRows=expected_target_state_rows,
            SelectedStateColumns=selected_state_columns,
            ExpectedSelectedStateColumns=expected_selected_state_columns,
        )
    matrices = []
    for direction in directions:
        rows = list_items(direction)
        matrices.append([
            [entry.decode() for entry in list_items(row)] for row in rows
        ])
    if (len(matrices) != 2 or any(len(matrix) != 2 for matrix in matrices)
            or any(len(row) != 8 for matrix in matrices for row in matrix)):
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetSliceDimensionsInvalid"
        )
    return matrices, {
        "TargetStateRows": target_state_rows,
        "TargetPhysicalMasterIntegralIDs": requested_target_physical_ids,
        "SelectedStateColumns": selected_state_columns,
        "SelectedPhysicalMasterIntegralIDs":
            requested_selected_physical_ids,
        "SourceStateColumns": selected_state_columns[
            :len(SOURCE_PHYSICAL_MASTER_INTEGRAL_IDS)
        ],
        "SourcePhysicalMasterIntegralIDs":
            list(SOURCE_PHYSICAL_MASTER_INTEGRAL_IDS),
        "RangesBlocksMappingIsBijective": True,
        "RequestedPhysicalMasterIntegralOrderPreserved": True,
    }


def write_native_preparation(
        path: Path, expressions: list[list[list[str]]],
        clearing_power: int) -> None:
    with path.open("w") as stream:
        stream.write(
            '<|"DeferredPreparation" -> <|"Preparation" -> '
            '<|"Status" -> "Prepared", "DataType" -> '
            '"DeferredBlockEquation", "SchemaVersion" -> 2, '
            '"Records" -> {\n'
        )
        first = True
        for direction in range(2):
            for row in range(2):
                for column in range(8):
                    if not first:
                        stream.write(",\n")
                    first = False
                    stream.write(
                        '<|"Target" -> {'
                        f"{direction + 1}, {row + 1}, {column + 1}"
                        '}, "Terms" -> {<|"Coefficient" -> ('
                        f"{SOFT_FACTOR}^{clearing_power})*("
                    )
                    stream.write(expressions[direction][row][column])
                    stream.write('), "Operands" -> {}|>}|>')
        stream.write("\n}|>|>|>\n")


def jet_values(value: Jet, order: int) -> str:
    return " ".join(str(value.coefficient(index))
                    for index in range(order + 1))


def write_native_request(
        path: Path, order: int, epsilon_images: Sequence[int]) -> None:
    x, y, _, _, root_squares, roots = path_data(order + 1)
    with path.open("w") as stream:
        stream.write("DeferredPathJetRequestV1\n")
        stream.write(f"prime {PRIME}\n")
        stream.write("variables x y eps\n")
        stream.write(f"order {order}\n")
        stream.write(f"rank {len(ROOT_EXPRESSIONS)}\n")
        for expression in ROOT_EXPRESSIONS:
            stream.write("root " + "".join(expression.split()) + "\n")
        stream.write(f"epsilon_count {len(epsilon_images)}\n")
        for image in epsilon_images:
            stream.write(f"epsilon {image % PRIME}\n")
        stream.write("x_jet " + jet_values(x, order) + "\n")
        stream.write("y_jet " + jet_values(y, order) + "\n")
        for square, root in zip(root_squares, roots):
            stream.write("delta_jet " + jet_values(square, order) + "\n")
            stream.write("root_jet " + jet_values(root, order) + "\n")


def read_native_output(path: Path) -> tuple[dict, list[tuple[tuple[int, ...],
                                                               list[list[int]]]]]:
    data = path.read_bytes()
    if len(data) < 112 or data[:8] != b"DAPJ1V1\0":
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetNativeOutputMalformed"
        )
    header_values = struct.unpack_from("<13Q", data, 8)
    keys = (
        "StatusCode", "Prime", "Order", "RootRank", "EpsilonImageCount",
        "RecordCount", "TermCount", "UniqueExpressionCount", "Dimension0",
        "Dimension1", "Dimension2", "ParseNanoseconds",
        "EvaluationNanoseconds",
    )
    header = dict(zip(keys, header_values))
    if header["StatusCode"] != 0:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetNativeEvaluationFailed",
            NativeHeader=header,
        )
    expected = 112 + header["RecordCount"] * (
        3 + header["EpsilonImageCount"] * (header["Order"] + 1)
    ) * 8
    if len(data) != expected:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetNativeOutputLengthInvalid",
            ExpectedBytes=expected,
            ObservedBytes=len(data),
        )
    offset = 112
    records = []
    channel_count = header["EpsilonImageCount"] * (header["Order"] + 1)
    for _ in range(header["RecordCount"]):
        target = struct.unpack_from("<3Q", data, offset)
        offset += 24
        flat = struct.unpack_from(f"<{channel_count}Q", data, offset)
        offset += 8 * channel_count
        channels = [
            list(flat[index * (header["Order"] + 1):
                      (index + 1) * (header["Order"] + 1)])
            for index in range(header["EpsilonImageCount"])
        ]
        records.append((target, channels))
    return header, records


def run_native(
        executable: Path, preparation: Path, request: Path, output: Path,
        threads: int, deadline_seconds: float) -> tuple[dict, list]:
    environment = dict(os.environ)
    for name in (
            "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS",
            "VECLIB_MAXIMUM_THREADS", "NUMEXPR_NUM_THREADS"):
        environment[name] = str(threads)
    started = time.monotonic()
    try:
        completed = subprocess.run(
            [str(executable), str(preparation), str(request), str(output),
             "--threads", str(threads)],
            check=False,
            capture_output=True,
            text=True,
            timeout=deadline_seconds,
            env=environment,
        )
    except subprocess.TimeoutExpired as error:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetNativeDeadlineExceeded",
            DeadlineSeconds=deadline_seconds,
        ) from error
    header, records = read_native_output(output)
    if completed.returncode != 0:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetNativeProcessFailed",
            ReturnCode=completed.returncode,
            StandardOutput=completed.stdout[-2000:],
            StandardError=completed.stderr[-2000:],
            NativeHeader=header,
        )
    header["WallSeconds"] = time.monotonic() - started
    header["StandardOutput"] = completed.stdout[-2000:]
    return header, records


def compile_native(source: Path, output: Path) -> float:
    started = time.monotonic()
    completed = subprocess.run(
        ["cc", "-O3", "-march=native", "-std=c11", "-Wall",
         "-Wextra", "-Werror", "-Wno-missing-field-initializers",
         "-Wno-unused-function", "-Wpedantic", "-Wconversion",
         "-Wshadow", "-Wstrict-prototypes", "-Wformat=2",
         "-fno-common", "-fopenmp", str(source), "-o", str(output)],
        check=False, capture_output=True, text=True,
    )
    if completed.returncode != 0:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetNativeCompilationFailed",
            ReturnCode=completed.returncode,
            StandardOutput=completed.stdout[-4000:],
            StandardError=completed.stderr[-4000:],
        )
    return time.monotonic() - started


def trim_polynomial(value: Sequence[int]) -> list[int]:
    result = [coefficient % PRIME for coefficient in value]
    while result and result[-1] == 0:
        result.pop()
    return result


def polynomial_add(
        left: Sequence[int], right: Sequence[int], sign: int = 1) -> list[int]:
    result = [0] * max(len(left), len(right))
    for index in range(len(result)):
        result[index] = (
            (left[index] if index < len(left) else 0)
            + sign * (right[index] if index < len(right) else 0)
        ) % PRIME
    return trim_polynomial(result)


def polynomial_multiply(
        left: Sequence[int], right: Sequence[int]) -> list[int]:
    if not left or not right:
        return []
    result = [0] * (len(left) + len(right) - 1)
    for left_index, left_value in enumerate(left):
        for right_index, right_value in enumerate(right):
            result[left_index + right_index] = (
                result[left_index + right_index]
                + left_value * right_value
            ) % PRIME
    return trim_polynomial(result)


def polynomial_divmod(
        numerator: Sequence[int], denominator: Sequence[int]
        ) -> tuple[list[int], list[int]]:
    remainder = trim_polynomial(numerator)
    divisor = trim_polynomial(denominator)
    if not divisor:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetPolynomialDivisionByZero"
        )
    if len(remainder) < len(divisor):
        return [], remainder
    quotient = [0] * (len(remainder) - len(divisor) + 1)
    inverse_leading = mod_inverse(divisor[-1])
    while remainder and len(remainder) >= len(divisor):
        shift = len(remainder) - len(divisor)
        coefficient = remainder[-1] * inverse_leading % PRIME
        quotient[shift] = coefficient
        for index, value in enumerate(divisor):
            remainder[index + shift] = (
                remainder[index + shift] - coefficient * value
            ) % PRIME
        remainder = trim_polynomial(remainder)
    return trim_polynomial(quotient), remainder


def polynomial_evaluate(polynomial: Sequence[int], point: int) -> int:
    result = 0
    for coefficient in reversed(polynomial):
        result = (result * point + coefficient) % PRIME
    return result


def interpolation_polynomials(
        points: Sequence[int], values: Sequence[int]
        ) -> tuple[list[int], list[int]]:
    divided = [value % PRIME for value in values]
    for width in range(1, len(points)):
        for index in range(len(points) - 1, width - 1, -1):
            divided[index] = (
                (divided[index] - divided[index - 1])
                * mod_inverse(points[index] - points[index - width])
            ) % PRIME
    interpolation: list[int] = []
    vanishing = [1]
    for index, coefficient in enumerate(divided):
        interpolation = polynomial_add(
            interpolation,
            [(coefficient * value) % PRIME for value in vanishing],
        )
        vanishing = polynomial_multiply(
            vanishing, [(-points[index]) % PRIME, 1]
        )
    return interpolation, vanishing


def rational_interpolate(
        fit_points: Sequence[int], fit_values: Sequence[int],
        held_out_points: Sequence[int], held_out_values: Sequence[int],
        ) -> tuple[list[int], list[int], int]:
    if len(fit_points) != len(fit_values) or not fit_points:
        raise ValueError("nonempty equal-length fit data required")
    if len(held_out_points) != len(held_out_values):
        raise ValueError("equal-length held-out data required")
    if all(value % PRIME == 0 for value in fit_values):
        if any(value % PRIME for value in held_out_values):
            raise ConnectionJetRefusal(
                "CF303PreFinalBlockBasisConnectionJetZeroFitFailedHeldOut"
            )
        return [], [1], len(held_out_values)
    interpolation, vanishing = interpolation_polynomials(
        fit_points, fit_values
    )
    remainder_previous, remainder = vanishing, interpolation
    denominator_previous, denominator = [], [1]
    candidates = 0
    while remainder:
        candidates += 1
        constant = denominator[0] if denominator else 0
        if constant:
            inverse_constant = mod_inverse(constant)
            candidate_numerator = [
                value * inverse_constant % PRIME for value in remainder
            ]
            candidate_denominator = [
                value * inverse_constant % PRIME for value in denominator
            ]
            valid = True
            for point, value in zip(
                    list(fit_points) + list(held_out_points),
                    list(fit_values) + list(held_out_values)):
                denominator_value = polynomial_evaluate(
                    candidate_denominator, point
                )
                if (denominator_value == 0 or
                        polynomial_evaluate(candidate_numerator, point) !=
                        value * denominator_value % PRIME):
                    valid = False
                    break
            if valid:
                return (
                    trim_polynomial(candidate_numerator),
                    trim_polynomial(candidate_denominator),
                    len(held_out_points),
                )
        quotient, next_remainder = polynomial_divmod(
            remainder_previous, remainder
        )
        next_denominator = polynomial_add(
            denominator_previous,
            polynomial_multiply(quotient, denominator),
            -1,
        )
        remainder_previous, remainder = remainder, next_remainder
        denominator_previous, denominator = denominator, next_denominator
    raise ConnectionJetRefusal(
        "CF303PreFinalBlockBasisConnectionJetRationalInterpolationFailed",
        FitCount=len(fit_points),
        HeldOutCount=len(held_out_points),
        CandidateCount=candidates,
    )


def rational_series(
        numerator: Sequence[int], denominator: Sequence[int],
        through: int) -> list[int]:
    if not denominator or denominator[0] == 0:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetRegulatorPoleNotCleared"
        )
    inverse_constant = mod_inverse(denominator[0])
    result = []
    for order in range(through + 1):
        correction = sum(
            denominator[index] * result[order - index]
            for index in range(1, min(order, len(denominator) - 1) + 1)
        ) % PRIME
        source = numerator[order] if order < len(numerator) else 0
        result.append((source - correction) * inverse_constant % PRIME)
    return result


def recovered_parallel_jets(
        native_records: Sequence[tuple[tuple[int, ...], list[list[int]]]],
        order: int, epsilon_count: int, clearing_power: int,
        ) -> list[list[list[Jet]]]:
    expected_targets = [
        (direction, row, column)
        for direction in range(1, 3)
        for row in range(1, 3)
        for column in range(1, 9)
    ]
    if [target for target, _ in native_records] != expected_targets:
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetNativeRecordOrderInvalid"
        )
    x, y, x_p, y_p, _, _ = path_data(order + 1)
    clearing_factor = x.add(y).add(
        Jet.constant(1, order + 1), -1
    ).power(clearing_power)
    clearing_inverse = clearing_factor.inverse()
    values = [[[] for _ in range(8)] for _ in range(2)]
    for row in range(2):
        for column in range(8):
            x_channels = native_records[row * 8 + column][1]
            y_channels = native_records[16 + row * 8 + column][1]
            for image in range(epsilon_count):
                x_scaled = Jet.make(enumerate(x_channels[image]), order + 1)
                y_scaled = Jet.make(enumerate(y_channels[image]), order + 1)
                parallel = x_p.multiply(
                    x_scaled.multiply(clearing_inverse)
                ).add(y_p.multiply(
                    y_scaled.multiply(clearing_inverse)
                ))
                values[row][column].append(parallel)
    return values


def reconstruct_records(
        jets: list[list[list[Jet]]], epsilon_images: Sequence[int],
        fit_count: int, epsilon_shift: int, through: int, basis_mapping: dict,
        ) -> tuple[list[dict], dict]:
    fit_points = list(epsilon_images[:fit_count])
    held_out_points = list(epsilon_images[fit_count:])
    records = []
    degree_profiles = []
    held_out_comparisons = 0
    rational_function_count = 0
    minimum_rho = through + 1
    target_state_rows = basis_mapping["TargetStateRows"]
    target_physical_ids = basis_mapping[
        "TargetPhysicalMasterIntegralIDs"
    ]
    selected_state_columns = basis_mapping["SelectedStateColumns"]
    selected_physical_ids = basis_mapping[
        "SelectedPhysicalMasterIntegralIDs"
    ]
    source_count = len(SOURCE_PHYSICAL_MASTER_INTEGRAL_IDS)
    for row, (target, target_physical_id) in enumerate(zip(
            target_state_rows, target_physical_ids)):
        for column_index, (column, physical_id) in enumerate(zip(
                selected_state_columns, selected_physical_ids)):
            block = (
                "TargetFromSource" if column_index < source_count
                else "TargetFromTarget"
            )
            epsilon_low, epsilon_high = DEMANDED_EPSILON_WINDOWS[block]
            coordinate_jets = jets[row][column_index]
            if any(value.cutoff <= through for value in coordinate_jets):
                raise ConnectionJetRefusal(
                    "CF303PreFinalBlockBasisConnectionJetPrecisionInsufficient",
                    TargetStateRow=target,
                    StateColumn=column,
                    Cutoffs=[value.cutoff for value in coordinate_jets],
                )
            rho_low = min(value.lower_bound for value in coordinate_jets)
            minimum_rho = min(minimum_rho, rho_low)
            coefficients = []
            profiles = []
            for rho_power in range(rho_low, through + 1):
                samples = [
                    value.coefficient(rho_power)
                    for value in coordinate_jets
                ]
                shifted = [
                    sample * pow(point, epsilon_shift, PRIME) % PRIME
                    for point, sample in zip(epsilon_images, samples)
                ]
                numerator, denominator, comparisons = rational_interpolate(
                    fit_points, shifted[:fit_count],
                    held_out_points, shifted[fit_count:],
                )
                held_out_comparisons += comparisons
                rational_function_count += 1
                expansion = rational_series(
                    numerator, denominator, epsilon_high + epsilon_shift
                )
                for epsilon_order in range(epsilon_low, epsilon_high + 1):
                    value = expansion[epsilon_order + epsilon_shift]
                    if value:
                        coefficients.append({
                            "RhoPower": rho_power,
                            "EpsilonOrder": epsilon_order,
                            "Value": value,
                        })
                profiles.append({
                    "RhoPower": rho_power,
                    "ShiftedNumeratorDegree": len(numerator) - 1,
                    "DenominatorDegree": len(denominator) - 1,
                    "RegulatorClearingPower": epsilon_shift,
                })
                degree_profiles.append(
                    (len(numerator) - 1, len(denominator) - 1)
                )
            records.append({
                "TargetStateRow": target,
                "TargetPhysicalMasterIntegralID": target_physical_id,
                "StateColumn": column,
                "PhysicalMasterIntegralID": physical_id,
                "Block": block,
                "RhoValuationOrLowerBoundThroughRequestedOrder": rho_low,
                "DemandedEpsilonOrderWindow":
                    [epsilon_low, epsilon_high],
                "Coefficients": coefficients,
                "EpsilonRationalProfilesByRhoPower": profiles,
            })
    profile_summary = {
        "RationalFunctionCount": rational_function_count,
        "HeldOutCoefficientComparisonCount": held_out_comparisons,
        "MaximumShiftedNumeratorDegree":
            max(pair[0] for pair in degree_profiles),
        "MaximumDenominatorDegree":
            max(pair[1] for pair in degree_profiles),
        "MinimumRhoValuation": minimum_rho,
    }
    return records, profile_summary


def apply_affinity(cpus: str | None) -> list[int]:
    if cpus is None:
        return sorted(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else []
    selected = set()
    for part in cpus.split(","):
        if "-" in part:
            start, end = (int(value) for value in part.split("-", 1))
            selected.update(range(start, end + 1))
        else:
            selected.add(int(part))
    if hasattr(os, "sched_setaffinity"):
        os.sched_setaffinity(0, selected)
        return sorted(os.sched_getaffinity(0))
    return sorted(selected)


def build(
        slice_path: Path, native: Path, native_order: int, through: int,
        fit_count: int, held_out_count: int, clearing_power: int,
        epsilon_shift: int, threads: int, deadline_seconds: float,
        ) -> dict:
    started = time.monotonic()
    if not native.is_file():
        raise ConnectionJetRefusal(
            "CF303PreFinalBlockBasisConnectionJetNativeExecutableMissing",
            NativeExecutable=str(native),
        )
    expressions, basis_mapping = slice_data(slice_path)
    epsilon_images = list(range(1, fit_count + held_out_count + 1))
    with tempfile.TemporaryDirectory(
            prefix="cf303-pre-final-block-jet-") as raw:
        directory = Path(raw)
        preparation = directory / "preparation.wl"
        request = directory / "request.txt"
        native_output = directory / "output.bin"
        native_executable = native
        compilation_seconds = 0.0
        if native.suffix == ".c":
            native_executable = directory / "cf303_laurent_path_jet"
            compilation_seconds = compile_native(native, native_executable)
        write_native_preparation(preparation, expressions, clearing_power)
        write_native_request(request, native_order, epsilon_images)
        native_header, native_records = run_native(
            native_executable, preparation, request, native_output,
            threads, deadline_seconds,
        )
        native_header["CompilationSeconds"] = compilation_seconds
    jets = recovered_parallel_jets(
        native_records, native_order, len(epsilon_images), clearing_power
    )
    records, reconstruction = reconstruct_records(
        jets, epsilon_images, fit_count, epsilon_shift, through,
        basis_mapping,
    )
    complete = (
        len(records) ==
        len(TARGET_PHYSICAL_MASTER_INTEGRAL_IDS) *
        len(SELECTED_PHYSICAL_MASTER_INTEGRAL_IDS)
    )
    conditions = {
        "SavedStateSectorIsTwentyFour": True,
        "DeclaredPhysicalRootJetsSquareExactly": True,
        "PackedFiniteFieldPathJetEvaluationSucceeded": True,
        "SoftFactorClearingRemovedInTruncatedLaurentRing": True,
        "EveryRegulatorRationalReconstructionPassesHeldOutImages":
            reconstruction["HeldOutCoefficientComparisonCount"] ==
            reconstruction["RationalFunctionCount"] * held_out_count,
        "DemandedRegulatorWindowsReconstructed": True,
        "RangesBlocksMappingIsBijective":
            basis_mapping["RangesBlocksMappingIsBijective"],
        "RequestedPhysicalMasterIntegralOrderPreserved":
            basis_mapping[
                "RequestedPhysicalMasterIntegralOrderPreserved"
            ],
        "CompleteSelectedTargetRowRectangle": complete,
    }
    status = (
        "CF303PreFinalBlockBasisConnectionJetFiniteFieldReconstructed"
        if all(conditions.values()) else
        "CF303PreFinalBlockBasisConnectionJetFiniteFieldFailed"
    )
    return {
        "DataType": "CF303PreFinalBlockBasisConnectionJet",
        "SchemaVersion": 2,
        "Status": status,
        "Family": "CF303",
        "Prime": PRIME,
        "TangentialPoint": [P_NUMERATOR, P_DENOMINATOR],
        "NormalCoordinate": "rho=2*p-z",
        "FixedRhoDerivative": "partial_p|rho=partial_p|z+2*partial_z",
        "Basis": {
            "SourceBlockBasis": "SourceFamilyDLogEpsilonFormBasis",
            "FinalBlockBasis": "F25BeforeFinalOffDiagonalTransformation",
            "OrderedAmbientBasis": "(G_source,F25)",
            "SavedStateSector": 24,
            **basis_mapping,
        },
        "DemandedEpsilonOrderWindowsByBlock":
            {key: list(value)
             for key, value in DEMANDED_EPSILON_WINDOWS.items()},
        "RhoCoefficientWindow": [
            reconstruction["MinimumRhoValuation"], through
        ],
        "NativeTruncatedRhoOrder": native_order,
        "SoftFactorClearingPower": clearing_power,
        "RegulatorClearingPower": epsilon_shift,
        "RegulatorFitImageCount": fit_count,
        "RegulatorHeldOutImageCount": held_out_count,
        "RegulatorImages": epsilon_images,
        "Records": records,
        "ReconstructionSummary": reconstruction,
        "NativeEvaluation": native_header,
        "Validation": {
            "Method":
                "PackedFiniteFieldTruncatedRhoJetsAndHeldOutRationalInterpolation",
            "Conditions": conditions,
        },
        "InputReference": str(slice_path),
        "TotalSeconds": time.monotonic() - started,
    }


def write_result(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps(value, indent=2) + "\n"
    if path.suffix == ".gz":
        with gzip.open(path, "wt") as stream:
            stream.write(serialized)
    else:
        path.write_text(serialized)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("slice", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--native", type=Path, default=NATIVE)
    parser.add_argument("--native-order", type=int, default=20)
    parser.add_argument("--through", type=int, default=2)
    parser.add_argument("--fit-count", type=int, default=32)
    parser.add_argument("--held-out-count", type=int, default=8)
    parser.add_argument(
        "--clearing-power", type=int, default=DEFAULT_CLEARING_POWER
    )
    parser.add_argument(
        "--epsilon-shift", type=int, default=DEFAULT_EPSILON_SHIFT
    )
    parser.add_argument("--threads", type=int, default=2)
    parser.add_argument("--cpus")
    parser.add_argument("--deadline-seconds", type=float, default=240.0)
    arguments = parser.parse_args()
    if arguments.native_order <= arguments.through + arguments.clearing_power:
        parser.error(
            "native-order must exceed through plus clearing-power"
        )
    if arguments.fit_count < 4 or arguments.held_out_count < 2:
        parser.error("at least four fit and two held-out images are required")
    if arguments.epsilon_shift < -min(
            value[0] for value in DEMANDED_EPSILON_WINDOWS.values()):
        parser.error("epsilon-shift does not cover demanded negative orders")
    if not 1 <= arguments.threads <= 2:
        parser.error("threads must be one or two")
    affinity: list[int] = []
    try:
        affinity = apply_affinity(arguments.cpus)
        result = build(
            arguments.slice, arguments.native, arguments.native_order,
            arguments.through, arguments.fit_count,
            arguments.held_out_count, arguments.clearing_power,
            arguments.epsilon_shift, arguments.threads,
            arguments.deadline_seconds,
        )
        result["ProcessAffinityCPUs"] = affinity
    except (OSError, UnicodeDecodeError, ValueError,
            PreFinalBlockAExtractionError,
            ConnectionJetRefusal) as error:
        if isinstance(error, ConnectionJetRefusal):
            result = {
                "DataType": "CF303PreFinalBlockBasisConnectionJet",
                "SchemaVersion": 2,
                "Status": error.status,
                "Family": "CF303",
                **error.details,
            }
        else:
            result = {
                "DataType": "CF303PreFinalBlockBasisConnectionJet",
                "SchemaVersion": 2,
                "Status":
                    "CF303PreFinalBlockBasisConnectionJetInputFailure",
                "Family": "CF303",
                "Exception": type(error).__name__,
                "Message": str(error),
            }
        result["ProcessAffinityCPUs"] = affinity
        write_result(arguments.output, result)
        print(json.dumps(result, sort_keys=True), flush=True)
        return 2
    write_result(arguments.output, result)
    print(json.dumps({
        "Status": result["Status"],
        "RecordCount": len(result["Records"]),
        "RhoCoefficientWindow": result["RhoCoefficientWindow"],
        "MaximumShiftedNumeratorDegree":
            result["ReconstructionSummary"]
                  ["MaximumShiftedNumeratorDegree"],
        "MaximumDenominatorDegree":
            result["ReconstructionSummary"]["MaximumDenominatorDegree"],
        "HeldOutCoefficientComparisonCount":
            result["ReconstructionSummary"]
                  ["HeldOutCoefficientComparisonCount"],
        "NativeWallSeconds": result["NativeEvaluation"]["WallSeconds"],
        "TotalSeconds": result["TotalSeconds"],
        "Output": str(arguments.output),
    }, sort_keys=True), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
