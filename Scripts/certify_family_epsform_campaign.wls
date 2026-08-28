If[Length[$ScriptCommandLine] < 5,
  Print["usage: wolframscript -file certify_family_epsform_campaign.wls OUTPUT DE_DIRECTORY INPUT_DIRECTORY ..."];
  Exit[2]
];

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

{outputDirectory, differentialDirectory} =
  ExpandFileName /@ $ScriptCommandLine[[2 ;; 3]];
inputDirectories = ExpandFileName /@ $ScriptCommandLine[[4 ;;]];
If[! DirectoryQ[differentialDirectory] ||
    ! AllTrue[inputDirectories, DirectoryQ],
  Print["CERTIFY-CAMPAIGN input directory missing"];
  Exit[3]
];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

familyName[file_] := First[StringCases[FileBaseName[file],
  StartOfString ~~ "nnlo_de_" ~~ family : ("CF" ~~ DigitCharacter ..) ~~
    EndOfString :> family], Missing["NoFamily"]];

writeAtomic[value_, file_] := Module[{temporary},
  temporary = file <> ".partial-" <> ToString[$ProcessID];
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

differentialFiles = SortBy[
  FileNames["nnlo_de_CF*.wl", differentialDirectory],
  ToExpression[StringDrop[familyName[#], 2]] &
];
results = {};
campaignStart = AbsoluteTime[];

Do[
  family = familyName[systemFile];
  outputFile = FileNameJoin[{outputDirectory,
    "family_epsform_" <> family <> ".wl"}];
  If[FileExistsQ[outputFile],
    existing = FeynFacet`FamilyArtifactRead[outputFile];
    If[AssociationQ[existing] &&
        FeynFacet`CertifiedFamilyEpsilonFormQ[existing],
      acceptedStatus = If[FeynFacet`ExactFamilyEpsilonFormQ[existing],
        "AlreadyExact", "AlreadyCertified"];
      AppendTo[results, <|"Family" -> family, "Status" -> acceptedStatus,
        "File" -> outputFile, "Seconds" -> 0.|>];
      Print["CERTIFY-CAMPAIGN family=", family,
        " certified=True status=", acceptedStatus, " cached"];
      Continue[]
    ]
  ];

  candidates = DeleteDuplicates @ Flatten[
    FileNames["family_epsform_" <> family <> ".wl", #, Infinity] & /@
      inputDirectories
  ];
  If[candidates === {},
    AppendTo[results, <|"Family" -> family,
      "Status" -> "NoCandidate"|>];
    Print["CERTIFY-CAMPAIGN family=", family, " exact=False no-candidate"];
    Continue[]
  ];

  system = FeynFacet`FamilyArtifactRead[systemFile];
  If[! AssociationQ[system],
    AppendTo[results, <|"Family" -> family,
      "Status" -> "SystemUnreadable"|>];
    Print["CERTIFY-CAMPAIGN family=", family, " exact=False system-unreadable"];
    Continue[]
  ];

  accepted = False;
  candidateDiagnostics = {};
  familyStart = AbsoluteTime[];
  Do[
    record = FeynFacet`FamilyArtifactRead[candidate];
    If[! AssociationQ[record],
      AppendTo[candidateDiagnostics, <|
        "Source" -> candidate, "Status" -> "Unreadable"|>];
      Continue[]];
    certified = FeynFacet`CertifyFamilyEpsilonForm[record, system];
    If[AssociationQ[certified] &&
        MemberQ[{"ExactEpsilonForm", "CertifiedEpsilonForm"},
          certified["Status"]] &&
        FeynFacet`CertifiedFamilyEpsilonFormQ[certified],
      writeAtomic[certified, outputFile];
      elapsed = AbsoluteTime[] - familyStart;
      acceptedStatus = If[FeynFacet`ExactFamilyEpsilonFormQ[certified],
        "Exact", "Certified"];
      AppendTo[results, <|"Family" -> family, "Status" -> acceptedStatus,
        "Source" -> candidate, "File" -> outputFile,
        "Seconds" -> elapsed, "Bytes" -> FileByteCount[outputFile]|>];
      Print["CERTIFY-CAMPAIGN family=", family,
        " certified=True status=", acceptedStatus,
        " seconds=", Round[elapsed, 0.1],
        " bytes=", FileByteCount[outputFile]];
      accepted = True;
      Break[],
      AppendTo[candidateDiagnostics, <|
        "Source" -> candidate,
        "Status" -> Lookup[certified, "Status", "NotAnAssociation"],
        "Checks" -> Lookup[certified, "Checks", <||>],
        "Gate" -> Lookup[certified, "Gate", <||>]
      |>]
    ],
    {candidate, candidates}
  ];
  If[! accepted,
    elapsed = AbsoluteTime[] - familyStart;
    AppendTo[results, <|"Family" -> family,
      "Status" -> "NoCertifiedCandidate",
      "Candidates" -> candidates,
      "CandidateDiagnostics" -> candidateDiagnostics,
      "Seconds" -> elapsed|>];
    Print["CERTIFY-CAMPAIGN family=", family,
      " certified=False seconds=", Round[elapsed, 0.1],
      " criteria=", InputForm[DeleteDuplicates[
        Lookup[candidateDiagnostics, "Checks", <||>]]]]
  ];
  Clear[system, record, certified, existing],
  {systemFile, differentialFiles}
];

acceptedStatuses = {"Exact", "AlreadyExact", "Certified",
  "AlreadyCertified"};
report = <|
  "Status" -> If[AllTrue[results,
      MemberQ[acceptedStatuses, #Status] &],
    "CompleteCertifiedInventory", "IncompleteCertifiedInventory"],
  "DifferentialFamilyCount" -> Length[differentialFiles],
  "CertifiedFamilyCount" -> Count[results,
    row_ /; MemberQ[acceptedStatuses, row["Status"]]],
  "CertifiedFamilies" -> Lookup[
    Select[results, MemberQ[acceptedStatuses, #["Status"]] &],
    "Family", {}],
  "ExactFamilyCount" -> Count[results,
    row_ /; MemberQ[{"Exact", "AlreadyExact"}, row["Status"]]],
  "ExactFamilies" -> Lookup[
    Select[results,
      MemberQ[{"Exact", "AlreadyExact"}, #["Status"]] &],
    "Family", {}],
  "IncompleteFamilies" -> Lookup[
    Select[results,
      ! MemberQ[acceptedStatuses, #["Status"]] &],
    "Family", {}],
  "ElapsedSeconds" -> AbsoluteTime[] - campaignStart,
  "Results" -> results
|>;
writeAtomic[report, FileNameJoin[{outputDirectory, "certification_report.wl"}]];
Print["CERTIFY-CAMPAIGN certified=", report["CertifiedFamilyCount"], "/",
  report["DifferentialFamilyCount"], " seconds=",
  Round[report["ElapsedSeconds"], 0.1], " exact=",
  report["ExactFamilyCount"]];
