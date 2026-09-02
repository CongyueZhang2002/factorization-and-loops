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
