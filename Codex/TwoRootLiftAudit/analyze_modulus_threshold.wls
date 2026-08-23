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

primes = {1000003, 2147483563, 2147483587, 2147483629, 2147483647};
interpolations = Get /@ (FileNameJoin[{sourceDirectory,
      "CF254_9_8_epsilon_interpolation_mod_" <> ToString[#] <> ".wl"}] & /@
    primes);

ClearAll[combineCoefficientLists];
combineCoefficientLists[lists_List, length_Integer, moduli_List] := Table[
  ChineseRemainder[
    Table[PadRight[lists[[k]], length][[index]], {k, Length[lists]}],
    moduli
  ],
  {index, length}
];

ClearAll[combineCoordinate];
combineCoordinate[data_List, moduli_List] := Module[
  {degrees, numeratorLength, denominatorLength},
  degrees = First[data]["Degrees"];
  numeratorLength = If[degrees[[1]] === -Infinity, 1, degrees[[1]] + 1];
  denominatorLength = degrees[[2]] + 1;
  <|
    "Numerator" -> combineCoefficientLists[
      data[[All, "Numerator"]], numeratorLength, moduli],
    "Denominator" -> combineCoefficientLists[
      data[[All, "Denominator"]], denominatorLength, moduli],
    "Degrees" -> degrees
  |>
];

ClearAll[rawLiftRows];
rawLiftRows[data_List, moduli_List] := Module[
  {modulus, combined},
  modulus = Times @@ moduli;
  combined = Table[
    combineCoordinate[data[[All, "Interpolations", coordinate]], moduli],
    {coordinate, Length[First[data]["Interpolations"]]}
  ];
  Flatten@Table[
    Join[
      MapIndexed[
        <|"Coordinate" -> coordinate, "Part" -> "Numerator",
          "Index" -> First[#2],
          "Value" -> FiniteFlow`FFRatRec[#1, modulus]|> &,
        combined[[coordinate, "Numerator"]]
      ],
      MapIndexed[
        <|"Coordinate" -> coordinate, "Part" -> "Denominator",
          "Index" -> First[#2],
          "Value" -> FiniteFlow`FFRatRec[#1, modulus]|> &,
        combined[[coordinate, "Denominator"]]
      ]
    ],
    {coordinate, Length[combined]}
  ]
];

fourPrimes = DeleteCases[primes, 2147483563];
fourData = Select[interpolations, MemberQ[fourPrimes, #["Prime"]] &];
fiveData = interpolations;

fourRows = rawLiftRows[fourData, fourPrimes];
fiveRows = rawLiftRows[fiveData, primes];
If[(KeyDrop[#, "Value"] & /@ fourRows) =!=
    (KeyDrop[#, "Value"] & /@ fiveRows),
  Print["Coefficient ledgers disagree."];
  Exit[1]
];

comparisonRows = MapThread[
  Join[
    KeyDrop[#1, "Value"],
    <|"FourPrimeValue" -> #1["Value"],
      "FivePrimeValue" -> #2["Value"],
      "Changed" -> TrueQ[#1["Value"] =!= #2["Value"]]|>
  ] &,
  {fourRows, fiveRows}
];

fourModulus = Times @@ fourPrimes;
fiveModulus = Times @@ primes;
fourBound = Floor[Sqrt[fourModulus/2]];
fiveBound = Floor[Sqrt[fiveModulus/2]];

heightRows = Map[
  Function[row,
    value = row["FivePrimeValue"];
    Join[row, <|
      "AbsNumerator" -> Abs[Numerator[value]],
      "Denominator" -> Denominator[value],
      "FourPrimeWangBoundSatisfied" ->
        Max[Abs[Numerator[value]], Denominator[value]] < fourBound,
      "FivePrimeWangBoundSatisfied" ->
        Max[Abs[Numerator[value]], Denominator[value]] < fiveBound,
      "FourPrimeProductBoundSatisfied" ->
        2 Abs[Numerator[value]] Denominator[value] < fourModulus
    |>]
  ],
  comparisonRows
];

changedRows = Select[heightRows, TrueQ[#["Changed"]] &];
fourBoundViolations = Select[heightRows,
  ! TrueQ[#["FourPrimeWangBoundSatisfied"]] &];
fiveBoundViolations = Select[heightRows,
  ! TrueQ[#["FivePrimeWangBoundSatisfied"]] &];
fourProductBoundViolations = Select[heightRows,
  ! TrueQ[#["FourPrimeProductBoundSatisfied"]] &];

independentFourthPath = FileNameJoin[{auditDirectory,
    "CF254_9_8_epsilon_interpolation_mod_2147483587_from_saved_samples.wl"}];
independentFourth = Get[independentFourthPath];
storedFourth = SelectFirst[interpolations, #["Prime"] === 2147483587 &];

exactCheck = Get[FileNameJoin[{sourceDirectory,
    "CF254_9_8_lifted_exact_check.wl"}]];

chronologicalPrimes =
  {1000003, 2147483647, 2147483629, 2147483587, 2147483563};
cumulativeReconstructionTable = Table[
  subsetPrimes = Take[chronologicalPrimes, primeCount];
  orderedSubsetData =
    Function[subsetPrime,
      SelectFirst[interpolations,
        Function[data, data["Prime"] === subsetPrime]]
    ] /@ subsetPrimes;
  subsetRows = rawLiftRows[orderedSubsetData, subsetPrimes];
  subsetModulus = Times @@ subsetPrimes;
  subsetBound = Floor[Sqrt[subsetModulus/2]];
  <|
    "PrimeCount" -> primeCount,
    "Primes" -> subsetPrimes,
    "Modulus" -> subsetModulus,
    "WangBound" -> subsetBound,
    "TrueCoefficientBoundViolationCount" -> Count[
      fiveRows,
      row_ /;
        Max[Abs[Numerator[row["Value"]]], Denominator[row["Value"]]] >=
          subsetBound
    ],
    "RawCoefficientMismatchCount" -> Count[
      MapThread[TrueQ[#1["Value"] =!= #2["Value"]] &,
        {subsetRows, fiveRows}],
      True
    ]
  |>,
  {primeCount, 1, Length[chronologicalPrimes]}
];

summary = <|
  "Primes" -> primes,
  "FourPrimeModulus" -> fourModulus,
  "FivePrimeModulus" -> fiveModulus,
  "FourPrimeWangBound" -> fourBound,
  "FivePrimeWangBound" -> fiveBound,
  "RawCoefficientCount" -> Length[heightRows],
  "ChangedRawCoefficientCount" -> Length[changedRows],
  "ChangedCoordinateCount" -> Length[DeleteDuplicates[
    #["Coordinate"] & /@ changedRows]],
  "FourPrimeWangBoundViolationCount" -> Length[fourBoundViolations],
  "FivePrimeWangBoundViolationCount" -> Length[fiveBoundViolations],
  "FourPrimeProductBoundViolationCount" ->
    Length[fourProductBoundViolations],
  "EveryChangedCoefficientViolatesFourPrimeWangBound" ->
    AllTrue[changedRows, ! TrueQ[#["FourPrimeWangBoundSatisfied"]] &],
  "MaximumAbsNumerator" -> Max[#["AbsNumerator"] & /@ heightRows],
  "MaximumDenominator" -> Max[#["Denominator"] & /@ heightRows],
  "IndependentFourthInterpolationEqualsStored" ->
    TrueQ[independentFourth["Interpolations"] ===
      storedFourth["Interpolations"]],
  "FivePrimeQuickChecksZero" ->
    And @@ Flatten[exactCheck["QuickChecksZero"]],
  "FivePrimeAllSymbolicResidualsZero" ->
    TrueQ[exactCheck["AllResidualsZero"]],
  "CumulativeReconstructionTable" -> cumulativeReconstructionTable
|>;

Put[summary,
  FileNameJoin[{auditDirectory, "modulus_threshold_result.wl"}]];
Put[TakeLargestBy[changedRows,
    Max[#["AbsNumerator"], #["Denominator"]] &, UpTo[20]],
  FileNameJoin[{auditDirectory,
    "largest_changed_raw_coefficients.wl"}]];
Print[summary];
