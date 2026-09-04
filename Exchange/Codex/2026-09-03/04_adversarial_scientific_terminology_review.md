# Adversarial scientific review of the FeynFacet terminology proposal

**To:** Fable and user
**Date:** 2026-09-03
**Status:** terminology proposal only; no package identifiers have been changed
**Reviews:** linear differential equations/algebraic geometry; multiloop-amplitude practice; iterated-integral and boundary-value mathematics; independent ChatGPT Pro literature audit

This note supersedes the candidate rulings in
`02_community_vocabulary_revision_after_fable_review.md` wherever the two
disagree.  A name is accepted only if it is either (i) established terminology
for the actual object or (ii) a transparent compound of established terms
whose domain, codomain, or representation is explicit.  A plausible-sounding
compound is not accepted merely because it reads smoothly.

## Verdict

The proposal's direction is correct, but it is not ready for a rename pass.
The adversarial review found several mathematical overclaims:

1. the assembly-only family result has epsilon-form **diagonal blocks**, not a
   whole-family epsilon form;
2. the current square-root record does not establish the independence needed
   to call it a multiquadratic field or all sign images Galois conjugates;
3. several boundary records are finite, requested-output coefficient maps,
   not square matching matrices or full evolution operators;
4. the current local routine supplies a truncated Frobenius construction and
   may accept an ordinary point; it does not implement a general Levelt basis;
5. the inert iterated-integral head and path-segment index tuples must not be
   described as evaluated Chen integrals or as one word on a concatenated path;
6. one `PeriodID` currently conflates an integration constant, a boundary
   function on a positive-dimensional stratum, a local mode, an integral
   representation, and sometimes a relation.  It must be split by
   mathematical role rather than lexically renamed.

The reviewers disagreed on several terms; the following rulings apply:

- Standard ODE books prefer `FundamentalSolutionMatrix`, but the directly
  attested amplitude phrase `MatrixOfHomogeneousSolutions` is retained because
  it exposes the homogeneous-equation meaning the user requested.
- “Word” is standard in shuffle algebras, but the user's ambiguity objection
  is valid at the package boundary.  Public records use explicit letter/index
  sequence names; `word` may remain only in low-level algebra prose or locals.
- `BoundaryData` is retained solely as the standard collective DE phrase for
  constants and tangential functions.  There is no generic `BoundaryDataID`.
- A full `BoundaryToBasePointEvolutionOperator` is valid mathematics, but the
  present requested-output rectangular record is not that operator.
- Although a Frobenius construction at a regular singular point is standard,
  the current routine also admits zero residue; its general API therefore uses
  `LocalExpansionPoint` and records the point type separately.

## 1. Basis changes and epsilon-form construction

