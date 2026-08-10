(* Canonicalize a regenerated pair set and run the streaming Kira
   reduction on the canonical artifacts.

   Usage:
     wolframscript -file Scripts/canonicalize_and_stream.wls \
       <processDirectory> <sourceResultName> <canonicalResultName> [solve]

   With the literal fourth argument "solve", KiraSolve and
   KiraStreamImport run on the canonical set after canonicalization;
   without it the script stops after writing the canonical artifacts. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3,
  Print["Usage: canonicalize_and_stream.wls <processDirectory> <sourceResultName> <canonicalResultName> [solve]"];
  Exit[1]
];
processDirectory = FileNameJoin[{root, arguments[[1]]}];
sourceName = arguments[[2]];
canonicalName = arguments[[3]];
runSolve = Length[arguments] >= 4 && arguments[[4]] === "solve";

sourceDirectory = FileNameJoin[{processDirectory, "Results", sourceName}];
canonicalDirectory = FileNameJoin[{
  processDirectory, "Results", canonicalName
}];
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

If[! runSolve, Exit[0]];

canonicalPairs = Sort[FileNames[
  "F*_C*.wl", FileNameJoin[{canonicalDirectory, "Pairs"}]
]];
Print["SOLVING: ", Length[canonicalPairs], " canonical pair artifacts"];
{solveSeconds, solveData} = AbsoluteTiming[
  FeynFacet`Private`KiraSolve[canonicalPairs, canonicalDirectory]
];
If[! AssociationQ[solveData],
  Print["KIRASOLVE: FAILED"];
  Exit[1]
];
Print["SOLVESECONDS: ", Round[solveSeconds, 0.1]];

{importSeconds, streamDirectory} = AbsoluteTiming[
  FeynFacet`Private`KiraStreamImport[solveData]
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
