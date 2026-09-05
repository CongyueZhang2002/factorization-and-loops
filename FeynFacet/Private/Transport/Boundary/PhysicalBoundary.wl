(* ::Package:: *)

(* Singular physical limits are not ordinary evaluation points.  This
   module supplies the local-solution and physical-boundary construction:

     epsilon-form connection -> local Frobenius prefactor and residue,
     physical-limit asymptotics -> normalized canonical Frobenius modes,
     boundary constants/functions -> boundary selectors and values.

   A PhysicalBoundaryPoint gives boundary constants.  A
   PhysicalBoundaryStratum gives functions of its declared tangential
   variables.  These are distinct record types; no generic identifier is
   emitted for both.  Genuine cycle periods may occur as values of boundary
   constants or functions, but the coefficient placeholders themselves are
   not called periods. *)

Clear[ComputeTruncatedLocalFrobeniusExpansion,
  TransformTangentialConnectionToNormalResidueEigenbasis,
  MatchBoundaryAsymptoticsToFrobeniusModes,
  ConstructBoundarySelectorMatrices,
  ConstructBoundaryValueVectorFromConstants,
  ConstructBoundaryValueVectorFromFunctions,
  BoundaryConstantEpsilonCoefficient,
  BoundaryFunctionEpsilonCoefficient, DegenerateResidueEigenspaceBasis];
ClearAll[boundaryExactZeroQ, boundaryCanonicalMatrix,
  boundaryFiniteQ, boundaryParticularSolution, boundaryLocalOrder,
  boundaryLeadingCoefficient, boundaryModeExtension,
  boundarySelectModeExtension,
  boundaryEpsilonValuation, boundaryExactCoefficientQ,
  boundaryUnambiguouslyPositiveQ, boundaryDataTypeFromDomain,
  boundaryDataIDKey, boundaryAnalyticClassKey,
  boundaryEpsilonValuationKey, boundaryTypedID,
  boundaryModeDataID, boundaryModeAnalyticClass,
  boundaryModeEpsilonValuation, boundaryModeCoefficient,
  boundaryModeCoefficientPattern, boundaryModeIdentifier,
  boundaryConstructValueVectorAndSelectorMatrices,
  boundarySelectorResult, boundaryValueResult];

boundaryDataTypeFromDomain[domain_Association] := Switch[
  Lookup[domain, "Type", Missing[]],
  "PhysicalBoundaryPoint", "BoundaryConstant",
  "PhysicalBoundaryStratum",
    If[MatchQ[Lookup[domain, "TangentialVariables", Missing[]], {__Symbol}],
      "BoundaryFunction", Missing["TangentialVariablesRequired"]],
  _, Missing["BoundaryDomainType"]
];
boundaryDataTypeFromDomain[___] := Missing["BoundaryDomain"];

boundaryDataIDKey["BoundaryConstant"] := "BoundaryConstantID";
boundaryDataIDKey["BoundaryFunction"] := "BoundaryFunctionID";
boundaryAnalyticClassKey["BoundaryConstant"] :=
  "DeclaredBoundaryConstantAnalyticClass";
boundaryAnalyticClassKey["BoundaryFunction"] :=
  "DeclaredBoundaryFunctionClass";
boundaryEpsilonValuationKey["BoundaryConstant"] :=
  "BoundaryConstantEpsilonValuation";
boundaryEpsilonValuationKey["BoundaryFunction"] :=
  "BoundaryFunctionEpsilonValuation";
boundaryTypedID[type_, id_] := <|boundaryDataIDKey[type] -> id|>;

boundaryModeDataID[mode_Association] := With[
  {type = Lookup[mode, "BoundaryDataType", Missing[]]},
  Lookup[mode, boundaryDataIDKey[type], Missing[boundaryDataIDKey[type]]]
];
boundaryModeAnalyticClass[mode_Association] := With[
  {type = Lookup[mode, "BoundaryDataType", Missing[]]},
  Lookup[mode, boundaryAnalyticClassKey[type], Missing[boundaryAnalyticClassKey[type]]]
];
boundaryModeEpsilonValuation[mode_Association] := With[
  {type = Lookup[mode, "BoundaryDataType", Missing[]]},
  Lookup[mode, boundaryEpsilonValuationKey[type], Missing[boundaryEpsilonValuationKey[type]]]
];
boundaryModeIdentifier[mode_Association] :=
  Lookup[mode, "FrobeniusModeID", Missing["FrobeniusModeID"]];

boundaryModeCoefficient["BoundaryConstant", id_, order_] :=
  BoundaryConstantEpsilonCoefficient[id, order];
boundaryModeCoefficient["BoundaryFunction", id_, order_,
    tangentialVariables_List] :=
  Apply[BoundaryFunctionEpsilonCoefficient[id, order],
    tangentialVariables];
boundaryModeCoefficient[type_, id_, order_, _List] :=
  boundaryModeCoefficient[type, id, order];
boundaryModeCoefficientPattern :=
  _BoundaryConstantEpsilonCoefficient | _BoundaryFunctionEpsilonCoefficient;

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
    "Residue" -> residue,
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

boundaryModeExtension[residue_, canonicalRows_, constraintRows_,
    eigenvalue_, maximumLevel_, suppliedSeed_] := Module[
  {dimension = Length[residue], operator, localOperator, seedBasis, seed,
   target, globalNullSpace, globalBasis, coefficients, candidate,
   found = None},
  operator = residue - eigenvalue IdentityMatrix[dimension];
  localOperator = operator[[canonicalRows, canonicalRows]];
  seed = If[suppliedSeed === Automatic,
    seedBasis = NullSpace[localOperator];
    If[Length[seedBasis] =!= 1,
      Return[<|"Status" -> "AmbiguousBlockEigenspace",
        "BlockNullity" -> Length[seedBasis]|>]
    ];
    First[seedBasis],
    suppliedSeed
  ];
  If[! VectorQ[seed] || Length[seed] =!= Length[canonicalRows] ||
      ! boundaryExactZeroQ[localOperator.seed],
    Return[<|"Status" -> "CanonicalSeedInvalid"|>]
  ];
  If[Complement[canonicalRows, constraintRows] =!= {},
    Return[<|"Status" -> "CanonicalRowsOutsideConstraints"|>]
  ];
  target = ConstantArray[0, Length[constraintRows]];
  Do[
    target[[First@FirstPosition[constraintRows, canonicalRows[[index]]]]] =
      seed[[index]],
    {index, Length[canonicalRows]}];
  Do[
    globalNullSpace = NullSpace[MatrixPower[operator, level + 1]];
    globalBasis = If[globalNullSpace === {},
      ConstantArray[0, {dimension, 0}], Transpose[globalNullSpace]];
    coefficients = boundaryParticularSolution[
      globalBasis[[constraintRows, All]], target];
    If[coefficients =!= $Failed,
      candidate = Together /@ (globalBasis.coefficients);
      If[boundaryExactZeroQ[candidate[[constraintRows]] - target],
        found = <|"Status" -> "Exact", "GeneralizedLevel" -> level,
          "Vector" -> candidate|>;
        Break[]
      ]
    ],
    {level, 0, maximumLevel}];
  If[found =!= None, found,
    <|"Status" -> "NoCompatibleGlobalMode"|>]
];

(* A repeated block eigenvalue does not by itself make a physical mode
   ambiguous.  The integer valuation of the original integral supplies the
   missing basis-independent condition: cancel every lower local power and
   retain the unique compatible direction that starts at the requested
   power.  This is the same Frobenius selection used for a one-dimensional
   eigenspace, expressed on the whole eigenspace rather than on Mathematica's
   arbitrary NullSpace basis. *)
