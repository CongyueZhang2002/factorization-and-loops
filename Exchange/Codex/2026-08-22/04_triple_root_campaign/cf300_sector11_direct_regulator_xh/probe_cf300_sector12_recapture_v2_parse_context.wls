#!/usr/bin/env wolframscript

(* Read-only clean-worker gate for the V2 recapture source.  It reproduces
   kpsubmit's held ToExpression parse in a disposable context and proves that
   parsing does not intern any symbol in the wrapper's dedicated runtime
   context or Global`.  It never Gets the wrapper and writes no files. *)

$HistoryLength = 0;
Module[
  {wrapper, expectedWrapperHash, hashHex, sourceText, sourceLines,
   parseText, parseContext, dedicatedNamesBefore, dedicatedNamesAfter,
   parseNamesBefore, parseNamesAfter, globalBefore, globalAfter,
   parsed, parseMessages, parsedHeadQ, dedicatedUnchangedQ,
   globalUnchangedQ, parseContextPopulatedQ, parseContextCleanedQ,
   preflightTag, fail, cleanupParseContext, result, probeResult},

  wrapper = FileNameJoin[{DirectoryName[ExpandFileName[$InputFileName]],
    "run_cf300_sector12_recapture_from_v4_xh_v2.wls"}];
  expectedWrapperHash =
    "8667a863f0fe60a8fc59080880c7736ee76114189bb1b49196c342a2f2a9ccbb";
  parseContext = "CodexCF300Sector12RecaptureV2ParseProbe`";
  preflightTag = Unique["CF300S12RecaptureV2ParseProbe$"];
  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file],
      IntegerString[FileHash[file, "SHA256"], 16, 64],
      Missing["NotFound"]], Missing["HashFailed"]]];
  fail[message_String, detail_: None] := (
    Print["CF300 S12 RECAPTURE V2 PARSE-CONTEXT PROBE FAIL: " <>
      message, If[detail === None, "", InputForm[detail]]];
    Throw[$Failed, preflightTag]);
  cleanupParseContext[] := (
    parsed =.;
    Quiet[System`Remove[
      "CodexCF300Sector12RecaptureV2ParseProbe`*"]]);

  probeResult = Catch[
  If[hashHex[wrapper] =!= expectedWrapperHash,
    fail["wrapper hash drift"]];
  If[! IntegerQ[$KernelID] || $KernelID <= 0 || Length[Kernels[]] =!= 0,
    fail["requires one pool worker and no nested kernels"]];

  dedicatedNamesBefore =
    System`Join[System`Names["CodexCF300Sector12RecaptureV2`*"],
      System`Names["CodexCF300Sector12RecaptureV2`Private`*"]];
  parseNamesBefore =
    System`Names["CodexCF300Sector12RecaptureV2ParseProbe`*"];
  globalBefore = System`Names["Global`*"];
  If[dedicatedNamesBefore =!= {} || parseNamesBefore =!= {},
    fail["worker context is not clean ",
      <|"Dedicated" -> dedicatedNamesBefore,
        "Parse" -> parseNamesBefore|>]];

  sourceText = Quiet[Check[Import[wrapper, "Text"], $Failed]];
  If[! StringQ[sourceText],
    fail["source import"]];
  sourceLines = StringSplit[sourceText, "\n"];
  parseText = If[sourceLines =!= {} &&
      StringStartsQ[First[sourceLines], "#!"],
    StringRiffle[Rest[sourceLines], "\n"], sourceText];

  Block[{$MessageList = {}},
    parsed = CheckAbort[
      Block[{$Context = parseContext, $ContextPath = {"System`"}},
        Quiet[Check[
          ToExpression[parseText, InputForm, HoldComplete], $Failed]]],
      cleanupParseContext[]; Abort[]];
    parseMessages = ToString[InputForm[#1]] & /@ $MessageList];
  parsedHeadQ = Head[parsed] === HoldComplete;
  dedicatedNamesAfter =
    System`Join[System`Names["CodexCF300Sector12RecaptureV2`*"],
      System`Names["CodexCF300Sector12RecaptureV2`Private`*"]];
  parseNamesAfter =
    System`Names["CodexCF300Sector12RecaptureV2ParseProbe`*"];
  globalAfter = System`Names["Global`*"];
  dedicatedUnchangedQ = SameQ[dedicatedNamesAfter, dedicatedNamesBefore];
  globalUnchangedQ = SameQ[globalAfter, globalBefore];
  parseContextPopulatedQ = Length[parseNamesAfter] > 0;

  cleanupParseContext[];
  parseContextCleanedQ =
    System`Names["CodexCF300Sector12RecaptureV2ParseProbe`*"] === {};
  result = <|
    "Status" -> "CF300Sector12RecaptureV2ParseContextProbe",
    "WrapperSHA256" -> expectedWrapperHash,
    "ParsedHeadHoldCompleteQ" -> parsedHeadQ,
    "ParseMessages" -> parseMessages,
    "DedicatedContextUnchangedQ" -> dedicatedUnchangedQ,
    "GlobalContextUnchangedQ" -> globalUnchangedQ,
    "DisposableParseContextPopulatedQ" -> parseContextPopulatedQ,
    "DisposableParseContextCleanedQ" -> parseContextCleanedQ,
    "WorkerKernelID" -> $KernelID,
    "NestedKernelCount" -> Length[Kernels[]]|>;
  Print["CF300 S12 RECAPTURE V2 PARSE-CONTEXT PROBE ",
    InputForm[result]];
  If[TrueQ[parsedHeadQ && parseMessages === {} &&
      dedicatedUnchangedQ && globalUnchangedQ &&
      parseContextPopulatedQ && parseContextCleanedQ],
    0, fail["one or more exact parse/context gates failed", result]],
  preflightTag];
  probeResult
]
