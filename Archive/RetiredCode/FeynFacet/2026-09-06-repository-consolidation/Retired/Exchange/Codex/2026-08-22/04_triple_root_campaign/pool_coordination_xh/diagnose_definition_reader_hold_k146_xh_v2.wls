#!/usr/bin/env wolframscript

Internal`InheritedBlock[{$Context, $ContextPath},
  Block[{$Context = "CodexDefinitionReaderHoldDiagnosticK146XHV2`",
      $ContextPath = {"System`"}},
    Module[{kernelID = System`$KernelID,
        helperQ, nestedCount, contextBefore, contextPathBefore,
        packagesBefore, leakedBefore, globalNamesBefore,
        runProbe, results, globalNamesAfter, leakedAfter},
      helperQ = TrueQ[
        System`ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
        KernelPoolMission`$TaskBrokerMaxHelpers === 0];
      nestedCount = System`Length[System`Kernels[]];
      contextBefore = System`$Context;
      contextPathBefore = System`$ContextPath;
      packagesBefore = System`$Packages;
      leakedBefore = System`Association[
        "V5Probe" -> System`Names[
          "CodexCF300Sector12RecaptureV5DirtyK146Probe`*"],
        "V5ProbePrivate" -> System`Names[
          "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"],
        "V1Diagnostic" -> System`Names[
          "CodexDefinitionReaderHoldDiagnosticK146XH`*"],
        "V1DiagnosticPrivate" -> System`Names[
          "CodexDefinitionReaderHoldDiagnosticK146XH`Private`*"]];
      globalNamesBefore = System`Names["Global`*"];

      System`SetAttributes[runProbe, System`HoldAllComplete];
      runProbe[label_String, expression_] := System`Module[
        {value, aborted = False, messages},
        System`Block[{System`$MessageList = {}},
          value = System`CheckAbort[
            System`Quiet[System`Check[expression, System`$Failed]],
            aborted = True; "ABORTED"];
          messages = System`$MessageList];
        System`Association[
          "Label" -> label,
          "AbortedQ" -> aborted,
          "FailedQ" -> System`SameQ[value, System`$Failed],
          "MessageCount" -> System`Length[messages],
          "ValueHead" -> System`ToString[
            System`InputForm[System`Head[System`Unevaluated[value]]]]]];

      results = {
        System`Association[
          "MessagesAttributes" -> System`Attributes[System`Messages],
          "OptionsAttributes" -> System`Attributes[System`Options],
          "AttributesAttributes" -> System`Attributes[System`Attributes]],
        runProbe["ownvalues-current-reader",
          System`ToExpression["FeynArts`M$ClassesDescription", InputForm,
            Function[heldSymbol, System`OwnValues[heldSymbol], HoldAll]]],
        runProbe["messages-current-reader",
          System`ToExpression["FeynArts`M$ClassesDescription", InputForm,
            Function[heldSymbol, System`Messages[heldSymbol], HoldAll]]],
        runProbe["messages-unevaluated-reader",
          System`ToExpression["FeynArts`M$ClassesDescription", InputForm,
            Function[heldSymbol,
              System`Messages[System`Unevaluated[heldSymbol]], HoldAll]]],
        runProbe["options-current-reader",
          System`ToExpression["FeynArts`M$ClassesDescription", InputForm,
            Function[heldSymbol, System`Options[heldSymbol], HoldAll]]],
        runProbe["options-unevaluated-reader",
          System`ToExpression["FeynArts`M$ClassesDescription", InputForm,
            Function[heldSymbol,
              System`Options[System`Unevaluated[heldSymbol]], HoldAll]]],
        runProbe["attributes-current-reader",
          System`ToExpression["FeynArts`M$ClassesDescription", InputForm,
            Function[heldSymbol, System`Attributes[heldSymbol], HoldAll]]],
        runProbe["attributes-unevaluated-reader",
          System`ToExpression["FeynArts`M$ClassesDescription", InputForm,
            Function[heldSymbol,
              System`Attributes[System`Unevaluated[heldSymbol]], HoldAll]]]
        };
      globalNamesAfter = System`Names["Global`*"];
      leakedAfter = System`Association[
        "V5Probe" -> System`Names[
          "CodexCF300Sector12RecaptureV5DirtyK146Probe`*"],
        "V5ProbePrivate" -> System`Names[
          "CodexCF300Sector12RecaptureV5DirtyK146Probe`Private`*"],
        "V1Diagnostic" -> System`Names[
          "CodexDefinitionReaderHoldDiagnosticK146XH`*"],
        "V1DiagnosticPrivate" -> System`Names[
          "CodexDefinitionReaderHoldDiagnosticK146XH`Private`*"]];
      System`Print["DEFINITION_READER_HOLD_DIAGNOSTIC_V2 ",
        System`InputForm[System`Association[
          "KernelID" -> kernelID,
          "KernelGateQ" -> System`TrueQ[kernelID === 146 && helperQ &&
            nestedCount === 0],
          "ContextAtDiagnosticEntry" -> contextBefore,
          "ContextPathAtDiagnosticEntry" -> contextPathBefore,
          "PackagesAtDiagnosticEntry" -> packagesBefore,
          "KnownLeakedNamesBefore" -> leakedBefore,
          "KnownLeakedNamesAfter" -> leakedAfter,
          "GlobalNamespaceStableQ" ->
            System`SameQ[globalNamesAfter, globalNamesBefore],
          "Results" -> results]]];
      0]]]

System`Quiet[System`Remove[
  "CodexDefinitionReaderHoldDiagnosticK146XHV2`*"]];

