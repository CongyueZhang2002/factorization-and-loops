# CF300 V6d occurrence/unique audit and pre-launch freeze

## V6c terminal evidence

V6c terminated fail-closed without messages after 289.656312 seconds:

- status: `GaloisChannelOrbitBasisPostconditionFailed` / exit 73
- artifact SHA256: `087515b1374ef33d6a7d5b947a55a45e732f2c63a724ec0cdfca0623f3489803`
- log SHA256: `49701a2014348c16c7907f8b648dba546795f8c4607868b2d4575d2267e8415e`
- status SHA256: `8df3feda5f811c00f3836aeec66ef60f0715d19cceadd6730c11916423fe99d0`
- frozen V6c driver SHA256:
  `86bd849d1e129be5db7c788cf99fc99069a52732b90fb04e423a9321e504b0fc`

The exact character certificates all passed, and both legacy expensive-call
counters were zero.  Runtime counters showed 32 sampled occurrences, 28 exact
canonical potential cores, 4 core reuses, 128 candidate occurrences, and 112
distinct dlog/potential orbit cores plus 16 reuses.

## Semantic audit

`TripleRootStripAdapter.wl` defines `ForcingDLogCandidates` as the number of
unique sampled functions: it applies `DeleteDuplicates` to the evaluated Bbar
entries before filtering and taking dlogs.  Therefore the pinned metadata value
28 is a unique-function count, not a raw `(mu,i,j,epsilon-sample)` occurrence
count.

The older V5-local loop did not repeat that `DeleteDuplicates`.  V6c retained
the V5 occurrence behavior while its driver compared the total to the adapter's
unique count.  The V6c counters make the relation exact:

```text
32 raw occurrences = 28 unique exact potentials + 4 aliases
128 masked occurrences = 112 unique-source masks + 16 alias masks
```

Relaxing the driver to accept 32/128 would preserve redundant work and keep the
metadata semantics inconsistent.  V6d instead performs exact canonical
potential grouping before the orbit hot loop.

## V6d design

V6d keeps all 32 raw occurrences as provenance but sends only 28 unique exact
sources through the Galois orbit.  Each source records:

- `SourceOccurrenceCount`
- `SourceAliasCount`
- the full `SourceOccurrenceProvenance`

Fingerprint groups are checked by exact canonical-channel equality, so a hash
collision fails closed.  The unique-source count is tied at runtime to
`OneFormMetadata["ForcingDLogCandidates"]`.  The driver derives all other
cardinalities and checks:

- occurrences = unique sources + aliases
- candidates = unique sources x sign-mask count
- distinct source cores = unique sources
- source-core reuses = aliases
- build + reuse counts conserve each orbit candidate count
- source provenance counts sum back to all raw occurrences
- one-form and appended-basis sizes are mutually consistent
- legacy decomposition and algebraic branch counters remain zero

There are no magic `28` or `112` comparisons in the V6d postcondition; the
pinned metadata and runtime group order determine them.

## Frozen sources

Core:

`/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/GaloisChannelOrbitCoreV6d.wl`

SHA256:
`7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed`

Driver:

`/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/run_cf300_sector12_galois_orbit_forcing_screen_v6d.wls`

SHA256:
`921422ec0f78c8a56a707fb487115d0b0a5debe6b84e5257e0d3df638e43988d`

## Required central parse gates

Use helper ceiling zero and run the existing actual Wolfram held-parser target
once on the V6d core and once on the driver.  Both must return
`ParsedHead -> "HoldComplete"`, no messages, and exit 0 before the full launch.

## Full launch after both parse seals

Mission name: `cf300_s12_galois_orbit_forcing_xh_v6d`

Arguments:

```text
/home/maxzhang/factorization-and-loops
/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl
/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl
/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl
2
```

The output path was confirmed absent at freeze.  The driver rejects a stale
output and writes atomically with `OverwriteTarget -> False`.
