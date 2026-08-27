(* Regression for the reconstruction result parser.

   The parser that ReconstructCoefficients replaced
   (finiteFieldParseReconstruction) located every marker by string
   position in one whole-file scan and required the markers to be all of
   the trace's outputs, in file order.  On anything else it either
   swallowed the intervening blocks silently or returned an undiagnosed
   $Failed - in particular on a subset (a long run is split so the heavy
   columns reconstruct separately) and on the relative marker paths a
   manual run started from the trace directory writes.

   This test builds synthetic rec files over the stored NLO trace and
   pins the contract down.  The alias map is read from the manifest, not
   assumed: the trace variables are numbered in emission order and the
   order differs between traces.

   Acceptance criteria:
   A. The stored NLO trace manifest loads and names its alias map.
   B. A complete, absolute-marker result set parses to exactly the
      expressions written, with every master covered.
   C. A subset parses to exactly its own blocks, and reports the
      uncovered masters as Missing/Partial rather than mis-assigning
      them.
   D. Blocks permuted against the trace's output order parse to the same
      values - block order carries no meaning.
   E. Relative marker paths resolve against the trace directory.
   F. A DONE marker terminates the file and never reaches a block.
   G. A duplicated marker fails loudly.
   H. A marker that names no output of the trace fails loudly.
   I. A series result set parses into per-order columns, and one whose
      orders are permuted (or gapped) fails loudly rather than silently
      assembling a wrong series.
   J. A block that is not a rational function of the trace variables
      fails loudly.
   K. The assembly entry point discovers the trace manifest by itself
      and signature-weights the columns into master coefficients. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

traceDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NLO", "CoefficientSimplification",
  "UU_08_10_10x10_regen", "FiniteField"
}];

record = FeynFacet`Private`reconstructionTraceRecord[traceDirectory];
traceData = If[AssociationQ[record], record["TraceData"], $Failed];

FTTest`FTAssert["A. the stored NLO trace manifest loads with its alias map",
  AssociationQ[traceData] &&
    AssociationQ[traceData["SymbolRules"]] &&
    Length[traceData["OutputFiles"]] > 1];

If[! AssociationQ[traceData], FTTest`FTReport[]];

