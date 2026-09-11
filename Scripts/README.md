# Driver index

Start with [WORKFLOW.md](../WORKFLOW.md) for installation, execution limits,
completion checks and fresh-versus-replay scope. Driver paths and arguments
below are relative to the repository root. Process inputs, outputs, scratch and
logs belong under Projects/PROJECT/ORDER/CHANNEL; reusable algorithms belong in
FeynFacet and reusable launchers here.

## Card-owned contributions

| Purpose | Command / guide |
|---|---|
| Complete supported NLO channel | `wolframscript -file Scripts/run_nlo_hard_function.wls PROJECT CHANNEL all` |
| Resume / assemble NLO | Same driver with `resume` / `assemble`; assemble does not regenerate Born dependencies |
| Explicit upstream/current stages | `python3 Scripts/run_contribution_stages.py MANIFEST.json` |
| Current-insertion contribution | `run_current_contribution.wls PROJECT ORDER CHANNEL CONTRIBUTION` |
| Combine declared components | `combine_current_components.wls PROJECT ORDER CHANNEL CONTRIBUTION` |
| Cards, dependencies and output format | [ProjectCardsAndResults.md](../Design/ProjectCardsAndResults.md) |

The stage manifest supplies Jobs with Project, Order, Channel, Contribution,
Stages and optional Execution/TimeoutSeconds; CpuSet and Report are top-level
fields. Report resolves relative to the manifest. A contribution component is
dot-separated, e.g. DoubleReal.Ghosts. Execution fields default to one in this
runner, so declare Kernels, KiraThreads, ReconstructionThreads and
NormalizationKernels explicitly when using eight cores.

The runner stops on the first unsuccessful stage and atomically records active
PID, completed stages, logs and elapsed times. It does not infer missing phases
or represent a complete arbitrary-process NNLO workflow.

| Manifest stage | Driver / operation |
|---|---|
| GeneratePairs | `regenerate_pairs.wls`; eligible Hermitian interferences are reduced automatically |
| ReducePairs | `canonicalize_and_stream.wls`; equivalent integral families and Kira reduction |
| ImportReduction | Same driver in import mode; compatible retained Kira workspace |
| ReconstructCoefficients | `stream_to_coefficients.wls`; materialize reduction, normalize and reconstruct |
| Generate | `construct_current_integrands.wls` |
| Prepare / PrepareSources / Decompose / FinishDecomposition | `prepare_current_integrals.wls` and its corresponding modes |
| DifferentialSystem / ShareMasters / PrepareSolution | Current measured-integral DE construction, sharing and finite preparation |
| PrepareVirtual / ReduceVirtual / EvaluateVirtual | Generated current virtual integrals and their analytic evaluation |
| ReduceOneLoop / EvaluateOneLoop | Measured one-loop reduction/evaluation, preserving full-D order demands |
| EvaluateCurrent / Combine / Counterterm | Card-defined current contribution, component sum or subtraction |

The authoritative stage mapping and argument construction are in
[run_contribution_stages.py](run_contribution_stages.py). The
[ppHX channel workflow](../Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/README.md) identifies
which stages and downstream mathematical inputs belong to the accepted run.

## Rational coefficients and finite reconstruction

- `compact_trace_columns.wls TRACE_DIRECTORY [kernels] [thresholdBytes]`
  replays exact summand compaction; it preserves original expressions.
- `prepare_coefficient_reconstruction.wls TRACE_DIRECTORY CHANNEL_DIRECTORY CONTRIBUTION OUTPUT.wl`
  derives candidate columns, literal exceptional parts and sufficient regular
  orders from current card dependencies. The alternative form is
  `TRACE_DIRECTORY REQUEST.wl OUTPUT.wl`. Preparation does not interpolate.
- `reconstruct_trace_jobs.wls TRACE_DIRECTORY REQUEST.wl` runs selected jobs
  from a normalized checkpoint. It reports a partial job collection, not a
  complete coefficient result. Requests specify Jobs, JobOptions,
  OutputDirectory and Options, with an optional PartitionManifest.
- `assemble_scheduled_coefficients.wls TRACE_DIRECTORY PLAN.wl RESULT.wl CURRENT_ORDER_INPUTS.wl`
  assembles explicitly completed jobs. Finite plans require current mathematical
  inputs; missing native results are not launched in ResumeOnly mode.
