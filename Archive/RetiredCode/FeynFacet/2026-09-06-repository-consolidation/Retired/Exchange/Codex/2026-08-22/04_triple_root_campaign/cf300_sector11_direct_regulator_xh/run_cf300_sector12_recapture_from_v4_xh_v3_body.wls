#!/usr/bin/env wolframscript

(* Private body for the fresh isolated CF300 sector-12 V3 recapture.  The
   launcher rejects dirty workers before this file can write an output and
   localizes $ContextPath/$Packages for the complete package lifecycle.  This
   body pins both failed recaptures as audit evidence, keeps every durable
   control in a dedicated private context, and accepts exactly the clean-run
   singleton BuildBasis::length message signature. *)

$HistoryLength = 0;
If[System`Join[System`Names["CodexCF300Sector12RecaptureV3`*"],
      System`Names["CodexCF300Sector12RecaptureV3`Private`*"]] =!= {} ||
    ! System`FreeQ[System`$ContextPath,
      "CodexCF300Sector12RecaptureV3`" |
       "CodexCF300Sector12RecaptureV3`Private`"] ||
    ! System`FreeQ[System`$Packages,
      "CodexCF300Sector12RecaptureV3`" |
       "CodexCF300Sector12RecaptureV3`Private`"],
  System`Exit[62]];
BeginPackage["CodexCF300Sector12RecaptureV3`"];
Begin["`Private`"];

