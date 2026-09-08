root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

resultDirectory = CreateDirectory[
  FileNameJoin[{
    root,
    "Codex",
    "TestResults",
    "leading-order-" <> StringReplace[CreateUUID[], "-" -> ""]
  }],
  CreateIntermediateDirectories -> True
];
baseCard = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
partons =
  {FeynArts`F[3, {1}], FeynArts`F[3, {1}]} ->
  {FeynArts`F[3, {1}], FeynArts`F[3, {1}]};
forwardAmplitudes = <|
  "LoopOrder" -> 0,
  "LoopMomenta" -> {},
  "DiagramIndices" -> {1},
  "SelectedIndex" -> 1
|>;
conjugateAmplitudes = forwardAmplitudes;
config = Join[baseCard, <|
  "CardName" -> "LeadingOrderTest",
  "ForwardAmplitudes" -> forwardAmplitudes,
  "ConjugateAmplitudes" -> conjugateAmplitudes,
  "Partons" -> partons,
  "PartonMomentum" -> {ka, kb} -> {kc, kd},
  "PhaseSpaceMomentum" -> {kd},
  "PartonIntegrated" -> {kd},
  "MomentumFraction" -> {xa, xb} -> {zh, FeynFacet`NA},
  "HadronMomentum" -> {Pa, Pb} -> {Ph, FeynFacet`NA},
  "HadronLongDirection" -> {n, nb} -> {nh, FeynFacet`NA},
  "HadronDualDirection" -> {nb, n} -> {nhb, FeynFacet`NA},
  "HadronLongSpin" -> {lambdaA, 0} -> {lambdaH, FeynFacet`NA},
  "HadronTransSpin" -> {STvec, 0} -> {SThvec, FeynFacet`NA},
  "SetDistributionZero" -> {
    FeynFacet`g1L, FeynFacet`G1L, FeynFacet`h1, FeynFacet`H1
  },
  "SetMassZero" -> {Pa, Pb, Ph, ka, kb, kc, kd}
|>];

diagramsBySide = FeynFacet`GenerateDiagram[config];
config = Join[config, <|"DiagramsBySide" -> diagramsBySide|>];
output = FeynFacet`CollinearFactorize[config];
If[output === $Failed, Exit[1]];
{
  fractionMeasure,
  preFactor,
  phaseSpace,
  integrand,
  propagators,
  loopMomentum
} = output;

fractionedPropagators = FeynFacet`PartialFraction[propagators, loopMomentum];
families = FeynFacet`BuildTopologies[
  fractionedPropagators,
  loopMomentum,
  config
];
shifted = FeynFacet`DimensionalShift[integrand, families, loopMomentum];
prescription = FeynFacet`AMFlowPrescription[config];

artifact = FeynFacet`GenerateCollinearFactorizePreIBPResult[
  config,
  fractionMeasure,
  preFactor,
  phaseSpace,
  shifted,
  families,
  resultDirectory
];
kiraFile = FileNameJoin[{resultDirectory, "KiraResult.wl"}];
kiraPath = If[
  AssociationQ[artifact],
  FeynFacet`KiraReduction[{artifact}, kiraFile],
  $Failed
];
kira = If[StringQ[kiraPath] && FileExistsQ[kiraPath], Get[kiraPath], $Failed];
reduced = If[
  AssociationQ[kira],
  FeynFacet`CoefficientSimplification[{artifact}, kira],
  $Failed
];
expectedBorn = If[
  AssociationQ[artifact],
  FeynFacet`Private`applyHadronicVariables[
    preFactor integrand /. FeynFacet`Private`$dimensionRule,
    artifact["AnalyticContext", "HadronicVariables"]
  ],
  $Failed
];

checks = <|
  "CollinearOutput" -> Length[output] === 6,
  "NoLoopMomenta" -> loopMomentum === {},
  "ExternalCutInPhaseSpace" ->
    Length[Cases[phaseSpace, _FeynFacet`Cut, {0, Infinity}]] === 1,
  "NoRemainingMeasure" -> FreeQ[phaseSpace, _FeynFacet`dD],
  "NoLoopPropagators" -> propagators === 1,
  "PartialFractionIdentity" -> fractionedPropagators === 1,
  "NoIntegralFamilies" -> families === {},
  "DimensionalShiftIdentity" -> shifted === integrand,
  "NoMasterIntegrals" -> FreeQ[shifted, _FeynCalc`GLI],
  "NoAMFlowLoops" -> prescription === <|
    "LoopMomenta" -> {},
    "Prescription" -> {}
  |>,
  "NonzeroBornIntegrand" -> ! MemberQ[{$Failed, $Aborted, 0}, integrand],
  "NonzeroBornPrefactor" -> ! MemberQ[{$Failed, $Aborted, 0}, preFactor],
  "ArtifactValid" -> AssociationQ[artifact] &&
    TrueQ[FeynFacet`Private`validPreIBPResultQ[artifact]],
  "KiraNotApplicable" -> AssociationQ[kira] &&
    kira["Topologies"] === {} && kira["Masters"] === {} &&
    MissingQ[kira["KiraProject"]],
  "ReductionIdentity" -> AssociationQ[reduced] &&
    reduced["Masters"] === {} &&
    TrueQ[
      Simplify[
        reduced["Expression"] - expectedBorn,
        Assumptions -> artifact["AnalyticContext", "Assumptions"]
      ] === 0
    ]
|>;

Print[checks];
Quiet[DeleteDirectory[resultDirectory, DeleteContents -> True]];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
