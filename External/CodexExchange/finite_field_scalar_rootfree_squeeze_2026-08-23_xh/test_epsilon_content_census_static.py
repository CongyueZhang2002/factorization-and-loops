#!/usr/bin/env python3
"""No-kernel static and independent content-GCD audit for patch 0002."""

from __future__ import annotations

from fractions import Fraction
import hashlib
import pathlib
import random
import subprocess
import sys
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[3]
SOURCE = ROOT / (
    "External/CodexExchange/triple_root_2026-08-22/"
    "direct_root_channel_assembler_xh/"
    "run_cf300_sector12_rank2_direct_ansatz_discriminator_v2.wls"
)
PATCH = pathlib.Path(__file__).with_name(
    "0002-target-epsilon-free-factor-census.patch"
)
LEXICAL_GUARD = SOURCE.parent / "check_wl_no_kernel_parse_guard.pl"
EXPECTED_SOURCE_SHA256 = (
    "346b3bfe722e1049d02a1d032a40479e19b6866b34811477c8cc12f05e676f64"
)


def require(condition: bool, label: str) -> None:
    if not condition:
        raise AssertionError(label)


def trim(polynomial: list[Fraction]) -> list[Fraction]:
    result = polynomial[:]
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    return result or [Fraction(0)]


def multiply(left: list[Fraction], right: list[Fraction]) -> list[Fraction]:
    result = [Fraction(0)] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            result[i + j] += a * b
    return trim(result)


def divide_with_remainder(
    dividend: list[Fraction], divisor: list[Fraction]
) -> tuple[list[Fraction], list[Fraction]]:
    dividend = trim(dividend)
    divisor = trim(divisor)
    require(divisor != [0], "zero-divisor")
    if len(dividend) < len(divisor):
        return [Fraction(0)], dividend
    quotient = [Fraction(0)] * (len(dividend) - len(divisor) + 1)
    remainder = dividend[:]
    while remainder != [0] and len(remainder) >= len(divisor):
        degree = len(remainder) - len(divisor)
        coefficient = remainder[-1] / divisor[-1]
        quotient[degree] += coefficient
        for index, value in enumerate(divisor):
            remainder[degree + index] -= coefficient * value
        remainder = trim(remainder)
    return trim(quotient), remainder


def monic(polynomial: list[Fraction]) -> list[Fraction]:
    polynomial = trim(polynomial)
    if polynomial == [0]:
        return polynomial
    return [value / polynomial[-1] for value in polynomial]


def polynomial_gcd(left: list[Fraction], right: list[Fraction]) -> list[Fraction]:
    left, right = trim(left), trim(right)
    while right != [0]:
        _, remainder = divide_with_remainder(left, right)
        left, right = right, remainder
    return monic(left)


def coefficient_content(coefficients: list[list[Fraction]]) -> list[Fraction]:
    require(coefficients, "empty-coefficients")
    result = coefficients[0]
    for coefficient in coefficients[1:]:
        result = polynomial_gcd(result, coefficient)
    return monic(result)


def contract(text: str) -> bool:
    start = text.find("epsilonContents = Table[")
    end = text.find("rawEpsilonFreeFactors = Cases", start)
    if start < 0 or end < 0:
        return False
    section = text[start:end]
    required = [
        "CoefficientList[",
        "Fold[PolynomialGCD",
        "FreeQ[#1, epsilon]",
        "contentGroups = GatherBy",
        "EpsilonContentFingerprintCollision",
        "FactorList[Expand[content]]",
        "contentCertificates = MapThread",
        "Times @@ ((First[#1]^Last[#1]) & /@ factorization)",
        "EpsilonContentFactorizationCertificateFailed",
    ]
    forbidden = ["FactorList[Expand[polynomial]]"]
    return all(item in section for item in required) and not any(
        item in section for item in forbidden
    )


def main() -> int:
    require(SOURCE.is_file(), "source-missing")
    require(PATCH.is_file(), "patch-missing")
    require(LEXICAL_GUARD.is_file(), "lexical-guard-missing")
    original = SOURCE.read_text(encoding="utf-8")
    source_sha = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    require(source_sha == EXPECTED_SOURCE_SHA256, "source-sha-drift")

    with tempfile.TemporaryDirectory(prefix="epsilon-content-") as directory:
        work = pathlib.Path(directory)
        target = work / SOURCE.relative_to(ROOT)
        target.parent.mkdir(parents=True)
        target.write_text(original, encoding="utf-8")
        applied = subprocess.run(
            ["git", "apply", "--unsafe-paths", "--directory", str(work),
             str(PATCH)], cwd=ROOT, text=True, capture_output=True,
            check=False,
        )
        require(applied.returncode == 0,
                "patch-apply: " + applied.stderr.strip())
        patched = target.read_text(encoding="utf-8")
        lexical = subprocess.run(
            ["perl", str(LEXICAL_GUARD), str(target)], cwd=ROOT,
            text=True, capture_output=True, check=False,
        )
        require(lexical.returncode == 0,
                "lexical-guard: " + lexical.stderr.strip())

    require(contract(patched), "targeted-content-contract")

    # Independent Q[x][epsilon] model of the same coefficient-content
    # theorem.  The production coefficient ring is Q[x,y]; adjoining one
    # more variable does not alter the UFD/Gauss-lemma argument.
    rng = random.Random(30012060823)
    cases = 0
    for _ in range(256):
        roots = rng.sample(range(-9, 10), rng.randint(1, 4))
        content = [Fraction(1)]
        for root in roots:
            multiplicity = rng.randint(1, 3)
            for _ in range(multiplicity):
                content = multiply(content, [Fraction(-root), Fraction(1)])
        primitive = [[Fraction(1)]]
        for _ in range(rng.randint(1, 5)):
            primitive.append([Fraction(rng.randint(-7, 7))
                              for _ in range(rng.randint(1, 5))])
        coefficients = [multiply(content, coefficient)
                        for coefficient in primitive]
        recovered = coefficient_content(coefficients)
        require(recovered == monic(content), "content-gcd-mismatch")
        for coefficient in coefficients:
            _, remainder = divide_with_remainder(coefficient, recovered)
            require(remainder == [0], "content-does-not-divide")
        cases += 1

    mutants = [
        patched.replace("Fold[PolynomialGCD", "First", 1),
        patched.replace("contentGroups = GatherBy", "contentGroups = List", 1),
        patched.replace("contentCertificates = MapThread",
                        "contentCertificates = ConstantArray", 1),
        patched.replace("FactorList[Expand[content]]",
                        "FactorList[Expand[polynomial]]", 1),
    ]
    for index, mutant in enumerate(mutants):
        require(not contract(mutant), f"mutant-accepted-{index}")

    print("PASS targeted epsilon-content census static/adversarial audit")
    print("source_sha256", source_sha)
    print("independent_cases", cases)
    print("mutants_rejected", len(mutants))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print("FAIL", error, file=sys.stderr)
        raise
