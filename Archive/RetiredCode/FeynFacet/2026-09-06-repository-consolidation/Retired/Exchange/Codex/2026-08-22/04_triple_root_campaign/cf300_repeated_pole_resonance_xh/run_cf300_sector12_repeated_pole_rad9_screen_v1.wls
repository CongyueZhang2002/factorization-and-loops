#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300RepeatedPoleRad9DriverV1`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300RepeatedPoleRad9DriverV1`Private`*"]];

cf300RepeatedPoleRad9DriverV1SystemExit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);
driverExitScopeActive = False;
driverExitTag =
  "CF300RepeatedPoleRad9DriverV1Exit-" <> CreateUUID[];
cf300RepeatedPoleRad9DriverV1Exit[code_Integer] := If[
  TrueQ[driverExitScopeActive],
  Throw[<|"Status" -> "CF300RepeatedPoleRad9DriverExitRequestedV1",
    "Code" -> code|>, driverExitTag],
  cf300RepeatedPoleRad9DriverV1SystemExit[code]];

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{6, 7}, Length[arguments]],
  Print["CF300_REPEATED_POLE_RAD9 FAIL usage=<project-root> <preparation.wl> " <>
    "<compiled-cache.wl> <denominator-census.wl> <output.wl> " <>
    "<CERTIFICATE|RAD9> [native-threads]"];
  cf300RepeatedPoleRad9DriverV1Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
censusFile = ExpandFileName[arguments[[4]]];
outputFile = ExpandFileName[arguments[[5]]];
runMode = arguments[[6]];
allowedRunModes = {"CERTIFICATE", "RAD9"};
nativeThreads = If[Length[arguments] === 7,
  Quiet[Check[ToExpression[arguments[[7]]], $Failed]], 1];
driverDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[driverDirectory];
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
  "NativeBinary" ->
    "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5"|>;
