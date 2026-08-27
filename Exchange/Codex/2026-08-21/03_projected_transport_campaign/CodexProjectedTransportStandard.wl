(* Standalone standardization wrapper for demand-driven epsilon-form transport.

   This file deliberately lives outside FeynFacet.  It consumes the package's
   exact whole-family epsilon-form certificate and its projected transport
   engine, but fixes a narrow, package-ready contract:

       certified epsilon form + physical hard-function demand
         -> projected two-segment maps P.T.U.N, up to boundary constants.

   It does not construct the full fundamental matrix, evaluate periods,
   perform endpoint matching, or install anything into the package. *)

BeginPackage["CodexProjectedTransportStandard`"];

CodexProjectedTransportBuildDemand::usage =
  "CodexProjectedTransportBuildDemand[record, system, valuations, opts] " <>
  "constructs the exact (epsilon order, master row) demand.";

CodexProjectedTransportSolve::usage =
  "CodexProjectedTransportSolve[record, system, valuations, opts] returns " <>
  "the exact demand-projected two-segment epsilon-form transport up to " <>
  "unevaluated boundary constants.";

CodexProjectedTransportExactQ::usage =
  "CodexProjectedTransportExactQ[result] checks the standardized terminal " <>
  "status and all retained exact certificates.";

CodexProjectedTransportSummary::usage =
  "CodexProjectedTransportSummary[result] returns a compact campaign row.";

CodexProjectedTransportWordMap::usage =
  "CodexProjectedTransportWordMap[result,firstWord,secondWord] " <>
  "reconstructs one exact demanded word map from either the compact " <>
  "automaton or a materialized transport record.";

Begin["`Private`"];

ClearAll[
  CodexProjectedTransportBuildDemand,
  CodexProjectedTransportSolve,
  CodexProjectedTransportExactQ,
  CodexProjectedTransportSummary,
  CodexProjectedTransportWordMap
];

Options[CodexProjectedTransportBuildDemand] = {
  "HardFunctionOrders" -> {0},
  "SafetyOrders" -> 1,
  "MasterValuation" -> 0,
  "Path" -> Automatic
};

