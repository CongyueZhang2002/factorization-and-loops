# 01 — Remove the dominant cost from adaptive multiquadratic reconstruction

> **Status:** [🟡] In progress
> **Owner:** Codex
> **Scope:** general two-variable rational and multiquadratic strip providers;
> no family-specific dispatch in `FeynFacet/Private`

## Goal

Reduce the wall time of a hard direct multiquadratic off-diagonal solve by
removing repeated work from each regulator image and each added CRT prime.
Keep only changes that buy a material fraction of the end-to-end route.  The
mathematical output remains one common rational-in-regulator affine section,
with exact normalization and independent fresh-prime provider residuals.

## Immediate high-value goals

- [🟢] Eliminate raw-expression hashing from every accepted finite-field
  point.  The physical CF300 `(12,9)` profile measured 182.927 s per image:
  171.678 s in coefficient evaluation, including 136.634 s in 7,659 sparse
  compile/cache calls.  Only 148 were misses; 7,511 hits repeatedly hashed
  the same 207 large scalar occurrences at each of 37 points.  Build one
  authenticated split-sparse provider plan per prime, compile each unique
  leaf once, and address every occurrence by an integer/positional map.  Keep
  exact substitution fallback for uncompiled leaves and fail closed on
  provider, root-order, or prime mismatch.  The physical gate is complete:
  the recurring image first fell from 182.927 s to 35.270 s (5.19x), then
  to 3.848 s after the native batches below.  The planned/unplanned
  finite-field matrix and RHS agree exactly.

- [🟢] Move the flattened sparse polynomial arithmetic, point preflight, and
  numeric row assembly into three bounded native batches.  All 43,808 grade
  coefficients and the complete physical matrix/RHS agree exactly with the
  Wolfram routes.  The warm CF300 image is 3.848 s; sparse evaluation is
  1.115 s, row assembly 0.230 s, and preflight 0.148 s, with zero fallbacks.
  The recurring image is now 47.5x faster than the 182.927 s baseline.

- [🟢] Reuse the exact split-plan topology across primes and reduce only its
  coefficients modulo the new prime.  First-prime plan construction is
  16.15 s; a later prime is 2.35 s with zero repeated exact compilation.

- [🟢] Parallelize independent follower images through the existing flat
  TaskBroker, with one mission share and up to seven free helpers.  The
  physical eight-image gate is exact and decisive: 47.179 s serial,
  30.596 s for the first cold eight-wide wave, and 6.189 s after helper
  caches warm (7.62x).  Admission order remains the regulator schedule,
  malformed results retain the exact local fallback, and no nested Wolfram
  kernels are introduced.

- [🟢] Remove whole-sample/whole-solution pilot hashing.  Pilot admission
  already checks image keys, dimensions, the exact particular residual,
  every nullspace residual, and the canonical free-column identity.  Hashing
  millions of matrix entries added no mathematical evidence and is no longer
  part of construction or reconstruction.

- [🟢] Remove repeated deep validation of objects built in the same call.
  The physical 61-bit CF300 run spent roughly two minutes re-canonicalizing
  and re-hashing the freshly built preparation/layout/provider before its
  first mathematical image.  The production driver now uses one explicit
  same-call trusted boundary with cheap structural/cross-object checks;
  standalone reconstruction keeps full validation by default.  A newly
  discovered affine pilot also no longer repeats the dense particular and
  nullspace replay immediately after the native solver verified every row.
  The finite-field round-2 gate passes 26/26 after this change.  No additional
  hashes are permitted on this route unless a persistent cross-process cache
  exhibits a concrete corruption mode; fresh provider-equation residuals are
  the mathematical certificate.

- [🟢] Restore the residue-integrability screen to its intended evidence
  budget: two configured images plus the requested fresh images.  It had
  accidentally consumed the adaptive reconstruction Cartesian pool and ran
  707 obstruction images.  The adaptive prime pool now remains confined to
  reconstruction.

- [ ] Make adaptive reconstruction resumable at accepted-prime boundaries
  after the speed-critical image path and 61-bit pilot are complete, or
  earlier only if a long campaign must start before those changes land.
  Atomically checkpoint only the accepted per-prime interpolants, prime and
  regulator ledgers, expected degree profile, normalization columns, and the
  constrained plan needed by followers.  Do not persist dense sampled
  matrices, provider expressions, or a web of object hashes.  On resume,
  rebuild the current provider and replay one stored interpolation at a fresh
  point before continuing.  Require exact resumed-versus-uninterrupted output
  and one interrupted-write fixture; add further defenses only for a failure
  that actually occurs.

