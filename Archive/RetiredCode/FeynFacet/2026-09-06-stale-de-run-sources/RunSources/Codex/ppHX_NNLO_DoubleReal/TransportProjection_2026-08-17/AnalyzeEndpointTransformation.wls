If[Length[$ScriptCommandLine] < 2,
  Print["usage: wolframscript -file AnalyzeEndpointTransformation.wls <family-record>"];
  Exit[2]
];

record = Get[$ScriptCommandLine[[2]]];
variables = record["Variables"];
u = variables[[2]];
baseFirst = If[record["Frame"] === "Chart", 1/2, 1/4];
t = record["TTotal"] /. variables[[1]] -> baseFirst;

RationalOrder[0] = Infinity;
RationalOrder[expr_] := Module[{num, den, numOrder, denOrder},
  {num, den} = NumeratorDenominator[Together[expr]];
  numOrder = Exponent[num /. u -> z u, z, Min];
  denOrder = Exponent[den /. u -> z u, z, Min];
  numOrder - denOrder
];

orders = Map[RationalOrder, t, {2}];
rowMinima = Map[Min, orders];

Print[<|
  "Family" -> record["Family"],
  "Dimension" -> record["Dim"],
  "RowMinimumOrders" -> rowMinima,
  "MinimumOrderCounts" -> Counts[rowMinima],
  "GlobalMinimumOrder" -> Min[rowMinima]
|>];
