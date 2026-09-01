#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
runID = CreateUUID["observable-transport-benchmark-"];
family = If[arguments === {}, "CF249", First[arguments]];
If[! StringMatchQ[family, "CF" ~~ DigitCharacter ..], Exit[64]];
representation = If[Length[arguments] >= 2, arguments[[2]],
  "CompactAutomaton"];
If[! MemberQ[{"CompactAutomaton", "OperatorAutomaton",
    "MaterializedWords"}, representation], Exit[64]];
maximumWeight = If[Length[arguments] >= 3,
  Quiet[Check[ToExpression[arguments[[3]]], $Failed]], Automatic];
If[maximumWeight =!= Automatic &&
    (! IntegerQ[maximumWeight] || maximumWeight < 0), Exit[64]];

root = DirectoryName[DirectoryName[DirectoryName[
  ExpandFileName[$InputFileName]]]];
sourceRoot = FileNameJoin[{DirectoryName[root], "factorization-and-loops"}];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
base = {"ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"};
epsilonFormFile = FileNameJoin[Join[{sourceRoot}, base,
  {"FamilyEpsFormsCertified", "family_epsform_" <> family <> ".wl"}]];
differentialFile = FileNameJoin[Join[{root}, base,
  {"DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
valuationsFile = FileNameJoin[Join[{sourceRoot}, base,
  {"MasterCoefficientValuations.wl"}]];
oldFile = FileNameJoin[{root, "Runtime",
  "2026-09-01_observable_transport_campaign", "families",
  "observable_transport_" <> family <> ".wl"}];
benchmarkRoot = FileNameJoin[{root, "Runtime",
  "2026-09-01_observable_transport_benchmarks", family}];
If[! DirectoryQ[benchmarkRoot],
  CreateDirectory[benchmarkRoot, CreateIntermediateDirectories -> True]];

epsilonForm = Get[epsilonFormFile];
differential = Get[differentialFile];
valuations = Get[valuationsFile];
demand = FeynFacet`BuildObservableTransportDemand[
  epsilonForm, differential, valuations];
If[Lookup[demand, "Status", None] =!= "ExactObservableDemand", Exit[1]];

{compactSeconds, compact} = AbsoluteTiming[
  FeynFacet`BuildObservableTransport[
    epsilonForm, demand,
    "WordRepresentation" -> representation,
    "MaximumWeight" -> maximumWeight,
    "CoordinateBackend" -> "Ratracer",
    "CoordinateCacheDirectory" -> FileNameJoin[{benchmarkRoot,
      "coordinates"}],
    "ReconstructionThreads" -> 1,
    "ValidationPrimeCount" -> 2,
    "ValidationPointsPerPrime" -> 1,
    "Verbose" -> True]];
If[Lookup[compact, "Status", None] === "BoundarySubspaceNotInvariant",
  alternateRecord = Join[epsilonForm,
    <|"Variables" -> Reverse[epsilonForm["Variables"]]|>];
  alternatePath = FeynFacet`FindObservableTransportPath[alternateRecord];
  If[AssociationQ[alternatePath] &&
      Lookup[alternatePath, "Status", None] === "ExactPathData",
    demand = Join[demand, <|"Path" -> alternatePath|>];
    {alternateSeconds, compact} = AbsoluteTiming[
      FeynFacet`BuildObservableTransport[
        epsilonForm, demand,
        "WordRepresentation" -> representation,
        "MaximumWeight" -> maximumWeight,
        "CoordinateBackend" -> "Ratracer",
        "CoordinateCacheDirectory" -> FileNameJoin[{benchmarkRoot,
          "coordinates-reversed"}],
        "ReconstructionThreads" -> 1,
        "ValidationPrimeCount" -> 2,
        "ValidationPointsPerPrime" -> 1,
        "Verbose" -> True]];
    compactSeconds += alternateSeconds;
    compact = Join[compact,
      <|"PrimaryPathStatus" -> "BoundarySubspaceNotInvariant"|>]
  ]
];

oldBytes = If[FileExistsQ[oldFile], FileByteCount[oldFile], 0];
old = If[0 < oldBytes <= 50 2^20, Quiet[Check[Get[oldFile], $Failed]],
  Missing["LargeBaselineNotLoaded"]];
