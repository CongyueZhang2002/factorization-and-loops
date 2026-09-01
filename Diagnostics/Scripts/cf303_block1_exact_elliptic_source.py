#!/usr/bin/env python3
"""Extract and validate the exact elliptic source channel of CF303 (25,1)."""

from __future__ import annotations

import importlib.util
import json
import sys
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
OUT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
SCRIPTS = ROOT / "Diagnostics/Scripts"
Q1 = OUT / "cf303_block1_nested_p_epsilon_q2305843009213691819.json"
Q2 = OUT / "cf303_block1_nested_p_epsilon_q2305843009213641971.json"
FRESH = (
    OUT / "cf303_block1_circuit_q7_p3_fixed_epsilon.json",
    OUT / "cf303_block1_circuit_q7_p239d47_fixed_epsilon.json",
)
OUTPUT = OUT / "cf303_block1_exact_elliptic_source.json"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def encode(value: Any):
    if isinstance(value, Fraction):
        return [value.numerator, value.denominator]
    if isinstance(value, list):
        return [encode(item) for item in value]
    if isinstance(value, dict):
        return {key: encode(item) for key, item in value.items()}
    return value


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
    numerator = polynomial_value(profile["numerator"], p_value, prime)
    denominator = polynomial_value(profile["denominator"], p_value, prime)
    if denominator == 0:
        raise ZeroDivisionError(f"candidate pole at {profile['key']}")
    return numerator * pow(denominator, prime - 2, prime) % prime


def fixed_values(record: dict[str, Any]) -> dict[tuple[Any, ...], int]:
    values = {}
    for channel, fields in record["stable_monic_denominators"].items():
        if not channel.endswith("elliptic"):
            continue
        for field, coefficients in fields.items():
            for index, coefficient in enumerate(coefficients):
                values[("u_denominator", channel, field, index)] = coefficient
    for coordinate in record["lifted_coordinates"]:
        channel = coordinate["channel"]
        if not channel.endswith("elliptic"):
            continue
        base = ("epsilon_profile", channel, coordinate["field"],
                int(coordinate["index"]))
        for part in ("numerator", "denominator"):
            for index, coefficient in enumerate(coordinate[part]):
                values[base + (part, index)] = coefficient
    return values


def main() -> int:
    lift = load_module("cf303_elliptic_lift", SCRIPTS / "cf303_nested_exact_lift.py")
    analysis = load_module(
        "cf303_elliptic_analysis",
        SCRIPTS / "analyze_cf303_nested_q_reconstruction.py",
    )
    candidate = load_module(
        "cf303_elliptic_candidates",
        SCRIPTS / "cf303_nested_candidate_point_validation.py",
    )
    q1, q2 = lift.load_image(Q1), lift.load_image(Q2)
    candidates, statistics = candidate.build_candidates(q1, q2, lift, analysis)
    elliptic = [profile for profile in candidates["shared_scale"]
                if len(profile["key"]) > 1
                and str(profile["key"][1]).endswith("elliptic")]
    if len(elliptic) != 238:
        raise RuntimeError(f"elliptic exact profile layout {len(elliptic)}/238")
    primitive_dynamic = [profile for profile in elliptic
        if profile["key"][0] == "epsilon_profile"
        and profile["key"][2] == "primitive_numerator"
        and profile["key"][4] == "numerator"]
    primitive_zero = bool(primitive_dynamic) and all(
        all(value == 0 for value in profile["numerator"])
        for profile in primitive_dynamic
    )
    if not primitive_zero:
        raise RuntimeError("elliptic primitive is not identically zero")

    fresh_reports = []
    comparison_total = 0
    for path in FRESH:
        fixed = json.loads(path.read_text())
        if fixed.get("status") != "CF303FixedPEpsilonLiftAcceptedV1":
            raise RuntimeError(f"fresh elliptic source record rejected: {path}")
        expected = fixed_values(fixed)
        prime = fixed["prime"]
        p_value = fraction_mod(Fraction(*fixed["p"]), prime)
        mismatches = []
        for profile in elliptic:
            key = tuple(profile["key"])
            observed = expected.get(key)
            candidate_value = profile_value(profile, p_value, prime)
            if observed is None or candidate_value != observed:
                mismatches.append([list(key), candidate_value, observed])
        if mismatches:
            raise RuntimeError(
                f"fresh elliptic candidate mismatch at {fixed['p']}: "
                f"{mismatches[:3]}"
            )
        comparisons = len(elliptic)
        comparison_total += comparisons
        fresh_reports.append({
            "prime": prime, "p": fixed["p"], "comparisons": comparisons,
            "raw_source_lift": str(path), "mismatches": 0,
        })

    outputs = [{
        "order": order, "row": row,
        "h_elliptic": "Zero",
        "y0_constant": "Zero",
        "k_elliptic": {
            "source": "exact_profiles",
            "channel": f"{row},1,elliptic",
            "epsilon_laurent_order": order,
            "components": ["remainder_numerator", "cohomology_coefficients"],
            "kernel_convention": "E4Factor/E4Pole with Yc kept symbolic",
        },
    } for order in range(-3, 5) for row in (1, 2)]
    result = {
        "status": "CF303Block1ExactEllipticSourceAcceptedV1",
        "block": [25, 1], "profile_count": len(elliptic),
        "exact_profiles": encode(elliptic),
        "elliptic_primitive_identically_zero": True,
        "path_gauge_consequence": (
            "D and S11 are rational, so rational/elliptic channels decouple. "
            "With every incoming elliptic primitive zero, H_n^elliptic and "
            "the Y0 base constant are zero for n=-3..4; K_n^elliptic is the "
            "exact source elliptic remainder/cohomology channel."
        ),
        "outputs": outputs,
        "fresh_validation": fresh_reports,
        "fresh_comparison_count": comparison_total,
        "candidate_statistics": {
            "modulus_bits": statistics["modulus_bits"],
            "shared_scale_profile_count": statistics["shared_scale"]["profile_count"],
        },
    }
    OUTPUT.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({
        "status": result["status"], "profiles": len(elliptic),
        "primitive_zero_profiles": len(primitive_dynamic),
        "fresh_comparisons": comparison_total, "outputs": len(outputs),
        "output": str(OUTPUT),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
