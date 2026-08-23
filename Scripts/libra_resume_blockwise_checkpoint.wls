#!/usr/bin/env wolframscript
(* Resume blockwise Fuchsification after an exact off-diagonal strip gauge. *)

$HistoryLength = 0;
root = ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]];
argv = Rest[$ScriptCommandLine];
If[Length[argv] < 4,
  Print["usage: libra_resume_blockwise_checkpoint.wls SOURCE CHECKPOINT STRIP_SOLUTION OUTPUT [BUDGET]"];
  Exit[2]];
sourceFile = ExpandFileName[argv[[1]]];
checkpointFile = ExpandFileName[argv[[2]]];
solutionFile = ExpandFileName[argv[[3]]];
outputFile = ExpandFileName[argv[[4]]];
budget = If[Length[argv] >= 5, ToExpression[argv[[5]]], 600];

readData[file_] := Block[{$Context = "FeynFacetResumeData`",
    $ContextPath = {"FeynFacetResumeData`", "System`"}}, Get[file]];
source = readData[sourceFile];
checkpoint = readData[checkpointFile];
solutionRecord = readData[solutionFile];
If[! And @@ (AssociationQ /@ {source, checkpoint, solutionRecord}), Exit[3]];

Quiet[Block[{Print = (Null &)},
  Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra",
    "Source", "Libra.m"}]]], {General::shdw}];
Off[OptionValue::optnf];
Off[OptionValue::nodef];

family = checkpoint["Family"];
If[source["Family"] =!= family || solutionRecord["Family"] =!= family,
  Print["family mismatch"]; Exit[4]];
{x1, x2} = checkpoint["Variables"];
epsilon = checkpoint["Regulator"];
ranges = checkpoint["Ranges"];
{bi, bj} = solutionRecord["Pair"];
solution = solutionRecord["Solution"];
solutionExact = AssociationQ[solution] &&
  TrueQ[Lookup[solution, "ExactDLog",
    TrueQ[Lookup[solution, "ODEEquationZero", False]] &&
     TrueQ[Lookup[solution, "TransformedDLogZero", False]]]];
If[! solutionExact ||
    ! MatrixQ[solution["Gauge"]],
  Print["strip solution is not an exactly checked gauge"]; Exit[5]];

baseX = source["EpsFormX"];
baseY = source["EpsFormY"];
ax = checkpoint["SystemX"];
ay = checkpoint["SystemY"];
total = checkpoint["Transformation"];
n = Length[ax];
numberOfBlocks = Length[ranges];
start = AbsoluteTime[];
steps = Lookup[checkpoint, "Steps", {}];
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
applyFull[transformation_] := Module[{inverse},
  If[! MatrixQ[transformation] || Dimensions[transformation] =!= {n, n},
    Return[False]];
  inverse = Map[Together, Inverse[transformation], {2}];
  If[! MatrixQ[inverse], Return[False]];
  ax = Map[Together,
    inverse . ax . transformation - inverse . D[transformation, x1], {2}];
  ay = Map[Together,
    inverse . ay . transformation - inverse . D[transformation, x2], {2}];
  total = Map[Together, total . transformation, {2}];
  True
];
applyLocal[raw_, indices_] := Module[{transformation = IdentityMatrix[n]},
  If[! MatrixQ[raw] || Dimensions[raw] =!= {Length[indices], Length[indices]},
    Return[False]];
  transformation[[indices, indices]] = raw;
  applyFull[transformation]
];
localComponents[i_, j_] := Module[{indices = Join[ranges[[i]], ranges[[j]]]},
  {ax[[indices, indices]], ay[[indices, indices]]}];
localFuchsianQ[i_, j_, axis_] := Module[{components, variable},
  components = localComponents[i, j];
  variable = {x1, x2}[[axis]];
  timed[Libra`FuchsianQ[components[[axis]], variable], 60]["Value"]
];

(* First certify the saved checkpoint against the original assembled family. *)
checkpointInverse = Quiet[Check[Map[Together, Inverse[total], {2}], $Failed]];
checkpointGauge = MatrixQ[checkpointInverse] && zeroQ[{
  checkpointInverse . baseX . total - checkpointInverse . D[total, x1] - ax,
  checkpointInverse . baseY . total - checkpointInverse . D[total, x2] - ay}];
If[! checkpointGauge, Print["checkpoint gauge identity failed"]; Exit[6]];

(* For A' = T^-1 A T - T^-1 dT, the strip equation solved by
   SolveResidueRationalGauge is embedded as T_(bi,bj) = D. *)
gauge = solution["Gauge"];
ri = ranges[[bi]];
rj = ranges[[bj]];
If[Dimensions[gauge] =!= {Length[ri], Length[rj]},
  Print["strip gauge dimensions do not match its blocks"]; Exit[7]];
stripTransformation = IdentityMatrix[n];
stripTransformation[[ri, rj]] = gauge;
If[! applyFull[stripTransformation],
  Print["strip transformation could not be applied"]; Exit[8]];
If[localFuchsianQ[bi, bj, 1] =!= True ||
   localFuchsianQ[bi, bj, 2] =!= True,
  Print["exact strip gauge did not make its two-variable connection Fuchsian"];
  Exit[9]];
AppendTo[steps, <|"Method" -> solution["Method"], "Pair" -> {bi, bj},
  "Result" -> "ExactDLogGauge", "Seconds" -> solutionRecord["Seconds"]|>];

pairs = Flatten[Table[
  If[i > j && nonzeroQ[{ax[[ranges[[i]], ranges[[j]]]],
      ay[[ranges[[i]], ranges[[j]]]]}], {{i, j}}, {}],
  {i, numberOfBlocks}, {j, numberOfBlocks}], 2];
axisOrder = {2, 1, 2, 1};

Do[
  If[failure =!= None, Break[]];
  {i, j} = pair;
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

inverse = Quiet[Check[Map[Together, Inverse[total], {2}], $Failed]];
checks = <|
  "FuchsianX" -> TrueQ[Libra`FuchsianQ[ax, x1]],
  "FuchsianY" -> TrueQ[Libra`FuchsianQ[ay, x2]],
  "Invertible" -> MatrixQ[inverse] && zeroQ[{
    total . inverse - IdentityMatrix[n], inverse . total - IdentityMatrix[n]}],
  "GaugeIdentity" -> MatrixQ[inverse] && zeroQ[{
    inverse . baseX . total - inverse . D[total, x1] - ax,
    inverse . baseY . total - inverse . D[total, x2] - ay}],
  "Flatness" -> zeroQ[D[ax, x2] - D[ay, x1] + ax . ay - ay . ax]|>;
accepted = failure === None && And @@ Values[checks];
output = <|"Family" -> family, "Variables" -> {x1, x2},
  "Regulator" -> epsilon, "Ranges" -> ranges, "Failure" -> failure,
  "Steps" -> steps, "Transformation" -> total,
  "SystemX" -> ax, "SystemY" -> ay, "Checks" -> checks,
  "Seconds" -> AbsoluteTime[] - start|>;
Put[output, outputFile];
Print[InputForm[KeyDrop[output, {"Transformation", "SystemX", "SystemY"}]]];
If[! accepted, Exit[1]];
