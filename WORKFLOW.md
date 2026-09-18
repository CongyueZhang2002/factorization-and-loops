# Running FeynFacet without conversation history

Start here, then read the selected project's guide and [STATUS.md](STATUS.md).
[AGENTS.md](AGENTS.md) contains implementation conventions and known traps.
Historical logs explain decisions; they are not the current execution plan.

## Raw contributions and result assembly

Read [the card contract](Design/ProjectCardsAndResults.md). Raw contributions
retain poles; only a complete result card requires the full contribution
inventory and exact cancellation. Counterterms are stored under the channel
of their perturbative amplitude. Result cards can select an explicit
OutputChannel from another source channel's Counter-PDF/FF/UV Results.wl.
Each channel component uses the same common partonic-result format. Counterterms regenerate source densities
from common physics, without reads of standalone lower-order results.

Physical normalization is owned by [FeynFacet/Normalization](FeynFacet/Normalization/README.md).
Declare the observable/tensor convention and particle content in cards; symmetry,
flavor multiplicities, bare-coupling rules and collinear weights/maps are derived.
Do not reinsert an independent factor to make a benchmark agree. Integrated
tagged densities must pass the generic-dimension measurement-covariance check
before ordinary Mellin counterterms are used. Endpoint powers and regularity
conditions are determined from the generated density, not handwritten True flags.

```bash
# Plan one explicit selection.
wolframscript -file Scripts/run_project_result.wls \
  Projects/DrellYan_UU/Results/NLO/q-qb/Result_Card.wl plan

# Regenerate all NLO result cards with two supervised kernels / eight CPUs total.
python3 Scripts/run_project_results.py --order NLO --mode all \
  --report "Reports/$(date +%F)/NLO_Run.json"

# Independently generate a single raw contribution.
wolframscript -file Scripts/run_raw_contribution.wls \
  Projects/DrellYan_UU/Raw/NLO/q-qb/Real/Card.wl all
```

Use `Scripts/wolfram.py` supervision for standalone production drivers too.
Completion requires the entry marker, completion marker and exit zero.
Do not start another kernel alongside the two-kernel campaign.

Raw directories contain `Card.wl`, `Results.wl` and `Work/`. Assembled channels
contain `Result_Card.wl`, `Results.wl` and timing/validation records.
Readable `.wl` results and intermediates have a `.meta.wxf` companion; keep
both files together. See [the record format](Design/ReadableRecords.md).
`assemble` only reads selected results. `resume` validates the exact effective
definition and epsilon coverage. `all` regenerates the ordinary amplitude
pipeline. Source reuse is limited to matching consumer-owned work or the
current run's mathematical source cache.

NLO runs use the ordinary amplitude pipeline. NNLO raw contributions use their
prepared integral inputs: explicit solved endpoint coefficients or reduced virtual
integrals with a declared scalar library. The same counterterm and result-selection
workflow applies at either order.

The old prepared NLO/NNLO calculations and masters were deleted on
16 September. The current fresh campaign uses:

~~~bash
python3 Scripts/run_fresh_projects.py MANIFEST.json
~~~

The manifest selects projects and explicit orders, CPUs 0–7, and a report.
Projects run sequentially. Fresh preflight rejects every generated file in the
selected order, including cached masters. Measured master preparation first
uses exact affine relations and a unit-cut basis, then individually certified
ordinary-prescription equivalences and differential closure. Do not omit the
second step: the fresh SIDIS audit reduced 62 integrals to 20 through it.
This equivalence is at generic kinematics; the subsequent resolved endpoint
construction is still necessary. For NNLO it first runs
prepare_project_upstream.wls inside the timed interval and executes every
generated stage before final assembly. The Upstream manifest path must belong
to the active project. The current ordered measured-boundary producer requires
a verified endpoint construction; it fails if the generated geometry is
unsupported. See STATUS.md for what has actually completed. Neither all nor
resume on a prepared NNLO contribution alone is a fresh master calculation.

