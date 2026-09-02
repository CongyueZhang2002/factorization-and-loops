# factorization-and-loops (FeynFacet)

Production tree for the FeynFacet package: collinear factorization and the
NNLO hard function for pp -> h+X. **New agent sessions: read this file end to end before acting.** It is the
only orientation document: workflow, current frontier, and house rules.

The legacy tree `~/FACET` is frozen reference material and the parallel
assistant's workspace — never write there.

## START HERE

**Round 2 of the overhaul (2026-09-02, user rulings U1-U4, N1-N8 in
`Design/PrivateOverhaul_2026-09-01.md`):** the Libra path-ordered
transport engines (`TransportFamily` and its modules), the CANONICA
class ladder (`CanonicalizeClasses`), the CANONICA/Maple strip-ladder
remnants and the August sweep scripts are retired to
`FeynFacet/Private_Backup/` and `Scripts/Backup/`; their public names
answer `RouteRetired`. CANONICA is not loaded anywhere in the live
package (`ValidateCanonicalForm` is self-contained). Libra remains
only where stage 1 needs it, the balance slice of `DiagonalBlockEpsForm`,
which with the finite-field diagonal-block route and the sector driver
is the production canonicalizer. **A stage that has produced its
artifacts is still a maintained, optimizable route**: the benchmark
harness (`Scripts/Diagnostics/benchmark_overhaul.wls`) carries stage-1
items on real classes (`dbe_class<N>`) next to the transport items.
Passages below that describe Libra as the stage-2 engine, CANONICA in
stage 1 or `sweep_transport.wls` are history.

**State advanced on 2026-09-02 (package overhaul, user-assigned; the
running record is `Design/PrivateOverhaul_2026-09-01.md` -- read it
before anything below, several older rules in this file are superseded
by it):**

- `FeynFacet/Private/` is organized in seven layer folders (`Core`,
  `Process`, `Reduction`, `Infrastructure`, `Geometry`, `EpsForm`,
  `Transport`); the load order is the manifest
  `FeynFacet/Private/LoadOrder.wl` (`Design/PrivateLayers_2026-09-02.md`).
  Superseded code lives, never loaded, in `FeynFacet/Private_Backup/`
  with its evidence (`EVIDENCE.md`); the CANONICA/Maple strip ladder
  (`SolveEpsFormStrip`), the whole-family Libra route
  (`LibraFamilyEpsForm`) and the Maple canonical gauge mode are retired
  and answer `<|"Status" -> "RouteRetired", ...|>`.
- Production transport is the observable transport
  (`BuildObservableTransport`, `FeynFacet/Private/Transport/ObservableTransport.wl`
  + `ObservableTransportFiniteField.wl`, adopted from Codex's
  `codex/day-rank3-validation`); the 88 ordinary families' accepted
  transports are under
  `Results/UU_08_10_canonical/ObservableTransport_2026-09-01_codex/`.
  The Libra path-ordered engines of `TransportFamily` are the August
  sweep route (decision U1 in the plan).
- Test batches: `REUSE=1 Scripts/run_tests_pool.sh <pool> 8` (pooled
  screening on reused subkernels, then standalone confirmation of every
  non-OK result); kernel-launching tests are standalone-only. The
  licence admits the pool main plus ONE more main kernel: sequence
  standalone jobs (`bench/seatqueue.sh` pattern), never launch a third.
- The lane split with Codex is dissolved (user, 2026-09-02); the Codex
  tree is reference material.
- Finite-field primitives (primes, modular square roots, split points,
  CRT, rational reconstruction, lift-and-verify) have ONE implementation:
  `FeynFacet/Private/Core/ModularArithmetic.wl`; do not add another.


**Session transfer note: `HANDOFF.md` (repo root) — volatile state,
open decisions and next steps, newest first. Read it before this file.**

