#!/usr/bin/env python3
"""Focused synthetic contract tests for cf303_nested_exact_lift.py."""

from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from fractions import Fraction
from pathlib import Path


SCRIPT = Path(__file__).with_name("cf303_nested_exact_lift.py")
SPEC = importlib.util.spec_from_file_location("cf303_nested_exact_lift", SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot import {SCRIPT}")
LIFT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LIFT)

PRIMES = (
    2_305_843_009_213_693_951,
    2_305_843_009_213_693_921,
    2_305_843_009_213_693_907,
)
EXACT = (
    {
        "key": ["u_denominator", "rational", "q", 0],
        "numerator": [Fraction(3, 7), Fraction(-5, 11)],
        "denominator": [Fraction(2, 13), Fraction(1)],
        "numerator_degree": 1,
        "denominator_degree": 1,
        "total_degree": 2,
    },
    {
        "key": ["epsilon_profile", "elliptic", "numerator", 3],
        "numerator": [Fraction(17, 19)],
        "denominator": [Fraction(1)],
        "numerator_degree": 0,
        "denominator_degree": 0,
        "total_degree": 0,
    },
    {
        "key": ["epsilon_profile", "rational", "numerator", 9],
        "numerator": [Fraction(0)],
        "denominator": [Fraction(1)],
        "numerator_degree": -1,
        "denominator_degree": 0,
        "total_degree": 0,
    },
)


def modular(value: Fraction, prime: int) -> int:
    return (
        value.numerator % prime
        * pow(value.denominator % prime, prime - 2, prime)
    ) % prime


def make_record(prime: int) -> dict:
    profiles = []
    for exact in EXACT:
        profile = {
            key: exact[key]
            for key in (
                "key", "numerator_degree", "denominator_degree", "total_degree"
            )
        }
        profile["numerator"] = [
            modular(value, prime) for value in exact["numerator"]
        ]
        profile["denominator"] = [
            modular(value, prime) for value in exact["denominator"]
        ]
        profiles.append(profile)
    return {
        "status": LIFT.IMAGE_STATUS,
        "block": [25, 1],
        "prime": prime,
        "construction_p": [[7, 1], [11, 1]],
        "heldout_p": [[101, 1]],
        "epsilon_values": [7, 8, 9],
        "epsilon_heldout": 1,
        "u_train": 5,
        "u_heldout": 1,
        "coordinate_count": len(profiles),
        "nested_lifted_coordinates": profiles,
        "lift_backend": {"name": "ignored execution detail"},
        "timings": {"campaign_wall": prime % 17},
    }


class NestedExactLiftTests(unittest.TestCase):
    def load_records(self) -> list[dict]:
        records = []
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for ordinal, prime in enumerate(PRIMES):
                path = root / f"q{prime}.json"
                path.write_text(json.dumps(make_record(prime)) + "\n")
                records.append(LIFT.load_image(path))
        return records

    def test_lifts_all_arrays_and_validates_disjoint_prime(self) -> None:
        records = self.load_records()
        LIFT.require_common_layout(records)
        lifted, statistics = LIFT.lift_records(records[:2])
        self.assertEqual(statistics["coefficient_count"], 8)
        self.assertEqual(statistics["unresolved_coefficient_count"], 0)
        validation = LIFT.validate_candidate(lifted, records[2])
        self.assertEqual(validation["validation_comparisons"], 8)
        self.assertEqual(validation["validation_mismatch_count"], 0)
        for expected, observed in zip(
            EXACT, lifted["nested_lifted_coordinates"], strict=True
        ):
            self.assertEqual(observed["numerator"], expected["numerator"])
            self.assertEqual(observed["denominator"], expected["denominator"])

    def test_validation_detects_wrong_coefficient(self) -> None:
        records = self.load_records()
        lifted, statistics = LIFT.lift_records(records[:2])
        self.assertEqual(statistics["unresolved_coefficient_count"], 0)
        records[2]["nested_lifted_coordinates"][0]["numerator"][0] += 1
        validation = LIFT.validate_candidate(lifted, records[2])
        self.assertEqual(validation["validation_mismatch_count"], 1)

    def test_rejects_profile_reordering(self) -> None:
        records = self.load_records()
        records[2]["nested_lifted_coordinates"].reverse()
        with self.assertRaisesRegex(RuntimeError, "key/profile layout"):
            LIFT.require_common_layout(records)


if __name__ == "__main__":
    unittest.main()
