#!/usr/bin/env wolframscript

(* Build the executable lazy CF303 final-row operator from the exact
   zero-block-1 baseline recurrence plus the accepted block-1 circuit. *)

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
scratch = "/home/maxzhang/factorization-and-loops-codex";
runtime = FileNameJoin[{scratch, "Runtime",
  "2026-08-31_cf303_native_dlog_residues"}];
sourceFile = FileNameJoin[{runtime,
  "cf303_hybrid_elliptic_operator_15_17_21.wl"}];
baseTransferFile = FileNameJoin[{runtime,
  "cf303_block25_general_elliptic_transfer.wl"}];
baselineGaugeFile = FileNameJoin[{runtime,
  "cf303_hybrid_baseline_finite_path_gauge.wl"}];
physicalGaugeFile = FileNameJoin[{runtime,
  "cf303_block25_physical_gauge.wl"}];
circuitFile = FileNameJoin[{runtime,
  "cf303_block1_full_exact_circuit.json"}];
ellipticFile = FileNameJoin[{runtime,
  "cf303_block1_exact_elliptic_source.json"}];
manifestValidationFile = FileNameJoin[{runtime,
  "cf303_hybrid90_circuit_path_gauge_validation.json"}];
resolvedFiles = FileNameJoin[{runtime, #}] & /@ {
  "cf303_block1_circuit_resolved_q2305843009213693693_p3d1.json",
  "cf303_block1_circuit_resolved_q2305843009213693693_p239d47.json"};
lazyLibrary = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_lazy_final_elliptic_transport.wl"}];
baselineLibrary = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_finite_path_gauge_adapter.wl"}];
hybridLibrary = FileNameJoin[{scratch, "Diagnostics", "Scripts",
  "cf303_hybrid_circuit_path_gauge_adapter.wl"}];
outputFile = FileNameJoin[{runtime,
  "cf303_final45_hybrid_circuit_path_gauge_operator.wl"}];
validationFile = FileNameJoin[{runtime,
  "cf303_final45_hybrid_circuit_path_gauge_validation.json"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Get[lazyLibrary]; Get[baselineLibrary]; Get[hybridLibrary];
sourceArtifact = Get[sourceFile];
baseTransfer = Get[baseTransferFile];
baselineGauge = Get[baselineGaugeFile];
physicalGauge = Get[physicalGaugeFile];
circuit = Import[circuitFile, "RawJSON"];
ellipticSource = Import[ellipticFile, "RawJSON"];
manifestValidation = Import[manifestValidationFile, "RawJSON"];
resolvedPoints = Import[#, "RawJSON"] & /@ resolvedFiles;

{buildSeconds, adapter} = AbsoluteTiming[
  cf303BuildHybridCircuitPathGaugeAdapter[sourceArtifact, baseTransfer,
    baselineGauge, physicalGauge, circuit, ellipticSource, eps, z]];
baselineAdapter = Lookup[adapter, "BaselineAdapter", <||>];

zeroPair[] := {SparseArray[{}, {2, 293}], SparseArray[{}, {2, 293}]};
pairEqual[left_, right_] := And @@ MapThread[
  TrueQ[Normal[#1] === Normal[#2]] &, {left, right}];
manualPhysical[word_, boundaryOrder_, order_] := Module[
  {result = zeroPair[], canonical, contribution},
  Do[
    canonical = cf303HybridCanonicalWordCoefficient[adapter, word,
      boundaryOrder, order - gaugeOrder];
    contribution = cf303PathGaugePairLeftMultiply[
      adapter["PhysicalGaugeByOrderPairs"][gaugeOrder], canonical,
      adapter["Curve"]];
    result = cf303PathGaugePairAdd[result, contribution],
    {gaugeOrder, adapter["PhysicalGaugeOrders"]}];
  result
];

probeStatus = "NOT_RUN";
physicalOrders = {};
resolverProbeStatus = "NOT_RUN";
deltaT25Reports = {};
If[adapter["Status"] ===
    "CF303HybridCircuitPathGaugeAdapterAcceptedV1",
  (* First nonzero rational image is (-2,row1); first elliptic image
     with a nonzero proper/cohomology part is (-1,row1). *)
  rationalLetter = adapter["CircuitIncomingLetterIDs"][[
    First@FirstPosition[adapter["CircuitIncomingLabels"],
      {"CF303CircuitGPLKernel", -2, 1}]]];
  ellipticLetter = adapter["CircuitIncomingLetterIDs"][[
    First@FirstPosition[adapter["CircuitIncomingLabels"],
      {"CF303ExactEllipticKernel", -1, 1}]]];
  rationalCanonical = cf303HybridCanonicalWordCoefficient[
    adapter, {rationalLetter}, 0, -2];
  rationalPhysical = cf303HybridPhysicalWordCoefficient[
    adapter, {rationalLetter}, 0, -2];
  ellipticCanonical = cf303HybridCanonicalWordCoefficient[
    adapter, {ellipticLetter}, 0, -1];
  ellipticPhysical = cf303HybridPhysicalWordCoefficient[
    adapter, {ellipticLetter}, 0, -1];
  physicalOrders = Table[
    pair = cf303HybridPhysicalWordCoefficient[adapter, {}, 0, order];
    <|"Order" -> order, "Dimensions" -> Dimensions /@ pair|>,
    {order, -4, 2}];
  probeStatus = If[
    And @@ (Dimensions[#] === {2, 293} & /@
      {rationalCanonical[[1]], rationalCanonical[[2]],
       rationalPhysical[[1]], rationalPhysical[[2]],
       ellipticCanonical[[1]], ellipticCanonical[[2]],
       ellipticPhysical[[1]], ellipticPhysical[[2]]}) &&
    pairEqual[rationalPhysical, manualPhysical[{rationalLetter}, 0, -2]] &&
    pairEqual[ellipticPhysical, manualPhysical[{ellipticLetter}, 0, -1]] &&
    And @@ ((#["Dimensions"] === {{2, 293}, {2, 293}} &) /@
      physicalOrders),
    "Accepted", "Failed"]
  ;
  resolverProbeStatus = If[And @@ Table[
      rationalResolved = cf303HybridCircuitResolvedPhysicalWordData[adapter,
        {rationalLetter}, 0, -2, resolution, 7, z];
      ellipticResolved = cf303HybridCircuitResolvedPhysicalWordData[adapter,
        {ellipticLetter}, 0, -1, resolution, 7, z];
      resolution["status"] ===
          "CF303Block1CircuitPointResolutionAcceptedV1" &&
        rationalResolved["Status"] ===
          "CF303HybridCircuitResolvedPhysicalWordAcceptedV1" &&
        ellipticResolved["Status"] ===
          "CF303HybridCircuitResolvedPhysicalWordAcceptedV1" &&
        Length[rationalResolved["PhysicalWordTerms"]] > 0 &&
        Length[ellipticResolved["PhysicalWordTerms"]] > 0,
      {resolution, resolvedPoints}], "Accepted", "Failed"]
  ;
  deltaT25Reports = cf303HybridValidateDeltaT25[
      adapter, baselineAdapter, #, 7] & /@ resolvedPoints
];

hShapes = If[AssociationQ[adapter], Association@KeyValueMap[
  Function[{order, pair}, order -> (Dimensions /@ pair)],
  Lookup[adapter, "HByOrderPairs", <||>]], <||>];
baselineExact = baselineGauge["Status"] ===
    "CF303Block25HybridBaselineFinitePathGaugeAcceptedV1" &&
  baselineGauge["CrossFailures"] === {} &&
  baselineGauge["BaseFailures"] === {} &&
  Length[baselineGauge["CrossReductionRecords"]] === 8 &&
  Sort[Keys[hShapes]] === Range[-3, 4] &&
  Values[hShapes] === ConstantArray[{{2, 43}, {2, 43}}, 8];
q7Block1 = manifestValidation["status"] ===
    "CF303Hybrid90CompositeInputManifestValidatedV1" &&
  manifestValidation["rational_recurrence_comparisons"] === 32 &&
  manifestValidation["basepoint_comparisons"] === 32 &&
  manifestValidation["exact_elliptic_profile_comparisons"] === 476;
mergedQ7Recurrence = baselineExact && q7Block1 &&
  adapter["Block1SupportAudit"]["RowCoordinatesOutsideColumn1"] === {};
deltaT25Accepted = Length[deltaT25Reports] === 2 &&
  AllTrue[deltaT25Reports,
    #["Status"] === "CF303HybridDeltaT25PointAcceptedV1" &];

status = If[adapter["Status"] ===
      "CF303HybridCircuitPathGaugeAdapterAcceptedV1" &&
    baselineExact && q7Block1 && probeStatus === "Accepted" &&
    resolverProbeStatus === "Accepted" && mergedQ7Recurrence &&
    deltaT25Accepted,
  "CF303Final45HybridCircuitPathGaugeOperatorAcceptedV1",
  "CF303Final45HybridCircuitPathGaugeOperatorFailedV1"];

artifact = <|
  "Status" -> status,
  "Family" -> "CF303", "MasterCount" -> 45,
  "SourceMasterCount" -> 43, "TargetRows" -> {44, 45},
  "BoundaryDimension" -> 293,
  "IncomingOrders" -> {-3, 4}, "TargetOrders" -> {-4, 2},
  "PhysicalGaugeOrders" -> {0, 1, 2},
  "Representation" ->
    "I25=T25.(Gbaseline+deltaG+(Hbaseline+deltaH).L), circuit coefficients lazy",
  "BuildSeconds" -> buildSeconds,
  "Adapter" -> KeyDrop[adapter, {"BaselineAdapter"}],
  "EvaluatorLibrary" -> hybridLibrary,
  "Inputs" -> <|"Source" -> sourceFile,
    "BaseTransfer76" -> baseTransferFile,
    "BaselineGauge88PlusZeroBlock1" -> baselineGaugeFile,
    "PhysicalGauge" -> physicalGaugeFile,
    "Block1Circuit" -> circuitFile,
    "Block1EllipticSource" -> ellipticFile|>,
  "Validation" -> <|
    "BaselineExactRecurrenceSlots" -> 8*2*43,
    "BaselineCrossFailures" -> baselineGauge["CrossFailures"],
    "BaselineBaseFailures" -> baselineGauge["BaseFailures"],
    "Block1Q7RationalRecurrences" ->
      manifestValidation["rational_recurrence_comparisons"],
    "Block1Q7Basepoints" ->
      manifestValidation["basepoint_comparisons"],
    "Block1Q7EllipticProfileComparisons" ->
      manifestValidation["exact_elliptic_profile_comparisons"],
    "MergedQ7RecurrenceStatus" -> If[mergedQ7Recurrence,
      "AcceptedByExactBaselinePlusDirectDeltaLinearity", "Failed"],
    "MergedQ7RecurrenceSlots" -> If[mergedQ7Recurrence, 2*8*2*43, 0],
    "StructuralPhysicalConvolutionProbe" -> probeStatus,
    "CircuitPointResolverProbe" -> resolverProbeStatus,
    "DeltaT25PointReplays" -> deltaT25Reports,
    "PhysicalOrderShapes" -> physicalOrders,
    "Block1SupportAudit" -> adapter["Block1SupportAudit"]|>,
  "StaleArtifactQuarantine" -> <|
    "Artifact" -> FileNameJoin[{runtime,
      "cf303_final45_low_order_materialization.wl"}],
    "Reason" -> "built from the stale 76-entry transfer; not an input here"|>|>;
Put[artifact, outputFile];

validation = <|
  "status" -> status,
  "operator" -> outputFile,
  "build_seconds" -> buildSeconds,
  "baseline_exact_recurrence_slots" -> 8*2*43,
  "baseline_cross_failures" -> Length[baselineGauge["CrossFailures"]],
  "baseline_base_failures" -> Length[baselineGauge["BaseFailures"]],
  "block1_q7_rational_recurrences" ->
    manifestValidation["rational_recurrence_comparisons"],
  "block1_q7_basepoints" ->
    manifestValidation["basepoint_comparisons"],
  "block1_q7_elliptic_profile_comparisons" ->
    manifestValidation["exact_elliptic_profile_comparisons"],
  "merged_q7_recurrence_status" -> mergedQ7Recurrence,
  "merged_q7_recurrence_slots" -> If[mergedQ7Recurrence, 2*8*2*43, 0],
  "structural_physical_convolution_probe" -> probeStatus,
  "circuit_point_resolver_probe" -> resolverProbeStatus,
  "delta_t25_point_replays" -> deltaT25Reports,
  "boundary_dimension" -> 293,
  "block1_source_position" ->
    adapter["Block1SupportAudit"]["SourcePosition"],
  "source_row1_off_column_support_count" ->
    Length[adapter["Block1SupportAudit"]["RowCoordinatesOutsideColumn1"]],
  "source_column1_nonzero_row_count" ->
    adapter["Block1SupportAudit"]["Column1NonzeroSourceRowCount"],
  "merge_rule" -> adapter["Block1SupportAudit"]["MergeRule"],
  "stale76_materialization_used" -> False|>;
Export[validationFile, validation, "RawJSON"];
Print[InputForm[KeyDrop[artifact, {"Adapter"}]]];
Print["VALIDATION ", validationFile];
Exit[If[StringEndsQ[status, "AcceptedV1"], 0, 2]];
