$HistoryLength = 0;
Global`$FACETKernelLimit = 4;

root = "/home/maxzhang/FACET";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Clear[$PrePrint];

assert[label_String, condition_] := If[
  TrueQ[condition],
  Print[label, "\tOK"],
  Print[label, "\tFAILED\t", InputForm[condition]];
  Quit[1]
];

card = Get[FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Cards", "UU.wl"
}]];
targets = FeynFacet`Private`coefficientReadRecord[FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "HadronicSimplification",
  "NNLOPhysicalTargets", "PhysicalTargets_0001.bin"
}]];
nonzeroTargets = Select[Values[targets], ! TrueQ[PossibleZeroQ[#]] &];
expression = First @ MinimalBy[nonzeroTargets, ByteCount];
expanded = Expand[expression];
contributions = If[Head[expanded] === Plus, List @@ expanded, {expanded}];

Print[
  "Stored NNLO target input\t",
  Length[contributions], " additive contributions\t",
  Round[ByteCount[expression]/1024., 0.01], " kB"
];

{time, result} = AbsoluteTiming[
  SimplifyHardCoefficients[
    {contributions},
    card,
    "Method" -> "ContributionWise",
    "TimeLimit" -> 180
  ]
];

assert["NNLO UU contribution-wise simplification", AssociationQ[result]];
assert[
  "NNLO UU distribution product",
  TrueQ @ FullSimplify[
    result["DistributionFactor"] == D1[zh] f1[xa] f1[xb],
    Assumptions -> result["SimplificationContext"]["PhysicalAssumptions"]
  ]
];
assert[
  "NNLO UU Laurent valuation",
  result["LaurentValuation"] === <|xa -> -1, xb -> -1, zh -> -2|>
];
assert[
  "NNLO UU fractions absent",
  FreeQ[result["Expressions"], xa | xb | zh]
];
Print[
  "NNLO UU stored target\t",
  Round[time, 0.01], " s\t",
  Round[ByteCount[result]/1024., 0.01], " kB"
];

Print["ACTUAL_NNLO_HARD_SIMPLIFICATION_OK"];
Quit[0];
