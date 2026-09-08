#!/usr/bin/env wolframscript

$HistoryLength = 0;
Get["/home/maxzhang/factorization-and-loops/Addon/Load/LoadFACET.wl"];
source = "/home/maxzhang/factorization-and-loops/External/" <>
  "CodexExchange/codex_ff_m1_m2_2026-08-20/" <>
  "CodexM1ConstrainedAffinePrototype.wl";
stream = OpenRead[source];
expressions = ReadList[stream, Hold[Expression]];
Close[stream];
hits = Select[expressions,
  ! FreeQ[#, CodexM1BuildSampleSystem, Infinity] &];
Print["expression count = ", Length[expressions],
  "; builder hit count = ", Length[hits]];
Do[
  Print[index, ": bytes=", ByteCount[hits[[index]]],
    "; prefix=", StringTake[ToString[hits[[index]], InputForm],
      UpTo[180]]],
  {index, Length[hits]}];
