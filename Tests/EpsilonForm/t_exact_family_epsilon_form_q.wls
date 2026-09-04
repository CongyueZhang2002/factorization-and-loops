root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

conditions = <|"BasisTransformationInverse" -> True,
  "ConnectionTransformationEquation" -> True,
  "EpsilonFactorized" -> True, "DLogRepresentation" -> True|>;
exact = <|"DataType" -> "FamilyDLogEpsilonForm", "SchemaVersion" -> 2,
  "Status" -> "ExactlyValidatedFamilyDLogEpsilonForm",
  "Validation" -> <|"Exact" -> True,
    "Probabilistic" -> False,
    "Method" -> "CharacteristicZeroSymbolicIdentity",
    "Conditions" -> conditions,
    "CharacteristicZeroResiduals" -> <|
      "BasisTransformationInverse" -> {{{0}}},
      "ConnectionTransformation" -> {{{0}}},
      "SourceConnectionFlatness" -> {{0}},
      "TransformedConnectionFlatness" -> {{0}},
      "DLogReconstruction" -> {{{0}}}|>|>|>;
probabilistic = Join[KeyDrop[exact, "Validation"], <|
  "Status" -> "ProbabilisticallyValidatedFamilyDLogEpsilonForm",
  "Validation" -> <|"Exact" -> False, "Probabilistic" -> True,
    "Method" -> "FiniteFieldEvaluation", "Conditions" -> conditions,
    "SamplingEvidence" -> <|
      "Status" -> "FiniteFieldValidationPassed",
      "Probabilistic" -> True|>|>|>];
failedCondition = ReplacePart[exact,
  {"Validation", "Conditions", "ConnectionTransformationEquation"} ->
    False];
wrongMethod = ReplacePart[probabilistic,
  {"Validation", "Method"} -> "CharacteristicZeroSymbolicIdentity"];

tests = <|
  "ExactlyValidated" ->
    FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[exact],
  "ExactIncludedByGeneralPredicate" ->
    FeynFacet`ValidatedFamilyDLogEpsilonFormQ[exact],
  "ProbabilisticValidatedButNotExact" ->
    FeynFacet`ValidatedFamilyDLogEpsilonFormQ[probabilistic] &&
      ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[probabilistic],
  "FalseConditionRejected" ->
    ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[failedCondition],
  "InconsistentMethodRejected" ->
    ! FeynFacet`ValidatedFamilyDLogEpsilonFormQ[wrongMethod]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
