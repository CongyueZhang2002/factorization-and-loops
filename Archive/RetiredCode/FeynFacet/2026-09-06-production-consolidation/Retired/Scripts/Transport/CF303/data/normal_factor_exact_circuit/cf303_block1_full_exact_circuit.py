#!/usr/bin/env python3
"""Build and replay the full 16-record exact circuit for CF303 (25,1)."""

from __future__ import annotations

import argparse
import gzip
import importlib.util
import json
import sys
import time
from fractions import Fraction
from pathlib import Path
from typing import Any


BUNDLE = Path(__file__).resolve().parent
REPOSITORY = BUNDLE.parents[5]
SOURCE = BUNDLE / "CF303_25_1_input.wl.gz"
DIAGONAL = BUNDLE / "cf303_block1_finite_gauge_inputs.json"
PILOT = BUNDLE / "cf303_block1_modular_finite_gauge_pilot.py"
DECK_SCRIPT = BUNDLE / "cf303_nested_laurent_deck.py"
BASELINE_76 = BUNDLE / "cf303_hybrid_baseline90_transfer.maple.gz"
EXCEPTION_INPUTS = {
    2: (BASELINE_76, 2), 11: (BASELINE_76, 2),
    14: (BASELINE_76, 4), 18: (BASELINE_76, 4),
}
Q7_FIXED_SECOND = (
    BUNDLE / "cf303_block1_circuit_q7_p239d47_fixed_epsilon.json.gz"
)
ELLIPTIC_SOURCE = BUNDLE / "cf303_block1_exact_elliptic_source.json"
Q7 = 2_305_843_009_213_693_693
PRIMES = (
    2_305_843_009_213_693_967,
    2_305_843_009_213_693_973,
)
ORDERS = tuple(range(-3, 5))
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


def read_json(path: Path) -> dict[str, Any]:
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt") as stream:
        return json.load(stream)


