#!/usr/bin/env wolframscript

(* Strictly read-only target probe for the intended virgin worker.  It does
   not create the recapture outdir, load FACET, intern absent Global symbols,
   launch helpers, or alter a process.  The preflight package removes its own
   namespace and the inherited System lifecycle is exact-audited. *)

BeginPackage["CodexCF300Sector12RecaptureV4Probe`"];
Begin["`Private`"];

probeFinalResult = With[
  {bundleDirectory = DirectoryName[ExpandFileName[System`$InputFileName]],
   preflightName =
     "preflight_cf300_sector12_recapture_v4_global_state.wls",
   expectedPreflightHash =
     "91249cb30209f2a19ee5eb980889024b98694ed21744e9a81f1f49142a330ae5",
   expectedPathSealHash =
     "6f326c92c6f9948f0fcb4c10f8e1052da446ac4ea9a5baf3cc71d177f690e44e",
   expectedKernelID = 146,
   expectedOutdir =
     "/tmp/codex-triple-root-20260823c.vx654S/" <>
      "cf300_sector12_recapture_from_v4_xh_v4",
   privatePatterns = {
     "CodexCF300Sector12RecaptureV4Preflight`*",
     "CodexCF300Sector12RecaptureV4Preflight`Private`*"}},
  With[
    {preflightPath = FileNameJoin[{bundleDirectory, preflightName}],
     pathSealPath = FileNameJoin[{bundleDirectory,
       "cf300_sector12_recapture_v4_path_seal.json"}],
     globalNamesBefore = System`Names["Global`*"],
     contextBefore = System`$Context,
     contextPathBefore = System`$ContextPath,
     packagesBefore = System`$Packages,
     pathBefore = System`$Path,
     directoryBefore = System`Directory[],
     commandLineBefore = System`$ScriptCommandLine,
     preflightNamesBefore = Flatten[
       System`Names[#1] & /@ privatePatterns],
     preflightHash = Quiet[Check[
       If[System`FileExistsQ[FileNameJoin[{bundleDirectory, preflightName}]],
         IntegerString[System`FileHash[
           FileNameJoin[{bundleDirectory, preflightName}], "SHA256"],
           16, 64], Missing["NotFound"]], Missing["HashFailed"]]],
     pathSealHash = Quiet[Check[
       IntegerString[System`FileHash[FileNameJoin[{bundleDirectory,
         "cf300_sector12_recapture_v4_path_seal.json"}], "SHA256"],
         16, 64], Missing["HashFailed"]]],
     pathSeal = Quiet[Check[Import[FileNameJoin[{bundleDirectory,
       "cf300_sector12_recapture_v4_path_seal.json"}], "RawJSON"],
       $Failed]]},
    With[
      {envelope = If[TrueQ[
           System`$KernelID === expectedKernelID &&
           Length[System`Kernels[]] === 0 &&
           ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
           KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
           Length[Rest[System`$ScriptCommandLine]] === 0 &&
           preflightHash === expectedPreflightHash &&
           pathSealHash === expectedPathSealHash &&
           AssociationQ[pathSeal] &&
           TrueQ[Lookup[pathSeal, "GateQ", False]] &&
           Lookup[pathSeal, "RecordCount", None] === 21 &&
           preflightNamesBefore === {} &&
           ! System`FileExistsQ[expectedOutdir] &&
           ! System`DirectoryQ[expectedOutdir]],
         Internal`InheritedBlock[
           {System`$Context, System`$ContextPath, System`$Packages,
            System`$Path, System`$HistoryLength},
           Block[{System`$Context = "Global`",
             System`$ContextPath = {"System`"}},
             System`Get[preflightPath]]],
         <|"Status" -> "ProbePreflightRejected"|>]},
      With[
        {report = If[AssociationQ[envelope],
           Lookup[envelope, "Report", $Failed], $Failed],
         globalNamesAfter = System`Names["Global`*"],
         preflightNamesAfter = Flatten[
           System`Names[#1] & /@ privatePatterns]},
        With[
          {gateQ = TrueQ[
             AssociationQ[envelope] &&
             Lookup[envelope, "Status", None] ===
               "CF300Sector12RecaptureV4PreflightEnvelope" &&
             TrueQ[Lookup[envelope, "DedicatedNameCleanupQ", False]] &&
             AssociationQ[report] &&
             TrueQ[Lookup[report, "GateQ", False]] &&
             SameQ[globalNamesAfter, globalNamesBefore] &&
             preflightNamesAfter === {} &&
             SameQ[System`$Context, contextBefore] &&
             SameQ[System`$ContextPath, contextPathBefore] &&
             SameQ[System`$Packages, packagesBefore] &&
             SameQ[System`$Path, pathBefore] &&
             SameQ[System`Directory[], directoryBefore] &&
             SameQ[System`$ScriptCommandLine, commandLineBefore] &&
             ! System`FileExistsQ[expectedOutdir] &&
             ! System`DirectoryQ[expectedOutdir]]},
          Print["CF300 S12 RECAPTURE V4 K146 VIRGIN PROBE ",
            InputForm[<|
              "GateQ" -> gateQ,
              "ExpectedKernelID" -> expectedKernelID,
              "ActualKernelID" -> System`$KernelID,
              "NestedKernelCount" -> Length[System`Kernels[]],
              "HelperCeilingZeroQ" -> TrueQ[
                ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
                KernelPoolMission`$TaskBrokerMaxHelpers === 0],
              "PreflightSHA256" -> preflightHash,
              "PathSealSHA256" -> pathSealHash,
              "PathSealGateQ" -> If[AssociationQ[pathSeal],
                Lookup[pathSeal, "GateQ", False], False],
              "GlobalNamespaceReadOnlyQ" ->
                SameQ[globalNamesAfter, globalNamesBefore],
              "PreflightDedicatedCleanupQ" ->
                preflightNamesAfter === {},
              "OutputAbsentQ" ->
                ! System`FileExistsQ[expectedOutdir] &&
                ! System`DirectoryQ[expectedOutdir],
              "PreflightReport" -> report|>]];
          If[gateQ, 0, $Failed]]]]]];

With[
  {resolvedResult = probeFinalResult,
   resolvedNames = System`Join[
     System`Names["CodexCF300Sector12RecaptureV4Probe`*"],
     System`Names["CodexCF300Sector12RecaptureV4Probe`Private`*"]]},
  End[];
  EndPackage[];
  Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV4Probe`Private`*"]];
  Quiet[System`Remove["CodexCF300Sector12RecaptureV4Probe`*"]];
  With[{cleanupQ = System`Join[
      System`Names["CodexCF300Sector12RecaptureV4Probe`*"],
      System`Names[
        "CodexCF300Sector12RecaptureV4Probe`Private`*"]] === {}},
    Print["CF300 S12 RECAPTURE V4 PROBE CLEANUP ",
      InputForm[<|"CleanupQ" -> cleanupQ,
        "NamesBeforeCleanupCount" -> Length[resolvedNames]|>]];
    If[cleanupQ, resolvedResult, $Failed]]]
