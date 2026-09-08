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
  study, "NNLOSelectedMasterCoefficients_SizeMonotone_01"
}];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];

Get[loader];
Clear[$PrePrint];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]
];

sourceManifest = Get[FileNameJoin[{sourceDirectory, "ShardManifest.wl"}]];
coverageFile = FileNameJoin[{cleanDirectory, "CoverageCertificate.wl"}];
coverage = Get[coverageFile];
If[! TrueQ[coverage["Verified"]], Print["COVERAGE_NOT_VERIFIED"]; Quit[2]];
selectedMasters = sourceManifest["SelectedMasters"];
cleanFiles = Sort[FileNames["CleanedEntries_*.bin", cleanDirectory]];

ClearAll[readMasterData];
readMasterData[file_String, master_] := Module[{data, masterData},
  data = FeynFacet`Private`coefficientReadRecord[file];
  masterData = Lookup[data["Masters"], master, <||>];
  If[Lookup[masterData, "EntryCount", 0] > 0,
    <|
      "Fractions" -> masterData["Fractions"],
      "DenominatorHashes" -> masterData["DenominatorHashes"]
    |>,
    <|"Fractions" -> {}, "DenominatorHashes" -> {}|>
  ]
];

ClearAll[mergeExactPairGroup];
mergeExactPairGroup[pairs_List] := Module[
  {
    denominator, numerator, rawPair, cancelled, cancelledPair,
    seconds, outcome, preferredPair, preference
  },
  If[Length[pairs] === 1, Return[<|
    "Outcome" -> "Unchanged",
    "Pair" -> First[pairs],
    "DenominatorHash" -> Hash[Last[First[pairs]], "SHA256", "HexString"],
    "Seconds" -> 0.,
    "InputBytes" -> ByteCount[pairs],
    "RawBytes" -> ByteCount[First[pairs]],
    "CancelledBytes" -> Missing["NotNeeded"],
    "OutputBytes" -> ByteCount[First[pairs]]
  |>]];
  denominator = Last[First[pairs]];
  numerator = Total[First /@ pairs];
  If[TrueQ[numerator === 0], Return[<|
    "Outcome" -> "Zero",
    "Pair" -> {0, 1},
    "DenominatorHash" -> Hash[1, "SHA256", "HexString"],
    "Seconds" -> 0.,
    "InputBytes" -> ByteCount[pairs],
    "RawBytes" -> 0,
    "CancelledBytes" -> 0,
    "OutputBytes" -> 0
  |>]];
  rawPair = {numerator, denominator};
  {seconds, cancelled} = AbsoluteTiming[
    TimeConstrained[
      MemoryConstrained[
        Quiet @ Check[Cancel[numerator/denominator], $Failed],
        3 1024^3,
        $MemoryExceeded
      ],
      300,
      $TimedOut
    ]
  ];
  outcome = Which[
    cancelled === $TimedOut, "TimedOut",
    cancelled === $MemoryExceeded, "MemoryExceeded",
    cancelled === $Failed, "Failed",
    True, "Computed"
  ];
  cancelledPair = If[
    outcome === "Computed",
    {Numerator[cancelled], Denominator[cancelled]},
    Missing["NotComputed"]
  ];
  If[ListQ[cancelledPair] && ByteCount[cancelledPair] < ByteCount[rawPair],
    preferredPair = cancelledPair;
    preference = "Cancelled",
    preferredPair = rawPair;
    preference = "Raw"
  ];
  <|
    "Outcome" -> If[outcome === "Computed", preference, outcome],
    "Pair" -> preferredPair,
    "DenominatorHash" -> Hash[
      Last[preferredPair], "SHA256", "HexString"
    ],
    "Seconds" -> seconds,
    "InputBytes" -> ByteCount[pairs],
    "RawBytes" -> ByteCount[rawPair],
    "CancelledBytes" -> If[
      ListQ[cancelledPair], ByteCount[cancelledPair], Missing["NotComputed"]
    ],
    "OutputBytes" -> ByteCount[preferredPair]
  |>
];

