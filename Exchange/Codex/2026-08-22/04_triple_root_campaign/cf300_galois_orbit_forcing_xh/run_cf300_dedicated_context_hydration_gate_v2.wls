#!/usr/bin/env wolframscript

(* Adjacent V2 diagnostic gate.  Raw Get is deliberately not wrapped in
   Check: V1 proved that a message can coexist with a valid returned artifact,
   and broad Check replaced that value by $Failed. *)

$HistoryLength = 0;
BeginPackage["CodexCF300DedicatedContextHydrationGateV2`"];
Begin["`Private`"];
Quiet[ClearAll[
  "CodexCF300DedicatedContextHydrationGateV2`Private`*"]];
gateExit[code_Integer] := (End[]; EndPackage[]; System`Exit[code]);

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["CF300_DEDICATED_HYDRATION_GATE_V2 FAIL usage=<project-root> ",
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
    "DirectRootChannelCompiledArtifact.wl"}]|>;
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
    "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557"|>;
expectedPreparationHash =
  "6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4";
expectedCacheHash =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";
expectedExactFingerprint =
  "fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d";
expectedCompiledFingerprint =
  "e9f7152a0880d3ec80f80f8e0fb8aadface6ca0e094a76953ed1a3070ec039e7";
expectedGlobalPoisonFingerprints = <|
  "x" ->
    "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
  "y" ->
    "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
  "eps" ->
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968"|>;

components = {"OwnValues", "DownValues", "UpValues", "SubValues",
  "NValues", "DefaultValues", "FormatValues", "Attributes"};
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
definitionStateByName[name_String] := ToExpression[name, InputForm,
  Function[heldSymbol, definitionStateByNameHeld[heldSymbol], HoldAll]];
definitionFreeQ[state_Association] := TrueQ[
  Lookup[state, components, $Failed] ===
    ConstantArray[{}, Length[components]]];
definitionFreeQ[___] := False;

fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
globalFingerprint[value_] := Block[
  {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
  fingerprint[value]];
globalStates[] := <|"x" -> definitionState[Global`x],
  "y" -> definitionState[Global`y],
  "eps" -> definitionState[Global`eps]|>;
