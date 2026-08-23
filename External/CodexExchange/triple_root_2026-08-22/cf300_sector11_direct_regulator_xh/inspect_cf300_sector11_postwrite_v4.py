#!/usr/bin/env python3
"""Independent exact-text formal audit of the pinned CF300 V4 continuation.

This inspector never starts Wolfram.  It parses every entry of the 22 x 22
completed prefix in the serialized input and output connections and computes
formal multidegrees in (eps, q), where q=P(eps)/eps^2.  In particular, it does
not use the syntactic Mathematica predicate FreeQ[entry/eps, eps].
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import sys
from pathlib import Path

from inspect_cf300_sector11_regulator_structure_v2 import (
    connection_from_value,
    expression_multidegrees,
    matrix_from_value,
    sha256,
    unique_list_value,
)


EXPECTED_INPUT_SHA256 = (
    "898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12"
)
EXPECTED_INPUT_BYTES = 33_012_365
EXPECTED_OUTPUT_SHA256 = (
    "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009"
)
EXPECTED_OUTPUT_BYTES = 33_009_263

DEFAULT_INPUT = Path(
    "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/"
    "UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/"
    "CF300/sector_state_CF300_standard.wl"
)
DEFAULT_OUTPUT = Path(
    "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/"
    "UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/"
    "CF300_direct_regulator_v4_candidate/sector_state_CF300_standard.wl"
)


def validate_shape(
    connection: list[list[list[str]]],
    s_matrix: list[list[str]],
    sinverse_matrix: list[list[str]],
) -> None:
    assert len(connection) == 2
    assert all(len(component) == 24 for component in connection)
    assert all(len(row) == 24 for component in connection for row in component)
    assert len(s_matrix) == len(sinverse_matrix) == 24
    assert all(len(row) == 24 for row in s_matrix + sinverse_matrix)


def region(row: int, column: int) -> str:
    if row < 20 and column < 20:
        return "old_20x20"
    if row < 20:
        return "upper_right_20x2"
    if column < 20:
        return "new_lower_left_2x20"
    return "new_diagonal_2x2"


def prefix_census(
    connection: list[list[list[str]]],
) -> tuple[collections.Counter[tuple[str, object]], list[dict[str, object]]]:
    counts: collections.Counter[tuple[str, object]] = collections.Counter()
    failures: list[dict[str, object]] = []
    for component in range(2):
        for row in range(22):
            for column in range(22):
                expression = connection[component][row][column]
                try:
                    degree = expression_multidegrees(expression)
                except Exception as error:  # bounded diagnostics at boundary
                    degree = "parse_failure"
                    if len(failures) < 8:
                        failures.append(
                            {
                                "index": [component + 1, row + 1, column + 1],
                                "error": str(error)[:240],
                                "expression_sha256": hashlib.sha256(
                                    expression.encode("utf-8")
                                ).hexdigest(),
                            }
                        )
                counts[(region(row, column), degree)] += 1
    return counts, failures


def support(
    connection: list[list[list[str]]],
    row_start: int,
    row_stop: int,
    column_start: int,
    column_stop: int,
) -> list[list[int]]:
    return [
        [component + 1, row + 1, column + 1]
        for component in range(2)
        for row in range(row_start, row_stop)
        for column in range(column_start, column_stop)
        if connection[component][row][column].strip() != "0"
    ]


def serializable_counts(
    counts: collections.Counter[tuple[str, object]],
) -> dict[str, int]:
    return {
        f"{name}:{degree!r}": count
        for (name, degree), count in sorted(counts.items(), key=lambda item: repr(item[0]))
    }


def inspect(input_path: Path, output_path: Path) -> dict[str, object]:
    input_path = input_path.resolve()
    output_path = output_path.resolve()
    assert input_path.is_file(), input_path
    assert output_path.is_file(), output_path
    assert input_path != output_path
    assert input_path.stat().st_size == EXPECTED_INPUT_BYTES
    assert output_path.stat().st_size == EXPECTED_OUTPUT_BYTES
    input_hash = sha256(input_path)
    output_hash = sha256(output_path)
    assert input_hash == EXPECTED_INPUT_SHA256
    assert output_hash == EXPECTED_OUTPUT_SHA256

    input_text = input_path.read_text(encoding="utf-8")
    output_text = output_path.read_text(encoding="utf-8")
    input_a = connection_from_value(unique_list_value(input_text, "A"))
    output_a = connection_from_value(unique_list_value(output_text, "A"))
    input_s = matrix_from_value(unique_list_value(input_text, "S"))
    output_s = matrix_from_value(unique_list_value(output_text, "S"))
    input_sinverse = matrix_from_value(unique_list_value(input_text, "SInverse"))
    output_sinverse = matrix_from_value(unique_list_value(output_text, "SInverse"))
    validate_shape(input_a, input_s, input_sinverse)
    validate_shape(output_a, output_s, output_sinverse)

    input_counts, input_parse_failures = prefix_census(input_a)
    output_counts, output_parse_failures = prefix_census(output_a)
    expected_input_counts = {
        ("old_20x20", "zero"): 516,
        ("old_20x20", ((1, 0),)): 284,
        ("upper_right_20x2", "zero"): 80,
        ("new_lower_left_2x20", "zero"): 54,
        ("new_lower_left_2x20", ((0, 1),)): 26,
        ("new_diagonal_2x2", ((1, 0),)): 8,
    }
    expected_output_counts = {
        ("old_20x20", "zero"): 516,
        ("old_20x20", ((1, 0),)): 284,
        ("upper_right_20x2", "zero"): 80,
        ("new_lower_left_2x20", "zero"): 55,
        ("new_lower_left_2x20", ((1, 0),)): 25,
        ("new_diagonal_2x2", ((1, 0),)): 8,
    }
    assert not input_parse_failures, input_parse_failures
    assert not output_parse_failures, output_parse_failures
    assert dict(input_counts) == expected_input_counts, input_counts
    assert dict(output_counts) == expected_output_counts, output_counts

    input_prefix_future = support(input_a, 0, 22, 22, 24)
    output_prefix_future = support(output_a, 0, 22, 22, 24)
    input_lower_left = support(input_a, 20, 22, 0, 20)
    output_lower_left = support(output_a, 20, 22, 0, 20)
    input_diagonal = support(input_a, 20, 22, 20, 22)
    output_diagonal = support(output_a, 20, 22, 20, 22)
    input_future_scaled = support(input_a, 22, 24, 20, 22)
    output_future_scaled = support(output_a, 22, 24, 20, 22)
    assert input_prefix_future == output_prefix_future == []
    eliminated_lower_left = [
        index for index in input_lower_left if index not in output_lower_left
    ]
    assert all(index in input_lower_left for index in output_lower_left)
    assert len(input_lower_left) == 26 and len(output_lower_left) == 25
    # Together legitimately proves this one root-identity channel to be zero.
    # The Wolfram validator independently checks the exact transformed identity.
    assert eliminated_lower_left == [[1, 22, 11]]
    assert input_diagonal == output_diagonal and len(output_diagonal) == 8
    assert input_future_scaled == output_future_scaled
    assert len(output_future_scaled) == 8

    # The unchanged old prefix is additionally bound entry-for-entry.  The
    # changed regions are proved algebraically by the Wolfram validator.
    old_prefix_equal = all(
        input_a[component][row][column] == output_a[component][row][column]
        for component in range(2)
        for row in range(20)
        for column in range(20)
    )
    assert old_prefix_equal
    assert '"Sector" -> 11' in output_text[:64]
    assert '"Stop" ->' not in output_text
    assert '"Method" -> "DirectInvariantSubspace/ScalarSectorBlock"' in output_text[-4096:]
    assert '"Rows" -> 11' in output_text[-4096:]
    assert '"RootIndices" -> {1, 2, 3}' in output_text[-4096:]

    prefix_degree_payload = serializable_counts(output_counts)
    prefix_degree_fingerprint = hashlib.sha256(
        json.dumps(prefix_degree_payload, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()
    return {
        "Status": "PASS",
        "Schema": "CF300Sector11PostwriteFormalInspectorV4",
        "InputStateSHA256": input_hash,
        "OutputStateSHA256": output_hash,
        "InputStateBytes": input_path.stat().st_size,
        "OutputStateBytes": output_path.stat().st_size,
        "CompletedPrefixDimension": 22,
        "FormalPrefixEntriesChecked": 968,
        "FormalEpsilonNonzeroChannels": 317,
        "FormalZeroChannels": 651,
        "PrefixToFutureZeroChannels": 88,
        "InputLowerLeftChannels": 26,
        "OutputLowerLeftNonzeroChannels": 25,
        "AlgebraicallyEliminatedInputChannels": eliminated_lower_left,
        "ChangedDiagonalChannels": 8,
        "FutureScaledChannels": 8,
        "OldPrefixEntrywiseUnchangedQ": old_prefix_equal,
        "OutputPrefixDegreeCensus": prefix_degree_payload,
        "OutputPrefixDegreeFingerprintSHA256": prefix_degree_fingerprint,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("input", nargs="?", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    try:
        result = inspect(args.input, args.output)
        exit_code = 0
    except Exception as error:  # fail closed with bounded diagnostics
        result = {
            "Status": "FAIL",
            "Schema": "CF300Sector11PostwriteFormalInspectorV4",
            "ErrorType": type(error).__name__,
            "Error": str(error)[:600],
        }
        exit_code = 2
    if args.json:
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    else:
        for key, value in result.items():
            print(f"{key}={value}")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
