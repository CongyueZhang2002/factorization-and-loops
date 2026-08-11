# Factorization and Loops — To Do

## Rewrite plan (agreed 2026-08-09)

Management model: Fable acts as architect/manager and reviewer; Opus
subagents write the individual modules against specifications and tests
defined here. Every module lands with its tests in the same commit.

### 0. Decisions taken

- **Method-development rule (user, 2026-08-11):** new methods and
  fixes are developed and measured at the cheapest sufficient scale
  (NLO -> ghost grid -> NNLO subset via MaximumTargets) before any
  full-NNLO run; a full-scale run is a validation of a measured
  method, never an experiment. (Adopted after the FireFly
  reconstruction consumed >100 core-hours without a prior small-scale
  degree measurement.)
- **Resource budget (user, 2026-08-11):** heavy stages may use 16
  cores (FireFly --threads=16, Kira workers, subkernel pools; machine
  has 20).
- **NNLO coefficient-stage bar (user, 2026-08-11): full projected time
  UNDER 5 h at 16 cores.** Reference points (Codex estimate for its
  own design, 8 cores): input construction 4-6 h, FireFly 0.5-2 h,
  verification+assembly 0.5-2 h, central 7 h total; and the key rate
  datum: a hard 5-variable coefficient at 169,567 probes in 20.2 s on
  8 threads = ~8,400 probes/s. Our terminated run measured ~80
  probes/s on uncanceled inputs - probe RATE (compact inputs), not
  only probe count, is a first-class acceptance criterion: measure
  probes/s at NLO for every candidate trace format.
