sourceDirectory =
  "/home/maxzhang/factorization-and-loops/Codex/" <>
    "TwoRootSharpSimultaneous";
auditDirectory = DirectoryName[$InputFileName];

finiteFlowRoot =
  "/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/" <>
    "PackageEvaluation/ExternalTools/finiteflow";
$FiniteFlowLibPath =
  FileNameJoin[{finiteFlowRoot, "install", "mathlink"}];
$LibraryPath = Prepend[
  DeleteCases[$LibraryPath, $FiniteFlowLibPath],
  $FiniteFlowLibPath
];
AppendTo[$Path, FileNameJoin[{finiteFlowRoot, "mathlink"}]];
Get[FileNameJoin[{finiteFlowRoot, "mathlink", "FiniteFlow.m"}]];

threePrimes = {1000003, 2147483647, 2147483629};
fourthPrime = 2147483587;
allPrimes = Append[threePrimes, fourthPrime];

interpolationPath[p_Integer] := FileNameJoin[{sourceDirectory,
    "CF254_9_8_epsilon_interpolation_mod_" <> ToString[p] <> ".wl"}];
samplePattern[p_Integer] := FileNameJoin[{sourceDirectory,
    "CF254_9_8_point_sample_rank_*_p" <> ToString[p] <> ".wl"}];

threeInterpolations = Get /@ (interpolationPath /@ threePrimes);
normalizationColumns = First[threeInterpolations]["NormalizationColumns"];

ClearAll[modRational];
modRational[value_, p_Integer] := Mod[
  Numerator[value] PowerMod[Mod[Denominator[value], p], -1, p],
  p
];

