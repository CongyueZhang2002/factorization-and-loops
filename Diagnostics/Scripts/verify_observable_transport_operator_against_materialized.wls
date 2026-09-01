#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2, Exit[64]];
family = arguments[[1]];
maximumWeight = Quiet[Check[ToExpression[arguments[[2]]], $Failed]];
If[! StringMatchQ[family, "CF" ~~ DigitCharacter ..] ||
    ! MatchQ[maximumWeight, Automatic | _Integer] ||
    (IntegerQ[maximumWeight] && maximumWeight < 0), Exit[64]];

root = DirectoryName[DirectoryName[DirectoryName[
  ExpandFileName[$InputFileName]]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
benchmarkRoot = FileNameJoin[{root, "Runtime",
  "2026-09-01_observable_transport_benchmarks", family}];
operatorFile = FileNameJoin[{benchmarkRoot,
  "operatorautomaton_result.wl"}];
operatorSummaryFile = FileNameJoin[{benchmarkRoot,
  "operatorautomaton_summary.wl"}];
materializedFile = FileNameJoin[{benchmarkRoot,
  "materializedwords" <> If[maximumWeight === Automatic, "",
    "-w" <> ToString[maximumWeight]] <> "_result.wl"}];
materializedSummaryFile = FileNameJoin[{benchmarkRoot,
  "materializedwords" <> If[maximumWeight === Automatic, "",
    "-w" <> ToString[maximumWeight]] <> "_summary.wl"}];
If[! And @@ (FileExistsQ /@ {operatorFile, operatorSummaryFile,
      materializedFile, materializedSummaryFile}),
  Exit[66]];

operator = Get[operatorFile];
materialized = Get[materializedFile];
operatorSummary = Get[operatorSummaryFile];
materializedSummary = Get[materializedSummaryFile];
If[! TrueQ[operatorSummary["CompactAccepted"]] ||
    ! TrueQ[materializedSummary["CompactAccepted"]] ||
    Lookup[operator, "BenchmarkRunID", None] =!=
      Lookup[operatorSummary, "BenchmarkRunID", Missing[]] ||
    Lookup[materialized, "BenchmarkRunID", None] =!=
      Lookup[materializedSummary, "BenchmarkRunID", Missing[]],
  Print["Benchmark result/summary pair is stale or rejected"];
  Exit[67]];
variables = operator["Variables"];
samples = Thread[variables -> #] & /@
  {{1/5, 2/7}, {2/9, 3/8}, {4/11, 5/13}};
gaugeRules = Lookup[operator, "GaugeConstantRules", {}];
equalAtSamples[a_, b_] := AllTrue[samples, Function[rules,
  aa = Flatten[Normal[a] /. gaugeRules /. rules];
  bb = Flatten[Normal[b] /. gaugeRules /. rules];
  Quiet[Check[Length[aa] === Length[bb] &&
    And @@ MapThread[TrueQ[#1 == #2] &, {aa, bb}], False]]]];

comparisons = Map[Function[item,
  word = FeynFacet`ObservableTransportWordMap[
    operator, item[[1]], item[[2]]];
  MemberQ[{"ExactWordMap", "ModularlyVerifiedWordMap"},
      Lookup[word, "Status", None]] &&
    equalAtSamples[item[[3]], word["Map"]]],
  materialized["TwoSegmentWordMaps"]];
summary = <|
  "Family" -> family,
  "MaximumWeight" -> maximumWeight,
  "MaterializedWordCount" -> Length[comparisons],
  "PassedWordCount" -> Count[comparisons, True],
  "AllPassed" -> comparisons =!= {} && And @@ comparisons|>;
Put[summary, FileNameJoin[{benchmarkRoot,
  "operator-vs-materialized-w" <> ToString[maximumWeight] <>
    "_verification.wl"}]];
Print[InputForm[summary]];
If[TrueQ[summary["AllPassed"]], Exit[0], Exit[1]];
