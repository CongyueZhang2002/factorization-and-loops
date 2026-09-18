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
    "RawContribution": "run_raw_contribution.wls",
    "EvaluateVirtual": "evaluate_current_virtual_integrals.wls",
    "PrepareVirtual": "prepare_current_virtual_integrals.wls",
    "ReduceVirtual": "reduce_current_virtual_integrals.wls",
    "PrepareSources": "prepare_current_integrals.wls",
    "Decompose": "prepare_current_integrals.wls",
    "FinishDecomposition": "prepare_current_integrals.wls",
    "EvaluateOneLoop": "evaluate_current_one_loop_integrands.wls",
    "OneLoopEndpoints": "construct_current_one_loop_endpoints.wls",
    "VirtualIntegrationPlan": "prepare_virtual_integration_plan.wls",
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
    if len(identity[3].split(".")) > 2 or any(not part for part in identity[3].split(".")):
        raise ValueError("Contribution accepts one optional named component.")
    return identity


def stage_arguments(job, stage):
    if stage not in DRIVERS:
        raise ValueError(f"Unknown contribution stage: {stage}")
    identity = job_identity(job)
    project, order, channel, contribution = identity
    if stage == "RawContribution":
        if "." in contribution:
            raise ValueError("A raw execution selects one complete contribution card.")
        return [str(ROOT / "Projects" / project / "Raw" / order / channel / contribution / "Card.wl"), "all"]
    owner = str(Path("Projects") / project / "Raw" / order / channel)
    parts = contribution.split(".")
    work = Path(parts[0]) / "Work"
    for part in parts[1:]:
        work = work / "Components" / part / "Work"
    component = str(work)
    execution = job.get("Execution", {})
    if stage == "GeneratePairs":
        return [owner, contribution, "resume", str(execution.get("Kernels", 1))]
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
    for job in manifest["Jobs"]:
        if not job.get("Stages"):
            raise ValueError("Each job must declare at least one stage.")
        for stage in job["Stages"]:
            stage_arguments(job, stage)
    rows = []
    def interrupted(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    for job in manifest["Jobs"]:
        identity = job_identity(job)
        project, order, channel, contribution = identity
        parts = contribution.split(".")
        work = ROOT / "Projects" / project / "Raw" / order / channel / parts[0] / "Work"
        if len(parts) == 2:
            work = work / "Components" / parts[1] / "Work"
        for stage in job["Stages"]:
            driver = ROOT / "Scripts" / DRIVERS[stage]
            logfile = work / "Validation" / (stage + ".log")
            active = dict(zip(("Project", "Order", "Channel", "Contribution"), identity))
            active["Stage"] = stage

            def record_start(process):
                active["PID"] = process.pid
                atomic_json(report, {"Active": active, "Completed": rows})

            marker = {"RawContribution": "RAW_CONTRIBUTION_COMPLETED", "GeneratePairs": "PAIR_ARTIFACTS_COMPLETED ", "ReducePairs": "STREAMDIRECTORY: ",
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
