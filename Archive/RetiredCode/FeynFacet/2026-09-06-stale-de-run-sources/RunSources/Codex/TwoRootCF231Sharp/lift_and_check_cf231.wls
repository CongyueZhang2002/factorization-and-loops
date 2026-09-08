directory = DirectoryName[$InputFileName];
interpolationPaths = Sort[FileNames[
  "CF231_8_7_epsilon_interpolation_mod_*.wl", directory]];
recordPath =
  "/home/maxzhang/factorization-and-loops/Codex/TwoRootCF231Audit/" <>
    "CF231_8_7_exact_strip.wl";
residuePath = FileNameJoin[{directory, "CF231_8_7_residue_space.wl"}];
polePath = FileNameJoin[{directory, "CF231_8_7_pole_bounds.wl"}];
outputPath = FileNameJoin[{directory,
    "CF231_8_7_lifted_exact_check.wl"}];
candidatePath = FileNameJoin[{directory,
    "CF231_8_7_lifted_candidate.wl"}];

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
poleData = Get[polePath];
{y, s} = record["Variables"];
epsilon = record["Regulator"];
{e, c} = record /@ {"E", "C"};
forcing = residueData["Forcing"];
freeResidues = residueData["Parameters"];
alphabet = residueData["Alphabet"];
generalResidues = residueData["GeneralResidues"];
gaugeDenominator = poleData["GaugeDenominator"];
{degreeY, degreeS} = poleData["NumeratorDegreeBounds"];

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
  ((((i - 1)*4 + j - 1)*(degreeY + 1) + px)*(degreeS + 1) +
    py + 1);

gauge = Table[
  Sum[
    liftedVector[[columnIndex[i, j, px, py]]] y^px s^py,
    {px, 0, degreeY}, {py, 0, degreeS}
  ]/gaugeDenominator,
  {i, 4}, {j, 4}
];
residueRules = Thread[freeResidues -> liftedVector[[1409 ;; 1425]]];
exactResidues = Map[Together, generalResidues /. residueRules, {3}];
gaugeDerivatives = {D[gauge, y], D[gauge, s]};

Put[<|
  "Primes" -> primes,
  "CombinedModulus" -> combinedModulus,
  "NormalizationColumns" ->
    First[interpolationData]["NormalizationColumns"],
  "LiftedVector" -> liftedVector,
  "ResidueRules" -> residueRules,
  "Alphabet" -> alphabet,
  "Residues" -> exactResidues,
  "Gauge" -> gauge
|>, candidatePath];

ClearAll[pfaffianResidual];
pfaffianResidual[mu_Integer, i_Integer, j_Integer] := Together[
  gaugeDerivatives[[mu, i, j]] -
    epsilon Sum[e[[mu, i, a]] gauge[[a, j]], {a, 4}] +
    epsilon Sum[gauge[[i, b]] c[[mu, b, j]], {b, 4}] -
    (forcing[[mu, i, j]] /. residueRules)
];

quickCheckPoints = {
  {epsilon -> 1/7, y -> 2/13, s -> 3/17},
  {epsilon -> 2/9, y -> 5/19, s -> 7/23},
  {epsilon -> -3/11, y -> 11/29, s -> 13/31}
};
quickCheckResiduals = Table[
  Together[
    (gaugeDerivatives[[mu, i, j]] -
        epsilon Sum[e[[mu, i, a]] gauge[[a, j]], {a, 4}] +
        epsilon Sum[gauge[[i, b]] c[[mu, b, j]], {b, 4}] -
        (forcing[[mu, i, j]] /. residueRules)) /. point
  ],
  {point, quickCheckPoints}, {mu, 2}, {i, 4}, {j, 4}
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

parallelKernelCount = Min[4, $ProcessorCount];
LaunchKernels[parallelKernelCount];
DistributeDefinitions[
  pfaffianResidual, gauge, gaugeDerivatives, e, c, forcing,
  residueRules, epsilon, y, s
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
    {mu, 2}, {i, 4}, {j, 4},
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
  "Alphabet" -> alphabet,
  "Residues" -> exactResidues,
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
