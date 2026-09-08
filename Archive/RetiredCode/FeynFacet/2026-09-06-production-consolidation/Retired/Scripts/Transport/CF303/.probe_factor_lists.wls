#!/usr/bin/env wolframscript
$AllowInternet = False;
$HistoryLength = 0;
data = Import[
  "/tmp/cf303_junction_interpolations/q2305843009213641971.json",
  "RawJSON"];
q = data["prime"];
by = Association[(#["key"] -> #) & /@ data["coordinates"]];
keys = If[Rest[$ScriptCommandLine] === {}, {"1:-2:44:0"},
  Rest[$ScriptCommandLine]];
Do[
  record = by[key];
  polynomial = record["denominator"] . p^Range[0,
      Length[record["denominator"]] - 1];
  factors = FactorList[polynomial, Modulus -> q];
  numeratorPolynomial = record["numerator"] . p^Range[0,
      Length[record["numerator"]] - 1];
  numeratorFactors = FactorList[numeratorPolynomial, Modulus -> q];
  Print[InputForm[<|"Key" -> key, "Factors" -> factors,
    "NumeratorFactorDegrees" -> ({Exponent[First[#], p], Last[#]} & /@
      Rest[numeratorFactors])|>]],
  {key, keys}];
