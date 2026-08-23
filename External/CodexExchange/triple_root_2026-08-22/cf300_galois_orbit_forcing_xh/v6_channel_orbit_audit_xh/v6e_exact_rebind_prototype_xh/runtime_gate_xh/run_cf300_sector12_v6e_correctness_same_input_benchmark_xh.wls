#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300V6eRuntimeGateDriverXH`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300V6eRuntimeGateDriverXH`Private`*"]];

systemExit[code_Integer] := (End[]; EndPackage[]; System`Exit[code]);
exitScopeActive = False;
exitTag = "CF300V6eRuntimeGateExit-" <> CreateUUID[];
driverExit[code_Integer] := If[TrueQ[exitScopeActive],
  Throw[<|"Status" -> "CF300V6eRuntimeGateExitRequested",
    "Code" -> code|>, exitTag], systemExit[code]];

expectedDispatchKernelID = 24;
actualDispatchKernelID = System`$KernelID;
If[actualDispatchKernelID =!= expectedDispatchKernelID,
  Print["CF300_V6E_RUNTIME_GATE FAIL wrong dispatch kernel expected=",
    expectedDispatchKernelID, " actual=", actualDispatchKernelID];
  driverExit[69]];
taskBrokerMaxHelpers = KernelPoolMission`$TaskBrokerMaxHelpers;
nestedKernelsAtEntry = System`Kernels[];
outerPoolKernelCount = System`$KernelCount;
If[! TrueQ[taskBrokerMaxHelpers === 0] || nestedKernelsAtEntry =!= {},
  Print["CF300_V6E_RUNTIME_GATE FAIL helper ceiling or nested kernels",
    " broker_max_helpers=", InputForm[taskBrokerMaxHelpers],
    " nested_kernels=", InputForm[nestedKernelsAtEntry]];
  driverExit[65]];

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{4, 5, 6, 7}, Length[arguments]],
  Print["CF300_V6E_RUNTIME_GATE FAIL usage=<project-root> " <>
    "<preparation.wl> <compiled-cache.wl> " <>
    "[<frozen-v6d-artifact.wl>] <fresh-benchmark-output.wl> " <>
    "[<fresh-lift-prerequisite-output.wl>] [native-threads]"];
  driverExit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
capturePrerequisiteQ = MemberQ[{6, 7}, Length[arguments]];
If[capturePrerequisiteQ,
  frozenV6dArtifactFile = ExpandFileName[arguments[[4]]];
  outputFile = ExpandFileName[arguments[[5]]];
  liftPrerequisiteOutputFile = ExpandFileName[arguments[[6]]];
  nativeThreads = If[Length[arguments] === 7,
    Quiet[Check[ToExpression[arguments[[7]]], $Failed]], 1],
  frozenV6dArtifactFile = Missing["PrerequisiteCaptureNotRequested"];
  outputFile = ExpandFileName[arguments[[4]]];
  liftPrerequisiteOutputFile =
    Missing["PrerequisiteCaptureNotRequested"];
  nativeThreads = If[Length[arguments] === 5,
    Quiet[Check[ToExpression[arguments[[5]]], $Failed]], 1]];
driverDirectory = DirectoryName[$InputFileName];
prototypeDirectory = DirectoryName[driverDirectory];
v6Directory = DirectoryName[prototypeDirectory];
exactLiftDirectory = FileNameJoin[{v6Directory,
  "exact_qeps_left_obstruction_xh"}];
galoisDirectory = DirectoryName[v6Directory];
exchangeDirectory = DirectoryName[galoisDirectory];
directDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];
supportDirectory = FileNameJoin[{exchangeDirectory,
  "cf300_sector12_next_ansatz_xh"}];
adapterDirectory = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_wl_xh"}];
nativeDirectory = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_xh"}];

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
    "DirectRootChannelCompiledArtifact.wl"}],
  "AnsatzRebind" -> FileNameJoin[{supportDirectory,
    "DirectRootChannelAnsatzRebind.wl"}],
  "NativeAdapter" -> FileNameJoin[{adapterDirectory,
    "FlintAffineRREFAdapter.wl"}],
  "OrbitCoreV6d" -> FileNameJoin[{v6Directory,
    "GaloisChannelOrbitCoreV6d.wl"}],
  "ExactChannelRebindV6" -> FileNameJoin[{v6Directory,
    "DirectRootChannelExactOneFormRebindV6.wl"}],
  "ExactChannelRebindV6e" -> FileNameJoin[{prototypeDirectory,
    "DirectRootChannelExactOneFormRebindV6e.wl"}],
  "V6eIntegrationReference" -> FileNameJoin[{prototypeDirectory,
    "V6E_DRIVER_INTEGRATION_BLOCK.wl"}],
  "ExactLiftPrerequisiteSchema" -> FileNameJoin[{exactLiftDirectory,
    "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl"}],
  "ExactLiftConsumerHelper" -> FileNameJoin[{exactLiftDirectory,
    "CF300ExactQepsLeftObstruction.wl"}],
  "NativeBinary" -> FileNameJoin[{nativeDirectory, "bin",
    "flint_affine_rref"}]|>;
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
    "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557",
  "AnsatzRebind" ->
    "8b0f8d7fdab72d9660836d1f2a92e7f03be5eb1adcbd7082b327ed4bb8b8e907",
  "NativeAdapter" ->
    "d5dbc6542ee21f6390963c57698e56992df9a04612464bc54f562398a1d78605",
  "OrbitCoreV6d" ->
    "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed",
  "ExactChannelRebindV6" ->
    "2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44",
  "ExactChannelRebindV6e" ->
    "2fea1e07c691ade811162f47db1d71d82a385dd01d07afd20beaa3aa0262f2e8",
  "V6eIntegrationReference" ->
    "7ea7a437cd25a440e4713040d0882947977a71f092510f0c02c940d8d02f0dbe",
  "ExactLiftPrerequisiteSchema" ->
    "909bc658858dc701cf05643e943655ea69fe301240f13272c70cc560c5506b45",
  "ExactLiftConsumerHelper" ->
    "e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b",
  "NativeBinary" ->
    "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5"|>;
allFiles = files;
allExpectedHashes = expectedHashes;
prerequisiteSourceNames = {"ExactLiftPrerequisiteSchema",
  "ExactLiftConsumerHelper"};
files = If[capturePrerequisiteQ, allFiles,
  KeyDrop[allFiles, prerequisiteSourceNames]];
expectedHashes = If[capturePrerequisiteQ, allExpectedHashes,
  KeyDrop[allExpectedHashes, prerequisiteSourceNames]];
expectedPreparationHash =
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedExactChannelFormsFingerprint =
  "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d";
expectedCompiledFormsFingerprint =
  "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7";
expectedMaximalAssemblyFingerprint =
  "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7";
expectedFrozenV6dArtifactHash =
  "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf";
expectedI00AcceptedPointsFingerprint =
  "f4ac00e6c1636c2f20028a2de449ea66a816ea017a84de6874dd63e54e155b50";
expectedCoefficientPivotFingerprint =
  "ccc7fa776fdcf55017e98e8d57ee2480690db3c27e0dc8f8625acebd79bfe377";
expectedCoefficientFreeFingerprint =
  "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534";
expectedCoefficientIndependentRowFingerprint =
  "9924c7eef76fea745d5451876be6012810e205e7ca28e021dd99cb2c720d9914";
expectedAugmentedPivotFingerprint =
  "8a9731fd7c345e781d71102d9cb3f8f0d745de3b17264e11b62ef538af0cb761";
expectedAugmentedFreeFingerprint = expectedCoefficientFreeFingerprint;
expectedAugmentedIndependentRowFingerprint =
  "3f35c25a1819c8c11ee28d300e252c47beda7f8213bcd45ac54f417fba3023a7";
frozenV6dRebindSeconds = 485.843061;
maximumAtomicOutputBytes = 2^30;

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
uuidStringQ[value_] := TrueQ[StringQ[value] && StringMatchQ[value,
  RegularExpression[
    "(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"]]];
sha256HexStringQ[value_] := TrueQ[StringQ[value] && StringMatchQ[value,
  RegularExpression["(?i)^[0-9a-f]{64}$"]]];
makeNonce[parts___] := Module[{nonce},
  nonce = Mod[Hash[{driverHashBefore, parts, #1}, "SHA256"], 2^64] & /@
    {"hi", "lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]];
artifactRead[file_String] := If[! FileExistsQ[file], $Failed,
  Quiet[CheckAbort[Get[file], $Aborted]]];
loadSource[file_String] := Module[{value},
  value = Quiet[CheckAbort[Get[file], $Aborted]];
  <|"Status" -> Which[value === $Aborted, "Aborted",
      value === $Failed, "Failed", True, "Loaded"],
    "ReturnHead" -> ToString[Head[value], InputForm]|>];
stableInputsQ[] := TrueQ[
  hashes[] === sourceHashesBefore &&
  FileHash[preparationFile, "SHA256", "HexString"] ===
    expectedPreparationHash &&
  FileHash[cacheFile, "SHA256", "HexString"] === expectedCacheHash &&
  (! capturePrerequisiteQ ||
    FileHash[frozenV6dArtifactFile, "SHA256", "HexString"] ===
      expectedFrozenV6dArtifactHash) &&
  FileHash[$InputFileName, "SHA256", "HexString"] === driverHashBefore];
deleteIfPresent[file_String] := Module[{},
  If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
  ! FileExistsQ[file]];
writeAtomicTo[value_, target_String] := Module[
  {temporary, written, renamed, reread},
  If[FileExistsQ[target] || ByteCount[value] > maximumAtomicOutputBytes,
    Return[$Failed]];
  temporary = target <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = CheckAbort[Quiet[Check[Put[value, temporary], $Failed]],
    (deleteIfPresent[temporary]; Abort[])];
  If[written === $Failed || ! FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  If[FileByteCount[temporary] > maximumAtomicOutputBytes,
    deleteIfPresent[temporary]; Return[$Failed]];
  renamed = CheckAbort[Quiet[Check[RenameFile[temporary, target,
    OverwriteTarget -> False], $Failed]],
    (deleteIfPresent[temporary]; Abort[])];
  If[renamed === $Failed || ! FileExistsQ[target] ||
      FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  reread = Quiet[Check[Get[target], $Failed]];
  If[! SameQ[reread, value],
    deleteIfPresent[target]; Return[$Failed]];
  target];
writeAtomic[value_] := writeAtomicTo[value, outputFile];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|"Status" -> status|>, data];
  result = Append[result, "AtomicOutputSizePolicy" -> <|
    "MaximumBytes" -> maximumAtomicOutputBytes,
    "PreTelemetryByteCount" -> ByteCount[result],
    "TemporaryCleanupRequired" -> True,
    "OverwriteTarget" -> False|>];
  If[writeAtomic[result] === $Failed,
    Print["CF300_V6E_RUNTIME_GATE FAIL atomic output race output=",
      outputFile]; driverExit[98]];
  Print["CF300_V6E_RUNTIME_GATE status=", status,
    " output=", outputFile];
  driverExit[code]];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    (capturePrerequisiteQ && ! FileExistsQ[frozenV6dArtifactFile]) ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]] ||
    (capturePrerequisiteQ && (
      FileExistsQ[liftPrerequisiteOutputFile] ||
      ! DirectoryQ[DirectoryName[liftPrerequisiteOutputFile]] ||
      outputFile === liftPrerequisiteOutputFile)) ||
    ! IntegerQ[nativeThreads] || ! (1 <= nativeThreads <= 8),
  Print["CF300_V6E_RUNTIME_GATE FAIL invalid input or stale output"];
  driverExit[65]];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
If[sourceHashesBefore =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash ||
    (capturePrerequisiteQ &&
      FileHash[frozenV6dArtifactFile, "SHA256", "HexString"] =!=
        expectedFrozenV6dArtifactHash),
  Print["CF300_V6E_RUNTIME_GATE FAIL pinned source or artifact mismatch"];
  driverExit[66]];

(* The integration block is a held reference, never executable input. *)
loadSourceNames = {"TripleRootAlgebra", "TripleRootStripAdapter",
  "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
  "Assembler", "ArtifactHelper", "AnsatzRebind", "NativeAdapter",
  "OrbitCoreV6d", "ExactChannelRebindV6", "ExactChannelRebindV6e"};
If[capturePrerequisiteQ,
  loadSourceNames = Append[loadSourceNames, "ExactLiftConsumerHelper"]];
loadOutcomes = AssociationMap[loadSource[files[#1]] &, loadSourceNames];
If[! AllTrue[Lookup[Values[loadOutcomes], "Status", None],
      #1 === "Loaded" &] || ! stableInputsQ[],
  Print["CF300_V6E_RUNTIME_GATE FAIL pinned load failed outcomes=",
    InputForm[loadOutcomes]];
  driverExit[67]];

artifactContext = "CodexCF300V6eRuntimeArtifactXH`";
artifactPattern = artifactContext <> "*";
expectedArtifactSymbolNames = {"v", "w", "x", "y", "eps"};
definitionComponents = {"OwnValues", "DownValues", "UpValues",
  "SubValues", "NValues", "DefaultValues", "FormatValues",
  "Attributes"};
artifactQualifiedName[name_String] := If[StringContainsQ[name, "`"],
  name, artifactContext <> name];
SetAttributes[symbolDefinitionStateHeld, HoldAll];
symbolDefinitionStateHeld[symbol_] := <|
  "OwnValues" -> OwnValues[symbol], "DownValues" -> DownValues[symbol],
  "UpValues" -> UpValues[symbol], "SubValues" -> SubValues[symbol],
  "NValues" -> NValues[symbol], "DefaultValues" -> DefaultValues[symbol],
  "FormatValues" -> FormatValues[symbol],
  "Attributes" -> Attributes[symbol]|>;
symbolDefinitionStateByName[name_String] := ToExpression[
  artifactQualifiedName[name], InputForm,
  Function[heldSymbol, symbolDefinitionStateHeld[heldSymbol], HoldAll]];
SetAttributes[artifactSymbolIdentityHeld, HoldAll];
artifactSymbolIdentityHeld[symbol_Symbol] := <|
  "Context" -> Context[symbol], "SymbolName" -> SymbolName[symbol],
  "FullName" -> Context[symbol] <> SymbolName[symbol]|>;
artifactSymbolIdentityHeld[___] := $Failed;
artifactSymbolIdentityByName[name_String] := ToExpression[
  artifactQualifiedName[name], InputForm,
  Function[heldSymbol, artifactSymbolIdentityHeld[heldSymbol], HoldAll]];
artifactNamespaceAudit[names_List] := Module[
  {qualifiedNames, identities, identityValues},
  qualifiedNames = DeleteDuplicates[artifactQualifiedName /@ names];
  identities = AssociationMap[artifactSymbolIdentityByName,
    qualifiedNames];
  identityValues = Values[identities];
  <|"RawNames" -> names, "QualifiedNames" -> qualifiedNames,
    "Identities" -> identities, "ExactOwnedNamespaceQ" -> TrueQ[
      Length[qualifiedNames] === Length[expectedArtifactSymbolNames] &&
      FreeQ[identityValues, $Failed] &&
      AllTrue[Lookup[identityValues, "Context", $Failed],
        #1 === artifactContext &] &&
      Sort[Lookup[identityValues, "SymbolName", $Failed]] ===
        Sort[expectedArtifactSymbolNames] &&
      Sort[Lookup[identityValues, "FullName", $Failed]] === Sort[
        artifactContext <> #1 & /@ expectedArtifactSymbolNames]]|>];
definitionFreeStateQ[state_Association] := TrueQ[
  Lookup[state, definitionComponents, $Failed] ===
    ConstantArray[{}, Length[definitionComponents]]];
definitionFreeStateQ[___] := False;
artifactDefinitionStates[names_List] := AssociationMap[
  symbolDefinitionStateByName,
  DeleteDuplicates[artifactQualifiedName /@ names]];
removeQualifiedSymbolName[name_String] := ToExpression[name, InputForm,
  Function[heldSymbol, Quiet[System`Remove[heldSymbol]], HoldAll]];
If[System`Names[artifactPattern] =!= {},
  Print["CF300_V6E_RUNTIME_GATE FAIL artifact context not fresh"];
  driverExit[67]];
runtimeContextPath = {artifactContext,
  "CodexDirectRootChannelCompiledArtifact`",
  "CodexDirectRootChannelAssembler`",
  "CodexDirectRootChannelAnsatzRebind`",
  "CodexFLINTAffineRREFAdapter`",
  "CodexCF300GaloisChannelOrbitV6d`",
  "CodexDirectRootChannelExactOneFormRebindV6`",
  "CodexDirectRootChannelExactOneFormRebindV6e`",
  "CodexCF300ExactQepsLeftObstruction`",
  "CodexTripleRootReconstruction`", "CodexTripleRootPilot`",
  "CodexTripleRootStrip`", "CodexTripleRoot`", "System`",
  "CodexCF300V6eRuntimeGateDriverXH`"};
callerContextBefore = $Context;
callerContextPathBefore = $ContextPath;
scopeCleanupPassed = False;

scopeOutcome = Internal`WithLocalSettings[
  exitScopeActive = True,
  Catch[Block[{$Context = artifactContext,
      $ContextPath = runtimeContextPath},

    preparationArtifact = artifactRead[preparationFile];
    rawCacheArtifact = artifactRead[cacheFile];
    hydratedPreparation = If[AssociationQ[preparationArtifact],
      Lookup[preparationArtifact, "Preparation", $Failed], $Failed];
    rawAssembly = If[AssociationQ[rawCacheArtifact],
      Lookup[rawCacheArtifact, "DirectAssembly", $Failed], $Failed];
    artifactNamesAfterHydration = System`Names[artifactPattern];
    artifactNamespaceAfterHydrationAudit = artifactNamespaceAudit[
      artifactNamesAfterHydration];
    artifactDefinitionsAfterHydration = artifactDefinitionStates[
      artifactNamesAfterHydration];
    hydrationDiagnostics = <|
      "ArtifactNamesAfterHydration" -> artifactNamesAfterHydration,
      "ArtifactNamespaceAfterHydrationAudit" ->
        artifactNamespaceAfterHydrationAudit,
      "ArtifactDefinitionsAfterHydration" ->
        artifactDefinitionsAfterHydration,
      "ArtifactNamespaceExact" -> TrueQ[
        artifactNamespaceAfterHydrationAudit["ExactOwnedNamespaceQ"]],
      "ArtifactSymbolsDefinitionFree" -> AllTrue[
        Values[artifactDefinitionsAfterHydration], definitionFreeStateQ],
      "GlobalContextPresent" -> MemberQ[$ContextPath, "Global`"],
      "PreparationAssociationQ" -> AssociationQ[preparationArtifact],
      "PreparationStatus" -> If[AssociationQ[preparationArtifact],
        Lookup[preparationArtifact, "Status", None], $Failed],
      "PreparationABIValidQ" -> If[AssociationQ[hydratedPreparation],
        CodexTripleRootReconstruction`TRPreparationABIValidQ[
          hydratedPreparation], False],
      "CacheAssociationQ" -> AssociationQ[rawCacheArtifact],
      "CacheStatus" -> If[AssociationQ[rawCacheArtifact],
        Lookup[rawCacheArtifact, "Status", None], $Failed],
      "CacheABIValidQ" -> If[AssociationQ[rawCacheArtifact],
        CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
          rawCacheArtifact], False],
      "AssemblyABIValidQ" -> If[AssociationQ[rawAssembly],
        CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
          rawAssembly], False],
      "ExactFormsFingerprint" -> If[AssociationQ[rawAssembly],
        fingerprint[rawAssembly["ExactChannelForms"]], $Failed],
      "CompiledFormsFingerprint" -> If[AssociationQ[rawAssembly],
        fingerprint[rawAssembly["CompiledForms"]], $Failed]|>;
    If[! TrueQ[hydrationDiagnostics["ArtifactNamespaceExact"]] ||
        ! TrueQ[hydrationDiagnostics["ArtifactSymbolsDefinitionFree"]] ||
        TrueQ[hydrationDiagnostics["GlobalContextPresent"]] ||
        ! And @@ Lookup[hydrationDiagnostics, {
          "PreparationAssociationQ", "PreparationABIValidQ",
          "CacheAssociationQ", "CacheABIValidQ",
          "AssemblyABIValidQ"}, False] ||
        hydrationDiagnostics["PreparationStatus"] =!=
          "PreparedCF300Sector12Rank2Extension" ||
        hydrationDiagnostics["CacheStatus"] =!=
          "DirectRootChannelCompiledArtifactV1" ||
        hydrationDiagnostics["ExactFormsFingerprint"] =!=
          expectedExactChannelFormsFingerprint ||
        hydrationDiagnostics["CompiledFormsFingerprint"] =!=
          expectedCompiledFormsFingerprint,
      finish["PinnedArtifactHydrationInvalid", <|
        "HydrationDiagnostics" -> hydrationDiagnostics|>, 68]];

    basePreparation = preparationArtifact["Preparation"];
    baseAssembly = rawCacheArtifact["DirectAssembly"];
    If[baseAssembly["SourceABIFingerprint"] =!=
        basePreparation["ABIFingerprint"],
      finish["BaseABIIdentityInvalid", <||>, 69]];
    {x, y} = basePreparation["Variables"];
    epsilon = basePreparation["Regulator"];
    roots = basePreparation["Roots"];
    baseOneForms = basePreparation["OneForms"];
    baseMetadata = basePreparation["OneFormMetadata"];
    baseSupport = basePreparation["GaugeSupport"];
    {upper, lower} = basePreparation["Dimensions"];
    gradeCount = basePreparation["GradeCount"];
    baseGaugeCount = basePreparation["GaugeUnknownCount"];
    baseResidueCount = basePreparation["ResidueUnknownCount"];
    baseUnknownCount = basePreparation["UnknownCount"];
    forcingPair = basePreparation["Record", "Strip"][[3]];
    epsilonSamples = {0, 1, -1, 2};
    signMasks = Range[0, 3];
    If[{Length[roots], gradeCount, upper, lower, Length[baseSupport],
          Length[baseOneForms], baseGaugeCount, baseResidueCount,
          baseUnknownCount} =!= {2, 4, 2, 2, 30, 36, 480, 144, 624} ||
        Lookup[baseMetadata, {"DiagonalCount", "ForcingDLogCandidates",
          "DeduplicatedCount"}, None] =!= {8, 28, 36} ||
        Dimensions[forcingPair] =!= {2, 2, 2},
      finish["PhysicalDimensionContractInvalid", <||>, 70]];

    censusMemoryBefore = MemoryInUse[];
    {censusSeconds, orbitBuild} = AbsoluteTiming[
      CodexCF300GaloisChannelOrbitV6d`GCOBuildOrbitBasis[
        basePreparation, baseAssembly,
        "EpsilonSamples" -> epsilonSamples,
        "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9]];
    censusMemoryAfter = MemoryInUse[];
    If[Lookup[orbitBuild, "Status", None] =!=
        "ExactGaloisChannelOrbitBasisV6d",
      finish["GaloisChannelOrbitBasisBuildFailed", <|
        "CensusSeconds" -> censusSeconds,
        "OrbitBuildFailure" -> orbitBuild|>, 72]];
    potentialOccurrenceCount = orbitBuild["PotentialOccurrenceCount"];
    potentialSourceCount = orbitBuild["PotentialSourceCount"];
    potentialAliasCount = orbitBuild["PotentialAliasCount"];
    conjugateCandidateCount = orbitBuild["ConjugateCandidateCount"];
    forcingLetterRecords = orbitBuild["ForcingLetterRecords"];
    additionalLetterCount = orbitBuild["AdditionalLetterCount"];
    additionalOneFormChannels = orbitBuild["AdditionalOneFormChannels"];
    maxOneForms = orbitBuild["MaxOneForms"];
    orbitClosureExact = orbitBuild["OrbitClosureExact"];
    orbitPerformanceCounters = orbitBuild["PerformanceCounters"];
    characterCertificates = orbitBuild["CharacterCertificates"];
    If[{potentialOccurrenceCount, potentialSourceCount,
          potentialAliasCount, conjugateCandidateCount,
          Length[forcingLetterRecords], additionalLetterCount,
          Length[maxOneForms]} =!= {32, 28, 4, 112, 100, 72, 108} ||
        ! TrueQ[orbitClosureExact] ||
        ! And @@ Lookup[characterCertificates, {
          "InvolutionExact", "XorCompositionExact",
          "FieldMultiplicationEquivarianceExact",
          "GradeDiagonalDerivativeEquivarianceExact"}, False] ||
        Lookup[orbitPerformanceCounters,
          "LegacyAlgebraicFieldDecomposeCallsInCensus", -1] =!= 0 ||
        Lookup[orbitPerformanceCounters,
          "LegacyAlgebraicRootBranchSubstitutionsInCensus", -1] =!= 0,
      finish["GaloisChannelOrbitPostconditionFailed", <|
        "Counts" -> {potentialOccurrenceCount, potentialSourceCount,
          potentialAliasCount, conjugateCandidateCount,
          Length[forcingLetterRecords], additionalLetterCount,
          Length[maxOneForms]},
        "CharacterCertificates" -> characterCertificates|>, 73]];

    gaugeCount = baseGaugeCount;
    residueCount = Length[maxOneForms] upper lower;
    unknownCount = gaugeCount + residueCount;
    payload = CodexTripleRootReconstruction`Private`trBuildABIPayload[
      basePreparation["Record"], roots, basePreparation["Variables"],
      epsilon, basePreparation["Dimensions"],
      basePreparation["GaugeDenominator"], baseSupport, maxOneForms,
      basePreparation["Normalizations"]];
    If[payload === $Failed,
      finish["MaximalOrbitABIPayloadFailed", <||>, 78]];
    maxPreparation = Join[basePreparation, <|
      "OneForms" -> maxOneForms,
      "OneFormMetadata" -> <|
        "Status" -> "CF300GaloisOrbitClosedForcingBasisV6eBenchmark",
        "BaseOneFormCount" -> Length[baseOneForms],
        "PotentialOccurrenceCount" -> potentialOccurrenceCount,
        "PotentialSourceCount" -> potentialSourceCount,
        "PotentialAliasCount" -> potentialAliasCount,
        "ConjugateCandidateCount" -> conjugateCandidateCount,
        "DeduplicatedForcingLetterCount" -> Length[forcingLetterRecords],
        "AppendedOrbitLetterCount" -> additionalLetterCount,
        "GaloisSignMasks" -> signMasks,
        "EpsilonSamples" -> epsilonSamples|>,
      "ResidueUnknownCount" -> residueCount,
      "UnknownCount" -> unknownCount,
      "ABIPayload" -> payload,
      "ABIFingerprint" -> fingerprint[payload]|>];
    If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[
          maxPreparation],
      finish["MaximalOrbitPreparationInvalid", <||>, 78]];
    pointCount = Max[21, Ceiling[(unknownCount + 32)/32]];
    If[unknownCount =!= 912 || pointCount =!= 30,
      finish["MaximalOrbitSampleDimensionContractInvalid", <|
        "UnknownCount" -> unknownCount,
        "PointCount" -> pointCount|>, 78]];

    additionalRecords = Map[
      Function[channel, SelectFirst[forcingLetterRecords,
        SameQ[Lookup[#1, "OneFormChannels", $Failed], channel] &,
        $Failed]], additionalOneFormChannels];
    If[Length[additionalRecords] =!= additionalLetterCount ||
        ! FreeQ[additionalRecords, $Failed] ||
        Lookup[additionalRecords, "OneFormChannels"] =!=
          additionalOneFormChannels ||
        Lookup[additionalRecords, "OneForm"] =!=
          Drop[maxOneForms, Length[baseOneForms]] ||
        ! DuplicateFreeQ[Lookup[additionalRecords,
          "ChannelFingerprint"]],
      finish["V6eAdditionalRecordSelectionInvalid", <||>, 79]];
    immutableInputFingerprint = fingerprint[
      {baseAssembly, maxPreparation, additionalRecords}];

    (* Correctness oracle deliberately precedes both benchmark trials. *)
    oracleMemoryBefore = MemoryInUse[];
    {oracleSeconds, oracleAssembly} = AbsoluteTiming[
      CodexDirectRootChannelExactOneFormRebindV6`DRCARebindExactOneFormChannels[
        baseAssembly, maxPreparation,
          additionalOneFormChannels]];
    oracleMemoryAfter = MemoryInUse[];
    oracleDiagnostics = Lookup[oracleAssembly,
      "ExactOneFormChannelRebindV6", <||>];
    If[Lookup[oracleDiagnostics, "Status", None] =!=
          "ExactOneFormChannelRebindV6" ||
        Lookup[oracleDiagnostics, "AppendedOneFormCount", -1] =!=
          additionalLetterCount ||
        Lookup[oracleAssembly, "AssemblyFingerprint", None] =!=
          expectedMaximalAssemblyFingerprint ||
        ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
          oracleAssembly] || ! stableInputsQ[] ||
        fingerprint[{baseAssembly, maxPreparation, additionalRecords}] =!=
          immutableInputFingerprint,
      finish["FrozenV6CorrectnessOracleFailed", <|
        "OracleSeconds" -> oracleSeconds,
        "OracleDiagnostics" -> oracleDiagnostics,
        "ObservedAssemblyFingerprint" -> Lookup[oracleAssembly,
          "AssemblyFingerprint", None]|>, 79]];
    oracleSemanticAssembly = KeyDrop[oracleAssembly,
      "ExactOneFormChannelRebindV6"];
    Print["CF300_V6E_RUNTIME_GATE milestone=oracle_ready seconds=",
      oracleSeconds, " fingerprint=", expectedMaximalAssemblyFingerprint];

    Clear[runV6eTrial];
    runV6eTrial[label_String] := Module[
      {inputBefore, memoryBefore, seconds, result, memoryAfter,
       diagnostics, seal, sealValidBefore, firstConsume, replayConsume,
       semanticResult, inputAfter, gates},
      inputBefore = fingerprint[
        {baseAssembly, maxPreparation, additionalRecords}];
      memoryBefore = MemoryInUse[];
      {seconds, result} = AbsoluteTiming[
        CodexDirectRootChannelExactOneFormRebindV6e`DRCARebindExactOneFormRecordsV6e[
          baseAssembly, maxPreparation, additionalRecords]];
      memoryAfter = MemoryInUse[];
      diagnostics = Lookup[result,
        "ExactOneFormChannelRebindV6e", <||>];
      seal = Lookup[result,
        "ExactOneFormChannelRebindSealV6e", <||>];
      sealValidBefore =
        CodexDirectRootChannelExactOneFormRebindV6e`DRCAExactOneFormRebindSealValidQ[
          baseAssembly, maxPreparation, result, seal];
      firstConsume =
        CodexDirectRootChannelExactOneFormRebindV6e`DRCAConsumeExactOneFormRebindSealV6e[
          baseAssembly, maxPreparation, result, seal];
      replayConsume =
        CodexDirectRootChannelExactOneFormRebindV6e`DRCAConsumeExactOneFormRebindSealV6e[
          baseAssembly, maxPreparation, result, seal];
      semanticResult = KeyDrop[result, {
        "ExactOneFormChannelRebindV6e",
        "ExactOneFormChannelRebindSealV6e"}];
      inputAfter = fingerprint[
        {baseAssembly, maxPreparation, additionalRecords}];
      gates = <|
        "StatusExact" -> (Lookup[diagnostics, "Status", None] ===
          "ExactOneFormChannelRebindV6e"),
        "InputIdentityStable" ->
          (inputBefore === immutableInputFingerprint === inputAfter),
        "ExactOracleIdentity" -> SameQ[semanticResult,
          oracleSemanticAssembly],
        "MaximalAssemblyFingerprintExact" ->
          (Lookup[result, "AssemblyFingerprint", None] ===
            expectedMaximalAssemblyFingerprint),
        "RawLeafCountExact" ->
          (Lookup[diagnostics, "RawLeafCount", -1] ===
            additionalLetterCount 2 gradeCount),
        "RawUniqueReuseConservationExact" ->
          (Lookup[diagnostics, "RawLeafCount", -1] ===
            Lookup[diagnostics, "UniqueCompiledLeafCount", -2] +
            Lookup[diagnostics, "CompileCacheReuseCount", -3]),
        "CompileCountExact" ->
          (Lookup[diagnostics, "CompileCount", -1] ===
            Lookup[diagnostics, "UniqueCompiledLeafCount", -2]),
        "CollisionFree" ->
          (Lookup[diagnostics, "CollisionGroupCount", -1] === 0),
        "LegacyOracleCountExact" ->
          (Lookup[diagnostics,
            "LegacyWholeResultOracleCount", -1] === 1),
        "LegacyOraclePassed" -> TrueQ[Lookup[diagnostics,
          "LegacyWholeResultOraclePassed", False]],
        "SpecializedSealPassed" -> TrueQ[Lookup[diagnostics,
          "SpecializedSealPassed", False]],
        "SpecializedSealValidBeforeConsume" ->
          TrueQ[sealValidBefore],
        "SealStatusExact" ->
          (Lookup[seal, "Status", None] ===
            "ExactOneFormRebindSpecializedSealV6e"),
        "SealNonceUUIDShaped" ->
          uuidStringQ[Lookup[seal, "Nonce", None]],
        "SealFingerprintSHA256Shaped" ->
          sha256HexStringQ[Lookup[seal, "SealFingerprint", None]],
        "FreshThenReplayConsumeExact" ->
          SameQ[{firstConsume, replayConsume}, {True, False}],
        "NoAlgebraicFallback" ->
          (Lookup[diagnostics,
              "AlgebraicFieldDecompositionCalls", -1] === 0 &&
            Lookup[diagnostics,
              "AlgebraicRootBranchSubstitutions", -1] === 0),
        "NoFailureOrMissing" -> FreeQ[{result, diagnostics, seal},
          $Failed | _Missing],
        "SourcesStable" -> stableInputsQ[]|>;
      <|"Status" -> If[And @@ Values[gates],
          "CF300V6eSameInputTrialPassed",
          "CF300V6eSameInputTrialFailed"],
        "Label" -> label, "Seconds" -> seconds,
        "OuterMemory" -> <|"BeforeBytes" -> memoryBefore,
          "AfterBytes" -> memoryAfter,
          "DeltaBytes" -> memoryAfter - memoryBefore|>,
        "Gates" -> gates,
        "AssemblyFingerprint" -> Lookup[result,
          "AssemblyFingerprint", $Failed],
        "ExactFormsFingerprint" -> Lookup[result,
          "ExactChannelFormsFingerprint", $Failed],
        "CompiledFormsFingerprint" -> Lookup[result,
          "CompiledFormsFingerprint", $Failed],
        "CompiledShapeFingerprint" -> Lookup[result,
          "CompiledFormsShapeFingerprint", $Failed],
        "RawLeafCount" -> Lookup[diagnostics, "RawLeafCount", $Failed],
        "UniqueCompiledLeafCount" -> Lookup[diagnostics,
          "UniqueCompiledLeafCount", $Failed],
        "CompileCacheReuseCount" -> Lookup[diagnostics,
          "CompileCacheReuseCount", $Failed],
        "PhaseSeconds" -> Lookup[diagnostics, "PhaseSeconds", $Failed],
        "PhaseMemory" -> Lookup[diagnostics, "PhaseMemory", $Failed],
        "ExpressionByteCounts" -> Lookup[diagnostics,
          "ExpressionByteCounts", $Failed],
        "SerializedInputFormCharacterCounts" -> Lookup[diagnostics,
          "SerializedInputFormCharacterCounts", $Failed],
        "SealStatus" -> Lookup[seal, "Status", $Failed],
        "SealNonce" -> Lookup[seal, "Nonce", $Failed],
        "SealFingerprint" -> Lookup[seal, "SealFingerprint", $Failed],
        "SealValidBeforeConsume" -> TrueQ[sealValidBefore],
        "FreshConsumePassed" -> TrueQ[firstConsume],
        "ReplayConsumeRejected" -> TrueQ[replayConsume === False],
        "SemanticAssembly" -> semanticResult|>];

    canonicalVectorQ[array_, length_Integer, prime_Integer] := TrueQ[
      VectorQ[array, IntegerQ] && Length[array] === length &&
      AllTrue[array, 0 <= #1 < prime &]];
    canonicalMatrixQ[array_, rows_Integer, columns_Integer,
        prime_Integer] := TrueQ[
      If[rows === 0, array === {},
        MatrixQ[array, IntegerQ] &&
          Dimensions[array] === {rows, columns}] &&
      AllTrue[Flatten[Normal[array]], 0 <= #1 < prime &]];
    nativeRankFailure[status_String, data_: <||>] :=
      Join[<|"Status" -> status|>, data];
    nativeRank[localMatrix_?MatrixQ, prime_Integer, label_String,
        imageID_String, tag_String] := Module[
      {rows, columns, request, seconds, run, certificate, rank,
       nullity, diagnosticSeconds, diagnosticRun, pivots, free,
       independentRows},
      {rows, columns} = Dimensions[localMatrix];
      request = CodexFLINTAffineRREFAdapter`CFFRMakeRequest[
        localMatrix, ConstantArray[0, rows], prime, Range[columns],
        makeNonce[label, imageID, tag]];
      If[Lookup[request, "Status", None] =!= "CFFRRequestV1",
        Return[nativeRankFailure["NativeRankRequestFailed", <|
          "RequestStatus" -> Lookup[request, "Status", None]|>]]];
      {seconds, run} = AbsoluteTiming[
        CodexFLINTAffineRREFAdapter`CFFRRun[
          files["NativeBinary"], request, nativeThreads, False, 900]];
      If[Lookup[run, "Status", None] =!=
          "VerifiedFLINTAffineRREFRun",
        {diagnosticSeconds, diagnosticRun} = AbsoluteTiming[
          CodexFLINTAffineRREFAdapter`CFFRRun[
            files["NativeBinary"], request, nativeThreads, True, 900]];
        Return[nativeRankFailure["NativeRankRunFailed", <|
          "RunStatus" -> Lookup[run, "Status", None],
          "Verification" -> Lookup[run, "Verification", Missing["Absent"]],
          "DiagnosticRunStatus" -> Lookup[diagnosticRun, "Status", None],
          "DiagnosticVerification" -> Lookup[diagnosticRun,
            "Verification", Missing["Absent"]],
          "DiagnosticArtifactDirectory" -> Lookup[diagnosticRun,
            "ArtifactDirectory", Missing["Absent"]],
          "DiagnosticSeconds" -> diagnosticSeconds,
          "Seconds" -> seconds|>]]];
      certificate = run["Certificate"];
      rank = certificate["Rank"];
      nullity = certificate["Nullity"];
      pivots = certificate["PivotColumns"];
      free = certificate["FreeColumns"];
      independentRows = certificate["IndependentEquationRows"];
      If[certificate["ParticularSolution"] =!=
            ConstantArray[0, columns] || rank + nullity =!= columns ||
          ! canonicalVectorQ[certificate["ParticularSolution"], columns,
            prime] ||
          ! canonicalMatrixQ[certificate["NullspaceBasis"], nullity,
            columns, prime] ||
          ! VectorQ[pivots, IntegerQ] || ! VectorQ[free, IntegerQ] ||
          ! VectorQ[independentRows, IntegerQ] ||
          ! DuplicateFreeQ[pivots] || ! DuplicateFreeQ[free] ||
          ! DuplicateFreeQ[independentRows] ||
          Sort[Join[pivots, free]] =!= Range[columns] ||
          Length[pivots] =!= rank || Length[free] =!= nullity ||
          Length[independentRows] =!= rank ||
          Min[independentRows] < 1 || Max[independentRows] > rows,
        Return[nativeRankFailure[
          "NativeRankCertificatePostconditionFailed", <|
            "MatrixDimensions" -> {rows, columns}, "Rank" -> rank,
            "Nullity" -> nullity, "Seconds" -> seconds|>]]];
      <|"Status" -> "VerifiedNativeRankWithStablePlanV1",
        "MatrixDimensions" -> {rows, columns}, "Rank" -> rank,
        "Nullity" -> nullity, "Seconds" -> seconds,
        "PivotColumns" -> pivots, "FreeColumns" -> free,
        "IndependentEquationRows" -> independentRows,
        "PivotFingerprint" -> fingerprint[pivots],
        "FreeColumnFingerprint" -> fingerprint[free],
        "RowWitnessFingerprint" -> fingerprint[independentRows]|>];
    rankImage[matrix_?MatrixQ, right_List, prime_Integer,
        label_String, imageID_String] := Module[
      {rows, columns, rightColumn, augmented, coefficient,
       augmentedRank},
      {rows, columns} = Dimensions[matrix];
      rightColumn = SparseArray[
        MapIndexed[{First[#2], 1} -> #1 &, right], {rows, 1}];
      augmented = Join[SparseArray[matrix], rightColumn, 2];
      coefficient = nativeRank[SparseArray[matrix], prime,
        label, imageID, "coefficient"];
      If[Lookup[coefficient, "Status", None] =!=
          "VerifiedNativeRankWithStablePlanV1",
        Return[nativeRankFailure["RankImageCoefficientFailed", <|
          "Coefficient" -> coefficient|>]]];
      augmentedRank = nativeRank[augmented, prime,
        label, imageID, "augmented"];
      If[Lookup[augmentedRank, "Status", None] =!=
          "VerifiedNativeRankWithStablePlanV1",
        Return[nativeRankFailure["RankImageAugmentedFailed", <|
          "Coefficient" -> coefficient,
          "Augmented" -> augmentedRank|>]]];
      If[! MemberQ[{coefficient["Rank"], coefficient["Rank"] + 1},
          augmentedRank["Rank"]],
        Return[nativeRankFailure["RankImageRankRelationFailed", <|
          "Coefficient" -> coefficient,
          "Augmented" -> augmentedRank|>]]];
      <|"Status" -> "CertifiedAffineConsistencyByTwoStableRanksV1",
        "Consistent" ->
          (coefficient["Rank"] === augmentedRank["Rank"]),
        "CoefficientRank" -> coefficient["Rank"],
        "AugmentedRank" -> augmentedRank["Rank"],
        "CoefficientNullity" -> coefficient["Nullity"],
        "CoefficientCertificate" -> coefficient,
        "AugmentedCertificate" -> augmentedRank|>];

    trial1Full = runV6eTrial["same-input-1"];
    trial1 = KeyDrop[trial1Full, "SemanticAssembly"];
    If[Lookup[trial1, "Status", None] =!=
        "CF300V6eSameInputTrialPassed",
      finish["CF300Sector12V6eFirstTrialFailed", <|
        "Trial1" -> trial1|>, 80]];
    Clear[trial1Full];
    trial2Full = runV6eTrial["same-input-2"];
    screenAssembly = Lookup[trial2Full, "SemanticAssembly", $Failed];
    trial2 = KeyDrop[trial2Full, "SemanticAssembly"];
    If[Lookup[trial2, "Status", None] =!=
        "CF300V6eSameInputTrialPassed",
      finish["CF300Sector12V6eSecondTrialFailed", <|
        "Trial1" -> trial1, "Trial2" -> trial2|>, 80]];
    Clear[trial2Full];

    repeatFingerprintsExact = SameQ[
      KeyTake[trial1, {"AssemblyFingerprint", "ExactFormsFingerprint",
        "CompiledFormsFingerprint", "CompiledShapeFingerprint",
        "RawLeafCount", "UniqueCompiledLeafCount",
        "CompileCacheReuseCount"}],
      KeyTake[trial2, {"AssemblyFingerprint", "ExactFormsFingerprint",
        "CompiledFormsFingerprint", "CompiledShapeFingerprint",
        "RawLeafCount", "UniqueCompiledLeafCount",
        "CompileCacheReuseCount"}]];
    trialSealEvidenceValid = TrueQ[AllTrue[{trial1, trial2},
      Function[trial,
        Lookup[trial, "SealStatus", None] ===
            "ExactOneFormRebindSpecializedSealV6e" &&
          uuidStringQ[Lookup[trial, "SealNonce", None]] &&
          sha256HexStringQ[Lookup[trial, "SealFingerprint", None]] &&
          TrueQ[Lookup[trial, "SealValidBeforeConsume", False]] &&
          TrueQ[Lookup[trial, "FreshConsumePassed", False]] &&
          TrueQ[Lookup[trial, "ReplayConsumeRejected", False]]]]];
    trialSealNoncesDistinct = TrueQ[DuplicateFreeQ[
      Lookup[{trial1, trial2}, "SealNonce", $Failed]]];
    trialSealFingerprintsDistinct = TrueQ[DuplicateFreeQ[
      Lookup[{trial1, trial2}, "SealFingerprint", $Failed]]];
    trialSeconds = Lookup[{trial1, trial2}, "Seconds"];
    medianV6eSeconds = Median[trialSeconds];
    performanceAcceptancePassed = TrueQ[
      repeatFingerprintsExact && trialSealEvidenceValid &&
      trialSealNoncesDistinct && trialSealFingerprintsDistinct &&
      medianV6eSeconds < frozenV6dRebindSeconds];
    If[! repeatFingerprintsExact || ! trialSealEvidenceValid ||
        ! trialSealNoncesDistinct || ! trialSealFingerprintsDistinct ||
        ! stableInputsQ[] ||
        fingerprint[{baseAssembly, maxPreparation, additionalRecords}] =!=
          immutableInputFingerprint,
      finish["CF300Sector12V6eRepeatIdentityFailed", <|
        "Trial1" -> trial1, "Trial2" -> trial2,
        "RepeatFingerprintsExact" -> repeatFingerprintsExact,
        "TrialSealEvidenceValid" -> trialSealEvidenceValid,
        "TrialSealNoncesDistinct" -> trialSealNoncesDistinct,
        "TrialSealFingerprintsDistinct" ->
          trialSealFingerprintsDistinct|>, 81]];
    oracleAssemblyFingerprint = oracleAssembly["AssemblyFingerprint"];
    Clear[oracleAssembly, oracleSemanticAssembly];

    images = {
      <|"ImageID" -> "I00", "Prime" -> 10007,
        "EpsilonValue" -> 1/21|>,
      <|"ImageID" -> "I01", "Prime" -> 10007,
        "EpsilonValue" -> 1/11|>,
      <|"ImageID" -> "I10", "Prime" -> 10039,
        "EpsilonValue" -> 1/21|>,
      <|"ImageID" -> "I11", "Prime" -> 10039,
        "EpsilonValue" -> 1/11|>};
    imageResults = Table[Module[
      {prime, epsilonValue, seed, sampleSeconds, targetSample,
       screenPoints, targetScreenMatrix, targetScreenRight, baseSample,
       fullRank, coefficientCertificate, augmentedCertificate,
       acceptedPointsFingerprint, certificateExact},
      prime = image["Prime"];
      epsilonValue = image["EpsilonValue"];
      seed = Hash[{2026082335, "GaloisOrbitForcingV6",
        image["ImageID"], maxPreparation["ABIFingerprint"]}, "CRC32"];
      {sampleSeconds, targetSample} = AbsoluteTiming[
        CodexDirectRootChannelAssembler`DRCAAssembleSample[
          screenAssembly, epsilonValue, prime,
          "PointCount" -> pointCount,
          "MaximumAttempts" -> 40 pointCount,
          "RandomSeed" -> seed, "CandidatePoints" -> Automatic,
          "BranchFlipMask" -> 0]];
      If[Lookup[targetSample, "Status", None] =!=
            "AssembledDirectRootChannelSampleV1" ||
          targetSample["MatrixDimensions"] =!= {960, 912},
        finish["V6eFrozenImageSampleFailed", <|
          "Image" -> image,
          "SampleStatus" -> Lookup[targetSample, "Status", None]|>, 82]];
      acceptedPointsFingerprint = fingerprint[
        targetSample["AcceptedPoints"]];
      If[image["ImageID"] === "I00" &&
          acceptedPointsFingerprint =!= expectedI00AcceptedPointsFingerprint,
        finish["V6eI00AcceptedPointFingerprintMismatch", <|
          "Expected" -> expectedI00AcceptedPointsFingerprint,
          "Observed" -> acceptedPointsFingerprint|>, 82]];
      screenPoints = Take[targetSample["AcceptedPoints"], 21];
      targetScreenMatrix = Take[targetSample["Matrix"], 32 21];
      targetScreenRight = Take[targetSample["RightHandSide"], 32 21];
      baseSample =
        CodexDirectRootChannelAssembler`DRCAAssembleSample[
          baseAssembly, epsilonValue, prime,
          "PointCount" -> 21, "MaximumAttempts" -> 21,
          "RandomSeed" -> seed, "CandidatePoints" -> screenPoints,
          "BranchFlipMask" -> 0];
      If[Lookup[baseSample, "Status", None] =!=
            "AssembledDirectRootChannelSampleV1" ||
          baseSample["AcceptedPoints"] =!= screenPoints ||
          baseSample["MatrixDimensions"] =!= {672, 624} ||
          baseSample["RightHandSide"] =!= targetScreenRight ||
          Take[targetScreenMatrix, All, baseUnknownCount] =!=
            baseSample["Matrix"],
        finish["V6eFrozenImageBaseSubsetContainmentFailed", <|
          "Image" -> image|>, 82]];
      fullRank = rankImage[targetSample["Matrix"],
        targetSample["RightHandSide"], prime,
        "GaloisOrbitForcingV6", image["ImageID"]];
      coefficientCertificate = Lookup[fullRank,
        "CoefficientCertificate", <||>];
      augmentedCertificate = Lookup[fullRank,
        "AugmentedCertificate", <||>];
      certificateExact = TrueQ[
        Lookup[fullRank, "Status", None] ===
          "CertifiedAffineConsistencyByTwoStableRanksV1" &&
        ! TrueQ[Lookup[fullRank, "Consistent", True]] &&
        Lookup[fullRank, "CoefficientRank", -1] === 888 &&
        Lookup[fullRank, "AugmentedRank", -1] === 889 &&
        Lookup[fullRank, "CoefficientNullity", -1] === 24 &&
        Lookup[coefficientCertificate, "PivotFingerprint", None] ===
          expectedCoefficientPivotFingerprint &&
        Lookup[coefficientCertificate, "FreeColumnFingerprint", None] ===
          expectedCoefficientFreeFingerprint &&
        Lookup[coefficientCertificate, "RowWitnessFingerprint", None] ===
          expectedCoefficientIndependentRowFingerprint &&
        Lookup[augmentedCertificate, "PivotFingerprint", None] ===
          expectedAugmentedPivotFingerprint &&
        Lookup[augmentedCertificate, "FreeColumnFingerprint", None] ===
          expectedAugmentedFreeFingerprint &&
        Lookup[augmentedCertificate, "RowWitnessFingerprint", None] ===
          expectedAugmentedIndependentRowFingerprint];
      If[! certificateExact,
        finish["V6eFrozenImageRankCertificateMismatch", <|
          "Image" -> image, "FullRank" -> fullRank|>, 83]];
      Print["CF300_V6E_RUNTIME_GATE milestone=image_certified image=",
        image["ImageID"], " coefficient_rank=888 augmented_rank=889"];
      Join[image, <|
        "PointCount" -> pointCount,
        "AttemptCount" -> targetSample["AttemptCount"],
        "AcceptedPoints" -> targetSample["AcceptedPoints"],
        "AcceptedPointsFingerprint" -> acceptedPointsFingerprint,
        "SampleSeconds" -> sampleSeconds,
        "MatrixFingerprint" ->
          Hash[targetSample["Matrix"], "SHA256", "HexString"],
        "RightHandSideFingerprint" ->
          Hash[targetSample["RightHandSide"], "SHA256", "HexString"],
        "BaseColumnPrefixContainedExactly" -> True,
        "FullRank" -> fullRank,
        "FrozenRankCertificateExact" -> certificateExact|>]],
      {image, images}];
    crossImagePlanStable = TrueQ[
      AllTrue[imageResults,
        Lookup[#1, "FrozenRankCertificateExact", False] &] &&
      SameQ @@ Lookup[Lookup[
        Lookup[imageResults, "FullRank"],
        "CoefficientCertificate"], "PivotColumns"] &&
      SameQ @@ Lookup[Lookup[
        Lookup[imageResults, "FullRank"],
        "CoefficientCertificate"], "FreeColumns"] &&
      SameQ @@ Lookup[Lookup[
        Lookup[imageResults, "FullRank"],
        "CoefficientCertificate"], "IndependentEquationRows"] &&
      SameQ @@ Lookup[Lookup[
        Lookup[imageResults, "FullRank"],
        "AugmentedCertificate"], "PivotColumns"] &&
      SameQ @@ Lookup[Lookup[
        Lookup[imageResults, "FullRank"],
        "AugmentedCertificate"], "FreeColumns"] &&
      SameQ @@ Lookup[Lookup[
        Lookup[imageResults, "FullRank"],
        "AugmentedCertificate"], "IndependentEquationRows"]];
    If[! crossImagePlanStable,
      finish["V6eFrozenCrossImageStablePlanMismatch", <|
        "ImageResults" -> imageResults|>, 83]];

    liftPrerequisite = Missing["PrerequisiteCaptureNotRequested"];
    liftPrerequisiteOutputHash =
      Missing["PrerequisiteCaptureNotRequested"];
    liftPrerequisiteByteCount =
      Missing["PrerequisiteCaptureNotRequested"];
    liftPrerequisiteFileByteCount =
      Missing["PrerequisiteCaptureNotRequested"];
    liftPrerequisiteStatus = "PrerequisiteCaptureNotRequested";
    If[capturePrerequisiteQ,
    anchorImage = SelectFirst[imageResults,
      Lookup[#1, "ImageID", None] === "I00" &, $Failed];
    anchorResidues = Lookup[anchorImage, "AcceptedPoints", $Failed];
    anchorFullRank = Lookup[anchorImage, "FullRank", <||>];
    anchorCoefficient = Lookup[anchorFullRank,
      "CoefficientCertificate", <||>];
    anchorAugmented = Lookup[anchorFullRank,
      "AugmentedCertificate", <||>];
    liftPrime = 10007;
    liftDenominatorBound = Floor[Sqrt[liftPrime]];
    balancedRepresentative[value_Integer, prime_Integer] := Module[
      {residue = Mod[value, prime]},
      If[2 residue > prime, residue - prime, residue]];
    rationalCoordinateLift[residue_Integer, prime_Integer,
        bound_Integer] := Module[
      {candidates, best},
      candidates = Table[Module[{a, divisor, numerator, denominator},
        a = balancedRepresentative[residue denominatorCandidate, prime];
        divisor = GCD[Abs[a], denominatorCandidate];
        numerator = Quotient[a, divisor];
        denominator = Quotient[denominatorCandidate, divisor];
        <|"Numerator" -> numerator, "Denominator" -> denominator,
          "Height" -> Max[Abs[numerator], denominator],
          "SearchKey" -> {Max[Abs[numerator], denominator],
            Abs[numerator] + denominator, denominator, numerator}|>],
        {denominatorCandidate, Select[Range[bound],
          CoprimeQ[#1, prime] &]}];
      best = First[SortBy[candidates, Lookup[#1, "SearchKey"] &]];
      best];
    coordinateLiftRecords = Flatten[MapIndexed[
      Function[{point, pointIndex}, MapIndexed[
        Function[{residue, coordinateIndex}, Module[
          {lift, numerator, denominator, reduction},
          lift = rationalCoordinateLift[residue, liftPrime,
            liftDenominatorBound];
          numerator = lift["Numerator"];
          denominator = lift["Denominator"];
          reduction = Mod[numerator PowerMod[denominator, -1, liftPrime],
            liftPrime];
          <|"PointIndex" -> First[pointIndex],
            "CoordinateIndex" -> First[coordinateIndex],
            "Residue" -> residue, "Numerator" -> numerator,
            "Denominator" -> denominator,
            "Height" -> lift["Height"], "Reduction" -> reduction,
            "ReductionMatches" -> (reduction === residue),
            "SearchKey" -> lift["SearchKey"]|>]], point]],
        anchorResidues], 1];
    exactRationalPointLifts = Partition[
      (Rational[#1["Numerator"], #1["Denominator"]] & /@
        coordinateLiftRecords), 2];
    allDenominatorsInvertible = AllTrue[coordinateLiftRecords,
      CoprimeQ[#1["Denominator"], liftPrime] &];
    allReductionsExact = AllTrue[coordinateLiftRecords,
      TrueQ[#1["ReductionMatches"]] &];
    exactPointsDistinctOverQ = DuplicateFreeQ[exactRationalPointLifts];
    capturedPlanRevalidated = TrueQ[
      Lookup[anchorFullRank, "CoefficientRank", -1] === 888 &&
      Lookup[anchorFullRank, "AugmentedRank", -1] === 889 &&
      Lookup[anchorFullRank, "CoefficientNullity", -1] === 24 &&
      crossImagePlanStable];
    pointLiftCertificate = <|
      "Status" -> "CertifiedBalancedRationalPointLiftV1",
      "Prime" -> liftPrime,
      "SearchDenominatorBound" -> liftDenominatorBound,
      "TieBreak" ->
        "Lexicographic {Max[Abs[a],b],Abs[a]+b,b,a}",
      "ResidueFingerprint" -> fingerprint[anchorResidues],
      "LiftFingerprint" -> fingerprint[exactRationalPointLifts],
      "CoordinateRecords" -> coordinateLiftRecords,
      "AllDenominatorsInvertible" -> allDenominatorsInvertible,
      "AllReductionsExact" -> allReductionsExact,
      "ExactPointsDistinctOverQ" -> exactPointsDistinctOverQ,
      "AnchorLiftedPointsNonsingularModuloPrimeAtEpsilon" -> True,
      "CapturedPlanRevalidatedAtLiftedResidues" ->
        capturedPlanRevalidated|>;
    stablePlan = <|
      "MatrixDimensions" -> {960, 912},
      "CoefficientRank" -> 888, "AugmentedRank" -> 889,
      "CoefficientPivotColumns" -> anchorCoefficient["PivotColumns"],
      "CoefficientFreeColumns" -> anchorCoefficient["FreeColumns"],
      "CoefficientIndependentEquationRows" ->
        anchorCoefficient["IndependentEquationRows"],
      "AugmentedPivotColumns" -> anchorAugmented["PivotColumns"],
      "AugmentedFreeColumns" -> anchorAugmented["FreeColumns"],
      "AugmentedIndependentEquationRows" ->
        anchorAugmented["IndependentEquationRows"],
      "CoefficientPivotFingerprint" ->
        anchorCoefficient["PivotFingerprint"],
      "CoefficientFreeFingerprint" ->
        anchorCoefficient["FreeColumnFingerprint"],
      "CoefficientIndependentRowFingerprint" ->
        anchorCoefficient["RowWitnessFingerprint"],
      "AugmentedPivotFingerprint" ->
        anchorAugmented["PivotFingerprint"],
      "AugmentedFreeFingerprint" ->
        anchorAugmented["FreeColumnFingerprint"],
      "AugmentedIndependentRowFingerprint" ->
        anchorAugmented["RowWitnessFingerprint"]|>;
    anchorPlanRevalidation = <|
      "Status" -> "CF300V6dI00StablePlanRevalidatedV1",
      "Prime" -> liftPrime, "EpsilonValue" -> 1/21,
      "PlanArraysRevalidated" -> True,
      "FullResidualRevalidated" -> True,
      "MatrixDimensions" -> {960, 912},
      "CoefficientRank" -> 888, "AugmentedRank" -> 889,
      "CoefficientNullity" -> 24,
      "RecoveredPlanArrayFingerprints" -> KeyTake[stablePlan, {
        "CoefficientPivotFingerprint", "CoefficientFreeFingerprint",
        "CoefficientIndependentRowFingerprint",
        "AugmentedPivotFingerprint", "AugmentedFreeFingerprint",
        "AugmentedIndependentRowFingerprint"}],
      "AllFrozenFingerprintsExact" -> True,
      "CrossImagePlanFingerprintStable" -> crossImagePlanStable|>;
    liftPrerequisite = <|
      "Status" -> "CF300V6dExactLiftPrerequisiteV1",
      "SourceV6dArtifactFile" -> frozenV6dArtifactFile,
      "SourceV6dArtifactSHA256" -> expectedFrozenV6dArtifactHash,
      "OrbitCoreV6dSHA256" -> expectedHashes["OrbitCoreV6d"],
      "MaximalAssemblyFingerprint" ->
        expectedMaximalAssemblyFingerprint,
      "MaximalAssembly" -> screenAssembly,
      "AnchorImageID" -> "I00", "AnchorPrime" -> liftPrime,
      "AnchorEpsilonValue" -> 1/21,
      "AnchorAcceptedPointResidues" -> anchorResidues,
      "AnchorAcceptedPoints" -> anchorResidues,
      "AnchorAcceptedPointsFingerprint" ->
        expectedI00AcceptedPointsFingerprint,
      "ExactRationalPointLifts" -> exactRationalPointLifts,
      "PointLiftCertificate" -> pointLiftCertificate,
      "PointLiftConvention" ->
        "For each residue enumerate denominators 1..Floor[Sqrt[p]], form the balanced numerator, reduce by gcd, and minimize {height,L1,denominator,numerator}; preserve V6d I00 order",
      "StablePlan" -> stablePlan,
      "AnchorPlanRevalidation" -> anchorPlanRevalidation,
      "CapturePolicy" -> <|
        "ReproduceOriginalV6dSeedAndCandidateOrder" -> True,
        "CompareRecoveredPointFingerprintBeforeLift" -> True,
        "CompareAllPlanArrayFingerprintsBeforeLift" -> True,
        "RequireCrossImageFingerprintStability" -> True,
        "AllowPlanRediscoveryInExactDriver" -> False,
        "ConsumeV6dScoreColumnIndices" -> False,
        "ExactRationalPointsNonsingularOverQepsClaimed" -> False|>|>;
    liftRequirements = <|
      "Status" -> "CF300V6dExactLiftRequirementsV1",
      "SourceV6dArtifactSHA256" -> expectedFrozenV6dArtifactHash,
      "OrbitCoreV6dSHA256" -> expectedHashes["OrbitCoreV6d"],
      "MaximalAssemblyFingerprint" ->
        expectedMaximalAssemblyFingerprint,
      "MatrixDimensions" -> {960, 912},
      "CoefficientRank" -> 888, "AugmentedRank" -> 889,
      "AnchorImageID" -> "I00", "AnchorPrime" -> liftPrime,
      "AnchorEpsilonValue" -> 1/21, "PointCount" -> 30,
      "AnchorAcceptedPointsFingerprint" ->
        expectedI00AcceptedPointsFingerprint,
      "CoefficientPivotFingerprint" ->
        expectedCoefficientPivotFingerprint,
      "CoefficientFreeFingerprint" ->
        expectedCoefficientFreeFingerprint,
      "CoefficientIndependentRowFingerprint" ->
        expectedCoefficientIndependentRowFingerprint,
      "AugmentedPivotFingerprint" -> expectedAugmentedPivotFingerprint,
      "AugmentedFreeFingerprint" -> expectedAugmentedFreeFingerprint,
      "AugmentedIndependentRowFingerprint" ->
        expectedAugmentedIndependentRowFingerprint,
      "CrossImagePlanFingerprintStable" -> True|>;
    liftConsumerValidationMemoryBefore = MemoryInUse[];
    {liftConsumerValidationSeconds, liftPrerequisiteConsumerValid} =
      AbsoluteTiming[
        CodexCF300ExactQepsLeftObstruction`EQWPrerequisiteValidQ[
          liftPrerequisite, liftRequirements]];
    liftConsumerValidationMemoryAfter = MemoryInUse[];
    liftPrerequisiteValid = TrueQ[
      AssociationQ[screenAssembly] &&
      screenAssembly["AssemblyFingerprint"] ===
        expectedMaximalAssemblyFingerprint &&
      MatchQ[anchorResidues, {{_Integer, _Integer} ..}] &&
      Length[anchorResidues] === 30 && DuplicateFreeQ[anchorResidues] &&
      fingerprint[anchorResidues] === expectedI00AcceptedPointsFingerprint &&
      MatchQ[exactRationalPointLifts,
        {{_Integer | _Rational, _Integer | _Rational} ..}] &&
      Length[exactRationalPointLifts] === 30 &&
      Length[coordinateLiftRecords] === 60 &&
      allDenominatorsInvertible && allReductionsExact &&
      exactPointsDistinctOverQ && capturedPlanRevalidated &&
      liftPrerequisiteConsumerValid &&
      FreeQ[liftPrerequisite, $Failed | _Missing] && stableInputsQ[]];
    If[! liftPrerequisiteValid,
      finish["CF300V6dExactLiftPrerequisiteCaptureInvalid", <|
        "PointLiftCertificate" -> pointLiftCertificate,
        "AnchorPlanRevalidation" -> anchorPlanRevalidation,
        "ConsumerValidatorPassed" ->
          liftPrerequisiteConsumerValid|>, 84]];
    liftPrerequisiteByteCount = ByteCount[liftPrerequisite];
    If[writeAtomicTo[liftPrerequisite,
          liftPrerequisiteOutputFile] === $Failed,
      finish["CF300V6dExactLiftPrerequisiteAtomicWriteFailed", <|
        "PrerequisiteOutput" -> liftPrerequisiteOutputFile|>, 98]];
    If[! stableInputsQ[],
      prerequisiteRollbackPassed = deleteIfPresent[
        liftPrerequisiteOutputFile];
      finish["SourceChangedAfterLiftPrerequisiteWrite", <|
        "PrerequisiteRollbackPassed" ->
          prerequisiteRollbackPassed|>, 95]];
    liftPrerequisiteOutputHash = FileHash[liftPrerequisiteOutputFile,
      "SHA256", "HexString"];
    liftPrerequisiteFileByteCount = FileByteCount[
      liftPrerequisiteOutputFile];
    liftPrerequisiteStatus = liftPrerequisite["Status"]];

    finalStatus = If[performanceAcceptancePassed,
      "CF300Sector12V6eCorrectnessSameInputBenchmarkPassedXH",
      "CF300Sector12V6eCorrectButPerformanceAcceptanceNotMetXH"];
    finish[finalStatus, <|
      "PreparationFile" -> preparationFile,
      "PreparationSHA256" -> expectedPreparationHash,
      "CacheFile" -> cacheFile,
      "CacheSHA256" -> expectedCacheHash,
      "FrozenV6dArtifactFile" -> frozenV6dArtifactFile,
      "FrozenV6dArtifactSHA256" -> If[capturePrerequisiteQ,
        expectedFrozenV6dArtifactHash,
        Missing["PrerequisiteCaptureNotRequested"]],
      "SourceHashes" -> sourceHashesBefore,
      "DriverSHA256" -> driverHashBefore,
      "ExpectedDispatchKernelID" -> expectedDispatchKernelID,
      "DispatchKernelID" -> actualDispatchKernelID,
      "TaskBrokerMaxHelpers" -> taskBrokerMaxHelpers,
      "OuterPoolKernelCount" -> outerPoolKernelCount,
      "NestedKernelCount" -> Length[nestedKernelsAtEntry],
      "NestedKernelsAtEntry" -> nestedKernelsAtEntry,
      "HydrationDiagnostics" -> hydrationDiagnostics,
      "CensusSeconds" -> censusSeconds,
      "CensusMemory" -> <|"BeforeBytes" -> censusMemoryBefore,
        "AfterBytes" -> censusMemoryAfter,
        "DeltaBytes" -> censusMemoryAfter - censusMemoryBefore|>,
      "OrbitCounts" -> <|
        "PotentialOccurrenceCount" -> potentialOccurrenceCount,
        "PotentialSourceCount" -> potentialSourceCount,
        "PotentialAliasCount" -> potentialAliasCount,
        "ConjugateCandidateCount" -> conjugateCandidateCount,
        "ForcingLetterCount" -> Length[forcingLetterRecords],
        "AdditionalLetterCount" -> additionalLetterCount|>,
      "ImmutableInputFingerprint" -> immutableInputFingerprint,
      "FrozenV6CorrectnessOracle" -> <|
        "Seconds" -> oracleSeconds,
        "OuterMemory" -> <|"BeforeBytes" -> oracleMemoryBefore,
          "AfterBytes" -> oracleMemoryAfter,
          "DeltaBytes" -> oracleMemoryAfter - oracleMemoryBefore|>,
        "AssemblyFingerprint" ->
          oracleAssemblyFingerprint,
        "Diagnostics" -> oracleDiagnostics|>,
      "Trial1" -> trial1, "Trial2" -> trial2,
      "RepeatFingerprintsExact" -> repeatFingerprintsExact,
      "TrialSealEvidenceValid" -> trialSealEvidenceValid,
      "TrialSealNoncesDistinct" -> trialSealNoncesDistinct,
      "TrialSealFingerprintsDistinct" ->
        trialSealFingerprintsDistinct,
      "V6eTrialSeconds" -> trialSeconds,
      "V6eMedianSeconds" -> medianV6eSeconds,
      "FrozenV6dRebindSeconds" -> frozenV6dRebindSeconds,
      "ObservedSpeedupFactor" ->
        N[frozenV6dRebindSeconds/medianV6eSeconds],
      "PerformanceAcceptancePassed" -> performanceAcceptancePassed,
      "FiniteFieldImages" -> images,
      "FiniteFieldImageResults" -> imageResults,
      "AllFourFrozenImageCertificatesExact" -> True,
      "CrossImageStablePlanExact" -> crossImagePlanStable,
      "PrerequisiteCaptureRequested" -> capturePrerequisiteQ,
      "LiftPrerequisiteOutputFile" -> liftPrerequisiteOutputFile,
      "LiftPrerequisiteOutputSHA256" -> liftPrerequisiteOutputHash,
      "LiftPrerequisiteStatus" -> liftPrerequisiteStatus,
      "LiftPrerequisiteByteCount" -> liftPrerequisiteByteCount,
      "LiftPrerequisiteFileByteCount" ->
        liftPrerequisiteFileByteCount,
      "MaximumAtomicOutputBytes" -> maximumAtomicOutputBytes,
      "LiftPrerequisiteConsumerValidation" ->
        If[capturePrerequisiteQ, <|
          "Passed" -> liftPrerequisiteConsumerValid,
          "Seconds" -> liftConsumerValidationSeconds,
          "MemoryBeforeBytes" -> liftConsumerValidationMemoryBefore,
          "MemoryAfterBytes" -> liftConsumerValidationMemoryAfter,
          "MemoryDeltaBytes" ->
            liftConsumerValidationMemoryAfter -
              liftConsumerValidationMemoryBefore|>,
          Missing["PrerequisiteCaptureNotRequested"]],
      "Qualification" -> If[capturePrerequisiteQ,
        "Exact-rebind correctness, two same-input timings, all four frozen finite-field image/rank certificates, and the exact-Q(eps) lift prerequisite capture are included.",
        "Exact-rebind correctness, two same-input timings, and all four frozen finite-field image/rank certificates are included; prerequisite capture was not requested."]|>,
      If[performanceAcceptancePassed, 0, 3]]
    ], exitTag],
  artifactNamesBeforeCleanup = System`Names[artifactPattern];
  artifactNamespaceBeforeCleanupAudit = artifactNamespaceAudit[
    artifactNamesBeforeCleanup];
  artifactDefinitionsBeforeCleanup = artifactDefinitionStates[
    artifactNamesBeforeCleanup];
  artifactCleanupPreconditionsPassed = TrueQ[
    artifactNamespaceBeforeCleanupAudit["ExactOwnedNamespaceQ"] &&
    AllTrue[Values[artifactDefinitionsBeforeCleanup],
      definitionFreeStateQ]];
  If[artifactCleanupPreconditionsPassed,
    Scan[removeQualifiedSymbolName,
      artifactNamespaceBeforeCleanupAudit["QualifiedNames"]]];
  scopeCleanupPassed = TrueQ[
    artifactCleanupPreconditionsPassed &&
    System`Names[artifactPattern] === {} &&
    SameQ[$Context, callerContextBefore] &&
    SameQ[$ContextPath, callerContextPathBefore]];
  exitScopeActive = False];

If[! TrueQ[scopeCleanupPassed],
  outputRollbackPassed = deleteIfPresent[outputFile];
  prerequisiteRollbackPassed = If[StringQ[liftPrerequisiteOutputFile],
    deleteIfPresent[liftPrerequisiteOutputFile], True];
  Print["CF300_V6E_RUNTIME_GATE FAIL artifact scope cleanup",
    " output_rollback=", outputRollbackPassed,
    " prerequisite_rollback=", prerequisiteRollbackPassed];
  systemExit[97]];
If[AssociationQ[scopeOutcome] &&
    Lookup[scopeOutcome, "Status", None] ===
      "CF300V6eRuntimeGateExitRequested" &&
    IntegerQ[Lookup[scopeOutcome, "Code", $Failed]],
  systemExit[scopeOutcome["Code"]]];
Print["CF300_V6E_RUNTIME_GATE FAIL unexpected scope outcome=",
  InputForm[scopeOutcome]];
systemExit[97];
