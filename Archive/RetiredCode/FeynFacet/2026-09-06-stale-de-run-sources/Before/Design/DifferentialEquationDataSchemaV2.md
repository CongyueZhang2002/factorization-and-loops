# Differential-equation data schema V2

This is the live schema for upstream differential systems and local boundary data.
Explicit finite solutions use schema version 3, described in section 9.
It is a clean break from the generated V1 artifacts.  V1 data is preserved in
a dated `Stale` directory and is not an interface that new code must support.

The schema uses mathematical roles rather than workflow nicknames.  Each upstream
record begins with

```wl
"DataType" -> "...",
"SchemaVersion" -> 2
```

and its `Status` names the mathematical statement established.  A bare
`"OK"`, a file fingerprint, or a settings fingerprint is not a mathematical
acceptance statement.

References between artifacts are explicit and human-readable:

```wl
<|
  "RelativePath" -> "...",
  "DataType" -> "...",
  "SchemaVersion" -> 2,
  "Family" -> "CF..."
|>
```

A block reference additionally gives its target and source rows when relevant.
The consumer reloads the referenced mathematical inputs and re-evaluates the
defining equation.  V2 records do not contain content hashes, settings hashes,
fingerprints, or hash-based acceptance and resumption gates.

## Conventions

- The independent variables are arbitrary symbols.  The current solver accepts
  two dimensionless kinematic variables, but their names need not be `v,w`.
- `DimensionalRegulator` is the dimensional-regularization variable.
- The basis convention is
  `OriginalMasterIntegrals == BasisTransformationMatrix . TransformedMasterIntegrals`.
  Consequently
  `Atransformed == Inverse[T].Aoriginal.T - Inverse[T].dT`.
- A deterministic symbolic identity and a probabilistic finite-field identity
  test are different validation methods.  A production finite-field result says
  `"Method" -> "ProbabilisticFiniteFieldSampling"`; it is never labelled exact.
- Data needed to reproduce a mathematical result is stored once.  Derived
  matrices may be cached for performance, but the cache is named as such and is
  not a second source of truth.

## 1. Family differential system

```wl
<|
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> "CF...",
  "KinematicVariables" -> {x1, x2},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" -> {...},
  "ConnectionMatrices" -> {A1, A2}
|>
```

`ConnectionMatrices[[i]]` is the coefficient of `d KinematicVariables[[i]]`.
This replaces the name-dependent `Av/Aw` pair without pretending to support an
arbitrary number of variables in the current implementation.

## 2. Coefficient presentations

There is no common `Chart` or `Frame` record.  A discriminated union contains
one of three mathematically different objects.  A containing record stores the
selected object once under `CoefficientPresentation`; its `DataType` selects
the case.  It does not repeat the same object under several case-specific
keys.

When a coefficient presentation is persisted as its own family input, it also
carries `Family` and a human-readable `FamilyDifferentialSystemReference`.
The project configuration must contain an explicit entry for every family;
an absent entry is not interpreted as an unchanged-source-variable case.

### Unchanged source variables

```wl
<|
  "DataType" -> "SourceVariableRepresentation",
  "SchemaVersion" -> 2,
  "SourceVariables" -> {x1, x2},
  "CoefficientVariables" -> {x1, x2},
  "SourceVariableSubstitution" -> {x1 -> x1, x2 -> x2},
  "DifferentialPullbackMatrix" -> IdentityMatrix[2]
|>
```

This is the root-free case.  It is not called an identity rationalizing
parametrization because no rationalization is being performed.

### Rationalizing parametrization

```wl
<|
  "DataType" -> "RationalizingParametrization",
  "SchemaVersion" -> 2,
  "Name" -> "...",
  "SourceVariables" -> {x1, x2},
  "ParametrizingVariables" -> {z1, z2},
  "SourceVariableSubstitution" -> {x1 -> f1, x2 -> f2},
  "RationalizedSquareRoots" -> {
    <|"RationalRoot" -> r, "SourceRadicand" -> q|>, ...
  }
|>
```

The verifier establishes rationality, the displayed square-root identities,
and a nonzero Jacobian.  It does not claim a rational inverse or birationality.

