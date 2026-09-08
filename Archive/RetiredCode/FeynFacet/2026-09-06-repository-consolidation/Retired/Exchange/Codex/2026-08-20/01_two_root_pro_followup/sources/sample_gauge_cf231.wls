workDirectory = DirectoryName[$InputFileName];
auditDirectory =
  "/home/maxzhang/factorization-and-loops/Codex/TwoRootCF231Audit";
recordPath = FileNameJoin[{auditDirectory, "CF231_8_7_exact_strip.wl"}];
residuePath = FileNameJoin[{workDirectory, "CF231_8_7_residue_space.wl"}];
polePath = FileNameJoin[{workDirectory, "CF231_8_7_pole_bounds.wl"}];

ClearAll[environmentValue];
environmentValue[name_String, default_String] := Module[{value},
  value = Environment[name];
  If[StringQ[value] && StringLength[value] > 0, value, default]
];

epsilonValue = ToExpression[environmentValue["FACET_EPSILON", "1/7"]];
prime = ToExpression[environmentValue["FACET_PRIME", "1000003"]];
requestedPointCount =
  ToExpression[environmentValue["FACET_POINT_COUNT", "50"]];
solveAffineQ =
  ToExpression[environmentValue["FACET_SOLVE_AFFINE", "False"]];
epsilonMod = Mod[
  Numerator[epsilonValue]
    PowerMod[Mod[Denominator[epsilonValue], prime], -1, prime],
  prime
];

outputTag = StringReplace[
  ToString[epsilonValue, InputForm] <> "_p" <> ToString[prime],
  {"/" -> "_", "-" -> "m", " " -> ""}
];
outputPath = FileNameJoin[{workDirectory,
  "CF231_8_7_gauge_sample_" <> outputTag <> ".wl"}];

record = Get[recordPath];
residueData = Get[residuePath];
poleData = Get[polePath];
{y, s} = record["Variables"];
epsilon = record["Regulator"];
{e, c} = record /@ {"E", "C"};
forcing = residueData["Forcing"];
freeResidues = residueData["Parameters"];
gaugeDenominator = poleData["GaugeDenominator"];
{degreeY, degreeS} = poleData["NumeratorDegreeBounds"];
matrixDimension = 4;
gaugeUnknownCount =
  matrixDimension^2 (degreeY + 1) (degreeS + 1);
unknownCount = gaugeUnknownCount + Length[freeResidues];

