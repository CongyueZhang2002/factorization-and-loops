(* Lazy composition across a singular tangential junction.

   An upstream path ends in a finite set of local modes.  A downstream path
   starts from its own regular base, so a regularized local inverse solve is
   needed between them.  This module consumes that solve order by order and
   composes only requested sparse iterated-integral coefficient maps,

       Z[downstream letter sequence] . J . P[upstream letter sequence].

   The two letter sequences remain an ordered pair on distinct path segments;
   no shuffle expansion or dense evolution operator is constructed here. *)

Clear[BuildSingularPointMatchingData,
  SingularPointMatchingDataQ,
  ComposeIteratedIntegralCoefficientMapsAcrossSingularPoint];

ClearAll[singularPointMatchingLaurentCoefficientMatrices,
  singularPointMatchingNonzeroQ,
  singularPointMatchingTermQ];

singularPointMatchingNonzeroQ[matrix_] :=
  Length[SparseArray[matrix]["NonzeroPositions"]] > 0;

singularPointMatchingLaurentCoefficientMatrices[coefficients_] := Module[{dimensions},
  If[! AssociationQ[coefficients] || coefficients === <||> ||
      ! VectorQ[Keys[coefficients], IntegerQ] ||
      ! AllTrue[Values[coefficients], MatrixQ],
    Return[$Failed]];
  dimensions = DeleteDuplicates[Dimensions /@ Values[coefficients]];
  If[Length[dimensions] =!= 1 ||
      ! MatchQ[First[dimensions], {_Integer?Positive, _Integer?Positive}],
    Return[$Failed]];
  Association@KeyValueMap[#1 -> SparseArray[#2] &, coefficients]
];

(* SourceModeCoefficientMatrices and TransformedTargetModeCoefficientMatrices are Laurent coefficient matrices: key r is
   the coefficient of eps^r.  LocalSolutionToBoundaryCoefficientMatrices maps a local-state
   coefficient at LocalStateOrder to a boundary coefficient at
   DownstreamBoundaryOrder.  Keeping both order indices is more general than
   assuming a translation-invariant Toeplitz map. *)
BuildSingularPointMatchingData[spec_Association] := Catch@Module[
  {fail, regulator, coordinateKeys, exponents, sourceCoefficients, targetCoefficients,
   sourceDimensions, targetDimensions, modeCount, localDimension,
   selectorRecords, selectorDimensions, downstreamBoundaryDimension,
   selectorPairs, selectorIndex, combinedCoefficients, shifts, sourceZero,
   targetZero, scope, junction, regularization},

  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];

  If[! TrueQ[Lookup[spec, "TransformedTargetModeCoefficientMatricesComplete", False]] ||
      ! KeyExistsQ[spec, "TransformedTargetModeCoefficientMatrices"],
    fail["SingularPointMatchingTransformedTargetModeCoefficientMatricesRequired",
      <|"RequiredRepresentation" -> "G=FTarget-H.FSource",
        "TransformedTargetModeCoefficientMatricesComplete" ->
          TrueQ[Lookup[spec, "TransformedTargetModeCoefficientMatricesComplete", False]]|>]];

  regulator = Lookup[spec, "Regulator", Missing[]];
  coordinateKeys = Lookup[spec, "BoundaryCoordinateKeys", Missing[]];
  exponents = Lookup[spec, "ModeExponents", Missing[]];
  scope = Lookup[spec, "Scope", Missing[]];
  junction = Lookup[spec, "Junction", Missing[]];
  regularization = Lookup[spec, "Regularization", Missing[]];
  If[! MatchQ[regulator, _Symbol] || ! ListQ[coordinateKeys] ||
      coordinateKeys === {} || ! DuplicateFreeQ[coordinateKeys] ||
      ! ListQ[exponents] || exponents === {} ||
      ! MemberQ[{"Full", "OwnHomogeneousContribution"}, scope] ||
      ! AssociationQ[junction],
    fail["SingularPointMatchingMetadataInvalid"]];
  If[! AssociationQ[regularization] ||
      Lookup[regularization, "Status", None] =!=
        "SingularPointMatchingEquationValidatedThroughFirstLocalOrder" ||
      ! ContainsAll[Lookup[regularization, "CheckedRhoOrders", {}], {0, 1}],
    fail["SingularPointMatchingRegularizationEvidenceRequired",
      <|"RequiredRhoOrders" -> {0, 1}|>]];

  sourceCoefficients = singularPointMatchingLaurentCoefficientMatrices[
    Lookup[spec, "SourceModeCoefficientMatrices", Missing[]]];
  targetCoefficients = singularPointMatchingLaurentCoefficientMatrices[spec["TransformedTargetModeCoefficientMatrices"]];
  If[sourceCoefficients === $Failed || targetCoefficients === $Failed,
    fail["SingularPointMatchingModeMapInvalid"]];
  sourceDimensions = Dimensions[First[Values[sourceCoefficients]]];
  targetDimensions = Dimensions[First[Values[targetCoefficients]]];
  modeCount = sourceDimensions[[2]];
  If[targetDimensions[[2]] =!= modeCount ||
      Length[exponents] =!= modeCount,
    fail["SingularPointMatchingModeDimensionMismatch"]];
  If[! FreeQ[{Values[sourceCoefficients], Values[targetCoefficients]}, regulator],
    fail["SingularPointMatchingModeCoefficientMatricesByEpsilonOrderRequired"]];
  localDimension = sourceDimensions[[1]] + targetDimensions[[1]];

  selectorRecords = Lookup[spec, "LocalSolutionToBoundaryCoefficientMatrices", Missing[]];
  If[! ListQ[selectorRecords] || selectorRecords === {} ||
      ! AllTrue[selectorRecords, AssociationQ[#] &&
        IntegerQ[Lookup[#, "DownstreamBoundaryOrder", None]] &&
        IntegerQ[Lookup[#, "LocalStateOrder", None]] &&
        MatrixQ[Lookup[#, "Map", None]] &],
    fail["SingularPointMatchingInverseSelectorsInvalid"]];
  selectorDimensions = DeleteDuplicates[
    Dimensions[#["Map"]] & /@ selectorRecords];
  If[Length[selectorDimensions] =!= 1 ||
      Last[First[selectorDimensions]] =!= localDimension ||
      First[First[selectorDimensions]] < 1,
    fail["SingularPointMatchingInverseSelectorDimensionMismatch"]];
  If[! FreeQ[Lookup[selectorRecords, "Map"], regulator],
    fail["SingularPointMatchingLocalSolutionToBoundaryCoefficientOrdersRequired"]];
  downstreamBoundaryDimension = First[First[selectorDimensions]];
  selectorPairs = ({#["DownstreamBoundaryOrder"],
        #["LocalStateOrder"]} &) /@ selectorRecords;
  If[! DuplicateFreeQ[selectorPairs],
    fail["SingularPointMatchingInverseSelectorDuplicateOrder"]];
  selectorRecords = Map[Join[KeyDrop[#, "Map"],
      <|"Map" -> SparseArray[#1["Map"]]|>] &, selectorRecords];
  selectorIndex = Association@KeyValueMap[
      Function[{downstreamOrder, records},
        downstreamOrder -> Association[
          (#["LocalStateOrder"] -> #["Map"]) & /@ records]],
      GroupBy[selectorRecords, #["DownstreamBoundaryOrder"] &]];

  shifts = Union[Keys[sourceCoefficients], Keys[targetCoefficients]];
  sourceZero = SparseArray[{}, sourceDimensions];
  targetZero = SparseArray[{}, targetDimensions];
  combinedCoefficients = Association@Table[shift -> SparseArray[Join[
        Lookup[sourceCoefficients, shift, sourceZero],
        Lookup[targetCoefficients, shift, targetZero]]], {shift, shifts}];

  <|"Status" -> "SingularPointMatchingDataV1",
    "Regulator" -> regulator,
    "Scope" -> scope,
    "Junction" -> junction,
    "BoundaryCoordinateKeys" -> coordinateKeys,
    "ModeExponents" -> exponents,
    "SourceModeCoefficientMatrices" -> sourceCoefficients,
    "TransformedTargetModeCoefficientMatrices" -> targetCoefficients,
    "TransformedTargetModeCoefficientMatricesComplete" -> True,
    "CombinedModeCoefficientMatrices" -> combinedCoefficients,
    "LocalSolutionToBoundaryCoefficientMatrices" -> selectorRecords,
    "LocalSolutionToBoundaryCoefficientMatrixIndex" -> selectorIndex,
    "Regularization" -> regularization,
    "Dimensions" -> <|
      "SourceState" -> sourceDimensions[[1]],
      "TransformedTargetState" -> targetDimensions[[1]],
      "LocalState" -> localDimension,
      "JunctionModes" -> modeCount,
      "DownstreamBoundary" -> downstreamBoundaryDimension,
      "UpstreamBoundaryData" -> Length[coordinateKeys]|>,
    "SegmentedIteratedIntegralConvention" -> <|
      "KeyOrder" -> {
        "UpstreamPathIteratedIntegralLetterSequence",
        "DownstreamPathIteratedIntegralLetterSequence"},
      "LetterSequenceOrientation" -> "OutermostFirst",
      "NoShuffleExpansion" -> True|>|>
];

BuildSingularPointMatchingData[___] :=
  <|"Status" -> "SingularPointMatchingDataInputsNotWellFormed"|>;

SingularPointMatchingDataQ[binding_] :=
  AssociationQ[binding] &&
  Lookup[binding, "Status", None] === "SingularPointMatchingDataV1" &&
  TrueQ[Lookup[binding, "TransformedTargetModeCoefficientMatricesComplete", False]] &&
  AssociationQ[Lookup[binding, "TransformedTargetModeCoefficientMatrices", None]] &&
  AssociationQ[Lookup[binding, "CombinedModeCoefficientMatrices", None]] &&
  AssociationQ[Lookup[binding, "LocalSolutionToBoundaryCoefficientMatrixIndex", None]] &&
  AssociationQ[Lookup[binding, "Dimensions", None]] &&
  ListQ[Lookup[binding, "BoundaryCoordinateKeys", None]] &&
  Length[binding["BoundaryCoordinateKeys"]] ===
    Lookup[binding["Dimensions"], "UpstreamBoundaryData", None] &&
  Length[Lookup[binding, "ModeExponents", {}]] ===
    Lookup[binding["Dimensions"], "JunctionModes", None] &&
  Lookup[binding, "SegmentedIteratedIntegralConvention", <||>] === <|
    "KeyOrder" -> {
      "UpstreamPathIteratedIntegralLetterSequence",
      "DownstreamPathIteratedIntegralLetterSequence"},
    "LetterSequenceOrientation" -> "OutermostFirst",
    "NoShuffleExpansion" -> True|>;

SingularPointMatchingDataQ[___] := False;

singularPointMatchingTermQ[term_, rowDimension_, columnDimension_] :=
  AssociationQ[term] &&
  IntegerQ[Lookup[term, "BoundaryOrder", None]] &&
  IntegerQ[Lookup[term, "OutputOrder", None]] &&
  ListQ[Lookup[term, "IteratedIntegralLetterSequence", None]] &&
  MatrixQ[Lookup[term, "IteratedIntegralCoefficientMatrix", None]] &&
  Dimensions[term["IteratedIntegralCoefficientMatrix"]] ===
    {rowDimension, columnDimension};

(* Upstream maps have shape junctionModes x Stage3Boundary.  Downstream maps
   have shape outputRows x DownstreamBoundary.  Only order-compatible pairs
   are multiplied, and exact duplicate segmented letter-sequence pairs are
   merged. *)
ComposeIteratedIntegralCoefficientMapsAcrossSingularPoint[
    binding_Association,
    upstreamTerms_List, downstreamTerms_List,
    outputOrder_Integer] := Catch@Module[
  {fail, dimensions, modeCount, upstreamBoundaryDataCount,
   downstreamBoundaryCount,
   outputRowCounts, outputRows, selectedDownstream, combinedCoefficients,
   selectorIndex, junctionMap, raw, harvested, groups, merged,
   activeColumns},

  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  If[! TrueQ[Lookup[binding, "TransformedTargetModeCoefficientMatricesComplete", False]] ||
      ! AssociationQ[Lookup[binding, "TransformedTargetModeCoefficientMatrices", None]],
    fail["SingularPointMatchingTransformedTargetModeCoefficientMatricesRequired",
      <|"RequiredRepresentation" -> "G=FTarget-H.FSource"|>]];
  If[! SingularPointMatchingDataQ[binding],
    fail["SingularPointMatchingDataRequired"]];
  If[upstreamTerms === {} || downstreamTerms === {},
    fail["SingularPointMatchingIteratedIntegralCoefficientMapTermsRequired"]];

  dimensions = binding["Dimensions"];
  modeCount = dimensions["JunctionModes"];
  upstreamBoundaryDataCount = dimensions["UpstreamBoundaryData"];
  downstreamBoundaryCount = dimensions["DownstreamBoundary"];
  If[! AllTrue[upstreamTerms,
      singularPointMatchingTermQ[#, modeCount, upstreamBoundaryDataCount] &],
    fail["SingularPointMatchingUpstreamTermsInvalid"]];
  outputRowCounts = DeleteDuplicates[
    First[Dimensions[
        #1["IteratedIntegralCoefficientMatrix"]]] & /@ downstreamTerms];
  If[Length[outputRowCounts] =!= 1 || First[outputRowCounts] < 1,
    fail["SingularPointMatchingDownstreamTermsInvalid"]];
  outputRows = First[outputRowCounts];
  If[! AllTrue[downstreamTerms,
      singularPointMatchingTermQ[#, outputRows,
        downstreamBoundaryCount] &],
    fail["SingularPointMatchingDownstreamTermsInvalid"]];
  selectedDownstream = Select[downstreamTerms,
    #["OutputOrder"] === outputOrder &];

  combinedCoefficients = binding["CombinedModeCoefficientMatrices"];
  selectorIndex = binding["LocalSolutionToBoundaryCoefficientMatrixIndex"];
  Clear[junctionMap];
  junctionMap[downstreamOrder_Integer, upstreamOrder_Integer] :=
    junctionMap[downstreamOrder, upstreamOrder] = Module[
      {localSelectors, products},
      localSelectors = Lookup[selectorIndex, downstreamOrder, <||>];
      products = Cases[KeyValueMap[Function[{shift, modeMap},
          With[{inverse = Lookup[localSelectors,
              upstreamOrder + shift, Missing[]]},
            If[MissingQ[inverse], Nothing, inverse . modeMap]]],
          combinedCoefficients], _?MatrixQ];
      If[products === {},
        SparseArray[{}, {downstreamBoundaryCount, modeCount}],
        SparseArray[Total[products]]]
    ];

  harvested = Reap[
    Do[With[{junction = junctionMap[
          downstream["BoundaryOrder"], upstream["OutputOrder"]]},
      If[singularPointMatchingNonzeroQ[junction],
        With[{map = SparseArray[(
              downstream["IteratedIntegralCoefficientMatrix"] . junction) .
              upstream["IteratedIntegralCoefficientMatrix"]]},
          If[singularPointMatchingNonzeroQ[map], Sow[<|
            "BoundaryOrder" -> upstream["BoundaryOrder"],
            "OutputOrder" -> outputOrder,
            "UpstreamPathIteratedIntegralLetterSequence" ->
              upstream["IteratedIntegralLetterSequence"],
            "DownstreamPathIteratedIntegralLetterSequence" ->
              downstream["IteratedIntegralLetterSequence"],
            "IteratedIntegralCoefficientMatrix" -> map|>]]]]],
      {downstream, selectedDownstream}, {upstream, upstreamTerms}]
  ][[2]];
  raw = If[harvested === {}, {}, First[harvested]];
  groups = GatherBy[raw, {#["BoundaryOrder"],
        #["UpstreamPathIteratedIntegralLetterSequence"],
        #["DownstreamPathIteratedIntegralLetterSequence"]} &];
  merged = Select[Map[Function[group, With[
        {map = SparseArray[Total[
            Lookup[group, "IteratedIntegralCoefficientMatrix"]]]},
        Join[KeyDrop[First[group], "IteratedIntegralCoefficientMatrix"],
          <|"IteratedIntegralCoefficientMatrix" -> map|>]]], groups],
    singularPointMatchingNonzeroQ[
      #1["IteratedIntegralCoefficientMatrix"]] &];
  activeColumns = If[merged === {}, {},
    Sort@DeleteDuplicates@Flatten[
      SparseArray[#1["IteratedIntegralCoefficientMatrix"]][
        "NonzeroPositions"][[All, 2]] & /@ merged]];

  <|"Status" ->
      "SingularPointMatchingIteratedIntegralCoefficientMapsComposed",
    "OutputOrder" -> outputOrder,
    "Scope" -> binding["Scope"],
    "ModeExponents" -> binding["ModeExponents"],
    "BoundaryCoordinateKeys" -> binding["BoundaryCoordinateKeys"],
    "ActiveBoundaryColumns" -> activeColumns,
    "SegmentedIteratedIntegralConvention" ->
      binding["SegmentedIteratedIntegralConvention"],
    "IteratedIntegralCoefficientMapTermCount" -> Length[merged],
    "IteratedIntegralCoefficientMapTerms" -> merged|>
];

ComposeIteratedIntegralCoefficientMapsAcrossSingularPoint[___] :=
  <|"Status" ->
    "SingularPointMatchingIteratedIntegralCoefficientMapInputsNotWellFormed"|>;
