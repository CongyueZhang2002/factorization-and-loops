# Round 8, agent M: stage-1 (canonicalization) speed campaign

**Mandate (user):** several-fold / order-of-magnitude speed-up of the off-diagonal block solvers
on hard blocks, using the transport lessons; exact acceptance contract unchanged.
**Rules:** every kernel through the seat launcher; 300 s caps for iteration, 900 s for at most a
few measurement runs; no commits; every number below is a launcher wall time or a stage timer
printed by the solver itself.  Working files: `scratchpad/round4/M/r8/` (probe
`stage1_probe.wls`, logs, per-run summaries under `runs/`).

## 1. Where the time went in the campaigns (measured from the records, no kernel)

Sector states of `FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean` (`StripSolvers`
entries carry per-prime sampling / interpolation / lifting seconds):

| family | strips | methods | inner finite-field seconds, whole family | costliest strip |
|---|---:|---|---:|---|
| CF300 | 66 | 27 ZeroForcing, 9 RationalFrame FF, 28 RationalChart FF (Kallen2/3/23, Bilinear115) | **1.7 s** | 0.3 s |
| CF303 | 276 | 128 ZeroForcing, 73 RationalFrame FF, 75 RationalChart FF | **33.6 s** | (21,2) 3.4 s |

So the finite-field affine solve itself (sampling, interpolation, lift) is not where the triple
roots were slow.  The campaign logs (`run.log`, per-stage lines) put the cost in the
chartless strips and in construction:

| strip | stage | seconds | outcome |
|---|---|---:|---|
| CF303 (25,18) | block equation: deferred materialize (interning 86 operands: 1467 s of it) | 1477 | |
| CF303 (25,18) | candidate letters: forcing dlogs | 1514 | |
| CF303 (25,18) | integrability screen | 121 | |
| CF303 (25,18) | direct provider (SplitBranch, 18836 unknowns, 48 one-forms, support 4661) | 74 | |
| CF303 (25,18) | inner solve (regulator reconstruction) | 3245 | `ModularStructureUnstable` (mission 4910 s, EXIT2) |
| CF300 (12,1) | prepare: exact bundle denominator refinement | 486 | then `RegulatorMaximumTotalDegreeExceeded` |
| CF300 (12,1) | deferred provider support ladder | 20 | |
| CF300 (12,7) | block equation construction (sector budget 1800 s hit at 303 s of it) | >303 | `StripBudgetExhausted` |

Every finite-field-route strip on the chart route was sub-second inside the solver; what the
chart route pays is symbolic (see 2).

## 2. The fixture ladder (production route: `SolveEpsFormStripInFrame` with the driver's
options, replicated by `stage1_probe.wls`; native FLINT backends built)

