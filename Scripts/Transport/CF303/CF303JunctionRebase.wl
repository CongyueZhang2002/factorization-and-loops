(* CF303 family-side rebase of the accepted lazy normal-path operator.

   The singular junction supplies Laurent decks V_S(eps,p) and
   V_G(eps,p) from thirteen physical soft modes to the 43 source rows and
   the two final G rows.  A physical mode is itself an epsilon series.  The
   selector at state order n is therefore the convolution

       F_n = Sum_r V_r c_(n-r).

   This file expands only that small convolution and substitutes the result
   into the existing lazy operator.  It neither materializes a 45x45
   transport nor restores the retired path-transport package. *)

ClearAll[
  CF303BuildJunctionModeSelectors,
  CF303RebaseLazyAdapterAtJunction,
  CF303AcceptedJunctionRebasedAdapterQ,
  cf303JunctionDeckDimensions,
  cf303JunctionCoordinateKey,
  cf303JunctionConvolutionDeck
];

cf303JunctionCoordinateKey[mode_, order_Integer] :=
  HoldComplete[mode, order];

cf303JunctionDeckDimensions[deck_] := Module[{dimensions},
  If[! AssociationQ[deck] || deck === <||> ||
      ! VectorQ[Keys[deck], IntegerQ] ||
      ! AllTrue[Values[deck], MatrixQ], Return[$Failed]];
  dimensions = DeleteDuplicates[Dimensions /@ Values[deck]];
  If[Length[dimensions] =!= 1, $Failed, First[dimensions]]
];

cf303JunctionConvolutionDeck[deck_Association, modeOrder_List,
    amplitudeOrders_List, coordinateIndex_Association,
    stateOrders_List] := Module[
  {dimensions, rowCount, columnCount, shifts, rules, amplitudeOrder},
  dimensions = cf303JunctionDeckDimensions[deck];
  If[dimensions === $Failed || Last[dimensions] =!= Length[modeOrder],
    Return[$Failed]];
  rowCount = First[dimensions];
  columnCount = Length[coordinateIndex];
  shifts = Keys[deck];
  Association@Table[stateOrder -> (
      rules = Flatten@Table[
        amplitudeOrder = stateOrder - shift;
        If[! MemberQ[amplitudeOrders, amplitudeOrder], {},
          Cases[Most[ArrayRules[SparseArray[deck[shift]]]],
            HoldPattern[{row_Integer, mode_Integer} -> value_] :>
              ({row, Lookup[coordinateIndex,
                  cf303JunctionCoordinateKey[
                    modeOrder[[mode]], amplitudeOrder]]} -> value)]],
        {shift, shifts}];
      SparseArray[rules, {rowCount, columnCount}]),
    {stateOrder, stateOrders}]
];