CodexProjectedTransportBuildDemand[record_Association,
    system_Association, valuations_List, OptionsPattern[]] :=
  FeynFacet`BuildObservableTransportDemand[
    record,
    system,
    valuations,
    "HardFunctionOrders" -> OptionValue["HardFunctionOrders"],
    "SafetyOrders" -> OptionValue["SafetyOrders"],
    "MasterValuation" -> OptionValue["MasterValuation"],
    "Path" -> OptionValue["Path"]
  ];

CodexProjectedTransportBuildDemand[___] :=
  <|"Status" -> "ProjectedTransportInputsNotWellFormed"|>;

Options[CodexProjectedTransportSolve] = Join[
  Options[CodexProjectedTransportBuildDemand],
  {
    "MaximumWeight" -> Automatic,
    "ClosureSteps" -> Automatic,
    "RankSamples" -> Automatic,
    "ResidueSamples" -> Automatic,
    "WordRepresentation" -> "MaterializedWords",
    "Verbose" -> False
  }
];

CodexProjectedTransportExactQ[result_] :=
  AssociationQ[result] &&
  Lookup[result, "Status", None] === "ExactProjectedTransportUpToConstants" &&
  AssociationQ[Lookup[result, "Certificates", None]] &&
  And @@ (TrueQ /@ Values[result["Certificates"]]) &&
  TrueQ[Lookup[Lookup[result, "Contract", <||>],
    "FullFundamentalMatrixBuilt", True] === False] &&
  TrueQ[Lookup[Lookup[result, "Contract", <||>],
    "BoundaryConstantsEvaluated", True] === False];

CodexProjectedTransportSolve[record_Association, system_Association,
    valuations_List, OptionsPattern[]] := Module[
  {start, memoryBefore, demandSeconds, demand, transportSeconds, result,
   certificates, contract, totalSeconds},

  start = AbsoluteTime[];
  memoryBefore = MemoryInUse[];

  If[! TrueQ[FeynFacet`ExactFamilyEpsilonFormQ[record]],
    Return[<|
      "Status" -> "FamilyEpsilonFormNotExactlyCertified",
      "Family" -> Lookup[record, "Family", Missing["NoFamily"]]
    |>]
  ];

  {demandSeconds, demand} = AbsoluteTiming[
    CodexProjectedTransportBuildDemand[
      record,
      system,
      valuations,
      "HardFunctionOrders" -> OptionValue["HardFunctionOrders"],
      "SafetyOrders" -> OptionValue["SafetyOrders"],
      "MasterValuation" -> OptionValue["MasterValuation"],
      "Path" -> OptionValue["Path"]
    ]
  ];
  If[! AssociationQ[demand] ||
      Lookup[demand, "Status", None] =!= "ExactObservableDemand",
    Return[<|
      "Status" -> "ProjectedDemandConstructionFailed",
      "Family" -> Lookup[record, "Family", Missing["NoFamily"]],
      "Demand" -> demand,
      "DemandSeconds" -> demandSeconds
    |>]
  ];

  {transportSeconds, result} = AbsoluteTiming[
    FeynFacet`BuildObservableTransport[
      record,
      demand,
      "MaximumWeight" -> OptionValue["MaximumWeight"],
      "ClosureSteps" -> OptionValue["ClosureSteps"],
      "RankSamples" -> OptionValue["RankSamples"],
      "ResidueSamples" -> OptionValue["ResidueSamples"],
      "WordRepresentation" -> OptionValue["WordRepresentation"],
      "Verbose" -> OptionValue["Verbose"]
    ]
  ];
  If[! AssociationQ[result] ||
      Lookup[result, "Status", None] =!= "ExactObservableTransport",
    Return[<|
      "Status" -> "ProjectedTransportFailed",
      "Family" -> Lookup[record, "Family", Missing["NoFamily"]],
      "Demand" -> demand,
      "EngineResult" -> result,
      "DemandSeconds" -> demandSeconds,
      "TransportSeconds" -> transportSeconds
    |>]
  ];

  certificates = Lookup[result, "Certificates", <||>];
  If[! AssociationQ[certificates] ||
      ! And @@ (TrueQ /@ Values[certificates]),
    Return[<|
      "Status" -> "ProjectedTransportNotExactlyCertified",
      "Family" -> Lookup[record, "Family", Missing["NoFamily"]],
      "Certificates" -> certificates
    |>]
  ];

  contract = <|
    "Version" -> If[OptionValue["WordRepresentation"] ===
      "CompactAutomaton", 2, 1],
    "Equation" -> "dF = epsilon Omega F; I = TTotal F",
    "TransportedObject" -> "P . TTotal . U . N",
    "Representation" -> If[OptionValue["WordRepresentation"] ===
      "CompactAutomaton",
      "Certified compact weighted automaton on an ordered two-segment path",
      "Sparse matrix-valued words on an ordered two-segment path"],
    "DemandAppliedBeforeWordGeneration" -> True,
    "BoundaryKernelAppliedBeforeWordGeneration" -> True,
    "FullFundamentalMatrixBuilt" -> False,
    "BoundaryConstantsEvaluated" -> False,
    "EndpointMatchingPerformed" -> False,
    "PhysicalPeriodsEvaluated" -> False,
    "BoundaryCoordinateHead" -> "ProjectedBoundaryConstant",
    "Meaning" ->
      "Multiplying the retained word maps by the unevaluated boundary " <>
      "coordinate vector gives exactly the demanded solution coefficients."
  |>;
  totalSeconds = N[AbsoluteTime[] - start];

  Join[
    result,
    <|
      "Status" -> "ExactProjectedTransportUpToConstants",
      "Standardization" -> "CodexExternalProjectedTransportV1",
      "Demand" -> demand,
      "Contract" -> contract,
      "DemandSeconds" -> demandSeconds,
      "TransportSeconds" -> transportSeconds,
      "TotalSeconds" -> totalSeconds,
      "MemoryInUseBeforeBytes" -> memoryBefore,
      "MemoryInUseAfterBytes" -> MemoryInUse[],
      "MaxMemoryUsedBytes" -> MaxMemoryUsed[]
    |>
  ]
];

CodexProjectedTransportSolve[___] :=
  <|"Status" -> "ProjectedTransportInputsNotWellFormed"|>;

CodexProjectedTransportSummary[result_] := Module[
  {exact = CodexProjectedTransportExactQ[result], firstMaps, secondMaps},
  firstMaps = Lookup[result, "FirstSegmentWordMaps", Missing[]];
  secondMaps = Lookup[result, "TwoSegmentWordMaps", Missing[]];
  <|
    "Family" -> Lookup[result, "Family", Missing["NoFamily"]],
    "Status" -> Lookup[result, "Status", Missing["NoStatus"]],
    "Exact" -> exact,
    "PhysicalDemandPairs" -> Length@Lookup[result,
      "PhysicalDemandPairs", {}],
    "BoundaryCoordinates" -> Lookup[result,
      "BoundaryCoordinates", Missing["NoBoundaryDimension"]],
    "MaximumWeight" -> Lookup[result,
      "MaximumWeight", Missing["NoWeight"]],
    "WordRepresentation" -> Lookup[result,
      "WordRepresentation", "MaterializedWords"],
    "FirstSegmentMapCountsByWeight" -> Lookup[result,
      "FirstSegmentMapCountsByWeight", Missing["NoFirstCounts"]],
    "TwoSegmentMapCountsByWeight" -> Lookup[result,
      "TwoSegmentMapCountsByWeight", Missing["NoTwoSegmentCounts"]],
    "TotalFirstSegmentMaps" -> If[ListQ[firstMaps], Length[firstMaps],
      Missing["CompactAutomatonNotEnumerated"]],
    "TotalTwoSegmentMaps" -> If[ListQ[secondMaps], Length[secondMaps],
      Missing["CompactAutomatonNotEnumerated"]],
    "DemandSeconds" -> Lookup[result, "DemandSeconds", Missing[]],
    "TransportSeconds" -> Lookup[result, "TransportSeconds", Missing[]],
    "TotalSeconds" -> Lookup[result, "TotalSeconds", Missing[]],
    "MaxMemoryUsedBytes" -> Lookup[result, "MaxMemoryUsedBytes", Missing[]]
  |>
];

CodexProjectedTransportWordMap[result_Association, firstWord_List,
    secondWord_List] := Module[
  {automaton, materialized, firstAlphabet, secondAlphabet, firstPositions,
   secondPositions, firstMaximum, requestedMaximum, initial, transitions,
   boundary, boundaryCount, orientation, initialCoordinates,
   terminalContractions, secondMatrices, weight, h, map, transitionWeight,
   cancelMatrix},

  cancelMatrix[m_] := Map[Quiet[Cancel[Together[#]]] &, Normal[m], {2}];
  automaton = Lookup[result, "CompactTransportAutomaton", Missing[]];
  If[! AssociationQ[automaton] ||
      Lookup[automaton, "Status", None] =!=
        "ExactCompactTwoSegmentAutomaton",
    materialized = Lookup[result, "TwoSegmentWordMaps", {}];
    materialized = SelectFirst[materialized,
      MatchQ[#, {firstWord, secondWord, _?MatrixQ}] &,
      Missing["WordMapNotPresent"]];
    Return[If[MissingQ[materialized],
      <|"Status" -> "WordMapNotAvailable",
        "FirstWord" -> firstWord, "SecondWord" -> secondWord|>,
      <|"Status" -> "ExactWordMap", "Source" -> "MaterializedWords",
        "FirstWord" -> firstWord, "SecondWord" -> secondWord,
        "Map" -> materialized[[3]]|>]]
  ];

  firstAlphabet = automaton["FirstAlphabetIndices"];
  secondAlphabet = automaton["SecondAlphabetIndices"];
  firstPositions = FirstPosition[firstAlphabet, #, Missing[]] & /@ firstWord;
  secondPositions = FirstPosition[secondAlphabet, #, Missing[]] & /@
    secondWord;
  If[AnyTrue[Join[firstPositions, secondPositions], MissingQ],
    Return[<|"Status" -> "WordUsesUnknownKernel",
      "FirstWord" -> firstWord, "SecondWord" -> secondWord|>]
  ];
  firstPositions = First /@ firstPositions;
  secondPositions = First /@ secondPositions;
  firstMaximum = automaton["FirstMaximumWeight"];
  requestedMaximum = automaton["RequestedMaximumWeight"];
  weight = Length[firstWord] + Length[secondWord];
  If[weight > requestedMaximum,
    Return[<|"Status" -> "WordExceedsRequestedWeight",
      "RequestedMaximumWeight" -> requestedMaximum,
      "FirstWord" -> firstWord, "SecondWord" -> secondWord|>]
  ];

  orientation = Lookup[automaton, "Orientation",
    "ForwardReachableColumns"];
  If[orientation === "DualObservableRows",
    boundaryCount = Lookup[automaton, "BoundaryCoordinateCount", 0],
    boundary = automaton["FirstBoundaryCoordinates"];
    boundaryCount = Dimensions[boundary][[2]]
  ];
  If[Length[firstWord] > firstMaximum,
    Return[<|"Status" -> "ExactWordMap", "Source" -> "CompactAutomaton",
      "FirstWord" -> firstWord, "SecondWord" -> secondWord,
      "Map" -> ConstantArray[0,
        {Length[Lookup[result, "PhysicalRows", {}]],
          boundaryCount}]|>]
  ];

  If[orientation === "DualObservableRows",
    initialCoordinates = automaton["FirstInitialCoordinates"];
    transitions = automaton["FirstObservableTransitionsByWeight"];
    terminalContractions =
      automaton["FirstTerminalContractionsByExactWeight"];
    h = initialCoordinates;
    Do[
      h = cancelMatrix[h .
        transitions[[position, firstPositions[[position]]]]],
      {position, Length[firstWord]}];
    map = cancelMatrix[
      h . terminalContractions[[Length[firstWord] + 1]]],

    initial = automaton["FirstInitialContractionsByExactWeight"];
    transitions = automaton["FirstReachableTransitionsByWeight"];
    h = initial[[Length[firstWord] + 1]];
    Do[
      transitionWeight = Length[firstWord] - position + 1;
      h = cancelMatrix[h .
        transitions[[transitionWeight, firstPositions[[position]]]]],
      {position, Length[firstWord]}];
    map = cancelMatrix[h . boundary]
  ];
  secondMatrices = automaton["SecondKernelMatrices"];
  Do[map = cancelMatrix[map . secondMatrices[[position]]],
    {position, secondPositions}];

  <|"Status" -> "ExactWordMap", "Source" -> "CompactAutomaton",
    "FirstWord" -> firstWord, "SecondWord" -> secondWord,
    "Map" -> map|>
];

CodexProjectedTransportWordMap[___] :=
  <|"Status" -> "ProjectedTransportWordInputsNotWellFormed"|>;

End[];
EndPackage[];
