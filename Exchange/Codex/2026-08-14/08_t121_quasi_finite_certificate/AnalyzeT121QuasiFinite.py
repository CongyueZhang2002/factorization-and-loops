"""Exact weighted-scaling census for the T121 boundary period.

The rationalized density uses r in (0,1) and a,u,v in (0,infinity).
At epsilon = 0 after n dimension shifts d -> d+2 n, its variable-dependent
part is

  a^(1+2n) u^(1+2n) v^(2n) r^(1+2n)
  (1-r^2)^(3+4n)
  (1+a^2)^(4-2n) (1+u^2)^(4-2n)
  (1+v^2)^(5-2n) (1+r^2)^(7-6n)
  / (P1 P2^2 P3^2 P4).

P1,...,P4 are retained as sums of two squares.  The script scans ordinary
coordinate boundaries and local charts around the real zero sets of P1 and
P4.  Integer rays are an exploratory census; the resulting candidate cones
are converted into analytic inequalities in the accompanying record.
"""

from __future__ import annotations

from collections import defaultdict
from itertools import product
from math import gcd
from pathlib import Path
import json

import sympy as sp


lam = sp.Symbol("lambda", positive=True)
r, a, u, v = sp.symbols("r a u v", positive=True)
p, h, normal = sp.symbols("p h normal", positive=True)

C = 1 + r**2
P1 = (C - 2*a*u*r)**2 + v**2*(C + 2*a*u*r)**2
P2 = (a*C + 2*u*r)**2 + v**2*(a*C - 2*u*r)**2
P3 = (u*C + 2*a*r)**2 + v**2*(u*C - 2*a*r)**2
P4 = (a*u*C - 2*r)**2 + v**2*(a*u*C + 2*r)**2

Q2 = (h*C + 2*r)**2 + v**2*(h*C - 2*r)**2
Q3 = (C + 2*h*r)**2 + v**2*(C - 2*h*r)**2
P1ph = (C - 2*p*r)**2 + v**2*(C + 2*p*r)**2
P4ph = (p*C - 2*r)**2 + v**2*(p*C + 2*r)**2


def primitive(weights: tuple[int, ...]) -> bool:
    common = 0
    for weight in weights:
        common = gcd(common, weight)
    return common == 1


def lambda_valuation(expression: sp.Expr) -> int:
    """Lowest exact power of lambda in a finite Laurent polynomial."""
    expanded = sp.expand(expression)
    grouped: dict[sp.Rational, sp.Expr] = defaultdict(lambda: sp.Integer(0))
    for term in sp.Add.make_args(expanded):
        exponent = sp.Rational(term.as_powers_dict().get(lam, 0))
        grouped[exponent] += term/lam**exponent
    nonzero = [exponent for exponent, coefficient in grouped.items()
               if sp.simplify(coefficient) != 0]
    if not nonzero:
        raise ValueError("zero expression has no valuation")
    return int(min(nonzero))


def monomial_support(expression: sp.Expr, variables: list[sp.Symbol]):
    """Exponent vectors of a polynomial after exact cancellation."""
    expanded = sp.expand(expression)
    vectors = set()
    for term in sp.Add.make_args(expanded):
        powers = term.as_powers_dict()
        vectors.add(tuple(int(powers.get(variable, 0)) for variable in variables))
    return tuple(sorted(vectors))


def factor_support(expression: sp.Expr, substitution: dict,
                   variables: list[sp.Symbol]):
    numerator, denominator = sp.fraction(sp.cancel(expression.subs(substitution)))
    return monomial_support(numerator, variables), monomial_support(denominator, variables)


def support_valuation(support, ray: tuple[int, ...]):
    numerator, denominator = support
    numerator_degree = min(sum(i*j for i, j in zip(vector, ray))
                           for vector in numerator)
    denominator_degree = min(sum(i*j for i, j in zip(vector, ray))
                             for vector in denominator)
    return numerator_degree - denominator_degree


def local_substitution(states: dict[str, str], weights: dict[str, int]):
    constants = {"r": sp.Rational(1, 3), "a": sp.Integer(2),
                 "u": sp.Integer(3), "v": sp.Integer(5)}
    symbols = {"r": r, "a": a, "u": u, "v": v}
    substitution = {}
    measure_degree = 0
    for name, state in states.items():
        symbol = symbols[name]
        if state == "fixed":
            substitution[symbol] = constants[name]
            continue
        weight = weights[name]
        coefficient = constants[name]
        if state == "zero":
            substitution[symbol] = coefficient*lam**weight
            measure_degree += weight
        elif state == "infinity":
            substitution[symbol] = coefficient*lam**(-weight)
            measure_degree -= weight
        elif state == "one":
            substitution[symbol] = 1 - coefficient*lam**weight
            measure_degree += weight
        else:
            raise ValueError(f"unknown boundary state {state}")
    return substitution, measure_degree


