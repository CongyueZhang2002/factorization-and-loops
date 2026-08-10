root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
FeynCalc`FCClearScalarProducts[];

ppPropagators =
  FeynFacet`Cut[FeynCalc`SPD[ke], 1] *
  FeynFacet`Cut[FeynCalc`SPD[ka + kb - kc - ke], 1] *
  FeynCalc`FAD[ka - kc]^2 *
  FeynCalc`FAD[ke - kb] *
  FeynCalc`FAD[-ka + kc + ke];
ppFractions = Expand @ FeynFacet`PartialFraction[ppPropagators, {ke}];
ppFamilies = FeynFacet`BuildTopologies[
  ppFractions,
  {ke},
  Association[
    "ForwardAmplitudes" -> Association[
      "LoopMomenta" -> {}, "SelectedIndex" -> 4
    ],
    "ConjugateAmplitudes" -> Association[
      "LoopMomenta" -> {}, "SelectedIndex" -> 7
    ],
    "PartonMomentum" -> ({ka, kb} -> {kc, kd, ke}),
    "SetMassZero" -> {ka, kb, kc, kd, ke}
  ]
];
ppTopologies = Lookup[ppFamilies, "Topology"];
ppShift = Total[
  FeynFacet`DimensionalShift[
    FeynCalc`SPE[ke],
    #["Propagators"],
    {ke},
    #["Topology"]
  ] & /@ ppFamilies
];

twoLoopPropagators =
  FeynFacet`Cut[FeynCalc`SPD[k1], 1] *
  FeynFacet`Cut[
    FeynCalc`SPD[p1 + p2 - p3 - k1 - k2],
    -1
  ] *
  FeynCalc`FAD[k2 - p1] *
  FeynCalc`FAD[k1 - k2];
twoLoopFamilies = FeynFacet`BuildTopologies[
  twoLoopPropagators,
  {k1, k2},
  Association[
    "ForwardAmplitudes" -> Association[
      "LoopMomenta" -> {}, "SelectedIndex" -> 2
    ],
    "ConjugateAmplitudes" -> Association[
      "LoopMomenta" -> {}, "SelectedIndex" -> 5
    ],
    "PartonMomentum" -> ({p1, p2} -> {p3, k1, k2, k3}),
    "SetMassZero" -> {p1, p2, p3, k1, k2, k3}
  ]
];
twoLoopTopology = twoLoopFamilies[[1, "Topology"]];
twoLoopShift = FeynFacet`DimensionalShift[
  1,
  twoLoopFamilies[[1, "Propagators"]],
  {k1, k2},
  twoLoopTopology
];

topologyQ[topology_] := And[
  TrueQ[FeynCalc`FCLoopValidTopologyQ[topology]],
  TrueQ[! FeynCalc`FCLoopBasisIncompleteQ[topology]],
  TrueQ[! FeynCalc`FCLoopBasisOverdeterminedQ[topology]]
];

checks = Association[
  "OneLoopFamilyCount" -> Length[ppFamilies] === 2,
  "OneLoopNames" ->
    ppTopologies[[All, 1]] === {TopologyF4C7N1, TopologyF4C7N2},
  "OneLoopTopologies" -> AllTrue[ppTopologies, topologyQ],
  "ExternalMomentaInferred" ->
    AllTrue[ppTopologies[[All, 4]], Sort[#] === Sort[{ka, kb, kc}] &],
  "MassRulesInferred" -> AllTrue[
    ppTopologies[[All, 5]],
    Function[rules,
      And @@ (
        TrueQ[(# /. rules) === 0] & /@
          FeynCalc`FCI[{
            FeynCalc`SPD[ka],
            FeynCalc`SPD[kb],
            FeynCalc`SPD[kc]
          }]
      )
    ]
  ],
  "CutsMapped" -> Lookup[ppFamilies, "CutIndices"] === {{3, 1}, {3, 1}},
  "OneLoopCutDirections" ->
    Lookup[ppFamilies, "CutDirections"] === {{1, 1}, {1, 1}},
  "OneLoopShift" ->
    ppShift =!= $Failed && ppShift =!= 0 && FreeQ[ppShift, FeynCalc`SPE],
  "TwoLoopTopology" -> topologyQ[twoLoopTopology],
  "TwoLoopName" -> twoLoopTopology[[1]] === TopologyF2C5N1,
  "TwoLoopCutsMapped" ->
    Length[twoLoopFamilies[[1, "CutIndices"]]] === 2,
  "TwoLoopCutDirections" ->
    twoLoopFamilies[[1, "CutDirections"]] === {1, -1},
  "TwoLoopShift" ->
    twoLoopShift =!= $Failed && twoLoopShift =!= 0 &&
      FreeQ[twoLoopShift, FeynCalc`SPE]
];

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
