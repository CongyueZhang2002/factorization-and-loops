# Codex M1/M2 exploration handoff and assessment, 2026-08-20

This responds to `fable_ff_milestone_assignment_2026-08-20.md` after reading
that assignment, Fable's critical review, the frozen M0 records, and the
relevant package and historical CF254 sources.

## Executive verdict

- **M1 is ready for Fable to standardize.** The constrained square-core solve
  works on the frozen CF254 (9,7) system, replaces four eliminations by one
  factorization with 17 right-hand sides, checks every original row, and
  reproduces the complete exact frozen result.
- **Use modular affine carry as the primary M2 architecture, but retain full
  `p,N` interpolation as a diagnostic/fallback path.** The reason is avoiding
  exact lifting, storage, and symbolic propagation of 34,304 nullspace
  coordinate functions, not a claimed 16-fold interpolation-time saving. On
  the current fixture, full affine interpolation is only 3.66 times the wall
  time of particular-only interpolation.
- The real CF254 (9,7) -> (9,6) pair consumes a 16-dimensional upstream affine
  state and has an exact two-row residual of zero. In this pair the Schur rank
  is zero: every upstream direction extends. This proves propagation and the
  implementation seam, but it does **not** demonstrate parameter elimination.
  Keep the full-affine fallback until a second real pair with nonzero Schur
  rank is captured as a regression.
- Everything delivered here is external exploration. No FeynFacet/package
  source was edited. Runs used at most four Wolfram subkernels and did not
  stop or modify unrelated processes.

## M0 bookkeeping reconciliation

The 1953/1937 and 2144/2128 records use the same gauge ansatz. The difference
is the residue-coordinate representation.

| record | gauge coordinates | residue coordinates in sampled system | unknowns | rank | nullity |
|---|---:|---:|---:|---:|---:|
| historical 2026-08-19 CF254 (9,7) | 1936 | 17 compatibility-reduced free residues | 1953 | 1937 | 16 |
| frozen M0 CF254 (9,7) | 1936 | 208 raw dlog-residue entries | 2144 | 2128 | 16 |

The historical `CF254_9_7_residue_data.wl` contains 208 residue variables,
191 compatibility rules, and 17 remaining free residues. The current frozen
sampler instead places all `13*4*4 = 208` raw residue entries in the linear
system and lets the sampled equations enforce compatibility. Thus the change
is a residue-elimination/schema choice, not an ansatz or denominator-census
change.

The historical normalization columns were `1937 ;; 1952`. The frozen raw
schema's normalization columns, discovered on the pilot and reproduced by
the oracle, are

```wl
{1937, 1938, 1939, 1940, 1942, 1943, 1946, 1947,
 1950, 1951, 1953, 1954, 1955, 1957, 1969, 1970}
```

These columns must be pinned with the frozen fixture; the historical columns
must not be reused with the raw-residue schema.

## M1: constrained multi-RHS solve

### Construction

For a sampled system `A z = b` with `n = 2144`, generic rank `r = 2128`, and
nullity `d = 16`, the pilot chooses:

1. `d` normalization columns `S` whose restriction to the pilot nullspace is
   nonsingular;
2. `r` independent original equation rows `R` (for this fixture they are
   exactly `Range[2128]`);
3. the square constrained core

   ```text
   B = [ A[[R]] ]
       [  E_S    ] ,       dimensions 2144 x 2144.
   ```

One call to `LinearSolve[B, RHS]` with `d+1 = 17` right-hand sides gives both
the particular vector and a normalized nullspace basis:

```text
RHS_particular = (b[[R]], 0),
RHS_direction j = (0, unit_j).
```

The result is accepted only if `A p-b == 0`, `A N == 0`, the normalization
block is canonical, and every one of the 2176 original rows passes. A singular
or rank-changed core, a failed pivot fingerprint, a bad finite-field point, or
any residual failure marks the epsilon image for discard and replacement.
The end-to-end run exercised this rule; none of its 122 images required
replacement.

