#!/usr/bin/env wolframscript

$HistoryLength = 0;
(* V6a supersedes frozen V6 driver SHA e6d0dd17378d3e7662f5926abaa97a6feef370bf6cb24b1ba26534c2e2385ba3. *)
BeginPackage["CodexCF300GaloisOrbitForcingDriverV6a`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300GaloisOrbitForcingDriverV6a`Private`*"]];

cf300GaloisOrbitDriverV6aSystemExit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);
driverExitScopeActive = False;
driverExitTag =
  "CF300GaloisOrbitDriverV6aExit-" <> CreateUUID[];
cf300GaloisOrbitDriverV6aExit[code_Integer] := If[
  TrueQ[driverExitScopeActive],
  Throw[<|"Status" -> "CF300GaloisOrbitDriverExitRequestedV6a",
    "Code" -> code|>, driverExitTag],
  cf300GaloisOrbitDriverV6aSystemExit[code]];

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{4, 5}, Length[arguments]],
  Print["CF300_GALOIS_ORBIT FAIL usage=<project-root> <preparation.wl> " <>
    "<compiled-cache.wl> <output.wl> [native-threads]"];
  cf300GaloisOrbitDriverV6aExit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
outputFile = ExpandFileName[arguments[[4]]];
nativeThreads = If[Length[arguments] === 5,
  Quiet[Check[ToExpression[arguments[[5]]], $Failed]], 1];
driverDirectory = DirectoryName[$InputFileName];
v6Directory = driverDirectory;
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
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
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
  "WitnessHelper" -> FileNameJoin[{supportDirectory,
    "AffineInconsistencyWitness.wl"}],
  "OrbitCoreV6" -> FileNameJoin[{v6Directory,
    "GaloisChannelOrbitCoreV6.wl"}],
  "ExactChannelRebindV6" -> FileNameJoin[{v6Directory,
    "DirectRootChannelExactOneFormRebindV6.wl"}],
  "NativeBinary" -> FileNameJoin[{nativeDirectory, "bin",
    "flint_affine_rref"}]|>;
expectedHashes = <|
  "LoadFACET" ->
    "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164",
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
  "WitnessHelper" ->
    "6d2ea56523cbee20c71efc265150ebd001d701421cac08dc69bb77296dafe79f",
  "OrbitCoreV6" ->
    "e7546be3b222581594fa2e57c6f22f2c891a27d21fd0a02c819ce732ad1f9942",
  "ExactChannelRebindV6" ->
    "2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44",
  "NativeBinary" ->
    "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5"|>;
expectedPreparationHash =
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedExactChannelFormsFingerprint =
  "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d";
expectedCompiledFormsFingerprint =
  "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7";

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
SetAttributes[symbolDefinitionFingerprint, HoldFirst];
symbolDefinitionFingerprint[symbol_] := fingerprint[{
  OwnValues[symbol], DownValues[symbol], UpValues[symbol],
  SubValues[symbol], Attributes[symbol]}];
SetAttributes[symbolDefinitionSummary, HoldFirst];
symbolDefinitionSummary[symbol_] := <|
  "OwnValueCount" -> Length[OwnValues[symbol]],
  "DownValueCount" -> Length[DownValues[symbol]],
  "UpValueCount" -> Length[UpValues[symbol]],
  "SubValueCount" -> Length[SubValues[symbol]],
  "Attributes" -> Attributes[symbol]|>;
SetAttributes[symbolDefinitionState, HoldFirst];
symbolDefinitionState[symbol_] := <|
  "OwnValues" -> OwnValues[symbol],
  "DownValues" -> DownValues[symbol],
  "UpValues" -> UpValues[symbol],
  "SubValues" -> SubValues[symbol],
  "NValues" -> NValues[symbol],
  "DefaultValues" -> DefaultValues[symbol],
  "FormatValues" -> FormatValues[symbol],
  "Attributes" -> Attributes[symbol]|>;
definitionComponents = {"OwnValues", "DownValues", "UpValues",
  "SubValues", "NValues", "DefaultValues", "FormatValues",
  "Attributes"};
