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

## 7. Third pass (coordinator's order: native DAG materialization, batched solves, gauge per-point evaluation)

All runs through `scratchpad/bench/seat_run.sh`; logs under `scratchpad/round4/M/r8/p3_*.log`
(the run directories `runs/<tag>_<pid>/` keep each solution's `summary.wl` and `gauge.wl`).
"Exact route" below is the pass-2 code (HEAD `dfa0fedf`) measured again in this session on the
same seats; "DAG route" is this pass.  Every DAG-route run ends `Solved` on the unchanged
acceptance path (post-pull-back residual, gauge pull-back, source-frame identity, family
certificate `Required`).

### 7.1 What lever 3 is now

The strip record no longer carries a materialized forcing.  `SolveEpsFormStripInFrame` builds a
*deferred forcing plan* (`FiniteFieldDeferredForcing.wl`) that binds the deferred preparation file,
the chart substitution, the Jacobian and the root images, and registers it under a key
(`Hash[{file, preparation fingerprint, Subst, root images, root squares}]`); the record carries only
that key plus the census.  Every consumer that needs the forcing modulo p asks
`finiteFieldDeferredForcingImages[key, prime, {{x, y, epsMod}, ...}]`, which evaluates the DAG
natively (`flint_deferred_ast_eval`, one request per chunk of at most `Floor[4096/gradeCount]`
images -- the evaluator's `MAX_TOTAL_IMAGES` cap, `ResourceLimit` exit 5 above it), contracts the
grades with the root values and applies the Jacobian, and caches every image.  The consumers:

- the sampler (`SampleEpsFormStripAffine`): draws its point sequence first (same RNG stream as
  before), asks for the images of the first `requestedPointCount + 8` points for the whole
  held-out wave (option `"DeferredForcingWaveValues"`, passed by the solver's `sampleBatch`), so one
  wave is one batch and the later samples hit the cache; a point past the prefetch is fetched on
  its own (`fetchForcing`).  A failed image rejects the point exactly like a pole did.
- the prepare step (`finiteFieldStripPrepare`): the alphabet and the gauge denominator come from
  the *census* (7.3) instead of `finiteFieldStripEntryFactorList` on materialized entries.
- the acceptance: the post-pull-back check evaluates the verifier's identity
  `dG - eps (e G - G c) - bbar + eps Sum K dlog = 0` at 16 random points modulo a fresh 31-bit
  prime with the DAG image as `bbar` (`finiteFieldDeferredForcingResidualQ`); the numerical
  `VerifyEpsFormStrip` is only used on the exact route.  The exact materialization
  (`transportChartPullBackDeferredPreparation`) runs only when the plan or the census is refused,
  and is then the same code as before.

Nothing in the DAG evaluation is approximate: the native batch returns residues of the same
rational functions the materializer would produce, and the proofs in 7.4 check that at the
sample points and on the final solutions.

### 7.2 Before/after by stage (launcher walls; the solver's own timers in seconds)

| rung | stage | exact route (pass 2, this session) | DAG route (this pass) | factor |
|---|---|---:|---:|---:|
| R1 (12,9) | ChartPullBack (materialize + Jacobian -> census) | 12.0 | 1.0 (census 1.0) | 12x |
| R1 (12,9) | prepare (`Prepared strip sampling once`) | 4.4 | 0.07 | 60x |
| R1 (12,9) | held-out sampling, 3 primes (point loops / solves / image batches) | 16.5 (5.6 / 5.5 / --) | 13.2 (4.5 / 3.4 / 0.7) | 1.25x |
| R1 (12,9) | InnerSolve | 24.9 | 15.3 | 1.6x |
| R1 (12,9) | GaugePullBack (normalizer / post-pull-back check) | 6.7 (4.2 / numerical verify) | 5.6 (4.2 / residual 0.3) | 1.2x |
| R1 (12,9) | **whole strip** | **43.6** | **21.9** (`p3_r1_dag9.log`; 26.6 in `p3_r1_final.log`, run concurrently with a probe on the other seat) | **2.0x** |
| R4 (12,7) | ChartPullBack (materialization 57 + Jacobian 20 -> census) | 76.9 | 1.8 (census 1.8) | 43x |
| R4 (12,7) | prepare | 20.1 | 0.08 | 250x |
| R4 (12,7) | held-out sampling, 4 primes (point loops / solves / image batches) | 48.6 (7.8 / 24.3 / --) | 61.6 (8.5 / 25.8 / 17.0 at 4 threads; 9.8 at 8 threads in `p3_r4_final.log`) | 0.8x |
| R4 (12,7) | InnerSolve | 87.6 | 73.9 | 1.2x |
| R4 (12,7) | GaugePullBack (normalizer / post-pull-back check) | 31.7 (21.8 / numerical verify ~9.8) | 37.4 (22.1 / residual 4.3, of which 3.9 building the tables of the 43995-leaf chart gauge) | 0.85x |
| R4 (12,7) | **whole strip** | **196.3** | **113.2** (`p3_r4_dag3.log`; 117.5 in `p3_r4_final.log`) | **1.7x** |

Against the first-pass baselines of section 5 (R1 51.3 s, R4 245.6 s) the strip is 2.3x and
2.2x faster.  The held-out sampling on R4 is *slower* on the DAG route by the image batches:
19 regulator values x (requestedPointCount + 8) points per prime = ~3200 images per prime at
~1.3 ms per image in the native evaluator with 4 threads (0.7 ms with 8; `p3_threads.log`:
960 images 1.36 -> 0.69 s).  The exact route paid for the same values inside the point loops
(its forcing tables were free once materialized), so the DAG route trades 77 s of
materialization for 10-17 s of native evaluation on R4 -- and for 12 s -> 1 s on R1.

Where the DAG route's time goes now (R4, `p3_r4_final.log`): solves 28 s (lever 1, 7.6),
normalizer 23 s (lever 3b, 7.7), image batches 10 s, point loops 10 s, residual check 4 s,
census 2 s, everything else < 2 s each.

### 7.3 The census (alphabet and gauge denominator without materialization)

`finiteFieldDeferredForcingCensus[key, prime]`: candidate factors = every denominator base of
the DAG (operands *and* term coefficients, at every level of the expressions -- `Denominator` is
structural and misses denominators nested inside sums), pulled back through the chart with
perfect-square radicals reduced (`Sqrt[p^2/q^2] -> p/q`, both sign variants: the algebra inverts
`a + b r` through its norm, which pulls back to `(aq + bp)(aq - bp)/q^2`), plus the chart's own
denominators (substitution, root images, Jacobian) and the root-image numerators; `FactorList`,
dedupe up to sign.  Then two random lines `(a + t, b + s t)` at a random regulator image: 240
images per line from one native batch, every entry fitted as a univariate rational function by
one `NullSpace[..., Modulus -> p]` at degree bound 110 reduced by the gcd and validated on
held-out points, the multiplicity of each candidate by repeated exact division, and the check
that the candidates explain the whole fitted denominator degree.  The two lines must agree on
every multiplicity and on the degree at infinity, or the census is a typed refusal
(`DeferredForcingCensusLinesDisagree`, `...LineFitFailed`) and the strip falls back to the exact
route.  Cost: R1 1.0 s, R4 1.8 s, CF303 (25,18) 12 s (`p3_census_lines_2518f.log`, 20 candidates,
16 letters, denominator degree 86 along a line fully explained).

Two findings.  (a) The exact census double counts a sign variant: on R1
`finiteFieldStripEntryFactorList` + `DeleteDuplicates[..., SameQ]` reports gauge denominator
degrees {14, 11} where the true (line-verified) degrees are {12, 10}; the DAG-route ansatz is
therefore smaller (596 unknowns against 736) and its solves cheaper.  The exact route is not
wrong (its ansatz contains the true one), only larger.  (b) On CF303 (25,18) the first three
candidate sets were incomplete (the four defects above, found one by one on the leftover of the
fitted denominator: `p3_census_lines_2518{,b,c,d,e,f}.log`); each time the census *refused* and
the run fell back to the exact route, so no wrong alphabet ever reached a solve.

### 7.4 Exactness

1. **Images.**  The DAG batch equals the exact materialized strip at every sample point:
   `SameQ` on the residue vectors, R1 12/12 points, R4 24/24 points (`dag_r1.log`, `dag_r4.log`;
   0.19 s against 12.1 s and 0.14 s against 80.7 s of exact pull-back).
2. **Batch evaluator.**  The vectorized preflights (coefficient tables + packed arithmetic) equal
   the per-point AST reference `finiteFieldDeferredForcingPreflightsReference` on 1908 images of
   R1 (`SameQ` True; 1.38 s -> 0.008 s), and the vectorized grade/Jacobian contraction equals the
   per-image reference on 41 images (`SameQ` True) -- `p3_batch_vec.log`.
3. **Solutions.**  The DAG-route gauges verified with `VerifyEpsFormStrip[..., "Method" -> "Exact"]`
   against the *exactly materialized* chart strip: R1 `ExactPfaffianResidualsZero -> True`
   (`p3_r1_verify.log`), R4 `DLogFormCertified -> True, ExactPfaffianResidualsZero -> True`
   (`p3_r4_verify.log`, 145 s of exact verification, chart gauge leaf count 43995).  Vector
   `SameQ` of the gauges with the exact route's is not a meaningful check: the constant-gauge
   freedom and the smaller ansatz (7.3a) give a different representative of the same class; the
   exact verification is the contract.
4. **Acceptance check.**  `finiteFieldDeferredForcingResidualQ` on tables: True on the R1 and R4
   solutions; the negative controls (a residue matrix entry + 1; a gauge entry x (1 + X)) are
   False (`p3_r1_residual.log` 0.33 s, `p3_r4_residual.log` 4.3 s).
5. **Sampler semantics.**  The point sequence, the acceptance rule per point, the solve and the
   held-out validation are unchanged; only where the forcing residues come from changed.

### 7.5 Tried and dropped inside this pass
- A solver-level pre-warm with the pilot's point count x 2: wrong count for the later samples
  (support learning shrinks the ansatz) and blind to the evaluator's cap -- the 31-bit primes' waves
  (1908 images) were refused and every sample re-batched (`p3_r1_dag5.log`: 3816 images batched,
  11 s); replaced by the sampler-side prefetch with the sampler's own count and chunking.
- A symbolic residual check (`D` and `Together` of the chart gauge at 16 points): 20 s on R4;
  replaced by the table evaluator with derivatives by exponent shift (4.3 s, 0.3 s on R1).
- Reducing the residue matrices as numbers in that check: they carry eps
  (`ResiduesEpsFree -> False`); they go through the tables like everything else.
- 4 evaluator threads: 8 is 2x on the seat's 8 pinned CPUs.

### 7.6 Lever 1 (batched adapter solves) -- design with measured bounds, not implemented
Measured: R4 `PrimeSamplingConstrainedSolveSeconds` 24.3-28.2 s for 73 solves (4 primes x 18-19
regulator values), i.e. 0.33-0.39 s per solve of the 1248-rank system in 1796 unknowns; the
pass-2 micro-benchmark puts the adapter's own floor at 0.12-0.21 s per call (process launch,
request/response files) and the FLINT solve at ~0.2 s at this size.  One request carrying all 18-19
systems of a prime (same sparsity pattern, different values) would cost about one launch plus
19 solves: ~4 s per prime instead of ~7, i.e. -12 to -15 s on R4 (about 12%).  It needs a
multi-system request/response format in `flint_affine_solve` and its writer/reader, and the
sampler's solve to be hoisted out of `SampleEpsFormStripAffine` (the samples of a wave would return
their assembled systems and receive their solutions), which touches the deterministic and broker
paths too; it is more than a session and is left as this note.

### 7.7 Lever 3b (gauge pull-back per-point evaluation) -- design with measured bounds, not implemented
Measured: `FrameCertificate/Normalizer/PrimeRecords :: EvaluatePointSeconds` 13.2-14.7 s on R4
(128 points on each of 2 accepted primes plus the attempts of the rejected one; 35-50 ms per
point), 2.2 s on R1.  `finiteFieldGaugePullBackEvaluatePoint` substitutes the point into the
coordinate channels and root squares symbolically (`/. sourceRules` then `ModRational`), builds
the chart monomials in the multiquadratic algebra (`multiquadraticMultiply` per monomial) and
assembles, for each of the 18 regulator fibres, 16 outputs as sums over the support of
coefficient x monomial (width `gradeCount`).  The batch form is the one used in
`FiniteFieldDeferredForcing.wl`: coefficient tables for the channels evaluated for all points at
once, monomials stacked as a (points x support x width) array, one `Dot` per fibre for the 16
outputs, the denominator inverse per point as now.  The same change on the sampler side took the
per-image cost from 1.7 ms to 0.03 ms; a conservative 10x here is -12 s on R4 (10%).  The
records must stay identical (same points in the same order, same rejections); the proof is
`SameQ` of the per-prime records before/after.

### 7.8 Files changed in this pass (pre-pass-3 copies from `dfa0fedf` in `scratchpad/round4/M/r8/*.before_p3`)
- NEW `FeynFacet/Private/EpsForm/FiniteField/FiniteFieldDeferredForcing.wl` (registered in
  `LoadOrder.wl:131` after `FiniteFieldStripBroker.wl`): registry and image cache; `RouteQ`
  (`FACET_DEFERRED_FORCING=Off` restores the exact route); `Plan` (l.83); coefficient tables and
  the packed evaluators `Table`/`Tables`/`Powers`/`PolynomialAt`/`RationalAt` (l.127-170);
  `Preflights` (vectorized, l.172) and `PreflightsReference` (l.199, the per-point AST evaluator
  kept for the exactness comparison); `Images` (chunked native batches, contraction, cache,
  l.223); `LineFit`, `PolynomialRoot`/`ReduceRadicals`, `CandidateFactors`, `Census`
  (l.268-380); `DerivativeRules`/`ResidualQ` (l.382-445).
- `FeynFacet/Private/EpsForm/FiniteField/FiniteFieldStripSolve.wl`: option
  `"DeferredForcingWaveValues"` (l.966); prepare takes alphabet/denominator from the census when
  the record carries `"DeferredForcing"` (l.1104-1120, 1238); the sampler's drawn points, wave
  prefetch, image lookup and `fetchForcing` (l.1716-1740, 1646); per-sample image timers
  (l.2024, 3737, 4004); the solver's `sampleBatch` passes the wave's values (l.3580-3586); the
  final check uses `ResidualQ` on the DAG route (l.3902).
- `FeynFacet/Private/EpsForm/Strip/EpsFormStripInFrame.wl`: the plan, census and descriptor
  before the pull-back, `timings["DeferredForcingCensus"]`, the exact pull-back gated on the
  descriptor being `None` (l.848, 1089-1090, 1389-1412); the post-pull-back verification on the
  DAG route (l.1552-1566).
- Note on HEAD: the coordinator's `dfa0fedf` is no longer HEAD.  Commit `955c3e78` (T, 23:28,
  "Round 8b") swept the then-current working-tree state of these four files into its commit, so
  HEAD `b2653f96` already carries an *intermediate* pass-3 state (before the chunking, the
  vectorized evaluators, the wave prefetch, the table residual check and the census fixes); the
  rest is uncommitted in the working tree (`git diff --stat`: `FiniteFieldDeferredForcing.wl`,
  `FiniteFieldStripSolve.wl`).  I did not commit anything.

