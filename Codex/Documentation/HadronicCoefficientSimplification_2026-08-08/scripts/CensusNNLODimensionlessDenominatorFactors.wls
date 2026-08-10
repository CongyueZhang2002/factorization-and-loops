$HistoryLength = 0;
Global`$FACETKernelLimit = 8;

root = "/home/maxzhang/FACET";
study = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "HadronicSimplification"
}];
inputDirectory = FileNameJoin[{
  study, "NNLOSelectedMasterCoefficients_DimensionlessConsolidated_01"
}];
outputDirectory = FileNameJoin[{
  study, "NNLODimensionlessDenominatorFactorCensus_01"
}];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
inputFile = FileNameJoin[{
  inputDirectory, "DimensionlessConsolidatedMasterCoefficient_003.bin"
}];

Get[loader];
Clear[$PrePrint];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]
];

ClearAll[xyFactorNormalize];
xyFactorNormalize[factor_] := Module[{expanded, rules, leading},
  expanded = Expand[factor];
  rules = CoefficientRules[expanded, {facetX, facetY}];
  If[Length[rules] === 0, Return[{expanded, 1}]];
  leading = Last[First[rules]];
  {Cancel[expanded/leading], leading}
];

ClearAll[xyFactorBase];
xyFactorBase[base_, outerExponent_Integer] := Module[
  {seconds, factorization, unit, factors, normalized, leading},
  If[FreeQ[base, facetX | facetY], Return[<|
    "Unit" -> base^outerExponent,
    "Factors" -> {},
    "Outcome" -> "CoefficientFieldElement",
    "Seconds" -> 0.
  |>]];
  {seconds, factorization} = AbsoluteTiming[
    TimeConstrained[
      MemoryConstrained[
        Quiet @ Check[FactorList[Expand[base]], $Failed],
        1024^3,
        $MemoryExceeded
      ],
      60,
      $TimedOut
    ]
  ];
  If[MemberQ[{$TimedOut, $MemoryExceeded, $Failed}, factorization],
    {normalized, leading} = xyFactorNormalize[base];
    Return[<|
      "Unit" -> leading^outerExponent,
      "Factors" -> {{normalized, outerExponent}},
      "Outcome" -> Which[
        factorization === $TimedOut, "TimedOutAtomic",
        factorization === $MemoryExceeded, "MemoryExceededAtomic",
        True, "FailedAtomic"
      ],
      "Seconds" -> seconds
    |>]
  ];
  unit = First[First[factorization]]^outerExponent;
  factors = Reap[
    Do[
      If[FreeQ[item[[1]], facetX | facetY],
        unit *= item[[1]]^(outerExponent item[[2]]),
        {normalized, leading} = xyFactorNormalize[item[[1]]];
        unit *= leading^(outerExponent item[[2]]);
        Sow[{normalized, outerExponent item[[2]]}]
      ],
      {item, Rest[factorization]}
    ]
  ][[2]];
  <|
    "Unit" -> unit,
    "Factors" -> If[factors === {}, {}, First[factors]],
    "Outcome" -> "Factored",
    "Seconds" -> seconds
  |>
];

ClearAll[xyDenominatorFactorRecord];
xyDenominatorFactorRecord[denominator_] := Module[
  {pieces, records, unit, factors, reconstruction, difference},
  pieces = If[Head[Unevaluated[denominator]] === Times,
    List @@ denominator,
    {denominator}
  ];
  records = Map[
    Function[piece,
      If[Head[Unevaluated[piece]] === Power &&
          IntegerQ[piece[[2]]] && piece[[2]] > 0,
        xyFactorBase[piece[[1]], piece[[2]]],
        xyFactorBase[piece, 1]
      ]
    ],
    pieces
  ];
  unit = Times @@ Lookup[records, "Unit"];
  factors = Flatten[Lookup[records, "Factors"], 1];
  factors = KeyValueMap[{#1, Total[#2[[All, 2]]]} &,
    GroupBy[factors, First -> Identity]
  ];
  reconstruction = unit Times @@ (Power @@@ factors);
  difference = Quiet @ Check[Cancel[Together[denominator - reconstruction]],
    $Failed
  ];
  <|
    "Unit" -> unit,
    "Factors" -> factors,
    "ExactReconstruction" -> TrueQ[difference === 0],
    "OutcomeCounts" -> Counts[Lookup[records, "Outcome"]],
    "Seconds" -> Total[Lookup[records, "Seconds"]]
  |>
];

data = FeynFacet`Private`coefficientReadRecord[inputFile];
pairs = data["Fractions"];
denominators = Last /@ pairs;

CloseKernels[];
kernels = LaunchKernels[8];
With[{load = loader},
  ParallelEvaluate[
    $HistoryLength = 0;
    Block[{$Output = {}, $Messages = {}}, Quiet[Get[load]]];
    Clear[$PrePrint],
    kernels
  ]
];
DistributeDefinitions[
  xyFactorNormalize,
  xyFactorBase,
  xyDenominatorFactorRecord
];

{factorSeconds, records} = AbsoluteTiming[
  ParallelMap[
    xyDenominatorFactorRecord,
    denominators,
    Method -> "FinestGrained"
  ]
];
CloseKernels[kernels];

allFactorPairs = Flatten[Lookup[records, "Factors"], 1];
factorOccurrences = First /@ allFactorPairs;
factorHashGroups = GroupBy[
  factorOccurrences,
  Hash[#, "SHA256", "HexString"] &
];
hashCollisionFree = AllTrue[
  Values[factorHashGroups],
  Function[group, AllTrue[Rest[group], SameQ[#, First[group]] &]]
];
factorHashes = Sort[Keys[factorHashGroups]];
factorTable = First /@ Lookup[factorHashGroups, factorHashes];
factorIDs = Association @ MapIndexed[
  #1 -> First[#2] &,
  factorHashes
];

profiles = Map[
  Function[record,
    ({Lookup[
        factorIDs,
        Hash[#[[1]], "SHA256", "HexString"],
        $Failed
      ], #[[2]]} & /@
      record["Factors"])
  ],
  records
];
units = Lookup[records, "Unit"];
incidences = Flatten[First /@ # & /@ profiles];
recurrence = Reverse @ SortBy[Normal @ Counts[incidences], Last];

dictionaryArtifact = <|
  "Method" -> "ExactDimensionlessDenominatorFactorDictionary",
  "SourceFileHash" -> FileHash[inputFile, "SHA256", "HexString"],
  "MasterIndex" -> data["MasterIndex"],
  "Master" -> data["Master"],
  "ScalePower" -> data["ScalePower"],
  "Variables" -> data["Variables"],
  "PhysicalChamber" -> data["PhysicalChamber"],
  "Numerators" -> First /@ pairs,
  "DenominatorUnits" -> units,
  "DenominatorProfiles" -> profiles,
  "FactorTable" -> factorTable
|>;
dictionaryFile = FileNameJoin[{outputDirectory, "FactorDictionary.bin"}];
FeynFacet`Private`coefficientWriteRecord[dictionaryFile, dictionaryArtifact];

report = <|
  "Method" -> "ExactDimensionlessDenominatorFactorCensus",
  "SourceFile" -> inputFile,
  "SourceFileHash" -> FileHash[inputFile, "SHA256", "HexString"],
  "SourceSerializedBytes" -> FileByteCount[inputFile],
  "DenominatorCount" -> Length[denominators],
  "FactorizationSeconds" -> factorSeconds,
  "ExactReconstructionCount" -> Count[
    Lookup[records, "ExactReconstruction"], True
  ],
  "AllExactReconstructions" -> And @@ Lookup[
    records, "ExactReconstruction"
  ],
  "OutcomeCounts" -> Merge[Lookup[records, "OutcomeCounts"], Total],
  "WorkerSeconds" -> Total[Lookup[records, "Seconds"]],
  "DistinctFactorCount" -> Length[factorTable],
  "FactorIncidenceCount" -> Length[incidences],
  "FactorHashCollisionFree" -> hashCollisionFree,
  "FactorIDsComplete" -> FreeQ[profiles, $Failed | _Missing],
  "RecurrenceCounts" -> Counts[Last /@ recurrence],
  "LargestRecurrences" -> Take[recurrence, UpTo[30]],
  "DictionaryFile" -> dictionaryFile,
  "DictionarySerializedBytes" -> FileByteCount[dictionaryFile],
  "DictionaryFileHash" -> FileHash[
    dictionaryFile, "SHA256", "HexString"
  ]
|>;

Put[report, FileNameJoin[{outputDirectory, "Census.wl"}]];
Print[InputForm[report]];
If[
  TrueQ[report["AllExactReconstructions"]] &&
    TrueQ[report["FactorHashCollisionFree"]] &&
    TrueQ[report["FactorIDsComplete"]],
  Quit[0],
  Quit[2]
];
