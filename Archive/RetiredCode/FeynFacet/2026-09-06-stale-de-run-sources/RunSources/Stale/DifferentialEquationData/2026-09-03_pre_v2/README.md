# Pre-V2 differential-equation data

This directory contains the generated differential-equation, epsilon-form,
path-solution and boundary-data artifacts that were live immediately before
the V2 mathematical-data reset on 2026-09-03.  They are retained only as
historical evidence and are not accepted input to live V2 package code.

The payload came from
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical`.  Its relative directory
structure is unchanged beneath `UU_08_10_canonical/`.  `INVENTORY.tsv` records
the original relative path, object type, byte size, file count and whether the
path contained files tracked at the time of the move.  No content hash is
needed: the tracked version is recoverable from Git history and the untracked
payload is reproducible run data.

The following regeneration inputs deliberately remain live:

- `Pairs/`: saved pre-IBP pair data;
- `KiraStream/`: the canonical streamed reduction output;
- `CanonicalRegistry.wl` and `CanonicalRegistry.wxf`: the upstream topology-
  family registry used before differential-equation construction;
- the finite-field trace manifest and Kira `masters.final` files, which define
  the actual master-integral list;
- `ppHX_NNLO_DoubleReal/InputData/UU_08_10_canonical/HardFunctionMasterCoefficientEpsilonValuations.wl`,
  the V2 form of the exact hard-function coefficient valuations;
- the process cards and all package source.

The archived `Masters/` directory is historical path-solution output despite
its name: its Wolfram records use `Format -> "FeynFacetTransportedFamily"` and
`FormatVersion -> 1`.  It is not a regeneration input.

The archived `KiraResult.wl` is a monolithic materialization of `KiraStream/`,
not a second source of reduction truth.  Live code should consume the streamed
store so the reduction is represented once.

The archived `Scripts/Transport/CF303/Artifacts/` directory contains the V1
CF303 boundary-analysis outputs that formerly lived beside executable scripts.
`HistoricalNotes/` contains contemporary design discussion, not machine input.
Neither location is part of the V2 data flow.

Regeneration under schema V2 starts from those inputs.  Each regenerated
mathematical stage must record wall time and peak resident memory in a separate
`ComputationMetrics` record.  Those measurements are diagnostic metadata and
must not affect mathematical identity, resumption, or acceptance.

Frozen V1 inputs previously stored inside `FamilyEpsFormsSolving` moved with
the archive.  Any still-useful mathematical fixture must be rebuilt under
`Tests/Fixtures` with an explicit fixture data type; live tests must not load a
V1 production-result path.
