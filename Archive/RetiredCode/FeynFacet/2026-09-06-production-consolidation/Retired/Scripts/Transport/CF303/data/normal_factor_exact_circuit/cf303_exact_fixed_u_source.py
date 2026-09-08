#!/usr/bin/env python3
"""Exact fixed-u compiler for demanded CF303 block-(25,1) source data.

The large deferred source is kept as its term DAG.  Individual factors are
compiled with the repository postfix parser and evaluated in the quadratic
residual-root extension of Q(eps) after fixing p and u.  This is the narrow
characteristic-zero primitive needed by the degree-bounded Hermite
reconstruction; it never materializes a rational function in both u and eps.
"""

from __future__ import annotations

import gzip
import importlib.util
import sys
import time
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Any, Iterable

from sympy import QQ
from sympy.polys.fields import field


BUNDLE = Path(__file__).resolve().parent
REPOSITORY = BUNDLE.parents[4]
SOURCE = BUNDLE / "CF303_25_1_input.wl.gz"
POSTFIX_MODULE = (
    REPOSITORY / "FeynFacet/Backends/native_postfix/deferred_gpu.py"
)
ROOT_EXPRESSIONS = (
    "1 + 2*x + x^2 - 2*y + 2*x*y + y^2",  # Delta2
    "1 - 2*x + x^2 + 2*y + 2*x*y + y^2",  # Delta1, residual
    "1 - 4*x*y",                            # Delta3
)


class ExactFixedUSourceRefusal(RuntimeError):
    """Typed refusal for malformed or out-of-domain exact source requests."""

    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


@dataclass(frozen=True)
class CompiledExpression:
    source_text: str
    postfix: tuple[tuple[int, int], ...]


@dataclass(frozen=True)
class CompiledTerm:
    expression_indices: tuple[int, ...]


@dataclass(frozen=True)
class FixedUSourceValue:
    row: int
    tangential_point: Fraction
    path_point: Fraction
    epsilon_order: int
    rational_laurent_coefficient: Fraction
    residual_root_laurent_coefficient: Fraction
    expression_count: int
    postfix_operation_count: int
    evaluation_seconds: float


def _load_postfix_module():
    sys.path.insert(0, str(POSTFIX_MODULE.parent))
    specification = importlib.util.spec_from_file_location(
        "cf303_exact_fixed_u_postfix", POSTFIX_MODULE
    )
    if specification is None or specification.loader is None:
        raise ExactFixedUSourceRefusal("CF303ExactPostfixParserUnavailable")
    module = importlib.util.module_from_spec(specification)
    sys.modules[specification.name] = module
    specification.loader.exec_module(module)
    return module


def _fraction(value: Any) -> Fraction:
    if isinstance(value, Fraction):
        return value
    numerator = int(value.numerator)
    denominator = int(value.denominator)
    return Fraction(numerator, denominator)


def _laurent_coefficient(value: Any, order: int) -> Fraction:
    """Coefficient of eps^order in an exact Q(eps) field element."""
    if not value:
        return Fraction(0)
    numerator = {
        exponent[0]: _fraction(coefficient)
        for exponent, coefficient in value.numer.terms()
    }
    denominator = {
        exponent[0]: _fraction(coefficient)
        for exponent, coefficient in value.denom.terms()
    }
    if not denominator:
        raise ExactFixedUSourceRefusal("CF303ExactEpsilonDenominatorZero")
    if not numerator:
        return Fraction(0)
    numerator_valuation = min(numerator)
    denominator_valuation = min(denominator)
    valuation = numerator_valuation - denominator_valuation
    if order < valuation:
        return Fraction(0)
    normalized_numerator = {
        exponent - numerator_valuation: coefficient
        for exponent, coefficient in numerator.items()
    }
    normalized_denominator = {
        exponent - denominator_valuation: coefficient
        for exponent, coefficient in denominator.items()
    }
    leading = normalized_denominator[0]
    quotient: list[Fraction] = []
    for degree in range(order - valuation + 1):
        source = normalized_numerator.get(degree, Fraction(0))
        correction = sum(
            normalized_denominator.get(shift, Fraction(0))
            * quotient[degree - shift]
            for shift in range(1, degree + 1)
        )
        quotient.append((source - correction) / leading)
    return quotient[-1]