### Square-root generators and quadratic relations

```wl
<|
  "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
  "SchemaVersion" -> 2,
  "SourceVariables" -> {x1, x2},
  "CoefficientVariables" -> {z1, z2},
  "SourceToCoefficientVariableRules" -> {x1 -> z1, x2 -> z2},
  "SquareRootGenerators" -> {
    <|"Generator" -> rho1, "QuadraticRadicand" -> q1z,
      "SourceRadicand" -> q1|>, ...
  },
  "SquareClassIndependenceStatus" -> "NotChecked"
|>
```

The equations `rhoi^2 == qi` are derived from `SquareRootGenerators`; they are
not stored a second time.  This record does not claim a degree-`2^r` field or
Galois group unless square-class independence is separately established.

## 3. Block decomposition

```wl
<|
  "DataType" -> "FamilyDifferentialSystemBlockDecomposition",
  "SchemaVersion" -> 2,
  "FamilyDifferentialSystemReference" -> <|...|>,
  "DiagonalBlocksInCurrentBasis" -> {{...}, ...}
|>
```

The ordered row lists are authoritative. These are strongly connected components
of the dependency graph in the supplied basis. They are indecomposable under
basis permutations; no irreducibility under general basis transformations is
asserted.  A permutation or contiguous block
range may be computed and cached privately, but is not a second source of
truth.  No downstream stage reconstructs block ordering from file names or
association order.

## 4. Diagonal-block dlog epsilon form

```wl
<|
  "DataType" -> "DiagonalBlockDLogEpsilonForm",
  "SchemaVersion" -> 2,
  "BlockRows" -> {...},
  "CoefficientVariables" -> {z1, z2},
  "DimensionalRegulator" -> eps,
  "BasisTransformationMatrix" -> T,
  "Letters" -> {phi1, ...},
  "ConstantResidueMatrices" -> {R1, ...},
  "Status" -> "DLogEpsilonFormValidated",
  "Validation" -> <|"Method" -> ..., "Passed" -> True, ...|>
|>
```

The inverse of `BasisTransformationMatrix` is derived rather than stored.  If
a performance cache is necessary it is named
`CachedInverseBasisTransformationMatrix` and is checked before use.  The
transformed connection is defined by
`eps Sum[Ri D[Log[phii], zj]]`.  Storing another full copy under `EpsForm` is
optional cache data, not a second definition.  `EpsilonFactorizedSystem` is
used when epsilon factorization is known but the constant-residue dlog
representation is not.

## 5. Off-diagonal block transformation

```wl
<|
  "DataType" -> "OffDiagonalBlockBasisTransformation",
  "SchemaVersion" -> 2,
  "TargetBlockRows" -> {...},
  "SourceBlockRows" -> {...},
  "OffDiagonalBasisTransformationBlock" -> H,
  "OffDiagonalDLogCoefficientMatrices" -> {K1, ...},
  "Status" -> "OffDiagonalBasisTransformationBlockValidated",
  "Validation" -> <|"Method" -> ..., "Passed" -> True, ...|>
|>
```

`OffDiagonalBasisTransformationBlock` and the constant dlog coefficient
matrices are authoritative.  A stored transformed connection block is an
optional `CachedTransformedOffDiagonalConnectionBlock`, not a second
definition of the result.

A finite-ansatz failure is `OffDiagonalBlockAnsatzInconsistency`.
The phrase `OffDiagonalBlockDLogEpsilonFormObstructionCertificate` requires
a characteristic-zero proof with explicit scope: coefficient field,
fixed diagonal connections and inhomogeneity, target one-forms, allowed
residue constants and regulator dependence. Eliminating the transformation
from the integrability equation removes its degree/denominator ansatz, but
does not remove the fixed-target or fixed-basis restrictions. A sampled
finite-field rank defect alone is diagnostic evidence. A claim under every
admissible basis additionally requires a basis-invariant obstruction or a
proved completeness argument. See the
[2026-09-06 audit](Stage1CostsAndEpsilonFormCriteria_2026-09-06.md).

