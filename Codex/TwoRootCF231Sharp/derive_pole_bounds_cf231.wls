auditDirectory =
  "/home/maxzhang/factorization-and-loops/Codex/TwoRootCF231Audit";
workDirectory = DirectoryName[$InputFileName];
stripPath = FileNameJoin[{auditDirectory, "CF231_8_7_exact_strip.wl"}];
residuePath = FileNameJoin[{workDirectory, "CF231_8_7_residue_space.wl"}];
outputPath = FileNameJoin[{workDirectory, "CF231_8_7_pole_bounds.wl"}];

record = Get[stripPath];
residueData = Get[residuePath];
{y, s} = record["Variables"];
epsilon = record["Regulator"];
{e, c, bbar} = record /@ {"E", "C", "Bbar"};

factors = <|
  "f3" -> s - 3,
  "f4" -> y,
  "f6" -> -1 - s + 2 y,
  "f8" -> -2 - 2 s + 5 y - 2 s y + s^2 y,
  "f10" -> 3 + 2 s - s^2 - 7 y + 2 s y + s^2 y,
  "qeps" ->
    -9 - 6 s + 3 s^2 + 15 y - 6 s y + 3 s^2 y +
      epsilon (-13 - 10 s + 3 s^2 + 25 y - 10 s y + 5 s^2 y)
|>;

ClearAll[canonicalPolynomial];
canonicalPolynomial[polynomial_] := Module[{expanded, rules, leading},
  expanded = Expand[polynomial];
  rules = CoefficientRules[expanded, {y, s, epsilon}];
  If[rules === {}, Return[0]];
  leading = Last[First[rules]];
  Expand[expanded/leading]
];

ClearAll[factorPowerInEntry];
factorPowerInEntry[entry_, factor_] := Module[
  {denominator, factorList, target},
  denominator = Denominator[Together[entry]];
  factorList = Rest[FactorList[denominator]];
  target = canonicalPolynomial[factor];
  Total[Cases[
    factorList,
    {candidate_, power_Integer} /;
        canonicalPolynomial[candidate] === target :> power
  ]]
];

ClearAll[maxFactorPower];
maxFactorPower[matrices_, factor_] := Max[
  factorPowerInEntry[#, factor] & /@ Flatten[matrices]
];

{orderSeconds, forcingOrders} = AbsoluteTiming[
  AssociationMap[maxFactorPower[bbar, factors[#]] &, Keys[factors]]
];
gaugePoleOrders = Map[Max[0, # - 1] &, forcingOrders];

ClearAll[localResidue];
localResidue[matrices_, factor_] := Module[
  {variable, direction, root, derivative},
  If[Exponent[factor, y] === 1,
    variable = y;
    direction = 1,
    variable = s;
    direction = 2
  ];
  root = variable /. First[Solve[factor == 0, variable]];
  derivative = D[factor, variable];
  Map[
    Together[
      Cancel[factor #/derivative] /. variable -> root
    ] &,
    matrices[[direction]],
    {2}
  ]
];

ClearAll[leadingPoleOperator];
leadingPoleOperator[factor_, poleOrder_Integer] := Module[
  {residueE, residueC, identity, matrix, determinant},
  residueE = localResidue[e, factor];
  residueC = localResidue[c, factor];
  identity = IdentityMatrix[4];
  matrix =
    poleOrder IdentityMatrix[16] + epsilon (
      KroneckerProduct[residueE, identity] -
      KroneckerProduct[identity, Transpose[residueC]]
    );
  determinant = Factor[Det[matrix]];
  <|
    "PoleOrder" -> poleOrder,
    "ResidueE" -> residueE,
    "ResidueC" -> residueC,
    "Determinant" -> determinant,
    "GenericallyInvertible" -> Not[TrueQ[determinant === 0]]
  |>
];

{operatorSeconds, operatorChecks} = AbsoluteTiming[
  Association@Flatten@Table[
    With[{name = factorName, maximalOrder = gaugePoleOrders[factorName]},
      Table[
        (name <> "_k" <> ToString[k]) ->
          leadingPoleOperator[factors[name], k],
        {k, maximalOrder}
      ]
    ],
    {factorName, Keys[factors]}
  ]
];

If[! AllTrue[operatorChecks[[All, "GenericallyInvertible"]], TrueQ],
  Print["A leading-pole operator is identically singular."];
  Exit[2]
];

gaugeDenominator = Times @@ MapThread[
  #1^#2 &,
  {Values[factors], Values[gaugePoleOrders]}
];
denominatorDegrees = Exponent[gaugeDenominator, #] & /@ {y, s};

ClearAll[rationalGrowth];
rationalGrowth[entry_, variable_] := Module[{q},
  q = Together[entry];
  Exponent[Numerator[q], variable] - Exponent[Denominator[q], variable]
];

forcingOwnAxisGrowth = {
  Max[rationalGrowth[#, y] & /@ Flatten[bbar[[1]]]],
  Max[rationalGrowth[#, s] & /@ Flatten[bbar[[2]]]]
};
gaugeGrowthBounds = forcingOwnAxisGrowth + 1;
numeratorDegreeBounds = denominatorDegrees + gaugeGrowthBounds;

result = <|
  "Family" -> record["Family"],
  "Pair" -> record["Pair"],
  "Chart" -> record["Chart"],
  "Variables" -> record["Variables"],
  "Regulator" -> epsilon,
  "Factors" -> factors,
  "ForcingPoleOrders" -> forcingOrders,
  "GaugePoleOrders" -> gaugePoleOrders,
  "LeadingPoleOperatorChecks" -> operatorChecks,
  "GaugeDenominator" -> gaugeDenominator,
  "GaugeDenominatorDegrees" -> denominatorDegrees,
  "ForcingOwnAxisGrowth" -> forcingOwnAxisGrowth,
  "GaugeGrowthBounds" -> gaugeGrowthBounds,
  "NumeratorDegreeBounds" -> numeratorDegreeBounds,
  "GaugeUnknownCount" -> 16 Times @@ (numeratorDegreeBounds + 1),
  "ResidueUnknownCount" -> residueData["FreeResidueParameterCount"],
  "TotalUnknownCount" ->
    16 Times @@ (numeratorDegreeBounds + 1) +
      residueData["FreeResidueParameterCount"],
  "Timings" -> <|
    "ForcingPoleOrders" -> orderSeconds,
    "LeadingPoleOperators" -> operatorSeconds
  |>
|>;

Put[result, outputPath];
Print[KeyDrop[result, {"LeadingPoleOperatorChecks", "GaugeDenominator"}]];
Print["Leading-pole determinants:"];
KeyValueMap[
  Print[#1, ": ", InputForm[#2["Determinant"]]] &,
  operatorChecks
];
Print["Saved: ", outputPath, " (", FileByteCount[outputPath], " bytes)"];