def make_manifest() -> dict[str, Any]:
    nodes: list[dict[str, Any]] = []

    def node(value: dict[str, Any]) -> int:
        identifier = len(nodes)
        nodes.append({"id": identifier, **value})
        return identifier

    source = node({"kind": "leaf", "type": "ExactDeferredInput",
                   "path": SOURCE.name})
    path = node({
        "kind": "leaf", "type": "ExactPathFactors",
        "value": {
            "k": "4*p*(1-p)", "a": "(k-2*u)/(u^2+k)",
            "x": "-a*p", "y": "(1-a)*(1-p)",
            "root_delta2": "a-p", "root_delta3": "1+u*a",
            "residual_root": "sqrt(1-2*x+x^2+2*y+2*x*y+y^2)",
            "rational_projection": "(plus+minus)/2",
        },
    })
    source_nodes = {}
    for order in ORDERS:
        for row in (1, 2):
            source_nodes[(order, row)] = node({
                "kind": "leaf", "type": "HermiteSourceComponent",
                "source": source, "path_map": path, "order": order,
                "row": row, "channel": "rational", "normalize_base": [1, 2],
            })
    diagonal = {}
    for row in (1, 2):
        for column in (1, 2):
            diagonal[(row, column)] = node({
                "kind": "leaf", "type": "ExactRational",
                "source": DIAGONAL.name, "selector": ["d", row, column],
            })
    s11 = node({"kind": "leaf", "type": "ExactRational",
                "source": DIAGONAL.name, "selector": ["s11"]})
    minus_one = node({"kind": "leaf", "type": "ExactInteger", "value": -1})
    baseline = node({
        "kind": "leaf", "type": "CompositeBaselineInputs",
        "base_76": {"path": BASELINE_76.name, "entry_count": 76},
        "exception_inputs": [
            {"block": block, "path": path.name, "entry_count": count}
            for block, (path, count) in EXCEPTION_INPUTS.items()
        ],
        "exception_status": "CF303EllipticLayerExactTransferCensusValidated",
        "composite_entry_count": 88,
        "assembly_status": (
            "The 76-entry base and four disjoint exception components remain "
            "separate exact/census artifacts; this node is their composite view."
        ),
    })
    elliptic_source = node({
        "kind": "leaf", "type": "ExactBlock1EllipticSource",
        "path": ELLIPTIC_SOURCE.name,
        "status": "CF303Block1ExactEllipticRemainderDataValidated",
        "primitive": "identically zero",
        "y0_constant": "zero",
        "output": "exact remainder/cohomology E4Factor/E4Pole channel",
    })

    outputs = []
    previous_h: dict[int, Any] = {}
    for order in ORDERS:
        current_h = {}
        for row in (1, 2):
            source_ref = source_nodes[(order, row)]
            if order == ORDERS[0]:
                h_ref, k_ref = [source_ref, "primitive"], [source_ref, "remainder"]
            else:
                products = [node({
                    "kind": "op", "op": "Mul",
                    "args": [diagonal[(row, column)], previous_h[column]],
                }) for column in (1, 2)]
                source_diagonal = node({
                    "kind": "op", "op": "Mul", "args": [s11, previous_h[row]],
                })
                negative_source = node({
                    "kind": "op", "op": "Mul",
                    "args": [minus_one, source_diagonal],
                })
                cross = node({
                    "kind": "op", "op": "Add",
                    "args": [*products, negative_source],
                })
                split = node({
                    "kind": "op", "op": "FixedRationalHermiteSplit",
                    "arg": cross, "normalize_base": [1, 2],
                    "exact_semantics": "cf303_exact_hermite_semantics.py",
                })
                h_ref = node({
                    "kind": "op", "op": "Add",
                    "args": [[source_ref, "primitive"], [split, "primitive"]],
                })
                k_ref = node({
                    "kind": "op", "op": "Add",
                    "args": [[source_ref, "remainder"], [split, "remainder"]],
                })
            current_h[row] = h_ref
            outputs.append({
                "order": order, "row": row, "delta_h": h_ref, "delta_k": k_ref,
                "elliptic": [elliptic_source, order, row],
                "kernel": {
                    "convention": "GPLFactor",
                    "formula": "Sum_i numerator[i] GPLFactor[denominator,i]",
                    "coefficient_vector": [k_ref, "numerator_coefficients"],
                    "factor": [k_ref, "denominator_polynomial"],
                    "physical_expansion": (
                        "Use existing GPLFactor->GPLPole root expansion only "
                        "when a physical word is requested; do not expand roots here."
                    ),
                },
            })
        previous_h = current_h
    return {
        "status": "CF303Block1ExactArithmeticDAGDeclared",
        "block": [25, 1], "orders": list(ORDERS), "rows": [1, 2],
        "abi": {
            "arithmetic_ops": ["Add", "Mul", "Inv"],
            "sealed_op": "FixedRationalHermiteSplit",
            "source_leaf_compiler": {
                "exact_input": SOURCE.name,
                "mathematical_operation": (
                    "exact path substitution, ordered radical projection, "
                    "epsilon Laurent coefficient selection, and the bound "
                    "exact Hermite normal form"
                ),
                "finite_field_validation_compiler":
                    "cf303_nested_laurent_deck.py",
                "root_order": ["Delta2", "Delta1", "Delta3"],
                "residual_sheet": "Delta1",
                "rational_projection": "(value(+sqrt(Delta1))+value(-sqrt(Delta1)))/2",
                "laurent_rule": "coefficient of eps^n at eps=0, n=-3..4",
            },
            "source_u_budget": {
                "row1_primitive": {"numerator_degree": 40, "denominator_degree": 39},
                "row2_primitive": {"numerator_degree": 38, "denominator_degree": 37},
                "remainder": {"numerator_degree": 22, "denominator_degree": 23},
            },
            "hermite_convention": {
                "identity": "omega = d_u primitive + remainder",
                "normalization": "primitive(u=1/2)=0",
                "remainder_denominator": "monic square-free",
                "algorithm": (
                    "gcd repeated-part elimination followed by RREF in "
                    "increasing-u coefficient order with every free "
                    "coordinate set to zero"
                ),
                "exact_semantics": "cf303_exact_hermite_semantics.py",
                "finite_field_evidence": "cf303_modular_hermite_pilot.py",
            },
            "kernel_factor_budget": {
                "maximum_factor_degree": 23,
                "maximum_GPLFactor_power": 22,
                "root_expansion": "deferred to existing GPLFactor->GPLPole map",
            },
            "circuit_evaluator": "cf303_block1_full_exact_circuit.py",
        },
        "nodes": nodes, "outputs": outputs,
        "accepted_baseline": baseline,
        "assembly_contract": (
            "Use the 88-entry composite baseline (76 base plus disjoint blocks "
            "2/11/14/18), then append the two block-1 entries from this circuit. "
            "Their rational deltaH/deltaK is the arithmetic DAG; their exact "
            "elliptic H and Y0 are zero and K is supplied by the elliptic leaf."
        ),
        "exact_source_bytes": SOURCE.stat().st_size,
    }


