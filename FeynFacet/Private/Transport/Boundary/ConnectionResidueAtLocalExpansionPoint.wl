(* Exact connection residues at a local expansion point, computed directly
   from the declared iterated-integral alphabet.
   No symbolic connection matrix is assembled. *)

Clear[ComputeConnectionResidueAtLocalExpansionPoint];
ClearAll[connectionResidueAtLocalExpansionPointZeroQ,
  connectionResidueAtLocalExpansionPointSparse,
  connectionResidueAtLocalExpansionPointVanishingData];

connectionResidueAtLocalExpansionPointZeroQ[value_] :=
  TrueQ[value === 0] || TrueQ[PossibleZeroQ[value]];

connectionResidueAtLocalExpansionPointSparse[matrix_, dimensions_] := SparseArray[
  Cases[Most[ArrayRules[SparseArray[matrix]]],
    (position_ -> value_) :> position -> Together[value]],
  dimensions
];

connectionResidueAtLocalExpansionPointVanishingData[
    polynomial_, variable_Symbol, localExpansionPoint_] := Module[
  {degree, coefficients, firstNonzero},
  If[! PolynomialQ[polynomial, variable] ||
      connectionResidueAtLocalExpansionPointZeroQ[polynomial],
    Return[$Failed]];
  degree = Exponent[polynomial, variable];
  coefficients = Table[
    Together[(D[polynomial, {variable, order}] /.
        variable -> localExpansionPoint)/
      Factorial[order]],
    {order, 0, degree}];
  firstNonzero = SelectFirst[Range[Length[coefficients]],
    ! connectionResidueAtLocalExpansionPointZeroQ[coefficients[[#]]] &,
    Missing["NotFound"]];
  If[MissingQ[firstNonzero], $Failed,
    {firstNonzero - 1, coefficients[[firstNonzero]]}]
];

Options[ComputeConnectionResidueAtLocalExpansionPoint] = {
  "Curve" -> None,
  "CompositeDefinitions" -> <||>
};

ComputeConnectionResidueAtLocalExpansionPoint[
    letters_List, residueMatrices_List, variable_Symbol,
    localExpansionPoint_, OptionsPattern[]] := Catch@Module[
  {fail, curve = OptionValue["Curve"],
   definitions = OptionValue["CompositeDefinitions"], dimensions,
   matrixDimensions, resolve, resolved, flatResolved, curveQ,
   curveAtLocalExpansionPoint,
   rationalWeight, oneWeight, weights, residue, active, curveHeads},

  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[Length[letters] =!= Length[residueMatrices] || letters === {} ||
      ! AssociationQ[definitions] ||
      ! FreeQ[localExpansionPoint, variable],
    fail["ConnectionResidueAtLocalExpansionPointInputsNotWellFormed"]];
  dimensions = Dimensions /@ residueMatrices;
  If[! SameQ @@ dimensions || ! MatchQ[First[dimensions],
      {_Integer?Positive, _Integer?Positive}],
    fail["ConnectionResidueMatricesNotAligned",
      <|"MatrixDimensions" -> dimensions|>]];
  matrixDimensions = First[dimensions];

  resolve[current_, stack_List] := Module[
    {currentDefinition, currentTerms, coefficient, baseLetter},
    If[MemberQ[stack, current],
      fail["CompositeLetterCycle", <|"Letter" -> current|>]];
    currentDefinition = Lookup[definitions, Key[current], Missing["BaseLetter"]];
    If[MissingQ[currentDefinition], Return[{{1, current}}]];
    If[! MatchQ[currentDefinition, {{_, _List} ..}],
      fail["CompositeLetterDefinitionInvalid", <|"Letter" -> current|>]];
    currentTerms = Flatten[Table[
      {coefficient, baseLetter} = term;
      If[! FreeQ[coefficient, variable],
        fail["CompositeCoefficientDependsOnPathVariable",
          <|"Letter" -> current, "Coefficient" -> coefficient|>]];
      ({Together[coefficient #[[1]]], #[[2]]} &) /@
        resolve[baseLetter, Append[stack, current]],
      {term, currentDefinition}], 1];
    DeleteCases[currentTerms,
      {value_ /; connectionResidueAtLocalExpansionPointZeroQ[value], _}]
  ];

  resolved = resolve[#, {}] & /@ letters;
  flatResolved = If[resolved === {}, {}, Join @@ resolved];
  curveHeads = {"E4Pole", "E4Factor", "E4Omega0", "E4OmegaInf", "E4Eta2"};
  curveQ = AnyTrue[flatResolved,
    MatchQ[Last[#], {head_String /; MemberQ[curveHeads, head], ___}] &];
  If[curveQ,
    If[curve === None,
      fail["LocalExpansionPointCurveDeclarationRequired"]];
    If[! PolynomialQ[curve, variable] || Exponent[curve, variable] =!= 4,
      fail["LocalExpansionPointCurveNotQuartic"]];
    If[connectionResidueAtLocalExpansionPointZeroQ[
        Together[Discriminant[curve, variable]]],
      fail["EllipticCurveDegenerate"]];
    curveAtLocalExpansionPoint = Together[curve /.
      variable -> localExpansionPoint];
    If[connectionResidueAtLocalExpansionPointZeroQ[
        curveAtLocalExpansionPoint],
      fail["EllipticCurveDegeneratesAtLocalExpansionPoint",
        <|"LocalExpansionPoint" -> localExpansionPoint|>]],
    curveAtLocalExpansionPoint = None
  ];

  rationalWeight[numerator_, denominator_, currentLabel_] := Module[
    {numeratorData, denominatorData, poleOrder},
    denominatorData = connectionResidueAtLocalExpansionPointVanishingData[
      denominator, variable, localExpansionPoint];
    If[denominatorData === $Failed,
      fail["ConnectionLetterMalformedAtLocalExpansionPoint",
        <|"Letter" -> currentLabel|>]];
    If[First[denominatorData] === 0, Return[0]];
    numeratorData = connectionResidueAtLocalExpansionPointVanishingData[
      numerator, variable, localExpansionPoint];
    If[numeratorData === $Failed, Return[0]];
    poleOrder = First[denominatorData] - First[numeratorData];
    If[poleOrder > 1,
      fail["ConnectionHigherOrderPoleAtLocalExpansionPoint", <|
        "Letter" -> currentLabel, "PoleOrder" -> poleOrder|>]];
    If[poleOrder === 1,
      Together[Last[numeratorData]/Last[denominatorData]], 0]
  ];

  oneWeight[currentLabel_] := Replace[currentLabel, {
    {"GPLPole", point_} :>
      rationalWeight[1, variable - point, currentLabel],
    {"GPLFactor", polynomial_, power_Integer} :> (
      If[power < 0,
        fail["ConnectionLetterMalformedAtLocalExpansionPoint",
        <|"Letter" -> currentLabel|>]];
      rationalWeight[variable^power, polynomial, currentLabel]),
    {"E4Pole", point_} :>
      If[connectionResidueAtLocalExpansionPointZeroQ[
          Together[localExpansionPoint - point]], 1, 0],
    {"E4Factor", polynomial_, power_Integer} :> (
      If[power < 0,
        fail["ConnectionLetterMalformedAtLocalExpansionPoint",
        <|"Letter" -> currentLabel|>]];
      Together[rationalWeight[variable^power, polynomial, currentLabel]/
        Sqrt[curveAtLocalExpansionPoint]]),
    {"E4Omega0"} | {"E4OmegaInf"} | {"E4Eta2"} :>
      0,
    _ :>
      fail["ConnectionLetterNotSupportedAtLocalExpansionPoint",
        <|"Letter" -> currentLabel|>]
  }];

  weights = Map[
    Function[currentTerms,
      Together@Total[(First[#] oneWeight[Last[#]]) & /@ currentTerms]],
    resolved];
  active = Flatten@Position[weights,
    value_ /; ! connectionResidueAtLocalExpansionPointZeroQ[value],
    {1}, Heads -> False];
  residue = connectionResidueAtLocalExpansionPointSparse[
    Total@MapThread[Times, {weights, residueMatrices}],
    matrixDimensions];

  <|
    "Status" -> "ConnectionResidueAtLocalExpansionPointComputed",
    "Variable" -> variable,
    "LocalExpansionPoint" -> localExpansionPoint,
    "MatrixDimensions" -> matrixDimensions,
    "Dimension" -> If[SameQ @@ matrixDimensions,
      First[matrixDimensions], Missing["Rectangular"]],
    "LetterWeights" -> MapThread[
      <|"Letter" -> #1, "Weight" -> #2|> &, {letters, weights}],
    "ActiveLetterIndices" -> active,
    "Residue" -> residue
  |>
];

ComputeConnectionResidueAtLocalExpansionPoint[___] :=
  <|"Status" ->
    "ConnectionResidueAtLocalExpansionPointInputsNotWellFormed"|>;
