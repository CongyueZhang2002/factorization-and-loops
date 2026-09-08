# Active tests

The production path is documented in [Scripts/Transport/README.md](../Scripts/Transport/README.md).
The 2026-09-06 cleanup preserves tests of the finite solver, order planner,
numerical backends, optional canonicalization and local boundary mathematics.
Tests exclusive to the retired lazy transport formats moved with their code to
[backup](../Archive/RetiredCode/FeynFacet/2026-09-06-production-consolidation/README.md).
Mixed tests retain their current mathematical assertions. Package export tests
require retired interfaces to be absent, and source scans exclude backup files.

# Test organization

Tests are grouped by the subsystem whose public behavior they protect:

- `Core/`: package loading, metadata, naming, generality, and basic invariants.
- `Coefficients/`: physical coefficient contraction, endpoint orders, exact
  pole decomposition, distribution extraction, color factors and base-point
  endpoint evaluation.
- `EpsilonForm/`: canonicalization, family epsilon forms, regulators, and row gauges.
- `FiniteField/`: modular sampling, reconstruction, and finite-field backends.
- `Infrastructure/`: schedulers, brokers, kernel-pool wrappers, budgets, and traps.
- `Multiquadratic/`: radical algebra, charts, letters, construction, and algebraic solvers.
- `Reconstruction/`: coefficient assembly, NLO golden data, and reconstruction parsers.
- `Transport/`: master-integral solutions along paths, local expansions, and boundary matching.

`TestKit.wl` and `run_tests.sh` stay at this level as shared infrastructure.
`run_tests.sh` discovers every categorized `t_*.wls` and `t_*.sh` recursively.
`Scripts/run_tests_pool.sh` discovers Wolfram tests recursively and still accepts
an individual test by its unique basename, for example
`t_multiquadratic_algebra`, or by `Category/name`.

The package organization is documented in [FeynFacet/README.md](../FeynFacet/README.md).
Tests of optional epsilon-form algorithms explicitly load `FeynFacet/EpsilonForm.m`.
Reader tests load `FeynFacet/Solution.m` independently. Direct source inspection
uses complete paths from `FeynFacet/Kernel/Modules.wl`.
`Core/t_package_entry_points.wls` checks the loading boundaries, actual reload,
and catalog extensibility. `Scripts/check_package_layout.py` checks manifest
coverage and static path integrity.

## Saved mathematical fixtures

Active tests read their required historical mathematical examples from
[Fixtures/DifferentialEquations](Fixtures/DifferentialEquations/README.md).
They no longer require the obsolete `Stale` archive or dated two-root run
directories. The fixtures contain only the inputs and reference samples used
by those tests; full solver logs and intermediate runs have been removed.

## Writing tests for the reused pool (2026-09-02)

