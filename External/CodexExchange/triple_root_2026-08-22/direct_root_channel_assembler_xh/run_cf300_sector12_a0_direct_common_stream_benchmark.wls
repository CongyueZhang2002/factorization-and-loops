#!/usr/bin/env wolframscript

$HistoryLength = 0;
campaignStartTime = AbsoluteTime[];
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 5,
  Print["CF300_A0_DRCA_BENCH FAIL usage=<project-root> <preparation.wl> " <>
    "<compiled-cache.wl> <passed-validation-report.wl> " <>
    "<fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
validationReportFile = ExpandFileName[arguments[[4]]];
outputFile = ExpandFileName[arguments[[5]]];
prototypeDirectory = DirectoryName[ExpandFileName[$InputFileName]];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelAssembler.wl"}];
artifactHelperFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelCompiledArtifact.wl"}];
validationDriverFile = FileNameJoin[{prototypeDirectory,
  "run_direct_compile_cache_validate_adversarial.wls"}];
cacheBuilderDriverFile = FileNameJoin[{prototypeDirectory,
  "run_cf300_sector12_a0_direct_compile_cache_build.wls"}];
expectedPreparationSHA256 =
  "a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6";
expectedAssemblerSHA256 =
  "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6";
expectedArtifactHelperSHA256 =
  "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557";
expectedValidationDriverSHA256 =
  "7565022c17c29c4b2c0f3e2661f6890db0ebb1ef1fc457623a8642f6e00d02d9";
expectedCacheBuilderDriverSHA256 =
  "d65a6bb912148d0add608fc347147e7f67e7c4ba67f92319afc309875e7a879f";
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
    ! FileExistsQ[cacheFile] || ! FileExistsQ[validationReportFile] ||
    ! FileExistsQ[assemblerFile] || ! FileExistsQ[artifactHelperFile] ||
    ! FileExistsQ[validationDriverFile] ||
    ! FileExistsQ[cacheBuilderDriverFile] ||
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
    "BenchmarkInputMode" ->
      "PreviouslyAdversariallyValidatedCompiledCache",
    "PreparationFile" -> preparationFile, "CacheFile" -> cacheFile,
    "ValidationReportFile" -> validationReportFile|>, diagnostics, data];
  If[writeAtomic[report] === $Failed, Exit[98]];
  Print["CF300_A0_DRCA_BENCH status=", status, " output=", outputFile];
  Exit[code]
];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
safeSHA256[file_] := If[StringQ[file] && FileExistsQ[file],
  Quiet[Check[FileHash[ExpandFileName[file], "SHA256", "HexString"],
    $Failed]], $Failed];

preparationHashBefore = FileHash[preparationFile,
  "SHA256", "HexString"];
dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
assemblerHashBefore = FileHash[assemblerFile, "SHA256", "HexString"];
artifactHelperHashBefore = FileHash[artifactHelperFile,
  "SHA256", "HexString"];
validationDriverHashBefore = FileHash[validationDriverFile,
  "SHA256", "HexString"];
cacheBuilderDriverHashBefore = FileHash[cacheBuilderDriverFile,
  "SHA256", "HexString"];