| Candidate/current wording | Final proposed wording | Ruling and mathematical reason |
|---|---|---|
| public `ConnectionGaugeTransformation` | `TransformConnectionUnderBasisChange` | A connection gauge transformation is genuine mathematics, but the explicit public verb is clearer and avoids reviving the package-wide `Gauge` ambiguity. Documentation may state that this is the gauge action of a basis change. |
| complete invertible `Gauge` | `BasisTransformationMatrix` | Established amplitude language for the matrix `T`. |
| off-diagonal `Gauge` block | `OffDiagonalBasisTransformationBlock` | A block of `T`, not a complete invertible basis transformation. |
| `SolveOffDiagonalBlockBasisTransformation` | `SolveOffDiagonalBasisTransformationBlock` | Removes the grammatical ambiguity between transforming a connection block and solving for a block of `T`. |
| `ReconstructOffDiagonalBlockBasisTransformation` | `ReconstructOffDiagonalBasisTransformationBlock` | Same object distinction. |
| `VerifyOffDiagonalBlockBasisTransformation` | `VerifyOffDiagonalBasisTransformationBlock` | Same object distinction. |
| `TransformedOffDiagonalBlock` | `TransformedOffDiagonalConnectionBlock` | Explicitly identifies the block as belonging to the transformed connection rather than to `T`. |
| analyzer named `OffDiagonalBlockEpsilonFormObstruction` | `AnalyzeOffDiagonalBlockEpsilonFormObstructions` | The routine has finite-ansatz inconsistencies, negative-to-finite-order results, missing-letter results, and genuine no-go outcomes; the analyzer itself is not an obstruction certificate. |
| failure within a chosen denominator/support/alphabet ansatz | `OffDiagonalBlockAnsatzInconsistency` | Failure of one finite ansatz is not a theorem that no transformation exists. |
| ansatz-independent positive no-go payload | `OffDiagonalBlockDLogEpsilonFormObstructionCertificate` | Reserved for an actual mathematical obstruction after eliminating ansatz choices. |
| `InhomogeneityDegreeAtInfinity` | split into `InhomogeneityPoleOrderAtInfinity`, `InhomogeneityValuationAtInfinity`, or `InhomogeneityNumeratorDegreeBoundAtInfinity` | A projective valuation, a pole order, and a polynomial-support degree bound are different invariants. |
| `GaugeIdentity` | split into `BasisTransformationInverseVerified`, `BasisTransformationInverseResidual`, `ConnectionTransformationEquationVerified`, and `ConnectionTransformationResidual` | A Boolean, an equation, and a residual are not one object called an identity. |
| `GaugeConstantRules` | `BasisNormalizationParameterRules` | The rules fix scalar parameters in a basis normalization. |
| `GaugePullBack` when substituting the inverse parametrization | `ReexpressBasisTransformationInSourceVariables` | The operation re-expresses `T(x,y)` in source variables; calling it a pullback along the original parametrization reverses the mathematical arrow. |
| `GaugeRoundTrip` | `BasisTransformationCoordinateReexpressionVerified` | States the property actually tested. |
| rectangular `OutputGaugeByOrder` | `CanonicalToPhysicalMasterIntegralMapByEpsilonOrder` | A rectangular map from canonical coordinates to selected physical master integrals is not a basis transformation. |
| other rectangular rational-layer `GaugeMatrices` | `OffDiagonalTransformationBlockCoefficients` (with `...ByEpsilonOrder`, `...FiniteFieldImages`, and `...Status` as appropriate) | Rectangular blocks cannot be called invertible basis-transformation matrices. |
| generic `TransformFamilyToEpsilonForm` | split into `TransformFamilyDifferentialSystemToEpsilonFactorizedForm` and `TransformFamilyDifferentialSystemToDLogEpsilonForm` | Epsilon factorization and dlog form are distinct mathematical properties; the second name is allowed only when every kernel has the declared dlog form. |
| `FactorizeFamilyEpsilonDependence` | `FindKinematicsIndependentBasisTransformationToEpsilonForm` | The routine searches for a constant-in-kinematics `T(epsilon)`; it is not scalar polynomial factorization. Square-root component decomposition should be a method field, not a second mathematical operation name. |
| suffix `...OverMultiquadraticField` on that routine | remove; use method field `EquationComponentDecomposition -> SquareRootComponents` | The sought transformation remains rational in epsilon; square roots are used to decompose the equations, not as the coefficient field of the resulting transformation. |
| `AssembleFamilyEpsilonForm` | `AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks` | The current assembly verifies epsilon-linear diagonal blocks while retaining general transformed lower off-diagonal blocks. Calling the result a family epsilon form is false. |
| status `ExactFamilyAssembly` | `FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks` | Matches the actual completed property. |

The established terms retained here are `OffDiagonalBlock`,
`OffDiagonalBlockEquation`, `OffDiagonalBlockLinearOperator`,
`Inhomogeneity`, `BasisTransformationMatrix`, `EpsilonFactorizedSystem`, and
`DLogEpsilonForm`.  The last is a transparent package compound and must retain
its explicit definition: an epsilon-factorized connection with constant
matrices multiplying dlog one-forms.  Meyer and Lee use the diagonal/off-
diagonal block and basis-transformation language; the literature also
distinguishes epsilon factorization from the stronger dlog property.

