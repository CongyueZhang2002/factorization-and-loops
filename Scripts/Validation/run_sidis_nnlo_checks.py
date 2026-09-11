#!/usr/bin/env python3
"""Run independent SIDIS NNLO comparisons with at most two Wolfram kernels."""
from pathlib import Path
import argparse
import concurrent.futures
import signal
import sys
import threading

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from wolfram import ROOT, atomic_json, run_wolfram, select_cpus


def run_project(project, points, cpus, cancel):
    folder = ROOT / "Projects" / project / "NNLO/q-q/Results/Validation"
    outcomes = []
    for point in points:
        outcome = run_wolfram(ROOT / "Scripts/Validation/check_sidis_nnlo.wls",
            [project, point], logfile=folder / f"NNLOComparisonPoint{point}.log",
            completion="NNLO COMPARISON Passed", cpus=cpus, cancel=cancel)
        outcomes.append({"point": point, "passed": outcome["Passed"],
                         "seconds": outcome["Seconds"], "log": outcome["Log"]})
        print(project, point, "PASS" if outcome["Passed"] else "FAIL", flush=True)
        if not outcome["Passed"]:
            break
    report = {"project": project, "points": outcomes, "completed": len(outcomes) == len(points),
              "passed": len(outcomes) == len(points) and all(row["passed"] for row in outcomes)}
    atomic_json(folder / "NNLOComparisonCampaign.json", report)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("projects", nargs="+")
    parser.add_argument("--points", default="1,2,3,4,5")
    parser.add_argument("--cpus", type=int, nargs="+")
    args = parser.parse_args()
    points = [int(value) for value in args.points.split(",")]
    if not points or not all(point in range(1, 6) for point in points):
        parser.error("point indices must be 1,2,3,4,5")
    if any(not name or "/" in name or "\\" in name or name in (".", "..") for name in args.projects):
        parser.error("Projects must be single path components.")
    if len(set(args.projects)) != len(args.projects):
        parser.error("Repeated projects would write the same result concurrently.")
    cpus = select_cpus(args.cpus)
    cancel = threading.Event()

    def interrupted(signum, frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, interrupted)
    pool = concurrent.futures.ThreadPoolExecutor(max_workers=2)
    try:
        results = list(pool.map(lambda project: run_project(project, points, cpus, cancel), args.projects))
    except BaseException:
        cancel.set()
        raise
    finally:
        pool.shutdown(wait=True)
    return 0 if all(result["passed"] for result in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
