#!/usr/bin/env wolframscript

$HistoryLength = 0;

repositoryRoot = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{4, 5}, Length[arguments]],
  Print[
    "Usage: family_observable_transport.wls " <>
    "<epsilon-form.wl> <differential-system.wl> <valuations.wl> " <>
    "<output.wl> [transport-card.wl]"
  ];
  Exit[64]
];

{epsilonFormFile, differentialSystemFile, valuationsFile, outputFile} =
  Take[arguments, 4];
cardFile = If[Length[arguments] === 5, arguments[[5]], None];

(* Run log (round 7, 2026-09-02): <output>.log next to the output file,
   opened at start; every stage milestone of the transport's Verbose path
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
    Exit[0]
  ]
];

epsilonForm = loadAssociation[epsilonFormFile, "Epsilon-form record"];
runLog["epsilon-form record loaded: " <> ToString[Lookup[epsilonForm, "Family", None]] <>
  ", status " <> ToString[Lookup[epsilonForm, "Status", None]]];
differentialSystem =
  loadAssociation[differentialSystemFile, "Differential system"];
valuations = Quiet[Check[Get[valuationsFile], $Failed]];
If[! ListQ[valuations],
  Print["Valuation record is not a List: ", valuationsFile];
  Exit[65]
];

card = If[cardFile === None, <||>,
  loadAssociation[cardFile, "Observable-transport card"]];
hardFunctionOrders = Lookup[card, "HardFunctionOrders", {0}];
safetyOrders = Lookup[card, "SafetyOrders", 1];
masterValuation = Lookup[card, "MasterValuation", 0];
path = Lookup[card, "Path", Automatic];
wordRepresentation = Lookup[card, "WordRepresentation", Automatic];
materializedWordLimit = Lookup[card, "MaterializedWordLimit", 4096];
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
  runLog["demand construction failed: " <> ToString[Lookup[demand, "Status", None]]];
  Print["Observable-demand construction failed: ", InputForm[demand]];
  Exit[1]
];
runLog["demand built: " <> ToString[Length[Lookup[demand, "PhysicalDemandPairs", {}]]] <>
  " demanded (order,row) pairs; transport starting"];

start = AbsoluteTime[];
result = FeynFacet`BuildObservableTransport[epsilonForm, demand,
  "WordRepresentation" -> wordRepresentation,
  "MaterializedWordLimit" -> materializedWordLimit,
  "CoordinateBackend" -> coordinateBackend,
  "CoordinateCacheDirectory" -> coordinateCacheDirectory,
  "ReconstructionThreads" -> reconstructionThreads,
  "ValidationPrimeCount" -> validationPrimeCount,
  "ValidationPointsPerPrime" -> validationPointsPerPrime,
  "DiagnosticDirectory" -> diagnosticDirectory,
  "Verbose" -> TrueQ[Lookup[card, "Verbose", False]]];
If[Lookup[result, "Status", None] === "BoundarySubspaceNotInvariant",
  alternateRecord = Join[epsilonForm,
    <|"Variables" -> Reverse[epsilonForm["Variables"]]|>];
  alternatePath = FeynFacet`FindObservableTransportPath[alternateRecord];
  If[AssociationQ[alternatePath] &&
      Lookup[alternatePath, "Status", None] === "ExactPathData",
    Print["Primary path boundary subspace is not invariant; retrying " <>
      "once with the variable order reversed"];
    demand = Join[demand, <|"Path" -> alternatePath|>];
    result = Join[FeynFacet`BuildObservableTransport[epsilonForm, demand,
      "WordRepresentation" -> wordRepresentation,
      "MaterializedWordLimit" -> materializedWordLimit,
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
runLog["transport returned: " <> ToString[Lookup[result, "Status", None]] <>
  " after " <> ToString[Round[AbsoluteTime[] - start, 0.1]] <> " s; accepted " <>
  ToString[acceptedTransportQ[result]]];
If[! acceptedTransportQ[result],
  runLog["transport failed: " <> ToString[Lookup[result, "Status", None]]];
  Print["Observable transport failed: ",
    InputForm[KeyTake[result, {"Status", "Reason", "Certificates",
      "Diagnostics", "RankSampleCount", "DiagnosticDirectory"}]]];
  Exit[1]
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
runLog["result written: " <> outputFile <> " (" <> ToString[FileByteCount[outputFile]] <> " bytes)"];

Print[result["Family"], " observable transport (", result["Status"], "): ",
  Length[result["PhysicalDemandPairs"]], " demanded (order,row) pairs, ",
  result["BoundaryCoordinates"], " boundary coordinates, maximum weight ",
  result["MaximumWeight"], ", ",
  Round[result["TotalSeconds"], 0.01], " s"];
