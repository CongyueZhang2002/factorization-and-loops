#!/usr/bin/env python3
"""Lexically extract a physical-master slice of the CF303 sector-24 A."""

from __future__ import annotations

import argparse
import mmap
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "Utilities"))
from extract_wl_matrix_slice import list_items, wl_list  # noqa: E402


class PreFinalBlockAExtractionError(RuntimeError):
    pass


def matching_brace(data: mmap.mmap, opening: int) -> int:
    depth = 0
    in_string = escaped = False
    comment_depth = 0
    index = opening
    while index < len(data):
        current = data[index]
        following = data[index + 1] if index + 1 < len(data) else -1
        if comment_depth:
            if current == 40 and following == 42:
                comment_depth += 1
                index += 2
                continue
            if current == 42 and following == 41:
                comment_depth -= 1
                index += 2
                continue
        elif in_string:
            if escaped:
                escaped = False
            elif current == 92:
                escaped = True
            elif current == 34:
                in_string = False
        elif current == 40 and following == 42:
            comment_depth = 1
            index += 2
            continue
        elif current == 34:
            in_string = True
        elif current == 123:
            depth += 1
        elif current == 125:
            depth -= 1
            if depth == 0:
                return index
        index += 1
    raise PreFinalBlockAExtractionError("UnterminatedList")


def association_list_field(data: mmap.mmap, name: str) -> bytes:
    needle = ('"' + name + '"').encode()
    position = data.find(needle)
    if position < 0:
        raise PreFinalBlockAExtractionError(f"MissingField:{name}")
    arrow = data.find(b"->", position + len(needle))
    opening = data.find(b"{", arrow + 2)
    if arrow < 0 or opening < 0:
        raise PreFinalBlockAExtractionError(f"MalformedField:{name}")
    return data[opening:matching_brace(data, opening) + 1]


def selected_matrix(matrix: bytes, rows: list[int], columns: list[int]) -> bytes:
    encoded_rows = list_items(matrix)
    if len(encoded_rows) < max(rows):
        raise PreFinalBlockAExtractionError("MatrixHasTooFewRows")
    selected = []
    for row in rows:
        entries = list_items(encoded_rows[row - 1])
        if len(entries) < max(columns):
            raise PreFinalBlockAExtractionError("MatrixHasTooFewColumns")
        selected.append(wl_list([entries[column - 1] for column in columns]))
    return wl_list(selected)


def nested_integer_list(encoded: bytes, field: str) -> list[list[int]]:
    try:
        value = [
            [int(item) for item in list_items(block)]
            for block in list_items(encoded)
        ]
    except (TypeError, ValueError) as error:
        raise PreFinalBlockAExtractionError(
            f"{field}MustBeNestedIntegerLists"
        ) from error
    if not value or any(not block for block in value):
        raise PreFinalBlockAExtractionError(f"{field}ContainsEmptyBlock")
    return value


def invert_ranges_blocks(
        ranges: list[list[int]], blocks: list[list[int]],
        ) -> tuple[dict[int, int], dict[int, int]]:
    """Return physical->state and state->physical after a strict bijection check."""
    if len(ranges) != len(blocks):
        raise PreFinalBlockAExtractionError(
            "RangesBlocksBlockCountsDiffer"
        )
    if any(len(state) != len(physical)
           for state, physical in zip(ranges, blocks)):
        raise PreFinalBlockAExtractionError(
            "RangesBlocksPairedBlockDimensionsDiffer"
        )
    state_positions = [item for block in ranges for item in block]
    physical_ids = [item for block in blocks for item in block]
    dimension = len(state_positions)
    if sorted(state_positions) != list(range(1, dimension + 1)):
        raise PreFinalBlockAExtractionError(
            "RangesDoNotPartitionStatePositions"
        )
    if len(set(physical_ids)) != dimension:
        raise PreFinalBlockAExtractionError(
            "BlocksContainDuplicatePhysicalMasterIntegralIDs"
        )
    if sorted(physical_ids) != list(range(1, dimension + 1)):
        raise PreFinalBlockAExtractionError(
            "BlocksDoNotEnumeratePhysicalMasterIntegralIDs"
        )
    physical_to_state = dict(zip(physical_ids, state_positions))
    state_to_physical = dict(zip(state_positions, physical_ids))
    if any(
            physical_to_state[physical] != state or
            state_to_physical[state] != physical
            for state, physical in zip(state_positions, physical_ids)):
        raise PreFinalBlockAExtractionError(
            "RangesBlocksMappingIsNotBijective"
        )
    return physical_to_state, state_to_physical


