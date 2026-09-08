root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
SetDirectory[root];
$HistoryLength = 0;
Global`$FACETKernelLimit = 4;

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
benchmarkPackage = Environment["FACET_BENCHMARK_PACKAGE"];
If[StringQ[benchmarkPackage] && benchmarkPackage =!= "",
  Get[ExpandFileName[benchmarkPackage]];
  FeynFacet`Private`$feynFacetRoot = root;
  FeynCalc`FCSetDiracGammaScheme["BMHV"];
  Global`GlobalBasis = FeynFacet`BuildGlobalBasis[{nb, n, xhat, yhat}];
  FeynArts`$FAVerbose = 0
];

card = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
resultDirectory = FileNameJoin[{root, "Codex", "TestResults", "nlo_e2e_modular"}];
If[! DirectoryQ[resultDirectory],
  CreateDirectory[resultDirectory, CreateIntermediateDirectories -> True]
];
setup = Join[card, <|"CardName" -> "UU_NLOReductionTest"|>];
setup["ForwardAmplitudes", "SelectedIndex"] = 1;
setup["ConjugateAmplitudes", "SelectedIndex"] = 2;

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

{kiraTime, kiraFile} = AbsoluteTiming[
  If[
    AssociationQ[artifact],
    FeynFacet`KiraReduction[
      {artifact},
      FileNameJoin[{resultDirectory, "KiraResult.wl"}]
    ],
    $Failed
  ]
];
kira = If[
  StringQ[kiraFile] && FileExistsQ[kiraFile],
  Get[kiraFile],
  $Failed
];
{coefficientTime, reduced} = AbsoluteTiming[
  If[
    AssociationQ[kira],
    FeynFacet`CoefficientSimplification[{artifact}, kira],
    $Failed
  ]
];

masterData = If[AssociationQ[reduced], Lookup[reduced, "Masters", {}], {}];
masterGLIs = If[
  AllTrue[masterData, AssociationQ],
  Lookup[masterData, "Master", {}],
  {}
];
checks = <|
  "ArtifactValid" -> AssociationQ[artifact] &&
    TrueQ[FeynFacet`Private`validPreIBPResultQ[artifact]],
  "KiraReturned" -> AssociationQ[kira] &&
    kira["Format"] === "FeynFacet-KiraReduction",
  "KiraArtifactValid" -> AssociationQ[kira] &&
    FeynFacet`Private`kiraReductionQ[kira],
  "MalformedKiraArtifactRejected" -> AssociationQ[kira] &&
    ! FeynFacet`Private`kiraReductionQ[KeyDrop[kira, {"KiraRules"}]],
  "TargetsReduced" -> AssociationQ[kira] && kira["Targets"] =!= {} &&
    kira["Masters"] =!= {},
  "ExactKiraRules" -> AssociationQ[kira] &&
    ListQ[kira["KiraRules"]] &&
    FeynFacet`Private`exactDataQ[kira["KiraRules"]],
  "ReducedReturned" -> AssociationQ[reduced] &&
    reduced["Format"] === "FeynFacet-IBP",
  "MastersReturned" -> masterData =!= {} &&
    AllTrue[masterGLIs, MatchQ[#, _FeynCalc`GLI] &],
  "CutsPreserved" -> AssociationQ[reduced] &&
    FeynFacet`Private`validateCutGLIs[
      masterGLIs,
      reduced["Topologies"]
    ] === True,
  "ExactFinalExpression" -> AssociationQ[reduced] &&
    FeynFacet`Private`exactDataQ[reduced["Expression"]],
  "NoIndependentD" -> AssociationQ[reduced] &&
    FreeQ[reduced["Expression"], System`D]
|>;

Print[<|"KiraSeconds" -> kiraTime, "CoefficientSeconds" -> coefficientTime|>];
Print[<|"ResultDirectory" -> resultDirectory|>];
Print[checks];
If[! And @@ Values[checks], Exit[1]];
Quiet[DeleteDirectory[resultDirectory, DeleteContents -> True]];
Exit[0];
