# Script layout

General production and operational entry points remain directly under
`Scripts/` so established commands and automation keep stable paths. More
specialized material is grouped by purpose:

- `Diagnostics/`: benchmarks, probes, ledgers, and read-only campaign analysis.
- `HardClasses/`: historical hard-class derivations and reproducibility drivers.
- `Backup/retired_routes_2026-09-02/`: the CANONICA/Maple eps-form drivers, the August transport sweep and the Libra research tooling, retired with their routes (see its README).

## Production entry points

- Sufficient epsilon orders:
  `Transport/determine_epsilon_orders.wls INPUT.wl OUTPUT.wl` derives integral
  bounds or propagates calculation, endpoint, local Frobenius and
  fundamental-matrix requirements. `Task -> "MasterIntegralExpansion"` runs
  the connected normalization, pole-bound and expansion-order workflow. See `Examples/Transport/README.md`.

- V2 differential-equation stages:
  `DifferentialEquations/build_family_differential_system_v2.wls` constructs
  one explicit `FamilyDifferentialSystem`; then
  `DifferentialEquations/build_family_differential_system_block_decomposition_v2.wls`
  derives its strongly connected components and writes one validated
  `FamilyDifferentialSystemBlockDecomposition`. Both accept absolute or
  repository-root-relative mathematical input paths.
- Full epsilon-form completion: `complete_family_epsforms.sh`
- Family campaign and worker: `family_epsform_campaign.sh`,
  `family_epsform_pool.sh`, and `family_epsform_sector.wls`. The launchers
  take a tab-separated table whose columns are the family and explicit paths
  to its V2 `FamilyDifferentialSystem`, block decomposition, coefficient
  presentation, and directory of validated diagonal-block dlog epsilon forms.
  Paths may be absolute or repository-root-relative. The worker validates the
  completed family equation and writes `FamilyDLogEpsilonForm.wl`; it never
  discovers or translates the retired pre-V2 result tree.
- Standalone validation of an explicitly supplied working result and V2
  system remains available through `certify_family_epsform_record.wls`; the
  production worker already performs this validation before writing output.
- Master-integral solutions along paths: `complete_observable_transport.sh`
  (manifest + rounds; dispatches the standalone driver),
  `observable_transport_kernelpool_campaign.sh` (CANONICAL multi-family
  driver: one pool main + N subkernels, mission
  `family_observable_transport_pool_mission.wls`),
  `observable_transport_campaign.sh` (standalone: one wolframscript per
  family, no pool -- only when no KernelPool can run or for one family),
  `family_observable_transport.wls`, `complete_master_transport.sh`
  (epsilon-form completion followed by construction of requested master-integral coefficients; the name
  predates the retirement of the Libra `TransportFamily` route, which it
  never calls)
- Shared persistent kernel pool: `KernelPool.wls`, `kpsubmit.sh`, `kpwait.sh`,
  `kpstatus.sh`, `watchdog_register.sh`
- Test pool: `run_tests_pool.sh`

The differential-equation builders, reconstruction pipeline, campaign launchers,
and small production utilities also stay at this level. `HardClassToolkit.wl`
and `EpsilonGraded.wl` remain here because both general and historical drivers
load them as shared source modules.

## Conventions

Categorized Wolfram scripts derive the repository root with
`DirectoryName[ExpandFileName[$InputFileName], 3]`. Top-level scripts use their
existing two-level ascent. Repository-internal callers and provenance strings
should name the categorized path explicitly.

New family-specific experiments belong in `Exchange/`; add a script here only
when it is reusable. Keep public production commands at `Scripts/` root. Move a
stable entry point only as a deliberate compatibility migration with all callers
and documentation updated in the same change.

Current mathematical names and saved-record conversion are documented in
[MathematicalTerminology.md](../Design/MathematicalTerminology.md).

### Finite solutions at an ordinary point

Transport/export_finite_master_integral_solution.wls accepts a general system
or dlog record, an explicit request, and an output directory. It stores finite
nested integrals and resolves both basis-change epsilon convolutions.
Transport/verify_finite_solution_at_base_point.wls checks the data in a fresh
kernel without FeynFacet. See Design/FiniteMasterIntegralSolutions.md.

