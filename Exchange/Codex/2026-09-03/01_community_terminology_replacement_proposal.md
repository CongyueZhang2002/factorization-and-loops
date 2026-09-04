# Final candidate terminology map for FeynFacet

Status: **user review only; no package rename or source edit is authorized**.

This is the merged result of a source inventory, a primary-literature review,
an independent adversarial review, and a ChatGPT Pro adversarial review.  It
is a semantic migration, not a blind search-and-replace: where one current
object combines several mathematical operations, the table says **split**.

## 1. Locked scientific vocabulary

| Mathematical meaning | Final package term | Terms not to use for it |
|---|---|---|
| `dF = epsilon Omega F`, with `Omega` epsilon-independent | `EpsilonFactorizedSystem` (general serialized type); `EpsilonForm` may remain in established API names | `CanonicalForm` as a universal label |
| `Omega = Sum_i R_i dlog(L_i)` with constant matrices `R_i` | `DLogEpsilonForm` | generic `CanonicalForm` |
| square homogeneous solution `U_gamma` | `FundamentalSolutionMatrix` | any rectangular selected-output object |
| `Pexp Integral_gamma A`, truncated in epsilon/weight | `TruncatedPathOrderedExponential` | `OperatorAutomaton` when it includes projections, embeddings, or boundary maps |
| propagation of specified data along a specified path | `Transport` or `EvolutionOperator` | charts, demand selection, endpoint-mode analysis, or a final answer |
| local regular-singular expansion | `FrobeniusExpansion`; `LeveltBasis` where Jordan/log structure is present | generic `EndpointTransport` |
| constants multiplying independent local solutions | `BoundaryConstants` | `Periods` unless an actual period integral is defined |
| an explicitly defined period integral | `Period`; use `EllipticPeriod` for elliptic-cycle periods | every unevaluated boundary coefficient |
| ordered integrals of connection one-forms | `ChenIteratedIntegral` | generic `TransportWord` |
| multiple-polylogarithm realization | `GoncharovPolylogarithm` / `GPL` | `GPL` as the name of every possible boundary function |
| solution before numerical/analytic boundary constants are fixed | `MasterIntegralSolution`, described in prose as “in terms of boundary constants” | `PhysicalTransportFinished`, `BoundaryParameterizedSolution` |
| solution with branch/region and every independent boundary constant fixed | `PhysicalRegionMasterIntegralSolution` | the pre-boundary-determination object |

Why `MasterIntegralSolution` rather than the longer type
`MasterIntegralSolutionWithBoundaryConstants`: boundary resolution is state,
not a different mathematical object type.  The record carries
`BoundaryDataStatus`; documentation must call the unresolved case a
“master-integral solution in terms of boundary constants.”

## 2. Final public workflow

1. `AssembleFamilyEpsilonFormInFrame`
2. `DetermineRequiredMasterIntegralEpsilonOrders`
3. `BuildFrobeniusExpansionAtEndpoint`
4. `BuildPhysicalEndpointModeMap`
5. reduce exact relations to independent boundary-constant coordinates
6. build the endpoint-to-base-point evolution and the graded boundary binding
7. `BuildMasterIntegralSolution`
8. `DetermineBoundaryConstants`
9. `ApplyBoundaryConstants`
10. `AcceptedPhysicalRegionMasterIntegralSolutionQ`

`TransportTo` and `AnalyticallyContinueSolution` remain valid names for later
genuine propagation.  The demand-restricted word operator is a private
computational intermediate, not a public scientific stage.

## 3. Public symbols: final replacements

### 3.1 Family epsilon-form assembly and frames

