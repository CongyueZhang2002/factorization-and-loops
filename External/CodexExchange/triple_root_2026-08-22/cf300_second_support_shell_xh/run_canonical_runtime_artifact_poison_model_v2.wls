#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300CanonicalRuntimeArtifactPoisonModelV2`"];
Begin["`Private`"];
Quiet[ClearAll[
  "CodexCF300CanonicalRuntimeArtifactPoisonModelV2`Private`*"]];
modelBootstrapExit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["CF300_CANONICAL_RUNTIME_MODEL FAIL usage=<project-root> " <>
    "<preparation.wl> <compiled-cache.wl>"];
  modelBootstrapExit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
modelDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[modelDirectory];
directDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];
canonicalRuntimeFile = FileNameJoin[{modelDirectory,
  "CanonicalGlobalArtifactRuntimeV2.wl"}];
expectedCanonicalRuntimeHash =
  "97ef42797ecd6b606fc9b702aade54b9c524e0853c948986dd52eed127068706";
expectedPreparationHash =
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedExactFingerprint =
  "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d";
expectedCompiledFingerprint =
  "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7";

files = <|
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}],
  "Assembler" -> FileNameJoin[{directDirectory,
    "DirectRootChannelAssembler.wl"}],
  "ArtifactHelper" -> FileNameJoin[{directDirectory,
    "DirectRootChannelCompiledArtifact.wl"}]|>;
