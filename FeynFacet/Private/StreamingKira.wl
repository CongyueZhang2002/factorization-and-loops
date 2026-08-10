(* Streaming Kira reduction: solve/import stage separation, one-family-at-a-time
   rule import, family-wise closure with a disk-backed memo, and a directory
   artifact that replaces the monolithic KiraResult.wl for large reductions.

   Specification: Design/StreamingKiraImport.md.

   Nothing here changes KiraReduction or KiraImportReduction; the three entry
   points below (KiraSolve, KiraStreamImport, KiraStreamResult) are additions
   that reuse the existing Reduction.wl internals stage by stage.

   Stages (each communicates only through on-disk state):

     KiraSolve[inputs, resultDirectory]
       prepares and runs the Kira project exactly as ibpKiraReductionCore does
       and then stops.  The solved workspace is left on disk under
       Codex/<process>/Kira/<run>; the returned Association carries the data an
       importer needs (project handle, family manifest, payload fingerprint,
       targets, completed kinematics).

     KiraStreamImport[solveData]  /  KiraStreamImport[inputs, resultDirectory]
       imports one family's exported rule table at a time, writes it as one WXF
       record, builds the family index, closes the reduction family-wise
       against a memo of the integrals that are actually needed, queries
       kira2math for undeclared frontier integrals, validates the masters, and
       writes <resultDirectory>/KiraStream/.

     KiraStreamResult[streamDirectory]
       compatibility loader.  It MATERIALIZES the whole reduction in memory in
       the schema of a KiraReduction result and is therefore intended for
       NLO-scale reductions and for validation only; large reductions must be
       consumed through the record store instead. *)

$kiraStreamFormat = "FeynFacet-KiraStream";
$kiraStreamVersion = 1;
$kiraStreamContextFormat = "FeynFacet-KiraStreamContext";
$kiraStreamIndexFormat = "FeynFacet-KiraStreamIndex";
$kiraSolveFormat = "FeynFacet-KiraSolve";
$kiraSolveVersion = 1;
$kiraStreamDirectoryName = "KiraStream";

(* Sentinel for "this integral cannot be reduced yet". *)
$kiraStreamUnresolved = "FeynFacetKiraStreamUnresolved";


(* ---------- artifact paths and record helpers ---------------------- *)

kiraStreamFamilyKey[name_Symbol] := SymbolName[name];

kiraStreamFamilyKey[name_] := StringReplace[
  ToString[name, InputForm],
  Except[WordCharacter] -> "_"
];

kiraStreamRuleRelative[key_String] := FileNameJoin[{"Rules", key <> ".wxf"}];

kiraStreamReducedRelative[key_String] :=
  FileNameJoin[{"Reduced", key <> ".wxf"}];

kiraStreamContextRelative[] := "Context.wxf";

kiraStreamIndexRelative[] := "Index.wxf";

kiraStreamManifestFile[directory_String] :=
  FileNameJoin[{directory, "Manifest.wl"}];

kiraStreamWriteRecord[file_String, expression_] := Module[{directory},
  directory = DirectoryName[file];
  If[! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]
  ];
  If[FileExistsQ[file], DeleteFile[file]];
  If[coefficientAppendRecord[file, expression] === $Failed,
    ibpFail[
      "streaming artifact",
      "could not write the record file " <> file
    ]
  ];
  file
];

kiraStreamReadRecord[file_String] := Module[{value},
  If[! FileExistsQ[file],
    ibpFail["streaming artifact", "missing record file " <> file]
  ];
  value = coefficientReadRecord[file];
  If[value === $Failed,
    ibpFail[
      "streaming artifact",
      "could not read the record file " <> file
    ]
  ];
  value
];

kiraStreamFileEntry[directory_String, relative_String] := Module[{file},
  file = FileNameJoin[{directory, relative}];
  If[! FileExistsQ[file],
    ibpFail["streaming artifact", "missing artifact file " <> relative]
  ];
  <|
    "File" -> relative,
    "Bytes" -> FileByteCount[file],
    "Hash" -> FileHash[file, "SHA256", "HexString"]
  |>
];

kiraStreamFileEntryValidQ[directory_String, entry_] := (
  AssociationQ[entry] &&
    StringQ[Lookup[entry, "File", None]] &&
    With[{path = FileNameJoin[{directory, entry["File"]}]},
      FileExistsQ[path] &&
        FileByteCount[path] === entry["Bytes"] &&
        FileHash[path, "SHA256", "HexString"] === entry["Hash"]
    ]
);

(* Everything except the fingerprint itself and the (inexact) diagnostics
   participates in the manifest fingerprint. *)
kiraStreamManifestPayload[manifest_Association] :=
  KeyDrop[manifest, {"ContentFingerprint", "Diagnostics"}];

