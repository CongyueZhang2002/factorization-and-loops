#!/usr/bin/env python3
"""Resumable nested (p, epsilon) lift of reduced CF303 block-1 data.

For each generic p value, the existing fixed-p epsilon lift produces 17
construction plus two held-out epsilon images under the same bounded worker
pool.  The resulting monic epsilon profiles and stable u-denominators
are flattened and lifted in p.  The first prime discovers p degrees once with
the simple reference interpolator; later primes reuse those degree pairs in a
single FFRI1 fixed-profile request with complete held-out p images.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import importlib.util
import json
import os
import subprocess
import sys
import time
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
FIXED_P_SCRIPT = ROOT / "Diagnostics/Scripts/cf303_fixed_p_epsilon_lift.py"
P_CENSUS_SCRIPT = ROOT / "Diagnostics/Scripts/cf303_fixed_epsilon_p_census.py"
RATIONAL_PATH = ROOT / "Diagnostics/Scripts/cf303_block18_native_path_degree.py"
OUTPUT_ROOT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
_DISCOVERY_RATIONAL = None


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def fraction_label(value: Fraction) -> str:
    return f"{value.numerator}d{value.denominator}"


def fixed_p_record_matches(
    record: dict[str, Any], *, block: int, prime: int, p_value: Fraction,
    epsilon_values: list[int], epsilon_heldout: int, u_train: int,
    u_heldout: int,
) -> bool:
    return (
        record.get("status") == "CF303FixedPEpsilonLiftAcceptedV1"
        and record.get("block") == [25, block]
        and record.get("prime") == prime
        and record.get("p") == [p_value.numerator, p_value.denominator]
        and record.get("construction_epsilons")
            == epsilon_values[:-epsilon_heldout]
        and record.get("heldout_epsilons")
            == epsilon_values[-epsilon_heldout:]
        and record.get("u_train") == u_train
        and record.get("u_heldout") == u_heldout
    )


def acquire_fixed_p_lift(
    *, block: int, prime: int, p_value: Fraction,
    epsilon_start: int, epsilon_count: int, epsilon_heldout: int,
    u_train: int, u_heldout: int, workers: int, threads: int,
    directory: Path,
) -> dict[str, Any]:
    target = directory / (
        f"block{block}_q{prime}_p{fraction_label(p_value)}.json"
    )
    epsilon_values = list(range(epsilon_start, epsilon_start + epsilon_count))
    if target.exists():
        cached = json.loads(target.read_text())
        if fixed_p_record_matches(
            cached, block=block, prime=prime, p_value=p_value,
            epsilon_values=epsilon_values, epsilon_heldout=epsilon_heldout,
            u_train=u_train, u_heldout=u_heldout,
        ):
            return {"record": cached, "path": str(target), "cached": True,
                    "subprocess_wall": 0.0}
    command = [
        sys.executable, str(FIXED_P_SCRIPT), "--block", str(block),
        "--prime", str(prime), "--p", str(p_value),
        "--epsilon-start", str(epsilon_start),
        "--epsilon-count", str(epsilon_count),
        "--epsilon-heldout", str(epsilon_heldout),
        "--u-train", str(u_train), "--u-heldout", str(u_heldout),
        "--workers", str(workers), "--threads-per-request", str(threads),
        "--output", str(target),
    ]
    started = time.perf_counter()
    process = subprocess.run(
        command, cwd=ROOT, capture_output=True, text=True, check=False,
    )
    wall = time.perf_counter() - started
    if process.returncode or not target.exists():
        raise RuntimeError(
            f"fixed-p epsilon lift failed at p={p_value}:\n"
            + (process.stderr + "\n" + process.stdout[-2400:])[-4800:]
        )
    record = json.loads(target.read_text())
    if not fixed_p_record_matches(
        record, block=block, prime=prime, p_value=p_value,
        epsilon_values=epsilon_values, epsilon_heldout=epsilon_heldout,
        u_train=u_train, u_heldout=u_heldout,
    ):
        raise RuntimeError(f"fixed-p output contract mismatch at p={p_value}")
    return {"record": record, "path": str(target), "cached": False,
            "subprocess_wall": wall}


def flatten_fixed_p(record: dict[str, Any]) -> dict[tuple[Any, ...], int]:
    values: dict[tuple[Any, ...], int] = {}
    for channel, fields in sorted(record["stable_monic_denominators"].items()):
        for field, coefficients in sorted(fields.items()):
            for index, coefficient in enumerate(coefficients):
                values[("u_denominator", channel, field, index)] = coefficient
    for profile in record["lifted_coordinates"]:
        base = (
            "epsilon_profile", profile["channel"], profile["field"],
            int(profile["index"]),
        )
        denominator = profile["denominator"]
        if not denominator or denominator[-1] != 1:
            raise RuntimeError(f"nonmonic epsilon denominator at {base}")
        for index, coefficient in enumerate(profile["numerator"]):
            values[base + ("numerator", index)] = coefficient
        for index, coefficient in enumerate(denominator):
            values[base + ("denominator", index)] = coefficient
    return values


def discovery_initializer(prime: int) -> None:
    global _DISCOVERY_RATIONAL
    _DISCOVERY_RATIONAL = load_module(
        f"cf303_nested_rational_{os.getpid()}", RATIONAL_PATH
    )
    _DISCOVERY_RATIONAL.PRIME = prime


def discover_one(payload):
    key, construction_x, construction_y, heldout_x, heldout_y = payload
    profile = _DISCOVERY_RATIONAL.reconstruct(
        construction_x, construction_y, heldout_x, heldout_y
    )
    if profile["status"] == "Zero":
        profile = {
            "status": "ReconstructedModPrime", "numerator": [0],
            "denominator": [1], "numerator_degree": -1,
            "denominator_degree": 0, "total_degree": 0,
        }
    return key, profile


def source_profile_map(record: dict[str, Any]) -> dict[tuple[Any, ...], tuple[int, int]]:
    return {
        tuple(profile["key"]): (
            int(profile["numerator_degree"]),
            int(profile["denominator_degree"]),
        )
        for profile in record["nested_lifted_coordinates"]
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block", type=int, default=1)
    parser.add_argument("--prime", type=int, default=2_305_843_009_213_691_819)
    parser.add_argument(
        "--p-census", type=Path,
        default=OUTPUT_ROOT / "cf303_block1_fixed_epsilon_p_census_fixed_replay.json",
    )
    parser.add_argument("--p-profile-source", type=Path)
    parser.add_argument("--epsilon-start", type=int, default=7)
    parser.add_argument("--epsilon-count", type=int, default=19)
    parser.add_argument("--epsilon-heldout", type=int, default=2)
    parser.add_argument("--u-train", type=int, default=125)
    parser.add_argument("--u-heldout", type=int, default=4)
    parser.add_argument("--workers", type=int, choices=range(1, 17), default=2)
    parser.add_argument("--threads-per-request", type=int, default=4)
    parser.add_argument("--discovery-workers", type=int, choices=range(1, 9), default=8)
    parser.add_argument("--ffri-threads", type=int, choices=range(1, 9), default=8)
    parser.add_argument("--prepare-only-p-count", type=int)
    parser.add_argument(
        "--output", type=Path,
        default=OUTPUT_ROOT / "cf303_block1_nested_p_epsilon_lift.json",
    )
    args = parser.parse_args()
    if args.workers * args.threads_per_request > 16:
        raise ValueError("native worker allocation exceeds sixteen cores")
    if args.prepare_only_p_count is not None and args.prepare_only_p_count < 1:
        raise ValueError("prepare-only p count must be positive")

    p_census = json.loads(args.p_census.read_text())
    if (
        p_census.get("status") != "CF303FixedEpsilonPDegreeCensusAcceptedV1"
        or p_census.get("block") != [25, args.block]
    ):
        raise ValueError("p-census contract mismatch")
    construction_p = [Fraction(*value) for value in p_census["construction_p"]]
    heldout_p = [Fraction(*value) for value in p_census["heldout_p"]]
    p_values = construction_p + heldout_p
    if not construction_p or not heldout_p or len(set(p_values)) != len(p_values):
        raise ValueError("invalid p partition")

    profile_source = None
    fixed_profile_map = None
    if args.p_profile_source is not None:
        profile_source = json.loads(args.p_profile_source.read_text())
        if (
            profile_source.get("status")
                != "CF303NestedPEpsilonLiftAcceptedV1"
            or profile_source.get("block") != [25, args.block]
            or profile_source.get("epsilon_values")
                != list(range(args.epsilon_start,
                              args.epsilon_start + args.epsilon_count))
        ):
            raise ValueError("nested p-profile source contract mismatch")
        fixed_profile_map = source_profile_map(profile_source)

    per_p_directory = args.output.parent / (
        f"block{args.block}_nested_p_epsilon_lifts/q{args.prime}"
    )
    per_p_directory.mkdir(parents=True, exist_ok=True)
    campaign_started = time.perf_counter()
    images: dict[Fraction, dict[str, Any]] = {}
    campaign_p_values = (
        p_values[:args.prepare_only_p_count]
        if args.prepare_only_p_count is not None else p_values
    )
    for ordinal, p_value in enumerate(campaign_p_values, 1):
        result = acquire_fixed_p_lift(
            block=args.block, prime=args.prime, p_value=p_value,
            epsilon_start=args.epsilon_start,
            epsilon_count=args.epsilon_count,
            epsilon_heldout=args.epsilon_heldout,
            u_train=args.u_train, u_heldout=args.u_heldout,
            workers=args.workers, threads=args.threads_per_request,
            directory=per_p_directory,
        )
        images[p_value] = result
        print(
            f"P_LIFT {ordinal}/{len(campaign_p_values)} p={p_value} "
            f"cached={result['cached']} wall={result['subprocess_wall']:.3f}",
            flush=True,
        )

    if args.prepare_only_p_count is not None:
        partial = {
            "status": "CF303NestedPEpsilonPreparationPartialV1",
            "block": [25, args.block], "prime": args.prime,
            "p_census": str(args.p_census),
            "prepared_p": [
                [value.numerator, value.denominator]
                for value in campaign_p_values
            ],
            "epsilon_count": args.epsilon_count,
            "records": [
                {
                    "p": [value.numerator, value.denominator],
                    "path": images[value]["path"],
                    "cached": images[value]["cached"],
                    "subprocess_wall": images[value]["subprocess_wall"],
                }
                for value in campaign_p_values
            ],
            "campaign_wall": time.perf_counter() - campaign_started,
        }
        args.output.parent.mkdir(parents=True, exist_ok=True)
        temporary = args.output.with_name(f".{args.output.name}.tmp.{os.getpid()}")
        temporary.write_text(json.dumps(partial, indent=2) + "\n")
        os.replace(temporary, args.output)
        print(json.dumps({
            "status": partial["status"],
            "prepared_p": len(campaign_p_values),
            "campaign_wall": partial["campaign_wall"],
            "output": str(args.output),
        }, sort_keys=True))
        return 0

    flattened = {
        p_value: flatten_fixed_p(images[p_value]["record"])
        for p_value in p_values
    }
    coordinate_keys = sorted(flattened[p_values[0]])
    reference_keys = set(coordinate_keys)
    layout_failures = [
        [value.numerator, value.denominator]
        for value in p_values if set(flattened[value]) != reference_keys
    ]
    if layout_failures:
        raise RuntimeError(f"nested reduced layout changed at {layout_failures[:4]}")
    if fixed_profile_map is not None and set(fixed_profile_map) != reference_keys:
        missing = sorted(reference_keys - set(fixed_profile_map))[:4]
        extra = sorted(set(fixed_profile_map) - reference_keys)[:4]
        raise RuntimeError(
            f"cross-prime nested layout mismatch: missing={missing}, extra={extra}"
        )

    p_helper = load_module("cf303_nested_p_helper", P_CENSUS_SCRIPT)
    rational = load_module("cf303_nested_rational_main", RATIONAL_PATH)
    rational.PRIME = args.prime
    construction_x = [
        p_helper.fraction_mod(value, args.prime) for value in construction_p
    ]
    heldout_x = [
        p_helper.fraction_mod(value, args.prime) for value in heldout_p
    ]
    value_rows = [
        [flattened[p_value][key] for key in coordinate_keys]
        for p_value in p_values
    ]
    lift_started = time.perf_counter()
    lifted_coordinates = []
    maximum_p_total_degree = 0
    lift_backend: dict[str, Any]
    if fixed_profile_map is None:
        payloads = [
            (
                key, construction_x,
                [flattened[value][key] for value in construction_p],
                heldout_x,
                [flattened[value][key] for value in heldout_p],
            )
            for key in coordinate_keys
        ]
        with concurrent.futures.ProcessPoolExecutor(
            max_workers=args.discovery_workers,
            initializer=discovery_initializer,
            initargs=(args.prime,),
        ) as executor:
            results = list(executor.map(discover_one, payloads, chunksize=8))
        for key, profile in results:
            if profile["status"] != "ReconstructedModPrime":
                raise RuntimeError(f"nested p discovery failed at {key}: {profile}")
            maximum_p_total_degree = max(
                maximum_p_total_degree, int(profile["total_degree"])
            )
            lifted_coordinates.append({
                "key": list(key), "numerator": profile["numerator"],
                "denominator": profile["denominator"],
                "numerator_degree": profile["numerator_degree"],
                "denominator_degree": profile["denominator_degree"],
                "total_degree": profile["total_degree"],
            })
        lift_backend = {
            "name": "PythonExtendedEuclideanDiscovery",
            "workers": args.discovery_workers,
        }
    else:
        fixed_profiles = [fixed_profile_map[key] for key in coordinate_keys]
        flint = p_helper.flint_reconstruct(
            prime=args.prime,
            abscissae=construction_x + heldout_x,
            value_rows=value_rows,
            initial_count=len(construction_p),
            heldout_count=len(heldout_p),
            maximum_total_degree=max(
                numerator + denominator if numerator >= 0 else 0
                for numerator, denominator in fixed_profiles
            ),
            threads=args.ffri_threads, fixed_profiles=fixed_profiles,
        )
        if flint["status"] != 0 or any(
            profile["status"] != 0 for profile in flint["profiles"]
        ):
            raise RuntimeError(
                f"nested fixed-profile FFRI failed: status={flint['status']} "
                f"reason={flint['reason']}"
            )
        for key, profile in zip(coordinate_keys, flint["profiles"], strict=True):
            total_degree = max(
                0, int(profile["numerator_degree"])
                + int(profile["denominator_degree"]),
            )
            maximum_p_total_degree = max(maximum_p_total_degree, total_degree)
            lifted_coordinates.append({
                "key": list(key), "numerator": profile["numerator"],
                "denominator": profile["denominator"],
                "numerator_degree": profile["numerator_degree"],
                "denominator_degree": profile["denominator_degree"],
                "total_degree": total_degree,
            })
        lift_backend = {
            name: flint[name] for name in (
                "status", "reason", "mode", "consumed",
                "construction_count", "required_additional", "threads",
                "wall", "stdout", "stderr", "binary",
            )
        }
        lift_backend["name"] = "FLINTFixedProfile"
    lift_seconds = time.perf_counter() - lift_started

    p_summaries = []
    cold_seconds = 0.0
    for value in p_values:
        image = images[value]
        record = image["record"]
        cold = float(record["timings"]["cold_two_worker_estimate"])
        cold_seconds += cold
        p_summaries.append({
            "p": [value.numerator, value.denominator],
            "partition": "construction" if value in construction_p else "heldout",
            "path": image["path"], "cached": image["cached"],
            "subprocess_wall": image["subprocess_wall"],
            "cold_two_worker_estimate": cold,
        })
    report = {
        "status": "CF303NestedPEpsilonLiftAcceptedV1",
        "claim": (
            "Every stable monic u-denominator and every coefficient of the "
            "fixed-p epsilon profiles is rationally lifted in p with complete "
            "held-out p images. The first prime discovers degree pairs once; "
            "later primes use those pairs in FFRI fixed-profile mode."
        ),
        "block": [25, args.block], "prime": args.prime,
        "p_census": str(args.p_census),
        "p_profile_source": (
            str(args.p_profile_source) if args.p_profile_source else None
        ),
        "p_profile_source_prime": (
            profile_source.get("prime") if profile_source else None
        ),
        "construction_p": [
            [value.numerator, value.denominator] for value in construction_p
        ],
        "heldout_p": [
            [value.numerator, value.denominator] for value in heldout_p
        ],
        "epsilon_values": list(
            range(args.epsilon_start, args.epsilon_start + args.epsilon_count)
        ),
        "epsilon_heldout": args.epsilon_heldout,
        "u_train": args.u_train, "u_heldout": args.u_heldout,
        "coordinate_count": len(coordinate_keys),
        "maximum_p_total_degree": maximum_p_total_degree,
        "nested_lifted_coordinates": lifted_coordinates,
        "lift_backend": lift_backend,
        "p_summaries": p_summaries,
        "maximum_active_native_threads": args.workers * args.threads_per_request,
        "timings": {
            "campaign_wall": time.perf_counter() - campaign_started,
            "cold_nested_image_estimate": cold_seconds,
            "p_lift": lift_seconds,
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_name(f".{args.output.name}.tmp.{os.getpid()}")
    temporary.write_text(json.dumps(report, indent=2) + "\n")
    os.replace(temporary, args.output)
    print(json.dumps({
        "status": report["status"], "p_images": len(p_values),
        "epsilon_images_per_p": args.epsilon_count,
        "coordinates": len(coordinate_keys),
        "maximum_p_total_degree": maximum_p_total_degree,
        "backend": lift_backend["name"], "timings": report["timings"],
        "output": str(args.output),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
