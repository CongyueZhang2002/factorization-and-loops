# Fable -> Codex: round-3 state and handover (2026-08-27 ~02:55 PDT)

Fable's session resets here; the user hands the work to Codex. Head is
7a6f716 on main, pushed, working tree clean except the solo-test chain
still running (see "Live at handover"). This note is the complete
state: what landed, what is verified, what is red, and the exact next
steps in the order we would have taken them.

## Committed tonight (all pushed)

- cb3ab49  the layout migration (your note 06), committed as one
  mechanical unit.
- 8205eb2  round-3 A1+A2 (evidence-classified obstruction promotion;
  active-support potential certification). Adversarial suites
  t_multiquadratic_obstruction_driver 23/0 (red-check vs pre-fix:
  4/19 FAIL) and t_multiquadratic_active_support 13/0 (red-check
  2/11). Your A1 decision (same evidence semantics for the residue
  screen, separate scheduler) implemented as specified.
- 594053f  round-3 A3 (BlockEquationDeferredBundleV2 per your
  contract; t_construction_bundle 44/0). The full-suite pre-fix red
  run is still owed; the self-contained script is
  scratch_round3_handoff/t_construction_bundle_prefix.wls.
- 921149e  YOUR three daytime units carried over from fb2cfbd,
  three-way, conflict-free, plus consumer re-pins to the leaner
  alphabet (46 one-forms + 8 span-pinned diagnostics on frozen CF300
  (12,9); {7,7} degrees, support 64, 1208 unknowns; {3,3} rung 121 /
  2120). The mathematical ladder walk is unchanged. gauge_ladder 28/0
  and gauge_screen 65/0 verified standalone after re-pinning.
- 7a6f716  pool + runner repairs (details in the commit): orderly
  close-grace-relaunch (the user's fix for the seat race), the
  scheduler pump, DUPLICATE routing, stale-record hygiene, REUSE mode,
  and the standalone-only list (t_canonica_scheduler,
  t_reconstruction_ghost, t_canonical_pipeline, t_pair_queue_schedule,
  t_kernelpool_return_marker, and t_solver_budget by kernel count).

## Verification state, exactly

The 95-suite reuse-mode batch: 82 green. Solo confirmations tonight:
gauge_screen 65/0, gauge_ladder 28/0, solver_budget 35/0 (fixture
enlarged - your speedups pushed it under the mid-deadline floor),
letters 25/0, kernelpool_return_marker 5/0, pair_queue_schedule 23/0,
reconstruction_ghost 8/0.

OPEN REDS, your starting queue:

1. t_chart_transport - REPRODUCIBLE (reused and fresh kernels, byte-
   identical): "T2c every one of CF258's 12 block forms pulls back and
   re-verifies" and "T2c' the single-conic-chart classes are composed
   with the chart". Not yet diagnosed.
2. t_transport_chart_extension - REPRODUCIBLE EXIT1 with NO FAIL line
   (reports through a non-tally path) and repeated Power::infy
   (division by zero) in its log. Not yet diagnosed.
3. t_kallen_q4_chart and t_family_regulator_factor_in_frame -
   NONDETERMINISTIC: 13 vs 16 failures, and 14 vs 7 assertions RUN,
   between reused and fresh kernels. Suspected hidden dependence on
   chart-catalog registration state (TransportFamilyChartLoad):
   Fable's own measurement script failed the same way until the
   catalog was loaded explicitly. Discriminator: run each twice
   standalone under identical conditions; if the numbers still wander,
   fix the tests to declare their state; if they stabilize red, then
   diagnose the code. THE UNRESOLVED ATTRIBUTION QUESTION for all four
   chart-cluster reds: are they pre-existing at 594053f (i.e. from the
   A-wave canonicalizer, item 4: the solver census consuming transport
   denesting) or introduced by the carry-over? The one-command
   experiment: stash/checkout the two Private files at 594053f, run
   the four suites clean, restore. Fable attempted it once and lost it
   to a licence refusal.
4. t_radical_denesting - red in shared mode (16 failures, the whole
   CF303 denesting feature set); clean-engine verdict NOT yet taken.
   Same attribution question as (3).
5. The Kira standalone set (t_canonical_pipeline, t_ghost_card_
   pipeline, t_registry_seeding, t_streaming_kira_import) - mid-run in
   the solo chain at handover; read
   /tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/tasks/b4r0m6bcs.output
   (or re-run; each needs its own main kernel, two at a time fits the
   seat budget).

## Live at handover

- The solo chain (paired, two main kernels at a time) may still be
  running the Kira set. Machine otherwise quiet; pool6 exited cleanly.
- The standing Opus watchdog stands down with this note; its state
  files are under the session scratchpad (watchdog/heartbeat5.log,
  findings5.log) and die with the session.

## Hard-won operational facts (tonight's tuition, do not re-pay)

- The licence admits ~2 of our main kernels and ~8 subkernels TOTAL.
  Concurrent batches + helper-launching tests exhaust seats; pools 3-5
  died of relaunch refusals within minutes. REUSE mode or your orderly
  relaunch fix; helper-launching tests two-at-a-time after the pool.
- A pool mission's elapsed time is not evidence of computation: check
  CPU. Seven "busy" kernels sat in futex wait for six minutes.
- t_pair_queue_schedule inside a pool subkernel loops forever writing
  ~590 MB/min (WaitNext::subnopar -> unmatched-completion warnings); a
  9.8 GB log was cancelled and deleted tonight.
- The reuse-mode failure tally over-counts: judge by per-mission logs.

## The queue after the reds are cleared (unchanged plan, your §
ownership note applies)

B1 (provider-backed AssembleSample, single sampling loop, delete the
fibrewise pass), B2 (adaptive 32-prime CRT, exceptional-image
replacement, provider-backed pointwise residuals), B3 (bounded
promotion validation: your minimum-sufficient list + the constructed
rank-3 oracle + the three real pairwise CF259 fixtures), C1 (phase
split, reported before choosing census vs compiled IR), then your
installation-contract conversion (a90ab40) once B1/B2 names are fixed.
No family production run: the mutual-empty-round gate and the user's
explicit go both still stand.
