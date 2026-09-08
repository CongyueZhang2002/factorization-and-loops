#!/usr/bin/env wolframscript

$HistoryLength = 0;
campaignStartTime = AbsoluteTime[];
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["DRCA_CACHE_VALIDATE FAIL usage=<project-root> " <>
    "<compiled-cache.wl> <fresh-report.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
cacheFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelAssembler.wl"}];
helperFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelCompiledArtifact.wl"}];
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
expectedDependencyHashes = <|
  "LoadFACET" -> "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164",
  "FeynFacetPublic" -> "4af4f6a8c3b9201ba6e1088e7fec94b6f0befc1d37bc2d76f43e5509fa64ac9e",
  "FiniteFieldStripSolve" -> "c6230ae8b6b1d00780ca697cf9e6838a395682a7eabe626b17c8371357bb1671",
  "FiniteFieldEpsForm" -> "c6dce4f78bd90238b815885e3d622d23aee3cf799a484419ef07d15763e97091",
  "FamilyEpsForm" -> "436c3fc6216e7be3ee1fce41dd1c98f91f1ce733aff27308214275f1a8221ce4",
  "TransportCharts" -> "c30e2e54b63abe9eb6c3b82ec2d275b8f4bb247007f2a93fa7db879399de051a",
  "TripleRootAlgebra" -> "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
  "TripleRootStripAdapter" -> "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
  "TripleRootAffinePilot" -> "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
  "TripleRootReconstructionPrototype" -> "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43"|>;
expectedAssemblerSHA256 =
  "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6";
expectedHelperSHA256 =
  "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557";

If[! DirectoryQ[projectRoot] || ! FileExistsQ[cacheFile] ||
    ! FileExistsQ[assemblerFile] || ! FileExistsQ[helperFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]],
  Exit[65]];

dependencyHashes[] := Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
validatorDriverFile = ExpandFileName[$InputFileName];
driverHashBefore = FileHash[validatorDriverFile, "SHA256", "HexString"];
cacheHashBefore = FileHash[cacheFile, "SHA256", "HexString"];
If[dependencyHashes[] =!= expectedDependencyHashes ||
    FileHash[assemblerFile, "SHA256", "HexString"] =!=
      expectedAssemblerSHA256 ||
    FileHash[helperFile, "SHA256", "HexString"] =!=
      expectedHelperSHA256,
  Exit[66]];

deleteIfPresent[file_String] := Module[{},
  If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
  ! FileExistsQ[file]];
writeAtomic[value_] := Module[{temporary, written, renamed},
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
    deleteIfPresent[temporary]; $Failed, outputFile]];

savedMessages = $Messages;
messageFile = outputFile <> ".messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
messageStream = OpenWrite[messageFile, CharacterEncoding -> "UTF8"];
$Messages = {messageStream};
loadOutcome = Check[
  Get[dependencyFiles["LoadFACET"]];
  Get[dependencyFiles["TripleRootAlgebra"]];
  Get[dependencyFiles["TripleRootStripAdapter"]];
  Get[dependencyFiles["TripleRootAffinePilot"]];
  Get[dependencyFiles["TripleRootReconstructionPrototype"]];
  Get[assemblerFile];
  Get[helperFile];
  True, $Failed];
If[loadOutcome =!= True, Close[messageStream]; Exit[67]];
Print["DRCA_CACHE_VALIDATE milestone=load_complete elapsed_s=",
  N[AbsoluteTime[] - campaignStartTime]];

{readSeconds, artifact} = AbsoluteTiming[
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    cacheFile]];
If[! AssociationQ[artifact] ||
    ! CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
      artifact],
  Close[messageStream]; Exit[68]];
assembly = artifact["DirectAssembly"];
provenance = artifact["BuilderProvenance"];
expectedRuntimeHashes = provenance["RuntimeSourceHashes"];
currentRuntimeHashes[] := <|
  "Preparation" -> FileHash[provenance["PreparationFile"],
    "SHA256", "HexString"],
  "Dependencies" -> dependencyHashes[],
  "Assembler" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "ArtifactHelper" -> FileHash[helperFile, "SHA256", "HexString"],
  "Driver" -> FileHash[provenance["BuilderDriverFile"],
    "SHA256", "HexString"]|>;
