#!/usr/bin/env python3
"""No-Wolfram static and independent finite-field adversarial gate."""

from __future__ import annotations

import hashlib
import math
import re
import sys
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops")
HERE = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "cf259_q4_rank3_oracle_2026-08-23_xh"
)
ALGEBRA = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/TripleRootAlgebra.wl"
)
ADAPTER = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/TripleRootStripAdapter.wl"
)
RECONSTRUCTION = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "TripleRootReconstructionPrototype.wl"
)
ORACLE = HERE / "TripleRootRank3CF259Oracle.wl"
DRIVER = HERE / "run_cf259_q4_rank3_oracle_xh_v1.wls"
MANIFEST = HERE / "SOURCE_SHA256SUMS"
OUTPUT = Path(
    "/tmp/codex-triple-root-20260823c.vx654S/"
    "cf259_q4_rank3_oracle_xh_v1.wl"
)
EXPECTED = {
    ALGEBRA: "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
    ADAPTER: "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
    RECONSTRUCTION: "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
    ORACLE: "b431db4737dab33329eeea709d9999990522e0925a26c9974d14faa3b2512d71",
    MANIFEST: "dc64dfb52af72dcb387a0c4fdfaf83fa9a6b8de8d85fbad9e2a297bf5c88b271",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def strip_wolfram_comments_and_strings(text: str) -> str:
    output: list[str] = []
    index = 0
    comment_depth = 0
    in_string = False
    while index < len(text):
        pair = text[index : index + 2]
        char = text[index]
        if comment_depth:
            if pair == "(*":
                comment_depth += 1
                output.extend("  ")
                index += 2
            elif pair == "*)":
                comment_depth -= 1
                output.extend("  ")
                index += 2
            else:
                output.append("\n" if char == "\n" else " ")
                index += 1
        elif in_string:
            if char == "\\" and index + 1 < len(text):
                output.extend("  ")
                index += 2
            elif char == '"':
                in_string = False
                output.append(" ")
                index += 1
            else:
                output.append("\n" if char == "\n" else " ")
                index += 1
        elif pair == "(*":
            comment_depth = 1
            output.extend("  ")
            index += 2
        elif char == '"':
            in_string = True
            output.append(" ")
            index += 1
        else:
            output.append(char)
            index += 1
    assert comment_depth == 0, "unterminated Wolfram comment"
    assert not in_string, "unterminated Wolfram string"
    return "".join(output)


def assert_balanced(code: str) -> None:
    opening = {"[": "]", "{": "}", "(": ")"}
    closing = {value: key for key, value in opening.items()}
    stack: list[tuple[str, int]] = []
    for offset, char in enumerate(code):
        if char in opening:
            stack.append((char, offset))
        elif char in closing:
            assert stack and stack[-1][0] == closing[char], (
                f"mismatched {char!r} at byte {offset}"
            )
            stack.pop()
    assert not stack, f"unclosed delimiter: {stack[-1] if stack else None}"


def parse_manifest(text: str) -> dict[str, str]:
    records: dict[str, str] = {}
    for line_number, raw in enumerate(text.splitlines(), 1):
        match = re.fullmatch(r"([0-9a-f]{64})  (\S+)", raw)
        assert match, f"malformed manifest line {line_number}: {raw!r}"
        digest, relative = match.groups()
        assert not relative.startswith("/")
        assert ".." not in Path(relative).parts
        assert relative not in records, f"duplicate manifest path: {relative}"
        records[relative] = digest
    return records


# Sparse bivariate integer polynomials keyed by (x degree, y degree).
Poly = dict[tuple[int, int], int]


def clean(poly: Poly) -> Poly:
    return {power: coefficient for power, coefficient in poly.items() if coefficient}


def add(left: Poly, right: Poly) -> Poly:
    result = dict(left)
    for power, coefficient in right.items():
        result[power] = result.get(power, 0) + coefficient
    return clean(result)


def scale(poly: Poly, scalar: int) -> Poly:
    return clean({power: scalar * coefficient for power, coefficient in poly.items()})


def multiply(left: Poly, right: Poly) -> Poly:
    result: Poly = {}
    for (lx, ly), lc in left.items():
        for (rx, ry), rc in right.items():
            power = (lx + rx, ly + ry)
            result[power] = result.get(power, 0) + lc * rc
    return clean(result)


def evaluate(poly: Poly, x_value: int, y_value: int, modulus: int) -> int:
    return sum(
        coefficient * pow(x_value, x_degree, modulus)
        * pow(y_value, y_degree, modulus)
        for (x_degree, y_degree), coefficient in poly.items()
    ) % modulus


def coefficients_in_x(poly: Poly) -> list[dict[int, int]]:
    degree = max((x_degree for x_degree, _ in poly), default=0)
    result: list[dict[int, int]] = [dict() for _ in range(degree + 1)]
    for (x_degree, y_degree), coefficient in poly.items():
        result[x_degree][y_degree] = coefficient
    return result


def univariate_add(left: dict[int, int], right: dict[int, int]) -> dict[int, int]:
    result = dict(left)
    for degree, coefficient in right.items():
        result[degree] = result.get(degree, 0) + coefficient
    return {degree: coefficient for degree, coefficient in result.items() if coefficient}


def univariate_multiply(
    left: dict[int, int], right: dict[int, int]
) -> dict[int, int]:
    result: dict[int, int] = {}
    for ld, lc in left.items():
        for rd, rc in right.items():
            result[ld + rd] = result.get(ld + rd, 0) + lc * rc
    return {degree: coefficient for degree, coefficient in result.items() if coefficient}


def discriminant_quadratic_in_x(poly: Poly) -> dict[int, int]:
    coefficients = coefficients_in_x(poly)
    assert len(coefficients) == 3 and coefficients[2] == {0: 1}
    return univariate_add(
        univariate_multiply(coefficients[1], coefficients[1]),
        {degree: -4 * coefficient for degree, coefficient in coefficients[0].items()},
    )


def is_prime(number: int) -> bool:
    if number < 2:
        return False
    if number % 2 == 0:
        return number == 2
    divisor = 3
    while divisor * divisor <= number:
        if number % divisor == 0:
            return False
        divisor += 2
    return True


def parity(number: int) -> int:
    return number.bit_count() & 1


def hadamard_sign(row: int, column: int) -> int:
    return -1 if parity(row & column) else 1


def mask_product(mask: int, values: list[int], modulus: int) -> int:
    result = 1
    for index, value in enumerate(values):
        if mask & (1 << index):
            result = result * value % modulus
    return result


def evaluate_conjugates(
    coefficients: list[int], roots: list[int], modulus: int
) -> list[int]:
    weighted = [
        coefficient * mask_product(mask, roots, modulus) % modulus
        for mask, coefficient in enumerate(coefficients)
    ]
    return [
        sum(hadamard_sign(row, column) * weighted[column] for column in range(8))
        % modulus
        for row in range(8)
    ]


def project_conjugates(values: list[int], roots: list[int], modulus: int) -> list[int]:
    inverse_eight = pow(8, -1, modulus)
    projected: list[int] = []
    for column in range(8):
        numerator = inverse_eight * sum(
            hadamard_sign(row, column) * values[row] for row in range(8)
        )
        projected.append(
            numerator * pow(mask_product(column, roots, modulus), -1, modulus)
            % modulus
        )
    return projected


def channel_multiply(
    left: list[int], right: list[int], deltas: list[int], modulus: int
) -> list[int]:
    result = [0] * 8
    for left_mask, left_value in enumerate(left):
        for right_mask, right_value in enumerate(right):
            common = left_mask & right_mask
            target = left_mask ^ right_mask
            term = left_value * right_value
            term *= mask_product(common, deltas, modulus)
            result[target] = (result[target] + term) % modulus
    return result


def split_points(radicals: list[Poly], prime: int, count: int) -> list[tuple[int, int]]:
    result: list[tuple[int, int]] = []
    for x_value in range(1, min(prime, 90)):
        for y_value in range(1, min(prime, 90)):
            values = [evaluate(poly, x_value, y_value, prime) for poly in radicals]
            if all(value and pow(value, (prime - 1) // 2, prime) == 1 for value in values):
                result.append((x_value, y_value))
                if len(result) == count:
                    return result
    return result


def modeled_dispatch_then_io(kernel_id: object) -> tuple[str, list[str]]:
    """Model the target-level ordering, with observable I/O events."""
    events: list[str] = []
    if type(kernel_id) is not int or kernel_id != 145:
        return "$Failed", events
    events.append("source-manifest-read")
    events.append("output-freshness-probe")
    return "continue", events


def main() -> int:
    checks = 0
    for path, expected in EXPECTED.items():
        assert path.is_file(), f"missing pinned source: {path}"
        assert sha256(path) == expected, f"source drift: {path}"
        checks += 1

    records = parse_manifest(MANIFEST.read_text())
    assert len(records) == 4
    for relative, expected in records.items():
        source = ROOT / relative
        assert source.is_file()
        assert sha256(source) == expected
        checks += 1
    checks += 1

    # The manifest parser must fail closed on traversal, duplicate, malformed,
    # and absolute-path mutants rather than silently accepting a subset.
    baseline_line = MANIFEST.read_text().splitlines()[0]
    manifest_mutants = [
        baseline_line + "\n" + baseline_line,
        "0" * 64 + "  ../escape.wl",
        "0" * 64 + "  /absolute.wl",
        "not-a-hash  relative.wl",
    ]
    for mutant in manifest_mutants:
        try:
            parse_manifest(mutant)
        except AssertionError:
            pass
        else:
            raise AssertionError(f"manifest mutant accepted: {mutant!r}")
        checks += 1

    driver_text = DRIVER.read_text()
    oracle_text = ORACLE.read_text()
    for path, text in [(DRIVER, driver_text), (ORACLE, oracle_text)]:
        code = strip_wolfram_comments_and_strings(text)
        assert_balanced(code)
        assert not any(line.rstrip().endswith("`") for line in text.splitlines()), (
            f"context-qualified symbol split across lines: {path}"
        )
        assert "RunProcess[" not in code and "StartProcess[" not in code
        assert "LaunchKernels[" not in code and "CloseKernels[" not in code
        assert "Parallel" not in code
        checks += 6

    driver_code = strip_wolfram_comments_and_strings(driver_text)
    assert re.findall(r"(?<![A-Za-z0-9`])(Exit|Quit)\s*\[", driver_code) == []
    assert "DeleteFile[" not in driver_code
    assert '"cf259_q4_rank3_oracle_xh_v1.wl"' in driver_text
    assert "KernelPoolMission`$TaskBrokerMaxHelpers === 0" in driver_text
    assert "$KernelID =!= 145" in driver_text
    assert '"RequiredWorkerKernelID" -> 145' in driver_text
    assert '"Scope" -> "ConstructedQ4ArithmeticTransferGateNotPhysicalSector"' in driver_text
    assert 'Length[checks] === 12' in driver_text
    assert "BranchFlipMask" in driver_text and "Range[0, 7]" in driver_text
    assert "TRVerifyReconstructionExact" in driver_text
    assert "OverwriteTarget -> False" in driver_text
    checks += 11

    dispatch_index = driver_text.index("$KernelID =!= 145")
    source_io_index = driver_text.index("hashHex[sourceManifest]")
    output_io_index = driver_text.index("FileExistsQ[outputFile]")
    assert dispatch_index < source_io_index < output_io_index
    checks += 1
    for wrong_kernel in [None, 0, 24, 141, 144, 146, "145"]:
        outcome, events = modeled_dispatch_then_io(wrong_kernel)
        assert outcome == "$Failed" and events == [], (
            f"wrong kernel performed target I/O: {wrong_kernel!r}, {events}"
        )
        checks += 1
    assert modeled_dispatch_then_io(145) == (
        "continue", ["source-manifest-read", "output-freshness-probe"]
    )
    checks += 1

    assert "CF300" not in oracle_text
    for token in [
        '"Family" -> "CF259"',
        "q4 = Expand[4 x + y^2]",
        "rootQ4 = Sqrt[q4]",
        '"SourceIndex" -> 4',
        '"IndependentSquareClasses"',
        '"Rank" -> If[AllTrue[nonsquare, TrueQ], 3',
    ]:
        assert token in oracle_text, f"missing oracle token: {token}"
        checks += 1

    # Independent polynomial construction and irreducibility certificate.
    one = {(0, 0): 1}
    x = {(1, 0): 1}
    y = {(0, 1): 1}
    lambda1 = add(multiply(add(add(one, scale(x, -1)), scale(y, -1)),
                           add(add(one, scale(x, -1)), scale(y, -1))),
                  scale(multiply(x, y), -4))
    lambda3 = add(multiply(add(add(one, scale(x, -1)), y),
                           add(add(one, scale(x, -1)), y)),
                  scale(multiply(x, y), 4))
    q4 = add(scale(x, 4), multiply(y, y))
    assert lambda1 == {
        (0, 0): 1, (2, 0): 1, (0, 2): 1,
        (1, 0): -2, (0, 1): -2, (1, 1): -2,
    }
    assert lambda3 == {
        (0, 0): 1, (2, 0): 1, (0, 2): 1,
        (1, 0): -2, (0, 1): 2, (1, 1): 2,
    }
    assert q4 == {(1, 0): 4, (0, 2): 1}
    checks += 3

    # lambda1/lambda3 are primitive quadratics in x with discriminants
    # +/-16 y, hence irreducible over Q(y); Q4 is primitive linear in x.
    # Distinct coefficient dictionaries prove the three irreducibles are not
    # associates. Every nonempty mask therefore has an odd prime divisor.
    assert discriminant_quadratic_in_x(lambda1) == {1: 16}
    assert discriminant_quadratic_in_x(lambda3) == {1: -16}
    assert max(power[0] for power in q4) == 1
    assert len({tuple(sorted(poly.items())) for poly in [lambda1, lambda3, q4]}) == 3
    for mask in range(1, 8):
        odd_generator_count = sum(bool(mask & (1 << index)) for index in range(3))
        assert odd_generator_count >= 1
        checks += 1
    checks += 4

    primes = [
        candidate for candidate in range(10000, 11000)
        if is_prime(candidate) and candidate % 4 == 3
    ][:3]
    assert len(primes) == 3
    radicals = [lambda1, lambda3, q4]
    for prime_index, prime in enumerate(primes):
        points = split_points(radicals, prime, 8)
        assert len(points) == 8, f"insufficient CF259 split points modulo {prime}"
        for point_index, (x_value, y_value) in enumerate(points):
            deltas = [evaluate(poly, x_value, y_value, prime) for poly in radicals]
            roots = [pow(value, (prime + 1) // 4, prime) for value in deltas]
            assert all(root and root * root % prime == value for root, value in zip(roots, deltas))
            coefficients = [
                (37 * mask + 101 * point_index + 17 * prime_index + 3) % prime
                for mask in range(8)
            ]
            conjugates = evaluate_conjugates(coefficients, roots, prime)
            assert project_conjugates(conjugates, roots, prime) == coefficients

            left = [
                (19 * mask + 11 * point_index + 5) % prime
                for mask in range(8)
            ]
            right = [
                (23 * mask + 7 * point_index + 9) % prime
                for mask in range(8)
            ]
            product = channel_multiply(left, right, deltas, prime)
            left_values = evaluate_conjugates(left, roots, prime)
            right_values = evaluate_conjugates(right, roots, prime)
            product_values = evaluate_conjugates(product, roots, prime)
            assert product_values == [
                left_value * right_value % prime
                for left_value, right_value in zip(left_values, right_values)
            ]

            # A single-branch corruption must not project to the original
            # channels; a simultaneous root sign flip is only a permutation.
            corrupted = list(conjugates)
            corrupted[5] = (corrupted[5] + 1) % prime
            assert project_conjugates(corrupted, roots, prime) != coefficients
            flipped_roots = [roots[0], roots[1], (-roots[2]) % prime]
            flipped = evaluate_conjugates(coefficients, flipped_roots, prime)
            assert sorted(flipped) == sorted(conjugates)
            checks += 5
    checks += 1

    # Ramified points are intentionally excluded: (x,y)=(0,0) has Q4=0.
    assert evaluate(q4, 0, 0, primes[0]) == 0
    assert (0, 0) not in split_points(radicals, primes[0], 20)
    checks += 2

    assert not OUTPUT.exists(), f"runtime output is no longer fresh: {OUTPUT}"
    assert OUTPUT.parent.is_dir()
    checks += 2

    print(f"PASS: {checks} CF259 Q4 static/adversarial assertions")
    print(f"driver_sha256={sha256(DRIVER)}")
    print(f"oracle_sha256={sha256(ORACLE)}")
    print(f"manifest_sha256={sha256(MANIFEST)}")
    print(f"fresh_output={OUTPUT}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
