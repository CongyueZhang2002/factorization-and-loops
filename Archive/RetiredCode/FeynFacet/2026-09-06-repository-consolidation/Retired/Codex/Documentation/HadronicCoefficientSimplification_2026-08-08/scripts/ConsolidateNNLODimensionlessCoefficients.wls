$HistoryLength = 0;
Global`$FACETKernelLimit = 8;

root = "/home/maxzhang/FACET";
study = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "HadronicSimplification"
}];
inputDirectory = FileNameJoin[{
  study, "NNLOSelectedMasterCoefficients_DimensionlessBenchmark_01"
}];
outputDirectory = FileNameJoin[{
  study, "NNLOSelectedMasterCoefficients_DimensionlessConsolidated_01"
}];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
mergeFile = FileNameJoin[{study, "NNLOSizeMonotoneMerge.wl"}];

Get[loader];
Get[mergeFile];
Clear[$PrePrint];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]
];

manifest = Get[FileNameJoin[{inputDirectory, "Manifest.wl"}]];
inputFiles = Lookup[manifest["Masters"], "OutputFile"];

CloseKernels[];
kernels = LaunchKernels[8];
With[{load = loader, merge = mergeFile},
  ParallelEvaluate[
    $HistoryLength = 0;
    Block[{$Output = {}, $Messages = {}}, Quiet[Get[load]]];
    Get[merge];
    Clear[$PrePrint],
    kernels
  ]
];
DistributeDefinitions[
  nnloMergeExactPairGroup,
  nnloMergeHashJob
];

reports = {};
Do[
  data = FeynFacet`Private`coefficientReadRecord[file];
  inputPairs = data["Fractions"];
  records = (
    {Hash[Last[#], "SHA256", "HexString"], #} & /@ inputPairs
  );
  {seconds, consolidated} = AbsoluteTiming[
    nnloSizeMonotoneConsolidation[records]
  ];
  finalPairs = consolidated["Fractions"];
  output = <|
    "MasterIndex" -> data["MasterIndex"],
    "Master" -> data["Master"],
    "ScalePower" -> data["ScalePower"],
    "Variables" -> data["Variables"],
    "PhysicalChamber" -> data["PhysicalChamber"],
    "InputFileHash" -> FileHash[file, "SHA256", "HexString"],
    "InputFractionCount" -> Length[inputPairs],
    "InputBytes" -> ByteCount[inputPairs],
    "ConsolidationSeconds" -> seconds,
    "ConsolidationHistory" -> consolidated["History"],
    "FinalFractionCount" -> Length[finalPairs],
    "FinalBytes" -> ByteCount[finalPairs],
    "ExactData" -> FreeQ[finalPairs, _Real],
    "SFree" -> FreeQ[finalPairs, s],
    "Fractions" -> finalPairs
  |>;
  outputFile = FileNameJoin[{
    outputDirectory,
    "DimensionlessConsolidatedMasterCoefficient_" <>
      IntegerString[data["MasterIndex"], 10, 3] <> ".bin"
  }];
  FeynFacet`Private`coefficientWriteRecord[outputFile, output];
  report = Join[
    KeyDrop[output, "Fractions"],
    <|
      "OutputFile" -> outputFile,
      "OutputFileBytes" -> FileByteCount[outputFile],
      "OutputFileHash" -> FileHash[outputFile, "SHA256", "HexString"]
    |>
  ];
  AppendTo[reports, report];
  Put[reports, FileNameJoin[{outputDirectory, "Progress.wl"}]];
  Print[
    "Master ", data["MasterIndex"], ": ", Length[inputPairs], " -> ",
    Length[finalPairs], " fractions; ", ByteCount[inputPairs], " -> ",
    ByteCount[finalPairs], " bytes"
  ];
  Clear[data, inputPairs, records, consolidated, finalPairs, output, report],
  {file, inputFiles}
];
CloseKernels[kernels];

finalManifest = <|
  "Method" -> "DimensionlessSizeMonotoneConsolidation",
  "Kernels" -> 8,
  "InputManifestHash" -> FileHash[
    FileNameJoin[{inputDirectory, "Manifest.wl"}],
    "SHA256",
    "HexString"
  ],
  "Masters" -> reports
|>;
Put[finalManifest, FileNameJoin[{outputDirectory, "Manifest.wl"}]];
Print[InputForm[finalManifest]];
Quit[];
