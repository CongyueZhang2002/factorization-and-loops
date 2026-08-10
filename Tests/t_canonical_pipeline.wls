(* Acceptance test for the canonical-family pipeline integration
   (Design/CanonicalFamiliesIntegration.md).

   The monolithic reduction of the regenerated NLO UU 10x10 pair set stays
   the reference: canonicalizing those pairs into one shared family registry
   and reducing the canonicalized artifacts must reproduce its physics.

   Acceptance criteria:
   1. CanonicalizePairArtifacts folds the 100 pairs into exactly 11 canonical
      families with zero collisions and zero rejected candidate mappings, and
      every canonicalized artifact passes validPreIBPResultQ, carries the
      registry fingerprint and points at the new result directory.
   2. KiraReduction on the canonicalized artifacts saves KiraResult.wl, and
      its stored TopologyEquivalence is the identity partition: SearchStatus
      "CanonicalIdentity" and one singleton class per canonical family, with
      no mappings and no GLI rules.
   3. Semantic equality with the reference reduction: the same master COUNT,
      the reference masters mapped through the canonicalization GLI rules are
      the canonical master set, and for every reference target the canonical
      reduction image of the mapped target agrees with the mapped reference
      image master by master; every coefficient difference vanishes under
      exactZeroQ. Rule lists are never compared structurally.
   4. Idempotence: canonicalizing the canonicalized pairs reproduces the
      registry fingerprint and the artifacts themselves (up to the creation
      timestamp and the new result directory). *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

sourceDirectory = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_10_10x10_regen"
}];
canonicalDirectory = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_10_canonical"
}];
scratchDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NLO", "CanonicalIdempotence"
}];

sourcePairFiles = Sort[FileNames["F*_C*.wl",
  FileNameJoin[{sourceDirectory, "Pairs"}]]];
referenceFile = FileNameJoin[{sourceDirectory, "KiraResult.wl"}];
canonicalResultFile = FileNameJoin[{canonicalDirectory, "KiraResult.wl"}];

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

