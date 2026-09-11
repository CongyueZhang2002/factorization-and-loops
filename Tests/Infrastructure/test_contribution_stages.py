"""Manifest routing keeps generated products under the selected channel."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "Scripts"))
from run_contribution_stages import stage_arguments, job_identity

class ContributionStages(unittest.TestCase):
    def setUp(self):
        self.job = {"Project": "Example", "Order": "NNLO", "Channel": "q-q",
                    "Contribution": "DoubleReal.Gluons",
                    "Execution": {"Kernels": 7, "KiraThreads": 8,
                                  "ReconstructionThreads": 8, "NormalizationKernels": 7}}
        self.owner = "Projects/Example/NNLO/q-q"

    def test_diagrams_use_component_card_and_channel_owned_output(self):
        self.assertEqual(stage_arguments(self.job, "GeneratePairs"),
                         [self.owner, "DoubleReal.Gluons", "DoubleReal/Gluons/Amplitudes", "7"])

    def test_reduction_uses_the_regenerated_amplitudes(self):
        self.assertEqual(stage_arguments(self.job, "ReducePairs"),
                         [self.owner, "DoubleReal/Gluons/Amplitudes",
                          "DoubleReal/Gluons/Reduction", "solve", "8"])

    def test_reconstruction_distinguishes_native_and_kernel_counts(self):
        self.assertEqual(stage_arguments(self.job, "ReconstructCoefficients"),
                         [self.owner, "DoubleReal/Gluons/Reduction", "8", "7"])

    def test_current_stages_keep_card_identity(self):
        self.assertEqual(stage_arguments(self.job, "PrepareSources"),
                         ["Example", "NNLO", "q-q", "DoubleReal.Gluons", "prepare"])
        self.assertEqual(stage_arguments(self.job, "EvaluateCurrent"),
                         ["Example", "NNLO", "q-q", "DoubleReal.Gluons"])

    def test_unsafe_or_empty_card_components_are_rejected(self):
        for field, value in [("Project", ".."), ("Order", "NNLO/other"),
                             ("Channel", "q" + chr(92) + "q"),
                             ("Contribution", "DoubleReal..Gluons"),
                             ("Contribution", ".Gluons"), ("Contribution", "...")]:
            with self.subTest(field=field, value=value):
                with self.assertRaises(ValueError):
                    job_identity({**self.job, field: value})

if __name__ == "__main__":
    unittest.main()
