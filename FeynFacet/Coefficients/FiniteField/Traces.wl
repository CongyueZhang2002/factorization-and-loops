finiteFieldMergeAssociationRecords[file_String, repeated_: True] := Module[
  {result = <||>, count, consistent = True},
  count = coefficientScanRecords[
    file,
    Function[record,
      If[! AssociationQ[record],
        $Failed,
        KeyValueMap[
          Function[{key, value},
            If[KeyExistsQ[result, key],
              If[repeated,
                AssociateTo[result, key -> (result[key] + value)],
                If[! SameQ[result[key], value], consistent = False]
              ],
              AssociateTo[result, key -> value]
            ]
          ],
          record
        ];
        If[consistent, True, $Failed]
      ]
    ]
  ];
  If[count === $Failed, $Failed, result]
];

finiteFieldRationalSymbols[expression_] := DeleteDuplicates @ Cases[
  expression,
  symbol_Symbol /; finiteFieldRationalQ[symbol] :> symbol,
  {0, Infinity},
  Heads -> False
];

finiteFieldToString[expression_, rules_] := Module[{text},
  text = ToString[
    expression /. rules,
    InputForm,
    CharacterEncoding -> "ASCII"
  ];
  StringReplace[text, WhitespaceCharacter .. -> ""]
];

