#!/usr/bin/env python3
"""Extract selected rows from a two-variable WL connection without loading it.

The input is a Wolfram Language Association whose requested key stores
``{A1, A2}``, with both components rectangular Lists.  The output is a small
WL Association containing only the requested rows.  Parsing is lexical: the
large matrices are never instantiated in either Python or a Wolfram kernel.
"""

from __future__ import annotations

import argparse
import mmap
from pathlib import Path


def extract_rows(data: mmap.mmap, key: str, wanted: list[int]) -> list[list[bytes]]:
    needle = ('"' + key + '"').encode()
    position = data.find(needle)
    if position < 0:
        raise ValueError(f"Association key not found: {key}")
    arrow = data.find(b"->", position + len(needle))
    opening = data.find(b"{", arrow + 2)
    if arrow < 0 or opening < 0:
        raise ValueError(f"Malformed value for key: {key}")

    selected = set(wanted)
    found: list[list[bytes]] = []
    depth = 0
    component = -1
    row = 0
    row_start: int | None = None
    in_string = False
    escaped = False
    comment_depth = 0
    i = opening
    while i < len(data):
        current = data[i]
        following = data[i + 1] if i + 1 < len(data) else -1
        if comment_depth:
            if current == 40 and following == 42:  # (*
                comment_depth += 1
                i += 2
                continue
            if current == 42 and following == 41:  # *)
                comment_depth -= 1
                i += 2
                continue
            i += 1
            continue
        if in_string:
            if escaped:
                escaped = False
            elif current == 92:
                escaped = True
            elif current == 34:
                in_string = False
            i += 1
            continue
        if current == 40 and following == 42:
            comment_depth = 1
            i += 2
            continue
        if current == 34:
            in_string = True
            i += 1
            continue
        if current == 123:  # {
            if depth == 1:
                component += 1
                found.append([])
                row = 0
            elif depth == 2:
                row += 1
                if row in selected:
                    row_start = i
            depth += 1
        elif current == 125:  # }
            if depth == 3 and row_start is not None:
                found[component].append(data[row_start : i + 1])
                row_start = None
            depth -= 1
            if depth == 0:
                break
        i += 1

    if len(found) != 2 or any(len(rows) != len(wanted) for rows in found):
        raise ValueError(
            "Expected two connection components and "
            f"{len(wanted)} selected rows in each; got {[len(x) for x in found]}"
        )
    return found


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("key")
    parser.add_argument("output", type=Path)
    parser.add_argument("rows", nargs="+", type=int)
    arguments = parser.parse_args()
    if arguments.rows != sorted(set(arguments.rows)) or arguments.rows[0] < 1:
        parser.error("rows must be sorted, unique, positive one-based indices")

    with arguments.source.open("rb") as stream, mmap.mmap(
        stream.fileno(), 0, access=mmap.ACCESS_READ
    ) as data:
        components = extract_rows(data, arguments.key, arguments.rows)

    payload = (
        b'<|"Source" -> "'
        + str(arguments.source).encode()
        + b'", "Key" -> "'
        + arguments.key.encode()
        + b'", "Rows" -> {'
        + b", ".join(str(row).encode() for row in arguments.rows)
        + b'}, "TensorRows" -> {'
        + b", ".join(b"{" + b", ".join(rows) + b"}" for rows in components)
        + b"}|>\n"
    )
    arguments.output.write_bytes(payload)
    print(
        f"components={len(components)} rows_per_component={len(components[0])} "
        f"output_bytes={len(payload)}"
    )


if __name__ == "__main__":
    main()
