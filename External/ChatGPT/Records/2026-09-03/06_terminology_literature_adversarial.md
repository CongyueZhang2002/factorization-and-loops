# Terminology Literature Adversarial

## Question

# Adversarial literature audit of the revised FeynFacet vocabulary

Continue the existing **Assess Multiquadratic Pipeline** conversation and use
the FeynFacet mathematical context already established there.  The attached
file is the revised terminology proposal after the user's objections and
Fable's review.  This is a terminology audit only; do not propose an
implementation or migration procedure.

Act as an independent expert in multiloop-amplitude differential equations,
regular-singular linear systems, iterated integrals, elliptic Feynman
integrals, and the algebraic geometry of rationalizing square roots.  Review
the *actual mathematical content* rather than API aesthetics.

For every proposed public scientific term, classify it as one of:

1. **established**: an attested term used for this object in primary amplitude
   papers or a standard mathematics reference;
2. **transparent package compound**: not a stock phrase, but an explicit and
   mathematically unambiguous combination of established nouns;
3. **reject**: vague, invented-sounding, misleading, or stronger than what the
   implementation establishes.

When uncertain, check actual papers or textbooks.  Cite the primary source or
standard reference supporting every disputed ruling.  Do not accept a phrase
merely because it sounds plausible.

Adversarially scrutinize in particular:

- the narrow legitimate use of `Gauge` versus `BasisTransformation`;
- complete removal of generic `Period` from boundary records, and whether
  anything called a boundary constant is actually a function on a boundary
  stratum;
- the split between boundary modes, independent constants, and integrals used
  to determine them;
- removal of bare `Word` and the distinction between letter sequences, index
  sequences, Chen integrals, coefficient matrices, and coefficient maps;
- `HomogeneousSolutionMatrix`;
- rationalizing parametrization versus generically birational change of
  variables, and whether `Chart` is justified anywhere;
- `MultiquadraticFunctionFieldPresentation` and the separate Jacobian/branch
  objects;
- regular singular point, boundary point, kinematic limit, base point, and
  path endpoint;
- matching matrix, path evolution/parallel transport, connection matrix, and
  the proposed maps between boundary data and master-integral coefficients;
- `FrobeniusExpansion` versus the unsupported full `LeveltBasis` claim;
- epsilon-factorized system versus dlog epsilon form;
- multiple-polylogarithmic function-class terminology versus an explicit
  Goncharov polylogarithm;
- whether any long proposed compound remains an AI-invented umbrella rather
  than a precise description.

Return:

1. a concise table of every proposed term that should still change, with its
   exact replacement and mathematical reason;
2. a short list of important terms that survive unchanged;
3. any place where the code's objects must be semantically split before they
   can receive honest names.

Do not discuss hashes, defensive checks, source migration, or coding style.

## Pro response

Verdict

Revise once more before approval. The revised proposal is substantially sound: it correctly separates mathematical objects from software records, recognizes that the current root map is only a rationalizing parametrization, reserves LeveltBasis until Jordan/logarithmic structure exists, and removes generic Period, Word, Frame, and Gauge vocabulary from places where those nouns misstate the object. 

02_community_vocabulary_revisio…

The largest remaining defect is the assumption that all unresolved boundary coefficients are constants. In a multivariate system, integrating in one variable leaves an undetermined function of the remaining variables; it becomes a constant vector only after the remaining differential equations have also been solved. This is exactly the CF303 soft-stratum situation, where normal boundary coefficients can remain functions of p. 
arXiv

Accordingly:

retain BoundaryConstantID;

add BoundaryFunctionID;

retain BoundaryModeID and optional BoundaryIntegralID;

do not introduce a generic BoundaryDatumID;

use boundary data only as a collective noun for heterogeneous records.

1. Terms that should still change
A. Epsilon-form construction and basis transformations

Amplitude papers and reduction software normally speak of a basis transformation or transformation matrix. Fuchsia explicitly describes transformations of off-diagonal blocks and returns a transformation matrix T; recent amplitude papers use the same terminology. GaugeTransformation remains standard mathematics for the induced action on a connection, but it should not be the public name of the master-integral matrix T. 
arXiv
+2
arXiv
+2