## Reports and completed run records

Physics projects alone belong under Projects. Human-readable reports, summary
tables and accepted campaign summaries belong under Reports/YYYY-MM-DD/.
Create a date directory only when it contains a report. Keep a TeX table and
its compiled PDF together. Result files and operational per-channel timing/
validation records stay with their owning calculations.

Completed attempt logs, superseded reports and one-off migration/recovery
scripts belong under Archive/Runs. Use the maintained drivers in Scripts for
new work; archived campaign scripts are historical source, not entry points.

The September 10–13 status tables and campaigns are historical: their generated
NLO/NNLO data was subsequently deleted. Current fresh timing, coverage and
verification are recorded in [the September 16 report](Reports/2026-09-16/NNLOImprovementsAndRegeneration.md).
Per-channel time remains owned raw-folder work plus assembly; the fresh
project/order total also counts all upstream stages, startup and cleanup. Master
generation is an explicitly timed production stage, even though later drivers
read its files. Shared master work is charged once to its raw-channel owner,
not repeated for every consuming channel. Resuming a stage retains its original
generation cost. Reports distinguish successful stages from failed/superseded
attempts and independent checks; an assembly replay is never a fresh total.

Completed saved results can be checked without regeneration:

~~~bash
wolframscript -file Scripts/Validation/check_project_results.wls DrellYan_UU NLO q-g
~~~

Verify the regenerated NLO coefficients against the external reference drivers
in [validation directions](Scripts/Validation/README.md). Old produced NLO
coefficients are not retained as comparison baselines.

## What is ready

| Task | Supported entry point | What it establishes |
|---|---|---|
| Compiled Born/real/virtual contribution | ``FeynFacet`EvaluateBareContribution[compiledCard, mode]`` | Shared ordinary/source pipeline with requested epsilon coverage and consumer-owned files |
| Supported complete NLO channel | `Scripts/run_project_result.wls RESULT_CARD all` | Automatically generated counterterm sources, real, virtual, counterterms and the common NLO result |
| Card-owned upstream scattering calculation | `Scripts/run_contribution_stages.py MANIFEST.json` | Only the stages explicitly listed in the manifest |
| Fixed-high-pT polarized SIDIS current | [Project guide](Projects/SIDIS_HighPT_TT_SpinTransfer/README.md) | Independent explicit q/qb NLO hard coefficients with exact pole cancellation and physical spin projections |
| Closed DE to explicit master solution | [Transport guide](Scripts/Transport/README.md) | Requested master epsilon coefficients; physical boundary constants are a separate step |
| Physical boundary construction/integration | [Boundary guide](Scripts/Boundary/README.md) | Supplied physical-limit equations, sufficient orders and evaluated constants |
| Coefficient/endpoint assembly | [Assembly guide](Scripts/Coefficients/README.md) | The contributions, endpoint domains and orders declared by its mathematical inputs |
| ppHX NNLO double real | Retained Raw/NNLO declaration cards | Old calculations deleted; regeneration excluded from the current campaign |
| Fresh SIDIS NNLO UU/LL | Scripts/run_fresh_projects.py | Newly connected upstream producer; see STATUS.md for execution and remaining limits |

There is **no single verified card-to-full-hard-function NNLO command for an
arbitrary new process**. General algorithms take cards plus integral definitions,
closed systems, boundary/endpoint specifications and order requests. Supported
NLO orchestration and saved NNLO phase inputs are more automatic than construction
of previously unsupported geometry. Do not silently supply a new boundary
constant, discard a pole, or substitute a literature coefficient to complete a run.

## Installation and first check

The current working installation is WSL **Ubuntu**:

```bash
cd /home/maxzhang/factorization-and-loops
git status --short
```

From Windows PowerShell, enter it with:

```powershell
wsl.exe -d Ubuntu --cd /home/maxzhang/factorization-and-loops
```

Windows file access is through
`\\wsl.localhost\Ubuntu\home\maxzhang\factorization-and-loops`.

Required components depend on the selected stage:

| Component | Purpose / location |
|---|---|
| Licensed `wolframscript` / Wolfram kernel | Symbolic package, drivers and physical normalization |
| `Addon/Load/LoadFACET.wl` and FeynCalc dependencies | Full symbolic/diagram entry point |
| Kira and its dependencies | IBP reduction; runtime paths come from installation configuration |
| `Addon/Other_Addon/Ratracer/bin/ratracer` | Native rational/epsilon-series reconstruction |
| FLINT numerical backends | Compiled finite-integral and Frobenius evaluation; [build/usage](Scripts/Transport/README.md) |
| AMFlow and optional AMFlowNative | Independent physical-master checks; [runtime instructions](Scripts/Transport/README.md#native-amflow-reference-solver) |
| Python 3 and stage-specific modules | Launchers/checkers; e.g. SymPy for prime validation |
| Optional GiNaC / SubTropica | GPL evaluation / boundary-integration backend; use only for the requested method |

Several vendor paths are local symlinks. **`~/FACET` is frozen and read-only.**
A Git clone alone does not include ignored calculation results, all vendor
installations or Wolfram licences. A new machine needs these installed and its
mathematical inputs regenerated or explicitly restored. Saved requests can contain
absolute paths: rebuilding their bindings is preferable to blindly replacing
path strings inside accepted mathematical artifacts.

A cheap package/CPU check, from the repository root:

```bash
PYTHONPATH=Scripts python3 - <<'PY'
from pathlib import Path
from wolfram import run_wolfram, atomic_json
out = Path("Archive/Runs/AgentStartup")
result = run_wolfram(
    "Tests/Core/t_native_thread_allocation.wls", [],
    logfile=out / "native_threads.log",
    completion="ALLOCATED CPUS ", cpus=[0], timeout=120)
