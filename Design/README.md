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
| Polylogarithmic representation assessment | [GPL and eMPL options](PolylogarithmicRepresentations.md) |
| Numerical evaluation | [Evaluation](NumericalMasterIntegralEvaluation.md), [speedups](NumericalEvaluationSpeedups.md) |
| Optional epsilon-form criteria | [Scope and performance](Stage1CostsAndEpsilonFormCriteria.md) |
| Integral-family equivalence | [CanonicalFamilies](CanonicalFamilies.md), [integration](CanonicalFamiliesIntegration.md) |
| Coefficient reconstruction | [ReconstructionModule](ReconstructionModule.md), [RationalizedCoefficients](RationalizedCoefficients.md) |
| Reduction import | [StreamingKiraImport](StreamingKiraImport.md) |
| Finite-field backend | [CFFR1Backend](CFFR1Backend.md) |
| Kernel scheduling | [KernelPool](KernelPool.md) |
| Bare fragmentation normalization | [Operator, cut tensor and hard convolution](FragmentationNormalization.md) |
| Mathematical terminology | [MathematicalTerminology](MathematicalTerminology.md) |

Completed campaign and cleanup reports are in [Reports](../Reports/README.md).
Current computed records are indexed by [Projects](../Projects/README.md).
Design contains maintained methods and interfaces, not pending campaign instructions.

Superseded architecture, canonicalization-first plans, surveys and chronological
implementation logs are in [Archive/History/Design](../Archive/History/Design/).

- [Explicit singular-boundary matching](ExplicitSingularBoundaryMatching.md): general construction and storage, with a dated worked example.

- [Polynomial measurements](PolynomialMeasurements.md): native dependent cuts, physical current integrations and closed-interval endpoint distributions.
