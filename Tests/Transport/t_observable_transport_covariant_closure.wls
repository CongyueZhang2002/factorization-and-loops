#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

identity = IdentityMatrix[5];
rows = {
  identity[[1]] + x^2 identity[[3]],
  identity[[2]] + x^2 identity[[4]],
  (x - 1)^2 identity[[5]]};
connection = ConstantArray[0, {5, 5}];

exceptionalOnly = FeynFacet`Private`observableTransportCovariantRowClosure[
  rows, connection, x, {x}, {{x -> 0}, {x -> 1}}, 5, 2, 1];
genericIncluded = FeynFacet`Private`observableTransportCovariantRowClosure[
  rows, connection, x, {x}, {{x -> 0}, {x -> 1}, {x -> 2}}, 5, 2, 1];
containment = If[
  Lookup[genericIncluded, "Status", None] ===
      "CovariantRowClosureAccepted",
  FeynFacet`Private`observableTransportModularSubspaceInclusion[
    genericIncluded["Basis"], rows, {x},
    "ValidationPrimeCount" -> 2,
    "ValidationPointsPerPrime" -> 1],
  <||>];

eps = Symbol["Global`closureEpsilon"];
y = Symbol["Global`closureY"];
closureQ = x - 1/4 + y - 1/2;
rankRecord = <|
  "Status" -> "ExactEpsilonForm", "Family" -> "RankSampleToy",
  "Variables" -> {x, y}, "Regulator" -> eps, "Dim" -> 1,
  "Ranges" -> {{1}}, "TTotal" -> {{closureQ}},
  "TTotalInverse" -> {{1/closureQ}}, "EpsFormX" -> eps {{0}},
  "EpsFormY" -> eps {{0}}, "Letters" -> {},
  "ChartRecord" -> <|"CoefficientField" -> "Rational"|>,
  "GateVerdict" -> True, "GaugeIdentity" -> True, "Flatness" -> True,
  "TTotalInvertible" -> True|>;
rankDemand = <|
  "PhysicalRows" -> {1}, "PhysicalOrders" -> {1},
  "PhysicalValuation" -> 1,
  "Path" -> <|"FirstVariable" -> x, "FirstBase" -> 1/4,
    "SecondBase" -> 1/3, "FirstTargetSample" -> 1/3|>|>;
rankSampleResult = FeynFacet`BuildObservableTransport[
  rankRecord, rankDemand,
  "RankSamples" -> {{y -> 1/2}, {y -> 1/2}, {y -> 1/2}}];

checks = <|
  "ExceptionalSampleCannotDropConstraint" ->
    Lookup[exceptionalOnly, "Status", None] =!=
      "CovariantRowClosureAccepted",
  "GenericClosureAccepted" ->
    Lookup[genericIncluded, "Status", None] ===
      "CovariantRowClosureAccepted",
  "OriginalRowsRetained" ->
    Lookup[containment, "Status", None] ===
      "FreshModularSubspaceInclusionAccepted",
  "NonzeroConstraintCannotBecomeRankZero" ->
    Lookup[rankSampleResult, "Status", None] ===
      "SingularConstraintRankSample" &&
    ! FeynFacet`AcceptedObservableTransportQ[rankSampleResult]
|>;

Print[InputForm[checks]];
If[And @@ Values[checks], Exit[0], Exit[1]];
