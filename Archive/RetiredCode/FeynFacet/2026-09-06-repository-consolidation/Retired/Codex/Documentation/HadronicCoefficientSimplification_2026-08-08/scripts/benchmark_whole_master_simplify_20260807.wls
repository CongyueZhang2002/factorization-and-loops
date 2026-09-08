$HistoryLength = 0;
$LoadFeynArts = True;
Global`$FACETKernelLimit = 8;

root = "/home/maxzhang/FACET";
work = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "CoefficientSimplification",
  "UU_08_05_1"
}];
outputDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "Validation",
  "WholeMasterSimplifyBenchmark"
}];
summaryFile = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "Validation",
  "WholeMasterSimplifyBenchmark_20260807.wl"
}];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

If[DirectoryQ[outputDirectory],
  DeleteDirectory[outputDirectory, DeleteContents -> True]
];
CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True];

metadata = FeynFacet`Private`coefficientReadRecord[
  FileNameJoin[{work, "KiraStore", "Metadata.bin"}]
];
assumptions = metadata["AnalyticContext", "Assumptions"];

jobs = Table[
  With[{name = "Master_" <> IntegerString[index, 10, 4] <> ".bin"},
    <|
      "MasterIndex" -> index,
      "Master" -> metadata["Masters"][[index]],
      "InputFile" -> FileNameJoin[{work, "MasterRecords", name}],
      "CurrentFile" -> FileNameJoin[{work, "FinalMasters", name}],
      "OutputFile" -> FileNameJoin[{outputDirectory, name}],
      "Assumptions" -> assumptions
    |>
  ],
  {index, 3, 10}
];

Clear[benchmarkReadRecord, benchmarkWriteRecord, benchmarkExactDataQ];
benchmarkReadRecord[file_String] := Module[
  {stream, length, bytes, value, extra},
  stream = OpenRead[file, BinaryFormat -> True];
  If[Head[stream] =!= InputStream, Return[$Failed]];
  length = BinaryRead[stream, "UnsignedInteger64"];
  If[! IntegerQ[length] || length < 0,
    Close[stream];
    Return[$Failed]
  ];
  bytes = BinaryReadList[stream, "Byte", length];
  extra = BinaryRead[stream, "UnsignedInteger64"];
  Close[stream];
  If[Length[bytes] =!= length || extra =!= EndOfFile, Return[$Failed]];
  value = Quiet @ Check[BinaryDeserialize[ByteArray[bytes]], $Failed];
  value
];

benchmarkWriteRecord[file_String, expression_] := Module[
  {stream, bytes, values},
  bytes = BinarySerialize[expression];
  values = Normal[bytes];
  If[FileExistsQ[file], DeleteFile[file]];
  stream = OpenWrite[file, BinaryFormat -> True];
  If[Head[stream] =!= OutputStream, Return[$Failed]];
  BinaryWrite[stream, Length[values], "UnsignedInteger64"];
  BinaryWrite[stream, values, "Byte"];
  Close[stream];
  file
];

benchmarkExactDataQ[expression_] := FreeQ[
  Unevaluated[expression],
  _Real | _Complex | Indeterminate | ComplexInfinity | DirectedInfinity[_],
  Infinity
];

Clear[wholeMasterSimplifyWorker];
wholeMasterSimplifyWorker[job_Association] := Module[
  {expression, seconds, result, outputRecord, status},
  expression = FeynFacet`Private`coefficientBalancedRecordTotal[
    job["InputFile"]
  ];
  If[expression === $Failed, Return[$Failed]];
  {seconds, result} = AbsoluteTiming[
    MemoryConstrained[
      TimeConstrained[
        Simplify[expression, Assumptions -> job["Assumptions"]],
        1800,
        $Aborted
      ],
      4 1024^3,
      $Aborted
    ]
  ];
  status = Which[
    result === $Aborted, "Aborted",
    ! FeynFacet`Private`exactDataQ[result], "NonExact",
    True, "Completed"
  ];
  If[status === "Completed",
    outputRecord = <|
      "Master" -> job["Master"],
      "Coefficient" -> result,
      "PreFactor" -> 1
    |>;
    If[
      FeynFacet`Private`coefficientWriteRecord[
        job["OutputFile"], outputRecord
      ] === $Failed,
      Return[$Failed]
    ]
  ];
  <|
    "MasterIndex" -> job["MasterIndex"],
    "Status" -> status,
    "Seconds" -> seconds,
    "InputBytes" -> FileByteCount[job["InputFile"]],
    "CurrentBytes" -> FileByteCount[job["CurrentFile"]],
    "OutputBytes" -> If[
      status === "Completed",
      FileByteCount[job["OutputFile"]],
      Missing["NotAvailable"]
    ],
    "Compression" -> If[
      status === "Completed",
      N[FileByteCount[job["InputFile"]]/FileByteCount[job["OutputFile"]]],
      Missing["NotAvailable"]
    ],
    "KernelID" -> $KernelID
  |>
];

LaunchKernels[8];
With[{path = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]},
  ParallelEvaluate[
    $HistoryLength = 0;
    $LoadFeynArts = True;
    Block[{$Output = {}, $Messages = {}}, Quiet[Get[path]]];
  ]
];
DistributeDefinitions[wholeMasterSimplifyWorker];
{totalSeconds, summaries} = AbsoluteTiming[
  ParallelMap[wholeMasterSimplifyWorker, jobs, Method -> "FinestGrained"]
];
CloseKernels[];

Put[<|"Seconds" -> totalSeconds, "Results" -> summaries|>, summaryFile];
Print[InputForm[<|"Seconds" -> totalSeconds, "Results" -> summaries|>]];
Exit[If[ListQ[summaries], 0, 2]];