text[list_] := Sort[ToString[#, InputForm] & /@ list];

(* --- 1. canonicalization --------------------------------------------- *)

assert["1. 100 regenerated pair artifacts and the reference reduction",
  Length[sourcePairFiles] === 100 && FileExistsQ[referenceFile]];

{canonicalSeconds, canonical} = AbsoluteTiming[
  FeynFacet`Private`CanonicalizePairArtifacts[
    sourcePairFiles,
    canonicalDirectory
  ]
];

canonicalOK = AssociationQ[canonical] &&
  ContainsAll[
    Keys[canonical],
    {"Files", "Registry", "Fingerprint", "Families", "FamilyCount",
      "Classes", "Rejected", "GLIRules", "CanonicalNames", "Collisions"}
  ];
assert["1. CanonicalizePairArtifacts returned the documented result",
  canonicalOK];

assert["1. exactly 11 canonical families",
  canonicalOK && canonical["FamilyCount"] === 11 &&
    Length[canonical["Registry"]["Families"]] === 11 &&
    Length[canonical["Classes"]] === 11];
assert["1. zero collisions and zero rejected candidate mappings",
  canonicalOK && canonical["Collisions"] === 0 &&
    canonical["Rejected"] === {} &&
    Complement[canonical["Statuses"], {"Registered", "Mapped"}] === {}];
assert["1. every canonical family is a Global` CF symbol",
  canonicalOK && AllTrue[
    Lookup[canonical["Families"], "Name"],
    Head[#] === Symbol && Context[#] === "Global`" &&
      StringMatchQ[SymbolName[#], "CF" ~~ DigitCharacter ..] &
  ]];
assert["1. the registry and its manifest were written",
  canonicalOK &&
    FileExistsQ[FileNameJoin[{canonicalDirectory, "CanonicalRegistry.wxf"}]] &&
    FileExistsQ[FileNameJoin[{canonicalDirectory, "CanonicalRegistry.wl"}]] &&
    AssociationQ @ FeynFacet`Private`coefficientReadRecord[
      FileNameJoin[{canonicalDirectory, "CanonicalRegistry.wxf"}]
    ] &&
    Get[FileNameJoin[{canonicalDirectory, "CanonicalRegistry.wl"}]] ===
      canonical["Manifest"]];

canonicalPairFiles = Sort[FileNames["F*_C*.wl",
  FileNameJoin[{canonicalDirectory, "Pairs"}]]];
canonicalArtifacts = Get /@ canonicalPairFiles;

assert["1. the same 100 pair basenames were written",
  Length[canonicalPairFiles] === 100 &&
    (FileNameTake /@ canonicalPairFiles) ===
      (FileNameTake /@ sourcePairFiles)];
assert["1. every canonicalized artifact passes validPreIBPResultQ",
  AllTrue[canonicalArtifacts, FeynFacet`Private`validPreIBPResultQ]];
assert["1. every canonicalized artifact carries the registry fingerprint",
  canonicalOK &&
    DeleteDuplicates[
      Lookup[canonicalArtifacts, "CanonicalRegistryFingerprint"]
    ] === {canonical["Fingerprint"]}];
assert["1. every canonicalized artifact points at the output directory",
  DeleteDuplicates[Lookup[canonicalArtifacts, "ResultDirectory"]] ===
    {FeynFacet`Private`ibpNormalizedPath[canonicalDirectory]}];
assert["1. the artifacts declare canonical families only",
  AllTrue[
    canonicalArtifacts,
    Function[artifact,
      DuplicateFreeQ[#["Topology"][[1]] & /@ artifact["Topologies"]] &&
        ContainsAll[
          #["Topology"][[1]] & /@ artifact["Topologies"],
          DeleteDuplicates[
            First /@ Cases[artifact["Integrand"], _FeynCalc`GLI, {0, Infinity}]
          ]
        ] &&
        AllTrue[
          artifact["Topologies"],
          StringMatchQ[
            SymbolName[#["Topology"][[1]]],
            "CF" ~~ DigitCharacter ..
          ] &
        ]
    ]
  ]];
assert["1. the registry is exact data",
  canonicalOK &&
    FeynFacet`Private`exactDataQ[canonical["Registry"]] &&
    AllTrue[canonicalArtifacts, FeynFacet`Private`exactDataQ]];

(* --- 2. reduction of the canonicalized artifacts ---------------------- *)

{reductionSeconds, savedPath} = AbsoluteTiming[
  FeynFacet`KiraReduction[canonicalPairFiles, canonicalResultFile]
];

assert["2. KiraReduction saved the canonical reduction artifact",
  StringQ[savedPath] &&
    FeynFacet`Private`ibpNormalizedPath[savedPath] ===
      FeynFacet`Private`ibpNormalizedPath[canonicalResultFile] &&
    FileExistsQ[canonicalResultFile]];

canonicalKira = If[FileExistsQ[canonicalResultFile],
  Get[canonicalResultFile],
  $Failed
];
assert["2. kiraReductionQ accepts the canonical reduction",
  AssociationQ[canonicalKira] &&
    FeynFacet`Private`kiraReductionQ[canonicalKira]];

canonicalEquivalence = If[AssociationQ[canonicalKira],
  canonicalKira["TopologyEquivalence"],
  <||>
];
assert["2. the stored equivalence is the canonical identity",
  AssociationQ[canonicalEquivalence] &&
    canonicalEquivalence["SearchStatus"] === "CanonicalIdentity" &&
    canonicalEquivalence["Scope"] === "CutAwareIBP" &&
    canonicalEquivalence["Mappings"] === {} &&
    canonicalEquivalence["GLIRules"] === {} &&
    canonicalEquivalence["RejectedCandidateMappings"] === {}];
assert["2. every equivalence class is a singleton canonical family",
  AssociationQ[canonicalEquivalence] &&
    Length[canonicalEquivalence["Classes"]] === 11 &&
    AllTrue[
      canonicalEquivalence["Classes"],
      Length[#["Members"]] === 1 &&
        #["Members"] === {#["Representative"]} &&
        #["SearchStatus"] === "Canonical" &
    ] &&
    text[Lookup[canonicalEquivalence["Classes"], "Representative"]] ===
      text[Lookup[canonical["Families"], "Name"]]];
assert["2. no pinched cut in the canonical reduction",
  AssociationQ[canonicalKira] &&
    FeynFacet`Private`validateCutGLIs[
      canonicalKira["KiraRules"], canonicalKira["Topologies"]
    ] === True &&
    FeynFacet`Private`validateCutGLIs[
      canonicalKira["Masters"], canonicalKira["Topologies"]
    ] === True];

(* --- 3. semantic equality with the reference reduction ---------------- *)

reference = Get[referenceFile];
canonicalRules = If[canonicalOK, Dispatch[canonical["GLIRules"]], {}];

mappedReferenceMasters = If[AssociationQ[reference],
  DeleteDuplicates[Replace[#, canonicalRules, {0}] & /@ reference["Masters"]],
  {}
];

assert["3. identical master count",
  AssociationQ[reference] && AssociationQ[canonicalKira] &&
    Length[canonicalKira["Masters"]] === Length[reference["Masters"]]];
assert["3. the mapped reference masters are the canonical master set",
  AssociationQ[reference] && AssociationQ[canonicalKira] &&
    Length[mappedReferenceMasters] === Length[reference["Masters"]] &&
    text[mappedReferenceMasters] === text[canonicalKira["Masters"]]];

imageFailures = {};
comparedTargets = 0;
comparedCoefficients = 0;

If[AssociationQ[reference] && AssociationQ[canonicalKira] && canonicalOK,
  Module[
    {
      referenceRules, canonicalReductionRules, referenceReverse,
      canonicalReverse, dimensionRule, sameCoefficientQ, masterSet
    },

    referenceRules = Dispatch[reference["KiraRules"]];
    canonicalReductionRules = Dispatch[canonicalKira["KiraRules"]];
    referenceReverse = reference["ReverseRules"];
    canonicalReverse = canonicalKira["ReverseRules"];
    dimensionRule = FeynFacet`Private`$dimensionRule;
    masterSet = text[canonicalKira["Masters"]];

    (* Coefficients live in different generated invariant bases only if the
       kinematic completion differs; both are resolved before comparing. *)
    sameCoefficientQ[a_, b_] := TrueQ[
      a === b ||
        FeynFacet`Private`exactZeroQ[a - b] ||
        FeynFacet`Private`exactZeroQ[
          ((a /. referenceReverse) /. dimensionRule) -
            ((b /. canonicalReverse) /. dimensionRule)
        ]
    ];

    Do[
      Module[{referenceImage, mappedImage, canonicalTarget, canonicalImage, keys},
        referenceImage = FeynFacet`Private`linearIntegralSum[
          target /. referenceRules
        ];
        canonicalTarget = Replace[target, canonicalRules, {0}];
        canonicalImage = FeynFacet`Private`linearIntegralSum[
          canonicalTarget /. canonicalReductionRules
        ];
        mappedImage = If[
          FeynFacet`Private`linearIntegralSumQ[referenceImage],
          FeynFacet`Private`linearMapIntegrals[referenceImage, canonicalRules],
          referenceImage
        ];
        Which[
          ! MatchQ[canonicalTarget, _FeynCalc`GLI],
            AppendTo[imageFailures, {target, "target does not map"}],
          ! FeynFacet`Private`linearIntegralSumQ[mappedImage] ||
            ! FeynFacet`Private`linearIntegralSumQ[canonicalImage],
            AppendTo[imageFailures, {target, "not a linear integral sum"}],
          True,
            keys = DeleteDuplicates[
              Join[Keys[mappedImage["Terms"]], Keys[canonicalImage["Terms"]]],
              SameQ
            ];
            If[! AllTrue[keys, MemberQ[masterSet, ToString[#, InputForm]] &],
              AppendTo[imageFailures, {target, "image is not a master sum"}]
            ];
            Scan[
              Function[master,
                comparedCoefficients++;
                If[
                  ! sameCoefficientQ[
                    Lookup[mappedImage["Terms"], master, 0],
                    Lookup[canonicalImage["Terms"], master, 0]
                  ],
                  AppendTo[imageFailures, {target, master}]
                ]
              ],
              keys
            ];
            If[
              ! sameCoefficientQ[
                mappedImage["Remainder"],
                canonicalImage["Remainder"]
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

assert["3. every reference target has the same reduction image",
  AssociationQ[reference] &&
    comparedTargets === Length[reference["Targets"]] &&
    comparedCoefficients >= Length[reference["Targets"]] &&
    imageFailures === {}];
If[imageFailures =!= {},
  Print["    mismatching targets: ", Take[imageFailures, UpTo[5]]]];

assert["3. the reference reduction artifact is unchanged",
  StringQ[referenceHash] &&
    FileHash[referenceFile, "SHA256", "HexString"] === referenceHash];

(* --- 4. idempotence --------------------------------------------------- *)

If[DirectoryQ[scratchDirectory],
  DeleteDirectory[scratchDirectory, DeleteContents -> True]];

{idempotenceSeconds, again} = AbsoluteTiming[
  FeynFacet`Private`CanonicalizePairArtifacts[
    canonicalPairFiles,
    scratchDirectory
  ]
];

assert["4. re-canonicalization reproduces the registry fingerprint",
  AssociationQ[again] && canonicalOK &&
    again["Fingerprint"] === canonical["Fingerprint"] &&
    again["FamilyCount"] === canonical["FamilyCount"] &&
    again["Collisions"] === 0 && again["Rejected"] === {} &&
    FeynFacet`Private`canonicalRegistryPayload[again["Registry"]] ===
      FeynFacet`Private`canonicalRegistryPayload[canonical["Registry"]]];

againFiles = Sort[FileNames["F*_C*.wl",
  FileNameJoin[{scratchDirectory, "Pairs"}]]];
(* The result directory is part of the artifact and is the one thing a
   second output location must change. *)
comparable[artifact_] := KeyDrop[artifact, {"Created", "ResultDirectory"}];
differingArtifacts = If[
  Length[againFiles] === Length[canonicalPairFiles],
  Select[
    Range[Length[againFiles]],
    comparable[Get[againFiles[[#]]]] =!= comparable[canonicalArtifacts[[#]]] &
  ],
  All
];

assert["4. the re-canonicalized artifacts are the canonicalized artifacts",
  Length[againFiles] === 100 &&
    (FileNameTake /@ againFiles) === (FileNameTake /@ canonicalPairFiles) &&
    differingArtifacts === {}];

If[DirectoryQ[scratchDirectory],
  DeleteDirectory[scratchDirectory, DeleteContents -> True]];

(* --- reporting -------------------------------------------------------- *)
seconds[value_] := If[NumericQ[value], N[Round[value, 1/100]], value];

Print[StringRepeat["-", 48]];
Print["    canonicalization wall time (s): ", seconds[canonicalSeconds]];
Print["    KiraReduction wall time (s):    ", seconds[reductionSeconds]];
Print["    re-canonicalization (s):        ", seconds[idempotenceSeconds]];
If[canonicalOK,
  Print["    canonical families:             ", canonical["FamilyCount"]];
  Print["    registry fingerprint:           ", canonical["Fingerprint"]];
  Print["    class sizes:                    ",
    Length /@ Lookup[canonical["Classes"], "Members"]]
];
If[AssociationQ[canonicalKira],
  Print["    targets / masters (canonical):  ",
    Length[canonicalKira["Targets"]], " / ",
    Length[canonicalKira["Masters"]]]
];
If[AssociationQ[reference],
  Print["    targets / masters (reference):  ",
    Length[reference["Targets"]], " / ", Length[reference["Masters"]]]
];
Print["    compared master coefficients:   ", comparedCoefficients];

FTTest`FTReport[];
