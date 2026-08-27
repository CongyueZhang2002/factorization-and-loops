# Fable -> Codex: assessment of the live CF300 (12,9) run — 2026-08-27 ~15:30

Written at the user's request after an outside look at the running solve
(launched 11:38, 7th CRT prime at ~3.5 h). Verdict up front: **the run is
healthy and is the deepest any (12,9) attempt has ever gone; nothing looks
mathematically wrong.** The wall time has three causes you have already
diagnosed yourself in
`Goals/Codex/2026-08-27/01_adaptive_multiquadratic_reconstruction_performance.md`;
this note adds three items I believe are missing from that list, and one
recommendation with a concrete decision boundary.

## What I verified from outside

- Main kernel (PID 1788453) at ~17 cores instantaneous, 5.5 GB of 47 GB
  resident — actively computing, not wedged.
- The run executes from the main tree (checked `/proc/<pid>/cwd`), i.e. the
  code snapshot on disk at 11:38: your morning state, **without** the
  three-projection residual patch and the no-core-replay patch finished this
  afternoon.
- Preparation through the integrability screen took ~2 minutes (old global
  route: 2710.9 s for preparation alone, measured 2026-08-25 —
  `Results/UU_08_10_canonical/FamilyEpsFormsSolving/MultiquadraticMeasurementNarratives_2026-08-26.md`).
  Support ladder adopted minimal `{0,0}` with zero defect; 68-letter
  alphabet passed the integrability screen (rank 176/176).
- The kernel holds **no open output file** (checked `/proc/<pid>/fd`): all
  accepted primes live only in process memory. Nothing under
  `sector_CF300_standard/` has been written since the 11:27 input seal.

## Historical comparison (the user asked for old-run context)

There is no successful earlier (12,9) run to compare against:

| Attempt | Outcome |
|---|---|
| 2026-08-23 (pool + standalone, v2–v4 candidates) | never reached reconstruction |
| 2026-08-24 standalone | cancelled at 4656 s with zero (12,9) progress lines — stuck in old exact preparation; `CF300_12_9_unsolved.wl` |
| 2026-08-25 frozen-fixture end-to-end | reached the modular system, failed `InconsistentModularSystem` (spawned your correction goal) |
| **2026-08-27 (live)** | **preparation 2 min, ladder zero-defect, per-prime held-out validation passing, 7th prime accumulating** |

So "7 primes, 3 hours, no result" is a record, not a regression. Seven
31-bit primes ≈ 217-bit modulus ≈ ~108-bit recoverable numerator/denominator
heights — plausible for this block, not yet pathological.

## The three costs (your list, confirmed)

1. Exact all-row replay of the 53 affine right-hand sides per accepted
   image — dominant; patch on disk, not in the kernel.
2. Duplicate Wolfram square-core replay after each successful native CFFA4
   solve — patch on disk, not in the kernel.
3. Global regulator-schedule backfill observed live at prime 7: the 10th
   image is being repeated for all prior primes although CRT needs only the
   same normalized degree profile per prime, not the same sample points.
   Fix (prime-local growth) designed, unimplemented. This makes every
   further prime progressively more expensive.

## Three items I believe your goal list is missing

1. **Per-prime checkpointing.** All 7 accepted primes exist only in RAM.
   A crash or license hiccup loses ~3.5 h, and it forecloses the otherwise
   attractive move of restarting on the patched engine *while keeping the
   primes already earned* (legitimate by your own argument: prior primes
   need not share regulator points). One sealed record per accepted prime —
   interpolants, degree profile, prime, validation evidence — fits the
   authenticated-checkpoint pattern you already built for preparation
   substages. This is, in my view, the highest-value small item on the
   board: it converts the restart decision from all-or-nothing into a
   warm resume.
2. **Idle subkernels during the dominant loop.** The 8 attached subkernels
   have been idle since the deferred materialization at +130 s. Regulator
   images within a prime are independent affine solves; with 9–10 images
   per prime this is the natural parallelism. Your follower-image wave is
   default-off pending the post-Freivalds profile — reasonable discipline,
   but I'd rank re-evaluating it above the other conditional second-wave
   items.
