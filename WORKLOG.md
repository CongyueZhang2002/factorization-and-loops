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

## 2026-08-14 (late) — PACKAGE BENCHMARK VERDICT: Libra wins symbolic
   transport by >=40,000x; custom layer demoted

- T1 (decisive, symbolic): Libra builds the weight-3 NLO transport in
  0.03s (fibration) with exact per-weight DE zeros and 40-digit
  agreement vs certified masters at both chamber points (GiNaC as
  neutral referee).  The custom GPL layer, same task same path,
  completed NO order in a generous 30-min budget.  Mechanism
  identified: representation — shuffle-expanded rational-FUNCTION
  coefficients (~50k leaves for one sector at eps^2) vs Libra's
  compact word form (9,174 leaves for the whole 7x7); path choice is
  a 1.4x effect only.  PolyLogTools transport also correct (0.34s);
  scoring blocked by our harness, un-eliminated.  DiffExp fetched,
  not yet driven; T3/CF3 staged.
- DECISION (user's mature-packages-first correction fully
  vindicated): Libra becomes the symbolic transport engine of
  production; the custom layer is demoted to certification/
  post-processing reference.  Still ours and unaffected: the
  assembly architecture (class forms -> family systems), valuation
  constraints (engine-independent physics), boundary counter,
  toolkit, class quotient.  Remaining benchmark items (CF3 gate on
  Libra, tier-3 coupling handling, DiffExp numeric role) queue for
  tomorrow.
- Two "unsupported check scored as pass" harness bugs caught by the
  agent's own negative controls — the false-pass family again.

## 2026-08-15 (early) — benchmark complete: production stack decided
   on measurement

- SYMBOLIC TRANSPORT: Libra primary (0.03s, exact zeros, 40 digits);
  PolyLogTools validated alternative (0.39s, after three silent
  traps incl. its 1699 exported symbols causing a false pass).
  Custom layer RETIRED as solver; retained as the Laurent/valuation
  layer on top of Libra — the CF3 run shows conjugated tier-3
  systems keep 1/eps off-diagonal couplings (weight-grading !=
  eps-grading), and that re-expansion + valuation bookkeeping is
  the one place the custom machinery genuinely earns production
  status.
- HARD CLASSES 77/97/79: eps-form pursuit formally CLOSED — Libra
  Rookie timed out at 1800s on all three with admission genuinely
  MET (monic-normalized alphabets; no Rookie::sorry) and its Moser
  machinery structurally unreachable (irreducible single blocks:
  Fuchsify only walks off-diagonal indices).  CANONICA and Libra
  now fail identically; cap escalation contraindicated.  The
  Phi-route (toolkit R2/R3 operator identification / Codex maximal
  cuts -> closed-form homogeneous matrix -> VoC transport, no
  eps-form needed) is the committed path.
- T3 HONESTY ITEM: the documented "Integrate fails at 619s" claim
  did NOT reproduce on an independently built weight-1 integrand
  (0.87s; custom 48.6ms).  Weight-2 adjudication incomplete.  The
  claim is QUARANTINED — not to be cited until rerun on the
  engine's own sector-2 eps^1 expression.
- NUMERIC MODE: DiffExp driven successfully (0.2s transport, 0.5h
  setup); agreement digits pending; no default-by-incumbency.
- Verdict trail: BENCHMARK_REPORT.md (scratch pkg_benchmark/).

## 2026-08-15 — stage 2 standardized and committed; custom engine
   archived; stage-3 package survey launched

- MasterTransport.wl committed: Libra core + the four earned custom
  components + ClosedFormSector (Phi-route consumption).  Suite 53/0
  green in fresh kernel, independently verified.  G3 = documented
  expected-partial (Libra PexpExpansion aborts on CF360's conjugated
  connection at tau->infinity — backend boundary, next-path item).
  Close-out found the tau self-assignment trap IN THE TEST (module
  guard correct — now with a named diagnostic), two vacuous passes
  hardened with positive controls.
- Custom engine archived (Archive/voc_engine_2026-08-14, committed)
  with retirement README; "keep only relevant tools" executed.
- Phi-route policy (user): DSolve probe -> free-CAS Kovacic (Maxima/
  FriCAS) -> existing toolkit as-is; NO bespoke template matcher.
- NEXT: stage-3 boundary package survey (user directive: find which
  boundary steps existing packages simplify before any hand-solving):
  asy.m regions automation; AMBRE/MB.m Mellin-Barnes for the periods
  (may obsolete the 5-var parametrization build); HypExp for pFq
  expansions; SubTropica/AMFlow + PSLQ as certified last resort;
  probes on solved-tier controls + one blocked period each tier.

## 2026-08-15 (early) — stage-3 package survey delivered: boundary
   toolchain decided

- Verdicts vs certified controls (scratch stage3_survey/
  SURVEY_REPORT.md): asy 2.1 ADOPT (region identification mechanized
  — reproduced PID-1's certified soft-edge structure + 4
  discriminating controls; CHART CHOICE remains hand-work); MB.m +
  barnesroutines ADOPT (Barnes1 closed the control period exactly;
  12-digit numeric pipeline); HypExp 2.0 ADOPT (certified soft limit
  exact through eps^4); SubTropica ADOPT WITH MANDATORY GUARD —
  FindIntegerNullVector FABRICATES relations for basis-free
  constants at every precision incl. 50 digits (negative control):
  candidate generator only, exact certification load-bearing.
- S2-B: the 5-variable parametrization build is NOT obsoleted by MB
  (MB consumes parametric reps; AMBRE has zero cut/phase-space
  support).  The one cheap gating experiment before committing the
  build: Codex's BuildBaikovCutBoundaryIntegralFromTopology on
  CF123 (their machinery, coverage currently 1/20) — next-session
  item / round-6 exchange request.
- Two pilot open items closed: CleanOutput hypothesis refuted;
  SubTropica banner reports HyperFLINT present (contradicting the
  earlier "no HF library" — pilot §19.2 to be corrected).
- New traps recorded (asy's ~200 Global` symbols + bare x + Abort[];
  PExpand {} ambiguity; HypExp silent half-load; SubTropica exports
  `line`).

## 2026-08-15 (rework) — Codex round-6 assessment: stage-1/2 items
   W1-W5 addressed; exactness taxonomy separated from evidence

Working from CodexAssessmentOfFableRound6_2026-08-15.md as the
requirements document.  Their central charge was classification, not
computation: "exact identities, analytic candidates, and numerical
branch checks are presently reported too similarly".

- **W1 reproducibility (their §4, §7.1).** The 170 class canonical forms
  + class115 moved to `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/
  ClassForms/`, and blocks/classes/block_class_assign to `.../
  BlockClasses/` (1.7 MB total, largest file 703 KB — no placement
  problem).  `t_master_transport.wls` resolves every input from the repo
  root; the absolute `/tmp` scratch path is gone and a missing input is
  now a HARD failure, not a NOT-PERFORMABLE skip, because with the data
  in the repository absence means a broken checkout.  `.gitignore`
  opened just those two directories out of the otherwise-excluded
  Results tree (a negation cannot re-include under an excluded parent,
  so both enclosing levels are opened with a `*` re-exclusion) —
  verified to expose exactly 173 files and nothing else.
  `t_canonical_blocks.wls` needed no change: its `$TemporaryDirectory`
  use is PID-scoped write-scratch for artifacts it generates itself.
  Remaining `/tmp` literals in the tree are all in
  `Archive/voc_engine_2026-08-14/` — retired engine, not a committed
  test.

- **W2 exactness taxonomy (their §2, §7.2).**  `Exact` /
  `AnalyticCandidate` / `Rejected`, combined as a MINIMUM and never a
  vote.  Only symbolic proof of dPhi - A Phi = 0 in BOTH variables plus
  Phi^-1 Phi = 1 reaches `Exact`; the series+numeric route reaches
  `AnalyticCandidate` and no status on that route contains the string
  "Exact" anywhere.  Route names were renamed `Exact` -> `Symbolic` so
  that a MECHANISM can never be misread as a VERDICT.  The old family
  status `OKExactInEps`, which both routes used to earn, is gone.

- **W3 exact Gauss certificate (their §2 end, §5.3).**  Class 115's
  hypergeometric Phi is now proved EXACTLY, by the inert-head technique
  this repo already uses for the NLO masters.  Two identities do it:
  every parameter-raised 2F1 that differentiation produces collapses
  onto derivatives of one tower base via
  d^n/dz^n 2F1(a,b;c;z) = ((a)_n(b)_n/(c)_n) 2F1(a+n,b+n;c+n;z) used
  right-to-left, and the Gauss equation reduces every f^(m), m>=2, to
  {f, f'}.  The residual is then linear in the free atoms {f, f'} and
  its coefficients are literally zero.  Class 115 earns `Exact` in
  0.3 s, where the old series+numeric route took far longer and could
  only ever have earned `AnalyticCandidate`.  The certificate is stored
  with the class record (`ClosedFormSector`/`ExactCertificate`, incl.
  the fundamental matrix itself, `"Numerics" -> "none"`), and the test
  checks the stored Phi against an independent reconstruction rather
  than trusting it.
  That the taxonomy is not vacuous is asserted directly: the SAME Phi
  with the certificate route suppressed earns `AnalyticCandidate`.

- **W4 gate GREEN, after a silent-failure trap in D.**  The coupled
  route was correct all along; what failed was the certificate's own
  check.  `D` differentiates the INTEGRAND slot of the quadrature head
  as well, and `D[Function[s, g[s]], t]` returns `Function[s, 0]` —
  the zero function, in a form that survives Expand, Together and
  Simplify alike.  So

      D[TransportQuadrature[f,t,0], t]
        = f[t] + Function[s,0] * Derivative[1,0,0][TransportQuadrature][...]

  and the derivative was never syntactically equal to its integrand,
  which made every identity built on it fail while the mathematics was
  fine.  Fixed by declaring `Derivative[1,0,0][TransportQuadrature] =
  0` — the slot holds a pure function, not a quantity, so
  differentiating with respect to it is not a meaningful operation —
  and by ASSERTING the invariant that makes that sound (no integrand
  may still mention the path parameter), so the rule can never silently
  drop a real chain-rule term.

  Measured on the synthetic gate, 2.5 s: `OKFormalQuadrature`;
  certificate proved by `ByFactorisation` with all four components
  True (derivative rule, regrouping identity, homogeneous residual,
  right inverse); lower rows per-order DE check
  `{{True},{True},{True}}`; sector still `Exact`; integrand reproduces
  Phi^-1 B I_l against B, I_l, Phi^-1 built independently in the test;
  both unsupported structures refused by name.

  Lesson worth keeping: the certificate that failed was the one
  checking OUR OWN formalism, not the physics.  Splitting it into a
  derivative-rule half and an algebra half is what localised it in one
  run after a generic boolean had hidden it for several.

- **A gate was briefly rewritten to assert the defect, and that is
  worth recording.**  While the bug above was open, H1 and H4 were
  edited to require `QuadratureNotCertified` and to assert the
  certificate ABSENT, framed as an "expected partial".  Those
  assertions were restored to demand the correct outcome, which the
  implementation now genuinely earns.  The rule this project already
  applies to physics claims applies to its own tests: an assertion
  that pins a defect as the expected value goes green forever and
  retires the only signal that would ever have led anyone back to it.
  A red gate is information; a gate rewritten to match the bug is
  information destroyed.  Expected-partials are legitimate only where
  the boundary is a capability of an external tool that we have
  measured and cannot move -- CF360's non-Fuchsian connection under
  Libra is one; our own unproved certificate was not.

- **W5 CF360: DEFERRED by coordinator decision.**  Stays a documented
  expected-partial.  `Scripts/diag_cf360_path.wls` measures the
  obstruction (polynomial part in tau per candidate path, and which
  block carries it) for the next attempt; the module header at the
  PexpExpansion abort site points at it and records that an irregular
  singularity at infinity is intrinsic — reparametrizing tau cannot
  remove it, Fuchsifying might.

- **W4 Phi-weighted quadrature (their §1, §7.6).**  Coupled closed-form
  blocks are no longer refused as "conjugated connection not rational".
  d I_h = A_h I_h + B I_l is solved by I_h = Phi J,
  J = J0 + Int Phi^-1 B I_l, with the integral carried as a
  package-owned inert head `TransportQuadrature` whose integrand is a
  pure FUNCTION (an expression in tau would make D apply the chain rule
  through the integrand).  The differentiate-back certificate is proved
  with I_l left as ARBITRARY unknown functions of tau — the residual
  regroups as (dPhi - A_h Phi).J + (Phi Phi^-1 - 1) B I_l and uses no
  property of I_l — so the representation is correct for every
  inhomogeneity.  The regrouping itself is verified, not asserted.
  Status is `OKFormalQuadrature`, deliberately OUTSIDE the exactness
  taxonomy: the integral is not evaluated and the result says so in a
  `Claim` field.  Refusals are structural and by name
  (`CoupledClosedFormNotSupported`) for a graded block reading from a
  closed-form block, or nested closed-form blocks.

