#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["CF300S12SAFETY FAIL usage=<project-root> <result.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
resultFile = ExpandFileName[arguments[[2]]];
safetyResultFile = resultFile;
scriptDirectory = DirectoryName[$InputFileName];
checkedScript = FileNameJoin[{scriptDirectory,
  "run_cf300_sector12_sidecar_checked.wls"}];
tripleRootAlgebraFile = FileNameJoin[{DirectoryName[scriptDirectory],
  "TripleRootAlgebra.wl"}];
stripAdapterFile = FileNameJoin[{DirectoryName[scriptDirectory],
  "TripleRootStripAdapter.wl"}];
workRoot = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "FeynFacet-cf300-s12-safety-" <> CreateUUID[]}]];

writeAtomic[value_, file_String] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[file]],
    CreateDirectory[DirectoryName[file],
      CreateIntermediateDirectories -> True]];
  temporary = file <> ".tmp";
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
Get[tripleRootAlgebraFile];
Get[stripAdapterFile];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilon = Symbol["Global`eps"];
ranges = {{1}, {2}};
connection = {
  {{epsilon/variables[[1]], 0},
   {0, 2 epsilon/variables[[1]]}},
  {{epsilon/variables[[2]], 0},
   {0, 2 epsilon/variables[[2]]}}};
frame = FeynFacet`TransportFamilyChart["CF300"];
solved = <|1 -> {{0}}|>;
forms = <|1 -> {{{0}}, {{0}}}|>;
connectionHash = Hash[connection /. epsilon -> CANONICA`eps,
  "SHA256", "HexString"];
checkpoint = <|"Sector" -> 2, "SubSize" -> 1, "Truncation" -> 2,
  "PrevD" -> {{0}}, "ConnectionHash" -> connectionHash,
  "StripSolvers" -> {<|"Sector" -> 2, "LowerSector" -> 1,
    "Method" -> "ZeroForcing", "ExactDLog" -> False|>},
  "SolvedForms" -> forms|>;
checkpointFile = FileNameJoin[{workRoot, "clean_checkpoint.wl"}];
inputFile = FileNameJoin[{workRoot, "CFTEST_2_1_input.wl"}];
FeynFacet`FamilyArtifactWrite[checkpoint, checkpointFile];
strip = FeynFacet`Private`familyRowGaugeResumeBlockEquation[
  connection, 2, 1, solved, ranges, epsilon];
FeynFacet`FamilyArtifactWrite[<|"Family" -> "CFTEST", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> variables,
  "Regulator" -> epsilon, "Strip" -> strip|>, inputFile];

clean = FeynFacet`Private`familyRowGaugeHydrateResume[
  checkpoint, checkpointFile, solved, forms, "CFTEST", 2,
  variables, epsilon, frame, ranges, workRoot, connection,
  "KernelCount" -> 1, "FinalCheck" -> "Exact",
  "MinimumCachedPrimeCount" -> 1];

corruptForms = <|1 -> {{{1}}, {{0}}}|>;
corruptFormCheckpoint = Join[checkpoint,
  <|"SolvedForms" -> corruptForms|>];
