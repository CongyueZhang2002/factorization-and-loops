root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];

Get[FileNameJoin[{
  root, "Addon", "Mathematica_Addon", "LoadAddons.wl"
}]];

resolved = ExpandFileName /@ $FACETMathematicaAddonEntryPoints;

checks = Map[StringQ[#] && FileExistsQ[#] &, resolved];
checks["InsideFACET"] = And @@ (
  StringStartsQ[
    #,
    FileNameJoin[{root, "Addon", "Mathematica_Addon"}]
  ] & /@ Values[resolved]
);

Print[resolved];
Print[checks];

If[! And @@ Values[checks], Exit[1]];
Exit[0];
