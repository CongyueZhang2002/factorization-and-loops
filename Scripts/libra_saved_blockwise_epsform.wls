#!/usr/bin/env wolframscript
(* Complete a saved block-triangular family with Libra block by block. *)

$HistoryLength = 0;
root = ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]];
argv = Rest[$ScriptCommandLine];
If[Length[argv] < 3,
  Print["usage: libra_saved_blockwise_epsform.wls FAMILY INPUT_DIRECTORY OUTPUT_DIRECTORY [BUDGET] [MODE]"];
  Exit[2]];
family = argv[[1]];
inputDirectory = ExpandFileName[argv[[2]]];
outputDirectory = ExpandFileName[argv[[3]]];
budget = If[Length[argv] >= 4, ToExpression[argv[[4]]], 600];
mode = If[Length[argv] >= 5, argv[[5]], "Complete"];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

Quiet[Block[{Print = (Null &)},
  Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra",
    "Source", "Libra.m"}]]], {General::shdw}];
Off[OptionValue::optnf];
Off[OptionValue::nodef];
record = Get[FileNameJoin[{inputDirectory,
  "family_epsform_" <> family <> ".wl"}]];
{x1, x2} = record["Variables"];
epsilon = record["Regulator"];
ranges = record["Ranges"];
ax0 = record["EpsFormX"];
ay0 = record["EpsFormY"];
ax = ax0;
ay = ay0;
n = Length[ax];
numberOfBlocks = Length[ranges];
total = IdentityMatrix[n];
reference = Unique["libraMu"];
start = AbsoluteTime[];
steps = {};
failure = None;

