# Codex daytime rank-3/performance handoff to Fable

**Time:** 2026-08-26 16:17 PDT  
**Status:** complete and committed in an isolated worktree; Fable's working tree was not modified  
**Branch / commit:** `codex/day-rank3-validation` / `fb2cfbd`  
**Worktree:** `/home/maxzhang/factorization-and-loops-codex`  
**Snapshot parent:** `2c19a22cc4145cea74d9352118d498b0f0a603a5`

## Executive result

The representative hard candidate-letter build fell from **71.84 s on one
kernel to 23.3--26.2 s on eight subkernels** (latest full-suite measurement:
25.97 s).  It still produces 44 installed verified letters and removes the
same eight spanned diagonal forms.  A separate compile-boundary test found and
fixed a performance-only regression: initially 17/44 retained records fell
back to decomposition because radical recomposition was algebraically equal
but not `SameQ`; the final code keeps **44/44 on the compact channel route**
while raw-letter/channel mutations are still refused.

No run is active, no unrelated process was signalled, and the main Fable tree
was left untouched.

## What changed

### 1. Exact grade-algebra dlog construction and bounded parallelism

- Package-derived forcing, rational-factor and algebraic letters are
  differentiated directly in the declared `2^r` grade algebra.  This avoids
  constructing a large radical `Together[D[L]/L]` only to decompose it again.
- All independent dlogs use one ordered batch and one helper bootstrap.
  `"DLogKernels" -> 1..8` is a subkernel cap.  The code chooses exactly that
  many kernel objects, launches only missing helpers, closes only helpers it
  launched, and recomputes a malformed shard locally.
- Exact letter and dlog channels, their canonical rational keys, and the
  construction evidence are retained.  The compiler reuses those channels
  instead of rebuilding the inverse/derivative.  The certificate binds the raw
  letter spelling and both channel payloads; the channels actually installed
  must still recompose exactly to the requested one-form.
- `Automatic` deliberately uses already-live helpers and launches none.  A
  production driver that wants this measured speedup must pass
  `"DLogKernels" -> 8` (or prelaunch the intended pool).

### 2. Shared diagonal-span solve

- The eight scalar diagonal questions now share one exact-rational image
  system and one augmented row reduction instead of eight `SolveAlways`
  calls.
- Already-constructed grade channels are reused.  Basis images are evaluated
  lazily and stop after a construction prefix plus six held-out exact-rational
  points.
- A mixed spanned/non-spanned batch declines the fast route.  Each target then
  receives the scalar sampled verdict, with the historical exact
  `SolveAlways` route as the final non-applicable/underdetermined fallback.
- Spanned unverified diagonal forms remain diagnostic and outside the unknown
  layout; verified dlog letters remain the installed basis.

### 3. Rank-3 deferred-construction hardening

- Root-frame identity now includes the chosen root expression/branch, not only
  its square, so odd-grade coefficients cannot alias under `r -> -r`.
- Bundle validation rechecks the mathematical root frame, operand table,
  divisor table/orbits and occurrence-to-job provenance instead of trusting a
  refreshed outer fingerprint.
- Canonically equal operand values are interned once while each source spelling
  retains its own explicit-divisor routes.  This removes repeated algebra
  without conflating provenance.
- The new adversarial rank-3 test uses three genuine independent radicands,
  exercises all eight grades, an eight-member Galois orbit, a triple-composite
  denesting, equivalent operand spellings, refingerprinted structural mutants,
  and opposite root branches.

No family identifier or family-specific condition was added to either Private
implementation file.

## Finite-field decision (measured, not assumed)

I tested the finite-field alternative on the real shared span system:

- coefficient matrix: `48 x 44`, eight right-hand sides;
- exact image construction for six accepted points: **2.028 s**;
- rational augmented `RowReduce`: **0.115 s**;
- conversion to one 31-bit prime: **0.0015 s**;
- one-prime `RowReduce`: **0.00032 s**;
- rational and modular ranks: both 29.

Finite-field row reduction is much faster in isolation, but it replaces only
about 5% of this stage.  Exact image construction dominates, and a certified
modular implementation would additionally need multi-prime lifting/rational
reconstruction.  I therefore did **not** add that complexity.  It cannot be a
major end-to-end improvement at the measured shape.  A minimal helper bootstrap
was also tested and saved only roughly 1--2 s, so that experiment was removed.

## Final adversarial/regression evidence

- `t_multiquadratic_provenance.wls`: **69/69** (serial/selected-route identity,
  helper ownership, invalid kernel counts, channel mutation, raw-letter
  mutation, compact-route coverage, rank-3 inverse agreement).
- `t_multiquadratic_letters.wls`: **25/25**.
- `t_multiquadratic_potentials.wls`: **16/16**.
- `t_construction_bundle_rank3_adversarial.wls`: **13/13**.
- `t_multiquadratic_diagonal_span_batch.wls`: **7/7**.
- `t_construction_dag.wls`: **78/78**.
- `t_construction_dag_divisors.wls`: **15/15**.
- `t_multiquadratic_regulator_reconstruction.wls`: **18/18**.
- `git diff --check`: clean; isolated worktree clean after commit.

The sampled positive span certificate is intentionally probabilistic (exact
rational arithmetic at deterministic construction and held-out images, no
floating tolerance), matching the accepted evaluation-certificate policy.
Non-applicable and mixed cases retain exact fallback, and downstream system
checks remain independent guards.

## Integration advice

Fable has concurrent round-3 edits, so inspect/cherry-pick `fb2cfbd` with
conflict resolution rather than copying the two Private files wholesale.  The
algorithmic units worth preserving together are:

1. `multiquadraticStripLetterChannelData` + batch dlog construction + retained
   channel admission/compile reuse;
2. shared/lazy diagonal span plus scalar/exact fallback;
3. the rank-3 root-branch and source/canonical-operand validation changes;
4. both new adversarial tests and the added provenance assertions.

The implementation stays at the presently accepted two chart variables.  No
attempt was made to generalize the solver to three or more independent chart
variables in this change.
