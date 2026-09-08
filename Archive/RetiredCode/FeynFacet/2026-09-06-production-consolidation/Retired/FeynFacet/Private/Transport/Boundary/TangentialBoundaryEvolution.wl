(* Tangential evolution of boundary functions and its composition with a
   requested-output solution map.  The operator convention is

       c(t, eps) = U(t, t0; eps) . c(t0, eps).

   Its coefficient data remain indexed by iterated-integral letter sequences;
   expanded formulas are deliberately not stored. *)

Clear[TangentialBoundaryEvolutionOperatorQ,
  ComposeBoundaryFunctionSolutionMapWithTangentialEvolution];

ClearAll[tangentialEvolutionExactZeroQ, tangentialEvolutionExactSparseMatrix,
  tangentialEvolutionLookup, tangentialEvolutionCoordinateKey,
  tangentialEvolutionPathKey, tangentialEvolutionFailure,
  tangentialEvolutionCoefficientMapQ,
  boundaryFunctionToMasterIntegralSolutionMapQ,
  tangentialEvolutionFunctionIndex, tangentialEvolutionBaseConstantIDs,
  tangentialEvolutionOutputCoordinate, tangentialEvolutionTransformation,
  tangentialEvolutionRequirement];

tangentialEvolutionExactZeroQ[value_] :=
  TrueQ[value === 0] || Quiet[TrueQ[PossibleZeroQ[value]]];

