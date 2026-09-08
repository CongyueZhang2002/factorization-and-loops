# Revised FeynFacet terminology after user and Fable review

**To:** Fable
**Date:** 2026-09-03
Status: **proposal only — no package identifiers have been changed**.

This document supersedes the disputed vocabulary in
`01_community_terminology_replacement_proposal.md`.  Public scientific names
must be normal terminology in differential equations, algebraic geometry, or
multiloop amplitudes.  Software terminology is confined to private
orchestration and must not masquerade as a mathematical stage.

Fable's Stage-1 additions (`OffDiagonalBlock`, `Inhomogeneity`, and
`BasisTransformation`) are accepted in substance.  The following parts of
Fable's note are corrected rather than adopted literally:

- this cannot be one pure lexical rename because several compound records
  must be split by mathematical domain and codomain;
- the current substitution verifier establishes a rationalizing
  parametrization, not a geometric chart or a generically birational change
  of variables;
- the current local solver uses a residue eigenbasis and does not implement
  the Jordan/logarithmic structure needed to claim a general `LeveltBasis`;
- generic `Period`, `BoundaryDatum`, bare `Word`, `Graded...`, `Binding`, and
  `Adapter` are not accepted as names for public mathematical objects;
- `EpsilonFactorizeFamily` is replaced by the standard public stage
  `TransformFamilyToEpsilonForm`, with the narrower internal operation named
  `FactorizeFamilyEpsilonDependence`.

## 1. User rulings on the disputed words

| Disputed term | Final rule | Reason |
|---|---|---|
| `Gauge` in the differential-equation pipeline | use `BasisTransformation` | Amplitude papers describe the master-integral matrix `T` as a transformation or change of basis. |
| `GaugeTransformation` | retain only in a private mathematical comment when the connection transformation law is meant literally | It is valid ODE geometry, but too overloaded for the public amplitude API. |
| generic `Period` | remove from the live boundary-condition API | The current records contain boundary constants and modes, not explicitly defined period integrals. |
| bare `Word` | remove from public symbols, records, and reports; name the representation explicitly | It hides whether the object is a letter sequence, integer-index sequence, integral value, or coefficient matrix. |
| `FundamentalSolutionMatrix` | `HomogeneousSolutionMatrix` | A square matrix whose columns solve the homogeneous differential equation. |
| `Chart` | `RationalizingChangeOfVariables` or `RationalizingParametrization` | These are the terms used in the root-rationalization literature; the current record is not a geometric chart with a declared domain. |
| `Frame` for root/variable records | remove; use `MultiquadraticFunctionFieldPresentation` and a rationalization map separately | A frame is a local basis; the current record instead specifies field generators and relations. |
| `Manifest` | private `InventoryMasterIntegralSolutionInputs` | The function discovers and classifies input files; it is not a mathematical object or stage. |
| `Endpoint` | use `RegularSingularPoint`, `BoundaryPoint`, `KinematicLimit`, or `PathEndpoint` according to meaning | These are distinct concepts in the differential-equation literature. |
| `Materialize` | private storage/implementation word only | Public mathematics should say `ConstructExplicit`, `Expand`, `Evaluate`, or `Reconstruct`. |
| `Strip` | `OffDiagonalBlock` | The solved object is Lee's off-diagonal block `(k,j)`. |
| `Forcing` | `Inhomogeneity` | It is the inhomogeneous term in the off-diagonal block equation. |
| square-root `Sheet` | `GaloisConjugate` for algebraic validation; `RootSignChoice` for a chosen sign | A genuine `RiemannSheet` remains distinct. |
| `Binding` / `Adapter` for mathematical data | replace by a map or operator whose domain and codomain are named | These names describe software plumbing rather than the stored mathematical map. |

## 2. Stage 1: epsilon-form construction

### 2.1 Off-diagonal blocks

The package must also distinguish the transformation problem, its equation,
the solver, and its result.  They are not all merely an "off-diagonal block":