**State advanced on 2026-08-20 — read the TransportProductionPlan.md
entries of that date before anything below.** The single ground-truth
family eps-form inventory is now
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsCertified/`
(54/91 certified by full recomputation; `certification_report.wl` has
per-family status and diagnostics). **A family listed Exact there is
never re-solved.** The family eps-form layer lives in
`FeynFacet/Private/FamilyEpsForm.wl` (context-guarded `FamilyArtifactRead`
— MANDATORY for reading any .wl artifact after CANONICA may have loaded —
atomic `FamilyArtifactWrite`, schema normalizer, and the certifier
`CertifyFamilyEpsilonForm`). Terminology (user-fixed): "diagonal block" /
"off-diagonal block (k,j)"; "strip" and "sector" retired from prose.
**Contract of the off-diagonal rung (clarified 2026-08-21 after a Codex
audit): `SolveEpsFormStripFiniteField`/`ReconstructEpsFormStrip` deliver a
DLOG FORM — regulator-free letters, residues free of x and y, the regulator
still allowed in the residues (`DLogFormCertified`); the sector driver then
applies CANONICA's `TransformDlogToEpsForm` and only the family certificate
asserts the epsilon form. Every deep-rung benchmark result has
regulator-dependent residues; that is normal, not a defect.**
The off-diagonal deep-rung solver `SolveEpsFormStripFiniteField` carries A2 (held-out regulator sampling, unseen-prime guard), A3 (a-priori sparse gauge support from the valuation census), and A4 (optional FLINT modular-solve backend, re-verified in Wolfram) as of 2026-08-21 — frozen (9,7) 7254 -> 1446 s; the build stage is now the bottleneck (`BenchmarkStripBackends/frozen_M0/A2A3A4_acceptance.md`). Deep-rung benchmark verdict (2026-08-20, equal resources): the
simultaneous finite-field affine solve is the production deep rung for
resistant off-diagonal blocks; Maple is the small-residue-system fast
path and cross-check (`BenchmarkStripBackends/` has fixtures + records).
Remaining without eps-forms: 29 zero-root (transport-only),
CF231/CF265/CF305, CF385/CF408 (blockwise schema adapter pending),
triple-root CF259/CF300/CF303. Hard-class stage 1 (irreducible diagonal blocks) is now a
push-button route on the finite-field machinery (2026-08-21):
`FeynFacet/Private/DiagonalBlockEpsForm.wl`, `DiagonalBlockEpsForm[{Ax,Ay},
{x,y},eps]` = one Libra slice -> finite-field ODE solve of the x-equation
-> exact y-completion -> exact gate; the engine is fully automatic from the raw
(v,w) representative (frame ladder with shears, automatic conic/catalog
charts, scalar and zero blocks) and re-derived ALL 173 classes with no
hints (173/173, oracle-identical to the ledger; 4 subkernels, 204 s wall
with the numeric-regulator slice engine and canonical residue frame);
`DiagonalBlockClassCampaign` writes CanonicalizeClasses-schema records.
Benchmark vs CANONICA and the record are in
`Results/UU_08_10_canonical/HardClasses/DiagonalBlockFiniteField/README.md`.
The section below describes the
2026-08-17 state and remains valid as background.

### Background (state at 2026-08-17 ~03:00)

**Stage 1 is CLOSED (173/173 certified eps-forms). Stage 2 is the active
campaign and its PRODUCTION SWEEP IS RUNNING**: one KernelPool mission per
family, `Scripts/sweep_transport.wls`, outputs
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Masters/<CF>.wl` (the
transported masters as words with symbolic constants + recursion
certificate + assembly certificate + original-DE check where performable
+ cost record) and `<CF>.status`; summary `Scripts/sweep_status.sh <outdir>`;
launcher `Scripts/sweep_launch.sh <outdir> [maxW] [cap] [ALL|list]`
(resumable: Transported families are skipped; `PRIORITY=1` puts the sweep
ahead of other queued missions).

Read these, in order, before acting:

1. `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/TransportProductionPlan.md`
   -- the campaign and its RUNNING RECORD (every measured fact and
   decision of 2026-08-17 is appended there with times).
2. `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/TransportDepthLedger.md`
   -- required depth per master (203 need eps^0, 131 eps^-1, 9 deeper) and
   the 2026-08-17 addendum on the coupling assumption.
3. `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsForms/README.md`
   -- agent B's family eps-form census (16 gated, 12 GateFailed, one
   failure mode) and the record schema the sweep's route 2 consumes.

