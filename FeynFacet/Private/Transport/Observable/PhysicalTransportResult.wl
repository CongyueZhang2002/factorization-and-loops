(* Requested master-integral epsilon-expansion coefficients from the lazy
   rational-epsilon-dependent-block coefficient operator.

   Boundary-value data supply one shared vector of boundary-constant or
   boundary-function epsilon coefficients. The block operator supplies sparse
   iterated-integral coefficient maps. This
   module composes them only for one requested epsilon order and master-integral row,
   applies an optional epsilon-dependent output basis transformation, and
   expands factor letters only in the surviving letter sequences. *)

Clear[AttachBoundarySelectorsToRationalEpsilonDependentBlock,
  ConstructMasterIntegralEpsilonExpansionCoefficient];
ClearAll[masterIntegralCoefficientNonzeroQ,
  masterIntegralCoefficientActiveColumns,
  masterIntegralCoefficientBoundaryRequirements];

masterIntegralCoefficientNonzeroQ[value_] :=
  Length[SparseArray[value]["NonzeroPositions"]] > 0;

masterIntegralCoefficientActiveColumns[vectors_List] := If[vectors === {}, {},
  Sort@DeleteDuplicates@Flatten[
    SparseArray[#]["NonzeroPositions"][[All, 1]] & /@ vectors]];

masterIntegralCoefficientBoundaryRequirements[
    boundary_Association, activeColumns_List] := Module[
  {boundaryDataType, recordsKey, labelsKey, valueVectorKey,
   records, activeLabels, requirements, filtered},
  boundaryDataType = Lookup[boundary, "BoundaryDataType", Missing[]];
  If[! MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType],
    Return[<|"Status" -> "BoundaryDataTypeRequired"|>]];
  recordsKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientRecords",
    "BoundaryFunctionEpsilonCoefficientRecords"];
  labelsKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientLabels",
    "BoundaryFunctionEpsilonCoefficientLabels"];
  valueVectorKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantVector", "BoundaryFunctionVector"];
  records = Lookup[boundary, recordsKey, {}];
  If[! ListQ[records] ||
      ! AllTrue[activeColumns, 1 <= # <= Length[records] &],
    Return[<|"Status" -> "BoundaryDataRequirementsUnavailable"|>]];
  activeLabels = If[activeColumns === {}, {},
    Lookup[boundary, labelsKey, {}][[activeColumns]]];
  requirements = Lookup[boundary, "BoundaryDataRequirements", {}];
  filtered = Select[Map[Function[item, Module[{affected},
      affected = Intersection[
        Lookup[item, labelsKey, {}], activeLabels];
      Join[item, <|labelsKey -> affected|>]
    ]], requirements], Lookup[#, labelsKey, {}] =!= {} &];
  <|"Status" -> "BoundaryDataRequirementsRestrictedToActiveCoefficients",
    "BoundaryDataType" -> boundaryDataType,
    "ActiveBoundaryColumns" -> activeColumns,
    "ActiveBoundaryEpsilonCoefficientLabels" -> activeLabels,
    "UnevaluatedBoundaryDataCoefficients" -> Cases[
      Transpose[{records,
        Lookup[boundary, valueVectorKey, {}]}][[activeColumns]],
      {record_, value_ /;
          ! FreeQ[value, _BoundaryConstantEpsilonCoefficient |
            _BoundaryFunctionEpsilonCoefficient]} :>
        Join[KeyTake[record, {"BoundaryDataType", "BoundaryConstantID",
            "BoundaryFunctionID", "DeclaredBoundaryConstantAnalyticClass",
            "DeclaredBoundaryFunctionClass", "EpsilonOrder"}],
          <|
          "Placeholder" -> value|>]],
    "BoundaryDataRequirements" -> filtered|>
];

(* Split full-system boundary selector matrices into source and block rows
   without duplicating their boundary-data coefficient labels. *)
AttachBoundarySelectorsToRationalEpsilonDependentBlock[source_Association,
    layer_Association, boundarySelectors_Association, sourceRows_List,
    targetRows_List] := Catch@Module[
  {fail, status, dimension, selectors, columnCounts, labels,
   labelsKey, boundaryDataType, sourceDimension, targetDimension,
   sourceSelectors, targetSelectors},
  fail[name_, extra_: <||>] := Throw[Join[<|"Status" -> name|>, extra]];
  status = Lookup[boundarySelectors, "Status", None];
  If[! MemberQ[{"BoundarySelectorMatricesConstructed",
        "FormalBoundarySelectorMatricesConstructed"}, status],
    fail["BoundarySelectorMatricesRequired"]];
  boundaryDataType = Lookup[boundarySelectors, "BoundaryDataType", Missing[]];
  If[! MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType],
    fail["BoundaryDataTypeRequired"]];
  labelsKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientLabels",
    "BoundaryFunctionEpsilonCoefficientLabels"];
  labels = Lookup[boundarySelectors, labelsKey, Missing[]];
  selectors = Lookup[boundarySelectors,
    "BoundarySelectorMatricesByEpsilonOrder", Missing[]];
  sourceDimension = Lookup[source, "Dimension", Missing[]];
  targetDimension = Length[Lookup[layer, "Rows", {}]];
  If[! AssociationQ[selectors] || selectors === <||> ||
      ! IntegerQ[sourceDimension] || sourceDimension < 1 ||
      targetDimension < 1 || Length[sourceRows] =!= sourceDimension ||
      Length[targetRows] =!= targetDimension ||
      ! DuplicateFreeQ[Join[sourceRows, targetRows]] ||
      ! AllTrue[Values[selectors], MatrixQ[#] &],
    fail["BoundarySelectorBlockRowLayoutInvalid"]];
  dimension = First[Dimensions /@ Values[selectors]][[1]];
  If[dimension < 1 ||
      ! AllTrue[Join[sourceRows, targetRows],
        IntegerQ[#] && 1 <= # <= dimension &] ||
      ! AllTrue[Values[selectors],
      Dimensions[#][[1]] === dimension &],
    fail["BoundarySelectorBlockRowLayoutInvalid"]];
  columnCounts = DeleteDuplicates[Dimensions[#][[2]] & /@ Values[selectors]];
  If[Length[columnCounts] =!= 1 || ! ListQ[labels] ||
      Length[labels] =!= First[columnCounts],
    fail["BoundarySelectorCoefficientColumnLayoutInvalid"]];
  sourceSelectors = Association@KeyValueMap[
    #1 -> SparseArray[#2[[sourceRows, All]]] &, selectors];
  targetSelectors = Association@KeyValueMap[
    #1 -> SparseArray[#2[[targetRows, All]]] &, selectors];
  <|"Status" ->
      "BoundarySelectorsAttachedToRationalEpsilonDependentBlock",
    "Source" -> Join[source,
      <|"BoundarySelectors" -> sourceSelectors,
        "BoundarySelectorSourceRows" -> sourceRows,
        "BoundarySelectorDimension" -> dimension,
        "BoundaryDataType" -> boundaryDataType,
        labelsKey -> labels|>],
    "Block" -> Join[layer, <|
      "TargetBoundarySelectors" -> targetSelectors,
      "BoundarySelectorTargetRows" -> targetRows,
      "SharedBoundaryCoordinates" -> True|>],
    "BoundarySelectorData" -> boundarySelectors,
    "SourceRows" -> sourceRows, "TargetRows" -> targetRows|>
];

AttachBoundarySelectorsToRationalEpsilonDependentBlock[___] :=
  <|"Status" ->
    "BoundarySelectorBlockAttachmentInputsNotWellFormed"|>;

Options[ConstructMasterIntegralEpsilonExpansionCoefficient] = {
  "CanonicalToPhysicalMasterIntegralMapByEpsilonOrder" -> Automatic,
  "CompositeDefinitions" -> <||>,
  "MaximumTerms" -> Infinity,
  "MaximumStates" -> 200000,
  "MaximumExpandedTerms" -> Infinity,
  "ExpandFactorLetters" -> True
};

ConstructMasterIntegralEpsilonExpansionCoefficient[operator_Association,
    boundary_Association, {outputOrder_Integer, outputRow_Integer},
    path_Association, OptionsPattern[]] := Catch@Module[
  {fail, dimensions, constants, variable, base, endpoint, curve,
   curvePointValues, basePointPrescription,
   definitions, canonicalToPhysicalMap, mapOrders, physicalDimension,
   maximumExpandedTerms, expandQ, rawStore, rawCount = 0,
   coefficientMapResult, coefficientMap, matrix, vector, letterSequence,
   expanded, expandedStore, expandedCount = 0, merged, surviving,
   activeColumns, activeBoundaryRequirements, iteratedIntegralTerms,
   functionSpace, expression, integral, binding, boundaryDataType,
   coefficientLabelsKey, valueVectorKey, coefficientLabels, operatorPath,
   activeTargetRows, basePointChange, boundSourceSelectors,
   boundTargetSelectors},
  fail[name_, extra_: <||>] := Throw[Join[<|"Status" -> name|>, extra]];
  If[! RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[operator],
    fail["RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorRequired"]];
  If[! MemberQ[{"BoundaryConstantValueVectorConstructed",
        "FormalBoundaryConstantValueVectorConstructed",
        "BoundaryFunctionValueVectorConstructed",
        "FormalBoundaryFunctionValueVectorConstructed"},
      Lookup[boundary, "Status", None]],
    fail["BoundaryValueVectorRequired"]];
  dimensions = operator["Dimensions"];
  boundaryDataType = Lookup[boundary, "BoundaryDataType", Missing[]];
  If[! MemberQ[{"BoundaryConstant", "BoundaryFunction"}, boundaryDataType],
    fail["BoundaryDataTypeRequired"]];
  coefficientLabelsKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantEpsilonCoefficientLabels",
    "BoundaryFunctionEpsilonCoefficientLabels"];
  valueVectorKey = If[boundaryDataType === "BoundaryConstant",
    "BoundaryConstantVector", "BoundaryFunctionVector"];
  constants = Lookup[boundary, valueVectorKey, Missing[]];
  coefficientLabels = Lookup[boundary, coefficientLabelsKey, Missing[]];
  If[! ListQ[constants] ||
      ! ListQ[coefficientLabels] ||
      Length[constants] =!= dimensions["TotalBoundary"] ||
      Length[coefficientLabels] =!= Length[constants],
    fail["BoundaryValueVectorDimensionMismatch"]];
  binding = Lookup[operator, "BoundarySelectorBinding", None];
  basePointChange = Lookup[operator, "BasePointChange", None];
  boundSourceSelectors = If[AssociationQ[basePointChange] &&
      Lookup[basePointChange, "Status", None] ===
        "IteratedIntegralCoefficientOperatorBasePointChanged",
    Lookup[basePointChange, "SourceBoundarySelectorsAtNewBasePoint",
      Missing[]],
    operator["SourceBoundarySelectors"]];
  boundTargetSelectors = If[AssociationQ[basePointChange] &&
      Lookup[basePointChange, "Status", None] ===
        "IteratedIntegralCoefficientOperatorBasePointChanged",
    Lookup[basePointChange, "TargetBoundarySelectorsAtNewBasePoint",
      Missing[]],
    operator["TargetBoundarySelectors"]];
  If[! AssociationQ[binding] ||
      Lookup[binding, "Dimension", None] =!=
        Total[{Length[binding["SourceRows"]],
          Length[binding["TargetRows"]]}] ||
      Lookup[binding, "BoundaryDataType", None] =!= boundaryDataType ||
      Lookup[binding, coefficientLabelsKey, None] =!= coefficientLabels ||
      ! AssociationQ[boundSourceSelectors] ||
      ! AssociationQ[boundTargetSelectors] ||
      Sort[Keys[boundSourceSelectors]] =!=
        Sort[Keys[boundTargetSelectors]] ||
      ! AllTrue[Join[Values[boundSourceSelectors],
          Values[boundTargetSelectors]],
        MatrixQ[#] && Dimensions[#][[2]] === Length[constants] &],
    fail["BoundaryValueVectorNotBoundToCoefficientOperator"]];
  variable = Lookup[path, "Variable", Missing[]];
  base = Lookup[path, "BasePoint", Missing[]];
  endpoint = Lookup[path, "PathEndpoint", Missing[]];
  curve = Lookup[path, "Curve", None];
  curvePointValues = Lookup[path, "CurvePointValues", <||>];
  basePointPrescription = Lookup[path, "BasePointPrescription", None];
  If[! MatchQ[variable, _Symbol] || MissingQ[base] || MissingQ[endpoint] ||
      ! FreeQ[base, variable] || ! FreeQ[endpoint, variable] ||
      (curve =!= None && (! PolynomialQ[curve, variable] ||
        Exponent[curve, variable] =!= 4)) ||
      ! AssociationQ[curvePointValues] ||
      (basePointPrescription =!= None &&
        ! (AssociationQ[basePointPrescription] &&
          Lookup[basePointPrescription, "Type", None] ===
            "TangentialRegularized" &&
          MemberQ[{-1, 1}, Lookup[basePointPrescription,
            "LocalDirection", Missing[]]])),
    fail["MasterIntegralSolutionPathInvalid"]];
  operatorPath = Lookup[operator, "Path", <||>];
  If[Lookup[operatorPath, "Variable", Missing[]] =!= variable ||
      Lookup[operatorPath, "BasePoint", Missing[]] =!= base ||
      Lookup[operatorPath, "PathEndpoint", Missing[]] =!= endpoint ||
      Lookup[operatorPath, "Curve", None] =!= curve ||
      Lookup[operatorPath, "CurvePointValues", <||>] =!= curvePointValues ||
      Lookup[operatorPath, "BasePointPrescription", None] =!=
        basePointPrescription,
    fail["MasterIntegralSolutionPathDoesNotMatchCoefficientOperator"]];
  definitions = OptionValue["CompositeDefinitions"];
  If[! AssociationQ[definitions],
    fail["CompositeLetterDefinitionsInvalid"]];
  canonicalToPhysicalMap = Replace[
    OptionValue["CanonicalToPhysicalMasterIntegralMapByEpsilonOrder"],
    Automatic -> <|0 -> IdentityMatrix[dimensions["Target"]]|>];
  If[! AssociationQ[canonicalToPhysicalMap] ||
      canonicalToPhysicalMap === <||> ||
      ! AllTrue[Keys[canonicalToPhysicalMap], IntegerQ] ||
      ! AllTrue[Values[canonicalToPhysicalMap], MatrixQ[#] &&
        Dimensions[#][[2]] === dimensions["Target"] &],
    fail["CanonicalToPhysicalMasterIntegralMapInvalid"]];
  physicalDimension = Dimensions[
    First[Values[canonicalToPhysicalMap]]][[1]];
  If[! AllTrue[Values[canonicalToPhysicalMap],
        Dimensions[#][[1]] === physicalDimension &] ||
      ! 1 <= outputRow <= physicalDimension,
    fail["MasterIntegralRowInvalid"]];
  mapOrders = Keys[canonicalToPhysicalMap];
  maximumExpandedTerms = OptionValue["MaximumExpandedTerms"];
  expandQ = TrueQ[OptionValue["ExpandFactorLetters"]];
  If[! (maximumExpandedTerms === Infinity ||
      IntegerQ[maximumExpandedTerms] && maximumExpandedTerms >= 1),
    fail["MasterIntegralExpandedTermLimitInvalid"]];

  Do[
    activeTargetRows = DeleteDuplicates[
      SparseArray[canonicalToPhysicalMap[mapOrder][[{outputRow}, All]]][
        "NonzeroPositions"][[All, 2]]];
    If[activeTargetRows === {}, Continue[]];
    coefficientMapResult =
      ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[
      operator,
      {outputOrder - mapOrder, activeTargetRows},
      "MaximumTerms" -> OptionValue["MaximumTerms"],
      "MaximumStates" -> OptionValue["MaximumStates"]];
    If[Lookup[coefficientMapResult, "Status", None] =!=
        "RationalEpsilonDependentBlockIteratedIntegralCoefficientMapConstructed",
      fail[Lookup[coefficientMapResult, "Status",
        "IteratedIntegralCoefficientMapConstructionFailed"],
        KeyDrop[coefficientMapResult, "Status"]]];
    coefficientMap = coefficientMapResult[
      "IteratedIntegralCoefficientMap"];
    KeyValueMap[Function[{sequence, coefficientMatrix},
      matrix = canonicalToPhysicalMap[mapOrder][
          [{outputRow}, activeTargetRows]] .
        coefficientMatrix;
      If[masterIntegralCoefficientNonzeroQ[matrix],
        rawCount++;
        rawStore[rawCount] = <|
          "IteratedIntegralLetterSequence" -> sequence,
          "IteratedIntegralCoefficientVector" ->
            First[Normal[matrix]]|>]], coefficientMap],
    {mapOrder, mapOrders}];

  Do[
    letterSequence =
      rawStore[index]["IteratedIntegralLetterSequence"];
    vector = rawStore[index]["IteratedIntegralCoefficientVector"];
    expanded = If[expandQ,
      ExpandIteratedIntegralLetterSequence[
        letterSequence, variable, curve, definitions],
      <|"Status" -> "IteratedIntegralLetterSequenceExpanded",
        "Terms" -> {{1, letterSequence}}|>];
    If[Lookup[expanded, "Status", None] =!=
        "IteratedIntegralLetterSequenceExpanded",
      fail[Lookup[expanded, "Status",
          "IteratedIntegralLetterSequenceExpansionFailed"],
        KeyDrop[expanded, "Status"]]];
    Do[
      expandedCount++;
      If[maximumExpandedTerms =!= Infinity &&
          expandedCount > maximumExpandedTerms,
        fail["MasterIntegralIteratedIntegralExpansionCapped",
          <|"MaximumExpandedTerms" -> maximumExpandedTerms,
            "ExpandedTermsBuilt" -> expandedCount - 1|>]];
      expandedStore[expandedCount] = expandedTerm[[2]] ->
        SparseArray[expandedTerm[[1]] vector],
      {expandedTerm, expanded["Terms"]}],
    {index, rawCount}];
  merged = If[expandedCount === 0, <||>,
    Merge[Table[expandedStore[index], {index, expandedCount}], Total]];
  surviving = Select[merged, masterIntegralCoefficientNonzeroQ];
  activeColumns = masterIntegralCoefficientActiveColumns[
    Normal /@ Values[surviving]];
  activeBoundaryRequirements =
    masterIntegralCoefficientBoundaryRequirements[boundary, activeColumns];
  If[Lookup[activeBoundaryRequirements, "Status", None] =!=
      "BoundaryDataRequirementsRestrictedToActiveCoefficients",
    fail["BoundaryDataRequirementsUnavailable"]];
  integral[{}] := 1;
  integral[w_List] := If[basePointPrescription === None,
    With[{sequenceValue = w, pathValue = {variable, base, endpoint},
        curveValue = curve, pointValues = curvePointValues},
      FeynFacet`FormalChenIteratedIntegral[
        sequenceValue, pathValue, curveValue, pointValues]],
    With[{sequenceValue = w, pathValue = {variable, base, endpoint},
        curveValue = curve, pointValues = curvePointValues,
        prescription = basePointPrescription},
      FeynFacet`FormalChenIteratedIntegral[
        sequenceValue, pathValue, curveValue, pointValues, prescription]]];
  iteratedIntegralTerms = KeyValueMap[
    Function[{markedPointSequence, coefficientVector},
      <|"IteratedIntegralLetterSequence" -> markedPointSequence,
        "BoundaryValueCoefficientVector" -> Normal[coefficientVector],
        "BoundaryValueCoefficient" ->
          Total[Normal[coefficientVector] constants],
        "FormalIteratedIntegral" -> integral[markedPointSequence]|>],
    surviving];
  expression = Total[(#1["BoundaryValueCoefficient"] *
        #1["FormalIteratedIntegral"] &) /@ iteratedIntegralTerms];
  functionSpace = If[AnyTrue[Keys[surviving],
      ! FreeQ[#, {head_String, ___} /;
        StringStartsQ[head, "E4"]] &], "GPL+Elliptic", "GPL"];
  <|"Status" -> "MasterIntegralEpsilonExpansionCoefficientConstructed",
    "EpsilonOrder" -> outputOrder,
    "MasterIntegralRow" -> outputRow,
    "FunctionSpace" -> functionSpace,
    "BoundaryDataStatus" -> Lookup[boundary, "BoundaryDataStatus", None],
    "Path" -> <|"Variable" -> variable, "BasePoint" -> base,
      "PathEndpoint" -> endpoint, "Curve" -> curve,
      "CurvePointValues" -> curvePointValues,
      "BasePointPrescription" -> basePointPrescription|>,
    "RawTermCount" -> rawCount,
    "IteratedIntegralTermCount" -> Length[iteratedIntegralTerms],
    "IteratedIntegralTerms" -> iteratedIntegralTerms,
    "Expression" -> expression,
    "ActiveBoundaryDataRequirements" -> activeBoundaryRequirements|>
];

ConstructMasterIntegralEpsilonExpansionCoefficient[___] :=
  <|"Status" ->
    "MasterIntegralEpsilonExpansionCoefficientInputsNotWellFormed"|>;
