#!/usr/bin/env python3
"""Split a textual Wolfram checkpoint's PrevD matrix without evaluating it.

Usage:
  split_prevd_checkpoint.py CHECKPOINT.wl OUTPUT_DIRECTORY [--groups 8]

The output contains skeleton.wl, manifest.wl, and size-balanced group text
files under groups/.  The original matrix positions travel with every group.
"""

from __future__ import annotations

import argparse
import os
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO, Iterable


@dataclass(frozen=True)
class Entry:
    row: int
    column: int
    start: int
    end: int

    @property
    def size(self) -> int:
        return self.end - self.start


def _atomic_writer(path: Path):
    temporary = path.with_name(path.name + f".tmp-{os.getpid()}")
    path.parent.mkdir(parents=True, exist_ok=True)

    class Writer:
        def __enter__(self) -> BinaryIO:
            self.stream = temporary.open("wb")
            return self.stream

        def __exit__(self, exception_type, exception, traceback) -> None:
            self.stream.close()
            if exception_type is None:
                os.replace(temporary, path)
            else:
                temporary.unlink(missing_ok=True)

    return Writer()


def _skip_space(stream: BinaryIO) -> bytes:
    byte = stream.read(1)
    while byte and byte in b" \t\r\n":
        byte = stream.read(1)
    return byte


def _find_prevd_start(path: Path) -> int:
    needle = b'"PrevD"'
    overlap = b""
    consumed = 0
    with path.open("rb") as stream, path.open("rb") as probe:
        while True:
            chunk = stream.read(1 << 20)
            if not chunk:
                break
            data = overlap + chunk
            search_from = 0
            while True:
                position = data.find(needle, search_from)
                if position < 0:
                    break
                absolute = consumed - len(overlap) + position
                probe.seek(absolute + len(needle))
                if _skip_space(probe) == b"-" and probe.read(1) == b">":
                    if _skip_space(probe) == b"{":
                        return probe.tell() - 1
                search_from = position + 1
            overlap = data[-(len(needle) - 1) :]
            consumed += len(chunk)
    raise ValueError('no textual Association key "PrevD" -> {...} found')


def _scan_matrix(path: Path, start: int) -> tuple[list[Entry], int, int, int]:
    entries: list[Entry] = []
    rows: list[int] = []
    brace_depth = 0
    square_depth = 0
    parenthesis_depth = 0
    association_depth = 0
    comment_depth = 0
    in_string = False
    escaped = False
    row = 0
    column = 0
    entry_start: int | None = None

    with path.open("rb") as stream:
        stream.seek(start)
        while True:
            position = stream.tell()
            byte = stream.read(1)
            if not byte:
                raise ValueError("PrevD ended before its outer list closed")
            following = stream.peek(1)[:1]

            if comment_depth:
                if byte == b"(" and following == b"*":
                    stream.read(1)
                    comment_depth += 1
                elif byte == b"*" and following == b")":
                    stream.read(1)
                    comment_depth -= 1
                continue

            if in_string:
                if escaped:
                    escaped = False
                elif byte == b"\\":
                    escaped = True
                elif byte == b'"':
                    in_string = False
                continue

            if byte == b"(" and following == b"*":
                stream.read(1)
                comment_depth = 1
                continue
            if byte == b'"':
                in_string = True
                continue
            if byte == b"<" and following == b"|":
                stream.read(1)
                association_depth += 1
                continue
            if byte == b"|" and following == b">":
                stream.read(1)
                association_depth -= 1
                if association_depth < 0:
                    raise ValueError("unbalanced Association delimiter in PrevD")
                continue
            if byte == b"[":
                square_depth += 1
                continue
            if byte == b"]":
                square_depth -= 1
                continue
            if byte == b"(":
                parenthesis_depth += 1
                continue
            if byte == b")":
                parenthesis_depth -= 1
                continue

            at_expression_level = (
                square_depth == 0
                and parenthesis_depth == 0
                and association_depth == 0
            )
            if byte == b"{":
                brace_depth += 1
                if brace_depth == 2 and at_expression_level:
                    row += 1
                    column = 1
                    entry_start = stream.tell()
                continue
            if byte == b"," and brace_depth == 2 and at_expression_level:
                if entry_start is None:
                    raise ValueError("PrevD row contains an empty entry")
                entries.append(Entry(row, column, entry_start, position))
                column += 1
                entry_start = stream.tell()
                continue
            if byte == b"}":
                if brace_depth == 2 and at_expression_level:
                    if entry_start is None:
                        raise ValueError("PrevD contains an empty row")
                    entries.append(Entry(row, column, entry_start, position))
                    rows.append(column)
                    entry_start = None
                    brace_depth = 1
                    continue
                if brace_depth == 1 and at_expression_level:
                    brace_depth = 0
                    end = stream.tell()
                    break
                brace_depth -= 1
                if brace_depth < 0:
                    raise ValueError("unbalanced list delimiter in PrevD")
                continue

    if not rows or len(set(rows)) != 1:
        raise ValueError(f"PrevD is not a nonempty rectangular matrix: {rows}")
    return entries, len(rows), rows[0], end


