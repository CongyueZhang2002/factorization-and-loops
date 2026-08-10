$LoadFeynArts = True;
Get["/home/maxzhang/FACET/Addon/Load/LoadFACET.wl"];

i1 = FeynCalc`GLI[topologyA, {1, 0}];
i2 = FeynCalc`GLI[topologyA, {0, 1}];
m1 = FeynCalc`GLI[topologyM, {1, 0}];
m2 = FeynCalc`GLI[topologyM, {0, 1}];
expression = (a + b) i1 + 2 a i2 + c;

parts = FeynFacet`Private`linearIntegralSum[expression];
mapped = FeynFacet`Private`linearMapIntegrals[
  parts,
  {i1 -> i2, i2 -> i2}
];
reduced = FeynFacet`Private`linearApplyReduction[
  parts,
  Dispatch[{i1 -> 2 m1 + m2, i2 -> -m1}],
  {}
];
nonlinear = Catch[
  FeynFacet`Private`linearIntegralSum[i1 i2],
  _
];
Global`$FACETKernelLimit = 2;
parallel = FeynFacet`Private`parallelNormalizeCoefficients[
  {1/(1 + x) + x/(1 + x), (a^2 - b^2)/(a - b)},
  True
];

checks = <|
  "SparseInvariant" -> FeynFacet`Private`linearIntegralSumQ[parts],
  "ExactReconstruction" -> TrueQ[
    Expand[FeynFacet`Private`linearToExpression[parts] - expression] === 0
  ],
  "DuplicateKeysMerged" -> TrueQ[
    mapped["Terms"][i2] === 3 a + b
  ],
  "ReductionExact" -> TrueQ[
    Expand[
      FeynFacet`Private`linearToExpression[reduced] -
        (2 (a + b) m1 + (a + b) m2 - 2 a m1 + c)
    ] === 0
  ],
  "NonlinearRejected" -> FailureQ[nonlinear],
  "ParallelMapExact" -> SameQ[
    Together /@ (parallel[[1]] - {1, a + b}),
    {0, 0}
  ]
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
