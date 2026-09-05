#!/usr/bin/env wolframscript

(* Singular-boundary production path: local Frobenius recurrence, exact
   physical-mode normalization, and separation of transport selectors from
   GPL/elliptic boundary constants.  Everything is a bounded 2x2 control. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

FTAssert["the local-solution APIs are exported without compatibility aliases",
  StringQ[ComputeTruncatedLocalFrobeniusExpansion::usage] &&
    StringQ[TransformTangentialConnectionToNormalResidueEigenbasis::usage] &&
    ! NameQ["FeynFacet`BuildEndpointFrobenius"] &&
    ! NameQ["FeynFacet`BuildEndpointLeveltModeConnection"]];

u = Symbol["Global`boundaryU"];
rho = Symbol["Global`boundaryRho"];
eps = Symbol["Global`eps"];
elliptic0 = Inactive[EllipticK][1/2];
elliptic1 = Inactive[EllipticE][1/3];
residue = ConstantArray[0, {2, 2}];
regular = {{0, 1}, {0, 0}};
connection = eps (residue/u + regular);
endpointSpec = <|"Variable" -> u, "Regulator" -> eps,
  "LocalVariable" -> rho, "LocalExpansionPoint" -> 0|>;

frobenius = ComputeTruncatedLocalFrobeniusExpansion[connection, endpointSpec,
  "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 2];
FTAssert["an ordinary point produces a finite exact local Frobenius expansion",
  frobenius["Status"] === "TruncatedLocalFrobeniusExpansionComputed" &&
    frobenius["PointType"] === "OrdinaryPoint" &&
    frobenius["LocalExpansionPoint"] === 0 &&
    frobenius["Residue"] === residue &&
    frobenius["FrobeniusPrefactorCoefficients"][{1, 1}] === regular &&
    frobenius["ResidualCheckedThrough"] ===
      <|"SeriesOrder" -> 1, "EpsilonOrder" -> 2|>];

reverseFrobenius = ComputeTruncatedLocalFrobeniusExpansion[
  eps (residue/(u - 1) + regular),
  Join[endpointSpec,
    <|"LocalExpansionPoint" -> 1, "LocalDirection" -> -1|>],
  "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 2];
FTAssert["an inward endpoint coordinate includes its differential Jacobian",
  reverseFrobenius["Status"] ===
      "TruncatedLocalFrobeniusExpansionComputed" &&
    reverseFrobenius["LocalDirection"] === -1 &&
    reverseFrobenius["Residue"] === residue &&
    reverseFrobenius["FrobeniusPrefactorCoefficients"][{1, 1}] ===
      -regular];

inwardScalarFrobenius = ComputeTruncatedLocalFrobeniusExpansion[{{0}},
  <|"Variable" -> u, "Regulator" -> eps, "LocalVariable" -> rho,
    "LocalExpansionPoint" -> 1, "LocalDirection" -> -1|>,
  "MaximumSeriesOrder" -> 1, "MaximumEpsilonOrder" -> 1];
inwardScalarMode = MatchBoundaryAsymptoticsToFrobeniusModes[inwardScalarFrobenius,
  {{1 - u}}, <|"Family" -> "InwardCoordinateControl",
    "Limit" -> <|"Variable" -> u, "Endpoint" -> 1|>,
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint"|>,
    "PhysicalEndpointRelation" -> <|"LocalPower" -> 1,
      "LeadingCoefficient" -> 1|>|>,
  {<|"BoundaryConstantID" -> "inward",
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0, "CanonicalRows" -> {1},
    "PhysicalRows" -> {1}, "EpsilonExponent" -> 0,
    "IntegerValuation" -> 1, "LogLevel" -> 0,
    "DemandedOutputs" -> {{0, 1}}|>}];
FTAssert["mode normalization uses the same inward coordinate as its Frobenius series",
  inwardScalarMode["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    inwardScalarMode["LocalExpansionSpecification", "LocalDirection"] === -1 &&
    inwardScalarMode["FrobeniusModes"][[1, "CanonicalMode"]] === {1} &&
    inwardScalarMode["FrobeniusModes"][[1, "PhysicalLeadingCoefficients"]] === {1}];

FTAssert["non-epsilon-form and higher-order endpoint poles are refused typed",
  ComputeTruncatedLocalFrobeniusExpansion[
      connection + IdentityMatrix[2],
      endpointSpec]["Status"] === "ConnectionNotEpsilonForm" &&
    ComputeTruncatedLocalFrobeniusExpansion[
      eps IdentityMatrix[2]/u^2, endpointSpec]["Status"] ===
      "ConnectionNotFuchsianAtLocalExpansionPoint"];

eigenbasisP = Symbol["Global`eigenbasisP"];
normalResidueEigenbasis = {{1, 0}, {1/eigenbasisP, 1}};
localExponents = {0, -2 - 4 eps};
expectedTangentialConnection =
  {{eps/eigenbasisP, 0}, {0, 2 eps/(1 - eigenbasisP)}};
normalResidue = Together[
  normalResidueEigenbasis.DiagonalMatrix[localExponents].
    Inverse[normalResidueEigenbasis]];
tangentialConnection = Together[
  normalResidueEigenbasis.expectedTangentialConnection.
      Inverse[normalResidueEigenbasis] +
    D[normalResidueEigenbasis, eigenbasisP].
      Inverse[normalResidueEigenbasis]];
eigenbasisResult = TransformTangentialConnectionToNormalResidueEigenbasis[
  normalResidue, tangentialConnection,
  <|"TangentialVariable" -> eigenbasisP, "Regulator" -> eps,
    "NormalResidueEigenbasis" -> normalResidueEigenbasis,
    "LocalExponents" -> localExponents|>];
FTAssert["the tangential connection is transformed in a moving normal-residue eigenbasis",
  eigenbasisResult["Status"] ===
      "TangentialConnectionTransformedToNormalResidueEigenbasis" &&
    And @@ Flatten[MapThread[Together[#1 - #2] === 0 &,
      {eigenbasisResult["TangentialConnectionInEigenbasis"],
       expectedTangentialConnection}, 2]] &&
    Lookup[eigenbasisResult["ExponentData"], "IntegerPart"] === {0, -2} &&
    Lookup[eigenbasisResult["ExponentData"], "RegulatorCoefficient"] ===
      {0, -4} &&
    Lookup[eigenbasisResult["EqualExponentSectors"], "Indices"] ===
      {{1}, {2}}];

FTAssert["an invalid residue eigenbasis and unequal-exponent tangential mixing are refused typed",
  TransformTangentialConnectionToNormalResidueEigenbasis[normalResidue,
      tangentialConnection, <|"TangentialVariable" -> eigenbasisP,
        "Regulator" -> eps,
        "NormalResidueEigenbasis" -> IdentityMatrix[2],
        "LocalExponents" -> localExponents|>]["Status"] ===
      "NormalResidueEigenbasisInvalid" &&
    TransformTangentialConnectionToNormalResidueEigenbasis[normalResidue,
      tangentialConnection +
        normalResidueEigenbasis.{{0, 1}, {0, 0}}.
          Inverse[normalResidueEigenbasis],
      <|"TangentialVariable" -> eigenbasisP, "Regulator" -> eps,
        "NormalResidueEigenbasis" -> normalResidueEigenbasis,
        "LocalExponents" -> localExponents|>]["Status"] ===
      "UnequalExponentSectorsCoupled"];

modeSpec = <|
  "Family" -> "SyntheticBoundaryControl",
  "Limit" -> <|"Variable" -> u, "Endpoint" -> 0,
    "Direction" -> "Positive"|>,
  "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint"|>,
  "PhysicalEndpointRelation" -> <|
    "LocalPower" -> 1, "LeadingCoefficient" -> 1|>|>;
realizations = {
  <|"BoundaryConstantID" -> "g", "BoundaryIntegralID" -> "I_g",
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0, "CanonicalRows" -> {1},
    "PhysicalRows" -> {1}, "EpsilonExponent" -> 0,
    "IntegerValuation" -> 0, "LogLevel" -> 0,
    "DemandedOutputs" -> {{0, 1}, {1, 1}, {3, 1}}|>,
  <|"BoundaryConstantID" -> "e", "BoundaryIntegralID" -> "I_e",
    "DeclaredBoundaryConstantAnalyticClass" -> "Elliptic",
    "BoundaryConstantEpsilonValuation" -> 0, "CanonicalRows" -> {2},
    "PhysicalRows" -> {2}, "EpsilonExponent" -> 0,
    "IntegerValuation" -> 0, "LogLevel" -> 0,
    "DemandedOutputs" -> {{0, 2}, {1, 2}}|>
};
modeMap = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius, {{1, 0}, {u, 2}},
  modeSpec, realizations];
FTAssert["physical modes are globally extended and normalized in the canonical boundary space",
    modeMap["Status"] ===
        "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    modeMap["LocalExpansionSpecification"] === <|"Variable" -> u,
      "LocalExpansionPoint" -> 0, "LocalDirection" -> 1, "FixedRules" -> {}|> &&
    modeMap["FrobeniusModes"][[1, "CanonicalMode"]] === {1, 0} &&
    modeMap["FrobeniusModes"][[2, "CanonicalMode"]] === {0, 1/2} &&
    modeMap["FrobeniusModes"][[All, "PhysicalToLocalMode"]] ===
      modeMap["FrobeniusModes"][[All, "CanonicalMode"]] &&
    modeMap["FrobeniusModes"][[All, "BoundaryIntegralID"]] ===
      {"I_g", "I_e"} &&
    modeMap["FrobeniusModes"][[All, "PhysicalLocalOrders"]] === {{0}, {0}} &&
    Lookup[modeMap["BoundaryDataRequirements"], "Status"] ===
      {"Unevaluated", "Unevaluated"}];

coordinateResidue = {{2, 1}, {0, 2}};
coordinateFrobenius = ComputeTruncatedLocalFrobeniusExpansion[
  eps coordinateResidue/u, endpointSpec,
  "MaximumSeriesOrder" -> 1, "MaximumEpsilonOrder" -> 2];
FTAssert["a nonzero Fuchsian residue classifies the local expansion point as regular singular",
  coordinateFrobenius["Status"] ===
      "TruncatedLocalFrobeniusExpansionComputed" &&
    coordinateFrobenius["PointType"] === "RegularSingularPoint"];
coordinateSpec = <|
  "Family" -> "SyntheticCoordinateControl",
  "Limit" -> <|"Variable" -> u, "Endpoint" -> 0,
    "Direction" -> "Positive"|>,
  "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint"|>,
  "PhysicalEndpointRelation" -> <|
    "LocalPower" -> 2, "LeadingCoefficient" -> 4|>|>;
coordinateRealizations = {
  <|"BoundaryConstantID" -> "eigen",
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0, "CanonicalRows" -> {1},
    "ConstraintRows" -> {1, 2}, "PhysicalRows" -> {1},
    "EpsilonExponent" -> 1, "IntegerValuation" -> 0,
    "LogLevel" -> 0, "DemandedOutputs" -> {{0, 1}}|>,
  <|"BoundaryConstantID" -> "jordan",
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0, "CanonicalRows" -> {2},
    "ConstraintRows" -> {1, 2}, "PhysicalRows" -> {2},
    "EpsilonExponent" -> 1, "IntegerValuation" -> 0,
    "LogLevel" -> 1, "DemandedOutputs" -> {{0, 2}}|>
};
coordinateModes = MatchBoundaryAsymptoticsToFrobeniusModes[coordinateFrobenius,
  IdentityMatrix[2], coordinateSpec, coordinateRealizations];
coordinateLog = Log[4];
expectedCoordinateModes = {
  {1 + eps coordinateLog + eps^2 coordinateLog^2/2, 0},
  {eps coordinateLog/2 + eps^2 coordinateLog^2/2,
   1 + eps coordinateLog + eps^2 coordinateLog^2/2}};
FTAssert["t = alpha rho^kappa converts eigenvectors and Jordan modes through the retained epsilon order",
  coordinateModes["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    coordinateModes["FrobeniusModes"][[All, "CanonicalMode"]] ===
      {{1, 0}, {0, 1}} &&
    And @@ Flatten[MapThread[Together[#1 - #2] === 0 &,
      {coordinateModes["FrobeniusModes"][[All, "PhysicalToLocalMode"]],
       expectedCoordinateModes}, 2]]];

negativeCoordinateSpec = MapAt[
  Join[#, <|"LeadingCoefficient" -> -4|>] &,
  coordinateSpec, Key["PhysicalEndpointRelation"]];
negativeCoordinateModes = MatchBoundaryAsymptoticsToFrobeniusModes[coordinateFrobenius,
  IdentityMatrix[2], negativeCoordinateSpec, coordinateRealizations];
branchedCoordinateModes = MatchBoundaryAsymptoticsToFrobeniusModes[coordinateFrobenius,
  IdentityMatrix[2], MapAt[Join[#, <|"LeadingCoefficient" -> -4,
      "LogBranch" -> -1|>] &, coordinateSpec,
    Key["PhysicalEndpointRelation"]], coordinateRealizations];
zeroNegativeModes = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
  {{1, 0}, {u, 2}}, MapAt[
    Join[#, <|"LeadingCoefficient" -> -4|>] &, modeSpec,
    Key["PhysicalEndpointRelation"]], realizations];
FTAssert["a non-positive coordinate factor needs an explicit logarithm branch only when the residue acts nontrivially",
  negativeCoordinateModes["Status"] ===
      "BoundaryAsymptoticsNotFullyMatchedToFrobeniusModes" &&
    Lookup[negativeCoordinateModes["FrobeniusModes"], "Status"] ===
      {"PhysicalLimitLogBranchRequired",
       "PhysicalLimitLogBranchRequired"} &&
    branchedCoordinateModes["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    zeroNegativeModes["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    zeroNegativeModes["FrobeniusModes"][[All, "PhysicalToLocalMode"]] ===
      zeroNegativeModes["FrobeniusModes"][[All, "CanonicalMode"]]];

jordanFrobenius = ComputeTruncatedLocalFrobeniusExpansion[
  eps {{0, 1}, {0, 0}}/u, endpointSpec,
  "MaximumSeriesOrder" -> 1, "MaximumEpsilonOrder" -> 1];
jordanMode = MatchBoundaryAsymptoticsToFrobeniusModes[jordanFrobenius, IdentityMatrix[2],
  modeSpec, {<|"BoundaryConstantID" -> "log",
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0, "CanonicalRows" -> {2},
    "ConstraintRows" -> {1, 2}, "PhysicalRows" -> {2},
    "EpsilonExponent" -> 0, "IntegerValuation" -> 0,
    "LogLevel" -> 1, "DemandedOutputs" -> {{0, 2}}|>}];
FTAssert["a genuine generalized residue mode is found at its minimal log level",
  jordanMode["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    jordanMode["FrobeniusModes"][[1, "GeneralizedLevel"]] === 1 &&
    jordanMode["FrobeniusModes"][[1, "CanonicalMode"]] === {0, 1}];

powerFrobenius = ComputeTruncatedLocalFrobeniusExpansion[
  eps {{0, 0}, {0, 1}}/u, endpointSpec,
  "MaximumSeriesOrder" -> 1, "MaximumEpsilonOrder" -> 1];
powerMode = MatchBoundaryAsymptoticsToFrobeniusModes[powerFrobenius, IdentityMatrix[2],
  modeSpec, {<|"BoundaryConstantID" -> "power",
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0, "CanonicalRows" -> {2},
    "PhysicalRows" -> {2}, "EpsilonExponent" -> 1,
    "IntegerValuation" -> 0, "LogLevel" -> 0,
    "DemandedOutputs" -> {{0, 2}}|>}];
FTAssert["nonzero and generalized residue modes require their tangential logarithmic factors before transport",
  ConstructBoundaryValueVectorFromConstants[jordanMode, <||>, {0, 0},
      "MissingBoundaryDataAction" -> "Formal"]["Status"] ===
        "TangentialLogModeRequired" &&
    ConstructBoundaryValueVectorFromConstants[powerMode, <||>, {0, 0},
      "MissingBoundaryDataAction" -> "Formal"]["Status"] ===
        "TangentialLogModeRequired" &&
    ConstructBoundaryValueVectorFromConstants[jordanMode, <||>, {0, 0},
      "MissingBoundaryDataAction" -> "Formal"]["BoundaryDataRequirements"][[1,
        "Problem"]] === "TangentialLogModeRequired"];

boundaryConstants = <|
  "g" -> <|"DeclaredBoundaryConstantAnalyticClass" -> "GPL", "Status" -> "Exact",
    "Valuation" -> 0, "Coefficients" -> <|0 -> 2, 1 -> 3|>|>,
  "e" -> <|"DeclaredBoundaryConstantAnalyticClass" -> "Elliptic", "Status" -> "Exact",
    "Valuation" -> 0,
    "Coefficients" -> <|0 -> elliptic0, 1 -> elliptic1|>|>|>;
boundarySelectors = ConstructBoundarySelectorMatrices[modeMap,
  boundaryConstants, {0, 1}];
boundary = ConstructBoundaryValueVectorFromConstants[modeMap,
  boundaryConstants, {0, 1}];
FTAssert["mixed GPL and elliptic data yield rational transport selectors and a separate exact constant vector",
  boundary["Status"] === "BoundaryConstantValueVectorConstructed" &&
    boundary["FunctionSpace"] === "GPL+Elliptic" &&
    boundary["BoundaryConstantVector"] ===
      {2, 3, elliptic0, elliptic1} &&
    boundarySelectors["BoundarySelectorMatricesByEpsilonOrder"][0] ===
      {{1, 0, 0, 0}, {0, 0, 1/2, 0}} &&
    boundarySelectors["BoundarySelectorMatricesByEpsilonOrder"][1] ===
      {{0, 1, 0, 0}, {0, 0, 0, 1/2}} &&
    boundary["BoundaryValueVectorByEpsilonOrder"][0] === {2, elliptic0/2} &&
    boundary["BoundaryValueVectorByEpsilonOrder"][1] === {3, elliptic1/2}];

FTAssert["the boundary-data requirements bind family, physical limit, Frobenius mode, affected epsilon coefficients and requested master-integral coefficients",
  Lookup[boundary["BoundaryDataRequirements"], "Status"] ===
      {"KnownExact", "KnownExact"} &&
    AllTrue[boundary["BoundaryDataRequirements"],
      #Family === "SyntheticBoundaryControl" &&
        AssociationQ[#PhysicalKinematicLimit] && AssociationQ[#FrobeniusMode] &&
        ListQ[#BoundaryConstantEpsilonCoefficientLabels] &&
        ListQ[#RequiredMasterIntegralCoefficients] &]];

source = Join[<|"Letters" -> {{"GPLPole", -1}},
    "Residues" -> {{{0, 0}, {0, 0}}}, "Dimension" -> 2|>,
  <|"BoundarySelectors" ->
    boundarySelectors["BoundarySelectorMatricesByEpsilonOrder"]|>];
layer = <|"Rows" -> {3}, "PathVariable" -> u,
  "Regulator" -> eps, "BasePoint" -> 0, "PathEndpoint" -> 1/2,
  "Diagonal" -> {{{"GPLPole", -1}, {{0}}}},
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> eps,
      "Letter" -> {"GPLPole", -1}|>,
    <|"Row" -> 1, "Column" -> 2, "Coefficient" -> eps,
      "Letter" -> {"GPLPole", -1}|>}
|>;
consumed = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer,
  <|"RequestedOutputPairs" -> {{1, 1}}|>];
FTAssert["the boundary selector matrices are consumed directly by the rational-epsilon-dependent-block solution",
  consumed["Status"] ===
    "RationalEpsilonDependentBlockSolutionAccepted" &&
    consumed["BoundaryColumns"] === 5];

gplOnly = ConstructBoundaryValueVectorFromConstants[modeMap,
  Join[boundaryConstants, <|"e" -> <|"DeclaredBoundaryConstantAnalyticClass" -> "Elliptic",
    "Status" -> "ExactZero"|>|>], {0, 1}];
FTAssert["known-zero elliptic modes leave a GPL-only boundary and are explicit in the ledger",
  gplOnly["Status"] === "BoundaryConstantValueVectorConstructed" &&
    gplOnly["FunctionSpace"] === "GPL" &&
    Lookup[gplOnly["BoundaryDataRequirements"], "Status"] ===
      {"KnownExact", "KnownZero"}];

missingElliptic = ConstructBoundaryValueVectorFromConstants[modeMap,
  KeyDrop[boundaryConstants, "e"], {0, 1}];
FTAssert["an absent elliptic boundary constant is typed incomplete and retained in the requirements",
  missingElliptic["Status"] ===
      "EllipticBoundaryConstantsIncomplete" &&
    Lookup[missingElliptic["BoundaryDataRequirements"], "Status"] ===
      {"KnownExact", "Unevaluated"} &&
    missingElliptic["BoundaryDataRequirements"][[2,
      "BoundaryConstantEpsilonCoefficientLabels"]] === {{"e", 0}, {"e", 1}}];

transferable = ConstructBoundaryValueVectorFromConstants[modeMap,
  Join[boundaryConstants, <|"e" -> <|"DeclaredBoundaryConstantAnalyticClass" -> "Elliptic",
    "Status" -> "Transferable", "TransferFrom" -> "other-limit"|>|>],
  {0, 1}];
FTAssert["a transferable but unapplied boundary constant remains incomplete rather than masquerading as a value",
  transferable["Status"] === "EllipticBoundaryConstantsIncomplete" &&
    transferable["BoundaryDataRequirements"][[2, "Status"]] ===
      "Transferable" &&
    transferable["BoundaryDataRequirements"][[2, "TransferFrom"]] ===
      "other-limit"];

FTAssert["missing GPL data and missing data of both classes have distinct typed statuses",
  ConstructBoundaryValueVectorFromConstants[modeMap, KeyDrop[boundaryConstants, "g"],
      {0, 1}]["Status"] === "GPLBoundaryConstantsIncomplete" &&
    ConstructBoundaryValueVectorFromConstants[modeMap, <||>,
      {0, 1}]["Status"] === "BoundaryDataIncomplete"];

FTAssert["a requested epsilon depth beyond the stored Frobenius prefactor is refused typed",
  ConstructBoundaryValueVectorFromConstants[modeMap, boundaryConstants,
    {0, 3}]["Status"] === "FrobeniusDepthInsufficient"];

prunedRealizations = realizations;
prunedRealizations[[1, "DemandedOutputs"]] = {{0, 1}};
prunedRealizations[[2, "DemandedOutputs"]] = {{1, 2}};
prunedModeMap = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
  {{1, 0}, {u, 2}}, modeSpec, prunedRealizations];
formalBoundarySelectors = ConstructBoundarySelectorMatrices[prunedModeMap, <||>,
  {0, 1}, "MissingBoundaryDataAction" -> "Formal"];
formalBoundary = ConstructBoundaryValueVectorFromConstants[prunedModeMap, <||>,
  {0, 1}, "MissingBoundaryDataAction" -> "Formal"];
FTAssert["formal GPL and elliptic boundary constants produce rational selector matrices and remain explicitly unevaluated",
  formalBoundary["Status"] ===
      "FormalBoundaryConstantValueVectorConstructed" &&
    formalBoundary["BoundaryDataStatus"] === "FormalNotEvaluated" &&
    Context[BoundaryConstantEpsilonCoefficient] === "FeynFacet`" &&
    formalBoundary["BoundaryConstantVector"] === {
      BoundaryConstantEpsilonCoefficient["g", 0],
      BoundaryConstantEpsilonCoefficient["e", 0],
      BoundaryConstantEpsilonCoefficient["e", 1]} &&
    formalBoundarySelectors["BoundarySelectorMatricesByEpsilonOrder"][0] ===
      {{1, 0, 0}, {0, 1/2, 0}} &&
    formalBoundarySelectors["BoundarySelectorMatricesByEpsilonOrder"][1] ===
      {{0, 0, 0}, {0, 0, 1/2}} &&
    Lookup[formalBoundary["BoundaryDataRequirements"], "Status"] ===
      {"Unevaluated", "Unevaluated"}];

FTAssert["demand pruning removes an unused boundary-constant epsilon coefficient from both the records and requirements",
  FreeQ[formalBoundary["BoundaryConstantEpsilonCoefficientRecords"],
    <|"BoundaryConstantID" -> "g", "EpsilonOrder" -> 1|>] &&
    FreeQ[formalBoundary["BoundaryDataRequirements"], {"g", 1}] &&
    formalBoundary["BoundaryDataRequirements"][[1,
      "BoundaryConstantEpsilonCoefficientLabels"]] === {{"g", 0}}];

formalSource = Join[<|"Letters" -> {{"GPLPole", -1}},
    "Residues" -> {{{0, 0}, {0, 0}}}, "Dimension" -> 2|>,
  <|"BoundarySelectors" ->
    formalBoundarySelectors["BoundarySelectorMatricesByEpsilonOrder"]|>];
formalConsumed = SolveRationalEpsilonDependentBlockByVariationOfConstants[formalSource, layer,
  <|"RequestedOutputPairs" -> {{1, 1}}|>];
FTAssert["the block solution proceeds unchanged with formal GPL and elliptic boundary constants",
  formalConsumed["Status"] ===
      "RationalEpsilonDependentBlockSolutionAccepted" &&
    formalConsumed["BoundaryColumns"] === 4];

transferredBoundary = ConstructBoundaryValueVectorFromConstants[prunedModeMap, <|
    "g" -> <|"DeclaredBoundaryConstantAnalyticClass" -> "GPL", "Status" -> "ExactZero"|>,
    "e" -> <|"DeclaredBoundaryConstantAnalyticClass" -> "Elliptic",
      "Status" -> "Transferable", "TransferFrom" -> "source-period",
      "TransferMap" -> <|0 -> 0,
        1 -> BoundaryConstantEpsilonCoefficient["source-constant", 2]|>|>|>,
  {0, 1}, "MissingBoundaryDataAction" -> "Formal"];
FTAssert["known zeros and transfer maps are substituted and zero transfer coordinates are pruned",
  transferredBoundary["Status"] ===
      "FormalBoundaryConstantValueVectorConstructed" &&
    transferredBoundary["BoundaryConstantVector"] ===
      {BoundaryConstantEpsilonCoefficient["source-constant", 2]} &&
    Lookup[transferredBoundary["BoundaryDataRequirements"], "Status"] ===
      {"KnownZero", "Transferable"} &&
    transferredBoundary["BoundaryDataRequirements"][[2,
      "BoundaryConstantEpsilonCoefficientLabels"]] === {{"e", 1}}];

exactTransferBoundary = ConstructBoundaryValueVectorFromConstants[prunedModeMap, <|
    "g" -> <|"DeclaredBoundaryConstantAnalyticClass" -> "GPL", "Status" -> "ExactZero"|>,
    "e" -> <|"DeclaredBoundaryConstantAnalyticClass" -> "Elliptic",
      "Status" -> "Transferable", "TransferFrom" -> "known-period",
      "TransferMap" -> <|0 -> 5, 1 -> 7|>|>|>, {0, 1}];
FTAssert["a complete exact transfer needs no formal placeholder and is marked exact-with-transfers",
  exactTransferBoundary["Status"] ===
      "BoundaryConstantValueVectorConstructed" &&
    exactTransferBoundary["BoundaryDataStatus"] ===
      "ExactWithTransfers" &&
    exactTransferBoundary["BoundaryConstantVector"] === {5, 7} &&
    exactTransferBoundary["BoundaryDataRequirements"][[2, "Status"]] ===
      "Transferable"];

FTAssert["class mismatches, approximate constants and truncated Laurent data are never accepted",
  ConstructBoundaryValueVectorFromConstants[modeMap,
      MapAt[Join[#, <|"DeclaredBoundaryConstantAnalyticClass" -> "GPL"|>] &, boundaryConstants,
        Key["e"]], {0, 1}]["Status"] ===
      "BoundaryDataInvalid" &&
    ConstructBoundaryValueVectorFromConstants[modeMap,
      MapAt[Join[#, <|"Coefficients" -> <|0 -> 2., 1 -> 3|>|>] &,
        boundaryConstants, Key["g"]], {0, 1}]["Status"] ===
      "BoundaryDataInvalid" &&
    ConstructBoundaryValueVectorFromConstants[modeMap,
      MapAt[Join[#, <|"Coefficients" -> <|0 -> elliptic0|>|>] &,
        boundaryConstants, Key["e"]], {0, 1}]["Status"] ===
      "EllipticBoundaryConstantsIncomplete"];

(* Round 9: a repeated block eigenvalue.  The 2x2 zero residue has a 2-d
   eigenspace at eigenvalue 0; the physical-row transformation decides what
   the integral's valuation can separate. *)
degenerateRealization[id_, valuation_, extra_: <||>] := Join[<|
  "BoundaryConstantID" -> id,
  "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
  "BoundaryConstantEpsilonValuation" -> 0, "CanonicalRows" -> {1, 2},
  "PhysicalRows" -> {1, 2}, "EpsilonExponent" -> 0,
  "IntegerValuation" -> valuation, "LogLevel" -> 0,
  "DemandedOutputs" -> {{0, 1}}|>, extra];
(* expected order 1: e1 maps to (rho, 0), e2 to (1 + ..., 1); only e1 cancels
   the rho^0 power *)
selectedByValuation = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius, {{u, 1}, {0, 1}},
  modeSpec, {degenerateRealization["sel", 1]}];
FTAssert["a repeated block eigenvalue is resolved when the integral's valuation cancels the lower powers of all but one direction",
  selectedByValuation["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    selectedByValuation["FrobeniusModes"][[1, "CanonicalMode"]] === {1, 0} &&
    selectedByValuation["FrobeniusModes"][[1, "PhysicalLocalOrders"]] === {1, Infinity} &&
    selectedByValuation["FrobeniusModes"][[1, "PhysicalLeadingCoefficients"]][[1]] === 1 &&
    selectedByValuation["DegenerateResidueEigenspaceBases"] === {}];
(* expected order 1 but every direction starts at rho^0: typed, not ambiguous *)
noDirection = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius, {{1, 1}, {0, 1}},
  modeSpec, {degenerateRealization["none", 1]}];
FTAssert["a repeated eigenvalue with no direction compatible with the valuation is refused typed",
  noDirection["Status"] ===
      "BoundaryAsymptoticsNotFullyMatchedToFrobeniusModes" &&
    noDirection["FrobeniusModes"][[1, "Status"]] === "PhysicalValuationMismatch" &&
    noDirection["FrobeniusModes"][[1, "PhysicalAdmissibleNullity"]] === 0 &&
    noDirection["FrobeniusModes"][[1, "BlockNullity"]] === 2 &&
    noDirection["BoundaryDataRequirements"][[1, "Problem"]] === "PhysicalValuationMismatch"];
(* expected order 0 and both directions at order 0: genuinely two
   coefficients; refused by default, realized as the canonical eigenspace
   basis under the explicit policy *)
genuinelyDegenerate = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius, IdentityMatrix[2],
  modeSpec, {degenerateRealization["deg", 0]}];
degenerateBasis = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius, IdentityMatrix[2],
  modeSpec, {degenerateRealization["deg", 0,
    <|"DegenerateResidueEigenspacePolicy" -> "Basis"|>]}];
FTAssert["a genuinely multi-dimensional admissible eigenspace is refused by default and realized as exact echelon sub-realizations only under the explicit Basis policy",
  genuinelyDegenerate["Status"] ===
      "BoundaryAsymptoticsNotFullyMatchedToFrobeniusModes" &&
    genuinelyDegenerate["FrobeniusModes"][[1, "Status"]] === "AmbiguousPhysicalEigenspace" &&
    genuinelyDegenerate["FrobeniusModes"][[1, "PhysicalAdmissibleNullity"]] === 2 &&
    Length[genuinelyDegenerate["FrobeniusModes"][[1, "AdmissibleBasis"]]] === 2 &&
    degenerateBasis["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    Length[degenerateBasis["FrobeniusModes"]] === 2 &&
    degenerateBasis["FrobeniusModes"][[All, "BoundaryConstantID"]] === {{"deg", 1}, {"deg", 2}} &&
    degenerateBasis["FrobeniusModes"][[All, "CanonicalMode"]] === {{1, 0}, {0, 1}} &&
    degenerateBasis["FrobeniusModes"][[All, "Status"]] ===
      {"BoundaryAsymptoticsMatchedToFrobeniusMode", "BoundaryAsymptoticsMatchedToFrobeniusMode"} &&
    degenerateBasis["FrobeniusModes"][[All, "EigenspaceDimension"]] === {2, 2} &&
    Length[degenerateBasis["DegenerateResidueEigenspaceBases"]] === 2 &&
    degenerateBasis["BoundaryDataRequirements"][[All, "BoundaryConstantID"]] ===
      {{"deg", 1}, {"deg", 2}} &&
    KeyTake[degenerateBasis["BoundaryDataRequirements"][[2,
        "DegenerateResidueEigenspaceBasis"]],
        {"ParentBoundaryConstantID", "EigenspaceDirection", "EigenspaceDimension",
          "IndependentBoundaryDataCount", "BoundaryRelations"}] ===
      <|"ParentBoundaryConstantID" -> "deg", "EigenspaceDirection" -> 2,
        "EigenspaceDimension" -> 2, "IndependentBoundaryDataCount" -> 2,
        "BoundaryRelations" -> {}|> &&
    ConstructBoundaryValueVectorFromConstants[degenerateBasis, <||>, {0, 0},
      "MissingBoundaryDataAction" -> "Formal"]["Status"] =!=
        "BoundaryConstantValueVectorInputsInvalid"];

(* Round 9b: R3's F4 -- an invalid policy value is refused typed, never
   read as "no policy" *)
invalidPolicies = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius, IdentityMatrix[2], modeSpec,
    {degenerateRealization["deg", 0, <|"DegenerateResidueEigenspacePolicy" -> #|>]}] & /@
  {"basis", "Bases", True};
FTAssert["an invalid DegenerateResidueEigenspacePolicy value is refused typed with the value named",
  AllTrue[invalidPolicies, #["Status"] ===
      "BoundaryAsymptoticsNotFullyMatchedToFrobeniusModes" &&
    #["FrobeniusModes"][[1, "Status"]] === "DegenerateResidueEigenspacePolicyInvalid" &] &&
    invalidPolicies[[All, "FrobeniusModes", 1, "Policy"]] === {"basis", "Bases", True} &&
    invalidPolicies[[1, "BoundaryDataRequirements", 1, "Problem"]] === "DegenerateResidueEigenspacePolicyInvalid"];
(* The split is declared on the mode records, every requirement, and every
   boundary-constant coefficient record. *)
degenerateVector = ConstructBoundaryValueVectorFromConstants[degenerateBasis, <||>, {0, 0},
  "MissingBoundaryDataAction" -> "Formal"];
expectedBasis[k_] := <|"BoundaryDataType" -> "BoundaryConstant",
  "ParentBoundaryConstantID" -> "deg", "EigenspaceDimension" -> 2,
  "CanonicalRows" -> {1, 2}, "FrobeniusModeIDs" -> {{"deg", 1}, {"deg", 2}},
  "EigenspaceBasis" -> {{1, 0}, {0, 1}}, "IndependentBoundaryDataCount" -> 2,
  "BoundaryRelations" -> {},
  "Meaning" -> DegenerateResidueEigenspaceBasis[
    degenerateBasis["FrobeniusModes"][[1]], degenerateBasis["FrobeniusModes"]]["Meaning"],
  "BoundaryConstantID" -> {"deg", k}, "EigenspaceDirection" -> k|>;
FTAssert["a degenerate residue eigenspace records independent basis directions and does not invent a relation among their boundary constants",
  degenerateBasis["FrobeniusModes"][[All, "EigenspaceBasis"]] ===
      {{{1, 0}, {0, 1}}, {{1, 0}, {0, 1}}} &&
    degenerateBasis["BoundaryDataRequirements"][[All,
      "DegenerateResidueEigenspaceBasis"]] === {expectedBasis[1], expectedBasis[2]} &&
    degenerateVector["Status"] === "FormalBoundaryConstantValueVectorConstructed" &&
    Length[degenerateVector["BoundaryConstantEpsilonCoefficientRecords"]] === 2 &&
    degenerateVector["BoundaryConstantEpsilonCoefficientRecords"][[All,
      "DegenerateResidueEigenspaceBasis"]] === {expectedBasis[1], expectedBasis[2]} &&
    degenerateVector["BoundaryDataRequirements"][[All,
      "DegenerateResidueEigenspaceBasis"]] === {expectedBasis[1], expectedBasis[2]} &&
    DegenerateResidueEigenspaceBasis[modeMap["FrobeniusModes"][[1]],
      modeMap["FrobeniusModes"]] === None];

missingDomain = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
  {{1, 0}, {u, 2}}, KeyDrop[modeSpec, "BoundaryDomain"], realizations];
FTAssert["mode matching refuses to guess whether unspecified boundary data are constants or functions",
  missingDomain["Status"] === "BoundaryDomainRequired"];

tangentialVariable = Symbol["Global`boundaryTangentialVariable"];
functionSpec = Join[modeSpec, <|
  "Family" -> "SyntheticBoundaryFunctionControl",
  "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryStratum",
    "TangentialVariables" -> {tangentialVariable}|>|>];
functionRealization = <|
  "BoundaryFunctionID" -> "f",
  "DeclaredBoundaryFunctionClass" -> "GPL",
  "BoundaryFunctionEpsilonValuation" -> 0,
  "CanonicalRows" -> {1}, "PhysicalRows" -> {1},
  "EpsilonExponent" -> 0, "IntegerValuation" -> 0,
  "LogLevel" -> 0, "DemandedOutputs" -> {{0, 1}}|>;
functionMatching = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,
  {{1, 0}, {u, 2}}, functionSpec, {functionRealization}];
functionSelectors = ConstructBoundarySelectorMatrices[functionMatching,
  <||>, {0, 0}, "MissingBoundaryDataAction" -> "Formal"];
functionValues = ConstructBoundaryValueVectorFromFunctions[functionMatching,
  <||>, {0, 0}, "MissingBoundaryDataAction" -> "Formal"];
FTAssert["a positive-dimensional physical boundary stratum emits a boundary function, never a boundary constant",
  functionMatching["DataType"] === "BoundaryAsymptoticModeMatching" &&
    functionMatching["SchemaVersion"] === 2 &&
    functionMatching["Status"] ===
      "BoundaryAsymptoticsMatchedToFrobeniusModes" &&
    functionMatching["BoundaryDataType"] === "BoundaryFunction" &&
    functionMatching["FrobeniusModes"][[1, "BoundaryFunctionID"]] === "f" &&
    functionValues["Status"] === "FormalBoundaryFunctionValueVectorConstructed" &&
    functionValues["BoundaryFunctionVector"] ===
      {BoundaryFunctionEpsilonCoefficient["f", 0][tangentialVariable]} &&
    ! FreeQ[D[First[functionValues["BoundaryFunctionVector"]],
        tangentialVariable], Derivative[1][
          BoundaryFunctionEpsilonCoefficient["f", 0]][
            tangentialVariable]] &&
    functionValues["BoundaryFunctionEpsilonCoefficientLabels"] === {{"f", 0}} &&
    functionSelectors["BoundarySelectorMatricesByEpsilonOrder"][0] === {{1}, {0}} &&
    ConstructBoundaryValueVectorFromConstants[functionMatching, <||>, {0, 0},
      "MissingBoundaryDataAction" -> "Formal"]["Status"] ===
        "PhysicalBoundaryPointRequired"];

FTAssert["the former ambiguous boundary-vector and period-placeholder heads are absent",
  ! NameQ["FeynFacet`BuildTransportBoundaryVector"] &&
    ! NameQ["FeynFacet`BoundaryPeriodCoefficient"] &&
    ! NameQ["FeynFacet`BuildBoundaryModeMap"] &&
    ! NameQ["FeynFacet`BoundaryDegenerateEigenspaceDeclaration"]];

FTAssert["the production boundary module contains no family-specific token",
  With[{text = Import[FileNameJoin[{root, "FeynFacet", "Private",
      "Transport", "Boundary", "PhysicalBoundary.wl"}], "Text"]},
    StringFreeQ[text, RegularExpression["CF[0-9]+"]]]];

FTReport[];
