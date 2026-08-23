# M0 census result and a regime-dependent correction, 2026-08-20

M0 is complete: `SampleEpsFormStripAffine` now records `SetupSeconds`
(the outer symbolic setup your diagnostic could not see) and
`PeakMemoryBytes`, and `SolveEpsFormStripFiniteField` persists every
sample's stage timers into the prime artifact (`"SampleTimings"`), so
every production run is self-instrumenting. The (9,7) oracle is frozen
in `BenchmarkStripBackends/frozen_M0/`; the census below ran on (9,6)
at the production allocation (2 cores, 1 kernel), by user decision —
(9,7) was judged too expensive to re-run for a census.

## CF254 (9,6) census

Solved exactly, wall 1399.5 s (1365 s in the concurrent run: the
single-kernel cost is intrinsic). 7 primes, {32, 15x6} = 122 samples.
System 736 x 728, 505,632 nonzeros (94% dense), rank 724, nullity 4,
peak memory 0.41 GB. Timed stages = 1314 s, 10.8 s per sample:

| stage | total s | share |
|---|---:|---:|
| SetupSeconds | 462.4 | 35.2% |
| SamplingSeconds (points + matrix build) | 425.9 | 32.4% |
| PreprocessingSeconds | 120.4 | 9.2% |
| RankSeconds | 68.7 | 5.2% |
| AugmentedRankSeconds | 66.1 | 5.0% |
| LinearSolveSeconds | 86.5 | 6.6% |
| NullspaceSeconds | 84.1 | 6.4% |

Full tables: `frozen_M0/M0_census_CF254_9_6.{md,wl}`; raw artifacts
with per-sample timers in `frozen_M0/census_run/`.

## What this changes — and what it does not

Your (9,7) diagnostic stands: at 2144 unknowns the eliminations are
~81% of a 60 s sample and A1 is the right first target THERE. But the
split is regime-dependent. Setup is ~4 s per sample in both regimes
(it is regulator- and prime-independent work rebuilt on every call:
the CANONICA `ExtractIrreducibles` alphabet extraction, dlog table,
residue layout, factor census, ansatz); elimination grows
superlinearly. On (9,6)-sized blocks — which are the majority of the
off-diagonal blocks across the 91 families — O1 hoisting plus O2
build is 77% of the time and A1 can save at most ~17%.

Consequences for the plan:

1. O1 moves back up for the small regime: hoist the setup to
   once-per-strip (fingerprinted cache as you proposed) and the
   preprocessing to once-per-prime. Expected on (9,6): ~460 s -> ~4 s
   for setup, i.e. roughly 1.5x on its own, before touching the build.
2. A1 stays first for the large regime. Both land in production; the
   dispatcher does not need to choose — the same code path benefits
   from both, with the gain shifting with size.
3. A2 (incremental regulator sampling) is regime-independent: 122
   samples for a nullity-4, {3,3}-degree system is the same
   oversampling you diagnosed on (9,7).
4. Density note for A4: (9,6) is 94% dense (your (9,7) was 40%), so
   the sparse/dense crossover question resolves toward dense for small
   blocks; the SparseArray conversion per point is pure overhead there.
5. Regression suite: both fixtures are pinned. A change must not
   regress either regime.

No change to the M1/M2 assignment: you explore A1 and the affine-row
state; we standardize. If you want to take O1's hoist into your M1
prototype since it touches the same sampler, say so — otherwise we
implement O1 on our side in parallel, against the (9,6) census as its
acceptance measurement.
