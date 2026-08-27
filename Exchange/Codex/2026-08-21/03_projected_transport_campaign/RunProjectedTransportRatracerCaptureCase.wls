#!/usr/bin/env wolframscript

(* One external, verbose compact-transport capture run.  It uses the licensed
   main kernel only, launches no subkernels, and never writes into FeynFacet.
   CODEX_RATRACER_CAPTURE_DIRECTORY makes the external candidate persist the
   first large coordinate system and stop before symbolic LinearSolve. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["Usage: RunProjectedTransportRatracerCaptureCase.wls " <>
    "FAMILY OUTPUT_DIRECTORY"];
  Exit[64]
];

family = arguments[[1]];
outputDirectory = ExpandFileName[arguments[[2]]];
root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];
loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
candidateFile = FileNameJoin[{bundle,
  "CodexObservableTransportRatracerCandidate.wl"}];
standardFile = FileNameJoin[{bundle,
  "CodexProjectedTransportStandard.wl"}];
workerFile = FileNameJoin[{bundle,
  "CodexProjectedTransportCoordinateWorker.wl"}];

If[! And @@ (FileExistsQ /@ {loadFile, candidateFile, standardFile,
    workerFile}),
  Print["Diagnostic source missing"];
  Exit[66]
];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

Get[loadFile];
Block[{$Context = "FeynFacet`Private`",
    $ContextPath = {"FeynFacet`", "System`", "Global`"}},
  Get[candidateFile]];
Get[standardFile];
Get[workerFile];

Print[DateString[{"ISODate", " ", "Time"}],
  " diagnostic ratracer-capture compact transport family=", family,
  " pid=", $ProcessID, " kernels=", Length[Kernels[]]];
result = CodexProjectedTransportWorker`CodexRunProjectedTransportWorker[
  root, bundle, family, outputDirectory, True,
  "CompactInvariantRefined"];
Print[InputForm[result]];

If[! TrueQ[Lookup[result, "Exact", False]], Exit[1]];
