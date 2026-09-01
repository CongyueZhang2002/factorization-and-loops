#!/usr/bin/env python3
"""Adaptive finite-field algebraic Hermite pilot for CF303 exceptions.

The provider is evaluated on both sheets of the one residual direct-u root.
The sheet pair is projected into the rational form pair

    even du + R du/Y,       R = P4 * odd_rho / Dcurve.

Each channel is reconstructed as a rational function of u from multiple local
jets.  Rational and elliptic Hermite reductions are then performed over F_q.
Additional full centers are requested only when a short independent-center
jet rejects the current reconstruction.  The block specification is isolated
from the reconstruction/reduction core so 11/14/18 can reuse the same path.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import importlib.util
import json
import os
import pickle
import struct
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Sequence


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
REPOSITORY = Path("/home/maxzhang/factorization-and-loops")
HELPER_PATH = ROOT / "Diagnostics/Scripts/cf303_modular_hermite_pilot.py"
NATIVE_PATH = ROOT / "Diagnostics/Scripts/native_path_residue_reconstruct.py"
BINARY = REPOSITORY / "FeynFacet/Backends/flint/bin/flint_deferred_path_jet"

DELTA1 = "1 - 2*x + x^2 + 2*y + 2*x*y + y^2"
DELTA2 = "1 + 2*x + x^2 - 2*y + 2*x*y + y^2"
DELTA3 = "1 - 4*x*y"


@dataclass(frozen=True)
class BlockSpec:
    block: int
    source: Path
    root_expressions: tuple[str, ...]
    path_root_indices: tuple[int, ...]
    residual_request_index: int
    dimensions: tuple[int, int, int]


SPECS = {
    1: BlockSpec(
        1,
        ROOT / (
            "Runtime/2026-08-30_cf303_25_2_exact_common_path/resume/"
            "sector_CF303_standard/CF303_25_1_input.wl"
        ),
        (DELTA2, DELTA1, DELTA3),
        (1, 0, 2),
        1,
        (2, 2, 1),
    ),
    11: BlockSpec(
        11,
        ROOT / (
            "Runtime/CF303_exception14_continuation_2026-08-30/"
            "sector_CF303_standard/CF303_25_11_input.wl"
        ),
        (DELTA2, DELTA1),
        (1, 0),
        1,
        (2, 2, 1),
    ),
    14: BlockSpec(
        14,
        ROOT / (
            "Runtime/2026-08-31_cf303_25_14_schema_current/"
            "sector_CF303_standard/CF303_25_14_input.wl"
        ),
        (DELTA1, DELTA2, DELTA3),
        (0, 1, 2),
        0,
        (2, 2, 2),
    ),
}


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def signed_path_data(native, helper, prime: int, order: int, p_value: Fraction,
                     center: Fraction, sign: int):
    data = helper.direct_u_path_data(
        native, prime, order, p_value, center, residual_root=True
    )
    if sign == 1:
        return data
    roots = list(data.roots)
    roots[0] = [(-value) % prime for value in roots[0]]
    return native.PathData(prime, order, data.x, data.y, roots, data.deltas)


def write_request(path: Path, data, epsilon: int, spec: BlockSpec) -> None:
    lines = [
        "DeferredPathJetRequestV1",
        f"prime {data.prime}",
        "variables x y eps",
        f"order {data.order}",
        f"rank {len(spec.root_expressions)}",
        *(f"root {root}" for root in spec.root_expressions),
        "epsilon_count 1",
        f"epsilon {epsilon % data.prime}",
        "x_jet " + " ".join(map(str, data.x)),
        "y_jet " + " ".join(map(str, data.y)),
    ]
    for path_index in spec.path_root_indices:
        lines.append(
            "delta_jet " + " ".join(map(str, data.deltas[path_index]))
        )
        lines.append(
            "root_jet " + " ".join(map(str, data.roots[path_index]))
        )
    path.write_text("\n".join(lines) + "\n")


def decode(path: Path, prime: int, order: int, spec: BlockSpec):
    raw = path.read_bytes()
    if raw[:8] != b"DAPJ1V1\0":
        raise RuntimeError(f"bad DAPJ magic {raw[:8]!r}")
    status = struct.unpack_from("<Q", raw, 8)[0]
    values = struct.unpack_from("<12Q", raw, 16)
    names = (
        "prime", "order", "rank", "epsilon_count", "record_count",
        "term_count", "unique_expression_count", "dimension0",
        "dimension1", "dimension2", "parse_nanoseconds",
        "evaluation_nanoseconds",
    )
    header = dict(zip(names, values, strict=True))
    dimensions = tuple(header[f"dimension{index}"] for index in range(3))
    if (
        status
        or header["prime"] != prime
        or header["order"] != order
        or header["rank"] != len(spec.root_expressions)
        or header["epsilon_count"] != 1
        or dimensions != spec.dimensions
    ):
        raise RuntimeError(f"DAPJ refusal status={status} header={header}")
    cursor = 112
    records = {}
    for _ in range(header["record_count"]):
        target = struct.unpack_from("<3Q", raw, cursor)
        cursor += 24
        records[target] = list(struct.unpack_from(f"<{order + 1}Q", raw, cursor))
        cursor += 8 * (order + 1)
    if cursor != len(raw):
        raise RuntimeError(f"trailing DAPJ bytes {len(raw) - cursor}")
    return header, records


def curve_polynomial(p_image: int, prime: int) -> list[int]:
    p = p_image % prime
    return [
        (16 * p**6 - 32 * p**4 + 16 * p**2) % prime,
        (48 * p**3 - 64 * p**2 + 16 * p) % prime,
        (-8 * p**4 + 16 * p**3 - 24 * p**2 + 16 * p + 4) % prime,
        (-12 * p + 8) % prime,
        (p**2 - 4 * p + 4) % prime,
    ]


def elliptic_identity(helper, numerator, denominator, primitive_numerator,
                      primitive_denominator, remainder_numerator,
                      remainder_denominator, curve, prime: int) -> bool:
    derivative_numerator = helper.add(
        helper.multiply(helper.derivative(primitive_numerator, prime),
                        primitive_denominator, prime),
        helper.multiply(primitive_numerator,
                        helper.derivative(primitive_denominator, prime), prime),
        prime, -1,
    )
    half = pow(2, -1, prime)
    operator_numerator = helper.add(
        helper.multiply(curve, derivative_numerator, prime),
        helper.scale(
            helper.multiply(
                helper.multiply(helper.derivative(curve, prime),
                                primitive_numerator, prime),
                primitive_denominator, prime,
            ),
            half, prime,
        ),
        prime,
    )
    primitive_denominator_square = helper.multiply(
        primitive_denominator, primitive_denominator, prime
    )
    left = helper.multiply(
        helper.multiply(numerator, primitive_denominator_square, prime),
        remainder_denominator, prime,
    )
    right_operator = helper.multiply(
        helper.multiply(operator_numerator, denominator, prime),
        remainder_denominator, prime,
    )
    right_remainder = helper.multiply(
        helper.multiply(remainder_numerator, denominator, prime),
        primitive_denominator_square, prime,
    )
    return helper.add(
        left, helper.add(right_operator, right_remainder, prime), prime, -1
    ) == [0]


def elliptic_hermite(helper, numerator: Sequence[int], denominator: Sequence[int],
                     curve: Sequence[int], prime: int) -> dict:
    numerator = helper.trim(numerator, prime)
    denominator = helper.trim(denominator, prime)
    common = helper.gcd_poly(numerator, denominator, prime)
    numerator = helper.exact_div(numerator, common, prime)
    denominator = helper.exact_div(denominator, common, prime)
    normalization = pow(denominator[-1], -1, prime)
    numerator = helper.scale(numerator, normalization, prime)
    denominator = helper.scale(denominator, normalization, prime)
    branch_gcd = helper.gcd_poly(denominator, curve, prime)
    if len(branch_gcd) > 1:
        raise ArithmeticError("branch-point pole needs a separate rule")
    repeated = helper.gcd_poly(
        denominator, helper.derivative(denominator, prime), prime
    )
    squarefree = helper.exact_div(denominator, repeated, prime)
    polynomial_part, _ = helper.divmod_poly(numerator, denominator, prime)
    polynomial_degree = -1 if polynomial_part == [0] else len(polynomial_part) - 1
    primitive_polynomial_degree = polynomial_degree - 3

    repeated_degree = len(repeated) - 1
    squarefree_degree = len(squarefree) - 1
    repeated_square = helper.multiply(repeated, repeated, prime)
    common_denominator = helper.lcm_poly(
        helper.lcm_poly(denominator, repeated_square, prime), squarefree, prime
    )
    target = helper.multiply(
        numerator, helper.exact_div(common_denominator, denominator, prime), prime
    )
    columns: list[list[int]] = []
    curve_derivative = helper.derivative(curve, prime)
    repeated_derivative = helper.derivative(repeated, prime)
    repeated_multiplier = helper.exact_div(
        common_denominator, repeated_square, prime
    )
    half = pow(2, -1, prime)
    for degree in range(repeated_degree):
        monomial = [0] * degree + [1]
        quotient_derivative_numerator = helper.add(
            helper.multiply(helper.derivative(monomial, prime), repeated, prime),
            helper.multiply(monomial, repeated_derivative, prime),
            prime, -1,
        )
        operator_numerator = helper.add(
            helper.multiply(curve, quotient_derivative_numerator, prime),
            helper.scale(
                helper.multiply(
                    helper.multiply(curve_derivative, monomial, prime),
                    repeated, prime,
                ),
                half, prime,
            ),
            prime,
        )
        columns.append(
            helper.multiply(operator_numerator, repeated_multiplier, prime)
        )
    squarefree_multiplier = helper.exact_div(
        common_denominator, squarefree, prime
    )
    for degree in range(squarefree_degree):
        columns.append(
            helper.multiply([0] * degree + [1], squarefree_multiplier, prime)
        )
    # Polynomial primitive terms.
    polynomial_primitive_count = max(0, primitive_polynomial_degree + 1)
    for degree in range(polynomial_primitive_count):
        monomial = [0] * degree + [1]
        operator = helper.add(
            helper.multiply(curve, helper.derivative(monomial, prime), prime),
            helper.scale(helper.multiply(curve_derivative, monomial, prime),
                         half, prime),
            prime,
        )
        columns.append(helper.multiply(operator, common_denominator, prime))
    # Three quartic cohomology representatives 1,u,u^2.
    for degree in range(3):
        columns.append(
            helper.multiply([0] * degree + [1], common_denominator, prime)
        )
    solution = helper.solve_linear(columns, target, prime)
    cursor = 0
    exact_numerator = helper.trim(solution[cursor:cursor + repeated_degree] or [0], prime)
    cursor += repeated_degree
    proper_remainder = helper.trim(solution[cursor:cursor + squarefree_degree] or [0], prime)
    cursor += squarefree_degree
    polynomial_primitive = helper.trim(
        solution[cursor:cursor + polynomial_primitive_count] or [0], prime
    )
    cursor += polynomial_primitive_count
    cohomology = [value % prime for value in solution[cursor:cursor + 3]]
    if len(cohomology) != 3:
        raise ArithmeticError("elliptic cohomology layout is not three-dimensional")
    primitive_numerator = helper.add(
        exact_numerator,
        helper.multiply(polynomial_primitive, repeated, prime),
        prime,
    )
    remainder_numerator = helper.add(
        proper_remainder,
        helper.multiply(cohomology, squarefree, prime),
        prime,
    )
    verified = elliptic_identity(
        helper, numerator, denominator,
        primitive_numerator, repeated,
        remainder_numerator, squarefree,
        curve, prime,
    )
    return {
        "primitive_numerator": primitive_numerator,
        "primitive_denominator": repeated,
        "remainder_numerator": remainder_numerator,
        "remainder_denominator": squarefree,
        "cohomology_coefficients": cohomology,
        "input_numerator_degree": len(numerator) - 1,
        "input_denominator_degree": len(denominator) - 1,
        "repeated_degree": repeated_degree,
        "squarefree_degree": squarefree_degree,
        "branch_gcd_degree": len(branch_gcd) - 1,
        "verified": verified,
    }


def evaluate_sheet_pair(native, helper, spec: BlockSpec, prime: int, p_value: Fraction,
                        epsilon: int, center: Fraction, order: int, threads: int,
                        cache_directory: Path | None = None,
                        sheet_workers: int = 1):
    cache_file = None
    if cache_directory is not None:
        cache_directory.mkdir(parents=True, exist_ok=True)
        cache_file = cache_directory / (
            f"block{spec.block}_q{prime}_p{p_value.numerator}d{p_value.denominator}_"
            f"e{epsilon}_c{center.numerator}d{center.denominator}_o{order}.pkl"
        )
        if cache_file.exists():
            with cache_file.open("rb") as stream:
                cached = pickle.load(stream)
            if (
                cached.get("status") == "CF303AlgebraicSheetPairCacheV2"
                and cached.get("source") == str(spec.source)
                and cached.get("source_size") == spec.source.stat().st_size
            ):
                print(f"CACHE center={center} order={order} file={cache_file}", flush=True)
                return cached["result"]
    headers = []
    records_by_sign = {}
    wall = 0.0
    stderrs = []
    def evaluate_sign(sign: int):
        data = signed_path_data(
            native, helper, prime, order, p_value, center, sign
        )
        with tempfile.TemporaryDirectory(prefix="cf303-algebraic-hermite-") as directory:
            request = Path(directory) / "request.txt"
            response = Path(directory) / "response.bin"
            write_request(request, data, epsilon, spec)
            environment = dict(os.environ)
            environment["OMP_NUM_THREADS"] = str(threads)
            started = time.perf_counter()
            process = subprocess.run(
                [str(BINARY), str(spec.source), str(request), str(response),
                 "--threads", str(threads)],
                capture_output=True, text=True, check=False, env=environment,
            )
            sheet_wall = time.perf_counter() - started
            if process.returncode:
                raise RuntimeError(f"provider failed sign={sign}: {process.stderr}")
            header, records = decode(response, prime, order, spec)
        return sign, data, header, records, process.stderr.strip(), sheet_wall

    if sheet_workers > 1:
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=min(2, sheet_workers)
        ) as executor:
            evaluated = list(executor.map(evaluate_sign, (1, -1)))
    else:
        evaluated = [evaluate_sign(sign) for sign in (1, -1)]
    for sign, data, header, records, stderr, sheet_wall in evaluated:
        headers.append(header)
        records_by_sign[sign] = (data, records)
        stderrs.append(stderr)
        wall += sheet_wall

    inverse_two = pow(2, -1, prime)
    plus_data, plus_records = records_by_sign[1]
    minus_data, minus_records = records_by_sign[-1]
    residual_path_index = spec.path_root_indices[spec.residual_request_index]
    p_mod = p_value.numerator % prime * pow(p_value.denominator % prime, -1, prime) % prime
    u_jet = [center.numerator % prime * pow(center.denominator % prime, -1, prime) % prime,
             1] + [0] * (order - 1)
    dcurve = native.jet_add(
        native.jet_constant((4 * p_mod * p_mod - 4 * p_mod) % prime, order, prime),
        native.jet_neg(native.jet_mul(u_jet, u_jet, prime), prime),
        prime,
    )
    elliptic_scale = native.jet_mul(
        dcurve, plus_data.deltas[residual_path_index][:order], prime, order
    )
    channels = {}
    for row in range(1, spec.dimensions[1] + 1):
        for column in range(1, spec.dimensions[2] + 1):
            plus = native.jet_add(
                native.jet_mul(plus_data.dx,
                               plus_records[(1, row, column)], prime, order),
                native.jet_mul(plus_data.dy,
                               plus_records[(2, row, column)], prime, order),
                prime,
            )
            minus = native.jet_add(
                native.jet_mul(minus_data.dx,
                               minus_records[(1, row, column)], prime, order),
                native.jet_mul(minus_data.dy,
                               minus_records[(2, row, column)], prime, order),
                prime,
            )
            even = [
                (left + right) * inverse_two % prime
                for left, right in zip(plus, minus)
            ]
            odd_times_rho = [
                (left - right) * inverse_two % prime
                for left, right in zip(plus, minus)
            ]
            odd_coefficient = native.jet_mul(
                odd_times_rho,
                native.jet_inv(
                    plus_data.roots[residual_path_index][:order], prime
                ),
                prime, order,
            )
            elliptic = native.jet_mul(
                odd_coefficient, elliptic_scale, prime, order
            )
            channels[(row, column, "rational")] = even
            channels[(row, column, "elliptic")] = elliptic
    result = {
        "channels": channels,
        "headers": headers,
        "wall_seconds": wall,
        "stderr": stderrs,
    }
    if cache_file is not None:
        temporary = cache_file.with_name(f".{cache_file.name}.tmp.{os.getpid()}")
        with temporary.open("wb") as stream:
            pickle.dump(
                {
                    "status": "CF303AlgebraicSheetPairCacheV2",
                    "source": str(spec.source),
                    "source_size": spec.source.stat().st_size,
                    "result": result,
                },
                stream,
                protocol=pickle.HIGHEST_PROTOCOL,
            )
        os.replace(temporary, cache_file)
        print(f"CACHED center={center} order={order} file={cache_file}", flush=True)
    return result


def schedule_seconds(durations: Sequence[float], workers: int) -> float:
    loads = [0.0] * max(1, workers)
    for duration in sorted(durations, reverse=True):
        index = min(range(len(loads)), key=loads.__getitem__)
        loads[index] += duration
    return max(loads, default=0.0)


def evaluate_center_batch(native, helper, spec: BlockSpec, prime: int,
                          p_value: Fraction, epsilon: int,
                          centers: Sequence[Fraction], order: int,
                          workers: int, core_budget: int, maximum_threads: int,
                          cache_directory: Path):
    active_jobs = max(1, 2 * len(centers))
    process_slots = min(max(1, workers), active_jobs)
    # DAPJ parallelizes over epsilon images.  The current sheet pilot has one,
    # so assigning more than one native thread would be fake parallelism.
    threads = min(maximum_threads, max(1, core_budget // process_slots), 1)
    center_workers = min(len(centers), process_slots)
    sheet_workers = max(1, min(2, process_slots // max(1, center_workers)))

    def evaluate(center: Fraction):
        return center, evaluate_sheet_pair(
            native, helper, spec, prime, p_value, epsilon, center, order,
            threads, cache_directory, sheet_workers
        )

    started = time.perf_counter()
    if center_workers > 1:
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=center_workers
        ) as executor:
            items = list(executor.map(evaluate, centers))
    else:
        items = [evaluate(center) for center in centers]
    controller_wall = time.perf_counter() - started
    results = dict(items)
    durations = [
        (header["parse_nanoseconds"] + header["evaluation_nanoseconds"]) / 1e9
        for result in results.values() for header in result["headers"]
    ]
    return results, {
        "workers": process_slots,
        "threads_per_process": threads,
        "controller_wall_seconds": controller_wall,
        "cold_parallel_estimate_seconds": schedule_seconds(durations, process_slots),
        "serial_process_seconds": sum(durations),
    }


def eligible_centers(native, helper, prime: int, p_value: Fraction,
                     count: int) -> list[Fraction]:
    candidates = [
        Fraction(value, 2) for value in
        (1, 3, -1, 5, -3, 7, -5, 9, -7, 11, -9, 13, -11)
    ] + [Fraction(value, 3) for value in (1, 2, 4, 5, 7, 8, -1, -2, -4)]
    result = []
    for center in candidates:
        try:
            helper.direct_u_path_data(
                native, prime, 2, p_value, center, residual_root=True
            )
        except (ValueError, ZeroDivisionError):
            continue
        result.append(center)
        if len(result) == count:
            return result
    raise RuntimeError("not enough split, nonsingular direct-u centers")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block", type=int, choices=tuple(SPECS), default=1)
    parser.add_argument("--prime", type=int, default=2_305_843_009_213_691_819)
    parser.add_argument("--p", type=Fraction, default=Fraction(4, 11))
    parser.add_argument("--epsilon", type=int, default=11)
    parser.add_argument("--order", type=int, default=64)
    parser.add_argument("--validation-order", type=int, default=12)
    parser.add_argument("--numerator-cap", type=int, default=60)
    parser.add_argument("--denominator-cap", type=int, default=60)
    parser.add_argument("--threads", type=int, default=2)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--core-budget", type=int, default=4)
    parser.add_argument("--maximum-centers", type=int, default=4)
    parser.add_argument("--degree-cap-step", type=int, default=4)
    parser.add_argument("--maximum-degree-cap", type=int, default=120)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    spec = SPECS[args.block]
    native = load_module("cf303_native_path", NATIVE_PATH)
    helper = load_module("cf303_modular_helper", HELPER_PATH)
    centers = eligible_centers(
        native, helper, args.prime, args.p, args.maximum_centers + 2
    )
    cache_directory = ROOT / (
        "Runtime/2026-08-31_cf303_native_dlog_residues/"
        "modular_algebraic_hermite_cache"
    )
    construction_centers = centers[:2]
    next_center_index = 2
    full_results = {}
    all_headers = []
    native_wall = 0.0
    native_stderr = []
    parallel_batches = []
    construction_batch, batch_timing = evaluate_center_batch(
        native, helper, spec, args.prime, args.p, args.epsilon,
        construction_centers, args.order, args.workers, args.core_budget,
        args.threads, cache_directory
    )
    parallel_batches.append(batch_timing)
    for center in construction_centers:
        result = construction_batch[center]
        full_results[center] = result["channels"]
        all_headers.extend(result["headers"])
        native_wall += result["wall_seconds"]
        native_stderr.extend(result["stderr"])

    reconstruction_seconds = 0.0
    attempts = []
    reconstructed = None
    validation_center = None
    validation_channels = None
    numerator_cap = args.numerator_cap
    denominator_cap = args.denominator_cap
    while True:
        started = time.perf_counter()
        candidate = {}
        reconstruction_error = None
        try:
            for row in range(1, spec.dimensions[1] + 1):
                for column in range(1, spec.dimensions[2] + 1):
                    for channel in ("rational", "elliptic"):
                        candidate[(row, column, channel)] = (
                            helper.reconstruct_multicenter(
                                [(center, full_results[center][
                                    (row, column, channel)])
                                 for center in construction_centers],
                                numerator_cap, denominator_cap, args.prime,
                            )
                        )
        except ArithmeticError as error:
            reconstruction_error = str(error)
        reconstruction_seconds += time.perf_counter() - started
        if reconstruction_error is not None:
            attempts.append({
                "construction_centers": [
                    [center.numerator, center.denominator]
                    for center in construction_centers
                ],
                "degree_caps": [numerator_cap, denominator_cap],
                "validation_center": None,
                "reconstruction_error": reconstruction_error,
                "validation": {},
                "accepted": False,
            })
            if max(numerator_cap, denominator_cap) >= args.maximum_degree_cap:
                raise RuntimeError(f"degree cap exhausted: {attempts[-1]}")
            numerator_cap = min(
                args.maximum_degree_cap, numerator_cap + args.degree_cap_step
            )
            denominator_cap = min(
                args.maximum_degree_cap, denominator_cap + args.degree_cap_step
            )
            print(
                f"GROW_CAPS numerator={numerator_cap} denominator={denominator_cap} "
                f"centers={len(construction_centers)}",
                flush=True,
            )
            continue
        if next_center_index >= len(centers):
            raise RuntimeError("eligible-center budget exhausted")
        validation_center = centers[next_center_index]
        validation_batch, batch_timing = evaluate_center_batch(
            native, helper, spec, args.prime, args.p, args.epsilon,
            [validation_center], args.validation_order, args.workers,
            args.core_budget, args.threads, cache_directory
        )
        parallel_batches.append(batch_timing)
        validation_result = validation_batch[validation_center]
        all_headers.extend(validation_result["headers"])
        native_wall += validation_result["wall_seconds"]
        native_stderr.extend(validation_result["stderr"])
        validation_channels = validation_result["channels"]
        validations = {}
        if reconstruction_error is None:
            for key, profile in candidate.items():
                validations[f"{key[0]},{key[1]},{key[2]}"] = helper.validates_at_center(
                    profile["numerator"], profile["denominator"],
                    validation_center, validation_channels[key], args.prime,
                )
        accepted = reconstruction_error is None and all(validations.values())
        attempts.append({
            "construction_centers": [
                [center.numerator, center.denominator]
                for center in construction_centers
            ],
            "validation_center": [validation_center.numerator,
                                  validation_center.denominator],
            "degree_caps": [numerator_cap, denominator_cap],
            "reconstruction_error": reconstruction_error,
            "validation": validations,
            "accepted": accepted,
        })
        if accepted:
            reconstructed = candidate
            break
        if len(construction_centers) >= args.maximum_centers:
            raise RuntimeError(f"adaptive center cap exhausted: {attempts[-1]}")
        # Promote the rejected short center to a full-order construction image.
        promotion_batch, batch_timing = evaluate_center_batch(
            native, helper, spec, args.prime, args.p, args.epsilon,
            [validation_center], args.order, args.workers, args.core_budget,
            args.threads, cache_directory
        )
        parallel_batches.append(batch_timing)
        promoted = promotion_batch[validation_center]
        full_results[validation_center] = promoted["channels"]
        construction_centers.append(validation_center)
        all_headers.extend(promoted["headers"])
        native_wall += promoted["wall_seconds"]
        native_stderr.extend(promoted["stderr"])
        next_center_index += 1

    p_mod = args.p.numerator % args.prime * pow(
        args.p.denominator % args.prime, -1, args.prime
    ) % args.prime
    curve = curve_polynomial(p_mod, args.prime)
    reduction_started = time.perf_counter()
    reductions = {}
    for key, profile in reconstructed.items():
        if key[2] == "rational":
            reduction = helper.rational_hermite(
                profile["numerator"], profile["denominator"], args.prime
            )
        else:
            reduction = elliptic_hermite(
                helper, profile["numerator"], profile["denominator"],
                curve, args.prime
            )
        if not reduction["verified"]:
            raise RuntimeError(f"Hermite identity failed for {key}")
        reductions[f"{key[0]},{key[1]},{key[2]}"] = {
            "profile": {
                name: value for name, value in profile.items()
                if name not in {"numerator", "denominator"}
            },
            "reduction": reduction,
        }
    reduction_seconds = time.perf_counter() - reduction_started
    report = {
        "status": "CF303ModularAlgebraicHermitePilotAcceptedV1",
        "block": [25, args.block],
        "source": str(spec.source),
        "prime": args.prime,
        "p": [args.p.numerator, args.p.denominator],
        "epsilon": args.epsilon,
        "full_jet_order": args.order,
        "validation_jet_order": args.validation_order,
        "degree_caps": [args.numerator_cap, args.denominator_cap],
        "accepted_degree_caps": [numerator_cap, denominator_cap],
        "attempts": attempts,
        "construction_center_count": len(construction_centers),
        "sheet_evaluations": len(all_headers),
        "fresh_center_validation": attempts[-1]["validation"],
        "timings": {
            "native_wall": native_wall,
            "native_parallel_cold_estimate": sum(
                batch["cold_parallel_estimate_seconds"]
                for batch in parallel_batches
            ),
            "controller_wall_this_run": sum(
                batch["controller_wall_seconds"] for batch in parallel_batches
            ),
            "native_parse": sum(
                header["parse_nanoseconds"] for header in all_headers
            ) / 1e9,
            "native_evaluation": sum(
                header["evaluation_nanoseconds"] for header in all_headers
            ) / 1e9,
            "rational_reconstruction": reconstruction_seconds,
            "hermite": reduction_seconds,
        },
        "parallel_batches": parallel_batches,
        "native_headers": all_headers,
        "channels": reductions,
        "native_stderr": native_stderr,
    }
    encoded = json.dumps(report, indent=2)
    print(encoded)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