- [🟢] Reject and remove the three-projection Freivalds residual path.  The
  physical-shape stress test measured only about 1.5x in a sub-second phase,
  far below one percent of the repeated image wall.  Production and
  Development now share one exact all-original-row, all-RHS replay; the
  nonce/projection/probabilistic ABI and its stress test were deleted.

- [🟢] Remove the duplicate Wolfram square-core replay after a successful
  native CFFA4 solve.  CFFA4 already verifies the square core exactly; the
  imported solution remains provisional until exact normalization and the
  all-original-row certificate.  Source and adversarial fixtures are ready;
  runtime validation remains.

- [🟢] Allow the existing CFFA4 multi-RHS backend to use 1--8 native threads.
  A 2,260-by-2,260, 53-RHS benchmark improved from 1.55 s at one thread to
  0.50 s at eight threads.  This is useful but not the dominant live cost.

- [🟢] Run and retire the 2,400-by-2,260, 53-RHS residual stress benchmark.
  Its result rejected the projected path; adversarial rank-jump coverage
  remains in `t_multiquadratic_constrained_affine_plan.wls`, which passes
  30/0 on the simplified exact-only source.

## Avoid unnecessary regulator images

- [ ] Learn the actual regulator `SampleCount` from the first accepted prime
  and let each later prime begin with that many images, rather than forcing
  `InitialRegulatorCount -> 9` for every prime.  Preserve the existing four
  construction plus three disjoint held-out images.  Implement the reduced
  starting count only if physical telemetry shows that fewer than nine images
  were consumed.

- [🟡] Make regulator-schedule growth prime-local.  The live CF300 run provided
  direct evidence: after the seventh prime used nine images, interpolation
  requested one more and the current global `values` logic began backfilling
  a tenth image for every previously accepted prime.  Prior held-out-validated
  interpolants do not need the same regulator points or sample count; CRT
  requires the same normalized degree profile.  Keep their caches unchanged
  and grow only the prime that returned `MoreSamplesRequired`.

- [ ] Add focused tests proving that prime-local image growth gives identical
  interpolants, degrees, CRT coefficients, and fresh validation when primes
  use different regular regulator points or sample counts.  Exceptional
  images must still be replaced independently per prime.

- [🟢] Stop rediscovering the regulator degree profile at every prime.  The
  61-bit physical run exposed the current dominant phase: all 2,260
  coordinates repeatedly scan every Padé numerator/denominator split, with
  adaptive fits growing through 9, 11, 13, 15 and 17 fibres.  Once the first
  good prime has fixed each degree pair, later primes now solve only that
  split and request exactly
  `Max[InitialConstructionCount, max(n+d)+1] + HeldOutCount` fibres.  Complete
  a native FLINT batch for both first-prime discovery and fixed-profile fits.
  The focused gate passes 6/6: native discovery agrees coefficient-for-
  coefficient with Wolfram, fixed profiles work at 61 bits, changed profiles
  are rejected, and automatic dispatch is active.  On 2,120 coordinates the
  native discovery measured 0.0086 s with eight threads; fixed-profile fitting
  is already 0.0018 s on one thread, so it deliberately avoids OpenMP startup.

- [🟢] Promote failed held-out fibres one at a time in native discovery.  The
  former three-at-once rule incorrectly turned every failed validation batch
  into three new construction points.  The exact boundary regression at total
  degree 22 now accepts with 26 samples / 23 construction points instead of
  28 / 25; a degree-4 discovery uses 8 / 5 instead of 10 / 7.  Release and
  ASan/UBSan self-tests pass.  On 2,120 coordinates the new discovery costs
  0.0382 s on one thread and 0.00705 s on eight threads; fixed-profile
  reconstruction is unchanged.

- [🟢] Retain a monotone per-coordinate lower bound on total regulator degree.
  After every candidate at degree `d` has failed a newly promoted point,
  later construction supersets cannot make any degree `<= d` viable again.
  The old native loop nevertheless rescanned all of them from zero.  On the
  captured 42-image, 2,260-coordinate CF300 input, retaining this one integer
  per coordinate reduced the exact same 8-thread result from 38.52 seconds to
  4.58 seconds (8.41x); the output files are byte-identical.  Release and
  ASan/UBSan self-tests pass.  This is a mathematical search-bound reuse, not
  a cache fingerprint or probabilistic shortcut.

- [🟢] Stop the degree census at its actual information boundary.  At 66
  images, 1,184 coordinates in the current direct-provider stream had no
  representative through total degree 64; the other 1,076 were waiting on
  those peers.  More images cannot repair a fixed degree-64 cap, so stopping
  was correct and blindly raising the package default is rejected.  This
  result characterizes that captured data stream only: it does **not** prove
  that the affine section itself has degree above 64.

