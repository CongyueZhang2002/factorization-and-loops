# FeynFacet package

FeynFacet is a general framework for NNLO calculations. Process-specific cards,
family assignments and computed results live outside this package.

## Entry points

- `FeynFacet.m` loads symbolic construction, order determination and finite
  solutions. In this installation, `Addon/Load/LoadFACET.wl` loads it together
  with FeynCalc and the physical conventions.
- `Solution.m` reads and evaluates saved solutions independently. It loads no
  FeynCalc, diagrams, reduction or epsilon-form algorithms.
- `EpsilonForm.m` explicitly adds optional epsilon-form transformations to the
  symbolic package. It preserves the existing solver state.
- `Kernel/init.m` supplies the conventional Wolfram package initialization path.

Use `Get` for an intentional reload. Reloading the symbolic entry resets its
private state and registered rationalizing maps; load `EpsilonForm.m` again if
needed. Parallel helpers inherit the explicitly loaded optional entry files. Each entry
checks its own required sources when loading.
The public mathematical symbols retain the `FeynFacet` and
`FeynFacetSolution` contexts used by saved results.

For physical coefficient contraction, sufficient endpoint orders, and
delta/plus/regular output with color decomposition, see the
[coefficient assembly drivers](../Scripts/Coefficients/README.md).

For independent diagram interferences and the explicitly scoped ordinary-i0
certificate, see [the implementation notes](../Design/HermitianInterferencesAndPrescriptions.md).
The production pair queue uses Hermitian reduction automatically when eligible.
`Integrals/Convergence.wl` owns one compact-cut convergence certificate, shared
by ordinary-prescription removal, Laurent bounds and dimensional recurrences.
It handles unit and repeated positive-energy cuts by the same independent
nonnegative cut-mass deformation. Scope remains explicit for endpoint work.

## Ownership

| Directory | Responsibility |
|---|---|
| `Kernel` | Explicit module manifest, loading, public declarations, syntax and display formatting |
| `Core` | Installation and execution support, generic record I/O, parallel task support |
| `Algebra` | Exact/modular arithmetic, coefficient-field presentations, radicals and multiquadratic arithmetic |
| `Geometry` | Rational coordinate maps, mathematical catalog data and supplied family root data |
| `Integrals` | Integral/topology definitions, linear combinations, parameter representations, dimensional shifts and integral pole bounds |
| `Physics` | Kinematics, collinear distributions and factorization |
| `Projects` | Root/contribution cards, physical-leg polarization, explicit lower-order dependencies and calculation orchestration |
| `Reduction` | IBP reduction, streamed reduction records and canonical family registry |
| `Coefficients` | Physical coefficient normalization, finite-field reconstruction, hard-function assembly and endpoint demands |
| `DifferentialEquations` | System assembly, coordinate/basis transformations, local analysis and optional epsilon form |
| `Boundary` | Physical boundary conditions, matching and boundary-function systems |
| `Solutions` | Shared representation, finite construction, preparation, validation, reading, order planning and solution-to-GPL conversion |
| `Functions` | Generic Chen/GPL mathematics, independent of a particular solution |
| `Numerics` | Evaluation algorithms, accuracy control, Taylor expansions, batches and their FLINT/GiNaC invocation |
| `Interfaces` | AMFlow, Libra and optional SubTropica translation/invocation |
| `Backends` | Native computation, protocol documentation and build scripts |
| `Tools` | Small package execution helpers |

`DifferentialEquations/EpsilonForm` contains `Blocks`, `Rational`,
`Multiquadratic` and `Assembly`. It is optional in the ordinary finite-solution
route. Exact FLINT code used by canonicalization remains in `Backends/flint`;
the directory also contains the separately built numerical integration programs.

The tree expresses ownership. It does not claim that every existing function
call follows a strict layered graph. `Kernel/Modules.wl` is the only load
manifest: files are listed explicitly, and an unlisted source file fails the
layout audit. Module lookup uses the full path relative to this package, so
different domains can use ordinary filenames such as `Validation.wl`.

## Adding mathematics