| Current | Final replacement / disposition |
|---|---|
| `TransportFamilyInChart` | **split**: its `"AssemblyOnly" -> True` behavior becomes `AssembleFamilyEpsilonFormInFrame`; its default call into retired `TransportFamily` retires with that route |
| `TransportChartCatalog` | `RationalizingChartCatalog` |
| `TransportChartVerify` | `VerifyRationalizingChart` |
| `TransportRootSetChart` | `FindRationalizingChartForRoots` |
| `ComposeTransportChartExtension` | `ComposeRationalizingChartExtension` |
| `RationalizeTransportChartExtension` | `ExtendRationalizingChart` |
| `BuildAlgebraicTransportFrame` | `BuildMultiquadraticFunctionFieldFrame` |
| `TransportFamilyChartRegister` | `RegisterFamilyVariableFrames` |
| `TransportFamilyChartLoad` | `LoadFamilyVariableFrames` |
| `TransportFamilyChart` | `FamilyVariableFrame` |
| `CertifyTransportEpsilonValuations` | `ValidateBasisTransformationEpsilonValuationBounds` |

`Frame` is required in the family-assembly name because the accepted input can
be either a rationalizing change of variables or an algebraic function-field
frame.  The valuation validator must retain `"Probabilistic" -> True` when its
evidence is random finite-field evaluation; it must not claim an exact global
certificate.

### 3.2 Demand-restricted intermediate (private by default)

| Current | Final replacement |
|---|---|
| `BuildObservableTransportManifest` | private `BuildDemandRestrictedWordOperatorManifest` |
| `BuildObservableTransportDemand` | public `DetermineRequiredMasterIntegralEpsilonOrders` |
| `FindObservableTransportPath` | `ChooseRegularBaseAndTargetPoints` |
| `BuildObservableTransport` | private `BuildDemandRestrictedWordOperator` |
| `AcceptedObservableTransportQ` | private `AcceptedDemandRestrictedWordOperatorQ` |
| `ObservableTransportWordMap` | private `DemandRestrictedWordMap` |
| `ReconstructObservableTransportWordMaps` | private `ReconstructDemandRestrictedWordMaps` |

The current path helper checks regularity at the selected base and target
points, not on the complete segments and not on a physical sheet.  Therefore
`FindAdmissibleIntegrationPath` is reserved for a future routine with
whole-path singularity and branch validation.  Its current `ExactPathData`
status becomes `RegularPathEndpointData`.

The operator object is a rectangular map from generic-base-point Laurent
coordinates to requested rows/orders.  `DemandRestrictedWordOperator` is an
implementation name; it is not a fundamental solution, a physical solution,
an observable, or a path-ordered exponential.  If it never needs independent
serialization, fold it into `BuildMasterIntegralSolution` instead of keeping a
public constructor.

### 3.3 Endpoint data

| Current | Final replacement |
|---|---|
| `BuildEndpointFrobenius` | `BuildFrobeniusExpansionAtEndpoint` |
| `BuildBoundaryModeMap` | `BuildPhysicalEndpointModeMap` |
| `BoundaryDegenerateEigenspaceDeclaration` | `DegeneratePhysicalEndpointModeData` |
| `BuildEndpointLeveltModeConnection` | `BuildTangentialConnectionInLeveltBasis` |
| `BuildTransportBoundaryVector` | `BuildBoundaryVectorFromConstants` |
| `BoundaryPeriodCoefficient` | `BoundaryConstantCoefficient` |

`BuildPhysicalEndpointModeMap` is deliberately not
`BuildPhysicalFrobeniusBasis`: the current routine handles declared/demanded
modes and may be incomplete or ambiguous.  `BuildBoundaryVectorFromConstants`
may return rational selectors, the constant-coordinate vector, and the
epsilon-graded boundary vector.  Its inner selector-only key is separately
named `BoundarySelectorMap`.

### 3.4 Current compound endpoint/current-path code

The current `PhysicalBoundaryCampaignAdapter` objects combine local-mode data,
endpoint-to-interior propagation, the current path, and demand projection.
There is no honest one-word replacement.  Split the concepts as follows:

| Current compound name | Final objects/names |
|---|---|
| `BuildEndpointAutomatonBoundaryAdapter` | private `BuildEndpointToBasePointWordMapAdapter` |
| `BuildGradedPhysicalEndpointTransport` | `BuildGradedBoundaryTransportBinding` |
| `ComposeEndpointAutomatonPeriodWords` | private `ComposeBoundaryTransportWordMaps` |
| `ComposeGradedPhysicalEndpointWords` | private `MaterializeBoundaryTransportWordMaps` |
| `PhysicalEndpointTransport` | `BoundaryTransportBinding` |
| `GradedPhysicalEndpointTransport` | `GradedBoundaryTransportBinding` |
| `EndpointConnectionWord` | private `EndpointEvolutionWord` |

