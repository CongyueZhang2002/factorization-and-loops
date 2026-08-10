(* Kira reduction, sparse master reconstruction, and artifact output. *)

(* Persisted pre-IBP inputs. *)

KiraReduction::input =
  "KiraReduction expects valid pre-IBP result Associations or saved result files and an output .wl path.";

KiraImportReduction::input =
  "KiraImportReduction expects valid pre-IBP result Associations or saved result files, a matching solved Kira workspace, and an output .wl path.";

KiraReduction::stage =
  "Reduction failed during `1`: `2`.";

KiraReduction::save =
  "KiraReduction could not write and verify the compact reduction artifact `1`. The temporary Kira workspace was retained.";

CoefficientSimplification::input =
  "CoefficientSimplification expects the original pre-IBP result list and its matching FeynFacet-KiraReduction Association.";

$ibpFailure = "FeynFacetIBPFailure";


ibpFail[stage_, detail_] := (
  Message[KiraReduction::stage, stage, detail];
  Throw[$Failed, $ibpFailure]
);

validPreIBPResultQ[result_] := Module[{pair, context},
  If[
    ! artifactHeaderQ[
        result,
        "FeynFacet-CollinearFactorizePreIBP",
        4
      ] ||
      ! And @@ (KeyExistsQ[result, #] & /@ {
        "CardName", "Pair", "Setup", "FractionMeasure",
        "PreFactor", "PhaseSpace", "Integrand", "Topologies",
        "ResultDirectory", "AnalyticContext", "ExpressionForm"
      }),
    Return[False]
  ];
  pair = result["Pair"];
  context = result["AnalyticContext"];
  AssociationQ[pair] &&
    result["ExpressionForm"] === "FeynCalcExternal" &&
    feynFacetFormQ @ Lookup[result, {
      "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand"
    }] &&
    IntegerQ[Lookup[pair, "Forward", None]] &&
    IntegerQ[Lookup[pair, "Conjugate", None]] &&
    analyticContextQ[context] &&
    ListQ[result["Topologies"]] &&
    AllTrue[
      result["Topologies"],
      topologyRecordQ[#, pair] &&
        SameQ[#1["AnalyticContext"], context] &
    ] &&
    exactDataQ @ Lookup[result, {
      "Setup", "FractionMeasure", "PreFactor", "PhaseSpace",
      "Integrand", "Topologies", "AnalyticContext"
    }]
];

kiraReductionQ[kira_] := Module[{required},
  required = {
    "CardName", "Pairs", "ResultDirectory", "AnalyticContext",
    "Targets", "Masters", "KiraRules", "ReverseRules",
    "Topologies", "TopologyEquivalence",
    "MassDimensions", "KiraManifest",
    "DimensionRule", "ReductionInputPayload",
    "ReductionInputFingerprint", "SourceInputFingerprint"
  };
  artifactHeaderQ[kira, "FeynFacet-KiraReduction", 4] &&
    ContainsAll[Keys[kira], required] &&
    ! KeyExistsQ[kira, "ReductionRules"] &&
    analyticContextQ[kira["AnalyticContext"]] &&
    kira["DimensionRule"] === $dimensionRule
];

validateCutGLIs[expression_, records_List] := Module[
  {recordByName, glis, bad},
  recordByName = Association[
    #1["Topology"][[1]] -> #1 & /@ records
  ];
  glis = DeleteDuplicates @ Cases[
    HoldComplete[expression],
    _FeynCalc`GLI,
    Infinity
  ];
  bad = Select[glis, Function[gli, Module[{record, indices},
    record = Lookup[recordByName, gli[[1]], Missing["UnknownFamily"]];
    If[! AssociationQ[record], Return[True]];
    indices = gli[[2]];
    Length[indices] =!= Length[record["Topology"][[2]]] ||
      ! AllTrue[
        indices[[record["CutIndices"]]],
        IntegerQ[#] && # > 0 &
      ]
  ]]];
  If[bad === {}, True, bad]
];

ibpBaseSetup[setup_Association] := Join[
  setup,
  <|
    "ForwardAmplitudes" -> KeyDrop[
      Lookup[setup, "ForwardAmplitudes", <||>],
      "SelectedIndex"
    ],
    "ConjugateAmplitudes" -> KeyDrop[
      Lookup[setup, "ConjugateAmplitudes", <||>],
      "SelectedIndex"
    ]
  |>
];

ibpInputSummary[item_, includeTargets_] := Module[
  {file, result, directory},
  file = If[StringQ[item], ExpandFileName[item], Missing["InMemory"]];
  If[StringQ[item] && ! FileExistsQ[file], Return[$Failed]];
  result = If[StringQ[item], Quiet @ Check[Get[file], $Failed], item];
  If[! validPreIBPResultQ[result], Return[$Failed]];
  directory = Lookup[result, "ResultDirectory", Missing[]];
  If[! StringQ[directory] || ! DirectoryQ[directory],
    directory = If[StringQ[file], DirectoryName[DirectoryName[file]], $Failed]
  ];
  If[directory === $Failed || ! DirectoryQ[directory], Return[$Failed]];
  <|
    "CardName" -> result["CardName"],
    "Pair" -> result["Pair"],
    "Setup" -> ibpBaseSetup[result["Setup"]],
    "FractionMeasure" -> result["FractionMeasure"],
    "PhaseSpace" -> result["PhaseSpace"],
    "AnalyticContext" -> result["AnalyticContext"],
    "ResultDirectory" -> ExpandFileName[directory],
    "CanonicalRegistryFingerprint" -> Lookup[
      result,
      "CanonicalRegistryFingerprint",
      Missing["NotCanonicalized"]
    ],
    "Records" -> result["Topologies"],
    "Targets" -> If[TrueQ[includeTargets],
      DeleteDuplicates[
        Cases[result["Integrand"], _FeynCalc`GLI, {0, Infinity}]
      ],
      {}
    ],
    "Source" -> If[StringQ[file], file, result]
  |>
];

(* Canonicalized artifacts declare one record per canonical family, so the
   same record repeats across pairs. Records that share a name and agree on
   everything but their pair bookkeeping are one record; a name shared by
   records that differ stays a hard failure. Legacy artifacts have pairwise
   distinct record names, so this is the identity on them. *)
