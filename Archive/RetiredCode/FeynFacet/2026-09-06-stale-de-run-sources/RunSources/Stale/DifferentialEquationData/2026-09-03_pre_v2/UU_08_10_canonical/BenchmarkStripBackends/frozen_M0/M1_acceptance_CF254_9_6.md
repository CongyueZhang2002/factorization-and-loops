# M1 acceptance — constrained one-factorization solve, CF254 (9,6)

Run 2026-08-21 00:00–00:13, 2 P-cores, KernelCount 1, fresh artifacts
(`m1_run/`), O1 + M1 together, against the M0 census and O1 runs.

| stage (s) | M0 | O1 | O1+M1 |
|---|---:|---:|---:|
| wall | 1399.5 | 1035.5 | **755.9** |
| Setup | 462.4 | 58.5 | 0.0 |
| Preprocessing | 120.4 | 131.6 | 126.8 |
| Sampling (point/matrix build) | 425.9 | 398.6 | 446.1 |
| Rank + AugmentedRank + Nullspace | 218.9 | 228.5 | 0.0 |
| LinearSolve (one constrained factorization) | 86.5 | 83.5 | 83.4 |
| primes / samples | 7 / 122 | 7 / 122 | 7 / 122 |
| solve path | four eliminations | four eliminations | 122/122 constrained, 0 discards |
| exact gauge / residues | oracle | identical | identical |
| exact Pfaffian check | True | True | True |

Combined factor 1.85x on the small fixture. Plan discovered by the
pilot: rank 724, nullity 4, normalization columns {677, 681, 682, 683}
(pinned into the interpolation). Remaining cost on (9,6): matrix build
59%, preprocessing 17%, solve 11% — O2 (build) and A2 (sample count)
are the next levers for the small regime; on (9,7)-class blocks the
constrained solve is the dominant gain (Codex measured 2.28x per
sample algorithmically).

Implementation (FiniteFieldStripSolve.wl): `finiteFieldStripDiscoverPlan`,
`finiteFieldStripIndependentRows`, the `"EliminationPlan"` /
`"DiscoverPlan"` sampler options, solver option `"Elimination"`
(`"Constrained"` default, `"Full"` fallback). Tests:
`t_finite_field_constrained_solve` 9/9 and the four other finite-field
tests green.
