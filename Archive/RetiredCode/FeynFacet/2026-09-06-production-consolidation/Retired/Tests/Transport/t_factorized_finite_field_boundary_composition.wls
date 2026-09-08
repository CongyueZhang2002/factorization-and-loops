#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

t = Symbol["Global`factorizedFiniteFieldT"];
eps = Symbol["Global`factorizedFiniteFieldEps"];
prime = 101;
family = "FactorizedFiniteFieldToy";
functionIDs = {{family, "f1"}, {family, "f2"}};
baseConstantIDs = {{family, "t0", "c1"}, {family, "t0", "c2"}};

familySystemReference = <|
  "RelativePath" -> "Tests/Fixtures/factorized_finite_field_system.wl",
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> family|>;
requirementsReference = <|
  "RelativePath" ->
    "Tests/Fixtures/factorized_finite_field_requirements.wl",
  "DataType" -> "MasterIntegralEpsilonOrderRequirements",
  "SchemaVersion" -> 2,
  "Status" -> "MasterIntegralEpsilonOrderRequirementsDerived",
  "MathematicalInputReferences" -> <||>|>;
boundaryDomain = <|"Type" -> "PhysicalBoundaryStratum",
  "TangentialVariables" -> {t}|>;

evolution = <|
  "DataType" -> "TangentialBoundaryEvolutionOperator",
  "SchemaVersion" -> 2,
  "Status" -> "TangentialBoundaryEvolutionOperatorValidated",
  "Family" -> family,
  "BoundaryDomain" -> boundaryDomain,
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
  "EpsilonOrderWindow" -> {0, 0},
  "EvolutionOperatorIteratedIntegralCoefficientMapsByEpsilonOrder" -> <|
    0 -> <|{} -> IdentityMatrix[2],
      {{"ToyTangentialLetter", 1}} -> {{0, 1}, {1, 0}}|>|>,
  "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
  "EvolutionConvention" -> "c(t,eps)=U(t,t0;eps).c(t0,eps)",
  "Validation" -> <|"Method" -> "ExactToyConstruction",
    "Conditions" -> <|
      "BoundaryFunctionDifferentialEquation" -> True,
      "TangentialBasePointNormalization" -> True,
      "EpsilonOrderCoverage" -> True|>|>|>;

coordinates = {
  <|"BoundaryDataType" -> "BoundaryFunction",
    "BoundaryFunctionID" -> functionIDs[[1]], "EpsilonOrder" -> 0|>,
  <|"BoundaryDataType" -> "BoundaryFunction",
    "BoundaryFunctionID" -> functionIDs[[2]], "EpsilonOrder" -> 0|>};

rationalDefinition = <|
  "CoefficientDefinitionID" -> "q-rational",
  "Representation" -> "RationalFunctionModuloPrime",
  "NumeratorCoefficientsModuloPrime" -> {1, 2},
  "DenominatorCoefficientsModuloPrime" -> {1}|>;
lazyDefinition = <|
  "CoefficientDefinitionID" -> "q-lazy-endpoint",
  "Representation" -> "OrderedExactEndpointFunctionalSumModuloPrime",
  "OrderedComponents" -> {
    <|"SignModuloPrime" -> 1,
      "ExactEndpointFunctional" -> <|
        "Operation" -> "RegularizedEndpointFunctional",
        "MathematicalDefinition" ->
          "Take the rho^0 coefficient of the normalized Hermite primitive.",
        "SourceReferences" -> {<|
          "RelativePath" ->
            "Tests/Fixtures/exact_endpoint_functional_a.wl"|>}|>|>,
    <|"SignModuloPrime" -> 100,
      "ExactEndpointFunctional" -> <|
        "Operation" -> "RegularizedEndpointFunctional",
        "MathematicalDefinition" ->
          "Take the rho^0 coefficient of the homogeneous endpoint action.",
        "SourceReferences" -> {<|
          "RelativePath" ->
            "Tests/Fixtures/exact_endpoint_functional_b.wl"|>}|>|>}|>;

