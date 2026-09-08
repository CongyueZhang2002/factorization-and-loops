root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
SetDirectory[root];
$HistoryLength = 0;

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

Card = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
AllDiagrams = GenerateDiagram[Card];

ForwardChoice = 1;
ConjugateChoice = 2;
Setup = Card;
Setup["ForwardAmplitudes", "SelectedIndex"] = ForwardChoice;
Setup["ConjugateAmplitudes", "SelectedIndex"] = ConjugateChoice;

result = CollinearFactorizePreIBP[Setup];

If[! MatchQ[result, {_, _, _, _, _}],
  Print[<|"Returned" -> False|>];
  Exit[1]
];

{
  fractionMeasure,
  preFactor,
  phaseSpace,
  shiftedIntegrand,
  topologies
} = result;

prescription = AMFlowPrescription[Setup];

metadataQ[family_] := Module[{topology},
  topology = family["Topology"];
  And[
    family["DiagramPair"] === <|
      "Forward" -> Setup["ForwardAmplitudes"]["SelectedIndex"],
      "Conjugate" -> Setup["ConjugateAmplitudes"]["SelectedIndex"]
    |>,
    family["Version"] === 3,
    topology[[3]] === prescription["LoopMomenta"] === {ke},
    prescription["Prescription"] === {0},
    Length[family["CutIndices"]] === Length[family["CutDirections"]],
    AllTrue[family["CutIndices"], 1 <= # <= Length[topology[[2]]] &],
    FreeQ[
      family,
      "EtaSign" | "PhysicalEtaSign" | "AMFlowInfo" |
        "PropagatorPrescription" | "PropagatorClass"
    ]
  ]
];

masters = DeleteDuplicates @ Cases[
  shiftedIntegrand,
  _FeynCalc`GLI,
  Infinity
];

checks = <|
  "Returned" -> True,
  "CardHasNoPairSelection" -> And[
    ! KeyExistsQ[Card["ForwardAmplitudes"], "SelectedIndex"],
    ! KeyExistsQ[Card["ConjugateAmplitudes"], "SelectedIndex"]
  ],
  "CardGeneratesAllDiagrams" -> And[
    AssociationQ[AllDiagrams],
    Length[AllDiagrams["Amplitude"]] === 10,
    Length[AllDiagrams["Conjugate"]] === 10
  ],
  "NonzeroMeasure" -> fractionMeasure =!= 0,
  "NonzeroPrefactor" -> ! MemberQ[{$Failed, $Aborted, 0}, preFactor],
  "PhaseSpaceReturned" -> phaseSpace =!= $Failed,
  "InternalFractionAssumptions" ->
    SimplifyAssum[Abs[xa] + Abs[xb] + Abs[zh], Setup] === xa + xb + zh,
  "TopologyCount" -> Length[topologies] === 2,
  "LoopSideAndCutMetadata" -> AllTrue[topologies, metadataQ],
  "GLITermCount" -> Length[masters] === 16,
  "NoEvanescentProducts" -> FreeQ[shiftedIntegrand, FeynCalc`SPE]
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
