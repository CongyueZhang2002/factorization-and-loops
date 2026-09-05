#!/usr/bin/env python3
"""Compute common dlog residues from a final epsilon connection on CUDA.

This is deliberately not a family certifier.  It consumes only EpsFormX/Y,
the declared multiquadratic root frame, and the dlog-letter derivatives.  The
large transformation, inverse, source connection, and curvature data are
never compiled or evaluated.
"""

from __future__ import annotations

import argparse
from array import array
import gc
import json
import math
import os
from pathlib import Path
import pickle
import random
import struct
import subprocess
import tempfile
import time

import numpy as np

from deferred_gpu import (
    ExpressionCompiler,
    GPUBackend,
    Programs,
    Request,
    association,
    cpu_program,
    is_prime31,
    list_spans,
    nprime32,
    normalized,
    scan_value,
    slice_value,
)


CFFR_INPUT = struct.Struct("<8s9Q")
CFFR_OUTPUT = struct.Struct("<8s11Q")
CFFA_INPUT = struct.Struct("<8s4Q")
CFFA_OUTPUT = struct.Struct("<8s3Q")


def sidecar_metadata(path: Path) -> tuple[tuple[str, str, str], tuple[str, ...],
                                           str, list[str], list[str], int]:
    text = path.read_text()
    top = association(text, (0, len(text)))
    if slice_value(text, top["Schema"]) != '"FamilyDLogComputationSidecarV1"':
        raise ValueError("unsupported dlog sidecar")
    variables = tuple(slice_value(text, span) for span in list_spans(text, top["Variables"]))
    regulator = slice_value(text, top["Regulator"])
    if len(variables) != 2:
        raise ValueError("two variables are required")
    roots = []
    for span in list_spans(text, top["Roots"]):
        record = association(text, span)
        roots.append(slice_value(text, record["RootSquare"]))

    def one_forms(key: str) -> list[str]:
        result = []
        for span in list_spans(text, top[key]):
            items = list_spans(text, span)
            if len(items) != 1:
                raise ValueError(f"{key} entries must be singleton rows")
            result.append(slice_value(text, items[0]))
        return result

    dx, dy = one_forms("LetterX"), one_forms("LetterY")
    if len(dx) != len(dy):
        raise ValueError("letter derivative counts differ")
    dimension = int(slice_value(text, top["Dimension"])) if "Dimension" in top else 0
    return (variables[0], variables[1], regulator), tuple(roots), regulator, dx, dy, dimension


def interned_programs(expressions: list[list[list[str]]], request: Request,
                      multiply_by_inverse_epsilon: bool,
                      label: str) -> Programs:
    offsets, ops, args = array("I", [0]), array("I"), array("I")
    record_offsets, term_offsets, factors = array("I", [0]), array("I", [0]), array("I")
    targets: list[tuple[int, int, int]] = []
    expression_indices: dict[str, int] = {}
    constant_indices: dict[int, int] = {}

    def intern(expression: str) -> int:
        key = normalized(expression)
        known = expression_indices.get(key)
        if known is not None:
            return known
        index = len(expression_indices)
        expression_indices[key] = index
        code = ExpressionCompiler(
            expression, request, constant_indices=constant_indices
        ).compile()
        for op, arg in code:
            ops.append(op)
            args.append(arg)
        offsets.append(len(ops))
        return index

    inverse_epsilon = intern(f"{request.symbols[2]}^(-1)") \
        if multiply_by_inverse_epsilon else None
    started = time.perf_counter()
    for first, matrix in enumerate(expressions, 1):
        for second, row in enumerate(matrix, 1):
            for third, expression in enumerate(row, 1):
                try:
                    factors.append(intern(expression))
                except Exception as error:
                    raise ValueError(
                        f"{label} expression {(first, second, third)} failed: "
                        f"{expression[:400]!r}"
                    ) from error
                if inverse_epsilon is not None:
                    factors.append(inverse_epsilon)
                term_offsets.append(len(factors))
                record_offsets.append(len(term_offsets) - 1)
                targets.append((first, second, third))
            if second == 1 or second % 5 == 0 or second == len(matrix):
                print(json.dumps({
                    "phase": "compile", "label": label, "first": first,
                    "row": second, "rows": len(matrix),
                    "unique_expressions": len(expression_indices),
                    "instructions": len(ops),
                    "seconds": round(time.perf_counter() - started, 3),
                }), flush=True)
    dimensions = (len(expressions), len(expressions[0]), len(expressions[0][0]))
    return Programs(
        offsets, ops, args, record_offsets, term_offsets, factors,
        tuple(constant_indices), targets, dimensions,
        len(term_offsets) - 1, len(expression_indices),
    )


