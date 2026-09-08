#!/usr/bin/env python3
"""Close the (25,11) potential-zero column (Codex note 03).

For every E/C component and axis, the reduced numerator slice is
divided by EVERY union-census curve's slice (repeated gcd division,
multiplicity included).  The nonconstant residual products are then
reconstructed bivariately: monic residual slices are sampled on a
spread of frozen coordinates, each monic coefficient is a rational
function of the frozen variable (rational.reconstruct per
coefficient), and the cleared, primitive bivariate residual is
factored and matched across the two 31-bit primes, with a third
fresh prime reserved for the factor-product check and a second
regulator value separating regulator-independent residual curves
from regulator-entangled ones.  Output: exact residual curves to add
to the union census, or the verdict that the residual is regulator-
entangled or empty per component."""

from __future__ import annotations

import json
from fractions import Fraction
from pathlib import Path

import cf303_block18_native_path_degree as rational
import cf303_25_11_selected_degree_probe as selected
from cf303_25_11_diagonal_degree_probe import (
    BINARY,
    decode,
    contract,
    poly_gcd,
    factor_univariate,
    probably_prime,
)
from cf303_25_11_ec_divisor_binding import (
    chart_candidates,
    kinematic_candidates,
)
import subprocess
import tempfile

ART = Path("/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts")
OUTPUT = ART / "cf303_25_11_numerator_residual_closure.json"


def SOURCE_path():
    """The block input the native evaluators read; follows
    selected.SOURCE so a caller (or __main__ via --source) can retarget
    the SAME closure pipeline at another block of the row."""
    return selected.SOURCE

MATCH_PRIMES = (2147483423, 2147483399)
FRESH_PRIME = 2147483323
EPS_VALUES = (11, 7)
COMPONENTS = [("E", r, c) for r in (1, 2) for c in (1, 2)] + [("C", 1, 1)]
T_POINTS = 72
S_SPREAD = [4, 9, 14, 19, 23, 29, 34, 39, 44, 49, 54, 59, 64, 69]


def census_polys():
    out = {}
    for name, poly in {**kinematic_candidates(), **chart_candidates()}.items():
        out[name] = poly
    return out


CENSUS = census_polys()


def poly_eval_slice(poly, axis, frozen_value, prime):
    """Univariate slice of an exact bivariate polynomial mod prime."""
    coefficients = {}
    for (i, j), v in poly.items():
        free, fixed = (i, j) if axis == "t" else (j, i)
        coefficients[free] = coefficients.get(free, Fraction(0)) + \
            v * Fraction(frozen_value) ** fixed
    if not coefficients:
        return [0]
    out = [0] * (max(coefficients) + 1)
    for deg, v in coefficients.items():
        out[deg] = v.numerator % prime * pow(v.denominator % prime,
                                             prime - 2, prime) % prime
    while len(out) > 1 and out[-1] % prime == 0:
        out.pop()
    return out


def sample_images(axis, frozen_value, epsilon, count, prime):
    selected.PRIME = prime
    rational.PRIME = prime
    images, candidate, draw = [], 3, 0
    while len(images) < count and draw < 4000:
        draw += 1
        value = 2 + selected.mix64(90210 + 17 * draw) % (prime - 3)
        try:
            if axis == "t":
                image = selected.chart_point(value, frozen_value, epsilon)
            else:
                image = selected.chart_point(frozen_value, value, epsilon)
        except (ValueError, ZeroDivisionError):
            continue
        image["_free"] = value
        images.append(image)
    if len(images) < count:
        raise RuntimeError(f"admissible-point drought at {prime}")
    return images


def component_slice(images, component, axis, prime):
    """Reconstructed numerator/denominator of one E/C component slice."""
    selected.PRIME = prime
    rational.PRIME = prime
    with tempfile.TemporaryDirectory(prefix="cf303-resid-") as folder:
        folder_path = Path(folder)
        request = folder_path / "request.txt"
        output = folder_path / "output.bin"
        selected.write_request(request, images, 1)
        process = subprocess.run(
            ["taskset", "-c", "0-3", str(BINARY), str(SOURCE_path()),
             str(request), str(output)],
            text=True, capture_output=True, check=False)
        if process.returncode:
            raise RuntimeError(process.stderr)
        header, records = decode(output)
    values = contract(records, images, prime)
    kind, row, col = component
    key = f"{kind},{axis},{row}" + ("" if kind == "C" else f",{col}")
    if kind == "C":
        key = f"C,{axis},1,1"
    else:
        key = f"E,{axis},{row},{col}"
    sequence = values[key]
    free = [image["_free"] for image in images]
    split = len(free) - 16
    return rational.reconstruct(free[:split], sequence[:split],
                                free[split:], sequence[split:])


