#!/usr/bin/env python3
"""Lift reduced CF303 exception data in epsilon at fixed (q,p).

Nineteen independently resumable selected-sheet scalar images are produced.
Up to four four-thread native requests are active, respecting a sixteen-core
budget.  The first seventeen epsilon values construct each scalar coefficient;
the final two are held out from interpolation and validate the lift.
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
SCALAR_SCRIPT = ROOT / (
    "Diagnostics/Scripts/cf303_scalar_modular_algebraic_hermite_pilot.py"
)
RATIONAL_PATH = ROOT / "Diagnostics/Scripts/cf303_block18_native_path_degree.py"
OUTPUT_ROOT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def image_matches(record: dict[str, Any], *, block: int, prime: int,
                  p_value: Fraction, epsilon: int, train: int,
                  heldout: int) -> bool:
    return (
        record.get("status")
        == "CF303ScalarModularAlgebraicHermitePilotAcceptedV1"
        and record.get("block") == [25, block]
        and record.get("prime") == prime
        and record.get("p") == [p_value.numerator, p_value.denominator]
        and record.get("epsilon") == epsilon
        and record.get("train_points") == train
        and record.get("heldout_points") == heldout
        and record.get("backend") == "selected"
        and record.get("parallel_mode") == "image"
    )


def run_image(*, block: int, prime: int, p_value: Fraction, epsilon: int,
              train: int, heldout: int, threads: int,
              directory: Path) -> dict[str, Any]:
    target = directory / f"block{block}_q{prime}_p{p_value.numerator}d{p_value.denominator}_e{epsilon}.json"
    if target.exists():
        cached = json.loads(target.read_text())
        if image_matches(
            cached, block=block, prime=prime, p_value=p_value,
            epsilon=epsilon, train=train, heldout=heldout,
        ):
            return {"record": cached, "path": str(target), "cached": True,
                    "subprocess_wall": 0.0}
    command = [
        sys.executable, str(SCALAR_SCRIPT),
        "--block", str(block), "--prime", str(prime),
        "--p", str(p_value), "--epsilon", str(epsilon),
        "--train", str(train), "--heldout", str(heldout),
        "--threads", str(threads), "--backend", "selected",
        "--parallel-mode", "image", "--output", str(target),
    ]
    started = time.perf_counter()
    process = subprocess.run(
        command, cwd=ROOT, capture_output=True, text=True, check=False,
    )
    wall = time.perf_counter() - started
    if process.returncode or not target.exists():
        raise RuntimeError(
            f"epsilon image {epsilon} failed ({process.returncode}):\n"
            f"{process.stderr}\n{process.stdout[-2000:]}"
        )
    record = json.loads(target.read_text())
    if not image_matches(
        record, block=block, prime=prime, p_value=p_value,
        epsilon=epsilon, train=train, heldout=heldout,
    ):
        raise RuntimeError(f"epsilon image {epsilon} output contract mismatch")
    return {"record": record, "path": str(target), "cached": False,
            "subprocess_wall": wall}


def normalized_profile(profile: dict[str, Any]) -> dict[str, Any]:
    if profile["status"] == "Zero":
        return {
            "status": "ReconstructedModPrime", "numerator": [0],
            "denominator": [1], "numerator_degree": -1,
            "denominator_degree": 0, "total_degree": 0,
        }
    return profile


def scheduled_wall(durations: list[float], workers: int) -> float:
    loads = [0.0] * workers
    for duration in sorted(durations, reverse=True):
        index = min(range(workers), key=loads.__getitem__)
        loads[index] += duration
    return max(loads, default=0.0)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block", type=int, default=1)
    parser.add_argument("--prime", type=int, default=2_305_843_009_213_691_819)
    parser.add_argument("--p", type=Fraction, default=Fraction(4, 11))
    parser.add_argument("--epsilon-start", type=int, default=7)
    parser.add_argument("--epsilon-count", type=int, default=19)
    parser.add_argument("--epsilon-heldout", type=int, default=2)
    parser.add_argument("--u-train", type=int, default=125)
    parser.add_argument("--u-heldout", type=int, default=4)
    parser.add_argument("--workers", type=int, choices=range(1, 5), default=2)
    parser.add_argument("--threads-per-request", type=int, default=4)
    parser.add_argument(
        "--output", type=Path,
        default=OUTPUT_ROOT / "cf303_block1_fixed_p_epsilon_lift.json",
    )
    args = parser.parse_args()
    if args.workers * args.threads_per_request > 16:
        raise ValueError("worker/thread allocation exceeds sixteen cores")
    if args.epsilon_count <= args.epsilon_heldout:
        raise ValueError("epsilon lift needs construction and held-out images")
    epsilon_values = list(
        range(args.epsilon_start, args.epsilon_start + args.epsilon_count)
    )
    construction_epsilons = epsilon_values[:-args.epsilon_heldout]
    heldout_epsilons = epsilon_values[-args.epsilon_heldout:]
    image_directory = args.output.parent / (
        f"block{args.block}_fixed_p_epsilon_images"
    )
    image_directory.mkdir(parents=True, exist_ok=True)

    started = time.perf_counter()
    def evaluate(epsilon: int):
        result = run_image(
            block=args.block, prime=args.prime, p_value=args.p,
            epsilon=epsilon, train=args.u_train, heldout=args.u_heldout,
            threads=args.threads_per_request, directory=image_directory,
        )
        print(
            f"EPSILON {epsilon} cached={result['cached']} "
            f"wall={result['subprocess_wall']:.3f}",
            flush=True,
        )
        return epsilon, result

    with concurrent.futures.ThreadPoolExecutor(
        max_workers=args.workers
    ) as executor:
        images = dict(executor.map(evaluate, epsilon_values))
    image_wall = time.perf_counter() - started
    records = {epsilon: images[epsilon]["record"] for epsilon in epsilon_values}

    channel_keys = sorted(records[epsilon_values[0]]["channels"])
    for epsilon in epsilon_values[1:]:
        if sorted(records[epsilon]["channels"]) != channel_keys:
            raise RuntimeError(f"channel layout changed at epsilon={epsilon}")

    # Monic u-denominators must be image-independent.  This fixes the section
    # and normalization before any epsilon coefficient is interpolated.
    denominator_fields = ("primitive_denominator", "remainder_denominator")
    stable_denominators: dict[str, dict[str, list[int]]] = {}
    coordinate_values: dict[tuple[str, str, int], list[int]] = {}
    layouts: dict[str, dict[str, int]] = {}
    for channel in channel_keys:
        reference_reduction = records[epsilon_values[0]]["channels"][channel][
            "reduction"
        ]
        stable_denominators[channel] = {}
        for field in denominator_fields:
            denominator = reference_reduction[field]
            if not denominator or denominator[-1] % args.prime != 1:
                raise RuntimeError(f"{channel}:{field} is not monic")
            for epsilon in epsilon_values[1:]:
                observed = records[epsilon]["channels"][channel]["reduction"][field]
                if observed != denominator:
                    raise RuntimeError(
                        f"{channel}:{field} changed at epsilon={epsilon}"
                    )
            stable_denominators[channel][field] = denominator
        layouts[channel] = {}
        coefficient_fields = ["primitive_numerator", "remainder_numerator"]
        if "cohomology_coefficients" in reference_reduction:
            coefficient_fields.append("cohomology_coefficients")
        for field in coefficient_fields:
            reference = reference_reduction[field]
            length = len(reference)
            if any(
                len(records[epsilon]["channels"][channel]["reduction"][field])
                != length for epsilon in epsilon_values
            ):
                raise RuntimeError(f"{channel}:{field} length changed")
            layouts[channel][field] = length
            for index in range(length):
                coordinate_values[(channel, field, index)] = [
                    records[epsilon]["channels"][channel]["reduction"][field][index]
                    for epsilon in epsilon_values
                ]

    rational = load_module("cf303_epsilon_rational", RATIONAL_PATH)
    rational.PRIME = args.prime
    lift_started = time.perf_counter()
    lifted_coordinates = []
    maximum_total_degree = 0
    for (channel, field, index), values in sorted(coordinate_values.items()):
        profile = normalized_profile(rational.reconstruct(
            construction_epsilons,
            values[:len(construction_epsilons)],
            heldout_epsilons,
            values[len(construction_epsilons):],
        ))
        if profile["status"] != "ReconstructedModPrime":
            raise RuntimeError(
                f"epsilon interpolation failed {channel}:{field}:{index}: {profile}"
            )
        maximum_total_degree = max(
            maximum_total_degree, int(profile["total_degree"])
        )
        lifted_coordinates.append({
            "channel": channel, "field": field, "index": index,
            "numerator": profile["numerator"],
            "denominator": profile["denominator"],
            "numerator_degree": profile["numerator_degree"],
            "denominator_degree": profile["denominator_degree"],
            "total_degree": profile["total_degree"],
        })
    lift_seconds = time.perf_counter() - lift_started

    image_summaries = []
    cold_durations = []
    for epsilon in epsilon_values:
        image = images[epsilon]
        record = image["record"]
        image_summaries.append({
            "epsilon": epsilon, "path": image["path"],
            "cached": image["cached"],
            "subprocess_wall": image["subprocess_wall"],
            "native_wall": record["timings"]["native_wall"],
            "interpolation": record["timings"]["rational_interpolation"],
            "hermite": record["timings"]["hermite"],
        })
        cold_durations.append(sum(
            record["timings"][field] for field in (
                "point_generation", "native_wall", "sheet_projection",
                "rational_interpolation", "hermite",
            )
        ))
    report = {
        "status": "CF303FixedPEpsilonLiftAcceptedV1",
        "claim": (
            "At fixed (q,p), monic reduced u-denominators are stable across "
            "epsilon and every reduced numerator/cohomology coefficient is "
            "rationally reconstructed from construction epsilon images with "
            "two complete held-out reduced images."
        ),
        "block": [25, args.block], "prime": args.prime,
        "p": [args.p.numerator, args.p.denominator],
        "construction_epsilons": construction_epsilons,
        "heldout_epsilons": heldout_epsilons,
        "u_train": args.u_train, "u_heldout": args.u_heldout,
        "workers": args.workers,
        "threads_per_request": args.threads_per_request,
        "maximum_active_native_threads": (
            args.workers * args.threads_per_request
        ),
        "channel_layouts": layouts,
        "stable_monic_denominators": stable_denominators,
        "lifted_coordinate_count": len(lifted_coordinates),
        "maximum_epsilon_total_degree": maximum_total_degree,
        "lifted_coordinates": lifted_coordinates,
        "heldout_reduced_image_count": len(heldout_epsilons),
        "image_summaries": image_summaries,
        "timings": {
            "epsilon_image_wall": image_wall,
            "cold_two_worker_estimate": scheduled_wall(
                cold_durations, args.workers
            ),
            "epsilon_lift": lift_seconds,
            "total": time.perf_counter() - started,
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_name(f".{args.output.name}.tmp.{os.getpid()}")
    temporary.write_text(json.dumps(report, indent=2) + "\n")
    os.replace(temporary, args.output)
    print(json.dumps({
        "status": report["status"],
        "construction_epsilons": len(construction_epsilons),
        "heldout_epsilons": len(heldout_epsilons),
        "coordinates": len(lifted_coordinates),
        "maximum_epsilon_total_degree": maximum_total_degree,
        "timings": report["timings"], "output": str(args.output),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
