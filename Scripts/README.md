# Scripts

[Transport/README.md](Transport/README.md) documents the general production path:

```text
integral definitions + coefficient demands
  -> closed differential system
  -> sufficient epsilon orders and explicit finite solution
  -> numerical boundary coefficients and evaluation
  -> physical coefficient density and delta/plus/regular distributions
```

[Coefficients/README.md](Coefficients/README.md) documents the final contraction,
endpoint order planning and distribution assembly with explicit color factors.

## General DE and numerical drivers

- DifferentialEquations/build_family_differential_system_v2.wls builds the DE;
  build_family_differential_system_block_decomposition_v2.wls finds its strongly
  connected components.
- Transport/solve_family_from_coefficient_orders.wls and
  solve_master_integral_families.wls call the general finite constructor.
- Transport/run_family_solution_campaign.py schedules families through
  KernelPool with bounded concurrency.
- Transport/evaluate_master_integral_solution.wls and its batch and Taylor
  drivers evaluate the saved explicit solutions.

## Upstream reduction and reconstruction

canonicalize_and_stream.wls, canonicalize_trace_buckets.wls,
compact_trace_columns.wls and stream_to_coefficients.wls prepare equivalent
integral families and coefficient data. assemble_reconstruction.wls and
verify_reconstruction_slice.wls assemble and check reconstructed coefficients.
`regenerate_pairs.wls` reads a contribution through `ReadProcessCard`.
Its owner argument is `PROJECT/ORDER/CHANNEL`; its card argument is `Real`,
`Virtual` or a component such as `DoubleReal.Ghosts`.
`run_nlo_hard_function.wls PROJECT CHANNEL all` runs the complete NLO path.
See [cards and results](../Design/ProjectCardsAndResults.md).
Here integral-family canonicalization means equivalence under momentum
relabeling; it is distinct from epsilon-form canonicalization of a DE.

## Optional epsilon-form methods

family_epsform_campaign.sh, family_epsform_pool.sh and
complete_family_epsforms.sh call family_epsform_sector.wls with an explicit V2
input table. certify_family_epsform_record.wls validates an explicit result.
DifferentialEquations/build_diagonal_block_dlog_epsilon_form_v2.wls and
rationalize_transport_chart_extension.wls expose optional general operations.
EpsilonGraded.wl is a standalone scalar epsilon-graded method with its own
mathematical tests.

Canonicalization is optional for the finite solver. The rational epsilon-form
diagnostic reports its tested ansatz and coefficient field; failure is not a
general nonexistence theorem. FACET_CHECK_LEVEL controls driver checks and
FACET_OBSTRUCTION_ANALYSIS_SECONDS bounds the optional diagnostic.

## Operations and diagnostics

KernelPool.wls, kpsubmit.sh, kpwait.sh and kpstatus.sh manage shared kernels.
seat_run.sh, native_core_lease.sh and run_with_allowance.sh bound resource use.
run_tests_pool.sh runs active tests. Diagnostics contains general benchmarks
with explicit inputs, modular sampling support and a coefficient-valuation
utility; it contains no old per-family campaign directory.

Put new scratch runs outside the repository. Put reusable input examples in
Examples or with the process. Current code goes here or in FeynFacet;
completed research notes go to Archive/History.

Retired drivers, duplicate wrappers, old migrations and historical class
experiments are preserved in
[the code backup](../Archive/RetiredCode/FeynFacet/2026-09-06-repository-consolidation/README.md).
Backups are never loaded or discovered as active tests.

## Finite density and saved-order checks

`Coefficients/assemble_finite_master_density.wls` accepts `CoefficientWorkers -> 1..8` (default 1) and `EpsilonRemainderChecks -> True`. Independent coefficient expansions use a fresh owned pool; shared master definitions remain in the parent kernel. The default `CoefficientFunctionDirectory -> None` avoids writing and immediately rereading hundreds of redundant coefficient files. A caller may still explicitly request resumable coefficient files.

`Coefficients/assemble_endpoint_subtracted_density.wls` accepts the same audit flag and writes assembly phase timings and an audit sidecar. Its `ColorDecomposition` request accepts `Workers -> 1..8`. Extracted factors must be independent of epsilon and the endpoint integration variable.

