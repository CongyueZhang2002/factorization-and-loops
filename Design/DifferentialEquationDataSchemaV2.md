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
  "IrreducibleDiagonalBlocks" -> {{...}, ...}
|>
```

The ordered row lists are authoritative.  A permutation or contiguous block
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

Together with the requested hard-function epsilon range, they determine

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
order `n` through the master-integral coefficient of order `n-v`.

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
  "ConnectionResidue" -> R,
  "TruncatedLocalPrefactor" -> H,
  "RetainedLocalOrders" -> {...},
  "RetainedEpsilonOrders" -> {...},
  "Status" -> "TruncatedLocalFrobeniusExpansionValidated",
  "Validation" -> <|...|>
|>
```

The connection residue and local prefactor are mathematical data.  A choice
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
`BoundaryFunctionID` and `BoundaryFunctionEpsilonCoefficient[id,n]`.
`FrobeniusModeID`, `BoundaryIntegralID`, and `BoundaryRelation` remain separate
objects.  Degeneracy of a residue eigenspace does not by itself create a
relation among boundary constants or functions.

A square path evolution object is stored only when it is actually constructed:

```wl
<|
  "DataType" -> "RegularizedBoundaryToBasePointEvolutionOperator",
  "SchemaVersion" -> 2,
  "DifferentialSystemReference" -> <|...|>,
  "BoundaryDomain" -> <|...|>,
  "BasePoint" -> <|...|>,
  "Path" -> <|...|>,
  "RegularizationPrescription" -> <|...|>,
  "EpsilonOrders" -> {...},
  "EvolutionOperatorCoefficients" -> <|...|>,
  "Status" -> "RegularizedBoundaryToBasePointEvolutionOperatorValidated",
  "Validation" -> <|...|>
|>
```

A rectangular, demand-pruned map is not called an evolution operator or
transport matrix.  It is a private
`IteratedIntegralCoefficientOperatorForRequestedOutputs` until requested
entries are constructed.

## 9. Master-integral solutions

The public solution has one data type.  Coverage of requested coefficients and
determination of boundary data are independent properties:

```wl
<|
  "DataType" -> "MasterIntegralSolution",
  "SchemaVersion" -> 2,
  "FamilyDifferentialSystemReference" -> <|...|>,
  "MasterIntegralEpsilonOrderRequirementsReference" -> <|...|>,
  "BoundaryDomain" -> <|...|>,
  "RequestedMasterIntegralEpsilonCoefficients" -> <|...|>,
  "BoundaryConstantTable" -> <|...|>,
  "BoundaryFunctionTable" -> <|...|>,
  "BoundaryRelations" -> {...},
  "DemandCoverage" -> "Complete" | "Incomplete",
  "BoundaryDataStatus" -> "Undetermined" | "Partial" | "Determined",
  "Status" -> "MasterIntegralSolutionConstructed",
  "Validation" -> <|...|>
|>
```

An empty boundary-constant or boundary-function table is omitted.  Formal
iterated-integral expressions use `FormalChenIteratedIntegral` with explicit
letter or index sequences.  A product of integrals on path segments remains a
product; it is not called one integral on the concatenated path unless Chen's
deconcatenation sum has actually been performed.

After all required constants or boundary functions, the physical region, and
the analytic continuation prescription have been fixed, the final object is

```wl
<|
  "DataType" -> "PhysicalRegionMasterIntegralSolution",
  "SchemaVersion" -> 2,
  "MasterIntegralSolutionReference" -> <|...|>,
  "PhysicalRegion" -> <|...|>,
  "AnalyticContinuationPrescription" -> <|...|>,
  "MasterIntegralEpsilonCoefficients" -> <|...|>,
  "Status" -> "PhysicalRegionMasterIntegralSolutionValidated",
  "Validation" -> <|...|>
|>
```

This is the only completed-solution status.  A result still containing
undetermined boundary data remains a `MasterIntegralSolution`, not a physical
region solution.

## 10. Complete artifact flow

```text
Pairs + KiraStream + CanonicalRegistry + master list
  + HardFunctionMasterCoefficientEpsilonValuations
        -> FamilyDifferentialSystem
        -> FamilyDifferentialSystemBlockDecomposition
        -> CoefficientPresentation
        -> diagonal and off-diagonal basis transformations
        -> FamilyDifferentialSystemWithEpsilonFormDiagonalBlocks
           or FamilyDLogEpsilonForm when the stronger equation is validated
        -> MasterIntegralEpsilonOrderRequirements
        -> TruncatedLocalFrobeniusExpansion
        -> BoundaryAsymptoticModeMatching
        -> RegularizedBoundaryToBasePointEvolutionOperator
           and/or private requested-output coefficient operator
        -> MasterIntegralSolution
        -> determine and substitute all boundary data
        -> PhysicalRegionMasterIntegralSolution
```

## Migration rule

Live code writes only V2.  V1 generated artifacts are moved intact to a dated
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
