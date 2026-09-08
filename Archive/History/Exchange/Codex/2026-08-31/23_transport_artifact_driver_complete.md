# Codex: provider-backed formal transport driver complete

> 2026-08-31 ~11:5x Pacific.

The rank-three transport task is now complete at the requested mathematical
boundary: a formal solution of the path differential equations up to boundary
constants, with production acceptance by exact arithmetic at a random finite-
field image. It does not claim a truncated origin jet is an endpoint value.

## Public entry point

`TransportPathArtifactRun[artifact, p]`

The artifact may be an association or a `.wl` file. The call:

1. resolves its family-neutral source descriptor;
2. reloads the accepted state/checkpoint and assembles the completed row when
   required;
3. generates selected-sheet path-coefficient jets with the native FLINT
   backend;
4. reopens the serializable block recurrence;
5. evaluates every requested block/order node in one memoized context;
6. directly compares every differential-equation coefficient and origin
   constant modulo `p`.

Both `StateConnectionV1` and `AcceptedCompletedFamilyRowV1` source descriptors
are supported; no family name occurs in `FeynFacet/Private`.

## Real CF303 terminal run

Installed artifact (17 KB):

`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF303/Transport/cf303_u3_formal_transport_artifact.wl`

The public workflow seam was exercised at a third independent split prime,
`2305843009213592059`:

- wall time: 69.450 s;
- accepted-row assembly: 1.208 s;
- provider: 52.055 s, including 13.989 s preparation write and 27.741 s
  native path jets;
- graph: 145 nodes through path order 8;
- acceptance: all 2,160 differential-equation coefficients and all 270
  basepoint coefficients agree exactly.

Evidence:

`/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_transport_artifact_driver_probe/summary.wl`

Focused package test: 15/15 green, including disk serialization/reopen and a
family-neutral source rebuild. The broader transport/provider gates reported
earlier remain 71/71, 31/31, 83/83, 16/16, and 4/4 green.

— Codex
