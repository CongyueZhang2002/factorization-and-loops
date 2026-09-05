$HistoryLength = 0;
Global`$FACETKernelLimit = 8;
root = "/home/maxzhang/FACET";
study = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "HadronicSimplification"
}];
sourceDirectory = FileNameJoin[{
  study, "NNLOSelectedMasterColumns_SmallMedianHard_03"
}];
cleanDirectory = FileNameJoin[{
  study, "NNLOEntryFirstInvariantCleanup_01"
}];
outputDirectory = FileNameJoin[{
  study, "NNLOSelectedMasterCoefficients_01"
}];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];

Get[loader];
Clear[$PrePrint];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]
];

sourceManifest = Get[FileNameJoin[{sourceDirectory, "ShardManifest.wl"}]];
coverage = Get[FileNameJoin[{cleanDirectory, "CoverageCertificate.wl"}]];
If[! TrueQ[coverage["Verified"]],
  Print["CLEAN_ENTRY_COVERAGE_NOT_VERIFIED"];
  Quit[2]
];
allSelectedMasters = sourceManifest["SelectedMasters"];
selectedMasters = allSelectedMasters;
masterSpec = Quiet[Environment["FACET_MASTER_INDICES"]];
If[StringQ[masterSpec] && StringLength[StringTrim[masterSpec]] > 0,
  requestedMasterIndices = ToExpression /@ StringSplit[masterSpec, ","];
  selectedMasters = allSelectedMasters[[requestedMasterIndices]]
];
cleanFiles = Sort[FileNames["CleanedEntries_*.bin", cleanDirectory]];

ClearAll[readMasterData];
readMasterData[file_String, master_] := Module[{data, masterData},
  data = FeynFacet`Private`coefficientReadRecord[file];
  masterData = Lookup[data["Masters"], master, <||>];
  If[
    AssociationQ[masterData] &&
      IntegerQ[Lookup[masterData, "EntryCount", 0]] &&
      Lookup[masterData, "EntryCount", 0] > 0,
    <|
      "Fractions" -> masterData["Fractions"],
      "DenominatorHashes" -> masterData["DenominatorHashes"]
    |>,
    <|"Fractions" -> {}, "DenominatorHashes" -> {}|>
  ]
];

ClearAll[splitDenominatorHashGroup];
splitDenominatorHashGroup[pairs_List] := Module[{denominator, exactGroups},
  If[pairs === {}, Return[{}]];
  denominator = Last[First[pairs]];
  If[AllTrue[Rest[pairs], SameQ[Last[#], denominator] &],
    Return[{{denominator, First /@ pairs}}]
  ];
  exactGroups = Gather[
    pairs,
    SameQ[Last[#1], Last[#2]] &
  ];
  ({Last[First[#]], First /@ #} &) /@ exactGroups
];

ClearAll[exactDenominatorJobs];
exactDenominatorJobs[records_List] := Join @@ Map[
  splitDenominatorHashGroup,
  Values @ GroupBy[records, First -> Last]
];

ClearAll[consolidateDenominatorJob];
consolidateDenominatorJob[job_List] := Module[
  {denominator, numerators, numerator, candidate, outcome, seconds, pair},
  denominator = First[job];
  numerators = Last[job];
  {seconds, candidate} = AbsoluteTiming[
    numerator = Total[numerators];
    If[TrueQ[numerator === 0], Return[<|
      "Outcome" -> "Zero", "Pair" -> {0, 1},
      "DenominatorHash" -> Hash[1, "SHA256", "HexString"],
      "Seconds" -> 0.
    |>]];
    candidate = TimeConstrained[
      MemoryConstrained[
        Quiet @ CheckAbort[
          Check[Cancel[numerator/denominator], $Failed],
          $Failed
        ],
        3 1024^3,
        $MemoryExceeded
      ],
      180,
      $TimedOut
    ];
    outcome = Which[
      candidate === $TimedOut, "TimedOut",
      candidate === $MemoryExceeded, "MemoryExceeded",
      candidate === $Failed, "Failed",
      True, "Cancelled"
    ];
    pair = If[
      outcome === "Cancelled",
      {Numerator[candidate], Denominator[candidate]},
      {numerator, denominator}
    ];
    {outcome, pair}
  ];
  If[AssociationQ[candidate], Return[candidate]];
  <|
    "Outcome" -> First[candidate],
    "Pair" -> Last[candidate],
    "Seconds" -> seconds,
    "InputBytes" -> ByteCount[job],
    "OutputBytes" -> ByteCount[Last[candidate]],
    "PairHash" -> Hash[Last[candidate], "SHA256", "HexString"],
    "DenominatorHash" -> Hash[
      Last[Last[candidate]], "SHA256", "HexString"
    ]
  |>
];

ClearAll[exactDenominatorConsolidation];
exactDenominatorConsolidation[inputRecords_List, maxIterations_: 4] := Module[
  {
    recordsIn, jobs, recordsOut, newRecords, nextJobs,
    history, iteration
  },
  recordsIn = inputRecords;
  history = {};
  For[iteration = 1, iteration <= maxIterations, iteration++,
    jobs = exactDenominatorJobs[recordsIn];
    jobs = Reverse @ SortBy[jobs, ByteCount];
    recordsOut = ParallelMap[
      consolidateDenominatorJob,
      jobs,
      Method -> "FinestGrained"
    ];
    newRecords = DeleteCases[
      MapThread[
        {#1, #2} &,
        {
          Lookup[recordsOut, "DenominatorHash"],
          Lookup[recordsOut, "Pair"]
        }
      ],
      {_, {0, 1}}
    ];
    nextJobs = exactDenominatorJobs[newRecords];
    AppendTo[history, <|
      "Iteration" -> iteration,
      "InputFractions" -> Length[recordsIn],
      "InputBytes" -> ByteCount[recordsIn],
      "EqualDenominatorGroups" -> Length[jobs],
      "OutputFractions" -> Length[newRecords],
      "DistinctOutputDenominators" -> Length[nextJobs],
      "OutputBytes" -> ByteCount[newRecords],
      "OutcomeCounts" -> Counts[Lookup[recordsOut, "Outcome"]],
      "WorkerSeconds" -> Total[Lookup[recordsOut, "Seconds"]]
    |>];
    recordsIn = newRecords;
    Clear[jobs, recordsOut, newRecords];
    If[Length[nextJobs] === Length[recordsIn], Break[]];
    Clear[nextJobs]
  ];
  <|"Fractions" -> Last /@ recordsIn, "History" -> history|>
];

ClearAll[boundedWholeCoefficient];
boundedWholeCoefficient[pairs_List] := Module[{candidate, seconds},
  If[Length[pairs] > 1000 || ByteCount[pairs] > 50 1024^2,
    Return[<|"Outcome" -> "NotAttempted", "Bytes" -> ByteCount[pairs]|>]
  ];
  {seconds, candidate} = AbsoluteTiming[
    TimeConstrained[
      MemoryConstrained[
        Quiet @ CheckAbort[
          Check[
            Cancel[Together[Total[(First[#]/Last[#]) & /@ pairs]]],
            $Failed
          ],
          $Failed
        ],
        6 1024^3,
        $MemoryExceeded
      ],
      600,
      $TimedOut
    ]
  ];
  <|
    "Outcome" -> Which[
      candidate === $TimedOut, "TimedOut",
      candidate === $MemoryExceeded, "MemoryExceeded",
      candidate === $Failed, "Failed",
      True, "Computed"
    ],
    "Seconds" -> seconds,
    "Bytes" -> If[
      MemberQ[{$TimedOut, $MemoryExceeded, $Failed}, candidate],
      Missing["NotComputed"],
      ByteCount[candidate]
    ],
    "Coefficient" -> candidate
  |>
];

CloseKernels[];
kernels = LaunchKernels[8];
With[{load = loader},
  ParallelEvaluate[
    $HistoryLength = 0;
    Block[{$Output = {}, $Messages = {}}, Quiet[Get[load]]];
    Clear[$PrePrint],
    kernels
  ]
];
DistributeDefinitions[consolidateDenominatorJob];

masterResults = {};
Do[
  {readSeconds, chunks} = AbsoluteTiming[
    readMasterData[#, master] & /@ cleanFiles
  ];
  fractions = Join @@ Lookup[chunks, "Fractions"];
  denominatorHashes = Join @@ Lookup[chunks, "DenominatorHashes"];
  inputRecords = MapThread[
    {#1, #2} &,
    {denominatorHashes, fractions}
  ];
  Clear[chunks];
  {consolidationSeconds, consolidated} = AbsoluteTiming[
    exactDenominatorConsolidation[inputRecords]
  ];
  finalPairs = consolidated["Fractions"];
  whole = boundedWholeCoefficient[finalPairs];
  result = <|
    "MasterIndex" -> First @ FirstPosition[allSelectedMasters, master],
    "Master" -> master,
    "EntryCount" -> Length[fractions],
    "LeafCount" -> sourceManifest["ObservedMasterLeaves"][master],
    "ReadSeconds" -> readSeconds,
    "InputBytes" -> ByteCount[fractions],
    "ConsolidationSeconds" -> consolidationSeconds,
    "ConsolidationHistory" -> consolidated["History"],
    "FinalFractionCount" -> Length[finalPairs],
    "FinalBytes" -> ByteCount[finalPairs],
    "ExactData" -> FreeQ[finalPairs, _Real],
    "IntegerSPowers" -> FreeQ[
      finalPairs,
      Power[base_, exponent_] /; (
        ! IntegerQ[exponent] && ! FreeQ[base, Global`s]
      )
    ],
    "WholeOutcome" -> KeyDrop[whole, "Coefficient"],
    "CoverageCertificateHash" -> FileHash[
      FileNameJoin[{cleanDirectory, "CoverageCertificate.wl"}],
      "SHA256",
      "HexString"
    ],
    "Fractions" -> finalPairs
  |>;
  If[Lookup[whole, "Outcome"] === "Computed",
    AssociateTo[result, "WholeCoefficient" -> whole["Coefficient"]]
  ];
  outputFile = FileNameJoin[{
    outputDirectory,
    "MasterCoefficient_" <>
      IntegerString[result["MasterIndex"], 10, 3] <> ".bin"
  }];
  FeynFacet`Private`coefficientWriteRecord[outputFile, result];
  summary = KeyDrop[result, {"Fractions", "WholeCoefficient"}];
  AppendTo[masterResults, Join[summary, <|
    "OutputFile" -> outputFile,
    "OutputFileBytes" -> FileByteCount[outputFile],
    "OutputFileHash" -> FileHash[outputFile, "SHA256", "HexString"]
  |>]];
  Put[
    masterResults,
    FileNameJoin[{outputDirectory, "Progress.wl"}]
  ];
  Print[
    "Master ", result["MasterIndex"], ": ", Length[fractions],
    " entries -> ", Length[finalPairs], " exact fractions"
  ];
  Clear[
    fractions, denominatorHashes, inputRecords,
    consolidated, finalPairs, whole, result
  ],
  {master, selectedMasters}
];
CloseKernels[kernels];

manifest = <|
  "Method" -> "ExactEqualDenominatorConsolidation",
  "Kernels" -> 8,
  "Masters" -> masterResults,
  "CoverageCertificateHash" -> FileHash[
    FileNameJoin[{cleanDirectory, "CoverageCertificate.wl"}],
    "SHA256",
    "HexString"
  ]
|>;
Put[manifest, FileNameJoin[{outputDirectory, "Manifest.wl"}]];
Print[InputForm[manifest]];
Quit[];
