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

- Ghost shared-namespace rerun (12:35): ALL 25 ghost families land on
  gluon-registry families, zero new (ghost cut topologies are a strict
  subset of gluon ones, as physics predicts); same 27 masters, now in
  the shared namespace; solve 290 s, import 15.7 s, peak 586 MB
  (UU_Ghost_08_10_shared).
- Assembly module landed (12:50): AssembleCutContributions with derived
  weights (+1 NLO, +1/2 gluon, -1 ghost), exact GLI-by-GLI merging,
  10/10 assertions. sigma_gg = (1/2) gluon - ghost is now one function
  call away once the gluon coefficients finish.

- Gluon FF coefficient run FAILED at target collection (13:00): the
  KiraResult materialization (52 s, 829 MB) and rule-store indexing
  (44,895 rules) succeeded, but coefficientCollectTargetRecords
  returned a silent $Failed. The identical path succeeded for the
  ghost-canonical set, so the failure is scale- or data-linked, not
  structural. Diagnostic script running to isolate which of the
  collection's fail-closed checks fires (per-source validation, target
  set equality vs the reduction, or the source fingerprint).

- Diagnosis (13:35): stepwise diagnostic passed every check (0 source
  failures, target sets identical, fingerprint match), and an
  instrumented rerun of the REAL collection function succeeded
  end-to-end, writing a valid target store. The original failure is
  not reproducible - most plausibly transient I/O or load interaction
  with the ghost-shared chain that overlapped the first attempt.
  Lesson recorded in TODO: the collection's silent $Failed exits must
  become labeled messages. Gluon coefficient run relaunched (13:40);
  it will reuse the validated target store and go straight to
  normalization + trace + FireFly.

- ROOT CAUSE of the gluon coefficient failure (14:25, deterministic
  after all): the canonicalized-record dedupe kept the FIRST-SEEN copy
  of each family record, whose DiagramPair/Created enter the stored
  SourceInputFingerprint - so the fingerprint depended on pair-file
  ordering. The reduction ran with lexicographic ordering, the
  project-form coefficient driver sorts numerically; for the 36x36
  grid the orders diverge -> different kept representatives ->
  fingerprint mismatch -> fail-closed abort. Consistent with every
  observation: ghost 7x7 orders coincide (success), instrumented rerun
  used lexicographic (success), NLO used the direct form with
  lexicographic (success). Fix: ibpDedupedRecords keeps the member
  with the LEAST diagram pair (order-independent); legacy inputs are
  unaffected (dedupe is the identity there). The two NNLO stream
  artifacts are being re-imported from their retained workspaces to
  refresh stored fingerprints - stage separation paying for itself:
  no re-solve needed.

- Post-fix rerun (15:10): the fingerprint fix VALIDATED - collection
  passed cleanly regardless of ordering, and the light regression
  subset is 61/61 green. The run then hit a NEW independent blocker
  deep in target normalization: one target's Kira-image coefficient
  (GLI[CF424, {1,1,1,-1,1,1,1,1,-1}], an aux-numerator target) failed
  the branch-grammar / positive-root-lift preparation. Also found: the
  failure report leaks an unevaluated local (failedMaster) instead of
  naming the master - reporting bug to fix. Single-target diagnostic
  running to identify which master coefficient fails and why (timeout
  in positivity certification vs genuine grammar violation). Note:
  this is exactly the root-lifting machinery that rewrite item 4
  (rationalized kinematics) is designed to delete.

- Normalization blocker diagnosed and hardened (15:40): the failing
  target's master coefficients certify INSTANTLY on an idle kernel -
  the production failure is load/cold-start sensitivity of hard-coded
  10 s TimeConstrained windows around FullSimplify positivity
  certification inside 8-way-loaded subkernels. Fix: caps raised to
  60 s, successful certifications memoized per kernel (False stays
  retryable - it may be a timeout artifact), failure report now names
  the master (was leaking an unevaluated local). Guard
  t_nlo_coefficient_golden green (6/6). Gluon coefficients relaunched
  (15:45) - the ONE bounded fix for this blocker; a recurrence stops
  the chain for write-up. (Also: fourth context-qualification incident
  of the project, this time in my own diagnostic - the rewrite's
  symbol-hygiene item keeps earning its place.)

