(* Family-level record normalization and context-safe artifact I/O on a
   self-contained mathematical fixture. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

scratch = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "t_family_epsform_" <> ToString[$ProcessID]}]];
sample = <|"A" -> {1/2, Symbol["Global`eps"]}, "B" -> "text"|>;
written = FeynFacet`FamilyArtifactWrite[sample,
  FileNameJoin[{scratch, "sample.wl"}]];
roundTrip = FeynFacet`FamilyArtifactRead[written] === sample;
missingRead = FeynFacet`FamilyArtifactRead[
  FileNameJoin[{scratch, "absent.wl"}]] === $Failed;

Clear[x, y, eps];
connection = {{{eps/x, 0}, {0, 0}}, {{0, 0}, {0, eps/y}}};
system = <|"Av" -> connection[[1]], "Aw" -> connection[[2]]|>;
candidate = <|
  "Family" -> "SyntheticFamilyRecord",
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Blocks" -> {{1}, {2}}, "Ranges" -> {{1}, {2}},
  "TTotal" -> IdentityMatrix[2],
  "TTotalInverse" -> IdentityMatrix[2],
  "EpsFormX" -> connection[[1]], "EpsFormY" -> connection[[2]]|>;
annotated = Join[candidate, <|"Blocks" -> {{{1}, 91}, {{2}, 92}}|>];

normalized = FeynFacet`FamilyEpsilonFormRecord[annotated];
validated = FeynFacet`ValidateFamilyDLogEpsilonForm[
  annotated, system, "SourceVariables" -> {x, y},
  "IdentityMethod" -> "Symbolic"];
typedFailure = FeynFacet`FamilyEpsilonFormRecord[
  <|"TTotal" -> {{1}}|>]["Status"] === "RecordKeysMissing";
badPermutation = FeynFacet`FamilyEpsilonFormRecord[
  Join[candidate, <|"Blocks" -> {{1}, {1}}|>]]["Status"] ===
    "BlockBasisPermutationInvalid";

tests = <|
  "ArtifactRoundTrip" -> roundTrip,
  "MissingFileFails" -> missingRead,
  "NormalizerPlainBlocks" ->
    normalized["Blocks"] === {{1}, {2}},
  "AnnotatedBlocksValidated" ->
    validated["DataType"] ===
        "FamilyDLogEpsilonFormValidationResult" &&
      validated["Status"] ===
        "FamilyDLogEpsilonFormValidationPassed" &&
      TrueQ[validated["Validation", "Exact"]] &&
      ! TrueQ[validated["Validation", "Probabilistic"]] &&
      validated["IrreducibleDiagonalBlocks"] === {{1}, {2}},
  "ValidationResultIsNotAPersistedFamilyRecord" ->
    ! FeynFacet`ValidatedFamilyDLogEpsilonFormQ[validated],
  "TypedMissingKeys" -> typedFailure,
  "TypedBadPermutation" -> badPermutation
|>;

DeleteDirectory[scratch, DeleteContents -> True];
Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
