#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

z = Symbol["Global`layerEndpointZ"];
a = Symbol["Global`layerEndpointA"];
source = <|"Letters" -> {{"GPLPole", a}},
  "Residues" -> {SparseArray[{{1, 2} -> 2}, {2, 2}]}|>;
diagonal = <|"Letters" -> {{"GPLPole", a}},
  "Residues" -> {SparseArray[{{1, 1} -> 3}, {1, 1}]}|>;
incoming = <|
  -1 -> <|"Letters" -> {{"GPLPole", a}},
    "Residues" -> {SparseArray[{{1, 1} -> 5}, {1, 2}]}|>,
  1 -> <|"Letters" -> {{"GPLPole", a + 1}},
    "Residues" -> {SparseArray[{{1, 2} -> 7}, {1, 2}]}|>
|>;

result = ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint[
  source, diagonal, incoming, z, a];
FTAssert["a rational-epsilon-dependent block connection residue is computed directly as Laurent coefficients at a local expansion point",
  result["Status"] ===
    "RationalEpsilonDependentBlockConnectionResidueComputed" &&
  result["Dimensions"] === <|"Source" -> 2, "Target" -> 1,
    "Total" -> 3|> &&
  result["LocalExpansionPoint"] === a &&
  Keys[result["BlockConnectionResiduesByEpsilonOrder"]] === {-1, 1} &&
  Normal[result["BlockConnectionResiduesByEpsilonOrder", -1]] ===
    {{0, 0, 0}, {0, 0, 0}, {5, 0, 0}} &&
  Normal[result["BlockConnectionResiduesByEpsilonOrder", 1]] ===
    {{0, 2, 0}, {0, 0, 0}, {0, 0, 3}}];

badIncoming = <|0 -> <|"Letters" -> {{"GPLPole", a}},
  "Residues" -> {IdentityMatrix[2]}|>|>;
FTAssert["an incoming deck with the wrong rectangular shape is refused",
  ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint[source, diagonal,
    badIncoming, z, a]["Status"] ===
      "IncomingBlockConnectionResidueDimensionsInvalid"];

FTSummary[];
