(* Reconstruct a requested batch while retaining its two path-segment
   letter-index sequences explicitly. *)
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
  "FamilyInputAccepted" -> True, "FamilyEpsilonFormExact" -> True,
  "TransportEpsilonValuationsBound" -> True,
  "BoundaryBaseKernel" -> True,
  "FirstKernelIdentity" -> True,
  "BoundaryConstraintSubspaceValidated" -> True,
  "SecondKernelIdentity" -> True|>;
valuationCertificate = <|
  "Status" -> "ExactBasisTransformationEpsilonValuationScan",
  "Accepted" -> True, "Probabilistic" -> False, "Exact" -> True,
  "TMin" -> 0, "BlockLower" -> {0}|>;
transport = <|
  "DataType" -> "IteratedIntegralCoefficientOperatorForRequestedOutputs",
  "SchemaVersion" -> 2,
  "Status" ->
    "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated",
  "CoefficientVariables" -> {u, v},
  "CoefficientPresentationType" -> "Rational",
  "IteratedIntegralCoefficientRepresentation" ->
    "IteratedIntegralCoefficientOperatorForRequestedOutputs",
  "BoundaryConstraintSubspaceRepresentation" -> "MovingNullspaceBasis",
  "ConstraintRank" -> 0,
  "DualClosureInitialSpanMethod" -> "NoConstraints",
  "DualClosureStabilizationMethod" -> "NoConstraints",
  "SecondBoundaryClosureInitialSpanMethod" -> "NotRequired",
  "SecondBoundaryClosureStabilizationMethod" -> "NotRequired",
  "TransportEpsilonValuationSource" ->
    "ComputedFromBasisTransformationMatrix",
  "TransportEpsilonValuationCertificate" -> valuationCertificate,
  "TransportEpsilonValuations" -> <|"TMin" -> 0, "BlockLower" -> {0}|>,
  "ExactIteratedIntegralCoefficientOperator" -> <|
    "Status" -> "IteratedIntegralCoefficientOperatorConstructed",
    "MaximumIteratedIntegralWeight" -> 2,
    "InitialRequestedOutputMap" -> initial,
    "FirstPathSegmentAlphabetLetterIndices" -> {17},
    "FirstPathSegmentOperatorMatrices" -> {first},
    "FirstPathSegmentBoundaryMap" -> IdentityMatrix[2],
    "SecondPathSegmentAlphabetLetterIndices" -> {29},
    "SecondPathSegmentOperatorMatrices" -> {second},
    "FinalBoundaryEmbedding" -> final|>,
  "Certificates" -> exactCertificates,
  "ProbabilisticCertificates" -> <||>,
  "Validation" -> <|"Method" -> "DeterministicSymbolic",
    "Passed" -> True, "Exact" -> True,
    "Probabilistic" -> False|>|>;

letterIndexSequencePairs = {{{}, {}}, {{17}, {29}}};
expected = Lookup[
    FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
      transport, #[[1]], #[[2]]],
    "IteratedIntegralCoefficientMatrix"] & /@ letterIndexSequencePairs;
cache = CreateDirectory[];
reconstructed =
  FeynFacet`ReconstructIteratedIntegralCoefficientMatricesForRequestedOutputs[
  transport, letterIndexSequencePairs,
  "CoordinateCacheDirectory" -> cache,
  "CoordinateKey" -> "two-word-public-integration",
  "ReconstructionThreads" -> Automatic,
  "ValidationPrimeCount" -> 2,
  "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> 7701];
actual = If[AssociationQ[reconstructed],
  Lookup[Lookup[reconstructed,
    "IteratedIntegralCoefficientMatrixRecords", {}],
    "IteratedIntegralCoefficientMatrix"], {}];

FTAssert["the public coefficient-matrix batch uses modular reconstruction",
  Lookup[reconstructed, "Status", None] ===
      "IteratedIntegralCoefficientMatricesForRequestedOutputsReconstructed" &&
    Lookup[reconstructed["Validation"], "Method", None] ===
      "ProbabilisticFiniteFieldSampling" &&
    TrueQ[Lookup[reconstructed["Validation"], "Passed", False]]];
FTAssert["only requested coefficient matrices are reconstructed",
  Length[actual] === Length[expected] &&
    And @@ MapThread[
      And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
        {#1, #2}, 2]] &, {actual, expected}]];
FTAssert["the final reconstruction has fresh full-row acceptance",
  Lookup[reconstructed["Validation", "Certificate"], "Status", None] ===
      "FreshModularIdentityAccepted" &&
    TrueQ[Lookup[reconstructed["Validation", "Certificate"],
      "AllComplementaryRowsChecked", False]] &&
    reconstructed["Validation", "Certificate",
      "EvaluatedFreshTrialCount"] === 2 &&
    reconstructed["Validation", "Certificate",
      "GeneratedFreshTrialCount"] === 10];

DeleteDirectory[cache, DeleteContents -> True];
FTReport[];
