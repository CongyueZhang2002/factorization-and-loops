#!/usr/bin/env python3
"""Focused rank-3 reference test for DAPJ1V1 (no Wolfram kernel)."""

from __future__ import annotations

import argparse
import pathlib
import struct
import subprocess
import tempfile
import time

P = 2305843009213693951
ORDER = 16
EPSILONS = (7, 11, 13, 17, 19, 23, 29, 31)


def add(a, b):
    return [(x + y) % P for x, y in zip(a, b)]


def scale(a, scalar):
    return [(scalar * x) % P for x in a]


def mul(a, b):
    out = [0] * len(a)
    for n in range(len(a)):
        out[n] = sum(a[k] * b[n - k] for k in range(n + 1)) % P
    return out


def inv(a):
    assert a[0]
    out = [0] * len(a)
    out[0] = pow(a[0], P - 2, P)
    for n in range(1, len(a)):
        out[n] = -out[0] * sum(a[k] * out[n - k] for k in range(1, n + 1)) % P
    return out


def power(a, exponent):
    if exponent < 0:
        return power(inv(a), -exponent)
    out = [1] + [0] * (len(a) - 1)
    base = list(a)
    while exponent:
        if exponent & 1:
            out = mul(out, base)
        exponent >>= 1
        if exponent:
            base = mul(base, base)
    return out


def series_line(label, values):
    return label + " " + " ".join(str(value % P) for value in values)


def preparation_text():
    expressions = [
        ("1/Sqrt[x^2] + eps*(x + y)", []),
        ("1", ["Sqrt[(1 + y)^2]", "Sqrt[(x + y)^2]"]),
        ("(x^2)^(-3/2)", []),
        ("Sqrt[x^2]/(1 + x)", ["eps + 2"]),
    ]
    records = []
    for index, (coefficient, operands) in enumerate(expressions):
        row, column = divmod(index, 2)
        operand_text = ", ".join(operands)
        records.append(
            '<|"Target" -> {%d, %d, %d}, "Terms" -> {'
            '<|"Coefficient" -> %s, "Operands" -> {%s}|>}|>'
            % (1, row + 1, column + 1, coefficient, operand_text)
        )
    return (
        '<|"DeferredPreparation" -> <|"Preparation" -> '
        '<|"Status" -> "Prepared", "ABIVersion" -> '
        '"BlockEquationDeferredV1", "Records" -> {'
        + ",\n".join(records)
        + "}|>|>|>\n"
    )


def fixture(signs):
    zeros = [0] * (ORDER - 1)
    x = [2, 1] + zeros
    y = [3, 2] + zeros
    one = [1] + [0] * ORDER
    roots_plus = [x, add(one, y), add(x, y)]
    roots = [scale(root, sign) for root, sign in zip(roots_plus, signs)]
    deltas = [mul(root, root) for root in roots]
    lines = [
        "DeferredPathJetRequestV1",
        f"prime {P}",
        "variables x y eps",
        f"order {ORDER}",
        "rank 3",
        "root x^2",
        "root (1 + y)^2",
        "root (x + y)^2",
        f"epsilon_count {len(EPSILONS)}",
        *(f"epsilon {epsilon}" for epsilon in EPSILONS),
        series_line("x_jet", x),
        series_line("y_jet", y),
    ]
    for delta, root in zip(deltas, roots):
        lines.append(series_line("delta_jet", delta))
        lines.append(series_line("root_jet", root))
    expected = []
    for epsilon in EPSILONS:
        eps_series = [epsilon] + [0] * ORDER
        expected.append([
            add(inv(roots[0]), mul(eps_series, add(x, y))),
            mul(roots[1], roots[2]),
            mul(power(deltas[0], -2), roots[0]),
            mul(mul(roots[0], inv(add(one, x))),
                add(eps_series, scale(one, 2))),
        ])
    by_record = [
        [expected[e][record] for e in range(len(EPSILONS))]
        for record in range(4)
    ]
    return "\n".join(lines) + "\n", by_record


