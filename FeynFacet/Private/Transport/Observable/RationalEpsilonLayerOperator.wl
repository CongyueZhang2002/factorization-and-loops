(* Lazy word operator for a rational-in-epsilon final layer.

   BuildRationalEpsilonLayerTransport determines the path gauge H and the
   dlog remainder K.  Enumerating every Chen word is unnecessary and becomes
   exponential at the weights needed by hard families.  This module keeps the
   finite operator data and evaluates one requested word by sparse matrix
   products.  It is independent of the letter class: GPL and elliptic letters
   are opaque labels here, so the same operator serves either channel once the
   corresponding residues have been constructed. *)

Clear[BuildRationalEpsilonLayerOperator,
  AcceptedRationalEpsilonLayerOperatorQ,
  RebaseRationalEpsilonLayerOperator,
  RationalEpsilonLayerWordMap,
  RationalEpsilonLayerDemandTerms];

ClearAll[
  rationalLayerOperatorNonzeroQ,
  rationalLayerOperatorBoundaryColumns,
  rationalLayerOperatorFold,
  rationalLayerOperatorRowSelection,
  rationalLayerOperatorRequestedRows,
  rationalLayerOperatorDemandCoveredQ,
  rationalLayerOperatorNonzeroRows,
  rationalLayerOperatorGrow,
  rationalLayerOperatorSelectorColumns
];

rationalLayerOperatorNonzeroQ[m_] :=
  Length[SparseArray[m]["NonzeroPositions"]] > 0;