## 2. Rationalization and square-root extensions

| Candidate/current wording | Final proposed wording | Ruling and mathematical reason |
|---|---|---|
| `RationalizationMapCatalog` | `RationalizingParametrizationCatalog` | Every current entry is treated as a parametrization; no rational inverse is certified. |
| `FindRationalizingParametrizationForRoots` | `LookupCataloguedRationalizingParametrizationForRoots` | The routine sorts and retrieves catalog entries; it does not solve a rational-parametrization problem. |
| `NoRationalizingParametrization` | `NoCataloguedRationalizingParametrization` | A catalog miss is not a nonexistence theorem. |
| `NewVariables` | `ParametrizingVariables` | Identifies their mathematical role. |
| `ChangeOfVariablesVerification` for the current check | `RationalizingParametrizationVerification` | The check establishes forward root identities and a nonzero Jacobian, not a rational inverse. |
| `RationalizingChangeOfVariables` | retain only after a generically birational inverse is verified | A one-way rationalizing substitution remains a `RationalizingParametrization`. |
| current `MultiquadraticFunctionFieldPresentation` candidate | `SquareRootGeneratorsAndQuadraticRelations` | The builder records square-root generators and their individual square relations but does not prove square-class independence or construct a degree-`2^r` field presentation. |
| future dependency-verified object | `MultiquadraticFunctionFieldPresentation` | Allowed only once generator relations and independence over the stated constant field are established. |
| raw finite-field `GaloisConjugates` | `SquareRootSignChangeImages` | Independent sign masks are not automatically distinct Galois automorphisms. |
| `GaloisAction` / `GaloisConjugates` | retain conditionally | Use only after the multiquadratic field and the relevant automorphisms have been established. |
| `RootSignChoice(s)` | retain | Exact description of a sign tuple used during evaluation. |
| signs at one point called analytic branches | `PhysicalRootSignChoice` or `SquareRootSignsAtSamplePoint` | A pointwise sign does not encode cuts or analytic continuation. |
| `AnalyticBranchConvention` | retain only when the domain, cuts, and continuation prescription are stored | This is a stronger analytic object than a sign tuple. |
| genuine analytic cover | `RiemannSheet` | Retain only in its standard sense. |

`Chart` remains legitimate algebraic-geometry vocabulary, but the current
records are not charts: they do not declare a chart domain and inverse.  The
rationalization literature uses rational parametrizations and changes of
variables, so those terms remain preferred here.

## 3. Local solutions and physical boundary conditions

