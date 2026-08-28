# A3 final state — pre-cancellation divisor provenance and the deferred bundle
2026-08-26, dev agent A3, base 06ba162. Working tree left uncommitted as directed.

## What landed

### FeynFacet/Private/BlockEquationDeferred.wl (only source file touched; +838/-21)
New section "THE PRE-CANCELLATION DEFERRED BUNDLE" (after the old divisor
metadata, before the driver entry point):

- `$blockEquationDeferredBundleSchema = "BlockEquationDeferredBundleV2"` and the
  full Codex A3 contract: Schema/Status("PreparedDeferredBundle")/ABIVersion/
  Variables/Regulator/Parameters/RootFrame{Roots,RootFingerprints,
  OrderingFingerprint}/Dimensions/TargetOrder/OperandTable/Jobs/
  DivisorOccurrences/DivisorSummary/SourceFingerprint/BundleFingerprint/
  Statistics. Statistics is the one field outside the fingerprint (wall times).
- `blockEquationDeferredRootFrame` — validates caller root records
  ({"Root","RootSquare"} shape), refuses DuplicateRootSquares and
  DependentRootSquares (dependence test via multiquadraticStripSquareClassSquareQ,
  read-only) BEFORE any orbit work; canonical order via
  multiquadraticStripCanonicalRules/Expression (read-only).
- Grade algebra: `blockEquationDeferredGradeReduceRules` / `GradeReduce` /
  `GradeChannels` / `AlgebraicZeroQ` (exact zero over the declared field by
  substitution + conjugation + per-channel Together, $Failed on undeclared
  radical, never a silent False).
- `blockEquationDeferredFrameCanonicalize` — build-order step 2: every operand
  denested into the declared frame through the SHARED exact denester
  (transportChartDenestRadicalBase + sign-fixed
  transportChartCanonicalizeDenestedRadicals). Sqrt[Delta1 Delta2] becomes the
  grade {1,2} product; typed DeferredRootFrameRequired /
  RadicalOutsideDeclaredFrame / UnsupportedAlgebraicPower.
- `blockEquationDeferredFactorRootMask`, `blockEquationDeferredFactorOrbit` —
  orbits generated ONLY from declared roots, reduced to the grade basis,
  norm accepted on all four Codex conditions (nonzero channels vanish,
  grade-zero radical-free, generator sign flips permute the orbit exactly,
  orbit size divides 2^rank; duplicates removed by exact channel equality).
- `blockEquationDeferredBundleTargetOrder` / `BundleFingerprint` /
  `BundleValidate` (schema, dimensions, lexicographic target coverage, job
  alignment, operand-ID bounds, root-order fingerprint, recomputed bundle
  fingerprint) / `BundleEvaluate` (each interned operand exactly once per
  point, OperandEvaluations counter returned).
- `blockEquationDeferredCompileBundle(WithCache)` — the compiler (build order
  steps 1-5): preparation fingerprint check, root frame, frame
  canonicalization per operand (cached), interning via the SHARED
  blockEquationDeferredCanonicalOperand core, pre-cancellation
  DivisorOccurrences from BOTH routes (canonical Together denominator factors
  AND explicit negative powers of the pre-Together spelling) with
  target/term/operand provenance, immutable jobs, validated orbits,
  DivisorSummary with EntryPoleOrderUpperBounds + CertifiedEntryPoleOrder ->
  None + Certification -> "PreCancellationUpperBound" (never labels the source
  maximum as exact). WithCache returns the intern pool for reuse.
- `blockEquationDeferredForcing`: new options "Output" -> "Bundle" |
  "BundleAndMaterialized" (default the latter until the provider consumer
  lands in MultiquadraticStripSolve.wl — its sole production caller
  Scripts/family_epsform_sector.wls:790 reads "Forcing"; then flip to
  "Bundle" per Codex), "BundleRoots" (Automatic inherits DivisorRoots, else
  {}; NEVER synthesized), "MaterializeFunction" (injected-oracle seam).
  Bundle compiled BEFORE materialization; "Output"->"Bundle" returns the
  bundle (census in Statistics) and never calls the materializer; typed
  bundle refusals are fatal in Bundle mode, non-fatal (recorded under
  "DeferredBundle") in compat mode so the production driver is unchanged.
- `blockEquationDeferredMaterialize`: new "SeedPool" option — compat mode
  seeds it with the compiler's pool so Together/FactorList per distinct
  operand is paid once, not twice.
