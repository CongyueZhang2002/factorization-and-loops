(* First-class finite-field reconstruction of an emitted coefficient
   trace.

   The trace emitter (Simplification.wl) writes one expression file per
   (master, analytic signature) column plus a manifest that records the
   masters, the signatures, the alias map and the physical factor.  This
   module turns that directory into the production CoefficientResult:

     - hybrid scheduling: homogeneous columns share one trace, outliers
       run solo, ascending by size.  A shared trace pays the maximum
       probe count times the total evaluation cost, so a fat column
       bundled with small ones charges its probe count to all of them
       (measured 18 h vs 8 h on the NNLO set);
     - optional eps-truncated reconstruction through ratracer
       "to-series", which cut the fat NNLO column from 3.9 M probes /
       ~6 h to 297 k probes / 15.5 min (measured 2026-08-13) and was
       verified exact to the truncation;
     - a streaming, subset-safe result parser that resolves markers by
       path instead of by position (the positional parser in
       Simplification.wl silently swallows blocks on a partial result
       set, and misses relative-path markers entirely);
     - resume: a result file carrying the DONE marker is never redone,
       which is the only checkpoint available because FireFly itself
       cannot checkpoint;
     - file-based progress, so a status command in another kernel can
       report phase, probe count, rate and ETA while the reconstructing
       kernel is blocked inside RunProcess.

   Everything channel-specific comes from the manifest and the card
   behind it: the module knows nothing about UU, TT or ghost sets. *)

ClearAll[
  $reconstructionFailure,
  $reconstructionDoneMarker,
  $reconstructionMarkerLineLimit,
  $reconstructionArtifactFormat,
  $reconstructionArtifactVersion,
  reconstructionFail,
  reconstructionTenth,
  reconstructionSeriesQ,
  reconstructionSeriesNormal,
  reconstructionSeriesFromOrders,
  reconstructionTraceRecord,
  reconstructionAbsolutePath,
  reconstructionOutputIndex,
  reconstructionMarkerLine,
  reconstructionSeriesAlias,
  reconstructionScanMarkers,
  reconstructionManifestCandidates,
  reconstructionSelectManifest,
  reconstructionParseBlock,
  reconstructionStreamBlocks,
  reconstructionCollectResults,
  reconstructionResultFiles,
  reconstructionScheduleJobs,
  reconstructionJobRecordFile,
  reconstructionJobTraceFile,
  reconstructionJobDoneQ,
  reconstructionJobScript,
  reconstructionRunJob,
  reconstructionRunSchedule,
  reconstructionProgressSamples,
  reconstructionInputs,
  reconstructionOrderExpressions,
  reconstructionRepairAssembly,
  reconstructionMergeOrders,
  reconstructionAssembleProduction,
  reconstructionColumnArtifact,
  reconstructionAssembledArtifact,
  reconstructionRandomRational,
  reconstructionSliceValue,
  reconstructionVerifySlice,
  reconstructionVerifySlices,
  reconstructionVerifySeriesOrders
];

(* Clear, not ClearAll: the public symbols carry the usage messages
   FeynFacet.m installed before this file is read, and ClearAll would
   remove them along with the definitions. *)
Clear[ReconstructCoefficients, ReconstructionStatus];

ReconstructCoefficients::trace =
  "`1` is not a finite-field trace directory: `2`.";

ReconstructCoefficients::option =
  "Invalid `1` option: `2`.";

ReconstructCoefficients::job =
  "Reconstruction job `1` failed (`2`); see `3`.";

ReconstructCoefficients::parse =
  "Result file `1`: `2`.";

ReconstructCoefficients::coverage =
  "The parsed result blocks do not cover the trace: `1`.";

ReconstructCoefficients::assembly =
  "The reconstructed coefficients could not be assembled: `1`.";

ReconstructCoefficients::verify =
  "Verification failed: `1`.";

ReconstructionStatus::directory =
  "`1` holds no reconstruction progress data.";

Options[ReconstructCoefficients] = {
  "SeriesVariable" -> Automatic,
  "SeriesOrder" -> 5,
  "Threads" -> Automatic,
  "Schedule" -> Automatic,
  "BundleBelowBytes" -> 16 2^20,
  "Resume" -> True,
  "RatracerExecutable" -> Automatic,
  "FactorScan" -> True,
  "ShiftScan" -> True,
  "CoefficientSetup" -> Automatic,
  "ResultFile" -> Automatic,
  "ProgressInterval" -> 60,
  "VerifySlices" -> 0,
  "VerifySeriesOrders" -> None
};

$reconstructionFailure = Unique["reconstructionFailure$"];

(* The marker is appended to the result file by the job script itself,
   after ratracer exits with status 0.  A result file without it was
   truncated by an interrupted run and is reconstructed again. *)
$reconstructionDoneMarker = "(* FeynFacet-ReconstructionDone";

(* A marker line is short and ends in " ="; a payload line is the whole
   rational function and can be tens of MB, so the length test comes
   first and keeps the scan off the payload. *)
$reconstructionMarkerLineLimit = 4096;

$reconstructionArtifactFormat = "FeynFacet-AssembledCoefficients";
$reconstructionArtifactVersion = 2;

reconstructionFail[stage_, detail_] := (
  coefficientProgressFailure[stage, detail];
  Message[ReconstructCoefficients::assembly,
    ToString[stage] <> ": " <> ToString[detail]];
  Throw[$Failed, $reconstructionFailure]
);

(* Round[x, 0.1] leaves binary noise in the printout (0.7000000000001);
   round through the exact rational instead. *)
reconstructionTenth[value_] := N[Round[10 value]/10];

(* --- the series storage convention -------------------------------- *)

(* A truncated column is stored as
     <|"SeriesVariable" -> var, "Orders" -> <|n -> value, ...|>|>
   with integer n counted from the column's true Laurent start.  Every
   consumer must accept this form and the plain rational form; the pair
   below is the conversion both directions. *)

reconstructionSeriesQ[value_] :=
  AssociationQ[value] &&
    Sort[Keys[value]] === {"Orders", "SeriesVariable"} &&
    AssociationQ[value["Orders"]] &&
    AllTrue[Keys[value["Orders"]], IntegerQ];

reconstructionSeriesFromOrders[variable_, orders_Association] := <|
  "SeriesVariable" -> variable,
  "Orders" -> KeySort[orders]
|>;

reconstructionSeriesNormal[value_] := If[
  reconstructionSeriesQ[value],
  Total @ KeyValueMap[
    Function[{order, coefficient}, coefficient value["SeriesVariable"]^order],
    value["Orders"]
  ],
  value
];

(* --- the trace manifest ------------------------------------------- *)

reconstructionTraceRecord[directory_String] := Module[{file, record},
  file = finiteFieldTraceManifestFile[directory];
  If[! FileExistsQ[file], Return[$Failed]];
  record = Quiet @ Check[coefficientReadRecord[file], $Failed];
  If[
    ! AssociationQ[record] ||
      record["Format"] =!= "FeynFacet-TraceCheckpoint" ||
      ! AssociationQ[record["TraceData"]] ||
      ! ListQ[record["TraceData"]["OutputFiles"]],
    $Failed,
    record
  ]
];

