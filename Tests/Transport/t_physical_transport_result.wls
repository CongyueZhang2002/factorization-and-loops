#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`physicalResultU"];
source = <|"Dimension" -> 2,
  "Letters" -> {{"GPLPole", -1}},
  "Residues" -> {ConstantArray[0, {2, 2}]}|>;
layer = <|"Rows" -> {3, 4},
  "Diagonal" -> {{{"GPLPole", -1}, ConstantArray[0, {2, 2}]}}|>;
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
transport = <|"Status" -> "RationalEpsilonLayerTransportAccepted",
  "Window" -> {0, 0}, "KResidues" -> <||>,
  "GaugeAtEndpoint" -> <|0 -> IdentityMatrix[2]|>,
  "PathVariable" -> u, "BasePoint" -> 0, "Endpoint" -> 1,
  "Curve" -> None,
  "Certificate" -> <|"Probabilistic" -> True|>|>;
operator = BuildRationalEpsilonLayerOperator[
  attached["Source"], attached["Layer"], transport];

FTAssert["a full physical boundary is split into one shared period basis",
  attached["Status"] === "TransportBoundaryAttachedToRationalLayer" &&
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

ellipticSource = Join[attached["Source"], <|
  "Letters" -> {{"E4Omega0"}}, "Residues" -> {{{1, 0}, {0, 0}}}|>];
ellipticTransport = Join[transport, <|"Curve" -> u^4 + u + 1|>];
ellipticOperator = BuildRationalEpsilonLayerOperator[
  ellipticSource, attached["Layer"], ellipticTransport];
ellipticCoefficient = BuildPhysicalTransportCoefficient[
  ellipticOperator, boundary, {1, 1},
  <|"Variable" -> u, "BasePoint" -> 0, "Endpoint" -> 1,
    "Curve" -> u^4 + u + 1|>];
FTAssert["mixed words remain explicit eMPL iterated integrals and only active periods reach Stage 3",
  ellipticCoefficient["FunctionSpace"] === "GPL+Elliptic" &&
  ! FreeQ[ellipticCoefficient["Expression"],
    TransportIteratedIntegral[{{"E4Omega0"}}, ___]] &&
  ellipticCoefficient["Stage3", "ActiveBoundaryCoordinates"] ===
    {{"a", 0}}];

FTAssert["paper expansion caps fail closed",
  BuildPhysicalTransportCoefficient[ellipticOperator, boundary,
    {1, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "Endpoint" -> 1, "Curve" -> u^4 + u + 1|>,
    "MaximumExpandedTerms" -> 0]["Status"] ===
      "PhysicalExpandedTermLimitInvalid"];

FTAssert["a different path or same-length but different boundary basis cannot be substituted",
  BuildPhysicalTransportCoefficient[operator, boundary,
    {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "Endpoint" -> 2|>]["Status"] ===
      "PhysicalTransportPathDoesNotMatchOperator" &&
  BuildPhysicalTransportCoefficient[operator,
    Join[boundary, <|"BoundaryCoordinates" ->
      Reverse[boundary["BoundaryCoordinates"]]|>],
    {0, 1}, <|"Variable" -> u, "BasePoint" -> 0,
      "Endpoint" -> 1|>]["Status"] ===
      "PhysicalBoundaryNotBoundToOperator"];

FTSummary[];