| Mathematical object | Approved name |
|---|---|
| complete input problem for blocks `E`, `C`, and `B` | `OffDiagonalBlockTransformationProblem` |
| differential equation for the unknown block | `OffDiagonalBlockEquation` |
| linear operator acting on the ansatz | `OffDiagonalBlockLinearOperator` |
| solver | `SolveOffDiagonalBlockBasisTransformation` |
| solved unipotent block `G` | `OffDiagonalBasisTransformationBlock` |
| block after applying `G` | `TransformedOffDiagonalBlock` |

| Current | Revised name | Meaning |
|---|---|---|
| retired `SolveEpsFormStrip` | remove after V1 compatibility | Retired CANONICA/Maple route; do not give it a new live-looking name. |
| `SolveEpsFormStripInFrame` | `SolveOffDiagonalBlockBasisTransformation` | Dispatcher constructing the off-diagonal change-of-basis block. |
| `SolveEpsFormStripFiniteField` | `SolveOffDiagonalBlockBasisTransformationFiniteField` | Finite-field solution for that basis-transformation block. |
| `PrepareEpsFormStripSampling` | private `PrepareOffDiagonalBlockFiniteFieldSystem` | Prime-independent linear-system preparation. |
| `SampleEpsFormStripAffine` | private `ComputeOffDiagonalBlockFiniteFieldImage` | One finite-field image at a specified epsilon value. |
| `InterpolateEpsFormStripAffine` | private `InterpolateOffDiagonalBlockInEpsilon` | Reconstructs epsilon dependence over one prime field. |
| `ReconstructEpsFormStrip` | `ReconstructOffDiagonalBlockBasisTransformation` | CRT and rational reconstruction of the transformation and residues. |
| `VerifyEpsFormStrip` | `VerifyOffDiagonalBlockBasisTransformation` | Checks both unspecialized block equations and dlog conditions. |
| `EpsFormStripObstruction` | `OffDiagonalBlockEpsilonFormObstruction` | Tests whether the rational off-diagonal transformation can exist. |
| `InstallEpsFormStripSolution` | private `RecordVerifiedOffDiagonalBlockSolution` | Adds an accepted result to the family checkpoint. |
| private `epsFormStrip*` | private `offDiagonalBlock*` | Complete private prefix replacement. |
| private `multiquadraticStrip*` | private `multiquadraticOffDiagonalBlock*` | Multiquadratic implementation family. |
| private `finiteFieldStrip*` | private `finiteFieldOffDiagonalBlock*` | Finite-field implementation family. |

### 2.2 Inhomogeneity

| Current | Revised name | Meaning |
|---|---|---|
| `Forcing` | `Inhomogeneity` | Source term in the off-diagonal differential equation. |
| `DeferredForcing` | `DeferredInhomogeneity` | Unevaluated representation of that source term. |
| `ForcingChannels` | `InhomogeneityComponents` | Components in the declared coefficient-field basis. |
| `ForcingCoefficients` | `InhomogeneityCoefficients` | Coefficients of those components. |
| `ForcingInfinityDegree` | `InhomogeneityDegreeAtInfinity` | Degree bound at infinity. |
| `ForcingProvider` | private `InhomogeneityEvaluator` | Computes finite-field values of the source term. |
| private variable `bbar` | private `inhomogeneity` | Mathematical role of `bbar_(k,j)`. |
| all remaining DE `*Forcing*` literals | corresponding `*Inhomogeneity*` literal | One systematic family replacement. |

### 2.3 Basis transformation instead of gauge