def compile_connection(path: Path, request: Request) -> Programs:
    started = time.perf_counter()
    text = path.read_text()
    print(json.dumps({"phase": "read", "bytes": len(text),
                      "seconds": round(time.perf_counter() - started, 3)}), flush=True)
    matrices: list[list[list[str]]] = []
    for key in ("EpsFormX", "EpsFormY"):
        marker = f'"{key}"'
        key_at = text.find(marker)
        if key_at < 0:
            raise ValueError(f"missing {key}")
        arrow_at = text.find("->", key_at + len(marker), key_at + len(marker) + 32)
        if arrow_at < 0:
            raise ValueError(f"malformed {key} rule")
        value_span = scan_value(text, arrow_at + 2, "|>")
        rows = []
        for row_span in list_spans(text, value_span):
            rows.append([slice_value(text, span) for span in list_spans(text, row_span)])
        if not rows or any(len(row) != len(rows) for row in rows):
            raise ValueError(f"{key} is not square")
        matrices.append(rows)
    programs = interned_programs(matrices, request, True, "epsilon_connection")
    del text, matrices
    gc.collect()
    return programs


def compile_dlogs(dx: list[str], dy: list[str], request: Request) -> Programs:
    matrices = [
        [[expression] for expression in dx],
        [[expression] for expression in dy],
    ]
    return interned_programs(matrices, request, False, "dlog_letters")


def prime_sequence() -> list[int]:
    result = []
    candidate = (1 << 31) - 1
    while len(result) < 16:
        if candidate % 4 == 3 and is_prime31(candidate):
            result.append(candidate)
        candidate -= 2
    return result


def root_square_value(expression: str, point: tuple[int, int, int],
                      shell: Request) -> int:
    p = shell.prime
    rmod, np_value = (1 << 32) % p, nprime32(p)
    code = ExpressionCompiler(expression, shell, allow_sqrt=False).compile()
    inputs = [[coordinate * rmod % p] for coordinate in point]
    inputs.extend([[0]] * len(shell.roots))
    montgomery = cpu_program(code, inputs, 0, p, np_value, rmod)
    return (montgomery * 1 * pow(1 << 32, -1, p)) % p