forcingConstant = forcing /. Thread[freeResidues -> 0];
forcingCoefficients = Table[
  Map[Coefficient[#, residue] &, forcing, {3}],
  {residue, freeResidues}
];

ClearAll[modNumber];
modNumber[value_] := Module[{numerator, denominator},
  If[! FreeQ[value, _Symbol], Throw[$Failed, "BadCoefficient"]];
  numerator = Mod[Numerator[value], prime];
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Throw[$Failed, "BadCoefficient"]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

ClearAll[polynomialRules];
polynomialRules[polynomial_] :=
  ({First[#], modNumber[Last[#]]} &) /@
    (List @@@ CoefficientRules[polynomial, {y, s}]);

ClearAll[rationalForm];
rationalForm[expression_] := Module[{q},
  q = Together[expression];
  {polynomialRules[Numerator[q]], polynomialRules[Denominator[q]]}
];

ClearAll[evaluatePolynomial];
evaluatePolynomial[rules_List, yValue_Integer, sValue_Integer] := Mod[
  Total[
    (#[[2]] PowerMod[Mod[yValue, prime], #[[1, 1]], prime]
        PowerMod[Mod[sValue, prime], #[[1, 2]], prime]) & /@ rules
  ],
  prime
];

ClearAll[evaluateRational];
evaluateRational[form_List, yValue_Integer, sValue_Integer] := Module[
  {numerator, denominator},
  numerator = evaluatePolynomial[form[[1]], yValue, sValue];
  denominator = evaluatePolynomial[form[[2]], yValue, sValue];
  If[denominator === 0, Throw[$Failed, "BadPoint"]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

{preprocessingSeconds, forms} = AbsoluteTiming[{
  Map[rationalForm, e /. epsilon -> epsilonValue, {3}],
  Map[rationalForm, c /. epsilon -> epsilonValue, {3}],
  Map[rationalForm, forcingConstant /. epsilon -> epsilonValue, {3}],
  Table[
    Map[rationalForm,
      forcingCoefficients[[index]] /. epsilon -> epsilonValue, {3}],
    {index, Length[freeResidues]}
  ],
  rationalForm[gaugeDenominator /. epsilon -> epsilonValue],
  {
    rationalForm[D[gaugeDenominator, y] /. epsilon -> epsilonValue],
    rationalForm[D[gaugeDenominator, s] /. epsilon -> epsilonValue]
  }
}];
{
  eForms, cForms, forcingConstantForms, forcingCoefficientForms,
  gaugeDenominatorForm, gaugeDenominatorDerivativeForms
} = forms;

ClearAll[columnIndex];
columnIndex[i_, j_, py_, ps_] :=
  ((((i - 1)*matrixDimension + j - 1)*(degreeY + 1) + py)*
      (degreeS + 1) + ps + 1);

If[columnIndex[1, 1, 0, 0] =!= 1 ||
    columnIndex[4, 4, degreeY, degreeS] =!= gaugeUnknownCount,
  Print["Invalid column map: ",
    {columnIndex[1, 1, 0, 0],
      columnIndex[4, 4, degreeY, degreeS]}];
  Print[InputForm[DownValues[columnIndex]]];
  Exit[8]
];

ClearAll[buildPointRows];
buildPointRows[yValue_Integer, sValue_Integer] := Catch[
 Module[
  {eValue, cValue, forcing0Value, forcingFreeValue,
   denominatorValue, derivativeDenominatorValues, inverseDenominator,
   yPowers, sPowers, phi, derivativePhi, rows, rightHandSide,
   rowIndex, row, coefficient, column, mu, i, j, aIndex, bIndex,
   py, ps, residueIndex},

  eValue = Map[evaluateRational[#, yValue, sValue] &, eForms, {3}];
  cValue = Map[evaluateRational[#, yValue, sValue] &, cForms, {3}];
  forcing0Value = Map[
    evaluateRational[#, yValue, sValue] &,
    forcingConstantForms,
    {3}
  ];
  forcingFreeValue = Table[
    Map[evaluateRational[#, yValue, sValue] &,
      forcingCoefficientForms[[residueIndex]], {3}],
    {residueIndex, Length[freeResidues]}
  ];

  denominatorValue =
    evaluateRational[gaugeDenominatorForm, yValue, sValue];
  inverseDenominator = PowerMod[denominatorValue, -1, prime];
  derivativeDenominatorValues =
    evaluateRational[#, yValue, sValue] & /@
      gaugeDenominatorDerivativeForms;

  yPowers = Table[PowerMod[Mod[yValue, prime], power, prime],
    {power, 0, degreeY}];
  sPowers = Table[PowerMod[Mod[sValue, prime], power, prime],
    {power, 0, degreeS}];
  phi = Table[
    Mod[yPowers[[py + 1]] sPowers[[ps + 1]] inverseDenominator,
      prime],
    {py, 0, degreeY}, {ps, 0, degreeS}
  ];
  derivativePhi = Table[
    Mod[
      If[mu === 1,
        If[py === 0, 0,
          py yPowers[[py]] sPowers[[ps + 1]]] inverseDenominator,
        If[ps === 0, 0,
          ps yPowers[[py + 1]] sPowers[[ps]]] inverseDenominator
      ] - phi[[py + 1, ps + 1]]
          derivativeDenominatorValues[[mu]] inverseDenominator,
      prime
    ],
    {mu, 2}, {py, 0, degreeY}, {ps, 0, degreeS}
  ];

  rows = ConstantArray[0, {2 matrixDimension^2, unknownCount}];
  rightHandSide = ConstantArray[0, 2 matrixDimension^2];
  rowIndex = 0;
  Do[
    rowIndex++;
    row = rows[[rowIndex]];

    Do[
      column = columnIndex[i, j, py, ps];
      row[[column]] = derivativePhi[[mu, py + 1, ps + 1]],
      {py, 0, degreeY}, {ps, 0, degreeS}
    ];

    Do[
      Do[
        column = columnIndex[aIndex, j, py, ps];
        coefficient = -epsilonMod eValue[[mu, i, aIndex]]
          phi[[py + 1, ps + 1]];
        row[[column]] = Mod[row[[column]] + coefficient, prime],
        {py, 0, degreeY}, {ps, 0, degreeS}
      ],
      {aIndex, matrixDimension}
    ];

    Do[
      Do[
        column = columnIndex[i, bIndex, py, ps];
        coefficient = epsilonMod phi[[py + 1, ps + 1]]
          cValue[[mu, bIndex, j]];
        row[[column]] = Mod[row[[column]] + coefficient, prime],
        {py, 0, degreeY}, {ps, 0, degreeS}
      ],
      {bIndex, matrixDimension}
    ];

    Do[
      row[[gaugeUnknownCount + residueIndex]] =
        Mod[-forcingFreeValue[[residueIndex, mu, i, j]], prime],
      {residueIndex, Length[freeResidues]}
    ];

    rows[[rowIndex]] = row;
    rightHandSide[[rowIndex]] = forcing0Value[[mu, i, j]],
    {mu, 2}, {i, matrixDimension}, {j, matrixDimension}
  ];

  If[! MatrixQ[rows, IntegerQ],
    Print["Malformed point rows. Dimensions: ", Dimensions[rows]];
    Print["Value dimensions: E=", Dimensions[eValue],
      ", C=", Dimensions[cValue],
      ", F0=", Dimensions[forcing0Value],
      ", Ffree=", Dimensions[forcingFreeValue]];
    Print["First row: ", InputForm[Short[First[rows], 4]]];
    Exit[9]
  ];

  {SparseArray[rows], rightHandSide}
 ],
 "BadPoint"
];

SeedRandom[2310807];
pointRows = {};
pointRightHandSides = {};
acceptedPoints = {};
attemptCount = 0;

Print["Gauge numerator degrees: ", {degreeY, degreeS}];
Print["Unknowns: ", unknownCount, " = ", gaugeUnknownCount,
  " gauge + ", Length[freeResidues], " residue"];
Print["Rational preprocessing seconds: ", preprocessingSeconds];

{samplingSeconds, samplingResult} = AbsoluteTiming[
  While[Length[acceptedPoints] < requestedPointCount,
    attemptCount++;
    point = RandomInteger[{2, prime - 2}, 2];
    pointResult = buildPointRows @@ point;
    If[pointResult =!= $Failed,
      AppendTo[acceptedPoints, point];
      AppendTo[pointRows, pointResult[[1]]];
      AppendTo[pointRightHandSides, pointResult[[2]]]
    ]
  ]
];

matrix = Join @@ pointRows;
rightHandSide = Join @@ pointRightHandSides;
augmented = Join[matrix, SparseArray[List /@ rightHandSide], 2];

{rankSeconds, rank} = AbsoluteTiming[
  MatrixRank[matrix, Modulus -> prime]
];
{augmentedRankSeconds, augmentedRank} = AbsoluteTiming[
  MatrixRank[augmented, Modulus -> prime]
];

affineData = <||>;
If[TrueQ[solveAffineQ] && TrueQ[rank === augmentedRank],
  {linearSolveSeconds, particularSolution} = AbsoluteTiming[
    LinearSolve[matrix, rightHandSide, Modulus -> prime]
  ];
  {nullspaceSeconds, nullspaceBasis} = AbsoluteTiming[
    NullSpace[matrix, Modulus -> prime]
  ];
  affineData = <|
    "LinearSolveSeconds" -> linearSolveSeconds,
    "NullspaceSeconds" -> nullspaceSeconds,
    "ParticularSolution" -> particularSolution,
    "NullspaceBasis" -> nullspaceBasis,
    "ParticularCheckZero" ->
      AllTrue[Mod[matrix.particularSolution - rightHandSide, prime],
        # === 0 &],
    "NullspaceCheckZero" ->
      AllTrue[Flatten[Mod[matrix.Transpose[nullspaceBasis], prime]],
        # === 0 &]
  |>
];

result = <|
  "Family" -> record["Family"],
  "Pair" -> record["Pair"],
  "EpsilonValue" -> epsilonValue,
  "Prime" -> prime,
  "AcceptedPoints" -> acceptedPoints,
  "AttemptCount" -> attemptCount,
  "GaugeNumeratorDegrees" -> {degreeY, degreeS},
  "GaugeUnknownCount" -> gaugeUnknownCount,
  "ResidueUnknownCount" -> Length[freeResidues],
  "MatrixDimensions" -> Dimensions[matrix],
  "NonzeroEntries" -> Length[matrix["NonzeroValues"]],
  "Rank" -> rank,
  "AugmentedRank" -> augmentedRank,
  "Nullity" -> unknownCount - rank,
  "Consistent" -> TrueQ[rank === augmentedRank],
  "PreprocessingSeconds" -> preprocessingSeconds,
  "SamplingSeconds" -> samplingSeconds,
  "RankSeconds" -> rankSeconds,
  "AugmentedRankSeconds" -> augmentedRankSeconds
|> ~Join~ affineData;

Put[result, outputPath];
Print[KeyDrop[result, {
  "AcceptedPoints", "ParticularSolution", "NullspaceBasis"
}]];
Print["Saved: ", outputPath, " (", FileByteCount[outputPath], " bytes)"];
