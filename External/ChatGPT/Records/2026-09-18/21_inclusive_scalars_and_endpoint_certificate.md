# Actual GPT-6 Pro review21

Conversation: https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

Reviewed pushed revision: `939a416d2789ca5e089692f2119af9b4978007eb`.
The UI identified6 Pro and reported11m18s. This record summarizes the response;
it is not a verbatim transcript. No measured NLO EEC hard coefficient was requested.

Pro explicitly inspected MeasuredInclusive.wl, InclusiveFourParticle.wl,
EquationSystems.wl, CutSystems.wl, CutFamilies.wl, LaurentSeriesProducts.wl,
MasterLibrary.wl and relevant tests. This was static source inspection and
mathematical review, not execution or independent verification of actual DQ data.

## Findings and repairs

1. The finite-DE same-pass dependency repair is correct.
2. The inclusive physical measure ratio, complement-mass beta distribution,
   and identified universal R6/R8 scalar coefficients are consistent. R8 geometry
   tests do not independently evaluate their finite coefficients.
3. Scalar providers must verify the actual directed cut frame, integration
   variables and recoil, not just FinalMomenta metadata. A consistently rescaled
   cut delta_+((2p)^2) changes normalization by1/4. The provider now checks the
   canonical unit-Jacobian decay frame and positive total mass.
4. Homogeneity does justify evaluating a rational unit at scale1, but a raw
   uncancelled expression may have a removable singularity there. A finite-value
   check and exceptional rational cancellation now preserve the fast path;
   a dedicated regression passes.
5. A requested epsilon window does not automatically retain all lower poles.
   Each inclusive output row now begins at the minimum of the card lower bound
   and the actual coefficient-plus-master valuations. The full raw coefficients
   must be computed before cancellations are tested.
6. Scalar provenance must survive library storage and reuse. The library now
   stores UniversalScalarSources in provenance and exposes it on reads. The
   inclusive consumer requires it, recomputing old entries when absent. Accepted
   rate companions retain the exact scalar records and contraction coefficients.

## Reduction guidance

Unit-cut candidate sectors and bounded predecessor IBPs are valid. They need not
be a minimal basis: retaining directly evaluated complement powers may lower
spurious epsilon poles. Match geometries before expensive scalar evaluation.
Finite-field ranks select equations; final closed exact target identities are
required, retaining every nontarget column. A bounded miss is inconclusive.
Unmeasured identities cannot be used pointwise in a measured system.

No general rule deletes cut dots. Reverse-unitarity multiplication lowers a dot
only when the corresponding inverse propagator is present. Mass differentiation
needs the full mass-dependent integral. Polynomial IBP vectors tangent to each
particle-cut surface avoid raising particle cuts. Such vectors help reduce
unit-cut numerator sectors but do not alone establish a unit-cut span for an
already dotted target. For measured systems, first establish that span, then
differentiate it; avoid differentiating a large provisional basis repeatedly.

## Sufficient endpoint certificate

Bind the proof to the exact normalized amplitude, original cuts/prescriptions
and full weighted tuple inventory. Construct a complete resolved chart cover
of actual denominator, Gram and angular singularities, including overlaps.
Universal unresolved factorization supplies candidate local tensor kernels;
it does not prove coverage or the generated expression's exact leading term.

After Jacobians and the necessary amplitude sums, prove normal powers are
logarithmic or milder, and prove a positive-power remainder after subtracting
the actual leading coefficient. Retain full D-dimensional spin/color data.
For stronger powers, Taylor-expand the full measured action H(r)phi(Z(r));
its higher jets include derivatives of phi and cannot be discarded.

Derive actual face measurement maps and group equal maps before summing weights.
Soft terms with undefined angles require uniform vanishing of their weights.
Collinear energy weights and all ordered/self pairs obey algebraic merging
identities; compute those from the card rather than hardcoding an EEC answer.
Interior constant face maps require extra contacts or rejection of a two-endpoint
representation.

Apply an inclusion-exclusion forest of the measurement-aware Taylor operators,
keeping every explicit regulator pole and every lower-dimensional face.
Ordinary weak convergence against smooth test functions is insufficient for
weighted L1: nearby delta functions do not converge in total variation.
Therefore each face needs one of these stronger checks:

- Nonconstant face map: use the actual measured coordinate on a chart with a
  certified nonzero tangential Jacobian. Subtract at fixed z and prove a weighted
  L1 monomial majorant for the positive-power remainder. Resolve critical points
  and moving integration boundaries separately.
- Endpoint-constant face map: prove W(r) Z(r)(1-Z(r)) is suppressed by a positive
  normal power, with the remaining variables integrable after their subtractions.

Together these prove finite-meromorphic L1-valued continuation of z(1-z) times
the source and rule out hidden higher endpoint derivatives. Finite subtraction
integrals need not be evaluated to prove this bound. Inclusive moments then fix
the two delta coefficients in linear-endpoint-interpolation convention; self
pairs are already included. A proof for a larger RR sum cannot assign contacts
to its individual pieces, and RV cancellation must not erase raw RR poles.

The complete RR endpoint certificate and measured NLO result remain unfinished.
