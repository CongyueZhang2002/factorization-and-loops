#!/usr/bin/env wolframscript

System`Print["K146_CONTEXT_LIFECYCLE ", System`InputForm[<|
  "KernelID" -> System`$KernelID,
  "Context" -> System`$Context,
  "ContextPath" -> System`$ContextPath,
  "Packages" -> System`$Packages,
  "V5ProbeNames" -> System`Names[
    "CodexCF300Sector12RecaptureV5DirtyK146Probe`*"],
  "V5ProbePrivateNames" -> System`Names[
    "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"],
  "V1DiagnosticNames" -> System`Names[
    "CodexDefinitionReaderHoldDiagnosticK146XH`*"],
  "V1DiagnosticPrivateNames" -> System`Names[
    "CodexDefinitionReaderHoldDiagnosticK146XH`Private`*"]|>]];
If[System`$KernelID === 146 &&
    System`ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
    KernelPoolMission`$TaskBrokerMaxHelpers === 0 &&
    System`Length[System`Kernels[]] === 0, 0, System`$Failed]

