root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
(* fixtures live in the repository (copied 2026-09-02 from the frozen legacy
   tree ~/FACET; the former sibling-directory path failed in any worktree) *)
artifactRoot = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsForms", "Fixtures_2026-08-19"}];

libraRecord = Get[FileNameJoin[{artifactRoot, "family_epsform_CF226.wl"}]];
sectorRecord = Get[FileNameJoin[{artifactRoot, "family_epsform_CF254.wl"}]];
invalidRecord = ReplacePart[sectorRecord, "Flatness" -> False];

tests = <|
  "ExactLibraRecord" -> FeynFacet`ExactFamilyEpsilonFormQ[libraRecord],
  "ExactSectorRecord" -> FeynFacet`ExactFamilyEpsilonFormQ[sectorRecord],
  "RejectedBrokenIdentity" ->
    ! FeynFacet`ExactFamilyEpsilonFormQ[invalidRecord]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