Proposed term	Classification	Exact ruling
OffDiagonalBlockEpsilonFormObstruction	reject	Split into OffDiagonalBlockAnsatzInconsistency for failure of a finite denominator/support/alphabet ansatz, and OffDiagonalBlockDLogEpsilonFormObstruction only for an ansatz-independent no-go such as the gauge-eliminated CF303 obstruction. A modular rank defect in a chosen finite space is not, by itself, an obstruction to all transformations.
InhomogeneityDegreeAtInfinity	reject	Split into InhomogeneityPoleOrderAtInfinity or InhomogeneityValuationAtInfinity when it is a local/projective valuation, and InhomogeneityNumeratorDegreeBoundAtInfinity when it is a polynomial-support bound. Degree and pole order are not interchangeable.
BasisTransformationRoundTrip	reject	Split into RationalizationMapCompositionIdentity for forward/inverse coordinate maps and BasisTransformationPullbackIdentity for agreement after changing variables and returning to the source field. “Round trip” is software vocabulary and hides which identity was proved.
PhysicalBasisTransformationCoefficientsByEpsilonOrder	reject as generic	Use an explicit domain and codomain, normally CanonicalToSourceBasisTransformationCoefficientsByEpsilonOrder or CanonicalToPhysicalBasisTransformationCoefficientsByEpsilonOrder. “Physical” is justified only after the physical basis and branch convention have actually been imposed.
TransformFamilyToEpsilonForm	split	Use TransformFamilyToEpsilonFactorizedSystem for the general polylogarithmic/elliptic operation. Reserve TransformFamilyToDLogEpsilonForm for the stronger dlog result.
AssembleFamilyEpsilonForm	split	Use AssembleFamilyEpsilonFactorizedSystem generically and AssembleFamilyDLogEpsilonForm only when every retained kernel is dlog.

The last split matters. Rational canonical-form literature often uses “epsilon form” together with a dlog system, while elliptic and Calabi–Yau literature deliberately speaks of epsilon-factorized differential equations even when the kernels are not dlogs. Von Manteuffel and Tancredi explicitly note that the canonical basis in the Henn sense requires both epsilon factorization and dlog form. 
ar5iv
+3
arXiv
+3
arXiv
+3

The proposal’s more specific terms—

OffDiagonalBlockTransformationProblem;

OffDiagonalBlockEquation;

OffDiagonalBlockLinearOperator;

SolveOffDiagonalBlockBasisTransformation;

OffDiagonalBasisTransformationBlock;

TransformedOffDiagonalBlock;

—are transparent package compounds and accurately distinguish the problem, equation, operator, solver, transformation block, and transformed connection. The underlying terms “off-diagonal block” and “transformation matrix” are established in the amplitude literature. 

02_community_vocabulary_revisio…

 
arXiv
+1

B. Rationalization maps and coefficient fields

The root-rationalization literature speaks of a suitable variable change or rational parametrization. In algebraic geometry, birationality requires inverse rational maps, equivalently isomorphic nonempty open subsets. A nonzero Jacobian and verified root identities do not alone establish birationality. 
arXiv
+1

Proposed term	Classification	Exact ruling
ChangeOfVariablesVerification for the current verifier	reject	Replace by RationalizingParametrizationVerification. Reserve RationalizingChangeOfVariablesVerification for an object that also establishes a rational inverse on a dense open set.
NewVariables	reject	Use ParametrizationVariables for the current one-way map; use TransformedVariables only for a certified change of variables.
NoRationalizingParametrization	reject	Replace by RationalizingParametrizationNotFound, or more explicitly NoCataloguedRationalizingParametrization. The package has not proved geometric nonexistence.
MultiquadraticFunctionFieldPresentation	transparent package compound, conditionally	Retain only for the generic characteristic-zero object after square-class independence establishes that the quotient is a field. Use MultiquadraticExtensionAlgebraPresentation for a dependent-generator quotient or a specialized split finite-field algebra.
generic public Chart	reject for current records	Retain Chart only for an actual coordinate chart with a declared open domain. BirationalChart or RationalChart is legitimate only when the map identifies specified nonempty open subsets.

“Presentation” is the correct mathematical noun for generators and relations of a quotient algebra. Whether that presented algebra is a field is an additional property, not part of the word “presentation.” 
The Stacks Project

These proposal terms survive as transparent package compounds:

RationalizationMapCatalog;

RationalizingParametrization;

RationalizingChangeOfVariables, once a rational inverse is established;

VerifyRationalizingParametrization;

FindRationalizingParametrizationForRoots;

ComposeRationalizingParametrizations;

ExtendRationalizingParametrization;

