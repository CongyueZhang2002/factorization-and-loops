#!/usr/bin/env python3
"""Compare one targeted q3 p fibre with nine full scalar reductions."""

from __future__ import annotations

import importlib.util
import json
from collections import defaultdict
from fractions import Fraction
from pathlib import Path


HERE = Path(__file__).resolve().parent
TARGETED_PATH = HERE / "cf303_nested_targeted_q3.py"
PRIME = 2_305_843_009_213_592_059
FULL_DIRECTORY = Path(
    "/tmp/cf303_adaptive_benchmark/block1_fixed_p_epsilon_images"
)
TARGETED_RECORD = Path(
    "/home/maxzhang/factorization-and-loops-codex/"
    "Runtime/2026-08-31_cf303_native_dlog_residues/"
    f"block1_targeted_q3/q{PRIME}/q{PRIME}_p3d1.json"
)
SUPPORT_ARTIFACT = Path(
    "/home/maxzhang/factorization-and-loops-codex/"
    "Runtime/2026-08-31_cf303_native_dlog_residues/"
    "cf303_block1_exact_denominator_support_smoke.json"
)


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


targeted = load_module("cf303_targeted_q3_test", TARGETED_PATH)
candidate = targeted.load_module(
    "cf303_targeted_q3_candidate_test", targeted.CANDIDATE_SCRIPT
)
support_record = targeted.decode_fractions(
    json.loads(SUPPORT_ARTIFACT.read_text())
)
support = support_record["support_profiles"]
p_value = Fraction(3)
epsilon_denominators = defaultdict(dict)
for profile in support:
    key = profile["key"]
    if key[0] != "epsilon_profile":
        continue
    value = targeted.exact_profile_value(
        profile, p_value, PRIME, candidate
    )
    _, channel, field, index, part, epsilon_index = key
    assert part == "denominator"
    epsilon_denominators[(channel, field, int(index))][
        int(epsilon_index)
    ] = value

targeted_record = json.loads(TARGETED_RECORD.read_text())
epsilon_numerators = defaultdict(dict)
for item in targeted_record["target_values"]:
    _, channel, field, index, part, epsilon_index = item["key"]
    assert part == "numerator"
    epsilon_numerators[(channel, field, int(index))][
        int(epsilon_index)
    ] = int(item["value"])

comparisons = 0
mismatches = []
for epsilon in range(7, 16):
    full_path = FULL_DIRECTORY / (
        f"block1_q{PRIME}_p3d1_e{epsilon}.json"
    )
    full = json.loads(full_path.read_text())
    for key, numerator_map in epsilon_numerators.items():
        channel, field, index = key
        denominator_map = epsilon_denominators[key]
        numerator = targeted.polynomial_value(
            [numerator_map[i] for i in range(len(numerator_map))],
            epsilon, PRIME,
        )
        denominator = targeted.polynomial_value(
            [denominator_map[i] for i in range(len(denominator_map))],
            epsilon, PRIME,
        )
        observed = numerator * targeted.inverse(denominator, PRIME) % PRIME
        expected = full["channels"][channel]["reduction"][field][index]
        comparisons += 1
        if observed != expected:
            mismatches.append([
                epsilon, channel, field, index, observed, expected
            ])

assert comparisons == 9 * 126
assert not mismatches, mismatches[:16]
print(
    "CF303_TARGETED_Q3_FULL_SCALAR_MATCH "
    f"comparisons={comparisons} mismatches={len(mismatches)}"
)
