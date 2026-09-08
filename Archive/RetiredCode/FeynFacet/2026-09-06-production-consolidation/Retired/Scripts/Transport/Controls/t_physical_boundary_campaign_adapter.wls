#!/usr/bin/env wolframscript

(* Focused control for the endpoint adapter.  The local Frobenius data and
   boundary-domain type are constructed here rather than loaded from a
   generated campaign record. *)
Block[{$HistoryLength = 0}, Module[
 {repo, checks = {}, check, x, y, eps, rho, family, epsilonForm, path,
  demand, transport, frobenius, constantRealizations, constantModeMap,
  adapter, composition, firstIndex, missingLetters, missingModes,
  insufficientDepth, logarithmicMode, logarithmicFailure,
  knownZeroModeMap, knownZeroAdapter,
  functionRealizations, functionModeMap,
  functionAdapter, testResult},

repo = ExpandFileName@FileNameJoin[
  {DirectoryName[$InputFileName], "..", "..", ".."}];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{repo, "Scripts", "Transport",
  "PhysicalBoundaryCampaignAdapter.wl"}]];

check[name_, condition_] := AppendTo[checks, name -> TrueQ[condition]];
x = Symbol["Global`endpointControlX"];
y = Symbol["Global`endpointControlY"];
eps = Symbol["Global`eps"];
rho = Symbol["Global`endpointControlRho"];
family = "EndpointAdapterControl";

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
  "FirstPathParameterScale" -> 1|>;
demand = <|
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> Flatten[
    Table[{order, row}, {order, 0, 2}, {row, 2}], 1],
  "MinimumRetainedMasterIntegralEpsilonOrder" -> 0,
  "RegularBasePointAndFirstPathParameterScale" -> path|>;
transport =
  FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    epsilonForm, demand,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints",
    "IteratedIntegralCoefficientRepresentation" ->
      "IteratedIntegralCoefficientOperatorForRequestedOutputs"];

frobenius = FeynFacet`ComputeTruncatedLocalFrobeniusExpansion[
  epsilonForm["EpsFormY"], <|"Variable" -> y, "Regulator" -> eps,
    "LocalVariable" -> rho, "LocalExpansionPoint" -> 1,
    "LocalDirection" -> -1, "FixedRules" -> {x -> 2}|>,
  "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 3];
constantRealizations = Table[<|
    "BoundaryConstantID" -> {family, id},
    "FrobeniusModeID" -> {family, id}, "BoundaryIntegralID" -> id,
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0,
    "CanonicalRows" -> {id}, "PhysicalRows" -> {id},
    "ConstraintRows" -> Range[id],
    "DemandedOutputs" -> Flatten[
      Table[{order, row}, {order, 0, 2}, {row, 2}], 1],
    "EpsilonExponent" -> 0, "IntegerValuation" -> 0,
    "LogLevel" -> 0|>, {id, 2}];
constantModeMap = FeynFacet`MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
  IdentityMatrix[2], <|"Family" -> family,
    "Limit" -> "controlPoint", "FixedRules" -> {x -> 2},
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint",
      "Coordinates" -> {x -> 2, y -> 1}|>,
    "PhysicalEndpointRelation" -> <|"Stratum" -> "controlPoint",
      "LocalPower" -> 1, "LeadingCoefficient" -> 1|>|>,
  constantRealizations];

adapter = FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
  transport, constantModeMap, <||>,
  "BoundaryDataEpsilonOrderWindow" -> {0, 2},
  "RequestedPathSegmentLetterIndexSequencePairs" -> {{{}, {}}}];
composition =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
    adapter, transport, {{{}, {}}}];
check["typed point-boundary adapter builds",
  AssociationQ[adapter] && adapter["Status"] ===
      "EndpointAutomatonBoundaryAdapterBuilt" &&
    adapter["BoundaryDataType"] === "BoundaryConstant"];
check["endpoint and interior base are distinct and both connecting segments are retained",
  adapter["Path", "Endpoint", "Point"] =!=
      adapter["Path", "InteriorBase", "Point"] &&
    Length[adapter["Path", "Segments"]] === 2 &&
    AnyTrue[adapter[
        "BoundaryPathIteratedIntegralCoefficientMatrixTerms"],
      Total[Length /@ Lookup[#,
        {"BoundaryPathFirstSegmentLetterIndices",
          "BoundaryPathSecondSegmentLetterIndices"}, {}]] === 1 &]];
