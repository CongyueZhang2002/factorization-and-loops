#!/usr/bin/env python3
"""Interpolate CF303 block-1 finite-gauge corrections after cancellation.

This scratch driver runs the accepted modular recurrence at the existing
construction/held-out p points, then reconstructs the canonical u
coefficients as rational functions of p.  The output is only the rational
correction (delta H, delta K); the accepted elliptic/baseline operator stays
separate and delta H must be added to it during final assembly.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import importlib.util
import json
import multiprocessing
import os
import sys
import time
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
OUT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
PILOT = ROOT / "Diagnostics/Scripts/cf303_block1_modular_finite_gauge_pilot.py"
RATIONAL = ROOT / "Diagnostics/Scripts/cf303_block18_native_path_degree.py"
CENSUS = OUT / "cf303_block1_fixed_epsilon_p_census_fixed_replay.json"
PRIMES = (
    2_305_843_009_213_691_819,
    2_305_843_009_213_641_971,
    2_305_843_009_213_693_951,
    2_305_843_009_213_693_921,
    2_305_843_009_213_693_907,
    2_305_843_009_213_693_723,
)
FIELDS = ("h_numerator", "h_denominator", "k_numerator", "k_denominator")
STATUS = "CF303Block1ModularFiniteGaugeProfilesAcceptedV1"
_POINT_CONTEXT: dict[str, Any] | None = None
_INTERPOLATION: dict[str, Any] = {}


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def reduce_fraction(value: Fraction, prime: int) -> int:
    return value.numerator % prime * pow(
        value.denominator % prime, prime - 2, prime
    ) % prime


def run_point(point: Fraction) -> dict[str, Any]:
    if _POINT_CONTEXT is None:
        raise RuntimeError("point worker has no inherited recurrence context")
    pilot = _POINT_CONTEXT["pilot"]
    report = pilot.run_point(_POINT_CONTEXT["context"], point)
    return {"p": report["p"], "records": report["records"],
            "seconds": report["seconds"]}


def interpolate_coefficient(job: tuple[int, str, int]) -> dict[str, Any]:
    record_index, field, coefficient_index = job
    rational = _INTERPOLATION["rational"]
    values = _INTERPOLATION["values"]
    train_count = _INTERPOLATION["train_count"]
    ys = [record[record_index][field][coefficient_index] for record in values]
    profile = rational.reconstruct(
        _INTERPOLATION["xs"][:train_count], ys[:train_count],
        _INTERPOLATION["xs"][train_count:], ys[train_count:],
    )
    if profile["status"] == "Zero":
        profile = {
            "status": "ReconstructedModPrime", "numerator": [0],
            "denominator": [1], "numerator_degree": -1,
            "denominator_degree": 0, "total_degree": 0,
        }
    if profile["status"] != "ReconstructedModPrime":
        raise RuntimeError(
            f"post-gauge p reconstruction failed at {record_index}:{field}:"
            f"{coefficient_index}"
        )
    reference = values[0][record_index]
    return {
        "key": ["finite_gauge_profile", reference["order"],
                reference["row"], field, coefficient_index],
        **{name: profile[name] for name in (
            "numerator", "denominator", "numerator_degree",
            "denominator_degree", "total_degree",
        )},
    }


def build_prime(
    prime: int, workers: int, point_top: int,
    heldout_count: int, record_indices: list[int] | None,
) -> dict[str, Any]:
    global _POINT_CONTEXT, _INTERPOLATION
    pilot = load_module(f"cf303_gauge_pilot_{prime}", PILOT)
    _POINT_CONTEXT = {"pilot": pilot, "context": pilot.load_context(prime)}
    census = json.loads(CENSUS.read_text())
    if point_top == 142:
        construction = [Fraction(*point) for point in census["construction_p"]]
        heldout = [Fraction(*point) for point in census["heldout_p"]]
    else:
        points = [Fraction(value) for value in range(3, point_top + 1)
                  if value != 4]
        if len(points) <= heldout_count:
            raise ValueError("not enough p points for requested heldout tail")
        construction, heldout = points[:-heldout_count], points[-heldout_count:]
    points = construction + heldout
    started = time.perf_counter()
    fork = multiprocessing.get_context("fork")
    with concurrent.futures.ProcessPoolExecutor(
        max_workers=workers, mp_context=fork
    ) as executor:
        point_records = list(executor.map(run_point, points))
    sampling_seconds = time.perf_counter() - started

    layouts = []
    for point in point_records:
        layouts.append(tuple(
            (record["order"], record["row"],
             *(len(record[field]) for field in FIELDS))
            for record in point["records"]
        ))
    if any(layout != layouts[0] for layout in layouts[1:]):
        raise RuntimeError("canonical u layout changed across p points")

    rational = load_module(f"cf303_gauge_rational_{prime}", RATIONAL)
    rational.PRIME = prime
    _INTERPOLATION = {
        "rational": rational,
        "values": [point["records"] for point in point_records],
        "xs": [reduce_fraction(point, prime) for point in points],
        "train_count": len(construction),
    }
    selected_records = (
        list(range(len(point_records[0]["records"])))
        if record_indices is None else record_indices
    )
    jobs = [
        (record_index, field, coefficient_index)
        for record_index in selected_records
        for record in [point_records[0]["records"][record_index]]
        for field in FIELDS
        for coefficient_index in range(len(record[field]))
    ]
    interpolation_started = time.perf_counter()
    with concurrent.futures.ProcessPoolExecutor(
        max_workers=workers, mp_context=fork
    ) as executor:
        profiles = list(executor.map(interpolate_coefficient, jobs))
    interpolation_seconds = time.perf_counter() - interpolation_started
    degree_histogram: dict[str, int] = {}
    for profile in profiles:
        degree = str(profile["total_degree"])
        degree_histogram[degree] = degree_histogram.get(degree, 0) + 1
    return {
        "status": STATUS, "block": [25, 1], "prime": prime,
        "construction_p": [[point.numerator, point.denominator]
                           for point in construction],
        "heldout_p": [[point.numerator, point.denominator]
                      for point in heldout],
        "recurrence_window": [-3, 4], "demanded_h_orders": [-3, -2, -1, 0, 1, 2],
        "channel_contract": (
            "Rational deltaH/deltaK only; preserve the accepted exact "
            "elliptic/baseline operator and add deltaH during final assembly."
        ),
        "elliptic_constant_channel": "unchanged; zero in this isolated correction",
        "record_u_layout": [list(item) for item in layouts[0]],
        "profile_count": len(profiles), "profiles": profiles,
        "degree_histogram": degree_histogram,
        "maximum_total_p_degree": max(profile["total_degree"] for profile in profiles),
        "sampling_seconds": sampling_seconds,
        "sum_point_recurrence_seconds": sum(point["seconds"] for point in point_records),
        "interpolation_seconds": interpolation_seconds,
        "wall_seconds": time.perf_counter() - started,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--primes", nargs="+", type=int, default=list(PRIMES))
    parser.add_argument("--workers", type=int, choices=range(1, 9), default=8)
    parser.add_argument("--point-top", type=int, default=142)
    parser.add_argument("--heldout-count", type=int, default=8)
    parser.add_argument("--record-indices", nargs="+", type=int)
    parser.add_argument("--output-dir", type=Path,
                        default=OUT / "block1_modular_finite_gauge_profiles")
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    layouts = []
    for prime in args.primes:
        artifact = build_prime(
            prime, args.workers, args.point_top,
            args.heldout_count, args.record_indices,
        )
        path = args.output_dir / f"cf303_block1_finite_gauge_profiles_q{prime}.json"
        path.write_text(json.dumps(artifact, indent=2) + "\n")
        layout = [
            (tuple(profile["key"]), profile["numerator_degree"],
             profile["denominator_degree"], profile["total_degree"])
            for profile in artifact["profiles"]
        ]
        layouts.append(layout)
        print(
            f"q={prime} profiles={artifact['profile_count']} "
            f"max_p_degree={artifact['maximum_total_p_degree']} "
            f"sample={artifact['sampling_seconds']:.3f}s "
            f"interpolate={artifact['interpolation_seconds']:.3f}s "
            f"wall={artifact['wall_seconds']:.3f}s",
            flush=True,
        )
    common = all(layout == layouts[0] for layout in layouts[1:])
    print(f"cross_prime_layout={'COMMON' if common else 'DIFFERENT'}")
    return 0 if common else 2


if __name__ == "__main__":
    raise SystemExit(main())
