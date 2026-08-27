(* Regenerate pre-IBP pair artifacts for any process card on the full
   forward x conjugate diagram grid, in parallel over subkernels.

   Usage:
     wolframscript -file Scripts/regenerate_pairs.wls \
       <processDirectory> <cardName> <resultName> [kernels]

   Example:
     wolframscript -file Scripts/regenerate_pairs.wls \
       ppHX_NNLO_DoubleReal UU_Ghost UU_Ghost_08_10_1 6

   The diagram grid is the card's own DiagramIndices declaration. Pair
   files are written to <processDirectory>/Results/<resultName>/Pairs;
   already-existing valid pair files are skipped, so an interrupted run
   resumes.

   [kernels] = N is the number of subkernels. All pairs go through ONE
   global dynamic queue: each worker takes the next pending pair the
   moment it frees up, so a slow pair costs one worker and never holds
   the others (the retired 4N-pair batches did). *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3,
  Print["Usage: regenerate_pairs.wls <processDirectory> <cardName> <resultName> [kernels]"];
  Exit[1]
];
processDirectory = FileNameJoin[{root, arguments[[1]]}];
cardName = arguments[[2]];
resultName = arguments[[3]];
kernelCount = If[Length[arguments] >= 4, ToExpression[arguments[[4]]], 6];

card = Get[FileNameJoin[{processDirectory, "Cards", cardName <> ".wl"}]];
If[! AssociationQ[card],
  Print["Could not read the card."];
  Exit[1]
];
forwardIndices = card["ForwardAmplitudes", "DiagramIndices"];
conjugateIndices = card["ConjugateAmplitudes", "DiagramIndices"];

resultDirectory = FileNameJoin[{processDirectory, "Results", resultName}];
pairDirectory = FileNameJoin[{resultDirectory, "Pairs"}];
If[! DirectoryQ[pairDirectory],
  CreateDirectory[pairDirectory, CreateIntermediateDirectories -> True]
];
scriptPath = ExpandFileName[$InputFileName];

pairFile[forward_, conjugate_] := FileNameJoin[{
  pairDirectory,
  "F" <> ToString[forward] <> "_C" <> ToString[conjugate] <> ".wl"
}];

pairSetup[forward_Integer, conjugate_Integer] := Join[
  card,
  <|
    "CardName" -> cardName,
    "SourceNotebook" -> scriptPath,
    "ForwardAmplitudes" -> Append[
      card["ForwardAmplitudes"], "SelectedIndex" -> forward
    ],
    "ConjugateAmplitudes" -> Append[
      card["ConjugateAmplitudes"], "SelectedIndex" -> conjugate
    ]
  |>
];

processPair[{forward_Integer, conjugate_Integer}] := Module[
  {setup, result, artifact, file},
  file = pairFile[forward, conjugate];
  If[FileExistsQ[file],
    Module[{saved = Quiet @ Check[Get[file], $Failed]},
      If[FeynFacet`Private`validPreIBPResultQ[saved],
        Return[{forward, conjugate, "Skipped"}]
      ]
    ]
  ];
  setup = pairSetup[forward, conjugate];
  result = FeynFacet`CollinearFactorizePreIBP[setup];
  If[! MatchQ[result, {_, _, _, _, _List}],
    Return[{forward, conjugate, "PreIBPFailed"}]
  ];
  artifact = FeynFacet`GenerateCollinearFactorizePreIBPResult[
    setup,
    result[[1]], result[[2]], result[[3]], result[[4]], result[[5]],
    resultDirectory
  ];
  If[! AssociationQ[artifact],
    Return[{forward, conjugate, "PackagingFailed"}]
  ];
  If[! FeynFacet`Private`validPreIBPResultQ[artifact],
    Return[{forward, conjugate, "ValidationFailed"}]
  ];
  Put[artifact, file];
  {forward, conjugate, "OK"}
];

(* processPair returns a status tuple for every failure it can see. The
   guard adds the two exits it cannot see -- an uncaught Throw and an
   Abort inside the pipeline -- so a worker always answers with a status
   for its own pair and one bad pair never drains the queue. *)
(* PAIRQUEUE-GUARD-BEGIN: Tests/Infrastructure/t_pair_queue_schedule.wls evaluates the
   source text between these markers against a synthetic worker; keep
   the markers when editing. *)