The present graded record is a binding: its composer still needs the separate
demand-restricted operator.  It is not yet a self-contained solution operator.
After a real responsibility split, the genuinely propagating factor may be
named `EndpointToBasePointEvolutionOperator` or exposed by the verb
`TransportBoundaryVectorToBasePoint`.  A future self-contained composition may
be called `BoundaryToTargetSolutionOperator`.  Use `EndpointMatchingMatrix`
only if the code actually constructs a matrix relating complete local bases;
the current selected-mode map alone must not receive that name.

### 3.5 Pre-Stage-3 and resolved results

| Current | Final replacement |
|---|---|
| `FinishPhysicalTransport` | `BuildMasterIntegralSolution` |
| `PhysicalTransportFinishedQ` | `ReadyForBoundaryDeterminationQ` |
| `PhysicalTransportFinished` | remove; use the orthogonal record fields below |
| `PhysicalTransportIncomplete` | `MasterIntegralSolutionIncomplete` |
| `FinishPhysicalTransportInputsNotWellFormed` | `MasterIntegralSolutionInputsInvalid` |
| `BuildPhysicalTransportCoefficient` | `BuildMasterIntegralEpsilonExpansionCoefficient` |
| `PhysicalTransportCoefficientBuilt` | `MasterIntegralEpsilonExpansionCoefficientBuilt` |
| `PhysicalTransportCoefficientInputsNotWellFormed` | `MasterIntegralEpsilonExpansionCoefficientInputsInvalid` |

Required pre-Stage-3 record fields:

```wl
"ObjectType" -> "MasterIntegralSolution"
"Representation" -> "ExplicitIteratedIntegrals"
"DemandCoverage" -> "Complete"
"BoundaryDataStatus" ->
  "Undetermined" | "PartiallyDetermined" | "Resolved"
"VerificationStatus" -> "Certified"
"ReadyForBoundaryDetermination" -> True
```

A square `PathOrderedExponential` may be retained as nested evolution evidence,
but it is not an allowed top-level ready representation: the agreed Stage-3
gate requires every demanded pair to be materialized as explicit iterated
integrals.  Unknown boundary constants do not make this pre-Stage-3 record
incomplete.  Incomplete means that demanded coefficients, the independent
boundary-coordinate set, the requirements ledger, or any required
differential-equation, endpoint-asymptotic, binding, purity,
path-prescription, or coverage verification is missing or failed.

`ReadyForBoundaryDeterminationQ` must recompute these conditions; it must not
trust the stored Boolean.  A prose-only degenerate-mode relation or a transfer
without an executable equality fails readiness, and the surviving coordinate
set must be independently parameterized.

New post-boundary API:

| New public name | Contract |
|---|---|
| `DetermineBoundaryConstants` | compute exact values or executable relations |
| `ApplyBoundaryConstants` | substitute a complete independent set |
| `PhysicalRegionMasterIntegralSolution` | branch/region and all independent constants resolved |
| `AcceptedPhysicalRegionMasterIntegralSolutionQ` | validate the resolved solution and its boundary data |

### 3.6 Iterated-integral heads

| Current | Final replacement / disposition |
|---|---|
| `TransportIteratedIntegral` | `ChenIteratedIntegral` |
| `TransportAlgebraicRoot` | `AlgebraicLetterRoot` |
| `TransportLetterKernel` | `IteratedIntegralKernel` |
| `ExpandTransportWordLetters` | `ExpandIteratedIntegralWordLetters` |
| live internal `TransportWord` | private `IteratedIntegralWord` |
| live `TransportConstant[block,order,index]` | `IntegrationConstantCoefficient`; otherwise confine it to the V1 reader |

