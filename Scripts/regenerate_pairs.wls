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
   resumes. *)

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

pairs = Tuples[{forwardIndices, conjugateIndices}];
Print["GRID: ", Length[forwardIndices], " x ", Length[conjugateIndices],
  " = ", Length[pairs], " pairs -> ", resultDirectory];

LaunchKernels[kernelCount];
With[{loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]},
  ParallelEvaluate[Block[{$Output = {}}, Quiet[Get[loadFile], General::shdw]]]
];
DistributeDefinitions[
  pairSetup, processPair, pairFile, card, cardName, scriptPath,
  resultDirectory, pairDirectory
];

completed = 0;
summaries = {};
Do[
  Module[{batchResults},
    batchResults = ParallelMap[
      processPair, batch, Method -> "FinestGrained"
    ];
    summaries = Join[summaries, batchResults];
    completed += Length[batch];
    Print["PROGRESS: ", completed, " / ", Length[pairs],
      "  failures: ",
      Count[summaries, {_, _, status_} /;
        ! MemberQ[{"OK", "Skipped"}, status]]]
  ],
  {batch, Partition[pairs, UpTo[4 kernelCount]]}
];

failures = Select[summaries, ! MemberQ[{"OK", "Skipped"}, #[[3]]] &];
Print["REGENERATED: ", Count[summaries, {_, _, "OK"}]];
Print["SKIPPED: ", Count[summaries, {_, _, "Skipped"}]];
Print["FAILURES: ", Length[failures]];
If[failures =!= {}, Print["FAILEDPAIRS: ", Take[failures, UpTo[20]]]];
Print["RESULTDIRECTORY: ", resultDirectory];
