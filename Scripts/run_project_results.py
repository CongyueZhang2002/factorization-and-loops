#!/usr/bin/env python3
"""Regenerate explicit result cards with two supervised kernels and eight CPUs total."""
from pathlib import Path
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import queue
import json
import time
import signal
import threading
from wolfram import ROOT, run_wolfram, atomic_json, select_cpus

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("cards", nargs="*")
    parser.add_argument("--order", default="NLO")
    parser.add_argument("--mode", choices=("all", "resume", "assemble", "plan"), default="all")
    parser.add_argument("--report", required=True)
    parser.add_argument("--timeout", type=float, default=3600)
    parser.add_argument("--workers", type=int, choices=(1, 2), default=2)
    parser.add_argument("--cpus", type=int, nargs="+")
    args = parser.parse_args()
    cards = [Path(p).resolve() for p in args.cards] if args.cards else sorted(
        (ROOT / "Projects").glob(f"*/Results/{args.order}/*/Result_Card.wl"))
    if not cards:
        parser.error("No result cards selected.")
    if len(set(cards)) != len(cards):
        parser.error("A result card may be selected only once.")
    if any(not p.is_file() or not p.is_relative_to(ROOT / "Projects") for p in cards):
        parser.error("Every input must be an existing project result card.")
    available = select_cpus(args.cpus)
    groups = [available] if len(cards) == 1 or args.workers == 1 else [available[::2], available[1::2]]
    groups = [g for g in groups if g]
    slots = queue.Queue()
    for cpus in groups:
        slots.put(cpus)
    started = time.monotonic()
    rows = []
    cancel = threading.Event()
    previous_handlers = {}
    for sig in (signal.SIGINT, signal.SIGTERM):
        previous_handlers[sig] = signal.signal(sig, lambda signum, frame: cancel.set())
    def run(card):
        cpus = slots.get()
        try:
            if cancel.is_set():
                return {"Card": str(card), "CpuSet": cpus, "ReturnCode": 130,
                        "Passed": False, "Seconds": 0, "StartupRetries": 0,
                        "Log": None, "Status": "CancelledBeforeStart"}
            log = card.parent / "Validation" / "Regeneration.log"
            value = run_wolfram(ROOT / "Scripts/run_project_result.wls", [str(card), args.mode],
                logfile=log, completion="PROJECT_RESULT_COMPLETED", cpus=cpus, timeout=args.timeout, cancel=cancel)
            timing_file = card.parent / "Timing.json"
            if value["Passed"] and args.mode != "plan":
                timing = json.loads(timing_file.read_text())
                timing["WolframSeconds"] = timing.pop("Seconds")
                timing.update({"WallSeconds": value["Seconds"], "CpuSet": cpus,
                               "WallTimeIncludes": "Kernel startup, calculation and owned-process cleanup"})
                atomic_json(timing_file, timing)
                (card.parent / "Pending.json").unlink(missing_ok=True)
            return {"Card": str(card), "CpuSet": cpus, **value}
        finally:
            slots.put(cpus)
    try:
        with ThreadPoolExecutor(max_workers=len(groups)) as pool:
            futures = [pool.submit(run, card) for card in cards]
            try:
                for future in as_completed(futures):
                    row = future.result()
                    rows.append(row)
                    atomic_json(args.report, {"Mode": args.mode, "Requested": len(cards),
                        "Finished": len(rows), "Passed": sum(x["Passed"] for x in rows),
                        "Cancelled": cancel.is_set(),
                        "ElapsedSeconds": time.monotonic() - started, "Channels": rows})
                    print(("PASS" if row["Passed"] else "FAIL"), row["Card"], round(row["Seconds"], 3), flush=True)
            except BaseException:
                cancel.set()
                raise
    finally:
        for sig, handler in previous_handlers.items():
            signal.signal(sig, handler)
    return 130 if cancel.is_set() else (0 if all(r["Passed"] for r in rows) else 1)

if __name__ == "__main__":
    raise SystemExit(main())
