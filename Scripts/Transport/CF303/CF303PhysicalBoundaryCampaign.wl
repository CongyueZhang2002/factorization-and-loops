(* CF303 data adapter.  It loads only the accepted 43+2 lazy operator and its
   small manifests.  In particular it never loads the obsolete 76-entry-only
   low-order materialization or constructs dense characteristic-zero H/K. *)

ClearAll[CF303PhysicalBoundaryCampaign];
cf303PhysicalBoundaryCampaignDirectory =
  DirectoryName[ExpandFileName[$InputFileName]];

Options[CF303PhysicalBoundaryCampaign] = {
  "RuntimeRoot" -> Automatic,
  "ScratchRoot" -> Automatic
};

CF303PhysicalBoundaryCampaign[OptionsPattern[]] := Catch@Module[
  {fail, here, repository, scratch, runtime, artifactFile, manifestFile,
   validationFile, staleFile, artifact, manifest, validation, sourceRows,
   targetRows, boundaryColumns, sourceCount, targetColumns, sourcePath,
   path, p, u, a, soft, endpoint1, endpoint2, coefficient1,
   coefficient2, physicalEndpoint, canonicalToPhysical, ledger, spec,
   campaign, completeIncomingCount},
  fail[name_, extra_: <||>] := Throw[Join[<|"Status" -> name|>, extra]];
  here = cf303PhysicalBoundaryCampaignDirectory;
  repository = DirectoryName[here, 3];
  scratch = Replace[OptionValue["ScratchRoot"],
    Automatic :> FileNameJoin[{DirectoryName[repository],
      "factorization-and-loops-codex"}]];
  runtime = Replace[OptionValue["RuntimeRoot"], Automatic :>
    FileNameJoin[{scratch, "Runtime",
      "2026-08-31_cf303_native_dlog_residues"}]];
  artifactFile = FileNameJoin[{runtime,
    "cf303_final45_hybrid_baseline_lazy_operator.wl"}];
  manifestFile = FileNameJoin[{runtime,
    "cf303_hybrid_baseline_lazy_adapter_manifest.json"}];
  validationFile = FileNameJoin[{runtime,
    "cf303_hybrid_baseline_lazy_adapter_validation.json"}];
  staleFile = FileNameJoin[{runtime,
    "cf303_final45_low_order_materialization.wl"}];
  If[! And @@ (FileExistsQ /@ {artifactFile, manifestFile, validationFile}),
    fail["CF303AcceptedTransportInputsMissing", <|"RequiredFiles" ->
      {artifactFile, manifestFile, validationFile}|>]];

  artifact = Get[artifactFile];
  manifest = Import[manifestFile, "RawJSON"];
  validation = Import[validationFile, "RawJSON"];
  If[Lookup[artifact, "Status", None] =!=
        "CF303HybridBaselineLazyCircuitAdapterAcceptedV1" ||
      Lookup[manifest, "status", None] =!=
        "CF303HybridBaselineLazyAdapterManifestV1" ||
      Lookup[validation, "status", None] =!=
        "CF303HybridBaselineLazyAdapterAcceptedV1",
    fail["CF303AcceptedTransportEvidenceInvalid"]];

  sourceRows = artifact["SourceRows"];
  targetRows = artifact["TargetRows"];
  boundaryColumns = artifact["BoundaryColumns"];
  sourceCount = artifact["GOperator", "SourceBoundaryCount"];
  targetColumns = artifact["GOperator", "TargetBoundaryColumns"];
  completeIncomingCount = 76 + Length[manifest["exception_k_leaves"]] + 2;
  If[Length[sourceRows] =!= 43 || targetRows =!= {44, 45} ||
      Sort[Join[sourceRows, targetRows]] =!= Range[45] ||
      sourceCount =!= 287 || Length[boundaryColumns] =!= 293 ||
      completeIncomingCount =!= 90 ||
      artifact["HOrders"] =!= Range[-3, 4] ||
      artifact["PhysicalGaugeOrders"] =!= Range[0, 2],
    fail["CF303AcceptedTransportLayoutInvalid"]];

  sourcePath = artifact["SourceArtifact", "Path"];
  path = <|"Variable" -> sourcePath["Variable"],
    "BasePoint" -> sourcePath["Base"], "Endpoint" -> sourcePath["Endpoint"],
    "Curve" -> artifact["Curve"]|>;

  (* In the Kallen2Bilinear115 chart, s=1-v-w=p+a.  The soft stratum a=-p
     has two u preimages.  The historical path has not selected a continued
     root sheet, so both are recorded and neither is silently preferred. *)
  p = Symbol["Global`p"];
  u = Symbol["Global`u"];
  a = Together[(4 p (1 - p) - 2 u)/(u^2 + 4 p (1 - p))];
  soft = Together[1 - (-a p) - (1 - a) (1 - p)];
  endpoint1 = 2 p;
  endpoint2 = Together[2 (1 - p^2)/p];
  coefficient1 = Together[D[soft, u] /. u -> endpoint1];
  coefficient2 = Together[D[soft, u] /. u -> endpoint2];
  physicalEndpoint = <|
    "Status" -> "PhysicalEndpointSheetSelectionRequired",
    "PhysicalChamber" -> HoldForm[
      Global`v > 0 && Global`w > 0 && Global`v + Global`w < 1],
    "CandidateStrata" -> {
      HoldForm[Global`v -> 0], HoldForm[Global`w -> 0],
      HoldForm[1 - Global`v - Global`w -> 0]},
    "SoftStratum" -> <|
      "PhysicalLimit" -> HoldForm[1 - Global`v - Global`w -> 0],
      "Direction" -> "Positive",
      "Chart" -> "Kallen2Bilinear115",
      "ChartMap" -> <|Global`v -> Together[-a p],
        Global`w -> Together[(1 - a) (1 - p)]|>,
      "PhysicalLocalVariable" -> HoldForm[1 - Global`v - Global`w],
      "ChartLocalExpression" -> soft,
      "Preimages" -> {
        <|"Endpoint" -> endpoint1,
          "PhysicalEndpointRelation" -> <|"LocalPower" -> 1,
            "LeadingCoefficient" -> coefficient1|>,
          "RootBranches" -> <|"SqrtLambda2" -> -2 p,
            "SqrtBilinear115" -> 1 - 2 p^2|>|>,
        <|"Endpoint" -> endpoint2,
          "PhysicalEndpointRelation" -> <|"LocalPower" -> 1,
            "LeadingCoefficient" -> coefficient2|>,
          "RootBranches" -> <|"SqrtLambda2" -> -2 p,
            "SqrtBilinear115" -> 2 p^2 - 1|>|>}
      |>,
    "MissingDatum" ->
      "A CF303 ordered stratum and continued-sheet/orientation record"|>;

  canonicalToPhysical = <|
    "Status" -> "CanonicalToPhysicalMapIncomplete",
    "Source" -> <|
      "Rows" -> sourceRows,
      "Status" -> "AcceptedSingularEndpointMapMissing",
      "KnownDefinition" ->
        "I_source=(TDiagonal.S).F_canonical, restricted to the 43 source rows",
      "PartialRegularPathArtifact" -> FileNameJoin[{scratch, "Runtime",
        "2026-08-31_cf303_analytic_transport",
        "cf303_selected21_source_gauge_slice.wl"}],
      "PartialRowCount" -> 37|>,
    "FinalLayer" -> <|
      "Rows" -> targetRows, "Status" -> "AcceptedPathGauge",
      "Orientation" -> artifact["PhysicalRelation"],
      "GaugeByOrderPairs" -> artifact["PhysicalGaugeByOrderPairs"],
      "Orders" -> artifact["PhysicalGaugeOrders"]|>,
    "MissingDatum" ->
      "A full 45-row canonical-to-physical map on the selected singular sheet"|>;

  ledger = {
    <|"PeriodID" -> "CF303::PhysicalBoundaryModes",
      "PeriodClass" -> "Undetermined",
      "Family" -> "CF303", "Limit" -> physicalEndpoint["SoftStratum"],
      "FrobeniusMode" -> <||>,
      "AffectedBoundaryCoordinates" -> boundaryColumns,
      "DemandedOutputs" -> Flatten[Table[{order, row},
        {order, -4, 2}, {row, targetRows}], 1],
      "Status" -> "Unevaluated",
      "Problem" -> "OrderedPhysicalLimitAndModeRealizationsRequired"|>,
    <|"PeriodID" -> "CF303::SourceCanonicalToPhysicalMap",
      "PeriodClass" -> "Undetermined",
      "Family" -> "CF303", "Limit" -> physicalEndpoint["SoftStratum"],
      "FrobeniusMode" -> <||>,
      "AffectedBoundaryCoordinates" -> Take[boundaryColumns, sourceCount],
      "DemandedOutputs" -> Flatten[Table[{order, row},
        {order, -4, 2}, {row, targetRows}], 1],
      "Status" -> "Unevaluated",
      "Problem" -> "FullSingularEndpointBasisMapRequired"|>};

  spec = <|
    "Family" -> "CF303",
    "AcceptedTransportStatus" ->
      "CF303HybridBaselineLazyCircuitAdapterAcceptedV1",
    "SourceRows" -> sourceRows, "TargetRows" -> targetRows,
    "SourceBoundaryCount" -> sourceCount,
    "BoundaryColumns" -> boundaryColumns,
    "TargetBoundaryColumns" -> targetColumns,
    "Path" -> path,
    "CanonicalToPhysical" -> canonicalToPhysical,
    "PhysicalEndpoint" -> physicalEndpoint,
    "BoundaryRealizations" -> Missing["NotRecorded"],
    "DeferredPointProvider" -> artifact["CircuitABI"],
    "Stage3NeedsLedger" -> ledger|>;
  campaign = BuildLazyTransportCampaign[artifact, spec];
  Join[campaign, <|
    "AcceptedData" -> <|
      "SourceOperator" -> artifact["SourceArtifact"],
      "FinalLayerOperator" -> artifact["GOperator"],
      "PathGaugeByOrderPairs" -> artifact["HByOrderPairs"],
      "PhysicalGaugeByOrderPairs" -> artifact["PhysicalGaugeByOrderPairs"],
      "IncomingEntryCount" -> completeIncomingCount,
      "IncomingComposition" -> <|"Baseline" -> 76,
        "ExceptionLeaves" -> Length[manifest["exception_k_leaves"]],
        "Block1Circuit" -> 2|>|>,
    "Evidence" -> <|"Artifact" -> artifactFile,
      "Manifest" -> manifestFile, "Validation" -> validationFile,
      "AcceptedPointCount" -> Length[validation["accepted_points"]],
      "NoCharacteristicZeroHKMaterialized" ->
        TrueQ[validation["no_characteristic_zero_h_or_k_matrix_materialized"]]|>,
    "InputPolicy" -> <|
      "Loaded" -> {artifactFile, manifestFile, validationFile},
      "ExcludedStaleArtifact" -> staleFile,
      "DenseCharacteristicZeroHK" -> "NotConstructed"|>
  |>]
];

CF303PhysicalBoundaryCampaign[___] :=
  <|"Status" -> "CF303PhysicalBoundaryCampaignInputsNotWellFormed"|>;
