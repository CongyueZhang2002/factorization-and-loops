# Frozen M0 regression fixture (acceptance oracle)

Frozen 2026-08-20 as milestone M0 of the finite-field optimization plan
(exchange: fable_finite_field_optimization_proposals_2026-08-20.md,
codex_assessment_and_addons_fable_ff_optimization_2026-08-20.md,
fable_critical_review_codex_ff_assessment_2026-08-20.md).

Contents:
- `fixture_CF254_9_7.wl` — the CF254 off-diagonal block (9,7) coupling
  record: Family/Sector/LowerSector, Variables {x,y}, Regulator eps,
  Strip {e,c,bbar}. THE benchmark input; never regenerate it.
- `result_fixture_CF254_9_7_FiniteField.wl` — the exactly verified
  solve of that fixture (2026-08-20 benchmark, single kernel,
  Concurrent -> True): numerator offset {1,0}, 7 primes, sample counts
  {32, 15, 15, 15, 15, 15, 15}, wall 7254 s. Its `BackendResult` holds
  the exact gauge and residues that every optimized implementation must
  REPRODUCE (same normalization) or match up to a verified affine
  transformation.

Acceptance rule for M1+ (unchanged at every milestone): the exact,
unspecialized, both-variable Pfaffian residuals of the produced gauge
are identically zero, and for regression comparability the discovered
normalization columns must be recorded in every run's artifacts.

Bookkeeping note to resolve in M0 (asked of Codex 2026-08-20): this
fixture/ansatz counts 2144 unknowns (1936 gauge + 208 residue, rank
2128, nullity 16), while the 2026-08-19 review packet recorded 1953
unknowns / rank 1937 for the same coupling — presumably an
ansatz/denominator-census version difference; the frozen system of
record is THIS one.

Instrumentation state at freeze: `SampleEpsFormStripAffine` records
SetupSeconds (outer symbolic setup — previously untimed),
PreprocessingSeconds, SamplingSeconds (point/matrix build),
RankSeconds, AugmentedRankSeconds, LinearSolveSeconds,
NullspaceSeconds, PeakMemoryBytes.
