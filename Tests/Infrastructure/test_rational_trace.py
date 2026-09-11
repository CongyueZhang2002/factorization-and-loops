import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "check_rational_trace", ROOT / "Scripts/Validation/check_rational_trace.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RationalTraceTests(unittest.TestCase):
    def test_small_modulus_is_rejected_before_native_execution(self):
        request = {"Samples": [{"Prime": 1000000007, "Values": {"x": 1}}],
                   "OutputNameMap": {"a": "b"}}
        with self.assertRaisesRegex(ValueError, "between 2"):
            module.validate_request(request)

    def test_large_composite_modulus_is_rejected(self):
        request = {"Samples": [{"Prime": (1 << 63)-1, "Values": {"x": 1}}],
                   "OutputNameMap": {"a": "b"}}
        with self.assertRaises(ValueError):
            module.validate_request(request)

    def test_reader_preserves_full_output_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory)/"values.txt"
            file.write_text("/a with spaces/output =\n  123;\n/b/output =\n  456;\n")
            self.assertEqual(module.read_values(file),
                             {"/a with spaces/output": 123, "/b/output": 456})

    def test_reader_rejects_partial_and_duplicate_results(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory)/"values.txt"
            for text in ["", "a =\n  1;\ntruncated", "a =\n  1;\na =\n  2;\n"]:
                file.write_text(text)
                with self.subTest(text=text), self.assertRaises(ValueError):
                    module.read_values(file)


if __name__ == "__main__":
    unittest.main()
