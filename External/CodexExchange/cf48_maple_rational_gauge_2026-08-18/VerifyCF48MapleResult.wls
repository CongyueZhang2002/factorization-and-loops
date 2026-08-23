#!/usr/bin/env wolframscript

$HistoryLength = 0;

outputDirectory =
  "/home/maxzhang/FACET/Codex/General/ToolStudy/CF48Maple";
prepared = Get[FileNameJoin[
  {outputDirectory, "CF48Sector13Strip4PreparedSystem.wl"}]];
equation = Get[FileNameJoin[
  {outputDirectory, "CF48Sector13Strip4.wl"}]];
mapleText = StringTrim@Import[FileNameJoin[
  {outputDirectory, "CF48Sector13Strip4RationalGauge.maple.txt"}], "Text"];

solution = ToExpression@StringReplace[mapleText, {
  "[" -> "{", "]" -> "}"}];
connection = prepared["Connection"];
rhs = prepared["RightHandSide"];

residualP = Map[Cancel@Together[#] &,
  D[solution, p] - connection[[1]].solution - rhs[[1]]];
residualS = Map[Cancel@Together[#] &,
  D[solution, s] - connection[[2]].solution - rhs[[2]]];

If[! And @@ (PossibleZeroQ /@ Join[residualP, residualS]),
  Print["Imported Maple solution has a nonzero exact residual."];
  Exit[1]];

gaugeMatrix = Partition[solution, 2];
{e, c, b} = Take[equation, 3];
target = Table[
  Sum[prepared["Residues"][[a]]
      D[Log[prepared["Alphabet"][[a]]], {p, s}[[mu]]],
    {a, Length[prepared["Alphabet"]]}],
  {mu, 2}];
transformedOffDiagonal = Table[
  b[[mu]] + eps (e[[mu]].gaugeMatrix - gaugeMatrix.c[[mu]]) -
    D[gaugeMatrix, {p, s}[[mu]]],
  {mu, 2}];
gaugeResidual = Map[Cancel@Together[#] &,
  transformedOffDiagonal - eps target, {3}];

If[! And @@ Flatten[Map[PossibleZeroQ, gaugeResidual, {3}]],
  Print["The transformed off-diagonal block is not in epsilon form."];
  Exit[1]];

result = <|
  "GaugeMatrix" -> gaugeMatrix,
  "GaugeVector" -> solution,
  "CanonicalOffDiagonal" -> eps target,
  "GaugeResidual" -> gaugeResidual,
  "ResidualP" -> residualP,
  "ResidualS" -> residualS,
  "FreeResiduesFixedToZero" -> prepared["FreeResiduesFixedToZero"]
|>;

Put[result, FileNameJoin[
  {outputDirectory, "CF48Sector13Strip4RationalGauge.wl"}]];

Print["Exact Mathematica residuals: p -> ", residualP,
  "; s -> ", residualS];
Print["Exact epsilon-form gauge residual: ", gaugeResidual];
Print["Gauge matrix bytes: ", ByteCount[result["GaugeMatrix"]]];
