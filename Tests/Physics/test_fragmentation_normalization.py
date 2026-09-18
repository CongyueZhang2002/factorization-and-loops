#!/usr/bin/env python3
"""Independent normalization identities for the collinear FF derivation.

This tests algebra, physical spin duality, and a convergent-dimensional
phase-space integral. It does not rerun a production hard coefficient.
Run: python3 Tests/Physics/test_fragmentation_normalization.py
"""
import argparse
import json
import time
from pathlib import Path

import mpmath as mp
import sympy as s
from sympy.physics.matrices import mgamma

started = time.perf_counter()
checks = {}


def require(name, passed, **evidence):
    checks[name] = {"Passed": bool(passed), **evidence}
    if not passed:
        raise AssertionError(name)


e, z, pplus = s.symbols("epsilon z pplus", real=True, positive=True)
D = 4 - 2 * e
# Quark: dk+ times the coefficient converting the cut matrix to slash(k).
require("quark_longitudinal_sewing",
        s.simplify((pplus / z**2) * (z**(4-D) / pplus)
                   / z**(-(D-2))) == 1)
# Gluon: two F^{m mu} insertions supply z^-2, distinct from the density.
gluon_cut_to_polarization = z**2 / pplus * z**(-2 + 2*e)
require("gluon_longitudinal_sewing",
        s.simplify((pplus / z**2) * gluon_cut_to_polarization
                   / z**(-(D-2))) == 1)
N = s.symbols("number_of_unobserved_particles", integer=True, positive=True)
prefactor = N * (1-D) + D
require("unobserved_phase_space_2pi_power",
        s.expand(prefactor - (N-(N-1)*D)) == 0)
require("single_recoil_2pi_power", prefactor.subs(N, 1) == 1)

# Exact four-dimensional spin algebra: arbitrary rational non-axis-aligned k.
I = s.I
gamma = [mgamma(i) for i in range(4)]
g5 = I*gamma[0]*gamma[1]*gamma[2]*gamma[3]


def slash(v):
    return v[0]*gamma[0] - sum(
        (v[i]*gamma[i] for i in range(1, 4)), s.zeros(4))


k = [5, 3, 0, 4]
n = [s.Rational(1, 10), -s.Rational(3, 50), 0, -s.Rational(2, 25)]
Sx = [0, s.Rational(4, 5), 0, -s.Rational(3, 5)]
Sy = [0, 0, 1, 0]
Q = [slash(k), g5*slash(k), g5*slash(Sx)*slash(k), g5*slash(Sy)*slash(k)]
dual = [slash(n)/4, slash(n)*g5/4,
        -slash(n)*slash(Sx)*g5/4, -slash(n)*slash(Sy)*g5/4]
gram = s.Matrix([[s.simplify(s.trace(a*b)) for b in Q] for a in dual])
require("physical_quark_U_L_T_duality", gram == s.eye(4),
        GramMatrix=[[str(x) for x in row] for row in gram.tolist()])


# In the fixed-current chart, compare the code's w-endpoint pullback
# with the direct recoil-mass delta Jacobian.
x, zh, w, scale = s.symbols("x zh w scale", positive=True)
xi = s.symbols("xi", positive=True)
out_root = zh+(1-zh)*w
out_w = (1-zh)*w/(xi-zh)
out_delta_jac = -1/s.diff(out_w,xi).subs(xi,out_root)
mapped_born_jac = 1/(scale*(1-x)*(1-zh/out_root))
require("fixed_tag_outgoing_recoil_delta",
        s.simplify(out_delta_jac*mapped_born_jac-out_root/(scale*(1-x))) == 0)
in_root = x+(1-x)*w
in_w = (1-x)*w/(xi-x)
in_delta_jac = -1/s.diff(in_w,xi).subs(xi,in_root)
mapped_born_jac_in = 1/(in_root*scale*(1-x/in_root)*(1-zh))
require("fixed_tag_incoming_recoil_delta",
        s.simplify(in_delta_jac*mapped_born_jac_in-1/(scale*(1-zh))) == 0)
# Unit directions used by the physical spin frame are invariant under
# positive rescaling of the observed momentum; the hard spin insertion
# already contains the corresponding linear momentum homogeneity.
lam = s.symbols("positive_rescaling", positive=True)
u_vec = s.Matrix([1,0,0,0])
k_vec = s.Matrix(k)
direction = k_vec/k_vec[0]-u_vec
rescaled_direction = lam*k_vec/(lam*k_vec[0])-u_vec
require("fixed_tag_spin_frame_rescaling",
        s.simplify(rescaled_direction-direction) == s.zeros(4,1)
        and s.simplify(g5*slash(Sx)*slash([lam*v for v in k])-lam*Q[2]) == s.zeros(4))

