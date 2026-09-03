#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`lazyLayerU"];
eps = Symbol["Global`lazyLayerEps"];

sourceResidues = {
  {{0, 1}, {0, 0}},
  {{1, 0}, {0, -1}}
};
source = <|
  "Dimension" -> 2,
  "Letters" -> {{"GPLPole", -1}, {"E4Omega0"}},
  "Residues" -> sourceResidues,
  "BoundarySelectors" -> <|
    -1 -> IdentityMatrix[2],
    0 -> {{1, 0}, {0, 0}}
  |>
|>;

diagonalResidue = {{1, 1}, {0, 1}};
incomingResidue = {{2, 0}, {3, 1}};
layer = <|
  "Rows" -> {7, 8},
  "PathVariable" -> u,
  "Regulator" -> eps,
  "BasePoint" -> 0,
  "Endpoint" -> 1,
  "Curve" -> u^4 + 1,
  "CurvePointValues" -> <||>,
  "Diagonal" -> {{{"E4OmegaInf"}, diagonalResidue}},
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 2/eps,
      "Letter" -> {"GPLPole", -2}|>,
    <|"Row" -> 2, "Column" -> 1, "Coefficient" -> 3/eps,
      "Letter" -> {"GPLPole", -2}|>,
    <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 1/eps,
      "Letter" -> {"GPLPole", -2}|>
  },
  "TargetBoundarySelectors" -> <|0 -> IdentityMatrix[2]|>
|>;
demand = <|"Pairs" -> {{0, 1}, {0, 2}, {2, 1}, {2, 2}}|>;
transport = BuildRationalEpsilonLayerTransport[source, layer, demand,
  "WordRepresentation" -> "LazyOperator"];
operator = BuildRationalEpsilonLayerOperator[source, layer, transport];
d = First[operator["DiagonalTokens"]];
k = First[operator["IncomingTokens"]];
s = First[operator["SourceTokens"]];

FTAssert["the compact final-layer operator is built only from a genuine accepted lazy transport and keeps mixed GPL/eMPL labels opaque",
  transport["Status"] === "RationalEpsilonLayerTransportAccepted" &&
  transport["Certificate", "IncomingRoute"] === "IncomingDlogDirect" &&
  transport["WordRepresentation"] === "LazyOperator" &&
  transport["DemandedWords"] === None &&
  AcceptedRationalEpsilonLayerOperatorQ[operator] &&
  operator["Dimensions"] === <|"Source" -> 2, "Target" -> 2,
    "SourceBoundary" -> 2, "TargetBoundary" -> 2,
    "TotalBoundary" -> 4|> &&
  operator["DiagonalLabels"][d] === {"E4OmegaInf"} &&
  operator["IncomingLabels"][k] === {"GPLFactor", u + 2, 0} &&
  operator["SourceLabels"][Last[operator["SourceTokens"]]] ===
    {"E4Omega0"}];

targetWord = RationalEpsilonLayerWordMap[operator, {d, d}, 0, 2, 2];
FTAssert["a target-boundary word is evaluated on demand without enumerating sibling words",
  targetWord["Status"] === "RationalEpsilonLayerWordMap" &&
  Normal[targetWord["Map"]] ===
    {Join[ConstantArray[0, 2], MatrixPower[diagonalResidue, 2][[2]]]}];

incomingWord = RationalEpsilonLayerWordMap[
  operator, {d, k, s}, -1, 0, 2];
expectedIncoming = diagonalResidue . incomingResidue .
  sourceResidues[[1]] . source["BoundarySelectors"][-1];
FTAssert["a D-K-S word uses the Laurent order carried by its incoming token and returns only the requested row",
  incomingWord["Status"] === "RationalEpsilonLayerWordMap" &&
  Normal[incomingWord["Map"]] ===
    {Join[expectedIncoming[[2]], {0, 0}]}];

FTAssert["zero and invalid words remain distinct, while an unaccepted coefficient is refused before enumeration",
  RationalEpsilonLayerWordMap[operator, {}, 0, 0, 1]["Status"] ===
    "RationalEpsilonLayerWordMap" &&
  RationalEpsilonLayerWordMap[operator, {k, k}, 0, 0, 1]["Status"] ===
    "WordOutsideLayerGrammar" &&
  RationalEpsilonLayerWordMap[operator, {d}, 0, 0, 7]["Status"] ===
    "RationalLayerRowsInvalid" &&
  RationalEpsilonLayerWordMap[operator, {}, 0, 1, 1]["Status"] ===
    "RationalLayerDemandOutsideAcceptedPairs" &&
  RationalEpsilonLayerDemandTerms[operator, {1, 1}]["Status"] ===
    "RationalLayerDemandOutsideAcceptedPairs"];

