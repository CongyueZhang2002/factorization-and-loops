# Two independent validation levels

For the full workflow and current process inputs, start with [WORKFLOW.md](../../WORKFLOW.md) and the [ppHX NNLO guide](../../Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/README.md).

These drivers accept process data. The package comparison function is
``FeynFacetSolution`CompareLaurentCoefficients``; it requires every requested
order, accounts for numerical uncertainty, and distinguishes failed values
from missing coefficients. It never interprets an omitted coefficient as zero.

## Stage 3: boundary integration only

```bash
wolframscript -file Scripts/Validation/validate_stage3.wls MANIFEST.wxf REPORT.wxf
```

The manifest specifies `AmplitudeReductionFile`, `BoundaryIntegrals` and
optional `ComparisonOptions`. Each boundary entry has a string `ID`,
`BoundaryInputIndex`, explicit `RequiredOrders`, and an independent reference
descriptor: `Reference -> <|"File" -> path, "Keys" -> optional key sequence|>`.
References contain `LaurentCoefficients` or a full `AnalyticExpression`.
`IndependentReferenceDescription` records the mathematical identification of
the reference with the physical coefficient, including normalization. That
identification must be supplied; equality of two arbitrary integrals is not
inferred from their file names.

By default the driver reruns `IntegrateEulerBoundaryIntegral` for entries with
independent references, using the production integral definition and full
requested epsilon range. It compares the new coefficients both to the
independent representation and to the stored production coefficients. The
new integral evaluations are saved beside the report. Setting
`RecomputeBoundaryIntegrals -> False` compares stored values only and is
recorded per input. Missing references do not trigger useless reintegration.
`IntegrationBackend` and `TimeLimit` are optional.

No DE transport or AMFlow-derived ordinary-point constants enter this test.
It validates the integrals and coefficients of the specified physical limits;
it does not re-prove completeness of the asymptotic regions.

An optional third argument selects comma-separated input IDs for a demonstration.
The report still lists the full inventory. Selected tests can pass while the
overall inventory remains `Incomplete`. The default tests every input; missing
references or reference orders return a nonzero exit code.

## Complete master integrals: physical solution against AMFlow

```bash
python3 Scripts/Validation/run_complete_master_validation.py COMPLETE_MANIFEST.json
```

For each family this command:

1. Constructs physical integral definitions from the source topology, with the
   requested master rows and sufficient reference epsilon orders.
2. Calls the general AMFlow driver in a separate Wolfram process.
3. Reads the saved physical solution and evaluates it afresh at the same point.
4. Compares every requested coefficient of every requested master, checking
   integral identity, point, normalization, cuts and reference precision.

The reference is never supplied as boundary data to the DE. Arbitrary supplied
initial constants are forbidden. AMFlow's corrected definition/order cache is
reused; the current physical solution is reevaluated. The default runs one family at a time. Use --workers 8 --resume for a
dynamic pool of eight families, one CPU per family, with one main Wolfram
dispatcher and eight subkernels. The pool runs AMFlow's generated solver
scripts in their existing family worker, under isolated definitions and
numerical settings; it launches no extra main kernels. Logs and mathematical results stay inside
the supplied process output directory.

`--only CF198 --rows 1` demonstrates one master. Omitting these options tests
every inventory entry. The JSON report retains all master rows and required
orders, including `NotChecked` entries. An overall `Passed` requires complete
coverage. `SelectedTestsPassed` and the process exit code describe the selected
run only. No complete numerical audit is implied by a demonstration.

## Preparing both inventories

```bash
wolframscript -file Scripts/Validation/prepare_validation.wls INPUT.wl
```

Input keys:

- `SolutionCampaignDirectory`, `OutputDirectory`, and common physical `Point`.
- `AMFlowRuntime`: explicit `AMFlowPath`, `KiraExecutable`, `FermatExecutable`.
- Optional `Threads`, `AMFlowPrecisionGoal`, `TimeLimit`, `EvaluationOptions`
  and `ComparisonOptions`.
- For stage 3, `AmplitudeReductionFile` and optional `BoundaryReferences`
  indexed by boundary input position. Missing references remain in the inventory.

The preparation reads all saved requested coefficient tables, rather than a
manually selected family list. It writes `complete_masters.json`, per-family
requests and `stage3.wxf`. Boundary demands come from the amplitude order plan.
Before running, changes to the family list, master identities or requested
orders require regeneration; an old inventory cannot silently omit new work.
The current process example and demonstrated coverage are in
`Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/Results/DoubleReal/Validation/TwoLevelValidation_2026-09-07`.

AMFlow runtime calls release their own parent subkernels before external
Wolfram solvers, allowing those solvers to use the requested worker licenses.
Pre-existing caller kernels are preserved. This prevents silent serial
fallback from exhausting the subkernel license allocation.

## Dynamic family pool and resuming

~~~bash
python3 Scripts/Validation/run_complete_master_validation.py MANIFEST.json \
  --workers 8 --resume --time-limit 14400
~~~

Workers cannot exceed the manifest's core budget (at most eight).
Preparation, AMFlow and physical DE comparison each use one core in family
mode. The time limit is seconds per phase. A fresh subkernel replaces each
finished family immediately, with explicit worker assignment to avoid
automatic requeueing during kernel replacement.

Resume validates the unchanged master/order inventory, retains current passed
comparisons, and reuses accepted AMFlow references for unfinished families.
It never counts a missing requested coefficient or a stale comparison after
worker failure as passing. Per-family pool_status.json records the worker PID,
assigned CPU, phase, thread settings and elapsed times. pool_state.json and
family_pool.log describe the dispatcher. The complete_master_report.json
always retains the full inventory.

The native AMFlow backend is built with Scripts/Transport/build_amflow_native.py
in a separate writable installation. To compare it against an existing
Mathematica reference with unchanged precision and epsilon orders:

~~~bash
wolframscript -file Scripts/Validation/benchmark_amflow_backend.wls \
  ORIGINAL_REQUEST.wl ORIGINAL_REFERENCE.wxf NATIVE_AMFLOW_DIRECTORY OUTPUT_DIRECTORY
~~~

This recomputes the reference numerically and compares all exported Laurent
coefficients at 20 digits. A copied symbolic AMFlow workspace under
OUTPUT_DIRECTORY/AMFlowWork can avoid repeating reductions; distinguish such
timings from an entirely fresh reference run. The test checks that native WSTP
links close afterward. No production boundary data enters AMFlow.
An optional final argument `FreshBoundaryOrders` recomputes AMFlow's boundary
orders in the copied workspace and requires them to match the original orders.
The production reference driver now selects a matching native installation
automatically. Completed numerical references are retained regardless of which
backend originally computed them; only new reference jobs use the new backend.
The benchmark also accepts SkipTargetReduction, NoMaximalCut or CachedSystems
as its final argument to test one change against the retained reference. It
records whether a symbolic workspace was actually present before execution.

The scope for generated AMFlow scripts is owned by
FeynFacetAMFlowRuntime, outside the contexts reset by FeynFacet.m. On Wolfram
14.2, ClearAll can defeat InheritedBlock restoration; the adapter uses Clear
and explicit attribute/option/default/message assignments instead. Both
Global and DESolver subcontexts are isolated. Existing workers are not reused
for another family.

## Full finite NLO scattering coefficients

`check_nlo_navis_references.wls UU_PROJECT LL_PROJECT` compares saved full
qq-prime, distinct-flavor annihilation and both qg observed tags against pinned
public Navis coefficients. It checks delta, both plus terms and the whole
regular coefficient at ten points. `Tests/Support/Navis/evaluate_reference.py`
compiles the unmodified upstream Rust files with `rustc`, without loading PDFs
or running Monte Carlo. Original sources remain under External/References,
and compact reports belong to each project/order/channel Results/Validation.
Missing inputs, unresolved symbols, wrong physical tags or failed comparisons
return a nonzero exit code. This is numerical finite-coefficient validation.
