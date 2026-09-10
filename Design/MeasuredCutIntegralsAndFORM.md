# Measured cut integrals and FORM algebra

The integrated SIDIS calculation uses the same generated-amplitude and
spin-density machinery as other projects. Process data and all outputs live
under Projects/. Reference coefficient files are used only by validation drivers.

## Cut algebra and differential equations

A measurement cut carries no positive-energy condition. Particle cuts retain
their directed momenta. The convention is
C_n(G) = [(G-i0)^(-n)-(G+i0)^(-n)]/(2 pi i)
= (-1)^(n-1) delta^(n-1)(G)/(n-1)!.
Consequently dC_n/dG = -n C_(n+1), and nonpositive cut powers vanish.

Integrals/CutFamilies.wl validates the complete affine scalar-product basis.
Its differential operator fixes the loop components, differentiates the
external momenta through their Gram matrix, and includes the measure prefactor.
An optional external-momentum derivative must reproduce the same Gram variation.

Reduction/IBP/CutFamilies.wl emits L(L+E) total derivatives for each declared
seed. Only mandatory-cut pinches are removed. Kira solves these equations in
user-defined-system mode with config:false; native topology symmetries and
zero-sector assignments are not used. Integral identifiers are opaque one-index
labels mapped back to the full typed integrals. The seed extension is explicit;
the remaining spanning integrals are not claimed to be globally minimal.

DifferentialEquations/CutSystems.wl reduces the requested integrals, differentiates
the resulting basis, and repeats with the union of targets until the basis closes.
It stores all matrices, requested-integral reductions, closure history and flatness
validation. Rational-point checks may be supplied for large systems. Boundary
values are a separate calculation.

The two- and three-particle measured-volume regressions compare the reduced
equations with independent exact Gamma/Beta phase-space evaluations. The
three-particle test additionally checks a negative-index numerator and the
automatic two-variable closure. Native cut-family reductions remain available
only as an explicitly selected diagnostic equation source.

## Card-driven scalar preparation

CreateMeasuredPhaseSpaceDefinition builds forward particle cuts and
G=2 p.k_tag - z (2 p.P), with the standard phase-space normalization
(2 pi)^(N-(N-1)D) (2 p.P). The last final momentum is eliminated by conservation.
Raw cut definitions may be overcomplete; complete families require an invertible
affine scalar-product matrix. A common eta sign is not an independence condition.

PrepareMeasuredCutIntegrand collects the original prescribed denominators and
any scalar gauge denominators, proves the source product using the same compact-
cut certificate, and only then identifies their rational cores. The certificate
acts on the full measurement test function and its normal derivatives. Its
scope is a distribution in z at fixed generic external x, including the z
endpoints. It does not establish uniformity at external x endpoints.

The unit-cut scalar-product constraints are solved once. Polynomial coefficients
are collected without expanding factors independent of the collection variables.
Off-shell source denominators remain available and are used for all dotted-cut
IBP equations.

PartialFractionAffineDenominators uses only the original affine polynomials G_i.
For a relation sum c_i G_i = c_0 != 0, it removes one denominator power in
each branch with coefficient c_i/c_0. For c_0=0 it chooses a fixed pivot j and
uses coefficients -c_i/c_j, lowering i and raising j. The nonpivot power sum
decreases until a denominator leaves the support. External exceptional divisors
are retained; no new loop-dependent hyperplane is introduced.

DecomposeMeasuredCutIntegrand recertifies the increased powers against the
original off-shell source. It completes independent supports with auxiliary
scalar products and stores explicit GLI coefficients. A subset is embedded into
a containing denominator family with zero indices. This is an identity in the
same momenta and directed cuts, not an inferred routing symmetry. Endpoint
distributions are expanded from the complete regulated sum, not by multiplying
singular partial-fraction coefficients by independently expanded distributions.

Scripts/prepare_current_integrals.wls runs these steps from the contribution
card and writes PreparedIntegrands.wl and IntegralFamilies.wl in the component's
Results directory. Both are pre-integration records.

