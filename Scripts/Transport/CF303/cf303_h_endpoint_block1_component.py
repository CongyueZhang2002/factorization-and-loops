#!/usr/bin/env python3
"""Replay the CF303 block-1 homogeneous H germ at existing p images.

This separates the block-1 homogeneous action from the cross-Hermite part of
the inherited mode-1 column.  It does not sample a new tangential point: the
point list is taken verbatim from an existing accepted H-germ campaign.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ProcessPoolExecutor
from fractions import Fraction
import importlib.util
import json
from pathlib import Path
import sys
import time
from typing import Any

import cf303_h_endpoint_interpolate as endpoint_samples


HERE = Path(__file__).resolve().parent
BUNDLE = HERE / "data/normal_factor_exact_circuit"
FULL = BUNDLE / "cf303_block1_full_exact_circuit.py"
PILOT = BUNDLE / "cf303_block1_modular_finite_gauge_pilot.py"
CIRCUIT = BUNDLE / "cf303_block1_full_exact_circuit.json"
EVALUATOR = BUNDLE / "cf303_hybrid_baseline_modular_circuit.py"
LOCALIZER = HERE / "cf303_deferred_soft_residue_point.py"
TARGET_ROWS = (44, 45)
NORMAL_POWERS = (-2, -1, 0)
_WORKER: dict[str, Any] = {}


class Block1ComponentRefusal(RuntimeError):
    def __init__(self, status: str, **details: Any) -> None:
        super().__init__(status)
        self.status = status
        self.details = details


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise Block1ComponentRefusal(
            "CF303Block1ComponentProviderUnavailable", Provider=path.name
        )
    module = importlib.util.module_from_spec(specification)
    sys.modules[name] = module
    specification.loader.exec_module(module)
    return module


def initialize_worker(prime: int, deck: str) -> None:
    suffix = str(prime)
    full = load_module(f"cf303_block1_component_full_{suffix}", FULL)
    pilot = load_module(f"cf303_block1_component_pilot_{suffix}", PILOT)
    evaluator = load_module(f"cf303_block1_component_evaluator_{suffix}", EVALUATOR)
    localizer = load_module(f"cf303_block1_component_localizer_{suffix}", LOCALIZER)
    context = pilot.load_context(prime, Path(deck))
    _WORKER.update({
        "prime": prime, "full": full, "pilot": pilot,
        "evaluator": evaluator, "localizer": localizer,
        "context": context, "manifest": json.loads(CIRCUIT.read_text()),
    })


def local_coefficient(local: dict[str, Any], power: int) -> int:
    if power == 0:
        channels = local["finite"]
    else:
        record = next((item for item in local["principal"]
                       if item["rho_power"] == power), None)
        channels = ({"rational": [0, 0],
                     "elliptic_y_coefficient": [0, 0]}
                    if record is None else record)
    if (channels["rational"][1] != 0
            or channels["elliptic_y_coefficient"] != [0, 0]):
        raise Block1ComponentRefusal(
            "CF303Block1ComponentNotInRationalCoefficientField",
            NormalCoordinatePower=power,
        )
    return int(channels["rational"][0])


def evaluate_point(point_pair: tuple[int, int]) -> dict[str, Any]:
    prime = _WORKER["prime"]
    full, pilot = _WORKER["full"], _WORKER["pilot"]
    evaluator, localizer = _WORKER["evaluator"], _WORKER["localizer"]
    context, manifest = _WORKER["context"], _WORKER["manifest"]
    point = Fraction(*point_pair)
    records = full.graph_evaluate(manifest, pilot, context, point)
    reference = pilot.run_point(context, point)["records"]
    if full.flatten(records) != full.flatten(reference):
        raise Block1ComponentRefusal(
            "CF303Block1ComponentCircuitReplayFailure", Point=list(point_pair)
        )
    endpoint = 2 * pilot.exact_fraction_mod(point, prime) % prime
    outputs = []
    for record in records:
        rational = evaluator.RationalFunction.make(
            record["h_numerator"], record["h_denominator"], prime,
            context["helper"],
        )
        zero = evaluator.RationalFunction.zero(prime)
        pair = (evaluator.ext_from_base(rational), evaluator.ext_from_base(zero))
        local = localizer.function_pair_local_data(
            pair, endpoint, prime, through_power=0
        )
        if local is None or local["valuation"] < -2:
            raise Block1ComponentRefusal(
                "CF303Block1ComponentLaurentWindowInvalid",
                Point=list(point_pair), Order=record["order"], Row=record["row"],
            )
        for power in NORMAL_POWERS:
            outputs.append({
                "EpsilonOrder": int(record["order"]),
                "TargetMasterIntegralRow": TARGET_ROWS[int(record["row"]) - 1],
                "NormalCoordinatePower": power,
                "Value": local_coefficient(local, power),
            })
    return {"TangentialPoint": list(point_pair), "Records": outputs}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample-directory", type=Path, required=True)
    parser.add_argument("--prime", type=int, required=True)
    parser.add_argument("--deck", type=Path, required=True)
    parser.add_argument("--workers", type=int, default=2)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    try:
        if arguments.workers < 1 or arguments.workers > 2:
            raise Block1ComponentRefusal(
                "CF303Block1ComponentWorkerCountInvalid",
                RequestedWorkers=arguments.workers,
            )
        paths = sorted(arguments.sample_directory.glob("p*.json"),
                       key=endpoint_samples.numeric_point)
        if not paths:
            raise Block1ComponentRefusal(
                "CF303Block1ComponentAcceptedPointListMissing"
            )
        samples = [endpoint_samples.read_sample(path, arguments.prime)
                   for path in paths]
        points = [tuple(map(int, sample["TangentialPoint"]))
                  for sample in samples]
        started = time.perf_counter()
        with ProcessPoolExecutor(
            max_workers=arguments.workers,
            initializer=initialize_worker,
            initargs=(arguments.prime, str(arguments.deck)),
        ) as pool:
            images = list(pool.map(evaluate_point, points))
        result = {
            "DataType": "CF303Block1HomogeneousMovingBoundaryGermFiniteFieldImages",
            "SchemaVersion": 2,
            "Status": "CF303Block1HomogeneousMovingBoundaryGermFiniteFieldImagesValidated",
            "Family": "CF303", "Prime": arguments.prime,
            "MathematicalQuantity":
                "Laurent coefficients rho^-2 through rho^0 of the block-1 homogeneous H action in inherited mode 1",
            "NormalCoordinate": "rho=2*p-u",
            "PointCount": len(images), "Points": images,
            "InputReferences": {
                "ExactCircuitBundle":
                    "Scripts/Transport/CF303/data/normal_factor_exact_circuit",
                "Block1LaurentDeckName": arguments.deck.name,
                "AcceptedPointSource": "Existing CF303 H-endpoint sample campaign",
            },
            "Validation": {
                "ExactCircuitReplayedAtEveryExistingPoint": True,
                "NoNewTangentialSamplePointsIntroduced": True,
                "RationalCoefficientFieldAfterRegularizedLocalization": True,
                "RecordCountPerPoint": 48,
            },
            "Seconds": time.perf_counter() - started,
        }
        arguments.output.write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps({
            "Status": result["Status"], "PointCount": len(images),
            "Seconds": result["Seconds"], "Output": str(arguments.output),
        }, sort_keys=True))
        return 0
    except Block1ComponentRefusal as error:
        print(json.dumps({"Status": error.status, **error.details}, sort_keys=True))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
