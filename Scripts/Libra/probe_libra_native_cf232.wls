#!/usr/bin/env wolframscript
(* Read-only diagnosis of Libra's whole-matrix block inference on CF232. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
resultDirectory = "/home/maxzhang/FACET/Codex/General/LibraTwoRoot_20260819";
Quiet[Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra",
  "Source", "Libra.m"}]], {General::shdw}];
Off[OptionValue::optnf];
record = Get[FileNameJoin[{resultDirectory, "family_epsform_CF232.wl"}]];
{ax, ay} = Lookup[record, {"EpsFormX", "EpsFormY"}];
variables = record["Variables"];
ranges = record["Ranges"];

SetAttributes[timed, HoldAll];
timed[expression_, seconds_: 60] := Module[{time, value},
  {time, value} = AbsoluteTiming[
    CheckAbort[TimeConstrained[expression, seconds, "TimedOut"], "Aborted"]];
  <|"Value" -> value, "Seconds" -> time|>
];
zeroQ[entry_] := TrueQ[Together[entry] === 0];
structure[matrix_] := Map[Boole[! zeroQ[#]] &, matrix, {2}];
compact[result_] := ReplacePart[result, "Value" -> Which[
  MatrixQ[result["Value"]], <|"Head" -> Matrix,
    "Dimensions" -> Dimensions[result["Value"]]|>,
  True, result["Value"]]];

axisRecord[matrix_, variable_] := Module[
  {graph, inferred, offDiagonal, poles, diagonalChecks, fuchsify},
  graph = structure[matrix];
  inferred = timed[Libra`EntangledBlocksIndices[graph], 20];
  offDiagonal = timed[Libra`OffDiagonalBlocksIndices[graph, Sort -> Row], 20];
  poles = timed[Libra`PolesInfo[matrix, variable], 120];
  diagonalChecks = Table[<|
      "Block" -> i, "Range" -> ranges[[i]],
      "Rational" -> timed[Libra`RatFuncQ[
        matrix[[ranges[[i]], ranges[[i]]]], variable], 20],
      "Fuchsian" -> timed[Libra`FuchsianQ[
        matrix[[ranges[[i]], ranges[[i]]]], variable], 60]|>,
    {i, Length[ranges]}];
  fuchsify = timed[Libra`Fuchsify[matrix, variable, All,
    Monitor -> False, Simplify -> False], 60];
  <|
    "Variable" -> variable,
    "Rational" -> timed[Libra`RatFuncQ[matrix, variable], 60],
    "Fuchsian" -> timed[Libra`FuchsianQ[matrix, variable], 120],
    "InferredBlocks" -> inferred,
    "InferredOffDiagonalOrder" -> offDiagonal,
    "DeclaredDiagonalChecks" -> diagonalChecks,
    "PoleRanks" -> If[ListQ[poles["Value"]] && poles["Value"] =!= {},
      <|"Count" -> Length[poles["Value"]],
        "Counts" -> Counts[Last /@ poles["Value"]],
        "Maximum" -> Max[Last /@ poles["Value"]]|>, compact[poles]],
    "FuchsifyAll" -> compact[fuchsify]|>
];

output = <|"Family" -> "CF232", "Dimension" -> Length[ax],
  "DeclaredBlocks" -> ranges,
  "Axes" -> MapThread[axisRecord, {{ax, ay}, variables}]|>;
Put[output, FileNameJoin[{resultDirectory, "native_diagnostic_CF232.wl"}]];
Print[InputForm[output]];
