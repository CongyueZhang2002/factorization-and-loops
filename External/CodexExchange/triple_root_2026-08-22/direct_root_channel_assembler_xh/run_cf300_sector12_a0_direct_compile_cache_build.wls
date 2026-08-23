#!/usr/bin/env wolframscript

$HistoryLength = 0;
campaignStartTime = AbsoluteTime[];
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["CF300_A0_DRCA_CACHE_BUILD FAIL usage=<project-root> <preparation.wl> " <>
    "<fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelAssembler.wl"}];
artifactHelperFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelCompiledArtifact.wl"}];
expectedPreparationSHA256 =
  "a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6";
expectedAssemblerSHA256 =
  "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6";
expectedArtifactHelperSHA256 =
  "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557";
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet",
    "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldStripSolve.wl"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldEpsForm.wl"}],
  "FamilyEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FamilyEpsForm.wl"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "TransportCharts.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}]|>;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[preparationFile] ||
    ! FileExistsQ[assemblerFile] || ! FileExistsQ[artifactHelperFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]],
  Exit[65]];

writeAtomic[value_] := Module[{temporary, written, renamed},
  If[FileExistsQ[outputFile], Return[$Failed]];
  temporary = outputFile <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], $Failed, outputFile]
];
finish[status_String, data_: <||>, code_: 1] := Module[
  {report, failureMessages = None, diagnostics = <||>},
  If[ValueQ[runtimeMessageStream] &&
      MatchQ[runtimeMessageStream, _OutputStream],
    Quiet[Close[runtimeMessageStream]];
    failureMessages = Quiet[Check[
      Import[runtimeMessageFile, "Text"], $Failed]];
    If[FileExistsQ[runtimeMessageFile],
      Quiet[DeleteFile[runtimeMessageFile]]];
    diagnostics = <|"CapturedFailureMessages" -> failureMessages|>];
  report = Join[<|"Status" -> status,
    "PreparationFile" -> preparationFile|>, diagnostics, data];
  If[writeAtomic[report] === $Failed, Exit[98]];
  Print["CF300_A0_DRCA_CACHE_BUILD status=", status, " output=", outputFile];
  Exit[code]
];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

preparationHashBefore = FileHash[preparationFile,
  "SHA256", "HexString"];
dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
assemblerHashBefore = FileHash[assemblerFile, "SHA256", "HexString"];
artifactHelperHashBefore = FileHash[artifactHelperFile,
  "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
expectedHashes = <|"Preparation" -> preparationHashBefore,
  "Dependencies" -> dependencyHashesBefore,
  "Assembler" -> assemblerHashBefore,
  "ArtifactHelper" -> artifactHelperHashBefore,
  "Driver" -> driverHashBefore|>;
sourceHashes[] := <|
  "Preparation" -> FileHash[preparationFile, "SHA256", "HexString"],
  "Dependencies" -> Map[
    FileHash[#1, "SHA256", "HexString"] &, dependencyFiles],
  "Assembler" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "ArtifactHelper" -> FileHash[artifactHelperFile,
    "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;

If[preparationHashBefore =!= expectedPreparationSHA256 ||
    assemblerHashBefore =!= expectedAssemblerSHA256 ||
    artifactHelperHashBefore =!= expectedArtifactHelperSHA256,
  finish["PinnedCacheBuilderSourceMismatch", <||>, 66]];

savedMessages = $Messages;
loadMessageFile = outputFile <> ".load-messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
loadMessageStream = OpenWrite[loadMessageFile, CharacterEncoding -> "UTF8"];
$Messages = {loadMessageStream};
loadOutcome = Check[
  Get[dependencyFiles["LoadFACET"]];
  Get[dependencyFiles["TripleRootAlgebra"]];
  Get[dependencyFiles["TripleRootStripAdapter"]];
  Get[dependencyFiles["TripleRootAffinePilot"]];
  Get[dependencyFiles["TripleRootReconstructionPrototype"]];
  Get[assemblerFile];
  Get[artifactHelperFile];
  True, $Failed];
Close[loadMessageStream];
$Messages = savedMessages;
loadMessages = Quiet[Check[Import[loadMessageFile, "Text"], $Failed]];
If[FileExistsQ[loadMessageFile], Quiet[DeleteFile[loadMessageFile]]];
If[loadOutcome =!= True || ! StringQ[loadMessages] ||
    StringTrim[loadMessages] =!= "" || sourceHashes[] =!= expectedHashes,
  finish["CF300A0DirectComparisonLoadFailed", <|
    "LoadOutcome" -> loadOutcome, "CapturedLoadMessages" -> loadMessages,
    "ExpectedSourceHashes" -> expectedHashes,
    "ObservedSourceHashes" -> sourceHashes[]|>, 66]];

runtimeMessageFile = outputFile <> ".runtime-messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
runtimeMessageStream = OpenWrite[runtimeMessageFile,
  CharacterEncoding -> "UTF8"];
$Messages = {runtimeMessageStream};
Print["CF300_A0_DRCA_CACHE_BUILD milestone=load_complete elapsed_s=",
  N[AbsoluteTime[] - campaignStartTime]];

preparationArtifact = FeynFacet`FamilyArtifactRead[preparationFile];
preparationArtifactKeys = {"Status", "InputFile", "InputSHA256",
  "DriverFile", "DriverSHA256", "DependencyHashes", "SidecarCertificate",
  "RegulatorClearFactor", "PreparationSeconds", "RootOrderingFingerprint",
  "OneFormOrderFingerprint", "Preparation", "PreparationSummary"};
If[! AssociationQ[preparationArtifact] ||
    ! AllTrue[preparationArtifactKeys,
      KeyExistsQ[preparationArtifact, #1] &] ||
    preparationArtifact["Status"] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    preparationArtifact["DependencyHashes"] =!= dependencyHashesBefore,
  finish["PreparationArtifactInvalid", <||>, 67]];
preparationDriverFile = preparationArtifact["DriverFile"];
inputFile = preparationArtifact["InputFile"];
If[! StringQ[preparationDriverFile] ||
    ! FileExistsQ[preparationDriverFile] ||
    FileHash[preparationDriverFile, "SHA256", "HexString"] =!=
      preparationArtifact["DriverSHA256"] ||
    ! StringQ[inputFile] || ! FileExistsQ[inputFile] ||
    FileHash[inputFile, "SHA256", "HexString"] =!=
      preparationArtifact["InputSHA256"],
  finish["PreparationProvenanceInvalid", <||>, 68]];
recursiveSourceHashesExpected = <|
  "PreparationDriver" -> preparationArtifact["DriverSHA256"],
  "PreparationInput" -> preparationArtifact["InputSHA256"]|>;
preparation = preparationArtifact["Preparation"];
summaryKeys = {"RootCount", "GradeCount", "RootSourceIndices",
  "RootFingerprints", "RootOrderingFingerprint", "Dimensions",
  "OneFormMetadata", "GaugeDenominator", "GaugeDenominatorDegrees",
  "GaugeSupport", "GaugeUnknownCount", "ResidueUnknownCount",
  "UnknownCount", "EquationsPerPoint", "ABIFingerprint"};
If[! AssociationQ[preparation] ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation] ||
    preparation["RootCount"] =!= 2 || preparation["GradeCount"] =!= 4 ||
    preparation["RootSourceIndices"] =!= {2, 3} ||
    preparation["Dimensions"] =!= {2, 2} ||
    preparation["Normalizations"] =!= {} ||
    preparation["GaugeUnknownCount"] =!= 480 ||
    preparation["ResidueUnknownCount"] =!= 144 ||
    preparation["UnknownCount"] =!= 624 ||
    preparation["EquationsPerPoint"] =!= 32 ||
    Length[preparation["GaugeSupport"]] =!= 30 ||
    preparationArtifact["RootOrderingFingerprint"] =!=
      preparation["RootOrderingFingerprint"] ||
    preparationArtifact["OneFormOrderFingerprint"] =!=
      fingerprint[preparation["ABIPayload", "OneForms"]] ||
    preparationArtifact["PreparationSummary"] =!=
      KeyTake[preparation, summaryKeys] ||
    TrueQ[Together[preparationArtifact["RegulatorClearFactor"]] === 0],
  finish["PreparationABIOrShapeInvalid", <||>, 69]];
sidecar = preparationArtifact["SidecarCertificate"];
sidecarKeys = {"RoundTripExact", "RoundTripSeconds",
  "ChannelEquationFingerprint", "SupportFingerprint",
  "TermGraphFingerprint", "ActiveGrades", "ActiveGradeRank",
  "GlobalRootSourceOrder", "StableLocalRootSourceOrder",
  "LocalToGlobalGradeMap", "LocalSquareClassCertificate"};
squareClass = If[AssociationQ[sidecar],
  Lookup[sidecar, "LocalSquareClassCertificate", $Failed], $Failed];
expectedGradeMap = Table[localMask -> Sum[
    BitGet[localMask, bit - 1] *
      2^(preparation["RootSourceIndices"][[bit]] - 1),
    {bit, preparation["RootCount"]}],
  {localMask, 0, preparation["GradeCount"] - 1}];
If[! AssociationQ[sidecar] ||
    ! AllTrue[sidecarKeys, KeyExistsQ[sidecar, #1] &] ||
    ! TrueQ[sidecar["RoundTripExact"]] ||
    ! AllTrue[{"ChannelEquationFingerprint", "SupportFingerprint",
        "TermGraphFingerprint"}, StringQ[sidecar[#1]] &] ||
    sidecar["ActiveGrades"] =!= {0, 2, 4} ||
    sidecar["ActiveGradeRank"] =!= 2 ||
    sidecar["StableLocalRootSourceOrder"] =!= {2, 3} ||
    sidecar["LocalToGlobalGradeMap"] =!= expectedGradeMap ||
    ! AssociationQ[squareClass] ||
    ! TrueQ[Lookup[squareClass, "Independent", False]] ||
    Lookup[squareClass, "Rank", None] =!= 2,
  finish["SidecarCertificateInvalid", <||>, 69]];

Print["CF300_A0_DRCA_CACHE_BUILD milestone=compile_start"];
{compileSeconds, directPreparation} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCAPrepare[preparation]];
If[Lookup[directPreparation, "Status", None] =!=
      "PreparedDirectRootChannelsV1" ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      directPreparation] ||
    directPreparation["SourceABIFingerprint"] =!=
      preparation["ABIFingerprint"] ||
    directPreparation["UnknownCount"] =!= 624 ||
    directPreparation["EquationsPerPoint"] =!= 32,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["DirectCacheCompilationFailed", <||>, 70]];
Print["CF300_A0_DRCA_CACHE_BUILD milestone=compile_complete compile_s=",
  compileSeconds];

completionHashes = sourceHashes[];
recursiveSourceHashesAtCompletion = <|
  "PreparationDriver" -> FileHash[preparationDriverFile,
    "SHA256", "HexString"],
  "PreparationInput" -> FileHash[inputFile, "SHA256", "HexString"]|>;
hashesStable = TrueQ[completionHashes === expectedHashes &&
  recursiveSourceHashesAtCompletion === recursiveSourceHashesExpected];
provenance = <|
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> preparationHashBefore,
  "PreparationInputFile" -> inputFile,
  "PreparationInputSHA256" -> preparationArtifact["InputSHA256"],
  "PreparationDriverFile" -> preparationDriverFile,
  "PreparationDriverSHA256" -> preparationArtifact["DriverSHA256"],
  "BuilderDriverFile" -> $InputFileName,
  "BuilderDriverSHA256" -> driverHashBefore,
  "RuntimeSourceHashes" -> expectedHashes,
  "RecursiveSourceHashes" -> recursiveSourceHashesExpected,
  "CompilationSeconds" -> compileSeconds|>;
compiledArtifact =
  CodexDirectRootChannelCompiledArtifact`DRCACreateCompiledArtifact[
    directPreparation, provenance];
If[! hashesStable || ! AssociationQ[compiledArtifact] ||
    ! CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
      compiledArtifact],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["DirectCacheArtifactConstructionFailed", <|
    "HashesStable" -> hashesStable|>, 71]];

Close[runtimeMessageStream];
$Messages = savedMessages;
runtimeMessages = Quiet[Check[Import[runtimeMessageFile, "Text"], $Failed]];
If[FileExistsQ[runtimeMessageFile], Quiet[DeleteFile[runtimeMessageFile]]];
If[! StringQ[runtimeMessages] || StringTrim[runtimeMessages] =!= "" ||
    sourceHashes[] =!= expectedHashes,
  finish["DirectCacheBuilderRuntimeGateFailed", <|
    "CapturedRuntimeMessages" -> runtimeMessages|>, 72]];
Print["CF300_A0_DRCA_CACHE_BUILD milestone=write_start cache_key=",
  compiledArtifact["CacheKey"]];
written =
  CodexDirectRootChannelCompiledArtifact`DRCAWriteCompiledArtifact[
    compiledArtifact, outputFile];
If[written =!= outputFile,
  finish["DirectCacheArtifactWriteFailed", <||>, 73]];
reread =
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    outputFile];
If[! SameQ[reread, compiledArtifact] ||
    sourceHashes[] =!= expectedHashes,
  If[FileExistsQ[outputFile], Quiet[DeleteFile[outputFile]]];
  Print["CF300_A0_DRCA_CACHE_BUILD FAIL post-write validation"];
  Exit[74]];
Print["CF300_A0_DRCA_CACHE_BUILD milestone=complete output=", outputFile,
  " file_sha256=", FileHash[outputFile, "SHA256", "HexString"],
  " compile_s=", compileSeconds];
Exit[0];