corruptFormFile = FileNameJoin[{workRoot,
  "corrupt_form_checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[corruptFormCheckpoint, corruptFormFile];
corruptFormResult =
  FeynFacet`Private`familyRowGaugeHydrateResume[
    corruptFormCheckpoint, corruptFormFile, solved, corruptForms,
    "CFTEST", 2, variables, epsilon, frame, ranges, workRoot,
    connection, "KernelCount" -> 1, "FinalCheck" -> "Exact",
    "MinimumCachedPrimeCount" -> 1];

corruptSolved = <|1 -> {{1}}|>;
corruptGaugeCheckpoint = Join[checkpoint,
  <|"PrevD" -> {{1}}|>];
corruptGaugeFile = FileNameJoin[{workRoot,
  "corrupt_gauge_checkpoint.wl"}];
FeynFacet`FamilyArtifactWrite[corruptGaugeCheckpoint,
  corruptGaugeFile];
corruptGaugeResult =
  FeynFacet`Private`familyRowGaugeHydrateResume[
    corruptGaugeCheckpoint, corruptGaugeFile, corruptSolved, forms,
    "CFTEST", 2, variables, epsilon, frame, ranges, workRoot,
    connection, "KernelCount" -> 1, "FinalCheck" -> "Exact",
    "MinimumCachedPrimeCount" -> 1];

(* Stale terminal targets must be refused without overwriting the stale
   sentinel or creating the opposite terminal marker. *)
staleResultFile = FileNameJoin[{workRoot, "stale_result.wl"}];
staleSentinelFile = staleResultFile <> ".mission_success.wl";
staleFailureFile = staleResultFile <> ".mission_failure.wl";
Put[<|"Status" -> "OldSuccess"|>, staleSentinelFile];
staleHashBefore = FileHash[staleSentinelFile, "SHA256", "HexString"];
oldCommandLine = $ScriptCommandLine;
Unprotect[$ScriptCommandLine];
$ScriptCommandLine = {checkedScript, projectRoot, "unused-state",
  "unused-checkpoint", workRoot, staleResultFile};
staleExit = Catch[Get[checkedScript], "KernelPoolExit"];
$ScriptCommandLine = oldCommandLine;
staleHashAfter = FileHash[staleSentinelFile, "SHA256", "HexString"];

(* A target Exit/throw must be converted into exactly one failure marker. *)
throwTarget = FileNameJoin[{workRoot, "throw_target.wls"}];
Export[throwTarget, "Exit[7];", "Text"];
throwResultFile = FileNameJoin[{workRoot, "throw_result.wl"}];
SetEnvironment[
  "FACET_CF300_SIDECAR_TARGET_OVERRIDE" -> throwTarget];
$ScriptCommandLine = {checkedScript, projectRoot, "unused-state",
  "unused-checkpoint", workRoot, throwResultFile};
throwExit = Catch[Get[checkedScript], "KernelPoolExit"];
$ScriptCommandLine = oldCommandLine;
SetEnvironment[
  "FACET_CF300_SIDECAR_TARGET_OVERRIDE" -> None];

(* Model the checked wrapper's immutable-held-source execution: mutation
   after parsing cannot change the held program that is released. *)
toctouFile = FileNameJoin[{workRoot, "toctou.wl"}];
Export[toctouFile, "1 + 1", "Text"];
toctouHashBefore = FileHash[toctouFile, "SHA256", "HexString"];
toctouHeld = ToExpression[Import[toctouFile, "Text"], InputForm,
  HoldComplete];
Export[toctouFile, "40 + 2", "Text"];
toctouReleased = ReleaseHold[toctouHeld];
toctouHashAfter = FileHash[toctouFile, "SHA256", "HexString"];

(* The channel-mask ABI must include the rational rank-0 subfield and
   preserve exact reconstruction for sparse and full root-index sets. *)
testRoots = {
  <|"Root" -> Sqrt[2], "RootSquare" -> 2|>,
  <|"Root" -> Sqrt[3], "RootSquare" -> 3|>,
  <|"Root" -> Sqrt[5], "RootSquare" -> 5|>};
rank0Expression = Together[-2/(1 + variables[[1]])];
rank0Channels = CodexTripleRootStrip`TRFieldDecompose[
  rank0Expression, {}];
rank0CubeRootChannels = CodexTripleRootStrip`TRFieldDecompose[
  (1 + variables[[1]])^(1/3), {}];
rank0Lift = CodexTripleRootStrip`TRLiftLocalChannels[
  rank0Channels, {}, 3];
rank0Expected = Prepend[ConstantArray[0, 7], rank0Expression];
testFrame = <|"Variables" -> variables,
  "Subst" -> Thread[variables -> variables], "Roots" -> testRoots|>;
rationalLeafStrip = ConstantArray[0, {3, 2, 1, 1}];
rationalLeafStrip[[1, 1, 1, 1]] = rank0Expression;
rationalLeafRecord = <|"Family" -> "CF300", "Sector" -> 12,
  "LowerSector" -> 11, "Variables" -> variables,
  "Regulator" -> epsilon, "Strip" -> rationalLeafStrip|>;
rationalLeafDecomposition =
  CodexTripleRootStrip`TRDecomposeStripRecord[
    rationalLeafRecord, testFrame];
cubeRootLeafStrip = ConstantArray[0, {3, 2, 1, 1}];
cubeRootLeafStrip[[1, 1, 1, 1]] =
  (1 + variables[[1]])^(1/3);
cubeRootLeafRecord = Join[rationalLeafRecord,
  <|"Strip" -> cubeRootLeafStrip|>];
cubeRootLeafDecomposition =
  CodexTripleRootStrip`TRDecomposeStripRecord[
    cubeRootLeafRecord, testFrame];
singleLocalChannels = {1 + variables[[1]], 2 - variables[[2]]};
singleLift = CodexTripleRootStrip`TRLiftLocalChannels[
  singleLocalChannels, {2}, 3];
singleExpected = {singleLocalChannels[[1]], 0,
  singleLocalChannels[[2]], 0, 0, 0, 0, 0};
rank2LocalChannels = {1 + variables[[1]], 2 - variables[[2]],
  variables[[1]] variables[[2]], 1/(1 + variables[[1]] +
    variables[[2]])};
rank2Lift = CodexTripleRootStrip`TRLiftLocalChannels[
  rank2LocalChannels, {1, 3}, 3];
rank2Expected = {rank2LocalChannels[[1]], rank2LocalChannels[[2]],
  0, 0, rank2LocalChannels[[3]], rank2LocalChannels[[4]], 0, 0};
fullLocalChannels = {1, variables[[1]], variables[[2]],
  variables[[1]] variables[[2]], 1/(1 + variables[[1]]),
  1/(1 + variables[[2]]), variables[[1]]/(1 + variables[[2]]),
  variables[[2]]/(1 + variables[[1]])};
fullLift = CodexTripleRootStrip`TRLiftLocalChannels[
  fullLocalChannels, {1, 2, 3}, 3];
exactExpressionQ[left_, right_] :=
  TrueQ[Together[left - right] === 0];

checks = <|
  "CleanCompleteCheckpointVerified" ->
    Lookup[clean, "Status", None] === "Verified" &&
      TrueQ[Lookup[clean, "ActivateInstalledRow", False]],
  "CleanReplayActionVerifiedExisting" ->
    Lookup[Lookup[clean, "ReplayRecords", {}], "Action", {}] ===
      {"VerifiedExisting"},
  "OldFalseSummaryUpgradedByExactReplay" ->
    Lookup[First[Lookup[clean, "ReplayRecords", {<||>}]],
      "ExactDLog", False] === True,
  "DimensionValidCorruptCompleteFormRejected" ->
    Lookup[corruptFormResult, "Status", None] ===
      "ResumeHydrationExistingFormReplayMismatch" &&
      ! TrueQ[Lookup[corruptFormResult,
        "ActivateInstalledRow", False]],
  "DimensionValidCorruptCompleteGaugeRejected" ->
    Lookup[corruptGaugeResult, "Status", None] ===
      "ResumeHydrationReplayIdentityFailed" &&
      ! TrueQ[Lookup[corruptGaugeResult,
        "ActivateInstalledRow", False]],
  "StaleSentinelExit93" -> MatchQ[staleExit, {"EXIT", 93}],
  "StaleSentinelUnchanged" -> staleHashBefore === staleHashAfter,
  "StaleRefusalDidNotCreateOppositeMarker" ->
    ! FileExistsQ[staleFailureFile] && ! FileExistsQ[staleResultFile],
  "ThrownTargetExit91" -> MatchQ[throwExit, {"EXIT", 91}],
  "ThrownTargetHasFailureOnly" ->
    FileExistsQ[throwResultFile <> ".mission_failure.wl"] &&
      ! FileExistsQ[throwResultFile <> ".mission_success.wl"],
  "HeldSourcePinsExecution" -> toctouReleased === 2 &&
    toctouHashBefore =!= toctouHashAfter,
  "WrapperUsesHeldSourceNotGet" -> Module[{text = Import[
      checkedScript, "Text"]},
    StringContainsQ[text, "ReleaseHold[parsed]"] &&
      ! StringContainsQ[text, "Get[target]"]],
  "Rank0DecompositionReturnsSoleRationalChannel" ->
    rank0Channels === {rank0Expression},
  "Rank0DecompositionRejectsCubeRootCoefficient" ->
    rank0CubeRootChannels === $Failed,
  "CubeRootLeafStripFailsClosedAtDecomposition" ->
    Lookup[cubeRootLeafDecomposition, "Status", None] ===
      "ChannelDecompositionFailed" &&
      Lookup[cubeRootLeafDecomposition, "RootIndices", None] === {},
  "Rank0PolynomialReductionReturnsSoleRationalChannel" ->
    CodexTripleRoot`TRFromPolynomial[rank0Expression, {}, {}] ===
      {rank0Expression},
  "RationalLeafStripDecompositionMatchesFailedCallPath" ->
    Lookup[rationalLeafDecomposition, "Status", None] ===
      "ExactChannelDecomposition" &&
      Lookup[rationalLeafDecomposition, "RootIndices", None] === {} &&
      Lookup[rationalLeafDecomposition, "ChannelCount", None] === 1 &&
      TrueQ[Lookup[rationalLeafDecomposition, "RoundTripExact", False]] &&
      rationalLeafDecomposition["ChannelStrip"][[1, 1, 1, 1]] ===
        {rank0Expression},
  "Rank0LiftMapsOnlyToGlobalGrade0" ->
    rank0Lift === rank0Expected,
  "Rank0LiftReconstructsExactly" -> exactExpressionQ[
    CodexTripleRootStrip`TRFieldCompose[rank0Lift, testRoots],
    rank0Expression],
  "SingleIndexLiftUsesGlobalMaskABI" ->
    singleLift === singleExpected,
  "SingleIndexLiftReconstructsExactly" -> exactExpressionQ[
    CodexTripleRootStrip`TRFieldCompose[singleLift, testRoots],
    CodexTripleRootStrip`TRFieldCompose[singleLocalChannels,
      {testRoots[[2]]}]],
  "NoncontiguousRank2LiftUsesGlobalMaskABI" ->
    rank2Lift === rank2Expected,
  "NoncontiguousRank2LiftReconstructsExactly" -> exactExpressionQ[
    CodexTripleRootStrip`TRFieldCompose[rank2Lift, testRoots],
    CodexTripleRootStrip`TRFieldCompose[rank2LocalChannels,
      testRoots[[{1, 3}]]]],
  "FullIndexLiftIsIdentity" -> fullLift === fullLocalChannels,
  "FullIndexLiftReconstructsExactly" -> exactExpressionQ[
    CodexTripleRootStrip`TRFieldCompose[fullLift, testRoots],
    CodexTripleRootStrip`TRFieldCompose[fullLocalChannels, testRoots]],
  "ChannelLiftRejectsInvalidIndexOrCount" -> And[
    CodexTripleRootStrip`TRLiftLocalChannels[{1, 2}, {}, 3] ===
      $Failed,
    CodexTripleRootStrip`TRLiftLocalChannels[{1, 2, 3, 4},
      {1, 1}, 3] === $Failed,
    CodexTripleRootStrip`TRLiftLocalChannels[{1, 2}, {4}, 3] ===
      $Failed,
    CodexTripleRootStrip`TRLiftLocalChannels[{1, 2, 3, 4},
      {2, 1}, 3] === $Failed],
  "ResultTargetOutsideTemporaryTree" ->
    ! StringStartsQ[safetyResultFile, workRoot <> "/"]|>;
status = If[And @@ Values[checks], "SafetyAdversarialSmokePassed",
  "SafetyAdversarialSmokeFailed"];
result = <|"Status" -> status, "Checks" -> checks,
  "CleanReplay" -> KeyDrop[clean, {"SolvedForms", "InstalledRow"}],
  "CorruptFormStatus" -> Lookup[corruptFormResult, "Status", None],
  "CorruptGaugeStatus" -> Lookup[corruptGaugeResult, "Status", None],
  "StaleExit" -> staleExit, "ThrowExit" -> throwExit,
  "CheckedWrapperSHA256" ->
    FileHash[checkedScript, "SHA256", "HexString"],
  "TripleRootAlgebraSHA256" ->
    FileHash[tripleRootAlgebraFile, "SHA256", "HexString"],
  "StripAdapterSHA256" ->
    FileHash[stripAdapterFile, "SHA256", "HexString"]|>;
writeAtomic[result, safetyResultFile];
artifactPersistedQ = FileExistsQ[safetyResultFile] &&
  SameQ[FeynFacet`FamilyArtifactRead[safetyResultFile], result];
If[DirectoryQ[workRoot],
  DeleteDirectory[workRoot, DeleteContents -> True]];
Print["CF300S12SAFETY RESULT status=", status,
  " artifact_persisted=", artifactPersistedQ,
  " output=", safetyResultFile];
Exit[If[status === "SafetyAdversarialSmokePassed" &&
    artifactPersistedQ, 0, 1]];