| Current | Revised name | Meaning |
|---|---|---|
| `SolveDiagonalBlockGaugeFiniteField` | `SolveDiagonalBlockBasisTransformationFiniteField` | Solves for the rational transformation `T`. |
| retired `SolveResidueRationalGauge` | remove after V1 compatibility | Retired Maple route. |
| `Gauge` storing complete `T` | `BasisTransformationMatrix` | Complete change of master-integral basis. |
| `Gauge` storing off-diagonal `G` | `OffDiagonalBasisTransformationBlock` | One unipotent off-diagonal block of the transformation. |
| actual connection action | `ConnectionGaugeTransformation` | The literal operation `A -> T^-1 A T - T^-1 dT`. |
| `GaugeIdentity` meaning `T == I` | `BasisTransformationIsIdentity` | Whether the transformation is the identity. |
| `GaugeIdentity` meaning `T T^-1 == I` | `BasisTransformationInverseIdentity` | Inverse relation for the transformation matrix. |
| `GaugeIdentity` meaning the transformed DE | `TransformedConnectionIdentity` | The differential connection transformation equation. |
| `GaugeDenominator` | `OffDiagonalBasisTransformationDenominator` | Denominator of the rational off-diagonal ansatz. |
| `GaugeDenominatorDegrees` | `OffDiagonalBasisTransformationDenominatorDegrees` | Degree bounds of that denominator. |
| `GaugeNumeratorDegrees` | `OffDiagonalBasisTransformationNumeratorDegrees` | Degree bounds of the numerator. |
| `GaugeSupport` | `OffDiagonalBasisTransformationNumeratorSupport` | Numerator monomials retained in the ansatz. |
| `GaugeSupportCount` | `OffDiagonalBasisTransformationNumeratorTermCount` | Number of retained numerator monomials. |
| `GaugeUnknownCount` | `OffDiagonalBasisTransformationUnknownCount` | Number of unknown transformation coefficients. |
| operation `GaugePullBack` | `PullBackBasisTransformation` | Rewrites the transformation in the original variables. |
| resulting pulled-back object | `PulledBackBasisTransformation` | Transformation after the variable substitution. |
| `GaugeRoundTrip` | `BasisTransformationRoundTrip` | Agreement after forward and inverse variable changes. |
| `GaugeAtEndpoint` at a regular base point | `BasisTransformationAtBasePoint` | Ordinary evaluation at a regular point. |
| `GaugeAtEndpoint` at a singular boundary | `RegularizedBasisTransformationAtBoundaryPoint` | Regularized limiting value, not direct substitution. |
| `OutputGaugeByOrder` | `PhysicalBasisTransformationCoefficientsByEpsilonOrder` | Output-basis transformation coefficients. |
| `GaugeConstantRules` | `BasisTransformationNormalizationRules` | Rules fixing constant basis freedom. |
| `GaugeMatrices` | `BasisTransformationMatrices` | Epsilon-graded transformation matrices. |
| `GaugeTokens` | `BasisTransformationEpsilonOrders` | Epsilon orders indexing those matrices. |
| `GaugeStatus` | `BasisTransformationStatus` | Construction state of the transformation. |
| `GaugeImages` | `BasisTransformationFiniteFieldImages` | Modular images used for reconstruction. |
| `FamilyRowGauge*` | `FamilyRowBasisTransformation*` | Row-wise assembly of the family transformation. |
| `FiniteFieldGaugePullBack*` | `FiniteFieldBasisTransformationPullback*` | Modular pullback and reconstruction implementation. |

Actual gauge-theory terms elsewhere in the package, such as a QCD gauge or
gauge invariance, are unaffected.

### 2.4 Epsilon factorization

| Current | Revised name | Meaning |
|---|---|---|
| public family stage | `TransformFamilyToEpsilonForm` | Names the mathematical output of the complete transformation. |
| `FactorFamilyRegulatorDependence` | private `FactorizeFamilyEpsilonDependence` | Removes residual epsilon dependence using a constant `T(epsilon)`. |
| `FactorFamilyRegulatorDependenceInFrame` | private dispatcher `FactorizeFamilyEpsilonDependence` | Selects the rational or multiquadratic implementation. |
| `FactorFamilyRegulatorDependenceMultiquadratic` | private `FactorizeFamilyEpsilonDependenceOverMultiquadraticField` | Grade-wise sufficient solver over the multiquadratic extension. |

