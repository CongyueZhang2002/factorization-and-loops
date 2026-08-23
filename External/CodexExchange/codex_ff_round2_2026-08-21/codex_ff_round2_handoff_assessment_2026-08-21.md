# Codex finite-field round-2 handoff and assessment — 2026-08-21

I read `fable_ff_round2_assignment_2026-08-21.md`, including the O2 addendum,
and kept the agreed ownership boundary: every Codex source and result in this
handoff is external. **No FeynFacet package file was edited.** Runs used one
main Wolfram kernel or at most four Wolfram/FLINT workers. No unrelated process
was stopped or signalled.

## Outcome

All three assigned tracks now have frozen-fixture evidence:

- **A2:** 122 regulator images become 70 (10 per prime) on both fixtures.
  Every modular interpolation is `SameQ` to its stored oracle; the lifted
  candidate passes an unseen-prime residual before the exact check and then
  reproduces the exact gauge and residues.
- **A3:** the a-priori infinity/finite-divisor certificate finds the exact
  85-monomial support on `(9,7)`: 2144 -> 1568 unknowns and 68 -> 50 points.
  On `(9,6)` it safely retains 124 monomials where the recovered answer happens
  to use 123: 728 -> 548 unknowns and 92 -> 70 points. Both reproduce the exact
  oracles.
- **A4:** on the actual `(9,7)` 2144-square constrained core with 17 RHS,
  FLINT at four threads is 0.555 s end-to-end at 31 bits and 0.650 s at 61
  bits, including conversion, 37 MB transfer, verification, and import. The
  corresponding Wolfram sparse walls are 13.413 s and 19.003 s.

Machine-readable aggregate:
`codex_ff_round2_2026-08-21/codex_ff_round2_measured_summary.wl`.

## A2 — incremental regulator sampling

### Measured frozen runs

| fixture | primes | samples per prime | total images | four-worker prime-loop wall | one-time preparation | one-time pilot | exact/oracle |
|---|---:|---|---:|---:|---:|---:|---|
| CF254 `(9,6)` | 7 | `{10,10,10,10,10,10,10}` | 70 | 122.56 s | 11.28 s | 4.35 s | exact residual zero; all oracle fields `SameQ` |
| CF254 `(9,7)` | 7 | `{10,10,10,10,10,10,10}` | 70 | 553.73 s | 5.23 s | 72.36 s | exact residual zero; all oracle fields `SameQ` |

The prime-loop walls are parallel-throughput numbers, not single-kernel claims.
The algorithmic result independent of scheduling is the image reduction:
`32 + 6*15 = 122` becomes `7*10 = 70`, a 42.6% reduction. No sample was
discarded in either acceptance run.

Per-prime four-worker sampling walls were:

- `(9,6)`: `{16.27, 11.63, 12.06, 12.87, 12.04, 12.54, 12.17}` s;
- `(9,7)`: `{139.56, 70.23, 69.47, 68.79, 67.37, 67.98, 67.79}` s.

The first `(9,7)` entry includes the 72.36 s unconstrained plan-discovery
pilot. Ordinary constrained samples remain about 22 s each on one worker;
this is why A3/A4 matter even after A2.

### Scheduler and certification contract

1. The first prime begins with four construction images and retains **all**
   minimal-total-degree Padé splits. Choosing the first split is incorrect:
   four points cannot distinguish `0/3`, `1/2`, `2/1`, and `3/0`.
2. Three held-outs reject the provisional degree-three fits for the true
   `{3,3}` coordinates. Failed held-outs are promoted into construction data,
   only failed coordinates are refit, and three fresh held-outs bring the
   first prime to ten images.
3. Later primes use the learned seven-coefficient degree profile plus three
   held-outs, again ten images.
4. A failed held-out check always grows the construction set; it is never
   accepted. A changed degree profile rejects the prime.
5. After sufficient CRT height, the candidate is lifted without exact
   verification, tested at prime `2147483563` that was absent from the lift,
   and only then sent to the exact two-variable Pfaffian check.

At three through six CRT primes, rational lifting correctly failed. At seven
it succeeded on both fixtures, the unseen-prime residual vanished, and the
exact check passed.

