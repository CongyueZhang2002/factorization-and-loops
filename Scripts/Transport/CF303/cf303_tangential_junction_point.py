#!/usr/bin/env python3
"""Contract the accepted CF303 soft residue onto inherited normal modes.

This is the point engine for the singular tangential junction.  It resolves
the accepted deferred circuit at one modular p image and immediately applies
the seven sparse inherited mode vectors.  The raw 2x43 residue is deliberately
not part of this ABI.
"""

from __future__ import annotations

import argparse
from contextlib import redirect_stdout
from fractions import Fraction
import importlib.util
import io
import itertools
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from typing import Any


HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parents[2]
DEFAULT_SCRATCH = REPOSITORY.parent / "factorization-and-loops-codex"
DEFAULT_PRIME = 2_305_843_009_213_641_971
DEFAULT_BLOCK1_DECK = DEFAULT_SCRATCH / (
    "Runtime/2026-08-31_cf303_native_dlog_residues/"
    "block1_modular_laurent_decks/"
    f"cf303_block1_laurent_deck_q{DEFAULT_PRIME}.json"
)
RESOLVER = DEFAULT_SCRATCH / (
    "Diagnostics/Scripts/cf303_block1_circuit_point_resolver.py"
)
EVALUATOR = DEFAULT_SCRATCH / (
    "Diagnostics/Scripts/cf303_hybrid_baseline_modular_circuit.py"
)
ENDPOINT_PROVIDER = HERE / "cf303_deferred_soft_residue_point.py"
INHERITED_PROVIDER = HERE / "cf303_inherited_soft_projection_point.py"


class JunctionPointError(RuntimeError):
    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise JunctionPointError("CF303JunctionProviderUnavailable", path=str(path))
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def fraction_mod(value: Fraction, prime: int) -> int:
    return value.numerator % prime * pow(value.denominator % prime, -1, prime) % prime


def resolve_block1(prime: int, p: Fraction, deck: Path, output: Path) -> float:
    started = time.perf_counter()
    completed = subprocess.run(
        [sys.executable, str(RESOLVER), "--prime", str(prime), "--p", str(p),
         "--deck", str(deck), "--output", str(output)],
        capture_output=True, text=True, check=False,
    )
    if completed.returncode != 0:
        raise JunctionPointError(
            "CF303Block1PointResolutionFailed",
            returncode=completed.returncode,
            stderr=completed.stderr[-2000:], stdout=completed.stdout[-2000:],
        )
    return time.perf_counter() - started


RADICAL_NAMES = (
    "sqrt((4p^4-8p^3+4p^2+1)/(p-1)^2)",
    "sqrt((p-1)(4p^2+p-1)/p^2)",
    "sqrt(p(4p^2+p-4))",
    "sqrt(p(p-1))",
)


def radical_squares(p_value: int, prime: int) -> tuple[int, ...]:
    p_value %= prime
    inverse_p = pow(p_value, -1, prime)
    inverse_pm1 = pow((p_value - 1) % prime, -1, prime)
    return (
        (4*p_value**4 - 8*p_value**3 + 4*p_value**2 + 1) *
            inverse_pm1**2 % prime,
        (p_value - 1) * (4*p_value**2 + p_value - 1) *
            inverse_p**2 % prime,
        p_value * (4*p_value**2 + p_value - 4) % prime,
        p_value * (p_value - 1) % prime,
    )