def resolver(values: dict[int, Any], reference: Any):
    if isinstance(reference, int):
        return values[reference]
    value = values[reference[0]]
    return value[reference[1]]


def graph_evaluate(manifest: dict[str, Any], pilot, context, p: Fraction):
    prime, helper = context["prime"], context["helper"]
    p_value = pilot.exact_fraction_mod(p, prime)
    base = pilot.exact_fraction_mod(Fraction(*context["inputs"]["base_point"]), prime)

    def incoming(row: int, order: int):
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
            return pilot.RationalFunction.make(
                numerator, denominator, prime, helper
            )

        primitive = component("primitive_numerator")
        primitive = primitive.add(
            pilot.RationalFunction.constant(primitive.evaluate(base), prime),
            helper, -1,
        )
        return {"primitive": primitive,
                "remainder": component("remainder_numerator")}

    values: dict[int, Any] = {}
    for item in manifest["nodes"]:
        identifier = item["id"]
        if item["kind"] == "leaf":
            kind = item["type"]
            if kind == "HermiteSourceComponent":
                values[identifier] = incoming(item["row"], item["order"])
            elif kind == "ExactRational":
                selector = item["selector"]
                record = (context["inputs"]["s11"] if selector[0] == "s11"
                          else context["inputs"]["d"][selector[1]-1][selector[2]-1])
                values[identifier] = context["input_function"](record, p_value)
            elif kind == "ExactInteger":
                values[identifier] = pilot.RationalFunction.constant(
                    item["value"], prime
                )
            else:
                values[identifier] = item
            continue
        if item["op"] == "Mul":
            values[identifier] = resolver(values, item["args"][0]).multiply(
                resolver(values, item["args"][1]), helper
            )
        elif item["op"] == "Add":
            arguments = [resolver(values, reference) for reference in item["args"]]
            result = arguments[0]
            for argument in arguments[1:]:
                result = result.add(argument, helper)
            values[identifier] = result
        elif item["op"] == "FixedRationalHermiteSplit":
            primitive, remainder = pilot.hermite(
                resolver(values, item["arg"]), helper
            )
            primitive = primitive.add(
                pilot.RationalFunction.constant(primitive.evaluate(base), prime),
                helper, -1,
            )
            values[identifier] = {"primitive": primitive, "remainder": remainder}
        else:
            raise RuntimeError(f"unsupported circuit operation {item['op']}")

    records = []
    for output in manifest["outputs"]:
        h_value = resolver(values, output["delta_h"])
        k_value = resolver(values, output["delta_k"])
        records.append({
            "order": output["order"], "row": output["row"],
            "h_numerator": list(h_value.numerator),
            "h_denominator": list(h_value.denominator),
            "k_numerator": list(k_value.numerator),
            "k_denominator": list(k_value.denominator),
        })
    return records


def flatten(records: list[dict[str, Any]]) -> list[int]:
    return [value for record in records for field in FIELDS for value in record[field]]


