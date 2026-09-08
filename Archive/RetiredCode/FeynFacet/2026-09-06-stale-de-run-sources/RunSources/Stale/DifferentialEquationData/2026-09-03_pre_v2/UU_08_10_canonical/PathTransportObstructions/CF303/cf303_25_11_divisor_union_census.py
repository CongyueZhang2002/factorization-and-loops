#!/usr/bin/env python3
"""D1 item 3, first half, for CF303 (25,11): the divisor union census.

Assemble the complete candidate divisor list the E1 ambient ladder
ranges over: the 15 exact kinematic factors (absolute irreducibility
dual-certified), the chart's own curves (root1/root2/Delta3 numerators
and the coordinate/chart lines), and the line at infinity.  Everything
is exact over Q.  Duplicates are removed by EXACT polynomial identity
after monic normalization (the E/C binding only identified slice-level
coincidences; this is the exact statement).  Provenance and
irreducibility status are recorded per entry."""

from __future__ import annotations

import json
from fractions import Fraction
from pathlib import Path

from cf303_25_11_ec_divisor_binding import (
    LIFT,
    ART,
    chart_candidates,
    kinematic_candidates,
)

OUTPUT = ART / "cf303_25_11_divisor_union_census.json"


def normalize(poly):
    lead = poly[max(poly)]
    return {k: v / lead for k, v in poly.items()}


def serialize(poly):
    return {f"{i},{j}": [v.numerator, v.denominator]
            for (i, j), v in sorted(poly.items())}


def main() -> int:
    kinematic = kinematic_candidates()
    chart = chart_candidates()
    entries = []
    seen: dict[tuple, str] = {}
    for name, poly in kinematic.items():
        canonical = normalize(poly)
        fingerprint = tuple(sorted(canonical.items()))
        seen[fingerprint] = name
        entries.append({
            "name": name,
            "provenance": "kinematic_denominator",
            "irreducibility": "DualCertifiedAbsolute",
            "total_degree": max(i + j for i, j in poly),
            "terms": serialize(canonical)})
    for name, poly in chart.items():
        canonical = normalize(poly)
        fingerprint = tuple(sorted(canonical.items()))
        if fingerprint in seen:
            entries.append({
                "name": name,
                "provenance": "chart_curve",
                "identical_to": seen[fingerprint]})
            continue
        seen[fingerprint] = name
        degree = max(i + j for i, j in poly)
        certified = {
            # (s+1)^2 + t (s^2-6s+1): linear in t with coprime
            # s-coefficients (elementary absolute irreducibility);
            # Maple evala(AFactors) and Singular absFactorize each
            # return one absolute factor (2026-08-31)
            "root2": "DualCertifiedAbsolute"}
        entries.append({
            "name": name,
            "provenance": "chart_curve",
            "irreducibility": certified.get(
                name, "Linear" if degree == 1
                else "PendingDualCertification"),
            "total_degree": degree,
            "terms": serialize(canonical)})
    # potential-zero residual curves (Codex note 03 closure,
    # cf303_25_11_numerator_residual_closure.json): the six exact
    # regulator-independent residual divisors of the E one-form
    # numerators after census division, fresh-prime verified.  Five
    # are absolutely irreducible (Maple evala/AFactors + Singular
    # absFactorize agree, 2026-08-31); the E12/E21 quartic is a
    # CONJUGATE PAIR over Q(sqrt(2)) (Singular orbit factor with
    # minimal polynomial a^2-2a-7, Maple two absolute factors) -- the
    # sqrt(2) pair the alphabet-completeness audit predicted.
    residual_file = ART / "cf303_25_11_residual_irreducibles.json"
    if residual_file.exists():
        residual = json.loads(residual_file.read_text())
        for curve in residual["curves"]:
            poly = {}
            for monomial, fraction in curve["terms"].items():
                i, j = map(int, monomial.split(","))
                poly[(i, j)] = Fraction(fraction[0], fraction[1])
            entries.append({
                "name": f"Z{curve['index']}(deg{curve['total_degree']})",
                "provenance": "potential_zero_residual",
                "residual_sources": curve["sources"],
                "irreducibility": curve["irreducibility"],
                "minimal_polynomial": curve.get("minimal_polynomial"),
                "total_degree": curve["total_degree"],
                "terms": serialize(normalize(poly))})
    entries.append({
        "name": "line_at_infinity",
        "provenance": "projective_closure",
        "irreducibility": "Linear",
        "total_degree": 1,
        "terms": "homogenization_variable"})

    distinct = [e for e in entries if "identical_to" not in e]
    out = {
        "status": "CF303Block11DivisorUnionCensusV1",
        "distinct_divisors": len(distinct),
        "identifications": {e["name"]: e["identical_to"]
                            for e in entries if "identical_to" in e},
        "pending_irreducibility": [
            e["name"] for e in distinct
            if e.get("irreducibility") == "PendingDualCertification"],
        "entries": entries,
    }
    OUTPUT.write_text(json.dumps(out, indent=1))
    print(json.dumps({k: out[k] for k in (
        "status", "distinct_divisors", "identifications",
        "pending_irreducibility")}, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
