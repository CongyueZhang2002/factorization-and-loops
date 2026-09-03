(* Lazy composition across a singular tangential junction.

   An upstream path ends in a finite set of local modes.  A downstream path
   starts from its own regular base, so a regularized local inverse solve is
   needed between them.  This module consumes that solve order by order and
   composes only demanded sparse word maps,

       Z[downstream word] . J . P[upstream word].

   The two words remain an ordered pair; no shuffle expansion or dense
   transport matrix is constructed here. *)

Clear[BuildTangentialJunctionBinding,
  AcceptedTangentialJunctionBindingQ,
  ComposeTangentialJunctionWordMaps];

ClearAll[tangentialJunctionSparseDeck,
  tangentialJunctionNonzeroQ,
  tangentialJunctionTermQ];

tangentialJunctionNonzeroQ[matrix_] :=
  Length[SparseArray[matrix]["NonzeroPositions"]] > 0;

tangentialJunctionSparseDeck[deck_] := Module[{dimensions},
  If[! AssociationQ[deck] || deck === <||> ||
      ! VectorQ[Keys[deck], IntegerQ] ||
      ! AllTrue[Values[deck], MatrixQ],
    Return[$Failed]];
  dimensions = DeleteDuplicates[Dimensions /@ Values[deck]];
  If[Length[dimensions] =!= 1 ||
      ! MatchQ[First[dimensions], {_Integer?Positive, _Integer?Positive}],
    Return[$Failed]];
  Association@KeyValueMap[#1 -> SparseArray[#2] &, deck]
];

(* SourceModeMap and TargetGModeMap are Laurent coefficient decks: key r is
   the coefficient of eps^r.  RegularizedInverseSelectors maps a local-state
   coefficient at LocalStateOrder to a boundary coefficient at
   DownstreamBoundaryOrder.  Keeping both order indices is more general than
   assuming a translation-invariant Toeplitz map. *)
BuildTangentialJunctionBinding[spec_Association] := Catch@Module[
  {fail, regulator, coordinateKeys, exponents, sourceDeck, targetDeck,
   sourceDimensions, targetDimensions, modeCount, localDimension,
   selectorRecords, selectorDimensions, downstreamBoundaryDimension,
   selectorPairs, selectorIndex, combinedDeck, shifts, sourceZero,
   targetZero, scope, junction, regularization},

  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];

  If[! TrueQ[Lookup[spec, "TargetGModeMapComplete", False]] ||
      ! KeyExistsQ[spec, "TargetGModeMap"],
    fail["TangentialJunctionTargetGModeMapRequired",
      <|"RequiredRepresentation" -> "TargetG",
        "TargetGModeMapComplete" ->
          TrueQ[Lookup[spec, "TargetGModeMapComplete", False]]|>]];

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
    fail["TangentialJunctionMetadataInvalid"]];
  If[! AssociationQ[regularization] ||
      Lookup[regularization, "Status", None] =!=
        "TangentialJunctionIntertwiningJetsAccepted" ||
      ! ContainsAll[Lookup[regularization, "CheckedRhoOrders", {}], {0, 1}],
    fail["TangentialJunctionRegularizationEvidenceRequired",
      <|"RequiredRhoOrders" -> {0, 1}|>]];

  sourceDeck = tangentialJunctionSparseDeck[
    Lookup[spec, "SourceModeMap", Missing[]]];
  targetDeck = tangentialJunctionSparseDeck[spec["TargetGModeMap"]];
  If[sourceDeck === $Failed || targetDeck === $Failed,
    fail["TangentialJunctionModeMapInvalid"]];
  sourceDimensions = Dimensions[First[Values[sourceDeck]]];
  targetDimensions = Dimensions[First[Values[targetDeck]]];
  modeCount = sourceDimensions[[2]];
  If[targetDimensions[[2]] =!= modeCount ||
      Length[exponents] =!= modeCount,
    fail["TangentialJunctionModeDimensionMismatch"]];
  If[! FreeQ[{Values[sourceDeck], Values[targetDeck]}, regulator],
    fail["TangentialJunctionModeMapOrderDeckRequired"]];
  localDimension = sourceDimensions[[1]] + targetDimensions[[1]];

  selectorRecords = Lookup[spec, "RegularizedInverseSelectors", Missing[]];
  If[! ListQ[selectorRecords] || selectorRecords === {} ||
      ! AllTrue[selectorRecords, AssociationQ[#] &&
        IntegerQ[Lookup[#, "DownstreamBoundaryOrder", None]] &&
        IntegerQ[Lookup[#, "LocalStateOrder", None]] &&
        MatrixQ[Lookup[#, "Map", None]] &],
    fail["TangentialJunctionInverseSelectorsInvalid"]];
  selectorDimensions = DeleteDuplicates[
    Dimensions[#["Map"]] & /@ selectorRecords];
  If[Length[selectorDimensions] =!= 1 ||
      Last[First[selectorDimensions]] =!= localDimension ||
      First[First[selectorDimensions]] < 1,
    fail["TangentialJunctionInverseSelectorDimensionMismatch"]];
  If[! FreeQ[Lookup[selectorRecords, "Map"], regulator],
    fail["TangentialJunctionInverseSelectorOrderDeckRequired"]];
  downstreamBoundaryDimension = First[First[selectorDimensions]];
  selectorPairs = ({#["DownstreamBoundaryOrder"],
        #["LocalStateOrder"]} &) /@ selectorRecords;
  If[! DuplicateFreeQ[selectorPairs],
    fail["TangentialJunctionInverseSelectorDuplicateOrder"]];
  selectorRecords = Map[Join[KeyDrop[#, "Map"],
      <|"Map" -> SparseArray[#1["Map"]]|>] &, selectorRecords];
  selectorIndex = Association@KeyValueMap[
      Function[{downstreamOrder, records},
        downstreamOrder -> Association[
          (#["LocalStateOrder"] -> #["Map"]) & /@ records]],
      GroupBy[selectorRecords, #["DownstreamBoundaryOrder"] &]];

  shifts = Union[Keys[sourceDeck], Keys[targetDeck]];
  sourceZero = SparseArray[{}, sourceDimensions];
  targetZero = SparseArray[{}, targetDimensions];
  combinedDeck = Association@Table[shift -> SparseArray[Join[
        Lookup[sourceDeck, shift, sourceZero],
        Lookup[targetDeck, shift, targetZero]]], {shift, shifts}];

  <|"Status" -> "TangentialJunctionBindingV1",
    "Regulator" -> regulator,
    "Scope" -> scope,
    "Junction" -> junction,
    "BoundaryCoordinateKeys" -> coordinateKeys,
    "ModeExponents" -> exponents,
    "SourceModeMap" -> sourceDeck,
    "TargetGModeMap" -> targetDeck,
    "TargetGModeMapComplete" -> True,
    "CombinedModeMap" -> combinedDeck,
    "RegularizedInverseSelectors" -> selectorRecords,
    "RegularizedInverseSelectorIndex" -> selectorIndex,
    "Regularization" -> regularization,
    "Dimensions" -> <|
      "SourceState" -> sourceDimensions[[1]],
      "TargetGState" -> targetDimensions[[1]],
      "LocalState" -> localDimension,
      "JunctionModes" -> modeCount,
      "DownstreamBoundary" -> downstreamBoundaryDimension,
      "Stage3Boundary" -> Length[coordinateKeys]|>,
    "SegmentedWordConvention" -> <|
      "KeyOrder" -> {"UpstreamWord", "DownstreamWord"},
      "WordOrientation" -> "OutermostFirst",
      "NoShuffleExpansion" -> True|>|>
];

BuildTangentialJunctionBinding[___] :=
  <|"Status" -> "TangentialJunctionBindingInputsNotWellFormed"|>;

AcceptedTangentialJunctionBindingQ[binding_] :=
  AssociationQ[binding] &&
  Lookup[binding, "Status", None] === "TangentialJunctionBindingV1" &&
  TrueQ[Lookup[binding, "TargetGModeMapComplete", False]] &&
  AssociationQ[Lookup[binding, "TargetGModeMap", None]] &&
  AssociationQ[Lookup[binding, "CombinedModeMap", None]] &&
  AssociationQ[Lookup[binding, "RegularizedInverseSelectorIndex", None]] &&
  AssociationQ[Lookup[binding, "Dimensions", None]] &&
  ListQ[Lookup[binding, "BoundaryCoordinateKeys", None]] &&
  Length[binding["BoundaryCoordinateKeys"]] ===
    Lookup[binding["Dimensions"], "Stage3Boundary", None] &&
  Length[Lookup[binding, "ModeExponents", {}]] ===
    Lookup[binding["Dimensions"], "JunctionModes", None] &&
  Lookup[binding, "SegmentedWordConvention", <||>] === <|
    "KeyOrder" -> {"UpstreamWord", "DownstreamWord"},
    "WordOrientation" -> "OutermostFirst",
    "NoShuffleExpansion" -> True|>;

AcceptedTangentialJunctionBindingQ[___] := False;

tangentialJunctionTermQ[term_, rowDimension_, columnDimension_] :=
  AssociationQ[term] &&
  IntegerQ[Lookup[term, "BoundaryOrder", None]] &&
  IntegerQ[Lookup[term, "OutputOrder", None]] &&
  ListQ[Lookup[term, "Word", None]] &&
  MatrixQ[Lookup[term, "Map", None]] &&
  Dimensions[term["Map"]] === {rowDimension, columnDimension};

(* Upstream maps have shape junctionModes x Stage3Boundary.  Downstream maps
   have shape outputRows x DownstreamBoundary.  Only order-compatible pairs
   are multiplied, and exact duplicate segmented words are merged. *)
ComposeTangentialJunctionWordMaps[binding_Association,
    upstreamTerms_List, downstreamTerms_List,
    outputOrder_Integer] := Catch@Module[
  {fail, dimensions, modeCount, stage3Count, downstreamBoundaryCount,
   outputRowCounts, outputRows, selectedDownstream, combinedDeck,
   selectorIndex, junctionMap, raw, harvested, groups, merged,
   activeColumns},

  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  If[! TrueQ[Lookup[binding, "TargetGModeMapComplete", False]] ||
      ! AssociationQ[Lookup[binding, "TargetGModeMap", None]],
    fail["TangentialJunctionTargetGModeMapRequired",
      <|"RequiredRepresentation" -> "TargetG"|>]];
  If[! AcceptedTangentialJunctionBindingQ[binding],
    fail["TangentialJunctionBindingRequired"]];
  If[upstreamTerms === {} || downstreamTerms === {},
    fail["TangentialJunctionWordTermsRequired"]];

  dimensions = binding["Dimensions"];
  modeCount = dimensions["JunctionModes"];
  stage3Count = dimensions["Stage3Boundary"];
  downstreamBoundaryCount = dimensions["DownstreamBoundary"];
  If[! AllTrue[upstreamTerms,
      tangentialJunctionTermQ[#, modeCount, stage3Count] &],
    fail["TangentialJunctionUpstreamTermsInvalid"]];
  outputRowCounts = DeleteDuplicates[
    First[Dimensions[#1["Map"]]] & /@ downstreamTerms];
  If[Length[outputRowCounts] =!= 1 || First[outputRowCounts] < 1,
    fail["TangentialJunctionDownstreamTermsInvalid"]];
  outputRows = First[outputRowCounts];
  If[! AllTrue[downstreamTerms,
      tangentialJunctionTermQ[#, outputRows,
        downstreamBoundaryCount] &],
    fail["TangentialJunctionDownstreamTermsInvalid"]];
  selectedDownstream = Select[downstreamTerms,
    #["OutputOrder"] === outputOrder &];

  combinedDeck = binding["CombinedModeMap"];
  selectorIndex = binding["RegularizedInverseSelectorIndex"];
  Clear[junctionMap];
  junctionMap[downstreamOrder_Integer, upstreamOrder_Integer] :=
    junctionMap[downstreamOrder, upstreamOrder] = Module[
      {localSelectors, products},
      localSelectors = Lookup[selectorIndex, downstreamOrder, <||>];
      products = Cases[KeyValueMap[Function[{shift, modeMap},
          With[{inverse = Lookup[localSelectors,
              upstreamOrder + shift, Missing[]]},
            If[MissingQ[inverse], Nothing, inverse . modeMap]]],
          combinedDeck], _?MatrixQ];
      If[products === {},
        SparseArray[{}, {downstreamBoundaryCount, modeCount}],
        SparseArray[Total[products]]]
    ];

  harvested = Reap[
    Do[With[{junction = junctionMap[
          downstream["BoundaryOrder"], upstream["OutputOrder"]]},
      If[tangentialJunctionNonzeroQ[junction],
        With[{map = SparseArray[(downstream["Map"] . junction) .
              upstream["Map"]]},
          If[tangentialJunctionNonzeroQ[map], Sow[<|
            "BoundaryOrder" -> upstream["BoundaryOrder"],
            "OutputOrder" -> outputOrder,
            "UpstreamWord" -> upstream["Word"],
            "DownstreamWord" -> downstream["Word"],
            "Map" -> map|>]]]]],
      {downstream, selectedDownstream}, {upstream, upstreamTerms}]
  ][[2]];
  raw = If[harvested === {}, {}, First[harvested]];
  groups = GatherBy[raw, {#["BoundaryOrder"], #["UpstreamWord"],
        #["DownstreamWord"]} &];
  merged = Select[Map[Function[group, With[
        {map = SparseArray[Total[Lookup[group, "Map"]]]},
        Join[KeyDrop[First[group], "Map"], <|"Map" -> map|>]]], groups],
    tangentialJunctionNonzeroQ[#1["Map"]] &];
  activeColumns = If[merged === {}, {},
    Sort@DeleteDuplicates@Flatten[
      SparseArray[#1["Map"]]["NonzeroPositions"][[All, 2]] & /@ merged]];

  <|"Status" -> "TangentialJunctionWordsComposed",
    "OutputOrder" -> outputOrder,
    "Scope" -> binding["Scope"],
    "ModeExponents" -> binding["ModeExponents"],
    "BoundaryCoordinateKeys" -> binding["BoundaryCoordinateKeys"],
    "ActiveBoundaryColumns" -> activeColumns,
    "SegmentedWordConvention" -> binding["SegmentedWordConvention"],
    "TermCount" -> Length[merged],
    "Terms" -> merged|>
];

ComposeTangentialJunctionWordMaps[___] :=
  <|"Status" -> "TangentialJunctionWordInputsNotWellFormed"|>;