def requested_state_positions(
        requested_physical_ids: list[int], physical_to_state: dict[int, int],
        state_to_physical: dict[int, int], label: str) -> list[int]:
    missing = [
        value for value in requested_physical_ids
        if value not in physical_to_state
    ]
    if missing:
        raise PreFinalBlockAExtractionError(
            f"{label}PhysicalMasterIntegralIDsAbsentFromBlocks:{missing}"
        )
    positions = [physical_to_state[value] for value in requested_physical_ids]
    if [state_to_physical[position] for position in positions] != \
            requested_physical_ids:
        raise PreFinalBlockAExtractionError(
            f"{label}PhysicalMasterIntegralOrderNotPreserved"
        )
    return positions


def extract(state: Path, output: Path,
            row_physical_master_integral_ids: list[int],
            column_physical_master_integral_ids: list[int]) -> dict[str, int]:
    with state.open("rb") as stream, mmap.mmap(
            stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
        sector_match = re.search(
            rb'"Sector"\s*->\s*([0-9]+)', data[:512]
        )
        if sector_match is None or int(sector_match.group(1)) != 24:
            raise PreFinalBlockAExtractionError(
                "SavedStateMustBeSectorTwentyFour"
            )
        matrices = list_items(association_list_field(data, "A"))
        if len(matrices) != 2:
            raise PreFinalBlockAExtractionError("PreFinalBlockAMustHaveTwoDirections")
        ranges_encoded = association_list_field(data, "Ranges")
        blocks_encoded = association_list_field(data, "Blocks")
        ranges = nested_integer_list(ranges_encoded, "Ranges")
        blocks = nested_integer_list(blocks_encoded, "Blocks")
        physical_to_state, state_to_physical = invert_ranges_blocks(
            ranges, blocks
        )
        rows = requested_state_positions(
            row_physical_master_integral_ids, physical_to_state,
            state_to_physical, "Row"
        )
        columns = requested_state_positions(
            column_physical_master_integral_ids, physical_to_state,
            state_to_physical, "Column"
        )
        selected = [selected_matrix(matrix, rows, columns)
                    for matrix in matrices]
    escaped = str(state).replace("\\", "\\\\").replace('"', '\\"')
    payload = b"".join([
        b'<|"DataType" -> "CF303PreFinalBlockBasisConnectionTargetRowSlice", ',
        b'"SchemaVersion" -> 2, "Sector" -> ',
        sector_match.group(1), b', ',
        b'"SourceStatePath" -> ',
        ('"' + escaped + '"').encode(),
        b', "RequestedRowPhysicalMasterIntegralIDs" -> ',
        wl_list([str(value).encode()
                 for value in row_physical_master_integral_ids]),
        b', "RequestedColumnPhysicalMasterIntegralIDs" -> ',
        wl_list([str(value).encode()
                 for value in column_physical_master_integral_ids]),
        b', "DerivedStateRows" -> ',
        wl_list([str(row).encode() for row in rows]),
        b', "DerivedStateColumns" -> ',
        wl_list([str(column).encode() for column in columns]),
        b', "Ranges" -> ', ranges_encoded,
        b', "Blocks" -> ', blocks_encoded,
        b', "MappingValidation" -> <|',
        b'"RangesBlocksMappingIsBijective" -> True, ',
        b'"RequestedPhysicalMasterIntegralOrderPreserved" -> True|>',
        b', "ConnectionMatrices" -> ', wl_list(selected), b'|>\n',
    ])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(payload)
    return {"Directions": 2, "Rows": len(rows), "Columns": len(columns),
            "OutputBytes": len(payload)}


def valid_physical_master_integral_ids(values: list[int]) -> bool:
    return bool(values) and len(values) == len(set(values)) and min(values) > 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("state", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument(
        "--row-physical-master-integral-ids", nargs="+", type=int,
        required=True,
    )
    parser.add_argument(
        "--column-physical-master-integral-ids", nargs="+", type=int,
        required=True,
    )
    arguments = parser.parse_args()
    if (not valid_physical_master_integral_ids(
            arguments.row_physical_master_integral_ids) or
            not valid_physical_master_integral_ids(
                arguments.column_physical_master_integral_ids)):
        parser.error(
            "requested physical master IDs must be unique positive integers"
        )
    try:
        metrics = extract(
            arguments.state, arguments.output,
            arguments.row_physical_master_integral_ids,
            arguments.column_physical_master_integral_ids,
        )
    except (OSError, PreFinalBlockAExtractionError) as error:
        print(f"REFUSED {type(error).__name__}: {error}")
        return 2
    print("EXTRACTED " + " ".join(
        f"{key}={value}" for key, value in metrics.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
