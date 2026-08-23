#!/usr/bin/env wolframscript

$HistoryLength = 0;
Get["/home/maxzhang/FACET/Addon/Mathematica_Addon/CANONICA/src/CANONICA.m"];
CANONICA`$ComputeParallel = False;
CANONICA`Private`$ComputeParallel = False;
Get["/home/maxzhang/factorization-and-loops/External/CodexExchange/fable_maple_route_standardization_2026-08-18/BuildResidueCompatibility.wl"];

equation = Get[
  "/home/maxzhang/FACET/Codex/General/ToolStudy/CF48Maple/CF48Sector13Strip4.wl"];
expected = Get[
  "/home/maxzhang/FACET/Codex/General/ToolStudy/CF48Maple/CF48Sector13Strip4Compatibility.wl"];

{e, c, bbar} = Take[equation, 3];
result = BuildResidueCompatibility[{e, c, bbar}, {p, s}, eps];

checks = <|
  "ReturnedAssociation" -> AssociationQ[result],
  "AlphabetExact" -> If[AssociationQ[result], result["Alphabet"] === expected["Alphabet"], False],
  "EquationCount" -> If[AssociationQ[result], result["EquationCount"] === 287, False],
  "ResidueVariableCount" -> If[AssociationQ[result], Length[result["ResidueVariables"]] === 48, False],
  "FixedResidueCount" -> If[AssociationQ[result], Length[result["ResidueRules"]] === 44, False],
  "FreeResidueCount" -> If[AssociationQ[result], Length[result["FreeResidues"]] === 4, False],
  "CompatibilityZero" -> If[AssociationQ[result], TrueQ[result["CompatibilityZero"]], False]
|>;

Put[<|"Checks" -> checks, "Measurements" -> If[AssociationQ[result],
  KeyTake[result, {"CompatibilitySeconds", "EquationSeconds", "SolveSeconds"}], <||>]|>,
  "/home/maxzhang/factorization-and-loops/External/CodexExchange/fable_maple_route_standardization_2026-08-18/TestKnownStrip139Result.wl"];
Print[checks];
Exit[If[And @@ Values[checks], 0, 1]];

