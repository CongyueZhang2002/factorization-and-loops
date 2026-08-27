# Codex assessment and addenda: Fable finite-field optimization plan, 2026-08-20

Reviewed against:

- `External/CodexExchange/fable_finite_field_optimization_proposals_2026-08-20.md`
- `External/CodexExchange/fable_deep_rung_benchmark_result_2026-08-20.md`
- `FeynFacet/Private/FiniteFieldStripSolve.wl`
- `FeynFacet/Private/FiniteFieldEpsForm.wl`
- the stored CF254 `(9,7)` modular artifacts and final benchmark record.

## Executive assessment

Fable's main conclusion is sound: the simultaneous finite-field route should remain the robust deep rung, Maple should remain the small-system fast path and independent cross-check, and the exact unspecialized two-variable Pfaffian residual must remain the acceptance certificate.

The optimization list contains several good directions, especially hoisting, sharper support bounds, residue pre-reduction, height-aware normalization, scheduling, and coupled affine rows. The priority order should nevertheless change after measuring one representative CF254 `(9,7)` sample. The dominant cost is modular elimination, not symbolic preprocessing or rational evaluation. The largest missing optimization is therefore to replace the four large eliminations currently performed per regulator sample with one normalized constrained solve with multiple right-hand sides.

There is also a correctness/architecture requirement which should be separated from performance claims: `InterpolateEpsFormStripAffine` currently normalizes each affine sample but interpolates only `canonical["ParticularSolution"]`. It discards the normalized nullspace. That is valid for returning one solution of an isolated strip, but it does not preserve the affine freedom needed by dependent strips in the same row. Production row transport should either interpolate the complete affine state or solve coupled dependent blocks before installing a representative.

## Corrections and additional measurements

The stored hard-fixture result gives the following exact bookkeeping:

- seven primes total, not six: one pilot plus six later primes;
- sample counts `{32, 15, 15, 15, 15, 15, 15}`;
- total modular sampling `7105.76 s` of `7253.96 s` wall;
- gauge unknowns `1936`, free-residue unknowns `208`, total unknowns `2144`;
- generic rank `2128`, nullity `16`;
- first-prime degree histogram dominated by `{3,3}` (`1284` coordinates), with `648` zero coordinates;
- exact verification `57.95 s`, interpolation `15.45 s`, and lifting `2.65 s`.

Thus the sentence in the benchmark note saying that `(9,7)` "used 6 primes" is a bookkeeping typo. The proposal document's "seven in total" is correct.

A representative diagnostic sample at `eps = 1/21`, `p = 1000003`, and numerator offset `{1,0}` gave:

| stage | seconds |
|---|---:|
| recorded polynomial preprocessing | 1.260 |
| finite-field points and matrix construction | 10.486 |
| `MatrixRank[A]` | 10.001 |
| `MatrixRank[A|b]` | 10.154 |
| `LinearSolve[A,b]` | 14.114 |
| `NullSpace[A]` | 13.993 |

The matrix was `2176 x 2144` with `1,867,008` nonzero entries, about 40% density. The timed subtotal is approximately 60 seconds, consistent with the 57.5-second average over the first-prime benchmark round. This is one diagnostic sample rather than a full repeated benchmark, but it is decisive enough to alter the first implementation target:

- approximately 47% of the sample is the separate solve and nullspace computation;
- approximately 34% is the two rank computations;
- approximately 17% is point/matrix construction;
- the currently recorded preprocessing block is approximately 2%.

Alphabet extraction, dlog construction, and the factor census occur outside the existing `PreprocessingSeconds` timer, so M1 should still add a complete outer timing and memory census. However, the current evidence does not support calling O1 the largest constant factor or expecting hoisting alone to provide a several-fold improvement.

## Assessment of Fable's O1--O9

### O1 -- hoist per-sample construction: accept, but lower its priority

