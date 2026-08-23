#!/usr/bin/env wolframscript
(* Probe Libra on one certified off-diagonal block of a saved family. *)

$HistoryLength = 0;
root = ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]];
argv = Rest[$ScriptCommandLine];
If[Length[argv] < 5,
  Print["usage: probe_libra_saved_pair.wls FAMILY RESULT_DIRECTORY I J BUDGET [MODE]"];
  Exit[2]];
family = argv[[1]];
resultDirectory = ExpandFileName[argv[[2]]];
bi = ToExpression[argv[[3]]];
bj = ToExpression[argv[[4]]];
budget = ToExpression[argv[[5]]];
mode = If[Length[argv] >= 6, argv[[6]], "Automatic"];
factorOptions = Switch[mode,
  "AllNoSort", {DependentRowIndices -> All, Sort -> False},
  "AllSort", {DependentRowIndices -> All, Sort -> True},
  "JointAllNoSort", {DependentRowIndices -> All, Sort -> False},
  "JointAutoNoSort", {DependentRowIndices -> Automatic, Sort -> False},
  _, {DependentRowIndices -> Automatic, Sort -> True}];

Quiet[Block[{Print = (Null &)},
  Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra",
    "Source", "Libra.m"}]]], {General::shdw}];
Off[OptionValue::optnf];
Off[OptionValue::nodef];
record = Get[FileNameJoin[{resultDirectory,
  "family_epsform_" <> family <> ".wl"}]];
{x1, x2} = record["Variables"];
epsilon = record["Regulator"];
ranges = record["Ranges"];
ri = ranges[[bi]];
rj = ranges[[bj]];
di = Length[ri];
dj = Length[rj];
idx = Join[ri, rj];
ax0 = record["EpsFormX"][[idx, idx]];
ay0 = record["EpsFormY"][[idx, idx]];
ax = ax0;
ay = ay0;
total = IdentityMatrix[di + dj];
reference = Unique["libraMu"];

