#!/usr/bin/env python3
"""Evaluate a fixed CF303 p-grid at one modular prime with a bounded pool."""

from __future__ import annotations

import argparse
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
import itertools
import json
from pathlib import Path
import subprocess
import sys
import time


HERE = Path(__file__).resolve().parent
PROVIDER = HERE / "cf303_tangential_junction_point.py"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, required=True)
    parser.add_argument("--block1-deck", type=Path, required=True)
    parser.add_argument("--points-from", type=Path,
                        help="accepted interpolation JSON carrying construction_points")
    parser.add_argument("--count", type=int)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--workers", type=int, default=2, choices=range(1, 9))
    arguments = parser.parse_args()

    reference_points = []
    if arguments.points_from:
        reference = json.loads(arguments.points_from.read_text())
        reference_points = reference.get("construction_points", [])
        if any(len(point) != 2 or point[1] != 1
               for point in reference_points):
            raise RuntimeError("the reference grid must contain integral p points")
    reference_integers = [int(point[0]) for point in reference_points]
    generated_start = max(reference_integers, default=2) + 1
    candidates = itertools.chain(reference_integers,
                                 itertools.count(generated_start))
    arguments.output_directory.mkdir(parents=True, exist_ok=True)

    def admissible(p_value: int) -> bool:
        q = arguments.prime
        p = p_value % q
        if p in (0, 1):
            return False
        half = pow(2, -1, q)
        curve = (
            16*p**6 - 32*p**4 + 16*p**2 +
            (48*p**3 - 64*p**2 + 16*p)*half +
            (-8*p**4 + 16*p**3 - 24*p**2 + 16*p + 4)*half**2 +
            (-12*p + 8)*half**3 + (p**2 - 4*p + 4)*half**4
        ) % q
        if curve == 0 or pow(curve, (q - 1)//2, q) != 1:
            return False
        inverse_p = pow(p, -1, q)
        inverse_pm1 = pow(p - 1, -1, q)
        squares = (
            (4*p**4 - 8*p**3 + 4*p**2 + 1)*inverse_pm1**2 % q,
            (p - 1)*(4*p**2 + p - 1)*inverse_p**2 % q,
            p*(4*p**2 + p - 4) % q,
            p*(p - 1) % q,
        )
        return 0 not in squares and len(set(squares)) == 4

    def next_candidate() -> int:
        while True:
            candidate = next(candidates)
            if admissible(candidate):
                return candidate

    def evaluate(point: list[int]) -> tuple[int, float]:
        p_value = int(point[0])
        destination = arguments.output_directory / f"p{p_value}.json"
        if destination.is_file():
            payload = json.loads(destination.read_text())
            if (payload.get("status") == "CF303TangentialJunctionPointV1" and
                    int(payload.get("prime", 0)) == arguments.prime):
                return p_value, 0.0
        started = time.perf_counter()
        completed = subprocess.run([
            sys.executable, str(PROVIDER), "--prime", str(arguments.prime),
            "--p", str(p_value), "--block1-deck", str(arguments.block1_deck),
            "--output", str(destination),
        ], capture_output=True, text=True, check=False)
        if completed.returncode != 0:
            raise RuntimeError(
                f"p={p_value} failed ({completed.returncode}): "
                f"{completed.stdout[-1000:]} {completed.stderr[-1000:]}"
            )
        return p_value, time.perf_counter() - started

    started = time.perf_counter()
    requested_count = arguments.count or len(reference_integers)
    if requested_count < 1:
        raise RuntimeError("a positive --count is required without a reference grid")
    completed_count = 0
    failed_count = 0
    with ThreadPoolExecutor(max_workers=arguments.workers) as pool:
        futures = {pool.submit(evaluate, [next_candidate(), 1])
                   for _ in range(arguments.workers)}
        while completed_count < requested_count:
            done, futures = wait(futures, return_when=FIRST_COMPLETED)
            for future in done:
                try:
                    future.result()
                    completed_count += 1
                except RuntimeError:
                    failed_count += 1
                if completed_count < requested_count:
                    futures.add(pool.submit(evaluate, [next_candidate(), 1]))
                if (completed_count % 20 == 0 or
                        completed_count == requested_count):
                    print(f"completed={completed_count}/{requested_count} "
                          f"rejected={failed_count}", flush=True)
        for future in futures:
            future.cancel()
    print(json.dumps({
        "status": "CF303TangentialJunctionGridComplete",
        "prime": arguments.prime, "points": requested_count,
        "rejected": failed_count,
        "workers": arguments.workers,
        "seconds": time.perf_counter() - started,
        "output_directory": str(arguments.output_directory),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
