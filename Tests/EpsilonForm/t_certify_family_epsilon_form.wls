(* Exact symbolic validation and probabilistic finite-field validation are
   distinct for the same rational family dlog epsilon form. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

Clear[v, w, u, eps];
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

exact = FeynFacet`ValidateFamilyDLogEpsilonForm[candidate, system,
  "SourceVariables" -> {v, w}, "IdentityMethod" -> "Symbolic"];
finiteField = FeynFacet`ValidateFamilyDLogEpsilonForm[candidate, system,
  "SourceVariables" -> {v, w}, "IdentityMethod" -> "Modular",
  "ModularPoints" -> 3, "ModularPrimes" -> 2];
broken = FeynFacet`ValidateFamilyDLogEpsilonForm[
  ReplacePart[candidate, {"EpsFormX", 1, 1} -> 2 eps/v], system,
  "SourceVariables" -> {v, w}, "IdentityMethod" -> "Symbolic"];
threeVariableSource = FeynFacet`ValidateFamilyDLogEpsilonForm[
  candidate, system, "SourceVariables" -> {v, w, u}];
unsupportedMethod = FeynFacet`ValidateFamilyDLogEpsilonForm[
  candidate, system, "SourceVariables" -> {v, w},
  "IdentityMethod" -> "Unknown"];

tests = <|
  "ExactStatus" -> exact["Status"] ===
    "ExactlyValidatedFamilyDLogEpsilonForm",
  "ExactPredicate" ->
    FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[exact],
  "GeneralPredicateIncludesExact" ->
    FeynFacet`ValidatedFamilyDLogEpsilonFormQ[exact],
  "FiniteFieldStatus" -> finiteField["Status"] ===
    "ProbabilisticallyValidatedFamilyDLogEpsilonForm",
  "FiniteFieldIsValidated" ->
    FeynFacet`ValidatedFamilyDLogEpsilonFormQ[finiteField],
  "FiniteFieldIsNotExact" ->
    ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[finiteField] &&
      TrueQ[finiteField["Validation", "Probabilistic"]] &&
      ! TrueQ[finiteField["Validation", "Exact"]],
  "ConnectionTransformationEquation" ->
    TrueQ[exact["Validation", "Conditions",
      "ConnectionTransformationEquation"]],
  "SourceRepresentation" ->
    exact["CoefficientPresentation", "DataType"] ===
      "SourceVariableRepresentation",
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