SetAttributes[timed, HoldAll];
timed[expression_, seconds_] := Module[{time, value},
  {time, value} = AbsoluteTiming[
    TimeConstrained[expression, seconds, "TimedOut"]];
  <|"Value" -> value, "Seconds" -> time|>
];
zeroQ[expression_] := AllTrue[Flatten[expression],
  TrueQ[Together[#] === 0] &];
epsilonFactoredQ[expression_] := AllTrue[Flatten[expression],
  TrueQ[Together[#] === 0] || FreeQ[Together[#/epsilon], epsilon] &];
blockDiagonal[a_, b_] := ArrayFlatten[{{a,
  ConstantArray[0, {Length[a], Length[b]}]},
  {ConstantArray[0, {Length[b], Length[a]}], b}}];
specialize[transformation_] := Module[{constants},
  constants = DeleteDuplicates[Cases[transformation, _C, Infinity]];
  Map[Together,
    transformation /. Thread[constants -> Range[Length[constants]]] /.
      reference -> 1, {2}]
];
unitUpper[transformation_] := Module[{t, a, b, c, lower, normalized},
  t = specialize[transformation];
  a = t[[1 ;; di, 1 ;; di]];
  b = t[[1 ;; di, di + 1 ;; di + dj]];
  lower = t[[di + 1 ;; di + dj, 1 ;; di]];
  c = t[[di + 1 ;; di + dj, di + 1 ;; di + dj]];
  If[! zeroQ[lower], Return[$Failed]];
  If[! FreeQ[{a, c}, x1 | x2], Return[$Failed]];
  normalized = Map[Together,
    t . blockDiagonal[Inverse[a], Inverse[c]], {2}];
  If[! zeroQ[normalized[[1 ;; di, 1 ;; di]] - IdentityMatrix[di]] ||
     ! zeroQ[normalized[[di + 1 ;; di + dj, di + 1 ;; di + dj]] -
       IdentityMatrix[dj]] ||
     ! zeroQ[normalized[[di + 1 ;; di + dj, 1 ;; di]]],
    Return[$Failed]];
  normalized
];
applyTransformation[raw_] := Module[{t, inverse},
  t = unitUpper[raw];
  If[! MatrixQ[t], Return[False]];
  inverse = Map[Together, Inverse[t], {2}];
  ax = Map[Together, inverse . ax . t - inverse . D[t, x1], {2}];
  ay = Map[Together, inverse . ay . t - inverse . D[t, x2], {2}];
  total = Map[Together, total . t, {2}];
  True
];
applyDirectTransformation[raw_] := Module[{t, inverse},
  t = specialize[raw];
  If[! MatrixQ[t], Return[False]];
  inverse = Map[Together, Inverse[t], {2}];
  ax = Map[Together, inverse . ax . t - inverse . D[t, x1], {2}];
  ay = Map[Together, inverse . ay . t - inverse . D[t, x2], {2}];
  total = Map[Together, total . t, {2}];
  True
];

steps = {};
Do[
  variable = {x1, x2}[[axis]];
  component := If[axis === 1, ax, ay];
  fuchsian = timed[Libra`FuchsianQ[component, variable], 60];
  AppendTo[steps, <|"Method" -> "FuchsianQ", "Axis" -> axis,
    "Result" -> fuchsian|>];
  If[fuchsian["Value"] =!= True,
    transformed = timed[
      Libra`FuchsifyBlock[component, variable,
        {Range[di], Range[di + 1, di + dj]}, All,
        Monitor -> False], budget];
    AppendTo[steps, <|"Method" -> "FuchsifyBlock", "Axis" -> axis,
      "Result" -> If[MatrixQ[transformed["Value"]], "Matrix",
        transformed["Value"]], "Seconds" -> transformed["Seconds"]|>];
    If[MatrixQ[transformed["Value"]],
      applyTransformation[transformed["Value"]]]],
  {axis, 2}];

rawTransformation = None;
If[StringStartsQ[mode, "Joint"],
  residueFile = FileNameJoin[{resultDirectory,
    "pair_residues_" <> family <> "_" <> ToString[bi] <> "_" <>
      ToString[bj] <> ".wl"}];
  residues = If[FileExistsQ[residueFile], Get[residueFile],
    value = Join[
      (Libra`LeadingSeriesCoefficient[ax/epsilon, {x1, #1, 0}] & @@@
        Libra`PolesInfo[ax, x1]),
      (Libra`LeadingSeriesCoefficient[ay/epsilon, {x2, #1, 0}] & @@@
        Libra`PolesInfo[ay, x2])];
    Put[value, residueFile]; value];
  transformed = timed[
    Libra`FactorDependence[residues, epsilon, reference,
      Sequence @@ factorOptions], budget];
  rawTransformation = transformed["Value"];
  AppendTo[steps, <|"Method" -> "FactorDependence", "Axis" -> "Both",
    "Mode" -> mode,
    "Result" -> If[MatrixQ[transformed["Value"]], "Matrix",
      transformed["Value"]], "Seconds" -> transformed["Seconds"]|>];
  If[MatrixQ[transformed["Value"]],
    applyDirectTransformation[transformed["Value"]]]];

factorOrder = {2, 1, 2, 1, 2, 1, 2, 1};
If[! StringStartsQ[mode, "Joint"], Do[
  If[epsilonFactoredQ[ax] && epsilonFactoredQ[ay], Break[]];
  axis = factorOrder[[round]];
  variable = {x1, x2}[[axis]];
  component = If[axis === 1, ax, ay];
  If[! epsilonFactoredQ[component],
    transformed = timed[
      Libra`FactorOut[component, variable, epsilon, reference,
        Sequence @@ factorOptions], budget];
    AppendTo[steps, <|"Method" -> "FactorOut", "Axis" -> axis,
      "Mode" -> mode,
      "Result" -> If[MatrixQ[transformed["Value"]], "Matrix",
        transformed["Value"]], "Seconds" -> transformed["Seconds"]|>];
    If[MatrixQ[transformed["Value"]],
      applyTransformation[transformed["Value"]]]],
  {round, Length[factorOrder]}]];

inverse = Map[Together, Inverse[total], {2}];
checks = <|
  "EpsFactored" -> (epsilonFactoredQ[ax] && epsilonFactoredQ[ay]),
  "Invertible" -> zeroQ[{total . inverse - IdentityMatrix[Length[total]],
    inverse . total - IdentityMatrix[Length[total]]}],
  "GaugeIdentity" -> zeroQ[{
    inverse . ax0 . total - inverse . D[total, x1] - ax,
    inverse . ay0 . total - inverse . D[total, x2] - ay}],
  "Flatness" -> zeroQ[D[ax, x2] - D[ay, x1] + ax . ay - ay . ax]|>;
output = <|"Family" -> family, "Pair" -> {bi, bj},
  "Dimensions" -> {di, dj}, "Steps" -> steps, "Checks" -> checks,
  "RawTransformation" -> rawTransformation,
  "Transformation" -> total, "EpsFormX" -> ax, "EpsFormY" -> ay|>;
Put[output, FileNameJoin[{resultDirectory,
  "pair_probe_" <> family <> "_" <> ToString[bi] <> "_" <>
    ToString[bj] <> ".wl"}]];
Print[InputForm[KeyDrop[output,
  {"RawTransformation", "Transformation", "EpsFormX", "EpsFormY"}]]];
If[! And @@ Values[checks], Exit[1]];
