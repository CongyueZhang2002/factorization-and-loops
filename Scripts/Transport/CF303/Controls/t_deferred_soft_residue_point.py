#!/usr/bin/env python3
"""Bounded two-point validation of the CF303 soft-residue ABI."""

from __future__ import annotations

from fractions import Fraction
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import sys


HERE = Path(__file__).resolve()
SCRIPT = HERE.parents[1] / "cf303_deferred_soft_residue_point.py"
spec = importlib.util.spec_from_file_location("cf303_soft_residue", SCRIPT)
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
REFERENCE = HERE.parents[1] / "Artifacts" / "CF303SoftSourceResidueQ7.json"
known = json.loads(REFERENCE.read_text())
assert known["status"] == "CF303SoftSourceResidueQ7ControlV1"
assert known["dimensions"] == [43, 43]
source_control = [[0] * 43 for _ in range(43)]
for row, column, value in known["entries"]:
    source_control[row - 1][column - 1] = value


def indexed(payload):
    return {
        (entry["order"], entry["target_master"], entry["source_master"]): entry
        for entry in payload["residue_entries"]
    }


def modular_rank(matrix, prime):
    rows = [row[:] for row in matrix]
    rank = 0
    for column in range(len(rows[0])):
        pivot = next((row for row in range(rank, len(rows))
                      if rows[row][column] % prime), None)
        if pivot is None:
            continue
        rows[rank], rows[pivot] = rows[pivot], rows[rank]
        inverse = pow(rows[rank][column] % prime, -1, prime)
        rows[rank] = [value * inverse % prime for value in rows[rank]]
        for row in range(len(rows)):
            if row != rank and rows[row][column] % prime:
                scale = rows[row][column] % prime
                rows[row] = [(left - scale * right) % prime
                             for left, right in zip(rows[row], rows[rank])]
        rank += 1
        if rank == len(rows):
            break
    return rank


def specialized_incoming(payload, epsilon):
    prime = payload["prime"]
    epsilon_value = (epsilon.numerator % prime) * pow(
        epsilon.denominator % prime, -1, prime
    ) % prime
    source_position = {master: index for index, master in enumerate(
        payload["source_rows"]
    )}
    matrix = [[0] * len(source_position) for _ in payload["target_rows"]]
    row_position = {master: index for index, master in enumerate(
        payload["target_rows"]
    )}
    for entry in payload["residue_entries"]:
        assert entry["rational"][1] == 0
        assert entry["elliptic_numerator"] == [0, 0]
        row = row_position[entry["target_master"]]
        column = source_position[entry["source_master"]]
        matrix[row][column] = (
            matrix[row][column] + entry["rational"][0] *
            pow(epsilon_value, entry["order"], prime)
        ) % prime
    return matrix


def matrix_product(left, right, prime):
    columns = list(zip(*right))
    return [[sum(a * b for a, b in zip(row, column)) % prime
             for column in columns] for row in left]


for point, epsilon in ((Fraction(3), Fraction(1, 7)),
                       (Fraction(239, 47), Fraction(5, 17))):
    result = module.build_point_payload(module.DEFAULT_SCRATCH, point)
    assert result["status"] == "CF303DeferredSoftResiduePointV1"
    assert result["contribution_counts"] == {
        "base": 182, "exceptions": 84, "cross_k": 98, "block1": 14,
    }
    assert result["combined_nonzero_coordinate_count"] == 280
    assert result["coefficient_field_usage"] == {
        "omega_nonzero_coordinate_count": 0,
        "elliptic_nonzero_coordinate_count": 0,
        "rational_base_only": True,
    }
    endpoint_map = result["physical_endpoint_map"]
    assert endpoint_map["status"] == "CF303PhysicalEndpointMapPointV1"
    assert endpoint_map["raw_h_valuation_counts"] == {"-2": 112}
    assert endpoint_map["source_valuation_counts"] == {
        "-2": 61, "-1": 58, "0": 14,
    }
    assert endpoint_map["final_valuation_counts"] == {"0": 10}
    assert endpoint_map["source_principal_term_counts"] == {
        "-2": 61, "-1": 119,
    }
    assert endpoint_map["maximum_source_pole_order"] == 2
    assert endpoint_map["source_nonzero_coordinate_count"] == 133
    assert endpoint_map["source_zero_coordinate_count"] == 7
    assert endpoint_map["final_nonzero_coordinate_count"] == 10
    assert endpoint_map["final_zero_coordinate_count"] == 2
    assert endpoint_map["elliptic_y_nonzero_coordinate_count"] == 0
    assert {entry["order"] for entry in result["residue_entries"]} == set(
        range(-2, 5)
    )
    assert all(sum(entry["order"] == order
                   for entry in result["residue_entries"]) == 40
               for order in range(-2, 5))
    entries = indexed(result)
    assert set(entries[-2, 44, 1]["sources"]) == {"block1", "cross_k"}
    assert set(entries[-2, 44, 2]["sources"]) == {
        "cross_k", "exceptions"
    }
    assert all(entry["rational"] != [0, 0]
               for entry in result["residue_entries"])
    incoming = specialized_incoming(result, epsilon)
    assert sum(value != 0 for row in incoming for value in row) == 40
    assert modular_rank(incoming, result["prime"]) == 2
    prime = result["prime"]
    assert prime == known["prime"]
    assert str(point) in known["accepted_points"]
    source = source_control
    assert modular_rank(source, prime) == 7
    assert modular_rank(source + incoming, prime) - modular_rank(source, prime) == 2
    full = [row + [0, 0] for row in source] + [row + [0, 0]
                                                       for row in incoming]
    assert modular_rank(full, prime) == 9
    power = full
    nullities = []
    for _ in range(4):
        nullities.append(45 - modular_rank(power, prime))
        power = matrix_product(power, full, prime)
    assert nullities == [36, 38, 38, 38]

    # rho=endpoint-u reverses odd Laurent powers.
    r = result["endpoint"]["value"]
    local = module.rational_function_local_data(SimpleNamespace(
        numerator=(2 - 3 * r, 3),
        denominator=(r * r, -2 * r, 1),
    ), r, prime)
    assert local["valuation"] == -2
    assert local["principal"] == {-2: 2, -1: prime - 3}

print("CF303 deferred soft residue point ABI: PASS at p=3 and p=239/47; "
      "B 40/86 and rank 2, rank(B|ker Rs)=2, full rank 9, "
      "nullities {36,38,38,38}; W=[T25.H,T25] principal deck bounded")
