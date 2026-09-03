(* Requested physical coefficients from the lazy final-layer operator.

   A singular-boundary mode basis supplies one shared vector of period
   coordinates.  The final-layer operator supplies sparse word maps.  This
   module composes them only for one requested epsilon order and physical row,
   applies an optional epsilon-dependent output gauge, and expands factor
   letters only in the surviving words. *)

Clear[AttachTransportBoundaryToRationalLayer,
  BuildPhysicalTransportCoefficient];
ClearAll[physicalTransportNonzeroQ, physicalTransportActiveColumns,
  physicalTransportLedger];

physicalTransportNonzeroQ[value_] :=
  Length[SparseArray[value]["NonzeroPositions"]] > 0;

physicalTransportActiveColumns[vectors_List] := If[vectors === {}, {},
  Sort@DeleteDuplicates@Flatten[
    SparseArray[#]["NonzeroPositions"][[All, 1]] & /@ vectors]];

physicalTransportLedger[boundary_Association, activeColumns_List] := Module[
  {coordinates, activeCoordinates, ledger, filtered},
  coordinates = Lookup[boundary, "BoundaryCoordinates", {}];
  If[! ListQ[coordinates] ||
      ! AllTrue[activeColumns, 1 <= # <= Length[coordinates] &],
    Return[<|"Status" -> "Stage3LedgerUnavailable"|>]];
  activeCoordinates = If[activeColumns === {}, {},
    ({#["PeriodID"], #["EpsilonOrder"]} &) /@
      coordinates[[activeColumns]]];
  ledger = Lookup[boundary, "Stage3NeedsLedger", {}];
  filtered = Select[Map[Function[item, Module[{affected},
      affected = Intersection[
        Lookup[item, "AffectedBoundaryCoordinates", {}],
        activeCoordinates];
      Join[item, <|"AffectedBoundaryCoordinates" -> affected|>]
    ]], ledger],
    Lookup[#, "AffectedBoundaryCoordinates", {}] =!= {} &];
  <|"Status" -> "Stage3NeedsPrunedByTransport",
    "ActiveBoundaryColumns" -> activeColumns,
    "ActiveBoundaryCoordinates" -> activeCoordinates,
    "UnevaluatedCoordinates" -> Cases[
      Transpose[{coordinates, Lookup[boundary,
        "BoundaryConstantVector", {}]}][[activeColumns]],
      {coordinate_, value_ /; ! FreeQ[value, _BoundaryPeriodCoefficient]} :>
        <|"PeriodID" -> coordinate["PeriodID"],
          "PeriodClass" -> coordinate["PeriodClass"],
          "EpsilonOrder" -> coordinate["EpsilonOrder"],
          "Placeholder" -> value|>],
    "Ledger" -> filtered|>
];

(* Split a full-system physical boundary selector into source and final-layer
   rows without duplicating its period coordinates. *)
AttachTransportBoundaryToRationalLayer[source_Association,
    layer_Association, boundary_Association, sourceRows_List,
    targetRows_List] := Catch@Module[
  {fail, status, dimension, selectors, columnCounts, coordinates, sourceDimension,
   targetDimension, sourceSelectors, targetSelectors},
  fail[name_, extra_: <||>] := Throw[Join[<|"Status" -> name|>, extra]];
  status = Lookup[boundary, "Status", None];
  If[! MemberQ[{"TransportBoundaryVectorBuilt",
        "FormalTransportBoundaryVectorBuilt"}, status],
    fail["TransportBoundaryVectorRequired"]];
  dimension = Lookup[boundary, "Dimension", Missing[]];
  selectors = Lookup[boundary, "BoundarySelectors", Missing[]];
  sourceDimension = Lookup[source, "Dimension", Missing[]];
  targetDimension = Length[Lookup[layer, "Rows", {}]];
  If[! IntegerQ[dimension] || dimension < 1 ||
      ! AssociationQ[selectors] || selectors === <||> ||
      ! IntegerQ[sourceDimension] || sourceDimension < 1 ||
      targetDimension < 1 || Length[sourceRows] =!= sourceDimension ||
      Length[targetRows] =!= targetDimension ||
      ! DuplicateFreeQ[Join[sourceRows, targetRows]] ||
      ! AllTrue[Join[sourceRows, targetRows],
        IntegerQ[#] && 1 <= # <= dimension &] ||
      ! AllTrue[Values[selectors],
        MatrixQ[#] && Dimensions[#][[1]] === dimension &],
    fail["TransportBoundaryLayerLayoutInvalid"]];
  columnCounts = DeleteDuplicates[Dimensions[#][[2]] & /@ Values[selectors]];
  coordinates = Lookup[boundary, "BoundaryCoordinates", Missing[]];
  If[Length[columnCounts] =!= 1 ||
      Length[Lookup[boundary, "BoundaryConstantVector", {}]] =!=
        First[columnCounts] || ! ListQ[coordinates] ||
      Length[coordinates] =!= First[columnCounts] ||
      ! AllTrue[coordinates, AssociationQ[#] &&
        KeyExistsQ[#, "PeriodID"] && KeyExistsQ[#, "EpsilonOrder"] &],
    fail["TransportBoundaryColumnLayoutInvalid"]];
  sourceSelectors = Association@KeyValueMap[
    #1 -> SparseArray[#2[[sourceRows, All]]] &, selectors];
  targetSelectors = Association@KeyValueMap[
    #1 -> SparseArray[#2[[targetRows, All]]] &, selectors];
  <|"Status" -> "TransportBoundaryAttachedToRationalLayer",
    "Source" -> Join[source,
      <|"BoundarySelectors" -> sourceSelectors,
        "PhysicalBoundaryRows" -> sourceRows,
        "PhysicalBoundaryDimension" -> dimension,
        "BoundaryCoordinateKeys" ->
          ({#["PeriodID"], #["EpsilonOrder"]} &) /@
            coordinates|>],
    "Layer" -> Join[layer, <|
      "TargetBoundarySelectors" -> targetSelectors,
      "PhysicalBoundaryRows" -> targetRows,
      "SharedBoundaryCoordinates" -> True|>],
    "Boundary" -> boundary,
    "SourceRows" -> sourceRows, "TargetRows" -> targetRows|>
];

AttachTransportBoundaryToRationalLayer[___] :=
  <|"Status" -> "TransportBoundaryLayerInputsNotWellFormed"|>;

Options[BuildPhysicalTransportCoefficient] = {
  "OutputGaugeByOrder" -> Automatic,
  "CompositeDefinitions" -> <||>,
  "MaximumTerms" -> Infinity,
  "MaximumStates" -> 200000,
  "MaximumExpandedTerms" -> Infinity,
  "ExpandFactorLetters" -> True
};

BuildPhysicalTransportCoefficient[operator_Association,
    boundary_Association, {outputOrder_Integer, outputRow_Integer},
    path_Association, OptionsPattern[]] := Catch@Module[
  {fail, dimensions, constants, variable, base, endpoint, curve,
   curvePointValues,
   definitions, outputGauge, gaugeOrders, physicalDimension,
   maximumExpandedTerms, expandQ, rawStore, rawCount = 0,
   demandTerms, matrix, vector, word, expanded, expandedStore,
   expandedCount = 0, merged, surviving, activeColumns, stage3,
   paperTerms, functionSpace, expression, integral, binding,
   coordinateKeys, boundarySelectors, operatorPath, activeTargetRows},
  fail[name_, extra_: <||>] := Throw[Join[<|"Status" -> name|>, extra]];
  If[! AcceptedRationalEpsilonLayerOperatorQ[operator],
    fail["RationalEpsilonLayerOperatorRequired"]];
  If[! MemberQ[{"TransportBoundaryVectorBuilt",
        "FormalTransportBoundaryVectorBuilt"},
      Lookup[boundary, "Status", None]],
    fail["TransportBoundaryVectorRequired"]];
  dimensions = operator["Dimensions"];
  constants = Lookup[boundary, "BoundaryConstantVector", Missing[]];
  If[! ListQ[constants] ||
      Length[constants] =!= dimensions["TotalBoundary"],
    fail["PhysicalBoundaryDimensionMismatch"]];
  binding = Lookup[operator, "PhysicalBoundaryBinding", None];
  coordinateKeys = ({#["PeriodID"], #["EpsilonOrder"]} &) /@
    Lookup[boundary, "BoundaryCoordinates", {}];
  boundarySelectors = Lookup[boundary, "BoundarySelectors", <||>];
  If[! AssociationQ[binding] ||
      Lookup[binding, "Dimension", None] =!= Lookup[boundary, "Dimension", None] ||
      Lookup[binding, "CoordinateKeys", None] =!= coordinateKeys ||
      ! AssociationQ[boundarySelectors] ||
      Sort[Keys[operator["SourceBoundarySelectors"]]] =!=
        Sort[Keys[boundarySelectors]] ||
      Sort[Keys[operator["TargetBoundarySelectors"]]] =!=
        Sort[Keys[boundarySelectors]] ||
      ! AllTrue[Keys[boundarySelectors], Function[order,
        Normal[operator["SourceBoundarySelectors"][order]] ===
          Normal[boundarySelectors[order][[binding["SourceRows"], All]]] &&
        Normal[operator["TargetBoundarySelectors"][order]] ===
          Normal[boundarySelectors[order][[binding["TargetRows"], All]]]
      ]],
    fail["PhysicalBoundaryNotBoundToOperator"]];
  variable = Lookup[path, "Variable", Missing[]];
  base = Lookup[path, "BasePoint", Missing[]];
  endpoint = Lookup[path, "Endpoint", Missing[]];
  curve = Lookup[path, "Curve", None];
  curvePointValues = Lookup[path, "CurvePointValues", <||>];
  If[! MatchQ[variable, _Symbol] || MissingQ[base] || MissingQ[endpoint] ||
      ! FreeQ[base, variable] || ! FreeQ[endpoint, variable] ||
      (curve =!= None && (! PolynomialQ[curve, variable] ||
        Exponent[curve, variable] =!= 4)) ||
      ! AssociationQ[curvePointValues],
    fail["PhysicalTransportPathInvalid"]];
  operatorPath = Lookup[operator, "Path", <||>];
  If[Lookup[operatorPath, "Variable", Missing[]] =!= variable ||
      Lookup[operatorPath, "BasePoint", Missing[]] =!= base ||
      Lookup[operatorPath, "Endpoint", Missing[]] =!= endpoint ||
      Lookup[operatorPath, "Curve", None] =!= curve ||
      Lookup[operatorPath, "CurvePointValues", <||>] =!= curvePointValues,
    fail["PhysicalTransportPathDoesNotMatchOperator"]];
  definitions = OptionValue["CompositeDefinitions"];
  If[! AssociationQ[definitions],
    fail["CompositeLetterDefinitionsInvalid"]];
  outputGauge = Replace[OptionValue["OutputGaugeByOrder"],
    Automatic -> <|0 -> IdentityMatrix[dimensions["Target"]]|>];
  If[! AssociationQ[outputGauge] || outputGauge === <||> ||
      ! AllTrue[Keys[outputGauge], IntegerQ] ||
      ! AllTrue[Values[outputGauge], MatrixQ[#] &&
        Dimensions[#][[2]] === dimensions["Target"] &],
    fail["PhysicalOutputGaugeInvalid"]];
  physicalDimension = Dimensions[First[Values[outputGauge]]][[1]];
  If[! AllTrue[Values[outputGauge],
        Dimensions[#][[1]] === physicalDimension &] ||
      ! 1 <= outputRow <= physicalDimension,
    fail["PhysicalOutputRowInvalid"]];
  gaugeOrders = Keys[outputGauge];
  maximumExpandedTerms = OptionValue["MaximumExpandedTerms"];
  expandQ = TrueQ[OptionValue["ExpandFactorLetters"]];
  If[! (maximumExpandedTerms === Infinity ||
      IntegerQ[maximumExpandedTerms] && maximumExpandedTerms >= 1),
    fail["PhysicalExpandedTermLimitInvalid"]];

  Do[
    activeTargetRows = DeleteDuplicates[
      SparseArray[outputGauge[gaugeOrder][[{outputRow}, All]]][
        "NonzeroPositions"][[All, 2]]];
    If[activeTargetRows === {}, Continue[]];
    demandTerms = RationalEpsilonLayerDemandTerms[operator,
      {outputOrder - gaugeOrder, activeTargetRows},
      "MaximumTerms" -> OptionValue["MaximumTerms"],
      "MaximumStates" -> OptionValue["MaximumStates"]];
    If[Lookup[demandTerms, "Status", None] =!=
        "RationalEpsilonLayerDemandTermsBuilt",
      fail[Lookup[demandTerms, "Status",
        "RationalLayerDemandFailed"], KeyDrop[demandTerms, "Status"]]];
    Do[
      matrix = outputGauge[gaugeOrder][[{outputRow}, activeTargetRows]] .
        term["Coefficient"];
      If[! physicalTransportNonzeroQ[matrix], Continue[]];
      rawCount++;
      rawStore[rawCount] = <|"Word" -> term["Word"],
        "Coefficient" -> First[Normal[matrix]]|>,
      {term, demandTerms["Terms"]}],
    {gaugeOrder, gaugeOrders}];

  Do[
    word = rawStore[index]["Word"];
    vector = rawStore[index]["Coefficient"];
    expanded = If[expandQ,
      ExpandTransportWordLetters[word, variable, curve, definitions],
      <|"Status" -> "TransportWordExpanded", "Terms" -> {{1, word}}|>];
    If[Lookup[expanded, "Status", None] =!= "TransportWordExpanded",
      fail[Lookup[expanded, "Status", "TransportWordExpansionFailed"],
        KeyDrop[expanded, "Status"]]];
    Do[
      expandedCount++;
      If[maximumExpandedTerms =!= Infinity &&
          expandedCount > maximumExpandedTerms,
        fail["PhysicalWordExpansionCapped",
          <|"MaximumExpandedTerms" -> maximumExpandedTerms,
            "ExpandedTermsBuilt" -> expandedCount - 1|>]];
      expandedStore[expandedCount] = expandedTerm[[2]] ->
        SparseArray[expandedTerm[[1]] vector],
      {expandedTerm, expanded["Terms"]}],
    {index, rawCount}];
  merged = If[expandedCount === 0, <||>,
    Merge[Table[expandedStore[index], {index, expandedCount}], Total]];
  surviving = Select[merged, physicalTransportNonzeroQ];
  activeColumns = physicalTransportActiveColumns[Normal /@ Values[surviving]];
  stage3 = physicalTransportLedger[boundary, activeColumns];
  If[Lookup[stage3, "Status", None] =!=
      "Stage3NeedsPrunedByTransport",
    fail["Stage3LedgerUnavailable"]];
  integral[{}] := 1;
  integral[w_List] := TransportIteratedIntegral[
    w, {variable, base, endpoint}, curve, curvePointValues];
  paperTerms = KeyValueMap[Function[{markedWord, coefficientVector},
      <|"Word" -> markedWord,
        "CoefficientVector" -> Normal[coefficientVector],
        "BoundaryCoefficient" ->
          Total[Normal[coefficientVector] constants],
        "Function" -> integral[markedWord]|>], surviving];
  expression = Total[(#1["BoundaryCoefficient"] #1["Function"] &) /@
    paperTerms];
  functionSpace = If[AnyTrue[Keys[surviving],
      ! FreeQ[#, {head_String, ___} /;
        StringStartsQ[head, "E4"]] &], "GPL+Elliptic", "GPL"];
  <|"Status" -> "PhysicalTransportCoefficientBuilt",
    "Demand" -> {outputOrder, outputRow},
    "FunctionSpace" -> functionSpace,
    "BoundaryDataStatus" -> Lookup[boundary, "BoundaryDataStatus", None],
    "Path" -> <|"Variable" -> variable, "BasePoint" -> base,
      "Endpoint" -> endpoint, "Curve" -> curve,
      "CurvePointValues" -> curvePointValues|>,
    "RawTermCount" -> rawCount,
    "PaperTermCount" -> Length[paperTerms],
    "Terms" -> paperTerms,
    "Expression" -> expression,
    "Stage3" -> stage3|>
];

BuildPhysicalTransportCoefficient[___] :=
  <|"Status" -> "PhysicalTransportCoefficientInputsNotWellFormed"|>;
