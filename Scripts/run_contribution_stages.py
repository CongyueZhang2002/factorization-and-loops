"""Run contribution stages from a project-owned JSON manifest."""
from pathlib import Path
import argparse
import json
import signal

from wolfram import ROOT, atomic_json, run_wolfram, select_cpus
DRIVERS = {
    "GeneratePairs": "regenerate_pairs.wls",
    "ReducePairs": "canonicalize_and_stream.wls",
    "ImportReduction": "canonicalize_and_stream.wls",
    "ReconstructCoefficients": "stream_to_coefficients.wls",
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

def job_identity(job):
    identity = [job[key] for key in ("Project", "Order", "Channel", "Contribution")]
    if any(not isinstance(value, str) or not value or value in (".", "..")
           or any(separator in value for separator in ("/", chr(92))) for value in identity):
        raise ValueError("Project, order, channel and contribution must be single path components.")
    if any(not part for part in identity[3].split(".")):
        raise ValueError("Contribution must contain nonempty dot-separated card components.")
    return identity


def stage_arguments(job, stage):
    identity = job_identity(job)
    project, order, channel, contribution = identity
    owner = str(Path("Projects") / project / order / channel)
    component = contribution.replace(".", "/")
    execution = job.get("Execution", {})
    if stage == "GeneratePairs":
        return [owner, contribution, component + "/Amplitudes", str(execution.get("Kernels", 1))]
    if stage in ("ReducePairs", "ImportReduction"):
        return [owner, component + "/Amplitudes", component + "/Reduction",
                "import" if stage == "ImportReduction" else "solve",
                str(execution.get("KiraThreads", 1))]
    if stage == "ReconstructCoefficients":
        return [owner, component + "/Reduction", str(execution.get("ReconstructionThreads", 1)),
                str(execution.get("NormalizationKernels", 1))]
    options = {"PrepareSources": ["prepare"], "Decompose": ["decompose"],
               "FinishDecomposition": ["finish"]}.get(stage, [])
    return [*identity, *options]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    manifest_path = args.manifest.resolve()
    manifest = json.loads(manifest_path.read_text())
    cpus = select_cpus(manifest.get("CpuSet"))
    report = (manifest_path.parent / manifest["Report"]).resolve()
    rows = []
    def interrupted(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    for job in manifest["Jobs"]:
        identity = job_identity(job)
        project, order, channel, contribution = identity
        directory = ROOT / "Projects" / project / order / channel / "Results/Validation"
        directory.mkdir(parents=True, exist_ok=True)
        for stage in job["Stages"]:
            driver = ROOT / "Scripts" / DRIVERS[stage]
            logfile = directory / (contribution + "." + stage + ".log")
            active = dict(zip(("Project", "Order", "Channel", "Contribution"), identity))
            active["Stage"] = stage

            def record_start(process):
                active["PID"] = process.pid
                atomic_json(report, {"Active": active, "Completed": rows})

            marker = {"GeneratePairs": "FAILURES: 0", "ReducePairs": "STREAMDIRECTORY: ",
                      "ImportReduction": "COMPLETED KIRA STREAM ",
                      "ReconstructCoefficients": "COEFFICIENTFILE: "}.get(stage, "COMPLETED ")
            outcome = run_wolfram(driver, stage_arguments(job, stage), logfile=logfile,
                completion=marker, cpus=cpus, on_start=record_start,
                timeout=job.get("TimeoutSeconds", manifest.get("TimeoutSeconds")))
            rows.append({**active, **outcome, "Log": str(logfile.relative_to(ROOT))})
            atomic_json(report, {"Active": None, "Completed": rows})
            if not outcome["Passed"]:
                return 1
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
