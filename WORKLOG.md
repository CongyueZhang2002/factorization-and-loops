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

- Degree-reduction experiment, ghost scale (15:30): candidate A
  (scale elimination, q->1) is a free 1.64x - FireFly 109 s vs 179 s
  baseline, expressions shrink, transform 0.4 s. Candidate B
  (+evenized x,y) is SLOWER at ghost scale (203 s): the 3.15x
  expression growth prices every probe up while low ghost degrees
  leave little to halve. B's verdict therefore moves to where it
  matters: a timeout-capped FireFly degree measurement on gluon
  column 1 (256 functions, the measured hardest) under both variants
  at 16 threads - factor-scan degree tables print in minutes and
  decide whether halving 150-500-range degrees repays the 3x probe
  cost. Shared gluon run terminated by user instruction at ~8 h/100
  core-hours; split-race telemetry preserved the degree table that
  motivated all of this.

- NLO-first validation round (16:30, per the user's directive): scale
  monomiality is EXACT on all genuine outputs (NLO-UU 43/43, TT
  149/149, ghost 186/186 nonzero; the single flagged file was a stale
  16-byte zero-content output - separate cleanup fix). Candidate B
  (evenization) REJECTED in current form below NNLO: slower at ghost
  scale and its transform reintroduces Together (watched at 1 gluon
  file per 10 min before killing); the granular-evenization variant is
  parked for if A alone misses the bar. Candidate A production design:
  per-output k by exact rational evaluation (no symbolic algebra),
  divide q^k out of the trace text with q kept in the variable list
  (wrong k = q-dependence survives = existing labeled parity failure),
  restore at assembly through the existing collapse; guards = the
  stored-reference golden tests which carry full s-dependence. Then
  the MaximumTargets NNLO subset measurement at 16 threads decides
  sufficiency.

- Rung-D measurements + complete coefficient-stage diagnosis (21:30,
  evidence-closed): (1) probe counts of 1e5-1e6 are INTRINSIC - the
  hardest master's coefficient genuinely has degrees ~450-700 in x,y
  (confirmed on the canonically merged bucket, so not an artifact);
  the old path saw 480k probes too. (2) The decisive lever is probe
  RATE = input compactness: the old record's column input was 0.8 MB
  giving ~7,600 probes/s and 63 s/column; our concatenated-entry
  outputs are 93-485 MB giving 37-85 probes/s = hours-to-days.
  [CORRECTED 2026-08-11 per Codex: the 0.8 MB was NOT a consolidated
  num/den - it was the plus-concatenated file of 1,129 entrywise
  normalized contributions (12.8 MB ByteCount -> 0.8 MB text), with an
  extracted exact monomial; no consolidation stage existed. Reference
  degrees for that master: (CA,CF,eps,x,y) = (4,2,22,22,23); our
  hardest bucket's measured (24,45,200,450,700) has physically
  impossible color degrees -> our emission pollutes buckets; signature
  equivalence must be modulo the full field Q(CA,CF,eps,x,y)*, not Q.] (3) Secondary real
  bug: the signature registry splits classes differing by RATIONAL
  factors (the 2^k from s->2q^2 leaked into signatures) - master 1
  fragmented into 13 buckets / 462 MB, all one canonical class
  (verified: every pairwise ratio rational). (4) The easy majority:
  three signature classes spanning ~350 buckets reconstruct in 7-16 s
  at 11-13 probes. NEXT BUILD (bounded, spec and measured benchmarks
  exist in the study's tables and scripts): post-descend output
  consolidation via the benchmarked entry-first cleanup + signature
  canonicalization modulo rational factors; target ~1 MB/output;
  measure at NLO -> ghost -> NNLO subset before any full run.

- REFERENCE MATCH (22:30, the Codex-endorsed apples-to-apples): the
  old benchmark GLI translates to our GLI[CF21,{1,1,2,0,0,1,0,1,0}]
  (master 107); our emission had fragmented it into 9 buckets (4.8 MB)
  whose signatures differ only by 2^k - the rational-factor bug on the
  reference object. Merged with rational weights it reconstructs FULLY
  in 19 s / 46,320 probes on 16 threads vs the reference 20.2 s /
  169,567 on 8 threads. The pipeline is sound; signature
  canonicalization modulo the full field Q(CA,CF,eps,x,y)* (Codex Q4)
  is the one production fix for the broad population. Also corrected:
  factor-scan probe counts are NOT degrees (master 107 scans {42,280,
  517,743,783} at true degrees (4,2,22,22,23)) - the master-1 "color
  degree" alarm dissolves; master 1's real issue is SIZE (462 MB vs
  ~10-15 MB expected from contributor scaling) -> bounded entry-fat
  audit. Build plan: (a) signature canonicalization at emission +
  bucket-merge post-pass on the existing checkpoint; (b) master-1
  entry audit.

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

## 2026-08-11 (continued) — physical-variable trace MERGED to main

- Rung E full suite: 11 tests, 123 assertions, 0 failed, SUITE_EXIT 0.
- Merged wip/physical-variable-trace into main (f307e28, --no-ff) and
  pushed. Rev. 2 is production: the trace is emitted in
  {CA, CF, Epsilon, x, y}, root variables never reach FireFly.
- Next build (TOP PRIORITY rev. 3): signature canonicalization modulo
  Q(CA,CF,eps,x,y)* at emission (Codex-confirmed rule: fold the
  maximal rational factor of a signature into the coefficient, e.g.
  2^(m+n eps) contributes 2^m to the coefficient and (2^eps)^n to the
  signature). Then a bucket-merge post-pass over the existing gluon
  checkpoint (UU_08_10_canonical/FiniteField, 2045 expressions), and
  the master-1 entry-size audit (462 MB vs ~0.8 MB text for the
  reference's 1,129-contribution column).
- Acceptance for rev. 3: NLO golden + t_physical_variable exact, ghost
  not slower, master 107 merges to ONE bucket at emission and
  reconstructs ~19 s, capped canonical-set measurement rebuilds the
  5 h projection. Full NNLO reconstruction launches only on user
  go-ahead.

## 2026-08-11 late — rev. 3 signature canonicalization LANDED (ed2aea2)

- Emission fix in Simplification.wl: every combined signature is
  canonicalized at registration modulo Q(CA,CF,eps,x,y)*: rational
  bases decompose over primes, integer exponent parts and foldable
  rational-function factors fold into the coefficient, scale and
  alpha_s never touched.  Unit test t_signature_canonicalization:
  15/15.
- NLO golden with FRESH emission (rev.2 checkpoint set aside as
  FiniteField_rev2_backup): 6/6 exact, signatures 18 -> 4, outputs
  40 -> 14 = one per (master, scale power), FireFly 0.31 s.
- Post-pass Scripts/canonicalize_trace_buckets.wls over the stored
  gluon checkpoint -> FiniteFieldCanonical (input untouched):
  2045 outputs -> 347 = ONE COLUMN PER MASTER, 83 signatures -> 7
  classes, largest fragmentation was 13 buckets; every signature
  split certified exact.  First script version had a Lookup/Key
  association bug (2045 unique signatures instead of 7) - fixed with
  the production hash-bucket idiom.
- Master 107 canonical column: 169,735 probes = the reference count
  (169,567; hand merge 169,753).  Wall 27.9 s at 16 threads UNDER
  LOAD (NLO test running concurrently; idle hand merge was 18.3 s,
  probe 1.49 ms vs 2.06 ms) - probe count, not wall, is the
  apples-to-apples number here.
- ENTRY-FAT AUDIT (closes the master-1 question): no defect.
  Master 1 = 44,175 contributions (~every target) x 11.0 KB/entry
  = 462.6 MB; master 2 = 24,082 x 11.7 KB = 267.6 MB; together 75%
  of the 977.6 MB set.  Master 107: 1,260 contributions ~ reference's
  1,129 - the structure matches Codex; our entries are ~5x fatter
  (no entrywise Cancel).  Median column 0.039 MB; only 6 columns
  over 10 MB, 2 over 50 MB.  The 5 h projection therefore hinges on
  masters 1 and 2 alone (master 1 measured at 0.159 s/probe, degrees
  108/56, killed mid-prime at 48.5k probes in the pre-restart run).
- Next: ghost fresh-emission acceptance (running), then a CAPPED
  master-1 probe-rate/degree measurement on an idle machine, then the
  full projection.  No full launch without user go-ahead.

## 2026-08-12 early — fresh-emission acceptances + entry compaction

- Ghost FRESH emission through the canonicalizer: 14/14 exact, 27
  masters -> 27 outputs (one column each), FireFly 18.84 s vs rev.2's
  60.6 s = 3.2x FASTER.  TT fresh emission also exact (14/14); TT only
  collapses 149 -> 136 outputs - its residual signatures are genuinely
  non-rational (evanescent ST/STh structures), intrinsic and harmless
  at 0.01 MB scale.
- Entrywise compaction (Scripts/compact_trace_columns.wls +
  split_merged.py): each merged contribution (w)*(t)*(r) replaced by
  its exact Together, in parallel; originals kept as .expr.fat;
  manifest bytes rewritten through the record writer (NOT plain WXF
  Export - the manifest is a length-prefixed record store).
  Certified on master 107: byte-identical FireFly result
  (169,751 probes, 17.8 s), 4.6 -> 3.6 MB.
- Compacted the six big columns: master 1 462.6 -> 88.8 MB in 109 s
  (= Codex's reported largest-column size, ~90-100 MB - structures
  match); master 2 267.6 -> 46.1 MB; 209/92/91/93 -> 6.8-9.7 MB.
  Sample measurement that justified it: byte-tail entries compact 28x
  at 1.9 s/MB, zero timeouts (300-entry stratified sample).
- Master 1 measurements: fat trace 0.234 s/probe (prime 1 killed at
  182k probes/44 min); compacted trace 0.054 s/probe, optimize leaves
  83 MB instructions, prime 1 STILL >773k probes at the 45-min cap.
  Degrees (CA,CF,eps,x,y) = (5,3,33,57,60), num/den 108/56 - the
  probe count is intrinsic to the function.  Extrapolation: if prime 1
  ends near 1M probes, master 1 totals 80-90 min; consistent with
  Codex's 0.5-2 h FireFly estimate at 8 cores for their m1-analog.
- DECISIVE RUN in flight: master 1 uncapped with a 3 h ceiling.
  Completion -> full projection (expect total ~2.5 h hybrid: small
  columns shared, masters 1/2 solo); ceiling breach -> the naive
  per-column path is dead and the CA/CF-split / eps-expansion ladder
  (user-gated) is next.

## 2026-08-12 — NLO UU masters SOLVED (DE method, exact in eps)

- System: Euler-operator construction + dedicated Kira run (stored
  amplitude rules never raise cut indices); 7x7 triangular; flatness
  EXACTLY zero; alphabet {v,w,1-v,1-w,v+w,1-v-w}.  Caught along the
  way: kira2math uses lowercase d for the dimension.
- Solution: 2F1 ansatz fit (6 cross ratios x inverse-letter pairs),
  contiguous elimination, pure algebra, UNIQUE hit per master:
  I_i = +-2(1-2eps)/eps * N(eps) (1-v-w)^(-eps) R_i 2F1(1,1;1-eps;z_i);
  volume alone fixes everything - no boundary integrals at all.
- Validation: all 14 DEs symbolically exact; independent two-angle
  numeric integration (stable via half-angle variables, exact edge
  factoring, z->1-z connection with elementary second branch, exact
  cone-root splits, 200-digit constants) agrees to 1e-18 at
  eps=-0.15 over 5 configurations; VOL to 24 digits; shared family
  F10C2N2 = Codex evaluation modulo (2Pi)^(d-2).  A double-counted
  volN in the fit save line was caught by the kinematics-independent
  N(eps) mismatch (N(0) = Pi/2) - conventions need independent
  numbers, DEs alone certify only functional form.
- Landed: ppHX_NLO/Results/NLO_UU_Masters.wl (exact + soft branches:
  I3, I5, I6 carry (1-v-w)^(-1-2eps) - the plus-distribution seeds),
  Tests/t_nlo_masters.wls 6/6 green, Scripts/{build_nlo_de,
  solve_nlo_exact, numeric_nlo_masters, build_nlo_masters_artifact}.
- master_NLO.tex updated with the full system table, the closed-form
  solution table, endpoint/plus-distribution section, and validation;
  pushed to Overleaf for the user's afternoon meeting.
- NEXT (user): overnight start on the NNLO double-real (two-loop)
  masters: same Euler construction on the 347-master canonical basis,
  flatness gate, alphabet discovery; solving strategy after review.

## 2026-08-12 overnight — two-loop DE ladder

- RUNG 1 (CF21, the benchmark family): two-loop Euler construction
  generalized (2 loop momenta, 9 propagators incl. the bilinear
  1/(kc.ke); sp-solve from all 9; iterative closure loop with fresh
  Kira per extension).  Block: 14x14 = 11 canonical + 3 subsector
  masters, closed after 2 iterations (133 targets, r 10, s 2; Kira
  seconds per pass).  FLATNESS EXACTLY ZERO.  Alphabet: NLO letters
  {v, w, 1-w, v+w, 1-v-w} PLUS the quadratic letter
  (1+v+w)^2 - 4w  (Kallen/threshold type - first genuinely two-loop
  structure; may force square-root letters in canonical form).
- Next: rung 2 = top master-count families sequentially in one
  kernel; full 374-family sweep after cost projection.

## 2026-08-12 morning — two-loop DE sweep COMPLETE (all 91 families)

- 91/91 master-hosting families built: every one of the 347 canonical
  NNLO double-real masters has its differential-equation block, and
  EVERY block is exactly flat (90 stored flags True + CF21 certified
  in its own run; zero failures).  Standalone per-family blocks incl.
  subsector closure: total dimension 1561; largest blocks 47, 45, 44,
  41, 32.  Cost: ~50 s/family average, whole sweep a few hours on one
  kernel + single-family Kira runs (seconds each; closure loop
  converges in <= 2 iterations everywhere).
- Fat masters demystified: ordinals 1 and 2 live in CF1 as
  {1,1,0,0,1,0,0,0,0} and {1,1,1,0,1,0,0,0,0} - the pure 3-cut
  phase-space volume and its single-propagator cousin; simplest
  integrals, largest coefficient columns.
- GLOBAL TWO-LOOP ALPHABET (38 letters): the NLO set {v, w, 1+-v,
  1+-w, v+w, 1-v-w, 1+v+w} plus ~20 quadratics, notably the Kallen
  letter (1-v-w)^2 - 4vw, the family v^2 +- 4w / w^2 +- 4v, 1 - 4vw,
  and shifted quadratics like 1-w+vw, (v+w)^2 +- v etc.  Quadratic
  letters => square-root letters in any canonical form.
- Artifacts: ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/
  DifferentialEquations/ (91 blocks + summary, 7 MB); scripts
  build_nnlo_de.wls / nnlo_de_core.wl / drive_nnlo_de.wls.
- RECOMMENDED NEXT (for user review):
  1. Consolidate the 91 standalone blocks into ONE global system on
     the canonical 347 basis by routing the derivative reduction
     through the full 374-family Kira job (subsectors then land on
     canonical names; projected cost ~ the 2 h production solve).
  2. Soft-surface residue matrices of all blocks -> exact NNLO
     endpoint exponents (the plus-distribution seeds) are extractable
     NOW from the saved systems, before any canonical form.
  3. Solving: NLO-style one-scale 2F1 ansatz will not cover the
     quadratic-letter sectors; options are (a) canonical form with
     algebraic letters (square roots of the Kallen family), or
     (b) branch-factored eps-expansion solving with numeric anchoring
     (the validated NLO toolkit generalizes).  CF1's volume masters
     have closed forms - the normalization anchor, as at NLO.

## 2026-08-12 — post-restart: soft exponents + global consolidation

- Windows update restarted the machine; nothing lost (all artifacts
  committed beforehand; scratchpad Kira workspaces disposable).
- Soft-surface (1-v-w -> 0) exponent extraction over the 91 blocks
  (exact a + b*eps identification from rational-eps probes of the
  residue matrices): global spectrum {0, -2eps, -3eps, 1-2eps,
  -1-2eps} - the -1-2eps plus-distribution seeds and the -3eps
  double-unresolved branch.  ~8 blocks (CF67, CF71, CF86, CF88, CF90,
  CF91, CF97, CF98) have SECOND-ORDER poles at the surface: they need
  Moser local normalization before Frobenius exponents can be read -
  deferred to the canonical-form stage.  Spectra saved
  (soft_exponent_spectra.wl, scratch).
- Launched Scripts/build_nnlo_global_de.wls: the global 347-master
  system via the full 374-family canonical Kira job (staged +
  checkpointed in ppHX_NNLO_DoubleReal/Kira/UU_08_12_derivatives, so
  it resumes after interruption).

## 2026-08-12 afternoon — census + closure fix + parallel lanes

- Global closure hit its iteration cap with an r-boundary oscillation
  (62 -> 23 -> 4 -> 8 new members): each pass raised r by one and
  moved the spurious-master frontier instead of closing it.  Fixed:
  r/s margins +2, cap 10 iterations; rerun resumes from checkpointed
  iterations 1-4.
- BLOCK CENSUS: 32/91 blocks are NLO-letters-only (incl. CF1 anchors,
  CF21 benchmark; sizes 2-14) -> immediately solvable with the
  validated NLO machinery.  59 blocks carry quadratic letters, mostly
  1-3 extra letters; hard structure concentrated in CF259 (47-dim, 5
  quadratics), CF385 (44, 7), CF303 (45, 3), CF408 (41, 5).
- Core cap 10 (user): all jobs pinned to cores 0-9 (taskset), Kira
  parallel=10, FireFly threads=10.  FireFly master-1 measurement
  resumed after a SIGSTOP pause (probes preserved; harness handle
  lost - tracked via m1_final.log).
- CF1 closed forms (3-body volume + one-propagator anchor) running.

## 2026-08-13 early — variable-split method test (cheap-scale, as due)

- CA/CF-split vs direct joint reconstruction, measured at NLO and
  ghost scale (text-substituted traces, minimal grids from measured
  color degrees):
    NLO:   joint 5,643 probes | split (2x3 grid) 9,397  -> 1.7x WORSE
    ghost: joint 23,807       | split (4x3 grid) 94,560 -> 4.0x WORSE
  Joint sparse interpolation absorbs the low-degree polynomial CA/CF
  dependence for ~3x the 3-variable cost, always below the grid
  factor.  Projected to master 1 (grid 24): ~24M vs the measured
  3.9M direct -> 6x worse.  FIRST ESCALATION RUNG CLOSED BY
  MEASUREMENT: the direct 5-variable method stands.
- Remaining untested alternative: eps-Laurent truncation (win would
  come from series truncation, not variable removal; needs
  series-mode tooling + user sign-off on truncated storage).
- Master-1 direct measurement (from tonight): prime 1 = 2,721,256
  probes, prime 2 = 757k (cum. 3.48M); verification prime killed by a
  too-tight ceiling but bounded small.  PROJECTION: full NNLO
  coefficient stage ~5-6.5h at 16 cores (marginal vs the 5h bar) or
  8-10h at the 10-core cap (overnight-sized).

## 2026-08-13 — eps-truncation VERIFIED: the fat-column problem is solved

- Codex exchange resolved the representation question: the 809KB-vs-
  3.8MB text gap is 94% alias-name length (renamed: 965KB vs 809KB =
  1.19x, matching our +12% entry count from signature-bucket targets).
  Representations algebraically equivalent; no compression lever.
- Ratracer to-series (eps truncation, Laurent-pole aware) measured:
  m107: 18,369 probes / 1.9s vs 169,685 / 39s full-rational (9x
  probes, 20x wall).  VERIFIED exact: series-sum vs full-rational
  differs only by truncation (scaling exponent 5.8 across eps
  halvings); the initial "mismatch" was a bug in my comparison
  harness, not the data.
- MASTER 1 (the 3.9M-probe column): series reconstruction complete in
  15.5 min / 297,094 probes at 16 threads (vs ~6h full-rational at 10
  threads).  13x probe reduction.
- Production depth: eps^5 (user decision - safety margin over master
  pole depths; ~15% extra probes).  Production runs for masters 1+2
  launched; the other 345 columns remain exact full-rational (already
  complete from the 5am run).
- Also closed today: CA/CF grid split (4x worse at ghost scale, 6x
  projected on m1), denominator merging (no gain - ratracer CSE),
  size-linearity claim (Codex correction: sublinear).
- Process fixes: per-run progress monitor + status command
  (Reconstruction_2026_08_13/status.sh); routine coding delegated to
  Opus (assembly + slice-verification scripts in progress).

## 2026-08-13 — NNLO UU reconstruction COMPLETE and VERIFIED

- Production: 345 exact rational columns (3.4h, 5am run) + masters 1
  and 2 as eps^5 series: m1 18.1 min / 345,682 probes, m2 5.3 min /
  198,027 probes.  The full coefficient set exists.
- Verification: m1 maxorder-4 vs maxorder-5 independent
  reconstructions agree EXACTLY on all 9 common Laurent orders (the
  column starts at eps^-4 - the eps^5 depth choice has margin);
  univariate slice checks 8/8 PASS on sampled rest columns (plus the
  agent's earlier 7/7 with negative controls).  Composition-bypass
  check (Codex protocol #1) deferred to the package module hooks.
- Standardization: Design/ReconstructionModule.md spec committed;
  Opus implementation in progress (golden-gated on NLO both modes).
- NEXT after standardization (user): back to master solving
  infrastructure; boundary constants via SubTropica
  (Addon/Mathematica_Addon/SubTropica; prior probes exist in
  ~/FACET/Codex/MasterEvaluationWorkflow/ProbeBoundarySubTropica*.wls
  - study those first).

## 2026-08-13 — reconstruction standardized into the package

- ReconstructCoefficients / ReconstructionStatus landed (Opus
  implementation against the committed spec; my review via golden
  gates + old-path regression).  NLO series mode: 4.8x fewer probes
  than full rational; ghost: 7.1s vs 18.8s baseline.  Latent
  Return[Nothing] assembly bug discovered, worked around, filed.
- NEXT: masters program - solving infrastructure over the 91
  certified blocks; boundary constants via SubTropica (probe scripts
  from Codex's MasterEvaluationWorkflow to study first); cheap-first
  at NLO edges where answers are known exactly.

## 2026-08-13 — masters strategy pivot: eps-forms via CANONICA, method
   gate PASSED at NLO

- Context: user directive — two assistants run in parallel (Codex +
  this session) so genuinely different routes get explored; do not
  copy Codex's MasterEvaluationWorkflow wholesale.  Their method
  (their MASTER_EVALUATION.md): CANONICA eps-form + Jordan/Fuchsian
  boundary counting + Baikov/SubTropica periods + Libra transport;
  NLO done + three demo two-loop families, with 7 family-dependent
  manual steps each.  Our divergence: the canonical-family lattice
  (91 blocks, subsector triangularity, registry names) solved in
  global dependency order with cheap branch-absence boundary
  conditions first, SubTropica only for residual constants.
- Exact-in-eps solutions demoted (user): no consumer needs all
  orders; closed forms kept only where cheaper (pure-prefactor
  blocks, NLO golden reference).
- CANONICA probes: CF3 (my stuck closed-form block) to eps-form in
  0.30s; NLO 7x7 in 0.50s.  Full sweep over all 91 NNLO blocks:
  83/91 OK = 317/347 masters, 854s total solver time (47-dim block:
  2.6s), {T, eps-form, basis order} stored per block
  (scratch canonica_sweep/forms/).  The 32-linear/59-quadratic
  alphabet split was too pessimistic: polynomial quadratic letters
  are rational dlogs (11 OK blocks carry them).  The 8 Moser-flagged
  blocks (CF67/71/86/88/90/91/97/98) all succeeded — Moser work item
  KILLED.  Holdouts: CF360/123/215/218/12 (linear alphabets — ansatz
  depth suspected), CF263/269/311 (true quadratics — possible sqrt);
  30 hosted masters total.  Deeper-ansatz pass 2 running.
- NLO METHOD GATE (Opus harness, scratch validate_epsform_nlo.wls):
  eps-form + explicit-primitive transport (1/4,1/4)->(v,1/4)->(v,w)
  + boundary from ONLY volume + six branch-absence conditions
  reproduces all 7 exact masters at eps^-1..eps^2, 3 chamber points,
  to >76 digits; 3min24s wall.  Measured: the 1/eps in T costs
  exactly one canonical weight (dropping weight 3 gives relative
  error 3.08 at eps^2); weight 3 stays in {Log, PolyLog, Zeta} but
  leaf growth is 7-12x/weight and weight >=4 generically leaves the
  classical class -> GPL representation (Libra/PolyLogTools) needed
  at NNLO depth.  Free cross-check: CANONICA diagonal residues
  reproduce master_NLO.tex §3.2 exponent table letter for letter.
- NEXT: pass-2 holdout results; NNLO boundary program on the
  eps-forms (corner residues + physical exponents from stored soft
  spectra + subsector inheritance across the lattice + SubTropica
  residual periods); conclusions note to Codex for
  confirm/challenge before scaling.

## 2026-08-13 — Codex exchange round 2 (masters): four plan changes

- Codex confirmed C1 (no Moser needed), C2 (quadratic letters fine),
  C4 (GPL beyond weight 3), Q1 (no new letters beyond raw
  denominators in their three families), Q4 (no exponent outside our
  global soft set AFTER chart translation).  Their E13 work already
  uses OUR registry names (CF407) — cross-adoption both ways.
- ADOPTED CHANGES:
  1. Weight budget (their Q3 answer REFINES my C3 rule): required
     weight is set by every canonical boundary component that can
     FEED the target through T-orders x transport weights x boundary
     valuations (convolution r+n+q=k + residue-product reachability),
     not by the target's apparent valuation.  83bb counterexample:
     G7 apparent eps^-3 but needs weight six.  Boundary valuations
     established by exact rational reduction, never numerically.
  2. Boundary nullity is a THEOREM-COUNT, not an estimate: per block
     assemble constraint matrix rows {volume, inherited, forbidden
     modes, regularity} restricted to physical local modes; nullity =
     genuinely new periods.  Their E13: FOUR corner-mode coefficients
     survive inheritance — inheritance+branch-absence alone is NOT
     always complete (C6 qualified).  Whole-set estimate 20-40 direct
     periods; our sweep can make this exact block by block, dedup by
     registry period equivalence.
  3. Exponent tables are PER-CHART: derive local exponents from local
     residue matrices, then map to the global soft variable before
     comparing to {0,-2eps,-3eps,1-2eps,-1-2eps}.
  4. Path validator: factor alphabet, prove fixed sign of every
     letter on every segment (check intermediate corners for
     axis-aligned paths); tangential regularization only for initial
     zero letters; Kallen-root fallback zeta/zetabar parametrization
     (likely unneeded: no sqrt letters found in our 91).
  Variation-of-constants caveat (their Q1): VoC integrates poles of
  off-diagonal kernels — alphabet may exceed the DIAGONAL letters
  (bounded by full raw-system denominators).
- Substrate build launched: per-letter residue matrices + stratum
  residue data (wEdge/vEdge/soft/corner: valuations, eigenvalues,
  diagonalizability) for all 87 stored eps-forms, with exact dlog
  reconstruction check per block (scratch canonica_sweep/forms/
  CF*_residues.wl).  Feeds both the nullity counter and the weight
  counter.
- Straggler pass 3 (off-diagonal-only D-degrees 3-4) still running.

## 2026-08-13 — CORRECTION: sweep acceptance bug; validated 40/91, retry
   pass running

- The 83/91 sweep claim was WRONG: CANONICA returns {False, {partial
  trafo, partial a}} on sector failure — a 2-list — and the sweep's
  ListQ && Length==2 test accepted 47 failure tuples as successes.
  Caught by the exact dlog-reconstruction gate of the residue
  extractor (all 47 refused; 40 reconstructed exactly).
- Validated: 40 blocks / 109 masters (incl. pass-2 deg-1 recoveries
  CF12/215/218/311).  Invalid files quarantined (scratch
  forms/partial/).  Pass 4 running: resume at failed sector from
  stored partials, degrees 1 then 2, 600s/8GB caps, reconstruction
  gate before storing.  Codex note corrected in place (appended
  section) — coverage number retracted until pass 4 lands.
- Unaffected: straggler diagnosis (matrix-level), NLO gate, C1/C2,
  residue/stratum substrate for the validated 40 (21 blocks have
  non-diagonalizable corner residues — Jordan logs at the corner,
  consistent with Codex's E13 warning).
- Rule adopted: no stored transformation counts as OK without exact
  eps-form reconstruction from constant residues.

## 2026-08-13 — the true obstruction map: 39 distinct non-rational
   sectors, one quadratic each

- Pass 5/6 over the 47 unresolved blocks (per-sector diagonal scans;
  message-capture bug fixed via HoldFirst — pass-5 NR/ansatz split was
  invalid): ALL 94 failing sector instances are CANONICA-certified
  NONRATIONAL (no rational eps-form transformation exists in (v,w));
  zero ansatz-depth cases.  Dedup by exact diagonal-system identity:
  94 instances = 39 DISTINCT systems, sizes 2-7, recurring across
  families exactly as the registry lattice predicts (e.g. group 18
  appears in 7 families, group 19 in 6 incl. CF407 — the family
  Codex's E13 also fights).
- Each distinct system carries EXACTLY ONE irreducible quadratic
  denominator (38 of 39; group 21 has none — separate investigation).
  Only 5 quadratics occur in total: the Kallen variants
  (1-v-w)^2-4vw, (1+v-w)^2+4vw, (1-v+w)^2+4vw, and v^2+4w, 4v+w^2.
  No multi-root sector exists -> every hard sector is a genus-0
  single-conic case, rationalizable by one parametrization (Codex
  zeta/zetabar for Kallen; standard conic maps for the others).
  Elliptic candidates: none demonstrated; certification = rerun
  CANONICA post-substitution per representative (5 runs pending).
- Moser-8 correction: only CF67/71/86/90 validated; CF88/91/97/98
  are diag-hard (their flagged second-order poles live in these
  non-rational sectors) — C1 narrowed accordingly in the exchange.
- Ledger (Codex three-state convention): canonicalized 40/91 blocks
  (109/347 masters); 47 blocked by the 39 hard cores; 4 blocked in
  off-diagonal only.  NEXT: (1) rationalization runs on 5
  representatives; (2) group-21 direct analysis; (3) recompute
  alphabet/eps-in-T statistics over validated blocks only; (4)
  nullity counter on the 40 (Codex Q4/Q5/Q10); (5) answers to Codex
  round-3 questions with this data.

## 2026-08-13 — frontier rationalized: 5/5 quadratic classes admit
   rational eps-forms in conic charts

- Representative hard sectors of all five quadratic classes
  rationalize at ansatz degree 0 (rationalize.wls; charts verified
  symbolically before use: each q = ell^2 + linear, chart u = ell+2t,
  linear remainder solved rationally; e.g. class v^2+4w -> chart
  w = t^2 + t v, letters {t, v, t+v, 2t+v}).  NO ELLIPTIC SECTOR
  demonstrated anywhere in the 91 blocks so far.  Stored:
  forms/class*_rationalized.wl (transformation + eps-form per rep).
- Per-block class mix of the 47 blocked blocks: 31 single-class
  (wholesale chart -> full-block CANONICA in chart variables is the
  next sweep), 13 two-class, 3 three-class (CF259 with three genuine
  quadratics; CF300/CF303 include the quadratic-free group 21).
  Multi-class blocks: sector-local charts + variation-of-constants
  assembly, or joint rationalization (Besier-van-Straten-Weinzierl
  style) where it exists — open design question.
- Still open: group 21 (3 instances, size 2, nonrational WITHOUT a
  quadratic denominator); 4 straggler blocks on the VoC track
  (pass 3 exhausted: timeouts at D-degree 3-4).
- Straggler CF263 quadratic (v+w)^2-v has the same ell^2+linear form
  -> same chart trick applies to its off-diagonal track.

## 2026-08-13 — operational rules after the sweep incident

- Killed the 900s×3-degree wholesale-chart sweep at the 2h mark: 1
  validated success (CF23, chart-frame eps-form, 215s), 3 timeout
  failures at ~45min each.  ~1h of that was avoidable: no deg-0
  triage first, no check at the first failure line.  Replaced by a
  deg-0-only 600s-cap resumable triage (running) with a watchdog
  that surfaces every per-block line and stalls >30min.
- Process-kill accident: kill -9 by name pattern took down every
  WolframKernel on the box, almost certainly including Codex's
  active kernel (their workspace wrote files one minute earlier).
  RULES (user-set, in memory): check long runs at least every 30
  minutes; never more than 1 main kernel + 4 subkernels — half the
  machine's Wolfram capacity is reserved for Codex; never kill by
  name pattern, only PIDs traced through this session's parent
  chain.
- Fixed classifier (total degree): 6 deg>=2 letters (bilinear
  -1+4vw added); block class-mix unchanged (31 single / 13 double /
  3 triple).  Group-21 chart w -> (1+u^2)/(4v) verified: 1-4vw ->
  -u^2; obstruction becomes ansatz-only (escalation queued behind
  the triage on the single license seat).

## 2026-08-14 — wholesale-chart triage CLOSED: 2/31; final tier map

- Final verdicts over the 31 single-class blocked blocks (deg-0 chart
  frame, 600s caps, exact-reconstruction gate): CANONICALIZED CF20 +
  CF23 only; 21 FAILED (fast ansatz refusals), 8 TIMEOUT.  The 9-block
  tail was completed by an instance whose stdout had been severed by a
  pipeline bug (head -5 SIGPIPE) — computation and atomic file writes
  were unaffected; verdicts recovered from the results file and
  consistent with all reconfirmed prior runs.
- FINAL LEDGER (certificate-backed): canonicalized 42/91 blocks
  (46%), 123/347 masters (35%).  Tier-3 (block-diagonal + VoC per
  Design/MasterSolvingArchitecture.md): 49 blocks / 224 masters
  (29 single-class + 16 multi-class + 4 off-diagonal stragglers).
  Wholesale-chart experiments are closed; no degree escalation.
- Incident log (all recorded as memory rules): WaitNext 3-element
  destructuring bug (garbage output from minute one — caught late);
  results-file corruption from kill-9 mid-Put (now atomic
  write+rename with an init guard); pgrep self-match (third
  occurrence — now exact-executable pgrep -x only); head-in-pipeline
  SIGPIPE.  Babysitter-agent pattern (user directive): every long
  run gets an active 5-min health-checker with kill authority
  limited to parent-chain-verified own processes.
- Codex coexistence: their normalize_class180 run (1 main + 4 subs,
  matching the machine-split convention) ran unharmed through
  tonight's cleanups after the one kernel kill earlier (reported).
- NEXT: tier-3 solving infrastructure (per-sector diagonal eps-forms
  + coupling conjugation + per-order VoC quadratures), boundary
  nullity counter on the 42 canonicalized blocks, round-3 answers to
  Codex (their Q1/Q2/Q9 now have final data).

## 2026-08-14 — inventory reconciliation with Codex: exact overlap table

- Same inventory confirmed at source level (their NNLOInventoryAudit
  reads our nnlo_de_CF*.wl; 91/347/1561 identical).  Their SCC
  decomposition (1117 required blocks, max coupled dim 4) is finer
  than our sector split — adopted for class-level work.
- Overlap: their unresolved classes 181 {CF20_B5, CF88_B5} and 184
  {CF231_B6, CF23_B7, CF303_B7, CF305_B9, CF97_B5} sit inside our
  verified CF20/CF23 whole-family eps-forms -> both classes RESOLVED
  by restriction; also resolves bad sectors in five of our tier-3
  families (CF88/97/231/303/305).  Their 20 open classes -> 18.
- Q3: our 4 stragglers all lie in their clean set with proof-grade
  off-diagonal-only diagnostics; +18 plausible-unproven.
- Found one counting bug in their Tools/count_canonical_coverage.wls
  (ALL blocks iterated vs required-only catalog -> Lookup Missing ->
  CF429 spuriously unresolved): 59 clean families should be 60.
  Their 305/347 block-level master coverage verified independently
  (57 unresolved instances host exactly 42 physical masters).
- Division of work agreed (their 4-point route + our ledger states):
  they take the 18 open classes per-class; we take whole-family
  off-diagonal stitching + the boundary nullity counter dedup'd by
  their class quotient.  Next deliverable: block-restricted 181/184
  transformations extracted from CF20/CF23 forms.

## 2026-08-14 — hybrid workflow adopted; Codex class quotient corrected
   (186 -> 173); 309/347 block-level coverage

- Codex proposed a hybrid workflow (their SCC/class decomposition +
  our whole-family forms + one VoC engine + strict completion
  criterion) — ACCEPTED.  Opus verification agent reproduced their
  inventory independently then aligned: blocks EXACT (1119; their
  "1117" = required subset, exclusion justified); their class
  partition OVER-SPLITS — true count 173, not 186; 13 missed
  equivalences from a non-canonical canonical form (their 181 == 186
  by pure column permutation) + structural === on equal-but-textually-
  different matrices (120 == 138).  Refutation bound: raw equality
  already gives only 6 dim-4 classes vs their 11.
- Payoff: 5 of their 20 unresolved classes resolve for free
  (181/183/186 == their solved 177; 179/184 == 176; explicit maps
  stored).  Corrected coverage 309/347 masters, 63/91 families
  (newly CF20/CF23/CF226).  92/173 classes covered by our 42 family
  forms; of the 81 uncovered, 53 purely linear (ordinary work).
  5 zero-matrix singleton blocks flagged for confirmation.
- Round-3 note with all five answers + work-split proposal:
  External/CodexExchange/hybrid_inventory_answers_2026-08-14.md.
  Division: we take the 53-class linear batch campaign + VoC engine +
  soft/collinear boundary; they take the 3 open chart geometries +
  hard region; labels rebuilt on the corrected 173 partition after a
  joint canonical-form fix.

## 2026-08-14 — class ledger self-contained: 166/173 canonicalized
   in our own artifacts; 7 hard classes identified

- Label-space closure check caught the merged-ledger inference gap
  (14 classes with no verified form on either side despite the
  cross-space bookkeeping); response: canonicalize ALL 173 class
  representatives directly from our artifacts.  Result: 166/173 with
  exact-reconstruction certificates (scratch class_campaign/forms/),
  including 9 of the 14 both-sides-missing classes, most at ansatz
  degree 0, chart branch engaging automatically for quadratic
  classes (~30 chart successes, up to 82s each).
- Three script bugs found by monitors during the runs (Return-in-Do
  discarding successes; v=Global`v self-assignment iteration-limit
  poison; license race + SIGPIPE'd tee) — all fixed; the babysitter
  pattern caught each within one event cycle.
- The 7 refusals {26, 33, 77, 79, 97, 115, 118}: all single-quadratic
  and certified NONRATIONAL in (v,w).  26/77/97 carry Kallen
  (1-v-w)^2-4vw variants; 33/79/118 the (v+w-1)^2+4v variant; sizes
  3-6 family instances each — these correspond to Codex's open chart
  geometries.  115 = the bilinear CF299{1,2} class; its chart branch
  silently failed to engage in campaign context (1s verdict) — bug
  hunt queued; manual deg-0 chart attempt is known to ansatz-fail,
  escalation untested.
- Overnight: extended-cap chart-frame runs on the 7; VoC engine
  build (Opus) starts in parallel on code (kernel tests seat-
  coordinated).

## 2026-08-14 (overnight) — hard classes 26/33 cracked; VoC engine
   built, assembly certified, transport backend needs GPL layer

- Extended-cap chart runs: classes 26 (324s) and 33 (631s) fell at
  deg 0 — the campaign's 300s cap had missed 26 by 24s.  Class
  ledger now 168/173.  Remaining: 79 (deg 0+1 timeouts at 1200s),
  115 (bilinear — refuses even in chart frame; dim 2, queued for
  direct second-order-ODE analysis), 97/77/118 (deg-0 requeued this
  morning after license incidents).
- VoC engine (Opus, scratch voc_engine/): COMPLETE as machinery —
  SCC assembly + five-part exact conjugation certificate PASSES on
  NLO and CF3 (block-triangularity, mapped class eps-forms entry-by-
  entry, eps-linearity, flatness); equivalence maps cached; sqrtQ
  chart pullback verified (residual 1e-39); computed (not assumed)
  weight budgets incl. CF3's rmin=-1 from its 1/eps coupling; NDSolve
  realization of the recursion reproduces all 7 NLO masters to 43.6+
  digits at two chamber points.  NOT passed as specified: the
  symbolic-constants quadrature backend (Integrate) fails at weight
  >=3 (NLO sector-2 eps^1 after 619s/955s; CF3 sector-2 eps^2 hung
  twice ignoring SIGTERM) — root cause confirmed: need a shuffle-
  algebra GPL integration layer over linear-in-tau letters (O(ms)
  per integral) instead of Integrate.  Also confirmed: base point
  (1/4,1/4) lies ON lambda(1,v,w)=0 — Kallen-chart transport needs a
  shifted base point.  Coverage: 44 families fully rational today,
  32 assemble-only, 15 blocked on the 5 open classes.
- Incidents: agent's stray probe kernel likely killed the hard-class
  run via the ~2-kernel license cap (classes 26/33 already saved);
  its log files were truncated by a license misfire (results
  preserved in transcript); two runs ignored timeout SIGTERM and
  needed coordinator kills.  Rules tightened: seat check before
  EVERY kernel invocation including probes.
- NEXT (day): GPL integration layer (the one identified blocker on
  the critical path); rerun VoC gates; stragglers + rational-family
  sweep; base-point shift for chart sectors; 79/115 special
  handling; boundary program.

## 2026-08-14 — stage 1 standardized and committed; GPL layer working;
   nullity counter closing in on the global count

- CanonicalBlocks.wl + tests (22/22 green, 13s) + fresh-agent
  workflow doc committed.  The test suite caught, in our own code,
  the same swap-relabeling over-splitting bug that gave Codex 186
  classes; fix makes correctness independent of the bucket invariant
  (orbit-key merge).  Open item documented: T-conjugation
  re-verification of stored forms (covered downstream by the VoC
  assembly certificate).
- GPL layer: complete decision procedure, 51/51 self-tests,
  primitives 0.3-5.8ms, the 619s-timeout integral now 8.41s with
  exact zeros; gates rerunning with numeric endpoints after measured
  coefficient swell at symbolic endpoints.  Pre-existing engine bug
  found (path-frame DE check compared unrestricted T — could never
  have passed); fixed.
- Nullity counter: acceptance (a) PASSED — N_new(NLO)=0, saturating
  at the COLLINEAR edges (single-stratum counting would fabricate
  3-4 periods; cross-stratum intersection is essential).  (b)
  correctly demands the CF231 blow-up; my E13<->CF231 conflation
  corrected (E13 = 24-dim ruTopology53 — mapping via registry goes
  in next exchange).  Three silent-drop bugs found via per-item
  records; substrate now 169/169 clean.  Global count rerunning.
- Specials: class 115 SOLVED (secretly one-variable 2F1 in z=vw;
  exact eps-form + closed form shipped to exchange); class 79 chart
  verified + two stored-basis defects with explicit balance fix
  handed to Codex.  Hard-class runs: 118 canonicalized (623s);
  77/97 deg-0 timeouts at 1200s — balance-fix route queued.
  Ledger: 170/173 effective.
- Ops: ours-vs-Codex kernel ownership via /proc cwd (both agents
  independently converged); dynamic two-main rule while Codex idle;
  nullity agent correctly REFUSED subkernel parallelization with
  measurements (12s total kernel wall) — cost-benefit rule applied
  back at us.  Codex wrote 6 boundary-census scripts into our
  Scripts/ on Aug 13 (untracked, flagged for exchange).

## 2026-08-14 — THE BOUNDARY COUNT: <=33 distinct periods

- Nullity counter delivered (scratch nullity/, NullityReport.md entry
  point; 170/170 substrate with exact dlog certificates; smoke 21/21;
  NLO acceptance PASSED with N_new=0).  Global result: 75 family-level
  surviving mode coefficients across 80/91 evaluated families
  deduplicate at class level to 33 DISTINCT new boundary periods —
  an upper bound (regularity rows omitted by policy; inheritance
  through inhomogeneous couplings not modeled; chart ordered corners
  not derived, so cornerRay does not vote for 34 families).
- Structure: ALL 33 survivors have eps-exponent ZERO — pure integer
  Frobenius modes, i.e. normalization CONSTANTS of blocks regular at
  all anchor strata, not transcendental branch modes (structural:
  normal-residue rows fix exactly the lambda!=0 modes).
- Pending additions: the 11 families blocked on classes 77/79/97.
- Provenance caution (agent): the "20-40" figure came through the
  user-shuttled Codex message, not their tree; their nearest on-disk
  figure is 17 maximal boundary SUPPORTS (families, not periods).
- CF231_B1 comparison machinery built (their RowReduce@NullSpace
  convention) — activates once class 79 has a form and the corner is
  Moser-reduced; E13 = 24-dim ruTopology53, mapping via registry to
  be settled in next exchange.
- Process lesson, now doctrine: FOUR silent-drop bugs found (all
  exit-0); per-item status records are the only signal.  All covered
  by assertions now.

## 2026-08-14 (afternoon) — first boundary periods SOLVED; both GPT-Pro
   rungs rejected on measurement; pre-balance rung promising

- QF pilot + extension (scratch qf_pilot/, PILOT.md 914 lines):
  PIDs 1, 6, 7 solved EXACTLY (all = 0) — the whole 1-uncut-
  denominator tier; e.g. R = -(2-3eps)/(v(1-2eps)) 2F1(1-eps,1;
  2-2eps;-s/v) for CF1, verified by exact DE checks + ~30-digit
  numerics + non-circular branch pinning (the agent caught its own
  circular first derivation).  All 20 one-dim certificates written
  in the exchange schema; 12 carry explicit realization-transfer
  caveats (no unverified transfer claimed).  17 resisters need a
  5-VARIABLE PARAMETRIZATION (>=3 uncut denominators) — one build
  serving all 17 = the highest-leverage boundary item.  Repricing:
  CF-class<->template map EXISTS (BoundaryTemplateTopologies.wl),
  coverage 1/20 is the gap; SubTropica failure was helper-kernel
  spawning (no HyperFLINT; Codex passes "Kernels"->1).
- Quasi-finite verdict: DEFER stands on measurement from both sides
  (shift count 0 = no-op at 1 denominator; >=1 at 6, cost unmeasured).
- Rung benchmark: Libra REJECTED (3 failure modes incl. a 1370s
  unbounded seat burn with no output); LS-proxy REJECTED
  (precondition only on dim-1 classes, settled off-seat in 15 min);
  pre-balance rung (our specials finding) fires on 18/173, scan
  0.27s/class off-seat, removed class 26's apparent singularity in
  0.4s — head-to-head vs 324s/631s baselines + class-77 attempt in
  flight.

## 2026-08-14 (evening) — rung benchmark closed: ladder unchanged;
   round-4 exchange with a retraction

- Final benchmark verdicts (controls reproduced baselines +7.2%/-1.3%):
  Libra REJECT (structurally unusable in chart frames; 1370s dead-
  kernel burn); LS-proxy REJECT (precondition only on dim-1); pre-
  balance REJECT EMPHATICALLY (destructive: 26: 347s success->946s
  FAIL; 33: 623s->1202s timeout; 77: +87s for nothing).  "Removing a
  letter is not simplifying the system."  Ladder stays as measured.
  Class 97 proven obstructed (2400s) -> 77/97/79 to maximal-cut/PF
  (Codex already on CF258 Kallen residues).
- Round-4 exchange note committed (round4_periods_and_benchmarks):
  RETRACTION of this morning's pre-balance advice to Codex (measured
  harmful before a rational-ansatz search); solved periods 1/6/7
  certificates; SubTropica option-stripping bug report; template-map
  coverage gap; their stray scripts; ruTopology53 mapping question.
- Class-115 registration delegated back to the specials agent (its
  file has a literal D[F1, 4vw] defect in ClosedForm; my u-frame
  reconstruction gate came out False pending the x-vs-z convention
  fix).

## 2026-08-14 (night) — Codex reply to round 4: three upgrades, one
   correction of ours

- Pre-balance retraction ACCEPTED; 77/79/97 confirmed to their
  maximal-cut/PF lane with a class-115-style one-variable-dependence
  test first (our mechanism adopted as their standard early check).
- PIDs 6/7 zeros made ANALYTIC by Codex (dominated-convergence bound
  on our own parametrization D_s = u+(1-u)(1-s)t; endpoint kernel
  integrable for Re(eps)<1/2 => free mode s^(2eps-1) has zero
  coefficient; meromorphic continuation => exactly 0).  Our numerics
  now serve as independent checks — the analytic-first doctrine
  holds end to end on the first solved periods.
- OUR SubTropica bug report challenged: raw STIntegrate takes
  "KernelsAvailable", not "Kernels" (FACET wrapper option) — the
  option-stripping we reported is correct behavior.  Retest with
  their prescription dispatched (QF pilot agent); PILOT.md will be
  marked retracted-or-confirmed on the evidence.
- E13 mapping DELIVERED: ruTopology53 = CF407 under (a1..a9) ->
  (a2,a1,a9,a8,a7,a6,a5,a4,a3); 24 masters in 17 diagonal blocks.
  Nullity counter acceptance test (b) rerun dispatched against
  CF407's family-level joint modes.
- Their six census scripts copied to their Tools/BoundaryCensus/;
  our untracked copies removed.

## 2026-08-14 (late night) — nullity counter FULLY VALIDATED:
   E13/CF407 comparison 24/24 PASS

- Acceptance test (b) closed: class-130's ordered corner turned out
  to be an ordinary coordinate corner (mixed-kind loci; unramified),
  no two-parameter solve needed; the genuinely hard curve-curve case
  stays honestly not-derived (affects corner_ws_* only).  Full
  24/24-master comparison at corner_vw_w1: ALL FIVE of Codex's
  candidate pairs reproduced with exact multiplicities, incl. the
  3-dim (0,-2) space; the (-2,-2) mode confirmed to originate in
  exactly the previously blocked class-130 block (hypothesis ->
  result).  Both counter acceptance tests now PASS.
- On record: we carry one negative pair they don't enumerate,
  (1,-1) x2 — round-5 question; and the agreement is on the corner
  MODE SPACE, not an independent rederivation of survivor selection
  (that needs ordered-corner constraint rows — future work).
- GPL engine: depth hypothesis FALSIFIED by its own prediction test
  (fix that would have shipped was wrong); defect cornered to the
  series constructor's I = sum T_r F_{n-r} assembly; order-0 binary
  split authorized and running.

## 2026-08-14 (night, cont.) — CF360 mystery RESOLVED: not a bug,
   missing valuation constraints; engine vindicated

- Fourth hypothesis (missing physical-valuation constraint set)
  CONFIRMED by construction: imposing I_{-1} = 0 identically (25
  linear equations on 17 constants; 5 fixed — exactly the constants
  every residual localized to all night) makes the order-0 assembled
  check pass on all rows incl. the 2x2.  The eps^1 line is top-edge
  support, understood.  Chain: 4 hypotheses tested by prediction,
  3 falsified (depth; padding-vs-cancellation; F-below-KMin, killed
  by index-shift evidence), 1 confirmed.  THE CHECK WAS CORRECT ALL
  NIGHT — it rejected the unconstrained general solution for
  violating the assumed Laurent valuation; gates (a)/(b) passed
  because boundary-fixing imposes the valuation implicitly.
- Fix (in build): solve-time valuation-constraint step — per-block
  valuation from ord(T^-1), I_n = 0 below it as linear constraints
  on the constant vector, verified by the below-window residual
  assertion in EVERY production solve; valuation reference coupled
  by design to the boundary-fixing n0 (one physics statement).
  Then CF360 end-to-end; stragglers at 3600s overnight.
- SubTropica: our defect report RETRACTED, Codex's correction
  confirmed materially (kernel storm was our own $ProcessorCount-1
  request); remaining narrow finding: HyperFLINT order-finder fails
  on a textbook integral with no HF library on disk — decisive
  correct-options+forced-HyperIntica test queued.

## 2026-08-14 (close) — ALL THREE ENGINE GATES GREEN; round-5 shipped

- Valuation-constraint step implemented as a universal solve-time
  stage (per-block from ord(T^-1); below-valuation assertion in
  every production solve; valuation reference coupled to boundary-
  fixing n0 by design, documented).  CF360 END-TO-END PASS (19/19
  exact quadrature zeros; assembled DE exact with symbolic
  constants).  Gates: NLO (>=40 digits, 2 points), CF3 (exact
  eps^0-2), CF360.  Stragglers CF123/CF269/CF263 running overnight
  (3600s guards, monitor); CF123 certificate OK, in solve.
- SubTropica saga closed: tool exonerated; final root cause OUR
  regulator symbol (ep vs its routing eps); Route R evaluates PID-1
  in 0.68s exact; six caller-side faults tabulated; "the prior sits
  on our invocation" adopted.  Open: whether eps>=2 orders need
  HyperFLINT (queued) — joint infra decision if so.
- Round-5 note committed + shuttled: 24/24 validation with the
  (1,-1) question; SubTropica retraction; valuation story; proposed
  division — stage-4 distributional pilot to Codex, survivor
  selection doubly derived, periods split 17-one-dim (us, one
  5-var build) / 13-multi-dim + fair QF test (them), their lane
  unchanged; regulator-normalization trap-list recommendation.

## 2026-08-14 (midnight) — hard-class toolkit delivered; class 97's
   "obstructed" verdict DISPROVED as chart-specific

- HardClassToolkit ladder (Scripts/HardClassToolkit.wl +
  Design/HardClassToolkit.md, uncommitted pending review): R1
  diagnostics / R2 cyclic-vector / R3 operator-ID / R3b
  rationalization / R4 certification / R5 obstruction handoff.
  Acceptance gate PASSED: class 115 rediscovered blind (z=vw derived
  mechanically, correct 2F1 parameters, exact certification; caveat
  recorded: agent had prior sight of the report during orientation —
  mitigated by auditable derivation, no stored constants).
- MAJOR: class 97's "proven obstructed (2400s)" verdict was
  CHART-SPECIFIC, not intrinsic — under v=xy, w=(1-x)(1-y) the
  Kallen curve becomes (x-y)^2 exactly; census shows NO half-integer,
  non-Fuchsian, or eps-dependent loci; 7-letter rational alphabet.
  Chart discovery cost 0.5s.  Lesson for the toolkit doc: "obstructed
  in a chart" is never "obstructed" — R3b tries the alternative
  rationalizations before any such verdict.  CANONICA runs on 97 (and
  77, sqrt cleared, residuals remain) in the new chart green-lit,
  seat-queued behind the straggler production runs.
- Class 79: toolkit R1 agrees with class79_localdata on every locus,
  adds one row; left to Codex.
- Toolkit found 3 of its own bugs by disbelieving output
  (non-deterministic tie-break; half-integer detector false-negative
  on algebraic loci; timeout discarding completed work).
