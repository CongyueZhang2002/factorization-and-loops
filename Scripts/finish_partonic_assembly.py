#!/usr/bin/env python3
"""Replay final assembly from explicit solved bulk and face profiles."""
from pathlib import Path
import argparse
import signal

from wolfram import ROOT, run_wolfram, select_cpus


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("endpoint_plan", type=Path)
    parser.add_argument("finalization_plan", type=Path)
    parser.add_argument("--projects", nargs="+", required=True)
    parser.add_argument("--order", required=True)
    parser.add_argument("--cpus", type=int, nargs="+")
    parser.add_argument("--timeout", type=float)
    args = parser.parse_args()
    cpus = select_cpus(args.cpus)
    if any(not name or "/" in name or "\\" in name or name in (".", "..")
           for name in [*args.projects, args.order]):
        parser.error("Projects and order must be single path components.")

    def interrupted(signum, frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, interrupted)
    steps = [
        ("assemble_endpoint_profiles.wls", "COMPLETED ALL ENDPOINT PROFILE OUTPUTS ",
         [args.endpoint_plan.resolve()], args.endpoint_plan.resolve().parent),
        *(("combine_partonic_contributions.wls", "COMPLETED ALL PARTONIC CONTRIBUTION SUMS ",
           [project, args.order], args.finalization_plan.resolve().parent) for project in args.projects),
        ("finalize_partonic_results.wls", "COMPLETED FINITE PARTONIC RESULTS ",
         [args.finalization_plan.resolve()], args.finalization_plan.resolve().parent),
    ]
    for index, (script, completion, arguments, folder) in enumerate(steps):
        logfile = folder / f"AssemblyStep{index + 1}.{Path(script).stem}.log"
        outcome = run_wolfram(ROOT / "Scripts" / script, arguments, logfile=logfile,
            completion=completion, cpus=cpus, timeout=args.timeout)
        print(script, "PASS" if outcome["Passed"] else "FAIL",
              f'{outcome["Seconds"]:.2f} s', logfile, flush=True)
        if not outcome["Passed"]:
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