The internal name is intentionally narrower than the public stage: the routine
does not perform arbitrary epsilon-form construction; it factorizes the
remaining epsilon dependence of an already dlog connection with a constant
basis transformation.

## 3. Variables and algebraic coefficient fields

| Current | Revised name | Meaning |
|---|---|---|
| `TransportFamilyInChart` assembly-only behavior | `AssembleFamilyEpsilonForm` | Combines certified block transformations into the family system. |
| default integration branch of `TransportFamilyInChart` | retire with `TransportFamily` | It calls the retired integration route. |
| `TransportChartCatalog` | `RationalizationMapCatalog` | Catalog of classified rationalizing maps. |
| current `TransportChartVerify` | `VerifyRationalizingParametrization` | It checks root identities and Jacobian, but not a rational inverse. |
| future verifier with a certified rational inverse | `VerifyRationalizingChangeOfVariables` | Establishes a generically birational variable change. |
| `TransportRootSetChart` | `FindRationalizingParametrizationForRoots` | Finds a rational map for a specified root set. |
| `ComposeTransportChartExtension` | `ComposeRationalizingParametrizations` | Composes the rational maps. |
| `RationalizeTransportChartExtension` | `ExtendRationalizingParametrization` | Rationalizes one additional root. |
| `BuildAlgebraicTransportFrame` | `BuildMultiquadraticFunctionFieldPresentation` | Specifies generators, square relations, ordering, and algebra basis. |
| `TransportFamilyChartRegister` | private `RegisterFamilyRootData` | Registers either a rationalizing substitution or root squares. |
| `TransportFamilyChartLoad` | private `LoadFamilyRootData` | Loads that campaign configuration. |
| `TransportFamilyChart` | private `FamilyRootData` | Retrieves the family root description. |
| key `Chart` | `RationalizingParametrization`; upgrade to `RationalizingChangeOfVariables` only after a rational inverse is verified | The actual rational map. |
| key `ChartVariables` | `NewVariables` | Variables after substitution. |
| key `ChartCertificate` | `ChangeOfVariablesVerification` | Exact verification of the substitution. |
| root-field key `Frame` | `MultiquadraticFunctionFieldPresentation` | Algebraic field presentation, not a basis. |
| `NoRationalChart` | `NoRationalizingParametrization` | No catalogued rationalizing map exists. |

The former aggregate `Frame` should not survive under another umbrella name.
Its mathematical components are separate:

| Content | Approved name |
|---|---|
| roots, square relations, generator ordering, and algebra-basis convention | `MultiquadraticFunctionFieldPresentation` |
| generically birational rationalizing substitution and inverse | `RationalizingChangeOfVariables` |
| rationalizing map without a verified rational inverse | `RationalizingParametrization` |
| Jacobian acting on differentials | `DifferentialPullbackMap` |
| physical square-root prescription | `RootBranchConvention` |
| finite sign tuples used for modular evaluation | `RootSignChoices` |
| automorphism action on the multiquadratic extension | `GaloisAction` |

Likewise, `Sheet` cannot undergo one global replacement:

| Actual meaning | Approved name |
|---|---|
| one tuple of independent square-root signs | `RootSignChoice` |
| the collection of such tuples | `RootSignChoices` |
| algebraic images under sign-changing automorphisms | `GaloisConjugates` |
| branch selected by the physical prescription | `PhysicalBranchChoice` |
| branch convention followed along a path | `AnalyticBranchConvention` |
| a genuine analytic sheet of a branched cover | `RiemannSheet` (retain) |

## 4. Boundary points and local differential equations

