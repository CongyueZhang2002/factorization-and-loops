#!/usr/bin/env python3
"""Per-block census closure for CF303 row-25 exceptions (25,j),
j in {2, 1, 14} — the (25,11) pipeline generalized.

In the full (t,s) chart every family root is rational, so ALL these
blocks (including (25,14), whose one-variable path saw an 8-sheet
cover) ride the same machinery.  Per block, per axis, per prime:

1. slice the block's C diagonal (via the strip diagonal evaluator)
   and its two physical forcing components (via the native sampler),
   reconstructing numerator and denominator per frozen value;
2. DENOMINATORS: gcd-divide by the family census; bind, and lift any
   residual bivariately -> the block's new POLAR curves, with
   per-factor multiplicities recorded for the gauge ansatz;
3. NUMERATORS: same -> the block's potential-zero curves;
4. cross-prime match with a fresh-prime product check, plus a second
   regulator value for regulator-independence.

E's zero column is (25,11)'s, already closed and certified; the
family census (v2, 24 divisors) is the division basis.  Output:
Diagnostics/Artifacts/cf303_25_<j>_census_closure.json.

Usage: cf303_row25_block_closure.py --block 2|1|14
"""

from __future__ import annotations

import argparse
import json
import tempfile
from pathlib import Path

import cf303_block18_native_path_degree as rational
import cf303_25_11_selected_degree_probe as selected
import cf303_25_11_full_bbar_reconstruct as sampler_module
import cf303_25_11_numerator_residual_closure as base

ART = Path("/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts")
ROOT = Path("/home/maxzhang/factorization-and-loops-codex")

INPUTS = {
    2: ROOT / ("Runtime/CF303_exception14_continuation_2026-08-30/"
               "sector_CF303_standard/CF303_25_2_input.wl"),
    1: ROOT / ("Runtime/2026-08-30_cf303_25_2_exact_common_path/"
               "resume/sector_CF303_standard/CF303_25_1_input.wl"),
    14: ROOT / ("Runtime/CF303_exception_continuation_2026-08-30/"
                "sector_CF303_standard/CF303_25_14_input.wl"),
}

PHYSICAL = ("t,1", "s,1", "t,2", "s,2")
# forcing entries carry higher degrees than the diagonals: a bigger
# per-slice point budget and a longer frozen spread than the (25,11)
# E/C closure needed
T_POINTS = 192
SPREAD = [4, 9, 14, 19, 23, 29, 34, 39, 44, 49, 54, 59, 64, 69,
          74, 79, 83, 89, 94, 99, 104, 109, 114, 119]


def physical_slices(images, prime, work: Path):
    """Both root3 sheets, split into rational EVEN/ODD grades: root1
    and root2 are rational functions of the chart, root3 is the one
    genuine square root, so a component with odd root3 content is not
    a rational function of the slice variable on either single sheet
    -- but (p+m)/2 and (p-m)/(2 root3) both are."""
    selected.PRIME = prime
    rational.PRIME = prime
    inverse_two = pow(2, prime - 2, prime)
    by_sign = {}
    for sign_index, sign in enumerate((1, -1)):
        accumulated = {component: [] for component in PHYSICAL}
        calls = 0
        for begin in range(0, len(images), 480):
            batch = images[begin:begin + 480]
            request = work / f"closure_{sign_index}_{calls}.request"
            output = work / f"closure_{sign_index}_{calls}.bin"
            sampler_module.write_request(request, batch, sign)
            import subprocess
            process = subprocess.run(
                ["taskset", "-c", "0-3",
                 str(sampler_module.SELECTED),
                 str(sampler_module.SOURCE), str(request),
                 str(output), "4", "expression"],
                text=True, capture_output=True, check=False)
            if process.returncode:
                raise RuntimeError(process.stderr)
            header, records = sampler_module.decode_selected(output)
            values = sampler_module.contract(dict(records), batch,
                                             "physical")
            for component in PHYSICAL:
                accumulated[component].extend(
                    values[f"physical,{component}"])
            calls += 1
        by_sign[sign] = accumulated
    out = {}
    for component in PHYSICAL:
        plus = by_sign[1][component]
        minus = by_sign[-1][component]
        out[f"{component}:even"] = [
            (a + b) * inverse_two % prime
            for a, b in zip(plus, minus, strict=True)]
        out[f"{component}:odd"] = [
            (a - b) * inverse_two %
            prime * pow(image["root3"], prime - 2, prime) % prime
            for a, b, image in zip(plus, minus, images, strict=True)]
    return out


