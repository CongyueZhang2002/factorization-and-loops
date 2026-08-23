#!/usr/bin/env wolframscript

$HistoryLength = 0;
campaignStart = AbsoluteTime[];
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["CF300_DRCAV2_BENCHMARK FAIL usage=<project-root> " <>
    "<prepared-a0-artifact.wl> <fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerFile = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh", "DirectRootChannelAssembler.wl"}];
compilerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelCompilerV2.wl"}];
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
    ! FileExistsQ[assemblerFile] || ! FileExistsQ[compilerFile] ||
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

sourceHashes[] := <|
  "Preparation" -> FileHash[preparationFile, "SHA256", "HexString"],
  "Dependencies" -> Map[
    FileHash[#1, "SHA256", "HexString"] &, dependencyFiles],
  "Assembler" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "CompilerV2" -> FileHash[compilerFile, "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;
expectedHashes = sourceHashes[];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

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
  Get[compilerFile];
  True, $Failed];
Close[loadMessageStream];
$Messages = savedMessages;
loadMessages = Quiet[Check[Import[loadMessageFile, "Text"], $Failed]];
If[FileExistsQ[loadMessageFile], Quiet[DeleteFile[loadMessageFile]]];
If[loadOutcome =!= True || ! StringQ[loadMessages] ||
    StringTrim[loadMessages] =!= "" || sourceHashes[] =!= expectedHashes,
  report = <|"Status" -> "CF300CompilerV2LoadFailed",
    "LoadOutcome" -> loadOutcome, "CapturedLoadMessages" -> loadMessages,
    "ExpectedSourceHashes" -> expectedHashes,
    "ObservedSourceHashes" -> sourceHashes[]|>;
  If[writeAtomic[report] === $Failed, Exit[98]];
  Exit[66]];

runtimeMessageFile = outputFile <> ".runtime-messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
runtimeMessageStream = OpenWrite[runtimeMessageFile,
  CharacterEncoding -> "UTF8"];
$Messages = {runtimeMessageStream};
Print["CF300_DRCAV2_BENCHMARK milestone=load_complete elapsed_s=",
  N[AbsoluteTime[] - campaignStart]];

preparationArtifact = FeynFacet`FamilyArtifactRead[preparationFile];
preparation = If[AssociationQ[preparationArtifact],
  Lookup[preparationArtifact, "Preparation", $Failed], $Failed];
If[! AssociationQ[preparationArtifact] || ! AssociationQ[preparation] ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation] ||
    Lookup[preparation, "RootCount", None] =!= 2 ||
    Lookup[preparation, "GradeCount", None] =!= 4 ||
    Lookup[preparation, "Dimensions", None] =!= {2, 2} ||
    Lookup[preparation, "GaugeUnknownCount", None] =!= 480 ||
    Lookup[preparation, "ResidueUnknownCount", None] =!= 144 ||
    Lookup[preparation, "UnknownCount", None] =!= 624 ||
    Lookup[preparation, "EquationsPerPoint", None] =!= 32 ||
    Length[Lookup[preparation, "GaugeSupport", {}]] =!= 30 ||
    Lookup[preparation, "Normalizations", None] =!= {},
  Close[runtimeMessageStream];
  $Messages = savedMessages;
  report = <|"Status" -> "CF300CompilerV2PreparationInvalid",
    "PreparationStatus" -> Lookup[preparationArtifact, "Status", None],
    "ExpectedSourceHashes" -> expectedHashes|>;
  If[writeAtomic[report] === $Failed, Exit[98]];
  Exit[67]];

metadata = <|
  "SourceABIFingerprint" -> preparation["ABIFingerprint"],
  "RootOrderingFingerprint" -> preparation["RootOrderingFingerprint"]|>;
Print["CF300_DRCAV2_BENCHMARK milestone=v2_core_start"];
{v2CoreSeconds, v2Core} = AbsoluteTiming[
  CodexDirectRootChannelCompilerV2`DRCAV2CompileCore[
    preparation["Record"], preparation["Roots"],
    preparation["GaugeDenominator"], metadata]];
If[Lookup[v2Core, "Status", None] =!=
      "PreparedDirectRootChannelCoreV2" ||
    ! CodexDirectRootChannelCompilerV2`DRCAV2CoreValidQ[v2Core],
  Close[runtimeMessageStream];
  $Messages = savedMessages;
  report = <|"Status" -> "CF300CompilerV2CoreFailed",
    "V2CoreSeconds" -> N[v2CoreSeconds],
    "V2CoreStatus" -> Lookup[v2Core, "Status", None],
    "V2CoreFailureReason" -> Lookup[v2Core, "FailureReason", None]|>;
  If[writeAtomic[report] === $Failed, Exit[98]];
  Exit[68]];
Print["CF300_DRCAV2_BENCHMARK milestone=v2_core_complete seconds=",
  N[v2CoreSeconds]];

Print["CF300_DRCAV2_BENCHMARK milestone=v2_ansatz_start"];
{v2AnsatzSeconds, v2Assembly} = AbsoluteTiming[
  CodexDirectRootChannelCompilerV2`DRCAV2InstantiateAnsatz[
    v2Core, preparation["OneForms"], preparation["GaugeSupport"],
    preparation["Normalizations"]]];
v1View = CodexDirectRootChannelCompilerV2`DRCAV2ToV1Assembly[v2Assembly];
If[Lookup[v2Assembly, "Status", None] =!=
      "PreparedDirectRootChannelsV2" || ! AssociationQ[v1View] ||
    ! CodexDirectRootChannelCompilerV2`DRCAV2AssemblyValidQ[v2Assembly] ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[v1View],
  Close[runtimeMessageStream];
  $Messages = savedMessages;
  report = <|"Status" -> "CF300CompilerV2AnsatzFailed",
    "V2CoreSeconds" -> N[v2CoreSeconds],
    "V2AnsatzSeconds" -> N[v2AnsatzSeconds],
    "V2AssemblyStatus" -> Lookup[v2Assembly, "Status", None],
    "V2FailureReason" -> Lookup[v2Assembly, "FailureReason", None]|>;
  If[writeAtomic[report] === $Failed, Exit[98]];
  Exit[69]];
