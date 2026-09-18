# Actual GPT-6 Pro review22

Conversation: https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

Reviewed pushed revision: fa012491cb8739b4d70d34f16f8d2a08602e29c7.
The UI identified6 Pro and reported9m12s. This is a faithful summary, not a
verbatim transcript. No measured NLO EEC hard coefficient was requested or used.

Pro inspected SeedSelection.wl, MeasuredTaylorSubtractions.wl, EquationSystems.wl,
CutFamilies.wl, InclusiveFourParticle.wl, MeasuredInclusive.wl, MasterLibrary.wl
and relevant tests. It did not execute tests or inspect/alter either running job.

## Accepted implementation and conservative limitations

The basis search preserves every equation column, including nontarget integrals.
Finite-field remainder support is only a search aid. Final acceptance uses a
closed exact reduction whose target images lie wholly in the candidate span.
Identity-only native sampling correctly leaves its targets unreduced, not zero.
The physical cut-frame, scale-specialization, all-pole storage and warm provenance
repairs are present and correct.

Three improvements were identified:

- RequiredProvenanceFields must also be enforced on a fresh provider before
  storage/return. This is now repaired and has a regression assertion.
- A predecessor stall at depth0 should try configured deeper shells before
  failing. The bounded search now tries the remaining depths through2.
- Candidate numerators should be sector-local: a denominator absent from the
  current support may be used as a numerator even if another sector uses it
  positively. This is now the default. Prefer targeted numerator enlargement
  and isolated ordinary dots before a Cartesian increase of all powers.

The measured Taylor identity is algebraically correct, including factorials,
the derivative of the test function and overlap poles. Its false physical-proof
flags are necessary. Keep each complete remainder together during integration;
its separate summands may diverge. Test-function derivatives need the usual
(-1)^j sign when later converted to delta derivatives.

## Constructive cut-compatible vector algorithm

Use unrestricted independent full-D scalar products, applying only external
kinematics. Never impose particle cuts or four-dimensional Gram identities in
the vector construction. Seek momentum-space vectors
V_i = sum_A c_iA(x) q_A, with q_A an integration or external momentum.

For each protected polynomial G_b separately solve
sum_iA c_iA (q_A . partial_i G_b) = f_b G_b.
Membership only in the joint cut ideal is insufficient: cross-cut terms can
transfer dots. A dependent measurement polynomial must remain its actual
polynomial in independent scalar products, not an independent coordinate.

Degree0/1/2 polynomial ansatzes for c and f give homogeneous sparse linear
systems over the external rational-function field. For three integration
momenta, one external momentum and five protected cuts, degree1 has at most170
unknown coefficients; degree2 at most935. Every adopted vector must pass exact
off-shell tangency residuals. Clear external denominators and retain their loci.
No loop-dependent division is allowed. Higher-degree searches should quotient
out polynomial multiples of already known vectors.

The full divergence is sum_iA D_iA c_iA + D sum_i c_ii. The coefficient-derivative
term cannot be omitted. Insert this divergence as a polynomial numerator, not a
scalar coefficient at zero integral shift.

For a protected normalized cut, V C_n(G) = -n f C_n(G). Generate this unchanged-
power cofactor directly, particularly for a dependent measurement polynomial.
Unprotected propagators retain the ordinary raised-index derivative, and the
existing dependent-denominator identities remain in the equation system.

A useful exact massless starting field varies p_i by W and p_j by -W, with
W=(p_i.p_j)r-(r.p_j)p_i-(r.p_i)p_j. It preserves momentum conservation and obeys
delta(p_i^2)=-2(r.p_j)p_i^2, delta(p_j^2)=2(r.p_i)p_j^2. It need not preserve a
measurement cut. The general nullspace construction also covers massive cuts.

Measurement differentiation remains separate:
partial_z C_m(M)=-m(partial_z M) C_(m+1)(M).
Homogeneous tangency does not eliminate this term. A future inhomogeneous lift
(partial_z+V)G_b=f_b G_b is a separate exact construction.

A bounded nullspace is not the complete syzygy module. Dot avoidance is not dot
removal. Momentum-space vectors provide the correct full-D lift and divergence;
arbitrary scalar-coordinate velocities do not. Existing forward-cut continuation
assumptions remain required, and additional acceptance boundaries need their own
boundary terms or tangency conditions.

## Implementation after review

CutCompatible.wl now implements the bounded polynomial nullspace, exact cofactor
certificates and complete divergence. CutFamilies.wl inserts polynomial divergence
and protected cofactors without increasing cut powers. Five assertions include
comparison with ordinary total derivatives of polynomial-shifted seeds.
An actual four-particle family produces24 vectors protecting particles, and12
protecting all cuts. These are vector constructions, not a completed reduction.

The mixed-vector three-particle benchmark reaches its exact scalar span in one
29-row search rather than three searches ending at114 rows. This is a small
algorithm test, not a claimed full-EEC speedup. The measured EEC calculation
still needs exact basis closure, physical masters and endpoint completion.
