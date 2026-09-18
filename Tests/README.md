# Active tests

The full production workflow is documented in [WORKFLOW.md](../WORKFLOW.md).
The DE portion has its own [Transport guide](../Scripts/Transport/README.md).
The 2026-09-06 cleanup preserves tests of the finite solver, order planner,
numerical backends, optional canonicalization and local boundary mathematics.
Tests exclusive to the retired lazy transport formats moved with their code to
[backup](../Archive/RetiredCode/FeynFacet/2026-09-06-production-consolidation/README.md).
Mixed tests retain their current mathematical assertions. Package export tests
require retired interfaces to be absent, and source scans exclude backup files.

# Test organization

Tests are grouped by the subsystem whose public behavior they protect:

- `Core/`: package loading, metadata, naming, generality, and basic invariants.
- `Normalization/`: absolute current/phase-space normalization, bare gluon sewing,
  and exact measurement covariance under collinear rescaling. State/flavor
  counting is additionally checked by `Physics/t_state_counting.wls`, all authored
  and ordinary compiled cards by `Core/t_derived_state_cards.wls`, and coordinate
  maps/endpoint hypotheses by the corresponding `Coefficients/t_derived_*.wls`.
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

## Fragmentation normalization derivation

`python3 Tests/Physics/test_fragmentation_normalization.py` runs 18 independent
algebra/numerical check groups with SymPy and mpmath. Optional `--report PATH`
writes JSON. It checks physical spin duality, longitudinal and recoil Jacobians,
nontrivial Mellin pairings, a convergent real-collinear radial integral and NNLO
pole/flavor ordering. It does not run a production coefficient or Wolfram;
it is invoked explicitly rather than discovered by the Wolfram test pool.
See [the derivation](../Design/FragmentationNormalization.md) and
[the dated results](../Reports/2026-09-17/FragmentationNormalizationDerivation.md).

## Saved mathematical fixtures

Active tests read their required historical mathematical examples from
[Fixtures/DifferentialEquations](Fixtures/DifferentialEquations/README.md).
They are self-contained mathematical fixtures. The fixtures contain only the inputs and reference samples used
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
[the 2026-09-06 evidence](../Projects/ppHX_UU/NNLO/qqp-qqp/Results/DoubleReal/Validation/Stage1CostsAndEpsilonFormCriteria_2026-09-06).

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


## Project/card/result contracts

`Core/t_project_cards_and_results.wls` checks inheritance, concrete counterterm
cards grouped by lower source channel, automatic Born epsilon requirements,
physical PDF/FF leg assignments, perturbative insertion orders, actual NNLO
components, normalization/basis mismatches, Born epsilon^2, and common NNLO
coefficient storage. The three fresh NLO projects are checked by
`Scripts/Validation/check_nlo_qqprime_references.wls` (53 checks).
Historical fixtures explicitly point into Archive/ProjectLayouts; they are
never a production input. Validation outputs use active order/channel Results.

`Core/t_nlo_counterterm_workflow.wls` checks explicit PDF/FF counterterm
distributions, exact dimensional factors, finite redefinition signs, physical
convolution, source stages, sufficient epsilon orders and regulator-independent
finite redefinitions.
`Core/t_nlo_counterterm_cards.wls` exercises a concrete finite card with a custom
delta kernel, its inverse scheme sign, physical source identity and rejection
of an already converted source or undefined positive-epsilon continuation.
`Core/t_counterterm_card_coverage.wls` checks complete physical operator coverage
independently of card names and grouping, rejecting missing or duplicate
insertions, insufficient epsilon ranges and inconsistent physical overrides.
`Coefficients/t_counterterm_source_dispatch.wls` checks the concrete source
and counterterm dispatcher, including source stages, finite conversion,
per-insertion scale overrides and supplied order-two finite kernels.
`Core/t_current_factorization_legs.wls` checks the dimensional Drell-Yan Born
coefficient and the two incoming PDF insertions using freshly generated sources.
`Core/t_fresh_current_nlo.wls` runs complete SIDIS q-q and q-g NLO calculations
in a fresh consumer project with no LO folder, checks symbolic-charge finite
results and exact pole cancellation, and exercises resume against an actual
retained fixed-charge real contribution when present. Its generated project
and integration report are retained in the q-q NLO validation directory.
`Coefficients/t_perturbative_renormalization.wls` compares the general flavor
sum with explicit matrix multiplication, including every pair of three
factorization legs. `Core/t_nnlo_collinear_renormalization.wls` checks the
order-two pole kernel, running at unequal scales, and the helicity commutator.
`Coefficients/t_counterterm_normalization.wls` checks exact NNLO normalization
covariance at Born coupling powers zero and two with unequal PDF/FF scales,
and rejects inconsistent coupling and leg normalizations.