3. **Convergence telemetry per prime.** With no prime estimator, "tall
   coefficients" and "wrong ansatz" are indistinguishable from outside.
   One printed number after each prime — the fraction of coefficients whose
   rational lift has stabilized across the last two prefixes — separates
   them: climbing means keep paying; stalled means stop and investigate the
   model. This is one line of output and needs no new mathematics.

## Recommendation

Let the current run finish. A restart today would discard all 7 primes
(no checkpoints) to bet on runtime-unvalidated patches — bad trade. But set
a boundary now: if the lift has not succeeded by roughly the 12th prime
**and** the resolved-coefficient fraction is not climbing, stop and treat it
as a model question, not a height question, rather than paying the growing
backfill tail. While the sole main kernel is occupied, the three items
above plus prime-local growth are exactly the work that makes the next run
fast, restartable, and self-diagnosing — whether or not this one lands.

— Fable, 2026-08-27

## Addendum (~15:50): historical prime counts correct my boundary

Measured from the accepted block records (`"ModularPrimeCount"` field; the
`"Primes"` lists are only the held-out validation primes): solved blocks in
the 2026-08-22 two-root campaign needed **up to 22 CRT primes** (CF231 and
CF305 both have accepted blocks at 22; counts of 12–22 are common among the
hard ones). The solved CF303 triple-root blocks needed 3, but none is in
the (12,9) class. So 7 primes is well within precedent and possibly not
halfway; my "investigate around the 12th prime" boundary above was too
tight. Keep the resolved-fraction telemetry as the discriminator, but do
not treat prime count alone as a stopping signal below ~20. This raises the
weight of prime-local schedule growth and per-prime checkpointing further:
under global backfill the marginal cost of primes 8–15 is exactly where the
current engine hurts most.

## Addendum 2 (~16:10): optimization review with the user — one new lever

The user asked which optimizations are worth pursuing (symbolic
pre-simplification, fewer primes, GPU). Assessment, recorded here so the
reasoning is shared:

1. **Wider primes — the one item not on your goal list.** We reconstruct
   with 31-bit primes; FiniteFlow and FireFly both use ~63-bit primes,
   which halves the prime count for the same coefficient heights at
   roughly unchanged cost per prime, and also halves the total image
   count. FLINT handles 62-bit moduli natively (`nmod` with 128-bit
   intermediates); the question is whether any part of the compiled
   evaluation path (sparse root-placeholder compiler, CFFA4 lanes,
   Wolfram-compiled arithmetic) relies on 32-bit-safe products. Requesting
   a word-size audit of the modular route; if it passes, this is ~2x fewer
   primes on every remaining hard block and compounds with everything
   else. If part of the path is 32-bit-bound, a mixed scheme (62-bit
   primes in the FLINT solve only) is probably not worth the split
   bookkeeping — audit first, decide on the measurement.

2. **Symbolic pre-simplification: declined.** Prime count is set by the
   bit-heights of the *answer's* coefficients, not the input's form, and
   input-side sharing/cancellation is already done in the deferred
   materialization. The only real symbolic lever left is normalization
   choice (a different gauge normalization changes the coefficients
   themselves and hence the heights) — noted as speculative, no evidence
   the current normalization is bad, not proposed as work.

3. **GPU: declined on cost-benefit.** The GPU-friendly piece (dense
   modular core solve) is ~0.5 s per image — seconds across the whole run;
   the dominant costs (exact row replay, sparse DAG evaluation) are
   irregular and expensive to port; no mainstream community tool runs
   finite-field reduction on GPU; and the campaign has ~5 remaining hard
   consumers to amortize against. The pending CPU patches already deliver
   the same order of magnitude.

Combined outlook if your two finished patches + prime-local growth +
follower-image parallelism + (if the audit passes) 62-bit primes all land:
roughly 25 min/prime x up to 22 primes becomes ~2-3 min/prime x ~8-11
primes. Ranked priority from my side: your patches and prime-local growth
first (already done or designed), then the follower wave, then the 62-bit
audit, then asymmetric bounds.

— Fable, 2026-08-27
