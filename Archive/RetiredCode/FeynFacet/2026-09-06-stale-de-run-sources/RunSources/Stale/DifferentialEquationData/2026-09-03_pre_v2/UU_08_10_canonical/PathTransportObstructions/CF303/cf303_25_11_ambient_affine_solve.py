#!/usr/bin/env python3
"""Ambient affine solve for CF303 (25,11) on the COMPLETE census span.

The rank0 production run exhausted its ladder on the production
alphabet only (span-relative).  This driver reruns the same affine row
equation -- gauge over the exact Q-power denominator plus constant
residues times dlog letters -- with the letter set drawn from the
COMPLETE union census v2 (15 kinematic factors, root2, s+1, six
residual potential-zero curves; each reduced and split mod p, so the
Q(sqrt(2)) conjugate pair enters as its two rational components), at
TWO independent images (prime, regulator): the first forcing from the
accepted Bbar tensor, the second sampled natively pointwise.

Outcomes: a consistent rung with held-out exact replay at BOTH images
is a constructive dlog-form candidate (the exception would be
WITHDRAWN); CFFR exit 5 at every rung at both images is the
alphabet-complete obstruction (the residue-only witness screen then
issues the frozen certificate).  Machinery is imported from
cf303_25_11_rank0_affine_solve; nothing there is modified."""

from __future__ import annotations

import json
import math
import subprocess
import tempfile
import time
from fractions import Fraction
from pathlib import Path

import cf303_block18_native_path_degree as rational
import cf303_25_11_selected_degree_probe as selected
import cf303_25_11_rank0_affine_solve as r0
import cf303_25_11_full_bbar_reconstruct as sampler_module
from cf303_25_11_kinematic_divisor_census import factor_modp

ART = Path("/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts")
LIFT = Path("/home/maxzhang/factorization-and-loops-codex/Runtime/"
            "2026-08-30_cf303_25_11_exact_lift")
OUTPUT = ART / "cf303_25_11_ambient_affine_result.json"

IMAGES = (
    {"prime": 2147483423, "epsilon": 11, "forcing": "tensor"},
    {"prime": 2147483399, "epsilon": 7, "forcing": "native"},
)
OFFSETS = ((0, 0), (1, 1), (2, 2))
HELDOUT = 64
CPUS = "0-3"
THREADS = 4


def set_prime(prime: int) -> None:
    r0.PRIME = prime
    selected.PRIME = prime
    rational.PRIME = prime
    sampler_module.PRIME = prime


def census_polys() -> list[dict]:
    census = json.loads((ART / "cf303_25_11_divisor_union_census.json"
                         ).read_text())
    out = []
    for entry in census["entries"]:
        if "identical_to" in entry or entry["terms"] == \
                "homogenization_variable":
            continue
        poly = {}
        for monomial, fraction in entry["terms"].items():
            i, j = map(int, monomial.split(","))
            poly[(i, j)] = Fraction(fraction[0], fraction[1])
        out.append({"name": entry["name"], "poly": poly})
    return out


def mod_letters(prime: int) -> list[dict]:
    """Census curves reduced mod p and split into irreducible mod-p
    factors (a finer span can only strengthen an obstruction and stays
    a valid letter set for a constructive solve)."""
    letters = {}
    for entry in census_polys():
        reduced = {}
        for monomial, value in entry["poly"].items():
            residue = value.numerator % prime * pow(
                value.denominator % prime, prime - 2, prime) % prime
            if residue:
                reduced[monomial] = residue
        for factor in factor_modp(reduced, prime):
            terms = factor["terms"]
            lead = terms[max(terms)]
            inverse = pow(lead, prime - 2, prime)
            canonical = tuple(sorted(
                (m, c * inverse % prime) for m, c in terms.items()))
            if canonical in letters:
                letters[canonical]["sources"].append(entry["name"])
            else:
                letters[canonical] = {
                    "terms": dict(canonical),
                    "sources": [entry["name"]]}
    return list(letters.values())


def exact_gauge(prime: int):
    """Gauge denominator (product of Q factors^(exponent-1)) and the
    dense Q grid, both mod p, from the EXACT kinematic census."""
    census = json.loads((LIFT / "cf303_25_11_kinematic_divisor_census.json"
                         ).read_text())
    gauge = {(0, 0): 1}
    denominator = {(0, 0): 1}
    for factor in census["factors"]:
        terms = {}
        for monomial, fraction in factor["terms"].items():
            i, j = map(int, monomial.split(","))
            terms[(i, j)] = fraction[0] % prime * pow(
                fraction[1] % prime, prime - 2, prime) % prime
        exponent = factor["exponent"]
        denominator = r0.poly_multiply(
            denominator, r0.poly_power(terms, exponent))
        if exponent > 1:
            gauge = r0.poly_multiply(
                gauge, r0.poly_power(terms, exponent - 1))
    dt = max(i for i, _ in denominator)
    ds = max(j for _, j in denominator)
    dense = [[0] * (ds + 1) for _ in range(dt + 1)]
    for (i, j), c in denominator.items():
        dense[i][j] = c
    return gauge, dense


def native_forcing(images, epsilon, work: Path):
    sampler = sampler_module.NativeSampler(work, CPUS, THREADS, 480)
    values = sampler.evaluate(images, "ambient_forcing")
    return {component: values[component]
            for component in ("t,1", "s,1", "t,2", "s,2")}


