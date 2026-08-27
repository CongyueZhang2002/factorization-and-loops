#!/usr/bin/env python3
"""No-kernel diagnosis of the V2 exit-71 full-prefix predicate."""

from __future__ import annotations

import collections
import hashlib
import importlib.util
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
INSPECTOR = HERE / "inspect_cf300_sector11_regulator_structure_v2.py"
EXPECTED_INSPECTOR_SHA256 = (
    "036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3"
)
EXPECTED_DISTRIBUTED = [
    (1, 18, 6, 7, 530,
     "6e11a172ec08c7aa334672ee16ea689b8de91e8b800e99bc4c211e9e98b2363c"),
    (2, 18, 6, 13, 747,
     "aff23d324ced5da40b4ca8695b18343d6f1439084060549bd9abcc6ca5e0a293"),
]
EPSILON = re.compile(r"(?<![A-Za-z0-9$])eps(?![A-Za-z0-9$])")


assert hashlib.sha256(INSPECTOR.read_bytes()).hexdigest() == (
    EXPECTED_INSPECTOR_SHA256
)
spec = importlib.util.spec_from_file_location("cf300_structure_v2", INSPECTOR)
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

state = module.DEFAULT_STATE.read_text(encoding="utf-8")
connection = module.connection_from_value(module.unique_list_value(state, "A"))
histogram: collections.Counter[int] = collections.Counter()
distributed: list[tuple[int, int, int, int, int, str]] = []

for component in range(2):
    for row in range(20):
        for column in range(20):
            expression = connection[component][row][column]
            if expression == "0":
                continue
            occurrences = len(EPSILON.findall(expression))
            histogram[occurrences] += 1
            degrees = module.expression_multidegrees(expression)
            assert degrees == ((1, 0),)
            if occurrences != 1:
                distributed.append(
                    (
                        component + 1,
                        row + 1,
                        column + 1,
                        occurrences,
                        len(expression),
                        hashlib.sha256(expression.encode()).hexdigest(),
                    )
                )

assert histogram == {1: 282, 7: 1, 13: 1}
assert distributed == EXPECTED_DISTRIBUTED

print("CF300_SECTOR11_V2_EXIT71_STATIC_DIAGNOSIS PASS")
print(f"old_prefix_eps_occurrence_histogram={dict(histogram)}")
print(f"homogeneous_but_distributed_entries={distributed}")
print("predicted_v2_legacy_first_failure={1,18,6}")
print(
    "cause=FreeQ[value/eps,eps] is a syntactic cancellation test, not an "
    "exact homogeneity test for a Plus whose terms each contain eps"
)
