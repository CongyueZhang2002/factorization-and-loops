# Test layout

Tests are grouped by the subsystem whose public behavior they protect:

- `Core/`: package loading, metadata, naming, generality, and basic invariants.
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

Overhaul 2026-09-02: package modules live in layer subfolders of
`FeynFacet/Private/` (manifest `FeynFacet/Private/LoadOrder.wl`); a test that
reads a module file directly names the layer in the path. Tests that only
exercised code retired to `FeynFacet/Private_Backup/` moved with it to
`FeynFacet/Private_Backup/Tests/` and are not part of the batch.
`Scripts/run_tests_pool.sh` runs the batch in reuse mode (`REUSE=1`, the
recommended mode) and runs kernel-launching tests standalone.

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
missing orders. Former physical-finisher tests now exercise boundary
coefficient-operator products, which are intermediate objects.

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
[the 2026-09-06 evidence](../Design/Stage1CostsAndEpsilonFormCriteria_2026-09-06_sources/).

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