expectedHashes = <|
  "TripleRootAlgebra" ->
    "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
  "TripleRootStripAdapter" ->
    "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
  "TripleRootAffinePilot" ->
    "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
  "TripleRootReconstructionPrototype" ->
    "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
  "Assembler" ->
    "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
  "ArtifactHelper" ->
    "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557"|>;

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
artifactRead[file_String] := Block[
  {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
  Quiet[Check[Get[file], $Failed]]];
loadSource[file_String] := Quiet[Check[Get[file], $Failed]];
stateComparison[current_Association, expected_Association] :=
  AssociationMap[SameQ[current[#1], expected[#1]] &,
    Keys[expected]];
stateComparison[___] := <|"Invalid" -> False|>;
comparisonPassedQ[comparison_Association] :=
  TrueQ[And @@ Values[comparison]];
comparisonPassedQ[___] := False;
validationBooleanKeys = {"SourceHashesStableQ", "LoadsSucceededQ",
  "PreparationStatusQ", "PreparationABIValidQ", "VariablesCanonicalQ",
  "RegulatorCanonicalQ", "RawCacheStatusQ", "RawCacheValidatorQ",
  "RawAssemblyValidatorQ", "ReaderCacheStatusQ",
  "ReaderCacheValidatorQ", "ReaderAssemblyValidatorQ",
  "RawReaderSameQ", "ExactFingerprintQ", "CompiledFingerprintQ"};
validationPassedQ[validation_Association] := TrueQ[
  And @@ Lookup[validation, validationBooleanKeys, False]];
validationPassedQ[___] := False;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[preparationFile] ||
    ! FileExistsQ[cacheFile] || ! FileExistsQ[canonicalRuntimeFile] ||
    ! AllTrue[Values[files], FileExistsQ],
  Print["CF300_CANONICAL_RUNTIME_MODEL FAIL invalid inputs"];
  modelBootstrapExit[65]];
If[hashes[] =!= expectedHashes ||
    FileHash[canonicalRuntimeFile, "SHA256", "HexString"] =!=
      expectedCanonicalRuntimeHash ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash,
  Print["CF300_CANONICAL_RUNTIME_MODEL FAIL pin mismatch"];
  modelBootstrapExit[66]];
canonicalRuntimeLoad = Quiet[Check[Get[canonicalRuntimeFile], $Failed]];
If[canonicalRuntimeLoad === $Failed ||
    DownValues[CodexCanonicalGlobalArtifactRuntimeV2`CGARRun] === {},
  Print["CF300_CANONICAL_RUNTIME_MODEL FAIL runtime load"];
  modelBootstrapExit[67]];

performArtifactValidation[] := Module[
  {sourceHashesBefore, loadOutcomes, preparationArtifact,
   preparation, variables, regulator, rawCache, readerCache,
   rawAssembly, readerAssembly, exactForms, compiledForms,
   exactFingerprint, compiledFingerprint},
  sourceHashesBefore = hashes[];
  loadOutcomes = AssociationMap[loadSource[files[#1]] &, Keys[files]];
  preparationArtifact = artifactRead[preparationFile];
  rawCache = artifactRead[cacheFile];
  readerCache =
    CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
      cacheFile];
  preparation = If[AssociationQ[preparationArtifact],
    Lookup[preparationArtifact, "Preparation", $Failed], $Failed];
  variables = If[AssociationQ[preparation],
    Lookup[preparation, "Variables", $Failed], $Failed];
  regulator = If[AssociationQ[preparation],
    Lookup[preparation, "Regulator", $Failed], $Failed];
  rawAssembly = If[AssociationQ[rawCache],
    Lookup[rawCache, "DirectAssembly", $Failed], $Failed];
  readerAssembly = If[AssociationQ[readerCache],
    Lookup[readerCache, "DirectAssembly", $Failed], $Failed];
  exactForms = If[AssociationQ[rawAssembly],
    Lookup[rawAssembly, "ExactChannelForms", $Failed], $Failed];
  compiledForms = If[AssociationQ[rawAssembly],
    Lookup[rawAssembly, "CompiledForms", $Failed], $Failed];
  exactFingerprint = If[exactForms === $Failed, $Failed,
    fingerprint[exactForms]];
  compiledFingerprint = If[compiledForms === $Failed, $Failed,
    fingerprint[compiledForms]];
  <|
    "SourceHashesStableQ" ->
      SameQ[sourceHashesBefore, expectedHashes, hashes[]],
    "LoadsSucceededQ" -> FreeQ[Values[loadOutcomes], $Failed],
    "PreparationStatusQ" -> TrueQ[
      AssociationQ[preparationArtifact] &&
      Lookup[preparationArtifact, "Status", None] ===
        "PreparedCF300Sector12Rank2Extension"],
    "PreparationABIValidQ" -> TrueQ[
      AssociationQ[preparation] &&
      CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation]],
    "VariablesCanonicalQ" -> SameQ[variables, {Global`x, Global`y}],
    "RegulatorCanonicalQ" -> SameQ[regulator, Global`eps],
    "RawCacheStatusQ" -> TrueQ[AssociationQ[rawCache] &&
      Lookup[rawCache, "Status", None] ===
        "DirectRootChannelCompiledArtifactV1"],
    "RawCacheValidatorQ" -> TrueQ[AssociationQ[rawCache] &&
      CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
        rawCache]],
    "RawAssemblyValidatorQ" -> TrueQ[AssociationQ[rawAssembly] &&
      CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        rawAssembly]],
    "ReaderCacheStatusQ" -> TrueQ[AssociationQ[readerCache] &&
      Lookup[readerCache, "Status", None] ===
        "DirectRootChannelCompiledArtifactV1"],
    "ReaderCacheValidatorQ" -> TrueQ[AssociationQ[readerCache] &&
      CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
        readerCache]],
    "ReaderAssemblyValidatorQ" -> TrueQ[
      AssociationQ[readerAssembly] &&
      CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        readerAssembly]],
    "RawReaderSameQ" -> SameQ[rawCache, readerCache],
    "ExactFingerprint" -> exactFingerprint,
    "ExactFingerprintQ" ->
      SameQ[exactFingerprint, expectedExactFingerprint,
        Lookup[rawAssembly, "ExactChannelFormsFingerprint", $Failed]],
    "CompiledFingerprint" -> compiledFingerprint,
    "CompiledFingerprintQ" ->
      SameQ[compiledFingerprint, expectedCompiledFingerprint,
        Lookup[rawAssembly, "CompiledFormsFingerprint", $Failed]]|>
];

