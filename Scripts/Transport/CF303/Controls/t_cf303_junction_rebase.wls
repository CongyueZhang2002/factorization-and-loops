#!/usr/bin/env wolframscript

repositoryRoot = DirectoryName[ExpandFileName[$InputFileName], 5];
Get[FileNameJoin[{repositoryRoot, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{repositoryRoot, "Scripts", "Transport", "CF303",
  "CF303JunctionRebase.wl"}]];

z = Symbol["Global`z"];
zTarget = Symbol["Global`zTarget"];

adapter = <|
  "Status" -> "CF303HybridBaselineLazyCircuitAdapterAcceptedV1",
  "Variable" -> z,
  "Curve" -> z^4 + 1,
  "SourceArtifact" -> <|
    "Path" -> <|"Variable" -> z, "Base" -> 1/2,
      "Endpoint" -> zTarget|>,
    "Operator" -> <|"BoundaryColumns" -> {{1, 0, 1}},
      "BoundarySelectors" -> <|0 -> {{1}}|>|>|>,
  "GOperator" -> <|"SourceN" -> 1|>,
  "TargetRows" -> {44},
  "BoundaryColumns" -> {{1, 0, 1}}
|>;

junction = <|
  "Status" -> "CF303TangentialJunctionMapReconstructedV1",
  "CombinedModeOrder" -> {"source-mode", "target-mode"},
  "SourceModeMap" -> <|0 -> SparseArray[{{1, 1} -> 1}, {1, 2}]|>,
  "TargetGModeMap" -> <|0 -> SparseArray[{{1, 2} -> 1}, {1, 2}]|>
|>;

rebased = CF303RebaseLazyAdapterAtJunction[
  adapter, junction, {0, 0}];

FTAssert[
  "the CF303 local mode maps become initial data for the same differential system with tangential lower limit z=2p",
  CF303AcceptedJunctionRebasedAdapterQ[rebased] &&
    rebased["Path"] === rebased["SourceArtifact", "Path"] ===
      rebased["GOperator", "Path"] &&
    rebased["Path", "BasePoint"] === 2 Global`p &&
    rebased["Path", "PathEndpoint"] === zTarget &&
    rebased["Path", "BasePointPrescription", "Type"] ===
      "TangentialRegularized" &&
    rebased["Path", "BasePointPrescription", "LocalDirection"] === -1 &&
    Normal[rebased["SourceArtifact", "Operator",
      "BoundarySelectors", 0]] === {{1, 0}} &&
    Normal[rebased["GOperator", "TargetBoundarySelectors", 0]] ===
      {{0, 1}} &&
    rebased["JunctionRebase", "MathematicalOperation"] ===
      "Solve the same G-basis differential system with its lower limit and local initial data at z=2p"
];

FTAssert[
  "a source operator without an explicit path cannot be assigned new tangential initial data",
  CF303RebaseLazyAdapterAtJunction[
    ReplacePart[adapter, {"SourceArtifact", "Path"} -> <||>],
    junction, {0, 0}]["Status"] === "CF303LazyAdapterPathInvalid"
];

FTSummary[];
