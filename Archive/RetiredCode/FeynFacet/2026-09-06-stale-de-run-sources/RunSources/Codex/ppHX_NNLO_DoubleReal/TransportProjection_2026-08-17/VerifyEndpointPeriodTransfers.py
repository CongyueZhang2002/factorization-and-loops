#!/usr/bin/env python3
"""Exact momentum-map checks for the four endpoint periods used by CF299/CF407."""

from __future__ import annotations

import json
from pathlib import Path

import sympy as sp
import yaml


ROOT = Path("/home/maxzhang/factorization-and-loops")
FAMILY_FILE = (
    ROOT
    / "Codex/ppHX_NNLO_DoubleReal/Kira/UU_08_10_canonical"
    / "kira/config/integralfamilies.yaml"
)
OUTPUT = (
    ROOT
    / "Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17"
    / "EndpointPeriodTransferCertificate.json"
)

ka, kb, kc, ke, kf = sp.symbols("ka kb kc ke kf")
locals_ = {str(x): x for x in (ka, kb, kc, ke, kf)}
P = ka + kb - kc


def load_families() -> dict[str, dict]:
    raw = yaml.safe_load(FAMILY_FILE.read_text())["integralfamilies"]
    return {entry["name"]: entry for entry in raw}


def momentum(family: dict, slot: int) -> sp.Expr:
    item = family["propagators"][slot - 1]
    if isinstance(item, dict):
        raise ValueError(f"slot {slot} is bilinear, not a squared momentum")
    return sp.expand(sp.sympify(item[0], locals=locals_))


def equal_square(left: sp.Expr, right: sp.Expr) -> bool:
    return sp.expand(left - right) == 0 or sp.expand(left + right) == 0


def mapped_powers(source: list[int], slot_map: dict[int, int], count: int) -> list[int]:
    result = [0] * count
    for source_slot, power in enumerate(source, 1):
        if power:
            result[slot_map[source_slot] - 1] += power
    return result


def certify(
    families: dict[str, dict],
    period: int,
    source_name: str,
    target_name: str,
    source_powers: list[int],
    target_powers: list[int],
    slot_map: dict[int, int],
    substitution: dict[sp.Symbol, sp.Expr],
    loop_jacobian: int,
    invariant_map: str,
) -> dict:
    source = families[source_name]
    target = families[target_name]
    active = [i for i, power in enumerate(source_powers, 1) if power]
    denominator_checks = {}
    for source_slot in active:
        target_slot = slot_map[source_slot]
        mapped = sp.expand(momentum(source, source_slot).subs(substitution, simultaneous=True))
        expected = momentum(target, target_slot)
        denominator_checks[str(source_slot)] = {
            "TargetSlot": target_slot,
            "MappedMomentum": str(mapped),
            "TargetMomentum": str(expected),
            "EqualSquaredMomentum": equal_square(mapped, expected),
        }

    source_cuts = set(source["cut_propagators"])
    target_cuts = set(target["cut_propagators"])
    mapped_cuts = {slot_map[i] for i in source_cuts}
    powers = mapped_powers(source_powers, slot_map, len(target["propagators"]))
    exact = (
        all(item["EqualSquaredMomentum"] for item in denominator_checks.values())
        and mapped_cuts == target_cuts
        and powers == target_powers
        and abs(loop_jacobian) == 1
    )
    return {
        "PeriodID": period,
        "SourceFamily": source_name,
        "TargetFamily": target_name,
        "SourcePowers": source_powers,
        "TargetPowers": target_powers,
        "SlotMap": {str(k): v for k, v in slot_map.items()},
        "InvariantMap": invariant_map,
        "LoopJacobian": loop_jacobian,
        "MappedCutSlots": sorted(mapped_cuts),
        "TargetCutSlots": sorted(target_cuts),
        "DenominatorChecks": denominator_checks,
        "Exact": exact,
    }


def main() -> None:
    families = load_families()
    identity = {ka: ka, kb: kb, kc: kc, ke: ke, kf: kf}
    swap_and_cycle = {
        ka: kb,
        kb: ka,
        kc: kc,
        ke: kf,
        kf: P - ke - kf,
    }

    records = [
        certify(
            families,
            8,
            "CF199",
            "CF299",
            [1, 1, 1, 0, 1, 1, 1, 1, 0],
            [1, 1, 0, 1, 1, 1, 1, 1, 0],
            {1: 1, 2: 2, 3: 4, 5: 5, 6: 6, 7: 7, 8: 8},
            identity,
            1,
            "(v,w) -> (v,w)",
        ),
        certify(
            families,
            9,
            "CF199",
            "CF299",
            [1, 1, 1, 0, 0, 1, 0, 1, 0],
            [1, 1, 0, 1, 0, 1, 0, 1, 0],
            {1: 1, 2: 2, 3: 4, 6: 6, 8: 8},
            identity,
            1,
            "(v,w) -> (v,w)",
        ),
        certify(
            families,
            9,
            "CF199",
            "CF299",
            [1, 1, 1, 0, 0, 1, 0, 2, 0],
            [1, 1, 0, 1, 0, 1, 0, 2, 0],
            {1: 1, 2: 2, 3: 4, 6: 6, 8: 8},
            identity,
            1,
            "(v,w) -> (v,w)",
        ),
        certify(
            families,
            25,
            "CF299",
            "CF300",
            [1, 1, 1, 1, 0, 1, 0, 1, 0],
            [1, 1, 1, 1, 0, 1, 0, 1, 0],
            {1: 1, 2: 2, 3: 3, 4: 4, 6: 6, 8: 8},
            identity,
            1,
            "(v,w) -> (v,w)",
        ),
        certify(
            families,
            25,
            "CF299",
            "CF300",
            [1, 1, 1, 1, 0, 1, 0, 2, 0],
            [1, 1, 1, 1, 0, 1, 0, 2, 0],
            {1: 1, 2: 2, 3: 3, 4: 4, 6: 6, 8: 8},
            identity,
            1,
            "(v,w) -> (v,w)",
        ),
        certify(
            families,
            23,
            "CF267",
            "CF388",
            [1, 1, 1, 0, 1, 1, 1, 1, 0],
            [1, 1, 1, 1, 0, 1, 1, 1, 0],
            {1: 8, 2: 1, 3: 3, 5: 6, 6: 4, 7: 7, 8: 2},
            swap_and_cycle,
            1,
            "(v,w) -> (w,v); (q1,q2,q3) -> (q3,q1,q2)",
        ),
        certify(
            families,
            23,
            "CF388",
            "CF407",
            [1, 1, 1, 1, 0, 1, 1, 1, 0],
            [1, 1, 1, 1, 0, 1, 1, 0, 1],
            {1: 1, 2: 2, 3: 3, 4: 4, 6: 6, 7: 7, 8: 9},
            identity,
            1,
            "(v,w) -> (v,w)",
        ),
    ]
    certificate = {
        "Format": "FeynFacetEndpointPeriodTransferCertificate",
        "Criterion": (
            "Every powered squared momentum maps to the target powered squared "
            "momentum, the three cut slots map bijectively, the powered-index "
            "vector is preserved, and the loop-variable Jacobian has unit magnitude."
        ),
        "Records": records,
        "EveryTransferExact": all(record["Exact"] for record in records),
    }
    OUTPUT.write_text(json.dumps(certificate, indent=2) + "\n")
    print(f"records = {len(records)}")
    print(f"exact records = {sum(record['Exact'] for record in records)}")
    print(f"EVERY_TRANSFER_EXACT = {certificate['EveryTransferExact']}")


if __name__ == "__main__":
    main()
