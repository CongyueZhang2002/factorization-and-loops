(* ::Package:: *)

BeginPackage["FeynFacetCampaign`PhysicalBoundary`"];

BuildEndpointAutomatonBoundaryAdapter::usage =
  "BuildEndpointAutomatonBoundaryAdapter[operator, modeMap, boundaryData] builds the " <>
  "finite endpoint-to-interior word map needed to feed singular zero modes into an " <>
  "exact requested-output iterated-integral coefficient operator for explicitly " <>
  "requested first- and second-path-segment letter-index sequences.  " <>
  "The returned coordinate maps are rational; unevaluated boundary data are represented " <>
  "by BoundaryConstantEpsilonCoefficient[id, order] or " <>
  "BoundaryFunctionEpsilonCoefficient[id, order], according to the boundary domain.";

ComposeEndpointAutomatonBoundaryCoefficientMaps::usage =
  "ComposeEndpointAutomatonBoundaryCoefficientMaps[adapter, operator, sequencePairs] composes endpoint " <>
  "connection words with prepared first- and second-path-segment letter-index " <>
  "sequences and returns maps to boundary-data coefficients.  Unprepared " <>
  "sequences fail typed.";

BuildGradedPhysicalEndpointTransport::usage =
  "BuildGradedPhysicalEndpointTransport[operator, modeMap, boundaryData] closes the " <>
  "validated requested-output coefficient operator under its current-path word " <>
  "operators grade by grade, " <>
  "then attaches the endpoint Frobenius transport to a basis of each finite row space. " <>
  "It represents every requested-weight word without enumerating the alphabet product.";

ComposeGradedPhysicalEndpointWords::usage =
  "ComposeGradedPhysicalEndpointWords[binding, operator, sequencePairs] materializes only " <>
  "the requested current-path words from a graded physical endpoint binding and returns " <>
  "their four-segment GPL maps on one shared vector of boundary-data coefficients.";

EndpointConnectionWord::usage =
  "EndpointConnectionWord[path, firstWord, secondWord] is the inert Chen word " <>
  "multiplying an endpoint-to-interior boundary-coordinate map.";

Begin["`Private`"];

ClearAll[exactZeroQ, failure, leadingEpsilonOrder,
  exactAssociationLookup,
  independentEmbeddingRows, modeVector, endpointModeStatus,
  endpointBoundaryDataRecord, endpointResidueMatrix, reachableWordPairs,
  endpointDemandRowBasis, endpointDemandVisibilityRows,
  endpointDemandCoReachability, endpointModeOrderKey,
  endpointModeCoefficientData, endpointDemandOrderMatrices,
  exactIteratedIntegralCoefficientMatrix,
  requestedOutputIteratedIntegralCoefficientMatrix,
  boundaryDataRequirement, pruneBoundaryDataRequirements, endpointExactRowBasis,
  endpointSpecializeMatrix, endpointCurrentRowSpaces,
  endpointBasisProjectionData, endpointExpandTermColumns,
  endpointMergeBoundaryDataRequirements, endpointCoordinateKey,
  endpointBoundaryDataIDKey, endpointBoundaryDataID,
  endpointBoundaryAnalyticClassKey, endpointBoundaryAnalyticClass,
  endpointBoundaryEpsilonValuationKey, endpointBoundaryEpsilonValuation,
  endpointBoundaryCoefficient, endpointBoundaryCoefficientRecordsKey,
  endpointBoundaryCoefficientLabelsKey];

endpointBoundaryDataIDKey["BoundaryConstant"] := "BoundaryConstantID";
endpointBoundaryDataIDKey["BoundaryFunction"] := "BoundaryFunctionID";
endpointBoundaryAnalyticClassKey["BoundaryConstant"] :=
  "DeclaredBoundaryConstantAnalyticClass";
endpointBoundaryAnalyticClassKey["BoundaryFunction"] :=
  "DeclaredBoundaryFunctionClass";
endpointBoundaryEpsilonValuationKey["BoundaryConstant"] :=
  "BoundaryConstantEpsilonValuation";
endpointBoundaryEpsilonValuationKey["BoundaryFunction"] :=
  "BoundaryFunctionEpsilonValuation";
endpointBoundaryDataID[mode_Association] := With[
  {type = Lookup[mode, "BoundaryDataType", Missing["BoundaryDataType"]]},
  Lookup[mode, endpointBoundaryDataIDKey[type], Missing[endpointBoundaryDataIDKey[type]]]
];
endpointBoundaryAnalyticClass[mode_Association] := With[
  {type = Lookup[mode, "BoundaryDataType", Missing["BoundaryDataType"]]},
  Lookup[mode, endpointBoundaryAnalyticClassKey[type],
    Missing[endpointBoundaryAnalyticClassKey[type]]]
];
endpointBoundaryEpsilonValuation[mode_Association] := With[
  {type = Lookup[mode, "BoundaryDataType", Missing["BoundaryDataType"]]},
  Lookup[mode, endpointBoundaryEpsilonValuationKey[type],
    Missing[endpointBoundaryEpsilonValuationKey[type]]]
];
endpointBoundaryCoefficient["BoundaryConstant", id_, order_] :=
  FeynFacet`BoundaryConstantEpsilonCoefficient[id, order];
endpointBoundaryCoefficient["BoundaryFunction", id_, order_] :=
  FeynFacet`BoundaryFunctionEpsilonCoefficient[id, order];
endpointBoundaryCoefficientRecordsKey["BoundaryConstant"] :=
  "BoundaryConstantEpsilonCoefficientRecords";
endpointBoundaryCoefficientRecordsKey["BoundaryFunction"] :=
  "BoundaryFunctionEpsilonCoefficientRecords";
endpointBoundaryCoefficientLabelsKey["BoundaryConstant"] :=
  "BoundaryConstantEpsilonCoefficientLabels";
endpointBoundaryCoefficientLabelsKey["BoundaryFunction"] :=
  "BoundaryFunctionEpsilonCoefficientLabels";

exactZeroQ[x_] := TrueQ[x === 0] || TrueQ[PossibleZeroQ[x]];

(* Lookup treats a list-valued key as a list of separate keys.  Physical
   realization IDs are commonly compound labels such as {family, mode}, so retrieve them through
   Association Part instead. *)
exactAssociationLookup[association_Association, key_, default_: Missing[]] :=
  If[KeyExistsQ[association, key], association[[Key[key]]], default];

failure[tag_String, details_Association] :=
  Failure[tag, Join[<|"Status" -> tag|>, details]];

leadingEpsilonOrder[expression_, regulator_Symbol] := Module[
  {together = Together[expression], numerator, denominator},
  If[exactZeroQ[together], Return[Infinity]];
  {numerator, denominator} = NumeratorDenominator[together];
  Exponent[numerator, regulator, Min] - Exponent[denominator, regulator, Min]
];

(* The lexicographically first pivot rows define one stable left inverse of
   the automaton's final embedding.  It is a coordinate convention, not a
   claim that separate endpoint words lie in the embedding image. *)