## 6. Family assembly

```wl
<|
  "DataType" ->
    "FamilyDifferentialSystemWithEpsilonFormDiagonalBlocks",
  "SchemaVersion" -> 2,
  "Status" ->
    "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks",
  "FamilyDifferentialSystem" -> <|...|>,
  "CoefficientPresentation" -> <|...|>,
  "BasisTransformationMatrix" -> Ttotal,
  "DiagonalBlockDLogEpsilonForms" -> {...}
|>
```

The status deliberately does not say that the whole family is in epsilon
form: lower off-diagonal connection blocks may still be general.

After every required off-diagonal basis-transformation block has been found,
the stronger result is a separate object:

```wl
<|
  "DataType" -> "FamilyDLogEpsilonForm",
  "SchemaVersion" -> 2,
  "Family" -> "CF...",
  "CoefficientPresentation" -> <|...|>,
  "CoefficientVariables" -> {z1, z2},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" -> {...},
  "BlockDecomposition" -> <|...|>,
  "BasisTransformationMatrix" -> Ttotal,
  "Letters" -> {phi1, ...},
  "ConstantResidueMatrices" -> {R1, ...},
  "Status" -> "FamilyDLogEpsilonFormValidated",
  "Validation" -> <|...|>
|>
```

This type is emitted only when the complete transformed connection is
`eps Sum[Ri dlog[phii]]`.  A rational-in-epsilon block that is not reducible to
this form remains a distinct block-triangular differential system and is
solved by variation of constants; it is never relabelled as a family dlog
epsilon form.

## 7. Required epsilon orders

The exact epsilon valuations of the hard-function coefficients are upstream
input, not output of the differential-equation solver:

```wl
<|
  "DataType" -> "HardFunctionMasterCoefficientEpsilonValuations",
  "SchemaVersion" -> 2,
  "Entries" -> {
    <|
      "MasterIntegralIndex" -> i,
      "MasterIntegral" -> <|
        "Family" -> "CF...", "PropagatorPowers" -> {...}|>,
      "HardFunctionCoefficientEpsilonValuation" -> n,
      "DeterminationMethod" -> "..."
    |>, ...
  },
  "Status" -> "HardFunctionMasterCoefficientEpsilonValuationsDetermined"
|>
```

Together with requested hard-function orders they give upper demands. For
finite ranges, supply MasterIntegralLaurentLowerBounds, indexed by global
MasterIntegralIndex, or use the third argument of
DeriveMasterIntegralEpsilonOrderRequirements. Its validation distinguishes
UpperBoundsOnly from FiniteEpsilonOrderRanges:

```wl
<|
  "DataType" -> "MasterIntegralEpsilonOrderRequirements",
  "SchemaVersion" -> 2,
  "RequestedHardFunctionEpsilonOrders" -> {nmin, ..., nmax},
  "Entries" -> {
    <|
      "MasterIntegralIndex" -> i,
      "RequiredMasterIntegralEpsilonOrders" -> {...}
    |>, ...
  },
  "Status" -> "MasterIntegralEpsilonOrderRequirementsDerived"
|>
```

A coefficient valuation is not itself a requested master-integral order.  For
example, a coefficient with valuation `v` can contribute to hard-function
order `n` through all master coefficients from a justified lower bound L
through `n-v`, since higher terms of the hard coefficient multiply lower
terms of the master integral. A known zero has valuation Infinity and requires
no coefficients. Earlier Missing["ZeroColumn"] inputs are normalized to this
mathematical convention.

## 8. Local solutions, boundary data, and evolution

A local differential-equation result is represented by

```wl
<|
  "DataType" -> "TruncatedLocalFrobeniusExpansion",
  "SchemaVersion" -> 2,
  "DifferentialSystemReference" -> <|...|>,
  "LocalExpansionPoint" -> <|...|>,
  "PointType" -> "OrdinaryPoint" | "RegularSingularPoint",
  "LocalVariable" -> rho,
  "EpsilonNormalizedConnectionResidue" -> R,
  "ResidueConvention" -> "R=Res(connection/eps); LocalSolution=H(rho,eps).rho^(eps R).c",
  "TruncatedLocalPrefactor" -> H,
  "RetainedLocalOrders" -> {...},
  "RetainedEpsilonOrders" -> {...},
  "Status" -> "TruncatedLocalFrobeniusExpansionValidated",
  "Validation" -> <|...|>
|>
```

