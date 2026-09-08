#!/usr/bin/env wolframscript

(* One licensed parent and at most two local subkernels.  The parent performs
   scheduling only; the two subkernels run independent families and persist
   large exact results themselves.  Running the parent under taskset on two
   CPUs gives a hard two-core ceiling while keeping the main kernel free. *)

$HistoryLength = 0;

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["Usage: RunProjectedTransportParallelCampaign.wls " <>
    "OUTPUT_DIRECTORY FAMILY ..."];
  Exit[64]
];

outputDirectory = ExpandFileName[First[arguments]];
remainingArguments = Rest[arguments];
mode = Which[
  MemberQ[remainingArguments, "--compact"],
    "CompactInvariantRefined",
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

If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];
If[! And @@ (FileExistsQ /@ Join[{loadFile, standardFile, workerFile},
      If[MemberQ[{"NoTerminalProbe", "InvariantRefinedNoTerminalProbe"},
          mode], {fastFile}, {}],
      If[MemberQ[{"InvariantRefinedNoTerminalProbe",
          "CompactInvariantRefined"}, mode], {candidateFile}, {}]]),
  Print["Campaign source missing"];
  Exit[66]
];

requestedKernels = 2;
launched = LaunchKernels[requestedKernels];
actualKernels = Length[Kernels[]];
If[actualKernels < 1,
  Print["No local subkernel could be initialized"];
  Exit[70]
];

Print["Projected campaign parent pid=", $ProcessID,
  "; local subkernels=", actualKernels,
  "; families=", Length[families], "; mode=", mode];

With[{lf = loadFile, sf = standardFile, wf = workerFile,
    ff = fastFile, cf = candidateFile, mm = mode},
  ParallelEvaluate[
    $HistoryLength = 0;
    Get[lf];
    If[MemberQ[{"InvariantRefinedNoTerminalProbe",
        "CompactInvariantRefined"}, mm],
      Block[{$Context = "FeynFacet`Private`",
          $ContextPath = {"FeynFacet`", "System`", "Global`"}},
        Get[cf]]];
    Get[sf];
    If[MemberQ[{"NoTerminalProbe", "InvariantRefinedNoTerminalProbe"}, mm],
      Get[ff]];
    Get[wf];
  ]
];

started = AbsoluteTime[];
results = With[{rr = root, bb = bundle, oo = outputDirectory, mm = mode},
  ParallelMap[
    CodexProjectedTransportWorker`CodexRunProjectedTransportWorker[
      rr, bb, #, oo, False, mm] &,
    families,
    Method -> "FinestGrained"
  ]
];
finished = AbsoluteTime[];

campaign = <|
  "Status" -> If[AllTrue[results, TrueQ[Lookup[#, "Exact", False]] &],
    "AllExact", "SomeIncomplete"],
  "ExternalScope" -> "NoPackageEdits",
  "Architecture" -> "OneFreeParentPlusTwoLocalWorkers",
  "Mode" -> mode,
  "RequestedWorkerKernels" -> requestedKernels,
  "ActualWorkerKernels" -> actualKernels,
  "Families" -> families,
  "Results" -> results,
  "TotalWallSeconds" -> N[finished - started],
  "ParentProcessID" -> $ProcessID,
  "ParentKernelVersion" -> $Version,
  "SourceSHA256" -> <|
    "StandardWrapper" -> FileHash[standardFile, "SHA256", "HexString"],
    "Worker" -> FileHash[workerFile, "SHA256", "HexString"],
    "FastWordKernel" -> If[
      MemberQ[{"NoTerminalProbe", "InvariantRefinedNoTerminalProbe"}, mode],
      FileHash[fastFile, "SHA256", "HexString"], None],
    "ObservableTransportCandidate" -> If[
      MemberQ[{"InvariantRefinedNoTerminalProbe",
        "CompactInvariantRefined"}, mode],
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