demandTerms = RationalEpsilonLayerDemandTerms[operator, {0, 2}];
FTAssert["one accepted coefficient is enumerated lazily and agrees term by term with the word accessor",
  demandTerms["Status"] === "RationalEpsilonLayerDemandTermsBuilt" &&
  demandTerms["TermCount"] > 0 &&
  AllTrue[demandTerms["Terms"], Function[term,
    Normal[term["Coefficient"]] === Normal[
      RationalEpsilonLayerWordMap[operator, term["WordTokens"],
        term["BoundaryOrder"], 0, 2]["Map"]]]]];

alteredSource = Join[source, <|"Residues" ->
  ReplacePart[source["Residues"], {1, 1, 1} -> 7]|>];
alteredLayer = Join[layer, <|"Diagonal" ->
  ReplacePart[layer["Diagonal"], {1, 2, 1, 1} -> 7]|>];
FTAssert["the operator cannot pair an accepted transport with different source or layer mathematics",
  BuildRationalEpsilonLayerOperator[alteredSource, layer, transport]["Status"] ===
    "RationalLayerTransportInputMismatch" &&
  BuildRationalEpsilonLayerOperator[source, alteredLayer, transport]["Status"] ===
    "RationalLayerTransportInputMismatch"];

sharedSource = <|
  "Dimension" -> 2,
  "Letters" -> {{"GPLPole", -1}},
  "Residues" -> {ConstantArray[0, {2, 2}]},
  "BoundarySelectors" -> <|0 -> IdentityMatrix[2]|>
|>;
sharedLayer = <|
  "Rows" -> {7, 8},
  "PathVariable" -> u,
  "Regulator" -> eps,
  "BasePoint" -> 0,
  "Endpoint" -> 1,
  "Diagonal" -> {{{"GPLPole", -2}, ConstantArray[0, {2, 2}]}},
  "Incoming" -> {
    <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 2/(u + 1),
      "Letter" -> {"GPLPole", -1}|>,
    <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 2/(u + 1),
      "Letter" -> {"GPLPole", -1}|>
  },
  "TargetBoundarySelectors" -> <|0 -> {{0, 1}, {1, 0}}|>,
  "SharedBoundaryCoordinates" -> True
|>;
sharedDemand = <|"Pairs" -> {{0, 1}, {0, 2}}|>;
sharedTransport = BuildRationalEpsilonLayerTransport[
  sharedSource, sharedLayer, sharedDemand,
  "WordRepresentation" -> "LazyOperator", "PrimeCount" -> 3];
sharedOperator = BuildRationalEpsilonLayerOperator[
  sharedSource, sharedLayer, sharedTransport];
sharedTerms = RationalEpsilonLayerDemandTerms[sharedOperator, {0, All}];
FTAssert["shared physical boundary coordinates are not duplicated and a genuine reconstructed endpoint gauge contributes as a coefficient rather than a fake integration letter",
  sharedTransport["GaugeAtEndpoint"][0] === IdentityMatrix[2] &&
  AcceptedRationalEpsilonLayerOperatorQ[sharedOperator] &&
  sharedOperator["BoundaryLayout"] === "Shared" &&
  sharedOperator["Dimensions", "TotalBoundary"] === 2 &&
  Count[Lookup[sharedTerms["Terms"], "Kind"], "EndpointGauge"] === 1 &&
  AllTrue[sharedTerms["Terms"], #1["Word"] === {} &] &&
  Total[Normal /@ Lookup[sharedTerms["Terms"], "Coefficient"]] ===
    sharedLayer["TargetBoundarySelectors", 0] +
      sharedSource["BoundarySelectors", 0]];

FTAssert["lazy demand caps fail closed instead of silently truncating",
  RationalEpsilonLayerDemandTerms[operator, {2, All},
    "MaximumTerms" -> 1]["Status"] ===
      "RationalLayerTermEnumerationCapped"];

FTSummary[];
