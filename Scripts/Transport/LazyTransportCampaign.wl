(* Campaign-side adapter for an accepted lazy source plus a final rational-in-
   epsilon layer.  Family data stay in Scripts/Transport/<family>; this file
   only checks the shared row/boundary layout and carries an honest Stage-3
   needs ledger until physical modes are supplied. *)

ClearAll[BuildLazyTransportCampaign, LazyTransportCampaignBoundary];

BuildLazyTransportCampaign[transport_Association, spec_Association] :=
 Catch@Module[
  {fail, family, acceptedStatus, sourceRows, targetRows, sourceCount,
   boundaryColumns, targetColumns, path, ledger, realizations, status,
   requiredLedgerKeys},
  fail[name_, extra_: <||>] := Throw[Join[<|"Status" -> name|>, extra]];
  family = Lookup[spec, "Family", Missing[]];
  acceptedStatus = Lookup[spec, "AcceptedTransportStatus", Missing[]];
  sourceRows = Lookup[spec, "SourceRows", Missing[]];
  targetRows = Lookup[spec, "TargetRows", Missing[]];
  sourceCount = Lookup[spec, "SourceBoundaryCount", Missing[]];
  boundaryColumns = Lookup[spec, "BoundaryColumns", Missing[]];
  targetColumns = Lookup[spec, "TargetBoundaryColumns", Missing[]];
  path = Lookup[spec, "Path", Missing[]];
  ledger = Lookup[spec, "Stage3NeedsLedger", {}];
  realizations = Lookup[spec, "BoundaryRealizations", Missing[]];

  If[MissingQ[family] || MissingQ[acceptedStatus] ||
      Lookup[transport, "Status", None] =!= acceptedStatus,
    fail["AcceptedLazyTransportRequired"]];
  If[! MatchQ[sourceRows, {__Integer}] ||
      ! MatchQ[targetRows, {__Integer}] ||
      ! DuplicateFreeQ[Join[sourceRows, targetRows]] ||
      ! IntegerQ[sourceCount] || sourceCount < 0 ||
      ! ListQ[boundaryColumns] || ! ListQ[targetColumns] ||
      sourceCount + Length[targetColumns] =!= Length[boundaryColumns] ||
      Take[boundaryColumns, -Length[targetColumns]] =!= targetColumns,
    fail["LazyTransportBoundaryLayoutInvalid"]];
  If[! AssociationQ[path] || ! KeyExistsQ[path, "Variable"] ||
      ! KeyExistsQ[path, "BasePoint"] || ! KeyExistsQ[path, "Endpoint"],
    fail["LazyTransportPathInvalid"]];
  requiredLedgerKeys = {"PeriodID", "PeriodClass", "Family", "Limit",
    "FrobeniusMode", "AffectedBoundaryCoordinates", "Status"};
  If[! ListQ[ledger] || ! AllTrue[ledger, AssociationQ] ||
      ! AllTrue[ledger, Function[item,
        AllTrue[requiredLedgerKeys, KeyExistsQ[item, #] &]]],
    fail["Stage3NeedsLedgerInvalid"]];

  status = If[ListQ[realizations] && realizations =!= {} &&
      AllTrue[realizations, AssociationQ],
    "LazyTransportCampaignReadyForBoundaryModeMap",
    "LazyTransportCampaignNeedsPhysicalBoundaryData"];
  <|
    "Status" -> status,
    "Family" -> family,
    "Transport" -> transport,
    "SourceRows" -> sourceRows,
    "TargetRows" -> targetRows,
    "MasterCount" -> Length[sourceRows] + Length[targetRows],
    "BoundaryColumns" -> boundaryColumns,
    "SourceBoundaryCount" -> sourceCount,
    "TargetBoundaryColumns" -> targetColumns,
    "Path" -> path,
    "CanonicalToPhysical" -> Lookup[spec, "CanonicalToPhysical", <||>],
    "PhysicalEndpoint" -> Lookup[spec, "PhysicalEndpoint", <||>],
    "BoundaryRealizations" -> realizations,
    "DeferredPointProvider" -> Lookup[spec, "DeferredPointProvider", <||>],
    "Stage3NeedsLedger" -> ledger,
    "BoundaryModeMapInput" -> <|
      "Status" -> "BoundaryModeMapIncomplete",
      "Family" -> family,
      "Stage3NeedsLedger" -> ledger|>
  |>
];

BuildLazyTransportCampaign[___] :=
  <|"Status" -> "LazyTransportCampaignInputsNotWellFormed"|>;

LazyTransportCampaignBoundary[campaign_Association, modeMap_Association,
    periodData_, window : {_Integer, _Integer},
    missingAction : ("Formal" | "Refuse") : "Formal"] := Module[{boundary},
  If[! StringStartsQ[ToString[Lookup[campaign, "Status", ""]],
      "LazyTransportCampaign"],
    Return[<|"Status" -> "LazyTransportCampaignRequired"|>]];
  If[Lookup[modeMap, "Status", None] =!= "BoundaryModeMapBuilt",
    Return[<|"Status" -> "CompleteBoundaryModeMapRequired",
      "Stage3NeedsLedger" -> Lookup[modeMap, "Stage3NeedsLedger",
        Lookup[campaign, "Stage3NeedsLedger", {}]]|>]];
  boundary = BuildTransportBoundaryVector[modeMap, periodData, window,
    "MissingPeriodAction" -> missingAction];
  If[MemberQ[{"TransportBoundaryVectorBuilt",
       "FormalTransportBoundaryVectorBuilt"}, Lookup[boundary, "Status", None]] &&
      Lookup[boundary, "Dimension", None] =!=
        Lookup[campaign, "MasterCount", None],
    <|"Status" -> "PhysicalBoundaryDimensionMismatch",
      "ExpectedDimension" -> campaign["MasterCount"],
      "ActualDimension" -> Lookup[boundary, "Dimension", Missing[]],
      "Stage3NeedsLedger" -> Lookup[boundary, "Stage3NeedsLedger", {}]|>,
    boundary]
];

LazyTransportCampaignBoundary[___] :=
  <|"Status" -> "LazyTransportCampaignBoundaryInputsNotWellFormed"|>;