- BLOCKER, definitively diagnosed (16:00): the NNLO gluon coefficient
  normalization fails deterministically on target
  GLI[CF424,{1,1,1,-1,1,1,1,1,-1}], master GLI[CF1,{1,1,0,0,1,0,0,0,0}].
  Stage-by-stage on the exact coefficient (1.1 MB; 2.4 MB after
  hadronic substitution): hadronic 0.4 s OK, branch grammar OK, root
  lift 0.3 s OK - then the mandatory final Cancel[Together[...]] of
  the root-lifted rational (which performs the root-parity cancellation
  that makes the result root-free for the trace) exceeds its 300 s
  budget. Not load, not a bug: a scalability wall of the
  PositiveMonomialRoots lifting machinery at NNLO coefficient sizes,
  multiplied by 45k targets. This is precisely the machinery rewrite
  item 4 (rationalized card kinematics) deletes: with root-free
  variables the hadronic substitution never introduces half-integer
  powers, so there is no lift and no giant Cancel. RECOMMENDATION:
  pull item 4 forward; do not tune timeouts (even 30 s/coefficient x
  45k targets x ~3 masters is days of Cancel).
  (Diagnostic honesty: my first two single-target probes were
  invalidated by my own script bugs - a context-qualification miss and
  a rule-vs-list destructuring miss - both now fixed in the record;
  the third probe is the one that holds.)

- Ghost-shared coefficients green (16:05): 27 masters in 35 min - the
  ghost side of sigma_gg is complete on the shared namespace. Deferred
  kernel-heavy tests re-run green. Final suite: 10 tests, 109
  assertions, 0 failures.

- TT baseline chain green (16:45): 25 pairs regenerated (0 failures),
  87 targets -> 6 masters, FF coefficients in 6.7 min
  (TT_08_10_1/CoefficientResult.wl - the first TT result on post-fix
  code; no prior reference existed). IMPORTANT for item 4 scoping: the
  evanescent-rich polarized TT coefficients pass the root-lift
  machinery cleanly at NLO scale - the Cancel wall is
  NNLO-coefficient-SIZE specific, not polarization or BMHV specific.

- Dead-code removal landed (17:45, Opus agent, reviewed, 432f862):
  -3987 lines. The never-called streaming-symbolic pipeline, all of
  CoefficientModules.wl, the legacy symbolic coefficient path, and
  Legacy/ are gone; collection failures now name their check. KEY
  FINDING: structuralAdditiveFactor was called at four sites across
  both deleted paths yet defined NOWHERE in the repository - the
  legacy paths were broken, not merely redundant (direct confirmation
  of the original code-quality concern that started this rewrite).
  Suite identical after removal: 10 tests, 109 assertions, 0 failures.
  Open API decision flagged: SimplifyHardCoefficients now has no
  in-repo callers.

- Rationalized coefficient variables LANDED (19:45, Opus agent,
  reviewed): the root-lift Cancel wall is gone from the finite-field
  path. Substitutions xa->xia^2, xb->xib^2, s->2q^2, x->rx^2, y->ry^2
  derived once per run from the card; structural positivity, no
  FullSimplify/Cancel/TimeConstrained on the hot path; evenness checked
  on the small reconstructed coefficients and collapsed back, schema
  unchanged. Fraction roots cancel completely against the Laurent
  factor - only the s/x/y roots reach the trace. Acceptance: NLO UU
  golden unchanged, stored TT and ghost-shared results reproduced
  EXACTLY (new t_rationalized_coefficients, 14/14); suite now 11
  tests / 123 assertions green. The supervised NNLO gluon run - the
  one the old path could not complete - launched 19:50.