Fixture facts: matrix `2176 x 2144`, 1,867,008 nonzeros, rank 2128, nullity
16, 1936 gauge coordinates, and 208 raw residue coordinates.

### One-prime stage measurements

Seconds below are the persisted stage fields. The constrained rows have zero
separate rank, augmented-rank, and nullspace stages because their work is
subsumed by the single solve.

| image/path | setup | preprocess | sample/build | rank | augmented rank | solve | nullspace | stage total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| pilot baseline, eps `1/21` | 2.652 | 1.174 | 10.491 | 10.417 | 9.923 | 13.595 | 14.206 | 62.458 |
| pilot constrained | 2.652 | 1.174 | 10.491 | 0 | 0 | 14.138 | 0 | 28.456 |
| later baseline, eps `1/11` | 2.555 | 1.171 | 9.712 | 9.749 | 10.458 | 13.001 | 13.436 | 60.082 |
| later constrained | 2.555 | 1.171 | 9.712 | 0 | 0 | 12.865 | 0 | 26.304 |

For the later image, elimination falls from 46.644 s to 12.865 s, a 3.626x
elimination speedup. The complete measured sample falls from 60.082 s to
26.304 s, a 2.284x algorithmic speedup. Both pilot and later canonical
particular/nullspace data agree with the baseline exactly.

`PeakMemoryBytes` is included in the artifact, as M0 requires. Wolfram's
`MaxMemoryUsed[]` is monotone over a kernel, and the baseline and constrained
paths ran sequentially, so their absolute peak fields are not an apples-to-
apples comparison. The later constrained call increased the process maximum
by 87,121,296 bytes (about 83 MiB). A production regression should measure
each path in a fresh kernel or record per-call memory growth.

### Exact frozen-fixture reproduction

`RunM1EndToEnd.wls` used the exact frozen allocation:

- primes
  `{1000003, 2147483423, 2147483477, 2147483489, 2147483497,
  2147483543, 2147483549}`;
- epsilon-image counts `{32, 15, 15, 15, 15, 15, 15}`;
- construction counts `{24, 7, 7, 7, 7, 7, 7}` and maximum total degrees
  `{22, 6, 6, 6, 6, 6, 6}`;
- four outer workers, with no nested parallelism.

Prime batch wall times were

```text
{216.035, 111.699, 112.696, 111.646, 112.474, 111.230, 111.861} s
```

and summed to 887.642 s. Interpolation summed to 14.504 s. Reconstruction was
attempted after primes 3, 4, 5, and 6 and correctly failed; the height-required
seventh-prime attempt succeeded in 39.569 s. Total wall time was 953.708 s.

All 122 modular images passed all original rows, with zero discarded images.
The unspecialized two-variable Pfaffian residual is identically zero. `SameQ`
against the frozen oracle is true for the gauge, alphabet, residue matrices,
and normalization columns.

The frozen M0 wall is 7254 s, so the observed four-worker wall comparison is
7.606x. This is a combined algorithm-plus-parallel result. The defensible
algorithm-only claim is the measured 2.284x per-image reduction above; do not
label 7.606x as a single-kernel M1 gain.

### M1 standardization recommendation

Standardize M1 now, with two implementation changes from the exploration
scaffold:

- expose the sampled `A,b` construction as a direct internal function; the
  prototype's ``Internal`InheritedBlock`` interception of the package's two
  `MatrixRank` calls is deliberately external-only;
- create and reuse a factorization object for the constrained core and pass
  all 17 right-hand sides together. Do not reintroduce separate `MatrixRank`,
  `MatrixRank[A|b]`, `LinearSolve`, and `NullSpace` calls merely to populate
  metadata. Rank and consistency metadata should be derived from the selected
  pivots plus the all-row residual checks.

## M2: affine-row state

### Full `p,N` interpolation measurement

The current frozen schema was measured directly from 32 constrained images at
prime 1000003. All original rows passed, and the interpolated particular is
`SameQ` to the M1 modular artifact.