atomic_json(out / "Report.json", result)
print(result)
raise SystemExit(0 if result["Passed"] else 1)
PY
```

This loads the package and tests allocation; it does not regenerate physics or
prove that every optional backend is installed. Check the executables used by
the intended stage before launching it.

## CPU and kernel policy on this installation

- Use at most **eight total CPU cores** and at most **two main Wolfram kernels**.
  Normally use one main kernel controlling native threads or up to eight
  subkernels. A fresh-kernel test may itself start a second main kernel.
- Python production launchers use `Scripts/wolfram.py`. Its CPU affinity and
  `FACET_CPU_COUNT` bound native work; it preserves owned-process cleanup.
- Native reconstruction thread counts are independent of Wolfram's licence
  limit and `OMP_NUM_THREADS`. The common queue runs one native job at a time
  with its requested available CPU budget.
- Do not recreate the old fixed **7+1** ordinary/finite split. It left the last
  finite job serial after seven cores became free.
- A manifest's `Execution` fields are explicit. `run_contribution_stages.py`
  currently defaults omitted stage thread counts to **1**, rather than reading
  the root card's Execution association. Supply the fields shown below.
- For direct Wolfram examples in these guides, this shell helper bounds the run
  on the current machine:

```bash
wl8() { taskset -c 0-7 env FACET_CPU_COUNT=8 wolframscript -file "$@"; }
```

Do not run two `wl8` calculations concurrently. On a different host choose valid
CPU IDs from its allocation. Long runs need an external supervisor and regular
progress inspection; a heartbeat is not required. The existing heartbeat is
paused and must not be assumed to be supervising anything.

## Cards, files and stage meanings

```text
Projects/PROJECT/
  Common-Card.wl
  Raw/ORDER/CHANNEL/CONTRIBUTION/{Card.wl, Results.wl, Work/}
  Results/ORDER/CHANNEL/{Result_Card.wl, Results.wl, RunReport.wl}
