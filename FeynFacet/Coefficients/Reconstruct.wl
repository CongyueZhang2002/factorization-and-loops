finiteFieldCoefficientSimplificationCore[
    inputs_List,
    kiraFile_String,
    options_Association
  ] := Catch[
  Module[
    {
      executable, threads, normalizationKernels, timeLimit,
      maximumTargets, keepFiles,
      store, storeManifest, metadata, data, sortedPairs,
      coefficientSetup, resultSetup, processSetup, process,
      currentContext, resultData,
      workDirectory, targetDirectory, context, physicalFactor,
      traceDirectory, traceData, trace, reconstruction, result,
      manifestFile
    },
    coefficientProgressStart["Preparing coefficient inputs", 1];
    executable = finiteFieldResolveExecutable[
      options["RatracerExecutable"]
    ];
    threads = finiteFieldThreadCount[options["Threads"]];
    normalizationKernels = options["NormalizationKernels"];
    timeLimit = options["TargetTimeLimit"];
    maximumTargets = options["MaximumTargets"];
    keepFiles = TrueQ[options["KeepWorkingFiles"]];
    If[executable === $Failed,
      finiteFieldFail[
        "Ratracer discovery",
        "set FACET_RATRACER or install the executable under Addon/Other_Addon/Ratracer/bin"
      ]
    ];
    If[threads === $Failed,
      finiteFieldFail["thread configuration", options["Threads"]]
    ];
    If[
      ! MatchQ[timeLimit, Infinity | _Integer | _Real] ||
        (timeLimit =!= Infinity && timeLimit <= 0),
      finiteFieldFail["target time limit", timeLimit]
    ];

    store = coefficientEnsureKiraStore[kiraFile];
    If[store === $Failed,
      finiteFieldFail["Kira store", kiraFile]
    ];
    storeManifest = Get[coefficientStoreManifestFile[store]];
    metadata = coefficientReadRecord[coefficientStoreMetadataFile[store]];
    If[
      ! AssociationQ[metadata] ||
        ! coefficientKiraReductionQ[Append[metadata, "KiraRules" -> {}]],
      finiteFieldFail["Kira store", "the indexed metadata is invalid"]
    ];
    data = Block[
      {analyticContextQ = coefficientAnalyticContextQ},
      ibpInputData[inputs, False]
    ];
    sortedPairs[list_List] := SortBy[
      list,
      {Lookup[#1, "Forward"], Lookup[#1, "Conjugate"]} &
    ];
    If[
      data["CardName"] =!= metadata["CardName"] ||
        ! coefficientSameInputsQ[data, metadata] ||
        sortedPairs[data["Pairs"]] =!= sortedPairs[metadata["Pairs"]],
      finiteFieldFail[
        "input validation",
        "the Kira artifact belongs to another diagram set"
      ]
    ];
    coefficientSetup = Lookup[options, "CoefficientSetup", Automatic];
    resultSetup = If[
      AssociationQ[coefficientSetup],
      Join[
        data["Setup"],
        KeyTake[coefficientSetup, $coefficientLateSetupKeys]
      ],
      data["Setup"]
    ];
    processSetup = Join[
      resultSetup,
      <|
        "ForwardAmplitudes" -> Append[
          resultSetup["ForwardAmplitudes"],
          "SelectedIndex" -> First[data["Pairs"]]["Forward"]
        ],
        "ConjugateAmplitudes" -> Append[
          resultSetup["ConjugateAmplitudes"],
          "SelectedIndex" -> First[data["Pairs"]]["Conjugate"]
        ]
      |>
    ];
    process = Catch[
      normalizeProcess[processSetup],
      $collinearFailure
    ];
    currentContext = If[
      AssociationQ[process],
      analyticContext[process],
      $Failed
    ];
    If[currentContext === $Failed,
      finiteFieldFail[
        "card validation",
        "the current card does not define a valid analytic context"
      ]
    ];
    resultData = Join[
      data,
      <|
        "Setup" -> resultSetup,
        "AnalyticContext" -> currentContext
      |>
    ];
    context = BuildSimplificationContext[resultSetup];
    If[context === $Failed,
      finiteFieldFail["card validation", "the simplification context is invalid"]
    ];
    physicalFactor = finiteFieldPhysicalFactor[context];
    If[physicalFactor === $Failed,
      finiteFieldFail[
        "card validation",
        "finite-field reconstruction requires a declared distribution factor and Laurent valuation"
      ]
    ];

    workDirectory = coefficientWorkDirectory[kiraFile];
    targetDirectory = FileNameJoin[{workDirectory, "TargetRecords"}];
    If[
      ! coefficientTargetStoreValidQ[
        data,
        metadata,
        targetDirectory,
        storeManifest["ShardCount"]
      ],
      coefficientProgressStart[
        "Collecting diagram-pair coefficients",
        Length[data["Sources"]]
      ];
      If[
        Block[
          {analyticContextQ = coefficientAnalyticContextQ},
          coefficientCollectTargetRecords[
            data,
            metadata,
            targetDirectory,
            storeManifest["ShardCount"]
          ]
        ] === $Failed,
        finiteFieldFail[
          "target collection",
          "the diagram-pair coefficients could not be indexed"
        ]
      ]
    ];

    traceDirectory = FileNameJoin[{workDirectory, "FiniteField"}];
    traceData = finiteFieldRestoreTraceCheckpoint[
      traceDirectory,
      coefficientInputFileFingerprint[data["Sources"]],
      coefficientFileHash[kiraFile]
    ];
    If[AssociationQ[traceData],
      coefficientProgressStage["Restored the trace checkpoint"];
      Print["Reusing the normalized trace checkpoint (",
        Length[traceData["OutputFiles"]], " outputs)"],
      If[coefficientResetDirectory[traceDirectory] === $Failed,
        finiteFieldFail["working directory", traceDirectory]
      ];
      traceData = finiteFieldTraceInputs[
        targetDirectory,
        store,
        metadata,
        context,
        physicalFactor,
        traceDirectory,
        timeLimit,
        maximumTargets,
        normalizationKernels
      ];
      If[traceData === $Failed,
        finiteFieldFail["trace emission", "target normalization failed"]
      ];
      If[
        finiteFieldWriteTraceManifest[
          traceDirectory,
          traceData,
          coefficientInputFileFingerprint[data["Sources"]],
          coefficientFileHash[kiraFile]
        ] === $Failed,
        finiteFieldFail["trace checkpoint", "could not write the manifest"]
      ]
    ];
    If[traceData["OutputFiles"] === {},
      finiteFieldFail["trace emission", "all reconstructed coefficients are zero"]
    ];
    coefficientProgressStage["Building the shared rational trace"];
    trace = finiteFieldBuildTrace[traceData, executable, traceDirectory];
    If[trace === $Failed,
      finiteFieldFail["shared trace construction", "Ratracer returned an error"]
    ];
    coefficientProgressStage["Reconstructing rational coefficients"];
    reconstruction = finiteFieldReconstructTrace[
      traceData,
      trace,
      executable,
      traceDirectory,
      threads,
      options["FactorScan"],
      options["ShiftScan"]
    ];
    If[reconstruction === $Failed,
      finiteFieldFail["rational reconstruction", "FireFly returned an error"]
    ];
    coefficientProgressStage["Assembling master coefficients"];
    result = finiteFieldAssembleResult[
      resultData,
      metadata,
      kiraFile,
      context,
      traceData,
      trace,
      reconstruction,
      executable,
      threads
    ];
    If[result === $Failed,
      finiteFieldFail[
        "result assembly",
        "the reconstructed coefficients violate the declared kinematics or cut data"
      ]
    ];
    coefficientProgressStage["Writing reconstruction metadata"];
    manifestFile = FileNameJoin[{traceDirectory, "Manifest.wl"}];
    Put[
      <|
        "Format" -> $finiteFieldReconstructionFormat,
        "FormatVersion" -> $finiteFieldReconstructionVersion,
        "InputFileFingerprint" -> coefficientInputFileFingerprint[
          data["Sources"]
        ],
        "KiraFileHash" -> coefficientFileHash[kiraFile],
        "PhysicalFactor" -> physicalFactor,
        "TraceData" -> KeyDrop[
          traceData,
          {"SymbolRules", "Signatures"}
        ],
        "Signatures" -> traceData["Signatures"],
        "SymbolRules" -> traceData["SymbolRules"],
        "Reconstruction" -> result["FiniteFieldReconstruction"]
      |>,
      manifestFile
    ];
    (* Cleanup is performed by the project writer only after the final
       result has been saved and read back successfully. *)
    Print @ Grid[
      {
        {"Targets", traceData["ProcessedTargetCount"]},
        {"Normalization kernels", traceData["NormalizationKernels"]},
        {"Masters", Length[result["Masters"]]},
        {"Analytic prefactors", Length[traceData["Signatures"]]},
        {"Reconstruction outputs", Length[traceData["OutputOrder"]]},
        {
          "Reconstruction variables",
          ToString[traceData["Variables"], InputForm]
        },
        {
          "Scale powers",
          ToString[
            MinMax[Append[Lookup[traceData, "ScalePowers", {}], 0]],
            InputForm
          ]
        },
        {
          "Algebraic normalization",
          ToString[
            Normal @ Lookup[traceData, "DescendStatistics", <||>],
            InputForm
          ]
        },
        {"Reconstruction input (MB)", Round[trace["TraceBytes"]/2.^20, 0.01]},
        {
          "FireFly time (s)",
          Round[reconstruction["ReconstructionSeconds"], 0.01]
        }
      },
      Frame -> All
    ];
    coefficientProgressFinish[];
    coefficientResultFromReconstruction[result]
  ],
  $finiteFieldFailure
];