| quantity | particular only | full `p,N` |
|---|---:|---:|
| coordinate functions | 2,144 | 36,448 = 2,144 + 34,304 |
| interpolation wall | 3.224 s | 11.798 s |
| unresolved coordinates | 0 | 0 |
| expression `ByteCount` | 2,764,544 | 44,479,312 |
| measured peak-memory growth | 1,307,488 B | 28,423,808 B |

Full interpolation is 3.660x slower, not 16x slower. It adds 8.574 s to a
205.046 s four-worker sampling batch, about 4.18% of that batch. Its stored
expression is nevertheless 16.09x larger, before multi-prime lifting and
exact symbolic propagation.

The historical compatibility-reduced schema gives the same qualitative
result: 1953 particular plus 31,248 nullspace coordinates, 3.941 s versus
10.607 s (2.691x), 40,639,784 bytes, and 25,169,152 bytes peak-memory growth.

Therefore Fable's coordinate-count concern is real, but the proposed
"16-fold interpolation load" is not a measured wall-time factor on this
fixture. Interpolation alone does not justify a complicated Schur path. The
stronger reasons are avoiding CRT/rational reconstruction of every direction,
avoiding large exact symbolic `N(eps)`, and retaining row dependence without
installing an arbitrary particular solution.

### Real dependent-pair experiment

The demonstrated pair is the consecutive real CF254 chain

```text
CF254 (9,7)  ->  CF254 (9,6).
```

The second fixture was regenerated through the exact CANONICA
`NextEquationD` replay source
`Codex/TwoRootCF254Sector9Lower/provenance_replay/sector_state_CF254_standard.wl`.
Its strip and affine forcing directions agree exactly with the stored source
artifacts.

At a modular image, write the upstream solution as

```text
u = p + N alpha,                  alpha in F_p^16,
A2 z = q2 + C alpha.
```

If `L2` spans the left nullspace of `A2`, downstream compatibility is

```text
H alpha = h,       H = L2 C,       h = -L2 q2.
```

The measured downstream data at prime 1000003 and eps `1/21` are:

- `A2`: `736 x 728`, rank 724, native nullity 4;
- `C`: `736 x 16`, all 11,776 entries nonzero, `ByteCount` 195,248;
- forcing projection: 6.460 s in the standalone symbolic evaluator;
- Schur analysis: 2.960 s;
- `H`: `12 x 16`, rank 0;
- augmented `[A2,-C]`: `736 x 744`, rank 724, nullity 20 = 16 + 4.

Thus the row genuinely consumes a dense perturbation from every upstream
direction, but imposes no constraint on those directions: `C` lies in the
column space of `A2`. A selected nonzero `alpha` was extended to the lower row
and all sampled residuals vanished.

The exact previous gauge is installed `SameQ` to its artifact. The exact (9,7)
residual vanishes in both variables, the public exact (9,6) verifier vanishes,
and the exact pair residual is zero. The two exact checks took 28.359 s and
16.980 s respectively.

### Representation decision

Adopt **modular affine carry** as the production representation, with these
conditions:

1. The carry is per `(prime, epsilon image)` and remains in the finite field.
   Do not interpolate or install an intermediate row before all rows that can
   depend on its affine parameters have been processed.
2. Build and solve the augmented system `[A,-C]` directly using the M1
   constrained multi-RHS machinery. Do not compute a separate left nullspace,
   Schur matrix, Schur rank, and then another solve in the hot path.
3. Construct `C` inside the downstream point sampler while its evaluated
   forcing data are already live. The prototype's separate 6.460 s projection
   is a correctness implementation, not the production design.
4. Retain full `p,N` interpolation behind a diagnostic option and as a safe
   fallback for dependency graphs not yet handled by the modular scheduler.
   It is fast enough to be a valuable oracle.

The standalone prototype spends 9.420 s on forcing projection plus Schur
analysis, comparable to the 8.574 s extra cost of full interpolation. A speed
claim for modular carry therefore depends on the fused implementation above.
Its present demonstrated advantage is architecture, lifting volume, and exact
dataflow—not standalone wall time.

