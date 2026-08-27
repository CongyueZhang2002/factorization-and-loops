#!/usr/bin/env wolframscript

$HistoryLength = 0;
Module[{resultFile, expectedHash, messages = {}, result, gate},
  resultFile =
    "/home/maxzhang/factorization-and-loops/External/CodexExchange/" <>
    "triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/" <>
    "cf300_sector11_postwrite_formal_inspector_v4_result.json";
  expectedHash =
    "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128";
  If[Length[Rest[$ScriptCommandLine]] =!= 0,
    Print["CF300_POSTWRITE_FORMAL_IMPORT_PROBE FAIL takes no arguments"];
    System`Exit[64]];
  Block[{$MessageList = {}},
    result = Quiet[CheckAbort[Import[resultFile, "RawJSON"], $Aborted]];
    messages = ToString[InputForm[#1]] & /@ $MessageList];
  gate = TrueQ[
    IntegerQ[$KernelID] && $KernelID > 0 && Length[Kernels[]] === 0 &&
    FileExistsQ[resultFile] && FileByteCount[resultFile] === 966 &&
    FileHash[resultFile, "SHA256", "HexString"] === expectedHash &&
    messages === {} && AssociationQ[result] &&
    Lookup[result, "Status", None] === "PASS" &&
    Lookup[result, "FormalPrefixEntriesChecked", None] === 968 &&
    Lookup[result, "FormalEpsilonNonzeroChannels", None] === 317 &&
    Lookup[result, "FormalZeroChannels", None] === 651 &&
    Lookup[result, "AlgebraicallyEliminatedInputChannels", None] ===
      {{1, 22, 11}}];
  Print["CF300_POSTWRITE_FORMAL_IMPORT_PROBE ",
    InputForm[<|"GateQ" -> gate, "KernelID" -> $KernelID,
      "NestedKernelCount" -> Length[Kernels[]], "Messages" -> messages,
      "ResultHead" -> Head[result]|>]];
  System`Exit[If[gate, 0, 2]]]
