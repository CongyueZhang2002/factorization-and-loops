(* Exact rational/signature modules for large master coefficients. *)

$coefficientModuleFormat = "FeynFacet-RationalSignatureModule";
$coefficientModuleVersion = 1;

coefficientModuleTopTerms[expression_] :=
  If[Head[expression] === Plus, List @@ expression, {expression}];

coefficientModuleTopFactors[expression_] :=
  If[Head[expression] === Times, List @@ expression, {expression}];

coefficientModuleScalarProductQ[expression_] := MatchQ[
  Head[expression],
  FeynCalc`SP | FeynCalc`SPD | FeynCalc`SPE
];

coefficientModuleRationalQ[expression_] := Which[
  IntegerQ[expression] || MatchQ[expression, _Rational], True,
  coefficientModuleScalarProductQ[expression], True,
  Head[expression] === Symbol,
    ! MemberQ[{Pi, E, EulerGamma, I, Infinity, ComplexInfinity}, expression],
  Head[expression] === Plus || Head[expression] === Times,
    AllTrue[List @@ expression, coefficientModuleRationalQ],
  MatchQ[expression, Power[_, _Integer]],
    coefficientModuleRationalQ[First[expression]],
  True, False
];

coefficientModuleHeld[expression_] := HoldComplete @@ {expression};

coefficientModuleSplitTerm[term_] := Module[
  {
    factors, rationalMask, rational, signature, normalized,
    numerator, denominator, timedOut = False
  },
  factors = coefficientModuleTopFactors[term];
  rationalMask = coefficientModuleRationalQ /@ factors;
  rational = Times @@ Pick[factors, rationalMask, True];
  signature = Times @@ Pick[factors, rationalMask, False];
  If[! SameQ[term, rational signature], Return[$Failed]];
  normalized = TimeConstrained[
    Quiet @ Cancel[rational],
    coefficientMasterTermTimeLimit[],
    timedOut = True;
    rational
  ];
  numerator = Numerator[normalized];
  denominator = Denominator[normalized];
  <|
    "Signature" -> coefficientModuleHeld[signature],
    "Denominator" -> denominator,
    "Numerator" -> numerator,
    "TimedOut" -> timedOut
  |>
];

coefficientModuleEntryKey[entry_Association] := coefficientModuleHeld[{
  entry["Signature"],
  entry["Denominator"]
}];

coefficientModuleEntryHash[entry_Association] :=
  Hash[coefficientModuleEntryKey[entry], "SHA256"];

coefficientModuleMergeEntries[entries_List] := Module[{groups},
  groups = GatherBy[entries, coefficientModuleEntryHash];
  If[
    ! AllTrue[
      groups,
      Function[group,
        With[{key = coefficientModuleEntryKey[First[group]]},
          AllTrue[Rest[group], SameQ[key, coefficientModuleEntryKey[#]] &]
        ]
      ]
    ],
    Return[$Failed]
  ];
  DeleteCases[
    Function[group,
      With[{numerator = Total[Lookup[group, "Numerator"]]},
        If[
          numerator === 0,
          Nothing,
          <|
            "Signature" -> First[group]["Signature"],
            "Denominator" -> First[group]["Denominator"],
            "Numerator" -> numerator,
            "SourceTermCount" -> Total[
              Lookup[#, "SourceTermCount", 1] & /@ group
            ]
          |>
        ]
      ]
    ] /@ groups,
    Nothing
  ]
];

coefficientModuleProcessLeaf[job_Association] := Module[
  {expression, terms, entries, merged, seconds, timeoutCount},
  {seconds, merged} = AbsoluteTiming @ Catch[
    expression = coefficientReadRecord[job["InputFile"]];
    If[expression === $Failed, Throw[$Failed]];
    terms = coefficientModuleTopTerms[expression];
    entries = coefficientModuleSplitTerm /@ terms;
    If[MemberQ[entries, $Failed], Throw[$Failed]];
    timeoutCount = Count[Lookup[entries, "TimedOut", False], True];
    merged = coefficientModuleMergeEntries[entries];
    If[merged === $Failed, Throw[$Failed]];
    If[
      coefficientWriteRecord[
        job["OutputFile"],
        <|
          "Format" -> $coefficientModuleFormat,
          "FormatVersion" -> $coefficientModuleVersion,
          "SourceFileHash" -> coefficientFileHash[job["InputFile"]],
          "TermCount" -> Length[terms],
          "TimeoutCount" -> timeoutCount,
          "Entries" -> merged
        |>
      ] === $Failed,
      Throw[$Failed]
    ];
    merged
  ];
  If[merged === $Failed, Return[$Failed]];
  <|
    "InputFile" -> job["InputFile"],
    "OutputFile" -> job["OutputFile"],
    "InputBytes" -> FileByteCount[job["InputFile"]],
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "TermCount" -> Length[terms],
    "EntryCount" -> Length[merged],
    "TimeoutCount" -> timeoutCount,
    "Seconds" -> seconds,
    "KernelID" -> $KernelID
  |>
];

coefficientModuleLeafValidQ[job_Association] := Module[{record},
  If[! FileExistsQ[job["OutputFile"]], Return[False]];
  record = coefficientReadRecord[job["OutputFile"]];
  AssociationQ[record] &&
    record["Format"] === $coefficientModuleFormat &&
    record["FormatVersion"] === $coefficientModuleVersion &&
    record["SourceFileHash"] === coefficientFileHash[job["InputFile"]] &&
    ListQ[record["Entries"]] && exactDataQ[record]
];

coefficientModuleBucketCount[] := 64;

coefficientModuleBucket[entry_Association, count_Integer] :=
  1 + Mod[coefficientModuleEntryHash[entry], count];

coefficientModulePartitionLeaf[job_Association] := Module[
  {record, entries, groups, files, seconds, count = job["BucketCount"]},
  {seconds, files} = AbsoluteTiming @ Catch[
    record = coefficientReadRecord[job["InputFile"]];
    If[! AssociationQ[record], Throw[$Failed]];
    entries = record["Entries"];
    groups = GatherBy[entries, coefficientModuleBucket[#, count] &];
    CreateDirectory[job["OutputDirectory"], CreateIntermediateDirectories -> True];
    Map[
      Function[group,
        With[
          {
            index = coefficientModuleBucket[First[group], count],
            file = FileNameJoin[{
              job["OutputDirectory"],
              "Bucket_" <>
                IntegerString[coefficientModuleBucket[First[group], count], 10, 4] <>
                ".bin"
            }]
          },
          If[coefficientWriteRecord[file, group] === $Failed, Throw[$Failed]];
          file
        ]
      ],
      groups
    ]
  ];
  If[files === $Failed, Return[$Failed]];
  <|
    "InputFile" -> job["InputFile"],
    "EntryCount" -> Length[entries],
    "OutputBytes" -> Total[FileByteCount /@ files],
    "Seconds" -> seconds,
    "KernelID" -> $KernelID
  |>
];

coefficientModuleMergeBucket[job_Association] := Module[
  {entries, merged, seconds},
  {seconds, merged} = AbsoluteTiming @ Catch[
    entries = Flatten[coefficientReadRecord /@ job["InputFiles"], 1];
    If[MemberQ[entries, $Failed], Throw[$Failed]];
    merged = coefficientModuleMergeEntries[entries];
    If[merged === $Failed, Throw[$Failed]];
    If[coefficientWriteRecord[job["OutputFile"], merged] === $Failed,
      Throw[$Failed]
    ];
    merged
  ];
  If[merged === $Failed, Return[$Failed]];
  <|
    "Bucket" -> job["Bucket"],
    "SourceEntryCount" -> Length[entries],
    "MergedEntryCount" -> Length[merged],
    "InputBytes" -> Total[FileByteCount /@ job["InputFiles"]],
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "Seconds" -> seconds,
    "KernelID" -> $KernelID
  |>
];

coefficientModuleRehydrateEntry[entry_Association] :=
  ReleaseHold[entry["Signature"]] entry["Numerator"]/entry["Denominator"];

coefficientModuleRehydrateBucket[job_Association] := Module[
  {entries, expression, seconds},
  {seconds, expression} = AbsoluteTiming @ Catch[
    entries = coefficientReadRecord[job["InputFile"]];
    If[! ListQ[entries], Throw[$Failed]];
    Total[coefficientModuleRehydrateEntry /@ entries]
  ];
  If[expression === $Failed, Return[$Failed]];
  If[coefficientWriteRecord[job["OutputFile"], expression] === $Failed,
    Return[$Failed]
  ];
  <|
    "InputFile" -> job["InputFile"],
    "OutputFile" -> job["OutputFile"],
    "EntryCount" -> Length[entries],
    "InputBytes" -> FileByteCount[job["InputFile"]],
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "Seconds" -> seconds,
    "KernelID" -> $KernelID
  |>
];

coefficientModuleRunJobs[jobs_List, worker_, label_String, jobsPerKernel_Integer] :=
  coefficientRunJobWaves[
    jobs,
    worker,
    label,
    Function[job,
      If[KeyExistsQ[job, "InputFile"] && FileExistsQ[job["InputFile"]],
        FileByteCount[job["InputFile"]],
        Total[FileByteCount /@ Lookup[job, "InputFiles", {}]]
      ]
    ],
    jobsPerKernel
  ];

coefficientModuleManifestFile[directory_String] :=
  FileNameJoin[{directory, "Manifest.wl"}];

coefficientProcessModuleMaster[job_Association, workDirectory_String] := Module[
  {
    name, directory, sourceDirectory, moduleDirectory, partitionDirectory,
    mergedDirectory, partialDirectory, leafInfo, leafJobs, pendingLeafJobs,
    leafSummaries, moduleFiles, bucketCount, partitionJobs,
    partitionSummaries, mergeJobs, mergeSummaries, mergedFiles,
    rehydrateJobs, rehydrateSummaries, streamFile, expression, parts,
    record, manifest, totalSeconds, output
  },
  totalSeconds = AbsoluteTime[];
  name = FileBaseName[job["OutputFile"]];
  directory = FileNameJoin[{workDirectory, "CoefficientModules", name}];
  sourceDirectory = FileNameJoin[{directory, "SourceRecords"}];
  moduleDirectory = FileNameJoin[{directory, "ModuleRecords"}];
  partitionDirectory = FileNameJoin[{directory, "PartitionRecords"}];
  mergedDirectory = FileNameJoin[{directory, "MergedModules"}];
  partialDirectory = FileNameJoin[{directory, "RehydratedPartials"}];
  Scan[
    If[coefficientEnsureDirectory[#] === $Failed, Return[$Failed, Module]] &,
    {directory, sourceDirectory, moduleDirectory}
  ];
  leafInfo = coefficientExplodeRecordFile[job["InputFile"], sourceDirectory];
  If[! AssociationQ[leafInfo], Return[$Failed]];
  leafJobs = MapIndexed[
    <|
      "InputFile" -> #1,
      "OutputFile" -> coefficientShardFile[
        moduleDirectory,
        "Module",
        First[#2]
      ]
    |> &,
    leafInfo["Files"]
  ];
  pendingLeafJobs = Select[leafJobs, ! coefficientModuleLeafValidQ[#] &];
  Print[
    "Rational/signature batches for ", name, ": ",
    Length[pendingLeafJobs], " / ", Length[leafJobs]
  ];
  leafSummaries = coefficientModuleRunJobs[
    pendingLeafJobs,
    coefficientModuleProcessLeaf,
    "Coefficient batches",
    Max[1, Ceiling[Length[pendingLeafJobs]/8]]
  ];
  If[leafSummaries === $Failed, Return[$Failed]];
  If[! AllTrue[leafJobs, coefficientModuleLeafValidQ], Return[$Failed]];
  moduleFiles = Lookup[leafJobs, "OutputFile"];

  If[coefficientResetDirectory[partitionDirectory] === $Failed, Return[$Failed]];
  If[coefficientResetDirectory[mergedDirectory] === $Failed, Return[$Failed]];
  bucketCount = coefficientModuleBucketCount[];
  partitionJobs = MapIndexed[
    <|
      "InputFile" -> #1,
      "OutputDirectory" -> FileNameJoin[{
        partitionDirectory,
        "Input_" <> IntegerString[First[#2], 10, 4]
      }],
      "BucketCount" -> bucketCount
    |> &,
    moduleFiles
  ];
  partitionSummaries = coefficientModuleRunJobs[
    partitionJobs,
    coefficientModulePartitionLeaf,
    "Module partition",
    Max[1, Ceiling[Length[partitionJobs]/8]]
  ];
  If[partitionSummaries === $Failed, Return[$Failed]];
  mergeJobs = DeleteCases[
    Table[
      With[
        {
          files = Sort @ FileNames[
            "Bucket_" <> IntegerString[index, 10, 4] <> ".bin",
            partitionDirectory,
            Infinity
          ]
        },
        If[
          files === {},
          Nothing,
          <|
            "Bucket" -> index,
            "InputFiles" -> files,
            "OutputFile" -> coefficientShardFile[
              mergedDirectory,
              "Module",
              index
            ]
          |>
        ]
      ],
      {index, bucketCount}
    ],
    Nothing
  ];
  mergeSummaries = coefficientModuleRunJobs[
    mergeJobs,
    coefficientModuleMergeBucket,
    "Module merge",
    Max[1, Ceiling[Length[mergeJobs]/8]]
  ];
  If[mergeSummaries === $Failed, Return[$Failed]];
  If[coefficientSafeWorkPathQ[partitionDirectory],
    DeleteDirectory[partitionDirectory, DeleteContents -> True]
  ];

  If[coefficientResetDirectory[partialDirectory] === $Failed, Return[$Failed]];
  mergedFiles = Lookup[mergeJobs, "OutputFile"];
  rehydrateJobs = MapIndexed[
    <|
      "InputFile" -> #1,
      "OutputFile" -> coefficientShardFile[
        partialDirectory,
        "Partial",
        First[#2]
      ]
    |> &,
    mergedFiles
  ];
  rehydrateSummaries = coefficientModuleRunJobs[
    rehydrateJobs,
    coefficientModuleRehydrateBucket,
    "Module rehydration",
    Max[1, Ceiling[Length[rehydrateJobs]/8]]
  ];
  If[rehydrateSummaries === $Failed, Return[$Failed]];
  streamFile = FileNameJoin[{directory, "RehydratedRecords.bin"}];
  If[FileExistsQ[streamFile], DeleteFile[streamFile]];
  Scan[
    Function[file,
      expression = coefficientReadRecord[file];
      If[
        expression === $Failed ||
          coefficientAppendRecord[streamFile, expression] === $Failed,
        Return[$Failed, Module]
      ];
      Clear[expression];
      ClearSystemCache[]
    ],
    Lookup[rehydrateSummaries, "OutputFile"]
  ];
  expression = coefficientBalancedRecordTotal[streamFile];
  If[expression === $Failed, Return[$Failed]];
  parts = structuralAdditiveFactor[expression];
  record = <|
    "Master" -> job["Master"],
    "PreFactor" -> First[parts],
    "Coefficient" -> Last[parts],
    "InputFileHash" -> coefficientFileHash[job["InputFile"]],
    "Normalizer" -> "RationalSignatureModule-v1"
  |>;
  If[coefficientWriteRecord[job["OutputFile"], record] === $Failed,
    Return[$Failed]
  ];
  If[
    coefficientWriteMasterManifest[
      job,
      record,
      Total[Lookup[leafSummaries, "TimeoutCount", 0]],
      TrueQ[record["Coefficient"] === 0]
    ] === $Failed,
    Return[$Failed]
  ];
  manifest = <|
    "Format" -> $coefficientModuleFormat,
    "FormatVersion" -> $coefficientModuleVersion,
    "InputFile" -> ExpandFileName[job["InputFile"]],
    "InputFileHash" -> coefficientFileHash[job["InputFile"]],
    "InputRecordCount" -> leafInfo["RecordCount"],
    "TermCount" -> Total[Lookup[leafSummaries, "TermCount", 0]],
    "EntryCount" -> Total[Lookup[mergeSummaries, "MergedEntryCount", 0]],
    "MergedFiles" -> Map[
      <|
        "File" -> FileNameTake[#],
        "Bytes" -> FileByteCount[#],
        "Hash" -> coefficientFileHash[#]
      |> &,
      mergedFiles
    ],
    "OutputFile" -> ExpandFileName[job["OutputFile"]],
    "OutputFileHash" -> coefficientFileHash[job["OutputFile"]]
  |>;
  Put[manifest, coefficientModuleManifestFile[directory]];
  Scan[
    Function[path,
      If[DirectoryQ[path] && coefficientSafeWorkPathQ[path],
        DeleteDirectory[path, DeleteContents -> True]
      ]
    ],
    {sourceDirectory, moduleDirectory, partialDirectory}
  ];
  If[FileExistsQ[streamFile], DeleteFile[streamFile]];
  Clear[expression, parts, record];
  ClearSystemCache[];
  output = <|
    "Master" -> job["Master"],
    "Zero" -> False,
    "OutputFile" -> job["OutputFile"],
    "Seconds" -> N[AbsoluteTime[] - totalSeconds],
    "TimeoutCount" -> Total[Lookup[leafSummaries, "TimeoutCount", 0]],
    "InputBytes" -> FileByteCount[job["InputFile"]],
    "OutputBytes" -> FileByteCount[job["OutputFile"]],
    "KernelID" -> 0
  |>;
  output
];

coefficientRunModuleMasterJobs[jobs_List, workDirectory_String] := Module[
  {summaries = {}, summary, completed = 0},
  Scan[
    Function[job,
      summary = coefficientProcessModuleMaster[job, workDirectory];
      If[summary === $Failed, Return[$Failed, Module]];
      AppendTo[summaries, summary];
      completed++;
      Print[
        "Large master coefficients ", completed, " / ", Length[jobs],
        "; time: ", Round[summary["Seconds"], 0.01], " s"
      ]
    ],
    Reverse @ SortBy[jobs, FileByteCount[#1["InputFile"]] &]
  ];
  summaries
];
