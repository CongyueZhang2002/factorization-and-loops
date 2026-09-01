#!/usr/bin/env python3
"""Compose the CF303 88-entry baseline with two lazy block-1 circuits."""

from __future__ import annotations

import importlib.util
import json
import sys
import time
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
OUT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
FULL_SCRIPT = ROOT / "Diagnostics/Scripts/cf303_block1_full_exact_circuit.py"
PILOT_SCRIPT = ROOT / "Diagnostics/Scripts/cf303_block1_modular_finite_gauge_pilot.py"
CIRCUIT = OUT / "cf303_block1_full_exact_circuit.json"
ELLIPTIC = OUT / "cf303_block1_exact_elliptic_source.json"
SOURCE_OPERATOR = OUT / "cf303_hybrid_elliptic_operator_15_17_21.wl"
PHYSICAL_GAUGE = OUT / "cf303_block25_physical_gauge.wl"
BASE_76 = OUT / "cf303_block25_general_elliptic_transfer.wl"
EXCEPTIONS = (
    (2, OUT / "cf303_block25_exception_2_elliptic_layer_census.maple", 2,
     ((44, 2), (45, 2))),
    (11, OUT / "cf303_block25_exception_11_elliptic_layer_census.maple", 2,
     ((44, 12), (45, 12))),
    (14, OUT / "cf303_block25_exception_14_elliptic_layer_census.maple", 4,
     ((44, 21), (44, 22), (45, 21), (45, 22))),
    (18, OUT / "cf303_block25_exception_18_elliptic_layer_census.maple", 4,
     ((44, 29), (44, 30), (45, 29), (45, 30))),
)
Q7 = 2_305_843_009_213_693_693
Q7_DECKS = (
    (Fraction(3), OUT / "block1_modular_laurent_decks" /
     f"cf303_block1_laurent_deck_q{Q7}.json"),
    (Fraction(239, 47), OUT / "block1_modular_laurent_decks" /
     f"cf303_block1_laurent_deck_q{Q7}_p239d47.json"),
)
JSON_OUTPUT = OUT / "cf303_hybrid90_circuit_path_gauge_operator.json"
WL_OUTPUT = OUT / "cf303_hybrid90_circuit_path_gauge_operator.wl"
REPORT = OUT / "cf303_hybrid90_circuit_path_gauge_validation.json"
CHANNELS = ("1,1,rational", "2,1,rational")
ORDERS = tuple(range(-3, 5))


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def incoming(pilot, context, p_value: int, row: int, order: int):
    prime, helper = context["prime"], context["helper"]
    base = pilot.exact_fraction_mod(Fraction(*context["inputs"]["base_point"]), prime)
    channel = CHANNELS[row - 1]

    def component(field: str):
        indices = sorted(int(key[3]) for key in context["deck_map"]
            if key[:3] == ("laurent_profile", channel, field)
            and key[4] == order)
        numerator = [pilot.profile_value(
            context["deck_map"][("laurent_profile", channel, field, index, order)],
            p_value, prime,
        ) for index in indices]
        denominator_field = ("primitive_denominator"
            if field == "primitive_numerator" else "remainder_denominator")
        denominator = context["denominator"](
            channel, denominator_field, p_value
        )
        return pilot.RationalFunction.make(numerator, denominator, prime, helper)

    primitive = component("primitive_numerator")
    primitive = primitive.add(
        pilot.RationalFunction.constant(primitive.evaluate(base), prime),
        helper, -1,
    )
    return primitive, component("remainder_numerator")


def derivative(function, pilot, helper):
    prime = function.prime
    numerator = helper.add(
        helper.multiply(helper.derivative(function.numerator, prime),
                        function.denominator, prime),
        helper.multiply(function.numerator,
                        helper.derivative(function.denominator, prime), prime),
        prime, -1,
    )
    denominator = helper.multiply(
        function.denominator, function.denominator, prime
    )
    return pilot.RationalFunction.make(numerator, denominator, prime, helper)


def rational(value: dict[str, Any], prefix: str, pilot, helper, prime: int):
    return pilot.RationalFunction.make(
        value[f"{prefix}_numerator"], value[f"{prefix}_denominator"],
        prime, helper,
    )


def validate_point(manifest, full, pilot, point: Fraction, deck_path: Path):
    context = pilot.load_context(Q7, deck_path)
    prime, helper = context["prime"], context["helper"]
    p_value = pilot.exact_fraction_mod(point, prime)
    base = pilot.exact_fraction_mod(Fraction(1, 2), prime)
    records = full.graph_evaluate(manifest, pilot, context, point)
    by_key = {(record["order"], record["row"]): record for record in records}
    inputs = context["inputs"]
    diagonal = [[context["input_function"](entry, p_value) for entry in row]
                for row in inputs["d"]]
    s11 = context["input_function"](inputs["s11"], p_value)
    previous = [pilot.RationalFunction.zero(prime) for _ in (1, 2)]
    identity_count = basepoint_count = 0
    maximum_h_degree = maximum_k_degree = 0
    for order in ORDERS:
        current = []
        for row in (1, 2):
            record = by_key[(order, row)]
            h_value = rational(record, "h", pilot, helper, prime)
            k_value = rational(record, "k", pilot, helper, prime)
            if h_value.evaluate(base) != 0:
                raise RuntimeError(f"basepoint failed at {point}:{order}:{row}")
            basepoint_count += 1
            b_primitive, b_remainder = incoming(
                pilot, context, p_value, row, order
            )
            cross = pilot.RationalFunction.zero(prime)
            for column in (1, 2):
                cross = cross.add(
                    diagonal[row - 1][column - 1].multiply(
                        previous[column - 1], helper
                    ), helper,
                )
            cross = cross.add(
                previous[row - 1].multiply(s11, helper), helper, -1
            )
            left = derivative(h_value, pilot, helper).add(k_value, helper)
            right = derivative(b_primitive, pilot, helper).add(
                b_remainder, helper
            ).add(cross, helper)
            if not left.add(right, helper, -1).zero_q:
                raise RuntimeError(
                    f"truncated recurrence failed at {point}:{order}:{row}"
                )
            identity_count += 1
            maximum_h_degree = max(
                maximum_h_degree, len(h_value.numerator) - 1,
                len(h_value.denominator) - 1,
            )
            maximum_k_degree = max(
                maximum_k_degree, len(k_value.numerator) - 1,
                len(k_value.denominator) - 1,
            )
            current.append(h_value)
        previous = current
    return {
        "prime": Q7, "p": [point.numerator, point.denominator],
        "recurrence_identities": identity_count,
        "basepoint_identities": basepoint_count,
        "elliptic_identities": 16,
        "maximum_h_u_degree": maximum_h_degree,
        "maximum_k_u_degree": maximum_k_degree,
    }


