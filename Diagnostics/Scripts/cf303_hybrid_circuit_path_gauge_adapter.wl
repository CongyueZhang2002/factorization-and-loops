(* Scratch-only lazy merge of the exact 88-entry CF303 baseline gauge with
   the separately accepted block-1 arithmetic circuit.  Circuit coefficients
   stay inert; the executable Python evaluator named in CircuitABI resolves
   them at exact or modular points. *)

If[Length[DownValues[cf303BuildFinitePathGaugeAdapter]] === 0,
  Get[FileNameJoin[{DirectoryName[$InputFileName],
    "cf303_finite_path_gauge_adapter.wl"}]]];

ClearAll[
  CF303CircuitH,
  CF303CircuitGPLKernel,
  CF303ExactEllipticKernel,
  cf303BuildHybridCircuitPathGaugeAdapter,
  cf303HybridCanonicalWordCoefficient,
  cf303HybridPhysicalWordCoefficient,
  cf303HybridCircuitKernelRecord,
  cf303HybridResolvedRecord,
  cf303HybridModularPolynomialValue,
  cf303HybridCircuitPointRules,
  cf303HybridResolveCircuitLabel,
  cf303HybridCircuitResolvedPhysicalWordTerms,
  cf303HybridCircuitResolvedPhysicalWordData,
  cf303HybridModularScalar,
  cf303HybridModularPair,
  cf303HybridValidateDeltaT25
];

cf303HybridCircuitKernelRecord[circuit_Association,
    order_Integer, row_Integer] := SelectFirst[circuit["outputs"],
  #["order"] === order && #["row"] === row &,
  Missing["CircuitOutput", {order, row}]];

cf303HybridResolvedRecord[resolution_Association,
    order_Integer, row_Integer] := SelectFirst[resolution["outputs"],
  #["order"] === order && #["row"] === row &,
  Missing["ResolvedOutput", {order, row}]];

