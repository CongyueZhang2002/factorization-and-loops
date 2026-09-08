#!/usr/bin/env wolframscript

(* V5b recovered-K146-only launcher.  It performs a source-derived, read-only dirty-worker
   preflight and requires the full relevant-package definition fingerprint
   printed by the immediately preceding no-write probe before the body may
   create its output.  The package-loading body
   owns an in-evaluation cooperative quarantine.  If an Abort escapes after
   the package-load-attempt seal exists, this launcher restores its inherited
   System state, removes dedicated contexts, and holds the worker until the
   exact abort-release sentinel is supplied; only then is the Abort rethrown.
   No Return is used on the target's top-level evaluation path. *)

(* This first expression is parsed before BeginPackage and therefore uses only
   fully qualified System symbols.  It binds production to the exact recovered
   lifecycle fingerprint emitted by the immediately preceding V5b probe. *)
System`SetAttributes[
  CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`definitionFreeHeld,
  System`HoldAll];
CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`definitionFreeHeld[
    CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol_] :=
  System`TrueQ[
    System`OwnValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`DownValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`UpValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`SubValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`NValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`DefaultValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`FormatValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`Attributes[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`Messages[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol] === {} &&
    System`Options[System`Unevaluated[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`symbol]] === {}];
CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`definitionFreeByName[
    CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`name_System`String] :=
  System`ToExpression[
    CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`name,
    System`InputForm,
    System`Function[
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`heldSymbol,
      CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`definitionFreeHeld[
        CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`heldSymbol],
      System`HoldAll]];

System`If[! System`TrueQ[
    System`Length[System`Rest[System`$ScriptCommandLine]] === 2 &&
    System`StringMatchQ[
      System`First[System`Rest[System`$ScriptCommandLine]],
      System`Repeated[System`HexadecimalCharacter, {64}]] &&
    System`StringMatchQ[
      System`Last[System`Rest[System`$ScriptCommandLine]],
      System`Repeated[System`HexadecimalCharacter, {64}]] &&
    System`$KernelID === 146 &&
    System`Length[System`Kernels[]] === 0 &&
    System`ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
    KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
    System`$Context === "Global`" &&
    System`ListQ[System`$ContextPath] &&
    System`DuplicateFreeQ[System`$ContextPath] &&
    System`MemberQ[System`$ContextPath, "System`"] &&
    System`MemberQ[System`$ContextPath, "Global`"] &&
    System`ListQ[System`$Packages] &&
    System`First[System`$Packages] ===
      "CodexCF300Sector12RecaptureV4Probe`" &&
    System`FreeQ[System`$Packages,
      "CodexDefinitionReaderHoldDiagnosticK146XH`" |
      "CodexCF300Sector12RecaptureV5DirtyK146Probe`" |
      "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`"] &&
    System`Join[
      System`Names[
        "CodexDefinitionReaderHoldDiagnosticK146XH`*"],
      System`Names[
        "CodexDefinitionReaderHoldDiagnosticK146XH`Private`*"],
      System`Names[
        "CodexCF300Sector12RecaptureV5DirtyK146Probe`*"],
      System`Names[
        "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"],
      System`Names[
        "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`*"],
      System`Names[
        "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`Private`*"]] ===
      {} &&
    System`MemberQ[
      {{},
       {"CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineCommandLine",
        "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineContext",
        "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineContextPath",
        "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineDirectory",
        "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselinePackages",
        "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselinePath",
        "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredLifecycleFingerprint"}},
      System`Sort[System`Names[
        "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`*"]]] &&
    System`Names[
      "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`Private`*"] ===
      {} &&
    System`AllTrue[
      System`Names[
        "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`*"],
      System`Function[
        CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`name,
        CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`definitionFreeByName[
          CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`name]]] &&
    ! System`FileExistsQ[
      "/tmp/codex-triple-root-20260823c.vx654S/" <>
       "cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146"] &&
    ! System`DirectoryQ[
      "/tmp/codex-triple-root-20260823c.vx654S/" <>
       "cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146"] &&
    System`IntegerString[
      System`Hash[
        System`ToString[System`InputForm[System`Association[
          "Context" -> System`$Context,
          "ContextPath" -> System`$ContextPath,
          "Packages" -> System`$Packages,
          "Path" -> System`$Path,
          "Directory" -> System`Directory[]]]],
        "SHA256"], 16, 64] ===
      System`Last[System`Rest[System`$ScriptCommandLine]]],
  System`Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`*"]];
  System`Abort[]];

CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineContext =
  System`$Context;
CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineContextPath =
  System`$ContextPath;
CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselinePackages =
  System`$Packages;
CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselinePath =
  System`$Path;
CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineDirectory =
  System`Directory[];
CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineCommandLine =
  System`$ScriptCommandLine;
CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredLifecycleFingerprint =
  System`Last[System`Rest[System`$ScriptCommandLine]];
System`Quiet[System`Remove[
  "CodexCF300Sector12RecaptureV5bRecoveredK146LauncherGuard`*"]];

BeginPackage["CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`"];
Begin["`Private`"];

launcherFinalResult = CheckAbort[
  With[
  {bundleDirectory = DirectoryName[ExpandFileName[System`$InputFileName]],
   launcherPath = ExpandFileName[System`$InputFileName],
   repositoryRoot = "/home/maxzhang/factorization-and-loops",
   bodyName = "run_cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146_body.wls",
   preflightName =
     "preflight_cf300_sector12_recapture_v5b_recovered_k146_global_state.wls",
   pathSealName = "cf300_sector12_recapture_v5b_recovered_k146_path_seal.json",
   pathInspectorName = "inspect_cf300_sector12_recapture_v5b_recovered_k146_paths.py",
   expectedBodyHash =
     "87b3e2aebbf9f969e3cf9ae4bd02d3c81f1a3df597003098233e4f260bd55a7e",
   expectedPreflightHash =
     "02bfc26610fe7300a470dc702ceaab88aac854496c1e5107af758657271a589f",
   expectedPathSealHash =
     "e6acf90517f2dd6c0ffd997ee2b777ddca1d8fe58414102111d0f24a1b9ee70b",
   expectedPathInspectorHash =
     "2d2310e959ff6ab3f6bd28c68938da990de74b8c0e437267d580c4586353898c",
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
      "cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146",
   bodyContextPatterns = {
     "CodexCF300Sector12RecaptureV5bRecoveredK146`*",
     "CodexCF300Sector12RecaptureV5bRecoveredK146`Private`*",
     "CodexCF300Sector12DriverV5bRecoveredK146`*",
     "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`*",
     "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`Private`*"},
   expectedPackageFingerprint = If[
     Length[Rest[System`$ScriptCommandLine]] === 2,
     First[Rest[System`$ScriptCommandLine]], $Failed],
   expectedLifecycleFingerprint = If[
     Length[Rest[System`$ScriptCommandLine]] === 2,
     Last[Rest[System`$ScriptCommandLine]], $Failed],
   abortReleaseToken =
     "CF300-S12-V5B-RECOVERED-K146-ABORT-RELEASE-844aa732c3b24e3693ff463beb74089e"},

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
       "CF300_package_load_attempted_v5b_recovered_k146.wl"}],
     abortReleaseFile = FileNameJoin[{expectedOutdir,
       "CF300_abort_quarantine_release_v5b_recovered_k146.txt"}],
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
             "Attributes" -> System`Attributes[heldSymbol],
             "Messages" -> System`Messages[heldSymbol],
             "Options" -> System`Options[System`Unevaluated[heldSymbol]]|>, HoldAll]]]},

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
             Length[Rest[System`$ScriptCommandLine]] === 2 &&
             StringQ[expectedPackageFingerprint] &&
             StringMatchQ[expectedPackageFingerprint,
               Repeated[HexadecimalCharacter, {64}]] &&
             StringQ[expectedLifecycleFingerprint] &&
             StringMatchQ[expectedLifecycleFingerprint,
               Repeated[HexadecimalCharacter, {64}]] &&
             expectedLifecycleFingerprint ===
               CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredLifecycleFingerprint &&
             packagesBefore === Prepend[
               CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselinePackages,
               "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`"] &&
             System`$KernelID === 146 &&
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
               "CF300Sector12RecaptureV5bRecoveredK146PathSealV1" &&
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
          Print["CF300 S12 RECAPTURE V5B RECOVERED K146 VIRGIN PREFLIGHT ",
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
              "ExpectedPackageDefinitionFingerprintSHA256" ->
                expectedPackageFingerprint,
              "ExpectedRecoveredLifecycleFingerprintSHA256" ->
                expectedLifecycleFingerprint,
              "ObservedPackageDefinitionFingerprintSHA256" ->
                If[AssociationQ[preflightReport], Lookup[preflightReport,
                  "PackageDefinitionFingerprintSHA256", Missing[]], Missing[]],
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
                "CF300Sector12RecaptureV5bRecoveredK146PreflightEnvelope" &&
              TrueQ[Lookup[preflightEnvelope,
                "DedicatedNameCleanupQ", False]] &&
              AssociationQ[preflightReport] &&
              TrueQ[Lookup[preflightReport, "GateQ", False]] &&
              Lookup[preflightReport,
                "PackageDefinitionFingerprintSHA256", None] ===
                  expectedPackageFingerprint &&
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
            Print["CF300 S12 RECAPTURE V5B RECOVERED K146 LAUNCHER FAIL: " <>
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
                     Print["CF300 S12 RECAPTURE V5B RECOVERED K146 ABORT QUARANTINE: " <>
                       "package load was attempted; holding worker until " <>
                       abortReleaseFile];
                     With[
                       {abortLoadHash = hashHex[loadAttemptFile],
                        abortResultPath = FileNameJoin[{expectedOutdir,
                          "CF300_sector12_recapture_result_v5b_recovered_k146.wl"}],
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
                               Print["CF300 S12 RECAPTURE V5B RECOVERED K146 ABORT " <>
                                 "RELEASE ACK integrity=true"];
                               Break[]];
                             Print["CF300 S12 RECAPTURE V5B RECOVERED K146 ABORT HEARTBEAT ",
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
                       "CF300Sector12RecaptureV5bRecoveredK146BodyEnvelope" &&
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
                  Print["CF300 S12 RECAPTURE V5B RECOVERED K146 POST-RELEASE LIFECYCLE ",
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
                    $Failed]]]]]]]]]],
  $Aborted];

With[
  {resolvedResult = launcherFinalResult,
   resolvedBaselineContext =
     CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineContext,
   resolvedBaselineContextPath =
     CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineContextPath,
   resolvedBaselinePackages =
     CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselinePackages,
   resolvedBaselinePath =
     CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselinePath,
   resolvedBaselineDirectory =
     CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineDirectory,
   resolvedBaselineCommandLine =
     CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`$RecoveredBaselineCommandLine,
   resolvedLauncherNames = System`Join[
     System`Names["CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`*"],
     System`Names[
       "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`Private`*"]]},
  End[];
  EndPackage[];
  With[
    {packageEnvelopeQ = TrueQ[
       System`$Context === resolvedBaselineContext &&
       System`$ContextPath === resolvedBaselineContextPath &&
       System`$Packages === Prepend[resolvedBaselinePackages,
         "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`"] &&
       System`$Path === resolvedBaselinePath &&
       System`Directory[] === resolvedBaselineDirectory &&
       System`$ScriptCommandLine === resolvedBaselineCommandLine]},
    If[packageEnvelopeQ,
      System`$Packages = resolvedBaselinePackages];
    Quiet[System`Remove[
      "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`Private`*"]];
    Quiet[System`Remove[
      "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`*"]];
    With[{cleanupQ = TrueQ[
        packageEnvelopeQ &&
        System`Join[
          System`Names[
            "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`*"],
          System`Names[
            "CodexCF300Sector12RecaptureV5bRecoveredK146Launcher`Private`*"]] ===
          {} &&
        System`$Context === resolvedBaselineContext &&
        System`$ContextPath === resolvedBaselineContextPath &&
        System`$Packages === resolvedBaselinePackages &&
        System`$Path === resolvedBaselinePath &&
        System`Directory[] === resolvedBaselineDirectory &&
        System`$ScriptCommandLine === resolvedBaselineCommandLine]},
      Print["CF300 S12 RECAPTURE V5B RECOVERED K146 LAUNCHER CLEANUP ",
        InputForm[<|"CleanupQ" -> cleanupQ,
          "PackageEnvelopeQ" -> packageEnvelopeQ,
          "NamesBeforeCleanupCount" -> Length[resolvedLauncherNames]|>]];
      If[cleanupQ, resolvedResult, $Failed]]]]