variables = epsilonForm["Variables"];
samples = Thread[variables -> #] & /@
  {{1/5, 2/7}, {2/9, 3/8}, {4/11, 5/13}};
gaugeRules = Lookup[compact, "GaugeConstantRules", {}];
matrixEqualAtSamples[a_, b_] := AllTrue[samples, Function[rules,
  aa = Flatten[Normal[a] /. gaugeRules /. rules];
  bb = Flatten[Normal[b] /. gaugeRules /. rules];
  Quiet[Check[Length[aa] === Length[bb] &&
    And @@ MapThread[TrueQ[#1 == #2] &, {aa, bb}], False]]]];
comparisons = If[AssociationQ[old] &&
    ListQ[Lookup[old, "TwoSegmentWordMaps", None]],
  Map[
    Function[item,
      word = FeynFacet`ObservableTransportWordMap[
        compact, item[[1]], item[[2]]];
      MemberQ[{"ExactWordMap", "ModularlyVerifiedWordMap"},
          Lookup[word, "Status", None]] &&
        matrixEqualAtSamples[item[[3]], word["Map"]]],
    old["TwoSegmentWordMaps"]],
  Missing["BaselineComparisonSkipped"]];
failureDiagnostic = If[ListQ[comparisons] && MemberQ[comparisons, False],
  failedPosition = First@FirstPosition[comparisons, False];
  failedItem = old["TwoSegmentWordMaps"][[failedPosition]];
  failedWord = FeynFacet`ObservableTransportWordMap[
    compact, failedItem[[1]], failedItem[[2]]];
  oldSample = Normal[failedItem[[3]]] /. gaugeRules /. First[samples];
  newSample = Normal[Lookup[failedWord, "Map", {{}}]] /.
    gaugeRules /. First[samples];
  differences = Position[MapThread[! TrueQ[#1 == #2] &,
    {oldSample, newSample}, 2], True, {2}];
  firstDifference = If[differences === {}, Missing[], First[differences]];
  sampleEqualityCounts = Table[
    aa = Flatten[Normal[failedItem[[3]]] /. gaugeRules /. rules];
    bb = Flatten[Normal[Lookup[failedWord, "Map", {{}}]] /.
      gaugeRules /. rules];
    equalities = MapThread[TrueQ[#1 == #2] &, {aa, bb}];
    {Length[aa], Length[bb], Count[equalities, True],
      Count[equalities, False]}, {rules, samples}];
  <|"Position" -> failedPosition,
    "FirstWord" -> failedItem[[1]],
    "SecondWord" -> failedItem[[2]],
    "WordStatus" -> Lookup[failedWord, "Status", None],
    "OldDimensions" -> Dimensions[oldSample],
    "NewDimensions" -> Dimensions[newSample],
    "DifferenceCountAtFirstSample" -> Length[differences],
    "FirstDifferencePositions" -> Take[differences, UpTo[10]],
    "OldRemainingSymbols" ->
      DeleteDuplicates[Cases[oldSample, _Symbol, Infinity]],
    "NewRemainingSymbols" ->
      DeleteDuplicates[Cases[newSample, _Symbol, Infinity]],
    "FirstOldValue" -> If[MissingQ[firstDifference], Missing[],
      Extract[oldSample, firstDifference]],
    "FirstNewValue" -> If[MissingQ[firstDifference], Missing[],
      Extract[newSample, firstDifference]],
    "FirstDifferenceTogether" -> If[MissingQ[firstDifference], Missing[],
      Together[Extract[oldSample - newSample, firstDifference]]],
    "SampleEqualityCounts" -> sampleEqualityCounts|>,
  <||>];

If[FeynFacet`AcceptedObservableTransportQ[compact],
  compact = Join[compact, <|"BenchmarkRunID" -> runID|>]];
summary = <|
  "BenchmarkRunID" -> runID,
  "Family" -> family,
  "RequestedRepresentation" -> representation,
  "RequestedMaximumWeight" -> maximumWeight,
  "CompactStatus" -> Lookup[compact, "Status", None],
  "CompactAccepted" -> FeynFacet`AcceptedObservableTransportQ[compact],
  "FailureDiagnostics" -> KeyTake[compact,
    {"Weight", "InvalidEntryCount", "InvalidEntryPositions",
      "UnsupportedHeads", "InvalidEntryExamples",
      "InvalidSpacePositions", "InvalidCandidatePositions",
      "InvalidExamples", "RemainingSymbols", "Prime", "Point",
      "SpaceRank", "JoinedRank", "Accepted", "Required"}],
  "ComparisonFailureDiagnostic" -> failureDiagnostic,
  "CompactSeconds" -> compactSeconds,
  "CompactBytes" -> ByteCount[compact],
  "BoundaryEvolutionMethod" -> Lookup[compact,
    "BoundaryEvolutionMethod", Missing[]],
  "BoundaryConstraintLeafCount" -> Lookup[compact,
    "BoundaryConstraintLeafCount", Missing[]],
  "MaterializedWordCountUpperBound" -> Lookup[compact,
    "MaterializedWordCountUpperBound", Missing[]],
  "CompactRanks" -> If[AssociationQ[Lookup[compact,
      "CompactTransportAutomaton", None]],
    compact["CompactTransportAutomaton", "ObservableRankByExactWeight"],
    Missing[]],
  "OldArtifactBytes" -> oldBytes,
  "OldStatus" -> If[AssociationQ[old], Lookup[old, "Status", None],
    Missing["NotLoaded"]],
  "OldSeconds" -> If[AssociationQ[old], Lookup[old, "Seconds",
    Lookup[old, "TotalSeconds", Missing[]]], Missing["NotLoaded"]],
  "ComparedWordCount" -> If[ListQ[comparisons], Length[comparisons], 0],
  "PassedWordCount" -> If[ListQ[comparisons],
    Count[comparisons, True], 0],
  "AllComparedWordsPassed" -> If[ListQ[comparisons],
    comparisons =!= {} && And @@ comparisons,
    Missing["BaselineComparisonSkipped"]]
|>;

tag = ToLowerCase[representation] <> If[maximumWeight === Automatic,
  "", "-w" <> ToString[maximumWeight]];
output = FileNameJoin[{benchmarkRoot, tag <> "_result.wl"}];
summaryFile = FileNameJoin[{benchmarkRoot, tag <> "_summary.wl"}];
If[FeynFacet`AcceptedObservableTransportQ[compact], Put[compact, output]];
Put[summary, summaryFile];
Print[InputForm[summary]];
If[FeynFacet`AcceptedObservableTransportQ[compact] &&
    (! ListQ[comparisons] || TrueQ[summary["AllComparedWordsPassed"]]),
  Exit[0], Exit[1]];
