# General master-integral production path

This is the master-solution portion of [WORKFLOW.md](../../WORKFLOW.md), not the
whole diagram-to-hard-function workflow. The current ppHX inputs are indexed in
[the NNLO channel guide](../../Projects/ppHX_UU/NNLO/qqp-qqp/README.md).

A closed differential system and requested master epsilon orders enter
`ConstructMasterIntegralSolution`. It determines sufficient expansion orders,
prepares the connection, constructs explicit finite coefficients, and writes
them with `WriteMasterIntegralSolution`. The standalone
`FeynFacet/Solution.m` reader evaluates those stored expressions.

The process enters through its integral definitions, coefficients and explicit
input paths. There is no family-specific solver. Full epsilon-form
canonicalization is an optional preparation or simplification.

## From the requested result to stored coefficients

1. Derive master demands from the coefficients multiplying the masters.
   `DeriveMasterIntegralEpsilonOrderRequirements` supplies coefficient-table
   demands; `determine_epsilon_orders.wls` also supports complete calculation,
   endpoint and local Frobenius requirements.
2. Supply a closed `FamilyDifferentialSystem`, or construct it with
   `Scripts/DifferentialEquations/build_family_differential_system_v2.wls`.
3. Call `ConstructMasterIntegralSolution` with
   `RequestedMasterIntegralOrderRanges` or `RequestedMasterIntegralUpperOrders`.
   The general order planner fixes an ordinary base point for the coupled
   system, establishes the needed Laurent bounds and propagates epsilon orders.
   Unknown bounds stop construction; supplied assumptions remain labelled.
4. Store the explicit solution. `solution.wxf` contains finite arithmetic and
   integral definitions plus every requested original-basis coefficient in
   kinematics-independent `C[j,n]`. Text export is also supported.
5. Supply numerical boundary coefficients and evaluate. Physical boundary values,
   global analytic continuation and final observable order coverage are separate
   requirements; a solution up to initial constants does not establish them.

[The mathematical interface](../../Design/FiniteMasterIntegralSolutions.md)
specifies the normalization, definitions, output files and supported scope.
[The order examples](../../Examples/Transport/README.md) explain calculation
and endpoint requests.

## Drivers of the same constructor

All commands below are relative to the repository root. Wolfram drivers run as
`wolframscript -file Scripts/Transport/<driver> ...`.

| Task | Driver and arguments |
|---|---|
| One family from coefficient-table demands | `solve_family_from_coefficient_orders.wls SPECIFICATION.wl OUTPUT_DIRECTORY` |
| Several families with explicit master requests | `solve_master_integral_families.wls INPUT.wl OUTPUT_DIRECTORY` |
| Direct system/form and request | `export_finite_master_integral_solution.wls DATA.wl REQUEST.wl OUTPUT_DIRECTORY` |
| Inspect or derive sufficient orders | `determine_epsilon_orders.wls INPUT.wl OUTPUT.wl` |
| Audit saved epsilon cutoffs without new integrals | `check_solution_epsilon_remainders.wls SOLUTION_FILE_OR_TREE REPORT.wxf` |

These are input adapters around the same mathematical constructor. The low-level
`RequestedEpsilonOrders` option selects evolution-matrix coefficients; use the
master-range options above when requesting actual master-integral orders.

`WithEpsilonRemainderChecks[calculation]` enables independent omitted-order
checks in stages 2, 3 and 4. It keeps the audit separate from the finite
mathematical result. See [epsilon remainder checks](../../Design/EpsilonRemainderChecks.md)
for parallel-worker usage, fault injection and the precise scope of the check.

For concurrent DE construction and finite solutions:

```sh
python3 Scripts/Transport/run_family_solution_campaign.py SPECIFICATION.json
```

This driver submits independent families to an existing KernelPool, with explicit
DE arguments and coefficient requirements. It limits concurrent families and
continues independent tasks after failures. `--retry-incomplete` retries unresolved
phases. It does not require an intervening full-canonicalization campaign.

Equal mathematical inputs can reuse saved work. Changed inputs are refused in an
existing result directory. The worker can form additional lower output coefficients
from stored finite evolution when the required upper evolution orders are unchanged.

## Numerical evaluation

```sh
bash FeynFacet/Backends/flint/build_finite_integrals.sh
wolframscript -file Scripts/Transport/evaluate_master_integral_solution.wls \
  SOLUTION_DIRECTORY REQUEST.wl OUTPUT.wxf
wolframscript -file Scripts/Transport/evaluate_master_integral_solution_batch.wls \
  REQUESTS.wl OUTPUT.wxf
```

