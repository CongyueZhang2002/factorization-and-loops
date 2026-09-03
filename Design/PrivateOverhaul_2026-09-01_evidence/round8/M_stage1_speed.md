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

## 6. Second pass (coordinator's four levers, in order)

Same rules; every number a launcher wall time or the solver's own timer; R1 = CF300 (12,9) with
its deferred preparation, R4 = CF300 (12,7).  Baselines are the first-pass numbers of section 5
(R1 51.3 s, R4 245.6 s; after the first-pass Jacobian change R4 204.0 s).

### Lever 1 -- the held-out block outside the point loop (diagnosed; the fix is lever 2 + a design item)
New timers (`FiniteFieldStripSolve.wl`: per sample `SampleSeconds`; per prime
`HeldOutBatchSeconds`, `HeldOutCanonicalSeconds`, `HeldOutInterpolateSeconds`,
`SamplingSetup/Preprocessing/ConstrainedSolve/LinearSolve/PlanDiscoverySeconds`, all carried into
`Timings/Inner`) split R1's 17.4 s (3 primes, 55 samples) into:

| part | seconds | per sample |
|---|---:|---:|
| point loops (`buildPointRows`): form evaluation 4.6 + row assembly 3.6 | 8.4 | 0.15 |
| constrained solve = one FLINT adapter round trip per sample (directory, 4.3 MB dense core written, process, read-back) | 4.5 | 0.08 |
| per-sample preprocessing (collapse of the prime forms at eps) | 1.2 | 0.02 |
| held-out interpolation (per prime, over the pool) | 1.2 | -- |
| canonicalization of the pool, setup, bookkeeping | ~2 | -- |

