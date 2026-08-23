(* ::Package:: *)

(*
  External prototype for milestone M1. This file intentionally lives outside
  FeynFacet and assumes Addon/Load/LoadFACET.wl has already been loaded.

  The prototype separates finite-field matrix construction from elimination,
  discovers a normalization and a stable square row core on one pilot sample,
  and solves later samples with one constrained factorization and r+1 right-
  hand sides. All original sampled equations are retained for residual checks.
*)

ClearAll[
  CodexM1BuildSampleSystem,
  CodexM1BaselineSolveSystem,
  CodexM1DiscoverPilotPlan,
  CodexM1SolveConstrainedSample,
  CodexM1CanonicalAgreementQ,
  codexM1IndependentNormalizationColumns,
  codexM1IndependentEquationRows,
  codexM1SampleMetadata,
  codexM1ZeroVectorQ,
  codexM1ZeroMatrixQ
];

Options[CodexM1BuildSampleSystem] = {
  "PointCount" -> Automatic,
  "NumeratorDegreeOffset" -> {0, 0},
  "RandomSeed" -> 2540908,
  "CaptureMinimumDimension" -> 1000
};

CodexM1BuildSampleSystem[
    record_Association, epsilonValue_, prime_Integer,
    OptionsPattern[]] := Module[
  {variables, epsilon, e, c, bbar, x, y, dimensions,
   upperDimension, lowerDimension, alphabet, dlog, residueTriples,
   freeResidues, forcingConstant, forcingCoefficients, factorPairs,
   factors, factorPowers, gaugeFactorPowers, gaugeDenominator,
   denominatorDegrees, degreeOffset, numeratorDegrees, equationCount,
   gaugeUnknownCount, unknownCount, requestedPointCount, randomSeed,
   epsilonMod, modNumber, polynomialRules, rationalForm,
   evaluatePolynomial, evaluateRational, preprocessedForms,
   preprocessingSeconds, eForms, cForms, forcingConstantForms,
   forcingCoefficientForms, gaugeDenominatorForm,
   gaugeDenominatorDerivativeForms, columnIndex, buildPointRows,
   pointRows = {}, pointRightHandSides = {}, acceptedPoints = {},
   attemptCount = 0, maximumAttempts, point, pointResult, matrix,
   rightHandSide, samplingSeconds, samplingResult, setupStart, setupSeconds,
   maximumMemoryBefore, peakMemoryBytes,
   preprocessingLabel = "NotStarted"},

  If[! AssociationQ[record] ||
      ! And @@ (KeyExistsQ[record, #] & /@
        {"Strip", "Variables", "Regulator"}) ||
      ! MatchQ[record["Variables"], {_, _}] ||
      ! SymbolQ[record["Regulator"]] ||
      ! epsFormStripShapeQ[record["Strip"]],
    Return[$Failed]];
  degreeOffset = OptionValue["NumeratorDegreeOffset"];
  requestedPointCount = OptionValue["PointCount"];
  randomSeed = OptionValue["RandomSeed"];
  If[! PrimeQ[prime] || prime <= 3 ||
      ! MatchQ[epsilonValue, _Integer | _Rational] ||
      Mod[Denominator[epsilonValue], prime] === 0 ||
      ! MatchQ[degreeOffset,
        {a_Integer, b_Integer} /; a >= 0 && b >= 0] ||
      ! (requestedPointCount === Automatic ||
        IntegerQ[requestedPointCount] && requestedPointCount > 0) ||
      ! IntegerQ[randomSeed],
    Return[$Failed]];

  maximumMemoryBefore = MaxMemoryUsed[];
  setupStart = AbsoluteTime[];
  variables = record["Variables"];
  epsilon = record["Regulator"];
  {x, y} = variables;
  {e, c, bbar} = record["Strip"];
  dimensions = Dimensions[bbar[[1]]];
  {upperDimension, lowerDimension} = dimensions;
  alphabet = epsFormStripAlphabet[record["Strip"], variables, epsilon];
  If[alphabet === $Failed, Return[$Failed]];
  dlog = Table[
    Together[D[Log[alphabet[[a]]], variables[[mu]]]],
    {a, Length[alphabet]}, {mu, 2}];
  residueTriples = Flatten[
    Table[{a, i, j}, {a, Length[alphabet]},
      {i, upperDimension}, {j, lowerDimension}], 2];
  freeResidues = Array[Unique["codexM1RawK"] &,
    Length[residueTriples]];
  forcingConstant = bbar;
  forcingCoefficients = Map[
    Function[triple,
      With[{a = triple[[1]], i = triple[[2]], j = triple[[3]]},
        Table[-epsilon dlog[[a, mu]]*
          Normal[SparseArray[{{i, j} -> 1}, dimensions]],
          {mu, 2}]]],
    residueTriples];

  factorPairs = Flatten[
    finiteFieldStripEntryFactorList /@ Flatten[bbar], 1];
  factors = If[factorPairs === {}, {},
    DeleteDuplicates[factorPairs[[All, 1]], SameQ]];
  factorPowers = Table[
    {factor, Max[Cases[factorPairs,
      {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
    {factor, factors}];
  gaugeFactorPowers = Select[factorPowers,
    Last[#] > 1 && ! FreeQ[First[#], Alternatives @@ variables] &];
  gaugeDenominator = Times @@
    ((First[#]^(Last[#] - 1)) & /@ gaugeFactorPowers);
  denominatorDegrees = Exponent[gaugeDenominator, #] & /@ variables;
  numeratorDegrees = denominatorDegrees + degreeOffset;
  equationCount = 2 upperDimension lowerDimension;
  gaugeUnknownCount = upperDimension lowerDimension
    (numeratorDegrees[[1]] + 1) (numeratorDegrees[[2]] + 1);
  unknownCount = gaugeUnknownCount + Length[freeResidues];
  requestedPointCount = Replace[requestedPointCount,
    Automatic :> Max[16,
      Ceiling[(unknownCount + equationCount)/equationCount]]];
  maximumAttempts = 20 requestedPointCount;
  epsilonMod = Mod[
    Numerator[epsilonValue]*
      PowerMod[Mod[Denominator[epsilonValue], prime], -1, prime],
    prime];

  modNumber[value_] := Module[{numeratorValue, denominatorValue},
    If[! FreeQ[value, _Symbol],
      Throw[<|
        "Status" -> "BadCoefficient",
        "BadCoefficientSymbols" ->
          DeleteDuplicates[Cases[value, _Symbol, Infinity]],
        "BadCoefficientHead" -> Head[value],
        "BadCoefficientDimensions" -> Dimensions[value],
        "PreprocessingLabel" -> preprocessingLabel
      |>, "BadCoefficient"]];
    numeratorValue = Mod[Numerator[value], prime];
    denominatorValue = Mod[Denominator[value], prime];
    If[denominatorValue === 0, Throw[$Failed, "BadCoefficient"]];
    Mod[numeratorValue PowerMod[denominatorValue, -1, prime], prime]
  ];
  polynomialRules[polynomial_] :=
    ({First[#], modNumber[Last[#]]} &) /@
      (List @@@ CoefficientRules[polynomial, variables]);
  rationalForm[expression_] := Module[{q = Together[expression]},
    {polynomialRules[Numerator[q]], polynomialRules[Denominator[q]]}
  ];
  evaluatePolynomial[rules_List, xValue_Integer,
      yValue_Integer] := Mod[
    Total[(#[[2]] PowerMod[Mod[xValue, prime], #[[1, 1]], prime]*
        PowerMod[Mod[yValue, prime], #[[1, 2]], prime]) & /@ rules],
    prime];
  evaluateRational[form_List, xValue_Integer,
      yValue_Integer] := Module[
    {numeratorValue, denominatorValue},
    numeratorValue = evaluatePolynomial[form[[1]], xValue, yValue];
    denominatorValue = evaluatePolynomial[form[[2]], xValue, yValue];
    If[denominatorValue === 0, Throw[$Failed, "BadPoint"]];
    Mod[numeratorValue PowerMod[denominatorValue, -1, prime], prime]
  ];

  setupSeconds = AbsoluteTime[] - setupStart;
  {preprocessingSeconds, preprocessedForms} = AbsoluteTiming[
    Catch[{
      (preprocessingLabel = "UpperDiagonal";
        Map[rationalForm, e /. epsilon -> epsilonValue, {3}]),
      (preprocessingLabel = "LowerDiagonal";
        Map[rationalForm, c /. epsilon -> epsilonValue, {3}]),
      (preprocessingLabel = "ForcingConstant";
        Map[rationalForm,
          forcingConstant /. epsilon -> epsilonValue, {3}]),
      (preprocessingLabel = "ForcingCoefficients";
       Table[
        Map[rationalForm,
          forcingCoefficients[[residueIndex]] /.
            epsilon -> epsilonValue, {3}],
        {residueIndex, Length[freeResidues]}]),
      (preprocessingLabel = "GaugeDenominator";
        rationalForm[gaugeDenominator /. epsilon -> epsilonValue]),
      (preprocessingLabel = "GaugeDenominatorDerivatives";
        rationalForm[# /. epsilon -> epsilonValue] & /@
          (D[gaugeDenominator, #] & /@ variables))
    }, "BadCoefficient"]];
  If[AssociationQ[preprocessedForms] &&
      Lookup[preprocessedForms, "Status", None] === "BadCoefficient",
    Return[Join[preprocessedForms, <|
      "EpsilonValue" -> epsilonValue,
      "Prime" -> prime,
      "SetupSeconds" -> setupSeconds,
      "PreprocessingSeconds" -> preprocessingSeconds,
      "AlphabetLength" -> Length[alphabet],
      "ResidueTriplesDimensions" -> Dimensions[residueTriples],
      "ForcingCoefficientsDimensions" ->
        Dimensions[forcingCoefficients],
      "FirstForcingCoefficientDimensions" ->
        Dimensions[First[forcingCoefficients]],
      "FirstForcingCoefficientArrayDepth" ->
        ArrayDepth[First[forcingCoefficients]]
    |>]]];
  {eForms, cForms, forcingConstantForms, forcingCoefficientForms,
    gaugeDenominatorForm, gaugeDenominatorDerivativeForms} =
      preprocessedForms;

  columnIndex[i_, j_, px_, py_] :=
    (((i - 1) lowerDimension + (j - 1))
      (numeratorDegrees[[1]] + 1) + px)
      (numeratorDegrees[[2]] + 1) + py + 1;

  buildPointRows[xValue_Integer, yValue_Integer] := Catch[Module[
    {eValue, cValue, forcing0Value, forcingFreeValue,
     denominatorValue, derivativeDenominatorValues,
     inverseDenominator, xPowers, yPowers, phi, derivativePhi,
     rows, right, rowIndex = 0, row, coefficient, column,
     mu, i, j, aIndex, bIndex, px, py, residueIndex},
    eValue = Map[evaluateRational[#, xValue, yValue] &, eForms, {3}];
    cValue = Map[evaluateRational[#, xValue, yValue] &, cForms, {3}];
    forcing0Value = Map[evaluateRational[#, xValue, yValue] &,
      forcingConstantForms, {3}];
    forcingFreeValue = Table[
      Map[evaluateRational[#, xValue, yValue] &,
        forcingCoefficientForms[[residueIndex]], {3}],
      {residueIndex, Length[freeResidues]}];
    denominatorValue = evaluateRational[
      gaugeDenominatorForm, xValue, yValue];
    inverseDenominator = PowerMod[denominatorValue, -1, prime];
    derivativeDenominatorValues =
      evaluateRational[#, xValue, yValue] & /@
        gaugeDenominatorDerivativeForms;
    xPowers = Table[PowerMod[Mod[xValue, prime], power, prime],
      {power, 0, numeratorDegrees[[1]]}];
    yPowers = Table[PowerMod[Mod[yValue, prime], power, prime],
      {power, 0, numeratorDegrees[[2]]}];
    phi = Table[
      Mod[xPowers[[px + 1]] yPowers[[py + 1]] inverseDenominator,
        prime],
      {px, 0, numeratorDegrees[[1]]},
      {py, 0, numeratorDegrees[[2]]}];
    derivativePhi = Table[
      Mod[
        If[mu === 1,
          If[px === 0, 0,
            px xPowers[[px]] yPowers[[py + 1]]] inverseDenominator,
          If[py === 0, 0,
            py xPowers[[px + 1]] yPowers[[py]]] inverseDenominator] -
          phi[[px + 1, py + 1]]*
            derivativeDenominatorValues[[mu]]*inverseDenominator,
        prime],
      {mu, 2}, {px, 0, numeratorDegrees[[1]]},
      {py, 0, numeratorDegrees[[2]]}];
    rows = ConstantArray[0, {equationCount, unknownCount}];
    right = ConstantArray[0, equationCount];
    Do[
      rowIndex++;
      row = rows[[rowIndex]];
      Do[
        column = columnIndex[i, j, px, py];
        row[[column]] = derivativePhi[[mu, px + 1, py + 1]],
        {px, 0, numeratorDegrees[[1]]},
        {py, 0, numeratorDegrees[[2]]}];
      Do[
        Do[
          column = columnIndex[aIndex, j, px, py];
          coefficient = -epsilonMod eValue[[mu, i, aIndex]]*
            phi[[px + 1, py + 1]];
          row[[column]] = Mod[row[[column]] + coefficient, prime],
          {px, 0, numeratorDegrees[[1]]},
          {py, 0, numeratorDegrees[[2]]}],
        {aIndex, upperDimension}];
      Do[
        Do[
          column = columnIndex[i, bIndex, px, py];
          coefficient = epsilonMod phi[[px + 1, py + 1]]*
            cValue[[mu, bIndex, j]];
          row[[column]] = Mod[row[[column]] + coefficient, prime],
          {px, 0, numeratorDegrees[[1]]},
          {py, 0, numeratorDegrees[[2]]}],
        {bIndex, lowerDimension}];
      Do[
        row[[gaugeUnknownCount + residueIndex]] = Mod[
          -forcingFreeValue[[residueIndex, mu, i, j]], prime],
        {residueIndex, Length[freeResidues]}];
      rows[[rowIndex]] = row;
      right[[rowIndex]] = forcing0Value[[mu, i, j]],
      {mu, 2}, {i, upperDimension}, {j, lowerDimension}];
    {SparseArray[rows], right}
  ], "BadPoint"];

  SeedRandom[randomSeed];
  {samplingSeconds, samplingResult} = AbsoluteTiming[
    While[Length[acceptedPoints] < requestedPointCount &&
        attemptCount < maximumAttempts,
      attemptCount++;
      point = RandomInteger[{2, prime - 2}, 2];
      pointResult = buildPointRows @@ point;
      If[pointResult =!= $Failed,
        AppendTo[acceptedPoints, point];
        AppendTo[pointRows, pointResult[[1]]];
        AppendTo[pointRightHandSides, pointResult[[2]]]]]];
  If[Length[acceptedPoints] < requestedPointCount, Return[$Failed]];
  matrix = Join @@ pointRows;
  rightHandSide = Join @@ pointRightHandSides;
  peakMemoryBytes = MaxMemoryUsed[];

  <|
    "EpsilonValue" -> epsilonValue,
    "Prime" -> prime,
    "AcceptedPoints" -> acceptedPoints,
    "AttemptCount" -> attemptCount,
    "MatrixDimensions" -> Dimensions[matrix],
    "GaugeDimensions" -> dimensions,
    "Alphabet" -> alphabet,
    "GaugeDenominator" -> gaugeDenominator,
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "FreeResidueCount" -> Length[freeResidues],
    "UnknownCount" -> unknownCount,
    "NonzeroEntries" -> Length[matrix["NonzeroValues"]],
    "SetupSeconds" -> setupSeconds,
    "PreprocessingSeconds" -> preprocessingSeconds,
    "SamplingSeconds" -> samplingSeconds,
    "PeakMemoryBytes" -> peakMemoryBytes,
    "PeakMemoryGrowthBytes" -> Max[0,
      peakMemoryBytes - maximumMemoryBefore],
    "Matrix" -> matrix,
    "RightHandSide" -> rightHandSide
  |>
];

(*
  Prototype capture seam. This later definition intentionally replaces the
  copied builder above. It lets the package construct the exact production
  matrix, while an inherited in-memory definition intercepts only the two
  terminal MatrixRank calls. No package source or persistent definition is
  changed. The standard implementation should expose this builder directly.
*)
CodexM1BuildSampleSystem[
    record_Association, epsilonValue_, prime_Integer,
    OptionsPattern[]] := Module[
  {pointCount, degreeOffset, randomSeed, captureMinimumDimension,
   rankCallCount = 0,
   capturedMatrix = Missing["NotCaptured"],
   capturedAugmented = Missing["NotCaptured"], sample,
   rightHandSide, metadata},
  pointCount = OptionValue["PointCount"];
  degreeOffset = OptionValue["NumeratorDegreeOffset"];
  randomSeed = OptionValue["RandomSeed"];
  captureMinimumDimension = OptionValue["CaptureMinimumDimension"];
  If[! IntegerQ[captureMinimumDimension] ||
      captureMinimumDimension < 1, Return[$Failed]];
  sample = Internal`InheritedBlock[{MatrixRank},
    Unprotect[MatrixRank];
    MatrixRank[argument_?(
        MatrixQ[#] && Length[Dimensions[#]] === 2 &&
        Min[Dimensions[#]] > captureMinimumDimension &),
        rankOptions___] := Module[{},
      rankCallCount++;
      Switch[rankCallCount,
        1, capturedMatrix = argument; 0,
        2, capturedAugmented = argument; 0,
        _, 0]
    ];
    SampleEpsFormStripAffine[
      record, epsilonValue, prime,
      "PointCount" -> pointCount,
      "NumeratorDegreeOffset" -> degreeOffset,
      "SolveAffineSystem" -> False,
      "RandomSeed" -> randomSeed]
  ];
  If[! AssociationQ[sample] || rankCallCount =!= 2 ||
      ! MatrixQ[capturedMatrix] ||
      ! MatrixQ[capturedAugmented] ||
      Dimensions[capturedAugmented] =!=
        Dimensions[capturedMatrix] + {0, 1},
    Return[$Failed]];
  rightHandSide = Normal[capturedAugmented[[All, -1]]];
  metadata = KeyDrop[sample,
    {"Rank", "AugmentedRank", "Nullity", "Consistent",
     "RankSeconds", "AugmentedRankSeconds"}];
  Join[metadata, <|
    "UnknownCount" -> Dimensions[capturedMatrix][[2]],
    "Matrix" -> capturedMatrix,
    "RightHandSide" -> rightHandSide,
    "CaptureMethod" -> "InheritedBlockMatrixRankInterception"
  |>]
];

codexM1ZeroVectorQ[values_, prime_Integer] :=
  VectorQ[values] && AllTrue[Mod[values, prime], # === 0 &];

codexM1ZeroMatrixQ[values_, prime_Integer] :=
  MatrixQ[values] && AllTrue[Flatten[Mod[values, prime]], # === 0 &];

codexM1SampleMetadata[system_Association] := KeyDrop[system,
  {"Matrix", "RightHandSide", "UnknownCount",
   "PeakMemoryGrowthBytes"}];

CodexM1BaselineSolveSystem[system_Association] := Module[
  {matrix, rightHandSide, prime, augmented, rank, augmentedRank,
   particular, nullspace, rankSeconds, augmentedRankSeconds,
   linearSolveSeconds, nullspaceSeconds},
  If[! And @@ (KeyExistsQ[system, #] & /@
      {"Matrix", "RightHandSide", "Prime"}), Return[$Failed]];
  matrix = system["Matrix"];
  rightHandSide = system["RightHandSide"];
  prime = system["Prime"];
  augmented = Join[matrix,
    SparseArray[List /@ rightHandSide], 2];
  {rankSeconds, rank} = AbsoluteTiming[
    MatrixRank[matrix, Modulus -> prime]];
  {augmentedRankSeconds, augmentedRank} = AbsoluteTiming[
    MatrixRank[augmented, Modulus -> prime]];
  If[rank =!= augmentedRank,
    Return[<|
      "Status" -> "BaselineRankMismatch",
      "Rank" -> rank,
      "AugmentedRank" -> augmentedRank,
      "RankSeconds" -> rankSeconds,
      "AugmentedRankSeconds" -> augmentedRankSeconds,
      "RightHandSideLength" -> Length[rightHandSide],
      "RightHandSideHash" -> Hash[rightHandSide]
    |>]];
  {linearSolveSeconds, particular} = AbsoluteTiming[
    LinearSolve[matrix, rightHandSide, Modulus -> prime]];
  {nullspaceSeconds, nullspace} = AbsoluteTiming[
    NullSpace[matrix, Modulus -> prime]];
  Join[codexM1SampleMetadata[system], <|
    "Rank" -> rank,
    "AugmentedRank" -> augmentedRank,
    "Nullity" -> Length[nullspace],
    "Consistent" -> True,
    "RankSeconds" -> rankSeconds,
    "AugmentedRankSeconds" -> augmentedRankSeconds,
    "LinearSolveSeconds" -> linearSolveSeconds,
    "NullspaceSeconds" -> nullspaceSeconds,
    "ParticularSolution" -> particular,
    "NullspaceBasis" -> nullspace,
    "ParticularCheckZero" -> codexM1ZeroVectorQ[
      matrix.particular - rightHandSide, prime],
    "NullspaceCheckZero" -> If[nullspace === {}, True,
      codexM1ZeroMatrixQ[matrix.Transpose[nullspace], prime]],
    "SolvePath" -> "BaselineFourEliminations"
  |>]
];

codexM1IndependentNormalizationColumns[
    nullspace_List, gaugeUnknownCount_Integer,
    freeResidueCount_Integer, prime_Integer] := Module[
  {residueColumns, residueBlock, rowReduced, localColumns},
  If[nullspace === {}, Return[{}]];
  residueColumns = gaugeUnknownCount + Range[freeResidueCount];
  residueBlock = nullspace[[All, residueColumns]];
  rowReduced = RowReduce[residueBlock, Modulus -> prime];
  localColumns = DeleteMissing[
    Function[row,
      FirstCase[Range[Length[row]],
        index_ /; row[[index]] =!= 0, Missing["NoPivot"]]] /@
      rowReduced];
  If[Length[localColumns] =!= Length[nullspace], Return[$Failed]];
  gaugeUnknownCount + localColumns
];

codexM1IndependentEquationRows[matrix_, rank_Integer,
    prime_Integer] := Module[
  {candidateRows, candidateRank, candidateSeconds,
   leftNullspace, leftNullspaceSeconds, rowReduced,
   rowReduceSeconds, pivotColumns, independentRows,
   verificationRank, verificationSeconds},
  candidateRows = Range[rank];
  {candidateSeconds, candidateRank} = AbsoluteTiming[
    MatrixRank[matrix[[candidateRows]], Modulus -> prime]];
  If[candidateRank === rank,
    Return[<|
      "IndependentRows" -> candidateRows,
      "Method" -> "LeadingRows",
      "CandidateRankSeconds" -> candidateSeconds,
      "LeftNullspaceSeconds" -> 0.,
      "RowReduceSeconds" -> 0.,
      "VerificationSeconds" -> candidateSeconds
    |>]];

  {leftNullspaceSeconds, leftNullspace} = AbsoluteTiming[
    NullSpace[Transpose[matrix], Modulus -> prime]];
  {rowReduceSeconds, rowReduced} = AbsoluteTiming[
    RowReduce[leftNullspace, Modulus -> prime]];
  pivotColumns = DeleteMissing[
    Function[row,
      FirstCase[Range[Length[row]],
        index_ /; row[[index]] =!= 0, Missing["NoPivot"]]] /@
      rowReduced];
  independentRows = Complement[Range[Length[matrix]], pivotColumns];
  {verificationSeconds, verificationRank} = AbsoluteTiming[
    MatrixRank[matrix[[independentRows]], Modulus -> prime]];
  If[Length[independentRows] =!= rank || verificationRank =!= rank,
    Return[$Failed]];
  <|
    "IndependentRows" -> independentRows,
    "Method" -> "LeftNullspacePivots",
    "CandidateRankSeconds" -> candidateSeconds,
    "LeftNullspaceSeconds" -> leftNullspaceSeconds,
    "RowReduceSeconds" -> rowReduceSeconds,
    "VerificationSeconds" -> verificationSeconds
  |>
];

CodexM1DiscoverPilotPlan[system_Association] := Module[
  {matrix, rightHandSide, prime, augmented, rank, augmentedRank,
   particular, nullspace, rankSeconds, augmentedRankSeconds,
   linearSolveSeconds, nullspaceSeconds, normalizationColumns,
   residueBlock, residueBlockRank, normalized, rowSelection,
   independentRows, selector,
   constrainedCore, coreRank, coreRankSeconds, plan, sample},
  If[! And @@ (KeyExistsQ[system, #] & /@
      {"Matrix", "RightHandSide", "Prime", "GaugeUnknownCount",
       "FreeResidueCount"}), Return[$Failed]];
  matrix = system["Matrix"];
  rightHandSide = system["RightHandSide"];
  prime = system["Prime"];
  augmented = Join[matrix,
    SparseArray[List /@ rightHandSide], 2];
  {rankSeconds, rank} = AbsoluteTiming[
    MatrixRank[matrix, Modulus -> prime]];
  {augmentedRankSeconds, augmentedRank} = AbsoluteTiming[
    MatrixRank[augmented, Modulus -> prime]];
  If[rank =!= augmentedRank,
    Return[<|
      "Status" -> "PilotRankMismatch",
      "Rank" -> rank,
      "AugmentedRank" -> augmentedRank,
      "RankSeconds" -> rankSeconds,
      "AugmentedRankSeconds" -> augmentedRankSeconds,
      "RightHandSideLength" -> Length[rightHandSide],
      "RightHandSideHash" -> Hash[rightHandSide]
    |>]];
  {linearSolveSeconds, particular} = AbsoluteTiming[
    LinearSolve[matrix, rightHandSide, Modulus -> prime]];
  {nullspaceSeconds, nullspace} = AbsoluteTiming[
    NullSpace[matrix, Modulus -> prime]];
  residueBlock = nullspace[[All,
    system["GaugeUnknownCount"] +
      Range[system["FreeResidueCount"]]]];
  residueBlockRank = MatrixRank[residueBlock, Modulus -> prime];
  normalizationColumns = codexM1IndependentNormalizationColumns[
    nullspace, system["GaugeUnknownCount"],
    system["FreeResidueCount"], prime];
  If[normalizationColumns === $Failed,
    Return[<|"Status" -> "PilotNormalizationDiscoveryFailed",
      "Rank" -> rank, "Nullity" -> Length[nullspace],
      "ResidueBlockDimensions" -> Dimensions[residueBlock],
      "ResidueBlockRank" -> residueBlockRank|>]];
  sample = Join[codexM1SampleMetadata[system], <|
    "Rank" -> rank,
    "AugmentedRank" -> augmentedRank,
    "Nullity" -> Length[nullspace],
    "Consistent" -> True,
    "RankSeconds" -> rankSeconds,
    "AugmentedRankSeconds" -> augmentedRankSeconds,
    "LinearSolveSeconds" -> linearSolveSeconds,
    "NullspaceSeconds" -> nullspaceSeconds,
    "ParticularSolution" -> particular,
    "NullspaceBasis" -> nullspace,
    "ParticularCheckZero" -> codexM1ZeroVectorQ[
      matrix.particular - rightHandSide, prime],
    "NullspaceCheckZero" -> If[nullspace === {}, True,
      codexM1ZeroMatrixQ[matrix.Transpose[nullspace], prime]],
    "SolvePath" -> "PilotFourEliminations"
  |>];
  normalized = NormalizeEpsFormAffineSample[
    sample, normalizationColumns, prime];
  If[normalized === $Failed,
    Return[<|"Status" -> "PilotNormalizationFailed",
      "NormalizationColumns" -> normalizationColumns|>]];

  rowSelection = codexM1IndependentEquationRows[
    matrix, rank, prime];
  If[rowSelection === $Failed,
    Return[<|"Status" -> "PilotRowSelectionFailed"|>]];
  independentRows = rowSelection["IndependentRows"];
  selector = SparseArray[
    MapIndexed[{First[#2], #1} -> 1 &, normalizationColumns],
    {Length[normalizationColumns], Length[First[matrix]]}];
  constrainedCore = Join[matrix[[independentRows]], selector];
  {coreRankSeconds, coreRank} = AbsoluteTiming[
    MatrixRank[constrainedCore, Modulus -> prime]];
  If[coreRank =!= Length[First[matrix]],
    Return[<|
      "Status" -> "PilotConstrainedCoreRankMismatch",
      "ConstrainedCoreRank" -> coreRank,
      "UnknownCount" -> Length[First[matrix]],
      "NormalizationColumns" -> normalizationColumns,
      "IndependentRowCount" -> Length[independentRows]
    |>]];

  plan = <|
    "PilotPrime" -> prime,
    "PilotEpsilonValue" -> system["EpsilonValue"],
    "NormalizationColumns" -> normalizationColumns,
    "IndependentEquationRows" -> independentRows,
    "GenericRank" -> rank,
    "Nullity" -> Length[nullspace],
    "UnknownCount" -> Length[First[matrix]],
    "MatrixRowCount" -> Length[matrix],
    "GaugeUnknownCount" -> system["GaugeUnknownCount"],
    "FreeResidueCount" -> system["FreeResidueCount"],
    "GaugeNumeratorDegrees" -> system["GaugeNumeratorDegrees"],
    "GaugeDenominatorDegrees" -> system["GaugeDenominatorDegrees"],
    "RowSelection" -> KeyDrop[rowSelection, "IndependentRows"],
    "ConstrainedCoreRankSeconds" -> coreRankSeconds,
    "ConstrainedCoreRank" -> coreRank
  |>;
  <|
    "Plan" -> plan,
    "PilotSample" -> sample,
    "NormalizedPilot" -> normalized
  |>
];

CodexM1SolveConstrainedSample[
    system_Association, plan_Association] := Module[
  {matrix, rightHandSide, prime, independentRows,
   normalizationColumns, rank, nullity, unknownCount, selector,
   selectedMatrix, selectedRightHandSide, constrainedCore,
   topRightHandSides, bottomRightHandSides, multipleRightHandSides,
   solutionMatrix, solveSeconds, particular, nullspace,
   particularCheck, nullspaceCheck, normalizationCheck,
   maximumMemoryBefore, peakMemoryBytes},
  If[! And @@ (KeyExistsQ[system, #] & /@
      {"Matrix", "RightHandSide", "Prime", "GaugeUnknownCount",
       "FreeResidueCount", "GaugeNumeratorDegrees",
       "GaugeDenominatorDegrees"}) ||
      ! And @@ (KeyExistsQ[plan, #] & /@
      {"IndependentEquationRows", "NormalizationColumns",
       "GenericRank", "Nullity", "UnknownCount",
       "GaugeUnknownCount", "FreeResidueCount",
       "GaugeNumeratorDegrees", "GaugeDenominatorDegrees"}),
    Return[$Failed]];
  If[system["GaugeUnknownCount"] =!= plan["GaugeUnknownCount"] ||
      system["FreeResidueCount"] =!= plan["FreeResidueCount"] ||
      system["GaugeNumeratorDegrees"] =!=
        plan["GaugeNumeratorDegrees"] ||
      system["GaugeDenominatorDegrees"] =!=
        plan["GaugeDenominatorDegrees"], Return[$Failed]];

  matrix = system["Matrix"];
  rightHandSide = system["RightHandSide"];
  prime = system["Prime"];
  independentRows = plan["IndependentEquationRows"];
  normalizationColumns = plan["NormalizationColumns"];
  rank = plan["GenericRank"];
  nullity = plan["Nullity"];
  unknownCount = plan["UnknownCount"];
  If[Length[independentRows] =!= rank ||
      Length[normalizationColumns] =!= nullity ||
      rank + nullity =!= unknownCount ||
      Dimensions[matrix][[2]] =!= unknownCount ||
      Max[independentRows] > Length[matrix], Return[$Failed]];

  selector = SparseArray[
    MapIndexed[{First[#2], #1} -> 1 &, normalizationColumns],
    {nullity, unknownCount}];
  selectedMatrix = matrix[[independentRows]];
  selectedRightHandSide = rightHandSide[[independentRows]];
  constrainedCore = Join[selectedMatrix, selector];
  topRightHandSides = Join[
    List /@ selectedRightHandSide,
    ConstantArray[0, {rank, nullity}], 2];
  bottomRightHandSides = Join[
    ConstantArray[0, {nullity, 1}], IdentityMatrix[nullity], 2];
  multipleRightHandSides = Join[
    topRightHandSides, bottomRightHandSides];

  maximumMemoryBefore = MaxMemoryUsed[];
  {solveSeconds, solutionMatrix} = AbsoluteTiming[
    Quiet[Check[
      LinearSolve[constrainedCore, multipleRightHandSides,
        Modulus -> prime], $Failed]]];
  peakMemoryBytes = MaxMemoryUsed[];
  If[solutionMatrix === $Failed ||
      ! MatrixQ[solutionMatrix, IntegerQ] ||
      Dimensions[solutionMatrix] =!= {unknownCount, nullity + 1},
    Return[Join[codexM1SampleMetadata[system], <|
      "Status" -> "DiscardRankLosingSample",
      "ConstrainedSolveSeconds" -> solveSeconds,
      "ConstrainedPeakMemoryBytes" -> peakMemoryBytes,
      "ConstrainedPeakMemoryGrowthBytes" -> Max[0,
        peakMemoryBytes - maximumMemoryBefore]
    |>]]];

  particular = solutionMatrix[[All, 1]];
  nullspace = If[nullity === 0, {},
    Transpose[solutionMatrix[[All, 2 ;;]]]];
  particularCheck = codexM1ZeroVectorQ[
    matrix.particular - rightHandSide, prime];
  nullspaceCheck = If[nullity === 0, True,
    codexM1ZeroMatrixQ[matrix.Transpose[nullspace], prime]];
  normalizationCheck =
    particular[[normalizationColumns]] ===
      ConstantArray[0, nullity] &&
    (nullity === 0 ||
      nullspace[[All, normalizationColumns]] ===
        IdentityMatrix[nullity]);
  If[! TrueQ[particularCheck && nullspaceCheck && normalizationCheck],
    Return[Join[codexM1SampleMetadata[system], <|
      "Status" -> "DiscardFailedResidualCheck",
      "ConstrainedSolveSeconds" -> solveSeconds,
      "ParticularCheckZero" -> particularCheck,
      "NullspaceCheckZero" -> nullspaceCheck,
      "NormalizationCheck" -> normalizationCheck
    |>]]];

  Join[codexM1SampleMetadata[system], <|
    "Status" -> "Solved",
    "Rank" -> rank,
    "AugmentedRank" -> rank,
    "Nullity" -> nullity,
    "Consistent" -> True,
    "RankSeconds" -> 0.,
    "AugmentedRankSeconds" -> 0.,
    "LinearSolveSeconds" -> solveSeconds,
    "NullspaceSeconds" -> 0.,
    "ConstrainedSolveSeconds" -> solveSeconds,
    "ConstrainedCoreDimensions" -> Dimensions[constrainedCore],
    "ConstrainedCoreNonzeroEntries" ->
      Length[constrainedCore["NonzeroValues"]],
    "ConstrainedPeakMemoryBytes" -> peakMemoryBytes,
    "ConstrainedPeakMemoryGrowthBytes" -> Max[0,
      peakMemoryBytes - maximumMemoryBefore],
    "ParticularSolution" -> particular,
    "NullspaceBasis" -> nullspace,
    "ParticularCheckZero" -> particularCheck,
    "NullspaceCheckZero" -> nullspaceCheck,
    "NormalizationCheck" -> normalizationCheck,
    "SolvePath" -> "OneConstrainedMultiRHSFactorization"
  |>]
];

CodexM1CanonicalAgreementQ[
    baselineSample_Association, constrainedSample_Association,
    normalizationColumns_List, prime_Integer] := Module[
  {canonical},
  canonical = NormalizeEpsFormAffineSample[
    baselineSample, normalizationColumns, prime];
  AssociationQ[canonical] &&
    canonical["ParticularSolution"] ===
      constrainedSample["ParticularSolution"] &&
    canonical["NullspaceBasis"] ===
      constrainedSample["NullspaceBasis"]
];