Do not map both `TransportWord` and `TransportIteratedIntegral` blindly to the
same head.  The former is an internal/legacy word carrier; the latter is the
paper-facing integral object.  `BoundaryConstantCoefficient[id,order]` remains
reserved for coefficients of named boundary-constant series.

### 3.7 Rational dependence on epsilon

| Current | Final replacement |
|---|---|
| `BuildRationalEpsilonLayerTransport` | `SolveRationalInEpsilonLayer` |
| one-argument `AcceptedRationalEpsilonLayerTransportQ` | `AcceptedRationalInEpsilonLayerSolutionQ` |
| input-bound mathematical overload | `VerifyRationalInEpsilonLayerSolution` |
| `AttachTransportBoundaryToRationalLayer` | `AttachBoundarySelectorsToRationalInEpsilonLayer` |
| `BuildRationalEpsilonLayerOperator` | `BuildRationalInEpsilonLayerSolutionOperator` |
| one-argument `AcceptedRationalEpsilonLayerOperatorQ` | `RationalInEpsilonLayerSolutionOperatorQ` |
| `RebaseRationalEpsilonLayerOperator` | `RebaseRationalInEpsilonLayerSolutionOperator` |
| `RationalEpsilonLayerWordMap` | `RationalInEpsilonLayerWordMap` |
| `RationalEpsilonLayerDemandTerms` | `RationalInEpsilonLayerRequiredTerms` |

Use **variation of constants** in documentation when that is the implemented
block-triangular method.  `Attach...` is intentional: the present function
splits and attaches selector matrices; it does not evaluate or substitute the
boundary constants, so `ApplyBoundaryConstants...` would be false.

### 3.8 Retired Libra route

| Current | Final disposition |
|---|---|
| `TransportFamily` | remove from the public API after the V1 compatibility interval |
| `TransportPathArtifactRun` | same |
| `TransportStatus` | same |
| `TransportQuadrature` | same |

`TransportWord` and `TransportConstant` are not placed in this table because
current loaded code still contains consumers; they require the semantic
replacements in section 3.6 before retirement.

## 4. Representation keys and statuses

### 4.1 Current operator record

| Current | Final replacement |
|---|---|
| `OperatorAutomaton` | `DemandRestrictedWordOperator` |
| `ExactOperatorAutomaton` | `DemandRestrictedWordOperator` plus exact coefficient-domain metadata |
| `CompactTransportAutomaton` | `CompactDemandRestrictedWordOperator` |
| `FirstOperatorMatrices` | `FirstSegmentKernelMatrices` |
| `SecondOperatorMatrices` | `SecondSegmentKernelMatrices` |
| `InitialDemandMap` | `RequestedOutputFunctionals` |
| `BoundaryAmbientSlots` | `CanonicalLaurentCoefficientSlots` |
| `WordRepresentation` | `IteratedIntegralWordRepresentation` |
| Boolean/status `TransportWordExpanded` | `IteratedIntegralWordExpansionCompleted` |

Never rename the current rectangular record to
`TruncatedPathOrderedExponential`.  If a true square `U_gamma` is stored later,
that factor may use `FundamentalSolutionMatrix` or
`TruncatedPathOrderedExponential`.

Replace the status pair
`ExactObservableTransport` / `ModularlyVerifiedObservableTransport` by fields,
not more compound status strings:

```wl
"ObjectType" -> "DemandRestrictedWordOperator"
"VerificationStatus" -> "Accepted"
"VerificationMethod" -> "ExactSymbolic" | "FiniteField"
```

Private prefix migration:

- `observableTransport*` -> `demandRestrictedWordOperator*`
- final-builder `finish*` -> `masterIntegralSolution*`

Live literal families must move with the symbols rather than survive as ghost
V1 vocabulary:

| Current family/key | V2 family/key |
|---|---|
| `ObservableDemand*` | `MasterIntegralEpsilonOrderRequirements*` |
| `ObservableTransport*` | `DemandRestrictedWordOperator*` |
| `ObservableWord*` | `DemandRestrictedWord*` |
| `DualObservableRows` | `DualRequestedOutputRows` |
| `ObservableRankByExactWeight` | `DemandRestrictedRankByWeight` |
| `ObservableTransitionsByWeight` | `DemandRestrictedTransitionsByWeight` |
| `CurrentObservableRowSpaces*` | `CurrentPathOutputRowSpaces*` |
| `ObservableTransportInput` | `DemandRestrictedWordOperatorInput` |

### 4.2 Boundary identifiers and typed boundary data

Use distinct, non-interchangeable identities:

| Identity | Meaning |
|---|---|
| `BoundaryDatumID` | global physical boundary datum/proof class before an independent coordinate basis is chosen |
| `BoundaryConstantID` | primary symbolic coefficient in the independent solution basis |
| `BoundaryModeID` | family-local Frobenius/Levelt mode realization |
| `BoundaryIntegralID` | integral definition used to determine a constant or combination |
| `PeriodID` | only a proved period-integral identity; use `EllipticPeriodID` for an elliptic-cycle period |

The epsilon coordinate is `{BoundaryConstantID, EpsilonOrder}`.  A boundary
integral, a local mode, and a constant need not be in one-to-one
correspondence.

Final boundary-data schema:

```wl
<|
  "BoundaryDatumID" -> datumID,
  "BoundaryConstantID" -> constantID,
  "EpsilonOrder" -> n,
  "BoundaryModeID" -> modeID | Missing["NotModeBased"],
  "DefinitionKind" ->
    "BoundaryValue" | "BoundaryIntegral" | "PeriodIntegral",
  "DeterminationMethod" ->
    "DirectEvaluation" | "ZeroProof" | "TransferRelation" |
    Missing["Undetermined"],
  "BoundaryIntegralID" -> integralID | Missing["NotApplicable"],
  "PeriodID" -> periodID | Missing["NotPeriodIntegral"],
  "BoundaryFunctionClass" ->
    "Rational" | "Polylogarithmic" | "Elliptic",
  "EvaluationStatus" ->
    "KnownExact" | "KnownZero" | "ExpressedByRelation" |
    "Undetermined",
  "Value" -> ...,
  "Definition" -> ...,
  "Relation" -> ...
|>
```

Definition type, determination method, and evaluation status are separate
axes.  Known/unknown is a status, not a mathematical kind.  Every transferred value
must carry an executable equality.  A dependent constant expressed by a
relation must not remain in the independent coordinate set.

### 4.3 `Period*` key family

| Current | Final replacement |
|---|---|
| `PeriodBasis` | `IndependentBoundaryConstantCoordinates` after independence is proved; otherwise `BoundaryConstantGenerators` |
| `PeriodRelations` | `BoundaryConstantRelations` |
| `PeriodCoordinates` | `BoundaryConstantCoordinates` |
| `PeriodCoordinatesByBinding` | classify first; usually `BoundaryCoordinatesByBinding` |
| `LocalPeriodCoordinates` | `LocalBoundaryConstantCoordinates` |
| `FormalPeriodCoordinates` | `FormalBoundaryConstantCoordinates` |
| `PeriodEpsilonValuation` | `BoundaryConstantEpsilonValuation` |
| `PeriodOrderWindow` | `BoundaryConstantEpsilonOrderWindow` |
| `MissingPeriodAction` | `MissingBoundaryConstantAction` |
| `BoundaryPeriodsEvaluated` | `BoundaryConstantsDetermined` |
| `NewPhysicalPeriodsIntroduced` | `NewBoundaryConstantsIntroduced` |
| `PeriodClass` | `BoundaryFunctionClass` |
| `PeriodBlockRows` | classify as `BoundaryModeBlockRows` or `BoundaryIntegralBlockRows` |
| `PeriodStatus` | `EvaluationStatus` |
| generic `Periods` | classify as `BoundaryConstants`, `BoundaryIntegrals`, or genuine `EllipticPeriods` |
| `EndpointPeriodTransport` | split into endpoint-mode mapping and endpoint-to-base-point evolution |
| `Stage3NeedsLedger` | `BoundaryDataRequirements` |
| `Stage3SeriesCount` | `BoundaryModeSeriesCount` |
| `Stage3CoordinateCount` | `BoundaryConstantCoefficientCount` |
| `Stage3Coordinates` | `BoundaryConstantCoordinates` |
| `ParentPeriodID` in the pre-independence ledger | `ParentBoundaryDatumID` |
| realization-level `PeriodID`/`RealizationKey` | populate both `BoundaryDatumID` and `BoundaryModeID` |
| independent-coordinate `PeriodID` | `BoundaryConstantID` |
| `PeriodCountConvention` | `BoundaryDatumCountConvention` |

