(* Fresh, source-pinned CF303 identity-frame capture, V3.

   Wrapper-level validation uses one private tagged Catch/Throw.  Every
   validation failure therefore becomes an ordinary $Failed value returned by
   Get to poolRun; no wrapper validation can dynamically escape poolRun's
   mission-end and completion-marker protocol.

   The family driver is different: KernelPool installs definitions which map
   its Exit/Quit to a throw tagged KernelPoolExit, and poolRun catches that
   tag.  V3 first verifies the live definitions structurally, then catches the
   driver's tagged exit locally, restores its process-local environment and
   other dynamic state, records a typed status, and rethrows the same payload
   for poolRun to file normally. *)

Module[
  {repositoryRoot = "/home/maxzhang/factorization-and-loops",
   driver, outdir, outdirParent, familyDataDirectory, classFormDirectory,
   sourceManifest, expectedManifestHash, kernelPoolSource,
   expectedKernelPoolSourceHash, poolRunDefinitionFile,
   expectedPoolRunDefinitionHash, manifestText, manifestLines,
   manifestParts, expectedHashes, hashHex, badSources,
   poolRunContractText, exitContractText, quitContractText,
   poolContractQ, preflightTag, preflightFailure, wrapperResult,
   environmentOverrides, savedEnvironment, environmentActive = False,
   savedCommandLine, savedDirectory, restoreEnvironment, putAtomic,
   launchSeal, runningStatus, driverArguments, driverResult,
   driverExitPayload = None},

  driver = FileNameJoin[
    {repositoryRoot, "Scripts", "family_epsform_sector.wls"}];
  outdir =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
      "cf303_identity_capture_xh_v3";
  outdirParent = DirectoryName[outdir];
  familyDataDirectory = FileNameJoin[{repositoryRoot,
    "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
  classFormDirectory =
    FileNameJoin[{familyDataDirectory, "ClassForms"}];
  sourceManifest = FileNameJoin[
    {DirectoryName[ExpandFileName[$InputFileName]],
      "SOURCE_SHA256SUMS"}];
  expectedManifestHash =
    "0123b6241eb8e396c98598d3de4625fc83b6df010d33d57b14b70a25a07c8a3d";
  kernelPoolSource =
    FileNameJoin[{repositoryRoot, "Scripts", "KernelPool.wls"}];
  expectedKernelPoolSourceHash =
    "0758f0f95a24b5dee4c6162939388ca5641610ef5e73bb73775a2030e8ff069d";
  poolRunDefinitionFile =
    "/tmp/codex-triple-root-20260823c.vx654S/pool/poolrun_definition.m";
  expectedPoolRunDefinitionHash =
    "d49632694d4da9f47a7c3c0d9828e98d47f9a416c9cb72d8a10a74b9b011db51";
  preflightTag = Unique["CF303IdentityCapturePreflightV3$"];

  preflightFailure[message_String] := (
    Print["CF303 CAPTURE PREFLIGHT FAILURE V3: " <> message];
    Throw[$Failed, preflightTag]);
  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file],
      IntegerString[FileHash[file, "SHA256"], 16, 64],
      Missing["NotFound"]], Missing["HashFailed"]]];
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

  wrapperResult = Catch[
    If[hashHex[sourceManifest] =!= expectedManifestHash,
      preflightFailure[
        "source manifest drifted or is unreadable: " <> sourceManifest]];
    If[hashHex[kernelPoolSource] =!= expectedKernelPoolSourceHash,
      preflightFailure[
        "KernelPool source drifted or is unreadable: " <> kernelPoolSource]];
    If[hashHex[poolRunDefinitionFile] =!= expectedPoolRunDefinitionHash,
      preflightFailure[
        "active poolRun definition file drifted or is unreadable: " <>
          poolRunDefinitionFile]];

    manifestText = Quiet[Check[Import[sourceManifest, "Text"], $Failed]];
    If[! StringQ[manifestText],
      preflightFailure["could not import source manifest"]];
    manifestLines = Select[
      StringSplit[manifestText, {"\r\n", "\n", "\r"}],
      StringLength[StringTrim[#]] > 0 &];
    manifestParts = StringSplit[StringTrim[#], Whitespace] & /@ manifestLines;
    If[Length[manifestParts] =!= 69 ||
        ! AllTrue[manifestParts,
          Length[#] === 2 &&
            StringMatchQ[#[[1]], Repeated[HexadecimalCharacter, {64}]] &&
            ! StringStartsQ[#[[2]], "/"] &&
            FreeQ[FileNameSplit[#[[2]]], ".."] &],
      preflightFailure["malformed source manifest"]];
    expectedHashes = Association[Rule @@@ (Reverse /@ manifestParts)];
    If[Length[expectedHashes] =!= Length[manifestParts],
      preflightFailure["duplicate source-manifest path"]];
    badSources = Select[Keys[expectedHashes],
      hashHex[FileNameJoin[{repositoryRoot, #}]] =!= expectedHashes[#] &];
    If[badSources =!= {},
      preflightFailure["source drift: " <> ToString[badSources, InputForm]]];

    If[Length[$ScriptCommandLine] =!= 1 ||
        ExpandFileName[First[$ScriptCommandLine]] =!=
          ExpandFileName[$InputFileName],
      preflightFailure["wrapper takes no arguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      preflightFailure["must run on a pool subkernel"]];
    If[Length[Kernels[]] =!= 0,
      preflightFailure["worker already owns nested kernels: " <>
        ToString[Length[Kernels[]], InputForm]]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 0),
      preflightFailure[
        "kpsubmit mission helper ceiling must be exactly zero"]];

    (* Verify the live interception contract without executing the traps. *)
    poolRunContractText =
      ToString[HoldComplete[DownValues[Global`poolRun]], InputForm];
    exitContractText =
      ToString[HoldComplete[DownValues[System`Exit]], InputForm];
    quitContractText =
      ToString[HoldComplete[DownValues[System`Quit]], InputForm];
    poolContractQ = And[
      StringContainsQ[poolRunContractText, "KernelPoolExit"],
      StringContainsQ[poolRunContractText, "MISSION end"],
      StringContainsQ[poolRunContractText, ".done"],
      StringContainsQ[exitContractText, "KernelPoolExit"],
      StringContainsQ[quitContractText, "KernelPoolExit"]];
    If[! TrueQ[poolContractQ],
      preflightFailure[
        "live poolRun/Exit/Quit marker contract is not installed"]];

    If[FileExistsQ[outdir] || DirectoryQ[outdir],
      preflightFailure["output is not fresh: " <> outdir]];
    If[! DirectoryQ[outdirParent],
      preflightFailure["output parent is absent: " <> outdirParent]];

    Quiet[Check[CreateDirectory[outdir], $Failed]];
    If[! DirectoryQ[outdir],
      preflightFailure["could not create output: " <> outdir]];

    environmentOverrides = <|
      "FACET_KERNEL_COUNT" -> "1",
      "FACET_TASK_BROKER_MAX_HELPERS" -> "0",
      "FACET_CHECK_LEVEL" -> "Production",
      "FACET_STRIP_ROUTE" -> "FiniteFieldFirst",
      "FACET_ZERO_FORCING" -> "True",
      "FACET_RECORD_STRIP_ONLY" -> "False",
      "FACET_RESUME_HYDRATION" -> "True",
      "FACET_MEMTRACE" -> FileNameJoin[{outdir, "memtrace.log"}]|>;
    savedEnvironment = AssociationThread[
      Keys[environmentOverrides], Environment /@ Keys[environmentOverrides]];
    savedCommandLine = $ScriptCommandLine;
    savedDirectory = Directory[];
    driverArguments = {driver, "CF303", outdir, "1800",
      "identity_capture_xh_v3", "30", "", familyDataDirectory,
      classFormDirectory};
    launchSeal = <|
      "Status" -> "CF303IdentityCaptureLaunchSealedV3",
      "Family" -> "CF303",
      "FrameRequest" -> "TransportFamilyChart[CF303] (no chart override)",
      "FreshOutputDirectory" -> outdir,
      "FreshOutputParent" -> outdirParent,
      "Driver" -> driver,
      "DriverArguments" -> driverArguments,
      "EnvironmentOverrides" -> environmentOverrides,
      "MissionTaskBrokerMaxHelpers" ->
        KernelPoolMission`$TaskBrokerMaxHelpers,
      "WorkerKernelID" -> $KernelID,
      "NestedKernelCountBeforeDriver" -> Length[Kernels[]],
      "SourceManifest" -> sourceManifest,
      "SourceManifestSHA256" -> expectedManifestHash,
      "KernelPoolSourceSHA256" -> expectedKernelPoolSourceHash,
      "PoolRunDefinitionSHA256" -> expectedPoolRunDefinitionHash,
      "PoolExitContractVerified" -> poolContractQ,
      "SourceFileCount" -> Length[expectedHashes] + 1,
      "WrapperSHA256" -> hashHex[ExpandFileName[$InputFileName]],
      "Created" -> DateString[Now, "ISODateTime"]|>;
    If[putAtomic[launchSeal,
        FileNameJoin[{outdir,
          "CF303_identity_capture_launch_seal_v3.wl"}]] === $Failed,
      preflightFailure["atomic launch-seal write failed"]];
    runningStatus = <|
      "Status" -> "CF303IdentityCaptureRunningV3",
      "Family" -> "CF303", "OutputDirectory" -> outdir,
      "DriverSHA256" -> expectedHashes["Scripts/family_epsform_sector.wls"],
      "SourceManifestSHA256" -> expectedManifestHash,
      "PoolExitContractVerified" -> poolContractQ,
      "Started" -> DateString[Now, "ISODateTime"]|>;
    If[putAtomic[runningStatus,
        FileNameJoin[{outdir,
          "CF303_identity_capture_status_running_v3.wl"}]] === $Failed,
      preflightFailure["atomic running-status write failed"]];

    Print["CF303 CAPTURE PREFLIGHT OK V3: 70 source hashes + active " <>
      "poolRun definition; fresh output " <> outdir <>
      "; one worker; zero nested helpers; pool exit contract verified"];
    environmentActive = True;
    If[! TrueQ[Quiet[Check[
        SetEnvironment[Normal[environmentOverrides]]; True, False]]],
      restoreEnvironment[];
      preflightFailure["could not install scoped environment"]];
    Unprotect[$ScriptCommandLine];
    $ScriptCommandLine = driverArguments;
    driverResult = CheckAbort[
      Catch[
        Quiet[Check[Get[driver], $Failed], General::shdw],
        "KernelPoolExit",
        Function[{payload, tag}, driverExitPayload = payload; payload]],
      Quiet[putAtomic[
        Join[runningStatus, <|
          "Status" -> "CF303IdentityCaptureAbortedV3",
          "Stopped" -> DateString[Now, "ISODateTime"]|>],
        FileNameJoin[{outdir,
          "CF303_identity_capture_status_aborted_v3.wl"}]]];
      restoreEnvironment[];
      $ScriptCommandLine = savedCommandLine;
      SetDirectory[savedDirectory];
      Abort[]];
    restoreEnvironment[];
    $ScriptCommandLine = savedCommandLine;
    SetDirectory[savedDirectory];

    If[MatchQ[driverExitPayload, {"EXIT", _}],
      Quiet[putAtomic[
        Join[runningStatus, <|
          "Status" -> "CF303IdentityCaptureDriverExitCapturedV3",
          "DriverExitCode" -> driverExitPayload[[2]],
          "EnvironmentRestored" -> ! TrueQ[environmentActive],
          "Stopped" -> DateString[Now, "ISODateTime"]|>],
        FileNameJoin[{outdir,
          "CF303_identity_capture_status_driver_exit_v3.wl"}]]];
      Throw[driverExitPayload, "KernelPoolExit"],
      Quiet[putAtomic[
        Join[runningStatus, <|
          "Status" -> "CF303IdentityCaptureDriverReturnedV3",
          "DriverResultHead" -> ToString[Head[driverResult], InputForm],
          "EnvironmentRestored" -> ! TrueQ[environmentActive],
          "Stopped" -> DateString[Now, "ISODateTime"]|>],
        FileNameJoin[{outdir,
          "CF303_identity_capture_status_returned_v3.wl"}]]];
      driverResult],
    preflightTag];
  wrapperResult
]
