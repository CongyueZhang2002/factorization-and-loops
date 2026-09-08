#!/usr/bin/env python3
"""Focused lexical test for the CF303 pre-final mixed-basis A extractor."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import tempfile

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "cf303_extract_pre_final_block_a_target_rows.py"


def main() -> int:
    spec = importlib.util.spec_from_file_location("cf303_extract_pre_final_a", SCRIPT)
    assert spec is not None and spec.loader is not None
    extractor = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = extractor
    spec.loader.exec_module(extractor)
    source = r'''<|"Sector" -> 24, "A" -> {
      {{a11, f[1, {2, 3}], a13}, {a21, a22, a23}, {a31, a32, a33}},
      {{b11, b12, b13}, {b21, g["comma,inside"], b23}, {b31, b32, b33}}},
      "Ranges" -> {{1}, {2, 3}}, "Blocks" -> {{3}, {1, 2}}|>'''
    with tempfile.TemporaryDirectory(prefix="cf303-pre-final-a-test-") as raw:
        directory = Path(raw)
        state, output = directory / "state.wl", directory / "slice.wl"
        state.write_text(source)
        metrics = extractor.extract(state, output, [2, 1], [3, 2])
        actual = output.read_text()
        mismatched = directory / "mismatched.wl"
        mismatched.write_text(source.replace(
            '"Blocks" -> {{3}, {1, 2}}',
            '"Blocks" -> {{3, 1}, {2}}',
        ))
        try:
            extractor.extract(mismatched, output, [2, 1], [3, 2])
            mismatched_refused = False
        except extractor.PreFinalBlockAExtractionError:
            mismatched_refused = True
        duplicate = directory / "duplicate.wl"
        duplicate.write_text(source.replace(
            '"Blocks" -> {{3}, {1, 2}}',
            '"Blocks" -> {{3}, {1, 1}}',
        ))
        try:
            extractor.extract(duplicate, output, [2, 1], [3, 2])
            duplicate_refused = False
        except extractor.PreFinalBlockAExtractionError:
            duplicate_refused = True
    assertions = {
        "two directions retained": metrics["Directions"] == 2,
        "selected dimensions reported":
            metrics["Rows"] == 2 and metrics["Columns"] == 2,
        "physical request order determines state slice order":
            '"RequestedRowPhysicalMasterIntegralIDs" -> {2, 1}' in actual and
            '"RequestedColumnPhysicalMasterIntegralIDs" -> {3, 2}' in actual and
            '"DerivedStateRows" -> {3, 2}' in actual and
            '"DerivedStateColumns" -> {1, 3}' in actual,
        "first direction is byte-faithful in requested order":
            "{{a31, a33}, {a21, a23}}" in actual,
        "second direction is byte-faithful in requested order":
            "{{b31, b33}, {b21, b23}}" in actual,
        "basis metadata retained":
            '"Ranges" -> {{1}, {2, 3}}' in actual and
            '"Blocks" -> {{3}, {1, 2}}' in actual,
        "bijection and order validation are explicit":
            '"RangesBlocksMappingIsBijective" -> True' in actual and
            '"RequestedPhysicalMasterIntegralOrderPreserved" -> True'
            in actual,
        "mismatched paired block dimensions refuse": mismatched_refused,
        "duplicate physical master IDs refuse": duplicate_refused,
        "pre-final mixed-basis type explicit":
            '"DataType" -> "CF303PreFinalBlockBasisConnectionTargetRowSlice"'
            in actual and '"Sector" -> 24' in actual,
    }
    for name, passed in assertions.items():
        print(("OK   " if passed else "FAIL ") + name)
    return 0 if all(assertions.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