SetAttributes[timed, HoldAll];
timed[expression_, seconds_] := Module[{time, value},
  {time, value} = AbsoluteTiming[
    TimeConstrained[CheckAbort[expression, "Aborted"],
      seconds, "TimedOut"]];
  <|"Value" -> value, "Seconds" -> time|>
];
zeroQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#] === 0] &];
nonzeroQ[expression_] := AnyTrue[Flatten[{expression}],
  ! TrueQ[# === 0] &];
epsilonFactoredQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#] === 0] || FreeQ[Together[#/epsilon], epsilon] &];
specialize[transformation_] := Module[{constants, candidates, result},
  constants = DeleteDuplicates[Cases[transformation, _C, Infinity]];
  candidates = If[constants === {}, {{}},
    {Thread[constants -> Range[Length[constants]]],
     Thread[constants -> Prime[Range[Length[constants]]]],
     Thread[constants -> (Range[Length[constants]] + 1)]}];
  result = SelectFirst[
    (Map[Together, transformation /. # /. reference -> 1, {2}] &) /@
      candidates,
    MatrixQ[#] && ! TrueQ[Together[Det[#]] === 0] &, $Failed];
  result
];
applyFull[raw_] := Module[{transformation, inverse},
  transformation = specialize[raw];
  If[! MatrixQ[transformation] || Dimensions[transformation] =!= {n, n},
    Return[False]];
  inverse = Map[Together, Inverse[transformation], {2}];
  ax = Map[Together,
    inverse . ax . transformation - inverse . D[transformation, x1], {2}];
  ay = Map[Together,
    inverse . ay . transformation - inverse . D[transformation, x2], {2}];
  total = Map[Together, total . transformation, {2}];
  True
];
applyLocal[raw_, indices_] := Module[{local, transformation},
  local = specialize[raw];
  If[! MatrixQ[local] || Dimensions[local] =!= {Length[indices], Length[indices]},
    Return[False]];
  transformation = IdentityMatrix[n];
  transformation[[indices, indices]] = local;
  applyFull[transformation]
];
localComponents[i_, j_] := Module[{indices = Join[ranges[[i]], ranges[[j]]]},
  {ax[[indices, indices]], ay[[indices, indices]]}];
localFuchsianQ[i_, j_, axis_] := Module[{components, variable},
  components = localComponents[i, j];
  variable = {x1, x2}[[axis]];
  timed[Libra`FuchsianQ[components[[axis]], variable], 60]["Value"]];

pairs = Flatten[Table[
  If[i > j && nonzeroQ[{ax[[ranges[[i]], ranges[[j]]]],
      ay[[ranges[[i]], ranges[[j]]]]}], {{i, j}}, {}],
  {i, numberOfBlocks}, {j, numberOfBlocks}], 2];
axisOrder = {2, 1, 2, 1};

Do[
  If[failure =!= None, Break[]];
  {i, j} = pair;
  Print["[blockwise] pair ", pair];
  indices = Join[ranges[[i]], ranges[[j]]];
  di = Length[ranges[[i]]];
  dj = Length[ranges[[j]]];
  Do[
    If[localFuchsianQ[i, j, 1] === True &&
       localFuchsianQ[i, j, 2] === True, Break[]];
    axis = axisOrder[[round]];
    If[localFuchsianQ[i, j, axis] =!= True,
      components = localComponents[i, j];
      variable = {x1, x2}[[axis]];
      transformed = timed[
        Libra`FuchsifyBlock[components[[axis]], variable,
          {Range[di], Range[di + 1, di + dj]}, All,
          Monitor -> False], budget];
      AppendTo[steps, <|"Method" -> "FuchsifyBlock", "Pair" -> pair,
        "Axis" -> axis, "Seconds" -> transformed["Seconds"],
        "Result" -> If[MatrixQ[transformed["Value"]], "Matrix",
          transformed["Value"]]|>];
      If[MatrixQ[transformed["Value"]],
        If[! applyLocal[transformed["Value"], indices],
          failure = <|"Pair" -> pair, "Axis" -> axis,
            "Reason" -> "TransformationRefused"|>],
        failure = <|"Pair" -> pair, "Axis" -> axis,
          "Reason" -> transformed["Value"]|>]],
    {round, Length[axisOrder]}];
  If[failure === None &&
     !(localFuchsianQ[i, j, 1] === True &&
       localFuchsianQ[i, j, 2] === True),
    failure = <|"Pair" -> pair, "Reason" -> "NotFuchsianAfterRounds"|>],
  {pair, SortBy[pairs, {Subtract @@ # &, First, Last}]}];

localFile = FileNameJoin[{outputDirectory,
  "blockwise_local_" <> family <> ".wl"}];
Put[<|"Family" -> family, "Variables" -> {x1, x2},
  "Regulator" -> epsilon, "Ranges" -> ranges, "Failure" -> failure,
  "Steps" -> steps, "Transformation" -> total,
  "SystemX" -> ax, "SystemY" -> ay|>, localFile];
Print["[blockwise] local transformations complete; checkpoint: ", localFile];
If[mode === "LocalOnly", Exit[If[failure === None, 0, 1]]];

If[failure === None,
  Print["[blockwise] checking the complete Fuchsian system"];
  fullFuchsian = {
    timed[Libra`FuchsianQ[ax, x1], budget],
    timed[Libra`FuchsianQ[ay, x2], budget]};
  If[! AllTrue[fullFuchsian, TrueQ[#["Value"]] &],
    failure = <|"Reason" -> "FullSystemNotFuchsian",
      "Results" -> fullFuchsian|>]];

If[failure === None,
  Print["[blockwise] collecting residues"];
  residueFile = FileNameJoin[{outputDirectory,
    "blockwise_residues_" <> family <> ".wl"}];
  residues = If[FileExistsQ[residueFile], Get[residueFile],
    value = Join[
      (Libra`LeadingSeriesCoefficient[ax/epsilon, {x1, #1, 0}] & @@@
        Libra`PolesInfo[ax, x1]),
      (Libra`LeadingSeriesCoefficient[ay/epsilon, {x2, #1, 0}] & @@@
        Libra`PolesInfo[ay, x2])];
    Put[value, residueFile]; value];
  Print["[blockwise] solving the joint regulator-factorization system"];
  transformed = timed[
    Libra`FactorDependence[residues, epsilon, reference,
      DependentRowIndices -> Automatic, Sort -> True], budget];
  AppendTo[steps, <|"Method" -> "FactorDependence", "Axis" -> "Both",
    "Seconds" -> transformed["Seconds"],
    "Result" -> If[MatrixQ[transformed["Value"]], "Matrix",
      transformed["Value"]]|>];
  If[MatrixQ[transformed["Value"]],
    If[! applyFull[transformed["Value"]],
      failure = <|"Reason" -> "FactorTransformationRefused"|>],
    failure = <|"Reason" -> transformed["Value"]|>]];

inverse = Quiet[Check[Map[Together, Inverse[total], {2}], $Failed]];
Print["[blockwise] checking the complete transformed family"];
checks = <|
  "EpsFactored" -> (epsilonFactoredQ[ax] && epsilonFactoredQ[ay]),
  "Fuchsian" -> If[failure === None,
    TrueQ[timed[Libra`FuchsianQ[ax, x1], budget]["Value"]] &&
      TrueQ[timed[Libra`FuchsianQ[ay, x2], budget]["Value"]], False],
  "BlockLowerTriangular" -> AllTrue[Flatten[Table[
    If[j > i, {ax[[ranges[[i]], ranges[[j]]]],
      ay[[ranges[[i]], ranges[[j]]]]}, {}],
    {i, numberOfBlocks}, {j, numberOfBlocks}]],
    TrueQ[# === 0] &],
  "Invertible" -> MatrixQ[inverse] &&
    zeroQ[{total . inverse - IdentityMatrix[n],
      inverse . total - IdentityMatrix[n]}],
  "GaugeIdentity" -> MatrixQ[inverse] && zeroQ[{
    inverse . ax0 . total - inverse . D[total, x1] - ax,
    inverse . ay0 . total - inverse . D[total, x2] - ay}],
  "Flatness" -> zeroQ[D[ax, x2] - D[ay, x1] + ax . ay - ay . ax]|>;
accepted = failure === None && And @@ Values[checks];
output = <|"Status" -> If[accepted, "EpsForm", "NotEpsForm"],
  "Family" -> family, "Variables" -> {x1, x2},
  "Regulator" -> epsilon, "Ranges" -> ranges, "Pairs" -> pairs,
  "Failure" -> failure, "Steps" -> steps, "Checks" -> checks,
  "Transformation" -> total, "EpsFormX" -> ax, "EpsFormY" -> ay,
  "Seconds" -> AbsoluteTime[] - start|>;
Put[output, FileNameJoin[{outputDirectory,
  "blockwise_epsform_" <> family <> ".wl"}]];
Print[InputForm[KeyDrop[output,
  {"Transformation", "EpsFormX", "EpsFormY"}]]];
If[! accepted, Exit[1]];
