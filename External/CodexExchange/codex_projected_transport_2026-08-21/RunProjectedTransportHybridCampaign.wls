#!/usr/bin/env wolframscript

(* Hybrid two-core campaign: one local subkernel runs a sequential half-queue
   asynchronously, while the licensed master kernel runs the other half.
   This uses QueueRun to dispatch the ParallelSubmit job before local work. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["Usage: RunProjectedTransportHybridCampaign.wls " <>
    "OUTPUT_DIRECTORY FAMILY ... [--compact|--candidate|--fast]"];
  Exit[64]
];

outputDirectory = ExpandFileName[First[arguments]];
remainingArguments = Rest[arguments];
mode = Which[
  MemberQ[remainingArguments, "--compact"], "CompactInvariantRefined",
  MemberQ[remainingArguments, "--candidate"],
    "InvariantRefinedNoTerminalProbe",
  MemberQ[remainingArguments, "--fast"], "NoTerminalProbe",
  True, "Baseline"
];
families = DeleteCases[remainingArguments,
  "--fast" | "--candidate" | "--compact"];
If[families === {}, Print["No families supplied"]; Exit[64]];

root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];
loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
standardFile = FileNameJoin[{bundle, "CodexProjectedTransportStandard.wl"}];
workerFile = FileNameJoin[{bundle, "CodexProjectedTransportWorker.wl"}];
fastFile = FileNameJoin[{bundle, "CodexProjectedTransportFastWordKernel.wl"}];
candidateFile = FileNameJoin[{bundle, "CodexObservableTransportCandidate.wl"}];
campaignFile = FileNameJoin[{outputDirectory, "campaign_result.wl"}];

needsFast = MemberQ[
  {"NoTerminalProbe", "InvariantRefinedNoTerminalProbe"}, mode];
needsCandidate = MemberQ[
  {"InvariantRefinedNoTerminalProbe", "CompactInvariantRefined"}, mode];
requiredFiles = Join[{loadFile, standardFile, workerFile},
  If[needsFast, {fastFile}, {}], If[needsCandidate, {candidateFile}, {}]];
If[! And @@ (FileExistsQ /@ requiredFiles),
  Print["Campaign source missing"]; Exit[66]];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

(* Load the exact same external stack in the master and one subkernel. *)
Get[loadFile];
If[needsCandidate,
  Block[{$Context = "FeynFacet`Private`",
      $ContextPath = {"FeynFacet`", "System`", "Global`"}},
    Get[candidateFile]]];
Get[standardFile];
If[needsFast, Get[fastFile]];
Get[workerFile];

launched = LaunchKernels[1];
actualSubkernels = Length[Kernels[]];
If[actualSubkernels > 0,
  With[{lf = loadFile, sf = standardFile, wf = workerFile,
      ff = fastFile, cf = candidateFile, mm = mode,
      nf = needsFast, nc = needsCandidate},
    ParallelEvaluate[
      $HistoryLength = 0;
      Get[lf];
      If[nc,
        Block[{$Context = "FeynFacet`Private`",
            $ContextPath = {"FeynFacet`", "System`", "Global`"}},
          Get[cf]]];
      Get[sf];
      If[nf, Get[ff]];
      Get[wf];
    ]
  ]
];

masterFamilies = families[[1 ;; ;; 2]];
subkernelFamilies = If[actualSubkernels > 0,
  families[[2 ;; ;; 2]], {}];
If[actualSubkernels === 0,
  masterFamilies = families;
  subkernelFamilies = {}];

Print["Projected hybrid campaign parent pid=", $ProcessID,
  "; local subkernels=", actualSubkernels,
  "; master families=", Length[masterFamilies],
  "; subkernel families=", Length[subkernelFamilies],
  "; mode=", mode];

started = AbsoluteTime[];
subJob = If[subkernelFamilies === {}, None,
  With[{rr = root, bb = bundle, oo = outputDirectory, mm = mode,
      ff = subkernelFamilies},
    ParallelSubmit[
      Map[CodexProjectedTransportWorker`CodexRunProjectedTransportWorker[
        rr, bb, #, oo, False, mm] &, ff]]
  ]
];
If[subJob =!= None, Parallel`Developer`QueueRun[]];

masterResults = Map[
  CodexProjectedTransportWorker`CodexRunProjectedTransportWorker[
    root, bundle, #, outputDirectory, False, mode] &,
  masterFamilies];
subkernelResults = If[subJob === None, {}, WaitAll[subJob]];

resultByFamily = Association@Map[
  Lookup[#, "Family", Missing["NoFamily"]] -> # &,
  Join[masterResults, subkernelResults]];
results = Lookup[resultByFamily, families,
  <|"Status" -> "MissingWorkerResult", "Exact" -> False|>];
finished = AbsoluteTime[];

campaign = <|
  "Status" -> If[AllTrue[results, TrueQ[Lookup[#, "Exact", False]] &],
    "AllExact", "SomeIncomplete"],
  "ExternalScope" -> "NoPackageEdits",
  "Architecture" -> "MasterPlusOneAsynchronousLocalSubkernel",
  "Mode" -> mode,
  "ActualSubkernels" -> actualSubkernels,
  "WorkerProcesses" -> 1 + actualSubkernels,
  "MasterFamilies" -> masterFamilies,
  "SubkernelFamilies" -> subkernelFamilies,
  "Families" -> families,
  "Results" -> results,
  "TotalWallSeconds" -> N[finished - started],
  "ParentProcessID" -> $ProcessID,
  "ParentKernelVersion" -> $Version,
  "SourceSHA256" -> <|
    "StandardWrapper" -> FileHash[standardFile, "SHA256", "HexString"],
    "Worker" -> FileHash[workerFile, "SHA256", "HexString"],
    "FastWordKernel" -> If[needsFast,
      FileHash[fastFile, "SHA256", "HexString"], None],
    "ObservableTransportCandidate" -> If[needsCandidate,
      FileHash[candidateFile, "SHA256", "HexString"], None],
    "ObservableTransportEngine" -> FileHash[
      FileNameJoin[{root, "FeynFacet", "Private", "ObservableTransport.wl"}],
      "SHA256", "HexString"]
  |>
|>;

temporary = campaignFile <> ".partial-" <> ToString[$ProcessID];
Put[campaign, temporary];
RenameFile[temporary, campaignFile, OverwriteTarget -> True];
Print[InputForm[campaign]];
If[campaign["Status"] =!= "AllExact", Exit[1]];
