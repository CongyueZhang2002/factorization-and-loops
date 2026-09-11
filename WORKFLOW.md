# Running FeynFacet without conversation history

Start here, then read the selected project's guide and [STATUS.md](STATUS.md).
[AGENTS.md](AGENTS.md) contains implementation conventions and known traps.
Historical logs explain decisions; they are not the current execution plan.

## What is ready

| Task | Supported entry point | What it establishes |
|---|---|---|
| Supported complete NLO channel | `Scripts/run_nlo_hard_function.wls PROJECT CHANNEL all` | Born dependencies, real, virtual, counterterms and the common NLO result |
| Card-owned upstream scattering calculation | `Scripts/run_contribution_stages.py MANIFEST.json` | Only the stages explicitly listed in the manifest |
| Closed DE to explicit master solution | [Transport guide](Scripts/Transport/README.md) | Requested master epsilon coefficients; physical boundary constants are a separate step |
| Physical boundary construction/integration | [Boundary guide](Scripts/Boundary/README.md) | Supplied physical-limit equations, sufficient orders and evaluated constants |
| Coefficient/endpoint assembly | [Assembly guide](Scripts/Coefficients/README.md) | The contributions, endpoint domains and orders declared by its mathematical inputs |
| Current ppHX NNLO double real | [Channel workflow](Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/README.md) | Two real gluons with ghost subtraction, with higher endpoint distributions retained |
| Current complete SIDIS NNLO UU/LL | [UU](Projects/SIDIS_UU_NNLO/NNLO/README.md), [LL](Projects/SIDIS_LL_NNLO/NNLO/README.md) | Complete saved channel results, final-assembly replay and independent reference checks |

There is **no single verified card-to-full-hard-function NNLO command for an
arbitrary new process**. General algorithms take cards plus integral definitions,
closed systems, boundary/endpoint specifications and order requests. Supported
NLO orchestration and retained NNLO replay are more automatic than construction
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
out = Path("Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/Results/Validation/AgentStartup")
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
  card.wl                        shared physical conventions
  LO/CHANNEL/Cards/Born.wl
  LO/CHANNEL/Results/Result.wl
  NLO/CHANNEL/Cards/{Real,Virtual,Counterterm}.wl
  NLO/CHANNEL/Results/Result.wl
  NNLO/CHANNEL/Cards/DoubleReal.wl
  NNLO/CHANNEL/{Results,Kira}/...
```

Components such as `DoubleReal.Gluons` come from one contribution card.
Counterterm cards declare lower-order result paths and required epsilon ranges;
the common partonic format is used at both orders. Read
[the card/result contract](Design/ProjectCardsAndResults.md). Do not use the
retired Julia-card idea or old project layouts.

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

**NLO:** for an existing supported project/channel:

```bash
wl8 Scripts/run_nlo_hard_function.wls ppHX_UU_NNLO qqp-qqp all
```

`resume` requests reuse according to the NLO orchestration; `assemble` assembles
existing contributions and must not regenerate missing Born inputs. Check
`NLO_PROJECT_COMPLETED`, exit status and `NLO/CHANNEL/Results/Result.wl`.
`all` is the complete workflow mode, not a promise to ignore every valid cache.

**Upstream NNLO scattering:** write a project-owned JSON manifest, for example
under the chosen channel's `Results/Validation`:

```json
{
  "CpuSet": [0, 1, 2, 3, 4, 5, 6, 7],
  "Report": "UpstreamReport.json",
  "Jobs": [{
    "Project": "ppHX_UU_NNLO",
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

**ppHX NNLO replay:** use the [exact input/output map and commands](Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/README.md).
**SIDIS NNLO replay:** use the completed project guides above; the final-assembly
command reuses solved profiles and does not regenerate diagrams or masters.

## Completion, validation and recovery

- A zero process exit is insufficient: a missing Wolfram script can exit zero.
  Require the driver's completion marker and its expected artifact/status.
  `run_wolfram` additionally requires `FEYNFACET DRIVER ENTERED`. Some older
  standalone DE/NLO adapters do not print that marker: run those through their
  documented launcher and inspect the output contract, rather than weakening
  the common runner's checks.
- JSON timings/progress are operational. Exact WXF/WL records carry mathematical
  definitions, normalizations, epsilon ranges, coordinate maps and bindings.
  `FamilyArtifactRead` reads the package's text/compressed records;
  `Import[file,"WXF"]` reads WXF. Use the standalone solution reader when a
  solution references shared finite definitions.
- Resume only with matching inputs and sufficient orders. Changed cards,
  normalizations, endpoints, source DEs or demands invalidate relevant records.
  Do not edit a success marker or copy a finished status onto new inputs.
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
