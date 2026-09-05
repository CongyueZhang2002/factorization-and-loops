#!/usr/bin/env wolframscript

(* Tangential evolution of the thirteen CF303 soft-boundary functions from
   p0=4/11 to p.  The intrinsic six-mode block reuses the accepted rational-
   in-epsilon variation-of-constants machinery.  The inherited seven-mode
   block is the direct Chen series of its recorded diagonal epsilon form. *)

$AllowInternet = False;
$HistoryLength = 0;

ClearAll[cf303ExactZeroMatrixQ, cf303BlockDiagonal, cf303MergeWordMaps,
  cf303EmbedRows, cf303EndpointMatrix, cf303SourceCoefficientWordMap,
  cf303EpsilonFormCoefficientWordMap, cf303ResidueMatrix,
  cf303IntrinsicConnection, cf303DerivativeWordMap,
  cf303LeftMultiplyWordMap, cf303WordMapEqualQ,
  cf303RelativePath, cf303InputReference];

cf303ExactZeroMatrixQ[matrix_] := And @@ Flatten[
  Map[Quiet[Check[Cancel[Together[#]] === 0, False]] &,
    Normal[matrix], {2}]];

cf303BlockDiagonal[matrices_List] := Module[{dimensions},
  If[matrices === {} || ! AllTrue[matrices,
      MatrixQ[#] && Equal @@ Dimensions[#] &], Return[$Failed]];
  dimensions = Length /@ matrices;
  ArrayFlatten@Table[If[i === j, Normal[matrices[[i]]],
      ConstantArray[0, {dimensions[[i]], dimensions[[j]]}]],
    {i, Length[matrices]}, {j, Length[matrices]}]
];

cf303MergeWordMaps[maps_List] := Module[{merged},
  If[maps === {}, Return[<||>]];
  merged = Merge[maps, SparseArray[Total[Normal /@ #]] &];
  Select[merged, Length[SparseArray[#]["NonzeroPositions"]] > 0 &]
];

cf303EmbedRows[matrix_, top_Integer, bottom_Integer] := SparseArray@Join[
  ConstantArray[0, {top, Dimensions[matrix][[2]]}], Normal[matrix],
  ConstantArray[0, {bottom, Dimensions[matrix][[2]]}]];

cf303EndpointMatrix[matrix_, endpoint_Symbol, variable_Symbol] :=
  SparseArray@Map[Cancel[Together[# /. endpoint -> variable]] &,
    Normal[matrix], {2}];

cf303SourceCoefficientWordMap[operator_Association,
    order_Integer?NonNegative] := Module[
  {tokens, matrices, labels, selector, words, pieces},
  tokens = operator["SourceTokens"];
  matrices = operator["SourceMatrices"];
  labels = operator["SourceLabels"];
  selector = Lookup[operator["SourceBoundarySelectors"], 0, Missing[]];
  If[! MatrixQ[selector], Return[<||>]];
  words = Tuples[tokens, order];
  pieces = Table[With[{labelWord =
        (Lookup[labels, Key[#], Missing[]] &) /@ tokenWord,
      matrix = Fold[Lookup[matrices, Key[#2], Missing[]] . #1 &,
        selector, Reverse[tokenWord]]},
      If[FreeQ[{labelWord, matrix}, _Missing] && MatrixQ[matrix],
        Association[labelWord -> SparseArray[matrix]], <||>]],
    {tokenWord, words}];
  cf303MergeWordMaps[pieces]
];

cf303EpsilonFormCoefficientWordMap[residues_Association,
    order_Integer?NonNegative] := Module[{letters, words, pieces},
  letters = Keys[residues];
  words = Tuples[letters, order];
  pieces = Table[Association[word -> SparseArray[
      Fold[Lookup[residues, Key[#2]] . #1 &,
        IdentityMatrix[Length[First[Values[residues]]]],
        Reverse[word]]]], {word, words}];
  cf303MergeWordMaps[pieces]
];

cf303ResidueMatrix[connection_, variable_Symbol, point_] :=
  Map[Cancel[Together[Limit[(variable - point) #,
      variable -> point]]] &, connection, {2}];

cf303IntrinsicConnection[source_Association, layer_Association,
    variable_Symbol, regulator_Symbol] := Module[
  {sourceConnection, targetConnection, incomingConnection,
   sourceDimension, targetDimension},
  sourceDimension = source["Dimension"];
  targetDimension = Length[layer["Rows"]];
  sourceConnection = regulator Total[MapThread[
    #1 FeynFacet`IteratedIntegralKernel[#2, variable, None] &,
    {source["Residues"], source["Letters"]}]];
  targetConnection = regulator Total[Map[
    Last[#] FeynFacet`IteratedIntegralKernel[First[#], variable, None] &,
    layer["Diagonal"]]];
  incomingConnection = ConstantArray[0,
    {targetDimension, sourceDimension}];
  Scan[Function[entry,
    incomingConnection[[entry["Row"], entry["Column"]]] +=
      entry["Coefficient"] FeynFacet`IteratedIntegralKernel[
        entry["Letter"], variable, None]], layer["Incoming"]];
  ArrayFlatten[{{sourceConnection,
      ConstantArray[0, {sourceDimension, targetDimension}]},
    {incomingConnection, targetConnection}}]
];

cf303DerivativeWordMap[map_Association, variable_Symbol] := Module[
  {pieces = {}, derivative, tail},
  KeyValueMap[Function[{word, matrix},
    derivative = SparseArray@Map[Cancel[Together[#]] &,
      D[Normal[matrix], variable], {2}];
    If[Length[derivative["NonzeroPositions"]] > 0,
      AppendTo[pieces, Association[word -> derivative]]];
    If[word =!= {},
      tail = SparseArray[
        FeynFacet`IteratedIntegralKernel[First[word], variable, None]
          Normal[matrix]];
      If[Length[tail["NonzeroPositions"]] > 0,
        AppendTo[pieces, Association[Rest[word] -> tail]]]]], map];
  If[pieces === {}, <||>, cf303MergeWordMaps[pieces]]
];

cf303LeftMultiplyWordMap[matrix_?MatrixQ, map_Association] :=
  Select[Map[SparseArray[matrix . Normal[#]] &, map],
    Length[SparseArray[#]["NonzeroPositions"]] > 0 &];

cf303WordMapEqualQ[left_Association, right_Association,
    dimension_Integer] := Module[{keys, zero},
  keys = Union[Keys[left], Keys[right]];
  zero = ConstantArray[0, {dimension, dimension}];
  AllTrue[keys, cf303ExactZeroMatrixQ[
    Normal[Lookup[left, Key[#], zero]] -
      Normal[Lookup[right, Key[#], zero]]] &]
];

cf303RelativePath[fromDirectory_String, target_String] := Module[
  {from = FileNameSplit[ExpandFileName[fromDirectory]],
   to = FileNameSplit[ExpandFileName[target]], common = 0},
  While[common < Min[Length[from], Length[to]] &&
      from[[common + 1]] === to[[common + 1]], common++];
  FileNameJoin[Join[ConstantArray["..", Length[from] - common],
    Drop[to, common]]]
];

cf303InputReference[fromDirectory_String, path_String, status_] := <|
  "RelativePath" -> cf303RelativePath[fromDirectory, path],
  "SourceStatus" -> status|>;

buildResult = Block[{$HistoryLength = 0}, Catch@Module[
  {scriptDirectory, repository, arguments, staleArtifactDirectory,
   v2ArtifactDirectory,
   framePath, inheritedPath, junctionPath, outputPath,
   frame, inherited, junction,
   production, source, layer, p, eps, pEndpoint, p0 = 4/11,
   orders = Range[0, 6], coefficientWindow = {-1, 5}, demand,
   solutionTiming, solution, operatorTiming, operator,
   intrinsicSourceMaps, intrinsicTargetRecords, intrinsicTargetMaps,
   intrinsicWordMaps, normalModeBlocks, inheritedBlockConnections,
   inheritedConnection, inheritedLetters, inheritedResidues,
   inheritedConnectionResidual,
   inheritedWordMaps, combinedWordMaps, modeOrder, intrinsicModeOrder,
   inheritedModeOrder, expectedInheritedModeOrder, intrinsicConnection,
   combinedConnection, declaredConnection, connectionCoefficients,
   recurrenceChecks, normalizationChecks,
   boundaryFunctionIDs, boundaryFunctionValuations,
   baseConstantIDRecords, boundaryDomain, path, leveltEvidence,
   validationConditions, validation,
   inputReferences, fail, readArtifact},

  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  readArtifact[path_, name_] := Module[{value},
    If[! StringQ[path] || ! FileExistsQ[path],
      fail["CF303BoundaryEvolutionInputMissing",
        <|"Input" -> name, "Path" -> path|>]];
    value = Quiet[Check[FeynFacet`FamilyArtifactRead[path], $Failed]];
    If[! AssociationQ[value],
      fail["CF303BoundaryEvolutionInputUnreadable",
        <|"Input" -> name, "Path" -> path|>]];
    value
  ];

  scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
  repository = DirectoryName[scriptDirectory, 3];
  arguments = Rest[$ScriptCommandLine];
  v2ArtifactDirectory = FileNameJoin[{repository,
    "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
    "DifferentialEquationDataV2", "CF303"}];
  staleArtifactDirectory = FileNameJoin[{repository, "Stale",
    "DifferentialEquationData", "2026-09-03_pre_v2", "Scripts",
    "Transport", "CF303", "Artifacts"}];
  framePath = If[Length[arguments] >= 1, arguments[[1]],
    FileNameJoin[{staleArtifactDirectory,
      "CF303SixModeEndpointFrame.wl"}]];
  inheritedPath = If[Length[arguments] >= 2, arguments[[2]],
    FileNameJoin[{staleArtifactDirectory,
      "CF303InheritedSoftSourceNeeds.wl"}]];
  junctionPath = If[Length[arguments] >= 3, arguments[[3]],
    FileNameJoin[{v2ArtifactDirectory,
      "CF303TangentialJunctionMapReconstructed.wl"}]];
  outputPath = If[Length[arguments] >= 4, arguments[[4]],
    FileNameJoin[{v2ArtifactDirectory,
      "CF303TangentialBoundaryEvolutionOperatorV2.wl"}]];

  Get[FileNameJoin[{repository, "Addon", "Load", "LoadFACET.wl"}]];
  frame = readArtifact[framePath, "CF303SixModeEndpointFrame"];
  inherited = readArtifact[inheritedPath, "CF303InheritedSoftSourceNeeds"];
  junction = readArtifact[junctionPath, "CF303TangentialJunctionMap"];

  p = Symbol["Global`p"];
  eps = Symbol["Global`eps"];
  pEndpoint = Symbol["Global`cf303TangentialEndpointP"];

  production = Lookup[frame, "ProductionInput", Missing[]];
  If[! AssociationQ[production] ||
      Lookup[production, "Status", None] =!=
        "CF303SixModeRationalLayerInputAcceptedV1" ||
      Lookup[inherited, "Status", None] =!=
        "CF303InheritedSoftSourceNeedsV1" ||
      Lookup[junction, "Status", None] =!=
        "CF303TangentialJunctionMapReconstructedV1" ||
      Lookup[junction, "IndependentValidationComparisonCount", 0] =!= 112,
    fail["CF303BoundaryEvolutionSourceRecordsInvalid"]];

  modeOrder = Lookup[junction, "CombinedModeOrder", Missing[]];
  intrinsicModeOrder = Lookup[production, "BoundaryCoordinateOrder",
    Missing[]];
  inheritedModeOrder = Lookup[junction, "InheritedModeOrder", Missing[]];
  expectedInheritedModeOrder = {
    "CF1::Class1Volume", "CF12::Class5Physical",
    "CF21::PID6Particular", "CF199::PID9ZeroMode",
    "CF199::Class44LambdaMinus4", "CF53::PID9ZeroMode",
    "CF53::Class44LambdaMinus4"};
  If[! MatchQ[intrinsicModeOrder, {__String}] ||
      Length[intrinsicModeOrder] =!= 6 ||
      inheritedModeOrder =!= expectedInheritedModeOrder ||
      modeOrder =!= Join[intrinsicModeOrder, inheritedModeOrder],
    fail["CF303BoundaryEvolutionModeOrderInvalid"]];
  boundaryFunctionIDs = modeOrder;
  (* These are the normalized soft-mode amplitudes used by the accepted
     junction rebase.  The mode maps carry every additional epsilon shift
     into the 43+2 local-state decks. *)
  boundaryFunctionValuations = AssociationThread[
    boundaryFunctionIDs, ConstantArray[First[coefficientWindow],
      Length[boundaryFunctionIDs]]];

  source = production["Source"];
  layer = Join[KeyDrop[production["Layer"],
      {"Endpoint", "PathEndpoint"}], <|"PathEndpoint" -> pEndpoint|>];
  demand = <|"RequestedOutputPairs" ->
    Flatten[Table[{order, row}, {order, orders}, {row, 2}], 1],
    "PathEndpoint" -> pEndpoint|>;
  solutionTiming = AbsoluteTiming[
    solution =
      FeynFacet`SolveRationalEpsilonDependentBlockByVariationOfConstants[
      source, layer, demand, "PrimeCount" -> 3,
      "IteratedIntegralCoefficientRepresentation" ->
        "LazyCoefficientOperator"]];
  If[Lookup[solution, "Status", None] =!=
        "RationalEpsilonDependentBlockSolutionAccepted" ||
      ! TrueQ[FeynFacet`VerifyRationalEpsilonDependentBlockSolution[
        solution, source, layer, demand]],
    fail["CF303IntrinsicBoundaryEvolutionSolveFailed",
      <|"Result" -> solution|>]];
  operatorTiming = AbsoluteTiming[
    operator =
      FeynFacet`ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
        source, layer, solution]];
  If[! FeynFacet`RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[
      operator],
    fail["CF303IntrinsicBoundaryEvolutionOperatorFailed",
      <|"Result" -> operator|>]];

  intrinsicSourceMaps = Association@Table[order ->
    cf303SourceCoefficientWordMap[operator, order], {order, orders}];
  intrinsicTargetRecords = Association@Table[order ->
    FeynFacet`ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[
      operator, {order, {1, 2}}], {order, orders}];
  If[! AllTrue[Values[intrinsicTargetRecords],
      Lookup[#, "Status", None] ===
        "RationalEpsilonDependentBlockIteratedIntegralCoefficientMapConstructed" &],
    fail["CF303IntrinsicBoundaryEvolutionCoefficientMapFailed",
      <|"Statuses" -> Lookup[Values[intrinsicTargetRecords], "Status"]|>]];
  intrinsicTargetMaps = Map[
    Lookup[#, "IteratedIntegralCoefficientMap", <||>] &,
    intrinsicTargetRecords];
  intrinsicWordMaps = Association@Table[order ->
    cf303MergeWordMaps[{
      Map[cf303EmbedRows[#, 0, 2] &, intrinsicSourceMaps[order]],
      Map[cf303EmbedRows[#, 4, 0] &, intrinsicTargetMaps[order]]}],
    {order, orders}];
  intrinsicWordMaps = Map[
    Map[cf303EndpointMatrix[#, pEndpoint, p] &, #] &,
    intrinsicWordMaps];

  normalModeBlocks = Lookup[inherited, "NormalModeBlocks", Missing[]];
  If[! ListQ[normalModeBlocks] || Length[normalModeBlocks] =!= 5,
    fail["CF303InheritedBoundaryEvolutionBlocksInvalid"]];
  inheritedBlockConnections = Map[
    Lookup[#, "TangentialConnectionInModeFrame",
      Lookup[#, "TangentialConnection", Missing[]]] &,
    normalModeBlocks];
  If[! AllTrue[inheritedBlockConnections,
      MatrixQ[#] && Equal @@ Dimensions[#] &] ||
      Total[Length /@ inheritedBlockConnections] =!= 7,
    fail["CF303InheritedBoundaryEvolutionConnectionInvalid"]];
  inheritedConnection = cf303BlockDiagonal[inheritedBlockConnections];
  inheritedLetters = {{"GPLPole", 0}, {"GPLPole", 1},
    {"GPLPole", -1}};
  inheritedResidues = Association@Table[letter ->
    cf303ResidueMatrix[inheritedConnection/eps, p, Last[letter]],
    {letter, inheritedLetters}];
  inheritedConnectionResidual = inheritedConnection - eps Total[
    KeyValueMap[#2 FeynFacet`IteratedIntegralKernel[#1, p, None] &,
      inheritedResidues]];
  If[! cf303ExactZeroMatrixQ[inheritedConnectionResidual],
    fail["CF303InheritedBoundaryEvolutionDLogDecompositionFailed",
      <|"Residual" -> Map[Together, inheritedConnectionResidual, {2}],
        "TangentialVariableOwnValues" -> OwnValues[p],
        "DimensionalRegulatorOwnValues" -> OwnValues[eps]|>]];
  inheritedWordMaps = Association@Table[order ->
    cf303EpsilonFormCoefficientWordMap[inheritedResidues, order],
    {order, orders}];

  combinedWordMaps = Association@Table[order ->
    cf303MergeWordMaps[{
      Map[cf303BlockDiagonal[{#, ConstantArray[0, {7, 7}]}] &,
        intrinsicWordMaps[order]],
      Map[cf303BlockDiagonal[{ConstantArray[0, {6, 6}], #}] &,
        inheritedWordMaps[order]]}], {order, orders}];

  intrinsicConnection = cf303IntrinsicConnection[source, layer, p, eps];
  combinedConnection = cf303BlockDiagonal[
    {intrinsicConnection, inheritedConnection}];
  declaredConnection = combinedConnection;

  connectionCoefficients = Association@Table[order ->
    Map[SeriesCoefficient[#, {eps, 0, order}] &,
      combinedConnection, {2}], {order, orders}];
  recurrenceChecks = Association@Table[order ->
    cf303WordMapEqualQ[
      cf303DerivativeWordMap[combinedWordMaps[order], p],
      cf303MergeWordMaps[Table[
        cf303LeftMultiplyWordMap[connectionCoefficients[k],
          combinedWordMaps[order - k]], {k, 0, order}]], 13],
    {order, orders}];
  normalizationChecks = Association@Table[order ->
    cf303ExactZeroMatrixQ[
      (Normal[Lookup[combinedWordMaps[order], Key[{}],
          ConstantArray[0, {13, 13}]]] /. p -> p0) -
        If[order === 0, IdentityMatrix[13],
          ConstantArray[0, {13, 13}]]], {order, orders}];

  boundaryDomain = <|
    "Type" -> "PhysicalBoundaryStratum",
    "TangentialVariables" -> {p},
    "PhysicalKinematicLimit" -> HoldForm[1 - Global`v - Global`w == 0],
    "PhysicalParameterization" ->
      {Global`v -> p^2, Global`w -> 1 - p^2},
    "NormalCoordinate" ->
      HoldForm[Evaluate[Global`rho == 2 p - Global`z]]|>;
  path = <|
    "Type" -> "TangentialPathOnPhysicalBoundaryStratum",
    "TangentialVariable" -> p, "From" -> p0, "To" -> p,
    "Parameterization" -> {p, p0, p},
    "Orientation" -> "TangentialBasePointToBoundaryPoint",
    "ConnectionSingularDivisors" -> DeleteDuplicates[
      Join[Cases[source["Letters"], {"GPLPole", point_} :> p - point],
        Cases[source["Letters"], {"GPLFactor", polynomial_, _} :>
          polynomial],
        Cases[layer["Diagonal"],
          {{"GPLPole", point_}, _} :> p - point],
        (p - Last[#] &) /@ inheritedLetters]]|>;
  baseConstantIDRecords = Map[
    <|"BoundaryFunctionID" -> #,
      "BoundaryConstantID" ->
        {"CF303", "SoftStratumTangentialBasePoint", #},
      "BasePoint" -> <|"Coordinates" -> {p -> p0}|>|> &,
    boundaryFunctionIDs];
  leveltEvidence = <|
    "TangentialJunctionMapReference" -> cf303InputReference[
      DirectoryName[ExpandFileName[outputPath]], junctionPath,
      Lookup[junction, "Status", Missing[]]],
    "EvidenceLocation" -> {"Regularization", "ResonantZeroSector"},
    "CheckedRhoOrders" -> Lookup[junction["Regularization"],
      "CheckedRhoOrders", Missing[]],
    "EpsilonCoefficientWindow" -> Lookup[junction["Regularization"],
      "EpsilonCoefficientWindow", Missing[]],
    "Status" -> Lookup[junction["Regularization"], "Status", Missing[]],
    "Role" ->
      "Bounded local Levelt-recurrence evidence; the singular normal-path operator generates the logarithmic term and does not consume an all-orders C(p,eps)"|>;

  validationConditions = <|
    "BoundaryFunctionDifferentialEquation" ->
      And @@ Values[recurrenceChecks],
    "TangentialBasePointNormalization" ->
      And @@ Values[normalizationChecks],
    "EpsilonOrderCoverage" -> Keys[combinedWordMaps] === orders,
    "CombinedModeOrderAccepted" -> boundaryFunctionIDs === modeOrder,
    "IntrinsicRationalEpsilonSolutionReverified" ->
      TrueQ[FeynFacet`VerifyRationalEpsilonDependentBlockSolution[
        solution, source, layer, demand]],
    "IntrinsicRequestedCoefficientMapsComplete" ->
      Length[intrinsicTargetRecords] === Length[orders] &&
        AllTrue[Values[intrinsicTargetRecords],
          Lookup[#, "Status", None] ===
            "RationalEpsilonDependentBlockIteratedIntegralCoefficientMapConstructed" &],
    "InheritedDLogDecompositionExact" ->
      cf303ExactZeroMatrixQ[inheritedConnection - eps Total[
        KeyValueMap[#2 FeynFacet`IteratedIntegralKernel[#1, p, None] &,
          inheritedResidues]]],
    "BoundedNormalLeveltRecurrenceEvidenceAccepted" ->
      leveltEvidence["Status"] ===
        "TangentialJunctionIntertwiningJetsAccepted"|>;
  If[! And @@ Values[validationConditions],
    fail["CF303BoundaryEvolutionValidationFailed",
      <|"Conditions" -> validationConditions,
        "RecurrenceChecks" -> recurrenceChecks,
        "NormalizationChecks" -> normalizationChecks|>]];
  validation = <|
    "Method" -> "ExactCoefficientWordRecurrence",
    "Conditions" -> validationConditions,
    "Evidence" -> <|
      "EvolutionDifferentialEquation" ->
        "D[U_r(p,p0),p]=Sum[Omega_k(p).U_(r-k)(p,p0),{k,0,r}]",
      "RecurrenceChecksByEpsilonOrder" -> recurrenceChecks,
      "BasePointNormalizationChecksByEpsilonOrder" ->
        normalizationChecks,
      "IntrinsicCoefficientWordCounts" -> Map[Length, intrinsicWordMaps],
      "InheritedCoefficientWordCounts" -> Map[Length, inheritedWordMaps],
      "CombinedCoefficientWordCounts" -> Map[Length, combinedWordMaps],
      "JunctionIndependentValidationComparisonCount" ->
        junction["IndependentValidationComparisonCount"],
      "BoundedNormalLeveltRecurrenceEvidence" -> leveltEvidence|>|>;
  inputReferences = <|
    "SixModeEndpointFrame" -> cf303InputReference[
      DirectoryName[ExpandFileName[outputPath]], framePath,
      Lookup[production, "Status", Missing[]]],
    "InheritedSoftSourceNeeds" -> cf303InputReference[
      DirectoryName[ExpandFileName[outputPath]], inheritedPath,
      Lookup[inherited, "Status", Missing[]]],
    "TangentialJunctionMap" -> cf303InputReference[
      DirectoryName[ExpandFileName[outputPath]], junctionPath,
      Lookup[junction, "Status", Missing[]]]|>;
  <|
    "DataType" -> "TangentialBoundaryEvolutionOperator",
    "SchemaVersion" -> 2,
    "Status" -> "TangentialBoundaryEvolutionOperatorValidated",
    "Family" -> "CF303",
    "ConstructionInputReferences" -> inputReferences,
    "BoundaryDomain" -> boundaryDomain,
    "DimensionalRegulator" -> eps,
    "BoundaryFunctionIDs" -> boundaryFunctionIDs,
    "BoundaryFunctionEpsilonValuations" ->
      boundaryFunctionValuations,
    "TangentialBasePoint" -> <|"Type" -> "RegularTangentialBasePoint",
      "Coordinates" -> {p -> p0}|>,
    "TangentialPath" -> path,
    "BoundaryFunctionConnectionMatrix" -> declaredConnection,
    "BoundedNormalLeveltRecurrenceEvidence" -> leveltEvidence,
    "EvolutionConvention" ->
      "c(t,eps)=U(t,t0;eps).c(t0,eps)",
    "EvolutionOperatorEpsilonValuation" -> First[orders],
    "EpsilonOrderWindow" -> MinMax[orders],
    "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder" ->
      combinedWordMaps,
    "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
    "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs" ->
      baseConstantIDRecords,
    "TimingsSeconds" -> <|"IntrinsicSolve" -> First[solutionTiming],
      "IntrinsicCoefficientOperator" -> First[operatorTiming]|>,
    "Validation" -> validation,
    "OutputPath" -> outputPath|>
]];

If[AssociationQ[buildResult] &&
    Lookup[buildResult, "Status", None] ===
      "TangentialBoundaryEvolutionOperatorValidated" &&
    TrueQ[FeynFacet`TangentialBoundaryEvolutionOperatorQ[buildResult]],
  outputPath = buildResult["OutputPath"];
  If[! DirectoryQ[DirectoryName[outputPath]],
    CreateDirectory[DirectoryName[outputPath],
      CreateIntermediateDirectories -> True]];
  Put[KeyDrop[buildResult, "OutputPath"], outputPath];
  Print["PASS status=", buildResult["Status"],
    " wordCounts=", InputForm[Map[Length,
      buildResult[
        "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder"]]],
    " output=", outputPath];
  Quit[0],
  Print["FAIL status=", Lookup[buildResult, "Status", Missing[]]];
  Quit[2]
];
