#!/usr/bin/env python3
"""Build the rational CF303 block-1 Laurent deck at one fixed (q,p).

This is a portable, validation-only compiler.  Its input is an accepted
fixed-p rational-in-epsilon lift produced directly from the preserved block-1
source.  It expands epsilon only through the declared finite demand window;
it does not claim a characteristic-zero reconstruction in p.
"""

from __future__ import annotations

import argparse
import gzip
import json
from pathlib import Path
from typing import Any


BUNDLE = Path(__file__).resolve().parent
Q7 = 2_305_843_009_213_693_693
ORDERS = tuple(range(-3, 5))
RATIONAL_CHANNELS = {"1,1,rational", "2,1,rational"}
NUMERATOR_FIELDS = {"primitive_numerator", "remainder_numerator"}


def read_json(path: Path) -> dict[str, Any]:
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt") as stream:
        return json.load(stream)


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix == ".gz":
        with gzip.open(path, "wt") as stream:
            json.dump(value, stream, separators=(",", ":"))
            stream.write("\n")
    else:
        path.write_text(json.dumps(value, indent=2) + "\n")


def laurent_coefficient(
    numerator: list[int], denominator: list[int], order: int, prime: int,
) -> int:
    numerator_start = next(
        (index for index, value in enumerate(numerator) if value % prime), None
    )
    denominator_start = next(
        (index for index, value in enumerate(denominator) if value % prime), None
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
    inverse_lead = pow(denominator[0] % prime, prime - 2, prime)
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


def build_deck(
    fixed: dict[str, Any], source_name: str,
    orders: tuple[int, ...] = ORDERS,
) -> dict[str, Any]:
    if fixed.get("status") != "CF303Block1FixedTangentialPointEpsilonDataValidated":
        raise RuntimeError("input is not an accepted fixed-p epsilon lift")
    prime = fixed.get("prime")
    point = fixed.get("p")
    if not isinstance(prime, int) or prime <= 2:
        raise RuntimeError("invalid prime")
    if not (
        isinstance(point, list) and len(point) == 2
        and all(isinstance(value, int) for value in point)
    ):
        raise RuntimeError("invalid fixed tangential point")

    profiles = []
    coordinate_keys = set()
    for coordinate in fixed.get("lifted_coordinates", []):
        channel = coordinate.get("channel")
        field = coordinate.get("field")
        index = coordinate.get("index")
        if channel not in RATIONAL_CHANNELS or field not in NUMERATOR_FIELDS:
            continue
        if not isinstance(index, int) or index < 0:
            raise RuntimeError("invalid rational coordinate index")
        key = (channel, field, index)
        if key in coordinate_keys:
            raise RuntimeError(f"duplicate rational coordinate {key}")
        coordinate_keys.add(key)
        numerator = coordinate.get("numerator")
        denominator = coordinate.get("denominator")
        if not (
            isinstance(numerator, list) and numerator
            and isinstance(denominator, list) and denominator
            and all(isinstance(value, int) for value in numerator + denominator)
        ):
            raise RuntimeError(f"malformed epsilon rational function {key}")
        for order in orders:
            value = laurent_coefficient(numerator, denominator, order, prime)
            profiles.append({
                "key": ["laurent_profile", channel, field, index, order],
                "numerator": [value],
                "denominator": [1],
                "numerator_degree": 0 if value else -1,
                "denominator_degree": 0,
                "total_degree": 0,
            })

    expected_coordinates = sum(
        int(fixed.get("channel_layouts", {}).get(channel, {}).get(field, 0))
        for channel in sorted(RATIONAL_CHANNELS)
        for field in sorted(NUMERATOR_FIELDS)
    )
    if expected_coordinates and len(coordinate_keys) != expected_coordinates:
        raise RuntimeError(
            f"rational coordinate layout {len(coordinate_keys)}/"
            f"{expected_coordinates}"
        )
    if len(profiles) != len(coordinate_keys) * len(orders):
        raise RuntimeError("incomplete Laurent profile layout")
    return {
        "status": "CF303Block1FiniteFieldLaurentDeckValidated",
        "block": [25, 1],
        "prime": prime,
        "requested_orders": list(orders),
        "coordinate_count": len(coordinate_keys),
        "profile_count": len(profiles),
        "source_fixed_p_epsilon_lift": source_name,
        "source_p": point,
        "profiles": profiles,
        "scope": (
            "finite-field validation deck at one fixed tangential point; "
            "not a characteristic-zero p-dependent solution"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input", type=Path,
        default=BUNDLE / "cf303_block1_circuit_q7_p3_fixed_epsilon.json.gz",
    )
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    fixed = read_json(args.input)
    output = args.output or BUNDLE / "block1_modular_laurent_decks" / (
        f"cf303_block1_laurent_deck_q{fixed.get('prime', Q7)}_"
        f"p{fixed.get('p', [0, 1])[0]}d{fixed.get('p', [0, 1])[1]}.json.gz"
    )
    deck = build_deck(fixed, args.input.name)
    write_json(output, deck)
    print(json.dumps({
        "status": deck["status"],
        "prime": deck["prime"],
        "p": deck["source_p"],
        "profiles": deck["profile_count"],
        "output": str(output),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