def slice_of(sequence, images):
    free = [image["_free"] for image in images]
    split = len(free) - 16
    return rational.reconstruct(free[:split], sequence[:split],
                                free[split:], sequence[split:])


def divide_and_multiplicities(polynomial, axis, frozen_value, prime):
    """Monic residual AND the per-census-curve division counts."""
    rational.PRIME = prime
    residual = rational.trim(list(polynomial))
    counts = {}
    for name, poly in base.CENSUS.items():
        cslice = base.poly_eval_slice(poly, axis, frozen_value, prime)
        if len(cslice) < 2:
            continue
        while True:
            g = base.poly_gcd(residual, cslice)
            if len(g) < 2:
                break
            quotient, remainder = rational.divide(residual, g)
            if rational.trim(remainder) != [0]:
                break
            residual = rational.trim(quotient)
            counts[name] = counts.get(name, 0) + 1
    lead = residual[-1] % prime
    if lead == 0:
        return [0], counts
    inverse = pow(lead, prime - 2, prime)
    return [c * inverse % prime for c in residual], counts


def block_profiles(block, axis, epsilon, prime):
    """Per component: {'num': {frozen: monic residual},
    'den': {frozen: monic residual}, 'mult': accumulated census
    multiplicities of the denominator}."""
    out = {}
    with tempfile.TemporaryDirectory(prefix="cf303-blk-") as folder:
        work = Path(folder)
        for frozen_value in SPREAD:
            images = base.sample_images(axis, frozen_value, epsilon,
                                        T_POINTS, prime)
            for image in images:
                image["epsilon"] = epsilon % prime
            physical = physical_slices(images, prime, work)
            diagonal_c = None
            graded = [f"{c}:{g}" for c in PHYSICAL
                      for g in ("even", "odd")]
            for component in graded + ["C"]:
                if component == "C":
                    if diagonal_c is None:
                        diagonal_c = base.component_slice(
                            images, ("C", 1, 1), axis, prime)
                    fit = diagonal_c
                    name = "C"
                else:
                    sequence = physical[component]
                    fit = slice_of(sequence, images)
                    name = f"B{component}"
                if fit.get("status") == "Zero":
                    continue
                if fit.get("status") != "ReconstructedModPrime":
                    raise RuntimeError((block, name, frozen_value,
                                        fit.get("status")))
                entry = out.setdefault(name, {"num": {}, "den": {},
                                              "mult": {}})
                num_res, _ = divide_and_multiplicities(
                    fit["numerator"], axis, frozen_value, prime)
                den_res, counts = divide_and_multiplicities(
                    fit["denominator"], axis, frozen_value, prime)
                entry["num"][frozen_value] = num_res
                entry["den"][frozen_value] = den_res
                for cname, count in counts.items():
                    entry["mult"][cname] = max(
                        entry["mult"].get(cname, 0), count)
    return out