`Validation/check_saved_epsilon_orders.wls` audits saved stage-3 or stage-4 coefficients from a manifest, with no integration. See [the omitted-epsilon guide](../Design/EpsilonRemainderChecks.md) for its contracts and limits.


Active calculation projects are under Projects/. The NLO and standalone Born
drivers take a project name and channel name; they resolve the common card
and contribution cards themselves. The Born driver writes the same explicit
PartonicResult consumed by the NLO counterterm workflow. The retired
generate_nlo_counterterm.wls expected the discarded card layout and is in
Archive/RetiredCode/Scripts/. Current counterterms are generated by
run_nlo_hard_function.wls from Counterterm.wl and its declared dependencies.

Current contribution cards run with:
`run_current_contribution.wls PROJECT ORDER CHANNEL Born|Real|Virtual`.
Results are written in the same epsilon-indexed partonic format under
Projects/PROJECT/ORDER/CHANNEL/Results. The complete current-project
counterterm/assembly driver remains in progress.

Integrated SIDIS and Drell–Yan share the current production driver. Independent full-result comparisons use Validation/check_sidis_references.wls and Validation/check_drell_yan_references.wls; neither reference reader is imported by production.

## Generated measured-current master systems

Run construct_current_integrands.wls, prepare_current_integrals.wls, and
construct_current_differential_systems.wls with PROJECT ORDER CHANNEL CONTRIBUTION.COMPONENT.
The component inventory and physics come from the cards. After all component
DEs exist, reduce_current_master_system.wls PROJECT ORDER CHANNEL CONTRIBUTION
shares exact powered cut identities and differential relations. Results and
Kira workspaces remain under that project/order/channel. These steps do not
claim integrated hard functions or determined physical boundary values.

prepare_current_differential_system.wls exercises the shared finite solver's
homogeneous preparation; its dimension conversion belongs to the general
solver interface, including sparse input matrices.

run_current_components.py MANIFEST.json executes an explicit ordered stage list
with a bounded CPU affinity. The manifest contains Jobs (Project, Order, Channel,
Contribution, Stages), CpuSet and Report; paths resolve relative to the manifest.
Each stage must report its completed output, exit successfully and have no syntax
error. The report is updated atomically after each stage and stops at a failure.

### Measured current preparation and virtual scalar functions

`prepare_current_integrals.wls PROJECT ORDER CHANNEL CONTRIBUTION [all|prepare|decompose]`
saves the complete prepared density before decomposition. The optional modes
allow a completed exact cancellation to survive a decomposition retry.
`run_current_components.py` supports PrepareSources and Decompose separately.

`reduce_current_one_loop_integrands.wls PROJECT ORDER CHANNEL CONTRIBUTION`
performs full-D tensor reduction with declared measured kinematics. Its output
retains the prescribed external factors and their separately identified interior
values. `evaluate_current_one_loop_integrands.wls` constructs explicit interior
Laurent coefficients with per-scalar order propagation and omitted-order checks.
It does not perform endpoint limits or add the conjugate interference.
The corresponding manifest stages are ReduceOneLoop and EvaluateOneLoop.


## Explicit endpoint profiles and final partonic results

- assemble_endpoint_profiles.wls PLAN.wl assembles shared solved bulk and full
  face profiles into current card-defined channel results.
- combine_partonic_contributions.wls PROJECT ORDER sums exactly the contributions
  declared by that order/channel's cards.
- finalize_partonic_results.wls PLAN.wl checks every input pole coefficient,
  matches the exact checked expressions, extracts the requested finite ranges,
  writes compressed Mathematica results and checks their read-back.
- finish_partonic_assembly.py ENDPOINT_PLAN FINALIZATION_PLAN --projects ...
  --order ... runs those three general steps with completion-marker checks.
- compact_partonic_results.wls PROJECT ORDER losslessly compresses final results.
- Validation/run_sidis_nnlo_checks.py is the independent SIDIS literature
  checker; it is never called to construct a production coefficient.