processPairGuarded[{forward_Integer, conjugate_Integer}] := Module[
  {outcome},
  outcome = CheckAbort[
    Catch[Catch[processPair[{forward, conjugate}], _, "QueueThrew" &]],
    "QueueAborted"
  ];
  Which[
    MatchQ[outcome, {_Integer, _Integer, _String}], outcome,
    outcome === "QueueThrew", {forward, conjugate, "PairThrew"},
    outcome === "QueueAborted", {forward, conjugate, "PairAborted"},
    True, {forward, conjugate, "PairError"}
  ]
];
(* PAIRQUEUE-GUARD-END *)

pairs = Tuples[{forwardIndices, conjugateIndices}];
Print["GRID: ", Length[forwardIndices], " x ", Length[conjugateIndices],
  " = ", Length[pairs], " pairs -> ", resultDirectory];

LaunchKernels[kernelCount];
With[{loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]},
  ParallelEvaluate[Block[{$Output = {}}, Quiet[Get[loadFile], General::shdw]]]
];
DistributeDefinitions[
  pairSetup, processPair, processPairGuarded, pairFile, card, cardName,
  scriptPath, resultDirectory, pairDirectory
];

(* ONE global dynamic queue over the whole grid. Every pair is submitted
   to the shared parallel queue up front, so a subkernel that finishes a
   pair immediately takes the next pending one and the kernels stay busy
   until the queue drains. The retired schedule partitioned the grid into
   batches of 4 kernelCount and ran ParallelMap per batch, which made
   every batch boundary a barrier: the slowest pair of a batch held all
   other kernels idle until it returned (Codex review 2026-08-24).

   Resumability is unchanged: the already-done test is the FileExistsQ +
   validPreIBPResultQ check inside processPair, so it stays on the
   workers (it costs a Get of the stored artifact) and a skipped pair
   still reports "Skipped". Completions are collected in whatever order
   they arrive and written back into grid order, so nothing downstream
   depends on the order in which pairs finish. *)
(* PAIRQUEUE-DRIVER-BEGIN: Tests/Infrastructure/t_pair_queue_schedule.wls evaluates the
   source text between these markers against a synthetic worker; keep
   the markers when editing. *)
pairTasks = Table[
  With[{pair = pairs[[i]]}, ParallelSubmit[processPairGuarded[pair]]],
  {i, Length[pairs]}
];
pairTaskIndex = AssociationThread[pairTasks -> Range[Length[pairTasks]]];
pairResults = ConstantArray[Missing["NotCompleted"], Length[pairs]];
completed = 0;
failedSoFar = 0;
pending = pairTasks;
While[pending =!= {},
  Module[{value, object, position, entry},
    {value, object, pending} = WaitNext[pending];
    position = Lookup[pairTaskIndex, Key[object], Missing["NotFound"]];
    If[MissingQ[position],
      Print["QUEUEWARNING: unmatched completion ", object, " -> ", value],
      entry = If[MatchQ[value, {_Integer, _Integer, _String}],
        value,
        Append[pairs[[position]], "PairError"]
      ];
      pairResults[[position]] = entry;
      completed++;
      If[! MemberQ[{"OK", "Skipped"}, entry[[3]]], failedSoFar++];
      Print["PROGRESS: ", completed, " / ", Length[pairs],
        "  failures: ", failedSoFar,
        "  F", entry[[1]], "_C", entry[[2]], " ", entry[[3]]]
    ]
  ]
];
summaries = MapIndexed[
  If[MatchQ[#1, {_Integer, _Integer, _String}], #1,
    Append[pairs[[First[#2]]], "QueueLost"]] &,
  pairResults
];
(* PAIRQUEUE-DRIVER-END *)

failures = Select[summaries, ! MemberQ[{"OK", "Skipped"}, #[[3]]] &];
Print["REGENERATED: ", Count[summaries, {_, _, "OK"}]];
Print["SKIPPED: ", Count[summaries, {_, _, "Skipped"}]];
Print["FAILURES: ", Length[failures]];
If[failures =!= {}, Print["FAILEDPAIRS: ", Take[failures, UpTo[20]]]];
Print["RESULTDIRECTORY: ", resultDirectory];
