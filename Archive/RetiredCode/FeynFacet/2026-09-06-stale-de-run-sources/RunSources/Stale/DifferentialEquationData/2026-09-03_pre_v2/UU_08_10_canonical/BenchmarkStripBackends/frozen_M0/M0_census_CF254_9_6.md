# M0 census — CF254 (9,6), finite-field, production allocation

Run 2026-08-20 22:16–22:39 on the user's explicit go: 2 P-cores,
KernelCount 1, fresh artifacts. Solved exactly (both-variable Pfaffian
residual zero), wall 1399.5 s (vs 1365 s for the same strip in the
concurrent 6-job benchmark: single-kernel cost is intrinsic).
Machine-readable: `M0_census_CF254_9_6.wl`; raw artifacts with
per-sample `SampleTimings` in `census_run/`.

- 7 primes, samples per prime {32, 15, 15, 15, 15, 15, 15} = 122.
- Sampled system 736 x 728, 505,632 nonzeros (94% dense), rank 724,
  nullity 4. Peak kernel memory 0.41 GB.
- Timed stages sum to 1314 s (94% of wall); mean 10.8 s per sample.

| stage | total s | share |
|---|---:|---:|
| SetupSeconds (alphabet via CANONICA, dlog table, residue layout, factor census, ansatz) | 462.4 | 35.2% |
| SamplingSeconds (finite-field points + matrix build) | 425.9 | 32.4% |
| PreprocessingSeconds | 120.4 | 9.2% |
| RankSeconds | 68.7 | 5.2% |
| AugmentedRankSeconds | 66.1 | 5.0% |
| LinearSolveSeconds | 86.5 | 6.6% |
| NullspaceSeconds | 84.1 | 6.4% |

Reading, against the (9,7) diagnostic (2176 x 2144, eliminations ~81%
of a 60 s sample): the cost split is REGIME-DEPENDENT. Setup is ~4 s
per sample in both regimes; elimination scales superlinearly with the
unknown count. On small blocks — the majority across the 91 families —
the per-sample rebuild of regulator/prime-independent setup (O1) plus
the matrix build (O2) is 77% of the time and A1 can save at most ~17%;
on large blocks A1 dominates. The production dispatcher should apply
both, and the regression suite needs both fixtures.