- [ReconstructionModule.md](../Design/ReconstructionModule.md) defines matching,
  physical normalization, divisor classification, omitted-tail bounds and reuse.

Native threads follow OS CPU allocation independently of Wolfram kernel licences.
The shared queue gives each pending native job its full requested budget.
Do not copy the old serial diagnostic settings or launch a fixed 7+1 split.
Completed jobs and finite plans must match their exact source/order definitions.

## Master DEs and physical boundaries

- [Transport/README.md](Transport/README.md): DE input, sufficient orders,
  explicit finite solutions, family campaigns and numerical evaluation.
- [Boundary/README.md](Boundary/README.md): physical asymptotics, independent
  amplitude equations, boundary integration, singular matching and substitution.
- [Examples/Transport](../Examples/Transport/README.md): small mathematical requests.
- `DifferentialEquations/build_family_differential_system_v2.wls`: raw family DE.
- `Transport/solve_family_from_coefficient_orders.wls SPECIFICATION.wl OUTPUT_DIRECTORY`:
  one family with coefficient-derived demands.
- `Transport/solve_master_integral_families.wls INPUT.wl OUTPUT_DIRECTORY`:
  explicit requested ranges for several families.

Integral-family canonicalization means equivalent momentum-space definitions.
DE epsilon-form conversion is a distinct optional operation. A failed restricted
epsilon-form ansatz is not a general nonexistence theorem. Native build and
AMFlow runtime instructions are in the Transport guide.

## Physical coefficient and distribution assembly

[Coefficients/README.md](Coefficients/README.md) gives the complete driver chain:
weighted cut sum, physical normalization, finite interior, complete common-frame
endpoint rows, scalar endpoint functions and final distributions.
[ScalarEndpointDriver.md](Coefficients/ScalarEndpointDriver.md) defines campaign
coverage, order extension, checkpoint reuse and explicit failure statuses.

For measured-current NNLO channels:

- `assemble_endpoint_profiles.wls PLAN.wl` assembles solved bulk/face profiles.
- `combine_partonic_contributions.wls PROJECT ORDER` sums declared contributions.
- `finalize_partonic_results.wls PLAN.wl` verifies pole coefficients and writes
  the requested finite epsilon ranges.
- `python3 Scripts/finish_partonic_assembly.py ENDPOINT_PLAN FINALIZATION_PLAN --projects PROJECTS... --order ORDER`
  runs these three phases with shared CPU/process handling.
- `compact_partonic_results.wls PROJECT ORDER` losslessly compresses final results.

The [SIDIS UU](../Projects/SIDIS_UU_NNLO/NNLO/README.md) and
[LL](../Projects/SIDIS_LL_NNLO/NNLO/README.md) guides contain actual replay inputs.
This final-assembly replay reuses solved profiles; it is not master regeneration.

## Validation and operations

- [Validation/README.md](Validation/README.md): separate boundary-only and
  complete-master/AMFlow inventories, coverage and dynamic family execution.
- `Validation/check_reconstructed_trace.py REQUEST.json OUTPUT_DIRECTORY`:
  every named rational/Laurent output versus its source at supplied modular points.
- `Validation/check_saved_epsilon_orders.wls MANIFEST.wl REPORT.wxf`:
  saved-order audits without integration; read [the epsilon audit contract](../Design/EpsilonRemainderChecks.md).
- `Validation/run_sidis_nnlo_checks.py PROJECTS...`: independent complete SIDIS
  references; never imported to construct production coefficients.
- [Tests/README.md](../Tests/README.md): focused tests and package layout checks.
- [wolfram.py](wolfram.py): shared Python runtime for bounded CPU affinity,
  atomic reports, strict current-attempt completion and owned-process cleanup.
- KernelPool and the kpsubmit/kpwait/kpstatus scripts manage the retained
  family-solver pool. Use them only as documented by the chosen campaign;
  do not assume a pool or heartbeat is already running.

Direct older Wolfram adapters can have different completion markers. Inspect
the required output/status as well as the exit code; never treat a missing
script's zero exit as success. Retired launchers and old process-specific
repair scripts are historical, not another production route.