expectedPreparationHash =
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedCensusHash =
  "c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a";
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
  FileHash[censusFile, "SHA256", "HexString"] === expectedCensusHash &&
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
    Print["CF300_REPEATED_POLE_RAD9 FAIL atomic output race output=",
      outputFile]; cf300RepeatedPoleRad9DriverV1Exit[98]];
  Print["CF300_REPEATED_POLE_RAD9 status=", status,
    " output=", outputFile];
  cf300RepeatedPoleRad9DriverV1Exit[code]
];
makeNonce[parts___] := Module[{nonce},
  nonce = Mod[Hash[{driverHashBefore, parts, #1}, "SHA256"], 2^64] & /@
    {"hi", "lo"};
  If[nonce === {0, 0}, {0, 1}, nonce]
];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    ! FileExistsQ[censusFile] || FileExistsQ[outputFile] ||
    ! DirectoryQ[DirectoryName[outputFile]] ||
    ! MemberQ[allowedRunModes, runMode] ||
    ! IntegerQ[nativeThreads] || ! (1 <= nativeThreads <= 8),
  Print["CF300_REPEATED_POLE_RAD9 FAIL invalid inputs, mode, stale output, or threads"];
  cf300RepeatedPoleRad9DriverV1Exit[65]];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
If[sourceHashesBefore =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash ||
    FileHash[censusFile, "SHA256", "HexString"] =!= expectedCensusHash,
  Print["CF300_REPEATED_POLE_RAD9 FAIL pinned source or artifact mismatch"];
  cf300RepeatedPoleRad9DriverV1Exit[66]];

loadSourceNames = {"TripleRootAlgebra", "TripleRootStripAdapter",
  "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
  "Assembler", "ArtifactHelper", "AnsatzRebind", "NativeAdapter",
  "WitnessHelper"};
loadOutcomes = AssociationMap[loadSource[files[#1]] &, loadSourceNames];
If[! AllTrue[Lookup[Values[loadOutcomes], "Status", None],
      #1 === "Loaded" &] || ! stableInputsQ[],
  Print["CF300_REPEATED_POLE_RAD9 FAIL pinned load failed outcomes=",
    InputForm[loadOutcomes]];
  cf300RepeatedPoleRad9DriverV1Exit[67]];

artifactContext = "CodexCF300RepeatedPoleRad9ArtifactV1`";
artifactContextPattern = "CodexCF300RepeatedPoleRad9ArtifactV1`*";
artifactNamesBeforeCreation = Names[artifactContextPattern];
If[artifactNamesBeforeCreation =!= {},
  Print["CF300_REPEATED_POLE_RAD9 FAIL dedicated artifact context not fresh"];
  cf300RepeatedPoleRad9DriverV1Exit[67]];
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
  "CodexTripleRootReconstruction`", "CodexTripleRootPilot`",
  "CodexTripleRootStrip`", "CodexTripleRoot`",
  "System`", "CodexCF300RepeatedPoleRad9DriverV1`"};

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
censusArtifact = artifactRead[censusFile];
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
  "Status" -> "CF300RepeatedPoleRad9DedicatedContextHydrationV1",
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
  "CensusAssociationQ" -> AssociationQ[censusArtifact],
  "CensusStatus" -> If[AssociationQ[censusArtifact],
    Lookup[censusArtifact, "Status", Missing["Absent"]], $Failed],
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
    ! AssociationQ[censusArtifact] ||
    Lookup[censusArtifact, "Status", None] =!=
      "CF300Sector12DenominatorCensusPassed" ||
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
baseSupport = basePreparation["GaugeSupport"];
baseDenominator = basePreparation["GaugeDenominator"];
{upper, lower} = basePreparation["Dimensions"];
gradeCount = basePreparation["GradeCount"];
baseGaugeCount = basePreparation["GaugeUnknownCount"];
baseResidueCount = basePreparation["ResidueUnknownCount"];
baseUnknownCount = basePreparation["UnknownCount"];
baseSupportCount = Length[baseSupport];
gaugeChannelCount = upper lower gradeCount;
If[{Length[roots], gradeCount, upper, lower, baseSupportCount,
      Length[baseOneForms], baseGaugeCount, baseResidueCount,
      baseUnknownCount, Exponent[baseDenominator, x],
      Exponent[baseDenominator, y]} =!=
    {2, 4, 2, 2, 30, 36, 480, 144, 624, 4, 5},
  finish["PhysicalDimensionOrBaseAnsatzContractInvalid", <|
    "Observed" -> {Length[roots], gradeCount, upper, lower,
      baseSupportCount, Length[baseOneForms], baseGaugeCount,
      baseResidueCount, baseUnknownCount,
      Exponent[baseDenominator, x], Exponent[baseDenominator, y]}|>,
    70]];

expectedFactorFingerprints = Sort[{
  "1dd399f7c8678f020a00263e2371d2fdc6c00f56984a71653b9e13e2751cb530",
  "2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881",
  "33ee404e011f65512b192d8baa6ecd29175dccb8c8328c801a495a56bead0301",
  "a1fce4363854ff888cff4b8e7875d600c2682390412a8cf79b37d0b11148b0fa",
  "b6719ed95b85c762bb92ca27122d3f634f52b4813ec641cb4f9053cddfb26c54",
  "c799eabc0695b12beeccf7a2edfa9702dc5efaddfdec7bf64437b73807eff7ed",
  "ca57b1d43a23420f8c1eec7d9e8dd0da36077e0a203b6a6feccd26ceac8f8284",
  "ce44a483203b0cde640e984643bcf415afd24ea95df2b50ee87ae72e232be10e",
  "d700fbc408b58cc5c9d5bdabefc64f3071dded7ad6a2d46f54ba2a0a07aea9ae"}];
factorCatalog = SortBy[censusArtifact["FactorSummary"],
  #1["FactorFingerprint"] &];
catalogFingerprints = Lookup[factorCatalog, "FactorFingerprint", {}];
reconstructedGaugeDenominator = Times @@
  (Power @@@ censusArtifact["GaugeFactorization"]);
If[Length[factorCatalog] =!= 9 ||
    Sort[catalogFingerprints] =!= expectedFactorFingerprints ||
    ! DuplicateFreeQ[catalogFingerprints] ||
    ! AllTrue[factorCatalog,
      AssociationQ[#1] && PolynomialQ[#1["Factor"], {x, y, epsilon}] &&
      TrueQ[#1["KinematicsDependent"]] &&
      IntegerQ[#1["GaugeDenominatorExponent"]] &&
      IntegerQ[#1["ForcingMaximumDenominatorExponent"]] &&
      IntegerQ[#1["DiagonalMaximumDenominatorExponent"]] &] ||
    ! TrueQ[Together[
      reconstructedGaugeDenominator - baseDenominator] === 0],
  finish["ExactDivisorCatalogContractInvalid", <|
    "CatalogFingerprints" -> catalogFingerprints,
    "ReconstructedGaugeDenominator" ->
      reconstructedGaugeDenominator|>, 71]];

radicalMultiplier = Expand[Times @@ Lookup[factorCatalog, "Factor"]];
targetDenominator = Expand[baseDenominator radicalMultiplier];
radicalDegrees = Exponent[radicalMultiplier, #1] & /@ {x, y};
targetDegrees = Exponent[targetDenominator, #1] & /@ {x, y};
denseSupport[degrees : {_Integer, _Integer}] :=
  Flatten[Table[{i, j}, {i, 0, degrees[[1]]},
    {j, 0, degrees[[2]]}], 1];
targetSupport = denseSupport[targetDegrees];
targetSupportCount = Length[targetSupport];
gaugeCount = gaugeChannelCount targetSupportCount;
residueCount = Length[baseOneForms] upper lower;
unknownCount = gaugeCount + residueCount;
If[radicalDegrees =!= {9, 7} || targetDegrees =!= {13, 12} ||
    targetSupportCount =!= 182 || gaugeCount =!= 2912 ||
    residueCount =!= 144 || unknownCount =!= 3056,
  finish["RAD9TargetCountContractInvalid", <|
    "RadicalDegrees" -> radicalDegrees,
    "TargetDegrees" -> targetDegrees,
    "TargetSupportCount" -> targetSupportCount,
    "GaugeUnknownCount" -> gaugeCount,
    "ResidueUnknownCount" -> residueCount,
    "UnknownCount" -> unknownCount|>, 72]];

(* The source-pinned assembler multiplies the epsilon-free E/C kernels
   by epsilon.  The algebraic gauge basis contributes its exact half-root
   valuation.  At divisor f and positive integer pole order k, the
   epsilon-zero leading spectrum is -k + nu_grade(f)/2.  Both active root
   squares have only simple zeros, so nu_grade is 0 or 1 and this spectrum
   never vanishes for positive integral k. *)
diagonalChannels = Lookup[baseAssembly["ExactChannelForms"],
  {"E", "C"}, $Failed];
diagonalKernelsEpsilonFreeQ =
  diagonalChannels =!= $Failed && FreeQ[diagonalChannels, epsilon];
diagonalFuchsianAtCatalogQ = AllTrue[factorCatalog,
  #1["DiagonalMaximumDenominatorExponent"] <= 1 &];
samePolynomialFactorQ[left_, right_] := Module[{ratio},
  ratio = Cancel[Together[left/right]];
  TrueQ[ratio =!= 0 &&
    FreeQ[ratio, Alternatives[x, y, epsilon]]]
];
factorValuation[rational_, factor_] := Module[
  {q = Together[rational], numeratorPairs, denominatorPairs},
  numeratorPairs = Rest[FactorList[Numerator[q]]];
  denominatorPairs = Rest[FactorList[Denominator[q]]];
  Total[Cases[numeratorPairs,
      {candidate_, power_Integer} /;
        samePolynomialFactorQ[candidate, factor] :> power]] -
    Total[Cases[denominatorPairs,
      {candidate_, power_Integer} /;
        samePolynomialFactorQ[candidate, factor] :> power]]
];
rootSquares = Lookup[roots, "RootSquare", $Failed];
rootValuationMatrix = If[ListQ[rootSquares],
  Table[factorValuation[rootSquares[[rootIndex]],
      factorCatalog[[factorIndex, "Factor"]]],
    {rootIndex, Length[rootSquares]},
    {factorIndex, Length[factorCatalog]}], $Failed];
rootValuationContractQ = TrueQ[
  Dimensions[rootValuationMatrix] === {2, 9} &&
  AllTrue[Flatten[rootValuationMatrix], MemberQ[{0, 1}, #1] &] &&
  Total[Flatten[rootValuationMatrix]] === 2 &&
  (Total /@ rootValuationMatrix) === {1, 1} &&
  Count[Total[rootValuationMatrix], 1] === 2];
modExact[value_, prime_Integer] := Module[
  {q = Together[value], denominator},
  If[! MatchQ[q, _Integer | _Rational], Return[$Failed]];
  denominator = Mod[Denominator[q], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[q] PowerMod[denominator, -1, prime], prime]
];
localPoleRecords = MapIndexed[
  Function[{record, position}, Module[
    {current, forcing, minimal, targetK, factorIndex,
     rootValuations, gradeValuations, epsilonZeroSpectrum,
     determinantConstant},
    current = record["GaugeDenominatorExponent"];
    forcing = record["ForcingMaximumDenominatorExponent"];
    minimal = Max[forcing - 1, 0];
    targetK = current + 1;
    factorIndex = First[position];
    rootValuations = rootValuationMatrix[[All, factorIndex]];
    gradeValuations = Table[
      Total[BitGet[grade, Range[0, Length[rootSquares] - 1]]
        rootValuations], {grade, 0, gradeCount - 1}];
    epsilonZeroSpectrum = -targetK + gradeValuations/2;
    determinantConstant =
      Times @@ (epsilonZeroSpectrum^(upper lower));
    <|"Factor" -> record["Factor"],
      "FactorFingerprint" -> record["FactorFingerprint"],
      "ForcingPoleOrder" -> forcing,
      "MinimalGaugePoleOrder" -> minimal,
      "CurrentGaugePoleOrder" -> current,
      "RAD9TargetGaugePoleOrder" -> targetK,
      "CurrentMeetsForcingValuation" -> TrueQ[current >= minimal],
      "PositiveLeadingOrderK" -> targetK,
      "RootSquareValuations" -> rootValuations,
      "GaugeGradeValuations" -> gradeValuations,
      "HomogeneousOperatorEpsilonZeroSpectrum" ->
        epsilonZeroSpectrum,
      "DeterminantEpsilonConstantTerm" -> determinantConstant,
      "ModularNonzeroChecks" -> AssociationMap[
        modExact[determinantConstant, #1] &, {10007, 10039}],
      "ExactNonresonanceAtTargetOrder" ->
        TrueQ[targetK > 0 && current >= minimal &&
          diagonalKernelsEpsilonFreeQ &&
          FreeQ[epsilonZeroSpectrum, 0]]|>
  ]], factorCatalog];
localResonanceCertificateExact = TrueQ[
  diagonalKernelsEpsilonFreeQ && diagonalFuchsianAtCatalogQ &&
  rootValuationContractQ &&
  AllTrue[localPoleRecords,
    TrueQ[#1["ExactNonresonanceAtTargetOrder"]] &&
    AllTrue[Values[#1["ModularNonzeroChecks"]],
      IntegerQ[#1] && #1 =!= 0 &] &]];
If[! localResonanceCertificateExact,
  finish["LocalResonanceCertificateFailed", <|
    "DiagonalKernelsEpsilonFreeQ" -> diagonalKernelsEpsilonFreeQ,
    "DiagonalFuchsianAtCatalogQ" -> diagonalFuchsianAtCatalogQ,
    "RootValuationMatrix" -> rootValuationMatrix,
    "RootValuationContractQ" -> rootValuationContractQ,
    "LocalPoleRecords" -> localPoleRecords|>, 73]];
localResonanceCertificate = <|
  "Status" -> "ExactNoPositiveLeadingPoleResonanceV1",
  "DiagonalKernelsEpsilonFreeQ" ->
    diagonalKernelsEpsilonFreeQ,
  "DiagonalFuchsianAtCatalogQ" ->
    diagonalFuchsianAtCatalogQ,
  "RootValuationMatrix" -> rootValuationMatrix,
  "RootValuationContractQ" -> rootValuationContractQ,
  "GaugeChannelDimension" -> gaugeChannelCount,
  "LeadingOperator" ->
    "(-k + nu_grade(f)/2) I + eps L_f",
  "DeterminantConstantTerm" ->
    "Product_grade (-k + nu_grade(f)/2)^4",
  "AllPositiveOrdersNonresonantOverQOfEpsilon" -> True,
  "RepeatedSpatialPolesPhysicsMotivated" -> False,
  "LocalPoleRecords" -> localPoleRecords|>;
If[! stableInputsQ[],
  finish["SourceOrArtifactChangedDuringLocalResonanceGate",
    <||>, 95]];
If[runMode === "CERTIFICATE",
  finish["CF300Sector12LocalResonanceCertificatePassedV1", <|
    "RunMode" -> runMode,
    "PreparationFile" -> preparationFile,
    "PreparationSHA256" -> expectedPreparationHash,
    "CacheFile" -> cacheFile, "CacheSHA256" -> expectedCacheHash,
    "CensusFile" -> censusFile, "CensusSHA256" -> expectedCensusHash,
    "SourceHashes" -> sourceHashesBefore,
    "DriverSHA256" -> driverHashBefore,
    "DedicatedContextHydrationDiagnostics" -> hydrationDiagnostics,
    "ExactDivisorCatalog" -> factorCatalog,
    "BaseGaugeDenominator" -> baseDenominator,
    "LocalResonanceCertificate" -> localResonanceCertificate,
    "RAD9FallbackNotRun" -> True,
    "RAD9FallbackScope" ->
      "one extra copy of each exact channel divisor; 511 nonempty bounded profiles; denominator degrees (13,12), support 182, unknowns 3056, points 97",
    "Interpretation" ->
      "genuine positive-order repeated spatial poles are excluded exactly; RAD9 would only be an adversarial numerator/cancellation-support stress"|>,
    0]];

supportRules[polynomial_] :=
  CoefficientRules[Expand[polynomial], {x, y}];
supportExponents[polynomial_] := First /@ supportRules[polynomial];
supportKey[{i_Integer, j_Integer}] :=
  ToString[i] <> ":" <> ToString[j];
targetSupportIndex = AssociationThread[
  supportKey /@ targetSupport, Range[targetSupportCount]];
profileRecords = Table[Module[
  {selectedIndices, selected, unselected, subsetMultiplier,
   complementMultiplier, subsetDenominator, subsetDegrees,
   subsetSupport, complementSupport, embeddedSupport},
  selectedIndices = Pick[Range[Length[factorCatalog]],
    BitGet[mask, Range[0, Length[factorCatalog] - 1]], 1];
  selected = factorCatalog[[selectedIndices]];
  unselected = factorCatalog[[
    Complement[Range[Length[factorCatalog]], selectedIndices]]];
  subsetMultiplier = Expand[Times @@ Lookup[selected, "Factor", {}]];
  complementMultiplier = Expand[
    Times @@ Lookup[unselected, "Factor", {}]];
  subsetDenominator = Expand[baseDenominator subsetMultiplier];
  subsetDegrees = Exponent[subsetDenominator, #1] & /@ {x, y};
  subsetSupport = denseSupport[subsetDegrees];
  complementSupport = supportExponents[complementMultiplier];
  embeddedSupport = DeleteDuplicates[
    Total /@ Tuples[{subsetSupport, complementSupport}]];
  <|"Mask" -> mask,
    "SelectedFactorFingerprints" ->
      Lookup[selected, "FactorFingerprint", {}],
    "SelectedFactorCount" -> Length[selected],
    "SubsetDenominatorDegrees" -> subsetDegrees,
    "SubsetSupportCount" -> Length[subsetSupport],
    "ComplementMultiplierNonzero" ->
      ! TrueQ[complementMultiplier === 0],
    "ConvolutionSupportContainedInRAD9" ->
      TrueQ[SubsetQ[targetSupport, embeddedSupport]]|>
  ], {mask, 0, 2^Length[factorCatalog] - 1}];
maximalSupersetCertificateExact = TrueQ[
  Length[profileRecords] === 512 &&
  AllTrue[profileRecords,
    TrueQ[#1["ComplementMultiplierNonzero"]] &&
    TrueQ[#1["ConvolutionSupportContainedInRAD9"]] &]];
If[! maximalSupersetCertificateExact,
  finish["RAD9MaximalSupersetCertificateFailed", <|
    "FailedProfiles" -> Select[profileRecords,
      ! TrueQ[#1["ComplementMultiplierNonzero"]] ||
      ! TrueQ[#1["ConvolutionSupportContainedInRAD9"]] &]|>, 74]];

payload = CodexTripleRootReconstruction`Private`trBuildABIPayload[
  basePreparation["Record"], roots, basePreparation["Variables"],
  epsilon, basePreparation["Dimensions"], targetDenominator,
  targetSupport, baseOneForms, basePreparation["Normalizations"]];
If[payload === $Failed, finish["RAD9ABIPayloadFailed", <||>, 75]];
targetPreparation = Join[basePreparation, <|
  "GaugeDenominator" -> targetDenominator,
  "GaugeDenominatorDegrees" -> targetDegrees,
  "GaugeSupport" -> targetSupport,
  "GaugeUnknownCount" -> gaugeCount,
  "ResidueUnknownCount" -> residueCount,
  "UnknownCount" -> unknownCount,
  "ABIPayload" -> payload,
  "ABIFingerprint" -> fingerprint[payload]|>];
If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      targetPreparation],
  finish["RAD9PreparationInvalid", <||>, 75]];

{rebindSeconds, targetAssembly} = AbsoluteTiming[
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, targetPreparation]];
If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      targetAssembly] ||
    targetAssembly["SourceABIFingerprint"] =!=
      targetPreparation["ABIFingerprint"] ||
    targetAssembly["OneForms"] =!= baseOneForms ||
    targetAssembly["GaugeSupport"] =!= targetSupport,
  finish["RAD9AnsatzRebindInvalid", <|
    "RebindStatus" -> Lookup[targetAssembly, "Status", None],
    "RebindSeconds" -> rebindSeconds|>, 76]];

pointCount = Max[21, Ceiling[(unknownCount + 32)/32]];
If[pointCount =!= 97,
  finish["RAD9PointCountContractInvalid", <|
    "UnknownCount" -> unknownCount, "PointCount" -> pointCount|>, 76]];
Print["CF300_REPEATED_POLE_RAD9 milestone=target_ready",
  " rebind_s=", rebindSeconds,
  " divisors=", Length[factorCatalog],
  " profiles=", Length[profileRecords] - 1,
  " support=", targetSupportCount,
  " unknowns=", unknownCount, " points=", pointCount,
  " local_resonance_admissible=False"];

modRational[value_, prime_Integer] := Module[{q = Together[value],
    denominator},
  If[! MatchQ[q, _Integer | _Rational], Return[$Failed]];
  denominator = Mod[Denominator[q], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[q] PowerMod[denominator, -1, prime], prime]
];
embeddingAtImage[prime_Integer, epsilonValue_] := Module[
  {rules, imageRules, entries, targetExponent, targetIndex,
   coefficient, residueEntries},
  rules = supportRules[radicalMultiplier /. epsilon -> epsilonValue];
  imageRules = ({First[#1], modRational[Last[#1], prime]} &) /@ rules;
  If[! FreeQ[imageRules, $Failed] ||
      ! AllTrue[Last /@ imageRules, IntegerQ], Return[$Failed]];
  entries = Flatten[Table[
    Table[
      targetExponent = baseSupport[[baseMonomial]] + rule[[1]];
      targetIndex = Lookup[targetSupportIndex,
        supportKey[targetExponent], $Failed];
      coefficient = rule[[2]];
      If[targetIndex === $Failed, Return[$Failed]];
      {channel targetSupportCount + targetIndex,
        channel baseSupportCount + baseMonomial} -> coefficient,
      {rule, imageRules}],
    {channel, 0, gaugeChannelCount - 1},
    {baseMonomial, baseSupportCount}], 2];
  residueEntries = Table[
    {gaugeCount + residue, baseGaugeCount + residue} -> 1,
    {residue, residueCount}];
  SparseArray[Join[entries, residueEntries],
    {unknownCount, baseUnknownCount}, 0]
];

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
   embedding, projectedBaseMatrix, witness, score, fullRank,
   imageInconsistent},
  prime = image["Prime"];
  epsilonValue = image["EpsilonValue"];
  seed = Hash[{2026082361, "RepeatedPoleRad9V1",
    image["ImageID"], targetPreparation["ABIFingerprint"]}, "CRC32"];
  {sampleSeconds, targetSample} = AbsoluteTiming[
    CodexDirectRootChannelAssembler`DRCAAssembleSample[
      targetAssembly, epsilonValue, prime,
      "PointCount" -> pointCount,
      "MaximumAttempts" -> 50 pointCount,
      "RandomSeed" -> seed, "CandidatePoints" -> Automatic,
      "BranchFlipMask" -> 0]];
  If[Lookup[targetSample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      targetSample["MatrixDimensions"] =!=
        {32 pointCount, unknownCount},
    finish["RAD9TargetSampleFailed", <|"Image" -> image,
      "SampleStatus" -> Lookup[targetSample, "Status", None]|>, 80]];
  screenPoints = Take[targetSample["AcceptedPoints"], 21];
  targetScreenMatrix = Take[targetSample["Matrix"], 32 21];
  targetScreenRight = Take[targetSample["RightHandSide"], 32 21];
  baseSample = CodexDirectRootChannelAssembler`DRCAAssembleSample[
    baseAssembly, epsilonValue, prime,
    "PointCount" -> 21, "MaximumAttempts" -> 21,
    "RandomSeed" -> seed, "CandidatePoints" -> screenPoints,
    "BranchFlipMask" -> 0];
  embedding = embeddingAtImage[prime, epsilonValue];
  If[embedding === $Failed ||
      Dimensions[embedding] =!= {unknownCount, baseUnknownCount},
    finish["RAD9ImageEmbeddingConstructionFailed", <|
      "Image" -> image|>, 81]];
  projectedBaseMatrix = Mod[
    Normal[SparseArray[targetScreenMatrix].embedding], prime];
  If[Lookup[baseSample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      baseSample["AcceptedPoints"] =!= screenPoints ||
      baseSample["MatrixDimensions"] =!= {672, 624} ||
      baseSample["RightHandSide"] =!= targetScreenRight ||
      projectedBaseMatrix =!= baseSample["Matrix"],
    finish["RAD9BaseConvolutionEmbeddingFailed", <|
      "Image" -> image,
      "BaseSampleStatus" -> Lookup[baseSample, "Status", None],
      "ProjectionDimensions" -> Dimensions[projectedBaseMatrix]|>, 81]];
  witness = CodexAffineInconsistencyWitness`AIWConstruct[
    SparseArray[baseSample["Matrix"]], baseSample["RightHandSide"],
    prime, files["NativeAdapter"], files["NativeBinary"],
    nativeThreads,
    makeNonce["RepeatedPoleRad9V1", image["ImageID"],
      "left-witness"]];
  If[Lookup[witness, "Status", None] =!=
      "CertifiedAffineLeftInconsistencyWitnessV1",
    finish["BaseLeftWitnessFailed", <|"Image" -> image,
      "WitnessStatus" -> Lookup[witness, "Status", None],
      "WitnessFailure" -> KeyDrop[witness, "Witness"]|>, 82]];
  score = CodexAffineInconsistencyWitness`AIWScoreColumns[
    witness, SparseArray[targetScreenMatrix]];
  If[Lookup[score, "Status", None] =!=
      "AffineWitnessCandidateColumnScoreV1",
    finish["RAD9ColumnWitnessScoreFailed", <|"Image" -> image|>, 83]];
  fullRank = If[TrueQ[score["AllScoresZero"]],
    Missing["RejectedByBaseLeftWitness"],
    rankImage[targetSample["Matrix"],
      targetSample["RightHandSide"], prime,
      "RepeatedPoleRad9V1", image["ImageID"]]];
  If[! MissingQ[fullRank] &&
      Lookup[fullRank, "Status", None] =!=
        "CertifiedAffineConsistencyByTwoRanksV1",
    finish["RAD9FullRankFailed", <|"Image" -> image,
      "RankFailure" -> fullRank|>, 84]];
  imageInconsistent = If[MissingQ[fullRank], True,
    ! TrueQ[fullRank["Consistent"]]];
  Print["CF300_REPEATED_POLE_RAD9 milestone=image_complete image=",
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
    "BaseConvolutionEmbeddingExactAtImage" -> True,
    "BaseWitness" -> KeyDrop[witness, "Witness"],
    "RAD9ColumnWitnessScore" -> score,
    "FullRank" -> fullRank,
    "RAD9AnsatzInconsistentAtImage" -> imageInconsistent|>]
  ], {image, images}];

If[! stableInputsQ[],
  finish["SourceOrArtifactChangedDuringScreen", <||>, 95]];
everyImageRejectsRAD9 = AllTrue[imageResults,
  TrueQ[#1["RAD9AnsatzInconsistentAtImage"]] &];
profileRejectionByImage = Association@Table[
  imageResult["ImageID"] ->
    TrueQ[imageResult["RAD9AnsatzInconsistentAtImage"]],
  {imageResult, imageResults}];

finish["CF300Sector12RepeatedPoleRAD9ScreenPassedV1", <|
  "RunMode" -> runMode,
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> expectedPreparationHash,
  "CacheFile" -> cacheFile, "CacheSHA256" -> expectedCacheHash,
  "CensusFile" -> censusFile, "CensusSHA256" -> expectedCensusHash,
  "SourceHashes" -> sourceHashesBefore,
  "DriverSHA256" -> driverHashBefore,
  "DedicatedContextHydrationDiagnostics" -> hydrationDiagnostics,
  "RebindSeconds" -> rebindSeconds,
  "ExactDivisorCatalog" -> factorCatalog,
  "BaseGaugeDenominator" -> baseDenominator,
  "RadicalMultiplier" -> radicalMultiplier,
  "RAD9GaugeDenominator" -> targetDenominator,
  "RadicalDegrees" -> radicalDegrees,
  "RAD9DenominatorDegrees" -> targetDegrees,
  "RAD9SupportCount" -> targetSupportCount,
  "RAD9UnknownCount" -> unknownCount,
  "PointCount" -> pointCount,
  "LocalResonanceCertificate" -> localResonanceCertificate,
  "RAD9Interpretation" ->
    "adversarial denominator/support stress; any gain cannot be attributed to a genuine positive-order local resonance pole",
  "RAD9PreparationSummary" -> KeyTake[targetPreparation, {
    "RootSourceIndices", "GaugeDenominator",
    "GaugeDenominatorDegrees", "GaugeSupport",
    "GaugeUnknownCount", "ResidueUnknownCount",
    "UnknownCount", "ABIFingerprint"}],
  "RAD9AssemblyFingerprint" ->
    targetAssembly["AssemblyFingerprint"],
  "ImageSpecifications" -> images,
  "ImageResults" -> imageResults,
  "EveryImageRejectsRAD9" -> everyImageRejectsRAD9,
  "MaximalSupersetCertificate" -> <|
    "Status" -> "ExactRAD9ConvolutionEmbeddingV1",
    "DivisorCount" -> Length[factorCatalog],
    "ProfileCountIncludingBase" -> Length[profileRecords],
    "NonemptyProfileCount" -> Length[profileRecords] - 1,
    "ProfileRecords" -> profileRecords,
    "OneFormColumnsUnchanged" -> True,
    "MultiplicationByComplementInjective" -> True,
    "ExactConvolutionSupportContainment" ->
      maximalSupersetCertificateExact,
    "ColumnSpaceInclusionImplicationExact" -> True,
    "ProfileRejectionCertifiedByImage" ->
      profileRejectionByImage,
    "EveryTestedImageRejectsEveryBoundedProfile" ->
      everyImageRejectsRAD9,
    "Scope" ->
      "all 511 nonempty subsets adding at most one copy of each of the nine exact channel divisors to the current gauge denominator",
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
  Quiet[Remove["CodexCF300RepeatedPoleRad9ArtifactV1`*"]];
  artifactContextRemovedAfterScope = TrueQ[
    Names["CodexCF300RepeatedPoleRad9ArtifactV1`*"] === {}];
  driverExitScopeActive = False];

If[! TrueQ[artifactNamespaceExactAfterScope] ||
    ! TrueQ[artifactSymbolsDefinitionFreeAfterScope] ||
    ! TrueQ[callerContextRestoredAfterScope] ||
    ! TrueQ[artifactContextRemovalAttempted] ||
    ! TrueQ[artifactContextRemovedAfterScope],
  Print["CF300_REPEATED_POLE_RAD9 FAIL dedicated artifact scope postcondition ",
    "namespace=", InputForm[artifactNamespaceAfterScopeAudit],
    "definitions=", InputForm[artifactDefinitionsAfterScope],
    " context_restored=", callerContextRestoredAfterScope,
    " context_removed=", artifactContextRemovedAfterScope];
  cf300RepeatedPoleRad9DriverV1SystemExit[97]];
If[AssociationQ[scopeOutcome] &&
    Lookup[scopeOutcome, "Status", None] ===
      "CF300RepeatedPoleRad9DriverExitRequestedV1" &&
    IntegerQ[Lookup[scopeOutcome, "Code", $Failed]],
  cf300RepeatedPoleRad9DriverV1SystemExit[scopeOutcome["Code"]]];
Print["CF300_REPEATED_POLE_RAD9 FAIL unexpected sanitized-scope outcome=",
  InputForm[scopeOutcome]];
cf300RepeatedPoleRad9DriverV1SystemExit[97];
