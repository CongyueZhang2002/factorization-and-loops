#!/usr/bin/env wolframscript

(* Reconstruct the fixed-core RHS from 42 direct modular samples and expand it
   about epsilon=1 for the native Taylor/Dixon recurrence. *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
args = Rest[$ScriptCommandLine];
mode = If[Length[args] >= 1, args[[1]], "downward"];
order = If[Length[args] >= 2, ToExpression[args[[2]]], 2048];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
runtime = FileNameJoin[{codexRoot, "Runtime", Switch[mode,
  "downward", "2026-08-31_cf259_downward_taylor_core",
  "shell3", "2026-08-31_cf259_shell3_stacked_taylor_core",
  _, Print["unknown mode: ", mode]; Exit[64]]}];
rhsDirectory = If[mode === "shell3", FileNameJoin[{runtime, "rhs_images"}],
  FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_downward_taylor_rhs_images_fixedcore"}]];
expectedStatus = If[mode === "shell3",
  "CF259Shell3StackedRHSImageV1", "CF259DownwardRHSImageV1"];
core = Get[FileNameJoin[{runtime, "core_report.wl"}]];
files = Sort[FileNames["rhs_*.wl", rhsDirectory]];
images = Get /@ files;
prime = core["Prime"];
n = core["CoreDimension"];
If[Length[images] =!= 42 || ! AllTrue[images,
    AssociationQ[#] && Lookup[#, "Status", None] ===
      expectedStatus && Lookup[#, "Prime", None] === prime &&
      Length[Lookup[#, "Values", {}]] === n &],
  Print["incomplete or invalid RHS image collection"]; Exit[1]];

knownChecks = Missing["PendingInterpolation"];
canonical = (<|"EpsilonValue" -> #["RegulatorValue"],
    "EpsilonMod" -> #["EpsilonMod"], "Values" -> #["Values"]|> &) /@
  images;
{interpolationSeconds, interpolation} = AbsoluteTiming[
  FeynFacet`Private`finiteFieldStripHeldOutInterpolate[
    canonical, prime, "InitialConstructionCount" -> 4,
    "HeldOutCount" -> 3, "MaximumTotalDegree" -> 36]];
If[Lookup[interpolation, "Status", None] =!= "HeldOutValidated",
  failure = <|"Status" -> "CF259FixedCoreRHSInterpolationFailedV1",
    "Prime" -> prime, "SampleCount" -> Length[images],
    "KnownRHSChecks" -> knownChecks,
    "InterpolationSeconds" -> N[interpolationSeconds],
    "Interpolation" -> KeyDrop[interpolation, {"Interpolations"}]|>;
  Put[failure, FileNameJoin[{runtime, "rhs_interpolation_failure.wl"}]];
  Print[InputForm[failure]]; Exit[3]];

evaluateCoefficients[coefficients_List, point_Integer] := Fold[
  Mod[#1 point + #2, prime] &, 0, Reverse[coefficients]];
modValue[value_] := Mod[Numerator[value]
  PowerMod[Denominator[value], -1, prime], prime];
evaluateRHS[value_] := Module[{point = modValue[value]},
  Developer`ToPackedArray[Table[With[
    {item = interpolation["Interpolations"][[coordinate]]},
    Mod[evaluateCoefficients[item["Numerator"], point]
      PowerMod[evaluateCoefficients[item["Denominator"], point], -1,
        prime], prime]], {coordinate, n}]]];
knownChecks = Association@Table[value ->
    (evaluateRHS[value] === core["RightHandSides"][value]),
  {value, Keys[core["RightHandSides"]]}];
If[! And @@ Values[knownChecks],
  Print["interpolated RHS disagrees with fixed-core samples: ", knownChecks];
  Exit[2]];

expansionPoint = 1/7;
expansionPointMod = Mod[Numerator[expansionPoint]
  PowerMod[Denominator[expansionPoint], -1, prime], prime];
shiftPolynomial[coefficients_List] := Table[Mod[Sum[
    coefficients[[k + 1]] Binomial[k, j]
      PowerMod[expansionPointMod, k - j, prime],
    {k, j, Length[coefficients] - 1}], prime],
  {j, 0, Length[coefficients] - 1}];
seriesFor[item_Association] := Module[{a, d, y, j, upper, value},
  a = shiftPolynomial[item["Numerator"]];
  d = shiftPolynomial[item["Denominator"]];
  If[First[d] === 0, Return[$Failed]];
  y = ConstantArray[0, order];
  Do[
    value = If[j < Length[a], a[[j + 1]], 0];
    upper = Min[j, Length[d] - 1];
    If[upper > 0, value = Mod[value - Sum[
      d[[k + 1]] y[[j - k + 1]], {k, 1, upper}], prime]];
    y[[j + 1]] = Mod[value PowerMod[First[d], -1, prime], prime];,
    {j, 0, order - 1}];
  Developer`ToPackedArray[y]];
{seriesSeconds, series} = AbsoluteTiming[
  seriesFor /@ interpolation["Interpolations"]];
If[MemberQ[series, $Failed],
  Print["epsilon=1 is a pole of a reconstructed RHS coordinate"]; Exit[4]];

rhsFile = FileNameJoin[{runtime, "core_rhs_taylor_order" <>
  ToString[order] <> "_center1_7.bin"}];
stream = OpenWrite[rhsFile <> ".tmp", BinaryFormat -> True];
BinaryWrite[stream, ToCharacterCode["CFK0T1\000"], "UnsignedInteger8"];
BinaryWrite[stream, {n, order, prime}, "UnsignedInteger64",
  ByteOrdering -> -1];
BinaryWrite[stream, Flatten[Transpose[series]], "UnsignedInteger64",
  ByteOrdering -> -1];
Close[stream]; RenameFile[rhsFile <> ".tmp", rhsFile,
  OverwriteTarget -> True];
activeReportFile = FileNameJoin[{runtime, "active_core_report.wl"}];
activeRHSFile = Missing["ActiveCoreAbsent"];
If[FileExistsQ[activeReportFile],
  activeReport = Get[activeReportFile];
  activeRows = activeReport["IndependentRowPositions"];
  activeRHSFile = FileNameJoin[{runtime,
    "active_rhs_taylor_order2048_center1_7.bin"}];
  stream = OpenWrite[activeRHSFile <> ".tmp", BinaryFormat -> True];
  BinaryWrite[stream, ToCharacterCode["CFK0T1\000"], "UnsignedInteger8"];
  BinaryWrite[stream, {Length[activeRows], order, prime},
    "UnsignedInteger64", ByteOrdering -> -1];
  BinaryWrite[stream, Flatten[Transpose[series[[activeRows]]]],
    "UnsignedInteger64", ByteOrdering -> -1];
  Close[stream]; RenameFile[activeRHSFile <> ".tmp", activeRHSFile,
    OverwriteTarget -> True]];
degreeHistogram = Counts[Lookup[interpolation["Interpolations"], "Degrees"]];
report = <|"Status" -> "CF259FixedCoreTaylorRHSV1", "Prime" -> prime,
  "ExpansionPoint" -> expansionPoint,
  "ExpansionPointMod" -> expansionPointMod, "CoreDimension" -> n,
  "SampleCount" -> Length[images], "KnownRHSChecks" -> knownChecks,
  "InterpolationSeconds" -> N[interpolationSeconds],
  "SeriesSeconds" -> N[seriesSeconds], "DegreeHistogram" -> degreeHistogram,
  "MaximumDegrees" -> Max /@ Transpose[Replace[
    Lookup[interpolation["Interpolations"], "Degrees"],
    -Infinity -> -1, {2}]], "TaylorOrder" -> order,
  "TaylorRHSFile" -> rhsFile,
  "ActiveTaylorRHSFile" -> activeRHSFile,
  "Interpolation" -> interpolation|>;
outputFile = FileNameJoin[{runtime, "core_rhs_interpolation.wl"}];
Put[report, outputFile];
Print[InputForm[KeyDrop[report, {"Interpolation"}]]];
Print["OUTPUT=", outputFile];
Exit[0];
