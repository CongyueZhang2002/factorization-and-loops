#!/usr/bin/env wolframscript

(* Self-contained V2 coverage for requested row/order mapping and the lazy
   requested-output iterated-integral coefficient operator. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];

Clear[x, y, eps, master];
family = "RequestedOutputCoefficientOperatorToy";
connection = {
  {{eps/x, 0}, {0, 0}},
  {{0, 0}, {0, eps/y}}
};
familySystem = <|
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> family,
  "KinematicVariables" -> {x, y},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" ->
    {master[family, {1}], master[family, {2}]},
  "ConnectionMatrices" -> connection|>;
candidate = <|
  "Family" -> family,
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Blocks" -> {{2}, {1}},
  "Ranges" -> {{1}, {2}},
  "TTotal" -> IdentityMatrix[2],
  "TTotalInverse" -> IdentityMatrix[2],
  "EpsFormX" -> connection[[1, {2, 1}, {2, 1}]],
  "EpsFormY" -> connection[[2, {2, 1}, {2, 1}]]|>;
systemReference = <|
  "RelativePath" -> "requested_output_coefficient_operator_toy.wl",
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> family|>;
familyDLogEpsilonForm =
  FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
    candidate, familySystem, systemReference,
    "IdentityMethod" -> "Symbolic"];

path = <|
  "FirstVariable" -> x,
  "SecondVariable" -> y,
  "FirstBase" -> 1/2,
  "SecondBase" -> 1/2,
  "FirstPathParameterScale" -> -1/6|>;
hardFunctionRequest = <|
  "DataType" -> "HardFunctionEpsilonOrderRequest", "SchemaVersion" -> 2,
  "Status" -> "HardFunctionEpsilonOrdersRequested",
  "RequestedHardFunctionEpsilonOrders" -> {0, 1},
  "Reference" -> <|
    "RelativePath" -> "requested_output_hard_function_orders.wl",
    "DataType" -> "HardFunctionEpsilonOrderRequest",
    "SchemaVersion" -> 2|>|>;
coefficientValuations = <|
  "DataType" -> "HardFunctionMasterCoefficientEpsilonValuations",
  "SchemaVersion" -> 2,
  "Status" ->
    "HardFunctionMasterCoefficientEpsilonValuationsDetermined",
  "Reference" -> <|
    "RelativePath" -> "requested_output_coefficient_valuations.wl",
    "DataType" -> "HardFunctionMasterCoefficientEpsilonValuations",
    "SchemaVersion" -> 2|>,
  "Entries" -> {
    <|"MasterIntegralIndex" -> 101,
      "MasterIntegral" -> <|
        "Family" -> family, "PropagatorPowers" -> {1}|>,
      "HardFunctionCoefficientEpsilonValuation" -> 0,
      "DeterminationMethod" -> "ExactToyInput"|>,
    <|"MasterIntegralIndex" -> 202,
      "MasterIntegral" -> <|
        "Family" -> family, "PropagatorPowers" -> {2}|>,
      "HardFunctionCoefficientEpsilonValuation" -> -2,
      "DeterminationMethod" -> "ExactToyInput"|>}|>;
requirements = DeriveMasterIntegralEpsilonOrderRequirements[
  hardFunctionRequest, coefficientValuations];
requirementsReference = <|
  "RelativePath" -> "Tests/Fixtures/requested_output_requirements.wl",
  "DataType" -> "MasterIntegralEpsilonOrderRequirements",
  "SchemaVersion" -> 2,
  "MathematicalInputReferences" ->
    requirements["MathematicalInputReferences"]|>;
legacyMappedDemand =
  FeynFacet`Private`mapMasterIntegralCoefficientValuationsToRequestedRows[
    familyDLogEpsilonForm, familySystem, {
      <|"Family" -> family, "Indices" -> {1}, "Valuation" -> 0|>,
      <|"Family" -> family, "Indices" -> {2}, "Valuation" -> -2|>},
    "RequestedHardFunctionEpsilonOrders" -> {0, 1},
    "AdditionalRetainedEpsilonOrders" -> 0,
    "MinimumRetainedMasterIntegralEpsilonOrder" -> 0,
    "RegularBasePointAndFirstPathParameterScale" -> path];
operator =
  FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    familyDLogEpsilonForm, requirements,
    "RegularBasePointAndFirstPathParameterScale" -> path,
    "MasterIntegralEpsilonOrderRequirementsReference" ->
      requirementsReference,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints"];
