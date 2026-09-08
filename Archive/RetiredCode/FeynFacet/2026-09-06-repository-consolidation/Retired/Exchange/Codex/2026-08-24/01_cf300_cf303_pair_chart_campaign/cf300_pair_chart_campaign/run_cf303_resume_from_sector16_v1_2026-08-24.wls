#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, driver, outdir, scratch, stateFile,
    stripCheckpointFile, familyDataDirectory, classFormDirectory,
    expectedHashes, badHashes, hashHex, launchSealFile, launchSeal,
    temporary, environmentOverrides, driverArguments, preflightTag,
    fail, result},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  driver = FileNameJoin[{repositoryRoot, "Scripts",
    "family_epsform_sector.wls"}];
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_resume_from_sector16_v1";
  scratch = FileNameJoin[{outdir,
    "sector_CF303_identity_capture_xh_v4"}];
  stateFile = FileNameJoin[{outdir,
    "sector_state_CF303_identity_capture_xh_v4.wl"}];
  stripCheckpointFile = FileNameJoin[{scratch,
    "CF303_17_strip_state.wl"}];
  familyDataDirectory = FileNameJoin[{repositoryRoot,
    "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
  classFormDirectory = FileNameJoin[{familyDataDirectory, "ClassForms"}];
  launchSealFile = FileNameJoin[{outdir,
    "CF303_resume_from_sector16_launch_seal_v1.wl"}];
  preflightTag = Unique["CF303ResumeSector16PreflightV1$"];

  expectedHashes = <|
    driver -> "001f0f9d25c15e4ec5228168328aa763266454e8437961dd6a6dea1e5e02c8b6",
    FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}] ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    FileNameJoin[{repositoryRoot, "FeynFacet", "FeynFacet.m"}] ->
      "95d9d65106efaf46b2824a7c39b19d18fe813a136eb1ed39803606d7cae6960e",
    FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
      "FamilyRowGauge.wl"}] ->
      "ebe728cf47d61b01552178a03001bf91297dcadd43a545b28ba83f9d00a71e1b",
    FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
      "FamilyRowGaugeResume.wl"}] ->
      "58ec23b60ac88434f14aa12f89e559feab7d752e28b229d67ad0be52f331833a",
    FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
      "FiniteFieldEpsForm.wl"}] ->
      "c6dce4f78bd90238b815885e3d622d23aee3cf799a484419ef07d15763e97091",
    FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
      "FiniteFieldStripSolve.wl"}] ->
      "c406216144d84fa10f0c794ef6ea079899919b6421acd2ca5f2e70043a0f4af1",
    FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
      "TransportCharts.wl"}] ->
      "2cd6cc63a94762c4546954881d5a16931e4ca1a6e7de716920882bad13d3efc9",
    FileNameJoin[{repositoryRoot, "FeynFacet", "Private",
      "MultiquadraticStripSolve.wl"}] ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stateFile ->
      "1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06",
    stripCheckpointFile ->
      "b5881e0ec284eecaea0d00b26d8e69a68cd4cea33f6ab363a61992bfe9d2c707"
  |>;
  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  fail[message_String] := (
    Print["CF303 RESUME PREFLIGHT FAILURE V1: " <> message];
    Throw[$Failed, preflightTag]);

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {},
      fail["wrapper takes no arguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0,
      fail["must run on a pool subkernel"]];
    If[Length[Kernels[]] =!= 0,
      fail["mission worker already owns nested kernels"]];
    If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 5),
      fail["mission helper ceiling must be exactly five"]];
    If[! DirectoryQ[outdir] || ! DirectoryQ[scratch] ||
        FileExistsQ[launchSealFile],
      fail["cloned resume tree is absent or launch seal already exists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["source/checkpoint hash mismatch: " <>
        ToString[badHashes, InputForm]]];

    environmentOverrides = <|
      "FACET_KERNEL_COUNT" -> "6",
      "FACET_TASK_BROKER_MAX_HELPERS" -> "5",
      "FACET_CHECK_LEVEL" -> "Production",
      "FACET_STRIP_ROUTE" -> "FiniteFieldFirst",
      "FACET_ZERO_FORCING" -> "True",
      "FACET_RECORD_STRIP_ONLY" -> "False",
      "FACET_RESUME_HYDRATION" -> "True",
      "FACET_MEMTRACE" -> FileNameJoin[{outdir,
        "memtrace_resume_v1.log"}]
    |>;
    driverArguments = {driver, "CF303", outdir, "1800",
      "identity_capture_xh_v4", "30", "", familyDataDirectory,
      classFormDirectory};
    launchSeal = <|
      "Status" -> "CF303ResumeFromSector16LaunchSealedV1",
      "Family" -> "CF303",
      "ResumeStateSector" -> 16,
      "PartialStripCheckpointSector" -> 17,
      "RecoveredLowerSectors" -> {16, 15, 14, 13},
      "StateFile" -> stateFile,
      "StateSHA256" -> expectedHashes[stateFile],
      "StripCheckpointFile" -> stripCheckpointFile,
      "StripCheckpointSHA256" -> expectedHashes[stripCheckpointFile],
      "CurrentSourceHashes" -> KeyDrop[expectedHashes,
        {stateFile, stripCheckpointFile}],
      "EnvironmentOverrides" -> environmentOverrides,
      "DriverArguments" -> driverArguments,
      "WorkerKernelID" -> $KernelID,
      "NestedKernelCountBeforeDriver" -> Length[Kernels[]],
      "TaskBrokerHelperCeiling" ->
        KernelPoolMission`$TaskBrokerMaxHelpers,
      "PackageSourceWillBeModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]
    |>;
    temporary = launchSealFile <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    If[Quiet[Check[Put[launchSeal, temporary];
          RenameFile[temporary, launchSealFile,
            OverwriteTarget -> False], $Failed]] === $Failed ||
        ! FileExistsQ[launchSealFile],
      fail["atomic launch seal write failed"]];

    Print["CF303 RESUME PREFLIGHT OK V1: exact cloned sector-16 state and " <>
      "sector-17 partial checkpoint; one mission worker plus at most five " <>
      "flat broker helpers; package source read-only"];
    SetEnvironment[Normal[environmentOverrides]];
    Unprotect[$ScriptCommandLine];
    $ScriptCommandLine = driverArguments;
    SetDirectory[repositoryRoot];
    Get[driver],
    preflightTag];
  result
]