Here R is the residue after dividing the connection by epsilon; the full
connection residue is eps R. The normalized residue and local prefactor are mathematical data.  A choice
of implementation backend is computation metadata and does not belong here.

A boundary domain is explicit:

```wl
"BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint"|>
```

or

```wl
"BoundaryDomain" -> <|
  "Type" -> "PhysicalBoundaryStratum",
  "TangentialVariables" -> {...}
|>
```

Matching physical asymptotics to the local modes produces

```wl
<|
  "DataType" -> "BoundaryAsymptoticModeMatching",
  "SchemaVersion" -> 2,
  "LocalFrobeniusExpansionReference" -> <|...|>,
  "BoundaryDomain" -> <|...|>,
  "FrobeniusModes" -> {
    <|"FrobeniusModeID" -> ..., "LocalExponent" -> ...|>, ...
  },
  "BoundaryConstantTable" -> <|...|>,
  "BoundaryFunctionTable" -> <|...|>,
  "BoundaryRelations" -> {...},
  "Status" -> "BoundaryAsymptoticsMatchedToFrobeniusModes",
  "Validation" -> <|...|>
|>
```

Point data use `BoundaryConstantID` and
`BoundaryConstantEpsilonCoefficient[id,n]`.  Stratum data use
`BoundaryFunctionID` and
`BoundaryFunctionEpsilonCoefficient[id,n][t1,...]`; the tangential
arguments are part of the mathematical object and must not be suppressed.
`FrobeniusModeID`, `BoundaryIntegralID`, and `BoundaryRelation` remain separate
objects.  Degeneracy of a residue eigenspace does not by itself create a
relation among boundary constants or functions.

On a positive-dimensional boundary stratum, the free local-mode coefficients
obey their induced tangential differential system.  If `B` is the matrix of
retained boundary-mode coefficient vectors in a normal-residue basis and
`Gamma_i` is the induced tangential connection, then

```text
B Omega_i = Gamma_i B - partial_i B,
partial_i c = Omega_i c.
```

The corresponding record is

```wl
<|
  "DataType" -> "BoundaryFunctionDifferentialSystem",
  "SchemaVersion" -> 2,
  "BoundaryDomain" -> <|
    "Type" -> "PhysicalBoundaryStratum",
    "TangentialVariables" -> {...}
  |>,
  "DimensionalRegulator" -> eps,
  "BoundaryFunctionIDs" -> {...},
  "NormalResidueNormalForm" -> J,
  "BoundaryModeCoefficientMatrixInNormalResidueBasis" -> B,
  "InducedTangentialConnectionMatrices" -> <|t1 -> Gamma1, ...|>,
  "BoundaryFunctionConnectionMatrices" -> <|t1 -> Omega1, ...|>,
  "Status" -> "BoundaryFunctionDifferentialSystemValidated",
  "Validation" -> <|...|>
|>
```

Validation covers the mathematically necessary identities: horizontality of
the normal residue, invariance of the retained boundary-mode subspace, and
flatness of the induced boundary-function connection.  In a constant Jordan
normal form, horizontality is `[J,Gamma_i]=0`; mixing within a generalized
eigenspace remains part of the system.  Only after this system is evolved
from a declared tangential base point may its initial values be called
boundary constants.  This coefficient matrix is not the complete
Frobenius/Levelt embedding: a solution with resonant logarithms must separately
retain the required normal powers, logarithmic powers, and epsilon orders.

The former letter-sequence evolution and singular matching operator formats
are archived. They are not current production interfaces. Local Frobenius
structure and an induced boundary-function DE do not determine a normalized
connection to an ordinary point or select physical constants.

