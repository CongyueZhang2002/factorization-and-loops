#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "Transport",
  "PhysicalBoundaryCampaignAdapter.wl"}]];

resultRoot = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical"}];
transportDirectory = FileNameJoin[{resultRoot,
  "ObservableTransport_2026-09-01_codex", "families"}];
modeDirectory = FileNameJoin[{resultRoot, "PhysicalBoundaryModes"}];

loadFamily[family_] := {
  Get[FileNameJoin[{transportDirectory,
    "observable_transport_" <> family <> ".wl"}]],
  Get[FileNameJoin[{modeDirectory, "boundary_mode_" <> family <> ".wl"}]]};

coordinateKey[coordinate_] := With[
  {id = Lookup[coordinate, "PeriodID"],
   order = Lookup[coordinate, "EpsilonOrder"]}, HoldComplete[id, order]];
wordKey[term_] := With[
  {currentFirst = Lookup[term, "CurrentFirstWord", {}],
   currentSecond = Lookup[term, "CurrentSecondWord", {}],
   endpointFirst = Lookup[term, "EndpointFirstWord", {}],
   endpointSecond = Lookup[term, "EndpointSecondWord", {}]},
  HoldComplete[currentFirst, currentSecond, endpointFirst, endpointSecond]];
nonzeroVectorQ[vector_] := AnyTrue[Flatten[vector], Not@*PossibleZeroQ];
canonicalWordMaps[result_] := Association@Map[Function[term,
    wordKey[term] -> Association@Select[
      Thread[(coordinateKey /@ result["PeriodCoordinates"]) ->
        Transpose[Normal[term["Map"]]]], nonzeroVectorQ[Last[#]] &]],
  result["WordMaps"]];

{transport, modeMap} = loadFamily["CF407"];
buildTiming = AbsoluteTiming[
  binding = FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    transport, modeMap, <||>]];
FTAssert["the real operator-automaton family closes by exact weight without enumerating its alphabet product",
  binding["Status"] === "GradedPhysicalEndpointTransportBuilt" &&
    binding["MaximumCurrentWeight"] ===
      transport["ExactOperatorAutomaton", "RequestedMaximumWeight"] &&
    Length[binding["GradesByWeight"]] >= 1 &&
    TrueQ[binding["FormalResultConvention",
      "NoAlphabetCartesianEnumeration"]]];

zeroPair = {{}, {}};
directAdapter = FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
  transport, modeMap, <||>,
    "DemandWordPairs" -> {zeroPair}];
directZero = FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords[
  directAdapter, transport, {zeroPair}];
gradedZero = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  binding, transport, {zeroPair}];
FTAssert["the graded zero-word map equals the independently demand-pruned endpoint composition",
  directZero["Status"] === "EndpointAutomatonPhysicalPeriodWordsBuilt" &&
    gradedZero["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    canonicalWordMaps[directZero] === canonicalWordMaps[gradedZero]];

firstIndex = First[transport["ExactOperatorAutomaton",
  "FirstAlphabetIndices"]];
onePair = {{firstIndex}, {}};
directAdapter = FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
  transport, modeMap, <||>,
    "DemandWordPairs" -> {onePair}];
directOne = FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords[
  directAdapter, transport, {onePair}];
gradedOne = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  binding, transport, {onePair}];
FTAssert["an arbitrary nonzero current-path word is recovered from its finite row-space basis",
  directOne["Status"] === "EndpointAutomatonPhysicalPeriodWordsBuilt" &&
    gradedOne["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    canonicalWordMaps[directOne] === canonicalWordMaps[gradedOne]];

secondIndex = First[transport["ExactOperatorAutomaton",
  "SecondAlphabetIndices"]];
orderedPairs = {{{}, {secondIndex}}, {{firstIndex}, {secondIndex}}};
directOrderedAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, modeMap, <||>, "DemandWordPairs" -> orderedPairs];
directOrdered =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords[
    directOrderedAdapter, transport, orderedPairs];
gradedOrdered =
  FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
    binding, transport, orderedPairs];
FTAssert["second-only and mixed current words retain the four-segment multiplication order",
  directOrdered["Status"] === "EndpointAutomatonPhysicalPeriodWordsBuilt" &&
    gradedOrdered["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    canonicalWordMaps[directOrdered] === canonicalWordMaps[gradedOrdered]];

zeroAutomaton = Join[transport["ExactOperatorAutomaton"], <|
  "FirstOperatorMatrices" ->
    (0 # & /@ transport["ExactOperatorAutomaton", "FirstOperatorMatrices"]),
  "SecondOperatorMatrices" ->
    (0 # & /@ transport["ExactOperatorAutomaton", "SecondOperatorMatrices"])
|>];
zeroTransport = Join[transport, <|"ExactOperatorAutomaton" -> zeroAutomaton|>];
zeroBinding =
  FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    zeroTransport, modeMap, <||>];
zeroWords =
  FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
    zeroBinding, zeroTransport, {onePair}];
FTAssert["a requested word in an exactly zero row-space grade composes to the empty map",
  zeroWords["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    zeroWords["WordMaps"] === {} &&
    AllTrue[zeroWords["Stage3NeedsLedger"],
      Lookup[#, "AffectedBoundaryCoordinates", Missing[]] === {} &]];

{materializedTransport, materializedModeMap} = loadFamily["CF123"];
materializedBinding = FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    materializedTransport, materializedModeMap, <||>];
materializedPairs = Take[
  ({#[[1]], #[[2]]} &) /@
    materializedTransport["TwoSegmentWordMaps"], UpTo[3]];
materializedWords = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
    materializedBinding, materializedTransport, materializedPairs];
materializedDirectAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    materializedTransport, materializedModeMap, <||>,
    "DemandWordPairs" -> materializedPairs];
materializedDirectWords =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords[
    materializedDirectAdapter, materializedTransport, materializedPairs];
FTAssert["the same graded endpoint representation consumes bounded materialized transports",
  materializedBinding["Status"] ===
      "GradedPhysicalEndpointTransportBuilt" &&
    materializedWords["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    materializedDirectWords["Status"] ===
      "EndpointAutomatonPhysicalPeriodWordsBuilt" &&
    canonicalWordMaps[materializedWords] ===
      canonicalWordMaps[materializedDirectWords]];

staleCoordinate = <|"PeriodID" -> {"SyntheticStale", 1},
  "EpsilonOrder" -> 0|>;
staleBinding = <|
  "Status" -> "GradedPhysicalEndpointTransportBuilt",
  "Family" -> "SyntheticStale",
  "PeriodCoordinates" -> {staleCoordinate},
  "GradesByWeight" -> <|0 -> <|
    "CurrentRowBasis" -> SparseArray[{{1, 0}}],
    "ProjectionColumns" -> {1},
    "ProjectionInverse" -> {{1}},
    "EndpointWordTerms" -> {<|
      "EndpointFirstWord" -> {}, "EndpointSecondWord" -> {},
      "Map" -> SparseArray[{{1}}]|>}|>|>,
  "CurrentBaseRules" -> {},
  "Stage3NeedsLedger" -> {},
  "PhysicalDemandPairs" -> {},
  "FormalResultConvention" -> <||>|>;
staleTransport = <|
  "Family" -> "SyntheticStale",
  "WordRepresentation" -> "MaterializedWords",
  "TwoSegmentWordMaps" -> {{{}, {}, SparseArray[{{1, 1}}]}}|>;
staleResult =
  FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
    staleBinding, staleTransport, {{{}, {}}}];
FTAssert["a same-family word outside the bound exact row space fails closed",
  MatchQ[staleResult,
    Failure["CurrentPathRowSpaceMismatch", _Association]]];

FTAssert["list-valued physical realization IDs remain single coordinate keys",
  AllTrue[binding["PeriodCoordinates"],
    MatchQ[Lookup[#, "PeriodID"], {_String, _Integer}] &] &&
    DuplicateFreeQ[coordinateKey /@ binding["PeriodCoordinates"]]];

FTAssert["the real-family construction remains bounded",
  First[buildTiming] < 120];

(* Round 9b (T, R3's F2): on the installed CF300 map the period-12 split is
   declared on every coordinate and ledger entry of its sub-realizations and
   at the record's top level; ordinary modes carry None *)
{transport300, modeMap300} = loadFamily["CF300"];
binding300 = FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
  transport300, modeMap300, <||>];
splitCoordinates = Select[binding300["PeriodCoordinates"],
  MatchQ[Lookup[#, "PeriodID"], {"CF300", 12, _}] &];
splitLedger = Select[binding300["Stage3NeedsLedger"],
  MatchQ[Lookup[#, "PeriodID"], {"CF300", 12, _}] &];
ordinaryCoordinates = Select[binding300["PeriodCoordinates"],
  ! MatchQ[Lookup[#, "PeriodID"], {"CF300", 12, _}] &];
FTAssert["a Basis split of the installed CF300 map is declared on the endpoint record, its coordinates and its ledger entries",
  binding300["Status"] === "GradedPhysicalEndpointTransportBuilt" &&
    binding300["DegenerateEigenspaces"] ===
      {<|"ParentPeriodID" -> {"CF300", 12}, "EigenspaceDimension" -> 2|>} &&
    splitCoordinates =!= {} && splitLedger =!= {} &&
    AllTrue[Join[splitCoordinates, splitLedger], With[{d = Lookup[#, "DegenerateEigenspace", None]},
      AssociationQ[d] && d["ParentPeriodID"] === {"CF300", 12} &&
        d["EigenspaceDimension"] === 2 && d["PeriodCount"] === 1 &&
        d["SubRealizationPeriodIDs"] === {{"CF300", 12, 1}, {"CF300", 12, 2}} &&
        MatrixQ[d["EigenspaceBasis"]] && Dimensions[d["EigenspaceBasis"]] === {2, 4} &&
        d["EigenspaceDirection"] === Last[Lookup[#, "PeriodID"]]] &] &&
    AllTrue[ordinaryCoordinates, Lookup[#, "DegenerateEigenspace", Missing[]] === None &]];

FTReport[];