originalDefinitions = <|
  "x" -> CodexCanonicalGlobalArtifactRuntimeV2`CGARDefinitionSnapshot["x"],
  "y" -> CodexCanonicalGlobalArtifactRuntimeV2`CGARDefinitionSnapshot["y"],
  "eps" ->
    CodexCanonicalGlobalArtifactRuntimeV2`CGARDefinitionSnapshot["eps"]|>;
poisonStates = <|
  "x" -> <|
    "OwnValues" -> {HoldPattern[Global`x] :> 31337},
    "DownValues" -> {
      HoldPattern[Global`x[poisonXArgument_]] :>
        poisonXArgument + 101},
    "UpValues" -> {}, "SubValues" -> {}, "NValues" -> {},
    "DefaultValues" -> {}, "FormatValues" -> {},
    "Attributes" -> {Locked, Protected}|>,
  "y" -> <|
    "OwnValues" -> {HoldPattern[Global`y] :> -27183},
    "DownValues" -> {
      HoldPattern[Global`y[poisonYArgument_]] :>
        3 poisonYArgument - 7},
    "UpValues" -> {}, "SubValues" -> {}, "NValues" -> {},
    "DefaultValues" -> {}, "FormatValues" -> {},
    "Attributes" -> {Listable, Locked, Protected}|>,
  "eps" -> <|
    "OwnValues" -> {HoldPattern[Global`eps] :> 65537},
    "DownValues" -> {
      HoldPattern[Global`eps[poisonEpsilonArgument_]] :>
        poisonEpsilonArgument^2 + 11},
    "UpValues" -> {}, "SubValues" -> {}, "NValues" -> {},
    "DefaultValues" -> {}, "FormatValues" -> {},
    "Attributes" -> {Locked, NumericFunction, Protected}|>|>;
poisonInstall = <|
  "x" -> CodexCanonicalGlobalArtifactRuntimeV2`CGARRestoreDefinitionState[
    "x", poisonStates["x"]],
  "y" -> CodexCanonicalGlobalArtifactRuntimeV2`CGARRestoreDefinitionState[
    "y", poisonStates["y"]],
  "eps" ->
    CodexCanonicalGlobalArtifactRuntimeV2`CGARRestoreDefinitionState[
      "eps", poisonStates["eps"]]|>;
poisonInstalledQ = TrueQ[And @@ Values[poisonInstall]];
poisonDefinitions = <|
  "x" -> CodexCanonicalGlobalArtifactRuntimeV2`CGARDefinitionSnapshot["x"],
  "y" -> CodexCanonicalGlobalArtifactRuntimeV2`CGARDefinitionSnapshot["y"],
  "eps" ->
    CodexCanonicalGlobalArtifactRuntimeV2`CGARDefinitionSnapshot["eps"]|>;

poisonCallerContext =
  "CodexCF300CanonicalRuntimePoisonCallerV2`";
poisonCallerContextPath = {"System`", poisonCallerContext,
  "CodexCF300CanonicalRuntimeArtifactPoisonModelV2`"};
Block[{$Context = poisonCallerContext,
    $ContextPath = poisonCallerContextPath},
  firstCallerContextBefore = $Context;
  firstCallerContextPathBefore = $ContextPath;
  firstOutcome =
    CodexCanonicalGlobalArtifactRuntimeV1`CGARRun[
      firstValidation = performArtifactValidation[];
      CodexCanonicalGlobalArtifactRuntimeV1`CGARRequestExit[0]];
  firstCallerContextRestoredQ =
    SameQ[$Context, firstCallerContextBefore];
  firstCallerContextPathRestoredQ =
    SameQ[$ContextPath, firstCallerContextPathBefore];
];
afterFirstDefinitions = <|
  "x" -> CodexCanonicalGlobalArtifactRuntimeV1`CGARDefinitionSnapshot[
    Global`x],
  "y" -> CodexCanonicalGlobalArtifactRuntimeV1`CGARDefinitionSnapshot[
    Global`y],
  "eps" -> CodexCanonicalGlobalArtifactRuntimeV1`CGARDefinitionSnapshot[
    Global`eps]|>;
firstDefinitionComparisons = AssociationMap[
  stateComparison[afterFirstDefinitions[#1], poisonDefinitions[#1]] &,
  Keys[poisonDefinitions]];

Block[{$Context = poisonCallerContext,
    $ContextPath = poisonCallerContextPath},
  secondCallerContextBefore = $Context;
  secondCallerContextPathBefore = $ContextPath;
  secondOutcome =
    CodexCanonicalGlobalArtifactRuntimeV1`CGARRun[
      secondValidation = performArtifactValidation[];
      CodexCanonicalGlobalArtifactRuntimeV1`CGARRequestExit[0]];
  secondCallerContextRestoredQ =
    SameQ[$Context, secondCallerContextBefore];
  secondCallerContextPathRestoredQ =
    SameQ[$ContextPath, secondCallerContextPathBefore];
];
afterSecondDefinitions = <|
  "x" -> CodexCanonicalGlobalArtifactRuntimeV1`CGARDefinitionSnapshot[
    Global`x],
  "y" -> CodexCanonicalGlobalArtifactRuntimeV1`CGARDefinitionSnapshot[
    Global`y],
  "eps" -> CodexCanonicalGlobalArtifactRuntimeV1`CGARDefinitionSnapshot[
    Global`eps]|>;