- A pool subkernel keeps state between missions. Since 2026-09-02 the pool
  unsets every Global` name that gained an own value during a mission
  (`FACET_POOL_ISOLATION=0` disables it); function definitions, `$Context`
  and `$ContextPath` are NOT restored -- a test that switches contexts
  restores them itself before `FTReport[]`.
- Use descriptive names for top-level test symbols (`radicalPrime`, not
  `p`): a leaked `p`, `m` or `q` becomes a numeric value inside a later
  mission's Kira coefficients.
- Write `System`Names[...]`: after LoadFACET, a bare `Names` binds to the
  empty `FeynCalc`Names` shadow (AGENTS.md, Traps).
- The pooled phase of `Scripts/run_tests_pool.sh` is a screen; a pooled
  failure is confirmed in a fresh standalone kernel before it counts.

Current mathematical names and saved-record conversion are documented in
[MathematicalTerminology.md](../Design/MathematicalTerminology.md).

### Finite master-integral solutions

Transport/t_finite_master_integral_solution.wls checks multivariate equations,
normalization, mixed epsilon orders, triangular epsilon-zero connections,
supplied elliptic homogeneous functions, Laurent basis changes, explicit
constant convolutions, and rejection of cyclic/undefined functions and
missing orders. Tests of the retired lazy transport and boundary coefficient
maps are preserved in the dated backup, outside active test discovery.

The finite-solution tests also cover epsilon rescaling with negative edges,
a common nilpotent flag, reusable homogeneous block reductions, standalone
quadrature, and deliberate corruption of stored kernels or source DEs.
Sampled production checks and optional exact proofs are distinguished in
the returned validation data.


`Transport/t_sufficient_epsilon_orders.wls` covers Laurent bounds,
coefficient/product/convolution truncations, endpoint Taylor projections,
matrix moments, resonant Frobenius pole bounds, and the finite solver's
entrywise order selection against an independent exponential solution.


`Transport/t_master_integral_expansion_orders.wls` tests the connected
normalization/order workflow, automatic parameter-sector resolution, Gamma
normalizations, ordinary and resonant boundaries, residue-exponential
precision, and a two-loop example with no supplied pole bound.

`Transport/t_master_integral_representations.wls` checks automatic construction
from topology data, AMFlow measure factors, scalar and numerator parameter
integrals, cut delta derivatives, phase-space volumes, and the distinction
between constructed cut representations and unresolved pole bounds. It also
exercises the saved-family reference adapter and automatic order-planner path.

- `Transport/t_cut_integral_laurent_bounds.wls` checks compact cut geometry,
  mass-deformed causal certificates, dotted cuts, nonlinear regulators,
  the complete CF269 conservative bounds, and an interior-resonance rejection.
- `Transport/t_dimensional_recurrence_laurent_bounds.wls` checks a complete
  two-body recurrence, the AMFlow shift factor, cache input matching, rational
  basis conversion and pole locations, and the saved 23-master CF269 recurrence
  through the general expansion-order planner. It does not repeat Kira reduction.


## Integrated master-range solutions

`Transport/t_master_order_solution_workflow.wls` checks the complete
master-range-to-solution interface, heterogeneous requests, explicit
constant convolutions, coordinate/point consistency, factorized real/virtual
definitions and compressed/text reading. It reuses the stored dimensional
recurrence and does not run Kira.

`python3 Tests/Transport/t_master_solution_batch.py` checks all-family reuse,
changed-input refusal and continuation after a family failure on small
synthetic systems. It requires the local Wolfram executable.

The stage 1/2 optimization checks are
`Transport/t_finite_solution_speedups.wls` (constant linearity, shared scalar
definitions, exact and numerical DE identities) and
`Transport/t_finite_field_reexpression_speedups.wls` (Schur elimination,
batched numerator recovery and damaged/singular samples).
`Transport/t_finite_field_basis_transformation_reexpression.wls` also checks
sample reuse and complete grid replacement after a newly singular sample.


### Stage-1 scope and performance controls (2026-09-06)

`EpsilonForm/t_epsilon_form_diagnostic_scope.wls` checks geometric residue
components, rational/Taylor-domain restrictions, target closedness, sampled
conclusion scope, and epsilon independence in kinematic support bounds.
The exceptional-epsilon fixture in
`Multiquadratic/t_multiquadratic_off_diagonal_basis_transformation_screen.wls`
now uses closed forms.

`Transport/t_finite_field_reexpression_speedups.wls` includes zero
transformations with zero or three root generators, their explicit
coefficient representations, and invalid root metadata. The current CF259
run also exercises zero reconstruction followed by the normal modular DE
residual.

Reproducible initial-assembly comparisons and the controlled three-root
benchmark are in
[the 2026-09-06 evidence](../ppHX_NNLO_DoubleReal/Results/Validation/Stage1CostsAndEpsilonFormCriteria_2026-09-06).

The standalone numerical evaluator is covered by
`Transport/t_numerical_finite_integrals.wls`: convergence, panel propagation,
boundary substitution, cancellation, insufficient input accuracy, singular
paths, time limits and preservation of exact row/order labels. These tests
need Wolfram but no IBP or AMFlow computation.

## Numerical evaluator optimization checks

- Transport/t_compiled_numerical_finite_integrals.wls checks complex arithmetic
  against the Wolfram evaluator, preparation reuse, changed definitions,
  independent batch failures and native/threaded agreement.
- Transport/t_numerical_taylor_expansion.wls checks explicit Taylor
  coefficients, epsilon dependency closure (including negative powers),
  missing center data, the valid query region, recentering with propagated
  uncertainty, and polynomial moments of the collocation matrix.
- Transport/t_numerical_finite_integrals.wls retains the convergence,
  cancellation, input accuracy and integration-path controls.

Build the native numerical executables before running the compiled checks.

## Independent reference implementations

[Support/README.md](Support/README.md) identifies the two former prototypes
used by active finite-field and multiquadratic tests, and the independent NLO
angular-integral reference. The Prototypes directory and duplicate Codex tests
are retired. Current test discovery is unchanged.

## Optional GPL conversion and evaluation

Build the GiNaC adapter before running the numerical GPL tests.
`Transport/t_gpl_integration.wls` tests rational Hermite reduction, integration
by parts, shuffle products, finite endpoint constants and independent known
GPL values. `Transport/t_gpl_master_solution.wls` checks complete/partial stored
conversion, source-pole and branch-cut counterexamples, precision after boundary
cancellation, schema validity, and two-worker batch evaluation.
`Transport/t_rationalizing_solution_coordinates.wls` checks two Kallen13 roots,
nonprincipal values, normalization, an independent exponential solution,
original-coordinate reference data, and automatic normalization/order discovery.

`Transport/t_amflow_epsilon_orders.wls` exercises the real AMFlow epsilon
sampling, fit and truncation with exact known samples in place of integration.
It checks positive and negative upper powers and a fixed numerical regulator.
The retained nonzero physical CF198 comparison is under the process
Results/Validation/AMFlowCF198_2026-09-07 directory.

`Transport/t_amflow_reference_driver.wls` checks the standalone driver with
real vendor fitting and known samples: prefactor orders, old-cache rejection,
corrected-cache reuse, quadratic cut routing and nonzero exit on vendor abort.

`Transport/t_validation_coverage.wls` checks mandatory coefficient coverage,
explicit zeros, mismatches and inadequate numerical precision. The two
process-level tests are in Scripts/Validation: boundary integration alone and
complete physical masters against AMFlow. Their inventories and demonstrated
coverage are recorded separately under the process Results/Validation folder.
`Boundary/t_boundary_integration.wls` now also checks automatic fallback to
SubTropica when the Beta integrator is inapplicable.

`Transport/t_validation_inventories.wls` checks that new masters, boundary
inputs and epsilon demands invalidate old validation inventories, and that
current inventories reach the coefficient checks.

`Transport/t_amflow_kernel_release.wls` checks ownership-aware release of
AMFlow workers, preservation of caller workers and command options, and cleanup
after normal or interrupted evaluation.


The dynamic-validation regressions include
Transport/t_amflow_in_process.wls (script isolation and restoration),
Transport/t_frobenius_thread_initialization.py (fresh-process FLINT arithmetic
with one/eight threads), and Transport/t_validation_pool_resume.py (complete
coverage and safe resuming). Support/ValidationPoolWorker.wl provides short
uneven-duration jobs for exercising explicit worker replacement.

Transport/t_amflow_native_runtime.wls takes a native AMFlow directory and
solves a small known differential equation through its WSTP backend. It checks
native-link ownership, cleanup on Quit/Abort, caller-definition restoration,
and reloading the runtime with colliding caller variable names.

Transport/t_amflow_system_cache.wls checks exact numerical-input compatibility,
backend/source handling, complete integral keys and epsilon grids, stale output
rejection and nonfinite-number rejection for completed auxiliary systems.
