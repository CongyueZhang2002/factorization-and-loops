#!/usr/bin/env wolframscript

(* Centralized, no-load held-parse gate for the frozen V6e sources. *)
Module[
  {files, expectedHashes, observedHashes, parseContext, globalBefore,
   parsed, source, parseMessages, syntaxMessages, syntaxLength,
   results, cleanup, passQ, helperCeilingQ, nestedKernelQ},

  files = <|
    "Helper" ->
      "/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/DirectRootChannelExactOneFormRebindV6e.wl",
    "Integration" ->
      "/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/V6E_DRIVER_INTEGRATION_BLOCK.wl"|>;
  expectedHashes = <|
    "Helper" ->
      "2fea1e07c691ade811162f47db1d71d82a385dd01d07afd20beaa3aa0262f2e8",
    "Integration" ->
      "7ea7a437cd25a440e4713040d0882947977a71f092510f0c02c940d8d02f0dbe"|>;
  helperCeilingQ = TrueQ[
    ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
      KernelPoolMission`$TaskBrokerMaxHelpers === 0];
  nestedKernelQ = Length[Kernels[]] === 0;
  observedHashes = AssociationMap[
    Quiet[Check[FileHash[#, "SHA256", "HexString"], $Failed]] &,
    files];
  parseContext = "CodexV6eHeldParseGate`c" <>
    StringReplace[CreateUUID[], "-" -> ""] <> "`";
  globalBefore = Names["Global`*"];
  cleanup[] := (
    parsed =.;
    Quiet[Remove[parseContext <> "*"]];
    Scan[(Quiet[Remove[#]]) &,
      Complement[Names["Global`*"], globalBefore]]);

  results = CheckAbort[
    AssociationMap[
      Function[label,
        source = Quiet[Check[Import[files[label], "Text"], $Failed]];
        parseMessages = {};
        syntaxMessages = {};
        parsed = $Failed;
        syntaxLength = $Failed;
        If[StringQ[source],
          Block[{$Context = parseContext, $ContextPath = {"System`"},
              $MessageList = {}},
            parsed = Quiet[Check[
              ToExpression[source, InputForm, HoldComplete], $Failed]];
            parseMessages = ToString[InputForm[#]] & /@ $MessageList];
          Block[{$MessageList = {}},
            syntaxLength = Quiet[Check[SyntaxLength[source], $Failed]];
            syntaxMessages = ToString[InputForm[#]] & /@ $MessageList]];
        <|
          "Path" -> files[label],
          "ExpectedSHA256" -> expectedHashes[label],
          "ObservedSHA256" -> observedHashes[label],
          "CharacterCount" -> If[StringQ[source], StringLength[source], $Failed],
          "SyntaxLength" -> syntaxLength,
          "HeldHead" -> If[parsed === $Failed, $Failed, Head[parsed]],
          "ParseMessages" -> parseMessages,
          "SyntaxMessages" -> syntaxMessages|>],
      Keys[files]],
    (cleanup[]; Abort[])];
  cleanup[];
  passQ = TrueQ[
    helperCeilingQ && nestedKernelQ &&
      Names[parseContext <> "*"] === {} &&
      Names["Global`*"] === globalBefore &&
      And @@ KeyValueMap[
        Function[{label, record},
          Lookup[record, "ObservedSHA256", None] ===
              expectedHashes[label] &&
            IntegerQ[Lookup[record, "CharacterCount", None]] &&
            Lookup[record, "SyntaxLength", None] ===
              Lookup[record, "CharacterCount", None] &&
            Lookup[record, "HeldHead", None] === HoldComplete &&
            Lookup[record, "ParseMessages", None] === {} &&
            Lookup[record, "SyntaxMessages", None] === {}],
        results]];
  Print["V6E HELD PARSE GATE ", InputForm[<|
    "PassQ" -> passQ,
    "HelperCeilingZeroQ" -> helperCeilingQ,
    "NestedKernelCountZeroQ" -> nestedKernelQ,
    "Results" -> results|>]];
  If[passQ,
    <|"Status" -> "V6eHeldParseGatePassed", "Results" -> results|>,
    $Failed]
]
