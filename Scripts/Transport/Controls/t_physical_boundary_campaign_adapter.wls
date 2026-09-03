#!/usr/bin/env wolframscript

Block[{$HistoryLength = 0}, Module[
 {repo, history, controlHistory, transportRoot, checks, check,
  loadAssociation, control, cf299, cf407, exactZeroArrayQ,
  nonzeroPositions, sparseFromEntries, historicalControl, control299,
  control407, transportForFailure, modeForFailure, logMode, logFailure,
  unpreparedIndex, materializedTransport, materializedResidue,
  materializedMode, materializedModeMap, materializedTiming,
  materializedAdapter, materializedComposition, materializedStoredMap,
  materializedProvidedMap, summary, testResult},

repo = ExpandFileName@FileNameJoin[{DirectoryName[$InputFileName], "..", "..", ".."}];
history = "/home/maxzhang/factorization-and-loops-codex/External/CodexExchange/endpoint_matching_2026-08-17";
controlHistory = FileNameJoin[{repo, "Codex", "ppHX_NNLO_DoubleReal",
  "TransportProjection_2026-08-17"}];
transportRoot = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "ObservableTransport_2026-09-01_codex", "families"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{repo, "Scripts", "Transport", "PhysicalBoundaryCampaignAdapter.wl"}]];

checks = {};
check[name_, condition_] := AppendTo[checks, name -> TrueQ[condition]];

loadAssociation[path_] := Get[path];

