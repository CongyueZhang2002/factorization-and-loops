"""Stream the additive terms of an emitted rational expression, without algebra.

Only depth-zero '+' separators are split. Parentheses are checked across chunk
boundaries. This handles current (target)*(reduction) columns without assuming
that either factor is a monomial. The original file is never modified.
"""
import argparse
from pathlib import Path
import re

DELIMITERS = re.compile(rb"[()+]")


def summands(stream, chunk_size=1 << 20):
    depth, parts = 0, []
    while chunk := stream.read(chunk_size):
        start = 0
        for match in DELIMITERS.finditer(chunk):
            char, position = match.group(), match.start()
            if char == b"(":
                depth += 1
            elif char == b")":
                depth -= 1
                if depth < 0:
                    raise ValueError("Unbalanced closing parenthesis.")
            elif depth == 0:
                parts.append(chunk[start:position])
                term = b"".join(parts).strip()
                if not term:
                    raise ValueError("Empty additive term.")
                yield term
                parts, start = [], position + 1
        parts.append(chunk[start:])
    if depth:
        raise ValueError("Unbalanced opening parenthesis.")
    term = b"".join(parts).strip()
    if not term:
        raise ValueError("Empty expression or trailing separator.")
    yield term


def split_file(source, destination):
    source, destination = Path(source), Path(destination)
    if source.resolve() == destination.resolve():
        raise ValueError("The destination must differ from the source.")
    temporary = destination.with_name(destination.name + ".partial")
    count = 0
    try:
        with source.open("rb") as input_file, temporary.open("wb") as output_file:
            for term in summands(input_file):
                # The emitter produces arithmetic only; the Wolfram reader
                # separately validates the allowed variables and rational grammar.
                output_file.write(re.sub(rb"\s+", b"", term) + b"\n")
                count += 1
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    return count


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source")
    parser.add_argument("destination")
    args = parser.parse_args()
    print(f"CONTRIBUTIONS: {split_file(args.source, args.destination)}")
