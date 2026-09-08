#!/usr/bin/env python3
"""Run physical AMFlow and DE comparisons, tracking every requested master.

Separate Wolfram processes avoid contaminating either computation with the
other's values. A dynamic family pool can share up to eight cores.
AMFlow's validated result cache is reused, but DE values are evaluated afresh.
"""
from __future__ import annotations
import argparse
import fcntl
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def write_json(path, value):
    path = Path(path)
    temp = path.with_name(path.name + ".tmp")
    temp.write_text(json.dumps(value, indent=2) + "\n")
    temp.replace(path)


def run(command, log, timeout):
    with open(log, "w") as stream:
        process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT,
                                   start_new_session=True)
        try:
            return process.wait(timeout=timeout)
        except (subprocess.TimeoutExpired, KeyboardInterrupt):
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--only", help="Comma-separated family IDs; default is all families")
    parser.add_argument("--rows", help="Comma-separated master rows, with exactly one --only family")
    parser.add_argument("--time-limit", type=int, default=2400, help="Seconds per computation")
    parser.add_argument("--workers", type=int, default=1, help="Concurrent families, 1 through 8")
    parser.add_argument("--resume", action="store_true", help="Retain completed comparisons and retry unfinished families")
    args = parser.parse_args()
    spec = json.loads(args.manifest.read_text())
    root = Path(spec["RepositoryRoot"])
    families = {f["ID"]: f for f in spec["Families"]}
    current_files = {p.resolve() for p in Path(spec["SolutionCampaignDirectory"]).rglob("solution.wxf")}
    if current_files != {Path(f["SolutionFile"]).resolve() for f in spec["Families"]}:
        parser.error("Solution-family inventory changed; regenerate validation inputs")
    selected = args.only.split(",") if args.only else list(families)
    if not selected or len(set(selected)) != len(selected) or not set(selected) <= families.keys():
        parser.error("Unknown or repeated family ID")
    rows = None
    if args.rows:
        if len(selected) != 1 or not args.only:
            parser.error("--rows requires exactly one --only family")
        try:
            rows = [int(r) for r in args.rows.split(",")]
        except ValueError:
            parser.error("Rows must be integers")
        available = {m["Row"] for m in spec["MasterIntegrals"] if m["Family"] == selected[0]}
        if not rows or len(set(rows)) != len(rows) or not set(rows) <= available:
            parser.error("Unknown or repeated master row")
    threads = spec["Threads"]
    if type(threads) is not int or not 1 <= threads <= 8 or args.time_limit <= 0:
        parser.error("Use 1 through 8 cores and a positive time limit")
    if not 1 <= args.workers <= threads or (args.workers > 1 and rows is not None):
        parser.error("Workers must fit the core budget; pooled validation uses complete families")
    if hasattr(os, "sched_getaffinity"):
        cpus = sorted(os.sched_getaffinity(0))
        if len(cpus) < threads:
            parser.error("The process CPU affinity is smaller than the requested core count")
        os.sched_setaffinity(0, cpus[:threads])
    output = args.manifest.resolve().parent
    with (output / "complete_master_validation.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        masters = [dict(m, Status="NotChecked", PassedCoefficientCount=0) for m in spec["MasterIntegrals"]]
        if not masters or sum(len(m["RequiredOrders"]) for m in masters) != spec["RequiredCoefficientCount"]:
            raise ValueError("Invalid complete-master inventory")
        report_file = output / "complete_master_report.json"
        if args.resume and report_file.exists():
            old = json.loads(report_file.read_text())
            identity = lambda m: (m["Family"], m["Row"], m["MasterIntegral"], tuple(m["RequiredOrders"]))
            previous = {identity(m): m for m in old["MasterIntegrals"]}
            if set(previous) != {identity(m) for m in masters}:
                parser.error("Cannot resume a changed master/order inventory")
            for master in masters:
                master.update(previous[identity(master)])
    
        def collect(family, failure=None):
            attempted = [m for m in masters if m["Family"] == family and (rows is None or m["Row"] in rows)]
            summary = Path(families[family]["OutputDirectory"]) / "comparison.wxf.json"
            if failure in {"ReferenceFailed", "WorkerFailed"} or not summary.is_file():
                for master in attempted:
                    master.update(Status="EvaluationFailed" if failure == "WorkerFailed" else failure or "EvaluationFailed", PassedCoefficientCount=0)
                return
            report = json.loads(summary.read_text())
            if report.get("Results") and report.get("Family") != family:
                for master in attempted:
                    master.update(Status="EvaluationFailed", PassedCoefficientCount=0)
                return
            by_row = {m["Row"]: m for m in report.get("Results", [])}
            for master in attempted:
                record = by_row.get(master["Row"])
                if record is None or record["RequiredOrders"] != master["RequiredOrders"]:
                    master.update(Status="EvaluationFailed" if failure else "Incomplete", PassedCoefficientCount=0)
                elif record["Status"] == "Passed" and record.get("PassedCoefficientCount") != len(master["RequiredOrders"]):
                    master.update(Status="Incomplete", PassedCoefficientCount=0)
                else:
                    master.update(record)
    
        if args.resume:
            for family, task in families.items():
                summary = Path(task["OutputDirectory"]) / "comparison.wxf.json"
                if summary.is_file() and summary.stat().st_mtime >= max(Path(task[k]).stat().st_mtime for k in ("RequestFile", "SolutionFile")):
                    collect(family)
                else:
                    for master in masters:
                        if master["Family"] == family:
                            master.update(Status="NotChecked", PassedCoefficientCount=0)
        chosen = [m for m in masters if m["Family"] in selected and (rows is None or m["Row"] in rows)]
        state = dict(Test="CompleteMasterIntegrals", RequiredMasterCount=len(masters),
                     RequiredCoefficientCount=spec["RequiredCoefficientCount"],
                     SelectedMasterCount=len(chosen), MasterIntegrals=masters, StartedUnixTime=time.time())
    
        def save(running=False):
            state["PassedMasterCount"] = sum(m["Status"] == "Passed" for m in masters)
            state["PassedCoefficientCount"] = sum(m["PassedCoefficientCount"] for m in masters)
            state["NotCheckedMasterCount"] = sum(m["Status"] == "NotChecked" for m in masters)
            state["SelectedTestsPassed"] = all(m["Status"] == "Passed" for m in chosen)
            state["Status"] = ("Running" if running else "Passed" if all(m["Status"] == "Passed" for m in masters)
                               else "Failed" if any(m["Status"] in {"Failed", "ReferenceFailed", "EvaluationFailed"} for m in masters)
                               else "Incomplete")
            state["UpdatedUnixTime"] = time.time()
            write_json(output / "complete_master_report.json", state)
    
        save(True)
        if args.workers > 1:
            from family_pool import run_family_pool
            pending = [f for f in selected if not args.resume or any(m["Status"] != "Passed" for m in chosen if m["Family"] == f)]
            def progress(active, finished=None):
                state["ActiveFamilies"] = active
                if finished is not None:
                    family, status = finished
                    collect(family, status if status in {"ReferenceFailed", "EvaluationFailed", "WorkerFailed"} else None)
                save(True)
            code = run_family_pool(root, output, [families[f] for f in pending], args.workers, args.time_limit, progress)
            state.pop("ActiveFamilies", None)
            state["PoolExitCode"] = code
            save()
            print(f"Full inventory: {state['PassedMasterCount']}/{len(masters)} masters, "
                  f"{state['PassedCoefficientCount']}/{state['RequiredCoefficientCount']} coefficients", flush=True)
            return 0 if state["SelectedTestsPassed"] else 1
        for family in selected:
            if args.resume and all(m["Status"] == "Passed" for m in chosen if m["Family"] == family):
                continue
            task = families[family]
            folder = Path(task["OutputDirectory"])
            request = task["RequestFile"]
            reference_request = str(folder / "amflow_request.wl")
            reference = str(folder / "amflow_reference.wxf")
            comparison = str(folder / "comparison.wxf")
            summary = Path(comparison + ".json")
            suffix = [args.rows] if rows is not None else []
            commands = [
                ("prepare", ["wolframscript", "-file", str(root / "Scripts/Validation/prepare_complete_master_reference.wls"), request, reference_request, *suffix]),
                ("amflow", ["wolframscript", "-file", str(root / "Scripts/Transport/evaluate_masters_with_amflow.wls"), reference_request, reference]),
                ("compare", ["wolframscript", "-file", str(root / "Scripts/Validation/validate_complete_masters.wls"), request, reference, comparison, *suffix]),
            ]
            attempted = [m for m in chosen if m["Family"] == family]
            failed = None
            for phase, command in commands:
                print(f"{family}: {phase}", flush=True)
                state["CurrentFamily"] = family
                state["CurrentPhase"] = phase
                save(True)
                if phase == "compare":
                    summary.unlink(missing_ok=True)
                try:
                    code = run(command, folder / f"{phase}.log", args.time_limit)
                except subprocess.TimeoutExpired:
                    code = 124
                if code:
                    failed = "ReferenceFailed" if phase != "compare" else "EvaluationFailed"
                    print(f"{family}: {phase} failed ({code}); see {folder / (phase + '.log')}", flush=True)
                    break
            if failed and not (failed == "EvaluationFailed" and summary.is_file()):
                for master in attempted:
                    master["Status"] = failed
            elif not summary.is_file():
                for master in attempted:
                    master["Status"] = "EvaluationFailed"
            else:
                report = json.loads(summary.read_text())
                by_row = {m["Row"]: m for m in report["Results"]}
                for master in attempted:
                    record = by_row.get(master["Row"])
                    if record is None or record["RequiredOrders"] != master["RequiredOrders"]:
                        master["Status"] = "EvaluationFailed" if failed and not by_row else "Incomplete"
                    else:
                        master.update(record)
                print(f"{family}: {report['Status']}, {report.get('PassedCoefficientCount', 0)} coefficients", flush=True)
            save(True)
        state.pop("CurrentPhase", None)
        state.pop("CurrentFamily", None)
        save()
        print(f"Selected tests passed: {state['SelectedTestsPassed']}; full inventory: "
              f"{state['PassedMasterCount']}/{len(masters)} masters, "
              f"{state['PassedCoefficientCount']}/{state['RequiredCoefficientCount']} coefficients", flush=True)
        return 0 if state["SelectedTestsPassed"] else 1

if __name__ == "__main__":
    raise SystemExit(main())