zeroSequenceCoefficient =
  FeynFacet`ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
    operator, {}, {}];
legacyCartesianDemand =
  FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    familyDLogEpsilonForm, <|
      "PhysicalRows" -> {1, 2},
      "PhysicalOrders" -> {0, 1},
      "PhysicalValuation" -> 0,
      "Path" -> path|>];

tests = <|
  "FamilyDLogEpsilonFormValidated" ->
    FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[
      familyDLogEpsilonForm],
  "RequestedRowsMapped" ->
    MasterIntegralEpsilonOrderRequirementsQ[requirements] &&
      operator["RequestedMasterIntegralEpsilonOrderAndRowPairs"] ===
        {{0, 1}, {1, 1}, {2, 2}, {3, 2}},
  "NontrivialBasisPermutationUsesOriginalPhysicalRows" ->
    familyDLogEpsilonForm["BlockDecomposition",
        "IrreducibleDiagonalBlocks"] === {{2}, {1}} &&
      familyDLogEpsilonForm["BasisTransformationMatrix"] ===
        {{0, 1}, {1, 0}} &&
      Lookup[operator["MasterIntegralEpsilonOrderRequirementRowMapping"],
        "OriginalPhysicalRow"] === {1, 2},
  "LiveLegacyCampaignBridgeAlsoUsesOriginalPhysicalRows" ->
    Lookup[legacyMappedDemand["MasterIntegralRowRequirements"],
      "OriginalPhysicalRow"] === {1, 2},
  "V2OperatorValidated" ->
    operator["Status"] ===
        "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
      FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
        operator] &&
      operator["FamilyDifferentialSystemReference"] === systemReference &&
      operator["MasterIntegralEpsilonOrderRequirementsReference"] ===
        requirementsReference,
  "ExplicitLetterIndexSequenceAccessor" ->
    zeroSequenceCoefficient["Status"] ===
        "IteratedIntegralCoefficientMatrixComputed" &&
      zeroSequenceCoefficient["FirstPathSegmentLetterIndices"] === {} &&
      zeroSequenceCoefficient["SecondPathSegmentLetterIndices"] === {},
  "CartesianDemandCompatibilityRemoved" ->
    legacyCartesianDemand["Status"] ===
      "RequestedMasterIntegralEpsilonOrderAndRowPairsNotWellFormed",
  "InvalidTypedRequirementsAreRefused" ->
    FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
      familyDLogEpsilonForm,
      ReplacePart[requirements,
        {"Validation", "Passed"} -> False],
      "MasterIntegralEpsilonOrderRequirementsReference" ->
        requirementsReference,
      "RegularBasePointAndFirstPathParameterScale" -> path]["Status"] ===
        "MasterIntegralEpsilonOrderRequirementsInvalid",
  "TypedMasterDescriptorMustResolveInOriginalBasis" ->
    FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
      familyDLogEpsilonForm,
      ReplacePart[requirements,
        {"MathematicalInputData",
          "HardFunctionMasterCoefficientEpsilonValuations", "Entries", 1,
          "MasterIntegral", "PropagatorPowers"} -> {99}],
      "MasterIntegralEpsilonOrderRequirementsReference" ->
        requirementsReference,
      "RegularBasePointAndFirstPathParameterScale" -> path]["Status"] ===
        "MasterIntegralRequirementRowMappingFailed",
  "TypedRequirementsArtifactReferenceIsRequired" ->
    FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
      familyDLogEpsilonForm, requirements,
      "RegularBasePointAndFirstPathParameterScale" -> path]["Status"] ===
        "MasterIntegralEpsilonOrderRequirementsReferenceInvalid",
  "TypedRequirementsArtifactReferenceInputsMustMatch" ->
    FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
      familyDLogEpsilonForm, requirements,
      "MasterIntegralEpsilonOrderRequirementsReference" ->
        ReplacePart[requirementsReference,
          "MathematicalInputReferences" -> <||>],
      "RegularBasePointAndFirstPathParameterScale" -> path]["Status"] ===
        "MasterIntegralEpsilonOrderRequirementsReferenceInvalid",
  "StoredRequirementRowMappingIsValidated" ->
    ! FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      ReplacePart[operator,
        {"MasterIntegralEpsilonOrderRequirementRowMapping", 1,
          "OriginalPhysicalRow"} -> 2]],
  "OldPublicSchemaAbsent" ->
    Intersection[Keys[operator],
      {"PhysicalRows", "PhysicalOrders", "PhysicalDemandPairs",
       "PhysicalValuation", "WordRepresentation",
       "ExactOperatorAutomaton", "CompactTransportAutomaton"}] === {}
|>;

Print[InputForm[tests]];
If[And @@ Values[tests], Exit[0], Exit[1]];
