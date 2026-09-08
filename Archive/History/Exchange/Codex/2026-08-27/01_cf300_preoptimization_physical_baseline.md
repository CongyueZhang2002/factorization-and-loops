# 01 — CF300 `(12,9)` pre-optimization physical baseline

> **Recorded:** 2026-08-27 16:11 PDT
> **Disposition:** terminated at the user's request after this record
> **Result:** no solved block or modular reconstruction checkpoint persisted

## Physical problem

- Family/block: `CF300`, sector 12, lower sector 9.
- Direct multiquadratic regulator reconstruction.
- Unknowns: 2,260.
- Original equations/points: 37 accepted points per image.
- Affine rank/nullity: 2,208 / 52.
- Simultaneous right-hand sides: 53 (particular plus 52 nullspace
  directions).
- Adopted support: `{0,0}` with zero support defect.
- Runtime allocation: one Wolfram main kernel, eight configured subkernels,
  native thread ceiling eight, process affinity CPUs 0--15.

The loaded kernel predates the current source changes for prime-local
regulator growth, removal of the duplicate native-core replay, the Production
three-projection all-row certificate, and per-prime reconstruction telemetry.

## Work completed before termination

- Good primes 1--6 completed with nine regulator images each.
- Prime 7 completed nine images, then requested a tenth interpolation image.
  The old global schedule-growth code backfilled that tenth image for all
  seven accepted primes.  Six earlier held-out-validated primes were
  needlessly revisited; seven tenth-image solves were executed in total.
- The seven-, eight-, and nine-prime rational lifts were all rejected.
- Prime 10 had completed 3 of 10 images when this baseline was recorded.
- The exact CFFA4 payload write was 42,777,659 bytes per image.  Relative to
  the end-of-prime-6 counter (`wchar = 2,403,691,045`), the final counter
  (`wchar = 4,072,019,746`) is exactly 39 further payloads:
  9 prime-7 images + 7 global backfills + 10 prime-8 images + 10 prime-9
  images + 3 prime-10 images.
- Including the first six nine-image batches, at least 93 scheduled CFFA4
  image solves were paid by the reconstruction trace.

No file in the sector checkpoint directory was modified after the input seal
at 11:27.  The current implementation keeps accepted images, interpolants,
CRT state, and the constrained plan only in memory, so this partial progress
cannot hydrate a later run.

## Prime-height evidence

The current symmetric rational reconstruction accepts a reduced coefficient
`n/d` only when both `Abs[n]` and `d` are at most
`Floor[Sqrt[(M - 1)/2]]`, where `M` is the accepted-prime product.

| Accepted 31-bit primes | Modulus bits | Symmetric height capacity | Outcome |
|---:|---:|---:|---|
| 6 | 186 | `7.0028*10^27` | rejected |
| 7 | 217 | `3.2452*10^32` | rejected |
| 8 | 248 | `1.5038*10^37` | rejected |
| 9 | 279 | `6.9690*10^41` | rejected |
| 10 | 310 | `3.2295*10^46` | incomplete |

Therefore the empirical minimum for this run is at least ten 31-bit primes.
The old kernel did not retain whether each rejected prefix failed the height
test outright or produced a small congruent alias rejected by fresh provider
images.

## Wall and resource baseline

- Elapsed at record: 4 h 28 min 44 s.
- Mean process CPU reported by `ps`: 1,466%, with observed instantaneous
  utilization commonly 14--18 logical cores.
- Resident memory at record: 6,927,252 KiB (about 6.6 GiB).
- Wolfram process threads: 80.
- No I/O wait or memory pressure was observed.
- Per-image intervals on the late primes were usually about 2--4 minutes.
- The separate physical-size CFFA4 benchmark for the 2,260-square,
  53-right-hand-side native solve was about 0.50 s at eight native threads.
  Thus the native solve itself was not the dominant per-image cost; the old
  Wolfram 53-RHS all-row replay and numeric image construction were.

## Comparison contract for the optimized route

An optimized rerun should record the same dimensions and mathematical result
and report the following separately:

1. preparation, coefficient evaluation, row assembly, native solve,
   projected residual, interpolation, CRT/lift, and fresh-validation times;
2. zero duplicate native-core replays after a verified CFFA4 solve;
3. one exact all-original-row replay of every affine right-hand side and zero
   duplicate square-core replays.  The later physical-shape stress test found
   only about 1.5x from three projected residuals in a sub-second phase, so
   that probabilistic machinery was rejected and removed;
4. prime-local regulator growth, with no recomputation of an earlier
   held-out-validated prime when a later prime requests another image;
5. learned per-prime image counts and the exact number of avoided images;
6. an atomic accepted-prime checkpoint that resumes at the next prime, after
   the speed-critical image path unless a campaign must start first;
7. lift-attempt history distinguishing height failure from fresh-image alias
   rejection, plus exact post-success coefficient height and minimum prefix;
8. end-to-end wall time and peak RSS, not only native microbenchmarks.

Only after this 31-bit baseline is green should a full-limb pilot compare ten
31-bit batches with approximately six 61-bit batches.  GPU work remains
conditional on optimized telemetry showing that regular coefficient
evaluation or row assembly dominates.
