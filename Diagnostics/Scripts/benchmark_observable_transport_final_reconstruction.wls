#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2, Exit[64]];
family = arguments[[1]];
maximumWeight = Quiet[Check[ToExpression[arguments[[2]]], $Failed]];
cacheTag = If[Length[arguments] >= 3,
  StringReplace[arguments[[3]], Except[LetterCharacter | DigitCharacter |
      "-" | "_"] -> ""], ""];
If[! StringMatchQ[family, "CF" ~~ DigitCharacter ..] ||
    ! IntegerQ[maximumWeight] || maximumWeight < 0, Exit[64]];

root = DirectoryName[DirectoryName[DirectoryName[
  ExpandFileName[$InputFileName]]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
benchmarkRoot = FileNameJoin[{root, "Runtime",
  "2026-09-01_observable_transport_benchmarks", family}];
operatorFile = FileNameJoin[{benchmarkRoot,
  "operatorautomaton_result.wl"}];
materializedFile = FileNameJoin[{benchmarkRoot,
  "materializedwords-w2_result.wl"}];
If[! FileExistsQ[operatorFile] || ! FileExistsQ[materializedFile], Exit[66]];
operator = Get[operatorFile];
materialized = Get[materializedFile];
reference = Select[materialized["TwoSegmentWordMaps"],
  Length[#[[1]]] + Length[#[[2]]] <= maximumWeight &];
wordPairs = #[[{1, 2}]] & /@ reference;
cache = FileNameJoin[{benchmarkRoot,
  "final-reconstruction-w" <> ToString[maximumWeight] <>
    If[cacheTag === "", "", "-" <> cacheTag]}];

{seconds, reconstruction} = AbsoluteTiming[
  FeynFacet`ReconstructObservableTransportWordMaps[
    operator, wordPairs,
    "CoordinateCacheDirectory" -> cache,
    "CoordinateKey" -> "final-word-batch",
    "ReconstructionThreads" -> 4,
    "ValidationPrimeCount" -> 2,
    "ValidationPointsPerPrime" -> 1,
    "Verbose" -> True]];
variables = operator["Variables"];
samples = Thread[variables -> #] & /@
  {{1/5, 2/7}, {2/9, 3/8}, {4/11, 5/13}};
actual = Lookup[reconstruction, "WordMaps", {}];
equalAtSamples[a_, b_] := AllTrue[samples, Function[rules,
  aa = Flatten[Normal[a] /. rules];
  bb = Flatten[Normal[b] /. rules];
  Length[aa] === Length[bb] &&
    And @@ MapThread[TrueQ[#1 == #2] &, {aa, bb}]]];
comparisons = If[Length[actual] === Length[reference],
  MapThread[equalAtSamples[#1[[3]], #2[[3]]] &,
    {reference, actual}], {}];
certificate = Lookup[reconstruction, "ModularCertificate", <||>];
summary = <|
  "Family" -> family, "MaximumWeight" -> maximumWeight,
  "WordCount" -> Length[wordPairs], "Seconds" -> seconds,
  "Status" -> Lookup[reconstruction, "Status", None],
  "Accepted" -> TrueQ[Lookup[reconstruction, "Accepted", False]],
  "PassedWordCount" -> Count[comparisons, True],
  "AllWordsPassed" -> comparisons =!= {} && And @@ comparisons,
  "TraceSeconds" -> Lookup[certificate, "TraceSeconds", Missing[]],
  "ReconstructionSeconds" ->
    Lookup[certificate, "ReconstructionSeconds", Missing[]],
  "GeneratedFreshTrialCount" ->
    Lookup[certificate, "GeneratedFreshTrialCount", Missing[]],
  "EvaluatedFreshTrialCount" ->
    Lookup[certificate, "EvaluatedFreshTrialCount", Missing[]],
  "SolutionBytes" -> Lookup[certificate, "SolutionBytes", Missing[]]|>;
Put[summary, FileNameJoin[{benchmarkRoot,
  "final-reconstruction-w" <> ToString[maximumWeight] <>
    If[cacheTag === "", "", "-" <> cacheTag] <> "_summary.wl"}]];
Print[InputForm[summary]];
If[TrueQ[summary["Accepted"]] && TrueQ[summary["AllWordsPassed"]],
  Exit[0], Exit[1]];
