(* Lazy iterated-integral coefficient operator for a
   rational-epsilon-dependent block.

   SolveRationalEpsilonDependentBlockByVariationOfConstants determines the
   off-diagonal
   basis-transformation block H along the path and the
   dlog remainder K.  Enumerating every Chen word is unnecessary and becomes
   exponential at the weights needed by hard families.  This module keeps the
   finite operator data and evaluates one requested letter sequence by sparse matrix
   products.  It is independent of the letter class: GPL and elliptic letters
   are opaque labels here, so the same operator serves either channel once the
   corresponding residues have been constructed. *)

Clear[ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator,
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ,
  ChangeRationalEpsilonDependentBlockSolutionBasePoint,
  ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix,
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap];

ClearAll[
  rationalEpsilonDependentBlockOperatorNonzeroQ,
  rationalEpsilonDependentBlockOperatorBoundaryColumns,
  rationalEpsilonDependentBlockOperatorFold,
  rationalEpsilonDependentBlockOperatorRowSelection,
  rationalEpsilonDependentBlockOperatorRequestedRows,
  rationalEpsilonDependentBlockOperatorRequestedOutputCoveredQ,
  rationalEpsilonDependentBlockOperatorNonzeroRows,
  rationalEpsilonDependentBlockOperatorGrow,
  rationalEpsilonDependentBlockOperatorSelectorColumns
];

rationalEpsilonDependentBlockOperatorNonzeroQ[m_] :=
  Length[SparseArray[m]["NonzeroPositions"]] > 0;

