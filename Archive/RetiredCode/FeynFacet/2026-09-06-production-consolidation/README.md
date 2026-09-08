# Retired production implementations, 2026-09-06

This directory preserves 196 files moved out of the active source tree.
It is **never loaded or used as a production input**. The current route is
documented in [Scripts/Transport/README.md](../../../Scripts/Transport/README.md).

[manifest.json](manifest.json) records every original path, backup location,
byte count and reason. Each move preserved the exact current file bytes,
including pre-existing uncommitted edits. No git reset or checkout was used.

- `Retired/` mirrors the original repository paths for retired modules, scripts,
  tests, fixtures and bytecode.
- `Before/` preserves complete pre-edit versions of active files changed in this
  consolidation. The manifest identifies the one mechanically reconstructed
  pre-edit path-only test change.
- `Relocated` in the manifest records useful modules moved within the active tree.

There are nine retired package modules, containing 11,540 lines. The package
no longer exports 31 retired interface names, including the older compatibility
stubs. Their usage messages, editor declarations and definitions were removed.
The active general solver and its stored mathematical outputs were not replaced.

## Retired interfaces

The old `ObservableTransport` and rational-epsilon-block operator modules
constructed lazy requested-output coefficient maps. `TangentialBoundaryEvolution`,
`BoundaryCoefficientOperatorProduct`, `FactorizedFiniteFieldBoundaryComposition`
and `SingularPointMatching` used those letter-sequence representations.

Their old top-level launchers, physical-boundary campaign, CF303-specific
implementations and representation-only tests moved with them. Earlier text-only
finite-solution verification scripts are also archived; current verification
uses `VerifyMasterIntegralSolution` on the complete record.

The CF303 tree includes its mathematical notes and saved control data. They are
evidence for later recovery, not a second supported production workflow.
Original source text and internal paths are preserved, so archived scripts are
not expected to run directly from this location.

## Mathematical capabilities archived with the old formats

Retiring these implementations also removes their executable interfaces for:

- Ordered path concatenation and sparse coefficient-map composition.
- Regularized singular-junction and endpoint matching maps.
- Tangential-base-point normalization and resonant-mode binding in those campaigns.
- Epsilon-order propagation through their legacy matching and selector maps.

Keeping local Frobenius/residue routines does not replace those operations.
General matching and continuation in the current finite-solution format remain
unfinished. This is an intentional interface gap, not a claim that the operations
are mathematically unnecessary.

## Retained active mathematics

Integral definitions and Laurent bounds; sufficient epsilon-order determination;
explicit finite solutions; compiled and Wolfram numerical evaluation; local
Frobenius expansions, residues, exact mode matching and boundary-function DEs;
optional epsilon-form algorithms and GPL/elliptic kernel conversion.

`MasterIntegralEpsilonOrderRequirements.wl` moved from `Boundary/` to `Orders/`.
`FormalChenIteratedIntegrals.wl` moved from `Observable/` to `Functions/`.
No compatibility wrapper loads the old paths.

[The cleanup report](../../../Design/ProductionPathConsolidation_2026-09-06.md)
records validation and the current scope.
