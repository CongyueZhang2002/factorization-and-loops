(* Lazy final-layer transport for CF303.

   The first 43 masters have an epsilon-linear Chen operator.  The final
   two-master block is also dlog on the quartic curve, but its incoming
   residues are rational functions of epsilon.  A word reaching the final
   block therefore has one of two forms:

     D ... D                                  (target boundary),
     D ... D B_r S ... S                      (source boundary),

   where D is a final-block diagonal letter, B_r is exactly one incoming
   letter at epsilon order r, and S is a source-operator letter.  The
   routines below evaluate the corresponding sparse coefficient without
   expanding the union alphabet or enumerating unrelated words. *)

ClearAll[
  cf303BuildLazyFinalEllipticOperator,
  cf303FinalEllipticWordCoefficient,
  cf303FinalEllipticWordLabels,
  cf303FinalEllipticPhysicalWordTerms,
  cf303FinalStandardLetterExpansion,
  cf303FinalEllipticCoefficientRecords,
  cf303FinalEllipticMaterializeCoefficient,
  cf303FinalSourceReachableTails,
  CF303BoundaryConstant,
  CF303CurveWord,
  CF303Root
];

cf303BuildLazyFinalEllipticOperator[sourceArtifact_Association,
    transfer_Association, eps_Symbol, variable_Symbol,
    epsilonOrders : {_Integer, _Integer}] := Module[
  {source, sourceRows, sourceN, sourceBoundaryCount, targetRows,
   targetDimension, sourceLocation, sourceLetterCount, offRecords,
   offLabels, offLabelIndex, offRules = <||>, offResidues,
   diagonalLabels, diagonalIDs, diagonalResidues,
   targetBlockIndex, targetBoundaryColumns, boundaryColumns,
   targetSelectors, updateRule, coefficientSeries, coefficient,
   target, row, column, label, letterID, order, key, coordinate,
   coordinateRules, sourceCompositeDefinitions = <||>,
   targetCompositeDefinitions, layerArtifact, layerLabels,
   layerDefinitions, layerNumber, definitionLabels, status,
   boundaryProbe, diagonalProbe},

  source = sourceArtifact["Operator"];
  sourceRows = sourceArtifact["OriginalRows"];
  sourceN = source["N"];
  sourceBoundaryCount = Length[source["BoundaryColumns"]];
  targetRows = transfer["Rows"];
  targetDimension = Length[targetRows];
  If[sourceArtifact["Status"] =!=
      "CF303HybridEllipticOperatorAcceptedV1" ||
      transfer["Status"] =!=
        "CF303Block25GeneralEllipticTransferAcceptedV1" ||
      targetDimension =!= 2,
    Return[<|"Status" -> "CF303FinalEllipticInputInvalidV1"|>]];

  sourceLocation = AssociationThread[sourceRows, Range[sourceN]];
  sourceLetterCount = Length[source["Letters"]];
  offRecords = Select[transfer["EntryRecords"],
    ! MemberQ[targetRows, #[[1, 2]]] &];
  offLabels = DeleteDuplicates[
    Flatten[offRecords[[All, 4, All, 2, 1]], 1] /. u -> variable];
  offLabelIndex = AssociationThread[offLabels,
    Range[sourceLetterCount + 1,
      sourceLetterCount + Length[offLabels]]];

  updateRule[residueKey_, position_, value_] := Module[
    {rules = Lookup[offRules, Key[residueKey], <||>], old},
    old = Lookup[rules, Key[position], 0];
    rules[position] = old + value;
    offRules[residueKey] = rules];

  Do[
    target = record[[1]];
    row = First@FirstPosition[targetRows, target[[1]]];
    column = Lookup[sourceLocation, target[[2]], Missing["SourceMaster"]];
    If[MissingQ[column],
      Return[<|"Status" -> "CF303FinalEllipticSourceMapFailedV1",
        "Target" -> target|>]];
    Do[
      coefficientSeries = Normal@Series[term[[1]],
        {eps, 0, epsilonOrders[[2]]}];
      label = term[[2, 1]] /. u -> variable;
      letterID = Lookup[offLabelIndex, Key[label]];
      Do[
        coefficient = Coefficient[coefficientSeries, eps, order];
        If[! TrueQ[coefficient === 0],
          updateRule[{order, letterID}, {row, column}, coefficient]],
        {order, epsilonOrders[[1]], epsilonOrders[[2]]}],
      {term, record[[4]]}],
    {record, offRecords}];
  offResidues = Association@KeyValueMap[
    Function[{residueKey, rules}, residueKey -> SparseArray[
      Normal[rules], {targetDimension, sourceN}]], offRules];

  diagonalLabels = Table[CompositeEllipticLetter[25, generator],
    {generator, Length[transfer["ConstantGeneratorMatrices"]]}];
  diagonalIDs = Range[sourceLetterCount + Length[offLabels] + 1,
    sourceLetterCount + Length[offLabels] + Length[diagonalLabels]];
  diagonalResidues = AssociationThread[diagonalIDs,
    SparseArray /@ transfer["ConstantGeneratorMatrices"]];

  targetBlockIndex = Length[source["Dimensions"]] + 1;
  targetBoundaryColumns = Flatten[Table[
    {targetBlockIndex, q, component},
    {q, 0, 2}, {component, targetDimension}], 1];
  boundaryColumns = Join[source["BoundaryColumns"],
    targetBoundaryColumns];
  targetSelectors = Association@Table[q -> SparseArray[
    Table[{component, sourceBoundaryCount +
        (q - 0) targetDimension + component} -> 1,
      {component, targetDimension}],
    {targetDimension, Length[boundaryColumns]}], {q, 0, 2}];

  (* Preserve the physical standard-letter expansion of every compressed
     diagonal letter, including those already present in the source deck. *)
  Do[
    layerNumber = summary["Block"];
    layerArtifact = Get[summary["ProviderFile"]];
    layerLabels = layerArtifact["Letters"] /. u -> variable;
    layerDefinitions = If[KeyExistsQ[layerArtifact,
      "DiagonalCompressed"],
      layerArtifact["DiagonalCompressed", "ConstantCompositeKernels"],
      layerArtifact["ConstantCompositeKernels"]];
    Do[
      sourceCompositeDefinitions[
        CompositeEllipticLetter[layerNumber, generator]] =
          ({#[[1]], layerLabels[[#[[2]]]]} &) /@
            layerDefinitions[[generator]],
      {generator, Length[layerDefinitions]}],
    {summary, sourceArtifact["LayerSummaries"]}];
  targetCompositeDefinitions = Association@Table[
    diagonalLabels[[generator]] ->
      (({#[[1]], transfer["DiagonalLetters"][[#[[2]]]] /.
            u -> variable} &) /@
        transfer["ConstantCompositeKernels"][[generator]]),
    {generator, Length[diagonalLabels]}];

  boundaryProbe = Lookup[targetSelectors, 0, Missing[]];
  diagonalProbe = If[diagonalIDs === {}, SparseArray[{}, {2, 2}],
    diagonalResidues[First[diagonalIDs]]];
  status = If[
    Dimensions[boundaryProbe] === {targetDimension,
        Length[boundaryColumns]} &&
      FeynFacet`Private`masterTransportCWNonzeroSparseQ[boundaryProbe] &&
      FeynFacet`Private`masterTransportCWNonzeroSparseQ[diagonalProbe],
    "CF303Final45LazyEllipticOperatorAcceptedV1",
    "CF303Final45LazyEllipticOperatorFailedV1"];

  <|"Status" -> status,
    "Route" -> "OneIncomingEdgeLazyWeightedChen",
    "SourceArtifact" -> sourceArtifact,
    "SourceRows" -> sourceRows,
    "TargetRows" -> targetRows,
    "Rows" -> Join[sourceRows, targetRows],
    "SourceN" -> sourceN,
    "N" -> sourceN + targetDimension,
    "SourceLetterCount" -> sourceLetterCount,
    "OffDiagonalLabels" -> offLabels,
    "OffDiagonalResidues" -> offResidues,
    "OffDiagonalEpsilonOrders" -> epsilonOrders,
    "DiagonalLabels" -> diagonalLabels,
    "DiagonalLetterIDs" -> diagonalIDs,
    "DiagonalResidues" -> diagonalResidues,
    "Letters" -> Join[source["Letters"], offLabels, diagonalLabels],
    "Variable" -> variable,
    "BoundaryColumns" -> boundaryColumns,
    "SourceBoundaryCount" -> sourceBoundaryCount,
    "TargetBoundaryColumns" -> targetBoundaryColumns,
    "TargetBoundarySelectors" -> targetSelectors,
    "TargetLow" -> -4, "TargetTop" -> 2,
    "CompositeDefinitions" -> Join[sourceCompositeDefinitions,
      targetCompositeDefinitions],
    "CoefficientFormula" ->
      "D...D boundary plus D...D B_r S...S with exactly one incoming B_r",
    "TransferProvider" -> transfer|>
];

cf303FinalEllipticWordCoefficient[operator_Association, word_List,
    boundaryOrder_Integer, order_Integer] := Module[
  {sourceArtifact, source, sourceN, sourceBoundaryCount,
   boundaryDimension, diagonalResidues, diagonalIDs, offResidues,
   sourceLetterCount, result, targetSelector, prefix, incoming,
   tail, epsilonOrder, incomingResidue, sourceOrder,
   sourceCoefficient, paddedSource, prefixProduct, contribution,
   split, sparseRules},
  sourceArtifact = operator["SourceArtifact"];
  source = sourceArtifact["Operator"];
  sourceN = operator["SourceN"];
  sourceBoundaryCount = operator["SourceBoundaryCount"];
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
    sourceCoefficient =
      FeynFacet`Private`masterTransportCanonicalChenWordCoefficient[
        source, tail, boundaryOrder, sourceOrder, All];
    If[! FeynFacet`Private`masterTransportCWNonzeroSparseQ[
        sourceCoefficient], Continue[]];
    sparseRules = Select[ArrayRules[sourceCoefficient],
      MatchQ[First[#], {_Integer, _Integer}] &];
    paddedSource = SparseArray[sparseRules,
      {sourceN, boundaryDimension}];
    prefixProduct = Fold[diagonalResidues[#2] . #1 &,
      SparseArray[IdentityMatrix[2]], Reverse[prefix]];
    contribution = prefixProduct . incomingResidue . paddedSource;
    If[FeynFacet`Private`masterTransportCWNonzeroSparseQ[contribution],
      result += contribution],
    {split, Length[word]}];
  SparseArray[result]
];

cf303FinalEllipticWordLabels[operator_Association, word_List] :=
  operator["Letters"][[word]];

(* Root-free factor letters are excellent for construction, but the standard
   paper alphabet uses simple marked points.  Split a square-free polynomial
   factor f into its roots c_k only when a physical word is requested:

     u^i du/f(u)   = Sum_k c_k^i/f'(c_k) du/(u-c_k),
     u^i du/(f Y) = Sum_k c_k^i/(f'(c_k)Y(c_k)) E4Pole(c_k).

   CF303Root[CoefficientList[f,u],k] is inert.  Its first argument contains no
   path variable, so the marked point is syntactically constant under endpoint
   differentiation while avoiding gigantic explicit radicals. *)
cf303FinalStandardLetterExpansion[operator_Association, label_List] :=
  Module[{variable = operator["Variable"], polynomial, coefficients,
    power, degree, root, derivative},
  Which[
    label[[1]] === "GPLFactor",
      polynomial = label[[2]]; power = label[[3]];
      coefficients = CoefficientList[polynomial, variable];
      degree = Length[coefficients] - 1;
      Table[
        root = CF303Root[coefficients, index];
        derivative = Sum[powerIndex coefficients[[powerIndex + 1]]
          root^(powerIndex - 1), {powerIndex, 1, degree}];
        {root^power/derivative, {"GPLPole", root}},
        {index, degree}],
    label[[1]] === "E4Factor",
      polynomial = label[[2]]; power = label[[3]];
      coefficients = CoefficientList[polynomial, variable];
      degree = Length[coefficients] - 1;
      Table[
        root = CF303Root[coefficients, index];
        derivative = Sum[powerIndex coefficients[[powerIndex + 1]]
          root^(powerIndex - 1), {powerIndex, 1, degree}];
        {root^power/(derivative Yc[root]), {"E4Pole", root}},
        {index, degree}],
    True, {{1, label}}
  ]
];

cf303FinalEllipticPhysicalWordTerms[operator_Association,
    word_List] := Module[
  {definitions, labelled, expanded, baseChoices, choices, merged},
  definitions = operator["CompositeDefinitions"];
  labelled = cf303FinalEllipticWordLabels[operator, word];
  expanded = {{1, {}}};
  Do[
    baseChoices = Lookup[definitions, Key[label], {{1, label}}];
    choices = Flatten[Table[
      {base[[1]] standard[[1]], standard[[2]]},
      {base, baseChoices},
      {standard, cf303FinalStandardLetterExpansion[
        operator, base[[2]]]}], 1];
    expanded = Flatten[Table[
      {left[[1]] right[[1]], Append[left[[2]], right[[2]]]},
      {left, expanded}, {right, choices}], 1],
    {label, labelled}];
  merged = Merge[(#[[2]] -> #[[1]]) & /@ expanded, Total];
  ({Last[#], First[#]} &) /@ Normal[merged]
];

cf303FinalSourceReachableTails[source_Association, left_SparseArray,
    boundaryOrder_Integer, depth_Integer, cap_Integer] := Module[
  {selector, states, next, product, final},
  selector = Lookup[source["BoundarySelectors"], boundaryOrder, None];
  If[selector === None, Return[{}]];
  states = {{{}, left}};
  Do[
    next = Reap[
      Do[
        product = state[[2]] . source["Residues"][[letter]];
        If[FeynFacet`Private`masterTransportCWNonzeroSparseQ[product],
          Sow[{Append[state[[1]], letter], product}]],
        {state, states}, {letter, Length[source["Letters"]]}]][[2]];
    states = If[next === {}, {}, First[next]];
    If[Length[states] > cap,
      Return[<|"Status" -> "LazyExpansionRequired",
        "Stage" -> "SourceTail", "Depth" -> step,
        "CandidateCount" -> Length[states], "Cap" -> cap|>]],
    {step, depth}];
  final = Select[states,
    FeynFacet`Private`masterTransportCWNonzeroSparseQ[
      #[[2]] . selector] &];
  final[[All, 1]]
];

Options[cf303FinalEllipticCoefficientRecords] = {
  "MaxInternalWords" -> 10000
};

cf303FinalEllipticCoefficientRecords[operator_Association,
    order_Integer, OptionsPattern[]] := Module[
  {cap, source, sourceBoundaryOrders, diagonalIDs, offResidues,
   candidates = <||>, addCandidate, targetBoundaryOrders, q, length,
   residueKey, epsilonOrder, incomingID, incomingResidue,
   remainingLength, diagonalLength, sourceDepth, tails, prefixes,
   word, records, coefficient},
  cap = OptionValue["MaxInternalWords"];
  source = operator["SourceArtifact", "Operator"];
  sourceBoundaryOrders = Keys[source["BoundarySelectors"]];
  diagonalIDs = operator["DiagonalLetterIDs"];
  offResidues = operator["OffDiagonalResidues"];
  addCandidate[boundaryOrder_, candidateWord_] := Module[{key},
    key = {boundaryOrder, candidateWord};
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
        Do[addCandidate[q, word],
          {word, Tuples[diagonalIDs, length]}]],
      {q, targetBoundaryOrders}];

    Do[
      epsilonOrder = residueKey[[1]];
      incomingID = residueKey[[2]];
      incomingResidue = offResidues[residueKey];
      Do[
        remainingLength = order - q - epsilonOrder;
        If[remainingLength < 0, Continue[]];
        Do[
          sourceDepth = remainingLength - diagonalLength;
          tails = cf303FinalSourceReachableTails[source,
            incomingResidue, q, sourceDepth, cap];
          If[AssociationQ[tails], Throw[tails]];
          prefixes = Tuples[diagonalIDs, diagonalLength];
          Do[addCandidate[q, Join[prefix, {incomingID}, tail]],
            {prefix, prefixes}, {tail, tails}],
          {diagonalLength, 0, remainingLength}],
        {q, sourceBoundaryOrders}],
      {residueKey, Keys[offResidues]}];

    records = Reap[
      Do[
        coefficient = cf303FinalEllipticWordCoefficient[operator,
          key[[2]], key[[1]], order];
        If[FeynFacet`Private`masterTransportCWNonzeroSparseQ[coefficient],
          Sow[<|"BoundaryOrder" -> key[[1]],
            "InternalWord" -> key[[2]],
            "Coefficient" -> coefficient|>]],
        {key, Keys[candidates]}]][[2]];
    records = If[records === {}, {}, First[records]];
    <|"Status" -> "OK", "Order" -> order,
      "Records" -> records, "InternalWordCount" -> Length[records]|>];
  records
];

Options[cf303FinalEllipticMaterializeCoefficient] = {
  "MaxInternalWords" -> 10000,
  "MaxPhysicalTerms" -> 50000
};

cf303FinalEllipticMaterializeCoefficient[operator_Association,
    order_Integer, variable_Symbol,
    OptionsPattern[]] := Module[
  {records, cap, boundaryConstants, total, physical, termCount = 0,
   coefficientVector, wordFactor},
  records = cf303FinalEllipticCoefficientRecords[operator, order,
    "MaxInternalWords" -> OptionValue["MaxInternalWords"]];
  If[records["Status"] =!= "OK", Return[records]];
  cap = OptionValue["MaxPhysicalTerms"];
  boundaryConstants = (CF303BoundaryConstant @@ #) & /@
    operator["BoundaryColumns"];
  total = ConstantArray[0, 2];
  Do[
    coefficientVector = Normal[record["Coefficient"]] .
      boundaryConstants;
    physical = cf303FinalEllipticPhysicalWordTerms[operator,
      record["InternalWord"]];
    termCount += Length[physical];
    If[termCount > cap,
      Return[<|"Status" -> "LazyExpansionRequired",
        "Stage" -> "PhysicalWords", "Order" -> order,
        "PhysicalTermCount" -> termCount, "Cap" -> cap|>]];
    Do[
      wordFactor = If[item[[2]] === {}, 1,
        CF303CurveWord[item[[2]], variable]];
      total += item[[1]] coefficientVector wordFactor,
      {item, physical}],
    {record, records["Records"]}];
  <|"Status" -> "OK", "Order" -> order,
    "InternalWordCount" -> records["InternalWordCount"],
    "PhysicalTermCount" -> termCount,
    "Rows" -> operator["TargetRows"], "Expression" -> total,
    "WordConvention" ->
      "CF303CurveWord[{omega1,...,omegak},z] is the base-point iterated integral on Y^2=P4"|>
];