def factor_degree(symbol: sp.Symbol, state: str, weight: int, kind: str):
    if kind == "coordinate":
        return weight if state == "zero" else (-weight if state == "infinity" else 0)
    if kind == "one-plus-square":
        return -2*weight if state == "infinity" else 0
    raise ValueError(kind)


def ordinary_degree(shift: int, states: dict[str, str], weights: dict[str, int]):
    substitution, measure = local_substitution(states, weights)
    degree = measure
    for name in ("a", "u"):
        degree += (1 + 2*shift)*factor_degree(
            {"a": a, "u": u}[name], states[name], weights.get(name, 0), "coordinate"
        )
        degree += (4 - 2*shift)*factor_degree(
            {"a": a, "u": u}[name], states[name], weights.get(name, 0), "one-plus-square"
        )
    degree += 2*shift*factor_degree(v, states["v"], weights.get("v", 0), "coordinate")
    degree += (5 - 2*shift)*factor_degree(
        v, states["v"], weights.get("v", 0), "one-plus-square"
    )
    degree += (1 + 2*shift)*(
        weights.get("r", 0) if states["r"] == "zero" else 0
    )
    degree += (3 + 4*shift)*(
        weights.get("r", 0) if states["r"] == "one" else 0
    )
    degree -= lambda_valuation(P1.subs(substitution))
    degree -= 2*lambda_valuation(P2.subs(substitution))
    degree -= 2*lambda_valuation(P3.subs(substitution))
    degree -= lambda_valuation(P4.subs(substitution))
    return int(degree)


def density_product_ratio(shift: int):
    return (
        p**(-3 + 2*shift)*h**3*r**(1 + 2*shift)*v**(2*shift)
        *(1-r**2)**(3 + 4*shift)
        *(1+p*h)**(4 - 2*shift)*(1+p/h)**(4 - 2*shift)
        *(1+v**2)**(5 - 2*shift)*(1+r**2)**(7 - 6*shift)
        /(P1ph*P4ph*Q2**2*Q3**2)
    )


def surface_expression(shift: int, surface: str):
    density = density_product_ratio(shift)
    if surface == "P1":
        p_rule = (C-normal)/(2*r)
        jacobian = 1/(2*r)
    elif surface == "P4":
        p_rule = (2*r+normal)/C
        jacobian = 1/C
    else:
        raise ValueError(surface)
    return sp.factor(density.subs(p, p_rule)*jacobian)


def surface_degree(expression: sp.Expr, r_state: str, h_state: str,
                   weights: dict[str, int]):
    substitution = {
        normal: sp.Integer(7)*lam**weights["normal"],
        v: sp.Integer(5)*lam**weights["v"],
    }
    measure = weights["normal"] + weights["v"]
    if r_state == "fixed":
        substitution[r] = sp.Rational(1, 3)
    elif r_state == "zero":
        substitution[r] = sp.Rational(1, 3)*lam**weights["r"]
        measure += weights["r"]
    elif r_state == "one":
        substitution[r] = 1 - sp.Rational(1, 3)*lam**weights["r"]
        measure += weights["r"]
    else:
        raise ValueError(r_state)
    if h_state == "fixed":
        substitution[h] = sp.Integer(2)
    elif h_state == "zero":
        substitution[h] = sp.Integer(2)*lam**weights["h"]
        measure += weights["h"]
    elif h_state == "infinity":
        substitution[h] = sp.Integer(2)*lam**(-weights["h"])
        measure -= weights["h"]
    else:
        raise ValueError(h_state)
    numerator, denominator = sp.fraction(sp.cancel(expression.subs(substitution)))
    return measure + lambda_valuation(numerator) - lambda_valuation(denominator)


