(* The public schema names the two path-segment letter-index sequences
   explicitly and records validation strength separately from status. *)
#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

initial = {{2, 3}};
transition = {{1, 4}, {0, 2}};
terminal0 = {{1, 0, 0}, {0, 1, 0}};
terminal1 = {{1, 2, 0}, {0, 1, 3}};
second = {{1, 0, 2}, {0, 3, 0}, {4, 0, 1}};
final = {{1, 0}, {2, 1}, {0, 3}};

certificate = <|"Status" -> "FreshModularIdentityAccepted",
  "Accepted" -> True, "Probabilistic" -> True, "Exact" -> False,
  "FreshTrials" -> {<|"Prime" -> 2147483629, "Point" -> {17, 19}|>},
  "AllComplementaryRowsChecked" -> True|>;
valuationCertificate = <|
  "Status" -> "ExactBasisTransformationEpsilonValuationScan",
  "Accepted" -> True, "Probabilistic" -> False, "Exact" -> True,
  "TMin" -> 0, "BlockLower" -> {0}|>;
automaton = <|
  "Status" -> "CompressedIteratedIntegralCoefficientOperatorValidated",
  "Orientation" -> "RequestedOutputDualRows",
  "MaximumIteratedIntegralWeight" -> 2,
  "RequestedOutputDualRowRankByIteratedIntegralWeight" -> {2, 2, 2},
  "FirstPathSegmentAlphabetLetterIndices" -> {17},
  "SecondPathSegmentAlphabetLetterIndices" -> {29},
  "InitialCoordinates" -> initial,
  "RequestedOutputDualTransitionMatricesByIteratedIntegralWeight" ->
    {{transition}, {IdentityMatrix[2]}},
  "TerminalContractionsByExactWeight" ->
    {terminal0, terminal1, terminal1},
  "CoordinateCertificates" -> {certificate},
  "SecondPathSegmentOperatorMatrices" -> {second},
  "FinalBoundaryEmbedding" -> final,
  "Validation" -> <|"Method" -> "ProbabilisticFiniteFieldSampling",
    "Passed" -> True, "Exact" -> False,
    "Probabilistic" -> True|>|>;
result = <|
  "DataType" -> "IteratedIntegralCoefficientOperatorForRequestedOutputs",
  "SchemaVersion" -> 2,
  "Status" ->
    "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated",
  "IteratedIntegralCoefficientRepresentation" ->
    "CompressedIteratedIntegralCoefficientOperator",
  "BoundaryConstraintSubspaceRepresentation" -> "MovingNullspaceBasis",
  "ConstraintRank" -> 1,
  "DualClosureInitialSpanMethod" -> "NoConstraints",
  "DualClosureStabilizationMethod" -> "NoConstraints",
  "SecondBoundaryClosureInitialSpanMethod" -> "NotRequired",
  "SecondBoundaryClosureStabilizationMethod" -> "NotRequired",
  "TransportEpsilonValuationSource" ->
    "ComputedFromBasisTransformationMatrix",
  "TransportEpsilonValuationCertificate" -> valuationCertificate,
  "TransportEpsilonValuations" -> <|"TMin" -> 0, "BlockLower" -> {0}|>,
  "CompressedIteratedIntegralCoefficientOperator" -> automaton,
  "Certificates" -> <|
    "FamilyInputAccepted" -> True, "FamilyEpsilonFormExact" -> True,
    "TransportEpsilonValuationsBound" -> True,
    "BoundaryBaseKernel" -> True,
    "FirstKernelIdentity" -> True,
    "BoundaryConstraintSubspaceValidated" -> True,
    "SecondKernelIdentity" -> True|>,
  "ProbabilisticCertificates" -> <|
    "CoordinateReconstructionFreshModular" -> True,
    "CoordinateSystems" -> {certificate}|>,
  "Validation" -> <|"Method" -> "ProbabilisticFiniteFieldSampling",
    "Passed" -> True, "Exact" -> False,
    "Probabilistic" -> True|>|>;

coefficientMatrix =
  FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
    result, {17}, {29}];
