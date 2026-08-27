#!/usr/bin/env wolframscript

$HistoryLength = 0;
Module[{names, overrides, before, afterSet, afterRestore, restoreResults,
    setResult, gate},
  names = {"FACET_KERNEL_COUNT", "FACET_TASK_BROKER_MAX_HELPERS",
    "FACET_CHECK_LEVEL", "FACET_STRIP_ROUTE", "FACET_ZERO_FORCING",
    "FACET_RECORD_STRIP_ONLY", "FACET_RESUME_HYDRATION"};
  overrides = <|
    "FACET_KERNEL_COUNT" -> "1",
    "FACET_TASK_BROKER_MAX_HELPERS" -> "0",
    "FACET_CHECK_LEVEL" -> "Production",
    "FACET_STRIP_ROUTE" -> "FiniteFieldFirst",
    "FACET_ZERO_FORCING" -> "True",
    "FACET_RECORD_STRIP_ONLY" -> "True",
    "FACET_RESUME_HYDRATION" -> "True"|>;
  before = AssociationThread[names, Environment /@ names];
  setResult = Quiet[Check[SetEnvironment[Normal[overrides]], $Failed]];
  afterSet = AssociationThread[names, Environment /@ names];
  restoreResults = KeyValueMap[
    Function[{name, value},
      name -> Quiet[Check[
        If[StringQ[value], SetEnvironment[name -> value],
          UnsetEnvironment[name]], $Failed]]], before];
  afterRestore = AssociationThread[names, Environment /@ names];
  gate = TrueQ[afterSet === overrides && afterRestore === before];
  Print["CF300_RECAPTURE_ENVIRONMENT_DIAGNOSTIC ", InputForm[<|
    "KernelID" -> $KernelID,
    "TaskBrokerMaxHelpers" ->
      If[ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers],
        KernelPoolMission`$TaskBrokerMaxHelpers, Missing["Unset"]],
    "Before" -> before, "SetResult" -> setResult,
    "AfterSet" -> afterSet, "RestoreResults" -> restoreResults,
    "AfterRestore" -> afterRestore, "RoundTripQ" -> gate|>]];
  If[gate, 0, $Failed]
]