## Installation contract for Fable

### Per-image affine state

Use one shared parameter vector for every solved row in a dependent chain.
A minimal internal association is:

```wl
<|
  "Prime" -> prime,
  "EpsilonValue" -> epsilonValue,
  "SolvedLowerSectors" -> sectorIds,
  "ParameterDimension" -> d,
  "Rows" -> {
    <|
      "Sector" -> sectorId,
      "CoefficientParticular" -> p,
      "CoefficientDirections" -> N,
      "GaugeParticular" -> decodedGaugeP,
      "GaugeDirections" -> decodedGaugeN,
      "ResidueParticular" -> decodedResidueP,
      "ResidueDirections" -> decodedResidueN,
      "Alphabet" -> alphabet
    |>, ...
  },
  "NormalizationPlans" -> plans,
  "RankHistory" -> rankHistory,
  "SourceFingerprint" -> fingerprint,
  "AllRowChecks" -> True
|>
```

Each row's direction list has the same trailing dimension `d`, so the entire
partial transformation is `P + N alpha`, not a collection of unrelated local
nullspaces. `SourceFingerprint` must cover the strip, ansatz, residue schema,
point policy, normalization columns, and selected row core.

### Advancing one row

The affine replacement for `NextEquationD` receives the state above and
returns a base strip plus forcing directions:

```wl
<|
  "BaseStrip" -> {e, c, bbar0},
  "ForcingDirections" -> bbarDirections,
  "ParameterDimension" -> d
|>
```

After sampling, flatten the direction forcing to `C` and solve

```text
[A_k, -C_k] (z, alpha)^T = q_k
```

with a pilot-pinned constrained core. Partition the resulting affine solution
as

```text
alpha = alpha0 + U beta,
z     = z0     + V beta.
```

Then update every old row and append the current one:

```text
old particular' = old particular + old directions . alpha0
old directions' = old directions . U
new particular  = decode(z0)
new directions  = decode(V).
```

The returned state is parameterized only by `beta`; any constraints consumed
by the row have already been incorporated. For certification, also return the
augmented rank, new parameter dimension, pivot fingerprint, and optional
Schur rank. The Schur matrix itself need not be materialized in production.

### Discard, closure, and installation

- Discard and replace the complete `(prime, epsilon image)` if a denominator
  is singular, the augmented rank or pilot pivot pattern changes, the
  constrained core is singular, or any original row residual fails.
- If a normalization plan fails systematically for a prime, reject the prime
  rather than silently choosing an incompatible basis for only some images.
- At dependency-chain closure, choose the final deterministic particular with
  the pinned terminal normalization. Only those selected particulars are
  interpolated, CRT-combined, rationally reconstructed, and exact-verified.
- Install all rows in the closed chain atomically after the unspecialized
  two-variable exact residual passes. Never install an intermediate `p` while
  discarding its `N`.
- If modular scheduling cannot yet cover a graph, use the full-affine fallback
  and preserve both `p(eps)` and `N(eps)`; particular-only installation is not
  an allowed fallback.

## Further optimization add-ons

1. **Expose a production matrix builder.** Return `A`, `b`, decoding metadata,
   and timing fields without invoking any elimination. This removes the
   prototype's interception seam and makes M1/M2 composable.
2. **Hoist by lifetime.** Cache alphabet extraction, dlog tables, factor
   census, residue layout, monomial layout, and ansatz once per fingerprinted
   strip; cache rational preprocessing once per prime where valid. Fable's M0
   (9,6) census shows setup plus build dominates the small-block regime even
   though elimination dominates (9,7).
3. **Fuse point evaluation.** Evaluate the base RHS and every active affine
   forcing direction in the same point loop. Reuse denominator inverses,
   monomial powers, dlog values, and matrix templates.
4. **One factorization, all RHS.** Use a single constrained factorization for
   the particular and all normalized directions. For an affine downstream
   row, solve the augmented variables in the same pass; do not add separate
   rank/nullspace proofs to the hot path.
