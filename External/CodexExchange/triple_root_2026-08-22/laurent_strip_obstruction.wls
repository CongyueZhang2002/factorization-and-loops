#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
recordFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[recordFile];
epsilon = record["Regulator"];
bbar = record["Strip"][[3]];

polynomialOrder[0] := Infinity;
polynomialOrder[polynomial_] := Min[
  First /@ (First /@ CoefficientRules[Expand[polynomial], {epsilon}])];
rationalValuation[expression_] := Module[{q = Together[expression]},
  polynomialOrder[Numerator[q]] - polynomialOrder[Denominator[q]]];
minimumOrder = Min[rationalValuation /@ Flatten[bbar]];
scaledRecord = record;
scaledRecord["Strip"] = ReplacePart[record["Strip"],
  3 -> Map[Together[epsilon^(-minimumOrder) #1] &, bbar, {3}]];

{seconds, obstruction} = AbsoluteTiming[
  FeynFacet`EpsFormStripObstruction[scaledRecord,
    "MaximumOrder" -> 6,
    "Verbose" -> True]];
result = <|"Source" -> recordFile,
  "MinimumForcingOrder" -> minimumOrder,
  "Scale" -> epsilon^(-minimumOrder),
  "Seconds" -> seconds,
  "Result" -> obstruction|>;
temporary = outputFile <> ".tmp";
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];

Print["TRLAURENT order=", minimumOrder,
  " scale=", epsilon^(-minimumOrder),
  " obstruction=", If[AssociationQ[obstruction],
    InputForm[KeyTake[obstruction, {"Status", "Order", "MissingLetters",
      "Obstructions", "GaugeNumeratorDegrees"}]], Head[obstruction]],
  " seconds=", Round[seconds, 0.1]];
