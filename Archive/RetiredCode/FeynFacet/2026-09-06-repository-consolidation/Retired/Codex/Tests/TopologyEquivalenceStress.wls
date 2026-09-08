root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
FeynCalc`FCClearScalarProducts[];
SeedRandom[20260805];

kinematics = {FeynCalc`SPD[p] -> s};
makeTopology[name_, loops_, propagators_] := FeynCalc`FCTopology[
  name,
  FeynCalc`SFAD /@ propagators,
  loops,
  {p},
  kinematics,
  {}
];

contextBase = <|
  "Gamma5Scheme" -> "BMHV",
  "GlobalBasis" -> {},
  "GlobalBasisGram" -> {},
  "SetEvanescentZero" -> {},
  "SetMassZero" -> {},
  "SetDistributionZero" -> {},
  "CollinearRelations" -> {},
  "Assumptions" -> True,
  "CoefficientKinematics" -> <||>,
  "KinematicMassDimensions" -> <||>,
  "LoopDimension" -> D,
  "DimensionRule" -> FeynFacet`Private`$dimensionRule,
  "CutConvention" -> "OrientedPositiveEnergyDelta",
  "DistributionConvention" -> "FeynFacet/Distributions.wl",
  "FeynFacetSourceHash" -> FeynFacet`Private`$feynFacetSourceHash
|>;
testContext = Append[
  contextBase,
  "Fingerprint" -> FeynFacet`Private`reductionFingerprint[contextBase]
];

record[
    topology_, cutMomenta_, cutIndices_, cutDirections_, indices_
  ] := <|
  "Type" -> "FeynFacetTopologyRecord",
  "Version" -> 3,
  "DiagramPair" -> <|"Forward" -> 1, "Conjugate" -> 1|>,
  "Propagators" -> 1,
  "Topology" -> topology,
  "BaseGLI" -> FeynCalc`GLI[topology[[1]], indices],
  "FamilyCoefficient" -> 1,
  "CutMomenta" -> cutMomenta,
  "CutIndices" -> cutIndices,
  "CutDirections" -> cutDirections,
  "AnalyticContext" -> testContext
|>;

renameRecord[input_, name_] := Module[{copy = input},
  copy["Topology"] = ReplacePart[copy["Topology"], 1 -> name];
  copy["BaseGLI"] = ReplacePart[copy["BaseGLI"], 1 -> name];
  copy
];

permuteRecord[input_, name_, permutation_] := Module[
  {copy = renameRecord[input, name], inverse},
  inverse = Ordering[permutation];
  copy["Topology"] = ReplacePart[
    copy["Topology"],
    2 -> copy["Topology"][[2, permutation]]
  ];
  copy["BaseGLI"] = FeynCalc`GLI[
    name,
    copy["BaseGLI"][[2, permutation]]
  ];
  copy["CutIndices"] = inverse[[copy["CutIndices"]]];
  copy
];

phaseSetup = <|
  "PhaseSpaceMomentum" -> {q1, q2},
  "PartonIntegrated" -> {},
  "ForwardAmplitudes" -> <|"LoopMomenta" -> {}|>,
  "ConjugateAmplitudes" -> <|"LoopMomenta" -> {}|>
|>;
phaseTopology = makeTopology[
  phaseBase,
  {q1, q2},
  {q1, q2, q1 - q2, q1 - p, q1 + q2 - p}
];
phaseRecord = record[
  phaseTopology,
  {q1, q2},
  {1, 2},
  {1, 1},
  {1, 1, 1, 1, 1}
];
phasePermutations = Table[
  permuteRecord[
    phaseRecord,
    Symbol["phasePermutation" <> ToString[i]],
    RandomSample[Range[5]]
  ],
  {i, 12}
];
phaseResult = FeynFacet`TopologyEquivalence[
  RandomSample[Prepend[phasePermutations, phaseRecord]],
  phaseSetup
];

badCut = renameRecord[phaseRecord, badCutDirection];
badCut["CutDirections"] = {-1, 1};
badCutResult = FeynFacet`TopologyEquivalence[
  {phaseRecord, badCut},
  phaseSetup
];

virtualSetup = <|
  "PhaseSpaceMomentum" -> {},
  "PartonIntegrated" -> {},
  "ForwardAmplitudes" -> <|"LoopMomenta" -> {lF}|>,
  "ConjugateAmplitudes" -> <|"LoopMomenta" -> {lC}|>
|>;
virtualTopology = makeTopology[
  virtualBase,
  {lF, lC},
  {lF, lC, lF - lC, lF - p, lF + lC - p}
];
virtualSafe = record[
  virtualTopology,
  {},
  {},
  {},
  {1, 1, 0, 1, 0}
];
virtualMixed = record[
  ReplacePart[virtualTopology, 1 -> virtualMixedActive],
  {},
  {},
  {},
  {1, 1, 1, 1, 0}
];

virtualData = FeynFacet`AMFlowPrescription[virtualSetup, virtualSafe];
mixedData = Quiet @ FeynFacet`AMFlowPrescription[
  virtualSetup,
  virtualMixed
];

checks = <|
  "RandomPermutationCoverage" -> And[
    AssociationQ[phaseResult],
    Total[Length /@ Lookup[phaseResult["Classes"], "Members"]] === 13,
    Sort[Flatten @ Lookup[phaseResult["Classes"], "Members"]] ===
      Sort[Lookup[Prepend[phasePermutations, phaseRecord], "Topology"][[All, 1]]]
  ],
  "CutOrientationCannotBePermutedAway" -> And[
    AssociationQ[badCutResult],
    Length[badCutResult["Classes"]] === 2
  ],
  "LoopPrescriptionsDerivedFromSetup" -> And[
    AssociationQ[virtualData],
    virtualData["LoopMomenta"] === {lF, lC},
    virtualData["Prescription"] === {1, -1},
    virtualData["Cut"] === ConstantArray[0, 5],
    Sort[Keys[virtualData]] === Sort[{
      "LoopMomenta", "Prescription", "Cut"
    }]
  ],
  "ActiveMixedCausalDenominatorRejected" -> mixedData === $Failed,
  "NoStoredSignMetadata" -> FreeQ[
    {phaseRecord, virtualSafe},
    "EtaSign" | "PhysicalEtaSign" | "PropagatorSources" |
      "ExternalPropagatorData" | "AMFlowInfo" |
      "PropagatorPrescription" | "PropagatorClass"
  ]
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
