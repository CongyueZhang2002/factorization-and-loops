#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
bundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_round2_2026-08-21"}];

fixtures = {
  <|"Name" -> "CF254_9_6",
    "Record" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "BenchmarkStripBackends", "fixtures",
      "fixture_CF254_9_6.wl"}],
    "Result" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "BenchmarkStripBackends", "frozen_M0",
      "m1_run", "result_M1_CF254_9_6_FiniteField.wl"}]|>,
  <|"Name" -> "CF254_9_7",
    "Record" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "BenchmarkStripBackends", "frozen_M0",
      "fixture_CF254_9_7.wl"}],
    "Result" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "BenchmarkStripBackends", "frozen_M0",
      "result_fixture_CF254_9_7_FiniteField.wl"}]|>
};

ClearAll[a3Support];
a3Support[polynomial_, variables_List] := Module[{rules},
  rules = CoefficientRules[Expand[polynomial], variables];
  If[rules === {}, {}, Sort[rules[[All, 1]]]]
];

results = Table[
  Print["A3 support census: ", fixture["Name"]];
  record = Get[fixture["Record"]];
  resultRun = Get[fixture["Result"]];
  result = Lookup[resultRun, "BackendResult", resultRun];
  variables = record["Variables"];
  {x, y} = variables;
  gauge = result["Gauge"];
  denominator = result["GaugeDenominator"];
  numeratorDegrees = result["GaugeNumeratorDegrees"];
  rectangle = Flatten[Table[{px, py},
    {px, 0, numeratorDegrees[[1]]},
    {py, 0, numeratorDegrees[[2]]}], 1];
  numerators = Map[Cancel[Together[# denominator]] &, gauge, {2}];
  supports = a3Support[#, variables] & /@ Flatten[numerators];
  supportUnion = Sort[Union @@ supports];
  supportIntersection = Sort[Intersection @@ supports];
  complement = Complement[rectangle, supportUnion];
  denominatorSupport = a3Support[denominator, variables];
  census = <|
    "Fixture" -> fixture["Name"],
    "GaugeDimensions" -> Dimensions[gauge],
    "NumeratorDegrees" -> numeratorDegrees,
    "RectangleCountPerEntry" -> Length[rectangle],
    "SupportCountsPerEntry" -> Length /@ supports,
    "SupportUnionCount" -> Length[supportUnion],
    "SupportIntersectionCount" -> Length[supportIntersection],
    "SupportUnion" -> supportUnion,
    "RectangleComplement" -> complement,
    "DenominatorDegrees" -> (Exponent[denominator, #] & /@ variables),
    "DenominatorSupportCount" -> Length[denominatorSupport],
    "DenominatorSupport" -> denominatorSupport,
    "DenominatorFactorList" -> FactorList[denominator]
  |>;
  Print[InputForm[census]];
  census,
  {fixture, fixtures}];

Put[results, FileNameJoin[{bundle, "a3_support_census_result.wl"}]];