secondDefinitionComparisons = AssociationMap[
  stateComparison[afterSecondDefinitions[#1], poisonDefinitions[#1]] &,
  Keys[poisonDefinitions]];

originalRestoration = <|
  "x" -> CodexCanonicalGlobalArtifactRuntimeV1`CGARRestoreDefinitionState[
    Global`x, originalDefinitions["x"]],
  "y" -> CodexCanonicalGlobalArtifactRuntimeV1`CGARRestoreDefinitionState[
    Global`y, originalDefinitions["y"]],
  "eps" ->
    CodexCanonicalGlobalArtifactRuntimeV1`CGARRestoreDefinitionState[
      Global`eps, originalDefinitions["eps"]]|>;
originalDefinitionsRestoredQ = TrueQ[And @@ Values[originalRestoration]];

diagnostics = <|
  "Status" -> "CF300CanonicalRuntimeArtifactPoisonModelV1",
  "CanonicalRuntimeSHA256" -> expectedCanonicalRuntimeHash,
  "PoisonInstalledQ" -> poisonInstalledQ,
  "PoisonDefinitionTables" -> AssociationMap[Keys,
    poisonDefinitions],
  "PoisonAttributes" -> AssociationMap[
    poisonDefinitions[#1]["Attributes"] &, Keys[poisonDefinitions]],
  "FirstOutcome" -> firstOutcome,
  "FirstValidation" -> firstValidation,
  "FirstDefinitionComparisons" -> firstDefinitionComparisons,
  "FirstDefinitionsRestoredQ" ->
    AllTrue[Values[firstDefinitionComparisons], comparisonPassedQ],
  "FirstCallerContextRestoredQ" -> firstCallerContextRestoredQ,
  "FirstCallerContextPathRestoredQ" ->
    firstCallerContextPathRestoredQ,
  "SecondOutcome" -> secondOutcome,
  "SecondValidation" -> secondValidation,
  "SecondDefinitionComparisons" -> secondDefinitionComparisons,
  "SecondDefinitionsRestoredQ" ->
    AllTrue[Values[secondDefinitionComparisons], comparisonPassedQ],
  "SecondCallerContextRestoredQ" -> secondCallerContextRestoredQ,
  "SecondCallerContextPathRestoredQ" ->
    secondCallerContextPathRestoredQ,
  "RepeatedValidationSameQ" -> SameQ[firstValidation, secondValidation],
  "OriginalDefinitionRestoration" -> originalRestoration,
  "OriginalDefinitionsRestoredQ" -> originalDefinitionsRestoredQ|>;
passed = TrueQ[
  diagnostics["PoisonInstalledQ"] &&
  Lookup[firstOutcome, "Status", None] ===
    "CanonicalGlobalArtifactRuntimeCompletedV1" &&
  Lookup[firstOutcome, "Code", 99] === 0 &&
  Lookup[firstOutcome, "DefinitionsRestoredQ", False] &&
  Lookup[firstOutcome, "ContextRestoredQ", False] &&
  Lookup[firstOutcome, "ContextPathRestoredQ", False] &&
  validationPassedQ[firstValidation] &&
  diagnostics["FirstDefinitionsRestoredQ"] &&
  diagnostics["FirstCallerContextRestoredQ"] &&
  diagnostics["FirstCallerContextPathRestoredQ"] &&
  Lookup[secondOutcome, "Status", None] ===
    "CanonicalGlobalArtifactRuntimeCompletedV1" &&
  Lookup[secondOutcome, "Code", 99] === 0 &&
  Lookup[secondOutcome, "DefinitionsRestoredQ", False] &&
  Lookup[secondOutcome, "ContextRestoredQ", False] &&
  Lookup[secondOutcome, "ContextPathRestoredQ", False] &&
  validationPassedQ[secondValidation] &&
  diagnostics["SecondDefinitionsRestoredQ"] &&
  diagnostics["SecondCallerContextRestoredQ"] &&
  diagnostics["SecondCallerContextPathRestoredQ"] &&
  diagnostics["RepeatedValidationSameQ"] &&
  diagnostics["OriginalDefinitionsRestoredQ"]];
Print["CF300_CANONICAL_RUNTIME_MODEL diagnostics=",
  InputForm[diagnostics]];
Print["CF300_CANONICAL_RUNTIME_MODEL pass=", passed];
finalCode = If[passed, 0, 2];
End[];
EndPackage[];
System`Exit[finalCode];
