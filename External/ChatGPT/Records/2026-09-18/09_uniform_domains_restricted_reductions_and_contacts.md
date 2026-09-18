# GPT-6 Pro — uniform integration domains, restricted reductions and contacts

Actual GPT-6 Pro reviewed pushed commit
b9b0daf7dd29ed254b4faad26f4aff1457fa6db3 for 18m25s in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
This was static source inspection, not execution of tests or timings. No published
NLO EEC hard coefficient was consulted. Source inspection covered the measured
loop constructors/evaluator, GPL rational decomposition and inversion, CutSystems,
native reduction resumption, propagator descriptors and scalar endpoint helpers.

## Findings and bounded repairs

The original prescribed-product partition and exact reconstruction are correct.
For one product, the external-factor modulus bound permits scalar cancellations
inside its coefficient, but not unproved cancellation between different products.
Nonnegative integer endpoint powers supply a regulator-independent integrability
margin after finite poles are cleared. This removes external prescriptions after
causal loop evaluation; it never removes virtual-loop prescriptions.

Endpoint checks alone did not exclude arbitrary interior poles in measurement
weights or scalar coefficients. The permanent repair partitions the energy
interval into two halves and verifies every smooth factor on each entire closed
half, including rational denominator units and supported real Gauss/Appell
branches. A weight with an interior double pole now fails. The three physical
RV groups passed this stronger check, taking 37.02 s including startup.

Negative-real infinite-argument polylogarithm inversion has the complete correct
Bernoulli polynomial and reciprocal sign. GPL collection before size limits is
lossless. Normalized scalar functions, root Jacobians, weights and generated
state factors are each included once.

Restricting the evolving DE span is valid, but replacing only the returned
reduction's Masters field leaves broader Targets/Rules inconsistent. The return
record now restricts Targets, Rules and Masters together to requested integrals
and closed-basis derivatives. The broader native solve remains in its workspace.
InitialReduction now compares the shared cutDefinitionConventions plus topology
and directed cuts. Twelve regression assertions pass, including an unrelated
retained family and a changed branch convention. The already-running RR process
loaded the preceding implementation and must be re-imported through the updated
constructor before accepting its final DE record.

Row reuse previously bound the card recipe but not a corrected prepared density
under unchanged cards. The repair stores the exact row input in the existing
binary metadata companion, compares it directly, and validates format, full
Laurent coverage, orientation and the complete integration-domain proof. No new
content hash was added: the user's no-hash instruction takes precedence over
Pro's suggested fingerprint. Native equation resumption and scale restoration
were accepted; optional hash-manifest hardening was not adopted.

## Contact-order construction

Use the full original weighted pushforward, not a finite-interior power fit.
Resolve every corner and edge of the energy/measurement square, including sector
ratio endpoints and artificial seams. For the mixed corner, the two ordinary
positive sectors have y=t*u or t=y*u, with their respective Jacobians; their
interiors are disjoint and there is no factor of two. Pull back the measured
variable and whole test function with the density.

If z(1-z) times every original prescribed component is integrable uniformly near
epsilon=0 after clearing its finite regulator poles, the remaining ambiguity
has only ordinary deltas at z=0 and z=1. Higher derivative contacts are excluded
by multiplication by z(1-z). Failure of this sufficient bound is inconclusive;
it can require exact cancellations or further resolution.

The implementation uses the existing general positive-sector chart constructor
on four half-squares, with a closed-chart analytic-factor check. All 24 actual
weighted RV charts passed in a 22.93 s verification of their retained resolutions.
The earlier exploratory resolutions took 114.52 s. These are separate timings,
not a full production solve. The card-owned contact-order driver subsequently completed in 181.93 s, saving all
24 chart proofs. Card-derived inclusive moment weights were added separately;
their exact tuple sum gives 1 and 1/2 without an inserted observable-specific factor.

Given a chosen interior extension K and its moments m0 and m1, the independently
generated inclusive RV rate T fixes c1=T/2-m1 and c0=T/2-m0+m1. If K excludes
self pairs, c0 already includes them: do not add their separate sector again.
The inclusive rate must have the same normalization, state/flavor counting,
coupling and orientation. No inclusive rate or contact coefficient has been
inserted from an EEC reference.

Conjugate the fully normalized scalar Laurent density before GPL integration,
after proving its real Log/PolyLog branches. This retains phase-times-pole terms
and avoids an unsupported rule that every GPL is real. The code now does this;
all three finite Hermitian coefficients agree with direct scalar-density
quadrature to more than 30 digits (37.39 s supervised). The completion choice is
part of the exact row-reuse identity.

The new closed-domain, contact-order and metadata implementations postdate the
reviewed revision and need the next implementation-specific review after push.
Full RR physical masters, the inclusive RV moment and final assembly remain.
