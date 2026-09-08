#!/usr/bin/env python3
"""Focused controls for the CF303 pre-final mixed-basis connection jet."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import tempfile


HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "cf303_pre_final_block_connection_jet.py"
SPEC = importlib.util.spec_from_file_location(
    "cf303_pre_final_block_connection_jet", SCRIPT
)
assert SPEC is not None and SPEC.loader is not None
jet = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = jet
SPEC.loader.exec_module(jet)


def synthetic_slice() -> str:
    entry_x = (
        "eps^(-2)*(1+2*eps)/"
        "((1+3*eps)*(-1+x+y)^2)"
    )
    row_x = "{" + ",".join([entry_x] * 8) + "}"
    row_zero = "{" + ",".join(["0"] * 8) + "}"
    matrices = "{{" + row_x + "," + row_x + "},{" + \
        row_zero + "," + row_zero + "}}"
    return (
        '<|"DataType" -> '
        '"CF303PreFinalBlockBasisConnectionTargetRowSlice", '
        '"SchemaVersion" -> 2, "Sector" -> 24, '
        '"RequestedRowPhysicalMasterIntegralIDs" -> {5,6}, '
        '"RequestedColumnPhysicalMasterIntegralIDs" -> '
        '{2,12,21,22,29,30,5,6}, '
        '"DerivedStateRows" -> {44,45}, '
        '"DerivedStateColumns" -> {43,15,30,31,21,22,44,45}, '
        '"Ranges" -> {{1},{2},{3},{4},{5},{6},{7,8},{9},{10},{11},'
        '{12},{13,14,15,16},{17,18,19,20},{21,22},{23,24,25},'
        '{26,27},{28},{29,30},{31,32,33,34},{35,36},{37,38},{39},'
        '{40,41},{42,43},{44,45}}, '
        '"Blocks" -> {{7},{39},{35},{26},{44},{9},{14,15},{28},'
        '{31},{45},{8},{10,11,12,13},{16,17,18,19},{29,30},'
        '{32,33,34},{36,37},{38},{20,21},{22,23,24,25},{40,41},'
        '{42,43},{27},{3,4},{1,2},{5,6}}, '
        '"MappingValidation" -> <|'
        '"RangesBlocksMappingIsBijective" -> True, '
        '"RequestedPhysicalMasterIntegralOrderPreserved" -> True|>, '
        '"ConnectionMatrices" -> ' + matrices + '|>\n'
    )


def main() -> int:
    cutoff = 16
    rho = jet.Jet.rho(cutoff)
    one = jet.Jet.constant(1, cutoff)
    singular = rho.multiply(one.add(rho))
    round_trip = singular.multiply(singular.inverse())
    x, y, x_p, _, squares, roots = jet.path_data(cutoff)

    points = list(range(1, 29))
    numerator_expected = [5, 7, 11]
    denominator_expected = [1, 3]
    values = [
        jet.polynomial_evaluate(numerator_expected, point)
        * jet.mod_inverse(
            jet.polynomial_evaluate(denominator_expected, point)
        ) % jet.PRIME
        for point in points
    ]
    numerator, denominator, comparisons = jet.rational_interpolate(
        points[:20], values[:20], points[20:], values[20:]
    )
    rational_replay = all(
        jet.polynomial_evaluate(numerator, point) ==
        value * jet.polynomial_evaluate(denominator, point) % jet.PRIME
        for point, value in zip(points, values)
    )

    with tempfile.TemporaryDirectory(
            prefix="cf303-pre-final-block-jet-test-") as raw:
        directory = Path(raw)
        slice_path = directory / "slice.wl"
        slice_path.write_text(synthetic_slice())
        result = jet.build(
            slice_path=slice_path,
            native=jet.NATIVE,
            native_order=12,
            through=1,
            fit_count=20,
            held_out_count=4,
            clearing_power=8,
            epsilon_shift=16,
            threads=1,
            deadline_seconds=20,
        )
        reordered_path = directory / "reordered-slice.wl"
        reordered_path.write_text(synthetic_slice().replace(
            '"DerivedStateColumns" -> {43,15,30,31,21,22,44,45}',
            '"DerivedStateColumns" -> {15,43,30,31,21,22,44,45}',
        ))
        try:
            jet.slice_data(reordered_path)
            reordered_slice_refused = False
        except jet.ConnectionJetRefusal:
            reordered_slice_refused = True
    first = result["Records"][0]
    reconstructed = {
        (coefficient["RhoPower"], coefficient["EpsilonOrder"]):
            coefficient["Value"]
        for coefficient in first["Coefficients"]
    }
    soft = x.add(y).add(one, -1)
    expected_rho_minus_two = x_p.multiply(
        soft.power(-2)
    ).coefficient(-2)

    source_text = SCRIPT.read_text()
    assertions = {
        "Laurent inverse round trip":
            round_trip.coefficient(0) == 1 and
            all(round_trip.coefficient(order) == 0
                for order in range(1, 8)),
        "three physical-sheet roots square exactly":
            all(not root.multiply(root).add(square, -1).terms
                for root, square in zip(roots, squares)),
        "rational interpolation replays fit and held-outs":
            comparisons == 8 and rational_replay,
        "packed evaluator removes a singular soft clearing factor":
            result["Status"] ==
            "CF303PreFinalBlockBasisConnectionJetFiniteFieldReconstructed",
        "reconstructed Laurent coefficient matches exact fixture":
            reconstructed[(-2, -2)] == expected_rho_minus_two and
            reconstructed[(-2, -1)] ==
            -expected_rho_minus_two % jet.PRIME,
        "demanded epsilon windows are explicit":
            result["DemandedEpsilonOrderWindowsByBlock"] == {
                "TargetFromSource": [-10, 3],
                "TargetFromTarget": [-8, 7],
            },
        "all 32 direction-contracted coordinates reconstructed":
            len(result["Records"]) == 16 and
            result["NativeEvaluation"]["RecordCount"] == 32,
        "physical IDs map to the correct nontrivial state positions":
            result["Basis"]["TargetStateRows"] == [44, 45] and
            result["Basis"]["TargetPhysicalMasterIntegralIDs"] == [5, 6] and
            result["Basis"]["SelectedStateColumns"] ==
            [43, 15, 30, 31, 21, 22, 44, 45] and
            result["Basis"]["SelectedPhysicalMasterIntegralIDs"] ==
            [2, 12, 21, 22, 29, 30, 5, 6],
        "record carries state and physical coordinates":
            first["TargetStateRow"] == 44 and
            first["TargetPhysicalMasterIntegralID"] == 5 and
            first["StateColumn"] == 43 and
            first["PhysicalMasterIntegralID"] == 2,
        "mapping validation is fail-closed and retained":
            result["Validation"]["Conditions"]
                  ["RangesBlocksMappingIsBijective"] is True and
            result["Validation"]["Conditions"]
                  ["RequestedPhysicalMasterIntegralOrderPreserved"] is True,
        "state-column reordering against physical request refuses":
            reordered_slice_refused,
        "basis vocabulary is mathematical and pre-final":
            "gauge" not in source_text.lower() and
            result["Basis"]["OrderedAmbientBasis"] ==
            "(G_source,F25)",
    }
    for name, passed in assertions.items():
        print(("OK   " if passed else "FAIL ") + name)
    return 0 if all(assertions.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
