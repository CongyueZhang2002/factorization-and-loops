#!/usr/bin/env wolframscript

(* Reusable KernelPool mission: all family state is lexical and no Exit/Quit is
   called, so a short family cannot close or contaminate its pool subkernel. *)
Module[
  {repositoryRoot, arguments, epsilonFormFile, differentialSystemFile,
   valuationsFile, outputFile, cardFile, loadAssociation, writeAtomic,
   acceptedTransportQ, existing, epsilonForm, differentialSystem, valuations,
   card, hardFunctionOrders, safetyOrders, masterValuation, path, demand,
   wordRepresentation, materializedWordLimit, coordinateBackend,
   coordinateCacheDirectory, reconstructionThreads, validationPrimeCount,
   validationPointsPerPrime,
   start, result, alternateRecord, alternatePath, alternateResult,
   missionTag},

  missionTag = Unique["ObservableTransportMissionExit$"];
  Catch[
  $HistoryLength = 0;
  repositoryRoot = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
  If[DownValues[FeynFacet`BuildObservableTransportDemand] === {},
    Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]]
  ];

  arguments = Rest[$ScriptCommandLine];
  If[! MemberQ[{4, 5}, Length[arguments]],
    Print[
      "Usage: family_observable_transport_pool_mission.wls " <>
      "<epsilon-form.wl> <differential-system.wl> <valuations.wl> " <>
      "<output.wl> [transport-card.wl]"
    ];
    Throw[$Failed, missionTag]
  ];
  {epsilonFormFile, differentialSystemFile, valuationsFile, outputFile} =
    Take[arguments, 4];
  cardFile = If[Length[arguments] === 5, arguments[[5]], None];

  loadAssociation[file_, description_] := Module[{value},
    If[! FileExistsQ[file],
      Print[description, " does not exist: ", file];
      Return[$Failed]
    ];
    value = Quiet[Check[Get[file], $Failed]];
    If[! AssociationQ[value],
      Print[description, " is not an Association: ", file];
      Return[$Failed]
    ];
    value
  ];

  writeAtomic[value_, file_] := Module[{directory, temporary},
    directory = DirectoryName[file];
    If[! DirectoryQ[directory],
      CreateDirectory[directory, CreateIntermediateDirectories -> True]
    ];
    temporary = file <> ".tmp-" <> ToString[$ProcessID];
    Put[value, temporary];
    RenameFile[temporary, file, OverwriteTarget -> True]
  ];

  acceptedTransportQ[value_] :=
    TrueQ[FeynFacet`AcceptedObservableTransportQ[value]];

  If[FileExistsQ[outputFile],
    existing = Quiet[Check[Get[outputFile], $Failed]];
    If[acceptedTransportQ[existing],
      Print[Lookup[existing, "Family", "family"],
        " exact observable transport already exists"];
      Throw[Null, missionTag]
    ]
  ];

  epsilonForm = loadAssociation[epsilonFormFile, "Epsilon-form record"];
  If[epsilonForm === $Failed, Throw[$Failed, missionTag]];
  differentialSystem =
    loadAssociation[differentialSystemFile, "Differential system"];
  If[differentialSystem === $Failed, Throw[$Failed, missionTag]];
  valuations = Quiet[Check[Get[valuationsFile], $Failed]];
  If[! ListQ[valuations],
    Print["Valuation record is not a List: ", valuationsFile];
    Throw[$Failed, missionTag]
  ];

  card = If[cardFile === None, <||>,
    loadAssociation[cardFile, "Observable-transport card"]];
  If[card === $Failed, Throw[$Failed, missionTag]];
  hardFunctionOrders = Lookup[card, "HardFunctionOrders", {0}];
  safetyOrders = Lookup[card, "SafetyOrders", 1];
  masterValuation = Lookup[card, "MasterValuation", 0];
  path = Lookup[card, "Path", Automatic];
  wordRepresentation = Lookup[card, "WordRepresentation", Automatic];
  materializedWordLimit = Lookup[card, "MaterializedWordLimit", 4096];
  coordinateBackend = Lookup[card, "CoordinateBackend", Automatic];
  coordinateCacheDirectory = Lookup[card, "CoordinateCacheDirectory",
    outputFile <> ".coordinates"];
  reconstructionThreads = Lookup[card, "ReconstructionThreads", 1];
  validationPrimeCount = Lookup[card, "ValidationPrimeCount", 2];
  validationPointsPerPrime = Lookup[card,
    "ValidationPointsPerPrime", 1];

  demand = FeynFacet`BuildObservableTransportDemand[
    epsilonForm,
    differentialSystem,
    valuations,
    "HardFunctionOrders" -> hardFunctionOrders,
    "SafetyOrders" -> safetyOrders,
    "MasterValuation" -> masterValuation,
    "Path" -> path
  ];
  If[Lookup[demand, "Status", None] =!= "ExactObservableDemand",
    Print["Observable-demand construction failed: ", InputForm[demand]];
    Throw[$Failed, missionTag]
  ];

  start = AbsoluteTime[];
  result = FeynFacet`BuildObservableTransport[
    epsilonForm, demand,
    "WordRepresentation" -> wordRepresentation,
    "MaterializedWordLimit" -> materializedWordLimit,
    "CoordinateBackend" -> coordinateBackend,
    "CoordinateCacheDirectory" -> coordinateCacheDirectory,
    "ReconstructionThreads" -> reconstructionThreads,
    "ValidationPrimeCount" -> validationPrimeCount,
    "ValidationPointsPerPrime" -> validationPointsPerPrime,
    "Verbose" -> TrueQ[Lookup[card, "Verbose", False]]
  ];
  If[Lookup[result, "Status", None] === "BoundarySubspaceNotInvariant",
    alternateRecord = Join[epsilonForm,
      <|"Variables" -> Reverse[epsilonForm["Variables"]]|>];
    alternatePath = FeynFacet`FindObservableTransportPath[alternateRecord];
    If[AssociationQ[alternatePath] &&
        Lookup[alternatePath, "Status", None] === "ExactPathData",
      Print["Primary path boundary subspace is not invariant; retrying " <>
        "once with the variable order reversed"];
      demand = Join[demand, <|"Path" -> alternatePath|>];
      alternateResult = FeynFacet`BuildObservableTransport[
        epsilonForm, demand,
        "WordRepresentation" -> wordRepresentation,
        "MaterializedWordLimit" -> materializedWordLimit,
        "CoordinateBackend" -> coordinateBackend,
        "CoordinateCacheDirectory" -> coordinateCacheDirectory,
        "ReconstructionThreads" -> reconstructionThreads,
        "ValidationPrimeCount" -> validationPrimeCount,
        "ValidationPointsPerPrime" -> validationPointsPerPrime,
        "Verbose" -> TrueQ[Lookup[card, "Verbose", False]]
      ];
      result = Join[alternateResult,
        <|"PrimaryPathStatus" -> "BoundarySubspaceNotInvariant"|>]
    ]
  ];
  If[! acceptedTransportQ[result],
    Print["Observable transport failed: ",
      InputForm[KeyTake[result, {"Status", "Certificates"}]]];
    Throw[$Failed, missionTag]
  ];

  result = Join[result, <|
    "Demand" -> demand,
    "SourceFiles" -> <|
      "EpsilonForm" -> ExpandFileName[epsilonFormFile],
      "DifferentialSystem" -> ExpandFileName[differentialSystemFile],
      "Valuations" -> ExpandFileName[valuationsFile],
      "Card" -> If[cardFile === None, None, ExpandFileName[cardFile]]
    |>,
    "TotalSeconds" -> AbsoluteTime[] - start
  |>];
  writeAtomic[result, outputFile];

  Print[result["Family"], " observable transport (", result["Status"],
    "): ",
    Length[result["PhysicalDemandPairs"]], " demanded (order,row) pairs, ",
    result["BoundaryCoordinates"], " boundary coordinates, maximum weight ",
    result["MaximumWeight"], ", ", Round[result["TotalSeconds"], 0.01],
    " s"];
  Null,
  missionTag
  ]
]
