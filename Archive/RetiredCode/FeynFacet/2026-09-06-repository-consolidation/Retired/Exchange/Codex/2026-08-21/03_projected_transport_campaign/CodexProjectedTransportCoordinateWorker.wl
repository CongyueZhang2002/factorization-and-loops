(* Worker used only by the external two-core campaign.  It assumes that
   LoadFACET.wl and CodexProjectedTransportStandard.wl were loaded in the
   current local subkernel.  It returns a compact status while persisting the
   exact word-map record directly, so the parent kernel never receives the
   potentially large transport object. *)

BeginPackage["CodexProjectedTransportWorker`"];

CodexRunProjectedTransportWorker::usage =
  "CodexRunProjectedTransportWorker[root,bundle,family,outdir,verbose] " <>
  "runs one exact projected transport without launching more kernels.";

Begin["`Private`"];

ClearAll[CodexRunProjectedTransportWorker];

CodexRunProjectedTransportWorker[root_String, bundle_String,
    family_String, outputDirectory_String, verbose_: False,
    mode_: "Baseline"] := Module[
  {certifiedDirectory, differentialDirectory, valuationFile, cardFile,
   recordFile, systemFile, standardFile, candidateSourceFile, outputFile,
   summaryFile, progressFile,
   existing,
   record, system, valuations, card, result, summary, started, finished,
   fastInstalled, fastTelemetry},

  certifiedDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "FamilyEpsFormsCertified"}];
  differentialDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations"}];
  valuationFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "MasterCoefficientValuations.wl"}];
  cardFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Cards",
    "UU_ObservableTransport.wl"}];
  recordFile = FileNameJoin[{certifiedDirectory,
    "family_epsform_" <> family <> ".wl"}];
  systemFile = FileNameJoin[{differentialDirectory,
    "nnlo_de_" <> family <> ".wl"}];
  standardFile = FileNameJoin[{bundle, "CodexProjectedTransportStandard.wl"}];
  candidateSourceFile = FileNameJoin[{bundle,
    If[(StringQ[Environment["CODEX_RATRACER_CACHE_DIRECTORY"]] &&
          Environment["CODEX_RATRACER_CACHE_DIRECTORY"] =!= "") ||
        (StringQ[Environment["CODEX_RATRACER_CAPTURE_DIRECTORY"]] &&
          Environment["CODEX_RATRACER_CAPTURE_DIRECTORY"] =!= ""),
      "CodexObservableTransportRatracerCandidate.wl",
      "CodexObservableTransportCoordinateCandidate.wl"]}];
  outputFile = FileNameJoin[{outputDirectory,
    "projected_transport_" <> family <> ".wl"}];
  summaryFile = FileNameJoin[{outputDirectory,
    "projected_transport_" <> family <> "_summary.wl"}];
  progressFile = FileNameJoin[{outputDirectory,
    "projected_transport_" <> family <> "_progress.wl"}];

  If[! And @@ (FileExistsQ /@ {recordFile, systemFile, valuationFile,
      cardFile, standardFile}),
    Return[<|"Family" -> family, "Status" -> "InputMissing",
      "Exact" -> False, "KernelID" -> $KernelID|>]
  ];

  existing = If[FileExistsQ[outputFile],
    FeynFacet`FamilyArtifactRead[outputFile], $Failed];
  If[CodexProjectedTransportStandard`CodexProjectedTransportExactQ[existing],
    Return[Join[
      CodexProjectedTransportStandard`CodexProjectedTransportSummary[existing],
      <|"WorkerStatus" -> "AlreadyExact", "KernelID" -> $KernelID,
        "OutputFile" -> outputFile|>]
    ]
  ];

  record = FeynFacet`FamilyArtifactRead[recordFile];
  system = FeynFacet`FamilyArtifactRead[systemFile];
  valuations = FeynFacet`FamilyArtifactRead[valuationFile];
  card = FeynFacet`FamilyArtifactRead[cardFile];
  If[! AssociationQ[record] || ! AssociationQ[system] ||
      ! ListQ[valuations] || ! AssociationQ[card],
    Return[<|"Family" -> family, "Status" -> "InputMalformed",
      "Exact" -> False, "KernelID" -> $KernelID|>]
  ];

  fastInstalled = If[MemberQ[
      {"NoTerminalProbe", "InvariantRefinedNoTerminalProbe"}, mode],
    TrueQ[CodexProjectedTransportFastWordKernel`CodexInstallProjectedTransportFastWordKernel[]],
    MemberQ[{"Baseline", "CompactInvariantRefined"}, mode]];
  If[! fastInstalled,
    Return[<|"Family" -> family, "Status" -> "OptimizationInstallFailed",
      "Exact" -> False, "KernelID" -> $KernelID, "Mode" -> mode|>]
  ];

  started = AbsoluteTime[];
  FeynFacet`FamilyArtifactWrite[<|
    "Family" -> family,
    "Status" -> "Running",
    "Mode" -> mode,
    "Dimension" -> Lookup[record, "Dim", Missing[]],
    "KernelID" -> $KernelID,
    "ProcessID" -> $ProcessID,
    "Started" -> started
  |>, progressFile];
  result = Quiet[Check[
    CodexProjectedTransportStandard`CodexProjectedTransportSolve[
      record,
      system,
      valuations,
      "HardFunctionOrders" -> Lookup[card, "HardFunctionOrders", {0}],
      "SafetyOrders" -> Lookup[card, "SafetyOrders", 1],
      "MasterValuation" -> Lookup[card, "MasterValuation", 0],
      "Path" -> Lookup[card, "Path", Automatic],
      "WordRepresentation" -> If[mode === "CompactInvariantRefined",
        "CompactAutomaton", "MaterializedWords"],
      "Verbose" -> TrueQ[verbose]
    ],
    <|"Status" -> "UnhandledWorkerMessage", "Exact" -> False|>
  ]];
  finished = AbsoluteTime[];
  fastTelemetry = If[MemberQ[
      {"NoTerminalProbe", "InvariantRefinedNoTerminalProbe"}, mode],
    CodexProjectedTransportFastWordKernel`CodexProjectedTransportFastWordTelemetry[],
    None];

  result = If[AssociationQ[result], Join[result, <|
      "ExternalScope" -> "NoPackageEdits",
      "SourceFiles" -> <|
        "EpsilonForm" -> recordFile,
        "DifferentialSystem" -> systemFile,
        "Valuations" -> valuationFile,
        "Card" -> cardFile,
        "StandardWrapper" -> standardFile,
        "ObservableTransportCandidate" -> candidateSourceFile
      |>,
      "SourceSHA256" -> <|
        "EpsilonForm" -> FileHash[recordFile, "SHA256", "HexString"],
        "DifferentialSystem" -> FileHash[systemFile, "SHA256", "HexString"],
        "Valuations" -> FileHash[valuationFile, "SHA256", "HexString"],
        "Card" -> FileHash[cardFile, "SHA256", "HexString"],
        "ObservableTransportEngine" -> FileHash[
          FileNameJoin[{root, "FeynFacet", "Private", "ObservableTransport.wl"}],
          "SHA256", "HexString"],
        "ObservableTransportCandidate" -> If[
          MemberQ[{"InvariantRefinedNoTerminalProbe",
            "CompactInvariantRefined"}, mode],
          FileHash[candidateSourceFile, "SHA256", "HexString"], None],
        "StandardWrapper" -> FileHash[standardFile, "SHA256", "HexString"]
      |>,
      "Runtime" -> <|
        "KernelVersion" -> $Version,
        "SystemID" -> $SystemID,
        "ProcessID" -> $ProcessID,
        "KernelID" -> $KernelID,
        "NestedSubkernelsLaunched" -> 0,
        "WorkerAbsoluteStart" -> started,
        "WorkerAbsoluteFinish" -> finished
      |>,
      "Optimization" -> <|
        "Mode" -> mode,
        "FastWordTelemetry" -> fastTelemetry
      |>
    |>], result];

  If[! CodexProjectedTransportStandard`CodexProjectedTransportExactQ[result],
    FeynFacet`FamilyArtifactWrite[<|
      "Family" -> family,
      "Status" -> "Failed",
      "Mode" -> mode,
      "KernelID" -> $KernelID,
      "ProcessID" -> $ProcessID,
      "Started" -> started,
      "Finished" -> finished,
      "FailureStatus" -> If[AssociationQ[result],
        Lookup[result, "Status", Missing[]], "NonAssociationResult"],
      "EngineStatus" -> If[AssociationQ[result] &&
          AssociationQ[Lookup[result, "EngineResult", None]],
        Lookup[result["EngineResult"], "Status", Missing[]], None]
    |>, progressFile];
    Return[<|
      "Family" -> family,
      "Status" -> If[AssociationQ[result], Lookup[result, "Status", Missing[]],
        "NonAssociationResult"],
      "EngineStatus" -> If[AssociationQ[result] &&
          AssociationQ[Lookup[result, "EngineResult", None]],
        Lookup[result["EngineResult"], "Status", Missing[]], None],
      "FailureDetail" -> If[AssociationQ[result],
        KeyTake[result, {"Status", "Certificates", "EngineResult"}], result],
      "Exact" -> False,
      "KernelID" -> $KernelID,
      "WorkerSeconds" -> N[finished - started]
    |>]
  ];

  FeynFacet`FamilyArtifactWrite[result, outputFile];
  summary = CodexProjectedTransportStandard`CodexProjectedTransportSummary[result];
  summary = Join[summary, <|
    "WorkerStatus" -> "ComputedExact",
    "Mode" -> mode,
    "KernelID" -> $KernelID,
    "OutputFile" -> outputFile,
    "OutputBytes" -> FileByteCount[outputFile]
  |>];
  FeynFacet`FamilyArtifactWrite[summary, summaryFile];
  FeynFacet`FamilyArtifactWrite[<|
    "Family" -> family,
    "Status" -> "CompleteExact",
    "Mode" -> mode,
    "KernelID" -> $KernelID,
    "ProcessID" -> $ProcessID,
    "Started" -> started,
    "Finished" -> finished,
    "SummaryFile" -> summaryFile,
    "OutputFile" -> outputFile
  |>, progressFile];
  summary
];

End[];
EndPackage[];
