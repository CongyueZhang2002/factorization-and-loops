#!/usr/bin/env python3
"""Exercise family continuation, exact-input reuse, and changed-input refusal."""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
DRIVER = ROOT / "Scripts/Transport/solve_master_integral_families.wls"
SYSTEM = """<|"KinematicVariables"->{Global`xx},"DimensionalRegulator"->Global`ee,
 "Topology"->FeynCalc`FCTopology[batchFamily,
  {FeynCalc`SFAD[{Global`kl,Global`xx}]},{Global`kl},{},{},{}],
 "OriginalMasterIntegralBasis"->{FeynCalc`GLI[batchFamily,{2}]},
 "ConnectionMatrices"->{{{-Global`ee/Global`xx}}}|>"""


def specification(upper=0):
    return ('<|"Data"->' + SYSTEM +
            ',"Request"-><|"BasePoint"->{1/2},'
            '"RequestedMasterIntegralOrderRanges"-><|1->{-1,' +
            str(upper) + '}|>|>|>')


class MasterSolutionBatchTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="feynfacet-batch-")
        self.directory = pathlib.Path(self.temporary.name)
        self.addCleanup(self.temporary.cleanup)
        self.input_file = self.directory / "input.wl"
        self.output = self.directory / "results"

    def run_batch(self, entries):
        self.input_file.write_text('<|"Families"-><|' + entries + '|>|>')
        return subprocess.run(
            ["/usr/local/bin/wolframscript", "-file", str(DRIVER),
             str(self.input_file), str(self.output)],
            cwd=ROOT, text=True, capture_output=True, timeout=90)

    def test_all_completed_families_are_reused(self):
        entries = '"first"->' + specification() + ',"second"->' + specification()
        first = self.run_batch(entries)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        paths = [self.output / name / "solution.wxf" for name in ("first", "second")]
        times = [p.stat().st_mtime_ns for p in paths]
        resumed = self.run_batch(entries)
        self.assertEqual(resumed.returncode, 0, resumed.stdout + resumed.stderr)
        self.assertEqual(resumed.stdout.count("ReusedCompletedResult -> True"), 2)
        self.assertEqual([p.stat().st_mtime_ns for p in paths], times)
        self.assertTrue((self.output / "report.wxf").exists())

    def test_changed_input_preserves_the_old_solution(self):
        first = self.run_batch('"first"->' + specification())
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        path = self.output / "first" / "solution.wxf"
        before = path.read_bytes()
        changed = self.run_batch('"first"->' + specification(1))
        self.assertEqual(changed.returncode, 1, changed.stdout + changed.stderr)
        self.assertIn("ExistingSolutionInputMismatch", changed.stdout)
        self.assertEqual(path.read_bytes(), before)

    def test_a_failure_does_not_skip_later_families(self):
        result = self.run_batch('"invalid"-><||>,"valid"->' + specification())
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("MasterIntegralRangeRequestRequired", result.stdout)
        self.assertIn("valid <|Status -> Completed", result.stdout)
        self.assertFalse((self.output / "invalid" / "solution.wxf").exists())
        self.assertTrue((self.output / "valid" / "solution.wxf").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