def materialize_kernels(records: list[dict[str, Any]], prime: int):
    output, term_count = [], 0
    for record in records:
        terms = [] if record["k_numerator"] == [0] else [
            {"coefficient": coefficient,
             "letter": ["GPLFactor", record["k_denominator"], power]}
            for power, coefficient in enumerate(record["k_numerator"])
            if coefficient
        ]
        term_count += len(terms)
        output.append({"order": record["order"], "row": record["row"],
                       "terms": terms})
    return output, term_count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path,
                        default=BUNDLE / "cf303_block1_full_exact_circuit.json")
    parser.add_argument("--report", type=Path,
                        default=BUNDLE / "cf303_block1_full_exact_circuit_validation.json")
    parser.add_argument("--kernel-sample", type=Path,
                        default=BUNDLE / "cf303_block1_full_circuit_q1_p3_gpl_kernels.json")
    args = parser.parse_args()
    pilot = load_module("cf303_full_circuit_pilot", PILOT)
    deck_module = load_module("cf303_full_circuit_deck", DECK_SCRIPT)
    build_started = time.perf_counter()
    manifest = make_manifest()
    manifest["build_seconds"] = time.perf_counter() - build_started
    args.output.write_text(json.dumps(manifest, indent=2) + "\n")

    validation = []
    q1_records = None
    for prime in PRIMES:
        context = pilot.load_context(prime)
        started = time.perf_counter()
        actual = graph_evaluate(manifest, pilot, context, Fraction(3))
        circuit_seconds = time.perf_counter() - started
        reference = pilot.run_point(context, Fraction(3))["records"]
        if flatten(actual) != flatten(reference):
            raise RuntimeError(f"full circuit mismatch at q={prime}")
        validation.append({
            "prime": prime, "p": [3, 1], "record_count": len(actual),
            "coefficient_comparisons": len(flatten(actual)),
            "circuit_evaluation_seconds": circuit_seconds,
        })
        if prime == PRIMES[0]:
            q1_records = actual
    fixed_second = read_json(Q7_FIXED_SECOND)
    second_deck = deck_module.build_deck(
        fixed_second, Q7_FIXED_SECOND.name
    )
    second_deck_path = args.report.parent / (
        "cf303_block1_laurent_deck_q2305843009213693693_p239d47.json.gz"
    )
    deck_module.write_json(second_deck_path, second_deck)
    second_context = pilot.load_context(Q7, second_deck_path)
    second_point = Fraction(239, 47)
    started = time.perf_counter()
    second_actual = graph_evaluate(manifest, pilot, second_context, second_point)
    second_seconds = time.perf_counter() - started
    second_reference = pilot.run_point(second_context, second_point)["records"]
    if flatten(second_actual) != flatten(second_reference):
        raise RuntimeError("full circuit mismatch at second fresh q7 point")
    validation.append({
        "prime": Q7, "p": [239, 47], "record_count": 16,
        "coefficient_comparisons": len(flatten(second_actual)),
        "circuit_evaluation_seconds": second_seconds,
        "raw_source_lift": Q7_FIXED_SECOND.name,
    })
    kernels, term_count = materialize_kernels(q1_records, PRIMES[0])
    kernel_sample = {
        "status": "CF303Block1GPLFactorFiniteFieldImage",
        "prime": PRIMES[0], "p": [3, 1], "records": kernels,
        "term_count": term_count,
        "standard_expansion": (
            "GPLFactor[f,i] uses the existing deferred root expansion into "
            "GPLPole[CF303Root[CoefficientList[f,u],k]] at physical-word time."
        ),
    }
    args.kernel_sample.write_text(json.dumps(kernel_sample, indent=2) + "\n")
    elliptic = read_json(ELLIPTIC_SOURCE)
    if elliptic.get("status") != "CF303Block1ExactEllipticRemainderDataValidated":
        raise RuntimeError("block-1 exact elliptic source is not accepted")
    report = {
        "status": "CF303Block1FiniteFieldArithmeticDAGReplayValidated",
        "circuit": args.output.name, "node_count": len(manifest["nodes"]),
        "output_record_count": len(manifest["outputs"]),
        "validation": validation,
        "total_coefficient_comparisons": sum(
            item["coefficient_comparisons"] for item in validation
        ),
        "q1_gpl_kernel_terms": term_count,
        "q1_gpl_kernel_sample": args.kernel_sample.name,
        "q7_deck": second_deck_path.name,
        "elliptic_source": ELLIPTIC_SOURCE.name,
        "elliptic_fresh_comparisons": elliptic["fresh_comparison_count"],
        "elliptic_primitive_identically_zero":
            elliptic["elliptic_primitive_identically_zero"],
        "composite_baseline_entries": 88,
        "entries_after_block1": 90,
        "full_row_representation": "composite exact references; not monolithic",
        "assembly_contract": manifest["assembly_contract"],
    }
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
