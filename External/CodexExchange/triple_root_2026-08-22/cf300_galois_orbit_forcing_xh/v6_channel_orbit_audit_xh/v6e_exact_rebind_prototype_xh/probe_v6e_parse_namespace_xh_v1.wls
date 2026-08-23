#!/usr/bin/env wolframscript

Module[{path, parseContext, globalBefore, held, parseNamesBeforeRemoval,
    parseNamesAfterRemoval, globalAfter, result},
  path =
    "/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/v6e_exact_rebind_prototype_xh/DirectRootChannelExactOneFormRebindV6e.wl";
  parseContext = "CodexV6eNamespaceProbe`c" <>
    StringReplace[CreateUUID[], "-" -> ""] <> "`";
  globalBefore = Names["Global`*"];
  held = Block[{$Context = parseContext, $ContextPath = {"System`"}},
    Quiet[Check[
      ToExpression[Import[path, "Text"], InputForm, HoldComplete],
      $Failed]]];
  held =.;
  parseNamesBeforeRemoval = Names[parseContext <> "*"];
  Scan[(Quiet[Remove[#]]) &, parseNamesBeforeRemoval];
  parseNamesAfterRemoval = Names[parseContext <> "*"];
  globalAfter = Names["Global`*"];
  result = <|
    "Status" -> "V6eParseNamespaceProbe",
    "ParseNameCountBeforeRemoval" -> Length[parseNamesBeforeRemoval],
    "ParseNamesAfterRemoval" -> parseNamesAfterRemoval,
    "GlobalAdded" -> Complement[globalAfter, globalBefore],
    "GlobalRemoved" -> Complement[globalBefore, globalAfter]|>;
  Print["V6E PARSE NAMESPACE PROBE ", InputForm[result]];
  result
]
