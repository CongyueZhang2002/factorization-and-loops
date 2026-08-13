(* Reassembly of per-master coefficients from ratracer/FireFly result
   files.  A reconstruction directory holds one or more rec_*.txt
   files, each a sequence of blocks

     <expression-file-path> =
       <rational function in alias variables>;

   covering a subset of the trace outputs (a long run is normally split
   so that the two heavy columns reconstruct separately).  This script
   parses whatever is present and writes the intermediate artifact
   AssembledCoefficients.wl; it deliberately stops short of the
   production CoefficientResult format, which needs the full column set
   plus the root-freedom and cut certifications.

   The result files are large (measured: 262 MB / 345 outputs, single
   blocks up to 17 MB), so the blocks are read and parsed one at a
   time from a stream instead of through one whole-file ToExpression.

   Usage:
     wolframscript -file Scripts/assemble_reconstruction.wls \
       <reconstructionDir> [<traceDirectory>]

   The trace manifest is discovered from the sibling directories of
   <reconstructionDir> unless <traceDirectory> names it explicitly. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 1,
  Print["Usage: assemble_reconstruction.wls <reconstructionDir> ",
    "[<traceDirectory>]"];
  Exit[1]
];
directory = ExpandFileName[arguments[[1]]];
If[! DirectoryQ[directory],
  Print["No such directory: ", directory];
  Exit[1]
];

resultFiles = Sort @ FileNames["rec_*.txt", directory];
If[resultFiles === {},
  Print["No rec_*.txt result files in ", directory];
  Exit[1]
];

(* Round[x, 0.1] leaves binary noise in the printout (0.7000000000001);
   round through the exact rational instead. *)
tenth[value_] := N[Round[10 value]/10];

(* --- block markers ------------------------------------------------ *)

(* A marker line is short and ends in " ="; an expression line is the
   whole rational function and can be tens of MB, so the length test
   comes first and keeps the scan off the payload. *)
$markerLineLimit = 4096;

markerPath[line_String] := Module[{trimmed},
  If[StringLength[line] >= $markerLineLimit, Return[None]];
  trimmed = StringTrim[line];
  If[! StringEndsQ[trimmed, "="] || StringLength[trimmed] < 2,
    Return[None]
  ];
  trimmed = StringTrim[StringDrop[trimmed, -1]];
  If[trimmed === "" || ! StringFreeQ[trimmed, WhitespaceCharacter],
    Return[None]
  ];
  trimmed
];

resultMarkers[file_String] := Module[{stream, line, path, markers = {}},
  stream = OpenRead[file];
  If[Head[stream] =!= InputStream, Return[$Failed]];
  While[(line = ReadLine[stream]) =!= EndOfFile,
    path = markerPath[line];
    If[path =!= None, AppendTo[markers, path]]
  ];
  Close[stream];
  markers
];

