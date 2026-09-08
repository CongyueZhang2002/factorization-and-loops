#!/usr/bin/env wolframscript
(* Post-integration, serial adversarial gate for bounded failure records and
   exact SolverConfiguration binding during resume. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
defaultRoot = ParentDirectory[ParentDirectory[ParentDirectory[
  DirectoryName[ExpandFileName[$InputFileName]]]]];
root = If[Length[arguments] >= 1, ExpandFileName[arguments[[1]]],
  defaultRoot];
resultFile = If[Length[arguments] >= 2,
  ExpandFileName[arguments[[2]]], None];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
checks = <||>;
putResult[value_, file_String] := Module[{temporary = file <> ".tmp"},
  Put[value, temporary]; RenameFile[temporary, file,
    OverwriteTarget -> True]];

rationalFrame = <|"Name" -> "RationalIdentity",
  "CoefficientField" -> "Rational"|>;
algebraicFrame = <|"Name" -> "TripleRootIdentity",
  "CoefficientField" -> "Multiquadratic", "Variables" -> {vCfg, wCfg},
  "Subst" -> {vCfg -> vCfg, wCfg -> wCfg},
  "Roots" -> {<|"Root" -> r1Cfg, "RootSquare" -> vCfg|>,
    <|"Root" -> r2Cfg, "RootSquare" -> wCfg|>}, "Parents" -> {}|>;
configuration = FeynFacet`Private`familyRowGaugeSolverConfiguration;
validQ = FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ;
resumeCheck =
  FeynFacet`Private`familyRowGaugeResumeSolverConfigurationCheck;
refingerprint[configuration_Association] := Module[{payload =
    KeyDrop[configuration, "Fingerprint"]},
  Join[payload, <|"Fingerprint" -> Hash[KeySort[payload],
    "SHA256", "HexString"]|>]];

direct = configuration["DirectRationalFiniteField", "Rational",
  rationalFrame, "Numerical", Automatic, 2, "Wolfram"];
chart = configuration["RationalChartFiniteField", "Multiquadratic",
  algebraicFrame, "Numerical", Automatic, 2, "Wolfram"];
zero = configuration["ZeroForcing", "Rational", rationalFrame,
  None, None, None, None];
checks["AllSupportedConfigurationsSeal"] = And @@ (validQ /@
  {direct, chart, zero});
checks["ConfigurationsHaveExactSchema"] = And @@
  (Sort[Keys[#]] === Sort[
      FeynFacet`Private`$familyRowGaugeSolverConfigurationRequiredKeys] & /@
    {direct, chart, zero});
checks["RouteFieldMismatchRejected"] =
  configuration["RationalChartFiniteField", "Rational", rationalFrame,
    "Numerical", Automatic, 2, "Wolfram"]["Status"] ===
      "InconsistentSolverConfigurationRoute";
checks["InvalidBackendRejectedByConfiguration"] =
  configuration["DirectRationalFiniteField", "Rational", rationalFrame,
    "Numerical", "TypoBackend", 2, "Wolfram"]["Status"] ===
      "InvalidSolverConfigurationArguments";
checks["FingerprintMutationRejected"] = ! validQ[Join[direct,
  <|"Fingerprint" -> StringRepeat["0", 64]|>]];
checks["ExtraKeyRejected"] = ! validQ[Join[direct,
  <|"Injected" -> True|>]];
checks["ProvenanceMutationRejected"] = ! validQ[Join[direct,
  <|"ImplementationProvenance" -> Join[
    direct["ImplementationProvenance"],
    <|"SolverABIVersion" -> 99|>]|>]];
checks["BackendImplementationProvenanceMutationRejected"] =
  ! validQ[refingerprint[Join[direct,
    <|"BackendImplementationProvenance" ->
      Join[direct["BackendImplementationProvenance"],
        <|"FLINTBinarySHA256" -> StringRepeat["0", 64]|>]|>]]];
checks["PlanDiscoveryBackendMutationRejected"] =
  ! validQ[refingerprint[Join[direct,
    <|"PlanDiscoveryBackend" -> "FLINTAffineRREF"|>]]];
checks["CompleteImplementationProvenancePresent"] =
  ContainsAll[Keys[direct["ImplementationProvenance", "SourceSHA256"]],
    {"FiniteFieldStripSolve.wl", "FamilyRowGaugeResume.wl",
      "FamilyRowGauge.wl", "family_epsform_sector.wls"}] &&
  StringQ[direct["BackendImplementationProvenance",
    "FiniteFieldStripSolveSHA256"]];
checks["ResealedInvalidThreadCountRejected"] = ! validQ[refingerprint[
  Join[direct, <|"FiniteFieldBackendThreads" -> 9|>]]];
checks["ResealedInvalidFinalCheckRejected"] = ! validQ[refingerprint[
  Join[direct, <|"FinalCheck" -> "Approximate"|>]]];

exactSummary = <|"Method" -> "SimultaneousFiniteFieldAffinePDE",
  "SolverConfiguration" -> direct|>;
checks["ExactConfigurationAccepted"] =
  resumeCheck[exactSummary, direct] ===
    <|"Status" -> "OK", "Mode" -> "Exact"|>;
otherDirect = configuration["DirectRationalFiniteField", "Rational",
  rationalFrame, "Numerical", "Wolfram", 2, "Wolfram"];
checks["BackendRequestChangeRejected"] =
  resumeCheck[<|"Method" -> "SimultaneousFiniteFieldAffinePDE",
    "SolverConfiguration" -> otherDirect|>, direct]["Status"] ===
      "ResumeSolverConfigurationMismatch";
checks["LegacyDirectCheckpointRejected"] =
  resumeCheck[<|"Method" ->
    "SimultaneousFiniteFieldAffinePDE"|>, direct]["Status"] ===
      "ResumeSolverConfigurationMissing";
checks["PresentNonAssociationConfigurationRejected"] =
  resumeCheck[<|"Method" ->
      "RationalChart/CF300Pair/SimultaneousFiniteFieldAffinePDE",
    "SolverConfiguration" -> 1|>, chart]["Status"] ===
      "ResumeSolverConfigurationInvalid";
checks["LegacyRationalChartCheckpointAcceptedNarrowly"] =
  resumeCheck[<|"Method" ->
    "RationalChart/CF300Pair/SimultaneousFiniteFieldAffinePDE"|>,
      chart] === <|"Status" -> "OK",
        "Mode" -> "LegacyRationalChart"|>;
checks["LegacyRationalFrameCheckpointAcceptedNarrowly"] =
  resumeCheck[<|"Method" ->
    "RationalFrame/SimultaneousFiniteFieldAffinePDE"|>, chart] ===
      <|"Status" -> "OK", "Mode" -> "LegacyRationalChart"|>;
checks["FutureDirectMultiquadraticCannotMasqueradeAsChart"] =
  resumeCheck[<|"Method" ->
    "DirectMultiquadraticFiniteField"|>, chart]["Status"] ===
      "ResumeSolverConfigurationMissing";
checks["DirectConfigurationCannotReplayThroughChart"] =
  resumeCheck[<|"Method" -> "DirectMultiquadraticFiniteField",
    "SolverConfiguration" -> direct|>, chart]["Status"] ===
      "ResumeSolverConfigurationMismatch";
checks["LegacyZeroForcingAccepted"] =
  resumeCheck[<|"Method" -> "ZeroForcing"|>, zero] ===
    <|"Status" -> "OK", "Mode" -> "LegacyZeroForcing"|>;

hugeFailure = <|"Status" -> "NoRationalStripChart",
  "Method" -> "RationalChart/Failed", "RootIndices" -> {1, 2, 3},
  "RootSquares" -> StringRepeat["root-square-payload", 2000],
  "Gauge" -> ConstantArray[1, {200, 200}],
  "Samples" -> ConstantArray[1, 100000],
  "InnerSolution" -> <|"DensePayload" ->
    ConstantArray[1, {100, 100}]|>|>;
failureSummary =
  FeynFacet`Private`familyRowGaugeSolverFailureSummary[hugeFailure];
checks["TypedFailureStatusPreserved"] =
  failureSummary["Status"] === "NoRationalStripChart";
checks["LargePayloadKeysNeverPersisted"] =
  FreeQ[failureSummary, "Gauge" | "Samples" | "InnerSolution"];
checks["WhitelistedLargeDiagnosticElided"] =
  TrueQ[failureSummary["Diagnostics", "RootSquares", "Elided"]] &&
  StringLength[
    failureSummary["Diagnostics", "RootSquares", "SHA256"]] === 64;
checks["FailureSummaryBounded"] = ByteCount[failureSummary] < 100000;
checks["DollarFailedGetsTypedSummary"] =
  FeynFacet`Private`familyRowGaugeSolverFailureSummary[$Failed]["Status"] ===
    "SolverReturnedFailed";
checks["NonAssociationReturnGetsTypedSummary"] =
  FeynFacet`Private`familyRowGaugeSolverFailureSummary[17]["Status"] ===
    "InvalidSolverReturn";
oversizedStatusSummary =
  FeynFacet`Private`familyRowGaugeSolverFailureSummary[
    <|"Status" -> StringRepeat["S", 100000]|>];
checks["OversizedStatusNeverPersists"] =
  oversizedStatusSummary["Status"] ===
      "SolverAssociationWithInvalidStatus" &&
    ByteCount[oversizedStatusSummary] < 100000;

(* Exercise the actual hydration gate on a zero strip: a semantically wrong,
   but individually valid, configuration must be rejected before replay. *)
Clear[xResumeCfg, yResumeCfg, epsResumeCfg];
temporary = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "FeynFacet-solver-configuration-test-" <> CreateUUID[]}]];
ranges = {{1}, {2}};
connection = ConstantArray[0, {2, 2, 2}];
input = <|"Family" -> "CFCONFIG", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {xResumeCfg, yResumeCfg},
  "Regulator" -> epsResumeCfg,
  "Strip" -> ConstantArray[0, {3, 2, 1, 1}]|>;