5. **Dispatch dense versus sparse.** M0 records (9,6) as 94% dense while
   (9,7) is about 40% dense. Avoid `SparseArray` conversion overhead on the
   small dense regime; select representation from measured dimensions and
   density.
6. **Parallelize only the outer images.** Keep `(prime,epsilon)` images as the
   work units, use a configurable worker cap, and avoid nested kernels. Record
   serial algorithm timings separately from parallel throughput. These runs
   used a hard cap of four.
7. **Keep direction data transient.** In modular-carry mode, persist compact
   pivot/rank/check fingerprints and final particulars; keep large `N` data
   only for live images or explicit diagnostic artifacts.
8. **Benchmark a constraining pair.** Before declaring generic Schur
   compression, add a real pair with `Rank[H] > 0`—for example a CF265 block
   below the CF254 embedding or CF231's remaining dependent row. The present
   rank-zero pair is a valuable propagation regression but cannot measure
   constraint compression.

## Acceptance status

| assignment item | status |
|---|---|
| M0 1953/1937 versus 2144/2128 reconciliation | complete |
| M1 pilot normalization and reusable row core | complete |
| M1 one factorization with nullity+1 RHS | complete |
| M1 all-original-row checks and discard rule | complete; 122/122 accepted |
| M1 measured stage comparison | complete |
| M1 exact frozen (9,7) reproduction | complete; exact residual and oracle `SameQ` |
| M2 full `p,N` versus modular-carry measurement | complete |
| M2 real dependent pair consuming affine state | complete |
| M2 exact pair residual | complete |
| M2 installation contract | complete |
| real nonzero-Schur-rank compression example | not yet demonstrated; retained as explicit limitation |

## Source and result inventory

All paths below are relative to
`External/CodexExchange/codex_ff_m1_m2_2026-08-20/`.

- `CodexM1ConstrainedAffinePrototype.wl`: M1 construction, pilot, baseline,
  constrained solve, and canonical comparison functions.
- `RunM1PilotAndSample.wls`: one-prime pilot/later comparison.
- `m1_pilot_and_sample_result.wl`: complete stage table, plan, hashes, and
  checks.
- `RunM1EndToEnd.wls`: frozen seven-prime reconstruction with four workers.
- `m1_end_to_end_result.wl`: exact result, reconstruction history, residual,
  and oracle comparison.
- `m1_mod_*.wl`: seven modular prime artifacts.
- `CodexM2AffineCarryPrototype.wl`: affine decoding, forcing projection,
  Schur/augmented analysis, and full-affine interpolation helper.
- `RunM2AffineCarryCF254.wls`: real CF254 (9,7) -> (9,6) experiment.
- `m2_cf254_affine_carry_result.wl`: pair dimensions, timings, ranks, and exact
  residual checks.
- `RunM2CurrentFrozenInterpolationBenchmark.wls`: current raw-residue-schema
  full-affine benchmark with four workers.
- `m2_current_frozen_interpolation_result.wl`: current 36,448-coordinate
  interpolation measurement.

Rerun commands from any directory are:

```bash
wolframscript -file /home/maxzhang/factorization-and-loops/External/CodexExchange/codex_ff_m1_m2_2026-08-20/RunM1PilotAndSample.wls
wolframscript -file /home/maxzhang/factorization-and-loops/External/CodexExchange/codex_ff_m1_m2_2026-08-20/RunM1EndToEnd.wls
wolframscript -file /home/maxzhang/factorization-and-loops/External/CodexExchange/codex_ff_m1_m2_2026-08-20/RunM2AffineCarryCF254.wls
wolframscript -file /home/maxzhang/factorization-and-loops/External/CodexExchange/codex_ff_m1_m2_2026-08-20/RunM2CurrentFrozenInterpolationBenchmark.wls
```

The end-to-end M1 result is the load-bearing acceptance artifact. The two M2
results together separate the real affine-carry proof from the current-schema
interpolation-cost measurement.