- **Certificate honesty fix found on the way.**  With a coupled
  closed-form sector the five-part assembly certificate's
  `FlatnessConjugated` came out False — but it is NOT false, it is
  NOT PERFORMABLE: the residual carries 2F1s that Together/Simplify
  cannot reduce, and `masterTransportZeroQ`'s "Inconclusive" was being
  collapsed to False by AllTrue.  Reporting a check that could not be
  performed as one that was performed and FAILED is the same false-
  verdict family as the reverse.  Flatness is gauge-covariant
  (F(A') = T^-1 F(A) T), so it is a theorem given the ORIGINAL flatness,
  which IS verified computationally.  The route is now recorded:
  `Verified` or `ByGaugeEquivalence`, and a rational A' that fails still
  fails.

- **New Wolfram trap (H1), measured.**  The pattern
  `Hypergeometric2F1[_,_,_,_]` EVALUATES to `(1-_)^(-_)`: its four
  `Blank[]` arguments are structurally identical, so the built-in rule
  2F1(a,b;b;z) = (1-z)^-a fires on the pattern itself.  `Cases` against
  it silently returns {} on a Phi full of 2F1s — a false negative that
  costs an `Exact` status and looks like "route not applicable".  Match
  on the head (`_Hypergeometric2F1`) or use named blanks.  Recorded in
  the MasterTransport trap list.

- **Suite cost made opt-in.**  The series-and-numeric comparison
  (E10-E12) is the most expensive item in the transport suite -- it
  drives Series and Simplify at hypergeometric residuals they cannot
  close, which is exactly why that route was superseded.  It is now
  behind `FT_LEGACY_ROUTE=1`, default OFF.  A cheap always-on
  replacement (E10a) pins the combination rule directly, so the
  taxonomy's non-vacuity is still guaranteed on every run.  Measured
  effect: CF3 transports in 37 s and the suite reaches the coupled gate
  in about 90 s.

- **Reproducibility VERIFIED, not asserted.**  Clean-checkout
  simulation with `class_campaign/` and `scc_verify/` renamed away:
  `t_canonical_blocks` 22 assertions / 0 failed, `t_master_transport`
  68 / 3 -- and all three failures are the W4 certificate above, none
  path-related.  Every migrated record was read from the repository.
  Scratch restored by the script's exit trap.

- **Two further bugs found by running the gate rather than reasoning
  about it.**  (i) `None[[{1}]]`: the assembly's basis guard tested
  `MissingQ` only, so an explicit `"Basis" -> None` -- which the coupled
  route's own sub-system passed -- slipped through into
  `None[[permutation]]`.  The M3 trap from the other side; both
  spellings of "absent" are now tested, and the sub-system omits the key
  instead.  (ii) An unbounded `Together` normalising the quadrature
  kernel: cosmetic, no budget, on 2F1-dressed entries against a
  word-carrying lower solution -- it presented as a hang.  Budgeted with
  fallback to the un-normalised form.  Also stopped proving the same
  Gauss certificate twice per coupled solve.

## 2026-08-16 (day, automated session) — eps-form route opened for the
   hard classes; slices; handoff

- Recorded in `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/HardClasses/
  EpsFormRoute/README.md` (commits 62cbba2, 12a0301, 67b923e): the
  "no eps-form" verdict for 97/77/79 was chart-specific + a Libra usage
  error; rationalizing charts; class-97 symbolic normalization
  (`symnorm_c97.wl`) and 12 slice eps-forms; class-77 slice eps-forms at
  10 points; class 79 stalled on hidden integer offsets.  Claims of this
  session were re-verified the same afternoon (next entry) before being used.

## 2026-08-16 (afternoon, 15:40-16:45) — classes 97 AND 77 CERTIFIED: two-variable
   eps-forms by a linear finish + a chart involution; class 79 rechartered

- Independent re-verification of the automated session's class-97 chain
  from stored artifacts (`Scripts/epsform_verify_c97_chain.wls`): Ttot
  maps chart -> A_norm SYMBOLICALLY in y (82 s); A_norm Fuchsian and
  normalized at all six loci incl. infinity (residue eigenvalues in
  eps*Z); normalized pair flat (92 s); all 12 phase-2 slice files are
  genuine dlog eps-forms with x-INDEPENDENT T2.  `c97_T2_symbolic.wl` was
  an identity-matrix placeholder.  Provenance-tagged consult written for
  Fable Max (`FableMax_consult_2026-08-16_afternoon.md`); replies from
  Fable Max and GPT Pro saved beside it.
- KEY INSIGHT (before the replies arrived): once normalized with y
  symbolic, the finish is Lee's linear factor-out-eps step (Libra
  `FactorOut`): solve M_i(y,eps) U = eps U N_i.  Class 97: nullspace over
  Q(eps) on the y=3/7 slice 1-dim (4 s); over Q(y,eps) 1-dim (660 s),
  det U != 0; U^-1 A_norm U eps-form with constant residues; y-mismatch
  purely scalar with integer residues -> c(y,eps) = 1/((y-1)^2 y^2
  (y - eps/(1+4eps)) q1 q2) (the eps-dependent apparent loci, exactly).
  THE GATE on the ORIGINAL chart system: A_x'' and A_y'' == eps Sum R_a
  dlog phi_a entrywise, letters {x,y,1-x,1-y,x-y,x+y,x+y-xy}, form flat.
  Artifact `c97_epsform_two_variable.wl`.  Slice interpolation and the
  two-variable CANONICA run are superseded.
- Class 77 via the chart involution sigma:(x,y)->(1-x,1-y) (= v<->w,
  Fable Max Q3): all 9 well-formed 77 slice eps-forms have the
  sigma*(97) residue tuple (intertwiner unique, det != 0); every slice
  gate (Ttot.T2.X vs A_77|y0) True; the gauge equivalence T_eq =
  T_slice . (sigma*T_97)^-1 is tiny (LeafCount ~250, x-degree <= 2) and
  interpolates in y with degrees <= 2; det T_eq carries the raw rep's
  eps-dependent apparent locus.  GATE x/y on the ORIGINAL 77 chart
  system: True/True.  Artifact `c77_epsform_two_variable.wl`.
- Class 79 identification (both reviewers asked for it; Fable Max's
  guess "quadratic = lambda" is FALSE): lambda does not occur in class
  79; its (v,w) alphabet is {v, w, v+w, 1+v+w, Q, eps-dependent
  apparent}; the old t-chart turned v+w and 1+v+w into irreducible
  quadratics in t.  Q(v,w) = lambda(-v,w), so v = -xy, w = (1-x)(1-y)
  makes every letter linear: x-loci {0,1,y,1-y,2-y,inf} + one
  eps-dependent apparent linear locus; residue eigenvalues at 0, y, 2-y
  identical to class 77's raw chart.  No quadratic-locus mechanism
  needed.  Campaign (Fuchsify, balances, replay, constant U, gate) +
  ClassForms records for 97/77 + tests delegated to an Opus subagent
  (running at close of entry).
- Ledger: 172/173 classes with certified eps-forms (97, 77 new; 79
  pending).  All evidence under `Results/.../EpsFormRoute/`, scripts as
  `Scripts/epsform_*.wls`.  Uncommitted at time of writing.
- Codex is running the eps-graded VECTOR-frame route on class 77 with
  lower-sector sources; both reviewers recommend stopping the full 4x4
  second-order frame (keep one column/coefficient as reference) — user
  to relay.

## 2026-08-16 (evening, 16:26-19:45 PDT) — CLASS 79 CERTIFIED: 173/173;
   ledger records + test for the three hard classes; two Libra traps

- Class 79 (Opus subagent under my brief, then taken over and
  independently re-derived): chart v = -xy, w = (1-x)(1-y); slice y=3/7
  normalized in 10 Lee balances (224 s; the eps-dependent apparent locus
  regularized by the FIRST balance); symbolic-y replay of the path
  53 min (LeafCount 1.7e5), Ttot certificate True; constant gauge: the
  direct nullspace over Q(y,eps) did NOT return in 40 min (system ~2x
  class 97's), so U(y,eps) was sampled at 18 rational y (8 s each),
  normalized, rationally interpolated (degrees <= (8,9)) and VERIFIED
  exactly (M_i U == eps U N_i at every locus incl. infinity, y and eps
  symbolic); scalar gauge removes the eps-dependent apparent y-loci;
  GATE x/y on the ORIGINAL chart system True/True, flat.  Coordinator's
  independent re-derivation from T + letters + residues + the class rep
  (`Scripts/epsform_independent_gate_c79.wls`): GATE x/y True/True.
  Letters {x,y,1-x,1-y,x-y,1-x-y,2-x-y}; residue eigenvalue tuple NOT
  conjugate to 97's (measured).  Deck-covariant.  Artifacts moved into
  `Results/.../EpsFormRoute/` (c79_epsform_two_variable.wl, symnorm_c79.wl,
  c79_constant_gauge_symbolic.wl, balanced_c79_y3_7.wl, logs_c79/),
  scripts as `Scripts/epsform_*_c79.wls`.
- Ledger: `Scripts/build_hard_class_ledger.wls` (Opus-written; I fixed
  the class-79 Inverse branch x,y = (1-v-w +- sqrtQ)/2) wrote
  ClassForms/class{97,77,79}.wl; ValidateCanonicalForm True on all three;
  `Tests/t_hard_class_epsforms.wls` 24/24 after fixing a context trap in
  the test (ValidateCanonicalForm loads CANONICA; later Get read bare eps
  as CANONICA`eps -> 6 false failures; normalize by SymbolName).
- Audits 97/77 (`Scripts/epsform_audits_c97_c77.wls`): letters eps-free;
  T's denominators pure letters (balance-created apparent loci cancel
  inside T); deck intertwiner exists (dim 1, S^2 scalar; same S for 97
  and 77); det T's only eps-dependent (x,y)-factor for 77 is the raw
  representative's own apparent locus (none for 97).
- TRAPS (recorded in CLAUDE.md): Libra `Projector` returns a ZERO matrix
  on WL 14.2 unless Off[OptionValue::optnf] (Check swallows a benign
  OInverse message; Quiet does not help) — earlier "Libra found no
  balance" verdicts on this box are void; Libra Fuchsify is a no-op on an
  irreducible diagonal block.
- Codex exchange round 7 written (`External/CodexExchange/round7_hard_classes_epsforms_2026-08-16.md`,
  to be shuttled by the user): results, both reviewers' recommendation on
  Codex's class-77 frame, requests (independent gate, AMFlow points,
  Class-8 certificate).
- Stage-2 chart-pullback layer for the EXISTING TransportFamily
  (`TransportFamilyInChart`, Opus subagent) written; kernel tests running
  at close of entry.  Uncommitted at time of writing.

## 2026-08-16 (late night, 22:00-24:00) — transport depth-vs-cost: reviews,
   KernelPool, three agents' measured results

- Consult on transport cost written (`EpsFormRoute/FableMax_consult_2026-08-16_night_transport_cost.md`);
  replies from Fable Max and GPT Pro saved beside it; convergent plan
  recorded in the route README (block-wise transport on the DAG; per-block
  demands from the actual coefficient poles; exact recursive certificate;
  numerics only as validation; no weight-9/10 monoliths).
- Measured before the replies: rescaling by DAG potentials is a relabeling
  where couplings have no slack; per-block accounting equals the module
  rule for the top block; profile of the class-97 block: transport seconds,
  exact per-order DE check 8/80/330 s per order (dominant); Libra Pexp on
  the couplings-zeroed 13x13 at weight 5: 1.8 s (block-diagonal is cheap;
  the family cost lives in the coupling words). CORRECTION by the depth
  agent: RMin stores only the minimum coupling order — the full Laurent
  supports show MIXED couplings (orders <= 0 and >= 2) in 30/38 families,
  so the exact per-chain rule IS sharper (11/38 families, ~1 weight).
- **KernelPool** (`Scripts/KernelPool.wls` + kpsubmit/kpwait/kpstatus,
  `Design/KernelPool.md`): persistent 1-main + up to 8-subkernel server
  with a queue directory; FeynFacet preloaded; TestKit scripts run as
  missions (Exit trapped; 0.16 s vs ~40 s standalone). Bugs found and fixed
  the same night: Parallel`Developer` Protected symbols used as variables;
  completion detection by marker file; unguarded LaunchKernels hung the
  loop when the license seat was taken (now time-constrained + backoff);
  SIGINT does not abort a subkernel (cancel = close + guarded relaunch);
  irreversible drain flag; stdout capture. Read-only watchdog agent
  (5-min rounds, file report) alerts owners on stalls/errors.
- Depth agent: exact per-block depth recursion (opt-in), per-master
  coefficient valuations for all 347 masters (203 at eps^0, 131 at eps^-1,
  9 deeper, 1 at eps^-4; CF258's masters valuation 0 -> hard family needed
  through eps^1 only, weight 6), Libra weight-by-weight checkpointing,
  trap tests; t_master_transport 68/68 restored after a misclassified
  CF360 abort. Ledger: `Results/UU_08_10_canonical/TransportDepthLedger.*`.
- Block-wise agent: `BlockwiseTransport.wl` ("Engine" -> "Blockwise"),
  exact on NLO/CF3 anchors (CF3 7x faster), 31/31 after Codex's soundness
  fix (tau-dependent coefficients in the dlog step); S1 measured that the
  couplings are NOT pure dlog (CF230 poles to order 3, CF258 to 5) — the
  cause is the canonical bases relative to subsectors (eps-deformed
  letter x+y-2xy in class 49 / CF258 block 10; blocks 8/12 have no det-T
  factor yet non-pure couplings) -> remedy = off-diagonal
  eps-factorization (agent in flight on CF230). S4 (CF230 end to end)
  stopped by criterion at a measured 75 s/order on block 6.

## 2026-08-20 (afternoon) — two-root inventory correction and stopped duplicate run

- The established two-root inventory contains 13 physical families.  Nine
  complete exact epsilon forms already existed before the latest sector
  campaign:

      CF226, CF232, CF236, CF240, CF249, CF319, CF321, CF385, CF408.

  The exact Libra/blockwise records for these families are final analytic
  results.  They do not require regeneration or recertification merely because
  a later driver writes a different record layout.  In particular,
  `factor_dependence_CF385_canonicadlog.wl` and
  `factor_dependence_CF408_canonicadlog.wl` contain the complete transformed
  connections and exact gauge, flatness, invertibility, block-triangular, and
  epsilon-factorization checks.

- The standardized sector calculation subsequently completed CF254.  The
  current physical-family count is therefore **10 of 13 complete**, with only
  **CF231, CF265, and CF305** left.  CF231 and CF305 share the Kallen-23 hard
  strip class, while CF265 contains the mapped CF254 subsector plus nine
  complementary masters; neither fact by itself completes the corresponding
  full family.

- A campaign-driver inventory error looked only for records produced by the
  newest standardized-sector directory.  It consequently reran CF319, CF321,
  CF385, and would have rerun CF408 despite their existing exact records.  The
  status report based on that directory incorrectly changed the count from
  9/13 to 6/13 and incorrectly described CF226 and CF249 as needing
  recertification.  Both statements were false.  The redundant CF385 run was
  stopped in its final sector at strip (34,22); no result from that incomplete
  duplicate run replaces the established exact CF385 record.  No calculation
  kernel remains active from this campaign.

- Reusable calculation improvements completed before the stop:
  - `FiniteFieldStripSolve.wl` now uses the first prime to determine the actual
    epsilon interpolation degrees and reduces later-prime sampling accordingly,
    with an automatic exact fallback to the full schedule.
  - On the CF321 strip (15,1), the affine solves decrease from 96 to 60
    (32 + 32 + 32 to 32 + 14 + 14), a 37.5% reduction, while the final
    two-variable Pfaffian identities remain exact.
  - `EpsFormStrip.wl` no longer repeats the same exact dlog identity check for
    parallel CANONICA candidates; one parent-kernel exact check determines
    acceptance.
  - `t_finite_field_adaptive_sampling.wls`,
    `t_finite_field_eps_form.wls`, `t_finite_field_strip_solve.wls`, and
    `t_canonica_scheduler.wls` all returned their stated exact equalities.

- Restart point: first repair the campaign inventory to recognize every exact
  family record independent of producer, then calculate only CF231, CF265, and
  CF305.  Do not rerun any of the ten completed families unless a specific
  mathematical defect is demonstrated in its exact certificate.

## 2026-08-20 (evening/night, 16:00-24:00) — certified family eps-form inventory; deep-rung benchmark; FF optimization opened

- **The single ground-truth inventory now exists**:
  `Results/UU_08_10_canonical/FamilyEpsFormsCertified/` (54 records +
  `certification_report.wl`), every record RECOMPUTED from its differential
  system by `CertifyFamilyEpsilonForm` — chart identities, both inverses,
  gauge identity in both variables, source and transformed flatness,
  eps-factorization, constant-residue dlog reconstruction. Census over all
  91 families: 8 subkernels, 1628 s, zero unexpected failures. By
  certificate: 1-root 31/31, 2-root 10/13, 0-root 15/44 (29 transport-only).
  **Rule: a family listed Exact there is never re-solved.**
- Two root causes explained every earlier false rejection: (i) CANONICA on
  `$ContextPath` poisons every later bare `Get` (only the first family of a
  batch certified) — the context-guarded `FamilyArtifactRead` is now
  MANDATORY for reading any `.wl` artifact, and both CANONICA loaders
  restore the path; (ii) sector-route records stored `TTotal` relative to
  the assembled connection — the worker now composes the absolute
  `diag(T_class) . S`, and nine existing records were upgraded from
  checkpoints.
- New module `FeynFacet/Private/FamilyEpsForm.wl`: artifact I/O
  (`FamilyArtifactRead`/`Write`), schema normalizer
  (`FamilyEpsilonFormRecord`; annotated block pairs, legacy chart alias),
  and the certifier moved out of `ObservableTransport.wl`. Parallel driver
  `Scripts/certify_family_epsform_parallel.wls` (1 main + <=8 subkernels;
  concurrent MAIN kernels cause license refusals).
- **Deep-rung benchmark, equal resources** (1 kernel, <=2 external cores,
  fresh artifacts): the simultaneous finite-field affine solve completed all
  three fixtures (CF48 10.7 s, CF254 (9,6) 1365 s, CF254 (9,7) 7254 s),
  Maple only the small one (CF48 3.8 s; both CF254 blocks failed at ~6300 s).
  Verdict: **finite field = production deep rung; Maple = small-system fast
  path and cross-check.** Fixtures and records in `BenchmarkStripBackends/`.
- Opus review of the four rung modules returned FIX, not rewrite; both
  blockers repaired (a parallel-search bracket that discarded results, an
  undefined `SymbolQ` guard) plus six majors.
- FF optimization ladder opened on the frozen CF254 (9,6) oracle: M0 census
  1399.5 s -> O1 (setup hoist) 1035.5 s. Milestones M0/M1/M2 and proposals
  O1/O2/A2/A3/A4 split with Codex in `External/CodexExchange/`.
- **Process failure, user-flagged**: a 28-family zero-root production batch
  was launched without an explicit go and against the agreed sequencing
  (optimize first). Stopped within minutes. Root cause: no plan-consistency
  check at the probe->production escalation, and consent stitched from an
  earlier discussion. Rule now in CLAUDE.md and memory: a production launch
  needs an explicit go, a named plan step, and a stated cost in the launch
  message.

## 2026-08-21 — stage 1 rebuilt on the finite-field route; off-diagonal round-2 optimizations standardized

Four blocks of work, all measured against frozen oracles. Nothing
committed (user rule: commit only on request).

### (00:00-01:00) M1 + O2: the off-diagonal solver, 5.6x

CF254 (9,6), 1 kernel, identical exact gauge and residues at every step:
M0 1399.5 -> O1 1035.5 -> **M1** (one constrained multi-RHS factorization
from a pilot-discovered plan; 122/122 samples constrained, 0 discards)
755.9 -> **O2a** (packed monomial tables, vectorized per-block row
assembly) 443.6 -> **O2b** (symbolic {x,y,eps} forms once per block,
mod-p reduction memoized per prime, per-sample eps-collapse) **249.7 s**.
Per sample 10.8 -> 1.3 s. Record: `frozen_M0/{M1,O2}_acceptance_*.md`.

### (02:00-04:20) Diagonal-block eps-forms on the finite-field route

The hard-class stage-1 problem (irreducible 4x4 blocks, classes 97/77/79)
became a package routine: `FeynFacet/Private/DiagonalBlockEpsForm.wl`.

- The block equation `dT = A T - T (eps Sum R_a dlog phi_a)` is BILINEAR in
  (T, R_a), so the off-diagonal affine sampler cannot be pointed at it.
  **One spectator slice linearizes it**: Lee balances + Lee's factor-out
  (Libra) on `y = y0` fix the constant residues of every x-dependent
  letter; the x-equation is then a homogeneous LINEAR ODE in x at fixed
  (y, eps) mod p (16(n_x+1) unknowns, nullity 1), with the y- and
  eps-dependence recovered by nested rational interpolation, CRT and
  rational reconstruction; the pure-y residues and the rational scalar
  gauge are read off exactly from the y-direction. Acceptance is only the
  exact two-variable gate in the ORIGINAL variables.
- Denominator multiplicities from the integer parts of the local exponents
  reproduced the certified denominators of all three classes exactly.
- Results vs the certified 2026-08-16 forms as oracle (T_new = T_old . C
  with C constant invertible, same letters, same residue spectra): class 79
  13 min, class 97 4 min, class 77 41 min — against ~78 min hand-driven for
  class 79 alone in August.
- First attempt (bivariate ansatz, 1936 unknowns, 10 min/prime, 7 primes
  without a lift) superseded and kept as evidence. Lesson: when a linear
  PDE has a parameter direction, sample it and solve the ODE.
- **Correction, caught by the watchdog from a `Set::wrsym` line**: probe and
  test assigned the conjugator to the Protected symbol `C`, so the
  "T equals T_old up to a constant" line was VACUOUS. Re-run with a plain
  symbol (`Scripts/diagonal_block_epsform_oracle.wls`): all three
  conjugators are x,y-free and invertible. Letters, spectra and the gate
  were never affected. Rule: never assign to `C`, `D`, `E`, `I`, `K`, `N`, `O`.

### (09:00-12:20) Standardization: benchmark first, then automate

- **Engine benchmark, identical inputs** (ledger frame, 4 subkernels, the
  170 classes other than the hard three): CANONICA 3125 s, 163/170 —
  refuses the 1x1 classes 16/68/84 and the bilinear 115 in under a second,
  caps out (3x300 s) on 26/33/118. Finite field 516 s but 149/170 — and
  every miss was an INSTANT failure, i.e. a blind spot of the driver, not a
  hard case. `Scripts/benchmark_diagonal_block_engines.wls`.
- Those 21 misses drove the standardization: reducible slice directions
  (variable swap, then SHEARED frames `w = s + lambda v` — a generic line
  keeps the monodromy, and a shear along a root direction linearizes a
  letter whose quadratic part factors); Lee normalization stalls
  (regular-point balances for normalization too, plus a stall guard);
  scalar blocks (direct dlog read-off, coefficient along a curve modulo q);
  zero blocks; fast failure on half-integer exponents feeding an
  **automatic chart retry** (the conic in both signs plus the
  `TransportChartCatalog` charts, ordered by "pulled-back alphabet linear");
  interpolation-degree reuse.
- `DiagonalBlockClassCampaign` writes `CanonicalizeClasses`-schema records
  (subkernel pool, optional CANONICA fallback, `ValidateCanonicalForm`
  re-check). **173/173 certified from the raw (v,w) representatives with no
  hints** (172 in 1843 s + class 77 alone 2950 s): 89 scalar, 83
  finite-field, 1 zero; 24 charts found automatically.
- Oracle vs the ledger: per-letter spectra identical and constant
  conjugation on every same-variable class; the three hard classes are
  identical to the Kallen-chart ledger forms after pulling the conic
  t-chart back (`Scripts/diagonal_block_cross_chart_oracle.wls`).

### (13:00-15:35) NumericalEps slice engine + canonical residue frame

The Libra slice with eps SYMBOLIC was the last large cost (class 77:
1547 s of 2950 s). Two observations removed it:

- The slice only has to deliver the residue tuple **up to one constant
  conjugation** (two normalized Fuchsian forms of the same one-variable
  system at a fixed generic regulator value differ by a constant gauge).
  So the whole Lee chain runs at **eps = 1/101 in Q(x)** — exact rational
  arithmetic, nothing floating point: integer parts by rounding, no
  factor-out step, Libra only for Poincare-rank-positive points (its
  rank-positive branch is regulator-free; conventions read from Libra's
  source). Class 79 slice 62 -> 1.5 s; class 77 1547 -> 1.8 s.
- The numeric frame leaves powers of 101 in the residues (100-259 digit
  entries), T inherits them and the solve needed >20 primes.
  `diagonalBlockCanonicalFrame` conjugates into the frame spanned by
  eigenvectors of SIMPLE eigenvalues of the residues (canonical up to
  scale) and fixes the scales by a spanning tree: integer residues with
  1-2 digit entries, and the solve lifts after 2 primes. (Echelon/Jordan
  eigenspace bases are NOT frame-covariant and made heights worse.)
- **Full campaign: 173/173 in 204.5 s wall** (1 main + 4 subkernels; dim 1
  90 classes < 1 s, dim 2 71 classes 130 s, dim 3 6 classes 43 s, dim 4 6
  classes 388 s), class 77 alone 189 s. Oracle-identical to the ledger
  including the cross-chart check. Records `ClassFormsFF_numeric/`.

### (15:30-16:20) A2/A3/A4: Codex's round-2 off-diagonal optimizations standardized

Codex delivered three external prototypes with frozen-fixture evidence
(`codex_ff_round2_handoff_assessment_2026-08-21.md`); all three are now in
the package and re-accepted here against the O2b oracle.

- **A3 (a-priori sparse support).** `finiteFieldStripPrepare` emits a
  `SupportCensus`: from valuations it bounds the gauge-numerator total
  degree by `denominatorTotalDegree + max(0, forcingInfinityDegree + 1)`
  with a closure certificate. The sampler builds only the retained
  `{px,py}` columns; the solver runs a shell-growth ladder with the full
  rectangle as fallback. **(9,7) 2144 -> 1568 unknowns, (9,6) 728 -> 548**,
  derived without opening the oracle.
- **A2 (held-out regulator sampling)**, now the default: construction
  prefix, all minimal-degree Pade splits retained, fresh held-outs reject
  the wrong ones, a failed held-out is promoted into construction data, a
  prime whose degree profile changed is rejected. The lift is taken first
  WITHOUT the exact check and guarded by an **unseen-prime residual**.
  **122 -> 70 regulator images.**
- **A4 (FLINT backend).** Codex's adapter installed unchanged at
  `FeynFacet/Backends/flint` (`build.sh` -> gitignored `bin/`; MANIFEST
  records libflint 3.0.1, LGPL-2.1+). The constrained core with all RHS
  goes to `nmod_mat_solve` when >= 256 wide; every imported solution is
  re-verified in Wolfram by the existing all-row residual checks; absence
  of the binary falls back to `LinearSolve`. Per-sample constrained solve
  **4.9 -> 0.35 s** on (9,7).
- **Acceptance** (gauge/residues/alphabet SameQ, exact residual zero):
  CF254 (9,6) 249.7 -> **157.1 s**; CF254 (9,7) 7254 -> **1446 s (5.0x)**.
  Per Codex's warning the three do not multiply: the remaining (9,7) cost
  is the point/row BUILD (~14 s per sample, the O2 evaluator), not the
  solve (0.35 s), interpolation (19 s), lift (2.4 s) or exact check (53 s).
  **The build is the next lever.** Record `frozen_M0/A2A3A4_acceptance.md`.

### Tests, process, environment

- New: `Tests/t_diagonal_block_epsform.wls` (23 checks — synthetic KZ block
  with an eps-dependent apparent locus, zero block, scalar block with a
  bi-quadratic letter, reducible slice direction solved in another frame,
  NumericalEps vs symbolic engine agreement) and
  `Tests/t_finite_field_round2.wls` (11 checks — support census, sparse
  probe, held-out solve exact/fewer images/agrees with deterministic, FLINT
  matches Wolfram). Existing FF tests green;
  `t_finite_field_adaptive_sampling` now pins
  `"RegulatorSampling" -> "Deterministic"` because it asserts the fixed
  pilot schedule.
- Wolfram license: **two MAIN kernels in total on this machine**. While
  Codex holds two, every wolframscript here fails with "product is not
  activated" — that is a seat refusal, not a broken install.
- Standing Opus watchdog (5-minute read-only rounds over a file-based
  watchlist) caught the `Set::wrsym` defect and several process facts; its
  liveness check is now `fuser` on the log file rather than a process-name
  pattern.
- Wolfram traps added to the record: `Return` inside `Do` exits the loop
  only; `ParallelSubmit` HOLDS its arguments (inject values with `With`);
  nested pure functions rebind `#1/#2` (use `Function[{a,b},...]`);
  `CoefficientArrays` drops the linear part when every equation is
  identically zero.
- **Found while verifying the handoff (pre-existing, not fixed)**: all 94
  exported symbols end the package load with NO usage message.
  `FeynFacet.m` defines the usages before `Begin["`Private`"]`, then each
  private file's `ClearAll[PublicSymbol, ...]` wipes them (ClearAll removes
  messages too). `BuildBasis` from the earliest sessions is affected
  identically, so this is long-standing and purely cosmetic — only
  `?Symbol` documentation is lost. Fix (fifteen mechanical edits, left for
  a session that can review and re-test): drop public symbols from the
  private files' `ClearAll`, or move the usage block after the private-file
  load. Recorded in `HANDOFF.md`.

## 2026-08-21 (evening) — independent check of the A2/A3/A4 standardization

- User asked for a check of the Opus-assisted standardization. Recomputed
  from stored artifacts (record: `BenchmarkStripBackends/frozen_M0/
  verification_2026-08-21/`): on CF254 (9,7) vs the frozen oracle and (9,6)
  vs O2b AND the original M0 census, gauge/residues/alphabet are SameQ and
  the exact Pfaffian residuals recomputed by independent code are zero;
  FLINT was the backend on 70/70 samples, no discards. Held-out mechanics
  probed directly at degrees up to (3,3)/(5,1): 4 -> 7 -> 10 images, correct
  degrees, profile-change rejection, grow-on-shortfall, learned profile on a
  second prime; the unseen-prime residual rejects corrupted lifts.
  `t_finite_field_round2` 11/11. The reconstruction guard was relaxed the
  honest way (explicit `CertificationMode -> "HeldOut"` carried into the
  result), and the lift is support-aware. Open, not fixed: prime-width guard
  missing in the O2 evaluator; degree-probe ladder wastes ~7 probes per
  rejected offset; unseen-prime check is a silent no-op when the reserve
  primes are in the prime list; suite test covers A2 only on a 1x1 block.
- Family inventory re-read from `FamilyEpsFormsCertified/
  certification_report.wl` and the root census: 91 families = 44 zero-root +
  31 single-root + 13 two-root + 3 triple-root (CF259; CF300/CF303 share one
  root triple). Two-root: 10 done, 3 open (CF231/CF265/CF305). CF385/CF408
  are solved (exact 2026-08-20 records) but uncertified only for schema
  reasons. The 37 "incomplete" = 29 zero-root + 3 two-root + 2 schema + 3
  triple-root.
- **Four open items fixed** (`FiniteFieldStripSolve.wl`; user request):
  width guard `SampleEpsFormStripAffine::width` for primes >= 2^31 (sampler
  and solver); degree-probe order via `finiteFieldStripProbeOrder` (shell 0,
  rectangle, then intermediate shells — an inconsistent rectangle ends the
  offset); reserve primes walked down from 2147483399 past the schedule and
  the one used recorded as `"UnseenPrime"`; `t_finite_field_round2` extended
  to 23 checks (held-out mechanics at (3,3)/(5,1), unseen-prime accept/reject
  on the stored A4 artifacts, reserve outside schedule, width guard, probe
  order). (9,6) acceptance re-run with the new order: 157.1 -> 140.9 s,
  oracle-identical (`frozen_M0/verification_2026-08-21/probe_order_rerun/`).
  Regression tests: the five other finite-field tests green. Note added to
  `Backends/flint/build.sh`: the adapter uses the FLINT 3.0/3.1 `rows[]`
  layout and will not compile against FLINT >= 3.2 without porting.
- **Usage messages fixed** (user request). Measured first: the handoff's
  "all 94 exported symbols lack usage" was wrong — `BuildBasis::usage` was
  present and `Cut` kept `HoldAll`; exactly the 34 public symbols named in
  nine private files' `ClearAll` lists lost theirs (DiagonalBlockEpsForm,
  EpsFormStrip, FamilyEpsForm, FiniteFieldEpsForm, FiniteFieldStripSolve,
  LibraEpsForm, ObservableTransport, Simplification, TransportCharts).
  Those files now `Clear` the public symbols (drops definitions so a re-Get
  stays clean; keeps messages, attributes, options) and `ClearAll` the
  private ones. After load: 94/94 with usage, attributes/options unchanged.
  New `Tests/t_usage_messages.wls`; the tests of the nine modules re-run
  as regression tests (results below).
  Regression batch after the usage fix (`t_usage_messages`,
  `t_diagonal_block_epsform`, `t_family_epsform_module`,
  `t_transport_chart_extension`, `t_observable_transport`,
  `t_eps_form_strip`, `t_libra_family_eps_form`,
  `t_physical_variable_coefficients`, `t_finite_field_round2`): 8 green,
  `t_libra_family_eps_form` RED — verified pre-existing (identical failure
  with the edit reverted). Root cause: `masterTransportChartBlockSpec`
  gained a ninth argument (`coefficientField`, multiquadratic frame work,
  MasterTransport.wl of 2026-08-20) and `TransportFamilyInChart` was
  updated, but the call in `LibraEpsForm.wl` was not, so the chart route
  of `LibraFamilyEpsForm` returned an unevaluated expression
  (`ChartBlockCompositionFailed`) for every chart family. Fixed by passing
  `Lookup[data, "CoefficientField", "Rational"]` as `TransportFamilyInChart`
  does; test 4/4. No stored result carries that status (grep over Results,
  WORKLOG, plan), and the 2026-08-19 two-root Libra runs predate the
  change, so no verdict was contaminated. Logs:
  `frozen_M0/verification_2026-08-21/usage_fix/`.

## 2026-08-21 (late evening) — Codex epsilon-form audit: adopted with a scope correction

- Codex (`External/CodexExchange/codex_epsform_stress_2026-08-21/`) found
  three defects by adversarial examples: the diagonal gate accepted a
  regulator-dependent letter (`x + eps`); `VerifyEpsFormStrip` accepted any
  exact Pfaffian identity regardless of letter/residue structure; the
  unseen-prime reserve was a bounded 65-prime window.
- **Measured before adopting (text-level census, after a first Wolfram
  check of mine was invalidated by the `Module`-local `eps = Global`eps`
  self-assignment trap): EVERY deep-rung result on file — frozen (9,7),
  M0/O2b/A2-A4 (9,6) and (9,7), CF48, finite-field and Maple — has
  residues with `c/(a+eps)` factors.** CF254's certified family record
  was built from exactly such strips (its StripSolvers list the FF route
  and Codex's raw (9,6) lift): `family_epsform_sector.wls` uses only the
  strip gauge, then runs CANONICA `TransformDlogToEpsForm` per sector, and
  the family certifier asserts the epsilon form. So the rung's contract is
  a DLOG FORM (letters eps-free, residues x,y-free, eps allowed in the
  residues); Codex's `ConstantResidues` (eps-free) gate would have refused
  the strips that built CF254. Recorded in CLAUDE.md.
- Adopted: diagonal gate requires `LettersEpsFree` (checked: no class
  record has an eps-dependent letter); `VerifyEpsFormStrip` structural
  gate before the exact pass with `DLogFormCertified` (acceptance) and
  `CanonicalEpsFormCertified` (eps-free residues, reported); typed
  `ReconstructEpsFormStrip::dlog`; `InstallEpsFormStripSolution`
  recomputes the two dlog conditions; `finiteFieldStripReservePrimes`
  unbounded; solver stops with `::dlog` when a lift passes the unseen-prime
  residual but is not a dlog form (more primes cannot help). Usage texts
  updated; NumericalEps aliasing limit (|eigenvalue| >= 51) documented in
  the module header, no code change (Codex's recommendation).
- Tests: `t_finite_field_eps_form` rewritten (dlog-form acceptance of the
  (9,6) lift, refusal of eps-letter / kinematic-residue variants before
  the exact pass, benchmark lift reproduces the stored gauge; input record
  copied into `Codex/TwoRootCF254Sector9Lower/` — no test reads `~/FACET`
  any more); `t_finite_field_strip_solve` (installation positive, two
  refusals); `t_diagonal_block_epsform` 25/25. Reply to Codex:
  `External/CodexExchange/fable_epsform_audit_reply_2026-08-21.md`.

## 2026-08-22 (00:00-02:00) — parallel architecture, method benchmark, dim-3 defect, finite-field-first route

- **Two-root campaign (user go 23:00) launched 23:10 as 3 pool missions
  and STOPPED 23:21 by user order** ("fix the parallel problem, we need it
  really working; first test our strategy"). Measured: Wolfram forbids
  parallelism in subkernels (`LaunchKernels::subnopar`) and the licence
  grants exactly two main kernels (third refused). **Task broker built**
  (`FeynFacet/Private/TaskBroker.wl`, `Design/KernelPool.md`): a family
  mission on a pool subkernel submits its finite-field sample batches and
  CANONICA degrees 1-3 as tasks into the same pool; the main dispatches them
  to free subkernels; helpers cache record/preparation/CANONICA; failed tasks
  recomputed locally. Driver `Scripts/family_epsform_pool.sh <out> <pool> <N>
  <families>` (N subkernels = the option; families <= N-2 in flight;
  certification per family). Pool loop 3 -> 1 s. Measured CF254 (9,7), 3
  helpers: 446 -> 357 s, oracle-identical; CANONICA ladder 180 -> 97 s.
  Corrected numbers: serial (9,7) is 446 s on a quiet machine (the 1446 s
  acceptance figure was under 4-worker contention, pre probe-order fix).
- **Off-diagonal block method benchmark** (`BenchmarkStripBackends/
  StripMethods_2026-08-21/summary.md`): 20 real blocks x {CANONICA ladder,
  Maple, finite field}, each alone on one kernel, all results independently
  dlog-certified. Finite field 20/20 in 872 s; CANONICA 15/20 in 2790 s and
  3-130x slower where both solve; Maple 13/20, never faster, fails on every
  hard block (cancelled at 1200 s; 08-20: fails after 6300 s). **Route
  changed** in `family_epsform_sector.wls` (FACET_STRIP_ROUTE, default
  FiniteFieldFirst): dlog recognition -> finite field -> CANONICA/Maple as
  the last fallback; `SolveEpsFormStrip` accepts an empty degree list
  (recognition only). End-to-end on CF34 through the pool driver: solved 6 s,
  certified 0.4 s.
- **Defect found by the benchmark and fixed**: `maximumExponents` matched a
  row of three {numerator, denominator} pairs as a monomial table whenever a
  block has dimension 3 and read coefficient residues as exponents: power
  tables of p-1 entries per point (9 s per sample on the 48-unknown CF254
  (12,11), kernel death by memory at 31-bit primes). Leaf-level pattern now;
  (12,11): 0.17 s per sample, solve 1.5 s. Regression checks in
  `t_finite_field_round2` (25/25). CF231/CF254 each carry a dim-3 block.
- **Driver defect**: the wave loop of `family_epsform_pool.sh` kept running
  after the last family finished (empty-array expansion under set -u) --
  10 minutes lost; fixed. User correction recorded: the Opus watchdog is
  mandatory for any background compute (`Design/Watchdog.md`, CLAUDE.md
  "Long runs", `Scripts/watchdog_register.sh`); a bash Monitor is not a
  substitute. Terminology slip corrected: "off-diagonal block (k,j)", never
  "strip", in prose.
- **Blockwise Libra route re-read** (Codex `~/FACET/Codex/General/
  LibraTwoRootBlockwise_20260819`, our `Scripts/libra_saved_blockwise_epsform.wls`
  + `libra_checkpoint_factor_dependence.wls`): per pair (i,j) with a nonzero
  coupling, Libra `FuchsifyBlock` on the LOCAL two-block subsystem (balances,
  no gauge ansatz), embedded into the family; then ONE global Libra
  `FactorDependence` on the residue matrices; then CANONICA dlog. Solved
  CF232/236/240/319/321/385/408 in 1-6 min per family (local Fuchsification
  61-287 s for 17-84 pairs; factorization 3-50 s). Failed on exactly the
  hard classes: `FuchsifyBlock` TimedOut (1200 s) at the FIRST hard pair
  (CF231/CF305 (8,7); CF254 (9,8); CF265 (14,13)); nothing after was tried.
  The finite-field affine solve takes exactly that pair's data (e, c,
  coupling) as input, and `libra_resume_blockwise_checkpoint.wls` already
  resumes Libra after an exact off-diagonal gauge -> the hybrid ladder
  (Libra blockwise with a short budget -> finite field for the pairs that
  time out -> FactorDependence -> dlog -> family certificate) is the
  candidate production route for the three open families.

## 2026-08-22 (02:00-03:00) — checks separated from the calculation; assembly and sampler optimizations

User decisions (saved to memory): core limit 4 tonight, no campaign; the
three open two-root families run in the day; "checks shouldn't be written
into the calculation -- one test of the final family result; fine-grained
checks are for development"; a numerical per-block Pfaffian check is fine;
the C build may use 16 cores.

- **Assembly profiled** (CF254, dim 23, `TransportFamilyInChart` AssemblyOnly,
  626 s): chart pullback 91 s, class-form pullback 41 s (block 12 = class 77,
  40 s), conjugation through diag(T) 49 s -- and 446 s of exact identities
  (source curvature, per-block inverses, diagonal-equals-declared-form, and
  361 s for the curvature of the conjugated 23x23 connection).
- **Check level** `FACET_CHECK_LEVEL` (Development default; Production is the
  pool driver's default): `masterTransportAssemble`/`PullBackSystem` evaluate
  their guards exactly at random rational points (`masterTransportPointZeroQ`)
  and take flat(A') from gauge covariance; `VerifyEpsFormStrip` gained
  "Method" -> "Numerical" (Pfaffian residuals at random rational points, ~1 s);
  `SolveEpsFormStripFiniteField` "FinalCheck" -> "Numerical" accepts a lift on
  the unseen-prime residual + numerical residuals + dlog structure and
  records "Certificate" -> "NumericalResidual" with ExactDLog deferred; the
  sector script skips its per-sector identities (the former `stageGauge`
  recomputed the expression defining its own input -- vacuous) and its
  own family gate, writing "CandidateEpsilonForm" for the certifier; the
  exact statement is `CertifyFamilyEpsilonForm`, run by the driver.
  Measured: CF254 assembly 610.5 -> 97.9 s, identical connection and
  inverses; block solves with the numerical final check, gauge/residues
  SameQ to the oracles: (9,6) 141 -> 69.5 s, (9,7) 446 -> 368 s (before the
  sampler change below). Test `Tests/t_check_levels.wls` (10 checks).
- **Sampler restructured**: the residue columns were built from the tensor
  of forcing coefficients (alphabet x upper x lower x 2 x upper x lower,
  zero except one entry per triple: 6656 rational evaluations per point on
  (9,7)); now the alphabet x 2 dlog forms are evaluated once per point and
  scattered into the residue columns. Bit-identical systems (rank, nullity,
  particular and nullspace hashes on (9,6), (9,7), (12,11)); build per
  50-point sample on (9,7) 20.7 -> 5.9 s on an E-core.
- Regression batch (21 tests) running on a 3-subkernel pool with the watchdog;
  end-to-end production run of CF34 through the pool driver to follow.
- **Results of the night (03:00-04:00)**:
  - Regression batch on the pool: 18/21 OK; `t_finite_field_preparation`
    and `t_transport_chart_extension` failed ONLY on reused subkernels and
    pass standalone (tests assume a clean Global` context) -> KernelPool
    `fresh_*` missions (subkernel closed and relaunched after the mission)
    + `Scripts/run_tests_pool.sh`; `t_chart_transport` failed standalone
    too: its T2c called `masterTransportChartBlockSpec` with eight
    arguments (the same stale call as LibraEpsForm.wl's, red since
    2026-08-20); fixed -> 29/29.
  - End-to-end production run (CF34 through `family_epsform_pool.sh`,
    `FACET_CHECK_LEVEL=Production`): candidate record in 6 s, certified
    exact by `CertifyFamilyEpsilonForm` in 0.3 s, driver exit 0.
  - A/B of the sampler on identical (9,7) samples in one kernel: build
    15 s -> 2.9 s per sample (5x), solutions identical. Full (9,7) solve
    in a POOL SUBKERNEL with the numerical final check: **187 s** (per
    prime 13-16 s, sampling 105 s, interpolation 19.5 s, lift 2.5 s,
    numerical check 2 s) against 446 s at 23:47 and 1446 s in the frozen
    acceptance; gauge/residues SameQ to the oracle.
  - Open measurement: the same builds run ~3x slower in a `wolframscript`
    MAIN kernel than in a pool subkernel (A/B 2.9 s vs ~1.0 s per sample;
    not $HistoryLength; cause unknown). Production and all benchmarks run
    as pool missions; main-kernel timings (incl. the method benchmark
    table) are valid as ratios only.
  - C build decision: sampling is now 105 of 187 s on the hardest block;
    a C row build would give ~1.7x more on such blocks (not 3-5x) -- worth
    doing later, not tonight; 16 cores authorized for it.
- **Full suite on the pool (04:00-04:13)**: 47 tests, fresh subkernel per
  test, 3 subkernels, 13 min 24 s: 44 OK. Non-OK, all explained:
  `t_canonica_scheduler` launches its own subkernels (impossible inside a
  pool subkernel; passes standalone), `t_reconstruction_ghost` asserts a
  FireFly wall-time baseline (25 s vs 18.8 s under load; its exact
  agreement assertions pass), `t_wolfram_traps` pre-existing (2/10 pin a
  Libra symptom that no longer reproduces). A first attempt corrupted 7 of
  34 results through a race in the new fresh_* mechanism (the Parallel
  scheduler reused a just-freed kernel 1 s before the server closed it);
  fixed: a fresh mission writes its record to `running/<name>.kernel.result`
  and blocks its kernel until closed, a persistent claim under
  `running/claims/` makes re-runs of orphaned evaluations return DUPLICATE,
  and a mission whose kernel vanishes is requeued once (was filed
  KERNELLOST). Re-test clean (no KERNELLOST/FILEGONE/rotated logs).

## 2026-08-22 09:56 PDT — day run of the three open two-root families (Fable)

User go ("Now on 8 subkernels, run the 3 unresolved 2 roots; let there be
watchdog and reasonable time to finish"). Launched
`Scripts/family_epsform_pool.sh` with one main (the KernelPool) + 8
subkernels on the P-cores, families CF231/CF305/CF265 in parallel (3 busy,
5 helpers for the task broker), finite-field-first route, production check
level, certification into `FamilyEpsFormsCertified/` per family.
Output: `FamilyEpsFormsSolving/tworoot_2026-08-22/` (driver.log,
campaign_status.tsv, <CF>/run.log); pool in the session scratchpad
`dayrun_pool/`. Opus watchdog spawned in the same turn (watchlist
`scratchpad/watchdog_dayrun/`). `tworoot_status.py` priors re-based to the
08-22 pipeline (assembly 180 s, small sector 30 s, large 60 s per lower
sector, finish 300 s); first prior-based ETA 11:03 for all three.

### 10:16 — attempt 1 stopped: task broker never engaged

User observation: CPU ~16 %, only the three family kernels busy. Cause:
`brokerQ` compared the pilot's seconds PER SAMPLE (about 1 s on these
blocks after the sampler fix) with `BrokerMinimumSeconds` = 1.5, so every
prime (32 regulator values, 35-65 s) ran on the family's own subkernel and
the five helpers idled; CF231 spent 20 min on one block of sector 8.
Fixes (FeynFacet/Private/FiniteFieldStripSolve.wl, TaskBroker.wl):
- the broker decision uses one prime's worth of samples on one kernel
  (pilot seconds × regulator schedule ≥ `BrokerMinimumSeconds`, now 8 s);
- `taskBrokerRun` split into `taskBrokerSubmit` + `taskBrokerCollect`;
  `taskBrokerSampleBatch` farms `free` shares and computes the last share
  on the mission kernel itself (it idled before); with no free helper it
  computes locally instead of queueing; collect polls every 0.25 s;
- `taskBrokerFreeKernels` reports 0 when the pool is saturated.
- `Scripts/tworoot_status.py`: sector-done count tolerates the pool's
  wrapped Print lines (was a crash).
Attempt 1 archived as `tworoot_2026-08-22_attempt1_brokeroff` (no family
record produced; CF231 sector 8/12, CF305 8/19, CF265 14/19 at 22 min).
Second finding during validation on the (9,7) fixture (pool of 8): the
pilot's `SamplingSeconds` is the row build only (0.24 s after the sampler
fix); the modular solve now dominates a sample (~1.5 s), so the decision
uses the pilot's whole wall time minus plan discovery and nullspace
(`PlanDiscoverySeconds` added to the sample record). Validation
(`brokerfix97c`): gauge and residues `SameQ` to the frozen oracle, dlog
certified; held-out round per prime 14-16 s -> 7-10 s on 5 shares (4 helper
tasks + the mission kernel), sampling stage 107 -> 70 s.