Endpoint binding status literals:

| Current status/key | V2 status/key |
|---|---|
| `EndpointAutomatonBoundaryAdapterBuilt` | `EndpointToBasePointWordMapAdapterBuilt` |
| `EndpointAutomatonPhysicalPeriodWordsBuilt` | `BoundaryTransportWordMapsBuilt` |
| `EndpointBoundaryAdapterRequired` | `EndpointToBasePointWordMapAdapterRequired` |
| `EndpointAdapterFamilyMismatch` | `EndpointToBasePointAdapterFamilyMismatch` |
| `GradedEndpointAdapterFailed` | `EndpointToBasePointWordMapAdapterFailed` |
| `GradedPhysicalEndpointTransportBuilt` | `GradedBoundaryTransportBindingBuilt` |
| `GradedPhysicalEndpointTransportInputsNotWellFormed` | `GradedBoundaryTransportBindingInputsInvalid` |
| `GradedPhysicalEndpointTransportRequired` | `GradedBoundaryTransportBindingRequired` |
| `GradedPhysicalEndpointWordsBuilt` | `BoundaryTransportWordMapsMaterialized` |
| `PhysicalEndpointTransportAcceptedV1` | `GradedBoundaryTransportBindingAcceptedV2` |
| `PhysicalEndpointTransportCampaignComplete` | `GradedBoundaryTransportBindingCampaignComplete` |
| `PhysicalEndpointTransportCampaignIncomplete` | `GradedBoundaryTransportBindingCampaignIncomplete` |

Contextual ID-list replacements:

| Current family | Final family after call-site confirmation |
|---|---|
| `CertifiedPeriodIDs` | `CertifiedBoundaryDatumIDs` |
| `StructuralPeriodIDs` | `StructuralBoundaryDatumIDs` |
| `KnownZeroLedgerPeriodIDs` | `KnownZeroBoundaryDatumIDs` |
| `KnownZeroStructuralPeriodIDs` | `KnownZeroStructuralBoundaryDatumIDs` |
| `UnevaluatedStructuralPeriodIDs` | `UndeterminedStructuralBoundaryDatumIDs` |

Keep `EllipticPeriods`, `MissingEllipticPeriods`, `PeriodMatrix`, and `PeriodID`
only where the object is demonstrably a period integral.  Do not rewrite the
scientific `BoundaryPeriods/` evidence tree wholesale; classify each source
first.

### 4.4 Other overloaded `Transport*` keys

| Current | Final replacement / rule |
|---|---|
| `TransportBoundary` | `BoundarySelectorMap` |
| `TransportEpsilonValuations` | `BasisTransformationEpsilonValuationBounds` |
| `TransportEpsilonValuationCertificate` | `BasisTransformationEpsilonValuationEvidence` |
| `TransportEpsilonValuationsBound` | `BasisTransformationEpsilonValuationBoundsValidated` |
| `TransportEpsilonValuationSource` | `BasisTransformationEpsilonValuationSource` |
| `TransportVariables` | `KinematicVariables` if complete; otherwise `PathVariables` |
| `TransportSecondVariable` | `SecondPathVariable` |
| `ExpectedTransportFile` | classify as `ExpectedWordOperatorFile`, `ExpectedBoundaryMapFile`, or `ExpectedMasterIntegralSolutionFile` |
| `TransportFile` | classify by stored object |
| `TransportProvider` | `SolutionOperatorProvider` only when that is what it returns |
| `TransportSeconds` | use the named stage, e.g. `EndpointToBasePointEvolutionSeconds` |
| `TransportProbabilistic` | stage-local `Probabilistic` evidence field |
| `FullProductionTransportAccepted` | no lexical replacement; classify as operator acceptance or solution readiness |

