#!/usr/bin/env python3
"""Measure early rational reconstruction on accepted nested-q artifacts.

This is a read-only diagnostic.  It compares Wang's symmetric-bound
reconstruction with Monagan's maximal-quotient heuristic.  When a following
accepted q image is supplied, every proposed coefficient is replayed there.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
import time
from collections import Counter
from fractions import Fraction
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
EXACT_LIFT = HERE / "cf303_nested_exact_lift.py"


def load_exact_lift():
    specification = importlib.util.spec_from_file_location(
        "cf303_nested_exact_lift_analysis", EXACT_LIFT
    )
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot import {EXACT_LIFT}")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


def maximal_quotient_reconstruct(
    residue: int, modulus: int, threshold: int
) -> tuple[Fraction | None, int]:
    """Monagan MQRR, returning its candidate and selected quotient."""
    residue %= modulus
    if residue == 0:
        return (Fraction(0), modulus) if modulus > threshold else (None, 0)
    numerator = denominator = 0
    r0, r1 = modulus, residue
    t0, t1 = 0, 1
    selected = threshold
    while r1 and r0 > selected:
        quotient = r0 // r1
        if quotient > selected:
            numerator, denominator, selected = r1, t1, quotient
        r0, r1 = r1, r0 - quotient * r1
        t0, t1 = t1, t0 - quotient * t1
    if denominator == 0 or math.gcd(numerator, denominator) != 1:
        return None, selected
    if denominator < 0:
        numerator, denominator = -numerator, -denominator
    candidate = Fraction(numerator, denominator)
    if (
        threshold * abs(candidate.numerator) * candidate.denominator >= modulus
        or (
            candidate.numerator
            - residue * candidate.denominator
        ) % modulus
    ):
        return None, selected
    return candidate, selected


def oracle_eea_reconstruct(
    residue: int, modulus: int, oracle_residue: int, oracle_prime: int
) -> tuple[Fraction | None, int]:
    """Select EEA convergents by exact congruence at a disjoint prime."""
    residue %= modulus
    if residue == 0:
        return (
            (Fraction(0), 1) if oracle_residue % oracle_prime == 0
            else (None, 0)
        )
    matches: set[Fraction] = set()
    r0, r1 = modulus, residue
    t0, t1 = 0, 1
    while r1:
        numerator, denominator = r1, t1
        if denominator < 0:
            numerator, denominator = -numerator, -denominator
        denominator_mod = denominator % oracle_prime
        if (
            denominator_mod
            and numerator % oracle_prime
                == oracle_residue * denominator_mod % oracle_prime
        ):
            matches.add(Fraction(numerator, denominator))
        quotient = r0 // r1
        r0, r1 = r1, r0 - quotient * r1
        t0, t1 = t1, t0 - quotient * t1
    return (
        (next(iter(matches)), 1) if len(matches) == 1
        else (None, len(matches))
    )


def flatten(record: dict[str, Any]) -> list[tuple[tuple[Any, ...], int]]:
    output = []
    for profile in record["nested_lifted_coordinates"]:
        for field in ("numerator", "denominator"):
            for index, value in enumerate(profile[field]):
                output.append((tuple(profile["key"]) + (field, index), value))
    return output


def reduce_fraction(value: Fraction, prime: int) -> int | None:
    denominator = value.denominator % prime
    if denominator == 0:
        return None
    return value.numerator % prime * pow(denominator, prime - 2, prime) % prime


def summarize(
    *, label: str, residues: list[int], modulus: int, candidates: list[Fraction | None],
    selected_quotients: list[int] | None, multiplicities: Counter[int],
    validation_residues: list[int] | None, validation_prime: int | None,
) -> dict[str, Any]:
    proposed = [value is not None for value in candidates]
    proposal_instances = sum(
        multiplicities[residue]
        for residue, present in zip(residues, proposed, strict=True) if present
    )
    result = {
        "method": label,
        "modulus_bits": modulus.bit_length(),
        "unique_residue_count": len(residues),
        "proposed_unique_count": sum(proposed),
        "proposed_instance_count": proposal_instances,
        "maximum_numerator_bits": max(
            (abs(value.numerator).bit_length()
             for value in candidates if value is not None),
            default=0,
        ),
        "maximum_denominator_bits": max(
            (value.denominator.bit_length()
             for value in candidates if value is not None),
            default=0,
        ),
    }
    if selected_quotients is not None:
        result["selected_quotient_bits"] = {
            "minimum": min(
                (quotient.bit_length() for quotient, present
                 in zip(selected_quotients, proposed, strict=True) if present),
                default=0,
            ),
            "maximum": max(
                (quotient.bit_length() for quotient, present
                 in zip(selected_quotients, proposed, strict=True) if present),
                default=0,
            ),
        }
    if validation_residues is not None and validation_prime is not None:
        matched_unique = 0
        matched_instances = 0
        mismatch_unique = 0
        for residue, candidate, expected in zip(
            residues, candidates, validation_residues, strict=True
        ):
            if candidate is None:
                continue
            if reduce_fraction(candidate, validation_prime) == expected:
                matched_unique += 1
                matched_instances += multiplicities[residue]
            else:
                mismatch_unique += 1
        result.update({
            "validation_prime": validation_prime,
            "matched_unique_count": matched_unique,
            "matched_instance_count": matched_instances,
            "mismatch_unique_count": mismatch_unique,
        })
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("images", nargs="+", type=Path)
    parser.add_argument(
        "--threshold-bits", default="8,12,16,20,24,30",
        help="comma-separated initial MQRR threshold exponents",
    )
    parser.add_argument(
        "--all-lift", action="store_true",
        help="use every supplied image in the CRT modulus (no validation image)",
    )
    args = parser.parse_args()
    lift = load_exact_lift()
    records = [lift.load_image(path) for path in args.images]
    lift.require_common_layout(records)
    flattened = [flatten(record) for record in records]
    keys = [key for key, _ in flattened[0]]
    if any([key for key, _ in image] != keys for image in flattened[1:]):
        raise RuntimeError("flattened coefficient order changed")

    lift_records = (
        records if args.all_lift or len(records) == 1 else records[:-1]
    )
    validation = (
        None if args.all_lift or len(records) == 1 else records[-1]
    )
    primes = [int(record["prime"]) for record in lift_records]
    modulus, weights = lift.crt_weights(primes)
    instance_residues = [
        sum(
            flattened[image][index][1] * weight
            for image, weight in enumerate(weights)
        ) % modulus
        for index in range(len(keys))
    ]
    multiplicities = Counter(instance_residues)
    residues = list(multiplicities)
    first_position = {}
    for index, residue in enumerate(instance_residues):
        first_position.setdefault(residue, index)
    validation_residues = (
        [flattened[-1][first_position[residue]][1] for residue in residues]
        if validation is not None else None
    )
    validation_prime = int(validation["prime"]) if validation else None

    started = time.perf_counter()
    strict = [lift.rational_reconstruct(value, modulus) for value in residues]
    reports = [summarize(
        label="WangSymmetricBound",
        residues=residues,
        modulus=modulus,
        candidates=strict,
        selected_quotients=None,
        multiplicities=multiplicities,
        validation_residues=validation_residues,
        validation_prime=validation_prime,
    )]
    if (
        len(lift_records) == 1
        and validation_residues is not None
        and validation_prime is not None
    ):
        oracle_candidates = []
        ambiguous = 0
        for residue, oracle_residue in zip(
            residues, validation_residues, strict=True
        ):
            candidate, match_count = oracle_eea_reconstruct(
                residue, modulus, oracle_residue, validation_prime
            )
            oracle_candidates.append(candidate)
            if match_count > 1:
                ambiguous += 1
        oracle_report = summarize(
            label="AllEEAConvergentsWithDisjointPrimeOracle",
            residues=residues,
            modulus=modulus,
            candidates=oracle_candidates,
            selected_quotients=None,
            multiplicities=multiplicities,
            validation_residues=validation_residues,
            validation_prime=validation_prime,
        )
        oracle_report["ambiguous_unique_residue_count"] = ambiguous
        reports.append(oracle_report)
    for bits in [
        int(value) for value in args.threshold_bits.split(",") if value
    ]:
        candidates = []
        quotients = []
        for residue in residues:
            candidate, quotient = maximal_quotient_reconstruct(
                residue, modulus, 1 << bits
            )
            candidates.append(candidate)
            quotients.append(quotient)
        mqrr_report = summarize(
            label=f"MonaganMQRRThreshold2^{bits}",
            residues=residues,
            modulus=modulus,
            candidates=candidates,
            selected_quotients=quotients,
            multiplicities=multiplicities,
            validation_residues=validation_residues,
            validation_prime=validation_prime,
        )
        mqrr_report.update({
            "new_beyond_wang_instance_count": sum(
                multiplicities[residue]
                for residue, wang, mqrr in zip(
                    residues, strict, candidates, strict=True
                ) if wang is None and mqrr is not None
            ),
            "disagrees_with_wang_instance_count": sum(
                multiplicities[residue]
                for residue, wang, mqrr in zip(
                    residues, strict, candidates, strict=True
                ) if wang is not None and mqrr is not None and wang != mqrr
            ),
        })
        reports.append(mqrr_report)
    output = {
        "status": "CF303NestedQReconstructionAnalysisV1",
        "lift_primes": primes,
        "validation_prime": validation_prime,
        "coefficient_instances": len(keys),
        "unique_crt_residues": len(residues),
        "elapsed_seconds": time.perf_counter() - started,
        "reports": reports,
    }
    print(json.dumps(output, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