def read_output(path):
    data = path.read_bytes()
    assert data[:8] == b"DAPJ1V1\0"
    status = struct.unpack_from("<Q", data, 8)[0]
    header = struct.unpack_from("<12Q", data, 16)
    if status:
        return status, header, []
    prime, order, rank, epsilon_count, record_count = header[:5]
    assert (prime, order, rank, epsilon_count, record_count) == (
        P, ORDER, 3, len(EPSILONS), 4
    )
    offset = 16 + 12 * 8
    records = []
    channel_count = epsilon_count * (order + 1)
    for _ in range(record_count):
        target = struct.unpack_from("<3Q", data, offset)
        offset += 24
        flat = struct.unpack_from(f"<{channel_count}Q", data, offset)
        offset += 8 * channel_count
        channels = [
            list(flat[e * (order + 1):(e + 1) * (order + 1)])
            for e in range(epsilon_count)
        ]
        records.append((target, channels))
    assert offset == len(data)
    return status, header, records


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", type=pathlib.Path,
                        default=pathlib.Path(__file__).parent / "bin" /
                                "flint_deferred_path_jet")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="dapj1_test_") as temporary:
        directory = pathlib.Path(temporary)
        preparation = directory / "fixture.wl"
        preparation.write_text(preparation_text())
        elapsed = []
        for sheet, signs in (("plus", (1, 1, 1)),
                             ("mixed", (-1, 1, -1))):
            request_text, expected = fixture(signs)
            request = directory / f"{sheet}.txt"
            output = directory / f"{sheet}.bin"
            request.write_text(request_text)
            started = time.perf_counter()
            completed = subprocess.run(
                [str(args.binary), str(preparation), str(request), str(output),
                 "--threads", "8"], check=False, text=True,
                capture_output=True,
            )
            elapsed.append(time.perf_counter() - started)
            assert completed.returncode == 0, completed.stderr
            status, _, records = read_output(output)
            assert status == 0
            assert [target for target, _ in records] == [
                (1, 1, 1), (1, 1, 2), (1, 2, 1), (1, 2, 2)
            ]
            for record_index, (_, actual) in enumerate(records):
                assert actual == expected[record_index], (
                    sheet, record_index, actual, expected[record_index]
                )

        # A supplied root that no longer squares to its delta is a typed
        # RootValueMismatch, not an unchecked sheet change.
        bad_text, _ = fixture((1, 1, 1))
        bad_lines = bad_text.splitlines()
        first_delta = next(i for i, line in enumerate(bad_lines)
                           if line.startswith("delta_jet "))
        fields = bad_lines[first_delta].split()
        fields[1] = str((int(fields[1]) + 1) % P)
        bad_lines[first_delta] = " ".join(fields)
        bad_request = directory / "bad.txt"
        bad_output = directory / "bad.bin"
        bad_request.write_text("\n".join(bad_lines) + "\n")
        bad = subprocess.run(
            [str(args.binary), str(preparation), str(bad_request),
             str(bad_output)], check=False, text=True, capture_output=True,
        )
        status, _, _ = read_output(bad_output)
        assert bad.returncode == 11 and status == 11, bad.stderr

        # A root jet may square correctly while authenticating the wrong
        # declared radicand.  That is the distinct RootSquareMismatch type.
        wrong_square_lines = fixture((1, 1, 1))[0].splitlines()
        wrong_square_lines[5] = "root (1 + x)^2"
        wrong_square_request = directory / "wrong_square.txt"
        wrong_square_output = directory / "wrong_square.bin"
        wrong_square_request.write_text("\n".join(wrong_square_lines) + "\n")
        wrong_square = subprocess.run(
            [str(args.binary), str(preparation), str(wrong_square_request),
             str(wrong_square_output)], check=False, text=True,
            capture_output=True,
        )
        status, _, _ = read_output(wrong_square_output)
        assert wrong_square.returncode == 12 and status == 12, wrong_square.stderr

    print("DAPJ1 rank-3 reference: PASS; two sheets, eight eps images, "
          f"order {ORDER}; wall seconds {elapsed}")


if __name__ == "__main__":
    main()
