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

- [x] Double-real gluon polarization sums: decision taken and landed
      2026-08-10 — cut ghost–antighost card
      `ppHX_NNLO_DoubleReal/Cards/UU_Ghost.wl` (7 diagrams, pipeline
      unmodified, `Tests/t_ghost_card_pipeline.wls` passes). Assembly
      convention in the card header:
      sigma_gg = (1/2!) x gluon grid - ghost grid.
- [x] Symmetry-factor audit (2026-08-10): the identical-gluon 1/2! is
      absent everywhere in the current pipeline and notes; it must be
      applied at assembly together with the ghost subtraction. The
      general rule is 1/n! per identical untagged final-state parton
      species, derivable from the card.
- [ ] Wire the (1/2!) gluon + (-1) ghost combination into the
      assembly stage.
- [ ] Validate the combination by a gauge/known-result check at a
      numeric phase-space point.
- [x] Brute-force numeric validation of `masslessSquareBounds` /
      `IdentifySafePropagator` (2026-08-10):
      `Tests/t_fixed_sign_theorem.wls`, 7 assertions pass (6000 RAMBO
      points, implementation vs direct extrema, accept/reject paths).
      The Overleaf notes prove the bound exactly (Sec. 3.1, max-flow /
      min-cut convex decomposition); proof reviewed and sound.

### 2. Canonical integral families

- [ ] Global cut-aware family registry: map every partial-fractioned
      denominator set onto canonical families (Pak-style canonical form
      with cut propagators distinguished, energy directions preserved);
      family identity independent of the diagram pair. Design and
      measurements in `Design/CanonicalFamilies.md`; prototype in
      progress (Opus agent, 2026-08-10).
- [x] Validation measurements (2026-08-10): Pak partition identical to
      the stored affine-verified equivalence on NLO (178 -> 11) and
      NNLO (1898 -> 430; 374 = classes with targets); the 342 NNLO
      masters are all Pak-distinct. The existing merging is optimal at
      its level; the registry's win is incremental O(N) merging and
      stable cross-run family identity, not a smaller class count.
- [ ] Benchmark sector embedding (430 completed families -> few
      maximal cut families with sub-sector GLIs) on a target subset:
      compare Kira wall time and exported rule mass against the
      preserved solved workspace before adopting.

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

- [x] Minimal assertion runner (2026-08-10): `Tests/TestKit.wl` +
      `Tests/run_tests.sh`, one kernel per test, nonzero exit on
      failure. Migration of the legacy `Codex/Tests` scripts onto it
      remains open.
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

### 9. Additional hardening and cleanups (2026-08-09 review items)

- [ ] **Artifact version skew (found 2026-08-10):** `analyticContextQ`
      (Core.wl) requires `"CoefficientKinematics"` in the analytic
      context, but the saved 2026-08-05 NLO artifacts predate that key,
      so `topologyRecordQ` now rejects every one of them - breaking
      `TopologyEquivalence`, `MasterIntegralAmFlow[result, ...]`, and
      the artifact validators on exactly the data the golden regression
      tests need. The context stores a self-consistent fingerprint, so
      in-place patching is impossible: either make the required-key set
      version-aware or regenerate the NLO artifacts. Decide before the
      golden-file tests (item 7) and the NNLO rerun.

- [ ] Scope kinematics into the process object: stop mutating global
      `SP/SPD/SPE` DownValues in `BuildGlobalBasis`/`declareGlobalBasis`;
      pass the basis and on-shell rules explicitly.
- [ ] Symbol hygiene: generated names (`Global`TopologyF*`, invariant
      aliases `f<hash>p*`, `FACETff*`) move into a dedicated context
      with deterministic naming.
- [ ] Replace `canonicalizeLinearTerms` string-based key ordering
      (`ToString[InputForm[...]]` per GLI per merge) with a fast
      canonical order.
- [ ] Deduplicate the `$ibpFailure` tag vs the `"FeynFacetIBPFailure"`
      string literal in the parallel import.
- [ ] Script-first drivers: `.wl`/`.wls` drivers for every pipeline
      stage; notebooks only for inspection (removes the notebook-safety
      hazard class documented in AGENTS.md).
- [ ] Record and check third-party versions at load (FeynCalc,
      FeynHelpers, FeynArts, Kira, Ratracer hashes are already in the
      reduction payload; surface a mismatch warning at package load).
- [ ] Gluon twist-2 correlators: `densityHead` currently fails for
      hadron-associated gluon legs; needed for qg/gg channels later.
      Design the correlator interface now so the card schema does not
      change again.
- [ ] Rename FACET -> Factorization and Loops in README/AGENTS once the
      final name is chosen; refresh README layout description for the
      new tree (symlinked addons, frozen legacy tree).
- [ ] Fold the remaining first-answer inefficiency list into item 6 as
      encountered: repeated full-artifact revalidation on load,
      `validateCutGLIs` full-expression scans per stage, repeated
      `exactZeroQ`/`Cancel@Together` in hot loops.

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