def prepare_adapter_context(prime: int, p: Fraction,
                            block1: Path) -> dict[str, Any]:
    started = time.perf_counter()
    evaluator = load_module(
        f"cf303_junction_evaluator_{prime}_{p.numerator}_{p.denominator}",
        EVALUATOR,
    )
    evaluator.Q7 = prime
    extension_nonresidue = 2
    while evaluator.legendre(extension_nonresidue, prime) != -1:
        extension_nonresidue += 1
    evaluator.EXT_NONRESIDUE = extension_nonresidue
    evaluator.point_resolution_path = lambda unused: block1
    helper = evaluator.load_module(
        f"cf303_junction_rational_{prime}_{p.numerator}_{p.denominator}",
        evaluator.RATIONAL_HELPER,
    )
    elliptic = evaluator.load_module(
        f"cf303_junction_elliptic_{prime}_{p.numerator}_{p.denominator}",
        evaluator.ELLIPTIC_HELPER,
    )
    inputs = evaluator.parse_inputs()
    resolution = json.loads(block1.read_text())
    if resolution.get("base_sheet") is None:
        raise JunctionPointError("CF303JunctionBaseSheetUnavailable")
    p_mod = fraction_mod(p, prime)
    base = pow(2, -1, prime)
    curve_polynomial = evaluator.curve_polynomial(p_mod, prime)
    curve = evaluator.RationalFunction.make(
        curve_polynomial, [1], prime, helper
    )
    support_masters = evaluator.ADAPTER_SUPPORT_MASTERS
    support_positions = tuple(
        evaluator.SOURCE_ROWS.index(master) for master in support_masters
    )
    support_set = set(support_positions)
    source_records = [
        record for record in inputs["source_forms"]
        if int(record[0]) - 1 in support_set
        and int(record[1]) - 1 in support_set
    ]
    incoming_entries = [
        entry for entry in inputs["source_entries"]
        if int(entry[0][1]) in support_masters
    ]
    incoming, _, _ = evaluator.parse_incoming_primitives(
        incoming_entries, p_mod, prime, helper
    )
    squares = radical_squares(p_mod, prime)
    if len(set(squares)) != len(squares) or 0 in squares:
        raise JunctionPointError("CF303JunctionExceptionalRadicalImage")
    original_sqrt = evaluator.fq2_sqrt_base
    roots = tuple(original_sqrt(value, prime) for value in squares)
    return {
        "prime": prime, "evaluator": evaluator, "helper": helper,
        "elliptic": elliptic,
        "inputs": inputs, "resolution": resolution, "p": p,
        "p_mod": p_mod, "endpoint": 2*p_mod % prime,
        "base": base, "base_sheet": int(resolution["base_sheet"]) % prime,
        "curve_polynomial": curve_polynomial, "curve": curve,
        "support_masters": support_masters,
        "support_positions": support_positions,
        "source_records": source_records, "incoming": incoming,
        "radical_squares": squares, "radical_roots": roots,
        "extension_nonresidue": extension_nonresidue,
        "original_sqrt": original_sqrt,
        "prepare_seconds": time.perf_counter() - started,
    }