zeroQ[value_] := AllTrue[Flatten[{value}],
  TrueQ[Together[#1] === 0] &];
artifactRead[file_String] := If[! FileExistsQ[file], $Failed,
  Quiet[CheckAbort[Get[file], $Aborted]]];
loadSource[file_String] := Module[{value},
  value = Quiet[CheckAbort[Get[file], $Aborted]];
  <|"Status" -> Which[value === $Aborted, "Aborted",
      value === $Failed, "Failed", True, "Loaded"],
    "ReturnHead" -> ToString[Head[value], InputForm]|>
];
stableInputsQ[] := TrueQ[
  hashes[] === sourceHashesBefore &&
  FileHash[preparationFile, "SHA256", "HexString"] ===
    expectedPreparationHash &&
  FileHash[cacheFile, "SHA256", "HexString"] === expectedCacheHash &&
  FileHash[$InputFileName, "SHA256", "HexString"] === driverHashBefore];
deleteIfPresent[file_String] := Module[{},
  If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
  ! FileExistsQ[file]
];
writeAtomic[value_] := Module[{temporary, written, renamed, reread},
  If[FileExistsQ[outputFile], Return[$Failed]];
  temporary = outputFile <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary],
    deleteIfPresent[temporary]; Return[$Failed]];
  reread = Quiet[Check[Get[outputFile], $Failed]];
  If[! SameQ[reread, value],
    deleteIfPresent[outputFile]; Return[$Failed]];
  outputFile
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|"Status" -> status|>, data];
  If[writeAtomic[result] === $Failed,
    Print["CF300_GALOIS_ORBIT FAIL atomic output race output=",
      outputFile]; cf300GaloisOrbitDriverV6aExit[98]];
  Print["CF300_GALOIS_ORBIT status=", status,
    " output=", outputFile];
  cf300GaloisOrbitDriverV6aExit[code]
];
makeNonce[parts___] := Module[{nonce},
  nonce = Mod[Hash[{driverHashBefore, parts, #1}, "SHA256"], 2^64] & /@
    {"hi", "lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]
];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]] ||
    ! IntegerQ[nativeThreads] || ! (1 <= nativeThreads <= 8),
  Print["CF300_GALOIS_ORBIT FAIL invalid inputs, stale output, or threads"];
  cf300GaloisOrbitDriverV6aExit[65]];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
If[sourceHashesBefore =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash,
  Print["CF300_GALOIS_ORBIT FAIL pinned source or artifact mismatch"];
  cf300GaloisOrbitDriverV6aExit[66]];

loadSourceNames = {"TripleRootAlgebra", "TripleRootStripAdapter",
  "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
  "Assembler", "ArtifactHelper", "AnsatzRebind", "NativeAdapter",
  "WitnessHelper", "OrbitCoreV6", "ExactChannelRebindV6"};
loadOutcomes = AssociationMap[loadSource[files[#1]] &, loadSourceNames];
If[! AllTrue[Lookup[Values[loadOutcomes], "Status", None],
      #1 === "Loaded" &] || ! stableInputsQ[],
  Print["CF300_GALOIS_ORBIT FAIL pinned load failed outcomes=",
    InputForm[loadOutcomes]];
  cf300GaloisOrbitDriverV6aExit[67]];

artifactContext = "CodexCF300GaloisOrbitArtifactV6a`";
artifactContextPattern = "CodexCF300GaloisOrbitArtifactV6a`*";
artifactNamesBeforeCreation = Names[artifactContextPattern];
If[artifactNamesBeforeCreation =!= {},
  Print["CF300_GALOIS_ORBIT FAIL dedicated artifact context not fresh"];
  cf300GaloisOrbitDriverV6aExit[67]];
artifactSymbolHolds = ToExpression[
    artifactContext <> #1, InputForm, HoldComplete] & /@
  {"v", "w", "x", "y", "eps"};
expectedArtifactSymbolNames = {"v", "w", "x", "y", "eps"};
artifactNamesBeforeHydration = Names[artifactContextPattern];

SetAttributes[symbolDefinitionStateByNameHeld, HoldAll];
symbolDefinitionStateByNameHeld[symbol_] := symbolDefinitionState[symbol];
artifactQualifiedName[name_String] := If[StringContainsQ[name, "`"],
  name, artifactContext <> name];
symbolDefinitionStateByName[name_String] := ToExpression[
  artifactQualifiedName[name], InputForm,
  Function[heldSymbol, symbolDefinitionStateByNameHeld[heldSymbol],
    HoldAll]];
SetAttributes[artifactSymbolIdentityHeld, HoldAll];
artifactSymbolIdentityHeld[symbol_Symbol] := <|
  "Context" -> Context[symbol],
  "SymbolName" -> SymbolName[symbol],
  "FullName" -> Context[symbol] <> SymbolName[symbol]|>;
artifactSymbolIdentityHeld[___] := $Failed;
artifactSymbolIdentityByName[name_String] := ToExpression[
  artifactQualifiedName[name], InputForm,
  Function[heldSymbol, artifactSymbolIdentityHeld[heldSymbol],
    HoldAll]];
artifactNamespaceAudit[names_List] := Module[
  {qualifiedNames, identities, identityValues, exactQ},
  qualifiedNames = artifactQualifiedName /@ names;
  identities = AssociationMap[artifactSymbolIdentityByName,
    qualifiedNames];
  identityValues = Values[identities];
  exactQ = TrueQ[
    DuplicateFreeQ[qualifiedNames] &&
    Length[qualifiedNames] === Length[expectedArtifactSymbolNames] &&
    FreeQ[identityValues, $Failed] &&
    AllTrue[Lookup[identityValues, "Context", $Failed],
      #1 === artifactContext &] &&
    Sort[Lookup[identityValues, "SymbolName", $Failed]] ===
      Sort[expectedArtifactSymbolNames] &&
    Sort[Lookup[identityValues, "FullName", $Failed]] === Sort[
      artifactContext <> #1 & /@ expectedArtifactSymbolNames]];
  <|"RawNames" -> names, "QualifiedNames" -> qualifiedNames,
    "Identities" -> identities, "ExactOwnedNamespaceQ" -> exactQ|>];
definitionFreeStateQ[state_Association] := TrueQ[
  Lookup[state, definitionComponents, $Failed] ===
    ConstantArray[{}, Length[definitionComponents]]];
definitionFreeStateQ[___] := False;
artifactDefinitionStatesFromNames[names_List] := AssociationMap[
  symbolDefinitionStateByName,
  DeleteDuplicates[artifactQualifiedName /@ names]];
artifactDefinitionStates[] := artifactDefinitionStatesFromNames[
  Names[artifactContextPattern]];
artifactNamespaceBeforeHydrationAudit = artifactNamespaceAudit[
  artifactNamesBeforeHydration];
artifactDefinitionsBeforeHydration = artifactDefinitionStates[];

dedicatedArtifactRuntimeContextPath = {
  artifactContext,
  "CodexDirectRootChannelCompiledArtifact`",
  "CodexDirectRootChannelAssembler`",
  "CodexDirectRootChannelAnsatzRebind`",
  "CodexAffineInconsistencyWitness`",
  "CodexFLINTAffineRREFAdapter`",
  "CodexCF300GaloisChannelOrbitV6`",
  "CodexDirectRootChannelExactOneFormRebindV6`",
  "CodexTripleRootReconstruction`", "CodexTripleRootPilot`",
  "CodexTripleRootStrip`", "CodexTripleRoot`",
  "System`", "CodexCF300GaloisOrbitForcingDriverV6a`"};

(* The held body was parsed in the driver's private package context.  Only
   artifact Get calls parse unqualified v/w/x/y/eps dynamically.  They are born
   in the fresh dedicated context, which stays explicitly visible for every
   public reader, validator, fingerprint, rebind and sampler call.  Global`
   is deliberately absent from the runtime context path. *)
artifactDefinitionsAfterScope = Missing["ScopeNotCompleted"];
artifactSymbolsDefinitionFreeAfterScope = False;
artifactNamespaceAfterScopeAudit = Missing["ScopeNotCompleted"];
artifactNamespaceExactAfterScope = False;
artifactContextRemovalAttempted = False;
artifactContextRemovedAfterScope = False;
callerContextBeforeScope = $Context;
callerContextPathBeforeScope = $ContextPath;
callerContextRestoredAfterScope = False;
scopeOutcome = Internal`WithLocalSettings[
  driverExitScopeActive = True,
  Catch[
    Block[{$Context = artifactContext,
      $ContextPath = dedicatedArtifactRuntimeContextPath},

preparationArtifact = artifactRead[preparationFile];
rawCacheArtifact = artifactRead[cacheFile];
hydratedPreparation = If[AssociationQ[preparationArtifact],
  Lookup[preparationArtifact, "Preparation", $Failed], $Failed];
rawAssembly = If[AssociationQ[rawCacheArtifact],
  Lookup[rawCacheArtifact, "DirectAssembly", $Failed], $Failed];
exactForms = If[AssociationQ[rawAssembly],
  Lookup[rawAssembly, "ExactChannelForms", $Failed], $Failed];
compiledForms = If[AssociationQ[rawAssembly],
  Lookup[rawAssembly, "CompiledForms", $Failed], $Failed];
storedExactFingerprint = If[AssociationQ[rawAssembly],
  Lookup[rawAssembly, "ExactChannelFormsFingerprint", $Failed],
  $Failed];
storedCompiledFingerprint = If[AssociationQ[rawAssembly],
  Lookup[rawAssembly, "CompiledFormsFingerprint", $Failed],
  $Failed];
canonicalExactFingerprint = If[exactForms === $Failed,
  $Failed, fingerprint[exactForms]];
canonicalCompiledFingerprint = If[compiledForms === $Failed,
  $Failed, fingerprint[compiledForms]];
artifactNamesAfterHydration = Names[artifactContextPattern];
artifactNamespaceAfterHydrationAudit = artifactNamespaceAudit[
  artifactNamesAfterHydration];
artifactDefinitionsAfterHydration =
  artifactDefinitionStatesFromNames[artifactNamesAfterHydration];
hydratedVariables = If[AssociationQ[hydratedPreparation],
  Lookup[hydratedPreparation, "Variables", $Failed], $Failed];
hydratedRegulator = If[AssociationQ[hydratedPreparation],
  Lookup[hydratedPreparation, "Regulator", $Failed], $Failed];
hydrationDiagnostics = <|
  "Status" -> "CF300GaloisOrbitDedicatedContextHydrationV6a",
  "RuntimeContext" -> $Context,
  "RuntimeContextPath" -> $ContextPath,
  "DedicatedArtifactContext" -> artifactContext,
  "GlobalContextPresentInRuntimePath" ->
    MemberQ[$ContextPath, "Global`"],
  "PublicReaderIntentionallyNotCalled" -> True,
  "PublicReaderExclusionReason" ->
    "DRCAReadCompiledArtifact hardcodes Global context hydration",
  "ArtifactNamesBeforeCreation" -> artifactNamesBeforeCreation,
  "ArtifactNamesBeforeHydration" -> artifactNamesBeforeHydration,
  "ArtifactNamespaceBeforeHydrationAudit" ->
    artifactNamespaceBeforeHydrationAudit,
  "ArtifactDefinitionsBeforeHydration" ->
    artifactDefinitionsBeforeHydration,
  "ArtifactNamesAfterHydration" -> artifactNamesAfterHydration,
  "ArtifactNamespaceAfterHydrationAudit" ->
    artifactNamespaceAfterHydrationAudit,
  "ArtifactDefinitionsAfterHydration" ->
    artifactDefinitionsAfterHydration,
  "DedicatedArtifactNamespaceBeforeHydrationExact" -> TrueQ[
    artifactNamespaceBeforeHydrationAudit["ExactOwnedNamespaceQ"]],
  "DedicatedArtifactNamespaceAfterHydrationExact" -> TrueQ[
    artifactNamespaceAfterHydrationAudit["ExactOwnedNamespaceQ"]],
  "DedicatedArtifactSymbolsDefinitionFree" ->
    AllTrue[Join[Values[artifactDefinitionsBeforeHydration],
      Values[artifactDefinitionsAfterHydration]], definitionFreeStateQ],
  "PreparationAssociationQ" -> AssociationQ[preparationArtifact],
  "PreparationStatus" -> If[AssociationQ[preparationArtifact],
    Lookup[preparationArtifact, "Status", Missing["Absent"]], $Failed],
  "PreparationValueValidatorDedicatedContext" -> If[
    AssociationQ[hydratedPreparation],
    CodexTripleRootReconstruction`TRPreparationABIValidQ[
      hydratedPreparation], False],
  "PreparationVariableNames" -> If[ListQ[hydratedVariables],
    SymbolName /@ hydratedVariables, $Failed],
  "PreparationVariableContexts" -> If[ListQ[hydratedVariables],
    Context /@ hydratedVariables, $Failed],
  "PreparationRegulatorName" -> If[MatchQ[hydratedRegulator, _Symbol],
    SymbolName[hydratedRegulator], $Failed],
  "PreparationRegulatorContext" -> If[
    MatchQ[hydratedRegulator, _Symbol],
    Context[Evaluate[hydratedRegulator]],
    $Failed],
  "RawCacheAssociationQ" -> AssociationQ[rawCacheArtifact],
  "RawCacheStatus" -> If[AssociationQ[rawCacheArtifact],
    Lookup[rawCacheArtifact, "Status", Missing["Absent"]], $Failed],
  "RawCacheValueValidatorDedicatedContext" -> If[
    AssociationQ[rawCacheArtifact],
    CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
      rawCacheArtifact], False],
  "RawAssemblyValueValidatorDedicatedContext" -> If[
    AssociationQ[rawAssembly],
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      rawAssembly], False],
  "StoredExactChannelFormsFingerprint" -> storedExactFingerprint,
  "DedicatedContextExactChannelFormsFingerprint" ->
    canonicalExactFingerprint,
  "ExpectedExactChannelFormsFingerprint" ->
    expectedExactChannelFormsFingerprint,
  "ExactFingerprintValueMatch" -> TrueQ[
    storedExactFingerprint === canonicalExactFingerprint ===
      expectedExactChannelFormsFingerprint],
  "StoredCompiledFormsFingerprint" -> storedCompiledFingerprint,
  "DedicatedContextCompiledFormsFingerprint" ->
    canonicalCompiledFingerprint,
  "ExpectedCompiledFormsFingerprint" ->
    expectedCompiledFormsFingerprint,
  "CompiledFingerprintValueMatch" -> TrueQ[
    storedCompiledFingerprint === canonicalCompiledFingerprint ===
      expectedCompiledFormsFingerprint]|>;
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    ! AssociationQ[rawCacheArtifact] ||
    Lookup[rawCacheArtifact, "Status", None] =!=
      "DirectRootChannelCompiledArtifactV1" ||
    ! And @@ Lookup[hydrationDiagnostics, {
      "DedicatedArtifactNamespaceBeforeHydrationExact",
      "DedicatedArtifactNamespaceAfterHydrationExact",
      "DedicatedArtifactSymbolsDefinitionFree",
      "PreparationValueValidatorDedicatedContext",
      "RawCacheValueValidatorDedicatedContext",
      "RawAssemblyValueValidatorDedicatedContext",
      "PublicReaderIntentionallyNotCalled",
      "ExactFingerprintValueMatch",
      "CompiledFingerprintValueMatch"}, False] ||
    TrueQ[Lookup[hydrationDiagnostics,
      "GlobalContextPresentInRuntimePath", True]] ||
    Lookup[hydrationDiagnostics, "PreparationVariableNames", $Failed] =!=
      {"x", "y"} ||
    Lookup[hydrationDiagnostics, "PreparationVariableContexts", $Failed] =!=
      {artifactContext, artifactContext} ||
    Lookup[hydrationDiagnostics, "PreparationRegulatorName", $Failed] =!=
      "eps" ||
    Lookup[hydrationDiagnostics, "PreparationRegulatorContext", $Failed] =!=
      artifactContext,
  finish["PinnedArtifactsOrDedicatedContextHydrationInvalid", <|
    "HydrationDiagnostics" -> hydrationDiagnostics|>, 68]];
Clear[exactForms, compiledForms];
basePreparation = preparationArtifact["Preparation"];
baseAssembly = rawCacheArtifact["DirectAssembly"];
If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      basePreparation] ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      baseAssembly] ||
    baseAssembly["SourceABIFingerprint"] =!=
      basePreparation["ABIFingerprint"],
  finish["BaseABIInvalid", <||>, 69]];

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
  finish["PhysicalDimensionOrMetadataContractInvalid", <|
    "ObservedOneFormMetadata" -> baseMetadata,
    "ObservedForcingDimensions" -> Dimensions[forcingPair]|>, 70]];

{censusSeconds, orbitBuild} = AbsoluteTiming[
  CodexCF300GaloisChannelOrbitV6`GCOBuildOrbitBasis[
    basePreparation, baseAssembly,
    "EpsilonSamples" -> epsilonSamples,
    "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9]];
If[Lookup[orbitBuild, "Status", None] =!=
    "ExactGaloisChannelOrbitBasisV6",
  finish["GaloisChannelOrbitBasisBuildFailed", <|
    "CensusSeconds" -> censusSeconds,
    "OrbitBuildFailure" -> orbitBuild|>, 72]];
potentialSourceCount = orbitBuild["PotentialSourceCount"];
conjugateCandidateCount = orbitBuild["ConjugateCandidateCount"];
forcingLetterRecords = orbitBuild["ForcingLetterRecords"];
additionalLetterCount = orbitBuild["AdditionalLetterCount"];
additionalOneFormChannels = orbitBuild["AdditionalOneFormChannels"];
maxOneForms = orbitBuild["MaxOneForms"];
sourceOrbitRecords = orbitBuild["SourceOrbitRecords"];
orbitClosureExact = orbitBuild["OrbitClosureExact"];
orbitPerformanceCounters = orbitBuild["PerformanceCounters"];
characterCertificates = orbitBuild["CharacterCertificates"];
If[potentialSourceCount =!= 28 ||
    conjugateCandidateCount =!= 112 ||
    Length[forcingLetterRecords] > 112 || Length[maxOneForms] > 120 ||
    additionalLetterCount > 84 ||
    ! TrueQ[orbitClosureExact] ||
    ! And @@ Lookup[characterCertificates, {
      "InvolutionExact", "XorCompositionExact",
      "FieldMultiplicationEquivarianceExact",
      "GradeDiagonalDerivativeEquivarianceExact"}, False] ||
    Lookup[orbitPerformanceCounters,
      "LegacyAlgebraicFieldDecomposeCallsInCensus", -1] =!= 0 ||
    Lookup[orbitPerformanceCounters,
      "LegacyAlgebraicRootBranchSubstitutionsInCensus", -1] =!= 0,
  finish["GaloisChannelOrbitBasisPostconditionFailed", <|
    "CensusSeconds" -> censusSeconds,
    "PerformanceCounters" -> orbitPerformanceCounters,
    "CharacterCertificates" -> characterCertificates|>, 73]];
Print["CF300_GALOIS_ORBIT milestone=channel_orbit_ready census_s=",
  censusSeconds, " sources=", potentialSourceCount,
  " distinct_source_cores=",
    orbitPerformanceCounters["DistinctPotentialCoreCount"],
  " candidates=", conjugateCandidateCount,
  " forcing_letters=", Length[forcingLetterRecords],
  " appended=", additionalLetterCount,
  " unique_compositions=",
    orbitPerformanceCounters["UniqueOneFormCompositionCount"]];

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
    "Status" -> "CF300GaloisOrbitClosedForcingBasisV6a",
    "BaseOneFormCount" -> Length[baseOneForms],
    "PotentialSourceCount" -> potentialSourceCount,
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

{rebindSeconds, maxAssembly} = AbsoluteTiming[
  CodexDirectRootChannelExactOneFormRebindV6`
    DRCARebindExactOneFormChannels[
      baseAssembly, maxPreparation, additionalOneFormChannels]];
exactRebindDiagnostics = Lookup[maxAssembly,
  "ExactOneFormChannelRebindV6", <||>];
If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      maxAssembly] ||
    maxAssembly["SourceABIFingerprint"] =!=
      maxPreparation["ABIFingerprint"] ||
    Take[maxAssembly["OneForms"], Length[baseOneForms]] =!=
      baseOneForms ||
    Lookup[exactRebindDiagnostics, "Status", None] =!=
      "ExactOneFormChannelRebindV6" ||
    Lookup[exactRebindDiagnostics,
      "AppendedOneFormCount", -1] =!= additionalLetterCount ||
    Lookup[exactRebindDiagnostics,
      "AlgebraicFieldDecompositionCalls", -1] =!= 0 ||
    Lookup[exactRebindDiagnostics,
      "AlgebraicRootBranchSubstitutions", -1] =!= 0,
  finish["MaximalOrbitExactChannelRebindInvalid", <|
    "RebindStatus" -> Lookup[maxAssembly, "Status", None],
    "ExactRebindDiagnostics" -> exactRebindDiagnostics,
    "RebindSeconds" -> rebindSeconds|>, 79]];

residueColumnsPerLetter = upper lower;
baseOneFormsArePrefixExact = TrueQ[
  Take[maxAssembly["OneForms"], Length[baseOneForms]] ===
    baseOneForms];
gaugeColumnsUnchangedExact = TrueQ[
  maxAssembly["GaugeSupport"] === baseAssembly["GaugeSupport"] &&
  maxAssembly["GaugeUnknownCount"] ===
    baseAssembly["GaugeUnknownCount"] &&
  maxAssembly["ColumnOrder", "Gauge"] ===
    baseAssembly["ColumnOrder", "Gauge"] &&
  Lookup[exactRebindDiagnostics,
    "EquationCorePreservedExactly", False]];
appendedOnlyResidueColumnStructureExact = TrueQ[
  IntegerQ[residueColumnsPerLetter] &&
  residueColumnsPerLetter === upper lower &&
  baseOneFormsArePrefixExact && gaugeColumnsUnchangedExact &&
  maxAssembly["ResidueUnknownCount"] ===
    baseResidueCount +
      additionalLetterCount residueColumnsPerLetter &&
  maxAssembly["UnknownCount"] ===
    baseUnknownCount +
      additionalLetterCount residueColumnsPerLetter &&
  maxAssembly["ColumnOrder", "Residue"] ===
    baseAssembly["ColumnOrder", "Residue"]];
If[! TrueQ[appendedOnlyResidueColumnStructureExact],
  finish["AppendedOnlyResidueColumnStructureInvalid", <|
    "ResidueColumnsPerLetter" -> residueColumnsPerLetter,
    "BaseOneFormsArePrefixExact" -> baseOneFormsArePrefixExact,
    "GaugeColumnsUnchangedExact" -> gaugeColumnsUnchangedExact,
    "BaseUnknownCount" -> baseUnknownCount,
    "TargetUnknownCount" -> maxAssembly["UnknownCount"],
    "AdditionalLetterCount" -> additionalLetterCount|>, 79]];

pointCount = Max[21, Ceiling[(unknownCount + 32)/32]];
If[unknownCount > 960 || pointCount > 31,
  finish["Rank2OrbitUnknownBoundViolated", <|
    "UnknownCount" -> unknownCount, "PointCount" -> pointCount|>,
    79]];
Print["CF300_GALOIS_ORBIT milestone=target_ready census_s=",
  censusSeconds, " rebind_s=", rebindSeconds,
  " sources=", potentialSourceCount,
  " forcing_letters=", Length[forcingLetterRecords],
  " appended=", additionalLetterCount,
  " unknowns=", unknownCount, " points=", pointCount];

canonicalVectorQ[array_, length_Integer, prime_Integer] := TrueQ[
  VectorQ[array, IntegerQ] && Length[array] === length &&
    AllTrue[array, 0 <= #1 < prime &]];
canonicalMatrixQ[array_, rows_Integer, columns_Integer,
    prime_Integer] := TrueQ[
  If[rows === 0, array === {},
    MatrixQ[array, IntegerQ] && Dimensions[array] === {rows, columns}] &&
  AllTrue[Flatten[Normal[array]], 0 <= #1 < prime &]];
nativeRankFailure[status_String, data_: <||>] :=
  Join[<|"Status" -> status|>, data];
nativeRank[localMatrix_?MatrixQ, prime_Integer, label_String,
    imageID_String, tag_String] := Module[
  {rows, columns, request, seconds, run, certificate, rank, nullity,
   diagnosticSeconds, diagnosticRun},
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
      "DiagnosticVerification" ->
        Lookup[diagnosticRun, "Verification", Missing["Absent"]],
      "DiagnosticArtifactDirectory" ->
        Lookup[diagnosticRun, "ArtifactDirectory", Missing["Absent"]],
      "DiagnosticSeconds" -> diagnosticSeconds,
      "Seconds" -> seconds|>]]];
  certificate = run["Certificate"];
  rank = certificate["Rank"];
  nullity = certificate["Nullity"];
  If[certificate["ParticularSolution"] =!=
        ConstantArray[0, columns] || rank + nullity =!= columns ||
      ! canonicalVectorQ[certificate["ParticularSolution"], columns,
        prime] ||
      ! canonicalMatrixQ[certificate["NullspaceBasis"], nullity,
        columns, prime],
    Return[nativeRankFailure[
      "NativeRankCertificatePostconditionFailed", <|
        "MatrixDimensions" -> {rows, columns}, "Rank" -> rank,
        "Nullity" -> nullity, "Seconds" -> seconds|>]]];
  <|"Status" -> "VerifiedNativeRankV1",
    "MatrixDimensions" -> {rows, columns}, "Rank" -> rank,
    "Nullity" -> nullity, "Seconds" -> seconds,
    "PivotFingerprint" -> fingerprint[certificate["PivotColumns"]],
    "FreeColumnFingerprint" -> fingerprint[certificate["FreeColumns"]],
    "RowWitnessFingerprint" ->
      fingerprint[certificate["IndependentEquationRows"]]|>
];
rankImage[matrix_?MatrixQ, right_List, prime_Integer,
    label_String, imageID_String] := Module[
  {rows, columns, rightColumn, augmented, coefficient, augmentedRank},
  {rows, columns} = Dimensions[matrix];
  rightColumn = SparseArray[
    MapIndexed[{First[#2], 1} -> #1 &, right], {rows, 1}];
  augmented = Join[SparseArray[matrix], rightColumn, 2];
  coefficient = nativeRank[SparseArray[matrix], prime,
    label, imageID, "coefficient"];
  If[Lookup[coefficient, "Status", None] =!= "VerifiedNativeRankV1",
    Return[nativeRankFailure["RankImageCoefficientFailed", <|
      "Coefficient" -> coefficient|>]]];
  augmentedRank = nativeRank[augmented, prime,
    label, imageID, "augmented"];
  If[Lookup[augmentedRank, "Status", None] =!=
      "VerifiedNativeRankV1",
    Return[nativeRankFailure["RankImageAugmentedFailed", <|
      "Coefficient" -> coefficient,
      "Augmented" -> augmentedRank|>]]];
  If[! MemberQ[{coefficient["Rank"], coefficient["Rank"] + 1},
      augmentedRank["Rank"]],
    Return[nativeRankFailure["RankImageRankRelationFailed", <|
      "Coefficient" -> coefficient,
      "Augmented" -> augmentedRank|>]]];
  <|"Status" -> "CertifiedAffineConsistencyByTwoRanksV1",
    "Consistent" ->
      (coefficient["Rank"] === augmentedRank["Rank"]),
    "CoefficientRank" -> coefficient["Rank"],
    "AugmentedRank" -> augmentedRank["Rank"],
    "CoefficientNullity" -> coefficient["Nullity"],
    "CoefficientCertificate" -> coefficient,
    "AugmentedCertificate" -> augmentedRank|>
];

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
   witness, newColumns, score, fullRank, imageInconsistent},
  prime = image["Prime"];
  epsilonValue = image["EpsilonValue"];
  seed = Hash[{2026082335, "GaloisOrbitForcingV6",
    image["ImageID"], maxPreparation["ABIFingerprint"]}, "CRC32"];
  {sampleSeconds, targetSample} = AbsoluteTiming[
    CodexDirectRootChannelAssembler`DRCAAssembleSample[
      maxAssembly, epsilonValue, prime,
      "PointCount" -> pointCount,
      "MaximumAttempts" -> 40 pointCount,
      "RandomSeed" -> seed, "CandidatePoints" -> Automatic,
      "BranchFlipMask" -> 0]];
  If[Lookup[targetSample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      targetSample["MatrixDimensions"] =!=
        {32 pointCount, unknownCount},
    finish["TargetSampleFailed", <|"Image" -> image,
      "SampleStatus" -> Lookup[targetSample, "Status", None]|>, 80]];
  screenPoints = Take[targetSample["AcceptedPoints"], 21];
  targetScreenMatrix = Take[targetSample["Matrix"], 32 21];
  targetScreenRight = Take[targetSample["RightHandSide"], 32 21];
  baseSample = CodexDirectRootChannelAssembler`DRCAAssembleSample[
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
    finish["BasePureSubsetContainmentFailed", <|"Image" -> image|>,
      81]];
  witness = CodexAffineInconsistencyWitness`AIWConstruct[
    SparseArray[baseSample["Matrix"]], baseSample["RightHandSide"],
    prime, files["NativeAdapter"], files["NativeBinary"],
    nativeThreads,
    makeNonce["GaloisOrbitForcingV6", image["ImageID"],
      "left-witness"]];
  If[Lookup[witness, "Status", None] =!=
      "CertifiedAffineLeftInconsistencyWitnessV1",
    finish["BaseLeftWitnessFailed", <|"Image" -> image,
      "WitnessStatus" -> Lookup[witness, "Status", None],
      "WitnessFailure" -> KeyDrop[witness, "Witness"]|>, 82]];
  newColumns = targetScreenMatrix[[All,
    baseUnknownCount + 1 ;; unknownCount]];
  score = CodexAffineInconsistencyWitness`AIWScoreColumns[
    witness, SparseArray[newColumns]];
  If[Lookup[score, "Status", None] =!=
      "AffineWitnessCandidateColumnScoreV1",
    finish["OrbitColumnWitnessScoreFailed", <|"Image" -> image|>,
      83]];
  fullRank = If[TrueQ[score["AllScoresZero"]],
    Missing["RejectedByBaseLeftWitness"],
    rankImage[targetSample["Matrix"],
      targetSample["RightHandSide"], prime,
      "GaloisOrbitForcingV6", image["ImageID"]]];
  If[! MissingQ[fullRank] &&
      Lookup[fullRank, "Status", None] =!=
        "CertifiedAffineConsistencyByTwoRanksV1",
    finish["MaximalOrbitFullRankFailed", <|"Image" -> image,
      "RankFailure" -> fullRank|>, 84]];
  imageInconsistent = If[MissingQ[fullRank], True,
    ! TrueQ[fullRank["Consistent"]]];
  Print["CF300_GALOIS_ORBIT milestone=image_complete image=",
    image["ImageID"], " score_nonzero=", score["NonzeroScoreCount"],
    " inconsistent=", imageInconsistent];
  Join[image, <|"PointCount" -> pointCount,
    "AttemptCount" -> targetSample["AttemptCount"],
    "AcceptedPointsFingerprint" ->
      fingerprint[targetSample["AcceptedPoints"]],
    "SampleSeconds" -> sampleSeconds,
    "MatrixFingerprint" ->
      Hash[targetSample["Matrix"], "SHA256", "HexString"],
    "RightHandSideFingerprint" ->
      Hash[targetSample["RightHandSide"], "SHA256", "HexString"],
    "BaseColumnPrefixContainedExactly" -> True,
    "BaseWitness" -> KeyDrop[witness, "Witness"],
    "AppendedOrbitColumnWitnessScore" -> score,
    "FullRank" -> fullRank,
    "MaximalOrbitAnsatzInconsistentAtImage" -> imageInconsistent|>]
  ], {image, images}];

If[! stableInputsQ[],
  finish["SourceOrArtifactChangedDuringScreen", <||>, 95]];
everyImageRejectsMaximalOrbitAnsatz = AllTrue[imageResults,
  TrueQ[#1["MaximalOrbitAnsatzInconsistentAtImage"]] &];
subsetRejectionByImage = Association@Table[
  imageResult["ImageID"] ->
    TrueQ[imageResult["MaximalOrbitAnsatzInconsistentAtImage"]],
  {imageResult, imageResults}];

everyImageBaseColumnPrefixContainedExactly = AllTrue[imageResults,
  TrueQ[#1["BaseColumnPrefixContainedExactly"]] &];
columnDeletionImplicationExact = TrueQ[
  appendedOnlyResidueColumnStructureExact &&
  everyImageBaseColumnPrefixContainedExactly];
If[! TrueQ[columnDeletionImplicationExact],
  finish["SubsetEmbeddingCertificateInvalid", <|
    "AppendedOnlyResidueColumnStructureExact" ->
      appendedOnlyResidueColumnStructureExact,
    "EveryImageBaseColumnPrefixContainedExactly" ->
      everyImageBaseColumnPrefixContainedExactly|>, 96]];

finish["CF300Sector12GaloisOrbitForcingScreenPassedV6a", <|
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> expectedPreparationHash,
  "CacheFile" -> cacheFile, "CacheSHA256" -> expectedCacheHash,
  "SourceHashes" -> sourceHashesBefore,
  "DriverSHA256" -> driverHashBefore,
  "DedicatedContextHydrationDiagnostics" -> hydrationDiagnostics,
  "CensusSeconds" -> censusSeconds,
  "RebindSeconds" -> rebindSeconds,
  "OrbitPerformanceCounters" -> orbitPerformanceCounters,
  "CharacterCertificates" -> characterCertificates,
  "ExactChannelRebindDiagnostics" -> exactRebindDiagnostics,
  "EpsilonSamples" -> epsilonSamples,
  "GaloisSignMasks" -> signMasks,
  "PotentialSourceCount" -> potentialSourceCount,
  "ConjugateCandidateCount" -> conjugateCandidateCount,
  "DeduplicatedForcingLetterCount" -> Length[forcingLetterRecords],
  "BaseOneFormCount" -> Length[baseOneForms],
  "AppendedOrbitLetterCount" -> additionalLetterCount,
  "MaximalOneFormCount" -> Length[maxOneForms],
  "MaximalUnknownCount" -> unknownCount,
  "PointCount" -> pointCount,
  "ExactPotentialAndDLogProvenance" -> forcingLetterRecords,
  "SourcePotentialGaloisOrbits" -> sourceOrbitRecords,
  "OrbitClosureExact" -> orbitClosureExact,
  "MaximalPreparationSummary" -> KeyTake[maxPreparation, {
    "RootSourceIndices", "OneFormMetadata", "GaugeDenominator",
    "GaugeSupport", "GaugeUnknownCount", "ResidueUnknownCount",
    "UnknownCount", "ABIFingerprint"}],
  "MaximalAssemblyFingerprint" -> maxAssembly["AssemblyFingerprint"],
  "ImageSpecifications" -> images,
  "ImageResults" -> imageResults,
  "EveryImageRejectsMaximalOrbitAnsatz" ->
    everyImageRejectsMaximalOrbitAnsatz,
  "SubsetEmbeddingCertificate" -> <|
    "Status" -> "ExactColumnSubsetEmbeddingV6a",
    "BaseOneFormsArePrefixExact" -> baseOneFormsArePrefixExact,
    "GaugeColumnsUnchangedExact" -> gaugeColumnsUnchangedExact,
    "ResidueColumnsPerLetter" -> residueColumnsPerLetter,
    "AppendedOnlyResidueColumnStructureExact" ->
      appendedOnlyResidueColumnStructureExact,
    "EveryImageBaseColumnPrefixContainedExactly" ->
      everyImageBaseColumnPrefixContainedExactly,
    "ColumnDeletionImplicationExact" ->
      columnDeletionImplicationExact,
    "SubsetRejectionCertifiedByImage" -> subsetRejectionByImage,
    "EveryTestedImageRejectsEveryLetterSubset" ->
      everyImageRejectsMaximalOrbitAnsatz,
    "Scope" ->
      "subsets of the four-sign closure of forcing-entry dlogs at epsilon samples {0,1,-1,2}",
    "Qualification" ->
      "finite-field image rejection is not by itself a lifted characteristic-zero obstruction certificate"|>|>,
  0]
      ],
    driverExitTag],
  artifactNamesAfterScope = Names[artifactContextPattern];
  artifactNamespaceAfterScopeAudit = artifactNamespaceAudit[
    artifactNamesAfterScope];
  artifactNamespaceExactAfterScope = TrueQ[
    artifactNamespaceAfterScopeAudit["ExactOwnedNamespaceQ"]];
  artifactDefinitionsAfterScope =
    artifactDefinitionStatesFromNames[artifactNamesAfterScope];
  artifactSymbolsDefinitionFreeAfterScope = TrueQ[
    artifactNamespaceExactAfterScope &&
    AllTrue[Values[artifactDefinitionsAfterScope],
      definitionFreeStateQ]];
  callerContextRestoredAfterScope = TrueQ[
    SameQ[$Context, callerContextBeforeScope] &&
    SameQ[$ContextPath, callerContextPathBeforeScope]];
  artifactContextRemovalAttempted = True;
  Quiet[Remove["CodexCF300GaloisOrbitArtifactV6a`*"]];
  artifactContextRemovedAfterScope = TrueQ[
    Names["CodexCF300GaloisOrbitArtifactV6a`*"] === {}];
  driverExitScopeActive = False];

If[! TrueQ[artifactNamespaceExactAfterScope] ||
    ! TrueQ[artifactSymbolsDefinitionFreeAfterScope] ||
    ! TrueQ[callerContextRestoredAfterScope] ||
    ! TrueQ[artifactContextRemovalAttempted] ||
    ! TrueQ[artifactContextRemovedAfterScope],
  Print["CF300_GALOIS_ORBIT FAIL dedicated artifact scope postcondition ",
    "namespace=", InputForm[artifactNamespaceAfterScopeAudit],
    "definitions=", InputForm[artifactDefinitionsAfterScope],
    " context_restored=", callerContextRestoredAfterScope,
    " context_removed=", artifactContextRemovedAfterScope];
  cf300GaloisOrbitDriverV6aSystemExit[97]];
If[AssociationQ[scopeOutcome] &&
    Lookup[scopeOutcome, "Status", None] ===
      "CF300GaloisOrbitDriverExitRequestedV6a" &&
    IntegerQ[Lookup[scopeOutcome, "Code", $Failed]],
  cf300GaloisOrbitDriverV6aSystemExit[scopeOutcome["Code"]]];
Print["CF300_GALOIS_ORBIT FAIL unexpected sanitized-scope outcome=",
  InputForm[scopeOutcome]];
cf300GaloisOrbitDriverV6aSystemExit[97];

