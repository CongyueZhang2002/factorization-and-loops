#!/usr/bin/env python3
"""Resume a family-parallel DE -> explicit finite-solution campaign in one KernelPool.

All mathematical inputs and family names come from a JSON specification. This
does not launch kernels, infer endpoint orders, or declare canonical forms.
"""
from __future__ import annotations
import argparse
import fcntl
import filecmp
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time
import uuid

SAFE = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,79}\Z")
COMPLETE = {"Completed", "NotRequiredByCoefficientOrders"}
TERMINAL = COMPLETE | {"Incomplete"}
OWNED_ARGUMENTS = {"--family", "--scratch", "--output", "--kira-threads", "--repository-root"}


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def wl_string(value):
    return json.dumps(str(value), ensure_ascii=False)


def wl(value):
    if isinstance(value, str):
        return wl_string(value)
    if value is True:
        return "True"
    if value is False:
        return "False"
    if value is None:
        return "None"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return "{" + ",".join(map(wl, value)) + "}"
    if isinstance(value, dict):
        return "<|" + ",".join(wl_string(k) + "->" + wl(v) for k, v in value.items()) + "|>"
    raise ValueError("Unsupported Wolfram specification value")


def validate(spec):
    required = ("RepositoryRoot", "PoolDirectory", "OutputDirectory", "ScratchDirectory",
                "OrderRequirementsFile", "DifferentialSystemArguments", "SourceFiles", "Families")
    if any(k not in spec for k in required):
        raise ValueError("Campaign paths, source files, DE arguments and families are required")
    if not isinstance(spec["Families"], list) or not spec["Families"]:
        raise ValueError("Families must be a nonempty list")
    names = [f["Family"] for f in spec["Families"]]
    if any(not SAFE.fullmatch(n) for n in names) or len(names) != len(set(names)):
        raise ValueError("Family names must be safe and unique")
    count = spec.get("MaximumConcurrentFamilies", 6)
    if type(count) is not int or not 1 <= count <= 8:
        raise ValueError("MaximumConcurrentFamilies must be 1 through 8")
    if any(a in OWNED_ARGUMENTS for a in spec["DifferentialSystemArguments"]):
        raise ValueError("Family, scratch, output, repository and Kira threads are owned by the coordinator")
    for key in ("DifferentialSystemTimeLimitSeconds", "FiniteSolutionTimeLimitSeconds"):
        if not isinstance(spec.get(key, 900), (int, float)) or spec.get(key, 900) <= 0:
            raise ValueError(f"{key} must be positive")
    for key in required[:5]:
        if not Path(spec[key]).is_absolute():
            raise ValueError(f"{key} must be an absolute path")


def input_files(spec):
    paths = [spec["OrderRequirementsFile"], *spec["SourceFiles"]]
    for family in spec["Families"]:
        paths.extend(family[k] for k in ("RequestOptionsFile", "FiniteIntegrationPreparationFile",
                                        "DimensionalRecurrenceFile") if k in family)
    return sorted(set(paths))


def ensure_inputs(spec, output):
    """Direct byte comparison, no hashes or mtime-only cache acceptance."""
    path = output / "campaign-input.json"
    if path.exists() and json.loads(path.read_text()) != spec:
        raise ValueError("Existing campaign specification differs; use another output directory")
    source_dir = output / "source-inputs"
    source_dir.mkdir(parents=True, exist_ok=True)
    sources = []
    for source in input_files(spec):
        sources.append(source)
        companion = Path(str(source) + ".meta.wxf")
        if companion.is_file():
            sources.append(str(companion))
    for index, source in enumerate(sources):
        source = Path(source)
        if not source.is_file():
            raise ValueError(f"Missing source input: {source}")
        saved = source_dir / f"{index:03d}_{source.name}"
        if saved.exists():
            if not filecmp.cmp(source, saved, shallow=False):
                raise ValueError(f"Changed mathematical source input: {source}")
        elif path.exists():
            raise ValueError(f"Campaign source snapshot missing: {saved}")
        else:
            shutil.copyfile(source, saved)
    if not path.exists():
        atomic_json(path, spec)