| Current | Revised name | Meaning |
|---|---|---|
| `BuildEndpointFrobenius` | `ConstructFrobeniusExpansionAtRegularSingularPoint` | Local Frobenius solution at a regular singular point. |
| option/key `Endpoint` in that calculation | `RegularSingularPoint` | Point about which the local series is constructed. |
| compound `EndpointSpec` | split into `RegularSingularPointSpec`, `KinematicLimitSpec`, `BasePointSpec`, and, only where applicable, `PathEndpointSpec` | The current key conflates four different roles. |
| `BuildBoundaryModeMap` | `ConstructBoundaryModeMatchingMatrix` | Matches declared physical boundary behavior to local Frobenius modes. |
| `BoundaryDegenerateEigenspaceDeclaration` | `DegeneratePhysicalBoundaryModeData` | Degenerate local-mode information and relations. |
| `BuildEndpointLeveltModeConnection` | `TransformTangentialConnectionToResidueEigenbasis` | Current code uses a diagonal residue eigenbasis, not a full Levelt basis. |
| current `LeveltBasis` claim | reserve for future Jordan/log implementation | Current implementation rejects the relevant generalized modes. |
| `BuildTransportBoundaryVector` | `ConstructBoundaryVectorFromConstants` | Forms the boundary vector from its independent constants. |
| `BoundaryPeriodCoefficient` | `BoundaryConstantCoefficient` | Epsilon coefficient of a boundary constant. |
| `BuildCompactEndpointResidue` | `ConstructResidueAtRegularSingularPoint` | Residue matrix of the local differential equation. |
| `BuildRationalEpsilonLayerEndpointResidue` | `ConstructRationalInEpsilonLayerResidueAtRegularSingularPoint` | Corresponding residue for the final layer. |
| `PhysicalEndpointRelation` | `BoundaryLimitCoordinateRelation` | Relation between the physical limit and local coordinate. |
| `PhysicalEdgePoint` | `PhysicalBoundaryPoint` | Kinematic point or stratum supplying boundary behavior. |
| `EndpointPath` | `BoundaryPointToBasePointPath` | Path from the physical boundary to the regular base point. |
| a true terminal point of a path | `PathEndpoint` | Retains endpoint only in its standard path meaning. |

`Endpoint` is therefore not banned English; it is reserved for an actual end
of an oriented path.  A soft, collinear, or threshold approach is a
`KinematicLimit`; a positive-dimensional limiting locus may be called a
`BoundaryStratum`.

## 5. Boundary constants: no live `Period*` vocabulary

`Period` has a precise mathematical meaning: an integral over a specified
cycle/contour or algebraic domain.  The present boundary records do not supply
such definitions.  Therefore the V2 live API uses no `Period*` name.

