#!/usr/bin/env python3
"""Structural smoke for the scratch-only CF303 deferred-circuit adapter.

This never starts Wolfram or Maple and never replays a symbolic identity.  It
checks the exact-leaf layout and D/S support graph, then consumes the two
already accepted 61-bit circuit images as the sole arithmetic evidence.
"""

from __future__ import annotations

import argparse
import ast
import importlib.util
import json
import re
import sys
from fractions import Fraction
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
RUNTIME = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
SCRIPTS = ROOT / "Diagnostics/Scripts"
ADAPTER = SCRIPTS / "cf303_hybrid_baseline_lazy_circuit_adapter.wl"
EVALUATOR = SCRIPTS / "cf303_hybrid_baseline_modular_circuit.py"
ADAPTER_MANIFEST = RUNTIME / "cf303_hybrid_baseline_lazy_adapter_manifest.json"
CIRCUIT_MANIFEST = RUNTIME / "cf303_hybrid_baseline_modular_circuit_manifest.json"
DEFAULT_OUTPUT = RUNTIME / "cf303_hybrid_baseline_lazy_adapter_validation.json"
Q7 = 2_305_843_009_213_693_693


def load_evaluator():
    spec = importlib.util.spec_from_file_location("cf303_adapter_evaluator", EVALUATOR)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load baseline evaluator")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def wolfram_balanced(text: str) -> bool:
    stack: list[str] = []
    pairs = {"(": ")", "[": "]", "{": "}"}
    position = comment_depth = 0
    in_string = escaped = False
    while position < len(text):
        pair = text[position:position + 2]
        character = text[position]
        if comment_depth:
            if pair == "(*":
                comment_depth += 1
                position += 2
                continue
            if pair == "*)":
                comment_depth -= 1
                position += 2
                continue
            position += 1
            continue
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            position += 1
            continue
        if pair == "(*":
            comment_depth = 1
            position += 2
            continue
        if character == '"':
            in_string = True
        elif character in pairs:
            stack.append(pairs[character])
        elif character in pairs.values():
            if not stack or stack.pop() != character:
                return False
        position += 1
    return not stack and not comment_depth and not in_string


