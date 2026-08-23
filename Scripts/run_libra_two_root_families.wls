#!/usr/bin/env wolframscript
(* Licensed parallel-kernel pool for all thirteen two-root families. *)

$HistoryLength = 0;
root = ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]];
argv = Rest[$ScriptCommandLine];
outputDirectory = ExpandFileName[If[Length[argv] >= 1, argv[[1]],
  "/home/maxzhang/FACET/Codex/General/LibraTwoRoot_20260819"]];
requestedKernels = If[Length[argv] >= 2, ToExpression[argv[[2]]], 8];
timeLimit = If[Length[argv] >= 3, ToExpression[argv[[3]]], 1800];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

families = {
  "CF232", "CF236", "CF240", "CF319", "CF321", "CF385", "CF408",
  "CF249", "CF254", "CF265", "CF226", "CF231", "CF305"
};
workerFile = FileNameJoin[{root, "Scripts", "LibraFamilyEpsFormWorker.wl"}];
loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];

CloseKernels[];
kernels = LaunchKernels[requestedKernels];
Print["[libra-pool] requested=", requestedKernels,
  " launched=", Length[kernels], " families=", Length[families]];
If[kernels === {}, Exit[2]];

ParallelEvaluate[$HistoryLength = 0, kernels];
With[{file = loadFile},
  ParallelEvaluate[Quiet[Block[{$Output = {}, $Messages = {}}, Get[file]]],
    kernels]];
With[{file = workerFile},
  ParallelEvaluate[Quiet[Block[{$Output = {}, $Messages = {}}, Get[file]]],
    kernels]];

evaluations = Map[
  Function[currentFamily,
    With[{fixedFamily = currentFamily, fixedOutput = outputDirectory,
      fixedLimit = timeLimit},
      ParallelSubmit[
        FACETBatch`RunLibraFamilyEpsForm[
        fixedFamily, fixedOutput, fixedLimit]]]],
  families];

remaining = evaluations;
results = {};
start = AbsoluteTime[];
While[remaining =!= {},
  {next, completedEvaluation, remaining} = WaitNext[remaining];
  AppendTo[results, next];
  Print["[libra-pool] completed=", Length[results], "/", Length[families],
    " family=", If[AssociationQ[next], Lookup[next, "Family", "?"], "?"],
    " status=", If[AssociationQ[next], Lookup[next, "Status", "?"], "?"],
    " elapsed=", Round[AbsoluteTime[] - start, 0.1], "s"];
  Flush[OutputStream["stdout", 1]]
];

CloseKernels[];
summary = <|"Families" -> families, "RequestedKernels" -> requestedKernels,
  "LaunchedKernels" -> Length[kernels],
  "Seconds" -> AbsoluteTime[] - start, "Results" -> results,
  "ExactEpsForms" -> Count[results,
    association_Association /; Lookup[association, "Status", None] === "EpsForm"],
  "Date" -> DateString[]|>;
Put[summary, FileNameJoin[{outputDirectory, "batch_summary.wl"}]];
Print["[libra-pool] exact_eps_forms=", summary["ExactEpsForms"],
  " unresolved=", Length[families] - summary["ExactEpsForms"]];
