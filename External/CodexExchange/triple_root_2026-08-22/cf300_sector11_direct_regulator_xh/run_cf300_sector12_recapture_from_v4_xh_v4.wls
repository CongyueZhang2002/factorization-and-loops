#!/usr/bin/env wolframscript

(* V4 launcher.  It performs a source-derived, read-only virgin-worker
   preflight before the body may create its output.  The package-loading body
   owns an in-evaluation cooperative quarantine.  If an Abort escapes after
   the package-load-attempt seal exists, this launcher restores its inherited
   System state, removes dedicated contexts, and holds the worker until the
   exact abort-release sentinel is supplied; only then is the Abort rethrown.
   No Return is used on the target's top-level evaluation path. *)

BeginPackage["CodexCF300Sector12RecaptureV4Launcher`"];
Begin["`Private`"];

launcherFinalResult = With[
  {bundleDirectory = DirectoryName[ExpandFileName[System`$InputFileName]],
   launcherPath = ExpandFileName[System`$InputFileName],
   repositoryRoot = "/home/maxzhang/factorization-and-loops",
   bodyName = "run_cf300_sector12_recapture_from_v4_xh_v4_body.wls",
   preflightName =
     "preflight_cf300_sector12_recapture_v4_global_state.wls",
   pathSealName = "cf300_sector12_recapture_v4_path_seal.json",
   pathInspectorName = "inspect_cf300_sector12_recapture_v4_paths.py",
   expectedBodyHash =
     "51f489e78ec5ea5f277b7b1c8b0ef18f2853d9d62795ce6a5327a2384caf9cc7",
   expectedPreflightHash =
     "91249cb30209f2a19ee5eb980889024b98694ed21744e9a81f1f49142a330ae5",
   expectedPathSealHash =
     "6f326c92c6f9948f0fcb4c10f8e1052da446ac4ea9a5baf3cc71d177f690e44e",
   expectedPathInspectorHash =
     "c6bfcee4603e5d2b0248a5dc8c02320f7a1d3fac3f4075e6f869d634caa6a0cd",
   expectedSourceManifestHash =
     "880c4f7850b2c0daf5c207e96df23113c91d75d1056e23c6edc169aec66487b2",
   expectedKernelPoolSourceHash =
     "0758f0f95a24b5dee4c6162939388ca5641610ef5e73bb73775a2030e8ff069d",
   expectedPoolRunDefinitionHash =
     "d49632694d4da9f47a7c3c0d9828e98d47f9a416c9cb72d8a10a74b9b011db51",
   expectedDriverHash =
     "6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1",
   expectedCensusHash =
     "990e086691cd0651823df256e019e6d7e32042b64951ded39f4f31ad8e16c377",
   expectedCensusInspectorHash =
     "89d27f01e6ab92bcf64fff60085f8c87115edab02d86b8ebf9691886735da6ae",
   expectedValidatorHash =
     "304e7748e3971e9b0bf50fc84b10f50cda8231d49d6df235327134a297c45759",
   expectedValidatorEvidenceHash =
     "185d009d9ed4a56037c3360a14862b97e8e39cfbe8e591c5d6bc38d936d45f3e",
   expectedFormalResultHash =
     "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128",
   expectedV4StateHash =
     "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009",
   expectedV4ReportHash =
     "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e",
   expectedOutdir =
     "/tmp/codex-triple-root-20260823c.vx654S/" <>
      "cf300_sector12_recapture_from_v4_xh_v4",
   bodyContextPatterns = {
     "CodexCF300Sector12RecaptureV4`*",
     "CodexCF300Sector12RecaptureV4`Private`*",
     "CodexCF300Sector12DriverV4`*",
     "CodexCF300Sector12RecaptureV4Preflight`*",
     "CodexCF300Sector12RecaptureV4Preflight`Private`*"},
   abortReleaseToken =
     "CF300-S12-V4-ABORT-RELEASE-7f4edb836dab4ce4a516e292c853d20f"},

  With[
    {bodyPath = FileNameJoin[{bundleDirectory, bodyName}],
     preflightPath = FileNameJoin[{bundleDirectory, preflightName}],
     pathSealPath = FileNameJoin[{bundleDirectory, pathSealName}],
     pathInspectorPath = FileNameJoin[{bundleDirectory, pathInspectorName}],
     sourceManifestPath = FileNameJoin[{bundleDirectory,
       "CF300_RESUME_SOURCE_SHA256SUMS"}],
     censusPath = FileNameJoin[{bundleDirectory,
       "family_sector_driver_global_census_v1.json"}],
     censusInspectorPath = FileNameJoin[{bundleDirectory,
       "inspect_family_sector_driver_global_census_v1.py"}],
     validatorPath = FileNameJoin[{bundleDirectory,
       "validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls"}],
     validatorEvidencePath = FileNameJoin[{bundleDirectory,
       "cf300_s11_postwrite_validator_xh_v2_OK.log"}],
     formalResultPath = FileNameJoin[{bundleDirectory,
       "cf300_sector11_postwrite_formal_inspector_v4_result.json"}],
     driverPath = FileNameJoin[{repositoryRoot, "Scripts",
       "family_epsform_sector.wls"}],
     kernelPoolSourcePath = FileNameJoin[{repositoryRoot, "Scripts",
       "KernelPool.wls"}],
     poolRunDefinitionPath =
       "/tmp/codex-triple-root-20260823c.vx654S/pool/" <>
        "poolrun_definition.m",
     v4StatePath = FileNameJoin[{repositoryRoot, "ppHX_NNLO_DoubleReal",
       "Results", "UU_08_10_canonical", "FamilyEpsFormsSolving",
       "triple_root_2026-08-23", "CF300_direct_regulator_v4_candidate",
       "sector_state_CF300_standard.wl"}],
     v4ReportPath = FileNameJoin[{repositoryRoot, "ppHX_NNLO_DoubleReal",
       "Results", "UU_08_10_canonical", "FamilyEpsFormsSolving",
       "triple_root_2026-08-23", "CF300_direct_regulator_v4_candidate",
       "cf300_sector11_direct_regulator_report_v4.wl"}],
     loadAttemptFile = FileNameJoin[{expectedOutdir,
       "CF300_package_load_attempted_v4.wl"}],
     abortReleaseFile = FileNameJoin[{expectedOutdir,
       "CF300_abort_quarantine_release_v4.txt"}],
     hashHex = Function[file,
       Quiet[Check[
         If[System`FileExistsQ[file],
           IntegerString[System`FileHash[file, "SHA256"], 16, 64],
           Missing["NotFound"]], Missing["HashFailed"]]]],
     globalStateByName = Function[name,
       System`ToExpression[name, InputForm,
         Function[heldSymbol,
           <|"OwnValues" -> System`OwnValues[heldSymbol],
             "DownValues" -> System`DownValues[heldSymbol],
             "UpValues" -> System`UpValues[heldSymbol],
             "SubValues" -> System`SubValues[heldSymbol],
             "NValues" -> System`NValues[heldSymbol],
             "DefaultValues" -> System`DefaultValues[heldSymbol],
             "FormatValues" -> System`FormatValues[heldSymbol],
             "Attributes" -> System`Attributes[heldSymbol]|>, HoldAll]]]},

    With[
      {launcherHashBefore = Quiet[Check[
         IntegerString[System`FileHash[launcherPath, "SHA256"], 16, 64],
         Missing["HashFailed"]]],
       bodyHashBefore = Quiet[Check[
         If[System`FileExistsQ[bodyPath],
           IntegerString[System`FileHash[bodyPath, "SHA256"], 16, 64],
           Missing["NotFound"]], Missing["HashFailed"]]],
       preflightHashBefore = Quiet[Check[
         If[System`FileExistsQ[preflightPath],
           IntegerString[System`FileHash[preflightPath, "SHA256"], 16, 64],
           Missing["NotFound"]], Missing["HashFailed"]]],
       pathSealHashBefore = Quiet[Check[
         If[System`FileExistsQ[pathSealPath],
           IntegerString[System`FileHash[pathSealPath, "SHA256"], 16, 64],
           Missing["NotFound"]], Missing["HashFailed"]]],
       pathInspectorHashBefore = Quiet[Check[
         If[System`FileExistsQ[pathInspectorPath],
           IntegerString[System`FileHash[pathInspectorPath, "SHA256"], 16, 64],
           Missing["NotFound"]], Missing["HashFailed"]]],
       pathSeal = Quiet[Check[Import[pathSealPath, "RawJSON"], $Failed]],
       dedicatedNamesBefore = Flatten[
         System`Names[#1] & /@ bodyContextPatterns],
       contextBefore = System`$Context,
       contextPathBefore = System`$ContextPath,
       packagesBefore = System`$Packages,
       pathBefore = System`$Path,
        directoryBefore = System`Directory[],
       commandLineBefore = System`$ScriptCommandLine,
       commandLineProtectedBeforeQ = MemberQ[
         System`Attributes[System`$ScriptCommandLine], Protected],
       environmentNames = {
         "FACET_KERNEL_COUNT", "FACET_TASK_BROKER_MAX_HELPERS",
         "FACET_CHECK_LEVEL", "FACET_STRIP_ROUTE",
         "FACET_ZERO_FORCING", "FACET_RECORD_STRIP_ONLY",
         "FACET_RESUME_HYDRATION", "FACET_MEMTRACE"},
       environmentBefore = AssociationThread[
         {"FACET_KERNEL_COUNT", "FACET_TASK_BROKER_MAX_HELPERS",
          "FACET_CHECK_LEVEL", "FACET_STRIP_ROUTE",
          "FACET_ZERO_FORCING", "FACET_RECORD_STRIP_ONLY",
          "FACET_RESUME_HYDRATION", "FACET_MEMTRACE"},
         Environment /@ {
          "FACET_KERNEL_COUNT", "FACET_TASK_BROKER_MAX_HELPERS",
          "FACET_CHECK_LEVEL", "FACET_STRIP_ROUTE",
          "FACET_ZERO_FORCING", "FACET_RECORD_STRIP_ONLY",
          "FACET_RESUME_HYDRATION", "FACET_MEMTRACE"}]},

      With[
        {preflightEnvelope = If[TrueQ[
             Length[Rest[System`$ScriptCommandLine]] === 0 &&
             IntegerQ[System`$KernelID] && System`$KernelID > 0 &&
             Length[System`Kernels[]] === 0 &&
             ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
             KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
              bodyHashBefore === expectedBodyHash &&
              preflightHashBefore === expectedPreflightHash &&
              pathSealHashBefore === expectedPathSealHash &&
              pathInspectorHashBefore === expectedPathInspectorHash &&
              hashHex[sourceManifestPath] === expectedSourceManifestHash &&
              hashHex[kernelPoolSourcePath] === expectedKernelPoolSourceHash &&
              hashHex[poolRunDefinitionPath] ===
                expectedPoolRunDefinitionHash &&
              hashHex[driverPath] === expectedDriverHash &&
              hashHex[censusPath] === expectedCensusHash &&
              hashHex[censusInspectorPath] ===
                expectedCensusInspectorHash &&
              hashHex[validatorPath] === expectedValidatorHash &&
              hashHex[validatorEvidencePath] ===
                expectedValidatorEvidenceHash &&
              hashHex[formalResultPath] === expectedFormalResultHash &&
              hashHex[v4StatePath] === expectedV4StateHash &&
              hashHex[v4ReportPath] === expectedV4ReportHash &&
              AssociationQ[pathSeal] &&
             Lookup[pathSeal, "Schema", None] ===
               "CF300Sector12RecaptureV4PathSealV1" &&
             TrueQ[Lookup[pathSeal, "GateQ", False]] &&
             Lookup[pathSeal, "RecordCount", None] === 21 &&
             AllTrue[Lookup[pathSeal, "Records", {$Failed}],
               AssociationQ[#1] && TrueQ[Lookup[#1, "GateQ", False]] &] &&
             ! System`FileExistsQ[expectedOutdir] &&
             ! System`DirectoryQ[expectedOutdir] &&
             dedicatedNamesBefore === {}],
           Internal`InheritedBlock[
             {System`$Context, System`$ContextPath, System`$Packages,
              System`$Path, System`$HistoryLength},
             Block[{System`$Context = "Global`",
               System`$ContextPath = {"System`"}},
                System`Get[preflightPath]]],
           <|"Status" -> "LauncherPreflightRejected",
             "DedicatedNamesBefore" -> dedicatedNamesBefore|>]},

        With[
          {preflightReport = If[AssociationQ[preflightEnvelope],
             Lookup[preflightEnvelope, "Report", $Failed], $Failed],
           globalNamesBefore = System`Names["Global`*"],
           globalStatesBefore = AssociationMap[globalStateByName,
             System`Names["Global`*"]]},
          Print["CF300 S12 RECAPTURE V4 VIRGIN PREFLIGHT ",
            InputForm[<|
              "WorkerKernelID" -> System`$KernelID,
              "NestedKernelCount" -> Length[System`Kernels[]],
              "LauncherSHA256Before" -> launcherHashBefore,
              "BodySHA256Before" -> bodyHashBefore,
              "PreflightSHA256Before" -> preflightHashBefore,
              "PathSealSHA256Before" -> pathSealHashBefore,
              "PathInspectorSHA256Before" -> pathInspectorHashBefore,
              "PathSealGateQ" -> If[AssociationQ[pathSeal],
                Lookup[pathSeal, "GateQ", False], False],
              "PreflightGateQ" -> If[AssociationQ[preflightReport],
                Lookup[preflightReport, "GateQ", False], False],
              "ExistingRelevantPackageNameCount" ->
                If[AssociationQ[preflightReport],
                  Lookup[preflightReport,
                    "ExistingRelevantPackageNameCount", Missing[]],
                  Missing[]],
              "DirtyDefinitionCount" -> If[AssociationQ[preflightReport],
                Lookup[preflightReport, "DirtyDefinitionCount",
                  Missing[]], Missing[]],
              "PackageShadowCount" -> If[AssociationQ[preflightReport],
                Lookup[preflightReport, "PackageShadowCount",
                  Missing[]], Missing[]],
              "PreflightDedicatedCleanupQ" ->
                If[AssociationQ[preflightEnvelope],
                  Lookup[preflightEnvelope, "DedicatedNameCleanupQ",
                    False], False]|>]];

          If[! TrueQ[
              AssociationQ[preflightEnvelope] &&
              Lookup[preflightEnvelope, "Status", None] ===
                "CF300Sector12RecaptureV4PreflightEnvelope" &&
              TrueQ[Lookup[preflightEnvelope,
                "DedicatedNameCleanupQ", False]] &&
              AssociationQ[preflightReport] &&
              TrueQ[Lookup[preflightReport, "GateQ", False]] &&
              SameQ[System`$Context, contextBefore] &&
              SameQ[System`$ContextPath, contextPathBefore] &&
              SameQ[System`$Packages, packagesBefore] &&
              SameQ[System`$Path, pathBefore] &&
              SameQ[System`Directory[], directoryBefore] &&
              SameQ[System`$ScriptCommandLine, commandLineBefore] &&
              SameQ[AssociationThread[environmentNames,
                Environment /@ environmentNames], environmentBefore] &&
              AssociationQ[globalStatesBefore] &&
              FreeQ[Values[globalStatesBefore], $Failed] &&
              Flatten[System`Names[#1] & /@ bodyContextPatterns] === {}],
            Print["CF300 S12 RECAPTURE V4 LAUNCHER FAIL: " <>
              "read-only virgin-worker preflight rejected; no output written"];
            $Failed,

            With[
              {bodyEnvelope = CheckAbort[
                 Internal`InheritedBlock[
                   {System`$Context, System`$ContextPath,
                    System`$Packages, System`$Path,
                    System`$HistoryLength},
                   First[{
                      (Quiet[System`Unprotect[System`$ScriptCommandLine]];
                      System`$ScriptCommandLine = Append[
                        commandLineBefore,
                        ExportString[globalNamesBefore, "RawJSON",
                          "Compact" -> True]];
                      If[TrueQ[commandLineProtectedBeforeQ],
                        System`Protect[System`$ScriptCommandLine],
                        System`Unprotect[System`$ScriptCommandLine]];
                      System`Get[bodyPath]),
                     (Quiet[System`Unprotect[System`$ScriptCommandLine]];
                      System`$ScriptCommandLine = commandLineBefore;
                      If[TrueQ[commandLineProtectedBeforeQ],
                        System`Protect[System`$ScriptCommandLine],
                        System`Unprotect[System`$ScriptCommandLine]];
                      Null)}]],
                 (KeyValueMap[
                    Function[{name, value},
                      If[StringQ[value], SetEnvironment[name -> value],
                        UnsetEnvironment[name]]], environmentBefore];
                   Quiet[System`Unprotect[System`$ScriptCommandLine]];
                  System`$ScriptCommandLine = commandLineBefore;
                  If[TrueQ[commandLineProtectedBeforeQ],
                     System`Protect[System`$ScriptCommandLine],
                     System`Unprotect[System`$ScriptCommandLine]];
                  Quiet[Check[SetDirectory[directoryBefore], Null]];
                   Scan[Function[pattern,
                     With[{heldPattern = pattern},
                       Quiet[System`Remove[heldPattern]]]],
                     bodyContextPatterns];
                   With[{ownedGlobalNames = Complement[
                       System`Names["Global`*"], globalNamesBefore]},
                     If[! AnyTrue[ownedGlobalNames,
                         Function[name,
                           MemberQ[System`ToExpression[name, InputForm,
                             Function[heldSymbol,
                               System`Attributes[heldSymbol], HoldAll]], Locked]]],
                       Scan[Function[name,
                         With[{literalName = name},
                           Quiet[System`Unprotect[literalName]];
                           Quiet[System`ClearAll[literalName]];
                           Quiet[System`Remove[literalName]]]],
                         ownedGlobalNames]]];
                   If[System`FileExistsQ[loadAttemptFile],
                     Print["CF300 S12 RECAPTURE V4 ABORT QUARANTINE: " <>
                       "package load was attempted; holding worker until " <>
                       abortReleaseFile];
                     With[
                       {abortLoadHash = hashHex[loadAttemptFile],
                        abortResultPath = FileNameJoin[{expectedOutdir,
                          "CF300_sector12_recapture_result_v4.wl"}],
                        abortStripPath = FileNameJoin[{expectedOutdir,
                          "sector_CF300_standard",
                          "CF300_12_11_input.wl"}],
                        abortStatePath = FileNameJoin[{expectedOutdir,
                          "sector_state_CF300_standard.wl"}],
                        abortInventory = Sort[DeleteCases[
                          System`FileNames["*", expectedOutdir],
                          abortReleaseFile]]},
                       With[
                         {abortResultHash = hashHex[abortResultPath]},
                         While[True,
                           With[
                             {abortIntegrityQ = TrueQ[
                                ValueQ[
                                  KernelPoolMission`$TaskBrokerMaxHelpers] &&
                                KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
                                Length[System`Kernels[]] === 0 &&
                                hashHex[launcherPath] === launcherHashBefore &&
                                hashHex[bodyPath] === expectedBodyHash &&
                                 hashHex[preflightPath] ===
                                   expectedPreflightHash &&
                                 hashHex[pathSealPath] ===
                                   expectedPathSealHash &&
                                 hashHex[pathInspectorPath] ===
                                   expectedPathInspectorHash &&
                                 hashHex[sourceManifestPath] ===
                                   expectedSourceManifestHash &&
                                 hashHex[kernelPoolSourcePath] ===
                                   expectedKernelPoolSourceHash &&
                                 hashHex[poolRunDefinitionPath] ===
                                   expectedPoolRunDefinitionHash &&
                                 hashHex[driverPath] === expectedDriverHash &&
                                 hashHex[censusPath] === expectedCensusHash &&
                                 hashHex[censusInspectorPath] ===
                                   expectedCensusInspectorHash &&
                                 hashHex[validatorPath] ===
                                   expectedValidatorHash &&
                                 hashHex[validatorEvidencePath] ===
                                   expectedValidatorEvidenceHash &&
                                 hashHex[formalResultPath] ===
                                   expectedFormalResultHash &&
                                 hashHex[v4StatePath] ===
                                   expectedV4StateHash &&
                                 hashHex[v4ReportPath] ===
                                   expectedV4ReportHash &&
                                 hashHex[loadAttemptFile] === abortLoadHash &&
                                hashHex[abortResultPath] === abortResultHash &&
                                hashHex[abortStatePath] ===
                                  "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009" &&
                                hashHex[abortStripPath] ===
                                  "f26c4cc36456a0a60de789efad0439644d48fa74eb6950aaeafd8c610b43a976" &&
                                 SameQ[System`Names["Global`*"],
                                   globalNamesBefore] &&
                                 SameQ[AssociationMap[globalStateByName,
                                   globalNamesBefore], globalStatesBefore] &&
                                 SameQ[AssociationThread[environmentNames,
                                  Environment /@ environmentNames],
                                  environmentBefore] &&
                                SameQ[System`$ScriptCommandLine,
                                  commandLineBefore] &&
                                SameQ[System`Directory[], directoryBefore] &&
                                System`FileNames["*.tmp*", expectedOutdir,
                                  Infinity] === {} &&
                                Sort[System`FileNames["*", expectedOutdir]] ===
                                  If[System`FileExistsQ[abortReleaseFile],
                                    Sort[Append[abortInventory,
                                      abortReleaseFile]], abortInventory]],
                              abortReleaseText = Quiet[Check[
                                If[System`FileExistsQ[abortReleaseFile],
                                  Import[abortReleaseFile, "Text"],
                                  Missing["Absent"]],
                                Missing["Unreadable"]]]},
                             If[abortIntegrityQ &&
                                 StringQ[abortReleaseText] &&
                                 StringTrim[abortReleaseText] ===
                                   abortReleaseToken,
                               Print["CF300 S12 RECAPTURE V4 ABORT " <>
                                 "RELEASE ACK integrity=true"];
                               Break[]];
                             Print["CF300 S12 RECAPTURE V4 ABORT HEARTBEAT ",
                               InputForm[<|
                                 "WorkerKernelID" -> System`$KernelID,
                                 "IntegrityQ" -> abortIntegrityQ,
                                 "LoadAttemptSealSHA256" ->
                                   hashHex[loadAttemptFile],
                                 "BodySHA256" -> hashHex[bodyPath],
                                 "LauncherSHA256" -> hashHex[launcherPath],
                                 "ReleaseSentinelPresentQ" ->
                                   System`FileExistsQ[abortReleaseFile]|>]];
                             Pause[30]]]]]];
                   Abort[])]},

              With[
                {launcherHashAfter = hashHex[launcherPath],
                 bodyHashAfter = hashHex[bodyPath],
                 preflightHashAfter = hashHex[preflightPath],
                 pathSealHashAfter = hashHex[pathSealPath],
                 pathInspectorHashAfter = hashHex[pathInspectorPath],
                 dedicatedNamesAfter = Flatten[
                   System`Names[#1] & /@ bodyContextPatterns]},
                With[
                  {postLifecycleGateQ = TrueQ[
                     AssociationQ[bodyEnvelope] &&
                     Lookup[bodyEnvelope, "Status", None] ===
                       "CF300Sector12RecaptureV4BodyEnvelope" &&
                     TrueQ[Lookup[bodyEnvelope,
                       "DedicatedNameCleanupQ", False]] &&
                     launcherHashAfter === launcherHashBefore &&
                     bodyHashAfter === bodyHashBefore &&
                     preflightHashAfter === preflightHashBefore &&
                     pathSealHashAfter === pathSealHashBefore &&
                     pathInspectorHashAfter === pathInspectorHashBefore &&
                     dedicatedNamesAfter === {} &&
                     SameQ[System`$Context, contextBefore] &&
                     SameQ[System`$ContextPath, contextPathBefore] &&
                     SameQ[System`$Packages, packagesBefore] &&
                     SameQ[System`$Path, pathBefore] &&
                      SameQ[System`Directory[], directoryBefore] &&
                     SameQ[System`$ScriptCommandLine,
                       commandLineBefore] &&
                     SameQ[AssociationThread[environmentNames,
                       Environment /@ environmentNames],
                       environmentBefore]]},
                  Print["CF300 S12 RECAPTURE V4 POST-RELEASE LIFECYCLE ",
                    InputForm[<|
                      "GateQ" -> postLifecycleGateQ,
                      "LauncherSHA256After" -> launcherHashAfter,
                      "BodySHA256After" -> bodyHashAfter,
                      "PreflightSHA256After" -> preflightHashAfter,
                      "PathSealSHA256After" -> pathSealHashAfter,
                      "PathInspectorSHA256After" -> pathInspectorHashAfter,
                      "DedicatedNamesAfter" -> dedicatedNamesAfter,
                      "BodyEnvelope" -> bodyEnvelope|>]];
                  If[postLifecycleGateQ,
                    Lookup[bodyEnvelope, "BodyResult", $Failed],
                    $Failed]]]]]]]]]];

With[
  {resolvedResult = launcherFinalResult,
   resolvedLauncherNames = System`Join[
     System`Names["CodexCF300Sector12RecaptureV4Launcher`*"],
     System`Names[
       "CodexCF300Sector12RecaptureV4Launcher`Private`*"]]},
  End[];
  EndPackage[];
  Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV4Launcher`Private`*"]];
  Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV4Launcher`*"]];
  With[{cleanupQ = System`Join[
      System`Names["CodexCF300Sector12RecaptureV4Launcher`*"],
      System`Names[
        "CodexCF300Sector12RecaptureV4Launcher`Private`*"]] === {}},
    Print["CF300 S12 RECAPTURE V4 LAUNCHER CLEANUP ",
      InputForm[<|"CleanupQ" -> cleanupQ,
        "NamesBeforeCleanupCount" -> Length[resolvedLauncherNames]|>]];
    If[cleanupQ, resolvedResult, $Failed]]]
