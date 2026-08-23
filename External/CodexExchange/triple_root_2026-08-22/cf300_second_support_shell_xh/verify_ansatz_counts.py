#!/usr/bin/env python3
"""Independent integer/count model for the CF300 sector-12 next ansatz axes."""

from __future__ import annotations

from math import ceil


CHANNELS_PER_MONOMIAL = 2 * 2 * 4
RESIDUE_COLUMNS_PER_LETTER = 2 * 2
BASE_LETTERS = 36
BASE_DENOMINATOR_BIDEGREE = (4, 5)


def rectangle(dx: int, dy: int) -> set[tuple[int, int]]:
    return {(i, j) for i in range(dx + 1) for j in range(dy + 1)}


def counts(support_count: int, letters: int = BASE_LETTERS) -> tuple[int, int]:
    unknowns = (
        CHANNELS_PER_MONOMIAL * support_count
        + RESIDUE_COLUMNS_PER_LETTER * letters
    )
    points = max(4, ceil((unknowns + 32) / 32))
    return unknowns, points


base = rectangle(4, 5)
first = rectangle(5, 6)
second = rectangle(6, 7)
x_edge = {(6, j) for j in range(7)}
y_edge = {(i, 7) for i in range(6)}
corner = {(6, 7)}

assert len(base) == 30 and counts(len(base)) == (624, 21)
assert len(first) == 42 and counts(len(first)) == (816, 27)
assert len(second) == 56 and counts(len(second)) == (1040, 34)
assert first < second
assert second - first == x_edge | y_edge | corner
assert len(x_edge) == 7 and len(y_edge) == 6 and len(corner) == 1
assert not (x_edge & y_edge or x_edge & corner or y_edge & corner)

support_masks = {
    "X": first | x_edge,
    "Y": first | y_edge,
    "C": first | corner,
    "XY": first | x_edge | y_edge,
    "XC": first | x_edge | corner,
    "YC": first | y_edge | corner,
    "XYC": second,
}
expected_support_counts = {
    "X": (49, 928, 30),
    "Y": (48, 912, 30),
    "C": (43, 832, 27),
    "XY": (55, 1024, 33),
    "XC": (50, 944, 31),
    "YC": (49, 928, 30),
    "XYC": (56, 1040, 34),
}
for name, support in support_masks.items():
    unknowns, points = counts(len(support))
    assert (len(support), unknowns, points) == expected_support_counts[name]
    assert first <= support <= second

# Denominator factors: x, Q, 1-x, 1+x+y, 1+x.
factor_bidegrees = {
    "x": (1, 0),
    "Q": (2, 2),
    "1-x": (1, 0),
    "1+x+y": (1, 1),
    "1+x": (1, 0),
}


def denominator_product_counts(names: tuple[str, ...]) -> tuple[int, int, int, int, int]:
    dx = BASE_DENOMINATOR_BIDEGREE[0] + sum(factor_bidegrees[n][0] for n in names)
    dy = BASE_DENOMINATOR_BIDEGREE[1] + sum(factor_bidegrees[n][1] for n in names)
    support = (dx + 1) * (dy + 1)
    unknowns, points = counts(support)
    return dx, dy, support, unknowns, points


assert denominator_product_counts(("1+x",)) == (5, 5, 36, 720, 24)
assert denominator_product_counts(("1+x+y",)) == (5, 6, 42, 816, 27)
assert denominator_product_counts(("1+x", "1+x+y")) == (6, 6, 49, 928, 30)
assert denominator_product_counts(tuple(factor_bidegrees)) == (10, 8, 99, 1728, 55)

# Orbit closure of the 28 forcing dlog candidates.  Four conjugates per
# candidate gives at most 112 forcing forms; retaining the 8 diagonal forms
# gives at most 120 total letters.  These are upper bounds before exact dedup.
assert counts(30, 120) == (960, 31)
assert counts(42, 120) == (1152, 37)
assert counts(56, 120) == (1376, 44)

# Closing all 36 base forms under the four-element Galois group is the looser
# 144-letter upper bound.
assert counts(30, 144) == (1056, 34)
assert counts(42, 144) == (1248, 40)
assert counts(56, 144) == (1472, 47)

print("CF300_ANSATZ_COUNT_MODEL PASS 33/33")
