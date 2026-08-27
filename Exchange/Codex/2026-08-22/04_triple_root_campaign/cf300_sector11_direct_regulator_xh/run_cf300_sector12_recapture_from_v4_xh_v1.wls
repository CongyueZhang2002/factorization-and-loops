#!/usr/bin/env wolframscript

(* Fresh isolated CF300 sector-12 strip recapture from the certified V4
   sector-11 state.  The V4 candidate is immutable.  The family driver is
   source pinned, gets exactly one main kernel and zero helpers, records the
   first sector-12 strip, and intentionally exits through KernelPoolExit 75.
   This wrapper restores all scoped process state before accepting 75 or
   rethrowing any other driver exit. *)

$HistoryLength = 0;
Module[
  {repositoryRoot, bundleDirectory, driver, sourceManifest,
   expectedManifestHash, kernelPoolSource, expectedKernelPoolSourceHash,
   poolRunDefinitionFile, expectedPoolRunDefinitionHash,
   validatorFile, expectedValidatorHash, validatorEvidenceFile,
   expectedValidatorEvidenceHash, formalInspectorFile,
   expectedFormalInspectorHash, formalResultFile,
   expectedFormalResultHash, v4State, expectedV4StateHash, v4Report,
   expectedV4ReportHash, outdir, outdirParent, stateFile, snapshotFile,
   scratch, stripInputFile, stripCheckpointFile, resultFile, launchSealFile,
   familyDataDirectory, classFormDirectory, manifestText, manifestLines,
   manifestParts, expectedHashes, badSources, badSourcesAfter, hashHex,
   preflightTag, fail, putAtomic, restoreEnvironment,
   restoreDriverDynamicState, environmentOverrides, savedEnvironment,
   environmentActive = False, savedCommandLine, savedCommandLineProtectedQ,
   savedDirectory, driverArguments, driverMessages = {}, driverResult,
   driverExitPayload = None, driverExitCapturedQ = False, wrapperResult,
   candidateHashesBefore,
   candidateHashesAfter, sourcePinsBefore, sourcePinsAfter, copyResults,
   recaptureState, snapshotState, stripRecord, expectedStrip, readMessages,
   stateGate, stripGate, filesystemGate, immutableGate, environmentRestoredQ,
   resultRecord},

  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  bundleDirectory = DirectoryName[ExpandFileName[$InputFileName]];
  driver = FileNameJoin[{repositoryRoot, "Scripts",
    "family_epsform_sector.wls"}];
  sourceManifest = FileNameJoin[{bundleDirectory,
    "CF300_RESUME_SOURCE_SHA256SUMS"}];
  expectedManifestHash =
    "880c4f7850b2c0daf5c207e96df23113c91d75d1056e23c6edc169aec66487b2";
  kernelPoolSource = FileNameJoin[{repositoryRoot, "Scripts",
    "KernelPool.wls"}];
  expectedKernelPoolSourceHash =
    "0758f0f95a24b5dee4c6162939388ca5641610ef5e73bb73775a2030e8ff069d";
  poolRunDefinitionFile =
    "/tmp/codex-triple-root-20260823c.vx654S/pool/poolrun_definition.m";
  expectedPoolRunDefinitionHash =
    "d49632694d4da9f47a7c3c0d9828e98d47f9a416c9cb72d8a10a74b9b011db51";
  validatorFile = FileNameJoin[{bundleDirectory,
    "validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls"}];
  expectedValidatorHash =
    "304e7748e3971e9b0bf50fc84b10f50cda8231d49d6df235327134a297c45759";
  validatorEvidenceFile = FileNameJoin[{bundleDirectory,
    "cf300_s11_postwrite_validator_xh_v2_OK.log"}];
  expectedValidatorEvidenceHash =
    "185d009d9ed4a56037c3360a14862b97e8e39cfbe8e591c5d6bc38d936d45f3e";
  formalInspectorFile = FileNameJoin[{bundleDirectory,
    "inspect_cf300_sector11_postwrite_v4.py"}];
  expectedFormalInspectorHash =
    "554248efd8e62d293c8a4bfcef0e6774945b36b43965a8a65297d9609b764a8b";
  formalResultFile = FileNameJoin[{bundleDirectory,
    "cf300_sector11_postwrite_formal_inspector_v4_result.json"}];
  expectedFormalResultHash =
    "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128";
  v4State = FileNameJoin[{repositoryRoot, "ppHX_NNLO_DoubleReal",
    "Results", "UU_08_10_canonical", "FamilyEpsFormsSolving",
    "triple_root_2026-08-23", "CF300_direct_regulator_v4_candidate",
    "sector_state_CF300_standard.wl"}];
  expectedV4StateHash =
    "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009";
  v4Report = FileNameJoin[{DirectoryName[v4State],
    "cf300_sector11_direct_regulator_report_v4.wl"}];
  expectedV4ReportHash =
    "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e";

  outdir =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
    "cf300_sector12_recapture_from_v4_xh_v1";
  outdirParent = DirectoryName[outdir];
  stateFile = FileNameJoin[{outdir, "sector_state_CF300_standard.wl"}];
  snapshotFile = FileNameJoin[{outdir,
    "pre_sector12_snapshot_CF300_standard.wl"}];
  scratch = FileNameJoin[{outdir, "sector_CF300_standard"}];
  stripInputFile = FileNameJoin[{scratch, "CF300_12_11_input.wl"}];
  stripCheckpointFile = FileNameJoin[{scratch,
    "CF300_12_strip_state.wl"}];
  resultFile = FileNameJoin[{outdir,
    "CF300_sector12_recapture_result_v1.wl"}];
  launchSealFile = FileNameJoin[{outdir,
    "CF300_sector12_recapture_launch_seal_v1.wl"}];
  familyDataDirectory = FileNameJoin[{repositoryRoot,
    "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
  classFormDirectory = FileNameJoin[{familyDataDirectory, "ClassForms"}];
  preflightTag = Unique["CF300Sector12RecaptureV1$"];

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file],
      IntegerString[FileHash[file, "SHA256"], 16, 64],
      Missing["NotFound"]], Missing["HashFailed"]]];
  fail[message_String] := (
    Print["CF300 S12 RECAPTURE V1 FAIL: " <> message];
    Throw[$Failed, preflightTag]);
  putAtomic[expression_, file_String] := Module[
    {temporary, written, moved},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    written = Quiet[Check[
      Put[expression, temporary]; FileExistsQ[temporary], False]];
    If[TrueQ[written],
      moved = Quiet[Check[
        RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
      If[StringQ[moved] && FileExistsQ[file], file, $Failed],
      $Failed]];
  restoreEnvironment[] := If[TrueQ[environmentActive],
    KeyValueMap[
      Function[{name, value},
        If[StringQ[value], SetEnvironment[name -> value],
          UnsetEnvironment[name]]], savedEnvironment];
    environmentActive = False];
  restoreDriverDynamicState[] := (
    restoreEnvironment[];
    Quiet[Unprotect[$ScriptCommandLine]];
    $ScriptCommandLine = savedCommandLine;
    If[TrueQ[savedCommandLineProtectedQ], Protect[$ScriptCommandLine]];
    SetDirectory[savedDirectory]);

  wrapperResult = Catch[
    If[hashHex[sourceManifest] =!= expectedManifestHash,
      fail["resume source manifest drifted or is unreadable"]];
    If[hashHex[kernelPoolSource] =!= expectedKernelPoolSourceHash ||
        hashHex[poolRunDefinitionFile] =!= expectedPoolRunDefinitionHash,
      fail["pool interception contract drifted"]];
    sourcePinsBefore = <|
      "ValidatorV2SHA256" -> hashHex[validatorFile],
      "ValidatorV2EvidenceSHA256" -> hashHex[validatorEvidenceFile],
      "FormalInspectorSHA256" -> hashHex[formalInspectorFile],
      "FormalResultSHA256" -> hashHex[formalResultFile],
      "V4StateSHA256" -> hashHex[v4State],
      "V4ReportSHA256" -> hashHex[v4Report]|>;
    If[sourcePinsBefore =!= <|
        "ValidatorV2SHA256" -> expectedValidatorHash,
        "ValidatorV2EvidenceSHA256" -> expectedValidatorEvidenceHash,
        "FormalInspectorSHA256" -> expectedFormalInspectorHash,
        "FormalResultSHA256" -> expectedFormalResultHash,
        "V4StateSHA256" -> expectedV4StateHash,
        "V4ReportSHA256" -> expectedV4ReportHash|>,
      fail["V4/validator provenance drifted"]];

    manifestText = Quiet[Check[Import[sourceManifest, "Text"], $Failed]];
    If[! StringQ[manifestText], fail["could not import source manifest"]];
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
    If[Length[expectedHashes] =!= Length[manifestParts],
      fail["duplicate source-manifest path"]];
    badSources = Select[Keys[expectedHashes],
      hashHex[FileNameJoin[{repositoryRoot, #1}]] =!=
        expectedHashes[#1] &];
    If[badSources =!= {},
      fail["source drift: " <> ToString[badSources, InputForm]]];

    If[Length[Rest[$ScriptCommandLine]] =!= 0,
      fail["wrapper takes no arguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["must run on a pool worker"]];
    If[Length[Kernels[]] =!= 0,
      fail["worker already owns nested kernels"]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 0),
      fail["mission helper ceiling must be exactly zero"]];
    If[FileExistsQ[outdir] || DirectoryQ[outdir],
      fail["recapture output is not fresh: " <> outdir]];
    If[! DirectoryQ[outdirParent],
      fail["recapture output parent is absent"]];

    If[Quiet[Check[CreateDirectory[outdir], $Failed]] === $Failed ||
        ! DirectoryQ[outdir],
      fail["could not create fresh recapture output"]];
    copyResults = Quiet[Check[
      {CopyFile[v4State, snapshotFile, OverwriteTarget -> False],
       CopyFile[v4State, stateFile, OverwriteTarget -> False]}, $Failed]];
    If[copyResults === $Failed ||
        hashHex[snapshotFile] =!= expectedV4StateHash ||
        hashHex[stateFile] =!= expectedV4StateHash || DirectoryQ[scratch],
      fail["exact V4 state copy or fresh-scratch gate failed"]];

    environmentOverrides = <|
      "FACET_KERNEL_COUNT" -> "1",
      "FACET_TASK_BROKER_MAX_HELPERS" -> "0",
      "FACET_CHECK_LEVEL" -> "Production",
      "FACET_STRIP_ROUTE" -> "FiniteFieldFirst",
      "FACET_ZERO_FORCING" -> "True",
      "FACET_RECORD_STRIP_ONLY" -> "True",
      "FACET_RESUME_HYDRATION" -> "True"|>;
    savedEnvironment = AssociationThread[
      Keys[environmentOverrides], Environment /@ Keys[environmentOverrides]];
    savedCommandLine = $ScriptCommandLine;
    savedCommandLineProtectedQ = MemberQ[Attributes[$ScriptCommandLine],
      Protected];
    savedDirectory = Directory[];
    driverArguments = {driver, "CF300", outdir, "7200", "standard",
      "30", "", familyDataDirectory, classFormDirectory};
    If[driverArguments =!= {driver, "CF300", outdir, "7200",
        "standard", "30", "", familyDataDirectory,
        classFormDirectory},
      fail["driver argument seal failed"]];
    If[environmentOverrides =!= <|
        "FACET_KERNEL_COUNT" -> "1",
        "FACET_TASK_BROKER_MAX_HELPERS" -> "0",
        "FACET_CHECK_LEVEL" -> "Production",
        "FACET_STRIP_ROUTE" -> "FiniteFieldFirst",
        "FACET_ZERO_FORCING" -> "True",
        "FACET_RECORD_STRIP_ONLY" -> "True",
        "FACET_RESUME_HYDRATION" -> "True"|>,
      fail["environment seal failed"]];

    candidateHashesBefore = <|
      "State" -> hashHex[v4State], "Report" -> hashHex[v4Report]|>;
    If[candidateHashesBefore =!= <|"State" -> expectedV4StateHash,
        "Report" -> expectedV4ReportHash|>,
      fail["V4 candidate changed before launch"]];
    If[putAtomic[<|
        "Status" -> "CF300Sector12RecaptureLaunchSealedV1",
        "Family" -> "CF300", "SourceSector" -> 11,
        "TargetSector" -> 12, "LowerSector" -> 11,
        "OutputDirectory" -> outdir,
        "PreSector12Snapshot" -> snapshotFile,
        "DriverArguments" -> driverArguments,
        "EnvironmentOverrides" -> environmentOverrides,
        "MissionTaskBrokerMaxHelpers" ->
          KernelPoolMission`$TaskBrokerMaxHelpers,
        "WorkerKernelID" -> $KernelID,
        "NestedKernelCountBeforeDriver" -> Length[Kernels[]],
        "SourceManifestSHA256" -> expectedManifestHash,
        "SourceFileCount" -> 69,
        "KernelPoolSourceSHA256" -> expectedKernelPoolSourceHash,
        "PoolRunDefinitionSHA256" -> expectedPoolRunDefinitionHash,
        "ValidatorV2SHA256" -> expectedValidatorHash,
        "ValidatorV2EvidenceSHA256" -> expectedValidatorEvidenceHash,
        "FormalResultSHA256" -> expectedFormalResultHash,
        "V4StateSHA256" -> expectedV4StateHash,
        "V4ReportSHA256" -> expectedV4ReportHash,
        "WrapperSHA256" -> hashHex[ExpandFileName[$InputFileName]],
        "Created" -> DateString[Now, "ISODateTime"]|>,
        launchSealFile] === $Failed,
      fail["atomic launch-seal write failed"]];

    Print["CF300 S12 RECAPTURE V1 PREFLIGHT OK: 69 sources; " <>
      "certified V4 copy; Production+FiniteFieldFirst; one main; " <>
      "zero helpers; record-only sector 12 lower 11"];
    environmentActive = True;
    If[! TrueQ[Quiet[Check[
        SetEnvironment[Normal[environmentOverrides]]; True, False]]],
      restoreEnvironment[];
      fail["could not install scoped environment"]];
    Quiet[Unprotect[$ScriptCommandLine]];
    $ScriptCommandLine = driverArguments;
    Block[{$MessageList = {}},
      driverResult = CheckAbort[
        Catch[
          Quiet[Get[driver], General::shdw],
          "KernelPoolExit",
          Function[{payload, tag},
            driverExitCapturedQ = True;
            driverExitPayload = payload; payload]],
        driverMessages = ToString[InputForm[#1]] & /@ $MessageList;
        restoreDriverDynamicState[];
        Abort[]];
      driverMessages = ToString[InputForm[#1]] & /@ $MessageList];
    restoreDriverDynamicState[];
    environmentRestoredQ = TrueQ[
      ! environmentActive && $ScriptCommandLine === savedCommandLine &&
      Directory[] === savedDirectory &&
      AssociationThread[Keys[environmentOverrides],
        Environment /@ Keys[environmentOverrides]] === savedEnvironment];

    If[TrueQ[driverExitCapturedQ] &&
        driverExitPayload =!= {"EXIT", 75},
      Print["CF300 S12 RECAPTURE V1 forwarding non-record exit after " <>
        "environment restoration: " <>
        ToString[driverExitPayload, InputForm]];
      Throw[driverExitPayload, "KernelPoolExit"]];
    If[! TrueQ[driverExitCapturedQ] ||
        driverExitPayload =!= {"EXIT", 75},
      fail["driver did not produce the intentional KernelPoolExit 75: " <>
        ToString[<|"Payload" -> driverExitPayload,
          "ResultHead" -> Head[driverResult]|>, InputForm]]];
    If[! environmentRestoredQ,
      fail["environment/command-line/directory restoration failed"]];
    If[driverMessages =!= {},
      fail["record-only driver emitted unexpected messages: " <>
        ToString[driverMessages, InputForm]]];

    readMessages = {};
    Block[{$MessageList = {}},
      recaptureState = Quiet[CheckAbort[Get[stateFile], $Aborted]];
      snapshotState = Quiet[CheckAbort[Get[snapshotFile], $Aborted]];
      stripRecord = Quiet[CheckAbort[Get[stripInputFile], $Aborted]];
      readMessages = ToString[InputForm[#1]] & /@ $MessageList];
    stateGate = TrueQ[
      readMessages === {} && AssociationQ[recaptureState] &&
      AssociationQ[snapshotState] && SameQ[recaptureState, snapshotState] &&
      Lookup[recaptureState, "Sector", None] === 11 &&
      ! KeyExistsQ[recaptureState, "Stop"] &&
      Dimensions[Lookup[recaptureState, "A", {}]] === {2, 24, 24} &&
      Dimensions[Lookup[recaptureState, "S", {}]] === {24, 24} &&
      Dimensions[Lookup[recaptureState, "SInverse", {}]] === {24, 24} &&
      Length[Lookup[recaptureState,
        "RegulatorFactorizations", {}]] === 10 &&
      Lookup[Last[recaptureState["RegulatorFactorizations"]],
        "Rows", None] === 11 &&
      ! AnyTrue[Lookup[recaptureState, "SectorCertificates", {}],
        Lookup[#1, "Sector", None] === 12 &] &&
      ! AnyTrue[Lookup[recaptureState, "StripSolvers", {}],
        Lookup[#1, "Sector", None] === 12 &]];
    expectedStrip = If[stateGate,
      FeynFacet`Private`familyRowGaugeResumeBlockEquation[
        recaptureState["A"], 12, 11, <||>,
        recaptureState["Ranges"], Symbol["Global`eps"]], $Failed];
    stripGate = TrueQ[
      AssociationQ[stripRecord] &&
      Lookup[stripRecord, "Family", None] === "CF300" &&
      Lookup[stripRecord, "Sector", None] === 12 &&
      Lookup[stripRecord, "LowerSector", None] === 11 &&
      Lookup[stripRecord, "Variables", None] ===
        {Symbol["Global`x"], Symbol["Global`y"]} &&
      Lookup[stripRecord, "Regulator", None] === Symbol["Global`eps"] &&
      Dimensions[Lookup[stripRecord, "Strip", {}]] === {3, 2, 2, 2} &&
      SameQ[Lookup[stripRecord, "Strip", $Failed], expectedStrip]];
    filesystemGate = TrueQ[
      FileExistsQ[stateFile] && FileExistsQ[snapshotFile] &&
      FileExistsQ[stripInputFile] && ! FileExistsQ[stripCheckpointFile] &&
      ! FileExistsQ[stateFile <> ".tmp"] &&
      ! FileExistsQ[stripInputFile <> ".tmp"] &&
      Sort[FileNames["*", scratch]] === {stripInputFile} &&
      hashHex[snapshotFile] === expectedV4StateHash];

    candidateHashesAfter = <|
      "State" -> hashHex[v4State], "Report" -> hashHex[v4Report]|>;
    sourcePinsAfter = <|
      "ValidatorV2SHA256" -> hashHex[validatorFile],
      "ValidatorV2EvidenceSHA256" -> hashHex[validatorEvidenceFile],
      "FormalInspectorSHA256" -> hashHex[formalInspectorFile],
      "FormalResultSHA256" -> hashHex[formalResultFile],
      "V4StateSHA256" -> hashHex[v4State],
      "V4ReportSHA256" -> hashHex[v4Report]|>;
    badSourcesAfter = Select[Keys[expectedHashes],
      hashHex[FileNameJoin[{repositoryRoot, #1}]] =!=
        expectedHashes[#1] &];
    immutableGate = TrueQ[
      candidateHashesAfter === candidateHashesBefore &&
      sourcePinsAfter === sourcePinsBefore && badSourcesAfter === {} &&
      hashHex[sourceManifest] === expectedManifestHash &&
      hashHex[kernelPoolSource] === expectedKernelPoolSourceHash &&
      hashHex[poolRunDefinitionFile] === expectedPoolRunDefinitionHash];
    If[! TrueQ[stateGate && stripGate && filesystemGate && immutableGate],
      fail["post-record validation failed: " <>
        ToString[<|"StateGateQ" -> stateGate,
          "StripGateQ" -> stripGate,
          "FilesystemGateQ" -> filesystemGate,
          "ImmutableGateQ" -> immutableGate,
          "ReadMessages" -> readMessages|>, InputForm]]];

    resultRecord = <|
      "Status" -> "CF300Sector12RecapturePassedV1",
      "Family" -> "CF300", "SourceSector" -> 11,
      "TargetSector" -> 12, "LowerSector" -> 11,
      "IntentionalDriverExit" -> driverExitPayload,
      "DriverMessages" -> driverMessages,
      "EnvironmentRestoredQ" -> environmentRestoredQ,
      "V4CandidateImmutableQ" -> immutableGate,
      "RecaptureStateUnchangedQ" -> stateGate,
      "FreshStripExactReconstructionQ" -> stripGate,
      "NoStaleSector12CheckpointQ" -> ! FileExistsQ[stripCheckpointFile],
      "PreSector12Snapshot" -> snapshotFile,
      "PreSector12SnapshotSHA256" -> hashHex[snapshotFile],
      "RecaptureState" -> stateFile,
      "RecaptureStateSHA256" -> hashHex[stateFile],
      "Sector12Input" -> stripInputFile,
      "Sector12InputSHA256" -> hashHex[stripInputFile],
      "Sector12InputBytes" -> FileByteCount[stripInputFile],
      "SourceManifestSHA256" -> expectedManifestHash,
      "SourceFileCount" -> 69,
      "ValidatorV2SHA256" -> expectedValidatorHash,
      "ValidatorV2EvidenceSHA256" -> expectedValidatorEvidenceHash,
      "FormalResultSHA256" -> expectedFormalResultHash,
      "V4StateSHA256" -> expectedV4StateHash,
      "V4ReportSHA256" -> expectedV4ReportHash,
      "WrapperSHA256" -> hashHex[ExpandFileName[$InputFileName]],
      "RequiredNextAction" ->
        "Analyze the fresh sector-12/lower-11 strip before full resume",
      "Completed" -> DateString[Now, "ISODateTime"]|>;
    If[putAtomic[resultRecord, resultFile] === $Failed,
      fail["atomic recapture result write failed"]];
    If[! FileExistsQ[resultFile] ||
        ! SameQ[Quiet[Get[resultFile]], resultRecord],
      fail["recapture result did not rehydrate exactly"]];
    Print["CF300 S12 RECAPTURE V1 PASS ",
      InputForm[KeyTake[resultRecord,
        {"Status", "IntentionalDriverExit", "EnvironmentRestoredQ",
         "V4CandidateImmutableQ", "RecaptureStateUnchangedQ",
         "FreshStripExactReconstructionQ",
         "NoStaleSector12CheckpointQ", "Sector12InputSHA256"}]]];
    0,
    preflightTag];
  wrapperResult
]
