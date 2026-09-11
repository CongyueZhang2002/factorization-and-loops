# FeynFacet/Coefficients/FiniteField/Traces.wl

finiteFieldMergeAssociationRecords[file_String, repeated_: True] := Module[
  {result = <||>, count},
  count = coefficientScanRecords[
    file,
    Function[record,
      If[! AssociationQ[record], Return[$Failed]];
      KeyValueMap[
        Function[{key, value},
          If[KeyExistsQ[result, key],
            If[repeated,
              AssociateTo[result, key -> (result[key] + value)],
              If[! SameQ[result[key], value], Return[$Failed]]
            ],
            AssociateTo[result, key -> value]
          ]
        ],
        record
      ];
      True
    ]
  ];
  If[count === $Failed, $Failed, result]
];

finiteFieldRationalSymbols[expression_] := DeleteDuplicates @ Cases[
  expression,
  symbol_Symbol /; finiteFieldRationalQ[symbol] :> symbol,
  Infinity,
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
      workerCount, workerData, jobs, chunks, chunkSize,
      normalizedChunks, normalizedBatch, failedResult, processingResult,
      existingKernels, launchedKernels = {}, loadFile, initialized,
      closeWorkers, progressTotal
    },

    manifest = Get[coefficientStoreManifestFile[store]];
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
    registerContribution[
        index_Integer,
        combined_HoldComplete,
        targetString_String,
        coefficient_
      ] := Module[{split},
      split = finiteFieldCanonicalizeSignature[combined, monomialExcluded];
      writeContribution[
        index,
        signatureID @ First[split],
        targetString,
        If[TrueQ[Last[split] === 1],
          coefficient,
          Last[split] coefficient
        ]
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
                      finiteFieldCombineSignatures[
                        signature,
                        coefficientSignature
                      ],
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
                  finiteFieldCombineSignatures[
                    signature,
                    remainderSignature
                  ],
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
            chunkSize = Max[
              1,
              Ceiling[Length[jobs]/(4 workerCount)]
            ];
            chunks = Partition[jobs, UpTo[chunkSize]];
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
    inputFingerprint_String, kiraHash_String
  ] := coefficientWriteRecord[
  finiteFieldTraceManifestFile[directory],
  <|
    "Format" -> "FeynFacet-TraceCheckpoint",
    "FormatVersion" -> $finiteFieldTraceCheckpointVersion,
    "InputFileFingerprint" -> inputFingerprint,
    "KiraFileHash" -> kiraHash,
    "TraceData" -> traceData
  |>
];

(* A valid checkpoint lets a fresh (small) kernel skip the
   normalization stage entirely: the expression files and the exact
   traceData are restored from disk, so the ratracer/FireFly forks
   happen from a low-RSS kernel. *)
finiteFieldRestoreTraceCheckpoint[
    directory_String, inputFingerprint_String, kiraHash_String
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
  {traceFile, inputsFile, outputsFile, arguments, result, seconds},
  traceFile = FileNameJoin[{directory, "MasterCoefficients.trace.gz"}];
  inputsFile = FileNameJoin[{directory, "TraceInputs.txt"}];
  outputsFile = FileNameJoin[{directory, "TraceOutputs.txt"}];
  (* A completed trace whose output list matches the checkpoint can be
     reused: rebuilding is deterministic given the same expressions. *)
  If[
    FileExistsQ[traceFile] && FileExistsQ[inputsFile] &&
      FileExistsQ[outputsFile] &&
      (* a zero-byte trace is a kill-during-write artifact, never a
         completed trace (0-byte reuse EXIT5, 2026-08-23) *)
      FileByteCount[traceFile] > 0 &&
      Length[
        Select[StringSplit[Import[outputsFile, "Text"], "\n"], # =!= "" &]
      ] === Length[traceData["OutputFiles"]],
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



# FeynFacet/Coefficients/FiniteField/Normalization.wl

(* A region equality alone never authorizes restriction of a distribution.
   The production caller supplies the actual external phase-space factor.
   This value-only implementation accepts a single unit delta; differentiated
   cuts need normal Taylor data and are deliberately left unsupported. *)
finiteFieldCoordinateSupportQ[context_Association]:=Module[
 {equalities=Lookup[context,"CoordinateEqualities",{}],distribution,argument,polynomial,ratio,variables},
 If[equalities==={},Return[True]];
 distribution=Lookup[context,"ExternalDistribution",None];
 If[Length[equalities]=!=1||!MatchQ[distribution,Cut[_,1]|Cut[_]],Return[False]];
 argument=First[distribution];
 If[KeyExistsQ[context,"HadronicVariables"],argument=applyHadronicVariables[argument,context["HadronicVariables"]]];
 (* Remove support equalities while simplifying the defining function:
    using them here would replace the very constraint being checked by zero. *)
 argument=FullSimplify[argument/.Lookup[context,"DimensionlessRules",{}],
  Assumptions->(Lookup[context,"DimensionlessAssumptions",True]/._Equal->True)];
 polynomial=Subtract@@(List@@First[equalities]);
 ratio=Cancel[argument/polynomial];variables=Lookup[context,"DimensionlessVariables",{}];
 FreeQ[ratio,Alternatives@@variables]&&TrueQ[FullSimplify[ratio!=0,
  Assumptions->Lookup[context,"DimensionlessAssumptions",True]]]
];
finiteFieldReduceCoordinateEqualities[expression_,context_Association]:=Module[
 {equalities=Lookup[context,"CoordinateEqualities",{}],variables,polynomials,basis,rational,numerator,denominator},
 If[equalities==={},Return[expression]];
 If[!finiteFieldCoordinateSupportQ[context],Return[$Failed]];
 variables=Reverse[Lookup[context,"DimensionlessVariables",{}]];
 polynomials=Subtract@@(List@@#)&/@equalities;
 If[variables==={}||!AllTrue[polynomials,PolynomialQ[#,variables]&],Return[$Failed]];
 basis=GroebnerBasis[polynomials,variables,MonomialOrder->Lexicographic];
 rational=Together[expression];
 numerator=Last[PolynomialReduce[Numerator[rational],basis,variables,MonomialOrder->Lexicographic]];
 denominator=Last[PolynomialReduce[Denominator[rational],basis,variables,MonomialOrder->Lexicographic]];
 If[denominator===0,Return[$Failed]];
 Factor[numerator/denominator]
];
(* Exact algebra for regulator-dependent powers of positive constants.
   Lift prime^epsilon and Pi^epsilon to formal Laurent variables, simplify
   rationally, then restore the same positive real branches. This exposes
   cancellations hidden by equivalent (2 Pi)^epsilon normalizations. *)
finiteFieldConstantPrimePowers[base_]:=Module[{factors,entries=<||>,add,valid=True},
 add[key_,power_]:=AssociateTo[entries,key->(Lookup[entries,key,0]+power)];
 factors=If[Head[base]===Times,List@@base,{base}];
 Do[Which[
  MatchQ[factor,_Integer|_Rational]&&factor>0,Scan[add[#[[1]],#[[2]]]&,FactorInteger[factor]],
  factor===Pi,add[Pi,1],
  MatchQ[factor,Power[Pi,_Integer]],add[Pi,Last[factor]],
  True,valid=False],{factor,factors}];
 If[valid,entries,$Failed]
];
finiteFieldNormalizeRegulatorConstants[expression_,e_Symbol]:=Module[
 {powers,records,base,exponent,constant,slope,factors,denominator,bases,generators,rules,lifted,restored},
 powers=DeleteDuplicates[Cases[expression,power:Power[_,exponent_]/;
  !FreeQ[exponent,e]&&PolynomialQ[exponent,e]&&Exponent[exponent,e]<=1:>power,{0,Infinity}]];
 records=DeleteCases[Map[Function[power,
  base=power[[1]];exponent=power[[2]];constant=exponent/.e->0;slope=Coefficient[exponent,e];
  factors=finiteFieldConstantPrimePowers[base];
  If[factors===$Failed||!MatchQ[{constant,slope},{_Integer|_Rational,_Integer|_Rational}],Nothing,
   <|"Power"->power,"Base"->base,"Constant"->constant,"Slope"->slope,"PrimePowers"->factors|>]],powers],Nothing];
 If[records==={},Return[expression]];
 denominator=LCM@@Denominator[Lookup[records,"Slope"]];
 bases=Union@@(Keys/@Lookup[records,"PrimePowers"]);
 generators=AssociationThread[bases,Unique["regulatorConstant$"]&/@bases];
 rules=Map[Function[record,record["Power"]->(record["Base"]^record["Constant"] Times@@KeyValueMap[
  Function[{prime,power},generators[prime]^(power denominator record["Slope"])],record["PrimePowers"]])],records];
 lifted=expression/.rules;
 restored=Factor[lifted]/.KeyValueMap[#2->#1^(e/denominator)&,generators];
 restored
];
finiteFieldNormalizeRegulatorConstants[expression_]:=Module[{regulators},
 regulators=DeleteDuplicates[Cases[expression,symbol_Symbol/;MemberQ[{"Epsilon","eps","ep"},SymbolName[symbol]]:>symbol,{0,Infinity}]];
 If[Length[regulators]===1,finiteFieldNormalizeRegulatorConstants[expression,First[regulators]],expression]
];

(* Shared finite-field reconstruction of exact master coefficients. *)

$finiteFieldReconstructionFormat =
  "FeynFacet-SharedFiniteFieldReconstruction";
$finiteFieldReconstructionVersion = 2;
$finiteFieldFailure = Unique["finiteFieldFailure$"];

CoefficientSimplification::finitefield =
  "Finite-field coefficient reconstruction failed during `1`: `2`.";

finiteFieldFail[stage_, detail_] := (
  coefficientProgressFailure[stage, detail];
  Message[CoefficientSimplification::finitefield, stage, detail];
  Throw[$Failed, $finiteFieldFailure]
);

finiteFieldResolveExecutable[value_] := Module[{environment, candidates},
  environment = Environment["FACET_RATRACER"];
  candidates = DeleteDuplicates @ Select[
    {
      value,
      If[ValueQ[Global`$FACETRatracerExecutable],
        Global`$FACETRatracerExecutable,
        Nothing
      ],
      If[StringQ[environment] && environment =!= "", environment, Nothing],
      FileNameJoin[{
        $feynFacetAddonRoot, "Addon", "Other_Addon", "Ratracer", "bin",
        "ratracer"
      }],
      Quiet @ Check[FindExecutable["ratracer"], Nothing]
    },
    StringQ
  ];
  SelectFirst[
    candidates,
    FileExistsQ[#] && TrueQ[FileType[#] === File] &,
    $Failed
  ]
];

finiteFieldThreadCount[value_] := Which[
  IntegerQ[value] && value > 0, value,
  value === Automatic && ValueQ[Global`$FACETKernelLimit] &&
      IntegerQ[Global`$FACETKernelLimit] && Global`$FACETKernelLimit > 0,
    Global`$FACETKernelLimit,
  value === Automatic, Max[1, $ProcessorCount],
  True, $Failed
];

finiteFieldPhysicalFactor[context_Association] := Module[
  {distribution, valuation, fractions},
  distribution = context["ExpectedDistributionFactor"];
  valuation = context["ExpectedLaurentValuation"];
  fractions = context["FractionVariables"];
  If[
    distribution === Automatic || ! AssociationQ[valuation] ||
      Sort[Keys[valuation]] =!= Sort[fractions],
    Return[$Failed]
  ];
  distribution Times @@ MapThread[
    Power,
    {fractions, Lookup[valuation, fractions]}
  ]
];

finiteFieldRationalQ[expression_] := Which[
  IntegerQ[expression] || MatchQ[expression, _Rational], True,
  Head[Unevaluated[expression]] === Symbol,
    ! MemberQ[
      {Pi, E, EulerGamma, I, Infinity, ComplexInfinity},
      Unevaluated[expression]
    ],
  Head[Unevaluated[expression]] === Plus ||
      Head[Unevaluated[expression]] === Times,
    AllTrue[List @@ expression, finiteFieldRationalQ],
  Head[Unevaluated[expression]] === Power && IntegerQ[expression[[2]]],
    finiteFieldRationalQ[expression[[1]]],
  True, False
];

finiteFieldSplitTerm[term_] := Module[
  {factors, rationalMask, rational, signature},
  factors = If[Head[term] === Times, List @@ term, {term}];
  rationalMask = finiteFieldRationalQ /@ factors;
  rational = Times @@ Pick[factors, rationalMask, True];
  signature = Times @@ Pick[factors, rationalMask, False];
  If[! SameQ[term, rational signature], Return[$Failed]];
  (HoldComplete @@ {signature}) -> rational
];

finiteFieldCancel[expression_, timeLimit_] := Module[{result},
  result = If[
    timeLimit === Infinity,
    Quiet @ CheckAbort[Check[Cancel[expression], $Failed], $Failed],
    TimeConstrained[
      Quiet @ CheckAbort[Check[Cancel[expression], $Failed], $Failed],
      timeLimit,
      $TimedOut
    ]
  ];
  If[exactDataQ[result], result, $Failed]
];

finiteFieldForbiddenQ[expression_, context_Association] := Module[
  {forbidden, heads, distributionObjects},
  forbidden = context["ForbiddenVariables"];
  heads = coefficientContextDistributionHeads[context];
  distributionObjects = Cases[
    HoldComplete[expression],
    object_ /; coefficientDistributionObjectQ[Unevaluated[object], heads] :>
      HoldComplete[object],
    Infinity
  ];
  distributionObjects =!= {} ||
    AnyTrue[forbidden, ! FreeQ[expression, #] &] ||
    ! FreeQ[expression, System`D]
];

(* --- rationalizing square-root substitution ------------------------ *)

$finiteFieldRootFailure = Unique["finiteFieldRootFailure$"];

CoefficientSimplification::rootbase =
  "A half-integer power survives rationalization: its base `1` is not an \
exact positive rational times a monomial in the declared positive \
quantities with a declared root substitution.";

CoefficientSimplification::rootparity =
  "A reconstructed coefficient is not even in the substitution variable \
`1`: the rationalized kinematics did not cancel.";

(* Structural decomposition base -> positive rational x monomial in the
   declared positive quantities.  Structural on purpose: positivity is
   read off the card region (0 < xa, xb, zh < 1, s > 0, x > 0, y > 0),
   never certified by FullSimplify. *)
finiteFieldRootMonomialData[base_, quantities_List] := Catch[
  Module[{factors, constant = 1, exponents},
    exponents = Association[# -> 0 & /@ quantities];
    factors = If[Head[base] === Times, List @@ base, {base}];
    Do[
      Which[
        KeyExistsQ[exponents, factor],
          exponents[factor] += 1,
        MatchQ[factor, Power[_, _Integer]] &&
            KeyExistsQ[exponents, factor[[1]]],
          exponents[factor[[1]]] += factor[[2]],
        MatchQ[factor, _Integer | _Rational] && TrueQ[factor > 0],
          constant *= factor,
        True,
          Throw[$Failed, $finiteFieldRootFailure]
      ],
      {factor, factors}
    ];
    <|"Constant" -> constant, "Exponents" -> exponents|>
  ],
  $finiteFieldRootFailure,
  $Failed &
];

(* Inject the value: HoldForm on the local symbol would leak the
   unevaluated variable name into the report. *)
finiteFieldRootFail[base_] := With[
  {reportedBase = base},
  Throw[HoldForm[reportedBase], $finiteFieldRootFailure]
];

(* base^(k/2) -> (rationalized base)^k.  The square root of the base is
   built symbolically: sqrt(constant) x product(rootVariable^power),
   with sqrt(constant) either rational or an exact constant root that
   the existing signature mechanism carries. *)
finiteFieldRationalizePower[
    power_,
    substitutions_Association,
    quantities_List
  ] := Module[{base, exponent, doubled, data, constant, monomial},
  base = power[[1]];
  exponent = power[[2]];
  If[FreeQ[base, Alternatives @@ quantities], Return[power]];
  doubled = 2 exponent;
  If[! IntegerQ[doubled], finiteFieldRootFail[base]];
  data = finiteFieldRootMonomialData[base, quantities];
  If[data === $Failed, finiteFieldRootFail[base]];
  constant = data["Constant"] Times @@ KeyValueMap[
    Function[{quantity, exponentValue},
      If[
        KeyExistsQ[substitutions, quantity],
        substitutions[quantity]["Constant"]^exponentValue,
        1
      ]
    ],
    data["Exponents"]
  ];
  monomial = Times @@ KeyValueMap[
    Function[{quantity, exponentValue},
      Which[
        KeyExistsQ[substitutions, quantity],
          substitutions[quantity]["Root"]^(exponentValue doubled),
        IntegerQ[exponentValue doubled/2],
          quantity^(exponentValue doubled/2),
        True,
          finiteFieldRootFail[base]
      ]
    ],
    data["Exponents"]
  ];
  constant^(doubled/2) monomial
];

(* No Cancel, no TimeConstrained, no FullSimplify: the reconstruction
   does not care whether the trace input is canceled. *)
finiteFieldRationalize[expression_, context_Association] := Catch[
  Module[{substitutions, quantities, powers, rules, substitutionRules},
    substitutions = Lookup[context, "RootSubstitutions", <||>];
    quantities = Lookup[context, "PositiveQuantities", {}];
    If[! AssociationQ[substitutions] || quantities === {},
      Return[expression]
    ];
    (* Level 0 included: a bare Sqrt can be the whole expression. *)
    powers = DeleteDuplicates @ Cases[
      expression,
      power : Power[_, _Rational] /; ! IntegerQ[power[[2]]] :> power,
      {0, Infinity}
    ];
    rules = Map[
      # -> finiteFieldRationalizePower[#, substitutions, quantities] &,
      powers
    ];
    substitutionRules = KeyValueMap[
      Function[{quantity, substitutionData},
        quantity -> substitutionData["Constant"] substitutionData["Root"]^2
      ],
      substitutions
    ];
    If[substitutionRules === {} && rules === {}, Return[expression]];
    (expression /. Dispatch[rules]) /. Dispatch[substitutionRules]
  ],
  $finiteFieldRootFailure,
  (Message[CoefficientSimplification::rootbase, #1]; $Failed) &
];

(* --- exact descend from the root ring back to physical variables ---

   Ported from an audited 2026-08-08 hadronic-simplification study.

   finiteFieldRationalize lifts an additive entry into Q(physical)[root].
   That lift must stay transient: FireFly probes the black box in the
   variables it is handed, and a root variable doubles the effective
   degree of its invariant (measured: ~100-fold probe inflation on a
   large production reconstruction,
   WORKLOG 2026-08-11).  The trace is therefore emitted in the physical
   variables, and the lift is undone here - entry by entry, before
   anything is written.

   For one family, an entry is N(r)/D(r) with r^2 = invariant.  Writing
   N = Ne + r No and D = De + r Do with Ne, No, De, Do free of r, the
   quotient is invariant under the branch flip r -> -r exactly when
   Ne Do - No De = 0, and then N/D = Ne/De.  The exact-zero
   certification runs on that SMALL combination only - never on a whole
   output.  Entries whose root content is already even skip the descend
   completely: their powers are restored structurally, with no rational
   algebra at all. *)

CoefficientSimplification::rootdescend =
  "An additive entry does not descend to the physical variables: its \
dependence on the root variable `1` is not even, and neither \
equal-denominator merging nor the merged remainder certified the odd \
part exactly zero.";

(* Per-kernel descend telemetry.  Block-bound around one target so the
   counters travel back with that target's record; Null outside means
   "not counting", never an error. *)
$finiteFieldDescendCounters = Null;

finiteFieldCountDescend[key_String, amount_: 1] := If[
  AssociationQ[$finiteFieldDescendCounters],
  $finiteFieldDescendCounters[key] =
    Lookup[$finiteFieldDescendCounters, key, 0] + amount
];

(* {root variable, invariant} per family; r^2 = quantity/constant. *)
finiteFieldRootFamilies[context_Association] := Module[{substitutions},
  substitutions = Lookup[context, "RootSubstitutions", <||>];
  If[! AssociationQ[substitutions], Return[{}]];
  KeyValueMap[
    Function[{quantity, substitutionData},
      {substitutionData["Root"], quantity/substitutionData["Constant"]}
    ],
    substitutions
  ]
];

finiteFieldRootEvenRestore[expression_, root_Symbol, invariant_] := With[
  {rootVariable = root, value = invariant},
  expression /. HoldPattern[
    Power[rootVariable, exponent_Integer /; EvenQ[exponent]]
  ] :> value^(exponent/2)
];

finiteFieldRootPolynomialRestore[
    polynomial_,
    root_Symbol,
    invariant_
  ] := Module[{direct, rules},
  direct = finiteFieldRootEvenRestore[polynomial, root, invariant];
  If[FreeQ[direct, root], Return[direct]];
  If[! PolynomialQ[polynomial, root], Return[$Failed]];
  rules = CoefficientRules[polynomial, {root}];
  If[! AllTrue[rules, EvenQ[First[First[#]]] &], Return[$Failed]];
  Total[(Last[#] invariant^(First[First[#]]/2)) & /@ rules]
];

finiteFieldRootEvenOddParts[
    polynomial_,
    root_Symbol,
    invariant_
  ] := Module[{rules},
  If[! PolynomialQ[polynomial, root], Return[$Failed]];
  rules = CoefficientRules[polynomial, {root}];
  <|
    "Even" -> Total @ Cases[
      rules,
      Rule[{power_Integer?EvenQ}, coefficient_] :>
        coefficient invariant^(power/2)
    ],
    "Odd" -> Total @ Cases[
      rules,
      Rule[{power_Integer?OddQ}, coefficient_] :>
        coefficient invariant^((power - 1)/2)
    ]
  |>
];

finiteFieldRootExactZeroQ[expression_, timeLimit_] := Module[{result},
  If[TrueQ[expression === 0], Return[True]];
  finiteFieldCountDescend["OddCertifications"];
  result = TimeConstrained[
    Quiet @ CheckAbort[
      Check[TrueQ[Cancel[Together[expression]] === 0], False],
      False
    ],
    timeLimit,
    $TimedOut
  ];
  If[result === $TimedOut, finiteFieldCountDescend["TimeConstrainedHits"]];
  result
];

(* The expression must already be a reduced N/D in the root variable. *)
finiteFieldRootDescendReduced[
    expression_,
    root_Symbol,
    invariant_,
    timeLimit_
  ] := Module[
  {
    numerator, denominator, restoredNumerator, restoredDenominator,
    numeratorParts, denominatorParts, pe, po, qe, qo, oddStatus,
    evenStatus, result
  },
  numerator = Numerator[expression];
  denominator = Denominator[expression];
  restoredNumerator = finiteFieldRootPolynomialRestore[
    numerator, root, invariant
  ];
  restoredDenominator = finiteFieldRootPolynomialRestore[
    denominator, root, invariant
  ];
  If[
    FreeQ[{restoredNumerator, restoredDenominator}, $Failed],
    finiteFieldCountDescend["EvenEntries"];
    Return @ finiteFieldCancel[
      restoredNumerator/restoredDenominator,
      timeLimit
    ]
  ];
  numeratorParts = finiteFieldRootEvenOddParts[numerator, root, invariant];
  denominatorParts = finiteFieldRootEvenOddParts[
    denominator, root, invariant
  ];
  If[MemberQ[{numeratorParts, denominatorParts}, $Failed],
    Return[$Failed]
  ];
  {pe, po} = Lookup[numeratorParts, {"Even", "Odd"}];
  {qe, qo} = Lookup[denominatorParts, {"Even", "Odd"}];
  (* The only nontrivial certification of the method, on the small
     combination pe qo - po qe - not on the entry itself. *)
  oddStatus = finiteFieldRootExactZeroQ[pe qo - po qe, timeLimit];
  If[oddStatus =!= True, Return[$Failed]];
  evenStatus = finiteFieldRootExactZeroQ[qe, timeLimit];
  result = Which[
    evenStatus === False, pe/qe,
    evenStatus === True,
      If[finiteFieldRootExactZeroQ[qo, timeLimit] === False,
        po/qo,
        Return[$Failed]
      ],
    True, Return[$Failed]
  ];
  finiteFieldCountDescend["DescendedEntries"];
  finiteFieldCancel[result, timeLimit]
];

finiteFieldRootDescend[
    expression_,
    root_Symbol,
    invariant_,
    timeLimit_
  ] := Module[{restored, rational, result},
  (* Structural first: an entry whose root powers are already even -
     the measured norm - never enters rational algebra at all. *)
  restored = finiteFieldRootEvenRestore[expression, root, invariant];
  If[FreeQ[restored, root],
    finiteFieldCountDescend["StructuralEntries"];
    Return[restored]
  ];
  rational = TimeConstrained[
    Quiet @ CheckAbort[
      Check[Cancel[Together[expression]], $Failed],
      $Failed
    ],
    timeLimit,
    $TimedOut
  ];
  If[rational === $TimedOut,
    finiteFieldCountDescend["TimeConstrainedHits"]
  ];
  If[MemberQ[{$Failed, $TimedOut}, rational], Return[$Failed]];
  result = finiteFieldRootDescendReduced[
    rational, root, invariant, timeLimit
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, result] || ! FreeQ[result, root] ||
      ! exactDataQ[result],
    $Failed,
    result
  ]
];

finiteFieldDescendEntry[entry_, families_List, timeLimit_] := Catch @ Module[
  {current = entry, descended},
  Do[
    If[FreeQ[current, First[family]], Continue[]];
    descended = finiteFieldRootDescend[
      current, First[family], Last[family], timeLimit
    ];
    If[descended === $Failed, Throw[$Failed]];
    current = descended,
    {family, families}
  ];
  current
];

(* Entry granularity of the 2026-08-08 study: descend the small pieces
   first and merge only exactly equal denominators when a piece does not
   descend on its own.  A whole-output Together never happens. *)
finiteFieldDescendEntries[
    entries_List,
    families_List,
    timeLimit_
  ] := Module[
  {roots, values, descended, residues, groups, sums, merged, failedRoot},
  If[families === {} || entries === {}, Return[entries]];
  roots = First /@ families;
  finiteFieldCountDescend["Entries", Length[entries]];
  values = Map[
    Function[entry,
      If[
        FreeQ[entry, Alternatives @@ roots],
        entry,
        finiteFieldDescendEntry[entry, families, timeLimit]
      ]
    ],
    entries
  ];
  descended = DeleteCases[values, $Failed];
  residues = MapThread[
    If[#2 === $Failed, #1, Nothing] &,
    {entries, values}
  ];
  If[residues === {}, Return[descended]];
  finiteFieldCountDescend["MergedEntries", Length[residues]];
  groups = Values @ GroupBy[residues, Denominator];
  sums = Total /@ groups;
  values = finiteFieldDescendEntry[#, families, timeLimit] & /@ sums;
  descended = Join[descended, DeleteCases[values, $Failed]];
  residues = MapThread[
    If[#2 === $Failed, #1, Nothing] &,
    {sums, values}
  ];
  If[residues === {}, Return[descended]];
  finiteFieldCountDescend["MergedRemainders"];
  merged = finiteFieldDescendEntry[Total[residues], families, timeLimit];
  If[merged === $Failed,
    failedRoot = SelectFirst[
      roots,
      ! FreeQ[residues, #] &,
      First[roots]
    ];
    Message[CoefficientSimplification::rootdescend, failedRoot];
    Return[$Failed]
  ];
  Append[descended, merged]
];

(* --- monomial variables carried by the signature, not by the trace ---

   Every entry is a monomial in the declared scale (mass-dimension
   homogeneity: exact on all measured outputs, WORKLOG 2026-08-11 16:30)
   and in the strong coupling.  Those powers ride along in the inert
   signature, so the trace variables reduce to the genuine rational
   kinematics.  The degree is read off structurally with the card's mass
   dimensions - no symbolic algebra, no evaluation at sample points.
   An entry that is not homogeneous simply keeps the variable: the
   emission stays exact, only the variable count grows. *)
finiteFieldMonomialVariables[context_Association] := Module[
  {scale, dimensions, scaleDimension},
  scale = Lookup[context, "Scale", None];
  dimensions = Lookup[context, "KinematicMassDimensions", <||>];
  scaleDimension = If[
    AssociationQ[dimensions] && MatchQ[scale, _Symbol],
    Lookup[dimensions, scale, 0],
    0
  ];
  Join[
    If[
      MatchQ[scale, _Symbol] && NumberQ[scaleDimension] &&
        TrueQ[scaleDimension > 0],
      {<|
        "Variable" -> scale,
        "Dimensions" -> KeyTake[dimensions, {scale}],
        "Unit" -> scaleDimension
      |>},
      {}
    ],
    {<|
      "Variable" -> FeynFacet`\[Alpha]s,
      "Dimensions" -> <|FeynFacet`\[Alpha]s -> 1|>,
      "Unit" -> 1
    |>}
  ]
];

finiteFieldMonomialStep[
    {monomial_, current_},
    data_Association
  ] := Module[{variable, degree, reduced},
  variable = data["Variable"];
  If[FreeQ[current, variable], Return[{monomial, current}]];
  degree = coefficientMassDimension[current, data["Dimensions"]];
  If[! NumberQ[degree], Return[{monomial, current}]];
  degree = degree/data["Unit"];
  If[! IntegerQ[degree], Return[{monomial, current}]];
  reduced = current /. variable -> 1;
  If[! FreeQ[reduced, variable], Return[{monomial, current}]];
  {monomial variable^degree, reduced}
];

finiteFieldMonomialSplit[entry_, monomialVariables_List] :=
  Fold[finiteFieldMonomialStep, {1, entry}, monomialVariables];

(* Signature module of a list of descended entries: an Association from
   an exact non-rational signature to an expression rational in the
   trace variables. *)
finiteFieldEntryModule[
    entries_List,
    monomialVariables_List
  ] := Module[{records},
  records = Catch @ Map[
    Function[term,
      Module[{monomial, reduced, split},
        {monomial, reduced} = finiteFieldMonomialSplit[
          term, monomialVariables
        ];
        split = finiteFieldSplitTerm[reduced];
        If[split === $Failed, Throw[$Failed]];
        If[
          TrueQ[monomial === 1],
          split,
          With[
            {signature = ReleaseHold[First[split]] monomial},
            (HoldComplete @@ {signature}) -> Last[split]
          ]
        ]
      ]
    ],
    Flatten[additiveTerms /@ entries, 1]
  ];
  If[records === $Failed, Return[$Failed]];
  Select[Merge[Association /@ records, Total], ! TrueQ[# === 0] &]
];

CoefficientSimplification::tracegrammar =
  "The `1` retains `2`, outside the variables allowed at this stage.";

(* The offending object itself, so a normalization failure names its
   cause instead of only its target. *)
finiteFieldTraceGrammarViolation[
    expression_,
    context_Association
  ] := Module[{candidates, offenders},
  candidates = Join[
    First /@ finiteFieldRootFamilies[context],
    Lookup[context, "ForbiddenVariables", {}],
    {System`D}
  ];
  offenders = Select[candidates, ! FreeQ[expression, #] &];
  Which[
    offenders =!= {},
      First[offenders],
    finiteFieldForbiddenQ[expression, context],
      HoldForm["a distribution object"],
    True,
      None
  ]
];

(* Post-reconstruction guard.  The descend leaves no root variable in
   the trace, so a reconstructed coefficient that carries one is a
   regression, not a parity accident: report it with the parity message
   the root-variable path used. *)
finiteFieldCertifyRootFree[
    expression_,
    context_Association
  ] := Module[{substitutions, roots, remaining},
  substitutions = Lookup[context, "RootSubstitutions", <||>];
  If[! AssociationQ[substitutions] || substitutions === <||>,
    Return[expression]
  ];
  roots = #["Root"] & /@ Values[substitutions];
  remaining = Select[roots, ! FreeQ[expression, #] &];
  If[remaining =!= {},
    Message[CoefficientSimplification::rootparity, First[remaining]];
    Return[$Failed]
  ];
  expression
];

(* Constant roots that rationalization leaves behind (Sqrt[2] from a
   base carrying an odd power of 2) ride along in the signature. *)
finiteFieldCombineSignatures[
    first_HoldComplete,
    second_HoldComplete
  ] := Which[
  second === HoldComplete[1], first,
  first === HoldComplete[1], second,
  True,
    With[
      {value = ReleaseHold[first] ReleaseHold[second]},
      HoldComplete[value]
    ]
];

(* --- signature canonicalization modulo the trace-variable field -----

   Trace classes are equal modulo the multiplicative group of the
   rational function field of the trace variables (Codex convention,
   2026-08-11): any factor of a signature that is rational in the trace
   variables belongs to the coefficient, e.g. 2^(m + n Epsilon) puts
   2^m into the coefficient and keeps 2^(n Epsilon).  Without this,
   classes fragment into buckets differing by 2^k (measured: master 107
   split into 9 buckets, master 1 into 13 buckets of one rational
   class), which multiplies the FireFly probe count.  The declared
   scale and the strong coupling route through signatures and are never
   folded. *)

finiteFieldFoldableFactorQ[expression_, excluded_List] :=
  finiteFieldRationalQ[expression] &&
    FreeQ[expression, Alternatives @@ excluded];

(* base^exponent with the integer part of the exponent's exact-number
   component split off: {folded factor, kept factor}.  Splitting an
   INTEGER power off b^(m + r) -> b^m b^r is an exact identity for any
   nonzero base; no positivity assumption is used. *)
finiteFieldResidualPower[base_, exponent_] := Module[
  {terms, constant, integerPart, residual},
  terms = If[Head[exponent] === Plus, List @@ exponent, {exponent}];
  constant = Total @ Cases[terms, _Integer | _Rational];
  integerPart = Floor[constant];
  residual = exponent - integerPart;
  Which[
    TrueQ[residual === 0], {base^integerPart, 1},
    IntegerQ[residual], {base^(integerPart + residual), 1},
    True, {If[integerPart === 0, 1, base^integerPart], base^residual}
  ]
];

finiteFieldCanonicalizeSignature[
    held_HoldComplete,
    excluded_List
  ] := Module[
  {signature, factors, fold = 1, keep = {}, primes = <||>, bases = <||>,
   resolve},
  signature = finiteFieldNormalizeRegulatorConstants[ReleaseHold[held]];
  If[finiteFieldFoldableFactorQ[signature, excluded],
    Return[{HoldComplete[1], signature}]
  ];
  factors = If[Head[signature] === Times, List @@ signature, {signature}];
  Scan[
    Function[factor,
      Which[
        finiteFieldFoldableFactorQ[factor, excluded],
          fold *= factor,
        Head[factor]===Complex && Re[factor]===0 &&
            MatchQ[Im[factor],_Integer|_Rational],
          fold *= Im[factor]; AppendTo[keep,I],
        (* A rational-number base decomposes over its primes: b^e with
           b = sign * Times[p^a] is exactly Times[p^(a e)] (positive
           base, principal branch), so 4^Epsilon and 2^(2 Epsilon) land
           in one class.  Exponents accumulate per prime, so pairs like
           2^Epsilon * 2^(1 - Epsilon) collapse before folding. *)
        MatchQ[factor, Power[_Integer | _Rational, _]],
          Module[{base = factor[[1]], exponent = factor[[2]], magnitude},
            magnitude = If[base < 0,
              primes[-1] = Lookup[primes, -1, 0] + exponent; -base,
              base
            ];
            Scan[
              If[#[[1]] =!= 1,
                primes[#[[1]]] = Lookup[primes, #[[1]], 0] + #[[2]] exponent
              ] &,
              FactorInteger[magnitude]
            ]
          ],
        MatchQ[factor, Power[_, _]] &&
            finiteFieldFoldableFactorQ[factor[[1]], excluded],
          bases[factor[[1]]] = Lookup[bases, factor[[1]], 0] + factor[[2]],
        True,
          AppendTo[keep, factor]
      ]
    ],
    factors
  ];
  resolve = Function[{base, exponent},
    Module[{pair = finiteFieldResidualPower[base, exponent]},
      fold *= First[pair];
      Last[pair]
    ]
  ];
  keep = Join[
    KeyValueMap[resolve, KeySort[primes]],
    KeyValueMap[
      resolve,
      KeySortBy[bases, ToString[#, InputForm] &]
    ],
    keep
  ];
  With[
    {canonical = Times @@ keep},
    {HoldComplete[canonical], fold}
  ]
];

(* Individual unreduced targets need not have fraction-independent
   coefficients. Keep declared rational fraction variables in the trace;
   require their absence only in the assembled common master coefficients. *)
finiteFieldTargetContext[context_Association]:=Join[context,<|
 "ForbiddenVariables"->Complement[Lookup[context,"ForbiddenVariables",{}],
  Lookup[context,"FractionVariables",{}]]|>];
finiteFieldCertifyPhysicalVariables[expression_,context_Association]:=Module[{value,remaining},
 (* Identities between color invariants and cancellation between analytic
    prefactors must be applied before testing the physical variable set. *)
 value=Factor[finiteFieldNormalizeRegulatorConstants[expression/.Lookup[context,"ColorRules",{}]]];
 If[!FreeQ[value,_DirectedInfinity|Indeterminate|$Failed|$Aborted],Return[$Failed]];
 value=finiteFieldReduceCoordinateEqualities[value,context];
 If[value===$Failed||!exactDataQ[value]||!FreeQ[value,_DirectedInfinity|Indeterminate|$Aborted],Return[$Failed]];
 value=finiteFieldCertifyRootFree[value,context];If[value===$Failed,Return[$Failed]];
 remaining=Select[Union[Lookup[context,"FractionVariables",{}],Lookup[context,"FractionRootVariables",{}]],
  !FreeQ[value,#]&];
 If[remaining=!={},Message[CoefficientSimplification::tracegrammar,"assembled master coefficient",First[remaining]];Return[$Failed]];
 value
];

finiteFieldNormalizeTarget[
    expression_,
    distributionFactor_,
    rationalLaurentFactor_,
    context_Association,
    timeLimit_
  ] := Module[
  {
    physical, distributionFreeTerms, distributionFree,
    dimensionless, rationalized, terms, descended, violation, module, admissibility
  },
  admissibility=finiteFieldTargetContext[context];
  physical = applyHadronicVariables[
    expression,
    context["HadronicVariables"]
  ];
  If[
    physical === $Failed || ! exactDataQ[physical],
    Return[$Failed]
  ];
  distributionFreeTerms =
    finiteFieldCancel[#/distributionFactor, timeLimit] & /@
      additiveTerms[physical];
  If[MemberQ[distributionFreeTerms, $Failed | $TimedOut], Return[$Failed]];
  distributionFree = Total[distributionFreeTerms];
  If[
    ! FreeQ[
      distributionFree,
      object_ /; coefficientDistributionObjectQ[Unevaluated[object],
        coefficientContextDistributionHeads[context]]
    ],
    Return[$Failed]
  ];
  dimensionless = distributionFree /. context["DimensionlessRules"];
  rationalized = finiteFieldRationalize[dimensionless, context];
  If[rationalized === $Failed, Return[$Failed]];
  terms = finiteFieldCancel[#/rationalLaurentFactor, timeLimit] & /@
    additiveTerms[rationalized];
  If[MemberQ[terms, $Failed | $TimedOut], Return[$Failed]];
  descended = finiteFieldDescendEntries[
    terms,
    finiteFieldRootFamilies[context],
    timeLimit
  ];
  If[descended === $Failed, Return[$Failed]];
  violation = finiteFieldTraceGrammarViolation[descended, admissibility];
  If[! exactDataQ[descended] || violation =!= None,
    Message[
      CoefficientSimplification::tracegrammar,
      "target coefficient",
      Replace[violation, None -> HoldForm["inexact data"]]
    ];
    Return[$Failed]
  ];
  module = finiteFieldEntryModule[
    descended,
    finiteFieldMonomialVariables[context]
  ];
  If[
    module === $Failed ||
      ! AllTrue[Values[module], finiteFieldRationalQ] ||
      AnyTrue[
        Keys[module],
        finiteFieldForbiddenQ[ReleaseHold[#], admissibility] &
      ],
    Return[$Failed]
  ];
  module
];

(* Returns the signature module of the rationalized Kira coefficient:
   an Association from an exact non-rational signature (normally 1) to
   an expression rational in the trace variables. *)
finiteFieldPrepareReductionCoefficient[
    expression_,
    metadata_Association,
    context_Association,
    timeLimit_
  ] := Module[{prepared, descended, violation, module},
  prepared = expression /.
    metadata["ReverseRules"] /. metadata["DimensionRule"];
  prepared = applyHadronicVariables[
    prepared,
    context["HadronicVariables"]
  ];
  If[prepared === $Failed || ! exactDataQ[prepared], Return[$Failed]];
  prepared = prepared /. context["DimensionlessRules"];
  prepared = finiteFieldRationalize[prepared, context];
  If[prepared === $Failed, Return[$Failed]];
  descended = finiteFieldDescendEntries[
    additiveTerms[prepared],
    finiteFieldRootFamilies[context],
    timeLimit
  ];
  If[descended === $Failed, Return[$Failed]];
  violation = finiteFieldTraceGrammarViolation[descended, context];
  If[! exactDataQ[descended] || violation =!= None,
    Message[
      CoefficientSimplification::tracegrammar,
      "Kira reduction coefficient",
      Replace[violation, None -> HoldForm["inexact data"]]
    ];
    Return[$Failed]
  ];
  module = finiteFieldEntryModule[
    descended,
    finiteFieldMonomialVariables[context]
  ];
  If[
    module === $Failed ||
      ! AllTrue[Values[module], finiteFieldRationalQ] ||
      AnyTrue[
        Keys[module],
        finiteFieldForbiddenQ[ReleaseHold[#], context] &
      ],
    Return[$Failed]
  ];
  module
];

finiteFieldNormalizationKernelCount[value_, targetCount_Integer] := Module[
  {limit},
  limit = Which[
    IntegerQ[value] && value > 0,
      value,
    value === Automatic && ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      facetKernelCount[Global`$FACETKernelLimit, targetCount],
    value === Automatic,
      facetKernelCount[Automatic, targetCount],
    True,
      $Failed
  ];
  If[limit === $Failed, $Failed,
    facetKernelCount[limit, targetCount]]
];

finiteFieldNormalizeTraceTarget[
    job_List,
    workerData_Association
  ] := Block[
  {$finiteFieldDescendCounters = <||>},
  With[
    {record = finiteFieldNormalizeTraceTargetCore[job, workerData]},
    If[
      AssociationQ[record] && ! FailureQ[record],
      Append[record, "DescendStatistics" -> $finiteFieldDescendCounters],
      record
    ]
  ]
];

finiteFieldNormalizeTraceTargetCore[
    {target_, expression_, rhs_},
    workerData_Association
  ] := Module[
  {
    targetModule, image, preparedTerms, preparedRemainder,
    failedMaster
  },
  targetModule = finiteFieldNormalizeTarget[
    expression,
    workerData["DistributionFactor"],
    workerData["RationalLaurentFactor"],
    workerData["Context"],
    workerData["TimeLimit"]
  ];
  If[
    targetModule === $Failed,
    Return @ Failure[
      "TargetNormalization",
      <|"Target" -> HoldComplete[target]|>
    ]
  ];
  image = linearIntegralSum[rhs];
  If[
    FailureQ[image],
    Return @ Failure["KiraImage", <|"Target" -> HoldComplete[target]|>]
  ];
  preparedTerms = Association @ KeyValueMap[
    Function[{master, coefficient},
      master -> finiteFieldPrepareReductionCoefficient[
        coefficient,
        workerData["ReductionMetadata"],
        workerData["Context"],
        workerData["TimeLimit"]
      ]
    ],
    image["Terms"]
  ];
  failedMaster = SelectFirst[
    Keys[preparedTerms],
    preparedTerms[#] === $Failed &,
    Missing["NotFound"]
  ];
  If[
    ! MissingQ[failedMaster],
    Return @ Failure[
      "KiraCoefficientNormalization",
      (* Inject the value: HoldComplete on the local symbol would leak
         the unevaluated variable name into the report. *)
      With[{failedMasterValue = failedMaster},
        <|
          "Target" -> HoldComplete[target],
          "Master" -> HoldComplete[failedMasterValue]
        |>
      ]
    ]
  ];
  preparedRemainder = finiteFieldPrepareReductionCoefficient[
    image["Remainder"],
    workerData["ReductionMetadata"],
    workerData["Context"],
    workerData["TimeLimit"]
  ];
  If[
    preparedRemainder === $Failed,
    Return @ Failure[
      "KiraCoefficientNormalization",
      <|
        "Target" -> HoldComplete[target],
        "Detail" -> "the scalar remainder does not rationalize"
      |>
    ]
  ];
  <|
    "Target" -> target,
    "TargetModule" -> targetModule,
    "PreparedTerms" -> preparedTerms,
    "PreparedRemainder" -> preparedRemainder
  |>
];

finiteFieldNormalizeTraceBatch[batch_List] :=
  finiteFieldNormalizeTraceTarget[
    #,
    $finiteFieldTraceWorkerData
  ] & /@ batch;

