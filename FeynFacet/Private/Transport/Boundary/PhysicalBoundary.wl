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
  BuildTransportBoundaryVector, BoundaryPeriodCoefficient];
ClearAll[boundaryExactZeroQ, boundaryCanonicalMatrix,
  boundaryFiniteQ, boundaryParticularSolution, boundaryLocalOrder,
  boundaryLeadingCoefficient, boundaryModeExtension,
  boundaryEpsilonValuation, boundaryExactCoefficientQ,
  boundaryUnambiguouslyPositiveQ];

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
   periodIDs, maximumSeriesOrder, maximumEpsilonOrder, initialLedger,
   logBranch},
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
  logBranch = Lookup[relation, "LogBranch", Automatic];
  If[! MatchQ[localPower, _Integer | _Rational] || localPower <= 0 ||
      boundaryExactZeroQ[endpointCoefficient] ||
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
     normalizedLeading, residueAction, coordinateLog,
     physicalToLocalMode},
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
        ! IntegerQ[periodEpsilonValuation] || ! ListQ[demandedOutputs] ||
        ! AllTrue[demandedOutputs, MatchQ[#, {_Integer, _Integer}] &],
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
    (* If t = alpha rho^kappa, then the physical and local Frobenius
       constants differ by exp(eps Log[alpha] R_rho/kappa).  Keep the
       exponential only to the same epsilon depth as the local prefactor.
       An ordinary zero-residue mode is invariant and needs no branch. *)
    residueAction = Together /@ (residue.normalizedVector);
    physicalToLocalMode = If[boundaryExactZeroQ[residueAction],
      normalizedVector,
      If[logBranch === Automatic,
        If[! boundaryUnambiguouslyPositiveQ[endpointCoefficient],
          Return[<|"Status" -> "PhysicalEndpointLogBranchRequired",
            "PeriodID" -> periodID|>]
        ];
        coordinateLog = Log[endpointCoefficient],
        If[! IntegerQ[logBranch],
          Return[<|"Status" -> "PhysicalEndpointLogBranchInvalid",
            "PeriodID" -> periodID|>]
        ];
        coordinateLog = Log[endpointCoefficient] + 2 Pi I logBranch
      ];
      Together /@ (normalizedVector + Sum[
        (regulator coordinateLog/localPower)^order/Factorial[order]
          MatrixPower[residue, order].normalizedVector,
        {order, 1, maximumEpsilonOrder}])
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
      "PhysicalToLocalMode" -> physicalToLocalMode,
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

Options[BuildTransportBoundaryVector] = {
  "MissingPeriodAction" -> "Refuse"
};

BuildTransportBoundaryVector[modeMap_Association, periodData_,
    window : {_Integer, _Integer}, OptionsPattern[]] := Catch@Module[
  {fail, low = window[[1]], high = window[[2]], action, formalActionQ,
   modes, regulator, dimension, records, normalizedRecords, recordIDs,
   missingGPL = {}, missingElliptic = {}, invalid = {}, depthProblems = {},
   windowProblems = {}, tangentialProblems = {}, coordinates = {},
   modeValues = {}, needsLedger = {},
   appendLedger, markMissing, resolveCoefficients, addCoordinates,
   modeValuation, expectedValuation, activeDemand, targetHigh,
   requiredHigh, requiredOrders, potentialCoordinates, actualCoordinates,
   record, recordStatus, coefficientData, missingOrders, resolved,
   activeClasses = {}, selectorForOrder, selectors, constants,
   boundaryVectors, functionSpace, dataStatus, incompleteStatus},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  action = OptionValue["MissingPeriodAction"];
  formalActionQ = action === "Formal";
  If[low > high || ! MemberQ[{"Refuse", "Formal"}, action],
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
      recordIDs = Lookup[periodData, "PeriodID"];
      If[! DuplicateFreeQ[recordIDs],
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
  appendLedger[mode_, demand_, status_, affected_, data_: <||>] :=
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
      "DemandedOutputs" -> demand,
      "Status" -> status|>, data]];
  markMissing[mode_, orders_] :=
    If[mode["PeriodClass"] === "GPL",
      AppendTo[missingGPL,
        <|"PeriodID" -> mode["PeriodID"], "Orders" -> orders|>],
      AppendTo[missingElliptic,
        <|"PeriodID" -> mode["PeriodID"], "Orders" -> orders|>]];
  resolveCoefficients[mode_, data_Association, orders_List] :=
    Association@Table[order -> If[KeyExistsQ[data, order], data[order],
      BoundaryPeriodCoefficient[mode["PeriodID"], order]],
      {order, orders}];
  addCoordinates[mode_, data_Association, orders_List] := Module[
    {affected = {}, value},
    Do[
      value = data[order];
      If[! boundaryExactZeroQ[value],
        AppendTo[coordinates, <|
          "PeriodID" -> mode["PeriodID"],
          "PeriodClass" -> mode["PeriodClass"],
          "EpsilonOrder" -> order,
          "Value" -> value|>];
        AppendTo[modeValues, <|"Mode" -> mode["CanonicalMode"],
          "EpsilonOrder" -> order|>];
        AppendTo[affected, {mode["PeriodID"], order}]
      ],
      {order, orders}];
    If[affected =!= {}, AppendTo[activeClasses, mode["PeriodClass"]]];
    affected
  ];

  Do[
    (* A mode absent from the already-pruned demand can require no boundary
       coefficient and therefore gets no needs-ledger row. *)
    activeDemand = DeleteDuplicates@Select[mode["DemandedOutputs"],
      MatchQ[#, {_Integer, _Integer}] &&
        low <= First[#] <= high &];
    If[activeDemand === {}, Continue[]];
    modeValuation = boundaryEpsilonValuation[
      mode["CanonicalMode"], regulator];
    expectedValuation = mode["PeriodEpsilonValuation"];
    If[modeValuation === $Failed || ! IntegerQ[modeValuation],
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "CanonicalModeNotRationalInRegulator"|>];
      appendLedger[mode, activeDemand, "Unevaluated", {},
        <|"Problem" -> "CanonicalModeNotRationalInRegulator"|>];
      Continue[]
    ];
    targetHigh = Max[activeDemand[[All, 1]]];
    requiredHigh = targetHigh - modeValuation;
    requiredOrders = If[expectedValuation <= requiredHigh,
      Range[expectedValuation, requiredHigh], {}];
    potentialCoordinates =
      {mode["PeriodID"], #} & /@ requiredOrders;
    If[requiredOrders === {}, Continue[]];
    (* The local solution is H(rho,eps) rho^(eps R)c.  A rational boundary
       selector represents it without extra tangential data only for an
       ordinary zero-residue mode.  Nonzero eigenvalues carry
       exp(eps lambda log rho), and generalized modes carry additional log
       powers; silently dropping either factor changes the solution. *)
    If[Lookup[mode, "GeneralizedLevel", Missing[]] =!= 0 ||
        ! boundaryExactZeroQ[
          Lookup[mode, "LocalEigenvalue", Missing[]]],
      AppendTo[tangentialProblems, <|
        "PeriodID" -> mode["PeriodID"],
        "LocalEigenvalue" -> Lookup[mode, "LocalEigenvalue", Missing[]],
        "GeneralizedLevel" ->
          Lookup[mode, "GeneralizedLevel", Missing[]]|>];
      appendLedger[mode, activeDemand, "Unevaluated",
        potentialCoordinates, <|
          "Problem" -> "TangentialLogModeRequired",
          "LocalEigenvalue" ->
            Lookup[mode, "LocalEigenvalue", Missing[]],
          "GeneralizedLevel" ->
            Lookup[mode, "GeneralizedLevel", Missing[]]|>];
      Continue[]
    ];
    If[expectedValuation + modeValuation < low,
      AppendTo[windowProblems, <|"PeriodID" -> mode["PeriodID"],
        "NeededMinimumOrder" -> expectedValuation + modeValuation,
        "AvailableMinimumOrder" -> low|>];
      appendLedger[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "BoundaryEpsilonWindowTooNarrow"|>];
      Continue[]
    ];
    If[targetHigh - expectedValuation >
        modeMap["MaximumEpsilonOrder"],
      AppendTo[depthProblems, <|"PeriodID" -> mode["PeriodID"],
        "NeededEpsilonOrder" -> targetHigh - expectedValuation,
        "AvailableEpsilonOrder" -> modeMap["MaximumEpsilonOrder"]|>];
      appendLedger[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "FrobeniusDepthInsufficient"|>];
      Continue[]
    ];
    record = Lookup[normalizedRecords, mode["PeriodID"], Missing[]];
    If[MissingQ[record] || ! AssociationQ[record],
      If[formalActionQ,
        resolved = resolveCoefficients[mode, <||>, requiredOrders];
        actualCoordinates = addCoordinates[mode, resolved, requiredOrders],
        markMissing[mode, requiredOrders];
        actualCoordinates = potentialCoordinates];
      appendLedger[mode, activeDemand, "Unevaluated",
        actualCoordinates];
      Continue[]
    ];
    If[Lookup[record, "PeriodID", mode["PeriodID"]] =!=
        mode["PeriodID"],
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "PeriodIDMismatch"|>];
      appendLedger[mode, activeDemand, "Unevaluated",
        potentialCoordinates, <|"Problem" -> "PeriodIDMismatch"|>];
      Continue[]
    ];
    If[Lookup[record, "PeriodClass", None] =!= mode["PeriodClass"],
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "PeriodClassMismatch"|>];
      appendLedger[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "PeriodClassMismatch"|>];
      Continue[]
    ];
    recordStatus = Lookup[record, "Status", None];
    If[recordStatus === "ExactZero",
      appendLedger[mode, activeDemand, "KnownZero", {}];
      Continue[]
    ];
    If[recordStatus === "Transferable",
      coefficientData = Lookup[record, "TransferMap", <||>];
      If[! AssociationQ[coefficientData] ||
          ! AllTrue[Lookup[coefficientData,
              Intersection[Keys[coefficientData], requiredOrders]],
            boundaryExactCoefficientQ[#, regulator] &],
        AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
          "Reason" -> "TransferMapInvalid"|>];
        appendLedger[mode, activeDemand, "Transferable",
          potentialCoordinates, <|"Problem" -> "TransferMapInvalid"|>];
        Continue[]
      ];
      missingOrders = Complement[requiredOrders, Keys[coefficientData]];
      If[missingOrders =!= {} && ! formalActionQ,
        markMissing[mode, missingOrders];
        appendLedger[mode, activeDemand, "Transferable",
          potentialCoordinates,
          Join[KeyTake[record, {"TransferFrom"}],
            <|"MissingOrders" -> missingOrders|>]];
        Continue[]
      ];
      resolved = resolveCoefficients[mode, coefficientData,
        requiredOrders];
      actualCoordinates = addCoordinates[mode, resolved, requiredOrders];
      appendLedger[mode, activeDemand, "Transferable",
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
      appendLedger[mode, activeDemand, "Unevaluated",
        actualCoordinates];
      Continue[]
    ];
    If[Lookup[record, "Valuation", Missing[]] =!=
        expectedValuation ||
        ! AssociationQ[Lookup[record, "Coefficients", Missing[]]],
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "PeriodSeriesInvalid",
        "ExpectedValuation" -> expectedValuation,
        "ActualValuation" -> Lookup[record, "Valuation", Missing[]]|>];
      appendLedger[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "PeriodSeriesInvalid"|>];
      Continue[]
    ];
    coefficientData = record["Coefficients"];
    If[! AllTrue[Lookup[coefficientData,
          Intersection[Keys[coefficientData], requiredOrders]],
        boundaryExactCoefficientQ[#, regulator] &&
          FreeQ[#, _BoundaryPeriodCoefficient] &] ||
        (MemberQ[requiredOrders, expectedValuation] &&
          KeyExistsQ[coefficientData, expectedValuation] &&
          boundaryExactZeroQ[coefficientData[expectedValuation]]),
      AppendTo[invalid, <|"PeriodID" -> mode["PeriodID"],
        "Reason" -> "PeriodCoefficientsNotExact"|>];
      appendLedger[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"Problem" -> "PeriodCoefficientsNotExact"|>];
      Continue[]
    ];
    missingOrders = Complement[requiredOrders, Keys[coefficientData]];
    If[missingOrders =!= {} && ! formalActionQ,
      markMissing[mode, missingOrders];
      appendLedger[mode, activeDemand, "Unevaluated",
        potentialCoordinates,
        <|"MissingOrders" -> missingOrders|>];
      Continue[]
    ];
    resolved = resolveCoefficients[mode, coefficientData,
      requiredOrders];
    actualCoordinates = addCoordinates[mode, resolved, requiredOrders];
    appendLedger[mode, activeDemand,
      If[missingOrders === {}, "KnownExact", "Unevaluated"],
      actualCoordinates,
      If[missingOrders === {}, <||>,
        <|"MissingOrders" -> missingOrders|>]],
    {mode, modes}];
  If[tangentialProblems =!= {},
    Return[<|"Status" -> "TangentialLogModeRequired",
      "Family" -> modeMap["Family"], "Limit" -> modeMap["Limit"],
      "RequestedWindow" -> window, "Problems" -> tangentialProblems,
      "Stage3NeedsLedger" -> needsLedger|>, Module]
  ];
  If[windowProblems =!= {},
    Return[<|"Status" -> "BoundaryEpsilonWindowTooNarrow",
      "Family" -> modeMap["Family"], "Limit" -> modeMap["Limit"],
      "RequestedWindow" -> window, "Problems" -> windowProblems,
      "Stage3NeedsLedger" -> needsLedger|>, Module]
  ];
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
  dataStatus = If[FreeQ[constants, _BoundaryPeriodCoefficient],
    If[MemberQ[Lookup[needsLedger, "Status", {}], "Transferable"],
      "ExactWithTransfers", "Exact"], "FormalNotEvaluated"];
  <|
    "Status" -> If[dataStatus === "FormalNotEvaluated",
      "FormalTransportBoundaryVectorBuilt",
      "TransportBoundaryVectorBuilt"],
    "Family" -> modeMap["Family"],
    "Limit" -> modeMap["Limit"],
    "Dimension" -> dimension,
    "Regulator" -> regulator,
    "Window" -> window,
    "FunctionSpace" -> functionSpace,
    "BoundaryDataStatus" -> dataStatus,
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
