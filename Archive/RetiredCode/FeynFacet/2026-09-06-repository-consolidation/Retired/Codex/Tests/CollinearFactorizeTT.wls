root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
SetDirectory[root];
$HistoryLength = 0;

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

setup = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "TT.wl"}]];
setup["ForwardAmplitudes", "SelectedIndex"] = 1;
setup["ConjugateAmplitudes", "SelectedIndex"] = 2;

result = FeynFacet`CollinearFactorizePreIBP[setup];
If[! MatchQ[result, {_, _, _, _, _}],
  Print[<|"ReturnedFiveObjects" -> False|>];
  Exit[1]
];

{
  fractionMeasure,
  preFactor,
  phaseSpace,
  shiftedIntegrand,
  topologies
} = result;

masters = DeleteDuplicates @ Cases[
  shiftedIntegrand,
  _FeynCalc`GLI,
  Infinity
];

checks = <|
  "ReturnedFiveObjects" -> True,
  "NonzeroMeasure" -> fractionMeasure =!= 0,
  "NonzeroPrefactor" -> ! MemberQ[{$Failed, $Aborted, 0}, preFactor],
  "PhaseSpaceReturned" -> phaseSpace =!= $Failed,
  "TransversityDistributionsRetained" -> And[
    ! FreeQ[preFactor, FeynFacet`h1[xa]],
    ! FreeQ[preFactor, FeynFacet`H1[zh]]
  ],
  "TransverseSpinVectorsRetained" -> And[
    ! FreeQ[
      preFactor shiftedIntegrand,
      STvec
    ],
    ! FreeQ[
    preFactor shiftedIntegrand,
      SThvec
    ]
  ],
  "TopologyRecordsValid" ->
    topologies =!= {} &&
      AllTrue[topologies, FeynFacet`Private`topologyRecordQ],
  "MasterIntegralsPresent" -> masters =!= {},
  "NoEvanescentProducts" -> FreeQ[shiftedIntegrand, FeynCalc`SPE]
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
