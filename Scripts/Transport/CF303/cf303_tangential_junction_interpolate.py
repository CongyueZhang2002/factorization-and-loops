#!/usr/bin/env python3
"""Interpolate the contracted CF303 junction functions with the FLINT ABI.

The script is deliberately only an adapter: point construction stays in
``cf303_tangential_junction_point.py`` and rational lifting/CRT stays in the
Wolfram artifact builder.  Supplying a degree profile switches FLINT from its
discovery scan to the fixed-profile pass used for later primes.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import time
from typing import Any


HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parents[2]
DEFAULT_BINARY = (
    REPOSITORY / "FeynFacet/Backends/flint/bin/flint_regulator_interpolate"
)
ZERO_DEGREE = (1 << 64) - 1


def coordinate_keys() -> list[str]:
    return [f"{mode}:{order}:{target}:0"
            for mode in range(1, 8)
            for order in range(-3, 5)
            for target in (44, 45)]


def sample_values(sample: dict[str, Any], keys: list[str]) -> list[int]:
    values = {
        f"{record['mode_index']}:{record['epsilon_order']}:"
        f"{record['target_master']}:{record.get('radical_mask_bits', 0)}":
        int(record["value"])
        for record in sample["normal_residue_projection"]
    }
    return [values.get(key, 0) for key in keys]


def read_sample(path: Path, expected_prime: int | None = None
                ) -> dict[str, Any]:
    sample = json.loads(path.read_text())
    if sample.get("status") != "CF303TangentialJunctionPointV1":
        raise RuntimeError(f"unaccepted junction sample: {path}")
    prime = int(sample["prime"])
    if expected_prime is not None and prime != expected_prime:
        raise RuntimeError(f"prime mismatch in {path}")
    return sample


def numeric_point(path: Path) -> int:
    stem = path.stem
    if not stem.startswith("p") or not stem[1:].isdigit():
        raise RuntimeError(f"sample name is not p<integer>.json: {path}")
    return int(stem[1:])


def write_input(path: Path, prime: int, samples: list[dict[str, Any]],
                keys: list[str], initial: int, held_out: int,
                maximum_degree: int,
                expected: list[list[int]] | None) -> None:
    mode = int(expected is not None)
    abscissae = [int(sample["p_mod_prime"]) for sample in samples]
    values = [sample_values(sample, keys) for sample in samples]
    header = (prime, len(samples), len(keys), initial, held_out,
              maximum_degree, mode)
    with path.open("wb") as stream:
        stream.write(b"FFRI1V1\0")
        stream.write(struct.pack("<7Q", *header))
        stream.write(struct.pack(f"<{len(abscissae)}Q", *abscissae))
        flattened = [value for row in values for value in row]
        stream.write(struct.pack(f"<{len(flattened)}Q", *flattened))
        if expected is not None:
            words = [ZERO_DEGREE if degree == -1 else degree
                     for pair in expected for degree in pair]
            stream.write(struct.pack(f"<{len(words)}Q", *words))


def read_output(path: Path, keys: list[str]) -> dict[str, Any]:
    with path.open("rb") as stream:
        if stream.read(8) != b"FFRI1X1\0":
            raise RuntimeError("invalid FLINT interpolation output magic")
        header = struct.unpack("<10Q", stream.read(80))
        (prime, sample_count, coordinate_count, mode, status, reason,
         consumed, construction_count, required_additional,
         actual_threads) = header
        if coordinate_count != len(keys):
            raise RuntimeError("FLINT interpolation coordinate mismatch")
        records = []
        for key in keys:
            fields = struct.unpack("<6Q", stream.read(48))
            (coordinate_status, numerator_degree, denominator_degree,
             coordinate_consumed, numerator_count, denominator_count) = fields
            coefficients = struct.unpack(
                f"<{numerator_count + denominator_count}Q",
                stream.read(8 * (numerator_count + denominator_count)),
            )
            records.append({
                "key": key,
                "status": coordinate_status,
                "degrees": [
                    -1 if numerator_degree == ZERO_DEGREE else numerator_degree,
                    -1 if denominator_degree == ZERO_DEGREE else denominator_degree,
                ],
                "consumed": coordinate_consumed,
                "numerator": list(coefficients[:numerator_count]),
                "denominator": list(coefficients[numerator_count:]),
            })
        if stream.read(1):
            raise RuntimeError("trailing bytes in FLINT interpolation output")
    return {
        "status": ("HeldOutValidated" if status == 0 else
                   "MaximumTotalDegreeExceeded" if reason == 4 else
                   "InterpolationIncomplete"),
        "prime": prime,
        "sample_count": sample_count,
        "mode": "FixedProfile" if mode else "Discovery",
        "reason_code": reason,
        "consumed": consumed,
        "construction_count": construction_count,
        "required_additional": required_additional,
        "threads": actual_threads,
        "coordinates": records,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample-directory", type=Path, required=True)
    parser.add_argument("--held-out", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--degree-profile", type=Path)
    parser.add_argument("--maximum-total-degree", type=int)
    parser.add_argument("--initial", type=int, default=8)
    parser.add_argument("--threads", type=int, default=2, choices=range(1, 9))
    parser.add_argument("--binary", type=Path, default=DEFAULT_BINARY)
    arguments = parser.parse_args()

    paths = sorted(arguments.sample_directory.glob("p*.json"),
                   key=numeric_point)
    if not paths:
        raise RuntimeError("no junction construction samples")
    first = read_sample(paths[0])
    prime = int(first["prime"])
    construction = [first] + [read_sample(path, prime) for path in paths[1:]]
    held_out = read_sample(arguments.held_out, prime)
    keys = coordinate_keys()
    profile = None
    if arguments.degree_profile:
        reference = json.loads(arguments.degree_profile.read_text())
        if reference.get("status") != "HeldOutValidated":
            raise RuntimeError("degree profile is not accepted")
        reference_by_key = {item["key"]: item for item in reference["coordinates"]}
        profile = [reference_by_key[key]["degrees"] for key in keys]
    maximum_degree = (arguments.maximum_total_degree
                      if arguments.maximum_total_degree is not None
                      else len(construction) - 2)
    initial = arguments.initial
    if profile is not None:
        initial = max(initial, max(sum(pair) for pair in profile if pair[0] >= 0) + 1)
    with tempfile.TemporaryDirectory(prefix="cf303-junction-fit-") as directory:
        input_path = Path(directory) / "input.bin"
        output_path = Path(directory) / "output.bin"
        write_input(input_path, prime, construction + [held_out], keys,
                    initial, 1, maximum_degree, profile)
        started = time.perf_counter()
        completed = subprocess.run(
            [str(arguments.binary), str(input_path), str(output_path),
             str(arguments.threads)], capture_output=True, text=True,
            check=False,
        )
        seconds = time.perf_counter() - started
        if completed.returncode != 0:
            raise RuntimeError(
                f"FLINT interpolation failed ({completed.returncode}): "
                f"{completed.stderr[-2000:]}"
            )
        result = read_output(output_path, keys)
    result["interpolation_seconds"] = seconds
    result["construction_points"] = [sample["p"] for sample in construction]
    result["held_out_point"] = held_out["p"]
    result["maximum_total_degree"] = maximum_degree
    arguments.output.write_text(json.dumps(result, indent=2) + "\n")
    maximum_observed = max(
        (sum(item["degrees"]) for item in result["coordinates"]
         if item["degrees"][0] >= 0), default=0)
    print(json.dumps({
        "status": result["status"], "prime": prime,
        "mode": result["mode"], "coordinates": len(keys),
        "max_degree": maximum_observed, "seconds": seconds,
        "output": str(arguments.output),
    }, sort_keys=True))
    return 0 if result["status"] == "HeldOutValidated" else 2


if __name__ == "__main__":
    raise SystemExit(main())
