# Session transfer note — updated 2026-08-31 ~13:2x (Fable)

## USER ALLOCATION RULING (direct): BOTH mains run CONCURRENTLY —
## Fable 1 main + 2 subkernels, Codex 1 main + 6.  No shared-seat
## waiting; Codex told not to kill our main (note 27; memory
## updated).  (25,14) rescreen RUN 3 relaunched immediately under
## it (shape-fixed script 267be974, allowance 14,400 s, log
## <scratchpad>/b14_screen_run3.log, watchdog armed) alongside
## Codex's GPL-subgraph run.  Next: on a good verdict, the (25,14)
## certificate on the (25,11) pattern; then (25,1) (fast route =
## note-21 provider hook, slow route = one main within allocation).

# Superseded: ~13:1x seat-window protocol (note 26) — voided by the
# allocation ruling above; its non-seat clauses (post results,
# verified-PID kills only) stand.

# Superseded: updated 2026-08-31 ~13:0x (Fable)

## HELD on conflicting instructions.  Codex note 25: it killed my
## (25,14) rescreen deliberately (seat coordination) and relays that
## the user's CURRENT instruction is to stop the obstruction proofs
## in favor of a paper-level analytic (GPL-subgraph) transport
## result — contradicting the direct "you can continue on the
## proofs" I hold from this afternoon.  ALL proof-side work stood
## down (my note 25 acknowledges); question put to the user; the
## Wolfram seat is Codex's for the analytic run.  On a user
## "continue": negotiate a seat window with Codex, then the
## relaunch line below.  On a user "paused": idle the campaign, keep
## the certified state as is.

# Superseded: updated 2026-08-31 afternoon (Fable)

## RESUMED by the user ("you can continue on the proofs").  (25,14)
## rescreen state: run 1 failed on a shape bug (Bbar hardcoded
## 2x2x1; block 14 is 2x2 — fixed, dimLower now read from the
## record, commit 267be974; run-1 output artifact in the codex tree
## is CONTAMINATED with unevaluated MatrixRank heads, do not
## consume).  Run 2 (shape-fixed, 6.2M leaves, 27 letters, healthy)
## was SIGKILLed ~12:54 by an external hand concurrent with Codex's
## `cf303_gpl_subgraph_smoke.wls` main-kernel launch — not my
## allowance, not the OOM killer (notes 23/24 to Codex; seat window
## requested).  WAITING on Codex's reply before relaunch; a
## persistent monitor watches Exchange/Codex for it.  (25,1) still
## waits on the note-21 provider-frame hook.  After each screen:
## final certificate to Results/.../PathTransportObstructions/CF303/
## on the (25,11) pattern.  Relaunch command when the seat frees:
## run_with_allowance.sh 14400 <scratchpad>/b14_screen_run3.log
## <scratchpad>/screen_cf303_25_2_kallen23.wls 14  (+ watchdog).

# Superseded: updated 2026-08-31 ~13:45 PDT (Fable)

## PAUSED by the user (~13:30, relayed via Codex note 24): the
## obstruction campaign holds.  Certified: (25,18), (25,11), (25,2)
## (complete span + defect at 2+1 images + witnesses).  (25,1) and
## (25,14): defect certificates + closed curve sets committed
## (Results/UU_08_10_canonical/PathTransportObstructions/CF303/);
## only the complete-span rescreens remain — block-1 symbolic route
## hit a compile wall at 10M leaves (provider-frame hook requested,
## Fable note 21).  Do not restart until the user resumes.

# Superseded: updated 2026-08-31 ~11:30 PDT (Fable)

## Obstruction-proof campaign (user-assigned ~05:30): 3 of 5 done

Standard = block-18 pattern (complete certified span + defect at two
usable images + frozen witnesses).  DONE: (25,18) — potential-ladder
second image closed the last gap; (25,11) — potential-zero column
closed (6 new exact curves incl. a Q(sqrt2) conjugate pair, census v2
= 24 divisors), ambient affine solve inconsistent at all 3 gauge
shells at 2 independent images, witnesses verified via the
transposed-CFFR trick (certificate:
codex-tree Diagnostics/Artifacts/cf303_25_11_obstruction_certificate.wl).
(25,2) — defect {1,1} + witnesses at 2 images on its 32-letter
expanded alphabet (Runtime/2026-08-31_rank3_integrability/).
REMAINING: completeness columns for (25,2), (25,1), (25,14) via the
generalized residual pipeline
(cf303_25_11_numerator_residual_closure.py now takes --source).
Exchange notes 15-17 of 2026-08-31 carry the audit table, results,
and method notes.  Transport remains Codex's (their notes 15/18);
kernel use only within their released allocation, every launch under
the allowance script.

# Superseded below — updated 2026-08-31 ~05:00 PDT (Fable)

## MILESTONE (Codex note 18, ~05:00): both rank-three rows COMPLETE;
## transport handed to Codex; Fable transport development STOPPED

CF259 row 27: solved 26..1 (block 1 exact: shell-3 ansatz, 6-prime
lift + held-out prime, zero defects), TransportReady.  CF303 row 25:
solved 24..1 with FIVE typed integral-form exceptions {18,14,11,2,1}
-- (25,1)'s 49-letter completion refused at two provider images
(defect 1), a genuine alphabet-independent obstruction meeting the
note-09 standard.  Checkpoints under
Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/.
Codex takes transport from the accepted modular-jet handoff; Fable
stopped per their note 18 (ack: Exchange/Fable/2026-08-31/14) at
commit 3737ba62 and holds idle.  Known open item on CODEX's side:
MultiquadraticStripSolve.wl provider-sampler p mod 4 admission gate.