def scan_ordinary(shift: int, max_weight: int):
    records = []
    for r_state in ("fixed", "zero", "one"):
        for a_state, u_state, v_state in product(
            ("fixed", "zero", "infinity"), repeat=3
        ):
            states = {"r": r_state, "a": a_state,
                      "u": u_state, "v": v_state}
            active = [name for name, state in states.items() if state != "fixed"]
            if not active:
                continue
            chart_variables = [sp.Symbol(f"t_{name}", positive=True) for name in active]
            chart_by_name = dict(zip(active, chart_variables))
            constants = {"r": sp.Rational(1, 3), "a": sp.Integer(2),
                         "u": sp.Integer(3), "v": sp.Integer(5)}
            physical = {"r": r, "a": a, "u": u, "v": v}
            substitution = {}
            measure_signs = []
            for name, state in states.items():
                if state == "fixed":
                    substitution[physical[name]] = constants[name]
                elif state == "zero":
                    substitution[physical[name]] = constants[name]*chart_by_name[name]
                    measure_signs.append(1)
                elif state == "infinity":
                    substitution[physical[name]] = constants[name]/chart_by_name[name]
                    measure_signs.append(-1)
                elif state == "one":
                    substitution[physical[name]] = 1-constants[name]*chart_by_name[name]
                    measure_signs.append(1)
            factors = [
                (a, 1+2*shift), (u, 1+2*shift), (v, 2*shift),
                (r, 1+2*shift), (1-r**2, 3+4*shift),
                (1+a**2, 4-2*shift), (1+u**2, 4-2*shift),
                (1+v**2, 5-2*shift), (1+r**2, 7-6*shift),
                (P1, -1), (P2, -2), (P3, -2), (P4, -1),
            ]
            factor_supports = [
                (factor_support(factor, substitution, chart_variables), power)
                for factor, power in factors if power != 0
            ]
            for values in product(range(1, max_weight + 1), repeat=len(active)):
                if not primitive(values):
                    continue
                weights = dict(zip(active, values))
                degree = sum(sign*weight for sign, weight in zip(measure_signs, values))
                degree += sum(
                    power*support_valuation(support, values)
                    for support, power in factor_supports
                )
                if shift == 2:
                    signed = {
                        name: (weights.get(name, 0) if states[name] == "zero"
                               else -weights.get(name, 0)
                               if states[name] == "infinity" else 0)
                        for name in ("a", "u", "v")
                    }
                    aa, uu, vv = signed["a"], signed["u"], signed["v"]
                    if r_state == "fixed":
                        expected = 2*abs(aa+uu)+4*abs(aa-uu)+5*abs(vv)
                    elif r_state == "one":
                        rr = weights["r"]
                        expected = 2*abs(aa+uu)+4*abs(aa-uu)+5*abs(vv)+12*rr
                    else:
                        rr = weights["r"]
                        expected = (
                            abs(aa+uu+rr)+abs(aa+uu-rr)
                            +2*abs(aa-uu-rr)+2*abs(uu-aa-rr)+5*abs(vv)
                        )
                    if degree != expected:
                        raise AssertionError(
                            f"D+4 ordinary identity failed: {states}, {weights}, "
                            f"{degree} != {expected}"
                        )
                if degree <= 0:
                    records.append({"States": states, "Weights": weights,
                                    "Degree": degree})
    return records