# Compare scalar replacement before/after sewing on non-endpoint monomials.
# F(z)=z^a, Z(xi)=xi^b, H(k)=k^r, W=z^-h.
u = s.symbols("u", positive=True)
mellin_rows = []
for h, a, b, r in [(s.Rational(8,3), 6, 4, 1), (s.Rational(5,2), 7, 5, 2)]:
    convolution = (z**b-z**a)/(a-b)
    original = s.integrate(z**(-h-r)*convolution, (z,0,1))
    adjoint = 1/(a-h-r+1)/(b-h-r+1)
    wrong = 1/(a-h-r+1)/(b-2-r+1)
    require("Mellin_adjoint_" + str(h), s.simplify(original-adjoint) == 0
            and s.simplify(original-wrong) != 0,
            Original=str(original), Derived=str(adjoint), WrongFourDWeight=str(wrong))
    mellin_rows.append(str(original))

# Independent convergent radial integrals in the fixed-tag and parent frames.
# Smooth UV cutoff is exp[-(xi*r/L)^2], so its scale is transformed too.
mp.mp.dps = 65
radial_rows = []
for eps, xi in [(-mp.mpf(1)/3, mp.mpf(2)/5),
                (-mp.mpf(2)/5, mp.mpf(3)/7),
                (-mp.mpf(3)/4, mp.mpf(5)/8)]:
    m = 2-2*eps
    L = mp.mpf(7)/5
    omega = 2*mp.pi**(m/2)/mp.gamma(m/2)
    # r=L*t^3 smooths the integrable lower endpoint; integrate both independently.
    tag = omega*3*L**(m-2)*mp.quad(
        lambda t: t**(3*(m-2)-1)*mp.exp(-xi**2*t**6), [0,1,mp.inf])
    parent = omega*3*L**(m-2)*mp.quad(
        lambda t: t**(3*(m-2)-1)*mp.exp(-t**6), [0,1,mp.inf])
    correct = xi**(2*eps)*parent
    relative = abs(tag-correct)/abs(correct)
    omission = abs(tag-parent)/abs(tag)
    radial_rows.append({"Epsilon":str(eps),"Fraction":str(xi),
                        "RelativeError":str(relative),"OmissionRelativeError":str(omission)})
require("real_collinear_radial_change_of_frame",
        all(mp.mpf(row["RelativeError"]) < mp.mpf("1e-45") for row in radial_rows),
        Points=radial_rows)

# Hard action reverses matrix composition under the FF-column pairing.
a_mat = s.Matrix([[1,2],[0,3]])
b_mat = s.Matrix([[2,0],[5,1]])
require("flavor_adjoint_composition",
        b_mat.T*a_mat.T == (a_mat*b_mat).T and a_mat*b_mat != b_mat*a_mat)

# NNLO bare-FF redefinition in Mellin moments. ln(xi) means d/dN.
t = s.symbols("moment")
P0 = s.Matrix([[1/(t+1),1/(t+2)],[2/(t+3),-1/(t+4)]])
P1 = s.Matrix([[2/(t+2),3/(t+1)],[1/(t+4),1/(t+3)]])
beta = s.Rational(9,2)
c = s.Integer(2)
double = (P0*P0-beta*P0)/2
single = P1/2
f1 = c*P0.diff(t)
f1eps = c**2*P0.diff(t,2)/2
new_single = single+c*double.diff(t)-P0*f1
f2 = c*single.diff(t)+c**2*double.diff(t,2)/2-P0*f1eps
# Product Z'_MS F_eps must restore each pole/finite coefficient of M_c Z M_c^-1.
at = lambda mat: mat.subs(t,3).applyfunc(s.simplify)
require("NNLO_conjugation_simple_pole",
        at(new_single+P0*f1-single-c*double.diff(t)) == s.zeros(2))
require("NNLO_conjugation_finite",
        at(f2+P0*f1eps-c*single.diff(t)-c**2*double.diff(t,2)/2) == s.zeros(2))
expected_P1 = P1 + f1*P0-P0*f1-beta*f1
require("NNLO_evolution_scheme_consistency",
        at(2*new_single-expected_P1) == s.zeros(2))
require("NNLO_positive_epsilon_conversion_is_needed",
        at(P0*f1eps) != s.zeros(2))

# An epsilon-dependent density changes finite R and V separately.
r1, r2 = s.symbols("r1 r2")
a2, a1, a0 = s.symbols("a2 a1 a0")
finite = s.expand((1+e*r1+e**2*r2)*(a2/e**2+a1/e+a0)).coeff(e,0)
require("density_change_affects_finite_raw_contributions",
        s.expand(finite-(a0+r1*a1+r2*a2)) == 0)
J0,J1,J2,l = s.symbols("J0 J1 J2 logxi")
finite2 = s.expand((1+2*e*l+2*e**2*l**2)*(J0+e*J1+e**2*J2)/e**2).coeff(e,0)
require("NNLO_fragmentation_double_pole",
        s.expand(finite2-(J2+2*l*J1+2*l**2*J0)) == 0)

out = {"Scope":"Independent identities for bare fragmentation normalization; no production rerun",
       "Passed":all(v["Passed"] for v in checks.values()),
       "CheckGroups":len(checks),"Seconds":time.perf_counter()-started,
       "Checks":checks}
parser = argparse.ArgumentParser()
parser.add_argument("--report",type=Path)
args = parser.parse_args()
if args.report:
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(out,indent=2)+"\n")
print(json.dumps(out,indent=2))