def _balanced_groups(entries: Iterable[Entry], count: int) -> list[list[Entry]]:
    entries = list(entries)
    count = min(count, len(entries))
    groups: list[list[Entry]] = [[] for _ in range(count)]
    loads = [0] * count
    for entry in sorted(entries, key=lambda item: (-item.size, item.row, item.column)):
        group = min(range(count), key=lambda index: (loads[index], index))
        groups[group].append(entry)
        loads[group] += entry.size
    for group in groups:
        group.sort(key=lambda item: (item.row, item.column))
    return groups


def _copy_bytes(source: BinaryIO, target: BinaryIO, count: int) -> None:
    remaining = count
    while remaining:
        chunk = source.read(min(1 << 20, remaining))
        if not chunk:
            raise ValueError("source ended while writing checkpoint skeleton")
        target.write(chunk)
        remaining -= len(chunk)


def _wl_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    escaped = escaped.replace("\n", "\\n").replace("\r", "\\r")
    return f'"{escaped}"'


def _write_skeleton(source: Path, destination: Path, start: int, end: int) -> None:
    with source.open("rb") as input_stream, _atomic_writer(destination) as output_stream:
        _copy_bytes(input_stream, output_stream, start)
        output_stream.write(b'Missing["ExternalPrevD"]')
        input_stream.seek(end)
        shutil.copyfileobj(input_stream, output_stream, length=1 << 20)


def _read_entry(source: BinaryIO, entry: Entry) -> bytes:
    source.seek(entry.start)
    value = source.read(entry.size).strip()
    if not value:
        raise ValueError(f"empty PrevD entry at ({entry.row}, {entry.column})")
    return value


def _write_group(
    source: Path,
    destination: Path,
    dimensions: tuple[int, int],
    entries: list[Entry],
) -> None:
    positions = ", ".join(f"{{{entry.row}, {entry.column}}}" for entry in entries)
    prefix = (
        '<|"Schema" -> "PrevDCheckpointGroupTextV1", '
        f'"Dimensions" -> {{{dimensions[0]}, {dimensions[1]}}}, '
        f'"Positions" -> {{{positions}}}, "Values" -> {{\n'
    ).encode("utf-8")
    with source.open("rb") as input_stream, _atomic_writer(destination) as output_stream:
        output_stream.write(prefix)
        for index, entry in enumerate(entries):
            if index:
                output_stream.write(b",\n")
            output_stream.write(_read_entry(input_stream, entry))
        output_stream.write(b"\n}|>\n")


def _write_manifest(
    destination: Path,
    source: Path,
    skeleton: Path,
    dimensions: tuple[int, int],
    groups: list[list[Entry]],
    group_directory: Path,
) -> None:
    records = []
    for index, entries in enumerate(groups, 1):
        text_file = (group_directory / f"group_{index:03d}.wl").resolve()
        wxf_file = (group_directory / f"group_{index:03d}.wxf").resolve()
        positions = ", ".join(
            f"{{{entry.row}, {entry.column}}}" for entry in entries
        )
        records.append(
            "<|"
            f'"Index" -> {index}, "TextFile" -> {_wl_string(str(text_file))}, '
            f'"WXFFile" -> {_wl_string(str(wxf_file))}, '
            f'"Positions" -> {{{positions}}}, '
            f'"TextBytes" -> {sum(entry.size for entry in entries)}'
            "|>"
        )
    text = (
        '<|"Schema" -> "PrevDCheckpointSplitV1", '
        f'"SourceFile" -> {_wl_string(str(source.resolve()))}, '
        f'"SkeletonFile" -> {_wl_string(str(skeleton.resolve()))}, '
        f'"Dimensions" -> {{{dimensions[0]}, {dimensions[1]}}}, '
        f'"EntryCount" -> {dimensions[0] * dimensions[1]}, '
        f'"GroupCount" -> {len(groups)}, '
        f'"Groups" -> {{{", ".join(records)}}}|>\n'
    )
    with _atomic_writer(destination) as output_stream:
        output_stream.write(text.encode("utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkpoint", type=Path)
    parser.add_argument("output_directory", type=Path)
    parser.add_argument("--groups", type=int, default=8)
    arguments = parser.parse_args()
    if arguments.groups < 1:
        parser.error("--groups must be positive")

    source = arguments.checkpoint.expanduser().resolve()
    if not source.is_file():
        parser.error(f"checkpoint does not exist: {source}")
    output_directory = arguments.output_directory.expanduser().resolve()
    group_directory = output_directory / "groups"
    group_directory.mkdir(parents=True, exist_ok=True)

    prevd_start = _find_prevd_start(source)
    entries, rows, columns, prevd_end = _scan_matrix(source, prevd_start)
    groups = _balanced_groups(entries, arguments.groups)
    skeleton = output_directory / "skeleton.wl"
    manifest = output_directory / "manifest.wl"

    _write_skeleton(source, skeleton, prevd_start, prevd_end)
    for index, group in enumerate(groups, 1):
        _write_group(
            source,
            group_directory / f"group_{index:03d}.wl",
            (rows, columns),
            group,
        )
    _write_manifest(
        manifest, source, skeleton, (rows, columns), groups, group_directory
    )

    print(f"PrevD {rows}x{columns}: {len(entries)} entries in {len(groups)} groups")
    for index, group in enumerate(groups, 1):
        print(
            f"  group_{index:03d}: {len(group)} entries, "
            f"{sum(entry.size for entry in group)} source bytes"
        )
    print(f"manifest: {manifest}")


if __name__ == "__main__":
    main()
