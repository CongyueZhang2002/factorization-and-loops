directory = DirectoryName[$InputFileName];
interpolationPaths = Sort[FileNames[
  "CF254_9_7_epsilon_interpolation_mod_*.wl", directory]];
If[interpolationPaths === {},
  Print["No completed epsilon interpolation artifacts were found."];
  Exit[1]
];
recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_7_input.wl";
residuePath = FileNameJoin[{directory, "CF254_9_7_residue_data.wl"}];
outputPath = FileNameJoin[{directory,
    "CF254_9_7_lifted_exact_check.wl"}];
candidatePath = FileNameJoin[{directory,
    "CF254_9_7_lifted_candidate.wl"}];
checkpointPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_strip_state.wl";
sourceHashes = <|
  "RecordSHA256" -> FileHash[recordPath, "SHA256"],
  "ResidueSHA256" -> FileHash[residuePath, "SHA256"],
  "CheckpointSHA256" -> FileHash[checkpointPath, "SHA256"],
  "InterpolationSHA256" -> AssociationThread[
    FileNameTake /@ interpolationPaths,
    FileHash[#, "SHA256"] & /@ interpolationPaths
  ]
|>;

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
If[Length[DeleteDuplicates[
      interpolationData[[All, "GaugeUnknownCount"]]]] =!= 1 ||
    Length[DeleteDuplicates[
      interpolationData[[All, "FreeResidueCount"]]]] =!= 1 ||
    Length[DeleteDuplicates[
      Length /@ interpolationData[[All, "Interpolations"]]]] =!= 1,
  Print["The interpolation artifacts have different coordinate dimensions."];
  Exit[1]
];
interpolationCertificateChecks = Table[
  With[{sampleCount = interpolationData[[dataIndex, "SampleCount"]]},
    AllTrue[interpolationData[[dataIndex, "Interpolations"]],
      Function[interpolation,
        AssociationQ[interpolation] &&
          Lookup[interpolation, "ConstructionNullity", 0] === 1 &&
          Lookup[interpolation, "ValidatedPointCount", -1] ===
            sampleCount &&
          Lookup[interpolation, "ValidatedPointCount", -1] >=
            Lookup[interpolation, "UniquenessPointRequirement", Infinity]
      ]
    ]
  ],
  {dataIndex, Length[interpolationData]}
];
If[! And @@ interpolationCertificateChecks,
  Print["At least one interpolation lacks a uniqueness certificate."];
  Exit[1]
];

primes = interpolationData[[All, "Prime"]];
If[! DuplicateFreeQ[primes] || ! AllTrue[primes, PrimeQ] ||
    ! AllTrue[Subsets[primes, {2}], CoprimeQ @@ # &],
  Print["Interpolation moduli are not distinct pairwise-coprime primes: ",
    primes];
  Exit[1]
];
combinedModulus = Times @@ primes;
If[Length[DeleteDuplicates[
      interpolationData[[All, "NormalizationColumns"]]]] =!= 1,
  Print["The interpolation normalizations disagree."];
  Exit[1]
];
If[Length[DeleteDuplicates[
      interpolationData[[All, "GaugeNumeratorDegrees"]]]] =!= 1,
  Print["The interpolation numerator degrees disagree."];
  Exit[1]
];
modularDenominatorsMonicQ = And @@ Flatten[
  Map[Last[#["Denominator"]] === 1 &,
    interpolationData[[All, "Interpolations"]], {2}]
];
If[! TrueQ[modularDenominatorsMonicQ],
  Print["At least one modular rational function is not monic-normalized."];
  Exit[1]
];
record = Get[recordPath];
residueData = Get[residuePath];
{x, y} = record["Variables"];
epsilon = record["Regulator"];
{e, c, bbar} = record["Strip"];
forcing = residueData["Forcing"];
freeResidues = residueData["FreeResidues"];

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
{numeratorDegreeX, numeratorDegreeY} =
  First[interpolationData]["GaugeNumeratorDegrees"];
{upperDimension, lowerDimension} = Rest[Dimensions[bbar]];
gaugeUnknownCount = upperDimension*lowerDimension*(numeratorDegreeX + 1)*
  (numeratorDegreeY + 1);
If[Length[First[interpolationData]["Interpolations"]] =!=
    gaugeUnknownCount + Length[freeResidues],
  Print["Lifted-coordinate count disagrees with the strip dimensions."];
  Exit[1]
];

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

ClearAll[liftInterpolationData];
liftInterpolationData[data_Association] := Module[
  {numeratorCoefficients, denominatorCoefficients},
  numeratorCoefficients = liftCoefficient /@ data["Numerator"];
  denominatorCoefficients = liftCoefficient /@ data["Denominator"];
  <|
    "NumeratorCoefficients" -> numeratorCoefficients,
    "DenominatorCoefficients" -> denominatorCoefficients,
    "Function" -> Together[
      FromDigits[Reverse[numeratorCoefficients], epsilon]/
        FromDigits[Reverse[denominatorCoefficients], epsilon]
    ]
  |>
];

{liftingSeconds, liftedInterpolationDataSet} = AbsoluteTiming[
  liftInterpolationData /@ combinedInterpolations
];
liftedVector = liftedInterpolationDataSet[[All, "Function"]];
rationalReconstructionBound = Floor[Sqrt[(combinedModulus - 1)/2]];
liftedCoefficients = Flatten[
  Join[#NumeratorCoefficients, #DenominatorCoefficients] & /@
    liftedInterpolationDataSet
];
rationalReconstructionBoundChecks =
  (Abs[Numerator[#]] <= rationalReconstructionBound &&
      Denominator[#] <= rationalReconstructionBound) & /@
    liftedCoefficients;
If[! And @@ rationalReconstructionBoundChecks,
  Print["At least one rational reconstruction is outside the uniqueness ",
    "bound for the combined modulus."];
  Exit[1]
];

ClearAll[coefficientImagesMatchQ];
coefficientImagesMatchQ[combined_Integer, lifted_] := AllTrue[primes,
  Function[modulus,
    Module[{denominator = Mod[Denominator[lifted], modulus]},
      denominator =!= 0 &&
        Mod[Numerator[lifted] PowerMod[denominator, -1, modulus],
          modulus] === Mod[combined, modulus]
    ]
  ]
];
coefficientLiftChecks = MapThread[
  Function[{combined, lifted},
    And[
      And @@ MapThread[coefficientImagesMatchQ,
        {combined["Numerator"], lifted["NumeratorCoefficients"]}],
      And @@ MapThread[coefficientImagesMatchQ,
        {combined["Denominator"], lifted["DenominatorCoefficients"]}]
    ]
  ],
  {combinedInterpolations, liftedInterpolationDataSet}
];
If[! And @@ coefficientLiftChecks,
  Print["At least one lifted coefficient fails modular back-substitution."];
  Exit[1]
];

ClearAll[columnIndex];
columnIndex[i_, j_, px_, py_] :=
  (((i - 1)*lowerDimension + (j - 1))*(numeratorDegreeX + 1) + px)*
    (numeratorDegreeY + 1) +
    py + 1;

gauge = Table[
  Sum[
    liftedVector[[columnIndex[i, j, px, py]]] x^px y^py,
    {px, 0, numeratorDegreeX}, {py, 0, numeratorDegreeY}
  ]/gaugeDenominator,
  {i, upperDimension}, {j, lowerDimension}
];
residueRules = Thread[freeResidues ->
  liftedVector[[gaugeUnknownCount + Range[Length[freeResidues]]]]];
gaugeDerivatives = {D[gauge, x], D[gauge, y]};

ClearAll[pfaffianResidual];
pfaffianResidual[mu_Integer, i_Integer, j_Integer] := Together[
  gaugeDerivatives[[mu, i, j]] -
    epsilon Sum[e[[mu, i, a]] gauge[[a, j]],
      {a, upperDimension}] +
    epsilon Sum[gauge[[i, b]] c[[mu, b, j]],
      {b, lowerDimension}] -
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
        epsilon Sum[e[[mu, i, a]] gauge[[a, j]],
          {a, upperDimension}] +
        epsilon Sum[gauge[[i, b]] c[[mu, b, j]],
          {b, lowerDimension}] -
        (forcing[[mu, i, j]] /. residueRules)) /. point
  ],
  {point, quickCheckPoints}, {mu, 2},
  {i, upperDimension}, {j, lowerDimension}
];
quickChecksZero = Map[TrueQ[# === 0] &, quickCheckResiduals, {4}];
Print["Exact rational-point checks zero: ",
  And @@ Flatten[quickChecksZero]];
If[! And @@ Flatten[quickChecksZero],
  Put[<|
    "Primes" -> primes,
    "CombinedModulus" -> combinedModulus,
    "SourceHashes" -> sourceHashes,
    "RationalReconstructionBound" -> rationalReconstructionBound,
    "RationalReconstructionBoundsSatisfied" -> True,
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
    {mu, 2}, {i, upperDimension}, {j, lowerDimension},
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
  "SourceHashes" -> sourceHashes,
  "RationalReconstructionBound" -> rationalReconstructionBound,
  "RationalReconstructionBoundsSatisfied" -> True,
  "NormalizationColumns" ->
    First[interpolationData]["NormalizationColumns"],
  "LiftingSeconds" -> liftingSeconds,
  "GaugeDenominatorDegrees" -> {degreeX, degreeY},
  "GaugeNumeratorDegrees" -> {numeratorDegreeX, numeratorDegreeY},
  "ModularDenominatorsMonic" -> modularDenominatorsMonicQ,
  "CoefficientLiftChecks" -> coefficientLiftChecks,
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
Put[<|
  "Primes" -> primes,
  "CombinedModulus" -> combinedModulus,
  "SourceHashes" -> sourceHashes,
  "RationalReconstructionBound" -> rationalReconstructionBound,
  "RationalReconstructionBoundsSatisfied" -> True,
  "NormalizationColumns" ->
    First[interpolationData]["NormalizationColumns"],
  "LiftedVector" -> liftedVector,
  "ResidueRules" -> residueRules,
  "Gauge" -> gauge,
  "GaugeDenominatorDegrees" -> {degreeX, degreeY},
  "GaugeNumeratorDegrees" -> {numeratorDegreeX, numeratorDegreeY},
  "ExactPfaffianResidualsZero" -> True
|>, candidatePath];
