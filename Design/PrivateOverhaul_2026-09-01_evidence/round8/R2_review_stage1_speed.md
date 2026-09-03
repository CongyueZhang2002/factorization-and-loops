# R2: adversarial review of agent M's stage-1 speed campaign (round 8)

Subject: `round8/M_stage1_speed.md` sections 1-7; code at HEAD `57f70155`
(M's pass-3 commit; the working tree of the reviewed files is clean, so
the reviewed text is the final one, not the intermediate state 7.8
describes): `FiniteFieldDeferredForcing.wl` (473 lines, new),
`FiniteFieldStripSolve.wl` (+278), `FiniteFieldGaugePullBack.wl` (+48),
`EpsFormStripInFrame.wl` (+95), `Backends/flint/flint_deferred_ast_eval.c`.
Rules kept: package read only, every kernel through the seat launcher
under 300 s, nothing committed. Evidence under `scratchpad/round4/R1/r2/`
(test logs; `r2_dag_adversarial.wls` + `.log`, 6.5 s after load, every
probe under `TimeConstrained[..., 90]`).

**Tests run (launcher walls from the seat log).** `t_finite_field_round2`
`failed: {}` (27 booleans True, 0 False), `t_finite_field_adaptive_sampling`
6 booleans True, 0 False, `t_multiquadratic_transport_frame` 20 assertions
0 failed (3.2 s after load), `t_deferred_bundle_chart_compatibility` 20
PASS 0 FAIL. All exit 0.