The current package reconstruction guard encodes only the deterministic
`2(m+n)+1` rule. The prototype does **not** pretend ten points meet that rule;
it preserves the deterministic requirement as metadata and uses a separate
held-out/unseen-prime/exact certification mode. Standardization should make
the certificate type explicit rather than weaken or spoof the existing key.

Sources/results:

- `codex_ff_round2_2026-08-21/CodexA2IncrementalRegulatorPrototype.wl`
- `codex_ff_round2_2026-08-21/RunA2OracleSimulation.wls`
- `codex_ff_round2_2026-08-21/RunA2FrozenEndToEnd.wls`
- `codex_ff_round2_2026-08-21/a2_oracle_simulation_result.wl`
- `codex_ff_round2_2026-08-21/a2_real_CF254_9_6/`
- `codex_ff_round2_2026-08-21/a2_real_CF254_9_7/`

## A3 — certified sparse Newton support and pole bounds

### Certificate, derived without the oracle

The prototype uses valuations at every finite forcing divisor and at the
projective infinity divisor.

- If the forcing has pole order `b_f` at an irreducible finite divisor `f`,
  the first-order Fuchsian equation bounds the gauge pole by `b_f - 1`.
  Reconstructing these exponents reproduces the package gauge denominator
  exactly on both fixtures.
- The diagonal epsilon-form entries and every dlog derivative have at most
  simple finite poles and infinity degree at most `-1` on both fixtures.
  Therefore derivative shifts and diagonal multiplication preserve the bound.
- If `delta_B` is the largest forcing infinity degree, the gauge infinity
  degree is bounded by `max(0, delta_B + 1)`. Intersecting that total-degree
  half-space with the already selected bidegree rectangle gives the lattice
  support.

For `(9,7)`, the denominator total degree is 12 and `delta_B = -1`, hence

`0 <= px,py <= 10`, `px + py <= 12`.

This contains 85 lattice monomials—exactly the frozen 85-of-121 regression
support, but computed before the oracle is opened. For `(9,6)`, the bound is
`px + py <= 15` inside the `{12,12}` rectangle, giving 124 monomials. The
oracle happens to have one additional accidental zero at `{12,3}`; the
prototype correctly does not learn that zero from the answer.

The persisted closure certificate checks derivative downward closure,
logarithmic diagonal/dlog infinity behavior, simple finite poles, and exact
finite-denominator reproduction. The growth ladder adds one total-degree
shell on inconsistency or a held-out residual and terminates at the full
rectangle:

- `(9,7)`: support counts `{85,93,100,106,111,115,118,120,121}`;
- `(9,6)`: `{124,133,141,148,154,159,163,166,168,169}`.

### Measured reduced systems

| fixture | unknowns | points | reduced matrix | nullity | Wolfram constrained solve | exact/oracle |
|---|---:|---:|---|---:|---:|---|
| `(9,6)` | 728 -> **548** | 92 -> **70** | `560 x 548` | 4 | 0.284 s | exact residual zero; gauge/alphabet/residues `SameQ` |
| `(9,7)` | 2144 -> **1568** | 68 -> **50** | `1600 x 1568` | 16 | 5.155 s | exact residual zero; gauge/alphabet/residues `SameQ` |

Every retained sampled row annihilates both the particular solution and the
homogeneous basis, and the affine normalization blocks are exact identities.
The modular particular solutions are `SameQ` to independent modular images of
the exact oracles. Projected seven-prime A2 data then lift in the sparse basis,
pass the unseen-prime residual, and pass the exact check.

The integration must make monomial support a first-class part of the ansatz
fingerprint and build only retained columns. The external timing above prunes a
captured full matrix, so it demonstrates elimination savings but understates
the build savings from 50 rather than 68 points.

Sources/results:

- `codex_ff_round2_2026-08-21/CodexA3SparseNewtonPrototype.wl`
- `codex_ff_round2_2026-08-21/RunA3SupportCensus.wls`
- `codex_ff_round2_2026-08-21/RunA3SparseNewtonFrozen.wls`
- `codex_ff_round2_2026-08-21/a3_sparse_newton_result_CF254_9_6.wl`
- `codex_ff_round2_2026-08-21/a3_sparse_newton_result_CF254_9_7.wl`

