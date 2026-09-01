#!/usr/bin/env python3
"""Fresh-prime functional test of two-prime CF303 nested candidates.

The mixed candidate uses q1 EEA coefficients selected by q2, strict q1*q2
Wang reconstruction, then low-threshold MQRR. The shared-scale candidate uses
exact factored p-denominators and one primitive integer scale per p-profile.
Both are tested against fresh-q reduced data without a full nested q image.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
import os
import subprocess
import sys
import time
from collections import Counter, defaultdict
from fractions import Fraction
from pathlib import Path
from typing import Any

import sympy


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
EXACT_LIFT = ROOT / "Diagnostics/Scripts/cf303_nested_exact_lift.py"
ANALYSIS = ROOT / "Diagnostics/Scripts/analyze_cf303_nested_q_reconstruction.py"
SCALAR = ROOT / (
    "Diagnostics/Scripts/cf303_scalar_modular_algebraic_hermite_pilot.py"
)
OUTPUT_ROOT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
DEFAULT_Q1 = OUTPUT_ROOT / (
    "cf303_block1_nested_p_epsilon_q2305843009213691819.json"
)
DEFAULT_Q2 = OUTPUT_ROOT / (
    "cf303_block1_nested_p_epsilon_q2305843009213641971.json"
)
DEFAULT_POINTS = (
    (Fraction(211, 37), 37),
    (Fraction(223, 41), 43),
    (Fraction(227, 43), 47),
)


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


def atomic_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    os.replace(temporary, path)


def multiply(left: list[Fraction], right: list[Fraction]) -> list[Fraction]:
    result = [Fraction(0)] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            result[i + j] += a * b
    return result


def power(polynomial: list[Fraction], exponent: int) -> list[Fraction]:
    result = [Fraction(1)]
    base = polynomial
    while exponent:
        if exponent & 1:
            result = multiply(result, base)
        exponent >>= 1
        if exponent:
            base = multiply(base, base)
    return result


def modular_multiply(left: list[int], right: list[int], prime: int) -> list[int]:
    result = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            result[i + j] = (result[i + j] + a * b) % prime
    return result


def reduce_fraction(value: Fraction, prime: int) -> int:
    denominator = value.denominator % prime
    if denominator == 0:
        raise ZeroDivisionError("candidate denominator vanished at fresh prime")
    return value.numerator % prime * pow(denominator, prime - 2, prime) % prime


def reduce_polynomial(polynomial: list[Fraction], prime: int) -> list[int]:
    return [reduce_fraction(value, prime) for value in polynomial]


def evaluate(polynomial: list[Fraction], value: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(polynomial):
        result = (
            result * value + reduce_fraction(coefficient, prime)
        ) % prime
    return result


def balanced(value: int, modulus: int) -> int:
    value %= modulus
    return value - modulus if value > modulus // 2 else value


def exact_factored_denominator(
    modular: list[int], prime: int, strict_reconstruct
) -> tuple[list[Fraction], dict[str, int]]:
    if modular == [1]:
        return [Fraction(1)], {"factor_count": 0, "recombined_count": 0}
    variable = sympy.symbols("p")
    polynomial = sympy.Poly.from_list(
        list(reversed(modular)), gens=variable, modulus=prime
    )
    unit, factors = sympy.factor_list(polynomial)
    if int(unit) % prime != 1:
        raise RuntimeError("nonmonic modular factorization")
    exact_factors: list[tuple[list[Fraction], int]] = []
    unresolved: list[tuple[list[int], int]] = []
    for factor, exponent in factors:
        coefficients = [
            int(value) % prime for value in reversed(factor.all_coeffs())
        ]
        lifted = [strict_reconstruct(value, prime) for value in coefficients]
        if all(value is not None for value in lifted):
            exact_factors.append((lifted, exponent))
        else:
            unresolved.append((coefficients, exponent))
    recombined = 0
    if unresolved:
        exponents = {exponent for _, exponent in unresolved}
        if len(unresolved) != 2 or len(exponents) != 1:
            raise RuntimeError(
                f"unrecognized modular denominator factors: {unresolved}"
            )
        product = modular_multiply(
            unresolved[0][0], unresolved[1][0], prime
        )
        lifted = [strict_reconstruct(value, prime) for value in product]
        if any(value is None for value in lifted):
            raise RuntimeError("conjugate factor product did not lift over Q")
        exact_factors.append((lifted, unresolved[0][1]))
        recombined = 1
    result = [Fraction(1)]
    for factor, exponent in exact_factors:
        result = multiply(result, power(factor, exponent))
    if result[-1] != 1 or reduce_polynomial(result, prime) != modular:
        raise RuntimeError("exact factored denominator replay failed")
    return result, {
        "factor_count": len(factors),
        "recombined_count": recombined,
    }


def crt_residue(values: list[int], weights: list[int], modulus: int) -> int:
    return sum(
        value * weight
        for value, weight in zip(values, weights, strict=True)
    ) % modulus


def build_candidates(q1: dict[str, Any], q2: dict[str, Any], lift, analysis):
    primes = [int(q1["prime"]), int(q2["prime"])]
    modulus, weights = lift.crt_weights(primes)
    q1_profiles = q1["nested_lifted_coordinates"]
    q2_profiles = q2["nested_lifted_coordinates"]
    denominator_cache: dict[tuple[int, ...], list[Fraction]] = {}
    factor_statistics = Counter()
    mixed_profiles = []
    structural_profiles = []
    mixed_sources = Counter()
    structural_statistics = Counter()
    structural_integer_bits = Counter()
    oracle_values_by_profile: list[list[Fraction | None]] = []

    for left, right in zip(q1_profiles, q2_profiles, strict=True):
        oracle_values = []
        for q1_value, q2_value in zip(
            left["numerator"], right["numerator"], strict=True
        ):
            candidate, _ = analysis.oracle_eea_reconstruct(
                q1_value, primes[0], q2_value, primes[1]
            )
            oracle_values.append(candidate)
        oracle_values_by_profile.append(oracle_values)

    for profile_index, (left, right) in enumerate(
        zip(q1_profiles, q2_profiles, strict=True)
    ):
        modular_denominator = tuple(left["denominator"])
        if modular_denominator not in denominator_cache:
            exact_denominator, statistics = exact_factored_denominator(
                list(modular_denominator), primes[0],
                lift.rational_reconstruct,
            )
            if reduce_polynomial(exact_denominator, primes[1]) != right["denominator"]:
                raise RuntimeError(
                    f"factored denominator disagrees at q2: {left['key']}"
                )
            denominator_cache[modular_denominator] = exact_denominator
            factor_statistics.update(statistics)
        exact_denominator = denominator_cache[modular_denominator]
        oracle_values = oracle_values_by_profile[profile_index]

        mixed_numerator = []
        for coefficient_index, (q1_value, q2_value, oracle) in enumerate(zip(
            left["numerator"], right["numerator"], oracle_values, strict=True
        )):
            residue = crt_residue(
                [q1_value, q2_value], weights, modulus
            )
            if oracle is not None:
                candidate = oracle
                source = "Q1EEAValidatedAtQ2"
            else:
                candidate = lift.rational_reconstruct(residue, modulus)
                source = "Q1Q2Wang"
                if candidate is None:
                    candidate, _ = analysis.maximal_quotient_reconstruct(
                        residue, modulus, 4
                    )
                    source = "Q1Q2MQRRThreshold4"
            if candidate is None:
                raise RuntimeError(
                    f"candidate missing at {left['key']}:numerator:"
                    f"{coefficient_index}"
                )
            mixed_numerator.append(candidate)
            mixed_sources[source] += 1

        common_scale = 1
        for coefficient in exact_denominator:
            common_scale = math.lcm(common_scale, coefficient.denominator)
        for oracle in oracle_values:
            if oracle is not None:
                common_scale = math.lcm(common_scale, oracle.denominator)
        structural_numerator = []
        oracle_disagreements = 0
        for q1_value, q2_value, oracle in zip(
            left["numerator"], right["numerator"], oracle_values, strict=True
        ):
            residue = crt_residue(
                [q1_value, q2_value], weights, modulus
            )
            integer = balanced(
                residue * (common_scale % modulus), modulus
            )
            candidate = Fraction(integer, common_scale)
            structural_integer_bits[abs(integer).bit_length()] += 1
            if oracle is not None:
                if candidate != oracle:
                    oracle_disagreements += 1
                candidate = oracle
            structural_numerator.append(candidate)
        structural_statistics["profile_count"] += 1
        structural_statistics["oracle_seeded_profiles"] += bool(
            [value for value in oracle_values if value is not None]
        )
        structural_statistics["oracle_coefficient_disagreements"] += (
            oracle_disagreements
        )
        structural_statistics[
            f"scale_bits_{common_scale.bit_length()}"
        ] += 1

        common = {
            name: left[name] for name in (
                "key", "numerator_degree", "denominator_degree", "total_degree"
            )
        }
        mixed_profiles.append({
            **common,
            "numerator": mixed_numerator,
            "denominator": exact_denominator,
        })
        structural_profiles.append({
            **common,
            "numerator": structural_numerator,
            "denominator": exact_denominator,
        })
    return {
        "mixed": mixed_profiles,
        "shared_scale": structural_profiles,
    }, {
        "modulus_bits": modulus.bit_length(),
        "unique_exact_p_denominators": len(denominator_cache),
        "denominator_factor_statistics": dict(factor_statistics),
        "mixed_sources": dict(mixed_sources),
        "shared_scale": dict(structural_statistics),
        "shared_scale_balanced_integer_bits": {
            str(bits): count
            for bits, count in sorted(structural_integer_bits.items())
        },
    }


def evaluate_p_profile(
    profile: dict[str, Any], p_value: int, prime: int
) -> int:
    numerator = evaluate(profile["numerator"], p_value, prime)
    denominator = evaluate(profile["denominator"], p_value, prime)
    if denominator == 0:
        raise ZeroDivisionError(f"p-profile pole at {profile['key']}")
    return numerator * pow(denominator, prime - 2, prime) % prime


def predicted_reductions(
    profiles: list[dict[str, Any]], p_value: Fraction,
    epsilon: int, prime: int,
) -> dict[str, dict[str, list[int]]]:
    p_mod = reduce_fraction(p_value, prime)
    denominators: dict[tuple[str, str], dict[int, int]] = defaultdict(dict)
    epsilon_profiles: dict[
        tuple[str, str, int], dict[str, dict[int, int]]
    ] = defaultdict(lambda: {"numerator": {}, "denominator": {}})
    for profile in profiles:
        key = profile["key"]
        value = evaluate_p_profile(profile, p_mod, prime)
        if key[0] == "u_denominator":
            _, channel, field, index = key
            denominators[(channel, field)][int(index)] = value
        elif key[0] == "epsilon_profile":
            _, channel, field, index, part, epsilon_index = key
            epsilon_profiles[(channel, field, int(index))][part][
                int(epsilon_index)
            ] = value
        else:
            raise RuntimeError(f"unknown nested key {key}")

    output: dict[str, dict[str, list[int]]] = defaultdict(dict)
    for (channel, field), coefficients in denominators.items():
        if set(coefficients) != set(range(len(coefficients))):
            raise RuntimeError(f"noncontiguous denominator {channel}:{field}")
        output[channel][field] = [
            coefficients[index] for index in range(len(coefficients))
        ]
    grouped: dict[tuple[str, str], dict[int, int]] = defaultdict(dict)
    for (channel, field, index), parts in epsilon_profiles.items():
        arrays = {}
        for part in ("numerator", "denominator"):
            coefficients = parts[part]
            if set(coefficients) != set(range(len(coefficients))):
                raise RuntimeError(
                    f"noncontiguous epsilon {channel}:{field}:{index}:{part}"
                )
            arrays[part] = [
                coefficients[position] for position in range(len(coefficients))
            ]
        numerator = 0
        for coefficient in reversed(arrays["numerator"]):
            numerator = (numerator * epsilon + coefficient) % prime
        denominator = 0
        for coefficient in reversed(arrays["denominator"]):
            denominator = (denominator * epsilon + coefficient) % prime
        if denominator == 0:
            raise ZeroDivisionError(
                f"epsilon-profile pole at {channel}:{field}:{index}"
            )
        grouped[(channel, field)][index] = (
            numerator * pow(denominator, prime - 2, prime) % prime
        )
    for (channel, field), coefficients in grouped.items():
        if set(coefficients) != set(range(len(coefficients))):
            raise RuntimeError(f"noncontiguous reduced field {channel}:{field}")
        output[channel][field] = [
            coefficients[index] for index in range(len(coefficients))
        ]
    return dict(output)


def scalar_image(
    *, prime: int, p_value: Fraction, epsilon: int, threads: int,
    directory: Path,
) -> tuple[dict[str, Any], float]:
    target = directory / (
        f"block1_q{prime}_p{p_value.numerator}d{p_value.denominator}_"
        f"e{epsilon}.json"
    )
    if target.exists():
        record = json.loads(target.read_text())
        if (
            record.get("status")
                == "CF303ScalarModularAlgebraicHermitePilotAcceptedV1"
            and record.get("prime") == prime
            and record.get("p") == [p_value.numerator, p_value.denominator]
            and record.get("epsilon") == epsilon
        ):
            return record, 0.0
    command = [
        sys.executable, str(SCALAR), "--block", "1",
        "--prime", str(prime), "--p", str(p_value),
        "--epsilon", str(epsilon), "--train", "125", "--heldout", "4",
        "--threads", str(threads), "--backend", "selected",
        "--parallel-mode", "image", "--output", str(target),
    ]
    started = time.perf_counter()
    process = subprocess.run(
        command, cwd=ROOT, capture_output=True, text=True, check=False
    )
    wall = time.perf_counter() - started
    if process.returncode or not target.exists():
        raise RuntimeError(
            "fresh scalar image failed:\n"
            + (process.stderr + "\n" + process.stdout[-2000:])[-4000:]
        )
    record = json.loads(target.read_text())
    if record.get("status") != "CF303ScalarModularAlgebraicHermitePilotAcceptedV1":
        raise RuntimeError("fresh scalar image was not accepted")
    return record, wall


def compare(
    predicted: dict[str, dict[str, list[int]]],
    observed: dict[str, Any],
) -> dict[str, Any]:
    mismatches = Counter()
    samples = []
    comparisons = 0
    dynamic_comparisons = 0
    denominator_comparisons = 0
    for channel, fields in predicted.items():
        reduction = observed["channels"][channel]["reduction"]
        for field, values in fields.items():
            expected = reduction[field]
            if len(values) != len(expected):
                raise RuntimeError(f"length mismatch {channel}:{field}")
            for index, (left, right) in enumerate(
                zip(values, expected, strict=True)
            ):
                comparisons += 1
                if "denominator" in field:
                    denominator_comparisons += 1
                else:
                    dynamic_comparisons += 1
                if left != right:
                    mismatches[(channel, field)] += 1
                    if len(samples) < 64:
                        samples.append([channel, field, index, left, right])
    return {
        "comparisons": comparisons,
        "dynamic_comparisons": dynamic_comparisons,
        "denominator_comparisons": denominator_comparisons,
        "mismatch_count": sum(mismatches.values()),
        "mismatches_by_channel_field": {
            f"{channel}:{field}": count
            for (channel, field), count in sorted(mismatches.items())
        },
        "mismatch_sample": samples,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--q1", type=Path, default=DEFAULT_Q1)
    parser.add_argument("--q2", type=Path, default=DEFAULT_Q2)
    parser.add_argument(
        "--validation-prime", type=int,
        default=2_305_843_009_213_693_951,
    )
    parser.add_argument("--threads", type=int, default=4)
    parser.add_argument(
        "--output", type=Path,
        default=OUTPUT_ROOT / "cf303_block1_two_prime_candidate_validation.json",
    )
    args = parser.parse_args()
    lift = load_module("cf303_nested_candidate_lift", EXACT_LIFT)
    analysis = load_module("cf303_nested_candidate_analysis", ANALYSIS)
    q1 = lift.load_image(args.q1)
    q2 = lift.load_image(args.q2)
    lift.require_common_layout([q1, q2])
    build_started = time.perf_counter()
    candidates, construction = build_candidates(q1, q2, lift, analysis)
    construction["wall_seconds"] = time.perf_counter() - build_started

    image_directory = args.output.parent / "nested_candidate_validation_images"
    image_directory.mkdir(parents=True, exist_ok=True)
    point_reports = []
    for p_value, epsilon in DEFAULT_POINTS:
        record, wall = scalar_image(
            prime=args.validation_prime, p_value=p_value,
            epsilon=epsilon, threads=args.threads,
            directory=image_directory,
        )
        candidate_reports = {}
        for name, profiles in candidates.items():
            predicted = predicted_reductions(
                profiles, p_value, epsilon, args.validation_prime
            )
            candidate_reports[name] = compare(predicted, record)
        point_reports.append({
            "p": [p_value.numerator, p_value.denominator],
            "epsilon": epsilon,
            "scalar_wall": wall,
            "scalar_native_wall": record["timings"]["native_wall"],
            "candidates": candidate_reports,
        })
        print(
            f"POINT p={p_value} epsilon={epsilon} wall={wall:.3f} "
            + " ".join(
                f"{name}_mismatch={report['mismatch_count']}"
                for name, report in candidate_reports.items()
            ),
            flush=True,
        )
    totals = {
        name: {
            "comparison_count": sum(
                point["candidates"][name]["comparisons"]
                for point in point_reports
            ),
            "mismatch_count": sum(
                point["candidates"][name]["mismatch_count"]
                for point in point_reports
            ),
        }
        for name in candidates
    }
    report = {
        "status": "CF303NestedTwoPrimeCandidateFreshPointValidationV1",
        "q_images": [int(q1["prime"]), int(q2["prime"])],
        "validation_prime": args.validation_prime,
        "fresh_point_count": len(DEFAULT_POINTS),
        "construction": construction,
        "points": point_reports,
        "totals": totals,
        "accepted_candidates": [
            name for name, total in totals.items()
            if total["mismatch_count"] == 0
        ],
    }
    atomic_json(args.output, report)
    print(json.dumps({
        "status": report["status"],
        "construction": construction,
        "totals": totals,
        "accepted_candidates": report["accepted_candidates"],
        "output": str(args.output),
    }, indent=2))
    return 0 if report["accepted_candidates"] else 4


if __name__ == "__main__":
    raise SystemExit(main())
