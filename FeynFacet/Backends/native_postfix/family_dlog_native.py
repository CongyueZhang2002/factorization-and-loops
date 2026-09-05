#!/usr/bin/env python3
"""Compute common dlog residues with native postfix evaluation and FLINT."""

from __future__ import annotations

import argparse
import gc
import json
import os
from pathlib import Path
import pickle
import tempfile
import time

import numpy as np

from deferred_gpu import association, normalized, slice_value
from deferred_native import NativeBackend
from family_dlog_gpu import (
    design_and_rhs,
    flint_pivots,
    flint_solve,
    make_request,
    modular_product,
    prime_sequence,
    reconstruct_coefficients,
    reduce_reconstruction,
    sidecar_literal,
    sidecar_metadata,
    wl_rational,
)


def write_record(path: Path, sidecar: Path,
                 reconstructed: list[list[tuple[int, int]]], pivots: list[int],
                 dimension: int, letter_count: int, crt_primes: list[int],
                 fresh_prime: int, training_points: int, validation_points: int,
                 seconds: float) -> None:
    full = [[(0, 1)] * (dimension * dimension) for _ in range(letter_count)]
    for pivot_position, letter_index in enumerate(pivots):
        full[letter_index] = reconstructed[pivot_position]

    def matrix(row: list[tuple[int, int]]) -> str:
        return "{" + ",".join(
            "{" + ",".join(wl_rational(value)
                             for value in row[start:start + dimension]) + "}"
            for start in range(0, len(row), dimension)
        ) + "}"

    body = (
        '<|"Schema" -> "FamilyDLogResiduesV1", '
        '"Status" -> "ComputedDLogResidues", "Valid" -> True, '
        '"Purpose" -> "RequestedOutputIteratedIntegralCoefficientOperatorInput", '
        f'"Variables" -> {sidecar_literal(sidecar, "Variables")}, '
        f'"Regulator" -> {sidecar_literal(sidecar, "Regulator")}, '
        f'"Dimension" -> {dimension}, "CoefficientField" -> "Multiquadratic", '
        f'"Letters" -> {sidecar_literal(sidecar, "Letters")}, "Residues" -> '
        "{" + ",".join(matrix(row) for row in full) + "},"
        '"ConstantResidues" -> True, "IdentityMethod" -> "FiniteFieldPointwise", '
        '"AllRootSheetsEvaluated" -> True, "PointwiseReplay" -> True, '
        f'"TrainingPointsPerPrime" -> {training_points}, '
        f'"ValidationPointsPerPrime" -> {validation_points}, '
        f'"CRTPrimes" -> {{{",".join(map(str, crt_primes))}}}, '
        f'"FreshValidationPrime" -> {fresh_prime}, '
        '"FreshPrimeValidation" -> True, "ResiduesVerifiedAtAllPrimes" -> True, '
        '"Backend" -> "NativeCPU31Postfix+FLINTMultiRHS", '
        f'"Seconds" -> {seconds:.9f}|>\n'
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + f".tmp.{os.getpid()}")
    temporary.write_text(body)
    os.replace(temporary, path)


def compare_records(candidate: Path, reference: Path) -> list[str]:
    candidate_text, reference_text = candidate.read_text(), reference.read_text()
    candidate_top = association(candidate_text, (0, len(candidate_text)))
    reference_top = association(reference_text, (0, len(reference_text)))
    ignored = {"Backend", "Seconds"}
    keys = (set(candidate_top) | set(reference_top)) - ignored
    differences = []
    for key in sorted(keys):
        if key not in candidate_top or key not in reference_top or normalized(
            slice_value(candidate_text, candidate_top[key])
        ) != normalized(slice_value(reference_text, reference_top[key])):
            differences.append(key)
    return differences


