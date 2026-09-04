#!/usr/bin/env wolframscript

(* Unit tests for the graded endpoint construction.  All boundary data are
   built from a mathematical fixture in this process; no generated campaign
   artifact is treated as an authoritative mode map. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "Transport",
  "PhysicalBoundaryCampaignAdapter.wl"}]];

x = Symbol["Global`gradedX"];
y = Symbol["Global`gradedY"];
eps = Symbol["Global`eps"];
rho = Symbol["Global`gradedRho"];
family = "GradedEndpointToy";

epsilonForm = <|
  "Status" -> "ExactEpsilonForm", "Family" -> family,
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Ranges" -> {{1}, {2}}, "Blocks" -> {{1}, {2}},
  "TTotal" -> IdentityMatrix[2], "TTotalInverse" -> IdentityMatrix[2],
  "EpsFormX" -> eps {{0, 0}, {1/x, 0}},
  "EpsFormY" -> eps {{0, 0}, {1/y, 0}},
  "Letters" -> {x, y},
  "DLog" -> <|"Valid" -> True, "Dimension" -> 2,
    "Variables" -> {x, y}, "Regulator" -> eps,
    "Letters" -> {x, y},
    "Residues" -> {{{0, 0}, {1, 0}}, {{0, 0}, {1, 0}}},
    "ConstantResidues" -> True|>,
  "ChartRecord" -> <|"CoefficientField" -> "Rational",
    "Variables" -> {x, y}, "Subst" -> {x -> x, y -> y},
    "Roots" -> {}|>,
  "Chart" -> "RationalIdentity", "GateVerdict" -> True,
  "GaugeIdentity" -> True, "Flatness" -> True,
  "TTotalInvertible" -> True|>;
path = <|"FirstVariable" -> x, "SecondVariable" -> y,
  "FirstBase" -> 3, "SecondBase" -> 1/2,
  "FirstTargetSample" -> 4|>;
demand = <|"PhysicalRows" -> {1, 2}, "PhysicalOrders" -> {0, 1, 2},
  "PhysicalValuation" -> 0, "Path" -> path|>;
transport = BuildObservableTransport[epsilonForm, demand,
  "BoundaryEvolution" -> "AmbientBasePoint",
  "WordRepresentation" -> "OperatorAutomaton"];
transport = Join[transport, <|
  "DLogLetters" -> epsilonForm["DLog", "Letters"],
  "DLogResidues" -> epsilonForm["DLog", "Residues"]|>];

frobenius = ComputeTruncatedLocalFrobeniusExpansion[
  epsilonForm["EpsFormY"], <|"Variable" -> y, "Regulator" -> eps,
    "LocalVariable" -> rho, "LocalExpansionPoint" -> 1,
    "LocalDirection" -> -1, "FixedRules" -> {x -> 2}|>,
  "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 3];
realizations = Table[<|
    "BoundaryConstantID" -> {family, id},
    "FrobeniusModeID" -> {family, id},
    "BoundaryIntegralID" -> id,
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0,
    "CanonicalRows" -> {id}, "PhysicalRows" -> {id},
    "ConstraintRows" -> Range[id],
    "DemandedOutputs" -> {{0, 1}, {0, 2}, {1, 1}, {1, 2},
      {2, 1}, {2, 2}},
    "EpsilonExponent" -> 0, "IntegerValuation" -> 0,
    "LogLevel" -> 0|>, {id, 2}];
modeMap = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
  IdentityMatrix[2], <|"Family" -> family, "Limit" -> "toyPoint",
    "FixedRules" -> {x -> 2},
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint",
      "Coordinates" -> {x -> 2, y -> 1}|>,
    "PhysicalEndpointRelation" -> <|"Stratum" -> "toyPoint",
      "LocalPower" -> 1, "LeadingCoefficient" -> 1|>|>, realizations];

coordinateKey[coordinate_] := With[
  {id = coordinate["BoundaryConstantID"],
   order = coordinate["EpsilonOrder"]}, HoldComplete[id, order]];
wordKey[term_] := With[
  {currentFirst = Lookup[term, "CurrentFirstWord", {}],
   currentSecond = Lookup[term, "CurrentSecondWord", {}],
   endpointFirst = Lookup[term, "EndpointFirstWord", {}],
   endpointSecond = Lookup[term, "EndpointSecondWord", {}]},
  HoldComplete[currentFirst, currentSecond, endpointFirst, endpointSecond]];
