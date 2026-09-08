# Current methods and interfaces

Use [the production guide](../Scripts/Transport/README.md) for commands and
[STATUS.md](../STATUS.md) for completion status.

| Subject | Current document |
|---|---|
| Explicit finite DE solutions | [FiniteMasterIntegralSolutions](FiniteMasterIntegralSolutions.md) |
| Requested master orders | [MasterIntegralExpansionOrders](MasterIntegralExpansionOrders.md) |
| Laurent bounds and order propagation | [EpsilonOrderDetermination](EpsilonOrderDetermination.md), [CutIntegralLaurentBounds](CutIntegralLaurentBounds.md) |
| Integral representations and normalization | [MasterIntegralRepresentations](MasterIntegralRepresentations.md) |
| DE data and references | [DifferentialEquationDataSchemaV2](DifferentialEquationDataSchemaV2.md) |
| Polylogarithmic representation assessment | [GPL and eMPL options](PolylogarithmicRepresentations_2026-09-06.md) |
| Numerical evaluation | [Evaluation](NumericalMasterIntegralEvaluation_2026-09-06.md), [speedups](NumericalEvaluationSpeedups_2026-09-06.md) |
| Optional epsilon-form criteria | [Scope and performance](Stage1CostsAndEpsilonFormCriteria_2026-09-06.md) |
| Integral-family equivalence | [CanonicalFamilies](CanonicalFamilies.md), [integration](CanonicalFamiliesIntegration.md) |
| Coefficient reconstruction | [ReconstructionModule](ReconstructionModule.md), [RationalizedCoefficients](RationalizedCoefficients.md) |
| Reduction import | [StreamingKiraImport](StreamingKiraImport.md) |
| Finite-field backend | [CFFR1Backend](CFFR1Backend.md) |
| Kernel scheduling | [KernelPool](KernelPool.md) |
| Mathematical terminology | [MathematicalTerminology](MathematicalTerminology.md) |

[The current all-family run](Stage1And2FullCampaign_2026-09-06.md) and dated
cleanup reports record completed work and its verification. Computed records
are stored under [the process result folder](../ppHX_NNLO_DoubleReal/Results/README.md).
Design contains methods and links to those records. Historical validation
programs and source snapshots are preserved with retired code.

Superseded architecture, canonicalization-first plans, surveys and chronological
implementation logs are in [Archive/History/Design](../Archive/History/Design/).

- [Explicit singular-boundary matching](ExplicitSingularBoundaryMatching_2026-09-07.md): 83-series substitutions, general code, storage, and the remaining numerical endpoint interface.
