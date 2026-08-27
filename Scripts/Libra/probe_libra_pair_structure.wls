#!/usr/bin/env wolframscript
(* Compact Fuchsian diagnostics for one saved block pair. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
argv = Rest[$ScriptCommandLine];
family = argv[[1]];
directory = ExpandFileName[argv[[2]]];
bi = ToExpression[argv[[3]]];
bj = ToExpression[argv[[4]]];
Quiet[Block[{Print = (Null &)},
  Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra",
    "Source", "Libra.m"}]]], {General::shdw}];
Off[OptionValue::optnf];
Off[OptionValue::nodef];
record = Get[FileNameJoin[{directory,
  "family_epsform_" <> family <> ".wl"}]];
variables = record["Variables"];
ranges = record["Ranges"];
matrices = {record["EpsFormX"], record["EpsFormY"]};
ri = ranges[[bi]];
rj = ranges[[bj]];
idx = Join[ri, rj];

SetAttributes[timed, HoldAll];
timed[expression_, seconds_: 120] := Module[{time, value},
  {time, value} = AbsoluteTiming[
    TimeConstrained[CheckAbort[expression, "Aborted"],
      seconds, "TimedOut"]];
  <|"Value" -> value, "Seconds" -> time|>
];
summarizePoles[value_] := If[ListQ[value],
  <|"Count" -> Length[value], "Ranks" -> Counts[Last /@ value],
    "Positive" -> Select[value, Last[#] > 0 &]|>, value];
axisData[axis_] := Module[{matrix, variable, high, low, pair},
  matrix = matrices[[axis]];
  variable = variables[[axis]];
  high = matrix[[ri, ri]];
  low = matrix[[rj, rj]];
  pair = matrix[[idx, idx]];
  <|"Axis" -> axis, "Variable" -> variable,
    "HighFuchsian" -> timed[Libra`FuchsianQ[high, variable]],
    "LowFuchsian" -> timed[Libra`FuchsianQ[low, variable]],
    "PairFuchsian" -> timed[Libra`FuchsianQ[pair, variable]],
    "HighPoles" -> MapAt[summarizePoles, timed[Libra`PolesInfo[high, variable]], "Value"],
    "LowPoles" -> MapAt[summarizePoles, timed[Libra`PolesInfo[low, variable]], "Value"],
    "PairPoles" -> MapAt[summarizePoles, timed[Libra`PolesInfo[pair, variable]], "Value"]|>
];
output = <|"Family" -> family, "Pair" -> {bi, bj},
  "Dimensions" -> {Length[ri], Length[rj]},
  "Axes" -> {axisData[1], axisData[2]}|>;
Put[output, FileNameJoin[{directory,
  "pair_structure_" <> family <> "_" <> ToString[bi] <> "_" <>
    ToString[bj] <> ".wl"}]];
Print[InputForm[output]];
