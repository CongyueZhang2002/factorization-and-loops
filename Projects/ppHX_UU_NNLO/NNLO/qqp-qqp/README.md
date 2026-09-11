# ppHX UU NNLO: qq' -> qq' double-real workflow

Read [the repository workflow](../../../../WORKFLOW.md) first. This guide identifies
the current mathematical inputs and executable replay steps. It needs no chat
history. Commands below run from the repository root in WSL.

## Accepted result and precise scope

The accepted [Mathematica result](Results/DoubleReal/Assembly/Regeneration_2026-09-10/BareDoubleRealDistributions.wxf)
is **76,125,796 bytes**. It is the bare two-real-gluon contribution with ghost
subtraction for `u d -> observed u + d g g`. It spans epsilon^-8 through
epsilon^0 and retains delta derivatives 0-4 and generalized plus powers -5 to -1.

Its domain is `0 < v < 1/3`, with `z = 1-v-w`, the stored branch prescriptions,
smooth test functions at z=0 and support away from w=0. Other NNLO cuts,
UV renormalization and PDF/FF counterterms are not included. Do not call this
a complete finite NNLO hard function or claim global cancellation of the
higher endpoint distributions.

There are 345 terminal masters in the regenerated reduction, 343 nonzero
master coefficients, 91 saved mathematical DE families and 92 owned endpoint
contributions. These counts describe different objects.

## Current inputs and evidence

All paths below are relative to this channel.

| Role | Current location |
|---|---|
| Contribution definition | [Cards/DoubleReal.wl](Cards/DoubleReal.wl); shared physics in [project card](../../card.wl) |
| Reconstructed gluon coefficients | [Results/DoubleReal/Gluons/Reduction/CoefficientResult.wl](Results/DoubleReal/Gluons/Reduction/CoefficientResult.wl) |
| Reconstructed ghost coefficients | [Results/DoubleReal/Ghosts/Reduction/CoefficientResult.wl](Results/DoubleReal/Ghosts/Reduction/CoefficientResult.wl) |
| Normalized source trace and reconstruction stores | Results/CoefficientSimplification/DoubleReal/Gluons/Reduction/FiniteField |
| Raw DEs and explicit finite solutions | [Stage1And2_2026-09-06](Results/DoubleReal/UU_08_10_canonical/Stage1And2_2026-09-06/README.md) |
| Bound target master definitions | [SavedMasterCatalog.wxf](Results/DoubleReal/Regeneration_2026-09-10/SavedMasterCatalog.wxf) |
| Accepted physical endpoint systems | [AcceptedEndpointSystems.json](Results/DoubleReal/Regeneration_2026-09-10/AcceptedEndpointSystems.json) |
| Endpoint frame/bound catalog | [EndpointCoefficientCatalog.wl](Results/DoubleReal/Regeneration_2026-09-10/EndpointCoefficientCatalog.wl) |
| Physical normalization declaration | [PhysicalMasterDensityRequest.wxf](Results/DoubleReal/Assembly/Stage4_2026-09-07/PhysicalMasterDensityRequest.wxf) |
| Current assembly input requests | Results/DoubleReal/Regeneration_2026-09-10 |
| Current assembly products | [Assembly/Regeneration_2026-09-10](Results/DoubleReal/Assembly/Regeneration_2026-09-10/README.md) |
| Automatic order/partition planning | [Regeneration_2026-09-11](Results/DoubleReal/Regeneration_2026-09-11/README.md) |
| Completed eight-core reconstruction check | [EightCoreReconstruction](Results/DoubleReal/Regeneration_2026-09-11/EightCoreReconstruction/README.md) |

A dated folder can hold a current dependency. The old Stage4_2026-09-07
**assembled distribution** is superseded; its explicitly referenced physical
normalization and boundary-construction inputs remain in use. Do not delete
that tree merely because its date is older.

Accepted evidence: 2,130 modular reconstruction comparisons; contraction of
1,408 retained AMFlow master coefficients from 91 families at (v,w)=(1/4,1/5);
all 92 endpoint contributions; exact output read-back and compaction identity.
Eighty nonempty endpoint contributions have passing epsilon audits; twelve
empty contributions record NoChecksExecuted. The broader historical complete-
master audit and the separate incomplete boundary-only reference inventory are
described in [validation](../../../../Scripts/Validation/README.md).

## Shell setup