Print["Result files: ", Length[resultFiles]];
markersByFile = Association @ Map[
  Function[file,
    Module[{markers, seconds},
      {seconds, markers} = AbsoluteTiming[resultMarkers[file]];
      If[markers === $Failed,
        Print["Unreadable result file: ", file];
        Exit[1]
      ];
      Print["  ", FileNameTake[file], ": ", Length[markers], " blocks, ",
        tenth[FileByteCount[file]/2.^20], " MB, scanned in ",
        tenth[seconds], " s"];
      file -> markers
    ]
  ],
  resultFiles
];
allMarkers = Join @@ Values[markersByFile];
If[allMarkers === {},
  Print["No '<path> =' blocks found in the result files"];
  Exit[1]
];
If[Length[allMarkers] =!= Length[DeleteDuplicates[allMarkers]],
  Print["Duplicate output blocks across the result files: ",
    Take[Keys @ Select[Counts[allMarkers], # > 1 &], UpTo[5]]];
  Exit[1]
];

(* --- trace manifest ----------------------------------------------- *)

(* The markers are written by ratracer exactly as the paths were passed
   on its command line, so a manual run started from the trace
   directory records relative paths while the package passes absolute
   ones.  A candidate manifest is accepted only if every marker
   resolves, against its own directory, to one of its output files -
   which is also what tells the canonical trace apart from the older
   one next to it. *)
manifestCandidates = If[Length[arguments] >= 2,
  {FeynFacet`Private`finiteFieldTraceManifestFile[
    ExpandFileName[arguments[[2]]]]},
  Select[
    DeleteDuplicates @ Map[
      FeynFacet`Private`finiteFieldTraceManifestFile,
      Join[
        {directory},
        Select[FileNames["*", ParentDirectory[directory]], DirectoryQ]
      ]
    ],
    FileExistsQ
  ]
];
If[manifestCandidates === {},
  Print["No TraceManifest.wxf found next to ", directory];
  Exit[1]
];

resolveMarkers[traceDirectory_String, outputFiles_List, markers_List] :=
  Module[{index},
    index = Association @ Join[
      MapIndexed[# -> First[#2] &, outputFiles],
      MapIndexed[ExpandFileName[#] -> First[#2] &, outputFiles]
    ];
    Map[
      Lookup[
        index,
        ExpandFileName[
          If[StringStartsQ[#, "/"], #,
            FileNameJoin[{traceDirectory, #}]]
        ],
        Missing["NotAnOutput"]
      ] &,
      markers
    ]
  ];

candidates = Map[
  Function[file,
    Module[{record, traceData, resolved},
      record = Quiet @ Check[
        FeynFacet`Private`coefficientReadRecord[file], $Failed];
      If[! AssociationQ[record] ||
          record["Format"] =!= "FeynFacet-TraceCheckpoint" ||
          ! AssociationQ[record["TraceData"]],
        Return[Nothing]
      ];
      traceData = record["TraceData"];
      resolved = resolveMarkers[
        DirectoryName[file], traceData["OutputFiles"], allMarkers];
      <|
        "File" -> file,
        "Record" -> record,
        "Resolved" -> resolved,
        "Matched" -> Count[resolved, _Integer]
      |>
    ]
  ],
  manifestCandidates
];
candidates = SortBy[candidates, -#["Matched"] &];
Scan[
  Print["  candidate ", #["File"], ": ", #["Matched"], "/",
    Length[allMarkers], " blocks resolve"] &,
  candidates
];
manifest = First[candidates, $Failed];
If[manifest === $Failed || manifest["Matched"] =!= Length[allMarkers],
  Print["No trace manifest accounts for every result block; pass the ",
    "trace directory explicitly as the second argument"];
  Exit[1]
];
Print["Manifest: ", manifest["File"]];

traceData = manifest["Record"]["TraceData"];
outputFiles = traceData["OutputFiles"];
outputMetadata = traceData["OutputMetadata"];
signatures = traceData["Signatures"];
symbolRules = traceData["SymbolRules"];
masters = traceData["Masters"];
aliasNames = SymbolName /@ Values[symbolRules];
aliasOriginals = AssociationThread[aliasNames, Keys[symbolRules]];
outputIndex = AssociationThread[allMarkers, manifest["Resolved"]];
Print["Outputs in the trace: ", Length[outputFiles],
  "; masters: ", Length[masters],
  "; result blocks: ", Length[allMarkers]];

(* --- parsing ------------------------------------------------------ *)

(* Same contract as finiteFieldParseReconstruction: the block text is
   read as InputForm, checked to be a rational function of the alias
   variables only, and mapped back to the original symbols through the
   symbols that were actually created by the parse (their context
   depends on the reading session, their names do not). *)
parseBlock[text_String] := Module[{held, expression, aliases, rules},
  held = Quiet @ Check[
    ToExpression[
      StringReplace[StringTrim[text], RegularExpression[";\\s*$"] -> ""],
      InputForm,
      HoldComplete
    ],
    $Failed
  ];
  If[Head[held] =!= HoldComplete, Return[$Failed]];
  expression = ReleaseHold[held];
  If[! FeynFacet`Private`finiteFieldParseRational[expression, aliasNames],
    Return[$Failed]
  ];
  aliases = DeleteDuplicates @ Cases[
    expression,
    symbol_Symbol /; MemberQ[aliasNames, SymbolName[symbol]] :> symbol,
    Infinity
  ];
  rules = Dispatch[(# -> aliasOriginals[SymbolName[#]]) & /@ aliases];
  expression /. rules
];

$parsed = <||>;
$parsedCount = 0;
$startTime = AbsoluteTime[];

recordBlock[path_String, lines_List] := Module[{index, expression},
  index = outputIndex[path];
  (* A block is normally one line; rejoin with newlines so a wrapped
     block cannot fuse two numbers into one. *)
  expression = parseBlock[StringRiffle[Reverse[lines], "\n"]];
  If[expression === $Failed,
    Print["FAILED to parse block ", path];
    Exit[1]
  ];
  AssociateTo[$parsed, index -> expression];
  $parsedCount++;
  If[Mod[$parsedCount, 25] === 0,
    Print["  parsed ", $parsedCount, "/", Length[allMarkers],
      " outputs, ", tenth[AbsoluteTime[] - $startTime], " s, ",
      Round[MemoryInUse[]/2.^20], " MB in use"]
  ];
];

parseResultFile[file_String] := Module[
  {stream, line, path, current = None, lines = {}},
  stream = OpenRead[file];
  If[Head[stream] =!= InputStream,
    Print["Unreadable result file: ", file];
    Exit[1]
  ];
  While[True,
    line = ReadLine[stream];
    path = If[line === EndOfFile, "", markerPath[line]];
    If[line === EndOfFile || path =!= None,
      If[current =!= None, recordBlock[current, lines]];
      If[line === EndOfFile, Break[]];
      current = path;
      lines = {},
      If[current =!= None, PrependTo[lines, line]]
    ]
  ];
  Close[stream];
];

Print["Parsing ", Length[allMarkers], " output blocks"];
Scan[
  Function[file,
    Module[{seconds},
      seconds = First @ AbsoluteTiming[parseResultFile[file]];
      Print["  ", FileNameTake[file], " parsed in ",
        tenth[seconds], " s"]
    ]
  ],
  resultFiles
];
Print["Parsed ", $parsedCount, "/", Length[outputFiles], " outputs in ",
  tenth[AbsoluteTime[] - $startTime], " s"];

(* --- assembly ----------------------------------------------------- *)

(* coefficient(master i) = sum over the outputs of master i of the
   analytic signature times the reconstructed rational function.  The
   remainder column carries MasterIndex 0 and is reported separately
   rather than folded into a master. *)
outputsByMaster = GroupBy[
  Range[Length[outputFiles]],
  outputMetadata[[#]]["MasterIndex"] &
];

masterColumn[index_Integer] := Total @ Map[
  Function[output,
    ReleaseHold[signatures[outputMetadata[[output]]["SignatureIndex"]]] *
      $parsed[output]
  ],
  Lookup[outputsByMaster, index, {}]
];

(* A master with no output at all is complete with coefficient zero -
   the emitter writes an output only where a nonzero contribution
   landed - so it counts as covered, not missing. *)
masterStatus = AssociationMap[
  Function[index,
    Module[{outputs, present},
      outputs = Lookup[outputsByMaster, index, {}];
      present = Count[outputs, output_ /; KeyExistsQ[$parsed, output]];
      Which[
        present === Length[outputs], "Covered",
        present === 0, "Missing",
        True, "Partial"
      ]
    ]
  ],
  Range[Length[masters]]
];
covered = Keys @ Select[masterStatus, # === "Covered" &];
partial = Keys @ Select[masterStatus, # === "Partial" &];
missing = Keys @ Select[masterStatus, # === "Missing" &];

Print["Assembling ", Length[covered], " master columns"];
coefficients = Association @ Map[
  masters[[#]] -> masterColumn[#] &,
  covered
];
remainder = If[KeyExistsQ[outputsByMaster, 0],
  If[AllTrue[outputsByMaster[0], KeyExistsQ[$parsed, #] &],
    masterColumn[0],
    Missing["Incomplete"]
  ],
  0
];

artifact = <|
  "Format" -> "FeynFacet-AssembledCoefficients",
  "Masters" -> masters,
  "Coefficients" -> coefficients,
  "Covered" -> covered,
  "Missing" -> missing,
  (* Provenance, so the slice check can find the same trace data. *)
  "Partial" -> partial,
  "ManifestFile" -> manifest["File"],
  "ResultFiles" -> resultFiles,
  "OutputsParsed" -> $parsedCount,
  "OutputCount" -> Length[outputFiles],
  "Remainder" -> remainder,
  "PhysicalFactor" -> traceData["PhysicalFactor"],
  "CompleteTargetSet" -> traceData["CompleteTargetSet"]
|>;

artifactFile = FileNameJoin[{directory, "AssembledCoefficients.wl"}];
Print["Writing ", artifactFile];
Print["  wrote in ",
  tenth[First @ AbsoluteTiming[Put[artifact, artifactFile]]],
  " s, ", tenth[FileByteCount[artifactFile]/2.^20], " MB"];

Print["SUMMARY"];
Print["  outputs parsed: ", $parsedCount, "/", Length[outputFiles]];
Print["  masters covered: ", Length[covered], "/", Length[masters]];
If[partial =!= {},
  Print["  masters partially covered: ", Length[partial], " ",
    Take[partial, UpTo[10]]]
];
If[missing =!= {},
  Print["  masters missing: ", Length[missing], " ",
    Take[missing, UpTo[10]]]
];
Print["  remainder column: ", If[remainder === 0, "absent", "present"]];
Print["  peak memory (MB): ", Round[MaxMemoryUsed[]/2.^20]];
