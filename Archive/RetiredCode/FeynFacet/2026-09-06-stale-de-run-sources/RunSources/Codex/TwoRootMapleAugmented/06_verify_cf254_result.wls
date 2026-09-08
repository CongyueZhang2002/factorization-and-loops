#!/usr/bin/env wolframscript

$HistoryLength = 0;

If[Length[$ScriptCommandLine] < 2,
  Print["usage=06_verify_cf254_result.wls <xy|yx>"];
  Exit[64]
];

orientation = Last[$ScriptCommandLine];
If[! MemberQ[{"xy", "yx"}, orientation],
  Print["invalid_orientation=", orientation];
  Exit[64]
];

artifactDirectory = DirectoryName[ExpandFileName[$InputFileName]];
dataPath = FileNameJoin[{artifactDirectory, "04_cf254_augmented_data.wl"}];
resultPath = FileNameJoin[{
  artifactDirectory, "05_cf254_augmented_" <> orientation <> ".result.txt"
}];
summaryPath = FileNameJoin[{
  artifactDirectory, "06_cf254_verification_" <> orientation <> ".wl"
}];
solutionPath = FileNameJoin[{
  artifactDirectory, "06_cf254_affine_solution_" <> orientation <> ".wl"
}];

zeroQ[expr_] := AllTrue[Flatten[{expr}], TrueQ[Together[#] === 0] &];

start = AbsoluteTime[];
Print["BEGIN_VERIFICATION"];
Print["orientation=", orientation];
Print["data_path=", dataPath];
Print["result_path=", resultPath];

If[! FileExistsQ[dataPath],
  Print["verification_status=MISSING_AUGMENTED_DATA"];
  Exit[2]
];
If[! FileExistsQ[resultPath],
  Print["verification_status=MISSING_MAPLE_RESULT"];
  Exit[3]
];

data = Get[dataPath];
variables = data["Summary"]["Variables"];
epsilon = data["Summary"]["Regulator"];
augmentedConnection = data["AugmentedConnection"];
If[orientation === "yx",
  orderedVariables = Reverse[variables];
  orderedConnection = Reverse[augmentedConnection],
  orderedVariables = variables;
  orderedConnection = augmentedConnection
];

rawResult = StringTrim[Import[resultPath, "Text"]];
identifierNames = DeleteDuplicates@StringCases[
  rawResult,
  RegularExpression["[A-Za-z$][A-Za-z0-9$]*"]
];
unexpectedIdentifiers = Complement[
  identifierNames,
  Join[SymbolName /@ variables, {SymbolName[epsilon]}]
];
If[unexpectedIdentifiers =!= {},
  Print["verification_status=UNEXPECTED_MAPLE_IDENTIFIERS"];
  Print["unexpected_identifiers=", InputForm[unexpectedIdentifiers]];
  Exit[4]
];

parseContext = "CF254MapleResultParse`";
parsedBasis = Block[
  {$Context = parseContext, $ContextPath = {"System`"}},
  ToExpression[StringReplace[rawResult, {"[" -> "{", "]" -> "}"}]]
];
parseRules = {
  Symbol[parseContext <> SymbolName[variables[[1]]]] -> variables[[1]],
  Symbol[parseContext <> SymbolName[variables[[2]]]] -> variables[[2]],
  Symbol[parseContext <> SymbolName[epsilon]] -> epsilon
};
basis = Map[Together, parsedBasis /. parseRules, {2}];
basisDimensions = Dimensions[basis];
augmentedDimension = data["Summary"]["AugmentedDimension"];
If[Length[basisDimensions] =!= 2 || First[basisDimensions] =!= augmentedDimension,
  Print["verification_status=WRONG_BASIS_DIMENSIONS"];
  Print["basis_dimensions=", InputForm[basisDimensions]];
  Exit[5]
];

residualStart = AbsoluteTime[];
augmentedResidual = Table[
  Map[Together,
    D[basis, orderedVariables[[mu]]] - orderedConnection[[mu]].basis,
    {2}],
  {mu, 2}];
augmentedResidualSeconds = AbsoluteTime[] - residualStart;
augmentedResidualZero = zeroQ[augmentedResidual];

gaugeDimension = data["Summary"]["GaugeDimension"];
residueCount = data["Summary"]["ResidueCount"];
constantCoordinate = gaugeDimension + 1;
bottom = basis[[constantCoordinate ;; augmentedDimension, All]];
bottomKinematicDerivative = Table[
  Map[Together, D[bottom, variable], {2}],
  {variable, variables}];
bottomKinematicConstant = zeroQ[bottomKinematicDerivative];

coefficientCount = Last[basisDimensions];
coefficients = Array[Symbol["Global`alpha" <> ToString[#]] &, coefficientCount];
sectionSolutions = Solve[
  bottom[[1]].coefficients == 1,
  coefficients
];
affineSectionExists = sectionSolutions =!= {};

pureHomogeneousCoefficientBasis = NullSpace[bottom];
pureHomogeneousGaugeBasis = If[pureHomogeneousCoefficientBasis === {},
  {},
  Map[Together,
    basis[[1 ;; gaugeDimension, All]].# & /@
      pureHomogeneousCoefficientBasis,
    {2}]
];

summary = <|
  "Orientation" -> orientation,
  "DataPath" -> dataPath,
  "ResultPath" -> resultPath,
  "ResultSHA256" -> FileHash[resultPath, "SHA256", "HexString"],
  "BasisDimensions" -> basisDimensions,
  "UnexpectedIdentifiers" -> unexpectedIdentifiers,
  "AugmentedResidualZero" -> augmentedResidualZero,
  "AugmentedResidualSeconds" -> augmentedResidualSeconds,
  "BottomKinematicConstant" -> bottomKinematicConstant,
  "AffineSectionExists" -> affineSectionExists,
  "PureHomogeneousGaugeDimension" -> Length[pureHomogeneousGaugeBasis]
|>;

If[affineSectionExists,
  sectionRules = First[sectionSolutions];
  affineVector = Map[Together, basis.coefficients /. sectionRules];
  affineFreeCoefficients = Select[
    coefficients,
    ! FreeQ[affineVector, #] &
  ];
  gaugeVector = affineVector[[1 ;; gaugeDimension]];
  gauge = ArrayReshape[gaugeVector, data["Summary"]["GaugeShape"]];
  residueValues = affineVector[[constantCoordinate + 1 ;; augmentedDimension]];
  residueValueRules = Thread[data["FreeResidues"] -> residueValues];
  solvedForcing = Map[Together,
    data["Forcing"] /. residueValueRules,
    {3}];
  solvedResidueMatrices = Map[Together,
    data["ResidueMatrices"] /. residueValueRules,
    {3}];
  {e, c, bbar} = data["Strip"];

  stripResidualStart = AbsoluteTime[];
  stripResidual = Table[
    Map[Together,
      D[gauge, variables[[mu]]] -
        epsilon (e[[mu]].gauge - gauge.c[[mu]]) -
        solvedForcing[[mu]],
      {2}],
    {mu, 2}];
  stripResidualSeconds = AbsoluteTime[] - stripResidualStart;
  stripResidualZero = zeroQ[stripResidual];

  transformedResidualStart = AbsoluteTime[];
  transformedResidual = Table[
    Map[Together,
      bbar[[mu]] + epsilon (e[[mu]].gauge - gauge.c[[mu]]) -
        D[gauge, variables[[mu]]] - epsilon Sum[
          solvedResidueMatrices[[letter]] data["DLog"][[letter, mu]],
          {letter, Length[solvedResidueMatrices]}],
      {2}],
    {mu, 2}];
  transformedResidualSeconds = AbsoluteTime[] - transformedResidualStart;
  transformedResidualZero = zeroQ[transformedResidual];

  summary = Join[summary, <|
    "AffineFreeCoefficientCount" -> Length[affineFreeCoefficients],
    "AffineFreeCoefficients" -> affineFreeCoefficients,
    "ConstantCoordinateExactlyOne" ->
      TrueQ[Together[affineVector[[constantCoordinate]] - 1] === 0],
    "StripResidualZero" -> stripResidualZero,
    "StripResidualSeconds" -> stripResidualSeconds,
    "TransformedDLogResidualZero" -> transformedResidualZero,
    "TransformedDLogResidualSeconds" -> transformedResidualSeconds
  |>];

  exactSolution = <|
    "Summary" -> summary,
    "Basis" -> basis,
    "AffineVector" -> affineVector,
    "Gauge" -> gauge,
    "ResidueValues" -> residueValues,
    "ResidueValueRules" -> residueValueRules,
    "AffineFreeCoefficients" -> affineFreeCoefficients,
    "PureHomogeneousGaugeBasis" -> pureHomogeneousGaugeBasis
  |>;
  Put[exactSolution, solutionPath],

  summary = Join[summary, <|
    "StripResidualZero" -> Missing["NoAffineSection"],
    "TransformedDLogResidualZero" -> Missing["NoAffineSection"]
  |>]
];

summary = Join[summary, <|
  "AcceptanceCriterionSatisfied" -> TrueQ[
    augmentedResidualZero && bottomKinematicConstant && affineSectionExists &&
    Lookup[summary, "ConstantCoordinateExactlyOne", False] &&
    Lookup[summary, "StripResidualZero", False] &&
    Lookup[summary, "TransformedDLogResidualZero", False]
  ],
  "TotalSeconds" -> AbsoluteTime[] - start
|>];
Put[summary, summaryPath];

Print["basis_dimensions=", InputForm[basisDimensions]];
Print["augmented_residual_seconds=", InputForm[augmentedResidualSeconds]];
Print["augmented_residual_zero=", augmentedResidualZero];
Print["bottom_kinematic_constant=", bottomKinematicConstant];
Print["affine_section_exists=", affineSectionExists];
Print["pure_homogeneous_gauge_dimension=", Length[pureHomogeneousGaugeBasis]];
If[affineSectionExists,
  Print["affine_free_coefficient_count=", Length[affineFreeCoefficients]];
  Print["constant_coordinate_exactly_one=",
    summary["ConstantCoordinateExactlyOne"]];
  Print["strip_residual_zero=", summary["StripResidualZero"]];
  Print["transformed_dlog_residual_zero=",
    summary["TransformedDLogResidualZero"]];
  Print["solution_path=", solutionPath]
];
Print["acceptance_criterion_satisfied=",
  summary["AcceptanceCriterionSatisfied"]];
Print["summary_path=", summaryPath];
Print["total_seconds=", InputForm[summary["TotalSeconds"]]];
Print["END_VERIFICATION"];

Exit[If[TrueQ[summary["AcceptanceCriterionSatisfied"]], 0, 1]];