inputFile = FileNameJoin[{temporary, "CFCONFIG_2_1_input.wl"}];
FeynFacet`FamilyArtifactWrite[input, inputFile];
wrongSummary = <|"Sector" -> 2, "LowerSector" -> 1,
  "Method" -> "ZeroForcing", "ExactDLog" -> True,
  "SolverConfiguration" -> direct|>;
checkpoint = <|"Sector" -> 2, "SubSize" -> 1,
  "Truncation" -> 2, "PrevD" -> {{0}},
  "ConnectionHash" -> Hash[
    connection /. epsResumeCfg -> CANONICA`eps,
    "SHA256", "HexString"], "StripSolvers" -> {wrongSummary}|>;
checkpointFile = FileNameJoin[{temporary, "checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[checkpoint, checkpointFile];
rejected = FeynFacet`Private`familyRowGaugeHydrateResume[
  checkpoint, checkpointFile, <|1 -> {{0}}|>, <||>, "CFCONFIG", 2,
  {xResumeCfg, yResumeCfg}, epsResumeCfg, rationalFrame, ranges,
  temporary, connection, "KernelCount" -> 1, "FinalCheck" -> "Exact"];
checks["HydrationRejectsWrongConfigurationBeforeReplay"] =
  rejected["Status"] === "ResumeSolverConfigurationMismatch" &&
    ! TrueQ[Lookup[rejected, "ActivateInstalledRow", True]];

zeroExact = configuration["ZeroForcing", "Rational", rationalFrame,
  None, None, None, None];
goodCheckpoint = Join[checkpoint, <|"StripSolvers" ->
  {Join[wrongSummary, <|"SolverConfiguration" -> zeroExact|>]}|>];
goodFile = FileNameJoin[{temporary, "good_checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[goodCheckpoint, goodFile];
accepted = FeynFacet`Private`familyRowGaugeHydrateResume[
  goodCheckpoint, goodFile, <|1 -> {{0}}|>, <||>, "CFCONFIG", 2,
  {xResumeCfg, yResumeCfg}, epsResumeCfg, rationalFrame, ranges,
  temporary, connection, "KernelCount" -> 1, "FinalCheck" -> "Exact"];
checks["HydrationAcceptsExactZeroConfiguration"] =
  accepted["Status"] === "Hydrated" &&
    TrueQ[accepted["ActivateInstalledRow"]] &&
    Lookup[First[Lookup[accepted, "ReplayRecords", {}]],
      "SolverConfigurationMode", None] === "Exact";
hydrationDiagnostics = <|
  "Rejected" -> KeyTake[rejected,
    {"Status", "ActivateInstalledRow", "LowerSector"}],
  "Accepted" -> KeyTake[accepted,
    {"Status", "ActivateInstalledRow", "LowerSector",
      "MissingLowerSectors"}],
  "AcceptedReplayRecords" -> Lookup[accepted, "ReplayRecords", None]|>;
If[DirectoryQ[temporary],
  Quiet[DeleteDirectory[temporary, DeleteContents -> True]]];

result = <|"Status" -> If[And @@ Values[checks], "OK", "Failed"],
  "Purpose" -> "SolverConfigurationResumeAdversarialV1",
  "Checks" -> checks,
  "HydrationDiagnostics" -> hydrationDiagnostics,
  "SourceHashes" -> Association@Table[file ->
    FileHash[FileNameJoin[{root, file}], "SHA256", "HexString"],
    {file, {"FeynFacet/Private/FamilyRowGaugeResume.wl",
      "Scripts/family_epsform_sector.wls"}}]|>;
If[StringQ[resultFile], putResult[result, resultFile]];
Print["SOLVER_CONFIGURATION_RESUME status=", result["Status"],
  " checks=", Count[Values[checks], True], "/", Length[checks]];
If[result["Status"] =!= "OK", Print[InputForm[result]]];
Exit[If[result["Status"] === "OK", 0, 1]];
