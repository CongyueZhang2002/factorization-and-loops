#!/usr/bin/env python3
"""Focused exact-normal-form tests for the portable CF303 lazy circuit."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import sympy


REPOSITORY = Path(__file__).resolve().parents[2]
MODULE = REPOSITORY / (
    "Scripts/Transport/CF303/data/normal_factor_exact_circuit/"
    "cf303_exact_hermite_semantics.py"
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    specification = importlib.util.spec_from_file_location(
        "cf303_exact_hermite_semantics", MODULE
    )
    require(specification is not None and specification.loader is not None,
            "cannot load exact Hermite module")
    exact = importlib.util.module_from_spec(specification)
    sys.modules[specification.name] = exact
    specification.loader.exec_module(exact)

    z, p, y0 = sympy.symbols("z p y0")

    rational_primitive = (z + p) / (z - 2) ** 2 + z**2 / 3
    rational_remainder = (3 * z + p) / (z**2 + 1)
    rational_input = sympy.diff(rational_primitive, z) + rational_remainder
    rational, rational_evidence = exact.rational_hermite(rational_input, z)
    require(sympy.cancel(
        rational_input
        - sympy.diff(rational.primitive_coefficient, z)
        - rational.remainder_coefficient
    ) == 0, "rational Hermite identity failed")
    rational_replay, _ = exact.rational_hermite(rational_input, z)
    require(rational_replay == rational,
            "rational RREF/free-zero convention is not deterministic")
    require(rational_evidence["FreeCoordinatesSetToZero"] is True,
            "rational free-coordinate convention missing")

    curve = z**4 + p * z + 1
    elliptic_primitive = (z + p) / (z - 2) ** 2 + z**2
    elliptic_remainder = (2 * z + p) / (z**2 + 1) + 3 - z + 2 * z**2
    elliptic_input = sympy.cancel(
        curve * sympy.diff(elliptic_primitive, z)
        + sympy.diff(curve, z) * elliptic_primitive / 2
        + elliptic_remainder
    )
    elliptic, elliptic_evidence = exact.elliptic_hermite(
        elliptic_input, curve, z
    )
    require(sympy.cancel(
        elliptic_input
        - curve * sympy.diff(elliptic.primitive_coefficient, z)
        - sympy.diff(curve, z) * elliptic.primitive_coefficient / 2
        - elliptic.remainder_coefficient
    ) == 0, "elliptic Hermite identity failed")
    elliptic_replay, _ = exact.elliptic_hermite(elliptic_input, curve, z)
    require(elliptic_replay == elliptic,
            "elliptic RREF/free-zero convention is not deterministic")
    require(elliptic_evidence["FreeCoordinatesSetToZero"] is True,
            "elliptic free-coordinate convention missing")
    monomial = elliptic.cohomology_monomial_coefficients
    basis = elliptic.elliptic_basis_coefficients
    a4 = sympy.Poly(curve, z).coeff_monomial(z**4)
    a3 = sympy.Poly(curve, z).coeff_monomial(z**3)
    require(sympy.cancel(
        monomial[0] + monomial[1] * z + monomial[2] * z**2
        - basis[0] - basis[1] * z
        - basis[2] * (z**2 + a3 * z / (2 * a4))
    ) == 0, "quartic cohomology basis conversion failed")

    try:
        exact.elliptic_hermite(1 / curve, curve, z)
    except exact.ExactHermiteRefusal as refusal:
        require(
            refusal.status ==
            "ExactEllipticHermiteBranchPointPoleUnsupported",
            "wrong branch-point refusal status",
        )
    else:
        raise AssertionError("branch-point pole was not refused")

    normalized_rational, normalized_elliptic = (
        exact.normalize_function_pair_at_base(
            1 + z, z - p, z, sympy.Rational(1, 2), y0
        )
    )
    require(sympy.cancel(
        normalized_rational.subs(z, sympy.Rational(1, 2))
        + normalized_elliptic.subs(z, sympy.Rational(1, 2)) * y0
    ) == 0, "declared-sheet base normalization failed")

    print(
        "PASS CF303 exact Hermite semantics; "
        f"rationalUnknowns={len(rational.coefficient_vector)} "
        f"ellipticUnknowns={len(elliptic.coefficient_vector)} "
        "branchPointRefusal=1 baseNormalization=1"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