**Adversarial fixture** (`r2_dag_adversarial.wls` on CF300 (12,9), the
plan built as in M's `dag_probe.wls`, prime 2147483423; the input's
forcing slot is the zero placeholder, its exact alphabet 6 letters, the
census adds 10 with pole orders {2,2,3,2}): P1 chunk boundary (batch limit
1024 vs 7 on 30 images) values SameQ; native batch 1 thread vs 8 threads
`BBarBatch` SameQ. P2 image cache crossing its reset inside one call: see
F1. P3 a regular point OK (no chart-pole point found by a one-line solve;
the preflight's typed rejection is by construction, `:180-192`). P4 small
primes: 2 -> `DeferredForcingSingularChartPoint`, 7 ->
`DeferredForcingBatchFailed`, 101 -> OK (fail closed). P5 census: SameQ
letters and powers under another seed and another prime; `DegreeBound 8`
-> `DeferredForcingLineFitFailed` (typed, never a smaller alphabet).

## Findings, ranked

### F1 (medium, correctness of a module contract): the image cache's reset inside a multi-chunk call returns status OK with Missing values

`FiniteFieldDeferredForcing.wl:244-245` clears the cache when it exceeds
400,000 entries, inside the chunk loop, after earlier chunks of the same
call have been written; `:262` then reads every requested image back from
the cache. Failing input (fixture P2): cache pre-filled to 399,998
entries, batch limit 8, 20 uncached images -> `"Status" -> "OK"`, 8 of 20
`"Values"` are `Missing["KeyAbsent", ...]`, cache size 12. The sampler
(`FiniteFieldStripSolve.wl:1735`) puts those straight into `forcingTable`.
Reachable in a long-lived kernel (the pool's REUSE mode: ~13 k images per
strip, so after ~30 strips) whenever the threshold falls inside a call.
Downstream this is a non-numeric row, i.e. almost certainly a typed or
hard failure of that sample, not a wrong acceptance -- but the module's
contract ("OK" = every value present) is broken. Fix: collect the chunk
results in a local list and reset the cache only between calls (or
return the values from the local list).

### F2 (medium, production route): on the KernelPool broker path every helper sample fails and is recomputed locally

`FiniteFieldStripSolve.wl:3502`: `brokerQ` is True on a pool kernel when
the pilot sample costs >= 8 s per prime -- the hard strips. The helper
task (`FiniteFieldStripBroker.wl:20-29`) rebuilds the preparation from the
record (the census travels in it) and calls `SampleEpsFormStripAffine`,
which on the DAG route asks `finiteFieldDeferredForcingImages[key, ...]`;
the plan lives only in the solving kernel's `$finiteFieldDeferredForcingRegistry`
(`FiniteFieldDeferredForcing.wl:117, 226`), so the helper gets
`DeferredForcingPlanUnknown`, `SampleEpsFormStripAffine` returns `$Failed`
(`FiniteFieldStripSolve.wl:1731-1732`), and the broker's local fallback
(`FiniteFieldStripBroker.wl:105-108`) recomputes the batch on the solving
kernel. Results stay right; the pool parallelism is silently lost on
exactly the strips the mandate targets, plus the wasted helper round
trip. Also the wave prefetch is disabled under the broker (`:3583`), so
the per-point `fetchForcing` path (one native process per point) is what
runs. M's tests and rungs are single-kernel and cannot see this. Fix:
make the plan reconstructible on the helper (it is a function of the
input file, chart data and root images already in the record) or ship
it in the record; add a pooled run to the evidence.

### F3 (medium, report): the (25,18) lead ignores the recorded no-go

7.11 reads the 46 inconsistent offset/shell systems as an ansatz-family
question and proposes the `GaugeDenominatorFactor` widening (eps powers
in the source-frame gauge denominator). But Codex's 2026-08-30 note 05
records a frame-independent integrability obstruction for this block
(gauge-eliminated screen, defect 1 at three images: no strict rational
dlog form), and the plan's round-8 state repeats it; T's transport route
exists because of it. An ansatz that is inconsistent at every offset is
the expected outcome of a block with no dlog form, not evidence for a
missing widening; a 14-minute probe ladder per candidate widening would
chase a solution that the obstruction says does not exist. The genuine
progress is narrower than 7.11 states: the chart route now reaches the
sampler in 13 s where it used to sit 25 minutes in materialization, and
returns typed. Recommendation: run the integrability screen (which the
DAG images can now feed) before any ansatz widening, and cite the no-go
in the report.

### F4 (low-medium, contract naming): the DAG-route acceptance record labels a modular check "Numerical"

The strip-level check that replaced `VerifyEpsFormStrip["Numerical"]` is
`finiteFieldDeferredForcingResidualQ` (`EpsFormStripInFrame.wl:1552-1566`,
`FiniteFieldStripSolve.wl` final check): 16 random points at a random
31-bit prime, unseeded (`FiniteFieldDeferredForcing.wl:429-430`), stored
under `NumericalPfaffianResidualsZero` with `Certificate -> "NumericalResidual"`.
The exactness picture is otherwise unchanged and honest: the chart-route
record already carried `FrameCertificate["Exact"] -> False`,
`ExactDLog -> Missing["DeferredToFamilyCertificate"]`, `familyCertificate
-> Required` (`:1585-1620`) before this pass; no exact strip-level
statement was downgraded, and the family certificate (which does not read
the strip records' forcing slot) remains the one exact statement, as the
check-levels decision prescribes. What `VerifyEpsFormStrip["Exact"]` in
7.4(3) proves: the DAG-route gauge satisfies the exact Pfaffian identity
against the exactly materialized chart strip -- the same object the
sampler solved (same `data`, `rootImages`, Jacobian; the census ansatz is
smaller, so a different representative of the same class). That is
offline evidence, not part of the acceptance. Fix: name the key
`ModularPfaffianResidualsZero`, record the seed, prime and point count.

### F5 (low): wrong-image paths are fail-closed, with two residual gaps

A singular image inside the DAG (`ST_SINGULAR_IMAGE`, evaluator `:393,
456, 468, 508`), an undeclared radical, a resource limit (`base_count >
4096/grade_count`, `:265`, which M's `Floor[4096/gradeCount]` chunk
matches) all fail the whole request, and `Images` returns
`DeferredForcingBatchFailed` (`:240-241`); a chart pole or a root-image
mismatch is rejected at the preflight (`:180-192`); the threads write
disjoint slots and share only the failure flag under `omp critical`
(`:1198-1260`); fixture P1 confirms 1 vs 8 threads and the chunk split
give identical images. Gaps: (a) one singular point among a wave's
`requestedPointCount + 8` fails the whole sample (`:1731`) instead of
rejecting the point as a pole did; (b) the DAG route caps attempts at
`2 requestedPointCount` drawn points (`:1719, 1739`) where the exact route
kept drawing to `maximumAttempts` -- a strip with many gauge-denominator
rejections now fails a sample earlier. Both typed, neither a wrong
acceptance; both probability ~1e-9 per point at 31-bit primes.

### F6 (low, census completeness): the conjugate sign variants cover one radical at a time

`FiniteFieldDeferredForcingCandidateFactors` (`:326-327`) applies a
single sign to every half-power in an operand base. For an inverted base
`a + b r + c s` with two source roots the norm has four conjugates; the
(+,-) and (-,+) pieces are never candidates. Consequence is fail-closed
(the degree-consistency check refuses and the strip falls back to the
exact route, `:380-389`), so this is coverage, not soundness; R1 and R4
(2-3 roots) pass because no such base occurs there. I could not build a
strip fixture (a deferred preparation with such an operand) inside the
budget. The census is otherwise sound in the sense that matters: letters
and pole orders are line-verified maxima, two lines and the full
denominator degree must agree, a too-low bound refuses (P5), and the
"double count" it removes on R1 ({14,11} -> {12,10}) is a sign duplicate
of `DeleteDuplicates[..., SameQ]` -- so it is correct, not merely
different, wherever it accepts.

### F7 (informational): what a production sector run now does differently

`FACET_DEFERRED_FORCING` unset -> DAG route (`:71-72`); on every chart
strip with a deferred preparation: no exact pull-back before the inner
solve; the strip record's forcing slot is a zero placeholder plus a
`DeferredForcing` descriptor (key + census); alphabet and gauge
denominator from the census; the post-pull-back check modular (F4);
family certificate Required as before. Readers of a record's forcing slot
that do not know the descriptor would see a zero forcing: the ones I
checked (`finiteFieldStripPrepare`, the sampler, the final check, the
in-frame zero-forcing shortcut which authenticates the input placeholder,
the family certificate) all handle or do not use it; the obstruction and
resume readers were not audited. No family name in package code (comments
only).

## Measurement honesty (point 3)

- "Before" and "after" are the same route and the same inputs: the
  chart route through `SolveEpsFormStripInFrame` on the same two sector
  files, exact route = pass-2 code re-measured in the same session
  (43.6 / 196.3 s), DAG route 21.9 / 113.2 s; against the untouched
  baselines (51.3 / 245.6 s) 2.3x / 2.2x. M states in his own words that
  the several-fold target is met on the materialization (12x-43x on that
  stage) and not on the whole strip.
- How much is the materialization skip: R1 gains 21.7 s, of which
  ChartPullBack 11 s + prepare 4.3 s = 15.3 s is the skip and ~6 s the
  pass-2 fibre fits; R4 gains 83 s while the skip alone is 95 s
  (ChartPullBack 75 + prepare 20) -- the DAG route gives back 13 s in
  sampling (image batches) and 6 s in the gauge pull-back, and the pass-1
  Jacobian change no longer runs there. So on the hard rung the whole
  gain is the skip; the levers of passes 1-2 are inside the skipped stage.
- The CF303 (25,18) ceiling: "census 12.5 s, prepare 0.33 s, then 46
  inconsistent systems at ~18 s each until BudgetExhausted" is measured
  and reproducible from the logs; its interpretation is F3.

## Recommendations, in priority order

1. F1: no cache reset inside a call (local chunk list); a unit assertion
   with a pre-filled cache.
2. F2: make the plan available on pool helpers (rebuild from the record
   or ship it) and put one pooled run of R4 in the evidence with the
   helper success count.
3. F3: run the integrability screen on (25,18) from the DAG images before
   any widening; cite the no-go.
4. F4: rename the modular residual key, seed it, record prime and points.
5. F5(a): reject a singular point instead of the sample; F6: all sign
   combinations for multi-root bases (or a typed note that the census
   covers one radical per base).
6. Unchanged from M's own list: lever 1 (batched adapter solves) and
   lever 3b, which are where the remaining R4 time is.

## Verdict

Finished with the listed fixes: the DAG route is exact where it claims
to be (images SameQ with the exact pull-back, fail-closed evaluator,
line-verified census, no strip-level certificate downgraded), the
speed-ups are measured on the same route and stated plainly against the
target, and the four required tests pass; the cache-reset defect (F1)
and the lost pool parallelism (F2) must be fixed before the route
carries a sector campaign, and the (25,18) lead (F3) should be replaced
by the recorded no-go.
