#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 4 || Length[arguments] > 5,
  Print["CF300_REBIND_GATE FAIL usage=<project-root> <preparation.wl> " <>
    "<compiled-a0-cache.wl> <fresh-output.wl> [QUICK|FULL]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
cacheFile = ExpandFileName[arguments[[3]]];
outputFile = ExpandFileName[arguments[[4]]];
mode = If[Length[arguments] === 5, arguments[[5]], "QUICK"];
driverDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[driverDirectory];
directDirectory = FileNameJoin[{exchangeDirectory,
  "direct_root_channel_assembler_xh"}];

files = <|
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
    "TripleRootReconstructionPrototype.wl"}],
  "DirectRootChannelAssembler" -> FileNameJoin[{directDirectory,
    "DirectRootChannelAssembler.wl"}],
  "DirectRootChannelCompiledArtifact" -> FileNameJoin[{directDirectory,
    "DirectRootChannelCompiledArtifact.wl"}],
  "DirectRootChannelAnsatzRebind" -> FileNameJoin[{driverDirectory,
    "DirectRootChannelAnsatzRebind.wl"}]|>;

expectedHashes = <|
  "LoadFACET" ->
    "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164",
  "FeynFacetPublic" ->
    "4af4f6a8c3b9201ba6e1088e7fec94b6f0befc1d37bc2d76f43e5509fa64ac9e",
  "FiniteFieldStripSolve" ->
    "c6230ae8b6b1d00780ca697cf9e6838a395682a7eabe626b17c8371357bb1671",
  "FiniteFieldEpsForm" ->
    "c6dce4f78bd90238b815885e3d622d23aee3cf799a484419ef07d15763e97091",
  "FamilyEpsForm" ->
    "436c3fc6216e7be3ee1fce41dd1c98f91f1ce733aff27308214275f1a8221ce4",
  "TransportCharts" ->
    "c30e2e54b63abe9eb6c3b82ec2d275b8f4bb247007f2a93fa7db879399de051a",
  "TripleRootAlgebra" ->
    "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab",
  "TripleRootStripAdapter" ->
    "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5",
  "TripleRootAffinePilot" ->
    "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90",
  "TripleRootReconstructionPrototype" ->
    "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43",
  "DirectRootChannelAssembler" ->
    "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6",
  "DirectRootChannelCompiledArtifact" ->
    "8393a31f03f211c9751163cdd299828a86ba49ea0052309f29abaa3f0eb97557",
  "DirectRootChannelAnsatzRebind" ->
    "8b0f8d7fdab72d9660836d1f2a92e7f03be5eb1adcbd7082b327ed4bb8b8e907"|>;
expectedPreparationSHA256 =
  "a674f449a8d46e7655f1b74927420ed4dcb42f7a07f1294fcbdd3ae64e13c8f6";
expectedCacheSHA256 =
  "0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be";

hashes[] := Map[FileHash[#1, "SHA256", "HexString"] &, files];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
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
  result = Join[<|"Status" -> status, "Mode" -> mode,
    "PreparationFile" -> preparationFile, "CacheFile" -> cacheFile|>,
    data];
  If[writeAtomic[result] === $Failed, Exit[98]];
  Print["CF300_REBIND_GATE status=", status, " output=", outputFile];
  Exit[code]
];

If[! DirectoryQ[projectRoot] ||
    ! AllTrue[Values[files], FileExistsQ] ||
    ! FileExistsQ[preparationFile] || ! FileExistsQ[cacheFile] ||
    ! MemberQ[{"QUICK", "FULL"}, mode] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]],
  Print["CF300_REBIND_GATE FAIL invalid inputs or stale output"];
  Exit[65]];
If[hashes[] =!= expectedHashes ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationSHA256 ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheSHA256,
  Print["CF300_REBIND_GATE FAIL pinned source or artifact mismatch"];
  Exit[66]];

driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
sourceHashesBefore = hashes[];
loadOutcome = Quiet[Check[
  Get[files["LoadFACET"]];
  Get[files["TripleRootAlgebra"]];
  Get[files["TripleRootStripAdapter"]];
  Get[files["TripleRootAffinePilot"]];
  Get[files["TripleRootReconstructionPrototype"]];
  Get[files["DirectRootChannelAssembler"]];
  Get[files["DirectRootChannelCompiledArtifact"]];
  Get[files["DirectRootChannelAnsatzRebind"]];
  True, $Failed]];
If[loadOutcome =!= True || hashes[] =!= sourceHashesBefore ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["PinnedLoadFailed", <||>, 67]];

