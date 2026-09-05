#!/usr/bin/env python3
"""Generate bounded CF303 moving-boundary H samples with two workers."""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import subprocess
import sys
import time
from pathlib import Path


HERE = Path(__file__).resolve().parent
POINT = HERE / "cf303_h_endpoint_point.py"


def accepted(path: Path, prime: int) -> bool:
    if not path.is_file():
        return False
    try:
        value = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return False
    return (
        value.get("Status") ==
        "CF303NormalPathGaugeAtMovingBoundaryFiniteFieldPointValidated"
        and value.get("Prime") == prime
        and value.get("RecordCount") == 336
    )


def run_point(prime: int, point: int, deck: Path, output: Path):
    if accepted(output, prime):
        return {"Point": point, "Status": "Cached", "Output": str(output)}
    environment = dict(os.environ)
    for name in (
        "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS",
        "VECLIB_MAXIMUM_THREADS", "NUMEXPR_NUM_THREADS",
    ):
        environment[name] = "1"
    completed = subprocess.run(
        [sys.executable, str(POINT), "--prime", str(prime), "--p", str(point),
         "--block1-deck", str(deck), "--orbit", "single",
         "--output", str(output)],
        capture_output=True, text=True, check=False, env=environment,
    )
    return {
        "Point": point,
        "Status": "Accepted" if completed.returncode == 0 else "Refused",
        "Output": str(output), "ReturnCode": completed.returncode,
        "Stdout": completed.stdout[-1000:], "Stderr": completed.stderr[-1000:],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prime", type=int, required=True)
    parser.add_argument("--block1-deck", type=Path, required=True)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--count", type=int, required=True)
    parser.add_argument("--start", type=int, default=3)
    parser.add_argument("--point-list", type=Path)
    parser.add_argument("--workers", type=int, choices=(1, 2), default=2)
    arguments = parser.parse_args()
    arguments.output_directory.mkdir(parents=True, exist_ok=True)
    started = time.perf_counter()
    accepted_records = []
    refused_records = []
    next_point = arguments.start
    listed_points = None
    listed_cursor = 0
    if arguments.point_list:
        raw_points = json.loads(arguments.point_list.read_text())
        if (not isinstance(raw_points, list)
                or any(not isinstance(item, list) or len(item) != 2
                       or not all(isinstance(value, int) for value in item)
                       or item[1] != 1 for item in raw_points)
                or len({item[0] for item in raw_points}) != len(raw_points)):
            raise RuntimeError("point list must contain distinct integer [p,1] pairs")
        listed_points = [item[0] for item in raw_points]
    with concurrent.futures.ThreadPoolExecutor(
        max_workers=arguments.workers
    ) as executor:
        while len(accepted_records) < arguments.count:
            if listed_points is None:
                batch = list(range(
                    next_point, next_point + arguments.workers
                ))
                next_point += arguments.workers
            else:
                batch = listed_points[
                    listed_cursor:listed_cursor + arguments.workers
                ]
                listed_cursor += len(batch)
                if not batch:
                    raise RuntimeError(
                        "point list exhausted before requested accepted count"
                    )
            futures = [executor.submit(
                run_point, arguments.prime, point, arguments.block1_deck,
                arguments.output_directory / f"p{point}.json",
            ) for point in batch]
            for future in futures:
                record = future.result()
                if record["Status"] in ("Accepted", "Cached"):
                    accepted_records.append(record)
                else:
                    refused_records.append(record)
                print(json.dumps({
                    "Point": record["Point"], "Status": record["Status"],
                    "AcceptedCount": len(accepted_records),
                    "RefusedCount": len(refused_records),
                }), flush=True)
                if len(accepted_records) >= arguments.count:
                    break
    print(json.dumps({
        "Status": "CF303HEndpointSampleCampaignComplete",
        "Prime": arguments.prime, "RequestedCount": arguments.count,
        "AcceptedCount": len(accepted_records),
        "RefusedCount": len(refused_records),
        "WallSeconds": time.perf_counter() - started,
        "OutputDirectory": str(arguments.output_directory),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
