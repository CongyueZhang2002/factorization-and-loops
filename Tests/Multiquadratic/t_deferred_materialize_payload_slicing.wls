#!/usr/bin/env wolframscript
(* Large singleton interning tasks receive only their own immutable operand
   slice.  The task-local ABI must be exactly equivalent to selecting the
   same batch from the historical shared payload, without making every pool
   helper parse and retain the complete operand forest. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, eps];
internTask = FeynFacet`Private`blockEquationDeferredInternTask;
expressions = Table[
  Expand[(index + x + 2 y)^8 + eps (1 + 2 x - y + index)^7]/
    ((1 + index + x)^3 (2 + index - y)^2), {index, 16}];
symbols = {x, y, eps};
batch = {7};
sharedPayload = <|"Expressions" -> expressions,
  "PolynomialSymbols" -> symbols|>;
slicedPayload = <|"Expressions" -> expressions[[batch]],
  "PolynomialSymbols" -> symbols|>;

sharedFile = CreateTemporary[];
slicedFile = CreateTemporary[];
Put[sharedPayload, sharedFile];
Put[slicedPayload, slicedFile];
sharedResult = internTask[sharedFile, batch];
slicedResult = internTask[slicedFile];

FTAssert["task-local interning is exactly the selected shared-payload result",
  SameQ[slicedResult, sharedResult] &&
    MatchQ[slicedResult, {{_, _Association}}]];

sharedBytes = FileByteCount[sharedFile];
slicedBytes = FileByteCount[slicedFile];
FTAssert["a singleton task avoids most of the shared serialized payload",
  IntegerQ[sharedBytes] && IntegerQ[slicedBytes] &&
    8 slicedBytes < sharedBytes];

Quiet[DeleteFile /@ {sharedFile, slicedFile}];
FTReport[];
