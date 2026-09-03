# Session transfer note — 2026-09-02 (overnight package overhaul; Fable)

Read `Design/PrivateOverhaul_2026-09-01.md` first: it is the living plan
with done / running / not-done / decisions-for-the-user, the bug list,
the benchmark table and the CF259 state. This note is the short version.

## Current status (2026-09-03 15:40, one block; everything below it is history)

- Package: seven layer folders under `FeynFacet/Private/`, each with
  sub-folders by responsibility (round 5), manifest `Private/LoadOrder.wl`
  with layer-relative entries, `feynFacetPrivateFile` for module paths;
  superseded code in `Private_Backup/` with evidence. Round 4 moved 55
  upward cross-layer calls down; the few remaining ones are named in the
  manifest header and `Design/GeometryDeclaration_2026-09-02.md`; since round 6
  the graph is acyclic (Geometry loads before EpsForm).
- Stage 1 (eps-forms): `DiagonalBlockEpsForm` with the Libra balance slice
  and the finite-field strip solvers; CANONICA and Maple routes retired.
  Round 8 (2026-09-02/03): the off-diagonal strip solvers no longer
  materialize the block equation in characteristic zero: the deferred
  DAG is evaluated natively at the sampler's points
  (`EpsForm/FiniteField/FiniteFieldDeferredForcing.wl`,
  `FACET_DEFERRED_FORCING=Off` restores the exact route). Hard rungs
  CF300 (12,9) 51 s to 22 s and (12,7) 246 s to 115 s; CF303's block
  (25,18) now passes the census in 13 s and reaches the sampler, where
  it fails typed as Codex's recorded no-go predicts (no rational dlog
  form). Reviewed adversarially (R2); the fixes of its findings are
  pass 4 of `round8/M_stage1_speed.md`. Next levers with measured
  bounds: batched per-prime adapter solves, the normalizer's per-point
  evaluation.
- Stage 2 (transport): `BuildObservableTransport` is the only production
  route. Laurent extraction is one `Series` per entry with per-row order
  caps (`"Series"`, round 4 agent L): identical canonical coefficients,
  CF259 265 s instead of 564 s. The jet route is kept selectable but is
  pathological on nested-quotient entries (candidate for the backup).
  Codex's modular-only closure was costed and not built (report L).
- Non-eps-form final layers (CF303 class): a general route
  `BuildRationalEpsilonLayerTransport` (`Transport/Observable/RationalEpsilonLayer.wl`)
  transports a rational-in-epsilon lower-triangular final layer order by
  order (certified epsilon window, sealed Hermite circuit over F_q[u],
  lifted gauge H at the endpoint, bound certificate, predicate that
  re-derives residues and words); test 35/35 with NDSolve-based
  assertions; reviewed adversarially twice (R1). CF303 itself is NOT
  transported: the elliptic (curve) channel, the seven Maple-only
  exception forcings, the T25 gauge, generic p and a lazy word
  representation for the weight-6 growth remain (list in
  `round8/T_noneps_transport.md`).
- Transport-ready records must carry a certificate of their epsilon
  valuations (`CertifyTransportEpsilonValuations`; produced by
  `Scripts/compact_family_dlog_record.wls`); the transport refuses an
  uncertified record typed. The stored CF259 record predates the
  certificate; certifying it is open (the certifier exceeds its cap on
  that 47 x 47 record; the fix is a numeric-point Series per entry).
- Accepted observable transports (round 9, 2026-09-03): 85 of the 87
  certified families under the certified route, records in
  `Results/UU_08_10_canonical/ObservableTransport_2026-09-03_round9/`
  (written only after `AcceptedObservableTransportQ`); the 2026-09-01 set
  is history (its records predate the valuation certificate and are
  refused by the current predicate). Typed refusals: CF265, CF305
  (`DLogResiduesRequired`, first-kernel dlog residues; with T). Physical
  boundary modes 39/40 and endpoint transports 39/39 of the 40
  nullity-period families in the `*_2026-09-03_round9/` siblings
  (CF211 degenerate eigenspace open; the period coefficients are formal
  until Stage 3 supplies values). Codex's overnight campaign record:
  `Goals/Codex/2026-09-03/01_round8_and_physical_transport.md`.