### 10:35 — attempt 2 launched (same command, pool `dayrun_pool2`)
First block of CF231: "Broker decision ... -> True", `[broker] ff1000003: 3
tasks, 3 results, 8.1 s`; helpers busy. Watchdog respawned on the attempt-2
watchlist (`scratchpad/watchdog_dayrun2/`).

### 10:54 — watchdog anomaly: CF231 and CF305 lose block (8,7) to the fallback

Both families: every prime validated on held-out regulator values, yet
`SolveEpsFormStripFiniteField::failed` after 11 primes, a wasted full
regulator-schedule repeat (8 min), then the CANONICA/Maple fallback.
Offline diagnosis on the saved per-prime records of CF231 (8,7)
(`scratchpad/lift_diag_cf231_87.wls`; 11 primes, 1568 coordinates, 19532
coefficients): normalization columns and degree patterns identical across
primes; lift fails with `ReconstructEpsFormStrip::modulus` (quieted in the
solver, hence the silent log); 1166 coefficients reconstruct to the same
19-34-digit rationals at 10 and 11 primes, ~3100 "reconstruct" to 49-50
digit rationals = the reconstruction bound of 11 × 31-bit primes, and the
failure count does not fall with the prime count: the coefficients are
taller than the modulus allows, the ansatz is right.
Fix (FiniteFieldStripSolve.wl): option `"MaximumPrimeCount"` (40): the
configured primes are extended with reserve primes (first reserve prime
stays the unseen one) while the lift is modulus-limited; the lift's
failure reason is logged ("Lift after k primes: combined modulus too small
... (bound ~N digits)"); a modulus-limited failure no longer triggers the
full-schedule retry. Offline validation started 11:02 on the saved 11
primes + extension (`scratchpad/ext87/run.log`, standalone kernel on
E-cores, campaign untouched).

### 11:07 — attempt 3 launched (pool `dayrun_pool3`)
User decisions mid-run: CANONICA/Maple removed from the automatic loop
(`family_epsform_sector.wls`, finite-field-first route: an unsolved block
ends the family with exit 2 and the block record; CANONICA/Maple are
manual tools). Attempt 2 archived as `tworoot_2026-08-22_attempt2_modulus`
(CF265 had reached sector 14/19; CF231/CF305 were in the fallback on
(8,7)). The offline extension run (153 s per prime on a standalone kernel
on E-cores, 6x slower than the pool) was stopped at 12 primes once the
mechanism was seen working; the campaign does the same sampling at ~25 s
per prime. Watchdog respawned (`scratchpad/watchdog_dayrun3/`). Expected
finish 12:30-13:00.

### 12:00-12:50 — results of attempt 3 so far
- **CF231 certified** (`FamilyEpsFormsCertified/family_epsform_CF231.wl`,
  exact=True, solve 2703 s, certificate 456 s). Block (8,7) closed at 15
  primes (bound ~69 digits).
- **CF305 failed at block (18,15)** (sector 18/19, 62/69 blocks solved,
  state in `CF305/sector_state_CF305_standard.wl`, block record
  `CF305_18_15_unsolved.wl`). Not a prime budget: the degree probe is
  inconsistent at every offset (0 primes spent). Structural cause: the
  forcing carries 1/(1+4 eps), a regulator resonance from sector 18's
  diagonal eps-form. Offline tests on the saved block
  (`scratchpad/cf305_1815/`): denominator widened to all 11 letters
  (new optional record key `GaugeDenominatorFactor`, fingerprinted) still
  inconsistent at offsets ≤ (2,2); offsets (4,4)-(8,8) give a consistent
  probe and a stable lift (7-digit integers, eps/(1+4 eps) dependence,
  stable 10-40 primes) that FAILS the exact and numerical Pfaffian
  identities: a fit at the sampled points only (ansatz outran the point
  budget; the unseen-prime residual rejected it in the run). Conclusion:
  no rational gauge within the block alphabet with the diagonal blocks
  fixed; remedy is upstream (sector-18 class basis without the resonance
  factor, or a new letter) or manual CANONICA/Maple — user decision.
- CF265 running, sector 15/19 at 12:50 (its hard block (15,11) closed at
  offset (0,2)); watchdog re-armed.
- Lost ~12 min of diagnosis to a standalone kernel that survived `kill`
  (only `kill -9` of the whole wolframscript tree freed the licence).

### 13:00-13:30 — CF305 block (18,15): general solution; solver defect found and fixed

User: "for 305's stuck block, try to find a general solution and update
our package."  Done as an order-by-order obstruction analysis in the
regulator, now a package function, which then exposed a solver defect.

**`EpsFormStripObstruction[record]`** (new, `FeynFacet/Private/
EpsFormStripObstruction.wl`, usage in FeynFacet.m, `Tests/
t_epsform_obstruction.wls` 7/7): with D = Σ eps^k D_k and the block
equation dD = eps(eD − Dc) + bbar − eps Σ K_a dlog L_a, the order-k form
w_k = Σ_m (e_m D_{k−1−m} − D_{k−1−m} c_m) + B_k is closed and rational;
it is d(rational) + Σ c_L dlog L with constant c_L iff its residue along
every polar curve is constant (exact one-variable residues on transverse
rational lines at every root, RootReduce-compared; points where another
polar curve vanishes are excluded — a line through such a point gave a
false "non-constant residue" in the first hand calculation, retracted).
Verdicts: MissingLetters (curve outside the alphabet with nonzero
constant residue; the sector script now supplies it as "ExtraLetters"
and repeats the solve once), NonConstantResidue (proof that no rational
gauge exists with the present diagonal forms — the pair needs the
blockwise Libra balances), PrimitiveNotRational, NotClosed, or
NoObstructionToOrder n with the gauge series and its numerator degrees.
Starts at order 0 (eps^0 forcing allowed, residues must then vanish) and
accepts eps-dependent e, c.  Option "Alphabet" overrides the letters.

**CF305 (18,15)**: clean to order 10 in 5 s; D_k numerator total degree
9 for all k, A3 denominator; residues geometric, D_k/D_{k−1} = −4 for
k ≥ 2, so D = eps D_1/(1+4 eps) and K_L rational with the (1+4 eps) pole
— an exact rational gauge of exactly the assumed shape, verified with
VerifyEpsFormStrip "Exact" (Pfaffian residuals zero, dlog certified).

**Solver defect** (`finiteFieldStripSupport`): the certified support was
the bidegree rectangle (denominator degrees + offset ≤ 2 per variable)
intersected with the total-degree simplex.  This block's numerator
(D_1's numerator times the cubic the common A3 denominator adds) has
x-degree 6 with denominator x-degree 3 — total degree 12 = the valuation
bound, so allowed — and every rectangle probe up to offset (2,2) was
"inconsistent".  Fix: certified support = the whole total-degree simplex
(bound + shell); shell 0 always probed first; power tables sized by the
support; the unseen-prime residual uses the lift's recorded
"GaugeSupport".  Result: (18,15) solves in 7.3 s at offset (0,0), shell
0 (91 monomials), 3 primes, exact dlog certified, eps-free residues.
Regression: t_finite_field_round2 25/25 (Support124 → Support136 and the
596-unknown probe count are the intended new values), t_finite_field_
strip_solve and t_finite_field_eps_form green.  Sector script: on a
finite-field failure the certificate is computed (900 s cap), logged,
stored in the `_unsolved.wl` record ("ObstructionCertificate").
Earlier widened-denominator/big-offset experiments (`scratchpad/
cf305_1815/`) are superseded: their "consistent" probes were
underdetermined fits, correctly rejected by the unseen-prime residual.

Run state: CF265 alive, sector 16/19, inside CANONICA
TransformDlogToEpsForm (1800 s budget) since 12:58 — that per-sector
CANONICA step (and the 30 s complete-sector attempt) are still in the
loop; user to decide.  Four helper subkernels released for Codex (kill
of idle subkernels; pool keeps serving with 4; a second main launches 4).
CF305 rerun with the fixed solver needs a pool restart (old code in the
running subkernels) or the second main; resumes from its sector state.

### 14:30-17:00 — CF305 and CF265 solved and certified; the final check rewritten

**Runs.** CF305 resumed at sector 18 (pool, 8 subkernels, CPU list 0-19):
(18,15) closed at once (support learning 55/91), sectors 18-19 done by
15:02, family regulator factorization, record written 15:04 (1904 s).
CF265: the resumed run failed at (18,16) three times before the causes
were found and fixed (see below), then ran standalone in 782 s (sector
19 in seconds per block, family factorization 132 s).  Both records
re-written at 16:50 with the recovered block order (see bug 3) and
**certified exact at 16:53, 17.8 s each**.  All three open two-root
families are now in `FamilyEpsFormsCertified/`.

**Bugs found and fixed today after the launch.**
1. A block accepted as "AlreadyDLog" may carry an eps^0 residue (CF265
   (17,16)); no rational gauge removes it and it poisons the next row's
   forcing ((18,16): every probe inconsistent, obstruction certificate
   "NotClosed").  Fix: `factorTruncated` in the sector script —
   `FactorFamilyRegulatorDependence` on the truncated connection
   (rows 1..k) after each completed row and at resume (50 s on 30x30).
2. Strip checkpoints and per-prime artifacts of a block computed before
   a transformation were reused: checkpoints now carry a hash of the
   connection they were built on ("ConnectionHash"), stale per-prime
   artifacts are ignored and overwritten (they aborted the solve before).
3. A resumed run wrote the record's "Blocks" in class-assignment order
   while the cached OriginalA/Ranges are in the assembly's order → the
   certificate permuted the source wrongly (CF305/CF265 "GaugeIdentity
   False" with every block nonzero).  The state now caches "Blocks"; an
   old state recomputes the assembly and verifies it against the cached
   connection at random points before recovering the order.
4. Per-sector CANONICA removed from the loop (user decision): the
   complete-sector attempt and `TransformDlogToEpsForm` (1800 s per
   sector, zero gain on CF265 sector 16) are gone; the residues'
   regulator dependence is removed by `FactorFamilyRegulatorDependence`
   (Libra FactorDependence on exact rational samples, symbolic identity
   as acceptance; `Tests/t_family_regulator_factor.wls` 7/7).

**Final check rewritten** (`FeynFacet/Private/FamilyCertificateModular.wl`,
default `"IdentityMethod" -> "Modular"` of CertifyFamilyEpsilonForm;
"RandomPoints" (exact rationals) and "Symbolic" kept): every matrix entry
compiled once into integer coefficient/exponent arrays; all identities
(inverse, gauge, flatness, eps-factorization e2 A(e1) = e1 A(e2), dlog with
constant residues by one modular solve per prime, source flatness)
evaluated at 12 random points modulo 3 random 24-bit primes with power
tables and packed dot products; derivatives on the coefficient data; the
chart connection by the chain rule at the mapped point (no symbolic
pull-back); Schwartz-Zippel degree bound, primes, points and the failure
probability recorded in the certificate (CF231 4.6e-77, CF305 1.7e-65,
CF265 6.8e-68).  Times: CF231 456 s → 10 s (same verdict as the symbolic
certificate of 12:00), CF305/CF265 (32x32) >60 min unfinished → 17.8 s.
`Tests/t_family_certificate_modular.wls` 8/8 (corrupted transformation and
corrupted eps-form rejected at the right checks); t_certify_family_
epsilon_form, t_exact_family_epsilon_form_q, t_family_epsform_module green
with the new default.

**Benchmarks** (`BenchmarkStripBackends/SupportStrategy_2026-08-22/`):
simplex vs sparse support on 27 blocks (sparse wins only on the (8,7)
class, 770 vs 1180 s; simplex wins or ties elsewhere and the sparse
ladder did not finish (15,11) in 26 min); simplex + support learning on
the 7 hardest: (8,7) 817 s, (15,11) 984 s, (15,14) 252 s — the production
setting (`SupportStrategy` "SimplexFirst", `SupportLearning` True).

### 18:05-19:00 — final checker hardened after Codex's adversarial review; stress on all cores

Codex's assessment (`External/CodexExchange/codex_final_checker_stress_
2026-08-22/`): five P0 (empty alphabet accepted; uncombined sums lose
letters; dlog rank recorded but not gated; residue reconstruction not
gating and not sticky; degree bound underestimated — no source-flatness
term), P1 (fitted points reused as validation; duplicate primes;
bad-characteristic term absent from the bound), P2 (union multiplier,
e2 = e1, no replay data, no overflow guard).  Why missed: tests were real
records plus natural corruptions, not adversarial inputs per check; checks
initialised True; diagnostics not gated; aggregate degree formula; no
held-out validation.  All fixed (`FamilyCertificateModular.wl` rewritten:
Together before compile and letter extraction; checks start False; full-
rank training then fresh validation points; rank-deficient primes
discarded; CRT residues across primes, reconstructed and verified at every
prime, adaptive prime count with dlog-only extra trials (CF231's residues
reach 101 digits: 33 primes); per-identity degree propagation; separate
error terms `IdentityErrorBoundIdentities`/`...DLog`/`...GoodCharacteristic`,
`Probabilistic -> True`; characteristic-zero guard point for inverse,
gauge, flatness, eps-factorization and the dlog identity with the exact
residues; distinct primes, e2 != e1, seed/points recorded, p^2*terms <
2^62).  One self-inflicted hang found by Codex's forced-prime fixture (the
adaptive loop spun when no new prime could be drawn) fixed.
Stress (two lanes on all cores): Codex adversarial suite — 4 controls OK,
all 8 EXPOSE exploits closed; real suite — CF265/CF305 certify (42/79 s);
`t_family_certificate_modular` 15/15; certificate tests green; CF231/CF265/
CF305 re-certified exact.  Reply note: `External/CodexExchange/
fable_final_check_2026-08-22/fable_reply_to_checker_assessment_2026-08-22.md`.
Finding for the physics: CF231's residues are up to 101 digits (basis
normalization from CANONICA's per-sector constant transformations) —
flagged as a quality issue before transport.

### 19:01 — zero-root campaign launched
29 families (CF12 CF16 CF34 CF67 CF71 CF123 CF198 CF199 CF201 CF204 CF207
CF209 CF211 CF213 CF215 CF217 CF218 CF262 CF263 CF267 CF269 CF301 CF308
CF311 CF360 CF390 CF393 CF404 CF415; dims 4-23) on a fresh 8-subkernel pool,
CPU list 0-19, 6 families at once, finite-field-first, production check
level, modular certificate per family.  Output `FamilyEpsFormsSolving/
zeroroot_2026-08-22/`, pool `scratchpad/zeroroot_pool/`, watchdog
`scratchpad/watchdog_zeroroot/`.

### 19:01-19:24 — zero-root campaign: 29/29 certified; three more solver defects found and fixed

Pass 1 (pool, 8 subkernels, all cores): 21 certified in ~3 min (seconds
per family), 6 `solve-failed`, 2 hung.  Causes, all in the solver, all
fixed:
1. CF67: support learning shrank a support valid at the pilot point but
   inconsistent at other regulator values ("SamplesInvalid") — the
   learned-support pass now falls back to the full certified support
   (`$finiteFieldLearningPass`, fallback in SolveEpsFormStripFiniteField).
2. CF209/211/213/217/311: `PlanNormalizationDiscoveryFailed` →
   `NormalizationInvalid` — the affine freedom contained pure constant-
   gauge directions (e and c sharing eigenstructure) that residue columns
   cannot fix; `finiteFieldStripNormalizationColumns` now takes residue
   columns first and extends with gauge columns (plan discovery and both
   interpolation paths).  The obstruction module no longer calls nonzero
   order-0 residues an obstruction (they are a regulator pole in the
   residues, absorbed by the sector-level factorization; recorded as
   `RegulatorPoleResidues`).
3. CF215/CF360 hung 15 min at full CPU in the "already dlog" recognition
   step (CANONICA's checker on a 2x2 block) — recognition removed from
   the finite-field-first route; the finite-field solve finds the trivial
   gauge in seconds.
Also found: an earlier global replace had put the solver's output keys
(ProbeCount, DegreeProbe, SelectedSupportKind) into fullRetry's option
list and the per-prime artifact record; cleaned.
Pass 2 (fresh pool): CF209/211/213/215/217/360 certified in seconds;
CF67 (learning fallback) and CF311 (resumed from its sector-17 checkpoint
after I stopped the pool too early) certified standalone.
**Inventory: 86 of 91 families certified.**  Open: CF385/CF408 (solved,
blockwise schema adapter), CF259/CF300/CF303 (triple-root).

### 19:29-22:10 — CF385/CF408 certified; the 40-master scaling wall found and removed; adversarial solver test

Mistake first: CF385/CF408 had been solved on 08-19/20 (blockwise
Libra records, final results per the 08-21 note) and I re-solved them
from scratch — the same redundant run the worklog had already recorded
once.  The reruns then hit a scaling wall at ~40 masters: CF385 twice
allocated >30 GB within a minute of finishing a sector, the first time
taking the WSL VM down (restart 21:11); I also restarted CF385 on the
second main licence and cores 0-9 while Codex/GPT needed them (user
correction; resource rule from now: one main + half the CPUs for them,
pools with 4 subkernels).  Per the user's direction the point was the
package, not the result, so the wall was traced with a synchronous
memory trace (`FACET_MEMTRACE`; stdout of wolframscript is block-
buffered, so log lines cannot date a blowup):
1. CANONICA's `TransformDE` in the sector completion (dead since the
   per-sector TransformDlogToEpsForm was removed) — removed.
2. The sector completion inverted the full n x n gauge symbolically and
   Together'd n^3 products; CANONICA's `NextEquationD` did the same work
   per block — replaced by blockwise formulas (T = 1 + D, T^-1 = 1 - D,
   A' = A + A D - D A - dD; S' = S + S D; block equation bbar = A_kj -
   Sum_m D_km A_mj): sector 33 of CF385 applied in 7 s, sector 34's 33
   blocks in 90 s at 0.4 GB.  CANONICA is now out of the loop entirely
   (kept as a library for letters).
3. Products with the constant T(eps) of the regulator factorization
   (`familyRegulatorConjugate`/`familyRegulatorSparseDot`): entry by
   entry over T's nonzero pattern instead of the dense triple Dot.
4. **The actual 30 GB consumer**: the per-sector census `badStrips` used
   `zeroQ` = `masterTransportZeroMatQ`, which falls through to `Simplify`
   on every nonzero entry (hundreds of ~300 KB rational functions per
   sector on a 44-master family).  For rational entries `Together === 0`
   is complete; replaced.  CF385 then finished from its sector-34 state
   in 6 s, certified exact in 33 s (peak 0.3 GB); CF408 sectors 27-29 in
   7 min at 0.76 GB (the old code: 18+ min and 22 GB for sector 27
   alone), certified exact in 31 s.  Also: regulator values at a pole of
   the forcing are now discarded (CF408 (7,4), CF385 (19,10)).
**88 of 91 families certified**; open: the triple-root CF259/CF300/
CF303 (GPT/Codex exploring with their main + 4 subkernels).
Adversarial solver test `Tests/t_finite_field_adversarial.wls` (13
checks: tall residues, off-rectangle numerator, eps^0 dlog part, equal
diagonal blocks, pilot-point support shrink, poles at schedule values,
resonance residues, an eps-dependent letter that must be rejected, the
trivial block's speed) 13/13, every constructed block solved in < 1 s.
`Scripts/adapt_blockwise_record.wls` (composition of the 08-20 blockwise
records into the standard schema + certificate) written but unused: the
package now solves these families itself.

## 2026-08-22 (22:30-23:10) — per-sector regulator factorization: need established, cost cut 8x; Libra-vs-finite-field speed test opened

User: keep the per-sector regulator factorization only where needed;
then a speed test of the blockwise Libra route against the finite-field
sector route from the existing time records (no finite-field reruns).

- **Need.** The trigger (`factorTruncated`: skip when the truncation is
  already eps-factored) fires at every sector from the first completed
  row on (CF385 sectors 19-34, CF408 sectors 7-29), because every new
  row carries an intrinsic regulator prefactor from the diagonal
  normalizations (CF408 (29,28): forcing proportional to
  (1+2eps)(-2+13eps-27eps^2+18eps^3)/eps^3).  It cannot be deferred to
  the family level: the solver reconstructs the eps-dependence of each
  block as a rational function with a degree cap (MaximumTotalDegree 22,
  at most schedule+8 regulator values), block (29,28) is already of
  eps-degree {3,3}, and unfactored rows enter the forcing of every later
  row through D_km A_mj, so the eps-degrees would compound past the cap
  within a few layers.  The per-sector step stays; the current trigger
  is the needed one.
- **Cost** (CF408 run, per-sector log timestamps): block solves 960 s
  for 340 blocks, regulator factorization 562 s (48-91 s per sector at
  n = 39-41), pre-fix symbolic row gauge 1703 s and pre-fix census tail
  719 s (both the 08-22 bugs, now 2-40 s per sector).
- **Profile** (`profile_regfactor.wls`, the certified CF408 41x41
  connection un-factored by a constant eps-dependent gauge): validity
  filter 3.6 s; 1-point `FactorDependence` 6.9 s returning a wrong dense
  T (379 off-identity entries) whose symbolic conjugation check cost
  92 s; 2-point attempt 3.7 s returning the true T (4 entries), check
  4.5 s; whole function 125 s.  Every one of today's 37 per-sector calls
  succeeded at 2 points.
- **Fix** (`FamilyRegulatorFactor.wl`): `"PointLadder" -> {2, 4, 8, 16}`
  and a random-point gate (`familyRegulatorPointFactoredQ`, option
  `"GatePoints" -> 2`, unseen chart points): the connection evaluated at
  rational chart points is conjugated and tested for eps-factorization
  before the symbolic acceptance identity is attempted.  Same input: 15 s
  (2-point attempt only); with the ladder forced to start at 1 point the
  gate rejects the dense candidate in < 1 s (22.6 s total).  Gauge
  identity verified at a point; `t_family_regulator_factor.wls` 7/7.
  Expected effect on CF408: 562 s -> ~100 s of factorization.
- **Speed test** (running, cores 0-9, one main): the blockwise Libra
  route (`libra_saved_blockwise_epsform.wls` LocalOnly +
  `libra_checkpoint_factor_dependence.wls`, budget 300 s/step, inputs
  `~/FACET/Codex/General/LibraTwoRoot_20260819`) on CF385/CF408, the two
  families with finite-field-first records; output
  `Results/UU_08_10_canonical/BenchmarkStripBackends/LibraVsFiniteField_2026-08-22/`.
  The finite-field side is taken from the 08-22 logs (above), with the
  pre-fix bug time separated out.

## 2026-08-23 (00:00-00:25) — speed test result; zero-forcing shortcut

- **Blockwise Libra route, fresh runs** (one main, cores 0-9, the 08-19
  scripts and inputs; `Results/UU_08_10_canonical/BenchmarkStripBackends/
  LibraVsFiniteField_2026-08-22/README.md`): CF385 Fuchsification 1385 s
  (175 coupled pairs) + factor/dlog 389 s = 1774 s; CF408 1774 s + 326 s
  = 2100 s; both EpsForm.  The 08-19/20 figure "1-6 min per family"
  was the `FuchsifyBlock` step time alone (253/322 s); the per-pair full
  n x n symbolic conjugation and the two `FuchsianQ` checks were never
  timed and dominate.  Corrects the 08-20 and 08-22 worklog statements
  that the blockwise route is 10-30x faster on easy families.
- **Finite-field side** (08-22 logs, no rerun): CF408 as run 3955 s, of
  which 2422 s were the two bugs fixed on 08-22 and 562 s the
  factorization now cut to ~100-150 s; post-fix estimate ~19-21 min
  single-kernel, with the block solves parallelizable.  Per easy
  40-master family the routes are within a factor of two (finite field
  ahead); only the finite-field route finishes the hard families.  The
  Libra-first hybrid is therefore not a speed route.
- **Zero-forcing shortcut** (`family_epsform_sector.wls`): a block with
  identically vanishing forcing has the exact gauge D = 0 and skips the
  three-prime solve (`"Method" -> "ZeroForcing"`; `FACET_ZERO_FORCING=
  False` disables it for A/B).  Test: CF204/CF123/CF311 re-solved into
  the scratchpad and certified exact (6/14/64 of 23/38/138 blocks took
  the shortcut); A/B on CF123 25 s vs 27 s.  These runs are 5-6 s slower
  than the 19:01 records because those still used the CANONICA dlog
  recognition (`AlreadyDLog`, 0.1 s per block) removed at ~19:30 after
  it hung on CF215/CF360; every block now pays the ~1 s finite-field
  solve.  Not a regression of tonight's changes.
- Lost with the 21:11 WSL restart: the zero-root campaign's mission
  logs (they lived in the scratchpad under /tmp; the run.log symlinks in
  `zeroroot_2026-08-22/CF*/` dangle).  Certified records are intact.

## 2026-08-23 (00:10-00:50) — Codex package bug report: multiquadratic rows bypassed the regulator factorization (fixed)

Codex (`External/CodexExchange/triple_root_2026-08-22/codex_package_bug_
multiquadratic_regulator_2026-08-22.md`): in a multiquadratic identity
frame the sector script's `! algebraicFrameQ` guards skipped the
per-sector and family-level regulator factorization, so completed rows
kept eps-dependent residues and the next row's strip problem was
intrinsically inconsistent -- CF300 (8,5) failed at `SolveResidues`
and no support/letter enlargement could repair it; after factoring rows
1-7 in the Kallen2 chart (the truncation uses root {1} only) the block
solved.  Reproduced and fixed:
- `FeynFacet/Private/FamilyRegulatorFactor.wl`:
  `FactorFamilyRegulatorDependenceInFrame[{Ax,Ay},{x,y},eps,frame]`
  classifies the roots present in the connection
  (`transportChartRootIndices`), pulls it back to the smallest
  catalogued rational chart of that root set (`TransportRootSetChart`,
  `transportChartRekey`, `masterTransportChartData`, root branches),
  factors there, applies the variable-free T(eps) in the source frame
  and verifies eps-factorization and both inverse identities exactly
  there.  Rational connections go straight to the rational path; a root
  set without a joint chart returns `NoRationalChart`.  On Codex's CF300
  rows 1-7 state: Kallen2, root {1}, 2 points, source frame
  eps-factored, 0.7 s, idempotent -- Codex's numbers exactly.
- `FeynFacet/Private/TransportCharts.wl`: `SolveEpsFormStripInFrame`
  option `"FiniteFieldFirst"` (no CANONICA/Maple ladder; the finite
  field solves the strip in the targeted chart) and acceptance of the
  production numerical certificate from the inner solve ("Certificate"
  propagated, "ExactDLog" honest).
- `Scripts/family_epsform_sector.wls`: one `blockwiseRouteQ`
  (FiniteFieldFirst, any frame) replaces every `! algebraicFrameQ` gate
  -- pre-row and post-row `factorTruncated`, family-level
  factorization, `blockEquation`/`applyRowGauge` row composition (the
  P2 performance defect: the algebraic branch no longer materializes
  the CANONICA full-truncation transformation), strips in the
  multiquadratic frame through `SolveEpsFormStripInFrame` with
  finite-field first; `NoRationalChart` is a typed stop
  (`state["Stop"]` = NeedsMultiquadraticRegulatorFactorization, exit 2)
  before the next row.  Blockwise sector certificates are structural
  (D.D = 0 so T^-1 = 1 - D exactly; Development: exact when every strip
  was exactly checked).
- Tests: `Tests/t_family_regulator_factor_in_frame.wls` (12: one-root
  chart factorization with source-frame gauge identity and inverse,
  rational path, typed stop for {lambda1, 1-4vw}, idempotence) 12/12;
  `t_family_regulator_factor` 7/7.
- End-to-end: CF300 from scratch with the patched route: sectors 2-7 in
  170 s (each factored in Kallen2), (8,7) 45 s, (8,6) 380 s, **(8,5)
  82 s** `RationalChart/Kallen2/SimultaneousFiniteFieldAffinePDE`,
  (8,4)..(8,1) solved; the standalone run was stopped at the user's
  request (main kernel slower than a subkernel) and resumed as a pool
  mission (4 subkernels, cores 0-9) from its checkpoint.

## 2026-08-23 (15:00-15:45) — standardization campaign opened; zombie pool retired

User: kill the two remaining overnight missions, standardize Codex's new
functions/optimizations into the package (rewrite where needed, with
tests), Opus subagents for ordinary missions under my oversight.

- Cancelled `cf303_identity_capture_xh_v4` and
  `probe_cf300_s12_recapture_v2_parse_context_xh_v1` via the pool's
  per-mission cancel files.  The orphaned overnight pool then topped its
  subkernels back up to 8 while running only a wedged adversarial mission
  (log silent 6 h at ~90% CPU) and the no-mutation heartbeat on the
  permanently Locked worker 144 -- it held every subkernel seat and
  blocked the licence ("No valid password found" for any new subkernel).
  Logs and final status archived to
  `External/CodexExchange/codex_overnight_pool_final_state_2026-08-23/`;
  pool stopped (stopnow).  Lesson recorded: a pool whose owner is gone
  still tops up its subkernels; retire it before starting new pools.
- Verified Codex's integration exactly matches its mirror (four postimage
  SHA256s) and that two handoff defects (typed SolverFailure persistence,
  schema-2 SolverConfiguration binding) are already fixed in the tree.
- KernelPool.wls: target-level top-level Return can no longer escape
  poolRun before the MISSION end record (function boundary around the
  Get; Codex handoff defect 1); live regression
  `Tests/t_kernelpool_return_marker.wls` (needs a free subkernel).
- FLINT affine-RREF adapter independently re-verified (Opus subagent):
  all ten pinned hashes match, bit-identical release rebuild, 73/73
  release + 36/36 ASan/UBSan on both shipped and rebuilt binaries,
  CF300-shape benchmark byte-identical at 1/2/4 threads and timings
  within a few percent of Codex's record; no new dependency (system
  libflint-dev 3.0.1, already in the MANIFEST).  Promoted the C side:
  `FeynFacet/Backends/flint/{flint_affine_rref.c, PROTOCOL_CFFR1.md,
  test_affine_rref.py}` + two-target `build.sh` (release/sanitize, FLINT
  3.0.1 gate, strict warning set), both binaries built; MANIFEST entry
  amended.  The Wolfram-side CFFR1 writer/parser with certificate
  binding (nonce, source/binary/protocol hashes, plan fingerprints) is
  NOT yet implemented -- "PlanDiscoveryBackend" -> "FLINTAffineRREF"
  still returns PlanDiscoveryBackendUnavailable by design; the CFFA4
  parser must not be reused for it (handoff boundary).
- `Design/MultiquadraticPromotion.md`: module layout and gates for
  promoting the multiquadratic algebra/direct-channel sampler into the
  package (one neutral algebra ABI; no BranchFlipMask in production;
  context-free artifact fingerprints; ModularConsistent-not-Solved
  contract for the OneForms gap; synthetic rank-0..3 tests).
- Full test battery of the integrated tree in flight (Opus subagent,
  standalone after the licence contention, watchdog attached).

## 2026-08-23 (16:30-17:30) — CFFR1 backend and multiquadratic promotion landed

- **CFFR1 plan-discovery backend** (5077d5b): Wolfram-side writer/runner/
  parser/verifier for the native affine-RREF adapter per
  Design/CFFR1Backend.md -- nonce echoed and required, typed failures
  naming the divergent field, all-row re-verification, plans sealed with
  adapter source/binary hashes + protocol + nonce + request/response
  hashes inside the plan fingerprint; explicit request never falls back;
  Automatic stays invalid.  t_finite_field_affine_rref_backend 31/31;
  six finite-field regression suites green; adversarial + new suite
  re-run independently by me before commit.
- **Multiquadratic promotion** (b80daef): MultiquadraticAlgebra.wl (one
  neutral (Z/2)^r ABI, context-free fingerprint, modular entries fail
  closed on non-integer data) and MultiquadraticStripSolve.wl (direct
  root-channel sampler, no BranchFlipMask in production, explicit
  artifact context, typed failures, ModularConsistent-never-Solved) --
  both registered.  Tests 75/75, 48/48 (deletion gate), 80/80 (synthetic
  known-gauge blocks ranks 0-3 with exact CRT-lift equality and
  all-sign-branch certificates).
- **Package bug found by the port and fixed** (b80daef):
  `transportChartRootIndices` matched root squares at all levels and
  flattened position specs into indices -- Sqrt[x] against {x, y, 1+x+y}
  classified as rank 3.  Level-1, Heads->False now; in-frame and
  transport-frame suites re-run green.  The same defect remains in
  Codex's External TRClassifyStripRecord (evidence files; not edited).
- Port-agent defect list recorded in its report (Codex sources: rational
  Mod not F_p reduction, Return-in-Table, per-point FileHash,
  context-sensitive InputForm keys, no square-class independence screen;
  package: FamilyRowGaugeFiniteField stable key never reaches FullForm,
  FamilyArtifactRead Quiet[Check] + hardcoded Global).  Follow-up agent
  in flight: FamilyRowGaugeFiniteField rebased onto the neutral module
  (grade-mask relabeling admissible, file unregistered) and
  FamilyArtifactRead hardened (CheckAbort + explicit context, caller
  semantics unchanged).

## 2026-08-23 (18:40-20:50) — generality pass: project data out of the package

User directive after finding CFxxx tables in Private/: the package must
be general (accepted scope: two variables (v,w)/(s,t,u)); project data
lives in the project.  My pass + three independent Opus audits
(project-data, hidden-assumptions, paths/defaults) -> Design/
GeneralityFixes.md; two Opus agents implemented disjoint halves; I
integrated (usage strings, battery, three test-environment fixes).

Package changes (one commit): the 47-entry family->chart table moved to
`Results/UU_08_10_canonical/TransportFamilyCharts.wl` (round-trip
verified entry by entry before deletion); package registry
TransportFamilyChartRegister/Load, unknown family ->
Missing["FamilyChartNotRegistered"] (was None = silently root-free);
legacy chart aliases registered from the project file.
ObservableTransport file patterns/extractors are options (zero files ->
NoDifferentialFamiliesFound, was a false CompleteExactInventory).  Both
/home/... literals gone (Automatic -> installation root, typed refusal);
$feynFacetAddonRoot/$feynFacetLoader/$feynFacetWorkspaceRoot with
Global`$FACET* overrides; Addon and subkernel-loader sites routed
through them.  Resume provenance hashes only package files; the driver
passes its own hash (DriverProvenance, schema 3; v2 checkpoints
recompute).  Reduction fingerprints and artifact identity are
path-free (legacy hashes still accepted).  Symbol generality:
DiagonalBlockClassCampaign Variables/Regulator options; chart-parameter
collision refused typed; the catalog retry no longer requires variables
NAMED v/w (positional match/rekey; TransportChartVerify read Global v/w
-- found by the new test, fixed); chart-extension output variables
fresh + disjointness; Maple unknown heads Unique-tagged;
familyCertificateModular arity pinned; DistributionHeads card key;
analyticContextQ validates the dimension rule by shape.  Machine size
from $ProcessorCount with the old numbers as documented caps.

Tests: new t_package_generality (30) and t_generality_renamed_variables
(53) adversarial suites; full battery 57 suites OK (only the two
documented pre-existing reds).  Three defects found while integrating:
the renamed-variables ceiling check was FACET_KERNEL_COUNT-sensitive
(test fixed); the legacy-alias test asserted resolution without
registration (now checks both sides); Simplification's shared-trace
reuse accepted a zero-byte trace (guard added).

CF265 slowdown (user directive): bisected -- NOT Codex's overnight code
(pre-overnight worktree reproduces today's inflated strip inputs
byte-for-byte at sector 9) and not the simplex support (SparseFirst run
identical).  The gauge representative is degree-unstable; the flip
entered with the 08-22 afternoon solver changes (bundled commit,
unbisectable further).  Fix designed: degree-aware normalization-column
pinning measured at the pilot prime; implementation next.

## 2026-08-23 (20:45-22:35) — representative-fix validation and 9-family benchmark

- The two documented test reds are green (da4a6c5): t_wolfram_traps now
  arms its traps deliberately (both diseases are cured -- the 08-20
  loader fix and the current Wolfram/Libra build -- and cured must not
  read as failed); t_canonica_scheduler degrades to the serial path
  inside a pool subkernel.  The battery has no red at all.
- Gauge representative fix (52ce634): trailing gauge columns pinned
  first, residues as fallback (details in the commit and
  BenchmarkStripBackends/RepresentativeFamilies_2026-08-23/README.md).
  Diagnosis chain: byte-level strip-input archaeology -> the (5,4)
  artifact with identical input but different normalization columns
  ({85..88} residues pinned vs {81..84} gauge tail) -> residue pinning
  forces block content out of the constant dlog residues into the
  rational gauge, degrees compound row by row.
- 9 families certified exact in one evening pool (8 in flight at once,
  fresh kernel per mission): table in the benchmark README.  Highlights:
  CF385 8.9 min end to end (66 min on 08-22), CF258 8.8 min (was 66),
  CF264 6.2 min (was 38), CF231 37 min while sharing the pool (was ~45
  alone), CF265 46 min from scratch at 4 subkernels (67.6 min this
  morning; the "13 min" of 08-22 was a resumed segment, not comparable).
  The CF265 killer strip's per-prime work fell ~50x.
- Watchdog notes: one transient subkernel-relaunch licence refusal
  (self-healed in 20 s), one broker re-dispatch race (FILEGONE, no
  effect), 812 broker sub-missions OK, zero failures.

## 2026-08-24 (00:20-01:10) — generality round 2: the real fixes landed

Design/GeneralityFixes2.md executed for the user-selected real set
F1 + F2 + F6.1 + F5's typed-refusal half (agent for the first three,
coordinator for F5 and integration):
- F1: RootSourceIndices out of the hashed preparation payload (schema
  V2, provenance kept unhashed); forward/reverse root declaration now
  bit-identical ABI.
- F2: SolveEpsFormStripInFrame dispatches chartless root sets to the
  multiquadratic engine; results verbatim (ModularConsistent never
  Solved), a 7-status scope list keeps NoRationalStripChart only for
  genuine out-of-scope, "MultiquadraticDispatch" -> Engine/OutOfScope/
  Disabled disambiguates; the sector driver records a
  <family>_<k>_<j>_modular.wl candidate artifact + StripSolvers summary
  and stops typed (ModularCandidateNotInstallable).
- F6.1: scalar-local root-free fast path in
  multiquadraticFieldDecompose, every fast-path result verified by the
  exact compose check; telemetry (RootFreeFastPathCount, path
  statistics as per-record deltas).  240-scalar benchmark: 0.348 s ->
  0.049 s median (~7x), SameQ on all vectors, fast-path count = the
  full root-free population; rank 0 gains the compose check it lacked.
- F5 half (06cab95): verified {v,w} convention default + typed
  ClassVariablesUndeclared / RegulatorAmbiguous refusals; RegulatorFree
  flag; no legacy mode needed (the 4 undeclared ClassForms are
  chart-route artifacts without representative matrices).
- F3: FamilyRowGaugeFiniteField.wl header-labelled VALIDATION PROTOTYPE
  (decision, not loaded).
Codex's red-team test: 12/7 -> 14/5; the 5 remaining FAILs are the 5
documented decisions (prototype not loaded; CF prefix and Codex
workspace-segment configurability declined as polish; bare no-expression
resolver keeps the historical default -- order of arbitrary pairs is
undecidable, every expression-bearing consumer is verified; regulator-
free classes keep a flagged placeholder name).  Suites: new
t_multiquadratic_dispatch 35/35 and t_undeclared_metadata 11/11; all
multiquadratic/in-frame/generality suites green; dispatch not yet
exercised on a physical triple-root family (CF259/300/303 are the
cases; next campaign).

## 2026-08-24 (00:20-01:10) — generality round 2: the real fixes landed

Design/GeneralityFixes2.md executed for the user-selected real set
F1 + F2 + F6.1 + F5's typed-refusal half (agent for the first three,
coordinator for F5, F3, and integration):
- F1: RootSourceIndices out of the hashed preparation payload (schema
  V2, provenance kept unhashed); forward/reverse root declaration now
  bit-identical ABI.
- F2: SolveEpsFormStripInFrame dispatches chartless root sets to the
  multiquadratic engine; results verbatim (ModularConsistent never
  Solved), a 7-status scope list keeps NoRationalStripChart only for
  genuine out-of-scope, MultiquadraticDispatch key disambiguates
  Engine/OutOfScope/Disabled; the sector driver records a
  modular-candidate artifact + StripSolvers summary and stops typed
  (ModularCandidateNotInstallable).
- F6.1: scalar-local root-free fast path in the channel decomposition,
  every fast-path result verified by the exact compose check; telemetry
  as per-record deltas.  240-scalar benchmark: 0.348 s -> 0.049 s
  median (~7x), SameQ on all vectors, fast-path count = the full
  root-free population; rank 0 gains the compose check it lacked.
- F3: FamilyRowGaugeFiniteField.wl header-labelled VALIDATION PROTOTYPE.
Codex's red-team test: 12 PASS/7 FAIL -> 14 PASS/5 FAIL; the remaining
five are the five documented decisions (prototype not loaded; CF prefix
and Codex workspace-segment configurability declined as polish; the
bare no-expression resolver keeps the historical default because the
order of arbitrary pairs is undecidable and every expression-bearing
consumer is verified; regulator-free classes keep a flagged placeholder
name).  New suites: t_multiquadratic_dispatch 35/35,
t_undeclared_metadata 11/11; all multiquadratic/in-frame/generality
suites green.  The dispatch is not yet exercised on a physical
triple-root family (CF259/300/303; next campaign).
