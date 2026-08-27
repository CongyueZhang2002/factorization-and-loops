#!/usr/bin/env wolframscript

(* Strictly read-only target probe for the intended dirty K146 worker.  It does
   not create the recapture outdir, load FACET, intern absent Global symbols,
   launch helpers, or alter a process.  The preflight package removes its own
   namespace and the inherited System lifecycle is exact-audited. *)

BeginPackage["CodexCF300Sector12RecaptureV5DirtyK146Probe`"];
Begin["`Private`"];

probeFinalResult = With[
  {bundleDirectory = DirectoryName[ExpandFileName[System`$InputFileName]],
   preflightName =
     "preflight_cf300_sector12_recapture_v5_dirty_k146_global_state.wls",
   expectedPreflightHash =
     "4065f4ad5c7315a71ae37e41732862bb9395bb17eb91ba9d0c2084053c1a5a23",
   expectedPathSealHash =
     "86aa2c45b42fa4e424016fb40ebb8e34f91c937b59c5bd564c5b00eaf5b8b693",
   expectedKernelID = 146,
   expectedOutdir =
     "/tmp/codex-triple-root-20260823c.vx654S/" <>
      "cf300_sector12_recapture_from_v4_xh_v5_dirty_k146",
   privatePatterns = {
     "CodexCF300Sector12RecaptureV5DirtyK146Preflight`*",
     "CodexCF300Sector12RecaptureV5DirtyK146Preflight`Private`*"}},
  With[
    {preflightPath = FileNameJoin[{bundleDirectory, preflightName}],
     pathSealPath = FileNameJoin[{bundleDirectory,
       "cf300_sector12_recapture_v5_dirty_k146_path_seal.json"}],
     globalNamesBefore = System`Names["Global`*"],
     globalStatesBefore = AssociationMap[
       Function[name, System`ToExpression[name, InputForm,
         Function[heldSymbol, <|
           "OwnValues" -> System`OwnValues[heldSymbol],
           "DownValues" -> System`DownValues[heldSymbol],
           "UpValues" -> System`UpValues[heldSymbol],
           "SubValues" -> System`SubValues[heldSymbol],
           "NValues" -> System`NValues[heldSymbol],
           "DefaultValues" -> System`DefaultValues[heldSymbol],
           "FormatValues" -> System`FormatValues[heldSymbol],
           "Attributes" -> System`Attributes[heldSymbol],
           "Messages" -> System`Messages[heldSymbol],
           "Options" -> System`Options[heldSymbol]|>, HoldAll]]],
       System`Names["Global`*"]],
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
         "cf300_sector12_recapture_v5_dirty_k146_path_seal.json"}], "SHA256"],
         16, 64], Missing["HashFailed"]]],
     pathSeal = Quiet[Check[Import[FileNameJoin[{bundleDirectory,
       "cf300_sector12_recapture_v5_dirty_k146_path_seal.json"}], "RawJSON"],
       $Failed]]},
    With[
      {envelope = If[TrueQ[
           System`$KernelID === expectedKernelID &&
           Length[System`Kernels[]] === 0 &&
           ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
           KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
           ListQ[System`$Output] && Length[System`$Output] >= 1 &&
           System`Head[System`First[System`$Output]] === System`OutputStream &&
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
         globalStatesAfter = AssociationMap[
           Function[name, System`ToExpression[name, InputForm,
             Function[heldSymbol, <|
               "OwnValues" -> System`OwnValues[heldSymbol],
               "DownValues" -> System`DownValues[heldSymbol],
               "UpValues" -> System`UpValues[heldSymbol],
               "SubValues" -> System`SubValues[heldSymbol],
               "NValues" -> System`NValues[heldSymbol],
               "DefaultValues" -> System`DefaultValues[heldSymbol],
               "FormatValues" -> System`FormatValues[heldSymbol],
               "Attributes" -> System`Attributes[heldSymbol],
               "Messages" -> System`Messages[heldSymbol],
               "Options" -> System`Options[heldSymbol]|>, HoldAll]]],
           System`Names["Global`*"]],
         preflightNamesAfter = Flatten[
           System`Names[#1] & /@ privatePatterns]},
        With[
          {gateQ = TrueQ[
             AssociationQ[envelope] &&
             Lookup[envelope, "Status", None] ===
               "CF300Sector12RecaptureV5DirtyK146PreflightEnvelope" &&
             TrueQ[Lookup[envelope, "DedicatedNameCleanupQ", False]] &&
             AssociationQ[report] &&
             TrueQ[Lookup[report, "GateQ", False]] &&
             Lookup[report, "FeynCalcVersion", None] === "10.2.1" &&
             Lookup[report, "FeynArtsVersion", None] ===
               "FeynArts 3.12 (27 Mar 2025)" &&
             Lookup[report, "ExistingRelevantPackageNameCount", None] ===
               1685 &&
             Lookup[report, "UnsafeDirtyDefinitionNames", {$Failed}] === {} &&
             Lookup[report, "UnsafePackageShadowNames", {$Failed}] === {} &&
             TrueQ[Lookup[report,
               "PackageDefinitionFingerprintStableQ", False]] &&
             StringMatchQ[Lookup[report,
               "PackageDefinitionFingerprintSHA256", ""],
               Repeated[HexadecimalCharacter, {64}]] &&
             SameQ[globalNamesAfter, globalNamesBefore] &&
             SameQ[globalStatesAfter, globalStatesBefore] &&
             preflightNamesAfter === {} &&
             SameQ[System`$Context, contextBefore] &&
             SameQ[System`$ContextPath, contextPathBefore] &&
             SameQ[System`$Packages, packagesBefore] &&
             SameQ[System`$Path, pathBefore] &&
             SameQ[System`Directory[], directoryBefore] &&
             SameQ[System`$ScriptCommandLine, commandLineBefore] &&
             ! System`FileExistsQ[expectedOutdir] &&
             ! System`DirectoryQ[expectedOutdir]]},
          Print["CF300 S12 RECAPTURE V5 DIRTY K146 NO-WRITE PROBE ",
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
              "GlobalDefinitionsReadOnlyQ" ->
                SameQ[globalStatesAfter, globalStatesBefore],
              "PackageDefinitionFingerprintSHA256" ->
                If[AssociationQ[report], Lookup[report,
                  "PackageDefinitionFingerprintSHA256", Missing[]], Missing[]],
              "FeynCalcVersion" -> If[AssociationQ[report],
                Lookup[report, "FeynCalcVersion", Missing[]], Missing[]],
              "FeynArtsVersion" -> If[AssociationQ[report],
                Lookup[report, "FeynArtsVersion", Missing[]], Missing[]],
              "PreflightDedicatedCleanupQ" ->
                preflightNamesAfter === {},
              "OutputAbsentQ" ->
                ! System`FileExistsQ[expectedOutdir] &&
                ! System`DirectoryQ[expectedOutdir],
              "PreflightReport" -> report|>]];
          If[gateQ,
            System`WriteString[System`First[System`$Output],
              "CF300_V5_DIRTY_K146_PACKAGE_FINGERPRINT_SHA256=" <>
                Lookup[report, "PackageDefinitionFingerprintSHA256", ""],
              "\n"];
            0,
            $Failed]]]]]];

With[
  {resolvedResult = probeFinalResult,
   resolvedNames = System`Join[
     System`Names["CodexCF300Sector12RecaptureV5DirtyK146Probe`*"],
     System`Names["CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"]]},
  End[];
  EndPackage[];
  Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"]];
  Quiet[System`Remove["CodexCF300Sector12RecaptureV5DirtyK146Probe`*"]];
  With[{cleanupQ = System`Join[
      System`Names["CodexCF300Sector12RecaptureV5DirtyK146Probe`*"],
      System`Names[
        "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"]] === {}},
    Print["CF300 S12 RECAPTURE V5 DIRTY K146 PROBE CLEANUP ",
      InputForm[<|"CleanupQ" -> cleanupQ,
        "NamesBeforeCleanupCount" -> Length[resolvedNames]|>]];
    If[cleanupQ, resolvedResult, $Failed]]]