What was built 2026-08-17 (all uncommitted; tests green unless stated):
- **Algebraic letters** (`FeynFacet/Private/BlockwiseTransport.wl`,
  `MasterTransport.wl` monic gate + radical zero test): quadratic path
  denominators with eps-free discriminant are admitted as letters
  (-b +- k Sqrt[D0])/(2a); `Tests/Multiquadratic/t_algebraic_letters.wls` 23/23. This is
  unavoidable (1 - w + v w in the Kallen chart is a genus-1 curve).
- **Chart catalog** `FeynFacet/Private/TransportCharts.wl`
  (`TransportChartCatalog`, `TransportChartVerify`, `TransportFamilyChart`):
  Kallen1/2/3, Q4a/b (degree-2-preserving), Bilinear115, joint Kallen12/13/23;
  per-family assignment measured; triple-root CF259/CF300/CF303 NOT covered
  (open: rationality of the triple cover).
- **(v,w) assembly of class MEMBERS** (agent A): the member's v<->w swap is
  recovered and applied (252/1028 members; no permutations); one-variable
  class-115 records refused by name in (v,w) and composed in charts
  ("frame 4"); `"BasePoint" -> Automatic` (both axis directions);
  `"DECheck"` option; per-block exact regrade assertion (verify mission
  `verA` was still running at 02:50).
- **KernelPool** patched (never-started missions: claim check +
  resubmission) and restarted 02:27; see Design/KernelPool.md.

PASS 1 RESULT (06:40): 85/91 with status, 40 transported at the ledger
demand N = -val + 1 (walls 0-965 s; CF12 15 min, CF24 ~1 h), ~40 not:
TimedOut at 1200 s dominates (chart families with non-pure couplings,
10^4-10^5-leaf coefficients), 3 ChartNotCovered (triple-root CF259/300/
303), a few PathDenominatorsNotLinear in Kallen12 (eps-dependent path
quadratics = uncleaned couplings). Cleanup pass 2a: 2 gated of 10 (CF20,
CF21), the rest GateFailed (two-variable Moser non-convergence); CF230/
CF258 cleanups were still running at 06:40. PASS 2b fires AUTOMATICALLY
when pass 1 drains (watcher `scratchpad/pass2b.sh` of the 26f8c32a
session): the failed families at the STRICT need N = -val (safety 0),
cap 2400 s, route 2 where a record gates -- status lines then say
"safety0". A safety-1 pass and the cleanup algorithm (Moser at infinity;
CANONICA off-diagonal recursion at higher degree) are the next work.

Next moves for a fresh session: `Scripts/sweep_status.sh .../Masters`;
re-run TimedOut families with a larger cap or via route 2; regenerate the
depth ledger .md over all 91 (`Scripts/Diagnostics/transport_depth_ledger.wls` +
`_assemble.py`; the 29 missing per-family records live in the coordinator
scratchpad `ledger/`); the triple-root tail; then stage 3.

**All kernel work goes through the KernelPool** (`Scripts/kpsubmit.sh`,
`kpwait.sh`, `kpstatus.sh`; pool dir in the 97c0fce7 scratchpad); if
`kpstatus.sh` reports nothing, remove `control/stop` AND `control/stopnow`
and relaunch per Design/KernelPool.md.

## What the project computes

The NNLO hard function for pp -> h+X, via collinear factorization and
reverse unitarity, in the Wolfram package **FeynFacet**. The physics
chain: process cards -> diagram generation -> cut-aware IBP reduction
(Kira) -> master integrals -> analytic evaluation -> endpoint /
plus-distribution expansion -> assembly into the hard function.

The active frontier is the **double-real channel**: 347 master
integrals, reduced to 91 family systems of coupled first-order
differential equations in two dimensionless variables (v, w) with
dimensional regulator eps.

## The master-evaluation workflow (stages)

