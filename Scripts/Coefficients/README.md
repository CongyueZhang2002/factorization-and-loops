# Coefficient and distribution assembly

Use [WORKFLOW.md](../../WORKFLOW.md) for the overall sequence and CPU limits,
and the [ppHX NNLO channel guide](../../Projects/ppHX_UU/NNLO/qqp-qqp/README.md)
for current input paths and replay commands. The drivers below take explicit
mathematical data. Family assignments, physical weights and domains remain
project inputs.

## Input/output chain

Run Wolfram drivers as `wolframscript -file Scripts/Coefficients/DRIVER ...`.

| Operation | Driver arguments | Main input contract |
|---|---|---|
| Weighted cut sum | `assemble_cut_coefficients.wls REQUEST.wl` | CoefficientFiles, Weights, OutputFile; bound master maps/catalog |
| Physical density | `construct_physical_master_density.wls REQUEST.wl OUTPUT.wxf` | CoefficientFile and physical Request; optional DefinitionRequest |
| Endpoint frame catalog | `build_endpoint_coefficient_catalog.wls CUT_CATALOG.wxf ACCEPTED_ENDPOINTS.json OUTPUT.wl` | Actual integral definitions and accepted physical endpoint/bound records |
| Complete endpoint groups | `prepare_endpoint_coefficient_groups.wls REQUEST.wl CATALOG.wl OUTPUT_DIRECTORY` | Physical coefficients, endpoint coordinates/order and accepted frames |
| Finite interior density | `assemble_finite_master_density.wls REQUEST.wl OUTPUT.wxf` | PhysicalCoefficientTable, FiniteSolutions and result-order Request |
| Scalar endpoints | `construct_scalar_endpoint_families.wls CAMPAIGN_INPUT.wl OUTPUT_DIRECTORY` | CoefficientInputFiles from the group manifest, accepted endpoint manifest and physical boundary input |
| Final distributions | `assemble_endpoint_subtracted_density.wls REQUEST.wl OUTPUT.wxf` | Complete InteriorDensity, labelled EndpointSolutions and distribution Request |
| Retained-reference contraction | `check_finite_density_poles.wls REQUEST.wl REPORT.wxf` | Matching physical master references and requested coefficients |

Weighted independent sources can use MasterIntegralRulesFiles in the same
order as CoefficientFiles, together with TargetCatalogFile. Bound match/relation
records are checked against source definitions and the exact target catalog.
Family names alone do not establish integral identity. The physical-density
driver derives normalized master definitions through the general constructor;
it does not copy definitions from an old assembled density.

The normal finite-coefficient production path is documented in
[ReconstructionModule.md](../../Design/ReconstructionModule.md). It keeps moving
divisor terms exact and derives sufficient orders for regular terms from
physical endpoint bounds. The endpoint grouping step then constructs fresh
complete coefficient rows in a common accepted DE basis and checks exact
moving-pole cancellation.

The generated group manifest defines the scalar contribution inventory.
Alternative saved frames are not missing contributions. Several owned
contributions can use the same mathematical family. Preserve both whole-master
coverage and ownership of split exact contributions.

## Scalar endpoint campaign

Read [ScalarEndpointDriver.md](ScalarEndpointDriver.md) before changing a
campaign. It defines the single-family interface, worker pool, required orders,
boundary extensions and stage reuse. Persistent output includes mathematical
inputs, stage completion, scalar solutions, per-contribution results and an
aggregate campaign report.

Missing orders/inputs, unresolved coefficient classes, timeouts and explicit
deferrals remain incomplete. A reused or structurally empty singular term can
have NoChecksExecuted; that does not become a new passing epsilon audit.

## Final distribution request and format

The request contains InteriorDensity, a labelled EndpointSolutions association,
and Request. Inputs can be records or paths. Declare normal/tangential
variables, the coordinate map, whether its Jacobian is included, interval,
target order, analytic assumptions and test-function domain.

Optional ColorDecomposition declares ColorVariables, CouplingVariable,
ExternalFactors and PartonicChannel. Use the actual symbol contexts from the
physics records. Color decomposition is an exact Laurent-monomial separation;
it is not an expansion of a nonpolynomial color denominator.

ResultMetadata identifies Project, Order, Channel, Contribution, variables,
coordinate conventions and physical scope. The default ResultFormat is
`"PartonicResult"`. Explicit `"EndpointDensity"` retains generalized endpoint
distributions without asserting reduction to standard delta/logarithmic-plus
terms. The accepted ppHX double-real contribution uses this explicit format.

CompactOutput defaults to true. The driver keeps the closed shared definitions,
checks exact read-back and compaction, and writes audit/summary sidecars.
Use `compact_distribution_result.wls SOURCE OUTPUT [verify]` for an explicit
lossless compaction/recheck; source and output must differ.

See [EndpointDistributions.md](../../Design/EndpointDistributions.md) for
normalization and test-function scope, and
[CoefficientPoleCancellation.md](../../Design/CoefficientPoleCancellation.md)
for complete-row cancellation. A bare double-real contribution retains
dimensional poles; other NNLO cuts and counterterms are needed for a finite
complete hard coefficient.

## Performance and validation controls

`assemble_finite_master_density.wls` accepts CoefficientWorkers (1-8, default 1)
and EpsilonRemainderChecks. The default CoefficientFunctionDirectory is None,
avoiding hundreds of redundant intermediate files. Final assembly supports
the same epsilon audit and a bounded ColorDecomposition Workers setting.

EvaluateScalarEndpointAtBasePoint gives a separate endpoint check without DE
transport. Load FeynFacet/Solution.m for GPL evaluation and provide all external
parameters. Unsupported definitions fail explicitly. A retained AMFlow
contraction is distinct from fresh AMFlow integration and from a boundary-only
reference check.

Use [the shared validation contracts](../Validation/README.md). Do not make
verification more expensive than the requested calculation without a concrete
unresolved issue.
