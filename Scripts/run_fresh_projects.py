#!/usr/bin/env python3
"""Run declared project/order calculations sequentially with an eight-CPU limit."""
from pathlib import Path
import argparse
import datetime
import json
import os
import signal
import time
from wolfram import ROOT, atomic_json, run_wolfram, select_cpus

def require_cleared_order(project, order):
    """Fresh means no generated contribution data, including cached masters."""
    for layer, card_name, depth in (("Raw", "Card.wl", 3), ("Results", "Result_Card.wl", 2)):
        base = project / layer / order
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            relative = path.relative_to(base)
            if path.name == card_name and len(relative.parts) == depth:
                continue
            if path.suffix == ".md" or path.name == ".gitignore":
                continue
            raise ValueError(f"Fresh calculation requires cleared generated data: {path}")


def input_snapshot(jobs):
    """Exact card text, without hashes or generated symbolic data."""
    inputs = {}
    for job in jobs:
        project = ROOT / "Projects" / job["Project"]
        files = [project / "Common-Card.wl"]
        for order in job["Orders"]:
            files.extend((project / "Raw" / order).glob("*/*/Card.wl"))
            files.extend((project / "Results" / order).glob("*/Result_Card.wl"))
        for path in sorted(set(files)):
            inputs[str(path.relative_to(ROOT))] = path.read_text()
    return inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--resume", action="store_true", help="Continue recorded stages, retaining failed-attempt time.")
    parser.add_argument("--rerun-from", nargs=3, metavar=("PROJECT", "ORDER", "STAGE"),
                        help="Invalidate this completed stage and its descendants within a resumed order.")
    parser.add_argument("--reason", help="Reason for invalidating recorded results.")
    args = parser.parse_args()
    source = args.manifest.resolve()
    manifest = json.loads(source.read_text())
    library_mode = manifest.get("MasterIntegralLibraryMode", "Recompute")
    if library_mode not in ("Recompute", "ReadWrite", "Disabled"):
        raise ValueError("Select Recompute, ReadWrite or Disabled for the shared master library.")
    os.environ["FEYNFACET_MASTER_LIBRARY_MODE"] = library_mode

    cpus = select_cpus(manifest.get("CpuSet"))
    report = (source.parent / manifest["Report"]).resolve()
    jobs = manifest["Projects"]
    snapshot_file = report.with_name(report.stem + "-Inputs.json")
    prior = json.loads(report.read_text()) if args.resume else {}
    if args.resume and (prior.get("CpuSet") != cpus or prior.get("ProjectRequests") != jobs
                        or prior.get("MasterIntegralLibraryMode", "Recompute") != library_mode):
        raise ValueError("Resume requires the recorded projects, orders, CPU allocation and master-library mode.")
    cards = input_snapshot(jobs)
    if args.resume:
        if not snapshot_file.is_file() or json.loads(snapshot_file.read_text())["Cards"] != cards:
            raise ValueError("Resume requires unchanged recorded cards.")
    elif report.exists():
        raise ValueError("A campaign report already exists; use --resume or a new report.")
    else:
        atomic_json(snapshot_file, {"Cards": cards, "RecordedAt": "BeforeExecution", "Upstream": {}})
    snapshots = json.loads(snapshot_file.read_text())
    prior_rows = prior.get("Completed", [])
    invalidations = list(prior.get("Invalidations", []))
    if args.rerun_from:
        if not args.resume or not args.reason or not args.reason.strip():
            raise ValueError("--rerun-from requires --resume and an explicit --reason.")
        name, order, stage_name = args.rerun_from
        selected_job = next((job for job in jobs if job["Project"] == name and order in job["Orders"]), None)
        if selected_job is None:
            raise ValueError("The invalidated order must belong to this campaign.")
        stage_names = ["Assembly"]
        if order == "NNLO":
            recipe = json.loads((source.parent / selected_job["Upstream"]).resolve().read_text())
            stage_names = ["PrepareUpstream"] + [stage["Name"] for stage in recipe["Stages"]] + ["Assembly"]
        if stage_name not in stage_names:
            raise ValueError("Unknown stage in the recorded linear producer recipe.")
        affected = set(stage_names[stage_names.index(stage_name):])
        for row in prior_rows:
            if row["Project"] == name and row["Order"] == order and row.get("Stage", "Assembly") in affected:
                row["Invalidated"] = True
                row["InvalidationReason"] = args.reason
        invalidations.append({"Project": name, "Order": order, "FromStage": stage_name,
            "Reason": args.reason, "RecordedUTC": datetime.datetime.now(datetime.timezone.utc).isoformat()})

    def order_rows(name, order):
        return [row for row in prior_rows if row["Project"] == name and row["Order"] == order]
    for job in jobs:
        name = job["Project"]
        if not isinstance(name, str) or name in ("", ".", "..") or "/" in name or chr(92) in name:
            raise ValueError("Project must be one directory name.")
        project = ROOT / "Projects" / name
        if not (project / "Common-Card.wl").is_file():
            raise ValueError(f"Missing project card: {project}")
        if not job["Orders"] or any(order not in ("NLO", "NNLO") for order in job["Orders"]):
            raise ValueError("Select explicit NLO/NNLO orders.")
        for order in job["Orders"]:
            if not order_rows(name, order):
                require_cleared_order(project, order)
            if order == "NNLO" and not job.get("Upstream"):
                raise ValueError("Fresh NNLO requires an explicit upstream producer manifest.")
    rows = list(prior_rows)
    started = time.monotonic()
    active = None
    def state():
        atomic_json(report, {"CpuSet": cpus, "ProjectRequests": jobs,
            "MasterIntegralLibraryMode": library_mode,
            "Active": active, "Completed": rows, "Invalidations": invalidations,
            "CurrentSegmentElapsedSeconds": time.monotonic() - started,
            "AccumulatedExecutionSeconds": sum(row["Seconds"] for row in rows if "ReturnCode" in row),
            "TimingScope": "Actual supervised execution including startup and cleanup. Resumed orders sum measured attempts; verification is separate."})

    def execute(name, order, stage_name, driver, arguments, logfile, completion, timeout):
        nonlocal active
        matches = [row for row in rows if row["Project"] == name and row["Order"] == order
                   and row.get("Stage", "Assembly") == stage_name and "ReturnCode" in row]
        passed = [row for row in matches if row.get("Passed") is True and not row.get("Invalidated", False)]
        if passed:
            return passed[-1]
        logfile = Path(logfile)
        if matches:
            logfile = logfile.with_name(logfile.stem + f"-Attempt{len(matches)+1}" + logfile.suffix)
        active = {"Project": name, "Order": order, "Stage": stage_name,
                  "StartedUTC": datetime.datetime.now(datetime.timezone.utc).isoformat()}
        def on_start(process):
            active["PID"] = process.pid
            active["Log"] = str(logfile)
            state()
        outcome = run_wolfram(driver, arguments, logfile=logfile, completion=completion,
                              cpus=cpus, timeout=timeout, on_start=on_start)
        result = {**active, **outcome}
        rows.append(result)
        active = None
        state()
        return result
    def interrupted(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    for job in jobs:
        project = ROOT / "Projects" / job["Project"]
        project_started = time.monotonic()
        for order in job["Orders"]:
            prior_order = order_rows(job["Project"], order)
            if any(row.get("Stage", "Assembly") == "Assembly" and row.get("Passed") and not row.get("Invalidated", False) for row in prior_order):
                base = project / "Results" / order
                expected = list(base.glob("*/Result_Card.wl"))
                if not expected or not (base / "Timing.json").is_file() or any(
                    not (card.parent / filename).is_file() for card in expected
                    for filename in ("Results.wl", "Results.wl.meta.wxf")):
                    raise ValueError("Recorded completed order is missing its result files.")
                continue
            order_started = time.monotonic()
            upstream_seconds = {}
            upstream_planning = 0
            # Upstream stages must be explicitly supervised and completed before
            # assembly can be considered a fresh NNLO result.
            if order == "NNLO":
                upstream = (source.parent / job["Upstream"]).resolve()
                if not upstream.is_relative_to(project):
                    raise ValueError("The generated upstream manifest must belong to this project.")
                preparation = execute(job["Project"], order, "PrepareUpstream",
                    ROOT / "Scripts/prepare_project_upstream.wls", [job["Project"], order, upstream],
                    project / "Results" / order / "Validation" / "UpstreamPlanning.log",
                    "COMPLETED PROJECT UPSTREAM INVENTORY", job.get("TimeoutSeconds", 14400))
                if not preparation["Passed"]:
                    return 1
                upstream_planning = preparation["Seconds"]
                upstream_text = upstream.read_text()
                snapshot_key = str(upstream.relative_to(ROOT))
                old_recipe = snapshots["Upstream"].get(snapshot_key)
                if old_recipe is not None and old_recipe != upstream_text:
                    raise ValueError("Recorded upstream recipe changed during continuation.")
                snapshots["Upstream"][snapshot_key] = upstream_text
                atomic_json(snapshot_file, snapshots)
                upstream_plan = json.loads(upstream_text)
                stages = upstream_plan["Stages"]
                if not stages:
                    raise ValueError("Fresh NNLO requires nonempty upstream stages.")
                for stage in stages:
                    driver = (ROOT / stage["Driver"]).resolve()
                    if not driver.is_relative_to(ROOT / "Scripts"):
                        raise ValueError("Upstream stages must use repository production drivers.")
                    logfile = (project / stage["Log"]).resolve()
                    if not logfile.is_relative_to(project):
                        raise ValueError("Upstream logs must belong to the active project.")
                    result = execute(job["Project"], order, stage["Name"], driver,
                        stage["Arguments"], logfile, stage["Completion"],
                        stage.get("TimeoutSeconds", job.get("TimeoutSeconds", 14400)))
                    location = logfile.relative_to(project).parts
                    if len(location) < 4 or location[:2] != ("Raw", order):
                        raise ValueError("Every upstream stage must have an explicit raw-channel owner.")
                    owner = location[2]
                    upstream_seconds[owner] = upstream_seconds.get(owner, 0) + result["Seconds"]
                    active = None
                    state()
                    if not result["Passed"]:
                        return 1
                if upstream_plan.get("FinalAssemblyReady") is not True:
                    rows.append({"Project": job["Project"], "Order": order,
                        "Passed": False, "Status": "IncompleteUpstreamProduction",
                        "Remaining": upstream_plan.get("Remaining", []),
                        "Seconds": time.monotonic() - order_started})
                    active = None
                    state()
                    return 1
            log = project / "Results" / order / "Validation" / "FreshRegeneration.log"
            assembly_arguments = [project, order, "all"]
            if order == "NNLO":
                upstream_timing = project / "Results" / order / "UpstreamTiming.json"
                atomic_json(upstream_timing, {
                    "UpstreamSecondsByOwnerChannel": upstream_seconds,
                    "UpstreamPlanningSeconds": upstream_planning,
                    "TimingScope": "Actual supervised upstream stages, including their kernel startup and cleanup."})
                assembly_arguments.append(upstream_timing)
            result = execute(job["Project"], order, "Assembly",
                ROOT / "Scripts/run_project_order.wls", assembly_arguments, log,
                "PROJECT_ORDER_COMPLETED", job.get("TimeoutSeconds", 14400))
            row = result
            if result["Passed"]:
                timing_file = project / "Results" / order / "Timing.json"
                timing = json.loads(timing_file.read_text())
                timing["CalculationSeconds"] = timing.pop("Seconds", timing.get("CalculationSeconds"))
                timing["AssemblyExecutionWallSeconds"] = result["Seconds"]
                attempts = [item for item in rows if item["Project"] == job["Project"]
                            and item["Order"] == order and "ReturnCode" in item]
                resumed = bool(order_rows(job["Project"], order))
                timing["Resumed"] = resumed
                timing["SuccessfulExecutionSeconds"] = sum(item["Seconds"] for item in attempts if item["Passed"] and not item.get("Invalidated", False))
                timing["DiscardedAttemptSeconds"] = sum(item["Seconds"] for item in attempts if item["Passed"] and item.get("Invalidated", False))
                timing["FailedAttemptSeconds"] = sum(item["Seconds"] for item in attempts if not item["Passed"])
                timing["MeasuredExecutionSeconds"] = sum(item["Seconds"] for item in attempts)
                if resumed:
                    timing.pop("WallSeconds", None)
                    timing["TimingKind"] = "AccumulatedStageExecution"
                else:
                    timing["WallSeconds"] = time.monotonic() - order_started
                    timing["TimingKind"] = "UninterruptedElapsedTime"
                timing["CpuSet"] = cpus
                timing["Fresh"] = library_mode != "ReadWrite"
                timing["FreshProjectArtifacts"] = True
                timing["MasterIntegralLibraryMode"] = library_mode
                timing["WallClock"] = "PythonMonotonic"
                timing["TimingScope"] = ("Shared master reuse is enabled; this is not a cold master-solution timing. " if library_mode == "ReadWrite" else "") + "Kernel startup, diagram/source generation, integral reduction and DE construction, physical boundaries, master solutions, endpoint extraction, all raw contributions, final assembly and cleanup. Shared upstream work is counted once; resumed attempts retain their original measured cost."
                atomic_json(timing_file, timing)
                row["CalculationSeconds"] = timing["CalculationSeconds"]
                row.update({key: timing[key] for key in ("WallSeconds", "MeasuredExecutionSeconds", "TimingKind") if key in timing})
                row["AssemblyExecutionWallSeconds"] = timing["AssemblyExecutionWallSeconds"]
            active = None
            state()
            print(("PASS" if result["Passed"] else "FAIL"), job["Project"], order,
                round(row.get("WallSeconds", result["Seconds"]), 3), flush=True)
            if not result["Passed"]:
                return 1
        state()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