**A new rationalizing formula.** Add a supported formula to
`Geometry/Rationalization/Catalog.wl` or call
`RegisterRationalizingParametrizations[<|"Name" -> entry|>]`.
Entries contain source/target variables, the forward substitution and rational
root images. Registration verifies every entry before changing the catalog;
invalid entries and conflicting names change nothing. Verification establishes
the stated rational map and identities, not an inverse or a nonexistence result.
The generic verifier and DE pullback algorithms need no edit for a new formula.

**A new coefficient field.** Put its arithmetic and normal forms in `Algebra`.
Do not extend multiquadratic masks to represent an unrelated algebraic field.
A new field needs the actual substitution/reduction operations its callers use.

**A new geometric method.** Put coordinate or curve operations in `Geometry`.
Applying the resulting map to a DE belongs in
`DifferentialEquations/Transformations`. Domains, chosen sheets and base-point
values remain explicit data; algebraic relations alone do not choose a branch.
New geometry can require new algorithms; catalog registration promises support
only for existing rational-map operations.

**A new function representation.** Put generic identities/integration in
`Functions`, conversion of the stored solution in `Solutions`, and evaluation in
`Numerics`. Keep the explicit finite solution representation usable independently.
A future elliptic-function implementation need not modify the GPL algorithms.

**A new pole-bound method.** Implement it beside the method:
`Integrals/PoleBounds` or `DifferentialEquations/LocalAnalysis`.
`Solutions/Orders` consumes bounds and propagates sufficient orders. Preserve
unknown/inconclusive results explicitly.

**A new external implementation.** Keep native code and protocols in `Backends`.
Keep the Wolfram translation with its existing domain or in `Interfaces` when
it is genuinely a shared vendor interface. Measurements belong under
`Tests/Benchmarks` and never run during loading.

Core declarations live in `Kernel/Exports.wl`; domain additions declare usage
alongside their public implementation. Add the implementation path to
the relevant manifest profile and extend the existing behavioral tests.
`Solutions/Representation.wl` owns the common stored-expression head conventions
used by both the constructor and reader.

## Checks and retained history

Run `python3 Scripts/check_package_layout.py` from the repository.
`Tests/Core/t_package_entry_points.wls` checks independent reading, finite
solving without epsilon form, explicit optional loading, actual `Get` reload,
and valid/invalid catalog additions.

Retired code is in `Archive/RetiredCode/FeynFacet` outside the active package.
Experimental native postfix implementations and their benchmark drivers are
under `Tests/Benchmarks/NativePostfix`. The distributions reference PDF is under
`LectureNotes`. Process results and their mathematical symbols were preserved.


Boundary reduction uses `Reduction/CutEquivalence.wl` for exact powered-integral
identities and `DifferentialEquations/GlobalSystem.wl` for the shared DE and
requested derivative closure. `Boundary/Reduction.wl` substitutes shared
constants into finite solutions; `Boundary/LocalLimits.wl` handles general
regular-singular block spectra and physical dimension bounds. The
three-particle phase-space geometry and elementary values are isolated in
`Integrals/Asymptotics/PhaseSpace.wl` and `Integrals/Evaluations/PhaseSpace.wl`.
See [the method](../Design/GlobalBoundaryReduction_2026-09-06.md).


The Boundary modules own explicit singular-to-ordinary matching.
Regular-singular normalization belongs to DifferentialEquations/LocalAnalysis,
Laurent-lattice saturation to Algebra, physical selection and connection/order
application to Boundary, and shared finite reading to Solutions.
Boundary/Preparation.wl provides the general orchestration interface.
The reader does not depend on the symbolic Frobenius constructor.

Singular-boundary numerics and physical Euler integration are documented in
[the numerical method](../Design/NumericalSingularBoundaryEvaluation_2026-09-07.md)
and [the coalescing-direction limit](../Design/CoalescingNullBoundaryIntegrals_2026-09-07.md).

