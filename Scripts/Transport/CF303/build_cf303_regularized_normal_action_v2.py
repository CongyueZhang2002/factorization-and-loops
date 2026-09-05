#!/usr/bin/env python3
"""Assemble the demand-complete CF303 regularized normal H action modulo q."""

from __future__ import annotations

import argparse
import gzip
import json
from pathlib import Path
import time
from typing import Any

import cf303_h_endpoint_interpolate as endpoint


HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parents[2]
DEFAULT_OUTPUT_DIRECTORY = (
    REPOSITORY / "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/"
    "DifferentialEquationDataV2/CF303"
)
PRIME = 2_305_843_009_213_641_971


class NormalActionRefusal(RuntimeError):
    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def read_json(path: Path) -> dict[str, Any]:
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt") as stream:
        return json.load(stream)


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix == ".gz":
        with gzip.open(path, "wt") as stream:
            json.dump(value, stream, separators=(",", ":"))
            stream.write("\n")
    else:
        path.write_text(json.dumps(value, indent=2) + "\n")


def polynomial_value(coefficients: list[int], point: int, prime: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result*point + int(coefficient)) % prime
    return result


def rational_value(record: dict[str, Any], point: int, prime: int) -> int:
    numerator = polynomial_value(
        record["NumeratorCoefficientsModuloPrime"], point, prime
    )
    denominator = polynomial_value(
        record["DenominatorCoefficientsModuloPrime"], point, prime
    )
    if denominator == 0:
        raise NormalActionRefusal(
            "CF303RegularizedNormalActionValidationPointOnPole"
        )
    return numerator*pow(denominator, -1, prime) % prime


def key(mode: int, order: int, target: int, power: int) -> str:
    return f"{mode}:{order}:{target}:{power}"


def sample_table(sample: dict[str, Any]) -> dict[str, int]:
    return {
        key(int(record["InheritedModeIndex"]), int(record["EpsilonOrder"]),
            int(record["TargetMasterIntegralRow"]),
            int(record["NormalCoordinatePower"])): int(record["Value"])
        for record in sample["Records"]
    }


