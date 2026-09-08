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
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryStratum",
      "TangentialVariables" -> {p}|>,
    "PrescribedModeEntries" -> {{8, 2}, {9, -3}},
    "ExpectedCompletedModeEntries" -> {{8, 2}, {9, -3}},
    "BoundaryIntegralID" -> 9|>,
  <|"Family" -> "CF53", "Missing" -> {{2, 4, 11}, {3, 5, 12}},
    "EndpointSpec" -> <|"Variable" -> y, "Endpoint" -> p,
      "FixedRules" -> {x -> -p}, "Stratum" -> "1-v-w=0"|>,
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryStratum",
      "TangentialVariables" -> {p}|>,
    "PrescribedModeEntries" -> {{11, 2}, {12, -3}},
    "ExpectedCompletedModeEntries" -> {{11, 2}, {12, -3}, {13, -2/5}},
    "BoundaryIntegralID" -> 9|>
};

exactZeroQ[value_] := TrueQ[value === 0] || TrueQ[PossibleZeroQ[value]];
exactZeroArrayQ[array_] := And @@ (exactZeroQ /@ Flatten[array]);

demandRow[basisTransformation_, regulator_, slots_, pair_] := Table[
  SeriesCoefficient[basisTransformation[[Last[pair], Last[slot]]],
    {regulator, 0, First[pair] - First[slot]}],
  {slot, slots}];

sparseEntries[matrix_] := Cases[
  Most[ArrayRules[SparseArray[matrix]]],
  HoldPattern[{row_Integer, column_Integer} -> value_] :>
    <|"Row" -> row, "Column" -> column, "Value" -> value|>];

completedEndpointMode[transport_, specification_] := Module[
  {variable, endpoint, fixedRules, normalResidue, dimension,
   prescribedEntries, prescribedRows, prescribedValues, constraints,
   vector, entries, boundaryDomain, boundaryDataType, dataIDKey,
   analyticClassKey, epsilonValuationKey, boundaryDataID},
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
  boundaryDomain = Lookup[specification, "BoundaryDomain", Missing[]];
  boundaryDataType = Switch[Lookup[boundaryDomain, "Type", None],
    "PhysicalBoundaryPoint", "BoundaryConstant",
    "PhysicalBoundaryStratum", "BoundaryFunction",
    _, Return[Failure["BoundaryDomainRequired", <|
      "Family" -> specification["Family"]|>]]];
  dataIDKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantID", "BoundaryFunctionID"];
  analyticClassKey = If[boundaryDataType === "BoundaryConstant",
    "DeclaredBoundaryConstantAnalyticClass",
    "DeclaredBoundaryFunctionClass"];
  epsilonValuationKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantEpsilonValuation", "BoundaryFunctionEpsilonValuation"];
  boundaryDataID =
    {specification["Family"], specification["BoundaryIntegralID"]};
  <|"ModeMap" -> <|
      "DataType" -> "BoundaryAsymptoticModeMatching",
      "SchemaVersion" -> 2,
      "Status" -> "BoundaryAsymptoticsMatchedToFrobeniusModes",
      "Family" -> specification["Family"],
      "BoundaryDataType" -> boundaryDataType,
      "BoundaryDomain" -> boundaryDomain,
      "PhysicalKinematicLimit" -> specification["EndpointSpec", "Stratum"],
      "LocalExpansionPoint" -> endpoint,
      "LocalExpansionSpecification" -> <|"Variable" -> variable,
        "LocalExpansionPoint" -> endpoint, "LocalDirection" -> 1,
        "FixedRules" -> fixedRules|>,
      "PhysicalEndpointRelation" -> <|
        "Stratum" -> specification["EndpointSpec", "Stratum"],
        "LocalPower" -> 1, "LeadingCoefficient" -> 1|>,
      "FrobeniusModes" -> {<|
        "Status" -> "BoundaryAsymptoticsMatchedToFrobeniusMode",
        "BoundaryDataType" -> boundaryDataType,
        dataIDKey -> boundaryDataID,
        "FrobeniusModeID" -> boundaryDataID,
        "BoundaryIntegralID" -> specification["BoundaryIntegralID"],
        analyticClassKey -> "GPL", epsilonValuationKey -> -1,
        "CanonicalModeEntries" -> entries,
        "LocalEigenvalue" -> 0, "GeneralizedLevel" -> 0,
        "Support" -> First /@ entries|>},
      "DegenerateResidueEigenspaceBases" -> {},
      "BoundaryDataRequirements" -> {<|
        "BoundaryDataType" -> boundaryDataType,
        dataIDKey -> boundaryDataID,
        "FrobeniusModeID" -> boundaryDataID,
        analyticClassKey -> "GPL", "Status" -> "Unevaluated"|>}|>,
    "NormalResidueDimensions" -> Dimensions[normalResidue],
    "CompletedModeEntries" -> entries|>
];

