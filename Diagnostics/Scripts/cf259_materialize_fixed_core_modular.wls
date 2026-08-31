#!/usr/bin/env wolframscript

(* Materialize the coordinatewise Padé stream as one modular rational vector
   in the original 3,524-coordinate ansatz, with the pilot free variables set
   to zero.  This does not perform a production acceptance check. *)

$HistoryLength = 0;
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
args = Rest[$ScriptCommandLine];
mode = If[Length[args] >= 1, args[[1]], "downward"];
trainRequested = If[Length[args] >= 2, ToExpression[args[[2]]], 1900];
runtime = Which[
  mode === "downward", FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_downward_taylor_core"}],
  mode === "shell3", FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_shell3_stacked_taylor_core"}],
  StringStartsQ[mode, "prime"], FileNameJoin[{codexRoot, "Runtime",
    "2026-08-31_cf259_shell3_multprime", mode}],
  True, Print["unknown mode: ", mode]; Exit[64]];
core = Get[FileNameJoin[{runtime, "core_report.wl"}]];
rhs = Get[FileNameJoin[{runtime, "core_rhs_interpolation.wl"}]];
If[mode =!= "downward",
  activeCore = <|"ActiveCoreDimension" -> core["CoreDimension"],
    "ActiveOriginalColumns" -> core["CoreColumns"]|>;
  padeFile = FileNameJoin[{runtime, "core_solution_pade_order" <>
    ToString[rhs["TaylorOrder"]] <> "_train" <>
    ToString[trainRequested] <> ".bin"}],
  activeCore = Get[FileNameJoin[{runtime, "active_core_report.wl"}]];
  padeFile = FileNameJoin[{runtime,
    "active_solution_pade_order2048_train1900.bin"}]];
stream = OpenRead[padeFile, BinaryFormat -> True];
magic = FromCharacterCode[BinaryReadList[stream, "UnsignedInteger8", 7]];
header = BinaryReadList[stream, "UnsignedInteger64", 4,
  ByteOrdering -> -1];
If[magic =!= "CFK0P1\000" || Length[header] =!= 4,
  Close[stream]; Print["invalid Padé header"]; Exit[1]];
{n, order, prime, train} = header;
If[n =!= activeCore["ActiveCoreDimension"] || prime =!= core["Prime"] ||
    order =!= rhs["TaylorOrder"],
  Close[stream]; Print["Padé metadata mismatch"]; Exit[2]];

center = rhs["ExpansionPoint"];
trim[coefficients_List] := Module[{last = Length[coefficients]},
  While[last > 1 && coefficients[[last]] === 0, --last];
  Take[coefficients, last]];
items = Table[
  lengths = BinaryReadList[stream, "UnsignedInteger64", 2,
    ByteOrdering -> -1];
  If[Length[lengths] =!= 2 || lengths[[2]] < 1,
    Close[stream]; Print["truncated Padé record ", coordinate]; Exit[3]];
  numerator = If[lengths[[1]] === 0, {0},
    BinaryReadList[stream, "UnsignedInteger64", lengths[[1]],
      ByteOrdering -> -1]];
  denominator = BinaryReadList[stream, "UnsignedInteger64", lengths[[2]],
    ByteOrdering -> -1];
  numerator = trim[numerator];
  denominator = trim[denominator];
  <|"Numerator" -> numerator, "Denominator" -> denominator,
    "Degrees" -> {If[numerator === {0}, -Infinity,
      Length[numerator] - 1], Length[denominator] - 1}|>,
  {coordinate, n}];
Close[stream];

activeOriginalColumns = activeCore["ActiveOriginalColumns"];
unknownCount = core["GaugeUnknownCount"] + core["ResidueUnknownCount"];
free = Complement[Range[unknownCount], activeOriginalColumns];
zero = <|"Numerator" -> {0}, "Denominator" -> {1},
  "Degrees" -> {-Infinity, 0}|>;
vector = ConstantArray[zero, unknownCount];
vector[[activeOriginalColumns]] = items;
degreeHistogram = Counts[Lookup[vector, "Degrees"]];
report = <|"Status" -> If[mode =!= "downward",
    "CF259Shell3FixedCoreModularVectorV1",
    "CF259FixedCoreModularVectorV1"],
  "Prime" -> prime, "ExpansionPoint" -> center,
  "PolynomialVariable" -> "EpsilonMinusExpansionPoint",
  "TaylorOrder" -> order, "TrainingCoefficientCount" -> train,
  "HeldOutCoefficientCount" -> order - train,
  "UnknownCount" -> unknownCount,
  "ActiveOriginalColumns" -> activeOriginalColumns,
  "ZeroOriginalColumns" -> free, "DegreeHistogram" -> degreeHistogram,
  "MaximumDegrees" -> Max /@ Transpose[Replace[
    Lookup[vector, "Degrees"], -Infinity -> -1, {2}]],
  "Interpolations" -> vector|>;
outputFile = FileNameJoin[{runtime, If[mode =!= "downward",
  "cf259_shell3_fixed_core_modular_vector_prime1.wl",
  "cf259_active_fixed_core_modular_vector_prime1.wl"]}];
Put[report, outputFile];
Print[InputForm[KeyDrop[report, {"ActiveOriginalColumns",
  "ZeroOriginalColumns", "Interpolations"}]]];
Print["OUTPUT=", outputFile];
Exit[0];
