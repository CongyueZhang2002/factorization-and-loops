#!/usr/bin/env wolframscript

$HistoryLength = 0;

root = "/home/maxzhang/factorization-and-loops";
bundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_round2_2026-08-21"}];
Get[FileNameJoin[{bundle, "CodexA2IncrementalRegulatorPrototype.wl"}]];

reference = Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "BenchmarkStripBackends", "frozen_M0",
  "m1_run", "ff_artifacts_M1_CF254_9_6_000055",
  "finite_field_strip_mod_1000003.wl"}]];
samples = CodexA2SamplesFromInterpolation[reference,
  Take[(#/(# + 20)) & /@ Range[32], 16]];
data = Table[{samples[[index, "EpsilonMod"]],
  samples[[index, "Values", 1]]}, {index, 4}];

Print["data = ", InputForm[data]];
Print["reference degrees = ",
  InputForm[reference["Interpolations"][[1, "Degrees"]]]];
Do[
  Print["split ", numeratorDegree, "/", 3 - numeratorDegree,
    " -> ", InputForm[CodexA2FitSplit[data, 1000003,
      numeratorDegree, 3 - numeratorDegree]]],
  {numeratorDegree, 0, 3}];
Print["candidates -> ",
  InputForm[CodexA2FitCoordinateCandidates[data, 1000003, 22]]];

