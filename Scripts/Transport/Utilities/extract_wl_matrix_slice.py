#!/usr/bin/env python3
"""Lexically extract a rectangular slice from WL Association matrices.

Mathematical entries remain byte strings.  The source matrices are never
parsed or instantiated, which is useful for taking a small block from a large
saved differential equation before a Wolfram kernel is started.
"""

from __future__ import annotations

import argparse
import mmap
from pathlib import Path


def matrix_rows(data: mmap.mmap, key: str, wanted: set[int]) -> list[bytes]:
    needle = ('"' + key + '"').encode()
    position = data.find(needle)
    if position < 0:
        raise ValueError(f"Association key not found: {key}")
    arrow = data.find(b"->", position + len(needle))
    opening = data.find(b"{", arrow + 2)
    if arrow < 0 or opening < 0:
        raise ValueError(f"Malformed matrix value for key: {key}")

    found: list[bytes] = []
    depth = 0
    row = 0
    row_start: int | None = None
    in_string = escaped = False
    comment_depth = 0
    index = opening
    while index < len(data):
        current = data[index]
        following = data[index + 1] if index + 1 < len(data) else -1
        if comment_depth:
            if current == 40 and following == 42:  # (*
                comment_depth += 1
                index += 2
                continue
            if current == 42 and following == 41:  # *)
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
        elif current == 123:  # {
            if depth == 1:
                row += 1
                if row in wanted:
                    row_start = index
            depth += 1
        elif current == 125:  # }
            if depth == 2 and row_start is not None:
                found.append(data[row_start:index + 1])
                row_start = None
            depth -= 1
            if depth == 0:
                break
        index += 1
    if len(found) != len(wanted):
        raise ValueError(f"Expected {len(wanted)} rows, got {len(found)}")
    return found


def list_items(encoded: bytes) -> list[bytes]:
    if encoded[:1] != b"{" or encoded[-1:] != b"}":
        raise ValueError("Expected an encoded WL List")
    items: list[bytes] = []
    start = 1
    parentheses = square = curly = 0
    in_string = escaped = False
    comment_depth = 0
    index = 1
    while index < len(encoded) - 1:
        current = encoded[index]
        following = encoded[index + 1]
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
        elif current == 40:
            parentheses += 1
        elif current == 41:
            parentheses -= 1
        elif current == 91:
            square += 1
        elif current == 93:
            square -= 1
        elif current == 123:
            curly += 1
        elif current == 125:
            curly -= 1
        elif current == 44 and parentheses == square == curly == 0:
            items.append(encoded[start:index].strip())
            start = index + 1
        index += 1
    items.append(encoded[start:-1].strip())
    return items


def wl_list(items: list[bytes]) -> bytes:
    return b"{" + b", ".join(items) + b"}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--key", action="append", required=True)
    parser.add_argument("--rows", nargs="+", type=int, required=True)
    parser.add_argument("--columns", nargs="+", type=int, required=True)
    arguments = parser.parse_args()
    for name, indices in (("rows", arguments.rows),
                          ("columns", arguments.columns)):
        if indices != sorted(set(indices)) or indices[0] < 1:
            parser.error(f"{name} must be sorted, unique, positive indices")

    matrices: list[bytes] = []
    with arguments.source.open("rb") as stream, mmap.mmap(
            stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
        for key in arguments.key:
            rows = matrix_rows(data, key, set(arguments.rows))
            selected = []
            for row in rows:
                entries = list_items(row)
                if len(entries) < arguments.columns[-1]:
                    raise ValueError(
                        f"Matrix {key} has only {len(entries)} columns"
                    )
                selected.append(wl_list([
                    entries[column - 1] for column in arguments.columns
                ]))
            matrices.append(
                b'"' + key.encode() + b'" -> ' + wl_list(selected)
            )
    payload = (
        b'<|"Source" -> "' + str(arguments.source).encode()
        + b'", "Rows" -> '
        + wl_list([str(row).encode() for row in arguments.rows])
        + b', "Columns" -> '
        + wl_list([str(column).encode() for column in arguments.columns])
        + b', "Matrices" -> <|' + b", ".join(matrices) + b"|>|>\n"
    )
    arguments.output.write_bytes(payload)
    print(
        f"keys={','.join(arguments.key)} rows={len(arguments.rows)} "
        f"columns={len(arguments.columns)} output_bytes={len(payload)}"
    )


if __name__ == "__main__":
    main()
