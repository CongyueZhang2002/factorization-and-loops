# General production-path consolidation, 2026-09-06

The active master-integral workflow now has one mathematical constructor:
`ConstructMasterIntegralSolution`, followed by `WriteMasterIntegralSolution`
and the standalone finite-solution reader/evaluator. Raw DEs, optional prepared
forms and different request adapters all enter this path.

## Retirement

Moved 196 files into
[Archive/RetiredCode/FeynFacet/2026-09-06-production-consolidation](../Archive/RetiredCode/FeynFacet/2026-09-06-production-consolidation/README.md):
nine package modules (11,540 lines), 155 scripts/control/data files and 32
tests/fixtures/bytecode files. Current modified and untracked bytes were preserved.
The [manifest](../Archive/RetiredCode/FeynFacet/2026-09-06-production-consolidation/manifest.json)
records paths, byte counts, reasons, active relocations and pre-edit snapshots.

Removed the public declarations, definitions and editor metadata for 31 retired
interfaces. This includes the already-retired CANONICA class-ladder and whole-family
Libra compatibility stubs. The private `TransportWord` collection branch is gone;
the algebraic zero checks needed by optional epsilon-form algorithms remain.

The defunct `DiagonalBlockClassCampaign` fallback option is removed.
Its additional result check is now called `"ValidateCanonicalForm"` rather than
`"CanonicaValidation"`; the actual mathematical check is unchanged.

The old lazy transport launchers, CF303-specific and physical-boundary campaigns,
legacy matching/letter-map composition and their exclusive tests are archived.
Two text-only finite-solution checking scripts are archived too; the current
`VerifyMasterIntegralSolution` API accepts the complete stored finite record.

## Retained and consolidated

- Integral representations, normalization discovery, Laurent bounds, coefficient
  demands and sufficient epsilon-order planning.
- General DE construction, finite coefficient construction, serialization,
  FLINT/Wolfram evaluation, numerical batches and explicit local Taylor expansions.
- Optional epsilon-form construction, radical algebra and coordinate changes.
- Local Frobenius expansions, residue extraction, boundary mode matching and
  boundary-function differential systems.
- Optional GPL/elliptic kernel notation and conversion.

`MasterIntegralEpsilonOrderRequirements.wl` now lives in `Transport/Orders/`.
`FormalChenIteratedIntegrals.wl` now lives in `Transport/Functions/`.
`Transport/Observable/` has no active implementation.

The [production guide](../Scripts/Transport/README.md), root README, script guide,
test guide and live mathematical schema describe the current path. Historical
five-family examples are labelled as such; the current completed run covers all
91 families. Existing generated mathematical results were not rewritten.

## Deliberately unfinished boundary interface

Some retired adapters implemented real connection-map mathematics, not just
format conversion: ordered path concatenation, regularized singular matching,
tangential-base-point normalization, resonant-mode binding and epsilon propagation
through matching maps. Their code and mathematical notes are preserved, but these
operations are not currently available through the finite-solution interface.

Retaining local Frobenius/residue routines does not automatically replace the
former end-to-end composition capability. A future implementation should attach
these operations to the same finite solver, with explicit branch, regularization
and epsilon-order data. Physical constants and general analytic continuation were
not implemented by this cleanup.

[Pro's architectural review](../External/ChatGPT/Records/2026-09-06/08_production_consolidation.md)
supported the retirement and emphasized this distinction. It reviewed the method
description, not the uncommitted source diff.

## Validation

All 22 focused test files pass in fresh processes. They cover package
exports and generality, optional canonicalization, retained local boundary
mathematics, order determination, finite solutions, numerical backends and batch
execution. Mixed tests retained their current mathematical assertions.

A fresh standalone reader loaded all 91 current solution files with `Get`/`Import`
from `Private_Backup` refused. None of the stored coefficient, algebraic, kernel
or finite-integral expressions reference a retired public helper or a
private FeynFacet implementation helper. CF259 and CF303 numerical regression
comparisons passed for all 92 requested coefficients at tolerance 10^-30 using
the same nonphysical test constants and points as before cleanup.

Executable source scans found no calls to the retired public symbols or their
exclusive private helpers. The remaining public-name strings are absence checks.
The manifest contains 70 existing, unique module files and no unlisted active
Private modules. The backup is outside active module and test discovery.

[Validation evidence](../ppHX_NNLO_DoubleReal/Results/Validation/ProductionPathConsolidation_2026-09-06/README.md)
contains the final logs, result summaries and reproducible stored-artifact checks.
This is a dependency/behavior check, not a new all-family physics validation.
