# Status, 2026-09-06

## Numerical evaluator speedups

The general FLINT evaluator reduces the matched CF259 evaluation from 53.4
to 8.0 seconds, plus 4.1 seconds of reusable preparation, at 30-digit goals.
Eight hard-family tasks take 18.1 seconds on eight workers versus 76.4
seconds on one. Optional explicit Taylor expansions evaluate 128 nearby
line points in about 0.4–1.6 seconds after 2.8–25 seconds of setup.
Finite epsilon-state closure, missing center data, numerical error and
recentring are checked. The original 91 symbolic solutions are unchanged.
[The implementation and timing report](Design/NumericalEvaluationSpeedups_2026-09-06.md)
records the general APIs, tested scope and remaining continuation/physical-boundary work.

## Numerical evaluation and AMFlow comparisons

The standalone evaluator now checks quadrature resolution, subdivision and
working precision, including cancellations after numerical boundary values
are substituted. It preserves integer master/constant labels and rejects
missing or insufficient-accuracy boundary data.

CF269 and CF259 pass independent AMFlow local-series DE comparisons at a
10^-30 tolerance. The saved physical CF3 comparison passes at 10^-18, but
its boundary, reference and transported coefficients are all zero at the
tested orders; it is a zero-value control. Nonzero physical AMFlow transport
validation remains open. These are selected-system checks, not a numerical audit of all 91
families. Full analytic continuation is not implemented by the evaluator.
[The numerical evaluation report](Design/NumericalMasterIntegralEvaluation_2026-09-06.md)
documents the general code, timings, source data and limitations.

## All-family DE and finite-solution regeneration complete

All 91 families now have fresh closed DEs and complete finite solutions for
the current coefficient-table demands: 345 requested masters, 2,220 explicit
coefficients, 79.1 MB compressed. The full run took 31.2 minutes elapsed on the
shared eight-core allocation, including failed attempts and recovery.
[The full report](Design/Stage1And2FullCampaign_2026-09-06.md) identifies the
general drivers, code changes, data, timing scope and remaining work.

The first pass completed 80 finite solutions; a general nonlinear-divisor
pole-support correction resolved the remaining eleven. Earlier general
changes add consistent elementary-function expressions and verified
cyclic-vector reconstruction. All 91 stored solutions passed the final
explicit-result and transported-order coverage audit.

Upper-only requests derive lower output cutoffs from the complete evolution
and the declared boundary Laurent class. Ordinary-point bounds are not used
alone as output bounds. Existing finite evolution can supply missing lower
output coefficients without reintegration. Equal mathematical inputs resume;
changed or invalid inputs preserve completed data.

Physical boundary values, continuation beyond the ordinary domains and final
endpoint/renormalization/PDF order requirements remain separate work.
Complete strict epsilon-form canonicalization of every family is not claimed.
The following dated sections retain earlier milestones and timing comparisons.

## Stage 1 costs and epsilon-form criteria

The [2026-09-06 record](Design/Stage1CostsAndEpsilonFormCriteria_2026-09-06.md)
documents the current general-code changes and the mathematical audit.
Production assembly preserves explicit algebraic products and the sector
driver now propagates its declared check level. CF259 initial assembly fell
from about 206 seconds to 16.81 seconds. Completing sectors 1–12 fell from
470 to 82 seconds; their transformations agree exactly and their connections
agree at rational points. These timings do not cover full canonicalization.

A controlled three-independent-root integrability screen fell from 1.063 to
0.743 seconds with unchanged ranks. Scalar values and derivatives are reused,
and optional per-letter rank diagnostics are disabled by default in the driver.
Exact zero transformations now retain the representation required by the
normal modular DE residual instead of failing prime reconstruction.

Sampled fixed-target inconsistencies are explicitly distinguished from
characteristic-zero and arbitrary-basis nonexistence results. The integrability
screen checks that supplied target forms are closed. The rational expansion
diagnostic no longer mistakes distinct constant residues on geometric
components for a varying residue, and no longer labels integration failure
as proof of nonexistence. It is opt-in and respects the remaining block time.
Kinematic support certification now requires epsilon-independent diagonal
coefficients. Historical CF303 arbitrary-basis claims have visible corrections;
the retained successful CF300 (12,9) result remains positive evidence for
that block only.

