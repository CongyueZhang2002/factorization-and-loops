recordPath = Which[
  ValueQ[$FacetRecordPathOverride], $FacetRecordPathOverride,
  StringQ[Environment["FACET_RECORD_PATH"]] &&
    StringLength[Environment["FACET_RECORD_PATH"]] > 0,
    Environment["FACET_RECORD_PATH"],
  True,
    "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
      "sector_CF254_standard/CF254_9_7_input.wl"
];
residuePath = If[ValueQ[$FacetResiduePathOverride],
  $FacetResiduePathOverride,
  FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_7_residue_data.wl"}]];
outputPrefix = Which[
  ValueQ[$FacetOutputPrefixOverride], $FacetOutputPrefixOverride,
  StringQ[Environment["FACET_OUTPUT_PREFIX"]] &&
    StringLength[Environment["FACET_OUTPUT_PREFIX"]] > 0,
    Environment["FACET_OUTPUT_PREFIX"],
  True, "CF254_9_7"
];

ClearAll[environmentValue];
environmentValue[name_String, default_String] := Module[{value},
  value = Environment[name];
  If[StringQ[value] && StringLength[value] > 0, value, default]
];

epsilonValue = If[ValueQ[$FacetEpsilonOverride], $FacetEpsilonOverride,
  ToExpression[environmentValue["FACET_EPSILON", "1/7"]]];
prime = If[ValueQ[$FacetPrimeOverride], $FacetPrimeOverride,
  ToExpression[environmentValue["FACET_PRIME", "1000003"]]];
requestedPointCount = If[ValueQ[$FacetPointCountOverride],
  $FacetPointCountOverride,
  ToExpression[environmentValue["FACET_POINT_COUNT", "80"]]];
solveAffineQ = If[ValueQ[$FacetSolveAffineOverride],
  $FacetSolveAffineOverride,
  ToExpression[environmentValue["FACET_SOLVE_AFFINE", "False"]]];
numeratorExtraX = If[ValueQ[$FacetNumeratorExtraXOverride],
  $FacetNumeratorExtraXOverride,
  ToExpression[environmentValue["FACET_NUMERATOR_EXTRA_X", "0"]]];
numeratorExtraY = If[ValueQ[$FacetNumeratorExtraYOverride],
  $FacetNumeratorExtraYOverride,
  ToExpression[environmentValue["FACET_NUMERATOR_EXTRA_Y", "0"]]];
quietQ = If[ValueQ[$FacetQuietOverride], $FacetQuietOverride,
  ToExpression[environmentValue["FACET_QUIET", "False"]]];
rawResiduesQ = If[ValueQ[$FacetRawResiduesOverride],
  $FacetRawResiduesOverride,
  ToExpression[environmentValue["FACET_RAW_RESIDUES", "False"]]];
ClearAll[samplePrint];
samplePrint[arguments___] := If[! TrueQ[quietQ], Print[arguments]];
If[! PrimeQ[prime] || prime <= 3 ||
    ! MatchQ[epsilonValue, _Integer | _Rational] ||
    Mod[Denominator[epsilonValue], prime] === 0 ||
    ! IntegerQ[requestedPointCount] || requestedPointCount <= 0 ||
    ! IntegerQ[numeratorExtraX] || ! IntegerQ[numeratorExtraY] ||
    ! MatchQ[solveAffineQ, True | False] ||
    ! MatchQ[quietQ, True | False] ||
    ! MatchQ[rawResiduesQ, True | False],
  samplePrint["Invalid finite-field, epsilon, point-count, degree, or ",
    "Boolean input."];
  Exit[1]
];
epsilonMod = Mod[
  Numerator[epsilonValue]*
    PowerMod[Mod[Denominator[epsilonValue], prime], -1, prime],
  prime
];

outputTag = StringReplace[
  ToString[epsilonValue, InputForm] <>
    "_nx" <> ToString[numeratorExtraX] <>
    "_ny" <> ToString[numeratorExtraY] <>
    "_p" <> ToString[prime],
  {"/" -> "_", "-" -> "m", " " -> ""}
];
outputPath = FileNameJoin[{DirectoryName[$InputFileName],
    outputPrefix <> "_point_sample_rank_" <> outputTag <> ".wl"}];

record = Get[recordPath];
{x, y} = record["Variables"];
epsilon = record["Regulator"];
{e, c, bbar} = record["Strip"];
{upperDimension, lowerDimension} = Rest[Dimensions[bbar]];

If[TrueQ[rawResiduesQ],
  $feynFacetRoot = "/home/maxzhang/factorization-and-loops";
  Get[FileNameJoin[{$feynFacetRoot, "FeynFacet", "Private",
    "EpsFormStrip.wl"}]];
  alphabet = epsFormStripAlphabet[
    record["Strip"], record["Variables"], epsilon];
  If[alphabet === $Failed, samplePrint["Alphabet construction failed."]; Exit[1]];
  dlog = Table[
    Together[D[Log[alphabet[[a]]], record["Variables"][[mu]]]],
    {a, Length[alphabet]}, {mu, 2}];
  residueTriples = Flatten[
    Table[{a, i, j}, {a, Length[alphabet]},
      {i, upperDimension}, {j, lowerDimension}], 2];
  freeResidues = Array[
    Symbol["Global`rawK" <> ToString[#]] &,
    Length[residueTriples]];
  forcingConstant = bbar;
  forcingCoefficients = Map[
    Function[triple,
      With[{a = triple[[1]], i = triple[[2]], j = triple[[3]]},
        Table[
          -epsilon*dlog[[a, mu]]*
            Normal[SparseArray[{{i, j} -> 1},
              {upperDimension, lowerDimension}]],
          {mu, 2}]]],
    residueTriples],
  residueData = Get[residuePath];
  forcing = residueData["Forcing"];
  freeResidues = residueData["FreeResidues"];
  forcingConstant = forcing /. Thread[freeResidues -> 0];
  forcingCoefficients = Table[
    Map[Coefficient[#, residue] &, forcing, {3}],
    {residue, freeResidues}]
];

ClearAll[entryFactorList];
entryFactorList[entry_] := Module[{denominator},
  denominator = Denominator[Together[entry]];
  If[TrueQ[denominator === 1], {},
    Select[Rest[FactorList[denominator]],
      ! TrueQ[NumericQ[First[#]]] &]]
];
factorPairs = Flatten[entryFactorList /@ Flatten[bbar], 1];
factors = DeleteDuplicates[factorPairs[[All, 1]]];
factorPowers = Table[
  {factor, Max[Cases[factorPairs, {factor, power_} :> power]]},
  {factor, factors}
];
gaugeFactorPowers = Select[factorPowers,
  Last[#] > 1 && ! FreeQ[First[#], x | y] &];
gaugeDenominator = Times @@
  ((First[#]^(Last[#] - 1)) & /@ gaugeFactorPowers);
degreeX = Exponent[gaugeDenominator, x];
degreeY = Exponent[gaugeDenominator, y];
numeratorDegreeX = degreeX + numeratorExtraX;
numeratorDegreeY = degreeY + numeratorExtraY;
If[numeratorDegreeX < 0 || numeratorDegreeY < 0,
  samplePrint["The gauge numerator degrees must be nonnegative."];
  Exit[1]
];
equationCount = 2*upperDimension*lowerDimension;
gaugeUnknownCount = upperDimension*lowerDimension*(numeratorDegreeX + 1)*
  (numeratorDegreeY + 1);
unknownCount = gaugeUnknownCount + Length[freeResidues];

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
  (((i - 1)*lowerDimension + (j - 1))*(numeratorDegreeX + 1) + px)*
    (numeratorDegreeY + 1) +
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
      {power, 0, numeratorDegreeX}];
    yPowers = Table[PowerMod[Mod[yValue, prime], power, prime],
      {power, 0, numeratorDegreeY}];
    phi = Table[
      Mod[xPowers[[px + 1]] yPowers[[py + 1]] inverseDenominator,
        prime],
      {px, 0, numeratorDegreeX}, {py, 0, numeratorDegreeY}
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
      {mu, 2}, {px, 0, numeratorDegreeX},
      {py, 0, numeratorDegreeY}
    ];

    rows = ConstantArray[0, {equationCount, unknownCount}];
    rightHandSide = ConstantArray[0, equationCount];
    rowIndex = 0;
    Do[
      rowIndex++;
      row = rows[[rowIndex]];

      Do[
        column = columnIndex[i, j, px, py];
        row[[column]] = derivativePhi[[mu, px + 1, py + 1]],
        {px, 0, numeratorDegreeX}, {py, 0, numeratorDegreeY}
      ];

      Do[
        Do[
          column = columnIndex[aIndex, j, px, py];
          coefficient = -epsilonMod*eValue[[mu, i, aIndex]]*
            phi[[px + 1, py + 1]];
          row[[column]] = Mod[row[[column]] + coefficient, prime],
          {px, 0, numeratorDegreeX}, {py, 0, numeratorDegreeY}
        ],
        {aIndex, upperDimension}
      ];

      Do[
        Do[
          column = columnIndex[i, bIndex, px, py];
          coefficient = epsilonMod*phi[[px + 1, py + 1]]*
            cValue[[mu, bIndex, j]];
          row[[column]] = Mod[row[[column]] + coefficient, prime],
          {px, 0, numeratorDegreeX}, {py, 0, numeratorDegreeY}
        ],
        {bIndex, lowerDimension}
      ];

      Do[
        row[[gaugeUnknownCount + residueIndex]] =
          Mod[-forcingFreeValue[[residueIndex, mu, i, j]], prime],
        {residueIndex, Length[freeResidues]}
      ];

      rows[[rowIndex]] = row;
      rightHandSide[[rowIndex]] = forcing0Value[[mu, i, j]],
      {mu, 2}, {i, upperDimension}, {j, lowerDimension}
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

samplePrint["Gauge denominator degrees: ", {degreeX, degreeY}];
samplePrint["Gauge numerator degrees: ",
  {numeratorDegreeX, numeratorDegreeY}];
samplePrint["Gauge dimensions: ", {upperDimension, lowerDimension},
  "; equations per point: ", equationCount];
samplePrint["Gauge denominator factors: ", gaugeFactorPowers];
samplePrint["Unknowns: ", unknownCount, " = ", gaugeUnknownCount,
  " gauge + ", Length[freeResidues], " residue"];
samplePrint["Rational-coefficient preprocessing seconds: ",
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
      samplePrint["Accepted points: ", Length[acceptedPoints], "/",
        requestedPointCount]
    ]
  ]
];

matrix = Join @@ pointRows;
rightHandSide = Join @@ pointRightHandSides;
augmented = Join[matrix, SparseArray[List /@ rightHandSide], 2];

samplePrint["Sample matrix dimensions: ", Dimensions[matrix],
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
  "RawResidues" -> rawResiduesQ,
  "Alphabet" -> If[TrueQ[rawResiduesQ], alphabet, Missing["NotStored"]],
  "EpsilonValue" -> epsilonValue,
  "Prime" -> prime,
  "AcceptedPoints" -> acceptedPoints,
  "AttemptCount" -> attemptCount,
  "MatrixDimensions" -> Dimensions[matrix],
  "GaugeDimensions" -> {upperDimension, lowerDimension},
  "GaugeDenominator" -> gaugeDenominator,
  "GaugeDenominatorDegrees" -> {degreeX, degreeY},
  "GaugeNumeratorDegrees" -> {numeratorDegreeX, numeratorDegreeY},
  "GaugeUnknownCount" -> gaugeUnknownCount,
  "FreeResidueCount" -> Length[freeResidues],
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
$FacetLastSampleResult = result;
samplePrint[KeyDrop[result, {"AcceptedPoints", "ParticularSolution",
  "NullspaceBasis"}]];