### 7.9 Tests (seat log walls; tally lines audited, no "Failed to open file")
Mid-pass code (after the vectorized evaluators): `t_finite_field_round2` `failed: {}` 24 s;
`t_finite_field_adaptive_sampling` all booleans True 3 s; `t_finite_field_gauge_pullback` 14 PASS
0 FAIL 7 s; `t_multiquadratic_transport_frame` 20 assertions 0 failed 4 s (the six pre-existing
`OptionValue::nodef` messages from `TransportFamilyInChart`, section 6); 
`t_deferred_bundle_chart_compatibility` 20 PASS 0 FAIL 3 s (`p3_t_*.log`).

Final code (after the census fixes and 8 threads; `f2_t_*.log`, run while the ceiling occupied the
other seat): `t_finite_field_round2` `failed: {}` 34 s; `t_finite_field_adaptive_sampling` all True
5 s; `t_finite_field_gauge_pullback` 14 PASS 0 FAIL 8 s; `t_multiquadratic_transport_frame`
20 assertions 0 failed 6 s (same six pre-existing messages); `t_deferred_bundle_chart_compatibility`
20 PASS 0 FAIL 9 s.  No test knows about the deferred route explicitly; the deferred-bundle test
and the gauge pull-back test exercise the code paths the pass changed (chart compatibility of the
deferred preparation; the acceptance's gauge pull-back), the sampler tests the unchanged
sampling contract.

### 7.10 Final-code runs (both seats busy: the ceiling run was on the other seat)
- R1 (12,9): **25.2 s** Solved (`f2_r1.log`; census 1.1 s, letters 10, pole orders {2,2,3,2} --
  the same multiset as before the candidate changes; InnerSolve 15.9, GaugePullBack 8.2 with the
  normalizer at 6.6 s against 4.2 s alone).  Range over this pass's R1 runs on the final route:
  21.9-26.6 s; the exact route 43.6 s alone.
- R4 (12,7): **121.0 s** Solved (`f2_r4.log`; census 1.8 s, letters 11, pole orders
  {4,2,2,3,2,2}; InnerSolve 74.9 with solves 27.7, image batches 11.1, point loops 9.6;
  GaugePullBack 44.3 with the normalizer at 26.3 s against 22 s alone).  Range 113.2-121.0 s;
  the exact route 196.3 s alone.
- The mandate's "several folds on hard blocks" is met on the materialization (43x on R4, and the
  block that could not be materialized under 900 s now passes its census in 12.5 s) and not yet on
  the whole strip (2.0x and 1.7x against the exact route; 2.3x and 2.2x against the first-pass
  baselines).  What remains is measured and designed in 7.6 and 7.7 (solves 28 s and normalizer
  22-26 s on R4, together 40-45% of the strip).