recursiveCurrent[] := <|
  "PreparationDriver" -> FileHash[provenance["PreparationDriverFile"],
    "SHA256", "HexString"],
    "PreparationInput" -> FileHash[provenance["PreparationInputFile"],
    "SHA256", "HexString"]|>;
runtimeHashesAtRead = currentRuntimeHashes[];
recursiveHashesAtRead = recursiveCurrent[];
If[runtimeHashesAtRead =!= expectedRuntimeHashes ||
    recursiveHashesAtRead =!= provenance["RecursiveSourceHashes"],
  Close[messageStream]; Exit[69]];
Print["DRCA_CACHE_VALIDATE milestone=read_complete read_validate_s=",
  readSeconds, " cache_key=", artifact["CacheKey"]];

CodexDirectRootChannelAssembler`DRCAClearCaches[];
{operationalSeconds, epsilonForms} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
    assembly, 10007, 1/21]];
operationalPassed = AssociationQ[epsilonForms] &&
  Lookup[epsilonForms, "Status", None] ===
    "DirectRootChannelEpsilonFormsV1" &&
  epsilonForms["AssemblyFingerprint"] === assembly["AssemblyFingerprint"];
Print["DRCA_CACHE_VALIDATE milestone=operational_check_complete elapsed_s=",
  N[AbsoluteTime[] - campaignStartTime]];

roundtripFile = outputFile <> ".roundtrip-" <>
  StringReplace[CreateUUID[], "-" -> ""] <> ".wl";
roundtripWritten =
  CodexDirectRootChannelCompiledArtifact`DRCAWriteCompiledArtifact[
    artifact, roundtripFile];
roundtripRead = If[roundtripWritten === roundtripFile,
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    roundtripFile], $Failed];
roundtripPassed = SameQ[roundtripRead, artifact];
deleteIfPresent[roundtripFile];

fingerprintTamperedAssembly = ReplacePart[assembly,
  "CompiledFormsFingerprint" ->
    StringReverse[assembly["CompiledFormsFingerprint"]]];
fingerprintTamperedArtifact = ReplacePart[artifact,
  "DirectAssembly" -> fingerprintTamperedAssembly];
fingerprintCorruptionRejected =
  ! CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
    fingerprintTamperedArtifact];

corruptedCompiledForms = ReplacePart[assembly["CompiledForms"],
  "RootSquares" -> Reverse[assembly["CompiledForms"]["RootSquares"]]];
payloadTamperedAssembly = ReplacePart[assembly,
  "CompiledForms" -> corruptedCompiledForms];
payloadTamperedArtifact = ReplacePart[artifact,
  "DirectAssembly" -> payloadTamperedAssembly];
payloadCorruptionRejected =
  ! CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
    payloadTamperedArtifact];

cacheKeyTamperedArtifact = ReplacePart[artifact,
  "CacheKey" -> StringReverse[artifact["CacheKey"]]];
