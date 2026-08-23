#!/usr/bin/env wolframscript

(* Read-only V3 launcher preflight plus localized package lifecycle.  It
   rejects Global/package shadow hazards before the private body can create an
   output, pins the body, localizes $ContextPath and protected $Packages across
   the complete body Get, then exact-audits restoration before returning or
   forwarding a driver payload.  No top-level Module locals or Return are used. *)

$HistoryLength = 0;
With[
  {bodyPath = FileNameJoin[{
      DirectoryName[ExpandFileName[$InputFileName]],
      "run_cf300_sector12_recapture_from_v4_xh_v3_body.wls"}],
   expectedBodyHash =
     "138ddd8643bff53779a14503c7c3579cc6b5375aab486e6a2e8719e3745ddff3",
   expectedOutdir =
     "/tmp/codex-triple-root-20260823c.vx654S/" <>
      "cf300_sector12_recapture_from_v4_xh_v3",
   dedicatedContexts = {
     "CodexCF300Sector12RecaptureV3`",
     "CodexCF300Sector12RecaptureV3`Private`"},
   knownGlobalShadowHazards = {
     "Global`$LoadFeynArts", "Global`$LoadAddOns", "Global`A0"},
   packageContexts = {
     "FeynCalc`", "FeynArts`", "FeynFacet`", "CANONICA`"},
   globalNamesBefore = System`Names["Global`*"],
   contextPathBefore = System`$ContextPath,
   packagesBefore = System`$Packages,
   contextBefore = System`$Context,
   packagesProtectedBeforeQ =
     System`MemberQ[System`Attributes[System`$Packages], Protected]},

  With[
    {packageBaseNames = System`DeleteDuplicates[
       System`Map[
         Function[name, System`Last[System`StringSplit[name, "`"]]],
         System`Flatten[
           System`Map[System`Names[#1 <> "*"] &, packageContexts]]]]},
    With[
      {dirtyShadowNames = System`Union[
         System`Intersection[globalNamesBefore,
           knownGlobalShadowHazards],
         System`Select[globalNamesBefore,
           Function[name,
             System`MemberQ[packageBaseNames,
               System`Last[System`StringSplit[name, "`"]]]]]],
       dedicatedNamesBefore = System`Join[
         System`Names["CodexCF300Sector12RecaptureV3`*"],
         System`Names["CodexCF300Sector12RecaptureV3`Private`*"]],
       bodyHash = Quiet[Check[
         If[FileExistsQ[bodyPath],
           IntegerString[FileHash[bodyPath, "SHA256"], 16, 64],
           Missing["NotFound"]], Missing["HashFailed"]]]},

      Print["CF300 S12 RECAPTURE V3 LAUNCHER PREFLIGHT ",
        InputForm[<|
          "WorkerKernelID" -> $KernelID,
          "NestedKernelCount" -> Length[Kernels[]],
          "BodySHA256" -> bodyHash,
          "DirtyGlobalShadowCount" -> Length[dirtyShadowNames],
          "DirtyGlobalShadows" -> Take[dirtyShadowNames, UpTo[20]],
          "DedicatedNamesBefore" -> dedicatedNamesBefore,
          "DedicatedContextOnPathBeforeQ" ->
            ! System`FreeQ[contextPathBefore,
              Alternatives @@ dedicatedContexts],
          "DedicatedContextInPackagesBeforeQ" ->
            ! System`FreeQ[packagesBefore,
              Alternatives @@ dedicatedContexts],
          "PackagesProtectedBeforeQ" -> packagesProtectedBeforeQ|>]];

      If[! TrueQ[
          Length[Rest[$ScriptCommandLine]] === 0 &&
          IntegerQ[$KernelID] && $KernelID > 0 &&
          Length[Kernels[]] === 0 &&
          ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
          KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
          bodyHash === expectedBodyHash &&
          ! FileExistsQ[expectedOutdir] && ! DirectoryQ[expectedOutdir] &&
          dirtyShadowNames === {} && dedicatedNamesBefore === {} &&
          System`FreeQ[contextPathBefore,
            Alternatives @@ dedicatedContexts] &&
          System`FreeQ[packagesBefore,
            Alternatives @@ dedicatedContexts] &&
          packagesProtectedBeforeQ],
        Print["CF300 S12 RECAPTURE V3 LAUNCHER FAIL: " <>
          "worker/body/freshness/namespace preflight rejected before write"];
        $Failed,

        With[
          {runRecord = Block[{$MessageList = {}},
             With[
               {bodyEnvelope = Internal`InheritedBlock[
                  {System`$ContextPath, System`$Packages},
                  Get[bodyPath]]},
               <|"BodyEnvelope" -> bodyEnvelope,
                 "LifecycleMessages" ->
                   (ToString[InputForm[#1]] & /@ $MessageList)|>]]},
          With[
            {contextPathAfter = System`$ContextPath,
             packagesAfter = System`$Packages,
             contextAfter = System`$Context,
             packagesProtectedAfterQ =
               System`MemberQ[
                 System`Attributes[System`$Packages], Protected],
             dedicatedNamesAfter = System`Join[
               System`Names["CodexCF300Sector12RecaptureV3`*"],
               System`Names[
                 "CodexCF300Sector12RecaptureV3`Private`*"]]},
            With[
              {bodyEnvelope = Lookup[runRecord,
                 "BodyEnvelope", $Failed],
               lifecycleMessages = Lookup[runRecord,
                 "LifecycleMessages", {"MissingLifecycleMessages"}],
               contextPathRestoredQ =
                 SameQ[System`$ContextPath, contextPathBefore],
               packagesRestoredQ =
                 SameQ[System`$Packages, packagesBefore],
               contextRestoredQ =
                 SameQ[System`$Context, contextBefore],
               packagesProtectionRestoredQ =
                 SameQ[packagesProtectedAfterQ,
                   packagesProtectedBeforeQ]},
              With[
                {lifecycleGateQ = TrueQ[
                   AssociationQ[bodyEnvelope] &&
                   Lookup[bodyEnvelope, "Status", None] ===
                     "CF300Sector12RecaptureV3BodyEnvelope" &&
                   TrueQ[Lookup[bodyEnvelope,
                     "DedicatedNameCleanupQ", False]] &&
                   TrueQ[Lookup[bodyEnvelope,
                     "ContextPathWasLocalizedQ", False]] &&
                   TrueQ[Lookup[bodyEnvelope,
                     "PackagesWasLocalizedQ", False]] &&
                   lifecycleMessages === {} &&
                   contextPathRestoredQ && packagesRestoredQ &&
                   contextRestoredQ && packagesProtectionRestoredQ &&
                   dedicatedNamesAfter === {}]},
                Print["CF300 S12 RECAPTURE V3 LIFECYCLE TELEMETRY ",
                  InputForm[<|
                    "LifecycleGateQ" -> lifecycleGateQ,
                    "LifecycleMessages" -> lifecycleMessages,
                    "ContextPathRestoredQ" -> contextPathRestoredQ,
                    "PackagesRestoredQ" -> packagesRestoredQ,
                    "ContextRestoredQ" -> contextRestoredQ,
                    "PackagesProtectionRestoredQ" ->
                      packagesProtectionRestoredQ,
                    "DedicatedNamesAfter" -> dedicatedNamesAfter,
                    "BodyEnvelope" -> bodyEnvelope|>]];
                If[! lifecycleGateQ,
                  Print["CF300 S12 RECAPTURE V3 LAUNCHER FAIL: " <>
                    "localized lifecycle/body envelope gate failed"];
                  $Failed,
                  If[Lookup[bodyEnvelope, "ForwardPayload", None] =!= None,
                    Throw[Lookup[bodyEnvelope, "ForwardPayload"],
                      "KernelPoolExit"],
                    Lookup[bodyEnvelope, "BodyResult", $Failed]]]]]]]]]]]
