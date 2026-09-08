# Explicit GPL representations and numerical comparison, 2026-09-06

The general finite solver now has an optional conversion to Goncharov
polylogarithms (GPLs), followed by optional GiNaC evaluation. It stores finite
expressions; reading or evaluating them never reruns symbolic integration.
FLINT remains the automatic numerical default.

The implementation follows the rational-function and hyperlogarithm integration
structure described by [Panzer](https://arxiv.org/abs/1403.3385), with the
[GiNaC convention](https://www.ginac.de/tutorial/) for `G`. It is a bounded
converter, not a complete implementation of HyperInt. The preceding
[assessment](PolylogarithmicRepresentations_2026-09-06.md) discusses the
mathematical scope and community formats.

## Mathematical operations and storage

``FeynFacetSolution`IntegrateGPL[expr,{t,0,s}]`` accepts rational functions of `t`
times polynomial products of GPLs whose letters are constant in `t`. It uses
rational Hermite reduction before splitting simple poles, integration by parts
for higher poles, shuffle multiplication with multiplicities, and a local
power/log expansion to retain the complete finite lower-end value.
A pole multiplying a vanishing GPL can have a nonzero finite limit; setting
all endpoint GPLs to zero would lose this constant.

Rational logarithms are continued from their lower-end values. Reciprocals of
GPLs, unsupported transcendental dependence, and unresolved algebraic kernels
are reported as unsupported. Limits bound conversion time, expression size,
word count, weight, pole degree, and endpoint expansion order.

`ConvertMasterIntegralSolutionToGPL[data,opts]` determines which finite integral
definitions the requested coefficients require and converts them in dependency
order. It retains the source definitions and appends `GPLRepresentation`, with
actual `IntegralExpressions`, counts, conventions, source snapshot and any
unconverted definitions. The original arithmetic sharing and boundary-constant
convolution remain in use. The status classifies these scalar integrals; it
does not assert that outer prefactors are polylogarithmic.

Partial conversions can be resumed. They are labelled
`PartiallyConvertedToGPL`; explicit GiNaC evaluation refuses missing required
definitions. Source definitions and the schema must match before reuse.
No classification is inferred merely from the number of square roots.

## Coordinate changes and normalization

`PullBackMasterIntegralDifferentialSystem[system,parametrization,baseLift]`
changes the complete connection and supplied basis/homogeneous matrices,
and substitutes into available physical integral definitions. It verifies
root identities and a nonsingular Jacobian at an explicit ordinary-point lift,
records the coordinate map, and preserves it through automatic Laurent-bound
and master-order construction.

The input must supply connection matrices. For a rationalizing change of path,
construct the finite solution again from the pulled-back DE. Independently
changing the paths of its auxiliary integrals does not establish the same solution.

If no sheet was previously declared, root signs default to principal source
values at the base point. A declared source sheet requires
`"RootValuesAtBasePoint" -> <|radicand -> exactRootValue, ...|>`.
These are local continuous branches, not a global physical continuation rule.
A previously fixed source base point cannot be silently replaced.

The direct export driver accepts `RationalizingParametrizationFile` and
`ParametrizingBasePoint`, with `BasePoint` in source coordinates. It maps supplied
integral representations and base-point regions. Existing point-specific
dimensional recurrence data must match the chosen coordinates; mismatches are
refused. Boundary/reference files can declare `KinematicVariables` in the
original coordinates; the numerical adapter checks their points through the map.

## Commands

Build the [GiNaC adapter](../FeynFacet/Backends/ginac/README.md), tested with
GiNaC 1.8.7, and the existing FLINT adapter for comparisons.

```wl
Get["FeynFacet/Solution.m"];
data = FeynFacetSolution`ReadMasterIntegralSolution["path/to/solution"];
converted = FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data,
  "TimeLimit" -> 90, "FunctionTimeLimit" -> 20,
  "MaxExpressionLeaves" -> 1000000];
values = FeynFacetSolution`EvaluateMasterIntegralSolution[converted, exactPoint,
  "NumericalBackend" -> "GiNaC",
  "InitialConstantValues" -> boundaryRules,
  "AccuracyGoal" -> 25, "PrecisionGoal" -> 25];
```

The standalone conversion command writes complete compressed `solution.wxf`:

```sh
wolframscript -file Scripts/Transport/convert_master_integral_solution_to_gpl.wls \
  INPUT_SOLUTION_DIRECTORY OPTIONS.wl OUTPUT_DIRECTORY
```

`OPTIONS.wl` is an option list. Exit 0 means all required definitions converted;
exit 3 means a partial result was saved; exit 1 means failure. Evaluation uses
the usual single-request and parallel-batch drivers with explicit
`"NumericalBackend" -> "GiNaC"`. Each native process uses one core; up to eight
independent requests may run in parallel.

This initial interface requires exact kinematic inputs, including exact rational
or algebraic points. Numerical boundary coefficients retain their supplied
precision; convergence is checked after substituting them. Source-integral poles
and endpoint singularities are checked even if reduction removes them from the
alphabet. Nonzero letters on the straight contour and source principal-log cut
crossings are refused. These checks are mandatory for this backend, including
when `PathCheck -> None` is requested. There is no automatic i0 choice,
contour deformation or singular-point matching.

Precision refinement gives empirical evidence, not a rigorous enclosure.
A direct `EvaluateGPLExpression` call controls working precision only; use the
master evaluator for assembled-coefficient convergence checks.

## Measured experiment

Wolfram 14.2.1 and GiNaC 1.8.7, Linux/WSL, one computational core per backend.
All comparisons request absolute and relative goals of 25 digits and use exact
test boundary constants. Times are elapsed seconds excluding Wolfram/package
startup; evaluation includes source-path and convergence checks. Each backend
is prepared once; the table uses the median of three evaluations.

| Example | Fresh conversion | GiNaC evaluation | FLINT evaluation | Compressed finite file → with GPL |
|---|---:|---:|---:|---:|
| Rational logarithmic control, epsilon orders 0–4 | 0.018 s | 0.0188 s | 0.614 s | 2,127 → 2,556 bytes |
| Genuine two-root closed subsystem, epsilon orders 0–1 | 24.60 s | 8.375 s | 0.242 s | 77,102 → 666,997 bytes |

The rational control is `dI/dx = epsilon I/(1-x)`, base point zero, test point
`4/5`, and `I(0,epsilon)=1/17`. Four required integral definitions convert to four
GPL expressions of maximum weight four. The comparison differs by about
`3.2×10^-63`. First evaluation timings were 0.134 s for GiNaC and 1.541 s for
FLINT, so startup/caching effects matter.

The two-root input is the closed set of prepared CF254 rows
`{1,2,3,4,5,6,7,8,9,10,17,18,19}`; Kallen roots 1 and 3 both occur.
The requested row is prepared row 9. The Kallen13 lift is `{1/4,4}` and the test
point is `{251/1000,401/100}`. Constants are `C[j,0]=j/17` and `C[j,1]=0`.
These labels identify prepared components, not physical master values.
This is not an AMFlow physical-boundary comparison.

All 24 required finite integrals convert from scratch to 352 distinct GPLs,
maximum word weight three. Epsilon order need not equal GPL weight when the
prepared connection has an epsilon-zero part. GiNaC and FLINT meet the 25-digit
comparison; the reported difference is zero with about 34 decimal digits of
absolute accuracy. The independent local Taylor calculation agrees at the same
accuracy. Preparation times were 0.00044 s for GiNaC and 0.042 s for FLINT.
GiNaC used 50- and 70-digit working precision; the source-path check resolved
all 17 distinct polynomials. No extra precision passes were needed.

For this nearby two-root point, Taylor construction and validation took 1.044 s.
Its explicit compressed coefficients occupy 20,460 bytes; subsequent queries
took a median 0.000306 s. The rational control's requested span was refused by
the Taylor constructor's conservative radius check. This does not establish
that Taylor continuation would fail.

Reproduce both examples with the same general benchmark driver:

```sh
wolframscript -file Examples/Transport/gpl_conversion_benchmark.wls rational ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06/RationalControl
wolframscript -file Scripts/Transport/benchmark_gpl_master_integral_solution.wls \
  ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06/RationalControl ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06/RationalControl/request.wl ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06/RationalControl/report.wxf

wolframscript -file Examples/Transport/gpl_conversion_benchmark.wls two-root ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06/CF254
wolframscript -file Scripts/Transport/benchmark_gpl_master_integral_solution.wls \
  ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06/CF254 ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06/CF254/request.wl ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06/CF254/report.wxf
```

The two-root example reads the retained current CF254 production solution.
Family selection appears only in the example, never in the converter or backend.
Compact requests, construction records and numerical reports are preserved in
[the evidence directory](../ppHX_NNLO_DoubleReal/Results/Validation/GPLImplementation_2026-09-06).

## Verification and decisions

Nine TestKit files passed 183 assertions, including 50 new assertions on
integration, source domains, precision cancellation, batch evaluation, coordinate
changes, independent analytic solutions and automatic normalization.
The separate usage test passed seven checks, with all 127 exports documented.
The tests cover existing finite construction, sufficient orders, FLINT,
Wolfram and Taylor evaluation, and package generality. A separate command-line
check passed complete coordinate pullback, automatic order discovery, compressed
export, full and partial conversion (including exit status 3), and evaluation
from the saved GPL file.

[Pro's review](../External/ChatGPT/Records/2026-09-06/10_gpl_implementation_review.md)
identified source-pole, branch and precision hazards. Those counterexamples now
have regression tests. It was a static review, not an independent execution of
the final code.

The results support selective GPL use: about 33 times faster for the logarithmic
control and 35 times slower for the two-root subsystem, whose file becomes about
8.7 times larger. FLINT remains the default. Repeated nearby numerical work
benefits most from the existing explicit Taylor coefficients.

No all-family GPL conversion has been launched, no original production DE or
solution has been replaced, and no general eMPL conversion is implemented here.
The next justified GPL optimization is expression/word reduction measured on
these examples. Global continuation remains separate work. A nonzero physical
CF198 AMFlow comparison subsequently passed through epsilon^1 after correcting
the vendor order conversion; see PhysicalBoundaryResults_2026-09-07.md.
