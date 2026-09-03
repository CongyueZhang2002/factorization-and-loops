#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "Transport",
  "LazyTransportCampaign.wl"}]];
Get[FileNameJoin[{root, "Scripts", "Transport", "CF303",
  "CF303PhysicalBoundaryCampaign.wl"}]];

campaign = CF303PhysicalBoundaryCampaign[];

FTAssert["the accepted 43+2 lazy CF303 transport is assembled without dense H/K",
  campaign["Status"] === "LazyTransportCampaignNeedsPhysicalBoundaryData" &&
  Length[campaign["SourceRows"]] === 43 &&
  campaign["TargetRows"] === {44, 45} &&
  campaign["MasterCount"] === 45 &&
  campaign["SourceBoundaryCount"] === 287 &&
  Length[campaign["BoundaryColumns"]] === 293 &&
  campaign["AcceptedData", "IncomingEntryCount"] === 90 &&
  campaign["Evidence", "AcceptedPointCount"] === 2 &&
  TrueQ[campaign["Evidence", "NoCharacteristicZeroHKMaterialized"]] &&
  FileExistsQ[campaign["DeferredPointProvider", "Evaluator"]] &&
  campaign["InputPolicy", "DenseCharacteristicZeroHK"] === "NotConstructed"];

FTAssert["the complete incoming layer is the accepted 76+12+2 composition",
  campaign["AcceptedData", "IncomingComposition"] ===
    <|"Baseline" -> 76, "ExceptionLeaves" -> 12,
      "Block1Circuit" -> 2|> &&
  Keys[Association[campaign["AcceptedData", "PathGaugeByOrderPairs"]]] ===
    Range[-3, 4] &&
  Keys[Association[campaign["AcceptedData", "PhysicalGaugeByOrderPairs"]]] ===
    Range[0, 2]];

FTAssert["the obsolete 76-entry-only materialization is excluded rather than loaded",
  ! MemberQ[campaign["InputPolicy", "Loaded"],
      campaign["InputPolicy", "ExcludedStaleArtifact"]] &&
  StringEndsQ[campaign["InputPolicy", "ExcludedStaleArtifact"],
    "cf303_final45_low_order_materialization.wl"]];

soft = campaign["PhysicalEndpoint", "SoftStratum"];
preimages = soft["Preimages"];
p = Symbol["Global`p"];
u = Symbol["Global`u"];
FTAssert["the soft endpoint pullback records both exact chart preimages",
  soft["ChartLocalExpression"] === Together[
    1 - soft["ChartMap"][Global`v] - soft["ChartMap"][Global`w]] &&
  Lookup[preimages, "Endpoint"] === {2 p, Together[2 (1 - p^2)/p]} &&
  AllTrue[preimages, Together[
      soft["ChartLocalExpression"] /. u -> #Endpoint] === 0 &]];

FTAssert["the branch ambiguity and the missing 43-row singular basis map stay typed",
  campaign["PhysicalEndpoint", "Status"] ===
      "PhysicalEndpointSheetSelectionRequired" &&
  campaign["CanonicalToPhysical", "Source", "Status"] ===
      "AcceptedSingularEndpointMapMissing" &&
  MissingQ[campaign["BoundaryRealizations"]] &&
  Lookup[campaign["Stage3NeedsLedger"], "Status"] ===
      {"Unevaluated", "Unevaluated"}];

refusal = BuildTransportBoundaryVector[
  campaign["BoundaryModeMapInput"], <||>, {-4, 2},
  "MissingPeriodAction" -> "Formal"];
FTAssert["the formal Stage-3 ledger is preserved by the package boundary API",
  refusal["Status"] === "CompleteBoundaryModeMapRequired" &&
  refusal["Stage3NeedsLedger"] === campaign["Stage3NeedsLedger"]];

FTReport[];
