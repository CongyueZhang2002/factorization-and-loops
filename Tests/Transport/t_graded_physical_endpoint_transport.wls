#!/usr/bin/env wolframscript

(* Unit tests for the graded endpoint construction.  All boundary data are
   built from a mathematical fixture in this process; no generated campaign
   artifact is treated as an authoritative mode map. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];
Get[FileNameJoin[{root, "Scripts", "Transport",
  "PhysicalBoundaryCampaignAdapter.wl"}]];

x = Symbol["Global`gradedX"];
y = Symbol["Global`gradedY"];
eps = Symbol["Global`eps"];
rho = Symbol["Global`gradedRho"];
family = "GradedEndpointToy";

connection = {
  eps {{0, 0}, {1/x, 0}},
  eps {{0, 0}, {1/y, 0}}
};
familySystem = <|
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> family, "KinematicVariables" -> {x, y},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" ->
    {gradedMaster[family, {1}], gradedMaster[family, {2}]},
  "ConnectionMatrices" -> connection|>;
workingEpsilonForm = <|
  "Family" -> family, "Variables" -> {x, y}, "Regulator" -> eps,
  "Ranges" -> {{1}, {2}}, "Blocks" -> {{1}, {2}},
  "TTotal" -> IdentityMatrix[2], "TTotalInverse" -> IdentityMatrix[2],
  "EpsFormX" -> connection[[1]], "EpsFormY" -> connection[[2]]|>;
epsilonForm = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  workingEpsilonForm, familySystem, <|
    "RelativePath" -> "graded_endpoint_toy.wl",
    "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
    "Family" -> family|>, "IdentityMethod" -> "Symbolic"];
path = <|"FirstVariable" -> x, "SecondVariable" -> y,
  "FirstBase" -> 3, "SecondBase" -> 1/2,
  "FirstPathParameterScale" -> 1|>;
demand = <|
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" ->
    Flatten[Table[{order, row}, {order, 0, 2}, {row, 2}], 1],
  "MinimumRetainedMasterIntegralEpsilonOrder" -> 0,
  "RegularBasePointAndFirstPathParameterScale" -> path|>;
transport =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    epsilonForm, demand,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints"];

frobenius = ComputeTruncatedLocalFrobeniusExpansion[
  connection[[2]], <|"Variable" -> y, "Regulator" -> eps,
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
pathSegmentSequenceKey[term_] := With[
  {currentFirst = Lookup[term,
      "CurrentPathFirstSegmentLetterIndices", {}],
   currentSecond = Lookup[term,
      "CurrentPathSecondSegmentLetterIndices", {}],
   boundaryFirst = Lookup[term,
      "BoundaryPathFirstSegmentLetterIndices", {}],
   boundarySecond = Lookup[term,
      "BoundaryPathSecondSegmentLetterIndices", {}]},
  HoldComplete[currentFirst, currentSecond, boundaryFirst, boundarySecond]];
nonzeroVectorQ[vector_] := AnyTrue[Flatten[vector], Not@*PossibleZeroQ];
canonicalCoefficientMatrices[result_] := Association@Map[Function[term,
    pathSegmentSequenceKey[term] -> Association@Select[
      Thread[(coordinateKey /@
          result["BoundaryConstantEpsilonCoefficientRecords"]) ->
        Transpose[Normal[term["IteratedIntegralCoefficientMatrix"]]]],
        nonzeroVectorQ[Last[#]] &]],
  result["IteratedIntegralCoefficientMatrixRecords"]];

buildTiming = AbsoluteTiming[
  binding = FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    transport, modeMap, <||>]];
FTAssert["a typed point-boundary fixture closes by exact weight without enumerating its alphabet product",
  binding["Status"] === "GradedPhysicalEndpointTransportBuilt" &&
    binding["BoundaryDataType"] === "BoundaryConstant" &&
    binding["MaximumCurrentWeight"] ===
      transport["ExactIteratedIntegralCoefficientOperator",
        "MaximumIteratedIntegralWeight"] &&
    Length[binding["GradesByWeight"]] >= 1 &&
    TrueQ[binding["FormalResultConvention",
      "NoAlphabetCartesianEnumeration"]]];

zeroPair = {{}, {}};
directAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, modeMap, <||>,
    "RequestedPathSegmentLetterIndexSequencePairs" -> {zeroPair}];
directZero =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
    directAdapter, transport, {zeroPair}];
gradedZero = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  binding, transport, {zeroPair}];
FTAssert["the zero-letter-sequence coefficient matrix agrees with independent demand pruning",
  directZero["Status"] ===
      "EndpointAutomatonBoundaryCoefficientMapsBuilt" &&
    gradedZero["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    canonicalCoefficientMatrices[directZero] ===
      canonicalCoefficientMatrices[gradedZero]];

firstIndex = First[transport["ExactIteratedIntegralCoefficientOperator",
  "FirstPathSegmentAlphabetLetterIndices"]];
secondIndex = First[transport["ExactIteratedIntegralCoefficientOperator",
  "SecondPathSegmentAlphabetLetterIndices"]];
requestedPairs = {{{firstIndex}, {}}, {{}, {secondIndex}},
  {{firstIndex}, {secondIndex}}};
directAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    transport, modeMap, <||>,
    "RequestedPathSegmentLetterIndexSequencePairs" -> requestedPairs];
directWords =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
    directAdapter, transport, requestedPairs];
