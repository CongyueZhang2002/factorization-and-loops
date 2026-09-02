#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`finalReconstructionU"];
v = Symbol["Global`finalReconstructionV"];
initial = {{(u + 1)/(v + 2), u - v}};
first = {{1, 2}, {0, 1}};
second = {{2, 0}, {1, 1}};
final = {{1}, {3}};
exactCertificates = <|
  "FamilyEpsilonFormExact" -> True, "BoundaryBaseKernel" -> True,
  "FirstKernelIdentity" -> True, "BoundaryEvolution" -> True,
  "SecondKernelIdentity" -> True|>;
transport = <|
  "Status" -> "ExactObservableTransport",
  "Variables" -> {u, v}, "CoefficientField" -> "Rational",
  "WordRepresentation" -> "OperatorAutomaton",
  "BoundaryEvolutionMethod" -> "MovingKernel", "ConstraintRank" -> 0,
  "DualClosureInitialSpanMethod" -> "NoConstraints",
  "DualClosureStabilizationMethod" -> "NoConstraints",
  "SecondBoundaryClosureInitialSpanMethod" -> "NotRequired",
  "SecondBoundaryClosureStabilizationMethod" -> "NotRequired",
  "ExactOperatorAutomaton" -> <|
    "Status" -> "ExactOperatorAutomaton",
    "RequestedMaximumWeight" -> 2,
    "InitialDemandMap" -> initial,
    "FirstAlphabetIndices" -> {17},
    "FirstOperatorMatrices" -> {first},
    "FirstBoundaryOperator" -> IdentityMatrix[2],
    "SecondAlphabetIndices" -> {29},
    "SecondOperatorMatrices" -> {second},
    "FinalBoundaryEmbedding" -> final|>,
  "Certificates" -> exactCertificates|>;

wordPairs = {{{}, {}}, {{17}, {29}}};
expected = Lookup[
    FeynFacet`ObservableTransportWordMap[transport, #[[1]], #[[2]]],
    "Map"] & /@ wordPairs;
cache = CreateDirectory[];
reconstructed = FeynFacet`ReconstructObservableTransportWordMaps[
  transport, wordPairs,
  "CoordinateCacheDirectory" -> cache,
  "CoordinateKey" -> "two-word-public-integration",
  "ReconstructionThreads" -> Automatic,
  "ValidationPrimeCount" -> 2,
  "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> 7701];
actual = If[AssociationQ[reconstructed],
  Last /@ Lookup[reconstructed, "WordMaps", {}], {}];

FTAssert["the public final-word batch uses modular reconstruction",
  Lookup[reconstructed, "Status", None] ===
      "ModularlyReconstructedObservableWordMaps" &&
    TrueQ[Lookup[reconstructed, "Accepted", False]] &&
    TrueQ[Lookup[reconstructed, "Probabilistic", False]]];
FTAssert["only final word matrices are reconstructed",
  Length[actual] === Length[expected] &&
    And @@ MapThread[
      And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
        {#1, #2}, 2]] &, {actual, expected}]];
FTAssert["the final reconstruction has fresh full-row acceptance",
  Lookup[reconstructed["ModularCertificate"], "Status", None] ===
      "FreshModularIdentityAccepted" &&
    TrueQ[Lookup[reconstructed["ModularCertificate"],
      "AllComplementaryRowsChecked", False]] &&
    reconstructed["ModularCertificate", "EvaluatedFreshTrialCount"] === 2 &&
    reconstructed["ModularCertificate", "GeneratedFreshTrialCount"] === 10];

DeleteDirectory[cache, DeleteContents -> True];
FTReport[];
