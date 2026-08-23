root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
artifactRoot = FileNameJoin[{DirectoryName[root], "FACET", "Codex", "General"}];

libraRecord = Get[FileNameJoin[{artifactRoot,
  "LibraTwoRoot_20260819", "family_epsform_CF226.wl"}]];
sectorRecord = Get[FileNameJoin[{artifactRoot,
  "CF254Standardized_20260819", "family_epsform_CF254.wl"}]];
invalidRecord = ReplacePart[sectorRecord, "Flatness" -> False];

tests = <|
  "ExactLibraRecord" -> FeynFacet`ExactFamilyEpsilonFormQ[libraRecord],
  "ExactSectorRecord" -> FeynFacet`ExactFamilyEpsilonFormQ[sectorRecord],
  "RejectedBrokenIdentity" ->
    ! FeynFacet`ExactFamilyEpsilonFormQ[invalidRecord]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
