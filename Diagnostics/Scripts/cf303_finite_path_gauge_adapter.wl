(* Scratch-only adapter from the accepted finite path gauge to the existing
   lazy CF303 weighted-Chen operator.  The package is not modified.

   A quadratic pair {A,B} represents A+B Y(u), with Y(u)^2=P4(u).  Matrices
   of pairs are stored as two equally shaped SparseArrays {A,B}; this keeps
   the endpoint gauges and word coefficients sparse without introducing a
   symbolic head at every matrix entry. *)

If[Length[DownValues[cf303BuildLazyFinalEllipticOperator]] === 0,
  Get[FileNameJoin[{DirectoryName[$InputFileName],
    "cf303_lazy_final_elliptic_transport.wl"}]]];

ClearAll[
  cf303BuildPathGaugeSyntheticTransfer,
  cf303BuildFinitePathGaugeAdapter,
  cf303PathGaugeCompileH,
  cf303PathGaugeCompilePhysicalGauge,
  cf303PathGaugePairAdd,
  cf303PathGaugePairLeftMultiply,
  cf303PathGaugePairNonzeroQ,
  cf303PathGaugeCanonicalWordCoefficient,
  cf303PathGaugePhysicalWordCoefficient,
  cf303PathGaugeCanonicalCoefficientRecords,
  cf303PathGaugePhysicalCoefficientRecords,
  cf303PathGaugeMaterializeCanonicalCoefficient,
  cf303PathGaugeMaterializePhysicalCoefficient,
  cf303PathGaugeMaterializeRecords,
  CF303Y
];

cf303PathGaugeSparseNonzeroQ[array_] :=
  FeynFacet`Private`masterTransportCWNonzeroSparseQ[SparseArray[array]];

cf303PathGaugePairNonzeroQ[{rational_, curve_}] :=
  cf303PathGaugeSparseNonzeroQ[rational] ||
    cf303PathGaugeSparseNonzeroQ[curve];

cf303PathGaugePairAdd[{leftR_, leftY_}, {rightR_, rightY_}] :=
  {SparseArray[leftR + rightR], SparseArray[leftY + rightY]};

(* (A+B Y).(C+D Y) = (A.C+P4 B.D)+(A.D+B.C)Y. *)
cf303PathGaugePairLeftMultiply[{leftR_, leftY_},
    {rightR_, rightY_}, curve_] :=
  {SparseArray[leftR . rightR + curve leftY . rightY],
   SparseArray[leftR . rightY + leftY . rightR]};

(* Repackage the transformed dlog residues in the exact EntryRecords schema
   consumed by cf303BuildLazyFinalEllipticOperator.  Coordinates whose
   transformed coupling vanishes are omitted; the four original target
   diagonal records and their constant-generator compression are retained. *)