```

Raw contributions retain all computed poles. Result cards own input selection,
completeness checks, cancellation and requested finite extraction. A source
inside a counterterm's Work directory is not another assembly input.
Project names have no order suffix; antiquarks use qb/qpb (explicit flavors
ub/db). Old NLO outputs, including archived copies, have been deleted.
A project/species rename invalidates private cached process identities: use
all for new upstream work. Preserved binary solver records retain their original
provenance; fresh NLO results are regenerated and independently validated.

See [the card contract](Design/ProjectCardsAndResults.md) for details.

The scientific stages used in this project are:

1. **Before master solving:** diagrams, Hermitian interference reduction,
   physical projector/measurement data, equivalent-family construction, IBP,
   master identities and rational coefficient input.
2. **Stage 1:** closed master DEs and any basis/coordinate preparation actually
   needed by the finite solver. Integral-family canonicalization and DE
   epsilon-form canonicalization are different operations.
3. **Stage 2:** sufficient epsilon orders and explicit finite DE solutions up to
   constants. Full epsilon-form conversion and GPL conversion are optional.
4. **Stage 3:** physical boundary integral equations, integration, connection
   and substitution of constants. A stage-2 file alone does not establish this.
5. **Stage 4:** physical coefficient contraction, endpoint distributions and
   the requested contribution/result assembly. A bare double-real distribution
   is not the sum of all NNLO real, virtual, UV and PDF/FF terms.

The dependency graph matters more than these labels. Optimized finite
coefficient reconstruction needs physical endpoint bounds **before** deciding
its truncation. Current replay uses accepted bounds. For a new geometry first
construct the required DE/boundary data, or use full rational reconstruction
without declaring unsupported finite-order inputs. Never guess epsilon^5 or
another safety margin.

## Starting or resuming a calculation

**NLO:** use an explicit result card with `run_project_result.wls` or
the supervised `run_project_results.py` queue shown above. Completion is
`PROJECT_RESULT_COMPLETED` plus exit zero. An accepted finite result is
`Results/NLO/CHANNEL/Results.wl`.

**One raw contribution:** use `run_raw_contribution.wls PATH/TO/Card.wl all`.
Completion is `RAW_CONTRIBUTION_COMPLETED`. It neither discovers other raw
outputs nor requires their cancellation. Prepare new cards with
`PrepareProjectChannel[projectDirectory, order, channel, lowerBounds]`, where
`lowerBounds` maps ordinary contribution names to established Laurent lower
bounds including all prefactors. LO defaults to zero; non-LO preparation refuses
missing bounds instead of guessing a universal pole order. Counterterm kernels
and finite redefinitions remain explicit physics inputs where provider data
are unavailable.

The general invariant operator and a complete symbolic real-source convolution
are documented in [InvariantCollinearConvolutions.md](Design/InvariantCollinearConvolutions.md).
The former ppHX NNLO demonstration outputs were deleted with the old
calculation. The maintained tests exercise the operator; historical output
paths are not available production inputs.

**Upstream NNLO scattering:** write a project-owned JSON manifest, for example
under the chosen channel's `Results/Validation`:

```json
{
  "CpuSet": [0, 1, 2, 3, 4, 5, 6, 7],
  "Report": "UpstreamReport.json",
  "Jobs": [{
    "Project": "ppHX_UU",
    "Order": "NNLO",
    "Channel": "qqp-qqp",
    "Contribution": "DoubleReal.Gluons",
    "Execution": {
      "Kernels": 8, "KiraThreads": 8,
      "ReconstructionThreads": 8, "NormalizationKernels": 8
    },
    "Stages": ["GeneratePairs", "ReducePairs", "ReconstructCoefficients"]
  }]
}
```

```bash
python3 Scripts/run_contribution_stages.py PATH_TO_MANIFEST.json
```

This writes the selected contribution's canonical result locations. It can
replace upstream output: use it for an intentional regeneration, not to inspect
an accepted result. Add each required card component explicitly. The ppHX
channel guide identifies the gluon and ghost components and downstream inputs.
`ImportReduction` imports a compatible retained Kira workspace instead of
rerunning its reduction; it is not a way to ignore an incompatible database.

**Master solving and boundary evaluation:** use the
[Transport](Scripts/Transport/README.md) and [Boundary](Scripts/Boundary/README.md)
adapters with explicit mathematical specifications. Existing campaigns have
retained specification files; read their embedded paths and output destinations
before reuse. A new process may require new supported physical-limit data.
The complete generic NNLO phase sequence is not encoded by the upstream
manifest alone.

**ppHX NNLO:** only declaration cards remain; it is excluded from the current
fresh campaign. **SIDIS NNLO:** use the fresh-project runner and an owned
upstream-manifest destination. Final assembly alone does not regenerate
diagrams or masters.

## Shared master-integral values

The package now consults `Library/MasterIntegrals` before supported master
evaluation. It checks the actual integral definition, analytic domain,
normalization, prescriptions and epsilon coverage; family/project names do not
identify an integral. Exact functions or fully explicit physical Laurent
coefficients are stored after evaluation. Free-boundary DE solutions are not
eligible.

Normal calculations use `ReadWrite`; the fresh-project supervisor defaults to
`Recompute` so shared values do not disappear from cold timing. A complete
measured-DE library hit skips master integration; a partial hit now supplies known physical Laurent coefficients to the
prepared inhomogeneous DE and evolves missing coefficients on demand. Boundary preparation for endpoint distributions
still has its own role. See [the full API and scope](Design/SharedMasterIntegralLibrary.md)
before changing the directory/mode or importing existing solutions.

## Coefficient source and checkpoint ownership

The producer finishes and joins its diagram-pair queue before family reduction
and coefficient reconstruction consume the files. Pair records and their
`.meta.wxf` companions must remain unchanged throughout those downstream stages.
Do not run `all` into the same contribution Work directory while another command
is reading it; use a separate contribution workspace for independent runs.

Large record batches use the allocated symbolic workers for independent reads
and canonical write/read-back checks. The registry itself is constructed in
deterministic filename order. Canonicalization also accepts complete in-memory
pair records and validates them identically; the raw driver passes its already
loaded records. ReturnRecords -> True also returns the checked canonical
records for an immediate Kira call, without changing the saved manifest or
skipping Kira validation. The raw driver verifies the canonical file inventory
and releases those records after import; Kira solve handles keep only their
derived input summaries.
Worker pools are closed by their owner, and nested serial scopes remain serial.
Small inputs avoid worker startup.

Cold coefficient collection validates each source once while collecting its
coefficients. It builds temporary target records and replaces an existing store
only after the source, reduction and target checks pass. Mandatory writes are
checked. Warm reuse compares the exact target inventory and topology mapping;
trace reuse also compares analytic context, physical factor and effective target
coverage. A checkpoint lacking the current normalization definition must be
regenerated. These checks use existing source provenance and exact definitions,
without new content hashes. Reuse also compares the binary companion bytes
exactly; changing or removing only a companion invalidates cached sources,
target records, normalized traces and final coefficient reuse. These snapshots
stay in binary metadata.

Coefficient normalization expands each distinct external scalar product once
with the declared hadronic coordinates, then substitutes its exact image.
Other tensor structures and singular intermediate substitutions use the original
whole-expression evaluator. Polynomial cancellation and epsilon-order handling
are unchanged.

## Completion, validation and recovery

- A zero process exit is insufficient: a missing Wolfram script can exit zero.
  Require the driver's completion marker and its expected artifact/status.
  `run_wolfram` additionally requires `FEYNFACET DRIVER ENTERED`. Some older
  standalone DE/NLO adapters do not print that marker: run those through their
  documented launcher and inspect the output contract, rather than weakening
  the common runner's checks.
- JSON timings/progress are operational. Exact WXF/WL records carry mathematical
  definitions, normalizations, epsilon ranges, coordinate maps and bindings.
  `FamilyArtifactRead` restores readable text plus its `.meta.wxf` companion;
  `Import[file,"WXF"]` reads WXF. Use the standalone solution reader when a
  solution references shared finite definitions.
- Resume only with matching inputs and sufficient orders. Changed cards,
  normalizations, endpoints, source DEs or demands invalidate relevant records.
  Do not edit a success marker or copy a finished status onto new inputs.
- A sequential campaign can continue with
  `python3 Scripts/run_fresh_projects.py MANIFEST.json --resume`.
  The campaign retains exact card text and its generated upstream recipe in a
  report companion, without hashes. Completed stages are skipped only within
  that recorded campaign; changed cards/recipes are rejected. Mathematical
  consumers still validate their exact source definitions and required orders.
  If a later consumer discovers an invalid completed result, use
  `--rerun-from PROJECT ORDER STAGE --reason "explanation"` with `--resume`.
  This invalidates that stage and its descendants in the recorded linear recipe.
  Historical outcomes remain recorded; discarded successful attempts have a
  separate timing category.
  Failed attempts keep separate logs. A resumed order reports successful,
  failed and total measured execution seconds, not an uninterrupted wall time.
- Preserve completed valid work after failure. Read the first failed stage,
  fix the general code/input declaration, and rerun that stage and its affected
  descendants. Do not restart Kira or AMFlow solely because assembly failed.
- `MissingOrders`, unresolved constants/classes, deferred jobs, `NotChecked`
  and `NoChecksExecuted` are not passing numerical checks. Empty endpoint
  contributions can be valid but have no nonempty epsilon audit.
- Use cheap rational/modular checks for algebra changes. Check coverage first.
  Boundary-only validation and full physical-master comparisons against AMFlow
  are [separate tests](Scripts/Validation/README.md). Independent published
  hard coefficients belong only in validation.
- Keep checks proportionate. Do not repeat the whole AMFlow campaign for a
  CPU-scheduling or documentation change.
- Record clock type, core count, scope and reused stages with timings. The
  10.5-minute benchmark covers **two coefficient expansions**, not all NNLO.
- If a nontrivial mathematical decision remains unclear, consult actual
  **GPT-6 Pro** through [the bridge](External/ChatGPT/README.md), preserve the
  prompt/source/response, and verify the model. Extra-high reasoning alone
  does not establish that the responder was Pro.

Before handing off, update STATUS.md, the affected project guide and its
project-owned run report with accepted artifacts, coverage, pending work and
owned process IDs. No future agent should need the conversation to identify
the current result or the next executable step.


The explicit GPL conversion stage retains partial successful conversions.
A retry reuses them only when exact source definitions match and the new
parameter domain implies the stored assumptions. The readable
PhysicalMasterFiniteSolution is the completed finite iterated-integral DE
solution; PhysicalMasterGPLSolution can still be partial. Only the explicit
GPL output and a successful driver completion permit bulk contraction.
The converter supports one quadratic root or a pair of affine roots with
nonzero basepoint values; unsupported root fields remain explicit failures.
Charts preserve the original continued root phases and unit tangent. Parameter
assumptions come from the physical boundary card; inferred sign facts are proved
from it. The GPL FunctionTimeLimit and total TimeLimit are separate resource
bounds, not mathematical existence criteria.

## Polynomial final-state measurements

The complete card-driven massless LO EEC example is [Projects/EE_EEC](Projects/EE_EEC/README.md). It uses the standard `Scripts/run_project_result.wls` entry point, with polynomial measurement geometry selecting the general measured-current stages. See [PolynomialMeasurements](Design/PolynomialMeasurements.md) for supported geometry and endpoint semantics.
