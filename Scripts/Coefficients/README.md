# Coefficient and distribution assembly

These drivers take explicit process input. Family assignments, coefficient
weights, domains and physical boundary data do not belong in package code.
Generated files belong under `<process>/Results`.

1. `assemble_cut_coefficients.wls` combines weighted cut coefficient tables
   using supplied exact master maps.
2. `assemble_finite_master_density.wls` contracts the physical coefficient
   table with finite master solutions, preserving requested epsilon orders
   and shared explicit definitions.
3. `prepare_endpoint_coefficient_inputs.wls` and
   `construct_scalar_endpoint_families.wls` construct coefficient-weighted
   endpoint functions. See [ScalarEndpointDriver.md](ScalarEndpointDriver.md)
   for input fields, order determination, boundary extensions and reuse of
   completed mathematical stages.
4. `assemble_endpoint_subtracted_density.wls REQUEST.wl OUTPUT.wxf` combines
   complete endpoint coverage with the full interior expression. It writes
   explicit delta derivatives, generalized plus distributions, and the full
   locally integrable remainder, through the requested epsilon order.

The last request contains `InteriorDensity`, a labelled association
`EndpointSolutions`, and `Request`. Each input can be a record or file path.
The request declares the normal/tangential variables, coordinate map and
included Jacobian, interval, target order and endpoint domain conditions.
Optional `ColorDecomposition` supplies `ColorVariables`, `CouplingVariable`,
`ExternalFactors` and `PartonicChannel`. The output is serialized to a
temporary file, read back exactly, and then renamed to the requested path.

`CollectDistributionColorFactors` collects Laurent monomials in the declared
scalar factors; it does not turn a nonpolynomial color denominator into a
truncated series. Each `ColorComponents` entry multiplies its `ColorFactor`,
`CouplingVariable^CouplingPower`, and `ExternalFactor`. Integral definitions
remain shared. The uncollected coefficient fields are retained in the same
record so the mathematical input can be compared directly. Original
algebraic and integral definitions are preserved exactly.
Collection uses sparse Laurent polynomials only in the declared scalar
factors, without expanding the kinematic coefficients.

`EvaluateScalarEndpointAtBasePoint` provides a small independent endpoint
check using the stored polynomial integral definitions and closed constants.
Load `FeynFacet/Solution.m` when GPL evaluation is needed, and supply all
external parameters using `ParameterRules`. Unsupported nonpolynomial
integrals cause an explicit failure. This check uses no DE transport.
`check_finite_density_poles.wls` contracts retained independent master
references without recomputing AMFlow.

Read [EndpointDistributions.md](../../Design/EndpointDistributions.md) for
the delta normalization, finite-interval plus prescription and test-function
domain, and [CoefficientPoleCancellation.md](../../Design/CoefficientPoleCancellation.md)
for moving reduction poles and the exact rational-series backend.

The current process demonstration and precise coverage are documented in
`ppHX_NNLO_DoubleReal/Results/Assembly/Stage4_2026-09-07/README.md`.
The bare double-real result retains dimensional poles. Other NNLO cuts and
factorization counterterms must be added before calling it a finite hard
coefficient.

## Compact final distribution files

`wolframscript -file Scripts/Coefficients/compact_distribution_result.wls SOURCE OUTPUT`
keeps explicit color-resolved delta/plus/regular coefficients and all required
shared definitions. It preserves domains and source path scopes and verifies
exact source-to-result equality. It writes compressed WXF and a small report.
Run the same command with a final `verify` argument in a fresh kernel to check
the saved expression, definition records and metadata against SOURCE. Source
and output must be different files. No integrals are reevaluated by either check.

## Analytic NLO campaigns

`Scripts/run_nlo_hard_function.wls PROJECT CAMPAIGN [all|assemble]` generates a
complete NLO hard function using contribution cards, exact analytic masters,
automatically sufficient epsilon orders and generated PDF/FF/UV counterterms.
The worked UU/double-incoming-LL/TT example is documented in
`ppHX_NLO_qqprime/README.md`. The output is an ordinary Mathematica association
with explicit LO and finite NLO delta, plus and regular coefficients.

`assemble_endpoint_subtracted_density.wls` now applies the same compact format
by default after color collection. A request can set `CompactOutput -> False`
when redundant uncolored views are explicitly needed for a separate comparison.
Timings report assembly, color collection and compaction separately.
