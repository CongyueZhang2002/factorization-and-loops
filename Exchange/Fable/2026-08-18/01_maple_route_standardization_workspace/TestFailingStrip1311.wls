#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{root, "External", "CodexExchange",
  "fable_maple_route_standardization_2026-08-18"}];

Get["/home/maxzhang/FACET/Addon/Mathematica_Addon/CANONICA/src/CANONICA.m"];
CANONICA`$ComputeParallel = False;
CANONICA`Private`$ComputeParallel = False;
Get[FileNameJoin[{exchange, "BuildResidueCompatibility.wl"}]];

resolve[name_String] := Module[
  {public = ToExpression["CANONICA`" <> name],
   private = ToExpression["CANONICA`Private`" <> name]},
  Which[
   DownValues[Evaluate[public]] =!= {}, public,
   DownValues[Evaluate[private]] =!= {}, private,
   True, Print["Undefined CANONICA function: ", name]; Exit[2]
  ]
];

calculateNext = resolve["CalculateNextSubsectorD"];
nextEquation = resolve["NextEquationD"];

state = Get[FileNameJoin[{exchange, "CF48_sector_state_after_sector12.wl"}]];
bounds = {{1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 6}, {7, 8}, {9, 9},
  {10, 10}, {11, 12}, {13, 14}, {15, 15}, {16, 16}, {17, 18},
  {19, 19}, {20, 20}, {21, 21}, {22, 22}, {23, 24}, {25, 25},
  {26, 27}};

globalEpsilon = Symbol["Global`eps"];
globalX = Symbol["Global`x"];
globalY = Symbol["Global`y"];
toCanonica[expr_] := expr /. globalEpsilon -> CANONICA`eps;
fromCanonica[expr_] := expr /. CANONICA`eps -> globalEpsilon;

a = toCanonica[Table[
  state["A"][[mu, 1 ;; 18, 1 ;; 18]], {mu, 2}]];
sectorBounds = bounds[[1 ;; 13]];
previousD = Table[{}, {2}];

step = calculateNext[a, {globalX, globalY}, sectorBounds, previousD,
  CANONICA`VerbosityLevel -> 0];
If[! ListQ[step] || Length[step] =!= 2 || Length[step[[1]]] =!= 1,
  Print["The known strip (13,12) did not widen previousD from 0 to 1."];
  Exit[3]
];
previousD = step;

next = nextEquation[a, {globalX, globalY}, sectorBounds, previousD];
If[! ListQ[next] || Length[next] < 5 || next[[1]] === False || next[[5]] =!= 11,
  Print["Could not reconstruct the requested strip (13,11): ",
    If[ListQ[next] && Length[next] >= 5, next[[5]], next]];
  Exit[4]
];

{e, c, bbar} = fromCanonica /@ Take[next, 3];
Put[{e, c, bbar}, FileNameJoin[{exchange, "CF48_strip_13_11_NextEquationD.wl"}]];

result = BuildResidueCompatibility[
  {e, c, bbar}, {globalX, globalY}, globalEpsilon];
checks = <|
  "RequestedStrip" -> (next[[5]] === 11),
  "ReturnedAssociation" -> AssociationQ[result],
  "NonemptyAlphabet" -> If[AssociationQ[result], Length[result["Alphabet"]] > 0, False],
  "NonemptyResidueSolution" -> If[AssociationQ[result], Length[result["ResidueRules"]] > 0, False],
  "CompatibilityZero" -> If[AssociationQ[result], TrueQ[result["CompatibilityZero"]], False]
|>;

summary = <|
  "Strip" -> {13, 11},
  "Checks" -> checks,
  "Alphabet" -> If[AssociationQ[result], result["Alphabet"], Missing["NotAvailable"]],
  "EquationCount" -> If[AssociationQ[result], result["EquationCount"], Missing["NotAvailable"]],
  "ResidueVariableCount" -> If[AssociationQ[result], Length[result["ResidueVariables"]], Missing["NotAvailable"]],
  "FixedResidueCount" -> If[AssociationQ[result], Length[result["ResidueRules"]], Missing["NotAvailable"]],
  "FreeResidueCount" -> If[AssociationQ[result], Length[result["FreeResidues"]], Missing["NotAvailable"]],
  "Measurements" -> If[AssociationQ[result],
    KeyTake[result, {"CompatibilitySeconds", "EquationSeconds", "SolveSeconds"}], <||>]
|>;
Put[summary, FileNameJoin[{exchange, "TestFailingStrip1311Result.wl"}]];
If[AssociationQ[result],
  Put[KeyTake[result, {"Alphabet", "ResidueMatrices", "ResidueRules",
     "FreeResidues", "DLog", "Forcing", "CompatibilityZero"}],
    FileNameJoin[{exchange, "CF48_strip_13_11_residue_compatibility.wl"}]]
];
Print[summary];
Exit[If[And @@ Cases[Values[checks], _?BooleanQ], 0, 1]];

