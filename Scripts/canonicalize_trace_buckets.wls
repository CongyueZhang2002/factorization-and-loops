(* Bucket-merge post-pass over an existing finite-field trace
   checkpoint: regroup its outputs by canonicalized signature
   (modulo the rational function field of the trace variables) WITHOUT
   renormalizing, and emit a new checkpoint directory.

   The input directory is never modified.  Unmerged expression files
   are hard-linked into the output; merged buckets are written as
   rational-weight plus-concatenations
     (w_1)*(file_1) + (w_2)*(file_2) + ...
   with w_i the exact rational factor between the bucket's signature
   and the canonical one - the identity Sum_i sig_i R_i =
   canonical * Sum_i w_i R_i, proven by hand on masters 1 and 107
   (WORKLOG 2026-08-11).

   Usage:
     wolframscript -file Scripts/canonicalize_trace_buckets.wls \
       <inputFiniteFieldDir> <outputDir> <cardFile> *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["Usage: canonicalize_trace_buckets.wls <inputFiniteFieldDir> <outputDir> <cardFile>"];
  Exit[1]
];
inputDirectory = ExpandFileName[arguments[[1]]];
outputDirectory = ExpandFileName[arguments[[2]]];
cardFile = ExpandFileName[arguments[[3]]];

If[FileExistsQ[outputDirectory] || DirectoryQ[outputDirectory],
  Print["Refusing to write into the existing path ", outputDirectory];
  Exit[1]
];

record = FeynFacet`Private`coefficientReadRecord[
  FeynFacet`Private`finiteFieldTraceManifestFile[inputDirectory]
];
If[! AssociationQ[record] ||
    record["Format"] =!= "FeynFacet-TraceCheckpoint",
  Print["Not a trace checkpoint: ", inputDirectory];
  Exit[1]
];
traceData = record["TraceData"];

