$HistoryLength = 0;
Global`$FACETKernelLimit = 4;

root = "/home/maxzhang/FACET";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
benchmarkPackage = Environment["FACET_BENCHMARK_PACKAGE"];
If[StringQ[benchmarkPackage] && benchmarkPackage =!= "",
  Get[ExpandFileName[benchmarkPackage]];
  FeynFacet`Private`$feynFacetRoot = root;
  FeynCalc`FCSetDiracGammaScheme["BMHV"];
  Global`GlobalBasis = FeynFacet`BuildGlobalBasis[{nb, n, xhat, yhat}];
  FeynArts`$FAVerbose = 0
];
Clear[$PrePrint];

assert[label_String, condition_] := If[
  TrueQ[condition],
  Print[label, "\tOK"],
  Print[label, "\tFAILED\t", InputForm[condition]];
  Quit[1]
];

uuCard = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
uuData = Get[FileNameJoin[{
  root, "Codex", "ppHX_NLO", "HadronicSimplification", "Production",
  "UU_08_08_3", "IBPResult.wl"
}]];
uuExpressions = uuData["PreFactor"] Map[
  #1["PreFactor"] #1["Coefficient"] &,
  uuData["Masters"]
];
{uuTime, uuResult} = AbsoluteTiming[
  SimplifyHardCoefficients[uuExpressions, uuCard, "TimeLimit" -> 180]
];
assert["NLO UU exact simplification", AssociationQ[uuResult]];
assert[
  "NLO UU distribution product",
  TrueQ @ FullSimplify[
    uuResult["DistributionFactor"] == D1[zh] f1[xa] f1[xb],
    Assumptions ->
      uuResult["SimplificationContext"]["PhysicalAssumptions"]
  ]
];
assert[
  "NLO UU Laurent valuation",
  uuResult["LaurentValuation"] === <|xa -> -1, xb -> -1, zh -> -2|>
];
assert[
  "NLO UU fractions absent",
  FreeQ[uuResult["Expressions"], xa | xb | zh]
];
Print[
  "NLO UU\t",
  Round[uuTime, 0.01], " s\t",
  Length[uuResult["Expressions"]], " coefficients\t",
  Round[ByteCount[uuResult]/1024., 0.01], " kB"
];

ttCard = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "TT.wl"}]];
ttData = Get[FileNameJoin[{
  root, "Codex", "ppHX_NLO", "HadronicSimplification", "TTOrdering",
  "TargetThenMaster_02.wl"
}]];
ttFinal = ttData["Data", "Final"];
ttTerms = Values[ttFinal["HardPart", "Terms"]];
ttTerm = First @ MinimalBy[ttTerms, ByteCount];
{ttTime, ttResult} = AbsoluteTiming[
  SimplifyHardCoefficients[
    {ttFinal["PreFactor"] ttTerm},
    ttCard,
    "TimeLimit" -> 180
  ]
];
assert["NLO TT exact simplification", AssociationQ[ttResult]];
assert[
  "NLO TT distribution product",
  TrueQ @ FullSimplify[
    ttResult["DistributionFactor"] == f1[xb] h1[xa] H1[zh],
    Assumptions ->
      ttResult["SimplificationContext"]["PhysicalAssumptions"]
  ]
];
assert[
  "NLO TT Laurent valuation",
  ttResult["LaurentValuation"] === <|xa -> -1, xb -> -1, zh -> -2|>
];
assert[
  "NLO TT fractions absent",
  FreeQ[ttResult["Expressions"], xa | xb | zh]
];
Print[
  "NLO TT smallest coefficient\t",
  Round[ttTime, 0.01], " s\t",
  Round[ByteCount[ttResult]/1024., 0.01], " kB"
];

nnloCard = Get[FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Cards", "UU.wl"
}]];
nnloTargets = FeynFacet`Private`coefficientReadRecord[FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "HadronicSimplification",
  "NNLOPhysicalTargets", "PhysicalTargets_0001.bin"
}]];
nnloNonzeroTargets = Select[
  Values[nnloTargets],
  ! TrueQ[PossibleZeroQ[#]] &
];
nnloExpression = First @ MinimalBy[nnloNonzeroTargets, ByteCount];
nnloExpanded = Expand[nnloExpression];
nnloContributions = If[
  Head[nnloExpanded] === Plus,
  List @@ nnloExpanded,
  {nnloExpanded}
];
{nnloTime, nnloResult} = AbsoluteTiming[
  SimplifyHardCoefficients[
    {nnloContributions},
    nnloCard,
    "Method" -> "ContributionWise",
    "TimeLimit" -> 180
  ]
];
assert["NNLO UU contribution-wise simplification", AssociationQ[nnloResult]];
assert[
  "NNLO UU distribution product",
  TrueQ @ FullSimplify[
    nnloResult["DistributionFactor"] == D1[zh] f1[xa] f1[xb],
    Assumptions ->
      nnloResult["SimplificationContext"]["PhysicalAssumptions"]
  ]
];
assert[
  "NNLO UU Laurent valuation",
  nnloResult["LaurentValuation"] === <|xa -> -1, xb -> -1, zh -> -2|>
];
assert[
  "NNLO UU fractions absent",
  FreeQ[nnloResult["Expressions"], xa | xb | zh]
];
Print[
  "NNLO UU stored target\t",
  Length[nnloContributions], " contributions\t",
  Round[nnloTime, 0.01], " s\t",
  Round[ByteCount[nnloResult]/1024., 0.01], " kB"
];

Print["ACTUAL_HARD_SIMPLIFICATION_OK"];
Quit[0];
