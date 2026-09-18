# Source-level rewrite, mixed routing and scalar bubble moments

Actual ChatGPT 6 Pro completed this review after11m45s, read on2026-09-18.
Conversation: https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84
Exact source inspected:217a9a9e05cc1e160f0ace9ceb2db775fecf3404.
This is a retained summary. Pro inspected the chart/regularity repairs, source
binding, virtual integrand adapter, measured one-loop drivers, partial fractions,
mixed topology/frame/signature code and tests. It did not execute our tests or
read the saved66-integral reduction. The later6750b7f8 frame implementation was
not part of that exact revision. No published measured EEC coefficient was used.

## Findings

The three previous repairs are correctly connected. The inclusive chart proves
its original phase-space support and unit delta normalization; the finite-slope
guards cover the remaining branches; and the proof reads the original amplitude
from the same scalar-source artifact whose producer definition it verifies.

The external-only rewrite may be performed before loop tensor reduction, after
the loop-first proof establishes its limit. For an external product P(p), causal
loop integration is linear over external coefficients: L[P N]=P L[N]. Each
partial-fraction product with powers m<=n equals the original product times a
polynomial in cut scalar products. That polynomial is bounded on fixed-scale
massless phase space. Thus each complete loop-integrated external-product group
inherits the original majorant. Merging products with the same rational cores
is bounded by the sum of the original majorants. This is equality of the
regulated limits and their meromorphic continuations, not finite-i0 algebra.

The inspected adapter preserves the required scope: only original unit cuts,
no raised external powers, original off-shell cores in new families, and no
change to virtual prescriptions. The source proof is not transferred to dotted
IBP descendants or to separately split scalar functions whose cancellation was
needed in the original group. Their own causal definitions govern subsequent IBP.

The raw-amplitude decomposition has raw d^D ell measure. Its generated loop
factors remain in the coefficients. Do not additionally multiply this route
by the PaVe pi^(-epsilon) factor. A scalar provider converts its own declared
measure to the actual family measure once. If tensor reduction is used INSIDE
that provider, the normal PaVe conversion belongs only to that internal step.

## Mixed frames

Completing the maximal rank-r cut span with L-r uncut quadratic-propagator
momenta or coordinate axes is sound. Use the rank in integration directions,
not full vectors including external directions. Keep only determinant+-1
matrices and compare unrestricted polynomials, directed cuts, causal signs,
measures and physical conventions. Include the sign of the WHOLE uncut vector,
including its external shift. A virtual loop reversal does not conjugate i0 or
produce a scalar-measure orientation sign. Selecting cut directions first gives
a block-triangular real/virtual change compatible with loop-first integration.

Do not infer momenta from square roots of generic propagator polynomials or
allow external-momentum shifts. Do not quotient uncut vectors by additions of
cut directions: that would discard precisely the virtual shifts being searched.

One completeness caveat remains: choosing only a minimum signature can miss
an actual common candidate when axes or unused auxiliaries enlarge the two
candidate sets differently. Accepted maps remain correct. Prefer covariant
positive-support candidates or compare actual common signatures with explicit
source/representative witness frames. Transitive set overlap alone does not
supply a direct witness to the chosen representative.

## Recommended evaluation order

Collect the routed inclusive combination first, evaluate recognized bubbles
directly, then use targeted IBPs for residual dotted-particle or nonbubble cases.
Do not expand every family's seeds to eliminate integrals whose coefficients
already cancel. Arbitrary positive virtual bubble powers obey

 B_ab(P2;D) = (-1)^(a+b) (-P2-i0)^(D/2-a-b)
   Gamma(a+b-D/2) Gamma(D/2-a) Gamma(D/2-b)
   /[Gamma(a) Gamma(b) Gamma(D-a-b)]

for normalized d^D ell/(i pi^(D/2)). Polynomial numerators require full-D tensor
moments. With the SAME normalized measure, an all-minus bubble is minus the
complex conjugate of the plus bubble; with raw loop measure, conjugate the raw
integral. Keep the actual declared prescription.

For y_ij=s_ij/s, the unnormalized three-body Dirichlet moment is

 integral dPhi3 Product[y_ij^lambda_ij]
 = (4pi)^(2epsilon) s^(1-2epsilon)/(128pi^3 Gamma(2-2epsilon))
   Product[Gamma(1-epsilon+lambda_ij)]
   /Gamma(3-3epsilon+Sum[lambda_ij]).

A pair-invariant bubble supplies an affine-epsilon exponent. Polynomial
numerators give finite sums of such moments. Use a dedicated scalar-insertion
entry point; do not pretend the noninteger loop power satisfies the guarded
tree rational-density interface. Non-monomial remaining denominators can still
need beta/Gauss integration or IBPs. Dotted particle cuts require off-shell
derivatives and cannot be evaluated by the on-shell unit-cut formula.

Universal U8 or other inputs must be identified by actual maps/reductions,
with sufficient Laurent orders determined from their generated coefficients.
