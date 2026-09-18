# Pro20: finite coefficient code and RR completion

Actual ChatGPT6 Pro,16m38s, in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
Source inspected after push:3e81ca9f7c774e356fc5b601147c84ae40805f44.
This is a mathematical/code-review summary, not a verbatim transcript.
No published measured NLO EEC hard coefficient was requested or used.

Pro statically inspected ComplementMassPeriods, GPL differentiation, the finite
DE helper, Gauss/library expansion, phase volumes, measured coefficient assembly,
and affected-row IBP substitution. It did not run our Wolfram tests or inspect
saved RR values. It separately checked a moving-letter GPL and an inclusive
Euler-to-3F2 identity numerically in Python.

## Confirmed bug and repair

The finite DE helper updated `values` inside a pass but used an old `indices`
snapshot for later known-column subtraction. A newly derived value could be
neither unknown nor subtracted. Example: I1'=I3, I2'=I3+I4, known I1=z,I2=3z:
the old routine derives I3=1 then wrongly I4=3 instead of2. Epsilon-tail auditing
cannot detect an omitted algebraic summand. Recompute available column indices
for each candidate row. Revalidate every inferred descendant before acceptance.
Direct Euler/complement values are not implicated. Existing short-coverage
records remain conservatively unresolved rather than inferred to higher order.

The actual campaign audit subsequently found an affected DifferentQuarks basis16
finite coefficient. Its old library record was quarantined; the corrected value
is derived from the full DE row, not adjusted against a reference. The general
same-pass regression now passes. See DifferentialDependencyAudit.wl and the
DerivedMasterRepair run receipt for the actual correction.

## Confirmed conventions

Complement-mass normalization, moving-letter GPL differential signs and finite
coverage are correct. The ratio of actual polynomial-cut Jacobian to
2/(s^2 x1 x2), then the family measure ratio, occurs once. The explicit constant
C0=1/(2048 Pi^5) is checked numerically/exactly. A holomorphic normalization uses
its epsilon-zero value for finite coefficients or the simple-pole residue;
additional shifted coverage is not claimed. Original prescriptions remain bound.
The GPL rule differentiates on a consistently continued contour, not across a
pole/winding change. Coincident letters are combined before division. The Gauss
materializer retains all lower orders; affected-row IBP substitution preserves
unaffected equations and all off-target columns.

## Inclusive scalar route

Prepare the complete generated unmeasured tree source with four particle cuts.
Deleting a measurement denominator from an individual measured master is wrong:
integral dz delta(Az-B)=1/abs(A), and the original physical numerator/weight must
remain. Derive moment weights from the generated tuples, including self pairs.

Candidate universal scalar geometries (not a presumed reduction outcome) are
R4=int dPhi4; R6=int dPhi4/(s134 s234);
R8a=int dPhi4/(s13 s23 s14 s24);
R8b=int dPhi4/(s13 s134 s23 s234).
See https://arxiv.org/abs/hep-ph/0311276 for these universal phase-space integrals.
Their use is separately identified scalar input, not a measured hard function.
For our delta-normalized cuts, multiply the physical R by
familyMeasure/(2Pi)^(4-3D). No virtual-loop iPi^(D/2) conversion belongs here.

Pro independently derived the exact identity

R6=(4Pi)^(3e) s^(-3e)/(2048Pi^5)
   Gamma(1-e)^4 Gamma(1-2e)/[Gamma(2-2e)Gamma(3-3e)Gamma(3-4e)]
   HypergeometricPFQ[{1,2-2e,2-3e},{3-3e,3-4e},1].

Derivation: factor q->p1+K, K^2=s t; inside K let xi=2K.p2/K^2 and
a=(1-cos(theta))/2 along p1. Q1=s t,
Q2=s[1-xi(t+(1-t)a)]. Normalized xi and a measures are respectively
Beta(2-2e,1-e) and Beta(1-e,1-e). With eta=t+(1-t)a, the t,a measure is
t^(-2e)(eta-t)^(-e)(1-eta)^(-e) dt d eta. Integrating t from0 to eta gives
Beta(1-2e,1-e) eta^(1-3e)(1-eta)^(-e). Expand1/(1-xi eta) geometrically
in a convergent domain to obtain3F2. Its excess1-2e is regular near zero.
At zero, R6=(zeta2-1)/(2048Pi^5). Pro checked at e=-1/4 to40-digit precision.
The remaining xi,eta corner has denominator(1-xi)+(1-eta); a two-sector blow-up
suffices if higher coefficients are evaluated through Euler integrals.

R8a/b can first be compressed with the existing normalized angular machinery.
Let A=R.p1,B=R.p2,zeta=(1-cos(psi))/2 and F_e(w)=2F1(1,1;1-e;w).
Then <1/(s13 s23)>=-(1-2e)F_e(1-zeta)/(2e A B), and
<1/(s13 s14 s23 s24)>=-(1-2e)[F_e(zeta)+F_e(1-zeta)]/(4e A^2 B^2).
The paper's Eq4.17 also gives exact4F3/3F2 scalar input. Determine actual orders
from coefficients before implementing more integration machinery.

## Endpoint proof, separate from inclusive moments

The required statement is: after clearing finite regulator poles,
z(1-z) S_RR(z,e) is locally uniformly holomorphic with values in L1(0,1).
Convergence for negative real e, or a finite interior with logarithmic endpoint
growth, does not exclude evanescent higher contacts.

Angular partial fractions reduce the proof to three variables where applicable.
Retain exact Gauss/Appell functions and all introduced divisors. With t=1-z,
X=1-x,Y=1-y, both d=t+X-tX and K=t+(1-t)XY must be resolved: treating d alone
misses t~XY. Angular connection formulas must expose their regulated powers.

Reuse Taylor subtraction/inclusion-exclusion for internal singular faces, but
every bulk/face record must keep its actual measurement map Z(u). Subtraction
acts on H(u,e) phi(Z(u)), not just H. For example, its first normal derivative
is H' phi(Z0)+H Z' phi'(Z0). Stronger-than-logarithmic internal powers can therefore
produce derivative contacts. Logarithmic faces require only constant jets.
If a soft tagged angle is undefined, prove uniform weighted vanishing or retain
the unresolved angle; never assign an arbitrary face angle.

After subtraction certify all bulk/noncontact weighted pushforwards, classify
endpoint-supported faces with their derivative order, and preserve actual
lower-multiplicity measurement faces. Internal poles need not be endpoint deltas.
The proof need not analytically evaluate every finite remainder.

Sum the complete physical final-state amplitude, all diagram/interference
orientations and declared spin/color/flavor factors. Then group actual tuple
limits. For collinear i,j->P, Ei Ek phi(zik)+Ej Ek phi(zjk)->EP Ek phi(zPk),
and Ei^2+Ej^2+2EiEj=EP^2. Check generated local jets against these identities.
Do not assume the singular degree of an isolated diagram/master is physical.
If only a larger RR sum passes the certificate, complete that sum and retain raw
component poles; do not invent a contact partition or cancel raw poles using RV.

Only after this proof, interpolation finite parts E[f] have zero zeroth/first
moments and completion is E[f]+(m0-m1)delta0+m1 delta1. For the complete ordered
energy sum m0=T,m1=T/2, including self pairs. Do not add self contacts again.
The minimal new pieces are an unmeasured scalar-provider layer and measurement-
aware endpoint-subtraction records with actual face maps and derivative orders.