- [🟢] Resolve the historical-status versus current direct-provider
  contradiction before changing the section.  The 11:38 run already used the
  deferred-bundle `SplitBranch` route from an uncommitted source snapshot; it
  was not a compiled-channel run.  The surviving baseline says six 31-bit
  primes were held-out-valid after nine images, but no raw acceptance log,
  canonical table, degree profile, or interpolant survived; the byte counters
  prove scheduled image solves only.  By contrast, the current route
  reproduces the same 1,184/1,076 nonterminal split at both 31 and 61 bits,
  and a Wolfram reference subset also requests more samples.  On the current
  physical matrix, historical Wolfram RREF and the new FLINT constrained plan
  now agree exactly on rank, pivots, all 52 normalization columns, and all
  2,260 canonical coordinates, with an exact all-row residual.  The
  registered-family-frame comparison also agrees on root squares/order,
  denominator, normalization rows, one-forms, coefficient ABI, and provider
  expressions.  A fresh 31-bit run persisted all nine canonical vectors and
  reproduced the `1184 ambiguous / 1076 shortfall` split; a Wolfram refit of
  ten ambiguous coordinates independently requests more samples.  The old
  six-prime narrative is therefore retained only as an unauthenticated
  observation from a lost dirty source state.  Full evidence is in
  `Exchange/Codex/2026-08-27/05_cf300_interpolation_contradiction.md`.

- [🟡] Search the affine nullspace for a low-regulator-degree normalization
  section only if the cross-route equality test proves that the historical
  and current systems are identical and the earlier low-degree evidence is
  invalid.  Reuse captured affine fibres, keep the current residue pins, and
  compare general column-order policies without encoding CF300 or physical
  column numbers in package source.  Promote a new policy only after fresh-
  prime nonsingularity and a material degree reduction.

- [🟢] Reject the proposed structural-prime parallel scheduler.  The audited
  implementation added roughly 574 production lines plus 135 test lines to
  save an estimated 35--70 seconds once per solve.  It was reverted; the
  concise serial quorum remains the deterministic admission path.  Revisit
  only if measured end-to-end telemetry makes this stage material and a thin
  prefetch can demonstrate at least a 1.5x stage gain.

## Avoid unnecessary CRT primes

- [🟡] Add an advisory required-prime estimator to every adaptive lift.  After
  each failed prefix, report the current modulus and symmetric height bound,
  the number and distribution of unresolved coefficients, and a
  lower/likely/conservative estimate for the additional 31-bit primes.  Use
  continued-fraction candidate heights and prefix-to-prefix stability as
  diagnostics, then calibrate the estimate retrospectively from the exact
  numerator/denominator heights once reconstruction succeeds.  Record both
  `EstimatedPrimeCount` and `ActualMinimumPrimeCount` in the final telemetry.
  The estimate is scheduling information only: it must never accept a lift,
  cap adaptive accumulation, or replace same-prime reprojection and unseen-
  prime provider validation.  The compact attempt history, preserved
  coefficient locations, lower/likely/conservative count, and exact
  post-success minimum-prefix calculation are implemented; runtime fixtures
  and physical CF300 calibration remain.

- [ ] Back-test the completed physical exact result against every prefix of
  its accepted prime list.  For each prefix, report unresolved, ambiguous,
  and wrong-but-congruent coefficient counts and the earliest prefix that
  reproduces the final vector and passes the reserved unseen-prime checks.

- [ ] If the back-test proves that the symmetric
  `B = Floor[Sqrt[(M - 1)/2]]` bound forced an extra whole prime, add a small
  asymmetric-bound ladder only for coefficients that fail the existing fast
  path.  Each box must satisfy `2 N D < M`; accept exactly one deduplicated
  reduced fraction, while zero or multiple candidates request another prime.
  Keep the existing same-prime reprojection and fresh unseen-prime provider
  residuals unchanged.  Do not add maximal-quotient heuristics or LLL unless
  the bounded ladder demonstrably fails and a later method has a clear win.

- [ ] Reject the asymmetric ladder unless it saves at least one complete
  physical prime batch, returns zero ambiguous or incorrect unique
  coefficients, and costs less than `Min[2 seconds, 5% of one prime batch]`.

## Conditional second-wave optimizations

