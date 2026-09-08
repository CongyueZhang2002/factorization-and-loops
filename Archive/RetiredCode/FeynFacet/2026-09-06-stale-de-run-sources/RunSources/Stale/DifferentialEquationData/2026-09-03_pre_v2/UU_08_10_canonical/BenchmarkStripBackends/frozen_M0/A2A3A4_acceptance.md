# A2 + A3 + A4 acceptance — Codex round-2 optimizations standardized

Codex's three round-2 off-diagonal-block optimizations
(`External/CodexExchange/codex_ff_round2_handoff_assessment_2026-08-21.md`)
are now in the package, verified against the frozen O2b oracle. 2026-08-21,
production allocation (1 Wolfram kernel, taskset -c 0,1,6, FLINT ≤4
threads), fresh artifacts each run.

## What landed

- **A3 (a-priori sparse support).** `finiteFieldStripPrepare` now emits a
  `SupportCensus`: from valuations (forcing pole orders at finite
  divisors, forcing/diagonal/dlog degrees at infinity, simple-pole
  hypotheses) it bounds the gauge numerator total degree by
  `denominatorTotalDegree + max(0, forcingInfinityDegree + 1)`, with a
  closure certificate. `finiteFieldStripSupport` returns the retained
  `{px,py}` list; `SampleEpsFormStripAffine` builds ONLY those columns
  (option `"Support"`, default Automatic); the solver runs a shell-growth
  ladder (`"SupportShell"`) that adds one total-degree shell per
  inconsistent probe and falls back to the full rectangle.  Derived
  without the oracle: (9,7) 121→**85** monomials (2144→**1568** unknowns);
  (9,6) 169→**124** (728→**548**).
- **A2 (held-out regulator sampling).** `finiteFieldStripHeldOutInterpolate`
  fits every coordinate from a small construction prefix, keeps all
  minimal-total-degree Padé splits, rejects wrong ones on fresh held-out
  images, promotes a failed held-out into construction data, and rejects
  a prime whose degree profile changed.  The solver runs it by default
  (`"RegulatorSampling" -> "HeldOut"`); the first prime learns the degree
  profile, later primes reuse it; the deterministic schedule is the cap
  and fallback.  A lift is now taken WITHOUT the exact check first, guarded
  by an **unseen-prime residual** (a prime absent from the lift), and only
  then sent to the exact both-variable Pfaffian check.  122 regulator
  images → **70** (10/prime) on both fixtures.
- **A4 (FLINT backend).** `FeynFacet/Backends/flint/flint_modular_solve.c`
  (Codex's adapter, unchanged; `build.sh` → gitignored `bin/`).  The
  constrained core with all RHS goes to FLINT `nmod_mat_solve` through a
  binary process adapter (`"Backend" -> Automatic`, used when the binary
  exists and the core is ≥256 wide; falls back to `LinearSolve`).  Every
  imported solution is re-verified in Wolfram by the existing all-row
  residual checks.  MANIFEST updated (libflint 3.0.1, LGPL-2.1+).
  Measured on the (9,7) 1568-square constrained core: solve **4.9 → 0.35 s**
  per sample.

## Frozen acceptance (vs O2b oracle: gauge, residues, alphabet SameQ)

| fixture | O2b (before) | A2+A3+A4 | speedup | primes | images/prime | support | exact |
|---|---:|---:|---:|---:|---:|---:|---|
| CF254 (9,6) | 249.7 s | **157.1 s** | 1.59× | 7 | 10 | 124 | residual zero, SameQ |
| CF254 (9,7) | 7254 s | **1446.2 s** | 5.02× | 7 | 10 | 85 | residual zero, SameQ |

Per Codex's warning the three do not simply multiply: on (9,7) the
remaining cost is the point/row BUILD (mean ~14 s per sample, the O2
evaluator), not the solve (0.35 s FLINT) or interpolation (2.7 s total)
or lift (2.4 s) or exact check (53 s).  Stage totals on (9,7):
sampling 1057 s (build-dominated, 4 workers in the parallel benchmark →
~150 s/prime wall), interpolation 19 s, lift 2.4 s, exact check 53 s.
The next lever is the build itself (O2 evaluator / native-backend
evaluation), exactly as the round-2 assessment predicted.

## Tests

`Tests/t_finite_field_round2.wls` (support census 124/548 and certificate,
sparse-probe consistency, held-out solve exact + fewer images + agrees
with deterministic + mode recorded, FLINT solve matches Wolfram / absence
falls back).  The five existing FF tests stay green; the adaptive-sampling
test pins `"RegulatorSampling" -> "Deterministic"` since it asserts the
deterministic pilot schedule.

## Addendum (2026-08-21 evening): independent check and four fixes

Independent recomputation from the stored artifacts confirmed the table
above (gauge/residues/alphabet SameQ, exact residuals recomputed zero, FLINT
on 70/70 samples). Four open items were then fixed in
`FiniteFieldStripSolve.wl` — prime-width guard (p < 2^31), degree-probe
order (shell 0, rectangle, then shells), reserve primes always outside the
schedule and recorded as `UnseenPrime`, and a test that exercises the
held-out mechanics at nontrivial degrees. (9,6) re-run with the new probe
order: 140.9 s, oracle-identical. Record: `verification_2026-08-21/`.

## Addendum (2026-08-22 night): sampler restructure + production check level

CF254 (9,7), one POOL SUBKERNEL, fresh artifacts, `FinalCheck -> Numerical`:
**187 s** (per prime 13-16 s; sampling 105 s; interpolation 19.5 s; lift
2.5 s; numerical Pfaffian check 2 s), gauge and residues SameQ to the oracle.
Sampler A/B on identical samples: build 15 -> 2.9 s per sample, identical
solutions (the residue columns are built from the alphabet x 2 dlog forms
instead of a 6656-entry forcing tensor). The exact Pfaffian check (57-60 s)
is now development-only; the exact statement is the family certificate.
Note: `wolframscript` main kernels run these builds ~3x slower than pool
subkernels (cause not identified); compare pool runs with pool runs.
