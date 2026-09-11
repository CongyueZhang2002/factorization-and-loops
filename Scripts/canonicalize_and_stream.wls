Print["FEYNFACET DRIVER ENTERED"];
(* Canonicalize a regenerated pair set and run the streaming Kira
   reduction on the canonical artifacts.

   Usage:
     wolframscript -file Scripts/canonicalize_and_stream.wls \
       <processDirectory> <sourceResultName> <canonicalResultName> [canonicalize|solve|import] [kiraThreads]

   "solve" canonicalizes, solves and imports. "import" resumes from the
   retained canonical artifacts and matching solved Kira workspace.
   The default "canonicalize" writes only the canonical artifacts. *)

$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3,
  Print["Usage: canonicalize_and_stream.wls <processDirectory> <sourceResultName> <canonicalResultName> [canonicalize|solve|import] [kiraThreads]"];
  Exit[1]
];
processDirectory = FileNameJoin[{root, arguments[[1]]}];
sourceName = arguments[[2]];
canonicalName = arguments[[3]];
action=If[Length[arguments]>=4,arguments[[4]],"canonicalize"];
If[!MemberQ[{"canonicalize","solve","import"},action],
 Print["Expected canonicalize, solve or import."];Exit[1]];
runSolve=action==="solve";importOnly=action==="import";
kiraThreads = If[Length[arguments] >= 5,
  If[StringMatchQ[arguments[[5]], DigitCharacter ..] && FromDigits[arguments[[5]]] > 0,
    FromDigits[arguments[[5]]], Print["Expected a positive Kira thread count."]; Exit[1]], Automatic];

sourceDirectory = FileNameJoin[{processDirectory, "Results", sourceName}];
canonicalDirectory = FileNameJoin[{
  processDirectory, "Results", canonicalName
}];
If[!importOnly,
pairFiles = Sort[FileNames[
  "F*_C*.wl", FileNameJoin[{sourceDirectory, "Pairs"}]
]];
Print["PAIRFILES: ", Length[pairFiles]];
If[pairFiles === {}, Exit[1]];

{canonicalSeconds, canonical} = AbsoluteTiming[
  FeynFacet`Private`CanonicalizePairArtifacts[
    pairFiles,
    canonicalDirectory
  ]
];
If[! AssociationQ[canonical],
  Print["CANONICALIZATION: FAILED"];
  Exit[1]
];
Print["CANONICALSECONDS: ", Round[canonicalSeconds, 0.1]];
Print["CANONICALFAMILIES: ", Length[canonical["Registry"]["Families"]]];
Print["REJECTED: ", Length[canonical["Registry"]["Rejected"]]];

];
If[!runSolve&&!importOnly,Exit[0]];

canonicalPairs = Sort[FileNames[
  "F*_C*.wl", FileNameJoin[{canonicalDirectory, "Pairs"}]
]];
If[canonicalPairs==={},Print["No canonical pair artifacts."];Exit[1]];
If[runSolve,
Print["SOLVING: ", Length[canonicalPairs], " canonical pair artifacts"];
{solveSeconds, solveData} = AbsoluteTiming[
  FeynFacet`Private`KiraSolve[canonicalPairs, canonicalDirectory, "Threads" -> kiraThreads]
];
If[! AssociationQ[solveData],
  Print["KIRASOLVE: FAILED"];
  Exit[1]
];
Print["SOLVESECONDS: ", Round[solveSeconds, 0.1]];
];

{importSeconds, streamDirectory} = AbsoluteTiming[
  If[importOnly,
    FeynFacet`Private`KiraStreamImport[canonicalPairs,canonicalDirectory],
    FeynFacet`Private`KiraStreamImport[solveData]]
];
If[! StringQ[streamDirectory],
  Print["KIRASTREAMIMPORT: FAILED"];
  Exit[1]
];
Print["IMPORTSECONDS: ", Round[importSeconds, 0.1]];
Print["STREAMDIRECTORY: ", streamDirectory];

manifest = Get[FileNameJoin[{streamDirectory, "Manifest.wl"}]];
Print["FAMILIES: ", manifest["FamilyCount"]];
Print["TARGETS: ", manifest["TargetCount"]];
Print["MASTERS: ", manifest["MasterCount"]];
Print["RULECOUNT: ", manifest["RuleCount"]];
Print["PEAKMB: ", manifest["Diagnostics"]["PeakMemoryInUseMB"]];

Print["COMPLETED KIRA STREAM ",streamDirectory];