def divide_out_census(numerator, axis, frozen_value, prime):
    """Repeated gcd division of the slice numerator by every census
    curve's slice; returns the monic residual."""
    rational.PRIME = prime
    residual = rational.trim(list(numerator))
    for poly in CENSUS.values():
        cslice = poly_eval_slice(poly, axis, frozen_value, prime)
        if len(cslice) < 2:
            continue
        while True:
            g = poly_gcd(residual, cslice)
            if len(g) < 2:
                break
            quotient, remainder = rational.divide(residual, g)
            if rational.trim(remainder) != [0]:
                break
            residual = rational.trim(quotient)
    lead = residual[-1] % prime
    if lead == 0:
        return [0]
    inverse = pow(lead, prime - 2, prime)
    return [c * inverse % prime for c in residual]


def residual_profile(axis, epsilon, prime):
    """Per component: monic residuals over the frozen-value spread."""
    frozen_values = S_SPREAD
    out = {}
    for frozen_value in frozen_values:
        images = sample_images(axis, frozen_value, epsilon,
                               T_POINTS, prime)
        for component in COMPONENTS:
            slice_data = component_slice(images, component, axis, prime)
            if slice_data.get("status") != "ReconstructedModPrime":
                raise RuntimeError((component, frozen_value,
                                    slice_data.get("status")))
            residual = divide_out_census(
                slice_data["numerator"], axis, frozen_value, prime)
            out.setdefault(component_name(component), {})[frozen_value] \
                = residual
    return out


def component_name(component):
    kind, r, c = component
    return f"{kind},{r},{c}"


def bivariate_from_slices(slices, axis, prime):
    """Monic residual slices -> bivariate polynomial candidate.
    Each monic coefficient (degree below the maximum) is a rational
    function of the frozen variable; reconstruct, clear denominators,
    return sparse {(t_deg, s_deg): residue} normalized by leading
    monomial, or None when the residual is trivial everywhere."""
    rational.PRIME = prime
    frozen_values = sorted(slices)
    degrees = {value: len(slices[value]) - 1 for value in frozen_values}
    top = max(degrees.values())
    if top < 1:
        return None
    usable = [value for value in frozen_values if degrees[value] == top]
    if len(usable) < 6:
        raise RuntimeError("residual degree unstable across the spread")
    split = len(usable) - 3
    coefficient_functions = []
    for deg in range(top):
        points = usable
        values = [slices[value][deg] for value in usable]
        fit = rational.reconstruct(points[:split], values[:split],
                                   points[split:], values[split:])
        if fit.get("status") == "Zero":
            coefficient_functions.append(([0], [1]))
            continue
        if fit.get("status") != "ReconstructedModPrime":
            raise RuntimeError(("coefficient fit failed", deg,
                                fit.get("status")))
        coefficient_functions.append((fit["numerator"],
                                      fit["denominator"]))
    common = [1]
    for _, den in coefficient_functions:
        g = poly_gcd(common, den)
        quotient, _ = rational.divide(den, g)
        common = rational.trim([
            c % prime for c in poly_mul(common, quotient, prime)])
    poly = {}
    for deg, (num, den) in enumerate(coefficient_functions):
        quotient, remainder = rational.divide(common, den)
        if rational.trim(remainder) != [0]:
            raise RuntimeError("denominator lcm failure")
        lifted = poly_mul(num, quotient, prime)
        for s_deg, value in enumerate(lifted):
            if value % prime:
                key = (deg, s_deg) if axis == "t" else (s_deg, deg)
                poly[key] = value % prime
    for s_deg, value in enumerate(common):
        if value % prime:
            key = (top, s_deg) if axis == "t" else (s_deg, top)
            poly[key] = value % prime
    lead = poly[max(poly)]
    inverse = pow(lead, prime - 2, prime)
    return {k: v * inverse % prime for k, v in poly.items()}


def poly_mul(a, b, prime):
    out = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i + j] = (out[i + j] + x * y) % prime
    return out


