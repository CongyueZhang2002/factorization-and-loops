(* Bounded-memory reconstruction and exact simplification of IBP coefficients. *)

CoefficientSimplification::collect =
  "Bounded target collection failed at check `1`: `2`.";

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
    (* same shape validation as analyticContextQ (Core.wl): the rule must
       be D -> a - 2 regulator with integer a, not identity with the
       front end's own $dimensionRule *)
    analyticDimensionRuleQ[context["DimensionRule"],
      analyticContextRegulator[context]] &&
    StringQ[context["FeynFacetSourceHash"]] &&
    context["Fingerprint"] ===
      reductionFingerprint[KeyDrop[context, "Fingerprint"]] &&
    exactDataQ[context]
];

coefficientKiraReductionQ[kira_] := Block[
  {analyticContextQ = coefficientAnalyticContextQ},
  kiraReductionQ[kira]
];

(* Do a freshly read input set and a stored artifact describe the same
   diagram set?  This used to be answered by comparing the two stored
   ABSOLUTE result directories, so moving or renaming a result tree
   turned every stored artifact into "another diagram set".  The
   analytic-context fingerprint is the content identity of the inputs
   (scheme, basis, kinematics, dimension rule, source hash) and is what
   is compared now; an artifact that carries no fingerprint on either
   side falls back to the stored paths, exactly as before (generality
   pass 2026-08-23). *)
coefficientContextFingerprint[data_] := Lookup[
  Lookup[data, "AnalyticContext", <||>], "Fingerprint",
  Missing["NoFingerprint"]
];

