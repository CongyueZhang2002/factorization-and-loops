# Package organization, 2026-09-06

The active implementation is organized by mathematical responsibility. The
[package guide](../FeynFacet/README.md) is the maintained ownership and extension
reference; Kernel/Modules.wl is the authoritative loading manifest.

The main changes are:
- Separate execution/record infrastructure from exact algebra, coefficient fields
  and coordinate geometry.
- Separate rationalizing catalog formulas from verification, family data and
  differential-system pullback.
- Separate local Frobenius analysis from physical boundary matching.
- Split physical coefficient normalization, finite-field normalization/traces,
  result assembly and execution.
- Separate symbolic solution construction, standalone reading, generic GPL
  mathematics, solution conversion and numerical evaluation.
- Make epsilon-form algorithms an explicitly loaded optional component.
- Move retired code, experimental benchmark implementations and reference PDFs
  outside the active package.

The Pro review recommended the algebra/geometry/DE distinction, explicit loading
boundaries, and a small verified catalog extension rather than a speculative
general geometry plugin system. These recommendations were applied. Public
mathematical symbols and stored process results keep their definitions.
Old private-file paths were removed; active callers use the new paths.

The generic solution constructor works without loading epsilon form. The
standalone reader works without symbolic construction or FeynCalc. Rationalizing
catalog additions are verified atomically before registration. Unsupported new
geometries still need mathematical implementations and are not claimed supported.

Validation and the exact file mapping are retained in the process validation
directory under PackageOrganization_2026-09-06. Only targeted existing tests,
loading/extension tests and source-path audits were run; a full NNLO regeneration
is unnecessary for these structural changes.

Twenty selected tests passed (488 assertions). The layout audit covers 99
manifest source files and 122 literal source references. A stripped installation
also solved a finite DE with epsilon-form sources absent. All 20,786 original
process files are unchanged. See the
[validation record](../ppHX_NNLO_DoubleReal/Results/Validation/PackageOrganization_2026-09-06/README.md).
