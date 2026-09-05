root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

Clear[x, y, eps, master];
conditions = <|"BasisTransformationInverse" -> True,
  "ConnectionTransformationEquation" -> True,
  "EpsilonFactorized" -> True, "DLogRepresentation" -> True|>;
blockDecomposition = <|
  "DataType" -> "FamilyDifferentialSystemBlockDecomposition",
  "SchemaVersion" -> 2,
  "FamilyDifferentialSystemReference" -> <|
    "RelativePath" -> "synthetic_family_system.wl",
    "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
    "Family" -> "Synthetic"|>,
  "IrreducibleDiagonalBlocks" -> {{1}}|>;
exact = <|"DataType" -> "FamilyDLogEpsilonForm", "SchemaVersion" -> 2,
  "Status" -> "FamilyDLogEpsilonFormValidated",
  "Family" -> "Synthetic",
  "CoefficientPresentation" -> <|
    "DataType" -> "SourceVariableRepresentation", "SchemaVersion" -> 2,
    "SourceVariables" -> {x, y}, "CoefficientVariables" -> {x, y},
    "SourceVariableSubstitution" -> {x -> x, y -> y},
    "DifferentialPullbackMatrix" -> IdentityMatrix[2]|>,
  "CoefficientVariables" -> {x, y}, "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" -> {master[1]},
  "BlockDecomposition" -> blockDecomposition,
  "BasisTransformationMatrix" -> {{1}}, "Letters" -> {},
  "ConstantResidueMatrices" -> {},
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
  "Status" -> "FamilyDLogEpsilonFormValidated",
  "Validation" -> <|"Exact" -> False, "Probabilistic" -> True,
    "Method" -> "ProbabilisticFiniteFieldSampling",
    "Conditions" -> conditions,
    "SamplingEvidence" -> <|
      "Status" -> "FiniteFieldValidationPassed",
      "Probabilistic" -> True|>|>|>];
failedCondition = ReplacePart[exact,
  {"Validation", "Conditions", "ConnectionTransformationEquation"} ->
    False];
wrongMethod = ReplacePart[probabilistic,
  {"Validation", "Method"} -> "CharacteristicZeroSymbolicIdentity"];
legacyFiniteFieldMethod = ReplacePart[probabilistic,
  {"Validation", "Method"} -> "FiniteFieldEvaluation"];
legacyStatus = ReplacePart[exact,
  "Status" -> "ExactlyValidatedFamilyDLogEpsilonForm"];
v2BlockRecord = exact;
legacyBlockRecord = Join[KeyDrop[exact, "BlockDecomposition"],
  <|"IrreducibleDiagonalBlocks" -> {{1}}|>];
incompletePublicRecord = KeyDrop[exact, "OriginalMasterIntegralBasis"];

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
    ! FeynFacet`ValidatedFamilyDLogEpsilonFormQ[wrongMethod],
  "LegacyFiniteFieldMethodRejected" ->
    ! FeynFacet`ValidatedFamilyDLogEpsilonFormQ[
      legacyFiniteFieldMethod],
  "LegacyStrengthStatusRejected" ->
    ! FeynFacet`ValidatedFamilyDLogEpsilonFormQ[legacyStatus],
  "IncompletePublicRecordRejected" ->
    ! FeynFacet`ValidatedFamilyDLogEpsilonFormQ[incompletePublicRecord],
  "ObservableConsumerUsesNestedBlockDecomposition" ->
    FeynFacet`Private`observableTransportIrreducibleDiagonalBlocks[
      v2BlockRecord] === {{1}},
  "ObservableConsumerHasNoTopLevelBlockFallback" ->
    MissingQ[FeynFacet`Private`observableTransportIrreducibleDiagonalBlocks[
      legacyBlockRecord]]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
