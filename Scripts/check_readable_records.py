#!/usr/bin/env python3
"""Check readable records and companion presence, without hashing result data."""
from pathlib import Path
import argparse
import json
import re

HEADER = "(* FeynFacet readable record 2;"
CONTEXT = re.compile(r"[A-Za-z$][A-Za-z0-9$]*`[A-Za-z$][A-Za-z0-9$]*")

def mathematical_text(text):
    """Exclude literal strings and nested Wolfram comments from the symbol scan."""
    parts = []
    i = 0
    while i < len(text):
        if text[i] == '"':
            i += 1
            while i < len(text):
                if text[i] == "\\":
                    i += 2
                elif text[i] == '"':
                    i += 1
                    break
                else:
                    i += 1
            parts.append(" ")
        elif text.startswith("(*", i):
            depth = 1
            i += 2
            while i < len(text) and depth:
                if text.startswith("(*", i):
                    depth += 1
                    i += 2
                elif text.startswith("*)", i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            parts.append(" ")
        else:
            parts.append(text[i])
            i += 1
    return "".join(parts)

def audit(directories):
    files = sorted({p for d in directories for p in Path(d).rglob("*")
                    if p.is_file() and p.suffix in (".wl", ".m")})
    errors = []
    records = []
    for file in files:
        text = file.read_text(encoding="utf-8", errors="replace")
        if not text.startswith(HEADER):
            continue  # Input cards, programs and solver-native files are separate formats.
        companion = Path(str(file) + ".meta.wxf")
        if not companion.is_file():
            errors.append({"File": str(file), "Error": "Missing companion"})
        prefixes = sorted(set(CONTEXT.findall(mathematical_text(text))))
        if prefixes:
            errors.append({"File": str(file), "Error": "Qualified mathematical symbols",
                           "Symbols": prefixes})
        records.append({"File": str(file), "TextBytes": file.stat().st_size,
                        "MetadataBytes": companion.stat().st_size if companion.is_file() else 0})
    for directory in directories:
        for file in Path(directory).rglob("*.meta.wxf"):
            if not Path(str(file)[:-len(".meta.wxf")]).is_file():
                errors.append({"File": str(file), "Error": "Orphan companion"})
    return {"Records": len(records), "TextBytes": sum(x["TextBytes"] for x in records),
            "MetadataBytes": sum(x["MetadataBytes"] for x in records),
            "Errors": errors}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directories", nargs="+", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    if not all(d.is_dir() for d in args.directories):
        parser.error("Every input must be an existing directory.")
    result = audit(args.directories)
    text = json.dumps(result, indent=2) + "\n"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(text)
    print(text, end="")
    return 1 if result["Errors"] else 0

if __name__ == "__main__":
    raise SystemExit(main())
