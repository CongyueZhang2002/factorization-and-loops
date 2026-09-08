#!/usr/bin/env python3
"""Execution controls for immutable inputs and independent family progress."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[2] / "Scripts/Transport/run_family_solution_campaign.py"
loader = importlib.util.spec_from_file_location("family_campaign", MODULE)
campaign = importlib.util.module_from_spec(loader)
loader.loader.exec_module(campaign)


class CampaignExecution(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.base = Path(self.tmp.name)
        self.source = self.base / "orders.wl"
        self.source.write_text("explicit orders")
        self.pool = self.base / "pool"
        for part in ("queue", "running", "done", "failed"):
            (self.pool / part).mkdir(parents=True)
        self.spec = {
            "RepositoryRoot": str(self.base), "PoolDirectory": str(self.pool),
            "OutputDirectory": str(self.base / "output"),
            "ScratchDirectory": str(self.base / "scratch"),
            "OrderRequirementsFile": str(self.source), "SourceFiles": [str(self.source)],
            "DifferentialSystemArguments": [], "MaximumConcurrentFamilies": 2,
            "Families": [{"Family": "FamilyA"}, {"Family": "FamilyB"}, {"Family": "FamilyC"}]}
        self.jobs = []

    def tearDown(self):
        self.tmp.cleanup()

    def submit(self, arguments, **kwargs):
        name = arguments[1]
        self.jobs.append(name)
        (self.pool / "queue" / (name + ".wl")).write_text("queued")

    def finish(self, name, stage, success):
        record = self.c.state["Families"][name]
        mission = record["Mission"]
        (self.pool / "queue" / (mission + ".wl")).unlink()
        (self.pool / ("done" if success else "failed") / (mission + ".status")).write_text("finished")
        out, data, finite = self.c.paths(name)
        if stage == "DifferentialSystem":
            campaign.atomic_json(out / "de-summary.json", {"Status": "Completed" if success else "Incomplete"})
            if success:
                data.write_text("closed DE")
        else:
            finite.mkdir(parents=True, exist_ok=True)
            campaign.atomic_json(finite / "summary.json", {"Status": "Completed" if success else "Incomplete"})
            if success:
                (finite / "solution.wxf").write_bytes(b"explicit coefficients")

    @patch.object(campaign.subprocess, "run")
    def test_family_failure_does_not_block_independent_families(self, run):
        run.side_effect = self.submit
        self.c = campaign.Campaign(self.spec)
        self.c.tick()
        self.assertEqual(len(self.jobs), 2)
        self.finish("FamilyA", "DifferentialSystem", False)
        self.finish("FamilyB", "DifferentialSystem", True)
        self.c.tick()
        self.assertEqual(self.c.state["Families"]["FamilyA"]["Status"], "Incomplete")
        self.assertEqual(self.c.state["Families"]["FamilyB"]["Phase"], "FiniteSolution")
        self.assertEqual(self.c.state["Families"]["FamilyC"]["Status"], "Running")
        self.assertEqual(len(self.jobs), 4)
        self.finish("FamilyB", "FiniteSolution", True)
        self.c.tick()
        self.assertEqual(self.c.state["Families"]["FamilyB"]["Status"], "Completed")
        self.c.lock.close()

    @patch.object(campaign.subprocess, "run")
    def test_restart_preserves_queued_jobs_without_duplicate_submission(self, run):
        run.side_effect = self.submit
        self.c = campaign.Campaign(self.spec)
        self.c.tick()
        self.c.lock.close()
        self.c = campaign.Campaign(self.spec)
        self.c.tick()
        self.assertEqual(len(self.jobs), 2)
        self.c.lock.close()

    def test_changed_inputs_are_refused_even_with_same_size_and_timestamp(self):
        self.c = campaign.Campaign(self.spec)
        self.c.lock.close()
        original = self.source.stat()
        self.source.write_text("changed  orders")
        import os
        os.utime(self.source, ns=(original.st_atime_ns, original.st_mtime_ns))
        with self.assertRaisesRegex(ValueError, "Changed mathematical source"):
            campaign.Campaign(self.spec)

    @patch.object(campaign.subprocess, "run")
    def test_invalid_phase_summary_does_not_crash_the_coordinator(self, run):
        run.side_effect = self.submit
        self.c = campaign.Campaign(self.spec)
        self.c.tick()
        self.finish("FamilyA", "DifferentialSystem", True)
        (self.c.paths("FamilyA")[0] / "de-summary.json").write_text("")
        self.c.tick()
        self.assertEqual(self.c.state["Families"]["FamilyA"]["Status"], "Incomplete")
        self.assertEqual(self.c.state["Families"]["FamilyC"]["Status"], "Running")
        self.c.lock.close()

    @patch.object(campaign.subprocess, "run")
    def test_done_marker_without_mathematical_artifact_is_incomplete(self, run):
        run.side_effect = self.submit
        self.c = campaign.Campaign(self.spec)
        self.c.tick()
        self.finish("FamilyA", "DifferentialSystem", True)
        self.c.paths("FamilyA")[1].unlink()
        self.c.tick()
        self.assertEqual(self.c.state["Families"]["FamilyA"]["Status"], "Incomplete")
        self.c.lock.close()


if __name__ == "__main__":
    unittest.main()
