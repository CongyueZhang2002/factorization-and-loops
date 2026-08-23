#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300ArtifactHydrationContextProbeV1`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300ArtifactHydrationContextProbeV1`Private`*"]];
probeExit[code_Integer] := (End[]; EndPackage[]; System`Exit[code]);

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 4,
  Print["CF300_HYDRATION_PROBE FAIL usage=<project-root> " <>
    "<preparation.wl> <compiled-cache.wl> <denominator-census.wl>"];
  probeExit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
censusFile = ExpandFileName[arguments[[4]]];
driverDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[driverDirectory];
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
expectedCensusHash =
  "c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a";

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
loadSource[file_String] := Quiet[Check[Get[file], $Failed]];
artifactRead[file_String] := Block[
  {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
  Quiet[Check[Get[file], $Failed]]];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

If[! DirectoryQ[projectRoot] || ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    ! FileExistsQ[censusFile],
  Print["CF300_HYDRATION_PROBE FAIL invalid inputs"];
  probeExit[65]];
driverHash = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashes = hashes[];
If[sourceHashes =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationHash ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheHash ||
    FileHash[censusFile, "SHA256", "HexString"] =!= expectedCensusHash,
  Print["CF300_HYDRATION_PROBE FAIL pin mismatch"];
  probeExit[66]];

Internal`InheritedBlock[{Global`x, Global`y, Global`eps},
  Block[{$Context = "Global`",
    $ContextPath = {"System`", "Global`",
      "CodexCF300ArtifactHydrationContextProbeV1`"}},
    loadResults = AssociationMap[loadSource[files[#1]] &,
      {"TripleRootAlgebra", "TripleRootStripAdapter",
       "TripleRootAffinePilot", "TripleRootReconstructionPrototype",
       "Assembler", "ArtifactHelper"}];
    If[MemberQ[Values[loadResults], $Failed],
      Print["CF300_HYDRATION_PROBE FAIL source load"];
      probeExit[67]];
    preparationRaw = artifactRead[preparationFile];
    cacheRaw = artifactRead[cacheFile];
    censusRaw = artifactRead[censusFile];
    cacheReadCanonical =
      CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
        cacheFile];
    cacheReadIsolated = Block[
      {$Context =
        "CodexCF300ArtifactHydrationContextProbeV1`Private`",
       $ContextPath = {
        "CodexCF300ArtifactHydrationContextProbeV1`", "System`"}},
      CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
        cacheFile]];
    assembly = If[AssociationQ[cacheRaw],
      Lookup[cacheRaw, "DirectAssembly", $Failed], $Failed];
    exactForms = If[AssociationQ[assembly],
      Lookup[assembly, "ExactChannelForms", $Failed], $Failed];
    storedExactFingerprint = If[AssociationQ[assembly],
      Lookup[assembly, "ExactChannelFormsFingerprint", $Failed], $Failed];
    canonicalExactFingerprint = If[exactForms === $Failed, $Failed,
      fingerprint[exactForms]];
    isolatedExactFingerprint = If[exactForms === $Failed, $Failed,
      Block[{$Context =
          "CodexCF300ArtifactHydrationContextProbeV1`Private`",
        $ContextPath = {
          "CodexCF300ArtifactHydrationContextProbeV1`", "System`"}},
        fingerprint[exactForms]]];
    preparation = If[AssociationQ[preparationRaw],
      Lookup[preparationRaw, "Preparation", $Failed], $Failed];
    variables = If[AssociationQ[preparation],
      Lookup[preparation, "Variables", $Failed], $Failed];
    regulator = If[AssociationQ[preparation],
      Lookup[preparation, "Regulator", $Failed], $Failed];
    diagnostics = <|
      "Status" -> "CF300ArtifactHydrationContextProbeV1",
      "DriverSHA256" -> driverHash,
      "SourceHashesMatch" -> (hashes[] === sourceHashes),
      "RuntimeContext" -> $Context,
      "RuntimeContextPath" -> $ContextPath,
      "PreparationAssociationQ" -> AssociationQ[preparationRaw],
      "PreparationStatus" -> If[AssociationQ[preparationRaw],
        Lookup[preparationRaw, "Status", Missing["Absent"]], $Failed],
      "PreparationVariablesHeld" -> ToString[
        InputForm[HoldComplete[variables]]],
      "PreparationVariableContexts" -> If[ListQ[variables],
        Context /@ Unevaluated[variables], $Failed],
      "PreparationRegulatorHeld" -> ToString[
        InputForm[HoldComplete[regulator]]],
      "RawCacheAssociationQ" -> AssociationQ[cacheRaw],
      "RawCacheStatus" -> If[AssociationQ[cacheRaw],
        Lookup[cacheRaw, "Status", Missing["Absent"]], $Failed],
      "RawCachePublicValidatorCanonical" ->
        If[AssociationQ[cacheRaw],
          CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
            cacheRaw], False],
      "RawAssemblyPublicValidatorCanonical" ->
        If[AssociationQ[assembly],
          CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
            assembly], False],
      "ReaderCanonicalAssociationQ" ->
        AssociationQ[cacheReadCanonical],
      "ReaderCanonicalStatus" -> If[AssociationQ[cacheReadCanonical],
        Lookup[cacheReadCanonical, "Status", Missing["Absent"]],
        cacheReadCanonical],
      "ReaderIsolatedAssociationQ" -> AssociationQ[cacheReadIsolated],
      "ReaderIsolatedStatus" -> If[AssociationQ[cacheReadIsolated],
        Lookup[cacheReadIsolated, "Status", Missing["Absent"]],
        cacheReadIsolated],
      "StoredExactChannelFormsFingerprint" -> storedExactFingerprint,
      "CanonicalExactChannelFormsFingerprint" ->
        canonicalExactFingerprint,
      "IsolatedExactChannelFormsFingerprint" ->
        isolatedExactFingerprint,
      "CanonicalExactFingerprintMatchesStored" ->
        (canonicalExactFingerprint === storedExactFingerprint),
      "IsolatedExactFingerprintMatchesStored" ->
        (isolatedExactFingerprint === storedExactFingerprint),
      "CensusAssociationQ" -> AssociationQ[censusRaw],
      "CensusStatus" -> If[AssociationQ[censusRaw],
        Lookup[censusRaw, "Status", Missing["Absent"]], $Failed]|>;
    Print["CF300_HYDRATION_PROBE_DIAGNOSTICS ",
      InputForm[diagnostics]];
    expected = TrueQ[
      diagnostics["PreparationStatus"] ===
          "PreparedCF300Sector12Rank2Extension" &&
      diagnostics["RawCacheStatus"] ===
          "DirectRootChannelCompiledArtifactV1" &&
      diagnostics["RawCachePublicValidatorCanonical"] &&
      diagnostics["ReaderCanonicalAssociationQ"] &&
      diagnostics["CanonicalExactFingerprintMatchesStored"] &&
      ! diagnostics["ReaderIsolatedAssociationQ"] &&
      ! diagnostics["IsolatedExactFingerprintMatchesStored"] &&
      diagnostics["CensusStatus"] ===
          "CF300Sector12DenominatorCensusPassed"];
    Print["CF300_HYDRATION_PROBE expected_context_sensitivity=",
      expected];
    probeExit[If[expected, 0, 2]]]];
