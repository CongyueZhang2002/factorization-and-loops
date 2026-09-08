#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2, Exit[64]];
{materializedFile, compactFile} = ExpandFileName /@ arguments;
root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{bundle, "CodexProjectedTransportStandard.wl"}]];
readGlobal[file_] := Block[
  {$ContextPath = {"System`", "Global`"}, $Context = "Global`"}, Get[file]];
materialized = readGlobal[materializedFile];
compact = readGlobal[compactFile];

maps = materialized["TwoSegmentWordMaps"];
entry = SelectFirst[maps, #[[1]] === {} && #[[2]] === {3, 1} &];
prefix = SelectFirst[maps, #[[1]] === {} && #[[2]] === {3} &];
base = SelectFirst[maps, #[[1]] === {} && #[[2]] === {} &];
kernels = compact["CompactTransportAutomaton", "SecondKernelMatrices"];
reconstructed =
  CodexProjectedTransportStandard`CodexProjectedTransportWordMap[
    compact, {}, {3, 1}]["Map"];
rightRecurrence = prefix[[3]] . kernels[[1]];
reverseProduct = base[[3]] . kernels[[1]] . kernels[[3]];
sampleRules = {p -> 2/7, u -> 3/11, v -> 5/13, w -> 7/17,
  x -> 11/19, y -> 13/23, s -> 17/29};
sampleSameQ[a_, b_] := SameQ[Together[Normal[a] /. sampleRules],
  Together[Normal[b] /. sampleRules]];
zeroCount[a_, b_] := Count[
  Flatten[Together[Normal[a - b] /. sampleRules]],
  value_ /; ! TrueQ[value === 0]];

result = <|
  "ExpectedEqualsStoredPrefixTimesK1AtSample" ->
    sampleSameQ[entry[[3]], rightRecurrence],
  "ExpectedEqualsCompactEvaluatorAtSample" ->
    sampleSameQ[entry[[3]], reconstructed],
  "ExpectedEqualsReverseProductAtSample" ->
    sampleSameQ[entry[[3]], reverseProduct],
  "NonzeroResidualEntriesRightRecurrence" ->
    zeroCount[entry[[3]], rightRecurrence],
  "NonzeroResidualEntriesCompactEvaluator" ->
    zeroCount[entry[[3]], reconstructed],
  "NonzeroResidualEntriesReverseProduct" ->
    zeroCount[entry[[3]], reverseProduct]
|>;
Print[InputForm[result]];