| Current | Revised name | Meaning |
|---|---|---|
| structural or realization `PeriodID` | `BoundaryModeID` | Identifies a local Frobenius mode before independent constants are chosen. |
| independent-coordinate `PeriodID` | `BoundaryConstantID` | Identifies one independent integration constant. |
| `ParentPeriodID` | `ParentBoundaryModeID` | Parent local mode of related mode realizations. |
| `BoundaryIntegralID` | retain only when an explicit boundary integral is supplied | Identifies a calculation used to determine a constant. |
| `PeriodBasis` | `BoundaryConstantBasis` | Independent constant coefficients after relation reduction. |
| `PeriodRelations` | `BoundaryConstantRelations` | Exact relations among constants. |
| `PeriodCoordinates` | `BoundaryConstantCoordinates` | Pairs of constant ID and epsilon order. |
| `PeriodCoordinatesByBinding` | `BoundaryConstantCoordinatesByMap` | Coordinates grouped by the mathematical coefficient map in which they occur. |
| `LocalPeriodCoordinates` | `LocalBoundaryConstantCoordinates` | Coordinates local to one family calculation. |
| `FormalPeriodCoordinates` | `UndeterminedBoundaryConstantCoordinates` | Constants not yet evaluated. |
| `PeriodEpsilonValuation` | `BoundaryConstantEpsilonValuation` | Lowest epsilon order of the series. |
| `PeriodOrderWindow` | `BoundaryConstantEpsilonOrderRange` | Required epsilon orders. |
| `PeriodClass` | `BoundaryConstantFunctionClass` | Rational, multiple-polylogarithmic, or elliptic. |
| `PeriodStatus` | `BoundaryConstantEvaluationStatus` | Known, zero, related, or undetermined. |
| `BoundaryPeriodsEvaluated` | `BoundaryConstantsDetermined` | Whether all required constants are known. |
| `MissingEllipticPeriods` | `UndeterminedEllipticBoundaryConstants` | Unknown constants in the elliptic function class. |
| `EllipticBoundaryPeriodsIncomplete` | `EllipticBoundaryConstantsIncomplete` | Required elliptic constants are missing. |
| `Stage3NeedsLedger` | `BoundaryConstantRequirements` | Constants and epsilon orders needed for Stage 3. |
| `Stage3SeriesCount` | `BoundaryConstantSeriesCount` | Number of distinct constant series. |
| `Stage3CoordinateCount` | `BoundaryConstantCoefficientCount` | Number of required epsilon coefficients. |
| `CertifiedPeriodIDs` | `VerifiedBoundaryModeIDs` | Local modes whose acceptance evidence has been checked. |
| `StructuralPeriodIDs` | `StructuralBoundaryModeIDs` | Local modes required by the Frobenius analysis. |
| `KnownZeroLedgerPeriodIDs` | `KnownZeroBoundaryModeIDs` | Local modes proved to vanish under the boundary conditions. |
| `UnevaluatedStructuralPeriodIDs` | `UndeterminedStructuralBoundaryModeIDs` | Local modes whose independent constants still require determination. |

If the package later constructs a genuine elliptic period
`Integral[omega, cycle]`, that new mathematical object may be called
`EllipticPeriod`; it must not share the boundary-constant schema above.

There is deliberately no replacement umbrella such as `BoundaryDatumID` or
`BoundaryConditionID`: a mode, an independent constant, and an integral used
to determine that constant need not be in one-to-one correspondence.  The
live identifiers are only `BoundaryModeID`, `BoundaryConstantID`, and, when
an explicit integral exists, `BoundaryIntegralID`.

## 6. Iterated integrals: remove bare `Word`

