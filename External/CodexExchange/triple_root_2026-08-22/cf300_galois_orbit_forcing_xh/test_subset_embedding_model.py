#!/usr/bin/env python3
"""Adversarial finite-field model of the maximal-column implication."""

from __future__ import annotations

from itertools import combinations


P = 101


def dot(left: list[int], right: list[int]) -> int:
    return sum(a * b for a, b in zip(left, right)) % P


# A_base x=b is inconsistent because y^T A_base=0 but y^T b=1.
y = [1, 0, 0]
b = [1, 9, 17]
base_columns = [[0, 1, 0], [0, 0, 1]]
assert all(dot(y, column) == 0 for column in base_columns)
assert dot(y, b) == 1

# A maximal screen may be rejected without ranks if every appended column is
# also annihilated.  Enumerate every subset, including the empty subset.
annihilated_appended = [[0, 3, 4], [0, 8, 2], [0, 99, 1], [0, 5, 5]]
checked = 0
for size in range(len(annihilated_appended) + 1):
    for indices in combinations(range(len(annihilated_appended)), size):
        columns = base_columns + [annihilated_appended[i] for i in indices]
        assert all(dot(y, column) == 0 for column in columns)
        assert dot(y, b) == 1
        checked += 1
assert checked == 2 ** len(annihilated_appended)

# Adversarial control: a column pierced by y invalidates the shortcut.  This
# does not prove consistency; it mandates the independent two-rank fallback.
piercing = [1, 0, 0]
assert dot(y, piercing) != 0

print(f"CF300_SUBSET_EMBEDDING_MODEL PASS subsets={checked} control=pierced")