expected = initial . transition . terminal1 . second . final;
operatorInitial = {{2, 1}};
firstOperator = {{1, 3}, {0, 2}};
firstBoundary = {{1, 0, 2}, {0, 1, 1}};
operatorSecond = {{1, 2, 0}, {0, 1, 3}, {4, 0, 1}};
operatorFinal = {{1}, {2}, {3}};
operatorResult = <|
  "DataType" -> "IteratedIntegralCoefficientOperatorForRequestedOutputs",
  "SchemaVersion" -> 2,
  "Status" ->
    "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated",
  "IteratedIntegralCoefficientRepresentation" ->
    "IteratedIntegralCoefficientOperatorForRequestedOutputs",
  "BoundaryConstraintSubspaceRepresentation" -> "MovingNullspaceBasis",
  "ConstraintRank" -> 1,
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
    "InitialRequestedOutputMap" -> operatorInitial,
    "FirstPathSegmentAlphabetLetterIndices" -> {17},
    "FirstPathSegmentOperatorMatrices" -> {firstOperator},
    "FirstPathSegmentBoundaryMap" -> firstBoundary,
    "SecondPathSegmentAlphabetLetterIndices" -> {29},
    "SecondPathSegmentOperatorMatrices" -> {operatorSecond},
    "FinalBoundaryEmbedding" -> operatorFinal|>,
  "Certificates" -> <|
    "FamilyInputAccepted" -> True, "FamilyEpsilonFormExact" -> True,
    "TransportEpsilonValuationsBound" -> True,
    "BoundaryBaseKernel" -> True,
    "FirstKernelIdentity" -> True,
    "BoundaryConstraintSubspaceValidated" -> True,
    "SecondKernelIdentity" -> True|>,
  "ProbabilisticCertificates" -> <||>,
  "Validation" -> <|"Method" -> "DeterministicSymbolic",
    "Passed" -> True, "Exact" -> True,
    "Probabilistic" -> False|>|>;
operatorCoefficientMatrix =
  FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
    operatorResult, {17}, {29}];
operatorExpected = operatorInitial . firstOperator . firstBoundary .
  operatorSecond . operatorFinal;
malformedResult = Join[operatorResult, <|
  "IteratedIntegralCoefficientRepresentation" ->
    "UnknownRepresentation"|>];
strippedOperatorResult = Join[operatorResult, <|
  "ExactIteratedIntegralCoefficientOperator" -> <|
    "Status" -> "IteratedIntegralCoefficientOperatorConstructed"|>|>];
strippedCompactResult = Join[result, <|
  "CompressedIteratedIntegralCoefficientOperator" -> <|
    "Status" ->
      "CompressedIteratedIntegralCoefficientOperatorValidated"|>|>];
checks = <|
  "CompactAccepted" ->
    FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      result],
  "CoefficientMatrixStatus" ->
    Lookup[coefficientMatrix, "Status", None] ===
      "IteratedIntegralCoefficientMatrixComputed",
  "AmbientOrdering" -> Lookup[coefficientMatrix,
    "IteratedIntegralCoefficientMatrix", Missing[]] === expected,
  "OperatorAcceptedExactly" ->
    FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      operatorResult],
  "OperatorCoefficientMatrixStatus" ->
    Lookup[operatorCoefficientMatrix, "Status", None] ===
      "IteratedIntegralCoefficientMatrixComputed",
  "OperatorOrdering" -> Lookup[operatorCoefficientMatrix,
    "IteratedIntegralCoefficientMatrix", Missing[]] === operatorExpected,
  "MalformedRecordRejected" ->
    ! FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      malformedResult],
  "StrippedOperatorRejected" ->
    ! FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      strippedOperatorResult],
  "StrippedCompactRejected" ->
    ! FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      strippedCompactResult],
  "UnknownFirstLetterRejected" ->
    Lookup[
      FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
        result, {18}, {}], "Status", None] ===
      "IteratedIntegralIndexSequenceContainsUnknownLetterIndex",
  "WeightBoundEnforced" ->
    Lookup[
      FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
        result, {17, 17, 17}, {}], "Status", None] ===
      "LetterIndexSequencesExceedRequestedWeight"
|>;

Print[InputForm[checks]];
If[And @@ Values[checks], Exit[0], Exit[1]];
