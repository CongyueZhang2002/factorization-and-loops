(* Univariate-slice check of a reassembled master coefficient.

   The reconstruction is only trustworthy if it agrees with the trace
   input it was built from.  Comparing the two multivariate rational
   functions directly is out of reach (the inputs run to tens of MB of
   plus-concatenated contributions), but a slice is cheap: fix every
   variable but one to a random rational, and the two sides become
   univariate rational functions that must agree exactly.  A random
   rational point of a wrong identity survives with probability zero in
   exact arithmetic, so a handful of slices is a strong check.

   The original input is substituted TEXTUALLY - the alias variables are
   string-replaced by their rational values before the file is parsed -
   so the giant symbolic expression is never built.  Only the slice
   variable stays symbolic.

   Usage:
     wolframscript -file Scripts/verify_reconstruction_slice.wls \
       <reconstructionDir> <masterIndex> [count]

   Exits 0 only if every slice agrees exactly. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["Usage: verify_reconstruction_slice.wls <reconstructionDir> ",
    "<masterIndex> [count]"];
  Exit[1]
];
directory = ExpandFileName[arguments[[1]]];
masterIndex = ToExpression[arguments[[2]]];
count = If[Length[arguments] >= 3, ToExpression[arguments[[3]]], 3];
If[! IntegerQ[masterIndex] || masterIndex < 1 ||
    ! IntegerQ[count] || count < 1,
  Print["masterIndex and count must be positive integers"];
  Exit[1]
];

tenth[value_] := N[Round[10 value]/10];

(* --- assembled coefficient ---------------------------------------- *)

artifactFile = FileNameJoin[{directory, "AssembledCoefficients.wl"}];
If[! FileExistsQ[artifactFile],
  Print["No AssembledCoefficients.wl in ", directory,
    " - run assemble_reconstruction.wls first"];
  Exit[1]
];
Print["Reading ", artifactFile, " (",
  tenth[FileByteCount[artifactFile]/2.^20], " MB)"];
{seconds, artifact} = AbsoluteTiming[Get[artifactFile]];
If[! AssociationQ[artifact] ||
    artifact["Format"] =!= "FeynFacet-AssembledCoefficients",
  Print["Not an assembled-coefficient artifact: ", artifactFile];
  Exit[1]
];
Print["  read in ", tenth[seconds], " s"];

masters = artifact["Masters"];
If[masterIndex > Length[masters],
  Print["Master index out of range: ", masterIndex, " of ",
    Length[masters]];
  Exit[1]
];
master = masters[[masterIndex]];
If[! MemberQ[artifact["Covered"], masterIndex],
  Print["Master ", masterIndex, " is not covered by the assembly"];
  Exit[1]
];
coefficient = Lookup[artifact["Coefficients"], Key[master],
  Missing["NotFound"]];
If[MissingQ[coefficient],
  Print["No assembled coefficient for master ", masterIndex];
  Exit[1]
];

(* --- trace data --------------------------------------------------- *)

manifestFile = artifact["ManifestFile"];
If[! StringQ[manifestFile] || ! FileExistsQ[manifestFile],
  Print["The artifact does not point at a readable trace manifest: ",
    manifestFile];
  Exit[1]
];
record = Quiet @ Check[
  FeynFacet`Private`coefficientReadRecord[manifestFile], $Failed];