## A4 — backend benchmark

The benchmark uses genuine `(9,7)` sampled systems at both primes. The 61-bit
matrix is not a coefficient relabeling: a cloned external O2 sampler replaces
packed constructors by unpacked exact-integer arithmetic. At `p=1000003`, its
matrix, RHS, and accepted points are all `SameQ` to the frozen system before it
is trusted at wider primes.

Core: `2144 x 2144`, 17 RHS, 1,825,840 nonzeros (39.7% density).

| prime | Wolfram sparse, core included | Wolfram dense, conversion included | FLINT 1 thread, all transfer included | FLINT 4 threads, all transfer included |
|---|---:|---:|---:|---:|
| 31-bit `2147483423` | 13.413 s | 14.072 s | 1.248 s | **0.555 s** |
| 61-bit `2305843009213693951` | 19.003 s | 20.093 s | 1.658 s | **0.650 s** |

FLINT solve-only walls at four threads are 0.410 s and 0.504 s. The binary is
37.07 MB; packed conversion is about 0.005 s and export about 0.084 s. FLINT
verifies `A.X=B`, and imported one- and four-thread solutions are `SameQ` to
both Wolfram solutions. Native Wolfram sparse is slightly faster than dense,
so it remains the appropriate no-dependency fallback.

The dependency worthiness benchmark is strong, but no integration was made.
The candidate authorization/MANIFEST record is:
`codex_ff_round2_2026-08-21/codex_a4_flint_manifest_candidate_2026-08-21.md`.

Sources/results:

- `codex_ff_round2_2026-08-21/codex_a4_flint_solve.c`
- `codex_ff_round2_2026-08-21/RunA4BackendBenchmark.wls`
- `codex_ff_round2_2026-08-21/a4_backend_benchmark_result.wl`

## Assessment and recommended standardization order

1. **Land A2 first.** It is regime-independent, compounds O2 immediately,
   and needs no external dependency. Introduce an explicit probabilistic
   interpolation certificate whose required terminal gates are unseen-prime
   and exact residual checks.
2. **Land A3 next.** It reaches Fable's exact `(9,7)` target without oracle
   leakage and reduces both matrix width and point count. Put support into O2's
   monomial tables so the dropped columns are never materialized. Keep the
   shell-growth ladder and rectangle fallback mandatory.
3. **Send FLINT through the authorization gate.** Its measured margin is too
   large to ignore. A process/binary adapter is already worthwhile; an
   in-memory adapter can remove the remaining roughly 0.1 s transfer later.
4. **Only then test a wider-prime production schedule.** Seven current primes
   provide roughly 206 aggregate bits. Three 61-bit primes plus the small
   pilot provide a similar bit budget, but actual sparse sampling,
   reconstruction height, exceptional-prime behavior, and exact checks must be
   measured before reducing the prime list.

## Add-ons from the measurements

- **Use A3 before plan discovery.** The current `(9,7)` pilot costs 72.36 s.
  Discovering normalization and independent rows on the 1568-column support,
  preferably through the selected backend, attacks a large serial startup.
- **Batch by scheduler phase, not by prime nesting.** With four workers, issue
  seven construction tasks, synchronize, then issue three held-outs. A flat
  `(prime,epsilon)` queue can fill otherwise idle workers while respecting
  early CRT termination and memory limits.
- **Fuse support and backend layouts.** A3 should emit ordered exponent arrays
  consumed directly by O2 and by the FLINT matrix writer; avoid constructing a
  2144-column SparseArray only to select 1568 columns.
- **Add a hard width guard to O2.** The packed evaluator's `2^62` intermediate
  assumption is valid near 31 bits, not at 61 bits. Wider primes require
  unpacked arithmetic, compiled `mulmod`, or backend-native evaluation.
- **Preserve all affine rows.** Even with a square constrained core, evaluate
  every sampled equation as a residual guard. Both A3 reductions did this and
  retained nullities 4 and 16.
- **Do not multiply headline speedups.** A2 removes tasks, A3 removes points
  and columns, and A4 changes elimination. They should compound, but build,
  lift, and exact-check stages remain. The next acceptance run should report a
  fresh stage decomposition rather than extrapolate a product of ratios.

