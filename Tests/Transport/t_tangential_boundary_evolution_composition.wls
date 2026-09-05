#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

t = Symbol["Global`tangentialCompositionT"];
eps = Symbol["Global`eps"];
family = "TangentialCompositionToy";
functionIDs = {{family, "f1"}, {family, "f2"}};
baseConstantIDs = {{family, "t0", "c1"}, {family, "t0", "c2"}};
letter = {"GPLPole", 0};
residue = {{0, 1}, {0, 0}};

evolution = <|
  "DataType" -> "TangentialBoundaryEvolutionOperator",
  "SchemaVersion" -> 2,
  "Status" -> "TangentialBoundaryEvolutionOperatorValidated",
  "Family" -> family,
  "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryStratum",
    "TangentialVariables" -> {t}|>,
  "DimensionalRegulator" -> eps,
  "BoundaryFunctionIDs" -> functionIDs,
  "BoundaryFunctionEpsilonValuations" ->
    AssociationThread[functionIDs, {0, 0}],
  "TangentialBasePoint" -> <|"Coordinates" -> {t -> 1}|>,
  "TangentialPath" -> <|"TangentialVariables" -> {t},
    "From" -> {t -> 1}, "To" -> {t -> t}|>,
  "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs" -> {
    <|"BoundaryFunctionID" -> functionIDs[[1]],
      "BoundaryConstantID" -> baseConstantIDs[[1]]|>,
    <|"BoundaryFunctionID" -> functionIDs[[2]],
      "BoundaryConstantID" -> baseConstantIDs[[2]]|>},
  "EvolutionOperatorEpsilonValuation" -> 0,
  "EpsilonOrderWindow" -> {0, 1},
  "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder" -> <|
    0 -> <|{} -> IdentityMatrix[2]|>,
    1 -> <|{letter} -> residue|>|>,
  "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
  "EvolutionConvention" -> "c(t,eps)=U(t,t0;eps).c(t0,eps)",
  "Validation" -> <|"Method" -> "ExactCoefficientRecurrence",
    "Conditions" -> <|
      "BoundaryFunctionDifferentialEquation" -> True,
      "TangentialBasePointNormalization" -> True,
      "EpsilonOrderCoverage" -> True|>|>|>;

FTAssert["the strict tangential-evolution schema accepts the complete operator",
  TangentialBoundaryEvolutionOperatorQ[evolution] &&
    FreeQ[Keys[evolution], "NormalResidueNormalForm" |
      "BoundaryModeCoefficientMatrixInNormalResidueBasis" |
      "ExactLeveltEmbedding"]];
FTAssert["the schema rejects missing coverage and expanded formula duplication",
  ! TangentialBoundaryEvolutionOperatorQ[
      KeyDrop[evolution, "EvolutionOperatorEpsilonValuation"]] &&
    ! TangentialBoundaryEvolutionOperatorQ[Join[evolution,
      <|"BoundaryFunctionEpsilonCoefficientFormulas" -> {}|>]]];
FTAssert["the schema validates matrix dimensions and the complete epsilon window",
  ! TangentialBoundaryEvolutionOperatorQ[ReplacePart[evolution,
      {"EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder", Key[1],
        Key[{letter}]} -> {{1}}]] &&
    ! TangentialBoundaryEvolutionOperatorQ[ReplacePart[evolution,
      "EpsilonOrderWindow" -> {0, 2}]]];
missingIntermediateOrder = ReplacePart[evolution, {
  "EpsilonOrderWindow" -> {0, 2},
  "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder" -> <|
    0 -> <|{} -> IdentityMatrix[2]|>, 2 -> <||>|>}];
FTAssert["the schema rejects a missing intermediate epsilon order",
  ! TangentialBoundaryEvolutionOperatorQ[missingIntermediateOrder]];

inputCoordinates = {
  <|"BoundaryDataType" -> "BoundaryFunction",
    "BoundaryFunctionID" -> functionIDs[[1]], "EpsilonOrder" -> 0|>,
  <|"BoundaryDataType" -> "BoundaryFunction",
    "BoundaryFunctionID" -> functionIDs[[2]], "EpsilonOrder" -> 0|>,
  <|"BoundaryDataType" -> "BoundaryFunction",
    "BoundaryFunctionID" -> functionIDs[[1]], "EpsilonOrder" -> 1|>,
  <|"BoundaryDataType" -> "BoundaryFunction",
    "BoundaryFunctionID" -> functionIDs[[2]], "EpsilonOrder" -> 1|>};
