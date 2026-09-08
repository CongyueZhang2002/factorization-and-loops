#!/usr/bin/env python3
"""Known-denominator interpolation of the contracted CF303 boundary germ.

The mathematical denominator factors and a numerator-degree bound are inputs,
not inferred by this program.  Clearing the declared denominator converts each
coordinate to polynomial interpolation.  All images beyond the bound-sized
construction set, including an explicitly reserved tail, are exact finite-
field validation points.
"""

from __future__ import annotations

import argparse
import json
import math
import time
from pathlib import Path
from typing import Any

import cf303_h_endpoint_interpolate as endpoint


PROFILE_STATUS = (
    "CF303NormalPathGaugeMovingBoundaryLaurentGermKnownDenominatorsEstablished"
)


class KnownDenominatorRefusal(RuntimeError):
    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def multiply_integer_polynomials(left: list[int], right: list[int]) -> list[int]:
    result = [0] * (len(left) + len(right) - 1)
    for left_degree, left_value in enumerate(left):
        for right_degree, right_value in enumerate(right):
            result[left_degree + right_degree] += left_value * right_value
    return result


def power_integer_polynomial(base: list[int], exponent: int) -> list[int]:
    result = [1]
    factor = base
    while exponent:
        if exponent & 1:
            result = multiply_integer_polynomials(result, factor)
        exponent >>= 1
        if exponent:
            factor = multiply_integer_polynomials(factor, factor)
    return result


def denominator_polynomial(record: dict[str, Any]) -> list[int]:
    result = [1]
    factors = record.get("DenominatorFactors")
    if not isinstance(factors, list) or not factors:
        raise KnownDenominatorRefusal(
            "CF303KnownDenominatorFactorizationMissing", Key=record.get("Key")
        )
    for factor in factors:
        coefficients = factor.get("Coefficients")
        multiplicity = factor.get("Multiplicity")
        if (not isinstance(coefficients, list) or len(coefficients) < 2
                or not all(isinstance(value, int) for value in coefficients)
                or coefficients[-1] <= 0
                or math.gcd(*coefficients) != 1
                or not isinstance(multiplicity, int) or multiplicity < 1):
            raise KnownDenominatorRefusal(
                "CF303KnownDenominatorFactorInvalid", Key=record.get("Key"),
                Factor=factor,
            )
        result = multiply_integer_polynomials(
            result, power_integer_polynomial(coefficients, multiplicity)
        )
    if result[-1] <= 0 or math.gcd(*result) != 1:
        raise KnownDenominatorRefusal(
            "CF303KnownDenominatorNormalizationInvalid", Key=record.get("Key")
        )
    return result


def evaluate_polynomial(coefficients: list[int], value: int,
                        prime: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * value + coefficient) % prime
    return result


def newton_interpolate(abscissae: list[int], values: list[int],
                       prime: int) -> list[int]:
    """Return ascending monomial coefficients over F_q."""
    newton_coefficients: list[int] = []
    for index, (abscissa, value) in enumerate(zip(abscissae, values, strict=True)):
        prediction = 0
        product = 1
        for earlier, coefficient in enumerate(newton_coefficients):
            prediction = (prediction + coefficient * product) % prime
            product = product * (abscissa - abscissae[earlier]) % prime
        if product == 0:
            raise KnownDenominatorRefusal(
                "CF303KnownDenominatorDuplicateInterpolationPoint",
                PointIndex=index,
            )
        newton_coefficients.append(
            (value - prediction) * pow(product, -1, prime) % prime
        )
    monomial = [0]
    basis = [1]
    for index, coefficient in enumerate(newton_coefficients):
        if len(monomial) < len(basis):
            monomial.extend([0] * (len(basis) - len(monomial)))
        for degree, value in enumerate(basis):
            monomial[degree] = (monomial[degree] + coefficient * value) % prime
        if index + 1 < len(newton_coefficients):
            root = abscissae[index]
            next_basis = [0] * (len(basis) + 1)
            for degree, value in enumerate(basis):
                next_basis[degree] = (next_basis[degree] - root * value) % prime
                next_basis[degree + 1] = (next_basis[degree + 1] + value) % prime
            basis = next_basis
    while len(monomial) > 1 and monomial[-1] == 0:
        monomial.pop()
    return monomial


