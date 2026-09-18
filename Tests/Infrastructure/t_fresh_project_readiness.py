"""Exercise fresh NNLO readiness with supervised-stage calls replaced by stubs."""
import importlib.util
import json
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

repo = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo / "Scripts"))
spec = importlib.util.spec_from_file_location("fresh_projects_test_module", repo / "Scripts/run_fresh_projects.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    project = root / "Projects" / "Example"
    project.mkdir(parents=True)
    (project / "Common-Card.wl").write_text("<||>")
    (root / "Scripts").mkdir()
    upstream = project / "Work" / "upstream.json"
    upstream_data = {"FinalAssemblyReady": False, "Remaining": ["EndpointProfiles"],
        "Stages": [{"Name": "MasterSolution", "Driver": "Scripts/solve.wls",
                    "Arguments": [], "Completion": "COMPLETED", "Log": "Raw/NNLO/q-q/DoubleReal/Work/solve.log"}]}
    manifest = root / "campaign.json"
    manifest.write_text(json.dumps({"CpuSet": [0], "Report": "report.json",
        "Projects": [{"Project": "Example", "Orders": ["NNLO"], "Upstream": str(upstream)}]}))
    calls = []
    def stage(script, arguments, **options):
        calls.append(Path(script).name)
        if Path(script).name == "prepare_project_upstream.wls":
            upstream.parent.mkdir(parents=True, exist_ok=True)
            upstream.write_text(json.dumps(upstream_data))
        return {"Passed": True, "Seconds": 0.01, "ReturnCode": 0}
    with patch.object(module, "ROOT", root), patch.object(module, "select_cpus", lambda requested: [0]), \
         patch.object(module, "run_wolfram", stage), patch.object(sys, "argv", ["run_fresh_projects.py", str(manifest)]):
        assert module.main() == 1
    assert calls == ["prepare_project_upstream.wls", "solve.wls"], calls
    old_master = project / "Raw" / "NNLO" / "q-q" / "DoubleReal" / "Work" / "MasterValues.wxf"
    old_master.parent.mkdir(parents=True, exist_ok=True)
    old_master.write_bytes(b"old generated master")
    try:
        module.require_cleared_order(project, "NNLO")
    except ValueError:
        pass
    else:
        raise AssertionError("A saved master without Results.wl was accepted as fresh.")
    report = json.loads((root / "report.json").read_text())
    assert report["Completed"][-1]["Status"] == "IncompleteUpstreamProduction"
    assert report["Completed"][-1]["Remaining"] == ["EndpointProfiles"]
with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    project = root / "Projects" / "Example"
    project.mkdir(parents=True)
    (project / "Common-Card.wl").write_text("<||>")
    (root / "Scripts").mkdir()
    upstream = project / "Work" / "upstream.json"
    manifest = root / "campaign.json"
    manifest.write_text(json.dumps({"CpuSet": [0], "Report": "report.json",
        "Projects": [{"Project": "Example", "Orders": ["NNLO"], "Upstream": str(upstream)}]}))
    received = []
    def stage(script, arguments, **options):
        if Path(script).name == "prepare_project_upstream.wls":
            upstream.parent.mkdir(parents=True)
            upstream.write_text(json.dumps({"FinalAssemblyReady": True, "Stages": [
                {"Name": "First", "Driver": "Scripts/solve.wls", "Arguments": [],
                 "Completion": "COMPLETED", "Log": "Raw/NNLO/q-q/DoubleReal/Work/first.log"},
                {"Name": "Second", "Driver": "Scripts/solve.wls", "Arguments": [],
                 "Completion": "COMPLETED", "Log": "Raw/NNLO/q-g/DoubleReal/Work/second.log"}]}))
        elif Path(script).name == "run_project_order.wls":
            received.append(json.loads(Path(arguments[3]).read_text()))
            target = project / "Results" / "NNLO" / "Timing.json"
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps({"Seconds": 0.01}))
        return {"Passed": True, "Seconds": 0.01, "ReturnCode": 0}
    with patch.object(module, "ROOT", root), patch.object(module, "select_cpus", lambda requested: [0]), \
         patch.object(module, "run_wolfram", stage), patch.object(sys, "argv", ["run_fresh_projects.py", str(manifest)]):
        assert module.main() == 0
    assert received[0]["UpstreamSecondsByOwnerChannel"] == {"q-q": 0.01, "q-g": 0.01}
    assert received[0]["UpstreamPlanningSeconds"] == 0.01
    timing = json.loads((project / "Results/NNLO/Timing.json").read_text())
    assert timing["Fresh"] and timing["WallSeconds"] >= 0
    assert timing["AssemblyExecutionWallSeconds"] == 0.01
    with patch.object(module, "ROOT", root), patch.object(module, "select_cpus", lambda requested: [0]), \
         patch.object(module, "run_wolfram", stage), patch.object(sys, "argv",
         ["run_fresh_projects.py", str(manifest), "--resume", "--rerun-from", "Example", "NNLO", "First",
          "--reason", "Downstream validation found an incomplete basis map."]):
        assert module.main() == 0
    timing = json.loads((project / "Results/NNLO/Timing.json").read_text())
    report = json.loads((root / "report.json").read_text())
    assert sum(row.get("Invalidated", False) for row in report["Completed"]) == 3
    assert abs(timing["DiscardedAttemptSeconds"] - 0.03) < 1e-10
    assert abs(timing["SuccessfulExecutionSeconds"] - 0.04) < 1e-10
    assert abs(timing["MeasuredExecutionSeconds"] - 0.07) < 1e-10
    assert len(received) == 2 and "WallSeconds" not in timing