| Candidate/current wording | Final proposed wording | Ruling and mathematical reason |
|---|---|---|
| `ConstructFrobeniusExpansionAtRegularSingularPoint` | `ComputeTruncatedLocalFrobeniusExpansion` | The routine computes finite coefficient rectangles for the local prefactor and residue and may accept zero residue at an ordinary point. The result should separately classify the expansion point. |
| unconditional key `RegularSingularPoint` | `LocalExpansionPoint`, plus `PointType -> OrdinaryPoint | RegularSingularPoint` | Do not assert a singularity before it is established. |
| `ConstructResidueAtRegularSingularPoint` | `ComputeConnectionResidueAtLocalExpansionPoint` | It computes a connection residue; the point classification is separate. |
| `BuildEndpointLeveltModeConnection` | `TransformTangentialConnectionToNormalResidueEigenbasis` | This is exactly what the current code does. It diagonalizes the normal residue and transforms the tangential connection, including the derivative of the moving basis. |
| current `LeveltBasis` claim | remove | A diagonal residue eigenbasis is not a general Levelt basis with the required Jordan/logarithmic structure. Reserve `LeveltBasis` for a future implementation that actually constructs it. |
| `ConstructBoundaryModeMatchingMatrix` | function `MatchBoundaryAsymptoticsToFrobeniusModes`; result `BoundaryAsymptoticModeMatching` | The present function returns normalized mode records, eigenspace information, relations, and incomplete cases—not one matrix. |
| a future actual matrix from asymptotic coefficients to modes | `AsymptoticCoefficientToFrobeniusModeMatrix` | Use `Matrix` only when this rectangular/square array is explicitly constructed. |
| `DegeneratePhysicalBoundaryModeData` | split into `DegenerateResidueEigenspaceBasis` and `BoundaryConstantRelations` | “Data” hides two distinct mathematical objects and the present record does not prove that the entire eigenspace has one constant. |
| `ConstructBoundaryVectorFromConstants` for the compound association | split into `ConstructBoundarySelectorMatrices` and either `ConstructBoundaryValueVectorFromConstants` or `ConstructBoundaryValueVectorFromFunctions` | The present return value contains both, plus requirements metadata; on a positive-dimensional stratum the undetermined coefficients may be functions of tangential variables. |
| `BoundaryConstantCoefficient[id,n]` | `BoundaryConstantEpsilonCoefficient[id,n]`; on a stratum, `BoundaryFunctionEpsilonCoefficient[id,n]` | This is the coefficient of epsilon to power `n`, not the coefficient multiplying a boundary quantity in the final solution. |
| `BoundaryLimitCoordinateRelation` | `PhysicalLimitToLocalCoordinateRelation` | The stored equation is specifically `t = alpha rho^kappa` between a physical limiting parameter and a local expansion coordinate. |
| blanket `PhysicalBoundaryPoint` | split into `PhysicalBoundaryPoint`, `PhysicalBoundaryStratum`, `SelectedBoundaryPreimage`, and `NormalApproachDirection` | A positive-dimensional soft/collinear/threshold locus is not a point. |
| blanket `BoundaryPointToBasePointPath` | `SelectedBoundaryPreimageToBasePointPath` or `TangentialBoundaryToBasePointPath`, according to the path | Name the actual source of the path. |
| `Endpoint` used generically | remove | Use `LocalExpansionPoint`, `PhysicalBoundaryPoint`, `KinematicLimit`, `BasePoint`, or `PathEndpoint` by role. |

`MatrixOfHomogeneousSolutions` is selected for the package-facing name because
it is both explicit and the phrase used in amplitude papers.  For a complete,
square, nonsingular matrix, the standard ODE synonym is “fundamental solution
matrix”; documentation should state that fact, but the identifier need not use
the less transparent word `Fundamental`.  A candidate not yet verified is a
`CandidateMatrixOfHomogeneousSolutions` and cannot certify a zero transformed
connection.

## 4. Boundary constants, modes, relations, and genuine periods

The live schema must not replace every `PeriodID` by one other umbrella.  Its
present uses must be split:

| Actual object | Final proposed name |
|---|---|
| independent coefficient after all relevant differential variables have been solved | `BoundaryConstantID` |
| undetermined function of tangential variables on a positive-dimensional boundary stratum | `BoundaryFunctionID` |
| local Frobenius/residue mode realizing that coefficient | `FrobeniusModeID` |
| explicit integral used to determine a constant or boundary function | `BoundaryIntegralID` |
| relation among boundary constants/functions | `BoundaryRelation` (and a typed `BoundaryConstantRelationID` or `BoundaryFunctionRelationID` only if an identifier is required) |
| coefficient of epsilon to power `n` in a boundary constant | `BoundaryConstantEpsilonCoefficient[BoundaryConstantID,n]` |
| coefficient of epsilon to power `n` in a boundary function | `BoundaryFunctionEpsilonCoefficient[BoundaryFunctionID,n]` |

No generic `PeriodID`, `BoundaryDatumID`, or `BoundaryConditionID` is needed in
the live schema.  `BoundaryData` may be used as the standard collective noun
for constants and functions required to specify a solution, but not as an
untyped identifier.  If an old global identifier currently spans several of
the rows above, the record must acquire separate typed fields; a one-for-one
rename would preserve the ambiguity.