DifferentialPullbackMap;

RootBranchConvention;

RootSignChoice and RootSignChoices;

PhysicalBranchChoice;

AnalyticBranchConvention.

GaloisAction, GaloisConjugate, and RiemannSheet are established, but they must retain their restricted meanings. A modular sign tuple is not automatically a physical sheet, and a physical analytic sheet contains continuation data beyond a sign assignment. 

02_community_vocabulary_revisio…

C. Regular singular points and boundary data

The revised proposal correctly distinguishes regular singular points, kinematic limits, base points, and path endpoints. It still applies several boundary-constant names to objects that can live on a positive-dimensional boundary stratum. 

02_community_vocabulary_revisio…

Proposed term	Classification	Exact ruling
ConstructBoundaryModeMatchingMatrix for the current record	reject	Use ConstructPhysicalBoundaryModeMap. Reserve ConstructBoundaryModeToFrobeniusCoordinateMatrix for the stage at which a single literal matrix between two declared coordinate bases has been assembled.
BoundaryModeMatchingMatrix	transparent package compound, conditionally	Valid only for an actual matrix. “Matching matrix” is established for a constant matrix relating local homogeneous-solution bases across regions; it should not name a collection of mode realizations, normalization records, and relations. 
arXiv
+2
arXiv
+2

DegeneratePhysicalBoundaryModeData	reject	Split into DegenerateResidueEigenspaceData for spectral degeneracy and BoundaryModeRelationMatrix for physical relations among mode coefficients.
ConstructResidueAtRegularSingularPoint	replace	ConstructResidueMatrixAtRegularSingularPoint. The stored object is a matrix residue, not a scalar residue or residue operation.
ConstructRationalInEpsilonLayerResidueAtRegularSingularPoint	replace	ConstructRationalInEpsilonLayerResidueMatrixAtRegularSingularPoint.
BoundaryLimitCoordinateRelation	replace	KinematicLimitCoordinateRelation. This is a relation between a physical scaling variable and a local coordinate, not between abstract boundary data.
PhysicalBoundaryPoint used for all limiting loci	split	Retain for a zero-dimensional point. Use PhysicalBoundaryStratum for a positive-dimensional locus, and KinematicLimit for the specified approach to that locus.
ConstructBoundaryVectorFromConstants	split	ConstructBoundaryValueVectorFromConstants at a fixed point; ConstructBoundaryValueVectorFromFunctions on a boundary stratum. A neutral constructor may be ConstructBoundaryValueVector.
BoundaryConstantCoefficient	replace	BoundaryConstantEpsilonCoefficient. On a stratum use BoundaryFunctionEpsilonCoefficient. The original name can be mistaken for the coefficient multiplying a boundary constant in the transported solution.
universal use of BoundaryConstantID	split	Retain BoundaryConstantID; add BoundaryFunctionID. Do not replace either by BoundaryDatumID.
BoundaryConstantBasis	conditional	Retain only after independence is established. Before relation reduction use BoundaryConstantGenerators. On a stratum use the corresponding BoundaryFunctionGenerators or IndependentBoundaryFunctionBasis.
BoundaryConstantCoordinatesByMap	reject	Name the actual map. If one generic grouping key is unavoidable, use BoundaryConstantCoordinatesBySolutionMapID; do not leave “map” untyped.
BoundaryConstantFunctionClass	reject	Split into BoundaryConstantAnalyticClass for fixed values and BoundaryFunctionClass for functions on a stratum.
StructuralBoundaryModeIDs	reject	Replace by RequiredFrobeniusModeIDs if these are modes required by local analysis. “Structural” states no mathematical property.
KnownZeroBoundaryModeIDs	reject	Replace by BoundaryModeIDsWithZeroPhysicalCoefficient, or use KnownZeroBoundaryConstantIDs once independent constants have been chosen. A mode is not itself zero merely because its physical coefficient vanishes.
UndeterminedStructuralBoundaryModeIDs	reject	Use BoundaryModeIDsWithUndeterminedCoefficients; preferably record the actual UndeterminedBoundaryConstantIDs or UndeterminedBoundaryFunctionIDs. The mode is already known.
UndeterminedEllipticBoundaryConstants	split	Use this only for fixed-point constants in an elliptic analytic class. Use UndeterminedEllipticBoundaryFunctions on a stratum. Retain UndeterminedEllipticPeriods only when explicit cycle integrals have been defined.
BoundaryConstantRequirements	replace for the general workflow	BoundaryDataRequirements. “Boundary data” is an established collective phrase and does not require a generic BoundaryDatumID.
ConstructMasterIntegralSolution before Stage 3	reject as underspecified	ConstructMasterIntegralSolutionInTermsOfBoundaryData; specialize to ...BoundaryConstants or ...BoundaryFunctions when the input type is uniform.

