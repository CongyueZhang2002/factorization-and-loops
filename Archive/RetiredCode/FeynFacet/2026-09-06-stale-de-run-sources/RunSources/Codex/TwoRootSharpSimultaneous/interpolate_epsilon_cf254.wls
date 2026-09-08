directory = DirectoryName[$InputFileName];
ClearAll[environmentValue];
environmentValue[name_String, default_String] := Module[{value},
  value = Environment[name];
  If[StringQ[value] && StringLength[value] > 0, value, default]
];

prime = ToExpression[environmentValue["FACET_PRIME", "1000003"]];
constructionCount = ToExpression[
  environmentValue["FACET_CONSTRUCTION_COUNT", "24"]];
maximumTotalDegree = ToExpression[
  environmentValue["FACET_MAXIMUM_TOTAL_DEGREE", "22"]];
outputPath = FileNameJoin[{directory,
    "CF254_9_8_epsilon_interpolation_mod_" <> ToString[prime] <> ".wl"}];

files = Sort[FileNames[
    "CF254_9_8_point_sample_rank_*_p" <> ToString[prime] <> ".wl",
    directory
  ]];
samples = Select[Get /@ files,
  TrueQ[#Consistent] && KeyExistsQ[#, "ParticularSolution"] &];

ClearAll[independentColumns];
independentColumns[matrix_List, modulus_Integer] := Module[
  {columns = {}, rank = 0, trialRank},
  Do[
    trialRank = MatrixRank[matrix[[All, Append[columns, column]]],
      Modulus -> modulus];
    If[trialRank > rank,
      AppendTo[columns, column];
      rank = trialRank
    ];
    If[rank === Length[matrix], Break[]],
    {column, Length[First[matrix]]}
  ];
  columns
];

ClearAll[canonicalParticular];
canonicalParticular[data_Association, columns_List] := Module[
  {particular, nullspace, block, parameters},
  particular = data["ParticularSolution"];
  nullspace = Normal[data["NullspaceBasis"]];
  block = nullspace[[All, columns]];
  parameters = LinearSolve[
    Transpose[block],
    Mod[-particular[[columns]], prime],
    Modulus -> prime
  ];
  Mod[particular + Transpose[nullspace].parameters, prime]
];

ClearAll[epsilonMod];
epsilonMod[value_] := Mod[
  Numerator[value] PowerMod[Mod[Denominator[value], prime], -1, prime],
  prime
];

referenceNullspace = Normal[First[samples]["NullspaceBasis"]];
normalizationColumns =
  independentColumns[referenceNullspace[[All, 969 ;; 977]], prime] + 968;
If[Length[normalizationColumns] =!= Length[referenceNullspace],
  Print["Residue coordinates do not span the affine freedom."];
  Exit[1]
];

canonicalSamples = Table[
  <|
    "EpsilonValue" -> sample["EpsilonValue"],
    "EpsilonMod" -> epsilonMod[sample["EpsilonValue"]],
    "Values" -> canonicalParticular[sample, normalizationColumns]
  |>,
  {sample, samples}
];
canonicalSamples = DeleteDuplicatesBy[canonicalSamples, #EpsilonMod &];

ClearAll[evaluateCoefficientList];
evaluateCoefficientList[coefficients_List, value_Integer] := Fold[
  Mod[#1 value + #2, prime] &,
  0,
  Reverse[coefficients]
];

ClearAll[trimCoefficientList];
trimCoefficientList[coefficients_List] := Module[{nonzeroIndices},
  nonzeroIndices = Select[Range[Length[coefficients]],
    coefficients[[#]] =!= 0 &];
  If[nonzeroIndices === {}, {0}, Take[coefficients, Last[nonzeroIndices]]]
];

ClearAll[reduceRationalPair];
reduceRationalPair[numeratorInput_List,
    denominatorInput_List] := Module[
  {z, numerator, denominator, divisor, normalization,
    numeratorCoefficients, denominatorCoefficients},
  numerator = FromDigits[Reverse[numeratorInput], z];
  denominator = FromDigits[Reverse[denominatorInput], z];
  divisor = PolynomialGCD[numerator, denominator,
    Modulus -> prime];
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
    denominatorDegree, matrix, nullspace, vector, pair, candidate},

  If[AllTrue[data, Last[#] === 0 &],
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
      vector = basisVector;
      If[AnyTrue[vector[[numeratorDegree + 2 ;;]], # =!= 0 &],
        pair = reduceRationalPair[
          vector[[1 ;; numeratorDegree + 1]],
          vector[[numeratorDegree + 2 ;;]]
        ];
        If[candidateValidQ[pair, validation],
          candidate = <|
            "Numerator" -> pair[[1]],
            "Denominator" -> pair[[2]],
            "Degrees" -> {
              Length[pair[[1]]] - 1,
              Length[pair[[2]]] - 1
            }
          |>;
          Throw[candidate, "Found"]
        ]
      ],
      {basisVector, nullspace}
    ],
    {totalDegree, 0, maximumTotalDegree},
    {numeratorDegree, 0, totalDegree}
  ];
  $Failed
], "Found"];

If[Environment["FACET_INTERPOLATOR_SELFTEST_ONLY"] === "True",
  syntheticFunctions = {
    (1 + 2 z + 3 z^2)/(4 + 5 z),
    (2 - z + 7 z^4)/(z^2 (3 + z)),
    11/(1 - 2 z + 5 z^3)
  };
  Do[
    syntheticData = ({#EpsilonMod,
          Mod[
            Numerator[Together[function /. z -> #EpsilonMod]]*
              PowerMod[
                Mod[Denominator[
                  Together[function /. z -> #EpsilonMod]], prime],
                -1, prime],
            prime
          ]} &) /@ canonicalSamples;
    Print[<|
      "Function" -> function,
      "Interpolation" -> interpolateCoordinate[syntheticData]
    |>],
    {function, syntheticFunctions}
  ];
  debugData = ({#EpsilonMod,
        Mod[
          Numerator[Together[First[syntheticFunctions] /.
              z -> #EpsilonMod]]*
            PowerMod[
              Mod[Denominator[Together[First[syntheticFunctions] /.
                    z -> #EpsilonMod]], prime], -1, prime],
          prime
        ]} &) /@ canonicalSamples;
  debugMatrix = Table[
    Join[
      Table[PowerMod[datum[[1]], power, prime], {power, 0, 2}],
      Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime],
        prime], {power, 0, 1}]
    ],
    {datum, Take[debugData, constructionCount]}
  ];
  debugNullspace = NullSpace[debugMatrix, Modulus -> prime];
  debugPair = If[debugNullspace === {}, Missing["None"],
    reduceRationalPair[First[debugNullspace][[1 ;; 3]],
      First[debugNullspace][[4 ;; 5]]]
  ];
  Print[<|
    "DebugRank" -> MatrixRank[debugMatrix, Modulus -> prime],
    "DebugNullspace" -> debugNullspace,
    "DebugReducedPair" -> debugPair,
    "DebugValidation" -> candidateValidQ[debugPair,
      Drop[debugData, constructionCount]],
    "DebugFirstHeldResidual" -> With[
      {datum = First[Drop[debugData, constructionCount]]},
      Mod[
        evaluateCoefficientList[debugPair[[1]], datum[[1]]] -
          datum[[2]] evaluateCoefficientList[debugPair[[2]], datum[[1]]],
        prime
      ]
    ]
  |>];
  Exit[0]
];

If[Length[canonicalSamples] < constructionCount + 4,
  Print["Not enough distinct epsilon samples: ", Length[canonicalSamples]];
  Exit[1]
];

coordinateCount = Length[First[canonicalSamples]["Values"]];
Print["Distinct epsilon samples: ", Length[canonicalSamples]];
Print["Normalization columns: ", normalizationColumns];
Print["Coordinates: ", coordinateCount];

{interpolationSeconds, interpolations} = AbsoluteTiming[
  Table[
    If[Mod[coordinate, 50] === 0,
      Print["Interpolated coordinates: ", coordinate, "/",
        coordinateCount]
    ];
    interpolateCoordinate[
      ({#EpsilonMod, #Values[[coordinate]]} &) /@ canonicalSamples
    ],
    {coordinate, coordinateCount}
  ]
];

unresolvedCoordinates = Flatten[Position[interpolations, $Failed]];
degreeHistogram = Counts[
  Cases[interpolations, association_Association :> association["Degrees"]]
];

result = <|
  "Prime" -> prime,
  "SampleCount" -> Length[canonicalSamples],
  "ConstructionCount" -> constructionCount,
  "ValidationCount" -> Length[canonicalSamples] - constructionCount,
  "MaximumTotalDegree" -> maximumTotalDegree,
  "NormalizationColumns" -> normalizationColumns,
  "InterpolationSeconds" -> interpolationSeconds,
  "UnresolvedCoordinates" -> unresolvedCoordinates,
  "DegreeHistogram" -> degreeHistogram,
  "Interpolations" -> interpolations
|>;

Put[result, outputPath];
Print[KeyDrop[result, "Interpolations"]];