Generic `Transport`, `TransportStatus`, `AcceptedTransportStatus`,
`SyntheticTransportStatus`, `TransportBackend`, `TransportFamily`,
`TransportedMapKnown`, and `TransportByteCount` require call-site
classification.  Preserve `Transport` only when the operation truly propagates
data along a path.

Predicate naming rule:

- `<Object>Q`: structural shape predicate;
- `Accepted<Object>Q`: accepted artifact/contract predicate;
- `Verify<Object>`: re-derives a mathematical relation from bound inputs;
- `Certified<Object>Q`: only if that call itself verifies the certificate.

## 5. File and directory map

Do not remove `Transport/` globally.  It remains the home of genuine path
propagation, rebasing, and analytic continuation.

| Current live path/stem | Final path/stem |
|---|---|
| `Private/Transport/Assembly/MasterTransport.wl` | split: epsilon-form assembly to `Private/EpsForm/Assembly/FamilyEpsilonFormAssembly.wl`; retain only genuine propagation under `Transport/` |
| `Private/Geometry/TransportCharts.wl` | `Private/Geometry/RationalizingCharts.wl` |
| `Private/Transport/Observable/ObservableTransport.wl` | `Private/Solutions/Operators/DemandRestrictedWordOperator.wl` |
| `.../ObservableTransportFiniteField.wl` | `.../DemandRestrictedWordOperatorFiniteField.wl` |
| `.../IteratedIntegralWords.wl` | `Private/Solutions/Functions/IteratedIntegralWords.wl` |
| `.../RationalEpsilonLayer.wl` | `Private/Solutions/Layers/RationalInEpsilonLayer.wl` |
| `.../RationalEpsilonLayerOperator.wl` | `.../RationalInEpsilonLayerSolutionOperator.wl` |
| `.../PhysicalTransportResult.wl` | `Private/Solutions/MasterIntegralEpsilonExpansionCoefficient.wl` |
| `Private/Transport/Boundary/PhysicalBoundary.wl` | `Private/Solutions/Boundary/EndpointBoundaryData.wl` |
| `.../FinishPhysicalTransport.wl` | `Private/Solutions/MasterIntegralSolution.wl` |
| `.../CompactEndpointResidue.wl` | `.../EndpointResidue.wl` |
| `.../PhysicalBoundaryCampaignAdapter.wl` | split between `Transport/EndpointToBasePointEvolution.wl` and `Solutions/Bindings/GradedBoundaryTransportBinding.wl` |
| `.../TangentialJunction.wl` | retain unless a real responsibility split is performed |
| `Scripts/Transport/` and `Tests/Transport/` | retain genuine path work; move solution construction to `Scripts/Solutions/` and `Tests/Solutions/` item by item |
| card `UU_ObservableTransport.wl` | `UU_MasterIntegralSolutionRequirements.wl` if it is a requirements card |

Generated V2 stems:

| Current stem | Final stem |
|---|---|
| `ObservableTransport_*` | `DemandRestrictedWordOperators_*` |
| `observable_transport_CF*.wl` | `demand_restricted_word_operator_CF*.wl` |
| `PhysicalBoundaryModes_*` | retain |
| `PhysicalEndpointTransport_*` | `GradedBoundaryTransportBindings_*` |
| `physical_endpoint_transport_CF*.wl` | `graded_boundary_transport_binding_CF*.wl` |
| `FinishedTransport_*` | `MasterIntegralSolutions_*` |
| `finished_transport_CF*.wl` | `master_integral_solution_CF*.wl` |

## 6. Compatibility boundary

The inventory found 15 affected package files, 32 scripts, 18 tests, 120
`observableTransport*` private symbols, 42 `finish*` helpers/globals, 30
`Period`-bearing keys, and 29 `Transport`-bearing keys.  There are also 585
generated legacy files, 87 result-log symlinks, and 13 result directories.

