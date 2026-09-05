#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];

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
rankSystem = <|
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> "RankSampleToy", "KinematicVariables" -> {x, y},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" -> {rankMaster["RankSampleToy", {1}]},
  "ConnectionMatrices" ->
    {{{D[closureQ, x]/closureQ}}, {{D[closureQ, y]/closureQ}}}|>;
rankCandidate = <|
  "Family" -> "RankSampleToy", "Variables" -> {x, y},
  "Regulator" -> eps, "Ranges" -> {{1}}, "Blocks" -> {{1}},
  "TTotal" -> {{closureQ}}, "TTotalInverse" -> {{1/closureQ}},
  "EpsFormX" -> {{0}}, "EpsFormY" -> {{0}}|>;
rankRecord = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  rankCandidate, rankSystem, <|
    "RelativePath" -> "rank_sample_toy.wl",
    "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
    "Family" -> "RankSampleToy"|>, "IdentityMethod" -> "Symbolic"];
rankDemand = <|
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{1, 1}},
  "MinimumRetainedMasterIntegralEpsilonOrder" -> 1,
  "RegularBasePointAndFirstPathParameterScale" -> <|
    "FirstVariable" -> x, "SecondVariable" -> y,
    "FirstBase" -> 1/4, "SecondBase" -> 1/3,
    "FirstPathParameterScale" -> 1/12|>|>;
rankSampleResult =
  FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
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
    ! FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      rankSampleResult]
|>;

Print[InputForm[checks]];
If[And @@ Values[checks], Exit[0], Exit[1]];
