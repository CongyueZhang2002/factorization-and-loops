# M1 standardized and accepted, 2026-08-21

Your M1 exploration was verified on our side (end-to-end (9,7) solution
SameQ to the frozen oracle, exact residual zero; bookkeeping
reconciliation accepted) and ported into `FiniteFieldStripSolve.wl`
behind the existing seams, per your two implementation notes: no
interception seam — the pilot (`"DiscoverPlan" -> True`) returns the
plan from inside the sampler, and later samples do exactly one
`LinearSolve` of the constrained core with nullity+1 right-hand sides;
rank/consistency metadata come from the plan plus the all-row checks,
with typed Discard statuses filtered from interpolation. Solver option
`"Elimination" -> "Constrained"` (default) | `"Full"`. Degenerate
nullity-0 blocks handled. Tests: `t_finite_field_constrained_solve`
(constrained sample reproduces the full path's normalized particular
and nullspace exactly on the real (9,6) record) plus the existing four,
all green.

Acceptance on CF254 (9,6), 2 cores / 1 kernel, fresh artifacts:

| | M0 | O1 | O1+M1 |
|---|---:|---:|---:|
| wall | 1399.5 s | 1035.5 s | **755.9 s** |
| eliminations | 305 s | 312 s | 83 s (one factorization) |
| setup | 462 s | 58 s | 0 s |
| primes / samples / discards | 7 / 122 / — | 7 / 122 / — | 7 / 122 / 0 |
| gauge, residues | oracle | identical | identical |

Combined 1.85x on the small fixture; your 2.28x per-sample algorithmic
figure on (9,7) stands as the large-regime number. Remaining (9,6)
cost is matrix build 59% + preprocessing 17%: O2/your add-ons 1+3
(production builder, fused point evaluation) and A2 (incremental
regulator sampling) are the next levers there.

Known v1 gap, tracked: discarded samples are filtered but not yet
REPLACED (the validation margin and fullRetry cover it today); the
replace-on-discard rule lands with the M2 scheduler work.

M2: your installation contract (modular affine carry, augmented
`[A,-C]` solve through the same constrained machinery, atomic install
at chain closure, full p,N as fallback, never particular-only) is
accepted as the design and is the next architecture item on our side;
the nonzero-Schur-rank pair you flagged (a CF265 block below the CF254
embedding, or CF231's remaining row) is the regression we'll want
before calling compression measured.
