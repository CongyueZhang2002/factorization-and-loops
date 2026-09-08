#!/usr/bin/env wolframscript

Module[{arguments, source, lines, parseText, parsed, messages,
    syntaxLength, heldHead},
  arguments = Rest[$ScriptCommandLine];
  If[Length[arguments] =!= 1 || ! FileExistsQ[First[arguments]],
    Print["WOLFRAM_PARSE_DIAGNOSTIC invalid input"];
    System`Exit[64]];
  source = Import[First[arguments], "Text"];
  If[! StringQ[source],
    Print["WOLFRAM_PARSE_DIAGNOSTIC import failed"];
    System`Exit[65]];
  lines = StringSplit[source, "\n"];
  parseText = If[lines =!= {} &&
      StringStartsQ[First[lines], "#!"],
    StringRiffle[Rest[lines], "\n"], source];
  messages = {};
  Block[{$MessageList = {}},
    parsed = Quiet[Check[
      ToExpression[parseText, InputForm, HoldComplete], $Failed]];
    messages = ToString[InputForm[#]] & /@ $MessageList];
  syntaxLength = Quiet[Check[SyntaxLength[parseText], $Failed]];
  heldHead = If[parsed === $Failed, "$Failed",
    ToString[Head[parsed], InputForm]];
  Print["WOLFRAM_PARSE_DIAGNOSTIC result=",
    InputForm[<|"File" -> ExpandFileName[First[arguments]],
      "Bytes" -> StringLength[source],
      "ParsedHead" -> heldHead,
      "SyntaxLength" -> syntaxLength,
      "Messages" -> messages|>]];
  System`Exit[If[Head[parsed] === HoldComplete, 0, 2]]]