The constant/function split is not optional. A multivariate master-integral calculation integrated first in x
1
	​

 is fixed only up to an undetermined function of the remaining x
i
	​

; after the remaining equations are solved, one obtains an unknown constant vector. 
arXiv
 At a fixed kinematic point, “boundary constant” is standard amplitude terminology. 
arXiv
+1

BoundaryModeID, BoundaryConstantID, BoundaryFunctionID, and BoundaryIntegralID are all transparent package compounds. They name distinct entities and need not be one-to-one:

local mode

=independent coefficient

=function on a stratum

=integral used to determine it.

No generic ID is needed. A heterogeneous record can carry typed references to whichever of these objects apply.

D. Period

The removal of generic Period* from live boundary records is correct. The mathematical justification should be stated more carefully:

a general mathematical period need not literally be a cycle integral;

an elliptic period matrix is specifically obtained by integrating a basis over a complete set of cycles;

a boundary constant that might later evaluate to such a period is not thereby a period object.

Frellesvig uses “period matrix” exactly for integrals of a basis over a complete set of integration cycles. 
arXiv

Therefore:

EllipticPeriod, PeriodID, and PeriodMatrix survive only where an explicit period integral and its cycle/domain are part of the record;

BoundaryIntegralID survives only where an actual endpoint/region integral is defined;

a formal unresolved coefficient remains a BoundaryConstantID or BoundaryFunctionID.

The proposal’s three-way mode/constant/integral split is correct in substance, but it needs the fourth BoundaryFunctionID for positive-dimensional strata. 

02_community_vocabulary_revisio…

E. Frobenius versus Levelt
Proposed term	Classification	Ruling
FrobeniusExpansion	established	Retain.
ConstructFrobeniusExpansionAtRegularSingularPoint	transparent package compound	Retain.
TransformTangentialConnectionToResidueEigenbasis	transparent package compound	Retain only when a complete diagonalizable residue eigenbasis actually exists.
LeveltBasis for the current implementation	reject	Continue reserving it.

A Levelt fundamental matrix has the structured form

Ψ(z)z
Λ
z
R
,

where the nilpotent part produces logarithmic terms; its columns constitute a Levelt basis. Merely diagonalizing a residue or storing its eigenvectors does not establish a Levelt basis in resonant/Jordan cases. 
arXiv

F. Iterated-integral objects

Henn distinguishes the ordered differential forms in a Chen integral from the integral value itself, and defines Goncharov polylogarithms by an ordered list of indices. GPLs are a special class of Chen iterated integrals once the kernels have the appropriate rational form. 
arXiv
+1

Proposed term	Classification	Exact ruling
AlgebraicLetterRoot	reject	Split into AlgebraicMarkedPoint when the object is a GPL/eMPL pole or point on a curve, and AlgebraicRootGenerator when it is a generator of the coefficient field. Elliptic polylogarithms are naturally associated with elliptic curves carrying marked points. 
arXiv
+1

IteratedIntegralRepresentation	reject	Replace by IteratedIntegralCoefficientRepresentation; the record chooses between an explicit coefficient table and a lazy coefficient operator, not between representations of the integral itself.
MultiplePolylogarithmic as a standalone stored class	reject	Use MultiplePolylogarithmFunctionClass, or the enumeration value "MultiplePolylogarithms". The adjective is normal prose but not a self-contained mathematical object name.
BoundaryToBasePointChenIteratedIntegral	transparent package compound	Accept, although ChenIteratedIntegralAlongBoundaryToBasePointPath is grammatically clearer. Use TangentialBasePoint explicitly when the lower limit is singular.

These terms survive as transparent package compounds:

IteratedIntegralLetterSequence;

IteratedIntegralIndexSequence;

IteratedIntegralIndexSequenceID;

IteratedIntegralLetterKernel;

IteratedIntegralCoefficientMatrix;

IteratedIntegralCoefficientMap;

DemandRestrictedIteratedIntegralCoefficientOperator;

DemandRestrictedIteratedIntegralCoefficientMap;