If[! AssociationQ[record] ||
    record["Format"] =!= "FeynFacet-TraceCheckpoint",
  Print["Not a trace checkpoint: ", manifestFile];
  Exit[1]
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
  Exit[1]
];
expressionFiles = traceData["OutputFiles"][[outputs]];
If[! AllTrue[expressionFiles, FileExistsQ],
  Print["Missing trace expression file(s): ",
    Select[expressionFiles, ! FileExistsQ[#] &]];
  Exit[1]
];
signatures = Map[
  ReleaseHold[
    traceData["Signatures"][outputMetadata[[#]]["SignatureIndex"]]] &,
  outputs
];

(* The expression files hold the rational part only; the analytic
   signature is the weight the assembly multiplies them by.  When all
   the master's outputs share one signature it divides out and both
   sides are honest rational functions - which is what makes the exact
   Together comparison meaningful even for an Epsilon slice, where the
   signature itself (2^(4 Epsilon) ...) is not rational. *)
commonSignature = If[SameQ @@ signatures, First[signatures], 1];
weights = signatures/commonSignature;
reconstruction = coefficient/commonSignature;

Print["Master ", masterIndex, ": ", InputForm[master]];
Print["  outputs: ", Length[outputs]];
Scan[
  Print["    ", FileNameTake[expressionFiles[[#]]], " (",
    tenth[FileByteCount[expressionFiles[[#]]]/2.^10], " KB), weight ",
    InputForm[weights[[#]]]] &,
  Range[Length[outputs]]
];
If[commonSignature =!= 1,
  Print["  common signature divided out: ", InputForm[commonSignature]]
];
Print["  variables: ", InputForm[variables]];

(* --- slices ------------------------------------------------------- *)

(* Small denominators keep the univariate arithmetic cheap; values in
   (0,1) stay inside the physical range of the dimensionless x, y and
   are harmless for the colour and Epsilon slots. *)
randomRational[] := Module[{denominator},
  denominator = RandomInteger[{2, 49}];
  RandomInteger[{1, denominator - 1}]/denominator
];

(* The kinematic variables come first, so the default three slices
   exercise them before the colour factors. *)
rotation = Reverse[Range[Length[variables]]];
SeedRandom[masterIndex];
Print["  slices: ", count, " (random seed ", masterIndex, ")"];

sliceValue[file_String, rules_List] := Module[{text},
  text = ReadString[file];
  If[! StringQ[text], Return[$Failed]];
  ToExpression[StringReplace[text, rules], InputForm]
];

(* The denominators carry poles at small rationals - (1 - x - y)^2 and
   (Epsilon^2 - 1/16)(Epsilon^2 - 1/4) both appear in this trace - so a
   point drawn with denominators under 50 lands on one often enough to
   matter (measured: 1 draw in 5).  Such a draw is not evidence either
   way, so redraw it rather than call it a failure. *)
$sliceAttempts = 8;

attemptSlice[position_Integer] := Module[
  {
    sliceSymbol, values, textRules, expressionRules,
    original, substituted, difference, seconds
  },
  sliceSymbol = ToExpression[aliasNames[[position]]];
  values = Table[
    If[index === position, sliceSymbol, randomRational[]],
    {index, Length[variables]}
  ];
  Print["    fixed: ",
    InputForm[
      Association @ Table[
        variables[[index]] -> values[[index]],
        {index, DeleteCases[Range[Length[variables]], position]}
      ]
    ]
  ];
  (* Longest alias first: the alias names share a prefix, so a shorter
     one must never be matched inside a longer one. *)
  textRules = SortBy[
    Table[
      aliasNames[[index]] -> "(" <> ToString[values[[index]], InputForm] <>
        ")",
      {index, DeleteCases[Range[Length[variables]], position]}
    ],
    -StringLength[First[#]] &
  ];
  expressionRules = Table[
    variables[[index]] -> values[[index]],
    {index, Range[Length[variables]]}
  ];
  {seconds, original} = AbsoluteTiming[
    Quiet[
      Module[{parsed},
        parsed = sliceValue[#, textRules] & /@ expressionFiles;
        If[MemberQ[parsed, $Failed],
          $Failed,
          Total[weights parsed]
        ]
      ],
      {Power::infy, Infinity::indet, General::stop}
    ]
  ];
  If[original === $Failed,
    Print["    FAIL - an expression file could not be substituted"];
    Return[False]
  ];
  Print["    original slice built in ", tenth[seconds], " s (LeafCount ",
    LeafCount[original], ")"];
  {seconds, substituted} = AbsoluteTiming[
    Quiet[
      reconstruction /. expressionRules,
      {Power::infy, Infinity::indet, General::stop}
    ]
  ];
  Print["    reconstruction slice built in ", tenth[seconds],
    " s (LeafCount ", LeafCount[substituted], ")"];
  If[! FreeQ[{original, substituted},
      DirectedInfinity | Indeterminate | ComplexInfinity],
    Print["    the draw hit a vanishing denominator - redrawing"];
    Return[$Degenerate]
  ];
  If[! FreeQ[substituted, Alternatives @@ variables],
    Print["    FAIL - the reconstruction still carries a trace variable"];
    Return[False]
  ];
  (* A slice that collapses both sides to zero would agree for the wrong
     reason; an output exists only where a nonzero contribution landed,
     so say so loudly instead of counting it as evidence. *)
  If[TrueQ[Together[original] === 0],
    Print["    WARNING - the original slice is identically zero"]
  ];
  {seconds, difference} = AbsoluteTiming[Together[original - substituted]];
  Print["    compared in ", tenth[seconds], " s"];
  If[difference === 0,
    Print["    PASS"];
    True,
    Print["    FAIL - the difference is not zero (LeafCount ",
      LeafCount[difference], ")"];
    False
  ]
];

runSlice[step_Integer] := Module[{position, result},
  position = rotation[[Mod[step - 1, Length[rotation]] + 1]];
  Print["  slice ", step, ": ", InputForm[variables[[position]]], " free"];
  Do[
    result = attemptSlice[position];
    If[result =!= $Degenerate, Return[result, Module]],
    {$sliceAttempts}
  ];
  Print["    FAIL - every draw hit a vanishing denominator"];
  False
];

results = Table[runSlice[step], {step, count}];
Print["SUMMARY"];
Print["  master ", masterIndex, ": ", Count[results, True], "/", count,
  " slices agree exactly"];
If[AllTrue[results, TrueQ],
  Print["  VERIFIED"];
  Exit[0],
  Print["  NOT VERIFIED"];
  Exit[1]
];
