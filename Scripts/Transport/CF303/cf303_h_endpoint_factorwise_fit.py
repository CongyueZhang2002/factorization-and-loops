#!/usr/bin/env python3
"""Factorwise finite-field fit of the CF303 rho^0 H coefficients.

For the six modes whose regulator support is closed, the normalized boundary
value is represented as

    (endpoint/cross remainder) - (exact baseline value at u=1/2).

The second factor is obtained directly from the exact transfer in F_q(p).  The
first is polynomial after clearing a mode-specific regulator assembled from
the exact baseline and diagonal-system denominators plus validated endpoint
factors.  Modes whose factor support is not closed are reported, not guessed.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import time
from pathlib import Path
from typing import Any

import sympy

import cf303_h_endpoint_interpolate as endpoint
import cf303_h_endpoint_known_denominator_interpolate as polynomial


HERE = Path(__file__).resolve().parent
BUNDLE = HERE / "data/normal_factor_exact_circuit"
EVALUATOR = BUNDLE / "cf303_hybrid_baseline_modular_circuit.py"
COMPLETE_MODES = (2, 3, 4, 5, 6, 7)


class FactorwiseFitRefusal(RuntimeError):
    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise FactorwiseFitRefusal(
            "CF303FactorwiseFitProviderUnavailable", Provider=path.name
        )
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def exact_polynomial_mod_prime(expression, variable, prime: int) -> list[int]:
    value = sympy.Poly(expression, variable, domain=sympy.QQ)
    result = []
    for degree in range(value.degree() + 1):
        coefficient = value.nth(degree)
        result.append(
            int(coefficient.p) * pow(int(coefficient.q), -1, prime) % prime
        )
    return result


def diagonal_normalization_regulator(evaluator, helper, prime: int) -> list[int]:
    inputs = evaluator.parse_inputs()
    p, u, final = sympy.symbols("p u uFinal")
    support_positions = {
        evaluator.SOURCE_ROWS.index(master)
        for master in evaluator.ADAPTER_SUPPORT_MASTERS
    }
    records = [
        record for record in inputs["source_forms"]
        if int(record[0]) - 1 in support_positions
        and int(record[1]) - 1 in support_positions
    ] + list(inputs["target_forms"])
    result = [1]
    for record in records:
        terms = []
        for raw in record[2]:
            if raw == "0":
                continue
            terms.append(sympy.sympify(
                raw.replace("^", "**").replace("[", "(").replace("]", ")"),
                locals={"p": p, "u": u, "uFinal": final,
                        "Sqrt": sympy.sqrt},
            ).subs({u: sympy.Rational(1, 2), final: 0}))
        rationalized = sympy.cancel(sympy.radsimp(sympy.Add(*terms)))
        denominator = sympy.fraction(rationalized)[1]
        result = helper.lcm_poly(
            result, exact_polynomial_mod_prime(denominator, p, prime), prime
        )
    return result


def block_endpoint_regulator(
    evaluator, helper, prime: int, support_masters: tuple[int, ...]
) -> tuple[list[int], list[dict[str, Any]]]:
    """Return square-free p factors of selected connection denominators.

    The moving-boundary recurrence sees the coefficient of the first nonzero
    rho power in every denominator, where rho=2*p-u.  Taking its square-free
    part records only the possible tangential pole support; multiplicities
    already present in the fitted regulator are retained by the outer LCM.
    """
    inputs = evaluator.parse_inputs()
    p, u, final, rho = sympy.symbols("p u uFinal rho")
    support_positions = {
        evaluator.SOURCE_ROWS.index(master) for master in support_masters
    }
    grouped: dict[tuple[str, int, int], list[list[str]]] = {}
    for record in inputs["source_forms"]:
        row, column = int(record[0]) - 1, int(record[1]) - 1
        if row not in support_positions or column not in support_positions:
            continue
        channels = grouped.setdefault(
            ("SourceConnection", evaluator.SOURCE_ROWS[row],
             evaluator.SOURCE_ROWS[column]), [[], []]
        )
        for channel, raw in enumerate(record[2]):
            if raw != "0":
                channels[channel].append(raw)
    for record in inputs["target_forms"]:
        channels = grouped.setdefault(
            ("TargetConnection", int(record[0]), int(record[1])), [[], []]
        )
        for channel, raw in enumerate(record[2]):
            if raw != "0":
                channels[channel].append(raw)

    result = [1]
    records = []
    for (kind, row, column), channels in sorted(grouped.items()):
        for channel, raw_terms in enumerate(channels):
            if not raw_terms:
                continue
            terms = [
                sympy.sympify(
                    raw.replace("^", "**").replace("[", "(").replace("]", ")"),
                    locals={"p": p, "u": u, "uFinal": final,
                            "Sqrt": sympy.sqrt},
                ).subs(final, 0)
                for raw in raw_terms
            ]
            expression = sympy.cancel(sympy.radsimp(sympy.Add(*terms)))
            denominator = sympy.fraction(expression)[1]
            shifted = sympy.Poly(
                sympy.expand(denominator.subs(u, 2*p - rho)), rho,
                domain="EX",
            )
            nonzero = [degree for degree in range(shifted.degree() + 1)
                       if shifted.nth(degree) != 0]
            if not nonzero:
                raise FactorwiseFitRefusal(
                    "CF303FactorwiseFitEndpointDenominatorVanished",
                    Kind=kind, Row=row, Column=column, Channel=channel,
                )
            rho_valuation = nonzero[0]
            leading = sympy.cancel(shifted.nth(rho_valuation))
            numerator, scalar_denominator = sympy.fraction(leading)
            if scalar_denominator.free_symbols or numerator.free_symbols - {p}:
                raise FactorwiseFitRefusal(
                    "CF303FactorwiseFitEndpointDenominatorNotRationalInTangentialVariable",
                    Kind=kind, Row=row, Column=column, Channel=channel,
                )
            polynomial = sympy.Poly(numerator, p, domain=sympy.QQ)
            square_free = polynomial.sqf_part().monic()
            modular = exact_polynomial_mod_prime(square_free.as_expr(), p, prime)
            result = helper.lcm_poly(result, modular, prime)
            factors = [
                str(factor.monic().as_expr())
                for factor, _multiplicity in sympy.factor_list(square_free)[1]
                if factor.degree() > 0
            ]
            records.append({
                "ConnectionKind": kind, "Row": row, "Column": column,
                "Channel": channel, "NormalCoordinateDenominatorValuation":
                    rho_valuation,
                "TangentialDenominatorFactors": factors,
            })
    return result, records


def sample_values(sample: dict[str, Any]) -> dict[str, int]:
    return {
        f"{record['InheritedModeIndex']}:{record['EpsilonOrder']}:"
        f"{record['TargetMasterIntegralRow']}:"
        f"{record['NormalCoordinatePower']}": int(record["Value"])
        for record in sample["Records"]
    }


def rational_value(record: dict[str, Any], point: int, prime: int) -> int:
    numerator = polynomial.evaluate_polynomial(
        record["NumeratorCoefficientsModuloPrime"], point, prime
    )
    denominator = polynomial.evaluate_polynomial(
        record["DenominatorCoefficientsModuloPrime"], point, prime
    )
    if denominator == 0:
        raise FactorwiseFitRefusal(
            "CF303FactorwiseFitBaselinePole", Key=record["Key"], Point=point
        )
    return numerator * pow(denominator, -1, prime) % prime


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample-directory", type=Path, required=True)
    parser.add_argument("--baseline-at-base", type=Path, required=True)
    parser.add_argument("--endpoint-leading-profile", type=Path, required=True)
    parser.add_argument("--total-degree-profile", type=Path, required=True)
    parser.add_argument("--held-out-count", type=int, default=3)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    try:
        baseline = json.loads(arguments.baseline_at_base.read_text())
        if (baseline.get("DataType") !=
                "CF303BaselinePathGaugeNormalizationValueFiniteFieldProfile"
                or baseline.get("Status") !=
                "CF303BaselinePathGaugeNormalizationValueFiniteFieldProfileValidated"):
            raise FactorwiseFitRefusal("CF303FactorwiseFitBaselineNotAccepted")
        prime = int(baseline["Prime"])
        baseline_by_key = {
            record["Key"]: record for record in baseline["Coordinates"]
        }
        leading = json.loads(arguments.endpoint_leading_profile.read_text())
        total = json.loads(arguments.total_degree_profile.read_text())
        if int(leading.get("prime", -1)) != prime or int(total.get("prime", -1)) != prime:
            raise FactorwiseFitRefusal("CF303FactorwiseFitProfilePrimeMismatch")
        leading_by_key = {record["key"]: record
                          for record in leading.get("coordinates", [])}
        total_by_key = {record["key"]: record
                        for record in total.get("coordinates", [])}
        paths = sorted(arguments.sample_directory.glob("p*.json"),
                       key=endpoint.numeric_point)
        if arguments.held_out_count < 3 or len(paths) <= arguments.held_out_count:
            raise FactorwiseFitRefusal(
                "CF303FactorwiseFitIndependentImagesMissing"
            )
        first = endpoint.read_sample(paths[0], prime)
        samples = [first] + [endpoint.read_sample(path, prime)
                             for path in paths[1:]]
        abscissae = [
            int(sample["TangentialPoint"][0])
            * pow(int(sample["TangentialPoint"][1]), -1, prime) % prime
            for sample in samples
        ]
        values = [sample_values(sample) for sample in samples]
        evaluator = load_module(f"cf303_factorwise_evaluator_{prime}", EVALUATOR)
        helper = evaluator.load_module(
            f"cf303_factorwise_polynomial_{prime}", evaluator.RATIONAL_HELPER
        )
        diagonal_regulator = diagonal_normalization_regulator(
            evaluator, helper, prime
        )
        mode5_endpoint_regulator, mode5_endpoint_factor_records = (
            block_endpoint_regulator(evaluator, helper, prime, (21, 22))
        )
        started = time.perf_counter()
        outputs = []
        regulator_records = []
        for mode in COMPLETE_MODES:
            regulator = diagonal_regulator
            for record in baseline["Coordinates"]:
                if record["InheritedModeIndex"] == mode:
                    regulator = helper.lcm_poly(
                        regulator,
                        record["DenominatorCoefficientsModuloPrime"], prime,
                    )
            for target in evaluator.TARGET_ROWS:
                key = f"{mode}:-3:{target}:0"
                if key not in leading_by_key:
                    raise FactorwiseFitRefusal(
                        "CF303FactorwiseFitEndpointLeadingFactorMissing",
                        Mode=mode, Key=key,
                    )
                regulator = helper.lcm_poly(
                    regulator, leading_by_key[key]["denominator"], prime
                )
            if mode == 4:
                saturated = total_by_key.get("4:-1:44:0")
                if saturated is None:
                    raise FactorwiseFitRefusal(
                        "CF303FactorwiseFitMode4SaturatedFactorMissing"
                    )
                regulator = helper.lcm_poly(
                    regulator, saturated["denominator"], prime
                )
            if mode == 5:
                regulator = helper.lcm_poly(
                    regulator, mode5_endpoint_regulator, prime
                )
            degree = len(regulator) - 1
            numerator_bound = degree + 4
            required = numerator_bound + 1
            if len(samples) - arguments.held_out_count < required:
                raise FactorwiseFitRefusal(
                    "CF303FactorwiseFitImageCountInsufficient", Mode=mode,
                    RequiredConstructionImages=required,
                    AvailableConstructionImages=(
                        len(samples) - arguments.held_out_count
                    ),
                )
            regulator_values = [
                polynomial.evaluate_polynomial(regulator, point, prime)
                for point in abscissae
            ]
            if any(value == 0 for value in regulator_values):
                raise FactorwiseFitRefusal(
                    "CF303FactorwiseFitImageOnRegulatorZero", Mode=mode
                )
            for order in evaluator.ORDERS:
                for target in evaluator.TARGET_ROWS:
                    key = f"{mode}:{order}:{target}:0"
                    base = baseline_by_key[key]
                    cleared = [
                        (value_by_key[key]
                         + rational_value(base, point, prime))
                        * regulator_value % prime
                        for value_by_key, point, regulator_value in zip(
                            values, abscissae, regulator_values, strict=True
                        )
                    ]
                    numerator = polynomial.newton_interpolate(
                        abscissae[:required], cleared[:required], prime
                    )
                    failures = [
                        index for index in range(required, len(samples))
                        if polynomial.evaluate_polynomial(
                            numerator, abscissae[index], prime
                        ) != cleared[index]
                    ]
                    if failures:
                        raise FactorwiseFitRefusal(
                            "CF303FactorwiseFitHeldOutFailure", Key=key,
                            FirstFailingImageIndex=failures[0],
                        )
                    residual = evaluator.RationalFunction.make(
                        numerator, regulator, prime, helper
                    )
                    baseline_value = evaluator.RationalFunction.make(
                        base["NumeratorCoefficientsModuloPrime"],
                        base["DenominatorCoefficientsModuloPrime"],
                        prime, helper,
                    )
                    normalized = residual.add(baseline_value, helper, -1)
                    if any(
                        normalized.evaluate(point) != value_by_key[key]
                        for point, value_by_key in zip(
                            abscissae, values, strict=True
                        )
                    ):
                        raise FactorwiseFitRefusal(
                            "CF303FactorwiseFitNormalizedReplayFailure", Key=key
                        )
                    outputs.append({
                        "Key": key, "InheritedModeIndex": mode,
                        "EpsilonOrder": order,
                        "TargetMasterIntegralRow": target,
                        "Representation":
                            "EndpointAndCrossRemainderMinusBaselineNormalizationValue",
                        "EndpointAndCrossRemainder": {
                            "NumeratorCoefficientsModuloPrime": list(residual.numerator),
                            "DenominatorCoefficientsModuloPrime": list(residual.denominator),
                        },
                        "BaselineNormalizationValue": {
                            "NumeratorCoefficientsModuloPrime": list(baseline_value.numerator),
                            "DenominatorCoefficientsModuloPrime": list(baseline_value.denominator),
                        },
                        "NormalizedCoefficient": {
                            "NumeratorCoefficientsModuloPrime": list(normalized.numerator),
                            "DenominatorCoefficientsModuloPrime": list(normalized.denominator),
                        },
                        "ConstructionImageCount": required,
                        "IndependentValidationImageCount": len(samples) - required,
                    })
            regulator_records.append({
                "InheritedModeIndex": mode,
                "RegulatorCoefficientsModuloPrime": regulator,
                "RegulatorDegree": degree,
                "ClearedNumeratorDegreeBound": numerator_bound,
                "RequiredConstructionImageCount": required,
            })
        output = {
            "DataType": "CF303NormalPathGaugeMovingBoundaryFiniteCoefficientFactorwiseFit",
            "SchemaVersion": 2,
            "Status": "CF303NormalPathGaugeMovingBoundaryFiniteCoefficientFactorwiseFitPartiallyValidated",
            "Family": "CF303", "Prime": prime,
            "CompletedInheritedModeIndices": list(COMPLETE_MODES),
            "MissingInheritedModes": [
                {"InheritedModeIndex": 1,
                 "Status": "CrossOnlyTransposedHermiteRegulatorMissing"},
            ],
            "CoordinateCount": len(outputs), "Coordinates": outputs,
            "ModeRegulators": regulator_records,
            "Mode5BlockEndpointDenominatorFactorRecords":
                mode5_endpoint_factor_records,
            "Validation": {
                "ExactBaselineNormalizationReducedBeforeSampling": True,
                "ExactDiagonalNormalizationDenominatorsIncluded": True,
                "Mode5BlockEndpointDenominatorFactorsDerivedFromExactConnection":
                    True,
                "ClearedNumeratorBoundsRespected": True,
                "AllSurplusAndHeldOutImagesReplayed": True,
                "NormalizedCoefficientReplayedAtEveryInputImage": True,
            },
            "Seconds": time.perf_counter() - started,
        }
        arguments.output.write_text(json.dumps(output, indent=2) + "\n")
        print(json.dumps({
            "Status": output["Status"], "CoordinateCount": len(outputs),
            "ModeRegulatorDegrees": {
                str(record["InheritedModeIndex"]): record["RegulatorDegree"]
                for record in regulator_records
            },
            "Seconds": output["Seconds"], "Output": str(arguments.output),
        }, sort_keys=True))
        return 0
    except FactorwiseFitRefusal as error:
        print(json.dumps({"Status": error.status, **error.details}, sort_keys=True))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