class Campaign:
    def __init__(self, spec):
        validate(spec)
        self.spec = spec
        self.root = Path(spec["RepositoryRoot"])
        self.output = Path(spec["OutputDirectory"])
        self.scratch = Path(spec["ScratchDirectory"])
        self.pool = Path(spec["PoolDirectory"])
        self.output.mkdir(parents=True, exist_ok=True)
        self.scratch.mkdir(parents=True, exist_ok=True)
        self.lock = (self.output / "campaign.lock").open("a")
        try:
            fcntl.flock(self.lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            ensure_inputs(spec, self.output)
        except BaseException:
            self.lock.close()
            raise
        self.path = self.output / "campaign.json"
        self.state = json.loads(self.path.read_text()) if self.path.exists() else {
            "DataType": "ExplicitFamilySolutionCampaign", "StartedUnixTime": time.time(),
            "RunID": uuid.uuid4().hex[:10], "Families": {
                f["Family"]: {"Status": "Pending", "Phase": "DifferentialSystem", "Attempts": []}
                for f in spec["Families"]}}
        self.by_name = {f["Family"]: f for f in spec["Families"]}
        self.save()

    def save(self):
        self.state["UpdatedUnixTime"] = time.time()
        self.state["CoordinatorPID"] = os.getpid()
        statuses = [r["Status"] for r in self.state["Families"].values()]
        self.state["Status"] = ("Completed" if all(s in COMPLETE for s in statuses) else
            "FinishedWithUnresolvedFamilies" if all(s in TERMINAL for s in statuses) else "Running")
        self.state["CompletedFamilyCount"] = sum(s in COMPLETE for s in statuses)
        self.state["IncompleteFamilyCount"] = statuses.count("Incomplete")
        self.state["FullCanonicalizationClaimed"] = False
        self.state["PhysicalNNLOCoverageInferred"] = False
        atomic_json(self.path, self.state)

    def paths(self, name):
        out = self.output / name
        return out, out / "FamilyDifferentialSystem.wl", out / "FiniteSolution"

    def make_script(self, name, phase, attempt):
        family = self.by_name[name]
        out, data, finite = self.paths(name)
        out.mkdir(parents=True, exist_ok=True)
        work = self.scratch / name / f"{phase}-{attempt}"
        work.mkdir(parents=True, exist_ok=True)
        if phase == "DifferentialSystem":
            arguments = ["--repository-root", str(self.root), *self.spec["DifferentialSystemArguments"],
                         "--family", name, "--scratch", str(work / "kira"),
                         "--output", str(data), "--kira-threads", "1"]
            # Call the library directly: the CLI's final Print is not an artifact.
            script = work / "build.wls"
            script.write_text(
                'Get[' + wl_string(self.root / "Scripts/DifferentialEquations/FamilyDifferentialSystemV2.wl") + '];\n'
                'Block[{Print},Get[' + wl_string(self.root / "Addon/Load/LoadFACET.wl") + ']];\n'
                'campaignStarted=AbsoluteTime[];\n'
                'campaignParsed=FeynFacetCampaign§DifferentialEquations§ParseFamilyDifferentialSystemCLIArguments['
                + wl(arguments) + '];\n'
                'campaignResult=TimeConstrained[FeynFacetCampaign§DifferentialEquations§BuildFamilyDifferentialSystemV2[campaignParsed],'
                + str(self.spec.get("DifferentialSystemTimeLimitSeconds", 900)) + ',$TimedOut];\n'
                'campaignValid=AssociationQ[campaignResult] && '
                'FeynFacetCampaign§DifferentialEquations§FamilyDifferentialSystemV2Q[Lookup[campaignResult,"FamilyDifferentialSystem",<||>]];\n'
                'campaignSummary=<|"Status"->If[TrueQ[campaignValid],"Completed","Incomplete"],'
                '"Family"->' + wl_string(name) + ',"Seconds"->N[AbsoluteTime[]-campaignStarted],'
                '"Dimension"->If[TrueQ[campaignValid],Length[campaignResult["FamilyDifferentialSystem","OriginalMasterIntegralBasis"]],0],'
                '"Detail"->If[TrueQ[campaignValid],"",StringTake[ToString[campaignResult,InputForm],UpTo[1500]]]|>;\n'
                'Export[' + wl_string(str(out / "de-summary.json") + ".tmp") + ',campaignSummary,"RawJSON"];\n'
                'RenameFile[' + wl_string(str(out / "de-summary.json") + ".tmp") + ','
                + wl_string(out / "de-summary.json") + ',OverwriteTarget->True];\n'
                'Print[campaignSummary];If[!TrueQ[campaignValid],Exit[2]];\n')
            script.write_text(script.read_text().replace("§", chr(96)))
            return script
        finite_spec = {
            "Family": name, "DataFile": str(data), "OrderRequirementsFile": self.spec["OrderRequirementsFile"],
            "TimeLimitSeconds": self.spec.get("FiniteSolutionTimeLimitSeconds", 900),
            "Options": self.spec.get("FiniteSolutionOptions", {"Verbose": True})}
        for key in ("FiniteIntegrationPreparationFile", "DimensionalRecurrenceFile"):
            if key in family:
                finite_spec[key] = family[key]
        spec_text = wl(finite_spec)
        if "RequestOptionsFile" in family:
            spec_text = spec_text[:-2] + ',"RequestOptions"->Get[' + wl_string(family["RequestOptionsFile"]) + ']|>'
        spec_file = work / "finite-specification.wl"
        spec_file.write_text(spec_text + "\n")
        script = work / "solve.wls"
        script.write_text(
            'Block[{$ScriptCommandLine={"solve",' + wl_string(spec_file) + ',' + wl_string(finite) + '}},Get['
            + wl_string(self.root / "Scripts/Transport/solve_family_from_coefficient_orders.wls") + ']];\n')
        return script

    def mission_location(self, mission):
        for folder, extension in (("done", ".status"), ("failed", ".status"),
                                  ("running", ".wl"), ("queue", ".wl")):
            if (self.pool / folder / (mission + extension)).exists():
                return folder
        return None

    def start(self, name, record):
        phase = record["Phase"]
        mission = record.get("Mission")
        if not mission:
            attempt = len(record["Attempts"]) + 1
            mission = f"fresh_{self.state['RunID']}_{name}_{phase}_{attempt}"
            record.update(Mission=mission, Status="Submitting", SubmittedUnixTime=time.time(),
                          Script=str(self.make_script(name, phase, attempt)))
            record["Attempts"].append({"Mission": mission, "Phase": phase, "SubmittedUnixTime": time.time()})
            self.save()
        if self.mission_location(mission) is None:
            env = dict(os.environ, POOL=str(self.pool), FACET_RESOURCE_ROLE="family",
                       FACET_RESOURCE_GROUP=f"{self.state['RunID']}_{name}",
                       FACET_TASK_BROKER_MAX_HELPERS="0")
            subprocess.run([str(self.root / "Scripts/kpsubmit.sh"), mission, record["Script"]],
                           env=env, check=True, stdout=subprocess.DEVNULL)
        record["Status"] = "Running"
        self.save()

    def check(self, name, record):
        location = self.mission_location(record["Mission"])
        if location not in ("done", "failed"):
            if location is None:
                record.update(Status="Incomplete", Reason="SubmittedMissionMissing")
                self.save()
            return
        out, data, finite = self.paths(name)
        summary_path = out / "de-summary.json" if record["Phase"] == "DifferentialSystem" else finite / "summary.json"
        try:
            summary = json.loads(summary_path.read_text()) if summary_path.exists() else {}
        except (OSError, ValueError):
            summary = {"Status": "UnreadableSummary", "Path": str(summary_path)}
        required_artifact = data if record["Phase"] == "DifferentialSystem" else finite / "solution.wxf"
        record["Attempts"][-1].update(FinishedUnixTime=time.time(), PoolResult=location, Summary=summary)
        if summary.get("Status") not in COMPLETE or (
                summary.get("Status") != "NotRequiredByCoefficientOrders" and not required_artifact.is_file()):
            record.update(Status="Incomplete", Reason="PhaseDidNotProduceCompleteMathematicalArtifact")
        elif record["Phase"] == "DifferentialSystem":
            record.update(Status="Pending", Phase="FiniteSolution")
            record.pop("Mission", None)
            record.pop("Script", None)
        else:
            record.update(Status="Completed", Summary=summary, FinishedUnixTime=time.time())
        self.save()

    def tick(self):
        for name, record in self.state["Families"].items():
            if record["Status"] == "Running":
                self.check(name, record)
            elif record["Status"] == "Submitting":
                self.start(name, record)
        active = sum(r["Status"] in {"Running", "Submitting"} for r in self.state["Families"].values())
        for name, record in self.state["Families"].items():
            if active >= self.spec.get("MaximumConcurrentFamilies", 6):
                break
            if record["Status"] == "Pending":
                self.start(name, record)
                active += 1
        self.save()
        return self.state["Status"] == "Running"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("specification", type=Path)
    parser.add_argument("--once", action="store_true", help="Perform one scheduling update")
    parser.add_argument("--retry-incomplete", action="store_true",
                        help="Retry unresolved phases with unchanged inputs and fresh DE work directories")
    args = parser.parse_args()
    campaign = Campaign(json.loads(args.specification.read_text()))
    if args.retry_incomplete:
        for record in campaign.state["Families"].values():
            if record["Status"] == "Incomplete":
                record["Status"] = "Pending"
                record.pop("Mission", None)
                record.pop("Script", None)
                record.pop("Reason", None)
        campaign.save()
    while campaign.tick() and not args.once:
        time.sleep(5)
    print(json.dumps({k: campaign.state[k] for k in
        ("Status", "CompletedFamilyCount", "IncompleteFamilyCount", "StartedUnixTime", "UpdatedUnixTime")}))
    return 0 if args.once or campaign.state["Status"] == "Completed" else 2


if __name__ == "__main__":
    raise SystemExit(main())
