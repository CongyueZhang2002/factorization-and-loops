If[Length[$ScriptCommandLine] =!= 4,
  Print["usage: wolframscript -file certify_family_epsform_record.wls WORKING_RESULT V2_SYSTEM OUTPUT"];
  Exit[2]
];

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];

{recordFile, systemFile, outputFile} = Rest[$ScriptCommandLine];
record = FeynFacet`FamilyArtifactRead[recordFile];
system = FeynFacet`FamilyArtifactRead[systemFile];
If[! AssociationQ[record] || ! AssociationQ[system],
  Print["CERTIFY unreadable input record=", AssociationQ[record],
    " system=", AssociationQ[system]];
  Exit[3]
];

systemAbsolutePath = ExpandFileName[systemFile];
rootParts = FileNameSplit[root];
systemPathParts = FileNameSplit[systemAbsolutePath];
systemReferencePath = If[
  Length[systemPathParts] >= Length[rootParts] &&
    Take[systemPathParts, Length[rootParts]] === rootParts,
  <|"RelativePath" ->
    FileNameJoin[Drop[systemPathParts, Length[rootParts]]]|>,
  <|"ExplicitPath" -> systemAbsolutePath|>];
systemReference = Join[systemReferencePath, <|
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> Lookup[system, "Family", Missing["NotGiven"]]|>];
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