def main() -> int:
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=None,
                        help="block input file (default: the (25,11) "
                             "input both native evaluators were built "
                             "against)")
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("--status-tag", default=None)
    args = parser.parse_args()
    global OUTPUT
    if args.source is not None:
        selected.SOURCE = args.source
        import cf303_25_11_full_bbar_reconstruct as sampler_module
        sampler_module.SOURCE = args.source
    if args.output is not None:
        OUTPUT = args.output
    status_tag = args.status_tag or "CF303Block11NumeratorResidualClosureV1"
    report = {"status": status_tag, "source": str(SOURCE_path()),
              "primes": list(MATCH_PRIMES), "fresh_prime": FRESH_PRIME,
              "epsilon_values": list(EPS_VALUES), "components": {}}
    profiles = {}
    for prime in MATCH_PRIMES:
        profiles[prime] = {
            axis: residual_profile(axis, EPS_VALUES[0], prime)
            for axis in ("t", "s")}
    eps_check = {axis: residual_profile(axis, EPS_VALUES[1],
                                        MATCH_PRIMES[0])
                 for axis in ("t", "s")}
    for component in COMPONENTS:
        name = component_name(component)
        entry = {}
        for axis in ("t", "s"):
            candidates = {}
            for prime in MATCH_PRIMES:
                candidates[prime] = bivariate_from_slices(
                    profiles[prime][axis][name], axis, prime)
            eps_candidate = bivariate_from_slices(
                eps_check[axis][name], axis, MATCH_PRIMES[0])
            if candidates[MATCH_PRIMES[0]] is None:
                entry[axis] = {"verdict": "NoResidual"}
                continue
            supports = {p: sorted(candidates[p]) for p in MATCH_PRIMES}
            if supports[MATCH_PRIMES[0]] != supports[MATCH_PRIMES[1]]:
                entry[axis] = {"verdict": "SupportMismatchAcrossPrimes",
                               "supports": {str(p): [list(m) for m in s]
                                            for p, s in supports.items()}}
                continue
            eps_stable = eps_candidate is not None and \
                sorted(eps_candidate) == supports[MATCH_PRIMES[0]] and \
                all(eps_candidate[m] == candidates[MATCH_PRIMES[0]][m]
                    for m in eps_candidate)
            terms = {}
            failures = 0
            for monomial in supports[MATCH_PRIMES[0]]:
                from cf303_25_11_kinematic_divisor_census import (
                    crt, rational_reconstruct)
                value, modulus = crt(
                    [candidates[p][monomial] for p in MATCH_PRIMES],
                    list(MATCH_PRIMES))
                fraction = rational_reconstruct(value, modulus)
                if fraction is None:
                    failures += 1
                    fraction = ["UNRESOLVED", value]
                terms[f"{monomial[0]},{monomial[1]}"] = list(fraction)
            fresh_ok = None
            if failures == 0:
                exact = {tuple(map(int, k.split(","))):
                         Fraction(v[0], v[1]) for k, v in terms.items()}
                fresh_slices = residual_profile_single(
                    axis, EPS_VALUES[0], FRESH_PRIME, name)
                fresh_ok = fresh_product_check(
                    exact, fresh_slices, axis, FRESH_PRIME)
            entry[axis] = {
                "verdict": ("ExactResidualCurve" if failures == 0 and
                            fresh_ok else "ResidualUnresolved"),
                "epsilon_stable": eps_stable,
                "coefficient_failures": failures,
                "fresh_product_check": fresh_ok,
                "terms": terms}
        report["components"][name] = entry
    OUTPUT.write_text(json.dumps(report, indent=1))
    print(json.dumps({name: {axis: entry[axis]["verdict"]
                             for axis in entry}
                      for name, entry in report["components"].items()},
                     indent=1))
    print("epsilon-stability:",
          {name: {axis: report["components"][name][axis].get(
              "epsilon_stable")
              for axis in report["components"][name]}
           for name in report["components"]})
    return 0


def residual_profile_single(axis, epsilon, prime, name):
    component = next(c for c in COMPONENTS if component_name(c) == name)
    out = {}
    for frozen_value in S_SPREAD[:8]:
        images = sample_images(axis, frozen_value, epsilon, T_POINTS,
                               prime)
        slice_data = component_slice(images, component, axis, prime)
        if slice_data.get("status") != "ReconstructedModPrime":
            raise RuntimeError((name, frozen_value,
                                slice_data.get("status")))
        out[frozen_value] = divide_out_census(
            slice_data["numerator"], axis, frozen_value, prime)
    return out


def fresh_product_check(exact, fresh_slices, axis, prime):
    """The exact residual's slice must divide (up to units) the fresh
    prime's direct residual at every sampled frozen value; equality of
    monic slices is the acceptance."""
    rational.PRIME = prime
    for frozen_value, direct in fresh_slices.items():
        expected = poly_eval_slice(exact, axis, frozen_value, prime)
        if len(expected) < 2 and len(direct) < 2:
            continue
        lead = expected[-1] % prime
        if lead == 0:
            return False
        inverse = pow(lead, prime - 2, prime)
        expected = [c * inverse % prime for c in expected]
        if expected != direct:
            return False
    return True


if __name__ == "__main__":
    raise SystemExit(main())
