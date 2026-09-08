"""Coordinate licensed family subkernels and publish complete coverage as they finish."""
from __future__ import annotations
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def run_family_pool(root, output, families, workers, timeout, progress):
    if not families:
        return 0
    cpus = sorted(os.sched_getaffinity(0))[:workers]
    spec = dict(RepositoryRoot=str(root), OutputDirectory=str(output), Workers=workers,
                CPUs=cpus, Tasks=[dict(f, RepositoryRoot=str(root), PhaseTimeLimit=timeout) for f in families])
    request = output / "family_pool.json"
    request.write_text(json.dumps(spec, indent=2) + "\n")
    for family in families:
        (Path(family["OutputDirectory"]) / "pool_status.json").unlink(missing_ok=True)
    (output / "pool_state.json").unlink(missing_ok=True)
    with (output / "family_pool.log").open("a") as log:
        process = subprocess.Popen(["wolframscript", "-file", str(root / "Scripts/Validation/family_pool.wls"),
                                    str(request)], stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        delivered = set()
        previous_active = None
        try:
            while True:
                active = []
                state_file = output / "pool_state.json"
                if state_file.exists():
                    state = json.loads(state_file.read_text())
                    active = state.get("ActiveFamilies", [])
                changed = active != previous_active
                for family in families:
                    path = Path(family["OutputDirectory"]) / "pool_status.json"
                    if family["ID"] in delivered or not path.exists():
                        continue
                    status = json.loads(path.read_text())
                    if status.get("Finished"):
                        delivered.add(family["ID"])
                        print(f"{family['ID']}: {status['Status']} ({status.get('ElapsedSeconds', 0):.1f}s)", flush=True)
                        progress(active, (family["ID"], status["Status"]))
                        changed = False
                if changed:
                    progress(active)
                previous_active = active
                code = process.poll()
                if code is not None:
                    for family in families:
                        if family["ID"] not in delivered:
                            progress([], (family["ID"], "WorkerFailed"))
                    return code
                time.sleep(1)
        except BaseException:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            raise
