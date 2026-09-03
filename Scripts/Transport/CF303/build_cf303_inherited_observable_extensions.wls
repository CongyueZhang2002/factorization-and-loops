#!/usr/bin/env wolframscript

Block[{$HistoryLength = 0}, Catch@Module[
 {scriptDirectory, repository, transportDirectory, formDirectory, outputPath,
  specifications, exactZeroQ, exactZeroArrayQ, demandRow, sparseEntries,
  completedEndpointMode, familyRecords, result, specification, record},

scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
repository = DirectoryName[scriptDirectory, 3];
transportDirectory = FileNameJoin[{repository, "ppHX_NNLO_DoubleReal",
  "Results", "UU_08_10_canonical", "ObservableTransport_2026-09-01_codex",
  "families"}];
formDirectory = FileNameJoin[{repository, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsCertified"}];
outputPath = FileNameJoin[{scriptDirectory, "Artifacts",
  "CF303InheritedObservableExtensions.wl"}];

Get[FileNameJoin[{repository, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{repository, "Scripts", "Transport",
  "PhysicalBoundaryCampaignAdapter.wl"}]];

specifications = {
  <|"Family" -> "CF12", "Missing" -> {{2, 4, 6}}|>,
  <|"Family" -> "CF199", "Missing" -> {{2, 1, 8}, {3, 2, 9}},
    "EndpointSpec" -> <|"Variable" -> y, "Endpoint" -> 1 - p^2,
      "FixedRules" -> {x -> p^2}, "Stratum" -> "1-v-w=0"|>,
    "PrescribedModeEntries" -> {{8, 2}, {9, -3}},
    "ExpectedCompletedModeEntries" -> {{8, 2}, {9, -3}},
    "PeriodID" -> 9|>,
  <|"Family" -> "CF53", "Missing" -> {{2, 4, 11}, {3, 5, 12}},
    "EndpointSpec" -> <|"Variable" -> y, "Endpoint" -> p,
      "FixedRules" -> {x -> -p}, "Stratum" -> "1-v-w=0"|>,
    "PrescribedModeEntries" -> {{11, 2}, {12, -3}},
    "ExpectedCompletedModeEntries" -> {{11, 2}, {12, -3}, {13, -2/5}},
    "PeriodID" -> 9|>
};

exactZeroQ[value_] := TrueQ[value === 0] || TrueQ[PossibleZeroQ[value]];
exactZeroArrayQ[array_] := And @@ (exactZeroQ /@ Flatten[array]);

demandRow[gauge_, regulator_, slots_, pair_] := Table[
  SeriesCoefficient[gauge[[Last[pair], Last[slot]]],
    {regulator, 0, First[pair] - First[slot]}],
  {slot, slots}];

sparseEntries[matrix_] := Cases[
  Most[ArrayRules[SparseArray[matrix]]],
  HoldPattern[{row_Integer, column_Integer} -> value_] :>
    <|"Row" -> row, "Column" -> column, "Value" -> value|>];

completedEndpointMode[transport_, specification_] := Module[
  {variable, endpoint, fixedRules, normalResidue, dimension,
   prescribedEntries, prescribedRows, prescribedValues, constraints,
   vector, entries},
  variable = specification["EndpointSpec"]["Variable"];
  endpoint = specification["EndpointSpec"]["Endpoint"];
  fixedRules = specification["EndpointSpec"]["FixedRules"];
  normalResidue = Total@MapThread[
    Limit[(variable - endpoint) (D[#1, variable]/#1 /. fixedRules),
      variable -> endpoint] #2 &,
    {transport["DLogLetters"], transport["DLogResidues"]}];
  dimension = Length[normalResidue];
  prescribedEntries = specification["PrescribedModeEntries"];
  prescribedRows = Range[Max[First /@ prescribedEntries]];
  prescribedValues = ConstantArray[0, Length[prescribedRows]];
  Do[prescribedValues[[First[entry]]] = Last[entry],
    {entry, prescribedEntries}];
  constraints = IdentityMatrix[dimension][[prescribedRows]];
  vector = Quiet@Check[LinearSolve[
    Join[normalResidue, constraints],
    Join[ConstantArray[0, dimension], prescribedValues]], $Failed];
  If[vector === $Failed,
    Return[Failure["PhysicalEndpointModeCompletionFailed", <|
      "Family" -> specification["Family"]|>]]];
  entries = Cases[MapIndexed[{First[#2], #1} &, vector],
    {_, value_} /; !exactZeroQ[value]];
  If[entries =!= specification["ExpectedCompletedModeEntries"] ||
      !exactZeroArrayQ[normalResidue . vector],
    Return[Failure["PhysicalEndpointModeCompletionMismatch", <|
      "Family" -> specification["Family"],
      "ExpectedEntries" -> specification["ExpectedCompletedModeEntries"],
      "ActualEntries" -> entries|>]]];
  <|"ModeMap" -> <|
      "Status" -> "BoundaryModeMapBuilt",
      "Family" -> specification["Family"],
      "EndpointSpec" -> specification["EndpointSpec"],
      "Modes" -> {<|"Status" -> "BoundaryModeMatched",
        "PeriodID" -> specification["PeriodID"],
        "CanonicalModeEntries" -> entries,
        "LocalEigenvalue" -> 0, "GeneralizedLevel" -> 0,
        "PeriodEpsilonValuation" -> -1,
        "Support" -> First /@ entries|>}|>,
    "NormalResidueDimensions" -> Dimensions[normalResidue],
    "CompletedModeEntries" -> entries|>
];

familyRecords = Table[Module[
  {family, transport, form, regulator, gauge, slots, existingRows,
   existingDemand, replay, missingTriples, missingPairs, missingRows,
   derivedTransport, modeResult, adapterTiming, adapter, compositionTiming,
   composition, endpointTransport, baseEmbedding, finalEmbedding},
  family = specification["Family"];
  transport = Get[FileNameJoin[{transportDirectory,
    "observable_transport_" <> family <> ".wl"}]];
  form = Get[FileNameJoin[{formDirectory,
    "family_epsform_" <> family <> ".wl"}]];
  regulator = form["Regulator"];
  gauge = form["TTotal"] /. Lookup[transport, "GaugeConstantRules", {}];
  slots = transport["BoundaryAmbientSlots"];
  existingRows = transport["PhysicalRows"];
  existingDemand = Normal[
    transport["ExactOperatorAutomaton"]["InitialDemandMap"]];
  replay = MapThread[
    exactZeroArrayQ[demandRow[gauge, regulator, slots, #1] - #2] &,
    {existingRows, existingDemand}];
  If[!And @@ replay,
    Throw@Failure["ExistingObservableDemandReplayMismatch", <|
      "Family" -> family, "Matched" -> Count[replay, True],
      "Total" -> Length[replay]|>]];
  missingTriples = specification["Missing"];
  missingPairs = ({First[#], Last[#]} &) /@ missingTriples;
  missingRows = demandRow[gauge, regulator, slots, #] & /@ missingPairs;
  derivedTransport = Join[transport, <|
    "PhysicalRows" -> missingPairs,
    "PhysicalDemandPairs" -> missingPairs,
    "ExactOperatorAutomaton" -> Join[transport["ExactOperatorAutomaton"],
      <|"InitialDemandMap" -> SparseArray[missingRows]|>]|>];
  baseEmbedding = transport["BoundaryBaseEmbedding"];
  finalEmbedding = transport["ExactOperatorAutomaton"][
    "FinalBoundaryEmbedding"];
  endpointTransport = If[!KeyExistsQ[specification, "EndpointSpec"],
    <|"Status" -> "PhysicalModeRealizationRequired",
      "Reason" ->
       "The CF12 class-5 soft zero mode has no accepted endpoint realization or nullity-period identity; no PeriodID is inferred"|>,
    modeResult = completedEndpointMode[transport, specification];
    If[FailureQ[modeResult], Throw[modeResult]];
    adapterTiming = AbsoluteTiming[
      adapter = FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
        derivedTransport, modeResult["ModeMap"], <||>,
        "PeriodOrderWindow" -> {-1, 5},
        "MaximumConnectorWords" -> 500000,
        "DemandWordPairs" -> {{{}, {}}}]];
    If[FailureQ[adapter] || Lookup[adapter, "Status", None] =!=
        "EndpointAutomatonBoundaryAdapterBuilt",
      Throw@Failure["EndpointBoundaryAdapterBuildFailed", <|
        "Family" -> family, "Result" -> adapter|>]];
    compositionTiming = AbsoluteTiming[
      composition = FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords[
        adapter, derivedTransport, {{{}, {}}}]];
    If[FailureQ[composition] || Lookup[composition, "Status", None] =!=
        "EndpointAutomatonPhysicalPeriodWordsBuilt",
      Throw@Failure["EndpointPeriodWordCompositionFailed", <|
        "Family" -> family, "Result" -> composition|>]];
    <|"Status" -> "FormalPhysicalPeriodWordsBuilt",
      "ModeCompletion" -> KeyDrop[modeResult, "ModeMap"],
      "AdapterSeconds" -> First[adapterTiming],
      "CompositionSeconds" -> First[compositionTiming],
      "RequiredConnectorWeight" -> adapter["RequiredConnectorWeight"],
      "VisitedConnectorStateCount" -> adapter["VisitedConnectorStateCount"],
      "EnumeratedConnectorWordCount" -> adapter["EnumeratedConnectorWordCount"],
      "RetainedConnectorWordCount" -> adapter["RetainedConnectorWordCount"],
      "PrunedConnectorChildCount" -> adapter["PrunedConnectorChildCount"],
      "DemandVisibleAmbientSlotMaximum" ->
        adapter["DemandVisibleAmbientSlotMaximum"],
      "BoundaryCoordinateConvention" ->
        adapter["BoundaryCoordinateConvention"],
      "Path" -> adapter["Path"],
      "PeriodCoordinates" -> composition["PeriodCoordinates"],
      "WordMaps" -> composition["WordMaps"],
      "Stage3NeedsLedger" -> composition["Stage3NeedsLedger"]|>
  ];
  <|"Family" -> family,
    "SourceTransportStatus" -> transport["Status"],
    "BoundaryEvolution" -> <|
      "Method" -> Lookup[transport, "BoundaryEvolutionMethod", Missing["Absent"]],
      "AmbientSlotCount" -> Length[slots],
      "BoundaryBaseEmbeddingDimensions" -> Dimensions[Normal[baseEmbedding]],
      "AutomatonFinalEmbeddingDimensions" -> Dimensions[Normal[finalEmbedding]]|>,
    "ExistingDemandReplay" -> <|"Matched" -> Count[replay, True],
      "Total" -> Length[replay]|>,
    "DemandExtension" -> <|
      "OriginalRows" -> missingTriples[[All, 2]],
      "PhysicalDemandPairs" -> missingPairs,
      "InitialDemandDimensions" -> Dimensions[missingRows],
      "InitialDemandEntries" -> sparseEntries[missingRows]|>,
    "EndpointPeriodTransport" -> endpointTransport|>
  ],
  {specification, specifications}];

result = <|
  "Status" -> "CF303InheritedObservableExtensionsBuiltV1",
  "Family" -> "CF303",
  "Scope" ->
   "Exactly five previously absent lower-family observable coefficients and their demanded soft-endpoint period words",
  "RequestedLowerRows" -> {
    <|"Family" -> "CF12", "OriginalRow" -> 4, "EpsilonOrder" -> 2|>,
    <|"Family" -> "CF199", "OriginalRow" -> 1, "EpsilonOrder" -> 2|>,
    <|"Family" -> "CF199", "OriginalRow" -> 2, "EpsilonOrder" -> 3|>,
    <|"Family" -> "CF53", "OriginalRow" -> 4, "EpsilonOrder" -> 2|>,
    <|"Family" -> "CF53", "OriginalRow" -> 5, "EpsilonOrder" -> 3|>},
  "Families" -> familyRecords,
  "Stage3BoundarySemantics" -> <|
    "CF199AndCF53" ->
     "Formal realization-local PID9 coefficients; not evaluated and not transferred",
    "CF12" ->
     "Typed incomplete until its class-5 physical soft mode is realized",
    "TargetComposition" ->
     "These are physical F_source columns. Apply the separate regularized G25=F25-H F_source junction once; do not count the source extension twice"|>,
  "CompleteForCF303TargetComposition" -> False,
  "RemainingNeeds" -> {
    "A physical realization for the CF12 class-5 soft zero mode",
    "Evaluation or justified realization transfer for the separate CF199 and CF53 PID9 coefficient series",
    "Composition with the regularized target G25 junction map"}
|>;

Put[result, outputPath];
Print["PASS output=", outputPath];
Do[Print[record["Family"], " replay=",
    record["ExistingDemandReplay"]["Matched"], "/",
    record["ExistingDemandReplay"]["Total"], " endpoint=",
    KeyTake[record["EndpointPeriodTransport"], {"Status", "AdapterSeconds",
      "VisitedConnectorStateCount", "RetainedConnectorWordCount"}]],
  {record, familyRecords}];
result
]]