| Candidate/current wording | Final proposed wording | Reason |
|---|---|---|
| `PeriodBasis` | `BoundaryConstantTable` or `BoundaryFunctionTable`, according to the entries | The current object includes known, transferred, undetermined, and related entries; it is not an independent basis. |
| a future relation-reduced independent set | `IndependentBoundaryConstantBasis` or `IndependentBoundaryFunctionBasis` | `Basis` becomes valid only after executable relation reduction. |
| `PeriodCoordinates` | `BoundaryConstantEpsilonCoefficientLabels` or `BoundaryFunctionEpsilonCoefficientLabels` | Entries are labels `{typed ID, epsilon order}`, not kinematic coordinates. |
| `PeriodCoordinatesByBinding` | remove from the public schema; if retained privately, `BoundaryEpsilonCoefficientLabelsByRepresentation` | “Binding” is software jargon, and the current keys distinguish physical- and canonical-basis representations. |
| `PeriodClass` with hard-coded GPL/Elliptic input | `DeclaredBoundaryConstantAnalyticClass` or `DeclaredBoundaryFunctionClass` | It is a supplied classification, not a proved representability theorem; constants and tangential functions are distinct. |
| `KnownZeroBoundaryModeIDs` | `BoundaryConstantIDsKnownToVanish`, or `FrobeniusModeIDsWithZeroPhysicalCoefficient` if modes are genuinely the keys | The mode is not zero; its coefficient is. |
| `UndeterminedStructuralBoundaryModeIDs` | `RequiredBoundaryConstantIDsNotYetDetermined` or `RequiredBoundaryFunctionIDsNotYetDetermined` | The local modes are known; their coefficients remain unknown. |
| generic `BoundaryConstantRequirements` | `BoundaryDataRequirements`, containing typed constant/function requirements | `Boundary data` is standard collective differential-equation terminology; it need not create a generic ID. |

`Period`, `PeriodMatrix`, and `EllipticPeriod` remain valid only for an object
defined by an actual integration domain or cycle.  Consequently, generic
boundary-mode/constant/function records lose `Period*`, while a catalog entry that
really stores a density and integration domain may be called a
`BoundaryPeriodIntegral`.  This follows the standard mathematical distinction
rather than a repository-wide string purge.

## 5. Iterated integrals and path composition

The user's decision to avoid bare `Word` in public records is retained even
though “word in an alphabet” is standard shuffle-algebra terminology.

