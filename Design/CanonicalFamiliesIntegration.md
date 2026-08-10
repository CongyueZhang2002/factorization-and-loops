# Canonical families: pipeline integration (rewrite item 2, stage 2)

## Staging decision

Canonicalization runs as a **post-pass over saved pre-IBP pair
artifacts**, not inside `CollinearFactorizePreIBP`. Reasons: pair
generation runs on parallel subkernels, and a shared registry updated
concurrently would race; a post-pass is sequential (registry order is
deterministic), leaves the generation pipeline untouched, and can be
re-run on existing artifacts. In-build canonicalization can come later
behind a registry service if ever needed.

## New stage

`CanonicalizePairArtifacts[pairFiles, outputDirectory]`:

1. Load artifacts (must pass `validPreIBPResultQ`), fold all topology
   records through `CanonicalizeTopologyRecords` (existing prototype)
   in sorted pair-file order.
2. For each pair, rewrite the `Integrand` GLIs through the verified
   rules (`linearMapIntegrals`), and replace `Topologies` by the
   canonical records the pair actually uses: the registry entry's
   record (canonical name, topology, cuts) with `DiagramPair` and
   `AnalyticContext` carried over from the pair.
3. Write canonicalized artifacts (same schema and format version, plus
   `"CanonicalRegistryFingerprint"`), and one registry artifact
   `CanonicalRegistry.wxf` + human-readable `CanonicalRegistry.wl`
   manifest (families, keys, class members, rejected candidates,
   fingerprint) in the output directory.
4. Fail closed on any `CollisionRegistered` unless explicitly allowed
   by an option; collisions at NLO/NNLO UU are known to be zero.

## Reduction-side handling

Canonicalized artifacts repeat identical records across pairs (same
canonical family). `ibpInputData` currently flattens records, and
`TopologyEquivalence` rejects duplicate names. Required changes
(minimal, in Reduction.wl):

- Dedupe records by name in `ibpInputData` **only when they are SameQ
  identical** (structurally equal records with equal names); a name
  collision with different content stays a hard failure.
- `TopologyEquivalence` fast path: when all record names are already
  distinct canonical names (post-dedupe), return the identity
  partition (singleton classes, no mappings) without running
  `FCLoopFindTopologyMappings`. The expensive pairwise search
  disappears for canonicalized inputs; legacy inputs take the old path
  unchanged.

## Acceptance tests (`Tests/t_canonical_pipeline.wls`)

1. Canonicalize the 100 regenerated NLO pairs
   (`UU_08_10_10x10_regen`); assert 11 families, zero collisions,
   canonicalized artifacts pass `validPreIBPResultQ`.
2. Run `KiraReduction` on the canonicalized artifacts into a separate
   result file; assert the equivalence fast path produced singleton
   classes.
3. Semantic equality against the reference
   `UU_08_10_10x10_regen/KiraResult.wl`: identical master count, and
   the assembled reduced expression per pair (integrand composed with
   each side's rules) agrees master-by-master after mapping the
   reference masters through the canonical GLI rules; coefficient
   differences vanish under `exactZeroQ`.
4. Idempotence: canonicalizing already-canonical artifacts is the
   identity (same registry fingerprint, same artifacts).

## NNLO rerun plan (after this lands)

Regenerate all NNLO double-real pairs with the current package
(gluon grid `UU.wl` 36x36 and ghost grid `UU_Ghost.wl` 7x7),
canonicalize both grids through ONE shared registry (the ghost grid
must land on the gluon grid's families where the topologies coincide),
then a single Kira solve + streaming import. Assembly combines the
grids as sigma_gg = (1/2!) x gluon - ghost
(`IdenticalParticleSymmetryFactor`), cf. `UU_Ghost.wl` header.
