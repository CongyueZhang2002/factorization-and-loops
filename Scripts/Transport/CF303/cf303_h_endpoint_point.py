#!/usr/bin/env python3
"""Evaluate the demanded CF303 path-gauge germ at rho=2p-u=0.

Only the two target rows and seven source columns reachable from the accepted
soft modes are retained.  The full rational functions in u are reduced by the
existing normal-factor circuit and immediately localized at the endpoint.
"""

from __future__ import annotations

import argparse
import importlib.util
import itertools
import json
import sys
import tempfile
import time
from fractions import Fraction
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parents[2]
BUNDLE = HERE / "data/normal_factor_exact_circuit"
JUNCTION_POINT = HERE / "cf303_tangential_junction_point.py"
DEFAULT_PRIME = 2_305_843_009_213_641_971
DEFAULT_DECK = BUNDLE / (
    "block1_modular_laurent_decks/"
    f"cf303_block1_laurent_deck_q{DEFAULT_PRIME}.json.gz"
)


class CF303HEndpointPointRefusal(RuntimeError):
    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise CF303HEndpointPointRefusal(
            "CF303HEndpointPointProviderUnavailable",
            RelativePath=str(path.relative_to(REPOSITORY)),
        )
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def build_point(prime: int, p: Fraction, deck: Path,
                orbit: str = "single",
                emit_mode1_components: bool = False) -> dict[str, Any]:
    started = time.perf_counter()
    if not deck.is_file():
        raise CF303HEndpointPointRefusal(
            "CF303HEndpointBlock1DeckMissing", DeckName=deck.name
        )
    junction = load_module(
        f"cf303_h_endpoint_junction_{prime}_{p.numerator}_{p.denominator}",
        JUNCTION_POINT,
    )
    inherited = load_module(
        f"cf303_h_endpoint_modes_{prime}_{p.numerator}_{p.denominator}",
        junction.INHERITED_PROVIDER,
    )
    endpoint_local = load_module(
        f"cf303_h_endpoint_local_{prime}_{p.numerator}_{p.denominator}",
        junction.ENDPOINT_PROVIDER,
    )
    modes = [
        {**mode, "mode_index": index}
        for index, mode in enumerate(inherited.MODE_SPECS, 1)
    ]
    signs = ([(1, 1, 1, 1)] if orbit == "single" else
             list(itertools.product((-1, 1), repeat=4)))
    with tempfile.TemporaryDirectory(prefix="cf303-h-endpoint-") as directory:
        resolved = Path(directory) / "block1.json"
        resolution_seconds = junction.resolve_block1(
            prime, p, deck, resolved
        )
        context = junction.prepare_adapter_context(prime, p, resolved)
        block1 = context["resolution"]
        if (block1.get("status") !=
                "CF303Block1FiniteFieldCircuitPointReplayValidated"
                or block1.get("output_count") != 16
                or not block1.get("base_sheet_available")):
            raise CF303HEndpointPointRefusal(
                "CF303HEndpointBlock1ReplayNotAccepted"
            )
        branches = []
        component_branches = []
        branch_seconds = []
        recurrence_checks = 0
        basepoint_checks = 0
        for branch_signs in signs:
            adapter, seconds = junction.evaluate_adapter_branch(
                context, branch_signs, h_endpoint_modes=modes,
                h_endpoint_localizer=endpoint_local.function_pair_local_data,
            )
            branch_seconds.append(seconds)
            expected_identity_count = (
                len(context["epsilon_orders"])
                * len(context["evaluator"].TARGET_ROWS)
                * len(context["support_masters"])
            )
            if (adapter["hermite_recurrence_comparison_count"]
                    != expected_identity_count):
                raise CF303HEndpointPointRefusal(
                    "CF303HEndpointHermiteRecurrenceCoverageIncomplete",
                    Expected=expected_identity_count,
                    Observed=adapter[
                        "hermite_recurrence_comparison_count"
                    ],
                )
            if (adapter["normalization_basepoint_comparison_count"]
                    != expected_identity_count):
                raise CF303HEndpointPointRefusal(
                    "CF303HEndpointNormalizationCoverageIncomplete",
                    Expected=expected_identity_count,
                    Observed=adapter[
                        "normalization_basepoint_comparison_count"
                    ],
                )
            recurrence_checks += adapter[
                "hermite_recurrence_comparison_count"
            ]
            basepoint_checks += adapter[
                "normalization_basepoint_comparison_count"
            ]
            records = adapter["h_endpoint_mode_outputs"]
            expected_count = (
                len(context["epsilon_orders"])
                * len(context["evaluator"].TARGET_ROWS)
                * len(modes)
            )
            if len(records) != expected_count:
                raise CF303HEndpointPointRefusal(
                    "CF303HEndpointDemandedLayoutIncomplete",
                    Expected=expected_count, Observed=len(records),
                )
            normalized = {}
            for record in records:
                base_key = (record["order"], record["target_master"],
                            record["mode_index"])
                local_data = record["local_data"]
                if local_data is None:
                    continue
                terms = list(local_data["principal"])
                terms.append({"rho_power": 0, **local_data["finite"]})
                for term in terms:
                    key = (*base_key, term["rho_power"])
                    if term["rational"][1] != 0 or term[
                            "elliptic_y_coefficient"] != [0, 0]:
                        raise CF303HEndpointPointRefusal(
                            "CF303HEndpointGermNotInRationalCoefficientField",
                            Key=list(key), RadicalSigns=list(branch_signs),
                            Rational=term["rational"],
                            EllipticYCoefficient=term[
                                "elliptic_y_coefficient"],
                        )
                    if term["rational"][0] != 0:
                        normalized[key] = term["rational"][0]
            branches.append((branch_signs, normalized))
            components = {}
            if emit_mode1_components:
                for record in adapter["h_endpoint_mode_component_outputs"]:
                    if record["mode_index"] != 1:
                        continue
                    local_data = record["local_data"]
                    if local_data is None:
                        continue
                    terms = list(local_data["principal"])
                    terms.append({"rho_power": 0, **local_data["finite"]})
                    for term in terms:
                        key = (record["component"], record["order"],
                               record["target_master"], 1,
                               term["rho_power"])
                        if (term["rational"][1] != 0 or
                                term["elliptic_y_coefficient"] != [0, 0]):
                            raise CF303HEndpointPointRefusal(
                                "CF303HEndpointComponentNotInRationalCoefficientField",
                                Key=list(key), RadicalSigns=list(branch_signs),
                            )
                        if term["rational"][0] != 0:
                            components[key] = term["rational"][0]
            component_branches.append((branch_signs, components))
    reference = branches[0][1]
    if any(values != reference for _signs, values in branches[1:]):
        first_failure = next(
            {"RadicalSigns": list(branch_signs), "Key": list(key),
             "Reference": reference.get(key), "Observed": values.get(key)}
            for branch_signs, values in branches[1:]
            for key in sorted(set(reference) | set(values))
            if values.get(key) != reference.get(key)
        )
        raise CF303HEndpointPointRefusal(
            "CF303HEndpointGaloisBranchDependenceDetected", **first_failure
        )
    component_reference = component_branches[0][1]
    if any(values != component_reference
           for _signs, values in component_branches[1:]):
        raise CF303HEndpointPointRefusal(
            "CF303HEndpointComponentGaloisBranchDependenceDetected"
        )
    component_sum_checks = 0
    if emit_mode1_components:
        for order in context["epsilon_orders"]:
            for target in context["evaluator"].TARGET_ROWS:
                for power in (-2, -1, 0):
                    total = reference.get((order, target, 1, power), 0)
                    parts = sum(component_reference.get(
                        (component, order, target, 1, power), 0
                    ) for component in ("CrossHermite", "Block1Homogeneous"))
                    if parts % prime != total:
                        raise CF303HEndpointPointRefusal(
                            "CF303HEndpointMode1ComponentSumFailure",
                            Order=order, Target=target,
                            NormalCoordinatePower=power,
                        )
                    component_sum_checks += 1
    output_records = [
        {"EpsilonOrder": key[0], "TargetMasterIntegralRow": key[1],
         "InheritedModeIndex": key[2],
         "InheritedModeID": modes[key[2] - 1]["mode_id"],
         "NormalCoordinatePower": key[3], "Value": value}
        for key, value in sorted(reference.items())
    ]
    component_records = [
        {"Component": key[0], "EpsilonOrder": key[1],
         "TargetMasterIntegralRow": key[2],
         "InheritedModeIndex": key[3],
         "NormalCoordinatePower": key[4], "Value": value}
        for key, value in sorted(component_reference.items())
    ]
    return {
        "DataType": "CF303NormalPathGaugeAtMovingBoundaryFiniteFieldPoint",
        "SchemaVersion": 2,
        "Status": "CF303NormalPathGaugeAtMovingBoundaryFiniteFieldPointValidated",
        "Family": "CF303", "Prime": prime,
        "TangentialPoint": [p.numerator, p.denominator],
        "NormalPathVariable": "u", "MovingBoundaryValue": "u=2*p",
        "PathGaugeRelation": "F25=G25+H*Fsource",
        "NormalizationBasePoint": [1, 2],
        "EpsilonOrderWindow": [context["epsilon_orders"][0],
                               context["epsilon_orders"][-1]],
        "TargetMasterIntegralRows": list(context["evaluator"].TARGET_ROWS),
        "InheritedModeOrder": [mode["mode_id"] for mode in modes],
        "SourceMasterIntegralSupportRows": list(context["support_masters"]),
        "RecordCount": len(output_records),
        "Records": output_records,
        "Mode1ComponentRecordCount": len(component_records),
        "Mode1ComponentRecords": component_records,
        "CoefficientField": "F_q",
        "MathematicalQuantity":
            "Laurent germ at rho=2*p-u=0 of H(u,p,eps) contracted with each inherited SourceModeMap column",
        "GaloisOrbitValidation": {
            "Orbit": "Full16" if orbit == "full" else "SingleBranch",
            "BranchCount": len(branches),
            "AllFourRadicalGeneratorsIndependent": orbit == "full",
            "AllBranchValuesEqual": len(branches) == 16,
        },
        "DefiningEquationValidation": {
            "Equation":
                "d_u H_r + K_r = d_u H_r^incoming + A_G H_(r-1) - H_(r-1) A_S",
            "HermiteRecurrenceIdentityChecks": recurrence_checks,
            "PathGaugeBasePointNormalizationChecks": basepoint_checks,
            "ExpectedChecksPerRadicalSheet":
                len(context["epsilon_orders"])
                * len(context["evaluator"].TARGET_ROWS)
                * len(context["support_masters"]),
            "Block1CircuitPointReplayStatus": block1["status"],
            "Block1RationalSourceReplayComparisons":
                block1["rational_source_replay_comparisons"],
            "Block1EllipticQuotientCohomologyChecks":
                block1["elliptic_quotient_cohomology_checks"],
            "Block1ExactProfileComparisons":
                block1["elliptic_exact_profile_comparisons"],
            "SelectedSupportAndBlock1IdentitiesAcceptedBeforeLocalization":
                True,
            "Mode1CrossPlusBlock1ComponentSumChecks": component_sum_checks,
        },
        "InputReferences": {
            "NormalFactorCircuitBundle":
                "Scripts/Transport/CF303/data/normal_factor_exact_circuit",
            "Block1LaurentDeckName": deck.name,
        },
        "TimingsSeconds": {
            "Block1PointResolution": resolution_seconds,
            "ContextPreparation": context["prepare_seconds"],
            "BranchTotal": sum(branch_seconds),
            "Total": time.perf_counter() - started,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=DEFAULT_PRIME)
    parser.add_argument("--p", type=Fraction, required=True)
    parser.add_argument("--block1-deck", type=Path, default=DEFAULT_DECK)
    parser.add_argument("--orbit", choices=("single", "full"), default="single")
    parser.add_argument("--emit-mode1-components", action="store_true")
    parser.add_argument("--output", type=Path)
    arguments = parser.parse_args()
    try:
        result = build_point(
            arguments.prime, arguments.p, arguments.block1_deck,
            arguments.orbit, arguments.emit_mode1_components,
        )
    except Exception as error:
        if isinstance(error, CF303HEndpointPointRefusal):
            failure = {"Status": error.status, **error.details}
        else:
            failure = {"Status": type(error).__name__, "Message": str(error)}
        print(json.dumps(failure, sort_keys=True))
        return 2
    encoded = json.dumps(result, indent=2) + "\n"
    if arguments.output:
        arguments.output.write_text(encoded)
        print(json.dumps({
            "Status": result["Status"], "RecordCount": result["RecordCount"],
            "Output": str(arguments.output),
            "TimingsSeconds": result["TimingsSeconds"],
        }, indent=2))
    else:
        print(encoded, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