A point request supplies `Point`, `BoundaryDataFile` and optional
`EvaluationOptions` / `ReferenceDataFile`. Batch requests additionally identify
`SolutionDirectory` and can specify distinct output files. Up to eight workers
prepare and evaluate independent requests; each uses one native thread.

`"NumericalBackend" -> Automatic` selects FLINT for supported expressions.
`"Wolfram"` retains one reference implementation and handles unsupported compiled
expressions; `"FLINT"` requires compilation to succeed. Both evaluate the same
stored finite definitions. Arithmetic uses arbitrary precision; convergence tests
estimate quadrature truncation rather than proving a global error enclosure.

Singular-boundary continuation retains native complex-ball uncertainty between
Taylor steps and predicts step sizes from the monitored tail. Numerical reports
include boundary precision attempts, continuation timings and ordinary transport
time. See [the numerical protocol](../../FeynFacet/Backends/flint/PROTOCOL_FROBENIUS.md).
The matching-point and final convergence checks retain their existing tolerances.

For repeated nearby points on a line, construct an explicit Taylor expansion:

```sh
wolframscript -file Scripts/Transport/construct_master_integral_taylor_expansion.wls \
  SOLUTION_DIRECTORY REQUEST.wl OUTPUT.wxf
```

This optional numerical route uses the stored rational DE and a finite closed
epsilon-state vector. Its file contains actual Taylor coefficients, a center,
direction and validity estimates. It does not replace the symbolic solution.
See [numerical interfaces and timings](../../Design/NumericalEvaluationSpeedups.md).

## Optional GPL representation

```sh
bash FeynFacet/Backends/ginac/build.sh
wolframscript -file Scripts/Transport/convert_master_integral_solution_to_gpl.wls \
  SOLUTION_DIRECTORY OPTIONS.wl OUTPUT_DIRECTORY
wolframscript -file Scripts/Transport/benchmark_gpl_master_integral_solution.wls \
  SOLUTION_DIRECTORY REQUEST.wl REPORT.wxf
```

The converter saves explicit GPL expressions alongside the finite solution.
A partial conversion is saved with exit status 3; GiNaC refuses missing required
definitions. Select `"NumericalBackend" -> "GiNaC"` explicitly in the usual
requests. Automatic selection remains FLINT, including when GPLs have been
stored. Exact kinematic inputs are required; numerical boundary coefficients
retain their precision.

For a complete coordinate change, the direct export request can supply
`RationalizingParametrizationFile`, `ParametrizingBasePoint` and optional
`RootValuesAtBasePoint`. Its `BasePoint` is in the source coordinates.
Optional `GPLConversionOptions` converts the result before writing.
The direct driver defaults to complete compressed WXF; use
`"FileFormat" -> "WolframText"` for an explicit text export.

See [the scope, branches and measured comparisons](../../Design/GPLImplementation.md).
GPL is optional because conversion can increase file size and numerical cost.

## Independent checks

- `evaluate_masters_with_amflow.wls REQUEST.wl OUTPUT.wxf` evaluates physical
  integral definitions through AMFlow, with explicit runtime and scratch paths.
  EpsilonOrder is the desired absolute upper power after master prefactors.
  The driver converts it to the vendor offset from -2 L and records both
  orders. Exports lacking AMFlowOrderConvention are recomputed. The public
  MasterIntegralAmFlow interface applies the same order conversion. Quadratic
  propagators retain their momentum-square form for AMFlow cut matching;
  vendor aborts produce a failure record and a nonzero exit code.
- `compare_finite_solution_with_amflow_desolver.wls SOLUTION_DIRECTORY REQUEST.wl REPORT.wxf`
  compares the original DE's local-series evolution with finite-solution evaluation
  for supplied test constants. This is distinct from physical AMFlow boundary data.
- `VerifyMasterIntegralSolution[solution]` checks the defining finite-integral
  identities, normalization and basis convolutions. Its default checks source
  and basis identities numerically at rational points; `"IdentityCheck"->"Exact"`
  requests the more expensive symbolic check. This API consumes the same complete
  record as the constructor, including WXF input; the earlier text-only checking
  scripts are archived.

Checks are proportional to a change; ordinary runs do not require a new symbolic
proof or a complete all-family numerical comparison.

## Physical boundaries and retired implementations

