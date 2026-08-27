#!/usr/bin/env python3
"""Static duplicate census for a text-serialized DRCA cache.

This intentionally does not evaluate Wolfram Language.  It scans balanced
Association expressions whose first field is a known DRCA type, hashes their
exact serialized bytes, and reports the upper bound available from exact DAG
deduplication.  It is safe to run while package/runtime hashes are pinned.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter
from pathlib import Path


TYPE_PATTERN = re.compile(
    rb'<\|\s*"Type"\s*->\s*"(DRCA(?:Rational|Polynomial)ExactV1)"'
)


def association_end(data: bytes, start: int) -> int:
    """Return the byte after the balanced Association starting at *start*."""
    if data[start : start + 2] != b"<|":
        raise ValueError(f"no Association opener at byte {start}")
    depth = 0
    index = start
    in_string = False
    escaped = False
    while index < len(data):
        byte = data[index]
        if in_string:
            if escaped:
                escaped = False
            elif byte == 0x5C:  # backslash
                escaped = True
            elif byte == 0x22:  # quote
                in_string = False
            index += 1
            continue
        if byte == 0x22:
            in_string = True
            index += 1
            continue
        pair = data[index : index + 2]
        if pair == b"<|":
            depth += 1
            index += 2
            continue
        if pair == b"|>":
            depth -= 1
            index += 2
            if depth == 0:
                return index
            if depth < 0:
                raise ValueError(f"unbalanced Association at byte {index}")
            continue
        index += 1
    raise ValueError(f"unterminated Association at byte {start}")


def summarize(records: list[bytes]) -> dict[str, object]:
    hashes = [hashlib.sha256(record).hexdigest() for record in records]
    counts = Counter(hashes)
    size_by_hash = {}
    for digest, record in zip(hashes, records, strict=True):
        size_by_hash.setdefault(digest, len(record))
    total_bytes = sum(map(len, records))
    unique_bytes = sum(size_by_hash.values())
    top = [
        {
            "sha256": digest,
            "occurrences": occurrences,
            "serialized_bytes_each": size_by_hash[digest],
            "duplicate_bytes": (occurrences - 1) * size_by_hash[digest],
        }
        for digest, occurrences in counts.most_common(20)
    ]
    return {
        "record_count": len(records),
        "unique_exact_record_count": len(counts),
        "duplicate_occurrence_count": len(records) - len(counts),
        "serialized_record_bytes": total_bytes,
        "unique_serialized_record_bytes": unique_bytes,
        "exact_dedup_byte_saving_upper_bound": total_bytes - unique_bytes,
        "exact_dedup_fraction": (
            (total_bytes - unique_bytes) / total_bytes if total_bytes else 0.0
        ),
        "top_multiplicities": top,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("cache", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    data = args.cache.read_bytes()
    records: dict[str, list[bytes]] = {
        "DRCARationalExactV1": [],
        "DRCAPolynomialExactV1": [],
    }
    for match in TYPE_PATTERN.finditer(data):
        start = match.start()
        end = association_end(data, start)
        records[match.group(1).decode("ascii")].append(data[start:end])
    report = {
        "status": "SerializedDirectCacheStaticCensusV1",
        "cache": str(args.cache.resolve()),
        "cache_bytes": len(data),
        "cache_sha256": hashlib.sha256(data).hexdigest(),
        "records": {kind: summarize(items) for kind, items in records.items()},
    }
    payload = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(payload, encoding="utf-8")
    else:
        print(payload, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
