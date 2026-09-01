#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
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
automaton = <|
  "Status" -> "ModularCompactAutomatonAccepted",
  "Orientation" -> "DualObservableRows",
  "RequestedMaximumWeight" -> 2,
  "ObservableRankByExactWeight" -> {2, 2, 2},
  "FirstAlphabetIndices" -> {17},
  "SecondAlphabetIndices" -> {29},
  "InitialCoordinates" -> initial,
  "ObservableTransitionsByWeight" -> {{transition}, {IdentityMatrix[2]}},
  "TerminalContractionsByExactWeight" ->
    {terminal0, terminal1, terminal1},
  "CoordinateCertificates" -> {certificate},
  "SecondKernelMatrices" -> {second},
  "FinalBoundaryEmbedding" -> final|>;
result = <|
  "Status" -> "ModularlyVerifiedObservableTransport",
  "WordRepresentation" -> "CompactAutomaton",
  "BoundaryEvolutionMethod" -> "MovingKernel",
  "ConstraintRank" -> 1,
  "DualClosureInitialSpanMethod" -> "NoConstraints",
  "DualClosureStabilizationMethod" -> "NoConstraints",
  "SecondBoundaryClosureInitialSpanMethod" -> "NotRequired",
  "SecondBoundaryClosureStabilizationMethod" -> "NotRequired",
  "CompactTransportAutomaton" -> automaton,
  "Certificates" -> <|
    "FamilyEpsilonFormExact" -> True, "BoundaryBaseKernel" -> True,
    "FirstKernelIdentity" -> True, "BoundaryEvolution" -> True,
    "SecondKernelIdentity" -> True|>,
  "ProbabilisticCertificates" -> <|
    "CoordinateReconstructionFreshModular" -> True,
    "CoordinateSystems" -> {certificate}|>|>;

word = FeynFacet`ObservableTransportWordMap[result, {17}, {29}];
expected = initial . transition . terminal1 . second . final;
operatorInitial = {{2, 1}};
firstOperator = {{1, 3}, {0, 2}};
firstBoundary = {{1, 0, 2}, {0, 1, 1}};
operatorSecond = {{1, 2, 0}, {0, 1, 3}, {4, 0, 1}};
operatorFinal = {{1}, {2}, {3}};
operatorResult = <|
  "Status" -> "ExactObservableTransport",
  "WordRepresentation" -> "OperatorAutomaton",
  "BoundaryEvolutionMethod" -> "MovingKernel",
  "ConstraintRank" -> 1,
  "DualClosureInitialSpanMethod" -> "NoConstraints",
  "DualClosureStabilizationMethod" -> "NoConstraints",
  "SecondBoundaryClosureInitialSpanMethod" -> "NotRequired",
  "SecondBoundaryClosureStabilizationMethod" -> "NotRequired",
  "ExactOperatorAutomaton" -> <|
    "Status" -> "ExactOperatorAutomaton",
    "RequestedMaximumWeight" -> 2,
    "InitialDemandMap" -> operatorInitial,
    "FirstAlphabetIndices" -> {17},
    "FirstOperatorMatrices" -> {firstOperator},
    "FirstBoundaryOperator" -> firstBoundary,
    "SecondAlphabetIndices" -> {29},
    "SecondOperatorMatrices" -> {operatorSecond},
    "FinalBoundaryEmbedding" -> operatorFinal|>,
  "Certificates" -> <|
    "FamilyEpsilonFormExact" -> True, "BoundaryBaseKernel" -> True,
    "FirstKernelIdentity" -> True, "BoundaryEvolution" -> True,
    "SecondKernelIdentity" -> True|>|>;
operatorWord = FeynFacet`ObservableTransportWordMap[
  operatorResult, {17}, {29}];
operatorExpected = operatorInitial . firstOperator . firstBoundary .
  operatorSecond . operatorFinal;
malformedResult = Join[operatorResult, <|
  "WordRepresentation" -> "UnknownRepresentation"|>];
strippedOperatorResult = Join[operatorResult, <|
  "ExactOperatorAutomaton" -> <|
    "Status" -> "ExactOperatorAutomaton"|>|>];
strippedCompactResult = Join[result, <|
  "CompactTransportAutomaton" -> <|
    "Status" -> "ModularCompactAutomatonAccepted"|>|>];
checks = <|
  "CompactAccepted" -> FeynFacet`AcceptedObservableTransportQ[result],
  "WordStatus" ->
    Lookup[word, "Status", None] === "ModularlyVerifiedWordMap",
  "AmbientOrdering" -> Lookup[word, "Map", Missing[]] === expected,
  "OperatorAcceptedExactly" ->
    FeynFacet`AcceptedObservableTransportQ[operatorResult],
  "OperatorWordStatus" ->
    Lookup[operatorWord, "Status", None] === "ExactWordMap",
  "OperatorOrdering" ->
    Lookup[operatorWord, "Map", Missing[]] === operatorExpected,
  "MalformedRecordRejected" ->
    ! FeynFacet`AcceptedObservableTransportQ[malformedResult],
  "StrippedOperatorRejected" ->
    ! FeynFacet`AcceptedObservableTransportQ[strippedOperatorResult],
  "StrippedCompactRejected" ->
    ! FeynFacet`AcceptedObservableTransportQ[strippedCompactResult],
  "UnknownFirstLetterRejected" ->
    Lookup[FeynFacet`ObservableTransportWordMap[result, {18}, {}],
      "Status", None] === "WordUsesUnknownKernel",
  "WeightBoundEnforced" ->
    Lookup[FeynFacet`ObservableTransportWordMap[result, {17, 17, 17}, {}],
      "Status", None] === "WordExceedsRequestedWeight"
|>;

Print[InputForm[checks]];
If[And @@ Values[checks], Exit[0], Exit[1]];