boundaryMap = <|
  "DataType" -> "BoundaryFunctionToMasterIntegralSolutionMap",
  "SchemaVersion" -> 2,
  "Status" -> "BoundaryFunctionToMasterIntegralSolutionMapValidated",
  "Family" -> family,
  "BoundaryDataType" -> "BoundaryFunction",
  "BoundaryDomain" -> evolution["BoundaryDomain"],
  "DimensionalRegulator" -> eps,
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{0, 1}},
  "DemandCoverage" -> "Complete",
  "BoundaryFunctionEpsilonCoefficientRecords" -> inputCoordinates,
  "BoundaryFunctionEpsilonCoefficientLabels" ->
    ({#["BoundaryFunctionID"], #["EpsilonOrder"]} & /@ inputCoordinates),
  "IteratedIntegralCoefficientMatrixRecords" -> {
    <|"CurrentPathFirstSegmentLetterIndices" -> {11},
      "CurrentPathSecondSegmentLetterIndices" -> {},
      "BoundaryPathFirstSegmentLetterIndices" -> {},
      "BoundaryPathSecondSegmentLetterIndices" -> {7},
      "IteratedIntegralCoefficientMatrix" ->
        SparseArray[{{1, 0, 1, 0}}]|>,
    <|"CurrentPathFirstSegmentLetterIndices" -> {11},
      "CurrentPathSecondSegmentLetterIndices" -> {},
      "BoundaryPathFirstSegmentLetterIndices" -> {},
      "BoundaryPathSecondSegmentLetterIndices" -> {7},
      "IteratedIntegralCoefficientMatrix" ->
        SparseArray[{{0, 1, 0, 1}}]|>},
  "BoundaryDataRequirements" -> {},
  "FormalResultConvention" -> <||>,
  "Validation" -> <|"Method" -> "ExactToyConstruction",
    "Conditions" -> <|"CoefficientMatrices" -> True,
      "BoundaryFunctionInterface" -> True,
      "DemandCoverage" -> True|>|>|>;

composed = ComposeBoundaryFunctionSolutionMapWithTangentialEvolution[
  boundaryMap, evolution];
labels = Lookup[composed, "BoundaryConstantEpsilonCoefficientLabels", {}];
terms = Lookup[composed, "IteratedIntegralCoefficientMatrixTerms", {}];
emptyTerm = SelectFirst[terms,
  #["TangentialBoundaryPathIteratedIntegralLetterSequence"] === {} &, <||>];
letterTerm = SelectFirst[terms,
  #["TangentialBoundaryPathIteratedIntegralLetterSequence"] === {letter} &,
  <||>];
coefficient[term_, id_, order_] := Module[{position},
  position = FirstPosition[labels, {id, order}, Missing[]];
  If[MissingQ[position], Missing[],
    Normal[term["IteratedIntegralCoefficientMatrix"]][[
      1, First[position]]]]
];

FTAssert["composition changes boundary functions into base-point constants",
  composed["DataType"] === "BoundaryConstantToMasterIntegralSolutionMap" &&
    composed["Status"] ===
      "BoundaryConstantToMasterIntegralSolutionMapConstructed" &&
    composed["BoundaryDataType"] === "BoundaryConstant" &&
    ContainsAll[Keys[First[terms]], {
      "CurrentPathFirstSegmentLetterIndices",
      "CurrentPathSecondSegmentLetterIndices",
      "BoundaryPathFirstSegmentLetterIndices",
      "BoundaryPathSecondSegmentLetterIndices",
      "TangentialBoundaryPathIteratedIntegralLetterSequence"}] &&
    composed["PathSegmentConvention", "SegmentMultiplicationOrder"] === {
      "CurrentPathFirstSegment", "CurrentPathSecondSegment",
      "BoundaryPathFirstSegment", "BoundaryPathSecondSegment",
      "TangentialBoundaryPath"} &&
    emptyTerm["CurrentPathFirstSegmentLetterIndices"] === {11} &&
    emptyTerm["BoundaryPathSecondSegmentLetterIndices"] === {7} &&
    Sort[labels] === Sort[Flatten[Table[
      {baseConstantIDs[[i]], order}, {i, 2}, {order, 0, 1}], 1]]];
FTAssert["the empty tangential sequence carries U0 and duplicate maps merge",
  AssociationQ[emptyTerm] &&
    coefficient[emptyTerm, baseConstantIDs[[1]], 0] === 1 &&
    coefficient[emptyTerm, baseConstantIDs[[2]], 0] === 1 &&
    coefficient[emptyTerm, baseConstantIDs[[1]], 1] === 1];
FTAssert["the nonempty sequence contracts the boundary-function matrix row",
  AssociationQ[letterTerm] &&
    coefficient[letterTerm, baseConstantIDs[[2]], 0] === 1 &&
    coefficient[letterTerm, baseConstantIDs[[1]], 0] === 0];

shortEvolution = ReplacePart[evolution, {
  "EpsilonOrderWindow" -> {0, 0},
  "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder" -> <|
    0 -> <|{} -> IdentityMatrix[2]|>|>}];
insufficient = ComposeBoundaryFunctionSolutionMapWithTangentialEvolution[
  boundaryMap, shortEvolution];
FTAssert["composition refuses an evolution window too short for its inputs",
  FailureQ[insufficient] && insufficient["Status"] ===
    "TangentialBoundaryEvolutionEpsilonWindowInsufficient"];

FTReport[];
