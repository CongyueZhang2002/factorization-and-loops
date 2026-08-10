(* Bounded-memory reconstruction and exact simplification of IBP coefficients. *)

CoefficientSimplification::store =
  "Could not build or read the indexed coefficient store for `1`.";

$coefficientStoreFormat = "FeynFacet-CoefficientStore";
$coefficientStoreVersion = 2;

$coefficientLateSetupKeys = {
  "HadronicVariables",
  "CoefficientKinematics",
  "KinematicMassDimensions"
};

coefficientAnalyticContextQ[context_] := Module[{required},
  required = {
    "Gamma5Scheme", "GlobalBasis", "GlobalBasisGram",
    "SetEvanescentZero", "SetMassZero", "SetDistributionZero",
    "CollinearRelations", "Assumptions", "KinematicMassDimensions",
    "LoopDimension", "DimensionRule", "CutConvention",
    "DistributionConvention", "FeynFacetSourceHash", "Fingerprint"
  };
  AssociationQ[context] &&
    ContainsAll[Keys[context], required] &&
    context["Gamma5Scheme"] === "BMHV" &&
    context["DimensionRule"] === $dimensionRule &&
    StringQ[context["FeynFacetSourceHash"]] &&
    context["Fingerprint"] ===
      reductionFingerprint[KeyDrop[context, "Fingerprint"]] &&
    exactDataQ[context]
];

coefficientKiraReductionQ[kira_] := Block[
  {analyticContextQ = coefficientAnalyticContextQ},
  kiraReductionQ[kira]
];

coefficientShardIndex[key_, count_Integer] :=
  1 + Mod[Hash[HoldComplete[key], "CRC32"], count];

coefficientShardFile[directory_, prefix_, index_Integer] := FileNameJoin[{
  directory,
  prefix <> "_" <> IntegerString[index, 10, 4] <> ".bin"
}];

coefficientAppendRecord[file_String, expression_] := Module[
  {stream, bytes, values},
  bytes = BinarySerialize[expression];
  values = Normal[bytes];
  stream = OpenAppend[file, BinaryFormat -> True];
  If[Head[stream] =!= OutputStream, Return[$Failed]];
  BinaryWrite[stream, Length[values], "UnsignedInteger64"];
  BinaryWrite[stream, values, "Byte"];
  Close[stream];
  file
];

coefficientWriteRecord[file_String, expression_] := Module[{},
  If[FileExistsQ[file], DeleteFile[file]];
  coefficientAppendRecord[file, expression]
];

coefficientScanRecords[file_String, function_] := Module[
  {stream, length, bytes, count = 0, value, result = True},
  If[! FileExistsQ[file], Return[0]];
  stream = OpenRead[file, BinaryFormat -> True];
  If[Head[stream] =!= InputStream, Return[$Failed]];
  While[True,
    length = BinaryRead[stream, "UnsignedInteger64"];
    If[length === EndOfFile, Break[]];
    If[! IntegerQ[length] || length < 0,
      result = $Failed;
      Break[]
    ];
    bytes = BinaryReadList[stream, "Byte", length];
    If[Length[bytes] =!= length,
      result = $Failed;
      Break[]
    ];
    value = Quiet @ Check[BinaryDeserialize[ByteArray[bytes]], $Failed];
    If[value === $Failed,
      result = $Failed;
      Break[]
    ];
    If[function[value] === $Failed,
      result = $Failed;
      Break[]
    ];
    count++
  ];
  Close[stream];
  If[result === $Failed, $Failed, count]
];