(`LinearSolveSeconds` and `ConstrainedSolveSeconds` are the same quantity recorded twice, so
`SamplingSolveSeconds` double-counts; the table uses the single value.)  Nothing here is a
repeated exact substitution or a `Together`: the non-loop time is the per-(prime, eps) modular
solve, which cannot be done "once per prime" (each regulator value is a different system).  The
in-kernel alternative is worse: `LinearSolve[..., Modulus -> p]` measured 0.82 s at 736 unknowns
and 11.5 s at 1800 against the adapter's 0.12-0.21 s and 0.45 s (`scratchpad/round4/M/r8/solve_bench.log`),
so the adapter stays; what remains batchable is its spawn/I-O share (multi-system protocol for
`flint_modular_solve`, or concurrent `StartProcess` solves of a prime's samples): on R4, 72
solves x ~0.4 s is the bulk of its 52 s held-out block.  Not implemented in this pass (a
protocol change plus a build/solve split of the certified sampler); the point-side share went to
lever 2.

### Lever 2 -- per-point evaluation cache across the regulator samples (implemented, kept)
`FiniteFieldStripSolve.wl`, `SampleEpsFormStripAffine`: the uncollapsed prime forms
`{ix, iy, matrix(terms x eps-powers)}` are evaluated once per (fingerprint, prime, point) into one
vector over the eps powers per polynomial (`evaluatePolynomialK`, column sums reduced below 2^62
as before), cached in `$finiteFieldStripPointValueCache` (bounded, 4096 points), and contracted
with each sample's eps powers (`contractRational`); the old path stays for records without
symbolic forms.  Exact: `Sum_k (Sum_t m[t,k] x^ix y^iy) eps^k = Sum_t (Sum_k m[t,k] eps^k) x^ix y^iy`
modulo p, and the `BadPoint` condition (denominator zero) is the same quantity.  R1: form
evaluation **4.6 -> 1.8-2.0 s**, point loops **8.4 -> 6.0 s**, sampling 17.4 -> 16.2 s; the first
sample of each prime pays the full K-column evaluation once, the other 18 contract.  Modest on
R1 because the assembly (3.8 s) and the solves (4.6 s) are untouched.

### Lever 3 -- deferred materialization (not implemented; design recorded)
53 s on R4 (44 operands, ~1.2 s each, real canonicalization: with the canonicalizer's Together
probe cut to 0.1 s it is still 43.9 s), 1477 s on the CF303 (25,18) record.  The transport-style
design: evaluate the deferred operand DAG at the sampler's points modulo the prime in one native
batch (`flint_deferred_ast_eval` already evaluates the DAG modulo p for the providers), hand the
finite-field sampler per-point values instead of characteristic-zero entries, and materialize
exactly only for the final certificate.  It changes the data handed from the router
(`transportChartPullBackDeferredPreparation`) to `SampleEpsFormStripAffine` (which today takes
symbolic forms), i.e. a new input contract for the certified sampler; out of this pass's budget.

### Lever 4 -- gauge pull-back normalizer (implemented, kept)
Phase timers in `finiteFieldGaugePullBackPrime` (`FiniteFieldGaugePullBack.wl`: `Specialize`,
`TakeFibres`, `SliceDegrees`, `EvaluatePoint`, `FitFibre` seconds per prime record) put 6.2 s of
R1's 11.5 s in the fibre fits -- which already used the native adapters, but once per fibre
(a CFFR nullspace run plus a FLINT solve per fibre, ~36 process round trips per prime for systems
of 25-75 unknowns).  Fix: the same 256-unknown gate as `finiteFieldStripBackendDecision` -- below
it `NullSpace[matrix, Modulus -> p]` (the fit's existing fallback path) and
`LinearSolve[construction, rhs, Modulus -> p]`, above it the adapters as before; both results are
verified on every original row / the held-out rows exactly as before.  R1: fits **6.2 -> 0.18 s**,
gauge pull-back stage **13.2 -> 7.05 s**, whole strip **51.3 -> 43.5 s**.

### Before/after per lever (launcher walls and the solver's own timers; `Solved` on the unchanged acceptance path in every run)

| rung | stage | first-pass baseline | after levers 1-4 | factor |
|---|---|---:|---:|---:|
| R1 (12,9) | form evaluation in the point loops (lever 2) | 4.6 s | 2.0 s | 2.3x |
| R1 (12,9) | point loops (evaluation + assembly) | 8.4 s | 6.0 s | 1.4x |
| R1 (12,9) | held-out sampling, 3 primes | 17.4 s | 16.4 s | 1.06x |
| R1 (12,9) | fibre fits of the gauge pull-back (lever 4) | 6.2 s | 0.18 s | 34x |
| R1 (12,9) | gauge pull-back stage | 13.2 s | 7.05 s | 1.9x |
| R1 (12,9) | **whole strip** | **51.3 s** | **43.5 s** | **1.18x** |
| R4 (12,7) | Jacobian normalization (first pass) | 60.1 s | 22.3 s | 2.7x |
| R4 (12,7) | ChartPullBack (materialization 57 + Jacobian 22) | 114.7 s | 81.1 s | 1.4x |
| R4 (12,7) | form evaluation in the point loops (lever 2) | (not timed then) | 4.5 s | -- |
| R4 (12,7) | held-out sampling, 4 primes (solves 23.4 s = 72 x 0.32 s, point loops 8.4 s, preprocessing 3.1 s) | 52 s | 46.9 s | 1.1x |
| R4 (12,7) | fibre fits of the gauge pull-back (lever 4) | (not timed then) | 1.35 s | -- |
| R4 (12,7) | gauge pull-back stage (now: per-point evaluation 15.2 s, slice degrees 4.1 s, specialize 2.2 s) | 38.7 s | 34.2 s | 1.13x |
| R4 (12,7) | **whole strip** | **245.6 s** | **203.3 s** | **1.21x** |

**Plainly:** the mandate's several-fold on hard blocks is not met.  The per-stage wins are real
(Jacobian normalization 2.7x, fibre fits 34x, form evaluation 2.3x) but the whole R4 solve is
1.2x, because the three costs that dominate it are the ones this pass diagnosed to a design
change and did not implement: the deferred materialization (57 s: 44 operands canonicalized
exactly although only modular images are consumed -- lever 3's native DAG batch), the
per-(prime, eps) FLINT solves (23 s: inherent per system, batchable only in their process
overhead), and the gauge pull-back's per-point evaluation (15 s on R4, symbolic-coefficient
evaluation per point and eps image; the sampler's own table approach applies).  Every retained
change is exact-preserving: same values modulo p, same canonical rational function, same
verifications on every original row; no schedule, prime count, acceptance step or certificate
changed.

### Ceiling measurement: CF303 (25,18) under a 900 s cap
`scratchpad/round4/M/r8/probe_ceiling_25_18.log`, seat A 18:52:19-19:07:19, exit 137 (the
launcher's KILL at 900 s).  The run read the 43 MB input (load 2.2 s), classified the roots
(0 s), entered the deferred materialization (`[deferred-materialize] start: block {25, 18},
records 8, terms 112`) and was still inside it when the cap hit; no `done` line, so the
materialization's new time is not measurable under the cap and the candidate-letters stage was
never reached.  Consistent with the record (1477 s for that stage) and with lever 3 not being
implemented: nothing in this pass changes what the materializer does.  **Where the cap hit:**
deferred materialization, interning of the operands (the campaign's `intern seconds 1467`).

### Tests on the final code (seat log walls)
- `Tests/FiniteField/t_finite_field_round2.wls` (sampler, held-out and deterministic modes): `failed: {}`, 0 messages, 27 s.
- `Tests/FiniteField/t_finite_field_adaptive_sampling.wls` (sampler, adaptive prime schedule): all booleans True, 0 messages, 4 s (run before lever 4; the sampler code was final).
- `Tests/Transport/t_finite_field_gauge_pullback.wls` (the gauge pull-back with the lever-4 gates): 14 PASS, 0 FAIL, 0 messages, 7 s.
- `Tests/Multiquadratic/t_multiquadratic_transport_frame.wls`: 20 assertions, 0 failed, 3 s; its six `OptionValue::nodef/optnf` messages come from `TransportFamilyInChart` (Transport, untouched by me) receiving the options the test passes at its line 174 -- pre-existing.

### Files changed in the second pass (all pre-change copies in `scratchpad/round4/M/r8/*.before_r8`)
- `FeynFacet/Private/EpsForm/FiniteField/FiniteFieldStripSolve.wl`: `SampleEpsFormStripAffine` --
  the per-point eps-power cache (`evaluatePolynomialK`, `evaluateRationalK`, `contractRational`,
  `$finiteFieldStripPointValueCache`, `kMaximumExponents` folded into the table exponents), the
  per-sample timers and `SampleSeconds`; the held-out block's three accumulators and the per-prime
  split keys; the `Timings/Inner` propagation.
- `FeynFacet/Private/EpsForm/FiniteField/FiniteFieldGaugePullBack.wl`: phase timers in
  `finiteFieldGaugePullBackPrime`; the 256-unknown gates in `finiteFieldGaugePullBackFitDenominator`
  (in-kernel `NullSpace[Modulus]` below, CFFR above) and `finiteFieldGaugePullBackFitNumerators`
  (in-kernel `LinearSolve[Modulus]` below, FLINT above).
- `FeynFacet/Private/EpsForm/Strip/EpsFormStripInFrame.wl` (first pass): the gated canonicalizer
  route of `transportChartJacobianTogetherRecipe`.
