# Complete finite master solutions, 2026-09-06

All 91 families completed: 345 requested masters, 2,220 explicit coefficients,
79.1 MB compressed. The full campaign took 31.2 minutes elapsed, including
failed attempts and recovery, with six concurrent families sharing eight cores.

Each family directory contains:
- `FamilyDifferentialSystem.wl`: fresh closed raw DE and source references.
- `FiniteSolution/solution.wxf`: the complete explicit finite solution.
- `FiniteSolution/order_determination.wxf` when emitted by the writer, and the
  complete order report inside solution.wxf.
- `FiniteSolution/input.wxf`: exact mathematical inputs used by the worker.
- `FiniteSolution/summary.wxf` and `summary.json`: completion, orders, counts and
  timings. JSON is operational metadata; WXF retains exact mathematics.

At the campaign level, `summary.json` has the complete family inventory;
`campaign.json` records all attempts; `campaign.first-pass.json` preserves the
first-pass failures; `campaign-input.json` and `source-inputs/` preserve the
specification and direct source snapshots. `stored-solution-audit.wxf` reports
91/91 passing explicit-solution and transported-order coverage checks.

Read a family's complete solution without loading the DE solver:

```wl
Get["FeynFacet/FiniteSolutionData.wl"];
data = FeynFacetSolution`ReadMasterIntegralSolution[
  "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06/CF13/FiniteSolution"];
```

The symbols C[j,n] label coefficients of that family's boundary vector in its
declared basis at its ordinary point; their labels are local to the family
record. Boundary values remain unevaluated. The files contain all finite
integral definitions and requested master coefficients; reading them performs
no DE construction or coefficient generation.

The order scope is the current hard-function coefficient inventory before
unspecified endpoint integration, renormalization and PDF convolution.
This is not a claim of final physical NNLO coverage or complete strict
epsilon-form canonicalization.

See [the full report](../../../../Design/Stage1And2FullCampaign_2026-09-06.md).
