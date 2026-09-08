(* Exact, demand-pruned coefficient accessors for the preserved CF303
   normal/bulk lazy operator.  This is a local family adapter: it does not
   install definitions in FeynFacet`Private` and it does not build a second
   differential-equation solver. *)

ClearAll[
  cf303NormalSparseNonzeroQ,
  cf303NormalCanonicalChenWordCoefficient,
  cf303NormalFinalWordCoefficient,
  cf303NormalSourceReachableTails,
  cf303NormalFinalCoefficientRecords,
  cf303NormalPairAdd,
  cf303NormalPairLeftMultiply,
  cf303NormalCanonicalWordCoefficient,
  cf303NormalPhysicalWordCoefficient,
  cf303NormalCanonicalCoefficientRecords,
  cf303NormalPhysicalCoefficientRecords
];

cf303NormalSparseNonzeroQ[array_] :=
  Length[SparseArray[array]["NonzeroPositions"]] > 0;

cf303NormalCanonicalChenWordCoefficient[operator_Association,
    word_List, boundaryOrder_Integer, order_Integer,
    rows_: All] := Module[
  {n, boundaryDimension, selector, coefficient, active, mask},
  n = operator["N"];
  boundaryDimension = Length[operator["BoundaryColumns"]];
  If[Length[word] =!= order - boundaryOrder,
    Return[SparseArray[{}, {If[rows === All, n, Length[rows]],
      boundaryDimension}]]];
  selector = Lookup[operator["BoundarySelectors"], boundaryOrder, None];
  If[selector === None,
    Return[SparseArray[{}, {If[rows === All, n, Length[rows]],
      boundaryDimension}]]];
  coefficient = Fold[
    operator["Residues"][[#2]] . #1 &, selector, Reverse[word]];
  active = Lookup[operator["ActiveRowsByOrder"], order, {}];
  mask = SparseArray[({#, #} -> 1) & /@ active, {n, n}];
  coefficient = mask . coefficient;
  If[rows === All, coefficient, coefficient[[rows, All]]]
];

cf303NormalFinalWordCoefficient[operator_Association, word_List,
    boundaryOrder_Integer, order_Integer] := Module[
  {source, sourceN, boundaryDimension, diagonalResidues, diagonalIDs,
   offResidues, sourceLetterCount, result, targetSelector, prefix,
   incoming, tail, epsilonOrder, incomingResidue, sourceOrder,
   sourceCoefficient, paddedSource, prefixProduct, contribution,
   split, sparseRules},
  source = operator["SourceArtifact", "Operator"];
  sourceN = operator["SourceN"];
  boundaryDimension = Length[operator["BoundaryColumns"]];
  diagonalResidues = operator["DiagonalResidues"];
  diagonalIDs = operator["DiagonalLetterIDs"];
  offResidues = operator["OffDiagonalResidues"];
  sourceLetterCount = operator["SourceLetterCount"];
  result = SparseArray[{}, {2, boundaryDimension}];
  If[order < operator["TargetLow"] || order > operator["TargetTop"],
    Return[result]];
  If[order - boundaryOrder === Length[word] &&
      AllTrue[word, MemberQ[diagonalIDs, #] &],
    targetSelector = Lookup[operator["TargetBoundarySelectors"],
      boundaryOrder, None];
    If[targetSelector =!= None,
      result += Fold[diagonalResidues[#2] . #1 &,
        targetSelector, Reverse[word]]]];
  epsilonOrder = order - boundaryOrder - (Length[word] - 1);
  Do[
    prefix = Take[word, split - 1];
    incoming = word[[split]];
    tail = Drop[word, split];
    If[! AllTrue[prefix, MemberQ[diagonalIDs, #] &] ||
        ! AllTrue[tail, 1 <= # <= sourceLetterCount &], Continue[]];
    incomingResidue = Lookup[offResidues,
      Key[{epsilonOrder, incoming}], None];
    If[incomingResidue === None, Continue[]];
    sourceOrder = boundaryOrder + Length[tail];
    sourceCoefficient = cf303NormalCanonicalChenWordCoefficient[
      source, tail, boundaryOrder, sourceOrder, All];
    If[! cf303NormalSparseNonzeroQ[sourceCoefficient], Continue[]];
    sparseRules = Select[ArrayRules[sourceCoefficient],
      MatchQ[First[#], {_Integer, _Integer}] &];
    paddedSource = SparseArray[sparseRules, {sourceN, boundaryDimension}];
    prefixProduct = Fold[diagonalResidues[#2] . #1 &,
      SparseArray[IdentityMatrix[2]], Reverse[prefix]];
    contribution = prefixProduct . incomingResidue . paddedSource;
    If[cf303NormalSparseNonzeroQ[contribution], result += contribution],
    {split, Length[word]}];
  SparseArray[result]
];

cf303NormalSourceReachableTails[source_Association, left_SparseArray,
    boundaryOrder_Integer, depth_Integer, cap_Integer] := Module[
  {selector, states, next, product, final},
  selector = Lookup[source["BoundarySelectors"], boundaryOrder, None];
  If[selector === None, Return[{}]];
  states = {{{}, left}};
  Do[
    next = Reap[Do[
        product = state[[2]] . source["Residues"][[letter]];
        If[cf303NormalSparseNonzeroQ[product],
          Sow[{Append[state[[1]], letter], product}]],
        {state, states}, {letter, Length[source["Letters"]]}]][[2]];
    states = If[next === {}, {}, First[next]];
    If[Length[states] > cap,
      Return[<|"Status" -> "LazyExpansionRequired",
        "Stage" -> "SourceTail", "Depth" -> step,
        "CandidateCount" -> Length[states], "Cap" -> cap|>]],
    {step, depth}];
  final = Select[states,
    cf303NormalSparseNonzeroQ[#[[2]] . selector] &];
  If[final === {}, {}, final[[All, 1]]]
];

cf303NormalFinalCoefficientRecords[operator_Association, order_Integer,
    cap_Integer] := Module[
  {source, sourceBoundaryOrders, diagonalIDs, offResidues,
   candidates = <||>, addCandidate, targetBoundaryOrders, q, length,
   epsilonOrder, incomingID, incomingResidue, remainingLength,
   sourceDepth, tails, prefixes, records, coefficient},
  source = operator["SourceArtifact", "Operator"];
  sourceBoundaryOrders = Keys[source["BoundarySelectors"]];
  diagonalIDs = operator["DiagonalLetterIDs"];
  offResidues = operator["OffDiagonalResidues"];
  addCandidate[boundaryOrder_, word_] := Module[{key = {boundaryOrder, word}},
    candidates[key] = True;
    If[Length[candidates] > cap,
      Throw[<|"Status" -> "LazyExpansionRequired",
        "Stage" -> "FinalWords", "Order" -> order,
        "CandidateCount" -> Length[candidates], "Cap" -> cap|>]]];
  records = Catch[
    targetBoundaryOrders = Keys[operator["TargetBoundarySelectors"]];
    Do[
      length = order - q;
      If[length >= 0,
        Scan[addCandidate[q, #] &, Tuples[diagonalIDs, length]]],
      {q, targetBoundaryOrders}];
    KeyValueMap[Function[{residueKey, residue},
      epsilonOrder = residueKey[[1]];
      incomingID = residueKey[[2]];
      incomingResidue = residue;
      Do[
        remainingLength = order - q - epsilonOrder;
        If[remainingLength >= 0,
          Do[
            sourceDepth = remainingLength - diagonalLength;
            tails = cf303NormalSourceReachableTails[source,
              incomingResidue, q, sourceDepth, cap];
            If[AssociationQ[tails], Throw[tails]];
            prefixes = Tuples[diagonalIDs, diagonalLength];
            Do[addCandidate[q, Join[prefix, {incomingID}, tail]],
              {prefix, prefixes}, {tail, tails}],
            {diagonalLength, 0, remainingLength}]],
        {q, sourceBoundaryOrders}]], offResidues];
    records = Reap[Do[
        coefficient = cf303NormalFinalWordCoefficient[operator,
          key[[2]], key[[1]], order];
        If[cf303NormalSparseNonzeroQ[coefficient],
          Sow[<|"BoundaryOrder" -> key[[1]],
            "InternalWord" -> key[[2]],
            "Coefficient" -> coefficient|>]],
        {key, Keys[candidates]}]][[2]];
    records = If[records === {}, {}, First[records]];
    <|"Status" -> "OK", "Order" -> order, "Records" -> records,
      "InternalWordCount" -> Length[records]|>];
  records
];

cf303NormalPairAdd[{leftR_, leftY_}, {rightR_, rightY_}] :=
  {SparseArray[leftR + rightR], SparseArray[leftY + rightY]};

cf303NormalPairLeftMultiply[{leftR_, leftY_}, {rightR_, rightY_},
    curve_] :=
  {SparseArray[leftR . rightR + curve leftY . rightY],
   SparseArray[leftR . rightY + leftY . rightR]};

cf303NormalCanonicalWordCoefficient[adapter_Association, word_List,
    boundaryOrder_Integer, order_Integer] := Module[
  {operator, source, sourceN, boundaryDimension, sourceLetterCount,
   gCoefficient, result, hOrder, hPair, sourceCoefficient,
   sparseRules, paddedSource},
  operator = adapter["GOperator"];
  source = adapter["SourceArtifact", "Operator"];
  sourceN = operator["SourceN"];
  boundaryDimension = Length[operator["BoundaryColumns"]];
  sourceLetterCount = operator["SourceLetterCount"];
  gCoefficient = cf303NormalFinalWordCoefficient[operator, word,
    boundaryOrder, order];
  result = {gCoefficient,
    SparseArray[{}, {Length[adapter["TargetRows"]], boundaryDimension}]};
  hOrder = order - boundaryOrder - Length[word];
  If[KeyExistsQ[adapter["HByOrderPairs"], hOrder] &&
      AllTrue[word, 1 <= # <= sourceLetterCount &],
    sourceCoefficient = cf303NormalCanonicalChenWordCoefficient[
      source, word, boundaryOrder, boundaryOrder + Length[word], All];
    If[cf303NormalSparseNonzeroQ[sourceCoefficient],
      sparseRules = Select[ArrayRules[sourceCoefficient],
        MatchQ[First[#], {_Integer, _Integer}] &];
      paddedSource = SparseArray[sparseRules, {sourceN, boundaryDimension}];
      hPair = adapter["HByOrderPairs", hOrder];
      result = cf303NormalPairAdd[result,
        {hPair[[1]] . paddedSource, hPair[[2]] . paddedSource}]]];
  result
];

cf303NormalPhysicalWordCoefficient[adapter_Association, word_List,
    boundaryOrder_Integer, order_Integer] := Module[
  {dimensions, result, canonicalPair, contribution},
  dimensions = {Length[adapter["TargetRows"]],
    Length[adapter["BoundaryColumns"]]};
  result = {SparseArray[{}, dimensions], SparseArray[{}, dimensions]};
  Do[
    canonicalPair = cf303NormalCanonicalWordCoefficient[adapter,
      word, boundaryOrder, order - gaugeOrder];
    If[cf303NormalSparseNonzeroQ[First[canonicalPair]] ||
        cf303NormalSparseNonzeroQ[Last[canonicalPair]],
      contribution = cf303NormalPairLeftMultiply[
        adapter["PhysicalGaugeByOrderPairs", gaugeOrder],
        canonicalPair, adapter["Curve"]];
      result = cf303NormalPairAdd[result, contribution]],
    {gaugeOrder, adapter["PhysicalGaugeOrders"]}];
  result
];

cf303NormalCanonicalCoefficientRecords[adapter_Association, order_Integer,
    cap_Integer] := Module[
  {operator, source, sourceBoundaryOrders, sourceLetterCount,
   gRecords, candidates = <||>, addCandidate, hPair, depth,
   tailsR, tailsY, tails, records, coefficientPair},
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
      gRecords = cf303NormalFinalCoefficientRecords[operator, order, cap];
      If[gRecords["Status"] =!= "OK", Throw[gRecords]];
      Scan[addCandidate[#["BoundaryOrder"], #["InternalWord"]] &,
        gRecords["Records"]]];
    Do[
      hPair = adapter["HByOrderPairs", hOrder];
      Do[
        depth = order - hOrder - boundaryOrder;
        If[depth >= 0,
          tailsR = If[cf303NormalSparseNonzeroQ[hPair[[1]]],
            cf303NormalSourceReachableTails[source, hPair[[1]],
              boundaryOrder, depth, cap], {}];
          If[AssociationQ[tailsR], Throw[tailsR]];
          tailsY = If[cf303NormalSparseNonzeroQ[hPair[[2]]],
            cf303NormalSourceReachableTails[source, hPair[[2]],
              boundaryOrder, depth, cap], {}];
          If[AssociationQ[tailsY], Throw[tailsY]];
          tails = DeleteDuplicates[Join[tailsR, tailsY]];
          Scan[addCandidate[boundaryOrder, #] &, tails]],
        {boundaryOrder, sourceBoundaryOrders}],
      {hOrder, adapter["HOrders"]}];
    records = Reap[Do[
        coefficientPair = cf303NormalCanonicalWordCoefficient[adapter,
          key[[2]], key[[1]], order];
        If[cf303NormalSparseNonzeroQ[First[coefficientPair]] ||
            cf303NormalSparseNonzeroQ[Last[coefficientPair]],
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

cf303NormalPhysicalCoefficientRecords[adapter_Association, order_Integer,
    cap_Integer] := Module[
  {candidates = <||>, addCandidate, canonicalRecords, records,
   coefficientPair},
  addCandidate[q_, word_] := Module[{key = {q, word}},
    candidates[key] = True;
    If[Length[candidates] > cap,
      Throw[<|"Status" -> "LazyExpansionRequired",
        "Stage" -> "PhysicalPathGaugeWords", "Order" -> order,
        "CandidateCount" -> Length[candidates], "Cap" -> cap|>]]];
  records = Catch[
    Do[
      canonicalRecords = cf303NormalCanonicalCoefficientRecords[
        adapter, order - gaugeOrder, cap];
      If[canonicalRecords["Status"] =!= "OK", Throw[canonicalRecords]];
      Scan[addCandidate[#["BoundaryOrder"], #["InternalWord"]] &,
        canonicalRecords["Records"]],
      {gaugeOrder, adapter["PhysicalGaugeOrders"]}];
    records = Reap[Do[
        coefficientPair = cf303NormalPhysicalWordCoefficient[adapter,
          key[[2]], key[[1]], order];
        If[cf303NormalSparseNonzeroQ[First[coefficientPair]] ||
            cf303NormalSparseNonzeroQ[Last[coefficientPair]],
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
