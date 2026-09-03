#!/usr/bin/env wolframscript

(* Singular-boundary production path: local Frobenius recurrence, exact
   physical-mode normalization, and separation of transport selectors from
   GPL/elliptic boundary constants.  Everything is a bounded 2x2 control. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`boundaryU"];
rho = Symbol["Global`boundaryRho"];
eps = Symbol["Global`eps"];
elliptic0 = Inactive[EllipticK][1/2];
elliptic1 = Inactive[EllipticE][1/3];
residue = ConstantArray[0, {2, 2}];
regular = {{0, 1}, {0, 0}};
connection = eps (residue/u + regular);
endpointSpec = <|"Variable" -> u, "Regulator" -> eps,
  "LocalVariable" -> rho, "Endpoint" -> 0|>;

frobenius = BuildEndpointFrobenius[connection, endpointSpec,
  "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 2];
FTAssert["a Fuchsian epsilon-form endpoint builds a finite exact Frobenius prefactor",
  frobenius["Status"] === "EndpointFrobeniusBuilt" &&
    frobenius["Residue"] === residue &&
    frobenius["FrobeniusPrefactorCoefficients"][{1, 1}] === regular &&
    frobenius["ResidualCheckedThrough"] ===
      <|"SeriesOrder" -> 1, "EpsilonOrder" -> 2|>];

reverseFrobenius = BuildEndpointFrobenius[
  eps (residue/(u - 1) + regular),
  Join[endpointSpec, <|"Endpoint" -> 1, "LocalDirection" -> -1|>],
  "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 2];
FTAssert["an inward endpoint coordinate includes its differential Jacobian",
  reverseFrobenius["Status"] === "EndpointFrobeniusBuilt" &&
    reverseFrobenius["LocalDirection"] === -1 &&
    reverseFrobenius["Residue"] === residue &&
    reverseFrobenius["FrobeniusPrefactorCoefficients"][{1, 1}] ===
      -regular];

inwardScalarFrobenius = BuildEndpointFrobenius[{{0}},
  <|"Variable" -> u, "Regulator" -> eps, "LocalVariable" -> rho,
    "Endpoint" -> 1, "LocalDirection" -> -1|>,
  "MaximumSeriesOrder" -> 1, "MaximumEpsilonOrder" -> 1];
inwardScalarMode = BuildBoundaryModeMap[inwardScalarFrobenius,
  {{1 - u}}, <|"Family" -> "InwardCoordinateControl",
    "Limit" -> <|"Variable" -> u, "Endpoint" -> 1|>,
    "PhysicalEndpointRelation" -> <|"LocalPower" -> 1,
      "LeadingCoefficient" -> 1|>|>,
  {<|"PeriodID" -> "inward", "PeriodClass" -> "GPL",
    "PeriodEpsilonValuation" -> 0, "CanonicalRows" -> {1},
    "PhysicalRows" -> {1}, "EpsilonExponent" -> 0,
    "IntegerValuation" -> 1, "LogLevel" -> 0,
    "DemandedOutputs" -> {{0, 1}}|>}];
FTAssert["mode normalization uses the same inward coordinate as its Frobenius series",
  inwardScalarMode["Status"] === "BoundaryModeMapBuilt" &&
    inwardScalarMode["EndpointSpec", "LocalDirection"] === -1 &&
    inwardScalarMode["Modes"][[1, "CanonicalMode"]] === {1} &&
    inwardScalarMode["Modes"][[1, "PhysicalLeadingCoefficients"]] === {1}];

FTAssert["non-epsilon-form and higher-order endpoint poles are refused typed",
  BuildEndpointFrobenius[connection + IdentityMatrix[2],
      endpointSpec]["Status"] === "ConnectionNotEpsilonForm" &&
    BuildEndpointFrobenius[eps IdentityMatrix[2]/u^2,
      endpointSpec]["Status"] === "EndpointNotFuchsian"];

leveltP = Symbol["Global`leveltP"];
leveltFrame = {{1, 0}, {1/leveltP, 1}};
leveltExponents = {0, -2 - 4 eps};
leveltExpected = {{eps/leveltP, 0}, {0, 2 eps/(1 - leveltP)}};
leveltResidue = Together[
  leveltFrame.DiagonalMatrix[leveltExponents].Inverse[leveltFrame]];
leveltTangential = Together[
  leveltFrame.leveltExpected.Inverse[leveltFrame] +
    D[leveltFrame, leveltP].Inverse[leveltFrame]];
levelt = BuildEndpointLeveltModeConnection[leveltResidue,
  leveltTangential, <|"TangentialVariable" -> leveltP,
    "Regulator" -> eps, "ModeFrame" -> leveltFrame,
    "LocalExponents" -> leveltExponents|>];
FTAssert["a rational-in-epsilon regular-singular endpoint is reduced in a moving Levelt frame",
  levelt["Status"] === "EndpointLeveltModeConnectionBuilt" &&
    And @@ Flatten[MapThread[Together[#1 - #2] === 0 &,
      {levelt["TangentialConnection"], leveltExpected}, 2]] &&
    Lookup[levelt["ExponentData"], "IntegerPart"] === {0, -2} &&
    Lookup[levelt["ExponentData"], "RegulatorCoefficient"] === {0, -4} &&
    Lookup[levelt["ExponentSectors"], "Indices"] === {{1}, {2}}];

FTAssert["an invalid frame and unequal-exponent tangential mixing are refused typed",
  BuildEndpointLeveltModeConnection[leveltResidue,
      leveltTangential, <|"TangentialVariable" -> leveltP,
        "Regulator" -> eps, "ModeFrame" -> IdentityMatrix[2],
        "LocalExponents" -> leveltExponents|>]["Status"] ===
      "EndpointLeveltModeFrameInvalid" &&
    BuildEndpointLeveltModeConnection[leveltResidue,
      leveltTangential + leveltFrame.{{0, 1}, {0, 0}}.
        Inverse[leveltFrame], <|"TangentialVariable" -> leveltP,
        "Regulator" -> eps, "ModeFrame" -> leveltFrame,
        "LocalExponents" -> leveltExponents|>]["Status"] ===
      "EndpointLeveltSectorsCoupled"];

modeSpec = <|
  "Family" -> "SyntheticBoundaryControl",
  "Limit" -> <|"Variable" -> u, "Endpoint" -> 0,
    "Direction" -> "Positive"|>,
  "PhysicalEndpointRelation" -> <|
    "LocalPower" -> 1, "LeadingCoefficient" -> 1|>|>;
realizations = {
  <|"PeriodID" -> "g", "PeriodClass" -> "GPL",
    "PeriodEpsilonValuation" -> 0, "CanonicalRows" -> {1},
    "PhysicalRows" -> {1}, "EpsilonExponent" -> 0,
    "IntegerValuation" -> 0, "LogLevel" -> 0,
    "DemandedOutputs" -> {{0, 1}, {1, 1}, {3, 1}}|>,
  <|"PeriodID" -> "e", "PeriodClass" -> "Elliptic",
    "PeriodEpsilonValuation" -> 0, "CanonicalRows" -> {2},
    "PhysicalRows" -> {2}, "EpsilonExponent" -> 0,
    "IntegerValuation" -> 0, "LogLevel" -> 0,
    "DemandedOutputs" -> {{0, 2}, {1, 2}}|>
};
modeMap = BuildBoundaryModeMap[frobenius, {{1, 0}, {u, 2}},
  modeSpec, realizations];
FTAssert["physical modes are globally extended and normalized in the canonical boundary space",
    modeMap["Status"] === "BoundaryModeMapBuilt" &&
    modeMap["EndpointSpec"] === <|"Variable" -> u,
      "Endpoint" -> 0, "LocalDirection" -> 1, "FixedRules" -> {}|> &&
    modeMap["Modes"][[1, "CanonicalMode"]] === {1, 0} &&
    modeMap["Modes"][[2, "CanonicalMode"]] === {0, 1/2} &&
    modeMap["Modes"][[All, "PhysicalToLocalMode"]] ===
      modeMap["Modes"][[All, "CanonicalMode"]] &&
    modeMap["Modes"][[All, "PhysicalLocalOrders"]] === {{0}, {0}} &&
    Lookup[modeMap["Stage3NeedsLedger"], "Status"] ===
      {"Unevaluated", "Unevaluated"}];

coordinateResidue = {{2, 1}, {0, 2}};
coordinateFrobenius = BuildEndpointFrobenius[
  eps coordinateResidue/u, endpointSpec,
  "MaximumSeriesOrder" -> 1, "MaximumEpsilonOrder" -> 2];
coordinateSpec = <|
  "Family" -> "SyntheticCoordinateControl",
  "Limit" -> <|"Variable" -> u, "Endpoint" -> 0,
    "Direction" -> "Positive"|>,
  "PhysicalEndpointRelation" -> <|
    "LocalPower" -> 2, "LeadingCoefficient" -> 4|>|>;
coordinateRealizations = {
  <|"PeriodID" -> "eigen", "PeriodClass" -> "GPL",
    "PeriodEpsilonValuation" -> 0, "CanonicalRows" -> {1},
    "ConstraintRows" -> {1, 2}, "PhysicalRows" -> {1},
    "EpsilonExponent" -> 1, "IntegerValuation" -> 0,
    "LogLevel" -> 0, "DemandedOutputs" -> {{0, 1}}|>,
  <|"PeriodID" -> "jordan", "PeriodClass" -> "GPL",
    "PeriodEpsilonValuation" -> 0, "CanonicalRows" -> {2},
    "ConstraintRows" -> {1, 2}, "PhysicalRows" -> {2},
    "EpsilonExponent" -> 1, "IntegerValuation" -> 0,
    "LogLevel" -> 1, "DemandedOutputs" -> {{0, 2}}|>
};
coordinateModes = BuildBoundaryModeMap[coordinateFrobenius,
  IdentityMatrix[2], coordinateSpec, coordinateRealizations];
coordinateLog = Log[4];
expectedCoordinateModes = {
  {1 + eps coordinateLog + eps^2 coordinateLog^2/2, 0},
  {eps coordinateLog/2 + eps^2 coordinateLog^2/2,
   1 + eps coordinateLog + eps^2 coordinateLog^2/2}};
FTAssert["t = alpha rho^kappa converts eigenvectors and Jordan modes through the retained epsilon order",
  coordinateModes["Status"] === "BoundaryModeMapBuilt" &&
    coordinateModes["Modes"][[All, "CanonicalMode"]] ===
      {{1, 0}, {0, 1}} &&
    And @@ Flatten[MapThread[Together[#1 - #2] === 0 &,
      {coordinateModes["Modes"][[All, "PhysicalToLocalMode"]],
       expectedCoordinateModes}, 2]]];

negativeCoordinateSpec = MapAt[
  Join[#, <|"LeadingCoefficient" -> -4|>] &,
  coordinateSpec, Key["PhysicalEndpointRelation"]];
negativeCoordinateModes = BuildBoundaryModeMap[coordinateFrobenius,
  IdentityMatrix[2], negativeCoordinateSpec, coordinateRealizations];
branchedCoordinateModes = BuildBoundaryModeMap[coordinateFrobenius,
  IdentityMatrix[2], MapAt[Join[#, <|"LeadingCoefficient" -> -4,
      "LogBranch" -> -1|>] &, coordinateSpec,
    Key["PhysicalEndpointRelation"]], coordinateRealizations];
zeroNegativeModes = BuildBoundaryModeMap[frobenius,
  {{1, 0}, {u, 2}}, MapAt[
    Join[#, <|"LeadingCoefficient" -> -4|>] &, modeSpec,
    Key["PhysicalEndpointRelation"]], realizations];
FTAssert["a non-positive coordinate factor needs an explicit logarithm branch only when the residue acts nontrivially",
  negativeCoordinateModes["Status"] === "BoundaryModeMapIncomplete" &&
    Lookup[negativeCoordinateModes["Modes"], "Status"] ===
      {"PhysicalEndpointLogBranchRequired",
       "PhysicalEndpointLogBranchRequired"} &&
    branchedCoordinateModes["Status"] === "BoundaryModeMapBuilt" &&
    zeroNegativeModes["Status"] === "BoundaryModeMapBuilt" &&
    zeroNegativeModes["Modes"][[All, "PhysicalToLocalMode"]] ===
      zeroNegativeModes["Modes"][[All, "CanonicalMode"]]];

jordanFrobenius = BuildEndpointFrobenius[
  eps {{0, 1}, {0, 0}}/u, endpointSpec,
  "MaximumSeriesOrder" -> 1, "MaximumEpsilonOrder" -> 1];
jordanMode = BuildBoundaryModeMap[jordanFrobenius, IdentityMatrix[2],
  modeSpec, {<|"PeriodID" -> "log", "PeriodClass" -> "GPL",
    "PeriodEpsilonValuation" -> 0, "CanonicalRows" -> {2},
    "ConstraintRows" -> {1, 2}, "PhysicalRows" -> {2},
    "EpsilonExponent" -> 0, "IntegerValuation" -> 0,
    "LogLevel" -> 1, "DemandedOutputs" -> {{0, 2}}|>}];
FTAssert["a genuine generalized residue mode is found at its minimal log level",
  jordanMode["Status"] === "BoundaryModeMapBuilt" &&
    jordanMode["Modes"][[1, "GeneralizedLevel"]] === 1 &&
    jordanMode["Modes"][[1, "CanonicalMode"]] === {0, 1}];

powerFrobenius = BuildEndpointFrobenius[
  eps {{0, 0}, {0, 1}}/u, endpointSpec,
  "MaximumSeriesOrder" -> 1, "MaximumEpsilonOrder" -> 1];
powerMode = BuildBoundaryModeMap[powerFrobenius, IdentityMatrix[2],
  modeSpec, {<|"PeriodID" -> "power", "PeriodClass" -> "GPL",
    "PeriodEpsilonValuation" -> 0, "CanonicalRows" -> {2},
    "PhysicalRows" -> {2}, "EpsilonExponent" -> 1,
    "IntegerValuation" -> 0, "LogLevel" -> 0,
    "DemandedOutputs" -> {{0, 2}}|>}];
FTAssert["nonzero and generalized residue modes require their tangential logarithmic factors before transport",
  BuildTransportBoundaryVector[jordanMode, <||>, {0, 0},
      "MissingPeriodAction" -> "Formal"]["Status"] ===
        "TangentialLogModeRequired" &&
    BuildTransportBoundaryVector[powerMode, <||>, {0, 0},
      "MissingPeriodAction" -> "Formal"]["Status"] ===
        "TangentialLogModeRequired" &&
    BuildTransportBoundaryVector[jordanMode, <||>, {0, 0},
      "MissingPeriodAction" -> "Formal"]["Stage3NeedsLedger"][[1,
        "Problem"]] === "TangentialLogModeRequired"];

periods = <|
  "g" -> <|"PeriodClass" -> "GPL", "Status" -> "Exact",
    "Valuation" -> 0, "Coefficients" -> <|0 -> 2, 1 -> 3|>|>,
  "e" -> <|"PeriodClass" -> "Elliptic", "Status" -> "Exact",
    "Valuation" -> 0,
    "Coefficients" -> <|0 -> elliptic0, 1 -> elliptic1|>|>|>;
boundary = BuildTransportBoundaryVector[modeMap, periods, {0, 1}];
FTAssert["mixed GPL and elliptic data yield rational transport selectors and a separate exact constant vector",
  boundary["Status"] === "TransportBoundaryVectorBuilt" &&
    boundary["FunctionSpace"] === "GPL+Elliptic" &&
    boundary["BoundaryConstantVector"] ===
      {2, 3, elliptic0, elliptic1} &&
    boundary["BoundarySelectors"][0] ===
      {{1, 0, 0, 0}, {0, 0, 1/2, 0}} &&
    boundary["BoundarySelectors"][1] ===
      {{0, 1, 0, 0}, {0, 0, 0, 1/2}} &&
    boundary["BoundaryVector"][0] === {2, elliptic0/2} &&
    boundary["BoundaryVector"][1] === {3, elliptic1/2}];

FTAssert["the explicit stage-3 ledger binds family, limit, Frobenius mode, affected coordinates and outputs",
  Lookup[boundary["Stage3NeedsLedger"], "Status"] ===
      {"KnownExact", "KnownExact"} &&
    AllTrue[boundary["Stage3NeedsLedger"],
      #Family === "SyntheticBoundaryControl" &&
        AssociationQ[#Limit] && AssociationQ[#FrobeniusMode] &&
        ListQ[#AffectedBoundaryCoordinates] &&
        ListQ[#DemandedOutputs] &]];

source = Join[<|"Letters" -> {{"GPLPole", -1}},
    "Residues" -> {{{0, 0}, {0, 0}}}|>,
  boundary["TransportBoundary"]];
layer = <|"Rows" -> {3}, "PathVariable" -> u,
  "Regulator" -> eps, "BasePoint" -> 0, "Endpoint" -> 1/2,
  "Diagonal" -> {{{"GPLPole", -1}, {{0}}}},
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> eps,
      "Letter" -> {"GPLPole", -1}|>,
    <|"Row" -> 1, "Column" -> 2, "Coefficient" -> eps,
      "Letter" -> {"GPLPole", -1}|>}
|>;
consumed = BuildRationalEpsilonLayerTransport[source, layer,
  <|"Pairs" -> {{1, 1}}|>];
FTAssert["the emitted TransportBoundary is consumed directly by the rational layer transport",
  consumed["Status"] === "RationalEpsilonLayerTransportAccepted" &&
    consumed["BoundaryColumns"] === 5];

gplOnly = BuildTransportBoundaryVector[modeMap,
  Join[periods, <|"e" -> <|"PeriodClass" -> "Elliptic",
    "Status" -> "ExactZero"|>|>], {0, 1}];
FTAssert["known-zero elliptic modes leave a GPL-only boundary and are explicit in the ledger",
  gplOnly["Status"] === "TransportBoundaryVectorBuilt" &&
    gplOnly["FunctionSpace"] === "GPL" &&
    Lookup[gplOnly["Stage3NeedsLedger"], "Status"] ===
      {"KnownExact", "KnownZero"}];

missingElliptic = BuildTransportBoundaryVector[modeMap,
  KeyDrop[periods, "e"], {0, 1}];
FTAssert["an absent elliptic period is typed incomplete and retained in the needs ledger",
  missingElliptic["Status"] ===
      "EllipticBoundaryPeriodsIncomplete" &&
    Lookup[missingElliptic["Stage3NeedsLedger"], "Status"] ===
      {"KnownExact", "Unevaluated"} &&
    missingElliptic["Stage3NeedsLedger"][[2,
      "AffectedBoundaryCoordinates"]] === {{"e", 0}, {"e", 1}}];

transferable = BuildTransportBoundaryVector[modeMap,
  Join[periods, <|"e" -> <|"PeriodClass" -> "Elliptic",
    "Status" -> "Transferable", "TransferFrom" -> "other-limit"|>|>],
  {0, 1}];
FTAssert["a transferable but unapplied period remains incomplete rather than masquerading as a value",
  transferable["Status"] === "EllipticBoundaryPeriodsIncomplete" &&
    transferable["Stage3NeedsLedger"][[2, "Status"]] ===
      "Transferable" &&
    transferable["Stage3NeedsLedger"][[2, "TransferFrom"]] ===
      "other-limit"];

FTAssert["missing GPL data and missing data of both classes have distinct typed statuses",
  BuildTransportBoundaryVector[modeMap, KeyDrop[periods, "g"],
      {0, 1}]["Status"] === "GPLBoundaryConstantsIncomplete" &&
    BuildTransportBoundaryVector[modeMap, <||>,
      {0, 1}]["Status"] === "BoundaryDataIncomplete"];

FTAssert["a requested epsilon depth beyond the stored Frobenius prefactor is refused typed",
  BuildTransportBoundaryVector[modeMap, periods,
    {0, 3}]["Status"] === "FrobeniusDepthInsufficient"];

prunedRealizations = realizations;
prunedRealizations[[1, "DemandedOutputs"]] = {{0, 1}};
prunedRealizations[[2, "DemandedOutputs"]] = {{1, 2}};
prunedModeMap = BuildBoundaryModeMap[frobenius,
  {{1, 0}, {u, 2}}, modeSpec, prunedRealizations];
formalBoundary = BuildTransportBoundaryVector[prunedModeMap, <||>,
  {0, 1}, "MissingPeriodAction" -> "Formal"];
FTAssert["formal mixed periods produce a rational selector basis and remain explicitly unevaluated",
  formalBoundary["Status"] ===
      "FormalTransportBoundaryVectorBuilt" &&
    formalBoundary["BoundaryDataStatus"] === "FormalNotEvaluated" &&
    Context[BoundaryPeriodCoefficient] === "FeynFacet`" &&
    formalBoundary["BoundaryConstantVector"] === {
      BoundaryPeriodCoefficient["g", 0],
      BoundaryPeriodCoefficient["e", 0],
      BoundaryPeriodCoefficient["e", 1]} &&
    formalBoundary["BoundarySelectors"][0] ===
      {{1, 0, 0}, {0, 1/2, 0}} &&
    formalBoundary["BoundarySelectors"][1] ===
      {{0, 0, 0}, {0, 0, 1/2}} &&
    Lookup[formalBoundary["Stage3NeedsLedger"], "Status"] ===
      {"Unevaluated", "Unevaluated"}];

FTAssert["demand pruning removes an unused period order from both the coordinate basis and needs ledger",
  FreeQ[formalBoundary["BoundaryCoordinates"],
    <|"PeriodID" -> "g", "EpsilonOrder" -> 1|>] &&
    FreeQ[formalBoundary["Stage3NeedsLedger"], {"g", 1}] &&
    formalBoundary["Stage3NeedsLedger"][[1,
      "AffectedBoundaryCoordinates"]] === {{"g", 0}}];

formalSource = Join[<|"Letters" -> {{"GPLPole", -1}},
    "Residues" -> {{{0, 0}, {0, 0}}}|>,
  formalBoundary["TransportBoundary"]];
formalConsumed = BuildRationalEpsilonLayerTransport[formalSource, layer,
  <|"Pairs" -> {{1, 1}}|>];
FTAssert["transport proceeds unchanged with formal GPL and elliptic boundary constants",
  formalConsumed["Status"] ===
      "RationalEpsilonLayerTransportAccepted" &&
    formalConsumed["BoundaryColumns"] === 4];

transferredBoundary = BuildTransportBoundaryVector[prunedModeMap, <|
    "g" -> <|"PeriodClass" -> "GPL", "Status" -> "ExactZero"|>,
    "e" -> <|"PeriodClass" -> "Elliptic",
      "Status" -> "Transferable", "TransferFrom" -> "source-period",
      "TransferMap" -> <|0 -> 0,
        1 -> BoundaryPeriodCoefficient["source-period", 2]|>|>|>,
  {0, 1}, "MissingPeriodAction" -> "Formal"];
FTAssert["known zeros and transfer maps are substituted and zero transfer coordinates are pruned",
  transferredBoundary["Status"] ===
      "FormalTransportBoundaryVectorBuilt" &&
    transferredBoundary["BoundaryConstantVector"] ===
      {BoundaryPeriodCoefficient["source-period", 2]} &&
    Lookup[transferredBoundary["Stage3NeedsLedger"], "Status"] ===
      {"KnownZero", "Transferable"} &&
    transferredBoundary["Stage3NeedsLedger"][[2,
      "AffectedBoundaryCoordinates"]] === {{"e", 1}}];

exactTransferBoundary = BuildTransportBoundaryVector[prunedModeMap, <|
    "g" -> <|"PeriodClass" -> "GPL", "Status" -> "ExactZero"|>,
    "e" -> <|"PeriodClass" -> "Elliptic",
      "Status" -> "Transferable", "TransferFrom" -> "known-period",
      "TransferMap" -> <|0 -> 5, 1 -> 7|>|>|>, {0, 1}];
FTAssert["a complete exact transfer needs no formal placeholder and is marked exact-with-transfers",
  exactTransferBoundary["Status"] ===
      "TransportBoundaryVectorBuilt" &&
    exactTransferBoundary["BoundaryDataStatus"] ===
      "ExactWithTransfers" &&
    exactTransferBoundary["BoundaryConstantVector"] === {5, 7} &&
    exactTransferBoundary["Stage3NeedsLedger"][[2, "Status"]] ===
      "Transferable"];

FTAssert["class mismatches, approximate constants and truncated Laurent data are never accepted",
  BuildTransportBoundaryVector[modeMap,
      MapAt[Join[#, <|"PeriodClass" -> "GPL"|>] &, periods,
        Key["e"]], {0, 1}]["Status"] ===
      "BoundaryPeriodDataInvalid" &&
    BuildTransportBoundaryVector[modeMap,
      MapAt[Join[#, <|"Coefficients" -> <|0 -> 2., 1 -> 3|>|>] &,
        periods, Key["g"]], {0, 1}]["Status"] ===
      "BoundaryPeriodDataInvalid" &&
    BuildTransportBoundaryVector[modeMap,
      MapAt[Join[#, <|"Coefficients" -> <|0 -> elliptic0|>|>] &,
        periods, Key["e"]], {0, 1}]["Status"] ===
      "EllipticBoundaryPeriodsIncomplete"];

FTAssert["the production boundary module contains no family-specific token",
  With[{text = Import[FileNameJoin[{root, "FeynFacet", "Private",
      "Transport", "Boundary", "PhysicalBoundary.wl"}], "Text"]},
    StringFreeQ[text, RegularExpression["CF[0-9]+"]]]];

FTReport[];