def run(args: argparse.Namespace) -> None:
    run_at = time.perf_counter()
    at = time.perf_counter()
    symbols, roots, _, dx, dy, declared_dimension = sidecar_metadata(args.sidecar)
    with args.cache.open("rb") as handle:
        cached = pickle.load(handle)
    connection, dlogs = cached["connection"], cached["dlogs"]
    load_s = time.perf_counter() - at
    dimension, letter_count = connection.dimensions[1], len(dx)
    if connection.dimensions != (2, dimension, dimension) or \
            (declared_dimension and dimension != declared_dimension):
        raise ValueError("connection dimension mismatch")
    if dlogs.dimensions != (2, letter_count, 1):
        raise ValueError("dlog program dimensions mismatch")
    print(json.dumps({
        "phase": "prepared", "cache_load_s": round(load_s, 6),
        "dimension": dimension, "letters": letter_count,
        "rank": len(roots), "connection_programs": connection.unique_expression_count,
        "connection_instructions": len(connection.ops),
        "dlog_programs": dlogs.unique_expression_count,
        "dlog_instructions": len(dlogs.ops), "threads": args.threads,
        "flint_threads": args.flint_threads,
    }), flush=True)

    primes = prime_sequence()
    pivot_reference = None
    modular_solutions: list[tuple[int, np.ndarray, list[int]]] = []
    reconstructed = None
    reconstructed_modulus = 1
    fresh_prime = None
    with tempfile.TemporaryDirectory(prefix="family-dlog-native-flint-") as temporary, \
            NativeBackend(args.native_library, args.threads) as native:
        temp = Path(temporary)
        for prime_index, prime in enumerate(primes[:args.max_primes]):
            prime_at = time.perf_counter()
            at = time.perf_counter()
            request = make_request(
                prime, symbols, roots,
                args.training_points + args.validation_points,
                args.seed + 1000 * prime_index,
            )
            request_s = time.perf_counter() - at
            connection_values, connection_timing = native.evaluate(request, connection)
            dlog_values, dlog_timing = native.evaluate(request, dlogs)
            at = time.perf_counter()
            matrix, rhs = design_and_rhs(connection_values, dlog_values, request,
                                         dimension, letter_count)
            design_s = time.perf_counter() - at
            training_rows = 2 * request.grade_count * args.training_points
            train_matrix, validation_matrix = matrix[:training_rows], matrix[training_rows:]
            train_rhs, validation_rhs = rhs[:training_rows], rhs[training_rows:]

            at = time.perf_counter()
            pivots, independent = flint_pivots(train_matrix, prime, args.rref,
                                               temp, args.flint_threads)
            rref_s = time.perf_counter() - at
            if pivot_reference is None:
                pivot_reference = pivots
            if pivots != pivot_reference:
                print(json.dumps({"phase": "prime_rejected", "prime": prime,
                                  "reason": "pivot_mismatch", "rank": len(pivots)}),
                      flush=True)
                continue
            at = time.perf_counter()
            core = train_matrix[np.ix_(independent, pivots)]
            coefficients = flint_solve(core, train_rhs[independent], prime,
                                       args.solve, temp, args.flint_threads)
            solve_s = time.perf_counter() - at
            at = time.perf_counter()
            training_ok = np.array_equal(
                modular_product(train_matrix[:, pivots], coefficients, prime),
                train_rhs % prime,
            )
            validation_ok = np.array_equal(
                modular_product(validation_matrix[:, pivots], coefficients, prime),
                validation_rhs % prime,
            )
            replay_s = time.perf_counter() - at
            if not training_ok or not validation_ok:
                raise RuntimeError("common dlog residue system failed pointwise replay")

            is_fresh = False
            reconstruction_s = 0.0
            if reconstructed is not None:
                reduced = reduce_reconstruction(reconstructed, prime)
                if reduced is not None and np.array_equal(reduced, coefficients):
                    fresh_prime, is_fresh = prime, True
                else:
                    raise RuntimeError("fresh-prime residue comparison failed")
            if not is_fresh:
                modular_solutions.append((prime, coefficients, pivots))
                if len(modular_solutions) == args.crt_primes:
                    at = time.perf_counter()
                    reconstructed, reconstructed_modulus, failed = \
                        reconstruct_coefficients(modular_solutions)
                    reconstruction_s = time.perf_counter() - at
                    if failed or reconstructed is None:
                        raise RuntimeError(f"rational reconstruction failed at {failed} coordinates")

            print(json.dumps({
                "phase": "fresh_prime" if is_fresh else "crt_prime",
                "prime_index": prime_index + 1, "prime": prime, "rank": len(pivots),
                "request_s": round(request_s, 6),
                "connection_plan_setup_s": round(connection_timing["plan_setup_s"], 6),
                "connection_prepare_s": round(connection_timing["preparation_s"], 6),
                "connection_native_s": round(connection_timing["native_total_s"], 6),
                "connection_call_s": round(connection_timing["call_s"], 6),
                "dlog_plan_setup_s": round(dlog_timing["plan_setup_s"], 6),
                "dlog_native_s": round(dlog_timing["native_total_s"], 6),
                "design_s": round(design_s, 6), "rref_s": round(rref_s, 6),
                "solve_s": round(solve_s, 6), "replay_s": round(replay_s, 6),
                "reconstruction_s": round(reconstruction_s, 6),
                "training_ok": bool(training_ok), "validation_ok": bool(validation_ok),
                "prime_s": round(time.perf_counter() - prime_at, 6),
            }), flush=True)
            if is_fresh:
                break

    if reconstructed is None or fresh_prime is None or pivot_reference is None:
        raise RuntimeError("13-prime lift did not pass its fresh prime")
    write_record(args.output, args.sidecar, reconstructed, pivot_reference,
                 dimension, letter_count,
                 [prime for prime, _, _ in modular_solutions], fresh_prime,
                 args.training_points, args.validation_points,
                 time.perf_counter() - run_at)
    differences = compare_records(args.output, args.reference)
    print(json.dumps({
        "phase": "done", "output": str(args.output),
        "output_bytes": args.output.stat().st_size,
        "crt_primes": len(modular_solutions), "fresh_prime": fresh_prime,
        "modulus_bits": reconstructed_modulus.bit_length(),
        "reference": str(args.reference),
        "record_fields_equal_cuda": not differences,
        "different_fields": differences,
        "seconds": round(time.perf_counter() - run_at, 6),
    }), flush=True)
    if differences:
        raise RuntimeError(f"native and CUDA records differ in fields: {differences}")
    del cached, connection, dlogs
    gc.collect()


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    result.add_argument("sidecar", type=Path)
    result.add_argument("output", type=Path)
    result.add_argument("--cache", type=Path, required=True)
    result.add_argument("--reference", type=Path, required=True)
    result.add_argument("--native-library", type=Path, required=True)
    result.add_argument("--rref", type=Path, required=True)
    result.add_argument("--solve", type=Path, required=True)
    result.add_argument("--training-points", type=int, default=9)
    result.add_argument("--validation-points", type=int, default=2)
    result.add_argument("--crt-primes", type=int, default=13)
    result.add_argument("--max-primes", type=int, default=14)
    result.add_argument("--threads", type=int, default=8)
    result.add_argument("--flint-threads", type=int, default=4)
    result.add_argument("--seed", type=int, default=259091)
    return result


if __name__ == "__main__":
    run(parser().parse_args())