The final fresh CF259 profile completed sectors 1–17 and stopped on (18,13)
when its 600-second family allowance expired. The sampled support there was
consistent; this is a budget stop. Full CF259 canonicalization and the
all-family regeneration remain unfinished. There are 213 passing focused
checks, with separate numerical comparisons of the complete initial assembly
and the first twelve sectors.


## Stage 1/2 speedups implemented

The [optimization record](Design/Stage1And2Speedups_2026-09-05.md) includes
matched timings, preserved pre-change source, and numerical comparisons.
Stage 1 reuses interpolation matrices and regular samples, batches numerator
right-hand sides, and eliminates numerator unknowns from sufficiently large
common-denominator systems with a Schur complement. A two-entry CF48
source-coordinate reconstruction fell from 39.1 to 24.3 seconds with the same
exact result. This excludes the chart solve and is not a full triple-root
family timing.

Stage 2 shares scalar coefficient expressions before path substitution,
checks linear dependence on boundary constants structurally, and reuses
epsilon-polynomial expansions and basis derivatives. CF48 construction plus
writing fell from 62.9 to 18.6 seconds; CF303 from 236.9 to 190.5 seconds.
The slower coefficient-abstraction and exact-point zero-test experiments
were removed. Mathematical order determination retains its existing
symbolic checks.

All five saved finite solutions were regenerated: 998 explicit coefficients,
17.11 MB combined, 379.51 seconds construction plus 8.24 seconds writing.
Their order requirements and final coefficient formulas agree exactly with
the previous results. Every defining integrand agrees at two rational points
using 65-digit arithmetic. There are 236 passing Wolfram assertions/checks
and three passing Python execution tests.

Runs used a common allocation of eight CPU cores. The family batch driver
remains sequential; all-family timed stage-1/2 regeneration has not started.
The unresolved canonicalization ansatzes, including CF259 (27,19), remain
mathematical work separate from these speedups.

## Earlier requested-range construction (before the speedups)

`ConstructMasterIntegralSolution` now accepts
`RequestedMasterIntegralOrderRanges` and completes the sequence from defining
integrals through derived pole bounds, shared ordinary-point normalization,
entrywise epsilon requirements, finite integration and explicit coefficients
in kinematics-independent C[j,m]. Unknown bounds stop construction; supplied
assumptions remain labelled conditional. Unneeded U entries are marked
uncomputed and never silently replaced by zero.

The general `solve_master_integral_families.wls` driver now handles all five
currently regenerated V2 systems. CF269, CF48, CF265, CF259 and CF303 contain
998 explicit requested master coefficients over 174 coupled-system master
positions. The complete compressed solutions total 36.28 MB; construction
took 453.25 seconds using the available forms/recurrence, including automatic
preparation for CF265/CF259. Full canonical forms are unnecessary for these
finite solutions. The driver reuses exact saved inputs, refuses changed
requests in an existing directory, and continues independent families after
an unresolved result.

The standalone reader loads either the complete compressed expression or
the explicit text definitions, without loading a DE solver. A CF269
off-base-point quadrature comparison agreed to 1.62e-38. The final constants
remain unevaluated.

Automatic point selection checks ordinary DE/basis conditions, a supplied
region and supported physical cut conditions. It now uses the correct
coefficient variables after rationalizing coordinate changes. CF48 chooses
(1/6,1/4), or source (v,w)=(5/12,1/6). The point is shared by the coupled
system, pole bounds and solution. A saved recurrence can supply it.
Boundary-evaluation cost and numerical conditioning are not optimized.

Independent real/virtual integrations now factor automatically from their
denominator/numerator dependencies, retaining the AMFlow measure. Their
Laurent bounds add and they use the same finite-solution interface.
A numerator coupling the integrations prevents false factorization.

The focused order/representation/finite-solution and package-generality tests
pass: 266 Wolfram assertions, including 27 new workflow assertions, plus three
batch-execution tests. All 157 exported symbols retain their usage messages. The new tests cover
explicit coefficient convolutions, uncomputed-entry semantics, coordinate
substitution, independent/coupled real-virtual cases, compressed/text reading,
input reuse, changed-input refusal and failure continuation.