Migration rules:

1. use the package's existing `FormatVersion` mechanism and write V2 only;
2. read V1 under `HoldComplete` through one isolated
   `NormalizeLegacySolutionRecord`;
3. regenerate accepted scientific artifacts from inputs rather than editing
   serialized expressions in place;
4. keep V1 artifacts read-only until the V2 campaign passes;
5. do not rewrite `Exchange/`, prior evidence/logs, backups, or git history;
6. do not introduce a parallel `SchemaVersion` unless it has a separately
   documented meaning from `FormatVersion`.

## 7. Explicitly preserved or rejected terms

Preserve:

- `EpsilonForm`, `DLogEpsilonForm`, `FrobeniusExpansion`, `LeveltBasis`;
- `FundamentalSolutionMatrix` and `PathOrderedExponential` only for square
  homogeneous evolution;
- `ChenIteratedIntegral`, `GoncharovPolylogarithm`;
- `EllipticPeriod`, `PeriodMatrix`, `PeriodID` only for true period integrals;
- `TransportTo`, `AnalyticallyContinueSolution`, and endpoint/base-point
  transport that actually propagates data;
- `TangentialJunction` until code responsibilities justify a split;
- historical names inside immutable V1 artifacts and history.

Reject:

- `ObservableTransport`;
- generic `BoundaryPeriod`;
- top-level `FundamentalSolution` for a boundary-contracted result;
- `SelectedSolutionOperator` (can sound like a branch choice);
- `TruncatedPathOrderedExponential` for the current rectangular automaton;
- `BuildPhysicalFrobeniusBasis` for an incomplete selected-mode map;
- `OutputProjection` for a general rectangular functional map;
- `MasterIntegralCoefficients` for epsilon-expansion coefficients;
- `PhysicalSolutionComplete` before all boundary constants are resolved;
- `Finished` as a scientific status;
- a wholesale removal of the `Transport/` namespace;
- a blind global replacement of `PeriodID`, `Transport`, or generic file/status
  keys.

## 8. Primary terminology references

- Henn, *Lectures on differential equations for Feynman integrals* —
  canonical/dlog systems, path-ordered solutions, Chen iterated integrals, and
  boundary constants: https://arxiv.org/abs/1412.2296
- Hidding, *DiffExp* — `TransportTo` as transport of boundary conditions to a
  target point: https://arxiv.org/abs/2006.05510
- Lee, *Libra* — epsilon-form differential equations and boundary constants:
  https://arxiv.org/abs/2012.00279
- Frellesvig, *On Epsilon Factorized Differential Equations for Elliptic
  Feynman Integrals* — epsilon-factorized versus dlog structure and elliptic
  period matrices: https://arxiv.org/abs/2110.07968
- Broedel et al., *An analytic solution for the equal-mass banana graph* —
  elliptic periods and iterated-integral solutions:
  https://arxiv.org/abs/1907.03787
- Besier et al., *RationalizeRoots* — rationalizing square roots by changes of
  variables: https://arxiv.org/abs/1910.13251
- Brown, *On the periods of some Feynman integrals* — mathematical period
  language: https://arxiv.org/abs/0910.0114
- SeaSyde — analytic continuation and physical-region evaluation:
  https://arxiv.org/abs/2205.03345

## 9. Review provenance

The independent and Pro reviews agreed on the important boundaries:

- transport is real only for propagation along a path;
- a rectangular demand-selected map is not `Pexp` or a fundamental matrix;
- endpoint mode mapping and endpoint evolution must remain distinct;
- generic boundary constants are not periods;
- the pre-Stage-3 result is a master-integral solution in terms of boundary
  constants, not a completed physical-region solution;
- the rational-in-epsilon layer name must state that epsilon dependence, and
  selector attachment is not boundary-value substitution.

Where the reviews proposed different labels, this list chose the shorter name
that still matches the current code's actual object.  No listed replacement is
authorized for implementation until the user approves this document.
