#!/usr/bin/env python3
"""Pilot the exact fixed-u compiler on one real deferred CF303 factor."""

from __future__ import annotations

import importlib.util
import sys
import time
from fractions import Fraction
from pathlib import Path

import sympy
from sympy.parsing.mathematica import parse_mathematica


REPOSITORY = Path(__file__).resolve().parents[2]
MODULE = REPOSITORY / (
    "Scripts/Transport/CF303/data/normal_factor_exact_circuit/"
    "cf303_exact_fixed_u_source.py"
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_module():
    specification = importlib.util.spec_from_file_location(
        "cf303_exact_fixed_u_source", MODULE
    )
    require(specification is not None and specification.loader is not None,
            "cannot load exact fixed-u source compiler")
    module = importlib.util.module_from_spec(specification)
    sys.modules[specification.name] = module
    specification.loader.exec_module(module)
    return module


def main() -> int:
    exact = load_module()
    started = time.perf_counter()
    compiler = exact.ExactFixedUSourceCompiler(row=2)
    expression_index, expression = compiler.pilot_expression()
    require(20 <= len(expression.postfix) <= 1000,
            "pilot is not bounded")

    p_value = Fraction(4, 11)
    u_value = Fraction(52, 55)
    epsilon_value = Fraction(7)
    rational, residual, residual_square = (
        compiler.evaluate_expression_at_rational_epsilon(
            expression_index, u_value, epsilon_value, p_value
        )
    )
    require(residual != 0, "pilot does not exercise the residual root")
    require(residual_square == Fraction(224730081, 57274624),
            "unexpected pilot residual-root square")
    residual_root_value = Fraction(14991, 7568)

    x, y, eps = sympy.symbols("x y eps")
    root1, root2, root3 = sympy.symbols("root1 root2 root3")
    delta1 = 1 - 2*x + x**2 + 2*y + 2*x*y + y**2
    delta2 = 1 + 2*x + x**2 - 2*y + 2*x*y + y**2
    delta3 = 1 - 4*x*y
    direct = parse_mathematica(expression.source_text).subs({
        sympy.sqrt(delta2): root2,
        sympy.sqrt(delta1): root1,
        sympy.sqrt(delta3): root3,
    }, simultaneous=True)
    require(root1 in direct.free_symbols,
            "independent parser did not expose the residual root")
    path = compiler._path_data(p_value, u_value)
    direct_base = direct.subs({
        x: sympy.Rational(path[0].numerator, path[0].denominator),
        y: sympy.Rational(path[1].numerator, path[1].denominator),
        eps: sympy.Rational(epsilon_value.numerator, epsilon_value.denominator),
        root2: sympy.Rational(path[5].numerator, path[5].denominator),
        root3: sympy.Rational(path[6].numerator, path[6].denominator),
    })
    for sign in (1, -1):
        direct_sheet = sympy.cancel(direct_base.subs(
            root1, sign * sympy.Rational(
                residual_root_value.numerator,
                residual_root_value.denominator,
            )
        ))
        compiled_sheet = rational + sign * residual * residual_root_value
        require(direct_sheet == sympy.Rational(
            compiled_sheet.numerator, compiled_sheet.denominator
        ), f"postfix/direct parser mismatch on sheet {sign}")

    try:
        exact.ExactFixedUSourceCompiler(row=3)
    except exact.ExactFixedUSourceRefusal as refusal:
        require(refusal.status == "CF303ExactFixedUSourceRowInvalid",
                "wrong invalid-row refusal")
    else:
        raise AssertionError("invalid row was not refused")

    print(
        "PASS CF303 exact fixed-u source pilot; "
        f"expression={expression_index} operations={len(expression.postfix)} "
        f"compiledExpressions={len(compiler.expressions)} "
        f"compiledOperations={compiler.postfix_operation_count} "
        f"compileSeconds={compiler.compile_seconds:.3f} "
        f"wallSeconds={time.perf_counter() - started:.3f} sheets=2"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
