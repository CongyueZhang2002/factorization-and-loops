#!/usr/bin/env python3
"""Adaptive exact fixed-path reconstruction for CF303 (25,2).

Modular images are persisted prime-by-prime.  CRT/rational reconstruction is
attempted after every batch, and the first complete lift must reduce to one
additional independently computed confirmation prime before it is accepted.
The whole campaign uses the codex scratch tree and launches no Wolfram kernel.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import math
import os
import time
from fractions import Fraction
from pathlib import Path
from typing import Any

import cf303_25_2_native_path_degree as degree
import cf303_block14_exact_quadratic_path_campaign as lift_core


CHANNELS = ("1,1", "2,1")
PRIME_IMAGE_STATUS = "CF303Block2RationalPathPrimeImageV1"
PRIME_FILE_PREFIX = "cf303_25_2_path_prime"
PRIME_POOL = (
    2_305_843_009_213_693_951,
    2_305_843_009_213_693_921,
    2_305_843_009_213_693_907,
    2_305_843_009_213_693_723,
    2_305_843_009_213_693_693,
    2_305_843_009_213_693_669,
    2_305_843_009_213_693_613,
    2_305_843_009_213_693_561,
    2_305_843_009_213_693_487,
    2_305_843_009_213_693_123,
    2_305_843_009_213_692_967,
    2_305_843_009_213_692_799,
    2_305_843_009_213_692_671,
    2_305_843_009_213_692_527,
    2_305_843_009_213_692_463,
    2_305_843_009_213_692_427,
    2_305_843_009_213_692_419,
    2_305_843_009_213_692_343,
    2_305_843_009_213_692_331,
    2_305_843_009_213_692_283,
)
GRID_Z_COUNT = 69
GRID_EPS = tuple(range(11, 20))
QZ_TRAIN = 160
QZ_HELDOUT = 32
QEPS_Z = 27
QEPS_POINTS = tuple(range(7, 47))
QEPS_TRAIN = 24
VALIDATION_COUNT = 16
CPU_SETS = ("4", "5", "6", "7")


def atomic_json(path: Path, value: Any) -> None:
    temporary = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    os.replace(temporary, path)


def evaluate_bivariate(
    coefficients: list[list[int]], z: int, epsilon: int, prime: int
) -> int:
    result = 0
    for z_coefficients in reversed(coefficients):
        epsilon_value = 0
        for coefficient in reversed(z_coefficients):
            epsilon_value = (epsilon_value * epsilon + coefficient) % prime
        result = (result * z + epsilon_value) % prime
    return result


def pad(polynomial: list[int], length: int) -> list[int]:
    if len(polynomial) > length:
        raise RuntimeError(
            f"degree {len(polynomial)-1} exceeds grid cap {length-1}"
        )
    return polynomial + [0] * (length - len(polynomial))


def eligible_points(prime: int, count: int, start: int, epsilon: int):
    images: list[dict[str, int]] = []
    candidate = start
    while len(images) < count:
        image = degree.chart_point(candidate, epsilon, prime)
        if image is not None:
            images.append(image)
        candidate += 1
    return images


def reconstruct_prime(
    prime: int, cpu_set: str, threads: int, output_directory: str
) -> dict[str, Any]:
    output = Path(output_directory)
    target = output / f"{PRIME_FILE_PREFIX}_{prime}.json"
    if target.is_file():
        existing = json.loads(target.read_text())
        if (
            existing.get("status") == PRIME_IMAGE_STATUS
            and int(existing.get("prime", -1)) == prime
            and existing.get("source_sha256") == degree.source_sha256()
        ):
            return existing

    qz_images = eligible_points(
        prime, QZ_TRAIN + QZ_HELDOUT, 7, GRID_EPS[0]
    )
    grid_z = [image["z"] for image in qz_images[:GRID_Z_COUNT]]
    qz_z = [image["z"] for image in qz_images]
    qeps_z = QEPS_Z
    while degree.chart_point(qeps_z, QEPS_POINTS[0], prime) is None:
        qeps_z += 1
    validation_images = eligible_points(prime, VALIDATION_COUNT, 1000, 61)
    validation_pairs = [
        (image["z"], 61 + 2 * index)
        for index, image in enumerate(validation_images)
    ]

    pairs: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for pair in (
        *((z, epsilon) for epsilon in GRID_EPS for z in grid_z),
        *((z, GRID_EPS[0]) for z in qz_z),
        *((qeps_z, epsilon) for epsilon in QEPS_POINTS),
        *validation_pairs,
    ):
        if pair not in seen:
            seen.add(pair)
            pairs.append(pair)
    images: list[dict[str, int]] = []
    for z, epsilon in pairs:
        image = degree.chart_point(z, epsilon, prime)
        if image is None:
            raise RuntimeError(f"invalid path pair p={prime} ({z},{epsilon})")
        images.append(image)

    header, records, stderr, native_seconds, max_rss_kb = degree.run_native(
        images, prime, cpu_set, threads
    )
    contracted = degree.contract(records, images, prime)
    value_maps = {
        f"{row},{column}": {
            pair: values[index] for index, pair in enumerate(pairs)
        }
        for (row, column), values in contracted.items()
    }
    core = degree.load_interpolation_core()
    core.PRIME = prime
    reconstruction_started = time.perf_counter()
    qz: dict[str, list[int]] = {}
    qeps: dict[str, list[int]] = {}
    degrees: dict[str, dict[str, int]] = {}
    for channel in CHANNELS:
        path_values = [
            value_maps[channel][(z, GRID_EPS[0])] for z in qz_z
        ]
        fit_z = core.reconstruct(
            qz_z[:QZ_TRAIN], path_values[:QZ_TRAIN],
            qz_z[QZ_TRAIN:], path_values[QZ_TRAIN:],
        )
        if fit_z["status"] != "ReconstructedModPrime":
            raise RuntimeError(f"z fit failed p={prime} channel={channel}")
        qz[channel] = fit_z["denominator"]

        epsilon_values = [
            value_maps[channel][(qeps_z, epsilon)]
            for epsilon in QEPS_POINTS
        ]
        fit_epsilon = core.reconstruct(
            list(QEPS_POINTS[:QEPS_TRAIN]), epsilon_values[:QEPS_TRAIN],
            list(QEPS_POINTS[QEPS_TRAIN:]), epsilon_values[QEPS_TRAIN:],
        )
        if fit_epsilon["status"] != "ReconstructedModPrime":
            raise RuntimeError(
                f"epsilon fit failed p={prime} channel={channel}"
            )
        qeps[channel] = fit_epsilon["denominator"]
        degrees[channel] = {
            "z_numerator": int(fit_z["numerator_degree"]),
            "z_denominator": int(fit_z["denominator_degree"]),
            "epsilon_numerator": int(fit_epsilon["numerator_degree"]),
            "epsilon_denominator": int(fit_epsilon["denominator_degree"]),
        }

    numerators: dict[str, list[list[int]]] = {}
    for channel in CHANNELS:
        z_polynomials: list[list[int]] = []
        for epsilon in GRID_EPS:
            samples = [
                value_maps[channel][(z, epsilon)]
                * core.evaluate(qz[channel], z)
                * core.evaluate(qeps[channel], epsilon) % prime
                for z in grid_z
            ]
            polynomial, _ = core.interpolation(grid_z, samples)
            z_polynomials.append(pad(polynomial, GRID_Z_COUNT))
        coefficients: list[list[int]] = []
        for z_index in range(GRID_Z_COUNT):
            polynomial, _ = core.interpolation(
                list(GRID_EPS),
                [image[z_index] for image in z_polynomials],
            )
            coefficients.append(pad(polynomial, len(GRID_EPS)))
        numerators[channel] = coefficients

    for channel in CHANNELS:
        for z, epsilon in validation_pairs:
            denominator = (
                core.evaluate(qz[channel], z)
                * core.evaluate(qeps[channel], epsilon)
            ) % prime
            if denominator == 0:
                raise RuntimeError("modular validation denominator vanished")
            observed = (
                evaluate_bivariate(numerators[channel], z, epsilon, prime)
                * pow(denominator, prime - 2, prime)
            ) % prime
            expected = value_maps[channel][(z, epsilon)]
            if observed != expected:
                raise RuntimeError(
                    f"held-out mismatch p={prime} channel={channel}"
                )

    result = {
        "status": PRIME_IMAGE_STATUS,
        "prime": prime, "prime_bits": prime.bit_length(),
        "cpu_set": cpu_set, "native_threads": threads,
        "path_points": len(pairs), "selected_sheet_images": len(images),
        "record_count": header["record_count"],
        "term_count": header["term_count"],
        "unique_expression_count": header["unique_expression_count"],
        "native_seconds": native_seconds,
        "native_parse_seconds": header["parse_nanoseconds"] / 1e9,
        "native_evaluation_seconds": header["evaluation_nanoseconds"] / 1e9,
        "max_rss_kb": max_rss_kb, "native_stderr": stderr,
        "reconstruction_seconds": time.perf_counter() - reconstruction_started,
        "qz_train": QZ_TRAIN, "qz_heldout": QZ_HELDOUT,
        "qeps_z": qeps_z, "qeps_train": QEPS_TRAIN,
        "qeps_heldout": len(QEPS_POINTS) - QEPS_TRAIN,
        "disjoint_validation_pairs": VALIDATION_COUNT,
        "source_sha256": degree.source_sha256(),
        "root_order": list(degree.ROOT_SQUARES),
        "selected_branch": ["a-p", "1+3a"],
        "path_extension": "None", "degrees": degrees,
        "qz": qz, "qeps": qeps, "numerators": numerators,
    }
    atomic_json(target, result)
    return result


def configure_lift_core() -> None:
    lift_core.CHANNELS = CHANNELS


def lift_structure(images: list[dict[str, Any]]):
    configure_lift_core()
    return lift_core.lift_structure(images)


def reduce_fraction(value: Fraction, prime: int) -> int:
    denominator = value.denominator % prime
    if denominator == 0:
        raise ZeroDivisionError("lift denominator vanished at confirmation prime")
    return value.numerator % prime * pow(denominator, prime - 2, prime) % prime


def confirmation_mismatches(
    lifted: dict[str, Any], image: dict[str, Any]
) -> list[str]:
    prime = int(image["prime"])
    mismatches: list[str] = []
    if lifted["degrees"] != image["degrees"]:
        return ["degree pattern"]
    for channel in CHANNELS:
        for key in ("qz", "qeps"):
            exact = lifted[key][channel]
            modular = image[key][channel]
            if len(exact) != len(modular):
                mismatches.append(f"{key}:{channel}:length")
                continue
            for index, (left, right) in enumerate(zip(exact, modular, strict=True)):
                if reduce_fraction(left, prime) != right:
                    mismatches.append(f"{key}:{channel}:{index}")
        exact_rows = lifted["numerators"][channel]
        modular_rows = image["numerators"][channel]
        if len(exact_rows) != len(modular_rows):
            mismatches.append(f"numerators:{channel}:rows")
            continue
        for i, (exact_row, modular_row) in enumerate(
            zip(exact_rows, modular_rows, strict=True)
        ):
            for j, (left, right) in enumerate(
                zip(exact_row, modular_row, strict=True)
            ):
                if reduce_fraction(left, prime) != right:
                    mismatches.append(f"numerators:{channel}:{i}:{j}")
                    if len(mismatches) >= 16:
                        return mismatches
    return mismatches


def wl_entry_declarations(lifted: dict[str, Any]) -> tuple[list[str], dict[str, str]]:
    declarations: list[str] = []
    entries: dict[str, str] = {}
    for index, channel in enumerate(CHANNELS, start=1):
        qz_name, qe_name, numerator_name = f"qz{index}", f"qe{index}", f"n{index}"
        declarations.extend((
            f"  {qz_name} = {lift_core.wl_list(lifted['qz'][channel], 2)},",
            f"  {qe_name} = {lift_core.wl_list(lifted['qeps'][channel], 2)},",
            f"  {numerator_name} = {lift_core.wl_list(lifted['numerators'][channel], 2)}"
            + ("," if index < len(CHANNELS) else ""),
        ))
        entries[channel] = f"entry[{numerator_name}, {qz_name}, {qe_name}]"
    return declarations, entries


def write_wolfram_artifact(
    path: Path, lifted: dict[str, Any], report: dict[str, Any]
) -> None:
    declarations, entries = wl_entry_declarations(lifted)
    forcing = "{{" + entries["1,1"] + "}, {" + entries["2,1"] + "}}"
    lines = [
        "(* Exact CF303 (25,2) fixed-path forcing; scratch reconstruction. *)",
        "With[{",
        *declarations,
        "},",
        " Module[{p = Symbol[\"Global`cf303TailZ\"],",
        "   ep = Symbol[\"Global`eps\"],",
        "   sourceX = Symbol[\"Global`x\"], sourceY = Symbol[\"Global`y\"],",
        "   a, poly, numerator, entry, forcing},",
        "  a = (4 p (1 - p) - 6)/(9 + 4 p (1 - p));",
        "  poly[c_, variable_] := Sum[c[[i]] variable^(i - 1),",
        "    {i, Length[c]}];",
        "  numerator[c_] := Sum[c[[i, j]] p^(i - 1) ep^(j - 1),",
        "    {i, Length[c]}, {j, Length[First[c]]}];",
        "  entry[n_, qz_, qe_] := numerator[n]/(poly[qz, p] poly[qe, ep]);",
        f"  forcing = {forcing};",
        "  <|",
        "   \"Status\" -> \"CF303Block2ExactStructuredPathV1\",",
        "   \"Family\" -> \"CF303\", \"HardSector\" -> 25,",
        "   \"LowerSector\" -> 2, \"Chart\" -> \"Kallen2Bilinear115\",",
        "   \"FrozenChartU\" -> 3, \"PathVariable\" -> p,",
        "   \"Regulator\" -> ep,",
        "   \"SourcePath\" -> <|sourceX -> -a p,",
        "      sourceY -> (1 - a) (1 - p)|>,",
        "   \"SourceRootBranch\" -> {a - p, 1 + 3 a},",
        "   \"SourceRootSquares\" -> {",
        "      1 + 2 sourceX + sourceX^2 - 2 sourceY +",
        "        2 sourceX sourceY + sourceY^2,",
        "      1 - 4 sourceX sourceY},",
        "   \"PathExtension\" -> <|\"Type\" -> \"None\"|>,",
        "   \"PathForcing\" -> forcing,",
        "   \"GaugeBlock\" -> ConstantArray[0, {2, 1}],",
        "   \"ReadsSolvedForms\" -> False,",
        "   \"TransportTerm\" -> HoldForm[Phi25[p] .",
        "      FeynFacet`TransportQuadrature[Function[s,",
        "        Inverse[Phi25[s]] . B252[s, ep] . J2[s]], p, p0]],",
        "   \"ConstantConvention\" -> HoldForm[c25Final ==",
        "      Inverse[Phi25[p0]] . (I25[p0] -",
        "        Sum[D25Lower[m, p0] . ILower[m, p0], {m, 1, 24}])],",
        "   \"DifferentiateBackStatement\" ->",
        "      \"Given Phi25'=A25,25 Phi25, differentiating the transport term returns A25,25 times the term plus PathForcing.J2.\",",
        f"   \"PrimeCount\" -> {len(report['lift_primes'])},",
        f"   \"CombinedModulusBits\" -> {report['combined_modulus_bits']},",
        f"   \"CRTConfirmationPrime\" -> {report['crt_confirmation_prime']},",
        f"   \"DisjointValidationPairsPerPrime\" -> {VALIDATION_COUNT},",
        "   \"Acceptance\" -> \"ExactPathForcingAccepted\",",
        "   \"ClaimBoundary\" ->",
        "      \"exact accepted-gauge forcing only on the fixed u=3 path; ExactPathForcingAccepted, not a two-variable gauge, global no-eps-form result, or family epsilon-form certificate\"",
        "  |>",
        " ]",
        "]",
        "",
    ]
    path.write_text("\n".join(lines))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--batch-size", type=int, default=4)
    parser.add_argument("--minimum-lift-primes", type=int, default=4)
    parser.add_argument("--maximum-lift-primes", type=int, default=20)
    args = parser.parse_args()
    if not 1 <= args.batch_size <= 4:
        raise RuntimeError("batch size must be 1..4")
    if not 1 <= args.minimum_lift_primes <= args.maximum_lift_primes <= len(PRIME_POOL):
        raise RuntimeError("invalid adaptive-prime bounds")
    args.output_directory.mkdir(parents=True, exist_ok=True)
    checkpoint_path = args.output_directory / "cf303_25_2_path_campaign_checkpoint.json"
    source_contract = degree.verify_source_contract()
    checkpoint = {
        "status": "CF303Block2AdaptivePathCampaignV1",
        "source_contract": source_contract,
        "completed_lift_primes": [],
        "lift_attempts": [],
        "crt_confirmation": None,
        "started_epoch": time.time(),
    }
    if checkpoint_path.is_file():
        saved = json.loads(checkpoint_path.read_text())
        if saved.get("source_contract") != source_contract:
            raise RuntimeError("campaign checkpoint source contract changed")
        checkpoint = saved
        if checkpoint.get("status") == "CF303Block2AdaptivePathCampaignCompleteV1":
            report_path = Path(checkpoint.get("report", ""))
            coefficient_path = Path(checkpoint.get("coefficients", ""))
            artifact_path = Path(checkpoint.get("artifact", ""))
            if not report_path.is_absolute():
                report_path = Path.cwd() / report_path
            if not coefficient_path.is_absolute():
                coefficient_path = Path.cwd() / coefficient_path
            if not artifact_path.is_absolute():
                artifact_path = Path.cwd() / artifact_path
            if not all(path.is_file() for path in
                       (report_path, coefficient_path, artifact_path)):
                raise RuntimeError("completed checkpoint references missing outputs")
            report = json.loads(report_path.read_text())
            if report.get("status") != "CF303Block2ExactPathReadyV1":
                raise RuntimeError("completed checkpoint report is not accepted")
            print(json.dumps(report, indent=2))
            print(f"CHECKPOINT={checkpoint_path}")
            print(f"REPORT={report_path}")
            print(f"COEFFICIENTS={coefficient_path}")
            print(f"ARTIFACT={artifact_path}")
            return 0

    completed = [int(value) for value in checkpoint["completed_lift_primes"]]
    wall_started = time.perf_counter()
    lifted: dict[str, Any] | None = None
    confirmation_image: dict[str, Any] | None = None
    while len(completed) < args.maximum_lift_primes:
        pending = [prime for prime in PRIME_POOL if prime not in completed]
        if not pending:
            break
        batch = pending[:min(args.batch_size, args.maximum_lift_primes - len(completed))]
        with concurrent.futures.ThreadPoolExecutor(max_workers=len(batch)) as executor:
            futures = [
                executor.submit(
                    reconstruct_prime, prime, CPU_SETS[index], 1,
                    str(args.output_directory),
                )
                for index, prime in enumerate(batch)
            ]
            images = [future.result() for future in futures]
        completed.extend(int(image["prime"]) for image in images)
        checkpoint["completed_lift_primes"] = completed
        checkpoint["last_batch"] = batch
        checkpoint["updated_epoch"] = time.time()
        atomic_json(checkpoint_path, checkpoint)

        lift_images = [
            json.loads((args.output_directory /
                        f"{PRIME_FILE_PREFIX}_{prime}.json").read_text())
            for prime in completed
        ]
        lift_started = time.perf_counter()
        candidate, failures = lift_structure(lift_images)
        attempt = {
            "prime_count": len(completed),
            "combined_modulus_bits": math.prod(completed).bit_length(),
            "rational_reconstruction_failures": failures,
            "lift_seconds": time.perf_counter() - lift_started,
        }
        checkpoint.setdefault("lift_attempts", []).append(attempt)
        atomic_json(checkpoint_path, checkpoint)
        if failures != 0 or len(completed) < args.minimum_lift_primes:
            continue

        confirmation_candidates = [p for p in PRIME_POOL if p not in completed]
        if not confirmation_candidates:
            raise RuntimeError("no independent CRT confirmation prime remains")
        confirmation_prime = confirmation_candidates[0]
        confirmation_image = reconstruct_prime(
            confirmation_prime, "4-7", 4, str(args.output_directory)
        )
        mismatches = confirmation_mismatches(candidate, confirmation_image)
        checkpoint["crt_confirmation"] = {
            "prime": confirmation_prime,
            "status": "Accepted" if not mismatches else "Mismatch",
            "mismatch_count": len(mismatches),
            "mismatches": mismatches,
        }
        atomic_json(checkpoint_path, checkpoint)
        if mismatches:
            completed.append(confirmation_prime)
            checkpoint["completed_lift_primes"] = completed
            atomic_json(checkpoint_path, checkpoint)
            continue
        lifted = candidate
        break

    if lifted is None or confirmation_image is None:
        checkpoint["status"] = "CF303Block2AdaptivePathCampaignIncompleteV1"
        atomic_json(checkpoint_path, checkpoint)
        raise RuntimeError("adaptive CRT campaign exhausted without a stable lift")

    maximum_numerator_bits, maximum_denominator_bits = lift_core.fraction_stats(lifted)
    lift_images = [
        json.loads((args.output_directory /
                    f"{PRIME_FILE_PREFIX}_{prime}.json").read_text())
        for prime in completed
    ]
    report = {
        "status": "CF303Block2ExactPathReadyV1",
        "acceptance": "ExactPathForcingAccepted",
        "family": "CF303", "hard_sector": 25, "lower_sector": 2,
        "chart": "Kallen2Bilinear115", "frozen_chart_u": 3,
        "path_extension": "None", "selected_branch": ["a-p", "1+3a"],
        "source_contract": source_contract,
        "lift_primes": completed,
        "prime_bits": [prime.bit_length() for prime in completed],
        "combined_modulus_bits": int(lifted["modulus"]).bit_length(),
        "crt_confirmation_prime": int(confirmation_image["prime"]),
        "crt_confirmation_status": "Accepted",
        "adaptive_lift_attempts": checkpoint["lift_attempts"],
        "rational_reconstruction_failures": 0,
        "max_reconstructed_numerator_bits": maximum_numerator_bits,
        "max_reconstructed_denominator_bits": maximum_denominator_bits,
        "degree_pattern": lifted["degrees"],
        "numerator_grid_bidegree_cap": [GRID_Z_COUNT - 1, len(GRID_EPS) - 1],
        "disjoint_validation_pairs_per_prime": VALIDATION_COUNT,
        "parallel_and_adaptive_wall_seconds": time.perf_counter() - wall_started,
        "per_prime": [
            {key: image[key] for key in (
                "prime", "cpu_set", "native_threads", "native_seconds",
                "native_parse_seconds", "native_evaluation_seconds",
                "max_rss_kb", "reconstruction_seconds",
            )}
            for image in lift_images
        ],
        "claim_boundary": (
            "exact accepted-gauge forcing only on the fixed u=3 path; "
            "ExactPathForcingAccepted, not global no-eps-form"
        ),
    }
    report_path = args.output_directory / "cf303_25_2_exact_path_report.json"
    coefficient_path = args.output_directory / "cf303_25_2_exact_path_coefficients.json"
    artifact_path = args.output_directory / "cf303_25_2_exact_structured_path.wl"
    atomic_json(report_path, report)
    atomic_json(coefficient_path, lift_core.map_fractions(lifted))
    write_wolfram_artifact(artifact_path, lifted, report)
    checkpoint["status"] = "CF303Block2AdaptivePathCampaignCompleteV1"
    checkpoint["report"] = str(report_path)
    checkpoint["coefficients"] = str(coefficient_path)
    checkpoint["artifact"] = str(artifact_path)
    checkpoint["completed_epoch"] = time.time()
    atomic_json(checkpoint_path, checkpoint)
    print(json.dumps(report, indent=2))
    print(f"CHECKPOINT={checkpoint_path}")
    print(f"REPORT={report_path}")
    print(f"COEFFICIENTS={coefficient_path}")
    print(f"ARTIFACT={artifact_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
