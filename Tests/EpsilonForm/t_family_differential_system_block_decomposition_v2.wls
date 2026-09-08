#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[xBlock, yBlock, epsBlock];

FTAssert["V2 block-decomposition API is exported with usage messages",
  System`Names[
      "FeynFacet`BuildFamilyDifferentialSystemBlockDecomposition"] =!= {} &&
    System`Names[
      "FeynFacet`FamilyDifferentialSystemBlockDecompositionQ"] =!= {} &&
    StringQ[
      BuildFamilyDifferentialSystemBlockDecomposition::usage] &&
    StringQ[FamilyDifferentialSystemBlockDecompositionQ::usage]];

a1 = ConstantArray[0, {5, 5}];
a2 = ConstantArray[0, {5, 5}];

(* SCC {1,3}; row 2 depends on it; SCC {4,5} depends on row 2.  The
   lower-triangular row order is consequently {1,3,2,4,5}, not the original
   basis order. *)
a1[[1, 3]] = xBlock/(1 - xBlock);
a1[[3, 1]] = 1/(1 + xBlock);
a1[[2, 3]] = epsBlock/(1 + xBlock);
a1[[4, 5]] = 1 + xBlock;
a1[[5, 4]] = 1/(1 - xBlock);
a1[[4, 2]] = epsBlock xBlock;

system = <|
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Status" -> "FamilyDifferentialSystemValidated",
  "Family" -> "SyntheticBlockFamily",
  "KinematicVariables" -> {xBlock, yBlock},
  "DimensionalRegulator" -> epsBlock,
  "OriginalMasterIntegralBasis" -> Array[masterIntegral, 5],
  "ConnectionMatrices" -> {a1, a2}|>;

reference = <|
  "RelativePath" ->
    "synthetic/SyntheticBlockFamily/FamilyDifferentialSystem.wl",
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> "SyntheticBlockFamily"|>;

exact = BuildFamilyDifferentialSystemBlockDecomposition[
  system, reference,
  "ValidationMethod" -> "CharacteristicZeroSymbolicIdentity"];

FTAssert["exact construction derives the nontrivially permuted SCC order",
  AssociationQ[exact] &&
    exact["DataType"] ===
      "FamilyDifferentialSystemBlockDecomposition" &&
    exact["SchemaVersion"] === 2 &&
    exact["Status"] ===
      "FamilyDifferentialSystemBlockDecompositionValidated" &&
    exact["DiagonalBlocksInCurrentBasis"] === {{1, 3}, {2}, {4, 5}}];

FTAssert["exact validation records its strength honestly",
  exact["Validation", "Method"] ===
      "CharacteristicZeroSymbolicIdentity" &&
    TrueQ[exact["Validation", "Exact"]] &&
    ! TrueQ[exact["Validation", "Probabilistic"]] &&
    TrueQ[exact["Validation", "StronglyConnectedComponentsDerived"]] &&
    TrueQ[exact["Validation",
      "RowsPartitionOriginalMasterIntegralBasis"]] &&
    TrueQ[exact["Validation", "AboveDiagonalConnectionBlocksZero"]]];

FTAssert["exact decomposition predicate re-evaluates and accepts",
  TrueQ[FamilyDifferentialSystemBlockDecompositionQ[exact, system]]];

nonLowerClaim = Join[exact, <|
  "DiagonalBlocksInCurrentBasis" ->
    Reverse[exact["DiagonalBlocksInCurrentBasis"]]|>];
FTAssert["reordered non-lower-triangular block claim is refused",
  ! TrueQ[FamilyDifferentialSystemBlockDecompositionQ[
    nonLowerClaim, system]]];

malformedPartition = Join[exact, <|
  "DiagonalBlocksInCurrentBasis" -> {{1, 3}, {2}, {4, 4}}|>];
FTAssert["malformed row partition is refused",
  ! TrueQ[FamilyDifferentialSystemBlockDecompositionQ[
    malformedPartition, system]]];

sampled = BuildFamilyDifferentialSystemBlockDecomposition[
  system, reference,
  "ValidationMethod" -> "ProbabilisticFiniteFieldSampling",
  "FiniteFieldPrimes" -> {1009, 1013},
  "PointsPerPrime" -> 2,
  "Seed" -> 7719,
  "MaximumAttemptsPerPrime" -> 12];

FTAssert["finite-field construction derives the same ordered components",
  AssociationQ[sampled] &&
    sampled["DiagonalBlocksInCurrentBasis"] ===
      exact["DiagonalBlocksInCurrentBasis"] &&
    sampled["Validation", "Method"] ===
      "ProbabilisticFiniteFieldSampling" &&
    ! TrueQ[sampled["Validation", "Exact"]] &&
    TrueQ[sampled["Validation", "Probabilistic"]] &&
    Length[sampled["Validation", "Samples"]] === 4];

FTAssert["finite-field predicate replays the stored points",
  TrueQ[FamilyDifferentialSystemBlockDecompositionQ[sampled, system]]];

FTAssert["record has one authoritative block list and no digests",
  KeyExistsQ[exact, "DiagonalBlocksInCurrentBasis"] &&
    FreeQ[Keys[exact],
      "BasisPermutation" | "RowOrder" | "Blocks" |
      "Hash" | "Fingerprint" | "SHA256"]];

cliSource = Import[FileNameJoin[{root, "Scripts", "DifferentialEquations",
  "build_family_differential_system_block_decomposition_v2.wls"}], "Text"];
FTAssert["CLI takes explicit or repository-relative V2 paths only",
  StringContainsQ[cliSource, "--family-differential-system"] &&
    StringContainsQ[cliSource, "--repository-root"] &&
    ! AnyTrue[{"nnlo_de_", "ClassID", "block_class_assign",
        "Fingerprint", "SHA256"},
      StringContainsQ[cliSource, #] &]];


(* Strong connectivity is relative to basis permutations, not differential irreducibility. *)
coupledSystem = Join[system, <|
  "OriginalMasterIntegralBasis" -> {masterIntegral[1], masterIntegral[2]},
  "ConnectionMatrices" -> {epsBlock {{0, 1}, {1, 0}}/xBlock,
    ConstantArray[0, {2, 2}]}|>];
coupledBlocks = BuildFamilyDifferentialSystemBlockDecomposition[
  coupledSystem, reference,
  "ValidationMethod" -> "CharacteristicZeroSymbolicIdentity"];
constantBasisChange = {{1, 1}, {1, -1}};
FTAssert["a diagonalizable coupled system has one graph block without an irreducibility claim",
  coupledBlocks["DiagonalBlocksInCurrentBasis"] === {{1, 2}} &&
    ! KeyExistsQ[coupledBlocks, "IrreducibleDiagonalBlocks"] &&
    Inverse[constantBasisChange].{{0, 1}, {1, 0}}.constantBasisChange ===
      DiagonalMatrix[{1, -1}]];


FTReport[];
