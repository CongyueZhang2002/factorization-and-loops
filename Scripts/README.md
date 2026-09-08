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
The reduce/regenerate pair drivers are example-process upstream operations,
with input cards and workspaces documented in the process directories.
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
