root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
SetDirectory[root];
$HistoryLength = 0;

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

card = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
resultDirectory = CreateDirectory[];
setup = Join[card, <|
  "CardName" -> "UU_StrictContractTest"
|>];
setup["ForwardAmplitudes", "SelectedIndex"] = 1;
setup["ConjugateAmplitudes", "SelectedIndex"] = 2;

process = Catch[
  FeynFacet`Private`normalizeProcess[setup],
  FeynFacet`Private`$collinearFailure
];
context = If[
  AssociationQ[process],
  FeynFacet`Private`analyticContext[process],
  $Failed
];

exactInputAccepted = AssociationQ[process] && AssociationQ[context];
inexactSetup = Join[setup, <|"KinematicMassDimensions" -> <|s -> 2.0|>|>];
inexactInputRejected = Quiet[
  Catch[
    FeynFacet`Private`normalizeProcess[inexactSetup],
    FeynFacet`Private`$collinearFailure
  ]
] === $Failed;

FeynCalc`FCSetDiracGammaScheme["NDR"];
ndrContextRejected = FeynFacet`Private`analyticContext[process] === $Failed;
FeynCalc`FCSetDiracGammaScheme["BMHV"];

preIBP = FeynFacet`CollinearFactorizePreIBP[setup];
artifact = If[
  MatchQ[preIBP, {_, _, _, _, _}],
  FeynFacet`GenerateCollinearFactorizePreIBPResult[
    setup,
    Sequence @@ preIBP,
    resultDirectory
  ],
  $Failed
];

validArtifactAccepted = AssociationQ[artifact] &&
  TrueQ[FeynFacet`Private`validPreIBPResultQ[artifact]];

badContextArtifact = If[
  AssociationQ[artifact],
  Append[
    artifact,
    "AnalyticContext" -> Append[
      artifact["AnalyticContext"],
      "Gamma5Scheme" -> "NDR"
    ]
  ],
  <||>
];
badContextRejected = AssociationQ[artifact] &&
  ! TrueQ[FeynFacet`Private`validPreIBPResultQ[badContextArtifact]];

badRecordArtifact = If[
  AssociationQ[artifact] && artifact["Topologies"] =!= {},
  Append[
    artifact,
    "Topologies" -> ReplacePart[
      artifact["Topologies"],
      1 -> KeyDrop[First[artifact["Topologies"]], "CutDirections"]
    ]
  ],
  <||>
];
badRecordRejected = AssociationQ[artifact] &&
  ! TrueQ[FeynFacet`Private`validPreIBPResultQ[badRecordArtifact]];

badRecordContextArtifact = If[
  AssociationQ[artifact] && artifact["Topologies"] =!= {},
  Append[
    artifact,
    "Topologies" -> ReplacePart[
      artifact["Topologies"],
      1 -> Append[
        First[artifact["Topologies"]],
        "AnalyticContext" -> Append[
          First[artifact["Topologies"]]["AnalyticContext"],
          "Fingerprint" -> "tampered"
        ]
      ]
    ]
  ],
  <||>
];
badRecordContextRejected = AssociationQ[artifact] &&
  ! TrueQ[
    FeynFacet`Private`validPreIBPResultQ[badRecordContextArtifact]
  ];

checks = <|
  "ExactInputAccepted" -> exactInputAccepted,
  "InexactInputRejected" -> inexactInputRejected,
  "NDRContextRejected" -> ndrContextRejected,
  "ValidArtifactAccepted" -> validArtifactAccepted,
  "MissingCutMetadataRejected" -> badRecordRejected,
  "TopLevelContextMismatchRejected" -> badContextRejected,
  "TopologyContextMismatchRejected" -> badRecordContextRejected
|>;

Print[checks];
Quiet[DeleteDirectory[resultDirectory, DeleteContents -> True]];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
