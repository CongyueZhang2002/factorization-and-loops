#!/usr/bin/env python3
"""Deferred exact circuit and modular evaluator for the CF303 88-entry baseline.

The exact object is the sealed recurrence over the original transfer/census,
D/S, and T25 leaves.  Point evaluation specializes those leaves first and
performs only F_q[u] rational/quartic Hermite arithmetic.  No expanded
characteristic-zero H/K matrix is constructed.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import resource
import sys
import time
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Any, Iterable, Sequence

import sympy


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
RUNTIME = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
TRANSFER = RUNTIME / "cf303_hybrid_baseline90_transfer.maple"
PATH_INPUT = RUNTIME / "cf303_hybrid_baseline_path_dlog_gauge_inputs.maple"
PHYSICAL_GAUGE = RUNTIME / "cf303_block25_physical_gauge.wl"
RATIONAL_HELPER = ROOT / "Diagnostics/Scripts/cf303_modular_hermite_pilot.py"
ELLIPTIC_HELPER = ROOT / "Diagnostics/Scripts/cf303_modular_algebraic_hermite_pilot.py"
Q7 = 2_305_843_009_213_693_693
ORDERS = tuple(range(-3, 5))
TARGET_ORDERS = tuple(range(-4, 3))
SOURCE_ROWS = (
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    17, 18, 19, 20, 21, 22, 26, 27, 29, 30, 31, 32, 33, 34, 35,
    36, 39, 40, 41, 42, 43, 23, 24, 25, 28, 37, 38,
)
TARGET_ROWS = (44, 45)
EXT_NONRESIDUE = 2
ADAPTER_SUPPORT_MASTERS = (1, 2, 12, 21, 22, 29, 30)


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def parse_bracket_list(text: str, position: int, opening="[", closing="]"):
    """Parse only container syntax; mathematical expressions remain strings."""
    if text[position] != opening:
        raise ValueError(f"expected {opening!r} at {position}")
    position += 1
    result = []
    while True:
        while text[position].isspace():
            position += 1
        if text[position] == closing:
            return result, position + 1
        if text[position] == opening:
            value, position = parse_bracket_list(
                text, position, opening, closing
            )
        elif text[position] == '"':
            end = position + 1
            while True:
                end = text.find('"', end)
                if end < 0:
                    raise ValueError("unterminated string")
                if text[end - 1] != "\\":
                    break
                end += 1
            value, position = text[position + 1:end], end + 1
        else:
            start = position
            parentheses = nested_square = 0
            while True:
                character = text[position]
                if character == "(":
                    parentheses += 1
                elif character == ")":
                    parentheses -= 1
                elif opening == "[" and character == "[":
                    nested_square += 1
                elif opening == "[" and character == "]":
                    if parentheses == 0 and nested_square == 0:
                        break
                    nested_square -= 1
                elif (
                    (character == "," or character == closing)
                    and parentheses == 0 and nested_square == 0
                ):
                    break
                position += 1
            value = text[start:position].strip()
        result.append(value)
        while text[position].isspace():
            position += 1
        if text[position] == ",":
            position += 1
        elif text[position] == closing:
            return result, position + 1
        else:
            raise ValueError(f"bad list separator at {position}")


def maple_list_assignment(text: str, name: str):
    marker = f"{name} :="
    position = text.index(marker) + len(marker)
    while text[position].isspace():
        position += 1
    return parse_bracket_list(text, position)[0]


def wolfram_list_rule(text: str, name: str):
    marker = f'"{name}" ->'
    position = text.index(marker) + len(marker)
    while text[position].isspace():
        position += 1
    return parse_bracket_list(text, position, "{", "}")[0]


class SparseBiPoly:
    """Sparse F_q[eps,u] polynomial, exponents keyed as (eps,u)."""

    __slots__ = ("terms", "prime")

    def __init__(self, terms: dict[tuple[int, int], int], prime: int):
        self.prime = prime
        self.terms = {
            key: value % prime for key, value in terms.items() if value % prime
        }

    @classmethod
    def constant(cls, value: int, prime: int):
        value %= prime
        return cls({(0, 0): value} if value else {}, prime)

    @classmethod
    def variable(cls, which: str, prime: int):
        return cls({(1, 0) if which == "eps" else (0, 1): 1}, prime)

    def copy(self):
        return SparseBiPoly(dict(self.terms), self.prime)

    @property
    def zero(self):
        return not self.terms

    @property
    def one(self):
        return self.terms == {(0, 0): 1}

    def add_inplace(self, other: "SparseBiPoly", sign=1):
        if self.prime != other.prime:
            raise ValueError("mixed primes")
        for key, value in other.terms.items():
            updated = (self.terms.get(key, 0) + sign * value) % self.prime
            if updated:
                self.terms[key] = updated
            else:
                self.terms.pop(key, None)
        return self

    def add(self, other: "SparseBiPoly", sign=1):
        return self.copy().add_inplace(other, sign)

    def multiply(self, other: "SparseBiPoly"):
        if self.zero or other.zero:
            return SparseBiPoly({}, self.prime)
        if len(self.terms) == 1:
            (left_key, left_value), = self.terms.items()
            return SparseBiPoly({
                (left_key[0] + right_key[0], left_key[1] + right_key[1]):
                    left_value * right_value
                for right_key, right_value in other.terms.items()
            }, self.prime)
        if len(other.terms) == 1:
            return other.multiply(self)
        result: dict[tuple[int, int], int] = {}
        prime = self.prime
        for (left_eps, left_u), left_value in self.terms.items():
            for (right_eps, right_u), right_value in other.terms.items():
                key = (left_eps + right_eps, left_u + right_u)
                result[key] = (result.get(key, 0) + left_value * right_value) % prime
        return SparseBiPoly(result, prime)

    def power(self, exponent: int):
        if exponent < 0:
            raise ValueError("polynomial negative power")
        result = SparseBiPoly.constant(1, self.prime)
        factor = self
        while exponent:
            if exponent & 1:
                result = result.multiply(factor)
            exponent >>= 1
            if exponent:
                factor = factor.multiply(factor)
        return result


class SparseBiRational:
    __slots__ = ("numerator", "denominator", "prime")

    def __init__(self, numerator: SparseBiPoly, denominator: SparseBiPoly):
        if denominator.zero:
            raise ZeroDivisionError("zero bivariate denominator")
        self.numerator, self.denominator = numerator, denominator
        self.prime = numerator.prime

    @classmethod
    def constant(cls, value: int, prime: int):
        return cls(SparseBiPoly.constant(value, prime),
                   SparseBiPoly.constant(1, prime))

    @classmethod
    def polynomial(cls, value: SparseBiPoly):
        return cls(value, SparseBiPoly.constant(1, value.prime))

    def add(self, other: "SparseBiRational", sign=1):
        if self.denominator.one and other.denominator.one:
            self.numerator.add_inplace(other.numerator, sign)
            return self
        numerator = self.numerator.multiply(other.denominator).add(
            other.numerator.multiply(self.denominator), sign
        )
        denominator = self.denominator.multiply(other.denominator)
        return SparseBiRational(numerator, denominator)

    def multiply(self, other: "SparseBiRational"):
        return SparseBiRational(
            self.numerator.multiply(other.numerator),
            self.denominator.multiply(other.denominator),
        )

    def divide(self, other: "SparseBiRational"):
        if other.numerator.zero:
            raise ZeroDivisionError("division by zero expression")
        return SparseBiRational(
            self.numerator.multiply(other.denominator),
            self.denominator.multiply(other.numerator),
        )

    def power(self, exponent: int):
        if exponent >= 0:
            return SparseBiRational(
                self.numerator.power(exponent),
                self.denominator.power(exponent),
            )
        return SparseBiRational(
            self.denominator.power(-exponent),
            self.numerator.power(-exponent),
        )


class ModularExpressionParser:
    """Recursive-descent parser that reduces integer/p coefficients immediately."""

    def __init__(self, text: str, prime: int, p_value: int):
        self.text, self.prime, self.p_value = text, prime, p_value % prime
        self.position = 0

    def skip(self):
        while self.position < len(self.text) and self.text[self.position].isspace():
            self.position += 1

    def parse(self):
        value = self.parse_sum()
        self.skip()
        if self.position != len(self.text):
            raise ValueError(f"unparsed expression at {self.position}: {self.text[self.position:self.position+40]}")
        return value

    def parse_sum(self):
        value = self.parse_product()
        while True:
            self.skip()
            if self.position >= len(self.text) or self.text[self.position] not in "+-":
                return value
            operation = self.text[self.position]
            self.position += 1
            value = value.add(self.parse_product(), 1 if operation == "+" else -1)

    def parse_product(self):
        value = self.parse_unary()
        while True:
            self.skip()
            if self.position >= len(self.text) or self.text[self.position] not in "*/":
                return value
            operation = self.text[self.position]
            self.position += 1
            right = self.parse_unary()
            value = value.multiply(right) if operation == "*" else value.divide(right)

    def parse_unary(self):
        self.skip()
        if self.text[self.position] == "+":
            self.position += 1
            return self.parse_unary()
        if self.text[self.position] == "-":
            self.position += 1
            return SparseBiRational.constant(-1, self.prime).multiply(self.parse_unary())
        return self.parse_power()

    def parse_power(self):
        value = self.parse_primary()
        self.skip()
        if self.position < len(self.text) and self.text[self.position] == "^":
            self.position += 1
            value = value.power(self.parse_integer_exponent())
        return value

    def parse_integer_exponent(self):
        self.skip()
        parenthesized = self.text[self.position] == "("
        if parenthesized:
            self.position += 1
            self.skip()
        sign = 1
        if self.text[self.position] in "+-":
            if self.text[self.position] == "-":
                sign = -1
            self.position += 1
        self.skip()
        start = self.position
        while self.position < len(self.text) and self.text[self.position].isdigit():
            self.position += 1
        if start == self.position:
            raise ValueError("noninteger exponent")
        exponent = sign * int(self.text[start:self.position])
        self.skip()
        if parenthesized:
            if self.text[self.position] != ")":
                raise ValueError("bad parenthesized exponent")
            self.position += 1
        return exponent

    def parse_primary(self):
        self.skip()
        character = self.text[self.position]
        if character == "(":
            self.position += 1
            value = self.parse_sum()
            self.skip()
            if self.text[self.position] != ")":
                raise ValueError("unclosed parenthesis")
            self.position += 1
            return value
        if character.isdigit():
            start = self.position
            while self.position < len(self.text) and self.text[self.position].isdigit():
                self.position += 1
            return SparseBiRational.constant(
                int(self.text[start:self.position]) % self.prime, self.prime
            )
        if character.isalpha():
            start = self.position
            while self.position < len(self.text) and (
                self.text[self.position].isalnum() or self.text[self.position] == "_"
            ):
                self.position += 1
            name = self.text[start:self.position]
            if name == "p":
                return SparseBiRational.constant(self.p_value, self.prime)
            if name in ("u", "eps"):
                return SparseBiRational.polynomial(
                    SparseBiPoly.variable(name, self.prime)
                )
            raise ValueError(f"unsupported symbol {name}")
        raise ValueError(f"bad expression token {character!r} at {self.position}")


@dataclass(frozen=True)
class RationalFunction:
    numerator: tuple[int, ...]
    denominator: tuple[int, ...]
    prime: int

    @classmethod
    def make(cls, numerator, denominator, prime, helper):
        numerator = helper.trim(numerator, prime)
        denominator = helper.trim(denominator, prime)
        if denominator == [0]:
            raise ZeroDivisionError("zero F_q[u] denominator")
        if numerator == [0]:
            return cls((0,), (1,), prime)
        common = helper.gcd_poly(numerator, denominator, prime)
        numerator = helper.exact_div(numerator, common, prime)
        denominator = helper.exact_div(denominator, common, prime)
        inverse = pow(denominator[-1], -1, prime)
        return cls(tuple(helper.scale(numerator, inverse, prime)),
                   tuple(helper.scale(denominator, inverse, prime)), prime)

    @classmethod
    def zero(cls, prime):
        return cls((0,), (1,), prime)

    @classmethod
    def constant(cls, value, prime):
        return cls((value % prime,), (1,), prime)

    @property
    def zero_q(self):
        return self.numerator == (0,)

    def add(self, other, helper, sign=1):
        numerator = helper.add(
            helper.multiply(self.numerator, other.denominator, self.prime),
            helper.multiply(other.numerator, self.denominator, self.prime),
            self.prime, sign,
        )
        denominator = helper.multiply(self.denominator, other.denominator, self.prime)
        return RationalFunction.make(numerator, denominator, self.prime, helper)

    def multiply(self, other, helper):
        return RationalFunction.make(
            helper.multiply(self.numerator, other.numerator, self.prime),
            helper.multiply(self.denominator, other.denominator, self.prime),
            self.prime, helper,
        )

    def derivative(self, helper):
        numerator = helper.add(
            helper.multiply(helper.derivative(self.numerator, self.prime),
                            self.denominator, self.prime),
            helper.multiply(self.numerator,
                            helper.derivative(self.denominator, self.prime),
                            self.prime),
            self.prime, -1,
        )
        return RationalFunction.make(
            numerator,
            helper.multiply(self.denominator, self.denominator, self.prime),
            self.prime, helper,
        )

    def evaluate(self, point):
        def value(poly):
            result = 0
            for coefficient in reversed(poly):
                result = (result * point + coefficient) % self.prime
            return result
        denominator = value(self.denominator)
        if not denominator:
            raise ZeroDivisionError("point lies on F_q[u] pole")
        return value(self.numerator) * pow(denominator, -1, self.prime) % self.prime


def poly_by_epsilon(poly: SparseBiPoly, helper):
    grouped: dict[int, dict[int, int]] = {}
    for (epsilon_degree, u_degree), value in poly.terms.items():
        grouped.setdefault(epsilon_degree, {})[u_degree] = value
    result = {}
    for epsilon_degree, terms in grouped.items():
        dense = [0] * (max(terms, default=0) + 1)
        for degree, value in terms.items():
            dense[degree] = value
        result[epsilon_degree] = helper.trim(dense, poly.prime)
    return result


def laurent_coefficients(expression: SparseBiRational, helper, low=-3, high=4):
    numerator = poly_by_epsilon(expression.numerator, helper)
    denominator = poly_by_epsilon(expression.denominator, helper)
    if not numerator:
        return {}
    numerator_valuation = min(numerator)
    denominator_valuation = min(denominator)
    valuation = numerator_valuation - denominator_valuation
    if valuation < low:
        raise ArithmeticError(f"Laurent valuation {valuation} below {low}")
    denominator_lead = denominator[denominator_valuation]
    inverse_lead = RationalFunction.make([1], denominator_lead,
                                         expression.prime, helper)
    quotient: dict[int, RationalFunction] = {}
    for index in range(max(0, high - valuation) + 1):
        numerator_poly = numerator.get(numerator_valuation + index, [0])
        value = RationalFunction.make(numerator_poly, [1], expression.prime, helper)
        for shift in range(1, index + 1):
            denominator_poly = denominator.get(denominator_valuation + shift)
            if denominator_poly is None or quotient[index - shift].zero_q:
                continue
            product = RationalFunction.make(
                denominator_poly, [1], expression.prime, helper
            ).multiply(quotient[index - shift], helper)
            value = value.add(product, helper, -1)
        quotient[index] = value.multiply(inverse_lead, helper)
    return {
        valuation + index: value for index, value in quotient.items()
        if low <= valuation + index <= high and not value.zero_q
    }


def bi_expression_to_rf(expression: SparseBiRational, helper):
    if any(key[0] for key in expression.numerator.terms) or any(
        key[0] for key in expression.denominator.terms
    ):
        raise ValueError("epsilon-dependent expression where F_q[u] expected")
    numerator = poly_by_epsilon(expression.numerator, helper).get(0, [0])
    denominator = poly_by_epsilon(expression.denominator, helper).get(0, [0])
    return RationalFunction.make(numerator, denominator, expression.prime, helper)


def legendre(value: int, prime: int):
    image = pow(value % prime, (prime - 1) // 2, prime)
    return -1 if image == prime - 1 else image


def tonelli(value: int, prime: int):
    value %= prime
    if not value:
        return 0
    if legendre(value, prime) != 1:
        raise ArithmeticError("nonsquare finite-field radical")
    odd, shifts = prime - 1, 0
    while odd % 2 == 0:
        odd //= 2
        shifts += 1
    nonresidue = 2
    while legendre(nonresidue, prime) != -1:
        nonresidue += 1
    c = pow(nonresidue, odd, prime)
    root = pow(value, (odd + 1) // 2, prime)
    residue = pow(value, odd, prime)
    active = shifts
    while residue != 1:
        index, probe = 1, residue * residue % prime
        while probe != 1:
            probe = probe * probe % prime
            index += 1
        factor = pow(c, 1 << (active - index - 1), prime)
        root = root * factor % prime
        residue = residue * factor * factor % prime
        c = factor * factor % prime
        active = index
    return min(root, prime - root)


def fq2_add(left, right, prime, sign=1):
    return ((left[0] + sign * right[0]) % prime,
            (left[1] + sign * right[1]) % prime)


def fq2_multiply(left, right, prime):
    return (
        (left[0] * right[0] + EXT_NONRESIDUE * left[1] * right[1]) % prime,
        (left[0] * right[1] + left[1] * right[0]) % prime,
    )


def fq2_inverse(value, prime):
    norm = (value[0] * value[0] - EXT_NONRESIDUE * value[1] * value[1]) % prime
    if not norm:
        raise ZeroDivisionError("zero F_q2 denominator")
    inverse = pow(norm, -1, prime)
    return value[0] * inverse % prime, -value[1] * inverse % prime


def fq2_power(value, exponent: int, prime: int):
    if exponent < 0:
        value, exponent = fq2_inverse(value, prime), -exponent
    result = (1, 0)
    while exponent:
        if exponent & 1:
            result = fq2_multiply(result, value, prime)
        exponent >>= 1
        if exponent:
            value = fq2_multiply(value, value, prime)
    return result


def fq2_sqrt_base(value: int, prime: int):
    value %= prime
    if not value:
        return 0, 0
    if legendre(value, prime) == 1:
        return tonelli(value, prime), 0
    scaled = value * pow(EXT_NONRESIDUE, -1, prime) % prime
    return 0, tonelli(scaled, prime)


def sympy_constant_fq2(expression, prime: int):
    if expression.is_Integer:
        return int(expression) % prime, 0
    if expression.is_Rational:
        return (int(expression.p) % prime * pow(int(expression.q) % prime, -1, prime) % prime, 0)
    if expression.is_Add:
        result = (0, 0)
        for term in expression.args:
            result = fq2_add(result, sympy_constant_fq2(term, prime), prime)
        return result
    if expression.is_Mul:
        result = (1, 0)
        for factor in expression.args:
            result = fq2_multiply(result, sympy_constant_fq2(factor, prime), prime)
        return result
    if expression.is_Pow:
        base, exponent = expression.args
        if exponent.is_Integer:
            return fq2_power(sympy_constant_fq2(base, prime), int(exponent), prime)
        if exponent == sympy.Rational(1, 2):
            base_value = sympy_constant_fq2(base, prime)
            if base_value[1]:
                raise ArithmeticError("nested non-base square root")
            return fq2_sqrt_base(base_value[0], prime)
        if exponent == sympy.Rational(-1, 2):
            base_value = sympy_constant_fq2(base, prime)
            if base_value[1]:
                raise ArithmeticError("nested non-base inverse square root")
            return fq2_inverse(fq2_sqrt_base(base_value[0], prime), prime)
    raise ArithmeticError(f"unsupported algebraic coefficient {expression}")


def sympy_sum_to_ext_rf(raw_expressions: Sequence[str], p_value: Fraction,
                        prime: int, helper):
    p_symbol, u_symbol, final_symbol = sympy.symbols("p u uFinal")
    substitutions = {
        p_symbol: sympy.Rational(p_value.numerator, p_value.denominator),
        final_symbol: 0,
    }
    terms = []
    for raw in raw_expressions:
        converted = raw.replace("^", "**").replace("[", "(").replace("]", ")")
        terms.append(sympy.sympify(converted, locals={
            "p": p_symbol, "u": u_symbol, "uFinal": final_symbol,
            "Sqrt": sympy.sqrt,
        }).subs(substitutions))
    # Source dlog records are letter-level leaves.  Their conjugate radicals
    # cancel only after all records at one matrix coordinate are added.
    expression = sympy.cancel(sympy.radsimp(sympy.Add(*terms)))
    if expression.free_symbols - {u_symbol}:
        raise ArithmeticError(f"D/S expression did not rationalize: {expression.free_symbols}")
    numerator, denominator = sympy.fraction(expression)

    def polynomial(value):
        result = sympy.Poly(value, u_symbol, domain="EX")
        base, extension = [], []
        for degree in range(result.degree() + 1 if result else 1):
            first, second = sympy_constant_fq2(result.nth(degree), prime)
            base.append(first)
            extension.append(second)
        return helper.trim(base or [0], prime), helper.trim(extension or [0], prime)

    numerator_base, numerator_extension = polynomial(numerator)
    denominator_base, denominator_extension = polynomial(denominator)
    norm = helper.add(
        helper.multiply(denominator_base, denominator_base, prime),
        helper.scale(
            helper.multiply(denominator_extension, denominator_extension, prime),
            EXT_NONRESIDUE, prime,
        ), prime, -1,
    )
    rationalized_base = helper.add(
        helper.multiply(numerator_base, denominator_base, prime),
        helper.scale(
            helper.multiply(numerator_extension, denominator_extension, prime),
            EXT_NONRESIDUE, prime,
        ), prime, -1,
    )
    rationalized_extension = helper.add(
        helper.multiply(numerator_extension, denominator_base, prime),
        helper.multiply(numerator_base, denominator_extension, prime),
        prime, -1,
    )
    return (
        RationalFunction.make(rationalized_base, norm, prime, helper),
        RationalFunction.make(rationalized_extension, norm, prime, helper),
    )


def ext_zero(prime):
    return RationalFunction.zero(prime), RationalFunction.zero(prime)


def ext_from_base(value: RationalFunction):
    return value, RationalFunction.zero(value.prime)


def ext_constant(value, prime):
    return (RationalFunction.constant(value[0], prime),
            RationalFunction.constant(value[1], prime))


def ext_zero_q(value):
    return value[0].zero_q and value[1].zero_q


def ext_add(left, right, helper, sign=1):
    return (left[0].add(right[0], helper, sign),
            left[1].add(right[1], helper, sign))


def ext_multiply(left, right, helper):
    first = left[0].multiply(right[0], helper).add(
        left[1].multiply(right[1], helper).multiply(
            RationalFunction.constant(EXT_NONRESIDUE, left[0].prime), helper
        ), helper,
    )
    second = left[0].multiply(right[1], helper).add(
        left[1].multiply(right[0], helper), helper
    )
    return first, second


def ext_derivative(value, helper):
    return value[0].derivative(helper), value[1].derivative(helper)


def ext_evaluate(value, point):
    return value[0].evaluate(point), value[1].evaluate(point)


def zero_pair(prime):
    return ext_zero(prime), ext_zero(prime)


def pair_zero(pair):
    return ext_zero_q(pair[0]) and ext_zero_q(pair[1])


def pair_add(left, right, helper, sign=1):
    return (ext_add(left[0], right[0], helper, sign),
            ext_add(left[1], right[1], helper, sign))


def function_form_product(function_pair, form_pair, curve_rf, helper):
    curve_ext = ext_from_base(curve_rf)
    return (
        ext_add(
            ext_multiply(function_pair[0], form_pair[0], helper),
            ext_multiply(function_pair[1], form_pair[1], helper), helper,
        ),
        ext_add(
            ext_multiply(function_pair[0], form_pair[1], helper),
            ext_multiply(
                ext_multiply(curve_ext, function_pair[1], helper),
                form_pair[0], helper,
            ), helper,
        ),
    )


def derivative_function_pair(function_pair, curve_rf, helper):
    half = ext_from_base(RationalFunction.constant(
        pow(2, -1, curve_rf.prime), curve_rf.prime
    ))
    elliptic = ext_add(
        ext_multiply(ext_from_base(curve_rf), ext_derivative(function_pair[1], helper), helper),
        ext_multiply(
            ext_multiply(ext_from_base(curve_rf.derivative(helper)),
                         function_pair[1], helper),
            half, helper,
        ), helper,
    )
    return ext_derivative(function_pair[0], helper), elliptic


def reduce_form(form_pair, curve_poly, helper, elliptic):
    prime = form_pair[0][0].prime

    def reduce_component(value, channel):
        if value.zero_q:
            return RationalFunction.zero(prime), RationalFunction.zero(prime)
        if channel == 0:
            result = helper.rational_hermite(value.numerator, value.denominator, prime)
            failure = "rational cross Hermite identity failed"
        else:
            result = elliptic.elliptic_hermite(
                helper, value.numerator, value.denominator, curve_poly, prime
            )
            failure = "elliptic cross Hermite identity failed"
        if not result["verified"]:
            raise ArithmeticError(failure)
        return (
            RationalFunction.make(result["primitive_numerator"],
                                  result["primitive_denominator"], prime, helper),
            RationalFunction.make(result["remainder_numerator"],
                                  result["remainder_denominator"], prime, helper),
        )

    primitives, remainders = [], []
    for channel in range(2):
        component_results = [
            reduce_component(form_pair[channel][extension], channel)
            for extension in range(2)
        ]
        primitives.append(tuple(result[0] for result in component_results))
        remainders.append(tuple(result[1] for result in component_results))
    return tuple(primitives), tuple(remainders)


def normalize_at_base(function_pair, base: int, base_sheet: int, helper):
    prime = function_pair[0][0].prime
    rational_value = ext_evaluate(function_pair[0], base)
    elliptic_value = ext_evaluate(function_pair[1], base)
    value = (
        (rational_value[0] + base_sheet * elliptic_value[0]) % prime,
        (rational_value[1] + base_sheet * elliptic_value[1]) % prime,
    )
    return ext_add(function_pair[0], ext_constant(value, prime), helper, -1), function_pair[1]


def curve_polynomial(p_value: int, prime: int):
    p = p_value % prime
    return [
        (16*p**6 - 32*p**4 + 16*p**2) % prime,
        (48*p**3 - 64*p**2 + 16*p) % prime,
        (-8*p**4 + 16*p**3 - 24*p**2 + 16*p + 4) % prime,
        (-12*p + 8) % prime,
        (p**2 - 4*p + 4) % prime,
    ]


def point_resolution_path(p_value: Fraction):
    suffix = f"p{p_value.numerator}d{p_value.denominator}"
    return RUNTIME / f"cf303_block1_circuit_resolved_q{Q7}_{suffix}.json"


def parse_inputs():
    transfer_text = TRANSFER.read_text()
    path_text = PATH_INPUT.read_text()
    gauge_text = PHYSICAL_GAUGE.read_text()
    entries = maple_list_assignment(transfer_text, "entryRecords")
    source_forms = maple_list_assignment(path_text, "sourceFormRecords")
    target_forms = maple_list_assignment(path_text, "targetFormRecords")
    source_rows = tuple(map(int, maple_list_assignment(path_text, "sourceRows")))
    gauge = wolfram_list_rule(gauge_text, "GaugeByOrder")
    source_entries = [entry for entry in entries if int(entry[0][1]) not in TARGET_ROWS]
    if (
        len(entries) != 90 or len(source_entries) != 86
        or source_rows != SOURCE_ROWS or len(source_forms) != 413
        or len(target_forms) != 4 or tuple(map(int, (record[0] for record in gauge))) != (0, 1, 2)
    ):
        raise RuntimeError("CF303 hybrid input layout mismatch")
    return {
        "entries": entries, "source_entries": source_entries,
        "source_forms": source_forms, "target_forms": target_forms,
        "gauge": gauge,
    }


def parse_form_records(records, p_value, prime, helper):
    grouped: dict[tuple[int, int], list[list[str]]] = {}
    for record in records:
        key = (int(record[0]) - 1, int(record[1]) - 1)
        channels = grouped.setdefault(key, [[], []])
        for channel, raw in enumerate(record[2]):
            if raw != "0":
                channels[channel].append(raw)
    return [
        (row, column, tuple(
            sympy_sum_to_ext_rf(raws or ["0"], p_value, prime, helper)
            for raws in channels
        ))
        for (row, column), channels in sorted(grouped.items())
    ]


def parse_physical_gauge(records, p_mod, prime, helper):
    result = {}
    for order_raw, matrix_raw in records:
        matrix = []
        for row in matrix_raw:
            parsed_row = []
            for pair in row:
                parsed = tuple(bi_expression_to_rf(
                    ModularExpressionParser(raw, prime, p_mod).parse(), helper
                ) for raw in pair)
                if not parsed[1].zero_q:
                    raise RuntimeError("physical T25 unexpectedly has an elliptic component")
                parsed_row.append(ext_from_base(parsed[0]))
            matrix.append(parsed_row)
        result[int(order_raw)] = matrix
    return result


def parse_incoming_primitives(entries, p_mod, prime, helper):
    source_position = {master: index for index, master in enumerate(SOURCE_ROWS)}
    target_position = {master: index for index, master in enumerate(TARGET_ROWS)}
    incoming = {
        order: [[zero_pair(prime) for _ in SOURCE_ROWS] for _ in TARGET_ROWS]
        for order in ORDERS
    }
    nonzero_leaves = 0
    started = time.perf_counter()
    for entry in entries:
        row = target_position[int(entry[0][0])]
        column = source_position[int(entry[0][1])]
        windows = []
        for raw in entry[2]:
            if raw == "0":
                windows.append({})
            else:
                nonzero_leaves += 1
                parsed = ModularExpressionParser(raw, prime, p_mod).parse()
                windows.append(laurent_coefficients(parsed, helper))
        for order in ORDERS:
            incoming[order][row][column] = (
                ext_from_base(windows[0].get(order, RationalFunction.zero(prime))),
                ext_from_base(windows[1].get(order, RationalFunction.zero(prime))),
            )
    return incoming, nonzero_leaves, time.perf_counter() - started


def load_block1_h(point_resolution, helper):
    prime = point_resolution["prime"]
    result = {}
    for record in point_resolution["outputs"]:
        result[(record["order"], record["row"] - 1)] = RationalFunction.make(
            record["h"]["numerator"], record["h"]["denominator"], prime, helper
        )
    return result


def rf_equal(left, right, helper):
    return left.add(right, helper, -1).zero_q


def ext_equal(left, right, helper):
    return (rf_equal(left[0], right[0], helper)
            and rf_equal(left[1], right[1], helper))


def pair_equal(left, right, helper):
    return ext_equal(left[0], right[0], helper) and ext_equal(left[1], right[1], helper)


def serialize_rf(value: RationalFunction):
    return {
        "numerator": list(value.numerator),
        "denominator": list(value.denominator),
    }


def serialize_ext(value):
    return {
        "base": serialize_rf(value[0]),
        "omega": serialize_rf(value[1]),
    }


def serialize_pair(value):
    return {
        "rational": serialize_ext(value[0]),
        "elliptic": serialize_ext(value[1]),
    }


def adapter_point_payload(p_value: Fraction, merged, cross_k_by_order, report):
    """Expose only the narrow circuit seam used by the lazy Wolfram adapter.

    The accepted incoming K leaves stay in their original transfer/census
    providers.  This payload resolves the two objects newly created by the
    sealed recurrence: merged H and the cross-Hermite K remainder.
    """
    support_positions = tuple(SOURCE_ROWS.index(master)
                              for master in ADAPTER_SUPPORT_MASTERS)
    unsupported = tuple(index for index in range(len(SOURCE_ROWS))
                        if index not in support_positions)
    for order in ORDERS:
        for row in range(len(TARGET_ROWS)):
            if any(not pair_zero(merged[order][row][column])
                   for column in unsupported):
                raise ArithmeticError("adapter H support escaped seven columns")
            if any(not pair_zero(cross_k_by_order[order][row][column])
                   for column in unsupported):
                raise ArithmeticError("adapter cross-K support escaped seven columns")
    if any(not pair_zero(cross_k_by_order[ORDERS[0]][row][column])
           for row in range(len(TARGET_ROWS))
           for column in support_positions):
        raise ArithmeticError("adapter cross-K unexpectedly nonzero at order -3")

    h_outputs = []
    for order in ORDERS:
        for row in range(len(TARGET_ROWS)):
            for column in support_positions:
                h_outputs.append({
                    "order": order,
                    "row": row + 1,
                    "target_master": TARGET_ROWS[row],
                    "column": column + 1,
                    "source_master": SOURCE_ROWS[column],
                    "pair": serialize_pair(merged[order][row][column]),
                })

    cross_outputs = []
    for order in ORDERS[1:]:
        for row in range(len(TARGET_ROWS)):
            for column in support_positions:
                cross_outputs.append({
                    "order": order,
                    "row": row + 1,
                    "target_master": TARGET_ROWS[row],
                    "column": column + 1,
                    "source_master": SOURCE_ROWS[column],
                    "pair": serialize_pair(cross_k_by_order[order][row][column]),
                })

    suffix = f"p{p_value.numerator}d{p_value.denominator}"
    return {
        "status": "CF303HybridBaselineLazyAdapterPointV1",
        "abi_version": 1,
        "prime": Q7,
        "p": [p_value.numerator, p_value.denominator],
        "field": {
            "degree": 2,
            "basis": ["1", "omega"],
            "relation": f"omega^2={EXT_NONRESIDUE}",
            "rational_function_variable": "u",
            "polynomial_coefficients": "ascending",
        },
        "source_rows": list(SOURCE_ROWS),
        "target_rows": list(TARGET_ROWS),
        "h_orders": [ORDERS[0], ORDERS[-1]],
        "cross_k_orders": [ORDERS[1], ORDERS[-1]],
        "support_source_masters": list(ADAPTER_SUPPORT_MASTERS),
        "h_output_count": len(h_outputs),
        "cross_k_output_count": len(cross_outputs),
        "h_outputs": h_outputs,
        "cross_k_outputs": cross_outputs,
        "accepted_point_evidence": str(
            RUNTIME / f"cf303_hybrid_baseline_modular_q7_{suffix}.json"
        ),
        "accepted_comparisons": {
            key: report[key] for key in (
                "baseline_recurrence_comparisons",
                "baseline_basepoint_comparisons",
                "t25_h_scalar_channel_comparisons",
                "t25_cross_k_scalar_channel_comparisons",
            )
        },
    }


def recurrence_point(inputs, p_value: Fraction, helper, elliptic,
                     include_adapter_values=False):
    prime = Q7
    p_mod = p_value.numerator % prime * pow(p_value.denominator % prime, -1, prime) % prime
    resolution = json.loads(point_resolution_path(p_value).read_text())
    if resolution.get("status") != "CF303Block1CircuitPointResolutionAcceptedV1":
        raise RuntimeError("block-1 point resolution is not accepted")
    base = pow(2, -1, prime)
    base_sheet = int(resolution["base_sheet"])
    curve_poly = curve_polynomial(p_mod, prime)
    if sum(value * pow(base, degree, prime)
           for degree, value in enumerate(curve_poly)) % prime != base_sheet * base_sheet % prime:
        raise RuntimeError("block-1 base sheet is inconsistent with P4")
    curve_rf = RationalFunction.make(curve_poly, [1], prime, helper)

    stage_started = time.perf_counter()
    source_forms = parse_form_records(inputs["source_forms"], p_value, prime, helper)
    target_forms = parse_form_records(inputs["target_forms"], p_value, prime, helper)
    diagonal_seconds = time.perf_counter() - stage_started
    incoming, primitive_leaf_count, primitive_seconds = parse_incoming_primitives(
        inputs["source_entries"], p_mod, prime, helper
    )
    stage_started = time.perf_counter()
    gauge = parse_physical_gauge(inputs["gauge"], p_mod, prime, helper)
    gauge_seconds = time.perf_counter() - stage_started

    previous = [[zero_pair(prime) for _ in SOURCE_ROWS] for _ in TARGET_ROWS]
    by_order = {}
    cross_k_by_order = {}
    recurrence_checks = basepoint_checks = 0
    rational_reductions = elliptic_reductions = 0
    cross_nonzero_by_order = {}
    order_seconds = {}
    recurrence_started = time.perf_counter()
    for order in ORDERS:
        order_started = time.perf_counter()
        cross = [[zero_pair(prime) for _ in SOURCE_ROWS] for _ in TARGET_ROWS]
        for row, middle, form in target_forms:
            for column in range(len(SOURCE_ROWS)):
                if not pair_zero(previous[middle][column]):
                    cross[row][column] = pair_add(
                        cross[row][column],
                        function_form_product(previous[middle][column], form, curve_rf, helper),
                        helper,
                    )
        for middle, column, form in source_forms:
            for row in range(len(TARGET_ROWS)):
                if not pair_zero(previous[row][middle]):
                    cross[row][column] = pair_add(
                        cross[row][column],
                        function_form_product(previous[row][middle], form, curve_rf, helper),
                        helper, -1,
                    )
        current = [[zero_pair(prime) for _ in SOURCE_ROWS] for _ in TARGET_ROWS]
        cross_k = [[zero_pair(prime) for _ in SOURCE_ROWS] for _ in TARGET_ROWS]
        cross_nonzero = 0
        for row in range(len(TARGET_ROWS)):
            for column in range(len(SOURCE_ROWS)):
                cross_form = cross[row][column]
                if pair_zero(cross_form):
                    cross_primitive = cross_remainder = zero_pair(prime)
                else:
                    cross_nonzero += 1
                    rational_reductions += sum(
                        int(not component.zero_q) for component in cross_form[0]
                    )
                    elliptic_reductions += sum(
                        int(not component.zero_q) for component in cross_form[1]
                    )
                    cross_primitive, cross_remainder = reduce_form(
                        cross_form, curve_poly, helper, elliptic
                    )
                cross_k[row][column] = cross_remainder
                total_primitive = pair_add(
                    incoming[order][row][column], cross_primitive, helper
                )
                current[row][column] = normalize_at_base(
                    total_primitive, base, base_sheet, helper
                )
                rational_value = ext_evaluate(current[row][column][0], base)
                elliptic_value = ext_evaluate(current[row][column][1], base)
                base_value = (
                    (rational_value[0] + base_sheet * elliptic_value[0]) % prime,
                    (rational_value[1] + base_sheet * elliptic_value[1]) % prime,
                )
                if base_value != (0, 0):
                    raise ArithmeticError(f"basepoint failure {order}:{row}:{column}")
                basepoint_checks += 1
                left = pair_add(
                    derivative_function_pair(current[row][column], curve_rf, helper),
                    cross_remainder, helper,
                )
                right = pair_add(
                    derivative_function_pair(incoming[order][row][column], curve_rf, helper),
                    cross_form, helper,
                )
                if not pair_equal(left, right, helper):
                    raise ArithmeticError(f"recurrence failure {order}:{row}:{column}")
                recurrence_checks += 1
        by_order[order] = current
        cross_k_by_order[order] = cross_k
        previous = current
        cross_nonzero_by_order[str(order)] = cross_nonzero
        order_seconds[str(order)] = time.perf_counter() - order_started
        print(json.dumps({
            "point": [p_value.numerator, p_value.denominator],
            "order": order, "cross_nonzero": cross_nonzero,
            "seconds": order_seconds[str(order)],
        }), flush=True)
    recurrence_seconds = time.perf_counter() - recurrence_started

    block1_h = load_block1_h(resolution, helper)
    merged = {
        order: [[pair for pair in row] for row in by_order[order]]
        for order in ORDERS
    }
    for order in ORDERS:
        for row in range(2):
            rational_channel = merged[order][row][0][0]
            merged[order][row][0] = (
                (
                    rational_channel[0].add(block1_h[(order, row)], helper),
                    rational_channel[1],
                ),
                merged[order][row][0][1],
            )

    path_value = 7 % prime
    t25_h_checks = 0
    for output_order in TARGET_ORDERS:
        for output_row in range(2):
            for column in range(len(SOURCE_ROWS)):
                generic = [(0, 0), (0, 0)]
                direct = [(0, 0), (0, 0)]
                for gauge_order, matrix in gauge.items():
                    h_order = output_order - gauge_order
                    if h_order not in merged:
                        continue
                    for middle in range(2):
                        gauge_value = ext_evaluate(matrix[output_row][middle], path_value)
                        for channel in range(2):
                            direct[channel] = fq2_add(
                                direct[channel],
                                fq2_multiply(
                                    gauge_value,
                                    ext_evaluate(
                                        merged[h_order][middle][column][channel],
                                        path_value,
                                    ), prime,
                                ), prime,
                            )
                            product = ext_multiply(
                                matrix[output_row][middle],
                                merged[h_order][middle][column][channel], helper
                            )
                            generic[channel] = fq2_add(
                                generic[channel], ext_evaluate(product, path_value), prime
                            )
                if generic != direct:
                    raise ArithmeticError(
                        f"T25 replay failure {output_order}:{output_row}:{column}"
                    )
                t25_h_checks += 4

    # The accepted incoming residue leaves are unchanged.  Replay every new
    # cross-Hermite K vector that can contribute through target eps^2.
    t25_k_checks = 0
    nonzero_cross_k_vectors = 0
    for order in ORDERS:
        for column in range(len(SOURCE_ROWS)):
            vector = [cross_k_by_order[order][row][column] for row in range(2)]
            if all(pair_zero(value) for value in vector):
                continue
            nonzero_cross_k_vectors += 1
            for gauge_order, matrix in gauge.items():
                if order + gauge_order not in TARGET_ORDERS:
                    continue
                for output_row in range(2):
                    generic = [(0, 0), (0, 0)]
                    direct = [(0, 0), (0, 0)]
                    for middle in range(2):
                        gauge_value = ext_evaluate(matrix[output_row][middle], path_value)
                        for channel in range(2):
                            direct[channel] = fq2_add(
                                direct[channel],
                                fq2_multiply(
                                    gauge_value,
                                    ext_evaluate(vector[middle][channel], path_value),
                                    prime,
                                ), prime,
                            )
                            product = ext_multiply(
                                matrix[output_row][middle], vector[middle][channel], helper
                            )
                            generic[channel] = fq2_add(
                                generic[channel], ext_evaluate(product, path_value), prime
                            )
                    if generic != direct:
                        raise ArithmeticError(
                            f"T25 K replay failure {order}:{gauge_order}:{output_row}:{column}"
                        )
                    t25_k_checks += 4

    status = (
        recurrence_checks == 8 * 2 * 43
        and basepoint_checks == 8 * 2 * 43
        and t25_h_checks == 7 * 2 * 43 * 4
        and t25_k_checks > 0
    )
    if not status:
        raise ArithmeticError("point acceptance count mismatch")
    report = {
        "status": "CF303HybridBaselineModularCircuitPointAcceptedV1",
        "prime": prime, "p": [p_value.numerator, p_value.denominator],
        "path_value": path_value,
        "baseline_recurrence_comparisons": recurrence_checks,
        "baseline_basepoint_comparisons": basepoint_checks,
        "t25_h_scalar_channel_comparisons": t25_h_checks,
        "t25_cross_k_scalar_channel_comparisons": t25_k_checks,
        "t25_scalar_channel_comparisons": t25_h_checks + t25_k_checks,
        "nonzero_cross_k_vectors": nonzero_cross_k_vectors,
        "coefficient_field": f"F_q2 with omega^2={EXT_NONRESIDUE}",
        "rational_cross_reductions": rational_reductions,
        "elliptic_cross_reductions": elliptic_reductions,
        "cross_nonzero_by_order": cross_nonzero_by_order,
        "block1_outputs_merged": len(block1_h),
        "primitive_nonzero_exact_leaves": primitive_leaf_count,
        "timings": {
            "diagonal_specialization": diagonal_seconds,
            "incoming_primitive_specialization": primitive_seconds,
            "physical_gauge_specialization": gauge_seconds,
            "recurrence": recurrence_seconds,
            "orders": order_seconds,
        },
        "degree_summary": {
            "maximum_h_numerator": max(
                len(pair[channel][extension].numerator) - 1
                for matrices in by_order.values() for row in matrices
                for pair in row for channel in range(2) for extension in range(2)
            ),
            "maximum_h_denominator": max(
                len(pair[channel][extension].denominator) - 1
                for matrices in by_order.values() for row in matrices
                for pair in row for channel in range(2) for extension in range(2)
            ),
        },
        "acceptance": (
            "Every baseline recurrence and basepoint coordinate passed exactly "
            "in the split F_q/F_q2 image; merged H and every demanded new "
            "cross-Hermite K vector passed T25 at u=7."
        ),
    }
    if include_adapter_values:
        report["_adapter_point"] = adapter_point_payload(
            p_value, merged, cross_k_by_order, report
        )
    return report


def manifest(point_outputs: list[Path], reports: list[dict[str, Any]]):
    return {
        "status": "CF303HybridBaselineDeferredExactCircuitAcceptedV1",
        "family": "CF303", "block": 25,
        "source_master_count": 43, "target_rows": [44, 45],
        "orders": [-3, 4], "physical_gauge_orders": [0, 1, 2],
        "modular_evaluator_field": f"F_q2 with omega^2={EXT_NONRESIDUE}",
        "t25_validation_path_value": 7,
        "incoming_coordinate_count": 86,
        "nonzero_incoming_primitive_leaf_count": 12,
        "exact_leaf_provenance": {
            "base_transfer_76_plus_exceptions_12_plus_zero_block1_2": str(TRANSFER),
            "source_and_target_dlog_forms": str(PATH_INPUT),
            "physical_gauge_T25": str(PHYSICAL_GAUGE),
            "block1_point_resolver_pattern": str(
                RUNTIME / f"cf303_block1_circuit_resolved_q{Q7}_pNUMdDEN.json"
            ),
        },
        "sealed_operations": [
            "Add", "Multiply", "Derivative",
            "DeterministicRationalHermite",
            "DeterministicQuarticHermite",
            "NormalizeHAtBasePoint", "AcceptedIncomingRemainderLeaf",
            "CrossHermiteRemainder", "T25Convolution",
        ],
        "recurrence": "K_n=B_n+D.H_(n-1)-H_(n-1).S-dH_n; H(1/2)=0",
        "representation": (
            "Original exact leaves plus sealed arithmetic/Hermite nodes; "
            "modular point images are evaluator evidence, not the exact object."
        ),
        "evaluator": str(Path(__file__).resolve()),
        "accepted_point_outputs": list(map(str, point_outputs)),
        "acceptance_totals": {
            "points": len(reports),
            "baseline_recurrence_comparisons": sum(
                report["baseline_recurrence_comparisons"] for report in reports
            ),
            "baseline_basepoint_comparisons": sum(
                report["baseline_basepoint_comparisons"] for report in reports
            ),
            "t25_scalar_channel_comparisons": sum(
                report["t25_scalar_channel_comparisons"] for report in reports
            ),
            "t25_h_scalar_channel_comparisons": sum(
                report["t25_h_scalar_channel_comparisons"] for report in reports
            ),
            "t25_cross_k_scalar_channel_comparisons": sum(
                report["t25_cross_k_scalar_channel_comparisons"] for report in reports
            ),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--p", type=Fraction)
    parser.add_argument("--all-q7", action="store_true")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--adapter-output", type=Path, help=(
        "write the lazy-adapter H/cross-K point ABI; with no --output, "
        "leave the accepted summary artifact untouched"
    ))
    parser.add_argument("--manifest-output", type=Path, default=(
        RUNTIME / "cf303_hybrid_baseline_modular_circuit_manifest.json"
    ))
    args = parser.parse_args()
    points = [Fraction(3), Fraction(239, 47)] if args.all_q7 else [args.p or Fraction(3)]
    if args.adapter_output and len(points) != 1:
        parser.error("--adapter-output requires one --p point")
    helper = load_module("cf303_hybrid_rational_helper", RATIONAL_HELPER)
    elliptic = load_module("cf303_hybrid_elliptic_helper", ELLIPTIC_HELPER)
    inputs = parse_inputs()
    reports, outputs = [], []
    for point in points:
        started = time.perf_counter()
        report = recurrence_point(
            inputs, point, helper, elliptic,
            include_adapter_values=args.adapter_output is not None,
        )
        adapter_point = report.pop("_adapter_point", None)
        report["timings"]["total"] = time.perf_counter() - started
        report["peak_rss_kib"] = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
        if args.adapter_output:
            args.adapter_output.write_text(json.dumps(adapter_point, indent=2) + "\n")
            print(json.dumps({
                "status": adapter_point["status"],
                "p": adapter_point["p"],
                "output": str(args.adapter_output),
            }), flush=True)
        if args.adapter_output and args.output is None:
            reports.append(report)
            continue
        output = args.output if len(points) == 1 and args.output else RUNTIME / (
            f"cf303_hybrid_baseline_modular_q7_p{point.numerator}d{point.denominator}.json"
        )
        output.write_text(json.dumps(report, indent=2) + "\n")
        reports.append(report)
        outputs.append(output)
        print(json.dumps({
            "status": report["status"], "p": report["p"],
            "seconds": report["timings"]["total"], "output": str(output),
        }), flush=True)
    if args.all_q7:
        circuit = manifest(outputs, reports)
        args.manifest_output.write_text(json.dumps(circuit, indent=2) + "\n")
        print(json.dumps({
            "status": circuit["status"], "manifest": str(args.manifest_output),
            "totals": circuit["acceptance_totals"],
        }), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
