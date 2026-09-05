(* Exact symbolic validation and probabilistic finite-field validation are
   distinct for the same rational family dlog epsilon form. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];

Clear[v, w, u, eps, master];
transformation = {{v, 0}, {0, 1}};
inverse = {{1/v, 0}, {0, 1}};
epsilonForm = {
  {{eps/v, 0}, {0, 0}},
  {{0, 0}, {0, -eps/(1 - w)}}
};
system = <|
  "Family" -> "SyntheticValidation",
  "Av" -> {{(1 + eps)/v, 0}, {0, 0}},
  "Aw" -> {{0, 0}, {0, -eps/(1 - w)}}
|>;
candidate = <|
  "Family" -> "SyntheticValidation",
  "Variables" -> {v, w},
  "Regulator" -> eps,
  "Ranges" -> {{1}, {2}},
  "Blocks" -> {{1}, {2}},
  "TTotal" -> transformation,
  "TTotalInverse" -> inverse,
  "EpsFormX" -> epsilonForm[[1]],
  "EpsFormY" -> epsilonForm[[2]]
|>;
v2System = <|
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> "SyntheticValidation", "KinematicVariables" -> {v, w},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" -> {master[1], master[2]},
  "ConnectionMatrices" -> {system["Av"], system["Aw"]}|>;
systemReference = <|
  "RelativePath" -> "synthetic_validation_system.wl",
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> "SyntheticValidation"|>;

exact = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  candidate, v2System, systemReference, "IdentityMethod" -> "Symbolic"];
finiteField = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  candidate, v2System, systemReference, "IdentityMethod" -> "Modular",
  "ModularPoints" -> 3, "ModularPrimes" -> 2];
broken = FeynFacet`ValidateFamilyDLogEpsilonForm[
  ReplacePart[candidate, {"EpsFormX", 1, 1} -> 2 eps/v], system,
  "SourceVariables" -> {v, w}, "IdentityMethod" -> "Symbolic"];
threeVariableSource = FeynFacet`ValidateFamilyDLogEpsilonForm[
  candidate, system, "SourceVariables" -> {v, w, u}];
unsupportedMethod = FeynFacet`ValidateFamilyDLogEpsilonForm[
  candidate, system, "SourceVariables" -> {v, w},
  "IdentityMethod" -> "Unknown"];
transportInput = exact;
transportDemand = <|
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{0, 1}},
  "MinimumRetainedMasterIntegralEpsilonOrder" -> 0,
  "RegularBasePointAndFirstPathParameterScale" -> <|
    "FirstVariable" -> v, "SecondVariable" -> w,
    "FirstBase" -> 1/2, "SecondBase" -> 1/2,
    "FirstPathParameterScale" -> -1/6|>|>;
transportFromV2Blocks =
  FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  transportInput, transportDemand,
  "BoundaryConstraintSubspaceRepresentation" ->
    "AmbientSpaceWithBasePointConstraints",
  "IteratedIntegralCoefficientRepresentation" ->
    "IteratedIntegralCoefficientOperatorForRequestedOutputs"];
transportFromTopLevelBlocks =
  FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  Join[KeyDrop[transportInput, "BlockDecomposition"],
    <|"IrreducibleDiagonalBlocks" -> {{1}, {2}}|>], transportDemand,
  "BoundaryConstraintSubspaceRepresentation" ->
    "AmbientSpaceWithBasePointConstraints",
  "IteratedIntegralCoefficientRepresentation" ->
    "IteratedIntegralCoefficientOperatorForRequestedOutputs"];

tests = <|
  "ExactStatus" -> exact["Status"] ===
    "FamilyDLogEpsilonFormValidated",
  "ExactPredicate" ->
    FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[exact],
  "GeneralPredicateIncludesExact" ->
    FeynFacet`ValidatedFamilyDLogEpsilonFormQ[exact],
  "FiniteFieldStatus" -> finiteField["Status"] ===
    "FamilyDLogEpsilonFormValidated",
  "FiniteFieldIsValidated" ->
    FeynFacet`ValidatedFamilyDLogEpsilonFormQ[finiteField],
  "FiniteFieldIsNotExact" ->
    ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[finiteField] &&
      TrueQ[finiteField["Validation", "Probabilistic"]] &&
      ! TrueQ[finiteField["Validation", "Exact"]] &&
      finiteField["Validation", "Method"] ===
        "ProbabilisticFiniteFieldSampling",
  "ConnectionTransformationEquation" ->
    TrueQ[exact["Validation", "Conditions",
      "ConnectionTransformationEquation"]],
  "SourceRepresentation" ->
    exact["CoefficientPresentation", "DataType"] ===
      "SourceVariableRepresentation",
  "CoefficientOperatorConsumesNestedBlockDecomposition" ->
    FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      transportFromV2Blocks],
  "CoefficientOperatorRefusesTopLevelBlockAlias" ->
    ! FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      transportFromTopLevelBlocks],
  "BrokenTransformationRejected" ->
    broken["Status"] === "FamilyDLogEpsilonFormValidationFailed" &&
      ! TrueQ[broken["Validation", "Conditions",
        "ConnectionTransformationEquation"]],
  "ThreeVariablesRejected" ->
    threeVariableSource["Status"] === "SourceVariablesInvalid" &&
      threeVariableSource["Actual"] === 3,
  "UnsupportedMethodRejected" ->
    unsupportedMethod["Status"] === "IdentityMethodUnsupported"
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
