#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

t = Symbol["Global`factorizedBoundaryT"];
eps = Symbol["Global`eps"];
family = "FactorizedBoundaryStratumToy";
functionIDs = {{family, "f1"}, {family, "f2"}};
baseConstantIDs = {{family, "t0", "c1"}, {family, "t0", "c2"}};
letter = {"GPLPole", 0};
familySystemReferenceFor[name_String] := <|
  "RelativePath" -> name <> "_family_differential_system.wl",
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> name|>;
requirementsReference = <|
  "RelativePath" ->
    "Tests/Fixtures/factorized_boundary_stratum_requirements.wl",
  "DataType" -> "MasterIntegralEpsilonOrderRequirements",
  "SchemaVersion" -> 2,
  "Status" -> "MasterIntegralEpsilonOrderRequirementsDerived",
  "MathematicalInputReferences" -> <||>|>;

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
    1 -> <|{letter} -> {{0, 1}, {0, 0}}|>|>,
  "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
  "EvolutionConvention" -> "c(t,eps)=U(t,t0;eps).c(t0,eps)",
  "Validation" -> <|"Method" -> "ExactCoefficientRecurrence",
    "Conditions" -> <|
      "BoundaryFunctionDifferentialEquation" -> True,
      "TangentialBasePointNormalization" -> True,
      "EpsilonOrderCoverage" -> True|>|>|>;

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
  "FamilyDifferentialSystemReference" ->
    familySystemReferenceFor[family],
  "MasterIntegralEpsilonOrderRequirementsReference" ->
    requirementsReference,
  "BoundaryDataType" -> "BoundaryFunction",
  "BoundaryDomain" -> evolution["BoundaryDomain"],
  "DimensionalRegulator" -> eps,
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{0, 1}},
  "DemandCoverage" -> "Complete",
  "BoundaryFunctionEpsilonCoefficientRecords" -> inputCoordinates,
  "BoundaryFunctionEpsilonCoefficientLabels" ->
    ({#["BoundaryFunctionID"], #["EpsilonOrder"]} & /@
      inputCoordinates),
  "IteratedIntegralCoefficientMatrixRecords" -> {
    <|"CurrentPathFirstSegmentLetterIndices" -> {11},
      "CurrentPathSecondSegmentLetterIndices" -> {},
      "BoundaryPathFirstSegmentLetterIndices" -> {},
      "BoundaryPathSecondSegmentLetterIndices" -> {7},
      "IteratedIntegralCoefficientMatrix" ->
        SparseArray[{{1, 0, 1, 0}}]|>,
    <|"CurrentPathFirstSegmentLetterIndices" -> {12},
      "CurrentPathSecondSegmentLetterIndices" -> {},
      "BoundaryPathFirstSegmentLetterIndices" -> {},
      "BoundaryPathSecondSegmentLetterIndices" -> {8},
      "IteratedIntegralCoefficientMatrix" ->
        SparseArray[{{0, 1, 0, 1}}]|>},
  "BoundaryDataRequirements" -> {},
  "FormalResultConvention" -> <|
    "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst"|>,
  "Validation" -> <|"Method" -> "ExactToyConstruction",
    "Conditions" -> <|"CoefficientMatrices" -> True,
      "BoundaryFunctionInterface" -> True,
      "DemandCoverage" -> True|>|>|>;

pathKey[record_Association, tangentialSequence_List] := With[
  {currentFirst = record["CurrentPathFirstSegmentLetterIndices"],
   currentSecond = record["CurrentPathSecondSegmentLetterIndices"],
   boundaryFirst = record["BoundaryPathFirstSegmentLetterIndices"],
   boundarySecond = record["BoundaryPathSecondSegmentLetterIndices"],
   sequence = tangentialSequence},
  HoldComplete[currentFirst, currentSecond, boundaryFirst, boundarySecond,
    sequence]];

coefficientTermAssociation[records_List, tangentialKey_String] := Module[
  {pieces, merged},
  pieces = Cases[records, record_Association :>
    pathKey[record, Lookup[record, tangentialKey, {}]] ->
      SparseArray[record["IteratedIntegralCoefficientMatrix"]]];
  merged = If[pieces === {}, <||>,
    Merge[(Association[#] &) /@ pieces,
      SparseArray[Total[Normal /@ #]] &]];
  Select[merged, Length[#["NonzeroPositions"]] > 0 &]
];

expandOrderedProduct[solution_Association] := Module[
  {product, left, right, pieces, merged},
  product = solution["OrderedSparseCoefficientOperatorProduct"];
  left = product["LeftFactor"][
    "IteratedIntegralCoefficientMatrixRecords"];
  right = product["RightFactor"][
    "EpsilonLiftedIteratedIntegralCoefficientMatrixRecords"];
  pieces = Flatten[Table[With[
      {matrix = SparseArray[
          left[[i]]["IteratedIntegralCoefficientMatrix"] .
          right[[j]]["IteratedIntegralCoefficientMatrix"]]},
      If[Length[matrix["NonzeroPositions"]] === 0, Nothing,
        pathKey[left[[i]], right[[j]][
          "TangentialBoundaryPathIteratedIntegralLetterSequence"]] ->
          matrix]], {i, Length[left]}, {j, Length[right]}]];
  merged = If[pieces === {}, <||>,
    Merge[(Association[#] &) /@ pieces,
      SparseArray[Total[Normal /@ #]] &]];
  Select[merged, Length[#["NonzeroPositions"]] > 0 &]
];

sameCoefficientTermsQ[first_Association, second_Association] :=
  Sort[Keys[first]] === Sort[Keys[second]] &&
    AllTrue[Keys[first],
      Normal[first[[Key[#]]]] === Normal[second[[Key[#]]]] &];

factorized = ConstructMasterIntegralSolution[boundaryMap, evolution];
missingReference = ConstructMasterIntegralSolution[
  KeyDrop[boundaryMap, "MasterIntegralEpsilonOrderRequirementsReference"],
  evolution];
eager = ComposeBoundaryFunctionSolutionMapWithTangentialEvolution[
  boundaryMap, evolution];
factorizedTerms = expandOrderedProduct[factorized];
eagerTerms = coefficientTermAssociation[
  eager["IteratedIntegralCoefficientMatrixTerms"],
  "TangentialBoundaryPathIteratedIntegralLetterSequence"];

FTAssert["the boundary-stratum result is one V2 MasterIntegralSolution in terms of boundary constants",
  factorized["DataType"] === "MasterIntegralSolution" &&
    factorized["SchemaVersion"] === 2 &&
    factorized["Status"] ===
      "MasterIntegralSolutionConstructed" &&
    factorized["SolutionType"] ===
      "MasterIntegralSolutionInTermsOfBoundaryConstants" &&
    factorized["SolutionRepresentation"] ===
      "OrderedSparseCoefficientOperatorProduct" &&
    factorized["FamilyDifferentialSystemReference"] ===
      familySystemReferenceFor[family] &&
    factorized["MasterIntegralEpsilonOrderRequirementsReference"] ===
      requirementsReference &&
    factorized["DemandCoverage"] === "Complete" &&
    factorized["BoundaryDataStatus"] === "Undetermined" &&
    ! KeyExistsQ[factorized, "IteratedIntegralCoefficientMatrixTerms"]];

FTAssert["the exact ordered sparse product contracts to the eager coefficient maps",
  sameCoefficientTermsQ[factorizedTerms, eagerTerms] &&
    factorized["BoundaryConstantEpsilonCoefficientLabels"] ===
      eager["BoundaryConstantEpsilonCoefficientLabels"]];

FTAssert["the structural predicate rederives the lift and rejects a changed factor",
  MasterIntegralSolutionQ[factorized] &&
    ! MasterIntegralSolutionQ[ReplacePart[factorized,
      {"OrderedSparseCoefficientOperatorProduct", "RightFactor",
       "EpsilonLiftedIteratedIntegralCoefficientMatrixRecords", 1,
       "IteratedIntegralCoefficientMatrix"} -> SparseArray[{{1}}]]]];

FTAssert["a V2 boundary-stratum solution requires both mathematical-input references",
  FailureQ[missingReference] &&
    missingReference["Status"] ===
      "MasterIntegralEpsilonOrderRequirementsReferenceRequired"];

scaleFamily = "FactorizedScalingToy";
scaleFunctionID = {scaleFamily, "f"};
scaleConstantID = {scaleFamily, "t0", "c"};
leftCount = 20;
rightCount = 30;
scaleEvolution = <|
  "DataType" -> "TangentialBoundaryEvolutionOperator",
  "SchemaVersion" -> 2,
  "Status" -> "TangentialBoundaryEvolutionOperatorValidated",
  "Family" -> scaleFamily,
  "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryStratum",
    "TangentialVariables" -> {t}|>,
  "DimensionalRegulator" -> eps,
  "BoundaryFunctionIDs" -> {scaleFunctionID},
  "BoundaryFunctionEpsilonValuations" -> <|scaleFunctionID -> 0|>,
  "TangentialBasePoint" -> <|"Coordinates" -> {t -> 1}|>,
  "TangentialPath" -> <|"TangentialVariables" -> {t},
    "From" -> {t -> 1}, "To" -> {t -> t}|>,
  "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs" -> {
    <|"BoundaryFunctionID" -> scaleFunctionID,
      "BoundaryConstantID" -> scaleConstantID|>},
  "EvolutionOperatorEpsilonValuation" -> 0,
  "EpsilonOrderWindow" -> {0, 0},
  "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder" -> <|
    0 -> Association@Table[{{"ToyKernel", j}} -> {{1}},
      {j, rightCount}]|>,
  "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
  "EvolutionConvention" -> "c(t,eps)=U(t,t0;eps).c(t0,eps)",
  "Validation" -> <|"Method" -> "ExactToyConstruction",
    "Conditions" -> <|
      "BoundaryFunctionDifferentialEquation" -> True,
      "TangentialBasePointNormalization" -> True,
      "EpsilonOrderCoverage" -> True|>|>|>;
scaleCoordinate = <|"BoundaryDataType" -> "BoundaryFunction",
  "BoundaryFunctionID" -> scaleFunctionID, "EpsilonOrder" -> 0|>;
scaleBoundaryMap = <|
  "DataType" -> "BoundaryFunctionToMasterIntegralSolutionMap",
  "SchemaVersion" -> 2,
  "Status" -> "BoundaryFunctionToMasterIntegralSolutionMapValidated",
  "Family" -> scaleFamily, "BoundaryDataType" -> "BoundaryFunction",
  "FamilyDifferentialSystemReference" ->
    familySystemReferenceFor[scaleFamily],
  "MasterIntegralEpsilonOrderRequirementsReference" ->
    requirementsReference,
  "BoundaryDomain" -> scaleEvolution["BoundaryDomain"],
  "DimensionalRegulator" -> eps,
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{0, 1}},
  "DemandCoverage" -> "Complete",
  "BoundaryFunctionEpsilonCoefficientRecords" -> {scaleCoordinate},
  "BoundaryFunctionEpsilonCoefficientLabels" ->
    {{scaleFunctionID, 0}},
  "IteratedIntegralCoefficientMatrixRecords" -> Table[
    <|"CurrentPathFirstSegmentLetterIndices" -> {j},
      "CurrentPathSecondSegmentLetterIndices" -> {},
      "BoundaryPathFirstSegmentLetterIndices" -> {},
      "BoundaryPathSecondSegmentLetterIndices" -> {},
      "IteratedIntegralCoefficientMatrix" -> SparseArray[{{1}}]|>,
    {j, leftCount}],
  "BoundaryDataRequirements" -> {},
  "FormalResultConvention" -> <||>,
  "Validation" -> <|"Method" -> "ExactToyConstruction",
    "Conditions" -> <|"CoefficientMatrices" -> True,
      "BoundaryFunctionInterface" -> True,
      "DemandCoverage" -> True|>|>|>;

scaleFactorized = ConstructMasterIntegralSolution[
  scaleBoundaryMap, scaleEvolution];
scaleEager = ComposeBoundaryFunctionSolutionMapWithTangentialEvolution[
  scaleBoundaryMap, scaleEvolution];
scaleProduct = scaleFactorized[
  "OrderedSparseCoefficientOperatorProduct"];
scaleDependency = First[scaleFactorized[
  "BoundaryConstantEpsilonCoefficientEvaluationWorklist",
  "BoundaryFunctionInterfaceCoordinateDependencies"]];

FTAssert["factor storage grows as left plus right rather than their Cartesian product",
  Length[scaleProduct["LeftFactor"][
      "IteratedIntegralCoefficientMatrixRecords"]] === leftCount &&
    Length[scaleProduct["RightFactor"][
      "EpsilonLiftedIteratedIntegralCoefficientMatrixRecords"]] ===
      rightCount &&
    Length[scaleDependency["LeftFactorRecordIndices"]] +
      Length[scaleDependency["RightFactorRecordIndices"]] ===
      leftCount + rightCount &&
    Length[scaleEager[
      "IteratedIntegralCoefficientMatrixTerms"]] === leftCount rightCount];

FTReport[];
