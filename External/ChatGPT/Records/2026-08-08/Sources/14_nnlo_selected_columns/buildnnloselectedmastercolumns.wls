$HistoryLength = 0;
Global`$FACETKernelLimit = 3;

root = "/home/maxzhang/FACET";
studyDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "HadronicSimplification"
}];
physicalTargetDirectory = FileNameJoin[{studyDirectory, "NNLOPhysicalTargets"}];
kiraStoreDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "CoefficientSimplification",
  "UU_08_05_1", "KiraStore"
}];
outputDirectory = FileNameJoin[{
  studyDirectory, "NNLOSelectedMasterColumns_SmallMedianHard_01"
}];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
commonFile = FileNameJoin[{
  root, "Codex", "ppHX_NLO", "HadronicSimplification", "TTOrdering",
  "Common.wl"
}];
fractionRingFile = FileNameJoin[{studyDirectory, "NNLOFractionRing.wl"}];

Get[loader];
Get[commonFile];
Get[fractionRingFile];
Clear[$PrePrint];

physicalManifest = Get[FileNameJoin[{physicalTargetDirectory, "Manifest.wl"}]];
catalogue = Get[FileNameJoin[{studyDirectory, "NNLOMasterColumnCatalogue.wl"}]];
metadata = FeynFacet`Private`coefficientReadRecord[
  FeynFacet`Private`coefficientStoreMetadataFile[kiraStoreDirectory]
];
context = Get[FileNameJoin[{studyDirectory, "NNLOHadronicContext.wl"}]];
If[
  ! AssociationQ[physicalManifest] || ! AssociationQ[catalogue] ||
    ! AssociationQ[metadata] || physicalManifest["Timeouts"] =!= 0 ||
    physicalManifest["Failures"] =!= 0,
  Print["SELECTED_COLUMN_INPUT_ERROR"];
  Quit[1]
];

catalogueRows = Select[
  catalogue["Catalogue"],
  Lookup[#, "ProductBytes", 0] > 0 &
];
selection = DeleteDuplicatesBy[
  {
    First @ SortBy[catalogueRows, Lookup[#, "ProductBytes"] &],
    catalogue["MedianProductBytes"],
    First[catalogue["LargestProductBytes"]]
  },
  Lookup[#, "Master"] &
];
selectedMasters = Lookup[selection, "Master"];
selectedSet = AssociationThread[
  selectedMasters,
  ConstantArray[True, Length[selectedMasters]]
];
masterPositions = AssociationThread[
  metadata["Masters"],
  Range[Length[metadata["Masters"]]]
];

If[
  ! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]
];
selectionFile = FileNameJoin[{outputDirectory, "Selection.wl"}];
If[
  FileExistsQ[selectionFile] && Get[selectionFile] =!= selection,
  Print["SELECTED_COLUMN_SELECTION_MISMATCH"];
  Quit[1]
];
Put[selection, selectionFile];

readRuleShard[file_String] := Module[{rules = <||>, count},
  count = FeynFacet`Private`coefficientScanRecords[
    file,
    Function[record,
      If[! AssociationQ[record], Return[$Failed]];
      KeyValueMap[AssociateTo[rules, #1 -> #2] &, record];
      True
    ]
  ];
  If[count === $Failed, $Failed, rules]
];

physicalImageCoefficient[value_] := Module[{physical},
  physical = ttPhysicalizeExpressions[
    {value /. metadata["ReverseRules"]},
    <|
      "DimensionRule" -> metadata["DimensionRule"],
      "HadronicVariables" -> context["HadronicVariables"]
    |>
  ];
  If[
    ! ListQ[physical] || Length[physical] =!= 1 ||
      ! ttExactDataQ[physical],
    Return[$Failed]
  ];
  physical = ttCanonicalCoefficient[First[physical], context["BranchRules"]];
  If[
    FreeQ[physical, Alternatives @@ nnloFractionVariables],
    physical,
    $Failed
  ]
];

processSelectedShard[job_Association] := Module[
  {
    targets, rules, leaves = AssociationThread[
      selectedMasters,
      ConstantArray[{}, Length[selectedMasters]]
    ], imageCache = <||>, imageKey, rhs, image, imageCoefficient, leaf,
    timedOut = 0,
    failureCount = 0, output, seconds, summary
  },
  targets = FeynFacet`Private`coefficientReadRecord[job["TargetFile"]];
  rules = readRuleShard[job["RuleFile"]];
  If[! AssociationQ[targets] || ! AssociationQ[rules], Return[$Failed]];
  seconds = First @ AbsoluteTiming[
    KeyValueMap[
      Function[{target, targetCoefficient},
        rhs = Lookup[rules, target, target];
        image = FeynFacet`Private`linearIntegralSum[rhs];
        If[FailureQ[image] || ! TrueQ[image["Remainder"] === 0],
          Return[$Failed, Module]
        ];
        KeyValueMap[
          Function[{master, rawImageCoefficient},
            If[KeyExistsQ[selectedSet, master],
              imageKey = HoldComplete[rawImageCoefficient];
              imageCoefficient = If[
                KeyExistsQ[imageCache, imageKey],
                imageCache[imageKey],
                With[{physical = physicalImageCoefficient[rawImageCoefficient]},
                  AssociateTo[imageCache, imageKey -> physical];
                  physical
                ]
              ];
              If[imageCoefficient === $Failed, Return[$Failed, Module]];
              leaf = nnloFractionLeaf[
                targetCoefficient imageCoefficient,
                60
              ];
              Which[
                leaf === $TimedOut,
                  timedOut++,
                leaf === $Failed,
                  failureCount++,
                True,
                  leaves[master] = Prepend[leaves[master], leaf]
              ]
            ]
          ],
          image["Terms"]
        ]
      ],
      targets
    ]
  ];
  If[timedOut =!= 0 || failureCount =!= 0, Return[$Failed]];
  output = AssociationMap[nnloMergeFractionLeaves[leaves[#]] &, selectedMasters];
  If[
    FeynFacet`Private`coefficientWriteRecord[job["OutputFile"], output] === $Failed,
    Return[$Failed]
  ];
  summary = <|
    "Shard" -> job["Shard"],
    "Seconds" -> seconds,
    "Targets" -> Length[targets],
    "Leaves" -> Total[Length /@ Values[leaves]],
    "DenominatorGroups" -> Total[Length /@ Values[output]],
    "Timeouts" -> timedOut,
    "Failures" -> failureCount,
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "KernelID" -> $KernelID
  |>;
  Put[summary, job["SummaryFile"]];
  Clear[targets, rules, leaves, imageCache, output];
  ClearSystemCache[];
  summary
];

jobs = Table[
  <|
    "Shard" -> shard,
    "TargetFile" -> FeynFacet`Private`coefficientShardFile[
      physicalTargetDirectory, "PhysicalTargets", shard
    ],
    "RuleFile" -> FeynFacet`Private`coefficientShardFile[
      kiraStoreDirectory, "Rules", shard
    ],
    "OutputFile" -> FeynFacet`Private`coefficientShardFile[
      outputDirectory, "SelectedColumns", shard
    ],
    "SummaryFile" -> FileNameJoin[{
      outputDirectory,
      "Summary_" <> IntegerString[shard, 10, 4] <> ".wl"
    }]
  |>,
  {shard, physicalManifest["ShardCount"]}
];
jobs = Reverse @ SortBy[
  jobs,
  FileByteCount[#1["TargetFile"]] + FileByteCount[#1["RuleFile"]] &
];

pendingJobs = Select[
  jobs,
  ! FileExistsQ[#1["OutputFile"]] || ! FileExistsQ[#1["SummaryFile"]] &
];

If[pendingJobs =!= {},
  CloseKernels[];
  kernels = LaunchKernels[3];
  With[{load = loader, common = commonFile, fractionRing = fractionRingFile},
    ParallelEvaluate[
      $HistoryLength = 0;
      Block[{$Output = {}, $Messages = {}}, Quiet[Get[load]]];
      Get[common];
      Get[fractionRing];
      Clear[$PrePrint],
      kernels
    ]
  ];
  DistributeDefinitions[
    metadata, context, selectedMasters, selectedSet,
    readRuleShard, physicalImageCoefficient, processSelectedShard
  ];
  {shardWallSeconds, pendingShardSummaries} = AbsoluteTiming[
    ParallelMap[processSelectedShard, pendingJobs, Method -> "FinestGrained"]
  ];
  CloseKernels[kernels],
  shardWallSeconds = 0.;
  pendingShardSummaries = {}
];
If[MemberQ[pendingShardSummaries, $Failed],
  Put[
    pendingShardSummaries,
    FileNameJoin[{outputDirectory, "FailedShardRun.wl"}]
  ];
  Print["SELECTED_COLUMN_SHARD_ERROR"];
  Quit[2]
];
shardSummaries = Get /@ Lookup[jobs, "SummaryFile"];

masterInputFiles = AssociationMap[
  Function[master,
    FileNameJoin[{
      outputDirectory,
      "MasterEntries_" <>
        IntegerString[masterPositions[master], 10, 4] <> ".bin"
    }]
  ],
  selectedMasters
];
DeleteFile /@ Select[Values[masterInputFiles], FileExistsQ];
Scan[
  Function[file,
    shardData = FeynFacet`Private`coefficientReadRecord[file];
    If[! AssociationQ[shardData], Print["COLUMN_TRANSPOSE_ERROR"]; Quit[3]];
    Scan[
      Function[master,
        If[
          FeynFacet`Private`coefficientAppendRecord[
            masterInputFiles[master],
            Lookup[shardData, master, {}]
          ] === $Failed,
          Print["COLUMN_TRANSPOSE_ERROR"];
          Quit[3]
        ]
      ],
      selectedMasters
    ];
    Clear[shardData]
  ],
  Lookup[jobs, "OutputFile"]
];

nnloLayeredHardCleanup[expression_, workerAssumptions_] := Module[
  {
    current = expression, candidate, equality, basis, stageRecords = {},
    inputBytes = ByteCount[expression], time, accepted
  },
  If[inputBytes <= 64 1024^2,
    {time, candidate} = AbsoluteTiming[
      ttFrozenWholeRationalMerge[current, 180]
    ];
    equality = If[
      MemberQ[{$Failed, $TimedOut}, candidate],
      False,
      TrueQ[nnloExactZeroQ[candidate - current, 120]]
    ];
    accepted = equality && ByteCount[candidate] <= ByteCount[current];
    AppendTo[stageRecords, <|
      "Stage" -> "ExactRationalMerge",
      "Seconds" -> time,
      "InputBytes" -> ByteCount[current],
      "CandidateBytes" -> If[MemberQ[{$Failed, $TimedOut}, candidate], Missing["NotAvailable"], ByteCount[candidate]],
      "Equality" -> equality,
      "Accepted" -> accepted,
      "Outcome" -> Which[candidate === $TimedOut, "TimedOut", candidate === $Failed, "Failed", True, "Computed"]
    |>];
    If[accepted, current = candidate],
    AppendTo[stageRecords, <|
      "Stage" -> "ExactRationalMerge",
      "InputBytes" -> inputBytes,
      "Outcome" -> "SkippedAbove64MiB",
      "Accepted" -> False
    |>]
  ];
  basis = ttHistoricalFunctionalBasis[current];
  If[basis =!= {} && ByteCount[current] <= 64 1024^2,
    {time, candidate} = AbsoluteTiming[
      TimeConstrained[
        Collect[
          current,
          basis,
          Factor[Cancel[Together[#]]] &
        ],
        180,
        $TimedOut
      ]
    ];
    equality = If[
      MemberQ[{$Failed, $TimedOut}, candidate],
      False,
      TrueQ[nnloExactZeroQ[candidate - current, 120]]
    ];
    accepted = equality && ByteCount[candidate] <= ByteCount[current];
    AppendTo[stageRecords, <|
      "Stage" -> "FunctionalBasisCollect",
      "BasisCount" -> Length[basis],
      "Seconds" -> time,
      "InputBytes" -> ByteCount[current],
      "CandidateBytes" -> If[MemberQ[{$Failed, $TimedOut}, candidate], Missing["NotAvailable"], ByteCount[candidate]],
      "Equality" -> equality,
      "Accepted" -> accepted,
      "Outcome" -> Which[candidate === $TimedOut, "TimedOut", candidate === $Failed, "Failed", True, "Computed"]
    |>];
    If[accepted, current = candidate],
    AppendTo[stageRecords, <|
      "Stage" -> "FunctionalBasisCollect",
      "BasisCount" -> Length[basis],
      "Outcome" -> If[basis === {}, "NoAnalyticMasterBasis", "SkippedAbove64MiB"],
      "Accepted" -> False
    |>]
  ];
  If[ByteCount[current] <= 32 1024^2,
    {time, candidate} = AbsoluteTiming[
      TimeConstrained[
        Simplify[current, Assumptions -> workerAssumptions],
        300,
        $TimedOut
      ]
    ];
    equality = If[
      MemberQ[{$Failed, $TimedOut}, candidate],
      False,
      TimeConstrained[
        TrueQ @ FullSimplify[
          candidate == current,
          Assumptions -> workerAssumptions
        ],
        120,
        False
      ]
    ];
    accepted = equality && ByteCount[candidate] <= ByteCount[current];
    AppendTo[stageRecords, <|
      "Stage" -> "AssumptionSimplify",
      "Seconds" -> time,
      "InputBytes" -> ByteCount[current],
      "CandidateBytes" -> If[MemberQ[{$Failed, $TimedOut}, candidate], Missing["NotAvailable"], ByteCount[candidate]],
      "Equality" -> equality,
      "Accepted" -> accepted,
      "Outcome" -> Which[candidate === $TimedOut, "TimedOut", candidate === $Failed, "Failed", True, "Computed"]
    |>];
    If[accepted, current = candidate],
    AppendTo[stageRecords, <|
      "Stage" -> "AssumptionSimplify",
      "InputBytes" -> ByteCount[current],
      "Outcome" -> "SkippedAbove32MiB",
      "Accepted" -> False
    |>]
  ];
  <|
    "Expression" -> current,
    "InputBytes" -> inputBytes,
    "OutputBytes" -> ByteCount[current],
    "Stages" -> stageRecords
  |>
];

processCompleteColumn[job_Association] := Module[
  {
    entries = {}, recordCount, grouped, column, certificate,
    hard, cleanup,
    seconds, outputRecord, summary
  },
  recordCount = FeynFacet`Private`coefficientScanRecords[
    job["InputFile"],
    Function[record,
      If[! ListQ[record], Return[$Failed]];
      entries = Join[entries, record];
      True
    ]
  ];
  If[recordCount === $Failed, Return[$Failed]];
  seconds = First @ AbsoluteTiming[
    grouped = nnloMergeFractionEntries[entries];
    column = nnloAssembleFractionColumn[grouped, 120];
    If[column === $Failed, Return[$Failed, Module]];
    certificate = nnloCertifyUniversalFactor[column, 120];
    If[
      ! AssociationQ[certificate] || ! TrueQ[certificate["Verified"]] ||
        ! TrueQ[certificate["FractionFree"]],
      Return[$Failed, Module]
    ];
    hard = certificate["HardCoefficient"];
    cleanup = nnloLayeredHardCleanup[hard, context["Assumptions"]];
  ];
  outputRecord = <|
    "MasterIndex" -> job["MasterIndex"],
    "Master" -> job["Master"],
    "Column" -> column,
    "UniversalFactorCertificate" -> certificate,
    "HardCoefficient" -> cleanup["Expression"],
    "Cleanup" -> KeyDrop[cleanup, "Expression"],
    "ExactData" -> True
  |>;
  If[
    FeynFacet`Private`coefficientWriteRecord[job["OutputFile"], outputRecord] === $Failed,
    Return[$Failed]
  ];
  summary = <|
    "MasterIndex" -> job["MasterIndex"],
    "Master" -> job["Master"],
    "Seconds" -> seconds,
    "ShardRecords" -> recordCount,
    "LeafCount" -> column["LeafCount"],
    "DenominatorCount" -> column["DenominatorCount"],
    "NumeratorMonomials" -> Length[column["Numerator"]],
    "UniversalFactorVerified" -> certificate["Verified"],
    "FractionFree" -> certificate["FractionFree"],
    "HardCoefficientInputBytes" -> ByteCount[hard],
    "HardCoefficientBytes" -> ByteCount[outputRecord["HardCoefficient"]],
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "CleanupStages" -> cleanup["Stages"],
    "KernelID" -> $KernelID
  |>;
  Put[summary, job["SummaryFile"]];
  Clear[entries, grouped, column, certificate, outputRecord];
  ClearSystemCache[];
  summary
];

columnJobs = Map[
  Function[master,
    With[{index = masterPositions[master]},
      <|
        "MasterIndex" -> index,
        "Master" -> master,
        "InputFile" -> masterInputFiles[master],
        "OutputFile" -> FileNameJoin[{
          outputDirectory,
          "CompleteMaster_" <> IntegerString[index, 10, 4] <> ".bin"
        }],
        "SummaryFile" -> FileNameJoin[{
          outputDirectory,
          "CompleteMasterSummary_" <> IntegerString[index, 10, 4] <> ".wl"
        }]
      |>
    ]
  ],
  selectedMasters
];

{columnWallSeconds, columnSummaries} = AbsoluteTiming[
  Map[processCompleteColumn, columnJobs]
];
If[MemberQ[columnSummaries, $Failed],
  Put[columnSummaries, FileNameJoin[{outputDirectory, "FailedColumnRun.wl"}]];
  Print["COMPLETE_COLUMN_ERROR"];
  Quit[4]
];

result = <|
  "Method" -> "CompleteTarget-Kira-PositiveRootFractionRing-UniversalFactorCertificate",
  "Selection" -> selection,
  "ShardWallSeconds" -> shardWallSeconds,
  "ColumnWallSeconds" -> columnWallSeconds,
  "Kernels" -> 3,
  "ShardSummary" -> <|
    "Targets" -> Total[Lookup[shardSummaries, "Targets"]],
    "Leaves" -> Total[Lookup[shardSummaries, "Leaves"]],
    "DenominatorGroups" -> Total[Lookup[shardSummaries, "DenominatorGroups"]],
    "OutputBytes" -> Total[Lookup[shardSummaries, "OutputBytes"]],
    "Timeouts" -> Total[Lookup[shardSummaries, "Timeouts"]],
    "Failures" -> Total[Lookup[shardSummaries, "Failures"]]
  |>,
  "ColumnSummaries" -> columnSummaries,
  "ExactData" -> True
|>;
Put[result, FileNameJoin[{outputDirectory, "Manifest.wl"}]];
Print[ToString[InputForm[result]]];
Quit[];
