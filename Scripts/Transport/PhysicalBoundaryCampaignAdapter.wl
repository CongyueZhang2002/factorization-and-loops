(* ::Package:: *)

BeginPackage["FeynFacetCampaign`PhysicalBoundary`"];

BuildEndpointAutomatonBoundaryAdapter::usage =
  "BuildEndpointAutomatonBoundaryAdapter[transport, modeMap, periodData] builds the " <>
  "finite endpoint-to-interior word map needed to feed singular zero modes into an " <>
  "OperatorAutomaton observable transport.  The returned coordinate maps are rational; " <>
  "unevaluated periods are represented only by BoundaryPeriodCoefficient[id, order].";

ComposeEndpointAutomatonPeriodWords::usage =
  "ComposeEndpointAutomatonPeriodWords[adapter, transport, wordPairs] composes endpoint " <>
  "connection words with selected OperatorAutomaton words and returns period-coordinate maps.";

EndpointConnectionWord::usage =
  "EndpointConnectionWord[path, firstWord, secondWord] is the inert Chen word " <>
  "multiplying an endpoint-to-interior boundary-coordinate map.";

Begin["`Private`"];

ClearAll[exactZeroQ, failure, wordProduct, leadingEpsilonOrder,
  independentEmbeddingRows, modeVector, endpointModeStatus,
  endpointModePeriodRecord, endpointResidueMatrix, reachableWordPairs,
  operatorAutomatonWordMap, stage3Entry, pruneLedger];

exactZeroQ[x_] := TrueQ[x === 0] || TrueQ[PossibleZeroQ[x]];

failure[tag_String, details_Association] :=
  Failure[tag, Join[<|"Status" -> tag|>, details]];

wordProduct[matrices_Association, word_List, dimension_Integer] :=
  Fold[Dot, IdentityMatrix[dimension], Lookup[matrices, word]];

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
  Lookup[periodData, periodID, Lookup[periodData, ToString[periodID], <||>]];