(* OutputFiles are written absolute, but a manifest moved with its
   directory (or produced by a relative-path run) is still usable, so
   an entry is resolved against the manifest's own directory. *)
reconstructionAbsolutePath[directory_String, path_String] :=
  ExpandFileName[
    If[StringStartsQ[path, "/"], path, FileNameJoin[{directory, path}]]
  ];

reconstructionOutputIndex[directory_String, outputFiles_List] :=
  Association @ Join[
    MapIndexed[# -> First[#2] &, outputFiles],
    MapIndexed[reconstructionAbsolutePath[directory, #] -> First[#2] &,
      outputFiles]
  ];

(* --- markers ------------------------------------------------------- *)

(* Two marker forms occur.  A full rational run names the expression
   file itself:

     /path/Output_000001_000001.expr =

   and a to-series run splits every output into one block per order:

     ORDER[/path/Output_000001_000001.expr,FACETff...v3^-1] =

   ratracer writes the path exactly as it was passed on its command
   line, so both an absolute and a relative form must be accepted. *)
reconstructionMarkerLine[line_String] := Module[
  {trimmed, body, comma, path, power, parts, alias, order},
  If[StringLength[line] >= $reconstructionMarkerLineLimit, Return[None]];
  trimmed = StringTrim[line];
  If[StringStartsQ[trimmed, $reconstructionDoneMarker], Return["Done"]];
  If[! StringEndsQ[trimmed, "="] || StringLength[trimmed] < 2,
    Return[None]
  ];
  trimmed = StringTrim[StringDrop[trimmed, -1]];
  If[trimmed === "" || ! StringFreeQ[trimmed, WhitespaceCharacter],
    Return[None]
  ];
  If[! (StringStartsQ[trimmed, "ORDER["] && StringEndsQ[trimmed, "]"]),
    Return[<|"Path" -> trimmed, "Order" -> None, "Alias" -> None|>]
  ];
  body = StringTake[trimmed, {7, -2}];
  (* The order part carries no comma, so the last comma separates it
     from a path that may well contain one. *)
  comma = Last[StringPosition[body, ","], None];
  If[comma === None, Return[None]];
  path = StringTake[body, {1, First[comma] - 1}];
  power = StringDrop[body, First[comma]];
  parts = StringSplit[power, "^"];
  {alias, order} = Switch[Length[parts],
    1, {First[parts], 1},
    2, {First[parts], Quiet @ Check[ToExpression[Last[parts]], $Failed]},
    _, {None, $Failed}
  ];
  If[path === "" || ! StringQ[alias] || ! IntegerQ[order], Return[None]];
  <|"Path" -> path, "Order" -> order, "Alias" -> alias|>
];

reconstructionSeriesAlias[traceData_Association, variable_] := Module[
  {rules, alias},
  rules = traceData["SymbolRules"];
  If[! AssociationQ[rules], Return[$Failed]];
  alias = Lookup[rules, Key[variable], Missing["NotATraceVariable"]];
  If[MissingQ[alias], $Failed, SymbolName[alias]]
];

(* --- streaming block reader ---------------------------------------- *)

(* One pass over the file.  The payload is handed to the caller block by
   block and never accumulated, because a single block reaches 17 MB and
   a result file 262 MB (measured on the NNLO set). *)
reconstructionStreamBlocks[file_String, handler_] := Module[
  {stream, line, marker, current = None, lines = {}, position = 0,
   lastPosition = -1, terminated = False, regressed = False},
  stream = OpenRead[file];
  If[Head[stream] =!= InputStream, Return[$Failed]];
  While[True,
    position = StreamPosition[stream];
    line = ReadLine[stream];
    marker = If[line === EndOfFile, None, reconstructionMarkerLine[line]];
    terminated = line === EndOfFile || marker === "Done";
    Which[
      terminated || AssociationQ[marker],
        If[current =!= None,
          handler[current, StringRiffle[lines, "\n"]]
        ];
        current = None;
        lines = {};
        If[terminated, Break[]];
        (* The stream only moves forward, so this can only fire if the
           reader itself regressed; it is the invariant the positional
           parser in Simplification.wl never checked. *)
        If[position <= lastPosition, regressed = True; Break[]];
        lastPosition = position;
        current = Append[marker, "Position" -> position],
      current =!= None,
        AppendTo[lines, line]
    ]
  ];
  Close[stream];
  If[regressed, $Failed, True]
];

(* Marker-only pass: used solely when the trace directory has to be
   discovered from the markers themselves, where the payload would be
   read and thrown away twice otherwise. *)
reconstructionScanMarkers[file_String] := Module[
  {stream, line, marker, markers = {}},
  stream = OpenRead[file];
  If[Head[stream] =!= InputStream, Return[$Failed]];
  While[(line = ReadLine[stream]) =!= EndOfFile,
    marker = reconstructionMarkerLine[line];
    If[marker === "Done", Break[]];
    If[AssociationQ[marker], AppendTo[markers, marker]]
  ];
  Close[stream];
  markers
];

(* Same contract as finiteFieldParseReconstruction: the block is read as
   InputForm, certified to be a rational function of the alias variables
   only, and mapped back through the symbols the parse actually created
   (their context depends on the reading session, their names do not).
   Unlike that function every rejection names its cause. *)
reconstructionParseBlock[
    text_String,
    aliasNames_List,
    aliasOriginals_Association
  ] := Module[{trimmed, held, expression, aliases, rules},
  trimmed = StringReplace[StringTrim[text], RegularExpression[";\\s*$"] -> ""];
  If[trimmed === "", Return[Failure["Empty", <|"MessageTemplate" ->
    "the block carries no expression"|>]]];
  held = Quiet @ Check[
    ToExpression[trimmed, InputForm, HoldComplete],
    $Failed
  ];
  If[Head[held] =!= HoldComplete,
    Return[Failure["Syntax", <|"MessageTemplate" ->
      "the block is not readable as InputForm"|>]]
  ];
  expression = ReleaseHold[held];
  If[! finiteFieldParseRational[expression, aliasNames],
    Return[Failure["Grammar", <|"MessageTemplate" ->
      "the block is not a rational function of the trace variables"|>]]
  ];
  aliases = DeleteDuplicates @ Cases[
    expression,
    symbol_Symbol /; MemberQ[aliasNames, SymbolName[symbol]] :> symbol,
    Infinity
  ];
  rules = Dispatch[(# -> aliasOriginals[SymbolName[#]]) & /@ aliases];
  expression /. rules
];

reconstructionResultFiles[directory_String] :=
  Sort @ FileNames["rec_*.txt", directory];

(* --- collecting a whole result directory --------------------------- *)

(* Returns
     <|"Columns" -> <|outputIndex -> rational | <|order -> rational|>|>,
       "Covered" / "Partial" / "Missing" -> master index lists,
       "Orders" -> the observed order range, ...|>
   and fails loudly - never silently - on a duplicated marker, a marker
   that names no output of the trace, a non-monotone order sequence
   within one output, or a block that does not parse. *)
reconstructionCollectResults[
    directory_String,
    traceDirectory_String,
    traceData_Association,
    seriesVariable_,
    resultFiles_List
  ] := Catch[
  Module[
    {
      outputFiles, index, aliasNames, aliasOriginals, seriesAlias,
      columns = <||>, orderSequence = <||>, seenIn = <||>,
      parsed = 0, started, status, resolve, record, blocks = 0
    },
    outputFiles = traceData["OutputFiles"];
    index = reconstructionOutputIndex[traceDirectory, outputFiles];
    aliasNames = SymbolName /@ Values[traceData["SymbolRules"]];
    aliasOriginals = AssociationThread[
      aliasNames,
      Keys[traceData["SymbolRules"]]
    ];
    seriesAlias = If[seriesVariable === None,
      None,
      reconstructionSeriesAlias[traceData, seriesVariable]
    ];
    If[seriesAlias === $Failed,
      reconstructionFail["result parsing",
        "the series variable is not a trace variable"]
    ];

    resolve[marker_Association, file_String] := Module[{key},
      key = Lookup[
        index,
        reconstructionAbsolutePath[traceDirectory, marker["Path"]],
        Missing["NotAnOutput"]
      ];
      If[MissingQ[key],
        Message[ReconstructCoefficients::parse, FileNameTake[file],
          "the marker " <> marker["Path"] <> " names no output of the trace"];
        reconstructionFail["result parsing", "an unresolved marker"]
      ];
      If[seriesAlias === None,
        If[marker["Order"] =!= None,
          Message[ReconstructCoefficients::parse, FileNameTake[file],
            "a series block appeared in a full rational reconstruction"];
          reconstructionFail["result parsing", "an unexpected series block"]
        ],
        If[marker["Order"] === None || marker["Alias"] =!= seriesAlias,
          Message[ReconstructCoefficients::parse, FileNameTake[file],
            "a block is not a series in " <> ToString[seriesAlias]];
          reconstructionFail["result parsing", "a mismatched series block"]
        ]
      ];
      key
    ];

    record[marker_Association, text_String, file_String] := Module[
      {output, order, expression, orders},
      output = resolve[marker, file];
      order = marker["Order"];
      If[KeyExistsQ[seenIn, {output, order}],
        Message[ReconstructCoefficients::parse, FileNameTake[file],
          "output " <> ToString[output] <> " order " <> ToString[order] <>
            " is already present in " <> FileNameTake[seenIn[{output, order}]]];
        reconstructionFail["result parsing", "a duplicated result block"]
      ];
      AssociateTo[seenIn, {output, order} -> file];
      (* ratracer emits the orders of one output in increasing order and
         with no gaps; anything else means the file was edited, spliced
         or truncated, and must not be assembled. *)
      If[order =!= None,
        orders = Lookup[orderSequence, output, {}];
        If[orders =!= {} && order =!= Last[orders] + 1,
          Message[ReconstructCoefficients::parse, FileNameTake[file],
            "output " <> ToString[output] <> " jumps from order " <>
              ToString[Last[orders]] <> " to " <> ToString[order]];
          reconstructionFail["result parsing", "an out-of-order series block"]
        ];
        AssociateTo[orderSequence, output -> Append[orders, order]]
      ];
      expression = reconstructionParseBlock[text, aliasNames, aliasOriginals];
      If[FailureQ[expression],
        Message[ReconstructCoefficients::parse, FileNameTake[file],
          "output " <> ToString[output] <> ": " <>
            expression["MessageTemplate"]];
        reconstructionFail["result parsing", "an unparsable result block"]
      ];
      If[order === None,
        AssociateTo[columns, output -> expression],
        AssociateTo[
          columns,
          output -> Append[Lookup[columns, output, <||>], order -> expression]
        ]
      ];
      blocks++;
      If[Mod[blocks, 25] === 0,
        Print["    parsed ", blocks, " blocks, ",
          reconstructionTenth[AbsoluteTime[] - started], " s, ",
          Round[MemoryInUse[]/2.^20], " MB in use"]
      ]
    ];

    started = AbsoluteTime[];
    Scan[
      Function[file,
        Module[{seconds, outcome},
          {seconds, outcome} = AbsoluteTiming @ reconstructionStreamBlocks[
            file,
            Function[{marker, text}, record[marker, text, file]]
          ];
          If[outcome === $Failed,
            Message[ReconstructCoefficients::parse, FileNameTake[file],
              "the file could not be read as a block stream"];
            reconstructionFail["result parsing", "an unreadable result file"]
          ];
          Print["    ", FileNameTake[file], ": ",
            reconstructionTenth[FileByteCount[file]/2.^20], " MB parsed in ",
            reconstructionTenth[seconds], " s"]
        ]
      ],
      resultFiles
    ];
    parsed = Length[columns];

    status = Module[{grouped, present},
      grouped = GroupBy[
        Range[Length[outputFiles]],
        traceData["OutputMetadata"][[#]]["MasterIndex"] &
      ];
      AssociationMap[
        Function[master,
          present = Count[
            Lookup[grouped, master, {}],
            output_ /; KeyExistsQ[columns, output]
          ];
          Which[
            present === Length[Lookup[grouped, master, {}]], "Covered",
            present === 0, "Missing",
            True, "Partial"
          ]
        ],
        (* A master with no output at all is complete with coefficient
           zero: the emitter writes an output only where a nonzero
           contribution landed. *)
        Range[Length[traceData["Masters"]]]
      ]
    ];
    <|
      "Columns" -> columns,
      "OutputCount" -> Length[outputFiles],
      "ParsedOutputs" -> parsed,
      "BlockCount" -> blocks,
      "Covered" -> Keys @ Select[status, # === "Covered" &],
      "Partial" -> Keys @ Select[status, # === "Partial" &],
      "Missing" -> Keys @ Select[status, # === "Missing" &],
      "OrderSequence" -> orderSequence,
      "SeriesVariable" -> seriesVariable,
      "ResultFiles" -> resultFiles,
      "ParseSeconds" -> AbsoluteTime[] - started
    |>
  ],
  $reconstructionFailure
];

(* --- manifest discovery (the CLI entry points) --------------------- *)

(* The result files of a series run live in a depth-specific
   subdirectory of the trace directory, so the manifest is looked for in
   the directory itself, in its parent, and in the parent's other
   children - which is also how the older manual runs, that put the rec
   files beside a sibling trace, are still found. *)
reconstructionManifestCandidates[directory_String, traceDirectory_] :=
  If[StringQ[traceDirectory],
    {finiteFieldTraceManifestFile[ExpandFileName[traceDirectory]]},
    Select[
      DeleteDuplicates @ Map[
        finiteFieldTraceManifestFile,
        Join[
          {directory, ParentDirectory[directory]},
          Select[FileNames["*", ParentDirectory[directory]], DirectoryQ]
        ]
      ],
      FileExistsQ
    ]
  ];

(* A candidate is accepted only if every marker resolves, against its own
   directory, to one of its output files - which is also what tells the
   canonical trace apart from an older one beside it. *)
reconstructionSelectManifest[
    directory_String,
    traceDirectory_,
    markers_List
  ] := Module[{candidates},
  (* No Return[Nothing] here: Return is not caught inside a Module
     inside an anonymous Function and would leave a literal
     Return[Nothing] in the list - the defect documented at
     reconstructionRepairAssembly. *)
  candidates = Map[
    Function[file,
      Module[{record, traceDirectoryOfFile, index, resolved},
        record = reconstructionTraceRecord[DirectoryName[file]];
        If[
          record === $Failed,
          Nothing,
          (* DirectoryName keeps the trailing separator; normalize it
             away so the recorded directory compares equal to an
             expanded path. *)
          traceDirectoryOfFile = FileNameJoin[
            FileNameSplit[DirectoryName[file]]
          ];
          index = reconstructionOutputIndex[
            traceDirectoryOfFile,
            record["TraceData"]["OutputFiles"]
          ];
          resolved = Count[
            markers,
            marker_ /; KeyExistsQ[
              index,
              reconstructionAbsolutePath[traceDirectoryOfFile, marker["Path"]]
            ]
          ];
          <|
            "File" -> file,
            "Directory" -> traceDirectoryOfFile,
            "Record" -> record,
            "Matched" -> resolved
          |>
        ]
      ]
    ],
    reconstructionManifestCandidates[directory, traceDirectory]
  ];
  candidates = SortBy[candidates, -#["Matched"] &];
  Scan[
    Print["  candidate ", #["File"], ": ", #["Matched"], "/",
      Length[markers], " blocks resolve"] &,
    candidates
  ];
  First[
    Select[candidates, #["Matched"] === Length[markers] &],
    $Failed
  ]
];

(* --- scheduling ---------------------------------------------------- *)

(* Bundle every column below the threshold into one shared trace and
   isolate the rest as solo jobs, ascending by size so that the early
   completions validate the run before the expensive column starts. *)
reconstructionScheduleJobs[
    traceData_Association,
    bundleBelow_,
    schedule_
  ] := Module[{bytes, outputs, small, large, jobs},
  bytes = If[
    ListQ[traceData["ExpressionBytes"]] &&
      Length[traceData["ExpressionBytes"]] === Length[traceData["OutputFiles"]],
    traceData["ExpressionBytes"],
    FileByteCount /@ traceData["OutputFiles"]
  ];
  outputs = Range[Length[traceData["OutputFiles"]]];
  {small, large} = Switch[schedule,
    "Shared", {outputs, {}},
    "Solo", {{}, outputs},
    _, {
      Select[outputs, bytes[[#]] < bundleBelow &],
      Select[outputs, bytes[[#]] >= bundleBelow &]
    }
  ];
  large = SortBy[large, bytes[[#]] &];
  jobs = Join[
    If[small === {},
      {},
      {<|
        "Name" -> "shared",
        "Outputs" -> small,
        "Bytes" -> Total[bytes[[small]]]
      |>}
    ],
    Map[
      <|
        "Name" -> "solo_" <> IntegerString[#, 10, 6],
        "Outputs" -> {#},
        "Bytes" -> bytes[[#]]
      |> &,
      large
    ]
  ];
  MapIndexed[Append[#1, "Index" -> First[#2]] &, jobs]
];

(* --- running one job ----------------------------------------------- *)

reconstructionJobRecordFile[directory_String, job_Association] :=
  FileNameJoin[{directory, "rec_" <> job["Name"] <> ".txt"}];

(* The trace file name carries the mode: a saved to-series trace has the
   regulator already eliminated, so replaying it as a full rational
   trace - or at another depth - would be silently wrong. *)
reconstructionJobTraceFile[
    directory_String,
    job_Association,
    options_Association
  ] := FileNameJoin[{
  directory, "Jobs",
  job["Name"] <> If[
    options["SeriesVariable"] === None,
    ".trace.gz",
    ".series" <> ToString[options["SeriesOrder"]] <> ".trace.gz"
  ]
}];

reconstructionJobDoneQ[file_String] := Module[{stream, size, text},
  If[! FileExistsQ[file], Return[False]];
  size = FileByteCount[file];
  stream = OpenRead[file];
  If[Head[stream] =!= InputStream, Return[False]];
  SetStreamPosition[stream, Max[0, size - 4096]];
  text = ReadString[stream];
  Close[stream];
  StringQ[text] && StringContainsQ[text, $reconstructionDoneMarker]
];

(* The job runs as a shell script for three reasons: RunProcess cannot
   launch a command with thousands of arguments (measured: 100 fine,
   4400 returns no result at all) and one NNLO trace names 2203
   expression files; the FireFly log has to be written incrementally so
   a status command can read it; and the progress sampler has to run
   while ratracer runs, which the calling kernel cannot do because it is
   blocked inside RunProcess. *)
reconstructionJobScript[
    job_Association,
    arguments_List,
    directory_String,
    logFile_String,
    recordFile_String,
    progressFile_String,
    doneFile_String,
    interval_Integer
  ] := Module[{quote, temporary},
  quote[value_String] := "'" <> StringReplace[value, "'" -> "'\\''"] <> "'";
  temporary = FileNameJoin[{directory, "Temporary", job["Name"]}];
  StringRiffle[
    {
      "#!/bin/bash",
      "set -u",
      "log=" <> quote[logFile],
      "rec=" <> quote[recordFile],
      "progress=" <> quote[progressFile],
      "done_file=" <> quote[doneFile],
      "export TMPDIR=" <> quote[temporary],
      "rm -rf \"$TMPDIR\"",
      "mkdir -p \"$TMPDIR\"",
      ": >\"$log\"",
      "",
      (* Cumulative probes: '<n> probes in total' is the running total
         and resets never, 'Probe: <k>' counts within the current prime
         and resets at every promotion, so the live count is the last
         total plus the probes seen since.  Threads interleave their
         writes, hence the scan for every match on a line rather than a
         whole-line match. *)
      "probe_state() {",
      "  awk '",
      "    {",
      "      line = $0",
      "      while (match(line, /Probe: [0-9]+|[0-9]+ probes in total/)) {",
      "        m = substr(line, RSTART, RLENGTH)",
      "        if (m ~ /^Probe:/) { cur = substr(m, 8) + 0 }",
      "        else { tot = m + 0; cur = 0 }",
      "        line = substr(line, RSTART + RLENGTH)",
      "      }",
      "      if ($0 ~ /Completed current prime field/ && first == 0) {",
      "        first = tot",
      "      }",
      "      if ($0 ~ /Promote to new prime field/) { primes++; phase = \"prime\" primes }",
      "      if ($0 ~ /Scanning for/) { phase = \"scan\" }",
      "      if ($0 ~ /Proceeding with interpolation/) {",
      "        if (primes == 0) primes = 1",
      "        phase = \"prime\" primes",
      "      }",
      "    }",
      "    END {",
      "      printf \"%d %s %d\\n\", tot + cur, (phase == \"\" ? \"start\" : phase), first",
      "    }' \"$log\"",
      "}",
      "",
      "emit() {",
      "  set -- $(probe_state)",
      "  printf '%s %s %s\\n' \"$(date +%s)\" \"$1\" \"$2\" >>\"$progress\"",
      "}",
      "",
      "start=$(date +%s)",
      StringRiffle[quote /@ arguments, " "] <> " >>\"$log\" 2>&1 &",
      "pid=$!",
      "while kill -0 \"$pid\" 2>/dev/null; do",
      "  emit",
      "  for i in $(seq 1 " <> ToString[interval] <> "); do",
      "    kill -0 \"$pid\" 2>/dev/null || break",
      "    sleep 1",
      "  done",
      "done",
      "wait \"$pid\"",
      "status=$?",
      "emit",
      "rm -rf \"$TMPDIR\"",
      (* and the shared parent, once the last job has left it *)
      "rmdir \"$(dirname \"$TMPDIR\")\" 2>/dev/null || true",
      "if [ \"$status\" -eq 0 ] && [ -s \"$rec\" ]; then",
      "  set -- $(probe_state)",
      "  seconds=$(( $(date +%s) - start ))",
      "  printf '" <> $reconstructionDoneMarker <>
        " job=%s probes=%s seconds=%s *)\\n' " <>
        quote[job["Name"]] <> " \"$1\" \"$seconds\" >>\"$rec\"",
      "  printf '<|\"Job\" -> \"%s\", \"Outputs\" -> " <>
        ToString[Length[job["Outputs"]]] <>
        ", \"Probes\" -> %s, \"FirstPrimeProbes\" -> %s, " <>
        "\"Seconds\" -> %s, \"Completed\" -> %s|>\\n' " <>
        quote[job["Name"]] <> " \"$1\" \"$3\" \"$seconds\" \"$(date +%s)\" " <>
        ">\"$done_file\"",
      "fi",
      "exit \"$status\""
    },
    "\n"
  ] <> "\n"
];

reconstructionRunJob[
    job_Association,
    traceData_Association,
    directory_String,
    executable_String,
    options_Association
  ] := Module[
  {
    outputFiles, traceFile, outputsFile, logFile, recordFile,
    progressFile, doneFile, scriptFile, arguments, script, result,
    seconds, seriesVariable, seriesAlias, order, reuse
  },
  seriesVariable = options["SeriesVariable"];
  order = options["SeriesOrder"];
  outputFiles = traceData["OutputFiles"][[job["Outputs"]]];
  traceFile = reconstructionJobTraceFile[directory, job, options];
  outputsFile = FileNameJoin[{directory, "Jobs", job["Name"] <> ".outputs.txt"}];
  logFile = FileNameJoin[{directory, "Jobs", job["Name"] <> ".log"}];
  doneFile = FileNameJoin[{directory, "Jobs", job["Name"] <> ".done"}];
  scriptFile = FileNameJoin[{directory, "Jobs", job["Name"] <> ".sh"}];
  recordFile = reconstructionJobRecordFile[directory, job];
  progressFile = FileNameJoin[{directory, "progress", job["Name"] <> ".progress"}];
  Scan[
    If[! DirectoryQ[#], CreateDirectory[#, CreateIntermediateDirectories -> True]] &,
    {FileNameJoin[{directory, "Jobs"}], FileNameJoin[{directory, "progress"}]}
  ];
  seriesAlias = If[seriesVariable === None,
    None,
    reconstructionSeriesAlias[traceData, seriesVariable]
  ];
  If[seriesAlias === $Failed,
    Return[$Failed]
  ];
  (* Rebuilding a trace is deterministic given the same expressions, so
     a saved one whose output list is complete is replayed instead. *)
  reuse = FileExistsQ[traceFile] && FileExistsQ[outputsFile] &&
    FileByteCount[traceFile] > 0 && FileByteCount[outputsFile] > 0;
  arguments = Join[
    {executable},
    If[reuse,
      {"load-trace", traceFile},
      Join[
        Flatten[{"trace-expression", #} & /@ outputFiles],
        {"optimize"},
        If[seriesAlias === None,
          {},
          {"to-series", seriesAlias, ToString[order]}
        ],
        {
          "finalize",
          "save-trace", traceFile,
          "list-outputs", "--to=" <> outputsFile
        }
      ]
    ],
    {
      "reconstruct",
      "--to=" <> recordFile,
      "--threads=" <> ToString[options["Threads"]],
      "--inmem"
    },
    If[TrueQ[options["FactorScan"]], {"--factor-scan"}, {}],
    If[TrueQ[options["ShiftScan"]], {"--shift-scan"}, {}]
  ];
  script = reconstructionJobScript[
    job, arguments, directory, logFile, recordFile, progressFile,
    doneFile, options["ProgressInterval"]
  ];
  Export[scriptFile, script, "String"];
  If[FileExistsQ[recordFile], DeleteFile[recordFile]];
  If[FileExistsQ[doneFile], DeleteFile[doneFile]];
  {seconds, result} = AbsoluteTiming @ Quiet @ Check[
    RunProcess[{"/bin/bash", scriptFile}],
    $Failed
  ];
  If[! AssociationQ[result] || Lookup[result, "ExitCode", 1] =!= 0,
    Message[ReconstructCoefficients::job, job["Name"],
      If[AssociationQ[result], Lookup[result, "ExitCode", 1], "no process"],
      logFile];
    Return[$Failed]
  ];
  If[! reconstructionJobDoneQ[recordFile],
    Message[ReconstructCoefficients::job, job["Name"],
      "no DONE marker was written", logFile];
    Return[$Failed]
  ];
  <|
    "Name" -> job["Name"],
    "Outputs" -> job["Outputs"],
    "Bytes" -> job["Bytes"],
    "TraceFile" -> traceFile,
    "TraceBytes" -> If[FileExistsQ[traceFile], FileByteCount[traceFile], 0],
    "RecordFile" -> recordFile,
    "RecordBytes" -> FileByteCount[recordFile],
    "LogFile" -> logFile,
    "ReusedTrace" -> reuse,
    "Seconds" -> seconds,
    "Statistics" -> If[
      FileExistsQ[doneFile],
      Quiet @ Check[Get[doneFile], <||>],
      <||>
    ]
  |>
];

reconstructionRunSchedule[
    jobs_List,
    traceData_Association,
    directory_String,
    executable_String,
    options_Association
  ] := Module[{records = {}, record, recordFile, traceFile, done},
  coefficientProgressStart["Reconstructing coefficient columns", Length[jobs]];
  Do[
    recordFile = reconstructionJobRecordFile[directory, jobs[[position]]];
    traceFile = reconstructionJobTraceFile[
      directory, jobs[[position]], options];
    done = TrueQ[options["Resume"]] && reconstructionJobDoneQ[recordFile];
    If[done,
      Print["  job ", jobs[[position]]["Name"], ": complete (",
        reconstructionTenth[FileByteCount[recordFile]/2.^20],
        " MB), kept"];
      AppendTo[
        records,
        <|
          "Name" -> jobs[[position]]["Name"],
          "Outputs" -> jobs[[position]]["Outputs"],
          "Bytes" -> jobs[[position]]["Bytes"],
          "TraceFile" -> traceFile,
          "TraceBytes" -> If[FileExistsQ[traceFile], FileByteCount[traceFile], 0],
          "RecordFile" -> recordFile,
          "RecordBytes" -> FileByteCount[recordFile],
          "LogFile" -> FileNameJoin[{
            directory, "Jobs", jobs[[position]]["Name"] <> ".log"}],
          "ReusedTrace" -> True,
          "Seconds" -> 0,
          "Statistics" -> Module[{file},
            file = FileNameJoin[{
              directory, "Jobs", jobs[[position]]["Name"] <> ".done"}];
            If[FileExistsQ[file], Quiet @ Check[Get[file], <||>], <||>]
          ]
        |>
      ],
      Print["  job ", jobs[[position]]["Name"], ": ",
        Length[jobs[[position]]["Outputs"]], " column(s), ",
        reconstructionTenth[jobs[[position]]["Bytes"]/2.^20], " MB"];
      record = reconstructionRunJob[
        jobs[[position]], traceData, directory, executable, options
      ];
      If[record === $Failed,
        reconstructionFail["column reconstruction", jobs[[position]]["Name"]]
      ];
      Print["    reconstructed in ",
        reconstructionTenth[record["Seconds"]], " s, ",
        reconstructionTenth[record["RecordBytes"]/2.^20], " MB, ",
        Lookup[record["Statistics"], "Probes", "?"], " probes"];
      AppendTo[records, record]
    ];
    coefficientProgressUpdate[position, Length[jobs]],
    {position, Length[jobs]}
  ];
  records
];

(* --- status -------------------------------------------------------- *)

reconstructionProgressSamples[file_String] := Module[{lines},
  lines = Quiet @ Check[
    Select[StringSplit[Import[file, "Text"], "\n"], # =!= "" &],
    {}
  ];
  DeleteCases[
    Map[
      Function[line,
        Module[{fields},
          fields = StringSplit[line];
          If[
            Length[fields] >= 2 &&
              StringMatchQ[fields[[1]], DigitCharacter ..] &&
              StringMatchQ[fields[[2]], DigitCharacter ..],
            <|
              "Time" -> ToExpression[fields[[1]]],
              "Probes" -> ToExpression[fields[[2]]],
              "Phase" -> If[Length[fields] >= 3, fields[[3]], "unknown"],
              "FirstPrimeProbes" -> If[
                Length[fields] >= 4 &&
                  StringMatchQ[fields[[4]], DigitCharacter ..],
                ToExpression[fields[[4]]],
                0
              ]
            |>,
            Nothing
          ]
        ]
      ],
      lines
    ],
    Nothing
  ]
];

ReconstructionStatus[directory_String] := Module[
  {
    root, workDirectories, files, labelOf, completed, completedIn,
    referenceFor, rows, records
  },
  root = ExpandFileName[directory];
  (* A full rational run works in the trace directory itself, a series
     run in one depth-specific subdirectory per depth; both are reported
     together, labelled by the directory when it is not the root. *)
  workDirectories = Select[
    Join[{root}, Select[FileNames["*", root], DirectoryQ]],
    DirectoryQ[FileNameJoin[{#, "progress"}]] &
  ];
  labelOf[work_String, name_String] := If[
    work === root,
    name,
    FileNameTake[work] <> "/" <> name
  ];
  files = Join @@ Map[
    Function[work,
      {work, #} & /@ Sort @ FileNames["*.progress", FileNameJoin[{work, "progress"}]]
    ],
    workDirectories
  ];
  If[files === {},
    Message[ReconstructionStatus::directory, root];
    Return[$Failed]
  ];
  completed = Association @ Flatten @ Map[
    Function[work,
      Map[
        Function[file,
          labelOf[work, FileBaseName[file]] -> Quiet @ Check[Get[file], <||>]
        ],
        FileNames["*.done", FileNameJoin[{work, "Jobs"}]]
      ]
    ],
    workDirectories
  ];
  (* An expected probe total is only honest once something comparable
     has finished: the same job in an earlier run, or - for a job still
     in its first prime - the total/first-prime ratio of a column that
     did complete.  A column of the same run is the closest comparison
     there is, so it is preferred over any other completed job. *)
  completedIn = GroupBy[
    Map[
      Function[work,
        work -> Map[
          Function[file, Quiet @ Check[Get[file], <||>]],
          FileNames["*.done", FileNameJoin[{work, "Jobs"}]]
        ]
      ],
      workDirectories
    ],
    First -> Last
  ];
  referenceFor[work_String] := SelectFirst[
    Join[
      Flatten[Lookup[completedIn, work, {}], 1],
      Values[completed]
    ],
    AssociationQ[#] && IntegerQ[Lookup[#, "FirstPrimeProbes", 0]] &&
      Lookup[#, "FirstPrimeProbes", 0] > 0 &
  ];
  records = Association @ Map[
    Function[entry,
      Module[
        {work, file, job, samples, last, window, rate, expected,
         remaining, statistics, reference},
        {work, file} = entry;
        reference = referenceFor[work];
        job = labelOf[work, FileBaseName[file]];
        samples = reconstructionProgressSamples[file];
        statistics = Lookup[completed, job, <||>];
        last = If[samples === {}, <||>, Last[samples]];
        window = Take[samples, -Min[Length[samples], 10]];
        rate = If[
          Length[window] >= 2 &&
            Last[window]["Time"] > First[window]["Time"],
          (Last[window]["Probes"] - First[window]["Probes"])/
            (Last[window]["Time"] - First[window]["Time"]),
          Indeterminate
        ];
        expected = Which[
          AssociationQ[statistics] && IntegerQ[Lookup[statistics, "Probes", None]],
            statistics["Probes"],
          AssociationQ[reference] && AssociationQ[last] &&
            Lookup[last, "FirstPrimeProbes", 0] > 0,
            Round[
              last["FirstPrimeProbes"] reference["Probes"]/
                reference["FirstPrimeProbes"]
            ],
          True, Indeterminate
        ];
        remaining = If[
          IntegerQ[expected] && NumericQ[rate] && rate > 0 &&
            AssociationQ[last] && expected > last["Probes"],
          (expected - last["Probes"])/rate,
          Indeterminate
        ];
        job -> <|
          "Phase" -> Lookup[last, "Phase", "unknown"],
          "Probes" -> Lookup[last, "Probes", 0],
          "ProbeRate" -> rate,
          "ExpectedProbes" -> expected,
          "RemainingSeconds" -> remaining,
          "Complete" -> KeyExistsQ[completed, job],
          (* The job stamps its samples with the Unix epoch. *)
          "UpdatedSecondsAgo" -> If[
            AssociationQ[last] && IntegerQ[Lookup[last, "Time", None]],
            Round[UnixTime[] - last["Time"]],
            Indeterminate
          ],
          "Statistics" -> statistics
        |>
      ]
    ],
    files
  ];
  rows = KeyValueMap[
    Function[{job, data},
      {
        job,
        If[TrueQ[data["Complete"]], "done", data["Phase"]],
        data["Probes"],
        If[NumericQ[data["ProbeRate"]],
          ToString[reconstructionTenth[data["ProbeRate"]]] <> "/s",
          "-"],
        If[IntegerQ[data["ExpectedProbes"]], data["ExpectedProbes"], "-"],
        If[NumericQ[data["RemainingSeconds"]],
          coefficientFormatDuration[data["RemainingSeconds"]],
          "-"],
        If[IntegerQ[data["UpdatedSecondsAgo"]],
          ToString[data["UpdatedSecondsAgo"]] <> " s ago",
          "-"]
      }
    ],
    records
  ];
  Print @ Grid[
    Prepend[
      rows,
      {"Job", "Phase", "Probes", "Rate", "Expected", "ETA", "Updated"}
    ],
    Frame -> All
  ];
  records
];

(* --- inputs behind the trace --------------------------------------- *)

(* Everything the production assembly needs is reachable from the trace
   directory: the Kira store beside it names the artifact, the artifact
   names the result folder, and the result folder names the project
   whose card supplies the late setup keys.  The stored ghost pairs
   still carry LaurentValuation -> Automatic, so that last step is not
   optional. *)
reconstructionInputs[traceDirectory_String, options_Association] := Catch[
  Module[
    {
      workDirectory, store, storeManifest, metadata, kiraFile,
      resultDirectory, projectDirectory, cardFile, card, pairFiles,
      data, resultSetup, processSetup, process, currentContext,
      context, physicalFactor, record, traceData
    },
    record = reconstructionTraceRecord[traceDirectory];
    If[record === $Failed,
      Message[ReconstructCoefficients::trace, traceDirectory,
        "no readable TraceManifest.wxf"];
      Throw[$Failed, $reconstructionFailure]
    ];
    traceData = record["TraceData"];
    workDirectory = ParentDirectory[ExpandFileName[traceDirectory]];
    store = FileNameJoin[{workDirectory, "KiraStore"}];
    storeManifest = If[
      FileExistsQ[coefficientStoreManifestFile[store]],
      Quiet @ Check[Get[coefficientStoreManifestFile[store]], $Failed],
      $Failed
    ];
    metadata = If[
      FileExistsQ[coefficientStoreMetadataFile[store]],
      Quiet @ Check[
        coefficientReadRecord[coefficientStoreMetadataFile[store]], $Failed],
      $Failed
    ];
    If[! AssociationQ[storeManifest] || ! AssociationQ[metadata],
      Message[ReconstructCoefficients::trace, traceDirectory,
        "no indexed Kira store beside the trace"];
      Throw[$Failed, $reconstructionFailure]
    ];
    kiraFile = storeManifest["KiraFile"];
    resultDirectory = DirectoryName[kiraFile];
    projectDirectory = ParentDirectory[ParentDirectory[resultDirectory]];
    pairFiles = SortBy[
      FileNames["F*_C*.wl", FileNameJoin[{resultDirectory, "Pairs"}]],
      coefficientPairFileKey
    ];
    If[pairFiles === {} || ! FileExistsQ[kiraFile],
      Message[ReconstructCoefficients::trace, traceDirectory,
        "the pair files or KiraResult.wl behind the trace are missing"];
      Throw[$Failed, $reconstructionFailure]
    ];
    card = Switch[options["CoefficientSetup"],
      _Association, options["CoefficientSetup"],
      _String, Quiet @ Check[Get[options["CoefficientSetup"]], $Failed],
      _,
        cardFile = FileNameJoin[{
          projectDirectory, "Cards", metadata["CardName"] <> ".wl"}];
        If[FileExistsQ[cardFile],
          Quiet @ Check[Get[cardFile], $Failed],
          Missing["NoCard"]
        ]
    ];
    data = Block[
      {analyticContextQ = coefficientAnalyticContextQ},
      ibpInputData[pairFiles, False]
    ];
    If[
      data["CardName"] =!= metadata["CardName"] ||
        ! coefficientSameInputsQ[data, metadata],
      Message[ReconstructCoefficients::trace, traceDirectory,
        "the Kira artifact belongs to another diagram set"];
      Throw[$Failed, $reconstructionFailure]
    ];
    resultSetup = If[
      AssociationQ[card],
      Join[data["Setup"], KeyTake[card, $coefficientLateSetupKeys]],
      data["Setup"]
    ];
    processSetup = Join[
      resultSetup,
      <|
        "ForwardAmplitudes" -> Append[
          resultSetup["ForwardAmplitudes"],
          "SelectedIndex" -> First[data["Pairs"]]["Forward"]
        ],
        "ConjugateAmplitudes" -> Append[
          resultSetup["ConjugateAmplitudes"],
          "SelectedIndex" -> First[data["Pairs"]]["Conjugate"]
        ]
      |>
    ];
    process = Catch[normalizeProcess[processSetup], $collinearFailure];
    currentContext = If[
      AssociationQ[process],
      analyticContext[process],
      $Failed
    ];
    context = BuildSimplificationContext[resultSetup];
    If[currentContext === $Failed || context === $Failed,
      Message[ReconstructCoefficients::trace, traceDirectory,
        "the card does not define a valid analytic context"];
      Throw[$Failed, $reconstructionFailure]
    ];
    physicalFactor = finiteFieldPhysicalFactor[context];
    If[physicalFactor === $Failed,
      Message[ReconstructCoefficients::trace, traceDirectory,
        "the card declares no distribution factor and Laurent valuation"];
      Throw[$Failed, $reconstructionFailure]
    ];
    <|
      "TraceDirectory" -> ExpandFileName[traceDirectory],
      "TraceData" -> traceData,
      "TraceRecord" -> record,
      "Metadata" -> metadata,
      "KiraFile" -> kiraFile,
      "Context" -> context,
      "PhysicalFactor" -> physicalFactor,
      "Card" -> card,
      "Data" -> Join[
        data,
        <|"Setup" -> resultSetup, "AnalyticContext" -> currentContext|>
      ]
    |>
  ],
  $reconstructionFailure
];

(* --- assembly ------------------------------------------------------ *)

reconstructionOrderExpressions[
    columns_Association,
    outputCount_Integer,
    order_
  ] := Table[
  Which[
    ! KeyExistsQ[columns, output], 0,
    order === None, columns[output],
    True, Lookup[columns[output], order, 0]
  ],
  {output, outputCount}
];

(* finiteFieldAssembleResult drops a master whose reconstructed column
   vanishes with

     Function[{master, position}, Module[..., If[..., Return[Nothing]], ...]]

   and Return is not caught inside a Module inside an anonymous Function
   (verified: the list keeps a literal Return[Nothing]).  Nothing ever
   vanished, so the entry survives as Return[Nothing] and poisons both
   the assembled Expression and the momentum, fraction and cut checks
   that read the master list.  A full rational run never noticed - no
   NLO or ghost column is exactly zero - but in series mode whole orders
   of a column vanish routinely.

   The repair is done here rather than in Simplification.wl: the leaked
   entries are dropped, the intended zero-coefficient masters with them,
   the assembled expression is rebuilt from the surviving masters, and
   every certification the leak invalidated is run again. *)
reconstructionRepairAssembly[
    result_Association,
    data_Association,
    metadata_Association,
    context_Association
  ] := Module[
  {
    masters, coefficients, remainder, reconstructed, forbiddenMomenta,
    remainingMomenta, rootSubstitutions, remainingFractionObjects, cutCheck
  },
  masters = Select[
    result["Masters"],
    AssociationQ[#] && ! TrueQ[#["Coefficient"] === 0] &
  ];
  remainder = result["Remainder"];
  coefficients = #["Coefficient"] & /@ masters;
  reconstructed = result["PreFactor"] (
    Total[#["Coefficient"] #["Master"] & /@ masters] + remainder
  );
  forbiddenMomenta = coefficientForbiddenMomenta[data["Setup"]];
  remainingMomenta = remainingDeclaredMomenta[
    {coefficients, remainder},
    forbiddenMomenta
  ];
  rootSubstitutions = Lookup[context, "RootSubstitutions", <||>];
  remainingFractionObjects = Select[
    Join[
      context["FractionVariables"],
      context["FractionRootVariables"],
      If[
        AssociationQ[rootSubstitutions],
        #["Root"] & /@ Values[rootSubstitutions],
        {}
      ]
    ],
    ! FreeQ[{coefficients, remainder}, #] &
  ];
  cutCheck = validateCutGLIs[
    #["Master"] & /@ masters,
    metadata["Topologies"]
  ];
  If[
    remainingMomenta =!= {} || remainingFractionObjects =!= {} ||
      ! FreeQ[reconstructed, System`D] || cutCheck =!= True,
    Return[$Failed]
  ];
  Join[
    result,
    <|"Masters" -> masters, "Expression" -> reconstructed|>
  ]
];

(* The production tail is finiteFieldAssembleResult itself: the root,
   momentum, distribution and cut certifications, the master records and
   the whole CoefficientResult header live there and are not worth
   duplicating.  In series mode it runs once per order - each order is a
   genuine rational column - and the per-order results are merged into
   the series storage form afterwards. *)
reconstructionMergeOrders[
    perOrder_Association,
    masterOrder_List,
    variable_,
    truncation_Integer
  ] := Module[
  {orders, skeleton, keyOf, byKey, masterKeys, masters, remainder,
   expression, orderSet},
  orders = Sort[Keys[perOrder]];
  skeleton = perOrder[Last[orders]];
  keyOf[entry_] := ToString[entry["Master"], InputForm];
  byKey = AssociationMap[
    Function[order,
      Association[keyOf[#] -> # & /@ perOrder[order]["Masters"]]
    ],
    orders
  ];
  (* A master drops out of an order whose coefficient vanishes, so the
     union over the orders is the master set and the trace order is what
     puts it back in a stable sequence. *)
  masterKeys = Select[
    masterOrder,
    Function[key, AnyTrue[Values[byKey], KeyExistsQ[#, key] &]]
  ];
  orderSet[values_Association] := Module[{present},
    present = Select[values, ! TrueQ[# === 0] &];
    If[
      present === <||>,
      <||>,
      KeyTake[values, Range[Min[Keys[present]], truncation]]
    ]
  ];
  masters = Map[
    Function[key,
      Module[{entry, values},
        entry = SelectFirst[
          Map[Lookup[#, key, Missing["Absent"]] &, Values[byKey]],
          AssociationQ
        ];
        values = orderSet @ AssociationMap[
          Function[order,
            Lookup[
              Lookup[byKey[order], key, <|"Coefficient" -> 0|>],
              "Coefficient",
              0
            ]
          ],
          orders
        ];
        If[
          values === <||>,
          Nothing,
          Append[
            entry,
            "Coefficient" -> reconstructionSeriesFromOrders[variable, values]
          ]
        ]
      ]
    ],
    masterKeys
  ];
  remainder = reconstructionSeriesFromOrders[
    variable,
    orderSet @ AssociationMap[perOrder[#]["Remainder"] &, orders]
  ];
  expression = reconstructionSeriesFromOrders[
    variable,
    orderSet @ AssociationMap[perOrder[#]["Expression"] &, orders]
  ];
  Join[
    skeleton,
    <|
      "Masters" -> masters,
      "Remainder" -> remainder,
      "Expression" -> expression,
      "SeriesVariable" -> variable,
      "SeriesTruncation" -> truncation
    |>
  ]
];

reconstructionAssembleProduction[
    inputs_Association,
    collected_Association,
    jobs_List,
    executable_String,
    options_Association
  ] := Catch[
  Module[
    {
      traceData, columns, outputCount, missing, orders, truncation,
      trace, reconstruction, perOrder, result, variable, primary,
      reconstructionData
    },
    traceData = inputs["TraceData"];
    columns = collected["Columns"];
    outputCount = collected["OutputCount"];
    missing = Complement[Range[outputCount], Keys[columns]];
    If[missing =!= {},
      Message[ReconstructCoefficients::coverage,
        ToString[Length[missing]] <> " of " <> ToString[outputCount] <>
          " outputs are absent, first " <>
          ToString[Take[missing, UpTo[5]]]];
      reconstructionFail["result assembly", "incomplete output coverage"]
    ];
    variable = collected["SeriesVariable"];
    orders = If[
      variable === None,
      {None},
      Sort @ DeleteDuplicates[Join @@ (Keys /@ Values[columns])]
    ];
    truncation = If[variable === None, None, Max[orders]];
    If[
      variable =!= None && truncation =!= options["SeriesOrder"],
      Message[ReconstructCoefficients::coverage,
        "the result files stop at order " <> ToString[truncation] <>
          " but order " <> ToString[options["SeriesOrder"]] <> " was requested"];
      reconstructionFail["result assembly", "a truncation mismatch"]
    ];
    primary = Last @ SortBy[jobs, Lookup[#, "RecordBytes", 0] &];
    trace = <|
      "TraceFile" -> Lookup[primary, "TraceFile", Missing["Resumed"]],
      "TraceBytes" -> Total[Map[Lookup[#, "TraceBytes", 0] &, jobs]],
      "BuildSeconds" -> 0
    |>;
    perOrder = AssociationMap[
      Function[order,
        reconstruction = <|
          "Expressions" -> reconstructionOrderExpressions[
            columns, outputCount, order],
          "ResultFile" -> primary["RecordFile"],
          "ReconstructionSeconds" -> Total[
            Map[Lookup[#, "Seconds", 0] &, jobs]],
          "ResultBytes" -> Total[Map[Lookup[#, "RecordBytes", 0] &, jobs]]
        |>;
        (* Lookup::invrl is the leak documented at
           reconstructionRepairAssembly, which repairs and re-certifies
           what it damaged; nothing else is silenced. *)
        result = Quiet[
          finiteFieldAssembleResult[
            inputs["Data"],
            inputs["Metadata"],
            inputs["KiraFile"],
            inputs["Context"],
            traceData,
            trace,
            reconstruction,
            executable,
            options["Threads"]
          ],
          {Lookup::invrl}
        ];
        result = If[
          result === $Failed,
          $Failed,
          reconstructionRepairAssembly[
            result, inputs["Data"], inputs["Metadata"], inputs["Context"]
          ]
        ];
        If[result === $Failed,
          reconstructionFail[
            "result assembly",
            "the reconstructed coefficients violate the declared " <>
              "kinematics or cut data" <>
              If[order === None, "", " at order " <> ToString[order]]
          ]
        ];
        result
      ],
      orders
    ];
    result = If[
      variable === None,
      perOrder[None],
      reconstructionMergeOrders[
        perOrder,
        ToString[#, InputForm] & /@ traceData["Masters"],
        variable,
        truncation
      ]
    ];
    reconstructionData = Join[
      result["FiniteFieldReconstruction"],
      <|
        "Method" -> "ScheduledColumnJobs",
        "SeriesVariable" -> variable,
        "SeriesTruncation" -> truncation,
        "Schedule" -> Map[
          KeyTake[#, {"Name", "Outputs", "Bytes", "RecordBytes", "Seconds",
            "ReusedTrace", "Statistics"}] &,
          jobs
        ],
        "JobCount" -> Length[jobs],
        "ResultFiles" -> Map[Lookup[#, "RecordFile", Missing["None"]] &, jobs],
        "ResultFileHashes" -> Map[
          Function[job,
            With[{file = Lookup[job, "RecordFile", None]},
              If[StringQ[file] && FileExistsQ[file],
                FileHash[file, "SHA256", "HexString"],
                Missing["None"]
              ]
            ]
          ],
          jobs
        ],
        "TraceFiles" -> Map[Lookup[#, "TraceFile", Missing["None"]] &, jobs],
        "ReconstructionSeconds" -> Total[Map[Lookup[#, "Seconds", 0] &, jobs]],
        "ParseSeconds" -> collected["ParseSeconds"],
        "BlockCount" -> collected["BlockCount"],
        "Threads" -> options["Threads"]
      |>
    ];
    Join[
      result,
      <|
        "FiniteFieldReconstruction" -> reconstructionData,
        "SeriesVariable" -> variable,
        "SeriesTruncation" -> truncation
      |>
    ]
  ],
  $reconstructionFailure
];

(* The intermediate artifact: what the assembly CLI has always written.
   It stops short of the production result on purpose - a partial result
   set has no complete column set and cannot carry the root-freedom and
   cut certifications - and it is the input of the slice check. *)
reconstructionColumnArtifact[
    traceData_Association,
    traceDirectory_String,
    collected_Association,
    manifestFile_,
    resultFiles_List
  ] := Module[
  {variable, outputsByMaster, masterColumn, coefficients, remainder},
  variable = collected["SeriesVariable"];
  outputsByMaster = GroupBy[
    Range[Length[traceData["OutputFiles"]]],
    traceData["OutputMetadata"][[#]]["MasterIndex"] &
  ];
  (* coefficient(master i) = sum over the outputs of master i of the
     analytic signature times the reconstructed column.  The remainder
     carries MasterIndex 0 and is reported separately. *)
  masterColumn[master_Integer] := Module[{terms},
    terms = Map[
      Function[output,
        Module[{signature, value},
          signature = ReleaseHold[
            traceData["Signatures"][
              traceData["OutputMetadata"][[output]]["SignatureIndex"]]
          ];
          value = collected["Columns"][output];
          If[variable === None, signature value, signature # & /@ value]
        ]
      ],
      Lookup[outputsByMaster, master, {}]
    ];
    If[
      variable === None,
      Total[terms],
      reconstructionSeriesFromOrders[variable, Merge[terms, Total]]
    ]
  ];
  coefficients = Association @ Map[
    traceData["Masters"][[#]] -> masterColumn[#] &,
    collected["Covered"]
  ];
  remainder = Which[
    ! KeyExistsQ[outputsByMaster, 0], 0,
    AllTrue[outputsByMaster[0], KeyExistsQ[collected["Columns"], #] &],
      masterColumn[0],
    True, Missing["Incomplete"]
  ];
  <|
    "Format" -> $reconstructionArtifactFormat,
    "FormatVersion" -> $reconstructionArtifactVersion,
    "Masters" -> traceData["Masters"],
    "Coefficients" -> coefficients,
    "Covered" -> collected["Covered"],
    "Partial" -> collected["Partial"],
    "Missing" -> collected["Missing"],
    "ManifestFile" -> manifestFile,
    "TraceDirectory" -> traceDirectory,
    "ResultFiles" -> resultFiles,
    "OutputsParsed" -> collected["ParsedOutputs"],
    "OutputCount" -> collected["OutputCount"],
    "Remainder" -> remainder,
    "SeriesVariable" -> variable,
    "SeriesTruncation" -> If[
      variable === None || collected["Columns"] === <||>,
      None,
      Max[Join @@ (Keys /@ Values[collected["Columns"]])]
    ],
    "PhysicalFactor" -> traceData["PhysicalFactor"],
    "CompleteTargetSet" -> traceData["CompleteTargetSet"]
  |>
];

reconstructionAssembledArtifact[
    directory_String,
    traceDirectory_,
    seriesVariable_: None
  ] := Catch[
  Module[
    {
      resultFiles, markers, manifest, traceDirectoryUsed, traceData,
      collected, variable
    },
    resultFiles = reconstructionResultFiles[directory];
    If[resultFiles === {},
      Message[ReconstructCoefficients::parse, directory,
        "no rec_*.txt result files"];
      Throw[$Failed, $reconstructionFailure]
    ];
    Print["Result files: ", Length[resultFiles]];
    markers = Join @@ Map[
      Function[file,
        Module[{seconds, found},
          {seconds, found} = AbsoluteTiming[reconstructionScanMarkers[file]];
          If[found === $Failed,
            Message[ReconstructCoefficients::parse, FileNameTake[file],
              "the file could not be read"];
            Throw[$Failed, $reconstructionFailure]
          ];
          Print["  ", FileNameTake[file], ": ", Length[found], " blocks, ",
            reconstructionTenth[FileByteCount[file]/2.^20], " MB, scanned in ",
            reconstructionTenth[seconds], " s"];
          found
        ]
      ],
      resultFiles
    ];
    If[markers === {},
      Message[ReconstructCoefficients::parse, directory,
        "no '<path> =' blocks in the result files"];
      Throw[$Failed, $reconstructionFailure]
    ];
    manifest = reconstructionSelectManifest[directory, traceDirectory, markers];
    If[manifest === $Failed,
      Message[ReconstructCoefficients::parse, directory,
        "no trace manifest accounts for every result block"];
      Throw[$Failed, $reconstructionFailure]
    ];
    Print["Manifest: ", manifest["File"]];
    traceDirectoryUsed = manifest["Directory"];
    traceData = manifest["Record"]["TraceData"];
    (* The marker form itself says whether this is a series run, so the
       caller need not know. *)
    variable = Which[
      seriesVariable =!= None, seriesVariable,
      AnyTrue[markers, #["Order"] =!= None &],
        Lookup[
          AssociationThread[
            SymbolName /@ Values[traceData["SymbolRules"]],
            Keys[traceData["SymbolRules"]]
          ],
          SelectFirst[markers, #["Order"] =!= None &]["Alias"],
          None
        ],
      True, None
    ];
    Print["Outputs in the trace: ", Length[traceData["OutputFiles"]],
      "; masters: ", Length[traceData["Masters"]],
      "; result blocks: ", Length[markers]];
    collected = reconstructionCollectResults[
      directory, traceDirectoryUsed, traceData, variable, resultFiles
    ];
    If[collected === $Failed, Throw[$Failed, $reconstructionFailure]];
    reconstructionColumnArtifact[
      traceData, traceDirectoryUsed, collected, manifest["File"], resultFiles
    ]
  ],
  $reconstructionFailure
];

(* --- univariate slice verification --------------------------------- *)

(* Comparing two multivariate rational functions directly is out of
   reach (the trace inputs run to tens of MB of plus-concatenated
   contributions), but a slice is cheap: fix every variable but one to a
   random rational and both sides become univariate rational functions
   that must agree exactly.  A wrong identity survives a random rational
   point with probability zero in exact arithmetic.

   The original input is substituted TEXTUALLY, before the file is
   parsed, so the giant symbolic expression is never built. *)

(* Small denominators keep the univariate arithmetic cheap; values in
   (0,1) stay inside the physical range of the dimensionless x and y and
   are harmless for the colour and Epsilon slots. *)
reconstructionRandomRational[] := Module[{denominator},
  denominator = RandomInteger[{2, 49}];
  RandomInteger[{1, denominator - 1}]/denominator
];

reconstructionSliceValue[file_String, rules_List] := Module[{text},
  text = ReadString[file];
  If[! StringQ[text], Return[$Failed]];
  ToExpression[StringReplace[text, rules], InputForm]
];

reconstructionVerifySlice[
    position_Integer,
    variables_List,
    aliasNames_List,
    expressionFiles_List,
    weights_List,
    reconstruction_
  ] := Module[
  {sliceSymbol, values, textRules, expressionRules, original,
   substituted, difference, seconds, indices},
  indices = DeleteCases[Range[Length[variables]], position];
  sliceSymbol = ToExpression[aliasNames[[position]]];
  values = Table[
    If[index === position, sliceSymbol, reconstructionRandomRational[]],
    {index, Length[variables]}
  ];
  Print["    fixed: ",
    InputForm[
      Association @ Table[variables[[index]] -> values[[index]], {index, indices}]
    ]
  ];
  (* Longest alias first: the alias names share a prefix, so a shorter
     one must never be matched inside a longer one. *)
  textRules = SortBy[
    Table[
      aliasNames[[index]] ->
        "(" <> ToString[values[[index]], InputForm] <> ")",
      {index, indices}
    ],
    -StringLength[First[#]] &
  ];
  expressionRules = Table[
    variables[[index]] -> values[[index]],
    {index, Length[variables]}
  ];
  {seconds, original} = AbsoluteTiming[
    Quiet[
      Module[{parsed},
        parsed = reconstructionSliceValue[#, textRules] & /@ expressionFiles;
        If[
          MemberQ[parsed, $Failed],
          $Failed,
          (* The weights are substituted like everything else.  Leaving
             them symbolic - as Scripts/verify_reconstruction_slice.wls
             did - compares a symbolic signature against the substituted
             one on the reconstruction side, and every master whose
             outputs do not all share one signature then "fails" by the
             leftover factor (2^(2 Epsilon) Pi^(3 + Epsilon) - its own
             value); measured on NLO master 1. *)
          Total[(weights /. expressionRules) parsed]
        ]
      ],
      {Power::infy, Infinity::indet, General::stop}
    ]
  ];
  If[original === $Failed,
    Print["    FAIL - an expression file could not be substituted"];
    Return[False]
  ];
  Print["    original slice built in ", reconstructionTenth[seconds],
    " s (LeafCount ", LeafCount[original], ")"];
  {seconds, substituted} = AbsoluteTiming[
    Quiet[
      reconstruction /. expressionRules,
      {Power::infy, Infinity::indet, General::stop}
    ]
  ];
  Print["    reconstruction slice built in ", reconstructionTenth[seconds],
    " s (LeafCount ", LeafCount[substituted], ")"];
  (* The denominators carry poles at small rationals, so a point drawn
     with denominators under 50 lands on one often enough to matter
     (measured: one draw in five).  Such a draw is not evidence either
     way - redraw it rather than call it a failure. *)
  If[! FreeQ[{original, substituted},
      DirectedInfinity | Indeterminate | ComplexInfinity],
    Print["    the draw hit a vanishing denominator - redrawing"];
    Return[$Degenerate]
  ];
  If[! FreeQ[substituted, Alternatives @@ variables],
    Print["    FAIL - the reconstruction still carries a trace variable"];
    Return[False]
  ];
  If[TrueQ[Together[original] === 0],
    Print["    WARNING - the original slice is identically zero"]
  ];
  {seconds, difference} = AbsoluteTiming[Together[original - substituted]];
  Print["    compared in ", reconstructionTenth[seconds], " s"];
  If[difference === 0,
    Print["    PASS"];
    True,
    Print["    FAIL - the difference is not zero (LeafCount ",
      LeafCount[difference], ")"];
    False
  ]
];

$reconstructionSliceAttempts = 8;

reconstructionVerifySlices[
    artifact_Association,
    masterIndex_Integer,
    count_Integer
  ] := Module[
  {
    masters, master, coefficient, record, traceDirectory, traceData,
    outputMetadata, symbolRules, variables, aliasNames, outputs,
    expressionFiles, signatures, commonSignature, weights,
    reconstruction, rotation, results
  },
  masters = artifact["Masters"];
  If[masterIndex < 1 || masterIndex > Length[masters],
    Print["Master index out of range: ", masterIndex, " of ", Length[masters]];
    Return[$Failed]
  ];
  master = masters[[masterIndex]];
  If[! MemberQ[artifact["Covered"], masterIndex],
    Print["Master ", masterIndex, " is not covered by the assembly"];
    Return[$Failed]
  ];
  coefficient = Lookup[artifact["Coefficients"], Key[master], Missing["NotFound"]];
  If[MissingQ[coefficient],
    Print["No assembled coefficient for master ", masterIndex];
    Return[$Failed]
  ];
  (* A version-1 artifact records only the manifest file. *)
  traceDirectory = Lookup[
    artifact,
    "TraceDirectory",
    FileNameJoin[FileNameSplit[DirectoryName[artifact["ManifestFile"]]]]
  ];
  record = reconstructionTraceRecord[traceDirectory];
  If[record === $Failed,
    Print["The artifact does not point at a readable trace manifest"];
    Return[$Failed]
  ];
  traceData = record["TraceData"];
  outputMetadata = traceData["OutputMetadata"];
  symbolRules = traceData["SymbolRules"];
  variables = Keys[symbolRules];
  aliasNames = SymbolName /@ Values[symbolRules];
  outputs = Select[
    Range[Length[outputMetadata]],
    outputMetadata[[#]]["MasterIndex"] === masterIndex &
  ];
  If[outputs === {},
    Print["Master ", masterIndex, " has no trace output; its coefficient ",
      "is zero by construction and there is nothing to slice"];
    Return[$Failed]
  ];
  expressionFiles = Map[
    reconstructionAbsolutePath[traceDirectory, #] &,
    traceData["OutputFiles"][[outputs]]
  ];
  If[! AllTrue[expressionFiles, FileExistsQ],
    Print["Missing trace expression file(s): ",
      Select[expressionFiles, ! FileExistsQ[#] &]];
    Return[$Failed]
  ];
  signatures = Map[
    ReleaseHold[traceData["Signatures"][outputMetadata[[#]]["SignatureIndex"]]] &,
    outputs
  ];
  (* The expression files hold the rational part only; the analytic
     signature is the weight the assembly multiplies them by.  Dividing
     both sides by one of the signatures leaves honest rational
     functions whenever the signatures of a master differ by a rational
     factor - which is the usual case, because the canonicalizer keeps
     the declared scale and the coupling out of the coefficient and so
     splits one analytic class into several buckets (the NLO columns
     differ by -1 and by s^2).  That is what makes the exact Together
     comparison meaningful even for an Epsilon slice, where the
     signature itself (2^(4 Epsilon) ...) is not rational. *)
  commonSignature = First[signatures];
  weights = Cancel[Together[#/commonSignature]] & /@ signatures;
  reconstruction = reconstructionSeriesNormal[coefficient]/commonSignature;
  Print["Master ", masterIndex, ": ", InputForm[master]];
  Print["  outputs: ", Length[outputs]];
  Scan[
    Print["    ", FileNameTake[expressionFiles[[#]]], " (",
      reconstructionTenth[FileByteCount[expressionFiles[[#]]]/2.^10],
      " KB), weight ", InputForm[weights[[#]]]] &,
    Range[Length[outputs]]
  ];
  If[commonSignature =!= 1,
    Print["  common signature divided out: ", InputForm[commonSignature]]
  ];
  Print["  variables: ", InputForm[variables]];
  If[reconstructionSeriesQ[coefficient],
    Print["  NOTE: a truncated series column - a slice can only agree ",
      "with the original up to the truncation"]
  ];
  (* The kinematic variables come first, so the default three slices
     exercise them before the colour factors. *)
  rotation = Reverse[Range[Length[variables]]];
  SeedRandom[masterIndex];
  Print["  slices: ", count, " (random seed ", masterIndex, ")"];
  results = Table[
    Module[{position, outcome},
      position = rotation[[Mod[step - 1, Length[rotation]] + 1]];
      Print["  slice ", step, ": ", InputForm[variables[[position]]], " free"];
      Do[
        outcome = reconstructionVerifySlice[
          position, variables, aliasNames, expressionFiles, weights,
          reconstruction
        ];
        If[outcome =!= $Degenerate, Return[outcome, Module]],
        {$reconstructionSliceAttempts}
      ];
      Print["    FAIL - every draw hit a vanishing denominator"];
      False
    ],
    {step, count}
  ];
  <|
    "MasterIndex" -> masterIndex,
    "Slices" -> count,
    "Agreed" -> Count[results, True],
    "Verified" -> AllTrue[results, TrueQ]
  |>
];

(* An independent, shallower series run must reproduce the production
   orders exactly: two FireFly runs at different depths share no random
   state, so agreement order by order is a real check on the truncated
   columns rather than a repetition of the same arithmetic. *)
reconstructionVerifySeriesOrders[
    inputs_Association,
    collected_Association,
    jobs_List,
    executable_String,
    options_Association,
    depth_Integer
  ] := Module[
  {directory, traceData, solo, checkOptions, results},
  traceData = inputs["TraceData"];
  directory = FileNameJoin[{inputs["TraceDirectory"], "Verify"}];
  If[! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]
  ];
  solo = Select[jobs, Length[#["Outputs"]] === 1 &];
  If[solo === {},
    Print["  no isolated column to verify at a shallower depth"];
    Return[<|"Verified" -> True, "Columns" -> 0|>]
  ];
  checkOptions = Join[options, <|"SeriesOrder" -> depth|>];
  results = Map[
    Function[job,
      Module[{record, shallowCollected, output, production, shallow, check},
        record = reconstructionRunJob[
          Append[job, "Name" -> job["Name"] <> "_verify" <> ToString[depth]],
          traceData, directory, executable, checkOptions
        ];
        shallowCollected = If[
          record === $Failed,
          $Failed,
          reconstructionCollectResults[
            directory, inputs["TraceDirectory"], traceData,
            options["SeriesVariable"], {record["RecordFile"]}
          ]
        ];
        If[
          shallowCollected === $Failed,
          False,
          output = First[job["Outputs"]];
          production = collected["Columns"][output];
          shallow = shallowCollected["Columns"][output];
          check = AllTrue[
            Keys[shallow],
            TrueQ @ exactZeroQ[
              shallow[#] - Lookup[production, #, Missing["Absent"]]
            ] &
          ];
          Print["  column ", output, " at order ", depth, ": ",
            If[check, "agrees", "DISAGREES"], " on ", Length[shallow],
            " orders"];
          check
        ]
      ]
    ],
    solo
  ];
  <|"Verified" -> AllTrue[results, TrueQ], "Columns" -> Length[solo]|>
];

(* --- the public stage ---------------------------------------------- *)

ReconstructCoefficients[traceDirectory_String, OptionsPattern[]] := Catch[
  Module[
    {
      directory, workDirectory, options, inputs, traceData, executable,
      threads, variable, order, jobs, records, collected, result,
      resultFile, slices, seriesCheck, started
    },
    started = AbsoluteTime[];
    directory = ExpandFileName[traceDirectory];
    If[! DirectoryQ[directory],
      Message[ReconstructCoefficients::trace, traceDirectory,
        "no such directory"];
      Return[$Failed]
    ];
    executable = finiteFieldResolveExecutable[
      OptionValue["RatracerExecutable"]
    ];
    If[executable === $Failed,
      Message[ReconstructCoefficients::option, "RatracerExecutable",
        "set FACET_RATRACER or install the executable under Addon/Other_Addon/Ratracer/bin"];
      Return[$Failed]
    ];
    threads = finiteFieldThreadCount[OptionValue["Threads"]];
    If[threads === $Failed,
      Message[ReconstructCoefficients::option, "Threads",
        OptionValue["Threads"]];
      Return[$Failed]
    ];
    order = OptionValue["SeriesOrder"];
    variable = Switch[OptionValue["SeriesVariable"],
      None, None,
      Automatic, $feynFacetEpsilon,
      _Symbol, OptionValue["SeriesVariable"],
      _, $Failed
    ];
    If[
      variable === $Failed ||
        (variable =!= None && ! IntegerQ[order]),
      Message[ReconstructCoefficients::option, "SeriesVariable",
        OptionValue["SeriesVariable"]];
      Return[$Failed]
    ];
    If[
      ! (IntegerQ[OptionValue["BundleBelowBytes"]] &&
        OptionValue["BundleBelowBytes"] > 0),
      Message[ReconstructCoefficients::option, "BundleBelowBytes",
        OptionValue["BundleBelowBytes"]];
      Return[$Failed]
    ];
    coefficientProgressStart["Reading the trace manifest", 1];
    inputs = reconstructionInputs[
      directory,
      <|"CoefficientSetup" -> OptionValue["CoefficientSetup"]|>
    ];
    If[inputs === $Failed, Return[$Failed]];
    traceData = inputs["TraceData"];
    If[variable =!= None && reconstructionSeriesAlias[traceData, variable] === $Failed,
      Message[ReconstructCoefficients::option, "SeriesVariable",
        ToString[variable] <> " is not a trace variable"];
      Return[$Failed]
    ];
    options = <|
      "SeriesVariable" -> variable,
      "SeriesOrder" -> order,
      "Threads" -> threads,
      "Resume" -> TrueQ[OptionValue["Resume"]],
      "FactorScan" -> OptionValue["FactorScan"],
      "ShiftScan" -> OptionValue["ShiftScan"],
      "ProgressInterval" -> Max[1, OptionValue["ProgressInterval"]]
    |>;
    (* A result file records one mode at one depth, so each depth gets
       its own work directory: the two modes can then be run over the
       same trace without their result files colliding, and the
       assembly CLI still sees a flat rec_*.txt directory. *)
    workDirectory = If[
      variable === None,
      directory,
      FileNameJoin[{directory, "Series" <> ToString[order]}]
    ];
    If[! DirectoryQ[workDirectory],
      CreateDirectory[workDirectory, CreateIntermediateDirectories -> True]
    ];
    jobs = reconstructionScheduleJobs[
      traceData,
      OptionValue["BundleBelowBytes"],
      OptionValue["Schedule"]
    ];
    Print @ Grid[
      Join[
        {{"Job", "Columns", "Input (MB)"}},
        {#["Name"], Length[#["Outputs"]],
          reconstructionTenth[#["Bytes"]/2.^20]} & /@ jobs,
        {{
          "Mode",
          If[variable === None,
            "full rational",
            ToString[variable] <> " series to order " <> ToString[order]],
          ToString[threads] <> " threads"
        }}
      ],
      Frame -> All
    ];
    records = reconstructionRunSchedule[
      jobs, traceData, workDirectory, executable, options
    ];
    (* This stage only ever reads the result files of its own schedule,
       but the assembly CLI globs the directory, so a file left by a
       different schedule would collide there.  Say so once. *)
    Module[{stale},
      stale = Complement[
        reconstructionResultFiles[workDirectory],
        Lookup[records, "RecordFile"]
      ];
      If[stale =!= {},
        Print["  note: ", Length[stale],
          " result file(s) in the directory belong to another schedule ",
          "and are ignored: ", FileNameTake /@ Take[stale, UpTo[5]]]
      ]
    ];
    coefficientProgressStage["Parsing reconstructed columns"];
    collected = reconstructionCollectResults[
      workDirectory,
      directory,
      traceData,
      variable,
      Lookup[records, "RecordFile"]
    ];
    If[collected === $Failed, Return[$Failed]];
    coefficientProgressStage["Assembling master coefficients"];
    result = reconstructionAssembleProduction[
      inputs, collected, records, executable, options
    ];
    If[result === $Failed, Return[$Failed]];
    slices = OptionValue["VerifySlices"];
    If[IntegerQ[slices] && slices > 0,
      coefficientProgressStage["Verifying columns on univariate slices"];
      Module[{artifact, outcome},
        (* Built from the columns just parsed, not from a fresh glob of
           the directory: result files of an earlier schedule may still
           be lying beside them. *)
        artifact = reconstructionColumnArtifact[
          traceData,
          directory,
          collected,
          finiteFieldTraceManifestFile[directory],
          Lookup[records, "RecordFile"]
        ];
        outcome = Map[
          reconstructionVerifySlices[artifact, #, slices] &,
          artifact["Covered"]
        ];
        If[! AllTrue[outcome, TrueQ[#["Verified"]] &],
          Message[ReconstructCoefficients::verify,
            "a univariate slice disagreed with the trace input"];
          Return[$Failed]
        ];
        result = Append[result, "SliceVerification" -> outcome]
      ]
    ];
    seriesCheck = OptionValue["VerifySeriesOrders"];
    If[variable =!= None && IntegerQ[seriesCheck] && seriesCheck < order,
      coefficientProgressStage["Verifying series orders independently"];
      Module[{outcome},
        outcome = reconstructionVerifySeriesOrders[
          inputs, collected, records, executable, options, seriesCheck
        ];
        If[! TrueQ[outcome["Verified"]],
          Message[ReconstructCoefficients::verify,
            "an independent shallower series run disagreed"];
          Return[$Failed]
        ];
        result = Append[result, "SeriesOrderVerification" -> outcome]
      ]
    ];
    resultFile = Switch[OptionValue["ResultFile"],
      None, None,
      Automatic, FileNameJoin[{workDirectory, "CoefficientResult.wl"}],
      _String, ExpandFileName[OptionValue["ResultFile"]],
      _, $Failed
    ];
    If[resultFile === $Failed,
      Message[ReconstructCoefficients::option, "ResultFile",
        OptionValue["ResultFile"]];
      Return[$Failed]
    ];
    If[StringQ[resultFile],
      result = Append[result, "CoefficientResultFile" -> resultFile];
      Put[result, resultFile]
    ];
    coefficientProgressFinish[];
    Print @ Grid[
      {
        {"Masters", Length[result["Masters"]]},
        {"Jobs", Length[records]},
        {"Columns", collected["OutputCount"]},
        {"Result blocks", collected["BlockCount"]},
        {
          "Mode",
          If[variable === None,
            "full rational",
            ToString[variable] <> " series through order " <> ToString[order]]
        },
        {"FireFly time (s)",
          Round[Total[Map[Lookup[#, "Seconds", 0] &, records]], 0.01]},
        {"Parse time (s)", Round[collected["ParseSeconds"], 0.01]},
        {"Total time (s)", Round[AbsoluteTime[] - started, 0.01]},
        {"Result file", If[StringQ[resultFile], resultFile, "not written"]}
      },
      Frame -> All
    ];
    result
  ],
  $reconstructionFailure
];