cacheKeyCorruptionRejected =
  ! CodexDirectRootChannelCompiledArtifact`DRCACompiledArtifactValidQ[
    cacheKeyTamperedArtifact];

sourceProbeFile = outputFile <> ".source-probe-" <>
  StringReplace[CreateUUID[], "-" -> ""] <> ".wl";
sourceCopied = Quiet[Check[CopyFile[assembly["PrototypeSourceFile"],
  sourceProbeFile, OverwriteTarget -> False], $Failed]];
relocatedAssembly = If[sourceCopied === sourceProbeFile,
  ReplacePart[assembly, "PrototypeSourceFile" -> sourceProbeFile], $Failed];
relocatedExactCopyAccepted = AssociationQ[relocatedAssembly] &&
  CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
    relocatedAssembly];
sourceStream = If[relocatedExactCopyAccepted,
  OpenAppend[sourceProbeFile, CharacterEncoding -> "UTF8"], $Failed];
If[MatchQ[sourceStream, _OutputStream],
  WriteString[sourceStream, "\n(* deliberate temporary mutation *)\n"];
  Close[sourceStream]];
sourceMutationRejected = relocatedExactCopyAccepted &&
  ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
    relocatedAssembly];
deleteIfPresent[sourceProbeFile];

truncatedFile = outputFile <> ".truncated-" <>
  StringReplace[CreateUUID[], "-" -> ""] <> ".wl";
truncatedWritten = If[FileByteCount[cacheFile] > 4096,
  Module[{input = OpenRead[cacheFile, BinaryFormat -> True], bytes,
      output},
    bytes = BinaryReadList[input, "Byte", 4096]; Close[input];
    output = OpenWrite[truncatedFile, BinaryFormat -> True];
    BinaryWrite[output, bytes, "Byte"]; Close[output];
    truncatedFile], $Failed];
truncationRejected = truncatedWritten === truncatedFile &&
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    truncatedFile] === $Failed;
deleteIfPresent[truncatedFile];

Print["DRCA_CACHE_VALIDATE milestone=adversarial_complete elapsed_s=",
  N[AbsoluteTime[] - campaignStartTime]];
Close[messageStream];
$Messages = savedMessages;
messages = Quiet[Check[Import[messageFile, "Text"], $Failed]];
deleteIfPresent[messageFile];
sourcesStable = TrueQ[
  FileHash[cacheFile, "SHA256", "HexString"] === cacheHashBefore &&
  dependencyHashes[] === expectedDependencyHashes &&
  FileHash[assemblerFile, "SHA256", "HexString"] ===
    expectedAssemblerSHA256 &&
  FileHash[helperFile, "SHA256", "HexString"] === expectedHelperSHA256 &&
  FileHash[validatorDriverFile, "SHA256", "HexString"] ===
    driverHashBefore &&
  currentRuntimeHashes[] === expectedRuntimeHashes &&
  recursiveCurrent[] === provenance["RecursiveSourceHashes"]];
messagesEmpty = StringQ[messages] && StringTrim[messages] === "";
temporaryFilesRemoved = AllTrue[
  {roundtripFile, sourceProbeFile, truncatedFile},
  ! FileExistsQ[#1] &];
passed = And[operationalPassed, roundtripPassed,
  fingerprintCorruptionRejected, payloadCorruptionRejected,
  cacheKeyCorruptionRejected, relocatedExactCopyAccepted,
  sourceMutationRejected, truncationRejected, temporaryFilesRemoved,
  sourcesStable, messagesEmpty];
report = <|"Status" -> If[passed,
    "DirectRootChannelCompiledArtifactValidationPassed",
    "DirectRootChannelCompiledArtifactValidationFailed"],
  "ValidationContract" ->
    "DirectRootChannelCompiledArtifactAdversarialValidationV1",
  "ValidatorDriverFile" -> validatorDriverFile,
  "ValidatorDriverSHA256" -> driverHashBefore,
  "CacheFile" -> cacheFile, "CacheFileSHA256" -> cacheHashBefore,
  "CacheKey" -> artifact["CacheKey"],
  "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
  "ReadAndFullValidationSeconds" -> readSeconds,
  "OperationalEpsilonCollapseSeconds" -> operationalSeconds,
  "OperationalEpsilonCollapsePassed" -> operationalPassed,
  "ExactPutGetRoundTripPassed" -> roundtripPassed,
  "CompiledFingerprintCorruptionRejected" ->
    fingerprintCorruptionRejected,
  "CompiledPayloadCorruptionRejected" -> payloadCorruptionRejected,
  "CacheKeyCorruptionRejected" -> cacheKeyCorruptionRejected,
  "RelocatedExactSourceCopyAccepted" -> relocatedExactCopyAccepted,
  "TemporarySourceMutationRejected" -> sourceMutationRejected,
  "TruncatedArtifactRejected" -> truncationRejected,
  "TemporaryFilesRemoved" -> temporaryFilesRemoved,
  "SourcesStableAtCompletion" -> sourcesStable,
  "CapturedMessages" -> messages, "MessagesEmpty" -> messagesEmpty,
  "ExpectedRuntimeSourceHashes" -> expectedRuntimeHashes,
  "CurrentRuntimeSourceHashes" -> currentRuntimeHashes[],
  "ExpectedRecursiveSourceHashes" ->
    provenance["RecursiveSourceHashes"],
  "CurrentRecursiveSourceHashes" -> recursiveCurrent[]|>;
If[writeAtomic[report] === $Failed, Exit[98]];
Print["DRCA_CACHE_VALIDATE milestone=complete status=", report["Status"],
  " output=", outputFile];
Exit[If[passed, 0, 1]];
