facetRoot = "/home/maxzhang/FACET";
workDirectory = FileNameJoin[{
  facetRoot, "Codex", "ppHX_NLO", "HadronicSimplification", "UU_10x10"
}];

Get[FileNameJoin[{facetRoot, "Addon", "Load", "LoadFACET.wl"}]];
Global`$FACETKernelLimit = 4;
card = Get[FileNameJoin[{facetRoot, "ppHX_NLO", "Cards", "UU.wl"}]];
hadronic = FeynFacet`Private`cardHadronicVariables[card];
assumptions = FeynFacet`Private`cardAssumptions[card, hadronic];
variants = Get[FileNameJoin[{workDirectory, "CompactStripVariants.wl"}]];
input = SelectFirst[variants, #1["Route"] === "DivideSimplify" &]["Expressions"];

factorCleanup[expression_] := Factor[expression];
fullCleanup[expression_] := TimeConstrained[
  FullSimplify[expression, Assumptions -> assumptions],
  120,
  Missing["TimeLimit"]
];
collectCleanup[expression_] := TimeConstrained[
  Collect[
    expression,
    {CA, CF},
    Factor[Cancel[Together[#]]] &
  ],
  120,
  Missing["TimeLimit"]
];

runVariant[name_String, function_] := Module[{seconds, expressions},
  {seconds, expressions} = AbsoluteTiming[
    ParallelMap[function, input, Method -> "FinestGrained"]
  ];
  <|
    "Route" -> name,
    "Seconds" -> seconds,
    "Bytes" -> Total[ByteCount /@ DeleteMissing[expressions]],
    "TimedOut" -> Count[expressions, _Missing],
    "Expressions" -> expressions
  |>
];

LaunchKernels[4];
DistributeDefinitions[
  factorCleanup, fullCleanup, collectCleanup, assumptions
];
results = {
  runVariant["Factor", factorCleanup],
  runVariant["FullSimplify", fullCleanup],
  runVariant["CollectColor", collectCleanup]
};
CloseKernels[];

Put[results, FileNameJoin[{workDirectory, "FinalCleanupVariants.wl"}]];
Clear[$PrePrint];
Print[InputForm[KeyDrop[#, "Expressions"] & /@ results]];
