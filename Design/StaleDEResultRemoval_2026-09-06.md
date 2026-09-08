# Stale DE result removal, 2026-09-06

Removed 5.721 GB of obsolete run files.
After preserving required inputs, regression fixtures and source notes, the net
reduction in file content is approximately 5.703 GB.
Sizes are decimal file bytes; filesystem allocation differs.

The full [removal manifest](../ppHX_NNLO_DoubleReal/Results/Validation/ResultOrganization_2026-09-06/PreviousRecords/StaleDEResultRemoval_2026-09-06.json) records exact paths,
file counts, sizes, preserved dependencies and post-deletion checks.
Results were deleted rather than moved to another result archive.

## Removed runs

| Removed run | MB |
|---|---:|
| Stale/…/2026-09-03_pre_v2 | 4854.36 |
| Scripts/ppHX_NNLO_DoubleReal/Results | 188.69 |
| …/UU_08_10_canonical/DifferentialEquationDataV2 | 122.65 |
| …/UU_08_10_canonical/Overnight_2026-09-06 | 38.67 |
| …/UU_08_10_canonical/MasterIntegralSolutions | 195.13 |
| ppHX_NNLO_DoubleReal/Results/RequestedMasterIntegralSolutions | 19.41 |
| Codex/TwoRootCF231Audit | 3.81 |
| Codex/TwoRootCF231Sharp | 45.22 |
| Codex/TwoRootCF254AffineBasis | 0.67 |
| Codex/TwoRootCF254Sector9Lower | 182.32 |
| Codex/TwoRootCF254ToCF265 | 0.02 |
| Codex/TwoRootCF254ToCF305 | 0.06 |
| Codex/TwoRootCrossClassInvolution | 0.01 |
| Codex/TwoRootLiftAudit | 0.68 |
| Codex/TwoRootMapleAugmented | 22.94 |
| Codex/TwoRootMethodComparison | 0.00 |
| Codex/TwoRootSharpSimultaneous | 33.89 |
| Older lazy-transport result files | 12.12 |

The nested generated Results directory under Scripts is gone. The current
91-family raw-DE/finite-solution campaign supersedes the older DE, canonicalization,
pilot and demonstration outputs. Dated two-root solve runs and the old lazy-transport
result files are no longer needed by active code.

## Preserved mathematical inputs and source

- All 91 current raw DEs and 91 explicit solutions in
  `Stage1And2_2026-09-06`. Their sizes and modification times are unchanged.
- Current coefficient tables, canonical registry, Kira reduction data and input
  configurations; epsilon-order requirements and the CF269 dimensional recurrence.
- Current AMFlow/numerical references and numerical-speedup results. Earlier
  auxiliary-mass-flow boundary work, third-party software and downloaded research
  material alongside the old transport experiment were outside this DE-result deletion.
- CF303's 5.25 MB finite-integration preparation,
  moved into its current campaign directory. The operational specification points
  to the new location. It agrees exactly with the preparation embedded in the
  current solution-construction input.
- 69 regression input files, about 11.18 MB,
  now in [Tests/Fixtures/DifferentialEquations](../Tests/Fixtures/DifferentialEquations/README.md).
  Active tests no longer read the Stale archive or old run directories. Two
  validated-form fixtures have updated references to their preserved defining DEs;
  their mathematical content was checked unchanged.
- Source programs and derivation notes, about 1.59 MB,
  retained in [Private_Backup](../Archive/RetiredCode/FeynFacet/2026-09-06-stale-de-run-sources/README.md).
  Generated Maple files containing emitted large matrices were removed as run inputs.

The executable five-family example now uses the current raw DE files and derives
the master counts from them. Example output is directed to a new scratch directory.
This does not regenerate or replace the current production solution inventory.

## Verification

All 69 fixtures read successfully. The cut-bound, integral-representation and
master-order/solution workflow tests pass after their path changes. The complete
master-order workflow was repeated in a fresh kernel after deletion.

A fresh post-deletion scan read all 182 current solution/input WXF records and
found no references to removed run directories. The relocated CF303 preparation
matches the embedded mathematical input exactly. All current campaign source
files still exist. Active source path scans and changed-file whitespace checks pass.

No expensive canonicalization campaign, full regeneration or new AMFlow evaluation
was run for this filesystem cleanup.