- **Performance requirement (user, 2026-08-10):** every stage of the
  rewritten workflow must be at least as fast as the historical run.
  Reference points: double-real pair generation 4 h 15 m on 8
  subkernels (2026-08 original) vs 35 min on 6 subkernels (rewrite,
  measured); canonicalization post-pass 27.5 min replaces the
  in-reduction pairwise equivalence search; import: monolithic path
  OOM-killed at 47.7 GB vs streaming path (NLO 223 MB, ghost grid
  573 MB peak); NNLO Kira solve reference ~2.5 h with 12 workers (user,
  2026-08-10) — note the current ibpRunKira default caps workers at 8
  unless Global`$FACETKernelLimit is set; set 12+ on the 20-core
  machine for like-for-like runs. Per-stage wall times recorded in
  WORKLOG.md.

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
- [x] Wire the (1/2!) gluon + (-1) ghost combination into the
      assembly stage (2026-08-10): `AssembleCutContributions`
      (Assembly.wl) - weight = IdenticalParticleSymmetryFactor x (-1)
      per ghost pair, GLI-by-GLI merging on the shared canonical
      namespace, fail-closed on namespace or measure mismatches
      (Tests/t_assembly.wls, 10 assertions). The production sigma_gg
      assembly runs once the gluon coefficients land.
- [ ] Validate the combination by a gauge/known-result check at a
      numeric phase-space point.
- [x] Brute-force numeric validation of `masslessSquareBounds` /
      `IdentifySafePropagator` (2026-08-10):
      `Tests/t_fixed_sign_theorem.wls`, 7 assertions pass (6000 RAMBO
      points, implementation vs direct extrema, accept/reject paths).
      The Overleaf notes prove the bound exactly (Sec. 3.1, max-flow /
      min-cut convex decomposition); proof reviewed and sound.

### 2. Canonical integral families

- [x] Global cut-aware family registry (2026-08-10): prototype +
      pipeline integration landed (`CanonicalFamilies.wl`,
      `CanonicalizePairArtifacts` post-pass, reduction-side dedupe and
      CanonicalIdentity fast path in both reduction paths); NLO
      acceptance reproduces the reference reduction exactly.
- [x] Registry-seeding API (2026-08-10): CanonicalizePairArtifacts
      "SeedRegistry" option — seeded grids keep the seed's family names
      and numbering, corner slots merge across grids, sector-partition
      mismatches rejected (Tests/t_registry_seeding.wls). Enables the
      gluon+ghost shared namespace for assembly.
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
- [x] Streaming one-family-at-a-time Kira import and rule closure
      (2026-08-10): `StreamingKira.wl` — KiraSolve (workspace-retaining
      stage separation), KiraStreamImport (per-family WXF record store,
      family-wise disk-backed closure, kira2math frontier fallback,
      fingerprinted directory artifact), KiraStreamResult
      (compatibility loader). NLO acceptance: identical targets,
      masters, and closed images vs the monolithic path; peak
      MemoryInUse 223 MB. Note: the "preserved solved NNLO workspace"
      from the 2026-08-07 record does not exist on disk (that run
      deleted it after saving), so NNLO validation folds into the NNLO
      rerun. Remaining at NNLO scale: bounded parallel family import
      benchmark; frontier-export branch first exercised at NNLO.
- [ ] Replace stdout regex parsing of Kira ("unreduced integrals") with
      checks on the exported results files.

### 4. Rationalized card kinematics

**Priority raised 2026-08-10: this now BLOCKS the NNLO gluon master
coefficients** (WORKLOG 16:00). **User decision 2026-08-10: option 1**
- square-root substitution variables confined to the finite-field
coefficient stage; cards, Distributions.wl and collinear factorization
untouched. Full spec: `Design/RationalizedCoefficients.md` (the giant
Cancel is not accelerated but REMOVED: FireFly input need not be
canceled; root-freeness is verified on the small reconstructed output).

- [ ] Implement finiteFieldRationalize per the spec; acceptance = NLO
      UU golden + TT baseline + ghost-shared reproduced EXACTLY, full
      suite green, then the supervised NNLO gluon run.
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

- [x] Delete dead pipelines (2026-08-10, -3987 lines, commit 432f862):
      stored-symbolic core + 24-helper closure, CoefficientModules.wl,
      Legacy/, the symbolic CoefficientSimplification path. Finding:
      structuralAdditiveFactor was called in both deleted paths but
      DEFINED NOWHERE - they were broken, not just unused. Remaining
      open decision: SimplifyHardCoefficients (public export) has no
      in-repo callers left; removing it would also drop
      parallelNormalizeCoefficients + the frozen-branch chain (~400
      more lines) - API removal, user call.
- [ ] Newly-orphaned Core.wl helpers to sweep in a later pass:
      compileSparseReduction/linearApplyReduction (orphaned by this
      cut), atomizeProtectedAnalyticObjects, structuralCommonFactor
      (pre-existing orphans).
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
      Done 2026-08-10 for UU at the pre-IBP and reduction level
      (`Tests/t_nlo_golden.wls`) and at the coefficient level
      (`Tests/t_nlo_coefficient_golden.wls`: identical 7-master
      finite-field coefficients vs the 2026-08-09 reference).
      Remaining: the TT card and the finite hard function.
- [ ] End-to-end numeric stage: evaluate the assembled hard function at
      rational phase-space points against AMFlow on the weighted master
      sum.

### 7b. Queued wrap-up items

- [ ] Live progress for long external stages: route the FireFly
      reconstruct invocation through a wrapper script with a live
      stdout redirect (as BuildTrace.sh does), so probe progress is
      tail-able during multi-hour reconstructions (no ETA is possible
      in principle - FireFly discovers degrees adaptively - but
      progress visibility is; requested 2026-08-11).
- [ ] **TOP PRIORITY (rev. 2) - Trace in physical variables {CA, CF,
      eps, x, y}**: the pre-rewrite record (Overnight_2026-08-09,
      master 0064, ~63 s/column at NNLO) proves the working recipe -
      roots eliminated entry-by-entry (equal-denominator merging, the
      2026-08-08 study's NNLO recommendation), scale by dimension
      (monomiality validated exactly on all datasets 2026-08-11),
      fractions by the declared valuation. Port into the validated
      shared-trace/checkpoint infrastructure. Acceptance ladder:
      exact NLO -> TT -> ghost reproduction; NLO shared-vs-one-by-one
      comparison; 3-5 timed NNLO columns for the total estimate;
      MaximumTargets subset; full run only with a projection under the
      bar. (Supersedes the root-variable trace, whose doubled degrees
      caused the 100x blowup; the earlier degree-reduction notes below
      are historical.)
- [ ] Escalation ladder beyond the 5-variable recipe (Codex proposal
      via user, 2026-08-11), to be invoked only if the measured
      column estimate misses the bar: (1) CA/CF as polynomial output
      labels inside the existing signature/bucket machinery (all
      color outputs share each (x,y) probe; cheap, low-risk);
      (2) epsilon Laurent expansion before reconstruction - 2-variable
      rational core, but verify first at NLO that denominators
      factorize as Q_xy(x,y) x Q_eps(eps) (else x,y degrees inflate
      per order), and note it changes storage to truncated-eps series
      (step-9/10 exactness policy decision). FireFly is not a naive
      dense box (factor scan/sparse/racing), so adopt by measurement,
      not by the box-count arithmetic.
- [ ] (historical) Degree reduction for the finite-field probes
      (blocks NNLO coefficients; shared run terminated at 8h/100
      core-hours by user instruction). Two candidates, both to be
      measured at ghost scale first per the method-development rule:
      (a) scale elimination: the s-dependence of every coefficient is
      a monomial fixed by mass dimension, so probe at s=2 (q=1) and
      restore the power at assembly - removes one variable and its
      doubling at zero expression-growth cost; (b) evenization: since
      values are even in each root r, f = (N(r)D(-r)+N(-r)D(r)) /
      (2 D(r)D(-r)) termwise-even -> substitute r^2 -> physical
      variable; halves degrees at the cost of bounded polynomial
      growth (measure the growth factor at ghost scale before
      committing to gluon).
- [ ] **/code-review ultra** (user-triggered, billed): independent
      multi-agent cloud review of the branch after the other items are
      done (user decision 2026-08-11). Covers the Codex-era core plus
      the 2026-08-10/11 rewrite work.

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

- [x] **Artifact version skew (found 2026-08-10, resolved by
      regeneration):** the saved 2026-08-05 NLO artifacts predate the
      `"CoefficientKinematics"` context key and are rejected by current
      validation. Decision: regenerate. Done via
      `Scripts/regenerate_nlo_pairs.wls` -> `UU_08_10_10x10_regen`
      (100/100 pairs, all pass current validation).
- [x] **Stale-artifact delta (found and resolved 2026-08-10):** 98 of
      100 regenerated UU integrands differ *structurally* from the
      2026-08-05 ones (the 2026-08-08 BMHV dimensional-shift correction
      landed after they were generated), but the difference is exactly
      zero pair by pair: old - new vanishes algebraically at the
      integrand level, and the fresh reduction reproduces the same 7
      masters. For the unpolarized UU card the correction was
      representation-only; TT (polarized) remains the case where it
      matters. `UU_08_10_10x10_regen` is the golden baseline
      (Tests/t_nlo_golden.wls, 5 assertions).

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
- [x] Silent Return[$Failed] exits in coefficientCollectTargetRecords
      replaced with labeled messages naming the failed check
      (2026-08-10, commit 432f862); the $ibpFailure string-literal
      duplication is also gone.
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