cacheHashBefore = FileHash[cacheFile, "SHA256", "HexString"];
validationReportHashBefore = FileHash[validationReportFile,
  "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
expectedHashes = <|"Preparation" -> preparationHashBefore,
  "Dependencies" -> dependencyHashesBefore,
  "Assembler" -> assemblerHashBefore,
  "ArtifactHelper" -> artifactHelperHashBefore,
  "ValidationDriver" -> validationDriverHashBefore,
  "CacheBuilderDriver" -> cacheBuilderDriverHashBefore,
  "CompiledCache" -> cacheHashBefore,
  "ValidationReport" -> validationReportHashBefore,
  "Driver" -> driverHashBefore|>;
sourceHashes[] := <|
  "Preparation" -> FileHash[preparationFile, "SHA256", "HexString"],
  "Dependencies" -> Map[
    FileHash[#1, "SHA256", "HexString"] &, dependencyFiles],
  "Assembler" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "ArtifactHelper" -> FileHash[artifactHelperFile,
    "SHA256", "HexString"],
  "ValidationDriver" -> FileHash[validationDriverFile,
    "SHA256", "HexString"],
  "CacheBuilderDriver" -> FileHash[cacheBuilderDriverFile,
    "SHA256", "HexString"],
  "CompiledCache" -> FileHash[cacheFile, "SHA256", "HexString"],
  "ValidationReport" -> FileHash[validationReportFile,
    "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;

If[preparationHashBefore =!= expectedPreparationSHA256 ||
    assemblerHashBefore =!= expectedAssemblerSHA256 ||
    artifactHelperHashBefore =!= expectedArtifactHelperSHA256 ||
    validationDriverHashBefore =!= expectedValidationDriverSHA256 ||
    cacheBuilderDriverHashBefore =!= expectedCacheBuilderDriverSHA256,
  finish["PinnedBenchmarkSourceMismatch", <||>, 66]];

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
Print["CF300_A0_DRCA_BENCH milestone=load_complete elapsed_s=",
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

prime = 10007;
epsilonValue = 1/21;
repetitions = 7;
surveyPointCount = 256;
candidateBudget = 2048;
seed = Hash[{1730000 + Mod[prime, 100000],
  preparation["ABIFingerprint"], prime, epsilonValue,
  "CF300A0DirectCommonStreamBenchmarkV1"}, "CRC32"];

stats[values_List] := Module[{median = Median[values]},
  <|"Count" -> Length[values], "Minimum" -> Min[values],
    "Median" -> median, "MAD" -> Median[Abs[values - median]],
    "Maximum" -> Max[values]|>];
sampleValidQ[sample_, points_List] := TrueQ[
  AssociationQ[sample] &&
  Lookup[sample, "Status", None] ===
    "AssembledDirectRootChannelSampleV1" &&
  sample["MatrixDimensions"] === {32 Length[points], 624} &&
  sample["AcceptedPoints"] === points &&
  sample["NormalizationCount"] === 0 &&
  sample["RowBasis"] === "MultiquadraticGradeBasis"];
rawPosition[stream_List, point_List] := Module[{position},
  position = FirstPosition[stream, point, $Failed];
  If[MatchQ[position, {_Integer}], First[position], $Failed]];
directRuns[points_List] := Module[
  {records = {}, wall, localSample, telemetry},
  Do[
    {wall, localSample} = AbsoluteTiming[
      CodexDirectRootChannelAssembler`DRCAAssembleSample[
        directPreparation, epsilonValue, prime,
        "PointCount" -> Length[points],
        "MaximumAttempts" -> Length[points],
        "RandomSeed" -> seed, "CandidatePoints" -> points,
        "BranchFlipMask" -> 0]];
    If[! sampleValidQ[localSample, points], Return[$Failed]];
    telemetry = localSample["Telemetry"];
    AppendTo[records, <|"WallSeconds" -> wall,
      "InternalTotalSeconds" -> telemetry["TotalSeconds"],
      "ValidationSeconds" -> telemetry["AssemblyValidationSeconds"],
      "EpsilonCollapseSeconds" -> telemetry["EpsilonCollapseSeconds"],
      "PointAssemblySeconds" -> telemetry["PointAssemblySeconds"],
      "DenseMaterializationSeconds" ->
        telemetry["DenseMaterializationSeconds"]|>];
    Clear[localSample], {repetitions}];
  records];
directSummary[records_List] := Module[
  {pointMedian = Median[Lookup[records, "PointAssemblySeconds"]]},
  <|"WallSeconds" -> stats[Lookup[records, "WallSeconds"]],
    "InternalTotalSeconds" ->
      stats[Lookup[records, "InternalTotalSeconds"]],
    "ValidationSeconds" -> stats[Lookup[records, "ValidationSeconds"]],
    "EpsilonCollapseSeconds" ->
      stats[Lookup[records, "EpsilonCollapseSeconds"]],
    "PointAssemblySeconds" ->
      stats[Lookup[records, "PointAssemblySeconds"]],
    "DenseMaterializationSeconds" ->
      stats[Lookup[records, "DenseMaterializationSeconds"]],
    "RowsPerPointAssemblySecondMedian" ->
      If[pointMedian > 0, 672/pointMedian, Indeterminate],
    "EntriesPerPointAssemblySecondMedian" ->
      If[pointMedian > 0, 672 624/pointMedian, Indeterminate]|>];
legacyRowsAt[points_List] := Module[{data, rows, right},
  data = Table[Quiet[Check[
      CodexTripleRootPilot`TRSplitPointRows[
        preparation["Record"], preparation["Roots"],
        preparation["OneForms"], preparation["GaugeDenominator"],
        preparation["GaugeSupport"], epsilonValue, prime, point],
      $Failed]], {point, points}];
  If[MemberQ[data, $Failed] ||
      ! AllTrue[data, AssociationQ[#1] &&
        Length[Lookup[#1, "Rows", {}]] === 32 &&
        Length[Lookup[#1, "RightHandSide", {}]] === 32 &],
    Return[$Failed]];
  rows = Developer`ToPackedArray[Mod[
    Normal /@ (Join @@ Lookup[data, "Rows"]), prime]];
  right = Developer`ToPackedArray[Mod[
    Join @@ Lookup[data, "RightHandSide"], prime]];
  If[Dimensions[rows] =!= {32 Length[points], 624} ||
      Length[right] =!= 32 Length[points], Return[$Failed]];
  <|"Rows" -> rows, "RightHandSide" -> right|>];

validationRequiredKeys = {"Status", "ValidationContract",
  "ValidatorDriverFile", "ValidatorDriverSHA256", "CacheFile",
  "CacheFileSHA256", "CacheKey", "AssemblyFingerprint",
  "OperationalEpsilonCollapsePassed", "ExactPutGetRoundTripPassed",
  "CompiledFingerprintCorruptionRejected",
  "CompiledPayloadCorruptionRejected", "CacheKeyCorruptionRejected",
  "RelocatedExactSourceCopyAccepted", "TemporarySourceMutationRejected",
  "TruncatedArtifactRejected", "TemporaryFilesRemoved",
  "SourcesStableAtCompletion", "CapturedMessages", "MessagesEmpty",
  "ExpectedRuntimeSourceHashes", "CurrentRuntimeSourceHashes",
  "ExpectedRecursiveSourceHashes", "CurrentRecursiveSourceHashes"};
validationBooleanKeys = {"OperationalEpsilonCollapsePassed",
  "ExactPutGetRoundTripPassed", "CompiledFingerprintCorruptionRejected",
  "CompiledPayloadCorruptionRejected", "CacheKeyCorruptionRejected",
  "RelocatedExactSourceCopyAccepted", "TemporarySourceMutationRejected",
  "TruncatedArtifactRejected", "TemporaryFilesRemoved",
  "SourcesStableAtCompletion", "MessagesEmpty"};
{validationReportReadSeconds, validationReport} = AbsoluteTiming[
  FeynFacet`FamilyArtifactRead[validationReportFile]];
If[! AssociationQ[validationReport] ||
    ! AllTrue[validationRequiredKeys,
      KeyExistsQ[validationReport, #1] &] ||
    validationReport["Status"] =!=
      "DirectRootChannelCompiledArtifactValidationPassed" ||
    validationReport["ValidationContract"] =!=
      "DirectRootChannelCompiledArtifactAdversarialValidationV1" ||
    ! StringQ[validationReport["ValidatorDriverFile"]] ||
    ExpandFileName[validationReport["ValidatorDriverFile"]] =!=
      validationDriverFile ||
    validationReport["ValidatorDriverSHA256"] =!=
      expectedValidationDriverSHA256 ||
    validationReport["CacheFile"] =!= cacheFile ||
    validationReport["CacheFileSHA256"] =!= cacheHashBefore ||
    ! AllTrue[validationBooleanKeys,
      TrueQ[validationReport[#1]] &] ||
    ! StringQ[validationReport["CapturedMessages"]] ||
    StringTrim[validationReport["CapturedMessages"]] =!= "" ||
    validationReport["ExpectedRuntimeSourceHashes"] =!=
      validationReport["CurrentRuntimeSourceHashes"] ||
    validationReport["ExpectedRecursiveSourceHashes"] =!=
      validationReport["CurrentRecursiveSourceHashes"],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["PriorAdversarialValidationInvalid", <||>, 70]];

Print["CF300_A0_DRCA_BENCH milestone=cache_read_start"];
{cacheReadSeconds, compiledArtifact} = AbsoluteTiming[
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    cacheFile]];
If[! AssociationQ[compiledArtifact] ||
    ! CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
      compiledArtifact],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["CompiledCacheReadOrValidationFailed", <||>, 70]];
directPreparation = compiledArtifact["DirectAssembly"];
builderProvenance = compiledArtifact["BuilderProvenance"];
builderProvenanceKeys = {"PreparationFile", "PreparationSHA256",
  "PreparationInputFile", "PreparationInputSHA256",
  "PreparationDriverFile", "PreparationDriverSHA256",
  "BuilderDriverFile", "BuilderDriverSHA256", "RuntimeSourceHashes",
  "RecursiveSourceHashes", "CompilationSeconds"};
If[! AssociationQ[builderProvenance] ||
    ! AllTrue[builderProvenanceKeys,
      KeyExistsQ[builderProvenance, #1] &] ||
    ! AllTrue[{"PreparationFile", "PreparationInputFile",
        "PreparationDriverFile", "BuilderDriverFile"},
      StringQ[builderProvenance[#1]] &&
        FileExistsQ[builderProvenance[#1]] &],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["CompiledCacheProvenanceSchemaInvalid", <||>, 70]];
currentBuilderRuntimeHashes = <|
  "Preparation" -> safeSHA256[builderProvenance["PreparationFile"]],
  "Dependencies" -> dependencyHashesBefore,
  "Assembler" -> assemblerHashBefore,
  "ArtifactHelper" -> artifactHelperHashBefore,
  "Driver" -> safeSHA256[builderProvenance["BuilderDriverFile"]]|>;
currentBuilderRecursiveHashes = <|
  "PreparationDriver" ->
    safeSHA256[builderProvenance["PreparationDriverFile"]],
  "PreparationInput" ->
    safeSHA256[builderProvenance["PreparationInputFile"]]|>;
cacheContractPassed = TrueQ[
  Lookup[directPreparation, "Status", None] ===
      "PreparedDirectRootChannelsV1" &&
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      directPreparation] &&
    directPreparation["SourceABIFingerprint"] ===
      preparation["ABIFingerprint"] &&
    directPreparation["RootOrderingFingerprint"] ===
      preparation["RootOrderingFingerprint"] &&
    directPreparation["UnknownCount"] === 624 &&
    directPreparation["EquationsPerPoint"] === 32 &&
    compiledArtifact["SourcePreparationABIFingerprint"] ===
      preparation["ABIFingerprint"] &&
    compiledArtifact["RootOrderingFingerprint"] ===
      preparation["RootOrderingFingerprint"] &&
    compiledArtifact["PrototypeSourceSHA256"] ===
      expectedAssemblerSHA256 &&
    ExpandFileName[compiledArtifact["PrototypeSourceFile"]] ===
      assemblerFile &&
    compiledArtifact["CacheKeyPayload"]["PreparationSHA256"] ===
      preparationHashBefore &&
    compiledArtifact["CacheKey"] === validationReport["CacheKey"] &&
    compiledArtifact["DirectAssemblyFingerprint"] ===
      validationReport["AssemblyFingerprint"] &&
    ExpandFileName[builderProvenance["PreparationFile"]] ===
      preparationFile &&
    builderProvenance["PreparationSHA256"] === preparationHashBefore &&
    ExpandFileName[builderProvenance["PreparationInputFile"]] ===
      inputFile &&
    builderProvenance["PreparationInputSHA256"] ===
      preparationArtifact["InputSHA256"] &&
    ExpandFileName[builderProvenance["PreparationDriverFile"]] ===
      preparationDriverFile &&
    builderProvenance["PreparationDriverSHA256"] ===
      preparationArtifact["DriverSHA256"] &&
    ExpandFileName[builderProvenance["BuilderDriverFile"]] ===
      cacheBuilderDriverFile &&
    builderProvenance["BuilderDriverSHA256"] ===
      expectedCacheBuilderDriverSHA256 &&
    safeSHA256[builderProvenance["BuilderDriverFile"]] ===
      expectedCacheBuilderDriverSHA256 &&
    currentBuilderRuntimeHashes ===
      builderProvenance["RuntimeSourceHashes"] &&
    currentBuilderRecursiveHashes ===
      builderProvenance["RecursiveSourceHashes"] &&
    validationReport["ExpectedRuntimeSourceHashes"] ===
      builderProvenance["RuntimeSourceHashes"] &&
    validationReport["ExpectedRecursiveSourceHashes"] ===
      builderProvenance["RecursiveSourceHashes"]];
If[! cacheContractPassed,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["ValidatedCacheSourceInputOrABIMismatch", <|
    "CacheKey" -> compiledArtifact["CacheKey"],
    "ValidationCacheKey" -> validationReport["CacheKey"]|>, 70]];
Print["CF300_A0_DRCA_BENCH milestone=cache_read_complete read_s=",
  cacheReadSeconds, " validation_report_read_s=",
  validationReportReadSeconds, " cache_key=",
  compiledArtifact["CacheKey"]];

candidateStream = BlockRandom[
  SeedRandom[seed, Method -> "MersenneTwister"];
  Table[RandomInteger[{2, prime - 2}, 2], {candidateBudget}]];
Print["CF300_A0_DRCA_BENCH milestone=survey_start"];
{surveySeconds, surveySample} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCAAssembleSample[
    directPreparation, epsilonValue, prime,
    "PointCount" -> surveyPointCount,
    "MaximumAttempts" -> candidateBudget,
    "RandomSeed" -> seed, "CandidatePoints" -> candidateStream,
    "BranchFlipMask" -> 0]];
If[! AssociationQ[surveySample] ||
    Lookup[surveySample, "Status", None] =!=
      "AssembledDirectRootChannelSampleV1" ||
    surveySample["MatrixDimensions"] =!= {8192, 624} ||
    Length[surveySample["AcceptedPoints"]] =!= surveyPointCount ||
    Length[surveySample["PointDeltaValues"]] =!= surveyPointCount,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["CommonStreamSurveyFailed", <||>, 71]];
acceptedPoints = surveySample["AcceptedPoints"];
deltaValues = surveySample["PointDeltaValues"];
residueCharacters = Map[JacobiSymbol[#1, prime] &, deltaValues, {2}];
If[! AllTrue[residueCharacters, Length[#1] === 2 &&
      AllTrue[#1, Function[value, MemberQ[{-1, 1}, value]]] &],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["CommonStreamCharacterClassificationFailed", <||>, 71]];
splitIndices = Flatten[Position[residueCharacters, {1, 1}]];
If[Length[splitIndices] < 21,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["InsufficientCommonStreamSplitPoints", <||>, 71]];
directPoints = Take[acceptedPoints, 21];
directDeltaValues = Take[deltaValues, 21];
splitPoints = acceptedPoints[[Take[splitIndices, 21]]];
directAttemptCount = rawPosition[candidateStream, Last[directPoints]];
splitAttemptCount = rawPosition[candidateStream, Last[splitPoints]];
directNonsplitCount = Count[
  Map[JacobiSymbol[#1, prime] &, directDeltaValues, {2}],
  Except[{1, 1}]];
If[! IntegerQ[directAttemptCount] || ! IntegerQ[splitAttemptCount] ||
    directAttemptCount < 21 || splitAttemptCount < directAttemptCount ||
    directNonsplitCount < 1,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["CommonStreamAttemptAccountingFailed", <||>, 71]];
Print["CF300_A0_DRCA_BENCH milestone=survey_complete survey_s=",
  surveySeconds, " direct_attempts=", directAttemptCount,
  " split_attempts=", splitAttemptCount];

CodexDirectRootChannelAssembler`DRCAClearCaches[];
Print["CF300_A0_DRCA_BENCH milestone=direct_cold_start"];
{directColdWallSeconds, directColdSample} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCAAssembleSample[
    directPreparation, epsilonValue, prime, "PointCount" -> 21,
    "MaximumAttempts" -> 21, "RandomSeed" -> seed,
    "CandidatePoints" -> directPoints, "BranchFlipMask" -> 0]];
If[! sampleValidQ[directColdSample, directPoints],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["DirectColdSampleFailed", <||>, 72]];
directColdTelemetry = directColdSample["Telemetry"];
directWarmup = CodexDirectRootChannelAssembler`DRCAAssembleSample[
  directPreparation, epsilonValue, prime, "PointCount" -> 21,
  "MaximumAttempts" -> 21, "RandomSeed" -> seed,
  "CandidatePoints" -> directPoints, "BranchFlipMask" -> 0];
If[! sampleValidQ[directWarmup, directPoints],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["DirectWarmupFailed", <||>, 72]];
directWarmRecords = directRuns[directPoints];
If[directWarmRecords === $Failed,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["DirectWarmRunsFailed", <||>, 72]];
Print["CF300_A0_DRCA_BENCH milestone=direct_warm_complete"];

splitWarmup = CodexDirectRootChannelAssembler`DRCAAssembleSample[
  directPreparation, epsilonValue, prime, "PointCount" -> 21,
  "MaximumAttempts" -> 21, "RandomSeed" -> seed,
  "CandidatePoints" -> splitPoints, "BranchFlipMask" -> 0];
If[! sampleValidQ[splitWarmup, splitPoints],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["SplitDirectWarmupFailed", <||>, 73]];
splitWarmRecords = directRuns[splitPoints];
If[splitWarmRecords === $Failed,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["SplitDirectWarmRunsFailed", <||>, 73]];
splitReferenceSample =
  CodexDirectRootChannelAssembler`DRCAAssembleSample[
    directPreparation, epsilonValue, prime, "PointCount" -> 21,
    "MaximumAttempts" -> 21, "RandomSeed" -> seed,
    "CandidatePoints" -> splitPoints, "BranchFlipMask" -> 0];
If[! sampleValidQ[splitReferenceSample, splitPoints],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["SplitReferenceSampleFailed", <||>, 73]];
Print["CF300_A0_DRCA_BENCH milestone=split_direct_complete"];

transformRecords = Table[
  {transformWall, transformSample} = AbsoluteTiming[
    CodexDirectRootChannelAssembler`DRCATransformSampleToSigns[
      directPreparation, splitReferenceSample, prime, 0]];
  If[Lookup[transformSample, "Status", None] =!=
        "TransformedDirectSampleToSplitSignsV1" ||
      transformSample["MatrixDimensions"] =!= {672, 624},
    Close[runtimeMessageStream]; $Messages = savedMessages;
    finish["SignTransformBenchmarkFailed", <||>, 74]];
  <|"WallSeconds" -> transformWall|>, {repetitions}];
Print["CF300_A0_DRCA_BENCH milestone=transform_complete"];

Print["CF300_A0_DRCA_BENCH milestone=legacy_hot_start"];
legacyWarmup = legacyRowsAt[splitPoints];
If[! AssociationQ[legacyWarmup],
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["LegacyCommonPointWarmupFailed", <||>, 75]];
legacyRecords = Table[
  {legacyWall, legacySample} = AbsoluteTiming[legacyRowsAt[splitPoints]];
  If[! AssociationQ[legacySample],
    Close[runtimeMessageStream]; $Messages = savedMessages;
    finish["LegacyCommonPointRunFailed", <||>, 75]];
  <|"WallSeconds" -> legacyWall|>, {repetitions}];
matrixEqual = TrueQ[transformSample["Rows"] === legacyWarmup["Rows"]];
rightEqual = TrueQ[
  transformSample["RightHandSide"] === legacyWarmup["RightHandSide"]];
If[! matrixEqual || ! rightEqual,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["CommonPointExactDifferentialFailed", <||>, 76]];
Print["CF300_A0_DRCA_BENCH milestone=legacy_hot_complete"];

Close[runtimeMessageStream];
$Messages = savedMessages;
runtimeMessages = Quiet[Check[Import[runtimeMessageFile, "Text"], $Failed]];
If[FileExistsQ[runtimeMessageFile], Quiet[DeleteFile[runtimeMessageFile]]];
completionHashes = sourceHashes[];
recursiveSourceHashesAtCompletion = <|
  "PreparationDriver" -> FileHash[preparationDriverFile,
    "SHA256", "HexString"],
  "PreparationInput" -> FileHash[inputFile, "SHA256", "HexString"]|>;
hashesStable = TrueQ[completionHashes === expectedHashes &&
  recursiveSourceHashesAtCompletion === recursiveSourceHashesExpected];
messagesEmpty = StringQ[runtimeMessages] &&
  StringTrim[runtimeMessages] === "";
status = If[messagesEmpty && hashesStable && cacheContractPassed &&
    matrixEqual && rightEqual,
  "CF300Sector12A0DirectCommonStreamBenchmarkPassed",
  "CF300Sector12A0DirectCommonStreamBenchmarkFailed"];
characterHistogram = Association@KeyValueMap[
  ToString[InputForm[#1]] -> #2 &, Counts[residueCharacters]];
report = <|"Status" -> status, "Prime" -> prime,
  "EpsilonValue" -> epsilonValue, "RandomSeed" -> seed,
  "Repetitions" -> repetitions, "CandidateBudget" -> candidateBudget,
  "SurveyPointCount" -> surveyPointCount,
  "CandidateStreamFingerprint" -> fingerprint[candidateStream],
  "SurveyAcceptedPointsFingerprint" -> fingerprint[acceptedPoints],
  "SurveySeconds" -> surveySeconds,
  "SurveyAttemptCount" -> surveySample["AttemptCount"],
  "SurveyRejectedReasonHistogram" ->
    Counts[Lookup[surveySample["RejectedPoints"], "FailureReason", None]],
  "ResidueCharacterHistogram" -> characterHistogram,
  "SplitPointsAmongSurvey" -> Length[splitIndices],
  "DirectTargetAttemptCount" -> directAttemptCount,
  "SplitTargetAttemptCount" -> splitAttemptCount,
  "MeasuredCommonStreamAttemptReduction" ->
    N[splitAttemptCount/directAttemptCount],
  "ExpectedRank2AttemptReduction" -> 4,
  "DirectTargetNonsplitPointCount" -> directNonsplitCount,
  "DirectTargetPoints" -> directPoints,
  "SplitTargetPoints" -> splitPoints,
  "DirectInputMode" ->
    "PreviouslyAdversariallyValidatedCompiledCache",
  "DirectCompilationPerformed" -> False,
  "DirectCompilationSeconds" ->
    Missing["NotPerformed", "ValidatedCompiledCacheBenchmark"],
  "DirectCacheFile" -> cacheFile,
  "DirectCacheFileSHA256" -> cacheHashBefore,
  "DirectCacheKey" -> compiledArtifact["CacheKey"],
  "DirectCacheReadAndFullValidationSeconds" -> cacheReadSeconds,
  "PriorAdversarialValidationReportFile" -> validationReportFile,
  "PriorAdversarialValidationReportSHA256" ->
    validationReportHashBefore,
  "PriorAdversarialValidationReportReadSeconds" ->
    validationReportReadSeconds,
  "PriorAdversarialValidationStatus" ->
    validationReport["Status"],
  "PriorAdversarialValidatorDriverFile" -> validationDriverFile,
  "PriorAdversarialValidatorDriverSHA256" ->
    validationDriverHashBefore,
  "DirectCold" -> <|"WallSeconds" -> directColdWallSeconds,
    "Telemetry" -> directColdTelemetry|>,
  "DirectArbitraryWarm" -> directSummary[directWarmRecords],
  "DirectSplitWarm" -> directSummary[splitWarmRecords],
  "SignTransformWarm" ->
    <|"WallSeconds" -> stats[Lookup[transformRecords, "WallSeconds"]]|>,
  "LegacySplitPointWarm" ->
    <|"WallSeconds" -> stats[Lookup[legacyRecords, "WallSeconds"]]|>,
  "LikeForLikeSignBasisMedianSpeedup" -> With[
    {d = Median[Lookup[splitWarmRecords, "WallSeconds"]] +
      Median[Lookup[transformRecords, "WallSeconds"]]},
    If[d > 0, Median[Lookup[legacyRecords, "WallSeconds"]]/d,
      Indeterminate]],
  "TransformFreeGradeBasisMedianSpeedup" -> With[
    {d = Median[Lookup[splitWarmRecords, "WallSeconds"]]},
    If[d > 0, Median[Lookup[legacyRecords, "WallSeconds"]]/d,
      Indeterminate]],
  "CommonPointMatrixEqual" -> matrixEqual,
  "CommonPointRightHandSideEqual" -> rightEqual,
  "CommonPointSignMatrixFingerprint" ->
    fingerprint[transformSample["Rows"]],
  "TimingScope" -> <|
    "Compilation" ->
      "NotPerformed;ValidatedCompiledCacheReadTimedSeparately",
    "CacheTrust" ->
      "FullArtifactValidationPlusPriorAdversarialReportSourceAndABIBinding",
    "AttemptReduction" -> "SameExplicitCandidateStream",
    "DirectWarm" ->
      "ValidatedAssemblyOnPreselectedPointsWithWarmPrimeEpsilonCaches",
    "LegacyWarm" ->
      "TRSplitPointRowsOnSamePreselectedSplitPointsNoPointSearch",
    "SignBasis" -> "DirectWarmPlusSeparatelyTimedSignTransform",
    "GradeBasis" -> "DirectWarmWithoutSignTransform"|>,
  "CapturedLoadMessages" -> loadMessages,
  "CapturedRuntimeMessages" -> runtimeMessages,
  "MessagesEmpty" -> messagesEmpty,
  "ExpectedSourceHashes" -> expectedHashes,
  "CompletionSourceHashes" -> completionHashes,
  "ExpectedRecursiveSourceHashes" -> recursiveSourceHashesExpected,
  "CompletionRecursiveSourceHashes" ->
    recursiveSourceHashesAtCompletion,
  "SourceHashesStableAtCompletion" -> hashesStable|>;
If[writeAtomic[report] === $Failed, Exit[98]];
Print["CF300_A0_DRCA_BENCH milestone=complete status=", status,
  " output=", outputFile];
Exit[If[status ===
  "CF300Sector12A0DirectCommonStreamBenchmarkPassed", 0, 1]];