ExplicitIteratedIntegralCoefficients;

IteratedIntegralTermCountUpperBound.

ChenIteratedIntegral and GoncharovPolylogarithm are established. An explicit G(a
1
	​

,…,a
n
	​

;z) is a Goncharov polylogarithm; “multiple polylogarithms” names the function class. 

02_community_vocabulary_revisio…

 
arXiv

G. Matching, evolution, and solution maps

MatchingMatrix is established amplitude terminology for the constant matrix relating local matrices of homogeneous solutions in neighboring regions. EvolutionOperator or path-ordered exponential names propagation along a path. Those should not be collapsed into one object. 
arXiv
+2
arXiv
+2

Proposed term	Classification	Exact ruling
BoundaryToBasePointEvolutionOperator	transparent package compound	Retain. It names genuine path evolution rather than a map between points.
BoundaryModeToBasePointCoefficientMap	reject	Replace by BoundaryModeToBasePointSolutionCoordinateMap. “Coefficient” does not identify the codomain.
BoundaryConstantToMasterIntegralCoefficientMap	reject	Replace by BoundaryConstantToMasterIntegralSolutionMap. On a stratum use BoundaryFunctionToMasterIntegralSolutionMap.
BoundaryConstantToMasterIntegralCoefficientMapByEpsilonOrder	reject	BoundaryConstantToMasterIntegralSolutionMapByEpsilonOrder.
BoundaryConstantToMasterIntegralCoefficientMapByIteratedIntegralWeight	reject	BoundaryConstantToMasterIntegralSolutionMapByIteratedIntegralWeight.

The phrase master-integral coefficients is already standard for the coefficients multiplying master integrals in IBP or amplitude reductions. Kira explicitly reconstructs “master integral coefficients” in that sense, and amplitude papers use the same phrase. Reusing it for coefficients of the master-integral solution would be predictably confusing. 
arXiv
+2
arXiv
+2

ConnectionMatrix is also an established ODE term, so it is not linguistically false. It should nevertheless remain absent from FeynFacet’s public vocabulary because “connection” already denotes the differential-equation one-form. MatchingMatrix plus EvolutionOperator is the cleaner package split.

2. Important terms that survive unchanged
Established terminology
Term	Scope
OffDiagonalBlock	Block-triangular differential equation
Inhomogeneity / InhomogeneousTerm	Source term of the off-diagonal equation
BasisTransformation	Change of master-integral basis
GaugeTransformation	Only the literal action on a connection
RegularSingularPoint	Local Fuchsian analysis
FrobeniusExpansion	Local regular-singular expansion
BoundaryPoint	A specific point at which boundary values are supplied
BoundaryStratum	Positive-dimensional boundary locus
KinematicLimit	Specified soft, collinear, threshold, or other limiting process
BasePoint, TangentialBasePoint	Lower point of an iterated integral
PathEndpoint	Actual end of an oriented path
MatchingMatrix	Constant matrix relating declared local solution bases
EvolutionOperator, ParallelTransport	Propagation along a path
GaloisAction, GaloisConjugate	Algebraic extension automorphisms and their images
RiemannSheet	Genuine analytic sheet
ChenIteratedIntegral	Ordered path integral
GoncharovPolylogarithm	Explicit G-function
VariationOfConstants	Inhomogeneous solution method
EllipticPeriod, PeriodMatrix	Only explicitly defined period integrals

The amplitude phrase matrix of homogeneous solutions is directly attested for elliptic master-integral systems. 
arXiv
+1

Transparent package compounds

The following are not stock phrases, but they are mathematically literal and acceptable:

OffDiagonalBlockTransformationProblem;

OffDiagonalBlockEquation;

OffDiagonalBlockLinearOperator;

SolveOffDiagonalBlockBasisTransformation;

OffDiagonalBasisTransformationBlock;

TransformedOffDiagonalBlock;

BasisTransformationMatrix;

OffDiagonalBasisTransformationDenominator;

OffDiagonalBasisTransformationNumeratorSupport;

BasisTransformationNormalizationRules;

PullBackBasisTransformation;

PulledBackBasisTransformation;

RationalizationMapCatalog;

RationalizingParametrization;

RationalizingChangeOfVariables, after a rational inverse is proved;

DifferentialPullbackMap;

RootBranchConvention;

RootSignChoice;

PhysicalBranchChoice;

AnalyticBranchConvention;

