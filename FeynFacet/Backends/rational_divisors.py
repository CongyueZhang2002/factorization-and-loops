"""Collect a conservative denominator product for each rational summand.

The emitted InputForm grammar writes inverses using '/'. Integer positive
powers of parenthesized rational expressions multiply their divisor counts.
Unsupported negative-power spelling is rejected, never silently truncated.
"""
import argparse
import hashlib
from collections import Counter
import json
from pathlib import Path
import re

from rational_summands import summands

POWER = re.compile(r"\^(?:\(([+]?\d+)\)|([+]?\d+))(?=$|[+*/)-])")
ATOM = re.compile(r"[A-Za-z][A-Za-z0-9]*|\d+")
TOKENS = re.compile(r"[()/]")


def term_divisors(text):
    if re.search(r"\^\(?-", text):
        raise ValueError("Negative powers must be normalized to division before order analysis.")
    # Check every power, including numerator atoms which the denominator
    # walk need not visit. A partial integer match must never undercount.
    for caret in re.finditer(r"\^", text):
        if not POWER.match(text, caret.start()):
            raise ValueError("Only complete nonnegative integer powers are supported.")
    pairs, stack = {}, []
    for match in re.finditer(r"[()]", text):
        if match[0] == "(":
            stack.append(match.start())
        else:
            if not stack:
                raise ValueError("Unbalanced rational term.")
            pairs[stack.pop()] = match.start()
    if stack:
        raise ValueError("Unbalanced rational term.")

    def power(end):
        match = POWER.match(text, end)
        if end < len(text) and text[end] == "^" and not match:
            raise ValueError("Only complete nonnegative integer powers are supported.")
        return (int(match[1] or match[2]), match.end()) if match else (1, end)

    found, weights, skip = Counter(), [1], -1
    for match in TOKENS.finditer(text):
        pos, token = match.start(), match[0]
        if pos < skip:
            continue
        if token == "(":
            exponent, end = power(pairs[pos]+1)
            weights.append(weights[-1] * exponent)
        elif token == ")":
            weights.pop()
        else:
            start = pos+1
            if start >= len(text):
                raise ValueError("Missing denominator.")
            if text[start] == "(":
                end = pairs[start]+1
            else:
                atom = ATOM.match(text, start)
                if not atom:
                    raise ValueError("Unsupported denominator atom.")
                end = atom.end()
            _, end = power(end)
            denominator = text[start:end]
            if denominator == "0":
                raise ValueError("Zero denominator.")
            if weights[-1] and not denominator.isdecimal():
                found[denominator] += weights[-1]
            skip = end
    return found


def inventory(source):
    divisors, products, count = {}, Counter(), 0
    with Path(source).open("rb") as stream:
        for raw in summands(stream):
            term = re.sub(r"\s+", "", raw.decode("ascii"))
            profile = []
            for divisor, multiplicity in term_divisors(term).items():
                index = divisors.setdefault(divisor, len(divisors)+1)
                profile.append((index, multiplicity))
            products[tuple(sorted(profile))] += 1
            count += 1
    with Path(source).open("rb") as stream:
        source_hash = hashlib.file_digest(stream, "sha256").hexdigest()
    return {"Source": str(Path(source).resolve()), "SourceSHA256": source_hash,
            "Summands": count, "Divisors": list(divisors),
            "Products": [{"Factors": list(key), "Count": number}
                         for key, number in products.items()]}


