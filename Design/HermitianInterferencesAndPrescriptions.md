# Hermitian diagram interferences and ordinary causal prescriptions

## Independent interference calculations

For the common Hermitian spin/color density operator W, define
H_ij = M_j^dagger W M_i. Then H_ji = H_ij^*, with simultaneous exchange
of forward and conjugate virtual integration variables. Positivity of W is
not required: helicity and transversity differences are covered.

`DiagramInterferencePlan` uses the upper triangle when both card sides have
the same selected diagram set and loop order, in the same process/model.
It retains the full rectangle otherwise. 36 diagrams require 666 direct
contractions instead of 1,296. The saving concerns amplitude contractions. Both orientations retain their
own prescribed integral records. Identical propagator definitions share their
Pak polynomial and ordering during family construction; each physical
momentum-map and cut-direction check still runs independently.

`CollinearFactorizeInterferencesPreIBP` saves the scalar physical contraction
before recoil elimination, tensor/dimensional shifts and normalized integral
measures. The reverse numerator and ordinary propagators are conjugated there;
virtual loop lists are exchanged bijectively. Phase-space cuts, positive-energy
orientations and all normalization factors are rebuilt for the reverse setup.
Neither abstract GLIs nor diagonal virtual/virtual integrands are assumed real.
For complex dimension, conjugation is coefficientwise Schwarz reflection,
H_ji(D) = conjugate(H_ij(conjugate(D))).

FeynCalc `ComplexConjugate` does not reverse SFAD eta metadata. FeynFacet masks
ordinary denominators during numerator conjugation and explicitly reverses each
SFAD sign once. Declared complex scalar parameters use the card's
`ComplexParameters -> {g, ...}` and the actual FeynCalc `Conjugate` option.
Unlisted scalar parameters follow the existing formal-real convention.
Complex functions beyond FeynCalc's admitted algebra require a separate
conjugation implementation. Mass and eikonal scalar fields are conjugated too.
When an algebra routine requires common eta signs, `FCLoopSwitchEtaSign` changes
both the inverse polynomial and its prefactor; it does not discard i0.

The production queue and Born assembly use this interface. Both ordered pair
artifacts are written, and each is summed once. No off-diagonal multiplicity
is added downstream. The one-loop/tree NLO path retains its existing single
orientation plus conjugate. A queue task is resumable only if both of its
required artifacts validate. Add the final CLI argument `Full` to
`Scripts/regenerate_pairs.wls` for an independent full-grid diagnostic.

## What permits removing an ordinary i0

A denominator sign bound alone is insufficient. `Integrals/Convergence.wl`
owns the single compact-cut convergence proof. Ordinary-i0 removal, Laurent
bounds and dimensional recurrences all call `cutIntegralConvergenceCertificate`
and consume the same `CutIntegralConvergenceCertificate` record. The separate
unit-cut prescription proof has been removed. `Integrals/Prescriptions.wl`
contains only the public scope checks and the pre-IBP adapter.

The sufficient criterion admits one compact connected phase space with L+1
positive-energy cuts, positive integer cut powers and finite integer ordinary
powers. Negative ordinary indices give polynomial numerators. It checks:

1. Exact conserved recoil, independent real affine cut routing, nonnegative
   cut masses and a physical point strictly above threshold.
2. A nondegenerate Lorentzian external frame and a future timelike total cut
   momentum. Symbolic assumptions must prove the physical inequalities.
3. Every positive ordinary denominator can vanish only on the actual integral
   Gram boundary **throughout independent nonnegative cut-mass increments**.
   Only fixed external null vectors can anchor null decompositions. Cone and
   rank calculations are inexpensive witnesses of this one criterion; a
   bounded real-algebraic decision checks the same criterion when needed,
   in independent loop scalar products. It retains every original polynomial,
   including redundant factors; it never divides by an unproved symbolic
   coordinate determinant.
4. A constant nonsingular cut-elimination Jacobian in scalar products.
   Nonzero external denominators must be proved nonzero on the requested
   domain; not being identically zero is insufficient. Affineness is checked
   by exact reconstruction, with a Boolean result. Cut rays must match their
   off-shell polynomials, and symbolic external-basis pivot minors must be
   nonzero throughout the domain.

For external Gram E and loop/external scalar-product matrix P, the transverse
Gram is T = P E^-1 P^T - G_loop. Its determinant G occurs in the actual measure
with exponent (D-d_ext-L-1)/2. No four-dimensional loop Gram identity is imposed.
The proof checks that a dependence survives restriction to the momentum span
actually used by the integral; unused external angular directions are integrated
out with a recomputed measure in the Laurent-bound calculation.

Compact semialgebraic domination suppresses the finitely raised denominator
powers and lowered Gram powers from cut-mass differentiation at sufficiently
large Re(D). The required traces on moving Gram and positive-energy boundaries
then vanish. For real Q and positive integer n,
|Q+i sigma eta|^-n <= |Q|^-n, uniformly in positive eta.
Take ordinary eta to zero and the required finite cut-mass derivatives in that
convergence region, then continue dimension meromorphically. Do not
differentiate an artificial theta function at the mass-parameter origin.
The certificate records the total cut normal-derivative order; unit cuts have
order zero. No numerical convergence dimension or master evaluation is needed.

