#!/usr/bin/env python3
"""Interpolate the contracted CF303 moving-boundary H Laurent germ."""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import tempfile
import time
from pathlib import Path


HERE = Path(__file__).resolve().parent
BASE_INTERPOLATOR = HERE / "cf303_tangential_junction_interpolate.py"


def load_base():
    specification = importlib.util.spec_from_file_location(
        "cf303_h_endpoint_base_interpolator", BASE_INTERPOLATOR
    )
    if specification is None or specification.loader is None:
        raise RuntimeError("CF303 interpolation backend unavailable")
    module = importlib.util.module_from_spec(specification)
    sys.modules[specification.name] = module
    specification.loader.exec_module(module)
    return module


def coordinate_keys() -> list[str]:
    return [
        f"{mode}:{order}:{target}:{power}"
        for mode in range(1, 8)
        for order in range(-3, 5)
        for target in (44, 45)
        for power in (-2, -1, 0)
    ]


def sample_values(sample: dict, keys: list[str]) -> list[int]:
    values = {
        f"{record['InheritedModeIndex']}:{record['EpsilonOrder']}:"
        f"{record['TargetMasterIntegralRow']}:"
        f"{record['NormalCoordinatePower']}": int(record["Value"])
        for record in sample["Records"]
    }
    return [values.get(key, 0) for key in keys]


def read_sample(path: Path, expected_prime: int | None = None) -> dict:
    sample = json.loads(path.read_text())
    if sample.get("Status") != (
        "CF303NormalPathGaugeAtMovingBoundaryFiniteFieldPointValidated"
    ):
        raise RuntimeError(f"unaccepted H endpoint sample: {path}")
    prime = int(sample["Prime"])
    if expected_prime is not None and prime != expected_prime:
        raise RuntimeError(f"prime mismatch in {path}")
    return sample


def numeric_point(path: Path) -> int:
    stem = path.stem
    if not stem.startswith("p") or not stem[1:].isdigit():
        raise RuntimeError(f"sample name is not p<integer>.json: {path}")
    return int(stem[1:])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample-directory", type=Path, required=True)
    parser.add_argument("--held-out", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--degree-profile", type=Path)
    parser.add_argument("--maximum-total-degree", type=int)
    parser.add_argument("--initial", type=int, default=8)
    parser.add_argument("--threads", type=int, choices=(1, 2), default=2)
    arguments = parser.parse_args()
    base = load_base()
    paths = sorted(
        (path for path in arguments.sample_directory.glob("p*.json")
         if path.resolve() != arguments.held_out.resolve()),
        key=numeric_point,
    )
    if not paths:
        raise RuntimeError("no H endpoint construction samples")
    first = read_sample(paths[0])
    prime = int(first["Prime"])
    construction = [first] + [read_sample(path, prime) for path in paths[1:]]
    held_out = read_sample(arguments.held_out, prime)
    keys = coordinate_keys()
    profile = None
    if arguments.degree_profile:
        reference = json.loads(arguments.degree_profile.read_text())
        if reference.get("status") != "HeldOutValidated":
            raise RuntimeError("degree profile is not accepted")
        reference_by_key = {
            record["key"]: record for record in reference["coordinates"]
        }
        profile = [reference_by_key[key]["degrees"] for key in keys]
    maximum_degree = (
        arguments.maximum_total_degree
        if arguments.maximum_total_degree is not None
        else len(construction) - 2
    )
    initial = arguments.initial
    if profile is not None:
        initial = max(
            initial,
            max(sum(pair) for pair in profile if pair[0] >= 0) + 1,
        )
    with tempfile.TemporaryDirectory(prefix="cf303-h-endpoint-fit-") as directory:
        input_path = Path(directory) / "input.bin"
        output_path = Path(directory) / "output.bin"
        samples = construction + [held_out]
        abscissae = [
            int(sample["TangentialPoint"][0])
            * pow(int(sample["TangentialPoint"][1]), -1, prime) % prime
            for sample in samples
        ]
        values = [sample_values(sample, keys) for sample in samples]
        adapted_samples = [
            {"p": sample["TangentialPoint"], "p_mod_prime": abscissa,
             "normal_residue_projection": [
                 {"mode_index": int(key.split(":")[0]),
                  "epsilon_order": int(key.split(":")[1]),
                  "target_master": int(key.split(":")[2]),
                  "radical_mask_bits": int(key.split(":")[3]),
                  "value": value}
                 for key, value in zip(keys, row, strict=True)
             ]}
            for sample, abscissa, row in zip(samples, abscissae, values, strict=True)
        ]
        base.write_input(
            input_path, prime, adapted_samples, keys, initial, 1,
            maximum_degree, profile,
        )
        started = time.perf_counter()
        completed = __import__("subprocess").run(
            [str(base.DEFAULT_BINARY), str(input_path), str(output_path),
             str(arguments.threads)], capture_output=True, text=True,
            check=False,
        )
        seconds = time.perf_counter() - started
        if completed.returncode != 0:
            raise RuntimeError(
                f"FLINT interpolation failed ({completed.returncode}): "
                f"{completed.stderr[-2000:]}"
            )
        result = base.read_output(output_path, keys)
    result["DataType"] = "CF303NormalPathGaugeAtMovingBoundaryFiniteFieldFit"
    result["SchemaVersion"] = 2
    result["interpolation_seconds"] = seconds
    result["construction_points"] = [
        sample["TangentialPoint"] for sample in construction
    ]
    result["held_out_point"] = held_out["TangentialPoint"]
    result["maximum_total_degree"] = maximum_degree
    arguments.output.write_text(json.dumps(result, indent=2) + "\n")
    maximum_observed = max(
        (sum(item["degrees"]) for item in result["coordinates"]
         if item["degrees"][0] >= 0), default=0
    )
    print(json.dumps({
        "status": result["status"], "prime": prime,
        "mode": result["mode"], "coordinates": len(keys),
        "max_degree": maximum_observed,
        "required_additional": result["required_additional"],
        "seconds": seconds, "output": str(arguments.output),
    }, sort_keys=True))
    return 0 if result["status"] == "HeldOutValidated" else 2


if __name__ == "__main__":
    raise SystemExit(main())