rationalEpsilonDependentBlockOperatorBoundaryColumns[selectors_Association] := Module[
  {dimensions = Dimensions /@ Values[selectors]},
  If[dimensions === {} || ! AllTrue[dimensions,
      MatchQ[#, {_Integer, _Integer}] &] ||
      Length[DeleteDuplicates[dimensions[[All, 2]]]] =!= 1,
    Missing["InvalidBoundarySelectors"], First[dimensions][[2]]]
];

rationalEpsilonDependentBlockOperatorSelectorColumns[selectors_Association,
    rows_Integer] := Module[
  {columns = rationalEpsilonDependentBlockOperatorBoundaryColumns[selectors]},
  If[MissingQ[columns] || selectors === <||> ||
      ! VectorQ[Keys[selectors], IntegerQ] ||
      ! AllTrue[Values[selectors],
        MatrixQ[#] && Dimensions[#] === {rows, columns} &],
    Missing["InvalidBoundarySelectors"], columns]
];

(* word is outermost first; multiplication starts at the boundary selector,
   hence the reverse traversal. *)
rationalEpsilonDependentBlockOperatorFold[matrices_Association, tokens_List, seed_] :=
  Fold[Lookup[matrices, Key[#2], Missing["UnknownLetter", #2]] . #1 &,
    seed, Reverse[tokens]];

rationalEpsilonDependentBlockOperatorRowSelection[matrix_, All] := matrix;
rationalEpsilonDependentBlockOperatorRowSelection[matrix_, row_Integer] /;
    1 <= row <= Dimensions[matrix][[1]] := matrix[[{row}, All]];
rationalEpsilonDependentBlockOperatorRowSelection[matrix_, rows_List] /;
    VectorQ[rows, IntegerQ] && DuplicateFreeQ[rows] &&
      AllTrue[rows, 1 <= # <= Dimensions[matrix][[1]] &] :=
  matrix[[rows, All]];
rationalEpsilonDependentBlockOperatorRowSelection[_, _] := $Failed;

rationalEpsilonDependentBlockOperatorRequestedRows[dimension_Integer, All] := Range[dimension];
rationalEpsilonDependentBlockOperatorRequestedRows[dimension_Integer, row_Integer] /;
    1 <= row <= dimension := {row};
rationalEpsilonDependentBlockOperatorRequestedRows[dimension_Integer, rows_List] /;
    VectorQ[rows, IntegerQ] && DuplicateFreeQ[rows] &&
      AllTrue[rows, 1 <= # <= dimension &] := rows;
rationalEpsilonDependentBlockOperatorRequestedRows[_, _] := $Failed;

rationalEpsilonDependentBlockOperatorRequestedOutputCoveredQ[operator_Association, order_Integer,
    rows_List] := Module[
  {pairs = Lookup[operator, "RequestedOutputPairs", {}]},
  AllTrue[rows, MemberQ[pairs, {order, #}] &]
];

rationalEpsilonDependentBlockOperatorNonzeroRows[matrix_] :=
  DeleteDuplicates[SparseArray[matrix]["NonzeroPositions"][[All, 1]]];

rationalEpsilonDependentBlockOperatorGrow[states_List, tokens_List,
    matrices_Association, maximumStates_] := Module[{next},
  next = Select[Flatten[Table[
      {Append[state[[1]], token], matrices[token] . state[[2]]},
      {state, states}, {token, tokens}], 1],
    rationalEpsilonDependentBlockOperatorNonzeroQ[#[[2]]] &];
  If[Length[next] > maximumStates,
    <|"Status" -> "IteratedIntegralCoefficientOperatorStateGrowthCapped",
      "StateCount" -> Length[next], "MaximumStates" -> maximumStates|>,
    next]
];

ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
    source_Association, block_Association,
    solution_Association] := Module[
  {sourceDimension, sourceLetters, sourceResidues, sourceSelectors,
   sourceBoundaryCount, rows, targetDimension, targetSelectors,
   targetBoundaryCount, sharedBoundaryQ, boundaryLayout, diagonal,
   diagonalMatrices, diagonalTokens,
   sourceMatrices, sourceTokens, incoming, incomingMatrices,
   incomingTokens, offDiagonalBlockAtPathEndpoint, offDiagonalBlockMatrices, offDiagonalTokens, dimensions, window,
   pathVariable, basePoint, endpoint, curve, boundaryBinding,
   sourceBindingRows, targetBindingRows, boundaryDataType,
   boundaryCoefficientLabels, boundaryCoefficientLabelsKey,
   operatorSourcePayload, operatorBlockPayload, declaredCurvePointValues,
   verificationDemand},

  If[! RationalEpsilonDependentBlockSolutionQ[solution],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockSolutionRequired"|>]];
  sourceDimension = Lookup[source, "Dimension", Missing[]];
  sourceLetters = Lookup[source, "Letters", Missing[]];
  sourceResidues = Lookup[source, "Residues", Missing[]];
  sourceSelectors = Lookup[source, "BoundarySelectors", Missing[]];
  If[! IntegerQ[sourceDimension] || sourceDimension < 1 ||
      ! ListQ[sourceLetters] || ! ListQ[sourceResidues] ||
      Length[sourceLetters] =!= Length[sourceResidues] ||
      ! AssociationQ[sourceSelectors],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockSourceSystemInvalid"|>]];
  sourceBoundaryCount =
    rationalEpsilonDependentBlockOperatorBoundaryColumns[sourceSelectors];
  If[MissingQ[sourceBoundaryCount] ||
      ! AllTrue[sourceResidues,
        Dimensions[#] === {sourceDimension, sourceDimension} &] ||
      ! AllTrue[Values[sourceSelectors],
        Dimensions[#][[1]] === sourceDimension &],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockSourceSystemInvalid"|>]];

  rows = Lookup[block, "Rows", Missing[]];
  targetDimension = If[ListQ[rows], Length[rows], 0];
  diagonal = Lookup[block, "Diagonal", Missing[]];
  If[targetDimension < 1 || ! ListQ[diagonal] ||
      ! AllTrue[diagonal,
        MatchQ[#, {_List, _?MatrixQ}] &&
          Dimensions[#[[2]]] === {targetDimension, targetDimension} &],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockDiagonalBlockInvalid"|>]];

  curve = Lookup[block, "Curve", None];
  declaredCurvePointValues = Lookup[block, "CurvePointValues", <||>];
  If[curve =!= None && ! AssociationQ[declaredCurvePointValues],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockCurvePointValuesInvalid"|>]];
  verificationDemand = <|
    "RequestedOutputPairs" -> solution["RequestedOutputPairs"],
    "PathEndpoint" -> Lookup[solution, "PathEndpoint", None]|>;
  If[! TrueQ[VerifyRationalEpsilonDependentBlockSolution[
      solution, source, block, verificationDemand]],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockSolutionVerificationFailed"|>]];

  operatorSourcePayload = <|"Dimension" -> sourceDimension,
    "Letters" -> sourceLetters, "Residues" -> sourceResidues,
    "BoundarySelectors" -> sourceSelectors|>;
  operatorBlockPayload = <|"Rows" -> rows, "Diagonal" -> diagonal,
    "TargetBoundarySelectors" -> Lookup[block,
      "TargetBoundarySelectors", <|0 -> IdentityMatrix[targetDimension]|>],
    "SharedBoundaryCoordinates" ->
      TrueQ[Lookup[block, "SharedBoundaryCoordinates", False]],
    "PathVariable" -> Lookup[block, "PathVariable", Missing["PathVariable"]],
    "Regulator" -> Lookup[block, "Regulator", Missing["Regulator"]],
    "BasePoint" -> Lookup[block, "BasePoint", Missing["BasePoint"]],
    "PathEndpoint" -> Lookup[block, "PathEndpoint",
      Missing["PathEndpoint"]],
    "Curve" -> curve,
    "CurvePointValues" -> If[curve === None, <||>,
      declaredCurvePointValues]|>;

  sharedBoundaryQ = TrueQ[
    Lookup[block, "SharedBoundaryCoordinates", False]];
  If[sharedBoundaryQ,
    targetSelectors = Lookup[block, "TargetBoundarySelectors", Missing[]];
    targetBoundaryCount = If[AssociationQ[targetSelectors],
      rationalEpsilonDependentBlockOperatorBoundaryColumns[targetSelectors], Missing[]],
    {targetSelectors, targetBoundaryCount} =
      rationalEpsilonDependentBlockTargetSelectors[block, targetDimension]
  ];
  If[! AssociationQ[targetSelectors] ||
      ! IntegerQ[targetBoundaryCount] || targetBoundaryCount < 1 ||
      ! AllTrue[Values[targetSelectors],
        Dimensions[#] === {targetDimension, targetBoundaryCount} &] ||
      (sharedBoundaryQ && targetBoundaryCount =!= sourceBoundaryCount),
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockTargetBoundarySelectorsInvalid"|>]];

  incoming = Lookup[solution, "KResidues", Missing[]];
  window = Lookup[solution, "Window", Missing[]];
  If[! AssociationQ[incoming] || ! MatchQ[window, {_Integer, _Integer}],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockDLogRemainderResiduesInvalid"|>]];
  If[! AllTrue[Normal[incoming],
      MatchQ[First[#], {_Integer, _, _Integer}] &&
        MatrixQ[Last[#]] &&
        Dimensions[Last[#]] === {targetDimension, sourceDimension} &],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockDLogRemainderResiduesInvalid"|>]];

  diagonalTokens = MapIndexed[{"D", First[#2]} &, diagonal];
  diagonalMatrices = AssociationThread[diagonalTokens,
    SparseArray /@ diagonal[[All, 2]]];
  sourceTokens = MapIndexed[{"S", First[#2]} &, sourceLetters];
  sourceMatrices = AssociationThread[sourceTokens,
    SparseArray /@ sourceResidues];
  incomingTokens = ({"K", #[[1]], #[[2]], #[[3]]} &) /@ Keys[incoming];
  incomingMatrices = AssociationThread[incomingTokens,
    SparseArray /@ Values[incoming]];

  offDiagonalBlockAtPathEndpoint = Lookup[solution, "OffDiagonalBasisTransformationBlockAtPathEndpoint", <||>];
  If[! AssociationQ[offDiagonalBlockAtPathEndpoint] || ! AllTrue[Values[offDiagonalBlockAtPathEndpoint],
      MatrixQ[#] && Dimensions[#] ===
        {targetDimension, sourceDimension} &],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockOffDiagonalBasisTransformationBlockInvalid"|>]];
  offDiagonalTokens = ({"H", #} &) /@ Keys[offDiagonalBlockAtPathEndpoint];
  offDiagonalBlockMatrices = AssociationThread[offDiagonalTokens, SparseArray /@ Values[offDiagonalBlockAtPathEndpoint]];

  boundaryLayout = If[sharedBoundaryQ, "Shared", "Independent"];
  pathVariable = Lookup[solution, "PathVariable",
    Lookup[block, "PathVariable", Missing["PathVariable"]]];
  basePoint = Lookup[solution, "BasePoint",
    Lookup[block, "BasePoint", Missing["BasePoint"]]];
  endpoint = Lookup[solution, "PathEndpoint",
    Lookup[block, "PathEndpoint", Missing["PathEndpoint"]]];
  curve = Lookup[solution, "Curve", curve];
  sourceBindingRows = Lookup[source, "BoundarySelectorSourceRows", Missing[]];
  targetBindingRows = Lookup[block, "BoundarySelectorTargetRows", Missing[]];
  boundaryDataType = Lookup[source, "BoundaryDataType", Missing[]];
  boundaryCoefficientLabelsKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientLabels",
    "BoundaryFunctionEpsilonCoefficientLabels"];
  boundaryCoefficientLabels = Lookup[source,
    boundaryCoefficientLabelsKey, Missing[]];
  boundaryBinding = If[sharedBoundaryQ &&
      MatchQ[sourceBindingRows, {__Integer}] &&
      MatchQ[targetBindingRows, {__Integer}] &&
      MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType] &&
      ListQ[boundaryCoefficientLabels],
    <|"Dimension" -> Lookup[source, "BoundarySelectorDimension", Missing[]],
      "BoundaryDataType" -> boundaryDataType,
      "SourceRows" -> sourceBindingRows,
      "TargetRows" -> targetBindingRows,
      boundaryCoefficientLabelsKey -> boundaryCoefficientLabels|>, None];

  dimensions = <|"Source" -> sourceDimension,
    "Target" -> targetDimension,
    "SourceBoundary" -> sourceBoundaryCount,
    "TargetBoundary" -> targetBoundaryCount,
    "TotalBoundary" -> If[sharedBoundaryQ, sourceBoundaryCount,
      sourceBoundaryCount + targetBoundaryCount]|>;

  <|
    "Status" ->
      "RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorConstructed",
    "Rows" -> rows,
    "Window" -> window,
    "RequestedOutputPairs" -> solution["RequestedOutputPairs"],
    "CoefficientOperatorSourceSystem" -> operatorSourcePayload,
    "CoefficientOperatorTargetBlock" -> operatorBlockPayload,
    "BoundaryLayout" -> boundaryLayout,
    "BoundarySelectorBinding" -> boundaryBinding,
    "Path" -> <|"Variable" -> pathVariable, "BasePoint" -> basePoint,
      "PathEndpoint" -> endpoint, "Curve" -> curve,
      "CurvePointValues" ->
        Lookup[operatorBlockPayload, "CurvePointValues", <||>]|>,
    "Dimensions" -> dimensions,
    "SourceBoundarySelectors" -> (SparseArray /@ sourceSelectors),
    "TargetBoundarySelectors" -> (SparseArray /@ targetSelectors),
    "DiagonalTokens" -> diagonalTokens,
    "DiagonalLabels" -> AssociationThread[diagonalTokens,
      diagonal[[All, 1]]],
    "DiagonalMatrices" -> diagonalMatrices,
    "IncomingTokens" -> incomingTokens,
    "IncomingLabels" -> AssociationThread[incomingTokens,
      (rationalEpsilonDependentBlockResidueLabel /@ Keys[incoming])],
    "IncomingMatrices" -> incomingMatrices,
    "OffDiagonalTransformationTokens" -> offDiagonalTokens,
    "OffDiagonalTransformationBlockCoefficientsByToken" -> offDiagonalBlockMatrices,
    "SourceTokens" -> sourceTokens,
    "SourceLabels" -> AssociationThread[sourceTokens, sourceLetters],
    "SourceMatrices" -> sourceMatrices,
    "IteratedIntegralLetterSequenceGrammar" ->
      "D...D, D...D K_r S...S, or H_r S...S",
    "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
    "SolutionValidationProbabilistic" ->
      TrueQ[Lookup[Lookup[solution, "Certificate", <||>],
        "Probabilistic", False]]
  |>
];

RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[operator_] :=
  AssociationQ[operator] &&
  Lookup[operator, "Status", None] ===
    "RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorConstructed" &&
  Lookup[operator, "IteratedIntegralLetterSequenceGrammar", None] ===
    "D...D, D...D K_r S...S, or H_r S...S" &&
  MemberQ[{"Shared", "Independent"},
    Lookup[operator, "BoundaryLayout", None]] &&
  AssociationQ[Lookup[operator, "DiagonalMatrices", None]] &&
  AssociationQ[Lookup[operator, "IncomingMatrices", None]] &&
  AssociationQ[Lookup[operator, "OffDiagonalTransformationBlockCoefficientsByToken", None]] &&
  AssociationQ[Lookup[operator, "SourceMatrices", None]] &&
  MatchQ[Lookup[operator, "RequestedOutputPairs", None],
    {{_Integer, _Integer} ..}] &&
  DuplicateFreeQ[operator["RequestedOutputPairs"]] &&
  AssociationQ[Lookup[operator, "CoefficientOperatorSourceSystem", None]] &&
  AssociationQ[Lookup[operator, "CoefficientOperatorTargetBlock", None]];

Options[ChangeRationalEpsilonDependentBlockSolutionBasePoint] = {
  "OffDiagonalTransformationBlockAtNewBase" -> Automatic,
  "BasePointPrescription" -> None
};

(* Use the same differential equation with a new lower integration limit.
   Chen-series coefficient matrices depend on the connection, not on the
   lower limit, so no old-base evolution matrix is inverted.  The caller
   supplies the actual source and target initial data at the new base.  For
   F_T = G + H F_S, the homogeneous target datum is

       G_q(e) = T_q(e) - Sum_r H_r(e) S_(q-r)(e).

   Independent source/target coordinates are embedded into one common
   boundary vector because G(e) mixes the two spaces. *)
ChangeRationalEpsilonDependentBlockSolutionBasePoint[
    operator_Association, newBase_,
    sourceSelectors_Association, targetSelectors_Association,
    OptionsPattern[]] := Catch@Module[
  {fail, dimensions, sourceDimension, targetDimension, sourceColumns,
   targetColumns, layout, commonColumns, sourceCommon, targetCommon,
   zeroSource, zeroTarget, offDiagonalBlockAtOldEndpoint, offDiagonalBlockAtNewBase, offDiagonalOrders,
   expectedOffDiagonalOrders, sourceOrders, targetOrders, correctedOrders,
   correctedTarget, path, variable, oldBase, oldEndpoint, rebased,
   binding, basePointPrescription, rebasedPath},
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[! RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[operator],
    fail["RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorRequired"]];
  dimensions = operator["Dimensions"];
  If[! AssociationQ[dimensions] ||
      ! MatchQ[Lookup[dimensions, {"Source", "Target", "TotalBoundary"}],
        {_Integer?Positive, _Integer?Positive, _Integer?Positive}],
    fail["RationalEpsilonDependentBlockCoefficientOperatorDimensionsInvalid"]];
  sourceDimension = dimensions["Source"];
  targetDimension = dimensions["Target"];
  sourceColumns = rationalEpsilonDependentBlockOperatorSelectorColumns[
    sourceSelectors, sourceDimension];
  targetColumns = rationalEpsilonDependentBlockOperatorSelectorColumns[
    targetSelectors, targetDimension];
  If[MissingQ[sourceColumns] || MissingQ[targetColumns],
    fail["RationalEpsilonDependentBlockBasePointChangeSelectorsInvalid"]];
  path = Lookup[operator, "Path", <||>];
  variable = Lookup[path, "Variable", Missing[]];
  oldBase = Lookup[path, "BasePoint", Missing[]];
  oldEndpoint = Lookup[path, "PathEndpoint", Missing[]];
  If[! MatchQ[variable, _Symbol] || MissingQ[oldBase] ||
      MissingQ[oldEndpoint] || MissingQ[newBase] ||
      ! FreeQ[newBase, variable],
    fail["RationalEpsilonDependentBlockBasePointChangePointInvalid"]];
  basePointPrescription = OptionValue["BasePointPrescription"];
  If[basePointPrescription =!= None &&
      ! (AssociationQ[basePointPrescription] &&
        Lookup[basePointPrescription, "Type", None] ===
          "TangentialRegularized" &&
        MemberQ[{-1, 1}, Lookup[basePointPrescription,
          "LocalDirection", Missing[]]]),
    fail["RationalEpsilonDependentBlockBasePointPrescriptionInvalid"]];

  offDiagonalBlockAtOldEndpoint = Lookup[operator, "OffDiagonalTransformationBlockCoefficientsByToken", <||>];
  If[! AssociationQ[offDiagonalBlockAtOldEndpoint] ||
      ! AllTrue[Normal[offDiagonalBlockAtOldEndpoint],
        MatchQ[First[#], {"H", _Integer}] && MatrixQ[Last[#]] &&
          Dimensions[Last[#]] === {targetDimension, sourceDimension} &],
    fail["RationalEpsilonDependentBlockOffDiagonalBasisTransformationBlockInvalid"]];
  expectedOffDiagonalOrders = If[offDiagonalBlockAtOldEndpoint === <||>, {},
    Keys[offDiagonalBlockAtOldEndpoint][[All, 2]]];
  offDiagonalBlockAtNewBase = OptionValue["OffDiagonalTransformationBlockAtNewBase"];
  If[offDiagonalBlockAtNewBase === Automatic,
    If[offDiagonalBlockAtOldEndpoint =!= <||> && newBase =!= oldEndpoint &&
        (! MatchQ[oldEndpoint, _Symbol] ||
          FreeQ[Values[offDiagonalBlockAtOldEndpoint], oldEndpoint]) &&
        AnyTrue[Values[offDiagonalBlockAtOldEndpoint], rationalEpsilonDependentBlockOperatorNonzeroQ],
      fail["OffDiagonalBasisTransformationBlockAtNewBasePointRequired"]];
    offDiagonalBlockAtNewBase = Association@KeyValueMap[
      #1[[2]] -> SparseArray[Normal[#2] /.
          oldEndpoint -> newBase] &,
      offDiagonalBlockAtOldEndpoint],
    If[! AssociationQ[offDiagonalBlockAtNewBase] ||
        Sort[Keys[offDiagonalBlockAtNewBase]] =!= Sort[expectedOffDiagonalOrders] ||
        ! AllTrue[Values[offDiagonalBlockAtNewBase], MatrixQ[#] &&
          Dimensions[#] === {targetDimension, sourceDimension} &],
      fail["OffDiagonalBasisTransformationBlockAtNewBasePointInvalid"]];
    offDiagonalBlockAtNewBase = Map[SparseArray, offDiagonalBlockAtNewBase]
  ];
  offDiagonalOrders = Keys[Select[offDiagonalBlockAtNewBase,
    rationalEpsilonDependentBlockOperatorNonzeroQ]];

  layout = operator["BoundaryLayout"];
  If[layout === "Shared",
    If[sourceColumns =!= targetColumns,
      fail["SharedBoundarySelectorsAtNewBasePointInvalid"]];
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
    Flatten[Table[r + q, {r, offDiagonalOrders}, {q, sourceOrders}]]];
  correctedTarget = Association@Table[q -> SparseArray[
      Lookup[targetCommon, q, zeroTarget] - Total[
        Table[offDiagonalBlockAtNewBase[r] .
          Lookup[sourceCommon, q - r, zeroSource], {r, offDiagonalOrders}]]],
    {q, correctedOrders}];

  binding = If[layout === "Shared" &&
      sourceColumns === dimensions["TotalBoundary"],
    Lookup[operator, "BoundarySelectorBinding", None], None];
  rebasedPath = Join[KeyDrop[path, "BasePointPrescription"],
    <|"BasePoint" -> newBase|>,
    If[AssociationQ[basePointPrescription],
      <|"BasePointPrescription" -> basePointPrescription|>, <||>]];
  rebased = Join[operator, <|
    "BoundaryLayout" -> "Shared",
    "BoundarySelectorBinding" -> binding,
    "Path" -> rebasedPath,
    "Dimensions" -> Join[dimensions, <|
      "SourceBoundary" -> commonColumns,
      "TargetBoundary" -> commonColumns,
      "TotalBoundary" -> commonColumns|>],
    "SourceBoundarySelectors" -> sourceCommon,
    "TargetBoundarySelectors" -> correctedTarget,
    "BasePointChange" -> <|
      "Status" -> "IteratedIntegralCoefficientOperatorBasePointChanged",
      "Method" -> "SameDifferentialEquationWithNewBasePoint",
      "MathematicalStatement" ->
        "The residue coefficient operator is unchanged; the formal iterated integrals and initial-data selectors use the new lower limit",
      "OriginalBasePoint" -> oldBase,
      "NewBasePoint" -> newBase,
      "BasePointPrescription" -> basePointPrescription,
      "PathEndpoint" -> oldEndpoint,
      "OriginalBoundaryLayout" -> layout,
      "SourceBoundarySelectorsAtNewBasePoint" ->
        Map[SparseArray, sourceSelectors],
      "TargetBoundarySelectorsAtNewBasePoint" ->
        Map[SparseArray, targetSelectors],
      "OffDiagonalTransformationBlockAtNewBase" -> offDiagonalBlockAtNewBase|>|>];
  If[! RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[rebased],
    fail["RationalEpsilonDependentBlockBasePointChangeFailed"]];
  rebased
];

ChangeRationalEpsilonDependentBlockSolutionBasePoint[___] :=
  <|"Status" ->
    "RationalEpsilonDependentBlockBasePointChangeInputsNotWellFormed"|>;

ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[
    operator_Association, operatorTokenSequence_List,
    boundaryOrder_Integer, outputOrder_Integer, rows_: All] := Module[
  {diagonalTokens, incomingTokens, sourceTokens, incomingPositions,
   prefix, incomingToken, tail, incomingOrder, seed, map,
   dimensions, selected, sharedBoundaryQ, requestedRows, labels,
   iteratedIntegralLetterSequence},

  If[! RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[operator],
    Return[<|"Status" ->
      "RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorRequired"|>]];
  dimensions = operator["Dimensions"];
  requestedRows = rationalEpsilonDependentBlockOperatorRequestedRows[
    dimensions["Target"], rows];
  If[requestedRows === $Failed,
    Return[<|"Status" -> "RequestedMasterIntegralRowsInvalid"|>]];
  If[! rationalEpsilonDependentBlockOperatorRequestedOutputCoveredQ[operator, outputOrder,
      requestedRows],
    Return[<|"Status" -> "RequestedOutputOutsideSolvedPairs",
      "RequestedOutput" -> {outputOrder, rows}|>]];
  sharedBoundaryQ = operator["BoundaryLayout"] === "Shared";
  diagonalTokens = operator["DiagonalTokens"];
  incomingTokens = operator["IncomingTokens"];
  sourceTokens = operator["SourceTokens"];
  incomingPositions = Flatten@Position[operatorTokenSequence,
    token_ /; MemberQ[incomingTokens, token], {1}];

  Which[
    incomingPositions === {},
      If[! AllTrue[operatorTokenSequence,
            MemberQ[diagonalTokens, #] &] ||
          outputOrder - boundaryOrder =!= Length[operatorTokenSequence] ||
          ! KeyExistsQ[operator["TargetBoundarySelectors"], boundaryOrder],
        Return[<|"Status" ->
          "IteratedIntegralOperatorTokenSequenceOutsideBlockGrammar"|>]];
      seed = operator["TargetBoundarySelectors"][boundaryOrder];
      map = rationalEpsilonDependentBlockOperatorFold[
        operator["DiagonalMatrices"], operatorTokenSequence, seed];
      If[! sharedBoundaryQ,
        map = ArrayFlatten[{{ConstantArray[0,
            {dimensions["Target"], dimensions["SourceBoundary"]}], map}}]],

    Length[incomingPositions] === 1,
      incomingToken = operatorTokenSequence[[First[incomingPositions]]];
      prefix = Take[operatorTokenSequence, First[incomingPositions] - 1];
      tail = Drop[operatorTokenSequence, First[incomingPositions]];
      incomingOrder = incomingToken[[2]];
      If[! AllTrue[prefix, MemberQ[diagonalTokens, #] &] ||
          ! AllTrue[tail, MemberQ[sourceTokens, #] &] ||
          outputOrder - boundaryOrder =!=
            Length[prefix] + incomingOrder + Length[tail] ||
          ! KeyExistsQ[operator["SourceBoundarySelectors"], boundaryOrder],
        Return[<|"Status" ->
          "IteratedIntegralOperatorTokenSequenceOutsideBlockGrammar"|>]];
      seed = rationalEpsilonDependentBlockOperatorFold[
        operator["SourceMatrices"], tail,
        operator["SourceBoundarySelectors"][boundaryOrder]];
      map = operator["IncomingMatrices"][incomingToken] . seed;
      map = rationalEpsilonDependentBlockOperatorFold[
        operator["DiagonalMatrices"], prefix, map];
      If[! sharedBoundaryQ,
        map = ArrayFlatten[{{map, ConstantArray[0,
            {dimensions["Target"], dimensions["TargetBoundary"]}]}}]],

    True,
      Return[<|"Status" ->
        "IteratedIntegralOperatorTokenSequenceOutsideBlockGrammar"|>]
  ];

  If[! MatrixQ[map] ||
      Dimensions[map] =!= {dimensions["Target"],
        dimensions["TotalBoundary"]} ||
      ! FreeQ[map, _Missing],
    Return[<|"Status" ->
      "IteratedIntegralCoefficientMatrixProductFailed"|>]];
  selected = rationalEpsilonDependentBlockOperatorRowSelection[SparseArray[map], requestedRows];
  If[selected === $Failed,
    Return[<|"Status" -> "RequestedMasterIntegralRowsInvalid"|>]];
  labels = Join[operator["DiagonalLabels"], operator["IncomingLabels"],
    operator["SourceLabels"]];
  iteratedIntegralLetterSequence = Lookup[labels, Key[#],
      Missing["UnknownOperatorToken", #]] & /@ operatorTokenSequence;
  If[! FreeQ[iteratedIntegralLetterSequence, _Missing],
    Return[<|"Status" ->
      "IteratedIntegralOperatorTokenSequenceInvalid"|>]];
  <|"Status" ->
      "RationalEpsilonDependentBlockIteratedIntegralCoefficientMatrixComputed",
    "BoundaryOrder" -> boundaryOrder,
    "OutputOrder" -> outputOrder,
    "IteratedIntegralOperatorTokenSequence" -> operatorTokenSequence,
    "IteratedIntegralLetterSequence" -> iteratedIntegralLetterSequence,
    "Rows" -> requestedRows,
    "IteratedIntegralCoefficientMatrix" -> SparseArray[selected]|>
];

ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[___] :=
  <|"Status" ->
    "IteratedIntegralCoefficientMatrixInputsNotWellFormed"|>;

Options[ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap] = {
  "MaximumTerms" -> Infinity,
  "MaximumStates" -> 200000
};

(* Construct the coefficient map for one requested epsilon order and set of
   master-integral rows. The key is the sequence of integration kernels,
   outermost first. Contributions from the
   off-diagonal transformation block at the path endpoint
   carry no H letter because H at the path endpoint is an algebraic coefficient, not an
   integration kernel. *)
ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[
    operator_Association,
    {outputOrder_Integer, requestedRows_}, OptionsPattern[]] := Catch@Module[
  {fail, dimensions, rows, maximumTerms, maximumStates, sharedBoundaryQ,
   embedSource, embedTarget, sourceTokens, diagonalTokens, incomingTokens,
   offDiagonalTokens, sourceStates = <||>, growSource, appendTerm, termStore, terms,
   count = 0, targetState, diagonalStates, incomingState, sourceState,
   a, b, q, incomingOrder, offDiagonalOrder, labels, labelledSequence,
   coefficientMap},
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[! RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[operator],
    fail["RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorRequired"]];
  dimensions = operator["Dimensions"];
  rows = Which[
    requestedRows === All, Range[dimensions["Target"]],
    IntegerQ[requestedRows] && 1 <= requestedRows <= dimensions["Target"],
      {requestedRows},
    MatchQ[requestedRows, {__Integer}] && DuplicateFreeQ[requestedRows] &&
      AllTrue[requestedRows, 1 <= # <= dimensions["Target"] &], requestedRows,
    True, fail["RequestedMasterIntegralRowsInvalid"]];
  If[! rationalEpsilonDependentBlockOperatorRequestedOutputCoveredQ[operator, outputOrder, rows],
    fail["RequestedOutputOutsideSolvedPairs",
      <|"RequestedOutput" -> {outputOrder, requestedRows}|>]];
  maximumTerms = OptionValue["MaximumTerms"];
  maximumStates = OptionValue["MaximumStates"];
  If[! (maximumTerms === Infinity || IntegerQ[maximumTerms] && maximumTerms >= 1) ||
      ! IntegerQ[maximumStates] || maximumStates < 1,
    fail["IteratedIntegralCoefficientMapLimitsInvalid"]];
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
  offDiagonalTokens = operator["OffDiagonalTransformationTokens"];
  labels = Join[operator["DiagonalLabels"], operator["IncomingLabels"],
    operator["SourceLabels"]];
  labelledSequence[sequence_] :=
    Lookup[labels, Key[#], Missing["UnknownToken", #]] & /@ sequence;
  appendTerm[kind_, word_, boundaryOrder_, matrix_, extra_: <||>] := Module[
    {selected = SparseArray[matrix[[rows, All]]], wordLabels},
    If[! rationalEpsilonDependentBlockOperatorNonzeroQ[selected], Return[Null]];
    count++;
    If[maximumTerms =!= Infinity && count > maximumTerms,
      fail["IteratedIntegralCoefficientMapConstructionCapped",
        <|"MaximumTerms" -> maximumTerms,
          "ContributionsConstructed" -> count - 1|>]];
    wordLabels = labelledSequence[word];
    If[! FreeQ[wordLabels, _Missing],
      fail["IteratedIntegralLetterSequenceLabelMissing"]];
    termStore[count] = Join[<|
      "ContributionType" -> kind,
      "IteratedIntegralLetterTokens" -> word,
      "IteratedIntegralLetterSequence" -> wordLabels,
      "BoundaryOrder" -> boundaryOrder,
      "Rows" -> rows,
      "IteratedIntegralCoefficientMatrix" -> selected|>, extra]
  ];
  growSource[order_] := If[KeyExistsQ[sourceStates, order],
    sourceStates[order],
    sourceStates[order] = NestList[
      Function[states, Module[{next = rationalEpsilonDependentBlockOperatorGrow[states,
          sourceTokens, operator["SourceMatrices"], maximumStates]},
        If[AssociationQ[next], fail[next["Status"], KeyDrop[next, "Status"]], next]]],
      {{{}, SparseArray[operator["SourceBoundarySelectors"][order]]}},
      Max[0, outputOrder - order - Min[Join[
        If[incomingTokens === {}, {}, incomingTokens[[All, 2]]],
        If[offDiagonalTokens === {}, {}, offDiagonalTokens[[All, 2]]], {0}]]]]
  ];

  (* Homogeneous target-boundary letter sequences. *)
  Do[
    a = outputOrder - q;
    If[a >= 0,
      diagonalStates = Nest[
        Function[states, Module[{next = rationalEpsilonDependentBlockOperatorGrow[states,
            diagonalTokens, operator["DiagonalMatrices"], maximumStates]},
          If[AssociationQ[next], fail[next["Status"], KeyDrop[next, "Status"]], next]]],
        {{{}, SparseArray[operator["TargetBoundarySelectors"][q]]}}, a];
      Do[appendTerm["TargetBoundary", Reverse[targetState[[1]]], q,
          embedTarget[targetState[[2]]]], {targetState, diagonalStates}]],
    {q, Keys[operator["TargetBoundarySelectors"]]}];

  (* One incoming dlog transition, with arbitrary source and target sequences. *)
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
          If[! rationalEpsilonDependentBlockOperatorNonzeroQ[incomingState[[2]]], Continue[]];
          diagonalStates = Nest[
            Function[states, Module[{next = rationalEpsilonDependentBlockOperatorGrow[states,
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

  (* Off-diagonal transformation block H_r at the path endpoint, multiplied
     by the transported source. *)
  Do[
    offDiagonalOrder = offDiagonalToken[[2]];
    Do[
      b = outputOrder - q - offDiagonalOrder;
      If[b < 0 || b + 1 > Length[growSource[q]], Continue[]];
      Do[appendTerm[
          "OffDiagonalBasisTransformationBlockAtPathEndpointContribution",
          Reverse[sourceState[[1]]], q,
          embedSource[operator["OffDiagonalTransformationBlockCoefficientsByToken"][offDiagonalToken] . sourceState[[2]]],
          <|"OffDiagonalTransformationOrder" -> offDiagonalOrder|>],
        {sourceState, growSource[q][[b + 1]]}],
      {q, Keys[operator["SourceBoundarySelectors"]]}],
    {offDiagonalToken, offDiagonalTokens}];

  terms = Table[termStore[index], {index, count}];
  coefficientMap = If[terms === {}, <||>, Merge[
    (Association[#["IteratedIntegralLetterSequence"] ->
        #["IteratedIntegralCoefficientMatrix"]] &) /@ terms,
    SparseArray[Total[#]] &]];
  coefficientMap = Select[coefficientMap,
    rationalEpsilonDependentBlockOperatorNonzeroQ];
  <|"Status" ->
      "RationalEpsilonDependentBlockIteratedIntegralCoefficientMapConstructed",
    "RequestedEpsilonOrderAndMasterIntegralRows" -> {outputOrder, rows},
    "BoundaryLayout" -> operator["BoundaryLayout"],
    "IteratedIntegralCoefficientMap" -> coefficientMap,
    "ContributionCount" -> Length[terms],
    "LetterSequenceCount" -> Length[coefficientMap]|>
];

ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[___] :=
  <|"Status" ->
    "IteratedIntegralCoefficientMapInputsNotWellFormed"|>;