def partition_source(source, rejected_divisors, directory):
    """Partition literal summands; no algebraic cancellation is assumed.

    Terms containing a rejected denominator go to Exact.expr. Only Regular.expr
    may subsequently be proposed for a finite epsilon expansion. The original
    source and complete summand coverage are retained in the manifest.
    """
    import hashlib
    source, directory = Path(source), Path(directory)
    if source.resolve().parent == directory.resolve():
        raise ValueError("Partition outputs need a separate directory.")
    rejected = set(rejected_divisors)
    if not all(isinstance(x, str) for x in rejected):
        raise ValueError("Rejected divisors must be strings.")
    directory.mkdir(parents=True, exist_ok=True)
    paths = [directory / name for name in ("Regular.expr", "Exact.expr")]
    temporary = [x.with_suffix(".expr.partial") for x in paths]
    counts = [0, 0]
    digest = hashlib.sha256()
    try:
        with source.open("rb") as stream, temporary[0].open("wb") as regular, temporary[1].open("wb") as exact:
            for raw in summands(stream):
                term = re.sub(rb"\s+", b"", raw)
                divisors = term_divisors(term.decode("ascii"))
                group = int(bool(rejected.intersection(divisors)))
                output = (regular, exact)[group]
                if counts[group]:
                    output.write(b"+")
                output.write(term)
                counts[group] += 1
                # Length prefixes bind the original ordered literal summands.
                digest.update(len(term).to_bytes(8, "little"))
                digest.update(term)
            for group, output in enumerate((regular, exact)):
                if not counts[group]:
                    output.write(b"0")
                output.write(b"\n")
        for partial, destination in zip(temporary, paths):
            partial.replace(destination)
    finally:
        for partial in temporary:
            partial.unlink(missing_ok=True)
    return {"Source": str(source.resolve()), "Summands": sum(counts),
            "OrderedSummandsSHA256": digest.hexdigest(),
            "Method": "Exact partition of literal summands by denominator inventory",
            "RejectedDivisors": sorted(rejected),
            "Parts": {name: {"File": str(path.resolve()), "Summands": count}
                      for name, path, count in zip(("Regular", "Exact"), paths, counts)}}


def verify_partition(record):
    """Compare every original term with its claimed part, in streaming order."""
    import hashlib
    source = Path(record["Source"])
    paths = [Path(record["Parts"][name]["File"]) for name in ("Regular", "Exact")]
    rejected = set(record["RejectedDivisors"])
    counts, digest = [0, 0], hashlib.sha256()
    with source.open("rb") as original, paths[0].open("rb") as regular, paths[1].open("rb") as exact:
        streams = [iter(summands(regular)), iter(summands(exact))]
        for raw in summands(original):
            term = re.sub(rb"\s+", b"", raw)
            group = int(bool(rejected.intersection(term_divisors(term.decode("ascii")))))
            if next(streams[group], None) != term:
                raise ValueError("A partition term differs from its original source.")
            counts[group] += 1
            digest.update(len(term).to_bytes(8, "little"))
            digest.update(term)
        for group, stream in enumerate(streams):
            if counts[group] == 0 and next(stream, None) != b"0":
                raise ValueError("An empty partition must contain exact zero.")
            if next(stream, None) is not None:
                raise ValueError("A partition has extra terms.")
    if counts != [record["Parts"][name]["Summands"] for name in ("Regular", "Exact")]:
        raise ValueError("Partition summand counts differ.")
    if sum(counts) != record["Summands"] or digest.hexdigest() != record["OrderedSummandsSHA256"]:
        raise ValueError("The original ordered summand identity changed.")
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", action="store_true", help="verify a JSON partition manifest")
    parser.add_argument("--partition", metavar="REJECTED_JSON", help="partition using the rejected divisor list")
    parser.add_argument("source")
    parser.add_argument("output", nargs="?")
    args = parser.parse_args()
    if args.verify:
        records = json.loads(Path(args.source).read_text())
        if isinstance(records, dict):
            records = [records]
        for record in records:
            verify_partition(record)
        print(f"LITERAL PARTITIONS VERIFIED {len(records)}")
    elif args.partition:
        if args.output is None:
            parser.error("an output directory is required for partitioning")
        result = partition_source(args.source, json.loads(Path(args.partition).read_text()), args.output)
        verify_partition(result)
        destination = Path(args.output) / "Partition.json"
        temporary = destination.with_suffix(".json.partial")
        temporary.write_text(json.dumps(result, separators=(",", ":")) + "\n")
        temporary.replace(destination)
        regular = inventory(result["Parts"]["Regular"]["File"])
        destination = Path(args.output) / "Regular.divisors.json"
        temporary = destination.with_suffix(".json.partial")
        temporary.write_text(json.dumps(regular, separators=(",", ":")) + "\n")
        temporary.replace(destination)
        print("LITERAL PARTITION CREATED AND VERIFIED")
    else:
        if args.output is None:
            parser.error("an output path is required for the inventory")
        result = inventory(args.source)
        destination = Path(args.output)
        temporary = destination.with_name(destination.name + ".partial")
        temporary.write_text(json.dumps(result, separators=(",", ":")) + "\n")
        temporary.replace(destination)
        print(f"DIVISOR INVENTORY {result['Summands']} summands, {len(result['Divisors'])} divisors")
