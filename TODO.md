# Factorization and Loops — To Do

## Rewrite plan (agreed 2026-08-09)

Management model: Fable acts as architect/manager and reviewer; Opus
subagents write the individual modules against specifications and tests
defined here. Every module lands with its tests in the same commit.

### 0. Decisions taken

- Keep the pair-level (forward × conjugate) work unit, but emit all
  coefficients on canonical integral families (see item 2).
- Conjugation symmetry (compute only forward ≤ conjugate, take 2 Re):
  **deferred**, future task. Full grid remains for now.
- Kinematics are rationalized once at the card level (item 4); the
  root-lifting / branch-grammar machinery is deleted, not ported.
- Validations stay in the package but become optional boundary checks
  (off in inner loops, on at artifact write/read).
- The finite-field (Ratracer/FireFly) coefficient pipeline is the only
  coefficient pipeline. The symbolic path and the abandoned streaming
  path are removed.
- New module layout under `FeynFacet/Kernel/`: Card, Amplitudes,
  Projectors, Cuts, Families, DimShift, Kira, Coefficients, Masters,
  Distributions, IO, Parallel.

### 1. Physics correctness gate (before any porting)

- [ ] Double-real gluon polarization sums: current code uses
      `DoPolarizationSums[.., 0]` (-g) with no ghost contributions.
      Decision: add cut ghost–antighost process cards (U[5], -U[5])
      combined with the -g gluon sum, standard relative minus sign and
      symmetry-factor bookkeeping. Ghost pairs replace the gluon pair —
      same 2 -> 4 kinematics, still two-loop cut integrals.
- [ ] Audit the identical-particle symmetry factor (1/2! for the gg
      final state) through prefactor assembly; verify it is applied
      exactly once.
- [ ] Validate the combination by a gauge/known-result check at a
      numeric phase-space point.
- [ ] Brute-force numeric validation of `masslessSquareBounds` /
      `IdentifySafePropagator` (random massless phase-space points vs
      the claimed pairwise-product extrema); compare against the
      derivation in the Overleaf notes
      (`Factorization_Agent_for_Collider_and_Event_shape_Theory.pdf`).

### 2. Canonical integral families

- [ ] Global cut-aware family registry: map every partial-fractioned
      denominator set onto canonical families (Pak-style canonical form
      with cut propagators distinguished, energy directions preserved);
      family identity independent of the diagram pair.
- [ ] Target: collapse the NNLO double-real 374 families to O(10);
      re-run Kira and compare masters/rules against the preserved
      solved workspace.

### 3. Kira interface and artifact format

- [ ] Streaming-first artifacts: WXF record store (extend the existing
      `coefficientAppendRecord`/`coefficientScanRecords` layer) as the
      only format for large data; small human-readable manifests with
      SHA-256 fingerprints; validate at write time, check hash on load.
- [ ] Streaming one-family-at-a-time Kira import and rule closure with
      progress and peak-RSS reporting (supersedes the 2026-08-07 OOM
      redesign list below; its acceptance criteria still apply).
- [ ] Replace stdout regex parsing of Kira ("unreduced integrals") with
      checks on the exported results files.

### 4. Rationalized card kinematics

- [ ] Redefine the hadronic-coordinate variables so every square root
      is a perfect square (roots as primary variables); coefficients
      become rational in (coordinates, fractions, eps) by construction.
- [ ] Port the NLO UU/TT cards and reproduce the frozen NLO golden
      results exactly.

### 5. Dimensional shift (BMHV)

- [ ] Benchmark the current pre-IBP Tarasov shift against treating
      mu_ij = SPE(l_i, l_j) numerators as ordinary irreducible
      numerators inside the Kira families (no pre-IBP shift); switch if
      the family/target growth is favorable.
- [ ] Unit-test the shift against AMFlow on random tensor integrals in
      D and D+2.

### 6. Dead code and duplication removal

- [ ] Delete: `coefficientSimplificationStoredCore` and helpers,
      `coefficientRunPendingMasterJobsLegacy`, all of
      `CoefficientModules.wl`, `FeynFacet/Legacy/`, the symbolic
      `CoefficientSimplification[inputs, kira_Association]` path and
      its `parallelNormalizeCoefficients` scheduler.
- [ ] One parallel job runner (single work-queue utility with optional
      per-job timeout) replacing the four ad-hoc pools.
- [ ] One analytic-context validator (remove the
      `Block[{analyticContextQ = ...}]` override), one rationality
      predicate, one `CoefficientSimplification` entry point.
- [ ] Reduce FCI/FCE round-trips and per-term `exactZeroQ` scans to
      module boundaries.

### 7. Test infrastructure

- [ ] Minimal assertion runner for `Codex/Tests`; every test declares
      its acceptance criterion machine-checkably.
- [ ] Golden-file regression tests: frozen NLO UU/TT results (masters,
      coefficients, finite hard function) must reproduce bit-exactly.
- [ ] End-to-end numeric stage: evaluate the assembled hard function at
      rational phase-space points against AMFlow on the weighted master
      sum.

### 8. Deferred: steps 9–10 master plan (skip this round)

Analytic master evaluation and endpoint assembly stay agent-driven for
now; codify later as:

- [ ] Masters module: store differential-equation systems, boundary
      constants, and epsilon-solutions as versioned artifacts;
      cross-check every master with AMFlow at several kinematic points;
      prefer a deliberately chosen (quasi-finite / uniform
      transcendentality) master basis so the DEs and endpoint limits
      become mechanical; SubTropica for linearly reducible phase-space
      representations.
- [ ] Distributions module: implement the (1-w)^(-1-a eps) ->
      delta(1-w) + plus-distribution expansion following the
      handwritten conventions (`Distributions.pdf`), transcribed into
      executable tests; keep exact endpoint factors until masters and
      coefficients are combined.
- [ ] Assembly module: real + virtual + UV renormalization + collinear
      counterterms -> finite hard function, with pole-cancellation
      checked exactly, order by order in eps.
- [ ] Future: exploit conjugation symmetry (item 0) to halve the pair
      grid.

## Kira rule import and closure (2026-08-07 record)

Superseded by rewrite items 2–3 above, but the measurements and
acceptance criteria remain the reference for the NNLO workspace:

- 374 topology families reduced with 12 Kira workers; zero unreduced
  integrals reported per family; 44,877 input integrals; 342 masters;
  compact reduction data ~5.88 GB; Mathematica import OOM-killed near
  47.7 GB RSS before `KiraResult.wl` was written.
- Preserve the solved workspace at
  `/home/maxzhang/FACET/Codex/ppHX_NNLO_DoubleReal/Kira/UU_08_05_1` so
  the importer can be retested without rerunning Kira.
- Validation targets for the new importer: exact arithmetic, one rule
  per left-hand side, no conflicting duplicates, no pinched cuts, zero
  undeclared frontier integrals, the same 342-master set; record wall
  time and peak RSS separately for Kira, import, closure, and save.
