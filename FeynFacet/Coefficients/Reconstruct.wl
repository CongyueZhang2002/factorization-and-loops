finiteFieldCoefficientSimplificationCore[
    inputs_List,
    kiraFile_String,
    options_Association
  ] := Catch[
  Module[
    {
      executable, threads, normalizationKernels, timeLimit,
      maximumTargets, keepFiles,
      store, storeManifest, metadata, data,
      coefficientSetup, resultSetup, processSetup, process,
      currentContext, resultData,
      workDirectory, targetDirectory, context, physicalFactor,
      traceDirectory, nativeDirectory, traceData, trace, reconstruction, result,
      manifestFile, inputFingerprint, normalizationDefinition
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
    storeManifest = FeynFacet`FamilyArtifactRead[coefficientStoreManifestFile[store]];
    metadata = coefficientReadRecord[coefficientStoreMetadataFile[store]];
    If[
      ! AssociationQ[metadata] ||
        ! coefficientKiraReductionQ[Append[metadata, "KiraRules" -> {}]],
      finiteFieldFail["Kira store", "the indexed metadata is invalid"]
    ];
    workDirectory = coefficientWorkDirectory[kiraFile];
    targetDirectory = FileNameJoin[{workDirectory, "TargetRecords"}];
    data = coefficientPrepareInputRecords[inputs,metadata,store,targetDirectory,storeManifest["ShardCount"]];
    If[!AssociationQ[data],finiteFieldFail["target collection","pair definitions and coefficients could not be collected"]];
    If[!coefficientInputMatchesReductionQ[data,metadata],
      finiteFieldFail["input validation","the Kira artifact belongs to another diagram set"]];
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

    normalizationDefinition=<|"Context"->context,"PhysicalFactor"->physicalFactor,
      "InputCompanions"->coefficientInputCompanions[data["Sources"]],
      "MaximumTargets"->Min[maximumTargets,Length[metadata["Targets"]]]|>;
    traceDirectory = FileNameJoin[{workDirectory, "FiniteField"}];
    traceData = finiteFieldRestoreTraceCheckpoint[
      traceDirectory,
      coefficientInputFileFingerprint[data["Sources"]],
      coefficientFileHash[kiraFile],normalizationDefinition
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
          coefficientFileHash[kiraFile],normalizationDefinition
        ] === $Failed,
        finiteFieldFail["trace checkpoint", "could not write the manifest"]
      ]
    ];
    If[traceData["OutputFiles"] === {},
      finiteFieldFail["trace emission", "all reconstructed coefficients are zero"]
    ];
    coefficientProgressStage["Compacting rational coefficient summands"];
    traceData = finiteFieldCompactTrace[traceData, traceDirectory,
      normalizationKernels, options["CompactAboveBytes"],
      options["CompactionEntrySeconds"], options["CompactionColumnSeconds"]];
    If[!AssociationQ[traceData],
      finiteFieldFail["rational summand compaction", traceData]];
    nativeDirectory = If[KeyExistsQ[traceData, "Compaction"],
      traceData["Compaction"]["Directory"], traceDirectory];
    coefficientProgressStage["Executing the coefficient reconstruction plan"];
    result = finiteFieldExecuteCoefficientPlan[
      <|"TraceDirectory"->traceDirectory,"Data"->resultData,"Metadata"->metadata,
        "KiraFile"->kiraFile,"Context"->context|>,traceData,nativeDirectory,executable,
      Join[options,<|"Threads"->threads|>],Lookup[options,"ReconstructionPlan",Automatic]];
    If[!AssociationQ[result],
      finiteFieldFail["scheduled coefficient reconstruction",result]];
    coefficientProgressStage["Writing reconstruction metadata"];
    manifestFile = FileNameJoin[{traceDirectory, "Manifest.wl"}];
    FeynFacet`FamilyArtifactWrite[
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
      manifestFile, "Compression"->True
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
        {"Reconstruction input (MB)", Round[result["FiniteFieldReconstruction"]["TraceBytes"]/2.^20, 0.01]},
        {
          "FireFly time (s)",
          Round[result["FiniteFieldReconstruction"]["ReconstructionSeconds"], 0.01]
        }
      },
      Frame -> All
    ];
    coefficientProgressFinish[];
    inputFingerprint=coefficientInputFileFingerprint[Sort[ExpandFileName/@data["Sources"]]];
    If[!StringQ[inputFingerprint],finiteFieldFail["coefficient input identity","explicit pair files are required"]];
    coefficientResultFromReconstruction[Join[result,<|"InputFileFingerprint"->inputFingerprint,
      "InputCompanions"->coefficientInputCompanions[Sort[ExpandFileName/@data["Sources"]]]|>]]
  ],
  $finiteFieldFailure
];
