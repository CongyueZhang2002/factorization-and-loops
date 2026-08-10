(* Materialize a KiraStream directory artifact into a legacy
   KiraResult.wl and run the finite-field coefficient reconstruction.

   Usage:
     wolframscript -file Scripts/stream_to_coefficients.wls \
       <processDirectory> <canonicalResultName> [threads] [kernels]

   The materialization uses KiraStreamResult, which loads the whole
   reduction into memory - appropriate for small and medium sets; the
   direct record-store adapter for very large sets is a separate task. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["Usage: stream_to_coefficients.wls <processDirectory> <canonicalResultName> [threads] [kernels]"];
  Exit[1]
];
processDirectory = FileNameJoin[{root, arguments[[1]]}];
resultName = arguments[[2]];
threads = If[Length[arguments] >= 3, ToExpression[arguments[[3]]], 8];
kernels = If[Length[arguments] >= 4, ToExpression[arguments[[4]]], 6];

resultDirectory = FileNameJoin[{processDirectory, "Results", resultName}];
streamDirectory = FileNameJoin[{resultDirectory, "KiraStream"}];
kiraFile = FileNameJoin[{resultDirectory, "KiraResult.wl"}];

If[! FileExistsQ[kiraFile],
  Print["Materializing ", streamDirectory];
  {seconds, kira} = AbsoluteTiming[
    FeynFacet`Private`KiraStreamResult[streamDirectory]
  ];
  If[! AssociationQ[kira],
    Print["MATERIALIZE: FAILED"];
    Exit[1]
  ];
  Print["MATERIALIZESECONDS: ", Round[seconds, 0.1]];
  Put[kira, kiraFile];
  Clear[kira];
  ClearSystemCache[]
];
Print["KIRAFILE: ", kiraFile, " (",
  Round[FileByteCount[kiraFile]/2.^20, 0.1], " MB)"];

pairFiles = Sort[FileNames[
  "F*_C*.wl", FileNameJoin[{resultDirectory, "Pairs"}]
]];
Print["PAIRFILES: ", Length[pairFiles]];

(* The project form late-binds HadronicVariables, CoefficientKinematics
   and KinematicMassDimensions from the card, so declaration updates do
   not require regenerating the pair artifacts. It writes
   CoefficientResult.wl into the result directory itself. *)
cardName = First[StringSplit[FileNameTake[First[pairFiles]], "_"]];
cardName = Lookup[
  Quiet @ Check[Get[First[pairFiles]], <||>],
  "CardName",
  $Failed
];
If[! StringQ[cardName],
  Print["CARDNAME: FAILED"];
  Exit[1]
];
Print["CARDNAME: ", cardName];

{coefficientSeconds, result} = AbsoluteTiming[
  FeynFacet`CoefficientSimplification[
    processDirectory,
    cardName,
    resultName,
    "Threads" -> threads,
    "NormalizationKernels" -> kernels
  ]
];
If[! AssociationQ[result],
  Print["COEFFICIENTS: FAILED"];
  Exit[1]
];
Print["COEFFICIENTSECONDS: ", Round[coefficientSeconds, 0.1]];
Print["COEFFICIENTMASTERS: ", Length[result["Masters"]]];
Print["COEFFICIENTFILE: ",
  FileNameJoin[{resultDirectory, "CoefficientResult.wl"}]];
