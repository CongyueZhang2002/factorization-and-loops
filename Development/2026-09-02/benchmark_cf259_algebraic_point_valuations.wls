#!/usr/bin/env wolframscript

repositoryRoot = ExpandFileName[FileNameJoin[
  {DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[FileNameJoin[{repositoryRoot, "Runtime",
  "2026-09-01_observable_transport_triple_final", "cf259_dlog_gpu",
  "family_epsform_CF259_compact.wl"}]];
eps = record["Regulator"];
{x, y} = record["Variables"];
points = {{2/7, 1/5}, {3/11, 2/13}, {4/13, 3/17}};

polynomialOrder[polynomial_] := Module[{coefficients, position},
  coefficients = CoefficientList[polynomial, eps];
  position = FirstPosition[coefficients,
    coefficient_ /; ! TrueQ[RootReduce[coefficient] === 0],
    Missing["ZeroPolynomial"], {1}, Heads -> False];
  If[MissingQ[position], Infinity, First[position] - 1]
];

algebraicEpsOrder[expression_] := Module[{rational},
  rational = Together[expression];
  If[TrueQ[RootReduce[rational] === 0], Return[Infinity, Module]];
  polynomialOrder[Numerator[rational]] -
    polynomialOrder[Denominator[rational]]
];

results = Table[
  {seconds, orders} = AbsoluteTiming[Module[
    {rules = Thread[{x, y} -> point], sampledT, sampledInverse, tmin,
     blockOrders},
    sampledT = record["TTotal"] /. rules;
    sampledInverse = record["TTotalInverse"] /. rules;
    tmin = Min[0, Sequence @@ DeleteCases[
      algebraicEpsOrder /@ Flatten[sampledT], Infinity]];
    blockOrders = Table[With[{values = DeleteCases[
        algebraicEpsOrder /@ Flatten[
          sampledInverse[[record["Ranges"][[block]], All]]], Infinity]},
      If[values === {}, Missing["ZeroBlock"], Min[values]]],
      {block, Length[record["Ranges"]]}];
    <|"TMin" -> tmin, "BlockLower" -> blockOrders|>
  ]];
  Print[InputForm[<|"Point" -> point, "Seconds" -> seconds,
    "Orders" -> orders|>]];
  orders,
  {point, points}];
Print[InputForm[<|"Status" -> If[SameQ @@ results,
    "AllGenericAlgebraicPointsAgree", "PointDependenceDetected"],
  "DistinctResults" -> DeleteDuplicates[results]|>]];