cf303HybridModularPolynomialValue[coefficients_List, value_Integer,
    prime_Integer] := Fold[Mod[#1 value + #2, prime] &, 0,
      Reverse[coefficients]];

(* Rules are deliberately point-valued: they turn every inert coefficient
   head into a concrete field element without pretending that residues
   0..q-1 are characteristic-zero rationals. *)
cf303HybridCircuitPointRules[resolution_Association,
    pathValue_Integer] := Module[
  {prime = resolution["prime"], records, harvested, hValue},
  records = resolution["outputs"];
  harvested = Reap[Do[
    hValue = Mod[
      cf303HybridModularPolynomialValue[
        record["h"]["numerator"], pathValue, prime]
      PowerMod[cf303HybridModularPolynomialValue[
        record["h"]["denominator"], pathValue, prime], -1, prime], prime];
    Sow[Verbatim[CF303CircuitH][record["order"], record["row"],
      Blank[], Blank[]] -> hValue],
    {record, records}]][[2]];
  If[harvested === {}, {}, First[harvested]]
];

(* Resolve a construction letter to the existing root-free factor convention.
   The elliptic composite returns its exact linear E4Factor expansion. *)
cf303HybridResolveCircuitLabel[label_List, resolution_Association,
    variable_Symbol] := Module[
  {record, numerator, denominator, omega, factorTerms, omegaTerms},
  Which[
    MatchQ[label, {"CF303CircuitGPLKernel", _Integer, _Integer}],
      record = cf303HybridResolvedRecord[resolution, label[[2]], label[[3]]];
      denominator = FromDigits[
        Reverse[record["k_rational"]["denominator"]], variable];
      DeleteCases[Table[{record["k_rational"]["numerator"][[power + 1]],
          {"GPLFactor", denominator, power}},
        {power, 0, Length[record["k_rational"]["numerator"]] - 1}], {0, _}],
    MatchQ[label, {"CF303ExactEllipticKernel", _Integer, _Integer}],
      record = cf303HybridResolvedRecord[resolution, label[[2]], label[[3]]];
      numerator = record["k_elliptic"]["proper_numerator"];
      denominator = FromDigits[
        Reverse[record["k_elliptic"]["denominator"]], variable];
      omega = record["k_elliptic"]["omega_coefficients"];
      factorTerms = DeleteCases[Table[{numerator[[power + 1]],
          {"E4Factor", denominator, power}},
        {power, 0, Length[numerator] - 1}], {0, _}];
      omegaTerms = DeleteCases[{
        {omega["E4Omega0"], {"E4Omega0"}},
        {omega["E4OmegaInf"], {"E4OmegaInf"}},
        {omega["E4Eta2"], {"E4Eta2"}}}, {0, _}];
      Join[factorTerms, omegaTerms],
    True, {{1, label}}
  ]
];

cf303HybridCircuitResolvedPhysicalWordTerms[adapter_Association, word_List,
    resolution_Association, variable_Symbol] := Module[
  {operator = adapter["GOperator"], definitions, labelled, expanded,
   baseChoices, choices, merged, circuitLabelQ},
  definitions = operator["CompositeDefinitions"];
  labelled = cf303FinalEllipticWordLabels[operator, word];
  circuitLabelQ[label_] := MatchQ[label,
    {"CF303CircuitGPLKernel", _Integer, _Integer} |
    {"CF303ExactEllipticKernel", _Integer, _Integer}];
  expanded = {{1, {}}};
  Do[
    baseChoices = Lookup[definitions, Key[label], {{1, label}}];
    choices = Flatten[Table[
      If[circuitLabelQ[base[[2]]],
        ({base[[1]] #[[1]], #[[2]]} &) /@
          cf303HybridResolveCircuitLabel[base[[2]], resolution, variable],
        ({base[[1]] #[[1]], #[[2]]} &) /@
          cf303FinalStandardLetterExpansion[operator, base[[2]]]],
      {base, baseChoices}], 1];
    expanded = Flatten[Table[
      {left[[1]] right[[1]], Append[left[[2]], right[[2]]]},
      {left, expanded}, {right, choices}], 1],
    {label, labelled}];
  merged = Merge[(#[[2]] -> #[[1]]) & /@ expanded, Total];
  ({Last[#], First[#]} &) /@ Normal[merged]
];

cf303HybridCircuitResolvedPhysicalWordData[adapter_Association, word_List,
    boundaryOrder_Integer, order_Integer, resolution_Association,
    pathValue_Integer, variable_Symbol] := Module[
  {pair, rules, terms, coefficientNonzero, termNonzero, status},
  pair = cf303HybridPhysicalWordCoefficient[
    adapter, word, boundaryOrder, order];
  rules = cf303HybridCircuitPointRules[resolution, pathValue];
  pair = (Normal[#] /. rules) & /@ pair;
  terms = cf303HybridCircuitResolvedPhysicalWordTerms[
    adapter, word, resolution, variable];
  coefficientNonzero = AnyTrue[Flatten[pair], ! TrueQ[# === 0] &];
  termNonzero = AnyTrue[terms,
    ! TrueQ[Mod[First[#], resolution["prime"]] === 0] &];
  status = If[
    And @@ (Dimensions[#] === {2, 293} & /@ pair) &&
      FreeQ[pair, CF303CircuitH] &&
      FreeQ[terms, CF303CircuitGPLKernel | CF303ExactEllipticKernel] &&
      coefficientNonzero && termNonzero,
    "CF303HybridCircuitResolvedPhysicalWordAcceptedV1",
    "CF303HybridCircuitResolvedPhysicalWordFailedV1"];
  <|"Status" -> status, "Prime" -> resolution["prime"],
    "P" -> resolution["p"], "PathValue" -> pathValue,
    "BoundaryOrder" -> boundaryOrder, "Order" -> order,
    "InternalWord" -> word, "CoefficientPair" -> pair,
    "CoefficientNonzero" -> coefficientNonzero,
    "PhysicalWordTerms" -> terms,
    "PhysicalWordTermCount" -> Length[terms],
    "PhysicalWordTermsNonzero" -> termNonzero|>
];

cf303BuildHybridCircuitPathGaugeAdapter[sourceArtifact_Association,
    baseTransfer_Association, baselinePathGauge_Association,
    physicalGauge_Association, circuit_Association,
    ellipticSource_Association, eps_Symbol, variable_Symbol] := Module[
  {normalizedGauge, baseline, source, sourceRows, sourcePosition,
   rowOutsideColumn1, column1Rows, outputs, hPairs, deltaLabels = {},
   deltaResidues = <||>, deltaIDs, nextID, order, row, label,
   matrix, gOperator, status, circuitABI},

  If[baselinePathGauge["Status"] =!=
        "CF303Block25HybridBaselineFinitePathGaugeAcceptedV1" ||
      circuit["status"] =!=
        "CF303Block1CompleteExactArithmeticCircuitV1" ||
      ellipticSource["status"] =!=
        "CF303Block1ExactEllipticSourceAcceptedV1",
    Return[<|"Status" -> "CF303HybridCircuitPathGaugeInputInvalidV1"|>]];
  normalizedGauge = Join[baselinePathGauge,
    <|"Status" -> "CF303Block25FinitePathGaugeAcceptedV1"|>];
  baseline = cf303BuildFinitePathGaugeAdapter[sourceArtifact, baseTransfer,
    normalizedGauge, physicalGauge, eps, variable, {-3, 4}];
  If[baseline["Status"] =!= "CF303FinitePathGaugeAdapterAcceptedV1",
    Return[Join[baseline, <|"Status" ->
      "CF303HybridCircuitPathGaugeBaselineFailedV1"|>]]];

  source = sourceArtifact["Operator"];
  sourceRows = sourceArtifact["OriginalRows"];
  sourcePosition = First@FirstPosition[sourceRows, 1];
  rowOutsideColumn1 = Flatten[MapIndexed[Function[{residue, letterIndex},
    ({First[#], First[letterIndex]} &) /@ Select[ArrayRules[residue],
      MatchQ[First[#], {sourcePosition, _Integer}] &&
        First[#][[2]] =!= sourcePosition && ! TrueQ[Last[#] === 0] &]],
    source["Residues"]], 1];
  column1Rows = DeleteDuplicates[Flatten[Map[Function[residue,
    sourceRows[[#]] & /@ (First[#][[1]] & /@
      Select[ArrayRules[residue],
        MatchQ[First[#], {_Integer, sourcePosition}] &&
          ! TrueQ[Last[#] === 0] &])], source["Residues"]]]];
  If[rowOutsideColumn1 =!= {},
    Return[<|"Status" -> "CF303HybridCircuitColumnSplitInvalidV1",
      "RowOutsideColumn1" -> rowOutsideColumn1|>]];

  outputs = Association@Flatten[Table[{order, row} ->
    cf303HybridCircuitKernelRecord[circuit, order, row],
    {order, -3, 4}, {row, 1, 2}], 1];
  If[AnyTrue[Values[outputs], MissingQ],
    Return[<|"Status" -> "CF303HybridCircuitOutputLayoutInvalidV1"|>]];

  (* Preserve every baseline column, especially the feed-down already present
     in column 1, and add the invariant block-1 correction in that column. *)
  hPairs = Association@KeyValueMap[Function[{epsilonOrder, pair},
    epsilonOrder -> {
      SparseArray[pair[[1]] + SparseArray[Table[
        {targetRow, sourcePosition} -> CF303CircuitH[
          epsilonOrder, targetRow, p, variable], {targetRow, 1, 2}],
        Dimensions[pair[[1]]]]],
      SparseArray[pair[[2]]] }], baseline["HByOrderPairs"]];

  gOperator = baseline["GOperator"];
  nextID = Length[gOperator["Letters"]];
  Do[
    label = {"CF303CircuitGPLKernel", order, row};
    AppendTo[deltaLabels, label]; nextID++;
    matrix = SparseArray[{{row, sourcePosition} -> 1},
      {2, Length[sourceRows]}];
    deltaResidues[{order, nextID}] = matrix;
    label = {"CF303ExactEllipticKernel", order, row};
    AppendTo[deltaLabels, label]; nextID++;
    deltaResidues[{order, nextID}] = SparseArray[
      {{row, sourcePosition} -> 1}, {2, Length[sourceRows]}],
    {order, -3, 4}, {row, 1, 2}];
  deltaIDs = Range[Length[gOperator["Letters"]] + 1, nextID];
  gOperator = Join[gOperator, <|
    "Letters" -> Join[gOperator["Letters"], deltaLabels],
    "OffDiagonalLabels" -> Join[gOperator["OffDiagonalLabels"],
      deltaLabels],
    "OffDiagonalResidues" -> Join[gOperator["OffDiagonalResidues"],
      deltaResidues],
    "CircuitIncomingLetterIDs" -> deltaIDs|>];

  circuitABI = <|
    "Circuit" -> circuit,
    "EllipticSource" -> ellipticSource,
    "Evaluator" -> circuit["abi"]["circuit_evaluator"],
    "PointResolver" -> FileNameJoin[{DirectoryName[$InputFileName],
      "cf303_block1_circuit_point_resolver.py"}],
    "HHead" -> HoldForm[CF303CircuitH[order, row, p, variable]],
    "RationalLetterResolution" ->
      "CF303CircuitGPLKernel[n,row] resolves to Sum_i N_i GPLFactor[D(u),i]",
    "EllipticLetterResolution" ->
      "CF303ExactEllipticKernel[n,row] resolves through the accepted exact-profile E4Factor/E4Pole source leaf",
    "MaximumGPLFactorPower" -> 22,
    "CircuitIncomingLabelCount" -> 32|>;

  status = If[
    Sort[Keys[hPairs]] === Range[-3, 4] &&
      Dimensions[hPairs[-3][[1]]] === {2, 43} &&
      Length[gOperator["BoundaryColumns"]] === 293 &&
      Sort[Keys[baseline["PhysicalGaugeByOrderPairs"]]] === {0, 1, 2} &&
      Length[deltaLabels] === 32 &&
      rowOutsideColumn1 === {} && Length[column1Rows] === 42,
    "CF303HybridCircuitPathGaugeAdapterAcceptedV1",
    "CF303HybridCircuitPathGaugeAdapterFailedV1"];

  Join[baseline, <|
    "Status" -> status,
    "Route" -> "HybridExactBaselinePlusBlock1Circuit",
    "GOperator" -> gOperator,
    "HByOrderPairs" -> hPairs,
    "HOrders" -> Range[-3, 4],
    "CircuitIncomingLetterIDs" -> deltaIDs,
    "CircuitIncomingLabels" -> deltaLabels,
    "CircuitABI" -> circuitABI,
    "BaselineAdapter" -> baseline,
    "Block1SupportAudit" -> <|
      "SourcePosition" -> sourcePosition,
      "RowCoordinatesOutsideColumn1" -> rowOutsideColumn1,
      "Column1NonzeroSourceRows" -> column1Rows,
      "Column1NonzeroSourceRowCount" -> Length[column1Rows],
      "MergeRule" -> "baseline column 1 plus delta column 1"|>,
    "CanonicalRelation" -> "F25=G25+(Hbaseline+deltaH).L",
    "PhysicalRelation" -> "I25=T25.F25"|>]
];

cf303HybridCanonicalWordCoefficient[adapter_Association, word_List,
    boundaryOrder_Integer, order_Integer] :=
  cf303PathGaugeCanonicalWordCoefficient[
    adapter, word, boundaryOrder, order];

cf303HybridPhysicalWordCoefficient[adapter_Association, word_List,
    boundaryOrder_Integer, order_Integer] :=
  cf303PathGaugePhysicalWordCoefficient[
    adapter, word, boundaryOrder, order];

cf303HybridModularScalar[expression_, resolution_Association,
    pathValue_Integer] := Module[
  {prime = resolution["prime"], pValue, ycArguments, specialized,
   unresolved, numerator, denominator},
  pValue = Mod[resolution["p"][[1]]
    PowerMod[resolution["p"][[2]], -1, prime], prime];
  ycArguments = DeleteDuplicates[Cases[
    Unevaluated[expression], Yc[argument_] :> argument, Infinity]];
  If[! AllTrue[ycArguments, TrueQ[# === 1/2] &],
    Return[Missing["UnsupportedMarkedSheet", ycArguments]]];
  If[ycArguments =!= {} && ! IntegerQ[resolution["base_sheet"]],
    Return[Missing["BaseSheetUnavailable"]]];
  specialized = Together[expression /. {
    p -> pValue, z -> pathValue, u -> pathValue,
    Yc[_] -> resolution["base_sheet"]}];
  unresolved = DeleteDuplicates[
    Cases[specialized, symbol_Symbol :> symbol, Infinity]];
  If[unresolved =!= {},
    Return[Missing["UnresolvedSymbols", unresolved]]];
  numerator = Mod[Numerator[specialized], prime];
  denominator = Mod[Denominator[specialized], prime];
  If[denominator === 0, Return[Missing["ZeroDenominator"]]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

cf303HybridModularPair[pair_List, resolution_Association,
    pathValue_Integer] := (Map[
  cf303HybridModularScalar[#, resolution, pathValue] &,
  Normal[#], {2}] &) /@ pair;

(* Non-tautological merge/T25 replay.  For circuit incoming words, compare
   hybrid-baseline against T_g.deltaK.selector.  For the source-only empty
   word, compare it against the independently assembled sum
   Sum_g T_g.deltaH_(order-g).selector. *)
cf303HybridValidateDeltaT25[hybrid_Association, baseline_Association,
    resolution_Association, pathValue_Integer] := Module[
  {source, sourceN, boundaryDimension, selector, selectorRules,
   paddedSelector, zeroPair, rules, probes, kChecks = {}, hChecks = {},
   labelPosition, labelID, label, epsilonOrder, boundaryOrder = 0,
   deltaResidue, canonicalDelta, observed, direct, gaugeOrder,
   outputOrder, hOrder, deltaH, contribution, observedMod, directMod,
   status},
  source = hybrid["SourceArtifact"]["Operator"];
  sourceN = hybrid["GOperator"]["SourceN"];
  boundaryDimension = Length[hybrid["BoundaryColumns"]];
  selector = Lookup[source["BoundarySelectors"], boundaryOrder, None];
  If[selector === None,
    Return[<|"Status" -> "CF303HybridDeltaT25NoBoundarySelectorV1"|>]];
  selectorRules = Select[ArrayRules[selector],
    MatchQ[First[#], {_Integer, _Integer}] &];
  paddedSelector = SparseArray[selectorRules, {sourceN, boundaryDimension}];
  zeroPair[] := {SparseArray[{}, {2, boundaryDimension}],
    SparseArray[{}, {2, boundaryDimension}]};
  rules = cf303HybridCircuitPointRules[resolution, pathValue];
  probes = {
    {"Rational", {"CF303CircuitGPLKernel", -2, 1}},
    {"Elliptic", {"CF303ExactEllipticKernel", -1, 1}}};

  Do[
    labelPosition = First@FirstPosition[
      hybrid["CircuitIncomingLabels"], probe[[2]]];
    labelID = hybrid["CircuitIncomingLetterIDs"][[labelPosition]];
    label = hybrid["CircuitIncomingLabels"][[labelPosition]];
    epsilonOrder = label[[2]];
    deltaResidue = hybrid["GOperator"]["OffDiagonalResidues"][
      {epsilonOrder, labelID}];
    canonicalDelta = {deltaResidue . paddedSelector,
      SparseArray[{}, {2, boundaryDimension}]};
    Do[
      outputOrder = epsilonOrder + gaugeOrder;
      observed = cf303PathGaugePairAdd[
        cf303HybridPhysicalWordCoefficient[hybrid, {labelID},
          boundaryOrder, outputOrder],
        -cf303HybridPhysicalWordCoefficient[baseline, {labelID},
          boundaryOrder, outputOrder]];
      direct = cf303PathGaugePairLeftMultiply[
        hybrid["PhysicalGaugeByOrderPairs"][gaugeOrder],
        canonicalDelta, hybrid["Curve"]];
      observedMod = cf303HybridModularPair[
        (Normal[#] /. rules) & /@ observed, resolution, pathValue];
      directMod = cf303HybridModularPair[
        (Normal[#] /. rules) & /@ direct, resolution, pathValue];
      AppendTo[kChecks, <|"Channel" -> probe[[1]],
        "EpsilonOrder" -> epsilonOrder, "GaugeOrder" -> gaugeOrder,
        "OutputOrder" -> outputOrder,
        "Equal" -> TrueQ[observedMod === directMod]|>],
      {gaugeOrder, hybrid["PhysicalGaugeOrders"]}],
    {probe, probes}];

  Do[
    observed = cf303PathGaugePairAdd[
      cf303HybridPhysicalWordCoefficient[hybrid, {}, boundaryOrder,
        outputOrder],
      -cf303HybridPhysicalWordCoefficient[baseline, {}, boundaryOrder,
        outputOrder]];
    direct = zeroPair[];
    Do[
      hOrder = outputOrder - gaugeOrder;
      If[KeyExistsQ[hybrid["HByOrderPairs"], hOrder],
        deltaH = cf303PathGaugePairAdd[
          hybrid["HByOrderPairs"][hOrder],
          -baseline["HByOrderPairs"][hOrder]];
        canonicalDelta = {deltaH[[1]] . paddedSelector,
          deltaH[[2]] . paddedSelector};
        contribution = cf303PathGaugePairLeftMultiply[
          hybrid["PhysicalGaugeByOrderPairs"][gaugeOrder],
          canonicalDelta, hybrid["Curve"]];
        direct = cf303PathGaugePairAdd[direct, contribution]],
      {gaugeOrder, hybrid["PhysicalGaugeOrders"]}];
    observedMod = cf303HybridModularPair[
      (Normal[#] /. rules) & /@ observed, resolution, pathValue];
    directMod = cf303HybridModularPair[
      (Normal[#] /. rules) & /@ direct, resolution, pathValue];
    AppendTo[hChecks, <|"OutputOrder" -> outputOrder,
      "Equal" -> TrueQ[observedMod === directMod]|>],
    {outputOrder, -4, 2}];

  status = If[AllTrue[Join[kChecks, hChecks], TrueQ[#1["Equal"]] &],
    "CF303HybridDeltaT25PointAcceptedV1",
    "CF303HybridDeltaT25PointFailedV1"];
  <|"Status" -> status, "Prime" -> resolution["prime"],
    "P" -> resolution["p"], "PathValue" -> pathValue,
    "KChecks" -> kChecks, "HChecks" -> hChecks,
    "ComparisonCount" -> Length[kChecks] + Length[hChecks]|>
];
