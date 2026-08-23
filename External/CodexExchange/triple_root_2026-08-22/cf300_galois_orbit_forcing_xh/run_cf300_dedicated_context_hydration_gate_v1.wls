#!/usr/bin/env wolframscript

(* Minimal, read-only artifact hydration gate.  Artifact x/y/eps are created
   only in a fresh dedicated context.  The public file reader is intentionally
   not called because its current implementation hardcodes Global`. *)

$HistoryLength = 0;
BeginPackage["CodexCF300DedicatedContextHydrationGateV1`"];
Begin["`Private`"];
Quiet[ClearAll[
  "CodexCF300DedicatedContextHydrationGateV1`Private`*"]];
gateExit[code_Integer] := (End[]; EndPackage[]; System`Exit[code]);

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["CF300_DEDICATED_HYDRATION_GATE FAIL usage=<project-root> ",
    "<preparation.wl> <compiled-cache.wl>"];
  gateExit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
exchangeDirectory = FileNameJoin[{projectRoot, "External",
  "CodexExchange", "triple_root_2026-08-22"}];
directDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];

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
expectedPreparationHash =
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedExactChannelFormsFingerprint =
  "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d";
expectedCompiledFormsFingerprint =
  "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7";
expectedGlobalPoisonFingerprints = <|
  "x" ->
    "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
  "y" ->
    "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
  "eps" ->
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968"|>;

definitionComponents = {"OwnValues", "DownValues", "UpValues",
  "SubValues", "NValues", "DefaultValues", "FormatValues",
  "Attributes"};
SetAttributes[definitionState, HoldFirst];
definitionState[symbol_Symbol] := <|
  "OwnValues" -> OwnValues[symbol],
  "DownValues" -> DownValues[symbol],
  "UpValues" -> UpValues[symbol],
  "SubValues" -> SubValues[symbol],
  "NValues" -> NValues[symbol],
  "DefaultValues" -> DefaultValues[symbol],
  "FormatValues" -> FormatValues[symbol],
  "Attributes" -> Attributes[symbol]|>;
definitionState[___] := $Failed;
SetAttributes[definitionStateByNameHeld, HoldAll];
definitionStateByNameHeld[symbol_] := definitionState[symbol];
definitionStateByName[name_String] := ToExpression[
  name, InputForm,
  Function[heldSymbol, definitionStateByNameHeld[heldSymbol], HoldAll]];
definitionFreeStateQ[state_Association] := TrueQ[
  Lookup[state, definitionComponents, $Failed] ===
    ConstantArray[{}, Length[definitionComponents]]];
definitionFreeStateQ[___] := False;

fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
globalFingerprint[value_] := Block[
  {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
  fingerprint[value]];
globalStates[] := <|
  "x" -> definitionState[Global`x],
  "y" -> definitionState[Global`y],
  "eps" -> definitionState[Global`eps]|>;
globalFingerprints[states_Association] := AssociationMap[
  globalFingerprint[states[#1]] &, Keys[states]];
loadSource[file_String] := Module[{value},
  value = Quiet[CheckAbort[Get[file], $Aborted]];
  <|"Status" -> Which[value === $Aborted, "Aborted",
      value === $Failed, "Failed", True, "Loaded"],
    "ReturnHead" -> ToString[Head[value], InputForm]|>];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile],
  Print["CF300_DEDICATED_HYDRATION_GATE FAIL missing input"];
  gateExit[65]];
sourceHashes = Map[FileHash[#1, "SHA256", "HexString"] &, files];
pinsValidQ = TrueQ[sourceHashes === expectedHashes &&
  FileHash[preparationFile, "SHA256", "HexString"] ===
    expectedPreparationHash &&
  FileHash[cacheFile, "SHA256", "HexString"] === expectedCacheHash];
If[! pinsValidQ,
  Print["CF300_DEDICATED_HYDRATION_GATE FAIL source/artifact pin"];
  gateExit[66]];

globalStatesBefore = globalStates[];
globalFingerprintsBefore = globalFingerprints[globalStatesBefore];
loadOutcomes = AssociationMap[loadSource[files[#1]] &, Keys[files]];
loadsValidQ = AllTrue[Lookup[Values[loadOutcomes], "Status", None],
  #1 === "Loaded" &];

artifactContext = "CodexCF300DedicatedArtifactGateV1" <>
  StringReplace[CreateUUID[], "-" -> ""] <> "`";
artifactContextPattern = artifactContext <> "*";
artifactNamesBeforeCreation = Names[artifactContextPattern];
artifactSymbolHolds = ToExpression[
    artifactContext <> #1, InputForm, HoldComplete] & /@
  {"x", "y", "eps"};
artifactNamesBeforeHydration = Names[artifactContextPattern];
artifactDefinitionsBeforeHydration = AssociationMap[
  definitionStateByName, artifactNamesBeforeHydration];

runtimeContextPath = {artifactContext,
  "CodexDirectRootChannelCompiledArtifact`",
  "CodexDirectRootChannelAssembler`",
  "CodexTripleRootReconstruction`", "CodexTripleRootPilot`",
  "CodexTripleRootStrip`", "CodexTripleRoot`", "System`",
  "CodexCF300DedicatedContextHydrationGateV1`"};
callerContextBefore = $Context;
callerContextPathBefore = $ContextPath;
runtimeDiagnostics = Block[
  {$Context = artifactContext, $ContextPath = runtimeContextPath},
  rawPreparationArtifact = Quiet[Check[Get[preparationFile], $Failed]];
  rawCacheArtifact = Quiet[Check[Get[cacheFile], $Failed]];
  hydratedPreparation = If[AssociationQ[rawPreparationArtifact],
    Lookup[rawPreparationArtifact, "Preparation", $Failed], $Failed];
  rawAssembly = If[AssociationQ[rawCacheArtifact],
    Lookup[rawCacheArtifact, "DirectAssembly", $Failed], $Failed];
  exactForms = If[AssociationQ[rawAssembly],
    Lookup[rawAssembly, "ExactChannelForms", $Failed], $Failed];
  compiledForms = If[AssociationQ[rawAssembly],
    Lookup[rawAssembly, "CompiledForms", $Failed], $Failed];
  variables = If[AssociationQ[hydratedPreparation],
    Lookup[hydratedPreparation, "Variables", $Failed], $Failed];
  regulator = If[AssociationQ[hydratedPreparation],
    Lookup[hydratedPreparation, "Regulator", $Failed], $Failed];
  <|
    "RuntimeContext" -> $Context,
    "RuntimeContextPath" -> $ContextPath,
    "GlobalContextPresentInRuntimePath" ->
      MemberQ[$ContextPath, "Global`"],
    "PublicReaderIntentionallyNotCalled" -> True,
    "PublicReaderExclusionReason" ->
      "DRCAReadCompiledArtifact hardcodes Global context hydration",
    "PreparationAssociationQ" -> AssociationQ[rawPreparationArtifact],
    "PreparationStatus" -> If[AssociationQ[rawPreparationArtifact],
      Lookup[rawPreparationArtifact, "Status", Missing["Absent"]],
      $Failed],
    "PreparationValidator" -> If[AssociationQ[hydratedPreparation],
      CodexTripleRootReconstruction`TRPreparationABIValidQ[
        hydratedPreparation], False],
    "PreparationVariableNames" -> If[ListQ[variables],
      SymbolName /@ variables, $Failed],
    "PreparationVariableContexts" -> If[ListQ[variables],
      Context /@ variables, $Failed],
    "PreparationRegulatorName" -> If[MatchQ[regulator, _Symbol],
      SymbolName[regulator], $Failed],
    "PreparationRegulatorContext" -> If[MatchQ[regulator, _Symbol],
      Context[regulator], $Failed],
    "CacheAssociationQ" -> AssociationQ[rawCacheArtifact],
    "CacheStatus" -> If[AssociationQ[rawCacheArtifact],
      Lookup[rawCacheArtifact, "Status", Missing["Absent"]], $Failed],
    "CacheValidator" -> If[AssociationQ[rawCacheArtifact],
      CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
        rawCacheArtifact], False],
    "AssemblyValidator" -> If[AssociationQ[rawAssembly],
      CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        rawAssembly], False],
    "StoredExactChannelFormsFingerprint" -> If[
      AssociationQ[rawAssembly],
      Lookup[rawAssembly, "ExactChannelFormsFingerprint", $Failed],
      $Failed],
    "RecomputedExactChannelFormsFingerprint" -> If[
      exactForms === $Failed, $Failed, fingerprint[exactForms]],
    "StoredCompiledFormsFingerprint" -> If[AssociationQ[rawAssembly],
      Lookup[rawAssembly, "CompiledFormsFingerprint", $Failed], $Failed],
    "RecomputedCompiledFormsFingerprint" -> If[
      compiledForms === $Failed, $Failed, fingerprint[compiledForms]]|>];
callerContextAfter = $Context;
callerContextPathAfter = $ContextPath;

artifactNamesAfterHydration = Names[artifactContextPattern];
artifactDefinitionsAfterHydration = AssociationMap[
  definitionStateByName, artifactNamesAfterHydration];
globalStatesAfter = globalStates[];
globalFingerprintsAfter = globalFingerprints[globalStatesAfter];

expectedArtifactNames = artifactContext <> #1 & /@ {"x", "y", "eps"};
dedicatedContextGateQ = TrueQ[
  artifactNamesBeforeCreation === {} &&
  Sort[artifactNamesBeforeHydration] === Sort[expectedArtifactNames] &&
  Sort[artifactNamesAfterHydration] === Sort[expectedArtifactNames] &&
  AllTrue[Values[artifactDefinitionsBeforeHydration],
    definitionFreeStateQ] &&
  AllTrue[Values[artifactDefinitionsAfterHydration],
    definitionFreeStateQ]];
globalPoisonPinnedAndUnchangedQ = TrueQ[
  globalFingerprintsBefore === expectedGlobalPoisonFingerprints &&
  SameQ[globalStatesBefore, globalStatesAfter] &&
  SameQ[globalFingerprintsBefore, globalFingerprintsAfter]];
runtimeValueGateQ = TrueQ[
  loadsValidQ && runtimeDiagnostics["PreparationAssociationQ"] &&
  runtimeDiagnostics["PreparationStatus"] ===
    "PreparedCF300Sector12Rank2Extension" &&
  runtimeDiagnostics["PreparationValidator"] &&
  runtimeDiagnostics["PreparationVariableNames"] === {"x", "y"} &&
  runtimeDiagnostics["PreparationVariableContexts"] ===
    {artifactContext, artifactContext} &&
  runtimeDiagnostics["PreparationRegulatorName"] === "eps" &&
  runtimeDiagnostics["PreparationRegulatorContext"] === artifactContext &&
  runtimeDiagnostics["CacheAssociationQ"] &&
  runtimeDiagnostics["CacheStatus"] ===
    "DirectRootChannelCompiledArtifactV1" &&
  runtimeDiagnostics["CacheValidator"] &&
  runtimeDiagnostics["AssemblyValidator"] &&
  ! runtimeDiagnostics["GlobalContextPresentInRuntimePath"] &&
  runtimeDiagnostics["PublicReaderIntentionallyNotCalled"] &&
  runtimeDiagnostics["StoredExactChannelFormsFingerprint"] ===
    runtimeDiagnostics["RecomputedExactChannelFormsFingerprint"] ===
      expectedExactChannelFormsFingerprint &&
  runtimeDiagnostics["StoredCompiledFormsFingerprint"] ===
    runtimeDiagnostics["RecomputedCompiledFormsFingerprint"] ===
      expectedCompiledFormsFingerprint];
callerContextRestoredQ = TrueQ[
  SameQ[callerContextBefore, callerContextAfter] &&
  SameQ[callerContextPathBefore, callerContextPathAfter]];
passed = TrueQ[pinsValidQ && dedicatedContextGateQ &&
  globalPoisonPinnedAndUnchangedQ && runtimeValueGateQ &&
  callerContextRestoredQ];

diagnostics = <|
  "Status" -> "CF300DedicatedContextHydrationGateV1",
  "DriverSHA256" ->
    FileHash[$InputFileName, "SHA256", "HexString"],
  "SourceHashes" -> sourceHashes,
  "LoadOutcomes" -> loadOutcomes,
  "DedicatedArtifactContext" -> artifactContext,
  "ArtifactNamesBeforeCreation" -> artifactNamesBeforeCreation,
  "ArtifactNamesBeforeHydration" -> artifactNamesBeforeHydration,
  "ArtifactNamesAfterHydration" -> artifactNamesAfterHydration,
  "ArtifactDefinitionsBeforeHydration" ->
    artifactDefinitionsBeforeHydration,
  "ArtifactDefinitionsAfterHydration" ->
    artifactDefinitionsAfterHydration,
  "RuntimeDiagnostics" -> runtimeDiagnostics,
  "GlobalStatesBefore" -> globalStatesBefore,
  "GlobalStatesAfter" -> globalStatesAfter,
  "GlobalFingerprintsBefore" -> globalFingerprintsBefore,
  "GlobalFingerprintsAfter" -> globalFingerprintsAfter,
  "ExpectedGlobalPoisonFingerprints" ->
    expectedGlobalPoisonFingerprints,
  "DedicatedContextGateQ" -> dedicatedContextGateQ,
  "GlobalPoisonPinnedAndUnchangedQ" ->
    globalPoisonPinnedAndUnchangedQ,
  "RuntimeValueGateQ" -> runtimeValueGateQ,
  "CallerContextRestoredQ" -> callerContextRestoredQ,
  "Pass" -> passed|>;
Print["CF300_DEDICATED_HYDRATION_GATE diagnostics=",
  InputForm[diagnostics]];
Print["CF300_DEDICATED_HYDRATION_GATE pass=", passed];
gateExit[If[passed, 0, 2]];

