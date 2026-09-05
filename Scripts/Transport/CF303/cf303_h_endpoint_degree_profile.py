#!/usr/bin/env python3
"""Discover and validate coordinate-wise p degrees of the CF303 H germ.

Each Laurent-germ coordinate is fitted independently.  Small total-degree
bounds are tried in increasing order, and every discovered degree pair is
then replayed in fixed-profile mode using all construction images and the
explicitly reserved held-out images.  Failure to establish any one bound is
reported as a typed refusal rather than hidden behind a family-wide cap.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import tempfile
import time
from pathlib import Path

import cf303_h_endpoint_interpolate as endpoint


DEFAULT_CAPS = (12, 18, 24, 32, 42, 56, 72)


def polynomial_value(coefficients: list[int], point: int, prime: int) -> int:
    value = 0
    for coefficient in reversed(coefficients):
        value = (value * point + coefficient) % prime
    return value


def adapted_sample(sample: dict, keys: list[str],
                   additive_profile: dict[str, dict] | None = None) -> dict:
    values = endpoint.sample_values(sample, keys)
    prime = int(sample["Prime"])
    point = (
        int(sample["TangentialPoint"][0])
        * pow(int(sample["TangentialPoint"][1]), -1, prime) % prime
    )
    if additive_profile:
        for index, key in enumerate(keys):
            correction = additive_profile.get(key)
            if correction is None:
                continue
            numerator = polynomial_value(
                correction["NumeratorCoefficientsModuloPrime"], point, prime
            )
            denominator = polynomial_value(
                correction["DenominatorCoefficientsModuloPrime"], point, prime
            )
            if denominator == 0:
                raise RuntimeError(
                    f"additive profile has a pole at sample point for {key}"
                )
            values[index] = (
                values[index] + numerator * pow(denominator, -1, prime)
            ) % prime
    return {
        "p": sample["TangentialPoint"],
        "p_mod_prime": point,
        "normal_residue_projection": [
            {
                "mode_index": int(key.split(":")[0]),
                "epsilon_order": int(key.split(":")[1]),
                "target_master": int(key.split(":")[2]),
                "radical_mask_bits": int(key.split(":")[3]),
                "value": value,
            }
            for key, value in zip(keys, values, strict=True)
        ],
    }


def run_fit(base, directory: Path, prime: int, samples: list[dict], key: str,
            initial: int, held_out_count: int, cap: int,
            expected: list[list[int]] | None, threads: int) -> dict:
    input_path = directory / "input.bin"
    output_path = directory / "output.bin"
    base.write_input(
        input_path, prime, samples, [key], initial, held_out_count, cap,
        expected,
    )
    completed = subprocess.run(
        [str(base.DEFAULT_BINARY), str(input_path), str(output_path),
         str(threads)],
        capture_output=True, text=True, check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"FLINT interpolation failed ({completed.returncode}): "
            f"{completed.stderr[-2000:]}"
        )
    return base.read_output(output_path, [key])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample-directory", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--held-out-count", type=int, default=3)
    parser.add_argument("--caps", default=",".join(map(str, DEFAULT_CAPS)))
    parser.add_argument("--prior-profile", type=Path)
    parser.add_argument("--add-baseline-at-base", type=Path)
    parser.add_argument("--initial", type=int, default=8)
    parser.add_argument("--threads", type=int, choices=(1, 2), default=2)
    arguments = parser.parse_args()
    caps = tuple(int(item) for item in arguments.caps.split(",") if item)
    if not caps or any(cap < 0 for cap in caps) or tuple(sorted(set(caps))) != caps:
        raise RuntimeError("caps must be distinct nonnegative increasing integers")
    paths = sorted(
        arguments.sample_directory.glob("p*.json"),
        key=endpoint.numeric_point,
    )
    if len(paths) <= arguments.held_out_count or arguments.held_out_count < 1:
        raise RuntimeError("insufficient samples for the requested held-out set")
    first = endpoint.read_sample(paths[0])
    prime = int(first["Prime"])
    records = [first] + [endpoint.read_sample(path, prime) for path in paths[1:]]
    construction = records[:-arguments.held_out_count]
    held_out = records[-arguments.held_out_count:]
    keys = endpoint.coordinate_keys()
    additive_profile = None
    if arguments.add_baseline_at_base:
        additive = json.loads(arguments.add_baseline_at_base.read_text())
        if (additive.get("DataType") !=
                "CF303BaselinePathGaugeNormalizationValueFiniteFieldProfile"
                or additive.get("SchemaVersion") != 2
                or additive.get("Status") !=
                "CF303BaselinePathGaugeNormalizationValueFiniteFieldProfileValidated"
                or int(additive.get("Prime", -1)) != prime):
            raise RuntimeError("baseline-at-base profile is not accepted")
        additive_profile = {
            record["Key"]: record for record in additive["Coordinates"]
        }
    base = endpoint.load_base()
    started = time.perf_counter()
    prior_by_key = {}
    prior_needs_replay = False
    if arguments.prior_profile:
        prior = json.loads(arguments.prior_profile.read_text())
        if int(prior.get("prime", -1)) != prime:
            raise RuntimeError("prior profile uses a different prime")
        prior_needs_replay = (
            prior.get("construction_points") != [
                sample["TangentialPoint"] for sample in construction
            ]
            or prior.get("held_out_points") != [
                sample["TangentialPoint"] for sample in held_out
            ]
        )
        prior_by_key = {
            record["key"]: record for record in prior.get("coordinates", [])
        }
    coordinates = ([] if prior_needs_replay else list(prior_by_key.values()))
    unresolved = []
    prior_cap_counts = (prior.get("coordinates_by_discovery_cap", {})
                        if arguments.prior_profile else {})
    cap_counts = {
        int(cap): int(count) for cap, count in prior_cap_counts.items()
    }
    for cap in caps:
        cap_counts.setdefault(cap, 0)
    with tempfile.TemporaryDirectory(prefix="cf303-h-degree-profile-") as raw:
        directory = Path(raw)
        for index, key in enumerate(keys, 1):
            if key in prior_by_key and not prior_needs_replay:
                continue
            adapted = [
                adapted_sample(sample, [key], additive_profile)
                for sample in construction + held_out
            ]
            if key in prior_by_key:
                previous = prior_by_key[key]
                replay_cap = max(sum(previous["degrees"]), max(caps))
                replay = run_fit(
                    base, directory, prime, adapted, key,
                    len(construction), len(held_out), replay_cap,
                    [previous["degrees"]], arguments.threads,
                )
                if replay["status"] == "HeldOutValidated":
                    coordinates.append({
                        **replay["coordinates"][0],
                        "discovery_cap": previous["discovery_cap"],
                        "construction_image_count": len(construction),
                        "held_out_image_count": len(held_out),
                    })
                    continue
            accepted = None
            for cap in caps:
                discovery_initial = min(
                    len(construction), max(arguments.initial, cap + 2)
                )
                result = run_fit(
                    base, directory, prime, adapted, key,
                    discovery_initial, len(held_out), cap, None,
                    arguments.threads,
                )
                if result["status"] != "HeldOutValidated":
                    continue
                candidate = result["coordinates"][0]
                fixed = run_fit(
                    base, directory, prime, adapted, key,
                    len(construction), len(held_out), cap,
                    [candidate["degrees"]], arguments.threads,
                )
                if fixed["status"] != "HeldOutValidated":
                    continue
                accepted = {
                    **fixed["coordinates"][0],
                    "discovery_cap": cap,
                    "construction_image_count": len(construction),
                    "held_out_image_count": len(held_out),
                }
                cap_counts[cap] += 1
                break
            if accepted is None:
                unresolved.append(key)
            else:
                coordinates.append(accepted)
            processed = len(prior_by_key) + len(coordinates) - len(prior_by_key) + len(unresolved)
            if processed % 24 == 0 or processed == len(keys):
                print(json.dumps({
                    "Processed": processed, "Accepted": len(coordinates),
                    "Unresolved": len(unresolved),
                }), flush=True)
    unresolved = [key for key in keys
                  if key not in {record["key"] for record in coordinates}]
    coordinates = sorted(coordinates, key=lambda record: keys.index(record["key"]))
    status = ("HeldOutValidated" if not unresolved
              else "CoordinateDegreeBoundsNotEstablished")
    output = {
        "DataType": "CF303NormalPathGaugeMovingBoundaryLaurentGermDegreeProfile",
        "SchemaVersion": 2,
        "status": status,
        "prime": prime,
        "mode": "CoordinatewiseIncrementalDiscoveryAndFixedProfileReplay",
        "coordinate_count": len(keys),
        "coordinates": coordinates,
        "unresolved_coordinate_keys": unresolved,
        "caps": list(caps),
        "coordinates_by_discovery_cap": {
            str(cap): count for cap, count in cap_counts.items()
        },
        "construction_points": [sample["TangentialPoint"]
                                for sample in construction],
        "held_out_points": [sample["TangentialPoint"] for sample in held_out],
        "validation": {
            "EveryCoordinateFittedIndependently": True,
            "FixedDegreeProfileReplayedUsingAllConstructionImages": not unresolved,
            "ExplicitHeldOutImagesValidated": not unresolved,
        },
        "seconds": time.perf_counter() - started,
    }
    arguments.output.write_text(json.dumps(output, indent=2) + "\n")
    print(json.dumps({
        "Status": status, "Coordinates": len(coordinates),
        "Unresolved": len(unresolved), "Seconds": output["seconds"],
        "Output": str(arguments.output),
    }, sort_keys=True))
    return 0 if not unresolved else 2


if __name__ == "__main__":
    raise SystemExit(main())
