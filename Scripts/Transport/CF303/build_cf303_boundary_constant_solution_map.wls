#!/usr/bin/env wolframscript

(* Compose the accepted CF303 normal/bulk lazy map, whose boundary columns
   are the thirteen soft-stratum functions, with their exact tangential
   evolution from p0=4/11.  The two path word sequences remain separate. *)

$AllowInternet = False;
$HistoryLength = 0;

ClearAll[cf303SolutionRelativePath, cf303SolutionReference,
  cf303SolutionReadArtifact, cf303SolutionNonzeroQ,
  cf303SolutionExactZeroMatrixQ,
  cf303SolutionPairMatrix, cf303SolutionEmbedRows,
  cf303SolutionBoundaryFunctionRecord, cf303SolutionRequirement];

cf303SolutionRelativePath[fromDirectory_String, target_String] := Module[
  {from = FileNameSplit[ExpandFileName[fromDirectory]],
   to = FileNameSplit[ExpandFileName[target]], common = 0},
  While[common < Min[Length[from], Length[to]] &&
      from[[common + 1]] === to[[common + 1]], common++];
  FileNameJoin[Join[ConstantArray["..", Length[from] - common],
    Drop[to, common]]]
];

cf303SolutionReference[fromDirectory_String, path_String, dataType_,
    schemaVersion_, status_] := <|
  "RelativePath" -> cf303SolutionRelativePath[fromDirectory, path],
  "DataType" -> dataType, "SchemaVersion" -> schemaVersion,
  "SourceStatus" -> status|>;

