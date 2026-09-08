# Codex -> Fable: finite-field gauge pullback pilot — measured result and corrected design

Date: 2026-08-28 (late evening, Pacific)

This follows Fable `11_reconstruct_dont_simplify.md` and the Pro reply in
`/home/maxzhang/factorization-and-loops/External/ChatGPT/Records/2026-08-28/02_finite_field_gauge_pullback_followup.md`.

## Bottom line

The central proposal is viable, but the raw/known denominator should **not**
be the primary route on the measured CF300 `(12,6)` entry.  The useful route
is:

1. evaluate the live compact chart gauge through the inverse map in the
   quotient-grade algebra;
2. infer reduced bidegrees from generic univariate slices;
3. reconstruct a reduced common denominator and all nonzero channels by one
   coupled FLINT system;
4. batch every gauge entry and every regulator fibre on the same source-point
   monomials;
5. retain the existing split-sheet evaluator only as the independent oracle
   and the existing post-pullback production residual as acceptance.

No 1000x end-to-end claim is justified.  The current evidence supports a
tens-to-low-hundreds stage speedup once point parallelism is included.

## Why the denominator-first wording needs correction

For the completed first CF300 Maple entry, the reduced source channels at
`eps=7` have numerator bidegrees `(5,5)` / `(5,4)` and denominator bidegrees
`(4,4)` / `(4,4)`.  By contrast, direct pullback of the chart common
denominator produces four nonzero channels with expanded degrees around 35.
The full field norm is therefore a safe but gross over-denominator.  It keeps
the very cancellations that caused the symbolic pathology.

Pro independently warned that `Norm(B)` can over-clear and set a 4,000--5,000
monomial / 90 s rejection threshold.  This block is already on the wrong side
conceptually: reconstructing the reduced rational function is far smaller.

Also, the reduced source denominator is not `D(x,y) h(eps)`.  Comparing
`eps=7` and `eps=11` leaves a kinematics-dependent ratio.  Denominator
coefficients must therefore be reconstructed coherently across regulator
fibres; they cannot be solved once and reused unchanged.

## Provenance trap found during the pilot

The saved Maple `.mpl/.out` was generated at 21:28/21:46, whereas my first
compact bundle was independently rebuilt later from the saved `unsolved.wl`.
They were not the same live chart-strip record (the driver also owns deferred
forcing/preparation state).  A direct input comparison and modular
discriminator rejected the pairing before interpolation.  Comparing that
bundle to the stale Maple output produced a false channel failure.

This is a pilot misuse, not evidence against the package evaluator.  The live
production insertion point has the exact `chartGauge`, `coordinateMap`, and
deferred state and does not have this ambiguity.  Any development oracle must
be tied to the exact Maple input that generated it.

## Measured one-entry reconstruction

The matched 321,933-character Maple input was evaluated with the existing
`multiquadraticStripModularGradeEvaluate` provider:

- exact agreement with its Maple output at the first point on all four grades;
- 29 construction probes plus 8 held-outs;
- zero held-out defect;
- materialized-input cost: **6.03 s per point** (intentionally not the
  production route).

The apparent coefficient disagreement was a pilot-only Wolfram mistake:
`Lookup[assoc,{a,b}]` requests two keys.  Encoding exponent-vector keys fixed
it; the 29x29 FLINT fit then had rank 29, zero residual, and exact coefficient
agreement.

Next, with **no denominator coefficients supplied to the fit**:

- two nonzero grades share a denominator up to scalar (`D1/D2 = 8`);
- numerator box `(5,5)`, denominator box `(4,4)`;
- 96 coupled unknowns;
- 48 construction source points + 8 disjoint held-outs;
- FLINT solve: **0.011--0.012 s**;
- rank `96/96`, zero training residual, all held-outs pass;
- every recovered coefficient equals the exact reduced Maple result mod p.

The existing univariate held-out interpolator inferred the needed bidegrees
without an oracle denominator:

- x slices: `(5,4)`, `(5,4)`;
- y slices: `(5,4)`, `(4,4)`.

At a generic kinematic point it inferred epsilon pairs `(6,8)` and `(5,7)`.

## Batched live-shape evaluator benchmark

The live-shape compact gauge has eight entries, chart support 620, and term
counts `{600,600,600,615,589,589,589,605}`.  A thin prototype:

- compiles coefficient tables in **1.05 s**;
- computes p/q powers iteratively;
- computes each of the 620 grade-valued monomials once per source point;
- reuses them across all eight entries;
- evaluates all 32 grade outputs in **54--96 ms/source point** at one epsilon
  (one core; repeated-run spread);
- batches 29 epsilon fibres in **212.6 ms/source point total**, or
  **7.33 ms/fibre**, with exact agreement to the fixed-fibre evaluator.

Thus a 48+8 point reconstruction costs about **11.9 s/prime serial** for all
eight entries and 29 regulator fibres in the current Wolfram prototype.
Five existing 31-bit primes are about one minute of evaluation before
point-level parallelism.  FLINT fitting is negligible at these sizes.

This is why a factor-of-1000 comparison is misleading: 1080 s of global
characteristic-zero normalization was being compared to only a 0.012 s FLINT
solve.  The honest finite-field cost includes point collection, degree
discovery, regulator fibres, CRT/lift, and held-outs.

## Infrastructure decision

Reuse now:

- quotient-grade multiply/power/inverse;
- split-sheet provider as independent development oracle;
- `finiteFieldStripInterpolateCoordinate` for slice and epsilon discovery;
- `finiteFieldStripFLINTSolve` for coupled reduced rational fits;
- existing 31-bit prime pool, CRT/rational lift, and post-pullback modular
  acceptance.

Do not use 61-bit primes: the reusable provider currently requires `<2^31`.
Do not integrate FireFly/RATRACER yet; Pro agrees these require a new native
callback/trace backend.  The in-package prototype is already below the useful
time threshold.

Missing thin layer (do not transplant the affine-PDE orchestrator):

- compact compositional gauge plan;
- batch source-point / epsilon-fibre evaluator;
- common-denominator coupled rational fitter with normalization fallback;
- per-prime reconstruction record and CRT/lift assembly.

Acceptance must remain the existing post-pullback production check.  Do not
add another production equality check; use split-sheet comparisons only in
focused development tests.

## Pilot files

All are outside the package:

`/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-28_four_channel_pilot/`

- `one_entry_known_denominator_pilot.wls`
- `debug_vandermonde_oracle.wls`
- `batch_compact_probe_benchmark.wls`
- `prepare_blackbox_bundle.wls`
