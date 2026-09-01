#!/usr/bin/env python3
"""Targeted numerator-only q3 reconstruction for CF303 block (25,1).

Exact q1/q2 p-denominators reduce the remaining q3 task to dense numerators.
For each of 84 p values, one selected-sheet request batches nine epsilon
values and 64 u values.  Known reduced u-denominators turn the rational
Hermite identity into one 64-by-64 modular system per rational channel; all
nine epsilon right-hand sides share the factorization.  The result is the q3
image of only the missing p-numerator arrays, not a full 139-by-19 image.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import importlib.util
import json
import os
import struct
import subprocess
import sys
import tempfile
import time
from collections import defaultdict
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
OUTPUT_ROOT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
CANDIDATE_SCRIPT = ROOT / (
    "Diagnostics/Scripts/cf303_nested_candidate_point_validation.py"
)
SCALAR_SCRIPT = ROOT / (
    "Diagnostics/Scripts/cf303_scalar_modular_algebraic_hermite_pilot.py"
)
SOLVER_SOURCE = ROOT / (
    "Diagnostics/Scripts/cf303_nmod_multi_rhs_solve.c"
)
SOLVER_BINARY = ROOT / (
    "Diagnostics/Artifacts/cf303_nmod_multi_rhs_solve"
)
DEFAULT_Q1 = OUTPUT_ROOT / (
    "cf303_block1_nested_p_epsilon_q2305843009213691819.json"
)
DEFAULT_Q2 = OUTPUT_ROOT / (
    "cf303_block1_nested_p_epsilon_q2305843009213641971.json"
)
RATIONAL_CHANNELS = ("1,1,rational", "2,1,rational")
NUMERATOR_FIELDS = ("primitive_numerator", "remainder_numerator")
_WORKER: dict[str, Any] = {}


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def atomic_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    os.replace(temporary, path)


def ensure_solver() -> None:
    if SOLVER_BINARY.exists() and (
        SOLVER_BINARY.stat().st_mtime >= SOLVER_SOURCE.stat().st_mtime
    ):
        return
    SOLVER_BINARY.parent.mkdir(parents=True, exist_ok=True)
    process = subprocess.run(
        [
            "cc", "-O3", "-std=c11", str(SOLVER_SOURCE),
            "-o", str(SOLVER_BINARY), "-lflint", "-lgmp", "-lmpfr",
        ],
        cwd=ROOT, capture_output=True, text=True, check=False,
    )
    if process.returncode:
        raise RuntimeError(f"cannot compile modular solver: {process.stderr}")


def inverse(value: int, prime: int) -> int:
    return pow(value % prime, prime - 2, prime)


def polynomial_value(coefficients: list[int], value: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * value + coefficient) % prime
    return result


def polynomial_derivative_value(
    coefficients: list[int], value: int, prime: int
) -> int:
    result = 0
    for degree in range(len(coefficients) - 1, 0, -1):
        result = (result * value + degree * coefficients[degree]) % prime
    return result


def interpolate(xs: list[int], ys: list[int], prime: int) -> list[int]:
    """Dense Newton interpolation, returning low-to-high coefficients."""
    count = len(xs)
    divided = [value % prime for value in ys]
    for order in range(1, count):
        for index in range(count - 1, order - 1, -1):
            divided[index] = (
                (divided[index] - divided[index - 1])
                * inverse(xs[index] - xs[index - order], prime)
            ) % prime
    polynomial = [0] * count
    basis = [1]
    for order in range(count):
        coefficient = divided[order]
        for index, value in enumerate(basis):
            polynomial[index] = (
                polynomial[index] + coefficient * value
            ) % prime
        if order + 1 < count:
            next_basis = [0] * (len(basis) + 1)
            for index, value in enumerate(basis):
                next_basis[index] = (
                    next_basis[index] - xs[order] * value
                ) % prime
                next_basis[index + 1] = (
                    next_basis[index + 1] + value
                ) % prime
            basis = next_basis
    return polynomial


def solve_multi_rhs(
    matrix: list[list[int]], right: list[list[int]], prime: int
) -> list[list[int]]:
    dimension = len(matrix)
    rhs_count = len(right[0])
    if (
        any(len(row) != dimension for row in matrix)
        or len(right) != dimension
        or any(len(row) != rhs_count for row in right)
    ):
        raise RuntimeError("modular solve shape mismatch")
    words = [
        prime, dimension, rhs_count,
        *(value for row in matrix for value in row),
        *(value for row in right for value in row),
    ]
    with tempfile.TemporaryDirectory(prefix="cf303-q3-solve-") as directory:
        request = Path(directory) / "request.bin"
        response = Path(directory) / "response.bin"
        request.write_bytes(
            b"NMSL1V1\0" + struct.pack(f"<{len(words)}Q", *words)
        )
        process = subprocess.run(
            [str(SOLVER_BINARY), str(request), str(response)],
            cwd=ROOT, capture_output=True, text=True, check=False,
        )
        if process.returncode or not response.exists():
            raise RuntimeError(
                f"modular solve failed: {process.returncode} {process.stderr}"
            )
        payload = response.read_bytes()
    if len(payload) < 40 or payload[:8] != b"NMSL1X1\0":
        raise RuntimeError("bad modular solve response")
    status, output_prime, output_n, output_rhs = struct.unpack_from(
        "<4Q", payload, 8
    )
    if (
        status or output_prime != prime or output_n != dimension
        or output_rhs != rhs_count
    ):
        raise RuntimeError("modular solve refusal")
    values = struct.unpack_from(
        f"<{dimension * rhs_count}Q", payload, 40
    )
    if len(payload) != 40 + 8 * len(values):
        raise RuntimeError("trailing modular solve payload")
    return [
        list(values[row * rhs_count:(row + 1) * rhs_count])
        for row in range(dimension)
    ]


def encode_fractions(value: Any) -> Any:
    if isinstance(value, Fraction):
        return [value.numerator, value.denominator]
    if isinstance(value, list):
        return [encode_fractions(item) for item in value]
    if isinstance(value, dict):
        return {key: encode_fractions(item) for key, item in value.items()}
    return value


def decode_fractions(value: Any) -> Any:
    if (
        isinstance(value, list) and len(value) == 2
        and all(isinstance(item, int) for item in value)
    ):
        return Fraction(value[0], value[1])
    if isinstance(value, list):
        return [decode_fractions(item) for item in value]
    if isinstance(value, dict):
        return {key: decode_fractions(item) for key, item in value.items()}
    return value


def exact_profile_value(profile, p_value: Fraction, prime: int, candidate) -> int:
    p_mod = candidate.reduce_fraction(p_value, prime)
    return candidate.evaluate_p_profile(profile, p_mod, prime)


def relevant_support_profiles(profiles: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        profile for profile in profiles
        if (
            profile["key"][0] == "u_denominator"
            or (
                profile["key"][0] == "epsilon_profile"
                and profile["key"][-2] == "denominator"
            )
        )
    ]


def target_profiles(profiles: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        profile for profile in profiles
        if (
            profile["key"][0] == "epsilon_profile"
            and profile["key"][1] in RATIONAL_CHANNELS
            and profile["key"][2] in NUMERATOR_FIELDS
            and profile["key"][-2] == "numerator"
        )
    ]


def initialize_worker(
    prime: int, epsilon_values: list[int], u_count: int, threads: int,
    encoded_support: list[dict[str, Any]],
    coordinate_lengths: dict[str, dict[str, int]],
    cache_directory: str,
) -> None:
    scalar = load_module(
        f"cf303_q3_scalar_{os.getpid()}", SCALAR_SCRIPT
    )
    algebraic = scalar.load_module(
        f"cf303_q3_algebraic_{os.getpid()}", scalar.ALGEBRAIC_PATH
    )
    candidate = load_module(
        f"cf303_q3_candidate_{os.getpid()}", CANDIDATE_SCRIPT
    )
    _WORKER.update({
        "prime": prime,
        "epsilon_values": epsilon_values,
        "u_count": u_count,
        "threads": threads,
        "support": decode_fractions(encoded_support),
        "coordinate_lengths": coordinate_lengths,
        "cache_directory": Path(cache_directory),
        "scalar": scalar,
        "spec": algebraic.SPECS[1],
        "candidate": candidate,
    })


def grouped_support_at_p(p_value: Fraction):
    prime = _WORKER["prime"]
    candidate = _WORKER["candidate"]
    u_denominators: dict[
        tuple[str, str], dict[int, int]
    ] = defaultdict(dict)
    epsilon_denominators: dict[
        tuple[str, str, int], dict[int, int]
    ] = defaultdict(dict)
    for profile in _WORKER["support"]:
        key = profile["key"]
        value = exact_profile_value(
            profile, p_value, prime, candidate
        )
        if key[0] == "u_denominator":
            _, channel, field, index = key
            u_denominators[(channel, field)][int(index)] = value
        else:
            _, channel, field, index, _, epsilon_index = key
            epsilon_denominators[
                (channel, field, int(index))
            ][int(epsilon_index)] = value
    packed_u = {}
    for key, coefficients in u_denominators.items():
        if set(coefficients) != set(range(len(coefficients))):
            raise RuntimeError(f"u denominator layout changed: {key}")
        packed_u[key] = [
            coefficients[index] for index in range(len(coefficients))
        ]
    packed_epsilon = {}
    for key, coefficients in epsilon_denominators.items():
        if set(coefficients) != set(range(len(coefficients))):
            raise RuntimeError(f"epsilon denominator layout changed: {key}")
        packed_epsilon[key] = [
            coefficients[index] for index in range(len(coefficients))
        ]
    return packed_u, packed_epsilon


def reduction_matrix(
    points: list[dict[str, int]], primitive_denominator: list[int],
    remainder_denominator: list[int], primitive_length: int,
    remainder_length: int, prime: int,
) -> list[list[int]]:
    repeated_degree = len(primitive_denominator) - 1
    if primitive_length != repeated_degree + 2:
        raise RuntimeError("primitive polynomial-part layout changed")
    matrix = []
    for point in points:
        u = point["u"]
        dp = polynomial_value(primitive_denominator, u, prime)
        dr = polynomial_value(remainder_denominator, u, prime)
        if dp == 0 or dr == 0:
            raise ZeroDivisionError("known reduced denominator vanished")
        dp_derivative = polynomial_derivative_value(
            primitive_denominator, u, prime
        )
        inverse_dp_square = inverse(dp * dp, prime)
        inverse_dr = inverse(dr, prime)
        powers = [1]
        for _ in range(max(primitive_length, remainder_length)):
            powers.append(powers[-1] * u % prime)
        row = []
        # Hermite's exact numerator has degree < deg(Dp).  Its polynomial
        # primitive has zero integration constant and is c*u here, so the
        # full reported P is E + c*u*Dp.  Solving for all coefficients of P
        # directly would leave the expected constant-of-integration kernel.
        for degree in range(repeated_degree):
            derivative_term = (
                degree * powers[degree - 1] * dp
                if degree else 0
            )
            row.append(
                (derivative_term - powers[degree] * dp_derivative)
                * inverse_dp_square % prime
            )
        row.append(1)
        row.extend(
            powers[degree] * inverse_dr % prime
            for degree in range(remainder_length)
        )
        matrix.append(row)
    return matrix


def acquire_p_image(p_value: Fraction) -> dict[str, Any]:
    prime = _WORKER["prime"]
    epsilon_values = _WORKER["epsilon_values"]
    u_count = _WORKER["u_count"]
    cache = _WORKER["cache_directory"] / (
        f"q{prime}_p{p_value.numerator}d{p_value.denominator}.json"
    )
    if cache.exists():
        record = json.loads(cache.read_text())
        if (
            record.get("status") == "CF303TargetedQ3FixedPAcceptedV1"
            and record.get("prime") == prime
            and record.get("p") == [p_value.numerator, p_value.denominator]
            and record.get("epsilon_values") == epsilon_values
            and record.get("u_count") == u_count
        ):
            record["cached"] = True
            return record

    scalar = _WORKER["scalar"]
    spec = _WORKER["spec"]
    base_points = scalar.eligible_points(
        prime, p_value, epsilon_values[0], u_count
    )
    point_groups = [
        [
            scalar.direct_u_point(
                prime, p_value, point["u"], epsilon
            )
            for point in base_points
        ]
        for epsilon in epsilon_values
    ]
    if any(point is None for group in point_groups for point in group):
        raise RuntimeError("common-u point became nongeneric across epsilon")
    values: dict[tuple[int, int, str], list[int]] = defaultdict(list)
    native_wall = 0.0
    native_parse = 0.0
    native_evaluation = 0.0
    selected_image_count = 0
    with tempfile.TemporaryDirectory(prefix="cf303-targeted-q3-") as directory:
        for batch_start in range(0, len(epsilon_values), 3):
            batch_groups = point_groups[batch_start:batch_start + 3]
            points = [point for group in batch_groups for point in group]
            request_points = scalar.selected_request_points(
                points, spec, prime
            )
            request = Path(directory) / f"request_{batch_start}.txt"
            response = Path(directory) / f"response_{batch_start}.bin"
            scalar.write_request(request, request_points, spec, prime)
            native_started = time.perf_counter()
            process = subprocess.run(
                [
                    str(scalar.SELECTED_BINARY), str(spec.source),
                    str(request), str(response),
                    str(min(_WORKER["threads"], 4)), "image",
                ],
                cwd=ROOT, capture_output=True, text=True, check=False,
            )
            native_wall += time.perf_counter() - native_started
            if process.returncode:
                raise RuntimeError(
                    f"targeted selected evaluator failed: {process.stderr}"
                )
            header, records = scalar.decode_selected(
                response, prime, len(request_points), spec
            )
            projected = scalar.project_selected_channels(
                records, points, spec, prime
            )
            for key, channel_values in projected.items():
                values[key].extend(channel_values)
            native_parse += header["parse_nanoseconds"] / 1e9
            native_evaluation += header["evaluation_nanoseconds"] / 1e9
            selected_image_count += len(request_points)
    u_denominators, epsilon_denominators = grouped_support_at_p(p_value)
    coordinate_lengths = _WORKER["coordinate_lengths"]
    reduced_by_epsilon: dict[
        tuple[str, str, int], list[int]
    ] = defaultdict(lambda: [0] * len(epsilon_values))
    solve_started = time.perf_counter()
    for channel in RATIONAL_CHANNELS:
        primitive_length = coordinate_lengths[channel]["primitive_numerator"]
        remainder_length = coordinate_lengths[channel]["remainder_numerator"]
        repeated_degree = len(
            u_denominators[(channel, "primitive_denominator")]
        ) - 1
        dimension = repeated_degree + 1 + remainder_length
        matrix = reduction_matrix(
            point_groups[0][:dimension],
            u_denominators[(channel, "primitive_denominator")],
            u_denominators[(channel, "remainder_denominator")],
            primitive_length, remainder_length, prime,
        )
        right = [
            [
                values[tuple(
                    int(part) if part.isdigit() else part
                    for part in channel.split(",")
                )][epsilon_index * u_count + row]
                for epsilon_index in range(len(epsilon_values))
            ]
            for row in range(dimension)
        ]
        solution = solve_multi_rhs(matrix, right, prime)
        for epsilon_index in range(len(epsilon_values)):
            primitive = [0] * primitive_length
            for index in range(repeated_degree):
                primitive[index] = solution[index][epsilon_index]
            polynomial_coefficient = solution[
                repeated_degree
            ][epsilon_index]
            for index, denominator_coefficient in enumerate(
                u_denominators[(channel, "primitive_denominator")]
            ):
                primitive[index + 1] = (
                    primitive[index + 1]
                    + polynomial_coefficient * denominator_coefficient
                ) % prime
            for index, value in enumerate(primitive):
                reduced_by_epsilon[
                    (channel, "primitive_numerator", index)
                ][epsilon_index] = value
            for index in range(remainder_length):
                reduced_by_epsilon[
                    (channel, "remainder_numerator", index)
                ][epsilon_index] = solution[
                    repeated_degree + 1 + index
                ][epsilon_index]
    solve_wall = time.perf_counter() - solve_started

    target_values = []
    for (channel, field, index), reduced_values in sorted(
        reduced_by_epsilon.items()
    ):
        epsilon_denominator = epsilon_denominators[
            (channel, field, index)
        ]
        numerator_values = [
            reduced * polynomial_value(
                epsilon_denominator, epsilon, prime
            ) % prime
            for reduced, epsilon in zip(
                reduced_values, epsilon_values, strict=True
            )
        ]
        epsilon_numerator = interpolate(
            epsilon_values, numerator_values, prime
        )
        for epsilon_index, value in enumerate(epsilon_numerator):
            target_values.append({
                "key": [
                    "epsilon_profile", channel, field, index,
                    "numerator", epsilon_index,
                ],
                "value": value,
            })
    record = {
        "status": "CF303TargetedQ3FixedPAcceptedV1",
        "prime": prime,
        "p": [p_value.numerator, p_value.denominator],
        "epsilon_values": epsilon_values,
        "u_count": u_count,
        "selected_sheet_images": selected_image_count,
        "target_values": target_values,
        "timings": {
            "native_wall": native_wall,
            "native_parse": native_parse,
            "native_evaluation": native_evaluation,
            "reduced_multi_rhs": solve_wall,
        },
        "cached": False,
    }
    atomic_json(cache, record)
    return record


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--q1", type=Path, default=DEFAULT_Q1)
    parser.add_argument("--q2", type=Path, default=DEFAULT_Q2)
    parser.add_argument(
        "--prime", type=int, default=2_305_843_009_213_693_951
    )
    parser.add_argument("--workers", type=int, choices=range(1, 5), default=4)
    parser.add_argument("--threads-per-request", type=int, default=4)
    parser.add_argument("--p-count", type=int, default=84)
    parser.add_argument("--u-count", type=int, default=64)
    parser.add_argument("--epsilon-start", type=int, default=7)
    parser.add_argument("--epsilon-count", type=int, default=9)
    parser.add_argument("--prepare-only-p-count", type=int)
    parser.add_argument(
        "--denominator-artifact", type=Path,
        default=OUTPUT_ROOT / "cf303_block1_exact_denominator_support.json",
    )
    parser.add_argument(
        "--output", type=Path,
        default=OUTPUT_ROOT / "cf303_block1_targeted_q3_numerators.json",
    )
    args = parser.parse_args()
    if args.workers * args.threads_per_request > 16:
        raise RuntimeError("targeted q3 allocation exceeds sixteen cores")
    if args.u_count != 64 or args.epsilon_count != 9 or args.p_count < 84:
        raise RuntimeError(
            "production contract requires 64 u, 9 epsilon, and at least 84 p"
        )
    if (
        args.prepare_only_p_count is not None
        and not 1 <= args.prepare_only_p_count <= args.p_count
    ):
        raise RuntimeError("invalid prepare-only p count")

    candidate = load_module("cf303_q3_candidate_main", CANDIDATE_SCRIPT)
    lift = candidate.load_module(
        "cf303_q3_exact_lift_main", candidate.EXACT_LIFT
    )
    analysis = candidate.load_module(
        "cf303_q3_analysis_main", candidate.ANALYSIS
    )
    q1 = lift.load_image(args.q1)
    q2 = lift.load_image(args.q2)
    lift.require_common_layout([q1, q2])
    candidates, candidate_statistics = candidate.build_candidates(
        q1, q2, lift, analysis
    )
    shared_profiles = candidates["shared_scale"]
    support = relevant_support_profiles(shared_profiles)
    targets = target_profiles(shared_profiles)
    if len(targets) != 1088:
        raise RuntimeError(f"unexpected target profile count {len(targets)}")
    if max(profile["numerator_degree"] for profile in targets) != 83:
        raise RuntimeError("target p numerator degree cap changed")
    epsilon_indices = sorted({int(profile["key"][-1]) for profile in targets})
    if epsilon_indices != list(range(9)):
        raise RuntimeError("target epsilon numerator degree cap changed")

    coordinate_lengths: dict[str, dict[str, int]] = defaultdict(dict)
    for channel in RATIONAL_CHANNELS:
        for field in NUMERATOR_FIELDS:
            indices = {
                int(profile["key"][3]) for profile in targets
                if profile["key"][1] == channel and profile["key"][2] == field
            }
            if indices != set(range(len(indices))):
                raise RuntimeError(f"target coordinate layout changed {channel}:{field}")
            coordinate_lengths[channel][field] = len(indices)
    if coordinate_lengths != {
        "1,1,rational": {
            "primitive_numerator": 41, "remainder_numerator": 23,
        },
        "2,1,rational": {
            "primitive_numerator": 39, "remainder_numerator": 23,
        },
    }:
        raise RuntimeError(f"target reduction dimensions changed: {coordinate_lengths}")

    exact_denominator_profiles = [
        {
            "key": profile["key"],
            "numerator_degree": profile["numerator_degree"],
            "denominator_degree": profile["denominator_degree"],
            "p_denominator": profile["denominator"],
        }
        for profile in shared_profiles
    ]
    denominator_artifact = {
        "status": "CF303Block1ExactDenominatorSupportV1",
        "block": [25, 1],
        "source_q_images": [int(q1["prime"]), int(q2["prime"])],
        "fresh_q3_point_evidence": str(
            OUTPUT_ROOT / "cf303_block1_two_prime_candidate_validation.json"
        ),
        "claim": (
            "Every monic p-denominator is reconstructed from the shared "
            "factor alphabet and replayed at q2. Full support profiles are "
            "included for u and epsilon denominators."
        ),
        "factor_statistics": candidate_statistics[
            "denominator_factor_statistics"
        ],
        "p_denominator_profiles": exact_denominator_profiles,
        "support_profiles": support,
    }
    atomic_json(
        args.denominator_artifact,
        encode_fractions(denominator_artifact),
    )
    ensure_solver()

    p_values = [
        Fraction(*value) for value in q1["construction_p"][:args.p_count]
    ]
    if len(p_values) != args.p_count or len(set(p_values)) != len(p_values):
        raise RuntimeError("insufficient distinct generic p values")
    epsilon_values = list(
        range(args.epsilon_start, args.epsilon_start + args.epsilon_count)
    )
    campaign_p_values = (
        p_values[:args.prepare_only_p_count]
        if args.prepare_only_p_count is not None else p_values
    )
    cache_directory = args.output.parent / (
        f"block1_targeted_q3/q{args.prime}"
    )
    cache_directory.mkdir(parents=True, exist_ok=True)
    started = time.perf_counter()
    records: dict[Fraction, dict[str, Any]] = {}
    with concurrent.futures.ProcessPoolExecutor(
        max_workers=args.workers,
        initializer=initialize_worker,
        initargs=(
            args.prime, epsilon_values, args.u_count,
            args.threads_per_request, encode_fractions(support),
            dict(coordinate_lengths), str(cache_directory),
        ),
    ) as executor:
        futures = {
            executor.submit(acquire_p_image, p_value): p_value
            for p_value in campaign_p_values
        }
        completed = 0
        for future in concurrent.futures.as_completed(futures):
            p_value = futures[future]
            record = future.result()
            records[p_value] = record
            completed += 1
            print(
                f"TARGETED_P {completed}/{len(campaign_p_values)} "
                f"p={p_value} cached={record['cached']} "
                f"native={record['timings']['native_wall']:.3f} "
                f"solve={record['timings']['reduced_multi_rhs']:.3f}",
                flush=True,
            )

    if args.prepare_only_p_count is not None:
        partial = {
            "status": "CF303TargetedQ3PreparationPartialV1",
            "prime": args.prime,
            "prepared_p": [
                [value.numerator, value.denominator]
                for value in campaign_p_values
            ],
            "wall_seconds": time.perf_counter() - started,
            "cache_directory": str(cache_directory),
        }
        atomic_json(args.output, partial)
        print(json.dumps(partial, indent=2))
        return 0

    p_mod = [
        candidate.reduce_fraction(value, args.prime) for value in p_values
    ]
    per_p_maps = {
        p_value: {
            tuple(item["key"]): int(item["value"])
            for item in records[p_value]["target_values"]
        }
        for p_value in p_values
    }
    reference_keys = set(per_p_maps[p_values[0]])
    if any(set(mapping) != reference_keys for mapping in per_p_maps.values()):
        raise RuntimeError("targeted fixed-p key layout changed")
    target_by_key = {tuple(profile["key"]): profile for profile in targets}
    if set(target_by_key) != reference_keys:
        raise RuntimeError("targeted q3 profile layout mismatch")

    reconstruction_started = time.perf_counter()
    q3_profiles = []
    for key in sorted(reference_keys):
        profile = target_by_key[key]
        degree = int(profile["numerator_degree"])
        if degree == -1:
            numerator = [0]
        else:
            sample_count = degree + 1
            numerator_values = []
            for p_value in p_values[:sample_count]:
                denominator_value = candidate.evaluate(
                    profile["denominator"],
                    candidate.reduce_fraction(p_value, args.prime),
                    args.prime,
                )
                if denominator_value == 0:
                    raise ZeroDivisionError(f"target p denominator vanished {key}")
                numerator_values.append(
                    per_p_maps[p_value][key] * denominator_value % args.prime
                )
            numerator = interpolate(
                p_mod[:sample_count], numerator_values, args.prime
            )
        q3_profiles.append({
            "key": list(key),
            "numerator": numerator,
            "denominator": [
                candidate.reduce_fraction(value, args.prime)
                for value in profile["denominator"]
            ],
            "numerator_degree": profile["numerator_degree"],
            "denominator_degree": profile["denominator_degree"],
            "total_degree": profile["total_degree"],
        })
    reconstruction_wall = time.perf_counter() - reconstruction_started
    output = {
        "status": "CF303NestedTargetedNumeratorQImageAcceptedV1",
        "block": [25, 1],
        "prime": args.prime,
        "source_q_images": [int(q1["prime"]), int(q2["prime"])],
        "denominator_artifact": str(args.denominator_artifact),
        "p_values": [
            [value.numerator, value.denominator] for value in p_values
        ],
        "epsilon_values": epsilon_values,
        "u_count": args.u_count,
        "target_profile_count": len(q3_profiles),
        "maximum_p_numerator_degree": 83,
        "maximum_epsilon_numerator_degree": 8,
        "targeted_profiles": q3_profiles,
        "timings": {
            "campaign_wall": time.perf_counter() - started,
            "p_reconstruction": reconstruction_wall,
            "sum_native_wall": sum(
                record["timings"]["native_wall"] for record in records.values()
            ),
            "sum_reduced_multi_rhs": sum(
                record["timings"]["reduced_multi_rhs"]
                for record in records.values()
            ),
        },
        "claim_boundary": (
            "q3 modular image of only the rational primitive/remainder "
            "epsilon-numerator p profiles; final exact lift still requires "
            "fresh-q4 functional replay"
        ),
    }
    atomic_json(args.output, output)
    print(json.dumps({
        "status": output["status"],
        "profiles": len(q3_profiles),
        "timings": output["timings"],
        "output": str(args.output),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