endpointResidueMatrix[kernels_Association, matrices_Association, variable_Symbol, endpoint_] :=
  Total[
    (Limit[(variable - endpoint) Lookup[kernels, #], variable -> endpoint] Lookup[matrices, #]) & /@
      Keys[kernels]
  ];

reachableWordPairs[firstIndices_List, secondIndices_List,
    matrices_Association, seedMatrix_, maximumWeight_Integer,
    maximumWords_Integer] := Catch@Module[
  {secondLevel = {{{}, seedMatrix}}, nextSecond, firstLevel, nextFirst,
   result, count = 0, action, appendResult, nonzeroActionQ, secondState,
   firstState, index, secondWeight, firstWeight, harvested},
  nonzeroActionQ[current_] := AnyTrue[Flatten[current], Not@*exactZeroQ];
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
        Scan[(appendResult[{First[#], First[secondState]}]) &, firstLevel];
        If[firstWeight < maximumWeight - secondWeight,
          nextFirst = Flatten[Table[
            action = Lookup[matrices, index] . Last[firstState];
            If[nonzeroActionQ[action],
              {{Prepend[First[firstState], index], action}}, {}],
            {firstState, firstLevel}, {index, firstIndices}], 2];
          firstLevel = nextFirst
        ],
        {firstWeight, 0, maximumWeight - secondWeight}],
      {secondState, secondLevel}];
    If[secondWeight < maximumWeight,
      nextSecond = Flatten[Table[
        action = Lookup[matrices, index] . Last[secondState];
        If[nonzeroActionQ[action],
          {{Prepend[First[secondState], index], action}}, {}],
        {secondState, secondLevel}, {index, secondIndices}], 2];
      secondLevel = nextSecond
    ],
    {secondWeight, 0, maximumWeight}], "ReachableWord"][[2]];
  result = If[harvested === {}, {}, First[harvested]];
  DeleteDuplicates[result]
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
  "PeriodOrderWindow" -> Automatic
};

BuildEndpointAutomatonBoundaryAdapter[
    transport_Association, modeMap_Association, periodData_: <||>,
    OptionsPattern[]] := Catch@Module[
  {automaton, path, variables, regulator, family, letters, residues, dimension,
   endpointSpec, endpointVariable, endpoint, fixedRules, firstVariable,
   secondVariable, firstBase, secondBase, fixedFirst, secondKernels,
   firstKernels, secondIndices, firstIndices, matrixAssociation,
   endpointResidue, modes, realizedModes, modeVectors, recordByID,
   knownZeroByID, statusByID, valuationByID, modeOrderByID,
   ambientSlots, embedding, pivotData, pivotRows, pivotSlots, pivotInverse,
   maximumWeight, maximumWords, periodWindow, periodCoordinates,
   wordPairs, endpointTerms, activeColumns, ledger,
   demandedOutputs, pathDescriptor, requestedWordCount, rawMap,
   product, weight, coordinate, id, q, mode, vector, betaMap,
   endpointAction, status, term, active, coefficient, order, row,
   localCoordinatePower, localCoordinateLeadingCoefficient,
   physicalEndpointRelation, formalModeIDs, seedMatrix,
   requiredConnectorWeight, realizationKey},

  automaton = Lookup[transport, "ExactOperatorAutomaton",
    Lookup[transport, "WordAutomaton", Missing["Absent"]]];
  If[!AssociationQ[automaton] ||
      Lookup[transport, "WordRepresentation", Missing["Absent"]] =!= "OperatorAutomaton",
    Throw@failure["OperatorAutomatonRequired", <||>]
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
  endpointSpec = Join[<|
      "Stratum" -> Lookup[Lookup[modeMap, "Limit", <||>],
        "Stratum", Lookup[physicalEndpointRelation, "Stratum", Missing["Absent"]]],
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
    endpointAction = Together[endpointResidue . Lookup[modeVectors,
      Lookup[mode, "PeriodID"]]];
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
      MemberQ[{"KnownZero", "ExactZero"}, Lookup[Lookup[recordByID, id], "Status", None]]),
    {id, Keys[modeVectors]}];
  statusByID = Association@Table[
    id -> If[TrueQ@Lookup[knownZeroByID, id], "KnownZero", "Unevaluated"],
    {id, Keys[modeVectors]}];
  valuationByID = Association@Table[
    id -> Lookup[Lookup[recordByID, id], "EpsilonValuation",
      Lookup[SelectFirst[realizedModes, Lookup[#, "PeriodID"] === id &],
        "PeriodEpsilonValuation", 0]],
    {id, Keys[modeVectors]}];
  If[!And @@ (IntegerQ /@ Values[valuationByID]),
    Throw@failure["MissingPeriodEpsilonValuation", <|
      "Valuations" -> valuationByID|>]
  ];
  modeOrderByID = Association@Table[
    id -> Min[leadingEpsilonOrder[#, regulator] & /@ Lookup[modeVectors, id]],
    {id, Keys[modeVectors]}];

  ambientSlots = Lookup[transport, "BoundaryAmbientSlots", Missing["Absent"]];
  embedding = Lookup[automaton, "FinalBoundaryEmbedding", Missing["Absent"]];
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
    If[TrueQ@Lookup[knownZeroByID, id], {},
      realizationKey = Lookup[Lookup[recordByID, id], "RealizationKey",
        If[TrueQ@Lookup[Lookup[recordByID, id], "ClassIdentityExact", False],
          id, {family, id}]];
      Table[<|"PeriodID" -> id, "RealizationKey" -> realizationKey,
        "EpsilonOrder" -> q,
        "Coefficient" -> FeynFacet`BoundaryPeriodCoefficient[realizationKey, q],
        "Status" -> Lookup[statusByID, id]|>,
        {q, Max[First[periodWindow], Lookup[valuationByID, id]], Last[periodWindow]}]],
    {id, Keys[modeVectors]}];
  requiredConnectorWeight = If[periodCoordinates === {}, 0,
    Max[0, Max@Table[
      id = Lookup[coordinate, "PeriodID"];
      q = Lookup[coordinate, "EpsilonOrder"];
      Max[pivotSlots[[All, 1]]] - q - Lookup[modeOrderByID, id],
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
      "Reason" -> "The requested period and automaton boundary orders need higher endpoint words"|>]
  ];
  formalModeIDs = Select[Keys[modeVectors], !TrueQ@Lookup[knownZeroByID, #] &];
  seedMatrix = If[formalModeIDs === {}, ConstantArray[0, {dimension, 0}],
    Transpose[Lookup[modeVectors, formalModeIDs]]];
  wordPairs = If[formalModeIDs === {}, {{{}, {}}},
    reachableWordPairs[firstIndices, secondIndices, matrixAssociation,
      seedMatrix, maximumWeight, maximumWords]];
  If[FailureQ[wordPairs], Throw[wordPairs]];
  requestedWordCount = Length[wordPairs];

  endpointTerms = Reap[
    Do[
      weight = Length[First[term]] + Length[Last[term]];
      product = wordProduct[matrixAssociation, First[term], dimension] .
        wordProduct[matrixAssociation, Last[term], dimension];
      rawMap = Table[
        coordinate = periodCoordinates[[coordinateColumn]];
        id = Lookup[coordinate, "PeriodID"];
        q = Lookup[coordinate, "EpsilonOrder"];
        vector = product . Lookup[modeVectors, id];
        Table[
          {order, row} = pivotSlots[[slot]];
          coefficient = Quiet@Check[
            SeriesCoefficient[
              regulator^weight vector[[row]], {regulator, 0, order - q}],
            $Failed];
          If[coefficient === $Failed,
            Throw@failure["EndpointCoefficientExtractionFailed", <|
              "PeriodID" -> id, "PeriodOrder" -> q,
              "BoundarySlot" -> pivotSlots[[slot]],
              "EndpointFirstWord" -> First[term],
              "EndpointSecondWord" -> Last[term]|>]
          ];
          Together[coefficient],
          {slot, Length[pivotSlots]}],
        {coordinateColumn, Length[periodCoordinates]}];
      rawMap = If[periodCoordinates === {},
        ConstantArray[0, {Length[pivotSlots], 0}], Transpose[rawMap]];
      betaMap = Together[pivotInverse . rawMap];
      If[Length[periodCoordinates] > 0 &&
          AnyTrue[Flatten[betaMap], Not@*exactZeroQ],
        Sow[<|"EndpointFirstWord" -> First[term],
          "EndpointSecondWord" -> Last[term], "Map" -> SparseArray[betaMap]|>]
      ],
      {term, wordPairs}]
    ][[2]];
  endpointTerms = If[endpointTerms === {}, {}, First[endpointTerms]];
  activeColumns = Sort@DeleteDuplicates@Flatten[
    Map[
      Function[currentTerm,
        active = DeleteDuplicates@Cases[
          First /@ ArrayRules[Lookup[currentTerm, "Map"]],
          {_, column_Integer} :> column];
        Select[active, 1 <= # <= Length[periodCoordinates] &]],
      endpointTerms]];
  If[activeColumns =!= Range[Length[periodCoordinates]],
    endpointTerms = endpointTerms /. currentTerm_Association :>
      Join[currentTerm, <|"Map" -> Lookup[currentTerm, "Map"][[All, activeColumns]]|>];
    periodCoordinates = If[activeColumns === {}, {}, periodCoordinates[[activeColumns]]]
  ];

  demandedOutputs = Lookup[transport, "PhysicalDemandPairs", {}];
  ledger = Table[
    id = Lookup[mode, "PeriodID"];
    status = Lookup[statusByID, id];
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
    "Regulator" -> regulator,
    "EndpointModeMapStatus" -> Lookup[modeMap, "Status", Missing["Absent"]],
    "Path" -> pathDescriptor,
    "AutomatonBoundaryDimension" -> Last[Dimensions[Normal[embedding]]],
    "BoundaryAmbientSlots" -> ambientSlots,
    "BoundaryCoordinateConvention" -> <|
      "EmbeddingPivotRows" -> pivotRows,
      "Definition" -> "LexicographicallyFirstExactLeftInverse"|>,
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
    "Stage3NeedsLedger" -> ledger
  |>
];

ComposeEndpointAutomatonPeriodWords[
    adapter_Association, transport_Association, wordPairs_List] := Catch@Module[
  {automaton, endpointTerms, periodCoordinates, outputTerms, currentMap,
   pair, endpointTerm, map, usedColumns, ledger, family},
  If[Lookup[adapter, "Status", Missing["Absent"]] =!=
      "EndpointAutomatonBoundaryAdapterBuilt",
    Throw@failure["EndpointBoundaryAdapterRequired", <||>]
  ];
  automaton = Lookup[transport, "ExactOperatorAutomaton",
    Lookup[transport, "WordAutomaton", Missing["Absent"]]];
  If[!AssociationQ[automaton] ||
      Lookup[transport, "WordRepresentation", Missing["Absent"]] =!= "OperatorAutomaton",
    Throw@failure["OperatorAutomatonRequired", <||>]
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
  outputTerms = Reap[
    Do[
      currentMap = Quiet@Check[
        operatorAutomatonWordMap[automaton, First[pair], Last[pair]],
        $Failed];
      If[currentMap === $Failed || FailureQ[currentMap] || !MatrixQ[Normal[currentMap]],
        Throw@failure["AutomatonWordMapUnavailable", <|
          "CurrentFirstWord" -> First[pair],
          "CurrentSecondWord" -> Last[pair]|>]
      ];
      Do[
        map = Together[currentMap . Lookup[endpointTerm, "Map"]];
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

End[];
EndPackage[];
