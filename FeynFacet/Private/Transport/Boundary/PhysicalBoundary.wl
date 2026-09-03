(* ::Package:: *)

(* Singular physical endpoints are not ordinary evaluation points.  This
   module supplies the missing three-step boundary map:

     epsilon-form connection -> local Frobenius prefactor and residue,
     physical endpoint asymptotics -> normalized canonical modes,
     exact period coefficients -> boundary selectors and constants.

   The selectors are rational matrices, so transport remains linear in a
   vector of exact boundary constants.  GPL constants and elliptic periods
   therefore share the same transport engine without being conflated. *)

Clear[BuildEndpointFrobenius, BuildBoundaryModeMap,
  BuildTransportBoundaryVector];
ClearAll[boundaryExactZeroQ, boundaryCanonicalMatrix,
  boundaryFiniteQ, boundaryParticularSolution, boundaryLocalOrder,
  boundaryLeadingCoefficient, boundaryModeExtension,
  boundaryEpsilonValuation, boundaryExactCoefficientQ];

boundaryExactZeroQ[value_] :=
  AllTrue[Flatten[{Normal[value]}],
    Quiet[Check[Together[#] === 0, False]] &];

boundaryCanonicalMatrix[matrix_] :=
  Map[Together, Normal[matrix], {2}];

boundaryFiniteQ[value_] :=
  FreeQ[value, Indeterminate | ComplexInfinity | DirectedInfinity[_]];

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
  {numerator, denominator, scale = Unique["boundaryScale$"]},
  {numerator, denominator} = NumeratorDenominator[Together[expression]];
  If[! PolynomialQ[numerator, variable] ||
      ! PolynomialQ[denominator, variable],
    Return[$Failed]
  ];
  Exponent[numerator /. variable -> scale variable, scale, Min] -
    Exponent[denominator /. variable -> scale variable, scale, Min]
];

boundaryLeadingCoefficient[0, _, _] := 0;
boundaryLeadingCoefficient[expression_, order_Integer,
    variable_Symbol] :=
  Together[Limit[expression/variable^order, variable -> 0]];

Options[BuildEndpointFrobenius] = {
  "MaximumSeriesOrder" -> 4,
  "MaximumEpsilonOrder" -> 3
};

BuildEndpointFrobenius[connection_?MatrixQ, spec_Association,
    OptionsPattern[]] := Catch@Module[
  {fail, matrix, dimension, variable, regulator, localVariable, endpoint,
   fixedRules, maximumSeriesOrder, maximumEpsilonOrder, normalized,
   residue, regularConnection, regularCoefficients, h, zero, source,
   prefactorCoefficients, regularTruncation, prefactorTruncation,
   residual, residualCoefficients},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  matrix = Normal[connection];
  If[Length[Dimensions[matrix]] =!= 2 ||
      Dimensions[matrix][[1]] =!= Dimensions[matrix][[2]],
    fail["EndpointConnectionNotSquare"]
  ];
  dimension = Length[matrix];
  variable = Lookup[spec, "Variable", Missing[]];
  regulator = Lookup[spec, "Regulator", Missing[]];
  localVariable = Lookup[spec, "LocalVariable", Global`rho];
  endpoint = Lookup[spec, "Endpoint", Missing[]];
  fixedRules = Lookup[spec, "FixedRules", {}];
  maximumSeriesOrder = OptionValue["MaximumSeriesOrder"];
  maximumEpsilonOrder = OptionValue["MaximumEpsilonOrder"];
  If[! MatchQ[variable, _Symbol] || ! MatchQ[regulator, _Symbol] ||
      ! MatchQ[localVariable, _Symbol] || MissingQ[endpoint] ||
      ! FreeQ[endpoint, variable] || ! ListQ[fixedRules] ||
      ! IntegerQ[maximumSeriesOrder] || maximumSeriesOrder < 1 ||
      ! IntegerQ[maximumEpsilonOrder] || maximumEpsilonOrder < 0 ||
      ! DuplicateFreeQ[{variable, regulator, localVariable}],
    fail["EndpointSpecificationInvalid"]
  ];
  normalized = boundaryCanonicalMatrix[
    (matrix /. fixedRules /. variable -> endpoint + localVariable)/
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
    fail["EndpointNotFuchsian"]
  ];
  regularConnection = boundaryCanonicalMatrix[
    normalized - residue/localVariable];
  If[! boundaryFiniteQ@Map[
      Quiet[Check[Limit[#, localVariable -> 0], Indeterminate]] &,
      regularConnection, {2}],
    fail["EndpointNotFuchsian"]
  ];
  regularCoefficients = Association@Table[order ->
      boundaryCanonicalMatrix@Map[
        Quiet[Check[
          Limit[D[#, {localVariable, order}], localVariable -> 0]/
            Factorial[order], Indeterminate]] &,
        regularConnection, {2}],
    {order, 0, maximumSeriesOrder - 1}];
  If[! boundaryFiniteQ[Values[regularCoefficients]],
    fail["EndpointNotFuchsian"]
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
    fail["FrobeniusRecurrenceFailed"]
  ];
  <|
    "Status" -> "EndpointFrobeniusBuilt",
    "Dimension" -> dimension,
    "Variable" -> variable,
    "Regulator" -> regulator,
    "LocalVariable" -> localVariable,
    "Endpoint" -> endpoint,
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

BuildEndpointFrobenius[___] :=
  <|"Status" -> "EndpointFrobeniusInputInvalid"|>;

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

BuildBoundaryModeMap[frobenius_Association, transformation_?MatrixQ,
    spec_Association, realizations_List] := Catch@Module[
  {fail, dimension, residue, regulator, variable, localVariable, endpoint,
   fixedRules, relation, localPower, endpointCoefficient, family, limit,
   transformationLocal, prefactor, buildMode, modes, physicalDimension,
   periodIDs, maximumSeriesOrder, maximumEpsilonOrder, initialLedger},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  If[Lookup[frobenius, "Status", None] =!= "EndpointFrobeniusBuilt",
    fail["EndpointFrobeniusRequired"]
  ];
  dimension = frobenius["Dimension"];
  residue = frobenius["Residue"];
  regulator = frobenius["Regulator"];
  variable = frobenius["Variable"];
  localVariable = frobenius["LocalVariable"];
  endpoint = frobenius["Endpoint"];
  maximumSeriesOrder = frobenius["MaximumSeriesOrder"];
  maximumEpsilonOrder = frobenius["MaximumEpsilonOrder"];
  fixedRules = Lookup[spec, "FixedRules", frobenius["FixedRules"]];
  relation = Lookup[spec, "PhysicalEndpointRelation", Missing[]];
  family = Lookup[spec, "Family", Missing[]];
  limit = Lookup[spec, "Limit", relation];
  If[MissingQ[family] || MissingQ[limit],
    fail["BoundaryContextRequired"]
  ];
  If[! AssociationQ[relation] ||
      ! KeyExistsQ[relation, "LocalPower"] ||
      ! KeyExistsQ[relation, "LeadingCoefficient"],
    fail["PhysicalEndpointRelationRequired"]
  ];
  localPower = relation["LocalPower"];
  endpointCoefficient = relation["LeadingCoefficient"];
  If[! MatchQ[localPower, _Integer | _Rational] || localPower <= 0 ||
      ! FreeQ[endpointCoefficient, variable | localVariable | regulator],
    fail["PhysicalEndpointRelationInvalid"]
  ];
  transformationLocal = boundaryCanonicalMatrix[
    Normal[transformation] /. fixedRules /.
      variable -> endpoint + localVariable];
  If[Dimensions[transformationLocal][[2]] =!= dimension,
    fail["EndpointTransformationDimensionMismatch"]
  ];
  physicalDimension = Dimensions[transformationLocal][[1]];
  prefactor = Total@KeyValueMap[
    Function[{key, coefficient},
      regulator^key[[2]] localVariable^key[[1]] coefficient],
    frobenius["FrobeniusPrefactorCoefficients"]];

  buildMode[realization_] := Module[
    {periodID, periodClass, periodEpsilonValuation, canonicalRows,
     physicalRows, constraintRows, demandedOutputs, exponent,
     integerValuation, maximumLevel, suppliedSeed, eigenvalue,
     extension, vector, mapped, selected, orders, expectedOrder,
     candidates, requestedNormalizationRow, normalizationIndex,
     expectedLeading, actualLeading, normalization, normalizedVector,
     normalizedMapped, normalizedSelected, normalizedOrders,
     normalizedLeading},
    If[! AssociationQ[realization],
      Return[<|"Status" -> "BoundaryRealizationInvalid"|>]
    ];
    periodID = Lookup[realization, "PeriodID", Missing[]];
    periodClass = Lookup[realization, "PeriodClass", Missing[]];
    periodEpsilonValuation = Lookup[realization,
      "PeriodEpsilonValuation", Missing[]];
    canonicalRows = Lookup[realization, "CanonicalRows", Missing[]];
    physicalRows = Lookup[realization, "PhysicalRows", Missing[]];
    demandedOutputs = Lookup[realization, "DemandedOutputs", {}];
    exponent = Lookup[realization, "EpsilonExponent", Missing[]];
    integerValuation = Lookup[realization, "IntegerValuation", Missing[]];
    maximumLevel = Lookup[realization, "LogLevel", 0];
    suppliedSeed = Lookup[realization, "CanonicalSeed", Automatic];
    If[MissingQ[periodID] ||
        ! MemberQ[{"GPL", "Elliptic"}, periodClass] ||
        ! IntegerQ[periodEpsilonValuation] || ! ListQ[demandedOutputs],
      Return[<|"Status" -> "BoundaryPeriodDescriptionInvalid",
        "PeriodID" -> periodID|>]
    ];
    If[! MatchQ[canonicalRows, {__Integer}] ||
        ! DuplicateFreeQ[canonicalRows] ||
        ! AllTrue[canonicalRows, 1 <= # <= dimension &] ||
        ! MatchQ[physicalRows, {__Integer}] ||
        ! DuplicateFreeQ[physicalRows] ||
        ! AllTrue[physicalRows, 1 <= # <= physicalDimension &],
      Return[<|"Status" -> "BoundaryModeRowsInvalid",
        "PeriodID" -> periodID|>]
    ];
    constraintRows = Lookup[realization, "ConstraintRows",
      Range[Max[canonicalRows]]];
    If[! MatchQ[constraintRows, {__Integer}] ||
        ! DuplicateFreeQ[constraintRows] ||
        ! AllTrue[constraintRows, 1 <= # <= dimension &],
      Return[<|"Status" -> "BoundaryModeConstraintsInvalid",
        "PeriodID" -> periodID|>]
    ];
    If[! MatchQ[exponent, _Integer | _Rational] ||
        ! IntegerQ[integerValuation] ||
        ! IntegerQ[maximumLevel] || maximumLevel < 0,
      Return[<|"Status" -> "BoundaryModePowersInvalid",
        "PeriodID" -> periodID|>]
    ];
    eigenvalue = Together[localPower exponent];
    extension = boundaryModeExtension[residue, canonicalRows,
      constraintRows, eigenvalue, maximumLevel, suppliedSeed];
    If[extension["Status"] =!= "Exact",
      Return[Join[<|"PeriodID" -> periodID,
          "PeriodClass" -> periodClass|>, extension]]
    ];
    vector = extension["Vector"];
    mapped = Together /@ (transformationLocal.prefactor.vector);
    selected = mapped[[physicalRows]];
    orders = boundaryLocalOrder[#, localVariable] & /@ selected;
    If[MemberQ[orders, $Failed],
      Return[<|"Status" -> "PhysicalModeNotRationalAtEndpoint",
        "PeriodID" -> periodID|>]
    ];
    expectedOrder = localPower integerValuation;
    If[! IntegerQ[expectedOrder],
      Return[<|"Status" -> "PhysicalValuationNotIntegral",
        "PeriodID" -> periodID|>]
    ];
    If[expectedOrder > maximumSeriesOrder,
      Return[<|"Status" -> "FrobeniusDepthInsufficient",
        "PeriodID" -> periodID,
        "NeededSeriesOrder" -> expectedOrder,
        "AvailableSeriesOrder" -> maximumSeriesOrder|>]
    ];
    candidates = Flatten@Position[orders, expectedOrder];
    If[candidates === {},
      Return[<|"Status" -> "PhysicalValuationMismatch",
        "PeriodID" -> periodID, "ComputedOrders" -> orders,
        "ExpectedOrder" -> expectedOrder|>]
    ];
    requestedNormalizationRow = Lookup[realization,
      "NormalizationPhysicalRow", Automatic];
    normalizationIndex = If[requestedNormalizationRow === Automatic,
      First[candidates],
      SelectFirst[candidates,
        physicalRows[[#]] === requestedNormalizationRow &, None]
    ];
    If[normalizationIndex === None,
      Return[<|"Status" -> "NormalizationRowInvalid",
        "PeriodID" -> periodID|>]
    ];
    expectedLeading = Together[endpointCoefficient^integerValuation];
    actualLeading = boundaryLeadingCoefficient[
      selected[[normalizationIndex]], expectedOrder, localVariable];
    If[boundaryExactZeroQ[actualLeading] ||
        ! boundaryFiniteQ[actualLeading],
      Return[<|"Status" -> "ModeNormalizationFailed",
        "PeriodID" -> periodID|>]
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
      Return[<|"Status" -> "BoundaryModeValidationFailed",
        "PeriodID" -> periodID|>]
    ];
    <|
      "Status" -> "BoundaryModeMatched",
      "PeriodID" -> periodID,
      "PeriodClass" -> periodClass,
      "PeriodEpsilonValuation" -> periodEpsilonValuation,
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
      "PhysicalLocalOrders" -> normalizedOrders,
      "PhysicalLeadingCoefficients" -> normalizedLeading
    |>
  ];

  modes = buildMode /@ realizations;
  periodIDs = DeleteCases[Lookup[modes, "PeriodID", Missing[]],
    _Missing];
  If[! DuplicateFreeQ[periodIDs],
    fail["DuplicateBoundaryPeriodID", <|"PeriodIDs" -> periodIDs|>]
  ];
  initialLedger = Map[Function[mode, <|
      "PeriodID" -> Lookup[mode, "PeriodID", Missing[]],
      "PeriodClass" -> Lookup[mode, "PeriodClass", Missing[]],
      "Family" -> family,
      "Limit" -> limit,
      "FrobeniusMode" -> KeyTake[mode,
        {"CanonicalRows", "LocalEigenvalue", "GeneralizedLevel"}],
      "AffectedBoundaryCoordinates" -> {},
      "DemandedOutputs" -> Lookup[mode, "DemandedOutputs", {}],
      "Status" -> "Unevaluated",
      "Problem" -> If[Lookup[mode, "Status", None] ===
        "BoundaryModeMatched", "PeriodDataRequired",
        Lookup[mode, "Status", "BoundaryModeIncomplete"]]|>], modes];
  <|
    "Status" -> If[AllTrue[modes,
      Lookup[#, "Status", None] === "BoundaryModeMatched" &],
      "BoundaryModeMapBuilt", "BoundaryModeMapIncomplete"],
    "Family" -> family,
    "Limit" -> limit,
    "Dimension" -> dimension,
    "PhysicalDimension" -> physicalDimension,
    "Regulator" -> regulator,
    "MaximumSeriesOrder" -> maximumSeriesOrder,
    "MaximumEpsilonOrder" -> maximumEpsilonOrder,
    "LocalVariable" -> localVariable,
    "Endpoint" -> endpoint,
    "PhysicalEndpointRelation" -> relation,
    "Modes" -> modes,
    "Stage3NeedsLedger" -> initialLedger
  |>
];

BuildBoundaryModeMap[___] :=
  <|"Status" -> "BoundaryModeMapInputInvalid"|>;

boundaryEpsilonValuation[vector_List, regulator_Symbol] := Module[
  {orders = DeleteCases[
     boundaryLocalOrder[#, regulator] & /@ vector, Infinity]},
  If[orders === {} || MemberQ[orders, $Failed], $Failed, Min[orders]]
];

boundaryExactCoefficientQ[value_, regulator_Symbol] :=
  FreeQ[value, regulator | _Real | _Missing | Indeterminate |
    ComplexInfinity | DirectedInfinity[_]];

BuildTransportBoundaryVector[modeMap_Association, periodData_,
    window : {_Integer, _Integer}] := Catch@Module[
  {fail, low = window[[1]], high = window[[2]], modes, regulator,
   dimension, records, normalizedRecords, recordList, missingGPL = {},
   missingElliptic = {}, invalid = {}, coordinates = {}, modeValues = {},
   depthProblems = {}, needsLedger = {}, appendLedger, modeValuation,
   markMissing, expectedValuation,
   record, recordStatus, valuation, requiredHigh, coefficients,
   missingOrders, values, potentialCoordinates, actualCoordinates,
   activeClasses = {}, selectorForOrder, selectors, constants,
   boundaryVectors, functionSpace, incompleteStatus},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  If[low > high,
    fail["BoundaryEpsilonWindowInvalid"]
  ];
  If[Lookup[modeMap, "Status", None] =!= "BoundaryModeMapBuilt",
    fail["CompleteBoundaryModeMapRequired",
      <|"Stage3NeedsLedger" ->
        Lookup[modeMap, "Stage3NeedsLedger", {}]|>]
  ];
  modes = modeMap["Modes"];
  regulator = modeMap["Regulator"];
  dimension = modeMap["Dimension"];
  records = Which[
    AssociationQ[periodData], periodData,
    ListQ[periodData] && AllTrue[periodData, AssociationQ] &&
        AllTrue[periodData, KeyExistsQ[#, "PeriodID"] &],
      recordList = Lookup[periodData, "PeriodID"];
      If[! DuplicateFreeQ[recordList],
        fail["BoundaryPeriodDataInvalid",
          <|"Reason" -> "DuplicatePeriodID"|>]
      ];
      Association@Table[item["PeriodID"] -> item,
        {item, periodData}],
    True, fail["BoundaryPeriodDataInvalid"]
  ];
  normalizedRecords = Association@KeyValueMap[
    #1 -> If[AssociationQ[#2] && ! KeyExistsQ[#2, "PeriodID"],
      Join[<|"PeriodID" -> #1|>, #2], #2] &, records];
  appendLedger[mode_, status_, affected_, data_: <||>] :=
    AppendTo[needsLedger, Join[<|
      "PeriodID" -> mode["PeriodID"],
      "PeriodClass" -> mode["PeriodClass"],
      "Family" -> modeMap["Family"],
      "Limit" -> modeMap["Limit"],
      "FrobeniusMode" -> <|
        "CanonicalRows" -> mode["CanonicalRows"],
        "LocalEigenvalue" -> mode["LocalEigenvalue"],
        "GeneralizedLevel" -> mode["GeneralizedLevel"]|>,
      "AffectedBoundaryCoordinates" -> affected,
      "DemandedOutputs" -> mode["DemandedOutputs"],
      "Status" -> status|>, data]];
  markMissing[mode_, orders_] :=
    If[mode["PeriodClass"] === "GPL",
      AppendTo[missingGPL,
        <|"PeriodID" -> mode["PeriodID"], "Orders" -> orders|>],
      AppendTo[missingElliptic,
        <|"PeriodID" -> mode["PeriodID"], "Orders" -> orders|>]];

  Do[
    modeValuation = boundaryEpsilonValuation[
      mode["CanonicalMode"], regulator];
    expectedValuation = mode["PeriodEpsilonValuation"];
    If[modeValuation === $Failed || ! IntegerQ[modeValuation],
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "CanonicalModeNotRationalInRegulator"|>];
      appendLedger[mode, "Unevaluated", {},
        <|"Problem" -> "CanonicalModeNotRationalInRegulator"|>];
      Continue[]
    ];
    requiredHigh = high - modeValuation;
    potentialCoordinates = If[expectedValuation <= requiredHigh,
      Table[{mode["PeriodID"], order},
        {order, expectedValuation, requiredHigh}], {}];
    If[high - expectedValuation > modeMap["MaximumEpsilonOrder"],
      AppendTo[depthProblems, <|"PeriodID" -> mode["PeriodID"],
        "NeededEpsilonOrder" -> high - expectedValuation,
        "AvailableEpsilonOrder" -> modeMap["MaximumEpsilonOrder"]|>];
      appendLedger[mode, "Unevaluated", potentialCoordinates,
        <|"Problem" -> "FrobeniusDepthInsufficient"|>];
      Continue[]
    ];
    record = Lookup[normalizedRecords, mode["PeriodID"], Missing[]];
    If[MissingQ[record] || ! AssociationQ[record],
      markMissing[mode, If[potentialCoordinates === {}, {},
        potentialCoordinates[[All, 2]]]];
      appendLedger[mode, "Unevaluated", potentialCoordinates];
      Continue[]
    ];
    If[Lookup[record, "PeriodClass", None] =!= mode["PeriodClass"],
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "PeriodClassMismatch"|>];
      appendLedger[mode, "Unevaluated", potentialCoordinates,
        <|"Problem" -> "PeriodClassMismatch"|>];
      Continue[]
    ];
    recordStatus = Lookup[record, "Status", None];
    If[recordStatus === "ExactZero",
      appendLedger[mode, "KnownZero", {}];
      Continue[]
    ];
    If[recordStatus === "Transferable",
      markMissing[mode, If[potentialCoordinates === {}, {},
        potentialCoordinates[[All, 2]]]];
      appendLedger[mode, "Transferable", potentialCoordinates,
        KeyTake[record, {"TransferFrom", "TransferMap"}]];
      Continue[]
    ];
    If[recordStatus =!= "Exact",
      markMissing[mode, If[potentialCoordinates === {}, {},
        potentialCoordinates[[All, 2]]]];
      appendLedger[mode, "Unevaluated", potentialCoordinates];
      Continue[]
    ];
    valuation = Lookup[record, "Valuation", Missing[]];
    coefficients = Lookup[record, "Coefficients", Missing[]];
    If[valuation =!= expectedValuation || ! AssociationQ[coefficients],
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "PeriodSeriesInvalid",
        "ExpectedValuation" -> expectedValuation,
        "ActualValuation" -> valuation|>];
      appendLedger[mode, "Unevaluated", potentialCoordinates,
        <|"Problem" -> "PeriodSeriesInvalid"|>];
      Continue[]
    ];
    missingOrders = If[valuation <= requiredHigh,
      Complement[Range[valuation, requiredHigh], Keys[coefficients]], {}];
    If[missingOrders =!= {},
      markMissing[mode, missingOrders];
      appendLedger[mode, "Unevaluated", potentialCoordinates,
        <|"MissingOrders" -> missingOrders|>];
      Continue[]
    ];
    values = If[valuation <= requiredHigh,
      Lookup[coefficients, Range[valuation, requiredHigh]], {}];
    If[! AllTrue[values,
        boundaryExactCoefficientQ[#, regulator] &] ||
        (valuation <= requiredHigh &&
          boundaryExactZeroQ[Lookup[coefficients, valuation]]),
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "PeriodCoefficientsNotExact"|>];
      appendLedger[mode, "Unevaluated", potentialCoordinates,
        <|"Problem" -> "PeriodCoefficientsNotExact"|>];
      Continue[]
    ];
    actualCoordinates = {};
    Do[
      If[! boundaryExactZeroQ[coefficients[order]],
        AppendTo[coordinates, <|
          "PeriodID" -> mode["PeriodID"],
          "PeriodClass" -> mode["PeriodClass"],
          "EpsilonOrder" -> order,
          "Value" -> coefficients[order]|>];
        AppendTo[modeValues, <|"Mode" -> mode["CanonicalMode"],
          "EpsilonOrder" -> order|>];
        AppendTo[actualCoordinates, {mode["PeriodID"], order}]
      ],
      {order, valuation, requiredHigh}];
    If[actualCoordinates =!= {},
      AppendTo[activeClasses, mode["PeriodClass"]]];
    appendLedger[mode, "KnownExact", actualCoordinates],
    {mode, modes}];
  If[depthProblems =!= {},
    Return[<|"Status" -> "FrobeniusDepthInsufficient",
      "Family" -> modeMap["Family"], "Limit" -> modeMap["Limit"],
      "RequestedWindow" -> window, "Problems" -> depthProblems,
      "Stage3NeedsLedger" -> needsLedger|>, Module]
  ];
  If[invalid =!= {},
    Return[<|"Status" -> "BoundaryPeriodDataInvalid",
      "Family" -> modeMap["Family"], "Limit" -> modeMap["Limit"],
      "RequestedWindow" -> window, "Problems" -> invalid,
      "Stage3NeedsLedger" -> needsLedger|>, Module]
  ];
  If[missingGPL =!= {} || missingElliptic =!= {},
    incompleteStatus = Which[
      missingGPL =!= {} && missingElliptic =!= {},
        "BoundaryDataIncomplete",
      missingGPL =!= {}, "GPLBoundaryConstantsIncomplete",
      True, "EllipticBoundaryPeriodsIncomplete"];
    Return[<|"Status" -> incompleteStatus,
      "Family" -> modeMap["Family"], "Limit" -> modeMap["Limit"],
      "MissingGPLConstants" -> missingGPL,
      "MissingEllipticPeriods" -> missingElliptic,
      "RequestedWindow" -> window,
      "Stage3NeedsLedger" -> needsLedger|>, Module]
  ];

  (* Preserve a one-column zero boundary so downstream transport retains a
     well-formed constant-vector space even when every physical mode is
     exactly zero. *)
  If[coordinates === {},
    coordinates = {<|"PeriodID" -> None, "PeriodClass" -> "Zero",
      "EpsilonOrder" -> 0, "Value" -> 0|>};
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
      <|"Stage3NeedsLedger" -> needsLedger|>]
  ];
  constants = Lookup[coordinates, "Value"];
  boundaryVectors = Association@Table[
    order -> Together /@ (selectors[order].constants),
    {order, low, high}];
  functionSpace = Which[
    MemberQ[activeClasses, "Elliptic"], "GPL+Elliptic",
    MemberQ[activeClasses, "GPL"], "GPL",
    True, "Zero"];
  <|
    "Status" -> "TransportBoundaryVectorBuilt",
    "Family" -> modeMap["Family"],
    "Limit" -> modeMap["Limit"],
    "Dimension" -> dimension,
    "Regulator" -> regulator,
    "Window" -> window,
    "FunctionSpace" -> functionSpace,
    "BoundaryCoordinates" -> coordinates,
    "BoundaryConstantVector" -> constants,
    "BoundarySelectors" -> selectors,
    "BoundaryVector" -> boundaryVectors,
    "TransportBoundary" -> <|"Dimension" -> dimension,
      "BoundarySelectors" -> selectors|>,
    "Stage3NeedsLedger" -> needsLedger
  |>
];

BuildTransportBoundaryVector[___] :=
  <|"Status" -> "TransportBoundaryVectorInputInvalid"|>;