# Superseded below — updated 2026-08-31 ~04:20 PDT (Fable)

## Overnight state (04:20): jet evaluator green; holding for Codex

Overnight exchange cycle (Codex notes 07-15, Fable notes 03-12): the
user ruled the package Maple fix and D1/E1 execution are CODEX's
(memory: lane-boundary-transport-only); ownership split accepted in
Codex note 07.  Since then, all in Fable's lane and committed green:
depth budget from a caller-suppliable order table (OrderTable seam,
68c5862c; the cheap source scan measured NOT seconds-scale and is
reference-only per notes 09/12/14), the LAZY formal lower-solution
graph (indexed nodes + provider handles + memoized renderer,
b7b0eb6d), and the modular origin-jet evaluator of that graph
(OKModularGraphSeries, per-call memo, typed origin/sheet/constants
refusals, a041b292; battery 69/69).  EdgeSeries/DiagonalSeries handles
are the only native crossing points.  House rule added after a wasted
hour (Design/Watchdog.md + memory launch-allowance-autokill): every
kernel launch embeds setsid + process-group auto-kill at ~3x design
expectation (scratchpad run_with_allowance.sh); at any watchdog
anomaly the default is stop-and-redesign.  Seat discipline: only what
Codex releases (note 15: one main + one subkernel for transport
validation); their CF259/CF303 production is untouched.

# Superseded below — updated 2026-08-31 ~00:30 PDT (Fable)

## State (2026-08-31): CF303 row-25 path-transport seam + D1

Module `FeynFacet/Private/PathTransportException.wl` (battery
`Tests/Transport/t_path_transport_exception.wls`, 49 assertions):
Waves A/B green through Codex note 29 (kernelMin quadrature floor,
commit 3f24938); Wave E generic entry point
`pathTransportExceptionTransport` wired (commit 09ca5a4) — dispatch to
the blockwise engine or the terminal formal quadrature; four
variable-length providers (25,{18,14,11,2}); contract-file
BranchConvention harmonization requested from Codex
(Exchange/Fable/2026-08-31/01). Real four-record plan benchmark on
the live continuation state was running at handoff (phase times owed
to Codex on completion; watchdog armed). Prepare's PhaseSeconds edit
is UNCOMMITTED pending the battery rerun behind the license.

D1 for (25,11) — notes 15/25 route — items 1-2 CLOSED
(Exchange/Fable/2026-08-31/02): numerator divisors all inside the 15
exact kinematic factors (…numerator_divisor_census.json, ExactV1);
E/C polar factors all bound to known curves at two images
(…ec_divisor_binding.json); union census = 18 distinct certified
divisors incl. root2 = (s+1)^2 + t(s^2-6s+1)
(…divisor_union_census.json, all in the codex tree
Diagnostics/Artifacts + Runtime exact-lift dir). NEXT: the E1 ambient
ladder on the COMPLETE 18-divisor span (the old rank0 ladder was
exhausted on the production alphabet only — span-relative), two
usable images per shell verdict (user rule: third image only replaces
a bad one). Trap found: cf303_block18_native_path_degree.trim
NORMALIZES mod the module-global PRIME — set rational.PRIME before
every use in multi-prime code.

# Superseded below — updated 2026-08-27 02:58 PDT (Fable)

## State (02:58): CODEX TAKES OVER. Read
## Exchange/Fable/2026-08-27/01_round3_state_and_handover.md — it is
## the complete authoritative handover (commits through 94ec15b, the
## verification table, the four open red clusters with their
## attribution experiment, tonight's operational facts, and the
## B1/B2/B3/C1 queue). Everything below this line is history.

# Superseded below — updated 2026-08-26 12:05 PDT (Fable)

## State (12:05): ROUND-3 WAVE A MID-FLIGHT, UNCOMMITTED — session cut
## at the user's usage limit; RESUME HERE

The working tree at 06ba162 carries UNCOMMITTED round-3 work. The scope
is Codex's detailed instructions
(Exchange/Codex/2026-08-26/02_round3_detailed_fix_instructions.md)
per the accepted plan (fable_round3_plan_2026-08-26.md). Model policy:
coordinator writes directly + FABLE-model subagents (user, 2026-08-26;
all-models limit). Test kernels run CONCURRENTLY (user correction: the
one-main rule is KernelPool-only; never serialize wolframscript tests).

DONE, in the tree, each with red-before-green evidence:
- A1 (obstruction promotion, P0) BY COORDINATOR: evidence classifier
  multiquadraticStripScreenEvidenceClassify + driver predicate
  multiquadraticStripConfirmedObstructionEvidenceQ; fresh-residue-image
  generator; both screen wrappers reworked (EvidenceRecord field, typed
  GaugeScreenInconclusive with Reason, dedup of identical images);
  driver negative gated on exact status + predicate recheck, adopts the
  confirmation run unconditionally, typed inconclusive stop otherwise;
  screen-first predicate recheck. NEW Tests/
  t_multiquadratic_obstruction_driver.wls 23/0 green, red-check vs
  pre-fix 4 OK/19 FAIL.
- A2 (active-support certification, P0/P1) BY COORDINATOR: two-phase
  candidate dedup (verified-first stable priority, SupersededKinds),
  diagonal span-pinning (multiquadraticStripDiagonalSpan, exact
  constant coefficients, DiagnosticRecords out of the layout),
  regulator-content guard (multiquadraticStripLetterKinematicPart:
  eps*x -> x; only multiplicative content can reach the guard —
  argument recorded in the test), ActivePotentialCertification computed
  from reconstructed residues in the terminal record
  (PendingReconstruction; vacuously-certified empty active alphabet),
  residue transfer helper multiquadraticStripTransferDiagnosticResidues.
  NEW Tests/Multiquadratic/t_multiquadratic_active_support.wls 13/0, red-check 2/11
  FAIL. Terminal SolvedLevelClaim now carries
  ActivePotentialsCertified vs CandidatePotentialsCertified.
