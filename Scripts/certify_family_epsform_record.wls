If[Length[$ScriptCommandLine] =!= 4,
  Print["usage: wolframscript -file certify_family_epsform_record.wls RECORD SYSTEM OUTPUT"];
  Exit[2]
];

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

{recordFile, systemFile, outputFile} = Rest[$ScriptCommandLine];
record = FeynFacet`FamilyArtifactRead[recordFile];
system = FeynFacet`FamilyArtifactRead[systemFile];
If[! AssociationQ[record] || ! AssociationQ[system],
  Print["CERTIFY unreadable input record=", AssociationQ[record],
    " system=", AssociationQ[system]];
  Exit[3]
];

{seconds, certified} = AbsoluteTiming[
  FeynFacet`CertifyFamilyEpsilonForm[record, system]
];
If[! AssociationQ[certified],
  Print["CERTIFY result is not an Association"];
  Exit[4]
];

If[certified["Status"] === "ExactEpsilonForm" &&
    FeynFacet`ExactFamilyEpsilonFormQ[certified],
  outputDirectory = DirectoryName[ExpandFileName[outputFile]];
  If[! DirectoryQ[outputDirectory],
    CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];
  temporary = outputFile <> ".partial-" <> ToString[$ProcessID];
  Put[certified, temporary];
  RenameFile[temporary, outputFile, OverwriteTarget -> True];
  Print["CERTIFY family=", certified["Family"],
    " exact=True seconds=", Round[seconds, 0.1],
    " bytes=", FileByteCount[outputFile]],
  Print["CERTIFY family=", Lookup[certified, "Family", "?"],
    " exact=False status=", certified["Status"],
    " checks=", InputForm[Lookup[certified, "Checks", <||>]],
    " seconds=", Round[seconds, 0.1]];
  Exit[5]
];
