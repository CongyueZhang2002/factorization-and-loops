#!/usr/bin/env wolframscript

(* Reusable KernelPool mission: all family state is lexical and no Exit/Quit is
   called, so a short family cannot close or contaminate its pool subkernel. *)
Module[
  {repositoryRoot, arguments, epsilonFormFile, differentialSystemFile,
   valuationsFile, outputFile, cardFile, loadAssociation, writeAtomic,
   repositoryRelativePath, validatedCoefficientOperatorQ, existing,
   epsilonForm, differentialSystem,
   valuations, typedRequirementsQ,
   requirementsReference,
   card, hardFunctionOrders, safetyOrders, masterValuation, path, demand,
   coefficientRepresentation, coordinateBackend,
   coordinateCacheDirectory, reconstructionThreads, validationPrimeCount,
   validationPointsPerPrime,
   start, loadStart, epsilonLoadSeconds, differentialLoadSeconds,
   valuationLoadSeconds, result, alternateRecord, alternatePath, alternateResult,
   missionTag},

  missionTag = Unique["CoefficientOperatorMissionExit$"];
  Catch[
  $HistoryLength = 0;
  repositoryRoot = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
  If[DownValues[
      FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs] === {},
    Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]]
  ];

  arguments = Rest[$ScriptCommandLine];
  If[! MemberQ[{4, 5}, Length[arguments]],
    Print[
      "Usage: family_observable_transport_pool_mission.wls " <>
      "<epsilon-form.wl> <differential-system.wl> " <>
      "<requirements-or-legacy-valuations.wl> " <>
      "<output.wl> [coefficient-operator-options.wl]"
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

  repositoryRelativePath[file_String] := Module[{rootParts, fileParts},
    rootParts = FileNameSplit[ExpandFileName[repositoryRoot]];
    fileParts = FileNameSplit[ExpandFileName[file]];
    If[Length[fileParts] > Length[rootParts] &&
        Take[fileParts, Length[rootParts]] === rootParts,
      FileNameJoin[Drop[fileParts, Length[rootParts]]],
      $Failed]
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

  validatedCoefficientOperatorQ[value_] :=
    TrueQ[FeynFacet`IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      value]];

  loadStart = AbsoluteTime[];
  epsilonForm = loadAssociation[epsilonFormFile, "Epsilon-form record"];
  epsilonLoadSeconds = AbsoluteTime[] - loadStart;
  If[epsilonForm === $Failed, Throw[$Failed, missionTag]];
  loadStart = AbsoluteTime[];
  differentialSystem =
    loadAssociation[differentialSystemFile, "Differential system"];
  differentialLoadSeconds = AbsoluteTime[] - loadStart;
  If[differentialSystem === $Failed, Throw[$Failed, missionTag]];
  loadStart = AbsoluteTime[];
  valuations = Quiet[Check[Get[valuationsFile], $Failed]];
  valuationLoadSeconds = AbsoluteTime[] - loadStart;
  typedRequirementsQ = TrueQ[
    FeynFacet`MasterIntegralEpsilonOrderRequirementsQ[valuations]];
  If[! typedRequirementsQ && ! ListQ[valuations],
    Print["Requested-output specification is neither a validated " <>
      "MasterIntegralEpsilonOrderRequirements record nor a legacy " <>
      "valuation List: ", valuationsFile];
    Throw[$Failed, missionTag]
  ];
  requirementsReference = If[typedRequirementsQ,
    With[{relativePath = repositoryRelativePath[valuationsFile]},
      If[relativePath === $Failed,
        Print["The requirements artifact must be inside the repository so " <>
          "its V2 reference has a RelativePath: ", valuationsFile];
        Throw[$Failed, missionTag]
      ];
      <|
        "RelativePath" -> relativePath,
        "DataType" -> "MasterIntegralEpsilonOrderRequirements",
        "SchemaVersion" -> 2,
        "MathematicalInputReferences" ->
          valuations["MathematicalInputReferences"]|>],
    Automatic];
  If[FileExistsQ[outputFile],
    existing = Quiet[Check[Get[outputFile], $Failed]];
    If[validatedCoefficientOperatorQ[existing] &&
        (! typedRequirementsQ ||
          (KeyExistsQ[existing, "FamilyDifferentialSystemReference"] &&
            KeyExistsQ[existing,
              "MasterIntegralEpsilonOrderRequirementsReference"])),
      Print[Lookup[existing, "Family", "family"],
        " validated requested-output coefficient operator already exists"];
      Throw[Null, missionTag]
    ]
  ];

  card = If[cardFile === None, <||>,
    loadAssociation[cardFile, "Coefficient-operator options"]];
  If[card === $Failed, Throw[$Failed, missionTag]];
  If[TrueQ[Lookup[card, "Verbose", False]], Print[
    "Coefficient-operator input loads: epsilon form ",
    Round[epsilonLoadSeconds, 0.1], " s; differential system ",
    Round[differentialLoadSeconds, 0.1], " s; valuations ",
    Round[valuationLoadSeconds, 0.1], " s"]];
  hardFunctionOrders = Lookup[card,
    "RequestedHardFunctionEpsilonOrders", {0}];
  safetyOrders = Lookup[card, "AdditionalRetainedEpsilonOrders", 1];
  masterValuation = Lookup[card,
    "MinimumRetainedMasterIntegralEpsilonOrder", 0];
  path = Lookup[card,
    "RegularBasePointAndFirstPathParameterScale", Automatic];
  coefficientRepresentation = Lookup[card,
    "IteratedIntegralCoefficientRepresentation", Automatic];
  coordinateBackend = Lookup[card, "CoordinateBackend", Automatic];
  coordinateCacheDirectory = Lookup[card, "CoordinateCacheDirectory",
    outputFile <> ".coordinates"];
  reconstructionThreads = Lookup[card, "ReconstructionThreads",
    Quiet[Check[ToExpression[
      Replace[Environment["FACET_TRANSPORT_RECONSTRUCTION_THREADS"],
        Except[_String] | "" -> "1"]], 1]]];
  validationPrimeCount = Lookup[card, "ValidationPrimeCount", 2];
  validationPointsPerPrime = Lookup[card,
    "ValidationPointsPerPrime", 1];

  demand = If[typedRequirementsQ, valuations,
    FeynFacet`Private`mapMasterIntegralCoefficientValuationsToRequestedRows[
      epsilonForm,
      differentialSystem,
      valuations,
      "RequestedHardFunctionEpsilonOrders" -> hardFunctionOrders,
      "AdditionalRetainedEpsilonOrders" -> safetyOrders,
      "MinimumRetainedMasterIntegralEpsilonOrder" -> masterValuation,
      "RegularBasePointAndFirstPathParameterScale" -> path]];
  If[! typedRequirementsQ && Lookup[demand, "Status", None] =!=
        "MasterIntegralCoefficientValuationsMappedToRequestedRows",
    Print["Requested-row mapping failed: ", InputForm[demand]];
    Throw[$Failed, missionTag]
  ];

  start = AbsoluteTime[];
  result =
    FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    epsilonForm, demand,
    "RegularBasePointAndFirstPathParameterScale" -> path,
    "MasterIntegralEpsilonOrderRequirementsReference" ->
      requirementsReference,
    "IteratedIntegralCoefficientRepresentation" ->
      coefficientRepresentation,
    "CoordinateBackend" -> coordinateBackend,
    "CoordinateCacheDirectory" -> coordinateCacheDirectory,
    "ReconstructionThreads" -> reconstructionThreads,
    "ValidationPrimeCount" -> validationPrimeCount,
    "ValidationPointsPerPrime" -> validationPointsPerPrime,
    "Verbose" -> TrueQ[Lookup[card, "Verbose", False]]
  ];
  If[Lookup[result, "Status", None] === "BoundarySubspaceNotInvariant",
    alternateRecord = Join[epsilonForm, <|"CoefficientVariables" ->
      Reverse[epsilonForm["CoefficientVariables"]]|>];
    alternatePath =
      FeynFacet`ChooseRegularBasePointAndFirstPathParameterScale[
        alternateRecord];
    If[AssociationQ[alternatePath] &&
        Lookup[alternatePath, "Status", None] ===
          "RegularBasePointAndFirstPathParameterScaleSelected",
      Print["Primary path boundary subspace is not invariant; retrying " <>
        "once with the variable order reversed"];
      path = alternatePath;
      alternateResult =
        FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
        epsilonForm, demand,
        "RegularBasePointAndFirstPathParameterScale" -> path,
        "MasterIntegralEpsilonOrderRequirementsReference" ->
          requirementsReference,
        "IteratedIntegralCoefficientRepresentation" ->
          coefficientRepresentation,
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
  If[! validatedCoefficientOperatorQ[result],
    Print["Requested-output coefficient operator failed: ",
      InputForm[KeyTake[result, {"Status", "Certificates"}]]];
    Throw[$Failed, missionTag]
  ];

  result = Join[result,
    If[typedRequirementsQ, <||>, <|"Demand" -> demand|>], <|
    "SourceFiles" -> <|
      "EpsilonForm" -> ExpandFileName[epsilonFormFile],
      "DifferentialSystem" -> ExpandFileName[differentialSystemFile],
      "Valuations" -> ExpandFileName[valuationsFile],
      "Card" -> If[cardFile === None, None, ExpandFileName[cardFile]]
    |>,
    "TotalSeconds" -> AbsoluteTime[] - start
  |>];
  writeAtomic[result, outputFile];

  Print[result["Family"], " requested-output coefficient operator (",
    result["Status"], "): ",
    Length[result["RequestedMasterIntegralEpsilonOrderAndRowPairs"]],
    " requested (epsilon order,row) pairs, ",
    result["BoundaryCoordinates"], " boundary coordinates, maximum weight ",
    result["MaximumIteratedIntegralWeight"], ", ",
    Round[result["TotalSeconds"], 0.01],
    " s"];
  Null,
  missionTag
  ]
]
