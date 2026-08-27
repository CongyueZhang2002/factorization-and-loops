# Canonical integral families (rewrite item 2)

## Problem

Family names embed the diagram pair (`TopologyF<i>C<j>N<n>`), so every
pair mints private families and `TopologyEquivalence` must merge them
back pairwise and conservatively. At NNLO double-real this left 374
Kira families (5.88 GB of rules, OOM on import) for a process whose
physical content is a handful of cut topologies.

## Evidence

Cut-aware Pak canonicalization probe (2026-08-10):

- NLO UU 10x10: 100 pair files, 178 topology records -> **11 Pak
  classes**, exactly equal to the 11 classes the affine-verified
  `TopologyEquivalence` found. Neither over- nor under-merging on the
  case where ground truth exists.
- NNLO double-real, all 1296 pairs, 1898 records, zero failures:
  **430 Pak classes, identical partition** to the stored affine-verified
  `TopologyEquivalence` (0 stored classes split by Pak, 0 extra Pak
  merges). The previously quoted 374 is the subset of classes that
  carried Kira targets.
- Master-level check: the 342 NNLO masters are **all Pak-distinct**
  across the 374 reduced families - no cross-family master
  duplication exists.

## Measured conclusions (2026-08-10)

1. The existing equivalence merging is *optimal* at the
   completed-family level, and the master set is already minimal. The
   registry does not reduce the class count below 430; its wins are
   architectural: O(N) incremental merging at build time instead of the
   post-hoc pairwise search, stable family identity across runs and
   process cards (the ghost grid lands on the gluon grid's families),
   and smaller pair artifacts.
2. The NNLO blocker is the in-memory Kira import/closure (rewrite
   item 3, streaming importer), not family proliferation.
3. **Sector embedding** (mapping the 430 completed families into a few
   maximal cut families as sub-sectors with zero/negative indices) may
   still shrink the Kira system by sharing sub-sector reductions, but
   this is now a benchmarkable hypothesis, not a presumed win: fewer
   families trade against larger per-family index spaces. Benchmark on
   a target subset before adopting.

## Canonical key

For a topology record (completed `FCTopology` + `CutIndices` +
`CutDirections`):

1. Mark every cut slot by injecting a fictitious marker mass into its
   `StandardPropagatorDenominator` (third slot -> `mass - cutMarker`).
   Pak orderings then cannot mix cut and uncut propagators.
2. `FCLoopToPakForm[markedTopology]` with the topology's own kinematic
   rules (slot 5) in effect; take the canonical characteristic
   polynomial.
3. Key = SHA-256 of `{canonical polynomial, Sort[CutDirections]}`.

Records with equal keys are candidate-equivalent; equality of the
polynomial implies existence of a propagator permutation + affine
momentum map, which is then constructed and **verified** (below).
Records with distinct keys are never merged.

## Registry

- Persistent artifact (WXF record + manifest fingerprint) mapping
  key -> `<| "Name" -> CF<n>, "Topology" -> canonical FCTopology,
  "CutIndices", "CutDirections", "FirstSource" |>`.
- Canonical names `CF1, CF2, ...` in registration order; a registry is
  deterministic for a fixed processing order (sorted pair files).
- The registry is created once per process/card and reused by every
  pair; pairs never mint family names.

## Mapping construction and verification

For a record whose key hits an existing entry:

1. Propagator permutation: compose the record's Pak ordering matrix
   with the inverse of the canonical entry's ordering matrix
   (`FCLoopToPakForm` returns the x(i) -> propagator table).
2. Momentum map: `FCLoopFindMomentumShifts` on the permuted propagator
   lists (fall back to `FCLoopFindTopologyMappings` on the pair).
3. Verify with the existing `topologyPhysicalMapping` (reused
   unchanged): exact rational affine map, unit Jacobian, propagator
   polynomials match under the map, cut slots map to cut slots,
   energy direction sign `momentumRelativeSign * direction` preserved,
   loop sectors (phase-space / forward / conjugate) not mixed.
4. On verification failure: fail closed - register the record as a new
   canonical family (name suffix records the collision) and log the
   rejected candidate. Correctness is never traded for collapse.

Output per record: a verified `GLI` replacement rule
`GLI[localName, indices__] :> GLI[CFn, permuted indices]` in the same
`HoldPattern` form `topologyVerifiedGLIRule` produces today.

## Integration

Prototype stage (this item): standalone module
`FeynFacet/Private/CanonicalFamilies.wl` + test, operating on saved
pre-IBP pair artifacts. Pipeline integration (BuildTopologies emitting
canonical GLIs directly) follows once the prototype reproduces the NLO
ground truth and the NNLO collapse is measured.

## API (prototype)

- `CanonicalFamilyRegistryCreate[]` -> empty registry Association.
- `CanonicalizeTopologyRecord[record, registry]` ->
  `<| "Registry" -> updated, "Name" -> CFn, "GLIRule" -> verified rule,
     "Status" -> "Registered" | "Mapped" | "CollisionRegistered" |>`.
- `CanonicalizeTopologyRecords[records]` -> convenience fold returning
  `<| "Registry", "Rules", "Classes", "Rejected" |>`.

## Acceptance tests (`Tests/EpsilonForm/t_canonical_families.wls`)

1. Over all saved NLO UU 10x10 pair records: exactly 11 canonical
   families, zero `CollisionRegistered`.
2. Class membership identical to the partition induced by the saved
   `KiraResult.wl` `TopologyEquivalence` classes.
3. Every emitted GLI rule passes `topologyPhysicalMapping`
   verification (the test re-verifies independently).
4. Determinism: a second run over the same inputs yields an identical
   registry and identical rules.
5. Exactness: no inexact numbers anywhere in registry or rules.
