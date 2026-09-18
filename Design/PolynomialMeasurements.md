# Polynomial measurements and closed-interval distributions

## Separation of responsibilities

The card declares the final-state tuple enumeration, measurement A/B and
weight. `Physics/Measurements.wl` compiles G=B z-A and the absolute unit-cut
Jacobian |B|. Constant observables on the physical unit particle cuts are
standalone inclusive weighted contact integrals. Nonconstant observables keep
their full off-shell polynomial. Source-level on-shell simplifications never
become global scalar-product rules for raised-cut algebra.

`Integrals/CutFamilies.wl` selects a complete independent affine scalar-product
coordinate basis and retains appended dependent polynomials. `Reduction/IBP`
generates all derivative monomial shifts and the defining equation
P(lowering operators)-lowering(polynomial slot)=0 at each seed. Kira receives
explicit equations; ordinary topology zero-sector assumptions are not used
for fictitious independent polynomial denominators. Nonpositive cut powers
vanish, while lowering a double cut retains the unit cut.

The common `ConstructCutDifferentialSystem` path differentiates the exact
polynomial and numerator. Its solution at generic measured variables does
not by itself specify distributions supported at an endpoint.

## Prescription and contact semantics

With C_m(G)=(-1)^(m-1) delta^(m-1)(G)/(m-1)!, pairing in z gives

    <C_m(B z-A),phi> = phi^(m-1)(A/B) / ((m-1)! |B| B^(m-1)).

There is no extra sign. For polynomial B=c product b_j^q_j, the existing
compact parent convergence proof is applied with additional affine inverse
powers q_j(m+2R), where R is the total particle-cut normal derivative order.
The proof includes independent nonnegative mass increments, a quantitative
Gram-boundary majorant, and finite-eta test-function pairing. It does not
evaluate endpoint coefficients or justify noncompact virtual loops. Virtual
loops are integrated first with their causal prescription retained.

An exactly constant measurement z0 contributes delta(z-z0) times its inclusive
weighted integral. This equality is at unit source cuts; its standalone
inclusive IBP descendants are not equated with raised descendants of a
different off-shell measured representation.

## Explicit integrations and endpoint continuation

`InvariantPhaseSpace.wl` supplies normalized massless two-/three-body invariant
moments and a native-cut root integration for a single timelike source. The
root integrator retains every proven simple physical root; unresolved domain
partitions fail. `EulerProducts.wl` expresses supported one-parameter positive
Euler integrals in beta/Gauss functions. These provide explicit physical
master values, and the common library can reuse or publish them.

`Functions/Hypergeometric/EndpointSeries.wl` computes all nonintegrable
endpoint terms before epsilon expansion. It uses the Taylor series at zero
and integer-resonance connection formulas DLMF 15.8.10/12 at one. It retains
worse-than-simple powers, so a vanishing coefficient at epsilon=0 cannot hide
a finite delta derivative. Truncation depth follows the rational prefactor
valuation; all negative powers are summed and simplified at generic epsilon.
The omitted terms have a strictly positive integrability margin near epsilon=0.

`Coefficients/IntervalDistributions.wl` uses

    t^(-1+b eps) Log[t]^k
      = (-1)^k k!/(b eps)^(k+1) delta(t)
        + Sum[(b eps)^n/n! [Log[t]^(n+k)/t]_+, {n,0,infinity}].

Both endpoint models are extended over the full unit interval and subtracted
from the regular remainder. Their finite off-endpoint parts are therefore
retained. A log^k endpoint coefficient needs k+1 additional epsilon orders for
the finite delta term. The common epsilon-tail audit checks these demands.
The present closed-interval constructor rejects powers worse than -1+b eps;
it does not silently discard delta derivatives.

## Common result representation

`FeynFacet-PartonicResult` version 2 with
`DistributionBasis = <|Representation -> UnitInterval, Variable -> z,
Interval -> {0,1}, Endpoints -> {0,1}|>` stores each Laurent row as
DeltaCoefficients[endpoint], PlusCoefficients[endpoint][logPower], and
RegularCoefficient. This is one variable with two endpoints, not two tensor
axes. The common constructor, reader, sums, coefficient maps, scalar rules
and interior restriction support it. Existing single-endpoint tensor-product
results keep version 1. A collinear convolution that assumes an endpoint at
one is not thereby generalized to this two-endpoint measurement basis.

`Projects/MeasuredCurrents.wl` orchestrates these general operations. No EEC
formula, energy-pair expression or reference coefficient is encoded there;
EEC's choices reside in its cards. Current evaluation support covers
massless two-/three-body timelike current decays with supported Euler
geometry and the one-loop two-body interference. This is not a claim of a
solver for every possible quadratic observable or of NLO EEC (alpha_s^2).

## Reducing measurement numerators before expansion

For unit cuts, polynomial division gives `N = Sum[Qi Gi] + R`, where the `Gi`
are measurement polynomials after the affine particle-cut equations are imposed.
Thus `N Product[delta(Gi)] = R Product[delta(Gi)]`. The preparer applies this to
the small card-defined weight times its measurement Jacobian before multiplying
by the amplitude. For the quadratic energy-pair measurement, this reduces the
scalar-product degree from four to two and avoids many unnecessary IBP targets.

The division is over the rational function field in external variables. Newly
introduced external divisors are retained in `ExceptionalDivisors`; they are
not automatically physical singularities. The original unrestricted measurement
and ordinary propagators remain the definitions for dotted cuts. No polynomial
relation restricted to unit cuts is substituted into an off-shell IBP identity.
Endpoint distributions are still obtained by continuing the original regulated
physical integral, rather than extending an unregulated interior identity.

The physical coordinate constructor in `Integrals/Parametric/InvariantPhaseSpace.wl`
supplies scalar two-, three- and four-body integration charts. Its four-body
chart retains the dimensional relative-azimuth measure. It is an integration
representation; it does not claim that a measured master has been evaluated.

## Review and sources

Actual GPT-6 Pro reviewed the cut algebra, convergence qualifications,
standalone constant sectors, normalization, and full endpoint completion:
[consultation record](../External/ChatGPT/Records/2026-09-17/QuadraticMeasurements.md).

- Native nonlinear cuts: https://arxiv.org/abs/1801.03219 and https://arxiv.org/abs/1807.07229
- Resonant Gauss formulas: https://dlmf.nist.gov/15.8
- Full EEC endpoint benchmark: https://arxiv.org/abs/1905.01310, Eq.21

Pro preferred moment reconstruction if direct resonance handling became
costly. Direct continuation finished quickly, so it remains production;
inclusive moments are independent checks, not fitted boundary conditions.
