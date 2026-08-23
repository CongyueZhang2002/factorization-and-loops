directory = DirectoryName[$InputFileName];
interpolationPaths = Sort[FileNames[
  "CF254_9_8_epsilon_interpolation_mod_*.wl", directory]];
If[interpolationPaths === {},
  Print["No completed epsilon interpolation artifacts were found."];
  Exit[1]
];
recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_8_unsolved.wl";
residuePath = FileNameJoin[{directory, "CF254_9_8_residue_data.wl"}];
outputPath = FileNameJoin[{directory,
    "CF254_9_8_lifted_exact_check.wl"}];
candidatePath = FileNameJoin[{directory,
    "CF254_9_8_lifted_candidate.wl"}];

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

interpolationData = Get /@ interpolationPaths;
If[AnyTrue[interpolationData,
    #["UnresolvedCoordinates"] =!= {} &],
  Print["At least one interpolation contains unresolved coordinates."];
  Exit[1]
];

primes = interpolationData[[All, "Prime"]];
combinedModulus = Times @@ primes;
If[Length[DeleteDuplicates[
      interpolationData[[All, "NormalizationColumns"]]]] =!= 1,
  Print["The interpolation normalizations disagree."];
  Exit[1]
];
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

ClearAll[liftCoefficient];
liftCoefficient[value_Integer] :=
  FiniteFlow`FFRatRec[value, combinedModulus];

ClearAll[combineCoefficientLists];
combineCoefficientLists[lists_List, length_Integer] := Table[
  ChineseRemainder[
    MapThread[Part, {PadRight[#, length] & /@ lists,
      ConstantArray[index, Length[lists]]}],
    primes
  ],
  {index, length}
];

ClearAll[combineInterpolationCoordinate];
combineInterpolationCoordinate[data_List] := Module[
  {degrees, numeratorLength, denominatorLength},
  degrees = data[[All, "Degrees"]];
  If[Length[DeleteDuplicates[degrees]] =!= 1,
    Print["Degree mismatch across primes: ", degrees];
    Return[$Failed]
  ];
  numeratorLength = If[First[degrees][[1]] === -Infinity,
    1, First[degrees][[1]] + 1];
  denominatorLength = First[degrees][[2]] + 1;
  <|
    "Numerator" -> combineCoefficientLists[
      data[[All, "Numerator"]], numeratorLength],
    "Denominator" -> combineCoefficientLists[
      data[[All, "Denominator"]], denominatorLength],
    "Degrees" -> First[degrees]
  |>
];

combinedInterpolations = Table[
  combineInterpolationCoordinate[
    interpolationData[[All, "Interpolations", coordinate]]],
  {coordinate, Length[First[interpolationData]["Interpolations"]]}
];
If[MemberQ[combinedInterpolations, $Failed], Exit[1]];

ClearAll[liftInterpolation];
liftInterpolation[data_Association] := Module[
  {numeratorCoefficients, denominatorCoefficients},
  numeratorCoefficients = liftCoefficient /@ data["Numerator"];
  denominatorCoefficients = liftCoefficient /@ data["Denominator"];
  Together[
    FromDigits[Reverse[numeratorCoefficients], epsilon]/
      FromDigits[Reverse[denominatorCoefficients], epsilon]
  ]
];

{liftingSeconds, liftedVector} = AbsoluteTiming[
  liftInterpolation /@ combinedInterpolations
];

ClearAll[columnIndex];
columnIndex[i_, j_, px_, py_] :=
  (((i - 1)*2 + (j - 1))*(degreeX + 1) + px)*(degreeY + 1) +
    py + 1;

gauge = Table[
  Sum[
    liftedVector[[columnIndex[i, j, px, py]]] x^px y^py,
    {px, 0, degreeX}, {py, 0, degreeY}
  ]/gaugeDenominator,
  {i, 4}, {j, 2}
];
residueRules = Thread[freeResidues -> liftedVector[[969 ;; 977]]];
gaugeDerivatives = {D[gauge, x], D[gauge, y]};

Put[<|
  "Primes" -> primes,
  "CombinedModulus" -> combinedModulus,
  "NormalizationColumns" ->
    First[interpolationData]["NormalizationColumns"],
  "LiftedVector" -> liftedVector,
  "ResidueRules" -> residueRules,
  "Gauge" -> gauge
|>, candidatePath];

ClearAll[pfaffianResidual];
pfaffianResidual[mu_Integer, i_Integer, j_Integer] := Together[
  gaugeDerivatives[[mu, i, j]] -
    epsilon Sum[e[[mu, i, a]] gauge[[a, j]], {a, 4}] +
    epsilon Sum[gauge[[i, b]] c[[mu, b, j]], {b, 2}] -
    (forcing[[mu, i, j]] /. residueRules)
];

quickCheckPoints = {
  {epsilon -> 1/7, x -> 2/13, y -> 3/17},
  {epsilon -> 2/9, x -> 5/19, y -> 7/23},
  {epsilon -> -3/11, x -> 11/29, y -> 13/31}
};
quickCheckResiduals = Table[
  Together[
    (gaugeDerivatives[[mu, i, j]] -
        epsilon Sum[e[[mu, i, a]] gauge[[a, j]], {a, 4}] +
        epsilon Sum[gauge[[i, b]] c[[mu, b, j]], {b, 2}] -
        (forcing[[mu, i, j]] /. residueRules)) /. point
  ],
  {point, quickCheckPoints}, {mu, 2}, {i, 4}, {j, 2}
];
quickChecksZero = Map[TrueQ[# === 0] &, quickCheckResiduals, {4}];
Print["Exact rational-point checks zero: ",
  And @@ Flatten[quickChecksZero]];
If[! And @@ Flatten[quickChecksZero],
  Put[<|
    "Primes" -> primes,
    "CombinedModulus" -> combinedModulus,
    "ResidueRules" -> residueRules,
    "QuickCheckPoints" -> quickCheckPoints,
    "QuickCheckResiduals" -> quickCheckResiduals,
    "QuickChecksZero" -> quickChecksZero
  |>, outputPath];
  Exit[1]
];

parallelKernelCount = Min[8, $ProcessorCount];
LaunchKernels[parallelKernelCount];
DistributeDefinitions[
  pfaffianResidual, gauge, gaugeDerivatives, e, c, forcing,
  residueRules, epsilon, x, y
];
{parallelCheckSeconds, residualData} = AbsoluteTiming[
  ParallelTable[
    {seconds, residual} = AbsoluteTiming[pfaffianResidual[mu, i, j]];
    <|
      "Index" -> {mu, i, j},
      "Seconds" -> seconds,
      "Zero" -> TrueQ[Numerator[residual] === 0],
      "Numerator" -> If[TrueQ[Numerator[residual] === 0],
        0, Numerator[residual]]
    |>,
    {mu, 2}, {i, 4}, {j, 2},
    Method -> "FinestGrained"
  ]
];
CloseKernels[];
residualChecks = Map[#["Zero"] &, residualData, {3}];
residualSeconds = Map[#["Seconds"] &, residualData, {3}];
nonzeroResidualNumerators = Cases[
  Flatten[residualData],
  data_Association /; ! TrueQ[data["Zero"]] :>
    (ToString[data["Index"], InputForm] -> data["Numerator"])
];

result = <|
  "Primes" -> primes,
  "CombinedModulus" -> combinedModulus,
  "NormalizationColumns" ->
    First[interpolationData]["NormalizationColumns"],
  "LiftingSeconds" -> liftingSeconds,
  "ResidueRules" -> residueRules,
  "Gauge" -> gauge,
  "QuickCheckPoints" -> quickCheckPoints,
  "QuickChecksZero" -> quickChecksZero,
  "ParallelCheckSeconds" -> parallelCheckSeconds,
  "ResidualSeconds" -> residualSeconds,
  "ResidualChecks" -> residualChecks,
  "AllResidualsZero" -> And @@ Flatten[residualChecks],
  "NonzeroResidualNumerators" -> nonzeroResidualNumerators
|>;

Put[result, outputPath];
Print[KeyDrop[result, {"Gauge", "NonzeroResidualNumerators"}]];
If[! TrueQ[result["AllResidualsZero"]], Exit[1]];
