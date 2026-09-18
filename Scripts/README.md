# Driver index

Start with [WORKFLOW.md](../WORKFLOW.md) for installation, execution limits,
completion checks and fresh-versus-replay scope. Driver paths and arguments
below are relative to the repository root. Process inputs, outputs, scratch and
logs belong with their Raw/Results calculation directories; reusable algorithms
belong in FeynFacet and reusable launchers here. User-facing reports and campaign
summaries go to Reports/YYYY-MM-DD/; retired run scripts go to Archive/Runs/.

## Card-owned contributions

| Purpose | Command / guide |
|---|---|
| Validate saved result cards and optional baselines | `Validation/check_project_results.wls PROJECT ORDER [CHANNEL\|all] [BASELINES.json]` |
| Complete supported NLO channel | `python3 Scripts/run_project_results.py --order NLO --mode all --report PROJECT_REPORT.json` |
| Resume / assemble NLO | Same driver with `resume` / `assemble`; all modes regenerate counterterm sources at derived epsilon orders |
| Explicit upstream/current stages | `python3 Scripts/run_contribution_stages.py MANIFEST.json` |
| Generate concrete counterterm cards | `prepare_counterterm_cards.wls PROJECT ORDER CHANNEL\|all` |
| Evaluate counterterm cards and their generated sources | `run_raw_contribution.wls RAW_CARD [all\|resume]` |
| Cards, sources and output format | [ProjectCardsAndResults.md](../Design/ProjectCardsAndResults.md) |

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
| GeneratePairs | `regenerate_pairs.wls RAW_CHANNEL CONTRIBUTION [all\|resume] [kernels]`; calls the same guarded queue as full raw execution |
| ReducePairs | `canonicalize_and_stream.wls`; equivalent integral families and Kira reduction |
| ImportReduction | Same driver in import mode; compatible retained Kira workspace |
| ReconstructCoefficients | `stream_to_coefficients.wls`; materialize reduction, normalize and reconstruct |
| Generate | `construct_current_integrands.wls` |
| Prepare / PrepareSources / Decompose / FinishDecomposition | `prepare_current_integrals.wls` and its corresponding modes |
| DifferentialSystem / ShareMasters / PrepareSolution | Current measured-integral DE construction, sharing and finite preparation |
| PrepareVirtual / ReduceVirtual / EvaluateVirtual | Generated current virtual integrals and their analytic evaluation |
| ReduceOneLoop / EvaluateOneLoop | Measured one-loop reduction/evaluation, preserving full-D order demands |
| RawContribution | Complete ordinary or counterterm contribution through the common raw runner (LO/NLO) |

The authoritative stage mapping and argument construction are in
[run_contribution_stages.py](run_contribution_stages.py).
Use the selected project's current cards and STATUS.md; deleted upstream
workspaces and historical result guides are not accepted calculation inputs.

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

- `import_master_integrals.wls DEFINITIONS.wl PHYSICAL_SOLUTION.wl REPORT.wl [LIBRARY_DIRECTORY]`:
  publish an existing fully explicit physical solution with its original
  integral definitions and coordinate map.
- `solve_ordered_measured_master_integrals.wls DEFINITIONS.wl BOUNDARY.wl REQUEST.wl OUTPUT_DIRECTORY`:
  check sufficient shared values first; integrate and publish if a complete
  match is unavailable. Partial coefficient matches are used by the physical
  residual DE solver; missing dependencies are integrated. See [the library API and limits](../Design/SharedMasterIntegralLibrary.md).

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

For measured-current NNLO phase work:

- `assemble_endpoint_profiles.wls PLAN.wl` assembles solved bulk/face profiles.
- `finalize_partonic_results.wls PLAN.wl` verifies pole coefficients and writes
  the requested finite epsilon ranges.
- Partonic results use the shared readable record writer; no separate compression rewrite is needed.

All old NLO/NNLO calculations and masters were deleted on 16 September.
`run_fresh_projects.py MANIFEST.json` runs one declared project at a time
and rejects preexisting generated data. For NNLO it times the generation of an
upstream recipe with `prepare_project_upstream.wls`, executes all producer
stages, and assembles only after those stages complete. A project's Upstream
manifest belongs under its raw contribution Work directory.