### Finite DE solutions

Transport/export_finite_master_integral_solution.wls accepts a general
system or dlog form, an explicit request, and an output directory. It writes
finite nested integrals and original-basis epsilon coefficients up to
kinematics-independent initial constants. The production default uses
sampled numerical checks; full coefficient verification and symbolic proofs
are optional. See [the interface](../Design/FiniteMasterIntegralSolutions.md).

The epsilon-order driver also supports `MasterIntegralDimensionalRecurrence`
and `DimensionalRecurrenceLaurentBounds` tasks, with a top-level `Options`
association. The master-expansion request can use an existing recurrence or
construct complete family recurrences at its rational ordinary point.
See [cut-integral Laurent bounds](../Design/CutIntegralLaurentBounds.md).


## Requested master coefficients for several families

`Transport/solve_master_integral_families.wls INPUT.wl OUTPUT_DIRECTORY`
takes a `Families` association of systems, master ranges and construction
options. It derives sufficient orders and stores complete compressed finite
solutions in ordinary-point constants. Independent failures are recorded
without skipping later families. Equal saved inputs resume without
recomputation; changed inputs are refused.
See [the example](../Examples/Transport/pre_stage3_family_solutions.wl) and
[the full interface](../Design/FiniteMasterIntegralSolutions.md).


### Stage-1 diagnostic cost and arithmetic scope (2026-09-06)

The sector driver propagates its selected `FACET_CHECK_LEVEL`. The default
Production mode uses explicit products for off-diagonal assembly; the package
option `"OffDiagonalSimplification"->"Together"` remains available for controlled
comparisons. Exact zero block transformations still pass the usual modular
DE residual.

`FACET_OBSTRUCTION_ANALYSIS_SECONDS` enables the optional rational Taylor
diagnostic with the specified positive time allowance, capped by the remaining
block deadline. It is disabled by default. Its output is stored under
`EpsilonFormDiagnostics`, with fixed normalization and coefficient-field
scope; it is not an arbitrary-basis nonexistence certificate. See
[the audit](../Design/Stage1CostsAndEpsilonFormCriteria_2026-09-06.md).


## Coefficient-table requests and concurrent finite solutions

`Transport/solve_family_from_coefficient_orders.wls SPECIFICATION.wl OUTPUT_DIRECTORY`
matches current coefficient-table master identifiers to a closed DE, combines
duplicate demands by their maximum upper order, and calls the standard order
planner and explicit finite-solution constructor. The specification contains
`DataFile`, `OrderRequirementsFile`, and optional `RequestOptions`, `Options`,
`FiniteIntegrationPreparationFile`, or `DimensionalRecurrenceFile`.
The lower cutoff includes transport of every required boundary component.
Equal saved inputs resume; changed inputs or invalid requests preserve the
completed mathematical result. If only lower output coefficients were omitted,
the worker can form them from the stored finite evolution without reintegration.

`python3 Transport/run_family_solution_campaign.py SPECIFICATION.json` submits
fresh DE construction and finite-solution phases to one existing KernelPool.
All paths, families, DE arguments and coefficient requirements are explicit
inputs. The driver keeps atomic status and direct source snapshots, limits
simultaneous families, assigns one Kira thread per family, and continues
independent families after failures. `--retry-incomplete` retries unresolved
phases using new DE scratch directories. It does not start another pool or
claim complete canonicalization or final physical NNLO order coverage.

## Numerical evaluation of stored master solutions

`Transport/evaluate_master_integral_solution.wls SOLUTION_DIRECTORY REQUEST.wl OUTPUT.wxf`
reads a request with `Point`, `BoundaryDataFile`, optional `ReferenceDataFile`,
and `EvaluationOptions`. It checks the basis, base point and reported boundary
accuracy, then evaluates the stored symbolic coefficients with convergence
control. See the CF3 numerical-evaluation result directory for a working request.

