recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
   "sector_CF254_standard/CF254_9_8_unsolved.wl";
residuePath = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_residue_data.wl"}];

ClearAll[environmentValue];
environmentValue[name_String, default_String] := Module[{value},
  value = Environment[name];
  If[StringQ[value] && StringLength[value] > 0, value, default]
];

epsilonValue = ToExpression[environmentValue["FACET_EPSILON", "1/7"]];
prime = ToExpression[environmentValue["FACET_PRIME", "1000003"]];
requestedPointCount =
  ToExpression[environmentValue["FACET_POINT_COUNT", "80"]];
solveAffineQ =
  ToExpression[environmentValue["FACET_SOLVE_AFFINE", "False"]];
epsilonMod = Mod[
  Numerator[epsilonValue]*
    PowerMod[Mod[Denominator[epsilonValue], prime], -1, prime],
  prime
];

outputTag = StringReplace[
  ToString[epsilonValue, InputForm] <> "_p" <> ToString[prime],
  {"/" -> "_", "-" -> "m", " " -> ""}
];
outputPath = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_point_sample_rank_" <> outputTag <> ".wl"}];

record = Get[recordPath];
residueData = Get[residuePath];
{x, y} = record["Variables"];
epsilon = record["Regulator"];
{e, c, bbar} = record["Strip"];
forcing = residueData["Forcing"];
freeResidues = residueData["FreeResidues"];

doublePoleFactors = {
  -1 + x,
  -1 + 2 x - y,
  -1 + 2 x + y,
  3 + 4 x^2 + 2 y - y^2,
  -1 + 6 x + 2 x y + y^2,
  -3 + 4 x + 4 x^2 - 2 y + 4 x y + y^2,
  -9 - 11 epsilon + 12 x + 24 epsilon x + 12 x^2 +
    12 epsilon x^2 - 6 y - 6 epsilon y + 12 x y +
    16 epsilon x y + 3 y^2 + 5 epsilon y^2
};

gaugeDenominator = Times @@ doublePoleFactors;
degreeX = Exponent[gaugeDenominator, x];
degreeY = Exponent[gaugeDenominator, y];
gaugeUnknownCount = 4*2*(degreeX + 1)*(degreeY + 1);
unknownCount = gaugeUnknownCount + Length[freeResidues];

