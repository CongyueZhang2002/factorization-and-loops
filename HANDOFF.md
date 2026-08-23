# Session transfer note — updated 2026-08-22 22:15 PDT (Fable)

## State (22:15)
- **88 of 91 families certified** (CF385/CF408 added 22:00-22:09 after the
  40-master scaling wall was removed: blockwise sector completion, no
  CANONICA in the loop, sparse conjugation by the constant T, and the
  per-sector census no longer calls Simplify — WORKLOG 19:29-22:10).
  Open: triple-root CF259/CF300/CF303 (GPT/Codex exploring).
- Resource rule (user, 22-08): Codex/GPT keep one Wolfram main licence and
  half the CPUs; Fable pools use at most 4 subkernels; never take both mains.
- Adversarial tests: `Tests/t_family_certificate_modular.wls` (checker, 15)
  and `Tests/t_finite_field_adversarial.wls` (solver, 13) are the first
  things to run after any change to the certificate or the block solver.
- Memory: `FACET_MEMTRACE=<file>` gives a synchronous memory trace of the
  sector script (stdout is block-buffered when redirected).

## State (19:25, superseded)
- **86 of 91 families certified** (`FamilyEpsFormsCertified/`): all zero-,
  single- and two-root families.  Open: CF385/CF408 (solved 08-20, need the
  blockwise-schema adapter) and the triple-root CF259/CF300/CF303 (no
  rational chart; extension-field finite field is the proposed route).
- Final checker hardened after Codex's adversarial review (all P0-P2
  fixed; `Tests/t_family_certificate_modular.wls` 15/15; Codex's suites:
  every exploit closed); reply note in
  `External/CodexExchange/fable_final_check_2026-08-22/`.
- Quality flag: residues of the certified forms can be very tall (CF231:
  101 digits) — basis normalization before transport is worth a pass.

## State (17:05, superseded above)
- **All three open two-root families are certified exact**: CF231 (12:00),
  CF305 and CF265 (16:53, 17.8 s each with the new modular certificate).
  Records in `FamilyEpsFormsCertified/`; the runs' working dirs in
  `FamilyEpsFormsSolving/tworoot_2026-08-22/` (attempts 1-2 archived
  beside it).  Nothing committed.
- Nothing is running.  Codex review requested on the certificate change:
  `External/CodexExchange/fable_final_check_2026-08-22/`.
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
  `Tests/t_finite_field_round2.wls` extended to 23 checks. (9,6) acceptance
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
  Guarded by the new `Tests/t_usage_messages.wls`.
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
- Codex works in `~/FACET` and in `External/CodexExchange/` and is
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
`Tests/t_diagonal_block_epsform.wls`, `Tests/t_finite_field_round2.wls`,
the `Scripts/diagonal_block_*` and `Scripts/benchmark_*` drivers,
`Addon/Mathematica_Addon/MANIFEST.md`, `CLAUDE.md`, `WORKLOG.md`, this file
and the records under `Results/UU_08_10_canonical/`.

## Quick verification for a new session (each needs a free kernel seat)

```bash
wolframscript -file Tests/t_diagonal_block_epsform.wls   # 23 checks, ~1 min
```

```bash
wolframscript -file Tests/t_finite_field_round2.wls      # 11 checks, ~2 min
```

The full stage-1 campaign reproduces in ~4 minutes on 4 subkernels:

```bash
wolframscript -file Scripts/diagonal_block_class_campaign.wls /tmp/classff 4 ALL
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
  CF300 solved through sector 8 incl. the former blocker (8,5).  The
  standalone and pool runs were stopped at the user's request; the CF300
  state through sector 8's strips is in the session scratchpad only
  (/tmp; will not survive a restart) -- a rerun from scratch costs ~12 min
  to that point.
- Open: the sector-8 row gauge (applyRowGauge) on algebraic entries ran
  > 17 min (Together on square-root expressions; 9-12 s for sectors 6-7);
  it needs the evaluate-and-reconstruct treatment before CF300 can go on.
  Then the first rank-3 block needs Codex's 8-channel multiquadratic
  sampler (no global rational chart exists: K3 cover).
- Resource rule unchanged; nothing running; pool stopped.