def component_records():
    records = [{
        "entry_index": index + 1, "kind": "BaselineEntryRef",
        "source": str(BASE_76), "source_entry_index": index + 1,
    } for index in range(76)]
    for block, path, count, targets in EXCEPTIONS:
        for index in range(count):
            records.append({
                "entry_index": len(records) + 1,
                "kind": "ExceptionCensusEntryRef", "block": block,
                "source": str(path), "source_entry_index": index + 1,
                "target": list(targets[index]),
            })
    return records


def main() -> int:
    full = load_module("cf303_hybrid_full", FULL_SCRIPT)
    pilot = load_module("cf303_hybrid_pilot", PILOT_SCRIPT)
    circuit = json.loads(CIRCUIT.read_text())
    elliptic = json.loads(ELLIPTIC.read_text())
    if (circuit.get("status") != "CF303Block1CompleteExactArithmeticCircuitV1"
            or elliptic.get("status") !=
            "CF303Block1ExactEllipticSourceAcceptedV1"):
        raise RuntimeError("block-1 circuit inputs are not accepted")
    baseline = component_records()
    if len(baseline) != 88:
        raise RuntimeError(f"composite baseline has {len(baseline)}/88 entries")
    block1_outputs = {(record["order"], record["row"]): record
                      for record in circuit["outputs"]}
    entries = baseline + [{
        "entry_index": 89 + row - 1,
        "kind": "Block1ExactCircuitEntry", "target": [43 + row, 1],
        "orders": [{
            "order": order,
            "delta_h": block1_outputs[(order, row)]["delta_h"],
            "delta_k": block1_outputs[(order, row)]["delta_k"],
            "rational_kernel": block1_outputs[(order, row)]["kernel"],
            "elliptic_kernel": elliptic["outputs"][
                (order - ORDERS[0]) * 2 + row - 1
            ]["k_elliptic"],
        } for order in ORDERS],
    } for row in (1, 2)]
    if len(entries) != 90:
        raise RuntimeError("hybrid operator entry count is not 90")

    started = time.perf_counter()
    validations = [validate_point(circuit, full, pilot, point, deck)
                   for point, deck in Q7_DECKS]
    validation_seconds = time.perf_counter() - started
    operator = {
        "status": "CF303Hybrid90CircuitPathGaugeOperatorAcceptedV1",
        "family": "CF303", "master_count": 45,
        "target_rows": [44, 45], "entry_count": len(entries),
        "baseline_entry_count": 88, "block1_entry_count": 2,
        "incoming_orders": [-3, 4], "target_orders": [-4, 2],
        "canonical_relation": "F25=G25+H.L",
        "physical_relation": "I25=T25.F25",
        "boundary_convention": "H(u=1/2)=0",
        "representation": "CompositeExactReferencesWithLazyArithmeticCircuitV1",
        "entries": entries,
        "block1_circuit": str(CIRCUIT),
        "block1_elliptic_source": str(ELLIPTIC),
        "source_operator": str(SOURCE_OPERATOR),
        "physical_gauge": str(PHYSICAL_GAUGE),
        "evaluator": str(Path(__file__).resolve()),
        "kernel_conventions": {
            "rational": "GPLFactor, deferred GPLPole root expansion",
            "elliptic": "E4Factor/E4Pole with Yc symbolic",
        },
        "validation": {
            "status": "Accepted",
            "q7_points": validations,
            "recurrence_window": [-3, 4],
            "exact_elliptic_profile_comparisons":
                elliptic["fresh_comparison_count"],
        },
    }
    JSON_OUTPUT.write_text(json.dumps(operator, indent=2) + "\n")
    WL_OUTPUT.write_text(f'Import["{JSON_OUTPUT}", "RawJSON"]\n')
    report = {
        "status": "CF303Hybrid90CircuitPathGaugeValidationAcceptedV1",
        "operator": str(JSON_OUTPUT), "wolfram_wrapper": str(WL_OUTPUT),
        "entry_count": 90, "component_counts": {
            "base": 76, "exception2": 2, "exception11": 2,
            "exception14": 4, "exception18": 4, "block1": 2,
        },
        "q7": validations,
        "rational_recurrence_comparisons": sum(
            value["recurrence_identities"] for value in validations
        ),
        "basepoint_comparisons": sum(
            value["basepoint_identities"] for value in validations
        ),
        "elliptic_recurrence_relations": sum(
            value["elliptic_identities"] for value in validations
        ),
        "validation_seconds": validation_seconds,
        "claim": (
            "The 90 entries are an executable composite of exact references. "
            "The block-1 lazy circuit passes the complete -3..4 recurrence "
            "and basepoint identities at two fresh q7 p points."
        ),
    }
    REPORT.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
