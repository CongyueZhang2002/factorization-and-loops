#!/usr/bin/env python3
"""Differential and refusal tests for flint_deferred_ast_eval."""

import argparse
import pathlib
import struct
import subprocess
import tempfile


HERE = pathlib.Path(__file__).resolve().parent
FIXTURE = HERE / "Fixtures"


def expected_rows(name):
    rows = []
    for line in (FIXTURE / name).read_text().splitlines():
        if line and not line.startswith("#"):
            rows.append(tuple(map(int, line.split("\t"))))
    return rows


def output_record(path):
    payload = pathlib.Path(path).read_bytes()
    if len(payload) < 112 or payload[:8] != b"DAGO1V1\0":
        raise AssertionError("bad output magic/length")
    fields = struct.unpack_from("<13Q", payload, 8)
    status = fields[0]
    header = fields[1:]
    base_count, grade_count, record_count = header[2:5]
    offset = 112
    rows = []
    if status == 0:
        for _ in range(record_count):
            target = struct.unpack_from("<3Q", payload, offset)
            offset += 24
            values = struct.unpack_from(
                f"<{base_count * grade_count}Q", payload, offset
            )
            offset += 8 * base_count * grade_count
            rows.append(target + values)
    if offset != len(payload):
        raise AssertionError(f"trailing bytes: {len(payload) - offset}")
    return status, header, rows


def invoke(binary, input_name, request_name, output):
    return subprocess.run(
        [str(binary), str(FIXTURE / input_name),
         str(FIXTURE / request_name), str(output)],
        text=True, capture_output=True, check=False,
    )


def differential(binary, input_name, request_name, expected_name):
    with tempfile.TemporaryDirectory(prefix="deferred-ast-test-") as directory:
        output = pathlib.Path(directory) / "output.bin"
        run = invoke(binary, input_name, request_name, output)
        status, header, rows = output_record(output)
    if run.returncode != 0 or status != 0:
        raise AssertionError(
            f"backend refused {input_name}/{request_name}: "
            f"exit={run.returncode}, status={status}, stderr={run.stderr}"
        )
    expected = expected_rows(expected_name)
    if rows != expected:
        raise AssertionError(
            f"differential mismatch {input_name}/{request_name}:\n"
            f"observed={rows}\nexpected={expected}"
        )
    return header