| Current | Revised name | Meaning |
|---|---|---|
| `TransportIteratedIntegral` | `ChenIteratedIntegral` | The iterated integral itself. |
| a sequence of actual letters or kernels | `IteratedIntegralLetterSequence` | Ordered sequence `(omega_1,...,omega_n)`. |
| internal/public `TransportWord` containing integers | `IteratedIntegralIndexSequence` | Ordered list of indices into the alphabet. |
| an interned integer-sequence identifier | `IteratedIntegralIndexSequenceID` | Identifier of one stored index sequence. |
| `TransportAlgebraicRoot` | `AlgebraicLetterRoot` | Algebraic marked point or letter datum. |
| `TransportLetterKernel` | `IteratedIntegralLetterKernel` | Differential one-form associated with a letter. |
| `ExpandTransportWordLetters` | `ExpandIteratedIntegralLetterSequence` | Rewrites composite letters as an explicit letter sequence. |
| `DemandRestrictedWordOperator` | private `DemandRestrictedIteratedIntegralCoefficientOperator` | Produces coefficient matrices only for master-integral outputs requested by the caller. |
| `BuildObservableTransportManifest` or `BuildDemandRestrictedWordOperatorManifest` | private `InventoryMasterIntegralSolutionInputs` | Discovers and classifies files needed by the solution calculation. |
| `BuildDemandRestrictedWordOperator` | private `ConstructDemandRestrictedIteratedIntegralCoefficientOperator` | Constructs the demand-restricted linear operator. |
| coefficient for one sequence | `IteratedIntegralCoefficientMatrix` | Matrix multiplying one iterated integral. |
| `DemandRestrictedWordMap` / association from sequences to coefficients | private `DemandRestrictedIteratedIntegralCoefficientMap` | Maps each requested index sequence to its coefficient matrix. |
| `ReconstructDemandRestrictedWordMaps` | private `ReconstructDemandRestrictedIteratedIntegralCoefficientMap` | Recovers exact requested coefficient matrices from finite-field data. |
| `OperatorAutomaton` | private `DemandRestrictedIteratedIntegralCoefficientOperator` | Current rectangular lazy representation. |
| `CompactTransportAutomaton` | private `CompressedIteratedIntegralCoefficientOperator` | Reduced internal representation. |
| `WordRepresentation` | `IteratedIntegralRepresentation` | Explicit coefficients or an internal operator. |
| `MaterializedWords` | `ExplicitIteratedIntegralCoefficients` | Explicit coefficient representation rather than the lazy operator. |
| `MaterializedWordLimit` | `ExplicitIteratedIntegralTermLimit` | Coding limit on explicit terms. |
| `MaterializedWordCountUpperBound` | `IteratedIntegralTermCountUpperBound` | Predicted number of explicit terms. |
| `TransportWordExpanded` | `ExplicitIteratedIntegralCoefficientsConstructed` | Whether explicit coefficient terms were produced. |
| `EndpointConnectionWord[path,...]` | private `BoundaryToBasePointChenIteratedIntegral[path,...]` | Inert iterated-integral value on the boundary-to-base-point path. |
| keys such as `CurrentFirstWord` and `EndpointSecondWord` | `CurrentPathFirstIndexSequence`, `BoundaryPathSecondIndexSequence`, and analogous explicit names | Index sequences on named path segments. |
| `WordMaps` | `IteratedIntegralCoefficientMaps` | Sequence-to-coefficient associations. |
| `RationalEpsilonLayerWordMap` | `RationalInEpsilonLayerIteratedIntegralCoefficients` | Coefficients associated with one iterated integral. |

Local variables named `word` may remain inside low-level shuffle-algebra code,
where the term has its standard combinatorial meaning.  They do not appear in
the public API, stored V2 schema, or user reports.

## 7. Boundary-to-base-point maps

The current campaign adapter combines several mathematical maps.  Fable's
suggestion cannot be implemented as a pure rename; the object must first be
split according to its mathematics.

| Mathematical object | Approved name | Meaning |
|---|---|---|
| physical boundary modes to local Frobenius coordinates | `BoundaryModeMatchingMatrix` | Matching imposed by the physical boundary behavior. |
| regularized propagation of local solution data from the boundary to the base point | `BoundaryToBasePointEvolutionOperator` | Evolution along the specified path; it does not map one point to another. |
| composition of matching and evolution | `BoundaryModeToBasePointCoefficientMap` | Maps boundary-mode coordinates to solution coefficients at the base point. |
| independent boundary constants to master-integral coefficients | `BoundaryConstantToMasterIntegralCoefficientMap` | Names both domain and codomain. |
| the preceding map indexed by epsilon order | `BoundaryConstantToMasterIntegralCoefficientMapByEpsilonOrder` | Epsilon-expanded coefficient maps. |
| the preceding map organized by iterated-integral weight | `BoundaryConstantToMasterIntegralCoefficientMapByIteratedIntegralWeight` | Weight decomposition used by the current row-space implementation. |

The current `BuildEndpointAutomatonBoundaryAdapter` record contains matching,
evolution, projection, requested-sequence data, and a boundary-constant
requirements list.  It must therefore be decomposed before renaming its
mathematical pieces.  Its principal composed output becomes
`BoundaryModeToBasePointCoefficientMap`; strictly representational conversion
helpers may retain private `adapter` terminology.

The current `BuildGradedPhysicalEndpointTransport` is explicitly organized by
iterated-integral weight (`GradesByWeight`), so its mathematical result becomes
`BoundaryConstantToMasterIntegralCoefficientMapByIteratedIntegralWeight`, not
the ambiguous `GradedBoundaryConstantMap`.  A separate epsilon-indexed view,
if exposed, uses the `...ByEpsilonOrder` name.  The two current
`Compose...Words` functions should become constructors of *requested
iterated-integral coefficient maps* after the sequence terminology in section
6 is applied; a blind one-to-one lexical rename is rejected.