nonzeroVectorQ[vector_] := AnyTrue[Flatten[vector], Not@*PossibleZeroQ];
canonicalWordMaps[result_] := Association@Map[Function[term,
    wordKey[term] -> Association@Select[
      Thread[(coordinateKey /@
          result["BoundaryConstantEpsilonCoefficientRecords"]) ->
        Transpose[Normal[term["Map"]]]], nonzeroVectorQ[Last[#]] &]],
  result["WordMaps"]];

buildTiming = AbsoluteTiming[
  binding = FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    transport, modeMap, <||>]];
FTAssert["a typed point-boundary fixture closes by exact weight without enumerating its alphabet product",
  binding["Status"] === "GradedPhysicalEndpointTransportBuilt" &&
    binding["BoundaryDataType"] === "BoundaryConstant" &&
    binding["MaximumCurrentWeight"] ===
      transport["ExactOperatorAutomaton", "RequestedMaximumWeight"] &&
    Length[binding["GradesByWeight"]] >= 1 &&
    TrueQ[binding["FormalResultConvention",
      "NoAlphabetCartesianEnumeration"]]];

zeroPair = {{}, {}};
directAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, modeMap, <||>, "DemandWordPairs" -> {zeroPair}];
directZero =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
    directAdapter, transport, {zeroPair}];
gradedZero = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  binding, transport, {zeroPair}];
FTAssert["the graded zero-word map equals the independently demand-pruned endpoint composition",
  directZero["Status"] ===
      "EndpointAutomatonBoundaryCoefficientMapsBuilt" &&
    gradedZero["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    canonicalWordMaps[directZero] === canonicalWordMaps[gradedZero]];

firstIndex = First[transport["ExactOperatorAutomaton",
  "FirstAlphabetIndices"]];
secondIndex = First[transport["ExactOperatorAutomaton",
  "SecondAlphabetIndices"]];
requestedPairs = {{{firstIndex}, {}}, {{}, {secondIndex}},
  {{firstIndex}, {secondIndex}}};
directAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, modeMap, <||>, "DemandWordPairs" -> requestedPairs];
directWords =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
    directAdapter, transport, requestedPairs];