**Stage 1 — canonicalization** (`FeynFacet/Private/CanonicalBlocks.wl`,
tests `Tests/EpsilonForm/t_canonical_blocks.wls`). Decompose each family's DE system
into strongly connected blocks (1119 of them), classify blocks into 173
equivalence classes (equivalence = basis permutation, optionally
composed with v<->w, as an exact rational matrix identity), and put each
class into **eps-form**: dF = eps (sum_a R_a dlog phi_a) F with constant
residues R_a. Acceptance is always an exact reconstruction check, never
a structural shape check.
Status: 173/173 classes have validated eps-forms (97 = CF258_B9,
77 = CF230_B1 and 79 = CF231_B1 certified 2026-08-16 as two-variable eps-forms in
the charts v = +-xy, w = (1-x)(1-y)); the hard-class stage-1 work is CLOSED — see
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/HardClasses/EpsFormRoute/README.md`.

**Stage 2 — transport** (`FeynFacet/Private/MasterTransport.wl`, tests
`Tests/Transport/t_master_transport.wls`). Given eps-forms, solve family by family:
assemble blocks in dependency order, transport solutions symbolically
(engine: **Libra**, chosen by measured benchmark — 0.03 s where our own
custom layer took >30 min; the custom engine is archived under
`Archive/voc_engine_2026-08-14/`). On top of Libra we keep only earned
components: the assembly certificate, valuation constraints, depth-budget
arithmetic, a Laurent/1-eps re-expansion layer for tier-3 couplings, and
a `ClosedFormSector` interface that consumes a closed-form fundamental
matrix + certificate directly.
Output: masters as generalized polylogarithms (GPLs) — eps-free
functions of kinematics; eps enters only through the expansion depth.

**Stage 3 — boundary constants** (`Design/Stage3BoundaryToolchain.md`,
evidence under `Results/UU_08_10_canonical/BoundaryPeriods/`). Transport
fixes functions up to integration constants; those constants are cut
phase-space periods at ordered limits. Toolchain, all probe-verified:
our nullity counter (<=33 candidate periods; validated 24/24 against
CF407), `asy 2.1` for regions, `MB.m` + `barnesroutines`, `HypExp 2.0`,
`SubTropica` for high-precision numerics. **PSLQ fabricates relations**
(negative control at 50 digits) — candidate generator only.
Ledger rule: a period enters only with the original cut integral +
normalization, exact variable map + domain, Frobenius mode + depth, an
exact value or exact zero proof, exact DE substitution, and an
independent numeric check. Numerics may guide, never prove: **every
recorded proof chain is numerics-free**.
Status: 3 periods ledger-Exact (PIDs 1, 6, 7 = 0), 12 realization
transfers verified, the 17-period tier is the open campaign.

**Stage 4 — endpoint expansion and assembly** (not yet in the package).
Plus-distribution extraction requires the UNEXPANDED endpoint modes
(1-w)^(a eps + m) — an eps-expanded log tower has lost its
delta-function content — so masters must ship with exact indicial data
and a mode decomposition, not just GPL words. Format verdict from Codex
still open; it sets production depth.

**Depth budget.** An ingredient's required eps depth = target order +
the deepest pole it multiplies anywhere in the subtracted assembly
(measure factors, IBP coefficient poles, transport regulator shifts,
subtraction kernels), plus 1 if the scalar->vector reconstruction is
Laurent-graded. The NLO analogue: LO must be carried to eps (eps^2 for
NNLO subtraction).

## Hard classes 97/77/79: all three certified (2026-08-16); frontier moves to stage 2

Entry point: `Results/UU_08_10_canonical/HardClasses/EpsFormRoute/README.md`
(state table, method record, consult records, ordered next steps).
One-paragraph version:

All three are order-4 irreducible at generic eps (certified), which does
NOT preclude an eps-form (a canonical form is a gauge transformation,
not a factorization). Their eps=0 operators factor completely, which
gave a first route (eps-graded recursion, `Scripts/EpsilonGraded.wl`,
certified scalar solutions through eps^3/eps^2 — the VERIFICATION
track). The production route is the eps-form route: rationalizing chart
-> Fuchsify -> Lee balances with the spectator SYMBOLIC -> Lee's linear
"factor out eps" step (an x-constant U(y,eps) from a nullspace over
Q(y,eps); Libra ships it as `FactorOut`) -> rational scalar gauge -> THE
GATE (original chart system through T equals eps Sum R_a dlog phi_a in
BOTH variables, constant R_a). Class 97 passed that gate on 2026-08-16
(`c97_epsform_two_variable.wl`); class 77 the same afternoon via the chart
involution (x,y) -> (1-x,1-y) (= v <-> w): its residue tuple is
sigma*(class 97's), and T_77 = T_eq . sigma*T_97 with a tiny T_eq
(`c77_epsform_two_variable.wl`). Class 79: the old t-chart hid three
irreducible quadratic loci; in v = -xy, w = (1-x)(1-y) (Q = lambda(-v,w))
every letter is linear; it went through the same pipeline the same day
(10 balances on a slice, symbolic replay, constant gauge by sampling +
rational interpolation verified exactly, gate) — `c79_epsform_two_variable.wl`,
independently re-derived. Ledger records `ClassForms/class{97,77,79}.wl`,
`Tests/EpsilonForm/t_hard_class_epsforms.wls` 24/24. Next: transport of these three
families in chart variables through the EXISTING `TransportFamily`
(chart-pullback layer `TransportFamilyInChart`, in review), then boundary
conditions at x = y by deck invariance and endpoint modes exact in eps.

Lessons that are now method (do not relearn): (i) check the pulled-back
alphabet of a class in a candidate chart BEFORE any normalization —
"irreducible quadratic locus" was a chart artifact; (ii) once a system
is normalized with the spectator symbolic, do NOT interpolate slice
transforms or run two-variable CANONICA — the finish is one linear
solve; interpolating raw CANONICA slices fails only because CANONICA
picks a free constant conjugation per slice; (iii) the eps-dependent
apparent loci introduced by balances come out of the y-direction as pure
scalar dlog terms with integer residues (the scalar gauge), and never
appear in the final letters; (iv) never claim an eps-form from a
one-variable check — the two-variable gate is the certificate.

## Two-assistant setup (important)

The user runs **two assistants in parallel on the same physics**: this
one (Claude/Fable, in `~/factorization-and-loops`) and **Codex**
(OpenAI, in `~/FACET`). This is deliberate: independent methods, then
cross-checked results. Rules:
- **Never write into `~/FACET`** — read-only reference, Codex's tree.
- Exchange goes through `Exchange/` as exact source files
  and certificates, not prose summaries.
- Codex's assessments of our work are valuable and have repeatedly been
  right; read the dated entries under `Exchange/Codex/` before re-deriving.
- The Wolfram license and this box are SHARED: never hold more than
  1 main kernel + 4 subkernels of ours (see House rules below).
- Consults with a fresh-context Fable ("Fable Max") are done manually:
  write a self-contained prompt, the user pastes it into a chat, the
  reply is saved beside the work it informs. A 2026-08-16 review this
  way corrected the hard-class route (see the eps-form README).

## Standing method rules (learned the hard way)

- **Mature packages first.** Survey and benchmark community tools before
  building anything custom; custom code only after measured inadequacy,
  and then archived as a certification reference.
- **A negative verdict needs evidence, like a positive one.** Before
  recording "X is impossible", verify the tool was run where success was
  admissible (CANONICA/Libra search RATIONAL transformations — a sqrt in
  the required transform dooms them silently) and that its API contract
  was honored (Libra's Rookie applies ONE balance per call). This cost
  the project days in August 2026.
- **Certification proportional to code age**: heavy exact certificates
  on our new code, spot checks for mature packages. Never pin a test to
  a defect's current symptom ("expected partial") except at a measured
  external capability boundary.
- **Test at cheap scale first**, always. Every long run emits per-item
  progress; a launch is not complete until its first output is checked.
- **Arm the watchdog in the same turn as the launch** and re-ask on
  every progress event whether the run's design is still justified.

## Key paths

- `FeynFacet/` — the package (`Private/<Layer>/` holds the modules, `Private/LoadOrder.wl` the load order, `Private_Backup/` retired code).
- `Tests/` + `run_tests.sh` — the suite; keep it green.
- `Scripts/` — campaign drivers (`KernelPool.wls` + `kpsubmit.sh`/
  `kpwait.sh`/`kpstatus.sh` = the persistent kernel pool every kernel
  job goes through; `HardClassToolkit.wl` with `HCTMissionPool` for
  in-script fan-out; the eps-form pipeline scripts `epsform_*.wls`;
  `EpsilonGraded.wl`).
- `Design/` — architecture and method records; start with
  `MasterSolvingArchitecture.md`, `HardClassToolkit.md`,
  `Stage3BoundaryToolchain.md`.
- `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/` — class forms,
  block classes, boundary periods, hard-class artifacts.
- `Archive/` — retired implementations kept as references.

## Layout

- `Exchange/Codex` and `Exchange/Fable`: dated exchanges with the parallel
  assistants, as exact source files and certificates.
- `Addon/Load`: FACET's repository-relative loader.
- `Addon/Mathematica_Addon`: third-party Wolfram Language packages.
- `Addon/Other_Addon`: non-Mathematica tools, currently Kira.
- `FeynFacet`: FACET's modular Wolfram Language package. `FeynFacet.m` is the
  public facade; focused files under `Private` own core exact algebra, process
  cards, topology and cut handling, dimensional shifts, collinear
  factorization, and Kira reduction.
- `Scripts`: campaign drivers (hard-class toolkit and kernel-pool helper,
  eps-form pipeline, eps-graded solver).
- `Design`: architecture and method records (master-solving architecture,
  hard-class toolkit, stage-3 boundary toolchain).
- `Tests` + `run_tests.sh`: the acceptance suite.
- `ppHX_NNLO_DoubleReal/Results`: class forms, block classes, boundary
  periods, hard-class artifacts.
- `Archive`: retired implementations kept as certification references.

Scratch work belongs in the session scratchpad, not in this tree; evidence
a reported result depends on must be moved into `Results/` first.

## Load

```wl
Get["/home/maxzhang/factorization-and-loops/Addon/Load/LoadFACET.wl"];
```

This resolves dependencies relative to this repository. It does not depend on
the old `Hard Function` or `Hard-pphX-Linux` directory after setup.

Third-party software remains subject to its own license and citation terms.
Those terms must be reviewed before publishing a redistributable release.

## Calculation boundary

`CollinearFactorizePreIBP` owns one diagram pair from generation through its
cut-aware, dimension-shifted `GLI` representation. Reduction is separate:
`KiraReduction` returns validated exact IBP rules and masters, while
`CoefficientSimplification` streams the pair results and constructs the
compact analytic master coefficients. This separation allows a Kira project
to be reused without retaining all unreduced pair expressions in memory.

The durable interfaces are Associations with versioned formats and analytic
contexts. They fail closed on missing BMHV, branch, cut, exactness, source, or
causal information. Physical cut metadata is never inferred back from a bare
Kira family.

## Topology equivalence

After partial fractions and `BuildTopologies`, compare all cut-aware family
records with

```wl
equivalence = TopologyEquivalence[Topologies];
```

The function accepts only complete unit-power families and exact rational
affine loop-momentum maps with unit Jacobian that preserve the complete
propagator permutation, stored eta signs, cut slots, cut energy directions,
kinematic rules, and AMFlow routing labels. It returns representatives,
equivalence classes, physical mapping metadata, and fresh `GLI` replacement
rules synthesized from the verified propagator permutation.

The result is deliberately conservative. `PhysicalCausalStatus` is `Verified`
only when every input record supplies per-propagator physical-role metadata;
otherwise the classes are certified for the cut-aware IBP representation.
`ConservativelySeparated` means a mapping proposed by FeynCalc failed a FACET
check. It does not prove that no other valid loop-momentum map exists.

# House rules

## Workspace

Scratch scripts, intermediate Kira projects, run state, logs, staging
files, and test output belong in the session scratchpad directory
(`/tmp/claude-*/.../scratchpad`), never in the repository tree. Evidence
that a result depends on — differential systems, transformations,
certificates, expected test values — must be MOVED INTO the repository
under the relevant `Results/.../` directory before that result is
reported as established; tests must locate it by repository-relative
paths. (A 2026-08-15 Codex review correctly refused results whose inputs
existed only under `/tmp`.)

**`~/FACET` is frozen and read-only for us.** It is the legacy tree and
the parallel assistant's workspace. Never write there. Our tree is
`~/factorization-and-loops`.

## Compute budget (shared machine, shared Wolfram license)

- **All kernel work goes through the persistent KernelPool**
  (`Scripts/KernelPool.wls`, since 2026-08-16): ONE main kernel of ours
  holding up to 8 subkernels (measured: the license accepts 8) with
  FeynFacet preloaded, watching a queue directory. Submit a script with
  `Scripts/kpsubmit.sh <name> <script.wls> [args]`, wait with
  `Scripts/kpwait.sh <name>`, read `<pool>/logs/<name>.log`, see
  `Scripts/kpstatus.sh`; cancel with `touch <pool>/control/<name>.cancel`;
  stop with `control/stop` (drain) or `control/stopnow`. Scripts ending
  in `Exit[code]` (TestKit) work — the code is captured. Missions run
  concurrently; the pool serializes nothing. Never launch a second main
  of ours while the pool runs; if the pool is down, start it (see
  `Design/KernelPool.md`). `HCTMissionPool` (static list) remains for
  in-script fan-out. Subkernels keep state between missions: don't rely
  on a clean Global` context; Clear large allocations.