## 8. Public operation verbs

| Operation | Verb |
|---|---|
| solve a differential equation | `Solve` |
| assemble already solved blocks | `Assemble` |
| construct a mathematical object from known ingredients | `Construct` |
| determine free constants or relations | `Determine` |
| change basis or variables | `Transform` |
| produce a local or epsilon expansion | `Expand` |
| compute a value at specified kinematics | `Evaluate` |
| recover exact expressions from modular data | `Reconstruct` |
| force a lazy object into explicit storage | private `Materialize` only |
| discover and classify campaign input files | private `Inventory` |

Accordingly, the public result builder should be
`ConstructMasterIntegralSolution`, while the coding implementation may still
use private `build...` helpers.

`Materialize` is not a mathematical stage.  It is a standard programming verb
for forcing a deferred/lazy representation into explicit storage and may stay
in such private helpers.  A public operation must instead say what it does:
`ConstructExplicitMasterIntegralCoefficient`,
`ExpandIteratedIntegralLetterSequence`, `EvaluateAtKinematicPoint`, or
`ReconstructFromFiniteFieldImages`.  These are not interchangeable synonyms.

Likewise, `Manifest` is a software term for an authoritative declared file
list.  The present function discovers and classifies whatever inputs exist, so
the accurate private name is `InventoryMasterIntegralSolutionInputs`; if the
two operations are later separated, use
`DiscoverMasterIntegralSolutionInputs` and
`ClassifyMasterIntegralSolutionInputs`.

## 9. Function classes and other retained scientific terms

| Meaning | Approved term | Boundary of use |
|---|---|---|
| system with an overall epsilon factor | `EpsilonFactorizedSystem` | Does not by itself assert a dlog alphabet. |
| epsilon-factorized system with constant residue matrices multiplying dlog letters | `DLogEpsilonForm` | Stronger statement than merely epsilon-factorized. |
| solution class generated by multiple polylogarithms | `MultiplePolylogarithmic` | Use for a function-class tag. |
| an explicit `G(a_1,...,a_n;z)` function | `GoncharovPolylogarithm` | Use for the represented function, not the whole class. |
| ordered path integral in Chen's sense | `ChenIteratedIntegral` | Mathematical integral value, not its index sequence. |
| local regular-singular expansion | `FrobeniusExpansion` | Current implementation supports the stated residue-eigenbasis case. |
| square invertible matrix whose columns solve the homogeneous system | `HomogeneousSolutionMatrix` | Do not use for a rectangular requested-output operator. |
| solution of an inhomogeneous system from a homogeneous solution matrix | `VariationOfConstants` | Standard method name in prose. |

The old `GPL` abbreviation should not be used as a generic function-class tag.
Where code stores a rational factor participating in a Goncharov-polylogarithm
letter, it must be named for that actual factor rather than mechanically
replacing every `GPL*` stem.

## 10. Primary references

- Henn, *Lectures on differential equations for Feynman integrals*:
  https://arxiv.org/abs/1412.2296
- Meyer, *Transforming differential equations of multi-loop Feynman integrals
  into canonical form*: https://arxiv.org/abs/1611.01087
- Adams and Weinzierl, *The epsilon-form ... in the elliptic case*:
  https://arxiv.org/abs/1802.05020
- Primo and Tancredi, *Maximal cuts and differential equations for Feynman
  integrals*: https://arxiv.org/abs/1704.05465
- Hidding, *DiffExp*: https://arxiv.org/abs/2006.05510
- Besier, Wasser and Weinzierl, *RationalizeRoots*:
  https://arxiv.org/abs/1910.13251

No implementation is authorized until the user approves the revised names and
the required semantic splits.
