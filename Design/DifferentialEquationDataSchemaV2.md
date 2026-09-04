# Differential-equation data schema V2

This is the live schema for the master-integral differential-equation flow.
It is a clean break from the generated V1 artifacts.  V1 data is preserved in
a dated `Stale` directory and is not an interface that new code must support.

The schema uses mathematical roles rather than workflow nicknames.  Every
generated record begins with

```wl
"DataType" -> "...",
"SchemaVersion" -> 2
```

and its `Status` names the mathematical statement established.  A bare
`"OK"`, a file fingerprint, or a settings fingerprint is not a mathematical
acceptance statement.

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
  "MasterIntegralBasis" -> {...},
  "ConnectionMatrices" -> {A1, A2}
|>
```

`ConnectionMatrices[[i]]` is the coefficient of `d KinematicVariables[[i]]`.
This replaces the name-dependent `Av/Aw` pair without pretending to support an
arbitrary number of variables in the current implementation.

## 2. Coefficient presentations

There is no common `Chart` or `Frame` record.  A discriminated union contains
one of two mathematically different objects.

### Rationalizing parametrization

```wl
<|
  "DataType" -> "RationalizingParametrization",
  "SchemaVersion" -> 2,
  "Name" -> "...",
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
    <|"GeneratorIndex" -> 1, "GeneratorExpression" -> Sqrt[q1z],
      "QuadraticRadicand" -> q1z, "SourceRadicand" -> q1|>, ...
  },
  "QuadraticRelations" -> {...},
  "SquareClassIndependenceStatus" -> "NotChecked"
|>
```

This record does not claim a degree-`2^r` field or Galois group unless
square-class independence is separately established.

## 3. Block decomposition

```wl
<|
  "DataType" -> "FamilyDifferentialSystemBlockDecomposition",
  "SchemaVersion" -> 2,
  "IrreducibleDiagonalBlocks" -> {{...}, ...},
  "BlockPermutation" -> {...},
  "BlockIndexRanges" -> {...}
|>
```

The rows in each block and the permutation are explicit.  No downstream stage
reconstructs their ordering from file names or dictionary order.

## 4. Diagonal-block dlog epsilon form

```wl
<|
  "DataType" -> "DiagonalBlockDLogEpsilonForm",
  "SchemaVersion" -> 2,
  "BlockRows" -> {...},
  "CoefficientVariables" -> {z1, z2},
  "DimensionalRegulator" -> eps,
  "BasisTransformationMatrix" -> T,
  "InverseBasisTransformationMatrix" -> Tinv,
  "Letters" -> {phi1, ...},
  "ConstantResidueMatrices" -> {R1, ...},
  "Status" -> "DLogEpsilonFormValidated",
  "Validation" -> <|"Method" -> ..., "Passed" -> True, ...|>
|>
```

The transformed connection is defined by
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
  "TransformedOffDiagonalConnectionBlock" -> {B1, B2},
  "DLogPotentials" -> {...},
  "Status" -> "OffDiagonalBasisTransformationBlockValidated",
  "Validation" -> <|"Method" -> ..., "Passed" -> True, ...|>
|>
```

A finite-ansatz failure is `OffDiagonalBlockAnsatzInconsistency`.  The phrase
`OffDiagonalBlockDLogEpsilonFormObstructionCertificate` is reserved for an
ansatz-independent no-go result.

## 6. Family assembly

```wl
<|
  "DataType" ->
    "FamilyDifferentialSystemWithEpsilonFormDiagonalBlocks",
  "SchemaVersion" -> 2,
  "Status" ->
    "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks",
  "FamilyDifferentialSystem" -> <|...|>,
  "BasisTransformationMatrix" -> Ttotal,
  "InverseBasisTransformationMatrix" -> TtotalInv,
  "DiagonalBlockDLogEpsilonForms" -> {...},
  "RationalizingParametrization" -> <|...|>
|>
```

For a generator presentation, the last key is instead
`SquareRootGeneratorsAndQuadraticRelations`.  The status deliberately does not
say that the whole family is in epsilon form: lower off-diagonal connection
blocks may still be general.

## 7. Boundary data and master-integral solution

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

Point data uses `BoundaryConstantID` and
`BoundaryConstantEpsilonCoefficient[id,n]`.  Stratum data uses
`BoundaryFunctionID` and `BoundaryFunctionEpsilonCoefficient[id,n]`.
`FrobeniusModeID`, `BoundaryIntegralID`, and `BoundaryRelation` remain separate
objects.  Degeneracy of a residue eigenspace does not by itself create a
relation among boundary constants or functions.

The publishable analytic output is

```wl
<|
  "DataType" -> "MasterIntegralSolutionInTermsOfBoundaryConstants",
  "SchemaVersion" -> 2,
  "RequestedMasterIntegralEpsilonCoefficients" -> <|...|>,
  "BoundaryConstantTable" -> <|...|>,
  "BoundaryConstantRelations" -> {...},
  "Status" -> "MasterIntegralSolutionInTermsOfBoundaryConstants"
|>
```

At a boundary stratum, the corresponding type and fields say
`BoundaryFunctions`.  A formal iterated-integral expression uses explicit
letter or index sequences; a product of integrals on path segments is not
called one integral on the concatenated path unless Chen's deconcatenation sum
has actually been performed.

## Migration rule

Live code writes only V2.  V1 generated artifacts are moved intact to a dated
`Stale/DifferentialEquationData` directory.  If a V1 record reaches a V2 core
function, the result is the typed refusal `LegacyDifferentialEquationSchemaUnsupported`.
Regeneration starts from the preserved reduction/master inputs and records the
wall time and peak memory of every mathematical stage as the new performance
baseline.