At that earlier point, the outstanding pre-stage-3 work was (the all-family regeneration is now complete):
- Regenerate the DE inputs for the other 86 of 91 canonical families in the
  current 347-entry (345 nonzero) coefficient inventory. The 174 positions
  above include lower sectors and are not 174 unique canonical masters.
- Derive final requested master ranges from the complete endpoint,
  renormalization and factorization calculation. The stored demonstration
  ranges do not claim observable NNLO coverage.
- Extend supported integral definitions/bounds for coupled real/virtual
  integrations and unresolved domains, and supply/find explicit homogeneous
  solutions for any blocks beyond the current preparation methods.

Physical boundary values, matching to singular constants and global
continuation remain separate work; they are not unknown kinematic functions
inside the completed ordinary-point solutions.
See [the general interface](Design/FiniteMasterIntegralSolutions.md),
[the saved solutions](ppHX_NNLO_DoubleReal/Results/RequestedMasterIntegralSolutions/README.md)
and [the family inventory](Design/FiniteMasterIntegralSolutions_sources/family_input_inventory.json).

The following sections retain earlier completed steps and historical timings.

## Cut-integral Laurent bounds and dimensional recurrences (2026-09-05)

The 22 outstanding CF269 cut-master bounds are now established. The general
code first uses a cheap compact-semialgebraic pole-multiplicity bound, with
mass-deformed causal certificates that justify repeated cuts. An optional
rational dimensional recurrence provides tighter bounds. No master values
or global DE solution are used.

`ConstructMasterIntegralDimensionalRecurrence` builds the Gram insertions,
runs Kira at a rational point with D symbolic, converts the reducer's basis
to the requested complete basis, and stores both recurrence matrices.
`DetermineLaurentBoundsFromDimensionalRecurrence` uses eventual holomorphy
and the finite downward product. The order planner can construct these
recurrences for several families or reuse supplied records.

For all 23 CF269 masters at (1/4,1/3), the refined bounds are at worst -3,
and two masters are holomorphic. Targets through epsilon^0 require prepared
evolution through epsilon^4 and heterogeneous boundary orders through at most
epsilon^3. There are no assumed Laurent bounds in the result.
The fresh public-constructor Kira run took 144.47 seconds; all 1,028 targets
were reduced. Recurrence, bounds and complete order records total about 1.1 MB
in compressed WXF and round-trip exactly.

The 33 new assertions, 37 representation assertions and 50 existing
master-expansion assertions pass. They include exact phase-volume shifts,
rational inverse checks, repeated-cut derivatives, input/cache mismatches,
several-family construction and an interior-resonance rejection. The 51 sufficient-order and 43 finite-solution assertions, 25 package-generality
assertions and public-usage check also pass. The stored recurrence is reused
in tests; they do not repeat the Kira reduction.

This closes the cut-bound gap for the supported compact pure-phase-space
integrals, not the full NNLO calculation. Coupled real/virtual conversion,
the final observable's endpoint/renormalization/factorization demands and
all-family solution regeneration remain outstanding. See
[the method](Design/CutIntegralLaurentBounds.md) and
[the complete stored example](ppHX_NNLO_DoubleReal/Results/EpsilonOrderDetermination/CF269/README.md).

## Automatic integral representations (2026-09-05)

`ConstructMasterIntegralRepresentations` now derives representations from
topology data and GLI indices. The momentum-space convention is explicitly
AMFlow's: normalized virtual loop measures and standard cut phase space.
This constructs the defining integrals; it does not choose a new master basis
or DE boundary normalization.

The order planner invokes construction automatically. Ordinary scalar and
numerator integrals use FeynCalc's parameter integrand and Gamma factors.
Pure phase-space integrals receive a Baikov Gram polynomial, Jacobian, complete
energy/Gram domain and signed delta derivatives for repeated cuts. The family
Gram construction is reused across all master exponent vectors.

All 23 CF269 definitions are now constructed from saved references in about
0.94 seconds: 22 cut Baikov integrals and one explicit inclusive volume.
All 23 now have derived sufficient bounds, using the cut-integral methods
below. Coupled real/virtual parameter conversion remains unfinished; independent
factors are supported by the current workflow above.

The focused 37 assertions and existing 50 expansion-order assertions pass.
They include independent phase-space normalizations, normal derivatives and
a numerical numerator-integral identity. The two-loop executable example
now supplies momentum-space propagators without hand-written U, F or prefactors.
See [the construction and remaining scope](Design/MasterIntegralRepresentations.md).


