(* Entrywise compaction of merged canonical trace columns: each
   contribution (w_i)*(t_i)*(r_i) is replaced by the exact Together of
   the product, in parallel.  The rational function of the column is
   unchanged; only its representation shrinks (measured on master 1's
   largest bucket: byte-tail entries compact 28x at ~1.9 s per input
   MB, no entry over 6 s).  Probe time is linear in column size
   (measured 0.45-0.5 ms per MB), so this is the probe-rate lever.

   The original file is kept next to the compacted one as
   <name>.expr.fat; the manifest's ExpressionBytes are rewritten.

   Usage:
     wolframscript -file Scripts/compact_trace_columns.wls \
       <canonicalDir> <kernels> <outputKey> [<outputKey> ...]
   e.g. outputKey 000001_000001 names Output_000001_000001.expr *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3,
  Print["Usage: compact_trace_columns.wls <canonicalDir> <kernels> <outputKey>..."];
  Exit[1]
];
directory = ExpandFileName[arguments[[1]]];
kernels = ToExpression[arguments[[2]]];
keys = Drop[arguments, 2];

splitter = FileNameJoin[{
  DirectoryName[$InputFileName], "split_merged.py"
}];
If[! FileExistsQ[splitter],
  Print["Missing splitter: ", splitter];
  Exit[1]
];

record = FeynFacet`Private`coefficientReadRecord[
  FeynFacet`Private`finiteFieldTraceManifestFile[directory]
];
If[! AssociationQ[record] ||
    record["Format"] =!= "FeynFacet-TraceCheckpoint",
  Print["Not a trace checkpoint: ", directory];
  Exit[1]
];
traceData = record["TraceData"];

LaunchKernels[kernels];
Print["KERNELS: ", Length[Kernels[]]];

compactColumn[key_String] := Module[
  {file, linesFile, run, records, entries, timedOut, stream, total},
  file = FileNameJoin[{directory, "Expressions", "Output_" <> key <> ".expr"}];
  If[! FileExistsQ[file], Print["MISSING: ", file]; Return[$Failed]];
  linesFile = file <> ".lines";
  run = RunProcess[{"python3", splitter, file, linesFile}];
  If[run["ExitCode"] =!= 0,
    Print["SPLIT FAILED: ", key, " ", run["StandardError"]];
    Return[$Failed]
  ];
  records = ReadList[linesFile, String];
  Print[key, ": ", Length[records], " contributions, ",
    Round[FileByteCount[file]/2.^20, 0.1], " MB"];
  entries = ParallelMap[
    Function[line,
      Module[{parts, weight, contribution, result},
        parts = StringSplit[line, "\t"];
        weight = ToExpression[parts[[1]], InputForm];
        contribution = ToExpression[parts[[2]], InputForm, HoldComplete];
        result = TimeConstrained[
          Together[weight ReleaseHold[contribution]],
          300,
          $TimedOut
        ];
        If[result === $TimedOut,
          $TimedOut,
          StringReplace[
            ToString[result, InputForm],
            WhitespaceCharacter .. -> ""
          ]
        ]
      ]
    ],
    records,
    Method -> "ItemsPerEvaluation" -> 16
  ];
  timedOut = Count[entries, $TimedOut];
  If[timedOut > 0,
    Print["TIMEDOUT ENTRIES: ", timedOut, " - keeping the original"];
    DeleteFile[linesFile];
    Return[$Failed]
  ];
  entries = Select[entries, # =!= "0" &];
  stream = OpenWrite[file <> ".new"];
  Do[
    WriteString[stream,
      If[i === 1, "", "+"], "(", entries[[i]], ")"],
    {i, Length[entries]}
  ];
  WriteString[stream, "\n"];
  Close[stream];
  DeleteFile[linesFile];
  RenameFile[file, file <> ".fat"];
  RenameFile[file <> ".new", file];
  total = FileByteCount[file];
  Print[key, ": compacted to ", Round[total/2.^20, 0.1], " MB"];
  total
];

Scan[
  Function[key,
    Module[{seconds, result},
      {seconds, result} = AbsoluteTiming[compactColumn[key]];
      Print[key, ": ", Round[seconds, 0.1], " s"];
      If[result === $Failed, Exit[1]]
    ]
  ],
  keys
];

(* Rewrite the manifest's byte table from the files on disk, through
   the package's record writer (the manifest is a length-prefixed WXF
   record store, not a plain WXF file). *)
traceData["ExpressionBytes"] = FileByteCount /@ traceData["OutputFiles"];
FeynFacet`Private`finiteFieldWriteTraceManifest[
  directory,
  traceData,
  record["InputFileFingerprint"],
  record["KiraFileHash"]
];
Print["MANIFEST UPDATED"];