control[family_String, currentFile_String, modeFile_String] := Module[
  {transport, modeMap, adapter, composed, adapterTiming, compositionTiming},
  transport = loadAssociation[FileNameJoin[{transportRoot, currentFile}]];
  modeMap = loadAssociation[FileNameJoin[{history, modeFile}]];
  adapterTiming = AbsoluteTiming[
    adapter = FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
      transport, modeMap, <||>, "MaximumConnectorWeight" -> Automatic,
      "PeriodOrderWindow" -> {0, 2}]];
  check[family <> " adapter built",
    AssociationQ[adapter] && Lookup[adapter, "Status", None] ===
      "EndpointAutomatonBoundaryAdapterBuilt"];
  If[FailureQ[adapter] || !AssociationQ[adapter],
    Print[family <> " failure: ", InputForm[adapter]];
    Return[adapter]
  ];
  compositionTiming = AbsoluteTiming[
    composed = FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords[
      adapter, transport, {{{}, {}}}]];
  check[family <> " composition built",
    AssociationQ[composed] && Lookup[composed, "Status", None] ===
      "EndpointAutomatonPhysicalPeriodWordsBuilt"];
  check[family <> " endpoint differs from interior base",
    Lookup[Lookup[Lookup[adapter, "Path"], "Endpoint"], "Point"] =!=
      Lookup[Lookup[Lookup[adapter, "Path"], "InteriorBase"], "Point"]];
  check[family <> " both endpoint-to-interior segments are retained",
    Length[Lookup[Lookup[adapter, "Path"], "Segments", {}]] === 2 &&
      AnyTrue[Lookup[adapter, "EndpointWordTerms", {}],
        Length[Lookup[#, "EndpointFirstWord", {}]] +
          Length[Lookup[#, "EndpointSecondWord", {}]] === 1 &]];
  check[family <> " formal ledger present",
    AnyTrue[Lookup[adapter, "Stage3NeedsLedger", {}],
      Lookup[#, "Status", None] === "Unevaluated" &]];
  <|"Adapter" -> adapter, "Composition" -> composed,
    "AdapterSeconds" -> First[adapterTiming],
    "CompositionSeconds" -> First[compositionTiming]|>
];

cf299 = control["CF299", "observable_transport_CF299.wl", "BoundaryModeMap_CF299.wl"];
cf407 = control["CF407", "observable_transport_CF407.wl", "BoundaryModeMap_CF407.wl"];

(* CF123 is an intentionally cheap provider control: its accepted transport
   stores direct two-segment word maps and no lazy automaton.  A known-zero
   residue mode exercises retrieval without claiming a new physical period. *)
materializedTransport = loadAssociation[
  FileNameJoin[{transportRoot, "observable_transport_CF123.wl"}]];
materializedStoredMap = SelectFirst[
  materializedTransport["TwoSegmentWordMaps"],
  First[#] === {} && #[[2]] === {} &][[3]];
materializedProvidedMap =
  FeynFacetCampaign`PhysicalBoundary`Private`transportObservableWordMap[
    materializedTransport, {}, {}];
check["CF123 materialized provider returns the exact stored word map",
  TrueQ[materializedProvidedMap === materializedStoredMap]];
materializedResidue = Total@MapThread[
  Limit[(y - (1 - p^2)) (D[#1, y]/#1 /. x -> p^2),
    y -> 1 - p^2] #2 &,
  {materializedTransport["DLogLetters"],
    materializedTransport["DLogResidues"]}];
materializedMode = First[NullSpace[materializedResidue]];
materializedModeMap = <|"Status" -> "BoundaryModeMapBuilt",
  "Family" -> "CF123",
  "EndpointSpec" -> <|"Variable" -> y, "Endpoint" -> 1 - p^2,
    "FixedRules" -> {x -> p^2}, "Stratum" -> "1-v-w=0"|>,
  "Modes" -> {<|"Status" -> "BoundaryModeMatched",
    "PeriodID" -> "MaterializedProviderControl",
    "CanonicalMode" -> materializedMode,
    "LocalEigenvalue" -> 0, "GeneralizedLevel" -> 0,
    "KnownCoefficient" -> 0, "PeriodEpsilonValuation" -> 0,
    "Support" -> Flatten@Position[materializedMode,
      _?(Not@*PossibleZeroQ)]|>}|>;
materializedTiming = AbsoluteTiming[
  materializedAdapter =
    FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
      materializedTransport, materializedModeMap, <||>,
      "MaximumConnectorWeight" -> 0, "MaximumConnectorWords" -> 100,
      "PeriodOrderWindow" -> {0, 0}]];
materializedComposition = If[AssociationQ[materializedAdapter],
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords[
    materializedAdapter, materializedTransport, {{{}, {}}}],
  materializedAdapter];
check["CF123 accepted materialized-word provider is consumed directly",
  AssociationQ[materializedAdapter] &&
    materializedAdapter["ObservableWordMapProvider"] === "MaterializedWords" &&
    AssociationQ[materializedComposition] &&
    materializedComposition["Status"] ===
      "EndpointAutomatonPhysicalPeriodWordsBuilt" &&
    materializedComposition["WordMaps"] === {}];

exactZeroArrayQ[array_] := And @@ (TrueQ[PossibleZeroQ[#]] & /@ Flatten[array]);
nonzeroPositions[array_] := ({#[[1, 1]], #[[1, 2]]} &) /@
  Most[ArrayRules[SparseArray[array]]];
sparseFromEntries[entries_, shape_] := SparseArray[
  ({#[[1]], #[[2]]} -> #[[3]]) & /@ entries, shape];

historicalControl[family_String, currentFile_String, modeFile_String] := Module[
  {transport, modeMap, adapter, composed, spectator, historical,
   endpointFrobenius, historicalResidue, currentResidue,
   currentEndpointConnection, currentRegularConnection,
   historicalRegularCoefficients, currentRegularCoefficients,
   coordinates, epsilon, dimension, vectors, coordinateMap, oldRows,
   newRows, rowPositions, baseRules, oldMatrix, oldProjected,
   newProjected, oldZero, newZero, oldFirst, newFirst, oldSecond,
   newSecond, firstKernels, secondKernels, selected, item, matrix,
   kernel, periodID, periodOrder, slotOrder, slotRow, firstSegment,
   secondSegment, coordinate},
  transport = loadAssociation[FileNameJoin[{transportRoot, currentFile}]];
  modeMap = loadAssociation[FileNameJoin[{history, modeFile}]];
  adapter = If[family === "CF299", cf299["Adapter"], cf407["Adapter"]];
  composed = If[family === "CF299", cf299["Composition"], cf407["Composition"]];
  spectator = loadAssociation[FileNameJoin[{controlHistory,
    "SpectatorSystem_" <> family <> ".wl"}]];
  historical = loadAssociation[FileNameJoin[{controlHistory,
    "TwoSegmentObservableTransport_" <> family <> ".wl"}]];
  endpointFrobenius = loadAssociation[FileNameJoin[{controlHistory,
    "EndpointFrobenius_" <> family <> ".wl"}]];
  coordinates = adapter["PeriodCoordinates"];
  epsilon = transport["Regulator"];
  dimension = Max[spectator["LiftedCoordinates"][[All, 2]]];
  vectors = Association@Map[
    Lookup[#, "PeriodID"] -> Normal@SparseArray[
      (First[#] -> Last[#]) & /@ Lookup[#, "CanonicalModeEntries", {}],
      dimension] &,
    Select[modeMap["Modes"],
      MemberQ[Lookup[coordinates, "PeriodID", {}], Lookup[#, "PeriodID"]] &]];
  coordinateMap = Transpose@Table[
    periodID = Lookup[coordinate, "PeriodID"];
    periodOrder = Lookup[coordinate, "EpsilonOrder"];
    Table[
      {slotOrder, slotRow} =
        spectator["LiftedCoordinates"][[spectator["IdentityPivotRows"]]][[slot]];
      SeriesCoefficient[Lookup[vectors, periodID][[slotRow]],
        {epsilon, 0, slotOrder - periodOrder}],
      {slot, Length[historical["BoundaryCoordinates"]]}],
    {coordinate, coordinates}];
  oldRows = historical["PhysicalRows"];
  newRows = transport["PhysicalDemandPairs"];
  rowPositions = First@FirstPosition[oldRows, #] & /@ newRows;
  baseRules = Lookup[Lookup[adapter["Path"], "InteriorBase"], "Point"];
  oldMatrix[current_] := sparseFromEntries[Lookup[current, "Entries", {}],
    {Length[oldRows], Length[historical["BoundaryCoordinates"]]}];
  oldProjected[current_] := Together[
    Normal[oldMatrix[current][[rowPositions, All]] . coordinateMap] /. baseRules];
  newProjected[current_] := Together[Normal[Lookup[current, "Map"]] /. baseRules];
  oldZero = Total[oldProjected /@ Select[historical["ObservableMaps"],
    Lookup[#, "FirstPathWord", {1}] === {} &&
      Lookup[#, "SpectatorPathWord", {1}] === {} &]];
  newZero = Total[newProjected /@ Select[composed["WordMaps"],
    Lookup[#, "EndpointFirstWord", {1}] === {} &&
      Lookup[#, "EndpointSecondWord", {1}] === {} &]];
  firstSegment = SelectFirst[adapter["Path"]["Segments"],
    Lookup[#, "Role", None] === "EndpointFirst" &];
  secondSegment = SelectFirst[adapter["Path"]["Segments"],
    Lookup[#, "Role", None] === "EndpointSecond" &];
  firstKernels = firstSegment["DLogKernels"];
  secondKernels = secondSegment["DLogKernels"];
  historicalResidue = sparseFromEntries[endpointFrobenius["ResidueEntries"],
    {dimension, dimension}];
  currentResidue = Total@Table[
    Limit[(Last[transport["Variables"]] - endpointFrobenius["Endpoint"])
      Lookup[secondKernels, index],
      Last[transport["Variables"]] -> endpointFrobenius["Endpoint"]]
      transport["DLogResidues"][[index]],
    {index, Keys[secondKernels]}];
  currentEndpointConnection = Total@Table[
    Lookup[secondKernels, index] transport["DLogResidues"][[index]],
    {index, Keys[secondKernels]}];
  currentRegularConnection = Together[
    currentEndpointConnection - currentResidue/
      (Last[transport["Variables"]] - endpointFrobenius["Endpoint"])] ;
  historicalRegularCoefficients = sparseFromEntries[
      Lookup[#, "Entries", {}], {dimension, dimension}] & /@
    endpointFrobenius["RegularConnectionCoefficients"];
  currentRegularCoefficients = Table[
    Map[Together[
      Limit[D[#, {Last[transport["Variables"]], order}],
        Last[transport["Variables"]] -> endpointFrobenius["Endpoint"]]/
      Factorial[order]] &, currentRegularConnection, {2}],
    {order, 0, Length[historicalRegularCoefficients] - 1}];
  selected = Select[historical["ObservableMaps"],
    Length[Lookup[#, "FirstPathWord", {}]] === 1 &&
      Lookup[#, "SpectatorPathWord", {1}] === {} &];
  oldFirst = Total@Table[
    item = current;
    kernel = D[historical["FirstPathDLogLetters"][[
        First[item["FirstPathWord"]]]], First[transport["Variables"]]]/
      historical["FirstPathDLogLetters"][[First[item["FirstPathWord"]]]];
    Together[kernel oldProjected[item] /. baseRules],
    {current, selected}];
  selected = Select[composed["WordMaps"],
    Length[Lookup[#, "EndpointFirstWord", {}]] === 1 &&
      Lookup[#, "EndpointSecondWord", {1}] === {} &];
  newFirst = Total@Table[
    item = current;
    Together[Lookup[firstKernels, First[item["EndpointFirstWord"]]]
      newProjected[item] /. baseRules],
    {current, selected}];
  selected = Select[historical["ObservableMaps"],
    Lookup[#, "FirstPathWord", {1}] === {} &&
      Length[Lookup[#, "SpectatorPathWord", {}]] === 1 &];
  oldSecond = Total@Table[
    item = current;
    kernel = historical["SpectatorPathKernels"][[
      First[item["SpectatorPathWord"]]]];
    Together[kernel oldProjected[item] /. baseRules],
    {current, selected}];
  selected = Select[composed["WordMaps"],
    Lookup[#, "EndpointFirstWord", {1}] === {} &&
      Length[Lookup[#, "EndpointSecondWord", {}]] === 1 &];
  newSecond = Total@Table[
    item = current;
    Together[Lookup[secondKernels, First[item["EndpointSecondWord"]]]
      newProjected[item] /. baseRules],
    {current, selected}];
  <|
    "EndpointResidueMatrixEqual" -> exactZeroArrayQ[
      Normal[historicalResidue - currentResidue]],
    "EndpointRegularSeriesEqual" -> And @@ MapThread[
      exactZeroArrayQ[Normal[#1 - #2]] &,
      {historicalRegularCoefficients, currentRegularCoefficients}],
    "ZeroWordMapEqual" -> exactZeroArrayQ[oldZero - newZero],
    "FirstSegmentOneFormEqual" -> exactZeroArrayQ[oldFirst - newFirst],
    "SecondSegmentOneFormEqual" -> exactZeroArrayQ[oldSecond - newSecond],
    "ZeroWordDifferencePositions" ->
      Take[nonzeroPositions[oldZero - newZero], UpTo[8]],
    "MultiplicationOrder" -> adapter["Path"]["MultiplicationOrder"]
  |>
];

control299 = historicalControl["CF299", "observable_transport_CF299.wl",
  "BoundaryModeMap_CF299.wl"];
control407 = historicalControl["CF407", "observable_transport_CF407.wl",
  "BoundaryModeMap_CF407.wl"];
check["CF299 current endpoint residue matches the accepted control frame",
  TrueQ[control299["EndpointResidueMatrixEqual"]] &&
    TrueQ[control299["EndpointRegularSeriesEqual"]]];
check["CF407 accepted endpoint control recurrence is reproduced",
  And @@ Values@KeyTake[control407,
    {"EndpointResidueMatrixEqual", "ZeroWordMapEqual",
      "EndpointRegularSeriesEqual", "ZeroWordMapEqual",
      "FirstSegmentOneFormEqual", "SecondSegmentOneFormEqual"}]];
check["CF299 quotient decomposition is correctly treated as aggregate-only",
  !TrueQ[control299["ZeroWordMapEqual"]] &&
    control299["MultiplicationOrder"] ===
      "EndpointFirstWord.EndpointSecondWord"];

transportForFailure = loadAssociation[
  FileNameJoin[{transportRoot, "observable_transport_CF407.wl"}]];
modeForFailure = loadAssociation[
  FileNameJoin[{history, "BoundaryModeMap_CF407.wl"}]];
check["missing dlog segment fails typed",
  MatchQ[
    FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
      KeyDrop[transportForFailure, "DLogLetters"], modeForFailure, <||>,
      "MaximumConnectorWeight" -> 0, "PeriodOrderWindow" -> {0, 1}],
    Failure["MissingFirstSegmentMap", _Association]]];
check["missing realized mode fails typed",
  MatchQ[
    FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
      transportForFailure, Join[modeForFailure, <|"Modes" -> {}|>], <||>,
      "MaximumConnectorWeight" -> 0, "PeriodOrderWindow" -> {0, 1}],
    Failure["MissingEndpointModeRealization", _Association]]];
check["insufficient connector depth fails typed",
  MatchQ[
    FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
      transportForFailure, modeForFailure, <||>,
      "MaximumConnectorWeight" -> 0, "PeriodOrderWindow" -> {0, 2}],
    Failure["EndpointConnectorDepthInsufficient", _Association]]];
logMode = Join[First[modeForFailure["Modes"]], <|
  "LocalEigenvalue" -> 1, "GeneralizedLevel" -> 0|>];
logFailure = FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
  transportForFailure, Join[modeForFailure, <|"Modes" -> {logMode}|>], <||>,
  "MaximumConnectorWeight" -> 0, "PeriodOrderWindow" -> {0, 1}];
check["nonzero local modes name the required logarithmic normalization",
  MatchQ[logFailure, Failure["TangentialLogModeRequired", _Association]] &&
    KeyExistsQ[Last[logFailure], "RequiredLocalNormalization"]];

If[AssociationQ[cf299] && KeyExistsQ[cf299, "Adapter"],
  check["CF299 known-zero mode remains known zero",
    AnyTrue[Lookup[cf299["Adapter"], "Stage3NeedsLedger", {}],
      Lookup[#, "PeriodID", None] === 7 && Lookup[#, "Status", None] === "KnownZero" &]]
];
If[AssociationQ[cf407] && KeyExistsQ[cf407, "Adapter"],
  check["CF407 period 23 remains formal",
    AnyTrue[Lookup[cf407["Adapter"], "Stage3NeedsLedger", {}],
      Lookup[#, "PeriodID", None] === 23 && Lookup[#, "Status", None] === "Unevaluated" &]]
];
If[AssociationQ[cf407] && KeyExistsQ[cf407, "Adapter"],
  unpreparedIndex = First[
    cf407["Adapter"]["Path"]["Segments"][[2]]["AlphabetIndices"]];
  check["unprepared observable words fail typed instead of broad enumeration",
    MatchQ[
      FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords[
        cf407["Adapter"], transportForFailure, {{{unpreparedIndex}, {}}}],
      Failure["EndpointDemandWordNotPrepared", _Association]]]
];
check["unused CF407 period orders are pruned before Stage3 composition",
  Length[First@Cases[cf407["Composition"]["Stage3NeedsLedger"],
    entry_Association /; Lookup[entry, "PeriodID", None] === 23 :>
      Lookup[entry, "AffectedBoundaryCoordinates", {}]]] === 1 &&
    Length@Select[cf407["Adapter"]["PeriodCoordinates"],
      Lookup[#, "PeriodID", None] === 23 &] === 1];

summary[result_] := If[AssociationQ[result] && KeyExistsQ[result, "Adapter"], <|
  "AdapterSeconds" -> result["AdapterSeconds"],
  "CompositionSeconds" -> result["CompositionSeconds"],
  "EnumeratedConnectorWordCount" -> result["Adapter"]["EnumeratedConnectorWordCount"],
  "RetainedConnectorWordCount" -> result["Adapter"]["RetainedConnectorWordCount"],
  "RequiredConnectorWeight" -> result["Adapter"]["RequiredConnectorWeight"],
  "PeriodCoordinates" -> Length[result["Adapter"]["PeriodCoordinates"]],
  "Ledger" -> ({Lookup[#, "PeriodID"], Lookup[#, "Status"],
      Length[Lookup[#, "AffectedBoundaryCoordinates", {}]]} & /@
    result["Composition"]["Stage3NeedsLedger"])
|>, result];

testResult = <|
  "Status" -> If[And @@ Last /@ checks, "PASS", "FAIL"],
  "Checks" -> checks,
  "CF299" -> summary[cf299],
  "CF407" -> summary[cf407],
  "CF123MaterializedProvider" -> <|
    "AdapterSeconds" -> First[materializedTiming],
    "Provider" -> If[AssociationQ[materializedAdapter],
      Lookup[materializedAdapter, "ObservableWordMapProvider", Missing["Absent"]],
      materializedAdapter]|>,
  "CF299HistoricalControl" -> control299,
  "CF407HistoricalControl" -> control407
|>;
Print[InputForm[testResult]];

If[TrueQ[KernelPoolMission`$MissionSafe], testResult,
  Exit[If[And @@ Last /@ checks, 0, 1]]]
]]
