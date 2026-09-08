# Blockwise Libra vs finite-field sector route — speed test (2026-08-22/23)

One Wolfram main kernel, cores 0-9, no subkernels, same machine for both
sides.  Libra side rerun tonight; finite-field side from the 2026-08-22
run logs (no rerun, user decision), with the time of the two bugs fixed
on 08-22 (symbolic row gauge, Simplify census) separated out.

## Blockwise Libra route (fresh runs)
`libra_saved_blockwise_epsform.wls FAMILY LibraTwoRoot_20260819 OUT 300 LocalOnly`
then `libra_checkpoint_factor_dependence.wls` (budget 600).

| family | n | coupled pairs | FuchsifyBlock step time | Fuchsification stage wall | factor/dlog stage wall | total |
|---|---|---|---|---|---|---|
| CF385 | 44 | 175 (63 needed a step) | 253 s | 1385 s | 389 s | **1774 s (30 min)** |
| CF408 | 41 | 176 (84 needed a step) | 322 s | 1774 s | 326 s | **2100 s (35 min)** |

The 08-19 record "1-6 min per family" was the sum of the FuchsifyBlock
step times only (`Steps[[All,"Seconds"]]`, 221/287 s); the per-pair
full n x n symbolic conjugation (`applyFull`) and the two `FuchsianQ`
checks per pair, which dominate, were never timed.  On the hard
families (CF231, CF305 (8,7); CF254 (9,8); CF265 (14,13)) the route
times out at the first hard pair (08-19 records: 4 x 300 s) and
completes nothing.

## Finite-field sector route (08-22 logs)
CF408, sectors 7-29 (sectors 2-6 are seconds), per-sector timestamps:

| phase | measured 08-22 | after the 08-22/23 fixes |
|---|---|---|
| block solves (340 blocks, 3 primes each) | 960 s | ~780 s (zero-forcing blocks skipped) |
| per-sector regulator factorization | 562 s | ~100-150 s (2-point ladder + gate) |
| row gauge (symbolic inverse bug) | 1703 s | 2-40 s per sector (~200 s) |
| census tail (Simplify bug) | 719 s | ~2 s per sector |
| **total** | **3955 s (66 min)** | **~19-21 min (estimate, not rerun)** |

Measured post-fix fragment: CF408 sectors 27-29 (n = 39-41) 405 s = block
solves 127 s + row gauge 59 s + factorization 202 s (-> ~50 s with the
gate).  CF385 sectors 19-30 measured 2242 s, of which 1441 s were the
two bugs.

Hard families (8 subkernels, finite field): CF265 13 min, CF305 ~32 min,
CF231 45 min.  Zero-root families (29, 08-22): 2-61 s each.

## Reading
Per easy 40-master family the two routes are within a factor of two of
each other once the finite-field route's bugs are out (Libra 30-35 min
measured; finite field ~20 min estimated, 66 min as actually run on
08-22); the finite-field route also parallelizes its block solves over
subkernels and is the only one that finishes the hard families.  The
hybrid (Libra first, finite field for the pairs that time out) would
not buy speed: the Libra stage's cost is the per-pair full conjugation,
not the Fuchsification.
