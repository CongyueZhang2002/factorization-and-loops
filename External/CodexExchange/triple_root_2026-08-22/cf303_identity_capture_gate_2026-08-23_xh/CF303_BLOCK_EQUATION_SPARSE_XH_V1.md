# CF303 sector-17 `blockEquation` sparse candidate

Prepared read-only with respect to the active mission and installed package on
2026-08-23.  No Wolfram kernel, native algebra backend, helper, or replacement
process was launched.  The staged diff was not applied.

## Observed hotspot

The active `cf303_identity_capture_xh_v4` mission stopped producing durable
progress after

```
block {17, 12} before equation
```

The driver was then inside the unbounded construction at
`Scripts/family_epsform_sector.wls:497-501`.  Its forcing is

```
bbar(k,j) = A(k,j) - Sum[D(k,m) . A(m,j), j < m < k].
```

The call forms dense `Dot` products and then applies `Together` to every output
entry.  Production's earlier row gauges deliberately preserve future-row
entries as exact raw `base + correction` sums.  Therefore `A(17,12)` is one of
the entries most exposed to deferred-expression growth.

The installed row-gauge optimizations do not bypass this call:

* `familyRowGaugeApply` runs only after every block in the current row has been
  solved.  It cannot construct the current triangular forcing.
* its `"Deferred"` mode optimizes prior-row propagation, but stores ordinary
  exact expressions rather than a reusable term graph;
* `familyRegulatorPropagateTruncation[..., "Deferred"]` similarly retains exact
  sparse right-product sums for future rows;
* `familyRowGaugeResumeBlockEquation` is a legacy-formula replay oracle, not a
  faster producer;
* `FamilyRowGaugeFiniteField.wl` contains a relevant tagged modular evaluator,
  but explicitly is not loaded by `FeynFacet.m` and does not reconstruct the
  exact strip record required by this driver.

## Staged change and identity proof

`cf303_block_equation_sparse_xh_v1.patch` changes only
`Scripts/family_epsform_sector.wls`.  It replaces each dense block `Dot` with
literal-support intersections and retains the existing final entrywise
`Together`.

For an output entry `(a,b)`, the legacy product is

```
Sum_q D(k,m)[a,q] A(m,j)[q,b].
```

The candidate sums over

```
support(D(k,m)[a,*]) intersect support(A(m,j)[*,b]),
```

where support excludes only entries `SameQ` to the literal integer `0`.
Every omitted legacy term therefore has a literal zero factor and is exactly
zero.  Every retained product, its scalar-factor order, the higher-sector key
order, the outer subtraction, and the final `Together` are unchanged.  Thus
the candidate equals the legacy rational/algebraic function entry by entry;
there is no sampling, numerical zero test, interpolation, timeout, or changed
physics criterion.

The patch deliberately leaves `FamilyRowGaugeResume.wl` unchanged.  On a later
resume, its dense legacy formula must still produce a `SameQ` strip record.
That is a useful independent oracle rather than duplicated candidate code.

## Staged files

* `cf303_block_equation_sparse_xh_v1.patch`: unapplied driver-only diff.
* `test_cf303_block_equation_sparse_static_xh_v1.py`: no-kernel source/hash,
  scope, forbidden-behavior, and resume-oracle audit.
* `test_cf303_block_equation_sparse_xh_v1.wls`: exact adversarial comparison of
  legacy and sparse formulas on multi-block rational/algebraic, sparse,
  deferred-sum, empty-higher, reordered-association, and malformed-dimension
  cases.  It writes nothing and returns `$Failed` on any failed check.

The staged diff currently passes `git apply --check`; it has not been applied.

## Promotion gates

1. Do not alter or restart the V4 mission.  Wait for a terminal pool state and
   preserve its wrapper, state, checkpoint, log, and hashes.
2. Verify the current base hashes before testing:
   * driver:
     `6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1`
   * resume oracle:
     `816fa4d544806115181b3c3fe2d6ee3de89fff1d3d999e6412b6a745b010fc2b`
3. Run the static audit and `git apply --check` without modifying the installed
   tree.
4. Run the adversarial `.wls` only through the central eight-subkernel pool,
   with both helper ceilings zero.  Require every `SameQ` and exact residual
   check to pass.
5. Apply the diff only in an isolated worktree/copy.  Parse-load the resulting
   driver and compare candidate versus legacy construction on copied CF303
   inputs/checkpoints, including every available sector-17 input.  Require
   `SameQ`, not merely numerical agreement.
6. Benchmark without converting a timeout into a result.  A benchmark abort or
   time limit is an explicit inconclusive/failure; it must never accept or
   substitute a forcing term.  Require a material reduction in wall time or
   peak memory on the sector-17 hotspot.
7. Run a fresh or explicitly source-versioned resume campaign.  Require the
   package's unchanged resume oracle to replay every saved strip `SameQ`, then
   require the full pinned whole-family certificate.
8. Promote only the driver hunk after all gates pass.  Regenerate the source
   manifest, mission wrapper, and label.  V4 cannot run the changed driver: its
   preflight correctly pins the old driver hash.

`familyRowGaugeSolverImplementationProvenance` includes the driver hash.
Therefore a promoted driver changes solver-configuration fingerprints.  An old
in-progress row checkpoint must be invalidated and re-solved by the existing
fail-closed hydration path; it must not be relabeled as produced by the new
implementation.

## Rollback criteria

Rollback the single driver hunk, preserving all old artifacts, if any of these
occurs:

* one synthetic or copied real block is not `SameQ` to the legacy formula;
* an exact residual is nonzero;
* resume replay reports an input/connection mismatch other than the expected
  implementation-fingerprint invalidation of an old current-row suffix;
* the candidate introduces undeclared radicals, a changed strip alphabet, or a
  different solver route on the same exact input;
* wall time or peak memory does not materially improve;
* the full exact family certificate fails or its source/provenance hashes do
  not bind the promoted driver.

No timeout or modular-only comparison is sufficient evidence for promotion.
