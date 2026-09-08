$HistoryLength = 0;
Global`$FACETKernelLimit = 8;

root = "/home/maxzhang/FACET";
study = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "HadronicSimplification"
}];
inputDirectory = FileNameJoin[{
  study, "NNLOSelectedMasterCoefficients_SizeMonotone_01"
}];
outputDirectory = FileNameJoin[{
  study, "NNLOSelectedMasterCoefficients_DimensionlessBenchmark_01"
}];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];

Get[loader];
Clear[$PrePrint];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]
];

manifest = Get[FileNameJoin[{inputDirectory, "Manifest.wl"}]];
inputFiles = Lookup[manifest["Masters"], "OutputFile"];

ClearAll[homogeneousDegree];
homogeneousDegree[expression_, variable_Symbol] := Module[{walk},
  walk[node_] := Which[
    SameQ[Unevaluated[node], variable], 1,
    FreeQ[node, variable], 0,
    Head[Unevaluated[node]] === Plus,
      With[{degrees = DeleteDuplicates[walk /@ (List @@ node)]},
        If[Length[degrees] === 1 && FreeQ[degrees, $Failed],
          First[degrees],
          $Failed
        ]
      ],
    Head[Unevaluated[node]] === Times,
      With[{degrees = walk /@ (List @@ node)},
        If[FreeQ[degrees, $Failed], Total[degrees], $Failed]
      ],
    Head[Unevaluated[node]] === Power && IntegerQ[node[[2]]],
      With[{degree = walk[node[[1]]]},
        If[degree === $Failed, $Failed, node[[2]] degree]
      ],
    True, $Failed
  ];
  walk[expression]
];

ClearAll[dimensionlessPair];
dimensionlessPair[pair_List] := Module[
  {numerator, denominator, numeratorDegree, denominatorDegree},
  numerator = First[pair] /. {t -> -s facetX, u -> -s facetY};
  denominator = Last[pair] /. {t -> -s facetX, u -> -s facetY};
  numeratorDegree = homogeneousDegree[numerator, s];
  denominatorDegree = homogeneousDegree[denominator, s];
  If[
    ! IntegerQ[numeratorDegree] || ! IntegerQ[denominatorDegree],
    Return[<|"Outcome" -> "NotHomogeneous"|>]
  ];
  <|
    "Outcome" -> "Completed",
    "ScalePower" -> numeratorDegree - denominatorDegree,
    "Pair" -> {
      numerator /. s -> 1,
      denominator /. s -> 1
    }
  |>
];

ClearAll[exactReconstructionTest];
exactReconstructionTest[item_Association] := Module[
  {source, normalized, reconstructed, difference},
  source = item["Source"];
  normalized = item["Normalized"];
  reconstructed = s^normalized["ScalePower"] *
    First[normalized["Pair"]]/Last[normalized["Pair"]] /.
      {facetX -> -t/s, facetY -> -u/s};
  difference = TimeConstrained[
    MemoryConstrained[
      Quiet @ Check[
        Cancel[Together[First[source]/Last[source] - reconstructed]],
        $Failed
      ],
      3 1024^3,
      $MemoryExceeded
    ],
    300,
    $TimedOut
  ];
  <|
    "SourceHash" -> Hash[source, "SHA256", "HexString"],
    "Outcome" -> Which[
      difference === 0, "ExactZero",
      difference === $TimedOut, "TimedOut",
      difference === $MemoryExceeded, "MemoryExceeded",
      difference === $Failed, "Failed",
      True, "Nonzero"
    ]
  |>
];

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
  homogeneousDegree,
  dimensionlessPair,
  exactReconstructionTest
];

masterReports = {};
Do[
  data = FeynFacet`Private`coefficientReadRecord[file];
  sourcePairs = data["Fractions"];
  {normalizationSeconds, normalized} = AbsoluteTiming[
    ParallelMap[dimensionlessPair, sourcePairs, Method -> "FinestGrained"]
  ];
  completed = Select[normalized, Lookup[#, "Outcome"] === "Completed" &];
  normalizedPairs = Lookup[completed, "Pair"];
  scalePowers = DeleteDuplicates[Lookup[completed, "ScalePower"]];
  sampleIndices = If[
    Length[sourcePairs] === 1,
    {1},
    DeleteDuplicates @ Join[
      Range[Min[8, Length[sourcePairs]]],
      Round @ Subdivide[
        1,
        Length[sourcePairs],
        Min[15, Length[sourcePairs] - 1]
      ],
      Range[Max[1, Length[sourcePairs] - 7], Length[sourcePairs]]
    ]
  ];
  samples = MapThread[
    <|"Source" -> #1, "Normalized" -> #2|> &,
    {sourcePairs[[sampleIndices]], normalized[[sampleIndices]]}
  ];
  {testSeconds, reconstructionTests} = AbsoluteTiming[
    ParallelMap[exactReconstructionTest, samples, Method -> "FinestGrained"]
  ];
  report = <|
    "MasterIndex" -> data["MasterIndex"],
    "Master" -> data["Master"],
    "InputFractions" -> Length[sourcePairs],
    "CompletedFractions" -> Length[completed],
    "OutcomeCounts" -> Counts[Lookup[normalized, "Outcome"]],
    "ScalePowers" -> scalePowers,
    "NormalizationSeconds" -> normalizationSeconds,
    "InputBytes" -> ByteCount[sourcePairs],
    "DimensionlessBytes" -> ByteCount[normalizedPairs],
    "InputDenominatorHashes" -> Length @ DeleteDuplicates[
      Hash[Last[#], "SHA256", "HexString"] & /@ sourcePairs
    ],
    "DimensionlessDenominatorHashes" -> Length @ DeleteDuplicates[
      Hash[Last[#], "SHA256", "HexString"] & /@ normalizedPairs
    ],
    "SFree" -> FreeQ[normalizedPairs, s],
    "ExactData" -> FreeQ[normalizedPairs, _Real],
    "PhysicalChamber" -> HoldForm[
      s > 0 && facetX > 0 && facetY > 0 && facetX + facetY < 1
    ],
    "ReconstructionTestSeconds" -> testSeconds,
    "ReconstructionTests" -> reconstructionTests,
    "ReconstructionTestsExactZero" -> AllTrue[
      reconstructionTests,
      Lookup[#, "Outcome"] === "ExactZero" &
    ]
  |>;
  If[
    Length[completed] === Length[sourcePairs] && Length[scalePowers] === 1 &&
      report["SFree"] && report["ExactData"] &&
      report["ReconstructionTestsExactZero"],
    output = <|
      "MasterIndex" -> data["MasterIndex"],
      "Master" -> data["Master"],
      "ScalePower" -> First[scalePowers],
      "Variables" -> {facetX, facetY},
      "PhysicalChamber" -> report["PhysicalChamber"],
      "Fractions" -> normalizedPairs,
      "SourceFileHash" -> FileHash[file, "SHA256", "HexString"],
      "Report" -> KeyDrop[report, "ReconstructionTests"]
    |>;
    outputFile = FileNameJoin[{
      outputDirectory,
      "DimensionlessMasterCoefficient_" <>
        IntegerString[data["MasterIndex"], 10, 3] <> ".bin"
    }];
    FeynFacet`Private`coefficientWriteRecord[outputFile, output];
    AssociateTo[report, <|
      "OutputFile" -> outputFile,
      "OutputFileBytes" -> FileByteCount[outputFile],
      "OutputFileHash" -> FileHash[outputFile, "SHA256", "HexString"]
    |>]
  ];
  AppendTo[masterReports, report];
  Put[masterReports, FileNameJoin[{outputDirectory, "Progress.wl"}]];
  Print[
    "Master ", data["MasterIndex"], ": scale powers ", scalePowers,
    "; ", ByteCount[sourcePairs], " -> ", ByteCount[normalizedPairs],
    " bytes; denominator classes ",
    report["InputDenominatorHashes"], " -> ",
    report["DimensionlessDenominatorHashes"]
  ];
  Clear[
    data, sourcePairs, normalized, completed, normalizedPairs,
    samples, reconstructionTests, output, report
  ],
  {file, inputFiles}
];
CloseKernels[kernels];

finalReport = <|
  "Method" -> "ExactDimensionlessHomogeneousNormalization",
  "Kernels" -> 8,
  "Substitution" -> HoldForm[{t -> -s facetX, u -> -s facetY}],
  "Masters" -> masterReports
|>;
Put[finalReport, FileNameJoin[{outputDirectory, "Manifest.wl"}]];
Print[InputForm[finalReport]];
Quit[];