(* Read the alias names from the manifest; never assume v1 = CA. *)
symbolRules = traceData["SymbolRules"];
aliasNames = SymbolName /@ Values[symbolRules];
variables = Keys[symbolRules];
outputFiles = traceData["OutputFiles"];
outputCount = Length[outputFiles];
epsilonAlias = SymbolName[symbolRules[Global`Epsilon]];

workDirectory = FileNameJoin[{traceDirectory, "ParserRegression"}];
If[DirectoryQ[workDirectory],
  DeleteDirectory[workDirectory, DeleteContents -> True]];
CreateDirectory[workDirectory, CreateIntermediateDirectories -> True];

(* One small, distinct rational function of the alias variables per
   output, so a swapped or swallowed block cannot pass unnoticed. *)
aliasSymbol[name_String] := ToExpression["Global`" <> name];
sampleText[output_Integer] := Module[{a, b, c},
  {a, b, c} = aliasSymbol /@ Take[aliasNames, 3];
  ToString[
    (output + a^2 + output b)/(1 + c + output a b),
    InputForm
  ]
];
sampleValue[output_Integer] := Module[{a, b, c},
  {a, b, c} = Take[variables, 3];
  (output + a^2 + output b)/(1 + c + output a b)
];

writeBlocks[file_String, blocks_List, done_: True] := Module[{stream},
  stream = OpenWrite[file];
  Scan[
    Function[block,
      WriteString[stream, First[block], " =\n  ", Last[block], ";\n"]
    ],
    blocks
  ];
  If[done,
    WriteString[stream,
      "(* FeynFacet-ReconstructionDone job=synthetic probes=0 seconds=0 *)\n"]
  ];
  Close[stream];
  file
];

recordFile[name_String] := FileNameJoin[{workDirectory, "rec_" <> name <> ".txt"}];

collect[files_List, series_] := Quiet @ Check[
  FeynFacet`Private`reconstructionCollectResults[
    workDirectory, traceDirectory, traceData, series, files],
  $Failed,
  {FeynFacet`ReconstructCoefficients::parse,
    FeynFacet`ReconstructCoefficients::assembly}
];

parsedExactlyQ[collected_, outputs_List] := AssociationQ[collected] &&
  Sort[Keys[collected["Columns"]]] === Sort[outputs] &&
  AllTrue[
    outputs,
    TrueQ @ FeynFacet`Private`exactZeroQ[
      collected["Columns"][#] - sampleValue[#]
    ] &
  ];

(* B. complete set, absolute markers *)
complete = collect[
  {writeBlocks[
    recordFile["complete"],
    Table[{outputFiles[[output]], sampleText[output]}, {output, outputCount}]
  ]},
  None
];
FTTest`FTAssert["B. a complete absolute-marker result set parses exactly",
  parsedExactlyQ[complete, Range[outputCount]] &&
    complete["Missing"] === {} && complete["Partial"] === {} &&
    Length[complete["Covered"]] === Length[traceData["Masters"]]];

(* C. subset - the case the positional parser swallowed *)
subset = {1, 4, 5, outputCount};
subsetCollected = collect[
  {writeBlocks[
    recordFile["subset"],
    Table[{outputFiles[[output]], sampleText[output]}, {output, subset}]
  ]},
  None
];
FTTest`FTAssert["C. a subset parses to exactly its own blocks",
  parsedExactlyQ[subsetCollected, subset] &&
    subsetCollected["Missing"] =!= {} &&
    Length[subsetCollected["Covered"]] < Length[traceData["Masters"]] &&
    Intersection[
      subsetCollected["Covered"],
      subsetCollected["Missing"],
      subsetCollected["Partial"]
    ] === {}];

(* D. permuted block order *)
permutation = Reverse[Range[outputCount]];
permuted = collect[
  {writeBlocks[
    recordFile["permuted"],
    Table[{outputFiles[[output]], sampleText[output]}, {output, permutation}]
  ]},
  None
];
FTTest`FTAssert["D. permuted block order parses to the same values",
  parsedExactlyQ[permuted, Range[outputCount]]];

(* E. relative markers, as a run started from the trace directory writes *)
relative = collect[
  {writeBlocks[
    recordFile["relative"],
    Table[
      {
        FileNameJoin[{"Expressions", FileNameTake[outputFiles[[output]]]}],
        sampleText[output]
      },
      {output, outputCount}
    ]
  ]},
  None
];
FTTest`FTAssert["E. relative marker paths resolve against the trace directory",
  parsedExactlyQ[relative, Range[outputCount]]];

(* F. a DONE marker terminates the file *)
truncatedFile = recordFile["done"];
writeBlocks[
  truncatedFile,
  Table[{outputFiles[[output]], sampleText[output]}, {output, {1, 2}}]
];
(* Anything after the marker must never reach a block. *)
Module[{stream = OpenAppend[truncatedFile]},
  WriteString[stream, "trailing junk that is not a block\n"];
  Close[stream]
];
doneCollected = collect[{truncatedFile}, None];
FTTest`FTAssert["F. the DONE marker terminates the file",
  parsedExactlyQ[doneCollected, {1, 2}] &&
    TrueQ[FeynFacet`Private`reconstructionJobDoneQ[truncatedFile]]];

(* G. duplicated marker *)
duplicate = collect[
  {
    writeBlocks[
      recordFile["dup_a"],
      Table[{outputFiles[[output]], sampleText[output]}, {output, {1, 2}}]
    ],
    writeBlocks[
      recordFile["dup_b"],
      Table[{outputFiles[[output]], sampleText[output]}, {output, {2, 3}}]
    ]
  },
  None
];
FTTest`FTAssert["G. a duplicated marker fails loudly", duplicate === $Failed];

(* H. a marker that names no output of the trace *)
foreign = collect[
  {writeBlocks[
    recordFile["foreign"],
    {{FileNameJoin[{traceDirectory, "Expressions", "Output_999999_999999.expr"}],
      sampleText[1]}}
  ]},
  None
];
FTTest`FTAssert["H. an unresolvable marker fails loudly", foreign === $Failed];

(* I. series result sets *)
seriesMarker[output_Integer, order_Integer] := "ORDER[" <>
  outputFiles[[output]] <> "," <> epsilonAlias <> "^" <> ToString[order] <> "]";
seriesBlocks[output_Integer, orders_List] :=
  Table[{seriesMarker[output, order], sampleText[output + 10 order]}, {order, orders}];

seriesCollected = collect[
  {writeBlocks[
    recordFile["series"],
    Join @@ Table[seriesBlocks[output, Range[-1, 2]], {output, {1, 2}}]
  ]},
  Global`Epsilon
];
FTTest`FTAssert["I1. a series result set parses into per-order columns",
  AssociationQ[seriesCollected] &&
    Sort[Keys[seriesCollected["Columns"]]] === {1, 2} &&
    Keys[seriesCollected["Columns"][1]] === Range[-1, 2] &&
    TrueQ @ FeynFacet`Private`exactZeroQ[
      seriesCollected["Columns"][2][2] - sampleValue[2 + 20]
    ]];

seriesPermuted = collect[
  {writeBlocks[
    recordFile["series_permuted"],
    seriesBlocks[1, {-1, 1, 0, 2}]
  ]},
  Global`Epsilon
];
FTTest`FTAssert["I2. permuted series orders fail loudly",
  seriesPermuted === $Failed];

seriesGapped = collect[
  {writeBlocks[recordFile["series_gap"], seriesBlocks[1, {-1, 0, 2}]]},
  Global`Epsilon
];
FTTest`FTAssert["I3. a gap in the series orders fails loudly",
  seriesGapped === $Failed];

seriesInFull = collect[
  {writeBlocks[recordFile["series_in_full"], seriesBlocks[1, {0, 1}]]},
  None
];
FTTest`FTAssert["I4. a series block in a full rational run fails loudly",
  seriesInFull === $Failed];

