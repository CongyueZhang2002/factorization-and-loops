#!/usr/bin/env python3
"""Resolve every inert CF303 block-1 circuit head at one modular (q,p).

The rational H/K channel is evaluated by the accepted arithmetic DAG.  The
elliptic K channel is evaluated from the accepted exact p profiles and reduced
to the same E4Factor numerator/denominator convention.  No symbolic Wolfram
verification is performed.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import time
from collections import defaultdict
from fractions import Fraction
from pathlib import Path
from typing import Any

import sympy


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
SCRIPTS = ROOT / "Diagnostics/Scripts"
OUT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
FULL = SCRIPTS / "cf303_block1_full_exact_circuit.py"
PILOT = SCRIPTS / "cf303_block1_modular_finite_gauge_pilot.py"
CIRCUIT = OUT / "cf303_block1_full_exact_circuit.json"
ELLIPTIC = OUT / "cf303_block1_exact_elliptic_source.json"
Q7 = 2_305_843_009_213_693_693


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def decode_fraction(value: list[int]) -> Fraction:
    return Fraction(int(value[0]), int(value[1]))


def fraction_mod(value: Fraction, prime: int) -> int:
    return value.numerator % prime * pow(
        value.denominator % prime, prime - 2, prime
    ) % prime


def polynomial_value(coefficients: list[Fraction], value: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * value + fraction_mod(coefficient, prime)) % prime
    return result


def profile_value(profile: dict[str, Any], p_value: int, prime: int) -> int:
    numerator = polynomial_value(
        [decode_fraction(value) for value in profile["numerator"]],
        p_value, prime,
    )
    denominator = polynomial_value(
        [decode_fraction(value) for value in profile["denominator"]],
        p_value, prime,
    )
    if denominator == 0:
        raise ZeroDivisionError(f"profile pole at {profile['key']}")
    return numerator * pow(denominator, prime - 2, prime) % prime


def laurent_coefficient(
    numerator: list[int], denominator: list[int], order: int, prime: int,
) -> int:
    numerator_start = next((i for i, value in enumerate(numerator) if value), None)
    denominator_start = next((i for i, value in enumerate(denominator) if value), None)
    if numerator_start is None:
        return 0
    if denominator_start is None:
        raise ZeroDivisionError("zero epsilon denominator")
    valuation = numerator_start - denominator_start
    if order < valuation:
        return 0
    numerator = numerator[numerator_start:]
    denominator = denominator[denominator_start:]
    target = order - valuation
    inverse_lead = pow(denominator[0], prime - 2, prime)
    coefficients: list[int] = []
    for degree in range(target + 1):
        source = numerator[degree] if degree < len(numerator) else 0
        correction = sum(
            (denominator[index] if index < len(denominator) else 0)
            * coefficients[degree - index]
            for index in range(1, degree + 1)
        )
        coefficients.append((source - correction) * inverse_lead % prime)
    return coefficients[-1]


def resolve_elliptic(
    artifact: dict[str, Any], p_value: int, prime: int, helper,
    curve_coefficients: list[int],
) -> dict[tuple[int, int], dict[str, list[int]]]:
    profile_map = {tuple(profile["key"]): profile
                   for profile in artifact["exact_profiles"]}
    epsilon_groups: dict[tuple[str, str, int], dict[str, dict[int, Any]]]
    epsilon_groups = defaultdict(lambda: {"numerator": {}, "denominator": {}})
    denominator_groups: dict[tuple[str, str], dict[int, Any]] = defaultdict(dict)
    for key, profile in profile_map.items():
        if key[0] == "epsilon_profile" and str(key[1]).endswith("elliptic"):
            epsilon_groups[(str(key[1]), str(key[2]), int(key[3]))][
                str(key[4])][int(key[5])] = profile
        elif key[0] == "u_denominator" and str(key[1]).endswith("elliptic"):
            denominator_groups[(str(key[1]), str(key[2]))][int(key[3])] = profile

    resolved: dict[tuple[int, int], dict[str, list[int]]] = {}
    for row in (1, 2):
        channel = f"{row},1,elliptic"
        denominator_map = denominator_groups[(channel, "remainder_denominator")]
        if set(denominator_map) != set(range(len(denominator_map))):
            raise RuntimeError(f"noncontiguous elliptic u denominator {channel}")
        denominator = [profile_value(denominator_map[index], p_value, prime)
                       for index in range(len(denominator_map))]
        numerator_indices = sorted(index for ch, field, index in epsilon_groups
                                   if ch == channel and field == "remainder_numerator")
        if numerator_indices != list(range(len(numerator_indices))):
            raise RuntimeError(f"noncontiguous elliptic u numerator {channel}")
        for order in range(-3, 5):
            numerator = []
            for index in numerator_indices:
                parts = epsilon_groups[(channel, "remainder_numerator", index)]
                arrays = {}
                for part in ("numerator", "denominator"):
                    entries = parts[part]
                    if set(entries) != set(range(len(entries))):
                        raise RuntimeError(
                            f"noncontiguous epsilon {channel}:{index}:{part}"
                        )
                    arrays[part] = [profile_value(entries[i], p_value, prime)
                                    for i in range(len(entries))]
                numerator.append(laurent_coefficient(
                    arrays["numerator"], arrays["denominator"], order, prime
                ))
            quotient, proper_numerator = helper.divmod_poly(
                numerator, denominator, prime
            )
            quotient = helper.trim(quotient, prime)
            if len(quotient) > 3:
                raise RuntimeError(
                    f"elliptic polynomial quotient exceeds cohomology basis: "
                    f"{channel}:{order}:{len(quotient) - 1}"
                )
            cohomology = []
            for index in range(3):
                parts = epsilon_groups[(channel, "cohomology_coefficients", index)]
                arrays = {}
                for part in ("numerator", "denominator"):
                    entries = parts[part]
                    arrays[part] = [profile_value(entries[i], p_value, prime)
                                    for i in range(len(entries))]
                cohomology.append(laurent_coefficient(
                    arrays["numerator"], arrays["denominator"], order, prime
                ))
            padded_quotient = quotient + [0] * (3 - len(quotient))
            if padded_quotient != cohomology:
                raise RuntimeError(
                    f"elliptic quotient/cohomology mismatch {channel}:{order}"
                )
            if len(curve_coefficients) != 5 or curve_coefficients[4] == 0:
                raise RuntimeError("quartic curve specialization is singular")
            basis_shift = (
                curve_coefficients[3]
                * pow(2 * curve_coefficients[4] % prime, prime - 2, prime)
            ) % prime
            omega = [
                cohomology[0],
                (cohomology[1] - cohomology[2] * basis_shift) % prime,
                cohomology[2],
            ]
            resolved[(order, row)] = {
                "numerator": numerator, "denominator": denominator,
                "proper_numerator": proper_numerator,
                "cohomology_polynomial": cohomology,
                "basis_shift": basis_shift,
                "omega_coefficients": {
                    "E4Omega0": omega[0],
                    "E4OmegaInf": omega[1],
                    "E4Eta2": omega[2],
                },
            }
    return resolved


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=Q7)
    parser.add_argument("--p", type=Fraction, default=Fraction(3))
    parser.add_argument("--deck", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    started = time.perf_counter()
    if args.deck is None:
        if args.prime == Q7 and args.p not in (Fraction(3), Fraction(239, 47)):
            raise RuntimeError("q7 has accepted fixed decks only at p=3 and p=239/47")
        suffix = "_p239d47" if (
            args.prime == Q7 and args.p == Fraction(239, 47)
        ) else ""
        args.deck = OUT / "block1_modular_laurent_decks" / (
            f"cf303_block1_laurent_deck_q{args.prime}{suffix}.json"
        )
    if args.output is None:
        args.output = OUT / (
            f"cf303_block1_circuit_resolved_q{args.prime}_"
            f"p{args.p.numerator}d{args.p.denominator}.json"
        )

    deck_metadata = json.loads(args.deck.read_text())
    if int(deck_metadata.get("prime", -1)) != args.prime:
        raise RuntimeError("deck prime does not match requested prime")
    source_p = deck_metadata.get("source_p")
    if source_p is None and deck_metadata.get("source"):
        source_path = Path(deck_metadata["source"])
        if source_path.is_file():
            source_p = json.loads(source_path.read_text()).get("p")
    if source_p is not None and [int(value) for value in source_p] != [
        args.p.numerator, args.p.denominator
    ]:
        raise RuntimeError(
            f"fixed-p deck provenance {source_p} does not match p={args.p}"
        )

    full = load_module("cf303_point_resolver_full", FULL)
    pilot = load_module("cf303_point_resolver_pilot", PILOT)
    manifest = json.loads(CIRCUIT.read_text())
    elliptic_artifact = json.loads(ELLIPTIC.read_text())
    context = pilot.load_context(args.prime, args.deck)
    records = full.graph_evaluate(manifest, pilot, context, args.p)
    reference = pilot.run_point(context, args.p)["records"]
    if full.flatten(records) != full.flatten(reference):
        raise RuntimeError("resolved rational circuit does not match source replay")
    p_value = pilot.exact_fraction_mod(args.p, args.prime)
    curve_coefficients = pilot.specialize_polynomial(
        context["inputs"]["curve"], p_value, args.prime
    )
    base_value = pilot.exact_fraction_mod(
        Fraction(*context["inputs"]["base_point"]), args.prime
    )
    base_curve = 0
    for coefficient in reversed(curve_coefficients):
        base_curve = (base_curve * base_value + coefficient) % args.prime
    base_roots = sympy.sqrt_mod(base_curve, args.prime, all_roots=True)
    base_sheet = int(min(base_roots)) if base_roots else None
    elliptic = resolve_elliptic(
        elliptic_artifact, p_value, args.prime,
        context["helper"], curve_coefficients,
    )
    outputs = []
    for record in records:
        key = (record["order"], record["row"])
        outputs.append({
            "order": key[0], "row": key[1],
            "h": {"numerator": record["h_numerator"],
                  "denominator": record["h_denominator"]},
            "k_rational": {"numerator": record["k_numerator"],
                           "denominator": record["k_denominator"]},
            "k_elliptic": elliptic[key],
        })
    result = {
        "status": "CF303Block1CircuitPointResolutionAcceptedV1",
        "prime": args.prime,
        "p": [args.p.numerator, args.p.denominator],
        "orders": [-3, 4], "rows": [1, 2],
        "base_point": context["inputs"]["base_point"],
        "base_curve_value": base_curve,
        "base_sheet": base_sheet,
        "base_sheet_available": base_sheet is not None,
        "output_count": len(outputs), "outputs": outputs,
        "head_resolution": {
            "CF303CircuitH": "h numerator/denominator in u",
            "CF303CircuitGPLKernel":
                "Sum_i k_rational numerator[i] GPLFactor[k_rational denominator,i]",
            "CF303ExactEllipticKernel":
                "proper remainder as E4Factor plus quotient mapped to E4Omega0/E4OmegaInf/E4Eta2",
        },
        "rational_source_replay_comparisons": len(full.flatten(records)),
        "elliptic_quotient_cohomology_checks": len(outputs),
        "elliptic_exact_profile_comparisons":
            elliptic_artifact["fresh_comparison_count"],
        "wall_seconds": time.perf_counter() - started,
        "circuit": str(CIRCUIT), "elliptic_source": str(ELLIPTIC),
    }
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({
        "status": result["status"], "prime": args.prime, "p": result["p"],
        "outputs": len(outputs),
        "rational_source_replay_comparisons":
            result["rational_source_replay_comparisons"],
        "output": str(args.output),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
