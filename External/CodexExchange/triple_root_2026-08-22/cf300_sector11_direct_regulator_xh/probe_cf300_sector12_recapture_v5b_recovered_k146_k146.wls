#!/usr/bin/env wolframscript

(* V5b K146 recovery/no-write probe.  The first phase is intentionally
   outside BeginPackage: K146 is pinned in two aborted Begin/BeginPackage
   frames.  It exact-gates the frozen evidence, lifecycle prefix, and leaked
   name censuses; only then does it unwind those two frames in LIFO order,
   remove only the two Codex-owned leaked contexts/package entries, and prove
   that Global and the relevant loaded package definitions are unchanged.
   Every Options read receives Unevaluated[symbol], preserving the Options
   table while preventing evaluation of FeynArts' aborting sentinel ownvalue.
   No file, directory, helper kernel, native process, or user process is
   created, changed, signalled, or stopped. *)

System`SetAttributes[
  CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateHeld,
  System`HoldAll];
CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateHeld[
    CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol_] :=
  System`Association[
    "OwnValues" -> System`OwnValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "DownValues" -> System`DownValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "UpValues" -> System`UpValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "SubValues" -> System`SubValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "NValues" -> System`NValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "DefaultValues" -> System`DefaultValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "FormatValues" -> System`FormatValues[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "Attributes" -> System`Attributes[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "Messages" -> System`Messages[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol],
    "Options" -> System`Options[System`Unevaluated[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbol]]];

CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateByName[
    CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`name_System`String] :=
  System`ToExpression[
    CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`name,
    System`InputForm,
    System`Function[
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`heldSymbol,
      CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateHeld[
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`heldSymbol],
      System`HoldAll]];

CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
    CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`pattern_System`String] :=
  Internal`InheritedBlock[{System`$Context, System`$ContextPath},
    System`Block[
      {System`$Context =
        "CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`",
       System`$ContextPath = {"System`"}},
      System`Sort[System`Names[
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`pattern]]]];

CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`hashHex[
    CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`file_System`String] :=
  System`Quiet[System`Check[
    System`If[System`FileExistsQ[
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`file],
      System`IntegerString[System`FileHash[
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`file,
        "SHA256"], 16, 64],
      System`Missing["NotFound"]],
    System`Missing["HashFailed"]]];

CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`lifecycleFingerprint[] :=
  System`IntegerString[
    System`Hash[
      System`ToString[System`InputForm[System`Association[
        "Context" -> System`$Context,
        "ContextPath" -> System`$ContextPath,
        "Packages" -> System`$Packages,
        "Path" -> System`$Path,
        "Directory" -> System`Directory[]]]],
      "SHA256"], 16, 64];

CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`result =
  System`CheckAbort[
    System`Catch[
      System`Module[
        {
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`expectedV5PrivateNames,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`expectedV1PrivateNames,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v5Names,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v5PrivateNames,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v1Names,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v1PrivateNames,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPath,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialDirectory,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialCommandLine,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalNamesBefore,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalStatesBefore,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalNamesAfter,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalStatesAfter,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageContexts,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageNames,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageStatesBefore,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageStatesAfter,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`ownedAttributes,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredPackages,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContext,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContextPath,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`lifecycleHash,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages
        },

        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`expectedV5PrivateNames =
          {
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`bundleDirectory",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`commandLineBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`commandLineBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`contextBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`contextBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`contextPathBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`contextPathBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`directoryBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`directoryBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`envelope",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`envelope$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`expectedKernelID",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`expectedOutdir",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`expectedPathSealHash",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`expectedPreflightHash",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`gateQ",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`gateQ$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`globalNamesAfter",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`globalNamesAfter$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`globalNamesBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`globalNamesBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`globalStatesAfter",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`globalStatesAfter$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`globalStatesBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`globalStatesBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`heldSymbol",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`heldSymbol$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`name",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`name$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`packagesBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`packagesBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`pathBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`pathBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`pathSeal",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`pathSeal$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`pathSealHash",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`pathSealHash$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`pathSealPath",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`pathSealPath$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightHash",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightHash$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightName",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightNamesAfter",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightNamesAfter$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightNamesBefore",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightNamesBefore$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightPath",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`preflightPath$",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`privatePatterns",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`probeFinalResult",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`report",
           "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`report$"
          };
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`expectedV1PrivateNames =
          {
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`aborted",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`aborted$",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`code",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`contextBefore",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`contextPathBefore",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`diagnosticExit",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`diagnostics",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`expression",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`expression$",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`globalNamesAfter",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`globalNamesBefore",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`heldSymbol",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`heldSymbol$",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`helperQ",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`kernelID",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`label",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`label$",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`leakedAfter",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`leakedBefore",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`messages",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`messages$",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`nestedCount",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`packagesBefore",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`probeEvaluation",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`results",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`runProbe",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`value",
           "CodexDefinitionReaderHoldDiagnosticK146XH`Private`value$"
          };

        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v5Names =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
            "CodexCF300Sector12RecaptureV5DirtyK146Probe`*"];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v5PrivateNames =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
            "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v1Names =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
            "CodexDefinitionReaderHoldDiagnosticK146XH`*"];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v1PrivateNames =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
            "CodexDefinitionReaderHoldDiagnosticK146XH`Private`*"];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages =
          System`$Packages;
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPath =
          System`$Path;
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialDirectory =
          System`Directory[];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialCommandLine =
          System`$ScriptCommandLine;

        System`If[! System`TrueQ[
            System`$KernelID === 146 &&
            System`Length[System`Kernels[]] === 0 &&
            System`ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
            KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
            System`Length[System`Rest[System`$ScriptCommandLine]] === 0 &&
            System`Head[System`First[System`$Output]] ===
              System`OutputStream &&
            System`$Context ===
              "CodexDefinitionReaderHoldDiagnosticK146XH`Private`" &&
            System`$ContextPath ===
              {"CodexDefinitionReaderHoldDiagnosticK146XH`", "System`"} &&
            System`Take[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages,
              3] ===
              {"CodexDefinitionReaderHoldDiagnosticK146XH`",
               "CodexCF300Sector12RecaptureV5DirtyK146Probe`",
               "CodexCF300Sector12RecaptureV4Probe`"} &&
            System`Count[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages,
              "CodexDefinitionReaderHoldDiagnosticK146XH`"] === 1 &&
            System`Count[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages,
              "CodexCF300Sector12RecaptureV5DirtyK146Probe`"] === 1 &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v5Names === {} &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v1Names === {} &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v5PrivateNames ===
              System`Sort[
                CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`expectedV5PrivateNames] &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v1PrivateNames ===
              System`Sort[
                CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`expectedV1PrivateNames] &&
            System`Attributes[System`Options] === {System`Protected} &&
            System`MemberQ[System`Attributes[System`Messages],
              System`HoldAll] &&
            ! System`FileExistsQ[
              "/tmp/codex-triple-root-20260823c.vx654S/" <>
               "cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146"] &&
            ! System`DirectoryQ[
              "/tmp/codex-triple-root-20260823c.vx654S/" <>
               "cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146"] &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`hashHex[
              "/home/maxzhang/factorization-and-loops/Addon/" <>
               "Mathematica_Addon/FeynArts/FeynArts/Initialize.m"] ===
              "db2bd29ac8215640bea3df31360431e7c94bd135c4d3e41fe255e9e1450a6142" &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`hashHex[
              "/tmp/codex-triple-root-20260823c.vx654S/pool/logs/" <>
               "probe_cf300_s12_recapture_v5_dirty_k146_no_write_xh_v1.log"] ===
              "6ff4c1e8ab36ce8c54d6a50ee43ce86281792aa7c22c961d38a05503dcf7ea54" &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`hashHex[
              "/tmp/codex-triple-root-20260823c.vx654S/pool/failed/" <>
               "probe_cf300_s12_recapture_v5_dirty_k146_no_write_xh_v1.status"] ===
              "ac3e8fd9c7df046eca0449092b9d335008e891e160c6c3d4508c55e881f8c650" &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`hashHex[
              "/tmp/codex-triple-root-20260823c.vx654S/pool/logs/" <>
               "diagnose_definition_reader_hold_k146_xh_v2.log"] ===
              "d46f89e2e9a56c19c4ecdf2dd1bf8866ae64df0514877cd3484fe19425d7c255" &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`hashHex[
              "/tmp/codex-triple-root-20260823c.vx654S/pool/done/" <>
               "diagnose_definition_reader_hold_k146_xh_v2.status"] ===
              "b0f23ab9e8c92431e24b4940d97737bf25ea7ae6da11408cfc78384990694506" &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`hashHex[
              "/tmp/codex-triple-root-20260823c.vx654S/pool/logs/" <>
               "inspect_k146_context_lifecycle_xh_v1.log"] ===
              "3d3e997de61b4e093d4605297c5e52f4d13b9e6d19c236a4b4a12d2330eda90c" &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`hashHex[
              "/tmp/codex-triple-root-20260823c.vx654S/pool/done/" <>
               "inspect_k146_context_lifecycle_xh_v1.status"] ===
              "306412e295634c58003ead74981a5527cde9ebdb041c70c05704d5fcec823269"],
          System`Throw[
            System`Association["Failure" -> "initial exact recovery gate"],
            "CF300V5bRecoveryFailure"]];

        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`ownedAttributes =
          System`AssociationMap[
            System`Function[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`name,
              System`Lookup[
                CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateByName[
                  CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`name],
                "Attributes", {System`Locked}]],
            System`Join[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v5PrivateNames,
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v1PrivateNames]];
        System`If[! System`AllTrue[
            System`Values[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`ownedAttributes],
            System`Function[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`attrs,
              System`FreeQ[
                CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`attrs,
                System`Locked | System`Protected]]],
          System`Throw[
            System`Association["Failure" -> "owned context attribute gate"],
            "CF300V5bRecoveryFailure"]];

        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalNamesBefore =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
            "Global`*"];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalStatesBefore =
          System`AssociationMap[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateByName,
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalNamesBefore];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageContexts =
          {"FeynCalc`", "FeynArts`", "FeynFacet`",
           "FeynHelpers`", "FeynCalcLegacy`", "CANONICA`"};
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageNames =
          System`Union @@
            (CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
                #1 <> "*"] & /@
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageContexts);
        System`If[
          System`Length[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageNames] =!=
            1685,
          System`Throw[
            System`Association["Failure" -> "relevant package name count"],
            "CF300V5bRecoveryFailure"]];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageStatesBefore =
          System`AssociationMap[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateByName,
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageNames];

        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages = {};
        System`Block[{System`$MessageList = {}},
          System`End[];
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages =
            System`Join[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages,
              System`$MessageList]];
        System`If[! System`TrueQ[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages ===
              {} &&
            System`$Context ===
              "CodexDefinitionReaderHoldDiagnosticK146XH`" &&
            System`$ContextPath ===
              {"CodexDefinitionReaderHoldDiagnosticK146XH`", "System`"}],
          System`Throw[
            System`Association["Failure" -> "diagnostic End unwind"],
            "CF300V5bRecoveryFailure"]];

        System`Block[{System`$MessageList = {}},
          System`EndPackage[];
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages =
            System`Join[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages,
              System`$MessageList]];
        System`If[! System`TrueQ[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages ===
              {} &&
            System`$Context ===
              "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`" &&
            System`$ContextPath ===
              {"CodexCF300Sector12RecaptureV5DirtyK146Probe`", "System`"}],
          System`Throw[
            System`Association["Failure" -> "diagnostic EndPackage unwind"],
            "CF300V5bRecoveryFailure"]];

        System`Block[{System`$MessageList = {}},
          System`End[];
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages =
            System`Join[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages,
              System`$MessageList]];
        System`If[! System`TrueQ[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages ===
              {} &&
            System`$Context ===
              "CodexCF300Sector12RecaptureV5DirtyK146Probe`" &&
            System`$ContextPath ===
              {"CodexCF300Sector12RecaptureV5DirtyK146Probe`", "System`"}],
          System`Throw[
            System`Association["Failure" -> "V5 probe End unwind"],
            "CF300V5bRecoveryFailure"]];

        System`Block[{System`$MessageList = {}},
          System`EndPackage[];
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages =
            System`Join[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages,
              System`$MessageList]];
        System`If[! System`TrueQ[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`phaseMessages ===
              {} &&
            System`$Context === "Global`" &&
            System`ListQ[System`$ContextPath] &&
            System`DuplicateFreeQ[System`$ContextPath] &&
            System`MemberQ[System`$ContextPath, "System`"] &&
            System`MemberQ[System`$ContextPath, "Global`"] &&
            System`FreeQ[System`$ContextPath,
              "CodexDefinitionReaderHoldDiagnosticK146XH`" |
              "CodexCF300Sector12RecaptureV5DirtyK146Probe`"] &&
            System`$Packages ===
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages],
          System`Throw[
            System`Association["Failure" -> "V5 probe EndPackage unwind"],
            "CF300V5bRecoveryFailure"]];

        System`$Packages =
          System`Drop[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages,
            2];
        System`Quiet[System`Remove[
          "CodexDefinitionReaderHoldDiagnosticK146XH`Private`*"]];
        System`Quiet[System`Remove[
          "CodexDefinitionReaderHoldDiagnosticK146XH`*"]];
        System`Quiet[System`Remove[
          "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"]];
        System`Quiet[System`Remove[
          "CodexCF300Sector12RecaptureV5DirtyK146Probe`*"]];

        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredPackages =
          System`$Packages;
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContext =
          System`$Context;
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContextPath =
          System`$ContextPath;
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalNamesAfter =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
            "Global`*"];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalStatesAfter =
          System`AssociationMap[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateByName,
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalNamesAfter];
        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageStatesAfter =
          System`AssociationMap[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`symbolStateByName,
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageNames];

        System`If[! System`TrueQ[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContext ===
              "Global`" &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredPackages ===
              System`Drop[
                CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPackages,
                2] &&
            System`First[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredPackages] ===
              "CodexCF300Sector12RecaptureV4Probe`" &&
            System`FreeQ[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredPackages,
              "CodexDefinitionReaderHoldDiagnosticK146XH`" |
              "CodexCF300Sector12RecaptureV5DirtyK146Probe`"] &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
              "CodexDefinitionReaderHoldDiagnosticK146XH`*"] === {} &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
              "CodexDefinitionReaderHoldDiagnosticK146XH`Private`*"] === {} &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
              "CodexCF300Sector12RecaptureV5DirtyK146Probe`*"] === {} &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`fullNames[
              "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"] === {} &&
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalNamesAfter ===
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalNamesBefore &&
            System`SameQ[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalStatesAfter,
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`globalStatesBefore] &&
            System`SameQ[
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageStatesAfter,
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`packageStatesBefore] &&
            System`$Path ===
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialPath &&
            System`Directory[] ===
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialDirectory &&
            System`$ScriptCommandLine ===
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`initialCommandLine],
          System`Throw[
            System`Association["Failure" -> "post-unwind equivalence gate"],
            "CF300V5bRecoveryFailure"]];

        CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`lifecycleHash =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`lifecycleFingerprint[];
        CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineContext =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContext;
        CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineContextPath =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContextPath;
        CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselinePackages =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredPackages;
        CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselinePath =
          System`$Path;
        CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineDirectory =
          System`Directory[];
        CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineCommandLine =
          System`$ScriptCommandLine;
        CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredLifecycleFingerprint =
          CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`lifecycleHash;

        System`Print[
          "CF300 S12 RECAPTURE V5B K146 LIFECYCLE RECOVERY ",
          System`InputForm[System`Association[
            "GateQ" -> System`True,
            "WorkerKernelID" -> System`$KernelID,
            "RemovedV5PrivateNameCount" ->
              System`Length[
                CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v5PrivateNames],
            "RemovedV1PrivateNameCount" ->
              System`Length[
                CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`v1PrivateNames],
            "RecoveredContext" ->
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContext,
            "RecoveredContextPath" ->
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredContextPath,
            "RecoveredPackagesPrefix" ->
              System`Take[
                CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`recoveredPackages,
                System`UpTo[8]],
            "LifecycleFingerprintSHA256" ->
              CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`lifecycleHash,
            "GlobalDefinitionEquivalenceQ" -> System`True,
            "RelevantPackageDefinitionEquivalenceQ" -> System`True]]];
        System`True
      ],
      "CF300V5bRecoveryFailure",
      System`Function[
        {CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`failure,
         CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`tag},
        System`Print[
          "CF300 S12 RECAPTURE V5B K146 RECOVERY REJECTED ",
          System`InputForm[
            CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`failure]];
        System`False]],
    System`False];

System`If[
  ! System`TrueQ[
    CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`result],
  System`Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`*"]];
  System`Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`*"]];
  System`Abort[]];

System`Quiet[System`Remove[
  "CodexCF300Sector12RecaptureV5bRecoveredK146Recovery`*"]];

BeginPackage["CodexCF300Sector12RecaptureV5bRecoveredK146Probe`"];
Begin["`Private`"];

probeFinalResult = CheckAbort[
  With[
    {bundleDirectory = DirectoryName[ExpandFileName[System`$InputFileName]],
     preflightName =
       "preflight_cf300_sector12_recapture_v5b_recovered_k146_global_state.wls",
     expectedPreflightHash =
       "02bfc26610fe7300a470dc702ceaab88aac854496c1e5107af758657271a589f",
     expectedPathSealHash =
       "e6acf90517f2dd6c0ffd997ee2b777ddca1d8fe58414102111d0f24a1b9ee70b",
     expectedKernelID = 146,
     expectedOutdir =
       "/tmp/codex-triple-root-20260823c.vx654S/" <>
        "cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146",
     preflightPatterns = {
       "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`*",
       "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`Private`*"},
     baselineContext =
       CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineContext,
     baselineContextPath =
       CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineContextPath,
     baselinePackages =
       CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselinePackages,
     baselinePath =
       CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselinePath,
     baselineDirectory =
       CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineDirectory,
     baselineCommandLine =
       CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineCommandLine,
     recoveredLifecycleFingerprint =
       CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredLifecycleFingerprint},
    With[
      {preflightPath = FileNameJoin[{bundleDirectory, preflightName}],
       pathSealPath = FileNameJoin[{bundleDirectory,
         "cf300_sector12_recapture_v5b_recovered_k146_path_seal.json"}],
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
             "Options" -> System`Options[
               System`Unevaluated[heldSymbol]]|>, HoldAll]]],
         System`Names["Global`*"]],
       contextBefore = System`$Context,
       contextPathBefore = System`$ContextPath,
       packagesBefore = System`$Packages,
       pathBefore = System`$Path,
       directoryBefore = System`Directory[],
       commandLineBefore = System`$ScriptCommandLine,
       preflightNamesBefore = Flatten[
         System`Names[#1] & /@ preflightPatterns],
       preflightHash = Quiet[Check[
         If[System`FileExistsQ[FileNameJoin[{bundleDirectory, preflightName}]],
           IntegerString[System`FileHash[
             FileNameJoin[{bundleDirectory, preflightName}], "SHA256"],
             16, 64], Missing["NotFound"]], Missing["HashFailed"]]],
       pathSealHash = Quiet[Check[
         IntegerString[System`FileHash[FileNameJoin[{bundleDirectory,
           "cf300_sector12_recapture_v5b_recovered_k146_path_seal.json"}],
           "SHA256"], 16, 64], Missing["HashFailed"]]],
       pathSeal = Quiet[Check[Import[FileNameJoin[{bundleDirectory,
         "cf300_sector12_recapture_v5b_recovered_k146_path_seal.json"}],
         "RawJSON"], $Failed]]},
      With[
        {envelope = If[TrueQ[
             System`$KernelID === expectedKernelID &&
             Length[System`Kernels[]] === 0 &&
             ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
             KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
             ListQ[System`$Output] && Length[System`$Output] >= 1 &&
             System`Head[System`First[System`$Output]] ===
               System`OutputStream &&
             Length[Rest[System`$ScriptCommandLine]] === 0 &&
             preflightHash === expectedPreflightHash &&
             pathSealHash === expectedPathSealHash &&
             AssociationQ[pathSeal] &&
             Lookup[pathSeal, "Schema", None] ===
               "CF300Sector12RecaptureV5bRecoveredK146PathSealV1" &&
             TrueQ[Lookup[pathSeal, "GateQ", False]] &&
             Lookup[pathSeal, "RecordCount", None] === 21 &&
             preflightNamesBefore === {} &&
             baselineContext === "Global`" &&
             ListQ[baselineContextPath] &&
             DuplicateFreeQ[baselineContextPath] &&
             First[baselinePackages] ===
               "CodexCF300Sector12RecaptureV4Probe`" &&
             StringMatchQ[recoveredLifecycleFingerprint,
               Repeated[HexadecimalCharacter, {64}]] &&
             packagesBefore ===
               Prepend[baselinePackages,
                 "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`"] &&
             ! System`FileExistsQ[expectedOutdir] &&
             ! System`DirectoryQ[expectedOutdir]],
           CheckAbort[
             Internal`InheritedBlock[
               {System`$Context, System`$ContextPath, System`$Packages,
                System`$Path, System`$HistoryLength},
               Block[{System`$Context = "Global`",
                 System`$ContextPath = {"System`"}},
                 System`Get[preflightPath]]],
             <|"Status" -> "ProbePreflightAborted"|>],
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
                 "Options" -> System`Options[
                   System`Unevaluated[heldSymbol]]|>, HoldAll]]],
             System`Names["Global`*"]],
           preflightNamesAfter = Flatten[
             System`Names[#1] & /@ preflightPatterns]},
          With[
            {gateQ = TrueQ[
               AssociationQ[envelope] &&
               Lookup[envelope, "Status", None] ===
                 "CF300Sector12RecaptureV5bRecoveredK146PreflightEnvelope" &&
               TrueQ[Lookup[envelope, "DedicatedNameCleanupQ", False]] &&
               AssociationQ[report] &&
               TrueQ[Lookup[report, "GateQ", False]] &&
               Lookup[report, "FeynCalcVersion", None] === "10.2.1" &&
               Lookup[report, "FeynArtsVersion", None] ===
                 "FeynArts 3.12 (27 Mar 2025)" &&
               Lookup[report, "ExistingRelevantPackageNameCount", None] ===
                 1685 &&
               Lookup[report, "UnsafeDirtyDefinitionNames", {$Failed}] ===
                 {} &&
               Lookup[report, "UnsafePackageShadowNames", {$Failed}] ===
                 {} &&
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
               baselinePath === pathBefore &&
               baselineDirectory === directoryBefore &&
               baselineCommandLine === commandLineBefore &&
               ! System`FileExistsQ[expectedOutdir] &&
               ! System`DirectoryQ[expectedOutdir]]},
            Print["CF300 S12 RECAPTURE V5B RECOVERED K146 NO-WRITE PROBE ",
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
                    "PackageDefinitionFingerprintSHA256", Missing[]],
                    Missing[]],
                "RecoveredLifecycleFingerprintSHA256" ->
                  recoveredLifecycleFingerprint,
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
                "CF300_V5B_RECOVERED_K146_PACKAGE_FINGERPRINT_SHA256=" <>
                  Lookup[report, "PackageDefinitionFingerprintSHA256", ""],
                "\n",
                "CF300_V5B_RECOVERED_K146_LIFECYCLE_SHA256=" <>
                  recoveredLifecycleFingerprint,
                "\n"];
              0,
              $Failed]]]]]],
  <|"Status" -> "CF300Sector12RecaptureV5bRecoveredK146ProbeCaughtAbort",
    "GateQ" -> False|>];

With[
  {resolvedResult = probeFinalResult,
   resolvedBaselineContext =
     CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineContext,
   resolvedBaselineContextPath =
     CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineContextPath,
   resolvedBaselinePackages =
     CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselinePackages,
   resolvedBaselinePath =
     CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselinePath,
   resolvedBaselineDirectory =
     CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineDirectory,
   resolvedBaselineCommandLine =
     CodexCF300Sector12RecaptureV5bRecoveredK146Probe`$RecoveredBaselineCommandLine,
   resolvedNames = System`Join[
     System`Names[
       "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`*"],
     System`Names[
       "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`Private`*"]]},
  End[];
  EndPackage[];
  With[
    {packageEnvelopeQ = TrueQ[
       System`$Context === resolvedBaselineContext &&
       System`$ContextPath === resolvedBaselineContextPath &&
       System`$Packages === Prepend[resolvedBaselinePackages,
         "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`"] &&
       System`$Path === resolvedBaselinePath &&
       System`Directory[] === resolvedBaselineDirectory &&
       System`$ScriptCommandLine === resolvedBaselineCommandLine]},
    If[packageEnvelopeQ,
      System`$Packages = resolvedBaselinePackages];
    Quiet[System`Remove[
      "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`Private`*"]];
    Quiet[System`Remove[
      "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`*"]];
    Quiet[System`Remove[
      "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`Private`*"]];
    Quiet[System`Remove[
      "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`*"]];
    With[
      {cleanupQ = TrueQ[
         packageEnvelopeQ &&
         System`Join[
           System`Names[
             "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`*"],
           System`Names[
             "CodexCF300Sector12RecaptureV5bRecoveredK146Probe`Private`*"],
           System`Names[
             "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`*"],
           System`Names[
             "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`Private`*"]] ===
           {} &&
         System`$Context === resolvedBaselineContext &&
         System`$ContextPath === resolvedBaselineContextPath &&
         System`$Packages === resolvedBaselinePackages &&
         System`$Path === resolvedBaselinePath &&
         System`Directory[] === resolvedBaselineDirectory &&
         System`$ScriptCommandLine === resolvedBaselineCommandLine]},
      Print["CF300 S12 RECAPTURE V5B RECOVERED K146 PROBE CLEANUP ",
        InputForm[<|"CleanupQ" -> cleanupQ,
          "PackageEnvelopeQ" -> packageEnvelopeQ,
          "NamesBeforeCleanupCount" -> Length[resolvedNames]|>]];
      If[cleanupQ, resolvedResult, $Failed]]]]