def build(arguments) -> dict[str, Any]:
    started = time.perf_counter()
    leading = read_json(arguments.leading_profile)
    finite = read_json(arguments.finite_profile)
    block1 = read_json(arguments.block1_components)
    if int(leading.get("prime", -1)) != PRIME:
        raise NormalActionRefusal("CF303RegularizedNormalActionLeadingPrimeMismatch")
    if (finite.get("Status") !=
            "CF303NormalPathGaugeMovingBoundaryFiniteCoefficientFactorwiseFitPartiallyValidated"
            or int(finite.get("Prime", -1)) != PRIME
            or finite.get("CompletedInheritedModeIndices") != [2, 3, 4, 5, 6, 7]):
        raise NormalActionRefusal("CF303RegularizedNormalActionFiniteFitInvalid")
    if (block1.get("Status") !=
            "CF303Block1HomogeneousMovingBoundaryGermFiniteFieldImagesValidated"
            or int(block1.get("Prime", -1)) != PRIME):
        raise NormalActionRefusal("CF303RegularizedNormalActionBlock1EvidenceInvalid")

    leading_by_key = {record["key"]: record
                      for record in leading.get("coordinates", [])}
    finite_by_key = {record["Key"]: record
                     for record in finite.get("Coordinates", [])}
    expected_leading = {
        key(mode, order, target, power)
        for mode in range(1, 8) for order in range(-3, 5)
        for target in (44, 45) for power in (-2, -1)
    }
    expected_finite = {
        key(mode, order, target, 0)
        for mode in range(2, 8) for order in range(-3, 5)
        for target in (44, 45)
    }
    if (not expected_leading <= set(leading_by_key)
            or any(leading_by_key[name].get("status") != 0
                   for name in expected_leading)):
        raise NormalActionRefusal(
            "CF303RegularizedNormalActionLeadingProfileIncomplete"
        )
    if set(finite_by_key) != expected_finite:
        raise NormalActionRefusal(
            "CF303RegularizedNormalActionFiniteProfileIncomplete"
        )

    coefficients = []
    explicit_by_key = {}
    for name in sorted(expected_leading):
        source = leading_by_key[name]
        mode, order, target, power = map(int, name.split(":"))
        record = {
            "Key": name, "InheritedModeIndex": mode,
            "EpsilonOrder": order, "TargetMasterIntegralRow": target,
            "NormalCoordinatePower": power,
            "CoefficientRepresentation": "RationalFunctionModuloPrime",
            "NumeratorCoefficientsModuloPrime": source["numerator"],
            "DenominatorCoefficientsModuloPrime": source["denominator"],
            "NumeratorDegree": source["degrees"][0],
            "DenominatorDegree": source["degrees"][1],
        }
        coefficients.append(record)
        explicit_by_key[name] = record
    for name in sorted(expected_finite):
        source = finite_by_key[name]
        mode, order, target, power = map(int, name.split(":"))
        value = source["NormalizedCoefficient"]
        record = {
            "Key": name, "InheritedModeIndex": mode,
            "EpsilonOrder": order, "TargetMasterIntegralRow": target,
            "NormalCoordinatePower": power,
            "CoefficientRepresentation": "RationalFunctionModuloPrime",
            **value,
            "NumeratorDegree":
                len(value["NumeratorCoefficientsModuloPrime"]) - 1,
            "DenominatorDegree":
                len(value["DenominatorCoefficientsModuloPrime"]) - 1,
        }
        coefficients.append(record)
        explicit_by_key[name] = record

    mode_regulators = {
        str(record["InheritedModeIndex"]): {
            "RegulatorDegree": record["RegulatorDegree"],
            "RegulatorCoefficientsModuloPrime":
                record["RegulatorCoefficientsModuloPrime"],
            "ClearedNumeratorDegreeBound":
                record["ClearedNumeratorDegreeBound"],
        } for record in finite["ModeRegulators"]
    }
    for order in range(-3, 5):
        for target in (44, 45):
            name = key(1, order, target, 0)
            coefficients.append({
                "Key": name, "InheritedModeIndex": 1,
                "EpsilonOrder": order,
                "TargetMasterIntegralRow": target,
                "NormalCoordinatePower": 0,
                "CoefficientRepresentation":
                    "OrderedExactRegularizedEndpointFunctionalSumModuloPrime",
                "OrderedComponents": [
                    {
                        "Component": "CrossHermite",
                        "Sign": 1,
                        "EvaluatorReference": {
                            "RelativePath":
                                "Scripts/Transport/CF303/cf303_h_endpoint_point.py",
                            "OutputField": "Mode1ComponentRecords",
                            "ComponentSelector": "CrossHermite",
                        },
                        "DefiningRecurrence":
                            "Hcross_r=RegHermitePrimitive[A_G H_(r-1)-H_(r-1) A_S], normalized at u=1/2",
                        "FactorSources": {
                            "CompletedInheritedModeRegulators": mode_regulators,
                            "SelectedConnectionMovingBoundaryFactors":
                                finite["Mode5BlockEndpointDenominatorFactorRecords"],
                        },
                    },
                    {
                        "Component": "Block1Homogeneous",
                        "Sign": 1,
                        "ExactCircuitReference": {
                            "RelativePath":
                                "Scripts/Transport/CF303/data/normal_factor_exact_circuit/cf303_block1_full_exact_circuit.json",
                            "DataType": "CF303Block1ExactArithmeticCircuit",
                        },
                        "EndpointFunctionalReference": {
                            "RelativePath":
                                "Scripts/Transport/CF303/cf303_h_endpoint_adjoint_pilot.py",
                            "Operation":
                                "Adjoint normalized rho^0 Hermite primitive functional",
                        },
                    },
                ],
            })

    sample_paths = sorted(arguments.sample_directory.glob("p*.json"),
                          key=endpoint.numeric_point)
    samples = [endpoint.read_sample(path, PRIME) for path in sample_paths]
    explicit_comparisons = 0
    for sample in samples:
        point = (int(sample["TangentialPoint"][0])
                 * pow(int(sample["TangentialPoint"][1]), -1, PRIME) % PRIME)
        observed = sample_table(sample)
        for name, record in explicit_by_key.items():
            if rational_value(record, point, PRIME) != observed.get(name, 0):
                raise NormalActionRefusal(
                    "CF303RegularizedNormalActionExplicitReplayFailure",
                    Key=name, TangentialPoint=sample["TangentialPoint"],
                )
            explicit_comparisons += 1

    block1_by_point = {
        tuple(image["TangentialPoint"]): {
            (int(record["EpsilonOrder"]),
             int(record["TargetMasterIntegralRow"]),
             int(record["NormalCoordinatePower"])): int(record["Value"])
            for record in image["Records"]
        } for image in block1["Points"]
    }
    component_comparisons = 0
    adjoint_comparisons = 0
    adjoint_timings: dict[int, list[float]] = {}
    direct_evidence = []
    for path in arguments.direct_component_evidence:
        evidence = read_json(path)
        if (evidence.get("Status") !=
                "CF303NormalPathGaugeAtMovingBoundaryFiniteFieldPointValidated"
                or evidence.get("DefiningEquationValidation", {}).get(
                    "Mode1CrossPlusBlock1ComponentSumChecks") != 48):
            raise NormalActionRefusal(
                "CF303RegularizedNormalActionDirectComponentEvidenceInvalid",
                Evidence=path.name,
            )
        point_pair = tuple(evidence["TangentialPoint"])
        stored_block1 = block1_by_point[point_pair]
        components = {
            (record["Component"], int(record["EpsilonOrder"]),
             int(record["TargetMasterIntegralRow"]),
             int(record["NormalCoordinatePower"])): int(record["Value"])
            for record in evidence["Mode1ComponentRecords"]
        }
        total = sample_table(evidence)
        for order in range(-3, 5):
            for target in (44, 45):
                for power in (-2, -1, 0):
                    block_value = components.get(
                        ("Block1Homogeneous", order, target, power), 0
                    )
                    cross_value = components.get(
                        ("CrossHermite", order, target, power), 0
                    )
                    if block_value != stored_block1[(order, target, power)]:
                        raise NormalActionRefusal(
                            "CF303RegularizedNormalActionBlock1ReplayFailure"
                        )
                    if ((block_value + cross_value) % PRIME !=
                            total.get(key(1, order, target, power), 0)):
                        raise NormalActionRefusal(
                            "CF303RegularizedNormalActionComponentSumFailure"
                        )
                    component_comparisons += 2
        direct_evidence.append({
            "TangentialPoint": list(point_pair),
            "HermiteRecurrenceIdentityChecks": evidence[
                "DefiningEquationValidation"
            ]["HermiteRecurrenceIdentityChecks"],
            "PathGaugeBasePointNormalizationChecks": evidence[
                "DefiningEquationValidation"
            ]["PathGaugeBasePointNormalizationChecks"],
        })
    for path in arguments.adjoint_evidence:
        evidence = read_json(path)
        if (evidence.get("Status") !=
                "CF303RegularizedEndpointHermiteAdjointPilotValidated"):
            raise NormalActionRefusal(
                "CF303RegularizedNormalActionAdjointEvidenceInvalid",
                Evidence=path.name,
            )
        adjoint_comparisons += len(evidence["Records"])
        adjoint_timings.setdefault(int(evidence["EpsilonOrder"]), []).extend(
            float(record["AdjointSeconds"])
            for record in evidence["Records"]
        )

    if len(coefficients) != 336 or len(explicit_by_key) != 320:
        raise NormalActionRefusal(
            "CF303RegularizedNormalActionDemandCoverageIncomplete",
            Coefficients=len(coefficients), Explicit=len(explicit_by_key),
        )
    return {
        "DataType": "CF303RegularizedNormalActionFiniteField",
        "SchemaVersion": 2,
        "Status": "CF303RegularizedNormalActionFiniteFieldValidated",
        "Family": "CF303", "Prime": PRIME,
        "Scope": {
            "TargetMasterIntegralRows": [44, 45],
            "InheritedModeIndices": list(range(1, 8)),
            "EpsilonOrderWindow": [-3, 4],
            "NormalCoordinatePowers": [-2, -1, 0],
            "NormalCoordinate": "rho=2*p-u",
            "PathGaugeNormalizationPoint": [1, 2],
        },
        "CoefficientCount": 336,
        "ExplicitRationalFunctionCoefficientCount": 320,
        "ExactLazyEndpointFunctionalCoefficientCount": 16,
        "Coefficients": sorted(coefficients, key=lambda record: (
            record["InheritedModeIndex"], record["EpsilonOrder"],
            record["TargetMasterIntegralRow"],
            record["NormalCoordinatePower"],
        )),
        "DemandCoverage": "Complete",
        "Validation": {
            "Conditions": {
                "EveryExplicitCoefficientReplayedAtEveryInputPoint": True,
                "Mode1CrossAndBlock1EmittedIndependently": True,
                "Mode1ComponentSumsEqualFullNormalRecurrence": True,
                "Block1AdjointEndpointFunctionalEqualsFullPrimitiveOracle": True,
                "HermiteDefiningRecurrenceAcceptedAtDirectEvidencePoints": True,
                "PathGaugeNormalizationAcceptedAtDirectEvidencePoints": True,
            },
            "ExplicitCoefficientImageComparisons": explicit_comparisons,
            "Mode1DirectComponentComparisons": component_comparisons,
            "Block1AdjointOracleComparisons": adjoint_comparisons,
            "Block1AdjointTimingByEpsilonOrder": [
                {
                    "EpsilonOrder": order,
                    "RowPointComparisonCount": len(seconds),
                    "TotalAdjointSeconds": sum(seconds),
                    "MaximumAdjointSeconds": max(seconds),
                }
                for order, seconds in sorted(adjoint_timings.items())
            ],
            "DirectEvidence": direct_evidence,
        },
        "InputReferences": {
            "NormalFactorExactCircuitBundle":
                "Scripts/Transport/CF303/data/normal_factor_exact_circuit",
            "RegularizedPointEvaluator":
                "Scripts/Transport/CF303/cf303_h_endpoint_point.py",
            "Block1EndpointAdjointFunctional":
                "Scripts/Transport/CF303/cf303_h_endpoint_adjoint_pilot.py",
        },
        "Seconds": time.perf_counter() - started,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample-directory", type=Path, required=True)
    parser.add_argument("--leading-profile", type=Path, required=True)
    parser.add_argument("--finite-profile", type=Path, required=True)
    parser.add_argument("--block1-components", type=Path, required=True)
    parser.add_argument("--direct-component-evidence", type=Path,
                        nargs="*", default=[])
    parser.add_argument("--adjoint-evidence", type=Path,
                        nargs="*", default=[])
    parser.add_argument("--output", type=Path,
                        default=DEFAULT_OUTPUT_DIRECTORY /
                        f"CF303RegularizedNormalActionFiniteFieldQ{PRIME}.json.gz")
    arguments = parser.parse_args()
    try:
        result = build(arguments)
    except NormalActionRefusal as error:
        print(json.dumps({"Status": error.status, **error.details}, sort_keys=True))
        return 2
    write_json(arguments.output, result)
    print(json.dumps({
        "Status": result["Status"],
        "CoefficientCount": result["CoefficientCount"],
        "ExplicitCoefficientImageComparisons": result["Validation"][
            "ExplicitCoefficientImageComparisons"
        ],
        "Mode1DirectComponentComparisons": result["Validation"][
            "Mode1DirectComponentComparisons"
        ],
        "Seconds": result["Seconds"], "Output": str(arguments.output),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
