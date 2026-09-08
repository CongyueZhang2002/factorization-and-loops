#!/usr/bin/env python3
"""Resuming the full audit must preserve passes without accepting stale failures."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / "Scripts/Validation"))
import run_complete_master_validation as driver
import family_pool

class ResumeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.output = self.directory / "validation"
        self.output.mkdir()
        self.masters = [dict(Family=f"F{i}", Row=1, MasterIntegral=f"j(F{i})", RequiredOrders=[-1, 0]) for i in [1, 2]]
        families = []
        for i in [1, 2]:
            solution = self.directory / "solutions" / f"F{i}" / "solution.wxf"
            solution.parent.mkdir(parents=True)
            solution.write_text("input")
            folder = self.output / f"F{i}"
            folder.mkdir()
            request = folder / "request.wxf"
            request.write_text("request")
            families.append(dict(ID=f"F{i}", SolutionFile=str(solution), RequestFile=str(request), OutputDirectory=str(folder)))
        self.spec = dict(RepositoryRoot=str(root), SolutionCampaignDirectory=str(self.directory / "solutions"),
                         Threads=2, RequiredCoefficientCount=4, Families=families, MasterIntegrals=self.masters)
        self.manifest = self.output / "complete_masters.json"
        self.manifest.write_text(json.dumps(self.spec))
        self.old = [dict(m, Status="Passed" if m["Family"] == "F1" else "NotChecked",
                         PassedCoefficientCount=2 if m["Family"] == "F1" else 0) for m in self.masters]
        (self.output / "complete_master_report.json").write_text(json.dumps(dict(MasterIntegrals=self.old)))
        self.summary("F1")

    def summary(self, family, count=2):
        record = dict(Row=1, Status="Passed", RequiredOrders=[-1, 0], PassedCoefficientCount=count)
        (self.output / family / "comparison.wxf.json").write_text(json.dumps(dict(Family=family, Status="Passed", Results=[record])))

    def run_driver(self, callback):
        with patch.object(sys, "argv", ["driver", str(self.manifest), "--workers", "2", "--resume"]), \
             patch.object(family_pool, "run_family_pool", side_effect=callback), \
             patch.object(driver.os, "sched_getaffinity", return_value={0, 1}), \
             patch.object(driver.os, "sched_setaffinity"):
            return driver.main()

    def test_resume_only_unfinished_family(self):
        def pool(root, output, families, workers, timeout, progress):
            self.assertEqual([f["ID"] for f in families], ["F2"])
            self.summary("F2")
            progress(["F2"], ("F2", "Compared"))
            return 0
        self.assertEqual(self.run_driver(pool), 0)
        report = json.loads((self.output / "complete_master_report.json").read_text())
        self.assertEqual((report["PassedMasterCount"], report["PassedCoefficientCount"]), (2, 4))

    def test_missing_coefficient_cannot_pass(self):
        def pool(root, output, families, workers, timeout, progress):
            self.summary("F2", count=1)
            progress([], ("F2", "Compared"))
            return 0
        self.assertEqual(self.run_driver(pool), 1)

    def test_worker_failure_cannot_reuse_stale_comparison(self):
        def pool(root, output, families, workers, timeout, progress):
            self.summary("F2")
            progress([], ("F2", "WorkerFailed"))
            return 1
        self.assertEqual(self.run_driver(pool), 1)
        report = json.loads((self.output / "complete_master_report.json").read_text())
        self.assertEqual(report["MasterIntegrals"][1]["Status"], "EvaluationFailed")

    def test_changed_inventory_is_rejected(self):
        self.old[0]["RequiredOrders"] = [0]
        (self.output / "complete_master_report.json").write_text(json.dumps(dict(MasterIntegrals=self.old)))
        with self.assertRaises(SystemExit) as failure:
            self.run_driver(lambda *args: 0)
        self.assertEqual(failure.exception.code, 2)

if __name__ == "__main__":
    unittest.main()