- Total compute across our jobs <= 10 cores (`--parallel=10`,
  `--threads=10`, `taskset -c 0-9` to bring a running job under cap).
- Ownership is decided by `/proc/<pid>/cwd`, not by command line: ours
  run from the scratchpad or `~/factorization-and-loops`, the parallel
  assistant's from `~/FACET`. **Never kill by name pattern** —
  `pgrep`/`pkill -f` self-match has killed our own watchers and once
  killed the other assistant's kernel. Kill verified PIDs only.
- On license refusal: jittered 60-180 s backoff and retry; redirect
  output to files directly, never through `tee` chains that can die
  under the process.

## Production launches (rule of 2026-08-20; a batch was launched on
## inferred consent and the user had to kill it)

A production campaign — any multi-family batch, overnight run, or
launch consuming hours of shared compute — starts ONLY on the user's
explicit instruction given in response to a concrete proposal naming
the scope and cost. An old conditional approval, an unanswered
proposal, or the general autonomy mandate is NOT a go. Cheap-scale
probes and diagnostics within an assigned task remain autonomous.
Before any such launch, check the launch against the CURRENT written
plan: if steps ordered before it are still open, do not start it
without the user explicitly reordering. State, in the launch message:
the quoted go, the plan step it executes, and the expected cost.