independentEmbeddingRows[embedding_] := Module[
  {dense = Normal[embedding], reduced, rows, firstNonzero, square},
  reduced = RowReduce[Transpose[dense]];
  firstNonzero[row_List] := SelectFirst[Range[Length[row]],
    !exactZeroQ[row[[#]]] &, Missing["NoPivot"]];
  rows = DeleteCases[firstNonzero /@ reduced, _Missing];
  If[Length[rows] =!= Last[Dimensions[dense]],
    Return[failure["RankDeficientBoundaryEmbedding", <|
      "EmbeddingDimensions" -> Dimensions[dense]|>]]
  ];
  square = dense[[rows, All]];
  <|"Rows" -> rows, "LeftInverseOnRows" -> Inverse[square]|>
];

modeVector[mode_Association, dimension_Integer] := Module[
  {entries, vector, physicalToLocal},
  Which[
    ListQ[Lookup[mode, "CanonicalMode", Missing["Absent"]]],
      vector = Lookup[mode, "CanonicalMode"],
    ListQ[Lookup[mode, "CanonicalModeEntries", Missing["Absent"]]],
      entries = Lookup[mode, "CanonicalModeEntries"];
      vector = Normal@SparseArray[(#[[1]] -> #[[2]]) & /@ entries, dimension],
    True,
      Return[failure["MissingEndpointModeRealization", <|
        "FrobeniusModeID" -> Lookup[mode, "FrobeniusModeID", Missing["Absent"]]|>]]
  ];
  If[Length[vector] =!= dimension,
    Return@failure["EndpointModeDimensionMismatch", <|
      "FrobeniusModeID" -> Lookup[mode, "FrobeniusModeID", Missing["Absent"]],
      "ExpectedDimension" -> dimension, "ActualDimension" -> Length[vector]|>]
  ];
  physicalToLocal = Lookup[mode, "PhysicalToLocalMode", Automatic];
  Which[
    physicalToLocal === Automatic, vector,
    VectorQ[physicalToLocal] && Length[physicalToLocal] === dimension,
      physicalToLocal,
    MatrixQ[physicalToLocal] &&
        Dimensions[physicalToLocal] === {dimension, dimension},
      physicalToLocal . vector,
    True,
      failure["PhysicalToLocalModeInvalid", <|
        "FrobeniusModeID" -> Lookup[mode, "FrobeniusModeID", Missing["Absent"]],
        "ExpectedVectorLengthOrMatrixDimension" -> dimension|>]
  ]
];

endpointModeStatus[mode_Association] := Lookup[mode, "Status", Missing["Absent"]];

endpointBoundaryDataRecord[boundaryData_Association, boundaryDataID_] :=
  exactAssociationLookup[boundaryData, boundaryDataID,
    exactAssociationLookup[boundaryData, ToString[boundaryDataID], <||>]];

endpointResidueMatrix[kernels_Association, matrices_Association, variable_Symbol, endpoint_] :=
  Total[
    (Limit[(variable - endpoint) Lookup[kernels, #], variable -> endpoint] Lookup[matrices, #]) & /@
      Keys[kernels]
  ];

endpointDemandRowBasis[rows_List] := Module[{reduced},
  If[rows === {}, Return[{}]];
  reduced = RowReduce[rows];
  Select[reduced, AnyTrue[#, Not@*exactZeroQ] &]
];

endpointDemandVisibilityRows[pivotDemand_, pivotSlots_List,
    dimension_Integer, weight_Integer, boundaryCoefficientRecords_List,
    coefficientPositions_Association] := Module[
  {orders, activeOrders, coefficientPresentQ, rows, vector},
  orders = DeleteDuplicates[pivotSlots[[All, 1]]];
  coefficientPresentQ[id_, order_] := KeyExistsQ[coefficientPositions,
    endpointModeOrderKey[id, order]];
  activeOrders = Select[orders, Function[slotOrder,
    AnyTrue[boundaryCoefficientRecords, Function[coordinate,
      coefficientPresentQ[endpointBoundaryDataID[coordinate],
        slotOrder - Lookup[coordinate, "EpsilonOrder"] - weight]]]]];
  rows = Flatten[Table[
    vector = ConstantArray[0, dimension];
    Do[If[pivotSlots[[slot, 1]] === slotOrder,
      vector[[pivotSlots[[slot, 2]]]] += pivotDemand[[output, slot]]],
      {slot, Length[pivotSlots]}];
    If[AnyTrue[vector, Not@*exactZeroQ], {vector}, {}],
    {output, Length[pivotDemand]}, {slotOrder, activeOrders}], 2];
  endpointDemandRowBasis[rows]
];

endpointDemandCoReachability[visibility_Association,
    firstIndices_List, secondIndices_List, matrices_Association,
    maximumWeight_Integer] := Module[
  {first = <||>, second = <||>, future},
  Do[
    future = If[weight === maximumWeight, {},
      Flatten[Table[row . Lookup[matrices, index],
        {row, first[weight + 1]}, {index, firstIndices}], 1]];
    AssociateTo[first, weight -> endpointDemandRowBasis[
      Join[Lookup[visibility, weight, {}], future]]],
    {weight, maximumWeight, 0, -1}];
  Do[
    future = If[weight === maximumWeight, {},
      Flatten[Table[row . Lookup[matrices, index],
        {row, second[weight + 1]}, {index, secondIndices}], 1]];
    AssociateTo[second, weight -> endpointDemandRowBasis[
      Join[first[weight], future]]],
    {weight, maximumWeight, 0, -1}];
  <|"First" -> first, "Second" -> second|>
];

endpointModeOrderKey[id_, order_Integer] := HoldComplete[id, order];

endpointModeCoefficientData[modeVectors_Association, ids_List,
    regulator_Symbol, orders_List, dimension_Integer,
    boundaryDataType_String] := Module[
  {records, coefficientVector,
   dataIDKey = endpointBoundaryDataIDKey[boundaryDataType]},
  records = Flatten@Table[
    coefficientVector = Quiet@Check[
      (SeriesCoefficient[#, {regulator, 0, order}] & /@
        exactAssociationLookup[modeVectors, id]),
      $Failed];
    If[coefficientVector === $Failed || !VectorQ[coefficientVector] ||
        Length[coefficientVector] =!= dimension,
      Return@failure["EndpointCoefficientExtractionFailed", <|
        "FrobeniusModeID" -> id, "ModeEpsilonOrder" -> order|>]
    ];
    If[AnyTrue[coefficientVector, Not@*exactZeroQ],
      {<|dataIDKey -> id, "ModeEpsilonOrder" -> order,
        "Vector" -> (Together /@ coefficientVector)|>}, {}],
    {id, ids}, {order, orders}];
  <|
    "Records" -> records,
    "SeedMatrix" -> If[records === {}, ConstantArray[0, {dimension, 0}],
      Transpose[Lookup[records, "Vector"]]],
    "ColumnPositions" -> AssociationThread[
      (endpointModeOrderKey[Lookup[#, dataIDKey],
          Lookup[#, "ModeEpsilonOrder"]] & /@ records),
      Range[Length[records]]]
  |>
];

endpointDemandOrderMatrices[pivotDemand_, pivotSlots_List,
    dimension_Integer] := Association@Cases[
  Table[
    With[{order = currentOrder}, Module[{matrix},
      matrix = ConstantArray[0, {Length[pivotDemand], dimension}];
      Do[
        If[pivotSlots[[slot, 1]] === order,
          matrix[[All, pivotSlots[[slot, 2]]]] += pivotDemand[[All, slot]]],
        {slot, Length[pivotSlots]}];
      If[AnyTrue[Flatten[matrix], Not@*exactZeroQ],
        order -> SparseArray[matrix], Nothing]
    ]],
    {currentOrder, DeleteDuplicates[pivotSlots[[All, 1]]]}],
  _Rule];

reachableWordPairs[firstIndices_List, secondIndices_List,
    matrices_Association, seedMatrix_, maximumWeight_Integer,
    maximumWords_Integer, coReachability_Association] := Catch@Module[
  {secondLevel = {{{}, seedMatrix}}, nextSecond, firstLevel, nextFirst,
   result, count = 0, visited = 0, action, appendResult, nonzeroActionQ,
   relevantQ,
   secondState, firstState, index, secondWeight, firstWeight, harvested,
   firstPruned = 0, secondPruned = 0, firstBases, secondBases},
  nonzeroActionQ[current_] := AnyTrue[Flatten[current], Not@*exactZeroQ];
  firstBases = Lookup[coReachability, "First", <||>];
  secondBases = Lookup[coReachability, "Second", <||>];
  relevantQ[basis_, current_] := basis =!= {} &&
    AnyTrue[Flatten[basis . current], Not@*exactZeroQ];
  appendResult[currentPair_] := (
    count++;
    If[count > maximumWords,
      Throw@failure["EndpointConnectorWordBudgetExceeded", <|
        "ReachedWordCount" -> count,
        "MaximumConnectorWords" -> maximumWords,
        "FirstAlphabetSize" -> Length[firstIndices],
        "SecondAlphabetSize" -> Length[secondIndices],
        "MaximumConnectorWeight" -> maximumWeight,
        "EnumerationMethod" -> "SparseReachableStates"|>]];
    Sow[currentPair, "ReachableWord"]);
  harvested = Reap[Do[
    Do[
      firstLevel = {{{}, Last[secondState]}};
      Do[
        Scan[(visited++; appendResult[
          {First[#], First[secondState], Last[#]}]) &,
          firstLevel];
        If[firstWeight < maximumWeight - secondWeight,
          nextFirst = Flatten[Table[
            action = Lookup[matrices, index] . Last[firstState];
            If[nonzeroActionQ[action] && relevantQ[
                firstBases[firstWeight + secondWeight + 1], action],
              {{Prepend[First[firstState], index], action}},
              firstPruned++; {}],
            {firstState, firstLevel}, {index, firstIndices}], 2];
          firstLevel = nextFirst
        ],
        {firstWeight, 0, maximumWeight - secondWeight}],
      {secondState, secondLevel}];
    If[secondWeight < maximumWeight,
      nextSecond = Flatten[Table[
        action = Lookup[matrices, index] . Last[secondState];
        If[nonzeroActionQ[action] && relevantQ[
            secondBases[secondWeight + 1], action],
          {{Prepend[First[secondState], index], action}},
          secondPruned++; {}],
        {secondState, secondLevel}, {index, secondIndices}], 2];
      secondLevel = nextSecond
    ],
    {secondWeight, 0, maximumWeight}], "ReachableWord"][[2]];
  result = If[harvested === {}, {}, First[harvested]];
  <|"Words" -> result, "VisitedStates" -> visited,
    "FirstChildrenPruned" -> firstPruned,
    "SecondChildrenPruned" -> secondPruned|>
];

exactIteratedIntegralCoefficientMatrix[automaton_Association,
    firstPathSegmentLetterIndices_List,
    secondPathSegmentLetterIndices_List,
    includeFinalEmbedding_: True] := Module[
  {firstAlphabet, secondAlphabet, firstPositions, secondPositions, map},
  If[Length[firstPathSegmentLetterIndices] +
      Length[secondPathSegmentLetterIndices] >
      Lookup[automaton, "MaximumIteratedIntegralWeight", -1],
    Return[failure["LetterIndexSequencesExceedRequestedWeight", <|
      "FirstPathSegmentLetterIndices" -> firstPathSegmentLetterIndices,
      "SecondPathSegmentLetterIndices" ->
        secondPathSegmentLetterIndices|>]]
  ];
  firstAlphabet = Lookup[automaton,
    "FirstPathSegmentAlphabetLetterIndices", {}];
  secondAlphabet = Lookup[automaton,
    "SecondPathSegmentAlphabetLetterIndices", {}];
  firstPositions = FirstPosition[firstAlphabet, #, Missing["Unknown"]] & /@
    firstPathSegmentLetterIndices;
  secondPositions = FirstPosition[secondAlphabet, #, Missing["Unknown"]] & /@
    secondPathSegmentLetterIndices;
  If[AnyTrue[Join[firstPositions, secondPositions], MissingQ],
    Return[failure["IteratedIntegralIndexSequenceContainsUnknownLetterIndex", <|
      "FirstPathSegmentLetterIndices" -> firstPathSegmentLetterIndices,
      "SecondPathSegmentLetterIndices" ->
        secondPathSegmentLetterIndices|>]]
  ];
  map = Lookup[automaton, "InitialRequestedOutputMap", Missing["Absent"]];
  If[!MatrixQ[Normal[map]],
    Return[failure["ExactIteratedIntegralCoefficientOperatorIncomplete", <||>]]];
  Do[map = map . Lookup[automaton,
      "FirstPathSegmentOperatorMatrices"][[First[position]]],
    {position, firstPositions}];
  map = map . Lookup[automaton, "FirstPathSegmentBoundaryMap"];
  Do[map = map . Lookup[automaton,
      "SecondPathSegmentOperatorMatrices"][[First[position]]],
    {position, secondPositions}];
  If[TrueQ[includeFinalEmbedding],
    map . Lookup[automaton, "FinalBoundaryEmbedding"], map]
];

requestedOutputIteratedIntegralCoefficientMatrix[
    operator_Association, firstPathSegmentLetterIndices_List,
    secondPathSegmentLetterIndices_List] := Module[
  {representation, automaton},
  representation = Lookup[operator,
    "IteratedIntegralCoefficientRepresentation", Missing["Absent"]];
  If[representation =!=
      "IteratedIntegralCoefficientOperatorForRequestedOutputs",
    Return@failure["ExactIteratedIntegralCoefficientOperatorRequired", <|
      "IteratedIntegralCoefficientRepresentation" -> representation|>]
  ];
  automaton = Lookup[operator,
    "ExactIteratedIntegralCoefficientOperator", Missing["Absent"]];
  If[!AssociationQ[automaton] ||
      Lookup[automaton, "Status", None] =!=
        "IteratedIntegralCoefficientOperatorConstructed",
    failure["ExactIteratedIntegralCoefficientOperatorRequired", <||>],
    exactIteratedIntegralCoefficientMatrix[automaton,
      firstPathSegmentLetterIndices, secondPathSegmentLetterIndices]]
];

boundaryDataRequirement[family_, endpointSpec_, mode_, status_,
    coefficientRecords_List, outputs_List] := Module[
  {type = mode["BoundaryDataType"], idKey, classKey, labelsKey},
  idKey = endpointBoundaryDataIDKey[type];
  classKey = endpointBoundaryAnalyticClassKey[type];
  labelsKey = endpointBoundaryCoefficientLabelsKey[type];
  <|"BoundaryDataType" -> type,
    idKey -> endpointBoundaryDataID[mode],
    "FrobeniusModeID" -> Lookup[mode, "FrobeniusModeID", Missing["Absent"]],
    classKey -> endpointBoundaryAnalyticClass[mode],
    "DegenerateResidueEigenspaceBasis" ->
      Lookup[mode, "DegenerateResidueEigenspaceBasis", None],
    "Family" -> family,
    "PhysicalKinematicLimit" -> <|
      "Variable" -> Lookup[endpointSpec, "Variable", Missing["Absent"]],
      "LocalExpansionPoint" ->
        Lookup[endpointSpec, "LocalExpansionPoint", Missing["Absent"]],
      "FixedRules" -> Lookup[endpointSpec, "FixedRules", {}],
      "Stratum" -> Lookup[endpointSpec, "Stratum", Missing["Absent"]]|>,
    "FrobeniusMode" -> <|
      "LocalEigenvalue" -> Lookup[mode, "LocalEigenvalue", Missing["Absent"]],
      "GeneralizedLevel" -> Lookup[mode, "GeneralizedLevel", Missing["Absent"]],
      "Support" -> Lookup[mode, "Support", Missing["Absent"]]|>,
    labelsKey ->
      ({endpointBoundaryDataID[#], #["EpsilonOrder"]} & /@ coefficientRecords),
    "RequiredMasterIntegralCoefficients" -> outputs,
    "Status" -> status|>
];

pruneBoundaryDataRequirements[requirements_List, coordinates_List,
    usedColumns_List] := Module[
  {used = If[usedColumns === {}, {}, coordinates[[usedColumns]]]},
  requirements /. entry_Association :> Module[
    {type = entry["BoundaryDataType"], id, selected, labelsKey},
    id = Lookup[entry, endpointBoundaryDataIDKey[type], Missing["Absent"]];
    labelsKey = endpointBoundaryCoefficientLabelsKey[type];
    selected = Select[used, endpointBoundaryDataID[#] === id &];
    Join[entry, <|labelsKey ->
      ({endpointBoundaryDataID[#], #["EpsilonOrder"]} & /@ selected)|>]
  ]
];

Options[BuildEndpointAutomatonBoundaryAdapter] = {
  "MaximumConnectorWeight" -> Automatic,
  "MaximumConnectorWords" -> 200000,
  "BoundaryDataEpsilonOrderWindow" -> Automatic,
  "RequestedPathSegmentLetterIndexSequencePairs" -> {{{}, {}}},
  "PreparedRequestedOutputCoefficientMatrices" -> Automatic
};

BuildEndpointAutomatonBoundaryAdapter[
    transport_Association, modeMap_Association, boundaryData_: <||>,
    OptionsPattern[]] := Catch@Module[
  {automaton, wordRepresentation, path, variables, regulator, family,
   letters, residues, dimension,
   endpointSpec, endpointVariable, endpoint, fixedRules, firstVariable,
   secondVariable, firstBase, secondBase, fixedFirst, secondKernels,
   firstKernels, secondIndices, firstIndices, matrixAssociation,
   endpointResidue, modes, realizedModes, modeVectors, recordByID,
   knownZeroByID, statusByID, valuationByID, modeOrderByID,
   ambientSlots, embedding, pivotData, pivotRows, pivotSlots, pivotInverse,
   maximumWeight, maximumWords, boundaryDataEpsilonOrderWindow,
   boundaryCoefficientRecords, wordPairs, wordRecord, endpointTerms,
   activeColumns, boundaryDataRequirements,
   demandedOutputs, pathDescriptor, requestedWordCount,
   weight, coordinate, id, q, mode,
   endpointAction, status, term, active,
   localCoordinatePower, localCoordinateLeadingCoefficient,
   physicalEndpointRelation, formalModeIDs, seedMatrix,
   requiredConnectorWeight, realizationKey,
   demandedPivotColumns, demandedSlotMaximum, demandWordPairs,
   demandMaps, demandMapStack, demandWordRecords, baseRules,
   pivotDemand, visibility, coReachability, projectedMap, rowOffset,
   currentMap, propagatedModes, demandOrderMatrices, demandOrders, modeLimit,
   coefficientOrders, coefficientData, coefficientPositions,
   coefficientPosition, contribution, outputColumn, boundaryDataType,
   dataIDKey, coefficientRecordsKey, coefficientLabelsKey,
   preparedRequestedOutputCoefficientMatrices},

  If[! TrueQ[
      FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
        transport]],
    Throw@failure[
      "IteratedIntegralCoefficientOperatorForRequestedOutputsRequired",
      <||>]
  ];
  wordRepresentation = Lookup[transport,
    "IteratedIntegralCoefficientRepresentation", Missing["Absent"]];
  If[wordRepresentation =!=
      "IteratedIntegralCoefficientOperatorForRequestedOutputs",
    Throw@failure["ExactIteratedIntegralCoefficientOperatorRequired", <|
      "IteratedIntegralCoefficientRepresentation" ->
        wordRepresentation|>]
  ];
  automaton = Lookup[transport,
    "ExactIteratedIntegralCoefficientOperator", Missing["Absent"]];
  If[!AssociationQ[automaton] ||
      Lookup[automaton, "Status", None] =!=
        "IteratedIntegralCoefficientOperatorConstructed",
    Throw@failure["ExactIteratedIntegralCoefficientOperatorRequired", <||>]
  ];
  path = Lookup[transport,
    "RegularBasePointAndFirstPathParameterScale", Missing["Absent"]];
  If[!AssociationQ[path], Throw@failure["MissingTransportPath", <||>]];
  variables = Lookup[transport, "CoefficientVariables", Missing["Absent"]];
  If[!MatchQ[variables, {_Symbol, _Symbol}],
    Throw@failure["UnsupportedCoefficientVariables", <|
      "CoefficientVariables" -> variables|>]
  ];
  {firstVariable, secondVariable} = variables;
  regulator = Lookup[transport, "DimensionalRegulator", Missing["Absent"]];
  If[!MatchQ[regulator, _Symbol],
    Throw@failure["MissingDimensionalRegulator", <||>]];
  family = Lookup[transport, "Family", Lookup[modeMap, "Family", Missing["Absent"]]];
  firstBase = Lookup[path, "FirstBase", Missing["Absent"]];
  secondBase = Lookup[path, "SecondBase", Missing["Absent"]];
  If[MemberQ[{firstBase, secondBase}, _Missing],
    Throw@failure["MissingTransportBasePoint", <|"Path" -> path|>]
  ];

  boundaryDataType = Lookup[modeMap, "BoundaryDataType", Missing["Absent"]];
  If[! MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType],
    Throw@failure["BoundaryDataTypeRequired", <||>]];
  If[boundaryDataType === "BoundaryFunction",
    Throw@failure["BoundaryFunctionEndpointTransportNotImplemented", <|
      "BoundaryDomain" -> Lookup[modeMap, "BoundaryDomain", Missing[]],
      "Reason" -> "the endpoint construction has no representation for the tangential arguments of a boundary function"|>]];
  dataIDKey = endpointBoundaryDataIDKey[boundaryDataType];
  coefficientRecordsKey = endpointBoundaryCoefficientRecordsKey[boundaryDataType];
  coefficientLabelsKey = endpointBoundaryCoefficientLabelsKey[boundaryDataType];
  endpointSpec = Lookup[modeMap, "LocalExpansionSpecification", Missing["Absent"]];
  If[!AssociationQ[endpointSpec],
    Throw@failure["MissingEndpointSpecification", <|"Family" -> family|>]
  ];
  physicalEndpointRelation = Lookup[modeMap, "PhysicalEndpointRelation", <||>];
  modeLimit = Lookup[modeMap, "PhysicalKinematicLimit", <||>];
  endpointSpec = Join[<|
      "Stratum" -> If[AssociationQ[modeLimit],
        Lookup[modeLimit, "Stratum",
          Lookup[physicalEndpointRelation, "Stratum", Missing["Absent"]]],
        modeLimit],
      "LocalCoordinatePower" -> Lookup[physicalEndpointRelation, "LocalPower", 1],
      "LocalCoordinateLeadingCoefficient" ->
        Lookup[physicalEndpointRelation, "LeadingCoefficient", 1]|>,
    endpointSpec];
  endpointVariable = Lookup[endpointSpec, "Variable", Missing["Absent"]];
  endpoint = Lookup[endpointSpec, "LocalExpansionPoint", Missing["Absent"]];
  fixedRules = Lookup[endpointSpec, "FixedRules", {}];
  localCoordinatePower = Lookup[endpointSpec, "LocalCoordinatePower", 1];
  localCoordinateLeadingCoefficient =
    Lookup[endpointSpec, "LocalCoordinateLeadingCoefficient", 1];
  If[endpointVariable =!= secondVariable,
    Throw@failure["EndpointPathMismatch", <|
      "EndpointVariable" -> endpointVariable, "TransportSecondVariable" -> secondVariable|>]
  ];
  fixedFirst = firstVariable /. fixedRules;
  If[!FreeQ[fixedFirst, firstVariable],
    Throw@failure["MissingFirstSegmentMap", <|
      "Reason" -> "Endpoint specification does not fix the first path variable",
      "FirstVariable" -> firstVariable, "FixedRules" -> fixedRules|>]
  ];

  letters = Lookup[transport, "Letters", Missing["Absent"]];
  residues = Lookup[transport, "ConstantResidueMatrices", Missing["Absent"]];
  If[!ListQ[letters] || !ListQ[residues] || Length[letters] =!= Length[residues] ||
      letters === {} || !And @@ (MatrixQ /@ residues),
    Throw@failure["MissingFirstSegmentMap", <|
      "Reason" -> "Accepted dlog letters and residue matrices are required"|>]
  ];
  dimension = First@Dimensions[First[residues]];
  If[!And @@ (Dimensions[#] === {dimension, dimension} & /@ residues),
    Throw@failure["InvalidConstantResidueMatrices", <||>]
  ];
  matrixAssociation = AssociationThread[Range[Length[residues]], residues];
  secondKernels = Association@Cases[
    MapIndexed[
      Function[{letter, index},
        With[{kernel = Together[(D[letter, secondVariable]/letter) /. firstVariable -> fixedFirst]},
          If[exactZeroQ[kernel], Nothing, First[index] -> kernel]]],
      letters],
    _Rule];
  firstKernels = Association@Cases[
    MapIndexed[
      Function[{letter, index},
        With[{kernel = Together[(D[letter, firstVariable]/letter) /. secondVariable -> secondBase]},
          If[exactZeroQ[kernel], Nothing, First[index] -> kernel]]],
      letters],
    _Rule];
  secondIndices = Keys[secondKernels];
  firstIndices = Keys[firstKernels];
  If[secondIndices === {} || firstIndices === {},
    Throw@failure["MissingFirstSegmentMap", <|
      "Reason" -> "One endpoint-to-interior segment has an empty dlog alphabet",
      "FirstAlphabetSize" -> Length[firstIndices],
      "SecondAlphabetSize" -> Length[secondIndices]|>]
  ];

  endpointResidue = Quiet@Check[
    endpointResidueMatrix[secondKernels, matrixAssociation, secondVariable, endpoint],
    $Failed];
  If[endpointResidue === $Failed || !MatrixQ[endpointResidue],
    Throw@failure["EndpointResidueUnavailable", <|
      "Variable" -> secondVariable, "Endpoint" -> endpoint|>]
  ];

  modes = Lookup[modeMap, "FrobeniusModes", Missing["Absent"]];
  If[!ListQ[modes] || modes === {},
    Throw@failure["MissingEndpointModeRealization", <|"Family" -> family|>]
  ];
  realizedModes = Select[modes,
    MemberQ[{"Exact", "BoundaryAsymptoticsMatchedToFrobeniusMode"},
      endpointModeStatus[#]] &];
  If[realizedModes === {},
    Throw@failure["MissingEndpointModeRealization", <|
      "Family" -> family, "ModeStatuses" -> (endpointModeStatus /@ modes)|>]
  ];
  If[AnyTrue[realizedModes,
      !exactZeroQ[Lookup[#, "LocalEigenvalue", Missing["Absent"]]] ||
      Lookup[#, "GeneralizedLevel", Missing["Absent"]] =!= 0 &],
    Throw@failure["TangentialLogModeRequired", <|
      "Reason" -> "Only ordinary zero modes can be passed to the interior automaton",
      dataIDKey -> (endpointBoundaryDataID /@ realizedModes),
      (* Round 10 (T): values are inserted; a HoldForm over Module locals
         wrote FeynFacetCampaign`PhysicalBoundary`Private`...$NNN symbols
         into 39 of 40 stored endpoint records *)
      "RequiredLocalNormalization" -> With[{coefficient =
          localCoordinateLeadingCoefficient, power = localCoordinatePower,
          variable = endpointVariable, reg = regulator},
        HoldForm[Exp[reg Log[coefficient] Subscript["R", variable]/power]]],
      "LogBranchMustBeSpecified" ->
        !exactZeroQ[localCoordinateLeadingCoefficient - 1]|>]
  ];
  (* Every realized mode carries its degenerate-residue-eigenspace basis
     record (None for an ordinary mode). *)
  realizedModes = Map[Join[#, <|"DegenerateResidueEigenspaceBasis" ->
      FeynFacet`DegenerateResidueEigenspaceBasis[#, realizedModes]|>] &,
    realizedModes];
  modeVectors = Association@Map[
    Function[currentMode,
      With[{currentVector = modeVector[currentMode, dimension]},
        If[FailureQ[currentVector], Throw[currentVector]];
        endpointBoundaryDataID[currentMode] -> currentVector]],
    realizedModes];
  If[MemberQ[Keys[modeVectors], _Missing],
    Throw@failure["MissingEndpointModeRealization", <|
      "Reason" -> "Every mode needs the boundary-domain-specific identifier"|>]
  ];
  Do[
    endpointAction = Together[endpointResidue . exactAssociationLookup[
      modeVectors, endpointBoundaryDataID[mode]]];
    If[!And @@ (exactZeroQ /@ endpointAction),
      Throw@failure["EndpointModeNotTangentiallyRegular", <|
        dataIDKey -> endpointBoundaryDataID[mode],
        "Variable" -> secondVariable, "Endpoint" -> endpoint|>]
    ],
    {mode, realizedModes}];

  recordByID = Association@Table[
    endpointBoundaryDataID[mode] -> endpointBoundaryDataRecord[
      If[AssociationQ[boundaryData], boundaryData, <||>],
      endpointBoundaryDataID[mode]],
    {mode, realizedModes}];
  knownZeroByID = Association@Table[
    id -> (exactZeroQ[Lookup[SelectFirst[realizedModes,
          endpointBoundaryDataID[#] === id &], "KnownCoefficient", Missing["Absent"]]] ||
      MemberQ[{"KnownZero", "ExactZero"}, Lookup[
        exactAssociationLookup[recordByID, id], "Status", None]]),
    {id, Keys[modeVectors]}];
  statusByID = Association@Table[
    id -> If[TrueQ@exactAssociationLookup[knownZeroByID, id],
      "KnownZero", "Unevaluated"],
    {id, Keys[modeVectors]}];
  valuationByID = Association@Table[
    id -> Lookup[exactAssociationLookup[recordByID, id], "EpsilonValuation",
      endpointBoundaryEpsilonValuation[
        SelectFirst[realizedModes, endpointBoundaryDataID[#] === id &]]],
    {id, Keys[modeVectors]}];
  If[!And @@ (IntegerQ /@ Values[valuationByID]),
    Throw@failure["MissingBoundaryDataEpsilonValuation", <|
      "Valuations" -> valuationByID|>]
  ];
  modeOrderByID = Association@Table[
    id -> Min[leadingEpsilonOrder[#, regulator] & /@
      exactAssociationLookup[modeVectors, id]],
    {id, Keys[modeVectors]}];

  ambientSlots = Lookup[transport, "BoundaryAmbientSlots", Missing["Absent"]];
  (* Endpoint modes live in the ambient Laurent-slot space at the interior
     base.  With a MovingNullspaceBasis, FinalBoundaryEmbedding is only the
     later square boundary-coordinate map; the ambient-to-boundary embedding
     is BoundaryBaseEmbedding.  In the AmbientSpaceWithBasePointConstraints
     route these two maps coincide in shape. *)
  embedding = Lookup[transport, "BoundaryBaseEmbedding", Missing["Absent"]];
  If[MissingQ[embedding] && AssociationQ[automaton],
    embedding = Lookup[automaton, "FinalBoundaryEmbedding", Missing["Absent"]]];
  If[!ListQ[ambientSlots] || !MatrixQ[Normal[embedding]] ||
      Length[ambientSlots] =!= First[Dimensions[Normal[embedding]]],
    Throw@failure["BoundarySlotEmbeddingMismatch", <|
      "BoundarySlotCount" -> If[ListQ[ambientSlots], Length[ambientSlots], Missing["Absent"]],
      "EmbeddingDimensions" -> If[MatrixQ[Normal[embedding]], Dimensions[Normal[embedding]],
        Missing["Absent"]]|>]
  ];
  pivotData = independentEmbeddingRows[embedding];
  If[FailureQ[pivotData], Throw[pivotData]];
  pivotRows = Lookup[pivotData, "Rows"];
  pivotSlots = ambientSlots[[pivotRows]];
  pivotInverse = Lookup[pivotData, "LeftInverseOnRows"];
  boundaryDataEpsilonOrderWindow =
    OptionValue["BoundaryDataEpsilonOrderWindow"];
  If[boundaryDataEpsilonOrderWindow === Automatic,
    boundaryDataEpsilonOrderWindow = {
      Min[Values[valuationByID]],
      Max[ambientSlots[[All, 1]]] - Min[Cases[Values[modeOrderByID], _Integer]]
    }];
  If[!MatchQ[boundaryDataEpsilonOrderWindow, {_Integer, _Integer}] ||
      First[boundaryDataEpsilonOrderWindow] >
        Last[boundaryDataEpsilonOrderWindow],
    Throw@failure["InvalidBoundaryDataEpsilonOrderWindow", <|
      "BoundaryDataEpsilonOrderWindow" -> boundaryDataEpsilonOrderWindow|>]
  ];
  boundaryCoefficientRecords = Flatten@Table[
    If[TrueQ@exactAssociationLookup[knownZeroByID, id], {},
      realizationKey = Lookup[exactAssociationLookup[recordByID, id],
        "RealizationKey",
        If[TrueQ@Lookup[exactAssociationLookup[recordByID, id],
            "ClassIdentityExact", False], id,
          If[MatchQ[id, {family, __}], id, {family, id}]]];
      mode = SelectFirst[realizedModes, endpointBoundaryDataID[#] === id &];
      Table[<|"BoundaryDataType" -> boundaryDataType,
        dataIDKey -> id,
        "FrobeniusModeID" -> Lookup[mode, "FrobeniusModeID", Missing["Absent"]],
        "RealizationKey" -> realizationKey,
        "EpsilonOrder" -> q,
        "Coefficient" -> endpointBoundaryCoefficient[
          boundaryDataType, realizationKey, q],
        "DegenerateResidueEigenspaceBasis" ->
          Lookup[mode, "DegenerateResidueEigenspaceBasis", None],
        "Status" -> exactAssociationLookup[statusByID, id]|>,
        {q, Max[First[boundaryDataEpsilonOrderWindow],
          exactAssociationLookup[valuationByID, id]],
          Last[boundaryDataEpsilonOrderWindow]}]],
    {id, Keys[modeVectors]}];
  formalModeIDs = Select[Keys[modeVectors],
    ! TrueQ@exactAssociationLookup[knownZeroByID, #] &];
  demandWordPairs =
    OptionValue["RequestedPathSegmentLetterIndexSequencePairs"];
  If[!ListQ[demandWordPairs] || demandWordPairs === {} ||
      !AllTrue[demandWordPairs, MatchQ[#, {_List, _List}] &],
    Throw@failure["InvalidRequestedPathSegmentLetterIndexSequencePairs", <|
      "RequestedPathSegmentLetterIndexSequencePairs" ->
        demandWordPairs|>]
  ];
  baseRules = Lookup[transport, "BoundaryBasePoint",
    {firstVariable -> firstBase, secondVariable -> secondBase}];
  preparedRequestedOutputCoefficientMatrices =
    OptionValue["PreparedRequestedOutputCoefficientMatrices"];
  demandMaps = If[
    preparedRequestedOutputCoefficientMatrices === Automatic,
    Table[
      currentMap = Quiet@Check[
        requestedOutputIteratedIntegralCoefficientMatrix[
          transport, First[pair], Last[pair]], $Failed];
      If[currentMap === $Failed || FailureQ[currentMap] ||
          !MatrixQ[Normal[currentMap]],
        Throw@failure["IteratedIntegralCoefficientMatrixUnavailable", <|
          "CurrentPathFirstSegmentLetterIndices" -> First[pair],
          "CurrentPathSecondSegmentLetterIndices" -> Last[pair],
          "IteratedIntegralCoefficientRepresentation" ->
            wordRepresentation,
          "ProviderResult" -> currentMap|>]
      ];
      Together[Normal[currentMap] /. baseRules],
      {pair, demandWordPairs}],
    If[! ListQ[preparedRequestedOutputCoefficientMatrices] ||
        Length[preparedRequestedOutputCoefficientMatrices] =!=
          Length[demandWordPairs] ||
        ! AllTrue[preparedRequestedOutputCoefficientMatrices,
          MatrixQ[Normal[#]] &],
      Throw@failure[
        "PreparedRequestedOutputCoefficientMatricesNotWellFormed", <|
          "RequestedPathSegmentLetterIndexSequencePairCount" ->
            Length[demandWordPairs]|>]
    ];
    Together[Normal[#] /. baseRules] & /@
      preparedRequestedOutputCoefficientMatrices
  ];
  If[Length[DeleteDuplicates[Last /@ (Dimensions /@ demandMaps)]] =!= 1 ||
      First[Last /@ (Dimensions /@ demandMaps)] =!= Length[pivotRows],
    Throw@failure["EndpointDemandMapDimensionMismatch", <|
      "DemandMapDimensions" -> Dimensions /@ demandMaps,
      "BoundaryCoordinateCount" -> Length[pivotRows]|>]
  ];
  demandMapStack = Join @@ demandMaps;
  rowOffset = 0;
  demandWordRecords = MapThread[Function[{pair, map},
    With[{rows = rowOffset + Range[Length[map]]},
      rowOffset += Length[map];
      <|"CurrentPathFirstSegmentLetterIndices" -> First[pair],
        "CurrentPathSecondSegmentLetterIndices" -> Last[pair],
        "RowRange" -> rows|>]],
    {demandWordPairs, demandMaps}];
  pivotDemand = Together[demandMapStack . pivotInverse];
  demandedPivotColumns = Sort@DeleteDuplicates@Cases[
    First /@ ArrayRules[SparseArray[pivotDemand]],
    {_, column_Integer} :> column];
  demandedPivotColumns = Select[demandedPivotColumns,
    1 <= # <= Length[pivotSlots] &];
  demandedSlotMaximum = If[demandedPivotColumns === {},
    Max[pivotSlots[[All, 1]]],
    Max[pivotSlots[[demandedPivotColumns, 1]]]];
  requiredConnectorWeight = If[boundaryCoefficientRecords === {}, 0,
    Max[0, Max@Table[
      id = endpointBoundaryDataID[coordinate];
      q = Lookup[coordinate, "EpsilonOrder"];
      demandedSlotMaximum - q - exactAssociationLookup[modeOrderByID, id],
      {coordinate, boundaryCoefficientRecords}]]];
  maximumWeight = OptionValue["MaximumConnectorWeight"];
  If[maximumWeight === Automatic, maximumWeight = requiredConnectorWeight];
  maximumWords = OptionValue["MaximumConnectorWords"];
  If[!IntegerQ[maximumWeight] || maximumWeight < 0 ||
      !IntegerQ[maximumWords] || maximumWords < 1,
    Throw@failure["InvalidConnectorWordBudget", <|
      "MaximumConnectorWeight" -> maximumWeight,
      "MaximumConnectorWords" -> maximumWords|>]
  ];
  If[maximumWeight < requiredConnectorWeight,
    Throw@failure["EndpointConnectorDepthInsufficient", <|
      "MaximumConnectorWeight" -> maximumWeight,
      "RequiredConnectorWeight" -> requiredConnectorWeight,
      "Reason" -> "The requested boundary-data and observable orders need higher endpoint words"|>]
  ];
  demandOrderMatrices = endpointDemandOrderMatrices[
    pivotDemand, pivotSlots, dimension];
  demandOrders = Keys[demandOrderMatrices];
  coefficientOrders = Sort@DeleteDuplicates@Flatten@Table[
    order - Lookup[coordinate, "EpsilonOrder"] - weight,
    {order, demandOrders}, {coordinate, boundaryCoefficientRecords},
    {weight, 0, maximumWeight}];
  coefficientData = endpointModeCoefficientData[modeVectors,
    formalModeIDs, regulator, coefficientOrders, dimension,
    boundaryDataType];
  If[FailureQ[coefficientData], Throw[coefficientData]];
  seedMatrix = Lookup[coefficientData, "SeedMatrix"];
  coefficientPositions = Lookup[coefficientData, "ColumnPositions"];
  visibility = Association@Table[weight ->
    endpointDemandVisibilityRows[pivotDemand, pivotSlots, dimension,
      weight, boundaryCoefficientRecords, coefficientPositions],
    {weight, 0, maximumWeight}];
  coReachability = endpointDemandCoReachability[visibility,
    firstIndices, secondIndices, matrixAssociation, maximumWeight];
  wordRecord = If[formalModeIDs === {},
    <|"Words" -> {{{}, {}, seedMatrix}}, "VisitedStates" -> 1,
      "FirstChildrenPruned" -> 0, "SecondChildrenPruned" -> 0|>,
    reachableWordPairs[firstIndices, secondIndices, matrixAssociation,
      seedMatrix, maximumWeight, maximumWords, coReachability]];
  If[FailureQ[wordRecord], Throw[wordRecord]];
  wordPairs = wordRecord["Words"];
  requestedWordCount = Length[wordPairs];

  endpointTerms = Reap[
    Do[
      weight = Length[term[[1]]] + Length[term[[2]]];
      propagatedModes = term[[3]];
      projectedMap = If[boundaryCoefficientRecords === {},
        ConstantArray[0, {Length[demandMapStack], 0}],
        Transpose@Table[
        coordinate = boundaryCoefficientRecords[[coordinateColumn]];
        id = endpointBoundaryDataID[coordinate];
        q = Lookup[coordinate, "EpsilonOrder"];
        outputColumn = ConstantArray[0, Length[demandMapStack]];
        Do[
          coefficientPosition = Lookup[coefficientPositions,
            endpointModeOrderKey[id, order - q - weight], Missing["Zero"]];
          If[!MissingQ[coefficientPosition],
            contribution = Lookup[demandOrderMatrices, order] .
              propagatedModes[[All, coefficientPosition]];
            outputColumn += contribution],
          {order, demandOrders}];
        Together[outputColumn],
        {coordinateColumn, Length[boundaryCoefficientRecords]}]];
      If[Length[boundaryCoefficientRecords] > 0 &&
          AnyTrue[Flatten[projectedMap], Not@*exactZeroQ],
        Sow[<|
          "BoundaryPathFirstSegmentLetterIndices" -> term[[1]],
          "BoundaryPathSecondSegmentLetterIndices" -> term[[2]],
          "DemandProjectedMap" -> SparseArray[projectedMap]|>]
      ],
      {term, wordPairs}]
    ][[2]];
  endpointTerms = If[endpointTerms === {}, {}, First[endpointTerms]];
  activeColumns = Sort@DeleteDuplicates@Flatten[
    Map[
      Function[currentTerm,
        active = DeleteDuplicates@Cases[
          First /@ ArrayRules[Lookup[currentTerm, "DemandProjectedMap"]],
          {_, column_Integer} :> column];
        Select[active, 1 <= # <= Length[boundaryCoefficientRecords] &]],
      endpointTerms]];
  If[activeColumns =!= Range[Length[boundaryCoefficientRecords]],
    endpointTerms = endpointTerms /. currentTerm_Association :>
      Join[currentTerm, <|"DemandProjectedMap" ->
        Lookup[currentTerm, "DemandProjectedMap"][[All, activeColumns]]|>];
    boundaryCoefficientRecords = If[activeColumns === {}, {},
      boundaryCoefficientRecords[[activeColumns]]]
  ];

  demandedOutputs = Lookup[transport,
    "RequestedMasterIntegralEpsilonOrderAndRowPairs", {}];
  boundaryDataRequirements = Table[
    id = endpointBoundaryDataID[mode];
    status = exactAssociationLookup[statusByID, id];
    boundaryDataRequirement[family, endpointSpec, mode, status,
      Select[boundaryCoefficientRecords,
        endpointBoundaryDataID[#] === id &], demandedOutputs],
    {mode, realizedModes}];
  pathDescriptor = <|
    "Endpoint" -> <|"Variables" -> variables,
      "Point" -> {firstVariable -> fixedFirst, secondVariable -> endpoint}|>,
    "InteriorBase" -> <|"Variables" -> variables,
      "Point" -> {firstVariable -> firstBase, secondVariable -> secondBase}|>,
    "Segments" -> {
      <|"Role" -> "EndpointSecond", "Variable" -> secondVariable,
        "Base" -> endpoint, "Target" -> secondBase,
        "FixedRules" -> {firstVariable -> fixedFirst},
        "BoundaryPathSecondSegmentAlphabetLetterIndices" ->
          secondIndices, "DLogKernels" -> secondKernels|>,
      <|"Role" -> "EndpointFirst", "Variable" -> firstVariable,
        "Base" -> fixedFirst, "Target" -> firstBase,
        "FixedRules" -> {secondVariable -> secondBase},
        "BoundaryPathFirstSegmentAlphabetLetterIndices" ->
          firstIndices, "DLogKernels" -> firstKernels|>
    },
    "MultiplicationOrder" ->
      "BoundaryPathFirstSegment.BoundaryPathSecondSegment",
    "BoundaryPrescription" -> "ZeroResidueModeTangential",
    "LocalCoordinateNormalization" -> <|
      "Power" -> localCoordinatePower,
      "LeadingCoefficient" -> localCoordinateLeadingCoefficient,
      "ActionOnAcceptedModes" -> "IdentityBecauseEndpointResidueAnnihilatesModes",
      (* Round 10 (T): values inserted, see the same fix above *)
      "NontrivialModesRequire" -> With[{coefficient =
          localCoordinateLeadingCoefficient, power = localCoordinatePower,
          variable = endpointVariable, reg = regulator},
        HoldForm[Exp[reg Log[coefficient] Subscript["R", variable]/power]]]|>
  |>;

  <|
    "Status" -> "EndpointAutomatonBoundaryAdapterBuilt",
    "Family" -> family,
    "BoundaryDataType" -> boundaryDataType,
    "IteratedIntegralCoefficientMatrixProvider" -> wordRepresentation,
    "DimensionalRegulator" -> regulator,
    "EndpointModeMapStatus" -> Lookup[modeMap, "Status", Missing["Absent"]],
    "Path" -> pathDescriptor,
    "AutomatonBoundaryDimension" -> Last[Dimensions[Normal[embedding]]],
    "BoundaryAmbientSlots" -> ambientSlots,
    "BoundaryCoordinateConvention" -> <|
      "EmbeddingPivotRows" -> pivotRows,
      "Definition" -> "LexicographicallyFirstExactLeftInverse",
      "Projection" ->
        "OnlyPreparedPathSegmentLetterIndexSequencesAtInteriorBase"|>,
    "DemandVisibleAmbientSlotMaximum" -> demandedSlotMaximum,
    "PreparedPathSegmentLetterIndexSequencePairs" -> demandWordPairs,
    "PreparedPathSegmentLetterIndexSequenceRecords" -> demandWordRecords,
    coefficientRecordsKey -> boundaryCoefficientRecords,
    coefficientLabelsKey ->
      ({endpointBoundaryDataID[#], #["EpsilonOrder"]} & /@
        boundaryCoefficientRecords),
    "BoundaryPathIteratedIntegralCoefficientMatrixTerms" -> endpointTerms,
    "FormalBoundaryConvention" ->
      "Sum[EndpointConnectionWord[Path, firstSegment, secondSegment] CoefficientMatrix . BoundaryDataEpsilonCoefficientVector]",
    "MaximumConnectorWeight" -> maximumWeight,
    "RequiredConnectorWeight" -> requiredConnectorWeight,
    "ConnectorDepthComplete" -> True,
    "AggregateBoundaryImageCondition" ->
      "AppliesAfterTheCompleteBoundaryPathSumNotToIndividualSequences",
    "EnumeratedBoundaryPathLetterIndexSequencePairCount" ->
      requestedWordCount,
    "RetainedBoundaryPathCoefficientMatrixTermCount" ->
      Length[endpointTerms],
    "VisitedConnectorStateCount" -> wordRecord["VisitedStates"],
    "ConnectorEnumerationMethod" -> "DemandDualCoReachableSparseStates",
    "EndpointCoefficientAssemblyMethod" ->
      "PrecomputedModeEpsilonCoefficientsProjectedBeforeMaterialization",
    "PrunedConnectorChildCount" ->
      wordRecord["FirstChildrenPruned"] +
        wordRecord["SecondChildrenPruned"],
    "BoundaryDataRequirements" -> boundaryDataRequirements
  |>
];

ComposeEndpointAutomatonBoundaryCoefficientMaps[
    adapter_Association, transport_Association, wordPairs_List] := Catch@Module[
  {wordRepresentation, endpointTerms, boundaryCoefficientRecords, outputTerms,
   pair, endpointTerm, map, usedColumns, boundaryDataRequirements, family,
   preparedRecords, prepared, rowRange, boundaryDataType,
   coefficientRecordsKey, coefficientLabelsKey},
  If[Lookup[adapter, "Status", Missing["Absent"]] =!=
      "EndpointAutomatonBoundaryAdapterBuilt",
    Throw@failure["EndpointBoundaryAdapterRequired", <||>]
  ];
  If[! TrueQ[
      FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
        transport]],
    Throw@failure[
      "IteratedIntegralCoefficientOperatorForRequestedOutputsRequired",
      <||>]
  ];
  wordRepresentation = Lookup[transport,
    "IteratedIntegralCoefficientRepresentation", Missing["Absent"]];
  If[wordRepresentation =!=
        "IteratedIntegralCoefficientOperatorForRequestedOutputs" ||
      Lookup[adapter, "IteratedIntegralCoefficientMatrixProvider",
          Missing["Absent"]] =!=
        wordRepresentation,
    Throw@failure["IteratedIntegralCoefficientMatrixProviderMismatch", <|
      "AdapterProvider" -> Lookup[adapter,
        "IteratedIntegralCoefficientMatrixProvider", Missing["Absent"]],
      "OperatorProvider" -> wordRepresentation|>]
  ];
  family = Lookup[transport, "Family", Missing["Absent"]];
  If[family =!= Lookup[adapter, "Family", Missing["Absent"]],
    Throw@failure["EndpointAdapterFamilyMismatch", <|
      "AdapterFamily" -> Lookup[adapter, "Family", Missing["Absent"]],
      "TransportFamily" -> family|>]
  ];
  If[!And @@ (MatchQ[#, {_List, _List}] & /@ wordPairs),
    Throw@failure["InvalidAutomatonWordRequest", <||>]
  ];
  boundaryDataType = Lookup[adapter, "BoundaryDataType", Missing["Absent"]];
  If[! MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType],
    Throw@failure["BoundaryDataTypeRequired", <||>]];
  coefficientRecordsKey = endpointBoundaryCoefficientRecordsKey[boundaryDataType];
  coefficientLabelsKey = endpointBoundaryCoefficientLabelsKey[boundaryDataType];
  endpointTerms = Lookup[adapter,
    "BoundaryPathIteratedIntegralCoefficientMatrixTerms", {}];
  boundaryCoefficientRecords = Lookup[adapter, coefficientRecordsKey, {}];
  preparedRecords = Lookup[adapter,
    "PreparedPathSegmentLetterIndexSequenceRecords", {}];
  outputTerms = Reap[
    Do[
      prepared = SelectFirst[preparedRecords,
        Lookup[#, "CurrentPathFirstSegmentLetterIndices",
            Missing["Absent"]] === First[pair] &&
          Lookup[#, "CurrentPathSecondSegmentLetterIndices",
            Missing["Absent"]] === Last[pair] &,
        Missing["NotPrepared"]];
      If[MissingQ[prepared],
        Throw@failure["EndpointDemandWordNotPrepared", <|
          "CurrentPathFirstSegmentLetterIndices" -> First[pair],
          "CurrentPathSecondSegmentLetterIndices" -> Last[pair],
          "PreparedPathSegmentLetterIndexSequencePairs" ->
            Lookup[adapter,
              "PreparedPathSegmentLetterIndexSequencePairs", {}]|>]
      ];
      rowRange = Lookup[prepared, "RowRange"];
      Do[
        map = Lookup[endpointTerm, "DemandProjectedMap"][[rowRange, All]];
        If[AnyTrue[Flatten[Normal[map]], Not@*exactZeroQ],
          Sow[<|
            "CurrentPathFirstSegmentLetterIndices" -> First[pair],
            "CurrentPathSecondSegmentLetterIndices" -> Last[pair],
            "BoundaryPathFirstSegmentLetterIndices" -> Lookup[
              endpointTerm,
              "BoundaryPathFirstSegmentLetterIndices"],
            "BoundaryPathSecondSegmentLetterIndices" -> Lookup[
              endpointTerm,
              "BoundaryPathSecondSegmentLetterIndices"],
            "IteratedIntegralCoefficientMatrix" -> SparseArray[map]|>]
        ],
        {endpointTerm, endpointTerms}],
      {pair, wordPairs}]
    ][[2]];
  outputTerms = If[outputTerms === {}, {}, First[outputTerms]];
  usedColumns = Sort@DeleteDuplicates@Flatten[
    (Cases[First /@ ArrayRules[
          Lookup[#, "IteratedIntegralCoefficientMatrix"]],
        {_, column_Integer} :> column]) & /@ outputTerms];
  usedColumns = Select[usedColumns,
    1 <= # <= Length[boundaryCoefficientRecords] &];
  boundaryDataRequirements = pruneBoundaryDataRequirements[
    Lookup[adapter, "BoundaryDataRequirements", {}],
    boundaryCoefficientRecords, usedColumns];
  <|
    "Status" -> "EndpointAutomatonBoundaryCoefficientMapsBuilt",
    "Family" -> family,
    "BoundaryDataType" -> boundaryDataType,
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> Lookup[
      transport, "RequestedMasterIntegralEpsilonOrderAndRowPairs", {}],
    coefficientRecordsKey -> boundaryCoefficientRecords,
    coefficientLabelsKey ->
      ({endpointBoundaryDataID[#], #["EpsilonOrder"]} & /@
        boundaryCoefficientRecords),
    "IteratedIntegralCoefficientMatrixRecords" -> outputTerms,
    "BoundaryDataRequirements" -> boundaryDataRequirements
  |>
];

ComposeEndpointAutomatonBoundaryCoefficientMaps[___] :=
  failure["EndpointAutomatonBoundaryCoefficientMapInputsNotWellFormed", <||>];

(* The observable operator may represent tens of millions of alphabet words,
   but at every exact weight their maps occupy a finite row space.  Close
   those row spaces under the two ordered path segments, then attach the
   endpoint connector once to a basis.  A requested word is recovered by a
   small coordinate projection; the alphabet product is never enumerated. *)
endpointExactRowBasis[rows_] := Module[{dense, reduced},
  dense = Normal[rows];
  If[dense === {}, Return[{}]];
  If[! MatrixQ[dense], Return[$Failed]];
  reduced = Quiet@Check[RowReduce[dense], $Failed];
  If[reduced === $Failed, Return[$Failed]];
  Select[reduced, AnyTrue[#, Not@*exactZeroQ] &]
];

endpointSpecializeMatrix[matrix_, rules_List] := Quiet@Check[
  Together[Normal[matrix] /. rules], $Failed];

endpointCurrentRowSpaces[transport_Association,
    initialRequestedOutputRowSelectorMatrix_: Automatic] := Catch@Module[
  {representation, variables, path, baseRules, maximumWeight, automaton,
   initial, firstMatrices, firstBoundary, secondMatrices, finalEmbedding,
   firstByWeight = <||>, spaces = <||>, rows, basis, firstState,
   secondState},
  representation = Lookup[transport,
    "IteratedIntegralCoefficientRepresentation", Missing[]];
  variables = Lookup[transport, "CoefficientVariables", Missing[]];
  path = Lookup[transport,
    "RegularBasePointAndFirstPathParameterScale", <||>];
  If[! MatchQ[variables, {_Symbol, _Symbol}],
    Throw@failure["UnsupportedCoefficientVariables", <||>]];
  baseRules = Lookup[transport, "BoundaryBasePoint", Thread[variables ->
    {Lookup[path, "FirstBase", Missing[]],
      Lookup[path, "SecondBase", Missing[]]}]];
  If[! MatchQ[baseRules, {(_Rule | _RuleDelayed) ..}] ||
      ! FreeQ[Last /@ baseRules, _Missing],
    Throw@failure["MissingTransportBasePoint", <|"Path" -> path|>]];

  If[representation =!=
      "IteratedIntegralCoefficientOperatorForRequestedOutputs",
    Throw@failure["ExactIteratedIntegralCoefficientOperatorRequired", <|
      "IteratedIntegralCoefficientRepresentation" -> representation|>]];
  automaton = Lookup[transport,
    "ExactIteratedIntegralCoefficientOperator", Missing[]];
  If[! AssociationQ[automaton] ||
      Lookup[automaton, "Status", None] =!=
        "IteratedIntegralCoefficientOperatorConstructed",
    Throw@failure["ExactIteratedIntegralCoefficientOperatorRequired", <||>]];
      maximumWeight = Lookup[automaton,
        "MaximumIteratedIntegralWeight", Missing[]];
      initial = endpointSpecializeMatrix[
        Replace[initialRequestedOutputRowSelectorMatrix,
          Automatic :> Lookup[automaton,
            "InitialRequestedOutputMap", Missing[]]], baseRules];
      firstMatrices = endpointSpecializeMatrix[#, baseRules] & /@
        Lookup[automaton, "FirstPathSegmentOperatorMatrices", {}];
      firstBoundary = endpointSpecializeMatrix[
        Lookup[automaton, "FirstPathSegmentBoundaryMap", Missing[]],
        baseRules];
      secondMatrices = endpointSpecializeMatrix[#, baseRules] & /@
        Lookup[automaton, "SecondPathSegmentOperatorMatrices", {}];
      finalEmbedding = endpointSpecializeMatrix[
        Lookup[automaton, "FinalBoundaryEmbedding", Missing[]], baseRules];
      If[! IntegerQ[maximumWeight] || maximumWeight < 0 ||
          MemberQ[Join[{initial, firstBoundary, finalEmbedding},
            firstMatrices, secondMatrices], $Failed] ||
          ! AllTrue[Join[{initial, firstBoundary, finalEmbedding},
            firstMatrices, secondMatrices], MatrixQ],
        Throw@failure[
          "ExactIteratedIntegralCoefficientOperatorIncomplete", <||>]];
      basis = endpointExactRowBasis[initial];
      If[basis === $Failed,
        Throw@failure["CurrentPathRowSpaceFailed", <|"Weight" -> 0|>]];
      AssociateTo[firstByWeight, 0 -> basis];
      Do[
        rows = If[Lookup[firstByWeight, weight - 1, {}] === {} ||
            firstMatrices === {}, {},
          Join @@ (Normal[Lookup[firstByWeight, weight - 1] . #] & /@
            firstMatrices)];
        basis = endpointExactRowBasis[rows];
        If[basis === $Failed,
          Throw@failure["CurrentPathRowSpaceFailed", <|"Weight" -> weight,
            "Segment" -> "First"|>]];
        AssociateTo[firstByWeight, weight -> basis],
        {weight, 1, maximumWeight}];
      Clear[firstState, secondState];
      Do[
        firstState = Lookup[firstByWeight, firstWeight, {}];
        secondState[firstWeight, 0] = endpointExactRowBasis[
          If[firstState === {}, {}, Normal[firstState . firstBoundary]]];
        If[secondState[firstWeight, 0] === $Failed,
          Throw@failure["CurrentPathRowSpaceFailed", <|
            "FirstWeight" -> firstWeight, "SecondWeight" -> 0|>]];
        Do[
          rows = If[secondState[firstWeight, secondWeight - 1] === {} ||
              secondMatrices === {}, {},
            Join @@ (Normal[
                secondState[firstWeight, secondWeight - 1] . #] & /@
              secondMatrices)];
          secondState[firstWeight, secondWeight] =
            endpointExactRowBasis[rows];
          If[secondState[firstWeight, secondWeight] === $Failed,
            Throw@failure["CurrentPathRowSpaceFailed", <|
              "FirstWeight" -> firstWeight,
              "SecondWeight" -> secondWeight|>]],
          {secondWeight, 1, maximumWeight - firstWeight}],
        {firstWeight, 0, maximumWeight}];
      Do[
        rows = Flatten[Table[
          If[secondState[firstWeight, weight - firstWeight] === {}, {},
            Normal[secondState[firstWeight, weight - firstWeight] .
              finalEmbedding]], {firstWeight, 0, weight}], 1];
        basis = endpointExactRowBasis[rows];
        If[basis === $Failed,
          Throw@failure["CurrentPathRowSpaceFailed", <|"Weight" -> weight,
            "Segment" -> "FinalEmbedding"|>]];
        If[basis =!= {}, AssociateTo[spaces, weight -> SparseArray[basis]]],
        {weight, 0, maximumWeight}];
  <|"Status" -> "CurrentRequestedOutputCoefficientRowSpacesBuilt",
    "IteratedIntegralCoefficientRepresentation" -> representation,
    "MaximumIteratedIntegralWeight" -> maximumWeight,
    "BaseRules" -> baseRules,
    "RowSpacesByIteratedIntegralWeight" -> spaces,
    "RowSpaceDimensionsByIteratedIntegralWeight" ->
      Association@KeyValueMap[
      #1 -> Dimensions[Normal[#2]] &, spaces]|>
];

endpointBasisProjectionData[basis_] := Module[
  {dense = Normal[basis], reduced, columns, square, firstNonzero},
  If[! MatrixQ[dense] || dense === {}, Return[$Failed]];
  reduced = Quiet@Check[RowReduce[dense], $Failed];
  If[reduced === $Failed, Return[$Failed]];
  firstNonzero[row_List] := SelectFirst[Range[Length[row]],
    ! exactZeroQ[row[[#]]] &, Missing["NoPivot"]];
  columns = DeleteCases[firstNonzero /@ reduced, _Missing];
  If[Length[columns] =!= Length[dense], Return[$Failed]];
  square = dense[[All, columns]];
  <|"Columns" -> columns,
    "Inverse" -> Quiet@Check[Inverse[square], $Failed]|>
];

endpointCoordinateKey[coordinate_Association] := With[
  {type = Lookup[coordinate, "BoundaryDataType", Missing["BoundaryDataType"]],
   id = endpointBoundaryDataID[coordinate],
   order = Lookup[coordinate, "EpsilonOrder"]},
  HoldComplete[type, id, order]];

endpointExpandTermColumns[term_Association, localCoordinates_List,
    globalIndex_Association, globalCount_Integer] := Module[
  {matrix, dimensions, rules},
  matrix = SparseArray[Lookup[term, "DemandProjectedMap"]];
  dimensions = Dimensions[matrix];
  rules = Cases[Most[ArrayRules[matrix]],
    HoldPattern[{row_Integer, column_Integer} -> value_] :>
      ({row, Lookup[globalIndex,
          endpointCoordinateKey[localCoordinates[[column]]]]} -> value)];
  Join[KeyDrop[term, "DemandProjectedMap"], <|
    "IteratedIntegralCoefficientMatrix" ->
      SparseArray[rules, {First[dimensions], globalCount}]|>]
];

endpointMergeBoundaryDataRequirements[requirements_List] := Module[
  {entries, groups},
  entries = Flatten[requirements];
  groups = GatherBy[entries,
    {Lookup[#, "BoundaryDataType", Missing[]], endpointBoundaryDataID[#]} &];
  Map[Function[group, Module[{type, labelsKey},
    type = Lookup[First[group], "BoundaryDataType", Missing[]];
    labelsKey = endpointBoundaryCoefficientLabelsKey[type];
    Join[First[group], <|labelsKey ->
      DeleteDuplicates@Flatten[Lookup[group, labelsKey, {}]]|>]
  ]], groups]
];

Options[BuildGradedPhysicalEndpointTransport] = {
  "BoundaryDataEpsilonOrderWindow" -> Automatic,
  "MaximumConnectorWords" -> 500000,
  "InitialRequestedOutputRowSelectorMatrix" -> Automatic
};

BuildGradedPhysicalEndpointTransport[transport_Association,
    modeMap_Association, boundaryData_: <||>, OptionsPattern[]] := Catch@Module[
  {rowSpaces, maximumWeight, spaces, maximumWords,
   boundaryDataEpsilonOrderWindow, gradeRecords, basis,
   projection, adapter, allCoefficientRecords, coordinateIndex, globalCount,
   grades, requirements, boundaryDataRequirements, firstGrade, family,
   boundaryDataType, coefficientRecordsKey, coefficientLabelsKey,
   localCoefficientRecordsKey},
  If[! TrueQ[
      FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
        transport]],
    Throw@failure[
      "IteratedIntegralCoefficientOperatorForRequestedOutputsRequired",
      <||>]];
  If[Lookup[transport, "IteratedIntegralCoefficientRepresentation", None] =!=
      "IteratedIntegralCoefficientOperatorForRequestedOutputs",
    Throw@failure["ExactIteratedIntegralCoefficientOperatorRequired", <||>]];
  family = Lookup[transport, "Family", Missing[]];
  If[Lookup[modeMap, "Family", family] =!= family,
    Throw@failure["EndpointModeFamilyMismatch", <|
      "TransportFamily" -> family,
      "ModeFamily" -> Lookup[modeMap, "Family", Missing[]]|>]];
  boundaryDataType = Lookup[modeMap, "BoundaryDataType", Missing[]];
  If[! MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType],
    Throw@failure["BoundaryDataTypeRequired", <||>]];
  coefficientRecordsKey = endpointBoundaryCoefficientRecordsKey[boundaryDataType];
  coefficientLabelsKey = endpointBoundaryCoefficientLabelsKey[boundaryDataType];
  localCoefficientRecordsKey = "Local" <> coefficientRecordsKey;
  maximumWords = OptionValue["MaximumConnectorWords"];
  boundaryDataEpsilonOrderWindow =
    OptionValue["BoundaryDataEpsilonOrderWindow"];
  If[! IntegerQ[maximumWords] || maximumWords < 1,
    Throw@failure["InvalidConnectorWordBudget", <||>]];
  rowSpaces = endpointCurrentRowSpaces[transport,
    OptionValue["InitialRequestedOutputRowSelectorMatrix"]];
  If[FailureQ[rowSpaces], Throw[rowSpaces]];
  If[! AssociationQ[rowSpaces] ||
      Lookup[rowSpaces, "Status", None] =!=
        "CurrentRequestedOutputCoefficientRowSpacesBuilt",
    Throw@failure[
      "CurrentRequestedOutputCoefficientRowSpacesRequired", <||>]];
  maximumWeight = rowSpaces["MaximumIteratedIntegralWeight"];
  spaces = rowSpaces["RowSpacesByIteratedIntegralWeight"];
  gradeRecords = Table[
    basis = Lookup[spaces, weight];
    projection = endpointBasisProjectionData[basis];
    If[projection === $Failed || projection["Inverse"] === $Failed,
      Throw@failure["CurrentPathBasisProjectionFailed", <|
        "Weight" -> weight|>]];
    adapter = BuildEndpointAutomatonBoundaryAdapter[
      transport, modeMap, boundaryData,
      "MaximumConnectorWeight" -> maximumWeight - weight,
      "MaximumConnectorWords" -> maximumWords,
      "BoundaryDataEpsilonOrderWindow" ->
        boundaryDataEpsilonOrderWindow,
      "RequestedPathSegmentLetterIndexSequencePairs" -> {{{}, {}}},
      "PreparedRequestedOutputCoefficientMatrices" -> {basis}];
    If[FailureQ[adapter] || Lookup[adapter, "Status", None] =!=
        "EndpointAutomatonBoundaryAdapterBuilt",
      Throw@failure["GradedEndpointAdapterFailed", <|
        "Weight" -> weight, "Result" -> adapter|>]];
    <|"CurrentWeight" -> weight, "CurrentRowBasis" -> basis,
      "ProjectionColumns" -> projection["Columns"],
      "ProjectionInverse" -> projection["Inverse"],
      localCoefficientRecordsKey -> adapter[coefficientRecordsKey],
      "LocalBoundaryPathIteratedIntegralCoefficientMatrixTerms" ->
        adapter["BoundaryPathIteratedIntegralCoefficientMatrixTerms"],
      "RequiredConnectorWeight" -> adapter["RequiredConnectorWeight"],
      "RetainedBoundaryPathCoefficientMatrixTermCount" ->
        adapter["RetainedBoundaryPathCoefficientMatrixTermCount"],
      "VisitedConnectorStateCount" ->
        adapter["VisitedConnectorStateCount"],
      "PrunedConnectorChildCount" -> adapter["PrunedConnectorChildCount"],
      "BoundaryDataRequirements" -> adapter["BoundaryDataRequirements"],
      "EndpointPath" -> adapter["Path"]|>,
    {weight, Keys[spaces]}];
  If[gradeRecords === {},
    Throw@failure["CurrentRequestedOutputCoefficientRowSpacesEmpty", <||>]];
  allCoefficientRecords = DeleteDuplicatesBy[
    Flatten[Lookup[gradeRecords, localCoefficientRecordsKey, {}]],
    endpointCoordinateKey];
  coordinateIndex = AssociationThread[
    endpointCoordinateKey /@ allCoefficientRecords,
    Range[Length[allCoefficientRecords]]];
  globalCount = Length[allCoefficientRecords];
  grades = Map[Function[grade, Join[
      KeyDrop[grade, {localCoefficientRecordsKey,
        "LocalBoundaryPathIteratedIntegralCoefficientMatrixTerms"}],
      <|"BoundaryPathIteratedIntegralCoefficientMatrixTerms" ->
        (endpointExpandTermColumns[#,
            grade[localCoefficientRecordsKey], coordinateIndex,
            globalCount] & /@
          grade[
            "LocalBoundaryPathIteratedIntegralCoefficientMatrixTerms"])|>]],
    gradeRecords];
  requirements = Lookup[gradeRecords, "BoundaryDataRequirements", {}];
  boundaryDataRequirements =
    endpointMergeBoundaryDataRequirements[requirements];
  firstGrade = First[grades];
  <|"Status" -> "GradedPhysicalEndpointTransportBuilt",
    "Family" -> family,
    "BoundaryDataType" -> boundaryDataType,
    "IteratedIntegralCoefficientOperatorStatus" ->
      Lookup[transport, "Status", Missing[]],
    "IteratedIntegralCoefficientRepresentation" -> Lookup[transport,
      "IteratedIntegralCoefficientRepresentation", Missing[]],
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> Lookup[
      transport, "RequestedMasterIntegralEpsilonOrderAndRowPairs", {}],
    "MaximumCurrentWeight" -> maximumWeight,
    "CurrentBaseRules" -> rowSpaces["BaseRules"],
    "RegularBasePointAndFirstPathParameterScale" -> Lookup[transport,
      "RegularBasePointAndFirstPathParameterScale", <||>],
    "EndpointPath" -> firstGrade["EndpointPath"],
    coefficientRecordsKey -> allCoefficientRecords,
    coefficientLabelsKey ->
      ({endpointBoundaryDataID[#], #["EpsilonOrder"]} & /@
        allCoefficientRecords),
    "BoundaryDataRequirements" -> boundaryDataRequirements,
    "DegenerateResidueEigenspaceBases" ->
      Lookup[modeMap, "DegenerateResidueEigenspaceBases", {}],
    "GradesByWeight" -> AssociationThread[
      Lookup[grades, "CurrentWeight"], grades],
    "CurrentRowSpaceDimensions" ->
      rowSpaces["RowSpaceDimensionsByIteratedIntegralWeight"],
    "FormalResultConvention" -> <|
      "Segments" -> {"CurrentFirst", "CurrentSecond",
        "EndpointFirst", "EndpointSecond"},
      "IteratedIntegralSequenceOrientation" -> "OutermostFirst",
      "NoAlphabetCartesianEnumeration" -> True,
      "Coefficient" -> If[boundaryDataType === "BoundaryConstant",
        "Map . BoundaryConstantEpsilonCoefficient[BoundaryConstantID,EpsilonOrder]",
        "Map . BoundaryFunctionEpsilonCoefficient[BoundaryFunctionID,EpsilonOrder]"]|>|>
];

BuildGradedPhysicalEndpointTransport[___] :=
  failure["GradedPhysicalEndpointTransportInputsNotWellFormed", <||>];

ComposeGradedPhysicalEndpointWords[binding_Association,
    transport_Association, wordPairs_List] := Catch@Module[
  {family, boundaryCoefficientRecords, grades, baseRules, outputTerms,
   wordResult, map, grade, columns, inverse, basisCoordinates, composed,
   usedColumns, boundaryDataRequirements, boundaryDataType,
   coefficientRecordsKey, coefficientLabelsKey},
  If[Lookup[binding, "Status", None] =!=
      "GradedPhysicalEndpointTransportBuilt",
    Throw@failure["GradedPhysicalEndpointTransportRequired", <||>]];
  If[! TrueQ[
      FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
        transport]] ||
      Lookup[transport, "IteratedIntegralCoefficientRepresentation", None] =!=
        "IteratedIntegralCoefficientOperatorForRequestedOutputs",
    Throw@failure[
      "ExactIteratedIntegralCoefficientOperatorRequired", <||>]];
  family = Lookup[transport, "Family", Missing[]];
  If[family =!= Lookup[binding, "Family", Missing[]],
    Throw@failure["EndpointAdapterFamilyMismatch", <||>]];
  If[! ListQ[wordPairs] ||
      ! AllTrue[wordPairs, MatchQ[#, {_List, _List}] &],
    Throw@failure["InvalidAutomatonWordRequest", <||>]];
  boundaryDataType = Lookup[binding, "BoundaryDataType", Missing[]];
  If[! MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType],
    Throw@failure["BoundaryDataTypeRequired", <||>]];
  coefficientRecordsKey = endpointBoundaryCoefficientRecordsKey[boundaryDataType];
  coefficientLabelsKey = endpointBoundaryCoefficientLabelsKey[boundaryDataType];
  boundaryCoefficientRecords = binding[coefficientRecordsKey];
  grades = binding["GradesByWeight"];
  baseRules = binding["CurrentBaseRules"];
  outputTerms = Reap[Do[
      wordResult = requestedOutputIteratedIntegralCoefficientMatrix[
        transport, First[pair], Last[pair]];
      If[FailureQ[wordResult] || ! MatrixQ[Normal[wordResult]],
        Throw@failure["IteratedIntegralCoefficientMatrixUnavailable", <|
          "PathSegmentLetterIndexSequencePair" -> pair,
          "Result" -> wordResult|>]];
      map = endpointSpecializeMatrix[wordResult, baseRules];
      If[map === $Failed,
        Throw@failure["CurrentPathWordSpecializationFailed", <|
          "PathSegmentLetterIndexSequencePair" -> pair|>]];
      (* An accepted automaton may have a requested maximum weight above
         its last nonzero row-space grade.  Such words are represented by
         the exact zero map, not by a missing grade. *)
      If[! AnyTrue[Flatten[map], Not@*exactZeroQ], Continue[]];
      grade = Lookup[grades, Length[First[pair]] + Length[Last[pair]],
        Missing["Weight"]];
      If[MissingQ[grade],
        Throw@failure["CurrentPathWeightUnavailable", <|
          "PathSegmentLetterIndexSequencePair" -> pair|>]];
      columns = grade["ProjectionColumns"];
      inverse = grade["ProjectionInverse"];
      basisCoordinates = map[[All, columns]] . inverse;
      If[AnyTrue[Flatten[Together[
            basisCoordinates . Normal[grade["CurrentRowBasis"]] - map]],
          Not@*exactZeroQ],
        Throw@failure["CurrentPathRowSpaceMismatch", <|
          "PathSegmentLetterIndexSequencePair" -> pair,
          "CurrentWeight" ->
            Length[First[pair]] + Length[Last[pair]]|>]];
      Do[
        composed = SparseArray[basisCoordinates .
          term["IteratedIntegralCoefficientMatrix"]];
        If[AnyTrue[Flatten[Normal[composed]], Not@*exactZeroQ], Sow[<|
          "CurrentPathFirstSegmentLetterIndices" -> First[pair],
          "CurrentPathSecondSegmentLetterIndices" -> Last[pair],
          "BoundaryPathFirstSegmentLetterIndices" ->
            term["BoundaryPathFirstSegmentLetterIndices"],
          "BoundaryPathSecondSegmentLetterIndices" ->
            term["BoundaryPathSecondSegmentLetterIndices"],
          "IteratedIntegralCoefficientMatrix" -> composed|>]],
        {term,
          grade["BoundaryPathIteratedIntegralCoefficientMatrixTerms"]}],
      {pair, wordPairs}]][[2]];
  outputTerms = If[outputTerms === {}, {}, First[outputTerms]];
  usedColumns = Sort@DeleteDuplicates@Flatten[
    Cases[First /@ ArrayRules[
        Lookup[#, "IteratedIntegralCoefficientMatrix"]],
        {_, column_Integer} :> column] & /@ outputTerms];
  usedColumns = Select[usedColumns,
    1 <= # <= Length[boundaryCoefficientRecords] &];
  boundaryDataRequirements = pruneBoundaryDataRequirements[
    binding["BoundaryDataRequirements"], boundaryCoefficientRecords,
    usedColumns];
  <|"Status" -> "GradedPhysicalEndpointWordsBuilt",
    "Family" -> family,
    "BoundaryDataType" -> boundaryDataType,
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" ->
      binding["RequestedMasterIntegralEpsilonOrderAndRowPairs"],
    coefficientRecordsKey -> boundaryCoefficientRecords,
    coefficientLabelsKey ->
      ({endpointBoundaryDataID[#], #["EpsilonOrder"]} & /@
        boundaryCoefficientRecords),
    "IteratedIntegralCoefficientMatrixRecords" -> outputTerms,
    "BoundaryDataRequirements" -> boundaryDataRequirements,
    "FormalResultConvention" -> binding["FormalResultConvention"]|>
];

ComposeGradedPhysicalEndpointWords[___] :=
  failure["GradedPhysicalEndpointWordInputsNotWellFormed", <||>];

End[];
EndPackage[];