### 7.11 Ceiling: CF303 (25,18) under 900 s on the DAG route
`p3_ceiling_dag2.log`, seat B 00:16:45-00:31:37, launcher wall 892 s, exit 0, result
**`BudgetExhausted` after 864.9 s in the inner solve** (the probe's 860 s solver budget; the
launcher's 900 s KILL was not reached).  Where the time went, for the first time on this block:
- load 2 s, root classification 0 s, chart `Kallen2Bilinear115` selected;
- **census 12.5 s** (20 candidates after the four fixes of 7.3, 16 letters, pole orders
  {2,2,2,2,2,3,3,4,4,3,3,4,2,4,2}, degree at infinity 1; both lines consistent, denominator
  degree 86 along a line fully explained): the DAG route accepted the block, so the 1477 s
  materialization of the campaign and the pass-2 ceiling run (killed inside it at 900 s) are
  gone from this path;
- prepare 0.33 s (support census `NumeratorTotalDegreeBound -> 58`, certified);
- then the sampler's **degree probe**: 23 numerator-degree offsets x 2 support shells = 46
  modular systems of 7144-9084 unknowns (2x2 strip: 64 residue unknowns + 4 x ~1770-2250
  support monomials), every one `inconsistent`, ~18 s each, until the budget ran out.  No
  offset up to {4,3} gave a consistent system, so no sample, prime or acceptance step was
  reached.

What this says (rewritten after R2's F3).  Codex's note of 2026-08-30
(`Exchange/Codex/2026-08-30/05_cf303_dlog_no_go_and_rational_kernel_route.md`) records a
frame-independent integrability obstruction for this block: the gauge-eliminated covariant
integrability screen has defect 1 at three independent (prime, eps) images for both the 48-dlog
and the 16-polar-dlog targets, the rational gauge ansatz is exhaustive (all 16 divisor bounds and
the infinity bound saturated), so no strict rational dlog form exists on (25,18) in any frame;
T's transport route exists because of it.  Forty-six inconsistent offset/shell systems are
therefore the *expected* outcome of a correct ansatz on a block with no dlog form, not evidence
about the ansatz, and the block's campaign record (`CF303_25_18_unsolved.wl`,
`ModularStructureUnstable` on `DirectRootChannel`) is the same fact seen from another route.
The progress this pass makes on the block is exactly this: the chart route reaches the sampler
in 13 s (census 12.5 s, prepare 0.33 s) where it used to sit 25 minutes in the materialization,
and it returns typed.  Whether any widening of the ansatz is meaningful on this block is a
question for the integrability screen, which the DAG images can now feed at ~1 ms per image;
it is not a plan of this campaign, and the `GaugeDenominatorFactor` remark of the earlier draft
is withdrawn.

Cost of a probe on this block: ~18 s per 7-9k-unknown modular system through the FLINT adapter --
the same per-solve floor lever 1 (7.6) addresses; a probe ladder of 46 systems is 14 minutes,
so a block of this size needs either the right ansatz at the first offsets or the batched solves.

### 7.12 State for the review
- Working tree: `FiniteFieldDeferredForcing.wl` and `FiniteFieldStripSolve.wl` modified against
  HEAD `b2653f96` (which already carries the four files' intermediate pass-3 state through T's
  commit `955c3e78`); `EpsFormStripInFrame.wl` and `LoadOrder.wl` unchanged against HEAD.  Full
  pass-3 diff against `dfa0fedf`: `git diff --stat dfa0fedf -- FeynFacet/Private` (448 + 100 + 66
  + 2 lines).  Nothing committed by me.  `FACET_DEFERRED_FORCING=Off` restores the exact route
  without a code change.
- Reproduction (all through the seat launcher): a rung
  `wolframscript -file scratchpad/round4/M/r8/stage1_probe.wls <input.wl> <budget s> <tag> 4`;
  the image/evaluator exactness `batch_size_probe.wls <input> <tag> 8 2147483423`; the census
  diagnostic `census_lines_probe.wls <input> <tag> 8 2147483423`; the solution verification
  `verify_dag_solution.wls <input> <tag> <points> <prime> <gauge.wl> Exact|Numerical|Residual`;
  the native evaluator's thread scaling `threads_probe.wls`.
- Open items, in the order they pay: lever 1 (7.6, -12..-15 s on R4), lever 3b (7.7, -12 s), the
  (25,18) ansatz question (7.11), and the per-image native cost (1.3 ms at 4 threads, 0.7 at 8).

## 8. R2's fixes (review `R2_review_stage1_speed.md`, verdict "finished with the listed fixes")

| finding | fix | where | verification |
|---|---|---|---|
| F1 (medium): the image cache's 400,000-entry reset sat inside the chunk loop, so a multi-chunk call crossing it returned `OK` with earlier chunks' values `Missing` (R2: 8 of 20) | A call is atomic with respect to the cache: the reset happens only at the start of a call (between calls), every result of the call lives in a local list until it is returned, and any `Missing` value is a typed failure `DeferredForcingImagesIncomplete` (with `MissingCount`), never `OK` | `FiniteFieldDeferredForcing.wl:268-312` (`finiteFieldDeferredForcingImages`) | R2's fixture P2 is now an assertion: NEW `Tests/FiniteField/t_finite_field_deferred_forcing.wls` D3 (cache pre-filled to 399,998, batch limit 8, 20 uncached images -> `OK`, no `Missing`, values `SameQ` with the fresh-cache reference), D4 (the next call resets between calls and is complete), D5 (a chunk that yields no values is a typed failure), D2 (batch limit 7 vs one request of 30: `SameQ`) -- 13/13 PASS, 7 s |
| F2 (medium): on the KernelPool broker path a helper kernel could not find the plan in the solving kernel's registry, every helper sample failed typed and the broker recomputed locally -- pool parallelism silently lost on the hard strips | The descriptor now carries a serializable **handle** (input file, the preparation's validation fields, chart substitution, Jacobian, root squares, root images, chart/source variables, regulator, dimensions); `finiteFieldDeferredForcingEnsurePlan` rebuilds a "slim" plan from it on a kernel whose registry lacks the key (same key by construction: the hash reads only those fields; a mismatch is refused), and the sampler resolves its key through it.  A slim plan serves images and residual checks and refuses a census typed (`DeferredForcingPlanSlim`).  Telemetry: `$finiteFieldDeferredForcingTypedFailures` (+ last status) counts the sampler's typed failures in each kernel; `$taskBrokerHelperFailureCount` counts helper samples the broker recomputed locally, printed unconditionally by the broker (`[broker] n of m helper samples failed typed at prime p; recomputed locally`), both carried per solve in `Timings/Inner` (`DeferredForcingTypedFailures`, `BrokerHelperFailures`) and logged by the solver (`Deferred-route telemetry: ...`, a line the sector driver prints) whenever nonzero | `FiniteFieldDeferredForcing.wl:127-159` (handle, ensure), `:402` (slim census refusal), `:68-72` (counters); `EpsFormStripInFrame.wl:1404-1405` (handle in the descriptor); `FiniteFieldStripSolve.wl:1717-1724` (ensure + count), `:1741-1745` (count), `:2985-2987` (baselines), `:3972-3976` (log), `:4027-4030` (timings); `FiniteFieldStripBroker.wl:108-120` (count + print) | In-kernel simulation of a helper, as the coordinator allowed (the licence's two seats forbid a pool test here): the same record file and options file a broker writes (`taskBrokerPutAtomic` into a fresh directory), the registry emptied, `taskBrokerSampleTask` called -> the sample equals the solving kernel's sample (all keys but timers `SameQ`), the plan is registered slim under the same key (D9), its images equal the original plan's (D10), the census refuses typed (D11); without the handle the sample fails typed and the counter advances by one with `DeferredForcingPlanUnknown` (D12).  Not verified: the real pool round trip (a `KernelPool` with `FACET_TASK_BROKER` set and a hard strip whose pilot exceeds `BrokerMinimumSeconds`); the check would be the broker line above absent from the sector log and `BrokerHelperFailures -> 0` in `Timings/Inner` of a strip that used helpers |
| F3 (medium, report): the (25,18) lead ignored the recorded frame-independent no-go | 7.11 rewritten: Codex note 05 (2026-08-30) cited -- defect-1 integrability obstruction at three images, exhaustive rational ansatz, no strict rational dlog form in any frame; the 46 inconsistent systems are the expected outcome; the progress stated as "reaches the sampler in 13 s and returns typed"; the `GaugeDenominatorFactor` remark withdrawn and any widening stated as a question for the integrability screen, not a plan | section 7.11 | -- |
| F4 (low-medium): the modular acceptance check was stored as `NumericalPfaffianResidualsZero` / `Certificate -> "NumericalResidual"`, unseeded | On the DAG route the check is stored as `ModularPfaffianResidualsZero` with a `ModularResidual` record (`Status`, `Prime`, `Points`, `RequestedPoints`, `Seed`, `Seconds`), `Certificate -> "ModularResidual"` (inner and strip level, `FrameCertificate["InnerCertificate"]`), the log line says "Modular (DAG-image) Pfaffian residuals"; `finiteFieldDeferredForcingResidualQ` draws its prime and points under `SeedRandom[Seed]` (option, default 20260903) and returns them.  Every reader of the certificate extended to accept `ModularResidual` alongside `NumericalResidual`: `familyRowGaugeStripAcceptanceRecordQ` (three places, and the frame key `ModularPfaffianResidualsZero`), the in-frame `innerSolvedQ`, the sector driver's `solvedQ`.  The exact route's keys are untouched | `FiniteFieldDeferredForcing.wl:459-485`; `EpsFormStripInFrame.wl:1558-1568, 1585-1595, 1622-1626, 1079`; `FiniteFieldStripSolve.wl:3916-3940`; `FamilyRowGauge.wl:118, 129-134, 153`; `Scripts/family_epsform_sector.wls:1279` | R1 on the final code (`r2_r1b.log`, 22.2 s, `Solved`): the record carries `"Certificate" -> "ModularResidual"`, `"InnerCertificate" -> "ModularResidual"`, `"ModularPfaffianResidualsZero" -> True`, `"ModularResidual" -> <|"Status" -> "OK", "Prime" -> 1329879151, "Points" -> 16, "RequestedPoints" -> 16, "Seed" -> 20260903, "Seconds" -> 0.23|>` (`runs/r1r2b_*/summary.wl`) |
| F5 (low, not required): one singular point fails a whole wave's sample; the DAG route caps attempts at 2 x requestedPointCount | Not changed in this round (typed, ~1e-9 per point at 31-bit primes, no wrong acceptance); recorded as open | -- | -- |
| F6 (low, not required): the conjugate sign variants cover one radical at a time | Not changed (fail-closed: the degree-consistency check refuses and the strip falls back to the exact route); recorded as open | -- | -- |