| rung | input | route taken | wall (launcher) | stage timers (solver's own) |
|---|---|---|---:|---|
| R1 | CF300 (12,9), sector-dir input with deferred preparation (118 kB) | RationalChart/Kallen3Bilinear115/FF | **51.3 s** (55 s seat) | ChartPullBack 12.3; inner solve 25.8; acceptance gauge pull-back 13.2 (source gauge substitution 11.6, leafCount 2981) |
| R2 | CF300 (12,9), frozen symbolic input (2.5 MB, no bundle) | same | **162.8 s** (167 s seat) | ChartPullBack 76.6; inner solve 48.6 (leafCount 421642); acceptance 37.5 (substitution 25.8, leafCount 14740) |
| R3 | CF300 (12,1), chartless, deferred bundle | multiquadratic direct route | measurement run (900 s cap) -- see 3 | |
| R4 | CF300 (12,7), chartless | | measurement run (900 s cap) -- see 3 | |
| ceiling | CF303 (25,18), 43 MB input | | not runnable under 900 s in any single stage (table in 1) | |

All four runnable rungs take the chart route on today's code -- including CF300 (12,1), which
the Aug-30 campaign sent down the chartless multiquadratic route (rank 3, `DirectRootChannel`,
died in `RegulatorMaximumTotalDegreeExceeded` after a 486 s denominator refinement); today it is
a rank-1 chart strip.  So the runnable ladder measures the production chart route; the chartless
route's costs of section 1 stand as the campaign's record and were not reproducible under 900 s.

| rung | wall | ChartPullBack (materialize + Jacobian normalization) | InnerSolve (prepare + held-out sampling per prime) | GaugePullBack (normalizer) |
|---|---:|---|---|---|
| R1 (12,9) prep. | 51.3 s | 12.3 (1.6 + 10.3) | 25.8 (4.4 + 3 x 5.5-6) | 13.2 (11.4) |
| R3 (12,1) prep. | 49.8 s | ~14 (9.8 + ~3) | 11.0 | 14.8 (12.4) |
| R2 (12,9) frozen | 162.8 s | 76.6 (symbolic pull-back) | 48.6 (6.6 + 3 x 10-11) | 37.5 (25.8) |
| R4 (12,7) prep. | 245.6 s | 114.7 (53.1 + 60.1) | 92.2 (21.2 + 4 x 11.6-14.2) | 38.7 (29) |

## 3. Profile

Per-stage shares on the two hardest runnable rungs (before any change):

| stage | R4 (12,7) | R2 (12,9) frozen | what it is |
|---|---:|---:|---|
| ChartPullBack: Jacobian normalization | 60.1 s (24%) | (inside 76.6) | serial `Together` of the chain-rule combinations `A_v J + A_w J` per entry (`EpsFormStripInFrame.wl`, `transportChartJacobianTogetherRecipe`) |
| ChartPullBack: deferred materialization (interning) | 53.1 s (22%) | -- | exact canonicalization of 44 operands of the deferred DAG (`BlockEquationDeferred.wl`); with the canonicalizer's Together probe cut to 0.1 s: 43.9 s, so it is real symbolic work, not probe timeouts |
| InnerSolve: held-out sampling | 52 s (21%) | 31 s (19%) | 3-4 primes x 18-19 regulator values; per prime-set on R1: point loops 8.0 s (form evaluation 4.5, row assembly 3.2), the other ~9 s in the per-prime held-out block outside the point loop (per-sample setup, constrained solve, all-row check, canonicalization, interpolation) |
| GaugePullBack: finite-field normalizer | 29 s (12%) | 25.8 s (16%) | `FiniteFieldGaugePullBack.wl`, two primes, 48-93 points, 16 outputs each |
| InnerSolve: finite-field prepare | 21.2 s (9%) | 6.6 s | `finiteFieldStripPrepare` (alphabet census, symbolic forms) |
| linear algebra, interpolation, lift | < 2 s | < 2 s | FLINT solves ~0.04 s per sample |

**Top three costs, named:** (1) the symbolic chart pull-back -- Jacobian normalization 60 s + deferred
materialization 53 s on R4 (47% of the solve), 77 s on the frozen R2; (2) held-out sampling,
31-52 s, of which only ~45% is the point loop; (3) the gauge pull-back normalizer, 26-29 s.
Exact, sub-second: the affine solves, the interpolation, the lift.  The instrumentation added for
this profile (`SamplingEvaluationSeconds`, `SamplingAssemblySeconds`, `SamplingPointCallSeconds`
per sample and per prime in `FiniteFieldStripSolve.wl`) stays.

## 4. Changes

### Retained

1. **Jacobian normalization through the exact native canonicalizer, size-gated**
   (`FeynFacet/Private/EpsForm/Strip/EpsFormStripInFrame.wl`, `transportChartJacobianTogetherRecipe`,
   with `$transportChartJacobianNativeLeafCount = 150000`).  Each chain-rule combination
   `A_v J_v + A_w J_w` above the gate goes through `rationalMaterializationCanonicalValue`
   (Core/Algebra/RationalMaterialization.wl: a 1 s `Together` probe, then the FLINT multivariate
   gcd reduction) and is rebuilt as numerator / product of denominator factors; any refusal falls
   back to `Together`.  Exact-preserving: the value is the same canonical rational function (the
   canonical-quotient contract puts numeric content in the numerator), and every consumer reads it
   through `Numerator`/`Denominator`/`CoefficientRules`/`FactorList`, which see identical
   polynomials; the finite-field solve, the held-out validation and the family certificate are
   unchanged.  Measured on R4 (12,7): Jacobian normalization **60.1 s -> 22.1 s** (2.7x), the solve
   **245.6 s -> 204.0 s**; on R1 (12,9) the ungated form cost 14.5 s against 10.1 s (its eight
   recipes, 99-120 k leaves, spend the 1 s probe and then 1.1 s in FLINT where `Together` alone
   takes 1.3 s), which is why the gate sits above R1's recipes.  An env-gated diagnostic
   (`FACET_R8_RECIPE_LOG=On`) prints leaf count and seconds per recipe.
2. **One sparse matrix per sample instead of one per point**
   (`FiniteFieldStripSolve.wl`, `SampleEpsFormStripAffine`: `buildPointRows` returns the packed
   dense block, `matrix = SparseArray[Join @@ pointRows]`).  Identical matrix entry by entry;
   measured neutral-to-slightly-positive on R1 (sampling 17.2 -> 16.1 s, within run-to-run noise
   of about 1 s).  Kept because it removes 93 SparseArray constructions per sample at no cost.
3. **Sampler profile timers** (`SamplingEvaluationSeconds`, `SamplingAssemblySeconds`,
   `SamplingPointCallSeconds` per sample, `PrimeSampling*Seconds` per prime): the instrumentation
   the mandate asked for where it was missing; they are what showed that only ~45% of the
   held-out sampling time is the point loop.

### Tried and dropped

- Ungated canonicalizer on the Jacobian recipes: 2.7x on R4, 0.7x on R1 (numbers above); replaced
  by the gated form.
- Cutting the canonicalizer's `Together` probe to 0.1 s for the deferred materialization
  (hypothesis: interning time = probe timeouts): R4 interning 53.1 s -> 43.9 s only, so the
  operands are genuinely expensive to canonicalize; the default probe stays.
- The per-point `SparseArray` as the missing ~9 s of sampling: wrong (the point loops are 8 s of
  the 17 s; the rest is the held-out block around the samples); kept as change 2 for its
  simplicity, not for speed.

### Not attempted (measured, with the number that motivates each)

- **Held-out sampling outside the point loop** (~9 s of 17 s on R1, ~35 s of 50 s on R4): per-sample
  setup/preprocessing, the constrained FLINT solve (0.04 s), the all-row residual replay, the
  canonicalization of samples and the interpolation are timed only in aggregate; the next step
  is the same three-timer treatment inside the held-out block.
- **Form evaluation cached across the regulator samples of a prime** (4.5 s of R1's 8 s point
  loops): the samples of a prime draw identical points (`SeedRandom[randomSeed]` with the default
  seed 2540908 per sample), so the uncollapsed prime forms could be evaluated once per point into
  eps-power vectors and contracted per sample -- bit-identical values, up to 19x on that share.
- **Deferred materialization interning** (53 s on R4, 1477 s on the CF303 (25,18) record): real
  canonicalization work per operand; a native batch of the operand DAG (flint_deferred_ast_eval
  evaluates it modulo p already) reconstructing only the entries the strip needs is the
  transport-style answer, a design change of BlockEquationDeferred.wl.
- **Gauge pull-back normalizer** (26-29 s): two primes, 48-93 points; not profiled below the
  per-prime record.

## 5. Before/after

All numbers are launcher wall times or the solver's own stage timers, fresh kernels, native
FLINT backends built, seat A/B of this box (runs with a second kernel on the other seat are
marked; the solver's stage timers are unaffected by the census that inflated two R1 walls).

| rung | stage | before | after | factor |
|---|---|---:|---:|---:|
| R4 CF300 (12,7) | Jacobian normalization | 60.1 s | 22.1 s (gated run 21.9 s) | 2.7x |
| R4 CF300 (12,7) | ChartPullBack (materialize + Jacobian) | 114.7 s | 78.1 s | 1.5x |
| R4 CF300 (12,7) | whole strip | 245.6 s | 204.0 s | 1.2x |
| R1 CF300 (12,9) | Jacobian normalization | 10.1 s | 10.1 s (gate keeps Together) | 1.0x |
| R1 CF300 (12,9) | held-out sampling (3 primes) | 17.2 s | 16.1-17.4 s | ~1.0x |
| R1 CF300 (12,9) | whole strip | 51.3 s | 49.6-54.5 s | ~1.0x |
| R3 CF300 (12,1) | whole strip | 49.8 s | not re-run | -- |
| R2 CF300 (12,9) frozen | whole strip | 162.8 s | not re-run (its pull-back is the symbolic `transportChartPullBackStrip`, not the deferred router) | -- |

Final confirmation of the gated form on R4 (12,7) with the per-recipe diagnostic: eight recipes of
235 128 - 268 010 leaves, all above the 150 000 gate, 2.6-3.2 s each through the canonicalizer;
Jacobian normalization **22.6 s** (before: 60.1 s), ChartPullBack 78.7 s (before 114.7 s), InnerSolve
89.2 s, GaugePullBack 37.6 s; `Solved` on the unchanged acceptance path.  R1's eight recipes are
99 131 - 120 372 leaves, below the gate, so R1 keeps its 10.1 s `Together` path.

**Plainly:** the several-fold target was reached on one stage of the hard rung (Jacobian
normalization 2.7x), not on the whole solve (1.2x on R4).  What resists, with numbers: the deferred
materialization (53 s, real canonicalization of 44 operands) and the held-out sampling block
(52 s of which only 14.5 s is the point loop) -- both need the design changes listed above, not
tuning.  On today's code every rung of the ladder is a chart strip; the chartless multiquadratic
route that produced the campaign's hour-scale failures ((25,18): letters 1514 s, inner solve
3245 s unstable) could not be given a fixture that finishes under 900 s, so its costs stand as the
campaign record.  No physics contract was touched: no acceptance step, certificate, schedule or
prime count changed.

### Files changed
- `FeynFacet/Private/EpsForm/Strip/EpsFormStripInFrame.wl`: `transportChartJacobianTogetherRecipe`
  (canonicalizer route, leaf-count gate, env-gated diagnostic), `$transportChartJacobianNativeLeafCount`.
- `FeynFacet/Private/EpsForm/FiniteField/FiniteFieldStripSolve.wl`: `SampleEpsFormStripAffine`
  (one SparseArray per sample; three profile timers and their per-prime aggregation).
- Pre-change copies: `scratchpad/round4/M/r8/*.before_r8`; probe and logs in `scratchpad/round4/M/r8/`.
- Tests after the changes: `Tests/FiniteField/t_finite_field_round2.wls` (drives
  `SampleEpsFormStripAffine` in the held-out and deterministic modes; sample counts {7,4,4} and
  {12,5,5}) -- `failed: {}`, zero messages, 28 s (seat log).  Its first run surfaced
  `Lookup::invrl` from the new per-prime aggregation (the deterministic route keeps its samples
  in `samples`, not `pool`); fixed, re-run clean.  Not run (seat budget):
  `t_finite_field_strip_solve.wls`, `t_finite_field_adaptive_sampling.wls`,
  `Tests/EpsilonForm/t_gauge_pullback_mode.wls`.  Every probe run after each change reached
  `Solved` on the unchanged acceptance path (R1 x6, R4 x4).
