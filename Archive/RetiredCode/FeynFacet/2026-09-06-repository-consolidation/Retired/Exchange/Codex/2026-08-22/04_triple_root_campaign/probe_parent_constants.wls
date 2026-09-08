#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 5, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
recordFile = ExpandFileName[arguments[[2]]];
couplingFile = ExpandFileName[arguments[[3]]];
debugCandidate = ExpandFileName[arguments[[4]]];
outputFile = ExpandFileName[arguments[[5]]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[debugCandidate];
End[];

record = Get[recordFile];
coupling = Get[couplingFile];
chartPair = coupling["ChartPair"];
solveRecord = KeyTake[record,
  {"Family", "Sector", "LowerSector", "Variables", "Regulator", "Strip"}];
variables = solveRecord["Variables"];
epsilon = solveRecord["Regulator"];
dimensions = Dimensions[solveRecord["Strip"][[3, 1]]];
couplingDimensions = Dimensions[chartPair[[1]]];
If[Length[dimensions] =!= 2 || Length[couplingDimensions] =!= 2 ||
    couplingDimensions[[2]] =!= dimensions[[2]],
  Print["TRCONSTANT FAIL dimensions=", {dimensions, couplingDimensions}];
  Exit[65]];

prime = 1000003;
epsilonValue = 1/7;
offsets = {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {2, 0}, {0, 2},
  {2, 1}, {1, 2}, {2, 2}, {3, 0}, {0, 3}, {3, 1}, {1, 3},
  {3, 2}, {2, 3}, {3, 3}};

modNumber[value_] := Module[{q = Together[value], denominator},
  If[Cases[q, _Symbol, {0, Infinity}, Heads -> False] =!= {},
    Return[$Failed]];
  denominator = Mod[Denominator[q], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Mod[Numerator[q], prime] PowerMod[denominator, -1, prime], prime]
];

preparation = FeynFacet`PrepareEpsFormStripSampling[solveRecord];
results = {};
Do[
  sample = Quiet[FeynFacet`SampleEpsFormStripAffine[
    solveRecord, epsilonValue, prime,
    "Preparation" -> preparation,
    "ExpectedFingerprint" -> preparation["Fingerprint"],
    "NumeratorDegreeOffset" -> offset,
    "Support" -> "Rectangle",
    "PointCount" -> 40,
    "DiscoverPlan" -> False,
    "RandomSeed" -> 20260822]];
  If[! AssociationQ[sample] ||
      ! MatrixQ[Lookup[sample, "DebugMatrix", None]] ||
      ! MatrixQ[Lookup[sample, "DebugAcceptedPoints", None]],
    AppendTo[results, <|"Offset" -> offset,
      "Status" -> "DebugSampleFailed"|>];
    Continue[]];
  matrix = sample["DebugMatrix"];
  right = sample["DebugRightHandSide"];
  points = sample["DebugAcceptedPoints"];
  couplingColumns = ConstantArray[0,
    {Length[right], dimensions[[1]] couplingDimensions[[1]]}];
  keepRows = {};
  equationsPerPoint = 2 (Times @@ dimensions);
  Do[
    point = points[[pointIndex]];
    rules = Join[Thread[variables -> point], {epsilon -> epsilonValue}];
    couplingValue = Map[modNumber[#1 /. rules] &, chartPair, {3}];
    If[! FreeQ[couplingValue, $Failed], Continue[]];
    localRow = 0;
    Do[
      localRow++;
      rowIndex = (pointIndex - 1) equationsPerPoint + localRow;
      AppendTo[keepRows, rowIndex];
      Do[
        column = (i - 1) couplingDimensions[[1]] + a;
        couplingColumns[[rowIndex, column]] =
          Mod[couplingValue[[mu, a, j]], prime],
        {a, couplingDimensions[[1]]}],
      {mu, 2}, {i, dimensions[[1]]}, {j, dimensions[[2]]}],
    {pointIndex, Length[points]}];
  If[Length[keepRows] <
      sample["GaugeUnknownCount"] + sample["FreeResidueCount"],
    AppendTo[results, <|"Offset" -> offset,
      "Status" -> "CouplingEvaluationFailed"|>];
    Continue[]];
  matrix = matrix[[keepRows]];
  right = right[[keepRows]];
  couplingColumns = couplingColumns[[keepRows]];
  jointMatrix = Join[matrix, SparseArray[couplingColumns], 2];
  {rankSeconds, jointRank} = AbsoluteTiming[
    MatrixRank[jointMatrix, Modulus -> prime]];
  {augmentedSeconds, jointAugmentedRank} = AbsoluteTiming[
    MatrixRank[Join[jointMatrix, SparseArray[List /@ right], 2],
      Modulus -> prime]];
  consistent = jointRank === jointAugmentedRank;
  solution = If[consistent,
    Quiet[Check[LinearSolve[jointMatrix, right, Modulus -> prime], $Failed]],
    $Failed];
  residualZero = VectorQ[solution, IntegerQ] &&
    AllTrue[Mod[jointMatrix . solution - right, prime], #1 === 0 &];
  constants = If[VectorQ[solution, IntegerQ],
    ArrayReshape[
      Take[solution, -dimensions[[1]] couplingDimensions[[1]]],
      {dimensions[[1]], couplingDimensions[[1]]}],
    Missing["NotSolved"]];
  result = <|"Offset" -> offset,
    "Status" -> If[consistent, "Consistent", "Inconsistent"],
    "OriginalRanks" -> {sample["Rank"], sample["AugmentedRank"]},
    "JointMatrixDimensions" -> Dimensions[jointMatrix],
    "JointRanks" -> {jointRank, jointAugmentedRank},
    "AddedRank" -> jointRank - sample["Rank"],
    "RankSeconds" -> rankSeconds,
    "AugmentedRankSeconds" -> augmentedSeconds,
    "ResidualZero" -> residualZero,
    "ParentConstants" -> constants|>;
  AppendTo[results, result];
  Print["TRCONSTANT offset=", offset,
    " original=", result["OriginalRanks"],
    " joint=", result["JointRanks"],
    " added_rank=", result["AddedRank"],
    " status=", result["Status"],
    " residual=", residualZero];
  If[consistent && residualZero, Break[]],
  {offset, offsets}];

output = <|"SourceRecord" -> recordFile,
  "CouplingSource" -> couplingFile,
  "Prime" -> prime, "EpsilonValue" -> epsilonValue,
  "Results" -> results,
  "FirstConsistent" -> SelectFirst[results,
    Lookup[#1, "Status", None] === "Consistent" &&
      TrueQ[Lookup[#1, "ResidualZero", False]] &,
    Missing["NotFound"]]|>;
temporary = outputFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRCONSTANT RESULT first_consistent=",
  InputForm[If[AssociationQ[output["FirstConsistent"]],
    KeyTake[output["FirstConsistent"],
      {"Offset", "OriginalRanks", "JointRanks", "AddedRank",
        "ResidualZero", "ParentConstants"}],
    output["FirstConsistent"]]]];
