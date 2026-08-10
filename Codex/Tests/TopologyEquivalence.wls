root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
FeynCalc`FCClearScalarProducts[];

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
    topology_, cutMomenta_, cutIndices_, cutDirections_,
    indices_: Automatic
  ] := <|
  "Type" -> "FeynFacetTopologyRecord",
  "Version" -> 3,
  "DiagramPair" -> <|"Forward" -> 1, "Conjugate" -> 1|>,
  "Propagators" -> 1,
  "Topology" -> topology,
  "BaseGLI" -> FeynCalc`GLI[
    topology[[1]],
    Replace[
      indices,
      Automatic :> ConstantArray[1, Length[topology[[2]]]]
    ]
  ],
  "FamilyCoefficient" -> 1,
  "CutMomenta" -> cutMomenta,
  "CutIndices" -> cutIndices,
  "CutDirections" -> cutDirections,
  "AnalyticContext" -> testContext
|>;

phaseTopologyA = makeTopology[
  phaseA,
  {q1, q2},
  {q1, q2, q1 - q2, q1 - p, q1 + q2 - p}
];
phaseTopologyB = makeTopology[
  phaseB,
  {q1, q2},
  {q2, q1, q2 - q1, q2 - p, q1 + q2 - p}
];
phaseTopologyCutBad = ReplacePart[phaseTopologyB, 1 -> phaseCutBad];
phaseSetup = <|
  "PhaseSpaceMomentum" -> {q1, q2},
  "PartonIntegrated" -> {},
  "ForwardAmplitudes" -> <|"LoopMomenta" -> {}|>,
  "ConjugateAmplitudes" -> <|"LoopMomenta" -> {}|>
|>;
phaseRecords = {
  record[phaseTopologyA, {q1, q2}, {1, 2}, {1, -1}],
  record[phaseTopologyB, {q2, q1}, {1, 2}, {1, -1}],
  record[phaseTopologyCutBad, {q2, q1}, {1, 2}, {-1, -1}]
};
phaseResult = FeynFacet`TopologyEquivalence[phaseRecords, phaseSetup];

virtualTopologyA = makeTopology[
  virtualA,
  {lF, lC},
  {lF, lC, lF - lC, lF - p, lF + lC - p}
];
virtualTopologySwapped = makeTopology[
  virtualSwapped,
  {lF, lC},
  {lC, lF, lC - lF, lC - p, lF + lC - p}
];
virtualSetup = <|
  "PhaseSpaceMomentum" -> {},
  "PartonIntegrated" -> {},
  "ForwardAmplitudes" -> <|"LoopMomenta" -> {lF}|>,
  "ConjugateAmplitudes" -> <|"LoopMomenta" -> {lC}|>
|>;
virtualRecords = {
  record[virtualTopologyA, {}, {}, {}, {1, 1, 0, 1, 0}],
  record[virtualTopologySwapped, {}, {}, {}, {1, 1, 0, 1, 0}]
};
virtualResult = FeynFacet`TopologyEquivalence[
  virtualRecords,
  virtualSetup
];

phaseAccepted = FirstCase[
  phaseResult["Classes"],
  class_ /; MemberQ[class["Members"], phaseA]
];
cutRejected = FirstCase[
  phaseResult["Classes"],
  class_ /; MemberQ[class["Members"], phaseCutBad]
];

checks = <|
  "PhaseLoopSwapAccepted" ->
    Sort[phaseAccepted["Members"]] === Sort[{phaseA, phaseB}],
  "CutDirectionMismatchRejected" ->
    cutRejected["Members"] === {phaseCutBad},
  "VirtualSideSwapRejected" ->
    Length[virtualResult["Classes"]] === 2,
  "LoopSideReasonRecorded" -> MemberQ[
    Lookup[virtualResult["RejectedCandidateMappings"], "Reason"],
    "loop sectors are mixed"
  ],
  "NoStoredPrescriptionMetadata" -> FreeQ[
    Join[phaseRecords, virtualRecords],
    "EtaSign" | "PhysicalEtaSign" | "AMFlowInfo" |
      "PropagatorPrescription" | "PropagatorClass"
  ]
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