rationalLayerOperatorBoundaryColumns[selectors_Association] := Module[
  {dimensions = Dimensions /@ Values[selectors]},
  If[dimensions === {} || ! AllTrue[dimensions,
      MatchQ[#, {_Integer, _Integer}] &] ||
      Length[DeleteDuplicates[dimensions[[All, 2]]]] =!= 1,
    Missing["InvalidBoundarySelectors"], First[dimensions][[2]]]
];

rationalLayerOperatorSelectorColumns[selectors_Association,
    rows_Integer] := Module[
  {columns = rationalLayerOperatorBoundaryColumns[selectors]},
  If[MissingQ[columns] || selectors === <||> ||
      ! VectorQ[Keys[selectors], IntegerQ] ||
      ! AllTrue[Values[selectors],
        MatrixQ[#] && Dimensions[#] === {rows, columns} &],
    Missing["InvalidBoundarySelectors"], columns]
];

(* word is outermost first; multiplication starts at the boundary selector,
   hence the reverse traversal. *)
rationalLayerOperatorFold[matrices_Association, tokens_List, seed_] :=
  Fold[Lookup[matrices, Key[#2], Missing["UnknownLetter", #2]] . #1 &,
    seed, Reverse[tokens]];

rationalLayerOperatorRowSelection[matrix_, All] := matrix;
rationalLayerOperatorRowSelection[matrix_, row_Integer] /;
    1 <= row <= Dimensions[matrix][[1]] := matrix[[{row}, All]];
rationalLayerOperatorRowSelection[matrix_, rows_List] /;
    VectorQ[rows, IntegerQ] && DuplicateFreeQ[rows] &&
      AllTrue[rows, 1 <= # <= Dimensions[matrix][[1]] &] :=
  matrix[[rows, All]];
rationalLayerOperatorRowSelection[_, _] := $Failed;

rationalLayerOperatorRequestedRows[dimension_Integer, All] := Range[dimension];
rationalLayerOperatorRequestedRows[dimension_Integer, row_Integer] /;
    1 <= row <= dimension := {row};
rationalLayerOperatorRequestedRows[dimension_Integer, rows_List] /;
    VectorQ[rows, IntegerQ] && DuplicateFreeQ[rows] &&
      AllTrue[rows, 1 <= # <= dimension &] := rows;
rationalLayerOperatorRequestedRows[_, _] := $Failed;

rationalLayerOperatorDemandCoveredQ[operator_Association, order_Integer,
    rows_List] := Module[{pairs = Lookup[operator, "DemandPairs", {}]},
  AllTrue[rows, MemberQ[pairs, {order, #}] &]
];

rationalLayerOperatorNonzeroRows[matrix_] :=
  DeleteDuplicates[SparseArray[matrix]["NonzeroPositions"][[All, 1]]];

rationalLayerOperatorGrow[states_List, tokens_List,
    matrices_Association, maximumStates_] := Module[{next},
  next = Select[Flatten[Table[
      {Append[state[[1]], token], matrices[token] . state[[2]]},
      {state, states}, {token, tokens}], 1],
    rationalLayerOperatorNonzeroQ[#[[2]]] &];
  If[Length[next] > maximumStates,
    <|"Status" -> "RationalLayerStateGrowthCapped",
      "StateCount" -> Length[next], "MaximumStates" -> maximumStates|>,
    next]
];

BuildRationalEpsilonLayerOperator[source_Association, layer_Association,
    transport_Association] := Module[
  {sourceDimension, sourceLetters, sourceResidues, sourceSelectors,
   sourceBoundaryCount, rows, targetDimension, targetSelectors,
   targetBoundaryCount, sharedBoundaryQ, boundaryLayout, diagonal,
   diagonalMatrices, diagonalTokens,
   sourceMatrices, sourceTokens, incoming, incomingMatrices,
   incomingTokens, gauge, gaugeMatrices, gaugeTokens, dimensions, window,
   pathVariable, basePoint, endpoint, curve, boundaryBinding,
   sourceBindingRows, targetBindingRows, boundaryCoordinateKeys,
   operatorSourcePayload, operatorLayerPayload, declaredCurvePointValues,
   basicLayerPayload},

  If[! AcceptedRationalEpsilonLayerTransportQ[transport],
    Return[<|"Status" -> "RationalEpsilonLayerTransportNotAccepted"|>]];

  sourceDimension = Lookup[source, "Dimension", Missing[]];
  sourceLetters = Lookup[source, "Letters", Missing[]];
  sourceResidues = Lookup[source, "Residues", Missing[]];
  sourceSelectors = Lookup[source, "BoundarySelectors", Missing[]];
  If[! IntegerQ[sourceDimension] || sourceDimension < 1 ||
      ! ListQ[sourceLetters] || ! ListQ[sourceResidues] ||
      Length[sourceLetters] =!= Length[sourceResidues] ||
      ! AssociationQ[sourceSelectors],
    Return[<|"Status" -> "RationalLayerSourceOperatorInvalid"|>]];
  sourceBoundaryCount =
    rationalLayerOperatorBoundaryColumns[sourceSelectors];
  If[MissingQ[sourceBoundaryCount] ||
      ! AllTrue[sourceResidues,
        Dimensions[#] === {sourceDimension, sourceDimension} &] ||
      ! AllTrue[Values[sourceSelectors],
        Dimensions[#][[1]] === sourceDimension &],
    Return[<|"Status" -> "RationalLayerSourceOperatorInvalid"|>]];

  rows = Lookup[layer, "Rows", Missing[]];
  targetDimension = If[ListQ[rows], Length[rows], 0];
  diagonal = Lookup[layer, "Diagonal", Missing[]];
  If[targetDimension < 1 || ! ListQ[diagonal] ||
      ! AllTrue[diagonal,
        MatchQ[#, {_List, _?MatrixQ}] &&
          Dimensions[#[[2]]] === {targetDimension, targetDimension} &],
    Return[<|"Status" -> "RationalLayerDiagonalOperatorInvalid"|>]];

  operatorSourcePayload = Lookup[transport, "OperatorSource", None];
  operatorLayerPayload = Lookup[transport, "OperatorLayer", None];
  basicLayerPayload = <|"Rows" -> rows, "Diagonal" -> diagonal,
    "TargetBoundarySelectors" -> Lookup[layer,
      "TargetBoundarySelectors", <|0 -> IdentityMatrix[targetDimension]|>],
    "SharedBoundaryCoordinates" ->
      TrueQ[Lookup[layer, "SharedBoundaryCoordinates", False]],
    "PathVariable" -> Lookup[layer, "PathVariable", Missing["PathVariable"]],
    "Regulator" -> Lookup[layer, "Regulator", Missing["Regulator"]],
    "BasePoint" -> Lookup[layer, "BasePoint", Missing["BasePoint"]],
    "Endpoint" -> Lookup[layer, "Endpoint", Missing["Endpoint"]]|>;
  If[operatorSourcePayload =!= <|"Dimension" -> sourceDimension,
        "Letters" -> sourceLetters, "Residues" -> sourceResidues,
        "BoundarySelectors" -> sourceSelectors|> ||
      ! AssociationQ[operatorLayerPayload] ||
      KeyTake[operatorLayerPayload, Keys[basicLayerPayload]] =!=
        basicLayerPayload,
    Return[<|"Status" -> "RationalLayerTransportInputMismatch"|>]];
  curve = Lookup[operatorLayerPayload, "Curve", None];
  declaredCurvePointValues = Lookup[layer, "CurvePointValues", <||>];
  If[curve =!= None &&
      (Lookup[layer, "Curve", None] =!= curve ||
       ! AssociationQ[declaredCurvePointValues] ||
       KeyTake[Lookup[operatorLayerPayload, "CurvePointValues", <||>],
          Keys[declaredCurvePointValues]] =!= declaredCurvePointValues),
    Return[<|"Status" -> "RationalLayerTransportInputMismatch"|>]];

  sharedBoundaryQ = TrueQ[Lookup[layer, "SharedBoundaryCoordinates", False]];
  If[sharedBoundaryQ,
    targetSelectors = Lookup[layer, "TargetBoundarySelectors", Missing[]];
    targetBoundaryCount = If[AssociationQ[targetSelectors],
      rationalLayerOperatorBoundaryColumns[targetSelectors], Missing[]],
    {targetSelectors, targetBoundaryCount} =
      rationalLayerTargetSelectors[layer, targetDimension]
  ];
  If[! AssociationQ[targetSelectors] ||
      ! IntegerQ[targetBoundaryCount] || targetBoundaryCount < 1 ||
      ! AllTrue[Values[targetSelectors],
        Dimensions[#] === {targetDimension, targetBoundaryCount} &] ||
      (sharedBoundaryQ && targetBoundaryCount =!= sourceBoundaryCount),
    Return[<|"Status" -> "RationalLayerTargetBoundaryInvalid"|>]];

  incoming = Lookup[transport, "KResidues", Missing[]];
  window = Lookup[transport, "Window", Missing[]];
  If[! AssociationQ[incoming] || ! MatchQ[window, {_Integer, _Integer}],
    Return[<|"Status" -> "RationalLayerResidueOperatorInvalid"|>]];
  If[! AllTrue[Normal[incoming],
      MatchQ[First[#], {_Integer, _, _Integer}] &&
        MatrixQ[Last[#]] &&
        Dimensions[Last[#]] === {targetDimension, sourceDimension} &],
    Return[<|"Status" -> "RationalLayerResidueOperatorInvalid"|>]];

  diagonalTokens = MapIndexed[{"D", First[#2]} &, diagonal];
  diagonalMatrices = AssociationThread[diagonalTokens,
    SparseArray /@ diagonal[[All, 2]]];
  sourceTokens = MapIndexed[{"S", First[#2]} &, sourceLetters];
  sourceMatrices = AssociationThread[sourceTokens,
    SparseArray /@ sourceResidues];
  incomingTokens = ({"K", #[[1]], #[[2]], #[[3]]} &) /@ Keys[incoming];
  incomingMatrices = AssociationThread[incomingTokens,
    SparseArray /@ Values[incoming]];

  gauge = Lookup[transport, "GaugeAtEndpoint", <||>];
  If[! AssociationQ[gauge] || ! AllTrue[Values[gauge],
      MatrixQ[#] && Dimensions[#] ===
        {targetDimension, sourceDimension} &],
    Return[<|"Status" -> "RationalLayerGaugeOperatorInvalid"|>]];
  gaugeTokens = ({"H", #} &) /@ Keys[gauge];
  gaugeMatrices = AssociationThread[gaugeTokens, SparseArray /@ Values[gauge]];

  boundaryLayout = If[sharedBoundaryQ, "Shared", "Independent"];
  pathVariable = Lookup[transport, "PathVariable",
    Lookup[layer, "PathVariable", Missing["PathVariable"]]];
  basePoint = Lookup[transport, "BasePoint",
    Lookup[layer, "BasePoint", Missing["BasePoint"]]];
  endpoint = Lookup[transport, "Endpoint",
    Lookup[layer, "Endpoint", Missing["Endpoint"]]];
  curve = Lookup[transport, "Curve", curve];
  sourceBindingRows = Lookup[source, "PhysicalBoundaryRows", Missing[]];
  targetBindingRows = Lookup[layer, "PhysicalBoundaryRows", Missing[]];
  boundaryCoordinateKeys = Lookup[source, "BoundaryCoordinateKeys", Missing[]];
  boundaryBinding = If[sharedBoundaryQ &&
      MatchQ[sourceBindingRows, {__Integer}] &&
      MatchQ[targetBindingRows, {__Integer}] &&
      ListQ[boundaryCoordinateKeys],
    <|"Dimension" -> Lookup[source, "PhysicalBoundaryDimension", Missing[]],
      "SourceRows" -> sourceBindingRows,
      "TargetRows" -> targetBindingRows,
      "CoordinateKeys" -> boundaryCoordinateKeys|>, None];

  dimensions = <|"Source" -> sourceDimension,
    "Target" -> targetDimension,
    "SourceBoundary" -> sourceBoundaryCount,
    "TargetBoundary" -> targetBoundaryCount,
    "TotalBoundary" -> If[sharedBoundaryQ, sourceBoundaryCount,
      sourceBoundaryCount + targetBoundaryCount]|>;

  <|
    "Status" -> "RationalEpsilonLayerOperatorAccepted",
    "Rows" -> rows,
    "Window" -> window,
    "DemandPairs" -> transport["DemandPairs"],
    "OperatorSource" -> transport["OperatorSource"],
    "OperatorLayer" -> transport["OperatorLayer"],
    "BoundaryLayout" -> boundaryLayout,
    "PhysicalBoundaryBinding" -> boundaryBinding,
    "Path" -> <|"Variable" -> pathVariable, "BasePoint" -> basePoint,
      "Endpoint" -> endpoint, "Curve" -> curve,
      "CurvePointValues" ->
        Lookup[operatorLayerPayload, "CurvePointValues", <||>]|>,
    "Dimensions" -> dimensions,
    "SourceBoundarySelectors" -> (SparseArray /@ sourceSelectors),
    "TargetBoundarySelectors" -> (SparseArray /@ targetSelectors),
    "DiagonalTokens" -> diagonalTokens,
    "DiagonalLabels" -> AssociationThread[diagonalTokens,
      diagonal[[All, 1]]],
    "DiagonalMatrices" -> diagonalMatrices,
    "IncomingTokens" -> incomingTokens,
    "IncomingLabels" -> AssociationThread[incomingTokens,
      (rationalLayerResidueLabel /@ Keys[incoming])],
    "IncomingMatrices" -> incomingMatrices,
    "GaugeTokens" -> gaugeTokens,
    "GaugeMatrices" -> gaugeMatrices,
    "SourceTokens" -> sourceTokens,
    "SourceLabels" -> AssociationThread[sourceTokens, sourceLetters],
    "SourceMatrices" -> sourceMatrices,
    "WordGrammar" -> "D...D, D...D K_r S...S, or H_r S...S",
    "WordOrientation" -> "OutermostFirst",
    "TransportProbabilistic" ->
      TrueQ[Lookup[Lookup[transport, "Certificate", <||>],
        "Probabilistic", False]]
  |>
];

AcceptedRationalEpsilonLayerOperatorQ[operator_] :=
  AssociationQ[operator] &&
  Lookup[operator, "Status", None] ===
    "RationalEpsilonLayerOperatorAccepted" &&
  Lookup[operator, "WordGrammar", None] ===
    "D...D, D...D K_r S...S, or H_r S...S" &&
  MemberQ[{"Shared", "Independent"},
    Lookup[operator, "BoundaryLayout", None]] &&
  AssociationQ[Lookup[operator, "DiagonalMatrices", None]] &&
  AssociationQ[Lookup[operator, "IncomingMatrices", None]] &&
  AssociationQ[Lookup[operator, "GaugeMatrices", None]] &&
  AssociationQ[Lookup[operator, "SourceMatrices", None]] &&
  MatchQ[Lookup[operator, "DemandPairs", None],
    {{_Integer, _Integer} ..}] &&
  DuplicateFreeQ[operator["DemandPairs"]] &&
  AssociationQ[Lookup[operator, "OperatorSource", None]] &&
  AssociationQ[Lookup[operator, "OperatorLayer", None]];

Options[RebaseRationalEpsilonLayerOperator] = {
  "HAtNewBase" -> Automatic
};

(* Rebase the accepted sparse Chen operator without constructing or
   inverting its word series.  The caller supplies the physical source and
   target selectors at the new base.  For F_T = G + H F_S, the homogeneous
   target datum is

       G_q(e) = T_q(e) - Sum_r H_r(e) S_(q-r)(e).

   Independent source/target coordinates are embedded into one common
   boundary vector because G(e) mixes the two spaces. *)
RebaseRationalEpsilonLayerOperator[operator_Association, newBase_,
    sourceSelectors_Association, targetSelectors_Association,
    OptionsPattern[]] := Catch@Module[
  {fail, dimensions, sourceDimension, targetDimension, sourceColumns,
   targetColumns, layout, commonColumns, sourceCommon, targetCommon,
   zeroSource, zeroTarget, gaugeEndpoint, gaugeAtNewBase, gaugeOrders,
   expectedGaugeOrders, sourceOrders, targetOrders, correctedOrders,
   correctedTarget, path, variable, oldBase, oldEndpoint, rebased,
   binding},
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[! AcceptedRationalEpsilonLayerOperatorQ[operator],
    fail["RationalEpsilonLayerOperatorNotAccepted"]];
  dimensions = operator["Dimensions"];
  If[! AssociationQ[dimensions] ||
      ! MatchQ[Lookup[dimensions, {"Source", "Target", "TotalBoundary"}],
        {_Integer?Positive, _Integer?Positive, _Integer?Positive}],
    fail["RationalLayerOperatorDimensionsInvalid"]];
  sourceDimension = dimensions["Source"];
  targetDimension = dimensions["Target"];
  sourceColumns = rationalLayerOperatorSelectorColumns[
    sourceSelectors, sourceDimension];
  targetColumns = rationalLayerOperatorSelectorColumns[
    targetSelectors, targetDimension];
  If[MissingQ[sourceColumns] || MissingQ[targetColumns],
    fail["RationalLayerRebaseSelectorsInvalid"]];
  path = Lookup[operator, "Path", <||>];
  variable = Lookup[path, "Variable", Missing[]];
  oldBase = Lookup[path, "BasePoint", Missing[]];
  oldEndpoint = Lookup[path, "Endpoint", Missing[]];
  If[! MatchQ[variable, _Symbol] || MissingQ[oldBase] ||
      MissingQ[oldEndpoint] || MissingQ[newBase] ||
      ! FreeQ[newBase, variable],
    fail["RationalLayerRebasePointInvalid"]];

  gaugeEndpoint = Lookup[operator, "GaugeMatrices", <||>];
  If[! AssociationQ[gaugeEndpoint] ||
      ! AllTrue[Normal[gaugeEndpoint],
        MatchQ[First[#], {"H", _Integer}] && MatrixQ[Last[#]] &&
          Dimensions[Last[#]] === {targetDimension, sourceDimension} &],
    fail["RationalLayerGaugeOperatorInvalid"]];
  expectedGaugeOrders = If[gaugeEndpoint === <||>, {},
    Keys[gaugeEndpoint][[All, 2]]];
  gaugeAtNewBase = OptionValue["HAtNewBase"];
  If[gaugeAtNewBase === Automatic,
    If[gaugeEndpoint =!= <||> && newBase =!= oldEndpoint &&
        (! MatchQ[oldEndpoint, _Symbol] ||
          FreeQ[Values[gaugeEndpoint], oldEndpoint]) &&
        AnyTrue[Values[gaugeEndpoint], rationalLayerOperatorNonzeroQ],
      fail["RationalLayerGaugeAtNewBaseRequired"]];
    gaugeAtNewBase = Association@KeyValueMap[
      #1[[2]] -> SparseArray[Normal[#2] /.
          oldEndpoint -> newBase] &,
      gaugeEndpoint],
    If[! AssociationQ[gaugeAtNewBase] ||
        Sort[Keys[gaugeAtNewBase]] =!= Sort[expectedGaugeOrders] ||
        ! AllTrue[Values[gaugeAtNewBase], MatrixQ[#] &&
          Dimensions[#] === {targetDimension, sourceDimension} &],
      fail["RationalLayerGaugeAtNewBaseInvalid"]];
    gaugeAtNewBase = Map[SparseArray, gaugeAtNewBase]
  ];
  gaugeOrders = Keys[Select[gaugeAtNewBase,
    rationalLayerOperatorNonzeroQ]];

  layout = operator["BoundaryLayout"];
  If[layout === "Shared",
    If[sourceColumns =!= targetColumns,
      fail["RationalLayerSharedRebaseSelectorsInvalid"]];
    commonColumns = sourceColumns;
    sourceCommon = Map[SparseArray, sourceSelectors];
    targetCommon = Map[SparseArray, targetSelectors],
    commonColumns = sourceColumns + targetColumns;
    sourceCommon = Association@KeyValueMap[#1 -> SparseArray[
        ArrayFlatten[{{#2, ConstantArray[0,
          {sourceDimension, targetColumns}]}}]] &, sourceSelectors];
    targetCommon = Association@KeyValueMap[#1 -> SparseArray[
        ArrayFlatten[{{ConstantArray[0,
          {targetDimension, sourceColumns}], #2}}]] &, targetSelectors]
  ];
  zeroSource = SparseArray[{}, {sourceDimension, commonColumns}];
  zeroTarget = SparseArray[{}, {targetDimension, commonColumns}];
  sourceOrders = Keys[sourceCommon];
  targetOrders = Keys[targetCommon];
  correctedOrders = Union[targetOrders,
    Flatten[Table[r + q, {r, gaugeOrders}, {q, sourceOrders}]]];
  correctedTarget = Association@Table[q -> SparseArray[
      Lookup[targetCommon, q, zeroTarget] - Total[
        Table[gaugeAtNewBase[r] .
          Lookup[sourceCommon, q - r, zeroSource], {r, gaugeOrders}]]],
    {q, correctedOrders}];

  binding = If[layout === "Shared" &&
      sourceColumns === dimensions["TotalBoundary"],
    Lookup[operator, "PhysicalBoundaryBinding", None], None];
  rebased = Join[operator, <|
    "BoundaryLayout" -> "Shared",
    "PhysicalBoundaryBinding" -> binding,
    "Path" -> Join[path, <|"BasePoint" -> newBase|>],
    "Dimensions" -> Join[dimensions, <|
      "SourceBoundary" -> commonColumns,
      "TargetBoundary" -> commonColumns,
      "TotalBoundary" -> commonColumns|>],
    "SourceBoundarySelectors" -> sourceCommon,
    "TargetBoundarySelectors" -> correctedTarget,
    "Rebase" -> <|
      "Status" -> "ExactLazyChenRebase",
      "Method" -> "ChenPathCompositionNoMaterialization",
      "OriginalBasePoint" -> oldBase,
      "NewBasePoint" -> newBase,
      "Endpoint" -> oldEndpoint,
      "OriginalBoundaryLayout" -> layout,
      "PhysicalSourceBoundarySelectors" ->
        Map[SparseArray, sourceSelectors],
      "PhysicalTargetBoundarySelectors" ->
        Map[SparseArray, targetSelectors],
      "HAtNewBase" -> gaugeAtNewBase|>|>];
  If[! AcceptedRationalEpsilonLayerOperatorQ[rebased],
    fail["RationalLayerRebaseConstructionFailed"]];
  rebased
];

RebaseRationalEpsilonLayerOperator[___] :=
  <|"Status" -> "RationalLayerRebaseInputsNotWellFormed"|>;

RationalEpsilonLayerWordMap[operator_Association, word_List,
    boundaryOrder_Integer, outputOrder_Integer, rows_: All] := Module[
  {diagonalTokens, incomingTokens, sourceTokens, incomingPositions,
   prefix, incomingToken, tail, incomingOrder, seed, map,
   dimensions, selected, sharedBoundaryQ, requestedRows},

  If[! AcceptedRationalEpsilonLayerOperatorQ[operator],
    Return[<|"Status" -> "RationalEpsilonLayerOperatorNotAccepted"|>]];
  dimensions = operator["Dimensions"];
  requestedRows = rationalLayerOperatorRequestedRows[
    dimensions["Target"], rows];
  If[requestedRows === $Failed,
    Return[<|"Status" -> "RationalLayerRowsInvalid"|>]];
  If[! rationalLayerOperatorDemandCoveredQ[operator, outputOrder,
      requestedRows],
    Return[<|"Status" -> "RationalLayerDemandOutsideAcceptedPairs",
      "Demand" -> {outputOrder, rows}|>]];
  sharedBoundaryQ = operator["BoundaryLayout"] === "Shared";
  diagonalTokens = operator["DiagonalTokens"];
  incomingTokens = operator["IncomingTokens"];
  sourceTokens = operator["SourceTokens"];
  incomingPositions = Flatten@Position[word,
    token_ /; MemberQ[incomingTokens, token], {1}];

  Which[
    incomingPositions === {},
      If[! AllTrue[word, MemberQ[diagonalTokens, #] &] ||
          outputOrder - boundaryOrder =!= Length[word] ||
          ! KeyExistsQ[operator["TargetBoundarySelectors"], boundaryOrder],
        Return[<|"Status" -> "WordOutsideLayerGrammar"|>]];
      seed = operator["TargetBoundarySelectors"][boundaryOrder];
      map = rationalLayerOperatorFold[
        operator["DiagonalMatrices"], word, seed];
      If[! sharedBoundaryQ,
        map = ArrayFlatten[{{ConstantArray[0,
            {dimensions["Target"], dimensions["SourceBoundary"]}], map}}]],

    Length[incomingPositions] === 1,
      incomingToken = word[[First[incomingPositions]]];
      prefix = Take[word, First[incomingPositions] - 1];
      tail = Drop[word, First[incomingPositions]];
      incomingOrder = incomingToken[[2]];
      If[! AllTrue[prefix, MemberQ[diagonalTokens, #] &] ||
          ! AllTrue[tail, MemberQ[sourceTokens, #] &] ||
          outputOrder - boundaryOrder =!=
            Length[prefix] + incomingOrder + Length[tail] ||
          ! KeyExistsQ[operator["SourceBoundarySelectors"], boundaryOrder],
        Return[<|"Status" -> "WordOutsideLayerGrammar"|>]];
      seed = rationalLayerOperatorFold[
        operator["SourceMatrices"], tail,
        operator["SourceBoundarySelectors"][boundaryOrder]];
      map = operator["IncomingMatrices"][incomingToken] . seed;
      map = rationalLayerOperatorFold[
        operator["DiagonalMatrices"], prefix, map];
      If[! sharedBoundaryQ,
        map = ArrayFlatten[{{map, ConstantArray[0,
            {dimensions["Target"], dimensions["TargetBoundary"]}]}}]],

    True,
      Return[<|"Status" -> "WordOutsideLayerGrammar"|>]
  ];

  If[! MatrixQ[map] ||
      Dimensions[map] =!= {dimensions["Target"],
        dimensions["TotalBoundary"]} ||
      ! FreeQ[map, _Missing],
    Return[<|"Status" -> "RationalLayerWordProductFailed"|>]];
  selected = rationalLayerOperatorRowSelection[SparseArray[map], requestedRows];
  If[selected === $Failed,
    Return[<|"Status" -> "RationalLayerRowsInvalid"|>]];
  <|"Status" -> "RationalEpsilonLayerWordMap",
    "BoundaryOrder" -> boundaryOrder,
    "OutputOrder" -> outputOrder,
    "Word" -> word,
    "Rows" -> requestedRows,
    "Map" -> SparseArray[selected]|>
];

RationalEpsilonLayerWordMap[___] :=
  <|"Status" -> "RationalEpsilonLayerWordInputsNotWellFormed"|>;

Options[RationalEpsilonLayerDemandTerms] = {
  "MaximumTerms" -> Infinity,
  "MaximumStates" -> 200000
};

(* Enumerate only one requested coefficient.  The stored word is the
   sequence of integration kernels, outermost first.  Endpoint-gauge terms
   carry no H letter because H(endpoint) is an algebraic coefficient, not an
   integration kernel. *)
RationalEpsilonLayerDemandTerms[operator_Association,
    {outputOrder_Integer, requestedRows_}, OptionsPattern[]] := Catch@Module[
  {fail, dimensions, rows, maximumTerms, maximumStates, sharedBoundaryQ,
   embedSource, embedTarget, sourceTokens, diagonalTokens, incomingTokens,
   gaugeTokens, sourceStates = <||>, growSource, appendTerm, termStore, terms,
   count = 0, targetState, diagonalStates, incomingState, sourceState,
   a, b, q, incomingOrder, gaugeOrder, labels, labelledWord},
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[! AcceptedRationalEpsilonLayerOperatorQ[operator],
    fail["RationalEpsilonLayerOperatorNotAccepted"]];
  dimensions = operator["Dimensions"];
  rows = Which[
    requestedRows === All, Range[dimensions["Target"]],
    IntegerQ[requestedRows] && 1 <= requestedRows <= dimensions["Target"],
      {requestedRows},
    MatchQ[requestedRows, {__Integer}] && DuplicateFreeQ[requestedRows] &&
      AllTrue[requestedRows, 1 <= # <= dimensions["Target"] &], requestedRows,
    True, fail["RationalLayerRowsInvalid"]];
  If[! rationalLayerOperatorDemandCoveredQ[operator, outputOrder, rows],
    fail["RationalLayerDemandOutsideAcceptedPairs",
      <|"Demand" -> {outputOrder, requestedRows}|>]];
  maximumTerms = OptionValue["MaximumTerms"];
  maximumStates = OptionValue["MaximumStates"];
  If[! (maximumTerms === Infinity || IntegerQ[maximumTerms] && maximumTerms >= 1) ||
      ! IntegerQ[maximumStates] || maximumStates < 1,
    fail["RationalLayerDemandLimitsInvalid"]];
  sharedBoundaryQ = operator["BoundaryLayout"] === "Shared";
  embedSource[m_] := If[sharedBoundaryQ, m,
    ArrayFlatten[{{m, ConstantArray[0,
      {Length[m], dimensions["TargetBoundary"]}]}}]];
  embedTarget[m_] := If[sharedBoundaryQ, m,
    ArrayFlatten[{{ConstantArray[0,
      {Length[m], dimensions["SourceBoundary"]}], m}}]];
  sourceTokens = operator["SourceTokens"];
  diagonalTokens = operator["DiagonalTokens"];
  incomingTokens = operator["IncomingTokens"];
  gaugeTokens = operator["GaugeTokens"];
  labels = Join[operator["DiagonalLabels"], operator["IncomingLabels"],
    operator["SourceLabels"]];
  labelledWord[word_] := Lookup[labels, Key[#], Missing["UnknownToken", #]] & /@ word;
  appendTerm[kind_, word_, boundaryOrder_, matrix_, extra_: <||>] := Module[
    {selected = SparseArray[matrix[[rows, All]]], wordLabels},
    If[! rationalLayerOperatorNonzeroQ[selected], Return[Null]];
    count++;
    If[maximumTerms =!= Infinity && count > maximumTerms,
      fail["RationalLayerTermEnumerationCapped",
        <|"MaximumTerms" -> maximumTerms, "TermsBuilt" -> count - 1|>]];
    wordLabels = labelledWord[word];
    If[! FreeQ[wordLabels, _Missing], fail["RationalLayerWordLabelMissing"]];
    termStore[count] = Join[<|"Kind" -> kind, "WordTokens" -> word,
      "Word" -> wordLabels, "BoundaryOrder" -> boundaryOrder,
      "Rows" -> rows, "Coefficient" -> selected|>, extra]
  ];
  growSource[order_] := If[KeyExistsQ[sourceStates, order],
    sourceStates[order],
    sourceStates[order] = NestList[
      Function[states, Module[{next = rationalLayerOperatorGrow[states,
          sourceTokens, operator["SourceMatrices"], maximumStates]},
        If[AssociationQ[next], fail[next["Status"], KeyDrop[next, "Status"]], next]]],
      {{{}, SparseArray[operator["SourceBoundarySelectors"][order]]}},
      Max[0, outputOrder - order - Min[Join[
        If[incomingTokens === {}, {}, incomingTokens[[All, 2]]],
        If[gaugeTokens === {}, {}, gaugeTokens[[All, 2]]], {0}]]]]
  ];

  (* Homogeneous target-boundary words. *)
  Do[
    a = outputOrder - q;
    If[a >= 0,
      diagonalStates = Nest[
        Function[states, Module[{next = rationalLayerOperatorGrow[states,
            diagonalTokens, operator["DiagonalMatrices"], maximumStates]},
          If[AssociationQ[next], fail[next["Status"], KeyDrop[next, "Status"]], next]]],
        {{{}, SparseArray[operator["TargetBoundarySelectors"][q]]}}, a];
      Do[appendTerm["TargetBoundary", Reverse[targetState[[1]]], q,
          embedTarget[targetState[[2]]]], {targetState, diagonalStates}]],
    {q, Keys[operator["TargetBoundarySelectors"]]}];

  (* One incoming dlog transition, with arbitrary source and target words. *)
  Do[
    incomingOrder = incomingToken[[2]];
    Do[
      Do[
        b = sourceStateIndex - 1;
        a = outputOrder - q - incomingOrder - b;
        If[a < 0, Continue[]];
        Do[
          incomingState = {Append[sourceState[[1]], incomingToken],
            operator["IncomingMatrices"][incomingToken] . sourceState[[2]]};
          If[! rationalLayerOperatorNonzeroQ[incomingState[[2]]], Continue[]];
          diagonalStates = Nest[
            Function[states, Module[{next = rationalLayerOperatorGrow[states,
                diagonalTokens, operator["DiagonalMatrices"], maximumStates]},
              If[AssociationQ[next], fail[next["Status"], KeyDrop[next, "Status"]], next]]],
            {incomingState}, a];
          Do[appendTerm["SourceBoundary", Reverse[targetState[[1]]], q,
              embedSource[targetState[[2]]],
              <|"IncomingOrder" -> incomingOrder|>],
            {targetState, diagonalStates}],
          {sourceState, growSource[q][[sourceStateIndex]]}],
        {sourceStateIndex, Length[growSource[q]]}],
      {q, Keys[operator["SourceBoundarySelectors"]]}],
    {incomingToken, incomingTokens}];

  (* Endpoint gauge H_r times the transported source. *)
  Do[
    gaugeOrder = gaugeToken[[2]];
    Do[
      b = outputOrder - q - gaugeOrder;
      If[b < 0 || b + 1 > Length[growSource[q]], Continue[]];
      Do[appendTerm["EndpointGauge", Reverse[sourceState[[1]]], q,
          embedSource[operator["GaugeMatrices"][gaugeToken] . sourceState[[2]]],
          <|"GaugeOrder" -> gaugeOrder|>],
        {sourceState, growSource[q][[b + 1]]}],
      {q, Keys[operator["SourceBoundarySelectors"]]}],
    {gaugeToken, gaugeTokens}];

  terms = Table[termStore[index], {index, count}];
  <|"Status" -> "RationalEpsilonLayerDemandTermsBuilt",
    "Demand" -> {outputOrder, requestedRows}, "Rows" -> rows,
    "BoundaryLayout" -> operator["BoundaryLayout"], "Terms" -> terms,
    "TermCount" -> Length[terms]|>
];

RationalEpsilonLayerDemandTerms[___] :=
  <|"Status" -> "RationalEpsilonLayerDemandInputsNotWellFormed"|>;