- A3 (deferred bundle) BY FABLE AGENT, per its progress log:
  BlockEquationDeferredBundleV2 compiler (root frame mandatory,
  shared-denester canonicalization, pre-cancellation occurrence
  collection, interned operand table + immutable jobs, validated
  orbits, pole-order upper-bound labels), bundle validate/fingerprint/
  evaluate, forcing Output->Bundle early return + MaterializeFunction
  seam, Automatic-roots synthesis now typed Missing[RootFrameRequired].
  Its runs: t_construction_bundle.wls 44/44, t_construction_dag 78/78,
  t_construction_dag_divisors 15/15. FINAL STATE preserved in
  scratch_round3_handoff/ at the repo root (A3_FINAL.md, the round-3
  progress log, the pre-fix red probe log, and the SELF-CONTAINED
  pre-fix red-check script t_construction_bundle_prefix.wls with its
  overlay BlockEquationDeferred_prefix.wl — A3's one PENDING item: run
  that script once, expect heavy failures, record the counts as the
  bundle suite's red evidence, then delete the handoff dir before the
  A3 commit).

PENDING VERIFICATION (was in flight at cutoff):
- t_multiquadratic_gauge_screen re-run with the STRENGTHENED S4/S6
  (configured+fresh evidence): completed GREEN, exit 0, at 12:5x —
  verified in-session before cutoff. No longer pending.
- Consumer batch RESULT (completed at cutoff): _dispatch 35/0 GREEN,
  _regulator_reconstruction 18/0 GREEN, _obstruction_images 19/0 GREEN;
  *** t_multiquadratic_potentials 15 OK / 1 FAIL — diagnose which
  assertion (A2 changed dedup order/counts; fix code or strengthen the
  consumer assertion, never weaken); *** t_multiquadratic_letters ENDED
  WITH NO TALLY LINE (last output: the C1 chosen/rejected samples
  report) — by the strict-classifier rule that is NOT green: suspect an
  abort inside the suite at the A2 candidate-builder changes; re-run it
  FIRST, full output captured, on resume.
- NOT yet re-run: gauge_ladder, providers, strip_solve, prepare_core,
  persistence, provenance, solver_budget, row_gauge_resume + full gate.

