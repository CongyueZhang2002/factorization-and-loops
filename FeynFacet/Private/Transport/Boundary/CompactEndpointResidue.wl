(* Exact endpoint residues directly from the inert transport alphabet.
   No symbolic connection matrix is assembled. *)

Clear[BuildCompactEndpointResidue];
ClearAll[compactEndpointZeroQ, compactEndpointSparse,
  compactEndpointVanishingData];

compactEndpointZeroQ[value_] :=
  TrueQ[value === 0] || TrueQ[PossibleZeroQ[value]];

compactEndpointSparse[matrix_, dimensions_] := SparseArray[
  Cases[Most[ArrayRules[SparseArray[matrix]]],
    (position_ -> value_) :> position -> Together[value]],
  dimensions
];

compactEndpointVanishingData[polynomial_, variable_Symbol, endpoint_] := Module[
  {degree, coefficients, firstNonzero},
  If[! PolynomialQ[polynomial, variable] ||
      compactEndpointZeroQ[polynomial], Return[$Failed]];
  degree = Exponent[polynomial, variable];
  coefficients = Table[
    Together[(D[polynomial, {variable, order}] /. variable -> endpoint)/
      Factorial[order]],
    {order, 0, degree}];
  firstNonzero = SelectFirst[Range[Length[coefficients]],
    ! compactEndpointZeroQ[coefficients[[#]]] &, Missing["NotFound"]];
  If[MissingQ[firstNonzero], $Failed,
    {firstNonzero - 1, coefficients[[firstNonzero]]}]
];

Options[BuildCompactEndpointResidue] = {
  "Curve" -> None,
  "CompositeDefinitions" -> <||>
};

BuildCompactEndpointResidue[letters_List, residueMatrices_List,
    variable_Symbol, endpoint_, OptionsPattern[]] := Catch@Module[
  {fail, curve = OptionValue["Curve"],
   definitions = OptionValue["CompositeDefinitions"], dimensions,
   dimension, resolve, resolved, flatResolved, curveQ, curveAtEndpoint,
   rationalWeight, oneWeight, weights, residue, active, curveHeads},

  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[Length[letters] =!= Length[residueMatrices] || letters === {} ||
      ! AssociationQ[definitions] || ! FreeQ[endpoint, variable],
    fail["CompactEndpointResidueInputInvalid"]];
  dimensions = Dimensions /@ residueMatrices;
  If[! SameQ @@ dimensions || Length[First[dimensions]] =!= 2 ||
      ! SameQ @@ First[dimensions],
    fail["EndpointResidueMatricesNotAligned",
      <|"MatrixDimensions" -> dimensions|>]];
  dimension = First[First[dimensions]];

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
    DeleteCases[currentTerms, {value_ /; compactEndpointZeroQ[value], _}]
  ];

  resolved = resolve[#, {}] & /@ letters;
  flatResolved = If[resolved === {}, {}, Join @@ resolved];
  curveHeads = {"E4Pole", "E4Factor", "E4Omega0", "E4OmegaInf", "E4Eta2"};
  curveQ = AnyTrue[flatResolved,
    MatchQ[Last[#], {head_String /; MemberQ[curveHeads, head], ___}] &];
  If[curveQ,
    If[curve === None, fail["EndpointCurveDeclarationRequired"]];
    If[! PolynomialQ[curve, variable] || Exponent[curve, variable] =!= 4,
      fail["EndpointCurveNotQuartic"]];
    If[compactEndpointZeroQ[Together[Discriminant[curve, variable]]],
      fail["EllipticCurveDegenerate"]];
    curveAtEndpoint = Together[curve /. variable -> endpoint];
    If[compactEndpointZeroQ[curveAtEndpoint],
      fail["EllipticCurveDegeneratesAtEndpoint",
        <|"Endpoint" -> endpoint|>]],
    curveAtEndpoint = None
  ];

  rationalWeight[numerator_, denominator_, currentLabel_] := Module[
    {numeratorData, denominatorData, poleOrder},
    denominatorData = compactEndpointVanishingData[
      denominator, variable, endpoint];
    If[denominatorData === $Failed,
      fail["EndpointLetterMalformed", <|"Letter" -> currentLabel|>]];
    If[First[denominatorData] === 0, Return[0]];
    numeratorData = compactEndpointVanishingData[numerator, variable, endpoint];
    If[numeratorData === $Failed, Return[0]];
    poleOrder = First[denominatorData] - First[numeratorData];
    If[poleOrder > 1,
      fail["EndpointHigherOrderPole", <|
        "Letter" -> currentLabel, "PoleOrder" -> poleOrder|>]];
    If[poleOrder === 1,
      Together[Last[numeratorData]/Last[denominatorData]], 0]
  ];

  oneWeight[currentLabel_] := Replace[currentLabel, {
    {"GPLPole", point_} :>
      rationalWeight[1, variable - point, currentLabel],
    {"GPLFactor", polynomial_, power_Integer} :> (
      If[power < 0, fail["EndpointLetterMalformed",
        <|"Letter" -> currentLabel|>]];
      rationalWeight[variable^power, polynomial, currentLabel]),
    {"E4Pole", point_} :>
      If[compactEndpointZeroQ[Together[endpoint - point]], 1, 0],
    {"E4Factor", polynomial_, power_Integer} :> (
      If[power < 0, fail["EndpointLetterMalformed",
        <|"Letter" -> currentLabel|>]];
      Together[rationalWeight[variable^power, polynomial, currentLabel]/
        Sqrt[curveAtEndpoint]]),
    {"E4Omega0"} | {"E4OmegaInf"} | {"E4Eta2"} :>
      0,
    _ :>
      fail["EndpointLetterNotSupported", <|"Letter" -> currentLabel|>]
  }];

  weights = Map[
    Function[currentTerms,
      Together@Total[(First[#] oneWeight[Last[#]]) & /@ currentTerms]],
    resolved];
  active = Flatten@Position[weights,
    value_ /; ! compactEndpointZeroQ[value], {1}, Heads -> False];
  residue = compactEndpointSparse[
    Total@MapThread[Times, {weights, residueMatrices}],
    {dimension, dimension}];

  <|
    "Status" -> "CompactEndpointResidueBuilt",
    "Variable" -> variable,
    "Endpoint" -> endpoint,
    "Dimension" -> dimension,
    "LetterWeights" -> MapThread[
      <|"Letter" -> #1, "Weight" -> #2|> &, {letters, weights}],
    "ActiveLetterIndices" -> active,
    "Residue" -> residue
  |>
];

BuildCompactEndpointResidue[___] :=
  <|"Status" -> "CompactEndpointResidueInputInvalid"|>;