The proposed three-stage cache is correct and low risk. It should be implemented because all samples share the symbolic strip, alphabet, dlogs, denominator structure, and coefficient layout. The cache should be fingerprinted by the strip, ansatz support, code/schema version, and variables.

The measured `1.260 s` preprocessing field is small, while some untimed symbolic setup remains to be measured. O1 is therefore a useful follow-on optimization, not presently the leading explanation of the 60-second sample.

### O2 -- straight-line evaluation: accept after elimination reuse

Top-level Wolfram expression evaluation and interpreted row assembly are slow. A straight-line evaluator, packed Horner tables, or a ratracer/FireFly adapter is worth pursuing. Its directly measured target is presently the approximately `10.5 s` point/matrix stage. Once the elimination cost is reduced, O2 will become proportionally more important.

The ratracer/FireFly route should be benchmarked rather than assumed free: conversion and data-transfer costs, field-size support, and whether it can feed the linear-algebra backend without rematerializing Wolfram expressions all matter.

### O3 -- sharp pole bounds: accept, but distinguish denominator bounds from numerator support

Local divisor exponents can remove failed offset probes and certify the denominator. They do not by themselves eliminate the unused monomials inside the rectangular numerator box.

For the recovered CF254 `(9,7)` gauge, multiplying by the common gauge denominator leaves 85 kinematic monomials in each of the 16 entries. The current `{10,10}` rectangle allocates 121 monomials per entry. A posteriori, this is `1360` occupied gauge coefficients versus `1936` allocated coefficients, a 30% reduction in the gauge part. A production version needs a certified Newton-support construction or a grow-on-inconsistency support ladder, not only sharper bidegrees.

### O4 -- residue-compatibility pre-reduction: accept with an affine-state guard

This is promising because the sampler currently introduces all 208 residue coordinates even though only 16 affine parameters survive. A bounded exact reducer is reasonable when cheap. A modular Schur-complement reducer may be preferable when exact `Q(eps)` expressions begin to swell.

The reducer must return an affine parameterization, not commit free residue parameters to zero. Its output should be substituted into the modular system while retaining every parameter that can affect a later dependent strip.

### O5 -- pilot row subset: technically valid, low payoff on the measured fixture

The relevant rank is 2128, not 1937. The sampled matrix has 2176 rows, so only 48 rows, about 2.2%, are redundant at the representative generic point. At point granularity this is essentially one 32-equation kinematic point. Row-subset reuse can still reduce overhead and provide a deterministic square core, but it is not a first-wave speedup for `(9,7)`.

If implemented, omitted equations must be evaluated as residual guards at every sample or at held-out points, with automatic fallback on exceptional primes or regulator values.

### O6 -- exact spot-checks in place of a prime: reject as stated, retain as candidate validation

`AdaptiveValidationMargin` controls regulator samples within a prime; it does not request extra CRT primes. `SolveEpsFormStripFiniteField` attempts rational reconstruction after every prime once `MinimumPrimeCount` is reached and stops at the first exactly verified reconstruction. Therefore the seventh prime was required by the current lift/normalization path; it was not sampled merely for confidence.

Exact rational spot-checks are useful after a candidate has been reconstructed, but they cannot supply missing modulus height or turn a failed rational reconstruction into a candidate. A fresh-prime modular residual is also a cheap rejection test before the full symbolic residual. Prime-count reduction must instead come from lower coefficient height, wider machine-word primes in a suitable backend, or a stronger reconstruction/early-termination strategy.

### O7 -- height-aware normalization: accept with a different score

Normalization can materially change rational coefficient height and therefore the number of CRT primes. Coefficient magnitude modulo one prime is not a reliable height estimator. Pilot candidates should instead be scored using stable structural signals such as:

- regulator numerator/denominator degree histogram;
- number of identically zero coordinates and support size;
- agreement of those signals across at least two primes;
- optionally, partial rational reconstruction of a diagnostic coordinate subset.

The chosen normalization columns must then be frozen across all primes and dependent row blocks.

### O8 -- parallel structure: accept with bounded prime batches