card = Get[cardFile];
scale = card["CoefficientKinematics"]["Scale"];
excluded = DeleteDuplicates @ Join[
  If[MatchQ[scale, _Symbol], {scale}, {}],
  {FeynFacet`\[Alpha]s}
];
Print["EXCLUDED: ", InputForm[excluded]];

signatures = traceData["Signatures"];
outputOrder = traceData["OutputOrder"];
outputFiles = traceData["OutputFiles"];
outputMetadata = traceData["OutputMetadata"];
contributionCounts = traceData["ContributionCounts"];
symbolRules = traceData["SymbolRules"];
aliasRules = Dispatch[Normal[symbolRules]];

resolveFile[name_] :=
  If[StringStartsQ[name, "/"], name,
    FileNameJoin[{inputDirectory, name}]];

(* Canonicalize every signature once, and certify each split exactly:
   fold x canonical must equal the original signature. *)
splits = Association @ KeyValueMap[
  Function[{id, held},
    Module[{split},
      split = FeynFacet`Private`finiteFieldCanonicalizeSignature[
        held, excluded
      ];
      If[! TrueQ @ FeynFacet`Private`exactZeroQ[
          Last[split] ReleaseHold[First[split]] - ReleaseHold[held]],
        Print["INEXACT SPLIT at signature ", id, ": ", InputForm[held]];
        Exit[1]
      ];
      id -> split
    ]
  ],
  signatures
];

(* Fold weights must stringify with the stored alias map: a fold
   symbol outside it would reach ratracer unaliased. *)
Scan[
  Function[split,
    Module[{loose},
      loose = Select[
        DeleteDuplicates @ Cases[
          Last[split], symbol_Symbol :> symbol, {0, Infinity},
          Heads -> False
        ],
        ! KeyExistsQ[symbolRules, #] &
      ];
      If[loose =!= {},
        Print["UNALIASED FOLD SYMBOLS: ", InputForm[loose]];
        Exit[1]
      ]
    ]
  ],
  Values[splits]
];

(* Group outputs by {MasterIndex, canonical signature}; new signature
   ids in first-appearance order over the stored output order. *)
(* Identity by hash bucket + SameQ, exactly as the production
   signatureID does: no reliance on Association Key semantics. *)
newSignatures = {};
canonicalBuckets = <||>;
newSignatureIndex[canonical_] := Module[{hash, candidates, existing},
  hash = Hash[canonical, "SHA256", "HexString"];
  candidates = Lookup[canonicalBuckets, hash, {}];
  existing = SelectFirst[
    candidates,
    SameQ[newSignatures[[#]], canonical] &,
    Missing["NotFound"]
  ];
  If[! MissingQ[existing], Return[existing]];
  AppendTo[newSignatures, canonical];
  AssociateTo[
    canonicalBuckets,
    hash -> Append[candidates, Length[newSignatures]]
  ];
  Length[newSignatures]
];

groups = <||>;  (* {masterIndex, newSigId} -> list of member positions *)
groupOrder = {};
Do[
  Module[{meta, split, key},
    meta = outputMetadata[[position]];
    split = splits[meta["SignatureIndex"]];
    key = {meta["MasterIndex"], newSignatureIndex[First[split]]};
    If[! KeyExistsQ[groups, key],
      AssociateTo[groups, key -> {}];
      AppendTo[groupOrder, key]
    ];
    AssociateTo[groups, key -> Append[groups[key], position]]
  ],
  {position, Length[outputOrder]}
];

expressionDirectory = FileNameJoin[{outputDirectory, "Expressions"}];
CreateDirectory[expressionDirectory, CreateIntermediateDirectories -> True];

outputKey[index_Integer, id_Integer] :=
  IntegerString[index, 10, 6] <> "_" <> IntegerString[id, 10, 6];

mergedCount = 0;
linkedCount = 0;
newOrder = {};
newFiles = {};
newMetadata = {};
newCounts = {};
Do[
  Module[{members, key, file, folds, singleton, source, status, stream},
    members = groups[group];
    key = outputKey[group[[1]], group[[2]]];
    file = FileNameJoin[{expressionDirectory, "Output_" <> key <> ".expr"}];
    folds = Last[splits[outputMetadata[[#]]["SignatureIndex"]]] & /@
      members;
    singleton = Length[members] === 1 && TrueQ[First[folds] === 1];
    If[singleton,
      source = resolveFile[outputFiles[[First[members]]]];
      status = RunProcess[{"ln", source, file}];
      If[status["ExitCode"] =!= 0, CopyFile[source, file]];
      linkedCount++,
      stream = OpenWrite[file];
      Do[
        Module[{contents},
          contents = StringTrim @ ReadString[
            resolveFile[outputFiles[[members[[i]]]]]
          ];
          WriteString[
            stream,
            If[i === 1, "", "+"],
            "(",
            StringReplace[
              ToString[folds[[i]] /. aliasRules, InputForm],
              WhitespaceCharacter .. -> ""
            ],
            ")*(", contents, ")"
          ]
        ],
        {i, Length[members]}
      ];
      WriteString[stream, "\n"];
      Close[stream];
      mergedCount++
    ];
    AppendTo[newOrder, key];
    AppendTo[newFiles, file];
    AppendTo[newMetadata, <|
      "MasterIndex" -> group[[1]],
      "SignatureIndex" -> group[[2]]
    |>];
    AppendTo[newCounts,
      Total[contributionCounts[[members]]]
    ]
  ],
  {group, groupOrder}
];

newRegistry = AssociationThread[
  Range[Length[newSignatures]], newSignatures
];
newScalePowers = If[
  MatchQ[scale, _Symbol],
  Map[
    Exponent[ReleaseHold[newSignatures[[#["SignatureIndex"]]]], scale] &,
    newMetadata
  ],
  ConstantArray[0, Length[newOrder]]
];

newTraceData = Join[
  traceData,
  <|
    "Signatures" -> newRegistry,
    "OutputOrder" -> newOrder,
    "OutputFiles" -> newFiles,
    "OutputMetadata" -> newMetadata,
    "ContributionCounts" -> newCounts,
    "ScalePowers" -> newScalePowers,
    "ExpressionBytes" -> FileByteCount /@ newFiles
  |>
];

FeynFacet`Private`finiteFieldWriteTraceManifest[
  outputDirectory,
  newTraceData,
  record["InputFileFingerprint"],
  record["KiraFileHash"]
];

Print["OUTPUTS: ", Length[outputOrder], " -> ", Length[newOrder]];
Print["SIGNATURES: ", Length[signatures], " -> ", Length[newSignatures]];
Print["LINKED: ", linkedCount, "  MERGED: ", mergedCount];
multi = Select[groupOrder, Length[groups[#]] > 1 &];
Print["MULTIBUCKET GROUPS: ", Length[multi]];
Print["LARGEST GROUPS: ",
  Take[
    ReverseSortBy[
      {#, Length[groups[#]]} & /@ groupOrder, Last
    ],
    UpTo[10]
  ]
];
Print["BYTES: ",
  Round[Total[traceData["ExpressionBytes"]]/2.^20, 0.1], " MB -> ",
  Round[Total[newTraceData["ExpressionBytes"]]/2.^20, 0.1], " MB"];
Print["DONE: ", outputDirectory];
