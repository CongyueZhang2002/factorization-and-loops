(* Acceptance test for the streaming Kira import (Design/StreamingKiraImport.md).

   The monolithic KiraReduction stays the reference: the streaming
   solve/import/load path must reproduce its physics content exactly on the
   regenerated NLO UU 10x10 pair set.

   Acceptance criteria:
   A. The 100 regenerated pair files are present and pass validPreIBPResultQ.
   B. KiraSolve prepares and runs Kira and RETAINS the solved workspace on
      disk (jobs.yaml, results/kira.db, one exported rule table and one
      masters.final per family).
   C. KiraStreamImport writes <ResultDirectory>/KiraStream/ and its manifest
      validates (format, content fingerprint, per-file size and SHA-256).
   D. KiraStreamResult loads an Association that kiraReductionQ accepts, with
      the same Targets set and the same Masters set as the saved
      KiraResult.wl, and for EVERY target the closed reduction image agrees:
      the per-master coefficient differences are exactly zero.  Rule lists are
      never compared structurally.
   E. The loaded reduction is exact data and pinches no cut, and the manifest
      payload that carries the fingerprint is exact data as well.
   F. The reference KiraResult.wl is not modified.

   The retained Kira workspace is removed only if every assertion passed. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

resultDirectory = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_10_10x10_regen"
}];
pairDirectory = FileNameJoin[{resultDirectory, "Pairs"}];
referenceFile = FileNameJoin[{resultDirectory, "KiraResult.wl"}];

pairFiles = Sort[FileNames["F*_C*.wl", pairDirectory]];
referenceHash = If[FileExistsQ[referenceFile],
  FileHash[referenceFile, "SHA256", "HexString"],
  Missing["NoReference"]
];