coefficientReadRecord[file_String] := Module[{values = {}, count},
  count = coefficientScanRecords[file, AppendTo[values, #] &];
  If[count === $Failed || count =!= 1, $Failed, First[values]]
];

coefficientCodexRoot[] := FileNameJoin[{$feynFacetRoot, "Codex"}];

coefficientSafeWorkPathQ[path_String] := Module[{root, normalized},
  root = ExpandFileName[coefficientCodexRoot[]] <> $PathnameSeparator;
  normalized = ExpandFileName[path] <> $PathnameSeparator;
  StringStartsQ[normalized, root] && normalized =!= root
];

coefficientResetDirectory[path_String] := Module[{},
  If[! coefficientSafeWorkPathQ[path], Return[$Failed]];
  If[DirectoryQ[path], DeleteDirectory[path, DeleteContents -> True]];
  CreateDirectory[path, CreateIntermediateDirectories -> True];
  path
];

coefficientProcessName[kiraFile_String] := Module[
  {resultDirectory, resultsDirectory, processDirectory},
  resultDirectory = DirectoryName[ExpandFileName[kiraFile]];
  resultsDirectory = DirectoryName[resultDirectory];
  processDirectory = DirectoryName[resultsDirectory];
  If[FileNameTake[resultsDirectory] =!= "Results", Return["Reduction"]];
  FileNameTake[processDirectory]
];

coefficientWorkDirectory[kiraFile_String] := FileNameJoin[{
  coefficientCodexRoot[],
  coefficientProcessName[kiraFile],
  "CoefficientSimplification",
  FileNameTake[DirectoryName[ExpandFileName[kiraFile]]]
}];

coefficientFileHash[file_String] :=
  FileHash[file, "SHA256", "HexString"];

coefficientStoreManifestFile[directory_String] :=
  FileNameJoin[{directory, "Manifest.wl"}];

coefficientStoreMetadataFile[directory_String] :=
  FileNameJoin[{directory, "Metadata.bin"}];

coefficientStoreValidQ[directory_String, kiraFile_String] := Module[
  {manifest},
  If[
    ! DirectoryQ[directory] ||
      ! FileExistsQ[coefficientStoreManifestFile[directory]] ||
      ! FileExistsQ[coefficientStoreMetadataFile[directory]],
    Return[False]
  ];
  manifest = Quiet @ Check[Get[coefficientStoreManifestFile[directory]], $Failed];
  AssociationQ[manifest] &&
    manifest["Format"] === $coefficientStoreFormat &&
    manifest["FormatVersion"] === $coefficientStoreVersion &&
    manifest["KiraFile"] === ExpandFileName[kiraFile] &&
    manifest["KiraFileBytes"] === FileByteCount[kiraFile] &&
    manifest["KiraFileHash"] === coefficientFileHash[kiraFile] &&
    IntegerQ[manifest["ShardCount"]] &&
    manifest["ShardCount"] > 0 &&
    AllTrue[
      Range[manifest["ShardCount"]],
      FileExistsQ[coefficientShardFile[directory, "Rules", #]] &
    ]
];

coefficientBuildKiraStore[kiraFile_String, directory_String] := Module[
  {
    kira, targetCount, shardCount, temporary, rules, ruleCount,
    chunkSize = 128, starts, chunk, groups, written = 0,
    metadata, manifest, result
  },
  If[! FileExistsQ[kiraFile], Return[$Failed]];
  Print["Loading the Kira artifact for one-time indexing"];
  kira = Quiet @ Check[Get[kiraFile], $Failed];
  If[! coefficientKiraReductionQ[kira], Return[$Failed]];
  targetCount = Length[kira["Targets"]];
  shardCount = 2^Ceiling @ Log[
    2,
    Max[
      1,
      Min[targetCount, coefficientKernelLimit[targetCount]],
      Ceiling[targetCount/256]
    ]
  ];
  temporary = directory <> ".building-" <> StringTake[CreateUUID[], 8];
  If[coefficientResetDirectory[temporary] === $Failed, Return[$Failed]];
  Scan[
    coefficientWriteRecord[
      coefficientShardFile[temporary, "Rules", #],
      <||>
    ] &,
    Range[shardCount]
  ];
  rules = kira["KiraRules"];
  ruleCount = Length[rules];
  starts = Range[1, ruleCount, chunkSize];
  Scan[
    Function[start,
      chunk = Take[rules, {start, Min[ruleCount, start + chunkSize - 1]}];
      groups = GroupBy[
        chunk,
        coefficientShardIndex[First[#], shardCount] &
      ];
      KeyValueMap[
        Function[{shard, shardRules},
          If[
            coefficientAppendRecord[
              coefficientShardFile[temporary, "Rules", shard],
              Association[shardRules]
            ] === $Failed,
            Return[$Failed, Module]
          ]
        ],
        groups
      ];
      written += Length[chunk];
      If[Mod[written, 4096] < chunkSize || written === ruleCount,
        Print["Indexed ", written, " / ", ruleCount, " Kira rules"]
      ]
    ],
    starts
  ];
  metadata = KeyDrop[kira, "KiraRules"];
  If[
    coefficientWriteRecord[
      coefficientStoreMetadataFile[temporary],
      metadata
    ] === $Failed,
    Return[$Failed]
  ];
  manifest = <|
    "Format" -> $coefficientStoreFormat,
    "FormatVersion" -> $coefficientStoreVersion,
    "KiraFile" -> ExpandFileName[kiraFile],
    "KiraFileBytes" -> FileByteCount[kiraFile],
    "KiraFileHash" -> coefficientFileHash[kiraFile],
    "ReductionInputFingerprint" -> kira["ReductionInputFingerprint"],
    "TargetCount" -> targetCount,
    "RuleCount" -> ruleCount,
    "MasterCount" -> Length[kira["Masters"]],
    "ShardCount" -> shardCount
  |>;
  Put[manifest, coefficientStoreManifestFile[temporary]];
  Clear[kira, rules, metadata, chunk, groups];
  ClearSystemCache[];
  If[DirectoryQ[directory],
    If[! coefficientSafeWorkPathQ[directory], Return[$Failed]];
    DeleteDirectory[directory, DeleteContents -> True]
  ];
  RenameDirectory[temporary, directory];
  result = If[coefficientStoreValidQ[directory, kiraFile], directory, $Failed];
  result
];

coefficientEnsureKiraStore[kiraFile_String] := Module[{directory},
  directory = FileNameJoin[{coefficientWorkDirectory[kiraFile], "KiraStore"}];
  If[coefficientStoreValidQ[directory, kiraFile],
    directory,
    coefficientBuildKiraStore[kiraFile, directory]
  ]
];

coefficientMergeAssociationRecord[target_Association, record_Association] :=
  Merge[{target, record}, Total];

coefficientInputFileFingerprint[sources_List] :=
  reductionFingerprint[{
    ExpandFileName /@ sources,
    FileHash[#, "SHA256"] & /@ sources
  }];

coefficientTargetStoreValidQ[
    data_Association,
    metadata_Association,
    directory_String,
    shardCount_Integer
  ] := Module[{manifest, sources, inputFingerprint},
  sources = data["Sources"];
  If[
    ! DirectoryQ[directory] || ! AllTrue[sources, StringQ] ||
      ! FileExistsQ[FileNameJoin[{directory, "Manifest.wl"}]] ||
      ! FileExistsQ[FileNameJoin[{directory, "Remainder.bin"}]] ||
      ! AllTrue[
        Range[shardCount],
        FileExistsQ[coefficientShardFile[directory, "Targets", #]] &
      ],
    Return[False]
  ];
  manifest = Quiet @ Check[
    Get[FileNameJoin[{directory, "Manifest.wl"}]],
    $Failed
  ];
  If[! AssociationQ[manifest], Return[False]];
  inputFingerprint = coefficientInputFileFingerprint[sources];
  manifest["SourceInputFingerprint"] === metadata["SourceInputFingerprint"] &&
    manifest["InputFileFingerprint"] === inputFingerprint &&
    manifest["PairCount"] === Length[sources] &&
    manifest["TargetCount"] === Length[metadata["Targets"]] &&
    manifest["ShardCount"] === shardCount
];

coefficientCollectTargetRecords[
    data_Association,
    metadata_Association,
    directory_String,
    shardCount_Integer
  ] := Module[
  {
    equivalence, batches, rawTargets = {}, rawSeen = <||>,
    mappedSeen = <||>, batchTerms, batchRemainder, result,
    rawParts, sourceParts, sourceMomenta, offendingMomenta,
    groups, sourceFingerprint, targetSet, kiraTargetSet,
    remainderFile, completed = 0, inputFingerprint, manifest
  },
  If[coefficientResetDirectory[directory] === $Failed, Return[$Failed]];
  Scan[
    coefficientWriteRecord[
      coefficientShardFile[directory, "Targets", #],
      <||>
    ] &,
    Range[shardCount]
  ];
  remainderFile = FileNameJoin[{directory, "Remainder.bin"}];
  coefficientWriteRecord[remainderFile, 0];
  equivalence = metadata["TopologyEquivalence"];
  batches = Partition[data["Sources"], UpTo[16]];
  Scan[
    Function[batch,
      batchTerms = <||>;
      batchRemainder = 0;
      Scan[
        Function[source,
          result = If[StringQ[source], Quiet @ Check[Get[source], $Failed], source];
          If[! validPreIBPResultQ[result], Return[$Failed, Module]];
          rawParts = linearIntegralSum[result["Integrand"]];
          If[FailureQ[rawParts], Return[$Failed, Module]];
          Scan[
            Function[target,
              If[! KeyExistsQ[rawSeen, target],
                AssociateTo[rawSeen, target -> True];
                AppendTo[rawTargets, target]
              ]
            ],
            Keys[rawParts["Terms"]]
          ];
          sourceParts = If[
            AssociationQ[equivalence] && KeyExistsQ[equivalence, "GLIRules"],
            linearMapIntegrals[rawParts, equivalence["GLIRules"]],
            rawParts
          ];
          If[FailureQ[sourceParts], Return[$Failed, Module]];
          sourceMomenta = coefficientForbiddenMomenta[result["Setup"]];
          offendingMomenta = remainingDeclaredMomenta[
            {Values[sourceParts["Terms"]], sourceParts["Remainder"]},
            sourceMomenta
          ];
          If[offendingMomenta =!= {}, Return[$Failed, Module]];
          sourceParts = linearScale[sourceParts, result["PreFactor"]];
          KeyValueMap[
            Function[{integral, coefficient},
              AssociateTo[
                batchTerms,
                integral -> (Lookup[batchTerms, integral, 0] + coefficient)
              ];
              AssociateTo[mappedSeen, integral -> True]
            ],
            sourceParts["Terms"]
          ];
          batchRemainder += sourceParts["Remainder"]
        ],
        batch
      ];
      groups = GroupBy[
        Normal[batchTerms],
        coefficientShardIndex[First[#], shardCount] &
      ];
      KeyValueMap[
        Function[{shard, rules},
          If[
            coefficientAppendRecord[
              coefficientShardFile[directory, "Targets", shard],
              Association[rules]
            ] === $Failed,
            Return[$Failed, Module]
          ]
        ],
        groups
      ];
      If[! TrueQ[batchRemainder === 0],
        coefficientAppendRecord[remainderFile, batchRemainder]
      ];
      completed += Length[batch];
      coefficientProgressUpdate[completed, Length[data["Sources"]]];
      Clear[batchTerms, batchRemainder, result, rawParts, sourceParts, groups];
      ClearSystemCache[]
    ],
    batches
  ];
  sourceFingerprint = reductionFingerprint[
    sourceInputPayload[
      data["Records"],
      rawTargets,
      data["AnalyticContext"]
    ]
  ];
  If[sourceFingerprint =!= metadata["SourceInputFingerprint"], Return[$Failed]];
  targetSet = Keys[mappedSeen];
  kiraTargetSet = metadata["Targets"];
  If[
    Length[targetSet] =!= Length[kiraTargetSet] ||
      ! ContainsAll[targetSet, kiraTargetSet] ||
      ! ContainsAll[kiraTargetSet, targetSet],
    Return[$Failed]
  ];
  inputFingerprint = coefficientInputFileFingerprint[data["Sources"]];
  manifest = <|
    "SourceInputFingerprint" -> sourceFingerprint,
    "InputFileFingerprint" -> inputFingerprint,
    "PairCount" -> Length[data["Sources"]],
    "TargetCount" -> Length[targetSet],
    "ShardCount" -> shardCount
  |>;
  Put[manifest, FileNameJoin[{directory, "Manifest.wl"}]];
  manifest
];

coefficientNormalizeOne[expression_, assumptions_, timeLimit_] := Module[
  {terms, result},
  terms = additiveTerms[expression];
  result = If[timeLimit === Infinity,
    Total[Simplify[#1, Assumptions -> assumptions] & /@ terms],
    TimeConstrained[
      Total[Simplify[#1, Assumptions -> assumptions] & /@ terms],
      timeLimit,
      expression
    ]
  ];
  If[exactDataQ[result], result, $Failed]
];

coefficientMasterTermTimeLimit[] := If[
  ValueQ[Global`$FACETMasterTermTimeLimit] &&
    NumericQ[Global`$FACETMasterTermTimeLimit] &&
    Global`$FACETMasterTermTimeLimit > 0,
  Global`$FACETMasterTermTimeLimit,
  60
];

coefficientRationalNormalizeOne[expression_, timeLimit_] := Module[
  {terms, timeoutCount = 0, outcome, normalized, result},
  terms = additiveTerms[expression];
  normalized = Function[term,
    outcome = If[
      timeLimit === Infinity,
      {Quiet @ Cancel[term], 0},
      TimeConstrained[
        {Quiet @ Cancel[term], 0},
        timeLimit,
        {term, 1}
      ]
    ];
    timeoutCount += Last[outcome];
    First[outcome]
  ] /@ terms;
  result = Total[normalized];
  If[exactDataQ[result], {result, timeoutCount}, $Failed]
];

coefficientProcessTargetShard[job_Association] := Module[
  {
    targetTerms = <||>, ruleTerms = <||>, targetCount, ruleCount,
    expected, keys, assumptions, timeLimit, normalized, timeoutCount = 0,
    masterTerms = <||>, remainder = 0, rhs, image, coefficient,
    reverseRules, dimensionRule, unexpected, outcome, summary
  },
  targetCount = coefficientScanRecords[
    job["TargetFile"],
    Function[record,
      If[! AssociationQ[record], Return[$Failed]];
      targetTerms = coefficientMergeAssociationRecord[targetTerms, record];
      True
    ]
  ];
  ruleCount = coefficientScanRecords[
    job["RuleFile"],
    Function[record,
      If[! AssociationQ[record], Return[$Failed]];
      KeyValueMap[AssociateTo[ruleTerms, #1 -> #2] &, record];
      True
    ]
  ];
  If[targetCount === $Failed || ruleCount === $Failed, Return[$Failed]];
  expected = job["ExpectedTargets"];
  keys = Keys[targetTerms];
  If[
    Length[keys] =!= Length[expected] ||
      ! ContainsAll[keys, expected] || ! ContainsAll[expected, keys],
    Return[$Failed]
  ];
  assumptions = job["Assumptions"];
  timeLimit = job["TimeLimit"];
  normalized = AssociationMap[
    Function[target,
      outcome = If[
        timeLimit === Infinity,
        {coefficientNormalizeOne[targetTerms[target], assumptions, Infinity], 0},
        TimeConstrained[
          {
            coefficientNormalizeOne[targetTerms[target], assumptions, Infinity],
            0
          },
          timeLimit,
          {targetTerms[target], 1}
        ]
      ];
      If[First[outcome] === $Failed, Return[$Failed, Module]];
      timeoutCount += Last[outcome];
      First[outcome]
    ],
    keys
  ];
  reverseRules = job["ReverseRules"];
  dimensionRule = job["DimensionRule"];
  Scan[
    Function[target,
      coefficient = normalized[target] /. dimensionRule;
      rhs = Lookup[ruleTerms, target, target];
      image = linearIntegralSum[rhs];
      If[FailureQ[image], Return[$Failed, Module]];
      image = linearMapCoefficients[
        image,
        Function[value, value /. reverseRules /. dimensionRule]
      ];
      KeyValueMap[
        Function[{master, imageCoefficient},
          AssociateTo[
            masterTerms,
            master -> (
              Lookup[masterTerms, master, 0] + coefficient imageCoefficient
            )
          ]
        ],
        image["Terms"]
      ];
      remainder += coefficient image["Remainder"]
    ],
    keys
  ];
  unexpected = Complement[Keys[masterTerms], job["Masters"], SameTest -> SameQ];
  If[unexpected =!= {}, Return[$Failed]];
  If[
    coefficientWriteRecord[
      job["OutputFile"],
      <|"Terms" -> masterTerms, "Remainder" -> remainder|>
    ] === $Failed,
    Return[$Failed]
  ];
  summary = <|
    "Shard" -> job["Shard"],
    "Targets" -> Length[keys],
    "InputBytes" -> FileByteCount[job["TargetFile"]],
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "TimeoutCount" -> timeoutCount,
    "OutputFile" -> job["OutputFile"],
    "KernelID" -> $KernelID
  |>;
  Clear[
    targetTerms, ruleTerms, normalized, masterTerms, remainder,
    rhs, image, coefficient
  ];
  ClearSystemCache[];
  summary
];

coefficientKernelLimit[count_Integer] := Min[
  count,
  If[
    ValueQ[Global`$FACETKernelLimit] &&
      IntegerQ[Global`$FACETKernelLimit] && Global`$FACETKernelLimit > 0,
    Global`$FACETKernelLimit,
    $ProcessorCount
  ]
];

coefficientJobsPerKernel[name_String] := Switch[name,
  "Target",
    If[
      ValueQ[Global`$FACETTargetJobsPerKernel] &&
        IntegerQ[Global`$FACETTargetJobsPerKernel] &&
        Global`$FACETTargetJobsPerKernel > 0,
      Global`$FACETTargetJobsPerKernel,
      4
    ],
  "Master",
    If[
      ValueQ[Global`$FACETMasterJobsPerKernel] &&
        IntegerQ[Global`$FACETMasterJobsPerKernel] &&
        Global`$FACETMasterJobsPerKernel > 0,
      Global`$FACETMasterJobsPerKernel,
      4
    ],
  _, 1
];

coefficientRunJobWaves[
    jobs_List,
    worker_,
    label_String,
    sizeFunction_,
    jobsPerKernel_Integer
  ] := Module[
  {
    limit, ordered, waves, existing, launched, loadFile,
    waveSummaries, summaries = {}, completed = 0
  },
  If[jobs === {}, Return[{}]];
  limit = coefficientKernelLimit[Length[jobs]];
  ordered = Reverse @ SortBy[jobs, sizeFunction];
  waves = Partition[ordered, UpTo[limit Max[1, jobsPerKernel]]];
  loadFile = FileNameJoin[{$feynFacetRoot, "Addon", "Load", "LoadFACET.wl"}];
  Scan[
    Function[wave,
      existing = Kernels[];
      launched = If[Length[existing] < limit,
        LaunchKernels[limit - Length[existing]],
        {}
      ];
      With[{path = loadFile},
        ParallelEvaluate[
          $HistoryLength = 0;
          $LoadFeynArts = True;
          Block[{$Output = {}, $Messages = {}}, Quiet[Get[path]]];
        ]
      ];
      waveSummaries = CheckAbort[
        With[{workerFunction = worker},
          ParallelMap[workerFunction, wave, Method -> "FinestGrained"]
        ],
        If[launched =!= {}, CloseKernels[launched]];
        Abort[]
      ];
      If[launched =!= {}, CloseKernels[launched]];
      If[
        ! ListQ[waveSummaries] || MemberQ[waveSummaries, $Failed],
        Return[$Failed, Module]
      ];
      summaries = Join[summaries, waveSummaries];
      completed += Length[waveSummaries];
      Print[
        label, " ", completed, " / ", Length[jobs],
        "; kernels: ", Counts[Lookup[waveSummaries, "KernelID"]]
      ];
      Clear[waveSummaries];
      ClearSystemCache[]
    ],
    waves
  ];
  summaries
];

coefficientRunTargetJobs[jobs_List] := coefficientRunJobWaves[
  jobs,
  coefficientProcessTargetShard,
  "Target shards",
  Function[job,
    FileByteCount[job["TargetFile"]] + FileByteCount[job["RuleFile"]]
  ],
  coefficientJobsPerKernel["Target"]
];

coefficientReducedShardStoreValidQ[jobs_List, masters_List] := Module[
  {allowed, data, unexpected},
  allowed = AssociationThread[masters, ConstantArray[True, Length[masters]]];
  Do[
    If[! FileExistsQ[job["OutputFile"]], Return[False]];
    data = coefficientReadRecord[job["OutputFile"]];
    If[
      ! AssociationQ[data] ||
        ! AssociationQ[Lookup[data, "Terms", Missing[]]] ||
        ! KeyExistsQ[data, "Remainder"] ||
        ! exactDataQ[data],
      Return[False]
    ];
    unexpected = Select[
      Keys[data["Terms"]],
      ! KeyExistsQ[allowed, #] &
    ];
    If[unexpected =!= {}, Return[False]];
    Clear[data, unexpected];
    ClearSystemCache[],
    {job, jobs}
  ];
  True
];

coefficientTransposeMasterShards[
    shardFiles_List,
    masters_List,
    directory_String
  ] := Module[
  {position, remainderFile, data, unexpected, completed = 0},
  If[coefficientResetDirectory[directory] === $Failed, Return[$Failed]];
  position = AssociationThread[masters, Range[Length[masters]]];
  remainderFile = FileNameJoin[{directory, "Remainder.bin"}];
  Scan[
    Function[file,
      data = coefficientReadRecord[file];
      If[! AssociationQ[data], Return[$Failed, Module]];
      unexpected = Select[Keys[data["Terms"]], ! KeyExistsQ[position, #] &];
      If[unexpected =!= {}, Return[$Failed, Module]];
      KeyValueMap[
        Function[{master, coefficient},
          coefficientAppendRecord[
            coefficientShardFile[directory, "Master", position[master]],
            coefficient
          ]
        ],
        data["Terms"]
      ];
      If[! TrueQ[data["Remainder"] === 0],
        coefficientAppendRecord[remainderFile, data["Remainder"]]
      ];
      completed++;
      If[Mod[completed, 32] === 0 || completed === Length[shardFiles],
        Print["Transposed ", completed, " / ", Length[shardFiles], " shards"]
      ];
      Clear[data];
      ClearSystemCache[]
    ],
    shardFiles
  ];
  <|
    "MasterFiles" -> MapIndexed[
      Function[{master, index},
        <|
          "Master" -> master,
          "File" -> coefficientShardFile[directory, "Master", First[index]]
        |>
      ],
      masters
    ],
    "RemainderFile" -> remainderFile
  |>
];

coefficientBalancedRecordTotal[file_String] := Module[
  {levels = <||>, count, add},
  add[value_] := Module[{level = 0, current = value},
    While[KeyExistsQ[levels, level],
      current = levels[level] + current;
      KeyDropFrom[levels, level];
      level++
    ];
    AssociateTo[levels, level -> current]
  ];
  count = coefficientScanRecords[file, (add[#]; True) &];
  If[count === $Failed, $Failed, Total[Values[levels]]]
];

coefficientProcessMaster[job_Association] := Module[
  {
    expression, normalized, parts, seconds, outcome, timeoutCount,
    validationInputFile, record
  },
  If[! FileExistsQ[job["InputFile"]], Return[<|
    "Master" -> job["Master"], "Zero" -> True,
    "OutputFile" -> job["OutputFile"], "Seconds" -> 0
  |>]];
  {seconds, outcome} = AbsoluteTiming[
    expression = coefficientBalancedRecordTotal[job["InputFile"]];
    If[expression === $Failed, Return[$Failed, Module]];
    coefficientRationalNormalizeOne[
      expression,
      coefficientMasterTermTimeLimit[]
    ]
  ];
  If[outcome === $Failed, Return[$Failed]];
  {normalized, timeoutCount} = outcome;
  parts = structuralAdditiveFactor[normalized];
  validationInputFile = Lookup[
    job,
    "ValidationInputFile",
    job["InputFile"]
  ];
  record = <|
    "Master" -> job["Master"],
    "PreFactor" -> First[parts],
    "Coefficient" -> Last[parts],
    "InputFileHash" -> coefficientFileHash[validationInputFile],
    "Normalizer" -> "TermCancel-v1"
  |>;
  If[coefficientWriteRecord[job["OutputFile"], record] === $Failed,
    Return[$Failed]
  ];
  If[
    coefficientWriteMasterManifest[
      job,
      record,
      timeoutCount,
      TrueQ[normalized === 0]
    ] === $Failed,
    Return[$Failed]
  ];
  <|
    "Master" -> job["Master"],
    "Zero" -> TrueQ[normalized === 0],
    "OutputFile" -> job["OutputFile"],
    "Seconds" -> seconds,
    "TimeoutCount" -> timeoutCount,
    "InputBytes" -> FileByteCount[job["InputFile"]],
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "KernelID" -> $KernelID
  |>
];

coefficientMasterManifestFile[file_String] := file <> ".manifest.wl";

coefficientMasterNormalizerQ[value_] := MemberQ[
  {"TermCancel-v1", "RationalSignatureModule-v1"},
  value
];

coefficientWriteMasterManifest[
    job_Association,
    record_Association,
    timeoutCount_Integer,
    zero_
  ] := Module[{file = job["OutputFile"], manifest},
  manifest = <|
    "Master" -> record["Master"],
    "InputFileHash" -> record["InputFileHash"],
    "Normalizer" -> record["Normalizer"],
    "Zero" -> TrueQ[zero],
    "TimeoutCount" -> timeoutCount,
    "OutputFileBytes" -> FileByteCount[file],
    "OutputFileHash" -> coefficientFileHash[file]
  |>;
  Quiet @ Check[
    Put[manifest, coefficientMasterManifestFile[file]],
    $Failed
  ]
];

coefficientFinalMasterRecordValidQ[job_Association] := Module[
  {record, manifest, validationInputFile, inputHash, valid},
  If[! FileExistsQ[job["OutputFile"]], Return[False]];
  validationInputFile = Lookup[
    job,
    "ValidationInputFile",
    job["InputFile"]
  ];
  inputHash = coefficientFileHash[validationInputFile];
  manifest = Quiet @ Check[
    Get[coefficientMasterManifestFile[job["OutputFile"]]],
    $Failed
  ];
  If[
    AssociationQ[manifest] &&
      manifest["Master"] === job["Master"] &&
      coefficientMasterNormalizerQ[manifest["Normalizer"]] &&
      manifest["InputFileHash"] === inputHash &&
      manifest["OutputFileBytes"] === FileByteCount[job["OutputFile"]] &&
      manifest["OutputFileHash"] === coefficientFileHash[job["OutputFile"]],
    Return[True]
  ];
  record = coefficientReadRecord[job["OutputFile"]];
  valid = AssociationQ[record] &&
    record["Master"] === job["Master"] &&
    coefficientMasterNormalizerQ[
      Lookup[record, "Normalizer", Missing[]]
    ] &&
    Lookup[record, "InputFileHash", Missing[]] === inputHash &&
    exactDataQ[record];
  If[
    TrueQ[valid],
    coefficientWriteMasterManifest[
      job,
      record,
      0,
      TrueQ[record["Coefficient"] === 0]
    ]
  ];
  TrueQ[valid]
];

coefficientMasterSplitThreshold[] := If[
  ValueQ[Global`$FACETMasterSplitThreshold] &&
    IntegerQ[Global`$FACETMasterSplitThreshold] &&
    Global`$FACETMasterSplitThreshold > 0,
  Global`$FACETMasterSplitThreshold,
  256 1024^2
];

coefficientMasterMergeWidth[] := If[
  ValueQ[Global`$FACETMasterMergeWidth] &&
    IntegerQ[Global`$FACETMasterMergeWidth] &&
    Global`$FACETMasterMergeWidth > 1,
  Global`$FACETMasterMergeWidth,
  8
];

coefficientEnsureDirectory[path_String] := Module[{},
  If[! coefficientSafeWorkPathQ[path], Return[$Failed]];
  If[
    ! DirectoryQ[path] &&
      CreateDirectory[path, CreateIntermediateDirectories -> True] === $Failed,
    Return[$Failed]
  ];
  path
];

coefficientExplodeRecordFile[inputFile_String, directory_String] := Module[
  {
    input, output, outputFile, files = {}, length, bytes,
    recordCount = 0, manifestFile, manifest
  },
  manifestFile = FileNameJoin[{directory, "Manifest.wl"}];
  manifest = Quiet @ Check[Get[manifestFile], $Failed];
  files = Sort @ FileNames["Leaf_*.bin", directory];
  If[
    AssociationQ[manifest] &&
      manifest["InputFile"] === ExpandFileName[inputFile] &&
      manifest["InputFileBytes"] === FileByteCount[inputFile] &&
      manifest["InputFileHash"] === coefficientFileHash[inputFile] &&
      manifest["RecordCount"] === Length[files] &&
      files =!= {},
    Return[<|"Files" -> files, "RecordCount" -> Length[files]|>]
  ];
  If[coefficientResetDirectory[directory] === $Failed, Return[$Failed]];
  files = {};
  input = OpenRead[inputFile, BinaryFormat -> True];
  If[Head[input] =!= InputStream,
    Return[$Failed]
  ];
  While[True,
    length = BinaryRead[input, "UnsignedInteger64"];
    If[length === EndOfFile, Break[]];
    If[! IntegerQ[length] || length < 0,
      Close[input];
      Return[$Failed]
    ];
    bytes = BinaryReadList[input, "Byte", length];
    If[Length[bytes] =!= length,
      Close[input];
      Return[$Failed]
    ];
    recordCount++;
    outputFile = coefficientShardFile[directory, "Leaf", recordCount];
    output = OpenWrite[outputFile, BinaryFormat -> True];
    If[Head[output] =!= OutputStream,
      Close[input];
      Return[$Failed]
    ];
    BinaryWrite[output, length, "UnsignedInteger64"];
    BinaryWrite[output, bytes, "Byte"];
    Close[output];
    AppendTo[files, outputFile]
  ];
  Close[input];
  Put[
    <|
      "InputFile" -> ExpandFileName[inputFile],
      "InputFileBytes" -> FileByteCount[inputFile],
      "InputFileHash" -> coefficientFileHash[inputFile],
      "RecordCount" -> recordCount
    |>,
    manifestFile
  ];
  <|"Files" -> files, "RecordCount" -> recordCount|>
];

coefficientWriteMergedMasterInput[
    partialFiles_List,
    outputFile_String
  ] := Module[{record},
  If[FileExistsQ[outputFile], DeleteFile[outputFile]];
  Scan[
    Function[file,
      record = coefficientReadRecord[file];
      If[
        ! AssociationQ[record] ||
          ! KeyExistsQ[record, "PreFactor"] ||
          ! KeyExistsQ[record, "Coefficient"],
        Return[$Failed, Module]
      ];
      If[
        coefficientAppendRecord[
          outputFile,
          record["PreFactor"] record["Coefficient"]
        ] === $Failed,
        Return[$Failed, Module]
      ]
    ],
    partialFiles
  ];
  outputFile
];

coefficientRunMasterJobs[
    jobs_List,
    jobsPerKernel_: Automatic
  ] := coefficientRunJobWaves[
  jobs,
  coefficientProcessMaster,
  "Master coefficients",
  Function[job,
    If[FileExistsQ[job["InputFile"]], FileByteCount[job["InputFile"]], 0]
  ],
  Replace[jobsPerKernel, Automatic :> coefficientJobsPerKernel["Master"]]
];

coefficientCachedMasterSummary[job_Association] := Module[{manifest},
  manifest = Get[coefficientMasterManifestFile[job["OutputFile"]]];
  <|
    "Master" -> job["Master"],
    "Zero" -> manifest["Zero"],
    "OutputFile" -> job["OutputFile"],
    "Seconds" -> 0,
    "TimeoutCount" -> manifest["TimeoutCount"],
    "InputBytes" -> FileByteCount[job["InputFile"]],
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "KernelID" -> 0,
    "Reused" -> True
  |>
];

coefficientRunMasterJobsCached[
    jobs_List,
    jobsPerKernel_: Automatic
  ] := Module[{valid, completed, pending, fresh},
  If[jobs === {}, Return[{}]];
  valid = coefficientFinalMasterRecordValidQ /@ jobs;
  completed = Map[
    coefficientCachedMasterSummary,
    Pick[jobs, valid, True]
  ];
  pending = Pick[jobs, valid, False];
  fresh = coefficientRunMasterJobs[pending, jobsPerKernel];
  If[fresh === $Failed, $Failed, Join[completed, fresh]]
];

coefficientRunPendingMasterJobsLegacy[
    jobs_List,
    workDirectory_String
  ] := Module[
  {
    largeFlags, largeJobs, directJobs, leafRoot, partialRoot,
    mergeRoot, groups, leafInfo, partialDirectory, leafJobs,
    directSummaries, leafSummaries, finalSummaries = {},
    activeGroups, level = 0, mergeJobs, nextGroups, partitions,
    inputFile, outputFile, finalLevel, mergeSummaries, completed,
    singletonJobs, singletonSummaries
  },
  If[jobs === {}, Return[{}]];
  largeFlags = (
    FileByteCount[#1["InputFile"]] >= coefficientMasterSplitThreshold[]
  ) & /@ jobs;
  largeJobs = Pick[jobs, largeFlags, True];
  directJobs = Pick[jobs, largeFlags, False];
  If[largeJobs === {}, Return[coefficientRunMasterJobs[directJobs]]];
  leafRoot = FileNameJoin[{workDirectory, "MasterLeaves"}];
  partialRoot = FileNameJoin[{workDirectory, "PartialMasters"}];
  mergeRoot = FileNameJoin[{workDirectory, "MergedMasterRecords"}];
  If[
    Or @@ (
      coefficientEnsureDirectory[#] === $Failed & /@
        {leafRoot, partialRoot, mergeRoot}
    ),
    Return[$Failed]
  ];
  groups = MapIndexed[
    Function[{job, index},
      leafInfo = coefficientExplodeRecordFile[
        job["InputFile"],
        FileNameJoin[{
          leafRoot,
          "Master_" <> IntegerString[First[index], 10, 4]
        }]
      ];
      If[! AssociationQ[leafInfo], Return[$Failed, Module]];
      partialDirectory = FileNameJoin[{
        partialRoot,
        "Master_" <> IntegerString[First[index], 10, 4],
        "Level_0000"
      }];
      If[
        ! DirectoryQ[partialDirectory] &&
          CreateDirectory[
            partialDirectory,
            CreateIntermediateDirectories -> True
          ] === $Failed,
        Return[$Failed, Module]
      ];
      leafJobs = MapIndexed[
        Function[{file, chunkIndex},
          <|
            "Master" -> job["Master"],
            "InputFile" -> file,
            "OutputFile" -> coefficientShardFile[
              partialDirectory,
              "Partial",
              First[chunkIndex]
            ],
            "Assumptions" -> job["Assumptions"]
          |>
        ],
        leafInfo["Files"]
      ];
      <|"MasterJob" -> job, "Jobs" -> leafJobs|>
    ],
    largeJobs
  ];
  If[MemberQ[groups, $Failed], Return[$Failed]];
  directSummaries = coefficientRunMasterJobsCached[directJobs, 8];
  If[directSummaries === $Failed, Return[$Failed]];
  Print[
    "Splitting ", Length[largeJobs], " large coefficients into ",
    Total[Length[#1["Jobs"]] & /@ groups], " exact records"
  ];
  leafSummaries = coefficientRunMasterJobsCached[
    Flatten[Lookup[groups, "Jobs"], 1],
    16
  ];
  If[leafSummaries === $Failed, Return[$Failed]];
  activeGroups = Map[
    <|
      "MasterJob" -> #1["MasterJob"],
      "Files" -> Lookup[#1["Jobs"], "OutputFile"]
    |> &,
    groups
  ];
  While[AnyTrue[activeGroups, Length[#1["Files"]] > 1 &],
    level++;
    mergeJobs = {};
    nextGroups = MapIndexed[
      Function[{group, groupIndex},
        If[Length[group["Files"]] === 1, Return[group]];
        partitions = Partition[
          group["Files"],
          UpTo[coefficientMasterMergeWidth[]]
        ];
        finalLevel = Length[partitions] === 1;
        MapIndexed[
          Function[{files, partitionIndex},
            inputFile = coefficientShardFile[
              FileNameJoin[{
                mergeRoot,
                "Level_" <> IntegerString[level, 10, 4]
              }],
              "Input_" <> IntegerString[First[groupIndex], 10, 4],
              First[partitionIndex]
            ];
            If[
              ! DirectoryQ[DirectoryName[inputFile]] &&
                CreateDirectory[
                  DirectoryName[inputFile],
                  CreateIntermediateDirectories -> True
                ] === $Failed,
              Return[$Failed, Module]
            ];
            If[
              coefficientWriteMergedMasterInput[files, inputFile] === $Failed,
              Return[$Failed, Module]
            ];
            outputFile = If[finalLevel,
              group["MasterJob", "OutputFile"],
              coefficientShardFile[
                FileNameJoin[{
                  partialRoot,
                  "MergeLevel_" <> IntegerString[level, 10, 4],
                  "Master_" <> IntegerString[First[groupIndex], 10, 4]
                }],
                "Partial",
                First[partitionIndex]
              ]
            ];
            If[
              ! DirectoryQ[DirectoryName[outputFile]] &&
                CreateDirectory[
                  DirectoryName[outputFile],
                  CreateIntermediateDirectories -> True
                ] === $Failed,
              Return[$Failed, Module]
            ];
            AppendTo[
              mergeJobs,
              Join[
                group["MasterJob"],
                <|
                  "InputFile" -> inputFile,
                  "OutputFile" -> outputFile,
                  "ValidationInputFile" -> If[
                    finalLevel,
                    group["MasterJob", "InputFile"],
                    inputFile
                  ]
                |>
              ]
            ];
            outputFile
          ],
          partitions
        ] // Flatten // (<|
          "MasterJob" -> group["MasterJob"],
          "Files" -> #1
        |> &)
      ],
      activeGroups
    ];
    If[! FreeQ[nextGroups, $Failed], Return[$Failed]];
    Print[
      "Merge level ", level, ": ", Length[mergeJobs],
      " coefficient groups"
    ];
    mergeSummaries = coefficientRunMasterJobsCached[mergeJobs, 8];
    If[mergeSummaries === $Failed, Return[$Failed]];
    completed = Select[
      mergeSummaries,
      MemberQ[Lookup[largeJobs, "OutputFile"], #1["OutputFile"]] &
    ];
    finalSummaries = Join[finalSummaries, completed];
    activeGroups = nextGroups
  ];
  singletonJobs = MapIndexed[
    Function[{group, index},
      If[
        First[group["Files"]] === group["MasterJob", "OutputFile"],
        Nothing,
        inputFile = coefficientShardFile[
          FileNameJoin[{mergeRoot, "Singleton"}],
          "Input",
          First[index]
        ];
        If[
          ! DirectoryQ[DirectoryName[inputFile]] &&
            CreateDirectory[
              DirectoryName[inputFile],
              CreateIntermediateDirectories -> True
            ] === $Failed,
          Return[$Failed, Module]
        ];
        If[
          coefficientWriteMergedMasterInput[
            group["Files"],
            inputFile
          ] === $Failed,
          Return[$Failed, Module]
        ];
        Join[
          group["MasterJob"],
          <|
            "InputFile" -> inputFile,
            "ValidationInputFile" -> group["MasterJob", "InputFile"]
          |>
        ]
      ]
    ],
    activeGroups
  ];
  If[! FreeQ[singletonJobs, $Failed], Return[$Failed]];
  singletonSummaries = coefficientRunMasterJobsCached[singletonJobs, 8];
  If[singletonSummaries === $Failed, Return[$Failed]];
  finalSummaries = Join[finalSummaries, singletonSummaries];
  If[Length[finalSummaries] =!= Length[largeJobs], Return[$Failed]];
  Join[directSummaries, finalSummaries]
];

coefficientRunPendingMasterJobs[
    jobs_List,
    workDirectory_String
  ] := Module[
  {largeFlags, largeJobs, directJobs, directSummaries, moduleSummaries},
  If[jobs === {}, Return[{}]];
  largeFlags = (
    FileByteCount[#1["InputFile"]] >= coefficientMasterSplitThreshold[]
  ) & /@ jobs;
  largeJobs = Pick[jobs, largeFlags, True];
  directJobs = Pick[jobs, largeFlags, False];
  directSummaries = coefficientRunMasterJobsCached[directJobs, 8];
  If[directSummaries === $Failed, Return[$Failed]];
  moduleSummaries = coefficientRunModuleMasterJobs[largeJobs, workDirectory];
  If[moduleSummaries === $Failed, Return[$Failed]];
  Join[directSummaries, moduleSummaries]
];

coefficientAssembleStoredResult[
    data_Association,
    metadata_Association,
    kiraFile_String,
    masterSummaries_List,
    finalDirectory_String,
    remainderFile_String
  ] := Module[
  {
    masterResults, nonzero, remainder, remainderParts,
    localFactors, shared, commonPreFactor, adjustedFactors,
    recordsByName, equivalence, classByName, masterData,
    reconstructed, forbiddenMomenta, remainingMomenta, cutCheck
  },
  masterResults = DeleteCases[
    coefficientReadRecord /@ Lookup[masterSummaries, "OutputFile"],
    $Failed
  ];
  nonzero = Select[masterResults, ! TrueQ[#1["Coefficient"] === 0] &];
  remainder = If[FileExistsQ[remainderFile],
    coefficientNormalizeOne[
      coefficientBalancedRecordTotal[remainderFile],
      data["AnalyticContext", "Assumptions"],
      Infinity
    ],
    0
  ];
  If[remainder === $Failed, Return[$Failed]];
  remainderParts = If[TrueQ[remainder === 0], {1, 0}, structuralAdditiveFactor[remainder]];
  localFactors = Join[
    Lookup[nonzero, "PreFactor"],
    If[TrueQ[remainder === 0], {}, {First[remainderParts]}]
  ];
  shared = If[localFactors === {}, {},
    commonFactorMultiset[topLevelFactors /@ localFactors]
  ];
  commonPreFactor = Times @@ shared;
  adjustedFactors = Times @@@ (
    removeFactorMultiset[topLevelFactors[#], shared] & /@
      Lookup[nonzero, "PreFactor"]
  );
  remainder = If[TrueQ[remainder === 0], 0,
    Times @@ removeFactorMultiset[topLevelFactors[First[remainderParts]], shared] *
      Last[remainderParts]
  ];
  recordsByName = Association[
    #1["Topology"][[1]] -> #1 & /@ metadata["Topologies"]
  ];
  equivalence = metadata["TopologyEquivalence"];
  classByName = If[
    AssociationQ[equivalence] && KeyExistsQ[equivalence, "Classes"],
    Association[#1["Representative"] -> #1 & /@ equivalence["Classes"]],
    <||>
  ];
  masterData = MapThread[
    Function[{entry, factor},
      With[{master = entry["Master"], record = recordsByName[entry["Master"][[1]]]},
        <|
          "Master" -> master,
          "PreFactor" -> factor,
          "Coefficient" -> entry["Coefficient"],
          "TopologyName" -> master[[1]],
          "CutMomenta" -> record["CutMomenta"],
          "CutIndices" -> record["CutIndices"],
          "CutDirections" -> record["CutDirections"],
          "TopologyClass" -> Lookup[classByName, master[[1]], Missing["NotFound"]]
        |>
      ]
    ],
    {nonzero, adjustedFactors}
  ];
  reconstructed = commonPreFactor (
    Total[#1["PreFactor"] #1["Coefficient"] #1["Master"] & /@ masterData] +
      remainder
  );
  forbiddenMomenta = coefficientForbiddenMomenta[data["Setup"]];
  remainingMomenta = remainingDeclaredMomenta[
    {Lookup[masterData, "Coefficient"], remainder},
    forbiddenMomenta
  ];
  If[remainingMomenta =!= {} || ! FreeQ[reconstructed, System`D], Return[$Failed]];
  cutCheck = validateCutGLIs[Lookup[masterData, "Master"], metadata["Topologies"]];
  If[cutCheck =!= True, Return[$Failed]];
  Join[
    resultHeader["FeynFacet-IBP", 7],
    resultContext[data],
    <|
      "FractionMeasure" -> data["FractionMeasure"],
      "PhaseSpace" -> data["PhaseSpace"],
      "PreFactor" -> commonPreFactor,
      "Remainder" -> remainder,
      "Expression" -> reconstructed,
      "Masters" -> masterData,
      "Topologies" -> metadata["Topologies"],
      "KiraArtifact" -> ExpandFileName[kiraFile],
      "ReverseRules" -> metadata["ReverseRules"],
      "TopologyEquivalence" -> equivalence,
      "Assumptions" -> data["AnalyticContext", "Assumptions"],
      "AnalyticContext" -> data["AnalyticContext"],
      "MassDimensions" -> metadata["MassDimensions"],
      "KiraManifest" -> metadata["KiraManifest"],
      "DimensionRule" -> $dimensionRule,
      "ReductionInputFingerprint" -> metadata["ReductionInputFingerprint"],
      "SourceInputFingerprint" -> metadata["SourceInputFingerprint"]
    |>
  ]
];

coefficientSimplificationStoredCore[inputs_List, kiraFile_String] := Catch[
  Module[
    {
      store, manifest, metadata, data, workDirectory, targetDirectory,
      shardOutputDirectory, masterDirectory, finalDirectory,
      shardCount, expectedByShard, jobs, targetSummaries,
      shardFiles, transposed, masterJobs, masterSummaries, result,
      masterJobValidity, completedMasterJobs, pendingMasterJobs,
      newMasterSummaries,
      sortedPairs
    },
    store = coefficientEnsureKiraStore[kiraFile];
    If[store === $Failed,
      Message[CoefficientSimplification::store, kiraFile];
      Throw[$Failed, $ibpFailure]
    ];
    manifest = Get[coefficientStoreManifestFile[store]];
    metadata = coefficientReadRecord[coefficientStoreMetadataFile[store]];
    If[
      ! AssociationQ[metadata] ||
        ! coefficientKiraReductionQ[Append[metadata, "KiraRules" -> {}]],
      ibpFail["coefficient store", "the stored Kira metadata is invalid"]
    ];
    data = ibpInputData[inputs, False];
    sortedPairs[list_List] := SortBy[
      list,
      {Lookup[#1, "Forward"], Lookup[#1, "Conjugate"]} &
    ];
    If[
      data["CardName"] =!= metadata["CardName"] ||
        data["ResultDirectory"] =!= metadata["ResultDirectory"] ||
        sortedPairs[data["Pairs"]] =!= sortedPairs[metadata["Pairs"]],
      ibpFail["coefficient input validation", "the Kira artifact belongs to another result set"]
    ];
    shardCount = manifest["ShardCount"];
    workDirectory = coefficientWorkDirectory[kiraFile];
    targetDirectory = FileNameJoin[{workDirectory, "TargetRecords"}];
    shardOutputDirectory = FileNameJoin[{workDirectory, "MasterShards"}];
    masterDirectory = FileNameJoin[{workDirectory, "MasterRecords"}];
    finalDirectory = FileNameJoin[{workDirectory, "FinalMasters"}];
    If[
      coefficientTargetStoreValidQ[
        data, metadata, targetDirectory, shardCount
      ],
      Print["Reusing validated target records"],
      Print["Writing bounded target records"];
      If[
        coefficientCollectTargetRecords[
          data, metadata, targetDirectory, shardCount
        ] === $Failed,
        ibpFail["target coefficient collection", "bounded target collection failed"]
      ]
    ];
    expectedByShard = GroupBy[
      metadata["Targets"],
      coefficientShardIndex[#, shardCount] &
    ];
    jobs = Table[
      <|
        "Shard" -> shard,
        "TargetFile" -> coefficientShardFile[targetDirectory, "Targets", shard],
        "RuleFile" -> coefficientShardFile[store, "Rules", shard],
        "OutputFile" -> coefficientShardFile[shardOutputDirectory, "Masters", shard],
        "ExpectedTargets" -> Lookup[expectedByShard, shard, {}],
        "Assumptions" -> data["AnalyticContext", "Assumptions"],
        "TimeLimit" -> targetCoefficientSimplifyTimeLimit[],
        "ReverseRules" -> metadata["ReverseRules"],
        "DimensionRule" -> metadata["DimensionRule"],
        "Masters" -> metadata["Masters"]
      |>,
      {shard, shardCount}
    ];
    If[
      coefficientReducedShardStoreValidQ[jobs, metadata["Masters"]],
      Print["Reusing validated reduced target shards"];
      targetSummaries = <|"OutputFile" -> #1["OutputFile"]|> & /@ jobs,
      Print["Simplifying and reducing ", shardCount, " target shards"];
      If[coefficientResetDirectory[shardOutputDirectory] === $Failed,
        ibpFail[
          "target coefficient simplification",
          "could not create the shard output directory"
        ]
      ];
      targetSummaries = coefficientRunTargetJobs[jobs];
      If[targetSummaries === $Failed,
        ibpFail["target coefficient simplification", "a target shard failed"]
      ]
    ];
    shardFiles = Lookup[targetSummaries, "OutputFile", Lookup[jobs, "OutputFile"]];
    If[Length[shardFiles] =!= shardCount,
      shardFiles = Lookup[jobs, "OutputFile"]
    ];
    Print["Indexing contributions by master"];
    transposed = coefficientTransposeMasterShards[
      Lookup[jobs, "OutputFile"],
      metadata["Masters"],
      masterDirectory
    ];
    If[transposed === $Failed,
      ibpFail["master coefficient collection", "master transposition failed"]
    ];
    If[
      ! DirectoryQ[finalDirectory] &&
        CreateDirectory[
          finalDirectory,
          CreateIntermediateDirectories -> True
        ] === $Failed,
      ibpFail[
        "master coefficient simplification",
        "could not create the final-master directory"
      ]
    ];
    masterJobs = MapIndexed[
      Function[{item, index},
        <|
          "Master" -> item["Master"],
          "InputFile" -> item["File"],
          "OutputFile" -> coefficientShardFile[finalDirectory, "Master", First[index]],
          "Assumptions" -> data["AnalyticContext", "Assumptions"]
        |>
      ],
      transposed["MasterFiles"]
    ];
    masterJobValidity = coefficientFinalMasterRecordValidQ /@ masterJobs;
    completedMasterJobs = Pick[masterJobs, masterJobValidity, True];
    pendingMasterJobs = Pick[masterJobs, masterJobValidity, False];
    If[completedMasterJobs =!= {},
      Print[
        "Reusing ", Length[completedMasterJobs],
        " validated master coefficients"
      ]
    ];
    Print["Simplifying ", Length[pendingMasterJobs], " master coefficients"];
    newMasterSummaries = coefficientRunPendingMasterJobs[
      pendingMasterJobs,
      workDirectory
    ];
    If[newMasterSummaries === $Failed,
      ibpFail["master coefficient simplification", "a master coefficient failed"]
    ];
    masterSummaries = Join[
      (<|
        "Master" -> #1["Master"],
        "OutputFile" -> #1["OutputFile"],
        "Reused" -> True
      |> &) /@ completedMasterJobs,
      newMasterSummaries
    ];
    result = coefficientAssembleStoredResult[
      data,
      metadata,
      kiraFile,
      Select[masterSummaries, FileExistsQ[#1["OutputFile"]] &],
      finalDirectory,
      transposed["RemainderFile"]
    ];
    If[! AssociationQ[result],
      ibpFail["result assembly", "the stored coefficients could not be assembled"]
    ];
    Print @ Grid[
      {
        {"Pairs", Length[inputs]},
        {"Input integrals", Length[metadata["Targets"]]},
        {"Master integrals", Length[result["Masters"]]},
        {"Result size (kB)", Round[ByteCount[result]/1024., 0.01]}
      },
      Frame -> All
    ];
    result
  ],
  $ibpFailure
];

CoefficientSimplification[
    inputs : ({__Association} | {__String}),
    kiraFile_String,
    OptionsPattern[]
  ] := finiteFieldCoefficientSimplificationCore[
  inputs,
  ExpandFileName[kiraFile],
  <|
    "RatracerExecutable" -> OptionValue["RatracerExecutable"],
    "Threads" -> OptionValue["Threads"],
    "NormalizationKernels" -> OptionValue["NormalizationKernels"],
    "TargetTimeLimit" -> OptionValue["TargetTimeLimit"],
    "MaximumTargets" -> OptionValue["MaximumTargets"],
    "KeepWorkingFiles" -> OptionValue["KeepWorkingFiles"],
    "FactorScan" -> OptionValue["FactorScan"],
    "ShiftScan" -> OptionValue["ShiftScan"]
  |>
];

coefficientPairFileKey[file_String] := Module[{parts},
  parts = StringSplit[StringDrop[FileBaseName[file], 1], "_C"];
  If[
    Length[parts] === 2 && AllTrue[parts, StringMatchQ[DigitCharacter ..]],
    ToExpression /@ parts,
    {Infinity, Infinity}
  ]
];

coefficientResolveResultDirectory[
    projectDirectory_String,
    cardName_String,
    resultFolder_
  ] := Module[{project, results, candidates, candidate},
  project = ExpandFileName[projectDirectory];
  results = FileNameJoin[{project, "Results"}];
  If[! DirectoryQ[results], Return[$Failed]];
  candidate = Which[
    resultFolder === Automatic,
      candidates = Select[
        FileNames[cardName <> "_*", results],
        DirectoryQ[#] &&
          FileExistsQ[FileNameJoin[{#, "KiraResult.wl"}]] &&
          DirectoryQ[FileNameJoin[{#, "Pairs"}]] &&
          FileNames["F*_C*.wl", FileNameJoin[{#, "Pairs"}]] =!= {} &
      ];
      If[
        candidates === {},
        $Failed,
        Last @ SortBy[
          candidates,
          AbsoluteTime @ FileDate[FileNameJoin[{#, "KiraResult.wl"}]] &
        ]
      ],
    StringQ[resultFolder] && DirectoryQ[resultFolder],
      ExpandFileName[resultFolder],
    StringQ[resultFolder],
      ExpandFileName[FileNameJoin[{results, resultFolder}]],
    True,
      $Failed
  ];
  If[
    ! StringQ[candidate] || ! DirectoryQ[candidate] ||
      ! FileExistsQ[FileNameJoin[{candidate, "KiraResult.wl"}]] ||
      ! DirectoryQ[FileNameJoin[{candidate, "Pairs"}]],
    $Failed,
    candidate
  ]
];

coefficientRunProject[
    projectDirectory_String,
    cardName_String,
    resultFolder_,
    options_Association
  ] := Module[
  {
    project, cardFile, card, resultDirectory, pairDirectory,
    pairFiles, kiraFile, result, resultFile, temporaryFile, saved
  },
  coefficientProgressStart["Locating coefficient inputs", 1];
  project = ExpandFileName[projectDirectory];
  cardFile = FileNameJoin[{project, "Cards", cardName <> ".wl"}];
  card = If[
    FileExistsQ[cardFile],
    Quiet @ Check[Get[cardFile], $Failed],
    $Failed
  ];
  resultDirectory = coefficientResolveResultDirectory[
    project,
    cardName,
    resultFolder
  ];
  If[! AssociationQ[card] || resultDirectory === $Failed,
    coefficientProgressFailure[
      "input discovery",
      "the card or result folder is missing"
    ];
    Message[
      CoefficientSimplification::project,
      projectDirectory,
      cardName,
      "the card or result folder is missing"
    ];
    Return[$Failed]
  ];
  pairDirectory = FileNameJoin[{resultDirectory, "Pairs"}];
  pairFiles = SortBy[
    FileNames["F*_C*.wl", pairDirectory],
    coefficientPairFileKey
  ];
  kiraFile = FileNameJoin[{resultDirectory, "KiraResult.wl"}];
  If[pairFiles === {} || ! FileExistsQ[kiraFile],
    coefficientProgressFailure[
      "input discovery",
      "the pair files or KiraResult.wl are missing"
    ];
    Message[
      CoefficientSimplification::project,
      projectDirectory,
      cardName,
      "the pair files or KiraResult.wl are missing"
    ];
    Return[$Failed]
  ];
  result = finiteFieldCoefficientSimplificationCore[
    pairFiles,
    kiraFile,
    Join[options, <|"CoefficientSetup" -> card|>]
  ];
  If[result === $Failed, Return[$Failed]];
  coefficientProgressStage["Writing CoefficientResult.wl"];
  resultFile = FileNameJoin[{resultDirectory, "CoefficientResult.wl"}];
  temporaryFile = resultFile <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  result = Append[result, "CoefficientResultFile" -> resultFile];
  saved = Quiet @ Check[
    Put[result, temporaryFile];
    FileExistsQ[temporaryFile] && FileByteCount[temporaryFile] > 0,
    False
  ];
  If[! TrueQ[saved],
    If[FileExistsQ[temporaryFile], DeleteFile[temporaryFile]];
    coefficientProgressFailure[
      "result writing",
      resultFile
    ];
    Message[
      CoefficientSimplification::project,
      projectDirectory,
      cardName,
      "CoefficientResult.wl could not be written"
    ];
    Return[$Failed]
  ];
  If[FileExistsQ[resultFile], DeleteFile[resultFile]];
  If[
    Quiet @ Check[RenameFile[temporaryFile, resultFile]; True, False] =!= True,
    coefficientProgressFailure["result writing", resultFile];
    Message[
      CoefficientSimplification::project,
      projectDirectory,
      cardName,
      "the temporary result could not be installed"
    ];
    Return[$Failed]
  ];
  coefficientProgressFinish[];
  Print @ Grid[
    {
      {"Card", cardName},
      {"Result folder", FileNameTake[resultDirectory]},
      {"Pair files", Length[pairFiles]},
      {"Coefficient file", resultFile},
      {"File size (MB)", Round[FileByteCount[resultFile]/2.^20, 0.01]}
    },
    Frame -> All
  ];
  result
];

CoefficientSimplification[
    projectDirectory_String,
    cardName_String,
    OptionsPattern[]
  ] := coefficientRunProject[
  projectDirectory,
  cardName,
  Automatic,
  <|
    "RatracerExecutable" -> OptionValue["RatracerExecutable"],
    "Threads" -> OptionValue["Threads"],
    "NormalizationKernels" -> OptionValue["NormalizationKernels"],
    "TargetTimeLimit" -> OptionValue["TargetTimeLimit"],
    "MaximumTargets" -> OptionValue["MaximumTargets"],
    "KeepWorkingFiles" -> OptionValue["KeepWorkingFiles"],
    "FactorScan" -> OptionValue["FactorScan"],
    "ShiftScan" -> OptionValue["ShiftScan"]
  |>
];

CoefficientSimplification[
    projectDirectory_String,
    cardName_String,
    resultFolder : (Automatic | _String),
    OptionsPattern[]
  ] := coefficientRunProject[
  projectDirectory,
  cardName,
  resultFolder,
  <|
    "RatracerExecutable" -> OptionValue["RatracerExecutable"],
    "Threads" -> OptionValue["Threads"],
    "NormalizationKernels" -> OptionValue["NormalizationKernels"],
    "TargetTimeLimit" -> OptionValue["TargetTimeLimit"],
    "MaximumTargets" -> OptionValue["MaximumTargets"],
    "KeepWorkingFiles" -> OptionValue["KeepWorkingFiles"],
    "FactorScan" -> OptionValue["FactorScan"],
    "ShiftScan" -> OptionValue["ShiftScan"]
  |>
];
