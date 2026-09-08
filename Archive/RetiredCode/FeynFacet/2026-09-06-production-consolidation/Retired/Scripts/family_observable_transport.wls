#!/usr/bin/env wolframscript

$HistoryLength = 0;

repositoryRoot = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{4, 5}, Length[arguments]],
  Print[
    "Usage: family_observable_transport.wls " <>
    "<epsilon-form.wl> <differential-system.wl> " <>
    "<requirements-or-legacy-valuations.wl> " <>
    "<output.wl> [coefficient-operator-options.wl]"
  ];
  Exit[64]
];

{epsilonFormFile, differentialSystemFile, valuationsFile, outputFile} =
  Take[arguments, 4];
cardFile = If[Length[arguments] === 5, arguments[[5]], None];

(* Run log (round 7, 2026-09-02): <output>.log next to the output file,
   opened at start; every stage milestone of the coefficient operator's
   Verbose path
   (FeynFacet`Private`$observableTransportMilestoneHook) and every driver
   milestone is appended AS IT HAPPENS with a wall-clock stamp and the
   seconds since start -- one OpenAppend/WriteString/Close per line, so
   the line is on disk when the next stage begins.  The milestones'
   content is unchanged (they are still printed to stdout as before). *)
runLogFile = outputFile <> ".log";
runStart = AbsoluteTime[];
runLog[line_String] := Module[{stream, directory = DirectoryName[runLogFile]},
  If[! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  stream = Quiet[Check[OpenAppend[runLogFile], $Failed]];
  If[stream =!= $Failed,
    WriteString[stream, DateString[{"Year", "-", "Month", "-", "Day", " ",
        "Hour", ":", "Minute", ":", "Second"}], " +",
      ToString[Round[AbsoluteTime[] - runStart, 0.1]], " s | ", line, "\n"];
    Close[stream]]];
runLog["driver start: family_observable_transport.wls; output " <> outputFile];
FeynFacet`Private`$observableTransportMilestoneHook = runLog;

loadAssociation[file_, description_] := Module[{value},
  If[! FileExistsQ[file],
    Print[description, " does not exist: ", file];
    Exit[66]
  ];
  value = Quiet[Check[Get[file], $Failed]];
  If[! AssociationQ[value],
    Print[description, " is not an Association: ", file];
    Exit[65]
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

epsilonForm = loadAssociation[epsilonFormFile, "Epsilon-form record"];
runLog["epsilon-form record loaded: " <> ToString[Lookup[epsilonForm, "Family", None]] <>
  ", status " <> ToString[Lookup[epsilonForm, "Status", None]]];
differentialSystem =
  loadAssociation[differentialSystemFile, "Differential system"];
valuations = Quiet[Check[Get[valuationsFile], $Failed]];
typedRequirementsQ = TrueQ[
  FeynFacet`MasterIntegralEpsilonOrderRequirementsQ[valuations]];
If[! typedRequirementsQ && ! ListQ[valuations],
  Print["Requested-output specification is neither a validated " <>
    "MasterIntegralEpsilonOrderRequirements record nor a legacy " <>
    "valuation List: ", valuationsFile];
  Exit[65]
];
requirementsReference = If[typedRequirementsQ,
  With[{relativePath = repositoryRelativePath[valuationsFile]},
    If[relativePath === $Failed,
      Print["The requirements artifact must be inside the repository so " <>
        "its V2 reference has a RelativePath: ", valuationsFile];
      Exit[65]
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
    Exit[0]
  ]
];

card = If[cardFile === None, <||>,
  loadAssociation[cardFile, "Coefficient-operator options"]];
hardFunctionOrders = Lookup[card,
  "RequestedHardFunctionEpsilonOrders", {0}];
safetyOrders = Lookup[card, "AdditionalRetainedEpsilonOrders", 1];
masterValuation = Lookup[card,
  "MinimumRetainedMasterIntegralEpsilonOrder", 0];
path = Lookup[card,
  "RegularBasePointAndFirstPathParameterScale", Automatic];
wordRepresentation = Lookup[card,
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
diagnosticDirectory = Lookup[card, "DiagnosticDirectory", None];

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
  runLog["demand construction failed: " <> ToString[Lookup[demand, "Status", None]]];
  Print["Requested-row mapping failed: ", InputForm[demand]];
  Exit[1]
  ];
runLog[If[typedRequirementsQ,
  "validated master-integral epsilon-order requirements loaded; " <>
    "coefficient-operator construction starting",
  "requested rows mapped: " <> ToString[Length[Lookup[demand,
      "RequestedMasterIntegralEpsilonOrderAndRowPairs", {}]]] <>
    " requested (epsilon order,row) pairs; " <>
    "coefficient-operator construction starting"]];

start = AbsoluteTime[];
result = FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  epsilonForm, demand,
  "RegularBasePointAndFirstPathParameterScale" -> path,
  "MasterIntegralEpsilonOrderRequirementsReference" ->
    requirementsReference,
  "IteratedIntegralCoefficientRepresentation" -> wordRepresentation,
  "CoordinateBackend" -> coordinateBackend,
  "CoordinateCacheDirectory" -> coordinateCacheDirectory,
  "ReconstructionThreads" -> reconstructionThreads,
  "ValidationPrimeCount" -> validationPrimeCount,
  "ValidationPointsPerPrime" -> validationPointsPerPrime,
  "DiagnosticDirectory" -> diagnosticDirectory,
  "Verbose" -> TrueQ[Lookup[card, "Verbose", False]]];
If[Lookup[result, "Status", None] === "BoundarySubspaceNotInvariant",
  alternateRecord = Join[epsilonForm, <|"CoefficientVariables" ->
    Reverse[epsilonForm["CoefficientVariables"]]|>];
  alternatePath =
    FeynFacet`ChooseRegularBasePointAndFirstPathParameterScale[alternateRecord];
  If[AssociationQ[alternatePath] &&
      Lookup[alternatePath, "Status", None] ===
        "RegularBasePointAndFirstPathParameterScaleSelected",
    Print["Primary path boundary subspace is not invariant; retrying " <>
      "once with the variable order reversed"];
    path = alternatePath;
    result = Join[
      FeynFacet`ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
      epsilonForm, demand,
      "RegularBasePointAndFirstPathParameterScale" -> path,
      "MasterIntegralEpsilonOrderRequirementsReference" ->
        requirementsReference,
      "IteratedIntegralCoefficientRepresentation" -> wordRepresentation,
      "CoordinateBackend" -> coordinateBackend,
      "CoordinateCacheDirectory" -> coordinateCacheDirectory,
      "ReconstructionThreads" -> reconstructionThreads,
      "ValidationPrimeCount" -> validationPrimeCount,
      "ValidationPointsPerPrime" -> validationPointsPerPrime,
      "DiagnosticDirectory" -> diagnosticDirectory,
      "Verbose" -> TrueQ[Lookup[card, "Verbose", False]]],
      <|"PrimaryPathStatus" -> "BoundarySubspaceNotInvariant"|>]
  ]
];
runLog["coefficient operator returned: " <>
  ToString[Lookup[result, "Status", None]] <>
  " after " <> ToString[Round[AbsoluteTime[] - start, 0.1]] <> " s; accepted " <>
  ToString[validatedCoefficientOperatorQ[result]]];
If[! validatedCoefficientOperatorQ[result],
  runLog["coefficient-operator construction failed: " <>
    ToString[Lookup[result, "Status", None]]];
  Print["Requested-output coefficient operator failed: ",
    InputForm[KeyTake[result, {"Status", "Reason", "Certificates",
      "Diagnostics", "RankSampleCount", "DiagnosticDirectory"}]]];
  Exit[1]
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
runLog["result written: " <> outputFile <> " (" <> ToString[FileByteCount[outputFile]] <> " bytes)"];

Print[result["Family"], " requested-output coefficient operator (",
  result["Status"], "): ",
  Length[result["RequestedMasterIntegralEpsilonOrderAndRowPairs"]],
  " requested (epsilon order,row) pairs, ",
  result["BoundaryCoordinates"], " boundary coordinates, maximum weight ",
  result["MaximumIteratedIntegralWeight"], ", ",
  Round[result["TotalSeconds"], 0.01], " s"];
