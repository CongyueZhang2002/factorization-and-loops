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
- NNLO double-real: measurement over all 1296 pairs (result recorded in
  the commit that lands the prototype).

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

## Acceptance tests (`Tests/t_canonical_families.wls`)

1. Over all saved NLO UU 10x10 pair records: exactly 11 canonical
   families, zero `CollisionRegistered`.
2. Class membership identical to the partition induced by the saved
   `KiraResult.wl` `TopologyEquivalence` classes.
3. Every emitted GLI rule passes `topologyPhysicalMapping`
   verification (the test re-verifies independently).
4. Determinism: a second run over the same inputs yields an identical
   registry and identical rules.
5. Exactness: no inexact numbers anywhere in registry or rules.
