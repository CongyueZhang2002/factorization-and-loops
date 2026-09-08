#!/usr/bin/env python3
"""Reduce the selected baseline-H normalization values in F_q(p).

The exact transfer stores H as rational expressions in (p,u,epsilon).  At the
declared normalization point u=1/2, the existing sparse bivariate parser can
be reused without a new algebra implementation: original p is mapped to its
polynomial slot and original u to the fixed scalar slot.  Laurent extraction
then returns reduced rational functions of p before any p sampling.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import sys
import time
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
BUNDLE = HERE / "data/normal_factor_exact_circuit"
EVALUATOR = BUNDLE / "cf303_hybrid_baseline_modular_circuit.py"
MODES = HERE / "cf303_inherited_soft_projection_point.py"
DEFAULT_PRIME = 2_305_843_009_213_641_971


class BaselineAtBaseRefusal(RuntimeError):
    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise BaselineAtBaseRefusal(
            "CF303BaselineAtBaseProviderUnavailable", Provider=path.name
        )
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def exchange_p_and_u(raw: str) -> str:
    exchanged = re.sub(r"\bp\b", "CF303TangentialVariable", raw)
    exchanged = re.sub(r"\bu\b", "p", exchanged)
    return exchanged.replace("CF303TangentialVariable", "u")


def build_profile(prime: int) -> dict[str, Any]:
    started = time.perf_counter()
    evaluator = load_module(f"cf303_baseline_evaluator_{prime}", EVALUATOR)
    helper = evaluator.load_module(
        f"cf303_baseline_polynomial_{prime}", evaluator.RATIONAL_HELPER
    )
    modes = load_module(f"cf303_baseline_modes_{prime}", MODES)
    inputs = evaluator.parse_inputs()
    raw_by_target_source = {
        (int(entry[0][0]), int(entry[0][1])): entry[2]
        for entry in inputs["source_entries"]
    }
    half = pow(2, -1, prime)
    parsed: dict[tuple[int, int], dict[int, Any]] = {}
    expression_count = 0
    for target in evaluator.TARGET_ROWS:
        for source in evaluator.ADAPTER_SUPPORT_MASTERS:
            channels = raw_by_target_source.get((target, source), ["0", "0"])
            if channels[1] != "0":
                raise BaselineAtBaseRefusal(
                    "CF303BaselineAtBaseEllipticChannelUnexpected",
                    Target=target, Source=source,
                )
            if channels[0] == "0":
                coefficients = {
                    order: evaluator.RationalFunction.zero(prime)
                    for order in evaluator.ORDERS
                }
            else:
                expression_count += 1
                expression = evaluator.ModularExpressionParser(
                    exchange_p_and_u(channels[0]), prime, half
                ).parse()
                coefficients = evaluator.laurent_coefficients(
                    expression, helper,
                    low=evaluator.ORDERS[0], high=evaluator.ORDERS[-1],
                )
            parsed[(target, source)] = coefficients
    records = []
    for mode_index, mode in enumerate(modes.MODE_SPECS, 1):
        for order in evaluator.ORDERS:
            for target in evaluator.TARGET_ROWS:
                value = evaluator.RationalFunction.zero(prime)
                for source, weight in mode["state_weights"].items():
                    value = value.add(
                        parsed[(target, source)][order], helper, int(weight)
                    )
                records.append({
                    "Key": f"{mode_index}:{order}:{target}:0",
                    "InheritedModeIndex": mode_index,
                    "InheritedModeID": mode["mode_id"],
                    "EpsilonOrder": order,
                    "TargetMasterIntegralRow": target,
                    "NumeratorCoefficientsModuloPrime": list(value.numerator),
                    "DenominatorCoefficientsModuloPrime": list(value.denominator),
                    "NumeratorDegree": len(value.numerator) - 1,
                    "DenominatorDegree": len(value.denominator) - 1,
                })
    return {
        "DataType": "CF303BaselinePathGaugeNormalizationValueFiniteFieldProfile",
        "SchemaVersion": 2,
        "Status": "CF303BaselinePathGaugeNormalizationValueFiniteFieldProfileValidated",
        "Family": "CF303", "Prime": prime,
        "PathVariableValue": [1, 2],
        "MathematicalQuantity":
            "H_baseline(u=1/2,p,epsilon) contracted with the seven inherited mode columns",
        "UseInMovingBoundaryGerm":
            "add this value to the normalized H rho^0 coefficient to remove the baseline-H normalization term",
        "ExpressionCount": expression_count,
        "CoordinateCount": len(records),
        "Coordinates": records,
        "Validation": {
            "ExactTransferExpressionsUsed": expression_count == 12,
            "ReductionBeforeTangentialSampling": True,
            "AllSelectedEllipticChannelsZero": True,
        },
        "Seconds": time.perf_counter() - started,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, default=DEFAULT_PRIME)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    try:
        result = build_profile(arguments.prime)
    except BaselineAtBaseRefusal as error:
        print(json.dumps({"Status": error.status, **error.details}, sort_keys=True))
        return 2
    arguments.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({
        "Status": result["Status"], "Prime": result["Prime"],
        "CoordinateCount": result["CoordinateCount"],
        "Seconds": result["Seconds"], "Output": str(arguments.output),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