def refusal(binary, input_path, request_path, expected_status):
    with tempfile.TemporaryDirectory(prefix="deferred-ast-refusal-") as directory:
        output = pathlib.Path(directory) / "output.bin"
        run = subprocess.run(
            [str(binary), str(input_path), str(request_path), str(output)],
            text=True, capture_output=True, check=False,
        )
        status, _, _ = output_record(output)
    if run.returncode != expected_status or status != expected_status:
        raise AssertionError(
            f"expected refusal {expected_status}, got "
            f"exit={run.returncode}, status={status}, stderr={run.stderr}"
        )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", required=True, type=pathlib.Path)
    args = parser.parse_args()
    if not args.binary.is_file():
        raise AssertionError(f"binary not found: {args.binary}")

    rank0 = differential(
        args.binary, "deferred_ast_rank0_input.wl",
        "deferred_ast_rank0_request.txt", "deferred_ast_rank0_expected.tsv"
    )
    dynamic = differential(
        args.binary, "deferred_ast_rank0_input.wl",
        "deferred_ast_rank0_dynamic_request.txt",
        "deferred_ast_rank0_dynamic_expected.tsv"
    )
    rank3 = differential(
        args.binary, "deferred_ast_rank3_input.wl",
        "deferred_ast_rank3_request.txt", "deferred_ast_rank3_expected.tsv"
    )
    half_powers = differential(
        args.binary, "deferred_ast_half_powers_input.wl",
        "deferred_ast_rank3_request.txt",
        "deferred_ast_half_powers_expected.tsv"
    )
    wide = differential(
        args.binary, "deferred_ast_rank3_input.wl",
        "deferred_ast_rank3_wide_request.txt", "deferred_ast_rank3_expected.tsv"
    )

    with tempfile.TemporaryDirectory(prefix="deferred-ast-bad-root-") as directory:
        request = pathlib.Path(directory) / "request.txt"
        text = (FIXTURE / "deferred_ast_rank3_request.txt").read_text()
        request.write_text(text.replace(
            "image 4 9 7 4 2 9 3 14 32",
            "image 4 9 7 4 2 9 3 14 31",
        ))
        refusal(
            args.binary, FIXTURE / "deferred_ast_rank3_input.wl",
            request, 11,
        )

    with tempfile.TemporaryDirectory(prefix="deferred-ast-radical-") as directory:
        input_path = pathlib.Path(directory) / "input.wl"
        input_path.write_text(
            '<|"DeferredPreparation" -> <|"Preparation" -> <|'
            '"DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 2, '
            '"Status" -> "Prepared", "Records" -> {<|'
            '"Target" -> {1,1,1}, "Terms" -> {<|'
            '"Coefficient" -> 1, "Operands" -> {Sqrt[x]}|>}|>}|>|>|>'
        )
        refusal(
            args.binary, input_path,
            FIXTURE / "deferred_ast_rank0_request.txt", 9,
        )

    with tempfile.TemporaryDirectory(prefix="deferred-ast-half-power-") as directory:
        input_path = pathlib.Path(directory) / "input.wl"
        input_path.write_text(
            '<|"DeferredPreparation" -> <|"Preparation" -> <|'
            '"DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 2, '
            '"Status" -> "Prepared", "Records" -> {<|'
            '"Target" -> {1,1,1}, "Terms" -> {<|'
            '"Coefficient" -> 1, "Operands" -> {(x+y)^(1/2)}|>}|>}|>|>|>'
        )
        refusal(
            args.binary, input_path,
            FIXTURE / "deferred_ast_rank3_request.txt", 9,
        )
        input_path.write_text(input_path.read_text().replace(
            "(x+y)^(1/2)", "x^(1/3)"
        ))
        refusal(
            args.binary, input_path,
            FIXTURE / "deferred_ast_rank3_request.txt", 8,
        )

    with tempfile.TemporaryDirectory(prefix="deferred-ast-schema-") as directory:
        input_path = pathlib.Path(directory) / "input.wl"
        input_path.write_text(
            '<|"DeferredPreparation" -> <|"Preparation" -> <|'
            '"DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 2, '
            '"Status" -> "Prepared", "Records" -> {<|'
            '"Target" -> {1,1}, "Terms" -> {<|'
            '"Coefficient" -> 1, "Operands" -> {x}|>}|>}|>|>|>'
        )
        refusal(
            args.binary, input_path,
            FIXTURE / "deferred_ast_rank0_request.txt", 7,
        )

    schema_refusals = [
        '"Status" -> "Prepared", '
        '"ABIVersion" -> "BlockEquationDeferredV1", ',
        '"DataType" -> "WrongType", "SchemaVersion" -> 2, '
        '"Status" -> "Prepared", ',
        '"DataType" -> "DeferredBlockEquation", "Status" -> "Prepared", ',
        '"DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 1, '
        '"Status" -> "Prepared", ',
        '"DataType" -> "DeferredBlockEquation", "SchemaVersion" -> "2", '
        '"Status" -> "Prepared", ',
        '"DataType" -> "DeferredBlockEquation", "SchemaVersion" -> 2.0, '
        '"Status" -> "Prepared", ',
    ]
    for index, header in enumerate(schema_refusals):
        with tempfile.TemporaryDirectory(
                prefix=f"deferred-ast-schema-refusal-{index}-") as directory:
            input_path = pathlib.Path(directory) / "input.wl"
            input_path.write_text(
                '<|"DeferredPreparation" -> <|"Preparation" -> <|'
                + header
                + '"Records" -> {<|"Target" -> {1,1,1}, "Terms" -> {'
                  '<|"Coefficient" -> 1, "Operands" -> {x}|>}|>}|>|>|>'
            )
            refusal(
                args.binary, input_path,
                FIXTURE / "deferred_ast_rank0_request.txt", 7,
            )

    print(
        "PASS deferred_ast_native_backend",
        f"rank0_base={rank0[2]}",
        f"dynamic_base={dynamic[2]}",
        f"rank3_grades={rank3[3]}",
        f"half_power_grades={half_powers[3]}",
        f"wide_prime={wide[0]}",
        "typed_refusals=11",
    )


if __name__ == "__main__":
    main()