## Long runs

**Watchdog (standardized 2026-08-22, `Design/Watchdog.md`): whenever
any compute of ours runs in the background, spawn ONE Opus watchdog
subagent in the same turn — first check immediately, then every 5
minutes, read-only, reporting only anomalies and drain. The prompt is
in `Design/Watchdog.md` (copy it verbatim); register outputs with
`Scripts/watchdog_register.sh`. A bash `Monitor` is not a substitute
(2026-08-22: a finished family left the driver idle for 10 minutes; a
pattern watch saw nothing wrong).**

Every long run emits per-item progress to a log, and its watchdog is
armed **in the same turn as the launch** (an 8-hour unmonitored
overnight run in August 2026 is the cautionary case). Check the first
output before reporting a run as healthy. Treat every progress event as
a decision point: if the evidence says the design is wrong (no
parallelism engaging, yield collapsing, cost estimate off by
multiples), stop and redesign rather than narrating "still going".

## Reporting language

Use precise terms. Call an executed calculation a `test` and report its
measured `result`. State the acceptance criterion before saying a test
passed; otherwise report observed values without `pass`. Use
`regression test` only for a repetition of a previously established test
after a code change. Never use `regression` as a generic synonym for
test, run, benchmark, or validation. Report numbers as measured or
estimated, explicitly.