def evaluate_adapter_branch(context: dict[str, Any], signs: tuple[int, ...]
                            ) -> tuple[dict[str, Any], float]:
    started = time.perf_counter()
    evaluator = context["evaluator"]
    helper = context["helper"]
    elliptic = context["elliptic"]
    prime = context["prime"]
    sign_by_square = dict(zip(context["radical_squares"], signs))
    seen_squares: set[int] = set()
    unknown_squares: set[int] = set()

    def signed_sqrt(value: int, modulus: int):
        root = context["original_sqrt"](value, modulus)
        square = value % modulus
        if square in sign_by_square:
            seen_squares.add(square)
        else:
            unknown_squares.add(square)
        sign = sign_by_square.get(square, 1)
        return tuple(sign*component % modulus for component in root)

    evaluator.fq2_sqrt_base = signed_sqrt
    try:
        source_forms = evaluator.parse_form_records(
            context["source_records"], context["p"], prime, helper
        )
        target_forms = evaluator.parse_form_records(
            context["inputs"]["target_forms"], context["p"], prime, helper
        )
    finally:
        evaluator.fq2_sqrt_base = context["original_sqrt"]
    if unknown_squares:
        raise JunctionPointError(
            "CF303JunctionRadicalInventoryChanged",
            unknown=len(unknown_squares),
        )
    context["last_target_forms"] = target_forms
    support_positions = context["support_positions"]
    incoming = context["incoming"]
    previous = [[evaluator.zero_pair(prime) for _ in evaluator.SOURCE_ROWS]
                for _ in evaluator.TARGET_ROWS]
    by_order = {}
    cross_by_order = {}
    for order in evaluator.ORDERS:
        cross = [[evaluator.zero_pair(prime) for _ in evaluator.SOURCE_ROWS]
                 for _ in evaluator.TARGET_ROWS]
        for row, middle, form in target_forms:
            for column in support_positions:
                if not evaluator.pair_zero(previous[middle][column]):
                    cross[row][column] = evaluator.pair_add(
                        cross[row][column], evaluator.function_form_product(
                            previous[middle][column], form,
                            context["curve"], helper
                        ), helper,
                    )
        for middle, column, form in source_forms:
            for row in range(len(evaluator.TARGET_ROWS)):
                if not evaluator.pair_zero(previous[row][middle]):
                    cross[row][column] = evaluator.pair_add(
                        cross[row][column], evaluator.function_form_product(
                            previous[row][middle], form,
                            context["curve"], helper
                        ), helper, -1,
                    )
        current = [[evaluator.zero_pair(prime) for _ in evaluator.SOURCE_ROWS]
                   for _ in evaluator.TARGET_ROWS]
        cross_k = [[evaluator.zero_pair(prime) for _ in evaluator.SOURCE_ROWS]
                   for _ in evaluator.TARGET_ROWS]
        for row in range(len(evaluator.TARGET_ROWS)):
            for column in support_positions:
                form = cross[row][column]
                if evaluator.pair_zero(form):
                    primitive = remainder = evaluator.zero_pair(prime)
                else:
                    primitive, remainder = evaluator.reduce_form(
                        form, context["curve_polynomial"], helper, elliptic
                    )
                cross_k[row][column] = remainder
                current[row][column] = evaluator.normalize_at_base(
                    evaluator.pair_add(
                        incoming[order][row][column], primitive, helper
                    ), context["base"], context["base_sheet"], helper,
                )
        by_order[order] = current
        cross_by_order[order] = cross_k
        previous = current

    block1_h = evaluator.load_block1_h(context["resolution"], helper)
    for order in evaluator.ORDERS:
        for row in range(2):
            channel = by_order[order][row][0][0]
            by_order[order][row][0] = (
                (channel[0].add(block1_h[(order, row)], helper), channel[1]),
                by_order[order][row][0][1],
            )
    cross_outputs = []
    for order in evaluator.ORDERS:
        for row in range(2):
            for column in support_positions:
                if order != evaluator.ORDERS[0]:
                    cross_outputs.append({
                        "order": order, "row": row + 1,
                        "target_master": evaluator.TARGET_ROWS[row],
                        "column": column + 1,
                        "source_master": evaluator.SOURCE_ROWS[column],
                        "pair": evaluator.serialize_pair(
                            cross_by_order[order][row][column]
                        ),
                    })
    return {
        "status": "CF303HybridBaselineLazyAdapterPointV1",
        "abi_version": 1, "prime": prime,
        "p": [context["p"].numerator, context["p"].denominator],
        "source_rows": list(evaluator.SOURCE_ROWS),
        "target_rows": list(evaluator.TARGET_ROWS),
        "cross_k_orders": [evaluator.ORDERS[1], evaluator.ORDERS[-1]],
        "support_source_masters": list(context["support_masters"]),
        "cross_k_output_count": len(cross_outputs),
        "cross_k_outputs": cross_outputs,
        "evaluation_scope": "AcceptedSevenColumnInvariantSupport",
        "radical_signs": list(signs),
        "active_radical_square_count": len(seen_squares),
    }, time.perf_counter() - started


def add_pair(target: dict[tuple[int, int, int], Any], key, value,
             evaluator, helper, prime: int) -> None:
    target[key] = evaluator.pair_add(
        target.get(key, evaluator.zero_pair(prime)), value, helper
    )


