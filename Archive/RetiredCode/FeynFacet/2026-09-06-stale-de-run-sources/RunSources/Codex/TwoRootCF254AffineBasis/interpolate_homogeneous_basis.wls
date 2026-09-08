sourceDirectory =
  "/home/maxzhang/factorization-and-loops/Codex/" <>
    "TwoRootSharpSimultaneous";
outputDirectory = DirectoryName[$InputFileName];

ClearAll[environmentValue];
environmentValue[name_String, default_String] := Module[{value},
  value = Environment[name];
  If[StringQ[value] && StringLength[value] > 0, value, default]
];

prime = ToExpression[environmentValue["FACET_PRIME", "1000003"]];
constructionCount = ToExpression[
  environmentValue["FACET_CONSTRUCTION_COUNT", "7"]];
maximumTotalDegree = ToExpression[
  environmentValue["FACET_MAXIMUM_TOTAL_DEGREE", "5"]];
normalizationColumns = Range[969, 976];
expectedDimensions = {8, 977};

outputPath = FileNameJoin[{outputDirectory,
    "CF254_9_8_homogeneous_interpolation_mod_" <>
      ToString[prime] <> ".wl"}];
samplePaths = Sort[FileNames[
    "CF254_9_8_point_sample_rank_*_p" <> ToString[prime] <> ".wl",
    sourceDirectory]];