def file_edges(path: Path, prefix_bytes=512, suffix_bytes=32768):
    with path.open("rb") as stream:
        prefix = stream.read(prefix_bytes).decode(errors="replace")
        stream.seek(max(0, path.stat().st_size - suffix_bytes))
        suffix = stream.read().decode(errors="replace")
    return prefix, suffix


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    adapter_manifest = json.loads(ADAPTER_MANIFEST.read_text())
    circuit_manifest = json.loads(CIRCUIT_MANIFEST.read_text())
    evaluator = load_evaluator()
    inputs = evaluator.parse_inputs()
    source_rows = tuple(evaluator.SOURCE_ROWS)
    target_rows = tuple(evaluator.TARGET_ROWS)
    zero = evaluator.zero_pair(Q7)
    synthetic_h = {
        order: [[zero for _ in source_rows] for _ in target_rows]
        for order in evaluator.ORDERS
    }
    synthetic_cross = {
        order: [[zero for _ in source_rows] for _ in target_rows]
        for order in evaluator.ORDERS
    }
    synthetic_point = evaluator.adapter_point_payload(
        Fraction(3), synthetic_h, synthetic_cross, {
            "baseline_recurrence_comparisons": 688,
            "baseline_basepoint_comparisons": 688,
            "t25_h_scalar_channel_comparisons": 2408,
            "t25_cross_k_scalar_channel_comparisons": 672,
        },
    )

    entries = inputs["entries"]
    source_entries = inputs["source_entries"]
    exception_targets = tuple(
        tuple(map(int, entry[0])) for entry in source_entries
        if any(component != "0" for component in entry[2])
    )
    declared_exception_targets = tuple(
        tuple(leaf["target"]) for leaf in adapter_manifest["exception_k_leaves"]
    )
    merged_exception_targets = tuple(
        tuple(map(int, entry[0])) for entry in entries[76:88]
    )
    block1_placeholders = entries[88:90]

    edges = {master: set() for master in source_rows}
    for record in inputs["source_forms"]:
        if not any(component != "0" for component in record[2]):
            continue
        row = source_rows[int(record[0]) - 1]
        column = source_rows[int(record[1]) - 1]
        edges[row].add(column)
    support = set(adapter_manifest["support"]["exception_source_masters"])
    while True:
        extended = support | set().union(*(edges[row] for row in support))
        if extended == support:
            break
        support = extended
    declared_support = set(adapter_manifest["support"]["cross_k_source_masters"])

    adapter_text = ADAPTER.read_text()
    ast.parse(EVALUATOR.read_text(), filename=str(EVALUATOR))
    source_text = Path(
        adapter_manifest["exact_leaf_provenance"]["source_operator"]
    ).read_text()
    source_match = re.search(
        r'"OriginalRows"\s*->\s*\{([^}]+)\}', source_text, re.S
    )
    source_artifact_rows = tuple(map(int, re.findall(r"\d+", source_match.group(1))))
    boundary_match = re.search(
        r'"BoundaryProbes".*?"Dimensions"\s*->\s*\{\d+,\s*(\d+)\}',
        source_text, re.S,
    )
    source_boundary_dimension = int(boundary_match.group(1))

    base_prefix, _ = file_edges(Path(
        adapter_manifest["exact_leaf_provenance"]["base_transfer_76"]
    ))
    gauge_text = Path(
        adapter_manifest["exact_leaf_provenance"]["physical_gauge"]
    ).read_text()
    provider_checks = []
    for provider in sorted({leaf["provider"]
                            for leaf in adapter_manifest["exception_k_leaves"]}):
        prefix, suffix = file_edges(Path(provider))
        provider_checks.append(
            'status := "CF303EllipticLayerCensusAcceptedV1"' in prefix
            and "failures := []:" in suffix
        )

    expected_point_data = {
        (3, 1): 49,
        (239, 47): 49,
    }
    point_checks = []
    point_summaries = []
    for path_string in adapter_manifest["accepted_point_evidence"]:
        point = json.loads(Path(path_string).read_text())
        p_key = tuple(point["p"])
        point_ok = (
            point["status"] == "CF303HybridBaselineModularCircuitPointAcceptedV1"
            and point["prime"] == Q7
            and point["baseline_recurrence_comparisons"] == 688
            and point["baseline_basepoint_comparisons"] == 688
            and point["t25_h_scalar_channel_comparisons"] == 2408
            and point["t25_cross_k_scalar_channel_comparisons"] == 672
            and point["nonzero_cross_k_vectors"] == expected_point_data[p_key]
            and point["rational_cross_reductions"] == 98
            and point["elliptic_cross_reductions"] == 0
            and point["cross_nonzero_by_order"] == {
                "-3": 0, "-2": 14, "-1": 14, "0": 14,
                "1": 14, "2": 14, "3": 14, "4": 14,
            }
        )
        point_checks.append(point_ok)
        point_summaries.append({
            "p": point["p"],
            "recurrence": point["baseline_recurrence_comparisons"],
            "basepoint": point["baseline_basepoint_comparisons"],
            "t25": point["t25_scalar_channel_comparisons"],
            "nonzero_cross_k_vectors": point["nonzero_cross_k_vectors"],
        })

    structural = {
        "adapter_wolfram_delimiters_balanced": wolfram_balanced(adapter_text),
        "adapter_defines_builder":
            "cf303BuildHybridBaselineLazyCircuitAdapter[" in adapter_text,
        "adapter_uses_unified_h_head":
            "CF303HybridBaselineH[order, targetMaster, sourceMaster" in
                adapter_text,
        "adapter_has_no_materialized_baseline_gauge_dependency":
            "baselinePathGauge" not in adapter_text
            and "cf303PathGaugeCompileH[" not in adapter_text,
        "evaluator_python_ast_parses": True,
        "evaluator_abi_synthetic_shape": (
            synthetic_point["status"] ==
                "CF303HybridBaselineLazyAdapterPointV1"
            and synthetic_point["h_output_count"] == 112
            and synthetic_point["cross_k_output_count"] == 98
        ),
        "source_rows_match": source_artifact_rows == source_rows,
        "source_boundary_dimension": source_boundary_dimension,
        "final_boundary_dimension": source_boundary_dimension + 6,
        "merged_entry_count": len(entries),
        "merged_incoming_coordinate_count": len(source_entries),
        "base_entry_count": len(entries) - len(declared_exception_targets) - 2,
        "base_status_present":
            "CF303Block25GeneralEllipticTransferAcceptedV1" in base_prefix,
        "exception_primitive_targets": [list(item) for item in exception_targets],
        "exception_targets_match_manifest":
            exception_targets == declared_exception_targets,
        "merged_exception_order_matches_manifest":
            merged_exception_targets == declared_exception_targets,
        "block1_zero_placeholders":
            [list(map(int, entry[0])) for entry in block1_placeholders],
        "block1_placeholders_are_zero": all(
            entry[2] == ["0", "0"] and entry[3] == []
            for entry in block1_placeholders
        ),
        "exception_provider_count": len(provider_checks),
        "exception_providers_accepted": all(provider_checks),
        "source_row1_targets": sorted(edges[1]),
        "source_row1_invariant": edges[1] == {1},
        "source_support_graph_closure": sorted(support),
        "support_graph_matches_manifest": support == declared_support,
        "cross_k_label_order_coordinate_pairs":
            7 * len(target_rows) * len(declared_support),
        "h_sparse_address_count": 8 * len(target_rows) * len(declared_support),
        "physical_gauge_accepted":
            "CF303Block25PhysicalGaugeAcceptedV1" in gauge_text,
        "physical_gauge_orders":
            tuple(map(int, re.search(
                r'"Orders"\s*->\s*\{([^}]+)\}', gauge_text
            ).group(1).split(","))),
    }
    structural_ok = (
        structural["adapter_wolfram_delimiters_balanced"]
        and structural["adapter_defines_builder"]
        and structural["adapter_uses_unified_h_head"]
        and structural["adapter_has_no_materialized_baseline_gauge_dependency"]
        and structural["evaluator_abi_synthetic_shape"]
        and structural["source_rows_match"]
        and structural["final_boundary_dimension"] == 293
        and structural["merged_entry_count"] == 90
        and structural["merged_incoming_coordinate_count"] == 86
        and structural["base_status_present"]
        and structural["exception_targets_match_manifest"]
        and structural["merged_exception_order_matches_manifest"]
        and structural["block1_zero_placeholders"] == [[44, 1], [45, 1]]
        and structural["block1_placeholders_are_zero"]
        and structural["exception_provider_count"] == 4
        and structural["exception_providers_accepted"]
        and structural["source_row1_invariant"]
        and structural["support_graph_matches_manifest"]
        and structural["cross_k_label_order_coordinate_pairs"] == 98
        and structural["h_sparse_address_count"] == 112
        and structural["physical_gauge_accepted"]
        and structural["physical_gauge_orders"] == (0, 1, 2)
    )
    modular_ok = (
        all(point_checks)
        and circuit_manifest["status"] ==
            "CF303HybridBaselineDeferredExactCircuitAcceptedV1"
        and circuit_manifest["acceptance_totals"] == {
            "points": 2,
            "baseline_recurrence_comparisons": 1376,
            "baseline_basepoint_comparisons": 1376,
            "t25_scalar_channel_comparisons": 6160,
            "t25_h_scalar_channel_comparisons": 4816,
            "t25_cross_k_scalar_channel_comparisons": 1344,
        }
    )
    report = {
        "status": (
            "CF303HybridBaselineLazyAdapterAcceptedV1"
            if structural_ok and modular_ok
            else "CF303HybridBaselineLazyAdapterFailedV1"
        ),
        "family": "CF303",
        "adapter": str(ADAPTER),
        "adapter_manifest": str(ADAPTER_MANIFEST),
        "arithmetic_evidence": "two pre-existing q7 point images only",
        "structural": structural,
        "accepted_points": point_summaries,
        "no_wolfram_or_maple_started": True,
        "no_characteristic_zero_h_or_k_matrix_materialized": True,
    }
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({
        "status": report["status"],
        "output": str(args.output),
        "support": structural["source_support_graph_closure"],
    }))
    return 0 if structural_ok and modular_ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
