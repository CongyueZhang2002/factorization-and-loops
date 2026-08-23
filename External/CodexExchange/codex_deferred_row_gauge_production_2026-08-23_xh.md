# Production-only deferred future-A row gauge: xhigh read-only assessment

Date: 2026-08-23 (America/Los_Angeles)

Scope: read-only review of the current package and running CF300 evidence. No
package file was edited, no Wolfram kernel was launched, and no process was
signalled. The companion patch is staged only in `External/CodexExchange`.

## Conclusion

The deferred construction is algebraically ready for a production-only hook.
The smallest safe policy is:

1. Development always requests `"Together"` (unchanged).
2. Production requests `"Deferred"` only when a complete materialized row was
   supplied; when it is `Automatic`, request `"Together"`.
3. Let `familyRowGaugeApply` retain the authoritative validation. In
   particular, a non-`Automatic` but incomplete row must fail closed with
   `DeferredFutureARequiresCompleteInstalledRow`, not silently degrade and
   install a `Missing` value.
4. When regulator factorization succeeds after a deferred row, install its
   already-certified transformed truncation, propagate the constant
   transformation to future rows as exact raw right-products, and keep the
   existing Together path for `S` and `SInverse`.
5. When Production actually used `"Deferred"`, skip the diagnostic full-family
   `badStrips` census immediately after the checkpoint. That census calls
   `Together` on the future blocks and can recreate the exact cost being
   removed. The mandatory final family certificate remains the sole exact
   production acceptance test.

The exact formula is unchanged. For the row gauge `T = 1 + D`, structural
block lower triangularity gives `D^2 = D dD = D A D = 0`, hence

`A' = A + A D - D A - dD`, `S' = S + S D`, and
`S'^(-1) = S^(-1) - D S^(-1)`.

Deferred mode changes representation only: current-row entries come from the
complete installed dlog form, while touched future-row entries retain the exact
raw sum `base + correction`. `S` and `SInverse` remain normalized exactly as
before. A later sector normalizes the relevant raw entries in its targeted
`blockEquation`; when that sector is completed, its full installed row
overwrites all of its lower columns. Therefore no deferred future row remains
after the final sector.

## Evidence reviewed

- `FeynFacet/Private/FamilyRowGauge.wl` already implements explicit
  `futureAMode` values `"Together"` and `"Deferred"`, rejects unknown modes,
  and rejects Deferred without a complete installed row before mutation.
- `Tests/t_family_row_gauge.wls` already proves exact dense equivalence,
  preservation of untouched entries, literal raw sums, accounting, malformed
  row rejection, and the unchanged `S`/`SInverse` construction.
- Real CF300 sector-8 gate v4 passed two construction primes plus one unseen
  prime, all eight root-sign branches at each image, for all 36 touched future
  targets. It reports a 0.065884 s deferred build and no differing targets.
- The current production log stops immediately after
  `sector 11 row completed from 10 individually checked strips`, before the
  row-gauge statistics line. Its last log write was 2026-08-23 03:18:04 PDT.
  The completed sector-11 strip checkpoint exists (14,533 bytes), while the
  family state is still the earlier 22,986,686-byte checkpoint. Thus a later
  restart can replay/hydrate the completed row; this assessment does not
  authorize or perform that restart.
- The regulator *solve* sees only rows through sector `k`, but the accepted
  factor is currently conjugated into the full connection. The present
  `familyRegulatorSparseDot` calls `Together` for every output entry. This is a
  second P1 normalization sink and must be covered by the revised patch.
- `CertifyFamilyEpsilonForm` reconstructs and checks the complete transformation
  independently. Extra row-gauge statistics in `SectorCertificates` are not
  trusted as acceptance evidence.

## P0/P1 audit

No P0 remains in the proposed wiring if the package validator remains the
authority and the final certificate stays mandatory.