def scan_surface(shift: int, surface: str, max_weight: int):
    records = []
    for r_state in ("fixed", "zero", "one"):
        for h_state in ("fixed", "zero", "infinity"):
            active = ["normal", "v"]
            if r_state != "fixed":
                active.append("r")
            if h_state != "fixed":
                active.append("h")
            chart_variables = [sp.Symbol(f"t_{name}", positive=True) for name in active]
            chart_by_name = dict(zip(active, chart_variables))
            substitution = {
                normal: sp.Integer(7)*chart_by_name["normal"],
                v: sp.Integer(5)*chart_by_name["v"],
            }
            measure_signs = [1, 1]
            if r_state == "fixed":
                substitution[r] = sp.Rational(1, 3)
            elif r_state == "zero":
                substitution[r] = sp.Rational(1, 3)*chart_by_name["r"]
                measure_signs.append(1)
            elif r_state == "one":
                substitution[r] = 1-sp.Rational(1, 3)*chart_by_name["r"]
                measure_signs.append(1)
            if h_state == "fixed":
                substitution[h] = sp.Integer(2)
            elif h_state == "zero":
                substitution[h] = sp.Integer(2)*chart_by_name["h"]
                measure_signs.append(1)
            elif h_state == "infinity":
                substitution[h] = sp.Integer(2)/chart_by_name["h"]
                measure_signs.append(-1)
            if surface == "P1":
                p_rule = (C-normal)/(2*r)
                jacobian = 1/(2*r)
            elif surface == "P4":
                p_rule = (2*r+normal)/C
                jacobian = 1/C
            else:
                raise ValueError(surface)
            factors = [
                (p_rule, -3+2*shift), (h, 3), (r, 1+2*shift),
                (v, 2*shift), (1-r**2, 3+4*shift),
                (1+p_rule*h, 4-2*shift), (1+p_rule/h, 4-2*shift),
                (1+v**2, 5-2*shift), (1+r**2, 7-6*shift),
                (P1ph.subs(p, p_rule), -1), (P4ph.subs(p, p_rule), -1),
                (Q2, -2), (Q3, -2), (jacobian, 1),
            ]
            factor_supports = [
                (factor_support(factor, substitution, chart_variables), power)
                for factor, power in factors if power != 0
            ]
            for values in product(range(1, max_weight + 1), repeat=len(active)):
                if not primitive(values):
                    continue
                weights = dict(zip(active, values))
                degree = sum(sign*weight for sign, weight in zip(measure_signs, values))
                degree += sum(
                    power*support_valuation(support, values)
                    for support, power in factor_supports
                )
                if shift == 2:
                    nn, vv = weights["normal"], weights["v"]
                    hh = (weights.get("h", 0) if h_state == "zero"
                          else -weights.get("h", 0)
                          if h_state == "infinity" else 0)
                    if r_state == "fixed":
                        expected = nn+5*vv-2*min(nn, vv)+4*abs(hh)
                    elif r_state == "one":
                        rr = weights["r"]
                        expected = (
                            12*rr+4*abs(hh)+nn+5*vv
                            -2*min(nn, vv)-2*min(2*rr, nn, vv)
                        )
                    elif surface == "P1":
                        rr = weights["r"]
                        expected = (
                            nn+5*vv-2*min(nn, vv)
                            +2*rr+2*abs(hh-rr)+2*abs(hh+rr)
                        )
                    else:
                        rr = weights["r"]
                        expected = (
                            nn+5*vv+min(rr, nn)
                            -2*min(nn, vv+min(rr, nn))
                            +2*rr+2*abs(hh-rr)+2*abs(hh+rr)
                        )
                    if degree != expected:
                        raise AssertionError(
                            f"D+4 {surface} identity failed: {r_state}, {h_state}, "
                            f"{weights}, {degree} != {expected}"
                        )
                if degree <= 0:
                    records.append({"Surface": surface, "RState": r_state,
                                    "HState": h_state, "Weights": weights,
                                    "Degree": int(degree)})
    return records


def summarize(records):
    by_degree = defaultdict(int)
    for record in records:
        by_degree[str(record["Degree"])] += 1
    return {"Count": len(records), "DegreeCounts": dict(sorted(by_degree.items())),
            "Examples": records[:20]}


def main():
    max_weight = 8
    result = {
        "Object": "T121QuasiFiniteWeightedScalingCensus",
        "Master": "GLI[CF385,{1,1,1,1,1,1,1,1,1}]",
        "WeightRange": [1, max_weight],
        "Shifts": {},
    }
    for shift in (0, 1, 2):
        ordinary = scan_ordinary(shift, max_weight)
        p1_surface = scan_surface(shift, "P1", max_weight)
        p4_surface = scan_surface(shift, "P4", max_weight)
        result["Shifts"][str(shift)] = {
            "Dimension": f"D+{2*shift}" if shift else "D",
            "OrdinaryBoundary": summarize(ordinary),
            "P1ZeroSet": summarize(p1_surface),
            "P4ZeroSet": summarize(p4_surface),
        }
        print(
            f"SHIFT={shift} ORDINARY={len(ordinary)} "
            f"P1={len(p1_surface)} P4={len(p4_surface)}"
        )
        for label, records in (("ORD", ordinary), ("P1", p1_surface),
                               ("P4", p4_surface)):
            if records:
                print(f"  {label}_FIRST={records[0]}")

    shift_one = result["Shifts"]["1"]
    shift_two = result["Shifts"]["2"]
    checks = {
        "DPlus2HasTwoCoordinateLogarithms":
            shift_one["OrdinaryBoundary"]["Count"] == 2,
        "DPlus2DenominatorZeroSetsConvergent":
            shift_one["P1ZeroSet"]["Count"] == 0
            and shift_one["P4ZeroSet"]["Count"] == 0,
        "DPlus4OrdinaryBoundariesConvergent":
            shift_two["OrdinaryBoundary"]["Count"] == 0,
        "DPlus4DenominatorZeroSetsConvergent":
            shift_two["P1ZeroSet"]["Count"] == 0
            and shift_two["P4ZeroSet"]["Count"] == 0,
    }
    if not all(checks.values()):
        raise AssertionError(f"T121 quasi-finite checks failed: {checks}")
    result["MinimumPureDimensionShifts"] = 2
    result["Checks"] = checks

    output = Path(__file__).with_name("T121QuasiFiniteWeightedScalingCensus.json")
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="ascii")
    print(f"OUTPUT={output}")


if __name__ == "__main__":
    main()