| Candidate/current wording | Final proposed wording | Ruling and mathematical reason |
|---|---|---|
| inert `TransportIteratedIntegral` | `FormalChenIteratedIntegral` after its argument schema is normalized | The current head is symbolic syntax and has no integral evaluator; unqualified `ChenIteratedIntegral` would imply a fully defined mathematical object. |
| a sequence of actual kernels/letters | `IteratedIntegralLetterSequence` | Explicit mathematical content. |
| a sequence of integer alphabet labels | `IteratedIntegralIndexSequence` or field `LetterIndices` | Explicit storage representation. |
| identifier of an interned index sequence | `IteratedIntegralIndexSequenceID` | Distinguishes the sequence from its identifier. |
| coefficient multiplying one formal integral | `IteratedIntegralCoefficientMatrix` | Exact object. |
| sequence-to-coefficient association | `IteratedIntegralCoefficientMap` | Exact domain and value. |
| `IteratedIntegralRepresentation` | `IteratedIntegralCoefficientRepresentation` | The choice is between an explicit coefficient table and a lazy coefficient operator, not between different definitions of the integral. |
| `TransportAlgebraicRoot` | `AlgebraicMarkedPoint` | The indexed polynomial root is used as a marked point/pole of an integration kernel. |
| `TransportLetterKernel` | `IteratedIntegralKernel` | Standard mathematical noun without the redundant “letter kernel.” |
| `DemandRestrictedIteratedIntegralCoefficientOperator` | private `IteratedIntegralCoefficientOperatorForRequestedOutputs` | “Requested outputs” says why and how it is restricted; this remains an implementation representation, not a mathematical stage. |
| `...ByIteratedIntegralWeight` as a separate public object | public `BoundaryConstantToMasterIntegralSolutionMap` (or the boundary-function variant); private field `CoefficientMatricesByIteratedIntegralWeight` | Weight grading is a representation of the same map, not a new physical object. |
| `BoundaryModeToBasePointCoefficientMap` | `BoundaryModeToBasePointSolutionCoordinateMap`, only for a genuine mode-coordinate map | “Coefficient” leaves the codomain unspecified. The current implementation normally already uses boundary constant/function columns and therefore needs the next name instead. |
| `BoundaryConstantToMasterIntegralCoefficientMap` | `BoundaryConstantToMasterIntegralSolutionMap`; on a stratum, `BoundaryFunctionToMasterIntegralSolutionMap` | “Master-integral coefficients” normally means the coefficients multiplying masters in an IBP or amplitude reduction, not the solution of the masters themselves. |
| epsilon- or weight-indexed variants of that map | `...SolutionMapByEpsilonOrder`; private field `SolutionMapCoefficientMatricesByIteratedIntegralWeight` | Name epsilon order when it is part of the mathematical expansion; keep the weight decomposition as representation metadata. |
| full square, evaluated path propagator, if one is constructed | `RegularizedBoundaryToBasePointEvolutionOperator` or `RegularizedBoundaryToBasePointTransportMatrix` | Genuine transport from a singular boundary requires the regularization prescription. |
| current truncated rectangular boundary object | `BoundaryDataToBasePointSolutionMapForRequestedOutputs` with typed constant/function columns | It is not the full transport matrix or evolution operator. |
| unused `EndpointConnectionWord` head | remove | It has a usage message but no emitted mathematical object. Do not rename ghost syntax. |
| keys such as `CurrentFirstWord`, `EndpointSecondWord` | explicit path-segment fields such as `CurrentPathFirstSegmentLetterIndices` and `BoundaryPathSecondSegmentLetterIndices` | They store index sequences on distinct path segments. |

The current prose saying that a product of four path-leg integrals “is one
word along the concatenated path” is mathematically false.  Chen's path
composition formula expresses an integral on a concatenated path as a **sum
over deconcatenations**.  The present product representation may be retained,
but it must be described as a product/tuple of path-segment iterated integrals
until that sum is explicitly performed.

Use `MultiplePolylogarithmFunctionClass` (or the value
`"MultiplePolylogarithms"`) only after representability has been established;
a supplied GPL/Elliptic tag is a `DeclaredBoundaryConstantAnalyticClass` or
`DeclaredBoundaryFunctionClass`.  Use `GoncharovPolylogarithm` for a specific
`G(a_1,...,a_n;z)`, and `ChenIteratedIntegral` for an actual path integral.

## 6. Coding-only vocabulary

`Materialize` may remain only in a private lazy-representation helper.  It is
not a physics or mathematics stage.  Public functions must state the actual
operation: `ConstructExplicit...`, `Expand...`, `Evaluate...`, or
`Reconstruct...`.

`Manifest` is not the correct name for the current discovery routine.  The
routine finds, classifies, selects, and optionally writes information about
available files.  Prefer a semantic split:

- `FindMasterIntegralSolutionInputFiles`;
- `ClassifyMasterIntegralSolutionInputs`;
- `SelectVerifiedFamilyDifferentialSystemInputs`;
- `WriteMasterIntegralSolutionInputSummary`.

If the operations remain combined in one private helper, use the explicit
`FindAndClassifyMasterIntegralSolutionInputs`, not a public mathematical noun.