def _evaluate_epsilon_rational(value: Any,
                               epsilon_value: Fraction) -> Fraction:
    if not value:
        return Fraction(0)

    def evaluate(polynomial) -> Fraction:
        coefficients = {
            exponent[0]: _fraction(coefficient)
            for exponent, coefficient in polynomial.terms()
        }
        return sum(
            coefficient * epsilon_value**exponent
            for exponent, coefficient in coefficients.items()
        )

    numerator = evaluate(value.numer)
    denominator = evaluate(value.denom)
    if denominator == 0:
        raise ExactFixedUSourceRefusal(
            "CF303ExactEpsilonEvaluationPole",
            Epsilon=[epsilon_value.numerator, epsilon_value.denominator],
        )
    return numerator / denominator


class ExactFixedUSourceCompiler:
    """Compile and evaluate only the two records for one demanded row."""

    def __init__(self, row: int = 2, source: Path = SOURCE) -> None:
        if row not in (1, 2):
            raise ExactFixedUSourceRefusal(
                "CF303ExactFixedUSourceRowInvalid", Row=row
            )
        if not source.is_file():
            raise ExactFixedUSourceRefusal(
                "CF303ExactDeferredSourceMissing", RelativePath=source.name
            )
        self.row = row
        self.source = source
        self.postfix = _load_postfix_module()
        started = time.perf_counter()
        with gzip.open(source, "rt") as stream:
            self.text = stream.read()
        self.expressions, self.records, self.constants = self._compile_records()
        self.compile_seconds = time.perf_counter() - started
        self.postfix_operation_count = sum(
            len(expression.postfix) for expression in self.expressions
        )

    def _compile_records(self):
        parser = self.postfix
        top = parser.association(self.text, (0, len(self.text)))
        for field_name, expected in (
            ("Family", '"CF303"'), ("Sector", "25"),
            ("LowerSector", "1"),
        ):
            observed = parser.slice_value(self.text, top[field_name])
            if observed != expected:
                raise ExactFixedUSourceRefusal(
                    "CF303ExactDeferredSourceMetadataMismatch",
                    Field=field_name, Expected=expected, Observed=observed,
                )
        deferred = parser.association(self.text, top["DeferredPreparation"])
        preparation = parser.association(self.text, deferred["Preparation"])
        record_spans = parser.list_spans(self.text, preparation["Records"])
        request = parser.Request(
            2_305_843_009_213_693_967,
            ("x", "y", "eps"), ROOT_EXPRESSIONS,
            1, 8, [], [], [],
        )
        constant_indices: dict[int, int] = {}
        expression_indices: dict[str, int] = {}
        expressions: list[CompiledExpression] = []
        records: dict[int, tuple[CompiledTerm, ...]] = {}

        def intern(raw: str) -> int:
            normalized = parser.normalized(raw)
            known = expression_indices.get(normalized)
            if known is not None:
                return known
            code = tuple(parser.ExpressionCompiler(
                raw, request, constant_indices=constant_indices
            ).compile())
            index = len(expressions)
            expression_indices[normalized] = index
            expressions.append(CompiledExpression(raw, code))
            return index

        for record_span in record_spans:
            record = parser.association(self.text, record_span)
            target = tuple(
                int(parser.slice_value(self.text, item))
                for item in parser.list_spans(self.text, record["Target"])
            )
            if target not in ((1, self.row, 1), (2, self.row, 1)):
                continue
            terms = []
            for term_span in parser.list_spans(self.text, record["Terms"]):
                term = parser.association(self.text, term_span)
                raw_factors = [parser.slice_value(
                    self.text, term["Coefficient"]
                )]
                raw_factors.extend(
                    parser.slice_value(self.text, item)
                    for item in parser.list_spans(self.text, term["Operands"])
                )
                terms.append(CompiledTerm(tuple(map(intern, raw_factors))))
            records[target[0]] = tuple(terms)
        if set(records) != {1, 2} or any(len(value) != 36 for value in records.values()):
            raise ExactFixedUSourceRefusal(
                "CF303ExactDeferredSourceRecordLayoutInvalid",
                DifferentialComponents=sorted(records),
                TermCounts={key: len(value) for key, value in records.items()},
            )
        reverse_constants = [0] * len(constant_indices)
        for value, index in constant_indices.items():
            reverse_constants[index] = value
        return tuple(expressions), records, tuple(reverse_constants)

    @staticmethod
    def _path_data(tangential_point: Fraction, path_point: Fraction):
        p = tangential_point
        u = path_point
        k = 4 * p * (1 - p)
        denominator = u * u + k
        if denominator == 0:
            raise ExactFixedUSourceRefusal(
                "CF303ExactPathPointPole", PathPoint=[u.numerator, u.denominator]
            )
        a = (k - 2 * u) / denominator
        derivative_a = (
            -2 * denominator - (k - 2 * u) * 2 * u
        ) / denominator**2
        x = -a * p
        y = (1 - a) * (1 - p)
        dx = -p * derivative_a
        dy = -(1 - p) * derivative_a
        delta1 = 1 - 2*x + x*x + 2*y + 2*x*y + y*y
        delta2 = 1 + 2*x + x*x - 2*y + 2*x*y + y*y
        delta3 = 1 - 4*x*y
        root2 = a - p
        root3 = 1 + u*a
        if root2 * root2 != delta2 or root3 * root3 != delta3:
            raise ExactFixedUSourceRefusal("CF303ExactPathRootIdentityFailed")
        return x, y, dx, dy, delta1, root2, root3

    def _evaluate_expression(self, expression: CompiledExpression,
                             inputs: tuple[Any, ...], field_domain: Any,
                             residual_square: Any):
        parser = self.postfix
        zero, one = field_domain.zero, field_domain.one

        def add(left, right):
            return left[0] + right[0], left[1] + right[1]

        def multiply(left, right):
            return (
                left[0] * right[0]
                + residual_square * left[1] * right[1],
                left[0] * right[1] + left[1] * right[0],
            )

        def inverse(value):
            norm = value[0] * value[0] - residual_square * value[1] * value[1]
            if not norm:
                raise ExactFixedUSourceRefusal(
                    "CF303ExactQuadraticDenominatorNormZero"
                )
            return value[0] / norm, -value[1] / norm

        def power(value, exponent: int):
            result = one, zero
            factor = value
            while exponent:
                if exponent & 1:
                    result = multiply(result, factor)
                exponent >>= 1
                if exponent:
                    factor = multiply(factor, factor)
            return result

        stack = []
        for operation, argument in expression.postfix:
            if operation == parser.CONST:
                stack.append((field_domain(self.constants[argument]), zero))
            elif operation == parser.INPUT:
                stack.append(inputs[argument])
            elif operation == parser.ADD:
                right = stack.pop()
                stack[-1] = add(stack[-1], right)
            elif operation == parser.SUB:
                right = stack.pop()
                stack[-1] = add(stack[-1], (-right[0], -right[1]))
            elif operation == parser.MUL:
                right = stack.pop()
                stack[-1] = multiply(stack[-1], right)
            elif operation == parser.INV:
                stack[-1] = inverse(stack[-1])
            elif operation == parser.NEG:
                stack[-1] = -stack[-1][0], -stack[-1][1]
            elif operation == parser.POW:
                stack[-1] = power(stack[-1], argument)
            else:
                raise ExactFixedUSourceRefusal(
                    "CF303ExactPostfixOperationUnsupported",
                    Operation=operation,
                )
        if len(stack) != 1:
            raise ExactFixedUSourceRefusal("CF303ExactPostfixStackInvalid")
        return stack[0]

    @staticmethod
    def _pair_add(left, right):
        return left[0] + right[0], left[1] + right[1]

    @staticmethod
    def _pair_multiply(left, right, residual_square):
        return (
            left[0] * right[0] + residual_square * left[1] * right[1],
            left[0] * right[1] + left[1] * right[0],
        )

    def evaluate(self, path_point: Fraction, epsilon_order: int,
                 tangential_point: Fraction = Fraction(4, 11)) -> FixedUSourceValue:
        path_point = Fraction(path_point)
        tangential_point = Fraction(tangential_point)
        if not isinstance(epsilon_order, int):
            raise ExactFixedUSourceRefusal(
                "CF303ExactEpsilonOrderInvalid", EpsilonOrder=epsilon_order
            )
        x, y, dx, dy, delta1, root2, root3 = self._path_data(
            tangential_point, path_point
        )
        epsilon_field, epsilon = field("eps", QQ)
        zero, one = epsilon_field.zero, epsilon_field.one
        constant = lambda value: (epsilon_field(value), zero)
        inputs = (
            constant(x), constant(y), (epsilon, zero), constant(root2),
            (zero, one), constant(root3),
        )
        residual_square = epsilon_field(delta1)
        started = time.perf_counter()
        values = tuple(
            self._evaluate_expression(
                expression, inputs, epsilon_field, residual_square
            )
            for expression in self.expressions
        )
        record_values = {}
        for differential_component, terms in self.records.items():
            total = zero, zero
            for term in terms:
                value = one, zero
                for expression_index in term.expression_indices:
                    value = self._pair_multiply(
                        value, values[expression_index], residual_square
                    )
                total = self._pair_add(total, value)
            record_values[differential_component] = total
        pulled_back = self._pair_add(
            (epsilon_field(dx) * record_values[1][0],
             epsilon_field(dx) * record_values[1][1]),
            (epsilon_field(dy) * record_values[2][0],
             epsilon_field(dy) * record_values[2][1]),
        )
        return FixedUSourceValue(
            row=self.row,
            tangential_point=tangential_point,
            path_point=path_point,
            epsilon_order=epsilon_order,
            rational_laurent_coefficient=_laurent_coefficient(
                pulled_back[0], epsilon_order
            ),
            residual_root_laurent_coefficient=_laurent_coefficient(
                pulled_back[1], epsilon_order
            ),
            expression_count=len(self.expressions),
            postfix_operation_count=self.postfix_operation_count,
            evaluation_seconds=time.perf_counter() - started,
        )

    def evaluate_expression_at_rational_epsilon(
        self, expression_index: int, path_point: Fraction,
        epsilon_value: Fraction,
        tangential_point: Fraction = Fraction(4, 11),
    ) -> tuple[Fraction, Fraction, Fraction]:
        """Return the two quadratic-field coordinates of one source factor."""
        if not 0 <= expression_index < len(self.expressions):
            raise ExactFixedUSourceRefusal(
                "CF303ExactExpressionIndexInvalid", Index=expression_index
            )
        path_point = Fraction(path_point)
        epsilon_value = Fraction(epsilon_value)
        tangential_point = Fraction(tangential_point)
        x, y, _dx, _dy, delta1, root2, root3 = self._path_data(
            tangential_point, path_point
        )
        epsilon_field, epsilon = field("eps", QQ)
        zero, one = epsilon_field.zero, epsilon_field.one
        constant = lambda value: (epsilon_field(value), zero)
        inputs = (
            constant(x), constant(y), (epsilon, zero), constant(root2),
            (zero, one), constant(root3),
        )
        pair = self._evaluate_expression(
            self.expressions[expression_index], inputs, epsilon_field,
            epsilon_field(delta1),
        )
        return (
            _evaluate_epsilon_rational(pair[0], epsilon_value),
            _evaluate_epsilon_rational(pair[1], epsilon_value),
            delta1,
        )

    def pilot_expression(self, minimum_operations: int = 20,
                         maximum_operations: int = 1000):
        """Return a small nontrivial real source factor for parser QA."""
        candidates = [
            (index, expression)
            for index, expression in enumerate(self.expressions)
            if minimum_operations <= len(expression.postfix) <= maximum_operations
            and "eps" in expression.source_text
            and self.postfix.normalized(ROOT_EXPRESSIONS[1]) in
                self.postfix.normalized(expression.source_text)
        ]
        if not candidates:
            raise ExactFixedUSourceRefusal(
                "CF303ExactPilotExpressionUnavailable",
                OperationWindow=[minimum_operations, maximum_operations],
            )
        return min(candidates, key=lambda item: len(item[1].postfix))


def fraction_pair(value: Fraction) -> list[int]:
    return [value.numerator, value.denominator]


__all__ = [
    "ExactFixedUSourceCompiler", "ExactFixedUSourceRefusal",
    "FixedUSourceValue", "fraction_pair",
]