After a serial pilot fixes support, normalization, and regulator degree estimates, `(prime, regulator)` tasks can be scheduled globally. Later primes can run in small concurrent batches, but launching every possible prime at once can waste work when reconstruction terminates early and can multiply the memory footprint of 2k-dimensional matrices. A memory-aware work queue is preferable to fixed nested parallelism.

### O9 -- cross-block amortization/coupled rows: elevate the correctness part

Shared alphabet and diagonal-block caches are straightforward wins. Coupled affine-row solving is more than amortization: it is the route that prevents a normalized representative of one strip from destroying solvability of a later dependent strip. This should be a production-readiness gate, even if the first speed benchmarks continue to use isolated strips.

The efficient implementation is block elimination or a Schur complement over the carried affine parameters, rather than blindly concatenating every dense unknown into one monolithic solve.

## Codex addenda

### A1 -- one normalized constrained factorization per sample

This is the highest-payoff missing item. Let the sampled system be

`A u = b`, with nullity `r`,

and let `P_C` select `r` normalization coordinates for which the nullspace coordinate block is invertible. After discovering `C` on the first generic pilot sample, solve subsequent samples as

```text
[ A   ] [ p  N ] = [ b  0 ]
[ P_C ]           [ 0  I ]
```

with one matrix factorization and `r+1` right-hand sides. The first output column is the normalized particular solution (`P_C p = 0`); the other columns are the normalized homogeneous basis (`P_C N = I`). Residual checks against all original rows certify the result. Exceptional samples for which the constrained matrix loses rank are discarded and replaced.

This removes the separate `MatrixRank[A]`, `MatrixRank[A|b]`, `LinearSolve[A,b]`, and `NullSpace[A]` operations from every ordinary sample. Only the pilot needs an unconstrained rank/nullspace discovery. Based on the diagnostic component times, a 2.5--4x per-sample improvement is a reasonable benchmark target before ansatz reduction; it is not yet a measured production speedup.

This change also makes full affine-row propagation practical. If interpolating all entries of `N(eps)` proves too large, carry the basis modularly into the next block and interpolate only the Schur-complemented quantities actually touched by that block.

### A2 -- incremental regulator sampling from the first prime

The first prime always spends 32 samples before learning that the maximum observed total regulator degree is six. Later primes then spend 15 samples because the current policy uses both `2 degreeSum + 1` and an eight-point validation margin.

Once numerator and denominator degree bounds `(m,n)` are fixed and one denominator coefficient is normalized, a generic rational interpolant has `m+n+1` coefficients. The sampler should:

1. start with a small construction set;
2. attempt all coordinates incrementally;
3. add samples only for unresolved or degree-growing coordinates;
4. validate at two or three held-out regulator values;
5. validate the lifted candidate at an unseen prime and finally with the exact both-variable residual.

For the observed `{3,3}` coordinates, this suggests roughly 9--10 samples per mature prime rather than 15, and an incremental pilot near 10--14 rather than an unconditional 32. The exact residual remains the proof; held-out checks only control when to spend more samples.

### A3 -- certified sparse Newton support with automatic growth

Build a monomial support from the denominator-cleared PDE and close it under:

- the derivative shifts from `d/dx` and `d/dy`;
- multiplication by the supports of the diagonal epsilon-form blocks;
- the forcing and dlog residue supports.

Attempt the smallest closed support first. If the generic modular system is inconsistent or a held-out residual is nonzero, add a neighboring support shell and retry. The full rectangular support remains a guaranteed fallback. The recovered 85-of-121 support provides a concrete regression target, but should not be hard-coded from the answer.

If that support were certified a priori on `(9,7)`, the total unknown count would fall approximately from 2144 to 1568 and the automatic kinematic point count from 68 to about 50. Because elimination is superlinear, the benefit can substantially exceed the 27% reduction in total columns.

### A4 -- direct matrix layout and an appropriate modular backend

