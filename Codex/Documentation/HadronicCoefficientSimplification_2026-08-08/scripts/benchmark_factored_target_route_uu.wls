facetRoot = "/home/maxzhang/FACET";
workDirectory = FileNameJoin[{
  facetRoot, "Codex", "ppHX_NLO", "HadronicSimplification", "UU_10x10"
}];
resultDirectory = FileNameJoin[{
  facetRoot, "ppHX_NLO", "Results", "UU_08_05_10x10_1"
}];

Get[FileNameJoin[{facetRoot, "Addon", "Load", "LoadFACET.wl"}]];
Global`$FACETKernelLimit = 4;
card = Get[FileNameJoin[{facetRoot, "ppHX_NLO", "Cards", "UU.wl"}]];
hadronic = FeynFacet`Private`cardHadronicVariables[card];
assumptions = FeynFacet`Private`cardAssumptions[card, hadronic];
kira = Get[FileNameJoin[{resultDirectory, "KiraResult.wl"}]];
factorTest = Get[FileNameJoin[{
  workDirectory, "TargetFactorizationTest.wl"
}]];

targetKeys = factorTest["TargetKeys"];
targetParts = <|
  "Terms" -> AssociationThread[Most[targetKeys], Most[factorTest["Stripped"]]],
  "Remainder" -> Last[factorTest["Stripped"]]
|>;

sparseReduction = FeynFacet`Private`compileSparseReduction[
  kira["Targets"],
  Dispatch[kira["KiraRules"]],
  Function[coefficient,
    coefficient /. kira["ReverseRules"] /. kira["DimensionRule"]
  ]
];

{compositionSeconds, masterParts} = AbsoluteTiming[
  FeynFacet`Private`linearComposeReduction[targetParts, sparseReduction]
];
masterParts = FeynFacet`Private`linearMapCoefficients[
  masterParts,
  Function[coefficient, coefficient /. kira["DimensionRule"]]
];
masterInput = Append[
  Values[masterParts["Terms"]],
  masterParts["Remainder"]
];

{masterSeconds, normalized} = AbsoluteTiming[
  FeynFacet`Private`parallelNormalizeCoefficients[
    masterInput,
    assumptions,
    60
  ]
];
masterOutput = First[normalized];
finalParts = <|
  "Terms" -> AssociationThread[Keys[masterParts["Terms"]], Most[masterOutput]],
  "Remainder" -> Last[masterOutput]
|>;

result = <|
  "CompositionSeconds" -> compositionSeconds,
  "MasterSimplificationSeconds" -> masterSeconds,
  "MasterCount" -> Length[masterParts["Terms"]],
  "MasterInputBytes" -> ByteCount[masterInput],
  "MasterOutputBytes" -> ByteCount[masterOutput],
  "MasterCompression" -> N[ByteCount[masterInput]/ByteCount[masterOutput]],
  "FractionFree" -> FreeQ[masterOutput, Alternatives[xa, xb, zh]],
  "PhysicalFactor" -> factorTest["PhysicalFactor"],
  "Parts" -> finalParts
|>;

Put[result, FileNameJoin[{
  workDirectory, "FactoredTargetRoute.wl"
}]];
Clear[$PrePrint];
Print[InputForm[KeyDrop[result, "Parts"]]];