The completed boundary path is described in
[the result and implementation report](../Design/PhysicalBoundaryResults_2026-09-07.md).
`Boundary/DetermineAmplitudes.wl` owns the general equation/order/integration
sequence. Collinear, cluster and pair-cluster geometries remain separate in
`Integrals/Asymptotics`; Euclidean parameter and scale operations are in
`Integrals/Parametric`.

`Numerics/Validation.wl` compares explicit Laurent coefficient maps with
mandatory order coverage and numerical uncertainty. The boundary-only and
complete-master test drivers are in Scripts/Validation; their inventories
are process data. Boundary integration automatically falls back from
Gamma/Beta integration to SubTropica when needed.

## Analytic NLO hard functions and subtraction schemes

`Physics/Distributions.wl` owns quark and gluon PDF/FF correlator definitions;
`Physics/CollinearFactorization.wl` applies them to diagram interferences.

`Physics/Born.wl` generates complete Born diagram selections, physical invariant
densities and the Born channels required by collinear factorization.
`Physics/Counterterms.wl` owns leading splitting kernels, finite factorization
scheme kernels, exact Born convolution maps, PDF/FF subtraction and UV coupling
renormalization. A campaign may choose a scheme separately for each incoming
PDF and observed FF, including a matrix of additional finite kernels.

`Integrals/Evaluations` supplies analytic one-loop and two-body angular master
values from geometry. Unsupported geometry returns an explicit failure/fallback;
it never selects a process-specific formula. `Coefficients/AnalyticContraction.wl`
propagates required master orders and checks supplied finite coefficients.
`AnalyticEndpoint.wl` handles the supported endpoint branches before expanding
the regulator; it preserves the finite moment contribution and checks both
interior and endpoint orders. `NLO.wl` combines real, virtual, UV and collinear
contributions, requires exact pole cancellation and writes explicit finite
Mathematica expressions. The card-driven runner is
`Scripts/run_nlo_hard_function.wls`; a worked process and independent external
checks use `ppHX_UU_NNLO`, `ppHX_LL_NLO` and `ppHX_TT_NLO`.
See [the common card/result contract](../Design/ProjectCardsAndResults.md).

`Coefficients/DistributionStorage.wl` stores final color-resolved distributions
without redundant uncolored views. The common `Solutions/SharedDefinitions.wl`
compactor compares full definitions within their semantic source scopes, then
removes unused entries. The optional independent verification compares every
retained source definition and full output without evaluating any integral.


Current code cleanup removes the duplicate Born-card generator and the retired
version-8 coefficient reader. `Physics/Born.wl` owns Born construction;
`Physics/Counterterms.wl` owns the physical convolutions; the generic common
result schema is in `Coefficients/PartonicResults.wl`, and finite endpoint
finalization is in `Coefficients/DistributionStorage.wl`.
Zero pruning during dimensional shifts conservatively retains undecided terms
and defers rational cancellation until master aggregation.


Current insertions use Physics/CurrentTensors.wl and the shared amplitude
converter in Physics/CollinearFactorization.wl. The external electromagnetic
wavefunction is amputated before contraction; its current indices stay in D.
Normalized PDF/FF spin insertions remain in Physics/Distributions.wl, while
Physics/Measurements.wl owns linear measurement constraints and their exact
delta-function Jacobians. Integrated tagged momenta retain their evanescent
components. These are general building blocks; complete SIDIS NLO/NNLO
assembly is still in progress.

All active process cards and physical output belong under Projects/.

## Current contributions

Coefficients/CurrentContributions.wl connects generated current amplitudes,
the measured two-particle evaluator, and the common tensor-product result.
The virtual contribution reuses the Born support Jacobian and analytic
one-loop scalar provider. Physics/Counterterms.wl owns the corresponding
Born Mellin convolution and PDF/FF subtraction.

Scalar loop functions use the normalization documented in the
[FeynCalc FAQ](https://feyncalc.github.io/FeynCalcBookDev/Extra/FrequentlyAskedQuestions.html):
FeynCalc B0/C0 have 1/(i pi^2), so their conversion to the package's
1/(i pi^(D/2)) Gamma formulas carries pi^(-epsilon).
