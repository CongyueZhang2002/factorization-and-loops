(* Run the exact Kira reduction on a regenerated NLO result set.
   Usage: wolframscript -file Scripts/reduce_nlo_pairs.wls [resultName] *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

resultName = If[Length[Rest[$ScriptCommandLine]] >= 1,
  First[Rest[$ScriptCommandLine]],
  "UU_08_10_10x10_regen"
];
resultDirectory = FileNameJoin[{root, "ppHX_NLO", "Results", resultName}];
pairFiles = Sort[FileNames[
  "F*_C*.wl", FileNameJoin[{resultDirectory, "Pairs"}]
]];
Print["PAIRFILES: ", Length[pairFiles]];

result = FeynFacet`KiraReduction[
  pairFiles,
  FileNameJoin[{resultDirectory, "KiraResult.wl"}]
];
Print["KIRARESULT: ", result];
If[! StringQ[result], Exit[1]];
