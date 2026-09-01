(* CF303 scratch adapter for the accepted deferred baseline circuit.

   The ordinary 76-entry transfer is compiled by the existing one-incoming-
   edge weighted-Chen builder.  The twelve accepted exception K leaves stay
   as provenance-bearing composite letters.  Merged H and the recurrence-
   generated cross-K remainders are inert circuit nodes, so no characteristic-
   zero 2x43 H/K coefficient matrix is ever expanded. *)

If[Length[DownValues[cf303BuildHybridCircuitPathGaugeAdapter]] === 0,
  Get[FileNameJoin[{DirectoryName[$InputFileName],
    "cf303_hybrid_circuit_path_gauge_adapter.wl"}]]];

ClearAll[
  CF303HybridBaselineH,
  CF303Fq2,
  cf303HybridBaselineAddCircuitLetter,
  cf303BuildHybridBaselineLazyCircuitAdapter,
  cf303HybridBaselineCanonicalWordCoefficient,
  cf303HybridBaselinePhysicalWordCoefficient,
  cf303HybridBaselineRFPointValue,
  cf303HybridBaselineExtPointValue,
  cf303HybridBaselineCircuitPointRules,
  cf303HybridBaselineCrossKRecord,
  cf303HybridBaselineRFKernelTerms,
  cf303HybridBaselineCrossKTerms,
  cf303HybridBaselineResolvedPhysicalWordTerms
];

cf303HybridBaselineAddCircuitLetter[state_Association, label_List,
    order_Integer, row_Integer, column_Integer, sourceN_Integer] := Module[
  {next = state["NextID"] + 1, residue},
  residue = SparseArray[{{row, column} -> 1}, {2, sourceN}];
  <|"NextID" -> next,
    "Labels" -> Append[state["Labels"], label],
    "IDs" -> Append[state["IDs"], next],
    "Residues" -> Append[state["Residues"], {order, next} -> residue]|>
];