Active FeynFacet/Boundary modules construct physical relations, integrate
boundary coefficients and apply ordinary/singular matching to explicit finite
solutions. Local Frobenius mathematics belongs to
FeynFacet/DifferentialEquations/LocalAnalysis; sufficient-order propagation
belongs to FeynFacet/Solutions/Orders; generic GPL operations belong to
FeynFacet/Functions. See [the Boundary guide](../Boundary/README.md) for the
current commands and required physical inputs.

Physical-mode selection, completeness of asymptotic regions, branch prescriptions
and analytic continuation domains remain explicit mathematical requirements.
A stored solution up to constants does not supply them automatically.

Old lazy coefficient operators and superseded composition implementations are
under [the dated backup](../../Archive/RetiredCode/FeynFacet/2026-09-06-production-consolidation/README.md).
They are outside loading and test discovery. Do not use the old
Private/Transport directory names or archived interfaces as current entry points.

The separate stage-3 and complete-master validation drivers are documented in
[../Validation/README.md](../Validation/README.md).

AMFlow runtime calls release their own parent subkernels before external
Wolfram solvers, allowing those solvers to use the requested worker licenses.
Pre-existing caller kernels are preserved. This prevents silent serial
fallback from exhausting the subkernel license allocation.


The AMFlow reference driver also accepts WolframScriptExecution -> "CurrentKernel"
with Threads -> 1. This mode is used by the general validation family pool:
vendor-generated numerical scripts run inside the same licensed worker with
isolated globals, DESolver state and numerical settings. Subprocess mode
remains the default for standalone multi-thread requests. The upstream AMFlow
installation is unchanged.
## Native AMFlow reference solver

AMFlow 2 includes a C++ differential-equation solver. Build it in a writable
installation separate from the upstream source (in particular, keep the legacy
FACET tree read-only):

~~~bash
python3 Scripts/Transport/build_amflow_native.py \
  Addon/Mathematica_Addon/AMFlow Addon/Mathematica_Addon/AMFlowNative \
  --wstp /usr/local/Wolfram/Wolfram/14.2/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64 \
  --jobs 1
~~~

This requires the upstream build dependencies: GMP, MPFR, MPC, Boost, yaml-cpp,
MPSolve and the Wolfram WSTP Developer Kit. `--dependency-prefix DIRECTORY`
also supports development packages extracted into a private prefix. The build
disables OpenMP and caps MPSolve at one thread for family workers. It copies the upstream solver
without changing its numerical algorithms or precision settings.

The default `AMFlowDESolver -> Automatic` selects the native solver if a
matching installation is present. It checks the upstream AMFlow.m and
DESolver.m against the sibling AMFlowNative directory; AMFlowNativePath can
select a different build directory. Otherwise it uses Mathematica.
`AMFlowDESolver -> "CPP"` requires the native solver and `"MMA"` selects the
Mathematica solver. Generated native links are closed inside the script's
definition scope, including after aborts. Neither choice changes requested
epsilon orders or reference accuracy. Build a new runtime directory for an
upgrade; do not rebuild a runtime that running families may still use.

Completed sampled AMFlow systems are reusable during a restart. Before scripts
are regenerated, the driver indexes only complete outputs newer than all their
inputs. It then requires exact bytes for the ordered mathematical inputs,
configuration, source/defaults, numerical settings and output. Only the approved
MMA/CPP backend choice and matching solver-installation path may differ. Wrong
integral keys, missing samples and nonfinite entries are rejected. This cache
uses AMFlow's own boundary values. `ReuseCompletedAMFlowSystems -> False`
disables it; final accepted master references are also reused as before.

`UseMaximalCut` controls Kira's method for discovering IBP masters; the physical
cut propagators remain part of the integral definition. False performs combined
master discovery, while True investigates sectors separately. The
default Automatic selects combined discovery for one-thread jobs and separate
sector investigations when several threads are available. This removes repeated
serial master-discovery jobs from the dynamic family pool. The optional
`SkipTargetReduction -> True` omits the initial reduction only when the supplied
objects are already individual scalar IBP masters; required auxiliary-DE masters
are still constructed. It is not enabled by default.

The same export_finite_master_integral_solution.wls driver accepts a generated
multivariable connection or a retained epsilon-form input. A request can name
FiniteIntegrationPreparationFile and MasterIntegralRepresentationsFile; paths
are relative to the request file. The former may contain the preparation
directly or the timing wrapper written by the common preparation driver.
The latter supplies normalized integral definitions so the planner derives
the bounds itself. No process name or number of variables is selected in
the exporter.
