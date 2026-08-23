#!/usr/bin/env wolframscript

(* Private V4 recapture body.  The launcher has already established a
   read-only virgin-worker gate.  The family driver is imported as source,
   parsed wholly in CodexCF300Sector12DriverV4` with only System` visible,
   and evaluated with Global` absent from its context path.  Every Global
   artifact/basis symbol that the driver or loader intentionally uses is
   explicitly inherited and cleared for the scoped run.  System package/path
   state, environment, argv, directory, and the dedicated driver context are
   restored before validation completes.  Loading FACET is not generally
   reversible, so every post-load outcome stays in a cooperative Pause loop;
   the worker is never re-advertised between PASS and quarantine. *)

BeginPackage["CodexCF300Sector12RecaptureV4`"];
Begin["`Private`"];

bodyFinalResult = Module[
  {repositoryRoot, bundleDirectory, bodyFile, launcherFile, driver,
   sourceManifest, kernelPoolSource, poolRunDefinitionFile,
   preflightFile, censusFile, censusInspectorFile,
   pathSealFile, pathInspectorFile, pathSeal,
   validatorFile, validatorEvidenceFile, formalResultFile,
   v4State, v4Report, v1StripFile, v2StripFile,
   expectedSourceManifestHash, expectedKernelPoolSourceHash,
   expectedPoolRunDefinitionHash, expectedValidatorHash,
   expectedValidatorEvidenceHash, expectedFormalResultHash,
   expectedV4StateHash, expectedV4ReportHash, expectedDriverHash,
   expectedV1StripHash, expectedV2StripHash, expectedStripBytes,
   expectedPreflightHash, expectedCensusHash, expectedCensusInspectorHash,
   expectedPathSealHash, expectedPathInspectorHash,
   outdir, outdirParent, stateFile, snapshotFile, scratch,
   stripInputFile, stripCheckpointFile, resultFile, launchSealFile,
   messageTranscriptFile, loadAttemptFile, quarantineMarkerFile,
   releaseSentinelFile, failureHoldFile, familyDataDirectory,
   classFormDirectory, driverContext, driverContextPattern,
   releaseToken, failureReleaseToken, explicitGlobalNames,
   globalBaselinePayload, globalNamesBaseline, globalNamesAfterCleanup,
   globalBaselineStatesBefore, globalBaselineStatesAfter,
   newGlobalNames, newGlobalStates, globalNamespaceGateQ,
   globalCleanupMessages,
   environmentOverrides, environmentNames, savedEnvironment,
   savedCommandLine, savedCommandLineProtectedQ, savedDirectory,
   environmentActive = False, messageStream = None,
   packageLoadAttemptedQ = False, lastFailure = None,
   driverArguments, tag, hashHex, symbolicLinkQ, putAtomic, fail,
   closeMessageStream,
   restoreEnvironment, restoreDynamicState, cleanupDriverContext,
   normalizeText, definitionComponents, symbolDefinitionStateByNameHeld,
   symbolDefinitionStateByName, definitionFreeStateQ,
   manifestText, manifestLines, manifestParts, expectedHashes,
   badSourcesBefore, badSourcesAfter, sourcePinsBefore, sourcePinsAfter,
   bodyHashBefore, launcherHashBefore, driverHashBefore,
   systemLifecycleBefore, systemLifecycleAfter, globalStatesBefore,
   globalStatesAfter, globalStateGateQ, scopedExecution,
   driverText, driverParseText, driverHeld, driverResult,
   driverExitPayload = None, driverExitCapturedQ = False,
   driverMessagesRaw = {}, driverMessageSignatures = {},
   transcriptText = "", normalizedTranscript = "",
   driverMessageGateQ = False, recaptureState, snapshotState,
   stripRecord, expectedStrip, readMessages, stateGateQ, stripGateQ,
   filesystemGateQ, immutableGateQ, copyResults, launchSeal,
   loadAttemptSeal, scopedResult, missionOutcome, resultRecord,
   resultHash, quarantineMarker, quarantineMarkerHash,
   expectedTopLevelBeforeResult, expectedTopLevelFinal,
   topLevelBeforeResult, topLevelFinal, noTemporaryFilesQ,
   integritySnapshot, integrityQ, currentTopLevel, failureIntegrityQ,
   failureTopLevelBaseline, failureHoldHash,
   releaseText, heartbeatCount, loadAttemptHash,
   finalOutput},

  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  bundleDirectory = DirectoryName[ExpandFileName[System`$InputFileName]];
  bodyFile = ExpandFileName[System`$InputFileName];
  launcherFile = FileNameJoin[{bundleDirectory,
    "run_cf300_sector12_recapture_from_v4_xh_v4.wls"}];
  driver = FileNameJoin[{repositoryRoot, "Scripts",
    "family_epsform_sector.wls"}];
  sourceManifest = FileNameJoin[{bundleDirectory,
    "CF300_RESUME_SOURCE_SHA256SUMS"}];
  kernelPoolSource = FileNameJoin[{repositoryRoot, "Scripts",
    "KernelPool.wls"}];
  poolRunDefinitionFile =
    "/tmp/codex-triple-root-20260823c.vx654S/pool/" <>
     "poolrun_definition.m";
  preflightFile = FileNameJoin[{bundleDirectory,
    "preflight_cf300_sector12_recapture_v4_global_state.wls"}];
  censusFile = FileNameJoin[{bundleDirectory,
    "family_sector_driver_global_census_v1.json"}];
  censusInspectorFile = FileNameJoin[{bundleDirectory,
    "inspect_family_sector_driver_global_census_v1.py"}];
  pathSealFile = FileNameJoin[{bundleDirectory,
    "cf300_sector12_recapture_v4_path_seal.json"}];
  pathInspectorFile = FileNameJoin[{bundleDirectory,
    "inspect_cf300_sector12_recapture_v4_paths.py"}];
  validatorFile = FileNameJoin[{bundleDirectory,
    "validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls"}];
  validatorEvidenceFile = FileNameJoin[{bundleDirectory,
    "cf300_s11_postwrite_validator_xh_v2_OK.log"}];
  formalResultFile = FileNameJoin[{bundleDirectory,
    "cf300_sector11_postwrite_formal_inspector_v4_result.json"}];
  v4State = FileNameJoin[{repositoryRoot, "ppHX_NNLO_DoubleReal",
    "Results", "UU_08_10_canonical", "FamilyEpsFormsSolving",
    "triple_root_2026-08-23", "CF300_direct_regulator_v4_candidate",
    "sector_state_CF300_standard.wl"}];
  v4Report = FileNameJoin[{DirectoryName[v4State],
    "cf300_sector11_direct_regulator_report_v4.wl"}];
  v1StripFile =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
     "cf300_sector12_recapture_from_v4_xh_v1/" <>
     "sector_CF300_standard/CF300_12_11_input.wl";
  v2StripFile =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
     "cf300_sector12_recapture_from_v4_xh_v2/" <>
     "sector_CF300_standard/CF300_12_11_input.wl";

  expectedSourceManifestHash =
    "880c4f7850b2c0daf5c207e96df23113c91d75d1056e23c6edc169aec66487b2";
  expectedKernelPoolSourceHash =
    "0758f0f95a24b5dee4c6162939388ca5641610ef5e73bb73775a2030e8ff069d";
  expectedPoolRunDefinitionHash =
    "d49632694d4da9f47a7c3c0d9828e98d47f9a416c9cb72d8a10a74b9b011db51";
  expectedValidatorHash =
    "304e7748e3971e9b0bf50fc84b10f50cda8231d49d6df235327134a297c45759";
  expectedValidatorEvidenceHash =
    "185d009d9ed4a56037c3360a14862b97e8e39cfbe8e591c5d6bc38d936d45f3e";
  expectedFormalResultHash =
    "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128";
  expectedV4StateHash =
    "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009";
  expectedV4ReportHash =
    "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e";
  expectedDriverHash =
    "6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1";
  expectedV1StripHash =
    "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976";
  expectedV2StripHash = expectedV1StripHash;
  expectedStripBytes = 15667;
  expectedPreflightHash =
    "91249cb30209f2a19ee5eb980889024b98694ed21744e9a81f1f49142a330ae5";
  expectedCensusHash =
    "990e086691cd0651823df256e019e6d7e32042b64951ded39f4f31ad8e16c377";
  expectedCensusInspectorHash =
    "89d27f01e6ab92bcf64fff60085f8c87115edab02d86b8ebf9691886735da6ae";
  expectedPathSealHash =
    "6f326c92c6f9948f0fcb4c10f8e1052da446ac4ea9a5baf3cc71d177f690e44e";
  expectedPathInspectorHash =
    "c6bfcee4603e5d2b0248a5dc8c02320f7a1d3fac3f4075e6f869d634caa6a0cd";

  outdir =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
     "cf300_sector12_recapture_from_v4_xh_v4";
  outdirParent = DirectoryName[outdir];
  stateFile = FileNameJoin[{outdir, "sector_state_CF300_standard.wl"}];
  snapshotFile = FileNameJoin[{outdir,
    "pre_sector12_snapshot_CF300_standard.wl"}];
  scratch = FileNameJoin[{outdir, "sector_CF300_standard"}];
  stripInputFile = FileNameJoin[{scratch, "CF300_12_11_input.wl"}];
  stripCheckpointFile = FileNameJoin[{scratch,
    "CF300_12_strip_state.wl"}];
  resultFile = FileNameJoin[{outdir,
    "CF300_sector12_recapture_result_v4.wl"}];
  launchSealFile = FileNameJoin[{outdir,
    "CF300_sector12_recapture_launch_seal_v4.wl"}];
  messageTranscriptFile = FileNameJoin[{outdir,
    "CF300_driver_messages_v4.txt"}];
  loadAttemptFile = FileNameJoin[{outdir,
    "CF300_package_load_attempted_v4.wl"}];
  quarantineMarkerFile = FileNameJoin[{outdir,
    "CF300_prequarantine_pass_v4.wl"}];
  releaseSentinelFile = FileNameJoin[{outdir,
    "CF300_quarantine_release_v4.txt"}];
  failureHoldFile = FileNameJoin[{outdir,
    "CF300_postload_failure_hold_v4.wl"}];
  familyDataDirectory = FileNameJoin[{repositoryRoot,
    "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
  classFormDirectory = FileNameJoin[{familyDataDirectory, "ClassForms"}];
  driverContext = "CodexCF300Sector12DriverV4`";
  driverContextPattern = driverContext <> "*";
  releaseToken =
    "CF300-S12-V4-PASS-RELEASE-e35c0f3fb91a43cdac8c276227b92e0e";
  failureReleaseToken =
    "CF300-S12-V4-FAIL-RELEASE-72e812e38ea6460594552626c92e3045";

  explicitGlobalNames = {
    "Global`tau", "Global`s", "Global`u", "Global`p",
    "Global`x", "Global`y", "Global`eps", "Global`v", "Global`w",
    "Global`t", "Global`r", "Global`mu", "Global`xi", "Global`xx",
    "Global`Eps", "Global`epsilon", "Global`Epsilon", "Global`ep",
    "Global`sqrtLambda", "Global`gli", "Global`nb", "Global`n",
    "Global`xhat", "Global`yhat", "Global`GlobalBasis",
    "Global`$LoadFeynArts", "Global`$LoadAddOns", "Global`A0",
    "Global`$FACETKernelLimit", "Global`$FACETRatracerExecutable",
    "Global`$FeynCalcStartupMessages", "Global`$PolyLogPath",
    "Global`FeynFacetFermatCheckVariable"};
  environmentOverrides = <|
    "FACET_KERNEL_COUNT" -> "1",
    "FACET_TASK_BROKER_MAX_HELPERS" -> "0",
    "FACET_CHECK_LEVEL" -> "Production",
    "FACET_STRIP_ROUTE" -> "FiniteFieldFirst",
    "FACET_ZERO_FORCING" -> "True",
    "FACET_RECORD_STRIP_ONLY" -> "True",
    "FACET_RESUME_HYDRATION" -> "True"|>;
  environmentNames = Append[Keys[environmentOverrides], "FACET_MEMTRACE"];
  driverArguments = {driver, "CF300", outdir, "7200", "standard",
    "30", "", familyDataDirectory, classFormDirectory};
  tag = Unique["CF300Sector12RecaptureV4$"];

  hashHex[file_String] := Quiet[Check[
    If[System`FileExistsQ[file],
      IntegerString[System`FileHash[file, "SHA256"], 16, 64],
      Missing["NotFound"]], Missing["HashFailed"]]];
  putAtomic[expression_, file_String] := Module[
    {temporary, written, moved},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    written = Quiet[Check[
      Put[expression, temporary]; System`FileExistsQ[temporary], False]];
    If[TrueQ[written],
      moved = Quiet[Check[
        RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
      If[StringQ[moved] && System`FileExistsQ[file], file, $Failed], $Failed]];
  fail[message_String] := (
    lastFailure = message;
    Print["CF300 S12 RECAPTURE V4 FAIL: " <> message];
    Throw[$Failed, tag]);
  closeMessageStream[] := If[Head[messageStream] === OutputStream,
    Quiet[Check[Close[messageStream], Null]];
    messageStream = None];
  restoreEnvironment[] := If[TrueQ[environmentActive],
    KeyValueMap[Function[{name, value},
      If[StringQ[value], SetEnvironment[name -> value],
        UnsetEnvironment[name]]], savedEnvironment];
    environmentActive = False];
  restoreDynamicState[] := (
    closeMessageStream[];
    restoreEnvironment[];
    If[ListQ[savedCommandLine],
    Quiet[System`Unprotect[System`$ScriptCommandLine]];
      System`$ScriptCommandLine = savedCommandLine;
      If[TrueQ[savedCommandLineProtectedQ],
        System`Protect[System`$ScriptCommandLine],
        System`Unprotect[System`$ScriptCommandLine]]];
    If[StringQ[savedDirectory],
      Quiet[Check[SetDirectory[savedDirectory], Null]]]);
  cleanupDriverContext[] := With[{pattern = driverContextPattern},
    Quiet[System`Remove[pattern]]];
  normalizeText[text_String] := StringTrim[
    StringReplace[text, WhitespaceCharacter .. -> " "]];
  normalizeText[___] := $Failed;

  definitionComponents = {"OwnValues", "DownValues", "UpValues",
    "SubValues", "NValues", "DefaultValues", "FormatValues",
    "Attributes"};
  System`SetAttributes[symbolDefinitionStateByNameHeld, HoldAll];
  symbolDefinitionStateByNameHeld[symbol_] := <|
    "OwnValues" -> System`OwnValues[symbol],
    "DownValues" -> System`DownValues[symbol],
    "UpValues" -> System`UpValues[symbol],
    "SubValues" -> System`SubValues[symbol],
    "NValues" -> System`NValues[symbol],
    "DefaultValues" -> System`DefaultValues[symbol],
    "FormatValues" -> System`FormatValues[symbol],
    "Attributes" -> System`Attributes[symbol]|>;
  symbolDefinitionStateByName[name_String] := System`ToExpression[
    name, InputForm,
    Function[heldSymbol,
      symbolDefinitionStateByNameHeld[heldSymbol], HoldAll]];
  definitionFreeStateQ[state_Association] := TrueQ[
    Lookup[state, definitionComponents, $Failed] ===
      ConstantArray[{}, Length[definitionComponents]]];
  definitionFreeStateQ[___] := False;

  savedEnvironment = AssociationThread[environmentNames,
    Environment /@ environmentNames];
  globalBaselinePayload = If[
    Length[Rest[System`$ScriptCommandLine]] === 1,
    Last[System`$ScriptCommandLine], $Failed];
  globalNamesBaseline = Quiet[Check[
    If[StringQ[globalBaselinePayload],
      ImportString[globalBaselinePayload, "RawJSON"], $Failed], $Failed]];
  savedCommandLine = If[ListQ[System`$ScriptCommandLine] &&
      Length[System`$ScriptCommandLine] >= 1,
    Most[System`$ScriptCommandLine], {}];
  savedCommandLineProtectedQ = MemberQ[
    System`Attributes[System`$ScriptCommandLine], Protected];
  savedDirectory = System`Directory[];
  bodyHashBefore = hashHex[bodyFile];
  launcherHashBefore = hashHex[launcherFile];
  driverHashBefore = hashHex[driver];
  systemLifecycleBefore = <|
    "Context" -> System`$Context,
    "ContextPath" -> System`$ContextPath,
    "Packages" -> System`$Packages,
    "Path" -> System`$Path|>;
  globalStatesBefore = AssociationMap[
    symbolDefinitionStateByName, explicitGlobalNames];
  globalBaselineStatesBefore = If[ListQ[globalNamesBaseline],
    AssociationMap[symbolDefinitionStateByName, globalNamesBaseline],
    $Failed];

  missionOutcome = CheckAbort[
    Catch[
      If[! (Length[Rest[System`$ScriptCommandLine]] === 1 &&
          ListQ[globalNamesBaseline] &&
          DuplicateFreeQ[globalNamesBaseline] &&
          Sort[globalNamesBaseline] === globalNamesBaseline &&
          AllTrue[globalNamesBaseline,
            StringQ[#1] && StringStartsQ[#1, "Global`"] &] &&
          Intersection[globalNamesBaseline, explicitGlobalNames] === {} &&
          AssociationQ[globalBaselineStatesBefore] &&
          FreeQ[Values[globalBaselineStatesBefore], $Failed]),
        fail["sealed launcher Global-namespace baseline was malformed"]];
      If[! IntegerQ[System`$KernelID] || System`$KernelID <= 0 ||
          Length[System`Kernels[]] =!= 0 ||
          ! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
            KernelPoolMission`$TaskBrokerMaxHelpers === 0),
        fail["worker/helper ceiling gate failed"]];
      If[! AllTrue[Values[globalStatesBefore], definitionFreeStateQ],
        fail["explicit inherited Global symbol was not definition-free"]];
      If[System`Names[driverContextPattern] =!= {},
        fail["dedicated driver context was not clean"]];
      If[System`FileExistsQ[outdir] || System`DirectoryQ[outdir] ||
          ! System`DirectoryQ[outdirParent],
        fail["V4 output is not fresh or parent is absent"]];

      sourcePinsBefore = <|
        "SourceManifest" -> hashHex[sourceManifest],
        "KernelPoolSource" -> hashHex[kernelPoolSource],
        "PoolRunDefinition" -> hashHex[poolRunDefinitionFile],
        "Preflight" -> hashHex[preflightFile],
        "GlobalCensus" -> hashHex[censusFile],
        "GlobalCensusInspector" -> hashHex[censusInspectorFile],
        "PathSeal" -> hashHex[pathSealFile],
        "PathInspector" -> hashHex[pathInspectorFile],
        "ValidatorV2" -> hashHex[validatorFile],
        "ValidatorV2Evidence" -> hashHex[validatorEvidenceFile],
        "FormalResult" -> hashHex[formalResultFile],
        "V4State" -> hashHex[v4State],
        "V4Report" -> hashHex[v4Report],
        "Driver" -> hashHex[driver],
        "V1Strip" -> hashHex[v1StripFile],
        "V1StripBytes" -> If[System`FileExistsQ[v1StripFile],
          System`FileByteCount[v1StripFile], Missing["NotFound"]],
        "V2Strip" -> hashHex[v2StripFile],
        "V2StripBytes" -> If[System`FileExistsQ[v2StripFile],
          System`FileByteCount[v2StripFile], Missing["NotFound"]]|>;
      If[sourcePinsBefore =!= <|
          "SourceManifest" -> expectedSourceManifestHash,
          "KernelPoolSource" -> expectedKernelPoolSourceHash,
          "PoolRunDefinition" -> expectedPoolRunDefinitionHash,
          "Preflight" -> expectedPreflightHash,
          "GlobalCensus" -> expectedCensusHash,
          "GlobalCensusInspector" -> expectedCensusInspectorHash,
          "PathSeal" -> expectedPathSealHash,
          "PathInspector" -> expectedPathInspectorHash,
          "ValidatorV2" -> expectedValidatorHash,
          "ValidatorV2Evidence" -> expectedValidatorEvidenceHash,
          "FormalResult" -> expectedFormalResultHash,
          "V4State" -> expectedV4StateHash,
          "V4Report" -> expectedV4ReportHash,
          "Driver" -> expectedDriverHash,
          "V1Strip" -> expectedV1StripHash,
          "V1StripBytes" -> expectedStripBytes,
          "V2Strip" -> expectedV2StripHash,
          "V2StripBytes" -> expectedStripBytes|>,
        fail["source/provenance pin gate failed"]];
      pathSeal = Quiet[Check[Import[pathSealFile, "RawJSON"], $Failed]];
      If[! TrueQ[AssociationQ[pathSeal] &&
          Lookup[pathSeal, "Schema", None] ===
            "CF300Sector12RecaptureV4PathSealV1" &&
          TrueQ[Lookup[pathSeal, "GateQ", False]] &&
          Lookup[pathSeal, "RecordCount", None] === 21 &&
          AllTrue[Lookup[pathSeal, "Records", {$Failed}],
            AssociationQ[#1] && TrueQ[Lookup[#1, "GateQ", False]] &] &&
          MemberQ[Lookup[pathSeal, "Records", {}],
            KeyValuePattern[{"Label" -> "OutputDirectory",
              "ExpectedKind" -> "absent", "ActualKind" -> "absent",
              "Lexists" -> False, "GateQ" -> True}]]],
        fail["pinned lstat/realpath path seal rejected"]];
      If[bodyHashBefore === Missing["HashFailed"] ||
          launcherHashBefore === Missing["HashFailed"],
        fail["launcher/body self-hash failed"]];

      manifestText = Quiet[Check[Import[sourceManifest, "Text"], $Failed]];
      If[! StringQ[manifestText], fail["source manifest import failed"]];
      manifestLines = Select[
        StringSplit[manifestText, {"\r\n", "\n", "\r"}],
        StringLength[StringTrim[#1]] > 0 &];
      manifestParts = StringSplit[StringTrim[#1], Whitespace] & /@
        manifestLines;
      If[Length[manifestParts] =!= 69 ||
          ! AllTrue[manifestParts,
            Length[#1] === 2 &&
              StringMatchQ[#1[[1]],
                Repeated[HexadecimalCharacter, {64}]] &&
              ! StringStartsQ[#1[[2]], "/"] &&
              FreeQ[FileNameSplit[#1[[2]]], ".."] &],
        fail["malformed 69-source manifest"]];
      expectedHashes = Association[Rule @@@ (Reverse /@ manifestParts)];
      If[Length[expectedHashes] =!= 69,
        fail["duplicate source-manifest path"]];
      badSourcesBefore = Select[Keys[expectedHashes],
        hashHex[FileNameJoin[{repositoryRoot, #1}]] =!=
          expectedHashes[#1] &];
      If[badSourcesBefore =!= {},
        fail["source drift before recapture: " <>
          ToString[badSourcesBefore, InputForm]]];

      If[Quiet[Check[CreateDirectory[outdir], $Failed]] === $Failed ||
          ! System`DirectoryQ[outdir],
        fail["could not create fresh V4 output"]];
      copyResults = Quiet[Check[
        {CopyFile[v4State, snapshotFile, OverwriteTarget -> False],
         CopyFile[v4State, stateFile, OverwriteTarget -> False]}, $Failed]];
      If[copyResults === $Failed ||
          hashHex[snapshotFile] =!= expectedV4StateHash ||
          hashHex[stateFile] =!= expectedV4StateHash || System`DirectoryQ[scratch],
        fail["exact V4 state copy/fresh scratch gate failed"]];

      launchSeal = <|
        "Status" -> "CF300Sector12RecaptureLaunchSealedV4",
        "Family" -> "CF300", "SourceSector" -> 11,
        "TargetSector" -> 12, "LowerSector" -> 11,
        "OutputDirectory" -> outdir,
        "WorkerKernelID" -> System`$KernelID,
        "NestedKernelCount" -> Length[System`Kernels[]],
        "TaskBrokerMaxHelpers" ->
          KernelPoolMission`$TaskBrokerMaxHelpers,
        "DriverArguments" -> driverArguments,
        "EnvironmentOverrides" -> environmentOverrides,
        "FACETMEMTRACEExplicitlyUnsetQ" -> True,
        "DedicatedDriverContext" -> driverContext,
        "DriverContextPath" -> {"System`"},
        "ExplicitInheritedGlobalNames" -> explicitGlobalNames,
        "LauncherSHA256Before" -> launcherHashBefore,
        "BodySHA256Before" -> bodyHashBefore,
        "DriverSHA256Before" -> driverHashBefore,
        "SourcePinsBefore" -> sourcePinsBefore,
        "Created" -> DateString[Now, "ISODateTime"]|>;
      If[putAtomic[launchSeal, launchSealFile] === $Failed,
        fail["atomic launch seal write failed"]];

      loadAttemptSeal = <|
        "Status" -> "CF300Sector12RecapturePackageLoadAttemptedV4",
        "WorkerKernelID" -> System`$KernelID,
        "BodySHA256" -> bodyHashBefore,
        "DriverSHA256" -> expectedDriverHash,
        "QuarantineRequiredAfterThisSealQ" -> True,
        "Created" -> DateString[Now, "ISODateTime"]|>;
      If[putAtomic[loadAttemptSeal, loadAttemptFile] === $Failed,
        fail["atomic package-load-attempt seal write failed"]];
      loadAttemptHash = hashHex[loadAttemptFile];
      If[loadAttemptHash === Missing["HashFailed"] ||
          loadAttemptHash === Missing["NotFound"] ||
          ! IntegerQ[System`FileByteCount[loadAttemptFile]] ||
          System`FileByteCount[loadAttemptFile] <= 0 ||
          ! SameQ[Quiet[Check[System`Get[loadAttemptFile], $Failed]],
            loadAttemptSeal],
        fail["package-load-attempt seal was not durably rehydratable"]];
      packageLoadAttemptedQ = True;

      scopedExecution = Internal`InheritedBlock[
        {Global`tau, Global`s, Global`u, Global`p,
         Global`x, Global`y, Global`eps, Global`v, Global`w,
         Global`t, Global`r, Global`mu, Global`xi, Global`xx,
         Global`Eps, Global`epsilon, Global`Epsilon, Global`ep,
         Global`sqrtLambda, Global`gli, Global`nb, Global`n,
         Global`xhat, Global`yhat, Global`GlobalBasis,
         Global`$LoadFeynArts, Global`$LoadAddOns, Global`A0,
         Global`$FACETKernelLimit, Global`$FACETRatracerExecutable,
         Global`$FeynCalcStartupMessages, Global`$PolyLogPath,
         Global`FeynFacetFermatCheckVariable,
         System`$Context, System`$ContextPath, System`$Packages,
         System`$Path, System`$HistoryLength},

        System`ClearAll[Global`tau, Global`s, Global`u, Global`p,
          Global`x, Global`y, Global`eps, Global`v, Global`w,
          Global`t, Global`r, Global`mu, Global`xi, Global`xx,
          Global`Eps, Global`epsilon, Global`Epsilon, Global`ep,
          Global`sqrtLambda, Global`gli, Global`nb, Global`n,
          Global`xhat, Global`yhat, Global`GlobalBasis,
          Global`$LoadFeynArts, Global`$LoadAddOns, Global`A0,
          Global`$FACETKernelLimit, Global`$FACETRatracerExecutable,
          Global`$FeynCalcStartupMessages, Global`$PolyLogPath,
          Global`FeynFacetFermatCheckVariable];
        System`$HistoryLength = 0;
        savedEnvironment = AssociationThread[environmentNames,
          Environment /@ environmentNames];
        environmentActive = True;
        If[! TrueQ[Quiet[Check[
            SetEnvironment[Normal[environmentOverrides]];
            UnsetEnvironment["FACET_MEMTRACE"];
            True, False]]],
          restoreEnvironment[];
          fail["could not install scoped driver environment"]];
        Quiet[System`Unprotect[System`$ScriptCommandLine]];
        System`$ScriptCommandLine = driverArguments;

        messageStream = Quiet[Check[
          OpenWrite[messageTranscriptFile, PageWidth -> Infinity], $Failed]];
        If[Head[messageStream] =!= OutputStream,
          restoreDynamicState[];
          fail["could not open exact driver message transcript"]];
        Block[{System`$Messages = {messageStream}, System`$MessageList = {},
            System`$InputFileName = driver, System`$Context = driverContext,
            System`$ContextPath = {"System`"}},
          driverText = Import[driver, "Text"];
          driverParseText = If[StringQ[driverText],
            StringReplace[driverText,
              StartOfString ~~ "#!" ~~ Except["\n"] ... ~~
                ("\n" | EndOfString) :> ""], $Failed];
          driverHeld = If[StringQ[driverParseText],
            System`ToExpression[driverParseText, InputForm, HoldComplete], $Failed];
          If[Head[driverHeld] =!= HoldComplete,
            driverResult = $Failed,
            driverResult = Catch[
              ReleaseHold[driverHeld], "KernelPoolExit",
              Function[{payload, exitTag},
                driverExitCapturedQ = True;
                driverExitPayload = payload;
                payload]]];
          driverMessagesRaw = System`$MessageList;
          driverMessageSignatures =
            ToString[InputForm[#1]] & /@ driverMessagesRaw];
        closeMessageStream[];
        restoreDynamicState[];

        transcriptText = Quiet[Check[
          Import[messageTranscriptFile, "Text"], $Failed]];
        normalizedTranscript = normalizeText[transcriptText];
        driverMessageGateQ = TrueQ[
          driverMessagesRaw === {} &&
          driverMessageSignatures === {} &&
          normalizedTranscript === ""];
        If[! driverMessageGateQ,
          fail["localized clean driver emitted messages; transcript SHA " <>
            ToString[hashHex[messageTranscriptFile], InputForm]]];
        If[! TrueQ[driverExitCapturedQ] ||
            driverExitPayload =!= {"EXIT", 75},
          fail["driver did not produce intentional KernelPoolExit 75: " <>
            ToString[<|"Payload" -> driverExitPayload,
              "ResultHead" -> Head[driverResult]|>, InputForm]]];

        readMessages = {};
        Block[{System`$Context = "Global`",
            System`$ContextPath = {"Global`", "System`"},
            System`$MessageList = {}},
          recaptureState = System`Get[stateFile];
          snapshotState = System`Get[snapshotFile];
          stripRecord = System`Get[stripInputFile];
          readMessages = ToString[InputForm[#1]] & /@
            System`$MessageList];
        stateGateQ = TrueQ[
          readMessages === {} && AssociationQ[recaptureState] &&
          AssociationQ[snapshotState] &&
          SameQ[recaptureState, snapshotState] &&
          Lookup[recaptureState, "Sector", None] === 11 &&
          ! KeyExistsQ[recaptureState, "Stop"] &&
          Dimensions[Lookup[recaptureState, "A", {}]] === {2, 24, 24} &&
          Dimensions[Lookup[recaptureState, "S", {}]] === {24, 24} &&
          Dimensions[Lookup[recaptureState,
            "SInverse", {}]] === {24, 24} &&
          Length[Lookup[recaptureState,
            "RegulatorFactorizations", {}]] === 10 &&
          Lookup[Last[recaptureState["RegulatorFactorizations"]],
            "Rows", None] === 11 &&
          ! AnyTrue[Lookup[recaptureState,
            "SectorCertificates", {}],
            Lookup[#1, "Sector", None] === 12 &] &&
          ! AnyTrue[Lookup[recaptureState, "StripSolvers", {}],
            Lookup[#1, "Sector", None] === 12 &]];
        expectedStrip = If[stateGateQ,
          FeynFacet`Private`familyRowGaugeResumeBlockEquation[
            recaptureState["A"], 12, 11, <||>,
            recaptureState["Ranges"], Global`eps], $Failed];
        stripGateQ = TrueQ[
          AssociationQ[stripRecord] &&
          Lookup[stripRecord, "Family", None] === "CF300" &&
          Lookup[stripRecord, "Sector", None] === 12 &&
          Lookup[stripRecord, "LowerSector", None] === 11 &&
          Lookup[stripRecord, "Variables", None] ===
            {Global`x, Global`y} &&
          Lookup[stripRecord, "Regulator", None] === Global`eps &&
          Dimensions[Lookup[stripRecord, "Strip", {}]] ===
            {3, 2, 2, 2} &&
          SameQ[Lookup[stripRecord, "Strip", $Failed], expectedStrip] &&
          hashHex[stripInputFile] === expectedV1StripHash &&
          System`FileByteCount[stripInputFile] === expectedStripBytes];
        <|"StateGateQ" -> stateGateQ,
          "StripGateQ" -> stripGateQ,
          "ReadMessages" -> readMessages,
          "DriverMessageGateQ" -> driverMessageGateQ,
          "DriverExitPayload" -> driverExitPayload,
          "MessageTranscriptSHA256" -> hashHex[messageTranscriptFile]|>
      ];

      restoreDynamicState[];
      cleanupDriverContext[];
      systemLifecycleAfter = <|
        "Context" -> System`$Context,
        "ContextPath" -> System`$ContextPath,
        "Packages" -> System`$Packages,
        "Path" -> System`$Path|>;
      globalStatesAfter = AssociationMap[
        symbolDefinitionStateByName, explicitGlobalNames];
      globalStateGateQ = TrueQ[
        SameQ[globalStatesAfter, globalStatesBefore] &&
        AllTrue[Values[globalStatesAfter], definitionFreeStateQ]];
      globalBaselineStatesAfter = AssociationMap[
        symbolDefinitionStateByName, globalNamesBaseline];
      newGlobalNames = Complement[
        System`Names["Global`*"], globalNamesBaseline];
      newGlobalStates = AssociationMap[
        symbolDefinitionStateByName, newGlobalNames];
      If[AnyTrue[Values[newGlobalStates],
          MemberQ[Lookup[#1, "Attributes", {Locked}], Locked] &],
        fail["newly owned Global symbol became Locked and cannot be " <>
          "removed exactly"]];
      globalCleanupMessages = {};
      Block[{System`$MessageList = {}},
        Scan[Function[name,
          With[{literalName = name},
            Quiet[System`Unprotect[literalName]];
            Quiet[System`ClearAll[literalName]];
            Quiet[System`Remove[literalName]]]], newGlobalNames];
        globalCleanupMessages =
          ToString[InputForm[#1]] & /@ System`$MessageList];
      globalNamesAfterCleanup = System`Names["Global`*"];
      globalNamespaceGateQ = TrueQ[
        globalCleanupMessages === {} &&
        SameQ[globalNamesAfterCleanup, globalNamesBaseline] &&
        SameQ[globalBaselineStatesAfter, globalBaselineStatesBefore]];
      If[! TrueQ[AssociationQ[scopedExecution] &&
          Lookup[scopedExecution, "StateGateQ", False] &&
          Lookup[scopedExecution, "StripGateQ", False] &&
          Lookup[scopedExecution, "DriverMessageGateQ", False] &&
          globalStateGateQ && globalNamespaceGateQ &&
          SameQ[systemLifecycleAfter, systemLifecycleBefore] &&
          System`Names[driverContextPattern] === {} &&
          SameQ[AssociationThread[environmentNames,
            Environment /@ environmentNames], savedEnvironment] &&
          SameQ[System`$ScriptCommandLine, savedCommandLine] &&
          SameQ[System`Directory[], savedDirectory] &&
          SameQ[MemberQ[System`Attributes[System`$ScriptCommandLine], Protected],
            savedCommandLineProtectedQ]],
        fail["scoped driver/restoration/state/strip gate failed: " <>
          ToString[scopedExecution, InputForm]]];

      expectedTopLevelBeforeResult = Sort[{
        launchSealFile, loadAttemptFile, messageTranscriptFile,
        snapshotFile, stateFile, scratch}];
      topLevelBeforeResult = Sort[System`FileNames["*", outdir]];
      noTemporaryFilesQ = TrueQ[
        System`FileNames["*.tmp*", outdir, Infinity] === {}];
      filesystemGateQ = TrueQ[
        topLevelBeforeResult === expectedTopLevelBeforeResult &&
        Sort[System`FileNames["*", scratch]] === {stripInputFile} &&
        ! System`FileExistsQ[stripCheckpointFile] &&
        ! System`FileExistsQ[releaseSentinelFile] &&
        noTemporaryFilesQ &&
        hashHex[stateFile] === expectedV4StateHash &&
        hashHex[snapshotFile] === expectedV4StateHash &&
        hashHex[stripInputFile] === expectedV1StripHash &&
        System`FileByteCount[stripInputFile] === expectedStripBytes];

      sourcePinsAfter = <|
        "SourceManifest" -> hashHex[sourceManifest],
        "KernelPoolSource" -> hashHex[kernelPoolSource],
        "PoolRunDefinition" -> hashHex[poolRunDefinitionFile],
        "Preflight" -> hashHex[preflightFile],
        "GlobalCensus" -> hashHex[censusFile],
        "GlobalCensusInspector" -> hashHex[censusInspectorFile],
        "PathSeal" -> hashHex[pathSealFile],
        "PathInspector" -> hashHex[pathInspectorFile],
        "ValidatorV2" -> hashHex[validatorFile],
        "ValidatorV2Evidence" -> hashHex[validatorEvidenceFile],
        "FormalResult" -> hashHex[formalResultFile],
        "V4State" -> hashHex[v4State],
        "V4Report" -> hashHex[v4Report],
        "Driver" -> hashHex[driver],
        "V1Strip" -> hashHex[v1StripFile],
        "V1StripBytes" -> System`FileByteCount[v1StripFile],
        "V2Strip" -> hashHex[v2StripFile],
        "V2StripBytes" -> System`FileByteCount[v2StripFile]|>;
      badSourcesAfter = Select[Keys[expectedHashes],
        hashHex[FileNameJoin[{repositoryRoot, #1}]] =!=
          expectedHashes[#1] &];
      immutableGateQ = TrueQ[
        sourcePinsAfter === sourcePinsBefore &&
        badSourcesAfter === {} &&
        hashHex[bodyFile] === bodyHashBefore &&
        hashHex[launcherFile] === launcherHashBefore &&
        hashHex[driver] === driverHashBefore &&
        hashHex[launchSealFile] =!= Missing["HashFailed"] &&
        hashHex[loadAttemptFile] =!= Missing["HashFailed"]];
      If[! TrueQ[filesystemGateQ && immutableGateQ],
        fail["filesystem/provenance/TOCTOU gate failed"]];

      resultRecord = <|
        "Status" -> "CF300Sector12RecapturePreQuarantinePassedV4",
        "Family" -> "CF300", "SourceSector" -> 11,
        "TargetSector" -> 12, "LowerSector" -> 11,
        "WorkerKernelID" -> System`$KernelID,
        "NestedKernelCount" -> Length[System`Kernels[]],
        "TaskBrokerMaxHelpers" ->
          KernelPoolMission`$TaskBrokerMaxHelpers,
        "IntentionalDriverExit" -> driverExitPayload,
        "ZeroDriverMessagesQ" -> driverMessageGateQ,
        "DriverMessageSignatures" -> driverMessageSignatures,
        "DriverMessageTranscriptSHA256" ->
          hashHex[messageTranscriptFile],
        "DedicatedDriverContextRemovedQ" ->
          System`Names[driverContextPattern] === {},
        "ExplicitGlobalDefinitionStateRestoredQ" -> globalStateGateQ,
        "ExactGlobalNamespaceRestoredQ" -> globalNamespaceGateQ,
        "GlobalNamespaceBaselineCount" -> Length[globalNamesBaseline],
        "NewGlobalNamesRemoved" -> newGlobalNames,
        "GlobalCleanupMessages" -> globalCleanupMessages,
        "SystemLifecycleRestoredQ" ->
          SameQ[systemLifecycleAfter, systemLifecycleBefore],
        "EnvironmentRestoredQ" -> SameQ[
          AssociationThread[environmentNames,
            Environment /@ environmentNames], savedEnvironment],
        "ScriptCommandLineRestoredQ" ->
          SameQ[System`$ScriptCommandLine, savedCommandLine],
        "DirectoryRestoredQ" -> SameQ[System`Directory[], savedDirectory],
        "RecaptureStateUnchangedQ" ->
          Lookup[scopedExecution, "StateGateQ", False],
        "FreshStripExactReconstructionQ" ->
          Lookup[scopedExecution, "StripGateQ", False],
        "FreshStripSHA256" -> hashHex[stripInputFile],
        "FreshStripBytes" -> System`FileByteCount[stripInputFile],
        "NoStaleSector12CheckpointQ" ->
          ! System`FileExistsQ[stripCheckpointFile],
        "ExactTopLevelInventoryBeforeResultQ" -> filesystemGateQ,
        "NoTemporaryFilesQ" -> noTemporaryFilesQ,
        "V4CandidateImmutableQ" -> immutableGateQ,
        "SourcePinsBefore" -> sourcePinsBefore,
        "SourcePinsAfter" -> sourcePinsAfter,
        "SourceFileCount" -> 69,
        "LauncherSHA256" -> launcherHashBefore,
        "BodySHA256" -> bodyHashBefore,
        "DriverSHA256" -> expectedDriverHash,
        "StateSHA256" -> hashHex[stateFile],
        "SnapshotSHA256" -> hashHex[snapshotFile],
        "ReleaseSentinel" -> releaseSentinelFile,
        "ReleaseTokenSHA256" -> IntegerString[
          Hash[releaseToken, "SHA256"], 16, 64],
        "WorkerReusableQ" -> False,
        "CooperativeQuarantineRequiredQ" -> True,
        "AcceptanceEvidence" ->
          "This durable result plus the PRE-QUARANTINE PASS log line",
        "Completed" -> DateString[Now, "ISODateTime"]|>;
      If[putAtomic[resultRecord, resultFile] === $Failed ||
          ! SameQ[Quiet[Check[System`Get[resultFile], $Failed]], resultRecord],
        fail["atomic result write/rehydration failed"]];
      resultHash = hashHex[resultFile];
      quarantineMarker = <|
        "Status" -> "CF300Sector12RecapturePreQuarantinePassedV4",
        "WorkerKernelID" -> System`$KernelID,
        "ResultSHA256" -> resultHash,
        "StripSHA256" -> expectedV1StripHash,
        "StripBytes" -> expectedStripBytes,
        "LauncherSHA256" -> launcherHashBefore,
        "BodySHA256" -> bodyHashBefore,
        "DriverSHA256" -> expectedDriverHash,
        "ReleaseSentinel" -> releaseSentinelFile,
        "ReleaseTokenSHA256" -> IntegerString[
          Hash[releaseToken, "SHA256"], 16, 64],
        "PoolWorkerMustRemainOccupiedQ" -> True,
        "Created" -> DateString[Now, "ISODateTime"]|>;
      If[putAtomic[quarantineMarker, quarantineMarkerFile] === $Failed ||
          ! SameQ[Quiet[Check[System`Get[quarantineMarkerFile], $Failed]],
            quarantineMarker],
        fail["atomic pre-quarantine marker write/rehydration failed"]];
      quarantineMarkerHash = hashHex[quarantineMarkerFile];
      expectedTopLevelFinal = Sort[Append[
        Append[expectedTopLevelBeforeResult, resultFile],
        quarantineMarkerFile]];
      topLevelFinal = Sort[System`FileNames["*", outdir]];
      If[! TrueQ[
          topLevelFinal === expectedTopLevelFinal &&
          System`FileNames["*.tmp*", outdir, Infinity] === {} &&
          ! System`FileExistsQ[releaseSentinelFile] &&
          hashHex[resultFile] === resultHash &&
          hashHex[quarantineMarkerFile] === quarantineMarkerHash],
        fail["final durable-result/inventory gate failed"]];

      Print["CF300 S12 RECAPTURE V4 PRE-QUARANTINE PASS ",
        InputForm[<|
          "WorkerKernelID" -> System`$KernelID,
          "ResultSHA256" -> resultHash,
          "QuarantineMarkerSHA256" -> quarantineMarkerHash,
          "FreshStripSHA256" -> expectedV1StripHash,
          "FreshStripBytes" -> expectedStripBytes,
          "ZeroDriverMessagesQ" -> driverMessageGateQ,
          "ExactGlobalRestoreQ" ->
            TrueQ[globalStateGateQ && globalNamespaceGateQ],
          "ReleaseSentinel" -> releaseSentinelFile,
          "WorkerReusableQ" -> False|>]];

      heartbeatCount = 0;
      While[True,
        releaseText = Quiet[Check[
          If[System`FileExistsQ[releaseSentinelFile],
            Import[releaseSentinelFile, "Text"], Missing["Absent"]],
          Missing["Unreadable"]]];
        integritySnapshot = <|
          "HelperCeilingZeroQ" -> TrueQ[
            ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
            KernelPoolMission`$TaskBrokerMaxHelpers === 0],
          "NestedKernelCount" -> Length[System`Kernels[]],
          "LauncherSHA256" -> hashHex[launcherFile],
          "BodySHA256" -> hashHex[bodyFile],
          "DriverSHA256" -> hashHex[driver],
          "SourceManifestSHA256" -> hashHex[sourceManifest],
          "KernelPoolSourceSHA256" -> hashHex[kernelPoolSource],
          "PoolRunDefinitionSHA256" -> hashHex[poolRunDefinitionFile],
          "PreflightSHA256" -> hashHex[preflightFile],
          "GlobalCensusSHA256" -> hashHex[censusFile],
          "GlobalCensusInspectorSHA256" ->
            hashHex[censusInspectorFile],
          "PathSealSHA256" -> hashHex[pathSealFile],
          "PathInspectorSHA256" -> hashHex[pathInspectorFile],
          "ValidatorV2SHA256" -> hashHex[validatorFile],
          "ValidatorV2EvidenceSHA256" ->
            hashHex[validatorEvidenceFile],
          "FormalResultSHA256" -> hashHex[formalResultFile],
          "V4StateSHA256" -> hashHex[v4State],
          "V4ReportSHA256" -> hashHex[v4Report],
          "ResultSHA256" -> hashHex[resultFile],
          "QuarantineMarkerSHA256" -> hashHex[quarantineMarkerFile],
          "StateSHA256" -> hashHex[stateFile],
          "SnapshotSHA256" -> hashHex[snapshotFile],
          "FreshStripSHA256" -> hashHex[stripInputFile],
          "FreshStripBytes" -> If[System`FileExistsQ[stripInputFile],
            System`FileByteCount[stripInputFile], Missing["NotFound"]],
          "GlobalNamespaceExactQ" -> TrueQ[
            SameQ[System`Names["Global`*"], globalNamesBaseline] &&
            SameQ[AssociationMap[symbolDefinitionStateByName,
              globalNamesBaseline], globalBaselineStatesBefore]],
          "EnvironmentExactQ" -> TrueQ[SameQ[
            AssociationThread[environmentNames,
              Environment /@ environmentNames], savedEnvironment]],
          "CommandLineExactQ" ->
            SameQ[System`$ScriptCommandLine, savedCommandLine],
          "DirectoryExactQ" -> SameQ[System`Directory[], savedDirectory],
          "ReleaseSentinelPresentQ" ->
            System`FileExistsQ[releaseSentinelFile]|>;
        currentTopLevel = Sort[System`FileNames["*", outdir]];
        integrityQ = TrueQ[
          Lookup[integritySnapshot, "HelperCeilingZeroQ", False] &&
          Lookup[integritySnapshot, "NestedKernelCount", -1] === 0 &&
          Lookup[integritySnapshot, "LauncherSHA256", None] ===
            launcherHashBefore &&
          Lookup[integritySnapshot, "BodySHA256", None] ===
            bodyHashBefore &&
          Lookup[integritySnapshot, "DriverSHA256", None] ===
            expectedDriverHash &&
          Lookup[integritySnapshot, "SourceManifestSHA256", None] ===
            expectedSourceManifestHash &&
          Lookup[integritySnapshot, "KernelPoolSourceSHA256", None] ===
            expectedKernelPoolSourceHash &&
          Lookup[integritySnapshot, "PoolRunDefinitionSHA256", None] ===
            expectedPoolRunDefinitionHash &&
          Lookup[integritySnapshot, "PreflightSHA256", None] ===
            expectedPreflightHash &&
          Lookup[integritySnapshot, "GlobalCensusSHA256", None] ===
            expectedCensusHash &&
          Lookup[integritySnapshot,
            "GlobalCensusInspectorSHA256", None] ===
            expectedCensusInspectorHash &&
          Lookup[integritySnapshot, "PathSealSHA256", None] ===
            expectedPathSealHash &&
          Lookup[integritySnapshot, "PathInspectorSHA256", None] ===
            expectedPathInspectorHash &&
          Lookup[integritySnapshot, "ValidatorV2SHA256", None] ===
            expectedValidatorHash &&
          Lookup[integritySnapshot,
            "ValidatorV2EvidenceSHA256", None] ===
            expectedValidatorEvidenceHash &&
          Lookup[integritySnapshot, "FormalResultSHA256", None] ===
            expectedFormalResultHash &&
          Lookup[integritySnapshot, "V4StateSHA256", None] ===
            expectedV4StateHash &&
          Lookup[integritySnapshot, "V4ReportSHA256", None] ===
            expectedV4ReportHash &&
          Lookup[integritySnapshot, "ResultSHA256", None] === resultHash &&
          Lookup[integritySnapshot,
            "QuarantineMarkerSHA256", None] === quarantineMarkerHash &&
          Lookup[integritySnapshot, "StateSHA256", None] ===
            expectedV4StateHash &&
          Lookup[integritySnapshot, "SnapshotSHA256", None] ===
            expectedV4StateHash &&
          Lookup[integritySnapshot, "FreshStripSHA256", None] ===
            expectedV1StripHash &&
          Lookup[integritySnapshot, "FreshStripBytes", None] ===
            expectedStripBytes &&
          Lookup[integritySnapshot, "GlobalNamespaceExactQ", False] &&
          Lookup[integritySnapshot, "EnvironmentExactQ", False] &&
          Lookup[integritySnapshot, "CommandLineExactQ", False] &&
          Lookup[integritySnapshot, "DirectoryExactQ", False] &&
          System`FileNames["*.tmp*", outdir, Infinity] === {} &&
          currentTopLevel === If[System`FileExistsQ[releaseSentinelFile],
            Sort[Append[expectedTopLevelFinal, releaseSentinelFile]],
            expectedTopLevelFinal]];
        If[TrueQ[integrityQ] && StringQ[releaseText] &&
            StringTrim[releaseText] === releaseToken,
          Print["CF300 S12 RECAPTURE V4 QUARANTINE RELEASE ACK ",
            InputForm[<|"WorkerKernelID" -> System`$KernelID,
              "HeartbeatCount" -> heartbeatCount,
              "IntegrityQ" -> integrityQ,
              "IntegritySnapshot" -> integritySnapshot|>]];
          Break[]];
        Print["CF300 S12 RECAPTURE V4 QUARANTINE HEARTBEAT ",
          InputForm[<|"WorkerKernelID" -> System`$KernelID,
            "HeartbeatCount" -> heartbeatCount,
            "IntegrityQ" -> integrityQ,
            "IntegritySnapshot" -> integritySnapshot|>]];
        heartbeatCount++;
        Pause[30]];
      0,
      tag],
    (restoreDynamicState[];
     cleanupDriverContext[];
     Abort[])];

  restoreDynamicState[];
  cleanupDriverContext[];
  finalOutput = missionOutcome;
  If[TrueQ[packageLoadAttemptedQ && missionOutcome === $Failed],
    If[ListQ[globalNamesBaseline] &&
        AssociationQ[globalBaselineStatesBefore],
      newGlobalNames = Complement[
        System`Names["Global`*"], globalNamesBaseline];
      newGlobalStates = AssociationMap[
        symbolDefinitionStateByName, newGlobalNames];
      If[! AnyTrue[Values[newGlobalStates],
          MemberQ[Lookup[#1, "Attributes", {Locked}], Locked] &],
        Scan[Function[name,
          With[{literalName = name},
            Quiet[System`Unprotect[literalName]];
            Quiet[System`ClearAll[literalName]];
            Quiet[System`Remove[literalName]]]], newGlobalNames]]];
    If[! System`FileExistsQ[failureHoldFile],
      putAtomic[<|
        "Status" -> "CF300Sector12RecapturePostLoadFailureHeldV4",
        "WorkerKernelID" -> System`$KernelID,
        "Failure" -> lastFailure,
        "BodySHA256" -> hashHex[bodyFile],
        "DriverSHA256" -> hashHex[driver],
        "LoadAttemptSealSHA256" -> hashHex[loadAttemptFile],
        "FailureReleaseTokenSHA256" -> IntegerString[
          Hash[failureReleaseToken, "SHA256"], 16, 64],
        "Created" -> DateString[Now, "ISODateTime"]|>,
        failureHoldFile]];
    failureHoldHash = hashHex[failureHoldFile];
    failureTopLevelBaseline = Sort[DeleteCases[
      System`FileNames["*", outdir], releaseSentinelFile]];
    Print["CF300 S12 RECAPTURE V4 POST-LOAD FAILURE QUARANTINE ",
      InputForm[<|"WorkerKernelID" -> System`$KernelID,
        "Failure" -> lastFailure,
        "FailureHoldSHA256" -> hashHex[failureHoldFile],
        "ReleaseSentinel" -> releaseSentinelFile|>]];
    While[True,
      releaseText = Quiet[Check[
        If[System`FileExistsQ[releaseSentinelFile],
          Import[releaseSentinelFile, "Text"], Missing["Absent"]],
        Missing["Unreadable"]]];
      failureIntegrityQ = TrueQ[
        ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
        Length[System`Kernels[]] === 0 &&
        hashHex[bodyFile] === bodyHashBefore &&
        hashHex[launcherFile] === launcherHashBefore &&
        hashHex[driver] === expectedDriverHash &&
        hashHex[sourceManifest] === expectedSourceManifestHash &&
        hashHex[kernelPoolSource] === expectedKernelPoolSourceHash &&
        hashHex[poolRunDefinitionFile] ===
          expectedPoolRunDefinitionHash &&
        hashHex[preflightFile] === expectedPreflightHash &&
        hashHex[censusFile] === expectedCensusHash &&
        hashHex[censusInspectorFile] === expectedCensusInspectorHash &&
        hashHex[pathSealFile] === expectedPathSealHash &&
        hashHex[pathInspectorFile] === expectedPathInspectorHash &&
        hashHex[validatorFile] === expectedValidatorHash &&
        hashHex[validatorEvidenceFile] === expectedValidatorEvidenceHash &&
        hashHex[formalResultFile] === expectedFormalResultHash &&
        hashHex[v4State] === expectedV4StateHash &&
        hashHex[v4Report] === expectedV4ReportHash &&
        hashHex[loadAttemptFile] === loadAttemptHash &&
        hashHex[failureHoldFile] === failureHoldHash &&
        SameQ[System`Names["Global`*"], globalNamesBaseline] &&
        SameQ[AssociationMap[symbolDefinitionStateByName,
          globalNamesBaseline], globalBaselineStatesBefore] &&
        SameQ[AssociationThread[environmentNames,
          Environment /@ environmentNames], savedEnvironment] &&
        SameQ[System`$ScriptCommandLine, savedCommandLine] &&
        SameQ[System`Directory[], savedDirectory] &&
        System`FileNames["*.tmp*", outdir, Infinity] === {} &&
        Sort[System`FileNames["*", outdir]] ===
          If[System`FileExistsQ[releaseSentinelFile],
            Sort[Append[failureTopLevelBaseline, releaseSentinelFile]],
            failureTopLevelBaseline]];
      If[TrueQ[failureIntegrityQ] && StringQ[releaseText] &&
          StringTrim[releaseText] === failureReleaseToken,
        Print["CF300 S12 RECAPTURE V4 FAILURE RELEASE ACK ",
          InputForm[<|"WorkerKernelID" -> System`$KernelID,
            "IntegrityQ" -> failureIntegrityQ,
            "FailureHoldSHA256" -> failureHoldHash|>]];
        Break[]];
      Print["CF300 S12 RECAPTURE V4 FAILURE HEARTBEAT ",
        InputForm[<|"WorkerKernelID" -> System`$KernelID,
          "HelperCeilingZeroQ" -> TrueQ[
            ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
            KernelPoolMission`$TaskBrokerMaxHelpers === 0],
          "BodySHA256" -> hashHex[bodyFile],
          "DriverSHA256" -> hashHex[driver],
          "FailureHoldSHA256" -> hashHex[failureHoldFile],
          "IntegrityQ" -> failureIntegrityQ,
          "ReleaseSentinelPresentQ" ->
            System`FileExistsQ[releaseSentinelFile]|>]];
      Pause[30]]];
  finalOutput
];

With[
  {resolvedResult = bodyFinalResult,
   resolvedNamesBeforeCleanup = System`Join[
     System`Names["CodexCF300Sector12RecaptureV4`*"],
     System`Names["CodexCF300Sector12RecaptureV4`Private`*"]]},
  End[];
  EndPackage[];
  Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV4`Private`*"]];
  Quiet[System`Remove["CodexCF300Sector12RecaptureV4`*"]];
  With[
    {cleanupQ = System`Join[
       System`Names["CodexCF300Sector12RecaptureV4`*"],
       System`Names["CodexCF300Sector12RecaptureV4`Private`*"]] === {}},
    <|"Status" -> "CF300Sector12RecaptureV4BodyEnvelope",
      "BodyResult" -> If[cleanupQ, resolvedResult, $Failed],
      "DedicatedNameCleanupQ" -> cleanupQ,
      "NamesBeforeCleanupCount" ->
        Length[resolvedNamesBeforeCleanup]|>]]