kiraStreamManifestQ[manifest_, directory_String] := Module[{families, files},
  If[
    ! artifactHeaderQ[manifest, $kiraStreamFormat, $kiraStreamVersion],
    Return[False]
  ];
  If[
    ! ContainsAll[Keys[manifest], {
      "Created", "CardName", "ResultDirectory", "Pairs",
      "Families", "Files", "Masters", "DeclaredMasters",
      "FamilyCount", "TargetCount", "RuleCount", "ImportedRuleCount",
      "ClosureRuleCount", "ReducedIntegralCount", "MasterCount",
      "ReductionInputFingerprint", "SourceInputFingerprint",
      "SolvedProjectFingerprint", "KiraExportClosure",
      "ContextFingerprint", "ContentFingerprint", "Diagnostics"
    }],
    Return[False]
  ];
  If[
    manifest["ContentFingerprint"] =!=
      reductionFingerprint[kiraStreamManifestPayload[manifest]],
    Return[False]
  ];
  If[! exactDataQ[kiraStreamManifestPayload[manifest]], Return[False]];
  families = manifest["Families"];
  files = manifest["Files"];
  ListQ[families] && families =!= {} &&
    AllTrue[families, AssociationQ] &&
    AssociationQ[files] &&
    AllTrue[
      Values[files],
      kiraStreamFileEntryValidQ[directory, #] &
    ] &&
    AllTrue[
      families,
      kiraStreamFileEntryValidQ[directory, #["Rules"]] &&
        kiraStreamFileEntryValidQ[directory, #["Reduced"]] &
    ]
];

kiraStreamReadManifest[directory_String] := Module[{file, manifest},
  If[! DirectoryQ[directory],
    ibpFail[
      "streaming artifact",
      "no streaming reduction directory at " <> directory
    ]
  ];
  file = kiraStreamManifestFile[directory];
  If[! FileExistsQ[file],
    ibpFail["streaming artifact", "missing Manifest.wl in " <> directory]
  ];
  manifest = Quiet @ Check[Get[file], $Failed];
  If[! kiraStreamManifestQ[manifest, directory],
    ibpFail[
      "streaming artifact",
      "the streaming manifest is invalid or its record files were modified"
    ]
  ];
  manifest
];


(* ---------- shared preparation (identical to ibpKiraReductionCore) --- *)

kiraStreamPrepare[inputs_List, resultDirectory_String] := Module[
  {
    data, records, equivalence, targets, representativeNames,
    representatives, completed, runtime, payload, projectLocation
  },
  data = ibpInputData[inputs, True];
  If[
    ibpNormalizedPath[resultDirectory] =!=
      ibpNormalizedPath[data["ResultDirectory"]],
    ibpFail[
      "streaming input validation",
      "the requested result directory is not the directory of the pre-IBP artifacts"
    ]
  ];
  records = data["Records"];
  If[records === {},
    ibpFail[
      "streaming input validation",
      "the streaming reduction requires at least one topology record"
    ]
  ];
  equivalence = TopologyEquivalence[records, data["Setup"]];
  If[! AssociationQ[equivalence],
    ibpFail["topology equivalence", "classification failed"]
  ];
  targets = DeleteDuplicates[
    data["RawTargets"] /. equivalence["GLIRules"],
    SameQ
  ];
  representativeNames = DeleteDuplicates[First /@ targets];
  representatives = Select[
    equivalence["Representatives"],
    MemberQ[representativeNames, #1["Topology"][[1]]] &
  ];
  If[targets === {} || representatives === {},
    ibpFail["target extraction", "the input contains no GLI targets"]
  ];
  completed = ibpCompleteKinematics[
    representatives,
    Lookup[data["AnalyticContext"], "KinematicMassDimensions", <||>]
  ];
  runtime = ibpRuntime[];
  payload = reductionInputPayload[
    completed["KiraFamilies"],
    targets,
    completed["MassDimensions"],
    runtime
  ];
  projectLocation = ibpProjectLocation[data["ResultDirectory"]];
  <|
    "InputData" -> data,
    "TopologyEquivalence" -> equivalence,
    "Targets" -> targets,
    "Completed" -> completed,
    "Runtime" -> runtime,
    "ReductionInputPayload" -> payload,
    "ProjectLocation" -> projectLocation
  |>
];

kiraStreamSolveData[
    prepared_Association,
    project_Association,
    diagnostics_Association
  ] := Module[{data},
  data = prepared["InputData"];
  <|
    "Format" -> $kiraSolveFormat,
    "FormatVersion" -> $kiraSolveVersion,
    "Created" -> DateString[{"ISODate", "T", "Time"}],
    "CardName" -> data["CardName"],
    "ResultDirectory" -> data["ResultDirectory"],
    "StreamDirectory" -> FileNameJoin[{
      data["ResultDirectory"], $kiraStreamDirectoryName
    }],
    "InputData" -> data,
    "TopologyEquivalence" -> prepared["TopologyEquivalence"],
    "Targets" -> prepared["Targets"],
    "Completed" -> prepared["Completed"],
    "Runtime" -> prepared["Runtime"],
    "ProjectLocation" -> prepared["ProjectLocation"],
    "Project" -> project,
    "ProjectRoot" -> project["ProjectRoot"],
    "ProjectDirectory" -> project["Directory"],
    "Manifest" -> project["Manifest"],
    "ReductionInputPayload" -> project["InputPayload"],
    "ReductionInputFingerprint" -> project["InputFingerprint"],
    "SolvedProjectFingerprint" -> ibpSolvedProjectFingerprint[project],
    "Diagnostics" -> diagnostics
  |>
];

kiraSolveDataQ[solveData_] := AssociationQ[solveData] &&
  artifactHeaderQ[solveData, $kiraSolveFormat, $kiraSolveVersion] &&
  ContainsAll[Keys[solveData], {
    "InputData", "TopologyEquivalence", "Targets", "Completed",
    "Runtime", "ProjectLocation", "Project", "Manifest",
    "ReductionInputPayload", "ReductionInputFingerprint",
    "SolvedProjectFingerprint"
  }] &&
  AssociationQ[solveData["Project"]] &&
  ListQ[solveData["Manifest"]] && solveData["Manifest"] =!= {};


(* ---------- stage 1: solve only ------------------------------------- *)

KiraSolve[
    inputs : ({__String} | {__Association}),
    resultDirectory_String
  ] := Catch[
  Module[
    {prepared, location, projectState, project, solveSeconds, solveData},
    prepared = kiraStreamPrepare[inputs, resultDirectory];
    location = prepared["ProjectLocation"];
    projectState = ibpResetProject[
      location["Directory"],
      location["Root"],
      prepared["ReductionInputPayload"],
      prepared["Runtime"]
    ];
    project = ibpPrepareKiraProject[
      prepared["Completed"]["KiraFamilies"],
      prepared["Targets"],
      projectState,
      prepared["Completed"]["MassDimensions"]
    ];
    Print[
      "Running Kira on ", Length[project["Manifest"]], " families (",
      Length[prepared["Targets"]], " targets)"
    ];
    solveSeconds = First @ AbsoluteTiming[ibpRunKira[project]];
    solveData = kiraStreamSolveData[
      prepared,
      project,
      <|
        "SolveSeconds" -> solveSeconds,
        "PeakMemoryInUseBytes" -> MemoryInUse[]
      |>
    ];
    Print @ Grid[
      {
        {"Solved Kira workspace", project["ProjectRoot"]},
        {"Families", Length[project["Manifest"]]},
        {"Targets", Length[prepared["Targets"]]},
        {"Solve time (s)", Round[solveSeconds, 0.01]},
        {"Workspace", "retained for the streaming import"}
      },
      Frame -> All
    ];
    solveData
  ],
  $ibpFailure
];


(* ---------- stage 2-5: streaming import ----------------------------- *)

kiraStreamTablePath[directory_String, item_Association] := FileNameJoin[{
  directory,
  "results",
  ToString[item["Name"], InputForm],
  "kira_integrals_" <> ToString[item["Ordinal"]] <> ".m"
}];

kiraStreamResetDirectory[resultDirectory_String] := Module[{target},
  If[! DirectoryQ[resultDirectory],
    ibpFail[
      "streaming artifact",
      "the result directory does not exist: " <> resultDirectory
    ]
  ];
  target = ibpNormalizedPath[
    FileNameJoin[{resultDirectory, $kiraStreamDirectoryName}]
  ];
  If[
    FileNameTake[target] =!= $kiraStreamDirectoryName ||
      ibpNormalizedPath[DirectoryName[target]] =!=
        ibpNormalizedPath[resultDirectory],
    ibpFail["streaming artifact", "unsafe streaming artifact path"]
  ];
  (* a failed earlier import leaves its staging directory behind *)
  Scan[
    If[DirectoryQ[#], DeleteDirectory[#, DeleteContents -> True]] &,
    FileNames[
      $kiraStreamDirectoryName <> ".building-*",
      ibpNormalizedPath[resultDirectory]
    ]
  ];
  target
];

kiraStreamImportCore[solveData_Association] := Module[
  {
    data, project, projectDirectory, manifest, targets, completed,
    physicalRecords, resultDirectory, streamDirectory, building,
    familyByName, familyKeyByName, familyRows, declaredMasters,
    declaredMasterSet, resolved, inProgress, pendingSet, frontierSet,
    closureRules, table, activeName, expandLinear, resolveLocal,
    round, maxRounds, groups, order, resolvedBefore, progress,
    closureIterations, closureDiagnostics, exportResult, newRules,
    solvedFingerprint, finalFingerprint, importedRuleCount,
    reducedGroups, images, masters, peak, note, stages, addStage,
    importSeconds, closureSeconds, writeSeconds, totalSeconds,
    persistentManifest, closureSummary, context, index, manifestData,
    files, sourceFingerprint, familyCount, cutCheck, key, count,
    ruleAssociation, path, entry, reducedEntry, doneCount
  },

  If[! kiraSolveDataQ[solveData],
    ibpFail[
      "streaming import",
      "the solve stage data is missing or malformed"
    ]
  ];
  data = solveData["InputData"];
  project = solveData["Project"];
  projectDirectory = project["Directory"];
  manifest = project["Manifest"];
  targets = solveData["Targets"];
  completed = solveData["Completed"];
  physicalRecords = completed["PhysicalRecords"];
  resultDirectory = data["ResultDirectory"];
  familyCount = Length[manifest];

  peak = MemoryInUse[];
  note[] := (peak = Max[peak, MemoryInUse[]]);
  stages = {};
  addStage[label_String, seconds_] := AppendTo[
    stages,
    <|
      "Stage" -> label,
      "Seconds" -> seconds,
      "MemoryInUseBytes" -> MemoryInUse[]
    |>
  ];

  (* The solved workspace must still be the one KiraSolve produced. *)
  solvedFingerprint = ibpSolvedProjectFingerprint[project];
  If[
    StringQ[Lookup[solveData, "SolvedProjectFingerprint", None]] &&
      solveData["SolvedProjectFingerprint"] =!= solvedFingerprint,
    ibpFail[
      "streaming import",
      "the solved Kira workspace changed after the solve stage"
    ]
  ];

  familyKeyByName = Association[
    #["Name"] -> kiraStreamFamilyKey[#["Name"]] & /@ manifest
  ];
  If[
    Length[familyKeyByName] =!= familyCount ||
      ! DuplicateFreeQ[Values[familyKeyByName]],
    ibpFail[
      "streaming import",
      "the family names do not map to unique record file names"
    ]
  ];
  familyByName = Association[#["Name"] -> # & /@ manifest];

  streamDirectory = kiraStreamResetDirectory[resultDirectory];
  building = streamDirectory <> ".building-" <> StringTake[CreateUUID[], 8];
  If[DirectoryQ[building], DeleteDirectory[building, DeleteContents -> True]];
  CreateDirectory[building, CreateIntermediateDirectories -> True];

  (* --- stage 1: one family's rule table at a time ------------------ *)
  importedRuleCount = 0;
  doneCount = 0;
  importSeconds = First @ AbsoluteTiming[
    familyRows = Table[
      Module[{item = manifest[[familyIndex]]},
        key = familyKeyByName[item["Name"]];
        path = kiraStreamTablePath[projectDirectory, item];
        table = ibpImportRuleTable[item["Name"], path];
        ibpValidateImportedRuleTable[item["Name"], table];
        cutCheck = validateCutGLIs[table, physicalRecords];
        If[cutCheck =!= True,
          ibpFail[
            "streaming import",
            "an imported reduction table pinches a cut or has an unknown family: " <>
              ToString[Take[cutCheck, UpTo[3]], InputForm]
          ]
        ];
        ruleAssociation = Association[table];
        If[Length[ruleAssociation] =!= Length[table],
          ibpFail[
            "streaming import",
            "a reduction table contains duplicate rows for one integral"
          ]
        ];
        count = Length[ruleAssociation];
        importedRuleCount += count;
        kiraStreamWriteRecord[
          FileNameJoin[{building, kiraStreamRuleRelative[key]}],
          ruleAssociation
        ];
        entry = kiraStreamFileEntry[building, kiraStreamRuleRelative[key]];
        table = <||>;
        ruleAssociation = <||>;
        doneCount++;
        note[];
        Print[
          "Imported ", doneCount, " / ", familyCount,
          " Kira families (", importedRuleCount, " rules; ",
          Round[MemoryInUse[]/1024.^2, 1], " MB in the kernel)"
        ];
        <|
          "Name" -> item["Name"],
          "Key" -> key,
          "Ordinal" -> item["Ordinal"],
          "CutIndices" -> item["CutIndices"],
          "TargetCount" -> Length[item["Targets"]],
          "RuleCount" -> count,
          "Rules" -> entry
        |>
      ],
      {familyIndex, familyCount}
    ]
  ];
  addStage["PerFamilyImport", importSeconds];

  (* --- stage 2: index --------------------------------------------- *)
  declaredMasters = ibpDeclaredMasters[project];
  declaredMasterSet = AssociationThread[
    declaredMasters,
    ConstantArray[True, Length[declaredMasters]]
  ];
  index = <|
    "Format" -> $kiraStreamIndexFormat,
    "FormatVersion" -> $kiraStreamVersion,
    (* Every exported row is validated to have a left-hand side in its own
       family (ibpValidateImportedRuleTable), so the integral -> family map is
       the GLI family argument; it is never materialized. *)
    "IntegralFamilyRouting" -> "FirstArgument",
    "Families" -> Association[
      Function[row,
        row["Name"] -> <|
          "Key" -> row["Key"],
          "Ordinal" -> row["Ordinal"],
          "CutIndices" -> row["CutIndices"],
          "RuleCount" -> row["RuleCount"],
          "RuleFile" -> row["Rules"]["File"],
          "ReducedFile" -> kiraStreamReducedRelative[row["Key"]],
          "DeclaredMasters" -> Select[
            declaredMasters,
            SameQ[#[[1]], row["Name"]] &
          ]
        |>
      ] /@ familyRows
    ],
    "DeclaredMasters" -> declaredMasters
  |>;

  (* --- stage 3: family-wise closure with a memo -------------------- *)
  resolved = <||>;
  inProgress = <||>;
  frontierSet = <||>;
  closureRules = <||>;
  pendingSet = AssociationThread[targets, ConstantArray[True, Length[targets]]];
  closureIterations = 0;
  closureDiagnostics = {};

  expandLinear[integral_, rhs_] := Module[{parts, terms, keys, pieces},
    parts = linearIntegralSum[rhs];
    If[FailureQ[parts],
      ibpFail[
        "streaming closure",
        "a reduction row is not linear in explicit GLI objects: " <>
          ToString[integral, InputForm]
      ]
    ];
    If[! TrueQ[parts["Remainder"] === 0],
      ibpFail[
        "streaming closure",
        "a reduction row has a non-integral remainder: " <>
          ToString[integral, InputForm]
      ]
    ];
    terms = parts["Terms"];
    keys = Keys[terms];
    If[keys === {}, Return[<||>]];
    pieces = resolveLocal /@ keys;
    If[MemberQ[pieces, $kiraStreamUnresolved],
      Return[$kiraStreamUnresolved]
    ];
    Select[
      Merge[
        MapThread[
          Function[{integralKey, image},
            Map[terms[integralKey] # &, image]
          ],
          {keys, pieces}
        ],
        Total
      ],
      ! TrueQ[# === 0] &
    ]
  ];

  resolveLocal[integral_] := Module[{value},
    Which[
      KeyExistsQ[resolved, integral],
        resolved[integral],

      TrueQ[Lookup[inProgress, integral, False]],
        ibpFail[
          "streaming closure",
          "the exported rules are cyclic at " <>
            ToString[integral, InputForm]
        ],

      SameQ[integral[[1]], activeName] && KeyExistsQ[table, integral],
        AssociateTo[inProgress, integral -> True];
        value = expandLinear[integral, table[integral]];
        KeyDropFrom[inProgress, integral];
        If[value === $kiraStreamUnresolved,
          $kiraStreamUnresolved,
          AssociateTo[resolved, integral -> value];
          value
        ],

      KeyExistsQ[closureRules, integral],
        AssociateTo[inProgress, integral -> True];
        value = expandLinear[integral, closureRules[integral]];
        KeyDropFrom[inProgress, integral];
        If[value === $kiraStreamUnresolved,
          $kiraStreamUnresolved,
          AssociateTo[resolved, integral -> value];
          value
        ],

      KeyExistsQ[declaredMasterSet, integral],
        AssociateTo[resolved, integral -> <|integral -> 1|>];
        resolved[integral],

      ! KeyExistsQ[familyByName, integral[[1]]],
        AssociateTo[frontierSet, integral -> True];
        $kiraStreamUnresolved,

      ! SameQ[integral[[1]], activeName],
        (* another family owns it; resolve it when that family is loaded *)
        AssociateTo[pendingSet, integral -> True];
        $kiraStreamUnresolved,

      True,
        (* in the active family, no exported row and not a declared master *)
        AssociateTo[frontierSet, integral -> True];
        $kiraStreamUnresolved
    ]
  ];

  round = 0;
  maxRounds = 8 + 2 familyCount;
  (* resolveLocal/expandLinear recurse along the rule dependency chains;
     NNLO-scale tables can exceed the default $RecursionLimit of 1024. *)
  closureSeconds = First @ AbsoluteTiming @ Block[
    {$RecursionLimit = 2^16},
    While[Length[pendingSet] > 0,
      round++;
      If[round > maxRounds,
        ibpFail[
          "streaming closure",
          "the family-wise closure did not terminate"
        ]
      ];
      groups = GroupBy[Keys[pendingSet], First];
      pendingSet = <||>;
      resolvedBefore = Length[resolved];
      order = Select[Lookup[manifest, "Name"], KeyExistsQ[groups, #] &];
      If[Length[order] =!= Length[groups],
        ibpFail[
          "streaming closure",
          "an unresolved integral belongs to a family without an exported table"
        ]
      ];
      doneCount = 0;
      Do[
        activeName = name;
        table = kiraStreamReadRecord[
          FileNameJoin[{
            building,
            kiraStreamRuleRelative[familyKeyByName[name]]
          }]
        ];
        Scan[
          Function[integral,
            If[resolveLocal[integral] === $kiraStreamUnresolved,
              AssociateTo[pendingSet, integral -> True]
            ]
          ],
          groups[name]
        ];
        table = <||>;
        activeName = Missing["NoActiveFamily"];
        doneCount++;
        note[];
        Print[
          "Closure round ", round, ": ", doneCount, " / ", Length[order],
          " families (", Length[resolved], " integrals reduced; ",
          Round[MemoryInUse[]/1024.^2, 1], " MB in the kernel)"
        ],
        {name, order}
      ];
      progress = Length[resolved] > resolvedBefore;
      If[! progress,
        If[Length[frontierSet] === 0,
          ibpFail[
            "streaming closure",
            "the imported tables do not reduce transitively to terminal integrals"
          ]
        ];
        closureIterations++;
        Print[
          "Exporting ", Length[frontierSet],
          " undeclared frontier integrals from the solved workspace"
        ];
        exportResult = ibpExportClosureFrontier[
          project,
          Keys[frontierSet],
          closureIterations,
          physicalRecords
        ];
        newRules = exportResult["Rules"];
        If[newRules === {},
          ibpFail[
            "streaming closure",
            "a nonempty frontier produced no new reduction rows"
          ]
        ];
        If[
          AnyTrue[First /@ newRules, KeyExistsQ[closureRules, #] &],
          ibpFail[
            "streaming closure",
            "an export-only frontier repeated an existing closure rule"
          ]
        ];
        (* A frontier integral is only classified as such with its own family
           table loaded and the integral absent from it, so the exported rows
           cannot collide with an imported table. *)
        AssociateTo[closureRules, Association[newRules]];
        AppendTo[closureDiagnostics, exportResult["Diagnostic"]];
        pendingSet = Join[pendingSet, frontierSet];
        frontierSet = <||>;
        note[]
      ]
    ]
  ];
  addStage["FamilyWiseClosure", closureSeconds];

  If[Length[frontierSet] > 0,
    ibpFail[
      "streaming closure",
      "the closure finished with unresolved frontier integrals"
    ]
  ];
  If[! AllTrue[targets, KeyExistsQ[resolved, #] &],
    ibpFail["streaming closure", "a target integral was not reduced"]
  ];
  If[closureIterations > 0,
    finalFingerprint = ibpSolvedProjectFingerprint[project];
    If[finalFingerprint =!= solvedFingerprint,
      ibpFail[
        "streaming closure",
        "the solved Kira project changed during export-only closure"
      ]
    ]
  ];

  (* --- stage 4: targets, masters, validation ----------------------- *)
  images = AssociationThread[targets, resolved /@ targets];
  masters = SortBy[
    DeleteDuplicates[Catenate[Keys /@ Values[images]], SameQ],
    ToString[#, InputForm] &
  ];
  cutCheck = validateCutGLIs[Keys[resolved], physicalRecords];
  If[cutCheck =!= True,
    ibpFail[
      "streaming closure",
      "a reduced integral has an unknown family or a pinched cut"
    ]
  ];
  ibpValidateMasters[masters, declaredMasters, physicalRecords];
  If[! exactDataQ[Values[images]],
    ibpFail["streaming closure", "a reduced target image is not exact"]
  ];

  (* --- stage 5: artifact ------------------------------------------- *)
  writeSeconds = First @ AbsoluteTiming[
    reducedGroups = GroupBy[Keys[resolved], First];
    familyRows = Function[row,
      Module[{integrals, memo},
        integrals = Lookup[reducedGroups, row["Name"], {}];
        memo = AssociationThread[integrals, resolved /@ integrals];
        kiraStreamWriteRecord[
          FileNameJoin[{building, kiraStreamReducedRelative[row["Key"]]}],
          memo
        ];
        reducedEntry = kiraStreamFileEntry[
          building,
          kiraStreamReducedRelative[row["Key"]]
        ];
        Append[
          row,
          <|
            "ReducedCount" -> Length[memo],
            "Reduced" -> reducedEntry
          |>
        ]
      ]
    ] /@ familyRows;
    note[];

    persistentManifest = Function[item,
      <|
        "Name" -> item["Name"],
        "CutIndices" -> item["CutIndices"],
        "TargetCount" -> Length[item["Targets"]],
        "Ordinal" -> item["Ordinal"]
      |>
    ] /@ manifest;

    closureSummary = If[
      closureIterations === 0,
      <|
        "Status" -> "AlreadyClosed",
        "InitialRuleCount" -> importedRuleCount,
        "FinalRuleCount" -> importedRuleCount,
        "Iterations" -> {}
      |>,
      <|
        "Status" -> "ClosedByExport",
        "SolvedProjectFingerprint" -> solvedFingerprint,
        "InitialRuleCount" -> importedRuleCount,
        "FinalRuleCount" -> importedRuleCount + Length[closureRules],
        "Iterations" -> closureDiagnostics,
        "TerminalMasterFingerprint" -> reductionFingerprint[masters]
      |>
    ];

    sourceFingerprint = reductionFingerprint[
      sourceInputPayload[
        data["Records"],
        data["RawTargets"],
        data["AnalyticContext"]
      ]
    ];

    context = <|
      "Format" -> $kiraStreamContextFormat,
      "FormatVersion" -> $kiraStreamVersion,
      "CardName" -> data["CardName"],
      "ResultDirectory" -> data["ResultDirectory"],
      "Pairs" -> data["Pairs"],
      "Setup" -> data["Setup"],
      "AnalyticContext" -> data["AnalyticContext"],
      "Targets" -> targets,
      "Masters" -> masters,
      "DeclaredMasters" -> declaredMasters,
      "ReverseRules" -> completed["ReverseRules"],
      "Topologies" -> physicalRecords,
      "TopologyEquivalence" -> solveData["TopologyEquivalence"],
      "MassDimensions" -> completed["MassDimensions"],
      "KiraManifest" -> persistentManifest,
      "KiraExportClosure" -> closureSummary,
      "DimensionRule" -> $dimensionRule,
      "ReductionInputPayload" -> project["InputPayload"],
      "ReductionInputFingerprint" -> project["InputFingerprint"],
      "SourceInputFingerprint" -> sourceFingerprint
    |>;
    kiraStreamWriteRecord[
      FileNameJoin[{building, kiraStreamContextRelative[]}],
      context
    ];
    kiraStreamWriteRecord[
      FileNameJoin[{building, kiraStreamIndexRelative[]}],
      index
    ];
    files = <|
      "Context" -> kiraStreamFileEntry[building, kiraStreamContextRelative[]],
      "Index" -> kiraStreamFileEntry[building, kiraStreamIndexRelative[]]
    |>;
    note[]
  ];
  addStage["ArtifactWrite", writeSeconds];
  totalSeconds = Total[Lookup[stages, "Seconds"]];

  manifestData = <|
      "Format" -> $kiraStreamFormat,
      "FormatVersion" -> $kiraStreamVersion,
      "Created" -> DateString[{"ISODate", "T", "Time"}],
      "CardName" -> data["CardName"],
      "ResultDirectory" -> data["ResultDirectory"],
      "Pairs" -> data["Pairs"],
      "FamilyCount" -> familyCount,
      "TargetCount" -> Length[targets],
      "RuleCount" -> importedRuleCount + Length[closureRules],
      "ImportedRuleCount" -> importedRuleCount,
      "ClosureRuleCount" -> Length[closureRules],
      "ReducedIntegralCount" -> Length[resolved],
      "MasterCount" -> Length[masters],
      "Masters" -> masters,
      "DeclaredMasters" -> declaredMasters,
      "Families" -> familyRows,
      "Files" -> files,
      "KiraExportClosure" -> closureSummary,
      "ReductionInputFingerprint" -> project["InputFingerprint"],
      "SourceInputFingerprint" -> sourceFingerprint,
      "SolvedProjectFingerprint" -> solvedFingerprint,
      "ContextFingerprint" -> reductionFingerprint[context],
      "ContentFingerprint" -> Missing["Pending"],
      "Diagnostics" -> <|
        "Stages" -> stages,
        "TotalSeconds" -> totalSeconds,
        "PeakMemoryInUseBytes" -> peak,
        "PeakMemoryInUseMB" -> N[Round[peak/1024^2, 1/100]],
        "SolveSeconds" -> Lookup[
          Lookup[solveData, "Diagnostics", <||>],
          "SolveSeconds",
          Missing["Retained"]
        ],
        "ClosureIterations" -> closureIterations,
        "ClosureRounds" -> round
      |>
    |>;
  manifestData["ContentFingerprint"] = reductionFingerprint[
    kiraStreamManifestPayload[manifestData]
  ];
  Put[manifestData, kiraStreamManifestFile[building]];

  If[! kiraStreamManifestQ[Get[kiraStreamManifestFile[building]], building],
    ibpFail[
      "streaming artifact",
      "the streaming manifest did not validate after writing"
    ]
  ];

  If[DirectoryQ[streamDirectory],
    DeleteDirectory[streamDirectory, DeleteContents -> True]
  ];
  RenameDirectory[building, streamDirectory];
  If[! DirectoryQ[streamDirectory],
    ibpFail["streaming artifact", "could not publish the streaming artifact"]
  ];
  kiraStreamReadManifest[streamDirectory];

  note[];
  Print @ Grid[
    Join[
      {
        {"Streaming artifact", streamDirectory},
        {"Families", familyCount},
        {"Imported rules", importedRuleCount},
        {"Closure rules", Length[closureRules]},
        {"Reduced integrals", Length[resolved]},
        {"Targets", Length[targets]},
        {"Masters", Length[masters]}
      },
      {#["Stage"] <> " time (s)", N[Round[#["Seconds"], 1/100]]} & /@ stages,
      {{"Peak MemoryInUse (MB)", N[Round[peak/1024^2, 1/100]]}}
    ],
    Frame -> All
  ];
  streamDirectory
];

KiraStreamImport[solveData_Association] := Catch[
  kiraStreamImportCore[solveData],
  $ibpFailure
];

KiraStreamImport[
    inputs : ({__String} | {__Association}),
    resultDirectory_String
  ] := Catch[
  Module[{prepared, project},
    prepared = kiraStreamPrepare[inputs, resultDirectory];
    project = ibpOpenSolvedProject[
      prepared["ProjectLocation"],
      prepared["Completed"]["KiraFamilies"],
      prepared["Targets"],
      prepared["ReductionInputPayload"],
      prepared["Runtime"]
    ];
    Print["Using the retained solved Kira workspace"];
    kiraStreamImportCore[
      kiraStreamSolveData[
        prepared,
        project,
        <|"SolveSeconds" -> Missing["Retained"]|>
      ]
    ]
  ],
  $ibpFailure
];


(* ---------- compatibility loader ------------------------------------ *)

(* KiraStreamResult materializes the complete reduction (all rules, all master
   coefficients) in one Association with the schema of a KiraReduction result.
   It is intended for NLO-scale reductions and for validating the streaming
   pipeline against a monolithic KiraResult.wl.  Large reductions must be read
   family by family through the record store instead. *)

kiraStreamLinearToExpression[image_Association] :=
  Total[KeyValueMap[#2 #1 &, image]];

KiraStreamResult[streamDirectory_String] := Catch[
  Module[
    {
      directory, manifest, context, reduced, targets, images, rules,
      masters, storedMasters, result
    },
    directory = ibpNormalizedPath[streamDirectory];
    manifest = kiraStreamReadManifest[directory];
    context = kiraStreamReadRecord[
      FileNameJoin[{directory, manifest["Files"]["Context"]["File"]}]
    ];
    If[
      ! artifactHeaderQ[
          context, $kiraStreamContextFormat, $kiraStreamVersion
        ] ||
        reductionFingerprint[context] =!= manifest["ContextFingerprint"],
      ibpFail[
        "streaming artifact",
        "the streaming context record does not match its manifest"
      ]
    ];
    reduced = Join @@ Map[
      Function[row,
        kiraStreamReadRecord[
          FileNameJoin[{directory, row["Reduced"]["File"]}]
        ]
      ],
      manifest["Families"]
    ];
    If[Length[reduced] =!= manifest["ReducedIntegralCount"],
      ibpFail[
        "streaming artifact",
        "the reduced records do not hold the recorded number of integrals"
      ]
    ];
    targets = context["Targets"];
    If[! AllTrue[targets, KeyExistsQ[reduced, #] &],
      ibpFail[
        "streaming artifact",
        "a target integral is missing from the reduced records"
      ]
    ];
    images = AssociationThread[targets, reduced /@ targets];
    masters = SortBy[
      DeleteDuplicates[Flatten[Keys /@ Values[images]], SameQ],
      ToString[#, InputForm] &
    ];
    storedMasters = context["Masters"];
    If[
      Sort[ToString[#, InputForm] & /@ masters] =!=
        Sort[ToString[#, InputForm] & /@ storedMasters],
      ibpFail[
        "streaming artifact",
        "the stored master list disagrees with the reduced target images"
      ]
    ];
    rules = DeleteCases[
      KeyValueMap[
        Function[{target, image},
          If[
            image === <|target -> 1|>,
            Nothing,
            target -> kiraStreamLinearToExpression[image]
          ]
        ],
        images
      ],
      Nothing
    ];
    result = Join[
      resultHeader["FeynFacet-KiraReduction", 4],
      KeyTake[
        context,
        {"CardName", "ResultDirectory", "Pairs", "Setup", "AnalyticContext"}
      ],
      <|
        "Targets" -> targets,
        "Masters" -> storedMasters,
        "DeclaredMasters" -> context["DeclaredMasters"],
        "KiraRules" -> rules,
        "ReverseRules" -> context["ReverseRules"],
        "Topologies" -> context["Topologies"],
        "TopologyEquivalence" -> context["TopologyEquivalence"],
        "MassDimensions" -> context["MassDimensions"],
        "KiraManifest" -> context["KiraManifest"],
        "KiraExportClosure" -> context["KiraExportClosure"],
        "DimensionRule" -> context["DimensionRule"],
        "ReductionInputPayload" -> context["ReductionInputPayload"],
        "ReductionInputFingerprint" -> context["ReductionInputFingerprint"],
        "SourceInputFingerprint" -> context["SourceInputFingerprint"],
        "KiraStreamDirectory" -> directory,
        "KiraStreamCreated" -> manifest["Created"]
      |>
    ];
    If[! kiraReductionQ[result],
      ibpFail[
        "streaming artifact",
        "the loaded streaming reduction does not satisfy the KiraReduction schema"
      ]
    ];
    result
  ],
  $ibpFailure
];