cf303BuildHybridBaselineLazyCircuitAdapter[
    sourceArtifact_Association, baseTransfer_Association,
    physicalGauge_Association, circuitManifest_Association,
    adapterManifest_Association, eps_Symbol, variable_Symbol] := Module[
  {sourceRows, targetRows = {44, 45}, sourceLocation, targetLocation,
   baseG, physicalByOrder, hSupport, hPairs, exceptionLeaves,
   state, exceptionIDs, crossIDs, block1IDs, gOperator, circuitABI,
   hShapes, status},

  If[sourceArtifact["Status"] =!=
        "CF303HybridEllipticOperatorAcceptedV1" ||
      baseTransfer["Status"] =!=
        "CF303Block25GeneralEllipticTransferAcceptedV1" ||
      physicalGauge["Status"] =!=
        "CF303Block25PhysicalGaugeAcceptedV1" ||
      circuitManifest["status"] =!=
        "CF303HybridBaselineDeferredExactCircuitAcceptedV1" ||
      adapterManifest["status"] =!=
        "CF303HybridBaselineLazyAdapterManifestV1",
    Return[<|"Status" ->
      "CF303HybridBaselineLazyCircuitInputInvalidV1"|>]];

  sourceRows = sourceArtifact["OriginalRows"];
  sourceLocation = AssociationThread[sourceRows, Range[Length[sourceRows]]];
  targetLocation = AssociationThread[targetRows, Range[2]];
  hSupport = adapterManifest["support", "h_source_masters"];
  exceptionLeaves = adapterManifest["exception_k_leaves"];
  If[Length[sourceRows] =!= 43 || ! AllTrue[hSupport,
      KeyExistsQ[sourceLocation, #] &] ||
      baseTransfer["Rows"] =!= targetRows,
    Return[<|"Status" ->
      "CF303HybridBaselineLazyCircuitLayoutInvalidV1"|>]];

  (* This is the accepted source G construction.  It materializes only the
     already-small base-transfer residues, never baseline H or cross-K. *)
  baseG = cf303BuildLazyFinalEllipticOperator[sourceArtifact,
    baseTransfer, eps, variable, {-3, 4}];
  If[baseG["Status"] =!=
      "CF303Final45LazyEllipticOperatorAcceptedV1", Return[baseG]];
  physicalByOrder = cf303PathGaugeCompilePhysicalGauge[
    physicalGauge, u, variable];

  (* {A,B} represents A+B Y.  Each populated entry is only an inert circuit
     address; its exact value remains the sealed recurrence over exact leaves. *)
  hPairs = Association@Table[order -> Table[SparseArray[
      Flatten@Table[
        {Lookup[targetLocation, targetMaster],
          Lookup[sourceLocation, sourceMaster]} ->
            CF303HybridBaselineH[order, targetMaster, sourceMaster,
              channel, p, variable],
        {targetMaster, targetRows}, {sourceMaster, hSupport}],
      {2, Length[sourceRows]}], {channel, 2}], {order, -3, 4}];

  state = <|"NextID" -> Length[baseG["Letters"]],
    "Labels" -> {}, "IDs" -> {}, "Residues" -> {}|>;

  (* The twelve exception remainders are accepted exact K leaves.  One
     composite letter per Laurent order avoids copying their huge expressions. *)
  Do[
    state = cf303HybridBaselineAddCircuitLetter[state,
      {"CF303AcceptedIncomingKLeaf", leaf["entry_index"], order,
        leaf["target"][[1]], leaf["target"][[2]]}, order,
      Lookup[targetLocation, leaf["target"][[1]]],
      Lookup[sourceLocation, leaf["target"][[2]]], Length[sourceRows]],
    {leaf, exceptionLeaves}, {order, -3, 4}];
  exceptionIDs = state["IDs"];

  (* Cross-Hermite support is exactly seven source columns and is zero at
     order -3.  Nodes that resolve to zero at a point remain cheap. *)
  Do[
    state = cf303HybridBaselineAddCircuitLetter[state,
      {"CF303HybridBaselineCrossK", order, targetMaster, sourceMaster},
      order, Lookup[targetLocation, targetMaster],
      Lookup[sourceLocation, sourceMaster], Length[sourceRows]],
    {order, -2, 4}, {targetMaster, targetRows},
    {sourceMaster, adapterManifest["support", "cross_k_source_masters"]}];
  crossIDs = Drop[state["IDs"], Length[exceptionIDs]];

  (* Block 1 remains the separately accepted delta-K circuit.  Its delta-H
     is already merged into CF303HybridBaselineH by the baseline evaluator. *)
  Do[
    state = cf303HybridBaselineAddCircuitLetter[state,
      {"CF303CircuitGPLKernel", order, row}, order, row,
      Lookup[sourceLocation, 1], Length[sourceRows]];
    state = cf303HybridBaselineAddCircuitLetter[state,
      {"CF303ExactEllipticKernel", order, row}, order, row,
      Lookup[sourceLocation, 1], Length[sourceRows]],
    {order, -3, 4}, {row, 1, 2}];
  block1IDs = Drop[state["IDs"],
    Length[exceptionIDs] + Length[crossIDs]];

  gOperator = Join[baseG, <|
    "Route" -> "OneIncomingEdgeLazyWeightedChenWithDeferredCF303Circuit",
    "Letters" -> Join[baseG["Letters"], state["Labels"]],
    "OffDiagonalLabels" -> Join[
      baseG["OffDiagonalLabels"], state["Labels"]],
    "OffDiagonalResidues" -> Join[baseG["OffDiagonalResidues"],
      Association[state["Residues"]]],
    "DeferredCircuitLetterIDs" -> state["IDs"]|>];

  circuitABI = <|
    "Version" -> 1,
    "Evaluator" -> circuitManifest["evaluator"],
    "PointCommand" ->
      "python3 EVALUATOR --p NUM/DEN --adapter-output OUTPUT.json",
    "PointStatus" -> "CF303HybridBaselineLazyAdapterPointV1",
    "FieldEncoding" ->
      "F_q2 coefficients are {base,omega}; polynomial lists are ascending",
    "HHead" -> HoldForm[CF303HybridBaselineH[
      order, targetMaster, sourceMaster, channel, p, variable]],
    "CrossKLabel" ->
      {"CF303HybridBaselineCrossK", "order", "targetMaster", "sourceMaster"},
    "AcceptedIncomingLeafLabel" ->
      {"CF303AcceptedIncomingKLeaf", "entryIndex", "order",
        "targetMaster", "sourceMaster"},
    "AcceptedIncomingLeafProvider" ->
      adapterManifest["exact_leaf_provenance", "merged_transfer"],
    "AcceptedIncomingLeafResolution" ->
      "Read EntryRecords[[entryIndex,4]] and extract only the requested epsilon order/word",
    "Block1PointResolver" ->
      adapterManifest["exact_leaf_provenance", "block1_point_resolver"],
    "SealedOperations" -> circuitManifest["sealed_operations"]|>;

  hShapes = Dimensions /@ # & /@ Values[hPairs];
  status = If[
    Sort[Keys[hPairs]] === Range[-3, 4] &&
      hShapes === ConstantArray[{{2, 43}, {2, 43}}, 8] &&
      Length[baseG["BoundaryColumns"]] === 293 &&
      Sort[Keys[physicalByOrder]] === {0, 1, 2} &&
      Length[exceptionLeaves] === 12 && Length[exceptionIDs] === 96 &&
      Length[crossIDs] === 98 && Length[block1IDs] === 32 &&
      hSupport === {1, 2, 12, 21, 22, 29, 30} &&
      circuitManifest["acceptance_totals", "points"] === 2,
    "CF303HybridBaselineLazyCircuitAdapterAcceptedV1",
    "CF303HybridBaselineLazyCircuitAdapterFailedV1"];

  <|"Status" -> status,
    "Route" -> "DeferredExactCircuitLazyGPL/eMPLWeightedChen",
    "SourceArtifact" -> sourceArtifact,
    "SourceRows" -> sourceRows, "TargetRows" -> targetRows,
    "BoundaryColumns" -> baseG["BoundaryColumns"],
    "GOperator" -> gOperator,
    "HByOrderPairs" -> hPairs, "HOrders" -> Range[-3, 4],
    "PhysicalGaugeByOrderPairs" -> physicalByOrder,
    "PhysicalGaugeOrders" -> {0, 1, 2},
    "Curve" -> (physicalGauge["Curve"] /. u -> variable),
    "Variable" -> variable,
    "PairConvention" -> "{A,B} represents A+B CF303Y[u]",
    "ExceptionIncomingLetterIDs" -> exceptionIDs,
    "BaselineCrossKLetterIDs" -> crossIDs,
    "Block1DeltaKLetterIDs" -> block1IDs,
    "DeferredCircuitLabels" -> state["Labels"],
    "CircuitABI" -> circuitABI,
    "CircuitManifest" -> circuitManifest,
    "AdapterManifest" -> adapterManifest,
    "CanonicalRelation" -> "F25=G25+H.L",
    "PhysicalRelation" -> "I25=T25.F25",
    "BoundaryConvention" ->
      "H(1/2)=0, so G25 and F25 share canonical boundary constants"|>
];

cf303HybridBaselineCanonicalWordCoefficient[adapter_Association,
    word_List, boundaryOrder_Integer, order_Integer] :=
  cf303PathGaugeCanonicalWordCoefficient[
    adapter, word, boundaryOrder, order];

cf303HybridBaselinePhysicalWordCoefficient[adapter_Association,
    word_List, boundaryOrder_Integer, order_Integer] :=
  cf303PathGaugePhysicalWordCoefficient[
    adapter, word, boundaryOrder, order];

cf303HybridBaselineRFPointValue[rf_Association, value_Integer,
    prime_Integer] := Module[{numerator, denominator},
  numerator = cf303HybridModularPolynomialValue[
    rf["numerator"], value, prime];
  denominator = cf303HybridModularPolynomialValue[
    rf["denominator"], value, prime];
  If[denominator === 0, Return[Missing["ZeroDenominator"]]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

cf303HybridBaselineExtPointValue[extension_Association, value_Integer,
    prime_Integer] := {
  cf303HybridBaselineRFPointValue[extension["base"], value, prime],
  cf303HybridBaselineRFPointValue[extension["omega"], value, prime]};

(* Point rules deliberately return an explicit F_q2 head.  They do not
   reinterpret modular residues as characteristic-zero rationals. *)
cf303HybridBaselineCircuitPointRules[resolution_Association,
    pathValue_Integer] := Module[{prime = resolution["prime"], harvested},
  harvested = Reap[Do[
    Do[Sow[Verbatim[CF303HybridBaselineH][record["order"],
        record["target_master"], record["source_master"], channel,
        Blank[], Blank[]] -> With[{value =
          cf303HybridBaselineExtPointValue[
            record["pair", If[channel === 1, "rational", "elliptic"]],
            pathValue, prime]}, CF303Fq2[value[[1]], value[[2]], prime]]],
      {channel, 1, 2}],
    {record, resolution["h_outputs"]}]][[2]];
  If[harvested === {}, {}, First[harvested]]
];

cf303HybridBaselineCrossKRecord[resolution_Association, label_List] :=
  SelectFirst[resolution["cross_k_outputs"],
    #["order"] === label[[2]] &&
      #["target_master"] === label[[3]] &&
      #["source_master"] === label[[4]] &,
    Missing["CrossKOutput", label]];

cf303HybridBaselineRFKernelTerms[rf_Association, channel_String,
    extension_Integer, variable_Symbol, prime_Integer] := Module[
  {numerator = rf["numerator"], denominator, tag, coefficient},
  If[numerator === {0}, Return[{}]];
  denominator = FromDigits[Reverse[rf["denominator"]], variable];
  tag = If[channel === "rational", "GPLFactor", "E4Factor"];
  DeleteCases[Table[
    coefficient = If[extension === 1,
      CF303Fq2[numerator[[power + 1]], 0, prime],
      CF303Fq2[0, numerator[[power + 1]], prime]];
    {coefficient, {tag, denominator, power}},
    {power, 0, Length[numerator] - 1}], {CF303Fq2[0, 0, _], _}]
];

cf303HybridBaselineCrossKTerms[label_List, resolution_Association,
    variable_Symbol] := Module[{record, prime = resolution["prime"]},
  record = cf303HybridBaselineCrossKRecord[resolution, label];
  If[MissingQ[record], Return[{}]];
  Flatten[Table[
    cf303HybridBaselineRFKernelTerms[
      record["pair", channel,
        If[extension === 1, "base", "omega"]],
      channel, extension, variable, prime],
    {channel, {"rational", "elliptic"}}, {extension, 1, 2}], 2]
];

(* Resolve only newly sealed circuit kernels.  Accepted exception leaves are
   intentionally preserved as exact provider labels; base and diagonal
   letters use the established GPL/eMPL standard-letter expansion. *)
cf303HybridBaselineResolvedPhysicalWordTerms[adapter_Association, word_List,
    baselineResolution_Association, block1Resolution_Association,
    variable_Symbol] := Module[
  {operator = adapter["GOperator"], definitions, labelled, expanded,
   baseChoices, choices, expandLabel, merged},
  definitions = operator["CompositeDefinitions"];
  labelled = cf303FinalEllipticWordLabels[operator, word];
  expandLabel[label_] := Which[
    MatchQ[label, {"CF303HybridBaselineCrossK", _Integer,
        _Integer, _Integer}],
      cf303HybridBaselineCrossKTerms[label, baselineResolution, variable],
    MatchQ[label, {"CF303CircuitGPLKernel", _Integer, _Integer} |
        {"CF303ExactEllipticKernel", _Integer, _Integer}],
      cf303HybridResolveCircuitLabel[label, block1Resolution, variable],
    MatchQ[label, {"CF303AcceptedIncomingKLeaf", ___}], {{1, label}},
    True, cf303FinalStandardLetterExpansion[operator, label]];
  expanded = {{1, {}}};
  Do[
    baseChoices = Lookup[definitions, Key[label], {{1, label}}];
    choices = Flatten[Table[
      ({base[[1]] #[[1]], #[[2]]} &) /@ expandLabel[base[[2]]],
      {base, baseChoices}], 1];
    expanded = Flatten[Table[
      {left[[1]] right[[1]], Append[left[[2]], right[[2]]]},
      {left, expanded}, {right, choices}], 1],
    {label, labelled}];
  merged = Merge[(#[[2]] -> #[[1]]) & /@ expanded, Total];
  ({Last[#], First[#]} &) /@ Normal[merged]
];