- Supervised gluon run on the rationalized path (20:45): the OLD WALL
  IS GONE - normalization of all 45k targets completed (~45 min,
  2203 expression files, 1.2 GB) - but the run failed one stage later:
  RunProcess returned no result for the ratracer trace build (the
  BuildTrace.log contains an unevaluated Lookup - the process never
  launched). Argv is ~375 KB (well under ARG_MAX); prime suspect is
  fork-from-a-multi-GB-kernel failure under WSL2. Reproducing the
  exact ratracer invocation from bash to isolate (and, if ratracer is
  fine, to salvage tonight's trace); the principled fix is a
  normalization checkpoint (Expressions + TraceManifest on disk, trace
  stage resumable in a fresh small kernel) - stage separation again.

- Trace-stage debugging arc (01:00-07:00) and a process lesson (user
  called it out, correctly): the ratracer launch failure went through
  one wrong theory (fork-from-big-kernel; the checkpoint machinery it
  motivated is still valuable) before the 10-second echo test proved
  the real cause - Mathematica's RunProcess cannot pass ~4400
  arguments (100 fine, 4400 returns no result) - and a 60-second
  manifest probe found the checkpoint restore path bug (FileNameJoin
  concatenates on absolute components). Both fixes are one-liners;
  several expensive gluon invocations were burned that cheap isolated
  tests would have avoided. RULES ADOPTED: a driver relaunch is the
  last step, never the test - unit-test the failing stage against
  on-disk state first; use the ghost grid or MaximumTargets subsets
  as the NNLO-shaped smoke test for coefficient-stage iterations.
- Invocation 5 (06:40-): checkpoint restored, 302 MB trace built via
  BuildTrace.sh, FireFly reconstructing (13 cores, 5.5 GB RSS).

- Historical finding (user question, 2026-08-11): the NNLO rational
  reconstruction was NEVER completed before. The frozen tree's record
  (Codex/ppHX_NNLO_DoubleReal/FiniteFieldReconstruction/
  Overnight_2026-08-09) contains exactly two single-master feasibility
  probes (master 0064: full column pipeline with certificate and
  independent verification, ~63 s FireFly; master 0185: trivial); the
  6-10 h figure in the documentation was a symbolic-path
  extrapolation. The current shared-trace run is the first full-set
  NNLO reconstruction attempt - which is also why the RunProcess argv
  ceiling and the root-lift Cancel wall were never seen before: this
  code path never ran at this scale.

- Shared-vs-split reconstruction experiment (user suggestion, 10:00):
  on the ghost set, sequential per-master-column FireFly (162 s) is on
  par with the shared trace (179 s), but the time is dominated by two
  hard columns and the split is embarrassingly parallel with free
  per-column progress. Since each shared-run probe evaluates the full
  302 MB trace while a column trace is ~50x smaller, a SPLIT GLUON
  RACE was launched on the spare cores (2 niced jobs x 3 threads over
  all master columns; shared run untouched at 13 cores): first to
  finish wins; split outputs are format-compatible by concatenation.

- Split race verdict at gluon scale (14:36): OPPOSITE of the ghost
  result - gluon column 1 alone consumed ~12 core-hours at 587k
  FireFly probes without converging (ghost's hardest column: ~2k
  probes). Probe sharing is exactly what the shared trace buys, so the
  shared run is the right design at this scale; race killed, cores
  returned. IMPORTANT STRUCTURAL FINDING: the probe counts are
  inflated by the root-variable substitution - the reconstructed
  values are even in (sq, rx, ry), but FireFly probes the black box in
  the root variables themselves, so effective polynomial degrees are
  DOUBLED relative to (s, x, y). A future degree-halving optimization
  (probing in even variables) would cut probe counts massively; design
  item queued. No ETA is derivable for the shared run (~95 core-hours
  so far; FireFly's remaining probe need is unknowable in advance).

## Day summary (2026-08-10, end of autonomous session)

**Per-stage performance vs historical (requirement: at least as fast):**

| Stage | Rewrite | Historical | 
|---|---|---|
| NNLO pair generation (1296) | 35 min / 6 subkernels | 4 h 15 m / 8 subkernels |
| Canonicalization (new) | 27.5 min (replaces in-reduction search) | - |
| Kira solve (374 fam / 45k targets) | 1 h 58 m / 8 workers | ~2.5 h / 12 workers |
| Streaming import + closure | 12.6 min, peak 7.9 GB | OOM-killed at 47.7 GB |
| Ghost coefficients (2451 targets) | 34 min | - |
| Gluon coefficients (45k targets) | BLOCKED (root-lift Cancel wall) | est 6-10 h (symbolic path) |

**The one red item:** NNLO gluon master coefficients. Root cause fully
diagnosed (16:00 entry): the PositiveMonomialRoots lift's mandatory
final Cancel of multi-MB root-lifted rationals does not scale. The fix
is architectural and already planned: rewrite item 4 (rationalized
card kinematics) makes hadronic substitution root-free by
construction. Needs a card-variable design decision from the user.

**Everything else is landed, tested, and pushed** - see the dated
entries above; every landed item carries its test. sigma_gg assembly
is one function call away once gluon coefficients exist
(AssembleCutContributions, tested; ghost ingredient ready on disk).

**Prioritized open list:** (1) item 4 rationalized kinematics -
unblocks NNLO coefficients, wants user input on variable choices;
(2) gauge/known-result numeric check; (3) old-vs-new NNLO reduction
cross-validation through the canonical registry; (4) dead-code
removal (item 6); (5) dimensional-shift benchmark (item 5); (6) TT
golden; (7) legacy Codex test migration; (8) items 8/9 remainders.

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