The intended connection uses the same finite-solution constructor for the
tangential DE and an explicit, correctly truncated matching transformation.
General regularized singular matching, path composition and branch continuation
in that format remain unfinished. Their former implementations, including
epsilon-order propagation through the old maps, are preserved in
[the retirement backup](../FeynFacet/Private_Backup/2026-09-06-production-consolidation/README.md).

## 9. Explicit solutions

The finite-solution format supersedes the earlier completion contract in
this section. See [FiniteMasterIntegralSolutions.md](FiniteMasterIntegralSolutions.md)
for its schema version 3 and executable interface. Upstream differential
systems and boundary intermediates still use version 2.

A MasterIntegralSolution contains explicit finite integral definitions,
finite arithmetic definitions and every requested coefficient. Its initial
constants are I(X0,epsilon) at a fixed ordinary point and are independent of
all kinematic variables. Physical boundary values are not required to solve
the DE up to those constants.

The old ordered coefficient-operator products and their constructors are
retired. Their format cannot pass `MasterIntegralSolutionQ` and is not a solved DE.

A future physical-region result must additionally fix the initial constants,
physical region and analytic continuation. This is distinct from the finite
DE solution up to constants. Undetermined functions on a positive-dimensional
boundary must not be relabelled as constants.

## 10. Artifact flow

    Reduction and master-integral inputs
      -> FamilyDifferentialSystem and block decomposition
      -> sufficient epsilon orders and any needed basis preparation
      -> fixed ordinary base point, domain, branch and finite epsilon request
      -> MasterIntegralSolution (explicit finite expressions, schema 3)
      -> determine initial constants and physical continuation
      -> physical master-integral values and hard-function assembly

The connection may be a strict epsilon form or an accepted non-dlog system
with known homogeneous data. Physical Laurent-order requirements need
justified lower bounds as well as hard-coefficient valuations.

Singular-boundary expansions and boundary-function differential systems remain
available as local mathematics. Their complete matching to ordinary-point
constants is not a prerequisite for constructing a finite solution and is not
yet part of the current end-to-end production interface.

The authoritative commands are in [the production guide](../Scripts/Transport/README.md).

## Migration rule

Live upstream differential-system code writes V2; explicit finite solutions use V3.  V1 generated artifacts are moved intact to a dated
`Stale/DifferentialEquationData` directory.  If a V1 record reaches a V2 core
function, the result is the typed refusal `LegacyDifferentialEquationSchemaUnsupported`.
Regeneration starts from the preserved reduction/master inputs and records the
wall time and peak memory of every mathematical stage as the new performance
baseline.  The pre-V2 payload is at
`Stale/DifferentialEquationData/2026-09-03_pre_v2`.

Performance data are stored beside, not inside, the mathematical result:

```wl
<|
  "DataType" -> "ComputationMetrics",
  "SchemaVersion" -> 2,
  "MathematicalStage" -> "...",
  "Family" -> "CF...",
  "WallTimeSeconds" -> 0.,
  "PeakResidentMemoryBytes" -> 0,
  "WolframKernelCount" -> 1,
  "NativeThreadCount" -> 0
|>
```

Metrics, backend choices, thread counts and file locations do not participate
in mathematical identity, resumption, or acceptance.  Live V2 data contain no
settings or content fingerprints.  A result is resumed from its explicit
mathematical inputs, completed blocks and their validation records.

## Terminology revision, 2026-09-05

The precise interface names and migration instructions are in
[MathematicalTerminology.md](MathematicalTerminology.md).
General integration kernels use `KernelCoefficientMatrices`;
`OffDiagonalKernelCoefficientMatrices` stores the remainder of an
off-diagonal Hermite reduction. `ExactKernelCoefficientDecomposition` does
not assert dlog form. A holomorphic elliptic differential may have a nonzero
kernel coefficient and zero pole residue.

`RegulatorFactorizationUnsuccessful` keeps
`RationalizingParametrizationSearch` separate from `MultiquadraticFactorization`.
Neither a missing catalogue entry nor a failed construction proves
non-rationalizability. Square-root metadata uses `RootCount`,
`MaximumRootCount`, `ParityComponentCount` and `ParityComponentMatrices`;
matrix rank and epsilon expansion order remain distinct concepts.
