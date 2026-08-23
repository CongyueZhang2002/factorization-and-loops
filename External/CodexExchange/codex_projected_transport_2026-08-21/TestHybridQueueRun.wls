#!/usr/bin/env wolframscript

(* External-only scheduler smoke test: the master and one local subkernel each
   wait for five seconds.  Correct asynchronous dispatch completes in about
   five seconds rather than ten. *)

$HistoryLength = 0;
CloseKernels[];
If[Length[LaunchKernels[1]] =!= 1,
  Print["Could not launch exactly one local subkernel."];
  Exit[70]
];

started = AbsoluteTime[];
job = ParallelSubmit[
  Pause[5];
  <|"ProcessID" -> $ProcessID, "KernelID" -> $KernelID|>
];
Parallel`Developer`QueueRun[];
master = <|"ProcessID" -> $ProcessID, "KernelID" -> $KernelID|>;
Pause[5];
subkernel = WaitAll[job];
elapsed = N[AbsoluteTime[] - started];

Print[<|
  "ElapsedSeconds" -> elapsed,
  "Master" -> master,
  "Subkernel" -> subkernel,
  "Concurrent" -> TrueQ[elapsed < 8]
|>];

CloseKernels[];
If[TrueQ[elapsed < 8], Exit[0], Exit[71]];