Module[
  {repositoryRoot, bundleDirectory, driver, sourceManifest,
   expectedManifestHash, kernelPoolSource, expectedKernelPoolSourceHash,
   poolRunDefinitionFile, expectedPoolRunDefinitionHash,
   validatorFile, expectedValidatorHash, validatorEvidenceFile,
   expectedValidatorEvidenceHash, formalInspectorFile,
   expectedFormalInspectorHash, formalResultFile,
   expectedFormalResultHash, v4State, expectedV4StateHash, v4Report,
   expectedV4ReportHash, v1WrapperFile, expectedV1WrapperHash,
   v1FailedLogFile, expectedV1FailedLogHash, v1FailedStatusFile,
   expectedV1FailedStatusHash, v1Outdir, v1LaunchSealFile,
   expectedV1LaunchSealHash, v1SnapshotFile, expectedV1SnapshotHash,
   v1StateFile, expectedV1StateHash, v1StripFile,
   expectedV1StripHash, expectedV1StripBytes, v1PinsBefore, v1PinsAfter,
   v2WrapperFile, expectedV2WrapperHash, v2ManifestFile,
   expectedV2ManifestHash, v2ProbeFile, expectedV2ProbeHash,
   v2ProbeLogFile, expectedV2ProbeLogHash, v2ProbeStatusFile,
   expectedV2ProbeStatusHash, v2FailedLogFile, expectedV2FailedLogHash,
   v2FailedStatusFile, expectedV2FailedStatusHash, v2Outdir,
   v2LaunchSealFile, expectedV2LaunchSealHash, v2SnapshotFile,
   expectedV2SnapshotHash, v2StateFile, expectedV2StateHash,
   v2StripFile, expectedV2StripHash, expectedV2StripBytes,
   v2PinsBefore, v2PinsAfter,
   knownDriverMessageText,
   outdir, outdirParent, stateFile, snapshotFile, scratch,
   stripInputFile, stripCheckpointFile, resultFile, launchSealFile,
   familyDataDirectory, classFormDirectory, manifestText, manifestLines,
   manifestParts, expectedHashes, badSources, badSourcesAfter, hashHex,
   preflightTag, fail, putAtomic, restoreEnvironment,
   restoreDriverDynamicState, environmentOverrides, savedEnvironment,
   environmentAfter, environmentActive = False, savedCommandLine,
   commandLineAfter, savedCommandLineProtectedQ,
   commandLineProtectedAfterQ, savedDirectory, directoryAfter,
   driverArguments, driverMessagesRaw = {}, driverMessageSignatures = {},
   allowedDriverMessageSignatures, allowedDriverMessagesQ = False,
   driverResult, driverExitPayload = None, driverExitCapturedQ = False,
   forwardExitPayload = None, wrapperResult, candidateHashesBefore,
   candidateHashesAfter, sourcePinsBefore, sourcePinsAfter, copyResults,
   recaptureState, snapshotState, stripRecord, expectedStrip, readMessages,
   stateGate, stripGate, filesystemGate, immutableGate,
   environmentComponentsQ, commandLineRestoredQ, directoryRestoredQ,
   protectionRestoredQ, environmentFlagRestoredQ, environmentRestoredQ,
   restorationTelemetry, resultRecord},

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

  v1WrapperFile = FileNameJoin[{bundleDirectory,
    "run_cf300_sector12_recapture_from_v4_xh_v1.wls"}];
  expectedV1WrapperHash =
    "e0456c5e0472cceeb982dac23ce78af632846a062dbe6ecdc8527929c96a21fe";
  v1FailedLogFile = FileNameJoin[{bundleDirectory,
    "cf300_s12_recapture_from_v4_xh_v1_FAILED.log"}];
  expectedV1FailedLogHash =
    "34a786e30fc00f13d6b630f42c544138f1b0c99a79c54fbb4f853d3cf257ecb6";
  v1FailedStatusFile = FileNameJoin[{bundleDirectory,
    "cf300_s12_recapture_from_v4_xh_v1_FAILED.status"}];
  expectedV1FailedStatusHash =
    "cce9b175ef7ca2123fccaede7688eb47986820ddd84c68d2a9323e76b3f8d950";
  v1Outdir =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
    "cf300_sector12_recapture_from_v4_xh_v1";
  v1LaunchSealFile = FileNameJoin[{v1Outdir,
    "CF300_sector12_recapture_launch_seal_v1.wl"}];
  expectedV1LaunchSealHash =
    "8de31fe88daabb96db1366cd402e505e7a5f505054ed0b78327464c323b6ba4d";
  v1SnapshotFile = FileNameJoin[{v1Outdir,
    "pre_sector12_snapshot_CF300_standard.wl"}];
  expectedV1SnapshotHash = expectedV4StateHash;
  v1StateFile = FileNameJoin[{v1Outdir,
    "sector_state_CF300_standard.wl"}];
  expectedV1StateHash = expectedV4StateHash;
  v1StripFile = FileNameJoin[{v1Outdir, "sector_CF300_standard",
    "CF300_12_11_input.wl"}];
  expectedV1StripHash =
    "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976";
  expectedV1StripBytes = 15667;
  v2WrapperFile = FileNameJoin[{bundleDirectory,
    "run_cf300_sector12_recapture_from_v4_xh_v2.wls"}];
  expectedV2WrapperHash =
    "8667a863f0fe60a8fc59080880c7736ee76114189bb1b49196c342a2f2a9ccbb";
  v2ManifestFile = FileNameJoin[{bundleDirectory,
    "MANIFEST_CF300_SECTOR12_RECAPTURE_V2.sha256"}];
  expectedV2ManifestHash =
    "6f006cc45ef60dbb029cf92d3c49fcf07c5c4aaa716dddab947a98d320b9791e";
  v2ProbeFile = FileNameJoin[{bundleDirectory,
    "probe_cf300_sector12_recapture_v2_parse_context.wls"}];
  expectedV2ProbeHash =
    "bf85d8df492e8b4a95c2a692f74177377daedc4d96cfa6da3b1de125cc6cb531";
  v2ProbeLogFile = FileNameJoin[{bundleDirectory,
    "probe_cf300_s12_recapture_v2_parse_context_xh_v2_OK.log"}];
  expectedV2ProbeLogHash =
    "0284f86e66b12033ee55ba0cfc713e3564da8de6b157b4dab59d74de90f5439f";
  v2ProbeStatusFile = FileNameJoin[{bundleDirectory,
    "probe_cf300_s12_recapture_v2_parse_context_xh_v2_OK.status"}];
  expectedV2ProbeStatusHash =
    "0c4fb1ffb4dae801a5c2412fddcb1ddda6bdd4a2a3496e2a9da253bd3f9ad6ae";
  v2FailedLogFile = FileNameJoin[{bundleDirectory,
    "cf300_s12_recapture_from_v4_xh_v2_FAILED.log"}];
  expectedV2FailedLogHash =
    "fb9d15dd1c3f00c48cb0fe673e57917ba15da7049e50329bcb764a7e5c0392c9";
  v2FailedStatusFile = FileNameJoin[{bundleDirectory,
    "cf300_s12_recapture_from_v4_xh_v2_FAILED.status"}];
  expectedV2FailedStatusHash =
    "b8799711ced0ee6f0be9f50166d7632b4163c9e780012d32a5389dde2ea0d142";
  v2Outdir =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
    "cf300_sector12_recapture_from_v4_xh_v2";
  v2LaunchSealFile = FileNameJoin[{v2Outdir,
    "CF300_sector12_recapture_launch_seal_v2.wl"}];
  expectedV2LaunchSealHash =
    "8a5d807036fbd01c136ab68ae774c058b8b29de95da7d2a4f4891a6e26473f43";
  v2SnapshotFile = FileNameJoin[{v2Outdir,
    "pre_sector12_snapshot_CF300_standard.wl"}];
  expectedV2SnapshotHash = expectedV4StateHash;
  v2StateFile = FileNameJoin[{v2Outdir,
    "sector_state_CF300_standard.wl"}];
  expectedV2StateHash = expectedV4StateHash;
  v2StripFile = FileNameJoin[{v2Outdir, "sector_CF300_standard",
    "CF300_12_11_input.wl"}];
  expectedV2StripHash =
    "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976";
  expectedV2StripBytes = 15667;
  knownDriverMessageText =
    "BuildBasis::length: Expected four basis vectors, but received " <>
    "{nb, 5, xhat, yhat}.";

  outdir =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
    "cf300_sector12_recapture_from_v4_xh_v3";
  outdirParent = DirectoryName[outdir];
  stateFile = FileNameJoin[{outdir, "sector_state_CF300_standard.wl"}];
  snapshotFile = FileNameJoin[{outdir,
    "pre_sector12_snapshot_CF300_standard.wl"}];
  scratch = FileNameJoin[{outdir, "sector_CF300_standard"}];
  stripInputFile = FileNameJoin[{scratch, "CF300_12_11_input.wl"}];
  stripCheckpointFile = FileNameJoin[{scratch,
    "CF300_12_strip_state.wl"}];
  resultFile = FileNameJoin[{outdir,
    "CF300_sector12_recapture_result_v3.wl"}];
  launchSealFile = FileNameJoin[{outdir,
    "CF300_sector12_recapture_launch_seal_v3.wl"}];
  familyDataDirectory = FileNameJoin[{repositoryRoot,
    "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
  classFormDirectory = FileNameJoin[{familyDataDirectory, "ClassForms"}];
  preflightTag = Unique["CF300Sector12RecaptureV3$"];
  allowedDriverMessageSignatures = {"HoldForm[BuildBasis::length]"};

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file],
      IntegerString[FileHash[file, "SHA256"], 16, 64],
      Missing["NotFound"]], Missing["HashFailed"]]];
  fail[message_String] := (
    Print["CF300 S12 RECAPTURE V3 FAIL: " <> message];
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
    If[TrueQ[savedCommandLineProtectedQ], Protect[$ScriptCommandLine],
      Unprotect[$ScriptCommandLine]];
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
    v1PinsBefore = <|
      "Wrapper" -> hashHex[v1WrapperFile],
      "FailedLog" -> hashHex[v1FailedLogFile],
      "FailedStatus" -> hashHex[v1FailedStatusFile],
      "LaunchSeal" -> hashHex[v1LaunchSealFile],
      "Snapshot" -> hashHex[v1SnapshotFile],
      "State" -> hashHex[v1StateFile],
      "Strip" -> hashHex[v1StripFile],
      "StripBytes" -> If[FileExistsQ[v1StripFile],
        FileByteCount[v1StripFile], Missing["NotFound"]]|>;
    If[v1PinsBefore =!= <|
        "Wrapper" -> expectedV1WrapperHash,
        "FailedLog" -> expectedV1FailedLogHash,
        "FailedStatus" -> expectedV1FailedStatusHash,
        "LaunchSeal" -> expectedV1LaunchSealHash,
        "Snapshot" -> expectedV1SnapshotHash,
        "State" -> expectedV1StateHash,
        "Strip" -> expectedV1StripHash,
        "StripBytes" -> expectedV1StripBytes|>,
      fail["frozen V1 evidence/output drifted"]];
    v2PinsBefore = <|
      "Wrapper" -> hashHex[v2WrapperFile],
      "Manifest" -> hashHex[v2ManifestFile],
      "Probe" -> hashHex[v2ProbeFile],
      "ProbeOKLog" -> hashHex[v2ProbeLogFile],
      "ProbeOKStatus" -> hashHex[v2ProbeStatusFile],
      "FailedLog" -> hashHex[v2FailedLogFile],
      "FailedStatus" -> hashHex[v2FailedStatusFile],
      "LaunchSeal" -> hashHex[v2LaunchSealFile],
      "Snapshot" -> hashHex[v2SnapshotFile],
      "State" -> hashHex[v2StateFile],
      "Strip" -> hashHex[v2StripFile],
      "StripBytes" -> If[FileExistsQ[v2StripFile],
        FileByteCount[v2StripFile], Missing["NotFound"]]|>;
    If[v2PinsBefore =!= <|
        "Wrapper" -> expectedV2WrapperHash,
        "Manifest" -> expectedV2ManifestHash,
        "Probe" -> expectedV2ProbeHash,
        "ProbeOKLog" -> expectedV2ProbeLogHash,
        "ProbeOKStatus" -> expectedV2ProbeStatusHash,
        "FailedLog" -> expectedV2FailedLogHash,
        "FailedStatus" -> expectedV2FailedStatusHash,
        "LaunchSeal" -> expectedV2LaunchSealHash,
        "Snapshot" -> expectedV2SnapshotHash,
        "State" -> expectedV2StateHash,
        "Strip" -> expectedV2StripHash,
        "StripBytes" -> expectedV2StripBytes|>,
      fail["frozen V2 evidence/output drifted"]];

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
        "Status" -> "CF300Sector12RecaptureLaunchSealedV3",
        "Family" -> "CF300", "SourceSector" -> 11,
        "TargetSector" -> 12, "LowerSector" -> 11,
        "OutputDirectory" -> outdir,
        "PreSector12Snapshot" -> snapshotFile,
        "DriverArguments" -> driverArguments,
        "EnvironmentOverrides" -> environmentOverrides,
        "AllowedDriverMessageSignatures" ->
          allowedDriverMessageSignatures,
        "AllowedDriverMessageRenderedV1" -> knownDriverMessageText,
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
        "V1WrapperSHA256" -> expectedV1WrapperHash,
        "V1FailedLogSHA256" -> expectedV1FailedLogHash,
        "V1FailedStatusSHA256" -> expectedV1FailedStatusHash,
        "V1LaunchSealSHA256" -> expectedV1LaunchSealHash,
        "V1StripSHA256" -> expectedV1StripHash,
        "V2WrapperSHA256" -> expectedV2WrapperHash,
        "V2ManifestSHA256" -> expectedV2ManifestHash,
        "V2ProbeSHA256" -> expectedV2ProbeHash,
        "V2ProbeOKLogSHA256" -> expectedV2ProbeLogHash,
        "V2ProbeOKStatusSHA256" -> expectedV2ProbeStatusHash,
        "V2FailedLogSHA256" -> expectedV2FailedLogHash,
        "V2FailedStatusSHA256" -> expectedV2FailedStatusHash,
        "V2LaunchSealSHA256" -> expectedV2LaunchSealHash,
        "V2StripSHA256" -> expectedV2StripHash,
        "BodySHA256" -> hashHex[ExpandFileName[$InputFileName]],
        "Created" -> DateString[Now, "ISODateTime"]|>,
        launchSealFile] === $Failed,
      fail["atomic launch-seal write failed"]];

    Print["CF300 S12 RECAPTURE V3 PREFLIGHT OK: 69 sources; " <>
      "certified V4 copy; frozen failed V1/V2; dedicated control context; " <>
      "Production+FiniteFieldFirst; one main; zero helpers; " <>
      "record-only sector 12 lower 11"];
    environmentActive = True;
    If[! TrueQ[Quiet[Check[
        SetEnvironment[Normal[environmentOverrides]]; True, False]]],
      restoreEnvironment[];
      fail["could not install scoped environment"]];
    Quiet[Unprotect[$ScriptCommandLine]];
    $ScriptCommandLine = driverArguments;
    Block[{$MessageList = {}, $Context = "Global`"},
      driverResult = CheckAbort[
        Catch[
          Get[driver],
          "KernelPoolExit",
          Function[{payload, tag},
            driverExitCapturedQ = True;
            driverExitPayload = payload; payload]],
        driverMessagesRaw = $MessageList;
        driverMessageSignatures =
          ToString[InputForm[#1]] & /@ driverMessagesRaw;
        restoreDriverDynamicState[];
        Abort[]];
      driverMessagesRaw = $MessageList;
      driverMessageSignatures =
        ToString[InputForm[#1]] & /@ driverMessagesRaw];
    restoreDriverDynamicState[];

    environmentAfter = AssociationThread[
      Keys[environmentOverrides], Environment /@ Keys[environmentOverrides]];
    commandLineAfter = $ScriptCommandLine;
    directoryAfter = Directory[];
    commandLineProtectedAfterQ =
      MemberQ[Attributes[$ScriptCommandLine], Protected];
    environmentComponentsQ = AssociationMap[
      SameQ[environmentAfter[#1], savedEnvironment[#1]] &,
      Keys[environmentOverrides]];
    commandLineRestoredQ = SameQ[commandLineAfter, savedCommandLine];
    directoryRestoredQ = SameQ[directoryAfter, savedDirectory];
    protectionRestoredQ = SameQ[commandLineProtectedAfterQ,
      savedCommandLineProtectedQ];
    environmentFlagRestoredQ = TrueQ[! environmentActive];
    environmentRestoredQ = TrueQ[
      And @@ Values[environmentComponentsQ] && commandLineRestoredQ &&
      directoryRestoredQ && protectionRestoredQ &&
      environmentFlagRestoredQ];
    restorationTelemetry = <|
      "SavedEnvironment" -> savedEnvironment,
      "CurrentEnvironment" -> environmentAfter,
      "EnvironmentComponentQ" -> environmentComponentsQ,
      "SavedCommandLine" -> savedCommandLine,
      "CurrentCommandLine" -> commandLineAfter,
      "CommandLineRestoredQ" -> commandLineRestoredQ,
      "SavedDirectory" -> savedDirectory,
      "CurrentDirectory" -> directoryAfter,
      "DirectoryRestoredQ" -> directoryRestoredQ,
      "SavedScriptCommandLineProtectedQ" ->
        savedCommandLineProtectedQ,
      "CurrentScriptCommandLineProtectedQ" ->
        commandLineProtectedAfterQ,
      "ScriptCommandLineProtectionRestoredQ" -> protectionRestoredQ,
      "EnvironmentActiveFlagClearedQ" -> environmentFlagRestoredQ,
      "AllRestoredQ" -> environmentRestoredQ|>;
    Print["CF300 S12 RECAPTURE V3 RESTORATION TELEMETRY ",
      InputForm[restorationTelemetry]];

    allowedDriverMessagesQ = TrueQ[
      Length[driverMessagesRaw] === 1 &&
      driverMessageSignatures === allowedDriverMessageSignatures];
    Print["CF300 S12 RECAPTURE V3 DRIVER MESSAGE TELEMETRY ",
      InputForm[<|
        "RawMessageCount" -> Length[driverMessagesRaw],
        "MessageSignatures" -> driverMessageSignatures,
        "AllowedSignatures" -> allowedDriverMessageSignatures,
        "AllowedQ" -> allowedDriverMessagesQ|>]];

    If[! environmentRestoredQ,
      fail["environment/command-line/directory/protection restoration " <>
        "failed"]];
    If[! allowedDriverMessagesQ,
      fail["driver message list was not the exact pinned startup " <>
        "signature: " <>
        ToString[driverMessageSignatures, InputForm]]];
    If[TrueQ[driverExitCapturedQ] &&
        driverExitPayload =!= {"EXIT", 75},
      Print["CF300 S12 RECAPTURE V3 forwarding non-record exit after " <>
        "restoration and telemetry: " <>
        ToString[driverExitPayload, InputForm]];
      forwardExitPayload = driverExitPayload;
      Throw["ForwardExit", preflightTag]];
    If[! TrueQ[driverExitCapturedQ] ||
        driverExitPayload =!= {"EXIT", 75},
      fail["driver did not produce the intentional KernelPoolExit 75: " <>
        ToString[<|"Payload" -> driverExitPayload,
          "ResultHead" -> Head[driverResult]|>, InputForm]]];

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
    v1PinsAfter = <|
      "Wrapper" -> hashHex[v1WrapperFile],
      "FailedLog" -> hashHex[v1FailedLogFile],
      "FailedStatus" -> hashHex[v1FailedStatusFile],
      "LaunchSeal" -> hashHex[v1LaunchSealFile],
      "Snapshot" -> hashHex[v1SnapshotFile],
      "State" -> hashHex[v1StateFile],
      "Strip" -> hashHex[v1StripFile],
      "StripBytes" -> If[FileExistsQ[v1StripFile],
        FileByteCount[v1StripFile], Missing["NotFound"]]|>;
    v2PinsAfter = <|
      "Wrapper" -> hashHex[v2WrapperFile],
      "Manifest" -> hashHex[v2ManifestFile],
      "Probe" -> hashHex[v2ProbeFile],
      "ProbeOKLog" -> hashHex[v2ProbeLogFile],
      "ProbeOKStatus" -> hashHex[v2ProbeStatusFile],
      "FailedLog" -> hashHex[v2FailedLogFile],
      "FailedStatus" -> hashHex[v2FailedStatusFile],
      "LaunchSeal" -> hashHex[v2LaunchSealFile],
      "Snapshot" -> hashHex[v2SnapshotFile],
      "State" -> hashHex[v2StateFile],
      "Strip" -> hashHex[v2StripFile],
      "StripBytes" -> If[FileExistsQ[v2StripFile],
        FileByteCount[v2StripFile], Missing["NotFound"]]|>;
    badSourcesAfter = Select[Keys[expectedHashes],
      hashHex[FileNameJoin[{repositoryRoot, #1}]] =!=
        expectedHashes[#1] &];
    immutableGate = TrueQ[
      candidateHashesAfter === candidateHashesBefore &&
      sourcePinsAfter === sourcePinsBefore &&
      v1PinsAfter === v1PinsBefore && v2PinsAfter === v2PinsBefore &&
      badSourcesAfter === {} &&
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
      "Status" -> "CF300Sector12RecapturePassedV3",
      "Family" -> "CF300", "SourceSector" -> 11,
      "TargetSector" -> 12, "LowerSector" -> 11,
      "IntentionalDriverExit" -> driverExitPayload,
      "DriverMessagesRaw" -> driverMessagesRaw,
      "DriverMessageSignatures" -> driverMessageSignatures,
      "AllowedDriverMessageRenderedV1" -> knownDriverMessageText,
      "AllowedDriverMessagesQ" -> allowedDriverMessagesQ,
      "RestorationTelemetry" -> restorationTelemetry,
      "EnvironmentRestoredQ" -> environmentRestoredQ,
      "V4CandidateImmutableQ" -> immutableGate,
      "FrozenV1ImmutableQ" -> SameQ[v1PinsAfter, v1PinsBefore],
      "FrozenV2ImmutableQ" -> SameQ[v2PinsAfter, v2PinsBefore],
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
      "V1WrapperSHA256" -> expectedV1WrapperHash,
      "V1FailedLogSHA256" -> expectedV1FailedLogHash,
      "V1FailedStatusSHA256" -> expectedV1FailedStatusHash,
      "V1LaunchSealSHA256" -> expectedV1LaunchSealHash,
      "V1StripSHA256" -> expectedV1StripHash,
      "V2WrapperSHA256" -> expectedV2WrapperHash,
      "V2ManifestSHA256" -> expectedV2ManifestHash,
      "V2ProbeSHA256" -> expectedV2ProbeHash,
      "V2ProbeOKLogSHA256" -> expectedV2ProbeLogHash,
      "V2ProbeOKStatusSHA256" -> expectedV2ProbeStatusHash,
      "V2FailedLogSHA256" -> expectedV2FailedLogHash,
      "V2FailedStatusSHA256" -> expectedV2FailedStatusHash,
      "V2LaunchSealSHA256" -> expectedV2LaunchSealHash,
      "V2StripSHA256" -> expectedV2StripHash,
      "BodySHA256" -> hashHex[ExpandFileName[$InputFileName]],
      "RequiredNextAction" ->
        "Analyze the fresh sector-12/lower-11 strip before full resume",
      "Completed" -> DateString[Now, "ISODateTime"]|>;
    If[putAtomic[resultRecord, resultFile] === $Failed,
      fail["atomic recapture result write failed"]];
    If[! FileExistsQ[resultFile] ||
        ! SameQ[Quiet[Get[resultFile]], resultRecord],
      fail["recapture result did not rehydrate exactly"]];
    Print["CF300 S12 RECAPTURE V3 PASS ",
      InputForm[KeyTake[resultRecord,
        {"Status", "IntentionalDriverExit", "AllowedDriverMessagesQ",
         "EnvironmentRestoredQ", "V4CandidateImmutableQ",
         "FrozenV1ImmutableQ", "FrozenV2ImmutableQ",
         "RecaptureStateUnchangedQ",
         "FreshStripExactReconstructionQ",
         "NoStaleSector12CheckpointQ", "Sector12InputSHA256"}]]];
    0,
    preflightTag];

  finalResult = wrapperResult;
  finalForwardPayload = forwardExitPayload;
];

With[
  {resolvedResult = finalResult,
   resolvedForwardPayload = finalForwardPayload,
   resolvedPrivateNames =
     System`Join[System`Names["CodexCF300Sector12RecaptureV3`*"],
       System`Names["CodexCF300Sector12RecaptureV3`Private`*"]],
   resolvedContextPathBeforeEnd = System`$ContextPath,
   resolvedPackagesBeforeEnd = System`$Packages},
  End[];
  EndPackage[];
  Print["CF300 S12 RECAPTURE V3 DEDICATED CONTEXT TELEMETRY ",
    InputForm[<|"NameCountBeforeCleanup" -> Length[resolvedPrivateNames],
      "FirstNames" -> Take[resolvedPrivateNames, UpTo[12]],
      "PublicContextOnPathBeforeEndQ" ->
        System`MemberQ[resolvedContextPathBeforeEnd,
          "CodexCF300Sector12RecaptureV3`"],
      "PrivateContextOnPathBeforeEndQ" ->
        System`MemberQ[resolvedContextPathBeforeEnd,
          "CodexCF300Sector12RecaptureV3`Private`"],
      "PublicContextInPackagesBeforeEndQ" ->
        System`MemberQ[resolvedPackagesBeforeEnd,
          "CodexCF300Sector12RecaptureV3`"]|>]];
  Quiet[System`Remove["CodexCF300Sector12RecaptureV3`Private`*"]];
  Quiet[System`Remove["CodexCF300Sector12RecaptureV3`*"]];
  With[{resolvedNameCleanupQ =
      System`Join[System`Names["CodexCF300Sector12RecaptureV3`*"],
        System`Names["CodexCF300Sector12RecaptureV3`Private`*"]] === {}},
    <|"Status" -> "CF300Sector12RecaptureV3BodyEnvelope",
      "BodyResult" -> If[resolvedNameCleanupQ, resolvedResult, $Failed],
      "ForwardPayload" -> resolvedForwardPayload,
      "DedicatedNameCleanupQ" -> resolvedNameCleanupQ,
      "ContextPathWasLocalizedQ" ->
        System`MemberQ[resolvedContextPathBeforeEnd,
          "CodexCF300Sector12RecaptureV3`"],
      "PackagesWasLocalizedQ" ->
        System`MemberQ[resolvedPackagesBeforeEnd,
          "CodexCF300Sector12RecaptureV3`"]|>]]
