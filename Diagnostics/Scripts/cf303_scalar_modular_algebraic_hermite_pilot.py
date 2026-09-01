#!/usr/bin/env python3
"""Batched scalar alternative to direct-u path jets for CF303 block 1.

One DAGO1V1 call evaluates many direct-u points.  The returned rank-3 basis
coefficients are contracted on both signs of the residual Delta1 sheet, so no
second native call is needed.  Rational interpolation in u then feeds the same
finite-field rational/elliptic Hermite reducers as the jet pilot.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import struct
import subprocess
import sys
import tempfile
import time
from fractions import Fraction
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
REPOSITORY = Path("/home/maxzhang/factorization-and-loops")
ALGEBRAIC_PATH = ROOT / (
    "Diagnostics/Scripts/cf303_modular_algebraic_hermite_pilot.py"
)
RATIONAL_PATH = ROOT / "Diagnostics/Scripts/cf303_block18_native_path_degree.py"
BINARY = REPOSITORY / "FeynFacet/Backends/flint/bin/flint_deferred_ast_eval"
SELECTED_BINARY = ROOT / "Diagnostics/Scripts/deferred_ast_selected_eval"
JET_REFERENCE = ROOT / (
    "Runtime/2026-08-31_cf303_native_dlog_residues/"
    "cf303_block1_modular_algebraic_hermite_pilot.json"
)


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def inv(value: int, prime: int) -> int:
    return pow(value % prime, -1, prime)


def legendre(value: int, prime: int) -> int:
    result = pow(value % prime, (prime - 1) // 2, prime)
    return -1 if result == prime - 1 else result


def tonelli(value: int, prime: int) -> int:
    value %= prime
    if value == 0:
        return 0
    if legendre(value, prime) != 1:
        raise ValueError("nonsplit residual root")
    if prime % 4 == 3:
        return pow(value, (prime + 1) // 4, prime)
    q, shift = prime - 1, 0
    while q % 2 == 0:
        q //= 2
        shift += 1
    nonresidue = 2
    while legendre(nonresidue, prime) != -1:
        nonresidue += 1
    c = pow(nonresidue, q, prime)
    root = pow(value, (q + 1) // 2, prime)
    residue = pow(value, q, prime)
    active = shift
    while residue != 1:
        index, probe = 1, residue * residue % prime
        while probe != 1:
            probe = probe * probe % prime
            index += 1
        factor = pow(c, 1 << (active - index - 1), prime)
        root = root * factor % prime
        residue = residue * factor * factor % prime
        c = factor * factor % prime
        active = index
    return root


def direct_u_point(prime: int, p_value: Fraction, u_value: int,
                   epsilon: int):
    p = p_value.numerator % prime * inv(p_value.denominator, prime) % prime
    u = u_value % prime
    k = 4 * p * (1 - p) % prime
    denominator = (u * u + k) % prime
    if denominator == 0:
        return None
    numerator = (k - 2 * u) % prime
    a = numerator * inv(denominator, prime) % prime
    a_derivative = (
        (-2 * denominator - 2 * u * numerator) * inv(denominator, prime) ** 2
    ) % prime
    x = -a * p % prime
    y = (1 - a) * (1 - p) % prime
    dx = -a_derivative * p % prime
    dy = -a_derivative * (1 - p) % prime
    delta1 = (1 - 2*x + x*x + 2*y + 2*x*y + y*y) % prime
    delta2 = (1 + 2*x + x*x - 2*y + 2*x*y + y*y) % prime
    delta3 = (1 - 4*x*y) % prime
    if delta1 == 0 or legendre(delta1, prime) != 1:
        return None
    root1 = tonelli(delta1, prime)
    root2 = (a - p) % prime
    root3 = (1 + u * a) % prime
    if (
        root1 * root1 % prime != delta1
        or root2 * root2 % prime != delta2
        or root3 * root3 % prime != delta3
    ):
        raise AssertionError("direct-u scalar branch identity")
    dcurve = (4*p*p - 4*p - u*u) % prime
    if root1 == 0 or root2 == 0 or root3 == 0 or dcurve == 0:
        return None
    return {
        "u": u, "x": x, "y": y, "epsilon": epsilon % prime,
        "dx": dx, "dy": dy, "dcurve": dcurve,
        "path_deltas": (delta1, delta2, delta3),
        "path_roots": (root1, root2, root3),
    }


def eligible_points(prime: int, p_value: Fraction, epsilon: int, count: int):
    """Return reproducible generic path points, not small consecutive integers.

    The old ``u=2,3,...`` schedule systematically met moving divisors such as
    ``u +/- 2 p`` when the p-census used small integer p.  Those were reported
    by the native evaluator as singular *whole images* even though almost every
    other field point was regular.  A full-period affine progression keeps the
    schedule deterministic while making that coincidence generic rather than
    systematic.  The direct path/root tests below remain the acceptance gate.
    """
    p = p_value.numerator % prime * inv(p_value.denominator, prime) % prime
    seed = (prime // 7 + 104_729 * p + 13_007 * (epsilon % prime)
            + 1_000_003) % prime
    step = (prime // 11 + 1_009 * p + 9_176 * (epsilon % prime)
            + 1_000_033) % prime
    if step == 0:
        step = 1
    points = []
    offset = 0
    while len(points) < count:
        candidate = (seed + offset * step) % prime
        offset += 1
        if candidate == 0:
            continue
        image = direct_u_point(prime, p_value, candidate, epsilon)
        if image is not None:
            points.append(image)
    return points


def write_request(path: Path, points: list[dict], spec, prime: int) -> None:
    lines = [
        "DeferredASTRequestV1",
        f"prime {prime}",
        "variables x y eps",
        f"rank {len(spec.root_expressions)}",
        *(f"root {expression}" for expression in spec.root_expressions),
        f"base_count {len(points)}",
    ]
    for point in points:
        values = [point["x"], point["y"], point["epsilon"]]
        for path_index in spec.path_root_indices:
            values.extend((point["path_deltas"][path_index],
                           point["path_roots"][path_index]))
        lines.append("image " + " ".join(map(str, values)))
    path.write_text("\n".join(lines) + "\n")


def decode(path: Path, prime: int, base_count: int, spec):
    raw = path.read_bytes()
    if raw[:8] != b"DAGO1V1\0":
        raise RuntimeError(f"bad DAGO magic {raw[:8]!r}")
    fields = struct.unpack_from("<13Q", raw, 8)
    names = (
        "status", "prime", "rank", "base_count", "grade_count",
        "record_count", "term_count", "unique_expression_count",
        "dimension0", "dimension1", "dimension2",
        "parse_nanoseconds", "evaluation_nanoseconds",
    )
    header = dict(zip(names, fields, strict=True))
    dimensions = tuple(header[f"dimension{index}"] for index in range(3))
    if (
        header["status"]
        or header["prime"] != prime
        or header["rank"] != len(spec.root_expressions)
        or header["base_count"] != base_count
        or header["grade_count"] != 1 << len(spec.root_expressions)
        or dimensions != spec.dimensions
    ):
        raise RuntimeError(f"DAGO refusal {header}")
    cursor = 112
    payload_words = base_count * header["grade_count"]
    records = {}
    for _ in range(header["record_count"]):
        target = struct.unpack_from("<3Q", raw, cursor)
        cursor += 24
        records[target] = list(struct.unpack_from(f"<{payload_words}Q", raw, cursor))
        cursor += 8 * payload_words
    if cursor != len(raw):
        raise RuntimeError(f"trailing DAGO bytes {len(raw)-cursor}")
    return header, records


def selected_request_points(points: list[dict], spec, prime: int) -> list[dict]:
    residual_path_index = spec.path_root_indices[spec.residual_request_index]
    selected = []
    for point in points:
        plus = dict(point)
        plus["path_roots"] = tuple(point["path_roots"])
        minus = dict(point)
        roots = list(point["path_roots"])
        roots[residual_path_index] = -roots[residual_path_index] % prime
        minus["path_roots"] = tuple(roots)
        selected.extend((plus, minus))
    return selected


def decode_selected(path: Path, prime: int, image_count: int, spec):
    raw = path.read_bytes()
    if raw[:8] != b"DAGS1V1\0":
        raise RuntimeError(f"bad DAGS magic {raw[:8]!r}")
    fields = struct.unpack_from("<15Q", raw, 8)
    names = (
        "status", "prime", "rank", "base_count", "record_count",
        "term_count", "unique_expression_count", "dimension0",
        "dimension1", "dimension2", "parse_nanoseconds",
        "evaluation_nanoseconds", "threads", "mode", "deck_grade_count",
    )
    header = dict(zip(names, fields, strict=True))
    dimensions = tuple(header[f"dimension{index}"] for index in range(3))
    if (
        header["status"]
        or header["prime"] != prime
        or header["rank"] != len(spec.root_expressions)
        or header["base_count"] != image_count
        or dimensions != spec.dimensions
    ):
        raise RuntimeError(f"DAGS refusal {header}")
    cursor = 128
    records = {}
    for _ in range(header["record_count"]):
        target = struct.unpack_from("<3Q", raw, cursor)
        cursor += 24
        records[target] = list(struct.unpack_from(f"<{image_count}Q", raw, cursor))
        cursor += 8 * image_count
    if cursor != len(raw):
        raise RuntimeError(f"trailing DAGS bytes {len(raw)-cursor}")
    return header, records


def evaluate_grade_deck(values: list[int], base: int, roots: tuple[int, ...],
                        residual_request_index: int, sign: int,
                        grade_count: int, prime: int) -> int:
    result = 0
    for grade in range(grade_count):
        monomial = 1
        for root_index, root in enumerate(roots):
            if grade & (1 << root_index):
                monomial = monomial * (
                    -root % prime
                    if root_index == residual_request_index and sign < 0
                    else root
                ) % prime
        result = (result + values[base * grade_count + grade] * monomial) % prime
    return result


def project_channels(records, points: list[dict], spec, prime: int):
    grade_count = 1 << len(spec.root_expressions)
    inverse_two = inv(2, prime)
    channels = {
        (row, column, channel): []
        for row in range(1, spec.dimensions[1] + 1)
        for column in range(1, spec.dimensions[2] + 1)
        for channel in ("rational", "elliptic")
    }
    residual_path_index = spec.path_root_indices[spec.residual_request_index]
    for base, point in enumerate(points):
        request_roots = tuple(
            point["path_roots"][index] for index in spec.path_root_indices
        )
        for row in range(1, spec.dimensions[1] + 1):
            for column in range(1, spec.dimensions[2] + 1):
                pulled = {}
                for sign in (1, -1):
                    av = evaluate_grade_deck(
                        records[(1, row, column)], base, request_roots,
                        spec.residual_request_index, sign, grade_count, prime,
                    )
                    aw = evaluate_grade_deck(
                        records[(2, row, column)], base, request_roots,
                        spec.residual_request_index, sign, grade_count, prime,
                    )
                    pulled[sign] = (av * point["dx"] + aw * point["dy"]) % prime
                even = (pulled[1] + pulled[-1]) * inverse_two % prime
                odd_times_rho = (pulled[1] - pulled[-1]) * inverse_two % prime
                residual_root = request_roots[spec.residual_request_index]
                odd = odd_times_rho * inv(residual_root, prime) % prime
                # rho^2=Delta1=P4/Dcurve^2, hence P4/Dcurve=Dcurve*Delta1.
                elliptic = (
                    odd * point["dcurve"]
                    * point["path_deltas"][residual_path_index]
                ) % prime
                channels[(row, column, "rational")].append(even)
                channels[(row, column, "elliptic")].append(elliptic)
    return channels


def project_selected_channels(records, points: list[dict], spec, prime: int):
    inverse_two = inv(2, prime)
    channels = {
        (row, column, channel): []
        for row in range(1, spec.dimensions[1] + 1)
        for column in range(1, spec.dimensions[2] + 1)
        for channel in ("rational", "elliptic")
    }
    residual_path_index = spec.path_root_indices[spec.residual_request_index]
    for base, point in enumerate(points):
        plus_index, minus_index = 2 * base, 2 * base + 1
        for row in range(1, spec.dimensions[1] + 1):
            for column in range(1, spec.dimensions[2] + 1):
                plus = (
                    records[(1, row, column)][plus_index] * point["dx"]
                    + records[(2, row, column)][plus_index] * point["dy"]
                ) % prime
                minus = (
                    records[(1, row, column)][minus_index] * point["dx"]
                    + records[(2, row, column)][minus_index] * point["dy"]
                ) % prime
                even = (plus + minus) * inverse_two % prime
                odd_times_rho = (plus - minus) * inverse_two % prime
                residual_root = point["path_roots"][residual_path_index]
                odd = odd_times_rho * inv(residual_root, prime) % prime
                elliptic = (
                    odd * point["dcurve"]
                    * point["path_deltas"][residual_path_index]
                ) % prime
                channels[(row, column, "rational")].append(even)
                channels[(row, column, "elliptic")].append(elliptic)
    return channels


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block", type=int, default=1)
    parser.add_argument("--prime", type=int, default=2_305_843_009_213_691_819)
    parser.add_argument("--p", type=Fraction, default=Fraction(4, 11))
    parser.add_argument("--epsilon", type=int, default=11)
    parser.add_argument("--train", type=int, default=128)
    parser.add_argument("--heldout", type=int, default=8)
    parser.add_argument("--threads", type=int, choices=range(1, 9), default=4)
    parser.add_argument(
        "--backend", choices=("selected", "all-sheets"), default="selected"
    )
    parser.add_argument(
        "--parallel-mode", choices=("expression", "image"), default="image"
    )
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    algebraic = load_module("cf303_algebraic", ALGEBRAIC_PATH)
    rational = load_module("cf303_rational", RATIONAL_PATH)
    rational.PRIME = args.prime
    helper = load_module(
        "cf303_helper_scalar",
        ROOT / "Diagnostics/Scripts/cf303_modular_hermite_pilot.py",
    )
    if args.block not in algebraic.SPECS:
        raise ValueError(f"no scalar block spec for {args.block}")
    spec = algebraic.SPECS[args.block]
    started = time.perf_counter()
    points = eligible_points(
        args.prime, args.p, args.epsilon, args.train + args.heldout
    )
    point_seconds = time.perf_counter() - started
    with tempfile.TemporaryDirectory(prefix="cf303-scalar-hermite-") as directory:
        request = Path(directory) / "request.txt"
        response = Path(directory) / "response.bin"
        request_points = (
            selected_request_points(points, spec, args.prime)
            if args.backend == "selected" else points
        )
        write_request(request, request_points, spec, args.prime)
        native_started = time.perf_counter()
        if args.backend == "selected":
            command = [
                str(SELECTED_BINARY), str(spec.source), str(request),
                str(response), str(min(args.threads, 4)), args.parallel_mode,
            ]
        else:
            command = [
                str(BINARY), str(spec.source), str(request), str(response),
                "--threads", str(args.threads),
            ]
        process = subprocess.run(command, capture_output=True, text=True, check=False)
        native_wall = time.perf_counter() - native_started
        if process.returncode:
            raise RuntimeError(f"native scalar evaluator failed: {process.stderr}")
        if args.backend == "selected":
            header, records = decode_selected(
                response, args.prime, len(request_points), spec
            )
        else:
            header, records = decode(response, args.prime, len(points), spec)
    started = time.perf_counter()
    values = (
        project_selected_channels(records, points, spec, args.prime)
        if args.backend == "selected"
        else project_channels(records, points, spec, args.prime)
    )
    projection_seconds = time.perf_counter() - started
    x_values = [point["u"] for point in points]
    profiles = {}
    started = time.perf_counter()
    for key, channel_values in values.items():
        profile = rational.reconstruct(
            x_values[:args.train], channel_values[:args.train],
            x_values[args.train:], channel_values[args.train:],
        )
        if profile["status"] not in {"ReconstructedModPrime", "Zero"}:
            raise RuntimeError(f"interpolation failed {key}: {profile}")
        if profile["status"] == "Zero":
            profile = {
                "status": "ReconstructedModPrime", "numerator": [0],
                "denominator": [1], "numerator_degree": -1,
                "denominator_degree": 0, "total_degree": 0,
            }
        profiles[key] = profile
    interpolation_seconds = time.perf_counter() - started
    p_mod = args.p.numerator % args.prime * inv(args.p.denominator, args.prime) % args.prime
    curve = algebraic.curve_polynomial(p_mod, args.prime)
    reductions = {}
    started = time.perf_counter()
    for key, profile in profiles.items():
        if key[2] == "rational":
            reduction = helper.rational_hermite(
                profile["numerator"], profile["denominator"], args.prime
            )
        else:
            reduction = algebraic.elliptic_hermite(
                helper, profile["numerator"], profile["denominator"],
                curve, args.prime,
            )
        if not reduction["verified"]:
            raise RuntimeError(f"Hermite identity failed {key}")
        reductions[",".join(map(str, key))] = {
            "profile": {
                name: value for name, value in profile.items()
                if name not in {"numerator", "denominator"}
            },
            "reduction": reduction,
        }
    hermite_seconds = time.perf_counter() - started

    jet_reference_match = None
    if (
        args.block == 1
        and args.prime == 2_305_843_009_213_691_819
        and args.p == Fraction(4, 11)
        and args.epsilon == 11
        and JET_REFERENCE.exists()
    ):
        jet_reference = json.loads(JET_REFERENCE.read_text())
        reference_channels = jet_reference.get("channels", {})
        comparisons = []
        for key, scalar_record in reductions.items():
            row, column, channel = key.split(",")
            reference = reference_channels.get(key)
            if reference is None:
                reference = reference_channels.get(f"{row},{channel}")
            comparisons.append(
                reference is not None
                and reference.get("reduction") == scalar_record["reduction"]
            )
        jet_reference_match = bool(comparisons) and all(comparisons)
        if not jet_reference_match:
            raise RuntimeError("scalar reductions disagree with accepted jet pilot")

    report = {
        "status": "CF303ScalarModularAlgebraicHermitePilotAcceptedV1",
        "block": [25, args.block], "prime": args.prime,
        "p": [args.p.numerator, args.p.denominator], "epsilon": args.epsilon,
        "train_points": args.train, "heldout_points": args.heldout,
        "point_schedule": "large_affine_p_keyed_v1",
        "threads": args.threads,
        "backend": args.backend, "parallel_mode": args.parallel_mode,
        "eligible_points": len(points),
        "grade_count": header.get("grade_count", header.get("deck_grade_count")),
        "selected_physical_sheets": 2,
        "wasted_grade_fraction": (
            0 if args.backend == "selected"
            else 1 - 2 / header["grade_count"]
        ),
        "jet_reference_match": jet_reference_match,
        "native": header,
        "timings": {
            "point_generation": point_seconds,
            "native_wall": native_wall,
            "native_parse": header["parse_nanoseconds"] / 1e9,
            "native_evaluation": header["evaluation_nanoseconds"] / 1e9,
            "sheet_projection": projection_seconds,
            "rational_interpolation": interpolation_seconds,
            "hermite": hermite_seconds,
        },
        "channels": reductions,
        "native_stderr": process.stderr.strip(),
    }
    encoded = json.dumps(report, indent=2)
    print(encoded)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
