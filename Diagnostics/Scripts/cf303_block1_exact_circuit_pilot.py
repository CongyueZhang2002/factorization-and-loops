#!/usr/bin/env python3
"""Concrete exact-circuit ABI and modular replay for CF303 (25,1).

The representative circuit is H_-2/K_-2 in rational source column 1,
target row 1.  Its large exact deferred connection remains an immutable leaf;
the circuit keeps the path compiler and sealed Hermite split as fixed
operations instead of expanding high-height bivariate coefficients.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import time
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
OUT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
SOURCE = ROOT / (
    "Runtime/2026-08-30_cf303_25_2_exact_common_path/resume/"
    "sector_CF303_standard/CF303_25_1_input.wl"
)
DIAGONAL = OUT / "cf303_block1_finite_gauge_inputs.json"
PILOT = ROOT / "Diagnostics/Scripts/cf303_block1_modular_finite_gauge_pilot.py"
DECK = ROOT / "Diagnostics/Scripts/cf303_nested_laurent_deck.py"
PROFILE_DIR = OUT / "block1_modular_finite_gauge_record2"
Q7_FIXED = OUT / "cf303_block1_circuit_q7_p3_fixed_epsilon.json"
PRIMES = (
    2_305_843_009_213_691_819, 2_305_843_009_213_641_971,
    2_305_843_009_213_693_951, 2_305_843_009_213_693_921,
    2_305_843_009_213_693_907, 2_305_843_009_213_693_723,
)
Q7 = 2_305_843_009_213_693_693
CHANNELS = ("1,1,rational", "2,1,rational")
FIELDS = ("h_numerator", "h_denominator", "k_numerator", "k_denominator")


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def polynomial_value(coefficients: list[int], value: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * value + coefficient) % prime
    return result


def profile_value(profile: dict[str, Any], value: int, prime: int) -> int:
    numerator = polynomial_value(profile["numerator"], value, prime)
    denominator = polynomial_value(profile["denominator"], value, prime)
    return numerator * pow(denominator, prime - 2, prime) % prime


def flatten(record: dict[str, Any]) -> list[int]:
    return [value for field in FIELDS for value in record[field]]


def manifest() -> dict[str, Any]:
    path_map = {
        "k": "4*p*(1-p)", "a": "(k-2*u)/(u^2+k)",
        "x": "-a*p", "y": "(1-a)*(1-p)",
        "root_delta2": "a-p", "root_delta3": "1+u*a",
        "residual_root": "sqrt(1-2*x+x^2+2*y+2*x*y+y^2)",
        "sheet_projection": "rational=(plus+minus)/2",
    }
    nodes = [
        {"id": 0, "kind": "leaf", "type": "ExactDeferredInput",
         "path": str(SOURCE)},
        {"id": 1, "kind": "leaf", "type": "ExactPathFactors",
         "value": path_map},
        {"id": 2, "kind": "leaf", "type": "HermiteSourceComponent",
         "source": 0, "path_map": 1, "row": 1, "order": -3,
         "channel": "rational", "normalize_base": [1, 2]},
        {"id": 3, "kind": "leaf", "type": "HermiteSourceComponent",
         "source": 0, "path_map": 1, "row": 2, "order": -3,
         "channel": "rational", "normalize_base": [1, 2]},
        {"id": 4, "kind": "leaf", "type": "HermiteSourceComponent",
         "source": 0, "path_map": 1, "row": 1, "order": -2,
         "channel": "rational", "normalize_base": [1, 2]},
        {"id": 5, "kind": "leaf", "type": "ExactRational", "source": str(DIAGONAL),
         "selector": ["d", 1, 1]},
        {"id": 6, "kind": "leaf", "type": "ExactRational", "source": str(DIAGONAL),
         "selector": ["d", 1, 2]},
        {"id": 7, "kind": "leaf", "type": "ExactRational", "source": str(DIAGONAL),
         "selector": ["s11"]},
        {"id": 8, "kind": "leaf", "type": "ExactInteger", "value": -1},
        {"id": 9, "kind": "op", "op": "Mul", "args": [5, [2, "primitive"]]},
        {"id": 10, "kind": "op", "op": "Mul", "args": [6, [3, "primitive"]]},
        {"id": 11, "kind": "op", "op": "Mul", "args": [7, [2, "primitive"]]},
        {"id": 12, "kind": "op", "op": "Mul", "args": [8, 11]},
        {"id": 13, "kind": "op", "op": "Add", "args": [9, 10]},
        {"id": 14, "kind": "op", "op": "Add", "args": [13, 12]},
        {"id": 15, "kind": "op", "op": "FixedRationalHermiteSplit",
         "arg": 14, "normalize_base": [1, 2]},
        {"id": 16, "kind": "op", "op": "Add",
         "args": [[4, "primitive"], [15, "primitive"]]},
        {"id": 17, "kind": "op", "op": "Add",
         "args": [[4, "remainder"], [15, "remainder"]]},
        {"id": 18, "kind": "leaf", "type": "AcceptedEllipticBaseline",
         "channel": "Y0(p)", "assembly": "separate; add node 16 as rational deltaH"},
    ]
    return {
        "status": "CF303Block1ExactArithmeticCircuitV1",
        "block": [25, 1], "representative": {"order": -2, "row": 1},
        "abi": {
            "arithmetic_ops": ["Add", "Mul", "Inv"],
            "sealed_op": "FixedRationalHermiteSplit",
            "source_component": (
                "Exact deferred pullback + conjugate rational projection + "
                "epsilon Laurent selection + sealed Hermite component"
            ),
        },
        "nodes": nodes, "outputs": {"delta_h": 16, "delta_k": 17},
        "assembly_contract": (
            "Preserve the accepted exact elliptic/Y0 baseline and add the "
            "rational deltaH output; this circuit does not replace full H."
        ),
        "exact_leaf_bytes": SOURCE.stat().st_size,
    }


def make_q7_deck(
    fixed: dict[str, Any], deck_module, source_path: Path = Q7_FIXED,
) -> dict[str, Any]:
    if fixed.get("status") != "CF303FixedPEpsilonLiftAcceptedV1":
        raise RuntimeError("fresh-q fixed-p source lift is not accepted")
    profiles = []
    for coordinate in fixed["lifted_coordinates"]:
        if (coordinate["channel"] not in CHANNELS
                or coordinate["field"] not in
                {"primitive_numerator", "remainder_numerator"}):
            continue
        for order in range(-3, 5):
            value = deck_module.laurent_coefficient(
                coordinate["numerator"], coordinate["denominator"], order, Q7
            )
            profiles.append({
                "key": ["laurent_profile", coordinate["channel"],
                        coordinate["field"], coordinate["index"], order],
                "numerator": [value], "denominator": [1],
                "numerator_degree": 0 if value else -1,
                "denominator_degree": 0, "total_degree": 0,
            })
    if len(profiles) != 1008:
        raise RuntimeError(f"fresh-q rational Laurent layout {len(profiles)}/1008")
    return {
        "status": "CF303Block1ModularLaurentDeckAcceptedV1",
        "block": [25, 1], "prime": Q7, "requested_orders": list(range(-3, 5)),
        "coordinate_count": 126, "profile_count": len(profiles),
        "source": str(source_path), "source_p": fixed["p"],
        "profiles": profiles, "wall_seconds": 0.0,
    }


def circuit_record(pilot, context, p: Fraction) -> tuple[dict[str, Any], float]:
    started = time.perf_counter()
    prime, helper = context["prime"], context["helper"]
    p_value = pilot.exact_fraction_mod(p, prime)
    base = pilot.exact_fraction_mod(Fraction(*context["inputs"]["base_point"]), prime)

    def incoming(channel: str, field: str, order: int):
        keys = [key for key in context["deck_map"]
                if key[:3] == ("laurent_profile", channel, field)
                and key[4] == order]
        indices = sorted(int(key[3]) for key in keys)
        numerator = [pilot.profile_value(
            context["deck_map"][("laurent_profile", channel, field, index, order)],
            p_value, prime,
        ) for index in indices]
        denominator_field = ("primitive_denominator"
                             if field == "primitive_numerator"
                             else "remainder_denominator")
        denominator = context["denominator"](channel, denominator_field, p_value)
        return pilot.RationalFunction.make(numerator, denominator, prime, helper)

    h_previous = []
    for channel in CHANNELS:
        primitive = incoming(channel, "primitive_numerator", -3)
        h_previous.append(primitive.add(
            pilot.RationalFunction.constant(primitive.evaluate(base), prime),
            helper, -1,
        ))
    inputs = context["inputs"]
    diagonal = [[context["input_function"](entry, p_value) for entry in row]
                for row in inputs["d"]]
    s11 = context["input_function"](inputs["s11"], p_value)
    cross = diagonal[0][0].multiply(h_previous[0], helper)
    cross = cross.add(diagonal[0][1].multiply(h_previous[1], helper), helper)
    cross = cross.add(h_previous[0].multiply(s11, helper), helper, -1)
    cross_primitive, cross_remainder = pilot.hermite(cross, helper)
    source_primitive = incoming(CHANNELS[0], "primitive_numerator", -2)
    h_value = source_primitive.add(cross_primitive, helper)
    h_value = h_value.add(
        pilot.RationalFunction.constant(h_value.evaluate(base), prime), helper, -1
    )
    k_value = incoming(CHANNELS[0], "remainder_numerator", -2).add(
        cross_remainder, helper
    )
    record = {
        "order": -2, "row": 1,
        "h_numerator": list(h_value.numerator),
        "h_denominator": list(h_value.denominator),
        "k_numerator": list(k_value.numerator),
        "k_denominator": list(k_value.denominator),
    }
    return record, time.perf_counter() - started


def expected_profile_record(artifact: dict[str, Any], p: int) -> dict[str, Any]:
    prime = artifact["prime"]
    fields: dict[str, dict[int, int]] = {field: {} for field in FIELDS}
    for profile in artifact["profiles"]:
        key = profile["key"]
        if key[1:3] != [-2, 1]:
            continue
        fields[key[3]][int(key[4])] = profile_value(profile, p % prime, prime)
    return {
        "order": -2, "row": 1,
        **{field: [values[index] for index in range(len(values))]
           for field, values in fields.items()},
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path,
                        default=OUT / "cf303_block1_exact_circuit_nminus2_row1.json")
    parser.add_argument("--report", type=Path,
                        default=OUT / "cf303_block1_exact_circuit_validation.json")
    args = parser.parse_args()
    pilot = load_module("cf303_exact_circuit_pilot", PILOT)
    deck_module = load_module("cf303_exact_circuit_deck", DECK)
    build_started = time.perf_counter()
    circuit = manifest()
    circuit["build_seconds"] = time.perf_counter() - build_started
    args.manifest.write_text(json.dumps(circuit, indent=2) + "\n")

    comparisons = 0
    per_prime = []
    for prime in PRIMES:
        artifact = json.loads((PROFILE_DIR /
            f"cf303_block1_finite_gauge_profiles_q{prime}.json").read_text())
        context_started = time.perf_counter()
        context = pilot.load_context(prime)
        context_seconds = time.perf_counter() - context_started
        actual, evaluation_seconds = circuit_record(pilot, context, Fraction(3))
        expected = expected_profile_record(artifact, 3)
        if flatten(actual) != flatten(expected):
            raise RuntimeError(f"circuit/profile mismatch at q={prime}")
        comparisons += len(flatten(actual))
        per_prime.append({
            "prime": prime, "comparisons": len(flatten(actual)),
            "context_seconds": context_seconds,
            "circuit_evaluation_seconds": evaluation_seconds,
        })

    fixed = json.loads(Q7_FIXED.read_text())
    q7_deck = make_q7_deck(fixed, deck_module)
    q7_deck_path = OUT / "block1_modular_laurent_decks" / (
        f"cf303_block1_laurent_deck_q{Q7}.json"
    )
    q7_deck_path.write_text(json.dumps(q7_deck, indent=2) + "\n")
    q7_context = pilot.load_context(Q7)
    q7_circuit, q7_seconds = circuit_record(pilot, q7_context, Fraction(3))
    q7_reference_report = pilot.run_point(
        q7_context, Fraction(3), orders=(-3, -2)
    )
    q7_reference = next(record for record in q7_reference_report["records"]
                        if record["order"] == -2 and record["row"] == 1)
    q7_equal = flatten(q7_circuit) == flatten(q7_reference)
    if not q7_equal:
        raise RuntimeError("fresh-q7 circuit/general recurrence mismatch")

    report = {
        "status": "CF303Block1ExactArithmeticCircuitValidatedV1",
        "manifest": str(args.manifest), "node_count": len(circuit["nodes"]),
        "exact_source": str(SOURCE), "exact_source_bytes": SOURCE.stat().st_size,
        "six_q_profile_comparisons": comparisons, "per_prime": per_prime,
        "fresh_q7": {
            "prime": Q7, "p": [3, 1], "raw_source_lift": str(Q7_FIXED),
            "construction_epsilons": len(fixed["construction_epsilons"]),
            "heldout_epsilons": len(fixed["heldout_epsilons"]),
            "compiled_laurent_leaf_values": len(q7_deck["profiles"]),
            "output_coefficient_comparisons": len(flatten(q7_circuit)),
            "equal_to_general_recurrence": q7_equal,
            "circuit_evaluation_seconds": q7_seconds,
        },
        "assembly_contract": circuit["assembly_contract"],
    }
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