gradedWords = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  binding, transport, requestedPairs];
FTAssert["first-segment, second-segment and mixed iterated-integral words retain the four-segment multiplication order",
  directWords["Status"] ===
      "EndpointAutomatonBoundaryCoefficientMapsBuilt" &&
    gradedWords["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    canonicalWordMaps[directWords] === canonicalWordMaps[gradedWords]];

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
zeroWords = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  zeroBinding, zeroTransport, {{{firstIndex}, {}}}];
FTAssert["a requested word in an exactly zero row-space grade composes to the empty map",
  zeroWords["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    zeroWords["WordMaps"] === {} &&
    AllTrue[zeroWords["BoundaryDataRequirements"],
      Lookup[#, "BoundaryConstantEpsilonCoefficientLabels", Missing[]] === {} &]];

materializedDemand = Join[demand, <|"PhysicalOrders" -> {0, 1}|>];
materializedTransport = BuildObservableTransport[epsilonForm,
  materializedDemand,
  "BoundaryEvolution" -> "AmbientBasePoint",
  "WordRepresentation" -> "MaterializedWords"];
materializedTransport = Join[materializedTransport, <|
  "DLogLetters" -> epsilonForm["DLog", "Letters"],
  "DLogResidues" -> epsilonForm["DLog", "Residues"]|>];
materializedBinding =
  FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    materializedTransport, modeMap, <||>];
materializedPairs = Take[
  ({#[[1]], #[[2]]} &) /@
    materializedTransport["TwoSegmentWordMaps"], UpTo[3]];
materializedWords =
  FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
    materializedBinding, materializedTransport, materializedPairs];
materializedDirectAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    materializedTransport, modeMap, <||>,
    "DemandWordPairs" -> materializedPairs];
materializedDirectWords =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
    materializedDirectAdapter, materializedTransport, materializedPairs];
FTAssert["the same graded endpoint representation consumes a bounded materialized transport",
  materializedBinding["Status"] === "GradedPhysicalEndpointTransportBuilt" &&
    materializedWords["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    materializedDirectWords["Status"] ===
      "EndpointAutomatonBoundaryCoefficientMapsBuilt" &&
    canonicalWordMaps[materializedWords] ===
      canonicalWordMaps[materializedDirectWords]];

staleCoordinate = <|"BoundaryDataType" -> "BoundaryConstant",
  "BoundaryConstantID" -> {"SyntheticStale", 1},
  "FrobeniusModeID" -> {"SyntheticStale", 1},
  "EpsilonOrder" -> 0|>;
staleBinding = <|
  "Status" -> "GradedPhysicalEndpointTransportBuilt",
  "Family" -> "SyntheticStale", "BoundaryDataType" -> "BoundaryConstant",
  "BoundaryConstantEpsilonCoefficientRecords" -> {staleCoordinate},
  "BoundaryConstantEpsilonCoefficientLabels" ->
    {{{"SyntheticStale", 1}, 0}},
  "GradesByWeight" -> <|0 -> <|
    "CurrentRowBasis" -> SparseArray[{{1, 0}}],
    "ProjectionColumns" -> {1}, "ProjectionInverse" -> {{1}},
    "EndpointWordTerms" -> {<|"EndpointFirstWord" -> {},
      "EndpointSecondWord" -> {}, "Map" -> SparseArray[{{1}}]|>}|>|>,
  "CurrentBaseRules" -> {}, "BoundaryDataRequirements" -> {},
  "PhysicalDemandPairs" -> {}, "FormalResultConvention" -> <||>|>;
staleTransport = <|"Family" -> "SyntheticStale",
  "WordRepresentation" -> "MaterializedWords",
  "TwoSegmentWordMaps" -> {{{}, {}, SparseArray[{{1, 1}}]}}|>;
staleResult = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  staleBinding, staleTransport, {{{}, {}}}];
FTAssert["a same-family word outside the bound exact row space fails closed",
  MatchQ[staleResult, Failure["CurrentPathRowSpaceMismatch", _Association]]];

FTAssert["compound boundary-constant identifiers remain single coefficient keys",
  AllTrue[binding["BoundaryConstantEpsilonCoefficientRecords"],
    MatchQ[Lookup[#, "BoundaryConstantID"], {_String, _Integer}] &] &&
    DuplicateFreeQ[coordinateKey /@
      binding["BoundaryConstantEpsilonCoefficientRecords"]]];

degenerateRealization = <|
  "BoundaryConstantID" -> {family, "degenerate"},
  "FrobeniusModeID" -> {family, "degenerate"},
  "BoundaryIntegralID" -> "degenerate",
  "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
  "BoundaryConstantEpsilonValuation" -> 0,
  "CanonicalRows" -> {1, 2}, "PhysicalRows" -> {1, 2},
  "ConstraintRows" -> {1, 2},
  "DemandedOutputs" -> {{0, 1}, {0, 2}},
  "EpsilonExponent" -> 0, "IntegerValuation" -> 0,
  "LogLevel" -> 0, "DegenerateResidueEigenspacePolicy" -> "Basis"|>;
degenerateModeMap = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
  IdentityMatrix[2], <|"Family" -> family, "Limit" -> "toyPoint",
    "FixedRules" -> {x -> 2},
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint",
      "Coordinates" -> {x -> 2, y -> 1}|>,
    "PhysicalEndpointRelation" -> <|"Stratum" -> "toyPoint",
      "LocalPower" -> 1, "LeadingCoefficient" -> 1|>|>,
  {degenerateRealization}];
degenerateBinding =
  FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    transport, degenerateModeMap, <||>];
FTAssert["a degenerate residue eigenspace retains two independent boundary constants and no inferred relation",
  degenerateBinding["Status"] === "GradedPhysicalEndpointTransportBuilt" &&
    Length[degenerateBinding["DegenerateResidueEigenspaceBases"]] === 2 &&
    AllTrue[degenerateBinding["DegenerateResidueEigenspaceBases"],
      #["IndependentBoundaryDataCount"] === 2 &&
        #["BoundaryRelations"] === {} &] &&
    Sort@DeleteDuplicates[Lookup[degenerateBinding[
      "BoundaryConstantEpsilonCoefficientRecords"], "BoundaryConstantID"]] ===
      Sort[{{family, "degenerate", 1}, {family, "degenerate", 2}}]];

FTAssert["the synthetic graded construction remains bounded",
  First[buildTiming] < 30];

FTReport[];
