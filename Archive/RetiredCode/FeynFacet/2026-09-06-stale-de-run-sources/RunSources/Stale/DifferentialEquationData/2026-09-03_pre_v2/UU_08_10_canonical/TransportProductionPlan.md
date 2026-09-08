# Stage-2 production plan: transport all 173 classes / 91 families at required depth

Goal (user directive 2026-08-17): drive stage 2 until the WHOLE family set
transports at its required eps depth in a few-hour parallel run, then
actually generate the masters. Required depth is per-master, from the
measured coefficient valuations (`TransportDepthLedger.md`): 203 masters
need eps^0, 131 eps^-1, 7 eps^-2, 1 eps^-3, 1 eps^-4 — so most families
need weight 1-2, the deepest ~weight 6 (block-wise + exact depth rule).

## The two blockers to "entire", quantified (2026-08-17 00:40)

A. **Couplings not pure dlog** for families whose canonical bases carry
   an eps-dependent apparent locus relative to their subsectors (hard
   classes and others). Block-wise transport then hits coefficient
   blow-up (CF230 block 6: 75 s/order growing x6/order -> ~19 h at eps^1).
   FIX: off-diagonal eps-factorization (strip transformations; CANONICA
   off-diagonal recursion / closed-form strip at a double pole) so the
   whole family connection is eps*dlog with constant residues; then
   block-wise transport is a pure-dlog append, seconds-minutes.
   STATUS: CF230 in progress (sectors 1-5 need no strip; sector 6 running).

