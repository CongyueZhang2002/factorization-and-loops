#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

eps = Symbol["Global`tangentialJunctionEps"];
pLetter = {"GPLPole", 0};
zLetter = {"GPLPole", 1};

(* The two modes have genuinely different normal exponents.  Their local
   state maps sit at different epsilon shifts; the inverse selector deck
   routes both to the same upstream output order without setting eps to 0. *)
spec = <|
  "Regulator" -> eps,
  "Scope" -> "Full",
  "Junction" -> <|"Prescription" -> "TangentialRegularized",
    "NormalCoordinate" -> "rho", "LocalDirection" -> -1|>,
  "BoundaryCoordinateKeys" -> {{"period-a", 0}, {"period-b", 0}},
  "ModeExponents" -> {0, -2 - 4 eps},
  "SourceModeMap" -> <|
    0 -> SparseArray[{{1, 1} -> 1}, {1, 2}],
    1 -> SparseArray[{}, {1, 2}]|>,
  "TargetGModeMap" -> <|
    0 -> SparseArray[{}, {1, 2}],
    1 -> SparseArray[{{1, 2} -> 1}, {1, 2}]|>,
  "TargetGModeMapComplete" -> True,
  "RegularizedInverseSelectors" -> {
    <|"DownstreamBoundaryOrder" -> 0, "LocalStateOrder" -> 0,
      "Map" -> IdentityMatrix[2, SparseArray]|>,
    <|"DownstreamBoundaryOrder" -> 0, "LocalStateOrder" -> 1,
      "Map" -> IdentityMatrix[2, SparseArray]|>
  },
  "Regularization" -> <|
    "Status" -> "TangentialJunctionIntertwiningJetsAccepted",
    "CheckedRhoOrders" -> {0, 1},
    "Method" -> "ExactSyntheticControl"|>
|>;

binding = BuildTangentialJunctionBinding[spec];
FTAssert["a complete sparse zero/nonzero-exponent junction builds without merging its exponent sectors",
  AcceptedTangentialJunctionBindingQ[binding] &&
    binding["ModeExponents"] === {0, -2 - 4 eps} &&
    binding["Dimensions"] === <|"SourceState" -> 1,
      "TargetGState" -> 1, "LocalState" -> 2,
      "JunctionModes" -> 2, "DownstreamBoundary" -> 2,
      "Stage3Boundary" -> 2|>];

upstream = {
  <|"BoundaryOrder" -> -1, "OutputOrder" -> 0,
    "Word" -> {pLetter},
    "Map" -> SparseArray[{{1, 1} -> 2, {2, 2} -> 3}, {2, 2}]|>
};
downstream = {
  <|"BoundaryOrder" -> 0, "OutputOrder" -> 2,
    "Word" -> {zLetter},
    "Map" -> SparseArray[{{1, 1} -> 5, {1, 2} -> 7}, {1, 2}]|>,
  <|"BoundaryOrder" -> 0, "OutputOrder" -> 2,
    "Word" -> {zLetter},
    "Map" -> SparseArray[{{1, 1} -> -1}, {1, 2}]|>
};
composed = ComposeTangentialJunctionWordMaps[
  binding, upstream, downstream, 2];

FTAssert["epsilon-order routing, sparse multiplication and duplicate segmented-word merging give the exact coefficient map",
  composed["Status"] === "TangentialJunctionWordsComposed" &&
    composed["TermCount"] === 1 &&
    First[composed["Terms"]]["BoundaryOrder"] === -1 &&
    First[composed["Terms"]]["UpstreamWord"] === {pLetter} &&
    First[composed["Terms"]]["DownstreamWord"] === {zLetter} &&
    Normal[First[composed["Terms"]]["Map"]] === {{8, 21}}];

FTAssert["the consumer preserves Stage-3 coordinates and the ordered two-segment word contract",
  composed["BoundaryCoordinateKeys"] === spec["BoundaryCoordinateKeys"] &&
    composed["ActiveBoundaryColumns"] === {1, 2} &&
    composed["SegmentedWordConvention"] === <|
      "KeyOrder" -> {"UpstreamWord", "DownstreamWord"},
      "WordOrientation" -> "OutermostFirst",
      "NoShuffleExpansion" -> True|>];

incomplete = BuildTangentialJunctionBinding[
  Join[KeyDrop[spec, "TargetGModeMap"],
    <|"TargetGModeMapComplete" -> False,
      "IndependentTargetFModeMap" -> IdentityMatrix[1]|>]];
FTAssert["an F-mode map or a leading target extension cannot stand in for the complete target G-mode map",
  incomplete["Status"] === "TangentialJunctionTargetGModeMapRequired" &&
    ComposeTangentialJunctionWordMaps[
      Join[binding, <|"TargetGModeMapComplete" -> False|>],
      upstream, downstream, 2]["Status"] ===
        "TangentialJunctionTargetGModeMapRequired"];

FTSummary[];
