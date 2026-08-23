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

exactTransportQ[value_] := AssociationQ[value] &&
  Lookup[value, "Status", None] === "ExactObservableTransport" &&
  AssociationQ[Lookup[value, "Certificates", None]] &&
  And @@ (TrueQ /@ Values[value["Certificates"]]);

If[FileExistsQ[outputFile],
  existing = Quiet[Check[Get[outputFile], $Failed]];
  If[exactTransportQ[existing],
    Print[Lookup[existing, "Family", "family"],
      " exact observable transport already exists"];
    Exit[0]
  ]
];

epsilonForm = loadAssociation[epsilonFormFile, "Epsilon-form record"];
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
  Exit[1]
];

start = AbsoluteTime[];
result = FeynFacet`BuildObservableTransport[epsilonForm, demand,
  "Verbose" -> TrueQ[Lookup[card, "Verbose", False]]];
If[! exactTransportQ[result],
  Print["Observable transport failed: ",
    InputForm[KeyTake[result, {"Status", "Certificates"}]]];
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

Print[result["Family"], " exact observable transport: ",
  Length[result["PhysicalDemandPairs"]], " demanded (order,row) pairs, ",
  result["BoundaryCoordinates"], " boundary coordinates, maximum weight ",
  result["MaximumWeight"], ", ",
  Round[result["TotalSeconds"], 0.01], " s"];
