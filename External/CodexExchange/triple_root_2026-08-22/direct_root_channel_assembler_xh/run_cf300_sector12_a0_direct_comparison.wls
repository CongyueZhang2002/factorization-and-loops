#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["CF300_A0_DRCA FAIL usage=<project-root> <preparation.wl> " <>
    "<fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelAssembler.wl"}];
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
    ! FileExistsQ[assemblerFile] ||
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
  Print["CF300_A0_DRCA status=", status, " output=", outputFile];
  Exit[code]
];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

preparationHashBefore = FileHash[preparationFile,
  "SHA256", "HexString"];
dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
assemblerHashBefore = FileHash[assemblerFile, "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
expectedHashes = <|"Preparation" -> preparationHashBefore,
  "Dependencies" -> dependencyHashesBefore,
  "Assembler" -> assemblerHashBefore, "Driver" -> driverHashBefore|>;
sourceHashes[] := <|
  "Preparation" -> FileHash[preparationFile, "SHA256", "HexString"],
  "Dependencies" -> Map[
    FileHash[#1, "SHA256", "HexString"] &, dependencyFiles],
  "Assembler" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;

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
randomSeed = 730000 + Mod[prime, 100000];
seed = Hash[{randomSeed, preparation["ABIFingerprint"], prime,
  epsilonValue}, "CRC32"];

{compileSeconds, directPreparation} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCAPrepare[preparation]];
If[Lookup[directPreparation, "Status", None] =!=
      "PreparedDirectRootChannelsV1" ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      directPreparation] ||
    directPreparation["UnknownCount"] =!= 624 ||
    directPreparation["EquationsPerPoint"] =!= 32,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["DirectPreparationFailed", <|
    "DirectPreparationStatus" -> Lookup[directPreparation,
      "Status", None]|>, 70]];

{legacySeconds, legacySample} = AbsoluteTiming[
  Block[{CodexTripleRootReconstruction`Private`$trValidatedABIFingerprint =
      preparation["ABIFingerprint"]},
    CodexTripleRootReconstruction`Private`trAssembleReconstructionSampleInternal[
      preparation, epsilonValue, prime,
      "PointCount" -> Automatic, "MaximumAttempts" -> Automatic,
      "RandomSeed" -> seed,
      "ValidatedABIFingerprint" -> preparation["ABIFingerprint"]]]];
If[! AssociationQ[legacySample] ||
    Lookup[legacySample, "Status", None] =!=
      "AssembledReconstructionSample" ||
    legacySample["MatrixDimensions"] =!= {672, 624} ||
    Length[legacySample["AcceptedPoints"]] =!= 21 ||
    legacySample["NormalizationCount"] =!= 0,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["LegacyPhysicalAssemblyFailed", <|
    "LegacyStatus" -> Lookup[legacySample, "Status", None],
    "LegacySeconds" -> legacySeconds|>, 71]];

{directSeconds, directSample} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCAAssembleSample[
    directPreparation, epsilonValue, prime,
    "PointCount" -> 21, "MaximumAttempts" -> 21,
    "RandomSeed" -> seed,
    "CandidatePoints" -> legacySample["AcceptedPoints"],
    "BranchFlipMask" -> 0]];
If[Lookup[directSample, "Status", None] =!=
      "AssembledDirectRootChannelSampleV1" ||
    directSample["MatrixDimensions"] =!= {672, 624} ||
    directSample["AcceptedPoints"] =!= legacySample["AcceptedPoints"] ||
    directSample["NormalizationCount"] =!= 0,
  Close[runtimeMessageStream]; $Messages = savedMessages;
  finish["DirectPhysicalAssemblyFailed", <|
    "DirectStatus" -> Lookup[directSample, "Status", None],
    "DirectSeconds" -> directSeconds|>, 72]];

{transformSeconds, signSample} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCATransformSampleToSigns[
    directPreparation, directSample, prime, 0]];
legacyDense = Developer`ToPackedArray[Mod[Normal[legacySample["Matrix"]],
  prime]];
legacyRight = Developer`ToPackedArray[Mod[
  legacySample["RightHandSide"], prime]];
matrixEqual = TrueQ[
  Lookup[signSample, "Rows", None] === legacyDense];
rightEqual = TrueQ[
  Lookup[signSample, "RightHandSide", None] === legacyRight];
{pointDifferentialSeconds, pointDifferential} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCADifferentialCheckPoint[
    directPreparation, epsilonValue, prime,
    First[legacySample["AcceptedPoints"]], 0]];

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
pointPassed = TrueQ[Lookup[pointDifferential, "Status", None] ===
  "DirectLegacyPointDifferentialPassed" &&
  Lookup[pointDifferential, "Passed", False]];
status = If[matrixEqual && rightEqual && pointPassed &&
    messagesEmpty && hashesStable,
  "CF300Sector12A0DirectComparisonPassed",
  "CF300Sector12A0DirectComparisonFailed"];
report = <|"Status" -> status, "Prime" -> prime,
  "EpsilonValue" -> epsilonValue, "RandomSeed" -> seed,
  "MatrixDimensions" -> directSample["MatrixDimensions"],
  "AcceptedPoints" -> directSample["AcceptedPoints"],
  "AcceptedPointsFingerprint" -> fingerprint[
    directSample["AcceptedPoints"]],
  "DirectGradeMatrixFingerprint" -> fingerprint[directSample["Matrix"]],
  "TransformedSignMatrixFingerprint" -> fingerprint[signSample["Rows"]],
  "LegacySignMatrixFingerprint" -> fingerprint[legacyDense],
  "RightHandSideFingerprint" -> fingerprint[legacyRight],
  "FullSampleMatrixEqual" -> matrixEqual,
  "FullSampleRightHandSideEqual" -> rightEqual,
  "FirstPointDifferentialPassed" -> pointPassed,
  "FirstPointDifferential" -> pointDifferential,
  "Telemetry" -> <|"DirectCompilationSeconds" -> compileSeconds,
    "LegacySampleSeconds" -> legacySeconds,
    "DirectSampleSeconds" -> directSeconds,
    "DirectSampleInternal" -> directSample["Telemetry"],
    "SignTransformSeconds" -> transformSeconds,
    "FirstPointDifferentialSeconds" -> pointDifferentialSeconds,
    "AssemblySpeedupExcludingCompilation" ->
      If[directSeconds > 0, legacySeconds/directSeconds, Indeterminate]|>,
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
Print["CF300_A0_DRCA status=", status, " legacy_s=", legacySeconds,
  " direct_s=", directSeconds, " output=", outputFile];
Exit[If[status === "CF300Sector12A0DirectComparisonPassed", 0, 1]];