tangentialEvolutionExactSparseMatrix[matrix_?MatrixQ] := Module[
  {sparse = SparseArray[matrix], rules},
  rules = Most[ArrayRules[sparse]];
  SparseArray[Map[First[#] -> Together[Last[#]] &, rules],
    Dimensions[sparse]]
];

(* Lookup treats a list-valued key as a list of separate keys. *)
tangentialEvolutionLookup[association_Association, key_,
    default_: Missing[]] :=
  If[KeyExistsQ[association, key], association[[Key[key]]], default];

tangentialEvolutionCoordinateKey[id_, order_Integer] :=
  HoldComplete[id, order];

tangentialEvolutionPathKey[term_Association, sequence_List] :=
  With[{currentFirst = Lookup[term,
        "CurrentPathFirstSegmentLetterIndices", Missing[]],
      currentSecond = Lookup[term,
        "CurrentPathSecondSegmentLetterIndices", Missing[]],
      boundaryFirst = Lookup[term,
        "BoundaryPathFirstSegmentLetterIndices", Missing[]],
      boundarySecond = Lookup[term,
        "BoundaryPathSecondSegmentLetterIndices", Missing[]]},
    HoldComplete[currentFirst, currentSecond, boundaryFirst, boundarySecond,
      sequence]];

tangentialEvolutionFailure[status_String, extra_: <||>] :=
  Failure[status, Join[<|"Status" -> status|>, extra]];

tangentialEvolutionCoefficientMapQ[map_, dimension_Integer] :=
  AssociationQ[map] && AllTrue[Keys[map], ListQ] &&
    AllTrue[Values[map], MatrixQ[#] &&
      Dimensions[#] === {dimension, dimension} && FreeQ[#, _Real] &];

TangentialBoundaryEvolutionOperatorQ[record_] := Module[
  {requiredKeys, requiredConditions, domain, variables, regulator, ids,
   valuations, idRecords, baseIDs, valuation, window, coefficientMaps,
   validation, conditions, dimension},
  requiredKeys = {
    "DataType", "SchemaVersion", "Status", "Family", "BoundaryDomain",
    "DimensionalRegulator", "BoundaryFunctionIDs",
    "BoundaryFunctionEpsilonValuations", "TangentialBasePoint",
    "TangentialPath",
    "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs",
    "EvolutionOperatorEpsilonValuation", "EpsilonOrderWindow",
    "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder",
    "IteratedIntegralLetterSequenceOrientation", "EvolutionConvention",
    "Validation"};
  requiredConditions = {"BoundaryFunctionDifferentialEquation",
    "TangentialBasePointNormalization", "EpsilonOrderCoverage"};
  If[! AssociationQ[record] || ! ContainsAll[Keys[record], requiredKeys],
    Return[False]];
  domain = record["BoundaryDomain"];
  variables = Lookup[domain, "TangentialVariables", Missing[]];
  regulator = record["DimensionalRegulator"];
  ids = record["BoundaryFunctionIDs"];
  valuations = record["BoundaryFunctionEpsilonValuations"];
  idRecords =
    record["BoundaryFunctionToTangentialBasePointBoundaryConstantIDs"];
  valuation = record["EvolutionOperatorEpsilonValuation"];
  window = record["EpsilonOrderWindow"];
  coefficientMaps =
    record["EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder"];
  validation = record["Validation"];
  conditions = Lookup[validation, "Conditions", <||>];
  dimension = If[ListQ[ids], Length[ids], 0];
  record["DataType"] === "TangentialBoundaryEvolutionOperator" &&
    record["SchemaVersion"] === 2 &&
    record["Status"] === "TangentialBoundaryEvolutionOperatorValidated" &&
    StringQ[record["Family"]] && AssociationQ[domain] &&
    Lookup[domain, "Type", None] === "PhysicalBoundaryStratum" &&
    MatchQ[variables, {__Symbol}] && MatchQ[regulator, _Symbol] &&
    ! MemberQ[variables, regulator] && ListQ[ids] && ids =!= {} &&
    FreeQ[ids, _Missing] && DuplicateFreeQ[ids] &&
    AssociationQ[valuations] && AllTrue[ids,
      IntegerQ[tangentialEvolutionLookup[valuations, #]] &] &&
    AssociationQ[record["TangentialBasePoint"]] &&
    AssociationQ[record["TangentialPath"]] && ListQ[idRecords] &&
    Length[idRecords] === dimension && AllTrue[idRecords, AssociationQ] &&
    Lookup[idRecords, "BoundaryFunctionID", Missing[]] === ids &&
    FreeQ[Lookup[idRecords, "BoundaryConstantID", Missing[]], _Missing] &&
    (baseIDs = Lookup[idRecords, "BoundaryConstantID"];
      DuplicateFreeQ[baseIDs]) && IntegerQ[valuation] &&
    MatchQ[window, {_Integer, _Integer}] && First[window] === valuation &&
    First[window] <= 0 <= Last[window] && AssociationQ[coefficientMaps] &&
    Sort[Keys[coefficientMaps]] === Range @@ window &&
    AllTrue[Values[coefficientMaps],
      tangentialEvolutionCoefficientMapQ[#, dimension] &] &&
    record["IteratedIntegralLetterSequenceOrientation"] ===
      "OutermostFirst" && record["EvolutionConvention"] ===
      "c(t,eps)=U(t,t0;eps).c(t0,eps)" &&
    AssociationQ[validation] && AssociationQ[conditions] &&
    ContainsAll[Keys[conditions], requiredConditions] &&
    AllTrue[requiredConditions,
      TrueQ[tangentialEvolutionLookup[conditions, #, False]] &] &&
    ! KeyExistsQ[record, "BoundaryFunctionEpsilonCoefficientFormulas"]
];

boundaryFunctionToMasterIntegralSolutionMapQ[record_] := Module[
  {coordinates, labels, terms, demands, columnCount, rowCount, validation,
   conditions, domain, regulator},
  If[! AssociationQ[record] ||
      Lookup[record, "DataType", None] =!=
        "BoundaryFunctionToMasterIntegralSolutionMap" ||
      Lookup[record, "SchemaVersion", None] =!= 2 ||
      Lookup[record, "Status", None] =!=
        "BoundaryFunctionToMasterIntegralSolutionMapValidated" ||
      Lookup[record, "BoundaryDataType", None] =!= "BoundaryFunction",
    Return[False]];
  domain = Lookup[record, "BoundaryDomain", Missing[]];
  regulator = Lookup[record, "DimensionalRegulator", Missing[]];
  coordinates = Lookup[record,
    "BoundaryFunctionEpsilonCoefficientRecords", Missing[]];
  labels = Lookup[record,
    "BoundaryFunctionEpsilonCoefficientLabels", Missing[]];
  terms = Lookup[record,
    "IteratedIntegralCoefficientMatrixRecords", Missing[]];
  demands = Lookup[record,
    "RequestedMasterIntegralEpsilonOrderAndRowPairs", Missing[]];
  validation = Lookup[record, "Validation", Missing[]];
  conditions = Lookup[validation, "Conditions", Missing[]];
  If[! ListQ[coordinates] || ! AllTrue[coordinates, AssociationQ] ||
      ! AllTrue[coordinates, KeyExistsQ[#, "BoundaryFunctionID"] &&
          IntegerQ[Lookup[#, "EpsilonOrder", None]] &] ||
      ! DuplicateFreeQ[(tangentialEvolutionCoordinateKey[
          #["BoundaryFunctionID"], #["EpsilonOrder"]] &) /@ coordinates] ||
      labels =!= ({#["BoundaryFunctionID"], #["EpsilonOrder"]} & /@
          coordinates) || ! ListQ[terms] || ! AllTrue[terms, AssociationQ] ||
      ! MatchQ[demands, {{_Integer, _Integer} ...}] ||
      ! DuplicateFreeQ[demands] ||
      ! StringQ[Lookup[record, "Family", Missing[]]] ||
      ! AssociationQ[domain] ||
      Lookup[domain, "Type", None] =!= "PhysicalBoundaryStratum" ||
      ! MatchQ[Lookup[domain, "TangentialVariables", Missing[]],
        {__Symbol}] || ! MatchQ[regulator, _Symbol] ||
      MemberQ[domain["TangentialVariables"], regulator] ||
      Lookup[record, "DemandCoverage", None] =!= "Complete" ||
      ! AssociationQ[Lookup[record, "FormalResultConvention", Missing[]]] ||
      ! AssociationQ[validation] || ! AssociationQ[conditions] ||
      conditions === <||> || ! AllTrue[Values[conditions], TrueQ],
    Return[False]];
  columnCount = Length[coordinates];
  rowCount = Length[demands];
  AllTrue[terms, Function[term,
    MatchQ[Lookup[term,
          {"CurrentPathFirstSegmentLetterIndices",
            "CurrentPathSecondSegmentLetterIndices",
            "BoundaryPathFirstSegmentLetterIndices",
            "BoundaryPathSecondSegmentLetterIndices"}, Missing[]],
        {_List, _List, _List, _List}] &&
      MatrixQ[Lookup[term, "IteratedIntegralCoefficientMatrix",
        Missing[]]] &&
      Dimensions[Lookup[term, "IteratedIntegralCoefficientMatrix"]] ===
        {rowCount, columnCount} &&
      FreeQ[Lookup[term, "IteratedIntegralCoefficientMatrix"], _Real]]]
];

tangentialEvolutionFunctionIndex[ids_List] :=
  AssociationThread[ids, Range[Length[ids]]];

tangentialEvolutionBaseConstantIDs[idRecords_List] :=
  AssociationThread[Lookup[idRecords, "BoundaryFunctionID"],
    Lookup[idRecords, "BoundaryConstantID"]];

tangentialEvolutionOutputCoordinate[baseID_, sourceID_, order_Integer,
    valuation_Integer] := <|
  "BoundaryDataType" -> "BoundaryConstant",
  "BoundaryConstantID" -> baseID,
  "SourceBoundaryFunctionID" -> sourceID,
  "BoundaryConstantEpsilonValuation" -> valuation,
  "EpsilonOrder" -> order,
  "Coefficient" -> BoundaryConstantEpsilonCoefficient[baseID, order],
  "Status" -> "Unevaluated"|>;

tangentialEvolutionTransformation[order_Integer, coefficientMatrix_?MatrixQ,
    inputCoordinates_List, outputIndex_Association,
    functionIndex_Association, ids_List, baseConstantIDs_Association,
    valuations_Association, outputCount_Integer] := Module[
  {rules, sourceID, sourceIndex, targetOrder, targetID, targetIndex, value},
  rules = Reap[Do[
      sourceID = inputCoordinates[[inputColumn]]["BoundaryFunctionID"];
      sourceIndex = tangentialEvolutionLookup[functionIndex,
        sourceID];
      targetOrder = inputCoordinates[[inputColumn]]["EpsilonOrder"] - order;
      Do[
        value = coefficientMatrix[[sourceIndex, targetColumn]];
        If[targetOrder >= tangentialEvolutionLookup[valuations,
              ids[[targetColumn]]] && ! tangentialEvolutionExactZeroQ[value],
          targetID = tangentialEvolutionLookup[baseConstantIDs,
            ids[[targetColumn]]];
          targetIndex = tangentialEvolutionLookup[outputIndex,
            tangentialEvolutionCoordinateKey[targetID, targetOrder]];
          Sow[{inputColumn, targetIndex} -> value]],
        {targetColumn, Length[ids]}],
      {inputColumn, Length[inputCoordinates]}]][[2]];
  rules = If[rules === {}, {}, First[rules]];
  SparseArray[rules, {Length[inputCoordinates], outputCount}]
];

tangentialEvolutionRequirement[coordinateGroup_List,
    basePoint_Association] := With[{first = First[coordinateGroup]}, <|
  "BoundaryDataType" -> "BoundaryConstant",
  "BoundaryConstantID" -> first["BoundaryConstantID"],
  "SourceBoundaryFunctionID" -> first["SourceBoundaryFunctionID"],
  "BoundaryConstantEpsilonValuation" ->
    first["BoundaryConstantEpsilonValuation"],
  "BoundaryConstantEpsilonCoefficientLabels" ->
    ({#["BoundaryConstantID"], #["EpsilonOrder"]} & /@ coordinateGroup),
  "TangentialBasePoint" -> basePoint, "Status" -> "Unevaluated"|>];

ComposeBoundaryFunctionSolutionMapWithTangentialEvolution[
    boundaryMap_Association, evolution_Association] := Catch@Module[
  {fail, family, ids, idRecords, baseConstantIDs, valuations, functionIndex,
   inputCoordinates, coefficientMaps, evolutionWindow, evolutionValuation,
   minimumBoundaryValuation, requiredHigh, requiredWindow,
   coordinatePieces, outputCoordinates, outputIndex, outputCount,
   transformations, coefficientTerm, termPieces, mergedTerms, outputTerms,
   usedColumns,
   requirements, outputWindow},
  fail[status_, extra_: <||>] :=
    Throw[tangentialEvolutionFailure[status, extra]];
  If[! TangentialBoundaryEvolutionOperatorQ[evolution],
    fail["TangentialBoundaryEvolutionOperatorRequired"]];
  If[! boundaryFunctionToMasterIntegralSolutionMapQ[boundaryMap],
    fail["BoundaryFunctionSolutionMapRequired"]];
  family = boundaryMap["Family"];
  If[family =!= evolution["Family"],
    fail["TangentialBoundaryEvolutionFamilyMismatch", <|
      "BoundaryFunctionSolutionMapFamily" -> family,
      "TangentialBoundaryEvolutionFamily" -> evolution["Family"]|>]];
  ids = evolution["BoundaryFunctionIDs"];
  idRecords = evolution[
    "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs"];
  baseConstantIDs = tangentialEvolutionBaseConstantIDs[idRecords];
  valuations = evolution["BoundaryFunctionEpsilonValuations"];
  functionIndex = tangentialEvolutionFunctionIndex[ids];
  inputCoordinates =
    boundaryMap["BoundaryFunctionEpsilonCoefficientRecords"];
  If[! AllTrue[inputCoordinates,
      IntegerQ[tangentialEvolutionLookup[functionIndex,
          #["BoundaryFunctionID"]]] &&
        #["EpsilonOrder"] >= tangentialEvolutionLookup[valuations,
          #["BoundaryFunctionID"]] &],
    fail["BoundaryFunctionSolutionMapCoordinateInvalid"]];
  coefficientMaps =
    evolution["EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder"];
  evolutionWindow = evolution["EpsilonOrderWindow"];
  evolutionValuation = evolution["EvolutionOperatorEpsilonValuation"];
  minimumBoundaryValuation = Min[
    tangentialEvolutionLookup[valuations, #] & /@ ids];
  (* In c_i^(n)(t) = Sum_r,j U_r,ij(t,t0) c_j^(n-r)(t0), the
     base-point coefficient vanishes for n-r below its declared valuation.
     Therefore r <= n-min_j(v_j) is a sufficient, family-neutral bound. *)
  requiredHigh = If[inputCoordinates === {}, evolutionValuation,
    Max[Lookup[inputCoordinates, "EpsilonOrder"]] - minimumBoundaryValuation];
  requiredWindow = {evolutionValuation, requiredHigh};
  If[Last[evolutionWindow] < requiredHigh,
    fail["TangentialBoundaryEvolutionEpsilonWindowInsufficient", <|
      "RequiredEpsilonOrderWindow" -> requiredWindow,
      "AvailableEpsilonOrderWindow" -> evolutionWindow|>]];

  coordinatePieces = Reap[Do[
      KeyValueMap[Function[{sequence, matrix},
          Do[With[{sourceID = coordinate["BoundaryFunctionID"],
            sourceIndex = tangentialEvolutionLookup[functionIndex,
              coordinate["BoundaryFunctionID"]],
            targetOrder = coordinate["EpsilonOrder"] - order},
          If[targetOrder >= tangentialEvolutionLookup[valuations,
                ids[[targetColumn]]] && ! tangentialEvolutionExactZeroQ[
                matrix[[sourceIndex, targetColumn]]],
            Sow[tangentialEvolutionOutputCoordinate[
              tangentialEvolutionLookup[baseConstantIDs,
                ids[[targetColumn]]], ids[[targetColumn]],
              targetOrder, tangentialEvolutionLookup[valuations,
                ids[[targetColumn]]]]]]],
          {coordinate, inputCoordinates}, {targetColumn, Length[ids]}]],
        tangentialEvolutionLookup[coefficientMaps, order]],
      {order, Range @@ requiredWindow}]][[2]];
  coordinatePieces = If[coordinatePieces === {}, {}, First[coordinatePieces]];
  outputCoordinates = DeleteDuplicatesBy[coordinatePieces,
    tangentialEvolutionCoordinateKey[
      #["BoundaryConstantID"], #["EpsilonOrder"]] &];
  outputIndex = AssociationThread[
    (tangentialEvolutionCoordinateKey[
        #["BoundaryConstantID"], #["EpsilonOrder"]] &) /@ outputCoordinates,
    Range[Length[outputCoordinates]]];
  outputCount = Length[outputCoordinates];
  transformations = Flatten@Table[
    KeyValueMap[Function[{sequence, matrix}, <|
        "TangentialBoundaryPathIteratedIntegralLetterSequence" -> sequence,
        "Matrix" -> tangentialEvolutionTransformation[order, matrix,
          inputCoordinates, outputIndex, functionIndex, ids,
          baseConstantIDs, valuations, outputCount]|>],
      tangentialEvolutionLookup[coefficientMaps, order]],
    {order, Range @@ requiredWindow}];
  transformations = Select[transformations,
    Length[#["Matrix"]["NonzeroPositions"]] > 0 &];

  termPieces = Reap[Do[
      Do[With[{matrix = SparseArray[
              coefficientTerm["IteratedIntegralCoefficientMatrix"] .
              transformation["Matrix"]]},
        If[Length[matrix["NonzeroPositions"]] > 0,
          Sow[tangentialEvolutionPathKey[coefficientTerm,
              transformation[
                "TangentialBoundaryPathIteratedIntegralLetterSequence"]] ->
            matrix]]],
        {transformation, transformations}],
      {coefficientTerm,
        boundaryMap["IteratedIntegralCoefficientMatrixRecords"]}]][[2]];
  termPieces = If[termPieces === {}, {}, First[termPieces]];
  mergedTerms = If[termPieces === {}, <||>, Merge[
    (Association[#] &) /@ termPieces,
    tangentialEvolutionExactSparseMatrix[Total[#]] &]];
  mergedTerms = Select[mergedTerms,
    Length[#["NonzeroPositions"]] > 0 &];
  outputTerms = KeyValueMap[Function[{key, matrix}, With[
      {parts = List @@ key}, <|
        "CurrentPathFirstSegmentLetterIndices" -> parts[[1]],
        "CurrentPathSecondSegmentLetterIndices" -> parts[[2]],
        "BoundaryPathFirstSegmentLetterIndices" -> parts[[3]],
        "BoundaryPathSecondSegmentLetterIndices" -> parts[[4]],
        "TangentialBoundaryPathIteratedIntegralLetterSequence" -> parts[[5]],
        "IteratedIntegralCoefficientMatrix" -> matrix|>]], mergedTerms];
  usedColumns = Sort@DeleteDuplicates@Flatten[Map[
    Cases[First /@ ArrayRules[#["IteratedIntegralCoefficientMatrix"]],
      {_, column_Integer} :> column] &, outputTerms]];
  usedColumns = Select[usedColumns, 1 <= # <= outputCount &];
  If[usedColumns =!= Range[outputCount],
    outputTerms = Map[Join[KeyDrop[#,
          "IteratedIntegralCoefficientMatrix"],
        <|"IteratedIntegralCoefficientMatrix" ->
          #["IteratedIntegralCoefficientMatrix"][[All, usedColumns]]|>] &,
      outputTerms];
    outputCoordinates = If[usedColumns === {}, {},
      outputCoordinates[[usedColumns]]]];
  requirements = tangentialEvolutionRequirement[#,
      evolution["TangentialBasePoint"]] & /@
    GatherBy[outputCoordinates, #["BoundaryConstantID"] &];
  outputWindow = If[outputCoordinates === {}, {},
    MinMax[Lookup[outputCoordinates, "EpsilonOrder"]]];
  <|
    "DataType" -> "BoundaryConstantToMasterIntegralSolutionMap",
    "SchemaVersion" -> 2,
    "Status" -> "BoundaryConstantToMasterIntegralSolutionMapConstructed",
    "Family" -> family, "BoundaryDataType" -> "BoundaryConstant",
    "BoundaryDomain" -> evolution["BoundaryDomain"],
    "DimensionalRegulator" -> evolution["DimensionalRegulator"],
    "SourceBoundaryFunctionIDs" -> ids,
    "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs" -> idRecords,
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" ->
      Lookup[boundaryMap,
        "RequestedMasterIntegralEpsilonOrderAndRowPairs", {}],
    "TangentialBasePoint" -> evolution["TangentialBasePoint"],
    "TangentialPath" -> evolution["TangentialPath"],
    "PathSegmentConvention" -> <|
      "InheritedBoundaryFunctionSolutionMapConvention" ->
        Lookup[boundaryMap, "FormalResultConvention", Missing[]],
      "SegmentMultiplicationOrder" -> {
        "CurrentPathFirstSegment", "CurrentPathSecondSegment",
        "BoundaryPathFirstSegment", "BoundaryPathSecondSegment",
        "TangentialBoundaryPath"},
      "TangentialBoundaryPathEvolutionConvention" ->
        evolution["EvolutionConvention"]|>,
    "BoundaryConstantEpsilonCoefficientRecords" -> outputCoordinates,
    "BoundaryConstantEpsilonCoefficientLabels" ->
      ({#["BoundaryConstantID"], #["EpsilonOrder"]} & /@
        outputCoordinates),
    "IteratedIntegralCoefficientMatrixTerms" -> outputTerms,
    "BoundaryDataRequirements" -> requirements,
    "EpsilonOrderCoverage" -> <|
      "RequiredTangentialEvolutionEpsilonOrderWindow" -> requiredWindow,
      "AvailableTangentialEvolutionEpsilonOrderWindow" -> evolutionWindow,
      "OutputBoundaryConstantEpsilonOrderWindow" -> outputWindow|>,
    "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
    "SolutionConvention" ->
      "BoundaryFunctionSolutionMap(t).U(t,t0) maps boundary constants at t0 to requested master-integral coefficients"|>
];

ComposeBoundaryFunctionSolutionMapWithTangentialEvolution[___] :=
  tangentialEvolutionFailure[
    "BoundaryFunctionTangentialEvolutionCompositionInputsNotWellFormed"];