## Boundary normalization through expansion orders

`DetermineMasterIntegralExpansionOrders` now connects the full sequence:
fixed ordinary/Frobenius normalization, independently derived integral pole
bounds, finite local matching bounds, and separate epsilon orders for evolution,
matching and boundary coefficients. It performs no global evolution or
boundary-value evaluation.

Normalized parameter integrals can now be resolved automatically into sectors.
Scalar Feynman-parameter inputs generate primary sectors and their Gamma
normalization. A two-loop example derives a double pole and requests evolution
through order 2 and boundary coefficients through order 0, in about 0.032 seconds.
Its updated complete result is about 12 KB. No pole order or integral value is supplied.

The prepared DE basis is the default local normalization. An explicit resonant
normalization is also supported; tests show the extra boundary precision it
requires. Local residue-exponential and Frobenius-series orders are included,
not just the direct local DE recurrence.

The 50 new assertions pass, along with the existing 51 order assertions,
43 finite-solution assertions and the usage/generality regressions.
See [the workflow](Design/MasterIntegralExpansionOrders.md) and
[the executable two-loop example](Examples/Transport/master_integral_expansion_orders.wl).

Actual cut-master identifiers now receive normalized cut representations
automatically, as described above, including all 23 CF269 Laurent bounds. The automatic
sector resolver covers its documented parameter domains; unresolved interior
singularities and resolution limits return an explicit failure.

## Sufficient epsilon orders: general implementation

The two Pro reviews are implemented in `FeynFacet/Private/Transport/Orders/`.
The package derives Laurent bounds from normalized resolved integral
representations, propagates requirements through the declared calculation,
distinguishes bulk/face/corner orders, computes scalar and matrix endpoint
moments, and bounds local Frobenius matching poles under uniform Fuchsian
hypotheses. Unknown bounds and supplied assumptions remain explicit.
No master evaluation or AMFlow run is needed for order determination.

The finite DE constructor closes entrywise requirements through the prepared
connection and skips unnecessary finite integrals. A full CF269 exercise at
the existing U range reduced definitions from 1194 to 905, with the same
requested original-basis coefficients. Construction took 2.22 seconds;
exact finite-integral identities and sampled source/basis checks passed.
Production exports below have not been replaced by this scratch comparison.

The generic 347-entry coefficient-table adapter produces 345 preliminary
nonzero-column demands and reports their missing integral lower bounds.
Endpoint integration, renormalization and mass factorization must be
represented before this becomes a final NNLO order table. Those operations
are not inferred from the NNLO label.

The new focused tests contain 51 passing assertions; all 43 finite-solution
assertions pass. Order-requirement, usage, package-generality and renamed-variable
regressions pass. See [the executable API example](Examples/Transport/README.md)
and [the mathematical derivation](Design/EpsilonOrderDetermination.md).

## Finite DE solutions up to initial constants (2026-09-05)

The package now has general code for exact finite-order solutions
I(X,epsilon)=U(X,X0;epsilon) C(epsilon), with all C independent of every
kinematic variable. It includes epsilon rescaling, a common nilpotent flag
when diagonal rescaling is insufficient, explicit zero-order block
reduction, and both original-basis epsilon convolutions. The stored answer
contains every finite nested-integral definition and explicit coefficient;
no lazy coefficient generator is used by the reader.

CF269 and CF48 have all-row/all-column exports at U orders -3 through 4.
Both passed exact coefficient identities. CF48 also passed the independent
original reduction-derived DE identity after coordinate pullback. CF269
passed an independent off-base-point quadrature/PDE spot check.

CF303's full 45-master two-variable DE was rebuilt from preserved Kira
inputs and passed exact flatness. Every epsilon-zero block has an explicit
reduction verified in both coordinates. Its complete reusable preparation
is saved, and all rows/columns of U at epsilon orders -2 through 4 are now
exported (transformed orders 0 through 6). Every stored finite-integral
identity passed an exact check after normalizing algebraically zero kernel
entries; kernel pullbacks and original input gauges passed sampled checks.
The standalone reader evaluated all coefficients at an off-base point;
12- versus 20-node quadrature differed by at most 3.32e-42. No DE solver
was loaded. The full text export is about 177 MB and its compressed
archive is about 6.5 MB.
The old missing
fixed-rho path-operator inputs no longer obstruct this construction.