def local_connection_pairs(context: dict[str, Any], adapter: dict[str, Any],
                           endpoint_provider: Any
                           ) -> dict[tuple[int, int, int], Any]:
    evaluator = context["evaluator"]
    helper = context["helper"]
    prime = context["prime"]
    p_mod = context["p_mod"]
    support = set(context["support_masters"])
    result: dict[tuple[int, int, int], Any] = {}

    def parse_kernel(labelled_kernel: list[Any]):
        label, kernel_raw = labelled_kernel
        if label[0] != "E4Pole":
            return tuple(evaluator.ext_from_base(
                evaluator.bi_expression_to_rf(
                    evaluator.ModularExpressionParser(
                        raw, prime, p_mod
                    ).parse(), helper,
                )
            ) for raw in kernel_raw)
        point_rf = endpoint_provider.scalar_expression(
            label[1], evaluator, helper, prime, p_mod
        )
        if len(point_rf.numerator) != 1 or len(point_rf.denominator) != 1:
            raise JunctionPointError(
                "CF303E4PolePointDependsOnPath", label=label
            )
        point_value = point_rf.evaluate(0)
        denominator = [(-point_value) % prime, 1]
        return (
            evaluator.ext_from_base(evaluator.RationalFunction.zero(prime)),
            evaluator.ext_from_base(evaluator.RationalFunction.make(
                [1], denominator, prime, helper
            )),
        )

    for entry in context["inputs"]["entries"]:
        target, source = map(int, entry[0])
        if target not in evaluator.TARGET_ROWS or source not in support:
            continue
        for coefficient_raw, labelled_kernel in entry[3]:
            label = labelled_kernel[0]
            if label[0] == "E4Pole":
                normalization = f"/Yc({label[1]})"
                if coefficient_raw.count(normalization) != 1:
                    raise JunctionPointError(
                        "CF303E4PoleNormalizationDidNotCancel", label=label
                    )
                coefficient_raw = coefficient_raw.replace(normalization, "")
            coefficient = evaluator.ModularExpressionParser(
                coefficient_raw, prime, p_mod
            ).parse()
            windows = evaluator.laurent_coefficients(
                coefficient, helper, low=evaluator.ORDERS[0],
                high=evaluator.ORDERS[-1]
            )
            kernels = parse_kernel(labelled_kernel)
            for order, coefficient_rf in windows.items():
                pair = tuple(tuple(
                    coefficient_rf.multiply(component, helper)
                    for component in kernel
                ) for kernel in kernels)
                add_pair(result, (order, target, source), pair,
                         evaluator, helper, prime)
    for record in adapter["cross_k_outputs"]:
        add_pair(
            result,
            (record["order"], record["target_master"],
             record["source_master"]),
            endpoint_provider.deserialize_pair(
                record["pair"], evaluator, helper, prime
            ), evaluator, helper, prime,
        )
    for record in context["resolution"]["outputs"]:
        rational = evaluator.RationalFunction.make(
            record["k_rational"]["numerator"],
            record["k_rational"]["denominator"], prime, helper
        )
        elliptic_record = record["k_elliptic"]
        elliptic = evaluator.RationalFunction.make(
            elliptic_record["numerator"], elliptic_record["denominator"],
            prime, helper,
        )
        add_pair(
            result, (record["order"], 43 + record["row"], 1),
            (evaluator.ext_from_base(rational),
             evaluator.ext_from_base(elliptic)),
            evaluator, helper, prime,
        )
    return result


def local_channels(local: dict[str, Any], power: int) -> dict[str, list[int]]:
    if power == 0:
        return local["finite"]
    collection = local["principal"] if power < 0 else local["positive"]
    record = next((item for item in collection
                   if item["rho_power"] == power), None)
    if record is None:
        return {"rational": [0, 0], "elliptic_y_coefficient": [0, 0]}
    return {name: record[name]
            for name in ("rational", "elliptic_y_coefficient")}


