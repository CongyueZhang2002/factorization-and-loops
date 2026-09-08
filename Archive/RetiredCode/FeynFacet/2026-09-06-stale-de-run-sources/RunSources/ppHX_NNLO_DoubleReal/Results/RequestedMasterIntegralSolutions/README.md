# Complete finite coefficients at requested master orders

Generated 2026-09-05 with the general
[family driver](../../../Scripts/Transport/solve_master_integral_families.wls)
and [explicit input](../../../Examples/Transport/pre_stage3_family_solutions.wl).

| Family | Master positions | Requested epsilon range | Coefficients | Prepared evolution through | Construction seconds | Bytes |
|---|---:|---|---:|---:|---:|---:|
| CF269 | 23 | -3 to 0 | 92 | 4 | 5.302075 | 1,064,930 |
| CF48 | 27 | -5 to 0 | 162 | 6 | 17.688280 | 2,101,528 |
| CF265 | 32 | -5 to 0 | 192 | 7 | 26.441591 | 2,237,882 |
| CF259 | 47 | -5 to 0 | 282 | 7 | 142.223109 | 5,734,164 |
| CF303 | 45 | -5 to 0 | 270 | 7 | 187.852771 | 5,969,547 |

Regenerated after the [stage 1/2 optimizations](../../../Design/Stage1And2Speedups_2026-09-05.md).
Total: 998 explicit coefficients and 17,108,051 bytes, down from 36,277,487.
Construction took 379.51 seconds and compressed writing 8.24 seconds.
These timings reuse the same exact inputs, including saved preparation and
recurrence where available; package loading and input reads are excluded.
CF265/CF259 preparation remains part of construction.

The requested ranges, basis convolutions and master-coefficient formulas
agree exactly with the prior outputs. Every defining integrand was also
compared at two rational points using 65-digit arithmetic; the differences
vanished within numerical precision. No boundary constants were evaluated.

Each `solution.wxf` contains the full finite expression, scalar kernels,
nested-integral definitions, shared arithmetic, derived order requirements
and check records. It can be read with `Import[path,"WXF"]`. Every requested
master coefficient is explicit and linear in kinematics-independent
`C[j,m]` in the `FeynFacetSolution` context. No lazy coefficient generator is stored.

`C(epsilon)=I(X0,epsilon)` in the original AMFlow-normalized master basis.
CF48 uses X0=(1/6,1/4) in its coefficient coordinates, or source coordinates
(v,w)=(5/12,1/6); the other systems use (1/4,1/3). Unneeded entries of U,
when stored alongside the final coefficients, are `Missing["NotComputed"]`
and must not be read as zero.

The 174 master positions include lower sectors in each coupled system.
They are not a count of unique canonical observable masters.
These ranges demonstrate sufficient-order solution construction; final
NNLO endpoint, renormalization and factorization demands are still separate.

Standalone numerical evaluation:

```wl
Get["FeynFacet/FiniteSolutionData.wl"];
data = FeynFacetSolution`ReadMasterIntegralSolution[directory];
value = FeynFacetSolution`EvaluateMasterIntegralSolution[data, point,
  "QuadratureOrder" -> 18, "WorkingPrecision" -> 50];
value["MasterIntegralEpsilonCoefficients"]
```

No DE solver is loaded. A CF269 convergence comparison at (13/50,17/50)
using 12 versus 18 nodes gave a maximum relative difference 1.62e-38
after setting all C[j,m] to one for the comparison. This is not a physical
boundary determination or AMFlow comparison.

To reproduce/resume from the repository root:

```sh
wolframscript -file Scripts/Transport/solve_master_integral_families.wls \
  Examples/Transport/pre_stage3_family_solutions.wl \
  ppHX_NNLO_DoubleReal/Results/RequestedMasterIntegralSolutions
```

`input.wxf` stores the exact construction inputs locally for resume; these
duplicate caches are excluded from version control. If only the distributed
solution files are present, choose a new empty output directory to recompute.
`summary.wxf` and `report.wxf` preserve the measured construction status.
Exact-input resume remains available for these regenerated results.

[Current measurements](../../../Design/Stage1And2Speedups_2026-09-05_sources/stage2-after.json)
and [91-family input inventory](../../../Design/FiniteMasterIntegralSolutions_sources/family_input_inventory.json).
The general mathematical scope is described in
[FiniteMasterIntegralSolutions.md](../../../Design/FiniteMasterIntegralSolutions.md).