with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    project = root / "Projects" / "Example"
    project.mkdir(parents=True)
    card = project / "Common-Card.wl"
    card.write_text("<||>")
    (root / "Scripts").mkdir()
    upstream = project / "Work" / "upstream.json"
    manifest = root / "campaign.json"
    manifest.write_text(json.dumps({"CpuSet": [0], "Report": "report.json",
        "Projects": [{"Project": "Example", "Orders": ["NNLO"], "Upstream": str(upstream)}]}))
    calls = []
    failure = [True]
    def stage(script, arguments, **options):
        name = Path(script).name
        calls.append(name)
        if name == "prepare_project_upstream.wls":
            upstream.parent.mkdir(parents=True)
            upstream.write_text(json.dumps({"FinalAssemblyReady": True, "Stages": [
                {"Name": "First", "Driver": "Scripts/first.wls", "Arguments": [],
                 "Completion": "COMPLETED", "Log": "Raw/NNLO/q-q/DoubleReal/Work/first.log"},
                {"Name": "Second", "Driver": "Scripts/second.wls", "Arguments": [],
                 "Completion": "COMPLETED", "Log": "Raw/NNLO/q-q/DoubleReal/Work/second.log"}]}))
        elif name == "second.wls" and failure[0]:
            failure[0] = False
            return {"Passed": False, "Seconds": 2.0, "ReturnCode": 1}
        elif name == "run_project_order.wls":
            target = project / "Results/NNLO/Timing.json"
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps({"Seconds": 0.2}))
        return {"Passed": True, "Seconds": 1.0, "ReturnCode": 0}
    with patch.object(module, "ROOT", root), patch.object(module, "select_cpus", lambda requested: [0]), \
         patch.object(module, "run_wolfram", stage):
        with patch.object(sys, "argv", ["run_fresh_projects.py", str(manifest)]):
            assert module.main() == 1
        card.write_text("<|Changed->True|>")
        with patch.object(sys, "argv", ["run_fresh_projects.py", str(manifest), "--resume"]):
            try:
                module.main()
            except ValueError as error:
                assert "unchanged recorded cards" in str(error)
            else:
                raise AssertionError("Changed cards accepted for continuation.")
        card.write_text("<||>")
        with patch.object(sys, "argv", ["run_fresh_projects.py", str(manifest), "--resume"]):
            assert module.main() == 0
    assert calls == ["prepare_project_upstream.wls", "first.wls", "second.wls",
                     "second.wls", "run_project_order.wls"], calls
    timing = json.loads((project / "Results/NNLO/Timing.json").read_text())
    assert "WallSeconds" not in timing
    assert timing["Resumed"] and timing["TimingKind"] == "AccumulatedStageExecution"
    assert timing["SuccessfulExecutionSeconds"] == 4.0
    assert timing["FailedAttemptSeconds"] == 2.0
    assert timing["MeasuredExecutionSeconds"] == 6.0
    report = json.loads((root / "report.json").read_text())
    assert len(report["Completed"]) == 5 and report["AccumulatedExecutionSeconds"] == 6.0
print("FRESH NNLO READINESS, RESUME AND TIMING TESTS PASSED")