`construct_ordered_endpoint_profiles.wls` connects the freshly generated
physical boundary, coefficient rows and bulk solution. Its direct-crossing
case constructs both physical open faces from the same ordered seed, verifies
the scalar joint meromorphic envelope and both face collars, solves tangential
coefficient functions, and binds each raw contribution's integration input to
its original source definitions. Unsupported geometry remains an explicit
failure; this does not claim a general exceptional-divisor continuation solver.
See STATUS.md for actual execution coverage.

## Fresh timing reports

`summarize_project_results.wls OUTPUT.json [ORDER ...]` reports completed fresh
project/order totals from the supervised monotonic timer. Each channel's time
is the recorded owned raw work plus assembly, including NNLO upstream stages.
Auxiliary raw source channels are listed separately at project level. File
sizes include both Results.wl and its metadata companion. Missing fresh totals
or inconsistent timing records cause an error; verification times remain
separate.

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

The upstream diagram, Kira and coefficient manifest stages resolve
`Raw/order/channel/contribution/Work`; a component owns
`contribution/Work/Components/component/Work`. Their path arguments are explicit
relative paths below the raw channel. The former standalone diagram queue and
its source-extraction test are archived; `Tests/Core/t_parallel_raw_pairs.wls`
exercises the shared production queue with physical interferences and failures.

Repository organization and local guide links are checked with
`python3 Scripts/check_repository_layout.py`. Package-module ownership is checked
separately by `python3 Scripts/check_package_layout.py`. These are structural
checks and do not establish that arbitrary NNLO physics is complete.

Measured-current Generate/Prepare stages require the explicit
`JointAngularAverage` and `MeasuredPhaseSpace` card geometry. The ordinary
NLO raw runner selects its own analytic integration path; it does not require
running every measured-current phase. Named components retain their own
`Work/Components/NAME/Work` directories.

## Readable mathematical records

Generated .wl files use the [shared format](../Design/ReadableRecords.md).
Keep their .meta.wxf companions for exact framework reads. The lexical check
does not hash calculation data:

~~~bash
python3 Scripts/check_readable_records.py Projects/DrellYan_UU/Raw/NLO Projects/DrellYan_UU/Results/NLO
~~~

It checks displayed mathematical symbols and companion presence. Scientific
reference comparisons remain separate.

### Prepared NNLO contributions

`run_project_result.wls RESULT_CARD all|resume|assemble|plan` also handles
NNLO cards with prepared solved integral inputs. `all` reevaluates those inputs,
not the preceding master-DE calculation. `--workers 1 --cpus 0 2 4 6` lets the
Python queue use one four-core allocation while an independent queue uses
1,3,5,7; never exceed two main kernels or eight aggregate cores.

`assemble_endpoint_profiles.wls` now stores a source-bound integration input
and uses the common raw-contribution runner. The measured one-loop reduction,
interior and endpoint drivers preserve/check the original integration definition.


The shared measured-DE driver uses the declared symbolic kernel allocation for
independent family IBP generation and the native thread allocation for Kira.
These phases run consecutively. GenerationKernels preserves exactly the same
selected seeds and equation order; it does not establish a smaller sufficient
seed set. The general worker pool also serves record processing, closes its
owned kernels on failures, and respects explicit nested serial scopes.

`publish_angular_masters.wls ANGULAR_DENSITY.wl REPORT.wl` publishes retained
independent two-body angular seeds to the shared library. Fresh angular production
invokes the same hook automatically; import time is not integration time.

## Polynomial measurement stages

`run_project_result.wls Projects/EE_EEC/Results/NLO/q-qb/Result_Card.wl all` executes the full LO EEC example through the general geometry dispatch. `run_measured_contribution.wls CARD {prepare|de|masters|interior|check|virtual} [all|resume]` exposes its upstream stages. `run_measured_result.wls RESULT_CARD [all|resume|assemble]` is a direct measured-result entry. See the [EE_EEC guide](../Projects/EE_EEC/README.md).
