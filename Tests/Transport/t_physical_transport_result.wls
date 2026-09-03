#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`physicalResultU"];
eps = Symbol["Global`physicalResultEps"];
source = <|"Dimension" -> 2,
  "Letters" -> {{"GPLPole", -1}},
  "Residues" -> {ConstantArray[0, {2, 2}]}|>;
layer = <|"Rows" -> {3, 4},
  "PathVariable" -> u, "Regulator" -> eps,
  "BasePoint" -> 0, "Endpoint" -> 1,
  "Diagonal" -> {{{"GPLPole", -2}, ConstantArray[0, {2, 2}]}},
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 2/(u + 1),
      "Letter" -> {"GPLPole", -1}|>,
    <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 2/(u + 1),
      "Letter" -> {"GPLPole", -1}|>
  }|>;
boundary = <|
  "Status" -> "FormalTransportBoundaryVectorBuilt",
  "BoundaryDataStatus" -> "FormalNotEvaluated", "Dimension" -> 4,
  "BoundarySelectors" -> <|0 -> IdentityMatrix[4]|>,
  "BoundaryCoordinates" -> {
    <|"PeriodID" -> "a", "PeriodClass" -> "GPL", "EpsilonOrder" -> 0|>,
    <|"PeriodID" -> "b", "PeriodClass" -> "Elliptic", "EpsilonOrder" -> 0|>,
    <|"PeriodID" -> "c", "PeriodClass" -> "GPL", "EpsilonOrder" -> 0|>,
    <|"PeriodID" -> "d", "PeriodClass" -> "GPL", "EpsilonOrder" -> 0|>},
  "BoundaryConstantVector" -> {
    BoundaryPeriodCoefficient["a", 0],
    BoundaryPeriodCoefficient["b", 0],
    BoundaryPeriodCoefficient["c", 0],
    BoundaryPeriodCoefficient["d", 0]},
  "Stage3NeedsLedger" -> Table[<|"PeriodID" -> id,
      "AffectedBoundaryCoordinates" -> {{id, 0}},
      "Status" -> "Unevaluated"|>, {id, {"a", "b", "c", "d"}}]
|>;

attached = AttachTransportBoundaryToRationalLayer[
  source, layer, boundary, {1, 2}, {3, 4}];
demand = <|"Pairs" -> {{0, 1}, {0, 2}}|>;
transport = BuildRationalEpsilonLayerTransport[
  attached["Source"], attached["Layer"], demand,
  "WordRepresentation" -> "LazyOperator", "PrimeCount" -> 3];
operator = BuildRationalEpsilonLayerOperator[
  attached["Source"], attached["Layer"], transport];

FTAssert["a full physical boundary is split into one shared period basis and bound to a genuine accepted lazy transport",
  attached["Status"] === "TransportBoundaryAttachedToRationalLayer" &&
  transport["Status"] === "RationalEpsilonLayerTransportAccepted" &&
  transport["WordRepresentation"] === "LazyOperator" &&
  transport["GaugeAtEndpoint"][0] === IdentityMatrix[2] &&
  AcceptedRationalEpsilonLayerOperatorQ[operator] &&
  operator["BoundaryLayout"] === "Shared" &&
  operator["Dimensions", "TotalBoundary"] === 4];