Production checks must remain a small part of computation. Sampled
80-digit checks at three rational points are now the default; expensive
generic symbolic checks and a second coefficient-verification pass are
optional. Sampled evidence is explicitly distinguished from symbolic proof.
AMFlow comparison remains the eventual independent validation of physically
normalized masters once their boundary constants are available.

The focused nine-file regression run passed, including 43 finite-solution
assertions, epsilon-order requirements, boundary intermediates, artifact
reading, usage declarations, package generality and renamed variables.

See [the mathematical scope and interface](Design/FiniteMasterIntegralSolutions.md).
Physical Laurent-order demands, boundary constants, global continuation,
and regeneration of every family remain separate unfinished work.


Rewritten at every change of state; the detailed goal ledger is under
`Goals/<agent>/<date>/STATUS.md`.

- Data: the V2 record schema is live. Pre-V2 results remain under
  `Stale/DifferentialEquationData/2026-09-03_pre_v2/`; regeneration uses the
  preserved Kira streams, family registry, master lists, hard-function
  coefficient valuations and cards. Historical canonicalization and
  path-solution timings are retained in
  `Design/PerformanceBaselines_2026-09-04.md`.
- Stage 1, epsilon forms: finite-field diagonal- and off-diagonal-block
  solvers are the production route; CANONICA and Maple are not production
  fallbacks. The V2 finite-field and square-root terminology migration is
  complete, and all 44 changed test files pass. CF269, CF48, CF265 and CF259
  differential systems were regenerated and exactly match their archived
  systems. CF48's family dlog epsilon form is validated. CF259's measured
  hard blocks are substantially faster, but its complete V2 multiquadratic
  family-level record remains unfinished.
- Stage 2, DE solutions up to constants: all 91 current families have fresh
  V2 DEs and complete finite exports at the derived pre-endpoint
  coefficient-table orders. The older five-family demonstration exports are
  retained separately. Physical boundary values and final endpoint,
  renormalization and PDF order requirements remain unfinished.
  Positive-dimensional soft-boundary functions belong to determining/matching
  the physical constants; they are not unknown functions inside the completed
  ordinary-point solutions.
- Stage 3, boundary data: three structural boundary constants are proven zero
  (ids 1, 6 and 7); the remaining required constants or boundary functions
  are unevaluated.
- Stage 4, marked-point expansion and hard-function assembly: not started.
- Validation: production uses finite-field or high-precision sampling at
  independent points. Generic symbolic proof is optional; verification
  should not dominate the computation. The repository-wide inventory retains two
  unrelated pre-existing failures: the ghost pre-IBP test and the test that
  requests archived pre-V2 class-form inputs.
- Coordination: the GPT Pro bridge now lives in `External/ChatGPT`; its
  tracked `gpt-6-pro` conversation state lives in the ignored
  `Codex/General/ChatGPT` runtime directory. Permanent exchanges and their
  supporting source packets are organized chronologically under
  `External/ChatGPT/Records/YYYY-MM-DD/NN_summary_name.md`, with the question
  and Pro response in the same numbered file. The bridge and
  state were moved from FACET into this workspace.
- Terminology: live interfaces now distinguish graph blocks from differential
  irreducibility, integration-kernel coefficients from pole residues,
  epsilon-normalized residues from full residues, and generator counts from
  matrix ranks. Singular-point matching and basis-transformation valuations
  use explicit mathematical names. The unsupported K3 and p-adic claims were
  removed. See `Design/MathematicalTerminology.md`. Validation: 29 Wolfram
  test files and 5 Python test files passed; six saved-record conversions
  and their overwrite refusals passed. Saved numerical results were not
  rewritten; the explicit converter produces new copies without promoting
  historical records or claiming new mathematical validation.
- Next work: evaluate/match physical boundary constants and establish final
  endpoint, renormalization and PDF order demands; use the general family
  driver if those require additional coefficients. Extend unsupported
  coupled-integral bounds and homogeneous-block solutions when a new process
  needs them. The present all-91-family raw-DE and finite-solution calculation
  is complete within its declared coefficient-table scope.
