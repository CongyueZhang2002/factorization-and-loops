(* Local Frobenius expansions and tangential residue eigenspaces. *)
Clear[ComputeTruncatedLocalFrobeniusExpansion, TransformTangentialConnectionToNormalResidueEigenbasis];
ClearAll[boundaryExactZeroQ, boundaryCanonicalMatrix, boundaryFiniteQ, boundaryParticularSolution, boundaryLocalOrder, boundaryLeadingCoefficient, boundaryUnambiguouslyPositiveQ];
boundaryExactZeroQ[value_] :=
  AllTrue[Flatten[{Normal[value]}],
    Quiet[Check[Together[#] === 0, False]] &];

boundaryCanonicalMatrix[matrix_] :=
  Map[Together, Normal[matrix], {2}];

boundaryFiniteQ[value_] :=
  FreeQ[value, Indeterminate | ComplexInfinity | DirectedInfinity[_]];

boundaryUnambiguouslyPositiveQ[value_] :=
  TrueQ[Quiet[Check[Refine[value > 0], False]]];

boundaryParticularSolution[matrix_, target_] := Module[
  {columnCount, reduced, coefficientPart, rightHandSide, solution,
   pivot},
  columnCount = If[MatrixQ[matrix], Dimensions[matrix][[2]], 0];
  If[columnCount === 0, Return[$Failed]];
  reduced = RowReduce[Join[matrix, List /@ target, 2]];
  coefficientPart = reduced[[All, 1 ;; columnCount]];
  rightHandSide = reduced[[All, -1]];
  If[AnyTrue[Range[Length[rightHandSide]],
      boundaryExactZeroQ[coefficientPart[[#]]] &&
        ! boundaryExactZeroQ[rightHandSide[[#]]] &],
    Return[$Failed]
  ];
  solution = ConstantArray[0, columnCount];
  Do[
    pivot = SelectFirst[Range[columnCount],
      ! boundaryExactZeroQ[coefficientPart[[row, #]]] &, None];
    If[pivot =!= None, solution[[pivot]] = rightHandSide[[row]]],
    {row, Length[rightHandSide]}];
  solution
];

boundaryLocalOrder[0, _Symbol] := Infinity;
boundaryLocalOrder[expression_, variable_Symbol] := Module[
  {numerator, denominator, scale = Unique["boundaryScale$"], series,
   coefficients, minimum, denominatorPower, position, order},
  {numerator, denominator} = NumeratorDenominator[Together[expression]];
  If[PolynomialQ[numerator, variable] &&
      PolynomialQ[denominator, variable],
    Return[
      Exponent[numerator /. variable -> scale variable, scale, Min] -
        Exponent[denominator /. variable -> scale variable, scale, Min]]
  ];
  (* A square-root presentation can leave square roots in the inverse basis
     transformation even
     when every root is regular and nonzero at the chosen physical edge.
     Their exact local series still has an ordinary integer valuation.  Read
     that valuation directly instead of rejecting the mode merely because
     NumeratorDenominator is not polynomial. *)
  series = Quiet@Check[Series[expression, {variable, 0, 8}], $Failed];
  If[series === $Failed || Head[series] =!= SeriesData, Return[$Failed]];
  coefficients = series[[3]];
  minimum = series[[4]];
  denominatorPower = series[[6]];
  position = SelectFirst[Range[Length[coefficients]],
    ! boundaryExactZeroQ[coefficients[[#]]] &, Missing["ZeroSeries"]];
  If[MissingQ[position], Return[$Failed]];
  order = (minimum + position - 1)/denominatorPower;
  If[IntegerQ[order], order, $Failed]
];

boundaryLeadingCoefficient[0, _, _] := 0;
boundaryLeadingCoefficient[expression_, order_Integer,
    variable_Symbol] :=
  Together[Limit[expression/variable^order, variable -> 0]];

Options[ComputeTruncatedLocalFrobeniusExpansion] = {
  "MaximumSeriesOrder" -> 4,
  "MaximumEpsilonOrder" -> 3
};

ComputeTruncatedLocalFrobeniusExpansion[connection_?MatrixQ, spec_Association,
    OptionsPattern[]] := Catch@Module[
  {fail, matrix, dimension, variable, regulator, localVariable,
   localExpansionPoint, pointType,
   localDirection, fixedRules, maximumSeriesOrder, maximumEpsilonOrder, normalized,
   residue, regularConnection, regularCoefficients, h, zero, source,
   prefactorCoefficients, regularTruncation, prefactorTruncation,
   residual, residualCoefficients},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  matrix = Normal[connection];
  If[Length[Dimensions[matrix]] =!= 2 ||
      Dimensions[matrix][[1]] =!= Dimensions[matrix][[2]],
    fail["LocalConnectionNotSquare"]
  ];
  dimension = Length[matrix];
  variable = Lookup[spec, "Variable", Missing[]];
  regulator = Lookup[spec, "Regulator", Missing[]];
  localVariable = Lookup[spec, "LocalVariable", Global`rho];
  localExpansionPoint = Lookup[spec, "LocalExpansionPoint", Missing[]];
  localDirection = Lookup[spec, "LocalDirection", 1];
  fixedRules = Lookup[spec, "FixedRules", {}];
  maximumSeriesOrder = OptionValue["MaximumSeriesOrder"];
  maximumEpsilonOrder = OptionValue["MaximumEpsilonOrder"];
  If[! MatchQ[variable, _Symbol] || ! MatchQ[regulator, _Symbol] ||
      ! MatchQ[localVariable, _Symbol] || MissingQ[localExpansionPoint] ||
      ! FreeQ[localExpansionPoint, variable] || ! ListQ[fixedRules] ||
      ! MemberQ[{-1, 1}, localDirection] ||
      ! IntegerQ[maximumSeriesOrder] || maximumSeriesOrder < 1 ||
      ! IntegerQ[maximumEpsilonOrder] || maximumEpsilonOrder < 0 ||
      ! DuplicateFreeQ[{variable, regulator, localVariable}],
    fail["LocalFrobeniusExpansionSpecificationInvalid"]
  ];
  normalized = boundaryCanonicalMatrix[
    localDirection (matrix /. fixedRules /.
        variable -> localExpansionPoint + localDirection localVariable)/
      regulator];
  If[! FreeQ[normalized, regulator],
    fail["ConnectionNotEpsilonForm"]
  ];
  residue = boundaryCanonicalMatrix@Map[
    Quiet[Check[Limit[localVariable #, localVariable -> 0],
      Indeterminate]] &,
    normalized, {2}];
  If[! boundaryFiniteQ[residue] ||
      ! FreeQ[residue, localVariable | regulator],
    fail["ConnectionNotFuchsianAtLocalExpansionPoint"]
  ];
  regularConnection = boundaryCanonicalMatrix[
    normalized - residue/localVariable];
  If[! boundaryFiniteQ@Map[
      Quiet[Check[Limit[#, localVariable -> 0], Indeterminate]] &,
      regularConnection, {2}],
    fail["ConnectionNotFuchsianAtLocalExpansionPoint"]
  ];
  regularCoefficients = Association@Table[order ->
      boundaryCanonicalMatrix@Map[
        Quiet[Check[
          Limit[D[#, {localVariable, order}], localVariable -> 0]/
            Factorial[order], Indeterminate]] &,
        regularConnection, {2}],
    {order, 0, maximumSeriesOrder - 1}];
  If[! boundaryFiniteQ[Values[regularCoefficients]],
    fail["ConnectionNotFuchsianAtLocalExpansionPoint"]
  ];

  zero = ConstantArray[0, {dimension, dimension}];
  h[0, 0] = IdentityMatrix[dimension];
  Do[h[0, epsilonOrder] = zero,
    {epsilonOrder, 1, maximumEpsilonOrder}];
  Do[
    h[seriesOrder, 0] = zero;
    Do[
      source = Total@Table[
        regularCoefficients[regularOrder].
          h[seriesOrder - 1 - regularOrder, epsilonOrder - 1],
        {regularOrder, 0, seriesOrder - 1}];
      h[seriesOrder, epsilonOrder] = boundaryCanonicalMatrix[
        (residue.h[seriesOrder, epsilonOrder - 1] -
          h[seriesOrder, epsilonOrder - 1].residue + source)/
          seriesOrder],
      {epsilonOrder, 1, maximumEpsilonOrder}],
    {seriesOrder, 1, maximumSeriesOrder}];
  prefactorCoefficients = Association@Flatten@Table[
    {seriesOrder, epsilonOrder} -> h[seriesOrder, epsilonOrder],
    {seriesOrder, 0, maximumSeriesOrder},
    {epsilonOrder, 0, maximumEpsilonOrder}];

  (* Check precisely the coefficient rectangle promised by the finite
     truncation; coefficients beyond it require more input orders. *)
  regularTruncation = Total@KeyValueMap[
    Function[{order, coefficient},
      localVariable^order coefficient], regularCoefficients];
  prefactorTruncation = Total@KeyValueMap[
    Function[{key, coefficient},
      regulator^key[[2]] localVariable^key[[1]] coefficient],
    prefactorCoefficients];
  residual = Map[Together,
    D[prefactorTruncation, localVariable] +
      regulator prefactorTruncation.residue/localVariable -
      regulator (residue/localVariable + regularTruncation).
        prefactorTruncation,
    {2}];
  residualCoefficients = Flatten@Table[
    Map[SeriesCoefficient[#, {localVariable, 0, seriesOrder}] &,
      Map[SeriesCoefficient[#, {regulator, 0, epsilonOrder}] &,
        residual, {2}], {2}],
    {seriesOrder, -1, maximumSeriesOrder - 1},
    {epsilonOrder, 0, maximumEpsilonOrder}];
  If[! boundaryExactZeroQ[residualCoefficients],
    fail["TruncatedLocalFrobeniusRecurrenceFailed"]
  ];
  pointType = If[boundaryExactZeroQ[residue],
    "OrdinaryPoint", "RegularSingularPoint"];
  <|
    "Status" -> "TruncatedLocalFrobeniusExpansionComputed",
    "Dimension" -> dimension,
    "Variable" -> variable,
    "Regulator" -> regulator,
    "LocalVariable" -> localVariable,
    "LocalDirection" -> localDirection,
    "LocalExpansionPoint" -> localExpansionPoint,
    "PointType" -> pointType,
    "FixedRules" -> fixedRules,
    "MaximumSeriesOrder" -> maximumSeriesOrder,
    "MaximumEpsilonOrder" -> maximumEpsilonOrder,
    "EpsilonNormalizedConnectionResidue" -> residue,
    "ResidueConvention" -> "R=Res(connection/eps); LocalSolution=H(rho,eps).rho^(eps R).c",
    "RegularConnectionCoefficients" -> regularCoefficients,
    "FrobeniusPrefactorCoefficients" -> prefactorCoefficients,
    "ResidualCheckedThrough" -> <|
      "SeriesOrder" -> maximumSeriesOrder - 1,
      "EpsilonOrder" -> maximumEpsilonOrder|>
  |>
];

ComputeTruncatedLocalFrobeniusExpansion[___] :=
  <|"Status" -> "TruncatedLocalFrobeniusExpansionInputsNotWellFormed"|>;

TransformTangentialConnectionToNormalResidueEigenbasis[
    normalResidue_?MatrixQ, tangentialConnection_?MatrixQ,
    spec_Association] := Catch@Module[
  {fail, dimension, variable, regulator, eigenbasis, exponents,
   inverseEigenbasis, expectedResidue, residueInEigenbasis,
   eigenbasisDerivative, tangentialConnectionInEigenbasis,
   equalExponentGroups, unequalExponentCouplings, exponentData},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  dimension = Length[normalResidue];
  If[dimension < 1 || Dimensions[normalResidue] =!= {dimension, dimension} ||
      Dimensions[tangentialConnection] =!= {dimension, dimension},
    fail["NormalResidueAndTangentialConnectionDimensionsInvalid"]
  ];
  variable = Lookup[spec, "TangentialVariable", Missing[]];
  regulator = Lookup[spec, "Regulator", Missing[]];
  eigenbasis = Lookup[spec, "NormalResidueEigenbasis", Missing[]];
  exponents = Lookup[spec, "LocalExponents", Missing[]];
  If[! MatchQ[variable, _Symbol] || ! MatchQ[regulator, _Symbol] ||
      variable === regulator || ! MatrixQ[eigenbasis] ||
      Dimensions[eigenbasis] =!= {dimension, dimension} ||
      ! ListQ[exponents] || Length[exponents] =!= dimension ||
      ! FreeQ[exponents, variable] ||
      ! FreeQ[{normalResidue, tangentialConnection, eigenbasis, exponents}, _Real],
    fail["NormalResidueEigenbasisSpecificationInvalid"]
  ];
  inverseEigenbasis = Quiet[Check[Inverse[eigenbasis], $Failed]];
  If[inverseEigenbasis === $Failed || ! MatrixQ[inverseEigenbasis] ||
      ! boundaryFiniteQ[inverseEigenbasis],
    fail["NormalResidueEigenbasisSingular"]
  ];
  inverseEigenbasis = boundaryCanonicalMatrix[inverseEigenbasis];
  expectedResidue = DiagonalMatrix[exponents];
  residueInEigenbasis = boundaryCanonicalMatrix[
    inverseEigenbasis.normalResidue.eigenbasis];
  If[! boundaryExactZeroQ[residueInEigenbasis - expectedResidue],
    fail["NormalResidueEigenbasisInvalid", <|
      "NormalResidueInEigenbasis" -> residueInEigenbasis,
      "ExpectedResidue" -> expectedResidue|>]
  ];
  eigenbasisDerivative = Map[D[#, variable] &, eigenbasis, {2}];
  tangentialConnectionInEigenbasis = boundaryCanonicalMatrix[
    inverseEigenbasis.tangentialConnection.eigenbasis -
      inverseEigenbasis.eigenbasisDerivative];
  equalExponentGroups = Gather[Range[dimension],
    boundaryExactZeroQ[exponents[[#1]] - exponents[[#2]]] &];
  unequalExponentCouplings = Select[
    Flatten[Table[{row, column}, {row, dimension}, {column, dimension}], 1],
    ! boundaryExactZeroQ[exponents[[First[#]]] -
          exponents[[Last[#]]]] &&
      ! boundaryExactZeroQ[
        tangentialConnectionInEigenbasis[[First[#], Last[#]]]] &];
  If[unequalExponentCouplings =!= {},
    fail["UnequalExponentSectorsCoupled", <|
      "Positions" -> unequalExponentCouplings,
      "LocalExponents" -> exponents|>]
  ];
  exponentData = Map[Function[exponent, Module[{integerPart, remainder},
      integerPart = Together[exponent /. regulator -> 0];
      remainder = Together[(exponent - integerPart)/regulator];
      <|"Exponent" -> exponent, "IntegerPart" -> integerPart,
        "RegulatorCoefficient" -> remainder,
        "AffineInRegulator" -> FreeQ[remainder, regulator]|>
    ]], exponents];
  <|
    "Status" -> "TangentialConnectionTransformedToNormalResidueEigenbasis",
    "Dimension" -> dimension,
    "TangentialVariable" -> variable,
    "Regulator" -> regulator,
    "NormalResidueEigenbasis" -> eigenbasis,
    "InverseNormalResidueEigenbasis" -> inverseEigenbasis,
    "LocalExponents" -> exponents,
    "ExponentData" -> exponentData,
    "NormalResidueInEigenbasis" -> residueInEigenbasis,
    "TangentialConnectionInEigenbasis" ->
      tangentialConnectionInEigenbasis,
    "EqualExponentSectors" -> Map[Function[indices, <|
        "Indices" -> indices,
        "Exponent" -> exponents[[First[indices]]],
        "TangentialConnectionInEigenbasis" ->
          tangentialConnectionInEigenbasis[[indices, indices]]|>],
      equalExponentGroups],
    "UnequalExponentCoupling" -> False
  |>
];

TransformTangentialConnectionToNormalResidueEigenbasis[___] :=
  <|"Status" ->
    "TangentialConnectionToNormalResidueEigenbasisInputsNotWellFormed"|>;

