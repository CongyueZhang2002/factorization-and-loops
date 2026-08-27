#!/usr/bin/env wolframscript

BeginPackage["CodexCF300ArtifactDedicatedContextProbeV1`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300ArtifactDedicatedContextProbeV1`Private`*"]];

probeBootstrapExit[code_Integer] :=
  (End[]; EndPackage[];
   Quiet[Remove["CodexCF300ArtifactDedicatedContextProbeV1`*"]];
   System`Exit[code]);

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 4,
  Print["CF300_DEDICATED_HYDRATION_PROBE FAIL usage=<project-root> " <>
    "<preparation.wl> <compiled-cache.wl> <denominator-census.wl>"];
  probeBootstrapExit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
censusFile = ExpandFileName[arguments[[4]]];
driverDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[driverDirectory];
directDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];
artifactContext = "CodexCF300ArtifactSymbolsHydrationProbeV1`";

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
expectedCensusHash =
  "c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a";

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
loadSource[file_String] := Quiet[Check[Get[file], $Failed]];
artifactReadActive[file_String] := If[! FileExistsQ[file], $Failed,
  Quiet[Check[Get[file], $Failed]]];
artifactReadValidatedActive[file_String] := Module[{artifact},
  artifact = artifactReadActive[file];
  If[AssociationQ[artifact] &&
      TrueQ[CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
        artifact]],
    artifact, $Failed]
];
globalDefinitionSnapshot[] := <|
  "x" -> <|
    "OwnValues" -> OwnValues[Global`x],
    "DownValues" -> DownValues[Global`x],
    "UpValues" -> UpValues[Global`x],
    "SubValues" -> SubValues[Global`x],
    "NValues" -> NValues[Global`x],
    "DefaultValues" -> DefaultValues[Global`x],
    "FormatValues" -> FormatValues[Global`x],
    "Attributes" -> Attributes[Global`x]|>,
  "y" -> <|
    "OwnValues" -> OwnValues[Global`y],
    "DownValues" -> DownValues[Global`y],
    "UpValues" -> UpValues[Global`y],
    "SubValues" -> SubValues[Global`y],
    "NValues" -> NValues[Global`y],
    "DefaultValues" -> DefaultValues[Global`y],
    "FormatValues" -> FormatValues[Global`y],
    "Attributes" -> Attributes[Global`y]|>,
  "eps" -> <|
    "OwnValues" -> OwnValues[Global`eps],
    "DownValues" -> DownValues[Global`eps],
    "UpValues" -> UpValues[Global`eps],
    "SubValues" -> SubValues[Global`eps],
    "NValues" -> NValues[Global`eps],
    "DefaultValues" -> DefaultValues[Global`eps],
    "FormatValues" -> FormatValues[Global`eps],
    "Attributes" -> Attributes[Global`eps]|>|>;