ClearAll[evaluateCoefficientList];
evaluateCoefficientList[coefficients_List, value_Integer, p_Integer] :=
  Fold[Mod[#1 value + #2, p] &, 0, Reverse[coefficients]];

ClearAll[polynomialFromCoefficientList];
polynomialFromCoefficientList[coefficients_List, variable_] :=
  FromDigits[Reverse[coefficients], variable];

ClearAll[canonicalParticular];
canonicalParticular[data_Association, columns_List, p_Integer] := Module[
  {particular, nullspace, normalizationBlock, parameters},
  particular = data["ParticularSolution"];
  nullspace = Normal[data["NullspaceBasis"]];
  normalizationBlock = nullspace[[All, columns]];
  parameters = LinearSolve[
    Transpose[normalizationBlock],
    Mod[-particular[[columns]], p],
    Modulus -> p
  ];
  Mod[particular + Transpose[nullspace].parameters, p]
];

ClearAll[interpolationValue];
interpolationValue[data_Association, epsilonValue_Integer, p_Integer] :=
  Module[{numerator, denominator},
    numerator = evaluateCoefficientList[
      data["Numerator"], epsilonValue, p];
    denominator = evaluateCoefficientList[
      data["Denominator"], epsilonValue, p];
    If[denominator === 0, Return[Indeterminate]];
    Mod[numerator PowerMod[denominator, -1, p], p]
  ];

ClearAll[loadCanonicalSamples];
loadCanonicalSamples[p_Integer] := Module[{records},
  records = Select[
    Get /@ Sort[FileNames[samplePattern[p]]],
    TrueQ[#Consistent] && TrueQ[#ParticularCheckZero] &&
      TrueQ[#NullspaceCheckZero] &&
      KeyExistsQ[#, "ParticularSolution"] &
  ];
  DeleteDuplicatesBy[
    (<|
       "EpsilonValue" -> #["EpsilonValue"],
       "EpsilonMod" -> modRational[#["EpsilonValue"], p],
       "Values" -> canonicalParticular[#, normalizationColumns, p]
     |> &) /@ records,
    #["EpsilonMod"] &
  ]
];

ClearAll[checkSavedInterpolation];
checkSavedInterpolation[data_Association] := Module[
  {p, samples, interpolatedValues},
  p = data["Prime"];
  samples = loadCanonicalSamples[p];
  interpolatedValues = Table[
    interpolationValue[coordinate, sample["EpsilonMod"], p],
    {sample, samples}, {coordinate, data["Interpolations"]}
  ];
  <|
    "Prime" -> p,
    "SavedSampleCount" -> Length[samples],
    "CoordinateCount" -> Length[data["Interpolations"]],
    "NormalizedCoordinatesAreZero" ->
      AllTrue[samples,
        AllTrue[#["Values"][[normalizationColumns]],
          Function[value, value === 0]] &],
    "AllSavedSamplesReproduced" ->
      TrueQ[interpolatedValues === (#Values & /@ samples)]
  |>
];

ClearAll[reducedPolynomialPairQ];
reducedPolynomialPairQ[data_Association, p_Integer] := Module[
  {z, numerator, denominator},
  numerator = polynomialFromCoefficientList[data["Numerator"], z];
  denominator = polynomialFromCoefficientList[data["Denominator"], z];
  Last[data["Denominator"]] === 1 &&
    PolynomialGCD[numerator, denominator, Modulus -> p] === 1
];

ClearAll[combineCoefficientLists];
combineCoefficientLists[lists_List, length_Integer, primes_List] := Table[
  ChineseRemainder[
    Table[PadRight[lists[[k]], length][[index]], {k, Length[lists]}],
    primes
  ],
  {index, length}
];

ClearAll[combineInterpolationCoordinate];
combineInterpolationCoordinate[data_List, primes_List] := Module[
  {degrees, numeratorLength, denominatorLength},
  degrees = data[[All, "Degrees"]];
  If[Length[DeleteDuplicates[degrees]] =!= 1, Return[$Failed]];
  numeratorLength = If[First[degrees][[1]] === -Infinity,
    1, First[degrees][[1]] + 1];
  denominatorLength = First[degrees][[2]] + 1;
  <|
    "Numerator" -> combineCoefficientLists[
      data[[All, "Numerator"]], numeratorLength, primes],
    "Denominator" -> combineCoefficientLists[
      data[[All, "Denominator"]], denominatorLength, primes],
    "Degrees" -> First[degrees]
  |>
];

ClearAll[crtResiduesCorrectQ];
crtResiduesCorrectQ[combined_Association, data_List, primes_List] :=
  And @@ Flatten@Table[
    And[
      Mod[combined["Numerator"], primes[[k]]] ===
        PadRight[data[[k, "Numerator"]], Length[combined["Numerator"]]],
      Mod[combined["Denominator"], primes[[k]]] ===
        PadRight[data[[k, "Denominator"]],
          Length[combined["Denominator"]]]
    ],
    {k, Length[primes]}
  ];

ClearAll[interpolateAtKnownDegrees];
interpolateAtKnownDegrees[degreePair_List, values_List, p_Integer] := Module[
  {numeratorDegree, denominatorDegree, unknownCount, construction,
    matrix, rightHandSide, solution, numerator, denominator, result},
  If[degreePair[[1]] === -Infinity,
    If[AllTrue[values, #[[2]] === 0 &],
      Return[<|"Numerator" -> {0}, "Denominator" -> {1},
        "Degrees" -> {-Infinity, 0}|>],
      Return[$Failed]
    ]
  ];
  {numeratorDegree, denominatorDegree} = degreePair;
  unknownCount = numeratorDegree + denominatorDegree + 1;
  If[Length[values] <= unknownCount, Return[$Failed]];
  construction = Take[values, unknownCount];
  matrix = Table[
    Join[
      Table[PowerMod[datum[[1]], power, p],
        {power, 0, numeratorDegree}],
      Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, p], p],
        {power, 0, denominatorDegree - 1}]
    ],
    {datum, construction}
  ];
  rightHandSide = Table[
    Mod[datum[[2]] PowerMod[datum[[1]], denominatorDegree, p], p],
    {datum, construction}
  ];
  solution = LinearSolve[matrix, rightHandSide, Modulus -> p];
  numerator = Take[solution, numeratorDegree + 1];
  denominator = Join[Drop[solution, numeratorDegree + 1], {1}];
  result = <|
    "Numerator" -> Mod[numerator, p],
    "Denominator" -> Mod[denominator, p],
    "Degrees" -> degreePair
  |>;
  If[AllTrue[values,
      interpolationValue[result, #[[1]], p] === #[[2]] &],
    result,
    $Failed
  ]
];

ClearAll[constructFourthPrimeInterpolation];
constructFourthPrimeInterpolation[] := Module[
  {samples, referenceDegrees, interpolations},
  samples = loadCanonicalSamples[fourthPrime];
  referenceDegrees =
    (#Degrees &) /@ First[threeInterpolations]["Interpolations"];
  interpolations = Table[
    interpolateAtKnownDegrees[
      referenceDegrees[[coordinate]],
      ({#["EpsilonMod"], #["Values"][[coordinate]]} &) /@ samples,
      fourthPrime
    ],
    {coordinate, Length[referenceDegrees]}
  ];
  <|
    "Prime" -> fourthPrime,
    "SampleCount" -> Length[samples],
    "ConstructionCount" -> 5,
    "ValidationCount" -> Length[samples] - 5,
    "NormalizationColumns" -> normalizationColumns,
    "UnresolvedCoordinates" -> Flatten[Position[interpolations, $Failed]],
    "DegreeHistogram" -> Counts[Cases[interpolations,
      association_Association :> association["Degrees"]]],
    "Interpolations" -> interpolations
  |>
];

ClearAll[liftInterpolation];
liftInterpolation[data_Association, modulus_Integer, variable_] := Module[
  {numeratorCoefficients, denominatorCoefficients},
  numeratorCoefficients = FiniteFlow`FFRatRec[#, modulus] & /@
    data["Numerator"];
  denominatorCoefficients = FiniteFlow`FFRatRec[#, modulus] & /@
    data["Denominator"];
  Together[
    polynomialFromCoefficientList[numeratorCoefficients, variable]/
      polynomialFromCoefficientList[denominatorCoefficients, variable]
  ]
];

ClearAll[rawLiftCongruenceQ];
rawLiftCongruenceQ[combined_Association, data_List, primes_List,
    modulus_Integer] := Module[
  {liftedNumerator, liftedDenominator},
  liftedNumerator = FiniteFlow`FFRatRec[#, modulus] & /@
    combined["Numerator"];
  liftedDenominator = FiniteFlow`FFRatRec[#, modulus] & /@
    combined["Denominator"];
  And @@ Flatten@Table[
    And[
      (modRational[#, primes[[k]]] & /@ liftedNumerator) ===
        PadRight[data[[k, "Numerator"]], Length[liftedNumerator]],
      (modRational[#, primes[[k]]] & /@ liftedDenominator) ===
        PadRight[data[[k, "Denominator"]], Length[liftedDenominator]]
    ],
    {k, Length[primes]}
  ]
];

primeChecks = <|
  "AllPrimeQ" -> And @@ (PrimeQ /@ allPrimes),
  "PairwiseCoprimeQ" ->
    And @@ Flatten[Table[
      If[i < j, CoprimeQ[allPrimes[[i]], allPrimes[[j]]], True],
      {i, Length[allPrimes]}, {j, Length[allPrimes]}]],
  "Primes" -> allPrimes
|>;

normalizationChecks = <|
  "IdenticalNormalizationColumns" ->
    Length[DeleteDuplicates[
      threeInterpolations[[All, "NormalizationColumns"]]]] === 1,
  "NormalizationColumns" -> normalizationColumns,
  "NormalizedCoordinatesAreResidues" ->
    SubsetQ[Range[969, 977], normalizationColumns],
  "CoordinateCount" ->
    Length[First[threeInterpolations]["Interpolations"]]
|>;

orderingChecks = <|
  "GaugeColumnMapIsBijection" ->
    Flatten[Table[
      (((i - 1)*2 + (j - 1))*11 + px)*11 + py + 1,
      {i, 4}, {j, 2}, {px, 0, 10}, {py, 0, 10}
    ]] === Range[968],
  "LowToHighPolynomialConvention" ->
    polynomialFromCoefficientList[{3, 5, 7}, z] === 3 + 5 z + 7 z^2 &&
      evaluateCoefficientList[{3, 5, 7}, 11, 1000003] ===
        Mod[3 + 5*11 + 7*11^2, 1000003]
|>;

savedInterpolationChecks = checkSavedInterpolation /@ threeInterpolations;
polynomialChecks = Table[
  <|
    "Prime" -> data["Prime"],
    "AllDenominatorsMonicAndPairsReduced" ->
      AllTrue[data["Interpolations"],
        reducedPolynomialPairQ[#, data["Prime"]] &]
  |>,
  {data, threeInterpolations}
];

combinedThree = Table[
  combineInterpolationCoordinate[
    threeInterpolations[[All, "Interpolations", coordinate]],
    threePrimes
  ],
  {coordinate, Length[First[threeInterpolations]["Interpolations"]]}
];
crtChecks = <|
  "ThreePrimeCRTRecoversEveryInputResidue" ->
    And @@ Table[
      crtResiduesCorrectQ[
        combinedThree[[coordinate]],
        threeInterpolations[[All, "Interpolations", coordinate]],
        threePrimes
      ],
      {coordinate, Length[combinedThree]}
    ]
|>;

syntheticRationals = {-7/13, 1234567/891011, 1/4, -17, 0};
threePrimeModulus = Times @@ threePrimes;
syntheticLiftChecks = Table[
  residues = modRational[value, #] & /@ threePrimes;
  crtValue = ChineseRemainder[residues, threePrimes];
  <|
    "Input" -> value,
    "Reconstructed" -> FiniteFlow`FFRatRec[crtValue, threePrimeModulus],
    "Equal" ->
      TrueQ[FiniteFlow`FFRatRec[crtValue, threePrimeModulus] === value]
  |>,
  {value, syntheticRationals}
];

threePrimeRawLiftCongruence = And @@ Table[
  rawLiftCongruenceQ[
    combinedThree[[coordinate]],
    threeInterpolations[[All, "Interpolations", coordinate]],
    threePrimes,
    threePrimeModulus
  ],
  {coordinate, Length[combinedThree]}
];

fourthInterpolation = constructFourthPrimeInterpolation[];
Put[fourthInterpolation,
  FileNameJoin[{auditDirectory,
    "CF254_9_8_epsilon_interpolation_mod_2147483587_from_saved_samples.wl"}]];

allInterpolations = Append[threeInterpolations, fourthInterpolation];
combinedFour = Table[
  combineInterpolationCoordinate[
    allInterpolations[[All, "Interpolations", coordinate]],
    allPrimes
  ],
  {coordinate, Length[First[allInterpolations]["Interpolations"]]}
];
fourPrimeModulus = Times @@ allPrimes;
epsilonVariable = Unique["epsilon"];
fourPrimeLiftedVector =
  liftInterpolation[#, fourPrimeModulus, epsilonVariable] & /@ combinedFour;

recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_8_unsolved.wl";
residuePath = FileNameJoin[{sourceDirectory,
    "CF254_9_8_residue_data.wl"}];
record = Get[recordPath];
residueData = Get[residuePath];
{x, y} = record["Variables"];
epsilon = record["Regulator"];
{e, c, bbar} = record["Strip"];
forcing = residueData["Forcing"];
freeResidues = residueData["FreeResidues"];
fourPrimeLiftedVector =
  fourPrimeLiftedVector /. epsilonVariable -> epsilon;

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

ClearAll[columnIndex];
columnIndex[i_, j_, px_, py_] :=
  (((i - 1)*2 + (j - 1))*11 + px)*11 + py + 1;

fourPrimeGauge = Table[
  Sum[
    fourPrimeLiftedVector[[columnIndex[i, j, px, py]]] x^px y^py,
    {px, 0, 10}, {py, 0, 10}
  ]/gaugeDenominator,
  {i, 4}, {j, 2}
];
fourPrimeResidueRules =
  Thread[freeResidues -> fourPrimeLiftedVector[[969 ;; 977]]];
fourPrimeGaugeDerivatives = {D[fourPrimeGauge, x], D[fourPrimeGauge, y]};

quickCheckPoints = {
  {epsilon -> 1/7, x -> 2/13, y -> 3/17},
  {epsilon -> 2/9, x -> 5/19, y -> 7/23},
  {epsilon -> -3/11, x -> 11/29, y -> 13/31}
};
{fourPrimeQuickCheckSeconds, fourPrimeQuickCheckResiduals} = AbsoluteTiming[
  Table[
    Together[
      (fourPrimeGaugeDerivatives[[mu, i, j]] -
          epsilon Sum[e[[mu, i, a]] fourPrimeGauge[[a, j]], {a, 4}] +
          epsilon Sum[fourPrimeGauge[[i, b]] c[[mu, b, j]], {b, 2}] -
          (forcing[[mu, i, j]] /. fourPrimeResidueRules)) /. point
    ],
    {point, quickCheckPoints}, {mu, 2}, {i, 4}, {j, 2}
  ]
];
fourPrimeQuickChecksZero =
  Map[TrueQ[# === 0] &, fourPrimeQuickCheckResiduals, {4}];

ClearAll[residualAtPointModulo];
residualAtPointModulo[epsilonRule_Rule, xValue_Integer, yValue_Integer,
    p_Integer] := Table[
  value = Together[
    (fourPrimeGaugeDerivatives[[mu, i, j]] -
        epsilon Sum[e[[mu, i, a]] fourPrimeGauge[[a, j]], {a, 4}] +
        epsilon Sum[fourPrimeGauge[[i, b]] c[[mu, b, j]], {b, 2}] -
        (forcing[[mu, i, j]] /. fourPrimeResidueRules)) /.
      {epsilonRule, x -> xValue, y -> yValue}
  ];
  modRational[value, p],
  {mu, 2}, {i, 4}, {j, 2}
];

alignmentPrime = 1000003;
alignmentSample = Get[FileNameJoin[{sourceDirectory,
    "CF254_9_8_point_sample_rank_1_7_p1000003.wl"}]];
alignmentAcceptedPoint = First[alignmentSample["AcceptedPoints"]];
alignmentFreshPoint = {
  modRational[2/13, alignmentPrime],
  modRational[3/17, alignmentPrime]
};
acceptedPointResidualModulo = residualAtPointModulo[
  epsilon -> 1/7,
  alignmentAcceptedPoint[[1]], alignmentAcceptedPoint[[2]],
  alignmentPrime
];
freshPointResidualModulo = residualAtPointModulo[
  epsilon -> 1/7,
  alignmentFreshPoint[[1]], alignmentFreshPoint[[2]],
  alignmentPrime
];
alignmentChecks = <|
  "Prime" -> alignmentPrime,
  "AcceptedPoint" -> alignmentAcceptedPoint,
  "AcceptedPointResidualZero" ->
    AllTrue[Flatten[acceptedPointResidualModulo], # === 0 &],
  "FreshPoint" -> alignmentFreshPoint,
  "FreshPointResidualZero" ->
    AllTrue[Flatten[freshPointResidualModulo], # === 0 &],
  "AcceptedPointNonzeroComponentCount" ->
    Count[Flatten[acceptedPointResidualModulo], Except[0]],
  "FreshPointNonzeroComponentCount" ->
    Count[Flatten[freshPointResidualModulo], Except[0]]
|>;

storedFivePrimeCandidate = Get[FileNameJoin[{sourceDirectory,
    "CF254_9_8_lifted_candidate.wl"}]];
changedCoordinates = Count[
  MapThread[TrueQ[#1 =!= #2] &,
    {storedFivePrimeCandidate["LiftedVector"], fourPrimeLiftedVector}],
  True
];

summary = <|
  "PrimeChecks" -> primeChecks,
  "NormalizationChecks" -> normalizationChecks,
  "OrderingChecks" -> orderingChecks,
  "SavedInterpolationChecks" -> savedInterpolationChecks,
  "PolynomialChecks" -> polynomialChecks,
  "CRTChecks" -> crtChecks,
  "SyntheticLiftChecks" -> syntheticLiftChecks,
  "ThreePrimeRawLiftPreservesAllCRTResidues" ->
    threePrimeRawLiftCongruence,
  "FourthPrimeSampleCount" -> fourthInterpolation["SampleCount"],
  "FourthPrimeUnresolvedCoordinates" ->
    fourthInterpolation["UnresolvedCoordinates"],
  "FourthPrimeDegreeHistogram" -> fourthInterpolation["DegreeHistogram"],
  "ThreePrimeModulus" -> threePrimeModulus,
  "FourPrimeModulus" -> fourPrimeModulus,
  "CoordinatesChangedByFourthPrime" -> changedCoordinates,
  "SampleEquationAlignmentChecks" -> alignmentChecks,
  "FourPrimeQuickCheckSeconds" -> fourPrimeQuickCheckSeconds,
  "FourPrimeQuickChecksZero" -> fourPrimeQuickChecksZero,
  "FourPrimeAllQuickChecksZero" ->
    And @@ Flatten[fourPrimeQuickChecksZero]
|>;

Put[summary, FileNameJoin[{auditDirectory, "audit_result.wl"}]];
Put[<|
  "Primes" -> allPrimes,
  "CombinedModulus" -> fourPrimeModulus,
  "NormalizationColumns" -> normalizationColumns,
  "LiftedVector" -> fourPrimeLiftedVector,
  "ResidueRules" -> fourPrimeResidueRules,
  "Gauge" -> fourPrimeGauge
|>, FileNameJoin[{auditDirectory, "CF254_9_8_four_prime_candidate.wl"}]];
If[! And @@ Flatten[fourPrimeQuickChecksZero],
  Put[fourPrimeQuickCheckResiduals,
    FileNameJoin[{auditDirectory,
      "CF254_9_8_four_prime_nonzero_quick_residuals.wl"}]]
];

Print[summary];
