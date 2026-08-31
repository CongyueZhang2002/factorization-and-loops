#!/usr/bin/env python3
"""Native common-path degree census for CF303 (25,2).

The saved BlockEquationDeferredV1 input is evaluated directly on the
Kallen2Bilinear115 chart with u=3. Both radicals of this block are rational
on the path, so there is one declared selected sheet and no residual field
extension. No Wolfram kernel and no package source are used.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import struct
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
HERE = ROOT / "Diagnostics/Scripts"
SOURCE = ROOT / (
    "Runtime/CF303_exception14_continuation_2026-08-30/"
    "sector_CF303_standard/CF303_25_2_input.wl"
)
BINARY = HERE / "deferred_ast_selected_eval"
INTERPOLATION_CORE = HERE / "cf303_block18_native_path_degree.py"
ROOT_SQUARES = (
    "1 + 2*x + x^2 - 2*y + 2*x*y + y^2",
    "1 - 4*x*y",
)
EXPECTED_DIMENSIONS = (2, 2, 1)
DEFAULT_PRIME = 2_147_483_423


def load_interpolation_core():
    specification = importlib.util.spec_from_file_location(
        "cf303_block18_native_path_degree", INTERPOLATION_CORE
    )
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {INTERPOLATION_CORE}")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


def source_sha256() -> str:
    digest = hashlib.sha256()
    with SOURCE.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_source_contract() -> dict[str, Any]:
    if not SOURCE.is_file() or not BINARY.is_file():
        raise RuntimeError("saved input or selected-sheet evaluator is missing")
    text = SOURCE.read_text()
    required = (
        '"Family" -> "CF303"',
        '"Sector" -> 25',
        '"LowerSector" -> 2',
        '"RowIndices" -> {44, 45}',
        '"ColumnIndices" -> {2}',
        '"Dimensions" -> {2, 2, 1}',
        '"ABIVersion" -> "BlockEquationDeferredV1"',
    )
    missing = [item for item in required if item not in text]
    missing_roots = [root for root in ROOT_SQUARES if root not in text]
    if missing or missing_roots:
        raise RuntimeError(
            f"saved input contract mismatch missing={missing} roots={missing_roots}"
        )
    return {
        "source": str(SOURCE),
        "source_sha256": source_sha256(),
        "root_order": list(ROOT_SQUARES),
        "dimensions": list(EXPECTED_DIMENSIONS),
    }


def inverse(value: int, prime: int) -> int:
    value %= prime
    if value == 0:
        raise ZeroDivisionError("zero modular denominator")
    return pow(value, prime - 2, prime)


def chart_point(z: int, epsilon: int, prime: int) -> dict[str, int] | None:
    z %= prime
    u = 3
    k = z * (1 - z) % prime
    denominator = (u * u + 4 * k) % prime
    if denominator == 0:
        return None
    a = (4 * k - 2 * u) * inverse(denominator, prime) % prime
    a_prime = (
        4 * u * (u + 2) * (1 - 2 * z)
        * inverse(denominator, prime) ** 2
    ) % prime
    x = -a * z % prime
    y = (1 - a) * (1 - z) % prime
    dx = (-a_prime * z - a) % prime
    dy = (-a_prime * (1 - z) - (1 - a)) % prime
    delta1 = (1 + 2 * x + x * x - 2 * y + 2 * x * y + y * y) % prime
    delta3 = (1 - 4 * x * y) % prime
    root1 = (a - z) % prime
    root3 = (1 + u * a) % prime
    if root1 == 0 or root3 == 0:
        return None
    if root1 * root1 % prime != delta1:
        raise AssertionError("Kallen2 path branch does not square to Delta1")
    if root3 * root3 % prime != delta3:
        raise AssertionError("bilinear path branch does not square to Delta3")
    return {
        "z": z,
        "x": x,
        "y": y,
        "epsilon": epsilon % prime,
        "delta1": delta1,
        "root1": root1,
        "delta3": delta3,
        "root3": root3,
        "dx": dx,
        "dy": dy,
    }


def eligible_images(
    axis: str, count: int, epsilon: int, fixed_z: int, prime: int
) -> tuple[list[int], list[dict[str, int]], int, int]:
    points: list[int] = []
    images: list[dict[str, int]] = []
    rejected = 0
    if axis == "path":
        candidate = 7
        while len(images) < count:
            image = chart_point(candidate, epsilon, prime)
            if image is None:
                rejected += 1
            else:
                points.append(candidate % prime)
                images.append(image)
            candidate += 1
    else:
        candidate_z = fixed_z
        representative = chart_point(candidate_z, 7, prime)
        while representative is None:
            rejected += 1
            candidate_z += 1
            representative = chart_point(candidate_z, 7, prime)
        fixed_z = candidate_z
        for epsilon_value in range(7, 7 + count):
            image = chart_point(fixed_z, epsilon_value, prime)
            if image is None:
                raise AssertionError("epsilon-independent path point became invalid")
            points.append(epsilon_value % prime)
            images.append(image)
    return points, images, fixed_z, rejected


def write_request(path: Path, images: list[dict[str, int]], prime: int) -> None:
    lines = [
        "DeferredASTRequestV1",
        f"prime {prime}",
        "variables x y eps",
        "rank 2",
        *(f"root {root}" for root in ROOT_SQUARES),
        f"base_count {len(images)}",
    ]
    fields = (
        "x", "y", "epsilon", "delta1", "root1", "delta3", "root3"
    )
    lines.extend(
        "image " + " ".join(str(image[field]) for field in fields)
        for image in images
    )
    path.write_text("\n".join(lines) + "\n")


def decode_selected(
    path: Path, expected_images: int
) -> tuple[dict[str, int], dict[tuple[int, int, int], list[int]]]:
    payload = path.read_bytes()
    if payload[:8] != b"DAGS1V1\0":
        raise RuntimeError(f"bad selected-sheet magic {payload[:8]!r}")
    fields = struct.unpack_from("<15Q", payload, 8)
    names = (
        "status", "prime", "rank", "base_count", "record_count",
        "term_count", "unique_expression_count", "dimension0", "dimension1",
        "dimension2", "parse_nanoseconds", "evaluation_nanoseconds",
        "threads", "mode", "deck_grade_count",
    )
    header = dict(zip(names, fields, strict=True))
    if header["status"] != 0 or header["rank"] != 2:
        raise RuntimeError(f"selected-sheet refusal {header}")
    if header["base_count"] != expected_images:
        raise RuntimeError(f"selected-sheet image mismatch {header}")
    if tuple(header[f"dimension{i}"] for i in range(3)) != EXPECTED_DIMENSIONS:
        raise RuntimeError(f"selected-sheet dimension mismatch {header}")
    offset = 8 + 15 * 8
    records: dict[tuple[int, int, int], list[int]] = {}
    for _ in range(header["record_count"]):
        target = struct.unpack_from("<3Q", payload, offset)
        offset += 24
        values = list(struct.unpack_from(f"<{expected_images}Q", payload, offset))
        offset += 8 * expected_images
        records[target] = values
    if offset != len(payload):
        raise RuntimeError(f"selected-sheet trailing bytes {len(payload)-offset}")
    return header, records


def contract(
    records: dict[tuple[int, int, int], list[int]],
    images: list[dict[str, int]], prime: int,
) -> dict[tuple[int, int], list[int]]:
    expected = {(mu, row, 1) for mu in (1, 2) for row in (1, 2)}
    if set(records) != expected:
        raise RuntimeError(f"record targets {sorted(records)} != {sorted(expected)}")
    return {
        (row, 1): [
            (
                records[(1, row, 1)][index] * image["dx"]
                + records[(2, row, 1)][index] * image["dy"]
            ) % prime
            for index, image in enumerate(images)
        ]
        for row in (1, 2)
    }


def run_native(
    images: list[dict[str, int]], prime: int, cpus: str, threads: int,
) -> tuple[dict[str, int], dict[tuple[int, int, int], list[int]], str, float, int]:
    if threads < 1 or threads > 4:
        raise ValueError("native thread count must be 1..4")
    with tempfile.TemporaryDirectory(prefix="cf303-25-2-path-") as directory:
        request = Path(directory) / "request.txt"
        output = Path(directory) / "output.bin"
        write_request(request, images, prime)
        started = time.perf_counter()
        process = subprocess.run(
            [
                "/usr/bin/time", "-f", "MAX_RSS_KB=%M", "taskset", "-c",
                cpus, str(BINARY), str(SOURCE), str(request), str(output),
                str(threads), "expression",
            ],
            text=True, capture_output=True, check=False,
        )
        seconds = time.perf_counter() - started
        if process.returncode:
            raise RuntimeError(
                f"selected evaluator exit {process.returncode}:\n{process.stderr}"
            )
        header, records = decode_selected(output, len(images))
    maximum_rss_kb = 0
    for line in process.stderr.splitlines():
        if line.startswith("MAX_RSS_KB="):
            maximum_rss_kb = int(line.split("=", 1)[1])
    return header, records, process.stderr.strip(), seconds, maximum_rss_kb


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=DEFAULT_PRIME)
    parser.add_argument("--axis", choices=("path", "epsilon"), default="path")
    parser.add_argument("--train", type=int, default=224)
    parser.add_argument("--heldout", type=int, default=48)
    parser.add_argument("--epsilon", type=int, default=11)
    parser.add_argument("--fixed-z", type=int, default=27)
    parser.add_argument("--cpus", default="4-7")
    parser.add_argument("--threads", type=int, choices=range(1, 5), default=4)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    contract_record = verify_source_contract()
    points, images, fixed_z, rejected = eligible_images(
        args.axis, args.train + args.heldout, args.epsilon,
        args.fixed_z, args.prime,
    )
    header, records, stderr, native_seconds, maximum_rss_kb = run_native(
        images, args.prime, args.cpus, args.threads
    )
    started = time.perf_counter()
    contracted = contract(records, images, args.prime)
    core = load_interpolation_core()
    core.PRIME = args.prime
    entries: dict[str, Any] = {}
    for key, values in contracted.items():
        entries[",".join(map(str, key))] = core.reconstruct(
            points[:args.train], values[:args.train],
            points[args.train:], values[args.train:],
        )
    reconstruction_seconds = time.perf_counter() - started
    failures = {
        key: value["status"] for key, value in entries.items()
        if value["status"] not in {"ReconstructedModPrime", "Zero"}
    }
    result = {
        "status": (
            "CF303Block2CommonPathCompatibleV1" if not failures
            else "CF303Block2CommonPathDegreeFailureV1"
        ),
        "family": "CF303", "hard_sector": 25, "lower_sector": 2,
        "chart": "Kallen2Bilinear115", "frozen_chart_u": 3,
        "path_extension": "None", "selected_branch": ["a-p", "1+3a"],
        "interpolation_axis": args.axis,
        "fixed_epsilon": args.epsilon if args.axis == "path" else None,
        "fixed_z": fixed_z if args.axis == "epsilon" else None,
        "prime": args.prime, "train_points": args.train,
        "heldout_points": args.heldout, "rejected_path_points": rejected,
        "native_header": header, "native_seconds": native_seconds,
        "native_parse_seconds": header["parse_nanoseconds"] / 1e9,
        "native_evaluation_seconds": header["evaluation_nanoseconds"] / 1e9,
        "native_max_rss_kb": maximum_rss_kb,
        "native_stderr": stderr,
        "reconstruction_seconds": reconstruction_seconds,
        "source_contract": contract_record,
        "failures": failures, "entries": entries,
        "claim_boundary": (
            "degree and common-path compatibility only; no two-variable gauge "
            "or epsilon-form claim"
        ),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    summary = dict(result)
    summary["entries"] = {
        key: {name: value for name, value in entry.items()
              if name not in {"numerator", "denominator"}}
        for key, entry in entries.items()
    }
    print(json.dumps(summary, indent=2))
    return 0 if not failures else 4


if __name__ == "__main__":
    raise SystemExit(main())