Tests after the fixes (seat launcher, 300 s caps; tally lines audited, no "Failed to open file"):
`t_finite_field_round2` `failed: {}` 27 s; `t_finite_field_adaptive_sampling` all True 3 s;
`t_multiquadratic_transport_frame` 20 assertions 0 failed 4 s (the six pre-existing
`OptionValue::nodef` messages); `t_deferred_bundle_chart_compatibility` 20 PASS 0 FAIL 4 s; NEW
`t_finite_field_deferred_forcing` 13 PASS 0 FAIL 7 s (`r2_t_*.log`, `r2_t_deferred_forcing2.log`).
Also run (not in the required list): `t_finite_field_gauge_pullback` 14 PASS 0 FAIL 6s (`r2_t_gauge.log`).

One defect of my own in this round, recorded: a first placement of the telemetry baselines
landed inside the solver's `Module` variable list (a nested `{}` default matched the anchor),
which broke `SolveEpsFormStripFiniteField`; the load check passed (the file parses) and only the
R1 run showed it (`Module::lvsym`, `r2_r1.log`).  Fixed by anchoring on the first body statement;
the test chain that had started on the broken code was killed by verified PID and re-run.
Nothing committed; the working tree now differs from HEAD in `FamilyRowGauge.wl`,
`FiniteFieldDeferredForcing.wl`, `FiniteFieldStripBroker.wl`, `FiniteFieldStripSolve.wl`,
`EpsFormStripInFrame.wl`, `Scripts/family_epsform_sector.wls`, this report, and the new test.
