#!/usr/bin/env wolframscript

(* Adaptive CRT/rational lift for the accepted CF259 shell-3 section.
   The next complete prime image is excluded from the CRT and used as the
   discriminator for whether the current modulus is already large enough. *)

$HistoryLength = 0;
args = Rest[$ScriptCommandLine];
If[Length[args] < 1,
  Print["usage: cf259_lift_shell3_vectors.wls TRAINING_PRIME_COUNT"];
  Exit[64]];
trainingCount = ToExpression[args[[1]]];
reconstructionMethod = If[Length[args] >= 2, args[[2]], "balanced"];
If[! MemberQ[{"balanced", "guided"}, reconstructionMethod], Exit[64]];
root = "/home/maxzhang/factorization-and-loops";
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
primeValues = {2305843009213693951, 2305843009213693907,
  2305843009213693723, 2305843009213693487, 2305843009213693123,
  2305843009213692199, 2305843009213691993};
tags = "prime" <> ToString[#] & /@ Range[Length[primeValues]];
If[trainingCount < 1 || trainingCount >= Length[primeValues], Exit[64]];
vectorFile[1] := FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_cf259_shell3_stacked_taylor_core",
  "cf259_shell3_fixed_core_modular_vector_prime1.wl"}];
vectorFile[index_Integer] := FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_cf259_shell3_multprime", tags[[index]],
  "cf259_shell3_fixed_core_modular_vector_prime1.wl"}];
