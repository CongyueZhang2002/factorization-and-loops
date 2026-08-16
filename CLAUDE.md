# FeynFacet / factorization-and-loops — session startup context

Read this first. It is the authoritative orientation for any new agent
session; `AGENTS.md` holds house rules, `WORKLOG.md` the running record,
`TODO.md` the rewrite plan. Anything under `~/FACET` is a FROZEN
reference tree — never write there (see "Two-assistant setup").

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
normalized symbolically in (x,y); 97 and 77 have slice eps-forms at 10
y-points; 79 is blocked by integer offsets on an irreducible quadratic
locus.

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
  1 main kernel + 4 subkernels of ours (see AGENTS.md).
- Consults with a fresh-context Fable ("Fable Max") are standardized in
  `External/FableBridge/` — subagent transport for routine questions,
  manual chat paste for strategic reviews.

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