- Old `blockEquationDeferredDivisorMetadata`: "Roots" -> Automatic no longer
  manufactures generators from observed radicals (algebraic factors get
  Missing["RootFrameRequired"] orbit/norm; new "RootFrameDeclared" field);
  fixed a latent Function::slotn slot defect in its orbit-dedup comparator.

### Tests/t_construction_bundle.wls (NEW; the full Codex A3 test list)
(a) contract+validation+plain-data; (b) oracle equality bundle-vs-materialized
on rational AND algebraic blocks, symbolic and at an exact point, operand
evaluated exactly once; (c) algebraic divisor kept in provenance after exact
cancellation removes its visible spelling; (d) complete cancellation: zero
entry, provenance retained, upper-bound label only, CertifiedEntryPoleOrder
None; (e) Sqrt[d1 d2] -> two declared generators, mask 3, no third root,
sign-exact; (f) DependentRootSquares (before orbits) + DuplicateRootSquares;
(g) RadicalOutsideDeclaredFrame + DeferredRootFrameRequired; (h) norm
channels/sign-invariance/orbit-size recomputed independently; (i) mutation of
operand IDs / target order / root ordering / job coefficient / operand
numerator each breaks validation with its typed status; (j) injected oracle:
"Output"->"Bundle" never materializes (also on typed refusal), compat mode
does (negative control), InvalidOutputMode typed; (k) seeded materializer
SameQ-identical to unseeded.

## Test counts (all verified green post-fix, single-suite runs)
- Tests/t_construction_bundle.wls: 44 assertions, 0 failed
  (scratchpad/round3/t_bundle_run1.log)
- Tests/t_construction_dag.wls: 78 assertions, 0 failed (regression test,
  t_dag_run1.log)
- Tests/t_construction_dag_divisors.wls: 15 OK, 0 FAIL (regression test,
  t_divisors_run1.log)

## Red-before-green evidence
- PRE-FIX RED PROBE (run on unmodified code BEFORE any edit):
  scratchpad/round3/a3_prefix_red_probe.log — shows (D1) no bundle in the
  public result, (D2) "Roots"->Automatic manufacturing Sqrt[d1 d2] as its own
  generator with an orbit built from it, plus the latent Function::slotn
  defect firing. This is measured red evidence on the pre-fix code.
- FULL-SUITE RED RUN (t_construction_bundle over a pre-fix overlay of
  06ba162's BlockEquationDeferred.wl, scratchpad/round3/
  t_construction_bundle_prefix.wls): PENDING — five launch attempts were
  refused with "Wolfram product is not activated or license-related problem"
  while the coordinator's kernels held the seats (attempts + backoffs logged
  in progress.log). NEXT STEP after reset: run
  `wolframscript -f scratchpad/round3/t_construction_bundle_prefix.wls`
  (self-contained; loads the package, overlays the pre-fix file extracted at
  scratchpad/round3/BlockEquationDeferred_prefix.wl, clears the new symbols,
  runs the identical 44 assertions; expected heavily red), save the log as
  t_bundle_prefix_red.log. No source change needed — the overlay approach
  leaves the working tree untouched.

## Unfinished / follow-ups (exact next steps)
1. The pre-fix full-suite red log (above) — one wolframscript run.
2. Default flip "Output" -> "Bundle" in blockEquationDeferredForcing once the
   coordinator's provider consumes the bundle (one-line option change +
   driver Scripts/family_epsform_sector.wls adaptation, coordinator's call).
3. Read-only runtime dependencies on MultiquadraticStripSolve.wl the
   coordinator should not rename without telling A3:
   multiquadraticStripSquareClassSquareQ, multiquadraticStripCanonicalRules,
   multiquadraticStripCanonicalExpression (all called from
   blockEquationDeferredRootFrame). No missing hook was needed.
4. Deliberately NOT done (spec allows): operand-ID packing (lists are small);
   restructuring the materializer's own interning loop (the shared core is
   blockEquationDeferredCanonicalOperand + SeedPool reuse instead — zero
   behavioral risk while the coordinator edits the consumer concurrently).
5. Compat-mode note: on algebraic blocks without declared roots the bundle
   compile fails fast (typed, before interning) so production cost is
   unchanged; on rational blocks the intern pool is shared via SeedPool.