finiteFieldTraceInputs[
    targetDirectory_String,
    store_String,
    metadata_Association,
    context_Association,
    physicalFactor_,
    directory_String,
    timeLimit_,
    maximumTargets_,
    normalizationKernels_: Automatic
  ] := Catch[
  Module[
    {
      manifest, shardCount, expectedByShard, expressionDirectory,
      distributionFactor, laurentFactor, rationalLaurentFactor,
      masters, masterIndices,
      signatures = {}, signatureBuckets = <||>, signatureID,
      signaturePairs = <||>, signaturePair, signaturePairCalls = 0,
      signaturePairMisses = 0,
      symbolRules = <||>, aliasPrefix, registerSymbols, aliasRules,
      outputFiles = <||>, outputMetadata = <||>, firstTerm = <||>,
      contributionCounts = <||>, streams = <||>, streamOrder = {},
      streamLimit = 128, outputKey, outputFile, getStream, closeStreams,
      writeContribution, emitNormalizedTarget, targetTerms, ruleTerms,
      expected, keys, reductionString, masterIndex,
      processed = 0, selectedTargets, targetLimit, shard, remainder,
      remainderModule, outputOrder, traceVariables, signatureRegistry,
      descendStatistics = <||>, scalePowers, monomialExcluded,
      registerContribution,
      workerCount, workerData, jobs, chunks,
      normalizedChunks, normalizedBatch, failedResult, processingResult,
      existingKernels, launchedKernels = {}, loadFile, initialized,
      closeWorkers, progressTotal
    },

    manifest = FeynFacet`FamilyArtifactRead[coefficientStoreManifestFile[store]];
    shardCount = manifest["ShardCount"];
    expectedByShard = GroupBy[
      metadata["Targets"],
      coefficientShardIndex[#, shardCount] &
    ];
    expressionDirectory = FileNameJoin[{directory, "Expressions"}];
    CreateDirectory[
      expressionDirectory,
      CreateIntermediateDirectories -> True
    ];

    distributionFactor = context["ExpectedDistributionFactor"];
    laurentFactor = Cancel[physicalFactor/distributionFactor];
    rationalLaurentFactor = finiteFieldRationalize[
      laurentFactor /. context["DimensionlessRules"],
      context
    ];
    If[rationalLaurentFactor === $Failed,
      finiteFieldFail[
        "physical normalization",
        "the declared distribution and Laurent factor do not rationalize"
      ]
    ];

    masters = metadata["Masters"];
    masterIndices = AssociationThread[masters, Range[Length[masters]]];
    monomialExcluded =
      #["Variable"] & /@ finiteFieldMonomialVariables[context];
    aliasPrefix = "FACETff" <>
      StringReplace[StringTake[CreateUUID[], 8], "-" -> ""] <> "v";

    signatureID[signature_] := Module[
      {hash, candidates, existing, id},
      hash = Hash[signature, "SHA256", "HexString"];
      candidates = Lookup[signatureBuckets, hash, {}];
      existing = SelectFirst[
        candidates,
        SameQ[signatures[[#]], signature] &,
        Missing["NotFound"]
      ];
      If[! MissingQ[existing], Return[existing]];
      AppendTo[signatures, signature];
      id = Length[signatures];
      AssociateTo[signatureBuckets, hash -> Append[candidates, id]];
      id
    ];

    registerSymbols[expression_] := Scan[
      Function[symbol,
        If[! KeyExistsQ[symbolRules, symbol],
          AssociateTo[
            symbolRules,
            symbol -> Symbol[
              "Global`" <> aliasPrefix <> ToString[Length[symbolRules] + 1]
            ]
          ]
        ]
      ],
      SortBy[
        finiteFieldRationalSymbols[expression],
        ToString[Unevaluated[#], InputForm] &
      ]
    ];

    outputKey[index_Integer, id_Integer] :=
      IntegerString[index, 10, 6] <> "_" <> IntegerString[id, 10, 6];

    getStream[key_String] := Module[{oldest, stream},
      If[KeyExistsQ[streams, key],
        streamOrder = Append[DeleteCases[streamOrder, key], key];
        Return[streams[key]]
      ];
      If[Length[streams] >= streamLimit,
        oldest = First[streamOrder];
        Close[streams[oldest]];
        KeyDropFrom[streams, oldest];
        streamOrder = Rest[streamOrder]
      ];
      stream = OpenAppend[outputFiles[key]];
      If[Head[stream] =!= OutputStream,
        finiteFieldFail["trace emission", "an expression file could not be opened"]
      ];
      AssociateTo[streams, key -> stream];
      AppendTo[streamOrder, key];
      stream
    ];

    closeStreams[] := (
      Scan[Close, Values[streams]];
      streams = <||>;
      streamOrder = {};
    );

    writeContribution[
        index_Integer,
        id_Integer,
        targetString_String,
        reductionCoefficient_
      ] := Module[{key, stream, separator},
      (* Zero contributions create nothing.  A stale 16-byte
         zero-content output file was found in the ghost set; an output
         that never receives a nonzero term must not exist at all. *)
      If[TrueQ[reductionCoefficient === 0] || targetString === "0",
        Return[Null]
      ];
      registerSymbols[reductionCoefficient];
      aliasRules = Dispatch[Normal[symbolRules]];
      reductionString = finiteFieldToString[
        reductionCoefficient,
        aliasRules
      ];
      key = outputKey[index, id];
      If[! KeyExistsQ[outputFiles, key],
        outputFile = FileNameJoin[{
          expressionDirectory,
          "Output_" <> key <> ".expr"
        }];
        If[FileExistsQ[outputFile], DeleteFile[outputFile]];
        Close[OpenWrite[outputFile]];
        AssociateTo[outputFiles, key -> outputFile];
        AssociateTo[firstTerm, key -> True];
        AssociateTo[contributionCounts, key -> 0];
        AssociateTo[
          outputMetadata,
          key -> <|
            "MasterIndex" -> index,
            "SignatureIndex" -> id
          |>
        ]
      ];
      stream = getStream[key];
      separator = If[TrueQ[firstTerm[key]], "", "+"];
      WriteString[
        stream,
        separator, "(", targetString, ")*(", reductionString, ")"
      ];
      firstTerm[key] = False;
      contributionCounts[key] = contributionCounts[key] + 1;
    ];

    (* Every contribution registers through the canonicalized class:
       the rational-in-trace-variables part of the combined signature
       folds into the coefficient, so buckets differing by such a
       factor merge at registration. *)
    (* Cache the exact ordered pair within this invocation. Both the
       canonical class ID and its folded rational factor are needed. *)
    signaturePair[a_HoldComplete,b_HoldComplete] := Module[{key,stored,split},
      signaturePairCalls++;
      key=HoldComplete[a,b];
      stored=Lookup[signaturePairs,key,Missing["NotFound"]];
      If[!MissingQ[stored],Return[stored]];
      signaturePairMisses++;
      split=finiteFieldCanonicalizeSignature[
        finiteFieldCombineSignatures[a,b],monomialExcluded];
      stored={signatureID[First[split]],Last[split]};
      AssociateTo[signaturePairs,key->stored];
      stored
    ];

    registerContribution[
        index_Integer,
        a_HoldComplete,
        b_HoldComplete,
        targetString_String,
        coefficient_
      ] := Module[{pair},
      pair=signaturePair[a,b];
      writeContribution[
        index,
        First[pair],
        targetString,
        If[TrueQ[Last[pair]===1],coefficient,Last[pair] coefficient]
      ]
    ];

    emitNormalizedTarget[record_Association] := Module[
      {targetModule, preparedTerms, preparedRemainder},
      targetModule = record["TargetModule"];
      preparedTerms = record["PreparedTerms"];
      preparedRemainder = record["PreparedRemainder"];
      KeyValueMap[
        Function[{signature, rationalTarget},
          Module[{targetString},
            registerSymbols[rationalTarget];
            aliasRules = Dispatch[Normal[symbolRules]];
            targetString = finiteFieldToString[
              rationalTarget,
              aliasRules
            ];
            KeyValueMap[
              Function[{master, coefficientModule},
                masterIndex = Lookup[
                  masterIndices,
                  master,
                  Missing["UnknownMaster"]
                ];
                If[MissingQ[masterIndex],
                  finiteFieldFail["Kira image", HoldForm[master]]
                ];
                KeyValueMap[
                  Function[{coefficientSignature, reductionCoefficient},
                    registerContribution[
                      masterIndex,
                      signature,
                      coefficientSignature,
                      targetString,
                      reductionCoefficient
                    ]
                  ],
                  coefficientModule
                ]
              ],
              preparedTerms
            ];
            KeyValueMap[
              Function[{remainderSignature, rationalRemainder},
                registerContribution[
                  0,
                  signature,
                  remainderSignature,
                  targetString,
                  rationalRemainder
                ]
              ],
              preparedRemainder
            ]
          ]
        ],
        targetModule
      ];
      processed++
    ];

    targetLimit = If[maximumTargets === All, Infinity, maximumTargets];
    If[
      ! (targetLimit === Infinity ||
          (IntegerQ[targetLimit] && targetLimit > 0)),
      finiteFieldFail[
        "trace emission",
        "MaximumTargets must be All or a positive integer"
      ]
    ];
    progressTotal = Min[targetLimit, Length[metadata["Targets"]]];
    coefficientProgressStart["Normalizing target coefficients", progressTotal];
    workerCount = finiteFieldNormalizationKernelCount[
      normalizationKernels,
      Min[
        Length[metadata["Targets"]],
        If[targetLimit === Infinity, Length[metadata["Targets"]], targetLimit]
      ]
    ];
    If[workerCount === $Failed,
      finiteFieldFail[
        "normalization kernel configuration",
        normalizationKernels
      ]
    ];
    workerData = <|
      "DistributionFactor" -> distributionFactor,
      "RationalLaurentFactor" -> rationalLaurentFactor,
      "Context" -> context,
      "TimeLimit" -> timeLimit,
      "ReductionMetadata" -> KeyTake[
        metadata,
        {"ReverseRules", "DimensionRule"}
      ]
    |>;
    closeWorkers[] := (
      If[workerCount > 1 && Kernels[] =!= {},
        Quiet @ ParallelEvaluate[
          Clear[FeynFacet`Private`$finiteFieldTraceWorkerData],
          Kernels[]
        ]
      ];
      If[launchedKernels =!= {},
        Quiet[CloseKernels[launchedKernels]];
        launchedKernels = {}
      ]
    );
    If[workerCount > 1,
      existingKernels = Kernels[];
      If[Length[existingKernels] < workerCount,
        launchedKernels = facetLaunchKernels[
          workerCount - Length[existingKernels]
        ]
      ];
      If[Kernels[] === {},
        workerCount = 1,
        workerCount = Length[Kernels[]];
        loadFile = $feynFacetLoader;
        initialized = With[{file = loadFile, data = workerData},
          And @@ ParallelEvaluate[
            Block[{$Output = {}, $Messages = {}},
              Global`$FeynCalcStartupMessages = False;
              Quiet[Get[file]];
              FeynFacet`Private`$finiteFieldTraceWorkerData = data;
              Length[
                DownValues[
                  FeynFacet`Private`finiteFieldNormalizeTraceBatch
                ]
              ] > 0
            ],
            Kernels[]
          ]
        ];
        If[! TrueQ[initialized],
          closeWorkers[];
          finiteFieldFail[
            "parallel target normalization",
            "the Mathematica workers did not initialize"
          ]
        ]
      ]
    ];

    processingResult = CheckAbort[
      Catch[
        Do[
          If[processed >= targetLimit, Break[]];
          targetTerms = finiteFieldMergeAssociationRecords[
            coefficientShardFile[targetDirectory, "Targets", shard],
            True
          ];
          ruleTerms = finiteFieldMergeAssociationRecords[
            coefficientShardFile[store, "Rules", shard],
            False
          ];
          If[targetTerms === $Failed || ruleTerms === $Failed,
            finiteFieldFail[
              "stored target reading",
              "a target or Kira-rule shard is invalid"
            ]
          ];
          expected = Lookup[expectedByShard, shard, {}];
          keys = Keys[targetTerms];
          If[
            Length[keys] =!= Length[expected] ||
              ! ContainsAll[keys, expected] ||
              ! ContainsAll[expected, keys],
            finiteFieldFail[
              "stored target reading",
              "the target and Kira shard keys differ"
            ]
          ];
          selectedTargets = Take[
            SortBy[keys, ToString[Unevaluated[#], InputForm] &],
            UpTo[
              If[
                targetLimit === Infinity,
                Length[keys],
                targetLimit - processed
              ]
            ]
          ];
          jobs = Function[currentTarget,
            {
              currentTarget,
              targetTerms[currentTarget] /. metadata["DimensionRule"],
              Lookup[ruleTerms, currentTarget, currentTarget]
            }
          ] /@ selectedTargets;
          normalizedBatch = If[workerCount === 1,
            finiteFieldNormalizeTraceTarget[#, workerData] & /@ jobs,
            (* Target sizes vary widely; independent jobs avoid serializing
               expensive neighbours inside the same worker batch. *)
            chunks = List /@ jobs;
            normalizedChunks = ParallelMap[
              FeynFacet`Private`finiteFieldNormalizeTraceBatch,
              chunks,
              Method -> "FinestGrained",
              DistributedContexts -> None
            ];
            If[! ListQ[normalizedChunks],
              $Failed,
              Flatten[normalizedChunks, 1]
            ]
          ];
          failedResult = If[ListQ[normalizedBatch],
            SelectFirst[normalizedBatch, FailureQ, Missing["NotFound"]],
            $Failed
          ];
          If[
            normalizedBatch === $Failed || ! MissingQ[failedResult],
            finiteFieldFail[
              "parallel target normalization",
              If[failedResult === $Failed, "a worker failed", failedResult]
            ]
          ];
          (* Lookup on a list of Associations only threads in its
             two-argument form; the three-argument form reads the list
             as a rule list and quietly returns the default. *)
          descendStatistics = Merge[
            Join[
              {descendStatistics},
              Map[Lookup[#, "DescendStatistics", <||>] &, normalizedBatch]
            ],
            Total
          ];
          Scan[emitNormalizedTarget, normalizedBatch];
          coefficientProgressUpdate[processed, progressTotal];
          If[$FrontEnd===Null&&(Mod[shard,4]===0||shard===shardCount),
            Print["Normalized ",processed," / ",progressTotal," coefficient targets (",
              shard," / ",shardCount," input partitions)"]];
          Clear[
            targetTerms, ruleTerms, jobs, chunks, normalizedChunks,
            normalizedBatch
          ];
          ClearSystemCache[],
          {shard, shardCount}
        ];
        True,
        $finiteFieldFailure
      ],
      closeWorkers[];
      Abort[]
    ];
    closeWorkers[];
    If[processingResult === $Failed,
      Throw[$Failed, $finiteFieldFailure]
    ];

    If[processed >= Length[metadata["Targets"]],
      remainder = coefficientBalancedRecordTotal[
        FileNameJoin[{targetDirectory, "Remainder.bin"}]
      ];
      If[remainder === $Failed,
        finiteFieldFail["stored target reading", "the scalar remainder is invalid"]
      ];
      If[! TrueQ[remainder === 0],
        remainderModule = finiteFieldNormalizeTarget[
          remainder /. metadata["DimensionRule"],
          distributionFactor,
          rationalLaurentFactor,
          context,
          timeLimit
        ];
        If[remainderModule === $Failed,
          finiteFieldFail["target normalization", "the scalar remainder failed"]
        ];
        KeyValueMap[
          Function[{signature, rationalRemainder},
            Module[{id, targetString},
              id = signatureID[signature];
              registerSymbols[rationalRemainder];
              aliasRules = Dispatch[Normal[symbolRules]];
              targetString = finiteFieldToString[
                rationalRemainder,
                aliasRules
              ];
              writeContribution[0, id, targetString, 1]
            ]
          ],
          remainderModule
        ]
      ]
    ];

    closeStreams[];
    (* An output key exists only once a nonzero contribution reached it;
       anything else is dropped from the trace instead of being written
       as a zero-content expression file. *)
    Scan[
      Function[key,
        If[TrueQ[firstTerm[key]],
          If[FileExistsQ[outputFiles[key]],
            DeleteFile[outputFiles[key]]
          ];
          KeyDropFrom[outputFiles, key];
          KeyDropFrom[outputMetadata, key];
          KeyDropFrom[contributionCounts, key]
        ]
      ],
      Keys[outputFiles]
    ];
    outputOrder = SortBy[
      Keys[outputFiles],
      {
        outputMetadata[#]["MasterIndex"],
        outputMetadata[#]["SignatureIndex"]
      } &
    ];
    Scan[
      Function[key,
        Module[{stream = OpenAppend[outputFiles[key]]},
          If[Head[stream] =!= OutputStream,
            finiteFieldFail[
              "trace emission",
              "an expression file could not be finalized"
            ]
          ];
          WriteString[stream, "\n"];
          Close[stream]
        ]
      ],
      outputOrder
    ];
    traceVariables = SortBy[
      Keys[symbolRules],
      ToString[Unevaluated[#], InputForm] &
    ];
    signatureRegistry = AssociationThread[
      Range[Length[signatures]],
      signatures
    ];
    (* Scale monomiality is an exact property of the emitted data here:
       the scale rides in the signature, so its per-output power is read
       off the signature rather than fitted. *)
    scalePowers = If[
      MatchQ[context["Scale"], _Symbol],
      Map[
        Exponent[
          ReleaseHold[signatures[[outputMetadata[#]["SignatureIndex"]]]],
          context["Scale"]
        ] &,
        outputOrder
      ],
      ConstantArray[0, Length[outputOrder]]
    ];
    <|
      "PhysicalFactor" -> physicalFactor,
      "NormalizationKernels" -> workerCount,
      "ProcessedTargetCount" -> processed,
      "CompleteTargetSet" -> TrueQ[processed === Length[metadata["Targets"]]],
      "TargetCount" -> Length[metadata["Targets"]],
      "Masters" -> masters,
      "Signatures" -> signatureRegistry,
      "SymbolRules" -> symbolRules,
      "Variables" -> traceVariables,
      "OutputOrder" -> outputOrder,
      "OutputFiles" -> Lookup[outputFiles, outputOrder],
      "OutputMetadata" -> Lookup[outputMetadata, outputOrder],
      "ContributionCounts" -> Lookup[contributionCounts, outputOrder],
      "ScalePowers" -> scalePowers,
      "DescendStatistics" -> descendStatistics,
      "SignaturePairCacheStatistics" -> <|
        "Calls" -> signaturePairCalls, "Misses" -> signaturePairMisses,
        "Entries" -> Length[signaturePairs]|>,
      "ExpressionBytes" -> FileByteCount /@ Lookup[outputFiles, outputOrder]
    |>
  ],
  $finiteFieldFailure
];

finiteFieldRunProcess[arguments_List, directory_String, log_String] := Module[
  {temporary, command, result},
  temporary = FileNameJoin[{directory, "Temporary"}];
  If[DirectoryQ[temporary], DeleteDirectory[temporary, DeleteContents -> True]];
  CreateDirectory[temporary, CreateIntermediateDirectories -> True];
  command = Join[{"/usr/bin/env", "TMPDIR=" <> temporary}, arguments];
  result = Quiet @ Check[RunProcess[command], $Failed];
  (* A fork failure from a large kernel (observed on WSL2 with a
     multi-GB session) returns no process Association at all. Say so,
     instead of exporting an unevaluated Lookup. *)
  If[! AssociationQ[result],
    Export[
      log,
      "RunProcess failed to launch the process (no result). " <>
        "Kernel MemoryInUse (MB): " <>
        ToString[Round[MemoryInUse[]/2.^20]] <>
        ". Re-running in a fresh kernel resumes from the trace " <>
        "checkpoint with a small footprint.",
      "Text"
    ];
    Return[$Failed]
  ];
  Export[
    log,
    Lookup[result, "StandardOutput", ""] <>
      Lookup[result, "StandardError", ""],
    "Text"
  ];
  If[DirectoryQ[temporary], DeleteDirectory[temporary, DeleteContents -> True]];
  If[Lookup[result, "ExitCode", 1] === 0, result, $Failed]
];

$finiteFieldTraceManifestName = "TraceManifest.wxf";

(* Version 2 is the physical-variable trace: a version-1 checkpoint
   holds root-variable expressions and must never be restored into the
   current emitter. *)
$finiteFieldTraceCheckpointVersion = 2;

finiteFieldTraceManifestFile[directory_String] :=
  FileNameJoin[{directory, $finiteFieldTraceManifestName}];

finiteFieldWriteTraceManifest[
    directory_String, traceData_Association,
    inputFingerprint_String, kiraHash_String, normalizationDefinition_Association
  ] := coefficientWriteRecord[
  finiteFieldTraceManifestFile[directory],
  <|
    "Format" -> "FeynFacet-TraceCheckpoint",
    "FormatVersion" -> $finiteFieldTraceCheckpointVersion,
    "InputFileFingerprint" -> inputFingerprint,
    "KiraFileHash" -> kiraHash,
    "NormalizationDefinition" -> normalizationDefinition,
    "TraceData" -> traceData
  |>
];

(* A valid checkpoint lets a fresh (small) kernel skip the
   normalization stage entirely: the expression files and the exact
   traceData are restored from disk, so the ratracer/FireFly forks
   happen from a low-RSS kernel. *)
finiteFieldRestoreTraceCheckpoint[
    directory_String, inputFingerprint_String, kiraHash_String, normalizationDefinition_Association
  ] := Module[{file, record, traceData, reason},
  file = finiteFieldTraceManifestFile[directory];
  If[! FileExistsQ[file], Return[$Failed]];
  record = Quiet @ Check[coefficientReadRecord[file], $Failed];
  reason = Which[
    ! AssociationQ[record],
      "the manifest record could not be read",
    record["Format"] =!= "FeynFacet-TraceCheckpoint",
      "unexpected manifest format",
    record["FormatVersion"] =!= $finiteFieldTraceCheckpointVersion,
      "the checkpoint predates the physical-variable trace (stored " <>
        ToString[record["FormatVersion"]] <> " vs current " <>
        ToString[$finiteFieldTraceCheckpointVersion] <> ")",
    record["InputFileFingerprint"] =!= inputFingerprint,
      "the pair-source fingerprint changed (stored " <>
        ToString[record["InputFileFingerprint"]] <> " vs current " <>
        inputFingerprint <> ")",
    record["KiraFileHash"] =!= kiraHash,
      "the Kira artifact hash changed",
    Lookup[record,"NormalizationDefinition",None] =!= normalizationDefinition,
      "the normalization definition or requested target coverage changed",
    ! AssociationQ[record["TraceData"]],
      "the stored trace data is not an Association",
    ! AllTrue[
        record["TraceData"]["OutputFiles"],
        (* OutputFiles are absolute paths; FileNameJoin would
           concatenate, not reset, on an absolute second component. *)
        FileExistsQ[
          If[StringStartsQ[#, "/"], #, FileNameJoin[{directory, #}]]
        ] &
      ],
      "an expression file named by the checkpoint is missing",
    True,
      None
  ];
  If[reason =!= None,
    Print["Trace checkpoint present but not restorable: ", reason];
    Return[$Failed]
  ];
  record["TraceData"]
];

finiteFieldBuildTrace[
    traceData_Association,
    executable_String,
    directory_String
  ] := Module[
  {traceFile, inputsFile, outputsFile, arguments, result, seconds,
   binding, bindingFile, savedBinding, listedOutputs},
  traceFile = FileNameJoin[{directory, "MasterCoefficients.trace.gz"}];
  inputsFile = FileNameJoin[{directory, "TraceInputs.txt"}];
  outputsFile = FileNameJoin[{directory, "TraceOutputs.txt"}];
  bindingFile = FileNameJoin[{directory, "TraceBinding.wl"}];
  binding = <|"Version" -> 1,
    "Definitions" -> KeyTake[traceData, {"Masters", "OutputMetadata", "OutputOrder",
      "SymbolRules", "Signatures", "Variables", "PhysicalFactor", "CompleteTargetSet"}],
    "OutputFiles" -> traceData["OutputFiles"],
    "InputHashes" -> coefficientFileHashes[traceData["OutputFiles"]],
    "ExecutableHash" -> coefficientFileHash[executable]|>;
  savedBinding = If[FileExistsQ[bindingFile],
    Quiet[Check[FeynFacet`FamilyArtifactRead[bindingFile], $Failed]], $Failed];
  listedOutputs = If[FileExistsQ[outputsFile],
    StringReplace[Select[StringSplit[Import[outputsFile, "Text"], "\n"], # =!= "" &],
      StartOfString ~~ DigitCharacter .. ~~ " " -> ""], {}];
  (* The source expressions and ordered output definitions, not just their
     number, determine the trace. Compaction must never reuse an earlier trace. *)
  If[
    FileExistsQ[traceFile] && FileExistsQ[inputsFile] &&
      FileExistsQ[outputsFile] &&
      (* a zero-byte trace is a kill-during-write artifact, never a
         completed trace (0-byte reuse EXIT5, 2026-08-23) *)
      FileByteCount[traceFile] > 0 &&
      savedBinding === binding && listedOutputs === traceData["OutputFiles"],
    Print["Reusing the existing shared trace (",
      Round[FileByteCount[traceFile]/2.^20, 0.1], " MB)"];
    Return[<|
      "TraceFile" -> traceFile,
      "InputsFile" -> inputsFile,
      "OutputsFile" -> outputsFile,
      "BuildSeconds" -> 0,
      "TraceBytes" -> FileByteCount[traceFile]
    |>]
  ];
  arguments = Join[
    {executable},
    Flatten[
      {"trace-expression", #} & /@ traceData["OutputFiles"]
    ],
    {
      "optimize", "finalize", "save-trace", traceFile,
      "list-inputs", "--to=" <> inputsFile,
      "list-outputs", "--to=" <> outputsFile
    }
  ];
  (* RunProcess cannot launch a process with thousands of arguments
     (measured: 100 fine, 4400 returns no result), and one large trace
     names 2203 expression files. Route the command through a script;
     the OS itself handles the argv fine (proven from a shell). *)
  Module[{script},
    script = FileNameJoin[{directory, "BuildTrace.sh"}];
    Export[
      script,
      StringRiffle[
        {
          "#!/bin/bash",
          "set -u",
          StringRiffle[
            "'" <> StringReplace[#, "'" -> "'\\''"] <> "'" & /@
              arguments,
            " "
          ]
        },
        "\n"
      ] <> "\n",
      "String"
    ];
    arguments = {"/bin/bash", script}
  ];
  {seconds, result} = AbsoluteTiming @ finiteFieldRunProcess[
    arguments,
    directory,
    FileNameJoin[{directory, "BuildTrace.log"}]
  ];
  If[result === $Failed, Return[$Failed]];
  listedOutputs = StringReplace[
    Select[StringSplit[Import[outputsFile, "Text"], "\n"], # =!= "" &],
    StartOfString ~~ DigitCharacter .. ~~ " " -> ""];
  If[listedOutputs =!= traceData["OutputFiles"] ||
     !FileExistsQ[traceFile] || FileByteCount[traceFile] === 0, Return[$Failed]];
  If[FeynFacet`FamilyArtifactWrite[binding, bindingFile, "Compression" -> True] === $Failed ||
     FeynFacet`FamilyArtifactRead[bindingFile] =!= binding, Return[$Failed]];
  <|
    "TraceFile" -> traceFile,
    "InputsFile" -> inputsFile,
    "OutputsFile" -> outputsFile,
    "BuildSeconds" -> seconds,
    "TraceBytes" -> FileByteCount[traceFile]
  |>
];

finiteFieldParseRational[expression_, aliasNames_List] := Which[
  IntegerQ[expression] || MatchQ[expression, _Rational], True,
  Head[Unevaluated[expression]] === Symbol,
    MemberQ[aliasNames, SymbolName[Unevaluated[expression]]],
  Head[Unevaluated[expression]] === Plus ||
      Head[Unevaluated[expression]] === Times,
    AllTrue[
      List @@ expression,
      finiteFieldParseRational[#, aliasNames] &
    ],
  Head[Unevaluated[expression]] === Power && IntegerQ[expression[[2]]],
    finiteFieldParseRational[expression[[1]], aliasNames],
  True, False
];

finiteFieldParseReconstruction[
    file_String,
    outputFiles_List,
    symbolRules_Association
  ] := Module[
  {
    text, markers, positions, strings, held, aliasNames,
    aliasOriginals, parsedAliases, reverseRules, expressions
  },
  text = Import[file, "Text"];
  markers = (# <> " =") & /@ outputFiles;
  positions = StringPosition[text, #, 1] & /@ markers;
  If[AnyTrue[positions, # === {} &], Return[$Failed]];
  positions = First /@ positions;
  strings = Table[
    StringTrim @ StringReplace[
      StringTake[
        text,
        {
          positions[[index, 2]] + 1,
          If[index < Length[positions],
            positions[[index + 1, 1]] - 1,
            StringLength[text]
          ]
        }
      ],
      RegularExpression[";\\s*$"] -> ""
    ],
    {index, Length[positions]}
  ];
  held = Quiet @ Check[
    Map[ToExpression[#, InputForm, HoldComplete] &, strings],
    $Failed
  ];
  If[held === $Failed || Length[held] =!= Length[outputFiles],
    Return[$Failed]
  ];
  aliasNames = SymbolName /@ Values[symbolRules];
  aliasOriginals = AssociationThread[aliasNames, Keys[symbolRules]];
  expressions = ReleaseHold /@ held;
  If[
    ! AllTrue[
      expressions,
      finiteFieldParseRational[#, aliasNames] &
    ],
    Return[$Failed]
  ];
  parsedAliases = DeleteDuplicates @ Cases[
    expressions,
    symbol_Symbol /; MemberQ[aliasNames, SymbolName[symbol]] :> symbol,
    Infinity
  ];
  reverseRules = Dispatch[
    (# -> aliasOriginals[SymbolName[#]]) & /@ parsedAliases
  ];
  expressions /. reverseRules
];

finiteFieldReconstructTrace[
    traceData_Association,
    trace_Association,
    executable_String,
    directory_String,
    threads_Integer,
    factorScan_,
    shiftScan_
  ] := Module[
  {resultFile, arguments, result, seconds, expressions},
  resultFile = FileNameJoin[{directory, "Reconstructed.txt"}];
  arguments = Join[
    {
      executable, "load-trace", trace["TraceFile"], "reconstruct",
      "--to=" <> resultFile,
      "--threads=" <> ToString[threads],
      "--inmem"
    },
    If[TrueQ[factorScan], {"--factor-scan"}, {}],
    If[TrueQ[shiftScan], {"--shift-scan"}, {}]
  ];
  {seconds, result} = AbsoluteTiming @ finiteFieldRunProcess[
    arguments,
    directory,
    FileNameJoin[{directory, "Reconstruct.log"}]
  ];
  If[result === $Failed, Return[$Failed]];
  expressions = finiteFieldParseReconstruction[
    resultFile,
    traceData["OutputFiles"],
    traceData["SymbolRules"]
  ];
  If[expressions === $Failed, Return[$Failed]];
  <|
    "Expressions" -> expressions,
    "ResultFile" -> resultFile,
    "ReconstructionSeconds" -> seconds,
    "ResultBytes" -> FileByteCount[resultFile]
  |>
];
