# factorization-and-loops (FeynFacet)

Production tree for the FeynFacet package: collinear factorization and the
NNLO hard function for pp -> h+X. **New agent sessions: read this file end to end before acting.** It is the
only orientation document: workflow, current frontier, and house rules.

The legacy tree `~/FACET` is frozen reference material and the parallel
assistant's workspace — never write there.

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
tests `Tests/t_canonical_blocks.wls`). Decompose each family's DE system
into strongly connected blocks (1119 of them), classify blocks into 173
equivalence classes (equivalence = basis permutation, optionally
composed with v<->w, as an exact rational matrix identity), and put each
class into **eps-form**: dF = eps (sum_a R_a dlog phi_a) F with constant
residues R_a. Acceptance is always an exact reconstruction check, never
a structural shape check.
Status: 170/173 classes have validated eps-forms. The last three
(97 = CF258_B9, 77 = CF230_B1, 79 = CF231_B1) are the current frontier —
see `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/HardClasses/`.

**Stage 2 — transport** (`FeynFacet/Private/MasterTransport.wl`, tests
`Tests/t_master_transport.wls`). Given eps-forms, solve family by family:
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

## Current frontier: the last three classes

Entry point: `Results/UU_08_10_canonical/HardClasses/EpsFormRoute/README.md`
(method, per-class state, ordered next steps). One-paragraph version:

All three are order-4 irreducible at generic eps (certified), which does
NOT preclude an eps-form. Their eps=0 operators factor completely, which
gave a first route (eps-graded recursion, `Scripts/EpsilonGraded.wl`,
certified solutions through eps^3/eps^2 — now the VERIFICATION track).
The production route is the eps-form found on 2026-08-16: rationalizing
chart -> Fuchsify -> two-point Lee balances -> CANONICA. Class 97 is
normalized symbolically in (x,y) (flat, integrability verified) and its
normalized family factorizes at 12/12 sampled y values; what remains is
the eps-factorizing gauge with y symbolic — a two-variable CANONICA run
was progressing when the session ended and is the first thing to
restart. Class 77 has slice eps-forms at 10 y-points and follows the
same template. Class 79 is blocked by integer offsets on an irreducible
quadratic locus (mechanism question written up, unanswered).

Do NOT try to lift the gauge by interpolating independent slice
transforms: the canonical transform is fixed only up to an
EPS-DEPENDENT constant matrix, so slices are incomparable, and
normalizing them at a reference point destroys the eps-form. This is
measured and recorded, with four alternatives, in the route README.

## Two-assistant setup (important)

The user runs **two assistants in parallel on the same physics**: this
one (Claude/Fable, in `~/factorization-and-loops`) and **Codex**
(OpenAI, in `~/FACET`). This is deliberate: independent methods, then
cross-checked results. Rules:
- **Never write into `~/FACET`** — read-only reference, Codex's tree.
- Exchange goes through `External/CodexExchange/` as exact source files
  and certificates, not prose summaries.
- Codex's assessments of our work are valuable and have repeatedly been
  right; read `External/CodexExchange/codex_*` before re-deriving.
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

- `FeynFacet/` — the package (`Private/` holds the stage modules).
- `Tests/` + `run_tests.sh` — the suite; keep it green.
- `Scripts/` — campaign drivers (`HardClassToolkit.wl` with
  `HCTMissionPool` for 1-main+4-subkernel pools; the eps-form pipeline
  scripts; `EpsilonGraded.wl`).
- `Design/` — architecture and method records; start with
  `MasterSolvingArchitecture.md`, `HardClassToolkit.md`,
  `Stage3BoundaryToolchain.md`.
- `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/` — class forms,
  block classes, boundary periods, hard-class artifacts.
- `Archive/` — retired implementations kept as references.

## Layout

- `External/CodexExchange`: exchange with the parallel assistant (Codex),
  as exact source files and certificates.
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

- Never hold more than **1 main kernel + 4 subkernels** of ours. The
  license refuses a second main while 4 subkernels are seated, so the
  pool topology (`HCTMissionPool` in `Scripts/HardClassToolkit.wl`) is
  strictly better than several serial mains: submit all missions, let
  `WaitNext` hand each finished subkernel the next one.
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

## Long runs

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
symbol identity. `Return` inside `Do` discards results. `Module`
initializers are not sequentially scoped. Self-assignment `v = Global\`v`
poisons iteration limits. `Missing[] =!= None` in both directions.
`Put` is not atomic — write to a temp file and `RenameFile`. `Together`
rationalizes square-root denominators and destroys algebraic-letter
words. Packages dump symbols into `Global\`` (asy ~200 of them, plus a
bare `x`; SubTropica exports `line`; PolyLogTools 1699 symbols).