def scalar_local_channels(local: dict[str, Any], through_power: int,
                          context: dict[str, Any], endpoint_provider: Any
                          ) -> dict[int, tuple[int, int]]:
    """Evaluate R(u)+E(u)/Y(u) on the selected local curve sheet."""
    evaluator = context["evaluator"]
    prime = context["prime"]
    maximum_inverse_order = through_power + 1
    curve_series = endpoint_provider.shifted_coefficients(
        context["curve_polynomial"], context["endpoint"],
        maximum_inverse_order + 1, prime,
    )
    curve_series = [((-value) if order % 2 else value) % prime
                    for order, value in enumerate(curve_series)]
    y_series = [evaluator.fq2_sqrt_base(curve_series[0], prime)]
    inverse_two_y0 = evaluator.fq2_inverse(
        (2*y_series[0][0] % prime, 2*y_series[0][1] % prime), prime
    )
    for order in range(1, maximum_inverse_order + 1):
        correction = (0, 0)
        for left in range(1, order):
            correction = evaluator.fq2_add(
                correction,
                evaluator.fq2_multiply(
                    y_series[left], y_series[order - left], prime
                ), prime,
            )
        residual = evaluator.fq2_add(
            (curve_series[order], 0), correction, prime, -1
        )
        y_series.append(evaluator.fq2_multiply(
            residual, inverse_two_y0, prime
        ))
    inverse_y = [evaluator.fq2_inverse(y_series[0], prime)]
    for order in range(1, maximum_inverse_order + 1):
        convolution = (0, 0)
        for left in range(1, order + 1):
            convolution = evaluator.fq2_add(
                convolution,
                evaluator.fq2_multiply(
                    y_series[left], inverse_y[order - left], prime
                ), prime,
            )
        inverse_y.append(evaluator.fq2_multiply(
            evaluator.fq2_add((0, 0), convolution, prime, -1),
            inverse_y[0], prime,
        ))
    result = {}
    for power in range(-1, through_power + 1):
        channels = local_channels(local, power)
        value = tuple(channels["rational"])
        for inverse_order in range(0, power + 2):
            elliptic_power = power - inverse_order
            elliptic = tuple(local_channels(
                local, elliptic_power
            )["elliptic_y_coefficient"])
            value = evaluator.fq2_add(
                value,
                evaluator.fq2_multiply(
                    elliptic, inverse_y[inverse_order], prime
                ), prime,
            )
        result[power] = value
    return result


def add_scaled_pair(result: list[int], pair: list[int], scale: int,
                    prime: int) -> None:
    result[0] = (result[0] + scale * pair[0]) % prime
    result[1] = (result[1] + scale * pair[1]) % prime


