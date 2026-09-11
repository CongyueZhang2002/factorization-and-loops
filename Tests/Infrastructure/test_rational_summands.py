import importlib.util
import io
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "rational_summands", ROOT / "FeynFacet/Backends/rational_summands.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RationalSummandsTests(unittest.TestCase):
    def test_parenthesized_factors_and_nested_additions(self):
        expression = b"(x+(y+1))*(1/(x+2))+(x^2-y)*(2/(y+3))"
        expected = [b"(x+(y+1))*(1/(x+2))", b"(x^2-y)*(2/(y+3))"]
        for chunk_size in [1, 2, 7, 32, 1024]:
            self.assertEqual(list(module.summands(io.BytesIO(expression), chunk_size)), expected)

    def test_single_term_and_whitespace(self):
        self.assertEqual(list(module.summands(io.BytesIO(b"  (x+1)/(x-1)\n"))),
                         [b"(x+1)/(x-1)"])

    def test_invalid_structure(self):
        for expression in [b"", b"(x", b"x)", b"x++y", b"x+"]:
            with self.subTest(expression=expression), self.assertRaises(ValueError):
                list(module.summands(io.BytesIO(expression), 1))

    def test_original_and_existing_destination_survive_failed_split(self):
        with tempfile.TemporaryDirectory() as directory:
            source, destination = (Path(directory)/name for name in ("source", "destination"))
            source.write_bytes(b"(x+1)+(broken")
            destination.write_bytes(b"retained")
            with self.assertRaises(ValueError):
                module.split_file(source, destination)
            self.assertEqual(source.read_bytes(), b"(x+1)+(broken")
            self.assertEqual(destination.read_bytes(), b"retained")
            self.assertFalse(Path(str(destination)+".partial").exists())

    def test_successful_file_contains_one_summand_per_line(self):
        with tempfile.TemporaryDirectory() as directory:
            source, destination = (Path(directory)/name for name in ("source", "destination"))
            source.write_bytes(b"(x+1) *(1/(x+1))+(x^2-1)/(x+1)\n")
            self.assertEqual(module.split_file(source, destination), 2)
            self.assertEqual(destination.read_bytes(),
                             b"(x+1)*(1/(x+1))\n(x^2-1)/(x+1)\n")

    def test_no_in_place_operation(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)/"source"
            source.write_bytes(b"x+y")
            with self.assertRaises(ValueError):
                module.split_file(source, source)
            self.assertEqual(source.read_bytes(), b"x+y")


if __name__ == "__main__":
    unittest.main()