Print["CF300_DRCAV2_BENCHMARK milestone=v2_ansatz_complete seconds=",
  N[v2AnsatzSeconds]];

Print["CF300_DRCAV2_BENCHMARK milestone=legacy_start"];
{legacySeconds, legacyAssembly} = AbsoluteTiming[
  CodexDirectRootChannelAssembler`DRCAPrepare[preparation]];
If[Lookup[legacyAssembly, "Status", None] =!=
      "PreparedDirectRootChannelsV1" ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      legacyAssembly],
  Close[runtimeMessageStream];
  $Messages = savedMessages;
  report = <|"Status" -> "CF300CompilerV2LegacyReferenceFailed",
    "LegacySeconds" -> N[legacySeconds]|>;
  If[writeAtomic[report] === $Failed, Exit[98]];
  Exit[70]];
Print["CF300_DRCAV2_BENCHMARK milestone=legacy_complete seconds=",
  N[legacySeconds]];

comparisonKeys = {"Status", "SourceABIFingerprint",
  "RootOrderingFingerprint", "RootCount", "GradeCount", "Variables",
  "Regulator", "Dimensions", "GaugeSupport", "OneForms",
  "GaugeDenominator", "Normalizations", "GaugeUnknownCount",
  "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
  "ColumnOrder", "RowOrder", "ExactChannelForms", "CompiledForms",
  "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
  "CompiledFormsShapeFingerprint", "SourceSemanticFingerprint",
  "AssemblyFingerprint"};
exactAssemblyEqual = SameQ[KeyTake[v1View, comparisonKeys],
  KeyTake[legacyAssembly, comparisonKeys]];

Print["CF300_DRCAV2_BENCHMARK milestone=support_rebind_start"];
stressSupport = Union[preparation["GaugeSupport"],
  Flatten[Table[{xDegree, yDegree}, {xDegree, 0, 6},
    {yDegree, 0, 7}], 1]];
{supportRebindSeconds, supportRebind} = AbsoluteTiming[
  CodexDirectRootChannelCompilerV2`DRCAV2RebindAnsatz[
    v2Assembly, preparation["OneForms"], stressSupport,
    preparation["Normalizations"]]];
{supportFreshSeconds, supportFresh} = AbsoluteTiming[
  CodexDirectRootChannelCompilerV2`DRCAV2InstantiateAnsatz[
    v2Core, preparation["OneForms"], stressSupport,
    preparation["Normalizations"]]];
supportRebindExact =
  Lookup[supportRebind, "Status", None] ===
      "PreparedDirectRootChannelsV2" &&
  Lookup[supportFresh, "Status", None] ===
      "PreparedDirectRootChannelsV2" &&
  supportRebind["Telemetry", "Mode"] === "SupportOrNormalizationOnly" &&
  supportRebind["CompatibilityAssemblyV1"] ===
    supportFresh["CompatibilityAssemblyV1"];

Close[runtimeMessageStream];
$Messages = savedMessages;
runtimeMessages = Quiet[Check[Import[runtimeMessageFile, "Text"], $Failed]];
If[FileExistsQ[runtimeMessageFile], Quiet[DeleteFile[runtimeMessageFile]]];
hashesStable = TrueQ[sourceHashes[] === expectedHashes];
messagesEmpty = StringQ[runtimeMessages] && StringTrim[runtimeMessages] === "";
v2TotalSeconds = N[v2CoreSeconds + v2AnsatzSeconds];
speedup = If[v2TotalSeconds > 0, N[legacySeconds/v2TotalSeconds],
  Indeterminate];
passed = TrueQ[exactAssemblyEqual && supportRebindExact &&
  hashesStable && messagesEmpty];
report = <|
  "Status" -> If[passed, "CF300CompilerV2BenchmarkPassed",
    "CF300CompilerV2BenchmarkFailed"],
  "Protocol" -> "CF300Sector12DirectCompilerV2BenchmarkV1",
  "PreparationFile" -> preparationFile,
  "PreparationSHA256" -> expectedHashes["Preparation"],
  "ExactV1AssemblyEqual" -> exactAssemblyEqual,
  "SupportRebindExact" -> supportRebindExact,
  "LegacyCompileSeconds" -> N[legacySeconds],
  "V2CoreCompileSeconds" -> N[v2CoreSeconds],
  "V2AnsatzCompileSeconds" -> N[v2AnsatzSeconds],
  "V2TotalCompileSeconds" -> v2TotalSeconds,
  "LegacyOverV2Speedup" -> speedup,
  "SupportRebindSeconds" -> N[supportRebindSeconds],
  "SupportFreshSeconds" -> N[supportFreshSeconds],
  "SupportCountBefore" -> Length[preparation["GaugeSupport"]],
  "SupportCountAfter" -> Length[stressSupport],
  "CoreTelemetry" -> v2Core["Telemetry"],
  "AnsatzTelemetry" -> v2Assembly["Telemetry"],
  "SupportRebindTelemetry" -> Lookup[supportRebind, "Telemetry", <||>],
  "LegacyAssemblyFingerprint" -> legacyAssembly["AssemblyFingerprint"],
  "V2AdapterAssemblyFingerprint" -> v1View["AssemblyFingerprint"],
  "CapturedRuntimeMessages" -> runtimeMessages,
  "MessagesEmpty" -> messagesEmpty,
  "SourceHashesStable" -> hashesStable,
  "ExpectedSourceHashes" -> expectedHashes,
  "ObservedSourceHashes" -> sourceHashes[],
  "CampaignSeconds" -> N[AbsoluteTime[] - campaignStart]|>;
If[writeAtomic[report] === $Failed, Exit[98]];
Print["CF300_DRCAV2_BENCHMARK status=", report["Status"],
  " legacy_s=", N[legacySeconds], " v2_s=", v2TotalSeconds,
  " speedup=", speedup, " output=", outputFile];
Exit[If[passed, 0, 1]];
