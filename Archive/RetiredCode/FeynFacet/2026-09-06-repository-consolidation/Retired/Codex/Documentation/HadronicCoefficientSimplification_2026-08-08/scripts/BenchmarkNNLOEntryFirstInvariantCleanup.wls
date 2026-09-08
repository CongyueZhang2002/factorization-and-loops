$HistoryLength = 0;
Global`$FACETKernelLimit = 8;

root = "/home/maxzhang/FACET";
studyDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "HadronicSimplification"
}];
sourceDirectory = FileNameJoin[{
  studyDirectory, "NNLOSelectedMasterColumns_SmallMedianHard_03"
}];
hardDirectory = FileNameJoin[{
  studyDirectory, "NNLOShardHardCoefficients_01"
}];
outputDirectory = FileNameJoin[{
  studyDirectory, "NNLOEntryFirstInvariantCleanupBenchmark_01"
}];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
commonFile = FileNameJoin[{
  root, "Codex", "ppHX_NLO", "HadronicSimplification", "TTOrdering",
  "Common.wl"
}];
fractionRingFile = FileNameJoin[{studyDirectory, "NNLOFractionRing.wl"}];
invariantRingFile = FileNameJoin[{studyDirectory, "NNLOInvariantRootRing.wl"}];

Get[loader];
Get[commonFile];
Get[fractionRingFile];
Get[invariantRingFile];
Clear[$PrePrint];

rootRingTests = {
  nnloInvariantRootLift[Sqrt[s^(-1)] s^(3/2)] === facetRs^2,
  nnloInvariantRootLift[s^(-7/2) + s^(5/2)] ===
    facetRs^(-7) + facetRs^5,
  nnloInvariantRootRestore[facetRs^4/(1 + facetRs^2)] ===
    s^2/(1 + s),
  nnloInvariantRootRestore[facetRs/(1 + facetRs^2)] === $Failed
};
If[! AllTrue[rootRingTests, TrueQ],
  Print["INVARIANT_ROOT_RING_TEST_FAILED: ", InputForm[rootRingTests]];
  Quit[1]
];

If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]
];

sourceManifest = Get[FileNameJoin[{sourceDirectory, "ShardManifest.wl"}]];
selectedMasters = sourceManifest["SelectedMasters"];
hardMaster = Last[selectedMasters];
shard = 40;
sourceFile = FileNameJoin[{
  sourceDirectory,
  "SelectedColumns_" <> IntegerString[shard, 10, 4] <> ".bin"
}];
hardFile = FileNameJoin[{
  hardDirectory,
  "HardCoefficients_" <> IntegerString[shard, 10, 4] <> ".bin"
}];
sourceData = FeynFacet`Private`coefficientReadRecord[sourceFile];
existingData = FeynFacet`Private`coefficientReadRecord[hardFile];
entries = sourceData[hardMaster];
existing = existingData["HardCoefficients"][hardMaster];

ClearAll[certifyAndCleanEntry];
certifyAndCleanEntry[job_] := Module[
  {
    assembly, certificate, hard, lifted, candidate, difference,
    certificateStatus, cleanupStatus, exactStatus, seconds
  },
  {seconds, {assembly, certificate, hard, lifted, candidate, difference}} =
    AbsoluteTiming[
      assembly = nnloAssembleFractionColumn[{job["Entry"]}, 60];
      If[! AssociationQ[assembly],
        Return[<|"Index" -> job["Index"], "Status" -> "AssemblyFailed"|>]
      ];
      certificate = nnloCertifyUniversalFactor[assembly, 60];
      certificateStatus = AssociationQ[certificate] &&
        TrueQ[Lookup[certificate, "Verified", False]];
      If[! certificateStatus,
        Return[<|"Index" -> job["Index"], "Status" -> "CertificateFailed"|>]
      ];
      hard = certificate["HardCoefficient"];
      lifted = nnloInvariantRootLift[hard];
      If[lifted === $Failed,
        Return[<|"Index" -> job["Index"], "Status" -> "LiftFailed"|>]
      ];
      candidate = TimeConstrained[
        MemoryConstrained[
          Quiet @ CheckAbort[Check[Cancel[Together[lifted]], $Failed], $Failed],
          4 1024^3,
          $MemoryExceeded
        ],
        300,
        $TimedOut
      ];
      cleanupStatus = ! MemberQ[
        {$Failed, $TimedOut, $MemoryExceeded},
        candidate
      ];
      If[! cleanupStatus,
        Return[<|
          "Index" -> job["Index"],
          "Status" -> ToString[InputForm[candidate]],
          "InputBytes" -> ByteCount[lifted]
        |>]
      ];
      difference = TimeConstrained[
        Quiet @ CheckAbort[
          Check[Cancel[Together[candidate - lifted]], $Failed],
          $Failed
        ],
        900,
        $TimedOut
      ];
      exactStatus = TrueQ[difference === 0];
      {assembly, certificate, hard, lifted, candidate, difference}
    ];
  If[! exactStatus,
    Return[<|"Index" -> job["Index"], "Status" -> "EqualityFailed"|>]
  ];
  <|
    "Index" -> job["Index"],
    "Status" -> "Verified",
    "Seconds" -> seconds,
    "LeafCount" -> job["Entry"]["LeafCount"],
    "SourceHash" -> job["SourceHash"],
    "InputBytes" -> ByteCount[lifted],
    "OutputBytes" -> ByteCount[candidate],
    "Coefficient" -> candidate,
    "CoefficientHash" -> Hash[candidate, "SHA256", "HexString"]
  |>
];

jobs = MapIndexed[
  <|
    "Index" -> First[#2],
    "Entry" -> #1,
    "SourceHash" -> Hash[#1, "SHA256", "HexString"]
  |> &,
  entries
];

CloseKernels[];
kernels = LaunchKernels[8];
With[
  {
    load = loader,
    common = commonFile,
    fractionRing = fractionRingFile,
    invariantRing = invariantRingFile
  },
  ParallelEvaluate[
    $HistoryLength = 0;
    Block[{$Output = {}, $Messages = {}}, Quiet[Get[load]]];
    Get[common];
    Get[fractionRing];
    Get[invariantRing];
    Clear[$PrePrint],
    kernels
  ]
];
DistributeDefinitions[certifyAndCleanEntry];
{wallSeconds, records} = AbsoluteTiming[
  ParallelMap[certifyAndCleanEntry, jobs, Method -> "FinestGrained"]
];
CloseKernels[kernels];

records = SortBy[records, Lookup[#, "Index"] &];
failed = Select[records, Lookup[#, "Status", Missing[]] =!= "Verified" &];
If[failed =!= {},
  Put[failed, FileNameJoin[{outputDirectory, "Failures.wl"}]];
  Print["ENTRY_FIRST_CLEANUP_FAILED"];
  Quit[2]
];

coefficients = Lookup[records, "Coefficient"];
rawTotal = Total[coefficients];
denominatorGroups = GroupBy[
  coefficients,
  HoldComplete[Denominator[#]] & -> Numerator
];
{bucketSeconds, bucketed} = AbsoluteTiming[
  Total @ KeyValueMap[
    Function[{heldDenominator, numerators},
      Cancel[Total[numerators]/ReleaseHold[heldDenominator]]
    ],
    denominatorGroups
  ]
];
{wholeSeconds, whole} = AbsoluteTiming[
  TimeConstrained[
    MemoryConstrained[
      Quiet @ CheckAbort[Check[Cancel[Together[bucketed]], $Failed], $Failed],
      6 1024^3,
      $MemoryExceeded
    ],
    600,
    $TimedOut
  ]
];

manifest = <|
  "Method" -> "IndividualUniversalFactorThenPositiveSRootCleanup",
  "Shard" -> shard,
  "Master" -> hardMaster,
  "Kernels" -> 8,
  "EntryCount" -> Length[entries],
  "LeafCount" -> Total[Lookup[entries, "LeafCount"]],
  "SourceFileHash" -> FileHash[sourceFile, "SHA256", "HexString"],
  "ExistingHardFileHash" -> FileHash[hardFile, "SHA256", "HexString"],
  "ExistingHardBytes" -> ByteCount[existing],
  "EntryWallSeconds" -> wallSeconds,
  "EntryInputBytes" -> Total[Lookup[records, "InputBytes"]],
  "EntryOutputBytes" -> Total[Lookup[records, "OutputBytes"]],
  "EntryCoefficientHashes" -> Lookup[records, "CoefficientHash"],
  "EntrySourceHashes" -> Lookup[records, "SourceHash"],
  "RawTotalBytes" -> ByteCount[rawTotal],
  "DenominatorGroups" -> Length[denominatorGroups],
  "BucketSeconds" -> bucketSeconds,
  "BucketBytes" -> ByteCount[bucketed],
  "WholeSeconds" -> wholeSeconds,
  "WholeOutcome" -> Which[
    whole === $TimedOut, "TimedOut",
    whole === $MemoryExceeded, "MemoryExceeded",
    whole === $Failed, "Failed",
    True, "Computed"
  ],
  "WholeBytes" -> If[
    MemberQ[{$TimedOut, $MemoryExceeded, $Failed}, whole],
    Missing["NotComputed"],
    ByteCount[whole]
  ],
  "ExactEntryCertificates" -> True,
  "FractionFree" -> FreeQ[
    coefficients,
    Alternatives @@ Join[nnloFractionVariables, nnloRootVariables]
  ],
  "InvariantRootOnly" -> FreeQ[coefficients, s]
|>;

Put[manifest, FileNameJoin[{outputDirectory, "Manifest.wl"}]];
FeynFacet`Private`coefficientWriteRecord[
  FileNameJoin[{outputDirectory, "CleanedEntries.bin"}],
  <|
    "Shard" -> shard,
    "Master" -> hardMaster,
    "SourceFileHash" -> manifest["SourceFileHash"],
    "Coefficients" -> coefficients
  |>
];
If[! MemberQ[{$TimedOut, $MemoryExceeded, $Failed}, whole],
  FeynFacet`Private`coefficientWriteRecord[
    FileNameJoin[{outputDirectory, "WholeCoefficient.bin"}],
    <|"Master" -> hardMaster, "Coefficient" -> whole|>
  ]
];
Print[ToString[InputForm[KeyDrop[manifest, {
  "EntryCoefficientHashes", "EntrySourceHashes"
}]]]];
Quit[];