def run_image(image_config) -> dict:
    prime = image_config["prime"]
    epsilon = image_config["epsilon"]
    set_prime(prime)
    letters = mod_letters(prime)
    gauge, q_dense = exact_gauge(prime)
    gauge_degrees = r0.poly_degrees(gauge)
    gauge_derivatives = (r0.poly_derivative(gauge, 0),
                         r0.poly_derivative(gauge, 1))
    data = {"kinematic_denominator": q_dense}
    tensor = None
    if image_config["forcing"] == "tensor":
        tensor = json.loads((ART / "cf303_25_11_full_bbar_modp.json"
                             ).read_text())
        if tensor.get("prime") != prime:
            raise RuntimeError("tensor prime mismatch")
    report = {"prime": prime, "epsilon": epsilon,
              "letter_count": len(letters),
              "gauge_degrees": list(gauge_degrees),
              "attempts": []}
    with tempfile.TemporaryDirectory(prefix="cf303-ambient-") as folder:
        work = Path(folder)
        for offset in OFFSETS:
            support = [(i, j)
                       for i in range(gauge_degrees[0] + offset[0] + 1)
                       for j in range(gauge_degrees[1] + offset[1] + 1)]
            columns = 2 * len(support) + 2 * len(letters)
            point_count = max(16, math.ceil((columns + 4) / 4))
            rows = 4 * point_count
            points = r0.draw_points(point_count, 25_119_800 + offset[0],
                                    data, letters, gauge)
            # ONE regulator value per image for BOTH the diagonal E/C
            # and the forcing (draw_points stamps 11 internally)
            for point in points:
                point["epsilon"] = epsilon % prime
            diagonal, diagonal_timing = r0.diagonal_images(points, CPUS)
            if image_config["forcing"] == "tensor":
                forcing = r0.bbar_values(tensor, points, epsilon)
            else:
                forcing = native_forcing(points, epsilon, work)
            def source():
                for index, point in enumerate(points):
                    yield point_rows_pair(index, point, diagonal,
                                          forcing, letters, gauge,
                                          gauge_derivatives, support,
                                          epsilon)
            request = work / f"request_{prime}_{offset[0]}.bin"
            response = work / f"response_{prime}_{offset[0]}.bin"
            preference = list(reversed(range(2 * len(support)))) + \
                list(range(2 * len(support), columns))
            nonce = (2026, 831_000 + offset[0])
            r0.write_cffr_request(request, rows, columns, source(),
                                  preference, nonce)
            started = time.perf_counter()
            process = subprocess.run(
                ["taskset", "-c", CPUS, str(r0.CFFR_BINARY),
                 str(request), str(response), str(THREADS)],
                text=True, capture_output=True, check=False)
            solve_seconds = time.perf_counter() - started
            attempt = {"offset": list(offset),
                       "support_count": len(support),
                       "matrix_dimensions": [rows, columns],
                       "cffr_exit_code": process.returncode,
                       "solve_seconds": solve_seconds}
            report["attempts"].append(attempt)
            if process.returncode == 5:
                continue
            if process.returncode:
                raise RuntimeError(process.stderr)
            particular, meta = r0.read_cffr_particular(
                response, rows, columns, nonce)
            attempt["rank"] = meta["rank"]
            attempt["nullity"] = meta["nullity"]
            training = {(p["t"], p["s"]) for p in points}
            held = r0.draw_points(HELDOUT, 25_119_900, data, letters,
                                  gauge, training)
            for point in held:
                point["epsilon"] = epsilon % prime
            held_diagonal, _ = r0.diagonal_images(held, CPUS)
            if image_config["forcing"] == "tensor":
                held_forcing = r0.bbar_values(tensor, held, epsilon)
            else:
                held_forcing = native_forcing(held, epsilon, work)
            mismatches = 0
            comparisons = 0
            for index, point in enumerate(held):
                matrix_rows, rhs = point_rows_pair(
                    index, point, held_diagonal, held_forcing,
                    letters, gauge, gauge_derivatives, support, epsilon)
                for row, expected in zip(matrix_rows, rhs, strict=True):
                    actual = sum(c * v for c, v in
                                 zip(row, particular, strict=True)) % prime
                    comparisons += 1
                    if actual != expected:
                        mismatches += 1
            attempt["heldout"] = {"points": len(held),
                                  "comparisons": comparisons,
                                  "mismatches": mismatches}
            attempt["consistent"] = mismatches == 0
            report["verdict"] = ("ConstructiveCandidateAccepted"
                                 if mismatches == 0 else
                                 "HeldoutRejected")
            report["particular_nonzero"] = sum(
                1 for v in particular if v)
            return report
    report["verdict"] = "LadderExhaustedInconsistent"
    return report


def point_rows_pair(index, image, diagonal, forcing, letters, gauge,
                    gauge_derivatives, support, epsilon):
    return r0.point_rows(index, image, diagonal, forcing, letters,
                         gauge, gauge_derivatives, support, epsilon)


def main() -> int:
    results = [run_image(cfg) for cfg in IMAGES]
    verdicts = [r["verdict"] for r in results]
    combined = ("AlphabetCompleteObstruction"
                if all(v == "LadderExhaustedInconsistent"
                       for v in verdicts)
                else "ConstructiveCandidateBothImages"
                if all(v == "ConstructiveCandidateAccepted"
                       for v in verdicts)
                else "ImagesDisagree")
    out = {"status": "CF303Block11AmbientAffineSolveV1",
           "combined_verdict": combined,
           "offsets": [list(o) for o in OFFSETS],
           "images": results}
    OUTPUT.write_text(json.dumps(out, indent=1))
    print(json.dumps({"combined_verdict": combined,
                      "verdicts": verdicts,
                      "letter_counts": [r["letter_count"]
                                        for r in results],
                      "attempts": [[a["cffr_exit_code"]
                                    for a in r["attempts"]]
                                   for r in results]}, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
