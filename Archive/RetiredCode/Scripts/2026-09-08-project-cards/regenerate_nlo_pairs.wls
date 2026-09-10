(* Regenerate the NLO UU 10x10 pre-IBP pair artifacts with the current
   package, writing a fresh result directory that carries the current
   analytic context (including CoefficientKinematics).

   Usage: wolframscript -file Scripts/regenerate_nlo_pairs.wls [resultName]
   Default resultName: UU_08_10_10x10_regen                      *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

resultName = If[Length[Rest[$ScriptCommandLine]] >= 1,
  First[Rest[$ScriptCommandLine]],
  "UU_08_10_10x10_regen"
];
resultDirectory = FileNameJoin[{root, "ppHX_NLO", "Results", resultName}];
pairDirectory = FileNameJoin[{resultDirectory, "Pairs"}];
If[! DirectoryQ[pairDirectory],
  CreateDirectory[pairDirectory, CreateIntermediateDirectories -> True]
];

card = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
diagramIndices = Range[10];
scriptPath = ExpandFileName[$InputFileName];

pairSetup[forward_Integer, conjugate_Integer] := Join[
  card,
  <|
    "CardName" -> "UU",
    "SourceNotebook" -> scriptPath,
    "ForwardAmplitudes" -> Join[
      card["ForwardAmplitudes"],
      <|"DiagramIndices" -> diagramIndices, "SelectedIndex" -> forward|>
    ],
    "ConjugateAmplitudes" -> Join[
      card["ConjugateAmplitudes"],
      <|"DiagramIndices" -> diagramIndices, "SelectedIndex" -> conjugate|>
    ]
  |>
];

processPair[{forward_Integer, conjugate_Integer}] := Module[
  {setup, result, artifact, file},
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
  file = FileNameJoin[{
    pairDirectory,
    "F" <> ToString[forward] <> "_C" <> ToString[conjugate] <> ".wl"
  }];
  Put[artifact, file];
  {forward, conjugate, "OK"}
];

pairs = Tuples[{diagramIndices, diagramIndices}];

LaunchKernels[6];
With[{loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]},
  ParallelEvaluate[Block[{$Output = {}}, Quiet[Get[loadFile], General::shdw]]]
];
DistributeDefinitions[
  pairSetup, processPair, card, diagramIndices, scriptPath,
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
      "  failures so far: ",
      Count[summaries, {_, _, status_} /; status =!= "OK"]]
  ],
  {batch, Partition[pairs, UpTo[24]]}
];

failures = Select[summaries, #[[3]] =!= "OK" &];
Print["REGENERATED: ", Count[summaries, {_, _, "OK"}]];
Print["FAILURES: ", Length[failures]];
If[failures =!= {}, Print["FAILEDPAIRS: ", failures]];
Print["RESULTDIRECTORY: ", resultDirectory];