familyRecords = Table[Module[
  {family, transportFile, formFile, transport, form, regulator,
   basisTransformation,
   slots, existingRows,
   existingDemand, replay, missingTriples, missingPairs, missingRows,
   derivedTransport, modeResult, adapterTiming, adapter, compositionTiming,
   composition, endpointTransport, baseEmbedding, finalEmbedding},
  family = specification["Family"];
  transportFile = FileNameJoin[{transportDirectory,
    "observable_transport_" <> family <> ".wl"}];
  formFile = FileNameJoin[{formDirectory,
    "family_epsform_" <> family <> ".wl"}];
  If[! FileExistsQ[transportFile] || ! FileExistsQ[formFile],
    Return[<|"Family" -> family,
      "Status" -> "FreshDifferentialEquationDataRequired",
      "RequiredInputFiles" -> <|"ObservableTransport" -> transportFile,
        "EpsilonForm" -> formFile|>|>, Module]];
  transport = Get[transportFile];
  form = Get[formFile];
  regulator = form["Regulator"];
  basisTransformation = form["TTotal"] /. Lookup[transport,
    "BasisNormalizationParameterRules", {}];
  slots = transport["BoundaryAmbientSlots"];
  existingRows = transport["PhysicalRows"];
  existingDemand = Normal[
    transport["ExactOperatorAutomaton"]["InitialDemandMap"]];
  replay = MapThread[
    exactZeroArrayQ[
      demandRow[basisTransformation, regulator, slots, #1] - #2] &,
    {existingRows, existingDemand}];
  If[!And @@ replay,
    Throw@Failure["ExistingObservableDemandReplayMismatch", <|
      "Family" -> family, "Matched" -> Count[replay, True],
      "Total" -> Length[replay]|>]];
  missingTriples = specification["Missing"];
  missingPairs = ({First[#], Last[#]} &) /@ missingTriples;
  missingRows = demandRow[basisTransformation, regulator, slots, #] & /@
    missingPairs;
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
       "The CF12 class-5 soft zero mode has no accepted boundary asymptotics or boundary-integral identity; neither a BoundaryConstantID nor a BoundaryFunctionID is inferred"|>,
    modeResult = completedEndpointMode[transport, specification];
    If[FailureQ[modeResult], Throw[modeResult]];
    If[modeResult["ModeMap", "BoundaryDataType"] === "BoundaryFunction",
      <|"Status" -> "BoundaryFunctionEndpointTransportNotImplemented",
        "BoundaryDataType" -> "BoundaryFunction",
        "ModeCompletion" -> KeyDrop[modeResult, "ModeMap"],
        "BoundaryDataRequirements" ->
          modeResult["ModeMap", "BoundaryDataRequirements"],
        "Reason" -> "the source boundary is a positive-dimensional stratum parameterized by p; its boundary function cannot be replaced by a constant without an additional mathematical relation"|>,
      adapterTiming = AbsoluteTiming[
      adapter = FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
        derivedTransport, modeResult["ModeMap"], <||>,
        "BoundaryDataEpsilonOrderWindow" -> {-1, 5},
        "MaximumConnectorWords" -> 500000,
        "DemandWordPairs" -> {{{}, {}}}]];
    If[FailureQ[adapter] || Lookup[adapter, "Status", None] =!=
        "EndpointAutomatonBoundaryAdapterBuilt",
      Throw@Failure["EndpointBoundaryAdapterBuildFailed", <|
        "Family" -> family, "Result" -> adapter|>]];
    compositionTiming = AbsoluteTiming[
      composition = FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
        adapter, derivedTransport, {{{}, {}}}]];
    If[FailureQ[composition] || Lookup[composition, "Status", None] =!=
        "EndpointAutomatonBoundaryCoefficientMapsBuilt",
      Throw@Failure["EndpointBoundaryCoefficientCompositionFailed", <|
        "Family" -> family, "Result" -> composition|>]];
    <|"Status" -> "FormalBoundaryConstantCoefficientMapsBuilt",
      "BoundaryDataType" -> "BoundaryConstant",
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
      "BoundaryConstantEpsilonCoefficientRecords" ->
        composition["BoundaryConstantEpsilonCoefficientRecords"],
      "BoundaryConstantEpsilonCoefficientLabels" ->
        composition["BoundaryConstantEpsilonCoefficientLabels"],
      "WordMaps" -> composition["WordMaps"],
      "BoundaryDataRequirements" ->
        composition["BoundaryDataRequirements"]|>]
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
    "EndpointBoundaryData" -> endpointTransport|>
  ],
  {specification, specifications}];

result = <|
  "Status" -> If[AllTrue[familyRecords,
    Lookup[Lookup[#, "EndpointBoundaryData", <||>], "Status", None] ===
      "FormalBoundaryConstantCoefficientMapsBuilt" &],
    "CF303InheritedObservableExtensionsBuiltV2",
    "CF303InheritedObservableExtensionsIncomplete"],
  "Family" -> "CF303",
  "Scope" ->
   "Exactly five previously absent lower-family observable coefficients and their required soft-limit boundary data",
  "RequestedLowerRows" -> {
    <|"Family" -> "CF12", "OriginalRow" -> 4, "EpsilonOrder" -> 2|>,
    <|"Family" -> "CF199", "OriginalRow" -> 1, "EpsilonOrder" -> 2|>,
    <|"Family" -> "CF199", "OriginalRow" -> 2, "EpsilonOrder" -> 3|>,
    <|"Family" -> "CF53", "OriginalRow" -> 4, "EpsilonOrder" -> 2|>,
    <|"Family" -> "CF53", "OriginalRow" -> 5, "EpsilonOrder" -> 3|>},
  "Families" -> familyRecords,
  "BoundaryDataSemantics" -> <|
    "CF199AndCF53" ->
     "Boundary functions on the one-dimensional soft stratum; no relation reducing them to constants has been supplied",
    "CF12" ->
     "Typed incomplete until its class-5 physical soft mode is realized",
    "TargetComposition" ->
     "These are physical F_source columns. Apply the separate regularized G25=F25-H F_source junction once; do not count the source extension twice"|>,
  "CompleteForCF303TargetComposition" -> False,
  "RemainingNeeds" -> {
    "A physical realization for the CF12 class-5 soft zero mode",
    "The tangentially dependent boundary functions for CF199 and CF53, or a proved relation reducing each to constants",
    "Composition with the regularized target G25 junction map"}
|>;

Put[result, outputPath];
Print[result["Status"], " output=", outputPath];
Do[If[KeyExistsQ[record, "EndpointBoundaryData"],
    Print[record["Family"], " replay=",
      record["ExistingDemandReplay"]["Matched"], "/",
      record["ExistingDemandReplay"]["Total"], " boundary=",
      KeyTake[record["EndpointBoundaryData"], {"Status", "AdapterSeconds",
        "VisitedConnectorStateCount", "RetainedConnectorWordCount"}]],
    Print[record["Family"], " status=", record["Status"]]],
  {record, familyRecords}];
result
]]
