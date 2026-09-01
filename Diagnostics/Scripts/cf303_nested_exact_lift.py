#!/usr/bin/env python3
"""Adaptive cross-prime lift of accepted nested p/epsilon artifacts.

Inputs are ordered independent-prime outputs of
cf303_nested_p_epsilon_lift.py. Prefixes are lifted over Q and the next
accepted image is reserved for coefficient-wise validation. Re-running with
additional images resumes the campaign without recomputing any modular image.

Only the diagnostic artifact schema is used. In particular, backend choices,
paths, timings, and worker allocations are deliberately absent from the
mathematical contract. This script launches no Wolfram or Maple kernel.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import time
from fractions import Fraction
from pathlib import Path
from typing import Any


IMAGE_STATUS = "CF303NestedPEpsilonLiftAcceptedV1"
ACCEPTED_STATUS = "CF303NestedPEpsilonExactLiftAcceptedV1"
INCOMPLETE_STATUS = "CF303NestedPEpsilonExactLiftIncompleteV1"
CONTRACT_FIELDS = (
    "block",
    "construction_p",
    "heldout_p",
    "epsilon_values",
    "epsilon_heldout",
    "u_train",
    "u_heldout",
    "coordinate_count",
)
PROFILE_FIELDS = (
    "key",
    "numerator_degree",
    "denominator_degree",
    "total_degree",
)


def atomic_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    os.replace(temporary, path)


def is_integer(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def profile_layout(profile: dict[str, Any]) -> tuple[Any, ...]:
    return (
        tuple(profile["key"]),
        int(profile["numerator_degree"]),
        int(profile["denominator_degree"]),
        int(profile["total_degree"]),
        len(profile["numerator"]),
        len(profile["denominator"]),
    )


def load_image(path: Path) -> dict[str, Any]:
    record = json.loads(path.read_text())
    if record.get("status") != IMAGE_STATUS:
        raise RuntimeError(f"not an accepted nested image: {path}")
    prime = record.get("prime")
    if not is_integer(prime) or prime <= 2:
        raise RuntimeError(f"invalid prime field: {path}")
    profiles = record.get("nested_lifted_coordinates")
    if not isinstance(profiles, list) or not profiles:
        raise RuntimeError(f"missing nested coordinate profiles: {path}")
    if record.get("coordinate_count") != len(profiles):
        raise RuntimeError(f"coordinate count mismatch: {path}")

    keys: set[tuple[Any, ...]] = set()
    for ordinal, profile in enumerate(profiles):
        if not isinstance(profile, dict) or any(
            field not in profile for field in PROFILE_FIELDS
        ):
            raise RuntimeError(f"invalid profile {ordinal}: {path}")
        key = profile.get("key")
        if not isinstance(key, list) or not key:
            raise RuntimeError(f"invalid key at profile {ordinal}: {path}")
        frozen_key = tuple(key)
        if frozen_key in keys:
            raise RuntimeError(f"duplicate coordinate key {key}: {path}")
        keys.add(frozen_key)

        numerator = profile.get("numerator")
        denominator = profile.get("denominator")
        if not isinstance(numerator, list) or not numerator or not all(
            is_integer(value) and 0 <= value < prime for value in numerator
        ):
            raise RuntimeError(f"invalid numerator at {key}: {path}")
        if not isinstance(denominator, list) or not denominator or not all(
            is_integer(value) and 0 <= value < prime for value in denominator
        ):
            raise RuntimeError(f"invalid denominator at {key}: {path}")

        numerator_degree = profile["numerator_degree"]
        denominator_degree = profile["denominator_degree"]
        total_degree = profile["total_degree"]
        if not all(is_integer(value) for value in (
            numerator_degree, denominator_degree, total_degree
        )):
            raise RuntimeError(f"invalid degree metadata at {key}: {path}")
        expected_numerator_length = max(1, numerator_degree + 1)
        if (
            numerator_degree < -1
            or denominator_degree < 0
            or len(numerator) != expected_numerator_length
            or len(denominator) != denominator_degree + 1
            or denominator[-1] != 1
            or total_degree != max(0, numerator_degree + denominator_degree)
        ):
            raise RuntimeError(f"profile layout mismatch at {key}: {path}")
        if numerator_degree == -1 and numerator != [0]:
            raise RuntimeError(f"nonzero degree-minus-one profile at {key}: {path}")
    return record


def mathematical_contract(record: dict[str, Any]) -> dict[str, Any]:
    missing = [field for field in CONTRACT_FIELDS if field not in record]
    if missing:
        raise RuntimeError(f"nested image lacks contract fields: {missing}")
    return {field: record[field] for field in CONTRACT_FIELDS}


def require_common_layout(records: list[dict[str, Any]]) -> list[tuple[Any, ...]]:
    reference_contract = mathematical_contract(records[0])
    reference_layout = [
        profile_layout(profile)
        for profile in records[0]["nested_lifted_coordinates"]
    ]
    for record in records[1:]:
        if mathematical_contract(record) != reference_contract:
            raise RuntimeError(
                f"prime {record['prime']} has a different mathematical contract"
            )
        layout = [
            profile_layout(profile)
            for profile in record["nested_lifted_coordinates"]
        ]
        if layout != reference_layout:
            raise RuntimeError(
                f"prime {record['prime']} has a different key/profile layout"
            )
    return reference_layout


def reduce_fraction(value: Fraction, prime: int) -> int:
    denominator = value.denominator % prime
    if denominator == 0:
        raise ZeroDivisionError(
            f"reconstructed denominator vanishes modulo validation prime {prime}"
        )
    return value.numerator % prime * pow(denominator, prime - 2, prime) % prime


def rational_reconstruct(residue: int, modulus: int) -> Fraction | None:
    residue %= modulus
    bound = math.isqrt(modulus // 2)
    r0, s0 = modulus, 0
    r1, s1 = residue, 1
    while r1 >= bound:
        quotient = r0 // r1
        r0, r1 = r1, r0 - quotient * r1
        s0, s1 = s1, s0 - quotient * s1
    if s1 == 0 or abs(s1) >= bound:
        return None
    numerator, denominator = (r1, s1) if s1 > 0 else (-r1, -s1)
    result = Fraction(numerator, denominator)
    if math.gcd(result.denominator, modulus) != 1:
        return None
    if (result.numerator - residue * result.denominator) % modulus:
        return None
    return result


def crt_weights(primes: list[int]) -> tuple[int, list[int]]:
    modulus = math.prod(primes)
    weights: list[int] = []
    for prime in primes:
        partial = modulus // prime
        weights.append(partial * pow(partial % prime, prime - 2, prime))
    return modulus, weights


def lift_value(
    values: list[int], primes: list[int], modulus: int, weights: list[int]
) -> Fraction | None:
    residue = sum(
        (value % prime) * weight
        for value, prime, weight in zip(values, primes, weights, strict=True)
    ) % modulus
    result = rational_reconstruct(residue, modulus)
    if result is None:
        return None
    if any(
        reduce_fraction(result, prime) != value
        for value, prime in zip(values, primes, strict=True)
    ):
        raise RuntimeError("internal CRT reduction mismatch")
    return result


def lift_records(records: list[dict[str, Any]]) -> tuple[dict[str, Any], dict[str, Any]]:
    primes = [int(record["prime"]) for record in records]
    modulus, weights = crt_weights(primes)
    output_profiles: list[dict[str, Any]] = []
    unresolved: list[list[Any]] = []
    unresolved_count = 0
    coefficient_count = 0
    maximum_numerator_bits = 0
    maximum_denominator_bits = 0

    for profile_index, reference in enumerate(
        records[0]["nested_lifted_coordinates"]
    ):
        output = {field: reference[field] for field in PROFILE_FIELDS}
        for array_name in ("numerator", "denominator"):
            exact: list[Fraction | None] = []
            for coefficient_index in range(len(reference[array_name])):
                coefficient_count += 1
                value = lift_value(
                    [
                        record["nested_lifted_coordinates"][profile_index]
                        [array_name][coefficient_index]
                        for record in records
                    ],
                    primes,
                    modulus,
                    weights,
                )
                exact.append(value)
                if value is None:
                    unresolved_count += 1
                    if len(unresolved) < 64:
                        unresolved.append([
                            *reference["key"], array_name, coefficient_index
                        ])
                else:
                    maximum_numerator_bits = max(
                        maximum_numerator_bits, abs(value.numerator).bit_length()
                    )
                    maximum_denominator_bits = max(
                        maximum_denominator_bits, value.denominator.bit_length()
                    )
            output[array_name] = exact
        output_profiles.append(output)

    statistics = {
        "coefficient_count": coefficient_count,
        "unresolved_coefficient_count": unresolved_count,
        "unresolved_location_sample": unresolved,
        "maximum_reconstructed_numerator_bits": maximum_numerator_bits,
        "maximum_reconstructed_denominator_bits": maximum_denominator_bits,
        "combined_modulus_bits": modulus.bit_length(),
    }
    return {
        "nested_lifted_coordinates": output_profiles,
        "modulus": modulus,
    }, statistics


def validate_candidate(
    lifted: dict[str, Any], validation: dict[str, Any]
) -> dict[str, Any]:
    prime = int(validation["prime"])
    comparisons = 0
    mismatch_count = 0
    mismatches: list[list[Any]] = []
    for exact_profile, modular_profile in zip(
        lifted["nested_lifted_coordinates"],
        validation["nested_lifted_coordinates"],
        strict=True,
    ):
        for array_name in ("numerator", "denominator"):
            for coefficient_index, (exact, modular) in enumerate(zip(
                exact_profile[array_name], modular_profile[array_name], strict=True
            )):
                if exact is None:
                    raise RuntimeError("cannot validate an unresolved candidate")
                comparisons += 1
                if reduce_fraction(exact, prime) != modular:
                    mismatch_count += 1
                    if len(mismatches) < 64:
                        mismatches.append([
                            *exact_profile["key"], array_name, coefficient_index
                        ])
    return {
        "validation_prime": prime,
        "validation_comparisons": comparisons,
        "validation_mismatch_count": mismatch_count,
        "validation_mismatch_sample": mismatches,
    }


def encode_fractions(value: Any) -> Any:
    if isinstance(value, Fraction):
        return [value.numerator, value.denominator]
    if isinstance(value, list):
        return [encode_fractions(item) for item in value]
    if isinstance(value, dict):
        return {key: encode_fractions(item) for key, item in value.items()}
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--images", nargs="+", type=Path, required=True,
        help=(
            "ordered accepted nested images; each prefix is a CRT set and "
            "the following image is its disjoint validation prime"
        ),
    )
    parser.add_argument("--minimum-lift-primes", type=int, default=2)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.minimum_lift_primes < 1:
        raise RuntimeError("minimum lift-prime count must be positive")
    if len(args.images) < args.minimum_lift_primes + 1:
        raise RuntimeError(
            "need the minimum CRT images plus one disjoint validation image"
        )

    records = [load_image(path) for path in args.images]
    primes = [int(record["prime"]) for record in records]
    if len(set(primes)) != len(primes):
        raise RuntimeError("nested images must have distinct primes")
    require_common_layout(records)

    started = time.perf_counter()
    attempts: list[dict[str, Any]] = []
    accepted_lift: dict[str, Any] | None = None
    accepted_validation: dict[str, Any] | None = None
    accepted_statistics: dict[str, Any] | None = None
    for lift_count in range(args.minimum_lift_primes, len(records)):
        lift_started = time.perf_counter()
        candidate, statistics = lift_records(records[:lift_count])
        attempt = {
            "lift_primes": primes[:lift_count],
            **statistics,
            "lift_seconds": time.perf_counter() - lift_started,
            "validation_prime": primes[lift_count],
            "validation_status": "NotAttempted",
        }
        if statistics["unresolved_coefficient_count"] == 0:
            validation = validate_candidate(candidate, records[lift_count])
            attempt.update(validation)
            attempt["validation_status"] = (
                "Accepted" if validation["validation_mismatch_count"] == 0
                else "Mismatch"
            )
            if validation["validation_mismatch_count"] == 0:
                accepted_lift = candidate
                accepted_validation = validation
                accepted_statistics = statistics
                attempts.append(attempt)
                break
        attempts.append(attempt)

    accepted = accepted_lift is not None
    last_attempt = attempts[-1]
    chosen_statistics = accepted_statistics or last_attempt
    report = {
        "status": ACCEPTED_STATUS if accepted else INCOMPLETE_STATUS,
        "block": records[0]["block"],
        "mathematical_contract": mathematical_contract(records[0]),
        "available_primes": primes,
        "minimum_lift_primes": args.minimum_lift_primes,
        "attempts": attempts,
        "lift_primes": attempts[-1]["lift_primes"],
        "prime_count": len(attempts[-1]["lift_primes"]),
        "combined_modulus_bits": chosen_statistics["combined_modulus_bits"],
        "coefficient_count": last_attempt["coefficient_count"],
        "unresolved_coefficient_count": (
            0 if accepted else last_attempt["unresolved_coefficient_count"]
        ),
        "unresolved_location_sample": (
            [] if accepted else last_attempt["unresolved_location_sample"]
        ),
        "maximum_reconstructed_numerator_bits": (
            chosen_statistics["maximum_reconstructed_numerator_bits"]
        ),
        "maximum_reconstructed_denominator_bits": (
            chosen_statistics["maximum_reconstructed_denominator_bits"]
        ),
        "validation_prime": (
            accepted_validation["validation_prime"]
            if accepted_validation else last_attempt.get("validation_prime")
        ),
        "validation_comparisons": (
            accepted_validation["validation_comparisons"]
            if accepted_validation
            else last_attempt.get("validation_comparisons", 0)
        ),
        "validation_mismatch_count": (
            accepted_validation["validation_mismatch_count"]
            if accepted_validation
            else last_attempt.get("validation_mismatch_count")
        ),
        "validation_mismatch_sample": (
            accepted_validation["validation_mismatch_sample"]
            if accepted_validation
            else last_attempt.get("validation_mismatch_sample", [])
        ),
        "wall_seconds": time.perf_counter() - started,
        "claim": (
            "Every modular integer in every nested p numerator and denominator "
            "array is lifted over Q and replayed coefficient-wise at one "
            "disjoint independently accepted prime image."
            if accepted else
            "Available accepted images do not yet determine and validate every "
            "nested coefficient over Q; append another image and rerun."
        ),
    }
    atomic_json(args.report, report)
    if not accepted:
        print(json.dumps(report, indent=2))
        return 4

    exact = {
        "status": ACCEPTED_STATUS,
        "block": records[0]["block"],
        "coefficient_encoding": "[numerator, denominator]",
        "mathematical_contract": mathematical_contract(records[0]),
        "lift_primes": attempts[-1]["lift_primes"],
        "combined_modulus_bits": accepted_statistics["combined_modulus_bits"],
        "validation_prime": accepted_validation["validation_prime"],
        "validation_comparisons": accepted_validation["validation_comparisons"],
        "nested_lifted_coordinates": accepted_lift[
            "nested_lifted_coordinates"
        ],
    }
    atomic_json(args.output, encode_fractions(exact))
    print(json.dumps(report, indent=2))
    print(f"REPORT={args.report}")
    print(f"OUTPUT={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