## Three-particle integration coordinates

Integrals/Parametric/MeasuredPhaseSpace.wl implements the recursive factorization
P -> k1 + K23, K23 -> k2 + k3, with S=P^2, J=2p.P, p^2=0 and fixed
z=2p.k1/J. Three coordinates t,y,a lie in (0,1). The invariant masses are

s23 = S(1-z)t,
s12 = S[y+zt-(1+z)ty-2 sqrt(z t(1-t)y(1-y))(1-2a)],
s13 = S-s12-s23.

The light-cone fractions are z,(1-z)y,(1-z)(1-y).
The normalized measures are Beta(1-epsilon,1-epsilon) for t and y and
Beta(1/2-epsilon,1/2-epsilon) for a. Their product multiplies

dPhi3/dz = S/(2 pi) Phi2(S)^2 z^(-epsilon)(1-z)^(1-2epsilon).

Scalar products, exact normalization, angular moments and the full Gram
determinant have independent regression checks. This representation applies
after the joint evanescent angular average. It does not by itself justify
ordinary-i0 removal or give dotted-particle-cut values.

## FORM and BMHV

Interfaces/FORM.wl keeps scalar normalization and propagator objects opaque.
All Lorentz indices live in the ambient D-dimensional space. A separate tensor
P4 satisfies P4^2=P4 and Tr(P4)=4; it is not the rank-two projector onto p,q.
Integrated momenta have independent full-D and physically projected scalar
products. Physical external momenta are fixed by the request.

BMHV lowering uses gamma5 = -i E4_abcd gamma^a gamma^b gamma^c gamma^d/24,
Tr(1)=4 and the Minkowski epsilon convention. E4 has physical slots, and its
pair contraction is minus the determinant of P4. FORM receives no native
gamma5 or four-dimensional trace command. FeynCalc's chiral projectors include
their explicit factor one half. Scheme counterterms are applied later and
never enter this algebra adapter.

Tests include 4(D-8), 4[2D-(D-8)^2], the first nonzero
16(D-4)^2 = 64 epsilon^2 identity, integrated-vector projections,
the physical epsilon norm -24, and generated NLO epsilon coefficients.
The nonchiral RR two-gluon scalar projections were generated in 56.1 seconds
including startup and output; this is not a master-integration timing.
Lossless Mathematica compression reduced their stored file from 82,971,514 to
2,341,477 bytes.

For one gamma5 the default uses the exact grade-four selection identity,
implemented by FORM distrib_(-1,4,...). The ordinary word is rotated only as
part of the complete trace to put gamma5 last. Gamma pairs are reduced only
inside that word; no interval crossing gamma5 is used. Projected pairs are
never treated as full-D Einstein pairs.

For expressions linear in traces, tensor containers allow the actual external
contractions before subset selection. Shared epsilon indices are contracted
with -r! times the remaining projector determinant, including permutation
signs. Repeated vector arguments do not count as summed indices. The generic
4 by 4 determinant waits until after ordinary tracing; shifted vectors remain
aliased until the complete scalar contraction has been collected. Trace products
use separate trace locals, which are hidden after evaluation.

Pro reviews: External/ChatGPT/Records/2026-09-09/09_cut_family_differential_equations.md,
10_cut_symmetries_and_SIDIS_signs.md, 11_FORM_BMHV_algebra.md,
12_measured_convergence_and_parameterization.md, 13_grade_four_BMHV_traces.md,
and 14_FORM_tensor_contraction.md.
FORM source and documentation: https://github.com/form-dev/form and
https://www.nikhef.nl/~form/maindir/documentation/reference/online/online.html.

## Completion boundary

All requested NLO benchmark channels are generated. Full finite LL qg external
comparisons remain unperformed. SIDIS NNLO is not complete: nontrivial RR
integration, RV, VV, NNLO factorization matrices and complete endpoint assembly
are still required. Generated scalar integrands and phase-space volume tests
must not be presented as a completed NNLO hard function.
