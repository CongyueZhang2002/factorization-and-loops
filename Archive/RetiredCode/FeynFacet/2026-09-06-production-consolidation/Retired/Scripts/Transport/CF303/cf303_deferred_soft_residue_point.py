#!/usr/bin/env python3
"""Pointwise soft residue of the accepted CF303 deferred final layer.

The accepted K deck, recurrence cross-K output, and block-1 point resolver are
reduced separately at u=2 p and then added by (epsilon order, row, column).
Only polynomial coefficient arrays are touched; no symbolic connection or H/K
matrix is materialized.  The elliptic channel is retained as the coefficient
of du/Y until the physical endpoint sheet is supplied.
"""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from fractions import Fraction
import importlib.util
import json
from math import comb
from pathlib import Path
import sys
import time
from typing import Any


REPOSITORY = Path(__file__).resolve().parents[3]
DEFAULT_SCRATCH = REPOSITORY.parent / "factorization-and-loops-codex"
ORDERS = tuple(range(-3, 5))


class EndpointResidueError(RuntimeError):
    """Typed failure of the compact point-residue construction."""

    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise EndpointResidueError("DeferredEvaluatorUnavailable", path=str(path))
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def trim(polynomial: list[int] | tuple[int, ...], prime: int) -> list[int]:
    result = [coefficient % prime for coefficient in polynomial]
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    return result or [0]