ClearAll[mergeHashJob];
mergeHashJob[pairs_List] := Module[{exactGroups},
  exactGroups = If[
    AllTrue[Rest[pairs], SameQ[Last[#], Last[First[pairs]]] &],
    {pairs},
    Gather[pairs, SameQ[Last[#1], Last[#2]] &]
  ];
  mergeExactPairGroup /@ exactGroups
];

ClearAll[sizeMonotoneConsolidation];
sizeMonotoneConsolidation[inputRecords_List, maxIterations_: 4] := Module[
  {records, jobs, results, nonzero, nextRecords, history, iteration},
  records = inputRecords;
  history = {};
  For[iteration = 1, iteration <= maxIterations, iteration++,
    jobs = Values[GroupBy[records, First -> Last]];
    jobs = Reverse[SortBy[jobs, Length]];
    results = Flatten[
      ParallelMap[mergeHashJob, jobs, Method -> "FinestGrained"],
      1
    ];
    nonzero = Select[results, Lookup[#, "Outcome"] =!= "Zero" &];
    nextRecords = ({#1["DenominatorHash"], #1["Pair"]} &) /@ nonzero;
    AppendTo[history, <|
      "Iteration" -> iteration,
      "InputFractions" -> Length[records],
      "HashGroups" -> Length[jobs],
      "OutputFractions" -> Length[nextRecords],
      "OutputHashGroups" -> Length[DeleteDuplicates[First /@ nextRecords]],
      "InputBytes" -> ByteCount[Last /@ records],
      "OutputBytes" -> ByteCount[Last /@ nextRecords],
      "OutcomeCounts" -> Counts[Lookup[results, "Outcome"]],
      "WorkerSeconds" -> Total[Lookup[results, "Seconds"]]
    |>];
    If[
      Length[DeleteDuplicates[First /@ nextRecords]] === Length[nextRecords],
      records = nextRecords;
      Break[]
    ];
    records = nextRecords;
    Clear[jobs, results, nonzero, nextRecords]
  ];
  <|"Fractions" -> Last /@ records, "History" -> history|>
];

ClearAll[boundedWholeCoefficient];
boundedWholeCoefficient[pairs_List] := Module[{candidate, seconds},
  If[Length[pairs] > 1000 || ByteCount[pairs] > 50 1024^2,
    Return[<|"Outcome" -> "NotAttempted", "Bytes" -> ByteCount[pairs]|>]
  ];
  {seconds, candidate} = AbsoluteTiming[
    TimeConstrained[
      MemoryConstrained[
        Quiet @ Check[
          Cancel[Together[Total[(First[#]/Last[#]) & /@ pairs]]],
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
DistributeDefinitions[mergeExactPairGroup, mergeHashJob];

masterResults = {};
Do[
  {readSeconds, chunks} = AbsoluteTiming[
    readMasterData[#, master] & /@ cleanFiles
  ];
  fractions = Join @@ Lookup[chunks, "Fractions"];
  denominatorHashes = Join @@ Lookup[chunks, "DenominatorHashes"];
  records = MapThread[{#1, #2} &, {denominatorHashes, fractions}];
  Clear[chunks];
  {consolidationSeconds, consolidated} = AbsoluteTiming[
    sizeMonotoneConsolidation[records]
  ];
  finalPairs = consolidated["Fractions"];
  whole = boundedWholeCoefficient[finalPairs];
  result = <|
    "MasterIndex" -> First @ FirstPosition[selectedMasters, master],
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
      coverageFile, "SHA256", "HexString"
    ],
    "Fractions" -> finalPairs
  |>;
  If[Lookup[whole, "Outcome"] === "Computed",
    AssociateTo[result, "WholeCoefficient" -> whole["Coefficient"]]
  ];
  file = FileNameJoin[{
    outputDirectory,
    "MasterCoefficient_" <> IntegerString[result["MasterIndex"], 10, 3] <>
      ".bin"
  }];
  FeynFacet`Private`coefficientWriteRecord[file, result];
  summary = KeyDrop[result, {"Fractions", "WholeCoefficient"}];
  AppendTo[masterResults, Join[summary, <|
    "OutputFile" -> file,
    "OutputFileBytes" -> FileByteCount[file],
    "OutputFileHash" -> FileHash[file, "SHA256", "HexString"]
  |>]];
  Put[masterResults, FileNameJoin[{outputDirectory, "Progress.wl"}]];
  Print[
    "Master ", result["MasterIndex"], ": ", Length[fractions],
    " entries -> ", Length[finalPairs], " fractions; ",
    ByteCount[fractions], " -> ", ByteCount[finalPairs], " bytes"
  ];
  Clear[
    fractions, denominatorHashes, records, consolidated,
    finalPairs, whole, result
  ],
  {master, selectedMasters}
];
CloseKernels[kernels];

manifest = <|
  "Method" -> "SizeMonotoneExactEqualDenominatorConsolidation",
  "Kernels" -> 8,
  "Masters" -> masterResults,
  "CoverageCertificateHash" -> FileHash[
    coverageFile, "SHA256", "HexString"
  ]
|>;
Put[manifest, FileNameJoin[{outputDirectory, "Manifest.wl"}]];
Print[InputForm[manifest]];
Quit[];