globalFingerprints[state_Association] := AssociationMap[
  globalFingerprint[state[#1]] &, Keys[state]];
loadSource[file_String] := Module[{value},
  value = Quiet[CheckAbort[Get[file], $Aborted]];
  <|"Status" -> Which[value === $Aborted, "Aborted",
      value === $Failed, "Failed", True, "Loaded"],
    "ReturnHead" -> ToString[Head[value], InputForm]|>];

(* Preserve both the returned value and all emitted messages. *)
rawReadWithDiagnostics[file_String] := Module[
  {value, messages},
  Block[{$MessageList = {}},
    value = Quiet[CheckAbort[Get[file], $Aborted]];
    messages = $MessageList];
  <|"Value" -> value,
    "ValueHead" -> ToString[Head[value], InputForm],
    "ValueSameQFailed" -> SameQ[value, $Failed],
    "ValueSameQAborted" -> SameQ[value, $Aborted],
    "AssociationQ" -> AssociationQ[value],
    "MessageCount" -> Length[messages],
    "Messages" -> messages|>];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile],
  Print["CF300_DEDICATED_HYDRATION_GATE_V2 FAIL missing input"];
  gateExit[65]];
sourceHashes = Map[FileHash[#1, "SHA256", "HexString"] &, files];
pinsValidQ = TrueQ[sourceHashes === expectedHashes &&
  FileHash[preparationFile, "SHA256", "HexString"] ===
    expectedPreparationHash &&
  FileHash[cacheFile, "SHA256", "HexString"] === expectedCacheHash];
If[! pinsValidQ,
  Print["CF300_DEDICATED_HYDRATION_GATE_V2 FAIL pin mismatch"];
  gateExit[66]];

globalBefore = globalStates[];
globalFingerprintsBefore = globalFingerprints[globalBefore];
loadNames = {"TripleRootAlgebra", "TripleRootStripAdapter",
  "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
  "Assembler", "ArtifactHelper"};
loadOutcomes = AssociationMap[loadSource[files[#1]] &, loadNames];
loadsValidQ = AllTrue[Lookup[Values[loadOutcomes], "Status", None],
  #1 === "Loaded" &];

artifactContext = "CodexCF300DedicatedArtifactGateV2" <>
  StringReplace[CreateUUID[], "-" -> ""] <> "`";
artifactPattern = artifactContext <> "*";
namesBeforeCreation = Names[artifactPattern];
artifactSymbolHolds = ToExpression[artifactContext <> #1,
    InputForm, HoldComplete] & /@ {"v", "w", "x", "y", "eps"};
expectedArtifactNames = artifactContext <> #1 & /@
  {"v", "w", "x", "y", "eps"};
namesBeforeHydration = Names[artifactPattern];
definitionsBeforeHydration = AssociationMap[
  definitionStateByName, namesBeforeHydration];

runtimePath = {artifactContext,
  "CodexDirectRootChannelCompiledArtifact`",
  "CodexDirectRootChannelAssembler`",
  "CodexTripleRootReconstruction`", "CodexTripleRootPilot`",
  "CodexTripleRootStrip`", "CodexTripleRoot`", "System`",
  "CodexCF300DedicatedContextHydrationGateV2`"};
callerContextBefore = $Context;
callerPathBefore = $ContextPath;
runtime = Block[{$Context = artifactContext, $ContextPath = runtimePath},
  preparationRead = rawReadWithDiagnostics[preparationFile];
  cacheRead = rawReadWithDiagnostics[cacheFile];
  preparationArtifact = preparationRead["Value"];
  cacheArtifact = cacheRead["Value"];
  preparation = If[AssociationQ[preparationArtifact],
    Lookup[preparationArtifact, "Preparation", $Failed], $Failed];
  assembly = If[AssociationQ[cacheArtifact],
    Lookup[cacheArtifact, "DirectAssembly", $Failed], $Failed];
  exactForms = If[AssociationQ[assembly],
    Lookup[assembly, "ExactChannelForms", $Failed], $Failed];
  compiledForms = If[AssociationQ[assembly],
    Lookup[assembly, "CompiledForms", $Failed], $Failed];
  variables = If[AssociationQ[preparation],
    Lookup[preparation, "Variables", $Failed], $Failed];
  regulator = If[AssociationQ[preparation],
    Lookup[preparation, "Regulator", $Failed], $Failed];
  <|"RuntimeContext" -> $Context, "RuntimeContextPath" -> $ContextPath,
    "GlobalContextPresentInRuntimePath" ->
      MemberQ[$ContextPath, "Global`"],
    "LoadFACETPinnedButIntentionallyNotLoaded" -> True,
    "InitializationMatchesPriorSuccessfulHydrationProbe" -> True,
    "PublicReaderIntentionallyNotCalled" -> True,
    "PublicReaderExclusionReason" ->
      "DRCAReadCompiledArtifact hardcodes Global context hydration",
    "PreparationRawRead" -> KeyDrop[preparationRead, "Value"],
    "CacheRawRead" -> KeyDrop[cacheRead, "Value"],
    "PreparationAssociationQ" -> AssociationQ[preparationArtifact],
    "PreparationStatus" -> If[AssociationQ[preparationArtifact],
      Lookup[preparationArtifact, "Status", Missing["Absent"]], $Failed],
    "PreparationValidator" -> If[AssociationQ[preparation],
      CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation],
      False],
    "VariableNames" -> If[ListQ[variables],
      SymbolName /@ variables, $Failed],
    "VariableContexts" -> If[ListQ[variables],
      Context /@ variables, $Failed],
    "RegulatorName" -> If[MatchQ[regulator, _Symbol],
      SymbolName[regulator], $Failed],
    "RegulatorContext" -> If[MatchQ[regulator, _Symbol],
      Context[regulator], $Failed],
    "CacheAssociationQ" -> AssociationQ[cacheArtifact],
    "CacheStatus" -> If[AssociationQ[cacheArtifact],
      Lookup[cacheArtifact, "Status", Missing["Absent"]], $Failed],
    "CacheValidator" -> If[AssociationQ[cacheArtifact],
      CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
        cacheArtifact], False],
    "AssemblyValidator" -> If[AssociationQ[assembly],
      CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        assembly], False],
    "StoredExactFingerprint" -> If[AssociationQ[assembly],
      Lookup[assembly, "ExactChannelFormsFingerprint", $Failed], $Failed],
    "RecomputedExactFingerprint" -> If[exactForms === $Failed,
      $Failed, fingerprint[exactForms]],
    "StoredCompiledFingerprint" -> If[AssociationQ[assembly],
      Lookup[assembly, "CompiledFormsFingerprint", $Failed], $Failed],
    "RecomputedCompiledFingerprint" -> If[compiledForms === $Failed,
      $Failed, fingerprint[compiledForms]]|>];
callerContextAfter = $Context;
callerPathAfter = $ContextPath;

namesAfterHydration = Names[artifactPattern];
definitionsAfterHydration = AssociationMap[
  definitionStateByName, namesAfterHydration];
globalAfter = globalStates[];
globalFingerprintsAfter = globalFingerprints[globalAfter];
dedicatedContextQ = TrueQ[namesBeforeCreation === {} &&
  Sort[namesBeforeHydration] === Sort[expectedArtifactNames] &&
  Sort[namesAfterHydration] === Sort[expectedArtifactNames] &&
  AllTrue[Join[Values[definitionsBeforeHydration],
    Values[definitionsAfterHydration]], definitionFreeQ]];
globalPinnedUnchangedQ = TrueQ[
  globalFingerprintsBefore === expectedGlobalPoisonFingerprints &&
  SameQ[globalBefore, globalAfter] &&
  SameQ[globalFingerprintsBefore, globalFingerprintsAfter]];
runtimeQ = TrueQ[loadsValidQ &&
  ! runtime["GlobalContextPresentInRuntimePath"] &&
  runtime["LoadFACETPinnedButIntentionallyNotLoaded"] &&
  runtime["InitializationMatchesPriorSuccessfulHydrationProbe"] &&
  runtime["PublicReaderIntentionallyNotCalled"] &&
  runtime["PreparationAssociationQ"] &&
  runtime["PreparationStatus"] ===
    "PreparedCF300Sector12Rank2Extension" &&
  runtime["PreparationValidator"] &&
  runtime["VariableNames"] === {"x", "y"} &&
  runtime["VariableContexts"] === {artifactContext, artifactContext} &&
  runtime["RegulatorName"] === "eps" &&
  runtime["RegulatorContext"] === artifactContext &&
  runtime["CacheAssociationQ"] &&
  runtime["CacheStatus"] === "DirectRootChannelCompiledArtifactV1" &&
  runtime["CacheValidator"] && runtime["AssemblyValidator"] &&
  runtime["StoredExactFingerprint"] ===
    runtime["RecomputedExactFingerprint"] === expectedExactFingerprint &&
  runtime["StoredCompiledFingerprint"] ===
    runtime["RecomputedCompiledFingerprint"] ===
      expectedCompiledFingerprint];
callerRestoredQ = TrueQ[SameQ[callerContextBefore, callerContextAfter] &&
  SameQ[callerPathBefore, callerPathAfter]];
passed = TrueQ[pinsValidQ && dedicatedContextQ &&
  globalPinnedUnchangedQ && runtimeQ && callerRestoredQ];

diagnostics = <|"Status" -> "CF300DedicatedContextHydrationGateV2",
  "DriverSHA256" -> FileHash[$InputFileName, "SHA256", "HexString"],
  "SourceHashes" -> sourceHashes, "LoadOutcomes" -> loadOutcomes,
  "DedicatedArtifactContext" -> artifactContext,
  "ExpectedArtifactNames" -> expectedArtifactNames,
  "NamesBeforeCreation" -> namesBeforeCreation,
  "NamesBeforeHydration" -> namesBeforeHydration,
  "NamesAfterHydration" -> namesAfterHydration,
  "DefinitionsBeforeHydration" -> definitionsBeforeHydration,
  "DefinitionsAfterHydration" -> definitionsAfterHydration,
  "RuntimeDiagnostics" -> runtime,
  "GlobalStatesBefore" -> globalBefore,
  "GlobalStatesAfter" -> globalAfter,
  "GlobalFingerprintsBefore" -> globalFingerprintsBefore,
  "GlobalFingerprintsAfter" -> globalFingerprintsAfter,
  "DedicatedContextGateQ" -> dedicatedContextQ,
  "GlobalPoisonPinnedAndUnchangedQ" -> globalPinnedUnchangedQ,
  "RuntimeValueGateQ" -> runtimeQ,
  "CallerContextRestoredQ" -> callerRestoredQ, "Pass" -> passed|>;
Print["CF300_DEDICATED_HYDRATION_GATE_V2 diagnostics=",
  InputForm[diagnostics]];
Print["CF300_DEDICATED_HYDRATION_GATE_V2 pass=", passed];
gateExit[If[passed, 0, 2]];