(* J. a block that is not a rational function of the trace variables *)
nonRational = collect[
  {writeBlocks[
    recordFile["nonrational"],
    {{outputFiles[[1]], "Sqrt[" <> First[aliasNames] <> "]"}}
  ]},
  None
];
FTTest`FTAssert["J. a non-rational block fails loudly", nonRational === $Failed];

(* K. discovery and signature-weighted assembly through the entry point
      the CLI uses *)
Scan[
  If[FileExistsQ[#], DeleteFile[#]] &,
  FileNames["rec_*.txt", workDirectory]
];
writeBlocks[
  recordFile["complete"],
  Table[{outputFiles[[output]], sampleText[output]}, {output, outputCount}]
];
artifact = Quiet @ Check[
  FeynFacet`Private`reconstructionAssembledArtifact[workDirectory, Automatic],
  $Failed
];
expectedColumn[master_Integer] := Total @ Map[
  Function[output,
    ReleaseHold[
      traceData["Signatures"][
        traceData["OutputMetadata"][[output]]["SignatureIndex"]]
    ] sampleValue[output]
  ],
  Select[
    Range[outputCount],
    traceData["OutputMetadata"][[#]]["MasterIndex"] === master &
  ]
];
FTTest`FTAssert["K. the assembly entry point discovers the trace and weights the columns",
  AssociationQ[artifact] &&
    artifact["Format"] === "FeynFacet-AssembledCoefficients" &&
    artifact["TraceDirectory"] === ExpandFileName[traceDirectory] &&
    artifact["Missing"] === {} &&
    AllTrue[
      artifact["Covered"],
      TrueQ @ FeynFacet`Private`exactZeroQ[
        artifact["Coefficients"][traceData["Masters"][[#]]] - expectedColumn[#]
      ] &
    ]];

If[DirectoryQ[workDirectory],
  DeleteDirectory[workDirectory, DeleteContents -> True]];

Print["    trace variables: ", InputForm[variables]];
Print["    alias map: ", InputForm[symbolRules]];
Print["    outputs: ", outputCount, ", masters: ",
  Length[traceData["Masters"]]];

FTTest`FTReport[];
