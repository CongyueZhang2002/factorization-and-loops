#!/usr/bin/env wolframscript
(* Read-only scan of individual CF232 block couplings in the saved chart. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
resultDirectory = "/home/maxzhang/FACET/Codex/General/LibraTwoRoot_20260819";

Quiet[Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra",
  "Source", "Libra.m"}]], {General::shdw}];
Off[OptionValue::optnf];

record = Get[FileNameJoin[{resultDirectory, "family_epsform_CF232.wl"}]];
{ax, ay} = Lookup[record, {"EpsFormX", "EpsFormY"}];
{x1, x2} = record["Variables"];
epsilon = record["Regulator"];
ranges = record["Ranges"];
reference = Unique["libraMu"];

SetAttributes[timed, HoldAll];
timed[expression_, seconds_: 60] := Module[{time, value},
  {time, value} = AbsoluteTiming[
    CheckAbort[TimeConstrained[expression, seconds, "TimedOut"], "Aborted"]];
  <|"Value" -> value, "Seconds" -> time|>
];
zeroQ[expression_] := AllTrue[Flatten[expression],
  TrueQ[Together[#] === 0] &];
epsilonFactoredQ[expression_] := AllTrue[Flatten[expression],
  TrueQ[Together[#] === 0] || FreeQ[Together[#/epsilon], epsilon] &];
summary[value_] := Which[
  MatrixQ[value], <|"Head" -> Matrix, "Dimensions" -> Dimensions[value],
    "Leaves" -> LeafCount[value]|>,
  MatchQ[value, {_List, _?MatrixQ, _List}],
    <|"Head" -> EquationSystem, "Equations" -> Length[value[[1]]],
      "Variables" -> Length[value[[3]]]|>,
  True, value];

pairRecord[i_, j_] := Module[
  {ri = ranges[[i]], rj = ranges[[j]], indices, px, py, fuchsian,
    poles},
  indices = Join[ri, rj];
  px = ax[[indices, indices]];
  py = ay[[indices, indices]];
  fuchsian = {
    timed[Libra`FuchsianQ[px, x1], 30],
    timed[Libra`FuchsianQ[py, x2], 30]};
  poles = If[And @@ (TrueQ[#1["Value"]] & /@ fuchsian),
    timed[{Libra`PolesInfo[px, x1], Libra`PolesInfo[py, x2]}, 30],
    "NotFuchsian"];
  <|
    "Pair" -> {i, j}, "Dimensions" -> {Length[ri], Length[rj]},
    "Distance" -> i - j,
    "NeedsReduction" -> ! epsilonFactoredQ[{ax[[ri, rj]], ay[[ri, rj]]}],
    "PairFuchsian" -> fuchsian,
    "PoleCounts" -> If[AssociationQ[poles] && ListQ[poles["Value"]],
      Append[KeyDrop[poles, "Value"],
        "Value" -> (Length /@ poles["Value"])], poles]|>
];

pairs = Flatten[Table[
  If[i > j && ! zeroQ[{ax[[ranges[[i]], ranges[[j]]]],
      ay[[ranges[[i]], ranges[[j]]]]}], {{i, j}}, {}],
  {i, Length[ranges]}, {j, Length[ranges]}], 2];
records = {};
Do[
  current = pairRecord @@ pair;
  AppendTo[records, current];
  output = <|"Family" -> "CF232", "Pairs" -> records|>;
  Put[output, FileNameJoin[{resultDirectory, "pair_scan_CF232.wl"}]];
  Print["pair ", pair, ": ", current["PairFuchsian"][[All, "Value"]]],
  {pair, pairs}];
Print[InputForm[output]];