## Verification

- **Check levels (user decision 2026-08-22):** checks are separate from
  the calculation. Production runs (`FACET_CHECK_LEVEL=Production`, the
  pool driver's default) keep only cheap guards inside the calculation —
  exact-rational evaluation at random points, the unseen-prime residual —
  and make ONE exact statement at the end, the family certificate
  (`CertifyFamilyEpsilonForm`); intermediate records then say
  "NumericalResidual"/"CandidateEpsilonForm", never "exact". The exact
  intermediate identities exist for development and tests
  (`Development`, the default outside the driver). Measured 2026-08-22:
  the exact identities were 70% of a family assembly and ~30% of a hard
  off-diagonal block.
- A stored transformation or result is "OK" only after an **exact**
  reconstruction check. Structural shape checks are never success
  criteria (CANONICA returns `{False, {partial}}` on failure, which is
  shape-identical to success).
- Numerics may guide derivations but never appear in a recorded proof
  chain; they enter a ledger entry only as the independent check.
- Never pin a test to a defect's current symptom, except at a measured
  external-tool capability boundary. Our own unfinished work stays red.

## Mathematica notebook safety

Never save or rewrite a `.nb` through a hidden or offscreen FrontEnd,
and never run a headless FrontEnd while a visible Wolfram FrontEnd is
open. This can persist `Visible -> False`, oversized `WindowSize`, and
negative `WindowMargins`, breaking mouse hit testing and cell selection.

Treat every notebook save as a high-risk operation. Package, script, and
test changes must never resave an open `.nb` as a side effect. Do not
use `NotebookSave`, `NotebookPut`, notebook `Export`, or a
programmatically launched FrontEnd unless the user explicitly requested
a notebook edit.

For every requested notebook edit:

1. Back up the exact on-disk notebook first.
2. Close every FrontEnd that has the notebook open before changing it.
3. Modify only the requested cells or options; never regenerate.
4. Persist a bounded `WindowSize`, nonnegative `WindowMargins`,
   `ShowCellBracket -> True`, and no `Visible` option.
5. Do not reopen a Linux notebook from an automated FrontEnd command;
   that path can evaluate initialization cells and rewrite outputs on
   exit. Leave it closed for the user to open normally.
6. Re-read the on-disk file and verify the required options before
   completion.

Never automate notebook-window clicks, `Alt+F4`, or save-dialog
responses. If an automated launch occurs accidentally, restore the
pre-launch backup rather than retaining any FrontEnd-generated rewrite.

## Wolfram traps this repository has paid for

Regulator symbols differ per package (`eps`, `ep`, `Epsilon`,
`CANONICA\`eps`) — normalize by `SymbolName` at every boundary, never by
symbol identity; in particular after `ValidateCanonicalForm` (loads
CANONICA) a later `Get` reads bare `eps`/`x`/`y` as `CANONICA\`` symbols.
Libra `Projector` returns a ZERO matrix on Wolfram 14.2 unless
`Off[OptionValue::optnf]` is set (its internal `Check` treats a benign
`OInverse` option message as failure; `Quiet` does not help) — a
"Libra found no balance" verdict without that `Off` is void; Libra
`Fuchsify` only walks off-diagonal blocks (no-op on an irreducible
block). `Return` inside `Do` discards results. `Module`
initializers are not sequentially scoped. Self-assignment `v = Global\`v`
poisons iteration limits. `Missing[] =!= None` in both directions.
`Put` is not atomic — write to a temp file and `RenameFile`. `Together`
rationalizes square-root denominators and destroys algebraic-letter
words. `Lookup[{}, key, default]` returns the DEFAULT — an empty list is
a valid (empty) rule list, so `Lookup` on a possibly-empty container
silently yields the fallback (e.g. `None`) where the code expected the
empty collection; check the container's head before `Lookup` (paid for
2026-08-26: a `None` fed to `Counts` broke the dispatch terminal-status
path). Packages dump symbols into `Global\`` (asy ~200 of them, plus a
bare `x`; SubTropica exports `line`; PolyLogTools 1699 symbols).
**FeynCalc creates `FeynCalc`Names`, and LoadFACET leaves `FeynCalc`` ahead
of `System`` on `$ContextPath`: in any script parsed after loading, a bare
`Names[...]` binds to that empty shadow and stays unevaluated (measured
2026-09-02 on five of eight pool subkernels). Write `System`Names` in
tests, mission scripts and pool code; package bodies under `BeginPackage`
are not affected.**

## Shell trap (found 2026-08-24 by the campaign watchdog)

Libra's Fermat banner writes a raw 0xA9 byte into solve logs. The
Claude Code shell's `grep` is a function dispatching to ugrep with
`-I`, which silently SKIPS such binary-classified streams — zero
matches, exit 1, indistinguishable from a genuinely empty result. Any
manual grep of Wolfram solve logs must use `command grep -a` (or
python); watchdog loops must install `grep(){ command grep -a "$@"; }`.