coefficient = BuildPhysicalTransportCoefficient[operator, boundary,
  {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
    "Endpoint" -> 1|>];
FTAssert["the endpoint gauge and target boundary combine into a paper-facing coefficient",
  coefficient["Status"] === "PhysicalTransportCoefficientBuilt" &&
  coefficient["PaperTermCount"] === 1 &&
  coefficient["Expression"] ===
    BoundaryPeriodCoefficient["a", 0] +
      BoundaryPeriodCoefficient["c", 0] &&
  coefficient["Stage3", "ActiveBoundaryCoordinates"] ===
    {{"a", 0}, {"c", 0}} &&
  Length[coefficient["Stage3", "Ledger"]] === 2];

rebasedOperator = RebaseRationalEpsilonLayerOperator[
  operator, 1/2,
  attached["Source", "BoundarySelectors"],
  attached["Layer", "TargetBoundarySelectors"],
  "HAtNewBase" -> <|0 -> 2/3 IdentityMatrix[2]|>,
  "BasePointPrescription" -> <|"Type" -> "TangentialRegularized",
    "LocalDirection" -> -1|>];
rebasedCoefficient = BuildPhysicalTransportCoefficient[
  rebasedOperator, boundary, {0, 1},
  <|"Variable" -> u, "BasePoint" -> 1/2, "Endpoint" -> 1,
    "BasePointPrescription" -> <|"Type" -> "TangentialRegularized",
      "LocalDirection" -> -1|>|>];
FTAssert["an accepted operator rebases by Chen path composition without materializing an inverse series",
  AcceptedRationalEpsilonLayerOperatorQ[rebasedOperator] &&
  rebasedOperator["Rebase", "Method"] ===
    "ChenPathCompositionNoMaterialization" &&
  Normal[rebasedOperator["TargetBoundarySelectors", 0][[1]]] ===
    {-2/3, 0, 1, 0} &&
  rebasedCoefficient["Status"] === "PhysicalTransportCoefficientBuilt" &&
  rebasedCoefficient["Expression"] ===
    1/3 BoundaryPeriodCoefficient["a", 0] +
      BoundaryPeriodCoefficient["c", 0] &&
  rebasedCoefficient["Path", "BasePoint"] === 1/2 &&
  rebasedCoefficient["Path", "BasePointPrescription", "Type"] ===
    "TangentialRegularized"];

FTAssert["rebasing refuses to guess a nonzero gauge value or missing selector geometry",
  RebaseRationalEpsilonLayerOperator[operator, 1/2,
    attached["Source", "BoundarySelectors"],
    attached["Layer", "TargetBoundarySelectors"]]["Status"] ===
      "RationalLayerGaugeAtNewBaseRequired" &&
  RebaseRationalEpsilonLayerOperator[operator, 1/2,
    <|0 -> {{1}}|>, attached["Layer", "TargetBoundarySelectors"],
    "HAtNewBase" -> <|0 -> 2/3 IdentityMatrix[2]|>]["Status"] ===
      "RationalLayerRebaseSelectorsInvalid"];

gauged = BuildPhysicalTransportCoefficient[operator, boundary,
  {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
    "Endpoint" -> 1|>,
  "OutputGaugeByOrder" -> <|0 -> {{0, 1}, {1, 0}}|>];
FTAssert["an epsilon-dependent physical output gauge is applied after F=G+H source",
  gauged["Expression"] ===
    BoundaryPeriodCoefficient["b", 0] +
      BoundaryPeriodCoefficient["d", 0] &&
  gauged["Stage3", "ActiveBoundaryCoordinates"] ===
    {{"b", 0}, {"d", 0}}];

curve = u^4 - u^3 + 5 u^2 - 2 u + 1;
ellipticLayer = Join[attached["Layer"], <|
  "Curve" -> curve,
  "CurvePointValues" -> <||>,
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> eps,
      "Letter" -> {"E4Omega0"}|>,
    <|"Row" -> 2, "Column" -> 2, "Coefficient" -> eps,
      "Letter" -> {"E4Omega0"}|>
  }|>];
ellipticDemand = <|"Pairs" -> {{1, 1}}|>;
ellipticTransport = BuildRationalEpsilonLayerTransport[
  attached["Source"], ellipticLayer, ellipticDemand,
  "WordRepresentation" -> "LazyOperator"];
ellipticOperator = BuildRationalEpsilonLayerOperator[
  attached["Source"], ellipticLayer, ellipticTransport];
ellipticCoefficient = BuildPhysicalTransportCoefficient[
  ellipticOperator, boundary, {1, 1},
  <|"Variable" -> u, "BasePoint" -> 0, "Endpoint" -> 1,
    "Curve" -> curve|>];
FTAssert["a genuine mixed transport keeps its surviving eMPL word explicit and sends only active periods to Stage 3",
  ellipticTransport["Status"] === "RationalEpsilonLayerTransportAccepted" &&
  ellipticTransport["Certificate", "IncomingRoute"] === "IncomingDlogDirect" &&
  AcceptedRationalEpsilonLayerOperatorQ[ellipticOperator] &&
  ellipticCoefficient["FunctionSpace"] === "GPL+Elliptic" &&
  ! FreeQ[ellipticCoefficient["Expression"],
    TransportIteratedIntegral[{{"E4Omega0"}}, ___]] &&
  ellipticCoefficient["Stage3", "ActiveBoundaryCoordinates"] ===
    {{"a", 0}}];

tangentialEllipticOperator = RebaseRationalEpsilonLayerOperator[
  ellipticOperator, 0, attached["Source", "BoundarySelectors"],
  attached["Layer", "TargetBoundarySelectors"],
  "BasePointPrescription" -> <|"Type" -> "TangentialRegularized",
    "LocalDirection" -> 1|>];
tangentialEllipticCoefficient = BuildPhysicalTransportCoefficient[
  tangentialEllipticOperator, boundary, {1, 1},
  <|"Variable" -> u, "BasePoint" -> 0, "Endpoint" -> 1,
    "Curve" -> curve,
    "BasePointPrescription" -> <|"Type" -> "TangentialRegularized",
      "LocalDirection" -> 1|>|>];
tangentialFunction = tangentialEllipticCoefficient["Terms"][[1]]["Function"];
FTAssert["a singular-base word carries its tangential prescription in the paper-facing integral",
  tangentialEllipticCoefficient["Status"] ===
      "PhysicalTransportCoefficientBuilt" &&
  Head[tangentialFunction] === FeynFacet`TransportIteratedIntegral &&
  First[List @@ tangentialFunction] === {{"E4Omega0"}} &&
  Last[List @@ tangentialFunction] ===
    <|"Type" -> "TangentialRegularized", "LocalDirection" -> 1|>];

FTAssert["paper expansion caps fail closed",
  BuildPhysicalTransportCoefficient[ellipticOperator, boundary,
    {1, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "Endpoint" -> 1, "Curve" -> curve|>,
    "MaximumExpandedTerms" -> 0]["Status"] ===
      "PhysicalExpandedTermLimitInvalid"];

FTAssert["a different path, same-length different boundary basis, and an out-of-demand coefficient are refused",
  BuildPhysicalTransportCoefficient[operator, boundary,
    {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "Endpoint" -> 2|>]["Status"] ===
      "PhysicalTransportPathDoesNotMatchOperator" &&
  BuildPhysicalTransportCoefficient[operator,
    Join[boundary, <|"BoundaryCoordinates" ->
      Reverse[boundary["BoundaryCoordinates"]]|>],
    {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "Endpoint" -> 1|>]["Status"] ===
      "PhysicalBoundaryNotBoundToOperator" &&
  BuildPhysicalTransportCoefficient[operator, boundary,
    {1, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "Endpoint" -> 1|>]["Status"] ===
      "RationalLayerDemandOutsideAcceptedPairs"];

FTSummary[];
