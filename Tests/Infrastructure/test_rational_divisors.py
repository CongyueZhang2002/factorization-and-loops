import sys
from pathlib import Path
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "FeynFacet/Backends"))
from rational_divisors import term_divisors, inventory, partition_source, verify_partition


class RationalDivisorsTests(unittest.TestCase):
    def test_enclosing_and_divisor_multiplicities(self):
        self.assertEqual(term_divisors("(x/e)^2"), {"e": 2})
        self.assertEqual(term_divisors("((x/e)^2/y)^3"), {"e": 6, "y": 3})
        self.assertEqual(term_divisors("x/(e^2*z)^3"), {"(e^2*z)^3": 1})

    def test_nested_additions_are_conservative(self):
        self.assertEqual(term_divisors("(x/e+y/e)^2"), {"e": 4})

    def test_zero_power_contributes_no_denominator(self):
        self.assertEqual(term_divisors("(x/e)^0"), {})

    def test_rejects_unsupported_powers_and_structure(self):
        for value in ["(x/e)^(2*3)", "(x/e)^1.5", "(x/e)^q", "x^(-1)", "x/", "(x/e", "x/e)"]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                term_divisors(value)

    def test_nested_denominator_retained_for_algebra_validation(self):
        self.assertEqual(term_divisors("x/(y/e)"), {"(y/e)": 1})

    def test_inventory_counts_and_indexes_products(self):
        with tempfile.TemporaryDirectory() as path:
            source = Path(path) / "source"
            source.write_text("(x/e)^2+(y/e)^2+x/z")
            result = inventory(source)
        self.assertEqual(result["Summands"], 3)
        self.assertEqual(result["Divisors"], ["e", "z"])
        self.assertEqual(result["Products"], [
            {"Factors": [(1, 2)], "Count": 2}, {"Factors": [(2, 1)], "Count": 1}])

    def test_partition_preserves_literal_terms(self):
        with tempfile.TemporaryDirectory() as path:
            source = Path(path) / "source"
            source.write_text("x/e+(x+1)/(z+e)+x/z")
            result = partition_source(source, ["(z+e)"], Path(path)/"parts")
            self.assertEqual(Path(result["Parts"]["Regular"]["File"]).read_text(), "x/e+x/z\n")
            self.assertEqual(Path(result["Parts"]["Exact"]["File"]).read_text(), "(x+1)/(z+e)\n")
            self.assertTrue(verify_partition(result))
            self.assertEqual(result["Summands"], 3)
            self.assertEqual(result["Parts"]["Exact"]["Summands"], 1)
            self.assertEqual(source.read_text(), "x/e+(x+1)/(z+e)+x/z")

    def test_all_regular_partition_requires_no_rejected_divisors(self):
        with tempfile.TemporaryDirectory() as path:
            source = Path(path) / "source"
            source.write_text("x/e+x/z")
            result = partition_source(source, [], Path(path)/"parts")
            self.assertEqual(result["Parts"]["Regular"]["Summands"], 2)
            self.assertEqual(result["Parts"]["Exact"]["Summands"], 0)
            self.assertTrue(verify_partition(result))

    def test_partition_tampering_rejected(self):
        with tempfile.TemporaryDirectory() as path:
            source = Path(path) / "source"
            source.write_text("x/e+(x+1)/(z+e)")
            result = partition_source(source, ["(z+e)"], Path(path)/"parts")
            part = Path(result["Parts"]["Regular"]["File"])
            part.write_text("y/e")
            with self.assertRaises(ValueError):
                verify_partition(result)

    def test_empty_partition_is_exact_zero(self):
        with tempfile.TemporaryDirectory() as path:
            source = Path(path) / "source"
            source.write_text("x/e")
            result = partition_source(source, ["(z+e)"], Path(path)/"parts")
            self.assertTrue(verify_partition(result))


if __name__ == "__main__":
    unittest.main()