cf303SolutionReadArtifact[path_String, name_String, fail_] := Module[{value},
  If[! FileExistsQ[path],
    fail["CF303BoundaryConstantSolutionInputMissing",
      <|"Input" -> name, "Path" -> path|>]];
  value = Quiet[Check[FeynFacet`FamilyArtifactRead[path], $Failed]];
  If[! AssociationQ[value],
    fail["CF303BoundaryConstantSolutionInputUnreadable",
      <|"Input" -> name, "Path" -> path|>]];
  value
];

cf303SolutionNonzeroQ[matrix_] :=
  Length[SparseArray[matrix]["NonzeroPositions"]] > 0;

cf303SolutionExactZeroMatrixQ[matrix_] := And @@ Flatten[Map[
  Quiet[Check[Cancel[Together[#]] === 0, False]] &,
  Normal[matrix], {2}]];

cf303SolutionPairMatrix[pair : {_?MatrixQ, _?MatrixQ}, variable_Symbol] :=
  SparseArray[Normal[First[pair]] + CF303Y[variable] Normal[Last[pair]]];

cf303SolutionEmbedRows[matrix_?MatrixQ, firstRow_Integer,
    totalRows_Integer] := SparseArray@Join[
  ConstantArray[0, {firstRow - 1, Dimensions[matrix][[2]]}],
  Normal[matrix],
  ConstantArray[0, {totalRows - firstRow - Dimensions[matrix][[1]] + 1,
    Dimensions[matrix][[2]]}]];

cf303SolutionBoundaryFunctionRecord[key : {id_, order_Integer},
    valuations_Association, variable_Symbol] := <|
  "BoundaryDataType" -> "BoundaryFunction",
  "BoundaryFunctionID" -> id,
  "BoundaryFunctionEpsilonValuation" -> valuations[[Key[id]]],
  "EpsilonOrder" -> order,
  "Coefficient" ->
    FeynFacet`BoundaryFunctionEpsilonCoefficient[id, order][variable],
  "Status" -> "Unevaluated"|>;

cf303SolutionRequirement[group_List, variable_Symbol] :=
  With[{first = First[group]}, <|
    "BoundaryDataType" -> "BoundaryFunction",
    "BoundaryFunctionID" -> first["BoundaryFunctionID"],
    "BoundaryFunctionEpsilonValuation" ->
      first["BoundaryFunctionEpsilonValuation"],
    "BoundaryFunctionEpsilonCoefficientLabels" ->
      ({#["BoundaryFunctionID"], #["EpsilonOrder"]} & /@ group),
    "TangentialVariables" -> {variable}, "Status" -> "Unevaluated"|>];

buildResult = Block[{$HistoryLength = 0}, Catch@Module[
  {fail, scriptDirectory, repository, arguments,
   v2ArtifactDirectory,
   adapterPath, junctionPath, evolutionPath, boundaryMapPath, outputPath,
   outputDirectory, adapterRecord, adapter, junction, evolution, rebased,
   amplitudeWindow = {-1, 5}, outputOrders = Range[-4, 2],
   targetRows, demands, modeOrder, valuations, p, normalVariable,
   coefficientRecords, coordinateKeys, recordsByOrder, recordTimings,
   wordMapPieces, wordMapAssociation, wordMaps, boundaryMap,
   boundaryFunctionRequirements, terminal, normalPath, inputReferences,
   coordinateArrangement,
   singularPointResidueData, providerFreeReplay, logarithmicDeck,
   leveltConditions, logWitnessCount,
   validationConditions, validation, maxInternalWords = 10000,
   boundaryMapDirectory, boundaryMapInputReferences},

  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
  repository = DirectoryName[scriptDirectory, 3];
  arguments = Rest[$ScriptCommandLine];
  v2ArtifactDirectory = FileNameJoin[{repository,
    "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
    "DifferentialEquationDataV2", "CF303"}];
  adapterPath = If[Length[arguments] >= 1, arguments[[1]],
    FileNameJoin[{v2ArtifactDirectory,
      "CF303NormalBulkIteratedIntegralCoefficientOperatorV2.wl"}]];
  junctionPath = If[Length[arguments] >= 2, arguments[[2]],
    FileNameJoin[{v2ArtifactDirectory,
      "CF303TangentialJunctionMapReconstructed.wl"}]];
  evolutionPath = If[Length[arguments] >= 3, arguments[[3]],
    FileNameJoin[{v2ArtifactDirectory,
      "CF303TangentialBoundaryEvolutionOperatorV2.wl"}]];
  boundaryMapPath = If[Length[arguments] >= 4, arguments[[4]],
    FileNameJoin[{v2ArtifactDirectory,
      "CF303BoundaryFunctionToMasterIntegralSolutionMapV2.wl"}]];
  outputPath = If[Length[arguments] >= 5, arguments[[5]],
    FileNameJoin[{v2ArtifactDirectory,
      "CF303BoundaryConstantToMasterIntegralSolutionMapV2.wl"}]];
  outputDirectory = DirectoryName[ExpandFileName[outputPath]];
  boundaryMapDirectory = DirectoryName[ExpandFileName[boundaryMapPath]];
  recordTimings = <||>;

  Get[FileNameJoin[{repository, "Addon", "Load", "LoadFACET.wl"}]];
  Get[FileNameJoin[{scriptDirectory,
    "CF303NormalBulkCoefficientMap.wl"}]];
  Get[FileNameJoin[{scriptDirectory, "CF303JunctionRebase.wl"}]];

  adapterRecord = cf303SolutionReadArtifact[
    adapterPath, "CF303NormalBulkLazyAdapter", fail];
  junction = cf303SolutionReadArtifact[
    junctionPath, "CF303TangentialJunctionMap", fail];
  evolution = cf303SolutionReadArtifact[
    evolutionPath, "CF303TangentialBoundaryEvolutionOperator", fail];
  If[Lookup[adapterRecord, "Status", None] ===
      "CF303NormalBulkCompletionInputsMissing",
    fail["CF303NormalBulkCompletionInputsMissing", <|
      "CompletionRequirement" -> Lookup[adapterRecord,
        "CompletionRequirement", Missing[]],
      "TerminalMasterIntegralSolutionPublished" -> False|>]];
  If[Lookup[adapterRecord, "DataType", None] =!=
        "IteratedIntegralCoefficientOperatorForRequestedOutputs" ||
      Lookup[adapterRecord, "SchemaVersion", None] =!= 2 ||
      Lookup[adapterRecord, "Status", None] =!=
        "CF303NormalBulkIteratedIntegralCoefficientOperatorValidated" ||
      ! AssociationQ[Lookup[adapterRecord, "OperatorData", None]],
    fail["CF303BoundaryConstantSolutionNormalOperatorInvalid"]];
  adapter = adapterRecord["OperatorData"];
  If[Lookup[adapter, "Status", None] =!=
        "CF303HybridBaselineLazyCircuitAdapterAcceptedV1" ||
      Lookup[junction, "Status", None] =!=
        "CF303TangentialJunctionMapReconstructedV1" ||
      ! TrueQ[FeynFacet`TangentialBoundaryEvolutionOperatorQ[evolution]],
    fail["CF303BoundaryConstantSolutionInputsInvalid"]];

  p = Symbol["Global`p"];
  normalVariable = adapter["Variable"];
  modeOrder = junction["CombinedModeOrder"];
  valuations = evolution["BoundaryFunctionEpsilonValuations"];
  If[evolution["BoundaryFunctionIDs"] =!= modeOrder ||
      ! MatchQ[normalVariable, _Symbol],
    fail["CF303BoundaryConstantSolutionConventionMismatch"]];

  rebased = CF303RebaseLazyAdapterAtJunction[
    adapter, junction, amplitudeWindow];
  If[! TrueQ[CF303AcceptedJunctionRebasedAdapterQ[rebased]],
    fail["CF303BoundaryConstantSolutionJunctionRebaseFailed",
      <|"Result" -> rebased|>]];
  coordinateKeys = rebased["BoundaryColumns"];
  coefficientRecords =
    cf303SolutionBoundaryFunctionRecord[#, valuations, p] & /@
      coordinateKeys;
  If[Length[coefficientRecords] =!=
        Length[modeOrder] Length[Range @@ amplitudeWindow] ||
      Lookup[coefficientRecords, "BoundaryFunctionID"] =!=
        Flatten[Table[modeOrder, {Length[Range @@ amplitudeWindow]}]],
    fail["CF303BoundaryConstantSolutionBoundaryCoordinatesInvalid"]];

  singularPointResidueData = Lookup[adapterRecord,
    "NormalSingularPointResidueData", Missing[]];
  logarithmicDeck = Lookup[singularPointResidueData,
    "LogarithmicJordanCoefficientDeck", Missing[]];
  providerFreeReplay = Lookup[singularPointResidueData,
    "ProviderFreeOperatorProjectionReplay", Missing[]];
  If[! AssociationQ[singularPointResidueData] ||
      ! AssociationQ[logarithmicDeck] ||
      ! AssociationQ[providerFreeReplay],
    fail["CF303BoundaryConstantSolutionNormalSingularPointDataMissing"]];
  logWitnessCount = Total[Length[# ["NonzeroPositions"]] & /@
    Values[logarithmicDeck]];
  leveltConditions = <|
    "DemandClosedFiniteModeEmbeddingPresent" ->
      AssociationQ[Lookup[junction, "SourceModeMap", None]] &&
        AssociationQ[Lookup[junction, "TargetGModeMap", None]] &&
        TrueQ[Lookup[junction, "TargetGModeMapComplete", False]] &&
        AllTrue[Values[junction["SourceModeMap"]],
          MatrixQ[#] && Dimensions[#] === {43, 13} &] &&
        AllTrue[Values[junction["TargetGModeMap"]],
          MatrixQ[#] && Dimensions[#] === {2, 13} &],
    "NormalOperatorDeclaresAuthoritativeLeveltInput" ->
      Lookup[singularPointResidueData, "DataType", None] ===
          "NormalSingularPointResidueData" &&
        Lookup[singularPointResidueData, "SchemaVersion", None] === 2 &&
        Lookup[singularPointResidueData, "EpsilonOrderWindow", None] ===
          {-3, 4},
    "AuthoritativeJunctionLeveltConstructionAccepted" ->
      Lookup[junction, "Status", None] ===
          "CF303TangentialJunctionMapReconstructedV1" &&
        Lookup[junction, "IndependentValidationComparisonCount", 0] ===
          112 &&
        Lookup[junction["Regularization"], "Status", None] ===
          "TangentialJunctionIntertwiningJetsAccepted" &&
        And @@ Values[Lookup[singularPointResidueData["Validation"],
          "Conditions", <||>]],
    "ProviderFreeReplayLimitationDeclaredWithoutDuplicateClaim" ->
      Lookup[providerFreeReplay, "Status", None] ===
          "NormalSingularPointResidueDeferredOneFormDefinitionsMissing" &&
        TrueQ[Lookup[providerFreeReplay,
          "RepresentationLimitationOnly", False]] &&
        Lookup[providerFreeReplay,
          "ContributingMissingLetterRecordCount", None] === 180 &&
        Lookup[providerFreeReplay,
          "Block1ContributionToResonantProjection", None] === 0,
    "NonzeroResonantLogarithmicDeckPresent" -> logWitnessCount > 0,
    "NormalLeveltRecurrenceCheckedThroughRhoOne" ->
      ContainsAll[Lookup[junction["Regularization"],
        "CheckedRhoOrders", {}], {0, 1}] &&
        Lookup[junction["Regularization"], "Status", None] ===
          "TangentialJunctionIntertwiningJetsAccepted",
    "ModeMapAndLogDeckFreshPrimeValidated" ->
      Lookup[junction, "IndependentValidationComparisonCount", 0] === 112|>;
  If[! And @@ Values[leveltConditions],
    fail["CF303BoundaryConstantSolutionLeveltEmbeddingIncomplete", <|
      "Conditions" -> leveltConditions,
      "NonzeroLogarithmicCoefficientCount" -> logWitnessCount|>]];

  targetRows = rebased["TargetRows"];
  demands = Flatten[Table[{order, row}, {order, outputOrders},
      {row, targetRows}], 1];
  recordsByOrder = Association@Table[order -> Module[{timing, records},
      timing = AbsoluteTiming[
        records = cf303NormalPhysicalCoefficientRecords[
          rebased, order, maxInternalWords]];
      recordTimings[order] = First[timing];
      If[! AssociationQ[records] || Lookup[records, "Status", None] =!= "OK",
        fail["CF303BoundaryConstantSolutionNormalWordsFailed",
          <|"EpsilonOrder" -> order, "Result" -> records|>]];
      records], {order, outputOrders}];

  wordMapPieces = Reap[Do[
      Do[With[{matrix = cf303SolutionPairMatrix[
            record["CoefficientPair"], normalVariable]},
        If[cf303SolutionNonzeroQ[matrix],
          Sow[HoldComplete[record["InternalWord"]] ->
            cf303SolutionEmbedRows[matrix,
              1 + Length[targetRows] (orderIndex - 1),
              Length[demands]]]]],
        {record, recordsByOrder[outputOrders[[orderIndex]], "Records"]}],
      {orderIndex, Length[outputOrders]}][[2]];
  wordMapPieces = If[wordMapPieces === {}, {}, First[wordMapPieces]];
  wordMapAssociation = If[wordMapPieces === {}, <||>, Merge[
    Association /@ wordMapPieces,
    SparseArray[Total[Normal /@ #]] &]];
  wordMapAssociation = Select[wordMapAssociation, cf303SolutionNonzeroQ];
  wordMaps = KeyValueMap[Function[{heldWord, matrix}, <|
      "CurrentFirstWord" -> {}, "CurrentSecondWord" -> {},
      "EndpointFirstWord" -> First[List @@ heldWord],
      "EndpointSecondWord" -> {}, "Map" -> matrix|>],
    wordMapAssociation];

  normalPath = <|
    "Type" -> "RegularizedNormalBoundaryToBulkPath",
    "Variable" -> normalVariable,
    "From" -> rebased["Path", "BasePoint"],
    "To" -> rebased["Path", "PathEndpoint"],
    "BasePointPrescription" ->
      rebased["Path", "BasePointPrescription"],
    "Curve" -> rebased["Curve"],
    "InternalWordAlphabetReference" -> <|
      "RelativePath" -> cf303SolutionRelativePath[
        boundaryMapDirectory, adapterPath],
      "Field" -> {"OperatorData", "GOperator", "Letters"},
      "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst"|>|>;
  boundaryFunctionRequirements =
    cf303SolutionRequirement[#, p] & /@
      GatherBy[coefficientRecords, #["BoundaryFunctionID"] &];
  inputReferences = <|
    "NormalBulkLazyAdapter" -> cf303SolutionReference[outputDirectory,
      adapterPath, "IteratedIntegralCoefficientOperatorForRequestedOutputs",
      2, adapterRecord["Status"]],
    "TangentialJunctionMap" -> cf303SolutionReference[outputDirectory,
      junctionPath, "CF303TangentialJunctionMap", 1,
      junction["Status"]],
    "TangentialBoundaryEvolutionOperator" ->
      cf303SolutionReference[outputDirectory, evolutionPath,
        "TangentialBoundaryEvolutionOperator", 2,
        evolution["Status"]]|>;
  boundaryMapInputReferences = <|
    "NormalBulkLazyAdapter" -> cf303SolutionReference[
      boundaryMapDirectory, adapterPath,
      "IteratedIntegralCoefficientOperatorForRequestedOutputs", 2,
      adapterRecord["Status"]],
    "TangentialJunctionMap" -> cf303SolutionReference[
      boundaryMapDirectory, junctionPath, "CF303TangentialJunctionMap", 1,
      junction["Status"]]|>;

  coordinateArrangement = <|
    "Type" -> "ModeCoordinatesWithDemandClosedLeveltEmbedding",
    "BoundaryModeOrder" -> modeOrder,
    "FiniteModeEmbeddingFields" ->
      {"SourceModeMap", "TargetGModeMap"},
    "LogarithmicCompletion" ->
      "The accepted tangential-junction reconstruction supplies the complete effective rho^-1 residue projection and its independently validated 2x4 logarithmic Levelt deck at epsilon orders -3 through 4",
    "NormalSingularPointResidueData" ->
      singularPointResidueData,
    "NormalBulkMapActsOnBoundaryModeCoordinates" -> True,
    "AmbientTangentialEvolutionRequired" -> False,
    "Composition" ->
      "NormalBulkModeMap(p).TangentialBoundaryEvolution(p,p0)"|>;

  boundaryMap = <|
    "DataType" -> "BoundaryFunctionToMasterIntegralSolutionMap",
    "SchemaVersion" -> 2,
    "Status" -> "GradedPhysicalEndpointWordsBuilt",
    "Family" -> "CF303", "BoundaryDataType" -> "BoundaryFunction",
    "PhysicalDemandPairs" -> demands,
    "BoundaryFunctionEpsilonCoefficientRecords" -> coefficientRecords,
    "BoundaryFunctionEpsilonCoefficientLabels" -> coordinateKeys,
    "WordMaps" -> wordMaps,
    "BoundaryDataRequirements" -> boundaryFunctionRequirements,
    "NormalBoundaryToBulkPath" -> normalPath,
    "ConstructionInputReferences" -> boundaryMapInputReferences,
    "BoundaryCoordinateArrangement" -> coordinateArrangement,
    "LeveltEmbeddingValidation" -> <|
      "Conditions" -> leveltConditions,
      "NonzeroLogarithmicCoefficientCount" -> logWitnessCount,
      "AuthoritativeSource" ->
        singularPointResidueData["AuthoritativeSource"],
      "ProviderFreeReplayLimitation" -> providerFreeReplay|>,
    "FormalResultConvention" -> <|
      "Segments" -> {"NormalBoundaryToBulk"},
      "WordOrientation" -> "OutermostFirst",
      "Coefficient" ->
        "Map . BoundaryFunctionEpsilonCoefficient[BoundaryFunctionID,EpsilonOrder]"|>|>;
  If[! DirectoryQ[boundaryMapDirectory],
    CreateDirectory[boundaryMapDirectory,
      CreateIntermediateDirectories -> True]];
  Put[boundaryMap, boundaryMapPath];

  composed =
    FeynFacet`ComposeBoundaryFunctionSolutionMapWithTangentialEvolution[
      boundaryMap, evolution];
  If[FailureQ[composed] || Lookup[composed, "Status", None] =!=
        "BoundaryConstantToMasterIntegralSolutionMapConstructed",
    fail["CF303BoundaryConstantSolutionTangentialCompositionFailed",
      <|"Result" -> composed|>]];
  validationConditions = <|
    "TangentialEvolutionAccepted" ->
      TrueQ[FeynFacet`TangentialBoundaryEvolutionOperatorQ[evolution]],
    "NormalBoundaryFunctionMapConstructed" -> wordMaps =!= {},
    "AllDemandedMasterIntegralCoefficientsPresent" ->
      Length[demands] === 14,
    "BoundaryFunctionsEliminatedInFavorOfBasePointConstants" ->
      Lookup[composed, "BoundaryDataType", None] === "BoundaryConstant" &&
        FreeQ[composed,
          _FeynFacet`BoundaryFunctionEpsilonCoefficient],
    "LeveltEmbeddingDemandWindowValidated" ->
      And @@ Values[leveltConditions]|>;
  If[! And @@ Values[validationConditions],
    fail["CF303BoundaryConstantSolutionValidationFailed",
      <|"Conditions" -> validationConditions|>]];
  validation = <|"Method" ->
      "ExactSparseNormalWordMapTimesTangentialEvolutionWordMap",
    "Conditions" -> validationConditions,
    "Evidence" -> <|
      "NormalInternalWordCountByEpsilonOrder" ->
        Map[Lookup[#, "InternalWordCount", Missing[]] &, recordsByOrder],
      "NormalWordMapCount" -> Length[wordMaps],
      "TangentialWordMapCountByEpsilonOrder" -> Map[Length,
        evolution[
          "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder"]],
      "LeveltEmbedding" -> boundaryMap["LeveltEmbeddingValidation"],
      "NormalRecordTimingsSeconds" -> recordTimings|>|>;
  Join[composed, <|
    "ConstructionInputReferences" -> inputReferences,
    "PathSegmentOrder" ->
      {"TangentialBasePointToBoundaryPoint",
       "RegularizedNormalBoundaryToBulkPoint"},
    "NormalBoundaryToBulkPath" -> normalPath,
    "BoundaryCoordinateArrangement" -> coordinateArrangement,
    "Validation" -> validation,
    "IntermediateBoundaryFunctionSolutionMap" -> <|
      "RelativePath" -> cf303SolutionRelativePath[
        outputDirectory, boundaryMapPath],
      "DataType" -> "BoundaryFunctionToMasterIntegralSolutionMap",
      "SchemaVersion" -> 2,
      "SourceStatus" -> "GradedPhysicalEndpointWordsBuilt"|>,
    "OutputPath" -> outputPath|>]
]]];

If[AssociationQ[buildResult] &&
    Lookup[buildResult, "Status", None] ===
      "BoundaryConstantToMasterIntegralSolutionMapConstructed",
  outputPath = buildResult["OutputPath"];
  If[! DirectoryQ[DirectoryName[outputPath]],
    CreateDirectory[DirectoryName[outputPath],
      CreateIntermediateDirectories -> True]];
  Put[KeyDrop[buildResult, "OutputPath"], outputPath];
  Print["PASS status=", buildResult["Status"],
    " demands=", Length[buildResult["PhysicalDemandPairs"]],
    " terms=", Length[
      buildResult["IteratedIntegralCoefficientMatrixTerms"]],
    " constants=", Length[
      buildResult["BoundaryConstantEpsilonCoefficientRecords"]],
    " output=", outputPath];
  Quit[0],
  Print["FAIL ", InputForm[buildResult]];
  Quit[2]
];
