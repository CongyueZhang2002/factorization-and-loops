If[Length[$ScriptCommandLine] =!= 4,
  Print["usage: wolframscript -file certify_family_epsform_record.wls WORKING_RESULT V2_SYSTEM OUTPUT"];
  Exit[2]
];

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];

{recordFile, systemFile, outputFile} = Rest[$ScriptCommandLine];
(* The per-family chart inventory -- including the legacy chart-alias
   strings that early records carry instead of a catalog name -- is
   project data since 2026-08-23 (generality pass A1/A3); the package
   registry starts empty, so this driver registers the table that travels
   with the differential system it was given. *)
familyChartFile = FileNameJoin[{
  ParentDirectory[DirectoryName[ExpandFileName[systemFile]]],
  "TransportFamilyCharts.wl"}];
If[FileExistsQ[familyChartFile],
  familyChartRegistration = FeynFacet`LoadFamilyRootData[familyChartFile];
  If[Lookup[familyChartRegistration, "Status", None] =!=
      "FamilyRootDataRegistered",
    Print["CERTIFY family chart registration refused: ",
      InputForm[familyChartRegistration]];
    Exit[2]]];
record = FeynFacet`FamilyArtifactRead[recordFile];
system = FeynFacet`FamilyArtifactRead[systemFile];
If[! AssociationQ[record] || ! AssociationQ[system],
  Print["CERTIFY unreadable input record=", AssociationQ[record],
    " system=", AssociationQ[system]];
  Exit[3]
];

systemReference = <|
  "RelativePath" -> FileNameJoin[
    {FileNameTake[DirectoryName[ExpandFileName[systemFile]]],
      FileNameTake[systemFile]}],
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> Lookup[system, "Family", Missing["NotGiven"]]|>;
{seconds, certified} = AbsoluteTiming[
  FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
    record, system, systemReference, "IdentityMethod" -> "Modular"]
];
If[! AssociationQ[certified],
  Print["CERTIFY result is not an Association"];
  Exit[4]
];

If[certified["Status"] === "FamilyDLogEpsilonFormValidated",
  outputDirectory = DirectoryName[ExpandFileName[outputFile]];
  If[! DirectoryQ[outputDirectory],
    CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];
  temporary = outputFile <> ".partial-" <> ToString[$ProcessID];
  Put[certified, temporary];
  RenameFile[temporary, outputFile, OverwriteTarget -> True];
  Print["VALIDATE family=", certified["Family"],
    " validated=True method=", Lookup[
      Lookup[certified, "Validation", <||>], "Method", "Unknown"],
    " seconds=", Round[seconds, 0.1],
    " bytes=", FileByteCount[outputFile]],
  Print["VALIDATE family=", Lookup[certified, "Family", "?"],
    " validated=False status=", certified["Status"],
    " conditions=", InputForm[Lookup[
      Lookup[certified, "Validation", <||>], "Conditions", <||>]],
    " seconds=", Round[seconds, 0.1]];
  Exit[5]
];