preparationArtifact = FeynFacet`FamilyArtifactRead[preparationFile];
compiledArtifact =
  CodexDirectRootChannelCompiledArtifact`DRCAReadCompiledArtifact[
    cacheFile];
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    ! AssociationQ[compiledArtifact] ||
    Lookup[compiledArtifact, "Status", None] =!=
      "DirectRootChannelCompiledArtifactV1",
  finish["PinnedArtifactsInvalid", <||>, 68]];
basePreparation = preparationArtifact["Preparation"];
baseAssembly = compiledArtifact["DirectAssembly"];
If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      basePreparation] ||
    ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      baseAssembly] ||
    baseAssembly["SourceABIFingerprint"] =!=
      basePreparation["ABIFingerprint"] ||
    basePreparation["GaugeSupport"] =!= baseAssembly["GaugeSupport"] ||
    basePreparation["OneForms"] =!= baseAssembly["OneForms"] ||
    basePreparation["GaugeDenominator"] =!=
      baseAssembly["GaugeDenominator"],
  finish["BasePreparationCacheBindingInvalid", <||>, 69]];

buildTarget[support_List, oneForms_List, denominator_, tag_String] :=
    Module[{dimensions, gradeCount, gaugeCount, residueCount,
      payload, target},
  dimensions = basePreparation["Dimensions"];
  gradeCount = basePreparation["GradeCount"];
  gaugeCount = Times @@ dimensions gradeCount Length[support];
  residueCount = Length[oneForms] Times @@ dimensions;
  payload = CodexTripleRootReconstruction`Private`trBuildABIPayload[
    basePreparation["Record"], basePreparation["Roots"],
    basePreparation["Variables"], basePreparation["Regulator"],
    dimensions, denominator, support, oneForms,
    basePreparation["Normalizations"]];
  If[payload === $Failed, Return[$Failed]];
  target = Join[basePreparation, <|
    "OneForms" -> oneForms,
    "OneFormMetadata" -> <|"Status" -> tag,
      "BaseCount" -> Length[basePreparation["OneForms"]],
      "TargetCount" -> Length[oneForms]|>,
    "GaugeDenominator" -> Together[denominator],
    "GaugeDenominatorDegrees" ->
      (Exponent[denominator, #1] & /@ basePreparation["Variables"]),
    "GaugeSupport" -> support,
    "GaugeUnknownCount" -> gaugeCount,
    "ResidueUnknownCount" -> residueCount,
    "UnknownCount" -> gaugeCount + residueCount,
    "ABIPayload" -> payload,
    "ABIFingerprint" -> fingerprint[payload]|>];
  If[CodexTripleRootReconstruction`TRPreparationABIValidQ[target],
    target, $Failed]
];

baseSupport = basePreparation["GaugeSupport"];
supportOffset22 = Flatten[Table[{px, py},
  {px, 0, basePreparation["GaugeDenominatorDegrees"][[1]] + 2},
  {py, 0, basePreparation["GaugeDenominatorDegrees"][[2]] + 2}], 1];
{x, y} = basePreparation["Variables"];
denominatorFactor = 1 + x;
changedDenominator = Together[
  basePreparation["GaugeDenominator"] denominatorFactor];
changedDenominatorDegrees = Exponent[changedDenominator, #1] & /@
  basePreparation["Variables"];
denominatorSupport = Flatten[Table[{px, py},
  {px, 0, changedDenominatorDegrees[[1]]},
  {py, 0, changedDenominatorDegrees[[2]]}], 1];
denominatorFactorSupport = First /@
  CoefficientRules[Expand[denominatorFactor], {x, y}];
requiredOldGaugeNumeratorSupport = Union[Flatten[Table[
  oldMonomial + factorMonomial,
  {oldMonomial, baseSupport},
  {factorMonomial, denominatorFactorSupport}], 1]];
oldGaugeContainedInChangedDenominatorQ =
  Complement[requiredOldGaugeNumeratorSupport, denominatorSupport] === {};
letterPotential = 1 + x + 2 y;
appendedOneForm = {D[letterPotential, x]/letterPotential,
  D[letterPotential, y]/letterPotential};
extendedForms = Append[basePreparation["OneForms"], appendedOneForm];

supportTarget = buildTarget[supportOffset22,
  basePreparation["OneForms"], basePreparation["GaugeDenominator"],
  "PhysicalSupportOffset22GateV1"];
denominatorTarget = buildTarget[denominatorSupport,
  basePreparation["OneForms"], changedDenominator,
  "PhysicalDenominatorRebindGateV1"];
oneFormTarget = buildTarget[baseSupport, extendedForms,
  basePreparation["GaugeDenominator"],
  "PhysicalAppendedOneFormGateV1"];
combinedTarget = buildTarget[supportOffset22, extendedForms,
  changedDenominator, "PhysicalCombinedAnsatzRebindGateV1"];
If[MemberQ[{supportTarget, denominatorTarget, oneFormTarget,
      combinedTarget}, $Failed] ||
    ! TrueQ[oldGaugeContainedInChangedDenominatorQ],
  finish["TargetPreparationConstructionFailed", <||>, 70]];

{sameSeconds, sameAssembly} = AbsoluteTiming[
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, basePreparation]];
{supportSeconds, supportAssembly} = AbsoluteTiming[
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, supportTarget]];
{denominatorSeconds, denominatorAssembly} = AbsoluteTiming[
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, denominatorTarget]];
{oneFormSeconds, oneFormAssembly} = AbsoluteTiming[
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, oneFormTarget]];
{combinedSeconds, combinedAssembly} = AbsoluteTiming[
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, combinedTarget]];
assemblies = {sameAssembly, supportAssembly, denominatorAssembly,
  oneFormAssembly, combinedAssembly};
If[sameAssembly =!= baseAssembly ||
    ! AllTrue[Rest[assemblies],
      CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ] ||
    KeyTake[supportAssembly["CompiledForms"],
      {"E", "C", "BBar", "RootSquares", "RootLogDerivatives"}] =!=
      KeyTake[baseAssembly["CompiledForms"],
        {"E", "C", "BBar", "RootSquares", "RootLogDerivatives"}] ||
    supportAssembly["GaugeSupport"] =!= supportOffset22 ||
    denominatorAssembly["GaugeDenominator"] =!= changedDenominator ||
    oneFormAssembly["OneForms"] =!= extendedForms ||
    combinedAssembly["SourceABIFingerprint"] =!=
      combinedTarget["ABIFingerprint"],
  finish["ReboundAssemblyContractFailed", <||>, 71]];

candidatePoints = {{4478, 1297}, {1960, 1050}, {901, 2502},
  {7529, 2454}, {1109, 2997}};
sampleOptions = {"PointCount" -> Length[candidatePoints],
  "MaximumAttempts" -> Length[candidatePoints],
  "RandomSeed" -> 2026082312, "CandidatePoints" -> candidatePoints,
  "BranchFlipMask" -> 0};
baseSample = CodexDirectRootChannelAssembler`DRCAAssembleSample[
  baseAssembly, 1/21, 10039, Sequence @@ sampleOptions];
supportSample = CodexDirectRootChannelAssembler`DRCAAssembleSample[
  supportAssembly, 1/21, 10039, Sequence @@ sampleOptions];
If[Lookup[baseSample, "Status", None] =!=
      "AssembledDirectRootChannelSampleV1" ||
    Lookup[supportSample, "Status", None] =!=
      "AssembledDirectRootChannelSampleV1" ||
    baseSample["AcceptedPoints"] =!= candidatePoints ||
    supportSample["AcceptedPoints"] =!= candidatePoints,
  finish["PhysicalSupportSampleAssemblyFailed", <||>, 72]];

{upper, lower} = basePreparation["Dimensions"];
gradeCount = basePreparation["GradeCount"];
baseSupportCount = Length[baseSupport];
targetSupportCount = Length[supportOffset22];
supportPositions = First /@ (FirstPosition[supportOffset22, #1,
    Missing["AbsentBaseSupport"]] & /@ baseSupport);
If[! VectorQ[supportPositions, IntegerQ],
  finish["SupportProjectionMapFailed", <||>, 73]];
gaugeProjection = Flatten[Table[
  (((i - 1) lower + (j - 1)) gradeCount + grade)
      targetSupportCount + supportPositions[[monomial]],
  {i, upper}, {j, lower}, {grade, 0, gradeCount - 1},
  {monomial, baseSupportCount}]];
residueProjection = supportAssembly["GaugeUnknownCount"] +
  Range[baseAssembly["ResidueUnknownCount"]];
projection = Join[gaugeProjection, residueProjection];
If[supportSample["Matrix"][[All, projection]] =!=
      baseSample["Matrix"] ||
    supportSample["RightHandSide"] =!= baseSample["RightHandSide"],
  finish["PhysicalSupportProjectionDifferentialFailed", <||>, 74]];

nonPrefixTarget = buildTarget[baseSupport,
  Reverse[basePreparation["OneForms"]],
  basePreparation["GaugeDenominator"], "NonPrefixMutant"];
nonPrefixResult = If[AssociationQ[nonPrefixTarget],
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    baseAssembly, nonPrefixTarget], $Failed];
sourceMutant = ReplacePart[baseAssembly,
  "PrototypeSourceSHA256" -> StringRepeat["0", 64]];
sourceMutantResult =
  CodexDirectRootChannelAnsatzRebind`DRCARebindAnsatz[
    sourceMutant, basePreparation];
If[Lookup[nonPrefixResult, "Status", None] =!=
      "DirectRootChannelAnsatzRebindFailure" ||
    Lookup[sourceMutantResult, "Status", None] =!=
      "DirectRootChannelAnsatzRebindFailure",
  finish["AdversarialMutantAccepted", <||>, 75]];

freshSeconds = Missing["QuickMode"];
freshAssemblySameQ = Missing["QuickMode"];
If[mode === "FULL",
  {freshSeconds, freshAssembly} = AbsoluteTiming[
    TimeConstrained[MemoryConstrained[
      CodexDirectRootChannelAssembler`DRCAPrepare[combinedTarget],
      6 2^30, $Failed], 2400, $Failed]];
  freshAssemblySameQ = SameQ[freshAssembly, combinedAssembly];
  If[! TrueQ[freshAssemblySameQ],
    finish["FullFreshCompileDifferentialFailed", <|
      "FreshCompileSeconds" -> freshSeconds,
      "FreshStatus" -> Lookup[freshAssembly, "Status", None]|>, 76]];
];

If[hashes[] =!= sourceHashesBefore ||
    FileHash[preparationFile, "SHA256", "HexString"] =!=
      expectedPreparationSHA256 ||
    FileHash[cacheFile, "SHA256", "HexString"] =!= expectedCacheSHA256 ||
    FileHash[$InputFileName, "SHA256", "HexString"] =!= driverHashBefore,
  finish["SourceOrArtifactChangedDuringGate", <||>, 95]];

finish["CF300Sector12DirectAnsatzRebindGatePassed", <|
  "PreparationSHA256" -> expectedPreparationSHA256,
  "CompiledCacheSHA256" -> expectedCacheSHA256,
  "SourceHashes" -> sourceHashesBefore,
  "DriverSHA256" -> driverHashBefore,
  "RebindSeconds" -> <|"Identity" -> sameSeconds,
    "SupportOffset22" -> supportSeconds,
    "DenominatorOnly" -> denominatorSeconds,
    "OneFormOnly" -> oneFormSeconds,
    "Combined" -> combinedSeconds|>,
  "TargetSummaries" -> <|
    "SupportOffset22" -> <|"SupportCount" -> Length[supportOffset22],
      "UnknownCount" -> supportTarget["UnknownCount"]|>,
    "DenominatorOnly" -> <|"DenominatorFactor" -> denominatorFactor,
      "SupportCount" -> Length[denominatorSupport],
      "UnknownCount" -> denominatorTarget["UnknownCount"],
      "OldGaugeNumeratorSupportRequired" ->
        requiredOldGaugeNumeratorSupport,
      "OldGaugeSubspaceContained" ->
        oldGaugeContainedInChangedDenominatorQ|>,
    "OneFormOnly" -> <|"AppendedPotential" -> letterPotential,
      "OneFormCount" -> Length[extendedForms],
      "UnknownCount" -> oneFormTarget["UnknownCount"]|>,
    "Combined" -> <|"SupportCount" -> Length[supportOffset22],
      "OneFormCount" -> Length[extendedForms],
      "UnknownCount" -> combinedTarget["UnknownCount"]|>|>,
  "PhysicalProjectionPrime" -> 10039,
  "PhysicalProjectionEpsilonValue" -> 1/21,
  "PhysicalProjectionPoints" -> candidatePoints,
  "PhysicalProjectionMatrixFingerprint" ->
    Hash[baseSample["Matrix"], "SHA256", "HexString"],
  "PhysicalProjectionRightFingerprint" ->
    Hash[baseSample["RightHandSide"], "SHA256", "HexString"],
  "NonPrefixMutantFailureReason" ->
    Lookup[nonPrefixResult, "FailureReason", None],
  "SourceMutantFailureReason" ->
    Lookup[sourceMutantResult, "FailureReason", None],
  "FreshCompileSeconds" -> freshSeconds,
  "FreshCompileSameQ" -> freshAssemblySameQ|>, 0];
