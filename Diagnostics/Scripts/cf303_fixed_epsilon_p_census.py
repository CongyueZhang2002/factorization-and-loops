#!/usr/bin/env python3
"""Adaptive fixed-epsilon p census of reduced CF303 block-1 data.

Each p image is an independently resumable selected-sheet scalar solve.  Two
four-thread requests are allowed concurrently.  A modal reduced-u layout
defines generic images; degree-drop images are recorded and excluded.  Every
monic u-denominator, reduced numerator, and elliptic cohomology coefficient is
then reconstructed as a rational function of p with complete held-out images.
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
from collections import Counter
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
SCALAR_SCRIPT = ROOT / (
    "Diagnostics/Scripts/cf303_scalar_modular_algebraic_hermite_pilot.py"
)
RATIONAL_PATH = ROOT / "Diagnostics/Scripts/cf303_block18_native_path_degree.py"
OUTPUT_ROOT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
FFRI_BINARY_CANDIDATES = (
    ROOT / "FeynFacet/Backends/flint/bin/flint_regulator_interpolate",
    Path("/home/maxzhang/factorization-and-loops/FeynFacet/Backends/flint/bin/")
    / "flint_regulator_interpolate",
)


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def fraction_mod(value: Fraction, prime: int) -> int:
    return value.numerator % prime * pow(value.denominator % prime, -1, prime) % prime


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
    target = directory / (
        f"block{block}_q{prime}_e{epsilon}_"
        f"p{p_value.numerator}d{p_value.denominator}.json"
    )
    if target.exists():
        cached = json.loads(target.read_text())
        if image_matches(
            cached, block=block, prime=prime, p_value=p_value,
            epsilon=epsilon, train=train, heldout=heldout,
        ):
            return {"status": "Accepted", "record": cached,
                    "path": str(target), "cached": True,
                    "subprocess_wall": 0.0}
    command = [
        sys.executable, str(SCALAR_SCRIPT), "--block", str(block),
        "--prime", str(prime), "--p", str(p_value),
        "--epsilon", str(epsilon), "--train", str(train),
        "--heldout", str(heldout), "--threads", str(threads),
        "--backend", "selected", "--parallel-mode", "image",
        "--output", str(target),
    ]
    started = time.perf_counter()
    process = subprocess.run(
        command, cwd=ROOT, capture_output=True, text=True, check=False,
    )
    wall = time.perf_counter() - started
    if process.returncode or not target.exists():
        return {
            "status": "RejectedExecution", "p": str(p_value),
            "cached": False, "subprocess_wall": wall,
            "reason": (process.stderr + "\n" + process.stdout[-1200:])[-2400:],
        }
    record = json.loads(target.read_text())
    if not image_matches(
        record, block=block, prime=prime, p_value=p_value,
        epsilon=epsilon, train=train, heldout=heldout,
    ):
        return {
            "status": "RejectedContract", "p": str(p_value),
            "cached": False, "subprocess_wall": wall,
            "reason": "output contract mismatch",
        }
    return {"status": "Accepted", "record": record, "path": str(target),
            "cached": False, "subprocess_wall": wall}


def layout_signature(record: dict[str, Any]) -> str:
    layout: dict[str, Any] = {}
    for channel, channel_record in sorted(record["channels"].items()):
        profile = channel_record["profile"]
        reduction = channel_record["reduction"]
        layout[channel] = {
            "input_degrees": [
                profile["numerator_degree"], profile["denominator_degree"]
            ],
            "reduction_degrees": [
                reduction["input_numerator_degree"],
                reduction["input_denominator_degree"],
                reduction["repeated_degree"], reduction["squarefree_degree"],
            ],
            "lengths": {
                field: len(reduction[field])
                for field in (
                    "primitive_numerator", "primitive_denominator",
                    "remainder_numerator", "remainder_denominator",
                    "cohomology_coefficients",
                ) if field in reduction
            },
        }
    return json.dumps(layout, sort_keys=True, separators=(",", ":"))


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


def flint_reconstruct(
    *, prime: int, abscissae: list[int], value_rows: list[list[int]],
    initial_count: int, heldout_count: int, maximum_total_degree: int,
    threads: int, fixed_profiles: list[tuple[int, int]] | None = None,
) -> dict[str, Any]:
    """Fit all coordinate profiles in one sample-major FFRI1 request."""
    binary = next((path for path in FFRI_BINARY_CANDIDATES if path.exists()), None)
    if binary is None:
        raise RuntimeError("flint_regulator_interpolate is unavailable")
    sample_count = len(abscissae)
    if len(value_rows) != sample_count or not value_rows:
        raise ValueError("FFRI sample shape mismatch")
    coordinate_count = len(value_rows[0])
    if any(len(row) != coordinate_count for row in value_rows):
        raise ValueError("FFRI ragged value matrix")
    mode = 1 if fixed_profiles is not None else 0
    if fixed_profiles is not None and len(fixed_profiles) != coordinate_count:
        raise ValueError("FFRI fixed-profile count mismatch")
    words = [
        prime, sample_count, coordinate_count, initial_count, heldout_count,
        maximum_total_degree, mode,
        *abscissae,
        *(value for row in value_rows for value in row),
    ]
    if fixed_profiles is not None:
        words.extend(
            degree if degree >= 0 else 2**64 - 1
            for profile in fixed_profiles for degree in profile
        )
    with tempfile.TemporaryDirectory(prefix="cf303-p-ffri-") as directory:
        request = Path(directory) / "request.bin"
        response = Path(directory) / "response.bin"
        request.write_bytes(
            b"FFRI1V1\0" + struct.pack(f"<{len(words)}Q", *words)
        )
        started = time.perf_counter()
        process = subprocess.run(
            [str(binary), str(request), str(response), str(threads)],
            cwd=ROOT, capture_output=True, text=True, check=False,
        )
        wall = time.perf_counter() - started
        if process.returncode or not response.exists():
            raise RuntimeError(
                "FLINT FFRI execution failed: "
                + (process.stderr + "\n" + process.stdout)[-2400:]
            )
        payload = response.read_bytes()
    if payload[:8] != b"FFRI1X1\0":
        raise RuntimeError(f"bad FFRI output magic {payload[:8]!r}")
    header = struct.unpack_from("<10Q", payload, 8)
    (
        output_prime, output_samples, output_coordinates, output_mode, status,
        reason, consumed, construction_count, required_additional,
        actual_threads,
    ) = header
    if (
        output_prime != prime or output_samples != sample_count
        or output_coordinates != coordinate_count or output_mode != mode
    ):
        raise RuntimeError(f"FFRI response contract mismatch: {header}")
    offset = 8 + 10 * 8
    profiles = []
    for _ in range(coordinate_count):
        fields = struct.unpack_from("<6Q", payload, offset)
        offset += 6 * 8
        (
            coordinate_status, numerator_degree, denominator_degree,
            coordinate_consumed, numerator_count, denominator_count,
        ) = fields
        coefficients = struct.unpack_from(
            f"<{numerator_count + denominator_count}Q", payload, offset
        )
        offset += 8 * (numerator_count + denominator_count)
        numerator = list(coefficients[:numerator_count])
        denominator = list(coefficients[numerator_count:])
        profiles.append({
            "status": coordinate_status,
            "numerator_degree": -1 if numerator_degree == 2**64 - 1
                else numerator_degree,
            "denominator_degree": denominator_degree,
            "consumed": coordinate_consumed,
            "numerator": numerator,
            "denominator": denominator,
        })
    if offset != len(payload):
        raise RuntimeError("FFRI output has trailing bytes")
    return {
        "status": status, "reason": reason, "mode": mode,
        "consumed": consumed,
        "construction_count": construction_count,
        "required_additional": required_additional,
        "threads": actual_threads, "profiles": profiles,
        "wall": wall, "stdout": process.stdout.strip(),
        "stderr": process.stderr.strip(), "binary": str(binary),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block", type=int, default=1)
    parser.add_argument("--prime", type=int, default=2_305_843_009_213_691_819)
    parser.add_argument("--epsilon", type=int, default=11)
    parser.add_argument("--p-start", type=int, default=3)
    parser.add_argument("--initial-images", type=int, default=24)
    parser.add_argument("--additional-batch", type=int, default=8)
    parser.add_argument("--maximum-images", type=int, default=96)
    parser.add_argument("--p-heldout", type=int, default=4)
    parser.add_argument("--known-maximum-p-degree", type=int)
    parser.add_argument("--u-train", type=int, default=125)
    parser.add_argument("--u-heldout", type=int, default=4)
    parser.add_argument("--workers", type=int, choices=(1, 2), default=2)
    parser.add_argument("--threads-per-request", type=int, default=4)
    parser.add_argument("--ffri-threads", type=int, choices=range(1, 9), default=8)
    parser.add_argument("--fixed-profile-source", type=Path)
    parser.add_argument(
        "--output", type=Path,
        default=OUTPUT_ROOT / "cf303_block1_fixed_epsilon_p_census.json",
    )
    args = parser.parse_args()
    if args.workers * args.threads_per_request > 8:
        raise ValueError("worker/thread allocation exceeds eight cores")
    if args.initial_images <= args.p_heldout:
        raise ValueError("initial image count must include held-out images")
    if args.known_maximum_p_degree is not None and args.known_maximum_p_degree < 0:
        raise ValueError("known p degree must be nonnegative")

    image_directory = args.output.parent / (
        f"block{args.block}_fixed_epsilon_p_images"
    )
    image_directory.mkdir(parents=True, exist_ok=True)
    rational = load_module("cf303_p_rational", RATIONAL_PATH)
    rational.PRIME = args.prime
    fixed_profile_record = None
    fixed_profile_map = None
    if args.fixed_profile_source is not None:
        fixed_profile_record = json.loads(args.fixed_profile_source.read_text())
        if (
            fixed_profile_record.get("status")
                != "CF303FixedEpsilonPDegreeCensusAcceptedV1"
            or fixed_profile_record.get("block") != [25, args.block]
            or fixed_profile_record.get("epsilon") != args.epsilon
        ):
            raise ValueError("fixed-profile census contract mismatch")
        fixed_profile_map = {
            (profile["channel"], profile["field"], int(profile["index"])): (
                int(profile["numerator_degree"]),
                int(profile["denominator_degree"]),
            )
            for profile in fixed_profile_record["lifted_coordinates"]
        }
        if args.known_maximum_p_degree is None:
            args.known_maximum_p_degree = int(
                fixed_profile_record["maximum_p_total_degree"]
            )
    images: dict[Fraction, dict[str, Any]] = {}
    execution_rejections: list[dict[str, Any]] = []
    next_integer = args.p_start
    requested_count = 0
    rounds = []
    campaign_started = time.perf_counter()

    def acquire(count: int) -> None:
        nonlocal next_integer, requested_count
        candidates = []
        while len(candidates) < count and requested_count < args.maximum_images:
            value = Fraction(next_integer, 1)
            next_integer += 1
            requested_count += 1
            # p=0,1,2 are known degenerations of this quartic path.
            if value in {Fraction(0), Fraction(1), Fraction(2)}:
                continue
            candidates.append(value)

        def evaluate(p_value: Fraction):
            result = run_image(
                block=args.block, prime=args.prime, p_value=p_value,
                epsilon=args.epsilon, train=args.u_train,
                heldout=args.u_heldout, threads=args.threads_per_request,
                directory=image_directory,
            )
            print(
                f"P_IMAGE {p_value} status={result['status']} "
                f"cached={result.get('cached', False)} "
                f"wall={result.get('subprocess_wall', 0.0):.3f}",
                flush=True,
            )
            return p_value, result

        with concurrent.futures.ThreadPoolExecutor(
            max_workers=args.workers
        ) as executor:
            for p_value, result in executor.map(evaluate, candidates):
                if result["status"] == "Accepted":
                    images[p_value] = result
                else:
                    execution_rejections.append(result)

    initial_image_count = args.initial_images
    if args.known_maximum_p_degree is not None:
        # A total degree d has d+1 projective coefficients after fixing the
        # denominator scale.  Acquire that construction budget plus held-outs
        # before the first FFRI call; this avoids replaying discovery at every
        # small outer batch when resuming an already-censused fixture.
        initial_image_count = max(
            initial_image_count,
            args.known_maximum_p_degree + 1 + args.p_heldout,
        )
    acquire(initial_image_count)
    accepted_lift = None
    generic_signature = None
    generic_images: list[Fraction] = []
    degree_drop_images: list[dict[str, Any]] = []
    while True:
        signatures = Counter(
            layout_signature(image["record"]) for image in images.values()
        )
        if not signatures:
            raise RuntimeError("no accepted p images")
        generic_signature, modal_count = signatures.most_common(1)[0]
        generic_images = sorted(
            p_value for p_value, image in images.items()
            if layout_signature(image["record"]) == generic_signature
        )
        degree_drop_images = [
            {
                "p": [p_value.numerator, p_value.denominator],
                "path": image["path"],
                "layout": layout_signature(image["record"]),
            }
            for p_value, image in sorted(images.items())
            if layout_signature(image["record"]) != generic_signature
        ]
        attempt = {
            "requested": requested_count, "accepted": len(images),
            "generic": len(generic_images), "modal_count": modal_count,
            "degree_drops": len(degree_drop_images),
            "execution_rejections": len(execution_rejections),
        }
        required_generic_images = args.p_heldout + 1
        if fixed_profile_map is not None:
            required_construction = 1 + max(
                numerator + denominator if numerator >= 0 else 0
                for numerator, denominator in fixed_profile_map.values()
            )
            required_generic_images = (
                required_construction + args.p_heldout
            )
        attempt["required_generic_images"] = required_generic_images
        if len(generic_images) < required_generic_images:
            attempt["status"] = "InsufficientGenericImages"
            rounds.append(attempt)
        else:
            construction = generic_images[:-args.p_heldout]
            heldout = generic_images[-args.p_heldout:]
            reference = images[generic_images[0]]["record"]
            channel_keys = sorted(reference["channels"])
            coordinate_values: dict[tuple[str, str, int], list[int]] = {}
            layouts: dict[str, dict[str, int]] = {}
            monic_failures = []
            for channel in channel_keys:
                layouts[channel] = {}
                reference_reduction = reference["channels"][channel]["reduction"]
                fields = [
                    "primitive_denominator", "remainder_denominator",
                    "primitive_numerator", "remainder_numerator",
                ]
                if "cohomology_coefficients" in reference_reduction:
                    fields.append("cohomology_coefficients")
                for field in fields:
                    length = len(reference_reduction[field])
                    layouts[channel][field] = length
                    if field.endswith("denominator"):
                        for p_value in generic_images:
                            denominator = images[p_value]["record"]["channels"][channel][
                                "reduction"
                            ][field]
                            if not denominator or denominator[-1] % args.prime != 1:
                                monic_failures.append([str(p_value), channel, field])
                    for index in range(length):
                        coordinate_values[(channel, field, index)] = [
                            images[p_value]["record"]["channels"][channel][
                                "reduction"
                            ][field][index]
                            for p_value in generic_images
                        ]
            if monic_failures:
                raise RuntimeError(f"nonmonic reduced denominators: {monic_failures[:4]}")
            coordinate_keys = sorted(coordinate_values)
            all_x = [fraction_mod(value, args.prime) for value in generic_images]
            value_rows = [
                [coordinate_values[key][sample] for key in coordinate_keys]
                for sample in range(len(generic_images))
            ]
            fixed_profiles = None
            if fixed_profile_map is not None:
                missing_profiles = [
                    key for key in coordinate_keys if key not in fixed_profile_map
                ]
                if missing_profiles:
                    raise RuntimeError(
                        f"fixed-profile layout mismatch: {missing_profiles[:4]}"
                    )
                fixed_profiles = [
                    fixed_profile_map[key] for key in coordinate_keys
                ]
            flint = flint_reconstruct(
                prime=args.prime, abscissae=all_x, value_rows=value_rows,
                initial_count=len(construction),
                heldout_count=len(heldout),
                maximum_total_degree=max(0, len(construction) - 1),
                threads=args.ffri_threads,
                fixed_profiles=fixed_profiles,
            )
            profiles = []
            failures = []
            maximum_total_degree = 0
            if flint["status"] == 0:
                for key, profile in zip(
                    coordinate_keys, flint["profiles"], strict=True
                ):
                    if profile["status"] != 0:
                        failures.append({
                            "coordinate": key,
                            "status": f"FFRICoordinateStatus{profile['status']}",
                        })
                        continue
                    total_degree = max(
                        0,
                        int(profile["numerator_degree"])
                        + int(profile["denominator_degree"]),
                    )
                    maximum_total_degree = max(
                        maximum_total_degree, total_degree
                    )
                    profiles.append({
                        "channel": key[0], "field": key[1], "index": key[2],
                        "numerator": profile["numerator"],
                        "denominator": profile["denominator"],
                        "numerator_degree": profile["numerator_degree"],
                        "denominator_degree": profile["denominator_degree"],
                        "total_degree": total_degree,
                    })
                # Three independent coordinates retain the simple Python
                # implementation as parity evidence, not as production work.
                for index in sorted({0, len(coordinate_keys) // 2,
                                     len(coordinate_keys) - 1}):
                    key = coordinate_keys[index]
                    values = coordinate_values[key]
                    reference_profile = normalized_profile(rational.reconstruct(
                        all_x[:len(construction)],
                        values[:len(construction)],
                        all_x[len(construction):],
                        values[len(construction):],
                    ))
                    native_profile = flint["profiles"][index]
                    if (
                        reference_profile["status"] != "ReconstructedModPrime"
                        or reference_profile["numerator"]
                            != native_profile["numerator"]
                        or reference_profile["denominator"]
                            != native_profile["denominator"]
                    ):
                        raise RuntimeError(f"FFRI/Python mismatch at {key}")
            else:
                failures = [
                    {
                        "coordinate": coordinate_keys[index],
                        "status": f"FFRICoordinateStatus{profile['status']}",
                    }
                    for index, profile in enumerate(flint["profiles"])
                    if profile["status"] != 0
                ][:12]
                if not failures:
                    failures = [{
                        "coordinate": None,
                        "status": f"FFRIGlobalStatus{flint['status']}",
                    }]
            lift_seconds = flint["wall"]
            attempt.update({
                "construction": len(construction),
                "heldout": len(heldout),
                "coordinate_count": len(coordinate_values),
                "fitted_before_failure": len(profiles),
                "failure_count": len(failures),
                "failures": failures,
                "maximum_total_degree_so_far": maximum_total_degree,
                "lift_seconds": lift_seconds,
                "ffri": {
                    name: flint[name] for name in (
                        "status", "reason", "consumed", "construction_count",
                        "required_additional", "threads", "wall", "binary",
                        "stdout", "stderr",
                    )
                },
            })
            if not failures and len(profiles) == len(coordinate_values):
                attempt["status"] = "Accepted"
                rounds.append(attempt)
                accepted_lift = {
                    "construction": construction, "heldout": heldout,
                    "profiles": profiles, "layouts": layouts,
                    "coordinate_count": len(coordinate_values),
                    "maximum_total_degree": maximum_total_degree,
                    "lift_seconds": lift_seconds,
                }
                break
            attempt["status"] = "NeedsMorePImages"
            rounds.append(attempt)

        if requested_count >= args.maximum_images:
            raise RuntimeError(f"p image cap exhausted: {rounds[-1]}")
        acquire(min(args.additional_batch, args.maximum_images - requested_count))

    assert accepted_lift is not None
    image_summaries = []
    cold_durations = []
    for p_value in sorted(images):
        image = images[p_value]
        record = image["record"]
        duration = sum(
            record["timings"][field] for field in (
                "point_generation", "native_wall", "sheet_projection",
                "rational_interpolation", "hermite",
            )
        )
        cold_durations.append(duration)
        image_summaries.append({
            "p": [p_value.numerator, p_value.denominator],
            "generic": p_value in accepted_lift["construction"]
                or p_value in accepted_lift["heldout"],
            "path": image["path"], "cached": image["cached"],
            "subprocess_wall": image["subprocess_wall"],
            "cold_duration": duration,
        })
    report = {
        "status": "CF303FixedEpsilonPDegreeCensusAcceptedV1",
        "claim": (
            "At fixed (q,epsilon), every coefficient of the modal generic "
            "reduced-u layout is rationally reconstructed in p and accepted "
            "on complete held-out p images. Degree-drop and failed images are "
            "excluded rather than interpreted as the generic section."
        ),
        "block": [25, args.block], "prime": args.prime,
        "epsilon": args.epsilon,
        "construction_p": [
            [value.numerator, value.denominator]
            for value in accepted_lift["construction"]
        ],
        "heldout_p": [
            [value.numerator, value.denominator]
            for value in accepted_lift["heldout"]
        ],
        "generic_layout": json.loads(generic_signature),
        "channel_layouts": accepted_lift["layouts"],
        "degree_drop_images": degree_drop_images,
        "execution_rejections": execution_rejections,
        "requested_image_count": requested_count,
        "known_maximum_p_degree": args.known_maximum_p_degree,
        "fixed_profile_source": (
            str(args.fixed_profile_source)
            if args.fixed_profile_source is not None else None
        ),
        "fixed_profile_source_prime": (
            fixed_profile_record.get("prime")
            if fixed_profile_record is not None else None
        ),
        "accepted_image_count": len(images),
        "generic_image_count": len(generic_images),
        "coordinate_count": accepted_lift["coordinate_count"],
        "maximum_p_total_degree": accepted_lift["maximum_total_degree"],
        "lifted_coordinates": accepted_lift["profiles"],
        "rounds": rounds,
        "workers": args.workers,
        "threads_per_request": args.threads_per_request,
        "maximum_active_native_threads": args.workers * args.threads_per_request,
        "u_train": args.u_train, "u_heldout": args.u_heldout,
        "image_summaries": image_summaries,
        "timings": {
            "campaign_wall": time.perf_counter() - campaign_started,
            "cold_two_worker_estimate": scheduled_wall(
                cold_durations, args.workers
            ),
            "final_p_lift": accepted_lift["lift_seconds"],
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_name(f".{args.output.name}.tmp.{os.getpid()}")
    temporary.write_text(json.dumps(report, indent=2) + "\n")
    os.replace(temporary, args.output)
    print(json.dumps({
        "status": report["status"],
        "requested": requested_count,
        "generic": len(generic_images),
        "construction": len(accepted_lift["construction"]),
        "heldout": len(accepted_lift["heldout"]),
        "coordinates": accepted_lift["coordinate_count"],
        "maximum_p_total_degree": accepted_lift["maximum_total_degree"],
        "rounds": len(rounds), "timings": report["timings"],
        "output": str(args.output),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