NEXT STEPS in order: (1) re-run the pending suites, fix consumers at
preserved-or-greater strength; (2) collect A3's final report, verify
its suites fresh, review its diff; (3) remaining A-scope: 13-file
narrative sweep (hygiene); (4) full-suite gate (strict classifier — a
suite is green only on an affirmative marker); (5) commit round-3 wave
A (separable commits A1/A2/A3 per Codex instruction 4 of Hygiene);
(6) wave B per the plan+instructions (B1 AssembleSample over providers,
one sampling loop, delete duplicate fiberwise pass; B2 adaptive 32-prime
CRT + exceptional-image replacement + pointwise default check; B3
bounded promotion validation with the CONSTRUCTED rank-3 oracle from
Exchange/Codex/2026-08-22/04_triple_root_campaign/cf259_q4_rank3_oracle_2026-08-23_xh/TripleRootRank3CF259Oracle.wl
+ real pairwise CF259 fixtures 24_16/21_11/23_11 — NOT a physical
rank-3 freeze, Codex's census showed the blocks are pairwise); (7) wave
C phase-split measurement reported to Codex BEFORE choosing census vs
IR; (8) review round with Codex; families only after a mutual empty
round AND the user's word.

STANDING GATES unchanged: no family production runs; scan the exchange
by mtime never by filename; cheap gate before >10-min stages; adversarial
tests red on parent; evidence into Results before reporting.

# Superseded below — updated 2026-08-26 07:20 PDT (Fable)

## State (07:20): ROUND-2 WAVE LANDED (335e42f); review request #2 sent

Review round 1 (Codex merged + ChatGPT Pro, committed b58161c,
disposition c8744a7) found the release blockers MATHEMATICAL: the
multiquadratic route solved ε fiberwise and published the first fiber
(no coherent rational-in-ε solution), potentials were uncertified, the
exact verifier left the gauge unspecialized in ε, denesting was
inconsistent between transport and solver, obstruction wording was
theorem-level from two fixed primes, and the 1400.5 s global
decomposition was unnecessary (direct branch evaluation reproduces all
32 channel values — Codex benchmark on our frozen fixture).

Round-2 wave (overnight, committed 335e42f, gate 94 suites GREEN 93 /
DIAGNOSTIC 1 / RED 0 / SUITE GATE PASS): all six §1 correctness items
landed with adversarial red-on-prefix tests; rational-in-ε
reconstruction (canonical affine section, every-coordinate rational
interpolation, held-out ε + unseen-prime validation, K_a
kinematics-free, generic object verified in the DE); certified
potentials (ω = dlog L once per unique pair, cached); DeferredDAG
preserved + divisor metadata; direct providers (split-branch
Walsh–Hadamard + quotient-grade tower) behind ONE row assembler with
per-entry active-root reduction and per-entry fallback; ghost code to
Prototypes/. MEASURED on frozen CF300 (12,9): split-branch 1.32 s for
the whole block vs 1400.5 s decomposition; dominant entries 0.26–0.28 s
vs 8.7–9.8 s symbolic (evidence Round2Providers_2026-08-26/). Solved
status remains withheld unconditionally (an over-promotion on a
chartless fixture was caught by the unmodified dispatch suite DURING
the wave). Round-3 scope declared: providers as default sampler (needs
real-block validation), compiled modular IR (quotient-grade speed),
support census, elimination backend/FLINT/parallelism, file split.

REVIEW REQUEST #2: Exchange/Fable/2026-08-26/
02_round2_review_request.md (item-by-item closure map, 4
questions incl. round-3 priority order). NEXT: read the replies (scan
by mtime, never filter filenames), disposition, round-3 wave; families
only after a mutual empty round AND the user's word.

# Superseded below — updated 2026-08-25 23:15 PDT (Fable)

## State (23:15): hardening wave LANDED; awaiting Codex review round 1

Resume plan steps 1-5 below are DONE:
- 366deac serial-phase wave committed (18 suites green pre-commit).
- fbd856f hardening wave committed: every Codex 12:30/14:30 P1 blocker
  closed with an adversarial merge-blocker test (root-sign core key,
  ChannelsSHA256 V2 seal, compact-dlog certificate, behavioral
  two-consumer refusal); compile Deadline; prepare intermediate
  checkpoints; family-deadline persistence + stale-stop migration;
  byte-bounded pools; OneForm route/provenance key; CompileShards
  demoted; screen boundaries; ceiling options; rank-3 tower inversion
  (15.76x on one real entry, exact agreement); CF303 modular resume
  gate steps 2-4 (ResumeGate default ModularThenExact — exact still
  decides). New suites t_multiquadratic_provenance (61),
  t_multiquadratic_persistence (52). Two standing base defects fixed:
  t_block_demands was silently dead (only suite loading FeynFacet.m
  without the loader; aborted line 3, exit 0), CF259 literal in a
  usage message. Full regression at fbd856f: 86 suites — GREEN 85,
  DIAGNOSTIC 1, RED 0, UNVERIFIED 0, GATE PASS (classifier verdicts,
  not exit codes; summary in the PrepareCoreMeasurement evidence dir).
- Attribution CLOSED (4 passes, README in
  Results/.../CF300/PrepareCoreMeasurement_2026-08-25/): CURRENT
  prepare on the identical strip is 1439.7 s = decomposition 1400.5 s
  (97.3%) + 39.2 s rest. Refuted by measurement: 52-one-form Expand
  (13.5 s), context traversal (0 s), root census (0.7 s). The 2710.9 s
  reference was pre-wave code; difference explained in kind (tower
  inversion inside decomposition entries), magnitude deliberately
  unclaimed. OPEN PROPOSAL (not built): modular
  evaluate-and-reconstruct for multiquadraticFieldDecompose, accepted
  only on the existing exact recompose check — addresses 97.3% of
  current prepare.
- REVIEW REQUEST #1 sent: Exchange/Fable/2026-08-25/
  04_private_code_review_request.md (P1 closure table, test
  evidence, 6 questions incl. the decomposition proposal). NEXT:
  read Codex's reply (scan by mtime, never filter filenames), fix
  round, iterate until BOTH sides return empty; then families only on
  the user's explicit word (fresh pool, 8 subkernels, Watchdog.md).

## Standing gates (user directives, 2026-08-25)
- NO family production runs until a mutual Fable+Codex sign-off that
  neither side has anything left to improve. Tests/benchmarks allowed.
- Review protocol: Fable SENDS on-demand review-request notes to Codex
  in `Exchange/Fable/` (changes + test evidence + questions);
  Codex's bihourly cadence is retired (protocol note committed).
- Exchange scans: NEVER filter filenames (Codex's notes contain
  "fable"); scan by mtime, classify by content.
- Any brief with a >10-min stage must name a cheap predictive gate.

## State (17:30)
- HEAD pushed through the protocol/disposition commits; working tree
  carries the UNCOMMITTED serial-phase wave (MultiquadraticStripSolve,
  TransportCharts, FamilyRowGaugeResume, Scripts/family_epsform_sector,
  new Tests/Multiquadratic/t_multiquadratic_prepare_core.wls): stage announcements
  (Verbose-gated), prepare Deadline (Preparation:<substage> stops),
  per-entry acceptance zero test with typed budget Throw, seal-at-write
  strip inputs + authenticated resume verdict (modular gate designed,
  NOT built), $Failed-interning fix with fault injection + negative
  control, option forwarding (CompileCore/LetterChannels/Legacy),
  prepare-consumes-core implemented but DEFAULT OFF (measured: does
  not pay; compile core stage 0.156 s; numbers at the option).
  16 suites green, 0 FAIL. Verify then commit as the next action.
- Measured on real CF300 (12,9): prepare 2710.9 s cold is THE
  remaining cost (compile 91 s). Attribution script ready:
  scratchpad/opt/cf300_attribute.wls. CF303 resume-cost script ready:
  scratchpad/opt/cf303_resume.wls.
- Evidence in scratchpad/opt/ (cf300_prepare_result.wl, suite/,
  suite2/) MUST move under Results/ before numbers are recorded.
- No Wolfram kernels running. No pools. Campaign checkpoints intact.

## Family ledger (checkpointed progress, all preserved)
- CF300: 24 masters, 12 sectors; 1-11 done; sector 12: (12,11),(12,10)
  done, (12,9) OPEN (integrability screen defect 0 at 68 letters;
  gauge screen-admitted at DegreeOffset {3,3}; full solve never
  completed - round-6 prepare was cut at cancel). <=8 couplings after.
- CF259: 47 masters, 27 sectors; 1-23 done; rank-3 graded factorization
  INSTALLED+persisted (ResolvedStop record in state, corroborated);
  sector 24: 4 of ~20 done ({24,16} solved incl. modular records).
- CF303: 45 masters, 25 sectors; 1-16 done; sector 17: 5 of ~15 done;
  {17,12} solved in round 5 via Kallen23 after the coordinate-map fix.

## Next steps, in order (after user resumes)
1. Verify + commit the serial-phase wave (working tree).
2. Move scratchpad/opt evidence into Results/.
3. Launch the HARDENING agent with Codex's full blocker list:
   root-expression/sign in the core key + adversarial sign mutant;
   ChannelsSHA256 content sealing (V2 seal) + mutation mutant;
   compact-dlog certification or exact dlog check + mutant;
   compile cooperative Deadline (prepare done); byte-bounded caches
   with oversize bypass; shard result schema/helper hygiene/absolute
   deadlines (or demote to private); OneForm key mode/provenance;
   behavioral S12 (replace source-string assertion); rank-3 recursive
   tower inversion + compact-route grade-support gate; stale-stop
   migration branch for pre-fix states; whole-family deadline
   persistence; screen post-rank/per-letter boundaries; top-level
   ceiling options; prepare INTERMEDIATE PERSISTENCE (round-6 loss);
   remaining clone-green fixtures (gauge_screen reads ~34MB ignored);
   prepare-cost attribution (cf300_attribute.wls) and act on it;
   CF303 modular resume gate (build steps 2-4 of the designed gate).
   Merge blockers: the two adversarial cache mutants + fault injection.
4. Full regression; commit; push.
5. FIRST ON-DEMAND REVIEW REQUEST note to Codex; iterate fix rounds
   until a round returns empty from both sides.
6. Only then, with the user's word: relaunch the three families
   (fresh pool, 8 subkernels, watchdog per Design/Watchdog.md with
   round-6 lessons: event-driven log watch, command grep -a, stage
   deadlines now real).

# Session transfer note — updated 2026-08-22 22:15 PDT (Fable)

## State (22:15)
- **88 of 91 families certified** (CF385/CF408 added 22:00-22:09 after the
  40-master scaling wall was removed: blockwise sector completion, no
  CANONICA in the loop, sparse conjugation by the constant T, and the
  per-sector census no longer calls Simplify — WORKLOG 19:29-22:10).
  Open: triple-root CF259/CF300/CF303 (GPT/Codex exploring).
- Resource rule (user, 22-08): Codex/GPT keep one Wolfram main licence and
  half the CPUs; Fable pools use at most 4 subkernels; never take both mains.
- Adversarial tests: `Tests/FiniteField/t_family_certificate_modular.wls` (checker, 15)
  and `Tests/FiniteField/t_finite_field_adversarial.wls` (solver, 13) are the first
  things to run after any change to the certificate or the block solver.
- Memory: `FACET_MEMTRACE=<file>` gives a synchronous memory trace of the
  sector script (stdout is block-buffered when redirected).

## State (19:25, superseded)
- **86 of 91 families certified** (`FamilyEpsFormsCertified/`): all zero-,
  single- and two-root families.  Open: CF385/CF408 (solved 08-20, need the
  blockwise-schema adapter) and the triple-root CF259/CF300/CF303 (no
  rational chart; extension-field finite field is the proposed route).
- Final checker hardened after Codex's adversarial review (all P0-P2
  fixed; `Tests/FiniteField/t_family_certificate_modular.wls` 15/15; Codex's suites:
  every exploit closed); reply note in
  `Exchange/Fable/2026-08-22/01_final_checker_changes_and_reply/`.
