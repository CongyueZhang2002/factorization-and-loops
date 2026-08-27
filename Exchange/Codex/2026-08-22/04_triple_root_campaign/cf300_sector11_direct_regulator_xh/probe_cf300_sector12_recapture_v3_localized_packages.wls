#!/usr/bin/env wolframscript

(* Read-only runtime proof that Internal`InheritedBlock can localize the
   protected $Packages together with $ContextPath across the same
   BeginPackage/EndPackage lifecycle used by the V3 body.  No Return, source
   Get, file write, package symbol definition, or process action is used. *)

$HistoryLength = 0;
With[
  {contextPathBefore = System`$ContextPath,
   packagesBefore = System`$Packages,
   contextBefore = System`$Context,
   packagesAttributesBefore = System`Attributes[System`$Packages],
   probeContexts = {
     "CodexCF300Sector12RecaptureV3LifecycleProbe`",
     "CodexCF300Sector12RecaptureV3LifecycleProbe`Private`"}},
  If[! TrueQ[
      IntegerQ[$KernelID] && $KernelID > 0 && Length[Kernels[]] === 0 &&
      ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
      KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
      System`Join[
        System`Names[
          "CodexCF300Sector12RecaptureV3LifecycleProbe`*"],
        System`Names[
          "CodexCF300Sector12RecaptureV3LifecycleProbe`Private`*"]] === {} &&
      System`FreeQ[System`$ContextPath,
        Alternatives @@ probeContexts] &&
      System`FreeQ[System`$Packages,
        Alternatives @@ probeContexts]],
    Print["CF300 S12 RECAPTURE V3 LOCALIZED-PACKAGES PROBE FAIL: " <>
      "worker/context preflight"];
    $Failed,
    With[
      {runRecord = Block[{$MessageList = {}},
         With[
           {inside = Internal`InheritedBlock[
              {System`$ContextPath, System`$Packages},
              System`BeginPackage[
                "CodexCF300Sector12RecaptureV3LifecycleProbe`"];
              System`Begin["`Private`"];
              System`End[];
              System`EndPackage[];
              <|
                "PublicContextOnLocalizedPathQ" ->
                  System`MemberQ[System`$ContextPath,
                    "CodexCF300Sector12RecaptureV3LifecycleProbe`"],
                "PublicContextInLocalizedPackagesQ" ->
                  System`MemberQ[System`$Packages,
                    "CodexCF300Sector12RecaptureV3LifecycleProbe`"],
                "PackagesStillProtectedInsideQ" ->
                  System`MemberQ[
                    System`Attributes[System`$Packages], Protected]|>]},
           <|"Inside" -> inside,
             "Messages" ->
               (ToString[InputForm[#1]] & /@ $MessageList)|>]]},
      Quiet[System`Remove[
        "CodexCF300Sector12RecaptureV3LifecycleProbe`Private`*"]];
      Quiet[System`Remove[
        "CodexCF300Sector12RecaptureV3LifecycleProbe`*"]];
      With[
        {report = <|
           "Status" -> "CF300Sector12RecaptureV3LocalizedPackagesProbe",
           "Inside" -> Lookup[runRecord, "Inside", $Failed],
           "Messages" -> Lookup[runRecord, "Messages", {$Failed}],
           "ContextPathRestoredQ" ->
             SameQ[System`$ContextPath, contextPathBefore],
           "PackagesRestoredQ" ->
             SameQ[System`$Packages, packagesBefore],
           "ContextRestoredQ" ->
             SameQ[System`$Context, contextBefore],
           "PackagesAttributesRestoredQ" ->
             SameQ[System`Attributes[System`$Packages],
               packagesAttributesBefore],
           "ProbeNamesCleanedQ" ->
             System`Join[
               System`Names[
                 "CodexCF300Sector12RecaptureV3LifecycleProbe`*"],
               System`Names[
                 "CodexCF300Sector12RecaptureV3LifecycleProbe`Private`*"]] ===
               {}|>},
        Print["CF300 S12 RECAPTURE V3 LOCALIZED-PACKAGES PROBE ",
          InputForm[report]];
        If[TrueQ[
            Lookup[report, "Messages", {$Failed}] === {} &&
            AssociationQ[Lookup[report, "Inside", $Failed]] &&
            TrueQ[Lookup[report["Inside"],
              "PublicContextOnLocalizedPathQ", False]] &&
            TrueQ[Lookup[report["Inside"],
              "PublicContextInLocalizedPackagesQ", False]] &&
            TrueQ[Lookup[report["Inside"],
              "PackagesStillProtectedInsideQ", False]] &&
            TrueQ[report["ContextPathRestoredQ"]] &&
            TrueQ[report["PackagesRestoredQ"]] &&
            TrueQ[report["ContextRestoredQ"]] &&
            TrueQ[report["PackagesAttributesRestoredQ"]] &&
            TrueQ[report["ProbeNamesCleanedQ"]]],
          0, $Failed]]]]]
