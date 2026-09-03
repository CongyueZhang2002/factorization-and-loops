#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`lazyLayerU"];

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
layer = <|
  "Rows" -> {7, 8},
  "Diagonal" -> {{{"E4OmegaInf"}, diagonalResidue}},
  "TargetBoundarySelectors" -> <|0 -> IdentityMatrix[2]|>
|>;

incomingResidue = {{2, 0}, {3, 1}};
transport = <|
  "Status" -> "RationalEpsilonLayerTransportAccepted",
  "Window" -> {-1, 1},
  "KResidues" -> <|{-1, u + 2, 0} -> incomingResidue|>,
  "GaugeAtEndpoint" -> <||>,
  "Certificate" -> <|"Probabilistic" -> True|>
|>;

operator = BuildRationalEpsilonLayerOperator[source, layer, transport];
d = First[operator["DiagonalTokens"]];
k = First[operator["IncomingTokens"]];
s = First[operator["SourceTokens"]];

FTAssert["the compact final-layer operator is accepted and keeps mixed GPL/eMPL labels opaque",
  AcceptedRationalEpsilonLayerOperatorQ[operator] &&
  operator["Dimensions"] === <|"Source" -> 2, "Target" -> 2,
    "SourceBoundary" -> 2, "TargetBoundary" -> 2,
    "TotalBoundary" -> 4|> &&
  operator["DiagonalLabels"][d] === {"E4OmegaInf"} &&
  operator["SourceLabels"][Last[operator["SourceTokens"]]] ===
    {"E4Omega0"}];

targetWord = RationalEpsilonLayerWordMap[operator, {d, d}, 0, 2];
FTAssert["a target-boundary word is evaluated on demand without enumerating sibling words",
  targetWord["Status"] === "RationalEpsilonLayerWordMap" &&
  Normal[targetWord["Map"]] ===
    ArrayFlatten[{{ConstantArray[0, {2, 2}],
      MatrixPower[diagonalResidue, 2]}}]];

incomingWord = RationalEpsilonLayerWordMap[
  operator, {d, k, s}, -1, 0, 2];
expectedIncoming = diagonalResidue . incomingResidue .
  sourceResidues[[1]] . source["BoundarySelectors"][-1];
FTAssert["a D-K-S word uses the Laurent order carried by its incoming token and returns only the requested row",
  incomingWord["Status"] === "RationalEpsilonLayerWordMap" &&
  Normal[incomingWord["Map"]] ===
    {Join[expectedIncoming[[2]], {0, 0}]}];

FTAssert["zero and invalid words are distinguished without an eager word census",
  RationalEpsilonLayerWordMap[operator, {}, 0, 0]["Status"] ===
    "RationalEpsilonLayerWordMap" &&
  RationalEpsilonLayerWordMap[operator, {k, k}, 0, -2]["Status"] ===
    "WordOutsideLayerGrammar" &&
  RationalEpsilonLayerWordMap[operator, {d}, 0, 7]["Status"] ===
    "WordOutsideLayerGrammar"];

demandTerms = RationalEpsilonLayerDemandTerms[operator, {0, 2}];
FTAssert["one requested coefficient is enumerated lazily and agrees term by term with the word accessor",
  demandTerms["Status"] === "RationalEpsilonLayerDemandTermsBuilt" &&
  demandTerms["TermCount"] > 0 &&
  AllTrue[demandTerms["Terms"], Function[term,
    Normal[term["Coefficient"]] === Normal[
      RationalEpsilonLayerWordMap[operator, term["WordTokens"],
        term["BoundaryOrder"], 0, 2]["Map"]]]]];

sharedLayer = <|
  "Rows" -> {7, 8},
  "Diagonal" -> {{{"GPLPole", -1}, ConstantArray[0, {2, 2}]}},
  "TargetBoundarySelectors" -> <|0 -> {{0, 1}, {1, 0}}|>,
  "SharedBoundaryCoordinates" -> True
|>;
sharedTransport = <|
  "Status" -> "RationalEpsilonLayerTransportAccepted",
  "Window" -> {0, 0}, "KResidues" -> <||>,
  "GaugeAtEndpoint" -> <|0 -> IdentityMatrix[2]|>,
  "Certificate" -> <|"Probabilistic" -> True|>
|>;
sharedOperator = BuildRationalEpsilonLayerOperator[
  Join[source, <|"Residues" -> ConstantArray[ConstantArray[0, {2, 2}], 2]|>],
  sharedLayer, sharedTransport];
sharedTerms = RationalEpsilonLayerDemandTerms[sharedOperator, {0, All}];
FTAssert["shared physical boundary coordinates are not duplicated and endpoint H contributes as a coefficient rather than a fake integration letter",
  AcceptedRationalEpsilonLayerOperatorQ[sharedOperator] &&
  sharedOperator["BoundaryLayout"] === "Shared" &&
  sharedOperator["Dimensions", "TotalBoundary"] === 2 &&
  Count[Lookup[sharedTerms["Terms"], "Kind"], "EndpointGauge"] === 1 &&
  AllTrue[sharedTerms["Terms"], #1["Word"] === {} &] &&
  Total[Normal /@ Lookup[sharedTerms["Terms"], "Coefficient"]] ===
    sharedLayer["TargetBoundarySelectors", 0] +
      source["BoundarySelectors", 0]];

FTAssert["lazy demand caps fail closed instead of silently truncating",
  RationalEpsilonLayerDemandTerms[operator, {2, All},
    "MaximumTerms" -> 1]["Status"] ===
      "RationalLayerTermEnumerationCapped"];

FTSummary[];