cf303BuildPathGaugeSyntheticTransfer[originalTransfer_Association,
    pathGauge_Association, eps_Symbol] := Module[
  {targetRows, sourceRows, letterRecords, contributions, grouped,
   offRecords, diagonalRecords, profile, terms, orders, coordinate,
   baseSheetRule},

  If[originalTransfer["Status"] =!=
        "CF303Block25GeneralEllipticTransferAcceptedV1" ||
      pathGauge["Status"] =!=
        "CF303Block25FinitePathGaugeAcceptedV1",
    Return[<|"Status" -> "CF303PathGaugeSyntheticTransferInvalidV1"|>]];
  targetRows = pathGauge["TargetRows"];
  sourceRows = pathGauge["SourceRows"];
  letterRecords = pathGauge["LetterRecords"];
  baseSheetRule = Y0 -> Yc[pathGauge["BasePoint"]];

  contributions = Flatten[Map[
    Function[residueRecord, With[
      {order = residueRecord[[1]],
       descriptor = letterRecords[[residueRecord[[2]]]]},
      ({#[[{1, 2}]],
          {(#[[3]] /. baseSheetRule) eps^order,
            descriptor /. baseSheetRule}, order} &) /@
        residueRecord[[3]]]],
    pathGauge["TransformedResidueRecords"]], 1];
  If[contributions === {},
    Return[<|"Status" -> "CF303PathGaugeSyntheticTransferEmptyV1"|>]];
  grouped = GroupBy[contributions, First -> Rest];
  offRecords = KeyValueMap[Function[{key, values},
    coordinate = key;
    terms = values[[All, 1]];
    orders = Sort@DeleteDuplicates[values[[All, 2]]];
    profile = If[orders === {}, {"Zero"}, {"FiniteLaurent", orders}];
    {coordinate, {profile, profile}, {0, 0}, terms}], grouped];
  offRecords = SortBy[offRecords, First];

  diagonalRecords = Select[originalTransfer["EntryRecords"],
    MemberQ[targetRows, #[[1, 2]]] &];
  If[Length[diagonalRecords] =!= Length[targetRows]^2,
    Return[<|"Status" ->
      "CF303PathGaugeSyntheticTransferDiagonalMissingV1"|>]];

  Join[originalTransfer, <|
    "Status" -> "CF303Block25GeneralEllipticTransferAcceptedV1",
    "Rows" -> targetRows,
    "Columns" -> Join[sourceRows, targetRows],
    "EntryRecords" -> Join[offRecords, diagonalRecords],
    "SyntheticPathGauge" -> True,
    "SyntheticIncomingRecordCount" -> Length[offRecords],
    "PathGaugeStatus" -> pathGauge["Status"]|>]
];

(* HByOrder records use original master row labels.  Compile each H_n into
   its two sparse 2x43 coefficient matrices, preserving sourceRows order. *)
cf303PathGaugeCompileH[pathGauge_Association,
    endpointVariable_: Automatic] := Module[
  {sourceRows = pathGauge["SourceRows"],
   targetRows = pathGauge["TargetRows"], sourceLocation, targetLocation,
   dimensions, nativeVariable, outputVariable, variableRule,
   baseSheetRule, compileSide},
  sourceLocation = AssociationThread[sourceRows, Range[Length[sourceRows]]];
  targetLocation = AssociationThread[targetRows, Range[Length[targetRows]]];
  dimensions = {Length[targetRows], Length[sourceRows]};
  nativeVariable = Lookup[pathGauge, "Variable", u];
  outputVariable = Replace[endpointVariable, Automatic -> nativeVariable];
  variableRule = nativeVariable -> outputVariable;
  (* Maple uses Y0 for the fixed sheet value at the base point when it
     normalizes H_n(base)=0.  Keep that constant explicit in the Wolfram
     result instead of leaking an otherwise undefined serializer symbol. *)
  baseSheetRule = Y0 -> Yc[pathGauge["BasePoint"]];
  compileSide[records_, side_] := SparseArray[
    ({Lookup[targetLocation, #[[1]]], Lookup[sourceLocation, #[[2]]]} ->
        (#[[3, side]] /. baseSheetRule /. variableRule) &) /@ records,
    dimensions];
  Association@Map[Function[orderRecord,
    orderRecord[[1]] -> {
      compileSide[orderRecord[[2]], 1],
      compileSide[orderRecord[[2]], 2]}], pathGauge["HByOrder"]]
];

cf303PathGaugeCompilePhysicalGauge[physicalGauge_Association,
    nativeVariable_, outputVariable_] :=
  Association@Map[Function[orderRecord, With[
    {matrix = orderRecord[[2]] /. nativeVariable -> outputVariable},
    orderRecord[[1]] -> {
      SparseArray[matrix[[All, All, 1]]],
      SparseArray[matrix[[All, All, 2]]]}]],
    physicalGauge["GaugeByOrder"]];

cf303BuildFinitePathGaugeAdapter[sourceArtifact_Association,
    originalTransfer_Association, pathGauge_Association,
    physicalGauge_Association, eps_Symbol, variable_Symbol,
    epsilonOrders : {_Integer, _Integer}] := Module[
  {syntheticTransfer, gOperator, hByOrder, physicalByOrder, status},

  If[pathGauge["Status"] =!=
        "CF303Block25FinitePathGaugeAcceptedV1" ||
      physicalGauge["Status"] =!=
        "CF303Block25PhysicalGaugeAcceptedV1" ||
      pathGauge["TargetRows"] =!= originalTransfer["Rows"] ||
      pathGauge["SourceRows"] =!= sourceArtifact["OriginalRows"],
    Return[<|"Status" -> "CF303FinitePathGaugeAdapterInputInvalidV1"|>]];
  syntheticTransfer = cf303BuildPathGaugeSyntheticTransfer[
    originalTransfer, pathGauge, eps];
  If[syntheticTransfer["Status"] =!=
      "CF303Block25GeneralEllipticTransferAcceptedV1",
    Return[syntheticTransfer]];
  gOperator = cf303BuildLazyFinalEllipticOperator[sourceArtifact,
    syntheticTransfer, eps, variable, epsilonOrders];
  If[gOperator["Status"] =!=
      "CF303Final45LazyEllipticOperatorAcceptedV1",
    Return[gOperator]];
  hByOrder = cf303PathGaugeCompileH[pathGauge, variable];
  physicalByOrder = cf303PathGaugeCompilePhysicalGauge[physicalGauge,
    Lookup[pathGauge, "Variable", u], variable];
  status = If[Sort[Keys[hByOrder]] === Range @@ pathGauge["Window"] &&
      Sort[Keys[physicalByOrder]] === physicalGauge["Orders"],
    "CF303FinitePathGaugeAdapterAcceptedV1",
    "CF303FinitePathGaugeAdapterFailedV1"];

  <|"Status" -> status,
    "Route" -> "FinitePathGaugeLazyWeightedChen",
    "GOperator" -> gOperator,
    "SyntheticTransfer" -> syntheticTransfer,
    "SourceArtifact" -> sourceArtifact,
    "SourceRows" -> pathGauge["SourceRows"],
    "TargetRows" -> pathGauge["TargetRows"],
    "BoundaryColumns" -> gOperator["BoundaryColumns"],
    "HByOrderPairs" -> hByOrder,
    "HOrders" -> Sort[Keys[hByOrder]],
    "PhysicalGaugeByOrderPairs" -> physicalByOrder,
    "PhysicalGaugeOrders" -> Sort[Keys[physicalByOrder]],
    "Curve" -> (pathGauge["Curve"] /.
      Lookup[pathGauge, "Variable", u] -> variable),
    "Variable" -> variable,
    "PairConvention" -> "{A,B} represents A+B CF303Y[u]",
    "CanonicalRelation" -> "F25=G25+H.L",
    "PhysicalRelation" -> "I25=T25.F25",
    "BoundaryConvention" ->
      "H(basePoint)=0, so G25 and F25 use the same canonical boundary constants"|>
];

(* Exact coefficient pair of one internal word in the original canonical
   F25.  G supplies the rational part.  A source-only word additionally gets
   H_k.L with k=order-boundaryOrder-wordLength. *)
cf303PathGaugeCanonicalWordCoefficient[adapter_Association,
    word_List, boundaryOrder_Integer, order_Integer] := Module[
  {operator = adapter["GOperator"], source, sourceN,
   boundaryDimension, sourceLetterCount, gCoefficient, result,
   hOrder, hPair, sourceCoefficient, sparseRules, paddedSource},
  source = adapter["SourceArtifact", "Operator"];
  sourceN = operator["SourceN"];
  boundaryDimension = Length[operator["BoundaryColumns"]];
  sourceLetterCount = operator["SourceLetterCount"];
  gCoefficient = cf303FinalEllipticWordCoefficient[operator, word,
    boundaryOrder, order];
  result = {gCoefficient,
    SparseArray[{}, {Length[adapter["TargetRows"]], boundaryDimension}]};

  hOrder = order - boundaryOrder - Length[word];
  If[KeyExistsQ[adapter["HByOrderPairs"], hOrder] &&
      AllTrue[word, 1 <= # <= sourceLetterCount &],
    sourceCoefficient =
      FeynFacet`Private`masterTransportCanonicalChenWordCoefficient[
        source, word, boundaryOrder, boundaryOrder + Length[word], All];
    If[cf303PathGaugeSparseNonzeroQ[sourceCoefficient],
      sparseRules = Select[ArrayRules[sourceCoefficient],
        MatchQ[First[#], {_Integer, _Integer}] &];
      paddedSource = SparseArray[sparseRules,
        {sourceN, boundaryDimension}];
      hPair = adapter["HByOrderPairs", hOrder];
      result = cf303PathGaugePairAdd[result,
        {hPair[[1]] . paddedSource, hPair[[2]] . paddedSource}]]];
  result
];

(* The physical gauge is an endpoint matrix, so it changes epsilon order but
   never changes the internal word. *)
cf303PathGaugePhysicalWordCoefficient[adapter_Association,
    word_List, boundaryOrder_Integer, order_Integer] := Module[
  {dimensions = {Length[adapter["TargetRows"]],
      Length[adapter["BoundaryColumns"]]}, result, gaugeOrder,
   canonicalPair, contribution},
  result = {SparseArray[{}, dimensions], SparseArray[{}, dimensions]};
  Do[
    canonicalPair = cf303PathGaugeCanonicalWordCoefficient[adapter,
      word, boundaryOrder, order - gaugeOrder];
    If[cf303PathGaugePairNonzeroQ[canonicalPair],
      contribution = cf303PathGaugePairLeftMultiply[
        adapter["PhysicalGaugeByOrderPairs", gaugeOrder],
        canonicalPair, adapter["Curve"]];
      result = cf303PathGaugePairAdd[result, contribution]],
    {gaugeOrder, adapter["PhysicalGaugeOrders"]}];
  result
];

Options[cf303PathGaugeCanonicalCoefficientRecords] = {
  "MaxInternalWords" -> 10000
};

cf303PathGaugeCanonicalCoefficientRecords[adapter_Association,
    order_Integer, OptionsPattern[]] := Module[
  {cap = OptionValue["MaxInternalWords"], operator, source,
   sourceBoundaryOrders, sourceLetterCount, gRecords,
   candidates = <||>, addCandidate, hOrder, hPair, boundaryOrder,
   depth, tailsR, tailsY, tails, records, coefficientPair},
  operator = adapter["GOperator"];
  source = adapter["SourceArtifact", "Operator"];
  sourceBoundaryOrders = Keys[source["BoundarySelectors"]];
  sourceLetterCount = operator["SourceLetterCount"];
  addCandidate[q_, word_] := Module[{key = {q, word}},
    candidates[key] = True;
    If[Length[candidates] > cap,
      Throw[<|"Status" -> "LazyExpansionRequired",
        "Stage" -> "CanonicalPathGaugeWords", "Order" -> order,
        "CandidateCount" -> Length[candidates], "Cap" -> cap|>]]];

  records = Catch[
    If[operator["TargetLow"] <= order <= operator["TargetTop"],
      gRecords = cf303FinalEllipticCoefficientRecords[operator, order,
        "MaxInternalWords" -> cap];
      If[gRecords["Status"] =!= "OK", Throw[gRecords]];
      Scan[addCandidate[#["BoundaryOrder"], #["InternalWord"]] &,
        gRecords["Records"]]];

    Do[
      hPair = adapter["HByOrderPairs", hOrder];
      Do[
        depth = order - hOrder - boundaryOrder;
        If[depth < 0, Continue[]];
        tailsR = If[cf303PathGaugeSparseNonzeroQ[hPair[[1]]],
          cf303FinalSourceReachableTails[source, hPair[[1]],
            boundaryOrder, depth, cap], {}];
        If[AssociationQ[tailsR], Throw[tailsR]];
        tailsY = If[cf303PathGaugeSparseNonzeroQ[hPair[[2]]],
          cf303FinalSourceReachableTails[source, hPair[[2]],
            boundaryOrder, depth, cap], {}];
        If[AssociationQ[tailsY], Throw[tailsY]];
        tails = DeleteDuplicates[Join[tailsR, tailsY]];
        Scan[addCandidate[boundaryOrder, #] &, tails],
        {boundaryOrder, sourceBoundaryOrders}],
      {hOrder, adapter["HOrders"]}];

    records = Reap[Do[
      coefficientPair = cf303PathGaugeCanonicalWordCoefficient[adapter,
        key[[2]], key[[1]], order];
      If[cf303PathGaugePairNonzeroQ[coefficientPair],
        Sow[<|"BoundaryOrder" -> key[[1]],
          "InternalWord" -> key[[2]],
          "CoefficientPair" -> coefficientPair|>]],
      {key, Keys[candidates]}]][[2]];
    records = If[records === {}, {}, First[records]];
    <|"Status" -> "OK", "Representation" -> "CanonicalF25",
      "Order" -> order, "Records" -> records,
      "InternalWordCount" -> Length[records]|>];
  records
];

Options[cf303PathGaugePhysicalCoefficientRecords] = {
  "MaxInternalWords" -> 10000
};

cf303PathGaugePhysicalCoefficientRecords[adapter_Association,
    order_Integer, OptionsPattern[]] := Module[
  {cap = OptionValue["MaxInternalWords"], candidates = <||>,
   addCandidate, gaugeOrder, canonicalRecords, records, coefficientPair},
  addCandidate[q_, word_] := Module[{key = {q, word}},
    candidates[key] = True;
    If[Length[candidates] > cap,
      Throw[<|"Status" -> "LazyExpansionRequired",
        "Stage" -> "PhysicalPathGaugeWords", "Order" -> order,
        "CandidateCount" -> Length[candidates], "Cap" -> cap|>]]];
  records = Catch[
    Do[
      canonicalRecords = cf303PathGaugeCanonicalCoefficientRecords[
        adapter, order - gaugeOrder, "MaxInternalWords" -> cap];
      If[canonicalRecords["Status"] =!= "OK", Throw[canonicalRecords]];
      Scan[addCandidate[#["BoundaryOrder"], #["InternalWord"]] &,
        canonicalRecords["Records"]],
      {gaugeOrder, adapter["PhysicalGaugeOrders"]}];
    records = Reap[Do[
      coefficientPair = cf303PathGaugePhysicalWordCoefficient[adapter,
        key[[2]], key[[1]], order];
      If[cf303PathGaugePairNonzeroQ[coefficientPair],
        Sow[<|"BoundaryOrder" -> key[[1]],
          "InternalWord" -> key[[2]],
          "CoefficientPair" -> coefficientPair|>]],
      {key, Keys[candidates]}]][[2]];
    records = If[records === {}, {}, First[records]];
    <|"Status" -> "OK", "Representation" -> "PhysicalI25",
      "Order" -> order, "Records" -> records,
      "InternalWordCount" -> Length[records]|>];
  records
];

Options[cf303PathGaugeMaterializeRecords] = {
  "MaxPhysicalTerms" -> 50000
};

cf303PathGaugeMaterializeRecords[adapter_Association,
    records_Association, variable_Symbol, OptionsPattern[]] := Module[
  {cap = OptionValue["MaxPhysicalTerms"], operator,
   boundaryConstants, total, termCount = 0, pair, coefficientR,
   coefficientY, physical, wordFactor},
  If[records["Status"] =!= "OK", Return[records]];
  operator = adapter["GOperator"];
  boundaryConstants = (CF303BoundaryConstant @@ #) & /@
    operator["BoundaryColumns"];
  total = ConstantArray[0, Length[adapter["TargetRows"]]];
  Do[
    pair = record["CoefficientPair"];
    coefficientR = Normal[pair[[1]]] . boundaryConstants;
    coefficientY = Normal[pair[[2]]] . boundaryConstants;
    physical = cf303FinalEllipticPhysicalWordTerms[operator,
      record["InternalWord"]];
    termCount += Length[physical];
    If[termCount > cap,
      Return[<|"Status" -> "LazyExpansionRequired",
        "Stage" -> "PathGaugePhysicalWords",
        "Representation" -> records["Representation"],
        "Order" -> records["Order"],
        "PhysicalTermCount" -> termCount, "Cap" -> cap|>]];
    Do[
      wordFactor = If[item[[2]] === {}, 1,
        CF303CurveWord[item[[2]], variable]];
      total += item[[1]] (coefficientR +
          coefficientY CF303Y[variable]) wordFactor,
      {item, physical}],
    {record, records["Records"]}];
  <|"Status" -> "OK", "Representation" -> records["Representation"],
    "Order" -> records["Order"],
    "InternalWordCount" -> records["InternalWordCount"],
    "PhysicalTermCount" -> termCount,
    "Rows" -> adapter["TargetRows"], "Expression" -> total,
    "PairConvention" -> "CF303Y[u]^2=Curve",
    "BoundaryConvention" -> adapter["BoundaryConvention"],
    "WordConvention" ->
      "CF303CurveWord[{omega1,...,omegak},z] is the base-point iterated integral on Y^2=P4"|>
];

Options[cf303PathGaugeMaterializeCanonicalCoefficient] = {
  "MaxInternalWords" -> 10000, "MaxPhysicalTerms" -> 50000
};

cf303PathGaugeMaterializeCanonicalCoefficient[adapter_Association,
    order_Integer, variable_Symbol, OptionsPattern[]] := Module[{records},
  records = cf303PathGaugeCanonicalCoefficientRecords[adapter, order,
    "MaxInternalWords" -> OptionValue["MaxInternalWords"]];
  cf303PathGaugeMaterializeRecords[adapter, records, variable,
    "MaxPhysicalTerms" -> OptionValue["MaxPhysicalTerms"]]
];

Options[cf303PathGaugeMaterializePhysicalCoefficient] = {
  "MaxInternalWords" -> 10000, "MaxPhysicalTerms" -> 50000
};

cf303PathGaugeMaterializePhysicalCoefficient[adapter_Association,
    order_Integer, variable_Symbol, OptionsPattern[]] := Module[{records},
  records = cf303PathGaugePhysicalCoefficientRecords[adapter, order,
    "MaxInternalWords" -> OptionValue["MaxInternalWords"]];
  cf303PathGaugeMaterializeRecords[adapter, records, variable,
    "MaxPhysicalTerms" -> OptionValue["MaxPhysicalTerms"]]
];
