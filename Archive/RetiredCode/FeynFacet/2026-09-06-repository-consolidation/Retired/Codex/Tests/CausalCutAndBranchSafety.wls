root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
FeynCalc`FCClearScalarProducts[];

dotted = FeynFacet`Private`restoreCutTerm[
  FeynCalc`SFAD[{{k, 0}, {0, 1}, 2}],
  {{k, 1}}
];

card = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
setup = card;
setup["ForwardAmplitudes", "SelectedIndex"] = 1;
setup["ConjugateAmplitudes", "SelectedIndex"] = 1;
result = FeynFacet`CollinearFactorizePreIBP[setup];
topologies = If[MatchQ[result, {_, _, _, _, _}], result[[5]], $Failed];
topologyAMFlowData = If[
  MatchQ[topologies, {_Association ..}],
  FeynFacet`AMFlowPrescription[setup, First[topologies]],
  $Failed
];

treeReal = FeynFacet`AMFlowPrescription[setup];
realVirtual = setup;
realVirtual["ForwardAmplitudes", "LoopOrder"] = 1;
realVirtual["ForwardAmplitudes", "LoopMomenta"] = {lF};
realVirtual["ConjugateAmplitudes", "LoopOrder"] = 0;
realVirtual["ConjugateAmplitudes", "LoopMomenta"] = {};
realVirtualData = FeynFacet`AMFlowPrescription[realVirtual];

loopSquared = realVirtual;
loopSquared["ConjugateAmplitudes", "LoopOrder"] = 1;
loopSquared["ConjugateAmplitudes", "LoopMomenta"] = {lC};
loopSquaredData = FeynFacet`AMFlowPrescription[loopSquared];

invalid = loopSquared;
invalid["ConjugateAmplitudes", "LoopMomenta"] = {lF};
invalidData = Quiet[FeynFacet`AMFlowPrescription[invalid]];

integerProjection = FeynFacet`Private`dimensionalShiftPreserveCuts[
  FeynCalc`GLI[testFamily, {1, 2}],
  {1}
];
pinchedProjection = FeynFacet`Private`dimensionalShiftPreserveCuts[
  FeynCalc`GLI[testFamily, {0, 2}],
  {1}
];
symbolicProjection = FeynFacet`Private`dimensionalShiftPreserveCuts[
  FeynCalc`GLI[testFamily, {a, 2}],
  {1}
];

cutCollision = FeynFacet`PartialFraction[
  FeynFacet`Cut[FeynCalc`SPD[k], 1] FeynCalc`SFAD[k],
  {k}
];

branchExpression = (1 + x)/(1 - x) Log[-x] +
  (1 + x)/(1 - x) Hypergeometric2F1[a, b, c, x];
branchNormalized = FeynFacet`Private`exactCoefficientNormalize[
  branchExpression
];

checks = <|
  "DottedCutPowerPreserved" -> MatchQ[
    dotted,
    FeynFacet`Cut[FeynCalc`SPD[k], 1]^2
  ],
  "TreeRealLoopPrescription" -> treeReal === <|
    "LoopMomenta" -> {ke},
    "Prescription" -> {0}
  |>,
  "RealVirtualLoopPrescription" -> realVirtualData === <|
    "LoopMomenta" -> {ke, lF},
    "Prescription" -> {0, 1}
  |>,
  "LoopSquaredPrescription" -> loopSquaredData === <|
    "LoopMomenta" -> {ke, lF, lC},
    "Prescription" -> {0, 1, -1}
  |>,
  "TopologyCausalityDerivedOnDemand" -> And[
    AssociationQ[topologyAMFlowData],
    topologyAMFlowData["LoopMomenta"] === {ke},
    topologyAMFlowData["Prescription"] === {0},
    Count[topologyAMFlowData["Cut"], 1] === 2,
    Sort[Keys[topologyAMFlowData]] === Sort[{
      "LoopMomenta", "Prescription", "Cut"
    }]
  ],
  "SharedVirtualLoopRejected" -> invalidData === $Failed,
  "NoDenominatorSignMetadata" -> If[
    ListQ[topologies],
    FreeQ[
      topologies,
      "EtaSign" | "PhysicalEtaSign" | "PropagatorSources" |
        "ExternalPropagatorData" | "AMFlowInfo" | "UncutProduct" |
        "PropagatorPrescription" | "PropagatorClass"
    ],
    False
  ],
  "IntegerCutRetained" ->
    integerProjection === FeynCalc`GLI[testFamily, {1, 2}],
  "PinchedCutRemoved" -> pinchedProjection === 0,
  "SymbolicCutRejected" -> symbolicProjection === $Failed,
  "CutOrdinaryCollisionRejected" -> cutCollision === $Failed,
  "BranchObjectsPreserved" -> And[
    ! FreeQ[branchNormalized, Log[-x]],
    ! FreeQ[branchNormalized, Hypergeometric2F1[a, b, c, x]],
    Together[branchNormalized - branchExpression] === 0
  ]
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
