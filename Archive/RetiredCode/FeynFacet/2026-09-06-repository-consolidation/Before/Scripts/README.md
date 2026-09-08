# Scripts

The general master-integral workflow is:

```text
integral definitions + coefficient demands
  -> closed differential system
  -> sufficient epsilon orders and explicit finite solution
  -> numerical boundary coefficients and evaluation
```

[Transport/README.md](Transport/README.md) is the production entry-point guide.
Every finite-solution driver calls `ConstructMasterIntegralSolution`; process
and family differences enter through input data.

## Production and operations

- `DifferentialEquations/build_family_differential_system_v2.wls` builds a closed
  DE. `build_family_differential_system_block_decomposition_v2.wls` finds its
  strongly connected components.
- `Transport/solve_family_from_coefficient_orders.wls` converts coefficient-table
  demands to explicit master solutions. `solve_master_integral_families.wls`
  accepts explicit requests for several families.
- `Transport/run_family_solution_campaign.py` submits raw-DE and finite-solution
  work to an existing KernelPool with bounded family concurrency.
- `Transport/evaluate_master_integral_solution.wls` and its batch driver evaluate
  the stored expressions. The optional Taylor driver supports many nearby points.
- `KernelPool.wls`, `kpsubmit.sh`, `kpwait.sh` and `kpstatus.sh` manage a shared
  kernel pool. `watchdog_register.sh` is an operational helper.
- `run_tests_pool.sh` runs the active Wolfram tests; see [Tests](../Tests/README.md).

Coefficient reconstruction, diagram and reduction drivers remain in their current
locations. `HardClassToolkit.wl` and `EpsilonGraded.wl` supply algorithms used by
optional canonicalization and research drivers.

## Optional epsilon-form construction

These tools can simplify a connection or help identify its function class.
Complete strict epsilon form is not required by the general finite solver.

- `complete_family_epsforms.sh`, `family_epsform_campaign.sh`,
  `family_epsform_pool.sh` and `family_epsform_sector.wls` run block/family
  canonicalization with explicit V2 input paths.
- `certify_family_epsform_record.wls` validates a supplied working result.
- `rationalize_transport_chart_extension.wls` constructs and verifies a
  rationalizing parametrization from an explicit specification.
- The sector driver respects `FACET_CHECK_LEVEL`. Its optional rational
  epsilon-form diagnostic uses `FACET_OBSTRUCTION_ANALYSIS_SECONDS` and reports
  the tested ansatz and coefficient field; failure is not an arbitrary-basis
  nonexistence theorem.
- `DiagonalBlockClassCampaign` uses `"ValidateCanonicalForm"` for its optional
  additional exact result check. The retired CANONICA fallback and its option
  have been removed.

## Layout and conventions

`Diagnostics/` contains current diagnostics. `HardClasses/` contains historical
mathematical derivations still useful for optional methods. Categorized Wolfram
drivers obtain the repository root from their own path; all process inputs and
output locations are explicit.

New process-specific input fixtures belong with the process or in `Examples/`.
Family-specific experiments belong in `Exchange/`. Shared drivers belong here.

Retired launchers and implementations are preserved in
[the 2026-09-06 backup](../FeynFacet/Private_Backup/2026-09-06-production-consolidation/README.md);
earlier retirements remain in `Backup/retired_routes_2026-09-02/` and
`FeynFacet/Private_Backup/`. Backup code is not loaded, discovered as a current
test, or used as a production input.