CF303BuildJunctionModeSelectors[junction_Association,
    amplitudeWindow : {_Integer, _Integer},
    stateWindow : (Automatic | {_Integer, _Integer}) : Automatic] :=
 Catch@Module[
  {fail, sourceDeck, targetDeck, sourceDimensions, targetDimensions,
   modeOrder, amplitudeOrders, coordinates, coordinateKeys,
   coordinateIndex, shifts, completeStateWindow, selectedStateWindow,
   stateOrders, sourceSelectors, targetSelectors},

  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[Lookup[junction, "Status", None] =!=
      "CF303TangentialJunctionMapReconstructedV1",
    fail["CF303TangentialJunctionMapRequired"]];
  If[Last[amplitudeWindow] < First[amplitudeWindow],
    fail["CF303JunctionAmplitudeWindowInvalid"]];
  sourceDeck = Lookup[junction, "SourceModeMap", Missing[]];
  targetDeck = Lookup[junction, "TargetGModeMap", Missing[]];
  sourceDimensions = cf303JunctionDeckDimensions[sourceDeck];
  targetDimensions = cf303JunctionDeckDimensions[targetDeck];
  modeOrder = Lookup[junction, "CombinedModeOrder", Missing[]];
  If[sourceDimensions === $Failed || targetDimensions === $Failed ||
      ! ListQ[modeOrder] || ! DuplicateFreeQ[modeOrder] ||
      Last[sourceDimensions] =!= Length[modeOrder] ||
      Last[targetDimensions] =!= Length[modeOrder],
    fail["CF303JunctionModeDeckInvalid"]];

  amplitudeOrders = Range @@ amplitudeWindow;
  coordinates = Flatten[Table[<|"ModeID" -> mode,
      "EpsilonOrder" -> order|>, {order, amplitudeOrders},
      {mode, modeOrder}], 1];
  coordinateKeys = ({#ModeID, #EpsilonOrder} &) /@ coordinates;
  coordinateIndex = AssociationThread[
    (cf303JunctionCoordinateKey[#ModeID, #EpsilonOrder] &) /@
      coordinates, Range[Length[coordinates]]];
  shifts = Union[Keys[sourceDeck], Keys[targetDeck]];
  completeStateWindow = {First[amplitudeWindow] + Min[shifts],
    Last[amplitudeWindow] + Max[shifts]};
  selectedStateWindow = Replace[stateWindow, Automatic -> completeStateWindow];
  If[Last[selectedStateWindow] < First[selectedStateWindow] ||
      First[selectedStateWindow] < First[completeStateWindow] ||
      Last[selectedStateWindow] > Last[completeStateWindow],
    fail["CF303JunctionStateWindowInvalid", <|
      "CompleteStateWindow" -> completeStateWindow|>]];
  stateOrders = Range @@ selectedStateWindow;
  sourceSelectors = cf303JunctionConvolutionDeck[sourceDeck, modeOrder,
    amplitudeOrders, coordinateIndex, stateOrders];
  targetSelectors = cf303JunctionConvolutionDeck[targetDeck, modeOrder,
    amplitudeOrders, coordinateIndex, stateOrders];
  If[sourceSelectors === $Failed || targetSelectors === $Failed,
    fail["CF303JunctionSelectorConvolutionFailed"]];

  <|"Status" -> "CF303JunctionModeSelectorsBuiltV1",
    "ModeOrder" -> modeOrder,
    "AmplitudeOrderWindow" -> amplitudeWindow,
    "StateOrderWindow" -> selectedStateWindow,
    "BoundaryCoordinates" -> coordinates,
    "BoundaryCoordinateKeys" -> coordinateKeys,
    "SourceModeMap" -> sourceDeck,
    "TargetGModeMap" -> targetDeck,
    "SourceBoundarySelectors" -> sourceSelectors,
    "TargetGBoundarySelectors" -> targetSelectors,
    "Dimensions" -> <|"SourceState" -> First[sourceDimensions],
      "TargetGState" -> First[targetDimensions],
      "ModeCount" -> Length[modeOrder],
      "BoundaryCoordinateCount" -> Length[coordinates]|>|>
];

CF303BuildJunctionModeSelectors[___] :=
  <|"Status" -> "CF303JunctionModeSelectorInputsNotWellFormed"|>;

CF303RebaseLazyAdapterAtJunction[adapter_Association,
    junction_Association, amplitudeWindow : {_Integer, _Integer}] :=
 Catch@Module[
  {fail, selectors, sourceArtifact, sourceOperator, gOperator,
   coordinateKeys, boundaryCount, oldPath, variable, pathEndpoint,
   newBasePoint, basePointPrescription, newPath, rebased},

  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[Lookup[adapter, "Status", None] =!=
      "CF303HybridBaselineLazyCircuitAdapterAcceptedV1",
    fail["CF303AcceptedLazyAdapterRequired"]];
  selectors = CF303BuildJunctionModeSelectors[
    junction, amplitudeWindow];
  If[Lookup[selectors, "Status", None] =!=
      "CF303JunctionModeSelectorsBuiltV1", Throw[selectors]];

  sourceArtifact = Lookup[adapter, "SourceArtifact", Missing[]];
  sourceOperator = If[AssociationQ[sourceArtifact],
    Lookup[sourceArtifact, "Operator", Missing[]], Missing[]];
  gOperator = Lookup[adapter, "GOperator", Missing[]];
  If[! AssociationQ[sourceArtifact] || ! AssociationQ[sourceOperator] ||
      ! AssociationQ[gOperator] ||
      Lookup[gOperator, "SourceN", None] =!=
        selectors["Dimensions", "SourceState"] ||
      Length[Lookup[adapter, "TargetRows", {}]] =!=
        selectors["Dimensions", "TargetGState"],
    fail["CF303LazyAdapterJunctionLayoutMismatch"]];

  oldPath = Lookup[sourceArtifact, "Path", <||>];
  variable = Lookup[oldPath, "Variable", Missing[]];
  pathEndpoint = Lookup[oldPath, "PathEndpoint",
    Lookup[oldPath, "Endpoint", Missing[]]];
  newBasePoint = 2 Global`p;
  basePointPrescription = <|
    "Type" -> "TangentialRegularized",
    "LocalCoordinate" -> Global`rho,
    "CoordinateRelation" -> HoldForm[
      Global`rho == newBasePoint - variable],
    "LocalDirection" -> -1|>;
  If[! MatchQ[variable, _Symbol] || MissingQ[pathEndpoint] ||
      ! FreeQ[pathEndpoint, variable],
    fail["CF303LazyAdapterPathInvalid"]];
  newPath = <|
    "Variable" -> variable,
    "BasePoint" -> newBasePoint,
    "PathEndpoint" -> pathEndpoint,
    "BasePointPrescription" -> basePointPrescription,
    "Curve" -> Lookup[adapter, "Curve", None]|>;

  coordinateKeys = selectors["BoundaryCoordinateKeys"];
  boundaryCount = Length[coordinateKeys];
  sourceOperator = Join[sourceOperator, <|
    "BoundaryColumns" -> coordinateKeys,
    "BoundarySelectors" -> selectors["SourceBoundarySelectors"],
    "Path" -> newPath,
    "IteratedIntegralConvention" ->
      "Formal Chen iterated integrals along the recorded path, with the letter sequence outermost first"|>];
  sourceArtifact = Join[sourceArtifact, <|
    "Operator" -> sourceOperator, "Path" -> newPath|>];
  gOperator = Join[gOperator, <|
    "SourceArtifact" -> sourceArtifact,
    "SourceBoundaryCount" -> boundaryCount,
    "BoundaryColumns" -> coordinateKeys,
    "TargetBoundaryColumns" -> coordinateKeys,
    "TargetBoundarySelectors" -> selectors["TargetGBoundarySelectors"],
    "BoundaryLayout" -> "SharedJunctionModes",
    "Path" -> newPath|>];
  rebased = Join[adapter, <|
    "Status" -> "CF303JunctionRebasedLazyAdapterV1",
    "SourceArtifact" -> sourceArtifact,
    "GOperator" -> gOperator,
    "Path" -> newPath,
    "BoundaryColumns" -> coordinateKeys,
    "BoundaryConvention" ->
      "Thirteen soft-mode epsilon series at the tangential base z=2p",
    "JunctionRebase" -> <|
      "Status" -> "ExactSparseLaurentInitialDataAtTangentialBasePoint",
      "MathematicalOperation" ->
        "Solve the same G-basis differential system with its lower limit and local initial data at z=2p",
      "BasePoint" -> newBasePoint,
      "BasePointPrescription" -> basePointPrescription,
      "Selectors" -> selectors,
      "OffDiagonalTransformationNormalizationBasePoint" -> 1/2,
      "TargetRepresentation" -> "G25"|>|>];
  If[! CF303AcceptedJunctionRebasedAdapterQ[rebased],
    fail["CF303JunctionRebasedAdapterConstructionFailed"]];
  rebased
];

CF303RebaseLazyAdapterAtJunction[___] :=
  <|"Status" -> "CF303JunctionRebaseInputsNotWellFormed"|>;

CF303AcceptedJunctionRebasedAdapterQ[adapter_] :=
  AssociationQ[adapter] &&
  Lookup[adapter, "Status", None] ===
    "CF303JunctionRebasedLazyAdapterV1" &&
  AssociationQ[Lookup[adapter, "SourceArtifact", None]] &&
  AssociationQ[Lookup[adapter, "GOperator", None]] &&
  AssociationQ[Lookup[adapter, "Path", None]] &&
  AssociationQ[Lookup[adapter, "JunctionRebase", None]] &&
  Lookup[adapter["SourceArtifact"], "Path", Missing[]] ===
    adapter["Path"] &&
  Lookup[adapter["GOperator"], "Path", Missing[]] === adapter["Path"] &&
  Lookup[adapter["Path"], "BasePointPrescription", <||>]["Type"] ===
    "TangentialRegularized" &&
  Lookup[adapter, "BoundaryColumns", {}] ===
    Lookup[adapter["GOperator"], "BoundaryColumns", Missing[]] &&
  Length[Lookup[adapter, "BoundaryColumns", {}]] ===
    Lookup[adapter["GOperator"], "SourceBoundaryCount", Missing[]];

CF303AcceptedJunctionRebasedAdapterQ[___] := False;