results = {};
assert[label_String, condition_] := Module[{ok},
  ok = FTTest`FTAssert[label, condition];
  AppendTo[results, ok];
  ok
];

sortedText[list_] := Sort[ToString[#, InputForm] & /@ list];

(* --- A. inputs --------------------------------------------------------- *)
assert["A. 100 regenerated pair files present",
  Length[pairFiles] === 100 && FileExistsQ[referenceFile]];
assert["A. every pair file passes validPreIBPResultQ",
  AllTrue[pairFiles, FeynFacet`Private`validPreIBPResultQ[Get[#]] &]];

(* --- B. solve stage ---------------------------------------------------- *)
{solveSeconds, solveData} = AbsoluteTiming[
  FeynFacet`Private`KiraSolve[pairFiles, resultDirectory]
];

solveOK = AssociationQ[solveData] &&
  FeynFacet`Private`kiraSolveDataQ[solveData];
assert["B. KiraSolve returned solve-stage data", solveOK];

workspaceFiles = If[solveOK,
  Join[
    {
      FileNameJoin[{solveData["ProjectDirectory"], "jobs.yaml"}],
      FileNameJoin[{solveData["ProjectDirectory"], "results", "kira.db"}],
      FileNameJoin[{solveData["ProjectRoot"], "reduction_input.wxf"}]
    },
    Flatten @ Map[
      Function[item,
        {
          FileNameJoin[{
            solveData["ProjectDirectory"], "results",
            ToString[item["Name"], InputForm],
            "kira_integrals_" <> ToString[item["Ordinal"]] <> ".m"
          }],
          FileNameJoin[{
            solveData["ProjectDirectory"], "results",
            ToString[item["Name"], InputForm], "masters.final"
          }]
        }
      ],
      solveData["Manifest"]
    ]
  ],
  {}
];

assert["B. the solved Kira workspace is retained on disk",
  solveOK && DirectoryQ[solveData["ProjectDirectory"]] &&
    workspaceFiles =!= {} && AllTrue[workspaceFiles, FileExistsQ]];
assert["B. the workspace lives under Codex/<process>/Kira",
  solveOK && StringContainsQ[
    solveData["ProjectRoot"],
    FileNameJoin[{root, "Codex"}] <> $PathnameSeparator
  ]];

(* --- C. streaming import ---------------------------------------------- *)
{importSeconds, streamDirectory} = AbsoluteTiming[
  FeynFacet`Private`KiraStreamImport[solveData]
];

assert["C. KiraStreamImport wrote the directory artifact",
  StringQ[streamDirectory] && DirectoryQ[streamDirectory] &&
    FileExistsQ[FileNameJoin[{streamDirectory, "Manifest.wl"}]] &&
    FeynFacet`Private`ibpNormalizedPath[DirectoryName[streamDirectory]] ===
      FeynFacet`Private`ibpNormalizedPath[resultDirectory]];

manifest = If[StringQ[streamDirectory],
  Catch[
    FeynFacet`Private`kiraStreamReadManifest[streamDirectory],
    FeynFacet`Private`$ibpFailure
  ],
  $Failed
];

assert["C. the streaming manifest validates (fingerprint, sizes, hashes)",
  AssociationQ[manifest] &&
    FeynFacet`Private`kiraStreamManifestQ[manifest, streamDirectory]];
assert["C. every family has a rule record and a reduced record",
  AssociationQ[manifest] &&
    Length[manifest["Families"]] === manifest["FamilyCount"] &&
    AllTrue[
      manifest["Families"],
      FileExistsQ[FileNameJoin[{streamDirectory, #["Rules"]["File"]}]] &&
        FileExistsQ[FileNameJoin[{streamDirectory, #["Reduced"]["File"]}]] &
    ]];
assert["C. the manifest records the solved-project fingerprint",
  AssociationQ[manifest] && solveOK &&
    manifest["SolvedProjectFingerprint"] ===
      solveData["SolvedProjectFingerprint"]];

(* --- D. compatibility loader vs the monolithic reference -------------- *)
{loadSeconds, loaded} = AbsoluteTiming[
  FeynFacet`Private`KiraStreamResult[streamDirectory]
];
reference = Get[referenceFile];

assert["D. kiraReductionQ accepts the loaded Association",
  AssociationQ[loaded] && FeynFacet`Private`kiraReductionQ[loaded]];
assert["D. identical Targets set",
  AssociationQ[loaded] && AssociationQ[reference] &&
    sortedText[loaded["Targets"]] === sortedText[reference["Targets"]]];
assert["D. identical Masters set",
  AssociationQ[loaded] && AssociationQ[reference] &&
    sortedText[loaded["Masters"]] === sortedText[reference["Masters"]]];
assert["D. identical DeclaredMasters set",
  AssociationQ[loaded] && AssociationQ[reference] &&
    sortedText[loaded["DeclaredMasters"]] ===
      sortedText[reference["DeclaredMasters"]]];

(* Rule lists may be ordered differently and are never compared structurally.
   Both sides are applied to each target and the resulting per-master
   coefficients are subtracted; every difference must be exactly zero. *)
imageFailures = {};
comparedTargets = 0;
comparedCoefficients = 0;
If[AssociationQ[loaded] && AssociationQ[reference],
  Module[{referenceRules, loadedRules, masterSet},
    referenceRules = Dispatch[reference["KiraRules"]];
    loadedRules = Dispatch[loaded["KiraRules"]];
    masterSet = Union[
      ToString[#, InputForm] & /@ reference["Masters"],
      ToString[#, InputForm] & /@ loaded["Masters"]
    ];
    Do[
      Module[{referenceParts, loadedParts, keys},
        referenceParts = FeynFacet`Private`linearIntegralSum[
          target /. referenceRules
        ];
        loadedParts = FeynFacet`Private`linearIntegralSum[
          target /. loadedRules
        ];
        Which[
          FailureQ[referenceParts] || FailureQ[loadedParts],
            AppendTo[imageFailures, {target, "not a linear integral sum"}],
          True,
            keys = DeleteDuplicates[
              Join[Keys[referenceParts["Terms"]], Keys[loadedParts["Terms"]]],
              SameQ
            ];
            If[
              ! AllTrue[keys, MemberQ[masterSet, ToString[#, InputForm]] &],
              AppendTo[imageFailures, {target, "image is not a master sum"}]
            ];
            Scan[
              Function[master,
                comparedCoefficients++;
                If[
                  ! FeynFacet`Private`exactZeroQ[
                    Lookup[referenceParts["Terms"], master, 0] -
                      Lookup[loadedParts["Terms"], master, 0]
                  ],
                  AppendTo[imageFailures, {target, master}]
                ]
              ],
              keys
            ];
            If[
              ! FeynFacet`Private`exactZeroQ[
                referenceParts["Remainder"] - loadedParts["Remainder"]
              ],
              AppendTo[imageFailures, {target, "remainder"}]
            ]
        ];
        comparedTargets++
      ],
      {target, reference["Targets"]}
    ]
  ]
];

assert["D. every target has the same closed reduction image",
  AssociationQ[loaded] && AssociationQ[reference] &&
    comparedTargets === Length[reference["Targets"]] &&
    comparedCoefficients >= Length[reference["Targets"]] &&
    imageFailures === {}];
If[imageFailures =!= {},
  Print["    mismatching targets: ", Take[imageFailures, UpTo[5]]]];

(* --- E. exactness and cut validation ---------------------------------- *)
assert["E. the loaded reduction is exact data",
  AssociationQ[loaded] && FeynFacet`Private`exactDataQ[loaded]];
assert["E. the fingerprinted manifest payload is exact data",
  AssociationQ[manifest] &&
    FeynFacet`Private`exactDataQ[
      FeynFacet`Private`kiraStreamManifestPayload[manifest]
    ]];
assert["E. no pinched cut in the reduction rules",
  AssociationQ[loaded] &&
    FeynFacet`Private`validateCutGLIs[
      loaded["KiraRules"], loaded["Topologies"]
    ] === True];
assert["E. no pinched cut in the masters",
  AssociationQ[loaded] &&
    FeynFacet`Private`validateCutGLIs[
      loaded["Masters"], loaded["Topologies"]
    ] === True];

(* --- F. the reference artifact is untouched --------------------------- *)
assert["F. the reference KiraResult.wl is unchanged",
  StringQ[referenceHash] &&
    FileHash[referenceFile, "SHA256", "HexString"] === referenceHash];

(* --- reporting -------------------------------------------------------- *)
seconds[value_] := If[NumericQ[value], N[Round[value, 1/100]], value];

Print[StringRepeat["-", 48]];
Print["    KiraSolve wall time (s):         ", seconds[solveSeconds]];
Print["    KiraStreamImport wall time (s):  ", seconds[importSeconds]];
Print["    KiraStreamResult wall time (s):  ", seconds[loadSeconds]];
If[AssociationQ[manifest],
  Module[{diagnostics},
    diagnostics = manifest["Diagnostics"];
    Print["    Kira solve (s):                  ",
      seconds[diagnostics["SolveSeconds"]]];
    Scan[
      Print["    import stage ", #["Stage"], " (s): ",
        seconds[#["Seconds"]]] &,
      diagnostics["Stages"]
    ];
    Print["    import total (s):                ",
      seconds[diagnostics["TotalSeconds"]]];
    Print["    peak MemoryInUse (MB):           ",
      diagnostics["PeakMemoryInUseMB"]];
    Print["    families / targets / masters:    ",
      manifest["FamilyCount"], " / ", manifest["TargetCount"], " / ",
      manifest["MasterCount"]];
    Print["    imported / closure rules:        ",
      manifest["ImportedRuleCount"], " / ", manifest["ClosureRuleCount"]];
    Print["    artifact bytes:                  ",
      Total[
        FileByteCount /@ Select[
          FileNames["*", streamDirectory, Infinity],
          ! DirectoryQ[#] &
        ]
      ]];
    Print["    compared master coefficients:    ", comparedCoefficients]
  ]
];

(* --- cleanup: only on a fully green run ------------------------------- *)
If[AllTrue[results, TrueQ] && solveOK,
  Module[{removed},
    removed = Catch[
      FeynFacet`Private`ibpRemoveKiraWorkspace[solveData["ProjectLocation"]];
      True,
      FeynFacet`Private`$ibpFailure
    ];
    Print["    retained Kira workspace removed: ", TrueQ[removed]]
  ],
  Print["    retained Kira workspace kept for debugging: ",
    If[solveOK, solveData["ProjectDirectory"], "unavailable"]]
];

FTTest`FTReport[];