`Transport/evaluate_masters_with_amflow.wls REQUEST.wl OUTPUT.wxf` computes
boundary/reference values from exact integral definitions and explicit AMFlow,
Kira and Fermat runtime paths. `WorkingDirectory` keeps temporary computations
outside the source tree. Existing sufficient results can supply new coefficient
exports without repeating AMFlow.

`Transport/compare_finite_solution_with_amflow_desolver.wls SOLUTION_DIRECTORY REQUEST.wl REPORT.wxf`
compares against AMFlow's local-series solver on the original DE using an
explicit finite test boundary polynomial. This optional diagnostic is distinct
from auxiliary-mass-flow evaluation of physical boundary constants.

See [the numerical evaluation report](../Design/NumericalMasterIntegralEvaluation_2026-09-06.md).

## Compiled arbitrary-precision evaluation and CPU batches

Build both numerical executables with:

```bash
bash FeynFacet/Backends/flint/build_finite_integrals.sh
```

The reader automatically uses FLINT complex ball arithmetic for supported
stored expressions. Set `"NumericalBackend"->"Wolfram"` to use the reference
implementation, or `"FLINT"` to require the compiled evaluator.
``FeynFacetSolution`PrepareMasterIntegralSolution[data]`` validates and prepares
arithmetic once for repeated points. Preparation is numerical setup; it does
not replace any stored symbolic coefficients.

`Transport/evaluate_master_integral_solution_batch.wls REQUESTS.wl OUTPUT.wxf`
accepts `<|"Requests"->{request1,request2,...},"BatchOptions"->{"Workers"->8}|>`.
Each request contains `SolutionDirectory`, `Point`, and the same optional
`BoundaryDataFile`, `ReferenceDataFile` and `EvaluationOptions` as the
single-point driver. `OutputFile` optionally writes each result as it finishes.
Results retain input order and independent failures. Each worker retains
prepared families and uses one native thread. `"KeepKernels"->True` retains
newly created subkernels; the default closes only those created by this call.

For a single point, `"Threads"->8` can parallelize kernel evaluation across
quadrature nodes. CPU batches are normally the better use of the eight cores.

## Explicit local Taylor expansions

`Transport/construct_master_integral_taylor_expansion.wls SOLUTION_DIRECTORY REQUEST.wl OUTPUT.wxf`
accepts `Direction`, optional `BoundaryDataFile`, and `Options` for
``FeynFacetSolution`ConstructMasterIntegralTaylorExpansion``. Otherwise,
`"InitialConstantValues"` supplies the original ordinary-point constants
through the required orders.

The constructor closes the raw-DE epsilon-coefficient dependencies and
applies a sparse Taylor recurrence. A negative epsilon power can require
higher boundary orders. Missing coefficients and unbounded dependencies are
reported explicitly; omitted coefficients are never assumed to vanish except
below the declared/propagated Laurent bounds.

The resulting WXF stores actual numerical Taylor coefficients, the ordered
coefficient states, center, direction, boundary binding, accuracy and validated
parameter radius. It is an optional numerical approximation alongside the
complete symbolic solution. Evaluate it with:

```wl
expansion = Import["expansion.wxf", "WXF"];
value = FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[expansion, z];
(* The point is expansion["Center"] + z expansion["Direction"]. *)
```

A directional expansion covers points on its specified line. Queries outside
its accepted radius or with insufficient estimated accuracy fail. Radius
selection uses complex poles of the restricted rational connection; Taylor
truncation estimates and off-grid DE residuals are checked at both outer
endpoints and an interior point. Production setup makes one direct comparison
against the stored finite integrals; `"ValidationPoints"->3` requests three. This is not a rigorous global
error bound or automatic continuation across thresholds.

To move the center, evaluate a point with `"ReturnCoefficientStateValues"->True`
and pass that result as `"CenterData"` to the constructor, together with the
same original boundary constants. Every required internal coefficient is
checked, and its exported accuracy includes the estimated Taylor error.
The new construction checks the basis, original base point and boundary
binding, and performs its own validation. A different direction may require
additional coefficient states.

See [the timing and scope report](../Design/NumericalEvaluationSpeedups_2026-09-06.md).
