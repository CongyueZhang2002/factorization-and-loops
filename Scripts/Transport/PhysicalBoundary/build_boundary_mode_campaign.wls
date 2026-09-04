#!/usr/bin/env wolframscript

(* Match physical-limit asymptotics to local Frobenius modes at one selected
   boundary point and record the required boundary constants.

   This is process data, not package logic: the generic Frobenius and mode
   builders live in Private/Transport/Boundary/PhysicalBoundary.wl.  The
   campaign deliberately uses one rational physical edge point per chart and
   obtains the family/row pairing from block_class_assign.wl, never from the
   independently deduplicated lists in NullityPeriods.wl. *)

$HistoryLength = 0;
repositoryRoot = DirectoryName[ExpandFileName[$InputFileName], 4];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[arguments === {},
  Print["Usage: build_boundary_mode_campaign.wls <output-directory> [CF...]"];
  Exit[64]
];
outputDirectory = ExpandFileName[First[arguments]];
requestedFamilies = Rest[arguments];
If[!DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

resultRoot = FileNameJoin[{repositoryRoot, "ppHX_NNLO_DoubleReal",
  "Results", "UU_08_10_canonical"}];
certificateDirectory = FileNameJoin[{resultRoot, "BoundaryPeriods",
  "Certificates"}];
formDirectory = FileNameJoin[{resultRoot, "FamilyEpsFormsCertified"}];
transportDirectory = FileNameJoin[{resultRoot,
  "ObservableTransport_2026-09-01_codex", "families"}];

(* Normalize the historical census at the file boundary.  No generated
   record below retains its ambiguous PeriodID field. *)
boundaryIntegralRecords = Map[
  KeyDrop[Join[#, <|"BoundaryIntegralID" -> #["PeriodID"]|>],
    "PeriodID"] &,
  Get[FileNameJoin[{certificateDirectory, "NullityPeriods.wl"}]]["Periods"]];
assignments = Get[FileNameJoin[{resultRoot, "BlockClasses",
  "block_class_assign.wl"}]];
certifiedBoundaryIntegralIDs = Sort@Flatten[ToExpression /@ StringCases[
  FileNameTake /@ FileNames["period_*.wl", certificateDirectory],
  "period_" ~~ digits : DigitCharacter .. ~~ ".wl" :> digits]];
(* A boundary-integral evaluation record is evidence about the value of a mode;
   it is not a prerequisite for the mode to occur in the physical solution.
   Keep every structurally counted boundary integral and mark unevaluated values formal
   downstream.  Filtering here used to erase 13 of the 33 exact nullity
   modes from the transport. *)
structuralBoundaryIntegralIDs =
  Sort@Lookup[boundaryIntegralRecords, "BoundaryIntegralID", {}];
activeBoundaryIntegrals = boundaryIntegralRecords;
allFamilies = Sort@DeleteDuplicates@Flatten@Lookup[
  activeBoundaryIntegrals, "Families"];
families = If[requestedFamilies === {}, allFamilies,
  Select[requestedFamilies, MemberQ[allFamilies, #] &]];
If[families === {},
  Print[InputForm[<|"Status" -> "NoActiveFamiliesSelected",
    "RequestedFamilies" -> requestedFamilies,
    "ActiveFamilies" -> allFamilies|>]];
  Exit[65]
];

writeAtomic[value_, file_] := Module[{temporary = file <> ".tmp"},
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

(* Every selected boundary integral is undetermined at at least one rational edge.
   Choose an edge for which the second chart coordinate is normal, because
   that is the endpoint leg of the accepted two-segment automata. *)
endpointForChart[chart_, variables_] := Switch[chart,
  "RationalIdentity" | "source (v,w)",
    <|"Stratum" -> "wEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 0, "LocalDirection" -> 1,
      "FixedRules" -> {variables[[1]] -> 1/2},
      "LeadingCoefficient" -> 1|>,
  "Kallen1",
    <|"Stratum" -> "wEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 1, "LocalDirection" -> -1,
      "FixedRules" -> {variables[[1]] -> 1/2},
      "LeadingCoefficient" -> 1/2|>,
  "Kallen2",
    <|"Stratum" -> "wEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 1, "LocalDirection" -> -1,
      "FixedRules" -> {variables[[1]] -> -1/2},
      "LeadingCoefficient" -> 3/2|>,
  "Kallen3",
    <|"Stratum" -> "wEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 1, "LocalDirection" -> 1,
      "FixedRules" -> {variables[[1]] -> 1/2},
      "LeadingCoefficient" -> 1/2|>,
  "Kallen12",
    <|"Stratum" -> "wEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 1, "LocalDirection" -> 1,
      "FixedRules" -> {variables[[1]] -> 1/2},
      "LeadingCoefficient" -> 3/2|>,
  "Kallen23",
    <|"Stratum" -> "vEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 0, "LocalDirection" -> -1,
      "FixedRules" -> {variables[[1]] -> 1/2},
      "LeadingCoefficient" -> 3/2|>,
  "Q4b",
    <|"Stratum" -> "vEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 1/2, "LocalDirection" -> -1,
      "FixedRules" -> {variables[[1]] -> 1/4},
      "LeadingCoefficient" -> 2|>,
  "Q4a",
    <|"Stratum" -> "wEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 1/2, "LocalDirection" -> -1,
      "FixedRules" -> {variables[[1]] -> 1/4},
      "LeadingCoefficient" -> 2|>,
  "Bilinear115",
    <|"Stratum" -> "wEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 1, "LocalDirection" -> -1,
      "FixedRules" -> {variables[[1]] -> 1/2},
      "LeadingCoefficient" -> 1|>,
  "Multiquadratic3",
    <|"Stratum" -> "wEdge", "Variable" -> variables[[2]],
      "Endpoint" -> 0, "LocalDirection" -> 1,
      "FixedRules" -> {variables[[1]] -> 1/2},
      "LeadingCoefficient" -> 1|>,
  _, Missing["UnsupportedChart", chart]
];

familyFile[directory_, prefix_, family_] :=
  FileNameJoin[{directory, prefix <> family <> ".wl"}];

buildFamily[family_] := Catch@Module[
  {fail, start = AbsoluteTime[], formFile, transportFile, form, transport,
   chart, variables, endpoint, familyBoundaryIntegrals, permutation, realization,
   rows, matches, rowMatches, blockPosition, canonicalRows, realizations, gaugeRules,
   connection, frobeniusSpec, frobeniusSeconds, frobenius, modeSeconds,
   modeMap, outputFile},
  fail[status_, extra_: <||>] := Throw[Join[<|"Family" -> family,
      "Status" -> status|>, extra]];
  formFile = familyFile[formDirectory, "family_epsform_", family];
  transportFile = familyFile[transportDirectory,
    "observable_transport_", family];
  If[!FileExistsQ[formFile], fail["CertifiedEpsilonFormMissing"]];
  If[!FileExistsQ[transportFile],
    fail["ObservableTransportRequiredForGaugeBinding",
      <|"EpsilonFormFile" -> formFile,
        "ExpectedTransportFile" -> transportFile|>]];
  form = Get[formFile];
  transport = Get[transportFile];
  chart = Lookup[form, "Chart", If[
      Lookup[form, "Frame", None] === "SourceVW",
      "source (v,w)", Missing["Chart"]]];
  variables = form["Variables"];
  endpoint = endpointForChart[chart, variables];
  If[MissingQ[endpoint], fail["PhysicalEdgeChartUnsupported",
      <|"Chart" -> chart|>]];
  If[Lookup[transport, "Variables", None] =!= variables,
    fail["TransportFrameMismatch", <|"FormVariables" -> variables,
      "TransportVariables" -> Lookup[transport, "Variables", None]|>]];

  familyBoundaryIntegrals = Select[activeBoundaryIntegrals,
    MemberQ[#["Families"], family] &];
  permutation = Flatten[form["Blocks"]];
  realizations = Map[Function[boundaryIntegral,
    matches = Select[assignments,
      #["Family"] === family &&
        #["ClassID"] === boundaryIntegral["ClassID"] &];
    (* A family may contain the same class in more than one block.  The
       independently deduplicated BlockRows list cannot be paired by
       position with Families, but it is still a safe discriminator when it
       selects exactly one of this family's same-class blocks. *)
    rowMatches = Select[matches, MemberQ[
        Sort /@ Lookup[boundaryIntegral, "BlockRows", {}], Sort[#Rows]] &];
    If[Length[rowMatches] === 1, matches = rowMatches];
    If[Length[matches] =!= 1,
      fail["BoundaryIntegralRealizationNotUnique", <|
        "BoundaryIntegralID" -> boundaryIntegral["BoundaryIntegralID"],
        "ClassID" -> boundaryIntegral["ClassID"],
        "MatchCount" -> Length[matches],
        "CandidateRows" -> Lookup[matches, "Rows", {}],
        "BoundaryIntegralBlockRows" ->
          Lookup[boundaryIntegral, "BlockRows", {}]|>]];
    rows = First[matches]["Rows"];
    blockPosition = FirstPosition[Sort /@ form["Blocks"], Sort[rows],
      Missing["Block"]];
    If[MissingQ[blockPosition],
      fail["BoundaryIntegralBlockNotInEpsilonForm", <|
        "BoundaryIntegralID" -> boundaryIntegral["BoundaryIntegralID"],
        "OriginalRows" -> rows|>]];
    canonicalRows = form["Ranges"][[First[blockPosition]]];
    realization = <|
      "BoundaryConstantID" ->
        {family, boundaryIntegral["BoundaryIntegralID"]},
      "FrobeniusModeID" ->
        {family, boundaryIntegral["BoundaryIntegralID"]},
      "BoundaryIntegralID" -> boundaryIntegral["BoundaryIntegralID"],
      "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
      "BoundaryConstantEpsilonValuation" -> 0,
      "CanonicalRows" -> canonicalRows,
      "PhysicalRows" -> canonicalRows,
      "ConstraintRows" -> Range[Max[canonicalRows]],
      "DemandedOutputs" -> transport["PhysicalDemandPairs"],
      "EpsilonExponent" -> boundaryIntegral["EpsPart"],
      "IntegerValuation" ->
        boundaryIntegral["IntegerValuation", endpoint["Stratum"]],
      "LogLevel" -> boundaryIntegral["LogLevel"],
      (* a repeated block eigenvalue whose admissible directions the
         valuation cannot separate is realized as its whole canonical
         eigenspace basis (one exact sub-realization per direction), never
         by a silent choice; the ledger records the split *)
      "DegenerateResidueEigenspacePolicy" -> "Basis"|>;
    If[MemberQ[{1, 6, 7}, boundaryIntegral["BoundaryIntegralID"]],
      Join[realization, <|"KnownCoefficient" -> 0|>], realization]
  ], familyBoundaryIntegrals];

  gaugeRules = Lookup[transport, "GaugeConstantRules", {}];
  connection = form["EpsFormY"] /. gaugeRules;
  frobeniusSpec = <|
    "Variable" -> endpoint["Variable"],
    "Regulator" -> form["Regulator"],
    "LocalVariable" -> Global`rho,
    "LocalExpansionPoint" -> endpoint["Endpoint"],
    "LocalDirection" -> endpoint["LocalDirection"],
    "FixedRules" -> endpoint["FixedRules"]|>;
  frobeniusSeconds = First@AbsoluteTiming[
    frobenius = ComputeTruncatedLocalFrobeniusExpansion[
      connection, frobeniusSpec,
      "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 3]];
  If[Lookup[frobenius, "Status", None] =!=
      "TruncatedLocalFrobeniusExpansionComputed",
    fail["TruncatedLocalFrobeniusExpansionFailed", <|"Result" -> frobenius,
      "Seconds" -> frobeniusSeconds|>]];
  modeSeconds = First@AbsoluteTiming[
    modeMap = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
      form["TTotal"] /. gaugeRules,
      <|"Family" -> family, "Limit" -> endpoint["Stratum"],
        "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint",
          "Coordinates" -> Join[endpoint["FixedRules"],
            {endpoint["Variable"] -> endpoint["Endpoint"]}]|>,
        "FixedRules" -> endpoint["FixedRules"],
        "PhysicalEndpointRelation" -> <|
          "Stratum" -> endpoint["Stratum"], "LocalPower" -> 1,
          "LeadingCoefficient" -> endpoint["LeadingCoefficient"]|>|>,
      realizations]];
  If[Lookup[modeMap, "Status", None] =!= "BoundaryAsymptoticModeMatching",
    fail["BoundaryAsymptoticModeMatchingFailed", <|"Result" -> modeMap,
      "Seconds" -> modeSeconds|>]];
  modeMap = Join[modeMap, <|
    "CampaignRecordStatus" -> "PhysicalBoundaryModeMapAcceptedV1",
    "Chart" -> chart,
    "GaugeConstantRules" -> gaugeRules,
    "BoundaryIntegralIDs" ->
      Lookup[familyBoundaryIntegrals, "BoundaryIntegralID"],
    "BoundaryIntegralIDsWithEvaluatedValues" -> Intersection[
      Lookup[familyBoundaryIntegrals, "BoundaryIntegralID"],
      certifiedBoundaryIntegralIDs],
    "BoundaryIntegralIDsKnownToVanish" -> Intersection[
      Lookup[familyBoundaryIntegrals, "BoundaryIntegralID"], {1, 6, 7}],
    "FrobeniusModeIDs" -> Lookup[realizations, "FrobeniusModeID"],
    "SourceFiles" -> <|"EpsilonForm" -> formFile,
      "ObservableTransport" -> transportFile|>,
    "TimingsSeconds" -> <|"Frobenius" -> frobeniusSeconds,
      "ModeMatching" -> modeSeconds,
      "Total" -> AbsoluteTime[] - start|>|>];
  outputFile = FileNameJoin[{outputDirectory,
    "boundary_mode_" <> family <> ".wl"}];
  writeAtomic[modeMap, outputFile];
  <|"Family" -> family, "Status" -> "Accepted",
    "Chart" -> chart, "Stratum" -> endpoint["Stratum"],
    "BoundaryConstantCount" -> Length[realizations],
    "FrobeniusModeCount" -> Length[Lookup[modeMap, "FrobeniusModes", {}]],
    "DegenerateResidueEigenspaceBases" ->
      Lookup[modeMap, "DegenerateResidueEigenspaceBases", {}],
    "FrobeniusSeconds" -> frobeniusSeconds,
    "ModeSeconds" -> modeSeconds,
    "TotalSeconds" -> AbsoluteTime[] - start,
    "Output" -> outputFile|>
];

campaignStart = AbsoluteTime[];
results = Table[
  result = buildFamily[family];
  Print[InputForm[result]];
  result,
  {family, families}];
summary = <|
  "Status" -> If[AllTrue[results,
      Lookup[#, "Status", None] === "Accepted" &],
    "PhysicalBoundaryModeCampaignAcceptedV1",
    "PhysicalBoundaryModeCampaignIncomplete"],
  "RequestedFamilies" -> families,
  "AcceptedFamilies" -> Lookup[
    Select[results, Lookup[#, "Status", None] === "Accepted" &], "Family"],
  "Results" -> results,
  "BoundaryIntegralIDs" -> structuralBoundaryIntegralIDs,
  "BoundaryIntegralIDsWithEvaluatedValues" -> certifiedBoundaryIntegralIDs,
  "BoundaryConstantCount" ->
    Total[Lookup[results, "BoundaryConstantCount", 0]],
  "FrobeniusModeCount" ->
    Total[Lookup[results, "FrobeniusModeCount", 0]],
  "DegenerateResidueEigenspaceBases" ->
    Flatten[Lookup[results, "DegenerateResidueEigenspaceBases", {}]],
  "Seconds" -> AbsoluteTime[] - campaignStart|>;
summaryFile = If[Length[requestedFamilies] === 1,
  "campaign_summary_" <> First[requestedFamilies] <> ".wl",
  "campaign_summary.wl"];
writeAtomic[summary, FileNameJoin[{outputDirectory, summaryFile}]];
Print[InputForm[KeyTake[summary, {"Status", "AcceptedFamilies",
  "BoundaryIntegralIDs", "BoundaryConstantCount", "FrobeniusModeCount",
  "DegenerateResidueEigenspaceBases", "Seconds"}]]];
If[summary["Status"] =!= "PhysicalBoundaryModeCampaignAcceptedV1",
  Exit[1]];
Quit[];