P1-performance (regulator propagation): after a successful truncated factor,
current lines 423-426 conjugate the full state. For
`G = diag(T_m, I)`, block lower triangularity gives exactly

`G^(-1) A G = {{T_m^(-1) A_mm T_m, 0}, {A_fm T_m, A_ff}}`.

The accepted factor already returns the certified transformed `m x m`
truncation. Install that block, leave upper-right and future/future blocks
unchanged, and form only `A_fm T_m` as raw exact sparse sums. The left factor
is the identity on future rows, so no future left multiplication exists.
`S -> S G` and `SInverse -> G^(-1) SInverse` remain on the established Together
path: they are not strip inputs, and later row gauges consume both, so carrying
them raw would move expression swell into every subsequent transformation
update.

P1-performance (diagnostic census): `badStrips[state["A"], nb]` at current lines 881-884 performs
entrywise `Together` over the full state after each sector. Running it after a
deferred row can negate the optimization or create a second stall. The patch
skips only this progress census when the applied mode was actually Deferred in
Production; the state has already been written atomically.

P1-correctness if implemented incorrectly: do not select Deferred merely by
`ListQ[installedRow]`, and do not convert a malformed/incomplete non-Automatic
row to `Automatic`. The package currently prevents an incomplete row from
entering deferred state. Preserve that fail-closed behavior.

P1-provenance: a production checkpoint can contain deliberately unnormalized
future entries. Persist the applied mode and complete statistics in the sector
certificate. Without this, a resumed run is exact but the representation
choice is not auditable.

P1-certificate boundary: do not reinterpret production sector statistics or
the modular strip residuals as exact identities. Acceptance remains
`CertifyFamilyEpsilonForm`, exactly as `family_epsform_pool.sh` currently
enforces.

Resume semantics: the matching sector certificate is appended before
`factorTruncated[k]`, so it is the stable source of the applied future-A mode.
The revised regulator record also persists its propagation statistics. A crash
before the atomic state write leaves the previous family state plus the
complete strip checkpoint; replay/hydration reconstructs the row. A crash
after the state write round-trips the exact raw sums through `Put`/`Get` and the
next targeted `blockEquation` normalizes only what it consumes. Old
certificates without row-gauge statistics fall back to Together. A Development
resume also selects Together even if the saved Production row had been
Deferred, preserving Development's canonical representation at the cost of
one safe normalization.

## Exact proposed edits

The revised companion apply-patch candidate changes the private regulator
helper and `Scripts/family_epsform_sector.wls`; it is still staged only in
External:

- `FeynFacet/Private/FamilyRegulatorFactor.wl`: add a typed
  `familyRegulatorPropagateTruncation` helper. Default `"Together"` reproduces
  the old full conjugation. `"Deferred"` installs the accepted transformed
  truncation, verifies the upper-right structural zero, and propagates only the
  future/lower right-product with support intersections, literal single-term
  fast paths, and unnormalized multi-term exact sums.

- Current lines 463-469: select `"Deferred"` iff `productionQ` and
  `installedRow =!= Automatic`; pass it as the eighth
  `familyRowGaugeApply` argument. Development therefore keeps the existing
  default representation exactly.
- Current lines 806-820: log applied mode, deferred future count, and future
  touched count from returned statistics.
- Current lines 825-827: persist the full compact `RowGaugeStatistics` in each
  blockwise sector certificate.
- Current `factorTruncated` lines 397-431: recover the applied row mode from the
  matching sector certificate, call the typed propagation helper, persist its
  statistics, and stop fail-closed if propagation is rejected. Continue to
  normalize `S` and `SInverse` through their existing sparse products.
- Current lines 881-884: skip the full `badStrips` census only when Production
  actually applied Deferred; retain it for Development and Together fallback.
- Current output record around lines 987-994: state the stable propagation
  policy and update provenance to name deferred exact sums and the separate
  exact family certificate.

No change to `FamilyRowGauge.wl`, the resume helper, the certifier, or a public
API is required.