- CF259: transported with the valuation certificate bound, accepted by the
  current predicate: `.../CF259/observable_transport_2026-09-02_certified/`
  (270 s, SameQ with the 05:51 artifact, which no longer passes the
  predicate and is kept as history). CF300 and CF303 are not transported.
- Tests: 12 retired, 8 fixed in round 3 (the long ones were quadratic test
  code, not physics); verification policy: small targeted tests through
  the two licensed kernel seats, no full-suite runs, kill pathological
  runs and fix the cause.
- Codex's 2026-09-02 assessment (`Exchange/Codex/2026-09-02/`): every
  point worked through in round 4 (agents T, M, G, L; reports under the
  plan's evidence folder `round4/`).
- `main` is ahead of `origin/main`; pushing needs the user's decision.

## What changed

- `FeynFacet/Private/` restructured into seven layer folders with the
  load-order manifest `Private/LoadOrder.wl` (`Design/PrivateLayers_2026-09-02.md`).
- Superseded code moved to `FeynFacet/Private_Backup/` (never loaded),
  each move with evidence in `Private_Backup/EVIDENCE.md`; retired public
  entries answer `RouteRetired`.
- The accepted lazy-operator observable transport (Codex branch) was
  adopted into this tree (`Transport/ObservableTransport.wl`,
  `ObservableTransportFiniteField.wl`, pool mission and campaign
  scripts, eight tests); a regression in its last revision (records
  without `ChartRecord` refused) is fixed.
- New `Core/ModularArithmetic.wl`: one implementation of the finite-field
  primitives (goal 2); call-site migration status in the plan.
- Laurent extraction: an exact epsilon-jet route was written (goal 6) but
  production stays on SeriesCoefficient (see Current status);
  rank-sampling failures carry diagnostics and can dump their state.
- Pool and driver fixes (B1-B4 in the plan): kernel-launching tests are
  standalone-only; requeued missions are no longer filed DUPLICATE; the
  pool and its tools take their root/paths from the file location or
  `FACET_SCRATCHPAD`, never from a hard-coded session path.
- Certification audit applied in part (goal 10): memoized ABI
  fingerprint, cached adapter hashes; the rest listed in the plan.

## CF259 (goal 11)

Inputs (assembled eps-form, native dlog residues, compact transport-ready
record with Codex's transport valuations, path card) are under
`Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF259/transport_inputs_2026-09-02/`.
State: TRANSPORTED on the overhaul branch (probe 5, 05:51, 564 s), credible
but provisional until the valuation certificate of round 4 binds TMin and
the block bounds to the record:
`Results/.../CF259/observable_transport_2026-09-02/observable_transport_CF259.wl`,
status ModularlyVerifiedObservableTransport, 20 demanded (order,row)
pairs, 167 boundary coordinates, maximum weight 5, operator-automaton
representation (demanded maps materialize through
ReconstructObservableTransportWordMaps with fresh modular acceptance).
The four earlier probes failed at the rank-sampling step because the
finite-field compiler did not accept rescaled declared radicals (B8 in
the plan); the fix and its test are on the branch. The Laurent
extraction (439 s of 564 s) is the remaining hot spot.

## Round 2 (2026-09-02, after the user's rulings on U1-U4 and N1-N8)

Retired to `FeynFacet/Private_Backup/` (evidence table in its EVIDENCE.md,
"Round 2"): the Libra path-ordered transport engines (`TransportFamily`,
BlockwiseTransport, CanonicalWordTransport, the exception seam and native
jets, the word/quadrature heads), the CANONICA class ladder
(`CanonicalizeClasses`) with its loader and helpers, the CANONICA/Maple
strip-ladder remnants and the broker's CANONICA farming, and
`multiquadraticSplitPointQ`; ten tests of those routes and the August
sweep/Libra scripts went with them (`Private_Backup/Tests/`,
`Scripts/Backup/retired_routes_2026-09-02/`). The retired public names
answer `<|"Status" -> "RouteRetired", ...|>`. CANONICA is no longer loaded
anywhere in the live package: `ValidateCanonicalForm` solves the residues
exactly itself and re-verifies the dlog identity with Together. Libra
stays exactly where stage 1 needs it: the balance slice of
`DiagonalBlockEpsForm`, the production canonicalizer. The sector driver
lost its Legacy branches (pre-removal copy under `Scripts/Backup/`).
Also applied: native constrained-core solves replay all rows by Freivalds
projections (U2); the solver's source hash is replaced by the
hand-maintained `$multiquadraticStripABIVersion` (U3); strip results carry
one top-level `Timings` record (U4); the reserve-prime schedule uses the
shared generator (N7). The benchmark harness has a stage-1 item on real
classes (`dbe_class<N>`): a stage that has produced its artifacts stays a
maintained, optimizable route (user ruling). Acceptance of round 2:
fresh-kernel smoke queue on the affected tests, then the full suite; see
the plan's "Round 2" section for the tables.

## Verification policy (user ruling, 2026-09-02 12:15)

Verification must be small and fast: after a change, run the small tests
of the touched code in fresh kernels, 8-way, as `fresh_<test>` missions of
the KernelPool (each relaunches one subkernel), never the driver's serial
standalone phase, and never the whole suite as an acceptance ritual. The
long integration tests are a defect of the tests: the real-block sections
of the three multiquadratic gauge tests now run only with
FACET_TEST_LONG=1, and the plan's "Test cost audit" lists the next
fixtures to shrink (the Kira-store rebuild of
t_physical_variable_coefficients first). Round 2 was accepted on the
smoke queue of the affected tests plus fresh-kernel checks of the pooled
failures; the three long solver tests were cancelled rather than waited
for.

## Acceptance batches and what they found

Both trees ran the full suite through their own KernelPool in reuse mode
(baseline = main at 2d73f71f, overhaul = this branch); the pooled phase is
a screen, every pooled failure was confirmed in a fresh standalone kernel
(the branch's confirmations through a sequential seat queue after its
driver died, 06:37). Final merged verdict over the 146 baseline rows plus 9 new tests: 118
identical (green on both, or the same verdict), 1 fixed by the overhaul
(t_algebraic_observable_transport), 9 new tests green (t_modular_arithmetic,
the seven adopted observable-transport tests, the rewritten pool verdict
test), 2 retired with their routes (t_libra_family_eps_form,
t_maple_canonical_gauge, now under Private_Backup/), 9 red on BOTH trees
with the same failing assertions
(t_multiquadratic_installation, _end_to_end_install,
_installed_family_chain, _obstruction_driver, _regulator_reconstruction,
_strip_solve, t_exact_depth, t_master_transport, t_streaming_kira_import),
3 without a verdict on either tree (t_multiquadratic_gauge_ladder /
_gauge_screen / _letters hit the 30-minute cap on the baseline; their
compile route is ~7900 s). No regression. The first comparison (06:05) had
shown twelve regressions with one root cause each, all fixed the same
night and recorded as B9-B14 in the plan: the strip solver located its own
source by a flat `Private/` path (B9), a broker helper was moved to backup
although a test drives it (B10), reused subkernels carried leaked Global
values (B11), the finite-field route stores timings and provenance hashes
inside its result (B12), `FeynCalc`Names` shadows `System`Names` (B13),
the multiquadratic certifier starved its prime budget on inadmissible
primes (B14, a pre-existing flaky design). An adversarial review of the
diff found four defects (D1: my layer order emptied SolveEpsFormStripInFrame's
inherited options; D2, D3, D4) and six risks; all defects and five risks
are fixed, the rest is in the plan's not-done list. Evidence:
`Design/PrivateOverhaul_2026-09-01_evidence/`.

## Merge state

The branch `overhaul` (17 checkpoints on top of 2d73f71f) was fast-forwarded
into `main` at the end of the session after the acceptance above; the
plan file is `Design/PrivateOverhaul_2026-09-01.md` (bugs B1-B14, review
findings D1-D4 and R1-R6, benchmarks, not-done list N1-N9, decisions for
the user U1-U4). If the merge commit is not on `main`, the branch is
complete and mergeable with `git merge --ff-only overhaul`.

## Rules that changed

- Test batches in reuse mode; two main kernels is the licence limit with
  the pool up; sequence standalone jobs.
- Lane split with Codex dissolved; the Codex tree is reference only.
- Scripts and tests write `System`Names`, never bare `Names` (B13).
- Run a batch driver from a scratch COPY: editing a running bash script
  killed the overhaul driver's standalone phase (bash reads incrementally).
- Test symbols get descriptive names; the pool unsets leaked Global
  values between missions (`FACET_POOL_ISOLATION=0` disables it).

# HANDOFF — orientation and workflow walkthrough

Rewritten 2026-09-01 as a general guide; the running session log that
used to live here is preserved in git history. Read CLAUDE.md after
this file for the house rules and full detail.

## What this project computes

FeynFacet computes the NNLO hard function for pp -> h+X via collinear
factorization and reverse unitarity. The active frontier is the
double-real channel: 347 master integrals, reduced to 91 family
systems of coupled first-order differential equations in two
dimensionless variables (v, w) with dimensional regulator eps.

**Overall state in one line:** most of the calculation is done —
stage 1 is complete, stage 2 is complete for the large majority of
families including the hardest one (CF303, carried through its
elliptic layer up to boundary constants); stage 3 (boundary
constants) is the open frontier, stage 4 not yet started.

## The workflow, stage by stage

**Stage 1 — canonicalization.** Decompose each family's DE system into
blocks, classify into equivalence classes, and bring each class to
epsilon-form dF = eps (Sum_a R_a dlog phi_a) F with constant residues.
State: all 173 block classes have validated eps-forms; 54/91 families
carry whole-family certified eps-forms
(Results/UU_08_10_canonical/FamilyEpsFormsCertified/ — a family listed
Exact there is never re-solved). The engine is the finite-field
machinery in Private/ (diagonal blocks push-button; off-diagonal deep
rungs by simultaneous modular affine solve with rational
reconstruction); charts rationalize root geometries (TransportCharts).

**Stage 2 — transport.** Solve family by family along paths: masters
as iterated-integral words with symbolic boundary constants. State:
73/90 families have transported masters
(Results/UU_08_10_canonical/Masters/). The remaining stragglers are a
few timeouts, a group with eps-dependent path quadratics (uncleaned
couplings), and the triple-root tail CF259/CF300/CF303. For CF303
(the hardest family): the rational 21-block / 37-master subsystem has
an exact GPL solution rotated to physical source masters through
eps^2 (compact lazy operator + on-demand materializer); the four
algebraic blocks (15, 17, 21, 25) close over a single quartic
elliptic curve with mixed GPL/eMPL (E4/Z4) letters, completion of the
block-25 exception couplings in progress. Five row-25 couplings carry
certified proofs that NO epsilon-form / constant-residue dlog form
exists on their complete certified letter spans
(Results/UU_08_10_canonical/PathTransportObstructions/CF303/) — those
couplings are transported in integral form / elliptic letters by
design, not by failure. CF259: hard row solved exactly, alphabet
reconstructed cleanly; transport application unfinished. CF300: rows
solved; transport application unfinished.

**Stage 3 — boundary constants.** Transport fixes solutions up to
integration constants; the constants are cut phase-space periods at
ordered limits (Design/Stage3BoundaryToolchain.md, evidence under
Results/UU_08_10_canonical/BoundaryPeriods/). State: 3 periods
ledger-Exact; the many-period tier is open. This stage is what turns
words into numbers, and it gates the only remaining end-to-end
validation: point-wise comparison of masters against an independent
method (sector decomposition / AMFlow).

**Stage 4 — endpoint expansion and assembly.** Plus-distribution
extraction needs unexpanded endpoint modes (exact indicial data), then
assembly into the hard function. Not yet in the package. The final
function-class decision: GPLs where eps-forms exist; E4/Z4 elliptic
polylogarithms on the quartic curve for the algebraic blocks; a
certified series evaluator as the numerics backbone. Acceptance bar
for any function in the final result: evaluable at a point by existing
public code (GiNaC class) — no bespoke integral definitions.

## How things run

- Load the package: Get[".../Addon/Load/LoadFACET.wl"].
- Tests: ./run_tests.sh; focused batteries under Tests/<area>/.
- Kernel jobs go through the KernelPool (Scripts/KernelPool.wls;
  kpsubmit.sh / kpwait.sh / kpstatus.sh).
- Long runs: Scripts/run_with_allowance.sh ALLOWANCE LOG SCRIPT
  [args] — embeds a hard kill at the allowance — plus a watchdog per
  Design/Watchdog.md, armed in the same turn as the launch.
- Check levels: FACET_CHECK_LEVEL=Production keeps cheap exact guards
  in-calculation plus one terminal certificate per result;
  Development enables the exact intermediate identities.
- Verification culture: acceptance is always exact — reconstruction
  identities, fresh-prime / held-out-image agreement; numerics may
  guide but never prove; structural shape checks are never success
  criteria.
- Wolfram/Maple/shell traps that have cost real time are catalogued
  at the bottom of CLAUDE.md; read them before writing kernel code.

## Where things live

- FeynFacet/ — the package; Private/ holds the stage modules;
  Backends/flint/ the native finite-field evaluators.
- Scripts/ — pool, launchers, campaign drivers.
- Design/ — architecture and method records.
- Tests/ + run_tests.sh — the acceptance suite.
- ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/ — certified
  artifacts: eps-forms, masters, obstruction certificates, boundary
  periods. Certified evidence is never modified in place.
- Archive/ — retired implementations kept as references.

**Round 3 (2026-09-02 afternoon, user ruling: fix the tests, kill pathological runs).** The two 30-40 minute synthetic tests were quadratic in their own source scan (per-character `AppendTo` over the 950,000-character solver source), now a linear `FTTest`FTStripComments`; the obstruction certificate no longer recomputes the eps-series matrix products per entry and its test certifies orders 0-1 by default; the three red multiquadratic tests were asserting against their own spelling of a gauge denominator that the engine canonicalizes (unit leading coefficient per factor, regulator-only factors dropped) and now read the canonical form from the engine; `t_streaming_kira_import` and `t_construction_dag` fail or crawl only in reused pool kernels (standalone 19/19 in 90 s and 86/86 in 3.9 s); `t_multiquadratic_installed_family_chain` was briefly moved to the backup as never-green; Codex corrected that (it had passed 14/14 four times): the automatic `GaugeDenominatorFactor` enlarged the planted base denominator, the test now pins the factor to 1 and is back in the suite. TestKit stamps every assertion with its wall seconds. Two fresh kernels hung at start on a paclet-server fetch and were killed; on the user's decision `$AllowInternet = False` is set in `~/.Wolfram/Kernel/init.m`. Details and measurements: `Design/PrivateOverhaul_2026-09-01.md`, sections "Round 2 acceptance" and "Round 3".

## Round 6 (2026-09-02 17:10): nothing in flight

All three open items of round 5 are done and pushed: CF259 transported on the certified record (accepted, `observable_transport_2026-09-02_certified/`), the Jet Laurent route retired to the backup, the layer graph acyclic (`SolveEpsFormStripInFrame` now in `EpsForm/Strip/`, Geometry loads before EpsForm), the seat launcher hardened (`Scripts/seat_run.sh`). Next: the certifier speed-ups listed in T's report; CF300/CF303 remain untransported.