samples = Select[Get /@ samplePaths,
  TrueQ[#1["Consistent"]] &&
    TrueQ[#1["NullspaceCheckZero"]] &&
    KeyExistsQ[#1, "NullspaceBasis"] &];

If[Length[samples] < constructionCount + 4,
  Print["Insufficient distinct epsilon samples for prime ", prime,
    ": ", Length[samples]];
  Exit[1]
];

ClearAll[epsilonMod];
epsilonMod[value_] := Mod[
  Numerator[value] PowerMod[Mod[Denominator[value], prime], -1, prime],
  prime
];

ClearAll[canonicalNullspace];
canonicalNullspace[data_Association] := Module[
  {nullspace, residueBlock, canonical},
  nullspace = Normal[data["NullspaceBasis"]];
  If[Dimensions[nullspace] =!= expectedDimensions, Return[$Failed]];
  residueBlock = nullspace[[All, normalizationColumns]];
  If[MatrixRank[residueBlock, Modulus -> prime] =!= 8,
    Return[$Failed]
  ];
  canonical = Mod[
    LinearSolve[residueBlock, nullspace, Modulus -> prime],
    prime
  ];
  If[canonical[[All, normalizationColumns]] =!= IdentityMatrix[8],
    Return[$Failed]
  ];
  canonical
];

canonicalSamples = Table[
  basis = canonicalNullspace[sample];
  If[basis === $Failed,
    Print["Residue-coordinate normalization failed at epsilon = ",
      sample["EpsilonValue"]];
    Exit[1]
  ];
  <|
    "EpsilonValue" -> sample["EpsilonValue"],
    "EpsilonMod" -> epsilonMod[sample["EpsilonValue"]],
    "Values" -> Flatten[basis]
  |>,
  {sample, samples}
];
canonicalSamples = DeleteDuplicatesBy[canonicalSamples, #1["EpsilonMod"] &];

If[Length[canonicalSamples] < constructionCount + 4,
  Print["Insufficient distinct modular epsilon values for prime ", prime,
    ": ", Length[canonicalSamples]];
  Exit[1]
];

ClearAll[evaluateCoefficientList];
evaluateCoefficientList[coefficients_List, value_Integer] := Fold[
  Mod[#1 value + #2, prime] &,
  0,
  Reverse[coefficients]
];

ClearAll[trimCoefficientList];
trimCoefficientList[coefficients_List] := Module[{positions},
  positions = Select[Range[Length[coefficients]],
    coefficients[[#1]] =!= 0 &];
  If[positions === {}, {0}, Take[coefficients, Last[positions]]]
];

ClearAll[reduceRationalPair];
reduceRationalPair[numeratorInput_List, denominatorInput_List] := Module[
  {z, numerator, denominator, divisor, normalization,
    numeratorCoefficients, denominatorCoefficients},
  numerator = FromDigits[Reverse[numeratorInput], z];
  denominator = FromDigits[Reverse[denominatorInput], z];
  divisor = PolynomialGCD[numerator, denominator, Modulus -> prime];
  numerator = PolynomialQuotient[numerator, divisor, z,
    Modulus -> prime];
  denominator = PolynomialQuotient[denominator, divisor, z,
    Modulus -> prime];
  numeratorCoefficients = trimCoefficientList[
    Mod[CoefficientList[numerator, z], prime]];
  denominatorCoefficients = trimCoefficientList[
    Mod[CoefficientList[denominator, z], prime]];
  normalization = PowerMod[Last[denominatorCoefficients], -1, prime];
  {
    Mod[normalization numeratorCoefficients, prime],
    Mod[normalization denominatorCoefficients, prime]
  }
];

ClearAll[candidateValidQ];
candidateValidQ[pair_List, data_List] := AllTrue[data,
  Function[datum,
    Module[{numerator, denominator},
      numerator = evaluateCoefficientList[pair[[1]], datum[[1]]];
      denominator = evaluateCoefficientList[pair[[2]], datum[[1]]];
      denominator =!= 0 &&
        Mod[numerator - datum[[2]] denominator, prime] === 0
    ]
  ]
];

ClearAll[interpolateCoordinate];
interpolateCoordinate[data_List] := Catch[Module[
  {construction, validation, totalDegree, numeratorDegree,
    denominatorDegree, matrix, nullspace, pair},

  If[AllTrue[data, Last[#1] === 0 &],
    Throw[<|
      "Numerator" -> {0},
      "Denominator" -> {1},
      "Degrees" -> {-Infinity, 0}
    |>, "Found"]
  ];

  construction = Take[data, constructionCount];
  validation = Drop[data, constructionCount];

  Do[
    denominatorDegree = totalDegree - numeratorDegree;
    matrix = Table[
      Join[
        Table[PowerMod[datum[[1]], power, prime],
          {power, 0, numeratorDegree}],
        Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime],
          prime], {power, 0, denominatorDegree}]
      ],
      {datum, construction}
    ];
    nullspace = NullSpace[matrix, Modulus -> prime];
    Do[
      If[AnyTrue[
          basisVector[[numeratorDegree + 2 ;;]], #1 =!= 0 &],
        pair = reduceRationalPair[
          basisVector[[1 ;; numeratorDegree + 1]],
          basisVector[[numeratorDegree + 2 ;;]]
        ];
        If[candidateValidQ[pair, validation],
          Throw[<|
            "Numerator" -> pair[[1]],
            "Denominator" -> pair[[2]],
            "Degrees" -> {
              Length[pair[[1]]] - 1,
              Length[pair[[2]]] - 1
            }
          |>, "Found"]
        ]
      ],
      {basisVector, nullspace}
    ],
    {totalDegree, 0, maximumTotalDegree},
    {numeratorDegree, 0, totalDegree}
  ];
  $Failed
], "Found"];

coordinateCount = Times @@ expectedDimensions;
Print["Prime: ", prime];
Print["Distinct epsilon samples: ", Length[canonicalSamples]];
Print["Canonical basis coordinates: ", coordinateCount];

{interpolationSeconds, flatInterpolations} = AbsoluteTiming[
  Table[
    If[Mod[coordinate, 977] === 0,
      Print["Interpolated basis vectors: ", coordinate/977, "/8"]
    ];
    interpolateCoordinate[
      ({#1["EpsilonMod"], #1["Values"][[coordinate]]} &) /@
        canonicalSamples
    ],
    {coordinate, coordinateCount}
  ]
];

unresolvedCoordinates = Flatten[Position[flatInterpolations, $Failed]];
degreeHistogram = Counts[
  Cases[flatInterpolations,
    association_Association :> association["Degrees"]]
];

result = <|
  "Prime" -> prime,
  "SampleCount" -> Length[canonicalSamples],
  "ConstructionCount" -> constructionCount,
  "ValidationCount" -> Length[canonicalSamples] - constructionCount,
  "MaximumTotalDegree" -> maximumTotalDegree,
  "BasisDimensions" -> expectedDimensions,
  "NormalizationColumns" -> normalizationColumns,
  "EpsilonValues" -> canonicalSamples[[All, "EpsilonValue"]],
  "InterpolationSeconds" -> interpolationSeconds,
  "UnresolvedCoordinates" -> unresolvedCoordinates,
  "DegreeHistogram" -> degreeHistogram,
  "Interpolations" -> ArrayReshape[flatInterpolations,
    expectedDimensions]
|>;

Put[result, outputPath];
Print[KeyDrop[result, "Interpolations"]];
If[unresolvedCoordinates =!= {}, Exit[1]];