boundarySelectModeExtension[residue_, transformationLocal_, prefactor_,
    canonicalRows_, physicalRows_, constraintRows_, eigenvalue_,
    maximumLevel_, expectedOrder_Integer, localVariable_Symbol] := Module[
  {localOperator, seeds, extensions, exactExtensions, vectors,
   selectedBasis, orders, finiteOrders, minimumOrder, lowerPowers,
   lowerConstraints, admissible, coefficients, vector, selected,
   expectedCoefficients, basisSeeds, basisExtensions},
  localOperator = (residue - eigenvalue IdentityMatrix[Length[residue]])[[
    canonicalRows, canonicalRows]];
  seeds = NullSpace[localOperator];
  If[seeds === {}, Return[<|"Status" -> "NoBlockEigenmode"|>]];
  extensions = boundaryModeExtension[residue, canonicalRows,
      constraintRows, eigenvalue, maximumLevel, #] & /@ seeds;
  exactExtensions = Select[extensions, Lookup[#, "Status", None] === "Exact" &];
  If[exactExtensions === {},
    Return[<|"Status" -> "NoCompatibleGlobalMode"|>]];
  If[Length[exactExtensions] === 1, Return[First[exactExtensions]]];

  vectors = Lookup[exactExtensions, "Vector"];
  selectedBasis = (Together /@
        (transformationLocal.prefactor.#))[[physicalRows]] & /@ vectors;
  orders = Map[boundaryLocalOrder[#, localVariable] &, selectedBasis, {2}];
  If[MemberQ[orders, $Failed, Infinity],
    Return[<|"Status" -> "PhysicalModeNotRationalAtEndpoint"|>]];
  finiteOrders = DeleteCases[Flatten[orders], Infinity];
  If[finiteOrders === {} || Min[finiteOrders] > expectedOrder,
    Return[<|"Status" -> "PhysicalValuationMismatch",
      "ComputedOrders" -> orders, "ExpectedOrder" -> expectedOrder|>]];
  minimumOrder = Min[finiteOrders];
  lowerPowers = If[minimumOrder < expectedOrder,
    Range[minimumOrder, expectedOrder - 1], {}];
  lowerConstraints = DeleteCases[
    Flatten[Table[
      Together /@ Table[
        SeriesCoefficient[selectedBasis[[basis, row]],
          {localVariable, 0, power}],
        {basis, Length[selectedBasis]}],
      {row, Length[physicalRows]}, {power, lowerPowers}], 1],
    row_ /; boundaryExactZeroQ[row]];
  admissible = If[lowerConstraints === {},
    IdentityMatrix[Length[vectors]], NullSpace[lowerConstraints]];
  (* no direction cancels every lower power: the valuation excludes the
     whole eigenspace (typed, distinct from an ambiguity) *)
  If[admissible === {},
    Return[<|"Status" -> "PhysicalValuationMismatch",
      "BlockNullity" -> Length[seeds], "PhysicalAdmissibleNullity" -> 0,
      "ComputedOrders" -> orders, "ExpectedOrder" -> expectedOrder|>]];
  (* more than one direction survives the valuation: the physical solution
     carries one coefficient per direction at this point.  Refuse typed and
     hand back the canonical (echelon) basis of the admissible eigenspace,
     each direction re-extended exactly, so that a caller with an explicit
     policy can realize the whole eigenspace instead of guessing *)
  If[Length[admissible] > 1,
    basisSeeds = Together /@ RowReduce[
      (Together /@ Total[MapThread[#1 #2 &, {#, vectors}]])[[canonicalRows]] & /@
        admissible];
    basisExtensions = boundaryModeExtension[residue, canonicalRows,
        constraintRows, eigenvalue, maximumLevel, #] & /@ basisSeeds;
    Return[<|"Status" -> "AmbiguousPhysicalEigenspace",
      "BlockNullity" -> Length[seeds],
      "PhysicalAdmissibleNullity" -> Length[admissible],
      "ExpectedOrder" -> expectedOrder,
      "AdmissibleBasis" -> If[AllTrue[basisExtensions,
          Lookup[#, "Status", None] === "Exact" &], basisExtensions, None]|>]];
  coefficients = First[admissible];
  vector = Together /@ Total[MapThread[#1 #2 &, {coefficients, vectors}]];
  selected = (Together /@ (transformationLocal.prefactor.vector))[[physicalRows]];
  expectedCoefficients = boundaryLeadingCoefficient[
      selected[[#]], expectedOrder, localVariable] & /@
    Range[Length[selected]];
  If[AllTrue[expectedCoefficients, boundaryExactZeroQ],
    Return[<|"Status" -> "PhysicalValuationMismatch",
      "ComputedOrders" -> (boundaryLocalOrder[#, localVariable] & /@ selected),
      "ExpectedOrder" -> expectedOrder|>]];
  <|"Status" -> "Exact",
    "GeneralizedLevel" -> Max[Lookup[exactExtensions, "GeneralizedLevel"]],
    "Vector" -> vector|>
];

MatchBoundaryAsymptoticsToFrobeniusModes[frobenius_Association, transformation_?MatrixQ,
    spec_Association, realizations_List] := Catch@Module[
  {fail, dimension, residue, regulator, variable, localVariable, localExpansionPoint,
   localDirection, fixedRules, relation, localPower, endpointCoefficient, family, limit,
   transformationLocal, prefactor, buildMode, modes, physicalDimension,
   boundaryDataIDs, maximumSeriesOrder, maximumEpsilonOrder,
   boundaryDataRequirements, logBranch, boundaryDomain, boundaryDataType,
   dataIDKey, analyticClassKey, epsilonValuationKey},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  If[Lookup[frobenius, "Status", None] =!=
      "TruncatedLocalFrobeniusExpansionComputed",
    fail["TruncatedLocalFrobeniusExpansionRequired"]
  ];
  dimension = frobenius["Dimension"];
  residue = frobenius["Residue"];
  regulator = frobenius["Regulator"];
  variable = frobenius["Variable"];
  localVariable = frobenius["LocalVariable"];
  localExpansionPoint = frobenius["LocalExpansionPoint"];
  localDirection = Lookup[frobenius, "LocalDirection", 1];
  maximumSeriesOrder = frobenius["MaximumSeriesOrder"];
  maximumEpsilonOrder = frobenius["MaximumEpsilonOrder"];
  fixedRules = Lookup[spec, "FixedRules", frobenius["FixedRules"]];
  relation = Lookup[spec, "PhysicalEndpointRelation", Missing[]];
  boundaryDomain = Lookup[spec, "BoundaryDomain", Missing[]];
  boundaryDataType = boundaryDataTypeFromDomain[boundaryDomain];
  family = Lookup[spec, "Family", Missing[]];
  limit = Lookup[spec, "Limit", relation];
  If[MissingQ[family] || MissingQ[limit],
    fail["BoundaryContextRequired"]
  ];
  If[MissingQ[boundaryDataType],
    fail["BoundaryDomainRequired", <|
      "RequiredForm" -> <|"Type" ->
        "PhysicalBoundaryPoint | PhysicalBoundaryStratum",
        "TangentialVariables" ->
          "required and nonempty for PhysicalBoundaryStratum"|>|>]
  ];
  dataIDKey = boundaryDataIDKey[boundaryDataType];
  analyticClassKey = boundaryAnalyticClassKey[boundaryDataType];
  epsilonValuationKey = boundaryEpsilonValuationKey[boundaryDataType];
  If[! AssociationQ[relation] ||
      ! KeyExistsQ[relation, "LocalPower"] ||
      ! KeyExistsQ[relation, "LeadingCoefficient"],
    fail["PhysicalEndpointRelationRequired"]
  ];
  localPower = relation["LocalPower"];
  endpointCoefficient = relation["LeadingCoefficient"];
  logBranch = Lookup[relation, "LogBranch", Automatic];
  If[! MatchQ[localPower, _Integer | _Rational] || localPower <= 0 ||
      boundaryExactZeroQ[endpointCoefficient] ||
      ! FreeQ[endpointCoefficient, variable | localVariable | regulator],
    fail["PhysicalEndpointRelationInvalid"]
  ];
  transformationLocal = boundaryCanonicalMatrix[
    Normal[transformation] /. fixedRules /.
      variable -> localExpansionPoint + localDirection localVariable];
  If[Dimensions[transformationLocal][[2]] =!= dimension,
    fail["EndpointTransformationDimensionMismatch"]
  ];
  physicalDimension = Dimensions[transformationLocal][[1]];
  prefactor = Total@KeyValueMap[
    Function[{key, coefficient},
      regulator^key[[2]] localVariable^key[[1]] coefficient],
    frobenius["FrobeniusPrefactorCoefficients"]];

  buildMode[realization_, given_: None] := Module[
    {boundaryDataID, declaredAnalyticClass, boundaryDataEpsilonValuation,
     frobeniusModeID, idFields, modeFailure, canonicalRows,
     physicalRows, constraintRows, demandedOutputs, exponent,
     integerValuation, maximumLevel, suppliedSeed, eigenvalue,
     extension, vector, mapped, selected, orders, expectedOrder,
     policy, basis, subID,
     candidates, requestedNormalizationRow, normalizationIndex,
     expectedLeading, actualLeading, normalization, normalizedVector,
     normalizedMapped, normalizedSelected, normalizedOrders,
     normalizedLeading, residueAction, coordinateLog,
     physicalToLocalMode},
    If[! AssociationQ[realization],
      Return[<|"Status" -> "BoundaryRealizationInvalid"|>]
    ];
    boundaryDataID = If[given === None,
      Lookup[realization, dataIDKey, Missing[]],
      given["BoundaryDataID"]];
    frobeniusModeID = If[given === None,
      Lookup[realization, "FrobeniusModeID", boundaryDataID],
      given["FrobeniusModeID"]];
    declaredAnalyticClass = Lookup[realization, analyticClassKey, Missing[]];
    boundaryDataEpsilonValuation = Lookup[realization,
      epsilonValuationKey, Missing[]];
    idFields = Join[boundaryTypedID[boundaryDataType, boundaryDataID],
      <|"FrobeniusModeID" -> frobeniusModeID|>,
      If[KeyExistsQ[realization, "BoundaryIntegralID"],
        <|"BoundaryIntegralID" -> realization["BoundaryIntegralID"]|>,
        <||>]];
    modeFailure[status_, extra_: <||>] :=
      Join[<|"Status" -> status|>, idFields, extra];
    canonicalRows = Lookup[realization, "CanonicalRows", Missing[]];
    physicalRows = Lookup[realization, "PhysicalRows", Missing[]];
    demandedOutputs = Lookup[realization, "DemandedOutputs", {}];
    exponent = Lookup[realization, "EpsilonExponent", Missing[]];
    integerValuation = Lookup[realization, "IntegerValuation", Missing[]];
    maximumLevel = Lookup[realization, "LogLevel", 0];
    suppliedSeed = Lookup[realization, "CanonicalSeed", Automatic];
    If[MissingQ[boundaryDataID] || MissingQ[frobeniusModeID] ||
        ! MemberQ[{"GPL", "Elliptic"}, declaredAnalyticClass] ||
        ! IntegerQ[boundaryDataEpsilonValuation] || ! ListQ[demandedOutputs] ||
        ! AllTrue[demandedOutputs, MatchQ[#, {_Integer, _Integer}] &],
      Return[modeFailure["BoundaryDataDescriptionInvalid"]]
    ];
    If[! MatchQ[canonicalRows, {__Integer}] ||
        ! DuplicateFreeQ[canonicalRows] ||
        ! AllTrue[canonicalRows, 1 <= # <= dimension &] ||
        ! MatchQ[physicalRows, {__Integer}] ||
        ! DuplicateFreeQ[physicalRows] ||
        ! AllTrue[physicalRows, 1 <= # <= physicalDimension &],
      Return[modeFailure["BoundaryModeRowsInvalid"]]
    ];
    constraintRows = Lookup[realization, "ConstraintRows",
      Range[Max[canonicalRows]]];
    If[! MatchQ[constraintRows, {__Integer}] ||
        ! DuplicateFreeQ[constraintRows] ||
        ! AllTrue[constraintRows, 1 <= # <= dimension &],
      Return[modeFailure["BoundaryModeConstraintsInvalid"]]
    ];
    If[! MatchQ[exponent, _Integer | _Rational] ||
        ! IntegerQ[integerValuation] ||
        ! IntegerQ[maximumLevel] || maximumLevel < 0,
      Return[modeFailure["BoundaryModePowersInvalid"]]
    ];
    (* Round 9b (T, R3's F4): the policy is validated up front; a typo can
       no longer silently disable the split *)
    policy = Lookup[realization, "DegenerateResidueEigenspacePolicy", "Refuse"];
    If[! MemberQ[{"Refuse", "Basis"}, policy],
      Return[modeFailure["DegenerateResidueEigenspacePolicyInvalid", <|
        "Policy" -> policy,
        "AllowedPolicies" -> {"Refuse", "Basis"}|>]]
    ];
    expectedOrder = localPower integerValuation;
    If[! IntegerQ[expectedOrder],
      Return[modeFailure["PhysicalValuationNotIntegral"]]
    ];
    If[expectedOrder > maximumSeriesOrder,
      Return[modeFailure["FrobeniusDepthInsufficient", <|
        "NeededSeriesOrder" -> expectedOrder,
        "AvailableSeriesOrder" -> maximumSeriesOrder|>]]
    ];
    eigenvalue = Together[localPower exponent];
    extension = Which[
      given =!= None, given["Extension"],
      suppliedSeed === Automatic,
      boundarySelectModeExtension[residue, transformationLocal, prefactor,
        canonicalRows, physicalRows, constraintRows, eigenvalue,
        maximumLevel, expectedOrder, localVariable],
      True,
      boundaryModeExtension[residue, canonicalRows,
        constraintRows, eigenvalue, maximumLevel, suppliedSeed]];
    (* A genuinely multi-dimensional admissible eigenspace is refused typed
       by default.  Under the realization's explicit policy "Basis" every
       direction of the canonical admissible basis becomes its own exact
       sub-realization.  The resulting coefficients remain independent unless
       an explicit BoundaryRelation is supplied; eigenspace degeneracy alone
       does not imply a relation.  Nothing selects a direction silently. *)
    If[extension["Status"] === "AmbiguousPhysicalEigenspace" &&
        policy === "Basis" &&
        ListQ[Lookup[extension, "AdmissibleBasis", None]],
      basis = extension["AdmissibleBasis"];
      subID[k_] := If[ListQ[boundaryDataID], Append[boundaryDataID, k],
        {boundaryDataID, k}];
      Return[Table[buildMode[realization, <|"Extension" -> basis[[k]],
          "BoundaryDataID" -> subID[k], "FrobeniusModeID" -> subID[k],
          "Direction" -> k, "Dimension" -> Length[basis],
          "ParentBoundaryDataID" -> boundaryDataID,
          "EigenspaceBasis" -> Map[Together /@ #["Vector"][[canonicalRows]] &,
            basis]|>],
        {k, Length[basis]}]]
    ];
    If[extension["Status"] =!= "Exact",
      Return[Join[idFields, <|analyticClassKey -> declaredAnalyticClass|>,
        extension]]
    ];
    vector = extension["Vector"];
    mapped = Together /@ (transformationLocal.prefactor.vector);
    selected = mapped[[physicalRows]];
    orders = boundaryLocalOrder[#, localVariable] & /@ selected;
    If[MemberQ[orders, $Failed],
      Return[modeFailure["PhysicalModeNotRationalAtLocalExpansionPoint"]]
    ];
    candidates = Flatten@Position[orders, expectedOrder];
    If[candidates === {},
      Return[modeFailure["PhysicalValuationMismatch", <|
        "ComputedOrders" -> orders, "ExpectedOrder" -> expectedOrder|>]]
    ];
    requestedNormalizationRow = Lookup[realization,
      "NormalizationPhysicalRow", Automatic];
    normalizationIndex = If[requestedNormalizationRow === Automatic,
      First[candidates],
      SelectFirst[candidates,
        physicalRows[[#]] === requestedNormalizationRow &, None]
    ];
    If[normalizationIndex === None,
      Return[modeFailure["NormalizationRowInvalid"]]
    ];
    expectedLeading = Together[endpointCoefficient^integerValuation];
    actualLeading = boundaryLeadingCoefficient[
      selected[[normalizationIndex]], expectedOrder, localVariable];
    If[boundaryExactZeroQ[actualLeading] ||
        ! boundaryFiniteQ[actualLeading],
      Return[modeFailure["ModeNormalizationFailed"]]
    ];
    normalization = Together[expectedLeading/actualLeading];
    normalizedVector = Together /@ (normalization vector);
    normalizedMapped = Together /@
      (transformationLocal.prefactor.normalizedVector);
    normalizedSelected = normalizedMapped[[physicalRows]];
    normalizedOrders = boundaryLocalOrder[#, localVariable] & /@
      normalizedSelected;
    normalizedLeading = MapThread[boundaryLeadingCoefficient,
      {normalizedSelected, normalizedOrders,
       ConstantArray[localVariable, Length[normalizedSelected]]}];
    If[! boundaryExactZeroQ[
        MatrixPower[residue - eigenvalue IdentityMatrix[dimension],
          extension["GeneralizedLevel"] + 1].normalizedVector] ||
        ! MemberQ[normalizedOrders, expectedOrder] ||
        ! AnyTrue[normalizedLeading,
          boundaryExactZeroQ[# - expectedLeading] &],
      Return[modeFailure["BoundaryModeValidationFailed"]]
    ];
    (* If t = alpha rho^kappa, then the physical and local Frobenius
       constants differ by exp(eps Log[alpha] R_rho/kappa).  Keep the
       exponential only to the same epsilon depth as the local prefactor.
       An ordinary zero-residue mode is invariant and needs no branch. *)
    residueAction = Together /@ (residue.normalizedVector);
    physicalToLocalMode = If[boundaryExactZeroQ[residueAction],
      normalizedVector,
      If[logBranch === Automatic,
        If[! boundaryUnambiguouslyPositiveQ[endpointCoefficient],
          Return[modeFailure["PhysicalLimitLogBranchRequired"]]
        ];
        coordinateLog = Log[endpointCoefficient],
        If[! IntegerQ[logBranch],
          Return[modeFailure["PhysicalLimitLogBranchInvalid"]]
        ];
        coordinateLog = Log[endpointCoefficient] + 2 Pi I logBranch
      ];
      Together /@ (normalizedVector + Sum[
        (regulator coordinateLog/localPower)^order/Factorial[order]
          MatrixPower[residue, order].normalizedVector,
        {order, 1, maximumEpsilonOrder}])
    ];
    With[{record = Join[<|
      "Status" -> "BoundaryAsymptoticsMatchedToFrobeniusMode",
      "BoundaryDataType" -> boundaryDataType,
      analyticClassKey -> declaredAnalyticClass,
      epsilonValuationKey -> boundaryDataEpsilonValuation,
      "CanonicalRows" -> canonicalRows,
      "ConstraintRows" -> constraintRows,
      "PhysicalRows" -> physicalRows,
      "DemandedOutputs" -> demandedOutputs,
      "LocalEigenvalue" -> eigenvalue,
      "GeneralizedLevel" -> extension["GeneralizedLevel"],
      "IntegerValuation" -> integerValuation,
      "NormalizationPhysicalRow" ->
        physicalRows[[normalizationIndex]],
      "CanonicalMode" -> normalizedVector,
      "PhysicalToLocalMode" -> physicalToLocalMode,
      "PhysicalLocalOrders" -> normalizedOrders,
      "PhysicalLeadingCoefficients" -> normalizedLeading
    |>, idFields]},
      If[given === None, record,
        Join[record, <|
          If[boundaryDataType === "BoundaryConstant",
            "ParentBoundaryConstantID", "ParentBoundaryFunctionID"] ->
              given["ParentBoundaryDataID"],
          "EigenspaceDirection" -> given["Direction"],
          "EigenspaceDimension" -> given["Dimension"],
          "EigenspaceBasis" -> given["EigenspaceBasis"]|>]]]
  ];

  modes = Flatten[buildMode /@ realizations];
  boundaryDataIDs = DeleteCases[boundaryModeDataID /@ modes, _Missing];
  If[! DuplicateFreeQ[boundaryDataIDs],
    fail[If[boundaryDataType === "BoundaryConstant",
        "DuplicateBoundaryConstantID", "DuplicateBoundaryFunctionID"],
      <|If[boundaryDataType === "BoundaryConstant",
          "BoundaryConstantIDs", "BoundaryFunctionIDs"] -> boundaryDataIDs|>]
  ];
  boundaryDataRequirements = Map[Function[mode, Join[<|
      "BoundaryDataType" -> boundaryDataType,
      "FrobeniusModeID" -> boundaryModeIdentifier[mode],
      analyticClassKey -> boundaryModeAnalyticClass[mode],
      "Family" -> family,
      "PhysicalKinematicLimit" -> limit,
      "BoundaryDomain" -> boundaryDomain,
      "FrobeniusMode" -> KeyTake[mode,
        {"CanonicalRows", "LocalEigenvalue", "GeneralizedLevel"}],
      If[boundaryDataType === "BoundaryConstant",
        "AffectedBoundaryConstantEpsilonCoefficientLabels",
        "AffectedBoundaryFunctionEpsilonCoefficientLabels"] -> {},
      "RequiredMasterIntegralCoefficients" -> Lookup[mode, "DemandedOutputs", {}],
      "Status" -> "Unevaluated",
      "DegenerateResidueEigenspaceBasis" ->
        DegenerateResidueEigenspaceBasis[mode, modes],
      "Problem" -> If[Lookup[mode, "Status", None] ===
        "BoundaryAsymptoticsMatchedToFrobeniusMode",
          If[boundaryDataType === "BoundaryConstant",
            "BoundaryConstantRequired", "BoundaryFunctionRequired"],
        Lookup[mode, "Status", "BoundaryModeIncomplete"]]|>,
      boundaryTypedID[boundaryDataType, boundaryModeDataID[mode]]]], modes];
  <|
    "DataType" -> "BoundaryAsymptoticModeMatching",
    "SchemaVersion" -> 2,
    "Status" -> If[AllTrue[modes,
      Lookup[#, "Status", None] ===
        "BoundaryAsymptoticsMatchedToFrobeniusMode" &],
      "BoundaryAsymptoticsMatchedToFrobeniusModes",
      "BoundaryAsymptoticsNotFullyMatchedToFrobeniusModes"],
    "Family" -> family,
    "PhysicalKinematicLimit" -> limit,
    "BoundaryDomain" -> boundaryDomain,
    "BoundaryDataType" -> boundaryDataType,
    "Dimension" -> dimension,
    "PhysicalDimension" -> physicalDimension,
    "Regulator" -> regulator,
    "MaximumSeriesOrder" -> maximumSeriesOrder,
    "MaximumEpsilonOrder" -> maximumEpsilonOrder,
    "LocalVariable" -> localVariable,
    "LocalExpansionPoint" -> localExpansionPoint,
    "LocalExpansionSpecification" -> <|"Variable" -> variable,
      "LocalExpansionPoint" -> localExpansionPoint,
      "LocalDirection" -> localDirection,
      "FixedRules" -> fixedRules|>,
    "PhysicalEndpointRelation" -> relation,
    "FrobeniusModes" -> modes,
    "DegenerateResidueEigenspaceBases" -> DeleteDuplicates[
      DeleteCases[DegenerateResidueEigenspaceBasis[#, modes] & /@ modes,
        None | _Missing]],
    "BoundaryDataRequirements" -> boundaryDataRequirements
  |>
];

MatchBoundaryAsymptoticsToFrobeniusModes[___] :=
  <|"Status" -> "BoundaryAsymptoticsToFrobeniusModesInputsInvalid"|>;

(* A basis for a degenerate admissible residue eigenspace.  It records the
   independent directions only.  No relation among their boundary constants
   or functions is inferred from degeneracy. *)
DegenerateResidueEigenspaceBasis[mode_Association, modes_List] := Module[
  {type = Lookup[mode, "BoundaryDataType", Missing[]], parentKey,
   parentID, siblings},
  parentKey = Switch[type,
    "BoundaryConstant", "ParentBoundaryConstantID",
    "BoundaryFunction", "ParentBoundaryFunctionID",
    _, Return[None]];
  If[! KeyExistsQ[mode, parentKey], Return[None]];
  parentID = mode[parentKey];
  siblings = Select[modes,
    Lookup[#, parentKey, None] === parentID &];
  Join[<|
    "BoundaryDataType" -> type,
    parentKey -> parentID,
    "EigenspaceDimension" -> mode["EigenspaceDimension"],
    "CanonicalRows" -> Lookup[mode, "CanonicalRows", Missing[]],
    "FrobeniusModeIDs" -> (boundaryModeIdentifier /@ siblings),
    "EigenspaceBasis" -> Lookup[mode, "EigenspaceBasis",
      Table[Lookup[sibling, "CanonicalMode"][[
        Lookup[sibling, "CanonicalRows"]]], {sibling, siblings}]],
    "IndependentBoundaryDataCount" -> Length[siblings],
    "BoundaryRelations" -> {},
    "Meaning" -> "the displayed vectors form independent admissible directions of a degenerate residue eigenspace; no relation among their boundary coefficients is implied"|>,
    boundaryTypedID[type, boundaryModeDataID[mode]],
    <|"EigenspaceDirection" -> mode["EigenspaceDirection"]|>]
];
DegenerateResidueEigenspaceBasis[___] := None;

boundaryEpsilonValuation[vector_List, regulator_Symbol] := Module[
  {orders = DeleteCases[
     boundaryLocalOrder[#, regulator] & /@ vector, Infinity]},
  If[orders === {} || MemberQ[orders, $Failed], $Failed, Min[orders]]
];

boundaryExactCoefficientQ[value_, regulator_Symbol] :=
  FreeQ[value, regulator | _Real | _Missing | Indeterminate |
    ComplexInfinity | DirectedInfinity[_]];

Options[boundaryConstructValueVectorAndSelectorMatrices] = {
  "MissingBoundaryDataAction" -> "Refuse"
};

boundaryConstructValueVectorAndSelectorMatrices[modeMap_Association, boundaryData_,
    window : {_Integer, _Integer}, OptionsPattern[]] := Catch@Module[
  {fail, low = window[[1]], high = window[[2]], action, formalActionQ,
   modes, regulator, dimension, records, normalizedRecords, recordIDs,
   missingGPL = {}, missingElliptic = {}, invalid = {}, depthProblems = {},
   windowProblems = {}, tangentialProblems = {}, coordinates = {},
   modeValues = {}, boundaryDataRequirements = {},
   appendRequirement, markMissing, resolveCoefficients, addCoordinates,
   modeValuation, expectedValuation, activeDemand, targetHigh,
   requiredHigh, requiredOrders, potentialCoordinates, actualCoordinates,
   record, recordStatus, coefficientData, missingOrders, resolved,
   activeClasses = {}, selectorForOrder, selectors, constants,
   boundaryVectors, functionSpace, dataStatus, incompleteStatus,
   boundaryDataType, dataIDKey, analyticClassKey, coefficientLabelsKey,
   coefficientRecordsKey, valueVectorKey, family, physicalLimit,
   modeID, modeClass, normalizedRecord, tangentialVariables},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  action = OptionValue["MissingBoundaryDataAction"];
  formalActionQ = action === "Formal";
  If[low > high || ! MemberQ[{"Refuse", "Formal"}, action],
    fail["BoundaryEpsilonWindowInvalid"]
  ];
  If[Lookup[modeMap, "DataType", None] =!=
        "BoundaryAsymptoticModeMatching" ||
      Lookup[modeMap, "SchemaVersion", None] =!= 2 ||
      Lookup[modeMap, "Status", None] =!=
        "BoundaryAsymptoticsMatchedToFrobeniusModes",
    fail["CompleteBoundaryAsymptoticModeMatchingRequired",
      <|"BoundaryDataRequirements" ->
        Lookup[modeMap, "BoundaryDataRequirements", {}]|>]
  ];
  boundaryDataType = Lookup[modeMap, "BoundaryDataType", Missing[]];
  If[! MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType],
    fail["BoundaryDataTypeRequired"]];
  dataIDKey = boundaryDataIDKey[boundaryDataType];
  analyticClassKey = boundaryAnalyticClassKey[boundaryDataType];
  coefficientLabelsKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientLabels",
    "BoundaryFunctionEpsilonCoefficientLabels"];
  coefficientRecordsKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientRecords",
    "BoundaryFunctionEpsilonCoefficientRecords"];
  valueVectorKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantVector", "BoundaryFunctionVector"];
  family = modeMap["Family"];
  physicalLimit = modeMap["PhysicalKinematicLimit"];
  tangentialVariables = Lookup[modeMap["BoundaryDomain"],
    "TangentialVariables", {}];
  modes = modeMap["FrobeniusModes"];
  regulator = modeMap["Regulator"];
  dimension = modeMap["Dimension"];
  records = Which[
    AssociationQ[boundaryData], boundaryData,
    ListQ[boundaryData] && AllTrue[boundaryData, AssociationQ] &&
        AllTrue[boundaryData, KeyExistsQ[#, dataIDKey] &],
      recordIDs = Lookup[boundaryData, dataIDKey];
      If[! DuplicateFreeQ[recordIDs],
        fail["BoundaryDataInvalid",
          <|"Reason" -> If[boundaryDataType === "BoundaryConstant",
            "DuplicateBoundaryConstantID", "DuplicateBoundaryFunctionID"]|>]
      ];
      Association@Table[
        item[dataIDKey] -> item,
        {item, boundaryData}],
    True, fail["BoundaryDataInvalid"]
  ];
  normalizedRecords = Association@KeyValueMap[
    Function[{id, item},
      normalizedRecord = If[AssociationQ[item], item, <||>];
      id -> Join[
        <|dataIDKey -> Lookup[normalizedRecord, dataIDKey, id],
          analyticClassKey -> Lookup[normalizedRecord, analyticClassKey,
            Missing[]]|>,
        KeyDrop[normalizedRecord,
          {dataIDKey, analyticClassKey}]]],
    records];
  appendRequirement[mode_, demand_, status_, affected_, data_: <||>] :=
    AppendTo[boundaryDataRequirements, Join[<|
      "BoundaryDataType" -> boundaryDataType,
      "FrobeniusModeID" -> boundaryModeIdentifier[mode],
      analyticClassKey -> boundaryModeAnalyticClass[mode],
      "Family" -> family,
      "PhysicalKinematicLimit" -> physicalLimit,
      "BoundaryDomain" -> modeMap["BoundaryDomain"],
      "FrobeniusMode" -> <|
        "CanonicalRows" -> mode["CanonicalRows"],
        "LocalEigenvalue" -> mode["LocalEigenvalue"],
        "GeneralizedLevel" -> mode["GeneralizedLevel"]|>,
      coefficientLabelsKey -> affected,
      "RequiredMasterIntegralCoefficients" -> demand,
      "DegenerateResidueEigenspaceBasis" ->
        DegenerateResidueEigenspaceBasis[mode, modes],
      "Status" -> status|>, boundaryTypedID[boundaryDataType,
        boundaryModeDataID[mode]], data]];
  markMissing[mode_, orders_] :=
    If[boundaryModeAnalyticClass[mode] === "GPL",
      AppendTo[missingGPL,
        Join[boundaryTypedID[boundaryDataType, boundaryModeDataID[mode]],
          <|"EpsilonOrders" -> orders|>]],
      AppendTo[missingElliptic,
        Join[boundaryTypedID[boundaryDataType, boundaryModeDataID[mode]],
          <|"EpsilonOrders" -> orders|>]]];
  resolveCoefficients[mode_, data_Association, orders_List] :=
    Association@Table[order -> If[KeyExistsQ[data, order], data[order],
      boundaryModeCoefficient[boundaryDataType, boundaryModeDataID[mode],
        order, tangentialVariables]],
      {order, orders}];
  addCoordinates[mode_, data_Association, orders_List] := Module[
    {affected = {}, value},
    Do[
      value = data[order];
      If[! boundaryExactZeroQ[value],
        AppendTo[coordinates, <|
          "BoundaryDataType" -> boundaryDataType,
          dataIDKey -> boundaryModeDataID[mode],
          "FrobeniusModeID" -> boundaryModeIdentifier[mode],
          analyticClassKey -> boundaryModeAnalyticClass[mode],
          "EpsilonOrder" -> order,
          "DegenerateResidueEigenspaceBasis" ->
            DegenerateResidueEigenspaceBasis[mode, modes],
          "Value" -> value|>];
        AppendTo[modeValues, <|"Mode" -> mode["CanonicalMode"],
          "EpsilonOrder" -> order|>];
        AppendTo[affected, {boundaryModeDataID[mode], order}]
      ],
      {order, orders}];
    If[affected =!= {}, AppendTo[activeClasses, boundaryModeAnalyticClass[mode]]];
    affected
  ];

  Do[
    modeID = boundaryModeDataID[mode];
    modeClass = boundaryModeAnalyticClass[mode];
    (* A mode absent from the already-pruned demand can require no boundary
       coefficient and therefore gets no needs-ledger row. *)
    activeDemand = DeleteDuplicates@Select[mode["DemandedOutputs"],
      MatchQ[#, {_Integer, _Integer}] &&
        low <= First[#] <= high &];
    If[activeDemand === {}, Continue[]];
    modeValuation = boundaryEpsilonValuation[
      mode["CanonicalMode"], regulator];
    expectedValuation = boundaryModeEpsilonValuation[mode];
    If[modeValuation === $Failed || ! IntegerQ[modeValuation],
      AppendTo[invalid, Join[boundaryTypedID[boundaryDataType, modeID],
        <|"Reason" -> "CanonicalModeNotRationalInRegulator"|>]];
      appendRequirement[mode, activeDemand, "Unevaluated", {},
        <|"Problem" -> "CanonicalModeNotRationalInRegulator"|>];
      Continue[]
    ];
    targetHigh = Max[activeDemand[[All, 1]]];
    requiredHigh = targetHigh - modeValuation;
    requiredOrders = If[expectedValuation <= requiredHigh,
      Range[expectedValuation, requiredHigh], {}];
    potentialCoordinates = {modeID, #} & /@ requiredOrders;
    If[requiredOrders === {}, Continue[]];
    (* The local solution is H(rho,eps) rho^(eps R)c.  A rational boundary
       selector represents it without extra tangential data only for an
       ordinary zero-residue mode.  Nonzero eigenvalues carry
       exp(eps lambda log rho), and generalized modes carry additional log
       powers; silently dropping either factor changes the solution. *)
    If[Lookup[mode, "GeneralizedLevel", Missing[]] =!= 0 ||
        ! boundaryExactZeroQ[
          Lookup[mode, "LocalEigenvalue", Missing[]]],
      AppendTo[tangentialProblems, Join[
        boundaryTypedID[boundaryDataType, modeID], <|
        "LocalEigenvalue" -> Lookup[mode, "LocalEigenvalue", Missing[]],
        "GeneralizedLevel" ->
          Lookup[mode, "GeneralizedLevel", Missing[]]|>]];
      appendRequirement[mode, activeDemand, "Unevaluated",
        potentialCoordinates, <|
          "Problem" -> "TangentialLogModeRequired",
          "LocalEigenvalue" ->
            Lookup[mode, "LocalEigenvalue", Missing[]],
          "GeneralizedLevel" ->
            Lookup[mode, "GeneralizedLevel", Missing[]]|>];
      Continue[]
    ];
    If[expectedValuation + modeValuation < low,
      AppendTo[windowProblems, Join[boundaryTypedID[boundaryDataType, modeID], <|
        "NeededMinimumOrder" -> expectedValuation + modeValuation,
        "AvailableMinimumOrder" -> low|>]];
      appendRequirement[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "BoundaryEpsilonWindowTooNarrow"|>];
      Continue[]
    ];
    If[targetHigh - expectedValuation >
        modeMap["MaximumEpsilonOrder"],
      AppendTo[depthProblems, Join[boundaryTypedID[boundaryDataType, modeID], <|
        "NeededEpsilonOrder" -> targetHigh - expectedValuation,
        "AvailableEpsilonOrder" -> modeMap["MaximumEpsilonOrder"]|>]];
      appendRequirement[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "FrobeniusDepthInsufficient"|>];
      Continue[]
    ];
    record = Lookup[normalizedRecords, modeID, Missing[]];
    If[MissingQ[record] || ! AssociationQ[record],
      If[formalActionQ,
        resolved = resolveCoefficients[mode, <||>, requiredOrders];
        actualCoordinates = addCoordinates[mode, resolved, requiredOrders],
        markMissing[mode, requiredOrders];
        actualCoordinates = potentialCoordinates];
      appendRequirement[mode, activeDemand, "Unevaluated",
        actualCoordinates];
      Continue[]
    ];
    If[Lookup[record, dataIDKey, modeID] =!= modeID,
      AppendTo[invalid, Join[boundaryTypedID[boundaryDataType, modeID],
        <|"Reason" -> If[boundaryDataType === "BoundaryConstant",
          "BoundaryConstantIDMismatch", "BoundaryFunctionIDMismatch"]|>]];
      appendRequirement[mode, activeDemand, "Unevaluated",
        potentialCoordinates, <|"Problem" -> If[boundaryDataType === "BoundaryConstant",
          "BoundaryConstantIDMismatch", "BoundaryFunctionIDMismatch"]|>];
      Continue[]
    ];
    If[Lookup[record, analyticClassKey, None] =!= modeClass,
      AppendTo[invalid, Join[boundaryTypedID[boundaryDataType, modeID],
        <|"Reason" -> "DeclaredBoundaryAnalyticClassMismatch"|>]];
      appendRequirement[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "DeclaredBoundaryAnalyticClassMismatch"|>];
      Continue[]
    ];
    recordStatus = Lookup[record, "Status", None];
    If[recordStatus === "ExactZero",
      appendRequirement[mode, activeDemand, "KnownZero", {},
        KeyTake[record, {"BoundaryIntegralID"}]];
      Continue[]
    ];
    If[recordStatus === "Transferable",
      coefficientData = Lookup[record, "TransferMap", <||>];
      If[! AssociationQ[coefficientData] ||
          ! AllTrue[Lookup[coefficientData,
              Intersection[Keys[coefficientData], requiredOrders]],
            boundaryExactCoefficientQ[#, regulator] &],
        AppendTo[invalid, Join[boundaryTypedID[boundaryDataType, modeID],
          <|"Reason" -> "TransferMapInvalid"|>]];
        appendRequirement[mode, activeDemand, "Transferable",
          potentialCoordinates, <|"Problem" -> "TransferMapInvalid"|>];
        Continue[]
      ];
      missingOrders = Complement[requiredOrders, Keys[coefficientData]];
      If[missingOrders =!= {} && ! formalActionQ,
        markMissing[mode, missingOrders];
        appendRequirement[mode, activeDemand, "Transferable",
          potentialCoordinates,
          Join[KeyTake[record, {"TransferFrom"}],
            <|"MissingOrders" -> missingOrders|>]];
        Continue[]
      ];
      resolved = resolveCoefficients[mode, coefficientData,
        requiredOrders];
      actualCoordinates = addCoordinates[mode, resolved, requiredOrders];
      appendRequirement[mode, activeDemand, "Transferable",
        actualCoordinates,
        Join[KeyTake[record, {"TransferFrom"}],
          If[missingOrders === {}, <||>,
            <|"MissingOrders" -> missingOrders|>]]];
      Continue[]
    ];
    If[recordStatus =!= "Exact",
      If[formalActionQ,
        resolved = resolveCoefficients[mode, <||>, requiredOrders];
        actualCoordinates = addCoordinates[mode, resolved, requiredOrders],
        markMissing[mode, requiredOrders];
        actualCoordinates = potentialCoordinates];
      appendRequirement[mode, activeDemand, "Unevaluated",
        actualCoordinates];
      Continue[]
    ];
    If[Lookup[record, "Valuation", Missing[]] =!=
        expectedValuation ||
        ! AssociationQ[Lookup[record, "Coefficients", Missing[]]],
      AppendTo[invalid, Join[boundaryTypedID[boundaryDataType, modeID], <|
        "Reason" -> "BoundaryEpsilonSeriesInvalid",
        "ExpectedValuation" -> expectedValuation,
        "ActualValuation" -> Lookup[record, "Valuation", Missing[]]|>]];
      appendRequirement[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "BoundaryEpsilonSeriesInvalid"|>];
      Continue[]
    ];
    coefficientData = record["Coefficients"];
    If[! AllTrue[Lookup[coefficientData,
          Intersection[Keys[coefficientData], requiredOrders]],
        boundaryExactCoefficientQ[#, regulator] &&
          FreeQ[#, boundaryModeCoefficientPattern] &] ||
        (MemberQ[requiredOrders, expectedValuation] &&
          KeyExistsQ[coefficientData, expectedValuation] &&
          boundaryExactZeroQ[coefficientData[expectedValuation]]),
      AppendTo[invalid, Join[boundaryTypedID[boundaryDataType, modeID],
        <|"Reason" -> "BoundaryCoefficientsNotExact"|>]];
      appendRequirement[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "BoundaryCoefficientsNotExact"|>];
      Continue[]
    ];
    missingOrders = Complement[requiredOrders, Keys[coefficientData]];
    If[missingOrders =!= {} && ! formalActionQ,
      markMissing[mode, missingOrders];
      appendRequirement[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"MissingOrders" -> missingOrders|>];
      Continue[]
    ];
    resolved = resolveCoefficients[mode, coefficientData,
      requiredOrders];
    actualCoordinates = addCoordinates[mode, resolved, requiredOrders];
    appendRequirement[mode, activeDemand,
      If[missingOrders === {}, "KnownExact", "Unevaluated"],
      actualCoordinates,
      If[missingOrders === {}, <||>,
        <|"MissingOrders" -> missingOrders|>]],
    {mode, modes}];
  If[tangentialProblems =!= {},
    Return[<|"Status" -> "TangentialLogModeRequired",
      "Family" -> family, "PhysicalKinematicLimit" -> physicalLimit,
      "BoundaryDataType" -> boundaryDataType,
      "RequestedWindow" -> window, "Problems" -> tangentialProblems,
      "BoundaryDataRequirements" -> boundaryDataRequirements|>, Module]
  ];
  If[windowProblems =!= {},
    Return[<|"Status" -> "BoundaryEpsilonWindowTooNarrow",
      "Family" -> family, "PhysicalKinematicLimit" -> physicalLimit,
      "BoundaryDataType" -> boundaryDataType,
      "RequestedWindow" -> window, "Problems" -> windowProblems,
      "BoundaryDataRequirements" -> boundaryDataRequirements|>, Module]
  ];
  If[depthProblems =!= {},
    Return[<|"Status" -> "FrobeniusDepthInsufficient",
      "Family" -> family, "PhysicalKinematicLimit" -> physicalLimit,
      "BoundaryDataType" -> boundaryDataType,
      "RequestedWindow" -> window, "Problems" -> depthProblems,
      "BoundaryDataRequirements" -> boundaryDataRequirements|>, Module]
  ];
  If[invalid =!= {},
    Return[<|"Status" -> "BoundaryDataInvalid",
      "Family" -> family, "PhysicalKinematicLimit" -> physicalLimit,
      "BoundaryDataType" -> boundaryDataType,
      "RequestedWindow" -> window, "Problems" -> invalid,
      "BoundaryDataRequirements" -> boundaryDataRequirements|>, Module]
  ];
  If[missingGPL =!= {} || missingElliptic =!= {},
    incompleteStatus = Which[
      missingGPL =!= {} && missingElliptic =!= {},
        "BoundaryDataIncomplete",
      missingGPL =!= {}, If[boundaryDataType === "BoundaryConstant",
        "GPLBoundaryConstantsIncomplete", "GPLBoundaryFunctionsIncomplete"],
      True, If[boundaryDataType === "BoundaryConstant",
        "EllipticBoundaryConstantsIncomplete", "EllipticBoundaryFunctionsIncomplete"]];
    Return[<|"Status" -> incompleteStatus,
      "Family" -> family, "PhysicalKinematicLimit" -> physicalLimit,
      "BoundaryDataType" -> boundaryDataType,
      If[boundaryDataType === "BoundaryConstant",
        "MissingGPLBoundaryConstants", "MissingGPLBoundaryFunctions"] -> missingGPL,
      If[boundaryDataType === "BoundaryConstant",
        "MissingEllipticBoundaryConstants", "MissingEllipticBoundaryFunctions"] -> missingElliptic,
      "RequestedWindow" -> window,
      "BoundaryDataRequirements" -> boundaryDataRequirements|>, Module]
  ];

  (* Preserve a one-column zero boundary so downstream transport retains a
     well-formed constant-vector space even when every physical mode is
     exactly zero. *)
  If[coordinates === {},
    coordinates = {<|"BoundaryDataType" -> boundaryDataType,
      dataIDKey -> None, "FrobeniusModeID" -> None,
      analyticClassKey -> "Zero", "EpsilonOrder" -> 0, "Value" -> 0|>};
    modeValues = {<|"Mode" -> ConstantArray[0, dimension],
      "EpsilonOrder" -> 0|>}
  ];
  selectorForOrder[order_] := Transpose@Table[
    Together /@ Map[
      SeriesCoefficient[#, {regulator, 0,
        order - item["EpsilonOrder"]}] &,
      item["Mode"]],
    {item, modeValues}];
  selectors = Association@Table[order -> selectorForOrder[order],
    {order, low, high}];
  If[! AllTrue[Values[selectors],
      MatrixQ[#, MatchQ[#, _Integer | _Rational] &] &],
    fail["BoundarySelectorFieldNotRational",
      <|"BoundaryDataRequirements" -> boundaryDataRequirements|>]
  ];
  constants = Lookup[coordinates, "Value"];
  boundaryVectors = Association@Table[
    order -> Together /@ (selectors[order].constants),
    {order, low, high}];
  functionSpace = Which[
    MemberQ[activeClasses, "Elliptic"], "GPL+Elliptic",
    MemberQ[activeClasses, "GPL"], "GPL",
    True, "Zero"];
  dataStatus = If[FreeQ[constants, boundaryModeCoefficientPattern],
    If[MemberQ[Lookup[boundaryDataRequirements, "Status", {}], "Transferable"],
      "ExactWithTransfers", "Exact"], "FormalNotEvaluated"];
  <|
    "Status" -> If[dataStatus === "FormalNotEvaluated",
      "FormalBoundaryValueVectorAndSelectorMatricesConstructed",
      "BoundaryValueVectorAndSelectorMatricesConstructed"],
    "Family" -> family,
    "PhysicalKinematicLimit" -> physicalLimit,
    "BoundaryDomain" -> modeMap["BoundaryDomain"],
    "BoundaryDataType" -> boundaryDataType,
    "Dimension" -> dimension,
    "Regulator" -> regulator,
    "Window" -> window,
    "FunctionSpace" -> functionSpace,
    "BoundaryDataStatus" -> dataStatus,
    coefficientRecordsKey -> coordinates,
    coefficientLabelsKey -> ({Lookup[#, dataIDKey], #["EpsilonOrder"]} & /@ coordinates),
    "DegenerateResidueEigenspaceBases" ->
      Lookup[modeMap, "DegenerateResidueEigenspaceBases", {}],
    valueVectorKey -> constants,
    "BoundarySelectorMatricesByEpsilonOrder" -> selectors,
    "BoundaryValueVectorByEpsilonOrder" -> boundaryVectors,
    "BoundaryDataRequirements" -> boundaryDataRequirements
  |>
];

boundaryConstructValueVectorAndSelectorMatrices[___] :=
  <|"Status" -> "BoundaryValueAndSelectorInputsInvalid"|>;

Options[ConstructBoundarySelectorMatrices] = {
  "MissingBoundaryDataAction" -> "Refuse"
};
ConstructBoundarySelectorMatrices[modeMatching_Association, boundaryData_,
    window : {_Integer, _Integer}, OptionsPattern[]] := Module[
  {result = boundaryConstructValueVectorAndSelectorMatrices[modeMatching,
      boundaryData, window, "MissingBoundaryDataAction" ->
        OptionValue["MissingBoundaryDataAction"]], labelsKey},
  If[! AssociationQ[result] ||
      ! MemberQ[{"BoundaryValueVectorAndSelectorMatricesConstructed",
        "FormalBoundaryValueVectorAndSelectorMatricesConstructed"},
        Lookup[result, "Status", None]], Return[result]];
  labelsKey = If[result["BoundaryDataType"] === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientLabels",
    "BoundaryFunctionEpsilonCoefficientLabels"];
  Join[KeyTake[result, {"Family", "PhysicalKinematicLimit",
      "BoundaryDomain", "BoundaryDataType", "Regulator", "Window",
      labelsKey, "DegenerateResidueEigenspaceBases",
      "BoundaryDataRequirements"}], <|
    "Status" -> If[result["BoundaryDataStatus"] === "FormalNotEvaluated",
      "FormalBoundarySelectorMatricesConstructed",
      "BoundarySelectorMatricesConstructed"],
    "BoundarySelectorMatricesByEpsilonOrder" ->
      result["BoundarySelectorMatricesByEpsilonOrder"]|>]
];
ConstructBoundarySelectorMatrices[___] :=
  <|"Status" -> "BoundarySelectorMatrixInputsInvalid"|>;

boundaryValueResult[requiredType_, modeMatching_Association, boundaryData_,
    window_, action_] := Module[
  {result = boundaryConstructValueVectorAndSelectorMatrices[modeMatching,
      boundaryData, window, "MissingBoundaryDataAction" -> action],
   labelsKey, recordsKey, vectorKey},
  If[! AssociationQ[result], Return[result]];
  If[Lookup[result, "BoundaryDataType", None] =!= requiredType,
    Return[<|"Status" -> If[requiredType === "BoundaryConstant",
      "PhysicalBoundaryPointRequired", "PhysicalBoundaryStratumRequired"],
      "ActualBoundaryDataType" -> Lookup[result, "BoundaryDataType", Missing[]]|>]];
  If[! MemberQ[{"BoundaryValueVectorAndSelectorMatricesConstructed",
      "FormalBoundaryValueVectorAndSelectorMatricesConstructed"},
      Lookup[result, "Status", None]], Return[result]];
  labelsKey = If[requiredType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientLabels",
    "BoundaryFunctionEpsilonCoefficientLabels"];
  recordsKey = If[requiredType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientRecords",
    "BoundaryFunctionEpsilonCoefficientRecords"];
  vectorKey = If[requiredType === "BoundaryConstant",
    "BoundaryConstantVector", "BoundaryFunctionVector"];
  Join[KeyTake[result, {"Family", "PhysicalKinematicLimit",
      "BoundaryDomain", "BoundaryDataType", "Regulator", "Window",
      "FunctionSpace", "BoundaryDataStatus", labelsKey, recordsKey,
      vectorKey, "DegenerateResidueEigenspaceBases",
      "BoundaryValueVectorByEpsilonOrder", "BoundaryDataRequirements"}], <|
    "Status" -> If[result["BoundaryDataStatus"] === "FormalNotEvaluated",
      If[requiredType === "BoundaryConstant",
        "FormalBoundaryConstantValueVectorConstructed",
        "FormalBoundaryFunctionValueVectorConstructed"],
      If[requiredType === "BoundaryConstant",
        "BoundaryConstantValueVectorConstructed",
        "BoundaryFunctionValueVectorConstructed"]]|>]
];

Options[ConstructBoundaryValueVectorFromConstants] = {
  "MissingBoundaryDataAction" -> "Refuse"
};
ConstructBoundaryValueVectorFromConstants[modeMatching_Association,
    boundaryConstantData_, window : {_Integer, _Integer}, OptionsPattern[]] :=
  boundaryValueResult["BoundaryConstant", modeMatching,
    boundaryConstantData, window, OptionValue["MissingBoundaryDataAction"]];
ConstructBoundaryValueVectorFromConstants[___] :=
  <|"Status" -> "BoundaryConstantValueVectorInputsInvalid"|>;

Options[ConstructBoundaryValueVectorFromFunctions] = {
  "MissingBoundaryDataAction" -> "Refuse"
};
ConstructBoundaryValueVectorFromFunctions[modeMatching_Association,
    boundaryFunctionData_, window : {_Integer, _Integer}, OptionsPattern[]] :=
  boundaryValueResult["BoundaryFunction", modeMatching,
    boundaryFunctionData, window, OptionValue["MissingBoundaryDataAction"]];
ConstructBoundaryValueVectorFromFunctions[___] :=
  <|"Status" -> "BoundaryFunctionValueVectorInputsInvalid"|>;
