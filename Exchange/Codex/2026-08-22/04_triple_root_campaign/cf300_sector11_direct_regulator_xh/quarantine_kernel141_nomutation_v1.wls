#!/usr/bin/env wolframscript

(* Hold the reused, namespace-contaminated pool worker out of subsequent
   dispatch without changing its Wolfram state.  Release is cooperative via
   an explicit sentinel; no signal, abort, kernel launch, or process control
   is used. *)

$HistoryLength = 0;
Module[{exitTag, releaseFile, counter = 0, outcome},
  exitTag = Unique["CodexKernel141QuarantineV1$"];
  releaseFile =
    "/tmp/codex-triple-root-20260823c.vx654S/quarantine141.release";
  outcome = Catch[
    If[! IntegerQ[$KernelID] || $KernelID =!= 141,
      Print["KERNEL141 QUARANTINE V1 FAIL: dispatched to kernel ",
        InputForm[$KernelID]];
      Throw[$Failed, exitTag]];
    If[Length[Kernels[]] =!= 0 ||
        ! TrueQ[ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
          KernelPoolMission`$TaskBrokerMaxHelpers === 0],
      Print["KERNEL141 QUARANTINE V1 FAIL: helper contract violated"];
      Throw[$Failed, exitTag]];
    If[FileExistsQ[releaseFile],
      Print["KERNEL141 QUARANTINE V1 FAIL: stale release sentinel"];
      Throw[$Failed, exitTag]];
    Print["KERNEL141 QUARANTINE V1 START: no mutation; cooperative " <>
      "release sentinel=", releaseFile];
    While[! FileExistsQ[releaseFile],
      Pause[5];
      counter++;
      If[Mod[counter, 12] === 0,
        Print["KERNEL141 QUARANTINE V1 heartbeat=", counter/12,
          " kernel=", $KernelID]]];
    Print["KERNEL141 QUARANTINE V1 RELEASED cooperatively"];
    0,
    exitTag];
  outcome
]