B. **Frame availability**: ~36 of 91 families do not assemble in either
   current frame (from the ledger's per-family status):
   - 14 `ChartPullBackFailed` — single-conic-chart blocks that do not pull
     back to the v = x y chart. The conic parameter composes rationally
     (t = 1 - y for the Kallen chart, done for CF258/CF230); generalize to
     all conic families and to the -xy chart (class-79 family).
   - 12 `PathDenominatorsNotLinear` — the chart path is not axis-aligned
     linear (bilinear letters x+y-xy etc. are quadratic on a generic
     segment). FIX: two-segment axis-aligned path, or transport in a chart
     where the family's letters are linear on the path.
   - 10 `AssemblyFailed` — diagnose per family (frame mismatch, swap
     member, missing class form).

## Work breakdown (each item a deliverable in the tree)

1. [in progress] CF230 off-diagonal cleanup -> `family_epsform_CF230.wl`;
   block-wise re-transport payoff measured. (agent: offdiag)
2. Generalize the cleanup to a production function
   `TransportFamilyCanonicalize` (or an option) that, given a family,
   assembles it, completes the off-diagonal eps-form, and returns a
   family eps-form with pure-dlog couplings + its certificate.
3. Frame availability: fix the three refusal categories so all 91
   families assemble; re-run the ledger to 91/91 per-block records.
4. Production sweep driver: sort families by predicted cost (ledger),
   transport cheap families immediately (pure block-wise), heavy ones
   after cleanup, all through the KernelPool in parallel; each family's
   masters written as a versioned artifact with its recursion +
   assembly certificate and an AMFlow spot-check point.
5. Actually generate: run the sweep to the required per-master depth;
   record wall time and per-family cost; the deliverable is the master
   set as GPLs (Libra II-words) with certificates.
6. Reviewer to-dos threaded through: exact-depth completeness assertion
   (H1), the inline-normalizer trap (H2), configurable original-DE check
   (H3) — agent: hygiene. Later: residue sparsification (2-5x);
   transport only the admissible boundary subspace (needs stage-3
   nullity); deck invariance at x=y and branch/orientation conventions
   for 77/97/79 (stage 3, physics-critical).

## Acceptance for "few hours in parallel"

The sweep, run on the 8-subkernel pool, produces every family's masters
to its required depth with (a) the block-wise recursion certificate exact
per block/order, (b) the five-part assembly certificate, (c) an AMFlow
numeric spot-check at one physical point per family (independent), in a
measured wall time of a few hours. Report the per-family cost table.

## Running record (append)

- 2026-08-17 00:40 plan written; CF230 cleanup in flight (offdiag),
  hygiene agent on H1-H3, frame-availability agent to be launched.
- 2026-08-17 00:50 CF230 FAMILY EPS-FORM CERTIFIED (offdiag agent, gate
  31.2 s): the whole 13x13 in the chart is an eps-form in BOTH variables
  on the ORIGINAL connections through T_total = diag(T_i).S — entries
  eps-free after dividing by eps, residues constant (x,y,eps-free) and
  equal between directions, flat, T_total.T_total^-1 = 1. Nine letters,
  all eps-free: {x, y, 1-x, 1-y, 1-xy, x+y-2xy, x+y-xy, x-y, 2-x-y} =
  the union of the block letters and the raw family letters; no new and
  no eps-dependent letter. S is block lower triangular with eps-only
  scalars on blocks 1-3 (a legitimate eps-dependent constant change of
  those blocks' canonical bases). Route: CANONICA off-diagonal recursion
  driven subsector-by-subsector with checkpoints (1601 s) after a
  closed-form strip removed the eps-dependent locus q (44 s); sectors
  2-5 needed no strip. q is FORCED: dlog det T_i = tr A0_ii - tr Ahat_ii
  with residual exactly 0 on all six blocks, so no class form avoids it.
  Artifacts: `HardClasses/EpsFormRoute/family_epsform_CF230.wl` (+ state
  files), `Scripts/epsform_offdiag_cf230_*.wls`.
  MEASURED NEGATIVES to keep: naive one-letter-at-a-time Moser reduction
  does NOT converge here (pair (6,4) cycles 27 steps; right-to-left
  column order is necessary but not sufficient — CANONICA's simultaneous
  ansatz is the right tool); `DDeltaDenominatorDegree` lives in
  CANONICA`Private` (the public spelling silently binds another symbol);
  and a per-entry pole function applied to a SUBMATRIX returns a silent
  zero that reads as a clean verdict (agent's own retracted claim).
- 2026-08-17 00:52 HYGIENE ITEMS H1-H3: reconnaissance only, NOTHING
  implemented (session stopped). Findings that change the plan, so the
  next session does not re-derive them:
  * H1 (make "DepthRule" -> "Exact" usable where it is sharper): the
    defect is `masterTransportRegrade` (MasterTransport.wl:2618)
    computing `predicted = wmax + 1 - shift` against the GLOBAL clamped
    shift (called at :3920). Everything needed for a per-block
    restatement is already returned by `masterTransportExactDepth`
    (:2166): "W", "Demands", "KMin", "Lowest", "NMax", "Table",
    "Support"; W_i(n) is monotone in n, so wmax >= W_i(need_i)
    certifies block i at all orders <= need_i (use assembly["Ranges"]
    for the rows; keep the "MeasuredConsistent" check).
    IMPORTANT: the regrading gate exists ONLY on the monolithic path —
    the "Engine" -> "Blockwise" branch (~:3820-3850) sets
    "Complete" -> True and never calls it, so a Blockwise run does NOT
    exercise the fix. Anchor: NOT CF230 (too slow on both engines) and
    NOT CF360 (documented Libra abort); recommended first attempt
    **CF27** (dim 8, chart, 3.9 s pre-transport, exact 5 vs clamped 6);
    other exact<clamped pairs: CF12/CF20/CF207 6/5, CF209/CF211 7/6,
    CF26 and CF50 exact 8, CF88 6/5.
  * H2 (inline-ReplaceAll normalizer trap): precedence is NOT the cause
    (Condition 130 > RuleDelayed 120 parses fine). The symptom
    `Symbol[_StringJoin]` requires SymbolName[s] not to return a string,
    i.e. the bare token `SymbolName`/`Symbol` did not bind to System` AT
    PARSE TIME — Get evaluates a file expression by expression, so a
    package loaded earlier in the same file (or already loaded in a pool
    subkernel) changes $ContextPath for the parse of every later
    expression. Corroboration in the tree: `symbolContexts` in
    t_wolfram_traps.wls is written with fully qualified System` heads.
    CANONICA exports only eps/$ComputeParallel/$NParallelKernels + its
    function names, so the shadow comes from something its load pulls in
    — the open question. Unrun diagnostic ready at
    scratchpad/opus_hygiene/diag_inline_normalizer.wls (varies parse vs
    application context, dumps resolved head contexts, probes
    Names["*`Symbol"] etc. before/after the CANONICA load). Call sites
    to fix: Tests/t_chart_transport.wls (~121-126) and
    Scripts/epsform_depth_diag_cf258.wls (~13); t_wolfram_traps.wls
    already has the correct form + a measured-only probe, so only the
    pinned assertion is missing.
  * H3 (configurable "DECheck"): site MasterTransport.wl:3968-3973,
    status at :3978-3988. TRAP: `AllTrue[{}, ...]` is True, so a None
    setting that merely empties deCheck would report "OK" — the skipped
    case must be discriminated BEFORE the AllTrue (and `checkable === {}`
    already means "SolvedNotCheckable"). "DECheck" is also produced by
    masterTransportCoupledSolve (~:3415) and consumed by TransportStatus
    (~:4237); both need the Missing["Skipped"] case.
- 2026-08-17 00:45 SESSION ENDED (user). State at handoff:
  * KernelPool running (8 subkernels) — `Scripts/KernelPool.wls` +
    kpsubmit/kpwait/kpstatus, `Design/KernelPool.md`. NEXT SESSION: check
    `<pool>/status.txt`; restart with
    `taskset -c 0-9 nohup wolframscript -file Scripts/KernelPool.wls <scratch>/kernelpool 8 True &`
    if it is not alive. All kernel work goes through it.
  * Stage 1: 173/173 classes certified (97/77/79 closed today);
    ClassForms records + Tests/t_hard_class_epsforms.wls 24/24.
  * Stage 2: block-wise engine (exact, 31/31), exact depth rule + full
    demand ledger (38/91 families), Libra checkpointing, traps pinned.
    Suite: t_master_transport 68/68, t_chart_transport 23/23,
    t_blockwise_transport 31/31, t_exact_depth 17/17,
    t_transport_checkpoint 5/5, t_wolfram_traps 9/9.
  * IN FLIGHT at cut-off: CF230 off-diagonal cleanup (sector 6; sectors
    1-5 need no strip; the eps-dependent locus q removed in closed form;
    ordinary higher poles remain -> Fuchs + CANONICA off-diagonal
    recursion, per-subsector checkpoints in the agent's report/artifacts)
    and the hygiene items H1-H3 (exact-depth completeness assertion,
    inline-normalizer trap, configurable original-DE check).
  * FIRST MOVES NEXT SESSION: (i) read this plan + TransportDepthLedger.md
    + the EpsFormRoute README (CLAUDE.md's START HERE section points at
    all three); (ii) run the ONE outstanding mission
    `Scripts/kpsubmit.sh payoff Scripts/epsform_offdiag_cf230_payoff.wls CF230 0,1`
    and compare against the baseline (block 6: eps^-2 28 words / 7123
    leaves / 151 s; eps^-1 172 words / 42271 leaves / 1568 s); (iii)
    items 2-5 above (production canonicalization function, frame
    availability for the ~36 refusing families, sweep driver, generate).
  * NOTHING IS COMMITTED. `git status` shows the whole session's work.
- 2026-08-17 01:01 PAYOFF MEASURED (`Scripts/epsform_offdiag_cf230_payoff.wls`,
  pool mission payoff2, 13.4 s wall): CF230 in the certified family eps-form
  basis (T = identity per block, couplings eps*const*dlog), Blockwise
  engine, orders {0,1}: transport total 7.8 s (decomposition 1.5 s,
  recursion 0.02 s, certificate 0.55 s), max words per block-order 32,
  max coefficient leaves 83, peak 1.38 GB; recursion certificate and Phi
  cross-check all zero, DE check True at eps^0 and eps^1. Baseline in the
  assembled-class-form basis: block 6 alone 151 s / 7123 leaves at eps^-2
  and 1568 s / 42271 leaves at eps^-1. VERDICT: once a family's
  off-diagonal eps-form exists, its transport is seconds; the sweep's cost
  is the per-family eps-form completion (CF230: 44 s strip + 1601 s
  CANONICA off-diagonal recursion) plus frame availability. Note the map
  back to the ORIGINAL masters is I = T_total.F with T_total = diag(T_i).S
  (eps-Laurent, certified exactly by the gate) -- the sweep must carry F
  to N + (pole depth of T_total) and regrade; the original-DE check is
  then optional (exact gauge identity + exact recursion certificate).
  Cosmetic bug seen: `Lookup::invrl` from the depth log line when
  "DepthRule" is Clamped (Missing passed to Lookup) -- fix.
- 2026-08-17 01:05-01:50 FRAME AVAILABILITY, MEASURED OVER ALL 91 (the
  ledger had records for 62 families only -- the four `ledger_*` pool
  missions of the night covered 62; the missing 29 were run in
  `ledger_m1..m4` and their records live beside the others in the
  session scratchpad; the .md ledger table itself is not yet
  regenerated). Refusals: 25 ChartPullBackFailed, 10 AssemblyFailed,
  18 PathDenominatorsNotLinear (of which 12 all-rational-class families).
  Three mechanisms, all measured (`monic_detail` missions, `chart_census`,
  `conic_census`, `class_alphabet` missions):
  (a) The (v,w) route applies the class representative's T to a MEMBER
      block without the member's v<->w swap / permutation
      (`block_class_assign.wl` predates the map keys) ->
      `ClassFormNotEpsForm` on CF67/71/262/263/267/269/308/311/390/393/
      404/415 (+ rational blocks of CF26/50/384/388/407). Fix: agent A
      (brief `scratchpad/brief_agentA_assembly.md`).
  (b) Roots. Only FIVE quadratics need a square root anywhere: lambda1,
      lambda2 = lambda1(-v,w), lambda3 = lambda1(v,-w), 4v+w^2 (and its
      swap v^2+4w), 1-4vw; a member may carry the v<->w image of its
      representative's quadratic (CF53/CF57 host lambda3-classes with
      lambda2; CF48/CF52 host class 98 with v^2+4w). Per family:
      14 lambda1-only, 11 lambda2-only, 2 lambda3-only, 3 Q4, 1 (1-4vw),
      7 lambda1+lambda2, 3 lambda1+lambda3, 3 lambda2+lambda3,
      3 triple-root (CF259, CF300, CF303). Chart catalog
      `FeynFacet/Private/TransportCharts.wl` (Kallen1/2/3, Q4a/b,
      Bilinear115 and the JOINT charts Kallen12/13/23 built by a rational
      point on the second conic in the base Kallen chart, all nine
      verified exactly by `TransportChartVerify`), per-family assignment
      `TransportFamilyChartTable[]`. First assemblies in the new charts
      (MaxWeight 0): CF248 (Kallen3), CF260 (Q4a), CF226 (Kallen23),
      CF232 (Kallen12), CF48 (Q4b) all assemble with the five-part
      certificate True.
  (c) Letters. Canonical alphabets contain letters that are QUADRATIC in
      the moving path variable with a non-square discriminant in the
      frozen one (1 - w + v w in the Kallen chart is a (2,2)-curve on
      P^1 x P^1, genus 1: no rational chart makes it linear). Libra's
      Pexp admits algebraic poles natively (PolesPosition = Solve); the
      monic gate refused them by policy. IMPLEMENTED (coordinator):
      algebraic letters (-b +- k Sqrt[D0])/(2a), D0 square-free, in the
      block-wise engine (`masterTransportBWLinearize`, pole parts by
      explicit factorization, partial fractions over the extension) and
      an exact zero test over the extension (`masterTransportRadicalZeroQ`,
      Sqrt -> r, reduce mod r^2 - D0) hooked into
      `masterTransportSimplifyZeroQ`; monic gate option
      "AlgebraicLetters" -> Automatic admits eps-free discriminants only.
      `Tests/t_algebraic_letters.wls` 23/23 (synthetic 2x2 with letter
      v^2 - w: Blockwise == Monolithic entrywise, DE check True, Phi
      cross-check True; negative controls). Real family CF301 (all
      rational classes, letter (1-v)^2 + v w): rational direction 21 s,
      algebraic direction 82 s, both certificates True.
  MEASURED and important for the sweep design: non-pure couplings are
  NOT automatically fatal -- CF301 needed the general integrator at
  27-32 (block pair, order) sites and still ran in 21-82 s. The sweep
  therefore TRIES every family directly under a time cap and routes only
  the ones that exceed it to the off-diagonal cleanup (agent B, brief
  `scratchpad/brief_agentB_familyeps.md`).
  Sweep driver: `Scripts/sweep_transport.wls <family> <outdir>` (one
  family per pool mission; catalog chart or (v,w) with a Kallen1 fallback;
  both axis directions; acceptance = assembly certificate + recursion
  certificate + Phi cross-check + valuation assertion + demand coverage;
  original-DE check recorded as performed/not performable). Cheap-scale
  ladder launched 01:52: CF429, CF3, CF1, CF27, CF12, CF230.
- 2026-08-17 02:10 AGENT REPORTS. Agent A: (v,w) assembly of class MEMBERS
  landed and green -- masterTransportClassFormBlock tries the stored T,
  then recovers the member's (Swap, Permutation) by reconstructing the
  representative's connection from the record's own T and EpsForm and
  matching in CanonicalBlocks' exact normal form; census over all 1119
  members: 252 of 1028 rational-frame members need the swap (213 dim 1,
  39 dim 2), NONE a permutation, 0 unmatched. The 12 formerly-refused
  all-rational families assemble in (v,w) (certificate True); CF26/50/
  384/388/407 now fail in (v,w) only on their conic block (correct);
  t_master_transport 75/0, t_blockwise 31/0, t_canonical_blocks 22/0.
  "BasePoint" -> Automatic (both axis directions) verified on CF1;
  "DECheck" -> All|"Demanded"|None and the per-block exact regrade
  assertion are on disk, verification mission queued. Agent A also caught
  a bug of the coordinator's: inside TransportFamily the regulator local is
  `regulator`, so `masterTransportMonicCheck[ahat, tau, eps]` had a
  vacuous EpsFree test -- fixed at the call site (all quadratics measured
  so far were genuinely eps-free). Coordinator added the one-variable
  (class 115) guard in the (v,w) route and a "frame 4" for such records
  in the chart route.
  Agent B (`Scripts/family_epsform.wls`, records in
  `Results/UU_08_10_canonical/FamilyEpsForms/`): 28 families measured so
  far -- pure (no cleanup needed): CF1/3/68/69/86/90/205/210/212/429;
  cleaned and gated: CF2/24/27/88/197/371; GateFailed after the
  mechanisms implemented: CF16/34/123/124/198/201/204/207/213/215/218/360
  (5-19 non-pure coupling pairs each). CONSEQUENCE for the sweep: the
  DIRECT block-wise route (general integrator over the extension) is the
  workhorse and the family eps-form is the fast path where it exists
  (`sweep_transport.wls` route 2, consuming the record with the module's
  own master series / valuation / original-DE check through a one-block
  pseudo-assembly carrying T_total).
  KernelPool: three dispatched-but-never-started missions tonight (no
  kernel file, no log, slot counted busy); manual remedy = cancel +
  resubmit; `KernelPool.wls` patched (claim check in the wrapper +
  resubmission after 90 s) for the next restart; Design/KernelPool.md
  updated. The pool is the bottleneck now (8 subkernels shared by two
  agents and the coordinator; queue 20+).
- 2026-08-17 02:25-02:30 POOL RESTARTED with the patched `KernelPool.wls`
  (drain + stopnow; the first relaunch exited at once on a STALE
  control/stopnow file -- remove BOTH control files before relaunching).
  Launcher incident recorded so it is not repeated: `sweep_launch.sh`'s
  PRIORITY touch created 91 EMPTY mission files while the pool was down;
  the pool ran them in 0 s as "done" and my duplicate cleanup then removed
  the real submissions -- fixed (touch only after a successful submit and
  only on a non-empty file; empty selection is refused).
  PRODUCTION SWEEP LAUNCHED 02:29: 91 missions `sw_<CF>` (priority mtime),
  `Scripts/sweep_transport.wls <CF> Results/UU_08_10_canonical/Masters 10 1200`,
  outputs `Masters/<CF>.wl` + `<CF>.status`; summary
  `Scripts/sweep_status.sh <outdir>`. Ladder measured before the launch:
  CF429 0.2 s, CF3 0.2 s (weight 4), CF27 15 s (weight 5, 20 general-
  integrator sites), CF12 15 min (weight 5, top block 61k-leaf
  coefficients, 45 sites) -- all ACCEPTED with recursion certificate,
  Phi cross-check, valuation assertion; CF12/CF3 original-DE check True
  at eps^0. Route 2 (family eps-form) on CF27 failed its original-DE
  check (basis/convention question sent to agent B); the direct route
  is the production path tonight.
- 2026-08-17 02:35 ROUTE 2 FIXED AND VERIFIED (family eps-form consumption
  in `sweep_transport.wls`): TransportFamily re-orders blocks into its own
  DAG order and permutes the system, so its F had to be un-permuted
  (Ordering[Flatten[Assembly.Blocks]]) before I = T_total.F; and the
  original-DE check needs I through nMax - r0 (r0 = min eps-order of the
  original A), so F is transported to nMax - tmin - r0. Measured: CF27
  route 2 -> ACCEPTED, original-DE check True at eps^0..2 (weight 7, 6560
  words, 5.4 s); CF3 likewise (True at 0..1); CF1 True at 0..5.
  AGENT B FINAL REPORT (`FamilyEpsForms/README.md`,
  `scratchpad/agentB/schema_answer_for_coordinator.md`): 28 of 38
  assembling families measured; 16 gate PASSED (CF429, 1, 3, 2, 371, 68,
  69, 210, 212, 86, 90, 205, 197, 27, 24, 88), 12 GateFailed (CF360, 34,
  204, 207, 201, 198, 123, 124, 16, 213, 215, 218). Findings that change
  the design: (1) the missing ingredient is usually the EPS-ONLY finish
  (CANONICA TransformDlogToEpsForm, 0.05-42 s), not the off-diagonal
  recursion -- no accepted family needed the CANONICA recursion; (2)
  purity is necessary but NOT sufficient: 10 families with zero non-pure
  couplings were still not eps-forms (couplings at eps^0) -> the ledger
  certificate must state pure-dlog AND eps-graded; (3) closed-form Fuchs
  reduction closes mid-size non-pure families (CF24 18.9 s, CF88 57.2 s);
  (4) all 12 failures are the two-variable Moser non-convergence mode
  (clearing 1-x in x re-creates 1-y in y); a fingerprint guard was added
  but never re-run at scale; (5) CF360 has a polynomial part at infinity
  (needs a Moser step at infinity, not implemented); (6) escalating
  CANONICA's ansatz does not rescue; (7) chart-frame retry fixes none.
  Records carry Blocks/Ranges/TTotal/EpsFormX/Y in the permuted basis,
  I = T_total.F, S diagonal blocks eps-dependent with NEGATIVE powers
  (CF3 diag(eps,1,eps^-2)). The old
  `family_epsform_CF230_offdiag_2026-08-17.wl` has Ranges dims != Blocks
  dims and must NOT be consumed for the map-back; a driver-made CF230
  record is queued (feCF230). Not done: 10 of 38 families have no record
  (CF12, 20, 98, 199, 209, 211, 258, 264, 217, 230).
  Ladder rung measured 02:35: CF67 in (v,w) with ALGEBRAIC letters
  (v - (1-w)^2 quadratic in the moving variable): ACCEPTED, 324 s,
  weight 4, 2 algebraic letters, 38 general-integrator sites.
- 2026-08-17 02:40 Q4 CHARTS REPLACED (TransportCharts.wl): with
  v = p, w = (p - s^2)/s (Q4a) / v = (p - s^2)/s, w = p (Q4b) every letter
  of CF48/CF52/CF260 has degree <= 2 in the moving variable (measured:
  CF48 assembles, 3 admissible quadratics; CF260 all linear) -- the
  naive v = (s^2-u^2)/4 chart made v + w - w^2 QUARTIC. TRIPLE-ROOT
  FAMILIES (CF259: lambda1+lambda3+(4v+w^2); CF300, CF303:
  lambda2+lambda3+(1-4vw)): over the two-root joint chart the third
  quadratic is a SQUARE-FREE QUARTIC in the path variable (discriminant
  in s nonzero; pool mission `triple`), so no further one-variable
  substitution rationalizes it; whether the total (Z/2)^3 cover of the
  (v,w) plane branched on three mutually tangent conics is a rational
  surface (rational elliptic surface) or not is OPEN -- if not, the
  couplings from the third-root blocks are elliptic-type kernels and the
  question becomes whether the exact depth rule ever reaches those blocks
  at nonzero weight (DAG + demands). Deferred; the sweep reports these
  three as ChartNotCovered.
  Sweep script now reloads the package at mission start (the pool
  preloads once at restart), so the running sweep sees the catalog.
- 2026-08-17 03:25 SWEEP FIRST PASS IN PROGRESS: 27/91 done, 18 transported
  (CF1, 12, 123, 197, 198, 199, 201, 204, 205, 207, 209, 210, 211, 212,
  213, 215, 217, 218; walls 0-965 s), 6 TimedOut at 1200 s (CF13, 16, 18,
  20, 21, 124 -- non-pure couplings, 10^4-10^5-leaf coefficients), CF231
  ChartPullBackFailed (composer nesting bug in TransportCharts.wl, FIXED:
  class 79 now composes into Kallen23), CF236/CF240 PathDenominatorsNotLinear
  in Kallen12 both directions (uncleaned couplings; cleanup route).
  Fixes landed meanwhile: T1f of t_chart_transport pinned to the strict
  gate (+T1f' algebraic-admissible); family_epsform.wls uses the catalog
  chart of the family. Agent A: t_exact_depth 23/0, t_blockwise 31/0,
  t_canonical_blocks 22/0, t_algebraic_letters 23/0, verA end-to-end OK.
  Agent B: M2 cycle guard fired live on CF230 (pair (6,4), the documented
  cycle) and returned the best state; CF230 record regeneration in flight.
  PASS 2 PLAN (after the first pass drains): for TimedOut and
  PathDenominatorsNotLinear families run `family_epsform.wls` (guarded M2,
  catalog chart) then re-run `sweep_launch.sh` (route 2 where a gated
  record exists, else direct with cap 3600); re-run the ChartPullBackFailed
  families (composer fix).
- 2026-08-17 03:50 first pass 41/91 done: 22 transported, 19 not (16 TimedOut
  or PathDenominatorsNotLinear -- mostly chart families with non-pure
  couplings: CF13, 16, 18, 20, 21, 124, 226, 230, 232, 236, 240, 248, 249,
  253, 254, 258; CF231 composer bug (fixed); CF259 ChartNotCovered;
  CF262 a FALSE refusal from agent A's block-wise completeness assertion
  (schedule window vs chain weight -- downgraded to a diagnostic; CF262
  re-runs in pass 2b). PASS 2a STARTED for the 16 (fe2_<CF> missions,
  guarded M2, GATE0 short-circuit, catalog chart) interleaved with the
  rest of pass 1. Pass 2b = `Scripts/sweep_launch.sh <Masters> 10 3600 ALL`
  when 2a has landed (route 2 where a gated record exists).
- 2026-08-17 04:15 first pass ~50/91: the CF2xx chart families with non-pure
  couplings time out on the direct route at 1200 s (CF226/230/248/253/254/
  258/260/264/265/26/269/299 ...). Reordered the queue: fe2_<CF> (cleanup
  driver) missions for ALL remaining not-yet-transported families now run
  AHEAD of their sweep missions (mtime priority), so each family's sweep
  mission takes route 2 where the record gates. Agent A's tests
  t_mt_C/t_ch_C/t_ed_C/t_transport_checkpoint/accF1/accF2/t1fprobe are queued
  behind the sweep (logs to be picked up at <pool>/logs); agent A writes
  its final report and stops. Agent A restated X6 (record, not verdict).
- 2026-08-17 04:35 pass 1: 49/91 with status, 24 transported (CF24 added via
  route 2/route 1 mix at 3569 s total). Pass 2a (fe2_<CF>, 37 families)
  running 8-wide, 30-40 min per chart family; the sweep resumes behind it.
  Both agents delivered final reports and stopped (agent A: full report in
  its transcript; agent B: FamilyEpsForms/README.md + schema note).
  Projection: pass 2a done ~07:30, sweep resume ~08:30. Nothing committed.
- 2026-08-17 05:10 PASS 2a MEASURED AND CUT SHORT: of the first 10 cleanup
  runs on the hard families, 2 gate (CF20, CF21) and 8 fail
  (CF124/16/226/232/236/249/253/301 -- the same two-variable Moser
  non-convergence mode; the guard returns a non-eps-form state), at 40-70
  min per family. The 27 queued fe2 missions were removed (the 8 running
  ones finish); the sweep's first pass resumes; pass 2b then re-runs the
  failed families with cap 3600 s (route 2 where a record gates). The
  cleanup needs an algorithmic step, not more runs: a Moser reduction at
  infinity (CF360-type polynomial parts) and/or the CANONICA off-diagonal
  recursion at higher ansatz degree per sector -- next session, with a
  cost estimate first.
- 2026-08-17 07:32 PASS 2b LAUNCHED (manually; the watcher had been killed by a self-matching pkill): cap 2400 s, SAFETY 0 = strict need -val; Transported families skipped; pass 1 final: 91/91 status, 41 transported at safety 1.
- 2026-08-17 08:10 STATE AT COORDINATOR HANDOFF. Pass 1 (safety 1) complete:
  91/91 status files, 41 transported. Pass 2b (safety 0, cap 2400 s)
  running: 50 missions, first results CF124 (516 s), CF16 (943 s, DE True)
  -- both had timed out at safety 1. Cleanups fe2_CF230/CF258 still running
  (4 h; CANONICA at higher degree). Deliverable so far:
  `Results/UU_08_10_canonical/Masters/<CF>.wl` for 43 families (transported
  masters as words with symbolic constants + certificates + cost), status
  lines in `<CF>.status`, summary `Scripts/sweep_status.sh`. Next session:
  (1) let pass 2b finish; `sweep_status.sh` -> table; (2) a safety-1 pass
  for the families transported at safety 0 (`sweep_launch.sh <Masters> 10
  3600 <list> 1` after moving their safety-0 artifacts aside -- the
  launcher skips Transported); (3) the cleanup algorithm for the
  still-failing chart families (Moser at infinity, CANONICA off-diagonal
  recursion per sector at higher degree, cost estimate first); (4) the
  three triple-root families; (5) regenerate TransportDepthLedger.md over
  91; (6) commit (Masters/ stays gitignored: sizes up to 46 MB per family).
- 2026-08-17 09:40 COORDINATOR STOPS ACTIVE MONITORING (pool keeps running).
  Tally: 91/91 attempted; 45 transported (41 at safety 1, +CF124, CF16,
  CF20, CF262 at safety 0 so far); pass 2b still running (25 queued; the
  CF2xx chart families with non-pure couplings mostly time out again at
  2400 s even at the strict need -- the cleanup algorithm, not a longer
  cap, is what they need); fe2_CF230/CF258 cleanups at 5.5 h (CANONICA
  per-sector at higher degree) -- cancel if a fresh session needs the
  kernels (touch control/fe2_CF230.cancel; costs a subkernel relaunch).
  To read results: `Scripts/sweep_status.sh Results/UU_08_10_canonical/Masters`;
  status lines carry the route direction, safety margin, weight, word
  count and whether the original-DE check was performable. Nothing
  committed; `git status` shows the whole night's work (FeynFacet/Private:
  MasterTransport.wl, BlockwiseTransport.wl, TransportCharts.wl (new);
  Scripts/{sweep_transport.wls, sweep_launch.sh, sweep_status.sh,
  sweep_pass2.sh, family_epsform*.wls, KernelPool.wls}; Tests/
  t_algebraic_letters.wls (new), t_master_transport/t_chart_transport/
  t_exact_depth (extended); Design/KernelPool.md; the ledger addendum;
  FamilyEpsForms/, Masters/ (gitignored)).
- 2026-08-17 10:20 STRATEGY CONSULT WRITTEN (user request; user suspects
  the approach may be wrong): `HardClasses/EpsFormRoute/
  Consult_2026-08-17_stage2_strategy.md` — summary of the method and the
  measured 46/91 split, the structural worry (classes were canonicalized
  in isolation; the standard workflow completes the WHOLE system's
  canonical form incl. off-diagonal steps before transporting), five
  candidate courses (A-E), and eight questions (decision B?, right
  off-diagonal algorithm incl. the UNTESTED Libra Fuchsify retry now that
  the Projector trap is known, the cycling two-variable Moser loop,
  closed-form strip generalization, triple-root feasibility, safety
  margin, acceptance without the original-DE check, and the
  endpoint-only shortcut). Replies to be saved beside it.
- 2026-08-17 10:35 CAMPAIGN PAUSED (user): more external assessments are
  incoming; nothing new starts until ALL replies are read and reconciled.
  State frozen: 47/91 families transported with full certificates
  (Masters/, sweep_status.sh); Fable Max's strategy reply is saved
  (EpsFormRoute/FableMax_reply_2026-08-17_stage2_strategy.md) and NOT yet
  acted on beyond stopping the compute it identified as waste (deep
  by-parts sweep missions and the two CANONICA-recursion cleanup
  marathons cancelled 10:26; queued sweep missions removed; the pass-2b
  auto-launcher watcher killed; the pool idle at 8 free subkernels; the
  status monitor stopped). The graded strip-purification gauge is
  DESIGNED but NOT implemented (task list #9, paused). Incidental: one
  more pkill-pattern self-match while killing the watcher (recovered;
  killed by exact-cmd match) -- the standing rule stands.
- 2026-08-17 10:50 CODEX ASSESSMENT RECEIVED and saved
  (External/CodexExchange/codex_assessment_stage2_strategy_2026-08-17.md,
  with the Fable-Max reconciliation appended). Convergent with Fable Max
  on: class forms = valid diagonal seeds (no global re-canonicalization);
  the off-diagonal completion is the missing stage and is the same
  equation in both replies; corrected Libra retry on CF230 + one
  unresolved family is experiment #1; by-parts at depth and bigger
  timeouts are the wrong tools; triple-root families are not obstructed
  (algebraic letters / segment charts / mixed rationalizations,
  arXiv:2501.07490). Divergent on the cure: Fable Max = direct graded
  primitive solve (choice-free, no tool); Codex = Libra/CANONICA
  implementations + the STRUCTURAL fix of master re-selection in
  affected sectors (arXiv:2002.08042, 2002.08173, 2503.19837 — nearly
  identical symptoms cured by choosing better masters before
  canonicalization), with finite-field reconstruction of D if swell
  (FiniteFlow). Still PAUSED: GPT Pro's reply pending; then a three-way
  decision memo before any implementation.
- 2026-08-17 11:15 ALL THREE REVIEWS IN; DECISION MEMO WRITTEN
  (`HardClasses/EpsFormRoute/DecisionMemo_2026-08-17_stage2_strategy.md`;
  GPT Pro's reply saved beside it with the user's planar-literature
  caution). Convergent core (C1-C7): class forms = valid seeds;
  off-diagonal completion before transport is THE cure; by-parts retired
  at depth; representation sane; numerics = checks; column economy;
  triple-root not obstructed. One open mechanism choice (direct graded
  solve vs corrected Libra), resolved by one head-to-head on CF230+CF124
  with master re-selection (Codex) as the trigger-gated contingency.
  Pro's submodule idea = cheap rank probe later (subtracted c-rows;
  additional route, not a replacement for master artifacts); function
  basis / one-fold deferred. Proposed execution order E1-E5 in the memo.
  AWAITING USER GO-AHEAD; nothing started.
- 2026-08-17 11:20 E1/E2 HEAD-TO-HEAD, FIRST VERDICTS (decision memo §2).
  E2 (sequential graded primitive, `Scripts/strip_gauge.wls`): STRUCTURALLY
  INCOMPLETE as prescribed -- measured tripwire on CF124 (strip (3,1),
  order 5, NonConstantResidue at v) and DERIVED: once a dlog part L
  appears at order k-1, dG_k = delta_i^L + L^delta_j != 0, so G_k is not
  closed and the per-order split fails; the reviewer's "flatness supplies
  closedness at every order" holds only through the first nonzero dlog
  order. The consistent solve is JOINT across eps-orders (unknown D AND
  the constant residues together) -- i.e. exactly Lee's FactorOut /
  CANONICA's recursion. Fable Max's Q1 prescription as stated is
  therefore wrong in detail; its diagnosis (one linear pass; apparent
  loci in the exact part) survives, implemented by the mature tool.
  E1 (corrected Libra, `Scripts/libra_offdiag_retry.wls`): after adding
  the FINITE Fuchsify pass (higher poles at finite points exist EXACTLY
  -- first version assumed simple) and an alternating y-pass:
  ** CF124 FULLY EPS-FACTORIZED IN 15.4 s ** -- Fuchsify finite+infinity
  (1.5 s + 0.3 s; the eps-dependent locus LEAVES the pole table),
  FactorOut in v (2.1 s), alternate Fuchsify+FactorOut in w (1.7 s);
  both components eps-factored, block-triangularity preserved, diagonals
  still eps-forms, strips eps-free, Ttot invertible. The family that
  cost 971 s per single eps-order by parts. Off[OptionValue::optnf] is
  load-bearing (the Projector trap): the identical run without it was
  the 2026-08-15 "Libra structurally unusable" verdict.
  E1d adds the gauge-identity gate vs the original permuted system and
  writes the route-2-consumable FamilyEpsForms record on success.
  CF230 running with the full alternating version (its q-locus sits at
  multiplicity 2; assembly alone 88 s). Agent B's CF124 GateFailed
  record backed up before overwrite.
- 2026-08-17 11:50 HEAD-TO-HEAD DECIDED (decision memo §2 rule):
  ** WINNER: corrected Libra (Fuchsify finite+infinity -> FactorOut,
  alternating in both variables; Off[OptionValue::optnf] load-bearing) **.
  CF124: fully eps-factorized in 15 s (971 s/order before); CF230: record
  written in 1422 s incl. exact gauge identity (Fuchsify 240 s, FactorOut
  123 s, y-side + gates the rest). The E2 sequential graded gauge
  tripwired on BOTH families at the derived obstruction (once a dlog part
  L_k appears, dG_{k+1} = delta^L + L^delta != 0): Fable Max's Q1
  closedness claim fails beyond the first nonzero dlog order; the solve
  must be JOINT across eps-orders, which is what FactorOut is. Codex's
  master re-selection contingency is NOT triggered (the loci were
  removed by a rational gauge). Route-2 window bug fixed (nTop =
  nMax - tmin; the padded window pushed weight past the cap).
  BATCH RUNNING: e1d_<CF> purification for all 41 blocked non-triple
  families (8-wide); a chain watcher submits each family's sweep mission
  (route 2, safety 1) as its record lands with GateVerdict True
  (Masters/chain_sweep.log). CF230's e1c record is in; r2x_CF124
  end-to-end validation passing its DE checks at close of entry.
- 2026-08-17 13:55 WATCHDOG LAPSE OWNED AND FIXED (user caught a 2 h
  unmonitored stretch -- against the standing rule): an Opus watchdog
  agent now runs 5-minute health rounds with alerts (log growth, pool
  liveness, failed verdicts, queue stagnation) and 30-min heartbeats.
  STATE: e1d batch 22/40 done -- EpsFactored so far CF13/18/21/124/226/
  230 (+ single-root chart families in flight); NotFactored cluster =
  the JOINT-CHART families: Fuchsify succeeds (CF232: all poles simple)
  but FactorOut times out at 1500 s on dim >= 18, and dims >= 23
  (CF254/265/305) time out in Fuchsify itself -- cancelled; next lever
  is Libra's Fermat backend (Fermatica`UseFermat; Fermat is in
  Addon/Other_Addon) -- probe queued. 33 records now gate. Chain watcher
  works (CF264/CF258/CF33/CF384... chained). r2x_CF124 validation
  TimedOut in the ORIGINAL-frame/inner DE checks (~170 s/order over a
  9-order window), not the transport.
  CODEX IS NOW WORKING IN OUR TREE (user-directed): it submitted
  codex_fast*_CF124 missions to our pool running OUR sweep script with
  ITS improvements -- per-block route-2 demand windows ("BlockDemands"/
  "BlockLowerOrders" engine options + masterTransportResolveBlockDemands
  in MasterTransport.wl, 13:39), ConstantDepth -> "PerBlockNeed", inner
  "DECheck" -> None. Its edits are exactly the sharpening route 2
  needed; I froze my own edits to that file mid-patch to avoid
  clobbering (one partial patch of mine was overtaken -- concurrent-edit
  hazard now real; coordination note to be exchanged).
- 2026-08-17 14:10 USER DIRECTIVES EXECUTED: (1) Codex's three wedged
  fast_CF124 kernels ENDED (user-authorized; 42-63 min frozen in the
  map-back phase, pre-superseded script versions) and its 8 queued
  missions HELD restorably in <pool>/held_codex/. (2) All stale
  background waiters of this session stopped; only the watchdog agent
  remains. (3) NEW PRIORITY REGIME: full capacity on transports we know
  how to do -- production sweeps of the purified single-root/root-free
  families first (16 running/queued, bumped to queue front) plus the
  remaining single-root purifications (CF48/50/52 running; CF53/56/57/
  91/97/98 queued; CF407/413/416/420 already gated); THEN the two-root
  study (Fermat backend probe queued; FactorOut/Fuchsify walls at
  dim >= 18; held missions in <pool>/held_tworoot/); ONLY THEN the
  triple-root three.
- 2026-08-17 14:45 PACKAGES (user standing authorization, recorded in
  memory + MANIFEST): Fermatica (rnlg/Fermatica @ abfd433) installed and
  wired to Addon/Other_Addon/Fermat/fer64 -- smoke test queued behind
  phase 1; consumer = Libra Fuchsify/FactorOut UseFermat->True for
  completing the family eps-forms of the two-root families (the dim>=18
  FactorOut wall). RationalizeRoots (marcobesier/rationalizeroots,
  GPL-3) installed; consumer = phase-3 triple-root feasibility. Phase-1
  status at entry: 49+ transported, completions all clean (CF48 1914 s,
  CF52 1854 s -- no single-root family hit the FactorOut wall), zero
  failures since 14:07.

2026-08-17 14:55 FERMAT GATE HARDENED (watchdog audit + tripwire).
  Watchdog audited the e2r wiring end-to-end and confirmed it correct:
  Fermatica loads (line ~54) BEFORE Libra (line 87), so Libra's load-time
  latch `$LibraUseFermat = MemberQ[$ContextPath,"Fermatica`"]` (Libra.m:4113)
  comes up True; runtime gate is $LibraUseFermat && OptionValue[Fermatica`UseFermat]
  (both required); Fermatica`UseFermat is genuinely in Options[Fuchsify] and
  Options[FactorOut]; $FermatCMD assignment has an upvalue that launches fer64
  and reads its banner. Independently re-verified: root= defined at line 35;
  $LibraUseFermat is public Libra` context with a Set-upvalue guard (Libra.m:2083).
  RISK CLOSED: with Off[OptionValue::optnf] active (load-bearing for Projector),
  a disarmed backend or a misspelled option would fail SILENTLY and burn the
  full 3600 s budget. Added tripwire to libra_offdiag_retry.wls after the Libra
  load: fermat mode asserts TrueQ[Libra`$LibraUseFermat] and membership of
  Fermatica`UseFermat in Options[FactorOut]; failure prints "[libraE1] FATAL"
  and Exit[3]. Healthy tell: "[libraE1] Fermat gate armed".
  pchk_e2r (priority mission): parse-only check of the edited script before
  e2r_CF232/e2r_CF231 dispatch. Watchdog watch list updated accordingly.

2026-08-17 15:05 TERMINOLOGY (user directive, supersedes wording in earlier
  entries; the earlier entries themselves are historical record and stand).
  - "passed the exact eps-form check" replaces "gate"/"gate-verified"
    everywhere in prose: the check is T-transforming the original system and
    verifying, as an exact rational identity in both variables, equality with
    eps Sum_a R_a dlog phi_a at constant R_a. The record field GateVerdict in
    already-written family_epsform_*.wl files remains as an identifier only.
  - "single-root batch / two-root batch / triple-root batch" replace
    "phase 1/2/3" (the word "phase" collides with phase space). No term for
    the transition; write "when the single-root batch finishes".
  - Status prose uses literal mechanisms and measured numbers, no metaphors
    (no fire/drain/wall/lever).
  Rules of language now standing: one literature- or house-anchored name per
  concept fixed at first use; no physics-domain words for scheduling/software
  concepts; metaphors replaced by the literal statement.

2026-08-17 15:45 CF249 FAILED / CF226 CANCELLED — both are two-root families
  whose transports slipped into the single-root batch because their
  completions (corrected Libra route, 12:11) passed the exact eps-form check
  and so were not in the held two-root backlog. The joint-root census is now
  fully accounted: 13 joint-root families = 11 held + CF226 + CF249.
  Failure signatures and levers recorded in held_tworoot/BACKLOG.md
  (transport-stage section). Queue audit: all remaining queued transports
  (sw_ and sw2_) are single-Kallen-chart families — no further joint-chart
  exposure in the single-root batch. Verdict statuses: sw_CF249
  PathDenominatorsNotLinear|TimedOut x2 at 4834 s; sw_CF226 cancelled at
  ~5900 s after route-2 TimedOut in both directions.

2026-08-17 16:45 DRIVER GAP (measured on the single-root tail): the sweep's
  post-transport stages are unbounded — original-frame DE check per order
  (CF230: >7,400 s inside eps^0 alone), valuation solve and map-back
  (CF258 ~6,500 s, CF26 ~6,600 s, sw2_CF33 ~2,600 s silent-but-computing).
  The 2400 s TimeConstrained caps bound transport operations only. 63
  families cleared these stages quickly; the dim>=24 tail swells there.
  FIX BEFORE TWO-ROOT TRANSPORTS (not hot-edited now, sw_CF97/98 still queued
  against the script): TimeConstrained per DE-check order recording
  DE:TimedOut (acceptance falls back to the certificate chain per R2), and a
  bound on valuation/map-back that converts a silent multi-hour stall into a
  recorded failure. CF230 decision rule: if still in eps^0 at 11,500 s,
  cancel, resubmit without the original-frame check, run that check OFFLINE
  from the written record (script to read Masters/CF230.wl + original DE).

2026-08-17 17:00 FERMAT SMOKE TEST FALSE ALARM RESOLVED + TRIPWIRE UPGRADE.
  fsmoke (0.16 s) proved binary/handshake/option/load-order but its two
  functional calls returned unevaluated. Diagnosis: the smoke test called
  FerSimplify/FerRowReduce, which are FeynHelpers' (FeynCalc add-on) Fermat
  stubs -- ZERO occurrences in Fermatica's source. Fermatica's actual API is
  the F* family (FTogether, FDet, FKer, FGaussSolve, ...). Installation
  unimpeached. Libra is context-shadowing-immune: it calls Fermatica`FDet/
  FKer/FQuolyMod/FDot/FInverse fully qualified (Libra.m 2096-2147).
  REAL RISK FOUND in Libra source: Fermat calls sit in CheckAbort with
  silent fallback to Mathematica ("resorting to Mathematica" log line) --
  a dead engine costs the full budget at plain speed with no error. 
  MITIGATIONS: (i) libra_offdiag_retry.wls fermat mode now has FUNCTIONAL
  tripwires -- FTogether identity after the Fermatica load, ODet-with-
  UseFermat end-to-end after the Libra load, both Exit[3] on failure;
  (ii) watchdog watches all e2r logs for "resorting to Mathematica";
  (iii) fsmoke2 queued at priority (real-API functional tests + latch +
  ODet end-to-end + parse re-check of the patched script). e2r_CF232/231
  HELD in held_fermatfix/ until fsmoke2 is ALL GREEN.
  ALSO: sw_CF299 failed TimedOut x3 at 7205 s (cost, not structural; block
  8/17 coefficient growth 6387 -> 8790 -> 10779 leaves). Goes to the pass-2
  retry list (larger cap or per-block economy), NOT the two-root backlog.

2026-08-17 17:05 FERMAT BACKEND VERIFIED FUNCTIONAL (fsmoke3, 0.6 s, ALL
  GREEN): FTogether/FDet/FKer compute through fer64; $LibraUseFermat latches
  True with FeynCalc preloaded; Libra ODet with UseFermat->True returns the
  correct determinant end-to-end; patched retry script parses (fsmoke2's
  Syntax:: death was a comment-terminator bug -- "Fer*)" closes a WL comment).
  POOL GAP noted for a later fix: a mission whose script fails to PARSE is
  recorded Status OK, HadMessages False, wall <1 s. Watchdog now scans
  Syntax:: and treats sub-second OK as suspect.
  e2r_CF232 and e2r_CF231 restored to the queue -> the two-root batch
  opening experiment is live: corrected-Libra completion with
  Fermatica`UseFermat->True, budget 3600 s, functional tripwires armed.

2026-08-17 17:08 CF230 TRANSPORTED (flagship single-root result): 10,398 s,
  direction 1, safety 1, weight 5, 19,276 words, DE:TrueWhereCheckable
  (938 s of checking; unchecked orders covered by the certificate chain per
  the co-signed acceptance). This is the end-to-end validation of the full
  pipeline on the hardest single-root content: hard class 77's certified
  two-variable eps-form -> family assembly -> completed family eps-form
  (corrected Libra route, 1,422 s this morning) -> blockwise transport ->
  exact certificates. The eps^0 original-frame DE-check stage that ran
  unbounded for ~2.5 h did complete on its own; the per-order bound remains
  a driver fix before two-root transports (16:45 entry).
  Board: 66 transported. e2r_CF232/CF231 live since ~17:05 with functional
  Fermat gates confirmed in both logs; CF232 on its 31 nonzero strips,
  CF231 assembling in Kallen23.

2026-08-17 18:20 CHECK SWAP EXECUTED (user directive): the symbolic
  original-frame DE check is REMOVED from the sweep driver, replaced by
  sweepSampledCheckDE -- exact evaluation of the per-order residual
  dI/dtau - Ahat.I at 3 random rational tau points, with every word and
  symbolic constant replaced by an independent random rational per sample
  (Schwartz-Zippel; all arithmetic exact; seed and sample points recorded
  in the artifact; method tag "SampledRational"). The withdrawn per-order
  time-bound idea is superseded: for standardized code the expensive layer
  is removed, not bounded (user's design ruling). The exact certificate
  chain (recursion certificate, valuation assertion, eps-form-frame check)
  is UNCHANGED and remains the acceptance. Validated on CF27: 3 orders
  checked in ~1 s (33 s symbolic on the old driver); verdict semantics
  match the current production driver (the TrueWhereCheckable /
  NotPerformable pattern is inherited from the per-block window change,
  which narrows checkable orders for deep-pole couplings -- an audit item,
  same for symbolic and sampled).
  SINGLE-ROOT ENDGAME per the same directive: sw_CF26/CF50/CF53/sw2_CF33
  cancelled mid-run (user order; ~11.6 h forfeited knowingly); CF258
  finished before cancel (13,377 s, transported, same shape as CF230).
  Rerun wave sw3_CF26/CF50/CF53/CF33 (cap 2400) + sw3_CF299/CF407 (cap
  5400, previous TimedOut x3) on the new driver. KNOWN RISK carried into
  the rerun: CF26/CF33 previously stalled INSIDE masterTransportValuation
  after "solved the linear constraints" -- a stage the check swap does not
  touch; watchdog watches for recurrence (>30 min -> alert -> direct fix).
  Two-root batch paused until the six land (user order). e2r_CF232 result:
  Fermat fixes Fuchsify (22.5 s), FactorOut still TimedOut at 3600 s, 0/31
  strips factored -> budget escalation dead; next lever CANONICA per-sector
  recursion / finite-field, after single-root closes. e2r_CF231 running.

2026-08-17 19:20 CF299/CF407 DIAGNOSIS CLOSED (fix-in-advance, no blind
  reruns). Measured: both fail identically at blockwise block 8/17 (dim 2)
  with word counts x5-6 per eps-order (2009/2541 at eps^1; ~10-13k at
  eps^2); demands are shallow (masters to eps^2 only) but the demanded
  rows of TTotal carry eps^-3 against most F-columns, so the direct
  block demands honestly reach 5 relative orders = weight-4/5 word
  closure on 17-block chains. Hypotheses tested and REJECTED: (i) window
  propagation ignoring demanded rows -- FALSE, the driver's blockDemands
  is row-restricted and correct; (ii) TTotal eps-depth removable by
  per-class scalar eps-rescaling -- FALSE, relative offsets are gauge
  invariant (rescaling relabels the window, cost unchanged). Comparison
  set: CF230 (6 blocks) and CF384 (20 blocks) carry the same -3 depth and
  succeed -- the failing pair's demanded chains hit the full closure where
  the survivors' demanded rows are shallow or terminal.
  DECISION: CF299/CF407 are deferred to ride with the two-root batch
  engineering, where the reviewer-endorsed column economy (C6: transport
  the physical boundary subspace, 1+q columns of F, nullity first) will be
  implemented -- word mass scales with columns, and these two families'
  cost profile is exactly the two-root transport class. No further cap
  retries (exponential growth, measured).

2026-08-17 19:45 SAMPLED-CHECK FALSE NEGATIVE FOUND AND FIXED. sw3_CF50/
  CF53 failed with OriginalDECheckFailed in 54-82 s on both route-2
  directions -- yet CF50's earlier SYMBOLIC run had passed eps^0 before
  cancellation, and on CF27 the sampled zero-test path had only ever
  returned InsufficientOrders (never exercised). Cause: the word-
  randomization rules were built from Variables[I] only, but dI/dtau
  peels leading letters and the peeled sub-words need not appear in I;
  an unsubstituted word symbol makes the residual spuriously nonzero.
  FIX: rules now cover Variables[{I, dI/dtau}]; plus a discrimination
  label -- non-numeric residual content is reported as
  "SampledLeftoverSymbols" (a coverage bug), never conflated with a
  genuine nonzero residual. VALIDATED: CF388 rerun reproduces its
  symbolic result exactly (TrueWhereCheckable, 2883 words, sampled True
  verdicts on the checkable orders, 24 s). sw4_CF50/CF53 rerunning on the
  fixed driver. Lesson recorded: a check is only validated when its PASS
  path has fired on a known-good case; CF27's all-InsufficientOrders
  "validation" validated nothing.

2026-08-17 20:05 MU LEAK: FOUND, REMEDIATED, REGENERATING. Following the
  external reviewer's flag (CF226/CF249 transport failure inconsistent
  with a certified family eps-form), the CF249 denominator probe exposed a
  third symbol in the record: Libra FactorOut's auxiliary gauge parameter
  mu (script symbol muS). Census: ALL 12 records completed before the
  muS->1 substitution entered the writer (~12:16) carry bare mu -- CF124
  CF13 CF18 CF21 CF226 CF230 CF248 CF249 CF253 CF258 CF260 CF264 -- and 9
  banked transport artifacts inherit it (CF258 worst, 578k occurrences;
  CF230 315k). Every check passed because the certified identity holds
  for ALL mu; a free spurious parameter nevertheless invalidates the
  artifacts as stage-3/4 inputs, and the transport engine reading mu as a
  kinematic symbol explains CF249's PathDenominatorsNotLinear and
  CF226/CF258-class costs (mu-swollen coefficients).
  REMEDIATION (remed_mu2; first attempt died at parse and the pool
  recorded OK -- third instance today of the parse-death gap; KernelPool
  wrapper fix committed-to at next pool restart): all 12 records
  instantiated at mu=1 (the writer's convention), verified -- sampled
  inverse identity at 2 rational points, entrywise eps-linearity, letter
  count preserved; originals kept as .premu; atomic rewrites.
  REGENERATION: sw5_ wave of 11 (CF249 CF226 leading as the plumbing-
  theory test, then CF21 CF248 CF13 CF18 CF253 CF260 CF264 CF230 CF258).
  ALSO: centralizer probe (reviewer item 1): CF299 dim Z <= 1 -> SCALARS
  ONLY, proven (projection is the only lever); CF407 dim Z <= 3 ->
  nontrivial candidate, refine with true residues before building
  projection machinery for it. External reviewer reply archived at
  HardClasses/EpsFormRoute/ChatReply_2026-08-17_evening_transport_state.md;
  its R1-R3 fixed-point window arithmetic + runtime window audit +
  factored artifacts (constants never substituted) are the next
  implementation block (CF50/CF53 closure path).

2026-08-17 21:05 SECOND FERMAT DATA POINT (e2r_CF231, 10,999 s, record in
  session scratchpad e1/): at 23x23 the system NEVER reaches Fuchsian form
  in y -- finite Fuchsify TimedOut at 3600 s twice (infinity legs fine,
  537/586 s), FactorOut never ran ("skipping FactorOut: system not
  Fuchsian in y"), and the two rounds DENSIFIED the couplings (non-eps-
  factored strips 31/36 -> 35/38). Structure survived (triangularity,
  diagonal eps-forms, invertibility all True). Ladder state after both
  data points: dim 18 = Fuchsify seconds + FactorOut wall; dim 23 =
  Fuchsify wall itself; Fermat cures neither wall. RULES ADOPTED: no
  repeated Fuchsify rounds at dim >= 23 (measured harmful -- strip count
  worsens); the corrected-Libra+Fermat route alone completes no two-root
  family; the 9 held two-root completions STAY HELD until the next rung
  lands. CRITICAL PATH for the two-root batch = reviewer item 7: strip
  completion as a LINEAR problem in the unknown D-entries (joint across
  eps-orders -- linearity is what finite-field reconstruction needs, not
  per-order grading, reconciling the E2 structural failure with the
  reviewer's graded-linear framing), decisive test on CF232's worst
  strip. CANONICA per-sector recursion (epsform_offdiag_cf230_canonica.wls,
  parameterized) stays the comparator; needs its probe-format assembly
  artifact for CF232 -- input reconciliation deferred to the next work
  block rather than rushed (three hasty-script bugs today).

2026-08-17 21:35 SW5 WAVE OUTCOME (corrected interpretation after the
  watchdog's overwrite alarm). SUCCESSES on remediated records, all with
  the sampled check's pass path genuinely firing: CF13 121 s, CF18 99 s,
  CF260 85 s, CF264 179 s (was 2185 s), CF258 692 s (was 13,377 s -- 19x;
  the mu-swollen coefficients were most of its old cost). Clean artifacts
  written. FAILURES with the genuine-residual signature (seconds-fast
  OriginalDECheckFailed on both route-2 directions): CF21, CF248, CF253 --
  joining CF50/CF53 and CF230 (dir 2 in flight when cancelled): the
  window-under-coverage class predicted by the reviewer's R1 (TTotal
  positive eps-powers truncating the F-window bottom); these six wait on
  the fixed-point window implementation (task #12). The failures are the
  CHECK WORKING, not a check defect. CF249: PathDenominatorsNotLinear
  SURVIVES the mu-clean record -- the joint-chart refusal is real, not
  plumbing; CF226 likewise TimedOut. Both remain two-root-scope transport
  work (projection/window rework). WRITER GUARD added to sweep driver: a
  non-Transported status never silently overwrites a Transported line
  (superseded line preserved as .status.prev). Three overwritten status
  lines: CF21's restored verbatim to .prev (watchdog had read it); CF248/
  CF253 recorded as lost-line stubs; all three artifacts (.wl) intact and
  mu-quarantined regardless. Single-root clean-and-transported now 60;
  pending window fix: CF21 CF248 CF253 CF50 CF53 CF230 (+CF26/CF33 via
  factored artifacts, CF299/CF407 via projection).

2026-08-17 21:05 USER DIRECTIVES + POOL RESTART. (1) Two-root batch PAUSED:
  all single-root families finish first. sw5_CF249/CF226 cancelled; the 9
  held two-root completions and all two-root transport work stay held; the
  CF232 strip-reconstruction experiment deferred until single-root closes.
  (2) Pool resized 8 -> 6 subkernels (restart 21:02, preload 2 s): two
  license slots left free for Codex, standing arrangement while both
  assistants are active. (3) KernelPool wrapper PARSE GATE landed with the
  restart: an unparseable mission is now status PARSEFAIL (loud), never OK
  -- closes the three-times-measured parse-death gap (fsmoke2, remed_mu,
  fermatprobe). Single-root remaining set (the focus): CF21 CF50 CF53
  CF230 CF248 CF253 (window fix, task #12) + CF26 CF33 (factored
  artifacts, same task) + CF299 CF407 (observable-quotient route pending
  Codex's CF27 validation). 60 single-root/root-free families are
  transported clean.

2026-08-17 21:20 COUNT RECONCILIATION (correcting the 21:05 entry's "60"):
  Masters on disk 88 = 64 Transported + 21 Failed + 3 ChartNotCovered.
  Clean-and-transported = 63: the 64 minus CF230 (status line predates its
  cancelled rerun; artifact mu-quarantined, regeneration owed after the
  window fix). CF124 verified CLEAN: Route -> Direct at 07:40 (predates
  the contaminated record by ~4.5 h; route 1, never consumed it), 0 mu,
  20/20 certificate blocks True; note it carries safety0 (strict-need
  depth, pass-2b convention) -- fine under the ledger, flag at ledger
  regeneration. The 9 sometime-contaminated artifacts resolve as: 5
  regenerated clean (CF13 18 258 260 264), 3 currently Failed pending the
  window fix (CF21 248 253), 1 quarantined-Transported (CF230).
  Single-root focus set unchanged: CF21 50 53 230 248 253 (+CF26/33,
  CF299/407) = 10 to finish.

2026-08-17 22:30 PAD EXPERIMENT REQUEUED (watchdog catch): the pad-2 runs
  hit the 2400 s per-direction envelope BEFORE reaching the sampled check
  (direction 1: >2403 s padded vs 284 s unpadded, >=8.5x) -- a TimedOut
  there would be no-answer, not a negative. Cancelled; requeued as
  w12pad2_CF50/CF53 with envelope 7200 s (statuses in session scratchpad
  win12/out3/). Control reproduced: w12dump_CF50 unpadded fails the check
  at the usual point (and banked the full 14.9 MB diagnostic dump of every
  object the check consumed, win12/diag/). Cost datum recorded: a blanket
  bottom-pad of 2 is >=8.5x on direction cost -- the production fix must
  derive PER-BLOCK bottoms from the entry-wise fixed-point arithmetic
  (R1-R3), not blanket-pad; the blanket is diagnostic only.

2026-08-18 00:55 PAD EXPERIMENT TERMINATED (design wrong, not hypothesis):
  direction 1 timed out at 7,200 s on BOTH CF50 and CF53 -- the blanket
  bottom-pad costs >25x (284 s -> >7,200 s), not the 8.5x lower bound,
  because widening the global window [lowF-2, nTop] raises the attainable
  WORD WEIGHT of every block by 2 (letters^2 per level), not just the
  order count. Both missions cancelled before burning ~4 more hours on a
  guaranteed no-answer. The experiment's instrument was wrong; the
  hypothesis stands untested by intervention.
  SHARPENED HYPOTHESIS (from the window-arithmetic analysis): the carried
  bottom blockLowerOrders[j] = min ord_eps(TTotalInverse rows) bounds the
  PHYSICAL solution's valuation (correct only after constants are fixed),
  but the recursion transports the GENERAL solution whose constants are
  fixed AFTERWARD by the valuation step. Truncating the general solution
  at the physical bound can starve the constant-fixing system, producing
  constants that satisfy every computed order (certificates + valuation
  assertion pass) yet fail the original DE -- exactly the observed
  signature on the six. The production fix is unchanged in kind (task
  #12: per-block GENERAL-solution bottoms from class-form kmins via the
  R1-R3 fixed point), now with the explicit requirement that the bottom
  serve the constant-fixing, not merely the delivered series.
  NEXT ENTRY POINT (reviewer's own prescription): localized symbolic
  residual -- rebuild ONE failing (row, order) slice from the banked CF50
  dump (win12/diag/CF50_dir1_diag.wl) and Together that slice alone; its
  letter/word content names the culprit directly. Then implement per-block
  bottoms and validate on CF50 at per-block (not blanket) cost.
  ALSO: Codex has begun submitting missions to the shared pool
  (codex_cf299_pid25_diag, failed -- its own workspace, untouched).

2026-08-18 02:20 SIX FAMILIES EXONERATED; CHECK FIXED, VALIDATED, RERUNS
  LAUNCHED. Chain of evidence: (1) the stored deCheck labels of every
  "failing" run were SampledLeftoverSymbols (leftover {x,y}), never
  {False} -- the status mapping collapsed a check-coverage defect into
  OriginalDECheckFailed and it was misreported as a genuine residual
  without reading the labels (coordinator error, caught via Codex's dump
  inventory 01:03). (2) Codex's corrected offline check
  (corrected_residual5, 34.7 s) returned True/True/True at the previously
  failing orders on the banked CF50 dump. (3) The operative fix is
  SUBSTITUTION ORDER in the sampled check: tau -> t0 FIRST, then the
  randomization rules (tau-carrying composites evaluate toward exact
  numbers before rules apply; only genuine unknowns receive randoms);
  ported into sweepSampledCheckDE together with a numeric-aware zero
  criterion (RootReduce; leftover label only for non-numeric content).
  (4) Offline validation w14chk PASS: the PORTED driver code reproduces
  Codex's result exactly on the same dump -- {True} at orders 0/1 of all
  demand groups, InsufficientOrders only where the window honestly
  refuses. NO WINDOW DEFECT EXISTS in the six: the under-coverage epic
  (pad experiments, general-solution-truncation hypothesis) is closed as
  a misdiagnosis cascade rooted in the check, not the transport. The
  window-arithmetic audit (R1-R3) remains as HYGIENE for the honest
  InsufficientOrders narrowing, no longer a blocker. Production reruns
  sw6_CF50/CF53/CF21/CF248 launched (Masters outdir); CF253/CF230 follow
  as slots free (Codex keeps ~2). Remaining after this wave: CF26/CF33
  (factored artifacts) and CF299/CF407 (observable-quotient route).

2026-08-18 02:50 SINGLE-ROOT MILESTONE: 69 CLEAN TRANSPORTED (88 records =
  69 Transported + 16 Failed + 3 ChartNotCovered; arithmetic with
  provenance: 63 + 5 (CF50 CF53 CF21 CF248 CF253 moved Failed ->
  Transported) + CF230 regenerated in place). All six sw6 runs passed the
  fixed sampled check with genuinely evaluated orders and ZERO False:
  CF248 11 s, CF21 13 s, CF253 44 s, CF53 152 s, CF50 177 s, CF230 355 s
  (29x faster than its original 10,398 s run -- mu-clean record + sampled
  check). MU-QUARANTINE FULLY CLEARED: no MuQuarantinedArtifact status
  tokens remain; CF230's regenerated 7.1 MB record carries no mu under
  six spellings (watchdog scan).
  PROVENANCE CLARIFICATION for the ledger regeneration: the three
  .status.prev files (CF21/CF248/CF253, "Transported ...
  MuQuarantinedArtifact") are the coordinator's MANUAL history stubs
  written ~21:35 after the r82 overwrite incident (CF21's line verbatim
  from the watchdog's read; the other two as lost-line stubs) -- not
  writer-guard products. The mu quarantine properly attributes to all
  NINE sometime-contaminated artifacts: five regenerated in the sw5 wave,
  CF21/CF248/CF253 + CF230 regenerated in the sw6 wave. CF230 was merely
  the last carrier, not the only one.
  COVERAGE NOTE (honest, corroborated by Codex's independent driver):
  CF253 and CF230 verify on thinner check coverage (3 True / 6
  InsufficientOrders = one verified order x three sample points) than the
  other four (18-24 True) -- a property of those families' deep-pole
  couplings vs the carried windows, not of the run. The entry-wise window
  audit (task #12 hygiene) is the item that would widen their checkable
  sets. Independent corroboration: Codex's separate driver (01:15-01:21)
  reproduces our verdict tallies family by family, incl. CF253's 3/6.
  SINGLE-ROOT REMAINING: CF26/CF33 (factored artifacts) and CF299/CF407
  (observable-quotient route). Two-root stays paused per user order.

2026-08-18 03:20 CORRECTION OF THE 02:20 ENTRY (Codex's diagnosis is the
  authoritative account; External/CodexExchange/
  codex_transport_checker_diagnosis_2026-08-18.md). The original-DE
  checker had TWO defects, both mine: (1) x,y left symbolic in A_tau
  while randomized elsewhere; (2) after fixing (1), A_tau and d_tau I were
  evaluated at tau0 but I on the RIGHT-hand side was not -- I carries tau
  explicitly (7,876 bare tau tokens in CF50's stored series), so the
  residual mixed evaluated and unevaluated tau. The 02:20 entry's
  "substitution ORDER" framing was imprecise: the operative missing piece
  was evaluating I at tau0 at all (my port happens to include it, which is
  why the six passed). VERIFIED CONSEQUENCE, contradicting my earlier
  "scheduler starts too high" diagnosis: with UNCHANGED transport depth
  and the corrected checker, CF21/CF50/CF53/CF248/CF253 are all
  TrueWhereCheckable (Codex 17-205 s; our sw6 runs agree). The remaining
  InsufficientOrders are the UPPER-window statement (the original DE has
  eps^-2 terms, so checking order n needs I_{n+2}) -- extending the TOP
  of the series would widen the checkable set, never lowering the bottom.
  The downward-padding experiment was therefore unnecessary in principle,
  not just badly instrumented. Rule recorded: when a check fails, first
  prove the CHECK on a known-good case, then read the stored labels;
  never propose a transport mechanism from status lines.

2026-08-18 04:10 REMAINING FOUR — STATE CORRECTED (Codex assessment,
  External/CodexExchange/codex_assessment_remaining_single_root_2026-08-18.md,
  accepted in full):
  CF26/CF33: diagnosis confirmed by the CF26 probe (transport 177 s;
  392 equations solved 0.8 s; then Map[Together[# /. rules]&, F] over
  136,167,224 bytes / 9 orders / 25 rules stalls; the sparse-word-map
  route has the same expansion). Fix = matrix-valued word coefficients
  F = Sum_w w C_w c with c = N b from the valuation kernel; the constraint
  becomes C_w -> C_w N (small exact matrix products; no whole-expression
  Together). Codex's PreTransportValuation_CF26/33.json hold the rank
  census only -- exact kernel matrices + package integration NOT done.
  Probe cancelled (measurement banked).
  CF299/CF407: my "quotient route pending CF27 validation" was STALE.
  Codex's exact observable-only two-segment transport is COMPLETE in its
  isolated records: valuation kernels over Q(z1,z2), induced spectator
  systems, two-segment sparse word maps (CF299 249, CF407 1187), exact
  recurrence identities, and CF27 validation DONE (six symbolic
  differences through eps^2 exactly zero); endpoint-mode matching done for
  the relevant modes. Remaining: integration into the FeynFacet artifact
  schema + four boundary periods B_8, B_9, B_25, B_23 (stage-3 objects,
  not a transport obstruction). NO further 17-block word closure runs.
  COUNTING CONVENTION (adopted): "69 of 73" = production TRANSPORT
  records only. Every family carries three separate statements from now
  on: (i) transported map known, (ii) endpoint modes matched, (iii)
  boundary periods evaluated. Stage-3 (periods) remains the open campaign
  for ALL families; the transport count is not "solved masters".
  ORDER: (1) matrix-valued coefficients + pre-transport valuation ->
  CF26/CF33 production records; (2) convert CF299/CF407 observable maps +
  endpoint substitutions into the production schema; (3) three-statement
  tracking in the ledger.

2026-08-18 03:35 CF26/CF33 FIX — TWO REPRESENTATIONS SHIPPED, BOTH EXACT ON
  CF50, COST MEASUREMENT RUNNING. (a) masterTransportSubstituteConstants:
  per-word-coefficient substitution (no whole-expression Together; Total-
  once assembly per Codex review). (c) masterTransportConstantKernel +
  masterTransportApplyKernel: matrix-valued word coefficients, c = N b
  from the solved valuation rules, constraint applied as row_w . N per
  word -- the standardized constant-space representation (Codex + external
  review); masterTransportValuation now takes the kernel route whenever
  the constants list is available, falling back to (a). REGRESSION TESTS
  (acceptance: identical Masters record to the pre-change method on a
  known-good family): CF50 via (a) 159 s and via (c) 170 s, both
  reproduce the original record exactly (6832 words, w5,
  DE:TrueWhereCheckable). CF26 measurement: sw7_CF26 (route a) 19 min in
  substitution and pker_CF26 (route c) 5 min in substitution at 03:35,
  neither returned -- 136 MB of coefficient content is heavy under both;
  the run decides. If both exceed ~1 h: the general solution must not be
  materialized at all -- Codex's PRE-transport kernel (constants
  restricted before word generation) is the next rung, requiring the
  exact N(w) for CF26/CF33 (only the rank census exists today).
  Overnight cron armed (hourly :23): read Codex's CodexExchange feedback
  first, act, advance CF26/CF33 -> CF299/CF407 schema integration ->
  three-statement ledger; stop when all four have production records.

2026-08-18 04:45 CF26 TRANSPORTED (production record): 3,187 s, direction
  1, weight 5, 13,482 words, DE:TrueWhereCheckable (165 s) -- the family
  that never returned from constant substitution now completes. Both new
  representations finish and agree exactly: per-coefficient substitution
  2,998 s (136 MB -> 5.2 MB), kernel route 2,829 s (-> 3.3 MB), identical
  Masters record. Measured ceiling of this fix: the cost is processing the
  swollen 136 MB GENERAL solution (Expand/collect per entry) -- ~50 min
  even without any whole-expression Together (CF50's comparable 48 MB
  order takes 6 s: CF26's entries are structurally denser). Functional,
  not fast; the standardized answer remains constants restricted BEFORE
  word generation (Codex's pre-transport kernel), which is the only route
  that never materializes the 136 MB. Profile mission (fprof) cancelled as
  redundant. sw7_CF33 launched to production with a 4,800 s per-direction
  envelope.

2026-08-18 04:20 CF299 AND CF407 — PRODUCTION RECORDS WRITTEN (Route
  "ObservableOnly", provenance Codex). New Scripts/integrate_observable_
  transport.wls consumes Codex's FeynFacetObservableDLogTransport v1
  records (Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17/) and
  establishes INDEPENDENTLY in our kernel before writing: V1 structure +
  exact rational entries in the chart variables; V2 every record dlog
  letter divides a letter of OUR certified family eps-form for the same
  family/chart (ties Codex's alphabet to our stage-1/2 certificates); V3
  path-pole reconstruction from scratch (d/dtau log phi(z(tau)) equals the
  record's pole expansion exactly, algebraic roots via RootReduce); V4 the
  source certificate block all True. Both families: V1-V4 True. Word
  counts match Codex's published census exactly (CF299: 80 = 1+5+26+48;
  CF407: 357 = 1+8+57+291, both through weight 3 -- nothing above weight
  3 contributes through physical eps^2). Records carry the maps
  contracted into the master representation (rows {eps-order, master}
  over the boundary-coordinate vector), the source maps, a Provenance
  block ("Codex observable-only transport"; what was and was NOT
  re-verified here -- the transport itself is not repeated), and the
  THREE-STATEMENT block: TransportedMapKnown True; EndpointModesMatched
  "Codex records (not re-verified here)"; BoundaryPeriodsEvaluated False
  (B_8, B_9, B_25, B_23 are stage-3 items). Cost: 0.2 s and 4 s.
  Schema note: Codex's Path sub-association carries Base/Target; the
  parameter is unnamed (poles written for z(tau) = base + tau(target-base)
  in the first variable) -- the reader introduces its own tau.
  Single-root remaining: CF33 only (sw7_CF33 running, envelope 4800 s).

2026-08-18 04:35 CORRECTION — TWO SINGLE-ROOT FAMILIES WERE MISCOUNTED AS
  COMPLETED: CF48 and CF52 (Q4b chart, root 4v+w^2, class 98; 87 nonzero
  coupling strips each). Their e1d completion missions exited OK at 1914 s
  and 1854 s on 2026-08-17 and I reported "all single-root completions
  succeeded" from the mission status; the verdict files say otherwise:
  Status NotFactored, GaugeIdentity False, "FactorOut: TimedOut in 1500 s"
  -- no family_epsform record was ever written, and their transports have
  only the pass-1 route-1 timeouts (06:23/06:31, 1200 s). Same failure
  class as the two-root FactorOut wall (CF232), reached at single-root
  through strip count (87 strips vs <=31 elsewhere). Rule broken: a
  mission's OK status is not the result; the record is. Rule recorded.
  Consequence for the single-root close-out: the batch cannot close on
  the four families named at 21:05; CF48/CF52 are open with the same
  method dependency as the two-root completions (Fermat does not cure
  FactorOut, budget escalation is dead) -> their path is the linear-
  reconstruction rung (reviewer item 7) or CANONICA per-sector recursion,
  i.e., the two-root completion method, applied at single-root. Also
  found by the three-statement ledger tool (Scripts/three_statement_
  ledger.py, new): CF226 has no status file at all (cancelled before any
  write; two-root scope, expected).
  Honest single-root count at 04:35: 72 transported map known of 73 named
  in the single-root batch definition, PLUS CF48/CF52 which were wrongly
  in the "done" column -> the correct denominator is 75 single-root/
  root-free families; 72 done; open: CF33 (running), CF48, CF52.

2026-08-18 05:40 CF48 STRIP MEASUREMENT (measure-only probe smeas_CF48;
  data scratchpad r1/strip_measure_CF48.wl) -- the reconstruction rung's
  concrete size: 27x27, 20 blocks (dims 1-2), 87 nonzero coupling strips,
  70 NOT eps-factored; unknown strip-gauge entries D_ij over all bad
  strips = 156 (strips are 1x1..2x2); entry eps-Laurent range {-3, 4};
  only 10 distinct kinematic denominator factors across all bad strips.
  Assembly itself: 100 s (status DepthExceedsCap is the transport depth
  guard at Orders {0,1}, irrelevant for the strip census). READ: the
  FactorOut wall (1500 s timeout, 87 strips) is the cost of Libra's GLOBAL
  27x27 nullspace over Q(x,eps), not of the content -- 156 rational
  unknowns with 10 denominator factors is a small sequential problem.
  Design for the build (Codex 04:24 + reviewer item 7): process strips in
  the sector order (i ascending, j descending); for each strip solve the
  LINEAR condition on D_ij (joint across eps orders, unknown rational
  entries with the measured 10-factor denominator ansatz; if the ansatz
  fails, reconstruct from prime-field samples) with the exact purity
  assertion (constant residues, eps-free letters) as acceptance; compose
  into TTotal; final acceptance = the exact eps-form check (both
  variables). CANONICA per-sector recursion stays the comparator.
  Not started tonight (delicate build; do it at full attention in the
  morning); CF52 is the same chart/class and follows CF48 directly.

2026-08-18 05:55 CLOSE-OUT OF THE FOUR SCOPED FAMILIES (CF26 CF33 CF299
  CF407) — ALL FOUR NOW CARRY PRODUCTION RECORDS. CF33: 1,674 s, weight 5,
  10,769 words (substitution 1,189 s), certificates 20/20 True. CF26:
  3,187 s, 13,482 words, 20/20. CF299/CF407: observable-only route,
  V1-V4 True, provenance Codex.
  STATED PLAINLY: CF26 and CF33's sampled original-frame checks evaluated
  ZERO orders (all 15 verdicts InsufficientOrders: their forbidden-order
  depth to eps^-6 puts every checked order beyond the carried top window).
  Acceptance rests on the certificate chain (assembly certificate,
  recursion certificate all-zero, valuation assertion) -- the co-signed
  criterion -- and NOT on an evaluated original-equation residual. They
  join the "vacuous-check" class (21 audited yesterday); the entry-wise
  window audit (R1-R3 hygiene) is what would give them evaluated orders.
  CF299/CF407: transport map known (Codex), endpoint modes matched in
  Codex records (not re-verified), boundary periods B_8 B_9 B_25 B_23 NOT
  evaluated.
  SINGLE-ROOT BATCH STATUS: 73 of 75 transported map known. OPEN: CF48,
  CF52 (family eps-form NOT completed; FactorOut wall at 87 strips;
  reconstruction-rung build specified at 05:40, to be built at full
  attention -- not tonight). The batch is NOT closed; two-root stays
  paused per user order until CF48/CF52 are done. The overnight loop
  continues for Codex feedback and pool health; the CF48/CF52 build is
  the morning's first item.

2026-08-18 05:36 CLOCK CORRECTION (Codex 05:26 note, verified):
  the 2026-08-18 entry headings from ~02:20 through "05:55" were stamped
  from an inflated internal clock, running up to ~75 min AHEAD of the
  system clock (e.g. the "05:55" close-out entry was written at 04:40
  system time; CF33's mission ended 04:38:20 by the kernel clock). The
  ORDER of entries is correct; the absolute times are not. Filesystem
  mtimes and kernel logs are authoritative for that stretch. From this
  entry on, headings are stamped from `date`. Rule (already in memory
  as a time-of-day rule) extended: every plan heading is generated by
  `date`, never typed.

2026-08-18 05:57 CF48 RECONSTRUCTION RUNG — FIRST PROBE (session
  scratchpad r1/strip_recon_probe.wls; three runs sprobe/sprobe2/sprobe3):
  the joint-in-eps LINEAR strip-gauge solver is VALIDATED (self-test:
  manufactured strip with known gauge D0 -> 72 unknowns, 140 conditions,
  1 solution, recovered strip eps-factored). Measured on CF48: 9 of the 70
  bad strips are CLOSED (no bad strip at shorter distance in their rows/
  cols, so solvable in isolation); the smallest, strip {8,6} (dims 1x2,
  13 leaves, eps range {0,2}), returns an INCONSISTENT system at every
  ansatz size (denominator basis = the strip's AND both diagonal blocks'
  letters {p, p-s^2, s, p-1, ...} and their squares; numerator degree up
  to 8 per variable; eps orders {-2..2}; up to 810 unknowns; solve <1 s
  each). READ: no rational gauge with poles at the strip's own letters
  eps-factors this strip in isolation. Two live explanations for the
  morning: (i) the gauge needs poles at letters absent from the strip and
  its diagonals (apparent loci of OTHER blocks -- widen the basis to the
  family's full alphabet, cheap); (ii) closed-in-my-sense strips still
  couple through the diagonal blocks' internal structure and must be
  solved in the sequential composition, not in isolation. Discriminating
  test = (i) first (one run). CF52 same chart/class, follows CF48. No
  FactorOut retries (Codex 05:26); no records touched.

2026-08-18 06:18 ROUND NOTE: explanation-(i) test running (sprobe4:
  full family alphabet, 21 denominator factors, as gauge basis for strip
  {8,6}; dmax 2 already inconsistent, dmax 4/6 solving -- degree-~40
  common denominator makes these slower). Result read next round. If
  still inconsistent at dmax 6 -> explanation (ii): sequential coupled
  composition is required from the first strip; the build then follows
  the sector order with the validated linear solver, composing D into
  TTotal strip by strip. Pool otherwise idle (Codex slots free).

2026-08-18 06:19 ROUND 3 CLOSE: sprobe4 (full 21-letter alphabet
  basis) inconsistent at dmax 2 (90 unknowns); dmax 4 still forming its
  system after ~18 min (degree-~40 common denominator) -- left to finish
  on the idle pool, result to be read but the low-degree inconsistency
  already shifts weight to explanation (ii): strip {8,6} is not
  completable in isolation; the completion is a coupled sequential
  construction (Codex per-sector recursion) with the validated joint-in-
  eps linear solver at each step. That is the morning build. State:
  73/75 single-root transported; CF48/CF52 open, method identified,
  solver validated, coupling structure to be built. Codex feedback
  through 05:26 fully acted on; plan headings now from `date`.

2026-08-18 06:36 CF48 RUNG — DESIGN FIXED (Codex 06:27, accepted in
  full; sprobe4 cancelled: full-alphabet basis inconsistent at dmax 2 and
  4, and further escalation would only measure the degree-~40 denominator
  blow-up, not the mathematics). Two corrections to my probe design:
  (1) "closed bad strip" was too weak -- for a block-lower-triangular
  connection D_ij obeys dD_ij = A_ii D_ij - D_ij A_jj + R_ij with R_ij
  containing the coupling AND terms induced by shorter-distance gauges,
  and HOMOGENEOUS freedom left in already-factored shorter strips may be
  needed for a later strip's solubility; no strip is an isolated problem.
  (2) poles/pole orders of D_ij must be derived from the actual
  inhomogeneous term R_ij, never from the whole-alphabet product.
  THE BUILD (morning, full attention): recursive in block distance i-j;
  at each distance solve all D_ij jointly in eps with the validated
  linear solver, RETAINING homogeneous parameters from earlier distances;
  form R_ij only after composing the transformations already fixed; poles
  from R_ij; after every distance, exact check in BOTH variables that all
  processed strips are eps x constant-residue dlog; FINAL criterion = the
  full 27x27 two-variable exact eps-form check, never single-strip
  solvability. CF52 from CF48 only via an explicit, checked family map.
  Assets in hand: validated joint-in-eps linear solver (self-test
  passed), strip census (156 unknowns, eps range {-3,4}, degrees to 14),
  assembly path (100 s). No FactorOut retries.

2026-08-18 07:36 ROUND 5 (Codex 07:29 acted on). (a) Build
  requirements added to the CF48 design: at each distance retain a
  homogeneous-parameter basis ONLY for transformations preserving all
  strips fixed at shorter distances -- quotient trivial null directions
  immediately; checkpoint per distance (composed gauge, remaining
  homogeneous basis, exact zero residuals of every processed strip);
  large exact systems -> solve over several primes and reconstruct, then
  verify the reconstructed gauge SYMBOLICALLY before proceeding. FIRST
  REAL MILESTONE = block distance ONE for CF48 complete (exact two-
  variable eps-factorization of every distance-1 coupling, homogeneous
  parameters for distance 2 retained), not another isolated strip.
  (b) RECORD-INTEGRITY DEFECT (Codex): mission name sprobe4_CF48's LOG
  was overwritten by the cancel/re-dispatch race's zero-second re-run --
  the 2,338 s calculation log is gone (the plan entries preserve the
  scientific summary; the raw log evidence does not survive). Third
  log-loss mode this campaign (cancel stubs; DUPLICATE overwrites; race
  re-run). POOL FIX QUEUED for the next restart: append-only mission
  logs (open with Append, or rename any existing log to
  <name>.log.<timestamp> before a fresh start) -- staged alongside the
  FILEGONE fix. Until then: unique mission names per run (already my
  practice from the sw6/sw7 suffixes; the probes violated it).
  Pool idle; no CF48 construction running (deliberate: full-attention
  build in the morning). Count unchanged: 73/75.

2026-08-18 08:36 ROUND 6 (Codex 08:29 acted on): log preservation
  hardened per its review -- unique archive destination (timestamp +
  monotone counter), RenameFile success verified, and a mission whose old
  log cannot be preserved is refused with status LOGPRESERVEFAIL instead
  of truncating. Staged with FILEGONE + PARSEFAIL for the next pool
  restart. No physics change; count 73/75; pool idle; CF48 distance-one
  construction remains the next calculation (morning, full attention).

2026-08-18 09:36 ROUND 7 (Codex 09:29): log-preservation fix confirmed
  by source inspection; staged, inactive until the next deliberate pool
  restart (no restart needed for an idle pool). No calculation ran this
  hour by design. State for the morning: 73/75 single-root transported;
  CF48/CF52 open -- next calculation = exact distance-one solution of the
  complete CF48 block system (all distance-1 strips jointly, homogeneous
  parameters retained, exact two-variable residual identities); CF52 via
  an explicit checked family map. Two-root paused; pool idle for Codex.

2026-08-18 10:36 OVERNIGHT LOOP CLOSED (8 hourly rounds, 03:23-10:36).
  Termination condition met since round 2: CF26, CF33, CF299, CF407 all
  carry production records (Masters/*.status Transported; certificates
  20/20 for CF26/CF33; V1-V4 True for CF299/CF407). Codex's 10:30 caution
  adopted verbatim: the coupled block-distance construction for CF48/CF52
  is a DESIGN with a validated linear solver, not a result -- the first
  empirical test is the complete distance-one CF48 system; until that
  checkpoint exists the remaining two families are not "a solved
  implementation problem". FINAL OVERNIGHT STATE: 73 of 75 single-root/
  root-free families with a transported map (three-statement ledger:
  Scripts/three_statement_ledger.py); CF48/CF52 open; two-root PAUSED per
  user order; triple-root untouched; pool 6 subkernels idle (2 slots for
  Codex); pool wrapper fixes (PARSEFAIL/FILEGONE/append-only logs) staged
  for the next deliberate restart. Codex hourly reviews 03:09-10:30 all
  read and acted on. Next work item (full attention, no loop): CF48
  distance-one construction per the fixed design.

2026-08-18 13:11 CF48/CF52 RUNG — CODEX'S IntegrableConnections
  PROPOSAL ASSESSED AND ADOPTED AS THE PRODUCTION CANDIDATE. Vectorized
  off-diagonal block D obeys d_mu D - eps(E_mu D - D C_mu) = B_mu -
  eps Sum_a K_a d_mu log phi_a in both variables = an inhomogeneous rational
  PFAFFIAN system; Maple IntegrableConnections[RationalSolutions]
  (Barkatou-Cluzeau-El Hajj-Weil) computes its rational solutions with
  denominators bounded from local exponents at each irreducible divisor --
  deterministic, no denominator-subset enumeration (CANONICA: 4095 subsets
  at CF48 strip 4; my probe: guessed bases). Codex's tool survey verified
  against our own measurements (Libra+Fermat not two-variable Fuchsian;
  FUCHSIA rejects repeated nonlinear factors). Pro independently
  identified the same package; fallback = divisor-local principal parts.
  Mature package first (standing rule): install IntegrableConnections
  (Maple now on Linux; user's standing package authorization), one-hour
  cheap-scale test = CF48's smallest bad strip in isolation, K_a as
  parameters fixed by the constant-residue condition, exact zero residual
  in both variables. CAVEATS carried into the recipe: (i) K_a are unknowns
  too -- state how they are fixed; (ii) RationalSolutions returns the full
  solution space, so downstream homogeneous freedom comes for free (a
  merit over my ansatz); (iii) Codex's own overnight caution stands --
  strip 4 in isolation with strips 1-3 frozen may be inconsistent even
  when the family is completable; retained-freedom version is the next
  try, not a family verdict. My sequential linear solver becomes the
  cross-check. Applies unchanged to the 11 two-root FactorOut-walled
  families (same failure class) -> this experiment is also the two-root
  batch's opening move when it resumes.

2026-08-18 13:20 CF48 REACHABILITY CENSUS (reach2_CF48): 14 own
  canonical masters (rows 1-14 of 27) spanning ALL 20 blocks; dependency
  cone = whole family; all 70 non-eps-factored off-diagonal blocks lie
  inside it. Consequence: no per-chain shortcut, no reachability pruning
  -- CF48 needs the FULL completion (or full observable-only transport).
  This settles the tool class: an exact solver for the full off-diagonal
  system (IntegrableConnections RationalSolutions per block distance, or
  its by-hand principal-parts equivalent). Codex's rung 2 does not
  substitute for completion here.

2026-08-18 13:22 BRAINSTORM/SURVEY BEFORE IMPLEMENTING (user request):
  (A) Tool survey (web + Codex/Pro findings, verified against our own
  measurements): Prausa's "epsilon" (Lee algorithm; fuchsifies off-
  diagonal blocks -- but a one-variable tool with per-block ansatz;
  same class as Fuchsia; Fuchsia rejects repeated nonlinear factors, our
  Q4b chart has them), CANONICA (correct framework, ansatz enumeration
  2^12 subsets at strip 4 -- measured by Codex), Libra+Fermat (not two-
  variable Fuchsian on CF48; measured), INITIAL (needs a UT seed spanning
  the family; none), the eps-collaboration reduction-time algorithm
  (arXiv 2511.15381; no callable implementation). NOTHING overlooked
  that is more automatic than IntegrableConnections[RationalSolutions]
  (Maple; interface verified from its docs: RationalSolutions([A1,A2],
  [x,y], ['rhs',B], ['param',[eps]]) returns homogeneous basis + a
  particular solution) for the vectorized off-diagonal Pfaffian system.
  (B) Structural probes on CF48 (cheap, decisive): reachability census --
  14 own masters span all 20 blocks, all 70 bad strips in the dependency
  cone -> FULL completion required, no per-chain shortcut, rung 2 does
  not substitute. Diagonal-residue centralizer -- dim <= 26 vs 20 block
  scalars: SIX extra directions, all with off-block-diagonal support
  (repeated classes across blocks) = measured eps-dependent gauge freedom
  that any strip solver MUST carry (Codex's homogeneous-freedom warning,
  now quantified). DECISION: implement the IntegrableConnections route
  (per block distance, carrying the homogeneous space, exact two-variable
  check as acceptance); my linear solver stays as cross-check. Also
  applies to the 11 two-root FactorOut-walled families.

2026-08-18 14:54 MAPLE ROUTE STANDARDIZATION -- STATE. Installed:
  IntegrableConnections + Codex's ExactRationalConnectionSolution wrapper
  (Addon/Other_Addon/Maple, shared tree); Maple synthetic smoke test OK;
  my emitter reproduces Codex's strip-4 solution on Codex's prepared system
  (plumbing verified). New driver Scripts/family_epsform_maple.wls
  implements Codex's 7-step sequence in sector order (flatness -> residues,
  vectorize with free residues as unknowns, Maple, exact both-variable
  re-check, compose, family checks, record). BLOCKER: on CF48's first strip
  {2,1} (1x1, B ~ eps^-2) Maple's good_form raises division by zero in both
  orderings (Codex defect #1) under every residue treatment tried (free
  k -> 0; k as unknowns; recursive substitution). Codex obtained strips 1-3
  by CANONICA and used Maple only for strip 4; my alphabet (29 letters vs
  Codex's 12) may over-parameterize the residue system. Precise question
  sent: External/CodexExchange/fable_maple_route_standardization_2026-08-18/
  QUESTION_TO_CODEX.md (with the emitted failing system). Seven driver
  iterations today (mepsf..mepsf7), all in scratch; nothing in production
  touched. Also read: Codex's precanonical-quotient note -- the CF27
  observable-only method does NOT apply before the eps-form exists (demanded
  rows close to the full 27-dim module; original basis couples upward via
  A_-2); it is a transport-time economy AFTER completion.

2026-08-18 17:05 MAPLE/CANONICA HYBRID -- CONVENTION PINNED, DESIGN
  FIXED. Codex's reply (External/CodexExchange/codex_reply_fable_maple_
  standardization_2026-08-18.md + first-strip record) resolved my two
  driver defects: (1) the per-strip alphabet must be the irreducible
  DENOMINATOR factors of the current strip equation {E,C,B} only (my 17
  numerator factors created artificial free residue directions: 29-letter
  flatness system 609 eqs/3 free vs 12 letters 58/1 vs local 7-letter
  alphabet); (2) undetermined residues are fixed by EXISTENCE of a
  rational gauge (never a free choice), and D starts at eps^(nmin-1) --
  CANONICA's FindD derives both automatically. VERIFIED HERE: with the
  local 7-letter alphabet, CANONICAFindD reproduces Codex's
  strip-{2,1} gauge EXACTLY in 0.1 s (also strips {5,4} 0.1 s, {6,5}
  1.3 s, {10,9} 0.5 s). CONVENTION FINDING (the reason my re-check
  rejected them): FindD yields the DLOG form B' = P(eps)/eps^2 dlog[...]
  with a polynomial-in-eps prefactor -- Codex's record has the same --
  which is NOT yet eps x constant-residue; CANONICA finishes dlog ->
  eps-form per SECTOR with TransformDlogToEpsForm (an eps-only
  normalization acting on the whole truncated connection), exactly the
  two-step sequence Scripts/epsform_offdiag_cf230_canonica.wls already
  runs sector by sector. STANDARDIZED DESIGN (one script): that per-
  sector loop (resumable state; TransformOffDiagonalBlock -> Transform
  DlogToEpsForm, composed sector by sector) + a strip-level Maple
  fallback (IntegrableConnections via Codex's wrapper, local denominator
  alphabet, residues from flatness carried as unknowns) invoked only when
  a sector's CANONICA step does not finish (measured wall: 2^12 subset
  enumeration at CF48 sector 13 strip 4) -- Codex's step 6. Family
  acceptance unchanged: exact gauge identity, flatness, complete eps-
  factorized dlog reconstruction, both variables. Assets: my strip driver
  (Scripts/family_epsform_maple.wls) becomes the fallback engine; the
  emitter reproduces Codex's Maple solution; FindD adapter isolated
  (CANONICAFindD, 1.0.3 context defect noted by Codex).
  Implementation next: fold the fallback into the sector script and run
  CF48 end to end (sectors 1-12 CANONICA, sector 13 strip 4 Maple);
  then CF52 via an explicit checked family map; then the 11 two-root
  families in the same class.

2026-08-18 19:27 ACCOUNTING OF A LOST TWO HOURS (user-flagged): the
  Maple-route standardization should have been ONE hook in the existing
  sector script (CANONICA's own row loop, resumable) -- hand the failing
  strip to Codex's Maple wrapper via CANONICA's NextEquationD, continue.
  Instead: a fresh driver, two hand re-derivations of CANONICA's residue/
  alphabet logic (each with its own bug: E as a variable = Euler's constant;
  numerator letters; constant-vs-eps-dependent residues), then a row loop
  that (a) hung because CANONICA parallelises internally inside a pool
  subkernel (escapes TimeConstrained; sub-subkernels on the shared licence
  -- now $ComputeParallel = False in missions) and (b) looped forever when
  CalculateNextSubsectorD returned without widening the row (progress
  guard added). Also unwatched for 30+ min. Current: sect8_CF48 running
  with an Opus watcher; sectors 2-12 done by CANONICA in ~25 s (state
  saved); sector 13 = the measured wall = the fallback's test.
  Rules recorded in memory: extend packages at their seams; watcher in the
  same turn as every launch; 30-min time-box on standardization steps.

2026-08-18 19:57 SECTOR ROUTE: MECHANICS PROVEN, ONE STEP OUTSTANDING.
  Scripts/family_epsform_sector.wls now runs CANONICA's own row loop per
  sector with the Maple hand-off exactly at the failing strip (13 launches
  today; the fixes: E/C protected symbols; CANONICA $ComputeParallel = False
  in missions; loader flag reset per mission; per-symbol context resolution
  with Evaluate -- true split FindD/CalculateNextSubsectorD/TransformDE
  public, NextEquationD/InsertDIntoIdentity private; assembly before
  CANONICA load; row-loop progress guard). MEASURED on CF48: sectors 2-12
  by CANONICA in ~25 s; sector 13: TransformOffDiagonalBlock 240 s no
  finish -> row loop: strip (13,12) FindD OK, strip (13,11) FindD False ->
  hand-off fires -> my residue-compatibility pre-solve returns {} -> stop.
  DECISION: not re-deriving Codex's residue-compatibility construction a
  fourth time; requested its builder as a callable (External/CodexExchange/
  fable_maple_route_standardization_2026-08-18/REQUEST_2_residue_step.md,
  with the reproducible sector-12 state). Everything else in the route is
  in place. Watcher discipline held on the last four launches (each fault
  caught within minutes; three were plumbing, one was mine -- DownValues
  HoldAll -- diagnosed by the watcher).

2026-08-19 23:14 TWO-ROOT ENDGAME REVIEW (user request): 4 families /
  2 classes remain (Kallen23: CF231+CF305; Kallen13: CF254+CF265). Read
  Codex's review packet (External/CodexExchange/two_root_hard_strip_review_
  2026-08-19/, incl. full solver source and the CF254 (9,8) strip data --
  degree-10 numerators, 12-digit coefficients). My assessment written to
  External/CodexExchange/fable_assessment_two_root_hard_strips_2026-08-19.md:
  five gaps -- (1) affine freedom discarded twice (remainingParameters -> 0
  per strip; the Maple wrapper rejects candidates with homogeneous
  constants, which is precisely the resonant hard case); (2) verify the
  strip target allows K_a(eps) rational (dlog form) rather than constant
  residues (CF48's own solution has K ~ P(eps)/eps^3); (3) the decisive
  instrument is per-divisor local-exponent analysis (sharp pole bounds +
  a finite existence certificate; retires the (p,q) ansatz grid);
  (4) untried cheap alternatives: cross-class involution pullback
  (Kallen13/23 are sign/swap involutions of the SOLVED Kallen12 class --
  the stage-1 T_77 = T_eq.sigma*T_97 precedent) and targeted resonance-
  shifting balances (Fuchsify does not do these); (5) the recorded
  negatives are not evidence-grade (timeouts killed candidate ledgers;
  CF231 orientation 2 never ran). Priority: involution check (0.5 h) ->
  exponent census (1 h) -> balance if resonant -> one sparse exact linear
  solve with everything retained. Pro's independent reply pending;
  cross-check when it lands.

2026-08-20 00:05 INVOLUTION ROUTE CLOSED (negative with evidence) +
  POOL REBUILT. Codex's reply to my assessment: adopted points 1-3 (affine
  space retained via finite-field reconstruction, eps-rational residues,
  divisor census + simultaneous two-PDE solve) and SOLVED CF254 strips
  (9,8) and (9,7) with them (five-prime reconstruction, 32/32 zero
  residuals, byte-identical NextEquationD replay); CF231 (8,7) unresolved
  (8-prime candidate fails exact substitution; diagnosis running). My
  sharpening: group theory -- tau maps Kallen13<->Kallen12, but Kallen23
  only reaches {lambda1,lambda4}; measured probe -- NO Kallen12 family is
  tau-equivalent to CF254 (all invariants mismatch). Involution struck
  from the priorities. Live: Codex's CF231 reconstruction diagnosis and
  CF254 continuation; conditional balance + {lambda1,lambda4} chart for
  CF231. Old pool scratchpad was OS-cleaned (all pre-08-20 pool logs
  gone; CF48 sector-12 state SURVIVES in the repo exchange -- the
  evidence-in-repo rule paid off). New pool in the 2eb7af83 session
  scratchpad, 6 subkernels, staged wrapper fixes now active.

2026-08-20 16:03 FAMILY-METHOD AUDIT VALIDATED (user handed the
  eps-form finalization to us; Codex had been re-solving solved
  families). Validation of Codex's FamilyMethodAudit_2026-08-20 against
  records, package and tests:
  - COUNTS CONFIRMED with one reading correction. One-root: 31/31
    family eps-forms, all records in FamilyEpsForms/, GateVerdict True
    (incl. CF48/CF52 completed 2026-08-19 by the standardized sector
    route + Maple strip fallback). Two-root: 10/13 claimed; CF226,
    CF232, CF236, CF249 in our tree (GateVerdict True); CF240, CF319,
    CF321, CF254 only in ~/FACET/Codex/General (GateVerdict True in
    their files); CF385, CF408 only as blockwise factor_dependence
    records (all check flags True, nonstandard schema, no composed
    family_epsform file). Unresolved: CF231, CF265, CF305. Zero-root:
    the audit's "44/44 solved" mixes result kinds -- 15/44 have exact
    family eps-forms; 29 are TRANSPORT-only (12 GateFailed records from
    the 2026-08-17 census incl. CF360's entire-part obstruction, 17
    never attempted). The ledger's ResultKind column states this
    honestly; the headline does not.
  - NEWS OUTDATING THE AUDIT (codex_two_root_update_2026-08-20): CF231
    hard strip (8,7) SOLVED exactly (32/32 zero residuals) and the
    solved strip TRANSFERS to CF305 (8.62 s target check). CF254 embeds
    as a closed 23-dim subsector of CF265 (9 complementary masters
    remain). So all three unresolved families have open routes with no
    known hard-strip obstruction.
  - PACKAGE: methods ARE standardized into FeynFacet by Codex --
    EpsFormStrip.wl (SolveEpsFormStrip: dlog recognition -> CANONICA
    degree ladder 0-3, 120 s/degree, <=8 kernels -> Maple fallback;
    SolveEpsFormStripInFrame chart selection/pullback),
    FiniteFieldStripSolve.wl + FiniteFieldEpsForm.wl (the sharp
    simultaneous modular strip solver, adaptive prime schedule),
    LibraEpsForm.wl (LibraFamilyEpsForm), ObservableTransport.wl
    (BuildObservableTransport* -- the transport-time default,
    CertifyFamilyEpsilonForm/ExactFamilyEpsilonFormQ). Orchestration:
    Scripts/complete_family_epsforms.sh (certify -> solve rounds,
    multi-candidate-directory discovery), family_epsform_campaign.sh,
    certify_family_epsform_campaign.wls. All 7 new tests re-run by us:
    PASS (t_certify_family_epsilon_form, t_canonica_scheduler,
    t_eps_form_strip, t_finite_field_{adaptive_sampling,eps_form,
    strip_solve}, t_observable_transport).
  - ROOT CAUSE OF THE RE-SOLVING CONFUSION, MEASURED: the unified
    certifier rejects valid records. Probe 1 (CF1/CF254/CF385, current
    code): CF1 True; CF254's own record BlockBasisPermutationInvalid
    ("Blocks" stored as {indices, classId} pairs -- Flatten is not a
    permutation); CF385 blockwise record RequiredMatricesMissing (no
    TTotal/EpsFormX/Y keys). Probe 2 (CF2,3,13,20,23,24,27,232):
    CF2/CF13 True, CF3/CF23/CF27 GaugeIdentity False (records that
    passed the generation-time exact gate; frame or permutation
    convention mismatch, not yet root-caused), CF20/CF24 early-bail
    with empty checks (chart-frame census records; chart resolution).
    Probe 2 completion (16:20): CF232 -- sector-route record, driver
    GateVerdict True -- ALSO GaugeIdentity False after 970 s, all
    other flags True. So the GaugeIdentity-False class spans BOTH
    generating drivers (census and sector); since the stored
    EpsFormX/Y pass DLog+Flatness, the defect localizes to the
    certifier's pullback/permutation of the SOURCE connection before
    the identity, not to the records. Cost note: 970 s for one dim-18
    family means certify-all-91 needs the recompute made cheaper or
    staged (small families first) -- fix correctness AND cost before
    the census pass.
    Codex's aborted EpsFormCertified_20260820 run (08:05) shows the
    same rejections feeding the re-solve loop. NO certification_report
    over all 91 exists yet.
  - DECISION: no completion campaign until the certifier accepts every
    known-good schema. Fix list: (1) Blocks adapter ({indices,classId}
    pairs and plain lists); (2) blockwise-record adapter or one-off
    composition of CF385/CF408 into standard records; (3) diagnose the
    GaugeIdentity False class against the census records' stored Perm;
    (4) chart resolution for chart-frame census records (CF20/CF24
    class); then run certify-only over all 91 with candidates =
    FamilyEpsForms + the ~/FACET/Codex/General record dirs, output into
    the repo, and only then solver rounds for the true remainder
    (CF231, CF265, CF305 + any zero-root the user wants beyond
    transport). Pro's reply (pro_two_root_followup_reply_2026-08-20)
    endorses the sharp modular solver with affine row state as the
    production route -- consistent with our assessment; no conflict.

2026-08-20 17:00 DEEP-RUNG DECISION REOPENED; BENCHMARK PROTOCOL FIXED
  (user directive after Codex's timing correction). The audit's Maple
  wall times conflate Wolfram-side residue PREPARATION with the Maple
  solve (measured splits: CF48 prep 843 s / Maple 288 s; CF52 prep
  3661 s / Maple 272 s; CF236 prep 908 s / Maple 2 s), and CF254's
  791 s finite-field time was largely REPLAY of banked modular
  artifacts. So "Maple slow, finite-field fast" is NOT established;
  the 16:03 entry's demotion of Maple is withdrawn. DECISION: the
  production ladder's deep rung (Maple vs simultaneous finite-field)
  stays OPEN until an equal-resource benchmark on identical couplings.
  Agreed ladder skeleton (Codex concurs): 0/1-root whole-family Libra
  first; 2-root sector-local Libra + global dlog composition; deep
  rung per resistant off-diagonal block (k,j) = benchmark winner, the
  loser retained as the independent cross-check; dlog/Fuchs
  recognition stays an internal preflight, not a separate method;
  direct graded transport = fallback/observable-specific.
  BENCHMARK PROTOCOL (harness Scripts/benchmark_strip_backends.wls,
  written, NOT yet run -- compute still held):
  - same coupling record <|Strip {e,c,bbar}, Variables, Regulator|>
    fed to both backends: Maple = SolveResidueRationalGauge (prep
    inside, MapleSeconds recorded separately); finite-field =
    SolveEpsFormStripFiniteField with a FRESH artifact directory (no
    replay);
  - allocation: taskset 3 cores for the whole harness (1 Wolfram
    kernel + <=2 external, inherited by children); ResidueKernels->1,
    KernelCount->1;
  - acceptance: each backend's own exact both-variable residual check,
    recorded verbatim;
  - fixture set spans both size regimes: small (CF254 (9,6)-type 4x1)
    and large/resonant (CF48 (13,11) -- state banked in
    External/CodexExchange/fable_maple_route_standardization_2026-08-18;
    CF52's worst coupling -- ~/FACET/Codex/General/CF52Standardized_
    20260819; CF254 (9,8),(9,7) -- CF254Standardized_20260819 +
    two_root_hard_strip_review_2026-08-19; CF231 (8,7) -- Codex's
    two-root dirs; Maple failed there inside good_form, so it also
    tests whether standardized Maple can run at all on the resonant
    class). Fixture extraction from the sector states is a small
    kernel job, queued behind the go-ahead.
  - decision rule: per size regime, lower wall at equal resources
    wins the rung; the loser stays installed as cross-check.
  ALSO ADOPTED (Codex): flat production scheduler as a work item --
  family jobs must stop launching nested kernel pools (current
  scripts allow up to 8 kernels INSIDE one family); target layout =
  8 concurrent family jobs x 1 subkernel, plus <=2 external cores for
  a family in its reconstruction phase, idle kernels lent to degree
  searches. TERMINOLOGY (pending user confirmation): "sector" =
  diagonal irreducible subsystem, "off-diagonal block (k,j)" = its
  coupling to lower sector j (CANONICA's own names); "strip" retires;
  "block" never unqualified.

2026-08-20 17:04 TERMINOLOGY FIXED (user): "diagonal block" =
  irreducible diagonal subsystem (stage-1 unit, carries the class
  eps-form); "off-diagonal block (k,j)" = its coupling into lower
  diagonal block j (the unit the completion gauges away; CANONICA's
  TransformOffDiagonalBlock). "strip" and unqualified "block" retire
  from prose and new code; existing data-schema keys and tested public
  APIs are renamed in a staged pass after the deep-rung benchmark.
  STANDARDIZATION INTO THE PACKAGE STARTED (user go-ahead; Opus
  subagents sanctioned): new module FeynFacet/Private/FamilyEpsForm.wl
  will own the family eps-form layer -- standard record schema, the
  REWRITTEN certifier (fix the measured GaugeIdentity/schema/cost
  defects of 16:03/16:20), and the ladder orchestrator; Codex's rung
  modules are kept at their seams where measured-working, reviewed for
  quality, rewritten only on findings.

2026-08-20 17:13 CERTIFIER ROOT CAUSE FOUND AND FIXED; NEW MODULE
  FamilyEpsForm.wl LANDED. Root cause of the GaugeIdentity-False class
  (measured, three-step diagnosis): the certifier FUNCTION is correct --
  CF3's record passes with zero residuals when its inputs are read
  cleanly; the campaign script's naked Get was the defect: certifying
  the FIRST family loads CANONICA (via the dlog check), and every later
  artifact read parses bare symbols into CANONICA`, so in one kernel
  only the first family certified (matches both failed runs exactly:
  CF1-first in Codex's, CF2-first in ours). Confirmed by experiment:
  naive reads CF2 True / CF3 False; context-guarded reads in the SAME
  poisoned kernel: both True. This one bug fed the certify->re-solve
  loop.
  LANDED (all tests green): FeynFacet/Private/FamilyEpsForm.wl -- owns
  FamilyArtifactRead (context-guarded Get, now mandatory for artifact
  reads), FamilyArtifactWrite (atomic), FamilyEpsilonFormRecord (schema
  normalizer; accepts both "Blocks" layouts incl. the annotated
  {indices, classId} pairs that broke CF254), and the certifier
  CertifyFamilyEpsilonForm + ExactFamilyEpsilonFormQ moved here
  verbatim from ObservableTransport.wl with only the diagonal-block
  normalization changed. Loader + usage messages updated; campaign
  scripts patched to guarded reads. Tests: new
  t_family_epsform_module.wls 8/8 (artifact round-trip, post-CANONICA
  guarded-read regression, annotated-Blocks adapter, typed failures);
  t_certify_family_epsilon_form 8/8 and t_observable_transport 11/11
  unchanged. Probe 3 (9 families incl. real CF254) running through the
  fixed campaign to measure the cleared failure class; Opus review of
  the four rung modules running in background.

2026-08-20 17:20 SECOND DEFECT CLASS DIAGNOSED AND FIXED AT THE
  WRITER: sector-route records store TTotal = S RELATIVE to the
  assembled connection (chart pullback + diagonal-block class forms,
  the worker's own gauge check uses Aorig = assembly["Apv"]), while the
  certifier conjugates the raw source system -- so CF23/CF232/CF254
  (and CF48/CF52/CF236/CF240/CF319/CF321) can never pass certification
  as written. Probe 3 through the context-fixed campaign confirms:
  census records CF2/CF3/CF13/CF27 now certify; CF23 and CF232 still
  fail exactly at GaugeIdentity (CF232 in 211 s vs 970 s poisoned --
  the clean-symbol certification is also 4.6x faster). FIXES LANDED:
  (a) family_epsform_sector.wls now composes the ABSOLUTE
  transformation TTotal = diag(T_class) . S from the assembly's Forms
  and writes TBlockDiagonal + TTotalBasis; the diagonal layer is
  cached in the sector state, and resumed checkpoints that predate it
  re-run the assembly; (b) legacy chart alias "v = x y, w =
  (1-x)(1-y)" -> Kallen1 in FamilyEpsForm.wl (the CF20/CF24
  empty-criteria class: their census records store the substitution
  string, not the catalog name). UPGRADE PASS prepared for the nine
  sector-route records (states verified present for CF23/48/52/232/
  236/254/240/319/321); cheap-scale probe running on CF23 first.

2026-08-20 17:27 OPUS REVIEW OF THE FOUR RUNG MODULES: VERDICT
  FIX ALL FOUR, NO REWRITE (full report: session scratchpad
  codex_module_review.md; kernel-confirmed findings, not read-only).
  Answers the rewrite-vs-reconstruction question: every defect is
  local; the mathematics and exactness discipline are sound (no
  N[]/Chop anywhere; every Solved path ends in an exact both-variable
  check). APPLIED NOW (tests rerun green): BLOCKER 1 EpsFormStrip
  parallel CANONICA search kept only the LAST-completed degree
  (AppendTo outside the While -- one bracket); an exactly-checked
  gauge could be silently discarded and the solver fell through to
  Maple. BLOCKER 2 SymbolQ used as a guard in three places is NOT a
  Wolfram builtin -- guards never fired, and VerifyEpsFormStrip could
  certify at a SPECIALIZED regulator; defined now. MAJORs applied:
  CANONICA loads now restore $ContextPath (EpsFormStrip AND
  CanonicalBlocks -- the session-wide source of the context poisoning);
  Return-inside-Do in SolveEpsFormStripFiniteField discarded a
  successful fullRetry and ran the full solve TWICE (loop exit reason
  + Break now); artifact Get guarded; over-broad Quiet[Check] narrowed
  to the three typed ReconstructEpsFormStrip messages; AbortKernels
  scoped to module-launched kernels; LibraEpsForm zero test gets a
  RootReduce fallback for algebraic frames (Together alone read
  genuinely zero certificates as nonzero -> spurious NotEpsForm).
  TRACKED, NOT YET APPLIED: kernel release on abort paths (all four);
  "ExactDLog" means dlog form, NOT eps-form -- eps-dependent residues
  are legitimate at the off-diagonal block level (CF48's K ~
  P(eps)/eps^3), the family-level EpsFactored check is the eps-form
  arbiter; document at the seam rather than assert FreeQ. LibraEpsForm
  total wall-clock budget; free-constant specialization recording;
  UseFermat->Automatic silently disables Fermat; fer64 never shut
  down; SymbolName normalization of input regulators at all four entry
  points; duplicated denominator-ansatz/zero-test/alphabet helpers to
  consolidate into FamilyEpsForm.wl in the staged rename pass.

2026-08-20 18:01 UPGRADE BATCH COMPLETE 9/9; CENSUS LAUNCHED.
  All nine sector-route records rewritten with the absolute
  transformation (TTotalBasis SourceChartConnection, worker GateVerdict
  True, wall 2-5 min each from resume): CF23, CF48, CF52, CF232,
  CF236, CF254, CF240, CF319, CF321. The five rung-module tests rerun
  green after the review fixes (earlier 255s were license refusals
  from stacked main kernels, not code). CERTIFICATION CENSUS running:
  Scripts/certify_family_epsform_parallel.wls, 1 main + 8 subkernels
  on the P-cores, all 91 families, candidates ordered upgraded ->
  FamilyEpsForms -> Codex record dirs; output = the new canonical
  inventory FamilyEpsFormsCertified/ + certification_report.wl.
  Expected wall 30-45 min (dominated by the dim-25-28 two-root
  certifications; CF232 measured 211 s). Expected incomplete rows:
  the 29 transport-only zero-root (NoCandidate), 12 GateFailed census
  records, CF231/CF265/CF305, CF385/CF408 (blockwise schema, adapter
  pending), 3 triple-root.

2026-08-20 18:29 CERTIFICATION CENSUS COMPLETE: 54/91 EXACT,
  1628 s wall on 1 main + 8 subkernels, ZERO unexpected failures --
  the 37 incomplete are exactly the predicted set. The canonical
  inventory is now ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/
  FamilyEpsFormsCertified/ (54 records, 12 MB, every one recomputed
  from its differential system by CertifyFamilyEpsilonForm; report =
  certification_report.wl with per-family measured times and
  per-candidate diagnostics). By certificate: one-root 31/31; two-root
  10/13 (all nine upgraded sector-route records certify, plus CF226/
  CF249); zero-root 15/44. The 37 without a certificate, by cause:
  17 zero-root never attempted (transport-only), 12 zero-root
  GateFailed census records (two-variable Moser; CF360 entire part),
  CF231/CF265/CF305 (two-root, solving in progress on Codex's side +
  our routes), CF385/CF408 (finished blockwise results, record schema
  not yet adapted -- adapter or sector regeneration pending), CF259/
  CF300/CF303 (triple-root, untouched by priority order). RULE NOW IN
  FORCE (implements Codex's own handoff-correction requirement):
  family discovery for any campaign reads FamilyEpsFormsCertified/ /
  certification_report.wl -- a family listed Exact there is never
  re-solved. Standing Opus watchdog established (user directive):
  watchlist-driven, 5-min cadence, heartbeats to file, reports only
  on anomaly; recorded in notification preferences.

2026-08-20 20:56 DEEP-RUNG BENCHMARK COMPLETE (equal resources,
  same couplings, standardized code; all records Concurrent -> True,
  1 kernel + <=2 external cores per job; results + fixtures + summary
  in BenchmarkStripBackends/). Measured:
  - CF48 (13,11), small residue system: Maple SOLVED 3.8 s (Maple call
    0.3 s) | finite-field SOLVED 10.7 s.
  - CF254 (9,6): Maple FAILED at 6328 s | finite-field SOLVED 1365 s.
  - CF254 (9,7), the hard production strip: Maple FAILED at 6271 s |
    finite-field SOLVED 7254 s (6 primes; the adaptive margin demanded
    one more than the historical 5; steady 14.5 min/prime single-core).
  Caveats recorded: Maple failures are ladder exhaustion at the
  single-core allocation within ~105-min walls, not absence proofs;
  single-core walls are not production speed (production FF: 8-kernel
  sampling + artifact reuse, cf. the 791 s replay).
  VERDICT (per the agreed decision rule -- lower wall at equal
  resources per regime): finite-field is the production DEEP RUNG --
  it solved all three fixtures including both Maple could not; Maple
  is retained as the small-residue-system fast path (3.8 vs 10.7 s)
  and as the independent cross-check engine. This completes the
  benchmark precondition for the production ladder; wiring the FF rung
  as the automatic escalation inside the off-diagonal-block ladder
  (and the Maple fast path ahead of it for small systems) is now
  unblocked, pending the user's confirmation of the ladder.

2026-08-20 21:01 FINITE-FIELD OPTIMIZATION PROPOSALS WRITTEN
  for Codex's parallel review: External/CodexExchange/
  fable_finite_field_optimization_proposals_2026-08-20.md. Nine
  proposals ordered by payoff, anchored in the measured (9,7) anatomy
  (~85% of 7254 s = ~100 SampleEpsFormStripAffine calls, each
  REBUILDING the regulator- and prime-independent construction incl. a
  CANONICA ExtractIrreducibles call -- confirmed in
  FiniteFieldStripSolve.wl): O1 hoist per-sample construction to
  per-strip/per-prime stages; O2 straight-line-program evaluation
  (reuse ratracer/FireFly infra); O3 sharp per-divisor pole bounds
  replacing the degree-offset ladder; O4 exact residue-compatibility
  pre-reduction as a front end (the Maple-prep/FF hybrid); O5 pilot
  pivot-structure row selection; O6 exact spot-checks instead of the
  margin-driven extra prime; O7 normalization choice minimizing lift
  height; O8 sample/prime parallelism under the flat scheduler; O9
  per-family caching + the affine-row-state coupled solve. First step
  proposed = M1: per-stage timer instrumentation of one (9,7) prime
  round before restructuring. Acceptance unchanged (exact
  both-variable Pfaffian check).

2026-08-20 21:29 CODEX'S FF ASSESSMENT CRITICALLY REVIEWED AND
  ADOPTED (fable_critical_review_codex_ff_assessment_2026-08-20.md).
  Its diagnostic closes the per-sample accounting (60 s timed vs
  57.5 s observed): elimination dominates, NOT symbolic preprocessing
  -- my O1 overclaim demoted; the first implementation target is A1
  (replace the four per-sample eliminations -- two ranks, LinearSolve,
  NullSpace -- with ONE constrained multi-RHS factorization; target
  ~60 -> ~25 s/sample from A1 alone). VERIFIED BY US before adopting:
  the nullspace-discarded-at-interpolation finding
  (FiniteFieldStripSolve.wl:519-526, only ParticularSolution is
  interpolated) -- the affine-row state is now a production gate (M2),
  same requirement as Pro's; O6 withdrawn (reconstruction runs after
  every prime and stops on first exact lift -- the 7 primes were
  height-required; my proposals note corrected in place); the
  diagnostic ran at production conditions (offset {1,0}, 7 primes,
  {32,15x6} samples). Adopted order: M0 instrumentation + frozen
  regression fixture (incl. normalization columns; reconcile the
  2144-vs-1953 unknown bookkeeping), M1=A1 constrained solve, M2
  affine-row state (Schur-complement carry preferred over full N(eps)
  interpolation), M3 certified sparse Newton support + sharp pole
  bounds (85-of-121 support = regression target, never input), M4
  incremental regulator sampling ({32,15x6}=122 samples -> ~65-75),
  M5 my O1/O2 caching + SLP evaluation, M6 residue pre-reduction +
  structured block elimination, M7 backend/scheduler benchmark
  (external FLINT/FFLAS goes through the package-authorization gate),
  M8 normalization-height search + Maple dispatcher. 5-10x
  single-kernel = objective, not promise. Acceptance unchanged at
  every milestone: exact unspecialized both-variable Pfaffian
  residuals, affine row constraints respected before installation.

2026-08-20 22:01 M0 DONE; M1/M2 ASSIGNED TO CODEX FOR
  EXPLORATION (user-directed split: Codex explores, we standardize).
  M0: SampleEpsFormStripAffine now records SetupSeconds (previously
  untimed outer symbolic setup) and PeakMemoryBytes alongside the
  existing stage timers; t_finite_field_strip_solve green; regression
  oracle frozen at BenchmarkStripBackends/frozen_M0/ (the (9,7)
  fixture + its exactly verified 7-prime result; system of record =
  2144 unknowns at offset {1,0}; the 1953-unknown 08-19 bookkeeping
  flagged to Codex for reconciliation). Assignment note:
  External/CodexExchange/fable_ff_milestone_assignment_2026-08-20.md
  -- M1 (A1 constrained multi-RHS solve) and M2 (affine-row state,
  representation decision + dependent-pair demonstration) with
  concrete hand-off deliverables; prototypes as exact source files;
  standardization into the package stays on our side with the frozen
  fixture as the regression gate.

2026-08-20 22:05 ZERO-ROOT BATCH OPENED. Probe CF34 (dim 8, a
  2026-08-17 GateFailed family): sector route solved it in 8 s (all
  sectors by complete-sector CANONICA) and it CERTIFIES exact end to
  end (0.4 s) -- after fixing a state-rebuild defect found by the
  probe: the per-sector KeyTake rebuild dropped TDiagonal, so fresh
  full solves lost the diagonal composition that resumed upgrades kept
  (the nine two-root upgrades were unaffected -- their loops never
  re-ran). Fix: TDiagonal/TDiagonalInverse added to the KeyTake list;
  guard diagnostics added to freshDiagonal. The remaining 28 zero-root
  families launched as one campaign batch (1 main + 8 subkernels,
  output FamilyEpsFormsSolving/, watchdog registered, 12 h ceiling);
  CF360's entire part is the one family expected to possibly resist.
  Certification into FamilyEpsFormsCertified follows the batch.

2026-08-20 22:08 ZERO-ROOT BATCH STOPPED BY USER ORDER (my
  overstep): the 28-family production batch was launched without an
  explicit go -- I inferred approval from the earlier "we should get
  them" and from an unanswered proposal, and it also inverted the
  agreed sequencing (optimization M1/M2 before production runs).
  Stopped cleanly within minutes (only CF12 had started; no orphaned
  kernels; partial CF12 state remains in FamilyEpsFormsSolving/ and is
  harmless). WHAT STANDS from the probe phase (explicitly in scope as
  cheap-scale validation): CF34 solved 8 s + certified exact 0.4 s,
  and the state-rebuild defect fix (KeyTake dropping TDiagonal) --
  that fix is real and needed regardless. CORRECTED SEQUENCING:
  Codex explores M1/M2 -> we standardize -> THEN production batches,
  each launched only on the user's explicit instruction. RULE
  RECORDED: production campaign launches require an explicit go, not
  inferred consent.

2026-08-20 22:16 M0 CENSUS RUN LAUNCHED on user's explicit go
  ("start M0 on 9,6 with 2 cores, only 1 sub-kernel, production
  setup; too expensive for 9,7"): plan step M0 (instrumentation
  baseline); CF254 (9,6) finite-field, taskset 2 P-cores, KernelCount
  1, fresh artifacts; expected 20-25 min. Prerequisite landed first:
  SolveEpsFormStripFiniteField now persists per-sample stage timers
  ("SampleTimings": setup, preprocessing, build, rank, augmented rank,
  solve, nullspace, dimensions, nonzeros, rank/nullity, points, peak
  memory) in each prime artifact -- every production run is
  self-instrumenting from here on; t_finite_field_strip_solve green.
  Output: BenchmarkStripBackends/frozen_M0/census_run/. Watchdog
  registered (30-min stall threshold).

2026-08-20 22:17 SCRATCHPAD WIPED at 22:14 by the harness
  restart (same OS-cleanup hazard as the 2026-08-20 morning loss).
  Durable artifacts were already in the repo and are intact: the
  certified inventory, frozen M0 fixtures/results, benchmark records,
  all nine upgraded sector-route records (via FamilyEpsFormsCertified).
  LOST: the watchdog heartbeat history, the probe staging dirs, the
  upgraded sector STATES (all nine families complete, so no resume
  need), and the Opus module-review report (codex_module_review.md) --
  its findings are preserved only as the applied-fix list and tracked
  items in the 17:5x plan entry. Lesson applied: review reports and
  any checkpoint we might resume from go into the repo (Design/ or
  External/), never scratchpad-only. Watchdog directory recreated and
  the agent re-engaged on the M0 census run.

2026-08-20 22:41 M0 CENSUS RESULT (CF254 (9,6), 2 cores / 1
  kernel, user-authorized): solved exactly, wall 1399.5 s (1365 s
  concurrent earlier -> intrinsic single-kernel cost), 7 primes,
  {32,15x6}=122 samples, system 736x728 at 94% density, rank 724,
  nullity 4, peak memory 0.41 GB. Stage split: Setup 35.2% (462 s --
  the previously untimed per-sample rebuild), matrix build 32.4%,
  preprocessing 9.2%, the four eliminations together 23.2%. FINDING:
  the cost split is regime-dependent -- on small blocks (the majority)
  O1 hoisting + O2 build dominate (77%) and A1 saves <=17%; on (9,7)-
  class blocks A1 dominates. Production needs both; the regression
  suite pins both fixtures. Census in BenchmarkStripBackends/frozen_M0/
  M0_census_CF254_9_6.{md,wl}; per-sample timers now persist in every
  prime artifact of every production run.

2026-08-20 23:29 O1 LANDED AND ACCEPTED. Setup hoist in
  FiniteFieldStripSolve.wl: PrepareEpsFormStripSampling computes the
  regulator/prime-independent setup once (fingerprinted); the sampler
  reuses it via "Preparation" (+ "ExpectedFingerprint" to avoid
  re-hashing per sample); the solver prepares once per solve. Measured
  on CF254 (9,6) at 2 cores / 1 kernel: 1399.5 -> 1035.5 s (1.35x),
  IDENTICAL exact gauge and residues, same 7 primes / 122 samples;
  setup 462 -> 58 s (the residual was the per-sample hash, now passed
  once; ~55 s more expected). Subkernels no longer load CANONICA.
  Tests: new t_finite_field_preparation + three FF tests green.
  Records: frozen_M0/O1_acceptance_CF254_9_6.md + o1_run/. Codex
  observed running RunM1EndToEnd.wls in External/CodexExchange/
  codex_ff_m1_m2_2026-08-20/ -- M1 prototype in progress on its side.

2026-08-21 00:01 M1 STANDARDIZED INTO THE PACKAGE (Codex's
  exploration verified first: its (9,7) end-to-end solution is SameQ
  to the frozen oracle, exact residual zero; its 2144-vs-1953
  bookkeeping reconciliation accepted -- same ansatz, residue
  elimination schema differs). Port in FiniteFieldStripSolve.wl behind
  the existing seams: pilot sample (full path, "DiscoverPlan") ->
  plan {normalization columns, row basis, verified square core} ->
  every later sample = ONE LinearSolve of the constrained core with
  nullity+1 RHS + all-row / nullspace / normalization checks, typed
  Discard statuses filtered from interpolation; plan columns pinned
  into InterpolateEpsFormStripAffine; solver option "Elimination" ->
  "Constrained" (default) | "Full" (fallback/diagnostic); nullity-0
  degenerate case handled (caught by the adaptive-sampling test).
  Tests: new t_finite_field_constrained_solve 9/9 (constrained sample
  reproduces the full path's normalized particular + nullspace exactly
  on the real (9,6) record; incompatible plan falls back) + the four
  other FF tests green. Acceptance run (9,6) 2 cores / 1 kernel in
  progress vs the 1035.5 s O1 baseline. Follow-ups tracked: discarded-
  sample REPLACEMENT (v1 relies on the validation margin + fullRetry);
  M2 installation contract (modular affine carry) = next session's
  architecture item; Codex's add-ons (production matrix builder, fused
  point evaluation, dense/sparse dispatch, nonzero-Schur-rank pair).

2026-08-21 00:14 M1 ACCEPTED: CF254 (9,6) at 2 cores / 1
  kernel 755.9 s vs 1035.5 (O1) vs 1399.5 (M0) -- combined O1+M1
  1.85x; identical exact gauge and residues, exact check True;
  122/122 samples constrained, 0 discards, same 7 primes; setup 0 s
  (fingerprint pass-through confirmed), eliminations 305 -> 83 s.
  Plan: rank 724, nullity 4, normalization columns {677,681,682,683}.
  Remaining (9,6) cost: build 59%, preprocessing 17%, solve 11% -> O2
  and A2 are the next small-regime levers; M2 (modular affine carry,
  Codex's installation contract) is the next architecture item.
  Record: frozen_M0/M1_acceptance_CF254_9_6.md + m1_run/.

2026-08-21 00:47 O2 ACCEPTED (both slices). CF254 (9,6), 1
  kernel: 755.9 (O1+M1) -> 443.6 (O2a: packed monomial-table
  evaluation + vectorized per-block row assembly) -> 249.7 s (O2b:
  symbolic {x,y,eps} forms once per block, mod-p reduction memoized
  once per prime, per-sample eps-collapse). CUMULATIVE 5.6x vs the M0
  census (1399.5 s); exact gauge/residues identical to the oracle at
  every step; 7 primes / 122 samples unchanged. Stage totals now:
  setup 0, preprocessing 2.9 s, build 68.8 s, one constrained solve
  84.6 s, + ~90 s interpolation/lift/exact check. Per sample 10.8 ->
  1.3 s. Five FF tests green incl. stored-sample old-vs-new builder
  equivalence. Record: frozen_M0/O2_acceptance_CF254_9_6.md +
  o2a_run/, o2b_run/. User rule re-affirmed: ONE main kernel of ours
  (one seat spared for Codex) -- acceptance runs now strictly serial.
  Next levers: A2 (Codex, in progress) -> lift/exact-check cost ->
  solve (A3/A4). Round-2 assignment: External/CodexExchange/
  fable_ff_round2_assignment_2026-08-21.md.

2026-08-21 04:05 DIAGONAL-BLOCK EPS-FORMS ON THE FINITE-FIELD ROUTE
  (hard-class stage 1 migrated). New module FeynFacet/Private/
  DiagonalBlockEpsForm.wl (DiagonalBlockEpsForm = DiagonalBlockSliceEpsForm
  -> SolveDiagonalBlockGaugeFiniteField -> CompleteDiagonalBlockEpsForm ->
  CertifyDiagonalBlockEpsForm). The bilinear problem dT = A T - T eps
  Sum R_a dlog phi_a is linearized by ONE spectator slice (Lee balances +
  factor-out, Libra; fixes R_a of every x-dependent letter), then the
  x-equation is a homogeneous linear ODE in x at fixed (y, eps) mod p
  (16 (n_x+1) unknowns, nullity 1), nested rational interpolation in y
  and eps, CRT + rational reconstruction, exact x-check; the pure-y
  residues and the rational scalar gauge are read off exactly from the
  y-direction (trace/traceless split, partial fractions; regulator-
  dependent scalar factors of any degree handled -- class 79 produced
  a quartic); acceptance = exact two-variable gate. Denominator
  multiplicities from the integer parts of the local exponents (census
  reproduced the certified denominators of all three classes exactly).
  RESULTS vs the certified 2026-08-16 forms as oracle (T_new = T_old .
  constant, same letters, same residue spectra, gate Certified): class
  79 slice 62 s + solve 713 s (5 primes) + 10 s = 13 min (old route:
  224 s + 53 min replay + ~20 min factor-out, hand-driven); class 97
  107 + 129 (5) + 3 s = 4 min; class 77 934 + 1533 (11) + 12 s = 41 min.
  Records: HardClasses/DiagonalBlockFiniteField/ (README, per-stage
  .wl, probe logs, the superseded bivariate attempt). Test: Tests/
  t_diagonal_block_epsform.wls 13/13 (synthetic 2x2 with known answer,
  eps-dependent apparent locus, 2.1 s end to end). Bugs met and fixed
  on the way are listed in the README (oracle Ax/Ay are the gated forms;
  FirstPosition subexpression match; Return-in-Do; nested slots; Lee
  Fuchsification needs lowering at a regular point when no singular
  partner exists). Follow-ups: reuse discovered interpolation degrees
  (interpolation is 60% of the solve), normalization coordinate by
  minimal spectator degree (class 77's 11 primes), slice-stage profile
  (Libra algebra with eps symbolic). Generality: needs a rationalizing
  chart with letters linear in the slice variable; no manual input
  otherwise.

2026-08-21 04:20 CORRECTION (watchdog catch): the probe/test assigned
  the conjugator to the Protected symbol C, making the "T_new = T_old .
  C constant" oracle line vacuous. Re-run from the stored certified
  records with a plain symbol (Scripts/diagonal_block_epsform_oracle.wls):
  all three conjugators x,y-free and invertible (79: scalar in eps; 97:
  constant/eps; 77: constant rational). Letters, spectra, gate were
  never affected. Test fixed, 13/13. Rule: no single-capital-letter
  assignments in Wolfram scripts.

2026-08-21 12:15 STAGE-1 ENGINE STANDARDIZED ON THE FINITE-FIELD ROUTE.
  Benchmark first (identical inputs, 4 subkernels, 170 classes without
  the hard three): CANONICA 3125 s 163/170 (refuses 16/68/84/115, caps
  on 26/33/118); FF 516 s but 149/170 -- 21 instant failures = blind
  spots, not hard cases. Fixed: reducible slice directions (swap, then
  sheared frames w = s + lambda v -- generic-line monodromy; shears also
  linearize letters whose quadratic part factors), normalization stalls
  (regular-point balances for normalization, stall guard), scalar blocks
  (direct dlog; coefficient along a curve modulo q), zero blocks,
  fast failure on half-integer exponents -> automatic chart retry (conic
  both signs + catalog Kallen/Q4/Bilinear, ordered by linear pulled-back
  alphabet), interpolation-degree reuse. DiagonalBlockClassCampaign
  (CanonicalizeClasses schema, pool, optional CANONICA fallback,
  ValidateCanonicalForm re-check). FINAL: all 173 classes from the RAW
  (v,w) representatives, no hints: 173/173 certified (172 in 31 min
  wall; 77 in 49 min alone), 89 scalar / 83 FF / 1 zero, 24 automatic
  charts; oracle vs ledger: spectra identical on 170/172 + constant
  conjugation on all 169 same-variable classes; 79/97/77 identical after
  pulling the t-chart back to the Kallen chart (cross-chart oracle).
  Test t_diagonal_block_epsform 20/20. Record: HardClasses/
  DiagonalBlockFiniteField/README.md (standardization section),
  ClassFormsFF/ (173 ledger-schema records). Remaining cost: Libra slice
  with eps symbolic on the hard classes (77: 1547 s) -> modular balance
  search is the next lever.

2026-08-21 15:35 MODULAR (NUMERIC-REGULATOR) BALANCE SEARCH DONE. The
  slice only needs the residue tuple up to a constant conjugation, so
  the Lee chain runs at eps = 1/101 in Q(x) (integer parts by rounding,
  no factor-out; Libra only for rank-positive points, regulator-free
  branch; conventions from Libra's source). Heights: the numeric frame
  carries powers of 101 -> T needed > 20 primes; fixed by a canonical
  residue frame (simple-eigenvalue eigenvectors across residues +
  spanning-tree scaling) giving integer residues. Class 77 raw -> 189 s
  (slice 1.8, solve 180 with 2 primes) vs 2950 s. FULL CAMPAIGN: 173/173
  in 204.5 s wall (4 subkernels), oracle-identical to the ledger incl.
  cross-chart for 77/79/97. Records ClassFormsFF_numeric/; test 23/23
  (numeric vs symbolic engine agreement pinned). Stage 1 on the finite-
  field route is now ~3.5 min for the whole process.

2026-08-21 16:20 A2/A3/A4 STANDARDIZED (Codex round-2 off-diagonal FF
  optimizations). A3 sparse support: finiteFieldStripPrepare SupportCensus
  (valuation bound + closure cert), SampleEpsFormStripAffine builds only
  retained {px,py} columns ("Support"), solver shell-growth ladder ->
  rectangle fallback; (9,7) 2144->1568 unknowns, (9,6) 728->548, no oracle
  leakage. A2 held-out sampling ("RegulatorSampling"->"HeldOut" default):
  construction prefix + fresh held-outs + grow-on-failure + degree-profile
  reject; lift guarded by an unseen-prime residual before the exact check;
  122->70 images. A4 FLINT backend FeynFacet/Backends/flint (Codex .c
  unchanged, build.sh, MANIFEST libflint 3.0.1 LGPL); constrained core ->
  nmod_mat_solve when >=256 wide, re-verified in Wolfram; solve 4.9->0.35 s
  per (9,7) sample. ACCEPTANCE vs O2b oracle (SameQ gauge/residues/alphabet,
  exact residual zero): (9,6) 249.7->157.1 s; (9,7) 7254->1446 s (5.0x).
  Remaining (9,7) cost is the point/row BUILD (~14 s/sample, O2 evaluator),
  not solve/interp/lift/check -- next lever. Test t_finite_field_round2
  (11 checks) + five existing FF tests green (adaptive_sampling pins
  Deterministic). Record BenchmarkStripBackends/frozen_M0/A2A3A4_acceptance.md.

2026-08-21 23:10 TWO-ROOT COMPLETION CAMPAIGN LAUNCHED (user go, quoted:
  "solve the remaing 2 roots families with our latest machinery, 2
  subkernels each, and I want there to be a good progress estimate";
  then "1) run 3 in parallel"). Plan step: HANDOFF next-steps item 4 /
  work item 2 (complete the family eps-forms of CF231, CF265, CF305).
  Machinery: standardized sector route (family_epsform_sector.wls:
  complete-sector CANONICA 30 s -> per off-diagonal block dlog
  recognition, CANONICA degrees 0-3 at 120 s, Maple 300 s, finite-field
  affine solve with M1/O2/A2/A3/A4 + today's dlog-form gate ->
  TransformDlogToEpsForm per sector -> family certificate), then
  CertifyFamilyEpsilonForm into FamilyEpsFormsCertified/. Execution:
  three families IN PARALLEL as KernelPool missions (one main + 3
  subkernels, FeynFacet preloaded, taskset P-cores 0,1,6,7,8,9); measured
  23:09 that subkernels cannot launch helper kernels on this licence (0 of
  2), so each family runs on ONE kernel, not the requested two -- stated
  to the user. Driver Scripts/tworoot_parallel.sh; progress and estimate
  Scripts/tworoot_status.sh (units = sectors and the script's own
  "non-eps-factored strips remaining"; per-sector model calibrated from
  the CF254 run of 2026-08-19 until measured: assembly 25 min, small
  sector 90 s, large sector 450 s per lower sector, finish 15 min).
  EXPECTED COST (prior): CF231 ~4.6 h, CF305/CF265 ~7.4 h each, i.e.
  ~7.5 h wall in parallel, uncertainty ~2x either way until the first
  large sector is measured. Output FamilyEpsFormsSolving/tworoot/.
  Watch: Monitor (milestones, "!!" lines, stall > 75 min with CPU check,
  pool death), 5-minute rounds.

2026-08-21 23:21 CAMPAIGN STOPPED BY USER ORDER ("Stop. 1) fix the parallel
  problem, we need it really working 2) first test our strategy perhaps.
  Do we really need Maple ...; how does canonica numerator compare against
  finite field?") after 11 min (all three families still in assembly; no
  sector completed, nothing to keep). Pool stopnow, waiters killed by PID;
  one self-inflicted casualty: a kill loop driven by `pgrep -f` matched
  the coordinator's own shell (the CLAUDE.md trap, again) -- harmless
  here, but the rule stands: enumerate PIDs from a status file, never
  from a pattern. Next: (1) measure the licence for 3 mains x 2
  subkernels and the nested-launch refusal message; (2) benchmark
  CANONICA degree ladder vs Maple vs finite field on real strips before
  relaunching.