- [🟡] Run a bounded full-limb-prime pilot after the 31-bit source is green.
  Five 61-bit primes roughly replace nine 31-bit primes; six exceed the
  capacity of the current ten-prime prefix.  FLINT supports a word-size
  modulus, but the present provider ABI deliberately requires `p < 2^31` so
  products stay machine integers.
  Audit every prime gate and move sampling, root arithmetic, row assembly,
  and residual products to safe `__int128`/FLINT/Montgomery arithmetic before
  admitting a 61-bit pool.  Promote only if a real image costs at most 1.35x
  the 31-bit image and the complete reconstruction improves by at least 1.5x;
  reject a route that merely trades fewer primes for Wolfram big integers.
  The physical single-image pilot passed: 3.804 s warm at 61 bits versus
  3.848 s at 31 bits, with exact leaf channels, complete rows/RHS and follower
  solution.  A full adaptive run is measuring accepted-prime count; its
  bottleneck is the Wolfram Padé scan, not wide-field arithmetic.

- [ ] Consider a GPU provider-evaluation prototype only after post-Freivalds
  physical timing.  Do not port CRT, rational reconstruction, or the native
  solve: those phases are small or branchy, and the 2,260-square FLINT solve
  is already about 0.5 s.  If coefficient evaluation plus row assembly still
  exceeds 60% of an optimized image, batch accepted points, regulator fibres,
  and prime lanes into a custom 31-bit modular CUDA kernel and require at
  least a 2x end-to-end physical-family gain.  Otherwise record GPU as a
  measured no-go; stock cuSOLVER/cuBLAS is not a finite-field backend.

- [🟢] Promote the bounded TaskBroker follower wave after the physical
  eight-image gate measured 7.62x warm throughput and 1.54x even while all
  seven helpers built their first process-local plans.  Automatic uses only
  currently free helpers and respects the native-thread processor ceiling.

- [ ] Consider an ephemeral provider-prime plan plus a two-fibre point
  context only if post-Freivalds timing still puts coefficient sampling first.
  It may share compiled sparse records, x/y monomial factors, regulator-free
  roots, one-forms, and bundle sites while retaining separate per-fibre poles,
  accepted points, rows, normalization, and evidence.  Require at least 1.3x
  pair throughput and byte-for-byte equality with two scalar calls on ranks
  zero through three.  Do not modify `BlockEquationDeferred.wl` for this.

- [🟢] Move the flattened numeric row assembler to the native CPU backend.
  This is complete: physical row assembly fell from 8.285 s to 0.230 s and is
  included in the exact 3.848 s recurring-image gate.  No further assembler
  rewrite is justified by the remaining fraction of wall time.

- [🟢] Do not reduce the physical point count blindly.  CF300 uses 37 points
  where 36 are the rank-count minimum, so the maximum possible saving is only
  one point and does not justify weakening the affine system.

- [🟢] Do not add more support machinery for the current block.  The physical
  support ladder already adopted the minimal support `{0,0}` with zero defect.

## Campaign and validation goals

- [🟢] Record and terminate the pre-optimization copied-state CF300 `(12,9)`
  run at the user's request.  Seven, eight, and nine 31-bit primes were
  empirically insufficient; the tenth had completed 3/10 images.  The full
  physical baseline is in
  `Exchange/Codex/2026-08-27/01_cf300_preoptimization_physical_baseline.md`.

- [ ] After the sole main kernel is released, run the constrained affine,
  follower authentication, modal reconstruction, installed-family chain, and
  physical residual stress gates on the final source.

- [ ] Use the validated optimized source for the remaining CF259 and CF303
  triple-root families.  Run through the broker pool so deferred symbolic
  materialization can use its already measured helper route.

- [🟢] Record physical phase timings for preparation, provider preflight,
  coefficient evaluation, row assembly, core solve, exact all-row residual,
  interpolation, CRT/lift, and fresh validation.  The first isolated image
  profile is recorded in
  `Exchange/Codex/2026-08-27/02_cf300_image_hotloop_profile.md`; it identifies
  repeated sparse-cache key hashing as the original dominant cost.  The
  measured 5.19x recurring-image improvement and the new arithmetic profile
  are recorded in
  `Exchange/Codex/2026-08-27/03_split_plan_physical_speedup.md`.  Extend this
  record with solve/interpolation/lift/fresh-validation timings on the
  optimized end-to-end rerun.

## Completion conditions

- [ ] One real triple-root off-diagonal block is installed and accepted by the
  family certificate.

- [ ] The focused adversarial suites and the integrated package gate are green
  on the final source.

- [ ] No retained optimization is family-specific, default-off ghost code, or
  substantial machinery for only a few percent of one minor phase.

- [ ] The measured end-to-end improvement and the exact number of avoided
  regulator images and CRT primes are recorded in `Exchange/Codex`.