check["composition returns typed boundary-constant coefficient maps",
  composition["Status"] ===
      "EndpointAutomatonBoundaryCoefficientMapsBuilt" &&
    ListQ[composition["BoundaryConstantEpsilonCoefficientRecords"]] &&
    AnyTrue[composition["BoundaryDataRequirements"],
      Lookup[#, "Status", None] === "Unevaluated" &]];

firstIndex = First[transport["ExactIteratedIntegralCoefficientOperator",
  "FirstPathSegmentAlphabetLetterIndices"]];
check["an unprepared current-path word fails typed",
  MatchQ[
    FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
      adapter, transport, {{{firstIndex}, {}}}],
    Failure["EndpointDemandWordNotPrepared", _Association]]];

missingLetters =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    KeyDrop[transport, "Letters"], constantModeMap, <||>,
    "MaximumConnectorWeight" -> 0,
    "BoundaryDataEpsilonOrderWindow" -> {0, 1}];
missingModes =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, Join[constantModeMap, <|"FrobeniusModes" -> {}|>], <||>,
    "MaximumConnectorWeight" -> 0,
    "BoundaryDataEpsilonOrderWindow" -> {0, 1}];
insufficientDepth =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, constantModeMap, <||>, "MaximumConnectorWeight" -> 0,
    "BoundaryDataEpsilonOrderWindow" -> {0, 2}];
check["missing letters, missing modes and insufficient connector depth refuse with distinct statuses",
  MatchQ[missingLetters, Failure["MissingFirstSegmentMap", _Association]] &&
    MatchQ[missingModes,
      Failure["MissingEndpointModeRealization", _Association]] &&
    MatchQ[insufficientDepth,
      Failure["EndpointConnectorDepthInsufficient", _Association]]];

logarithmicMode = Join[First[constantModeMap["FrobeniusModes"]], <|
  "LocalEigenvalue" -> 1, "GeneralizedLevel" -> 0|>];
logarithmicFailure =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, Join[constantModeMap,
      <|"FrobeniusModes" -> {logarithmicMode}|>], <||>,
    "MaximumConnectorWeight" -> 0,
    "BoundaryDataEpsilonOrderWindow" -> {0, 1}];
check["nonzero local exponents name the required logarithmic normalization",
  MatchQ[logarithmicFailure,
      Failure["TangentialLogModeRequired", _Association]] &&
    KeyExistsQ[Last[logarithmicFailure], "RequiredLocalNormalization"]];

knownZeroModeMap = Join[constantModeMap, <|"FrobeniusModes" ->
  MapAt[Join[#, <|"KnownCoefficient" -> 0|>] &,
    constantModeMap["FrobeniusModes"], 2]|>];
knownZeroAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, knownZeroModeMap, <||>,
    "BoundaryDataEpsilonOrderWindow" -> {0, 2}];
check["a known-zero boundary constant remains explicit in the requirements and contributes no coefficient coordinate",
  AnyTrue[knownZeroAdapter["BoundaryDataRequirements"],
      Lookup[#, "BoundaryConstantID", None] === {family, 2} &&
        Lookup[#, "Status", None] === "KnownZero" &] &&
    FreeQ[Lookup[knownZeroAdapter[
      "BoundaryConstantEpsilonCoefficientRecords"], "BoundaryConstantID"],
      {family, 2}]];

functionRealizations = Table[<|
    "BoundaryFunctionID" -> {family, "f", id},
    "FrobeniusModeID" -> {family, "f", id},
    "DeclaredBoundaryFunctionClass" -> "GPL",
    "BoundaryFunctionEpsilonValuation" -> 0,
    "CanonicalRows" -> {id}, "PhysicalRows" -> {id},
    "ConstraintRows" -> Range[id],
    "DemandedOutputs" -> {{0, 1}, {0, 2}},
    "EpsilonExponent" -> 0, "IntegerValuation" -> 0,
    "LogLevel" -> 0|>, {id, 2}];
functionModeMap = FeynFacet`MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
  IdentityMatrix[2], <|"Family" -> family,
    "Limit" -> "controlStratum", "FixedRules" -> {},
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryStratum",
      "TangentialVariables" -> {x}|>,
    "PhysicalEndpointRelation" -> <|"Stratum" -> "controlStratum",
      "LocalPower" -> 1, "LeadingCoefficient" -> 1|>|>,
  functionRealizations];
functionAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, functionModeMap, <||>,
    "BoundaryDataEpsilonOrderWindow" -> {0, 1}];
check["a positive-dimensional boundary is identified as function-valued and refused until tangential arguments are represented",
  functionModeMap["BoundaryDataType"] === "BoundaryFunction" &&
    MatchQ[functionAdapter,
      Failure["BoundaryFunctionEndpointTransportNotImplemented",
        _Association]]];

check["the obsolete period composer is absent",
  ! NameQ[
    "FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords"]];

testResult = <|"Status" -> If[And @@ Last /@ checks, "PASS", "FAIL"],
  "Checks" -> checks,
  "BoundaryConstantCoefficientCount" -> If[AssociationQ[adapter],
    Length[Lookup[adapter,
      "BoundaryConstantEpsilonCoefficientRecords", {}]], Missing[]],
  "BoundaryFunctionTransportStatus" ->
    Lookup[Last[functionAdapter], "Status", Missing[]]|>;
Print[InputForm[testResult]];
If[TrueQ[KernelPoolMission`$MissionSafe], testResult,
  Exit[If[testResult["Status"] === "PASS", 0, 1]]]
]]