```bash
cd /home/maxzhang/factorization-and-loops
C=Projects/ppHX_UU_NNLO/NNLO/qqp-qqp
B="$C/Results/DoubleReal"
D0="$B/Regeneration_2026-09-10"
D1="$B/Regeneration_2026-09-11"
A="$B/Assembly/Regeneration_2026-09-10"
TRACE="$C/Results/CoefficientSimplification/DoubleReal/Gluons/Reduction/FiniteField"
wl8() { taskset -c 0-7 env FACET_CPU_COUNT=8 wolframscript -file "$@"; }

# Choose an unused output directory. mkdir deliberately fails if it exists.
OUT="$B/Replay"
mkdir "$OUT"
```

The examples use retained accepted mathematical inputs. They do not launch a
fresh full NNLO calculation. Every driver must exit successfully, print its
completion marker and produce the expected mathematical artifact.

## Inspect or replay final assembly

Read the result without expanding its large shared definitions:

```wl
result = Import[
 "Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/Results/DoubleReal/Assembly/Regeneration_2026-09-10/BareDoubleRealDistributions.wxf",
 "WXF"];
Keys[result]
```

To repeat only the last distribution assembly into a new file:

```bash
wl8 Scripts/Coefficients/assemble_endpoint_subtracted_density.wls \
  "$D0/EndpointAssemblyRequest.wl" "$OUT/BareDoubleRealDistributions.wxf"
```

This reuses the accepted interior and scalar endpoint solutions named by the
request. It is not a fresh boundary calculation. Check the output summary and
epsilon-audit sidecar, contribution ownership, exact read-back and stated domain.

## Prepare optimized coefficient jobs automatically

```bash
wl8 Scripts/prepare_coefficient_reconstruction.wls \
  "$TRACE" "$C" DoubleReal.Gluons "$OUT/ReconstructionPlan.wl"
```

Expected marker: `COEFFICIENT RECONSTRUCTION PLAN COMPLETE`. This prepares
partitions and order proofs; it does not interpolate or solve masters. Derived
partitions are written under the trace's Compacted/ReconstructionPlan directory.
For isolated preparation, use the three-argument form with a request whose
PlanDirectory points into the new replay directory.

The card supplies endpoint/normalization inputs and the requested result order.
The current source discovers two expensive outputs and epsilon^1 for their
regular parts, with 257 exact exceptional summands per output. Those numbers
are regression observations, never production selection rules.
The physical prefactor lower bound is 0; the active physical sector has lower
bound 0 and nilpotency index 1, so target 0 needs rational order 1.

A saved finite plan requires current ReconstructionOrderInputs on execution.
Changing the requested order, normalization, coordinates, domain, accepted
bounds or source DE invalidates reuse. An unsupported analysis can retain a
column exactly; missing/stale declared inputs must fail.

## Repeat the two-expansion performance check

Create a new operational request that inherits the accepted benchmark's checked
orders and overrides only its output directory:

```bash
cat > "$OUT/FiniteJobs.wl" <<EOF
Join[
 Get["$PWD/$D1/EightCoreReconstruction/RerunRequest.wl"],
 <|"OutputDirectory" -> "$PWD/$OUT/FiniteJobs"|>
]
EOF
wl8 Scripts/reconstruct_trace_jobs.wls "$TRACE" "$OUT/FiniteJobs.wl"
```

Expected marker: `RECONSTRUCTION JOBS COMPLETE`. Both jobs must log eight
native threads. The source request forces fresh interpolation, verifies
current mathematical bindings and leaves the accepted coefficient files alone.

Check the new coefficients against the accepted source traces:

```bash
PYTHONPATH=Scripts:Scripts/Validation python3 - "$OUT" "$D0" <<'PY'
import json, sys
from pathlib import Path
from check_reconstructed_trace import check
out, accepted = map(Path, sys.argv[1:])
for job, label in [("solo_000003", "Regular22"), ("solo_000001", "Regular20")]:
    request = json.loads(
        (accepted / "ReconstructionValidation" / label / "Request.json").read_text())
    request["RecordFile"] = str((out / "FiniteJobs" / f"rec_{job}.txt").resolve())
    request.pop("AlternativeTrace", None)
    request.pop("OutputNameMap", None)
    report = check(request, out / "Validation" / job)
    assert report["Passed"], report
    print(job, report["Comparisons"], "passed")
PY
```

