(* Fresh, source-pinned CF303 identity-frame capture.

   This wrapper is meant to be submitted through Scripts/kpsubmit.sh with
   FACET_TASK_BROKER_MAX_HELPERS=0.  It refuses a main kernel, a pool worker
   which already owns nested kernels, any source drift, any pre-existing
   output directory, or any extra command-line argument.  The family driver
   then receives KernelCount=1 and cannot launch nested Wolfram kernels; both
   the inherited and mission-scoped task-broker ceilings are zero.

   Environment changes are restored if the driver returns or aborts.  The
   normal family driver terminates with Exit; in that case the pool worker
   process ends and its process-local environment disappears with it. *)

Module[
  {repositoryRoot = "/home/maxzhang/factorization-and-loops",
   driver, outdir, familyDataDirectory, classFormDirectory,
   sourceManifest, expectedManifestHash,
   manifestText, manifestLines, manifestParts, expectedHashes,
   hashHex, badSources, environmentOverrides, savedEnvironment,
   savedCommandLine, savedDirectory, restoreEnvironment, putAtomic,
   launchSeal, runningStatus, driverArguments, driverResult},

  driver = FileNameJoin[
    {repositoryRoot, "Scripts", "family_epsform_sector.wls"}];
  outdir =
    "/tmp/codex-triple-root-20260823c.vx654S/" <>
      "cf303_identity_capture_xh_v1";
  familyDataDirectory = FileNameJoin[{repositoryRoot,
    "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
  classFormDirectory =
    FileNameJoin[{familyDataDirectory, "ClassForms"}];
  sourceManifest = FileNameJoin[
    {DirectoryName[ExpandFileName[$InputFileName]],
      "SOURCE_SHA256SUMS"}];
  expectedManifestHash =
    "0123b6241eb8e396c98598d3de4625fc83b6df010d33d57b14b70a25a07c8a3d";

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file],
      IntegerString[FileHash[file, "SHA256"], 16, 64],
      Missing["NotFound"]], Missing["HashFailed"]]];

  If[hashHex[sourceManifest] =!= expectedManifestHash,
    Print["CF303 CAPTURE PREFLIGHT FAILURE: source manifest drifted or is " <>
      "unreadable: " <> sourceManifest];
    Return[$Failed]];

  manifestText = Quiet[Check[Import[sourceManifest, "Text"], $Failed]];
  If[! StringQ[manifestText],
    Print["CF303 CAPTURE PREFLIGHT FAILURE: could not import source manifest"];
    Return[$Failed]];
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
    Print["CF303 CAPTURE PREFLIGHT FAILURE: malformed source manifest"];
    Return[$Failed]];
  expectedHashes = Association[Rule @@@ (Reverse /@ manifestParts)];
  If[Length[expectedHashes] =!= Length[manifestParts],
    Print["CF303 CAPTURE PREFLIGHT FAILURE: duplicate source-manifest path"];
    Return[$Failed]];
  badSources = Select[Keys[expectedHashes],
    hashHex[FileNameJoin[{repositoryRoot, #}]] =!= expectedHashes[#] &];
  If[badSources =!= {},
    Print["CF303 CAPTURE PREFLIGHT FAILURE: source drift: ", badSources];
    Return[$Failed]];

  If[Length[$ScriptCommandLine] =!= 1 ||
      ExpandFileName[First[$ScriptCommandLine]] =!=
        ExpandFileName[$InputFileName],
    Print["CF303 CAPTURE PREFLIGHT FAILURE: wrapper takes no arguments"];
    Return[$Failed]];
  If[! IntegerQ[$KernelID] || $KernelID <= 0,
    Print["CF303 CAPTURE PREFLIGHT FAILURE: must run on a pool subkernel"];
    Return[$Failed]];
  If[Length[Kernels[]] =!= 0,
    Print["CF303 CAPTURE PREFLIGHT FAILURE: worker already owns nested " <>
      "kernels: " <> ToString[Length[Kernels[]], InputForm]];
    Return[$Failed]];
  If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
      KernelPoolMission`$TaskBrokerMaxHelpers === 0),
    Print["CF303 CAPTURE PREFLIGHT FAILURE: kpsubmit mission helper ceiling " <>
      "must be exactly zero"];
    Return[$Failed]];
  If[FileExistsQ[outdir] || DirectoryQ[outdir],
    Print["CF303 CAPTURE PREFLIGHT FAILURE: output is not fresh: " <> outdir];
    Return[$Failed]];
  If[! DirectoryQ[ParentDirectory[outdir]],
    Print["CF303 CAPTURE PREFLIGHT FAILURE: output parent is absent: " <>
      ParentDirectory[outdir]];
    Return[$Failed]];

  putAtomic[expression_, file_String] := Module[{temporary, written, moved},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    written = Quiet[Check[Put[expression, temporary];
      FileExistsQ[temporary], False]];
    If[! TrueQ[written], Return[$Failed]];
    moved = Quiet[Check[
      RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
    If[StringQ[moved] && FileExistsQ[file], file, $Failed]];

  Quiet[Check[CreateDirectory[outdir], $Failed]];
  If[! DirectoryQ[outdir],
    Print["CF303 CAPTURE PREFLIGHT FAILURE: could not create output: " <>
      outdir];
    Return[$Failed]];

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
  restoreEnvironment[] := KeyValueMap[
    Function[{name, value},
      If[StringQ[value], SetEnvironment[name -> value],
        UnsetEnvironment[name]]], savedEnvironment];
  savedCommandLine = $ScriptCommandLine;
  savedDirectory = Directory[];

  driverArguments = {driver, "CF303", outdir, "1800",
    "identity_capture_xh_v1", "30", "", familyDataDirectory,
    classFormDirectory};
  launchSeal = <|
    "Status" -> "CF303IdentityCaptureLaunchSealed",
    "Family" -> "CF303",
    "FrameRequest" -> "TransportFamilyChart[CF303] (no chart override)",
    "FreshOutputDirectory" -> outdir,
    "Driver" -> driver,
    "DriverArguments" -> driverArguments,
    "EnvironmentOverrides" -> environmentOverrides,
    "MissionTaskBrokerMaxHelpers" ->
      KernelPoolMission`$TaskBrokerMaxHelpers,
    "WorkerKernelID" -> $KernelID,
    "NestedKernelCountBeforeDriver" -> Length[Kernels[]],
    "SourceManifest" -> sourceManifest,
    "SourceManifestSHA256" -> expectedManifestHash,
    "SourceFileCount" -> Length[expectedHashes],
    "WrapperSHA256" -> hashHex[ExpandFileName[$InputFileName]],
    "Created" -> DateString[Now, "ISODateTime"]|>;
  If[putAtomic[launchSeal,
      FileNameJoin[{outdir, "CF303_identity_capture_launch_seal.wl"}]] ===
      $Failed,
    Print["CF303 CAPTURE PREFLIGHT FAILURE: atomic launch-seal write failed"];
    Return[$Failed]];
  runningStatus = <|
    "Status" -> "CF303IdentityCaptureRunning",
    "Family" -> "CF303", "OutputDirectory" -> outdir,
    "DriverSHA256" -> expectedHashes["Scripts/family_epsform_sector.wls"],
    "SourceManifestSHA256" -> expectedManifestHash,
    "Started" -> DateString[Now, "ISODateTime"]|>;
  If[putAtomic[runningStatus,
      FileNameJoin[{outdir, "CF303_identity_capture_status_running.wl"}]] ===
      $Failed,
    Print["CF303 CAPTURE PREFLIGHT FAILURE: atomic running-status write failed"];
    Return[$Failed]];

  Print["CF303 CAPTURE PREFLIGHT OK: 69 source hashes; fresh output ",
    outdir, "; one worker; zero nested helpers"];
  SetEnvironment[Normal[environmentOverrides]];
  Unprotect[$ScriptCommandLine];
  $ScriptCommandLine = driverArguments;
  driverResult = CheckAbort[
    Quiet[Check[Get[driver], $Failed], General::shdw],
    Quiet[putAtomic[
      Join[runningStatus, <|
        "Status" -> "CF303IdentityCaptureAborted",
        "Stopped" -> DateString[Now, "ISODateTime"]|>],
      FileNameJoin[{outdir,
        "CF303_identity_capture_status_aborted.wl"}]]];
    restoreEnvironment[];
    $ScriptCommandLine = savedCommandLine;
    SetDirectory[savedDirectory];
    Abort[]];
  restoreEnvironment[];
  $ScriptCommandLine = savedCommandLine;
  SetDirectory[savedDirectory];
  Quiet[putAtomic[
    Join[runningStatus, <|
      "Status" -> "CF303IdentityCaptureDriverReturned",
      "DriverResultHead" -> ToString[Head[driverResult], InputForm],
      "Stopped" -> DateString[Now, "ISODateTime"]|>],
    FileNameJoin[{outdir, "CF303_identity_capture_status_returned.wl"}]]];
  driverResult
]
