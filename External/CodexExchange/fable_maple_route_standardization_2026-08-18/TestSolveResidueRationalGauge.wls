#!/usr/bin/env wolframscript

$HistoryLength = 0;
exchange = "/home/maxzhang/factorization-and-loops/External/CodexExchange/fable_maple_route_standardization_2026-08-18";
scratch = "/home/maxzhang/FACET/Codex/General/ToolStudy/CF48ResidueHandoff/reusable_solver_test";
If[! DirectoryQ[scratch], CreateDirectory[scratch, CreateIntermediateDirectories -> True]];

Get["/home/maxzhang/FACET/Addon/Mathematica_Addon/CANONICA/src/CANONICA.m"];
CANONICA`$ComputeParallel = False;
CANONICA`Private`$ComputeParallel = False;
Get[FileNameJoin[{exchange, "BuildResidueCompatibility.wl"}]];
Get[FileNameJoin[{exchange, "SolveResidueRationalGauge.wl"}]];

ee = Symbol["Global`eps"];
xx = Symbol["Global`x"];
yy = Symbol["Global`y"];
mapleLibrary = "/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections";

results = Association@Table[
  input = Get[FileNameJoin[{exchange,
    "CF48_strip_13_" <> ToString[lower] <> "_NextEquationD.wl"}]];
  lower -> SolveResidueRationalGauge[input, {xx, yy}, ee,
    "MapleLibrary" -> mapleLibrary,
    "ScratchDirectory" -> scratch,
    "Tag" -> "strip_13_" <> ToString[lower],
    "TimeLimit" -> 300,
    "Verbose" -> True],
  {lower, {11, 10}}];

summary = Association@KeyValueMap[#1 -> If[AssociationQ[#2],
  KeyTake[#2, {"ResidueRules", "ParameterEquationCount",
    "FirstVariable", "MapleSeconds", "ODEEquationZero",
    "TransformedDLogZero"}], #2] &, results];
Put[results, FileNameJoin[{exchange,
  "TestSolveResidueRationalGaugeResult.wl"}]];
Print[summary];
Exit[If[AllTrue[Values[results], AssociationQ], 0, 1]];
