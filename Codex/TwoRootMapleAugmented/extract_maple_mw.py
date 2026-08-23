#!/usr/bin/env python3
"""Extract text fields from a Maple XML worksheet in document order."""

from __future__ import annotations

import argparse
import html
import xml.etree.ElementTree as ET
from pathlib import Path


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    root = ET.parse(args.input).getroot()
    records: list[str] = []
    for element in root.iter():
        if local_name(element.tag) != "Text-field":
            continue
        text = html.unescape("".join(element.itertext())).strip()
        if not text:
            continue
        style = element.attrib.get("style", "")
        prompt = element.attrib.get("prompt", "")
        records.append(f"STYLE={style!r} PROMPT={prompt!r}\n{text}\n")

    args.output.write_text("\n".join(records), encoding="utf-8")


if __name__ == "__main__":
    main()
