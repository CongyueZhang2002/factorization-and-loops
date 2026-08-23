#!/usr/bin/env wolframscript

$HistoryLength = 0;
cache = Get["/home/maxzhang/factorization-and-loops/External/" <>
  "CodexExchange/codex_ff_m1_m2_2026-08-20/" <>
  "m1_later_system_cache.wl"];
Print["top keys = ", InputForm[Keys[cache]]];
Do[
  value = cache[key];
  Print[InputForm[key], ": head=", Head[value],
    ", dimensions=", InputForm[Quiet[Dimensions[value]]],
    ", bytecount=", ByteCount[value],
    If[AssociationQ[value],
      ", keys=" <> ToString[Keys[value], InputForm], ""]],
  {key, Keys[cache]}];
If[KeyExistsQ[cache, "System"],
  Print["system keys = ", InputForm[Keys[cache["System"]]]];
  Do[
    value = cache["System", key];
    Print["  ", InputForm[key], ": head=", Head[value],
      ", dimensions=", InputForm[Quiet[Dimensions[value]]],
      ", bytecount=", ByteCount[value]],
    {key, Keys[cache["System"]]}]];
If[KeyExistsQ[cache, "Plan"],
  Print["plan keys = ", InputForm[Keys[cache["Plan"]]]]];

