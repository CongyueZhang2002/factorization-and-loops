root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
FeynCalc`FCClearScalarProducts[];

ClearAll[raiseExpected];

raiseExpected[expression_, topology_, rank_Integer?NonNegative] := Module[
  {raiseOnce, offsets},
  raiseOnce[expr_, offset_] := Module[{glis},
    glis = DeleteDuplicates @ Cases[
      expr,
      _FeynCalc`GLI,
      {0, Infinity}
    ];
    Expand[expr /. (# -> (
      FeynCalc`FCLoopGLIRaiseDimension[
        #,
        topology,
        FeynCalc`Collecting -> False,
        FeynCalc`FCE -> True
      ] /. D -> D + offset
    ) & /@ glis)]
  ];
  If[rank === 0, Return[expression]];
  offsets = 2 Reverse[Range[0, rank - 1]];
  Fold[raiseOnce, expression, offsets]
];

topology1 = FeynCalc`FCTopology[
  shift1,
  {FeynCalc`SFAD[{k, m^2}]},
  {k},
  {},
  {},
  {}
];
propagators1 = FeynCalc`SFAD[{k, m^2}]^2;

ordinary1 = FeynFacet`DimensionalShift[
  FeynCalc`SPD[k],
  propagators1,
  {k},
  topology1
];
evanescent1 = FeynFacet`DimensionalShift[
  FeynCalc`SPE[k],
  propagators1,
  {k},
  topology1
];
evanescentPair1 = FeynFacet`DimensionalShift[
  FeynCalc`SPE[k, k],
  propagators1,
  {k},
  topology1
];
loopDependentCoefficientRejected = Quiet[
  FeynFacet`DimensionalShift[f[k], propagators1, {k}, topology1]
] === $Failed;
fourDimensional1 = FeynFacet`DimensionalShift[
  FeynCalc`SP[k],
  propagators1,
  {k},
  topology1
];
zero1 = FeynFacet`DimensionalShift[
  0,
  propagators1,
  {k},
  topology1
];

expectedOrdinary1 =
  FeynCalc`GLI[shift1, {1}] +
  m^2 FeynCalc`GLI[shift1, {2}];
expectedEvanescent1 = (D - 4)/D expectedOrdinary1;

topology2 = FeynCalc`FCTopology[
  shift2,
  {
    FeynCalc`SFAD[{k1, m1^2}],
    FeynCalc`SFAD[{k2, m2^2}],
    FeynCalc`SFAD[{k1 - k2, m3^2}]
  },
  {k1, k2},
  {},
  {},
  {}
];
propagators2 = Times @@ topology2[[2]];

mixed2 = FeynFacet`DimensionalShift[
  FeynCalc`SPE[k1, k2],
  propagators2,
  {k1, k2},
  topology2
];
expectedMixed2 = raiseExpected[
  -(D - 4)/2 FeynCalc`GLI[shift2, {1, 1, 2}],
  topology2,
  1
];

gram2 = FeynFacet`DimensionalShift[
  FeynCalc`SPE[k1] FeynCalc`SPE[k2] -
    FeynCalc`SPE[k1, k2]^2,
  propagators2,
  {k1, k2},
  topology2
];
expectedGram2 = raiseExpected[
  (D - 4) (D - 5)/4 (
    FeynCalc`GLI[shift2, {2, 2, 1}] +
    FeynCalc`GLI[shift2, {2, 1, 2}] +
    FeynCalc`GLI[shift2, {1, 2, 2}]
  ),
  topology2,
  2
];

topologyCut = FeynCalc`FCTopology[
  shiftCut,
  {
    FeynCalc`SFAD[kc],
    FeynCalc`SFAD[kc - p]
  },
  {kc},
  {p},
  {FeynCalc`SPD[p] -> s},
  {}
];
cutResult = FeynFacet`DimensionalShift[
  FeynCalc`SPE[kc],
  FeynFacet`Cut[FeynCalc`SPD[kc], -1] FeynCalc`SFAD[kc - p],
  {kc},
  topologyCut
];
cutIndices = Cases[
  cutResult,
  FeynCalc`GLI[shiftCut, indices_List] :> indices[[1]],
  {0, Infinity}
];

checks = <|
  "OneLoopOrdinary" ->
    TrueQ[Together[ordinary1 - expectedOrdinary1] === 0],
  "OneLoopEvanescent" ->
    TrueQ[Together[evanescent1 - expectedEvanescent1] === 0],
  "OneArgumentSPE" -> SameQ[evanescent1, evanescentPair1],
  "LoopDependentCoefficientRejected" -> loopDependentCoefficientRejected,
  "SPDecomposition" ->
    TrueQ[Together[fourDimensional1 - ordinary1 + evanescent1] === 0],
  "ZeroNumerator" -> TrueQ[zero1 === 0],
  "TwoLoopMixed" ->
    TrueQ[Together[mixed2 - expectedMixed2] === 0],
  "TwoLoopGram" ->
    TrueQ[Together[gram2 - expectedGram2] === 0],
  "CutResultNonzero" -> ! MemberQ[{$Failed, $Aborted, 0}, cutResult],
  "CutPreserved" -> cutIndices =!= {} && AllTrue[cutIndices, # > 0 &],
  "NoEvanescentProducts" ->
    FreeQ[{ordinary1, evanescent1, mixed2, gram2, cutResult}, FeynCalc`SPE]
|>;

Print[checks];

If[! And @@ Values[checks], Exit[1]];
Exit[0];
