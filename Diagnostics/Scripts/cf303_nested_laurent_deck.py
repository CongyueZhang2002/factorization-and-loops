#!/usr/bin/env python3
"""Cancel epsilon dependence mod q before lifting CF303 block (25,1).

The accepted nested q images are a poor exact-lift basis: expanding the
monic rational-in-epsilon profiles first creates coefficients whose heights
are far larger than the physical Laurent coefficients.  This script reuses
the six cached q images, extracts the required epsilon Laurent deck modulo
each q, interpolates only those coefficients in p, and then lifts them over Q.

q1--q5 form the CRT modulus.  q6 selects a unique extended-Euclid convergent
coefficient by coefficient.  Acceptance is an end-to-end replay at three
fresh q7 p points, using nine raw scalar/Hermite epsilon images per point.
No symbolic Wolfram equality and no additional full q image are used.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import importlib.util
import json
import math
import os
import sys
import time
from collections import Counter, defaultdict
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
OUT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
EXACT_LIFT = ROOT / "Diagnostics/Scripts/cf303_nested_exact_lift.py"
ANALYSIS = ROOT / "Diagnostics/Scripts/analyze_cf303_nested_q_reconstruction.py"
CANDIDATE = ROOT / "Diagnostics/Scripts/cf303_nested_candidate_point_validation.py"
RATIONAL = ROOT / "Diagnostics/Scripts/cf303_block18_native_path_degree.py"
DEFAULT_Q1 = OUT / "cf303_block1_nested_p_epsilon_q2305843009213691819.json"
DEFAULT_Q2 = OUT / "cf303_block1_nested_p_epsilon_q2305843009213641971.json"
DEFAULT_TARGETED = tuple(
    OUT / f"cf303_block1_targeted_q{index}_numerators.json"
    for index in (3, 4, 5, 6)
)
DEFAULT_CENSUS = OUT / "cf303_block1_fixed_epsilon_p_census_fixed_replay.json"
DEFAULT_ORDERS = tuple(range(-3, 5))
VALIDATION_POINTS = (Fraction(239, 47), Fraction(241, 53), Fraction(251, 59))
VALIDATION_EPSILONS = tuple(range(31, 40))
RATIONAL_CHANNELS = {"1,1,rational", "2,1,rational"}
NUMERATOR_FIELDS = {"primitive_numerator", "remainder_numerator"}
MODULAR_STATUS = "CF303Block1ModularLaurentDeckAcceptedV1"
EXACT_STATUS = "CF303Block1ExactLaurentDeckAcceptedV1"
_WORKER: dict[str, Any] = {}


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def atomic_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    os.replace(temporary, path)


def encode_fractions(value: Any) -> Any:
    if isinstance(value, Fraction):
        return [value.numerator, value.denominator]
    if isinstance(value, list):
        return [encode_fractions(item) for item in value]
    if isinstance(value, dict):
        return {key: encode_fractions(item) for key, item in value.items()}
    return value


def reduce_fraction(value: Fraction, prime: int) -> int:
    denominator = value.denominator % prime
    if denominator == 0:
        raise ZeroDivisionError("exact denominator vanished modulo prime")
    return value.numerator % prime * pow(denominator, prime - 2, prime) % prime


def balanced(value: int, modulus: int) -> int:
    value %= modulus
    return value - modulus if value > modulus // 2 else value


def polynomial_value(coefficients: list[int], value: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * value + coefficient) % prime
    return result


def profile_value(profile: dict[str, Any], value: int, prime: int) -> int:
    numerator = polynomial_value(profile["numerator"], value, prime)
    denominator = polynomial_value(profile["denominator"], value, prime)
    if denominator == 0:
        raise ZeroDivisionError(f"p-profile pole at {profile['key']}")
    return numerator * pow(denominator, prime - 2, prime) % prime


def laurent_coefficient(
    numerator: list[int], denominator: list[int], order: int, prime: int,
) -> int:
    numerator_start = next(
        (index for index, value in enumerate(numerator) if value), None
    )
    denominator_start = next(
        (index for index, value in enumerate(denominator) if value), None
    )
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


def interpolate(xs: list[int], ys: list[int], prime: int) -> list[int]:
    divided = [value % prime for value in ys]
    for order in range(1, len(xs)):
        for index in range(len(xs) - 1, order - 1, -1):
            divided[index] = (
                (divided[index] - divided[index - 1])
                * pow(xs[index] - xs[index - order], prime - 2, prime)
            ) % prime
    result = [0] * len(xs)
    basis = [1]
    for order, coefficient in enumerate(divided):
        for index, value in enumerate(basis):
            result[index] = (result[index] + coefficient * value) % prime
        if order + 1 < len(xs):
            next_basis = [0] * (len(basis) + 1)
            for index, value in enumerate(basis):
                next_basis[index] = (next_basis[index] - xs[order] * value) % prime
                next_basis[index + 1] = (next_basis[index + 1] + value) % prime
            basis = next_basis
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    return result


def modular_profile(profile: dict[str, Any], prime: int) -> dict[str, Any]:
    return {
        **{field: profile[field] for field in (
            "key", "numerator_degree", "denominator_degree", "total_degree"
        )},
        "numerator": [reduce_fraction(value, prime) for value in profile["numerator"]],
        "denominator": [reduce_fraction(value, prime) for value in profile["denominator"]],
    }


def grouped_epsilon_profiles(
    profiles: dict[tuple[Any, ...], dict[str, Any]],
) -> dict[tuple[str, str, int], dict[str, list[dict[str, Any]]]]:
    grouped: dict[
        tuple[str, str, int], dict[str, dict[int, dict[str, Any]]]
    ] = defaultdict(lambda: {"numerator": {}, "denominator": {}})
    for key, profile in profiles.items():
        if (
            key[0] != "epsilon_profile"
            or key[1] not in RATIONAL_CHANNELS
            or key[2] not in NUMERATOR_FIELDS
        ):
            continue
        grouped[(key[1], key[2], int(key[3]))][key[4]][int(key[5])] = profile
    packed = {}
    for coordinate, parts in grouped.items():
        packed[coordinate] = {}
        for part in ("numerator", "denominator"):
            values = parts[part]
            if set(values) != set(range(len(values))):
                raise RuntimeError(f"noncontiguous epsilon profile {coordinate}:{part}")
            packed[coordinate][part] = [values[index] for index in range(len(values))]
    return packed


def initialize_worker(
    prime: int, grouped: dict, construction_p: list[Fraction],
    heldout_p: list[Fraction], orders: tuple[int, ...],
) -> None:
    rational = load_module(f"cf303_laurent_rational_{os.getpid()}", RATIONAL)
    rational.PRIME = prime
    _WORKER.update({
        "prime": prime,
        "grouped": grouped,
        "construction_p": construction_p,
        "heldout_p": heldout_p,
        "orders": orders,
        "rational": rational,
    })


def build_coordinate(coordinate: tuple[str, str, int]) -> list[dict[str, Any]]:
    prime = _WORKER["prime"]
    parts = _WORKER["grouped"][coordinate]
    construction_p = _WORKER["construction_p"]
    heldout_p = _WORKER["heldout_p"]
    orders = _WORKER["orders"]

    def at_p(point: Fraction) -> list[int]:
        p_value = reduce_fraction(point, prime)
        numerator = [profile_value(profile, p_value, prime)
                     for profile in parts["numerator"]]
        denominator = [profile_value(profile, p_value, prime)
                       for profile in parts["denominator"]]
        return [laurent_coefficient(numerator, denominator, order, prime)
                for order in orders]

    construction_values = [at_p(point) for point in construction_p]
    heldout_values = [at_p(point) for point in heldout_p]
    train_x = [reduce_fraction(point, prime) for point in construction_p]
    heldout_x = [reduce_fraction(point, prime) for point in heldout_p]
    output = []
    for position, order in enumerate(orders):
        profile = _WORKER["rational"].reconstruct(
            train_x,
            [values[position] for values in construction_values],
            heldout_x,
            [values[position] for values in heldout_values],
        )
        if profile["status"] == "Zero":
            profile = {
                "status": "ReconstructedModPrime", "numerator": [0],
                "denominator": [1], "numerator_degree": -1,
                "denominator_degree": 0, "total_degree": 0,
            }
        if profile["status"] != "ReconstructedModPrime":
            raise RuntimeError(f"Laurent p reconstruction failed at {coordinate}:{order}")
        output.append({
            "key": ["laurent_profile", *coordinate, order],
            **{field: profile[field] for field in (
                "numerator", "denominator", "numerator_degree",
                "denominator_degree", "total_degree",
            )},
        })
    return output


def build_modular_deck(
    *, prime: int, profile_map: dict, construction_p: list[Fraction],
    heldout_p: list[Fraction], orders: tuple[int, ...], workers: int,
    coordinate_limit: int | None,
) -> dict[str, Any]:
    grouped = grouped_epsilon_profiles(profile_map)
    coordinates = sorted(grouped)
    if coordinate_limit is not None:
        coordinates = coordinates[:coordinate_limit]
    started = time.perf_counter()
    with concurrent.futures.ProcessPoolExecutor(
        max_workers=workers, initializer=initialize_worker,
        initargs=(prime, grouped, construction_p, heldout_p, orders),
    ) as executor:
        nested = list(executor.map(build_coordinate, coordinates))
    profiles = [profile for group in nested for profile in group]
    return {
        "status": MODULAR_STATUS,
        "block": [25, 1], "prime": prime,
        "requested_orders": list(orders),
        "construction_p": encode_fractions(construction_p),
        "heldout_p": encode_fractions(heldout_p),
        "coordinate_count": len(coordinates),
        "profile_count": len(profiles),
        "profiles": profiles,
        "wall_seconds": time.perf_counter() - started,
    }


def profile_layout(profile: dict[str, Any]) -> tuple[Any, ...]:
    return (
        tuple(profile["key"]), profile["numerator_degree"],
        profile["denominator_degree"], profile["total_degree"],
        len(profile["numerator"]), len(profile["denominator"]),
    )


def exact_lift(decks: list[dict[str, Any]], lift, analysis):
    layouts = [[profile_layout(profile) for profile in deck["profiles"]]
               for deck in decks]
    if any(layout != layouts[0] for layout in layouts[1:]):
        raise RuntimeError("Laurent deck layout changed across primes")
    lift_decks, oracle_deck = decks[:-1], decks[-1]
    primes = [deck["prime"] for deck in lift_decks]
    oracle_prime = oracle_deck["prime"]
    modulus, weights = lift.crt_weights(primes)
    output = []
    unresolved = []
    maximum_numerator_bits = 0
    maximum_denominator_bits = 0
    coefficient_count = 0
    source_counts = Counter()
    scale_bits = Counter()
    scale_closed_profiles = 0
    for profile_index, reference in enumerate(lift_decks[0]["profiles"]):
        exact = {field: reference[field] for field in (
            "key", "numerator_degree", "denominator_degree", "total_degree"
        )}
        residues_by_field = {}
        oracle_by_field = {}
        matches_by_field = {}
        for field in ("numerator", "denominator"):
            residues = []
            oracle_values = []
            values: list[Fraction | None] = []
            for coefficient_index in range(len(reference[field])):
                modular = [deck["profiles"][profile_index][field][coefficient_index]
                           for deck in lift_decks]
                residue = sum(value * weight for value, weight in zip(
                    modular, weights, strict=True)) % modulus
                oracle_value = oracle_deck["profiles"][profile_index][field][
                    coefficient_index]
                value, match_count = analysis.oracle_eea_reconstruct(
                    residue, modulus, oracle_value, oracle_prime
                )
                coefficient_count += 1
                values.append(value)
                residues.append(residue)
                oracle_values.append(oracle_value)
                if value is not None:
                    source_counts["EEAWithQ6Oracle"] += 1
            residues_by_field[field] = residues
            oracle_by_field[field] = oracle_values
            matches_by_field[field] = values

        common_scale = 1
        denominator_complete = all(
            value is not None for value in matches_by_field["denominator"]
        )
        if denominator_complete:
            for value in matches_by_field["denominator"]:
                common_scale = math.lcm(common_scale, value.denominator)
            for value in matches_by_field["numerator"]:
                if value is not None:
                    common_scale = math.lcm(common_scale, value.denominator)
            scale_bits[common_scale.bit_length()] += 1
            rescued = 0
            for index, value in enumerate(matches_by_field["numerator"]):
                if value is not None:
                    continue
                integer = balanced(
                    residues_by_field["numerator"][index]
                    * (common_scale % modulus), modulus,
                )
                candidate = Fraction(integer, common_scale)
                if (
                    reduce_fraction(candidate, oracle_prime)
                    == oracle_by_field["numerator"][index]
                ):
                    matches_by_field["numerator"][index] = candidate
                    source_counts["PostLaurentSharedScaleWithQ6Replay"] += 1
                    rescued += 1
            if rescued and all(
                value is not None for value in matches_by_field["numerator"]
            ):
                scale_closed_profiles += 1

        for field in ("numerator", "denominator"):
            values = matches_by_field[field]
            for index, value in enumerate(values):
                if value is None:
                    unresolved.append({
                        "key": reference["key"], "field": field,
                        "index": index, "matches": 0,
                    })
                    continue
                maximum_numerator_bits = max(
                    maximum_numerator_bits, abs(value.numerator).bit_length()
                )
                maximum_denominator_bits = max(
                    maximum_denominator_bits, value.denominator.bit_length()
                )
            exact[field] = [value for value in values if value is not None]
        if (
            len(exact["numerator"]) == len(reference["numerator"])
            and len(exact["denominator"]) == len(reference["denominator"])
        ):
            output.append(exact)
    return output, {
        "lift_primes": primes, "oracle_prime": oracle_prime,
        "modulus_bits": modulus.bit_length(),
        "coefficient_count": coefficient_count,
        "resolved_count": coefficient_count - len(unresolved),
        "unresolved_count": len(unresolved),
        "unresolved_sample": unresolved[:32],
        "maximum_numerator_bits": maximum_numerator_bits,
        "maximum_denominator_bits": maximum_denominator_bits,
        "coefficient_sources": dict(source_counts),
        "shared_scale_closed_profiles": scale_closed_profiles,
        "shared_scale_bits": {
            str(bits): count for bits, count in sorted(scale_bits.items())
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--q1", type=Path, default=DEFAULT_Q1)
    parser.add_argument("--q2", type=Path, default=DEFAULT_Q2)
    parser.add_argument("--targeted", nargs=4, type=Path, default=DEFAULT_TARGETED)
    parser.add_argument("--p-census", type=Path, default=DEFAULT_CENSUS)
    parser.add_argument("--workers", type=int, choices=range(1, 9), default=8)
    parser.add_argument("--coordinate-limit", type=int)
    parser.add_argument("--modular-only", action="store_true")
    parser.add_argument("--validation-prime", type=int,
                        default=2_305_843_009_213_693_693)
    parser.add_argument("--validation-workers", type=int, default=3)
    parser.add_argument("--threads-per-validation", type=int, default=4)
    parser.add_argument("--output", type=Path,
                        default=OUT / "cf303_block1_exact_laurent_deck.json")
    parser.add_argument("--report", type=Path,
                        default=OUT / "cf303_block1_exact_laurent_deck_report.json")
    args = parser.parse_args()
    if args.coordinate_limit is not None and args.coordinate_limit < 1:
        raise ValueError("coordinate limit must be positive")
    if (
        args.validation_workers < 1
        or args.validation_workers * args.threads_per_validation > 12
    ):
        raise ValueError("validation allocation exceeds twelve cores")

    lift = load_module("cf303_deck_lift", EXACT_LIFT)
    analysis = load_module("cf303_deck_analysis", ANALYSIS)
    candidate = load_module("cf303_deck_candidate", CANDIDATE)
    q1 = lift.load_image(args.q1)
    q2 = lift.load_image(args.q2)
    lift.require_common_layout([q1, q2])
    targeted_records = [json.loads(path.read_text()) for path in args.targeted]
    if any(record.get("status") != "CF303NestedTargetedNumeratorQImageAcceptedV1"
           for record in targeted_records):
        raise RuntimeError("targeted q artifact is not accepted")
    all_primes = [q1["prime"], q2["prime"],
                  *(record["prime"] for record in targeted_records)]
    if len(set(all_primes)) != 6:
        raise RuntimeError("six independent primes are required")

    candidates, candidate_statistics = candidate.build_candidates(
        q1, q2, lift, analysis
    )
    shared_profiles = {
        tuple(profile["key"]): profile
        for profile in candidates["shared_scale"]
    }
    raw_maps = [
        {tuple(profile["key"]): profile
         for profile in record["nested_lifted_coordinates"]}
        for record in (q1, q2)
    ]
    for record in targeted_records:
        prime = record["prime"]
        profile_map = {
            key: modular_profile(profile, prime)
            for key, profile in shared_profiles.items()
        }
        profile_map.update({
            tuple(profile["key"]): profile
            for profile in record["targeted_profiles"]
        })
        raw_maps.append(profile_map)

    census = json.loads(args.p_census.read_text())
    construction_p = [Fraction(*value) for value in census["construction_p"]]
    heldout_p = [Fraction(*value) for value in census["heldout_p"]]
    deck_directory = args.output.parent / "block1_modular_laurent_decks"
    deck_directory.mkdir(parents=True, exist_ok=True)
    decks = []
    for prime, profile_map in zip(all_primes, raw_maps, strict=True):
        path = deck_directory / f"cf303_block1_laurent_deck_q{prime}.json"
        cached = None
        if path.exists():
            candidate_record = json.loads(path.read_text())
            if (
                candidate_record.get("status") == MODULAR_STATUS
                and candidate_record.get("prime") == prime
                and candidate_record.get("requested_orders") == list(DEFAULT_ORDERS)
                and candidate_record.get("coordinate_count")
                    == (args.coordinate_limit or 126)
            ):
                cached = candidate_record
        if cached is None:
            cached = build_modular_deck(
                prime=prime, profile_map=profile_map,
                construction_p=construction_p, heldout_p=heldout_p,
                orders=DEFAULT_ORDERS, workers=args.workers,
                coordinate_limit=args.coordinate_limit,
            )
            atomic_json(path, cached)
        decks.append(cached)
        print(
            f"DECK q={prime} profiles={cached['profile_count']} "
            f"wall={cached['wall_seconds']:.3f}", flush=True
        )
    if args.modular_only:
        return 0

    exact_profiles, lift_report = exact_lift(decks, lift, analysis)
    if lift_report["unresolved_count"]:
        report = {
            "status": "CF303Block1ExactLaurentDeckIncompleteV1",
            "block": [25, 1], "requested_orders": list(DEFAULT_ORDERS),
            "lift": lift_report, "candidate_statistics": candidate_statistics,
        }
        atomic_json(args.report, report)
        print(json.dumps(report, indent=2))
        return 4

    exact_by_key = {tuple(profile["key"]): profile for profile in exact_profiles}
    exact_coordinates = sorted({key[1:4] for key in exact_by_key})
    support_grouped = grouped_epsilon_profiles(shared_profiles)
    validation_directory = args.report.parent / (
        f"block1_laurent_q7_validation/q{args.validation_prime}"
    )
    validation_directory.mkdir(parents=True, exist_ok=True)

    def scalar_task(payload):
        point, epsilon = payload
        record, wall = candidate.scalar_image(
            prime=args.validation_prime, p_value=point, epsilon=epsilon,
            threads=args.threads_per_validation, directory=validation_directory,
        )
        return point, epsilon, record, wall

    payloads = [(point, epsilon) for point in VALIDATION_POINTS
                for epsilon in VALIDATION_EPSILONS]
    with concurrent.futures.ThreadPoolExecutor(
        max_workers=args.validation_workers
    ) as executor:
        scalar_records = list(executor.map(scalar_task, payloads))
    records_by_point = defaultdict(dict)
    scalar_wall_sum = 0.0
    for point, epsilon, record, wall in scalar_records:
        records_by_point[point][epsilon] = record
        scalar_wall_sum += wall

    mismatches = Counter()
    mismatch_sample = []
    comparisons = 0
    for point in VALIDATION_POINTS:
        p_mod = reduce_fraction(point, args.validation_prime)
        for coordinate in exact_coordinates:
            parts = support_grouped[coordinate]
            denominator = [
                profile_value(profile, p_mod, args.validation_prime)
                for profile in parts["denominator"]
            ]
            reduced_values = [
                records_by_point[point][epsilon]["channels"][coordinate[0]][
                    "reduction"][coordinate[1]][coordinate[2]]
                for epsilon in VALIDATION_EPSILONS
            ]
            numerator_values = [
                reduced * polynomial_value(
                    denominator, epsilon, args.validation_prime
                ) % args.validation_prime
                for reduced, epsilon in zip(
                    reduced_values, VALIDATION_EPSILONS, strict=True
                )
            ]
            numerator = interpolate(
                list(VALIDATION_EPSILONS), numerator_values,
                args.validation_prime,
            )
            for order in DEFAULT_ORDERS:
                key = ("laurent_profile", *coordinate, order)
                predicted = profile_value(
                    exact_by_key[key], p_mod, args.validation_prime
                )
                observed = laurent_coefficient(
                    numerator, denominator, order, args.validation_prime
                )
                comparisons += 1
                if predicted != observed:
                    mismatches[(coordinate[0], coordinate[1], order)] += 1
                    if len(mismatch_sample) < 32:
                        mismatch_sample.append([
                            list(point.as_integer_ratio()), *coordinate,
                            order, predicted, observed,
                        ])
    mismatch_count = sum(mismatches.values())
    status = EXACT_STATUS if mismatch_count == 0 else (
        "CF303Block1ExactLaurentDeckRejectedV1"
    )
    report = {
        "status": status, "block": [25, 1],
        "requested_orders": list(DEFAULT_ORDERS),
        "lift": lift_report,
        "validation_prime": args.validation_prime,
        "validation_points": [encode_fractions(point)
                              for point in VALIDATION_POINTS],
        "validation_epsilon_values": list(VALIDATION_EPSILONS),
        "validation_comparisons": comparisons,
        "validation_mismatch_count": mismatch_count,
        "mismatches": {
            f"{channel}:{field}:eps^{order}": count
            for (channel, field, order), count in sorted(mismatches.items())
        },
        "mismatch_sample": mismatch_sample,
        "scalar_wall_sum": scalar_wall_sum,
        "candidate_statistics": candidate_statistics,
        "claim": (
            "All block-1 rational Laurent coefficients eps^-3..eps^4 "
            "replay at three fresh p points through raw q7 scalar/Hermite "
            "images; cancellation preceded exact lifting."
            if mismatch_count == 0 else
            "The exact Laurent deck failed fresh-q7 scalar/Hermite replay."
        ),
    }
    atomic_json(args.report, report)
    if mismatch_count:
        print(json.dumps(report, indent=2))
        return 5
    output = {
        "status": EXACT_STATUS, "block": [25, 1],
        "coefficient_encoding": "[numerator, denominator]",
        "requested_orders": list(DEFAULT_ORDERS),
        "lift": lift_report,
        "validation_prime": args.validation_prime,
        "validation_points": [encode_fractions(point)
                              for point in VALIDATION_POINTS],
        "profiles": exact_profiles,
    }
    atomic_json(args.output, encode_fractions(output))
    print(json.dumps({
        "status": status, "profiles": len(exact_profiles),
        "lift": lift_report,
        "validation_comparisons": comparisons,
        "validation_mismatch_count": mismatch_count,
        "output": str(args.output), "report": str(args.report),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