finiteFieldMap = <|
  "DataType" ->
    "FactorizedFiniteFieldBoundaryFunctionToMasterIntegralSolutionMap",
  "SchemaVersion" -> 2,
  "Status" ->
    "FactorizedFiniteFieldBoundaryFunctionToMasterIntegralSolutionMapValidated",
  "Family" -> family,
  "FamilyDifferentialSystemReference" -> familySystemReference,
  "MasterIntegralEpsilonOrderRequirementsReference" ->
    requirementsReference,
  "BoundaryDataType" -> "BoundaryFunction",
  "BoundaryDomain" -> boundaryDomain,
  "DimensionalRegulator" -> eps,
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{0, 44}, {0, 45}},
  "BoundaryFunctionEpsilonCoefficientRecords" -> coordinates,
  "BoundaryFunctionEpsilonCoefficientLabels" ->
    ({#["BoundaryFunctionID"], #["EpsilonOrder"]} & /@ coordinates),
  "CoefficientField" -> <|
    "Type" -> "RationalFunctionFieldModuloPrime", "Prime" -> prime,
    "CoefficientVariables" -> {t}|>,
  "FiniteFieldRegularizedActionReference" -> <|
    "RelativePath" ->
      "Tests/Fixtures/factorized_regularized_action_q101.wl",
    "DataType" -> "RegularizedBoundaryActionFiniteField",
    "SchemaVersion" -> 2, "Family" -> family, "Prime" -> prime|>,
  "FiniteFieldCoefficientDefinitions" ->
    {rationalDefinition, lazyDefinition},
  "IteratedIntegralCoefficientReferenceRecords" -> {
    <|"CurrentPathFirstSegmentLetterIndices" -> {11},
      "CurrentPathSecondSegmentLetterIndices" -> {},
      "BoundaryPathFirstSegmentLetterIndices" -> {},
      "BoundaryPathSecondSegmentLetterIndices" -> {7},
      "NonzeroCoefficientEntries" -> {
        <|"RequestedMasterIntegralEpsilonOrderAndRowPairIndex" -> 1,
          "BoundaryFunctionEpsilonCoefficientIndex" -> 1,
          "CoefficientDefinitionID" -> "q-rational"|>,
        <|"RequestedMasterIntegralEpsilonOrderAndRowPairIndex" -> 2,
          "BoundaryFunctionEpsilonCoefficientIndex" -> 2,
          "CoefficientDefinitionID" -> "q-lazy-endpoint"|>}|>,
    <|"CurrentPathFirstSegmentLetterIndices" -> {12},
      "CurrentPathSecondSegmentLetterIndices" -> {},
      "BoundaryPathFirstSegmentLetterIndices" -> {},
      "BoundaryPathSecondSegmentLetterIndices" -> {8},
      "NonzeroCoefficientEntries" -> {
        <|"RequestedMasterIntegralEpsilonOrderAndRowPairIndex" -> 1,
          "BoundaryFunctionEpsilonCoefficientIndex" -> 2,
          "CoefficientDefinitionID" -> "q-rational"|>}|>},
  "FiniteFieldDemandCoverage" -> "Complete",
  "CharacteristicZeroDemandCoverage" -> "NotEstablished",
  "FormalResultConvention" -> <|
    "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst"|>,
  "Validation" -> <|"Method" -> "ExactFiniteFieldToyConstruction",
    "Conditions" -> <|"CoefficientReferenceClosure" -> True,
      "DeclaredSupportIsNonzero" -> True,
      "FiniteFieldDemandCoverage" -> True|>|>|>;

composition =
  ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution[
  finiteFieldMap, evolution];
product = composition[
  "OrderedCoefficientOperatorFactors"];
worklist = composition[
  "BoundaryConstantEpsilonCoefficientEvaluationWorklist"];

FTAssert["the result is explicitly a non-characteristic-zero V2 composition",
  composition["DataType"] ===
      "FactorizedFiniteFieldBoundarySolutionComposition" &&
    composition["SchemaVersion"] === 2 &&
    composition["Status"] ===
      "FactorizedFiniteFieldBoundarySolutionCompositionConstructed" &&
    composition["FiniteFieldDemandCoverage"] === "Complete" &&
    composition["CharacteristicZeroDemandCoverage"] ===
      "NotEstablished" &&
    composition["CharacteristicZeroLiftStatus"] ===
      "NotEstablished" &&
    composition["CrossFactorCoefficientMultiplicationStatus"] ===
      "DeferredUntilCharacteristicZeroLift" &&
    ! MasterIntegralSolutionQ[composition]];

FTAssert["the two sparse factors are retained without Cartesian expansion",
  product["LeftFactor"] === finiteFieldMap &&
    product["RightFactor", "TangentialBoundaryEvolutionOperator"] ===
      evolution &&
    Length[product["LeftFactor",
        "IteratedIntegralCoefficientReferenceRecords"]] === 2 &&
    Length[product["RightFactor",
        "EpsilonLiftedIteratedIntegralCoefficientMatrixRecords"]] === 2 &&
    ! KeyExistsQ[composition, "IteratedIntegralCoefficientMatrixTerms"]];

FTAssert["support reachability reports both definitions and the lazy subset",
  Sort[worklist["RequiredFiniteFieldCoefficientDefinitionIDs"]] ===
      {"q-lazy-endpoint", "q-rational"} &&
    worklist[
      "RequiredLazyEndpointFunctionalCoefficientDefinitionIDs"] ===
      {"q-lazy-endpoint"} &&
    Length[worklist[
        "RequiredPathSegmentLetterIndexSequenceRecords"]] === 2 &&
    Length[worklist[
        "RequiredTangentialIteratedIntegralLetterSequences"]] === 2 &&
    Sort[composition["BoundaryConstantEpsilonCoefficientLabels"]] ===
      Sort[{{baseConstantIDs[[1]], 0}, {baseConstantIDs[[2]], 0}}]];

FTAssert["the structural predicate rederives the factorized image",
  FactorizedFiniteFieldBoundarySolutionCompositionQ[
      composition] &&
    ! FactorizedFiniteFieldBoundarySolutionCompositionQ[
      ReplacePart[composition,
        "CharacteristicZeroLiftStatus" -> "Complete"]]];

malformed = ReplacePart[finiteFieldMap,
  {"FiniteFieldCoefficientDefinitions", 2, "OrderedComponents", 1,
      "ExactEndpointFunctional", "SourceReferences"} ->
    {<|"RelativePath" -> "/tmp/not-portable.wl"|>}];
refusal =
  ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution[
  malformed, evolution];

FTAssert["a lazy endpoint functional without portable source data is refused",
  FailureQ[refusal] && refusal["Status"] ===
    "FactorizedFiniteFieldBoundaryFunctionSolutionMapRequired"];

FTReport[];