- Quality flag: residues of the certified forms can be very tall (CF231:
  101 digits) — basis normalization before transport is worth a pass.

## State (17:05, superseded above)
- **All three open two-root families are certified exact**: CF231 (12:00),
  CF305 and CF265 (16:53, 17.8 s each with the new modular certificate).
  Records in `FamilyEpsFormsCertified/`; the runs' working dirs in
  `FamilyEpsFormsSolving/tworoot_2026-08-22/` (attempts 1-2 archived
  beside it).  Nothing committed.
- Nothing is running.  Codex review requested on the certificate change:
  `Exchange/Fable/2026-08-22/01_final_checker_changes_and_reply/`.
- Day's package changes (all tested, see WORKLOG 2026-08-22 afternoon):
  finite-field support = certified simplex + support learning, prime
  sequence extension to 40, task broker per-prime decision and mission-side
  share, obstruction certificate `EpsFormStripObstruction`, family/sector
  regulator factorization `FactorFamilyRegulatorDependence` (per-sector
  CANONICA removed from the loop), self-validating strip checkpoints and
  artifacts, cached assembly block order in the sector state, modular
  family certificate (default).
- Known weak spots: a package change mid-campaign needs a pool restart
  (subkernels do not reload); the certificate's residue reconstruction
  is informational only; `t_wolfram_traps` pre-existing red.

# Session transfer note — written 2026-08-21 16:30 PDT (Fable); updated 2026-08-22 04:00 PDT

## Update 2026-08-22 night (Fable, user asleep; core limit 4, no campaign)

