facetRoot = "/home/maxzhang/FACET";
workDirectory = FileNameJoin[{
  facetRoot, "Codex", "ppHX_NLO", "HadronicSimplification", "UU_10x10"
}];

Get[FileNameJoin[{facetRoot, "Addon", "Load", "LoadFACET.wl"}]];
Global`$FACETKernelLimit = 4;
card = Get[FileNameJoin[{facetRoot, "ppHX_NLO", "Cards", "UU.wl"}]];
hadronic = FeynFacet`Private`cardHadronicVariables[card];
assumptions = FeynFacet`Private`cardAssumptions[card, hadronic];
hybrid = Get[FileNameJoin[{workDirectory, "HybridMasterCoefficients.wl"}]];
radicalTest = Get[FileNameJoin[{
  workDirectory, "RadicalNormalizationTest.wl"
}]];

physicalFactor =
  FeynFacet`\[Alpha]s^3*FeynFacet`D1[zh]*FeynFacet`f1[xa]*
    FeynFacet`f1[xb]/(xa*xb*zh^2);

canonicalInput[expression_] :=
  expression /. Dispatch[radicalTest["Rules"]];

divideOnly[expression_] := Total[
  (#/physicalFactor) & /@
    FeynFacet`Private`additiveTerms[canonicalInput[expression]]
];

divideSimplify[expression_] := Total[
  Simplify[#/physicalFactor, Assumptions -> assumptions] & /@
    FeynFacet`Private`additiveTerms[canonicalInput[expression]]
];

divideFactorTerms[expression_] := Total[
  FactorTerms[#/physicalFactor, {s, t, u, Global`Epsilon, CA, CF}] & /@
    FeynFacet`Private`additiveTerms[canonicalInput[expression]]
];

runVariant[name_String, function_] := Module[{seconds, expressions},
  {seconds, expressions} = AbsoluteTiming[
    ParallelMap[function, Values[hybrid["Terms"]], Method -> "FinestGrained"]
  ];
  <|
    "Route" -> name,
    "Seconds" -> seconds,
    "Bytes" -> ByteCount[expressions],
    "Compression" -> N[ByteCount[Values[hybrid["Terms"]]]/ByteCount[expressions]],
    "Terms" -> Total[Length[FeynFacet`Private`additiveTerms[#]] & /@ expressions],
    "FractionFree" -> FreeQ[expressions, Alternatives[xa, xb, zh]],
    "Expressions" -> expressions
  |>
];

LaunchKernels[4];
DistributeDefinitions[
  canonicalInput, divideOnly, divideSimplify, divideFactorTerms,
  physicalFactor, radicalTest, assumptions
];
results = {
  runVariant["DivideOnly", divideOnly],
  runVariant["DivideSimplify", divideSimplify],
  runVariant["DivideFactorTerms", divideFactorTerms]
};
CloseKernels[];

Put[results, FileNameJoin[{workDirectory, "CompactStripVariants.wl"}]];
Clear[$PrePrint];
Print[InputForm[KeyDrop[#, "Expressions"] & /@ results]];