gradedWords = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  binding, transport, requestedPairs];
FTAssert["first-segment, second-segment and mixed coefficient matrices retain the four-segment multiplication order",
  directWords["Status"] ===
      "EndpointAutomatonBoundaryCoefficientMapsBuilt" &&
    gradedWords["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    canonicalCoefficientMatrices[directWords] ===
      canonicalCoefficientMatrices[gradedWords]];

zeroAutomaton = Join[
  transport["ExactIteratedIntegralCoefficientOperator"], <|
  "FirstPathSegmentOperatorMatrices" ->
    (0 # & /@ transport["ExactIteratedIntegralCoefficientOperator",
      "FirstPathSegmentOperatorMatrices"]),
  "SecondPathSegmentOperatorMatrices" ->
    (0 # & /@ transport["ExactIteratedIntegralCoefficientOperator",
      "SecondPathSegmentOperatorMatrices"])
|>];
zeroTransport = Join[transport, <|
  "ExactIteratedIntegralCoefficientOperator" -> zeroAutomaton|>];
zeroBinding =
  FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    zeroTransport, modeMap, <||>];
zeroWords = FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
  zeroBinding, zeroTransport, {{{firstIndex}, {}}}];
FTAssert["a requested letter sequence in an exactly zero row-space grade gives no coefficient matrix",
  zeroWords["Status"] === "GradedPhysicalEndpointWordsBuilt" &&
    zeroWords["IteratedIntegralCoefficientMatrixRecords"] === {} &&
    AllTrue[zeroWords["BoundaryDataRequirements"],
      Lookup[#, "BoundaryConstantEpsilonCoefficientLabels", Missing[]] === {} &]];

boundedDemand = Join[demand, <|
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" ->
    Flatten[Table[{order, row}, {order, 0, 1}, {row, 2}], 1]|>];
boundedOperator =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    epsilonForm, boundedDemand,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints"];
boundedBinding =
  FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
    boundedOperator, modeMap, <||>];
boundedFirstIndex = First[
  boundedOperator["ExactIteratedIntegralCoefficientOperator",
    "FirstPathSegmentAlphabetLetterIndices"]];
boundedSecondIndex = First[
  boundedOperator["ExactIteratedIntegralCoefficientOperator",
    "SecondPathSegmentAlphabetLetterIndices"]];
boundedPairs = {{{}, {}}, {{boundedFirstIndex}, {}},
  {{}, {boundedSecondIndex}}};
boundedAdapter =
  FeynFacetCampaign`PhysicalBoundary`BuildEndpointAutomatonBoundaryAdapter[
    boundedOperator, modeMap, <||>,
    "RequestedPathSegmentLetterIndexSequencePairs" -> boundedPairs];
boundedDirect =
  FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps[
    boundedAdapter, boundedOperator, boundedPairs];
boundedGraded =
  FeynFacetCampaign`PhysicalBoundary`ComposeGradedPhysicalEndpointWords[
    boundedBinding, boundedOperator, boundedPairs];
FTAssert["an independently constructed bounded lazy operator preserves endpoint-composition coefficients",
  IteratedIntegralCoefficientOperatorForRequestedOutputsQ[boundedOperator] &&
    boundedBinding["Status"] === "GradedPhysicalEndpointTransportBuilt" &&
    canonicalCoefficientMatrices[boundedDirect] ===
      canonicalCoefficientMatrices[boundedGraded]];

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