**State for the day run of CF231/CF305/CF265** (the user's instruction:
"We'll run the 3 unresolved 2 roots in the day instead"):
- Launch command (one main + N subkernels, families in parallel, task broker
  for the hard blocks, finite-field-first route, production check level,
  certification into `FamilyEpsFormsCertified/`):
  `Scripts/family_epsform_pool.sh <out> <pooldir> 8 CF231 CF305 CF265`
  Progress/ETA: `Scripts/tworoot_status.sh <out>`. Spawn the watchdog
  (`Design/Watchdog.md`) in the same turn. Expected per family on 8
  subkernels: assembly ~2-3 min (was 10-24), easy off-diagonal blocks
  seconds, hard blocks 1-3 min each (the (9,7)-class block is 187 s on one
  subkernel) -> tens of minutes per family, not hours; ~2x uncertainty.
- Everything below is tested; nothing is committed (user rule).

**What changed tonight** (details in WORKLOG 2026-08-22):
1. Task broker (`FeynFacet/Private/TaskBroker.wl`): a family mission farms its
   sample batches and CANONICA degrees to the pool's free subkernels; measured
   on (9,7) 446 -> 357 s with 3 helpers. Wolfram forbids nested parallelism;
   the licence allows 2 mains.
2. Method benchmark on 20 real off-diagonal blocks: finite field 20/20, 872 s;
   CANONICA ladder 15/20, 2790 s; Maple 13/20, never faster. Route is now
   finite-field-first (`FACET_STRIP_ROUTE`), CANONICA/Maple last fallback.
3. Defect fixed: dimension-3 blocks inflated the power tables (pattern
   collision in `maximumExponents`); regression checks in t_finite_field_round2.
