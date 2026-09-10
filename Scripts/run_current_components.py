"""Run card-driven current stages from a project-owned JSON manifest."""
from pathlib import Path
import argparse
import json
import os
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
DRIVERS = {
    "Counterterm": "construct_partonic_counterterm.wls",
    "EvaluateCurrent": "run_current_contribution.wls",
    "Combine": "combine_current_components.wls",
    "EvaluateVirtual": "evaluate_current_virtual_integrals.wls",
    "PrepareVirtual": "prepare_current_virtual_integrals.wls",
    "ReduceVirtual": "reduce_current_virtual_integrals.wls",
    "PrepareSources": "prepare_current_integrals.wls",
    "Decompose": "prepare_current_integrals.wls",
    "FinishDecomposition": "prepare_current_integrals.wls",
    "EvaluateOneLoop": "evaluate_current_one_loop_integrands.wls",
    "ReduceOneLoop": "reduce_current_one_loop_integrands.wls",
    "Generate": "construct_current_integrands.wls",
    "Prepare": "prepare_current_integrals.wls",
    "DifferentialSystem": "construct_current_differential_systems.wls",
    "ShareMasters": "reduce_current_master_system.wls",
    "PrepareSolution": "prepare_current_differential_system.wls",
}

def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    manifest_path = args.manifest.resolve()
    manifest = json.loads(manifest_path.read_text())
    cpus = manifest.get("CpuSet", [0])
    available = os.sched_getaffinity(0)
    if not cpus or not set(cpus).issubset(available) or len(cpus) > 8:
        raise ValueError("CpuSet must name one to eight available CPUs.")
    report = (manifest_path.parent / manifest["Report"]).resolve()
    rows = []
    def interrupted(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    for job in manifest["Jobs"]:
        identity = [job[key] for key in ("Project", "Order", "Channel", "Contribution")]
        if any(not isinstance(value, str) or not value or "/" in value or "\\" in value
               or value in (".", "..") for value in identity):
            raise ValueError("Project, order, channel and contribution must be single path components.")
        project, order, channel, contribution = identity
        directory = ROOT / "Projects" / project / order / channel / "Results/Validation"
        directory.mkdir(parents=True, exist_ok=True)
        for stage in job["Stages"]:
            driver = ROOT / "Scripts" / DRIVERS[stage]
            logfile = directory / (contribution + "." + stage + ".log")
            command = ["taskset", "-c", ",".join(map(str, cpus)),
                       "wolframscript", "-file", str(driver), *identity,
                       *{"PrepareSources": ["prepare"], "Decompose": ["decompose"], "FinishDecomposition": ["finish"]}.get(stage, [])]
            start = time.monotonic()
            with logfile.open("w") as log:
                for startup_attempt in range(5):
                    attempt_offset = log.tell()
                    process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                               env={**os.environ, "FACET_CPU_COUNT": str(len(cpus))},
                                               start_new_session=True)
                    active = dict(zip(("Project", "Order", "Channel", "Contribution"), identity))
                    active.update(Stage=stage, PID=process.pid)
                    atomic_json(report, {"Active": active, "Completed": rows})
                    try:
                        code = process.wait(timeout=job.get("TimeoutSeconds", manifest.get("TimeoutSeconds")))
                    except (KeyboardInterrupt, subprocess.TimeoutExpired) as error:
                        # Wolfram may ignore SIGTERM during a long algebraic operation.
                        # Reap the whole owned job before another licensed kernel starts.
                        os.killpg(process.pid, signal.SIGTERM)
                        try:
                            process.wait(timeout=5)
                        except subprocess.TimeoutExpired:
                            os.killpg(process.pid, signal.SIGKILL)
                            process.wait()
                        code = 130 if isinstance(error, KeyboardInterrupt) else 124
                        log.write("\nCURRENT COMPONENT INTERRUPTED\n" if code == 130
                                  else "\nCURRENT COMPONENT TIME LIMIT\n")
                        log.flush()
                    log.flush()
                    attempt_output = logfile.read_bytes()[attempt_offset:].decode(errors="replace")
                    startup_lines = [line.strip() for line in attempt_output.splitlines() if line.strip()]
                    password_failure = set(startup_lines) == {
                        "No valid password found.", "Connection closed by WolframKernel."}
                    activation_failure = (len(startup_lines) == 3 and startup_lines[:2] == [
                        "Your Wolfram product is not activated or is experiencing a license-related problem.",
                        "Please activate the product at the following WolframKernel location:"]
                        and startup_lines[2].endswith("/WolframKernel"))
                    startup_only = code == 255 and (password_failure or activation_failure)
                    if not startup_only or startup_attempt == 4:
                        break
                    log.write("Retrying transient Wolfram license startup failure.\n")
                    log.flush()
                    time.sleep(2 ** (startup_attempt + 1))
            output = logfile.read_text(errors="replace")
            passed = (code == 0 and "COMPLETED " in output
                      and not any(token in output for token in
                                  ("::sntx", "Syntax::", "Get::noopen", "$Aborted")))
            rows.append({**active, "Seconds": time.monotonic() - start,
                         "ReturnCode": code, "Passed": passed, "StartupRetries": startup_attempt,
                         "Log": str(logfile.relative_to(ROOT))})
            atomic_json(report, {"Active": None, "Completed": rows})
            if not passed:
                return 1
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
