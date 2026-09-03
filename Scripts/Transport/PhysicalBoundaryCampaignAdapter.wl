(* ::Package:: *)

BeginPackage["FeynFacetCampaign`PhysicalBoundary`"];

BuildEndpointAutomatonBoundaryAdapter::usage =
  "BuildEndpointAutomatonBoundaryAdapter[transport, modeMap, periodData] builds the " <>
  "finite endpoint-to-interior word map needed to feed singular zero modes into an " <>
  "operator or materialized observable transport for explicitly requested words.  " <>
  "The returned coordinate maps are rational; " <>
  "unevaluated periods are represented only by BoundaryPeriodCoefficient[id, order].";

ComposeEndpointAutomatonPeriodWords::usage =
  "ComposeEndpointAutomatonPeriodWords[adapter, transport, wordPairs] composes endpoint " <>
  "connection words with prepared OperatorAutomaton demand words and returns " <>
  "period-coordinate maps.  Unprepared demand words fail typed.";

BuildGradedPhysicalEndpointTransport::usage =
  "BuildGradedPhysicalEndpointTransport[transport, modeMap, periodData] closes the " <>
  "accepted observable transport under its current-path word operators grade by grade, " <>
  "then attaches the endpoint Frobenius transport to a basis of each finite row space. " <>
  "It represents every requested-weight word without enumerating the alphabet product.";

ComposeGradedPhysicalEndpointWords::usage =
  "ComposeGradedPhysicalEndpointWords[binding, transport, wordPairs] materializes only " <>
  "the requested current-path words from a graded physical endpoint binding and returns " <>
  "their four-segment GPL maps on one shared vector of physical period coordinates.";

EndpointConnectionWord::usage =
  "EndpointConnectionWord[path, firstWord, secondWord] is the inert Chen word " <>
  "multiplying an endpoint-to-interior boundary-coordinate map.";

Begin["`Private`"];

ClearAll[exactZeroQ, failure, leadingEpsilonOrder,
  exactAssociationLookup,
  independentEmbeddingRows, modeVector, endpointModeStatus,
  endpointModePeriodRecord, endpointResidueMatrix, reachableWordPairs,
  endpointDemandRowBasis, endpointDemandVisibilityRows,
  endpointDemandCoReachability, endpointModeOrderKey,
  endpointModeCoefficientData, endpointDemandOrderMatrices,
  operatorAutomatonWordMap, transportObservableWordMap,
  stage3Entry, pruneLedger, endpointExactRowBasis,
  endpointSpecializeMatrix, endpointCurrentRowSpaces,
  endpointBasisProjectionData, endpointExpandTermColumns,
  endpointMergeStage3Ledger, endpointCoordinateKey];

exactZeroQ[x_] := TrueQ[x === 0] || TrueQ[PossibleZeroQ[x]];

(* Lookup treats a list-valued key as a list of separate keys.  Physical
   realization IDs are commonly {family, period}, so retrieve them through
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
        "PeriodID" -> Lookup[mode, "PeriodID", Missing["Absent"]]|>]]
  ];
  If[Length[vector] =!= dimension,
    Return@failure["EndpointModeDimensionMismatch", <|
      "PeriodID" -> Lookup[mode, "PeriodID", Missing["Absent"]],
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
        "PeriodID" -> Lookup[mode, "PeriodID", Missing["Absent"]],
        "ExpectedVectorLengthOrMatrixDimension" -> dimension|>]
  ]
];

endpointModeStatus[mode_Association] := Lookup[mode, "Status", Missing["Absent"]];