The current builder allocates dense Wolfram rows, fills them in interpreted loops, and converts each point block to `SparseArray`. At approximately 40% density, this may be the wrong side of the sparse/dense crossover.

Benchmark at least:

- direct packed dense construction plus one Wolfram modular solve;
- direct compressed sparse construction;
- a machine-word dense backend such as FLINT or FFLAS-FFPACK with one decomposition and multiple right-hand sides.

Black-box Wiedemann methods are more attractive for much larger genuinely sparse systems; they are not the obvious first choice for this 2k-dimensional, 40%-dense fixture. If an external backend handles 61-bit primes efficiently, compare its total wall against the present 31-bit sequence. Wider primes could reduce CRT rounds, but Wolfram big-integer modular arithmetic may negate that benefit without an external machine-word kernel.

### A5 -- exploit the block/Kronecker operator before generic elimination

The gauge part is not an arbitrary matrix. At a sampled point it consists of derivative-basis terms plus the Sylvester-type action

`E_mu . G - G . C_mu`,

while residue columns are dlog scalars times matrix units. Construct and eliminate this block operator directly. Reuse monomial values and the diagonal-block action across both differential directions and across coupled lower blocks. Even when a generic dense backend is retained, this structure can reduce assembly time and make Schur-complement residue elimination cheap.

### A6 -- separate proof, rejection, and reconstruction budgets

Use three distinct layers:

- modular residuals on all sampled and held-out rows for cheap rejection;
- an unseen-prime residual for candidate reconstruction validation;
- one final exact unspecialized two-variable Pfaffian residual as the certificate.

Do not rerun the expensive exact symbolic check merely to decide whether another prime is needed when rational reconstruction has already failed. Conversely, do not describe probabilistic spot checks as replacing the final certificate.

## Revised implementation order

1. **M0: complete instrumentation and freeze the regression fixture.** Add outer setup time, matrix-build time, dimensions, density, peak memory, and every elimination time. Preserve the current exact `(9,7)` result as the acceptance oracle.
2. **M1: A1 constrained multi-RHS affine solve.** Reuse normalization columns after one pilot discovery; verify particular and homogeneous residuals on every sample. This is the first performance implementation.
3. **M2: affine-row production state.** Either interpolate `p(eps)` and `N(eps)` or carry a modular Schur-complemented basis into dependent strips. Do not install a committed strip representative before row compatibility is closed.
4. **M3: A3 sparse Newton support plus sharp local pole bounds.** Keep automatic support growth and the rectangular fallback.
5. **M4: A2 incremental regulator sampling.** Replace the fixed first-prime 32 and later-prime 15 schedules with construct/validate/grow logic.
6. **M5: O1/O2 cached preprocessing and straight-line matrix evaluation.** At this point matrix construction will likely be a leading fraction of the reduced sample time.
7. **M6: O4 residue reduction and structured block elimination.** Compare exact `Q(eps)` and modular Schur-complement variants.
8. **M7: backend and scheduler benchmark.** Dense versus sparse, Wolfram versus external machine-word algebra, 31- versus 61-bit primes, and bounded cross-prime scheduling.
9. **M8: normalization-height search and hybrid dispatcher tuning.** Retain Maple for small estimated systems; route medium/large cases to the optimized finite-field rung.

## Quantitative target

The changes will not multiply perfectly, but the measured anatomy supports a staged target:

- A1: reduce a representative sample from about 60 seconds toward 15--25 seconds;
- A3: reduce `(9,7)` total columns from 2144 toward about 1568 if the 85-monomial support can be certified;
- A2: reduce the seven-prime regulator workload from 122 samples toward roughly 65--75.

A 5--10x single-kernel improvement for the hard strip is a credible benchmark objective, not a promise. Production parallelism should be measured only after the serial algorithm stops repeating eliminations and oversampling regulator values.

The unchanged acceptance condition for every milestone is: exact, unspecialized, both-variable Pfaffian residuals identically zero, with the full affine row constraints respected before installation.
