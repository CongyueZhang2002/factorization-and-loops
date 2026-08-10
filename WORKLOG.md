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
- Step 3a done for the gluon grid too (03:35, far faster than
  expected): 1296/1296 pairs regenerated, zero failures, ~35 min on 6
  subkernels (1.1 GB of artifacts).
- Step 3b+c done for the ghost grid (09:00): full chain green -
  canonicalization 49 pairs -> 25 canonical families in 28 s (0
  rejected), Kira solve 239 s, streaming import 12.9 s at peak 573 MB;
  2451 targets -> 27 masters, 2447 rules
  (UU_Ghost_08_10_canonical/KiraStream). First NNLO-style exercise of
  the full canonicalize+solve+stream chain.
- Step 3b+c gluon chain launched (09:02): canonicalization of 1296
  artifacts, then the big Kira solve, then the first true NNLO-scale
  streaming import.
- Step 3b+c gluon chain COMPLETE (10:55, exit 0). Full NNLO double-real
  reduction reproduced from cards on current code:
    - canonicalization: 27.5 min, 430 canonical families, 0 rejected
      (exactly the measured Pak-class count);
    - Kira solve: 1 h 58 m on 8 workers (historical ~2.5 h on 12
      workers - FASTER on fewer workers; requirement met);
    - streaming import + closure + artifact: 12.6 min, peak
      MemoryInUse 7.9 GB (the stage that OOM-killed the old importer
      at 47.7 GB; closure ran 4 family-wise rounds, 45,513 integrals);
    - 374 solve families, 45,129 targets -> 347 masters, 45,171 rules
      (UU_08_10_canonical/KiraStream).
- FINDING: 347 masters vs historical 342. All 347 are Pak-distinct (no
  cross-family duplicates; checked). Exactly 5 masters carry
  irreducible-numerator indices; the post-BMHV-fix integrand
  representation reaches a slightly different target set (45,129 vs
  44,877), steering Kira to a slightly different (equally valid) master
  basis. Physics equality to be established downstream: (a) NNLO
  finite-field coefficients, (b) optional cross-check mapping the old
  798 MB KiraResult through the canonical registry.

- NLO cross-test of the canonical+streaming composition (11:20):
  green - 11 families, 116 targets, 7 masters, peak 214 MB
  (UU_08_10_canonical_stream). Every path combination is now exercised.
- Ghost-grid finite-field coefficients launched (11:25) via the new
  stream-to-coefficients bridge (KiraStreamResult materialization) -
  first NNLO-shaped run of the coefficient machinery, at the safe
  2451-target scale.

- Ghost-grid finite-field coefficients GREEN (12:05, exit 0): 2451
  targets -> 27 master coefficients in 34 min on 6 kernels (FireFly
  100 s). The declared NNLO Laurent valuation xa^-1 xb^-1 zh^-2 was
  VERIFIED EXACTLY by the reconstruction (first finding of the run: the
  NNLO cards declared LaurentValuation -> Automatic, which the FF path
  rejects fail-closed; declared + verified, cards updated).
- Registry seeding landed (df4821b, 6/6 assertions): grids of one
  process now share one family namespace; ghost re-canonicalization on
  the gluon seed running (UU_Ghost_08_10_shared).
- Gluon-grid finite-field coefficients launched (12:10; 45,129 targets,
  8 kernels / 12 FireFly threads; ghost-scaling estimate ~6-8 h,
  historical symbolic-path estimate was 6-10 h on 8 kernels).

**Morning plan (recommended supervised next steps):**

1. NNLO finite-field coefficient reconstruction on the canonical gluon
   set (first NNLO-scale exercise of the CoefficientStore target
   collection; run supervised, not blind).
2. Same for the ghost grid (small), then the sigma_gg assembly:
   (1/2!) x gluon - ghost via IdenticalParticleSymmetryFactor.
3. Optional: cross-validate old-vs-new NNLO reduction images by
   canonicalizing the OLD topology records (Pak partition proven
   identical) and comparing target images through the registry.
4. NLO cross-test of the canonical+streaming composition (closes the
   last untested path combination; minutes).
5. Registry-seeding API so gluon+ghost grids share one registry.

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