endpointModePeriodRecord[periodData_Association, periodID_] :=
  exactAssociationLookup[periodData, periodID,
    exactAssociationLookup[periodData, ToString[periodID], <||>]];

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
    dimension_Integer, weight_Integer, periodCoordinates_List,
    coefficientPositions_Association] := Module[
  {orders, activeOrders, coefficientPresentQ, rows, vector},
  orders = DeleteDuplicates[pivotSlots[[All, 1]]];
  coefficientPresentQ[id_, order_] := KeyExistsQ[coefficientPositions,
    endpointModeOrderKey[id, order]];
  activeOrders = Select[orders, Function[slotOrder,
    AnyTrue[periodCoordinates, Function[coordinate,
      coefficientPresentQ[Lookup[coordinate, "PeriodID"],
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
    regulator_Symbol, orders_List, dimension_Integer] := Module[
  {records, coefficientVector},
  records = Flatten@Table[
    coefficientVector = Quiet@Check[
      (SeriesCoefficient[#, {regulator, 0, order}] & /@
        exactAssociationLookup[modeVectors, id]),
      $Failed];
    If[coefficientVector === $Failed || !VectorQ[coefficientVector] ||
        Length[coefficientVector] =!= dimension,
      Return@failure["EndpointCoefficientExtractionFailed", <|
        "PeriodID" -> id, "ModeEpsilonOrder" -> order|>]
    ];
    If[AnyTrue[coefficientVector, Not@*exactZeroQ],
      {<|"PeriodID" -> id, "ModeEpsilonOrder" -> order,
        "Vector" -> (Together /@ coefficientVector)|>}, {}],
    {id, ids}, {order, orders}];
  <|
    "Records" -> records,
    "SeedMatrix" -> If[records === {}, ConstantArray[0, {dimension, 0}],
      Transpose[Lookup[records, "Vector"]]],
    "ColumnPositions" -> AssociationThread[
      (endpointModeOrderKey[Lookup[#, "PeriodID"],
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

operatorAutomatonWordMap[automaton_Association, firstWord_List,
    secondWord_List, includeFinalEmbedding_: True] := Module[
  {firstAlphabet, secondAlphabet, firstPositions, secondPositions, map},
  If[Length[firstWord] + Length[secondWord] >
      Lookup[automaton, "RequestedMaximumWeight", -1],
    Return[failure["WordExceedsRequestedWeight", <|
      "FirstWord" -> firstWord, "SecondWord" -> secondWord|>]]
  ];
  firstAlphabet = Lookup[automaton, "FirstAlphabetIndices", {}];
  secondAlphabet = Lookup[automaton, "SecondAlphabetIndices", {}];
  firstPositions = FirstPosition[firstAlphabet, #, Missing["Unknown"]] & /@ firstWord;
  secondPositions = FirstPosition[secondAlphabet, #, Missing["Unknown"]] & /@ secondWord;
  If[AnyTrue[Join[firstPositions, secondPositions], MissingQ],
    Return[failure["WordUsesUnknownKernel", <|
      "FirstWord" -> firstWord, "SecondWord" -> secondWord|>]]
  ];
  map = Lookup[automaton, "InitialDemandMap", Missing["Absent"]];
  If[!MatrixQ[Normal[map]], Return[failure["OperatorAutomatonIncomplete", <||>]]];
  Do[map = map . Lookup[automaton, "FirstOperatorMatrices"][[First[position]]],
    {position, firstPositions}];
  map = map . Lookup[automaton, "FirstBoundaryOperator"];
  Do[map = map . Lookup[automaton, "SecondOperatorMatrices"][[First[position]]],
    {position, secondPositions}];
  If[TrueQ[includeFinalEmbedding],
    map . Lookup[automaton, "FinalBoundaryEmbedding"], map]
];

transportObservableWordMap[transport_Association, firstWord_List,
    secondWord_List] := Module[{representation, automaton, records, record},
  representation = Lookup[transport, "WordRepresentation", Missing["Absent"]];
  Switch[representation,
    "OperatorAutomaton",
      automaton = Lookup[transport, "ExactOperatorAutomaton",
        Lookup[transport, "WordAutomaton", Missing["Absent"]]];
      If[!AssociationQ[automaton],
        failure["OperatorAutomatonRequired", <||>],
        operatorAutomatonWordMap[automaton, firstWord, secondWord]],
    "MaterializedWords",
      records = Lookup[transport, "TwoSegmentWordMaps", Missing["Absent"]];
      If[!ListQ[records],
        Return@failure["MaterializedObservableWordsRequired", <||>]];
      record = SelectFirst[records,
        MatchQ[#, {_List, _List, _}] && First[#] === firstWord &&
          #[[2]] === secondWord &, Missing["Unavailable"]];
      If[MissingQ[record],
        failure["MaterializedDemandWordUnavailable", <|
          "CurrentFirstWord" -> firstWord,
          "CurrentSecondWord" -> secondWord|>], record[[3]]],
    _, failure["SupportedObservableWordRepresentationRequired", <|
      "WordRepresentation" -> representation|>]
  ]
];

stage3Entry[family_, endpointSpec_, mode_, status_, coordinates_List, outputs_List] := <|
  "PeriodID" -> Lookup[mode, "PeriodID", Missing["Absent"]],
  "Family" -> family,
  "Limit" -> <|
    "Variable" -> Lookup[endpointSpec, "Variable", Missing["Absent"]],
    "Endpoint" -> Lookup[endpointSpec, "Endpoint", Missing["Absent"]],
    "FixedRules" -> Lookup[endpointSpec, "FixedRules", {}],
    "Stratum" -> Lookup[endpointSpec, "Stratum", Missing["Absent"]]|>,
  "FrobeniusMode" -> <|
    "LocalEigenvalue" -> Lookup[mode, "LocalEigenvalue", Missing["Absent"]],
    "GeneralizedLevel" -> Lookup[mode, "GeneralizedLevel", Missing["Absent"]],
    "Support" -> Lookup[mode, "Support", Missing["Absent"]]|>,
  "AffectedBoundaryCoordinates" -> coordinates,
  "DemandedOutputs" -> outputs,
  "Status" -> status
|>;

pruneLedger[ledger_List, coordinates_List, usedColumns_List] := Module[
  {used = If[usedColumns === {}, {}, coordinates[[usedColumns]]]},
  ledger /. entry_Association :> Module[{periodID, selected},
    periodID = Lookup[entry, "PeriodID", Missing["Absent"]];
    selected = Select[used, Lookup[#, "PeriodID", Missing["Absent"]] === periodID &];
    Join[entry, <|"AffectedBoundaryCoordinates" -> selected|>]
  ]
];

Options[BuildEndpointAutomatonBoundaryAdapter] = {
  "MaximumConnectorWeight" -> Automatic,
  "MaximumConnectorWords" -> 200000,
  "PeriodOrderWindow" -> Automatic,
  "DemandWordPairs" -> {{{}, {}}}
};

BuildEndpointAutomatonBoundaryAdapter[
    transport_Association, modeMap_Association, periodData_: <||>,
    OptionsPattern[]] := Catch@Module[
  {automaton, wordRepresentation, path, variables, regulator, family,
   letters, residues, dimension,
   endpointSpec, endpointVariable, endpoint, fixedRules, firstVariable,
   secondVariable, firstBase, secondBase, fixedFirst, secondKernels,
   firstKernels, secondIndices, firstIndices, matrixAssociation,
   endpointResidue, modes, realizedModes, modeVectors, recordByID,
   knownZeroByID, statusByID, valuationByID, modeOrderByID,
   ambientSlots, embedding, pivotData, pivotRows, pivotSlots, pivotInverse,
   maximumWeight, maximumWords, periodWindow, periodCoordinates,
   wordPairs, wordRecord, endpointTerms, activeColumns, ledger,
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
   coefficientPosition, contribution, outputColumn},

  automaton = Lookup[transport, "ExactOperatorAutomaton",
    Lookup[transport, "WordAutomaton", Missing["Absent"]]];
  wordRepresentation = Lookup[transport, "WordRepresentation", Missing["Absent"]];
  If[!MemberQ[{"OperatorAutomaton", "MaterializedWords"}, wordRepresentation] ||
      (wordRepresentation === "OperatorAutomaton" && !AssociationQ[automaton]) ||
      (wordRepresentation === "MaterializedWords" &&
        !ListQ[Lookup[transport, "TwoSegmentWordMaps", Missing["Absent"]]]),
    Throw@failure["SupportedObservableWordRepresentationRequired", <|
      "WordRepresentation" -> wordRepresentation|>]
  ];
  path = Lookup[transport, "Path", Missing["Absent"]];
  If[!AssociationQ[path], Throw@failure["MissingTransportPath", <||>]];
  variables = Lookup[transport, "Variables", Missing["Absent"]];
  If[!MatchQ[variables, {_Symbol, _Symbol}],
    Throw@failure["UnsupportedTransportVariables", <|"Variables" -> variables|>]
  ];
  {firstVariable, secondVariable} = variables;
  regulator = Lookup[transport, "Regulator", Missing["Absent"]];
  If[!MatchQ[regulator, _Symbol], Throw@failure["MissingTransportRegulator", <||>]];
  family = Lookup[transport, "Family", Lookup[modeMap, "Family", Missing["Absent"]]];
  firstBase = Lookup[path, "FirstBase", Missing["Absent"]];
  secondBase = Lookup[path, "SecondBase", Missing["Absent"]];
  If[MemberQ[{firstBase, secondBase}, _Missing],
    Throw@failure["MissingTransportBasePoint", <|"Path" -> path|>]
  ];

  endpointSpec = Lookup[modeMap, "EndpointSpec", Missing["Absent"]];
  If[!AssociationQ[endpointSpec] &&
      And @@ (KeyExistsQ[modeMap, #] & /@ {"Variable", "Endpoint", "FixedRules"}),
    endpointSpec = KeyTake[modeMap, {"Variable", "Endpoint", "FixedRules"}];
    physicalEndpointRelation = Lookup[modeMap, "PhysicalEndpointRelation", <||>];
    endpointSpec = Join[endpointSpec, <|
      "Stratum" -> Lookup[physicalEndpointRelation, "Stratum", Missing["Absent"]],
      "LocalCoordinatePower" -> Lookup[physicalEndpointRelation, "LocalPower", 1],
      "LocalCoordinateLeadingCoefficient" ->
        Lookup[physicalEndpointRelation, "LeadingCoefficient", 1]|>]
  ];
  If[!AssociationQ[endpointSpec],
    Throw@failure["MissingEndpointSpecification", <|"Family" -> family|>]
  ];
  physicalEndpointRelation = Lookup[modeMap, "PhysicalEndpointRelation", <||>];
  modeLimit = Lookup[modeMap, "Limit", <||>];
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
  endpoint = Lookup[endpointSpec, "Endpoint", Missing["Absent"]];
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

  letters = Lookup[transport, "DLogLetters", Missing["Absent"]];
  residues = Lookup[transport, "DLogResidues", Missing["Absent"]];
  If[!ListQ[letters] || !ListQ[residues] || Length[letters] =!= Length[residues] ||
      letters === {} || !And @@ (MatrixQ /@ residues),
    Throw@failure["MissingFirstSegmentMap", <|
      "Reason" -> "Accepted dlog letters and residue matrices are required"|>]
  ];
  dimension = First@Dimensions[First[residues]];
  If[!And @@ (Dimensions[#] === {dimension, dimension} & /@ residues),
    Throw@failure["InvalidDLogResidues", <||>]
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

  modes = Lookup[modeMap, "Modes", Missing["Absent"]];
  If[!ListQ[modes] || modes === {},
    Throw@failure["MissingEndpointModeRealization", <|"Family" -> family|>]
  ];
  realizedModes = Select[modes,
    MemberQ[{"Exact", "BoundaryModeMatched"}, endpointModeStatus[#]] &];
  If[realizedModes === {},
    Throw@failure["MissingEndpointModeRealization", <|
      "Family" -> family, "ModeStatuses" -> (endpointModeStatus /@ modes)|>]
  ];
  If[AnyTrue[realizedModes,
      !exactZeroQ[Lookup[#, "LocalEigenvalue", Missing["Absent"]]] ||
      Lookup[#, "GeneralizedLevel", Missing["Absent"]] =!= 0 &],
    Throw@failure["TangentialLogModeRequired", <|
      "Reason" -> "Only ordinary zero modes can be passed to the interior automaton",
      "PeriodIDs" -> Lookup[realizedModes, "PeriodID", Missing["Absent"]],
      "RequiredLocalNormalization" -> HoldForm[
        Exp[regulator Log[localCoordinateLeadingCoefficient]
          Subscript[R, endpointVariable]/localCoordinatePower]],
      "LogBranchMustBeSpecified" ->
        !exactZeroQ[localCoordinateLeadingCoefficient - 1]|>]
  ];
  modeVectors = Association@Map[
    Function[currentMode,
      With[{currentVector = modeVector[currentMode, dimension]},
        If[FailureQ[currentVector], Throw[currentVector]];
        Lookup[currentMode, "PeriodID", Missing["Absent"]] -> currentVector]],
    realizedModes];
  If[MemberQ[Keys[modeVectors], _Missing],
    Throw@failure["MissingEndpointModeRealization", <|
      "Reason" -> "Every mode needs a PeriodID"|>]
  ];
  Do[
    endpointAction = Together[endpointResidue . exactAssociationLookup[
      modeVectors, Lookup[mode, "PeriodID"]]];
    If[!And @@ (exactZeroQ /@ endpointAction),
      Throw@failure["EndpointModeNotTangentiallyRegular", <|
        "PeriodID" -> Lookup[mode, "PeriodID"],
        "Variable" -> secondVariable, "Endpoint" -> endpoint|>]
    ],
    {mode, realizedModes}];

  recordByID = Association@Table[
    Lookup[mode, "PeriodID"] -> endpointModePeriodRecord[
      If[AssociationQ[periodData], periodData, <||>], Lookup[mode, "PeriodID"]],
    {mode, realizedModes}];
  knownZeroByID = Association@Table[
    id -> (exactZeroQ[Lookup[SelectFirst[realizedModes,
          Lookup[#, "PeriodID"] === id &], "KnownCoefficient", Missing["Absent"]]] ||
      MemberQ[{"KnownZero", "ExactZero"}, Lookup[
        exactAssociationLookup[recordByID, id], "Status", None]]),
    {id, Keys[modeVectors]}];
  statusByID = Association@Table[
    id -> If[TrueQ@exactAssociationLookup[knownZeroByID, id],
      "KnownZero", "Unevaluated"],
    {id, Keys[modeVectors]}];
  valuationByID = Association@Table[
    id -> Lookup[exactAssociationLookup[recordByID, id], "EpsilonValuation",
      Lookup[SelectFirst[realizedModes, Lookup[#, "PeriodID"] === id &],
        "PeriodEpsilonValuation", 0]],
    {id, Keys[modeVectors]}];
  If[!And @@ (IntegerQ /@ Values[valuationByID]),
    Throw@failure["MissingPeriodEpsilonValuation", <|
      "Valuations" -> valuationByID|>]
  ];
  modeOrderByID = Association@Table[
    id -> Min[leadingEpsilonOrder[#, regulator] & /@
      exactAssociationLookup[modeVectors, id]],
    {id, Keys[modeVectors]}];

  ambientSlots = Lookup[transport, "BoundaryAmbientSlots", Missing["Absent"]];
  (* Endpoint modes live in the ambient Laurent-slot space at the interior
     base.  For MovingKernel transports the automaton's FinalBoundaryEmbedding
     is only the later square boundary-coordinate map; the ambient-to-boundary
     embedding is BoundaryBaseEmbedding.  In the AmbientBasePoint route these
     two maps coincide in shape. *)
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
  periodWindow = OptionValue["PeriodOrderWindow"];
  If[periodWindow === Automatic,
    periodWindow = {
      Min[Values[valuationByID]],
      Max[ambientSlots[[All, 1]]] - Min[Cases[Values[modeOrderByID], _Integer]]
    }];
  If[!MatchQ[periodWindow, {_Integer, _Integer}] || First[periodWindow] > Last[periodWindow],
    Throw@failure["InvalidPeriodOrderWindow", <|"PeriodOrderWindow" -> periodWindow|>]
  ];
  periodCoordinates = Flatten@Table[
    If[TrueQ@exactAssociationLookup[knownZeroByID, id], {},
      realizationKey = Lookup[exactAssociationLookup[recordByID, id],
        "RealizationKey",
        If[TrueQ@Lookup[exactAssociationLookup[recordByID, id],
            "ClassIdentityExact", False], id,
          If[MatchQ[id, {family, __}], id, {family, id}]]];
      Table[<|"PeriodID" -> id, "RealizationKey" -> realizationKey,
        "EpsilonOrder" -> q,
        "Coefficient" -> FeynFacet`BoundaryPeriodCoefficient[realizationKey, q],
        "Status" -> exactAssociationLookup[statusByID, id]|>,
        {q, Max[First[periodWindow],
          exactAssociationLookup[valuationByID, id]], Last[periodWindow]}]],
    {id, Keys[modeVectors]}];
  formalModeIDs = Select[Keys[modeVectors],
    ! TrueQ@exactAssociationLookup[knownZeroByID, #] &];
  demandWordPairs = OptionValue["DemandWordPairs"];
  If[!ListQ[demandWordPairs] || demandWordPairs === {} ||
      !AllTrue[demandWordPairs, MatchQ[#, {_List, _List}] &],
    Throw@failure["InvalidEndpointDemandWordPairs", <|
      "DemandWordPairs" -> demandWordPairs|>]
  ];
  baseRules = Lookup[transport, "BoundaryBasePoint",
    {firstVariable -> firstBase, secondVariable -> secondBase}];
  demandMaps = Table[
    currentMap = Quiet@Check[
      transportObservableWordMap[transport, First[pair], Last[pair]], $Failed];
    If[currentMap === $Failed || FailureQ[currentMap] ||
        !MatrixQ[Normal[currentMap]],
      Throw@failure["ObservableWordMapUnavailable", <|
        "CurrentFirstWord" -> First[pair],
        "CurrentSecondWord" -> Last[pair],
        "WordRepresentation" -> wordRepresentation,
        "ProviderResult" -> currentMap|>]
    ];
    Together[Normal[currentMap] /. baseRules],
    {pair, demandWordPairs}];
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
      <|"CurrentFirstWord" -> First[pair],
        "CurrentSecondWord" -> Last[pair], "RowRange" -> rows|>]],
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
  requiredConnectorWeight = If[periodCoordinates === {}, 0,
    Max[0, Max@Table[
      id = Lookup[coordinate, "PeriodID"];
      q = Lookup[coordinate, "EpsilonOrder"];
      demandedSlotMaximum - q - exactAssociationLookup[modeOrderByID, id],
      {coordinate, periodCoordinates}]]];
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
      "Reason" -> "The requested period and observable boundary orders need higher endpoint words"|>]
  ];
  demandOrderMatrices = endpointDemandOrderMatrices[
    pivotDemand, pivotSlots, dimension];
  demandOrders = Keys[demandOrderMatrices];
  coefficientOrders = Sort@DeleteDuplicates@Flatten@Table[
    order - Lookup[coordinate, "EpsilonOrder"] - weight,
    {order, demandOrders}, {coordinate, periodCoordinates},
    {weight, 0, maximumWeight}];
  coefficientData = endpointModeCoefficientData[modeVectors,
    formalModeIDs, regulator, coefficientOrders, dimension];
  If[FailureQ[coefficientData], Throw[coefficientData]];
  seedMatrix = Lookup[coefficientData, "SeedMatrix"];
  coefficientPositions = Lookup[coefficientData, "ColumnPositions"];
  visibility = Association@Table[weight ->
    endpointDemandVisibilityRows[pivotDemand, pivotSlots, dimension,
      weight, periodCoordinates, coefficientPositions],
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
      projectedMap = If[periodCoordinates === {},
        ConstantArray[0, {Length[demandMapStack], 0}],
        Transpose@Table[
        coordinate = periodCoordinates[[coordinateColumn]];
        id = Lookup[coordinate, "PeriodID"];
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
        {coordinateColumn, Length[periodCoordinates]}]];
      If[Length[periodCoordinates] > 0 &&
          AnyTrue[Flatten[projectedMap], Not@*exactZeroQ],
        Sow[<|"EndpointFirstWord" -> term[[1]],
          "EndpointSecondWord" -> term[[2]],
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
        Select[active, 1 <= # <= Length[periodCoordinates] &]],
      endpointTerms]];
  If[activeColumns =!= Range[Length[periodCoordinates]],
    endpointTerms = endpointTerms /. currentTerm_Association :>
      Join[currentTerm, <|"DemandProjectedMap" ->
        Lookup[currentTerm, "DemandProjectedMap"][[All, activeColumns]]|>];
    periodCoordinates = If[activeColumns === {}, {}, periodCoordinates[[activeColumns]]]
  ];

  demandedOutputs = Lookup[transport, "PhysicalDemandPairs", {}];
  ledger = Table[
    id = Lookup[mode, "PeriodID"];
    status = exactAssociationLookup[statusByID, id];
    stage3Entry[family, endpointSpec, mode, status,
      Select[periodCoordinates, Lookup[#, "PeriodID"] === id &], demandedOutputs],
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
        "AlphabetIndices" -> secondIndices, "DLogKernels" -> secondKernels|>,
      <|"Role" -> "EndpointFirst", "Variable" -> firstVariable,
        "Base" -> fixedFirst, "Target" -> firstBase,
        "FixedRules" -> {secondVariable -> secondBase},
        "AlphabetIndices" -> firstIndices, "DLogKernels" -> firstKernels|>
    },
    "MultiplicationOrder" -> "EndpointFirstWord.EndpointSecondWord",
    "BoundaryPrescription" -> "ZeroResidueModeTangential",
    "LocalCoordinateNormalization" -> <|
      "Power" -> localCoordinatePower,
      "LeadingCoefficient" -> localCoordinateLeadingCoefficient,
      "ActionOnAcceptedModes" -> "IdentityBecauseEndpointResidueAnnihilatesModes",
      "NontrivialModesRequire" -> HoldForm[
        Exp[regulator Log[localCoordinateLeadingCoefficient]
          Subscript[R, endpointVariable]/localCoordinatePower]]|>
  |>;

  <|
    "Status" -> "EndpointAutomatonBoundaryAdapterBuilt",
    "Family" -> family,
    "ObservableWordMapProvider" -> wordRepresentation,
    "Regulator" -> regulator,
    "EndpointModeMapStatus" -> Lookup[modeMap, "Status", Missing["Absent"]],
    "Path" -> pathDescriptor,
    "AutomatonBoundaryDimension" -> Last[Dimensions[Normal[embedding]]],
    "BoundaryAmbientSlots" -> ambientSlots,
    "BoundaryCoordinateConvention" -> <|
      "EmbeddingPivotRows" -> pivotRows,
      "Definition" -> "LexicographicallyFirstExactLeftInverse",
      "Projection" -> "OnlyPreparedDemandWordsAtInteriorBase"|>,
    "DemandVisibleAmbientSlotMaximum" -> demandedSlotMaximum,
    "PreparedDemandWordPairs" -> demandWordPairs,
    "PreparedDemandWordRecords" -> demandWordRecords,
    "PeriodCoordinates" -> periodCoordinates,
    "EndpointWordTerms" -> endpointTerms,
    "FormalBoundaryConvention" ->
      "Sum[EndpointConnectionWord[Path, firstWord, secondWord] Map . PeriodCoordinateVector]",
    "MaximumConnectorWeight" -> maximumWeight,
    "RequiredConnectorWeight" -> requiredConnectorWeight,
    "ConnectorDepthComplete" -> True,
    "AggregateBoundaryImageCondition" ->
      "AppliesAfterTheCompleteEndpointWordSumNotToIndividualWords",
    "EnumeratedConnectorWordCount" -> requestedWordCount,
    "RetainedConnectorWordCount" -> Length[endpointTerms],
    "VisitedConnectorStateCount" -> wordRecord["VisitedStates"],
    "ConnectorEnumerationMethod" -> "DemandDualCoReachableSparseStates",
    "EndpointCoefficientAssemblyMethod" ->
      "PrecomputedModeEpsilonCoefficientsProjectedBeforeMaterialization",
    "PrunedConnectorChildCount" ->
      wordRecord["FirstChildrenPruned"] +
        wordRecord["SecondChildrenPruned"],
    "Stage3NeedsLedger" -> ledger
  |>
];

ComposeEndpointAutomatonPeriodWords[
    adapter_Association, transport_Association, wordPairs_List] := Catch@Module[
  {wordRepresentation, endpointTerms, periodCoordinates, outputTerms,
   pair, endpointTerm, map, usedColumns, ledger, family,
   preparedRecords, prepared, rowRange},
  If[Lookup[adapter, "Status", Missing["Absent"]] =!=
      "EndpointAutomatonBoundaryAdapterBuilt",
    Throw@failure["EndpointBoundaryAdapterRequired", <||>]
  ];
  wordRepresentation = Lookup[transport, "WordRepresentation", Missing["Absent"]];
  If[!MemberQ[{"OperatorAutomaton", "MaterializedWords"}, wordRepresentation] ||
      Lookup[adapter, "ObservableWordMapProvider", Missing["Absent"]] =!=
        wordRepresentation,
    Throw@failure["ObservableWordMapProviderMismatch", <|
      "AdapterProvider" -> Lookup[adapter, "ObservableWordMapProvider",
        Missing["Absent"]],
      "TransportProvider" -> wordRepresentation|>]
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
  endpointTerms = Lookup[adapter, "EndpointWordTerms", {}];
  periodCoordinates = Lookup[adapter, "PeriodCoordinates", {}];
  preparedRecords = Lookup[adapter, "PreparedDemandWordRecords", {}];
  outputTerms = Reap[
    Do[
      prepared = SelectFirst[preparedRecords,
        Lookup[#, "CurrentFirstWord", Missing["Absent"]] === First[pair] &&
          Lookup[#, "CurrentSecondWord", Missing["Absent"]] === Last[pair] &,
        Missing["NotPrepared"]];
      If[MissingQ[prepared],
        Throw@failure["EndpointDemandWordNotPrepared", <|
          "CurrentFirstWord" -> First[pair],
          "CurrentSecondWord" -> Last[pair],
          "PreparedDemandWordPairs" ->
            Lookup[adapter, "PreparedDemandWordPairs", {}]|>]
      ];
      rowRange = Lookup[prepared, "RowRange"];
      Do[
        map = Lookup[endpointTerm, "DemandProjectedMap"][[rowRange, All]];
        If[AnyTrue[Flatten[Normal[map]], Not@*exactZeroQ],
          Sow[<|
            "CurrentFirstWord" -> First[pair],
            "CurrentSecondWord" -> Last[pair],
            "EndpointFirstWord" -> Lookup[endpointTerm, "EndpointFirstWord"],
            "EndpointSecondWord" -> Lookup[endpointTerm, "EndpointSecondWord"],
            "Map" -> SparseArray[map]|>]
        ],
        {endpointTerm, endpointTerms}],
      {pair, wordPairs}]
    ][[2]];
  outputTerms = If[outputTerms === {}, {}, First[outputTerms]];
  usedColumns = Sort@DeleteDuplicates@Flatten[
    (Cases[First /@ ArrayRules[Lookup[#, "Map"]],
        {_, column_Integer} :> column]) & /@ outputTerms];
  usedColumns = Select[usedColumns, 1 <= # <= Length[periodCoordinates] &];
  ledger = pruneLedger[Lookup[adapter, "Stage3NeedsLedger", {}],
    periodCoordinates, usedColumns];
  <|
    "Status" -> "EndpointAutomatonPhysicalPeriodWordsBuilt",
    "Family" -> family,
    "PhysicalDemandPairs" -> Lookup[transport, "PhysicalDemandPairs", {}],
    "PeriodCoordinates" -> periodCoordinates,
    "WordMaps" -> outputTerms,
    "Stage3NeedsLedger" -> ledger
  |>
];

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

endpointCurrentRowSpaces[transport_Association] := Catch@Module[
  {representation, variables, path, baseRules, maximumWeight, automaton,
   initial, firstMatrices, firstBoundary, secondMatrices, finalEmbedding,
   firstByWeight = <||>, spaces = <||>, records, selected, matrices, rows,
   basis, firstState, secondState},
  representation = Lookup[transport, "WordRepresentation", Missing[]];
  variables = Lookup[transport, "Variables", Missing[]];
  path = Lookup[transport, "Path", <||>];
  If[! MatchQ[variables, {_Symbol, _Symbol}],
    Throw@failure["UnsupportedTransportVariables", <||>]];
  baseRules = Lookup[transport, "BoundaryBasePoint", Thread[variables ->
    {Lookup[path, "FirstBase", Missing[]],
      Lookup[path, "SecondBase", Missing[]]}]];
  If[! MatchQ[baseRules, {(_Rule | _RuleDelayed) ..}] ||
      ! FreeQ[Last /@ baseRules, _Missing],
    Throw@failure["MissingTransportBasePoint", <|"Path" -> path|>]];

  Switch[representation,
    "OperatorAutomaton",
      automaton = Lookup[transport, "ExactOperatorAutomaton", Missing[]];
      If[! AssociationQ[automaton],
        Throw@failure["OperatorAutomatonRequired", <||>]];
      maximumWeight = Lookup[automaton, "RequestedMaximumWeight", Missing[]];
      initial = endpointSpecializeMatrix[
        Lookup[automaton, "InitialDemandMap", Missing[]], baseRules];
      firstMatrices = endpointSpecializeMatrix[#, baseRules] & /@
        Lookup[automaton, "FirstOperatorMatrices", {}];
      firstBoundary = endpointSpecializeMatrix[
        Lookup[automaton, "FirstBoundaryOperator", Missing[]], baseRules];
      secondMatrices = endpointSpecializeMatrix[#, baseRules] & /@
        Lookup[automaton, "SecondOperatorMatrices", {}];
      finalEmbedding = endpointSpecializeMatrix[
        Lookup[automaton, "FinalBoundaryEmbedding", Missing[]], baseRules];
      If[! IntegerQ[maximumWeight] || maximumWeight < 0 ||
          MemberQ[Join[{initial, firstBoundary, finalEmbedding},
            firstMatrices, secondMatrices], $Failed] ||
          ! AllTrue[Join[{initial, firstBoundary, finalEmbedding},
            firstMatrices, secondMatrices], MatrixQ],
        Throw@failure["OperatorAutomatonIncomplete", <||>]];
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
        {weight, 0, maximumWeight}],

    "MaterializedWords",
      records = Lookup[transport, "TwoSegmentWordMaps", Missing[]];
      If[! ListQ[records] ||
          ! AllTrue[records, MatchQ[#, {_List, _List, _?MatrixQ}] &],
        Throw@failure["MaterializedObservableWordsRequired", <||>]];
      maximumWeight = Max[0, Sequence @@
        ((Length[#[[1]]] + Length[#[[2]]]) & /@ records)];
      Do[
        selected = Select[records,
          Length[#[[1]]] + Length[#[[2]]] === weight &];
        matrices = endpointSpecializeMatrix[#[[3]], baseRules] & /@ selected;
        If[MemberQ[matrices, $Failed],
          Throw@failure["CurrentPathWordSpecializationFailed", <|
            "Weight" -> weight|>]];
        rows = If[matrices === {}, {}, Join @@ matrices];
        basis = endpointExactRowBasis[rows];
        If[basis === $Failed,
          Throw@failure["CurrentPathRowSpaceFailed", <|"Weight" -> weight|>]];
        If[basis =!= {}, AssociateTo[spaces, weight -> SparseArray[basis]]],
        {weight, 0, maximumWeight}],

    _, Throw@failure["SupportedObservableWordRepresentationRequired", <|
      "WordRepresentation" -> representation|>]
  ];
  <|"Status" -> "CurrentObservableRowSpacesBuilt",
    "WordRepresentation" -> representation,
    "MaximumWeight" -> maximumWeight, "BaseRules" -> baseRules,
    "SpacesByWeight" -> spaces,
    "DimensionsByWeight" -> Association@KeyValueMap[
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
  {id = Lookup[coordinate, "PeriodID"],
   order = Lookup[coordinate, "EpsilonOrder"]},
  HoldComplete[id, order]];

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
    "Map" -> SparseArray[rules, {First[dimensions], globalCount}]|>]
];

endpointMergeStage3Ledger[ledgers_List, coordinates_List] := Module[
  {entries, groups},
  entries = Flatten[ledgers];
  groups = GatherBy[entries, Lookup[#, "PeriodID", Missing[]] &];
  Map[Function[group, Join[First[group], <|
      "AffectedBoundaryCoordinates" -> DeleteDuplicates@Select[
        Flatten[Lookup[group, "AffectedBoundaryCoordinates", {}]],
        MemberQ[coordinates, #] &]|>]], groups]
];

Options[BuildGradedPhysicalEndpointTransport] = {
  "PeriodOrderWindow" -> Automatic,
  "MaximumConnectorWords" -> 500000
};

BuildGradedPhysicalEndpointTransport[transport_Association,
    modeMap_Association, periodData_: <||>, OptionsPattern[]] := Catch@Module[
  {rowSpaces, maximumWeight, spaces, maximumWords, periodWindow,
   gradeRecords, synthetic, basis, projection, adapter, allCoordinates,
   coordinateIndex, globalCount, grades, ledgers, globalLedger,
   firstGrade, family},
  If[! MemberQ[{"ExactObservableTransport",
        "ModularlyVerifiedObservableTransport"},
      Lookup[transport, "Status", None]],
    Throw@failure["AcceptedObservableTransportRequired", <||>]];
  family = Lookup[transport, "Family", Missing[]];
  If[Lookup[modeMap, "Family", family] =!= family,
    Throw@failure["EndpointModeFamilyMismatch", <|
      "TransportFamily" -> family,
      "ModeFamily" -> Lookup[modeMap, "Family", Missing[]]|>]];
  maximumWords = OptionValue["MaximumConnectorWords"];
  periodWindow = OptionValue["PeriodOrderWindow"];
  If[! IntegerQ[maximumWords] || maximumWords < 1,
    Throw@failure["InvalidConnectorWordBudget", <||>]];
  rowSpaces = endpointCurrentRowSpaces[transport];
  If[FailureQ[rowSpaces], Throw[rowSpaces]];
  If[! AssociationQ[rowSpaces] ||
      Lookup[rowSpaces, "Status", None] =!=
        "CurrentObservableRowSpacesBuilt",
    Throw@failure["CurrentObservableRowSpacesRequired", <||>]];
  maximumWeight = rowSpaces["MaximumWeight"];
  spaces = rowSpaces["SpacesByWeight"];
  gradeRecords = Table[
    basis = Lookup[spaces, weight];
    projection = endpointBasisProjectionData[basis];
    If[projection === $Failed || projection["Inverse"] === $Failed,
      Throw@failure["CurrentPathBasisProjectionFailed", <|
        "Weight" -> weight|>]];
    synthetic = Join[transport, <|
      "WordRepresentation" -> "MaterializedWords",
      "TwoSegmentWordMaps" -> {{{}, {}, basis}}|>];
    adapter = BuildEndpointAutomatonBoundaryAdapter[
      synthetic, modeMap, periodData,
      "MaximumConnectorWeight" -> maximumWeight - weight,
      "MaximumConnectorWords" -> maximumWords,
      "PeriodOrderWindow" -> periodWindow,
      "DemandWordPairs" -> {{{}, {}}}];
    If[FailureQ[adapter] || Lookup[adapter, "Status", None] =!=
        "EndpointAutomatonBoundaryAdapterBuilt",
      Throw@failure["GradedEndpointAdapterFailed", <|
        "Weight" -> weight, "Result" -> adapter|>]];
    <|"CurrentWeight" -> weight, "CurrentRowBasis" -> basis,
      "ProjectionColumns" -> projection["Columns"],
      "ProjectionInverse" -> projection["Inverse"],
      "LocalPeriodCoordinates" -> adapter["PeriodCoordinates"],
      "LocalEndpointWordTerms" -> adapter["EndpointWordTerms"],
      "RequiredConnectorWeight" -> adapter["RequiredConnectorWeight"],
      "RetainedConnectorWordCount" ->
        adapter["RetainedConnectorWordCount"],
      "VisitedConnectorStateCount" ->
        adapter["VisitedConnectorStateCount"],
      "PrunedConnectorChildCount" -> adapter["PrunedConnectorChildCount"],
      "Stage3NeedsLedger" -> adapter["Stage3NeedsLedger"],
      "EndpointPath" -> adapter["Path"]|>,
    {weight, Keys[spaces]}];
  If[gradeRecords === {},
    Throw@failure["CurrentObservableRowSpacesEmpty", <||>]];
  allCoordinates = DeleteDuplicatesBy[
    Flatten[Lookup[gradeRecords, "LocalPeriodCoordinates", {}]],
    endpointCoordinateKey];
  coordinateIndex = AssociationThread[
    endpointCoordinateKey /@ allCoordinates,
    Range[Length[allCoordinates]]];
  globalCount = Length[allCoordinates];
  grades = Map[Function[grade, Join[
      KeyDrop[grade, {"LocalPeriodCoordinates", "LocalEndpointWordTerms"}],
      <|"EndpointWordTerms" ->
        (endpointExpandTermColumns[#,
            grade["LocalPeriodCoordinates"], coordinateIndex,
            globalCount] & /@ grade["LocalEndpointWordTerms"])|>]],
    gradeRecords];
  ledgers = Lookup[gradeRecords, "Stage3NeedsLedger", {}];
  globalLedger = endpointMergeStage3Ledger[ledgers, allCoordinates];
  firstGrade = First[grades];
  <|"Status" -> "GradedPhysicalEndpointTransportBuilt",
    "Family" -> family,
    "ObservableTransportStatus" -> Lookup[transport, "Status", Missing[]],
    "ObservableWordRepresentation" ->
      Lookup[transport, "WordRepresentation", Missing[]],
    "PhysicalDemandPairs" -> Lookup[transport, "PhysicalDemandPairs", {}],
    "MaximumCurrentWeight" -> maximumWeight,
    "CurrentBaseRules" -> rowSpaces["BaseRules"],
    "CurrentPath" -> Lookup[transport, "Path", <||>],
    "EndpointPath" -> firstGrade["EndpointPath"],
    "PeriodCoordinates" -> allCoordinates,
    "Stage3NeedsLedger" -> globalLedger,
    "GradesByWeight" -> AssociationThread[
      Lookup[grades, "CurrentWeight"], grades],
    "CurrentRowSpaceDimensions" -> rowSpaces["DimensionsByWeight"],
    "FormalResultConvention" -> <|
      "Segments" -> {"CurrentFirst", "CurrentSecond",
        "EndpointFirst", "EndpointSecond"},
      "WordOrientation" -> "OutermostFirst",
      "NoAlphabetCartesianEnumeration" -> True,
      "Coefficient" ->
        "Map . BoundaryPeriodCoefficient[RealizationKey,EpsilonOrder]"|>|>
];

BuildGradedPhysicalEndpointTransport[___] :=
  failure["GradedPhysicalEndpointTransportInputsNotWellFormed", <||>];

ComposeGradedPhysicalEndpointWords[binding_Association,
    transport_Association, wordPairs_List] := Catch@Module[
  {family, coordinates, grades, baseRules, outputTerms, wordResult, map,
   grade, columns, inverse, basisCoordinates, composed, usedColumns,
   ledger},
  If[Lookup[binding, "Status", None] =!=
      "GradedPhysicalEndpointTransportBuilt",
    Throw@failure["GradedPhysicalEndpointTransportRequired", <||>]];
  family = Lookup[transport, "Family", Missing[]];
  If[family =!= Lookup[binding, "Family", Missing[]],
    Throw@failure["EndpointAdapterFamilyMismatch", <||>]];
  If[! ListQ[wordPairs] ||
      ! AllTrue[wordPairs, MatchQ[#, {_List, _List}] &],
    Throw@failure["InvalidAutomatonWordRequest", <||>]];
  coordinates = binding["PeriodCoordinates"];
  grades = binding["GradesByWeight"];
  baseRules = binding["CurrentBaseRules"];
  outputTerms = Reap[Do[
      wordResult = transportObservableWordMap[
        transport, First[pair], Last[pair]];
      If[FailureQ[wordResult] || ! MatrixQ[Normal[wordResult]],
        Throw@failure["ObservableWordMapUnavailable", <|
          "WordPair" -> pair, "Result" -> wordResult|>]];
      map = endpointSpecializeMatrix[wordResult, baseRules];
      If[map === $Failed,
        Throw@failure["CurrentPathWordSpecializationFailed", <|
          "WordPair" -> pair|>]];
      (* An accepted automaton may have a requested maximum weight above
         its last nonzero row-space grade.  Such words are represented by
         the exact zero map, not by a missing grade. *)
      If[! AnyTrue[Flatten[map], Not@*exactZeroQ], Continue[]];
      grade = Lookup[grades, Length[First[pair]] + Length[Last[pair]],
        Missing["Weight"]];
      If[MissingQ[grade],
        Throw@failure["CurrentPathWeightUnavailable", <|
          "WordPair" -> pair|>]];
      columns = grade["ProjectionColumns"];
      inverse = grade["ProjectionInverse"];
      basisCoordinates = map[[All, columns]] . inverse;
      If[AnyTrue[Flatten[Together[
            basisCoordinates . Normal[grade["CurrentRowBasis"]] - map]],
          Not@*exactZeroQ],
        Throw@failure["CurrentPathRowSpaceMismatch", <|
          "WordPair" -> pair,
          "CurrentWeight" ->
            Length[First[pair]] + Length[Last[pair]]|>]];
      Do[
        composed = SparseArray[basisCoordinates . term["Map"]];
        If[AnyTrue[Flatten[Normal[composed]], Not@*exactZeroQ], Sow[<|
          "CurrentFirstWord" -> First[pair],
          "CurrentSecondWord" -> Last[pair],
          "EndpointFirstWord" -> term["EndpointFirstWord"],
          "EndpointSecondWord" -> term["EndpointSecondWord"],
          "Map" -> composed|>]],
        {term, grade["EndpointWordTerms"]}],
      {pair, wordPairs}]][[2]];
  outputTerms = If[outputTerms === {}, {}, First[outputTerms]];
  usedColumns = Sort@DeleteDuplicates@Flatten[
    Cases[First /@ ArrayRules[Lookup[#, "Map"]],
        {_, column_Integer} :> column] & /@ outputTerms];
  usedColumns = Select[usedColumns, 1 <= # <= Length[coordinates] &];
  ledger = pruneLedger[binding["Stage3NeedsLedger"], coordinates,
    usedColumns];
  <|"Status" -> "GradedPhysicalEndpointWordsBuilt",
    "Family" -> family,
    "PhysicalDemandPairs" -> binding["PhysicalDemandPairs"],
    "PeriodCoordinates" -> coordinates,
    "WordMaps" -> outputTerms,
    "Stage3NeedsLedger" -> ledger,
    "FormalResultConvention" -> binding["FormalResultConvention"]|>
];

ComposeGradedPhysicalEndpointWords[___] :=
  failure["GradedPhysicalEndpointWordInputsNotWellFormed", <||>];

End[];
EndPackage[];