`CertifyOrdinaryPrescriptionRemoval[source, master]` uses this shared proof.
Production pre-IBP reduction checks the whole polynomial-numerator term before
rational partial fractions, retaining `OriginalPrescribedPropagators` and
`SourceOrdinaryPrescriptionCertificate`. FeynCalc's subsequent +1 eta field is
an algebraic placeholder. Actual master definitions are checked individually.
A source certificate does not automatically certify every GLI in its family.

Outside certified removal, a proposed partial-fraction identity is checked with
finite ordinary eta and independent cut regulators before acceptance. This
prevents a common-eta convention from erasing a pinch: 1/(x+i eta)-1/(x-i eta)
cannot be replaced by zero. The check is bounded to three seconds and fails
closed when unresolved. Momentum shifts and scaleless removal are explicitly
disabled when ApartFF sees only the denominator product.

## Explicit limits of the certificate

The status is `CertifiedGenericKinematics`. It is **not** a proof of equality
as distributions in observed endpoint variables, and cannot determine possible
endpoint contact terms. `RequireOrdinaryPrescriptionCertificate[definition,
"EndpointDistributions"]` rejects this status. The representation/definition
constructors also enforce that scope when it is requested through
`PrescriptionScope -> "EndpointDistributions"`. A generic representation must
not be used to infer a complete causal endpoint distribution solely from this
certificate. Stronger smearing/boundary proofs are separate work.

Repeated cuts are handled by the same mass-deformation proof as unit cuts.
Unknown geometry, unproved inequalities, interior resonances, noninteger
indices and virtual integrations remain unresolved. A failure is not a proof
that removal is impossible. Original ordinary prescriptions remain in the
definition, and the Baikov expression retains its finite positive eta limit.

The two-body analytic evaluator additionally verifies the actual quadratic
core, including an overall negative scale. This fixes an exposed sign error
for equivalent negative-polynomial propagator representations.

## Sources and review

- [FeynCalc SFAD prescription convention](https://feyncalc.github.io/FeynCalcBook/StandardPropagatorDenominator.html).
- [FeynCalc exact eta-sign change](https://feyncalc.github.io/FeynCalcBook/FCLoopSwitchEtaSign.html).
- [Heinrich, sector decomposition and phase-space measures](https://arxiv.org/abs/0803.4177).
- [Gehrmann-De Ridder, Gehrmann and Heinrich, four-particle phase space](https://arxiv.org/abs/hep-ph/0311276).
- The beam-aware zero-set argument above is our explicitly scoped proof; the
  cited decay phase-space examples alone do not establish its beam-collinear
  or observed-endpoint claims.
- Verified GPT-6 Pro implementation review: `External/ChatGPT/Records/2026-09-08/10_interference_and_convergence_implementation.md`.

## AMFlow real-emission interface

AMFlow's phase-space loop convention is Prescription -> 0. Its separate Cut
mask encodes on-shell distributions; this is not an interface for choosing
ordinary +i0/-i0 signs on real-emission propagators. Retaining an unresolved
ordinary prescription in our symbolic definition is therefore not an AMFlow
numerical fallback.

The exporter rejects an explicitly nonzero PropagatorPrescriptions entry in
any active ordinary slot supported only on phase-space loops. It checks
nested records and every master in a batch before AMFlow is loaded. Dotted
cut powers themselves remain supported. Numerator/absent ordinary slots
do not require an i0 limit.

A bare family explicitly requested in AMFlow's Prescription -> 0 convention
can still be evaluated in that convention. This does not certify equality
to a separately prescribed physical source. An unresolved source requires
an applicable removal proof, a justified reduction to compatible integrals,
or a different numerical method. A source certificate never overrides a
master definition that explicitly retains a real-emission prescription.

Tests/Transport/t_amflow_real_prescriptions.wls checks 11 interface cases
without launching numerical integrations. The vendor convention is documented
in examples/automatic_phasespace/run.wl and examples/feynman_prescription/run.wl.

## Retrospective audit of the computed processes

The earlier audit established that the computed masters had valid justification,
although the then-new checker did not reuse the stronger pole-bound proof.
That implementation gap is now removed: all 345 retained NNLO masters,
including 86 doubled-cut masters, and all 91 generic family templates pass
the single shared implementation. All twelve UU/LL NLO real-master entries
also pass it. TT source numerators are zero.

The historical audit and endpoint argument remain at
Projects/ppHX_UU/NNLO/qqp-qqp/Results/DoubleReal/Validation/PrescriptionAudit_2026-09-08/README.md.
GPT-6 Pro reviewed the consolidation; its symbolic-coordinate and Jacobian
findings were corrected and covered by regression tests. See
External/ChatGPT/Records/2026-09-08/14_shared_convergence_certification.md.
Current implementation checks are in the process-owned
Results/Validation/SharedConvergence_2026-09-08 directories. The source-level
recoil-endpoint argument remains explicitly scoped and is not an automatic
distributional guarantee of the generic certificate.
