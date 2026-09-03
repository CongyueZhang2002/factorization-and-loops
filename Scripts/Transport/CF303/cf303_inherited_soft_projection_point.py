#!/usr/bin/env python3
"""Project the CF303 physical endpoint map onto its seven inherited modes.

The accepted deferred evaluator is sampled first.  Projection is performed
before any reconstruction, and only Laurent powers rho^-2 through rho^0 are
returned.  No 2x43 symbolic map is built.
"""

from __future__ import annotations

import argparse
from fractions import Fraction
import importlib.util
import json
from pathlib import Path
import sys
import time
from typing import Any


HERE = Path(__file__).resolve().parent
ENDPOINT_SCRIPT = HERE / "cf303_deferred_soft_residue_point.py"
SPEC = importlib.util.spec_from_file_location(
    "cf303_deferred_soft_residue_point", ENDPOINT_SCRIPT
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("CF303EndpointPointProviderUnavailable")
endpoint_provider = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = endpoint_provider
SPEC.loader.exec_module(endpoint_provider)


MODE_SPECS = (
    {
        "mode_id": "CF1::Class1Volume",
        "family": "CF1", "class_id": 1, "state_weights": {1: 1},
        "epsilon_orders": range(-3, 3), "source_orders": [0, 5],
        "normal_eigenvalue": -2, "period_status": "KnownVolumeAnchor",
    },
    {
        "mode_id": "CF12::Class5Physical",
        "family": "CF12", "class_id": 5, "state_weights": {2: 1},
        "epsilon_orders": range(-3, 3), "source_orders": [0, 5],
        "normal_eigenvalue": 0,
        "period_status": "NoNullityPeriod;PhysicalJetsRequired",
    },
    {
        "mode_id": "CF21::PID6Particular",
        "family": "CF21", "class_id": 17, "state_weights": {12: 1},
        "epsilon_orders": range(-3, 3), "source_orders": [0, 5],
        "normal_eigenvalue": 0,
        "period_status": "FreeModeKnownZero;VolumeParticularRequired",
    },
    {
        "mode_id": "CF199::PID9ZeroMode",
        "family": "CF199", "class_id": 44,
        "state_weights": {21: 2, 22: -3},
        "epsilon_orders": range(-3, 4), "source_orders": [-1, 5],
        "normal_eigenvalue": 0, "period_status": "FormalUnevaluated",
    },
    {
        "mode_id": "CF199::Class44LambdaMinus4",
        "family": "CF199", "class_id": 44, "state_weights": {22: 1},
        "epsilon_orders": range(-3, 4), "source_orders": [-1, 5],
        "normal_eigenvalue": -4,
        "period_status": "PhysicalAnchorOrParticularJetsRequired",
    },
    {
        "mode_id": "CF53::PID9ZeroMode",
        "family": "CF53", "class_id": 44,
        "state_weights": {29: 2, 30: -3},
        "epsilon_orders": range(-3, 4), "source_orders": [-1, 5],
        "normal_eigenvalue": 0, "period_status": "FormalUnevaluated",
    },
    {
        "mode_id": "CF53::Class44LambdaMinus4",
        "family": "CF53", "class_id": 44, "state_weights": {30: 1},
        "epsilon_orders": range(-3, 4), "source_orders": [-1, 5],
        "normal_eigenvalue": -4,
        "period_status": "PhysicalAnchorOrParticularJetsRequired",
    },
)


class ProjectionError(Exception):
    def __init__(self, status: str, **details: Any):
        super().__init__(status)
        self.status = status
        self.details = details


def zero_channels() -> dict[str, list[int]]:
    return {"rational": [0, 0], "elliptic_y_coefficient": [0, 0]}


def local_coefficient(entry: dict[str, Any], power: int) -> dict[str, list[int]]:
    if power == 0:
        return entry["finite"]
    term = next((item for item in entry["principal"]
                 if item["rho_power"] == power), None)
    return zero_channels() if term is None else {
        "rational": term["rational"],
        "elliptic_y_coefficient": term["elliptic_y_coefficient"],
    }


def add_scaled(result: dict[str, list[int]], value: dict[str, list[int]],
               scale: int, prime: int) -> None:
    for channel in result:
        result[channel] = [
            (left + scale * right) % prime
            for left, right in zip(result[channel], value[channel])
        ]


def nonzero(value: dict[str, list[int]]) -> bool:
    return any(coefficient for channel in value.values()
               for coefficient in channel)


def build_projection(scratch: Path, p: Fraction,
                     adapter_point: Path | None = None,
                     block1_point: Path | None = None) -> dict[str, Any]:
    started = time.perf_counter()
    source = endpoint_provider.build_point_payload(
        scratch, p, adapter_point, block1_point
    )
    endpoint_map = source["physical_endpoint_map"]
    if (source["status"] != "CF303DeferredSoftResiduePointV1" or
            endpoint_map["status"] != "CF303PhysicalEndpointMapPointV1" or
            endpoint_map["support_source_masters"] !=
            [1, 2, 12, 21, 22, 29, 30] or
            endpoint_map["maximum_source_pole_order"] != 2):
        raise ProjectionError("CF303InheritedEndpointInputInvalid")
    index = {
        (entry["order"], entry["target_master"], entry["source_master"]): entry
        for entry in endpoint_map["source_entries"]
    }
    prime = source["prime"]
    projected = []
    for mode in MODE_SPECS:
        for order in mode["epsilon_orders"]:
            for target in source["target_rows"]:
                local = []
                for power in (-2, -1, 0):
                    value = zero_channels()
                    for state_row, weight in mode["state_weights"].items():
                        entry = index.get((order, target, state_row))
                        if entry is None:
                            raise ProjectionError(
                                "CF303InheritedWCoordinateMissing",
                                mode_id=mode["mode_id"], order=order,
                                target=target, state_row=state_row,
                            )
                        add_scaled(value, local_coefficient(entry, power),
                                   weight, prime)
                    if nonzero(value):
                        local.append({"rho_power": power, **value})
                projected.append({
                    "mode_id": mode["mode_id"], "family": mode["family"],
                    "class_id": mode["class_id"],
                    "normal_eigenvalue_over_epsilon":
                        mode["normal_eigenvalue"],
                    "period_status": mode["period_status"],
                    "source_state_weights": [
                        [row, weight]
                        for row, weight in mode["state_weights"].items()
                    ],
                    "source_boundary_order_window": mode["source_orders"],
                    "w_epsilon_order": order, "target_master": target,
                    "local_coefficients": local,
                })
    formal = [entry for entry in projected
              if entry["period_status"] == "FormalUnevaluated"]
    elliptic_nonzero = sum(
        any(item["elliptic_y_coefficient"] != [0, 0]
            for item in entry["local_coefficients"])
        for entry in projected
    )
    extension_nonzero = sum(
        any(item["rational"][1] != 0
            for item in entry["local_coefficients"])
        for entry in projected
    )
    return {
        "status": "CF303InheritedSoftProjectionPointV1",
        "prime": prime, "p": source["p"],
        "endpoint": source["endpoint"],
        "basis": "AcceptedPathGaugeG25FinalLayer",
        "relation": "project W=[T25.H,T25] before reconstructing p",
        "final_target_order_window": [-4, 2],
        "local_rho_power_window": [-2, 0],
        "maximum_input_w_pole_order":
            endpoint_map["maximum_source_pole_order"],
        "target_rows": source["target_rows"],
        "source_state_rows": endpoint_map["support_source_masters"],
        "mode_count": len(MODE_SPECS),
        "projected_w_coordinate_count": len(projected),
        "formal_pid9_coordinate_count": len(formal),
        "formal_period_realizations": ["CF199::PID9", "CF53::PID9"],
        "coefficient_field_usage": {
            "rational_extension_nonzero": extension_nonzero,
            "elliptic_y_nonzero": elliptic_nonzero,
            "rational_base_only": extension_nonzero == elliptic_nonzero == 0,
        },
        "provider_timings_seconds": source["timings_seconds"],
        "projection_seconds": time.perf_counter() - started -
            source["timings_seconds"]["total"],
        "total_seconds": time.perf_counter() - started,
        "mode_projections": projected,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scratch", type=Path,
                        default=endpoint_provider.DEFAULT_SCRATCH)
    parser.add_argument("--p", type=Fraction, default=Fraction(3))
    parser.add_argument("--adapter-point", type=Path)
    parser.add_argument("--block1-point", type=Path)
    parser.add_argument("--output", type=Path)
    arguments = parser.parse_args()
    try:
        payload = build_projection(
            arguments.scratch, arguments.p,
            arguments.adapter_point, arguments.block1_point,
        )
    except (ProjectionError, endpoint_provider.EndpointResidueError,
            FileNotFoundError, ZeroDivisionError) as error:
        if hasattr(error, "status"):
            failure = {"status": error.status, **getattr(error, "details", {})}
        else:
            failure = {"status": type(error).__name__, "message": str(error)}
        print(json.dumps(failure, sort_keys=True))
        return 2
    encoded = json.dumps(payload, indent=2) + "\n"
    if arguments.output:
        arguments.output.write_text(encoded)
        print(json.dumps({
            "status": payload["status"], "output": str(arguments.output),
            "coordinates": payload["projected_w_coordinate_count"],
            "formal": payload["formal_pid9_coordinate_count"],
            "seconds": payload["total_seconds"],
        }, sort_keys=True))
    else:
        print(encoded, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
