$HistoryLength = 0;

root = "/home/maxzhang/FACET";
outputDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NLO", "HadronicSimplification", "TT_Debug"
}];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
FeynCalc`FCClearScalarProducts[];

FeynCalc`SPD[p1] = 1;
FeynCalc`SPD[p2] = -1;
FeynCalc`SPD[p3] = -2;
FeynCalc`SPD[p1, p2] = 0;
FeynCalc`SPD[p1, p3] = 0;
FeynCalc`SPD[p2, p3] = 0;
FeynCalc`SPD[Y] = -1;
FeynCalc`SPD[Y, p1] = 0;
FeynCalc`SPD[Y, p2] = 0;
FeynCalc`SPD[Y, p3] = 0;

topology = FeynCalc`FCTopology[
  toyTensor,
  {
    FeynCalc`SFAD[k],
    FeynCalc`SFAD[k - p1],
    FeynCalc`SFAD[k - p2],
    FeynCalc`SFAD[k - p3]
  },
  {k},
  {p1, p2, p3},
  {},
  {}
];
integral = FeynCalc`GLI[toyTensor, {1, 1, 1, 1}];
tensorHead = FeynCalc`FCGV["TensorIdentityProduct"];

reduce[numerator_] := (
  FeynCalc`FCE @ FeynCalc`FCLoopTensorReduce[
    FeynCalc`FCI[tensorHead[numerator, integral]],
    {topology},
    Head -> tensorHead,
    FeynCalc`Uncontract -> {Y},
    FeynCalc`Dimension -> System`D,
    FeynCalc`Collecting -> False,
    FeynCalc`Contract -> True,
    FeynCalc`DiracSimplify -> False,
    FeynCalc`Factoring -> False,
    FeynCalc`FCI -> True,
    FeynCalc`FCE -> False,
    FeynCalc`FCVerbose -> False
  ]
) /. System`D -> NTensor;

rankOne = reduce[FeynCalc`SPD[k, Y]];
rankTwo = reduce[FeynCalc`SPD[k, Y]^2];
rankTwoWithOriginalD = (System`D - 4) reduce[FeynCalc`SPD[k, Y]^2];

rankOneNumerator = rankOne /. tensorHead[value_, _] :> value;
rankTwoNumerator = rankTwo /. tensorHead[value_, _] :> value;
rankTwoOriginalDNumerator =
  rankTwoWithOriginalD /. tensorHead[value_, _] :> value;
kPerpendicularSquared =
  FeynCalc`SPD[k] - FeynCalc`SPD[k, p1]^2 +
    FeynCalc`SPD[k, p2]^2 + FeynCalc`SPD[k, p3]^2/2;
expectedRankTwo = -kPerpendicularSquared/(NTensor - 3);

rankOneExact = TrueQ[
  FeynFacet`SimplifyAssum[rankOneNumerator] === 0
];
rankTwoExact = TrueQ[
  FeynFacet`SimplifyAssum[
    rankTwoNumerator - expectedRankTwo
  ] === 0
];
originalDExact = TrueQ[
  FeynFacet`SimplifyAssum[
    rankTwoOriginalDNumerator - (System`D - 4) expectedRankTwo
  ] === 0
];
r0Exact = TrueQ[
  FeynFacet`SimplifyAssum[
    (expectedRankTwo /. NTensor -> System`D) +
      kPerpendicularSquared/(System`D - 3)
  ] === 0
];
r1Exact = TrueQ[
  FeynFacet`SimplifyAssum[
    (expectedRankTwo /. NTensor -> System`D + 2) +
      kPerpendicularSquared/(System`D - 1)
  ] === 0
];
wrongR1Rejected = ! TrueQ[
  FeynFacet`SimplifyAssum[
    (expectedRankTwo /. NTensor -> System`D + 2) +
      kPerpendicularSquared/(System`D - 3)
  ] === 0
];

cutExpression =
  3 FeynCalc`GLI[toyCut, {1, 2, 1}] +
  5 FeynCalc`GLI[toyCut, {0, 2, 1}] +
  7 FeynCalc`GLI[toyCut, {1, -1, 1}];
cutProjected = FeynFacet`Private`dimensionalShiftPreserveCuts[
  cutExpression,
  {1, 2}
];
cutProjectionExact = TrueQ[
  cutProjected === 3 FeynCalc`GLI[toyCut, {1, 2, 1}]
];

summary = <|
  "RankOneExact" -> rankOneExact,
  "RankTwoExact" -> rankTwoExact,
  "OriginalDimensionFactorPreserved" -> originalDExact,
  "R0DenominatorDMinus3" -> r0Exact,
  "R1DenominatorDMinus1" -> r1Exact,
  "WrongR1DenominatorRejected" -> wrongR1Rejected,
  "CutProjectionExact" -> cutProjectionExact
|>;
Put[summary, FileNameJoin[{outputDirectory, "TensorIdentitySummary.wl"}]];
Clear[$PrePrint];
Print[InputForm[summary]];
If[! rankTwoExact,
  Print[InputForm @ <|
    "RankTwoNumerator" -> rankTwoNumerator,
    "ExpectedRankTwo" -> expectedRankTwo,
    "Difference" -> FeynFacet`SimplifyAssum[
      rankTwoNumerator - expectedRankTwo
    ]
  |>]
];
If[! And @@ Values[summary], Exit[1]];
Quit[];