`Coefficients/t_counterterm_operator_ordering.wls` checks noncommuting PDF and
FF raw/finite matrix order and the supported polarized timelike orders,
including recursive finite-scheme defaults and explicit supplied order-two data.
`Coefficients/t_finite_factorization_scheme.wls` checks inverse finite matrices,
their different-leg products, source stages and rejection of a second finite
conversion. `Coefficients/t_bare_partonic_sources.wls` checks charge covariance
in every entry of a synthetic full distribution and Drell-Yan source metadata
with two incoming legs and no observed fragmentation leg.
`Coefficients/t_generated_bare_sources.wls` generates LO epsilon^2 and bare NLO
epsilon^1 sources in a fresh NNLO consumer without sibling lower-order folders.

`Transport/t_gpl_rational_endpoint.wls` checks finite constants from rational
poles multiplying vanishing GPLs, including trailing-zero logarithms and
cancellation between words. It rejects a divergent lower endpoint and a
nonregular direct upper substitution. `Core/t_collinear_counterterms.wls`
uses the independent Born-only reference in `Support/BornCollinearReference.wl`.

`Coefficients/t_invariant_counterterm_convolution.wls` checks the defining
single-inclusive PDF/FF actions on arbitrary delta, plus and regular Laurent
densities. Independent elementary integrals fix the physical lower limits,
FF dimensional Jacobian, Born specialization and order-two products of all
three physical legs. Kernel endpoint checks include the standard double-plus
Mellin identity, independent nonlinear distribution moments, leg commutation
and vector-valued structure functions.
`Core/t_compiled_scattering_sources.wls` checks consumer-owned scattering
source compilation, inferred QCD channels absent from standalone NLO cards,
positive epsilon requests and allocated execution counts.
`Core/t_invariant_source_fractions.wls` checks the actual saved source setup's
momentum-fraction independence and rejects a scalar contaminated by an incoming
fraction. It requires the observed-gluon validation source.
`Support/check_nlo_positive_epsilon_sources.wls [Real|Virtual ...]` evaluates
retained exact scattering reductions through epsilon one, compares every pole
and finite scalar, and checks the independent renormalization-scale derivative.
`Support/check_fresh_scattering_sources.wls [owned-consumer-project]` generates
LO and NLO sources including diagrams, Kira and coefficient reconstruction in
a new consumer project, then compares them through epsilon one with those
independent retained-reduction calculations. It can resume only its own saved
consumer below the validation directory. These drivers require one allocated
main Wolfram kernel and preserve accepted production results. Inputs, outputs
and current execution are indexed in
[the unification record](../Projects/ppHX_UU/NNLO/qqp-qqp/Results/Validation/CountertermUnification_2026-09-12/README.md).
`Support/check_nlo_only_scattering_source.wls [replay]` checks real-only channel
planning and generates a fresh observed-gluon density through epsilon one;
`replay` verifies its saved output and component-owned upstream artifacts.
`Support/check_nlo_only_subtraction.wls` reuses that source, generates its
physical Born neighbors and requires exact raw pole cancellation. The separate
positive-epsilon copy survives the lower-order request used during subtraction.
Generated intermediate directories may be removed after successful validation;
the retained report distinguishes verified historical paths from current files.

`Core/t_intermediate_zero_pruning.wls` checks conservative pruning and spin
harmonics. `Coefficients/t_zero_reconstruction_prefix.wls` ensures a finite
zero prefix cannot supply uncomputed epsilon orders. `Core/t_compressed_records.wls`
checks exact compressed record I/O. Current coefficient-format tests reject
retired version-8 records. Old NLO data-dependent replay tests were moved to
`Archive/RetiredCode/2026-09-08-cleanup` after the user requested deletion of
their generated inputs.

The NLO regeneration checks include `Scripts/Validation/check_nlo_spin_transfer.wls`:
same-line helicity conservation, transverse Born ratios and spin-angle
correlations, leading soft emission, all three factorization-scale derivatives,
exact pole cancellation and explicit integral-free output. It generates the
required Born coefficients through epsilon zero under its own validation
directory through the shared source executor, and compares the derivatives
with `Support/BornCollinearReference.wl`. It reads no standalone LO results. They supplement
the independent UU/LL reference driver. A full finite TT external reference
has not been established.
`Coefficients/t_analytic_sum_orders.wls` checks sufficient order bounds for
sums of analytic prefactors and rejection of an insufficient master tail.

`Core/t_parallel_kernel_startup.wls` checks eight-worker startup and preservation
of a caller's existing worker pool. `Core/t_compressed_records.wls` checks
plain/compressed exact recovery, including package symbols, the regulator,
and System symbols shadowed by packages.

## Shared cards, finalization and driver execution

- Core/t_compiled_card_dependencies.wls checks compiled-card reuse, actual
  perturbative orders, fresh Born generation owned by the consuming NLO
  contribution, increased epsilon demand, and pure LO output through epsilon^0.
- Algebra/t_final_partonic_results.wls checks separate components and endpoint
  axes, missing Laurent orders, source/assumption matching, exact-versus-numerical
  evidence, unresolved finite integrals and positive epsilon slices.
- Run `python3 Tests/Infrastructure/test_wolfram_runner.py` for CPU allocations,
  current-attempt completion, startup-only retries and cleanup of a worker
  whose launcher has already exited. These checks do not start Wolfram.