coefficientSameInputsQ[data_, stored_] := Module[{left, right, a, b},
  left = coefficientContextFingerprint[data];
  right = coefficientContextFingerprint[stored];
  If[StringQ[left] && StringQ[right], Return[left === right]];
  a = Lookup[data, "ResultDirectory", Missing[]];
  b = Lookup[stored, "ResultDirectory", Missing[]];
  StringQ[a] && StringQ[b] && ExpandFileName[a] === ExpandFileName[b]
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

(* The scratch workspace this module writes into.  It is
   <workspace root>/Codex/<process>/CoefficientSimplification/<run>; only
   the ROOT used to be a literal ($feynFacetRoot), which tied the store
   to the package's parent directory.  It now comes from
   $feynFacetWorkspaceRoot (Core.wl, default $feynFacetRoot, override
   Global`$FACETWorkspaceRoot), so the default path is unchanged and an
   installation may put its scratch space elsewhere.  The delete guard
   below is checked against exactly this root. *)
coefficientCodexRoot[] :=
  FileNameJoin[{$feynFacetWorkspaceRoot, "Codex"}];

coefficientSafeWorkPathQ[path_String] :=
  coefficientSafeWorkPathQ[path, coefficientCodexRoot[]];

coefficientSafeWorkPathQ[path_String, workspaceRoot_String] :=
  Module[{root, normalized},
    root = ExpandFileName[workspaceRoot] <> $PathnameSeparator;
    normalized = ExpandFileName[path] <> $PathnameSeparator;
    StringStartsQ[normalized, root] && normalized =!= root
  ];

coefficientResetDirectory[path_String] := Module[{},
  If[! coefficientSafeWorkPathQ[path], Return[$Failed]];
  If[DirectoryQ[path], DeleteDirectory[path, DeleteContents -> True]];
  CreateDirectory[path, CreateIntermediateDirectories -> True];
  path
];

(* The name of the results folder in the <process>/<results>/<run>
   layout this front end uses.  It only NAMES the scratch workspace: a
   tree that does not follow the convention falls back to "Reduction"
   and keeps working, so this is a label, never a gate. *)
$coefficientResultsFolderName = "Results";

coefficientProcessName[kiraFile_String] := Module[
  {resultDirectory, resultsDirectory, processDirectory},
  resultDirectory = DirectoryName[ExpandFileName[kiraFile]];
  resultsDirectory = DirectoryName[resultDirectory];
  processDirectory = DirectoryName[resultsDirectory];
  If[FileNameTake[resultsDirectory] =!= $coefficientResultsFolderName,
    Return["Reduction"]];
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

(* Every fail-closed exit of coefficientCollectTargetRecords names its check:
   a silent Return[$Failed] here cost a full diagnostic cycle on 2026-08-10. *)
coefficientCollectFail[check_String, detail_] := (
  Message[
    CoefficientSimplification::collect,
    check,
    If[StringQ[detail], detail, ToString[detail, InputForm]]
  ];
  $Failed
);

coefficientCollectSourceLabel[source_] := If[
  StringQ[source],
  source,
  "an in-memory pre-IBP result"
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
  If[coefficientResetDirectory[directory] === $Failed,
    Return[
      coefficientCollectFail[
        "target directory reset",
        "could not create the target record directory " <> directory
      ]
    ]
  ];
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
          If[! validPreIBPResultQ[result],
            Return[
              coefficientCollectFail[
                "pre-IBP source validation",
                "could not read a valid pre-IBP result from " <>
                  coefficientCollectSourceLabel[source]
              ],
              Module
            ]
          ];
          rawParts = linearIntegralSum[result["Integrand"]];
          If[FailureQ[rawParts],
            Return[
              coefficientCollectFail[
                "source integrand linearity",
                "the integrand of " <> coefficientCollectSourceLabel[source] <>
                  " is not a linear sum of explicit GLI objects"
              ],
              Module
            ]
          ];
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
          If[FailureQ[sourceParts],
            Return[
              coefficientCollectFail[
                "canonical GLI mapping",
                "the verified topology rules did not map " <>
                  coefficientCollectSourceLabel[source] <>
                  " to a linear GLI sum"
              ],
              Module
            ]
          ];
          sourceMomenta = coefficientForbiddenMomenta[result["Setup"]];
          offendingMomenta = remainingDeclaredMomenta[
            {Values[sourceParts["Terms"]], sourceParts["Remainder"]},
            sourceMomenta
          ];
          If[offendingMomenta =!= {},
            Return[
              coefficientCollectFail[
                "integrated momenta in a source coefficient",
                coefficientCollectSourceLabel[source] <> " still contains " <>
                  ToString[offendingMomenta, InputForm]
              ],
              Module
            ]
          ];
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
            Return[
              coefficientCollectFail[
                "target shard write",
                "could not append a target record to " <>
                  coefficientShardFile[directory, "Targets", shard]
              ],
              Module
            ]
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
  If[sourceFingerprint =!= metadata["SourceInputFingerprint"],
    Return[
      coefficientCollectFail[
        "source input fingerprint",
        "the collected topology records and raw targets do not reproduce the " <>
          "fingerprint stored by the reduction (collected " <>
          ToString[sourceFingerprint] <> ", stored " <>
          ToString[metadata["SourceInputFingerprint"]] <> ")"
      ]
    ]
  ];
  targetSet = Keys[mappedSeen];
  kiraTargetSet = metadata["Targets"];
  If[
    Length[targetSet] =!= Length[kiraTargetSet] ||
      ! ContainsAll[targetSet, kiraTargetSet] ||
      ! ContainsAll[kiraTargetSet, targetSet],
    Return[
      coefficientCollectFail[
        "target set equality",
        "the collected targets differ from the targets reduced by Kira (" <>
          ToString[Length[targetSet]] <> " collected, " <>
          ToString[Length[kiraTargetSet]] <> " reduced, " <>
          ToString[Length[Complement[targetSet, kiraTargetSet, SameTest -> SameQ]]] <>
          " collected-only, " <>
          ToString[Length[Complement[kiraTargetSet, targetSet, SameTest -> SameQ]]] <>
          " reduced-only)"
      ]
    ]
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

coefficientKernelLimit[count_Integer] := Min[
  count,
  If[
    ValueQ[Global`$FACETKernelLimit] &&
      IntegerQ[Global`$FACETKernelLimit] && Global`$FACETKernelLimit > 0,
    Global`$FACETKernelLimit,
    $ProcessorCount
  ]
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
