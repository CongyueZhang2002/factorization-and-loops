facetRoot = "/home/maxzhang/FACET";
workDirectory = FileNameJoin[{
  facetRoot, "Codex", "ppHX_NLO", "HadronicSimplification", "UU_10x10"
}];
Get[FileNameJoin[{facetRoot, "Addon", "Load", "LoadFACET.wl"}]];
Global`$FACETKernelLimit = 4;
inspection = Get[FileNameJoin[{
  facetRoot, "Codex", "ppHX_NLO", "HadronicSimplification",
  "TargetAlgebraInspection.wl"
}]];
card = Get[FileNameJoin[{facetRoot, "ppHX_NLO", "Cards", "UU.wl"}]];
hadronic = FeynFacet`Private`cardHadronicVariables[card];
assumptions = FeynFacet`Private`cardAssumptions[card, hadronic];
kira = Get[FileNameJoin[{
  facetRoot, "ppHX_NLO", "Results", "UU_08_05_10x10_1", "KiraResult.wl"
}]];

inputs = FeynFacet`Private`applyHadronicVariables[
  inspection["LargestExpressions"] /. kira["DimensionRule"],
  hadronic
];

smallClean[expression_] := Factor[Cancel[Together[expression]]];

functionalBasis[expression_] := DeleteDuplicates @ Cases[
  expression,
  _FeynFacet`D1 | _FeynFacet`f1,
  Infinity
];

termwiseSimplify[expression_] := Total[
  Simplify[#1, Assumptions -> assumptions] & /@
    FeynFacet`Private`additiveTerms[expression]
];

wholeSimplify[expression_] := Simplify[
  expression,
  Assumptions -> assumptions
];

wholeFullSimplify[expression_] := FullSimplify[
  expression,
  Assumptions -> assumptions
];

originalCollectSimplify[expression_] := Simplify[
  Collect[
    expression,
    functionalBasis[expression],
    smallClean
  ],
  Assumptions -> assumptions
];

runStrategy[name_String, function_] := Module[
  {elapsed, outputs, timedOut, exactDifferences},
  DistributeDefinitions[function, assumptions];
  {elapsed, outputs} = AbsoluteTiming[
    ParallelMap[
      TimeConstrained[
        function[#1],
        180,
        Missing["TimeLimit"]
      ] &,
      inputs,
      Method -> "FinestGrained"
    ]
  ];
  timedOut = Count[outputs, _Missing];
  exactDifferences = MapThread[
    If[
      MissingQ[#1],
      Missing["NotChecked"],
      Simplify[#1 - #2, Assumptions -> assumptions]
    ] &,
    {outputs, inputs}
  ];
  <|
    "Strategy" -> name,
    "Seconds" -> elapsed,
    "InputBytes" -> ByteCount[inputs],
    "OutputBytes" -> Total[ByteCount /@ DeleteMissing[outputs]],
    "TimedOut" -> timedOut,
    "ExactDifferencesZero" -> AllTrue[
      DeleteMissing[exactDifferences],
      TrueQ[#1 === 0] &
    ],
    "Output" -> outputs
  |>
];

LaunchKernels[Min[4, Global`$FACETKernelLimit]];
DistributeDefinitions[
  smallClean,
  functionalBasis,
  termwiseSimplify,
  wholeSimplify,
  wholeFullSimplify,
  originalCollectSimplify,
  assumptions
];

results = {
  runStrategy["TermwiseSimplify", termwiseSimplify],
  runStrategy["WholeSimplify", wholeSimplify],
  runStrategy["WholeFullSimplify", wholeFullSimplify],
  runStrategy["OriginalCollectSimplify", originalCollectSimplify]
};

Put[results, FileNameJoin[{workDirectory, "AlgebraStrategyBenchmark.wl"}]];
Print[InputForm[KeyDrop[#, "Output"] & /@ results]];
CloseKernels[];