forcingConstant = forcing /. Thread[freeResidues -> 0];
forcingCoefficients = Table[
  Map[Coefficient[#, residue] &, forcing, {3}],
  {residue, freeResidues}
];

ClearAll[modNumber];
modNumber[value_] := Module[{numeratorValue, denominatorValue},
  If[! FreeQ[value, _Symbol], Throw[$Failed, "BadCoefficient"]];
  numeratorValue = Mod[Numerator[value], prime];
  denominatorValue = Mod[Denominator[value], prime];
  If[denominatorValue === 0, Throw[$Failed, "BadCoefficient"]];
  Mod[numeratorValue PowerMod[denominatorValue, -1, prime], prime]
];

ClearAll[polynomialRules];
polynomialRules[polynomial_] :=
  ({First[#], modNumber[Last[#]]} &) /@
    (List @@@ CoefficientRules[polynomial, {x, y}]);

ClearAll[rationalForm];
rationalForm[expression_] := Module[{q},
  q = Together[expression];
  {polynomialRules[Numerator[q]], polynomialRules[Denominator[q]]}
];

ClearAll[evaluatePolynomial];
evaluatePolynomial[rules_List, xValue_Integer, yValue_Integer] := Mod[
  Total[
    (#[[2]] PowerMod[Mod[xValue, prime], #[[1, 1]], prime]*
        PowerMod[Mod[yValue, prime], #[[1, 2]], prime]) & /@ rules
  ],
  prime
];

ClearAll[evaluateRational];
evaluateRational[form_List, xValue_Integer, yValue_Integer] := Module[
  {numeratorValue, denominatorValue},
  numeratorValue = evaluatePolynomial[form[[1]], xValue, yValue];
  denominatorValue = evaluatePolynomial[form[[2]], xValue, yValue];
  If[denominatorValue === 0, Throw[$Failed, "BadPoint"]];
  Mod[numeratorValue PowerMod[denominatorValue, -1, prime], prime]
];

{preprocessingSeconds, preprocessedForms} = AbsoluteTiming[{
  Map[rationalForm, e /. epsilon -> epsilonValue, {3}],
  Map[rationalForm, c /. epsilon -> epsilonValue, {3}],
  Map[rationalForm, forcingConstant /. epsilon -> epsilonValue, {3}],
  Table[
    Map[rationalForm,
      forcingCoefficients[[residueIndex]] /. epsilon -> epsilonValue,
      {3}],
    {residueIndex, Length[freeResidues]}
  ],
  rationalForm[gaugeDenominator /. epsilon -> epsilonValue],
  {
    rationalForm[D[gaugeDenominator, x] /. epsilon -> epsilonValue],
    rationalForm[D[gaugeDenominator, y] /. epsilon -> epsilonValue]
  }
}];
{
  eForms, cForms, forcingConstantForms, forcingCoefficientForms,
  gaugeDenominatorForm, gaugeDenominatorDerivativeForms
} = preprocessedForms;

ClearAll[columnIndex];
columnIndex[i_, j_, px_, py_] :=
  (((i - 1)*2 + (j - 1))*(degreeX + 1) + px)*(degreeY + 1) +
    py + 1;

ClearAll[buildPointRows];
buildPointRows[xValue_Integer, yValue_Integer] := Catch[
  Module[
    {eValue, cValue, forcing0Value, forcingFreeValue,
      denominatorValue, derivativeDenominatorValues, inverseDenominator,
      xPowers, yPowers, phi, derivativePhi, rows, rightHandSide,
      rowIndex, row, coefficient, column, mu, i, j, aIndex, bIndex,
      px, py, residueIndex},

    eValue = Map[evaluateRational[#, xValue, yValue] &, eForms, {3}];
    cValue = Map[evaluateRational[#, xValue, yValue] &, cForms, {3}];
    forcing0Value =
      Map[evaluateRational[#, xValue, yValue] &,
        forcingConstantForms, {3}];
    forcingFreeValue = Table[
      Map[evaluateRational[#, xValue, yValue] &,
        forcingCoefficientForms[[residueIndex]], {3}],
      {residueIndex, Length[freeResidues]}
    ];

    denominatorValue =
      evaluateRational[gaugeDenominatorForm, xValue, yValue];
    inverseDenominator = PowerMod[denominatorValue, -1, prime];
    derivativeDenominatorValues =
      evaluateRational[#, xValue, yValue] & /@
        gaugeDenominatorDerivativeForms;

    xPowers = Table[PowerMod[Mod[xValue, prime], power, prime],
      {power, 0, degreeX}];
    yPowers = Table[PowerMod[Mod[yValue, prime], power, prime],
      {power, 0, degreeY}];
    phi = Table[
      Mod[xPowers[[px + 1]] yPowers[[py + 1]] inverseDenominator,
        prime],
      {px, 0, degreeX}, {py, 0, degreeY}
    ];
    derivativePhi = Table[
      Mod[
        If[mu === 1,
          If[px === 0, 0,
            px xPowers[[px]] yPowers[[py + 1]]] inverseDenominator,
          If[py === 0, 0,
            py xPowers[[px + 1]] yPowers[[py]]] inverseDenominator
        ] - phi[[px + 1, py + 1]]*
          derivativeDenominatorValues[[mu]]*inverseDenominator,
        prime
      ],
      {mu, 2}, {px, 0, degreeX}, {py, 0, degreeY}
    ];

    rows = ConstantArray[0, {16, unknownCount}];
    rightHandSide = ConstantArray[0, 16];
    rowIndex = 0;
    Do[
      rowIndex++;
      row = rows[[rowIndex]];

      Do[
        column = columnIndex[i, j, px, py];
        row[[column]] = derivativePhi[[mu, px + 1, py + 1]],
        {px, 0, degreeX}, {py, 0, degreeY}
      ];

      Do[
        Do[
          column = columnIndex[aIndex, j, px, py];
          coefficient = -epsilonMod*eValue[[mu, i, aIndex]]*
            phi[[px + 1, py + 1]];
          row[[column]] = Mod[row[[column]] + coefficient, prime],
          {px, 0, degreeX}, {py, 0, degreeY}
        ],
        {aIndex, 4}
      ];

      Do[
        Do[
          column = columnIndex[i, bIndex, px, py];
          coefficient = epsilonMod*phi[[px + 1, py + 1]]*
            cValue[[mu, bIndex, j]];
          row[[column]] = Mod[row[[column]] + coefficient, prime],
          {px, 0, degreeX}, {py, 0, degreeY}
        ],
        {bIndex, 2}
      ];

      Do[
        row[[gaugeUnknownCount + residueIndex]] =
          Mod[-forcingFreeValue[[residueIndex, mu, i, j]], prime],
        {residueIndex, Length[freeResidues]}
      ];

      rows[[rowIndex]] = row;
      rightHandSide[[rowIndex]] = forcing0Value[[mu, i, j]],
      {mu, 2}, {i, 4}, {j, 2}
    ];

    {SparseArray[rows], rightHandSide}
  ],
  "BadPoint"
];

SeedRandom[2540908];
pointRows = {};
pointRightHandSides = {};
acceptedPoints = {};
attemptCount = 0;

Print["Gauge denominator degrees: ", {degreeX, degreeY}];
Print["Unknowns: ", unknownCount, " = ", gaugeUnknownCount,
  " gauge + ", Length[freeResidues], " residue"];
Print["Rational-coefficient preprocessing seconds: ",
  preprocessingSeconds];

{samplingSeconds, samplingResult} = AbsoluteTiming[
  While[Length[acceptedPoints] < requestedPointCount,
    attemptCount++;
    point = RandomInteger[{2, prime - 2}, 2];
    pointResult = buildPointRows @@ point;
    If[pointResult =!= $Failed,
      AppendTo[acceptedPoints, point];
      AppendTo[pointRows, pointResult[[1]]];
      AppendTo[pointRightHandSides, pointResult[[2]]]
    ];
    If[Mod[Length[acceptedPoints], 10] === 0 &&
        Length[acceptedPoints] > 0,
      Print["Accepted points: ", Length[acceptedPoints], "/",
        requestedPointCount]
    ]
  ]
];

matrix = Join @@ pointRows;
rightHandSide = Join @@ pointRightHandSides;
augmented = Join[matrix, SparseArray[List /@ rightHandSide], 2];

Print["Sample matrix dimensions: ", Dimensions[matrix],
  ", nonzero entries: ", Length[matrix["NonzeroValues"]],
  ", sampling seconds: ", samplingSeconds];

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
      AllTrue[
        Flatten[Mod[matrix.Transpose[nullspaceBasis], prime]],
        # === 0 &]
  |>;
];

result = <|
  "EpsilonValue" -> epsilonValue,
  "Prime" -> prime,
  "AcceptedPoints" -> acceptedPoints,
  "AttemptCount" -> attemptCount,
  "MatrixDimensions" -> Dimensions[matrix],
  "NonzeroEntries" -> Length[matrix["NonzeroValues"]],
  "Rank" -> rank,
  "AugmentedRank" -> augmentedRank,
  "Nullity" -> unknownCount - rank,
  "Consistent" -> TrueQ[rank === augmentedRank],
  "SamplingSeconds" -> samplingSeconds,
  "RankSeconds" -> rankSeconds,
  "AugmentedRankSeconds" -> augmentedRankSeconds
|> ~Join~ affineData;

Put[result, outputPath];
Print[KeyDrop[result, {"AcceptedPoints", "ParticularSolution",
  "NullspaceBasis"}]];
