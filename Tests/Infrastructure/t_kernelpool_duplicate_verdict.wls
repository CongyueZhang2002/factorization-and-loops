#!/usr/bin/env wolframscript
(* Regression test for B2 (2026-09-02): the KernelPool server filed a
   passed mission under duplicates/ with Wall 0 because its own re-dispatch
   of a never-started mission drained as DUPLICATE while the first
   evaluation had written an OK result sidecar (baseline batch attempt 1,
   03:16-03:21: a passing 261 s test vanished from done/).

   The verdict logic now lives in ONE function of Scripts/KernelPool.wls,
   poolVerdictFromDrain[drained, sidecarFile], evaluated here VERBATIM from
   the source (the pool script cannot be loaded without starting a server,
   and a planted claim cannot reproduce the race: the dispatcher's
   stale-record hygiene deletes claims before every dispatch).

   Acceptance criteria:
   (a) a drained DUPLICATE with an OK sidecar yields the sidecar record
       (Status OK, its Wall);
   (b) a drained OK record is the verdict even when a sidecar exists;
   (c) a drained non-record ($Failed) falls back to the sidecar;
   (d) a drained DUPLICATE without a sidecar stays DUPLICATE;
   (e) the source still routes the collected mission through this function. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

source = Import[FileNameJoin[{root, "Scripts", "KernelPool.wls"}], "Text"];
start = StringPosition[source, "poolVerdictFromDrain[drained_, sidecarFile_String] :="];
FTAssert["the verdict function is defined once in the pool source", Length[start] === 1];
body = StringTake[source, {start[[1, 1]], -1}];
endPos = StringPosition[body, "\n  res];\n"];
definition = StringTake[body, {1, endPos[[1, 2]]}];
Begin["KPVerdictTest`"];
ToExpression[definition];
End[];
verdict = KPVerdictTest`poolVerdictFromDrain;
FTAssert["the definition evaluated from the source",
  Length[DownValues[KPVerdictTest`poolVerdictFromDrain]] === 1];

dir = CreateDirectory[];
sidecar = FileNameJoin[{dir, "dup_probe.kernel.result"}];
okRecord = <|"Mission" -> "dup_probe.wl", "Status" -> "OK", "HadMessages" -> False,
  "Wall" -> 261.7, "Kernel" -> 3, "Result" -> 0|>;
Put[okRecord, sidecar];
duplicate = <|"Mission" -> "dup_probe.wl", "Status" -> "DUPLICATE", "Kernel" -> 5, "Wall" -> 0.|>;
drainedOK = <|"Mission" -> "dup_probe.wl", "Status" -> "OK", "Wall" -> 12.5, "Kernel" -> 5, "Result" -> 0|>;

FTAssert["(a) DUPLICATE with an OK sidecar yields the sidecar verdict",
  verdict[duplicate, sidecar] === okRecord];
FTAssert["(b) a drained OK record stays the verdict when a sidecar exists",
  verdict[drainedOK, sidecar] === drainedOK];
FTAssert["(c) a drained non-record falls back to the sidecar",
  verdict[$Failed, sidecar] === okRecord];
DeleteFile[sidecar];
FTAssert["(d) DUPLICATE without a sidecar stays DUPLICATE",
  verdict[duplicate, sidecar] === duplicate];
FTAssert["(e) the server collects through the verdict function",
  StringContainsQ[source, "res = poolVerdictFromDrain[Quiet[Check[WaitAll[eid], $Failed]], kf <> \".result\"];"]];
DeleteDirectory[dir, DeleteContents -> True];
FTReport[];