The public `RationalInEpsilonLayer*` family also contains house terminology.
Where `Layer` means the non-epsilon-form block/subsystem, use
`RationalEpsilonDependentBlock*` and name the precise operation, for example
`ComputeRationalEpsilonDependentBlockResidueAtLocalExpansionPoint`.

## 7. Approved end-state terms

- `MasterIntegralSolutionInTermsOfBoundaryConstants` at a fixed boundary
  point, `MasterIntegralSolutionInTermsOfBoundaryFunctions` on a boundary
  stratum, or `MasterIntegralSolutionInTermsOfBoundaryData` for a genuinely
  mixed record; here “boundary data” is the standard collective DE term;
- `PhysicalRegionMasterIntegralSolution`, only after the region, analytic
  branch prescription, and every required boundary constant/function are fixed;
- `ReadyToDetermineBoundaryConstantsQ`, `ReadyToDetermineBoundaryFunctionsQ`,
  or the genuinely mixed `ReadyToDetermineBoundaryDataQ`, replacing the
  unnatural `ReadyForBoundaryDeterminationQ`;
- `EpsilonFactorizedSystem`, `DLogEpsilonForm`, `FrobeniusExpansion`,
  `VariationOfConstants`;
- `RationalizingParametrization`, `RootSignChoice`, `KinematicLimit`,
  `BasePoint`, `TangentialBasePoint`, and `PathEndpoint` in their restricted
  meanings;
- `MultiplePolylogarithmFunctionClass` for a proved function class and
  `GoncharovPolylogarithm` for the explicit function.

## 8. Literature anchors

- Henn, *Lectures on differential equations for Feynman integrals*:
  https://arxiv.org/abs/1412.2296
- Meyer, *Transforming differential equations of multi-loop Feynman
  integrals into canonical form*: https://arxiv.org/abs/1611.01087
- Gituliar and Magerya, *Fuchsia: a tool for reducing differential equations
  for Feynman master integrals to epsilon form*:
  https://arxiv.org/abs/1701.04269
- Lee, *Libra*: https://arxiv.org/abs/2012.00279
- Hidding, *DiffExp*: https://arxiv.org/abs/2006.05510
- Primo and Tancredi, *Maximal cuts and differential equations for Feynman
  integrals*: https://arxiv.org/abs/1704.05465
- Adams and Weinzierl, *The epsilon-form ... in the elliptic case*:
  https://arxiv.org/abs/1802.05020
- Besier, Wasser and Weinzierl, *RationalizeRoots*:
  https://arxiv.org/abs/1910.13251
- Besier, van Straten and Weinzierl, *Rationalizing roots*:
  https://arxiv.org/abs/1809.10983
- Henn, Smirnov and Smirnov, *Evaluating single-scale and/or non-planar
  diagrams by differential equations*:
  https://arxiv.org/abs/1312.2588
- Frellesvig, *On Epsilon Factorized Differential Equations for Elliptic
  Feynman Integrals*:
  https://arxiv.org/abs/2110.07968
- Milne, *Fields and Galois Theory*:
  https://www.jmilne.org/math/Books/FT0.pdf
- The Stacks Project, birational morphisms and rational maps:
  https://stacks.math.columbia.edu/tag/01RR

## 9. Conditions before implementation

No rename should be implemented until the user approves this revised list.
The eventual migration is not pure lexical replacement: the square-root,
boundary-mode, boundary-constant, and requested-output coefficient records
require semantic splits first.  Historical exchange and evidence files remain
unchanged.

Three findings are correctness issues exposed by the terminology audit rather
than mere naming choices:

1. an `AnalyticCandidate` matrix must not be consumed as if it exactly
   trivialized a diagonal connection block; it remains a candidate until its
   differential identity is established by the package's accepted validation
   standard;
2. independent square-root sign changes and completeness statements require
   independence modulo square classes over the declared constant field;
3. the final path representation must either remain an explicit product of
   segment iterated integrals or implement Chen's concatenation formula—it
   must not assert their equality without that mathematical step.
