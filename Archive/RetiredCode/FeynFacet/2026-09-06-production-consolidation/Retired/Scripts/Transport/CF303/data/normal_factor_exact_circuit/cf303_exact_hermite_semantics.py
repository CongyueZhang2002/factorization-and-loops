#!/usr/bin/env python3
"""Exact characteristic-zero Hermite semantics for the CF303 lazy DAG.

The routines operate over a rational-function coefficient field such as
Q(p,eps).  Their purpose is to define the sealed Hermite nodes exactly; the
large CF303 circuit may remain lazy.  Linear coefficient systems are reduced
to RREF in the declared coefficient-vector order and every free coordinate is
set to zero, so the normal form does not depend on a solver heuristic.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable

import sympy


class ExactHermiteRefusal(RuntimeError):
    """Typed refusal for an input outside the declared reduction domain."""

    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


@dataclass(frozen=True)
class HermiteNormalForm:
    kind: str
    primitive_coefficient: sympy.Expr
    remainder_coefficient: sympy.Expr
    repeated_denominator: sympy.Expr
    squarefree_denominator: sympy.Expr
    coefficient_vector_order: tuple[str, ...]
    coefficient_vector: tuple[sympy.Expr, ...]
    cohomology_monomial_coefficients: tuple[sympy.Expr, ...] = ()
    elliptic_basis_coefficients: tuple[sympy.Expr, ...] = ()


def _coefficient_domain(expressions: Iterable[sympy.Expr], variable: sympy.Symbol):
    parameters = sorted(
        set().union(*(sympy.sympify(item).free_symbols for item in expressions))
        - {variable},
        key=str,
    )
    return sympy.QQ.frac_field(*parameters) if parameters else sympy.QQ


def _reduced_monic_fraction(expression: sympy.Expr, variable: sympy.Symbol,
                             *domain_expressions: sympy.Expr):
    expression = sympy.cancel(sympy.sympify(expression))
    numerator, denominator = sympy.fraction(expression)
    domain = _coefficient_domain(
        (numerator, denominator, *domain_expressions), variable
    )
    numerator = sympy.Poly(numerator, variable, domain=domain)
    denominator = sympy.Poly(denominator, variable, domain=domain)
    common = sympy.gcd(numerator, denominator)
    numerator = numerator.exquo(common)
    denominator = denominator.exquo(common)
    if denominator.is_zero:
        raise ExactHermiteRefusal("ExactHermiteZeroDenominator")
    leading = denominator.LC()
    numerator = sympy.Poly(numerator.as_expr() / leading,
                            variable, domain=domain)
    denominator = denominator.monic()
    return numerator, denominator, domain


def _polynomial_ansatz(prefix: str, count: int, variable: sympy.Symbol):
    symbols = sympy.symbols(f"{prefix}0:{count}") if count else ()
    return symbols, sum(
        (coefficient * variable**degree
         for degree, coefficient in enumerate(symbols)),
        sympy.S.Zero,
    )


def _rref_free_zero_solve(identity_numerator: sympy.Expr,
                          unknowns: tuple[sympy.Symbol, ...],
                          variable: sympy.Symbol):
    polynomial = sympy.Poly(sympy.expand(identity_numerator), variable)
    equations = polynomial.all_coeffs()
    if not unknowns:
        if any(sympy.cancel(value) != 0 for value in equations):
            raise ExactHermiteRefusal("ExactHermiteCoefficientSystemInconsistent")
        return (), {"EquationCount": len(equations), "Rank": 0,
                    "Nullity": 0, "FreeCoordinatesSetToZero": True}
    coefficient_matrix, right_hand_side = sympy.linear_eq_to_matrix(
        equations, unknowns
    )
    augmented, pivots = coefficient_matrix.row_join(right_hand_side).rref()
    width = len(unknowns)
    if width in pivots:
        raise ExactHermiteRefusal("ExactHermiteCoefficientSystemInconsistent")
    values = [sympy.S.Zero] * width
    for row, pivot in enumerate(pivots):
        values[pivot] = sympy.cancel(augmented[row, width])
    residual = coefficient_matrix * sympy.Matrix(values) - right_hand_side
    if any(sympy.cancel(value) != 0 for value in residual):
        raise ExactHermiteRefusal("ExactHermiteRREFReplayFailed")
    return tuple(values), {
        "EquationCount": coefficient_matrix.rows,
        "Rank": len(pivots),
        "Nullity": width - len(pivots),
        "FreeCoordinatesSetToZero": True,
    }


def rational_hermite(expression: sympy.Expr, variable: sympy.Symbol):
    """Return f=dH/dz+K in the deterministic rational normal form."""
    numerator, denominator, domain = _reduced_monic_fraction(
        expression, variable
    )
    polynomial_part, proper_numerator = numerator.div(denominator)
    repeated = sympy.gcd(denominator, denominator.diff())
    squarefree = denominator.exquo(repeated)
    repeated_degree = repeated.degree()
    squarefree_degree = squarefree.degree()
    primitive_polynomial = sum(
        coefficient / (degree + 1) * variable ** (degree + 1)
        for (degree,), coefficient in polynomial_part.terms()
    )
    exact_symbols, exact_numerator = _polynomial_ansatz(
        "rationalPrimitive", repeated_degree, variable
    )
    remainder_symbols, remainder_numerator = _polynomial_ansatz(
        "rationalRemainder", squarefree_degree, variable
    )
    rational_part = exact_numerator / repeated.as_expr()
    remainder = remainder_numerator / squarefree.as_expr()
    primitive = primitive_polynomial + rational_part
    residual = sympy.together(
        numerator.as_expr() / denominator.as_expr()
        - sympy.diff(primitive, variable) - remainder
    )
    residual_numerator = sympy.fraction(residual)[0]
    unknowns = tuple(exact_symbols) + tuple(remainder_symbols)
    values, evidence = _rref_free_zero_solve(
        residual_numerator, unknowns, variable
    )
    replacement = dict(zip(unknowns, values, strict=True))
    primitive = sympy.cancel(primitive.subs(replacement))
    remainder = sympy.cancel(remainder.subs(replacement))
    if sympy.cancel(expression - sympy.diff(primitive, variable) - remainder) != 0:
        raise ExactHermiteRefusal("ExactRationalHermiteIdentityFailed")
    labels = tuple(
        [f"PrimitiveNumeratorZPower[{degree}]"
         for degree in range(repeated_degree)]
        + [f"SquarefreeRemainderNumeratorZPower[{degree}]"
           for degree in range(squarefree_degree)]
    )
    return HermiteNormalForm(
        kind="RationalHermiteNormalForm",
        primitive_coefficient=primitive,
        remainder_coefficient=remainder,
        repeated_denominator=repeated.as_expr(),
        squarefree_denominator=squarefree.as_expr(),
        coefficient_vector_order=labels,
        coefficient_vector=values,
    ), evidence


def elliptic_hermite(expression: sympy.Expr, curve: sympy.Expr,
                     variable: sympy.Symbol):
    """Return f dz/Y=d(H Y)+K dz/Y for Y^2=curve."""
    numerator, denominator, domain = _reduced_monic_fraction(
        expression, variable, curve
    )
    curve_poly = sympy.Poly(curve, variable, domain=domain)
    if curve_poly.degree() != 4 or curve_poly.LC() == 0:
        raise ExactHermiteRefusal("ExactEllipticHermiteQuarticCurveRequired")
    branch_gcd = sympy.gcd(denominator, curve_poly)
    if branch_gcd.degree() > 0:
        raise ExactHermiteRefusal(
            "ExactEllipticHermiteBranchPointPoleUnsupported",
            CommonFactor=branch_gcd.as_expr(),
        )
    repeated = sympy.gcd(denominator, denominator.diff())
    squarefree = denominator.exquo(repeated)
    polynomial_part, _ = numerator.div(denominator)
    polynomial_degree = -1 if polynomial_part.is_zero else polynomial_part.degree()
    polynomial_primitive_count = max(0, polynomial_degree - 2)
    repeated_degree = repeated.degree()
    squarefree_degree = squarefree.degree()
    exact_symbols, exact_numerator = _polynomial_ansatz(
        "ellipticPrimitive", repeated_degree, variable
    )
    remainder_symbols, proper_remainder_numerator = _polynomial_ansatz(
        "ellipticFiniteRemainder", squarefree_degree, variable
    )
    infinity_symbols, polynomial_primitive = _polynomial_ansatz(
        "ellipticInfinityPrimitive", polynomial_primitive_count, variable
    )
    cohomology_symbols, cohomology_polynomial = _polynomial_ansatz(
        "ellipticCohomology", 3, variable
    )
    primitive = exact_numerator / repeated.as_expr() + polynomial_primitive
    remainder = (
        proper_remainder_numerator / squarefree.as_expr()
        + cohomology_polynomial
    )
    primitive_derivative_coefficient = (
        curve * sympy.diff(primitive, variable)
        + sympy.diff(curve, variable) * primitive / 2
    )
    residual = sympy.together(
        numerator.as_expr() / denominator.as_expr()
        - primitive_derivative_coefficient - remainder
    )
    residual_numerator = sympy.fraction(residual)[0]
    unknowns = (
        tuple(exact_symbols) + tuple(remainder_symbols)
        + tuple(infinity_symbols) + tuple(cohomology_symbols)
    )
    values, evidence = _rref_free_zero_solve(
        residual_numerator, unknowns, variable
    )
    replacement = dict(zip(unknowns, values, strict=True))
    primitive = sympy.cancel(primitive.subs(replacement))
    remainder = sympy.cancel(remainder.subs(replacement))
    replay = sympy.cancel(
        expression
        - curve * sympy.diff(primitive, variable)
        - sympy.diff(curve, variable) * primitive / 2
        - remainder
    )
    if replay != 0:
        raise ExactHermiteRefusal("ExactEllipticHermiteIdentityFailed")
    cohomology = tuple(
        sympy.cancel(symbol.subs(replacement))
        for symbol in cohomology_symbols
    )
    curve_coefficients = sympy.Poly(curve, variable, domain=domain).all_coeffs()
    a4, a3 = curve_coefficients[0], curve_coefficients[1]
    elliptic_basis = (
        cohomology[0],
        sympy.cancel(cohomology[1] - cohomology[2] * a3 / (2 * a4)),
        cohomology[2],
    )
    labels = tuple(
        [f"PrimitiveNumeratorZPower[{degree}]"
         for degree in range(repeated_degree)]
        + [f"SquarefreeFiniteRemainderNumeratorZPower[{degree}]"
           for degree in range(squarefree_degree)]
        + [f"InfinityPrimitiveZPower[{degree}]"
           for degree in range(polynomial_primitive_count)]
        + [f"CohomologyMonomialZPower[{degree}]" for degree in range(3)]
    )
    return HermiteNormalForm(
        kind="QuarticEllipticHermiteNormalForm",
        primitive_coefficient=primitive,
        remainder_coefficient=remainder,
        repeated_denominator=repeated.as_expr(),
        squarefree_denominator=squarefree.as_expr(),
        coefficient_vector_order=labels,
        coefficient_vector=values,
        cohomology_monomial_coefficients=cohomology,
        elliptic_basis_coefficients=elliptic_basis,
    ), evidence


def normalize_function_pair_at_base(
    rational_part: sympy.Expr,
    elliptic_y_coefficient: sympy.Expr,
    variable: sympy.Symbol,
    base_point: sympy.Expr,
    y_at_base: sympy.Expr,
):
    """Normalize A+B Y by subtracting its declared-sheet base value."""
    base_value = sympy.cancel(
        rational_part.subs(variable, base_point)
        + elliptic_y_coefficient.subs(variable, base_point) * y_at_base
    )
    return (
        sympy.cancel(rational_part - base_value),
        sympy.cancel(elliptic_y_coefficient),
    )


EXACT_SEMANTICS = {
    "CoefficientField": "Q(p,eps)(z)[Y]/(Y^2-P4(p,z))",
    "RationalCoefficientVectorOrder": (
        "primitive numerator by increasing z power",
        "squarefree remainder numerator by increasing z power",
    ),
    "EllipticCoefficientVectorOrder": (
        "finite-pole primitive numerator by increasing z power",
        "squarefree finite-pole remainder numerator by increasing z power",
        "infinity primitive by increasing z power",
        "cohomology monomials 1,z,z^2",
    ),
    "LinearSystemConvention": (
        "reduced row-echelon form in the declared order; every free "
        "coordinate is zero"
    ),
    "BranchPointPolePolicy": (
        "typed refusal ExactEllipticHermiteBranchPointPoleUnsupported "
        "when gcd(denominator,P4) is nonconstant"
    ),
    "PrimitiveNormalization": "subtract H(z=1/2) on the declared sheet",
    "PhysicalBranch": (
        "at p=4/11 choose Y(1/2)>0 and analytically continue; "
        "on the initial physical sheet 0<p<1/Sqrt(2) at z=2p, "
        "Y=+8*p*sqrt(1-p^2)"
    ),
}