dedicatedSymbolsCleanQ[] := And @@ (
  OwnValues[#1] === {} && DownValues[#1] === {} &&
  UpValues[#1] === {} && SubValues[#1] === {} &&
  NValues[#1] === {} && DefaultValues[#1] === {} &&
  FormatValues[#1] === {} && Attributes[#1] === {} & /@
    Unevaluated[{Symbol[artifactContext <> "x"],
      Symbol[artifactContext <> "y"],
      Symbol[artifactContext <> "eps"]}]);
removeDedicatedContext[] := Module[{outcome},
  outcome = Quiet[Check[Remove[artifactContext <> "*"], $Failed]];
  TrueQ[outcome =!= $Failed && Names[artifactContext <> "*"] === {}]
];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    ! FileExistsQ[censusFile],
  Print["CF300_DEDICATED_HYDRATION_PROBE FAIL invalid inputs"];
  probeBootstrapExit[65]];
driverHash = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashes = hashes[];
If[sourceHashes =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash ||
    FileHash[censusFile, "SHA256", "HexString"] =!= expectedCensusHash,
  Print["CF300_DEDICATED_HYDRATION_PROBE FAIL pin mismatch"];
  probeBootstrapExit[66]];
If[Names[artifactContext <> "*"] =!= {},
  Print["CF300_DEDICATED_HYDRATION_PROBE FAIL context preexists names=",
    InputForm[Names[artifactContext <> "*"]]];
  probeBootstrapExit[67]];

globalBefore = globalDefinitionSnapshot[];
scopeOutcome = CheckAbort[
  Block[{$Context = artifactContext,
      $ContextPath = {"System`", artifactContext,
        "CodexCF300ArtifactDedicatedContextProbeV1`"}},
    loadResults = AssociationMap[loadSource[files[#1]] &,
      {"TripleRootAlgebra", "TripleRootStripAdapter",
       "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
       "Assembler", "ArtifactHelper"}];
    If[MemberQ[Values[loadResults], $Failed],
      <|"Code" -> 68, "Reason" -> "SourceLoadFailed",
        "LoadResults" -> loadResults|>,
      preparationRaw = artifactReadActive[preparationFile];
      cacheRaw = artifactReadActive[cacheFile];
      cacheReadDedicated = artifactReadValidatedActive[cacheFile];
      censusRaw = artifactReadActive[censusFile];
      preparation = If[AssociationQ[preparationRaw],
        Lookup[preparationRaw, "Preparation", $Failed], $Failed];
      variables = If[AssociationQ[preparation],
        Lookup[preparation, "Variables", $Failed], $Failed];
      regulator = If[AssociationQ[preparation],
        Lookup[preparation, "Regulator", $Failed], $Failed];
      assembly = If[AssociationQ[cacheRaw],
        Lookup[cacheRaw, "DirectAssembly", $Failed], $Failed];
      exactForms = If[AssociationQ[assembly],
        Lookup[assembly, "ExactChannelForms", $Failed], $Failed];
      storedExactFingerprint = If[AssociationQ[assembly],
        Lookup[assembly, "ExactChannelFormsFingerprint", $Failed],
        $Failed];
      activeExactFingerprint = If[exactForms === $Failed, $Failed,
        fingerprint[exactForms]];
      dedicatedX = Symbol[artifactContext <> "x"];
      dedicatedY = Symbol[artifactContext <> "y"];
      dedicatedEps = Symbol[artifactContext <> "eps"];
      diagnostics = <|
        "Status" -> "CF300ArtifactDedicatedContextProbeV1",
        "DriverSHA256" -> driverHash,
        "SourceHashesMatch" -> (hashes[] === sourceHashes),
        "ArtifactContext" -> artifactContext,
        "RuntimeContext" -> $Context,
        "RuntimeContextPath" -> $ContextPath,
        "ArtifactContextVisibleQ" -> MemberQ[$ContextPath, artifactContext],
        "GlobalStateUnchangedInsideScopeQ" ->
          SameQ[globalDefinitionSnapshot[], globalBefore],
        "PreparationAssociationQ" -> AssociationQ[preparationRaw],
        "PreparationStatus" -> If[AssociationQ[preparationRaw],
          Lookup[preparationRaw, "Status", Missing["Absent"]], $Failed],
        "PreparationVariablesHeld" -> ToString[
          InputForm[HoldComplete[variables]]],
        "PreparationVariableContexts" -> If[ListQ[variables],
          Context /@ Unevaluated[variables], $Failed],
        "PreparationVariablesDedicatedQ" ->
          SameQ[variables, {dedicatedX, dedicatedY}],
        "PreparationRegulatorHeld" -> ToString[
          InputForm[HoldComplete[regulator]]],
        "PreparationRegulatorContext" -> If[Head[Unevaluated[regulator]] ===
            Symbol, Context[Unevaluated[regulator]], $Failed],
        "PreparationRegulatorDedicatedQ" -> SameQ[regulator, dedicatedEps],
        "DedicatedSymbolsDefinitionFreeQ" -> dedicatedSymbolsCleanQ[],
        "RawCacheAssociationQ" -> AssociationQ[cacheRaw],
        "RawCacheStatus" -> If[AssociationQ[cacheRaw],
          Lookup[cacheRaw, "Status", Missing["Absent"]], $Failed],
        "RawCachePublicValidatorDedicatedQ" -> If[AssociationQ[cacheRaw],
          TrueQ[
            CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
              cacheRaw]], False],
        "RawAssemblyPublicValidatorDedicatedQ" -> If[AssociationQ[assembly],
          TrueQ[
            CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
              assembly]], False],
        "PreparationPublicValidatorDedicatedQ" ->
          If[AssociationQ[preparation],
            TrueQ[
              CodexTripleRootReconstruction`TRPreparationABIValidQ[
                preparation]], False],
        "DedicatedReaderAssociationQ" -> AssociationQ[cacheReadDedicated],
        "DedicatedReaderSameAsRawQ" -> SameQ[cacheReadDedicated, cacheRaw],
        "StoredExactChannelFormsFingerprint" -> storedExactFingerprint,
        "DedicatedExactChannelFormsFingerprint" -> activeExactFingerprint,
        "DedicatedExactFingerprintMatchesStoredQ" ->
          SameQ[activeExactFingerprint, storedExactFingerprint],
        "CensusAssociationQ" -> AssociationQ[censusRaw],
        "CensusStatus" -> If[AssociationQ[censusRaw],
          Lookup[censusRaw, "Status", Missing["Absent"]], $Failed]|>;
      expected = TrueQ[
        diagnostics["SourceHashesMatch"] &&
        diagnostics["ArtifactContextVisibleQ"] &&
        diagnostics["GlobalStateUnchangedInsideScopeQ"] &&
        diagnostics["PreparationStatus"] ===
          "PreparedCF300Sector12Rank2Extension" &&
        diagnostics["PreparationVariablesDedicatedQ"] &&
        diagnostics["PreparationRegulatorDedicatedQ"] &&
        diagnostics["DedicatedSymbolsDefinitionFreeQ"] &&
        diagnostics["RawCacheStatus"] ===
          "DirectRootChannelCompiledArtifactV1" &&
        diagnostics["RawCachePublicValidatorDedicatedQ"] &&
        diagnostics["RawAssemblyPublicValidatorDedicatedQ"] &&
        diagnostics["PreparationPublicValidatorDedicatedQ"] &&
        diagnostics["DedicatedReaderAssociationQ"] &&
        diagnostics["DedicatedReaderSameAsRawQ"] &&
        diagnostics["DedicatedExactFingerprintMatchesStoredQ"] &&
        diagnostics["CensusStatus"] ===
          "CF300Sector12DenominatorCensusPassed"];
      <|"Code" -> If[expected, 0, 2], "Reason" ->
          If[expected, "DedicatedContextHydrationPassed",
            "DedicatedContextHydrationFailed"],
        "Diagnostics" -> diagnostics|>]],
  removeDedicatedContext[];
  Abort[]];

cleanupPassed = removeDedicatedContext[];
globalAfter = globalDefinitionSnapshot[];
globalRestoredQ = SameQ[globalAfter, globalBefore];
Print["CF300_DEDICATED_HYDRATION_PROBE diagnostics=",
  InputForm[Lookup[scopeOutcome, "Diagnostics", scopeOutcome]]];
Print["CF300_DEDICATED_HYDRATION_PROBE cleanup=",
  InputForm[<|"DedicatedContextRemovedQ" -> cleanupPassed,
    "GlobalStateUnchangedAfterScopeQ" -> globalRestoredQ,
    "RemainingDedicatedNames" -> Names[artifactContext <> "*"]|>]];
finalCode = If[AssociationQ[scopeOutcome] &&
    IntegerQ[Lookup[scopeOutcome, "Code", None]] && cleanupPassed &&
    globalRestoredQ, Lookup[scopeOutcome, "Code"], 99];
probeBootstrapExit[finalCode];
