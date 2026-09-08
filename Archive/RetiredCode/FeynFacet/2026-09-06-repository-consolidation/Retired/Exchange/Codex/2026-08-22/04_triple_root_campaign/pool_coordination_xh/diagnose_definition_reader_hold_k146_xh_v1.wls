#!/usr/bin/env wolframscript

BeginPackage["CodexDefinitionReaderHoldDiagnosticK146XH`"];
Begin["`Private`"];
Quiet[ClearAll["CodexDefinitionReaderHoldDiagnosticK146XH`Private`*"]];

diagnosticExit[code_Integer] :=
  (End[]; EndPackage[];
   Quiet[Remove["CodexDefinitionReaderHoldDiagnosticK146XH`*"]];
   System`Exit[code]);

If[$KernelID =!= 146,
  Print["DEFINITION_READER_HOLD_DIAGNOSTIC FAIL wrong dispatch expected=146 observed=",
    $KernelID];
  diagnosticExit[97]];
If[! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
    KernelPoolMission`$TaskBrokerMaxHelpers === 0) || Length[Kernels[]] =!= 0,
  Print["DEFINITION_READER_HOLD_DIAGNOSTIC FAIL helper/nested-kernel gate"];
  diagnosticExit[65]];

SetAttributes[probeEvaluation, HoldAllComplete];
probeEvaluation[label_String, expression_] := Block[{$MessageList = {}},
  Module[{value, messages},
    value = Quiet[Check[expression, $Failed]];
    messages = $MessageList;
    <|"Label" -> label,
      "FailedQ" -> SameQ[value, $Failed],
      "MessageCount" -> Length[messages],
      "ValueHead" -> ToString[InputForm[Head[Unevaluated[value]]]]|>]];

globalNamesBefore = Names["Global`*"];
diagnostics = {
  <|"MessagesAttributes" -> Attributes[Messages],
    "OptionsAttributes" -> Attributes[Options],
    "AttributesAttributes" -> Attributes[Attributes]|>,
  probeEvaluation["messages-current-reader",
    ToExpression["FeynArts`M$ClassesDescription", InputForm,
      Function[heldSymbol, Messages[heldSymbol], HoldAll]]],
  probeEvaluation["messages-unevaluated-reader",
    ToExpression["FeynArts`M$ClassesDescription", InputForm,
      Function[heldSymbol, Messages[Unevaluated[heldSymbol]], HoldAll]]],
  probeEvaluation["options-current-reader",
    ToExpression["FeynArts`M$ClassesDescription", InputForm,
      Function[heldSymbol, Options[heldSymbol], HoldAll]]],
  probeEvaluation["options-unevaluated-reader",
    ToExpression["FeynArts`M$ClassesDescription", InputForm,
      Function[heldSymbol, Options[Unevaluated[heldSymbol]], HoldAll]]],
  probeEvaluation["attributes-current-reader",
    ToExpression["FeynArts`M$ClassesDescription", InputForm,
      Function[heldSymbol, Attributes[heldSymbol], HoldAll]]],
  probeEvaluation["attributes-unevaluated-reader",
    ToExpression["FeynArts`M$ClassesDescription", InputForm,
      Function[heldSymbol, Attributes[Unevaluated[heldSymbol]], HoldAll]]]
  };
globalNamesAfter = Names["Global`*"];
Print["DEFINITION_READER_HOLD_DIAGNOSTIC ", InputForm[<|
  "KernelID" -> $KernelID,
  "GlobalNamespaceStableQ" -> SameQ[globalNamesAfter, globalNamesBefore],
  "Diagnostics" -> diagnostics|>]];

diagnosticExit[If[SameQ[globalNamesAfter, globalNamesBefore], 0, 69]];

