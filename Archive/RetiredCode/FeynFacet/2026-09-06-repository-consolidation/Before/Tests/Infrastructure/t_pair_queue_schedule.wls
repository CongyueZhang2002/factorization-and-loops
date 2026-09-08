#!/usr/bin/env wolframscript
(* Scheduling test for Scripts/regenerate_pairs.wls.

   The script fans the forward x conjugate pair grid out over subkernels.
   Until 2026-08-24 it partitioned the grid into batches of 4N and called
   ParallelMap per batch, so every batch boundary was a barrier: the
   slowest pair of a batch held the other kernels idle until it returned
   (Codex review, Exchange/Codex/2026-08-24/02_parallelism_advice.md).
   It now submits every pair to ONE global dynamic queue and collects
   completions with WaitNext.

   This test evaluates the SOURCE TEXT of the script's two marked
   scheduling regions (PAIRQUEUE-GUARD, PAIRQUEUE-DRIVER) against a
   synthetic worker, so the production scheduler itself is exercised
   without the pre-IBP workload. The pair semantics (what a pair is, when
   it is skipped, how the artifact is written) live in processPair and
   are not touched here.

   Acceptance criteria:
   A. Static: the edited script parses (held parse, no evaluation), both
      marked regions are present, parse on their own, and the retired
      batch schedule is gone (no ParallelMap, no Partition of the pairs).
      Asserted on the PARSED script, never on its text, so that prose
      about the retired schedule cannot register as a call site.
   B. Drain: with N = 2 workers all 16 synthetic pairs complete; every
      pair appears exactly once and the summary is in grid order, not in
      completion order.
   C. Per-pair error handling: a pair that reports a failure status, a
      pair that throws out of the pipeline and a pair that aborts are
      each recorded with their own status, and the queue still drains.
   D. Skip: a pair whose worker reports "Skipped" is carried through as
      "Skipped" (the resumability path of processPair).
   E. Identity: the queued summary equals the summary the retired 4N
      batch schedule produces on the same synthetic workers.
   F. No barrier: two 3 s pairs placed in what used to be two different
      batches run concurrently. Wall time of the queue must be below
      0.75 x the wall time of the batch schedule. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

scriptPath = FileNameJoin[{root, "Scripts", "regenerate_pairs.wls"}];
source = Import[scriptPath, "Text"];

(* ---------- A. static checks ---------- *)

FTTest`FTAssert["campaign script is readable", StringQ[source]];

heldScript = Quiet@ToExpression[source, InputForm, Hold];
FTTest`FTAssert["edited script parses (held parse, nothing evaluated)",
  MatchQ[heldScript, _Hold] && Length[heldScript] > 10];

(* These are asserted against the PARSED script, not its text: comments
   are gone from a held parse, so a schedule word inside the comment that
   documents the retired design cannot be mistaken for a live call site.
   The first version of this test matched the source text and failed on
   its own explanatory comment. *)
FTTest`FTAssert["queue primitives present (ParallelSubmit + WaitNext)",
  MatchQ[heldScript, _Hold] &&
    ! FreeQ[heldScript, ParallelSubmit] && ! FreeQ[heldScript, WaitNext]];
FTTest`FTAssert["retired batch schedule removed (no live ParallelMap call)",
  MatchQ[heldScript, _Hold] && FreeQ[heldScript, ParallelMap]];
FTTest`FTAssert["retired batch schedule removed (pairs are not partitioned)",
  MatchQ[heldScript, _Hold] && FreeQ[heldScript, Partition]];

(* The two scheduling regions are extracted by their marker comments:
   text starts after the closing *) of the BEGIN comment and ends at the
   opening (* of the END comment. *)
extractRegion[name_String] := Module[
  {begin, end, closes, opens},
  begin = StringPosition[source, "PAIRQUEUE-" <> name <> "-BEGIN"];
  end = StringPosition[source, "PAIRQUEUE-" <> name <> "-END"];
  If[Length[begin] =!= 1 || Length[end] =!= 1, Return[$Failed]];
  closes = Select[StringPosition[source, "*)"], First[#] > begin[[1, 2]] &];
  opens = Select[StringPosition[source, "(*"], Last[#] < end[[1, 1]] &];
  If[closes === {} || opens === {}, Return[$Failed]];
  StringTake[source, {First[closes][[2]] + 1, Last[opens][[1]] - 1}]
];

guardText = extractRegion["GUARD"];
driverText = extractRegion["DRIVER"];
FTTest`FTAssert["guard region delimited exactly once and non-empty",
  StringQ[guardText] && StringLength[StringTrim[guardText]] > 0];
FTTest`FTAssert["driver region delimited exactly once and non-empty",
  StringQ[driverText] && StringLength[StringTrim[driverText]] > 0];

heldGuard = If[StringQ[guardText],
  Quiet@ToExpression[guardText, InputForm, Hold], $Failed];
heldDriver = If[StringQ[driverText],
  Quiet@ToExpression[driverText, InputForm, Hold], $Failed];
FTTest`FTAssert["guard region parses on its own", MatchQ[heldGuard, _Hold]];
FTTest`FTAssert["driver region parses on its own", MatchQ[heldDriver, _Hold]];
FTTest`FTAssert["driver region carries the whole queue (submit, wait, summary)",
  MatchQ[heldDriver, _Hold] &&
    ! FreeQ[heldDriver, ParallelSubmit] &&
    ! FreeQ[heldDriver, WaitNext] &&
    ! FreeQ[heldDriver, summaries]];

If[! (MatchQ[heldGuard, _Hold] && MatchQ[heldDriver, _Hold]),
  Print["Cannot run the scheduling checks without both regions."];
  FTTest`FTReport[]
];

(* ---------- synthetic workload ---------- *)

(* 4 x 4 grid, Tuples order. Index 1 = {1,1} is the already-done pair,
   5 = {2,1} reports a failure status, 6 = {2,2} throws out of the
   pipeline, 7 = {2,3} aborts, 8 = {2,4} and 9 = {3,1} are the slow
   pairs. With N = 2 and the retired 4N = 8 batch size the two slow
   pairs fall into different batches and are serialized; the queue runs
   them concurrently. *)
workerCount = 2;
grid = Range[4];
pairs = Tuples[{grid, grid}];
slowSeconds = 3.0;
shortSeconds = 0.05;

processPair[{forward_Integer, conjugate_Integer}] := Which[
  {forward, conjugate} === {1, 1},
    {forward, conjugate, "Skipped"},
  {forward, conjugate} === {2, 1},
    {forward, conjugate, "PreIBPFailed"},
  {forward, conjugate} === {2, 2},
    Throw[$Failed, "syntheticPipelineTag"],
  {forward, conjugate} === {2, 3},
    Abort[],
  MemberQ[{{2, 4}, {3, 1}}, {forward, conjugate}],
    Pause[slowSeconds]; {forward, conjugate, "OK"},
  True,
    Pause[shortSeconds]; {forward, conjugate, "OK"}
];

LaunchKernels[workerCount];
ReleaseHold[heldGuard];
DistributeDefinitions[processPair, processPairGuarded, slowSeconds,
  shortSeconds];

expected = Map[
  Which[
    # === {1, 1}, Append[#, "Skipped"],
    # === {2, 1}, Append[#, "PreIBPFailed"],
    # === {2, 2}, Append[#, "PairThrew"],
    # === {2, 3}, Append[#, "PairAborted"],
    True, Append[#, "OK"]
  ] &,
  pairs
];

(* ---------- B, C, D, F: the queue ---------- *)

Print["-- global dynamic queue, ", workerCount, " workers"];
queuedTiming = AbsoluteTiming[ReleaseHold[heldDriver]];
queuedWall = First[queuedTiming];
queuedSummaries = summaries;
Print["QUEUEDWALL: ", Round[queuedWall, 0.01], " s"];

FTTest`FTAssert["queue drains: one entry per pair",
  Length[queuedSummaries] === Length[pairs]];
FTTest`FTAssert["every pair completed exactly once",
  Sort[queuedSummaries[[All, {1, 2}]]] === Sort[pairs]];
FTTest`FTAssert["summary is in grid order, not completion order",
  queuedSummaries[[All, {1, 2}]] === pairs];
FTTest`FTAssert["no pair was lost by the queue",
  ! MemberQ[queuedSummaries[[All, 3]], "QueueLost" | "PairError"]];
FTTest`FTAssert["failing pair recorded with its own status, queue continued",
  MemberQ[queuedSummaries, {2, 1, "PreIBPFailed"}]];
FTTest`FTAssert["throwing pair recorded, queue continued",
  MemberQ[queuedSummaries, {2, 2, "PairThrew"}]];
FTTest`FTAssert["aborting pair recorded, queue continued",
  MemberQ[queuedSummaries, {2, 3, "PairAborted"}]];
FTTest`FTAssert["already-complete pair skipped",
  MemberQ[queuedSummaries, {1, 1, "Skipped"}]];
FTTest`FTAssert["every status is the one its worker reported",
  queuedSummaries === expected];
FTTest`FTAssert["failure count of the run is exactly the three bad pairs",
  Count[queuedSummaries, {_, _, s_} /;
    ! MemberQ[{"OK", "Skipped"}, s]] === 3];

(* ---------- E, F: the retired batch schedule as reference ---------- *)

(* Same workers, same guard, only the scheduling differs: this is the
   4N-batch code that was replaced. *)
Print["-- retired 4N batch schedule, ", workerCount, " workers"];
batchedTiming = AbsoluteTiming[
  Module[{acc = {}},
    Do[
      acc = Join[acc,
        ParallelMap[processPairGuarded, batch, Method -> "FinestGrained"]],
      {batch, Partition[pairs, UpTo[4 workerCount]]}
    ];
    acc
  ]
];
batchedWall = First[batchedTiming];
batchedSummaries = Last[batchedTiming];
Print["BATCHEDWALL: ", Round[batchedWall, 0.01], " s"];

FTTest`FTAssert["queued summary is identical to the batched summary",
  queuedSummaries === batchedSummaries];
FTTest`FTAssert["batch barrier reproduced by the reference schedule (two slow pairs serialized)",
  batchedWall > 1.8 slowSeconds];
FTTest`FTAssert["queue removes the barrier: wall < 0.75 x batched wall",
  queuedWall < 0.75 batchedWall];

Print["SPEEDUP: ", Round[batchedWall/queuedWall, 0.01], " x"];

CloseKernels[];
FTTest`FTReport[];