indices = Range[trainingCount + 1];
If[! AllTrue[indices, FileExistsQ[vectorFile[#]] &],
  Print["missing modular vector among indices ", indices]; Exit[1]];
vectors = Get /@ (vectorFile /@ indices);
If[! AllTrue[vectors, AssociationQ[#] &&
      Lookup[#, "Status", None] ===
        "CF259Shell3FixedCoreModularVectorV1" &], Exit[2]];
training = Take[vectors, trainingCount];
validation = Last[vectors];
primes = Lookup[training, "Prime"];
validationPrime = validation["Prime"];
unknownCount = First[training]["UnknownCount"];
If[Lookup[vectors, "UnknownCount"] =!=
    ConstantArray[unknownCount, Length[vectors]] ||
    Lookup[vectors, "ExpansionPoint"] =!=
      ConstantArray[First[training]["ExpansionPoint"], Length[vectors]],
  Print["modular vector metadata mismatch"]; Exit[3]];

{combineSeconds, combined} = AbsoluteTiming[Table[
  FeynFacet`Private`epsFormFiniteFieldCombineCoordinate[
    training[[All, "Interpolations", coordinate]], primes],
  {coordinate, unknownCount}]];
degreeFailures = Flatten[Position[combined, $Failed, {1}, Heads -> False]];
If[degreeFailures =!= {},
  report = <|"Status" -> "CF259Shell3DegreeProfileMismatchV1",
    "TrainingPrimes" -> primes, "Coordinates" -> degreeFailures|>;
  Print[InputForm[report]]; Exit[4]];
modulus = Times @@ primes;
validationGuidedReconstruct[value_Integer, check_Integer] := Module[
  {r0 = modulus, r1 = Mod[value, modulus], t0 = 0, t1 = 1, quotient,
   candidate, candidates = {}},
  If[r1 === 0,
    Return[If[Mod[check, validationPrime] === 0, 0, $Failed]]];
  While[r1 =!= 0,
    If[t1 =!= 0,
      candidate = If[t1 < 0, (-r1)/(-t1), r1/t1];
      If[FeynFacet`Private`epsFormFiniteFieldImageQ[
          check, candidate, validationPrime], AppendTo[candidates, candidate]]];
    quotient = Quotient[r0, r1];
    {r0, r1} = {r1, r0 - quotient r1};
    {t0, t1} = {t1, t0 - quotient t1}];
  candidates = DeleteDuplicates[candidates];
  If[Length[candidates] === 1, First[candidates], $Failed]];
reconstructList[values_List, checks_List] := If[
  reconstructionMethod === "guided",
  MapThread[validationGuidedReconstruct, {values, checks}],
  FeynFacet`Private`epsFormFiniteFieldRationalReconstruct[#, modulus] & /@
    values];
{liftSeconds, lifted} = AbsoluteTiming[Table[<|
    "NumeratorCoefficients" ->
      reconstructList[combined[[coordinate, "Numerator"]],
        validation["Interpolations"][[coordinate, "Numerator"]]],
    "DenominatorCoefficients" ->
      reconstructList[combined[[coordinate, "Denominator"]],
        validation["Interpolations"][[coordinate, "Denominator"]]],
    "Degrees" -> combined[[coordinate, "Degrees"]]|>,
  {coordinate, unknownCount}]];
liftFailures = DeleteDuplicates[First /@ Position[lifted, $Failed, Infinity,
  Heads -> False]];
imageQ[modular_Integer, rational_] :=
  FeynFacet`Private`epsFormFiniteFieldImageQ[
    modular, rational, validationPrime];
validationFailures = If[liftFailures =!= {}, {}, Select[
  Range[unknownCount], Function[coordinate,
    With[{image = validation["Interpolations"][[coordinate]],
      candidate = lifted[[coordinate]]},
      image["Degrees"] =!= candidate["Degrees"] ||
      ! And @@ MapThread[imageQ,
        {image["Numerator"], candidate["NumeratorCoefficients"]}] ||
      ! And @@ MapThread[imageQ,
        {image["Denominator"], candidate["DenominatorCoefficients"]}]]]]];
accepted = liftFailures === {} && validationFailures === {};
finiteRationals = Cases[lifted, value_Rational | value_Integer /;
  value =!= $Failed :> value, Infinity];
maxNumeratorBits = If[finiteRationals === {}, 0,
  Max[IntegerLength[Abs[Numerator[#]], 2] & /@ finiteRationals]];
maxDenominatorBits = If[finiteRationals === {}, 0,
  Max[IntegerLength[Denominator[#], 2] & /@ finiteRationals]];
report = <|"Status" -> If[accepted, "CF259Shell3RationalLiftAcceptedV1",
    "CF259Shell3RationalLiftInsufficientV1"], "Accepted" -> accepted,
  "TrainingPrimes" -> primes, "ValidationPrime" -> validationPrime,
  "ReconstructionMethod" -> reconstructionMethod,
  "ModulusBits" -> IntegerLength[modulus, 2],
  "UnknownCount" -> unknownCount,
  "LiftFailureCount" -> Length[liftFailures],
  "LiftFailureCoordinates" -> liftFailures,
  "ValidationFailureCount" -> Length[validationFailures],
  "ValidationFailureCoordinates" -> validationFailures,
  "MaximumNumeratorBits" -> maxNumeratorBits,
  "MaximumDenominatorBits" -> maxDenominatorBits,
  "CombineSeconds" -> N[combineSeconds], "LiftSeconds" -> N[liftSeconds],
  "ExpansionPoint" -> First[training]["ExpansionPoint"],
  "PolynomialVariable" -> "EpsilonMinusExpansionPoint",
  "LiftedInterpolations" -> If[accepted, lifted, Missing["NotAccepted"]]|>;
outputDirectory = FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_cf259_shell3_multprime"}];
outputFile = FileNameJoin[{outputDirectory,
  "rational_lift_" <> ToString[trainingCount] <> "_plus_1" <>
    If[reconstructionMethod === "guided", "_guided", ""] <> ".wl"}];
Put[report, outputFile];
Print[InputForm[KeyDrop[report, {"LiftFailureCoordinates",
  "ValidationFailureCoordinates", "LiftedInterpolations"}]]];
Print["OUTPUT=", outputFile];
Exit[If[accepted, 0, 5]];