The cut-catalog and coefficient assembly regressions cover independent family
names, typed cuts and measures, restricted integration domains, Lorentz-dimension
annotations, bound source/target catalogs, polarization conventions and finite
Laurent coverage. `Coefficients/t_cut_assembly_files.wls` exercises the actual
catalog producer and assembly CLI with WXF round-trips and failed-output cases;
it requires two available Wolfram main-kernel licenses and should run outside
an active Wolfram production job.


`Reduction/t_supplemental_ibp_reduction.wls` checks missing-export accounting,
exact cut-preserving supplementary rules, rejection of circular/unresolved
targets, local seed padding, and isolation of Kira's `d` from caller values.

`Algebra/t_exact_data.wls` checks exact/inexact real and complex numbers, held expressions, and both stored entries and implicit values of sparse arrays without dense expansion.

`Coefficients/t_coefficient_record_merging.wls` distinguishes additive amplitude
records from reduction rules: identical repeated rules are allowed, conflicting
rules and malformed or truncated records are rejected.

`Coefficients/t_reconstruction_aliases.wls` covers bare-variable coefficients,
context-preserving alias decoding and rejection of unregistered or surviving
aliases. The emitter must register a scalar variable even at expression level zero.

- `Coefficients/t_rational_compaction.wls`: 21 checks of exact rational summand compaction, source preservation, native trace reuse bindings and byte-hash equivalence.
- `Infrastructure/test_rational_summands.py`: six checks of streamed term splitting across chunk boundaries and atomic file replacement.

- `Infrastructure/test_rational_trace.py`: four checks of native modulus restrictions and complete evaluation-output parsing.

- `Coefficients/t_automatic_reconstruction_plan.wls` checks automatic source
  selection, literal moving-divisor separation, physical-prefactor order loss,
  exact fallback, dependency validation and card/default-path integration.
- `Coefficients/t_reconstruction_orders.wls` also rejects coordinate maps whose
  numerator substitutions would introduce untracked poles or nonpolynomial
  functions.

- `Coefficients/t_reconstruction_planning_inputs.wls` checks source-to-endpoint
  physical normalization, reference scale, representative factors, effective
  coordinate composition and nonzero parameter denominators.
- The automatic-plan test also covers changed current inputs, a stale divisor
  inventory, independent unsupported masters, regulator rewrites and replacement
  of a previous finite plan by an all-rational plan.

- `Core/t_native_thread_allocation.wls` checks both Kira and reconstruction
  allocation independently of Wolfram kernel limits.
- `Coefficients/t_reconstruction_cpu_schedule.wls` checks that later jobs
  receive the available CPU budget and preserve their individual epsilon modes.

The retired aggregate counterterm migration checks are archived. Use
`Scripts/Validation/check_project_results.wls` for saved result-card and optional
baseline validation, plus the Core source-owned counterterm tests. The shared
`CountertermComparison.wl` implementation remains the exact comparison reference.

Repository organization and local guide links are checked with
`python3 Scripts/check_repository_layout.py`. Package-module ownership is checked
separately by `python3 Scripts/check_package_layout.py`. These are structural
checks and do not establish that arbitrary NNLO physics is complete.

## Record and pre-IBP handoff checks

Core/t_readable_records.wls covers exact readable serialization.
Core/t_resumed_pair_provenance.wls includes the actual raw-driver Kira handoff
and stale output inventory. Core/t_canonical_parallel_inputs.wls uses a
32-file batch on two actual subkernels, checks exact output readback and corrupt
companion rejection, and verifies that solve handles omit full source records.
The last two tests use existing ppHX UU NLO qq′ pair fixtures in Projects.

## Shared master library

`TestKit.wl` sets the library mode to `Disabled` before package loading so test
fixtures cannot populate production records. The `Integrals/t_master_library*`
tests explicitly use temporary libraries. They cover physical identity,
sufficient epsilon orders, exact conflicts, cut and virtual momentum transformations,
family/sector indexing, automatic scalar publication and pole-aware IBP relations.
`Transport/t_partial_master_library_evolution.wls` tests physical evolution,
singular inverse gauges, Frobenius logarithms and endpoint cancellations. See [the library design](../Design/SharedMasterIntegralLibrary.md).

High-pT SIDIS current checks are `Physics/t_highpt_hard_functions.wls`,
`Physics/t_highpt_quark_poles.wls`, and `Physics/t_highpt_antiquark_finite.wls`.
`Algebra/t_regular_analytic_limits.wls` verifies explicit two-sided removable
limits and rejection of genuine poles/jumps. `Integrals/t_unmeasured_cut_phase_space.wls`
also checks publication and reuse of independent angular seeds. These tests do
not claim an external full finite-NLO reference comparison.

Full LO EEC: `Physics/t_eec_complete.wls` checks the endpoint-inclusive literature result, exact pole cancellation, and independently generated inclusive moments. `Physics/t_eec_card_workflow.wls` checks the native master DEs and interior reconstruction. `Functions/t_gauss_endpoint_series.wls` checks resonant connection formulas independently of the process.