4. Checks separated from the calculation (`FACET_CHECK_LEVEL`, Production is
   the driver's default): numerical guards inside, ONE exact family
   certificate at the end. Assembly 610 -> 98 s on CF254 (identical output).
5. Sampler: residue columns from the dlog forms (build 15 -> 2.9 s per sample
   on (9,7), identical systems). (9,7) full solve 187 s in a pool subkernel.
6. Watchdog standardized (`Design/Watchdog.md`, mandatory, verbatim prompt);
   `fresh_*` pool missions + `Scripts/run_tests_pool.sh` for test batches.
7. Tests: all touched modules green (21-test batch; `t_chart_transport`'s
   stale 8-argument call fixed, pre-existing since 08-20); new
   `t_check_levels.wls`, `t_usage_messages.wls`.

**Suite state (04:13)**: 44/47 OK on the pool (fresh kernel per test);
the three non-OK are explained in WORKLOG (one needs standalone subkernels,
one is a wall-time baseline, one pre-existing). KernelPool gained fresh_*
missions with a blocked-kernel handoff, persistent claims and a one-time
requeue of lost missions (`Design/KernelPool.md`).

**Open**: main-kernel vs subkernel speed discrepancy (~3x, cause unknown;
benchmark as pool missions); C row build (~1.7x more on hard blocks, 16
cores authorized); blockwise-FF orchestration (~15-20% of kernel-seconds,
not worth it alone); the `::usage` item is fixed.


## Update 2026-08-21 evening (Fable, user-directed)

- The A2/A3/A4 standardization (partly Opus-assisted) was independently
  re-verified from stored artifacts: gauge/residues/alphabet SameQ to the
  oracles on both frozen fixtures, exact residuals recomputed zero, FLINT on
  70/70 samples, held-out mechanics probed at nontrivial degrees. Record:
  `BenchmarkStripBackends/frozen_M0/verification_2026-08-21/`.
- Four open items found there were FIXED in `FiniteFieldStripSolve.wl`:
  prime-width guard (`::width`, p < 2^31), degree-probe order
  (`finiteFieldStripProbeOrder`: shell 0, rectangle, then shells), reserve
  primes always outside the schedule (`"UnseenPrime"` recorded), and
  `Tests/FiniteField/t_finite_field_round2.wls` extended to 23 checks. (9,6) acceptance
  re-run: 157.1 -> 140.9 s, oracle-identical. All six finite-field tests green.
  The "width guard" entry in next step 1 below is therefore done.
- Inventory wording corrected: of the 37 families without a certified
  eps-form, CF385/CF408 are SOLVED (exact 2026-08-20 records) and only need
  the blockwise-schema adapter to enter the certified inventory; the open
  two-root work is CF231/CF265/CF305 only. Triple-root families are three
  (CF259; CF300/CF303 share one root triple).
- Codex's epsilon-form audit (late evening) adopted with a SCOPE
  CORRECTION: the off-diagonal rung delivers a dlog form (eps allowed in
  the residues; every benchmark result has `c/(a+eps)` residues and that
  is normal — the sector driver factorizes eps afterwards). New fields
  `DLogFormCertified`/`CanonicalEpsFormCertified`; diagonal gate requires
  eps-free letters; reserve primes unbounded; solver stops on a non-dlog
  lift. See WORKLOG "late evening" and the reply in CodexExchange.
- The `::usage` item (section below) is FIXED and its diagnosis corrected:
  only the 34 public symbols listed in nine private files' `ClearAll` lost
  their usage (not all 94 — `BuildBasis::usage` was always present and
  `Cut` kept `HoldAll`). Those nine files now `Clear` the public symbols
  (definitions dropped, messages/attributes kept) and `ClearAll` only the
  private ones. Measured after load: 94/94 exported symbols with usage.
  Guarded by the new `Tests/Core/t_usage_messages.wls`.
- Found by the regression batch and FIXED: `LibraFamilyEpsForm`'s chart
  route had been returning `ChartBlockCompositionFailed` for every chart
  family since ~2026-08-20 — `masterTransportChartBlockSpec` gained a
  `coefficientField` argument and `LibraEpsForm.wl` still called it with
  eight. `t_libra_family_eps_form` was red; now 4/4. No stored verdict
  carried that status.

Read this, then `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/TransportProductionPlan.md`
(entries of 2026-08-21) and the `WORKLOG.md` section "2026-08-21". CLAUDE.md's
START HERE has the durable rules; this file is the volatile state.

## Where the project stands

Stage 1 (class canonicalization) and the off-diagonal deep rung both got
much faster today, and both were re-verified against frozen oracles. No
physics result changed: every new form reproduces the established one.

**Stage 1 — diagonal blocks.** `FeynFacet/Private/DiagonalBlockEpsForm.wl`
is a complete, automatic engine: `DiagonalBlockEpsForm[{Av,Aw},{v,w},eps]`
takes a RAW class representative and does chart discovery, frame selection,
the slice, the finite-field solve, the exact completion and the exact
two-variable gate itself. `DiagonalBlockClassCampaign` runs the whole class
ledger. Measured: **173/173 classes in 204 s wall** (1 main + 4 subkernels),
oracle-identical to the 2026-08 ledger. Compare CANONICA: 3125 s for
163/170 of the easy classes and no result at all on the three hard ones.

**Off-diagonal blocks — the deep rung.** `SolveEpsFormStripFiniteField` now
carries M1, O2, and Codex's round-2 A2/A3/A4. Frozen acceptance:
CF254 (9,6) 1399.5 -> **157.1 s**, CF254 (9,7) 7254 -> **1446 s**, exact
gauge/residues identical to the oracle in both.

## Ground truth, and what is only a parallel artifact

- **Family eps-forms**: `Results/UU_08_10_canonical/FamilyEpsFormsCertified/`
  (54 of 91 certified by full recomputation). A family listed Exact there
  is NEVER re-solved. Unchanged today.
- **Class forms (stage 1)**: the production ledger is still
  `Results/UU_08_10_canonical/ClassForms/` (the CANONICA campaign, 173/173,
  used by everything downstream). Today's run wrote a SECOND, independent
  set at `HardClasses/DiagonalBlockFiniteField/ClassFormsFF_numeric/`
  (173/173, same schema, oracle-checked against the first).
  **Open decision for the user: whether to promote the FF set to be the
  ledger, keep it as the cross-check, or keep both.** Nothing downstream
  points at it yet — that is deliberate.
- **Frozen benchmark oracle**: `BenchmarkStripBackends/frozen_M0/`
  (`README.md` states the acceptance rule; `A2A3A4_acceptance.md` is
  today's newest record).

## Next steps, in the order I would take them

1. **The point/row BUILD is now the only large cost of the deep rung**
   (~14 s per sample on (9,7); solve 0.35 s, interpolation 19 s, lift
   2.4 s, exact check 53 s). Attack the O2 evaluator or move evaluation
   into the backend. Codex's add-ons list the concrete variants: fuse the
   A3 support with the FLINT matrix layout (do not build 2144 columns to
   keep 1568), batch by scheduler phase rather than by prime nesting, run
   A3 BEFORE plan discovery (the (9,7) pilot still costs ~70 s), and add a
   width guard to O2 before anyone tries 61-bit primes (the packed
   evaluator assumes intermediates < 2^62).
2. **M2 (modular affine-row carry)** is designed by Codex but not
   implemented; the nullspace is still discarded at interpolation.
3. **Zero-root family batch (29 families)**: the pipeline is proven end to
   end on CF34 but the batch has NEVER been launched — it needs an explicit
   go, and by house rule the launch message must quote that go, name the
   plan step and state the cost.
4. **Remaining families**: CF231, CF265, CF305 (two-root); CF385/CF408 need
   standard-schema records or an adapter; triple-root CF259/CF300/CF303
   have no global rational chart (an open surface-rationality question, not
   a missing feature).
5. **Production ladder wiring** is still unwired: Libra-first for 0/1-root
   families, size-dispatched deep rung, Maple as the small-system fast path
   and cross-check.
6. Optional: the diagonal-block route needs only a chart with letters
   linear in the slice variable, so it can serve as the independent stage-1
   cross-check for any future process, or replace the CANONICA dependency.

## Environment and process facts that will bite

- **The Wolfram license allows two MAIN kernels on this machine, total.**
  Codex often holds two. When it does, every `wolframscript` here dies with
  "product is not activated" — that is a seat refusal, not a broken
  install. Wait, do not reinstall anything.
- **One main kernel is ours; a seat is spared for Codex** (standing user
  rule). Subkernels are fine — the user authorized 4 today.
- Codex works in `~/FACET` and in `Exchange/Codex/` and is
  read-only for us. A live `RunProjectedTransport*` kernel is theirs.
- **Never `pkill -f` a pattern**: it matched my own shell twice today.
  Kill by PID, verified with `ps -o args=`.
- A standing Opus watchdog (file-based watchlist at
  `<scratchpad>/watchdog/watchlist.tsv`, 5-minute read-only rounds) is the
  house pattern for any launch; it catches message tags and stalls. Its
  liveness check must be `fuser` on the log, not a process-name pattern.
- The campaign logs are SILENT during a finite-field solve (only Libra
  chatters). Do not read silence as a hang; check CPU.

## Found while verifying the handoff: usage messages (FIXED 2026-08-21 evening; the "all 94" claim below was an overstatement — 34 symbols in nine files)

`FeynFacet.m` defines every public `::usage` at lines 12-360, then loads the
private files at line 431 — and each private file begins with
`ClearAll[PublicSymbol, ...]`, which wipes messages as well as values. Result:
**all 94 exported symbols end the load with no usage message**
(`StringQ[FeynFacet`BuildBasis::usage]` is False, and so is every other one).

- **Pre-existing and systemic**, not caused by today's work: `BuildBasis`,
  from the earliest sessions, is affected identically. Verified by
  `foo::usage="hello"; ClearAll[foo]` -> usage gone.
- **Zero functional impact**: only `?Symbol` documentation is lost; no
  definition, option or check is touched, which is why it has gone unnoticed.
- **Fix** (deliberately left for a session that can review it): drop the
  public symbols from each private file's `ClearAll[...]` — they are already
  cleared once by `ClearAll["FeynFacet`*"]` at the top of `FeynFacet.m` — or
  move the usage block to after the private-file `Scan[Get...]`. Fifteen
  files, mechanical, but it should be reviewed and re-tested rather than
  slipped in at the end of a session.

## Uncommitted surface

**Nothing is committed** (user rule: commit only on request). `git status`
shows ~227 paths, most of them Codex's exchange directories and results.
Mine, if a commit is ever requested, are: the four private modules
(`DiagonalBlockEpsForm.wl` new today; `FiniteFieldStripSolve.wl`,
`FiniteFieldEpsForm.wl`, `FamilyEpsForm.wl`), `FeynFacet/FeynFacet.m`,
`FeynFacet/Backends/flint/` (source + build.sh; `bin/` is gitignored),
`Tests/EpsilonForm/t_diagonal_block_epsform.wls`, `Tests/FiniteField/t_finite_field_round2.wls`,
the `Scripts/Diagnostics/diagonal_block_*` and
`Scripts/Diagnostics/benchmark_*` drivers,
`Addon/Mathematica_Addon/MANIFEST.md`, `CLAUDE.md`, `WORKLOG.md`, this file
and the records under `Results/UU_08_10_canonical/`.

## Quick verification for a new session (each needs a free kernel seat)

```bash
wolframscript -file Tests/EpsilonForm/t_diagonal_block_epsform.wls   # 23 checks, ~1 min
```

```bash
wolframscript -file Tests/FiniteField/t_finite_field_round2.wls      # 11 checks, ~2 min
```

The full stage-1 campaign reproduces in ~4 minutes on 4 subkernels:

```bash
wolframscript -file Scripts/Diagnostics/diagonal_block_class_campaign.wls /tmp/classff 4 ALL
```

## Update 2026-08-23 00:25 (Fable)
- Per-sector regulator factorization stays (needed: intrinsic eps prefactor
  on every new row; deferral would compound eps-degrees past the solver's
  cap); its cost is cut 8x (`FamilyRegulatorFactor.wl`: 2-point ladder +
  random-point gate, 125 s -> 15 s at n = 41).
- Zero-forcing blocks take D = 0 directly (`FACET_ZERO_FORCING=False` to
  disable).  Sector-script change tested on CF204/CF123/CF311 (exact).
- Speed test Libra blockwise vs finite field: `BenchmarkStripBackends/
  LibraVsFiniteField_2026-08-22/README.md`.  Libra 30-35 min per easy
  40-master family (fresh measurement; the old "1-6 min" counted only the
  Fuchsify steps); finite field ~20 min post-fix (estimate; 66 min as run
  with the bugs), and the only route for the hard families.
- Nothing of mine running; Codex/GPT kernels were idle at 00:02.

## Update 2026-08-23 01:15 (Fable) — stopped and pushed (commit f96e234)
- Codex's package bug (multiquadratic rows bypassed the regulator
  factorization) is fixed in the package and script; tests 12/12 + 7/7;
  CF300 solved through sector 9 (state "Sector" -> 9) with sector 10's
  strips checkpointed, incl. the former blocker (8,5); strips resolved in
  Kallen2/Kallen3 and the two-root joint chart Kallen23.  The pool run was
  stopped at the user's request (01:13).  Checkpoint copied to
  `Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/
  CF300/` (state + strip checkpoints; both run logs beside it): resume
  with the pool driver pointing at that directory.
- Open: sector 8 cost 21 min in total, almost all in the row gauge
  (applyRowGauge: Together on square-root entries; sectors 9-10 then
  2 min each), so the algebraic row gauge wants the evaluate-and-
  reconstruct treatment before the 4-row sectors 11-12.  The first
  genuinely rank-3 block (if any appears dynamically) needs Codex's
  8-channel multiquadratic sampler (no global rational chart: K3 cover);
  the typed stop NeedsMultiquadraticRegulatorFactorization marks it.
- Resource rule unchanged; nothing running; pool stopped.

## Update 2026-08-23 18:00 (Fable) — standardization campaign complete
Commits 12f046f, 5077d5b, b80daef, bb3d096, 1ce84c7 (all pushed).
Codex's overnight integration verified (full battery), FLINT affine-RREF
promoted C-side + CFFR1 Wolfram backend (typed, nonce/hash-bound, never
falls back), multiquadratic algebra + direct-channel strip sampler in
the package (ModularConsistent-never-Solved pending the OneForms
contract), FamilyRowGaugeFiniteField rebased on the neutral ABI,
FamilyArtifactRead hardened, pool Return-escape fixed (Codex's
prescribed fix falsified by measurement -- see the exchange reply), and
the package root-classifier level bug fixed (transportChartRootIndices).
Open threads: sector-12 ansatz axis and CF303 recapture (questions to
Codex in fable_standardization_reply_2026-08-23.md); regulator-
dependence reconstruction + OneForms certification before any
multiquadratic Solved claim; Codex's External witness Heads patch still
unapplied (needs its own regressions).  Nothing running.
