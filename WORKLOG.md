# Work log

Running record of findings, decisions, and landed work. Newest entries
at the bottom of each date section. Maintained by Fable (architect) with
Opus subagents doing module implementation; every landed item has its
tests in the same commit.

## 2026-08-10 (day)

**Landed** (all pushed, suite green at each step):

- Test harness (`Tests/TestKit.wl`, `run_tests.sh`); suite grown to 7
  tests over the day.
- Fixed-sign theorem validated: notes Sec. 3.1 proof reviewed sound;
  implementation checked on 6000 RAMBO points (`t_fixed_sign_theorem`).
- Ghost-antighost cut card `UU_Ghost.wl` (7 diagrams; unmodified
  pipeline runs a ghost pair in ~3 s). Assembly convention documented:
  sigma_gg = (1/2!) x gluon grid (-g sums) - ghost grid.
- `IdenticalParticleSymmetryFactor`: 1/n! per identical untagged
  outgoing species; the 1/2! for the NNLO gg state was confirmed absent
  from the whole pipeline and is applied at assembly.
- Canonical family registry (Opus): cut-aware Pak keys + fail-closed
  verified GLI mappings; NLO 178 records -> the exact 11 ground-truth
  classes.
- NLO regeneration (user decision): 100/100 pairs with the current
  analytic context -> `UU_08_10_10x10_regen`; golden test proves
  old-minus-new integrand difference is EXACTLY ZERO pair by pair (the
  2026-08-08 BMHV correction was representation-only for unpolarized
  UU) and the fresh reduction reproduces the same 7 masters.
- Streaming Kira import (Opus): KiraSolve / KiraStreamImport /
  KiraStreamResult; NLO acceptance 19/19; peak MemoryInUse 223 MB
  against the 47.7 GB OOM of the monolithic path. Recursion-limit
  hardening added in review.
- Canonical pipeline integration (Opus): `CanonicalizePairArtifacts`
  post-pass, `ibpInputData` dedupe + canonicalized detection, identity
  equivalence fast path in both reduction paths; 23/23; canonical
  reduction reproduces the reference images exactly (125 coefficients).
  Corner-BaseGLI deviation documented in the module; identity-rule bug
  in the prototype found and fixed by the agent.

**Measured facts worth remembering**

- Pak partition == stored affine-verified equivalence on ALL data
  (NLO 178->11, NNLO 1898->430); the 342 NNLO masters are all
  Pak-distinct. The old pipeline's merging was already optimal at its
  level; 374 = classes that carried targets.
- The "preserved solved NNLO workspace" of the 2026-08-07 record does
  not exist (the successful run deleted it after saving); NNLO
  streaming validation folds into the NNLO rerun.
- The reference NLO coefficient result
  (`UU_08_05_10x10_1/CoefficientResult.wl`, FormatVersion 8) was
  produced 2026-08-09, after the BMHV fix, so it is physics-current.

## 2026-08-10/11 (overnight)

**Outcomes so far:**

- Step 1 done (02:35): canonical-families integration verified
  independently (7 tests, 87 assertions) and committed (d0f8b6c).
- Step 2 done (02:52): coefficient-level NLO golden green 6/6
  (59c0f03). The finite-field reconstruction on the regenerated set
  reproduces the reference CoefficientResult.wl exactly (7 masters,
  every coefficient product and the remainder identical). NLO UU is
  golden-locked at pre-IBP, reduction, and coefficient level.
- Step 3a done (03:00): ghost grid 49/49 regenerated, zero failures
  (UU_Ghost_08_10_1). Gluon grid 36x36 (UU_08_10_1) launched in
  background (expect hours; resumable).

Plan, in order; each step appends its outcome here:

1. Independent full-suite verification of the canonical integration
   (running); commit + push on green.
2. Coefficient-level NLO golden: finite-field CoefficientSimplification
   on the regenerated set vs the reference CoefficientResult.wl,
   per-master exact comparison.
3. NNLO rerun chain (resumable, background):
   a. regenerate ghost grid (7x7) and gluon grid (36x36) with the
      current package (`Scripts/regenerate_pairs.wls`);
   b. canonicalize each grid (post-pass). NOTE: one *shared* registry
      across the two grids needs a registry-seeding API that
      `CanonicalizePairArtifacts` does not have yet; tonight the grids
      are canonicalized independently (correctness unaffected - the
      1/2 and -1 combination happens at the coefficient level; shared
      families were an optimization). API gap logged for the morning.
   c. KiraSolve + KiraStreamImport per grid (first NNLO-scale exercise
      of the streaming importer and the kira2math frontier branch);
   d. if the chain is clean and time remains: NNLO finite-field
      coefficient reconstruction.
4. Not attempted overnight (need daytime discussion or are gated):
   dimensional-shift benchmark (item 5, gated on NNLO infra),
   rationalized kinematics (item 4, changes card variables - user
   input wanted), dead-code removal + runner consolidation (items 6/9,
   should not race the overnight chain), legacy Codex test migration,
   assembly module + gauge check (needs both grids' coefficients).
