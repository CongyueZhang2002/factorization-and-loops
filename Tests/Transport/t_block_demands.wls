#!/usr/bin/env wolframscript
(* Exact observable-driven epsilon windows for the block-wise transport.

   The two demanded rows form a lower-triangular system,

     d F_1/dv = eps F_1/v,
     d F_2/dv = F_1/(eps v) + eps F_2/v,

   while F_3 is disconnected. Asking for F_2 through eps^1 therefore
   requires F_1 through eps^2, even though F_1 has no direct observable
   demand. F_3 must not be constructed at all.

   Acceptance criteria:
     1. exact demand propagation gives top orders {2,1,-Infinity};
     2. the solver converts the disconnected block to an empty interval;
     3. F_2 through eps^1 is exactly equal to a full-family calculation;
     4. every constructed block/order satisfies the exact recursion;
     5. malformed demands and demands without DepthRule -> Exact are
        refused rather than interpreted silently. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
(* 2026-08-25: this was the ONLY suite of 86 that loaded FeynFacet.m
   without loading the repository loader first.  LoadFACET.wl is what
   puts the bundled add-ons on the path, so without it FeynFacet.m's
   Needs["FeynCalc`"] cannot resolve and the package aborts by design
   ("the FeynCalcLegacy add-on is required but could not be loaded").
   The suite therefore aborted at this line and reached NONE of its
   assertions -- while still exiting 0, which is why it read as green
   for as long as it did. *)
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]];

vv = Symbol["Global`v"];
ww = Symbol["Global`w"];
ee = Symbol["Global`eps"];

zeroQ[expr_] := TrueQ[FeynFacet`Private`masterTransportZeroQ[expr]];
statusQ[result_] := AssociationQ[result] &&
  MemberQ[{"OK", "SolvedNotCheckable", "CheckInconclusive",
    "SolvedDECheckSkipped"}, Lookup[result, "Status", None]];

system = <|
  "Family" -> "TOY_BLOCK_DEMANDS",
  "Av" -> {
    {ee/vv, 0, 0},
    {1/(ee vv), ee/vv, 0},
    {0, 0, ee/vv}},
  "Aw" -> ConstantArray[0, {3, 3}]|>;

blocks = Table[
  {{i}, <|"Type" -> "EpsForm", "T" -> {{1}}|>},
  {i, 3}];

common = {
  "Variables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> blocks, "FormDirectory" -> None,
  "BasePoint" -> {1/4, 1/4}, "Target" -> {vv, ww},
  "PhysicalValuation" -> 0, "Orders" -> {0, 2},
  "Engine" -> "Blockwise", "TransportBackend" -> "Libra",
  "DepthRule" -> "Exact", "ConstantDepth" -> "PerBlockNeed",
  "PhiCrossCheck" -> False, "DECheck" -> None,
  "MaxWeight" -> 8, "Verbose" -> False};

full = FeynFacet`TransportFamily[system, Sequence @@ common];
scheduled = FeynFacet`TransportFamily[system, Sequence @@ common,
  "BlockDemands" -> {-Infinity, 1, -Infinity},
  "BlockLowerOrders" -> {0, 0, 2}];

valueForRows[rows_, values_, wanted_] :=
  values[[First @ FirstPosition[rows, wanted]]];
assemblyRows = scheduled["Assembly"]["Blocks"];
inactiveRows = scheduled["Assembly"]["Blocks"][[
  scheduled["ExactDepth"]["InactiveBlocks"]]];
inactiveIndex = First @ FirstPosition[scheduled["Assembly"]["Blocks"], {3}];

FTAssert["D1 both full and observable-driven transports produce exact recursion certificates",
  statusQ[full] && statusQ[scheduled] &&
    TrueQ[full["Blockwise"]["Certificate"]["AllZero"]] &&
    TrueQ[scheduled["Blockwise"]["Certificate"]["AllZero"]]];

FTAssert["D2 direct demand on block 2 through eps^1 propagates to block 1 through eps^2, while disconnected block 3 remains unreachable",
  (valueForRows[assemblyRows, scheduled["ExactDepth"]["RawNMax"], #] & /@
      {{1}, {2}, {3}}) ===
    {2, 1, -Infinity}];

FTAssert["D3 the unreachable block is represented by an empty epsilon interval and creates no word-map row",
  valueForRows[assemblyRows, scheduled["ExactDepth"]["NMax"], {3}] ===
      valueForRows[assemblyRows,
        scheduled["Blockwise"]["Schedule"]["KMin"], {3}] - 1 &&
    inactiveRows === {{3}} &&
    scheduled["Blockwise"]["Schedule"]["Top"][[inactiveIndex]] ===
      scheduled["Blockwise"]["Schedule"]["KMin"][[inactiveIndex]] - 1 &&
    FreeQ[scheduled["Blockwise"]["WordCounts"],
      record_Association /; Lookup[record, "Block", None] === inactiveIndex]];

fullSeries = AssociationThread[full["I"]["Orders"], full["I"]["I"]];
scheduledSeries = AssociationThread[
  scheduled["I"]["Orders"], scheduled["I"]["I"]];

FTAssert["D4 every demanded coefficient of the physical row is identical to the full-family calculation",
  Module[{row = First @ FirstPosition[scheduled["Assembly"]["Perm"], 2]},
    AllTrue[Range[0, 1],
      zeroQ[scheduledSeries[#][[row]] - fullSeries[#][[row]]] &]]];

FTAssert["D5 the scheduled calculation constructs fewer block/order rows than the full-family calculation",
  Length[scheduled["Blockwise"]["WordCounts"]] <
    Length[full["Blockwise"]["WordCounts"]]];

badRule = Quiet[FeynFacet`TransportFamily[system,
  Sequence @@ FilterRules[common, Except["DepthRule"]],
  "DepthRule" -> "Clamped", "BlockDemands" -> {-Infinity, 1, -Infinity}]];
badShape = Quiet[FeynFacet`TransportFamily[system, Sequence @@ common,
  "BlockDemands" -> {-Infinity, 1}]];

FTAssert["D6 BlockDemands without the exact Laurent-order recursion is refused",
  badRule === $Failed];
FTAssert["D7 a demand list whose length differs from the block count is refused",
  badShape === $Failed];

FTAssert["D8 identity diagonal transformations return the transported coefficients without a redundant Laurent-matrix multiplication",
  Lookup[full["I"], "Route", None] === "IdentityBlocks" &&
    And @@ MapThread[
      SameQ[#1, Lookup[full["F"], #2, ConstantArray[0, 3]]] &,
      {full["I"]["I"], full["I"]["Orders"]}]];

FTAssert["D9 transformed-block lower orders are remapped by physical rows and propagated through the negative-order coupling",
  (valueForRows[assemblyRows,
       scheduled["Blockwise"]["Schedule"]["KMin"], #] & /@
      {{1}, {2}, {3}}) === {0, 0, 2} &&
    (valueForRows[assemblyRows,
       scheduled["Blockwise"]["Schedule"]["Low"], #] & /@
      {{1}, {2}, {3}}) === {0, -1, 2}];

FTReport[];