ibpDedupedRecords[records_List] := KeyValueMap[
  Function[{name, group},
    If[
      ! SameQ @@ (KeyDrop[#, {"DiagramPair", "Created"}] & /@ group),
      ibpFail[
        "input validation",
        "topology records named " <> ToString[name, InputForm] <>
          " differ beyond their diagram pair"
      ]
    ];
    (* The kept representative must not depend on the source file
       ordering: its DiagramPair and Created enter the stored
       SourceInputFingerprint, and different drivers order the pair
       files differently (lexicographic vs numeric). Keep the member
       with the least diagram pair. *)
    First @ SortBy[
      group,
      {
        Lookup[#["DiagramPair"], "Forward", Infinity] &,
        Lookup[#["DiagramPair"], "Conjugate", Infinity] &,
        ToString[Lookup[#, "Created", ""], InputForm] &
      }
    ]
  ],
  GroupBy[records, #1["Topology"][[1]] &]
];

ibpInputData[items_List, includeTargets_: False] := Module[
  {summaries, unique, pairs, data, fingerprints, canonicalized},
  If[items === {} || ! (AllTrue[items, AssociationQ] || AllTrue[items, StringQ]),
    ibpFail["input validation", "expected nonempty Associations or saved result files"]
  ];
  summaries = ibpInputSummary[#, includeTargets] & /@ items;
  If[MemberQ[summaries, $Failed],
    ibpFail["input validation", "a pre-IBP result is missing, invalid or has no result directory"]
  ];
  pairs = Lookup[summaries, "Pair"];
  If[! DuplicateFreeQ[pairs],
    ibpFail["input validation", "diagram pairs must be unique"]
  ];
  unique[key_] := DeleteDuplicates[Lookup[summaries, key], SameQ];
  If[! AllTrue[
      {
        "CardName", "Setup", "FractionMeasure", "PhaseSpace",
        "ResultDirectory", "AnalyticContext"
      },
      Length[unique[#]] === 1 &
    ],
    ibpFail["input validation", "results do not share one card, setup, measure and directory"]
  ];
  data = AssociationMap[First[unique[#]] &,
    {
      "CardName", "Setup", "FractionMeasure", "PhaseSpace",
      "ResultDirectory", "AnalyticContext"
    }
  ];
  fingerprints = Lookup[summaries, "CanonicalRegistryFingerprint"];
  canonicalized = AllTrue[fingerprints, StringQ] &&
    Length[DeleteDuplicates[fingerprints]] === 1;
  Join[data, <|
    "Pairs" -> pairs,
    "Records" -> ibpDedupedRecords[
      Flatten[Lookup[summaries, "Records"], 1]
    ],
    "RawTargets" -> DeleteDuplicates[Flatten[Lookup[summaries, "Targets"], 1]],
    "Sources" -> Lookup[summaries, "Source"],
    "Canonicalized" -> canonicalized,
    "CanonicalRegistryFingerprint" -> If[
      canonicalized,
      First[fingerprints],
      Missing["NotCanonicalized"]
    ]
  |>]
];

(* Canonicalized inputs already carry the partition: every record is its own
   class and no GLI has to move. The conservative pairwise search is only
   needed for legacy inputs. *)
ibpTopologyEquivalenceForData[data_Association] := Module[{records, classes},
  records = data["Records"];
  If[! TrueQ[data["Canonicalized"]],
    Return[TopologyEquivalence[records, data["Setup"]]]
  ];
  classes = Function[record,
    <|
      "Representative" -> record["Topology"][[1]],
      "Members" -> {record["Topology"][[1]]},
      "SearchStatus" -> "Canonical"
    |>
  ] /@ records;
  Print @ Grid[
    Prepend[
      {#1["Representative"], 1, #1["Members"]} & /@ classes,
      {"Representative", "Count", "Members"}
    ],
    Frame -> All
  ];
  <|
    "Scope" -> "CutAwareIBP",
    "SearchStatus" -> "CanonicalIdentity",
    "Representatives" -> records,
    "Classes" -> classes,
    "Mappings" -> {},
    "GLIRules" -> {},
    "RejectedCandidateMappings" -> {}
  |>
];

(* Kira-only completion of scalar-product kinematics. *)
ibpCompleteKinematics[records_List, dimensionMap_Association] := Module[
  {
    topologies, externalLists, loopLists, ruleLists, external,
    baseRules, pairs, missingPairs, generatedData,
    generatedRules, reverseRules, augmentedTopologies,
    kiraFamilies, invariants, generatedInvariants, missingDimensions,
    massDimensions, symbolPrefix
  },

  topologies = Lookup[records, "Topology"];
  externalLists = #[[4]] & /@ topologies;
  loopLists = #[[3]] & /@ topologies;
  ruleLists = #[[5]] & /@ topologies;
  If[
    Length[DeleteDuplicates[externalLists, SameQ]] =!= 1 ||
      Length[DeleteDuplicates[loopLists, SameQ]] =!= 1 ||
      Length[DeleteDuplicates[ruleLists, SameQ]] =!= 1,
    ibpFail[
      "kinematic completion",
      "representative topologies do not share one external basis"
    ]
  ];
  external = First[externalLists];
  baseRules = First[ruleLists];
  (* Fermat silently stalls on long invariant identifiers. *)
  symbolPrefix = "Global`f" <>
    StringTake[reductionFingerprint[{external, baseRules}], 4] <> "p";
  pairs = Flatten[
    Table[{external[[i]], external[[j]]},
      {i, Length[external]}, {j, i, Length[external]}],
    1
  ];
  missingPairs = Select[
    pairs,
    Function[pair,
      With[{lhs = FeynCalc`FCI[FeynCalc`SPD @@ pair]},
        SameQ[lhs /. baseRules, lhs]
      ]
    ]
  ];
  generatedData = MapIndexed[
    Function[{pair, position}, Module[{lhs, invariant, physical},
      lhs = FeynCalc`FCI[FeynCalc`SPD @@ pair];
      invariant = Symbol[symbolPrefix <> ToString[First[position]]];
      If[
        ! With[
          {candidate = invariant},
          OwnValues[candidate] === {} && DownValues[candidate] === {} &&
            UpValues[candidate] === {} && SubValues[candidate] === {}
        ],
        ibpFail[
          "kinematic completion",
          "generated invariant already has definitions: " <>
            ToString[invariant, InputForm]
        ]
      ];
      physical = If[
        SameQ[pair[[1]], pair[[2]]],
        FeynCalc`SPD[pair[[1]]],
        2 FeynCalc`SPD[pair[[1]], pair[[2]]]
      ];
      <|
        "Forward" -> (lhs -> If[
          SameQ[pair[[1]], pair[[2]]],
          invariant,
          invariant/2
        ]),
        "Reverse" -> (invariant -> physical)
      |>
    ]],
    missingPairs
  ];
  generatedRules = If[
    generatedData === {},
    {},
    Lookup[generatedData, "Forward"]
  ];
  reverseRules = If[
    generatedData === {},
    {},
    Lookup[generatedData, "Reverse"]
  ];

  augmentedTopologies = Replace[
    topologies,
    FeynCalc`FCTopology[
        name_, propagators_, loops_, ext_, rules_, options_
      ] :> FeynCalc`FCTopology[
        name,
        propagators,
        loops,
        ext,
        DeleteDuplicates[Join[rules, generatedRules]],
        options
      ],
    {1}
  ];
  If[
    ! AllTrue[
      augmentedTopologies,
      completeTopologyQ
    ],
    ibpFail[
      "kinematic completion",
      "the completed FCTopology basis is invalid or incomplete"
    ]
  ];
  invariants = FeynCalc`FCLoopGetKinematicInvariants[
    augmentedTopologies,
    Check -> False,
    FeynCalc`FCFeynmanPrepare -> False,
    FeynCalc`FCVerbose -> -1,
    Union -> True
  ];
  invariants = DeleteCases[Flatten[{invariants}], 0 | 1];
  invariants = DeleteDuplicates[invariants];
  generatedInvariants = First /@ reverseRules;
  missingDimensions = Select[
    Complement[invariants, generatedInvariants],
    ! KeyExistsQ[dimensionMap, #] &
  ];
  If[missingDimensions =!= {},
    ibpFail[
      "kinematic completion",
      "missing mass dimensions for " <>
        ToString[missingDimensions, InputForm]
    ]
  ];
  massDimensions = (# -> If[
        MemberQ[generatedInvariants, #],
        2,
        dimensionMap[#]
      ]) & /@ invariants;
  kiraFamilies = MapThread[
    <|"Topology" -> #2, "CutIndices" -> #1["CutIndices"]|> &,
    {records, augmentedTopologies}
  ];

  <|
    "PhysicalRecords" -> records,
    "KiraFamilies" -> kiraFamilies,
    "MassDimensions" -> massDimensions,
    "ReverseRules" -> reverseRules
  |>
];

ibpInsertCuts[path_String, cutIndices_List] := Module[
  {lines, position},
  lines = Import[path, "Lines"];
  lines = DeleteCases[
    lines,
    line_String /;
      StringStartsQ[StringTrim[line], "cut_propagators:"]
  ];
  position = FirstPosition[
    lines,
    line_String /;
      StringStartsQ[StringTrim[line], "top_level_sectors:"]
  ];
  If[MissingQ[position],
    ibpFail["Kira configuration", "missing top_level_sectors"]
  ];
  lines = Insert[
    lines,
    "    cut_propagators: [" <>
      StringRiffle[ToString /@ Sort[cutIndices], ", "] <> "]",
    position[[1]] + 1
  ];
  Export[path, StringRiffle[lines, "\n"] <> "\n", "String"];
];

(* Runtime identity and cache state. *)
packageVersion[name_String] := If[
  Names[name] === {},
  Missing["NotAvailable"],
  Quiet @ Check[Symbol[name], Missing["NotAvailable"]]
];

ibpRuntime[] := Module[{kira, fermat, supportFile},
  kira = If[
    ValueQ[Global`$FACETKiraExecutable],
    Global`$FACETKiraExecutable,
    FileNameJoin[{
      $feynFacetRoot, "Addon", "Other_Addon", "Kira", "bin", "kira"
    }]
  ];
  fermat = If[
    ValueQ[Global`$FACETFermatExecutable],
    Global`$FACETFermatExecutable,
    FileNameJoin[{DirectoryName[kira], "fer64"}]
  ];
  supportFile = FileNameJoin[{DirectoryName[fermat], "BACKWARD", "chdat"}];
  If[
    ! FileExistsQ[kira] || ! FileExistsQ[fermat] || ! FileExistsQ[supportFile],
    ibpFail[
      "Kira launch",
      "the complete Kira/Fermat runtime is not installed"
    ]
  ];
  <|
    "KiraExecutable" -> ExpandFileName[kira],
    "KiraExecutableHash" -> FileHash[kira, "SHA256"],
    "FermatExecutable" -> ExpandFileName[fermat],
    "FermatExecutableHash" -> FileHash[fermat, "SHA256"],
    "SupportFile" -> ExpandFileName[supportFile],
    "SupportFileHash" -> FileHash[supportFile, "SHA256"]
  |>
];

reductionInputPayload[
    records_List,
    targets_List,
    massDimensions_List,
    runtime_Association
  ] := <|
  "SchemaVersion" -> 2,
  "Topologies" -> SortBy[records, ToString[InputForm[#1["Topology"][[1]]]] &],
  "Targets" -> SortBy[targets, ToString[InputForm[#]] &],
  "MassDimensions" -> SortBy[massDimensions, ToString[InputForm[First[#]]] &],
  "IntegralOrdering" -> 2,
  "Runtime" -> runtime,
  "FeynFacetSourceHash" -> $feynFacetSourceHash,
  "FeynCalcVersion" -> packageVersion["FeynCalc`$FeynCalcVersion"],
  "FeynHelpersVersion" -> packageVersion["FeynHelpers`$FeynHelpersVersion"]
|>;

sourceInputPayload[records_List, targets_List, context_Association] := <|
  "SchemaVersion" -> 2,
  "TopologyRecords" -> SortBy[
    records,
    ToString[InputForm[#1["Topology"][[1]]]] &
  ],
  "Targets" -> SortBy[targets, ToString[InputForm[#]] &],
  "AnalyticContext" -> context
|>;

ibpNormalizedPath[path_String] :=
  FileNameJoin @ FileNameSplit @ ExpandFileName[path];

ibpProjectLocation[resultDirectory_String] := Module[
  {rootParts, resultParts, relativeParts, process, run, projectRoot},
  rootParts = FileNameSplit[ExpandFileName[$feynFacetRoot]];
  resultParts = FileNameSplit[ExpandFileName[resultDirectory]];
  If[
    Length[resultParts] <= Length[rootParts] ||
      Take[resultParts, Length[rootParts]] =!= rootParts,
    ibpFail["project setup", "the result directory is outside FACET"]
  ];
  relativeParts = Drop[resultParts, Length[rootParts]];
  process = If[
    First[relativeParts] === "Codex" && Length[relativeParts] > 1,
    relativeParts[[2]],
    First[relativeParts]
  ];
  run = Last[relativeParts];
  projectRoot = FileNameJoin[{
    $feynFacetRoot, "Codex", process, "Kira"
  }];
  If[! DirectoryQ[projectRoot],
    CreateDirectory[projectRoot, CreateIntermediateDirectories -> True]
  ];
  <|
    "Root" -> projectRoot,
    "Directory" -> FileNameJoin[{projectRoot, run}]
  |>
];

ibpResetProject[
    projectDirectory_String,
    allowedRoot_String,
    payload_Association,
    runtime_Association
  ] := Module[
  {
    root, project, payloadPath, fingerprintPath, fingerprint
  },
  root = FileNameJoin[FileNameSplit[ExpandFileName[allowedRoot]]];
  project = FileNameJoin[FileNameSplit[ExpandFileName[projectDirectory]]];
  If[! DirectoryQ[root],
    ibpFail["project setup", "the result directory does not exist"]
  ];
  If[
    project === root || ! StringStartsQ[
      project <> $PathnameSeparator,
      root <> $PathnameSeparator
    ],
    ibpFail["project setup", "unsafe IBP project path"]
  ];
  payloadPath = FileNameJoin[{project, "reduction_input.wxf"}];
  fingerprintPath = FileNameJoin[{project, "reduction_input.sha256"}];
  fingerprint = reductionFingerprint[payload];
  If[DirectoryQ[project],
    DeleteDirectory[project, DeleteContents -> True]
  ];
  CreateDirectory[project, CreateIntermediateDirectories -> True];
  Export[payloadPath, payload, "WXF"];
  Export[fingerprintPath, fingerprint <> "\n", "String"];
  <|
    "Directory" -> project,
    "InputPayload" -> payload,
    "InputFingerprint" -> fingerprint,
    "Runtime" -> runtime
  |>
];

ibpOpenSolvedProject[
    location_Association,
    records_List,
    targets_List,
    expectedPayload_Association,
    runtime_Association
  ] := Module[
  {
    projectRoot, combinedDirectory, payloadPath, fingerprintPath,
    storedPayload, storedFingerprint, manifest, topology, name,
    familyTargets, familyDirectory, requiredFiles
  },
  projectRoot = ibpNormalizedPath[location["Directory"]];
  combinedDirectory = FileNameJoin[{projectRoot, "kira"}];
  payloadPath = FileNameJoin[{projectRoot, "reduction_input.wxf"}];
  fingerprintPath = FileNameJoin[{
    projectRoot, "reduction_input.sha256"
  }];
  If[
    ! DirectoryQ[projectRoot] || ! DirectoryQ[combinedDirectory] ||
      ! FileExistsQ[payloadPath] || ! FileExistsQ[fingerprintPath],
    ibpFail[
      "solved-project import",
      "the matching solved Kira workspace is incomplete"
    ]
  ];
  storedPayload = Quiet @ Check[Import[payloadPath, "WXF"], $Failed];
  storedFingerprint = StringTrim @ Quiet @ Check[
    Import[fingerprintPath, "Text"],
    ""
  ];
  If[
    ! AssociationQ[storedPayload] || storedFingerprint === "" ||
      reductionFingerprint[storedPayload] =!= storedFingerprint,
    ibpFail[
      "solved-project import",
      "the stored reduction payload is invalid"
    ]
  ];
  If[
    ! SameQ[
      KeyDrop[storedPayload, "FeynFacetSourceHash"],
      KeyDrop[expectedPayload, "FeynFacetSourceHash"]
    ],
    ibpFail[
      "solved-project import",
      "the solved workspace does not match the current topologies, targets, dimensions, or Kira runtime"
    ]
  ];
  manifest = MapIndexed[
    Function[{record, position},
      topology = record["Topology"];
      name = topology[[1]];
      familyTargets = Select[targets, SameQ[#[[1]], name] &];
      familyDirectory = FileNameJoin[{
        projectRoot, "families", ToString[name, InputForm]
      }];
      <|
        "Name" -> name,
        "Directory" -> familyDirectory,
        "Targets" -> familyTargets,
        "CutIndices" -> Sort[record["CutIndices"]],
        "Ordinal" -> First[position]
      |>
    ],
    records
  ];
  If[
    manifest === {} ||
      ! DuplicateFreeQ[Lookup[manifest, "Name"], SameQ] ||
      MemberQ[Lookup[manifest, "Targets"], {}],
    ibpFail[
      "solved-project import",
      "the current family manifest cannot reconstruct the solved project"
    ]
  ];
  requiredFiles = Join[
    {
      FileNameJoin[{combinedDirectory, "jobs.yaml"}],
      FileNameJoin[{combinedDirectory, "results", "kira.db"}]
    },
    Flatten @ Map[
      Function[item,
        {
          FileNameJoin[{
            combinedDirectory,
            "results",
            ToString[item["Name"], InputForm],
            "kira_integrals_" <> ToString[item["Ordinal"]] <> ".m"
          }],
          FileNameJoin[{
            combinedDirectory,
            "results",
            ToString[item["Name"], InputForm],
            "masters.final"
          }]
        }
      ],
      manifest
    ]
  ];
  If[! AllTrue[requiredFiles, FileExistsQ],
    ibpFail[
      "solved-project import",
      "the solved workspace is missing an exported rule table or master list"
    ]
  ];
  <|
    "ProjectRoot" -> projectRoot,
    "Directory" -> combinedDirectory,
    "Manifest" -> manifest,
    "InputPayload" -> storedPayload,
    "InputFingerprint" -> storedFingerprint,
    "Runtime" -> runtime
  |>
];

(* Kira project generation and execution. *)
ibpPrepareKiraProject[
    records_List,
    targets_List,
    projectState_Association,
    massDimensions_List
  ] := Module[
  {
    familyRoot, combinedDirectory, manifest, record, topology,
    name, familyTargets, familyDirectory, cutIndices, familyBlocks,
    kinematics, reduceLines, jobLines
  },

  familyRoot = FileNameJoin[{projectState["Directory"], "families"}];
  combinedDirectory = FileNameJoin[{projectState["Directory"], "kira"}];
  If[
    ! DirectoryQ[familyRoot],
    CreateDirectory[familyRoot, CreateIntermediateDirectories -> True]
  ];

  manifest = Table[
    record = records[[index]];
    topology = record["Topology"];
    name = topology[[1]];
    cutIndices = Sort[record["CutIndices"]];
    familyTargets = Select[targets, SameQ[#[[1]], name] &];
    If[familyTargets === {},
      ibpFail["Kira target construction", "empty target family"]
    ];
    If[
      ! AllTrue[
        familyTargets,
        AllTrue[#[[2, cutIndices]], IntegerQ[#] && # > 0 &] &
      ],
      ibpFail[
        "Kira target construction",
        "a requested integral removes an oriented cut propagator"
      ]
    ];

    If[
      CheckAbort[
        Quiet[
          FeynCalc`KiraCreateConfigFiles[
            topology,
            familyTargets,
            familyRoot,
            FeynCalc`KiraMassDimensions -> massDimensions,
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          FeynCalc`KiraCreateIntegralFile[
            Total[familyTargets],
            topology,
            familyRoot,
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          FeynCalc`KiraCreateJobFile[
            topology,
            familyTargets,
            familyRoot,
            FeynCalc`KiraIntegrals -> {"KiraLoopIntegrals"},
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          True
        ],
        False
      ] =!= True,
      ibpFail[
        "Kira configuration",
        "FeynHelpers could not export the topology"
      ]
    ];
    familyDirectory = FileNameJoin[{
      familyRoot,
      ToString[name, InputForm]
    }];
    ibpInsertCuts[
      FileNameJoin[{
        familyDirectory,
        "config",
        "integralfamilies.yaml"
      }],
      cutIndices
    ];
    <|
      "Name" -> name,
      "Directory" -> familyDirectory,
      "Targets" -> familyTargets,
      "CutIndices" -> cutIndices,
      "Ordinal" -> index
    |>,
    {index, Length[records]}
  ];

  If[
    ! DirectoryQ[FileNameJoin[{combinedDirectory, "config"}]],
    CreateDirectory[
      FileNameJoin[{combinedDirectory, "config"}],
      CreateIntermediateDirectories -> True
    ]
  ];
  familyBlocks = Flatten @ Table[
    Rest @ Import[
      FileNameJoin[{
        manifest[[index, "Directory"]],
        "config",
        "integralfamilies.yaml"
      }],
      "Lines"
    ],
    {index, Length[manifest]}
  ];
  Export[
    FileNameJoin[{
      combinedDirectory,
      "config",
      "integralfamilies.yaml"
    }],
    StringRiffle[Prepend[familyBlocks, "integralfamilies:"], "\n"] <>
      "\n",
    "String"
  ];
  kinematics = Import[
    FileNameJoin[{
      #["Directory"],
      "config",
      "kinematics.yaml"
    }],
    "Text"
  ] & /@ manifest;
  If[Length[DeleteDuplicates[kinematics]] =!= 1,
    ibpFail[
      "Kira configuration",
      "families generated different external kinematics"
    ]
  ];
  Export[
    FileNameJoin[{
      combinedDirectory,
      "config",
      "kinematics.yaml"
    }],
    First[kinematics],
    "String"
  ];

  reduceLines = Flatten @ Table[
    Select[
      Import[
        FileNameJoin[{manifest[[index, "Directory"]], "job.yaml"}],
        "Lines"
      ],
      StringStartsQ[StringTrim[#], "- {topologies:"] &
    ],
    {index, Length[manifest]}
  ];
  Do[
    CopyFile[
      FileNameJoin[{
        manifest[[index, "Directory"]],
        "KiraLoopIntegrals"
      }],
      FileNameJoin[{
        combinedDirectory,
        "integrals_" <> ToString[index]
      }],
      OverwriteTarget -> True
    ],
    {index, Length[manifest]}
  ];
  jobLines = Join[
    {"jobs:", "  - reduce_sectors:", "      reduce:"},
    reduceLines,
    {"      select_integrals:", "        select_mandatory_list:"},
    Table[
      "          - [" <>
        ToString[manifest[[index, "Name"]], InputForm] <>
        ", \"integrals_" <> ToString[index] <> "\"]",
      {index, Length[manifest]}
    ],
    {
      "      run_initiate: true",
      "      run_triangular: true",
      "      run_back_substitution: true",
      "      integral_ordering: 2",
      "  - kira2math:",
      "      target:"
    },
    Table[
      "        - [" <>
        ToString[manifest[[index, "Name"]], InputForm] <>
        ", \"integrals_" <> ToString[index] <> "\"]",
      {index, Length[manifest]}
    ]
  ];
  Export[
    FileNameJoin[{combinedDirectory, "jobs.yaml"}],
    StringRiffle[jobLines, "\n"] <> "\n",
    "String"
  ];

  Join[
    projectState,
    <|
      "ProjectRoot" -> projectState["Directory"],
      "Directory" -> combinedDirectory,
      "Manifest" -> manifest
    |>
  ]
];

ibpRunKira[project_Association] := Module[
  {
    directory, manifest, runtime, kira, fermat, parallel,
    process, log, logPath, unreduced
  },

  directory = project["Directory"];
  manifest = project["Manifest"];
  runtime = project["Runtime"];
  kira = runtime["KiraExecutable"];
  fermat = runtime["FermatExecutable"];
  parallel = Min[
    Max[1, $ProcessorCount],
    If[
      ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
      8
    ]
  ];
  logPath = FileNameJoin[{directory, "kira.log"}];
  process = RunProcess[
    {kira, "--parallel=" <> ToString[parallel], "jobs.yaml"},
    All,
    ProcessDirectory -> directory,
    ProcessEnvironment -> <|"FERMATPATH" -> fermat|>
  ];
  log = StringJoin[
    Lookup[process, "StandardOutput", ""],
    Lookup[process, "StandardError", ""]
  ];
  Export[logPath, log, "String"];
  If[Lookup[process, "ExitCode", 1] =!= 0,
    ibpFail[
      "Kira reduction",
      "Kira exited with code " <>
        ToString[Lookup[process, "ExitCode", "unknown"]] <>
        "; see " <> logPath
    ]
  ];
  unreduced = FromDigits /@ StringCases[
    log,
    RegularExpression["unreduced integrals: ([0-9]+)"] -> "$1"
  ];
  If[
    Length[unreduced] < Length[manifest] ||
      ! AllTrue[unreduced, # === 0 &],
    ibpFail[
      "Kira reduction",
      "Kira did not report zero unreduced integrals for every family"
    ]
  ];
  logPath
];

(* Exact Kira import, closure, and master validation. *)
ibpImportRuleTable[name_, path_String] := Module[
  {dimension, imported},
  If[! FileExistsQ[path],
    ibpFail["Kira import", "missing reduction table " <> path]
  ];
  dimension = Symbol["Global`d"] -> System`D;
  imported = Quiet @ CheckAbort[
    Check[
      FeynCalc`KiraImportResults[
        name,
        path,
        FeynCalc`FCReplaceD -> {dimension},
        FeynCalc`FCVerbose -> -1
      ],
      $Failed
    ],
    $Failed
  ];
  If[
    imported === $Failed || ! ListQ[imported] ||
      ! AllTrue[imported, MatchQ[#, _Rule | _RuleDelayed] &] ||
      ! exactDataQ[imported],
    ibpFail[
      "Kira import",
      "the imported reduction table is not an exact list of rules: " <>
        path
    ]
  ];
  imported
];

ibpImportKernelLimit[count_Integer] := Module[
  {reductionLimit, importLimit},
  reductionLimit = If[
    ValueQ[Global`$FACETKernelLimit] &&
      IntegerQ[Global`$FACETKernelLimit] &&
      Global`$FACETKernelLimit > 0,
    Global`$FACETKernelLimit,
    $ProcessorCount
  ];
  importLimit = If[
    ValueQ[Global`$FACETKiraImportKernelLimit] &&
      IntegerQ[Global`$FACETKiraImportKernelLimit] &&
      Global`$FACETKiraImportKernelLimit > 0,
    Global`$FACETKiraImportKernelLimit,
    4
  ];
  Min[count, $ProcessorCount, reductionLimit, importLimit]
];

ibpValidateImportedRuleTable[name_, table_List] := Module[{leftSides},
  leftSides = First /@ table;
  If[
    ! AllTrue[
      leftSides,
      MatchQ[#, _FeynCalc`GLI] && SameQ[#[[1]], name] &
    ],
    ibpFail[
      "Kira import",
      "a reduction table contains a row for the wrong family"
    ]
  ];
  If[! DuplicateFreeQ[leftSides, SameQ],
    ibpFail[
      "Kira import",
      "a reduction table contains duplicate rows for one integral"
    ]
  ];
  True
];

ibpImportRules[project_Association, records_List] := Module[
  {
    directory, manifest, specifications, familyCount, workerCount,
    existingKernels, launchedKernels = {}, loadFile, initialized,
    importBatch, batch, tables, harvested, rules, cutCheck,
    completed = 0, ruleCount = 0, result, aborted = False
  },
  directory = project["Directory"];
  manifest = project["Manifest"];
  If[! DuplicateFreeQ[Lookup[manifest, "Name"], SameQ],
    ibpFail["Kira import", "the Kira manifest repeats a family name"]
  ];
  specifications = MapIndexed[
    Function[{item, position}, <|
      "Name" -> item["Name"],
      "Path" -> FileNameJoin[{
      directory,
      "results",
        ToString[item["Name"], InputForm],
        "kira_integrals_" <> ToString[First[position]] <> ".m"
      }]
    |>],
    manifest
  ];
  familyCount = Length[specifications];
  workerCount = ibpImportKernelLimit[familyCount];
  existingKernels = Kernels[];
  If[workerCount > 1 && Length[existingKernels] < workerCount,
    launchedKernels = LaunchKernels[workerCount - Length[existingKernels]]
  ];
  If[workerCount > 1,
    loadFile = FileNameJoin[{
      $feynFacetRoot, "Addon", "Load", "LoadFACET.wl"
    }];
    initialized = With[{file = loadFile},
      And @@ ParallelEvaluate[
        Block[{$Output = {}},
          Quiet[
            CheckAbort[
              Get[file];
              Length[
                DownValues[FeynFacet`Private`ibpImportRuleTable]
              ] > 0,
              False
            ],
            General::shdw
          ]
        ],
        Kernels[]
      ]
    ];
    If[! TrueQ[initialized],
      If[launchedKernels =!= {}, CloseKernels[launchedKernels]];
      ibpFail["Kira import", "parallel import workers did not initialize"]
    ]
  ];
  importBatch[current_List] := If[
    workerCount === 1,
    Catch[
        ibpImportRuleTable[#1["Name"], #1["Path"]],
        $ibpFailure
      ] & /@ current,
    ParallelMap[
      Function[specification,
        Catch[
          FeynFacet`Private`ibpImportRuleTable[
            specification["Name"],
            specification["Path"]
          ],
          "FeynFacetIBPFailure"
        ]
      ],
      current,
      Method -> "FinestGrained",
      DistributedContexts -> None
    ]
  ];
  result = CheckAbort[
    Catch[
      harvested = Reap[
        Do[
          batch = Take[
            specifications,
            {start, Min[start + workerCount - 1, familyCount]}
          ];
          tables = importBatch[batch];
          If[
            ! ListQ[tables] ||
              Length[tables] =!= Length[batch] ||
              MemberQ[tables, $Failed | $Aborted],
            ibpFail["Kira import", "a family import failed"]
          ];
          MapThread[
            Function[{specification, table},
              ibpValidateImportedRuleTable[
                specification["Name"],
                table
              ];
              Scan[
                Function[rule,
                  Sow[rule, "KiraRule"];
                  ruleCount++
                ],
                table
              ]
            ],
            {batch, tables}
          ];
          completed += Length[batch];
          Clear[tables];
          Print[
            "Imported ", completed, " / ", familyCount,
            " Kira families (", ruleCount, " rules; ",
            Round[MemoryInUse[]/1024.^2, 1], " MB in the main kernel)"
          ],
          {start, 1, familyCount, workerCount}
        ],
        "KiraRule"
      ];
      rules = If[harvested[[2]] === {}, {}, First[harvested[[2]]]];
      cutCheck = validateCutGLIs[rules, records];
      If[cutCheck =!= True,
        ibpFail[
          "Kira import",
          "the imported reduction pinches a cut or has invalid GLI arity: " <>
            ToString[Take[cutCheck, UpTo[3]], InputForm]
        ]
      ];
      rules,
      $ibpFailure
    ],
    aborted = True;
    $Aborted
  ];
  If[launchedKernels =!= {}, CloseKernels[launchedKernels]];
  If[aborted, Abort[]];
  If[result === $Failed, Throw[$Failed, $ibpFailure]];
  result
];

ibpDeclaredMasters[project_Association] := Module[
  {
    directory, manifest, nameMap, paths, lines, parseInteger, parseLine,
    masters
  },
  directory = project["Directory"];
  manifest = project["Manifest"];
  nameMap = Association[
    ToString[#1["Name"], InputForm] -> #1["Name"] & /@ manifest
  ];
  paths = FileNameJoin[{
      directory,
      "results",
      ToString[#1["Name"], InputForm],
      "masters.final"
    }] & /@ manifest;
  If[! AllTrue[paths, FileExistsQ],
    ibpFail["Kira master validation", "a masters.final file is missing"]
  ];
  parseInteger[text_String] := Module[{trimmed, sign},
    trimmed = StringTrim[text];
    If[! StringMatchQ[trimmed, RegularExpression["[+-]?[0-9]+"]],
      Return[$Failed]
    ];
    sign = If[StringStartsQ[trimmed, "-"], -1, 1];
    sign FromDigits[StringTrim[trimmed, "+" | "-"]]
  ];
  parseLine[line_String] := Module[
    {integral, pieces, name, indices},
    integral = StringTrim[First[StringSplit[line, "#"]]];
    pieces = StringSplit[integral, {"[", "]"}];
    If[Length[pieces] < 2 || ! KeyExistsQ[nameMap, First[pieces]],
      ibpFail[
        "Kira master validation",
        "cannot parse master integral " <> integral
      ]
    ];
    name = nameMap[First[pieces]];
    indices = parseInteger /@ StringSplit[pieces[[2]], ","];
    If[! MatchQ[indices, {___Integer}],
      ibpFail[
        "Kira master validation",
        "invalid master indices in " <> integral
      ]
    ];
    FeynCalc`GLI[name, indices]
  ];
  lines = Flatten[Select[Import[#1, "Lines"],
      StringTrim[#1] =!= "" &] & /@ paths];
  masters = DeleteDuplicates[parseLine /@ lines];
  masters
];

ibpCloseReductionRules[rules_List, targets_List] := Module[
  {
    uniqueRules, leftSides, dispatch, current, next,
    converged = False, unresolved, closedRules, masters
  },
  uniqueRules = rules;
  leftSides = First /@ uniqueRules;
  dispatch = Dispatch[uniqueRules];
  current = targets;
  Do[
    next = current /. dispatch;
    If[SameQ[next, current],
      converged = True;
      Break[]
    ];
    current = next,
    {Length[uniqueRules] + 2}
  ];
  unresolved = Intersection[
    DeleteDuplicates @ Cases[current, _FeynCalc`GLI, {0, Infinity}],
    leftSides,
    SameTest -> SameQ
  ];
  If[! converged || unresolved =!= {},
    ibpFail[
      "Kira rule closure",
      "the imported tables do not reduce transitively to terminal integrals"
    ]
  ];
  closedRules = Select[
    MapThread[Rule, {targets, current}],
    ! SameQ[First[#1], Last[#1]] &
  ];
  masters = DeleteDuplicates @ Cases[
    current,
    _FeynCalc`GLI,
    {0, Infinity}
  ];
  <|
    "Rules" -> closedRules,
    "Images" -> current,
    "Masters" -> masters
  |>
];

ibpValidateMasters[
    masters_List,
    declaredMasters_List,
    records_List
  ] := Module[{undeclared, cutCheck},
  undeclared = Complement[
    masters,
    declaredMasters,
    SameTest -> SameQ
  ];
  If[undeclared =!= {},
    ibpFail[
      "Kira master validation",
      ToString[Length[undeclared]] <>
        " terminal integrals are absent from Kira's declared master list; " <>
        "the exported rule set is not closed"
    ]
  ];
  cutCheck = validateCutGLIs[masters, records];
  If[cutCheck =!= True,
    ibpFail[
      "cut validation",
      "the reduction returned an invalid master or removed a required cut"
    ]
  ];
  True
];

ibpKiraIntegralText[integral_FeynCalc`GLI] :=
  ToString[integral[[1]], InputForm] <> "[" <>
    StringRiffle[ToString[#, InputForm] & /@ integral[[2]], ", "] <>
    "]";

ibpSolvedProjectFingerprint[project_Association] := Module[
  {directory, manifest, files},
  directory = project["Directory"];
  manifest = project["Manifest"];
  files = Join[
    {
      FileNameJoin[{directory, "results", "kira.db"}],
      FileNameJoin[{directory, "jobs.yaml"}],
      FileNameJoin[{directory, "config", "kinematics.yaml"}],
      FileNameJoin[{directory, "config", "integralfamilies.yaml"}]
    },
    FileNameJoin[{
        directory,
        "results",
        ToString[#1["Name"], InputForm],
        "masters.final"
      }] & /@ manifest
  ];
  If[! AllTrue[files, FileExistsQ],
    ibpFail[
      "Kira export closure",
      "the solved Kira project is incomplete"
    ]
  ];
  reductionFingerprint[{
    project["InputFingerprint"],
    Lookup[project["Runtime"], {
      "KiraExecutableHash", "FermatExecutableHash", "SupportFileHash"
    }],
    ({#1, FileByteCount[#1], FileHash[#1, "SHA256"]} &) /@ files
  }]
];

ibpExportClosureFrontier[
    project_Association,
    frontier_List,
    iteration_Integer,
    records_List
  ] := Module[
  {
    directory, runtime, kira, fermat, ordered, groups, knownNames,
    unknownNames, queries, name, file, jobPath, logPath, process, log,
    unreduced, resultPath, imported, rules, leftSides, missing,
    unexpected, cutCheck
  },
  directory = project["Directory"];
  runtime = project["Runtime"];
  kira = runtime["KiraExecutable"];
  fermat = runtime["FermatExecutable"];
  ordered = SortBy[
    DeleteDuplicates[frontier, SameQ],
    ToString[#, InputForm] &
  ];
  If[
    ! AllTrue[
      ordered,
      MatchQ[#, FeynCalc`GLI[_, {___Integer}]] &
    ],
    ibpFail[
      "Kira export closure",
      "the unresolved frontier contains a malformed integral"
    ]
  ];
  cutCheck = validateCutGLIs[ordered, records];
  If[cutCheck =!= True,
    ibpFail[
      "Kira export closure",
      "the unresolved frontier contains an unknown family or invalid cut"
    ]
  ];
  groups = GatherBy[ordered, First];
  knownNames = Lookup[project["Manifest"], "Name"];
  unknownNames = Complement[
    groups[[All, 1, 1]],
    knownNames,
    SameTest -> SameQ
  ];
  If[unknownNames =!= {},
    ibpFail[
      "Kira export closure",
      "the unresolved frontier contains an unknown topology"
    ]
  ];
  queries = Table[
    name = groups[[index, 1, 1]];
    file = "closure_frontier_" <>
      IntegerString[iteration, 10, 3] <> "_" <>
      IntegerString[index, 10, 3];
    Export[
      FileNameJoin[{directory, file}],
      StringRiffle[ibpKiraIntegralText /@ groups[[index]], "\n"] <>
        "\n",
      "String"
    ];
    <|
      "Name" -> name,
      "File" -> file,
      "Targets" -> groups[[index]]
    |>,
    {index, Length[groups]}
  ];
  jobPath = FileNameJoin[{
    directory,
    "export_closure_" <> IntegerString[iteration, 10, 3] <> ".yaml"
  }];
  Export[
    jobPath,
    StringRiffle[
      Join[
        {"jobs:", "  - kira2math:", "      target:"},
        ("        - [" <>
          ToString[#1["Name"], InputForm] <> ", \"" <>
          #1["File"] <> "\"]") & /@ queries
      ],
      "\n"
    ] <> "\n",
    "String"
  ];
  process = RunProcess[
    {
      kira,
      "--parallel=1",
      FileNameTake[jobPath]
    },
    All,
    ProcessDirectory -> directory,
    ProcessEnvironment -> <|"FERMATPATH" -> fermat|>
  ];
  log = StringJoin[
    Lookup[process, "StandardOutput", ""],
    Lookup[process, "StandardError", ""]
  ];
  logPath = FileNameJoin[{
    directory,
    "export_closure_" <> IntegerString[iteration, 10, 3] <> ".log"
  }];
  Export[logPath, log, "String"];
  If[Lookup[process, "ExitCode", 1] =!= 0,
    ibpFail[
      "Kira export closure",
      "kira2math exited with code " <>
        ToString[Lookup[process, "ExitCode", "unknown"]] <>
        "; see " <> logPath
    ]
  ];
  unreduced = FromDigits /@ StringCases[
    log,
    RegularExpression["unreduced integrals: ([0-9]+)"] -> "$1"
  ];
  If[
    Length[unreduced] =!= Length[queries] ||
      ! AllTrue[unreduced, # === 0 &],
    ibpFail[
      "Kira export closure",
      "kira2math did not report zero unreduced integrals for every frontier family"
    ]
  ];
  imported = Flatten @ Map[
    Function[query,
      resultPath = FileNameJoin[{
        directory,
        "results",
        ToString[query["Name"], InputForm],
        "kira_" <> query["File"] <> ".m"
      }];
      ibpImportRuleTable[query["Name"], resultPath]
    ],
    queries
  ];
  rules = DeleteDuplicates[imported, SameQ];
  leftSides = First /@ rules;
  missing = Complement[ordered, leftSides, SameTest -> SameQ];
  unexpected = Complement[leftSides, ordered, SameTest -> SameQ];
  If[missing =!= {} || unexpected =!= {},
    ibpFail[
      "Kira export closure",
      "kira2math did not return exactly one reduction row for every requested frontier integral"
    ]
  ];
  cutCheck = validateCutGLIs[rules, records];
  If[cutCheck =!= True,
    ibpFail[
      "Kira export closure",
      "an exported closure row has an unknown family, invalid arity or pinched cut"
    ]
  ];
  <|
    "Rules" -> rules,
    "Diagnostic" -> <|
      "Iteration" -> iteration,
      "QueryCount" -> Length[ordered],
      "QueryFingerprint" -> reductionFingerprint[ordered],
      "NewRuleCount" -> Length[rules],
      "ExportFingerprint" -> reductionFingerprint[rules],
      "KiraReportedUnreduced" -> unreduced
    |>
  |>
];

ibpCloseKiraExport[
    project_Association,
    initialRules_List,
    targets_List,
    declaredMasters_List,
    records_List
  ] := Module[
  {
    rules, closure, frontier, initialRuleCount, solvedFingerprint,
    exportResult, newRules, oldLeftSides, overlapping, iteration = 0,
    diagnostics = {}, finalFingerprint
  },
  rules = initialRules;
  initialRuleCount = Length[rules];
  closure = ibpCloseReductionRules[rules, targets];
  frontier = Complement[
    closure["Masters"],
    declaredMasters,
    SameTest -> SameQ
  ];
  If[frontier === {},
    Return @ Join[
      closure,
      <|"ExportClosure" -> <|
        "Status" -> "AlreadyClosed",
        "InitialRuleCount" -> initialRuleCount,
        "FinalRuleCount" -> initialRuleCount,
        "Iterations" -> {}
      |>|>
    ]
  ];
  solvedFingerprint = ibpSolvedProjectFingerprint[project];
  While[frontier =!= {},
    iteration++;
    exportResult = ibpExportClosureFrontier[
      project,
      frontier,
      iteration,
      records
    ];
    newRules = exportResult["Rules"];
    oldLeftSides = First /@ rules;
    overlapping = Intersection[
      oldLeftSides,
      First /@ newRules,
      SameTest -> SameQ
    ];
    If[overlapping =!= {},
      ibpFail[
        "Kira export closure",
        "an export-only frontier unexpectedly repeated an existing rule"
      ]
    ];
    If[newRules === {},
      ibpFail[
        "Kira export closure",
        "a nonempty frontier produced no new reduction rows"
      ]
    ];
    rules = Join[rules, newRules];
    AppendTo[diagnostics, exportResult["Diagnostic"]];
    closure = ibpCloseReductionRules[rules, targets];
    frontier = Complement[
      closure["Masters"],
      declaredMasters,
      SameTest -> SameQ
    ];
  ];
  finalFingerprint = ibpSolvedProjectFingerprint[project];
  If[finalFingerprint =!= solvedFingerprint,
    ibpFail[
      "Kira export closure",
      "the solved Kira project changed during export-only closure"
    ]
  ];
  Join[
    closure,
    <|"ExportClosure" -> <|
      "Status" -> "ClosedByExport",
      "SolvedProjectFingerprint" -> solvedFingerprint,
      "InitialRuleCount" -> initialRuleCount,
      "FinalRuleCount" -> Length[rules],
      "Iterations" -> diagnostics,
      "TerminalMasterFingerprint" ->
        reductionFingerprint[closure["Masters"]]
    |>|>
  ]
];

linearPartExpressions[parts_Association] := Append[
  Values[parts["Terms"]],
  Lookup[parts, "Remainder", 0]
];

replaceLinearPartExpressions[
    parts_Association,
    expressions_List
  ] := <|
  "Terms" -> AssociationThread[Keys[parts["Terms"]], Most[expressions]],
  "Remainder" -> Last[expressions]
|>;

physicalizeLinearCoefficientParts[
    parts_Association,
    context_Association
  ] := Module[{hadronic, expressions, physical},
  hadronic = Lookup[
    context,
    "HadronicVariables",
    emptyHadronicVariables[]
  ];
  expressions = linearPartExpressions[parts] /.
    Lookup[context, "DimensionRule", $dimensionRule];
  physical = applyHadronicVariables[expressions, hadronic];
  If[physical === $Failed || ! exactDataQ[physical], Return[$Failed]];
  replaceLinearPartExpressions[parts, physical]
];

coefficientForbiddenMomenta[setup_Association] := DeleteDuplicates @ Join[
  Lookup[setup, "PhaseSpaceMomentum", {}],
  Lookup[
    Lookup[setup, "ForwardAmplitudes", <||>],
    "LoopMomenta",
    {}
  ],
  Lookup[
    Lookup[setup, "ConjugateAmplitudes", <||>],
    "LoopMomenta",
    {}
  ]
];

parallelNormalizeCoefficients[
    expressions_List,
    assumptions_,
    coefficientTimeLimit_: Infinity,
    mode_: "Terms"
  ] := Module[
  {
    count, termCounts, limit, existingKernels, launchedKernels,
    pending, nextResult, finishedTask, results, value,
    activeKernels, valid, completed, nextIndex, submitCoefficient,
    waitForTasks, jobOrder, timeoutCount, kernelObjects, kernelIDs,
    kernelByID, recycleTimedOutKernel, recycledCount
  },

  If[! MemberQ[{"Terms", "Whole"}, mode], Return[$Failed]];
  count = Length[expressions];
  If[count === 0, Return[{{}, 0, 0}]];
  termCounts = If[
    mode === "Whole",
    ConstantArray[1, count],
    Length[additiveTerms[#]] & /@ expressions
  ];
  limit = Min[
    count,
    $ProcessorCount,
    If[
      ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
      $ProcessorCount
    ]
  ];
  existingKernels = Kernels[];
  launchedKernels = If[
    Length[existingKernels] < limit,
    LaunchKernels[limit - Length[existingKernels]],
    {}
  ];
  activeKernels = Min[count, limit, Length[Kernels[]]];
  If[activeKernels === 0,
    value = Map[
      Function[coefficient,
        With[{
          pieces = If[
            mode === "Whole",
            {coefficient},
            additiveTerms[coefficient]
          ]
        },
          If[coefficientTimeLimit === Infinity,
            {
              Total[
                Simplify[#1, Assumptions -> assumptions] & /@
                  pieces
              ],
              0
            },
            TimeConstrained[
              {
                Total[
                  Simplify[#1, Assumptions -> assumptions] & /@ pieces
                ],
                0
              },
              coefficientTimeLimit,
              {coefficient, 1}
            ]
          ]
        ]
      ],
      expressions
    ];
    timeoutCount = Total[value[[All, 2]]];
    value = value[[All, 1]];
    If[! AllTrue[value, exactDataQ], Return[$Failed]];
    If[timeoutCount > 0,
      Print[
        timeoutCount,
        " coefficients retained exactly after the simplification limit"
      ]
    ];
    Return[{
      value,
      1,
      Total[termCounts]
    }]
  ];
  results = ConstantArray[Missing["Pending"], count];
  valid = True;
  completed = 0;
  timeoutCount = 0;
  recycledCount = 0;
  kernelObjects = Kernels[];
  kernelIDs = ParallelEvaluate[$KernelID, kernelObjects];
  kernelByID = AssociationThread[kernelIDs, kernelObjects];
  recycleTimedOutKernel[kernelID_Integer] := Module[
    {kernel, newKernels, newKernelIDs},
    kernel = Lookup[kernelByID, kernelID, Missing["UnknownKernel"]];
    If[MissingQ[kernel], Return[False]];
    If[! MemberQ[launchedKernels, kernel], Return[True]];
    CloseKernels[{kernel}];
    launchedKernels = DeleteCases[launchedKernels, kernel];
    KeyDropFrom[kernelByID, kernelID];
    newKernels = LaunchKernels[1];
    If[Length[newKernels] =!= 1, Return[False]];
    newKernelIDs = ParallelEvaluate[$KernelID, newKernels];
    If[Length[newKernelIDs] =!= 1,
      CloseKernels[newKernels];
      Return[False]
    ];
    launchedKernels = Join[launchedKernels, newKernels];
    AssociateTo[kernelByID, First[newKernelIDs] -> First[newKernels]];
    recycledCount++;
    True
  ];
  jobOrder = Reverse @ Ordering[ByteCount /@ expressions];
  submitCoefficient[index_Integer] := With[{
    localIndex = index,
    localTerms = If[
      mode === "Whole",
      {expressions[[index]]},
      additiveTerms[expressions[[index]]]
    ],
    localAssumptions = assumptions,
    localTimeLimit = coefficientTimeLimit
  },
    ParallelSubmit[
      If[localTimeLimit === Infinity,
        {
          localIndex,
          Total[
            Simplify[#1, Assumptions -> localAssumptions] & /@ localTerms
          ],
          0,
          $KernelID
        },
        TimeConstrained[
          {
            localIndex,
            Total[
              Simplify[#1, Assumptions -> localAssumptions] & /@ localTerms
            ],
            0,
            $KernelID
          },
          localTimeLimit,
          {localIndex, Total[localTerms], 1, $KernelID}
        ]
      ]
    ]
  ];
  nextIndex = Min[count, activeKernels] + 1;
  pending = submitCoefficient /@ Take[
    jobOrder,
    Min[count, activeKernels]
  ];
  waitForTasks[] := While[pending =!= {},
    {nextResult, finishedTask, pending} = WaitNext[pending];
    If[
      ! MatchQ[nextResult, {_Integer, _, _Integer, _Integer}] ||
        FailureQ[nextResult[[2]]] || ! exactDataQ[nextResult[[2]]],
      valid = False;
      Break[]
    ];
    results[[First[nextResult]]] = nextResult[[2]];
    timeoutCount += nextResult[[3]];
    If[
      nextResult[[3]] > 0 &&
        ! TrueQ[recycleTimedOutKernel[nextResult[[4]]]],
      valid = False;
      Break[]
    ];
    completed++;
    If[nextIndex <= count,
      AppendTo[pending, submitCoefficient[jobOrder[[nextIndex]]]];
      nextIndex++
    ]
  ];
  value = CheckAbort[
    Quiet[
      If[
        TrueQ[$Notebooks],
        Monitor[
          waitForTasks[],
          Column[{
            ProgressIndicator[completed, {0, count}],
            Row[{completed, " / ", count, " coefficients"}]
          }]
        ],
        waitForTasks[]
      ];
      If[valid, results, $Failed]
    ],
    If[launchedKernels =!= {}, CloseKernels[launchedKernels]];
    Abort[]
  ];
  If[launchedKernels =!= {}, CloseKernels[launchedKernels]];
  If[
    value === $Failed || MemberQ[value, $Failed | $Aborted | _Missing],
    Return[$Failed]
  ];
  If[timeoutCount > 0,
    Print[
      timeoutCount,
      " coefficients retained exactly after the simplification limit; ",
      recycledCount,
      " workers recycled"
    ]
  ];
  {value, activeKernels, Total[termCounts]}
];

targetCoefficientSimplifyTimeLimit[] := If[
  ValueQ[Global`$FACETTargetSimplifyTimeLimit] &&
    NumericQ[Global`$FACETTargetSimplifyTimeLimit] &&
    Global`$FACETTargetSimplifyTimeLimit > 0,
  Global`$FACETTargetSimplifyTimeLimit,
  60
];

normalizeLinearCoefficientParts[
    parts_Association,
    assumptions_
  ] := Module[{keys, normalized, remainder},
  keys = Keys[parts["Terms"]];
  normalized = parallelNormalizeCoefficients[
    Values[parts["Terms"]],
    assumptions,
    targetCoefficientSimplifyTimeLimit[]
  ];
  If[normalized === $Failed, Return[$Failed]];
  remainder = exactCoefficientNormalize[
    Lookup[parts, "Remainder", 0],
    assumptions
  ];
  If[remainder === $Failed, Return[$Failed]];
  <|
    "Terms" -> AssociationThread[keys, First[normalized]],
    "Remainder" -> remainder
  |>
];

normalizeMasterCoefficients[
    parts_Association,
    label_String,
    setup_Association,
    context_Association
  ] := Module[
  {
    coefficientAssociation, masters, coefficients, remainder,
    elapsed, simplified, simplifiedCoefficients, nonzero,
    expressionsForFactor, factorResult, commonPreFactor,
    normalizedExpressions, normalizedCoefficients,
    simplifiedRemainder, coefficientParts, localPreFactors,
    reducedCoefficients, reconstructed, kernelCount, termCount,
    assumptions, hardNormalization, hardPreFactor
  },
  assumptions = context["Assumptions"];
  coefficientAssociation = parts["Terms"];
  masters = Keys[coefficientAssociation];
  coefficients = Values[coefficientAssociation];
  remainder = Lookup[parts, "Remainder", 0];
  If[masters === {},
    simplifiedRemainder = exactCoefficientNormalize[remainder, assumptions];
    If[simplifiedRemainder === $Failed,
      ibpFail[label, "remainder normalization failed"]
    ];
    Return[<|
      "PreFactor" -> 1,
      "Masters" -> {},
      "PreFactors" -> {},
      "Coefficients" -> {},
      "Remainder" -> simplifiedRemainder,
      "Expression" -> simplifiedRemainder,
      "HadronicNormalization" -> <|
        "PreFactor" -> 1,
        "FractionVariables" -> {},
        "BranchRules" -> {},
        "PositiveVariables" -> {}
      |>
    |>]
  ];
  {elapsed, simplified} = AbsoluteTiming[
    parallelNormalizeCoefficients[coefficients, assumptions]
  ];
  If[simplified === $Failed,
    ibpFail[label, "parallel coefficient simplification failed"]
  ];
  {simplifiedCoefficients, kernelCount, termCount} = simplified;
  nonzero = Flatten @ Position[
    simplifiedCoefficients,
    coefficient_ /; ! TrueQ[coefficient === 0],
    {1},
    Heads -> False
  ];
  masters = masters[[nonzero]];
  simplifiedCoefficients = simplifiedCoefficients[[nonzero]];
  simplifiedRemainder = exactCoefficientNormalize[remainder, assumptions];
  If[simplifiedRemainder === $Failed,
    ibpFail[label, "remainder normalization failed"]
  ];
  expressionsForFactor = Join[
    simplifiedCoefficients,
    If[TrueQ[simplifiedRemainder === 0], {}, {simplifiedRemainder}]
  ];
  hardNormalization = SimplifyHardCoefficients[
    expressionsForFactor,
    setup,
    "Method" -> "Assembled",
    "TimeLimit" -> targetCoefficientSimplifyTimeLimit[]
  ];
  If[hardNormalization === $Failed,
    ibpFail[
      label,
      "the physical branch or momentum-fraction factor could not be certified"
    ]
  ];
  hardPreFactor = hardNormalization["PreFactor"];
  expressionsForFactor = hardNormalization["Expressions"];
  Print["Extracting overall factor"];
  factorResult = structuralCommonAdditiveFactor[expressionsForFactor];
  commonPreFactor = hardPreFactor First[factorResult];
  normalizedExpressions = Last[factorResult];
  normalizedCoefficients = Take[
    normalizedExpressions,
    Length[simplifiedCoefficients]
  ];
  simplifiedRemainder = If[
    TrueQ[simplifiedRemainder === 0],
    0,
    Last[normalizedExpressions]
  ];
  coefficientParts = structuralAdditiveFactor /@ normalizedCoefficients;
  localPreFactors = First /@ coefficientParts;
  reducedCoefficients = Last /@ coefficientParts;
  reconstructed =
    Total[MapThread[Times, {
      localPreFactors,
      reducedCoefficients,
      masters
    }]] + simplifiedRemainder;
  Print[
    label, ": ", Length[masters], " masters on ", kernelCount,
    " kernels (", termCount, " additive terms) in ",
    Round[elapsed, 0.01], " s"
  ];
  <|
    "PreFactor" -> commonPreFactor,
    "Masters" -> masters,
    "PreFactors" -> localPreFactors,
      "Coefficients" -> reducedCoefficients,
      "Remainder" -> simplifiedRemainder,
      "Expression" -> commonPreFactor reconstructed,
      "HadronicNormalization" -> KeyDrop[
        hardNormalization,
        "Expressions"
      ]
    |>
];

(* Public two-stage reduction implementation. *)
ibpKiraReductionCore[
    data_Association,
    useSolvedProject_: False
  ] := Module[
  {
    records, equivalence, targets, representativeNames,
    representatives, completed, projectLocation, projectRoot,
    projectDirectory, projectState, project,
    runtime, payload, sourceFingerprint, importedRules, closure,
    declaredMasters, persistentManifest, compactSize
  },
  records = data["Records"];
  If[records === {},
    equivalence = <|
      "Scope" -> "CutAwareIBP",
      "SearchStatus" -> "Complete",
      "Representatives" -> {},
      "Classes" -> {},
      "Mappings" -> {},
      "GLIRules" -> {},
      "RejectedCandidateMappings" -> {}
    |>;
    payload = reductionInputPayload[
      {},
      {},
      {},
      <|"Status" -> "NotApplicable"|>
    ];
    sourceFingerprint = reductionFingerprint[
      sourceInputPayload[{}, {}, data["AnalyticContext"]]
    ];
    Return[Join[
      resultHeader["FeynFacet-KiraReduction", 4],
      resultContext[data],
      <|
      "Targets" -> {},
      "Masters" -> {},
      "DeclaredMasters" -> {},
      "KiraRules" -> {},
      "ReverseRules" -> {},
      "Topologies" -> {},
      "TopologyEquivalence" -> equivalence,
      "MassDimensions" -> {},
      "KiraManifest" -> {},
      "KiraExportClosure" -> <|"Status" -> "NotApplicable"|>,
      "DimensionRule" -> $dimensionRule,
      "ReductionInputPayload" -> payload,
      "ReductionInputFingerprint" -> reductionFingerprint[payload],
      "SourceInputFingerprint" -> sourceFingerprint
      |>
    ]]
  ];

  equivalence = ibpTopologyEquivalenceForData[data];
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
    Lookup[
      data["AnalyticContext"],
      "KinematicMassDimensions",
      <||>
    ]
  ];
  runtime = ibpRuntime[];
  payload = reductionInputPayload[
    completed["KiraFamilies"],
    targets,
    completed["MassDimensions"],
    runtime
  ];
  projectLocation = ibpProjectLocation[data["ResultDirectory"]];
  projectRoot = projectLocation["Root"];
  projectDirectory = projectLocation["Directory"];
  If[TrueQ[useSolvedProject],
    project = ibpOpenSolvedProject[
      projectLocation,
      completed["KiraFamilies"],
      targets,
      payload,
      runtime
    ];
    Print["Using the validated solved Kira workspace"],
    projectState = ibpResetProject[
      projectDirectory,
      projectRoot,
      payload,
      runtime
    ];
    project = ibpPrepareKiraProject[
      completed["KiraFamilies"],
      targets,
      projectState,
      completed["MassDimensions"]
    ];
    Print["Running Kira"];
    ibpRunKira[project]
  ];
  payload = project["InputPayload"];
  Print["Importing Kira rules"];
  importedRules = ibpImportRules[
    project,
    completed["PhysicalRecords"]
  ];
  declaredMasters = ibpDeclaredMasters[project];
  closure = ibpCloseKiraExport[
    project,
    importedRules,
    targets,
    declaredMasters,
    completed["PhysicalRecords"]
  ];
  If[validateCutGLIs[closure["Images"], completed["PhysicalRecords"]] =!= True,
    ibpFail["Kira rule closure", "a closed reduction image removes a cut"]
  ];
  ibpValidateMasters[
    closure["Masters"],
    declaredMasters,
    completed["PhysicalRecords"]
  ];
  persistentManifest = Map[
    Function[item,
      <|
        "Name" -> item["Name"],
        "CutIndices" -> item["CutIndices"],
        "TargetCount" -> Length[item["Targets"]],
        "Ordinal" -> item["Ordinal"]
      |>
    ],
    project["Manifest"]
  ];
  compactSize = ByteCount[{
    closure["Rules"],
    completed["ReverseRules"],
    closure["Masters"],
    completed["PhysicalRecords"]
  }];
  sourceFingerprint = reductionFingerprint[
    sourceInputPayload[
      records,
      data["RawTargets"],
      data["AnalyticContext"]
    ]
  ];
  Print @ Grid[
    {
      {"Input integrals", Length[targets]},
      {"Master integrals", Length[closure["Masters"]]},
      {"Reduction data size (kB)", Round[compactSize/1024., 0.01]}
    },
    Frame -> All
  ];
  Join[
    resultHeader["FeynFacet-KiraReduction", 4],
    resultContext[data],
    <|
    "Targets" -> targets,
    "Masters" -> closure["Masters"],
    "DeclaredMasters" -> declaredMasters,
    "KiraRules" -> closure["Rules"],
    "ReverseRules" -> completed["ReverseRules"],
    "Topologies" -> completed["PhysicalRecords"],
    "TopologyEquivalence" -> equivalence,
    "MassDimensions" -> completed["MassDimensions"],
    "KiraManifest" -> persistentManifest,
    "KiraExportClosure" -> closure["ExportClosure"],
    "DimensionRule" -> $dimensionRule,
    "ReductionInputPayload" -> payload,
    "ReductionInputFingerprint" -> project["InputFingerprint"],
    "SourceInputFingerprint" -> sourceFingerprint
    |>
  ]
];

ibpWriteKiraReduction[result_Association, output_String] := Module[
  {target, temporary, rules},
  target = ibpNormalizedPath[output];
  If[ToLowerCase[FileExtension[target]] =!= "wl",
    Message[KiraReduction::save, target];
    Return[$Failed]
  ];
  rules = result["KiraRules"];
  If[
    ! kiraReductionQ[result] ||
      ! ListQ[rules] ||
      ! AllTrue[rules, MatchQ[#, _Rule | _RuleDelayed] &],
    Message[KiraReduction::save, target];
    Return[$Failed]
  ];
  temporary = target <> ".tmp-" <> StringReplace[CreateUUID[], "-" -> ""];
  If[
    Quiet @ Check[
      Put[result, temporary];
      FileExistsQ[temporary] && FileByteCount[temporary] > 0,
      False
    ] =!= True,
    Message[KiraReduction::save, target];
    Return[$Failed]
  ];
  If[
    Quiet @ Check[
      RenameFile[temporary, target, OverwriteTarget -> True];
      True,
      False
    ] =!= True,
    Quiet @ Check[DeleteFile[temporary], Null];
    Message[KiraReduction::save, target];
    Return[$Failed]
  ];
  target
];

ibpKiraReductionSummary[result_Association] := <|
  "TargetCount" -> Length[result["Targets"]],
  "RuleCount" -> Length[result["KiraRules"]],
  "MasterCount" -> Length[result["Masters"]],
  "DeclaredMasterCount" -> Length[result["DeclaredMasters"]],
  "ManifestCount" -> Length[result["KiraManifest"]],
  "Pairs" -> result["Pairs"],
  "ReductionInputFingerprint" -> result["ReductionInputFingerprint"],
  "SourceInputFingerprint" -> result["SourceInputFingerprint"]
|>;

ibpValidateSavedKiraReduction[
    path_String,
    expected_Association
  ] := Module[{saved, valid},
  saved = Quiet @ Check[Get[path], $Failed];
  valid = AssociationQ[saved] &&
    kiraReductionQ[saved] &&
    SameQ[ibpKiraReductionSummary[saved], expected] &&
    AllTrue[
      saved["KiraRules"],
      MatchQ[#, _Rule | _RuleDelayed] &
    ];
  Clear[saved];
  TrueQ[valid]
];

ibpRemoveKiraWorkspace[location_Association] := Module[
  {root, project},
  root = ibpNormalizedPath[location["Root"]];
  project = ibpNormalizedPath[location["Directory"]];
  If[
    project === root ||
      ! StringStartsQ[
        project <> $PathnameSeparator,
        root <> $PathnameSeparator
      ],
    ibpFail["temporary Kira cleanup", "unsafe project path"]
  ];
  If[
    DirectoryQ[project] &&
      Quiet @ Check[
        DeleteDirectory[project, DeleteContents -> True];
        True,
        False
      ] =!= True,
    ibpFail[
      "temporary Kira cleanup",
      "could not remove " <> project
    ]
  ];
  If[
    DirectoryQ[root] && FileNames[All, root] === {},
    Quiet @ Check[DeleteDirectory[root], Null]
  ];
  If[DirectoryQ[project],
    ibpFail[
      "temporary Kira cleanup",
      "the project directory still exists"
    ]
  ];
  Null
];

ibpRunReduction[
    inputs_List,
    output_String,
    useSolvedProject_
  ] := Catch[
  Module[{data, result, location, savedPath, expectedSummary},
    data = ibpInputData[inputs, True];
    If[
      ibpNormalizedPath[DirectoryName[output]] =!=
        ibpNormalizedPath[data["ResultDirectory"]],
      Message[KiraReduction::save, ExpandFileName[output]];
      Return[$Failed]
    ];
    location = ibpProjectLocation[data["ResultDirectory"]];
    result = ibpKiraReductionCore[data, useSolvedProject];
    If[! AssociationQ[result], Return[$Failed]];
    expectedSummary = ibpKiraReductionSummary[result];
    savedPath = ibpWriteKiraReduction[result, output];
    If[savedPath === $Failed, Return[$Failed]];
    Clear[result];
    ClearSystemCache[];
    Print["Validating the saved reduction artifact"];
    If[! ibpValidateSavedKiraReduction[savedPath, expectedSummary],
      Message[KiraReduction::save, savedPath];
      Return[$Failed]
    ];
    ibpRemoveKiraWorkspace[location];
    Print @ Grid[
      {
        {"Saved", savedPath},
        {"File size (kB)",
          Round[FileByteCount[savedPath]/1024., 0.01]},
        {"Temporary Kira workspace", "removed"}
      },
      Frame -> All
    ];
    savedPath
  ],
  $ibpFailure
];

KiraReduction[
    inputs : ({__String} | {__Association}),
    output_String
  ] := ibpRunReduction[inputs, output, False];

KiraImportReduction[
    inputs : ({__String} | {__Association}),
    output_String
  ] := ibpRunReduction[inputs, output, True];


coefficientSimplificationCore[inputs_List, kira_Association] := Catch[
  Module[
    {
      data, sortedPairs, equivalence, targetParts, collectSource,
      targetTerms, targetRemainder, kiraTargetSet,
      targets, sparseReduction, physicalParts, unexpectedMasters,
      coefficientResult, commonPreFactor, masters,
      coefficientPreFactors, reducedCoefficients, recordByName,
      classByName, masterData, reconstructed, compactSize,
      sourceFingerprint, cutCheck, forbiddenMomenta, remainingMomenta,
      targetPhysicalSeconds, targetNormalizeSeconds, normalizedTargetParts
    },
    If[! kiraReductionQ[kira],
      Message[CoefficientSimplification::input];
      Throw[$Failed, $ibpFailure]
    ];
    data = ibpInputData[inputs, True];
    sourceFingerprint = reductionFingerprint[
      sourceInputPayload[
        data["Records"],
        data["RawTargets"],
        data["AnalyticContext"]
      ]
    ];
    If[
      sourceFingerprint =!=
        Lookup[kira, "SourceInputFingerprint", Missing["NotAvailable"]],
      ibpFail[
        "coefficient input validation",
        "the topology records or GLI targets differ from the Kira input"
      ]
    ];
    sortedPairs[list_List] := SortBy[
      list,
      {Lookup[#1, "Forward"], Lookup[#1, "Conjugate"]} &
    ];
    If[
      data["CardName"] =!= kira["CardName"] ||
        data["ResultDirectory"] =!= kira["ResultDirectory"] ||
        sortedPairs[data["Pairs"]] =!= sortedPairs[kira["Pairs"]],
      ibpFail[
        "coefficient input validation",
        "the Kira reduction does not belong to this result set"
      ]
    ];
    equivalence = kira["TopologyEquivalence"];
    Print["Collecting target coefficients"];
    targetTerms = <||>;
    targetRemainder = 0;
    collectSource[source_] := Module[
      {result, sourceParts, sourceMomenta, offendingMomenta},
      result = If[StringQ[source], Quiet @ Check[Get[source], $Failed], source];
      If[! validPreIBPResultQ[result],
        ibpFail["target coefficient collection", "could not read a pre-IBP result"]
      ];
      sourceParts = linearIntegralSum[result["Integrand"]];
      If[FailureQ[sourceParts],
        ibpFail[
          "target coefficient collection",
          "a pre-IBP expression is not linear in explicit GLI objects"
        ]
      ];
      sourceMomenta = coefficientForbiddenMomenta[result["Setup"]];
      offendingMomenta = remainingDeclaredMomenta[
        {Values[sourceParts["Terms"]], sourceParts["Remainder"]},
        sourceMomenta
      ];
      If[offendingMomenta =!= {},
        ibpFail[
          "target coefficient collection",
          "a pre-IBP coefficient still contains integrated momenta: " <>
            ToString[offendingMomenta, InputForm]
        ]
      ];
      If[AssociationQ[equivalence] && KeyExistsQ[equivalence, "GLIRules"],
        sourceParts = linearMapIntegrals[
          sourceParts,
          equivalence["GLIRules"]
        ];
        If[FailureQ[sourceParts],
          ibpFail[
            "target coefficient collection",
            "a verified topology rule did not return a linear GLI sum"
          ]
        ]
      ];
      sourceParts = linearScale[sourceParts, result["PreFactor"]];
      KeyValueMap[
        Function[{integral, coefficient},
          AssociateTo[
            targetTerms,
            integral -> (Lookup[targetTerms, integral, 0] + coefficient)
          ]
        ],
        sourceParts["Terms"]
      ];
      targetRemainder += sourceParts["Remainder"];
      Null
    ];
    Scan[collectSource, data["Sources"]];
    targetParts = <|
      "Terms" -> canonicalizeLinearTerms[targetTerms],
      "Remainder" -> targetRemainder
    |>;
    If[
      ! linearIntegralSumStructureQ[targetParts] ||
        ! FreeQ[targetRemainder, _FeynCalc`GLI],
      ibpFail[
        "target coefficient collection",
        "the sparse integral sums could not be accumulated"
      ]
    ];
    targets = Keys[targetParts["Terms"]];
    kiraTargetSet = AssociationThread[
      kira["Targets"],
      ConstantArray[True, Length[kira["Targets"]]]
    ];
    If[
      Length[kiraTargetSet] =!= Length[kira["Targets"]] ||
        Length[targets] =!= Length[kira["Targets"]] ||
        ! AllTrue[targets, KeyExistsQ[kiraTargetSet, #] &],
      ibpFail[
        "target coefficient collection",
        "the collected targets differ from the targets reduced by Kira"
      ]
    ];
    Print["Applying hadronic kinematics to target coefficients"];
    {targetPhysicalSeconds, normalizedTargetParts} = AbsoluteTiming[
      physicalizeLinearCoefficientParts[
        targetParts,
        data["AnalyticContext"]
      ]
    ];
    If[normalizedTargetParts === $Failed,
      ibpFail[
        "target coefficient kinematics",
        "the card-defined hadronic coordinates could not be applied exactly"
      ]
    ];
    targetParts = normalizedTargetParts;
    Print[
      "Hadronic kinematics applied in ",
      Round[targetPhysicalSeconds, 0.01],
      " s"
    ];
    Print["Simplifying target coefficients"];
    {targetNormalizeSeconds, normalizedTargetParts} = AbsoluteTiming[
      normalizeLinearCoefficientParts[
        targetParts,
        data["AnalyticContext", "Assumptions"]
      ]
    ];
    If[normalizedTargetParts === $Failed,
      ibpFail[
        "target coefficient simplification",
        "exact target-level coefficient simplification failed"
      ]
    ];
    targetParts = normalizedTargetParts;
    Print[
      "Target coefficients simplified in ",
      Round[targetNormalizeSeconds, 0.01],
      " s"
    ];
    Print["Applying Kira rules"];
    sparseReduction = compileSparseReduction[
      targets,
      Dispatch[kira["KiraRules"]],
      Function[coefficient,
        coefficient /. kira["ReverseRules"] /. kira["DimensionRule"]
      ]
    ];
    If[FailureQ[sparseReduction],
      ibpFail[
        "Kira rule application",
        "the compact Kira rules could not be compiled sparsely"
      ]
    ];
    Print["Restoring physical kinematics"];
    Print["Collecting master coefficients"];
    physicalParts = linearComposeReduction[
      targetParts,
      sparseReduction
    ];
    If[FailureQ[physicalParts],
      ibpFail[
        "Kira rule application",
        "the reduction did not produce a linear master-integral sum"
      ]
    ];
    physicalParts = linearMapCoefficients[
      physicalParts,
      Function[coefficient, coefficient /. $dimensionRule]
    ];
    forbiddenMomenta = coefficientForbiddenMomenta[data["Setup"]];
    remainingMomenta = remainingDeclaredMomenta[
      {Values[physicalParts["Terms"]], physicalParts["Remainder"]},
      forbiddenMomenta
    ];
    If[remainingMomenta =!= {},
      ibpFail[
        "master coefficient collection",
        "a reduced master coefficient still contains integrated momenta: " <>
          ToString[remainingMomenta, InputForm]
      ]
    ];
    If[
      ! FreeQ[
        {Values[physicalParts["Terms"]], physicalParts["Remainder"]},
        System`D
      ],
      ibpFail[
        "dimension convention",
        "the reduced coefficients still contain an independent D"
      ]
    ];
    unexpectedMasters = Complement[
      Keys[physicalParts["Terms"]],
      kira["Masters"],
      SameTest -> SameQ
    ];
    If[unexpectedMasters =!= {},
      ibpFail[
        "master coefficient collection",
        "the reduction produced a master outside the validated Kira set"
      ]
    ];
    cutCheck = validateCutGLIs[
      Keys[physicalParts["Terms"]],
      kira["Topologies"]
    ];
    If[cutCheck =!= True,
      ibpFail[
        "master coefficient collection",
        "a final master removes a required cut or has invalid arity"
      ]
    ];

    Print["Simplifying master coefficients"];
    coefficientResult = normalizeMasterCoefficients[
      physicalParts,
      "Master coefficients",
      data["Setup"],
      data["AnalyticContext"]
    ];
    commonPreFactor = coefficientResult["PreFactor"];
    masters = coefficientResult["Masters"];
    coefficientPreFactors = coefficientResult["PreFactors"];
    reducedCoefficients = coefficientResult["Coefficients"];
    recordByName = Association[
      #1["Topology"][[1]] -> #1 & /@ kira["Topologies"]
    ];
    classByName = If[
      AssociationQ[equivalence] && KeyExistsQ[equivalence, "Classes"],
      Association[
        #1["Representative"] -> #1 & /@ equivalence["Classes"]
      ],
      <||>
    ];
    masterData = MapThread[
      Function[{master, coefficientPreFactor, coefficient},
        With[{record = recordByName[master[[1]]]},
          <|
            "Master" -> master,
            "PreFactor" -> coefficientPreFactor,
            "Coefficient" -> coefficient,
            "TopologyName" -> master[[1]],
            "CutMomenta" -> record["CutMomenta"],
            "CutIndices" -> record["CutIndices"],
            "CutDirections" -> record["CutDirections"],
            "TopologyClass" -> Lookup[
              classByName,
              master[[1]],
              Missing["NotFound"]
            ]
          |>
        ]
      ],
      {masters, coefficientPreFactors, reducedCoefficients}
    ];
    reconstructed = commonPreFactor (
      Total[
        #1["PreFactor"] #1["Coefficient"] #1["Master"] & /@
          masterData
      ] + coefficientResult["Remainder"]
    );
    If[! SameQ[coefficientResult["Expression"], reconstructed],
      ibpFail[
        "master coefficient extraction",
        "the stored factors do not reconstruct the simplified expression"
      ]
    ];
    If[
      ! exactDataQ @ HoldComplete[
        commonPreFactor, coefficientResult["Remainder"], reconstructed,
        masterData, coefficientResult["HadronicNormalization"],
        kira["KiraRules"], kira["ReverseRules"], equivalence
      ],
      ibpFail[
        "result validation",
        "the analytic IBP result contains inexact numerical data"
      ]
    ];
    compactSize = ByteCount[{
      commonPreFactor,
      coefficientResult["Remainder"],
      masterData,
      kira["KiraRules"],
      kira["ReverseRules"],
      equivalence
    }];
    Print @ Grid[
      {
        {"Pairs", Length[inputs]},
        {"Topology classes", Length[kira["Topologies"]]},
        {"Input integrals", Length[kira["Targets"]]},
        {"Master integrals", Length[masters]},
        {"Compact result size (kB)", Round[compactSize/1024., 0.01]}
      },
      Frame -> All
    ];
    Join[
      resultHeader["FeynFacet-IBP", 7],
      resultContext[data],
      <|
      "FractionMeasure" -> data["FractionMeasure"],
      "PhaseSpace" -> data["PhaseSpace"],
      "PreFactor" -> commonPreFactor,
      "Remainder" -> coefficientResult["Remainder"],
      "Expression" -> reconstructed,
      "Masters" -> masterData,
      "HadronicNormalization" ->
        coefficientResult["HadronicNormalization"],
      "Topologies" -> kira["Topologies"],
      "KiraRules" -> kira["KiraRules"],
      "ReverseRules" -> kira["ReverseRules"],
      "TopologyEquivalence" -> equivalence,
      "Assumptions" -> data["AnalyticContext", "Assumptions"],
      "AnalyticContext" -> data["AnalyticContext"],
      "MassDimensions" -> kira["MassDimensions"],
      "KiraManifest" -> kira["KiraManifest"],
      "DimensionRule" -> $dimensionRule,
      "ReductionInputFingerprint" -> kira["ReductionInputFingerprint"],
      "SourceInputFingerprint" -> kira["SourceInputFingerprint"]
      |>
    ]
  ],
  $ibpFailure
];

CoefficientSimplification[
    inputs : ({__Association} | {__String}),
    kira_Association
  ] := coefficientSimplificationCore[inputs, kira];

KiraReduction[___] := (
  Message[KiraReduction::input];
  $Failed
);

KiraImportReduction[___] := (
  Message[KiraImportReduction::input];
  $Failed
);

CoefficientSimplification[___] := (
  Message[CoefficientSimplification::input];
  $Failed
);
