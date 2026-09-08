# Stage 1/2 optimizations, 2026-09-05

The general package changes reduce repeated interpolation, scalar algebra,
and export validation. All five existing finite solutions were regenerated
with the same requested epsilon ranges. All-family stage-1/2 regeneration
has not started.

## Measurements

| Computation | Before | After | Ratio |
|---|---:|---:|---:|
| CF48 finite solution, including compressed writing | 62.85 s | 18.62 s | 3.37 |
| CF303 finite solution, including compressed writing | 236.86 s | 190.46 s | 1.24 |
| CF48 source reconstruction of two saved basis entries | 39.07 s | 24.28 s | 1.61 |
| Twelve numerator fits, 81 monomials, 32 outputs | 0.128 s | 0.030 s | 4.31 |
| Complete synthetic three-root reconstruction | 0.714 s | 0.612 s | 1.17 |

The numerator example has the size of four entries in an eight-dimensional
square-root algebra. The three-root example is synthetic. The CF48 entries
are positions (14,1) and (14,5) of its saved V2 basis transformation; the
timing excludes obtaining that transformation. These measurements do **not**
establish a speedup for complete physical triple-root canonicalization.

All processes were restricted to CPUs 0,1,6,7,8,9,18,19, sharing eight cores.
Families run sequentially inside the stage-2 measurement script. Some short
checks and independent measurements shared that allocation, so ratios are
representative timings, not dedicated-machine statistical estimates.
Package loading and exact input reads are excluded. Construction and writing
are recorded separately.

The five solutions contain the same 998 coefficients over 174 coupled-system
master positions. Compressed size is 17,108,051 bytes, versus 36,277,487
previously. Construction took 379.51 seconds, writing 8.24 seconds.
CF303 is 5.97 MB versus 20.26 MB in the matched pre-change measurement.
The recorded memory figures are cumulative Wolfram allocation high-water
marks, not independent physical resident-memory measurements.

## Stage 1

Numerator interpolation uses one monomial matrix and independent row
selection for all epsilon samples at a fixed prime. Multiple right-hand
sides are solved together, in groups of at most sixteen, with a 32 MiB
limit on the joint right-hand side. Every unused kinematic row is checked
for each sample. Singular or insufficient denominators retain the existing
independent reconstruction and denominator augmentation.

For sufficiently large denominator fits, the numerator equations at the
independent construction rows are

    P_c n_a = diag(f_a,c) D_c d.

P contains numerator monomials, D denominator monomials, d the common
denominator coefficients, and a labels a selected output. Eliminating n_a
gives the Schur complement

    [P_v P_c^(-1) diag(f_a,c) D_c - diag(f_a,v) D_v] d = 0.

The code computes interpolation weights by a linear solve, never by
explicitly forming an inverse. Nonsingularity of P_c preserves the
denominator nullspace and projective normalization exactly. This path is
used when the original system has at least 256 unknowns and numerator
unknowns outnumber denominator unknowns. Small systems retain direct
nullspace computation. Subsequent numerator fits retain the original
residual checks.

The first successful epsilon fit is reused. Schedule growth evaluates only
new epsilon values at existing regular kinematic points and retains completed
fits. If a new value makes an old point unusable, the common grid and cached
fits are discarded together. Tests exercise both growth paths.

## Stage 2

- Linear dependence on initial constants is checked by structural polynomial
  degree, avoiding expansion in hundreds of constant symbols. Constant
  offsets, products, inverse powers and undefined functions remain rejected.
- The unused connection-order scan is skipped when a complete entrywise
  order plan is already supplied.
- Each finite epsilon polynomial is expanded once; basis derivatives are
  computed once before the convolution over epsilon orders.
- Scalar coefficient expressions are shared before path substitution.
  Explicit K_i(t) definitions may refer only to earlier K_j(t). Path
  derivatives are included after substitution. All functions and integrands
  are stored, with no coefficient generator or unresolved DE.
- The standalone reader and numerical verifier evaluate definitions in
  dependency order. The exact verifier can expand them. Numerical kernel
  values are reused across epsilon orders.
- Ordinary-point testing avoids duplicate entries and rejects every
  DirectedInfinity form, including ComplexInfinity.

Trials of coefficient abstraction during order determination and exact
algebraic sample tests for nonzero coefficients did not improve full
construction timings. Those changes were removed. No numerical test
replaces the mathematical determination of sufficient epsilon orders.

## Validation and remaining work

Order requirements, basis convolutions and final master-coefficient
expressions agree **exactly** with the saved results. Every defining
integrand was compared at two rational points with 65-digit arithmetic;
differences vanished within numerical precision. This compares the changed
representation with the prior result, not with independent physical values.
Boundary constants remain unevaluated; AMFlow is available for that later
master-value check. A standalone CF269 comparison, loading only the reader,
also agrees with the old export at (13/50,17/50) using 12 quadrature nodes.

There are 229 passing Wolfram assertions, seven passing public-interface
checks (157 exported symbols), and three passing Python execution tests.
New cases include Schur-reduced denominator coefficients, damaged unused
rows, singular denominator isolation, epsilon-grid replacement, scalar
definition cycles, malformed references, and exact/numerical DE identities.

The family driver remains sequential. Parallel family execution, native
quotient evaluation during source reconstruction, and further DE assembly
optimizations remain possible. CF259 (27,23)'s retained roughly 428-second
source reconstruction has not been remeasured: its complete original timing
input is unavailable. CF259 (27,19) has a separate incomplete-ansatz problem.
Neither is claimed solved here.

## Reproduction

The source directory contains pre-change functions, the two-entry CF48 input
and measurement scripts. Reloads set the private Wolfram context explicitly;
loading source into Global invalidates a comparison. Preliminary measurements
made before that correction were excluded.

Run from the repository root:

```sh
taskset -c 0,1,6,7,8,9,18,19 wolframscript -file \
  Design/Stage1And2Speedups_2026-09-05_sources/benchmark-stage2.wls baseline CF48 CF303
taskset -c 0,1,6,7,8,9,18,19 wolframscript -file \
  Design/Stage1And2Speedups_2026-09-05_sources/benchmark-stage2.wls after CF48 CF303
taskset -c 0,1,6,7,8,9,18,19 wolframscript -file \
  Design/Stage1And2Speedups_2026-09-05_sources/benchmark-stage1.wls
taskset -c 0,1,6,7,8,9,18,19 wolframscript -file \
  Design/Stage1And2Speedups_2026-09-05_sources/benchmark-cf48-reexpression.wls
```

Stage-2 scripts use local exact input.wxf records from the family driver;
those caches are not versioned. Outputs go to
`$TemporaryDirectory/feynfacet-stage2-benchmark`. The comparison script takes
old and new result directories explicitly.

[Stage 2 before](Stage1And2Speedups_2026-09-05_sources/stage2-before.json),
[stage 2 after](Stage1And2Speedups_2026-09-05_sources/stage2-after.json),
[CF48 reconstruction](Stage1And2Speedups_2026-09-05_sources/stage1-cf48.json),
[numerator fitting](Stage1And2Speedups_2026-09-05_sources/stage1-numerators.json),
[three-root reconstruction](Stage1And2Speedups_2026-09-05_sources/stage1-rank3.json),
[solution comparisons](Stage1And2Speedups_2026-09-05_sources/solution-comparison.json),
[checks](Stage1And2Speedups_2026-09-05_sources/checks.json).