def polynomial_value(polynomial: list[int] | tuple[int, ...],
                     point: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(polynomial):
        result = (result * point + coefficient) % prime
    return result


def divide_by_linear(polynomial: list[int], root: int,
                     prime: int) -> tuple[list[int], int]:
    polynomial = trim(polynomial, prime)
    if len(polynomial) == 1:
        return [0], polynomial[0]
    quotient = [0] * (len(polynomial) - 1)
    quotient[-1] = polynomial[-1]
    for index in range(len(quotient) - 1, 0, -1):
        quotient[index - 1] = (
            polynomial[index] + root * quotient[index]
        ) % prime
    remainder = (polynomial[0] + root * quotient[0]) % prime
    return trim(quotient, prime), remainder


def strip_vanishing(polynomial: list[int] | tuple[int, ...], point: int,
                    prime: int) -> tuple[int | None, list[int]]:
    reduced = trim(polynomial, prime)
    if reduced == [0]:
        return None, reduced
    order = 0
    while polynomial_value(reduced, point, prime) == 0:
        reduced, remainder = divide_by_linear(reduced, point, prime)
        if remainder:
            raise EndpointResidueError("EndpointPolynomialDivisionFailed")
        order += 1
    return order, reduced


def vanishing_data(polynomial: list[int] | tuple[int, ...], point: int,
                   prime: int) -> tuple[int | None, int]:
    order, reduced = strip_vanishing(polynomial, point, prime)
    if order is None:
        return None, 0
    return order, polynomial_value(reduced, point, prime)


def rational_function_residue(record: dict[str, list[int]], point: int,
                              prime: int) -> int:
    numerator_order, numerator_lead = vanishing_data(
        record["numerator"], point, prime
    )
    denominator_order, denominator_lead = vanishing_data(
        record["denominator"], point, prime
    )
    if denominator_order is None:
        raise EndpointResidueError("EndpointZeroDenominatorPolynomial")
    if numerator_order is None:
        return 0
    pole_order = denominator_order - numerator_order
    if pole_order > 1:
        raise EndpointResidueError(
            "EndpointHigherOrderPole", pole_order=pole_order
        )
    if pole_order != 1:
        return 0
    return numerator_lead * pow(denominator_lead, -1, prime) % prime


def shifted_coefficients(polynomial: list[int], point: int, count: int,
                         prime: int) -> list[int]:
    return [sum(coefficient * comb(degree, order) *
                pow(point, degree - order, prime)
                for degree, coefficient in enumerate(polynomial)
                if degree >= order) % prime
            for order in range(count)]


def rational_function_local_data(rf: Any, point: int, prime: int,
                                 through_power: int = -1
                                 ) -> dict[str, Any] | None:
    numerator_order, numerator = strip_vanishing(rf.numerator, point, prime)
    denominator_order, denominator = strip_vanishing(
        rf.denominator, point, prime
    )
    if denominator_order is None:
        raise EndpointResidueError("EndpointZeroDenominatorPolynomial")
    if numerator_order is None:
        return None
    valuation = numerator_order - denominator_order
    count = max(1, through_power - valuation + 1)
    numerator_series = shifted_coefficients(numerator, point, count, prime)
    denominator_series = shifted_coefficients(
        denominator, point, count, prime
    )
    inverse_lead = pow(denominator_series[0], -1, prime)
    quotient = []
    for order in range(count):
        correction = sum(denominator_series[index] * quotient[order - index]
                         for index in range(1, order + 1))
        quotient.append((numerator_series[order] - correction) *
                        inverse_lead % prime)
    def rho_coefficient(power: int, coefficient: int) -> int:
        return (-coefficient if power % 2 else coefficient) % prime
    coefficients = {
        valuation + order: rho_coefficient(
            valuation + order, coefficient
        )
        for order, coefficient in enumerate(quotient)
        if valuation + order <= through_power and coefficient
    }
    return {
        "valuation": valuation,
        "leading": rho_coefficient(valuation, quotient[0]),
        "principal": {power: value for power, value in coefficients.items()
                      if power < 0},
        "finite": coefficients.get(0, 0),
        "positive": {power: value for power, value in coefficients.items()
                     if power > 0},
    }


def function_pair_local_data(pair: Any, point: int, prime: int,
                             through_power: int = -1
                             ) -> dict[str, Any] | None:
    channels = ("rational", "elliptic_y_coefficient")
    components = {
        (channel, extension): rational_function_local_data(
            pair[channel_index][extension], point, prime, through_power
        )
        for channel_index, channel in enumerate(channels)
        for extension in range(2)
    }
    populated = [value for value in components.values() if value is not None]
    if not populated:
        return None
    valuation = min(value["valuation"] for value in populated)
    leading = {
        channel: [
            (components[channel, extension]["leading"]
             if components[channel, extension] is not None and
             components[channel, extension]["valuation"] == valuation else 0)
            for extension in range(2)
        ]
        for channel in channels
    }
    powers = sorted({power for value in populated
                     for power in value["principal"]})
    principal = [{
        "rho_power": power,
        **{
            channel: [
                (components[channel, extension]["principal"].get(power, 0)
                 if components[channel, extension] is not None else 0)
                for extension in range(2)
            ]
            for channel in channels
        },
    } for power in powers]
    positive_powers = sorted({power for value in populated
                              for power in value["positive"]})
    positive = [{
        "rho_power": power,
        **{
            channel: [
                (components[channel, extension]["positive"].get(power, 0)
                 if components[channel, extension] is not None else 0)
                for extension in range(2)
            ]
            for channel in channels
        },
    } for power in positive_powers]
    finite = {
        channel: [
            (components[channel, extension]["finite"]
             if components[channel, extension] is not None else 0)
            for extension in range(2)
        ]
        for channel in channels
    }
    return {"valuation": valuation, "leading": leading,
            "principal": principal, "finite": finite,
            "positive": positive}


def zero_value() -> dict[str, list[int]]:
    return {"rational": [0, 0], "elliptic_numerator": [0, 0]}


def add_value(left: dict[str, list[int]], right: dict[str, list[int]],
              prime: int) -> dict[str, list[int]]:
    return {
        channel: [
            (left[channel][extension] + right[channel][extension]) % prime
            for extension in range(2)
        ]
        for channel in ("rational", "elliptic_numerator")
    }


def scale_value(value: dict[str, list[int]], coefficient: int,
                prime: int) -> dict[str, list[int]]:
    return {
        channel: [coefficient * component % prime
                  for component in value[channel]]
        for channel in ("rational", "elliptic_numerator")
    }


def nonzero(value: dict[str, list[int]]) -> bool:
    return any(value[channel] != [0, 0]
               for channel in ("rational", "elliptic_numerator"))


def scalar_expression(raw: str, evaluator: Any, helper: Any,
                      prime: int, p_value: int):
    parsed = evaluator.ModularExpressionParser(raw, prime, p_value).parse()
    return evaluator.bi_expression_to_rf(parsed, helper)


def letter_residue(label: list[Any], evaluator: Any, helper: Any,
                   prime: int, p_value: int,
                   endpoint: int) -> dict[str, list[int]]:
    head = label[0] if label else None
    if head in ("E4Omega0", "E4OmegaInf", "E4Eta2"):
        return zero_value()
    if head in ("GPLPole", "E4Pole") and len(label) == 2:
        point = scalar_expression(label[1], evaluator, helper,
                                  prime, p_value)
        if len(point.numerator) != 1 or len(point.denominator) != 1:
            raise EndpointResidueError(
                "EndpointPolePointDependsOnPath", label=label
            )
        point_value = point.evaluate(endpoint)
        if point_value != endpoint:
            return zero_value()
        # E4Pole is normalized by Y(point), so its endpoint residue is one.
        return {"rational": [1, 0], "elliptic_numerator": [0, 0]}
    if head in ("GPLFactor", "E4Factor") and len(label) == 3:
        power = int(label[2])
        if power < 0:
            raise EndpointResidueError("EndpointLetterMalformed", label=label)
        kernel = scalar_expression(
            f"u^{power}/({label[1]})", evaluator, helper, prime, p_value
        )
        residue = rational_function_residue({
            "numerator": list(kernel.numerator),
            "denominator": list(kernel.denominator),
        }, endpoint, prime)
        if head == "GPLFactor":
            return {"rational": [residue, 0],
                    "elliptic_numerator": [0, 0]}
        return {"rational": [0, 0],
                "elliptic_numerator": [residue, 0]}
    raise EndpointResidueError("EndpointLetterNotSupported", label=label)


@dataclass
class Contribution:
    values: dict[tuple[int, int, int], dict[str, list[int]]]
    sources: dict[tuple[int, int, int], set[str]]

    @classmethod
    def empty(cls) -> "Contribution":
        return cls({}, {})

    def add(self, key: tuple[int, int, int], value: dict[str, list[int]],
            source: str, prime: int) -> None:
        if not nonzero(value):
            return
        self.values[key] = add_value(self.values.get(key, zero_value()),
                                     value, prime)
        self.sources.setdefault(key, set()).add(source)
        if not nonzero(self.values[key]):
            del self.values[key]
            del self.sources[key]


def accepted_k_contributions(inputs: dict[str, Any], evaluator: Any,
                             helper: Any, prime: int, p_value: int,
                             endpoint: int) -> tuple[Contribution, dict[str, int]]:
    result = Contribution.empty()
    counts = {"base": 0, "exceptions": 0}
    residue_cache: dict[tuple[Any, ...], dict[str, list[int]]] = {}
    for entry_index, entry in enumerate(inputs["entries"], 1):
        target, source = map(int, entry[0])
        component = "exceptions" if 77 <= entry_index <= 88 else "base"
        for coefficient_raw, labelled_kernel in entry[3]:
            label = labelled_kernel[0]
            label_key = tuple(label)
            residue = residue_cache.get(label_key)
            if residue is None:
                residue = letter_residue(
                    label, evaluator, helper, prime, p_value, endpoint
                )
                residue_cache[label_key] = residue
            if not nonzero(residue):
                continue
            try:
                coefficient = evaluator.ModularExpressionParser(
                    coefficient_raw, prime, p_value
                ).parse()
            except ValueError as error:
                raise EndpointResidueError(
                    "ActiveEndpointCoefficientNotPointEvaluable",
                    entry_index=entry_index, label=label, cause=str(error),
                ) from error
            windows = evaluator.laurent_coefficients(
                coefficient, helper, low=ORDERS[0], high=ORDERS[-1]
            )
            for order, coefficient_rf in windows.items():
                if (len(coefficient_rf.numerator) != 1 or
                        len(coefficient_rf.denominator) != 1):
                    raise EndpointResidueError(
                        "ActiveEndpointCoefficientDependsOnPath",
                        entry_index=entry_index, label=label,
                    )
                value = scale_value(
                    residue, coefficient_rf.evaluate(endpoint), prime
                )
                if nonzero(value):
                    result.add((order, target, source), value,
                               component, prime)
                    counts[component] += 1
    return result, counts


def serialized_extension_residue(extension: dict[str, Any], endpoint: int,
                                 prime: int) -> list[int]:
    return [rational_function_residue(extension[name], endpoint, prime)
            for name in ("base", "omega")]


def cross_k_contributions(adapter_point: dict[str, Any], endpoint: int,
                          prime: int) -> tuple[Contribution, int]:
    result = Contribution.empty()
    count = 0
    for record in adapter_point["cross_k_outputs"]:
        value = {
            "rational": serialized_extension_residue(
                record["pair"]["rational"], endpoint, prime
            ),
            "elliptic_numerator": serialized_extension_residue(
                record["pair"]["elliptic"], endpoint, prime
            ),
        }
        if nonzero(value):
            result.add((record["order"], record["target_master"],
                        record["source_master"]), value, "cross_k", prime)
            count += 1
    return result, count


def block1_contributions(block1_point: dict[str, Any], endpoint: int,
                         prime: int) -> tuple[Contribution, int]:
    result = Contribution.empty()
    count = 0
    for record in block1_point["outputs"]:
        elliptic = record["k_elliptic"]
        value = {
            "rational": [rational_function_residue(
                record["k_rational"], endpoint, prime
            ), 0],
            "elliptic_numerator": [rational_function_residue({
                "numerator": elliptic["proper_numerator"],
                "denominator": elliptic["denominator"],
            }, endpoint, prime), 0],
        }
        if nonzero(value):
            result.add((record["order"], 43 + record["row"], 1),
                       value, "block1", prime)
            count += 1
    return result, count


def deserialize_rf(record: dict[str, list[int]], evaluator: Any,
                   helper: Any, prime: int):
    return evaluator.RationalFunction.make(
        record["numerator"], record["denominator"], prime, helper
    )


def deserialize_extension(record: dict[str, Any], evaluator: Any,
                          helper: Any, prime: int):
    return tuple(deserialize_rf(record[name], evaluator, helper, prime)
                 for name in ("base", "omega"))


def deserialize_pair(record: dict[str, Any], evaluator: Any,
                     helper: Any, prime: int):
    return tuple(deserialize_extension(record[name], evaluator, helper, prime)
                 for name in ("rational", "elliptic"))


def physical_endpoint_map(adapter_point: dict[str, Any], inputs: dict[str, Any],
                          evaluator: Any, helper: Any, prime: int,
                          p_value: int, endpoint: int) -> dict[str, Any]:
    gauge = evaluator.parse_physical_gauge(
        inputs["gauge"], p_value, prime, helper
    )
    h_values = {
        (record["order"], record["row"] - 1, record["source_master"]):
            deserialize_pair(record["pair"], evaluator, helper, prime)
        for record in adapter_point["h_outputs"]
    }
    if len(h_values) != 112:
        raise EndpointResidueError("DeferredHPointLayoutInvalid")

    raw_h_valuations = Counter()
    for pair in h_values.values():
        local = function_pair_local_data(pair, endpoint, prime)
        if local is not None:
            raw_h_valuations[local["valuation"]] += 1

    source_entries = []
    source_valuations = Counter()
    source_orders = range(min(gauge) + min(ORDERS),
                          max(gauge) + max(ORDERS) + 1)
    for order in source_orders:
        for target_row in range(2):
            for source_master in adapter_point["support_source_masters"]:
                value = evaluator.zero_pair(prime)
                for gauge_order, matrix in gauge.items():
                    h_order = order - gauge_order
                    if (h_order, 0, source_master) not in h_values:
                        continue
                    for middle in range(2):
                        h_pair = h_values[h_order, middle, source_master]
                        value = tuple(evaluator.ext_add(
                            value[channel], evaluator.ext_multiply(
                                matrix[target_row][middle], h_pair[channel],
                                helper
                            ), helper
                        ) for channel in range(2))
                local = function_pair_local_data(
                    value, endpoint, prime, through_power=0
                )
                if local is None:
                    continue
                source_valuations[local["valuation"]] += 1
                source_entries.append({
                    "order": order,
                    "target_master": adapter_point["target_rows"][target_row],
                    "source_master": source_master,
                    **local,
                })

    final_entries = []
    final_valuations = Counter()
    zero_extension = evaluator.ext_zero(prime)
    for order, matrix in sorted(gauge.items()):
        for target_row in range(2):
            for source_row in range(2):
                pair = (matrix[target_row][source_row], zero_extension)
                local = function_pair_local_data(
                    pair, endpoint, prime, through_power=0
                )
                if local is None:
                    continue
                final_valuations[local["valuation"]] += 1
                final_entries.append({
                    "order": order,
                    "target_master": adapter_point["target_rows"][target_row],
                    "source_master": adapter_point["target_rows"][source_row],
                    **local,
                })

    elliptic_nonzero = sum(
        entry["leading"]["elliptic_y_coefficient"] != [0, 0] or
        any(term["elliptic_y_coefficient"] != [0, 0]
            for term in entry["principal"])
        for entry in source_entries + final_entries
    )
    principal_counts = Counter(
        term["rho_power"] for entry in source_entries
        for term in entry["principal"]
    )
    return {
        "status": "CF303PhysicalEndpointMapPointV1",
        "relation": "I25=T25*(G25+H*F_source)",
        "column_blocks": ["T25*H", "T25"],
        "source_epsilon_order_window": [min(source_orders), max(source_orders)],
        "final_epsilon_order_window": [min(gauge), max(gauge)],
        "support_source_masters": adapter_point["support_source_masters"],
        "raw_h_valuation_counts": {
            str(key): raw_h_valuations[key] for key in sorted(raw_h_valuations)
        },
        "source_valuation_counts": {
            str(key): source_valuations[key] for key in sorted(source_valuations)
        },
        "final_valuation_counts": {
            str(key): final_valuations[key] for key in sorted(final_valuations)
        },
        "source_principal_term_counts": {
            str(key): principal_counts[key] for key in sorted(principal_counts)
        },
        "maximum_source_pole_order": max(
            0, -min(source_valuations, default=0)
        ),
        "source_nonzero_coordinate_count": len(source_entries),
        "source_zero_coordinate_count": len(source_orders) * 2 * len(
            adapter_point["support_source_masters"]
        ) - len(source_entries),
        "final_nonzero_coordinate_count": len(final_entries),
        "final_zero_coordinate_count": len(gauge) * 4 - len(final_entries),
        "elliptic_y_nonzero_coordinate_count": elliptic_nonzero,
        "source_entries": source_entries,
        "final_entries": final_entries,
    }


def merge_contributions(parts: list[Contribution], prime: int) -> Contribution:
    result = Contribution.empty()
    for part in parts:
        for key, value in part.values.items():
            combined = add_value(result.values.get(key, zero_value()),
                                 value, prime)
            if nonzero(combined):
                result.values[key] = combined
                result.sources.setdefault(key, set()).update(part.sources[key])
            else:
                result.values.pop(key, None)
                result.sources.pop(key, None)
    return result


def suffix(p: Fraction) -> str:
    return f"p{p.numerator}d{p.denominator}"


def build_point_payload(scratch: Path, p: Fraction,
                        adapter_path: Path | None = None,
                        block1_path: Path | None = None) -> dict[str, Any]:
    total_started = time.perf_counter()
    stage_started = total_started
    evaluator_path = scratch / (
        "Diagnostics/Scripts/cf303_hybrid_baseline_modular_circuit.py"
    )
    evaluator = load_module("cf303_soft_residue_evaluator", evaluator_path)
    evaluator_seconds = time.perf_counter() - stage_started
    runtime = scratch / "Runtime/2026-08-31_cf303_native_dlog_residues"
    adapter_path = adapter_path or runtime / (
        f"cf303_hybrid_baseline_lazy_adapter_q7_{suffix(p)}.json"
    )
    adapter_point = json.loads(adapter_path.read_text())
    prime = int(adapter_point["prime"])
    block1_path = block1_path or runtime / (
        f"cf303_block1_circuit_resolved_q{prime}_{suffix(p)}.json"
    )
    block1_point = json.loads(block1_path.read_text())
    input_seconds = time.perf_counter() - total_started - evaluator_seconds
    expected_p = [p.numerator, p.denominator]
    if (adapter_point.get("status") !=
            "CF303HybridBaselineLazyAdapterPointV1" or
        block1_point.get("status") !=
            "CF303Block1CircuitPointResolutionAcceptedV1" or
        adapter_point.get("p") != expected_p or
        block1_point.get("p") != expected_p or
        block1_point.get("prime") != prime or
        len(adapter_point.get("cross_k_outputs", [])) != 98 or
        len(block1_point.get("outputs", [])) != 16):
        raise EndpointResidueError("DeferredPointInputsNotAligned")

    stage_started = time.perf_counter()
    helper = evaluator.load_module(
        "cf303_soft_residue_rational_helper", evaluator.RATIONAL_HELPER
    )
    inputs = evaluator.parse_inputs()
    accepted_input_seconds = time.perf_counter() - stage_started
    p_value = p.numerator % prime * pow(p.denominator % prime, -1, prime) % prime
    endpoint = 2 * p_value % prime
    curve_value = 64 * p_value * p_value * (1 - p_value * p_value) % prime
    if curve_value == 0:
        raise EndpointResidueError("EllipticCurveDegeneratesAtEndpoint")

    stage_started = time.perf_counter()
    accepted, accepted_counts = accepted_k_contributions(
        inputs, evaluator, helper, prime, p_value, endpoint
    )
    accepted_seconds = time.perf_counter() - stage_started
    stage_started = time.perf_counter()
    cross, cross_count = cross_k_contributions(
        adapter_point, endpoint, prime
    )
    block1, block1_count = block1_contributions(
        block1_point, endpoint, prime
    )
    combined = merge_contributions([accepted, cross, block1], prime)
    deferred_seconds = time.perf_counter() - stage_started
    stage_started = time.perf_counter()
    endpoint_map = physical_endpoint_map(
        adapter_point, inputs, evaluator, helper, prime, p_value, endpoint
    )
    endpoint_map_seconds = time.perf_counter() - stage_started
    entries = [{
        "order": key[0], "target_master": key[1], "source_master": key[2],
        **combined.values[key], "sources": sorted(combined.sources[key]),
    } for key in sorted(combined.values)]
    elliptic_nonzero = sum(
        entry["elliptic_numerator"] != [0, 0] for entry in entries
    )
    omega_nonzero = sum(entry["rational"][1] != 0 or
                        entry["elliptic_numerator"][1] != 0
                        for entry in entries)
    return {
        "status": "CF303DeferredSoftResiduePointV1",
        "abi_version": 1,
        "prime": prime,
        "p": expected_p,
        "endpoint": {
            "variable": "u", "exact": "2*p", "value": endpoint,
            "inward_coordinate": "rho=2*p-u",
        },
        "curve_endpoint": {
            "exact": "64*p^2*(1-p^2)", "value": curve_value,
            "elliptic_channel": "elliptic_numerator/Y(endpoint)",
            "sheet_status": "RetainedUntilPhysicalEndpointSheetIsSupplied",
        },
        "basis": "AcceptedPathGaugeG25FinalLayer",
        "gauge_relation": "F25=G25+H*L",
        "scope": "Rows44And45AgainstSourceRows;SourceDiagonalResidueIsSeparate",
        "epsilon_order_window": [ORDERS[0], ORDERS[-1]],
        "target_rows": adapter_point["target_rows"],
        "source_rows": adapter_point["source_rows"],
        "contribution_counts": {
            "base": accepted_counts["base"],
            "exceptions": accepted_counts["exceptions"],
            "cross_k": cross_count,
            "block1": block1_count,
        },
        "combined_nonzero_coordinate_count": len(entries),
        "coefficient_field_usage": {
            "omega_nonzero_coordinate_count": omega_nonzero,
            "elliptic_nonzero_coordinate_count": elliptic_nonzero,
            "rational_base_only": omega_nonzero == 0 and elliptic_nonzero == 0,
        },
        "timings_seconds": {
            "evaluator_import": evaluator_seconds,
            "point_input_load": input_seconds,
            "accepted_deck_parse": accepted_input_seconds,
            "accepted_deck_residue": accepted_seconds,
            "cross_k_and_block1_residue": deferred_seconds,
            "physical_endpoint_map": endpoint_map_seconds,
            "total": time.perf_counter() - total_started,
        },
        "physical_endpoint_map": endpoint_map,
        "residue_entries": entries,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scratch", type=Path, default=DEFAULT_SCRATCH)
    parser.add_argument("--p", type=Fraction, default=Fraction(3))
    parser.add_argument("--adapter-point", type=Path)
    parser.add_argument("--block1-point", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        payload = build_point_payload(
            args.scratch, args.p, args.adapter_point, args.block1_point
        )
    except (EndpointResidueError, FileNotFoundError, ZeroDivisionError) as error:
        if isinstance(error, EndpointResidueError):
            failure = {"status": error.status, **error.details}
        else:
            failure = {"status": type(error).__name__, "message": str(error)}
        print(json.dumps(failure, sort_keys=True))
        return 2
    encoded = json.dumps(payload, indent=2) + "\n"
    if args.output:
        args.output.write_text(encoded)
        print(json.dumps({
            "status": payload["status"],
            "output": str(args.output),
            "counts": payload["contribution_counts"],
            "combined": payload["combined_nonzero_coordinate_count"],
        }, sort_keys=True))
    else:
        print(encoded, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
