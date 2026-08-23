#!/usr/bin/env wolframscript

$HistoryLength = 0;
exchange = "/home/maxzhang/factorization-and-loops/External/CodexExchange/fable_maple_route_standardization_2026-08-18";
runDirectory = "/home/maxzhang/FACET/Codex/General/ToolStudy/CF48ResidueHandoff/full_20260818_2045";

Get["/home/maxzhang/FACET/Addon/Mathematica_Addon/CANONICA/src/CANONICA.m"];
CANONICA`$ComputeParallel = False;
CANONICA`Private`$ComputeParallel = False;
Get[FileNameJoin[{exchange, "BuildResidueCompatibility.wl"}]];

{e, c, bbar} = Get[FileNameJoin[{exchange,
  "CF48_strip_13_11_NextEquationD.wl"}]];
ee = Symbol["Global`eps"];
xx = Symbol["Global`x"];
yy = Symbol["Global`y"];

data = BuildResidueCompatibility[{e, c, bbar}, {xx, yy}, ee];
freeRules = Thread[data["FreeResidues"] -> 0];
K = data["ResidueMatrices"] /. freeRules;
dl = data["DLog"];
F = Map[Together, data["Forcing"] /. freeRules, {3}];

mapleLines = StringSplit[Import[FileNameJoin[{runDirectory,
  "sector_CF48_codex", "strip_13_11.out"}], "Text"], "\n"];
solution = ToExpression[
  StringReplace[mapleLines[[3]], {"[" -> "{", "]" -> "}"}]];
Dmatrix = ArrayReshape[solution, Dimensions[bbar[[1]]]];
variables = {xx, yy};

forcingDefinitionResidual = Table[
  Map[Together,
    F[[mu]] - (bbar[[mu]] - ee Sum[
      K[[a]] dl[[a, mu]], {a, Length[K]}]), {2}],
  {mu, 2}
];

odeResidual = Table[
  Map[Together,
    D[Dmatrix, variables[[mu]]] -
      ee (e[[mu]].Dmatrix - Dmatrix.c[[mu]]) - F[[mu]], {2}],
  {mu, 2}
];

transformedBlock = Table[
  Map[Together,
    bbar[[mu]] + ee (e[[mu]].Dmatrix - Dmatrix.c[[mu]]) -
      D[Dmatrix, variables[[mu]]], {2}],
  {mu, 2}
];
transformedResidual = Table[
  Map[Together,
    transformedBlock[[mu]] - ee Sum[
      K[[a]] dl[[a, mu]], {a, Length[K]}], {2}],
  {mu, 2}
];

zeroQ[expr_] := AllTrue[Flatten[expr], TrueQ[Together[#] === 0] &];
summary = <|
  "ForcingDefinitionZero" -> zeroQ[forcingDefinitionResidual],
  "MapleEquationZero" -> zeroQ[odeResidual],
  "TransformedDLogZero" -> zeroQ[transformedResidual],
  "ForcingDefinitionNonzeroCount" -> Count[Flatten[forcingDefinitionResidual], Except[0]],
  "MapleEquationNonzeroCount" -> Count[Flatten[odeResidual], Except[0]],
  "TransformedDLogNonzeroCount" -> Count[Flatten[transformedResidual], Except[0]]
|>;

Put[<|"Summary" -> summary,
  "ForcingDefinitionResidual" -> forcingDefinitionResidual,
  "MapleEquationResidual" -> odeResidual,
  "TransformedDLogResidual" -> transformedResidual|>,
  FileNameJoin[{exchange, "DiagnoseStrip1311MapleCheckResult.wl"}]];
Print[summary];
Exit[If[And @@ Take[Values[summary], 3], 0, 1]];