ConstructFrobeniusExpansionAtRegularSingularPoint;

BoundaryModeID;

BoundaryConstantID;

BoundaryFunctionID;

BoundaryIntegralID;

IteratedIntegralLetterSequence;

IteratedIntegralIndexSequence;

IteratedIntegralCoefficientMatrix;

DemandRestrictedIteratedIntegralCoefficientOperator;

BoundaryToBasePointEvolutionOperator;

HomogeneousSolutionMatrix;

EpsilonFactorizedSystem;

DLogEpsilonForm.

HomogeneousSolutionMatrix is therefore acceptable as a transparent package compound, not as the exact standard phrase. The exact literature phrase is “matrix of homogeneous solutions.” DLogEpsilonForm is likewise a transparent combination of the established terms “dlog form” and “epsilon form.”

3. Semantic splits required before honest naming

Transformation versus gauge action

Tbasis-transformation matrix,Goff-diagonal basis-transformation block,

versus

A↦T
−1
AT−T
−1
dTconnection gauge transformation.

These must not share one generic Gauge family.

Rationalization geometry

Separate:

rationalizing parametrization;

generically birational change of variables;

actual chart on specified open subsets;

multiquadratic extension presentation;

differential pullback;

analytic branch convention.

A verified Jacobian does not promote a parametrization to a birational chart. 
The Stacks Project

Generic field versus specialized algebra

Separate the generic multiquadratic function field from:

lower-rank square-class quotients;

split finite-field algebras;

branch evaluations at points.

Only the generic field object should receive FunctionField in its type name.

Boundary geometry

Separate:

RegularSingularPoint;

KinematicLimit;

PhysicalBoundaryPoint;

PhysicalBoundaryStratum;

BasePoint or TangentialBasePoint;

PathEndpoint.

Boundary information

Separate:

local Frobenius mode;

independent boundary constant;

boundary function on a stratum;

integral used to determine one of those;

genuine period integral.

No generic BoundaryDatumID is needed, but a collective BoundaryDataRequirements record is appropriate.

Frobenius versus Levelt

FrobeniusExpansion is honest for the current implementation. LeveltBasis requires the resonant/Jordan/logarithmic structure represented by z
Λ
z
R
; it must remain reserved. 
arXiv

Matching versus evolution

Separate:

local basis matching matrix;

regularized boundary-to-base-point evolution operator;

their composed solution-coordinate map.

Iterated-integral representation

Separate:

letter or kernel;

ordered letter sequence;

integer index sequence;

iterated-integral value;

coefficient matrix;

sequence-to-coefficient map;

lazy coefficient operator.

Failure versus obstruction

Separate a failed finite ansatz from an ansatz-independent mathematical obstruction. This distinction is essential in the CF259/CF300/CF303 campaign, where many modular inconsistency screens were later resolved by a different support or rationalizing parametrization, whereas the CF303 gauge-eliminated compatibility defect had genuinely broader scope.

Epsilon factorization versus dlog form

Use:

dF=ϵΩF⇒EpsilonFactorizedSystem,

and only when

Ω=
i
∑
	​

R
i
	​

dlogL
i
	​

,R
i
	​

 kinematics-independent,

use DLogEpsilonForm. Elliptic and Calabi–Yau systems provide established examples of epsilon-factorized systems beyond ordinary dlog/MPL form. 
arXiv
+2
arXiv
+2

Pre-Stage-3 versus physical solution

A solution with unresolved but explicitly named boundary constants or functions is a genuine parameterized solution, but not yet a physical-region solution. The honest general name is:

MasterIntegralSolutionInTermsOfBoundaryData

with narrower constant/function variants where applicable. PhysicalRegionMasterIntegralSolution remains reserved for a specified region and a complete set of determined boundary data.

Final ruling

The revised vocabulary is close, but three changes are non-negotiable:

introduce BoundaryFunctionID and split every universal BoundaryConstant* family by point versus stratum;

reserve MatchingMatrix for a literal matrix between declared local bases;

distinguish finite-ansatz inconsistency, epsilon factorization, and dlog epsilon form explicitly.

After those corrections, the remaining long compounds are mostly legitimate transparent package compounds, not invented scientific methods.

## Sources sent to Pro

- Original source reference: `/home/maxzhang/factorization-and-loops/Exchange/Codex/2026-09-03/02_community_vocabulary_revision_after_fable_review.md` (not archived with this exchange)
