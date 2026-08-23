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
        FeynFacet`ExactFamilyEpsilonFormQ[existing],
      AppendTo[results, <|"Family" -> family, "Status" -> "AlreadyExact",
        "File" -> outputFile, "Seconds" -> 0.|>];
      Print["CERTIFY-CAMPAIGN family=", family, " exact=True cached"];
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
        certified["Status"] === "ExactEpsilonForm" &&
        FeynFacet`ExactFamilyEpsilonFormQ[certified],
      writeAtomic[certified, outputFile];
      elapsed = AbsoluteTime[] - familyStart;
      AppendTo[results, <|"Family" -> family, "Status" -> "Exact",
        "Source" -> candidate, "File" -> outputFile,
        "Seconds" -> elapsed, "Bytes" -> FileByteCount[outputFile]|>];
      Print["CERTIFY-CAMPAIGN family=", family,
        " exact=True seconds=", Round[elapsed, 0.1],
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
      "Status" -> "NoExactlyCertifiedCandidate",
      "Candidates" -> candidates,
      "CandidateDiagnostics" -> candidateDiagnostics,
      "Seconds" -> elapsed|>];
    Print["CERTIFY-CAMPAIGN family=", family,
      " exact=False seconds=", Round[elapsed, 0.1],
      " criteria=", InputForm[DeleteDuplicates[
        Lookup[candidateDiagnostics, "Checks", <||>]]]]
  ];
  Clear[system, record, certified, existing],
  {systemFile, differentialFiles}
];

report = <|
  "Status" -> If[AllTrue[results,
      MemberQ[{"Exact", "AlreadyExact"}, #Status] &],
    "CompleteExactInventory", "IncompleteExactInventory"],
  "DifferentialFamilyCount" -> Length[differentialFiles],
  "ExactFamilyCount" -> Count[results,
    row_ /; MemberQ[{"Exact", "AlreadyExact"}, row["Status"]]],
  "ExactFamilies" -> Lookup[
    Select[results,
      MemberQ[{"Exact", "AlreadyExact"}, #["Status"]] &],
    "Family", {}],
  "IncompleteFamilies" -> Lookup[
    Select[results,
      ! MemberQ[{"Exact", "AlreadyExact"}, #["Status"]] &],
    "Family", {}],
  "ElapsedSeconds" -> AbsoluteTime[] - campaignStart,
  "Results" -> results
|>;
writeAtomic[report, FileNameJoin[{outputDirectory, "certification_report.wl"}]];
Print["CERTIFY-CAMPAIGN exact=", report["ExactFamilyCount"], "/",
  report["DifferentialFamilyCount"], " seconds=",
  Round[report["ElapsedSeconds"], 0.1]];