## Required tests before package merge

### Unit (exact)

1. Run the existing `Tests/t_family_row_gauge.wls`; require zero failures.
2. Add a sequential deferred test: apply a first installed row with Deferred,
   verify that at least one future entry is a non-canonical raw sum, construct
   a constant regulator factor on that prefix, propagate it with Deferred,
   verify the future/lower block remains an exact raw sum, then construct and
   install the later row. Prove the final connection, `S`, and
   `SInverse` equal the ordered dense two-gauge formula entrywise under
   `Together`.
3. Assert Development/Together produces `FutureAMode == "Together"` and
   `DeferredFutureEntries == 0` with a complete installed row.
4. Assert Production-policy fallback (`installedRow === Automatic`) requests
   Together. Assert a dimension-correct row containing `Missing` is rejected,
   not installed and not downgraded.

### Static

Parse the script held and require all of the following in the same source
image: the mode depends on `productionQ`; Automatic selects Together; the mode
is passed to `familyRowGaugeApply`; `RowGaugeStatistics` is persisted; and the
post-sector census guard tests the returned applied mode. Require the regulator
helper call and propagation statistics, and prove by source position that the
atomic state write precedes the guarded census. Also require the source SHA
pinned by the integration record.

### Real integration

1. Re-run the existing CF300 sector-8 v4 gate against the exact candidate
   source. Require 36 targets, two construction primes, one unseen prime, all
   eight signs, and zero differences.
2. On a copied CF300 sector-11 checkpoint, run one Production sector. Require
   `FutureAMode == "Deferred"`, positive `DeferredFutureEntries`, and, if
   regulator factorization fires, Deferred regulator propagation statistics.
   Require an atomic state write before any progress census and no full census
   log. Set explicit
   wall/memory ceilings and retain the result artifact.
3. Run the same copied checkpoint in Development. Require
   `FutureAMode == "Together"`, `DeferredFutureEntries == 0`, and exact equality
   to the Production connection after entrywise Together.
4. Force installed-row unavailability on a copied fixture. Require Together
   fallback and successful state progression. Force an incomplete installed
   row separately and require a typed rejection with no state advance.
5. Finish a copied CF300 family state through the remaining sectors and run
   `Scripts/certify_family_epsform_record.wls`. Merge only if the independently
   written certified record has `Status -> "ExactEpsilonForm"` and
   `ExactFamilyEpsilonFormQ == True`.

## Reviewed SHA-256 provenance

- `FeynFacet/Private/FamilyRowGauge.wl`:
  `ebe728cf47d61b01552178a03001bf91297dcadd43a545b28ba83f9d00a71e1b`
- `FeynFacet/Private/FamilyRowGaugeResume.wl`:
  `e9719e551fcd1930dfbce478a25880d7393a9b6ab3dcf1d2a9672cf0bf4c5dde`
- `Scripts/family_epsform_sector.wls`:
  `60cc272a0b28da47d670984f401286f4ec29854b6216b7f36580bcde43e4a660`
- `Tests/t_family_row_gauge.wls`:
  `f9f1d99ca31f5ca25259b944ce5391e161d4e20d71e3c817fd9dc0d4579619ab`
- CF300 sector-8 deferred gate v4 result:
  `72ede9afd33c9b898685ae77f6a167fdaf44832430bfd84301bc298b5c2f9b1f`
- `Scripts/family_epsform_pool.sh`:
  `f443ad5023d315d39dd8f688f4d844fa24fae6e6f25695feeb45aa6a0d6821b2`
- `Scripts/certify_family_epsform_record.wls`:
  `251c9fc05ec5eb73fd2ef4b8a419bfad0325cfe7a175f1fec65fda0210d1305e`
- `FeynFacet/Private/FamilyEpsForm.wl`:
  `436c3fc6216e7be3ee1fce41dd1c98f91f1ce733aff27308214275f1a8221ce4`