def make_request(prime: int, symbols: tuple[str, str, str], roots: tuple[str, ...],
                 base_count: int, seed: int) -> Request:
    shell = Request(prime, symbols, roots, 1, 1 << len(roots), [], [], [])
    rng = random.Random(seed + prime)
    base_rows: list[list[int]] = []
    attempts = 0
    while len(base_rows) < base_count and attempts < 10000:
        attempts += 1
        point = tuple(rng.randrange(2, prime - 1) for _ in range(3))
        deltas = [root_square_value(root, point, shell) for root in roots]
        if any(value == 0 or pow(value, (prime - 1) // 2, prime) != 1
               for value in deltas):
            continue
        positive = [pow(value, (prime + 1) // 4, prime) for value in deltas]
        row = list(point)
        for delta, root in zip(deltas, positive):
            row.extend((delta, root))
        base_rows.append(row)
    if len(base_rows) != base_count:
        raise RuntimeError("could not find enough split points")

    rank, grade_count = len(roots), 1 << len(roots)
    inputs = [[] for _ in range(3 + rank)]
    deltas_by_root = [[] for _ in range(rank)]
    positive_by_root = [[] for _ in range(rank)]
    for fields in base_rows:
        for root_index in range(rank):
            positive_by_root[root_index].append(fields[4 + 2 * root_index])
        for sheet in range(grade_count):
            for axis in range(3):
                inputs[axis].append(fields[axis])
            for root_index in range(rank):
                delta = fields[3 + 2 * root_index]
                root = fields[4 + 2 * root_index]
                inputs[3 + root_index].append(
                    prime - root if sheet & (1 << root_index) else root
                )
                deltas_by_root[root_index].append(delta)
    return Request(prime, symbols, roots, base_count, grade_count,
                   inputs, deltas_by_root, positive_by_root)


def reshape_images(values: array, records: int, images: int) -> np.ndarray:
    return np.frombuffer(values, dtype=np.uint32).astype(np.uint64).reshape(records, images)


def design_and_rhs(connection: array, dlogs: array, request: Request,
                   dimension: int, letter_count: int) -> tuple[np.ndarray, np.ndarray]:
    images = request.image_count
    b = reshape_images(connection, 2 * dimension * dimension, images)
    d = reshape_images(dlogs, 2 * letter_count, images)
    rows, rhs = [], []
    for base in range(request.base_count):
        for grade in range(request.grade_count):
            image = base * request.grade_count + grade
            for direction in range(2):
                rows.append(d[direction * letter_count:(direction + 1) * letter_count, image])
                start = direction * dimension * dimension
                rhs.append(b[start:start + dimension * dimension, image])
    return np.asarray(rows, dtype=np.uint64), np.asarray(rhs, dtype=np.uint64)


def write_u64_matrix(handle, matrix: np.ndarray) -> None:
    handle.write(np.asarray(matrix, dtype="<u8", order="C").tobytes())


def flint_pivots(matrix: np.ndarray, prime: int, binary: Path,
                 directory: Path, threads: int) -> tuple[list[int], list[int]]:
    rows, columns = matrix.shape
    nonce_hi, nonce_lo = random.getrandbits(64) or 1, random.getrandbits(64) or 1
    request_path, output_path = directory / "rref.in", directory / "rref.out"
    preference = np.arange(columns, dtype="<u8")
    zero = np.zeros(rows, dtype="<u8")
    payload_words = rows * columns + rows + columns
    with request_path.open("wb") as handle:
        handle.write(CFFR_INPUT.pack(b"CFFR1V1\0", rows, columns, 1, prime,
                                     columns, 0, nonce_hi, nonce_lo, payload_words))
        write_u64_matrix(handle, matrix)
        handle.write(zero.tobytes())
        handle.write(preference.tobytes())
    completed = subprocess.run([str(binary), str(request_path), str(output_path), str(threads)],
                               check=False, capture_output=True, text=True)
    if completed.returncode != 0:
        raise RuntimeError(f"FLINT RREF failed: {completed.stderr}")
    data = output_path.read_bytes()
    fields = CFFR_OUTPUT.unpack_from(data)
    if fields[0] != b"CFFR1X1\0" or fields[9:11] != (nonce_hi, nonce_lo):
        raise RuntimeError("FLINT RREF response mismatch")
    rank, nullity = fields[5], fields[6]
    words = np.frombuffer(data, dtype="<u8", offset=CFFR_OUTPUT.size)
    offset = 0
    pivots = words[offset:offset + rank].astype(int).tolist(); offset += rank
    offset += nullity
    independent_rows = words[offset:offset + rank].astype(int).tolist()
    return pivots, independent_rows


def flint_solve(core: np.ndarray, rhs: np.ndarray, prime: int, binary: Path,
                directory: Path, threads: int) -> np.ndarray:
    rows, columns = core.shape
    if rows != columns or rhs.shape[0] != rows:
        raise ValueError("FLINT solve requires a square core")
    request_path, output_path = directory / "solve.in", directory / "solve.out"
    with request_path.open("wb") as handle:
        handle.write(CFFA_INPUT.pack(b"CFFA4V1\0", rows, columns, rhs.shape[1], prime))
        write_u64_matrix(handle, core)
        write_u64_matrix(handle, rhs)
    completed = subprocess.run([str(binary), str(request_path), str(output_path), str(threads)],
                               check=False, capture_output=True, text=True)
    if completed.returncode != 0:
        raise RuntimeError(f"FLINT multi-RHS solve failed: {completed.stderr}")
    data = output_path.read_bytes()
    magic, out_rows, out_columns, out_prime = CFFA_OUTPUT.unpack_from(data)
    if magic != b"CFFA4X1\0" or out_rows != rows or out_columns != rhs.shape[1] \
            or out_prime != prime:
        raise RuntimeError("FLINT solve response mismatch")
    return np.frombuffer(data, dtype="<u8", offset=CFFA_OUTPUT.size).reshape(rows, rhs.shape[1]).copy()


def modular_product(matrix: np.ndarray, coefficients: np.ndarray, prime: int) -> np.ndarray:
    result = np.zeros((matrix.shape[0], coefficients.shape[1]), dtype=np.uint64)
    for column in range(matrix.shape[1]):
        result = (result + matrix[:, column, None] * coefficients[column, :]) % prime
    return result


def rational_reconstruct(value: int, modulus: int) -> tuple[int, int] | None:
    value %= modulus
    if value == 0:
        return (0, 1)
    bound = math.isqrt((modulus - 1) // 2)
    r0, r1, t0, t1 = modulus, value, 0, 1
    while r1 > bound:
        quotient = r0 // r1
        r0, r1 = r1, r0 - quotient * r1
        t0, t1 = t1, t0 - quotient * t1
    if t1 == 0 or abs(t1) > bound or math.gcd(r1, t1) != 1:
        return None
    if t1 < 0:
        r1, t1 = -r1, -t1
    if (value * t1 - r1) % modulus:
        return None
    return (r1, t1)


def reconstruct_coefficients(
        solutions: list[tuple[int, np.ndarray, list[int]]]
        ) -> tuple[list[list[tuple[int, int]]] | None, int, int]:
    if not solutions:
        return None, 1, 0
    shape = solutions[0][1].shape
    values = [[int(solutions[0][1][i, j]) for j in range(shape[1])]
              for i in range(shape[0])]
    modulus = solutions[0][0]
    for prime, coefficients, _ in solutions[1:]:
        inverse = pow(modulus % prime, -1, prime)
        for row in range(shape[0]):
            for column in range(shape[1]):
                current = values[row][column]
                correction = ((int(coefficients[row, column]) - current) % prime) * inverse % prime
                values[row][column] = current + correction * modulus
        modulus *= prime
    reconstructed: list[list[tuple[int, int]]] = []
    failed = 0
    for row in values:
        reconstructed_row = []
        for value in row:
            rational = rational_reconstruct(value, modulus)
            if rational is None:
                failed += 1
                rational = (0, 1)
            reconstructed_row.append(rational)
        reconstructed.append(reconstructed_row)
    return (None if failed else reconstructed), modulus, failed


def reduce_reconstruction(reconstructed: list[list[tuple[int, int]]],
                          prime: int) -> np.ndarray | None:
    rows, columns = len(reconstructed), len(reconstructed[0])
    result = np.empty((rows, columns), dtype=np.uint64)
    for row in range(rows):
        for column in range(columns):
            numerator, denominator = reconstructed[row][column]
            denominator_mod = denominator % prime
            if denominator_mod == 0:
                return None
            result[row, column] = numerator % prime * pow(denominator_mod, -1, prime) % prime
    return result


def wl_rational(value: tuple[int, int]) -> str:
    numerator, denominator = value
    return str(numerator) if denominator == 1 else f"({numerator}/{denominator})"


def sidecar_literal(path: Path, key: str) -> str:
    text = path.read_text()
    top = association(text, (0, len(text)))
    return slice_value(text, top[key])


def write_dlog_record(path: Path, sidecar: Path,
                      reconstructed: list[list[tuple[int, int]]],
                      pivots: list[int], dimension: int, letter_count: int,
                      crt_primes: list[int], fresh_prime: int,
                      training_points: int, validation_points: int,
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

    variables = sidecar_literal(sidecar, "Variables")
    regulator = sidecar_literal(sidecar, "Regulator")
    letters = sidecar_literal(sidecar, "Letters")
    body = (
        '<|"Schema" -> "FamilyDLogResiduesV1", '
        '"Status" -> "ComputedDLogResidues", "Valid" -> True, '
        '"Purpose" -> "RequestedOutputIteratedIntegralCoefficientOperatorInput", '
        f'"Variables" -> {variables}, "Regulator" -> {regulator}, '
        f'"Dimension" -> {dimension}, "CoefficientField" -> "Multiquadratic", '
        f'"Letters" -> {letters}, "Residues" -> '
        "{" + ",".join(matrix(row) for row in full) + "},"
        '"ConstantResidues" -> True, "IdentityMethod" -> "FiniteFieldPointwise", '
        '"AllRootSheetsEvaluated" -> True, "PointwiseReplay" -> True, '
        f'"TrainingPointsPerPrime" -> {training_points}, '
        f'"ValidationPointsPerPrime" -> {validation_points}, '
        f'"CRTPrimes" -> {{{",".join(map(str, crt_primes))}}}, '
        f'"FreshValidationPrime" -> {fresh_prime}, '
        '"FreshPrimeValidation" -> True, "ResiduesVerifiedAtAllPrimes" -> True, '
        '"Backend" -> "CUDA31Postfix+FLINTMultiRHS", '
        f'"Seconds" -> {seconds:.9f}|>\n'
    )
    temporary = path.with_name(path.name + f".tmp.{os.getpid()}")
    temporary.write_text(body)
    os.replace(temporary, path)


def run(args: argparse.Namespace) -> None:
    run_started = time.perf_counter()
    symbols, roots, _, dx, dy, declared_dimension = sidecar_metadata(args.sidecar)
    primes = prime_sequence()
    first_request = make_request(primes[0], symbols, roots,
                                 args.training_points + args.validation_points, args.seed)
    cache = args.cache
    if cache.exists():
        with cache.open("rb") as handle:
            cached = pickle.load(handle)
        connection_programs, dlog_programs = cached["connection"], cached["dlogs"]
        print(json.dumps({"phase": "cache_load", "path": str(cache),
                          "bytes": cache.stat().st_size}), flush=True)
    else:
        connection_programs = compile_connection(args.family, first_request)
        cache.parent.mkdir(parents=True, exist_ok=True)
        with cache.open("wb") as handle:
            pickle.dump({"connection": connection_programs}, handle,
                        protocol=pickle.HIGHEST_PROTOCOL)
        print(json.dumps({"phase": "connection_cache_write", "path": str(cache),
                          "bytes": cache.stat().st_size}), flush=True)
        dlog_programs = compile_dlogs(dx, dy, first_request)
        with cache.open("wb") as handle:
            pickle.dump({"connection": connection_programs, "dlogs": dlog_programs},
                        handle, protocol=pickle.HIGHEST_PROTOCOL)
        print(json.dumps({"phase": "cache_write", "path": str(cache),
                          "bytes": cache.stat().st_size}), flush=True)
    dimension = connection_programs.dimensions[1]
    if dimension != connection_programs.dimensions[2] or \
            (declared_dimension and dimension != declared_dimension):
        raise ValueError("connection dimension mismatch")
    letter_count = len(dx)
    print(json.dumps({
        "phase": "prepared", "dimension": dimension, "letters": letter_count,
        "connection_instructions": len(connection_programs.ops),
        "connection_unique_expressions": connection_programs.unique_expression_count,
        "dlog_instructions": len(dlog_programs.ops),
    }), flush=True)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="family-dlog-flint-") as temp_name, \
            GPUBackend() as gpu:
        temp = Path(temp_name)
        pivot_reference = None
        modular_solutions: list[tuple[int, np.ndarray, list[int]]] = []
        reconstructed = None
        reconstructed_modulus = 1
        fresh_prime = None
        for prime_index, prime in enumerate(primes[:args.max_primes]):
            request = make_request(prime, symbols, roots,
                                   args.training_points + args.validation_points,
                                   args.seed + 1000 * prime_index)
            started = time.perf_counter()
            connection_values, connection_timing = gpu.evaluate(request, connection_programs)
            dlog_values, dlog_timing = gpu.evaluate(request, dlog_programs)
            matrix, rhs = design_and_rhs(connection_values, dlog_values, request,
                                         dimension, letter_count)
            training_rows = 2 * request.grade_count * args.training_points
            train_matrix, validation_matrix = matrix[:training_rows], matrix[training_rows:]
            train_rhs, validation_rhs = rhs[:training_rows], rhs[training_rows:]
            pivots, independent = flint_pivots(train_matrix, prime, args.rref, temp,
                                               args.threads)
            if pivot_reference is None:
                pivot_reference = pivots
            if pivots != pivot_reference:
                print(json.dumps({"phase": "prime_rejected", "prime": prime,
                                  "reason": "pivot_mismatch", "rank": len(pivots)}),
                      flush=True)
                continue
            core = train_matrix[np.ix_(independent, pivots)]
            core_rhs = train_rhs[independent]
            coefficients = flint_solve(core, core_rhs, prime, args.solve, temp,
                                       args.threads)
            train_ok = np.array_equal(
                modular_product(train_matrix[:, pivots], coefficients, prime),
                train_rhs % prime,
            )
            validation_ok = np.array_equal(
                modular_product(validation_matrix[:, pivots], coefficients, prime),
                validation_rhs % prime,
            )
            print(json.dumps({
                "phase": "prime", "prime": prime, "rank": len(pivots),
                "training_ok": bool(train_ok), "validation_ok": bool(validation_ok),
                "connection_gpu_seconds": round(connection_timing["kernel_s"], 6),
                "dlog_gpu_seconds": round(dlog_timing["kernel_s"], 6),
                "prime_seconds": round(time.perf_counter() - started, 3),
            }), flush=True)
            if not train_ok or not validation_ok:
                raise RuntimeError("common dlog residue system failed pointwise replay")
            if reconstructed is not None:
                reduced = reduce_reconstruction(reconstructed, prime)
                if reduced is not None and np.array_equal(reduced, coefficients):
                    fresh_prime = prime
                    print(json.dumps({"phase": "fresh_prime", "prime": prime,
                                      "residue_match": True,
                                      "pointwise_replay": True}), flush=True)
                    break
                print(json.dumps({"phase": "fresh_prime_rejected", "prime": prime,
                                  "reason": "lift_mismatch_or_exceptional_denominator"}),
                      flush=True)
                reconstructed = None
            modular_solutions.append((prime, coefficients, pivots))
            if len(modular_solutions) >= args.crt_primes:
                reconstructed, reconstructed_modulus, failed = \
                    reconstruct_coefficients(modular_solutions)
                print(json.dumps({
                    "phase": "rational_reconstruction",
                    "crt_primes": len(modular_solutions),
                    "modulus_bits": reconstructed_modulus.bit_length(),
                    "failed_coordinates": failed,
                }), flush=True)
        if reconstructed is None or fresh_prime is None:
            raise RuntimeError("rational residue lift did not pass a fresh prime")
        write_dlog_record(
            args.output, args.sidecar, reconstructed, pivot_reference,
            dimension, letter_count,
            [prime for prime, _, _ in modular_solutions], fresh_prime,
            args.training_points, args.validation_points,
            time.perf_counter() - run_started,
        )
        print(json.dumps({
            "phase": "done", "status": "ComputedDLogResidues",
            "output": str(args.output), "bytes": args.output.stat().st_size,
            "crt_primes": len(modular_solutions), "fresh_prime": fresh_prime,
            "modulus_bits": reconstructed_modulus.bit_length(),
            "seconds": round(time.perf_counter() - run_started, 3),
        }), flush=True)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    result.add_argument("family", type=Path)
    result.add_argument("sidecar", type=Path)
    result.add_argument("output", type=Path)
    result.add_argument("--cache", type=Path, required=True)
    result.add_argument("--rref", type=Path, required=True)
    result.add_argument("--solve", type=Path, required=True)
    result.add_argument("--training-points", type=int, default=9)
    result.add_argument("--validation-points", type=int, default=2)
    result.add_argument("--crt-primes", type=int, default=3)
    result.add_argument("--max-primes", type=int, default=8)
    result.add_argument("--threads", type=int, default=8)
    result.add_argument("--seed", type=int, default=259091)
    return result


if __name__ == "__main__":
    run(parser().parse_args())
