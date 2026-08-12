(* Sequential two-loop DE construction over the master-hosting
   families, hardest (most masters) first.  Skips families whose
   block file already exists; logs failures and continues. *)
Get["/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/nnlo_de_core.wl"];

countArg = If[Length[Rest[$ScriptCommandLine]] >= 1,
  ToExpression[First[Rest[$ScriptCommandLine]]], 25];

manifest0 = FeynFacet`Private`coefficientReadRecord[
  FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal",
    "CoefficientSimplification", "UU_08_10_canonical",
    "FiniteFieldCanonical", "TraceManifest.wxf"}]];
masters0 = manifest0["TraceData"]["Masters"];
Print["ordinal 1 family: ", InputForm[masters0[[1]]]];
Print["ordinal 2 family: ", InputForm[masters0[[2]]]];
counts = ReverseSort[Counts[ToString[#[[1]]] & /@ masters0]];
Print["families with masters: ", Length[counts]];
Print["top 10: ", Normal[Take[counts, UpTo[10]]]];
queue = Take[Keys[counts], UpTo[countArg]];
queue = DeleteDuplicates @ Join[
  {ToString[masters0[[1, 1]]], ToString[masters0[[2, 1]]]}, queue];

Do[
  Module[{out, status, seconds},
    out = FileNameJoin[{scratch, "nnlo_de_" <> fam <> ".wl"}];
    If[FileExistsQ[out],
      Print["== ", fam, ": already done"],
      Print["== ", fam];
      {seconds, status} = AbsoluteTiming[
        Quiet @ Check[buildFamilyDE[fam], $failed]
      ];
      Print["== ", fam, " -> ", status, "  (",
        Round[seconds, 0.1], " s)"]
    ]
  ],
  {fam, queue}
];
Print["QUEUE DONE"];
summary = Map[
  Function[fam,
    Module[{file, data},
      file = FileNameJoin[{scratch, "nnlo_de_" <> fam <> ".wl"}];
      If[FileExistsQ[file],
        data = Get[file];
        fam -> <|
          "Block" -> Length[data["BlockBasis"]],
          "Canonical" -> Length[data["CanonicalMasters"]],
          "Flat" -> data["FlatnessZero"],
          "Alphabet" -> Select[data["Alphabet"], ! NumberQ[#] &]
        |>,
        fam -> "MISSING"
      ]
    ]
  ],
  queue
];
Put[Association[summary],
  FileNameJoin[{scratch, "nnlo_de_summary.wl"}]];
Print["SUMMARY SAVED"];
