#!/usr/bin/env python3
"""Bounded exact tests against preserved TSVs and an independent CPU batch."""

from array import array
from pathlib import Path
import tempfile

from deferred_gpu import (
    ExpressionCompiler, Request, authenticate_roots, canonical_channels,
    compile_preparation, cpu_program,
    gpu_evaluate, mont_mul, nprime32, parse_request,
)


HERE = Path(__file__).resolve().parent
FIXTURES = HERE.parents[2] / "Tests" / "Multiquadratic" / "Fixtures"


def expected(path: Path) -> list[int]:
    values = []
    for line in path.read_text().splitlines():
        if line and not line.startswith("#"):
            values.extend(map(int, line.split("\t")[3:]))
    return values


def fixture(input_name: str, request_name: str) -> None:
    request = parse_request(FIXTURES / f"{request_name}_request.txt")
    authenticate_roots(request)
    programs = compile_preparation(FIXTURES / f"{input_name}_input.wl", request)
    observed, _ = gpu_evaluate(request, programs, 1024)
    wanted = expected(FIXTURES / f"{request_name}_expected.tsv")
    if observed.tolist() != wanted:
        raise AssertionError(f"{request_name}: {observed.tolist()} != {wanted}")
    print(f"PASS fixture={request_name} values={len(wanted)}")


def synthetic_batch() -> None:
    p = 2147483423
    bases = [(2, 5, 3), (3, 7, 4), (4, 9, 5), (6, 8, 7)]
    request_lines = [
        "DeferredASTRequestV1", f"prime {p}", "variables x y eps", "rank 3",
        "root x^2", "root y^2", "root (x+y)^2", f"base_count {len(bases)}",
    ]
    for x, y, eps in bases:
        request_lines.append(
            f"image {x} {y} {eps} {x*x%p} {x} {y*y%p} {y} "
            f"{(x+y)*(x+y)%p} {(x+y)%p}"
        )
    records = []
    for index in range(1, 33):
        records.append(
            '<|"Target" -> {1,1,' + str(index) + '}, "Terms" -> {'
            '<|"Coefficient" -> -((x+' + str(index) + ')^3+y*eps-'
            'Sqrt[x^2]*Sqrt[y^2]+((x+y)^2)^(3/2)+((x+y)^2)^(-3/2))/'
            '(1+eps^2), '
            '"Operands" -> {(x-y)^(-1),1+Sqrt[(x+y)^2]}|>,'
            '<|"Coefficient" -> ' + str(2 * index + 1) + ', '
            '"Operands" -> {Sqrt[x^2]+Sqrt[y^2]+Sqrt[(x+y)^2]}|>'
            '}|>'
        )
    preparation = (
        '<|"DeferredPreparation" -> <|"Preparation" -> <|'
        '"DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 2, '
        '"Status" -> "Prepared", '
        '"Records" -> {' + ",".join(records) + '}|>|>|>\n'
    )
    with tempfile.TemporaryDirectory(prefix="gpu31-deferred-test-") as directory:
        request_path = Path(directory) / "request.txt"
        input_path = Path(directory) / "input.wl"
        request_path.write_text("\n".join(request_lines) + "\n")
        input_path.write_text(preparation)
        request = parse_request(request_path)
        authenticate_roots(request)
        programs = compile_preparation(input_path, request)
    p, np, rmod = request.prime, nprime32(request.prime), (1 << 32) % request.prime
    mont_inputs = [[value * rmod % p for value in channel] for channel in request.inputs]
    mont_constants = [value % p * rmod % p for value in programs.constants]
    expression_values = array("I")
    instructions = list(zip(programs.ops, programs.args))
    for program in range(programs.unique_expression_count):
        code = instructions[programs.offsets[program]:programs.offsets[program + 1]]
        for image in range(request.image_count):
            expression_values.append(
                cpu_program(code, mont_inputs, image, p, np, rmod, mont_constants)
            )
    raw = array("I")
    for record in range(len(programs.targets)):
        for image in range(request.image_count):
            total = 0
            for term in range(programs.record_offsets[record],
                              programs.record_offsets[record + 1]):
                first = programs.term_offsets[term]
                product = expression_values[
                    programs.factors[first] * request.image_count + image
                ]
                for factor in range(first + 1, programs.term_offsets[term + 1]):
                    product = mont_mul(
                        product,
                        expression_values[
                            programs.factors[factor] * request.image_count + image
                        ],
                        p, np,
                    )
                total = (total + product) % p
            raw.append(total)
    cpu = [value for row in canonical_channels(raw, request) for value in row]
    gpu, timings = gpu_evaluate(request, programs, 2048)
    if gpu.tolist() != cpu:
        mismatch = next(i for i, (a, b) in enumerate(zip(gpu, cpu)) if a != b)
        raise AssertionError(f"synthetic mismatch {mismatch}: {gpu[mismatch]} != {cpu[mismatch]}")
    print(
        f"PASS synthetic records={len(programs.targets)} images={request.image_count} "
        f"instructions={len(programs.ops)} values={len(gpu)} "
        f"kernel_ms={timings['kernel_s'] * 1e3:.3f}"
    )


def half_integer_declared_root() -> None:
    p = 2147483423
    preparation = (
        '<|"DeferredPreparation" -> <|"Preparation" -> <|'
        '"DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 2, '
        '"Status" -> "Prepared", '
        '"Records" -> {'
        '<|"Target" -> {1,1,1}, "Terms" -> {'
        '<|"Coefficient" -> (x^2)^(3/2), "Operands" -> {1}|>}|>,'
        '<|"Target" -> {1,1,2}, "Terms" -> {'
        '<|"Coefficient" -> (x^2)^(-3/2), "Operands" -> {1}|>}|>'
        '}|>|>|>\n'
    )
    with tempfile.TemporaryDirectory(prefix="gpu31-half-power-test-") as directory:
        input_path = Path(directory) / "input.wl"
        input_path.write_text(preparation)
        request = Request(
            p, ("x", "y", "eps"), ("x^2",), 1, 2,
            [[3, 3], [5, 5], [7, 7], [3, p - 3]],
            [[9, 9]], [[3]],
        )
        authenticate_roots(request)
        programs = compile_preparation(input_path, request)
    observed, _ = gpu_evaluate(request, programs, 32)
    wanted = [0, 9, 0, pow(3, -4, p)]
    if observed.tolist() != wanted:
        raise AssertionError(f"half powers: {observed.tolist()} != {wanted}")
    print(f"PASS half_integer_declared_root values={len(wanted)}")


def power_followed_by_division() -> None:
    p = 2147483423
    request = Request(p, ("x", "y", "eps"), (), 1, 1,
                      [[3], [5], [7]], [], [])
    code = ExpressionCompiler("y^2/4", request).compile()
    rmod, np_value = (1 << 32) % p, nprime32(p)
    inputs = [[value * rmod % p] for value in (3, 5, 7)]
    observed = mont_mul(
        cpu_program(code, inputs, 0, p, np_value, rmod), 1, p, np_value
    )
    wanted = 25 * pow(4, -1, p) % p
    if observed != wanted:
        raise AssertionError(f"power/division precedence: {observed} != {wanted}")
    print("PASS power_followed_by_division")


def main() -> None:
    fixture("deferred_ast_rank0", "deferred_ast_rank0")
    fixture("deferred_ast_rank0", "deferred_ast_rank0_dynamic")
    fixture("deferred_ast_rank3", "deferred_ast_rank3")
    half_integer_declared_root()
    power_followed_by_division()
    synthetic_batch()


if __name__ == "__main__":
    main()