This checks all ten scalar epsilon coefficients at three points over two primes
(60 exact modular comparisons). The accepted eight-core check additionally
established byte equality with all ten previous expressions. Its **10.5 min**
is the two-job driver time, including input checks; the earlier one-thread run
took 80.2 min. This is not the time for all coefficients or for DE solving.

## Full phase map for an intentional regeneration

Use the [general upstream manifest](../../../../WORKFLOW.md#starting-or-resuming-a-calculation)
with **both** `DoubleReal.Gluons` and `DoubleReal.Ghosts`. The physical assembly
weights come from the contribution card, not a hand-entered ghost sign.
GeneratePairs, ReducePairs/ImportReduction and ReconstructCoefficients produce
the current component coefficient tables. They do not execute all phases below.

| Phase | General driver | Retained input / output contract |
|---|---|---|
| Exact source-to-saved-master matching | `match_cut_integral_catalogs.wls REQUEST OUTPUT.wxf` | GluonsCatalogRequest.wl / GhostsCatalogRequest.wl |
| Compose established integral relations | `reduce_matched_integral_catalog.wls RELATION_REQUEST MATCH OUTPUT.wxf` | SavedIntegralRelationRequest.wl and each fresh match |
| Weighted cut sum | `Coefficients/assemble_cut_coefficients.wls REQUEST.wl` | CutAssemblyRequest.wl; OutputFile is inside the request |
| Physical normalization | `Coefficients/construct_physical_master_density.wls REQUEST OUTPUT.wxf` | PhysicalDensityRequest.wl; derives definitions through general code |
| Accepted endpoint catalog | `Coefficients/build_endpoint_coefficient_catalog.wls CUT_CATALOG ACCEPTED_ENDPOINTS OUTPUT.wl` | SavedMasterCatalog.wxf + AcceptedEndpointSystems.json |
| Complete coefficient endpoint groups | `Coefficients/prepare_endpoint_coefficient_groups.wls REQUEST CATALOG OUTPUT_DIRECTORY` | EndpointInputRequest.wl; returns manifest.json with all owned contributions |
| Physical interior | `Coefficients/assemble_finite_master_density.wls REQUEST OUTPUT.wxf` | FiniteDensityRequest.wl and the saved finite solutions |
| Scalar endpoint functions | `Coefficients/construct_scalar_endpoint_families.wls REQUEST OUTPUT_DIRECTORY` | ScalarEndpointCampaign.wl; CoefficientInputFiles must come from the fresh group manifest |
| Final distributions | `Coefficients/assemble_endpoint_subtracted_density.wls REQUEST OUTPUT.wxf` | EndpointAssemblyRequest.wl; must reference every fresh scalar endpoint and the fresh interior |

Driver paths in the table are relative to Scripts; retained request basenames
are under D0 above. Consult [assembly contracts](../../../../Scripts/Coefficients/README.md)
and [scalar campaign contracts](../../../../Scripts/Coefficients/ScalarEndpointDriver.md).

For a new replay of several phases, construct new request associations in OUT
and update their typed input/output fields in dependency order. For example:
CoefficientFile/PhysicalCoefficientTable must name the new predecessor;
CutAssemblyRequest's OutputFile is embedded; ScalarEndpointCampaign's
CoefficientInputFiles come from the new manifest; final InteriorDensity and
EndpointSolutions must point to the new products. Do not run the old request
list blindly: some saved requests write directly into the accepted directory.

For a new geometry, unmatched master, changed boundary data or different order
demand, first use the [DE](../../../../Scripts/Transport/README.md) and
[boundary](../../../../Scripts/Boundary/README.md) constructors with supported
mathematical inputs. The current card's optimized coefficient plan assumes an
accepted endpoint catalog exists. There is not yet one verified command that
builds every new NNLO boundary specification from arbitrary cards.

## Recovery and handoff

Use the newest relevant RunState.json plus mathematical artifacts, not an old
log's status. Files beginning WrongColorContext, BeforeCancellation, recovery
attempts, *.failure.wxf and the historical ProductionReconstructionPlan.wl are
diagnostic records, not default replay commands.

Preserve compatible completed reduction, reconstruction, DE and AMFlow work.
After a failure, repair the general implementation and rerun affected phases.
Never insert coefficient factors or manually edit a stored integral to match
an external result. A count of families alone cannot prove epsilon coverage,
integral identity, contribution ownership or successful endpoint audits.

Update this guide and the run's README/RunState when accepted locations,
scope or commands change. No production jobs or heartbeat are currently active.
