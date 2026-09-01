#!/usr/bin/env python3
"""Scratch-only modular finite path gauge for CF303 source block 1.

At fixed (q,p), the cached Laurent decks provide the accepted primitive and
remainder of delta B_n.  Exact rational D and S11 are specialized from the
small exported input.  The recurrence

    delta K_n = delta B_n + D delta H_(n-1)
                - delta H_(n-1) S11 - d delta H_n

is then performed over F_q(u), with every new cross form Hermite-reduced and
H_n normalized to vanish at u=1/2.  No characteristic-zero expanded p
profile is constructed here.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import time
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Any

import sympy


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
OUT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
INPUT = OUT / "cf303_block1_finite_gauge_inputs.json"
DECK_DIR = OUT / "block1_modular_laurent_decks"
Q1 = OUT / "cf303_block1_nested_p_epsilon_q2305843009213691819.json"
Q2 = OUT / "cf303_block1_nested_p_epsilon_q2305843009213641971.json"
EXACT_LIFT = ROOT / "Diagnostics/Scripts/cf303_nested_exact_lift.py"
ANALYSIS = ROOT / "Diagnostics/Scripts/analyze_cf303_nested_q_reconstruction.py"
CANDIDATE = ROOT / "Diagnostics/Scripts/cf303_nested_candidate_point_validation.py"
HELPER = ROOT / "Diagnostics/Scripts/cf303_modular_hermite_pilot.py"
CHANNELS = ("1,1,rational", "2,1,rational")
ORDERS = tuple(range(-3, 5))


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


@dataclass(frozen=True)
class RationalFunction:
    numerator: tuple[int, ...]
    denominator: tuple[int, ...]
    prime: int

    @classmethod
    def make(cls, numerator, denominator, prime, helper):
        numerator = helper.trim(numerator, prime)
        denominator = helper.trim(denominator, prime)
        if denominator == [0]:
            raise ZeroDivisionError("zero rational-function denominator")
        if numerator == [0]:
            return cls((0,), (1,), prime)
        common = helper.gcd_poly(numerator, denominator, prime)
        numerator = helper.exact_div(numerator, common, prime)
        denominator = helper.exact_div(denominator, common, prime)
        inverse = pow(denominator[-1], prime - 2, prime)
        numerator = helper.scale(numerator, inverse, prime)
        denominator = helper.scale(denominator, inverse, prime)
        return cls(tuple(numerator), tuple(denominator), prime)

    @classmethod
    def zero(cls, prime):
        return cls((0,), (1,), prime)

    @classmethod
    def constant(cls, value, prime):
        return cls((value % prime,), (1,), prime)

    def add(self, other, helper, sign=1):
        if self.prime != other.prime:
            raise ValueError("mixed-prime rational operation")
        numerator = helper.add(
            helper.multiply(self.numerator, other.denominator, self.prime),
            helper.multiply(other.numerator, self.denominator, self.prime),
            self.prime, sign,
        )
        denominator = helper.multiply(
            self.denominator, other.denominator, self.prime
        )
        return RationalFunction.make(
            numerator, denominator, self.prime, helper
        )

    def multiply(self, other, helper):
        if self.prime != other.prime:
            raise ValueError("mixed-prime rational operation")
        return RationalFunction.make(
            helper.multiply(self.numerator, other.numerator, self.prime),
            helper.multiply(self.denominator, other.denominator, self.prime),
            self.prime, helper,
        )

    def evaluate(self, point):
        numerator = polynomial_value(self.numerator, point, self.prime)
        denominator = polynomial_value(self.denominator, point, self.prime)
        if denominator == 0:
            raise ZeroDivisionError("rational-function evaluation pole")
        return numerator * pow(denominator, self.prime - 2, self.prime) % self.prime

    @property
    def zero_q(self):
        return self.numerator == (0,)


def polynomial_value(coefficients, value, prime):
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * value + coefficient) % prime
    return result


def exact_fraction_mod(value: Fraction, prime: int) -> int:
    return value.numerator % prime * pow(value.denominator % prime, prime - 2, prime) % prime


def parse_polynomial(text: str) -> list[int]:
    variable = sympy.symbols("p")
    expression = sympy.sympify(text.replace("^", "**"), locals={"p": variable})
    polynomial = sympy.Poly(expression, variable, domain=sympy.QQ)
    if any(value.q != 1 for value in polynomial.all_coeffs()):
        raise RuntimeError(f"nonintegral exported p polynomial: {text}")
    coefficients = [int(value) for value in reversed(polynomial.all_coeffs())]
    return coefficients or [0]


def specialize_polynomial(encoded: list[str], p_value: int, prime: int) -> list[int]:
    return [polynomial_value(parse_polynomial(value), p_value, prime)
            for value in encoded]


def profile_value(profile: dict[str, Any], p_value: int, prime: int) -> int:
    numerator = polynomial_value(profile["numerator"], p_value, prime)
    denominator = polynomial_value(profile["denominator"], p_value, prime)
    if denominator == 0:
        raise ZeroDivisionError(f"p-profile pole at {profile['key']}")
    return numerator * pow(denominator, prime - 2, prime) % prime


def exact_profile_value(profile: dict[str, Any], p_value: int, prime: int) -> int:
    numerator = [exact_fraction_mod(value, prime) for value in profile["numerator"]]
    denominator = [exact_fraction_mod(value, prime) for value in profile["denominator"]]
    return profile_value({
        "key": profile["key"], "numerator": numerator,
        "denominator": denominator,
    }, p_value, prime)


def hermite(function: RationalFunction, helper):
    if function.zero_q:
        return RationalFunction.zero(function.prime), RationalFunction.zero(function.prime)
    reduction = helper.rational_hermite(
        function.numerator, function.denominator, function.prime
    )
    if not reduction["verified"]:
        raise RuntimeError("cross rational Hermite identity failed")
    primitive = RationalFunction.make(
        reduction["primitive_numerator"], reduction["primitive_denominator"],
        function.prime, helper,
    )
    remainder = RationalFunction.make(
        reduction["remainder_numerator"], reduction["remainder_denominator"],
        function.prime, helper,
    )
    return primitive, remainder


def load_context(prime: int, deck_path: Path | None = None) -> dict[str, Any]:
    helper = load_module("cf303_finite_gauge_helper", HELPER)
    lift = load_module("cf303_finite_gauge_lift", EXACT_LIFT)
    analysis = load_module("cf303_finite_gauge_analysis", ANALYSIS)
    candidate = load_module("cf303_finite_gauge_candidate", CANDIDATE)
    q1 = lift.load_image(Q1)
    q2 = lift.load_image(Q2)
    candidates, _ = candidate.build_candidates(q1, q2, lift, analysis)
    support = {
        tuple(profile["key"]): profile
        for profile in candidates["shared_scale"]
        if profile["key"][0] == "u_denominator"
    }
    if deck_path is None:
        deck_path = DECK_DIR / f"cf303_block1_laurent_deck_q{prime}.json"
    deck = json.loads(deck_path.read_text())
    if deck.get("status") != "CF303Block1ModularLaurentDeckAcceptedV1":
        raise RuntimeError("modular Laurent deck is not accepted")
    deck_map = {tuple(profile["key"]): profile for profile in deck["profiles"]}
    inputs = json.loads(INPUT.read_text())
    if inputs.get("status") != "CF303Block1FiniteGaugeInputsV1":
        raise RuntimeError("finite-gauge diagonal input is not accepted")

    def input_function(record, p_value):
        return RationalFunction.make(
            specialize_polynomial(record["Numerator"], p_value, prime),
            specialize_polynomial(record["Denominator"], p_value, prime),
            prime, helper,
        )

    def denominator(channel, field, p_value):
        values = {
            int(key[-1]): exact_profile_value(profile, p_value, prime)
            for key, profile in support.items()
            if key[1] == channel and key[2] == field
        }
        if set(values) != set(range(len(values))):
            raise RuntimeError(f"noncontiguous u denominator {channel}:{field}")
        return [values[index] for index in range(len(values))]

    return {
        "prime": prime, "helper": helper, "support": support,
        "deck_map": deck_map, "inputs": inputs,
        "input_function": input_function, "denominator": denominator,
    }


def run_point(
    context: dict[str, Any], p: Fraction,
    orders: tuple[int, ...] = ORDERS,
) -> dict[str, Any]:
    prime = context["prime"]
    helper = context["helper"]
    deck_map = context["deck_map"]
    inputs = context["inputs"]
    p_value = exact_fraction_mod(p, prime)
    input_function = context["input_function"]
    s11 = input_function(inputs["s11"], p_value)
    diagonal = [[input_function(record, p_value) for record in row]
                for row in inputs["d"]]
    denominator = context["denominator"]
    denominators = {
        (channel, field): denominator(channel, field, p_value)
        for channel in CHANNELS
        for field in ("primitive_denominator", "remainder_denominator")
    }

    def incoming(channel, field, order):
        indices = sorted({
            int(key[3]) for key in deck_map
            if key[:3] == ("laurent_profile", channel, field)
            and key[4] == order
        })
        if indices != list(range(len(indices))):
            raise RuntimeError(f"noncontiguous incoming numerator {channel}:{field}:{order}")
        numerator = [profile_value(
            deck_map[("laurent_profile", channel, field, index, order)],
            p_value, prime,
        ) for index in indices]
        denominator_field = (
            "primitive_denominator" if field == "primitive_numerator"
            else "remainder_denominator"
        )
        return RationalFunction.make(
            numerator, denominators[(channel, denominator_field)],
            prime, helper,
        )

    base = exact_fraction_mod(Fraction(*inputs["base_point"]), prime)
    previous = [RationalFunction.zero(prime) for _ in CHANNELS]
    records = []
    started = time.perf_counter()
    for order in orders:
        current = []
        for row, channel in enumerate(CHANNELS):
            cross = RationalFunction.zero(prime)
            for middle in range(len(CHANNELS)):
                cross = cross.add(
                    diagonal[row][middle].multiply(previous[middle], helper),
                    helper,
                )
            cross = cross.add(previous[row].multiply(s11, helper), helper, -1)
            cross_primitive, cross_remainder = hermite(cross, helper)
            total_primitive = incoming(
                channel, "primitive_numerator", order
            ).add(cross_primitive, helper)
            base_value = total_primitive.evaluate(base)
            normalized = total_primitive.add(
                RationalFunction.constant(base_value, prime), helper, -1
            )
            if normalized.evaluate(base) != 0:
                raise RuntimeError(f"base normalization failed at {row}:{order}")
            transformed_remainder = incoming(
                channel, "remainder_numerator", order
            ).add(cross_remainder, helper)
            current.append(normalized)
            records.append({
                "order": order, "row": row + 1,
                "h_numerator": list(normalized.numerator),
                "h_denominator": list(normalized.denominator),
                "k_numerator": list(transformed_remainder.numerator),
                "k_denominator": list(transformed_remainder.denominator),
                "cross_zero": cross.zero_q,
                "degrees": {
                    "h": [len(normalized.numerator) - 1,
                          len(normalized.denominator) - 1],
                    "k": [len(transformed_remainder.numerator) - 1,
                          len(transformed_remainder.denominator) - 1],
                    "cross": [len(cross.numerator) - 1,
                              len(cross.denominator) - 1],
                },
            })
        previous = current
    report = {
        "status": "CF303Block1ModularFiniteGaugePointAcceptedV1",
        "block": [25, 1], "prime": prime,
        "p": [p.numerator, p.denominator],
        "source_boundary_orders": inputs["source_boundary_orders"],
        "target_output_top": inputs["target_output_top"],
        "demanded_h_orders": inputs["demanded_h_orders"],
        "recurrence_window": inputs["recurrence_window"],
        "base_point": inputs["base_point"],
        "records": records,
        "seconds": time.perf_counter() - started,
        "acceptance": (
            "Every new cross form passed the modular rational Hermite identity "
            "and every H_n vanishes at u=1/2."
        ),
    }
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=2_305_843_009_213_691_819)
    parser.add_argument("--p", type=Fraction, default=Fraction(3))
    parser.add_argument("--output", type=Path)
    parser.add_argument("--summary-only", action="store_true")
    args = parser.parse_args()
    report = run_point(load_context(args.prime), args.p)
    encoded = json.dumps(report, indent=2)
    if args.summary_only:
        print(json.dumps({
            "status": report["status"], "prime": report["prime"],
            "p": report["p"], "records": len(report["records"]),
            "seconds": report["seconds"],
        }))
    else:
        print(encoded)
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