def build_point(prime: int, p: Fraction, block1_deck: Path,
                orbit: str = "single", local_through: int = -1,
                emit_components: bool = False,
                component_keys: set[str] | None = None,
                ) -> dict[str, Any]:
    started = time.perf_counter()
    endpoint_provider = load_module(
        f"cf303_junction_endpoint_{prime}_{p.numerator}_{p.denominator}",
        ENDPOINT_PROVIDER,
    )
    inherited_provider = load_module(
        f"cf303_junction_modes_{prime}_{p.numerator}_{p.denominator}",
        INHERITED_PROVIDER,
    )
    if not block1_deck.is_file():
        raise JunctionPointError(
            "CF303Block1LaurentDeckMissing", path=str(block1_deck)
        )
    with tempfile.TemporaryDirectory(prefix="cf303-junction-") as directory:
        temporary = Path(directory)
        block1_path = temporary / "block1.json"
        block1_seconds = resolve_block1(
            prime, p, block1_deck, block1_path
        )
        context = prepare_adapter_context(prime, p, block1_path)
        evaluator = context["evaluator"]
        helper = context["helper"]
        accepted, _ = endpoint_provider.accepted_k_contributions(
            context["inputs"], evaluator, helper, prime,
            context["p_mod"], context["endpoint"],
        )
        block1, _ = endpoint_provider.block1_contributions(
            context["resolution"], context["endpoint"], prime
        )
        if orbit == "full":
            signs = list(itertools.product((-1, 1), repeat=4))
        elif orbit == "even":
            signs = [(1,) + tail
                     for tail in itertools.product((-1, 1), repeat=3)]
        else:
            signs = [(1, 1, 1, 1)]
        branch_values: dict[tuple[int, ...], dict[tuple[int, int, int],
                                                    tuple[int, int]]] = {}
        branch_component_values: dict[
            str, dict[tuple[int, ...], dict[tuple[int, int, int],
                                            tuple[int, int]]]
        ] = {name: {} for name in ("accepted", "cross", "block1")}
        branch_seconds = []
        active_radical_counts = []
        local_projection: list[dict[str, Any]] = []
        for branch_signs in signs:
            adapter, seconds = evaluate_adapter_branch(context, branch_signs)
            branch_seconds.append(seconds)
            active_radical_counts.append(
                adapter["active_radical_square_count"]
            )
            cross, _ = endpoint_provider.cross_k_contributions(
                adapter, context["endpoint"], prime
            )
            parts = {"accepted": accepted, "cross": cross, "block1": block1}

            def project_contribution(contribution: Any):
                if any(value["elliptic_numerator"] != [0, 0]
                       for value in contribution.values.values()):
                    raise JunctionPointError(
                        "CF303JunctionComponentHasEllipticNormalChannel"
                    )
                projection = {}
                for mode_index, mode in enumerate(
                        inherited_provider.MODE_SPECS, 1):
                    for order in range(-3, 5):
                        for target in evaluator.TARGET_ROWS:
                            value = [0, 0]
                            for state_row, weight in mode["state_weights"].items():
                                add_scaled_pair(
                                    value,
                                    contribution.values.get(
                                        (order, target, state_row),
                                        endpoint_provider.zero_value(),
                                    )["rational"],
                                    int(weight), prime,
                                )
                            projection[(mode_index, order, target)] = tuple(value)
                return projection

            combined = endpoint_provider.merge_contributions(
                list(parts.values()), prime
            )
            branch_values[branch_signs] = project_contribution(combined)
            if emit_components:
                for name, contribution in parts.items():
                    branch_component_values[name][branch_signs] = (
                        project_contribution(contribution)
                    )
        if local_through >= 0:
            if orbit != "single":
                raise JunctionPointError(
                    "CF303LocalJetRequiresSingleRationalizedBranch"
                )
            pairs = local_connection_pairs(context, adapter, endpoint_provider)
            local_state_projection: list[dict[str, Any]] = []
            for order in range(-3, 5):
                for target in evaluator.TARGET_ROWS:
                    for state_row in context["support_masters"]:
                        local = endpoint_provider.function_pair_local_data(
                            pairs.get(
                                (order, target, state_row),
                                evaluator.zero_pair(prime),
                            ), context["endpoint"], prime,
                            through_power=local_through,
                        )
                        if local is None:
                            continue
                        scalar = scalar_local_channels(
                            local, local_through, context,
                            endpoint_provider,
                        )
                        for rho_power, channels in scalar.items():
                            channels = tuple((-value) % prime
                                             for value in channels)
                            if channels != (0, 0):
                                local_state_projection.append({
                                    "epsilon_order": order,
                                    "target_master": target,
                                    "source_state_row": state_row,
                                    "rho_power": rho_power,
                                    "value": list(channels),
                                })
            for mode_index, mode in enumerate(
                    inherited_provider.MODE_SPECS, 1):
                for order in range(-3, 5):
                    for target in evaluator.TARGET_ROWS:
                        pair = evaluator.zero_pair(prime)
                        for state_row, weight in mode["state_weights"].items():
                            pair = evaluator.pair_add(
                                pair, pairs.get(
                                    (order, target, state_row),
                                    evaluator.zero_pair(prime),
                                ), helper, int(weight),
                            )
                        local = endpoint_provider.function_pair_local_data(
                            pair, context["endpoint"], prime,
                            through_power=local_through,
                        )
                        if local is None:
                            continue
                        scalar = scalar_local_channels(
                            local, local_through, context,
                            endpoint_provider,
                        )
                        for rho_power, channels in scalar.items():
                            # Stored kernels multiply du and rho=2p-u.
                            channels = tuple((-value) % prime
                                             for value in channels)
                            if channels != (0, 0):
                                local_projection.append({
                                    "mode_index": mode_index,
                                    "mode_id": mode["mode_id"],
                                    "epsilon_order": order,
                                    "target_master": target,
                                    "rho_power": rho_power,
                                    "value": list(channels),
                                })
            local_target_connection: list[dict[str, Any]] = []
            for row, column, pair in context["last_target_forms"]:
                local = endpoint_provider.function_pair_local_data(
                    pair, context["endpoint"], prime,
                    through_power=local_through,
                )
                if local is None:
                    continue
                scalar = scalar_local_channels(
                    local, local_through, context, endpoint_provider,
                )
                for rho_power, channels in scalar.items():
                    channels = tuple((-value) % prime for value in channels)
                    if channels != (0, 0):
                        local_target_connection.append({
                            "target_row": row + 1,
                            "target_column": column + 1,
                            "rho_power": rho_power,
                            "value": list(channels),
                        })

    even_masks = tuple(mask for mask in range(16) if mask.bit_count() % 2 == 0)
    masks = tuple(range(16)) if orbit == "full" else (
        even_masks if orbit == "even" else (0,)
    )
    inverse_orbit_size = pow(len(signs), -1, prime)
    root_products = {}
    for mask in masks:
        product = (1, 0)
        for index, root in enumerate(context["radical_roots"]):
            if mask & (1 << index):
                product = evaluator.fq2_multiply(product, root, prime)
        root_products[mask] = product

    projected: list[dict[str, Any]] = []
    projected_components: list[dict[str, Any]] = []
    target_extensions: list[dict[str, Any]] = []
    zero_mode_couplings: list[dict[str, Any]] = []
    for mode_index, mode in enumerate(inherited_provider.MODE_SPECS, 1):
        eigenvalue = int(mode["normal_eigenvalue"])
        for order in range(-3, 5):
            for target in evaluator.TARGET_ROWS:
                key = (mode_index, order, target)
                for mask in masks:
                    numerator = (0, 0)
                    for branch_signs in signs:
                        character = 1
                        for index in range(4):
                            if mask & (1 << index):
                                character *= branch_signs[index]
                        numerator = evaluator.fq2_add(
                            numerator, branch_values[branch_signs][key],
                            prime, character,
                        )
                    numerator = tuple(
                        component*inverse_orbit_size % prime
                        for component in numerator
                    )
                    coefficient = evaluator.fq2_multiply(
                        numerator,
                        evaluator.fq2_inverse(root_products[mask], prime),
                        prime,
                    )
                    if coefficient[1] != 0:
                        raise JunctionPointError(
                            "CF303GaloisProjectionDidNotReachBaseField",
                            mask=mask, mode=mode["mode_id"], order=order,
                            target=target,
                        )
                    if orbit == "full" and mask.bit_count() % 2 and coefficient[0] != 0:
                        raise JunctionPointError(
                            "CF303OddGaloisParityDidNotVanish", mask=mask,
                            mode=mode["mode_id"], order=order, target=target,
                        )
                    if coefficient[0] == 0 or mask.bit_count() % 2:
                        continue
                    record = {
                        "mode_index": mode_index, "mode_id": mode["mode_id"],
                        "normal_eigenvalue_over_epsilon": eigenvalue,
                        "epsilon_order": order, "target_master": target,
                        "radical_mask": [index + 1 for index in range(4)
                                         if mask & (1 << index)],
                        "radical_mask_bits": mask, "value": coefficient[0],
                    }
                    projected.append(record)
                    if eigenvalue:
                        target_extensions.append({
                            **record, "epsilon_order": order - 1,
                            "value": coefficient[0] *
                                pow(eigenvalue % prime, -1, prime) % prime,
                            "relation": "B.v/(lambda*eps)",
                        })
                    else:
                        zero_mode_couplings.append({
                            **record, "generalized_level": 1,
                        })

    if emit_components:
        for component, component_branches in branch_component_values.items():
            for mode_index, mode in enumerate(inherited_provider.MODE_SPECS, 1):
                for order in range(-3, 5):
                    for target in evaluator.TARGET_ROWS:
                        coordinate_key = f"{mode_index}:{order}:{target}:0"
                        if component_keys and coordinate_key not in component_keys:
                            continue
                        key = (mode_index, order, target)
                        for mask in masks:
                            numerator = (0, 0)
                            for branch_signs in signs:
                                character = 1
                                for index in range(4):
                                    if mask & (1 << index):
                                        character *= branch_signs[index]
                                numerator = evaluator.fq2_add(
                                    numerator,
                                    component_branches[branch_signs][key],
                                    prime, character,
                                )
                            numerator = tuple(
                                value*inverse_orbit_size % prime
                                for value in numerator
                            )
                            coefficient = evaluator.fq2_multiply(
                                numerator,
                                evaluator.fq2_inverse(root_products[mask], prime),
                                prime,
                            )
                            if coefficient[1] != 0:
                                raise JunctionPointError(
                                    "CF303ComponentGaloisProjectionDidNotReachBaseField",
                                    component=component, mask=mask,
                                )
                            if coefficient[0] == 0 or mask.bit_count() % 2:
                                continue
                            projected_components.append({
                                "component": component,
                                "mode_index": mode_index,
                                "epsilon_order": order,
                                "target_master": target,
                                "radical_mask_bits": mask,
                                "value": coefficient[0],
                            })

    return {
        "status": "CF303TangentialJunctionPointV1",
        "prime": prime, "p": [p.numerator, p.denominator],
        "p_mod_prime": fraction_mod(p, prime),
        "coefficient_field": "Even subfield of four-radical extension",
        "quadratic_extension_nonresidue": context["extension_nonresidue"],
        "radical_names": list(RADICAL_NAMES),
        "radical_squares": list(context["radical_squares"]),
        "galois_orbit": {"full": "Full16", "even": "EvenParity8",
                          "single": "SingleBranch"}[orbit],
        "galois_parity": (
            "Odd masks checked zero" if orbit == "full" else
            "Even masks projected" if orbit == "even" else
            "Rational component assumed; certify with a held-out full orbit"
        ),
        "active_radical_square_counts": active_radical_counts,
        "basis": "AcceptedPathGaugeG25FinalLayer",
        "source_mode_basis": "CF303InheritedSoftSourceNeedsV1::NormalModeBlocks",
        "scope": "Seven inherited source modes contracted before p reconstruction",
        "target_rows": list(evaluator.TARGET_ROWS),
        "mode_order": [mode["mode_id"] for mode in inherited_provider.MODE_SPECS],
        "normal_residue_projection": projected,
        "normal_residue_projection_components": projected_components,
        "nonzero_eigenmode_target_g_extension": target_extensions,
        "zero_eigenmode_chain_coupling": zero_mode_couplings,
        "normal_connection_local_projection": local_projection,
        "normal_connection_local_state_projection": (
            local_state_projection if local_through >= 0 else []
        ),
        "target_normal_local_connection": (
            local_target_connection if local_through >= 0 else []
        ),
        "normal_connection_local_window": [-1, local_through],
        "raw_residue_deck_emitted": False,
        "timings_seconds": {
            "block1_resolution": block1_seconds,
            "context_prepare": context["prepare_seconds"],
            "branch_total": sum(branch_seconds),
            "branch_min": min(branch_seconds),
            "branch_max": max(branch_seconds),
            "total": time.perf_counter() - started,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=DEFAULT_PRIME)
    parser.add_argument("--p", type=Fraction, required=True)
    parser.add_argument("--block1-deck", type=Path,
                        default=DEFAULT_BLOCK1_DECK)
    parser.add_argument("--orbit", choices=("single", "even", "full"),
                        default="single")
    parser.add_argument("--local-through", type=int, choices=(0, 1),
                        default=-1)
    parser.add_argument("--emit-components", action="store_true")
    parser.add_argument("--component-key", action="append", default=[])
    parser.add_argument("--output", type=Path)
    arguments = parser.parse_args()
    try:
        payload = build_point(
            arguments.prime, arguments.p, arguments.block1_deck,
            arguments.orbit, arguments.local_through,
            arguments.emit_components, set(arguments.component_key),
        )
    except (JunctionPointError, FileNotFoundError, ZeroDivisionError) as error:
        if isinstance(error, JunctionPointError):
            failure = {"status": error.status, **error.details}
        else:
            failure = {"status": type(error).__name__, "message": str(error)}
        print(json.dumps(failure, sort_keys=True))
        return 2
    encoded = json.dumps(payload, indent=2) + "\n"
    if arguments.output:
        arguments.output.write_text(encoded)
        print(json.dumps({
            "status": payload["status"], "output": str(arguments.output),
            "projected": len(payload["normal_residue_projection"]),
            "target_g": len(payload["nonzero_eigenmode_target_g_extension"]),
            "seconds": payload["timings_seconds"]["total"],
        }, sort_keys=True))
    else:
        print(encoded, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
