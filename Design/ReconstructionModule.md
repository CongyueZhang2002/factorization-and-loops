# Design: first-class finite-field reconstruction in FeynFacet

Goal: replace the ad-hoc reconstruction scripts (launch.sh / finish.sh /
series_production.sh, hand-rolled monitors, scratch parsers) with a
package-level reconstruction stage as generic as the dimensionless-
kinematics construction: everything channel-specific comes from the
card/context; the module knows nothing about UU vs TT vs ghost.

All numeric facts referenced here are measured (WORKLOG 2026-08-12/13):
the hybrid schedule (bundle homogeneous columns, isolate outliers),
eps-truncated series reconstruction (13x probe reduction on the fat
column, verified exact to truncation), the parser defects on partial
result sets, and the progress-monitoring requirement.

## Public API (Simplification.wl or a new Reconstruction.wl)

    ReconstructCoefficients[traceDirectory, options]

returns/writes the standard coefficient artifact. Options:

- "SeriesVariable" -> Automatic | None | symbol.
  Automatic = the context regulator (Epsilon), None = full rational
  reconstruction. Series mode uses ratracer `to-series` (Laurent-pole
  aware; verified).
- "SeriesOrder" -> 5 (production default, user decision 2026-08-13:
  safety margin over master pole depths; ~15% probe overhead).
- "Threads" -> Automatic (respects the core-cap convention:
  Global`$FACETKernelLimit, currently 16 by user grant).
- "Schedule" -> Automatic: bundle all columns with expression files
  below "BundleBelowBytes" (default 16 MB) into one shared trace;
  isolate larger columns as sequential solo jobs, ascending by size
  (early completions validate the run). Rationale: shared traces pay
  max-probe-count times total-eval-cost; only homogeneous columns
  bundle well (measured 18h-vs-8h case).
- "Resume" -> True: a completed rec file with a DONE marker is never
  redone; interrupted jobs restart cleanly (FireFly cannot checkpoint).
- Progress: every job appends (epoch, probes) once a minute to
  <dir>/progress/<job>.progress; public ReconstructionStatus[dir]
  prints per-job phase (scan / prime n), probe count, measured rate,
  and ETA once an expected total is known (after the first completed
  prime of a comparable column, or the recorded count on resume).

## Parser and assembly (replace the defective path)

Adopt the reviewed Scripts/assemble_reconstruction.wls internals into
the package, replacing direct use of finiteFieldParseReconstruction
(defects filed in TODO 2026-08-13: subset-unsafe block extraction,
absolute-vs-relative marker mismatch, per-output full-text scans,
undiagnosed $Failed):

- streaming one-pass block parser; marker resolution accepts both
  relative and absolute paths; explicit diagnostics per failure cause;
  asserts marker positions are strictly increasing.
- signature-weighted per-master assembly as in the reviewed script.
- Full production CoefficientResult output (not the intermediate
  artifact): including remainder, physical factor, measures — reuse
  the existing finiteFieldAssembleResult tail where possible.

## Series-form storage convention

When "SeriesVariable" -> var, a coefficient is stored as

    <|"SeriesVariable" -> var, "Orders" -> <|n -> rational, ...|>|>

with integer n from the column's true Laurent start (negative allowed).
Downstream consumers (assembly weights, golden tests) must accept both
this and the plain rational form. The artifact records
"SeriesTruncation" -> maxorder so no consumer can silently assume
completeness beyond it.

## Verification hooks (optional boundary checks, package idiom)

- "VerifySlices" -> n: per column, n exact univariate-slice
  comparisons against the original expression file (adopt
  Scripts/verify_reconstruction_slice.wls: textual substitution,
  degenerate-point redraw, signature division).
- "VerifySeriesOrders" -> k: for isolated (solo) columns in series
  mode, an independent reconstruction at maxorder k < production depth
  must agree order-by-order exactly (two independent FireFly runs).
- Composition check (Codex protocol #1) stays a separate script for
  now; hook name reserved: "VerifyComposition".

## Tests (land with the module, same commit)

- t_reconstruction_nlo.wls: NLO golden through the new API in BOTH
  modes: full-rational equals the stored golden exactly; series mode
  equals the eps-series of the golden exactly to depth. Timing
  recorded.
- t_reconstruction_ghost.wls: ghost grid in series mode vs stored
  exact coefficients (series-expanded); wall time must not exceed the
  measured 18.8 s full-rational baseline.
- t_reconstruction_parser.wls: synthetic rec files exercising subset,
  permuted, and relative-marker cases (regression for the filed
  defects); a wrong-order file must fail loudly, not silently.

## Migration

The ad-hoc scripts under Reconstruction_2026_08_13/ stay as the
historical record; Scripts/assemble_reconstruction.wls and
verify_reconstruction_slice.wls become thin wrappers over the package
functions (keep CLIs working). WORKLOG documents the switchover.