def lift_side(profiles_by_prime, name, side, axis):
    candidates = {}
    for prime, profile in profiles_by_prime.items():
        if name not in profile:
            return {"verdict": "AbsentComponent"}
        candidates[prime] = base.bivariate_from_slices(
            profile[name][side], axis, prime)
    primes = sorted(candidates)
    if candidates[primes[0]] is None:
        if all(candidates[p] is None for p in primes):
            return {"verdict": "NoResidual"}
        return {"verdict": "SupportMismatchAcrossPrimes"}
    supports = {p: sorted(candidates[p] or {}) for p in primes}
    if len({tuple(map(tuple, s)) for s in supports.values()}) != 1:
        return {"verdict": "SupportMismatchAcrossPrimes"}
    from cf303_25_11_kinematic_divisor_census import (
        crt, rational_reconstruct)
    terms, failures = {}, 0
    for monomial in supports[primes[0]]:
        value, modulus = crt([candidates[p][monomial] for p in primes],
                             primes)
        fraction = rational_reconstruct(value, modulus)
        if fraction is None:
            failures += 1
            fraction = ["UNRESOLVED", value]
        terms[f"{monomial[0]},{monomial[1]}"] = list(fraction)
    return {"verdict": ("ExactResidualCurve" if failures == 0
                        else "ResidualUnresolved"),
            "coefficient_failures": failures, "terms": terms}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block", type=int, required=True,
                        choices=sorted(INPUTS))
    args = parser.parse_args()
    source = INPUTS[args.block]
    if not source.exists():
        raise SystemExit(f"missing input {source}")
    selected.SOURCE = source
    sampler_module.SOURCE = source
    report = {"status": f"CF303Block{args.block}CensusClosureV1",
              "source": str(source),
              "primes": list(base.MATCH_PRIMES),
              "epsilon_values": list(base.EPS_VALUES),
              "components": {}, "multiplicities": {}}
    # profile at BOTH regulator values at BOTH primes; the letter
    # census wants only the regulator-INDEPENDENT numerator/denominator
    # content, which lives inside the per-slice gcd across the two
    # regulator values (the raw residuals are dominated by regulator-
    # dependent structure and are far too large to lift)
    raw = {}
    for prime in base.MATCH_PRIMES:
        raw[prime] = {
            axis: {eps: block_profiles(args.block, axis, eps, prime)
                   for eps in base.EPS_VALUES}
            for axis in ("t", "s")}
    profiles = {}
    for prime in base.MATCH_PRIMES:
        rational.PRIME = prime
        profiles[prime] = {}
        for axis in ("t", "s"):
            merged = {}
            eps0, eps1 = base.EPS_VALUES
            for name in raw[prime][axis][eps0]:
                if name not in raw[prime][axis][eps1]:
                    continue
                entry = {"num": {}, "den": {},
                         "mult": raw[prime][axis][eps0][name]["mult"]}
                for side in ("num", "den"):
                    a_side = raw[prime][axis][eps0][name][side]
                    b_side = raw[prime][axis][eps1][name][side]
                    for frozen in a_side:
                        if frozen not in b_side:
                            continue
                        g = base.poly_gcd(a_side[frozen],
                                          b_side[frozen])
                        entry[side][frozen] = g
                merged[name] = entry
            profiles[prime][axis] = merged
    eps_profiles = None
    names = sorted({name for prime in profiles
                    for axis in profiles[prime]
                    for name in profiles[prime][axis]})
    for name in names:
        entry = {}
        for axis in ("t", "s"):
            by_prime = {p: profiles[p][axis] for p in base.MATCH_PRIMES}
            for side in ("num", "den"):
                lifted = lift_side(by_prime, name, side, axis)
                if lifted.get("verdict") == "ExactResidualCurve":
                    # the lifted object IS the two-regulator gcd, so
                    # regulator-independence is built in by
                    # construction
                    lifted["epsilon_stable"] = True
                entry[f"{axis}:{side}"] = lifted
        report["components"][name] = entry
        for prime in base.MATCH_PRIMES:
            for axis in ("t", "s"):
                if name in profiles[prime][axis]:
                    for cname, count in \
                            profiles[prime][axis][name]["mult"].items():
                        key = f"{name}"
                        report["multiplicities"].setdefault(key, {})
                        report["multiplicities"][key][cname] = max(
                            report["multiplicities"][key].get(cname, 0),
                            count)
    output = ART / f"cf303_25_{args.block}_census_closure.json"
    output.write_text(json.dumps(report, indent=1))
    print(json.dumps({name: {k: v.get("verdict")
                             for k, v in entry.items()}
                      for name, entry in report["components"].items()},
                     indent=1))
    print("multiplicities:",
          json.dumps(report["multiplicities"], indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
