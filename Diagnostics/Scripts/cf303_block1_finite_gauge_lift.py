#!/usr/bin/env python3
"""Lift post-gauge CF303 block-1 p profiles over Q using q1--q5/q6."""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path


ROOT = Path("/home/maxzhang/factorization-and-loops-codex")
OUT = ROOT / "Runtime/2026-08-31_cf303_native_dlog_residues"
SOURCE = OUT / "block1_modular_finite_gauge_record2"
EXACT_LIFT = ROOT / "Diagnostics/Scripts/cf303_nested_exact_lift.py"
ANALYSIS = ROOT / "Diagnostics/Scripts/analyze_cf303_nested_q_reconstruction.py"
DECK = ROOT / "Diagnostics/Scripts/cf303_nested_laurent_deck.py"
PRIMES = (
    2_305_843_009_213_691_819, 2_305_843_009_213_641_971,
    2_305_843_009_213_693_951, 2_305_843_009_213_693_921,
    2_305_843_009_213_693_907, 2_305_843_009_213_693_723,
)


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def encode(value):
    if hasattr(value, "numerator") and hasattr(value, "denominator"):
        return [value.numerator, value.denominator]
    if isinstance(value, list):
        return [encode(item) for item in value]
    if isinstance(value, dict):
        return {key: encode(item) for key, item in value.items()}
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path,
                        default=OUT / "cf303_block1_finite_gauge_record2_exact.json")
    parser.add_argument("--report", type=Path,
                        default=OUT / "cf303_block1_finite_gauge_record2_lift_report.json")
    args = parser.parse_args()
    artifacts = [json.loads((args.input_dir /
        f"cf303_block1_finite_gauge_profiles_q{prime}.json").read_text())
        for prime in PRIMES]
    lift = load_module("cf303_gauge_exact_lift", EXACT_LIFT)
    analysis = load_module("cf303_gauge_analysis", ANALYSIS)
    deck = load_module("cf303_gauge_deck_lift", DECK)
    profiles, report = deck.exact_lift(artifacts, lift, analysis)
    status = ("CF303Block1ExactFiniteGaugeProfilesAcceptedV1"
              if report["unresolved_count"] == 0
              else "CF303Block1ExactFiniteGaugeProfilesIncompleteV1")
    result = {
        "status": status, "block": [25, 1],
        "channel_contract": artifacts[0]["channel_contract"],
        "elliptic_constant_channel": artifacts[0]["elliptic_constant_channel"],
        "exact_profiles": encode(profiles), "lift_report": report,
    }
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"status": status, **report}, indent=2))
    return 0 if report["unresolved_count"] == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