def sample_index(sample: dict[str, Any]) -> dict[str, int]:
    return {
        f"{record['InheritedModeIndex']}:{record['EpsilonOrder']}:"
        f"{record['TargetMasterIntegralRow']}:"
        f"{record['NormalCoordinatePower']}": int(record["Value"])
        for record in sample["Records"]
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample-directory", type=Path, required=True)
    parser.add_argument("--denominator-profile", type=Path, required=True)
    parser.add_argument("--held-out-count", type=int, default=3)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    try:
        profile = json.loads(arguments.denominator_profile.read_text())
        if (profile.get("DataType") !=
                "CF303NormalPathGaugeMovingBoundaryLaurentGermKnownDenominatorProfile"
                or profile.get("SchemaVersion") != 2
                or profile.get("Status") != PROFILE_STATUS):
            raise KnownDenominatorRefusal(
                "CF303KnownDenominatorProfileNotEstablished"
            )
        coordinate_profiles = profile.get("Coordinates")
        if not isinstance(coordinate_profiles, list) or not coordinate_profiles:
            raise KnownDenominatorRefusal(
                "CF303KnownDenominatorCoordinateProfilesMissing"
            )
        keys = [record.get("Key") for record in coordinate_profiles]
        if (any(key not in endpoint.coordinate_keys() for key in keys)
                or len(keys) != len(set(keys))):
            raise KnownDenominatorRefusal(
                "CF303KnownDenominatorCoordinateKeyLayoutInvalid"
            )
        paths = sorted(
            arguments.sample_directory.glob("p*.json"),
            key=endpoint.numeric_point,
        )
        if (arguments.held_out_count < 1
                or len(paths) <= arguments.held_out_count):
            raise KnownDenominatorRefusal(
                "CF303KnownDenominatorValidationImagesMissing"
            )
        first = endpoint.read_sample(paths[0])
        prime = int(first["Prime"])
        samples = [first] + [endpoint.read_sample(path, prime)
                             for path in paths[1:]]
        construction = samples[:-arguments.held_out_count]
        held_out = samples[-arguments.held_out_count:]
        abscissae = [
            int(sample["TangentialPoint"][0])
            * pow(int(sample["TangentialPoint"][1]), -1, prime) % prime
            for sample in samples
        ]
        values = [sample_index(sample) for sample in samples]
        started = time.perf_counter()
        outputs = []
        for record in coordinate_profiles:
            key = record["Key"]
            bound = record.get("NumeratorDegreeBound")
            if not isinstance(bound, int) or bound < 0:
                raise KnownDenominatorRefusal(
                    "CF303KnownDenominatorNumeratorDegreeBoundMissing", Key=key
                )
            required = bound + 1
            if len(construction) < required:
                raise KnownDenominatorRefusal(
                    "CF303KnownDenominatorImageCountInsufficient", Key=key,
                    RequiredConstructionImages=required,
                    AvailableConstructionImages=len(construction),
                )
            denominator = denominator_polynomial(record)
            cleared = []
            for point, value_by_key in zip(abscissae, values, strict=True):
                denominator_value = evaluate_polynomial(
                    denominator, point, prime
                )
                if denominator_value == 0:
                    raise KnownDenominatorRefusal(
                        "CF303KnownDenominatorImageOnDeclaredPole",
                        Key=key, Point=point,
                    )
                cleared.append(value_by_key.get(key, 0) * denominator_value % prime)
            numerator = newton_interpolate(
                abscissae[:required], cleared[:required], prime
            )
            failures = [
                index for index in range(required, len(samples))
                if evaluate_polynomial(numerator, abscissae[index], prime)
                != cleared[index]
            ]
            if failures:
                raise KnownDenominatorRefusal(
                    "CF303KnownDenominatorProfileRejectedAtFiniteFieldImages",
                    Key=key, FirstFailingImageIndex=failures[0],
                    ValidationImageCount=len(samples) - required,
                )
            outputs.append({
                "Key": key,
                "NumeratorDegree": len(numerator) - 1,
                "NumeratorDegreeBound": bound,
                "NumeratorCoefficientsModuloPrime": numerator,
                "DenominatorFactors": record["DenominatorFactors"],
                "ConstructionImageCount": required,
                "IndependentValidationImageCount": len(samples) - required,
            })
        output = {
            "DataType":
                "CF303NormalPathGaugeMovingBoundaryLaurentGermKnownDenominatorFiniteFieldFit",
            "SchemaVersion": 2,
            "Status":
                "CF303NormalPathGaugeMovingBoundaryLaurentGermKnownDenominatorFiniteFieldFitValidated",
            "Family": "CF303", "Prime": prime,
            "CoordinateCount": len(outputs), "Coordinates": outputs,
            "HeldOutPoints": [sample["TangentialPoint"] for sample in held_out],
            "Validation": {
                "DeclaredDenominatorsClearedBeforeInterpolation": True,
                "NumeratorDegreeBoundsRespected": True,
                "AllUnusedConstructionAndHeldOutImagesValidated": True,
            },
            "Seconds": time.perf_counter() - started,
        }
        arguments.output.write_text(json.dumps(output, indent=2) + "\n")
        print(json.dumps({
            "Status": output["Status"], "Prime": prime,
            "CoordinateCount": len(outputs), "Seconds": output["Seconds"],
            "Output": str(arguments.output),
        }, sort_keys=True))
        return 0
    except KnownDenominatorRefusal as error:
        print(json.dumps({"Status": error.status, **error.details}, sort_keys=True))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
